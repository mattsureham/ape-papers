## 03_main_analysis.R — Main DiD and DDD specifications
## APEP Working Paper apep_0754

source("00_packages.R")

## ---- 1. Load panels ----
panel_conv <- readRDS("../data/panel_conv.rds")
panel_ddd  <- readRDS("../data/panel_ddd.rds")
panel_full <- readRDS("../data/panel_full.rds")
pilot_dates <- readRDS("../data/pilot_dates.rds")

## ---- 2. Callaway-Sant'Anna for convenience stores ----
cat("=== Callaway-Sant'Anna DiD (convenience stores) ===\n")

# Need numeric state ID
panel_conv[, state_id := as.integer(as.factor(State))]

# CS-DiD requires: yname, tname, idname, gname
cs_out <- att_gt(
  yname = "exit_rate",
  tname = "yq_num",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel_conv[!is.na(exit_rate)]),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("ATT(g,t) summary:\n")
print(summary(cs_out))

# Aggregate: overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat(sprintf("\nOverall ATT: %.5f (SE: %.5f)\n", cs_agg$overall.att, cs_agg$overall.se))

# Aggregate: event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 16)
cat("Event study summary:\n")
print(summary(cs_es))

## ---- 3. TWFE DiD + DDD with fixest ----
cat("\n=== TWFE DDD (fixest) ===\n")

panel_ddd[, state_type := paste0(State, "_", store_group)]
panel_ddd[, state_type_id := as.integer(as.factor(state_type))]

# Main DDD specification with state×quarter FE to absorb state-specific shocks
# This ensures identification comes from WITHIN state-quarter differential
# between convenience stores and supermarkets
ddd_main <- feols(
  exit_rate ~ treated:is_conv |
    State^store_group + State^yq_num,
  data = panel_ddd,
  cluster = ~State
)

cat("\nDDD Main Result:\n")
print(summary(ddd_main))

# Alternative: continuous time interaction
panel_ddd[, rel_time := yq_num - treat_yq_num]
panel_ddd[is.na(rel_time), rel_time := -999]  # never treated

# Event study version of DDD
# Bin relative time for event study
panel_ddd[, rel_time_bin := case_when(
  rel_time == -999 ~ NA_real_,
  rel_time < -8 ~ -8,
  rel_time > 16 ~ 16,
  TRUE ~ rel_time
)]

# Event study DDD (dropping t=-1 as reference)
ddd_es <- feols(
  exit_rate ~ i(rel_time_bin, is_conv, ref = -1) |
    State^store_group + yq_num,
  data = panel_ddd[!is.na(rel_time_bin)],
  cluster = ~State
)

cat("\nDDD Event Study:\n")
print(summary(ddd_es))

## ---- 4. Heterogeneity: Pre-COVID vs COVID-era ----
cat("\n=== Pre-COVID vs COVID-era heterogeneity ===\n")

# NY is the only state treated before COVID (April 2019)
panel_conv[, pre_covid_treat := as.integer(State == "NY" & treated == 1)]
panel_conv[, covid_treat := as.integer(State != "NY" & treated == 1)]

het_covid <- feols(
  exit_rate ~ pre_covid_treat + covid_treat | State + yq_num,
  data = panel_conv,
  cluster = ~State
)
cat("\nPre-COVID (NY only) vs COVID-era treatment:\n")
print(summary(het_covid))

## ---- 5. Sun-Abraham (robustness) ----
cat("\n=== Sun-Abraham event study (convenience stores) ===\n")

panel_conv[, cohort := ifelse(first_treat == 0, 10000, first_treat)]

sa_es <- feols(
  exit_rate ~ sunab(cohort, yq_num) | State + yq_num,
  data = panel_conv,
  cluster = ~State
)

cat("\nSun-Abraham event study:\n")
print(summary(sa_es))

## ---- 6. Save results ----
results <- list(
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_es = cs_es,
  ddd_main = ddd_main,
  ddd_es = ddd_es,
  het_covid = het_covid,
  sa_es = sa_es
)
saveRDS(results, "../data/main_results.rds")

## ---- 7. Write diagnostics ----
diagnostics <- list(
  n_treated = panel_conv[first_treat > 0, uniqueN(State)],
  n_pre = panel_conv[yq_num < min(panel_conv[first_treat > 0 & first_treat != 0]$first_treat),
                      uniqueN(yq_num)],
  n_obs = nrow(panel_conv),
  n_obs_ddd = nrow(panel_ddd),
  n_conv_stores = sum(panel_conv$n_active[panel_conv$yq == "2019Q4"]),
  n_super_stores = sum(panel_full[store_group == "supermarket" & yq == "2019Q4"]$n_active),
  att_overall = cs_agg$overall.att,
  att_se = cs_agg$overall.se,
  ddd_coef = coef(ddd_main)[grep("treated.*is_conv|is_conv.*treated", names(coef(ddd_main)))[1]],
  ddd_se = sqrt(diag(vcov(ddd_main))[grep("treated.*is_conv|is_conv.*treated", names(coef(ddd_main)))[1]])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
