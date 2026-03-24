## 04_robustness.R — Robustness checks for apep_0864
## Placebo referendum, HonestDiD, leave-one-canton-out, first differences

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel |> mutate(rel_year = year - 2015)

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# 1. PLACEBO REFERENDUM — FABI (railway financing)
# ============================================================
cat("\n--- Placebo: FABI Railway Referendum ---\n")

panel <- panel |>
  mutate(
    placebo_std = (placebo_yes_share - mean(placebo_yes_share, na.rm = TRUE)) /
      sd(placebo_yes_share, na.rm = TRUE)
  )

# Same specification as main but with FABI yes-share instead of MEI
m_placebo <- feols(foreign_share ~ placebo_std:post | bfs_nr + year,
                   data = panel, cluster = ~bfs_nr)
cat("Placebo (FABI): β =", round(coef(m_placebo)[1], 5),
    "SE =", round(se(m_placebo)[1], 5),
    "p =", round(pvalue(m_placebo)[1], 4), "\n")

# ============================================================
# 2. FIRST DIFFERENCES — Remove level dependence
# ============================================================
cat("\n--- First-Differenced Outcome ---\n")

panel <- panel |>
  group_by(bfs_nr) |>
  arrange(year) |>
  mutate(d_foreign_share = foreign_share - dplyr::lag(foreign_share)) |>
  ungroup()

m_fd <- feols(d_foreign_share ~ yes_share_std:post | bfs_nr + year,
              data = panel |> filter(!is.na(d_foreign_share)),
              cluster = ~bfs_nr)
cat("First-diff: β =", round(coef(m_fd)[1], 5),
    "SE =", round(se(m_fd)[1], 5),
    "p =", round(pvalue(m_fd)[1], 4), "\n")

# ============================================================
# 3. HONESTDID — Rambachan-Roth bounds
# ============================================================
cat("\n--- HonestDiD Sensitivity ---\n")

es <- readRDS(file.path(data_dir, "event_study_model.rds"))

# Get the event study coefficients and vcov in the right format
es_coef <- coef(es)
es_vcov <- vcov(es)

# Order: t=-4, t=-3, t=-2, t=0, t=1, ..., t=9 (ref: t=-1)
# Pre-period coefficients: indices 1-3 (t=-4, -3, -2)
# Post-period coefficients: indices 4-13 (t=0 through t=9)

n_pre <- 3   # t=-4, -3, -2
n_post <- 10  # t=0 through t=9

# Sensitivity analysis: what if pre-trends continued?
# M-bar = max pre-trend slope
pre_coefs <- es_coef[1:n_pre]
pre_diffs <- diff(pre_coefs)
M_bar <- max(abs(pre_diffs))
cat(sprintf("Max pre-trend slope (M-bar): %.5f\n", M_bar))

honest_result <- tryCatch({
  HonestDiD::createSensitivityResults(
    betahat = es_coef,
    sigma = es_vcov,
    numPrePeriods = n_pre,
    numPostPeriods = n_post,
    Mvec = seq(0, 2 * M_bar, length.out = 5),
    alpha = 0.05
  )
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  NULL
})

if (!is.null(honest_result)) {
  cat("HonestDiD sensitivity results:\n")
  print(honest_result)
}

saveRDS(honest_result, file.path(data_dir, "honestdid_results.rds"))

# ============================================================
# 4. LEAVE-ONE-CANTON-OUT
# ============================================================
cat("\n--- Leave-One-Canton-Out ---\n")

cantons <- sort(unique(panel$canton_id))
loco_results <- data.frame()

for (ct in cantons) {
  sub <- panel |> filter(canton_id != ct)
  m_loco <- feols(foreign_share ~ yes_share_std:post | bfs_nr + year,
                  data = sub, cluster = ~bfs_nr)
  loco_results <- bind_rows(loco_results, data.frame(
    canton_dropped = ct,
    coef = coef(m_loco)[1],
    se = se(m_loco)[1],
    n_mun = n_distinct(sub$bfs_nr)
  ))
}

cat(sprintf("LOCO range: [%.5f, %.5f] (main: %.5f)\n",
            min(loco_results$coef), max(loco_results$coef),
            coef(readRDS(file.path(data_dir, "main_models.rds"))$m1)[1]))

# ============================================================
# 5. SWISS-BORN vs FOREIGN-BORN (mechanism)
# ============================================================
cat("\n--- Swiss Population Check ---\n")

panel <- panel |>
  mutate(swiss_share = swiss / total)

m_swiss <- feols(swiss_share ~ yes_share_std:post | bfs_nr + year,
                 data = panel, cluster = ~bfs_nr)
cat("Swiss share: β =", round(coef(m_swiss)[1], 5),
    "SE =", round(se(m_swiss)[1], 5), "\n")
cat("(Should be opposite sign or zero if foreign effect is real)\n")

# ============================================================
# 6. POPULATION-WEIGHTED REGRESSION
# ============================================================
cat("\n--- Population-Weighted ---\n")

m_weighted <- feols(foreign_share ~ yes_share_std:post | bfs_nr + year,
                    data = panel, weights = ~pre_total, cluster = ~bfs_nr)
cat("Weighted: β =", round(coef(m_weighted)[1], 5),
    "SE =", round(se(m_weighted)[1], 5), "\n")

# Save all robustness results
saveRDS(list(
  placebo = m_placebo,
  first_diff = m_fd,
  loco = loco_results,
  swiss = m_swiss,
  weighted = m_weighted
), file.path(data_dir, "robustness_models.rds"))

cat("\n=== Robustness checks complete ===\n")
