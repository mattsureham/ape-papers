# 03_main_analysis.R — Main DiD analysis
# apep_1026: Marijuana legalization and FHA mortgage exclusion

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
cat(glue("Loaded panel: {nrow(panel)} obs, {uniqueN(panel$state)} states\n\n"))

# ============================================================
# 1. TWFE baseline (for comparison)
# ============================================================
cat("=== TWFE Regressions ===\n")

# Main outcome: FHA share (pct)
twfe_fha <- feols(fha_share_pct ~ post | state + year,
                  data = panel[always_treated == 0],
                  cluster = ~state)

# Conventional share (substitution test)
twfe_conv <- feols(conv_share_pct ~ post | state + year,
                   data = panel[always_treated == 0],
                   cluster = ~state)

# VA share (placebo — also federally backed, same exclusion should apply)
twfe_va <- feols(va_share_pct ~ post | state + year,
                 data = panel[always_treated == 0],
                 cluster = ~state)

# Government share (FHA + VA + USDA)
twfe_govt <- feols(govt_share_pct ~ post | state + year,
                   data = panel[always_treated == 0],
                   cluster = ~state)

cat("\nTWFE Results:\n")
etable(twfe_fha, twfe_conv, twfe_va, twfe_govt,
       headers = c("FHA Share", "Conv Share", "VA Share", "Govt Share"))

# ============================================================
# 2. Callaway-Sant'Anna (2021) — group-time ATT
# ============================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for did package
# CS requires: yname (outcome), tname (time), idname (unit), gname (cohort)
# cohort = 0 for never-treated
cs_data <- panel[always_treated == 0]
cs_data[, state_num := as.integer(factor(state))]

# Ensure cohort coding: 0 = never-treated, year = first treatment for treated
stopifnot(all(cs_data[treated == 0]$cohort == 0))
stopifnot(all(cs_data[treated == 1]$cohort > 2018))

cs_out <- att_gt(
  yname = "fha_share_pct",
  tname = "year",
  idname = "state_num",
  gname = "cohort",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  est_method = "reg",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
print(summary(cs_out))

# Aggregate to event-study
cs_es <- aggte(cs_out, type = "dynamic")
cat("\nEvent-study ATTs:\n")
print(summary(cs_es))

# Aggregate to simple ATT
cs_simple <- aggte(cs_out, type = "simple")
cat("\nSimple ATT:\n")
print(summary(cs_simple))

# Aggregate by group (cohort)
cs_group <- aggte(cs_out, type = "group")
cat("\nGroup-level ATTs:\n")
print(summary(cs_group))

# ============================================================
# 3. TWFE Event Study (for visual pre-trends)
# ============================================================
cat("\n=== TWFE Event Study ===\n")

# Create event-time indicators (relative to legalization)
# Only for states treated in our window (2019-2023)
es_data <- panel[always_treated == 0 & (treated == 0 | (treated == 1 & cohort > 2018))]

# Bin extreme leads/lags
es_data[, rel_year_binned := fcase(
  rel_year <= -4, -4L,
  rel_year >= 4, 4L,
  default = as.integer(rel_year)
)]

# Drop rel_year = -1 (reference)
es_data[, rel_year_binned := factor(rel_year_binned)]

twfe_es <- feols(fha_share_pct ~ i(rel_year_binned, ref = "-1") | state + year,
                 data = es_data[treated == 1 | rel_year_binned == "-1" | TRUE],
                 cluster = ~state)

cat("\nEvent-study coefficients:\n")
print(coeftable(twfe_es))

# ============================================================
# 4. Save results for table generation
# ============================================================

# Extract key results
results <- list(
  twfe_fha = twfe_fha,
  twfe_conv = twfe_conv,
  twfe_va = twfe_va,
  twfe_govt = twfe_govt,
  cs_out = cs_out,
  cs_es = cs_es,
  cs_simple = cs_simple,
  cs_group = cs_group,
  twfe_es = twfe_es
)

saveRDS(results, "../data/main_results.rds")

# ============================================================
# 5. Diagnostics for validator
# ============================================================
# Count all states that ever legalized (including always-treated)
all_treated <- uniqueN(panel[treated == 1]$state)
# Pre-periods for latest cohort (most pre-periods available)
max_pre <- max(panel[treated == 1 & always_treated == 0,
                     .(n_pre = sum(year < cohort)), by = state]$n_pre)

diagnostics <- list(
  n_treated = all_treated,
  n_pre = max_pre,
  n_obs = nrow(panel),
  n_states = uniqueN(panel$state),
  n_years = uniqueN(panel$year),
  cs_att = cs_simple$overall.att,
  cs_se = cs_simple$overall.se,
  twfe_coef = coef(twfe_fha)["post"],
  twfe_se = se(twfe_fha)["post"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat(glue("Treated states (in CS): {diagnostics$n_treated}\n"))
cat(glue("Observations: {diagnostics$n_obs}\n"))
cat(glue("CS ATT: {round(diagnostics$cs_att, 3)} (SE: {round(diagnostics$cs_se, 3)})\n"))
cat(glue("TWFE coef: {round(diagnostics$twfe_coef, 3)} (SE: {round(diagnostics$twfe_se, 3)})\n"))

cat("\nMain analysis complete. Results saved.\n")
