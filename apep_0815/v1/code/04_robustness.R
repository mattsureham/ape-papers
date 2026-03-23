## 04_robustness.R — Robustness checks and placebo tests
source("code/00_packages.R")

df_main <- readRDS("data/panel_main.rds")
df_full <- readRDS("data/panel_full.rds")

cat("=== Robustness Checks ===\n\n")

# ── R1: Include partial-waiver states ────────────────────────────
df_all <- df_full |>
  mutate(enforce_any = as.integer(enforcement == "full"),
         ddd_all = post * young * enforce_any,
         post_young = post * young,
         post_enforce = post * enforce_any,
         young_enforce = young * enforce_any,
         f_state = factor(state_fips),
         f_age = factor(age_group),
         f_qtr = factor(qtr_num))

r1 <- feols(log_emp ~ ddd_all + post_young + post_enforce + young_enforce |
              f_state^f_age + f_age^f_qtr + f_state^f_qtr,
            data = df_all, cluster = ~state_fips)

cat("R1 (all states): DDD =", round(coef(r1)["ddd_all"], 5),
    "SE =", round(se(r1)["ddd_all"], 5), "\n")

# ── R2: Pre-trend test ───────────────────────────────────────────
pre_data <- df_main |>
  filter(post == 0) |>
  mutate(f_state = factor(state_fips), f_age = factor(age_group))

r2_trend <- feols(log_emp ~ qtr_num:young:enforce + qtr_num:young + qtr_num:enforce |
                    f_state^f_age, data = pre_data, cluster = ~state_fips)
cat("R2 (pre-trend DDD slope):", round(coef(r2_trend)["qtr_num:young:enforce"], 6),
    "SE:", round(se(r2_trend)["qtr_num:young:enforce"], 6), "\n")

# ── R3: Phase-specific effects ───────────────────────────────────
df_main <- df_main |>
  mutate(
    phase1 = as.integer(year == 2023 & quarter == 3),
    phase2plus = as.integer((year == 2023 & quarter == 4) | year >= 2024),
    ddd_p1 = phase1 * young * enforce,
    ddd_p2 = phase2plus * young * enforce,
    f_state = factor(state_fips),
    f_age = factor(age_group),
    f_qtr = factor(qtr_num)
  )

r3 <- feols(log_emp ~ ddd_p1 + ddd_p2 +
              phase1:young + phase2plus:young +
              phase1:enforce + phase2plus:enforce +
              young_enforce |
              f_state^f_age + f_age^f_qtr + f_state^f_qtr,
            data = df_main, cluster = ~state_fips)

cat("R3 Phase 1 DDD:", round(coef(r3)["ddd_p1"], 5),
    "SE:", round(se(r3)["ddd_p1"], 5), "\n")
cat("R3 Phase 2+ DDD:", round(coef(r3)["ddd_p2"], 5),
    "SE:", round(se(r3)["ddd_p2"], 5), "\n")

# ── R4-R5: Already in main results ──────────────────────────────
results <- readRDS("data/main_results.rds")
cat("R4 Hires DDD:", round(coef(results$m2_hires)["ddd"], 5),
    "SE:", round(se(results$m2_hires)["ddd"], 5), "\n")
cat("R4 Separations DDD:", round(coef(results$m3_sep)["ddd"], 5),
    "SE:", round(se(results$m3_sep)["ddd"], 5), "\n")
cat("R5 Earnings DDD:", round(coef(results$m4_earn)["ddd"], 5),
    "SE:", round(se(results$m4_earn)["ddd"], 5), "\n")

# ── Save robustness results ──────────────────────────────────────
robust <- list(
  r1_all_states = r1,
  r2_pretrend = r2_trend,
  r3_phase = r3
)
saveRDS(robust, "data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
