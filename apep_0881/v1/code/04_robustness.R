# 04_robustness.R — Robustness checks
# apep_0881: Academy Conversion and Pupil Sorting

source("00_packages.R")

data_dir <- "../data"
did_panel <- readRDS(file.path(data_dir, "did_panel.rds"))
entity_panel <- readRDS(file.path(data_dir, "entity_panel.rds"))

# Prepare data (same as main analysis)
did_data <- did_panel |>
  mutate(
    school_id = as.integer(school_id),
    year = as.integer(year),
    g = as.integer(g),
    la_code = as.character(la_code),
    cohort = ifelse(g == 0, Inf, g),
    post = as.integer(g > 0 & year >= g),
    treated = as.integer(g > 0)
  ) |>
  filter(!is.na(fsm_pct)) |>
  group_by(school_id, year) |>
  slice_max(n_pupils, n = 1, with_ties = FALSE) |>
  ungroup()

cat("Robustness panel:", nrow(did_data), "obs,", n_distinct(did_data$school_id), "schools\n")

# ==============================================================================
# 1. Leave-one-cohort-out
# ==============================================================================

cat("\n=== Leave-One-Cohort-Out ===\n")

cohorts <- sort(unique(did_data$g[did_data$g > 0]))
loco_results <- list()

for (c in cohorts) {
  did_loco <- did_data |> filter(g == 0 | g != c)
  n_treat <- n_distinct(did_loco$school_id[did_loco$g > 0])
  if (n_treat < 20) next

  sa_loco <- feols(
    fsm_pct ~ sunab(cohort, year) | school_id + year,
    data = did_loco |> mutate(cohort = ifelse(g == 0, Inf, g)),
    cluster = ~la_code
  )
  agg <- summary(sa_loco, agg = "ATT")
  coef_att <- coef(agg)["ATT"]
  se_att <- agg$se["ATT"]

  loco_results[[as.character(c)]] <- tibble(
    dropped_cohort = c, att = coef_att, se = se_att,
    n_treated = n_treat
  )
  cat("  Drop cohort", c, ": ATT =", round(coef_att, 3),
      "(SE =", round(se_att, 3), ") n_treated =", n_treat, "\n")
}

loco_df <- bind_rows(loco_results)
saveRDS(loco_df, file.path(data_dir, "robustness_loco.rds"))

# ==============================================================================
# 2. Placebo: Number of pupils (should not change)
# ==============================================================================

cat("\n=== Placebo: Number of Pupils ===\n")

sa_pupils <- feols(
  n_pupils ~ sunab(cohort, year) | school_id + year,
  data = did_data,
  cluster = ~la_code
)

sa_pupils_agg <- summary(sa_pupils, agg = "ATT")
cat("Pupil count ATT:\n")
print(sa_pupils_agg)

saveRDS(sa_pupils, file.path(data_dir, "robustness_placebo_pupils.rds"))

# ==============================================================================
# 3. TWFE with LA-by-year FE (more restrictive)
# ==============================================================================

cat("\n=== TWFE with LA-by-Year FE ===\n")

# This absorbs all LA-specific trends
twfe_layr <- feols(
  fsm_pct ~ post | school_id + la_code^year,
  data = did_data,
  cluster = ~la_code
)

cat("TWFE with LA×Year FE:\n")
print(summary(twfe_layr))

saveRDS(twfe_layr, file.path(data_dir, "robustness_twfe_layr.rds"))

# ==============================================================================
# 4. Sun-Abraham with LA-by-year FE
# ==============================================================================

cat("\n=== Sun-Abraham with LA-by-Year FE ===\n")

sa_layr <- feols(
  fsm_pct ~ sunab(cohort, year) | school_id + la_code^year,
  data = did_data,
  cluster = ~la_code
)

sa_layr_agg <- summary(sa_layr, agg = "ATT")
cat("Sun-Abraham with LA×Year FE:\n")
print(sa_layr_agg)

saveRDS(sa_layr, file.path(data_dir, "robustness_sa_layr.rds"))

# ==============================================================================
# 5. Weighted by school size
# ==============================================================================

cat("\n=== Pupil-Weighted Estimation ===\n")

sa_weighted <- feols(
  fsm_pct ~ sunab(cohort, year) | school_id + year,
  data = did_data,
  weights = ~n_pupils,
  cluster = ~la_code
)

sa_wt_agg <- summary(sa_weighted, agg = "ATT")
cat("Weighted ATT:\n")
print(sa_wt_agg)

saveRDS(sa_weighted, file.path(data_dir, "robustness_weighted.rds"))

# ==============================================================================
# 6. Spillover: Effect on neighboring maintained schools in same LA
# ==============================================================================

cat("\n=== Spillover Test ===\n")

# For never-treated schools: does being in an LA with more recent conversions
# change FSM%?

# Compute LA-level conversion intensity for each year
la_conv_intensity <- did_data |>
  filter(g > 0) |>
  group_by(la_code, year) |>
  summarise(
    n_converted_cumul = n_distinct(school_id[year >= g]),
    .groups = "drop"
  )

never_treated <- did_data |>
  filter(g == 0) |>
  left_join(la_conv_intensity, by = c("la_code", "year")) |>
  mutate(n_converted_cumul = replace_na(n_converted_cumul, 0))

if (nrow(never_treated) > 100) {
  spillover_reg <- feols(
    fsm_pct ~ n_converted_cumul | school_id + year,
    data = never_treated,
    cluster = ~la_code
  )

  cat("Spillover (maintained schools in LA with conversions):\n")
  print(summary(spillover_reg))
  saveRDS(spillover_reg, file.path(data_dir, "robustness_spillover.rds"))
}

# ==============================================================================
# 7. Compile robustness summary
# ==============================================================================

cat("\n=== ROBUSTNESS SUMMARY ===\n")

main_att <- coef(summary(readRDS(file.path(data_dir, "sa_fsm.rds")), agg = "ATT"))["ATT"]
main_se <- summary(readRDS(file.path(data_dir, "sa_fsm.rds")), agg = "ATT")$se["ATT"]

robustness_summary <- tibble(
  Specification = c(
    "Main (Sun-Abraham)",
    "TWFE (biased)",
    "SA with LA×Year FE",
    "Pupil-weighted SA",
    "TWFE with LA×Year FE"
  ),
  ATT = c(
    main_att,
    coef(readRDS(file.path(data_dir, "twfe_fsm.rds")))["post"],
    coef(sa_layr_agg)["ATT"],
    coef(sa_wt_agg)["ATT"],
    coef(twfe_layr)["post"]
  ),
  SE = c(
    main_se,
    summary(readRDS(file.path(data_dir, "twfe_fsm.rds")))$se["post"],
    sa_layr_agg$se["ATT"],
    sa_wt_agg$se["ATT"],
    summary(twfe_layr)$se["post"]
  )
) |>
  mutate(
    t_stat = ATT / SE,
    p_value = 2 * pt(-abs(t_stat), df = 150)
  )

print(robustness_summary)
saveRDS(robustness_summary, file.path(data_dir, "robustness_summary.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
