## ============================================================
## 03_main_analysis.R — Main DiD estimates
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

source("00_packages.R")
load("../data/analysis_panel.RData")

## ============================
## A. Callaway-Sant'Anna: Completions
## ============================

cat("\n=== CS-DiD: Bachelor's Completions (log) ===\n")

## Prepare data: need complete cases for CS-DiD
cs_data <- analysis_df |>
  filter(!is.na(ln_bachelors), year >= 2003, year <= 2022) |>
  ## Ensure balanced-ish panel: keep institutions with >= 10 years of data
  group_by(unitid) |>
  filter(n() >= 10) |>
  ungroup() |>
  mutate(unitid_num = as.numeric(as.factor(unitid)))

cat("CS sample: ", nrow(cs_data), " obs, ",
    n_distinct(cs_data$unitid), " institutions, ",
    n_distinct(cs_data$state[cs_data$first_treat > 0]), " treated states\n")

cs_comp <- att_gt(
  yname = "ln_bachelors",
  tname = "year",
  idname = "unitid_num",
  gname = "first_treat",
  data = cs_data,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\nCS-DiD completions summary:\n")
summary(cs_comp)

## Aggregate: simple ATT
agg_comp <- aggte(cs_comp, type = "simple")
cat("\nSimple ATT (completions):", agg_comp$overall.att,
    " SE:", agg_comp$overall.se, "\n")

## Event study
es_comp <- aggte(cs_comp, type = "dynamic", min_e = -8, max_e = 8)
cat("Event study computed.\n")

## ============================
## B. Callaway-Sant'Anna: Graduation Rate
## ============================

cat("\n=== CS-DiD: 6-Year Graduation Rate ===\n")

cs_gr_data <- analysis_df |>
  filter(!is.na(grad_rate_150), year >= 2003, year <= 2022) |>
  group_by(unitid) |>
  filter(n() >= 10) |>
  ungroup() |>
  mutate(unitid_num = as.numeric(as.factor(unitid)))

cat("GR sample:", nrow(cs_gr_data), "obs,", n_distinct(cs_gr_data$unitid), "institutions\n")

cs_gr <- tryCatch({
  att_gt(
    yname = "grad_rate_150",
    tname = "year",
    idname = "unitid_num",
    gname = "first_treat",
    data = cs_gr_data,
    control_group = "nevertreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD for graduation rate failed:", conditionMessage(e), "\n")
  cat("Falling back to TWFE with Sun-Abraham.\n")
  NULL
})

if (!is.null(cs_gr)) {
  agg_gr <- aggte(cs_gr, type = "simple")
  cat("Simple ATT (grad rate):", agg_gr$overall.att, " SE:", agg_gr$overall.se, "\n")
  es_gr <- aggte(cs_gr, type = "dynamic", min_e = -8, max_e = 8)
} else {
  ## Sun-Abraham fallback
  sa_gr <- feols(grad_rate_150 ~ sunab(first_treat, year) | unitid + year,
                 data = cs_gr_data |> filter(first_treat == 0 | first_treat > 0),
                 cluster = ~state)
  agg_gr <- list(overall.att = NA, overall.se = NA)
  es_gr <- NULL
  cat("Sun-Abraham estimates:\n")
  print(summary(sa_gr))
}

## ============================
## C. Callaway-Sant'Anna: Enrollment (log)
## ============================

cat("\n=== CS-DiD: Total Enrollment (log) ===\n")

cs_enroll_data <- analysis_df |>
  filter(!is.na(ln_enroll), enroll_total > 0, year >= 2003, year <= 2022) |>
  group_by(unitid) |>
  filter(n() >= 10) |>
  ungroup() |>
  mutate(unitid_num = as.numeric(as.factor(unitid)))

cs_enroll <- att_gt(
  yname = "ln_enroll",
  tname = "year",
  idname = "unitid_num",
  gname = "first_treat",
  data = cs_enroll_data,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_enroll <- aggte(cs_enroll, type = "simple")
cat("Simple ATT (enrollment):", agg_enroll$overall.att,
    " SE:", agg_enroll$overall.se, "\n")
es_enroll <- aggte(cs_enroll, type = "dynamic", min_e = -8, max_e = 8)

## ============================
## D. Cream-Skimming Tests: Pell share and minority share
## ============================

cat("\n=== CS-DiD: Minority Enrollment Share ===\n")

cs_min_data <- analysis_df |>
  filter(!is.na(pct_minority), year >= 2003, year <= 2022) |>
  group_by(unitid) |>
  filter(n() >= 10) |>
  ungroup() |>
  mutate(unitid_num = as.numeric(as.factor(unitid)))

cs_minority <- att_gt(
  yname = "pct_minority",
  tname = "year",
  idname = "unitid_num",
  gname = "first_treat",
  data = cs_min_data,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_minority <- aggte(cs_minority, type = "simple")
cat("Simple ATT (minority share):", agg_minority$overall.att,
    " SE:", agg_minority$overall.se, "\n")
es_minority <- aggte(cs_minority, type = "dynamic", min_e = -8, max_e = 8)

## ============================
## E. TWFE Regressions (fixest) for table presentation
## ============================

cat("\n=== TWFE (Sun-Abraham) Regressions ===\n")

## Filter data once for TWFE
twfe_data <- analysis_df |>
  filter(year >= 2003, year <= 2022) |>
  mutate(treated = as.integer(post_pbf))

## Main regressions
reg_comp <- feols(ln_bachelors ~ treated | unitid + year,
                  data = twfe_data, cluster = ~state)

reg_gr <- feols(grad_rate_150 ~ treated | unitid + year,
                data = twfe_data, cluster = ~state)

reg_enroll <- feols(ln_enroll ~ treated | unitid + year,
                    data = twfe_data, cluster = ~state)

reg_minority <- feols(pct_minority ~ treated | unitid + year,
                      data = twfe_data, cluster = ~state)

reg_black <- feols(pct_black ~ treated | unitid + year,
                   data = twfe_data, cluster = ~state)

cat("TWFE results:\n")
cat("  Completions (log):", coef(reg_comp)["treated"], " SE:", se(reg_comp)["treated"], "\n")
cat("  Grad rate:", coef(reg_gr)["treated"], " SE:", se(reg_gr)["treated"], "\n")
cat("  Enrollment (log):", coef(reg_enroll)["treated"], " SE:", se(reg_enroll)["treated"], "\n")
cat("  Minority %:", coef(reg_minority)["treated"], " SE:", se(reg_minority)["treated"], "\n")
cat("  Black %:", coef(reg_black)["treated"], " SE:", se(reg_black)["treated"], "\n")

## ============================
## F. Sun-Abraham event study
## ============================

sa_comp <- feols(ln_bachelors ~ sunab(first_treat, year) | unitid + year,
                 data = twfe_data |> filter(first_treat == 0 | first_treat > 0),
                 cluster = ~state)

sa_gr2 <- feols(grad_rate_150 ~ sunab(first_treat, year) | unitid + year,
                data = twfe_data |> filter(first_treat == 0 | first_treat > 0),
                cluster = ~state)

sa_minority <- feols(pct_minority ~ sunab(first_treat, year) | unitid + year,
                     data = twfe_data |> filter(first_treat == 0 | first_treat > 0),
                     cluster = ~state)

## ============================
## G. Diagnostics
## ============================

n_treated_states <- n_distinct(cs_data$state[cs_data$first_treat > 0])
n_control_states <- n_distinct(cs_data$state[cs_data$first_treat == 0])
n_treated_inst <- n_distinct(cs_data$unitid[cs_data$first_treat > 0])
pre_periods <- cs_data |>
  filter(first_treat > 0) |>
  group_by(unitid_num) |>
  summarise(n_pre = sum(year < first_treat), .groups = "drop")

diagnostics <- list(
  n_treated = n_treated_inst,
  n_pre = as.integer(median(pre_periods$n_pre)),
  n_obs = nrow(cs_data),
  n_treated_states = n_treated_states,
  n_control_states = n_control_states,
  n_control_inst = n_distinct(cs_data$unitid[cs_data$first_treat == 0]),
  years = paste(range(cs_data$year), collapse = "-")
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")
print(diagnostics)

## ============================
## Save results
## ============================

save(cs_comp, agg_comp, es_comp,
     cs_gr, agg_gr, es_gr,
     cs_enroll, agg_enroll, es_enroll,
     cs_minority, agg_minority, es_minority,
     reg_comp, reg_gr, reg_enroll, reg_minority, reg_black,
     sa_comp, sa_gr2, sa_minority,
     twfe_data, cs_data,
     file = "../data/main_results.RData")
cat("Saved main results to data/main_results.RData\n")
