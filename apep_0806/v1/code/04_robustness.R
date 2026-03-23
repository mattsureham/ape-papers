## 04_robustness.R — Robustness checks
## apep_0806: Ireland Rent Pressure Zones

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# ── 1. Bacon decomposition (TWFE bias diagnostic) ────────────────────────
cat("=== Bacon Decomposition ===\n")

if (!requireNamespace("bacondecomp", quietly = TRUE)) {
  install.packages("bacondecomp", repos = "https://cloud.r-project.org")
}
library(bacondecomp)

# Need binary treatment indicator and 2x2 DiD setup
# bacon() needs: outcome ~ treatment, data, id, time
bacon_out <- bacon(
  log_rent ~ post_rpz,
  data = panel,
  id_var = "county_id",
  time_var = "time_id"
)

cat("\nBacon decomposition of TWFE estimate:\n")
print(
  bacon_out %>%
    group_by(type) %>%
    summarise(
      n_pairs = n(),
      avg_estimate = weighted.mean(estimate, weight),
      total_weight = sum(weight),
      .groups = "drop"
    )
)

# ── 2. Sun-Abraham estimator (alternative to C-S) ────────────────────────
cat("\n=== Sun-Abraham (fixest::sunab) ===\n")

sa <- feols(
  log_rent ~ sunab(first_treat, time_id) | county_id + time_id,
  data = panel,
  cluster = ~county_id
)

cat("Sun-Abraham overall ATT:\n")
sa_agg <- summary(sa, agg = "ATT")
print(sa_agg)
# Extract SA coefficient for later use
sa_coeftable <- sa_agg$coeftable
sa_att_val <- sa_coeftable[1, 1]  # Estimate
sa_se_val  <- sa_coeftable[1, 2]  # Std. Error
cat("SA ATT:", sa_att_val, "SE:", sa_se_val, "\n")

# ── 3. Placebo: restrict to pre-RPZ period ───────────────────────────────
cat("\n=== Placebo: Fake treatment 2 years before actual ===\n")

panel_placebo <- panel %>%
  mutate(
    fake_treat = first_treat - 8,  # 8 quarters = 2 years earlier
    fake_post  = as.integer(time_id >= fake_treat)
  ) %>%
  filter(time_id < first_treat)  # Only pre-treatment data

twfe_placebo <- feols(
  log_rent ~ fake_post | county_id + time_id,
  data = panel_placebo,
  cluster = ~county_id
)

cat("Placebo TWFE (fake treatment 2y before actual):\n")
print(summary(twfe_placebo))

# ── 4. Heterogeneity: early vs. late cohorts ─────────────────────────────
cat("\n=== Heterogeneity by treatment cohort ===\n")

# Early treated (2016-2017): Dublin, Cork, Galway, Kildare, Louth, Meath, Wicklow
early_panel <- panel %>% filter(first_treat <= (2017 * 4 + 4))
late_panel <- panel %>% filter(first_treat >= (2019 * 4 + 1))

# C-S for early cohorts only (using not-yet-treated as control)
cs_early <- att_gt(
  yname = "rent_growth_yy",
  tname = "time_id",
  idname = "county_id",
  gname = "first_treat",
  data = panel %>% filter(!is.na(rent_growth_yy)),
  control_group = "notyettreated",
  base_period = "universal"
)

agg_early_group <- aggte(cs_early, type = "group")
cat("\nGroup-level ATTs on YoY growth:\n")
summary(agg_early_group)

# ── 5. Wild cluster bootstrap (few clusters) ─────────────────────────────
cat("\n=== Wild cluster bootstrap inference ===\n")

if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

# TWFE with wild bootstrap
twfe_growth <- feols(
  rent_growth_yy ~ post_rpz | county_id + time_id,
  data = panel %>% filter(!is.na(rent_growth_yy)),
  cluster = ~county_id
)

boot_res <- boottest(
  twfe_growth,
  param = "post_rpz",
  B = 9999,
  clustid = "county_id",
  type = "mammen"
)
cat("Wild cluster bootstrap for TWFE growth:\n")
print(summary(boot_res))

# ── 6. Save robustness results ───────────────────────────────────────────
rob_results <- list(
  bacon = bacon_out,
  sa_att = sa_att_val,
  sa_se  = sa_se_val,
  twfe_placebo = twfe_placebo,
  cs_group_growth = agg_early_group,
  twfe_growth = twfe_growth,
  boot_growth = boot_res
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\n✓ Robustness results saved\n")
