# 04_robustness.R — Robustness checks and placebo tests
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

source("00_packages.R")

data_dir <- "../data"

panel <- fread(file.path(data_dir, "panel_state_month.csv"))
hour_dist <- fread(file.path(data_dir, "hour_distribution_teen.csv"))
hour_dist_school <- fread(file.path(data_dir, "hour_distribution_teen_school.csv"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. Placebo: Adult (25-54) morning fatalities in CA
# ============================================================
cat("--- Placebo 1: Adult Morning Fatalities ---\n")

am <- panel[age_group == "adult" & hour_block == "morning"]
placebo_adult <- feols(fatality_rate ~ treat | STATE + t,
                       data = am, cluster = ~STATE)
cat("Adult morning fatalities (should be null):\n")
print(summary(placebo_adult))

# ============================================================
# 2. Placebo: Teen evening fatalities in CA
# ============================================================
cat("\n--- Placebo 2: Teen Evening Fatalities ---\n")

te <- panel[age_group == "teen" & hour_block == "evening"]
placebo_evening <- feols(fatality_rate ~ treat | STATE + t,
                         data = te, cluster = ~STATE)
cat("Teen evening fatalities (should be null):\n")
print(summary(placebo_evening))

# ============================================================
# 3. Permutation inference (reassign treatment to each state)
# ============================================================
cat("\n--- Permutation Inference ---\n")

tm <- panel[age_group == "teen" & hour_block == "morning"]
true_est <- feols(fatality_rate ~ treat | STATE + t, data = tm, cluster = ~STATE)
true_beta <- coef(true_est)["treat"]

all_states <- sort(unique(tm$STATE))
perm_betas <- numeric(length(all_states))

for (i in seq_along(all_states)) {
  s <- all_states[i]
  tm_perm <- copy(tm)
  tm_perm[, treat_perm := as.integer(STATE == s) * post]

  perm_fit <- tryCatch(
    feols(fatality_rate ~ treat_perm | STATE + t, data = tm_perm, cluster = ~STATE),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    perm_betas[i] <- coef(perm_fit)["treat_perm"]
  } else {
    perm_betas[i] <- NA
  }
}

perm_betas_valid <- perm_betas[!is.na(perm_betas)]
perm_p <- mean(abs(perm_betas_valid) >= abs(true_beta))
cat(sprintf("Permutation p-value (two-sided): %.4f\n", perm_p))
cat(sprintf("True beta: %.4f | Rank: %d / %d\n",
            true_beta, sum(abs(perm_betas_valid) >= abs(true_beta)), length(perm_betas_valid)))

# ============================================================
# 4. Alternative time windows
# ============================================================
cat("\n--- Alternative time windows ---\n")

# Wider morning window (5-9am)
fars_fatal <- fread(file.path(data_dir, "fars_fatal_2015_2023.csv"))
fars_fatal_v <- fars_fatal[HOUR >= 0 & HOUR <= 23]
fars_fatal_v[, age_group := fcase(AGE >= 15 & AGE <= 19, "teen",
                                   AGE >= 25 & AGE <= 54, "adult",
                                   default = "other")]

# 5-9am window
wide_morn <- fars_fatal_v[age_group == "teen" & HOUR >= 5 & HOUR <= 9,
  .(fatalities = .N),
  by = .(STATE, YEAR, MONTH)
]
pop <- fread(file.path(data_dir, "state_population_2015_2023.csv"))
wide_grid <- CJ(STATE = sort(unique(fars_fatal_v$STATE)), YEAR = 2015:2023, MONTH = 1:12)
wide_panel <- merge(wide_grid, wide_morn, by = c("STATE", "YEAR", "MONTH"), all.x = TRUE)
wide_panel[is.na(fatalities), fatalities := 0]
wide_panel <- merge(wide_panel, pop[, .(STATE, YEAR, pop_teen)], by = c("STATE", "YEAR"), all.x = TRUE)
wide_panel[, fatality_rate := fatalities / pop_teen * 100000]
wide_panel[, t := (YEAR - 2015) * 12 + MONTH]
wide_panel[, ca := as.integer(STATE == 6)]
wide_panel[, post := as.integer(YEAR > 2022 | (YEAR == 2022 & MONTH >= 7))]
wide_panel[, treat := ca * post]

twfe_wide <- feols(fatality_rate ~ treat | STATE + t, data = wide_panel, cluster = ~STATE)
cat("TWFE with wider morning (5-9am):\n")
print(summary(twfe_wide))

# Narrow window (7-8am only)
narrow_morn <- fars_fatal_v[age_group == "teen" & HOUR >= 7 & HOUR <= 8,
  .(fatalities = .N),
  by = .(STATE, YEAR, MONTH)
]
narrow_panel <- merge(wide_grid, narrow_morn, by = c("STATE", "YEAR", "MONTH"), all.x = TRUE)
narrow_panel[is.na(fatalities), fatalities := 0]
narrow_panel <- merge(narrow_panel, pop[, .(STATE, YEAR, pop_teen)], by = c("STATE", "YEAR"), all.x = TRUE)
narrow_panel[, fatality_rate := fatalities / pop_teen * 100000]
narrow_panel[, t := (YEAR - 2015) * 12 + MONTH]
narrow_panel[, ca := as.integer(STATE == 6)]
narrow_panel[, post := as.integer(YEAR > 2022 | (YEAR == 2022 & MONTH >= 7))]
narrow_panel[, treat := ca * post]

twfe_narrow <- feols(fatality_rate ~ treat | STATE + t, data = narrow_panel, cluster = ~STATE)
cat("\nTWFE with narrow morning (7-8am):\n")
print(summary(twfe_narrow))

# ============================================================
# 5. Hour-of-day distribution shift test
# ============================================================
cat("\n--- Hour-of-Day Distribution Shift ---\n")

# Compare CA teen hour distribution pre vs post
ca_hours_pre <- hour_dist_school[ca == 1 & post == 0, .(fat = sum(fatalities)), by = HOUR]
ca_hours_post <- hour_dist_school[ca == 1 & post == 1, .(fat = sum(fatalities)), by = HOUR]

# Ensure all hours present
all_hours <- data.table(HOUR = 0:23)
ca_hours_pre <- merge(all_hours, ca_hours_pre, by = "HOUR", all.x = TRUE)
ca_hours_post <- merge(all_hours, ca_hours_post, by = "HOUR", all.x = TRUE)
ca_hours_pre[is.na(fat), fat := 0]
ca_hours_post[is.na(fat), fat := 0]

# Normalize to shares
ca_hours_pre[, share := fat / sum(fat)]
ca_hours_post[, share := fat / sum(fat)]

# Morning shift: share at 6-7am should decrease, 8-9am might increase or stay
cat("CA teen fatality hour shares (school months):\n")
cat("Hour  Pre-share  Post-share  Change\n")
for (h in 5:10) {
  pre_s <- ca_hours_pre[HOUR == h, share]
  post_s <- ca_hours_post[HOUR == h, share]
  cat(sprintf("  %2d    %.4f     %.4f    %+.4f\n", h, pre_s, post_s, post_s - pre_s))
}

# KS test on distributions
# Pool individual fatality hours
ca_fat_pre_hours <- rep(hour_dist_school[ca == 1 & post == 0]$HOUR,
                         hour_dist_school[ca == 1 & post == 0]$fatalities)
ca_fat_post_hours <- rep(hour_dist_school[ca == 1 & post == 1]$HOUR,
                          hour_dist_school[ca == 1 & post == 1]$fatalities)

if (length(ca_fat_pre_hours) > 0 & length(ca_fat_post_hours) > 0) {
  ks_result <- ks.test(ca_fat_pre_hours, ca_fat_post_hours)
  cat(sprintf("\nKS test (CA teen hour distribution, pre vs post): D=%.4f, p=%.4f\n",
              ks_result$statistic, ks_result$p.value))
}

# ============================================================
# 6. Placebo treatment timing (2019, 2020)
# ============================================================
cat("\n--- Placebo Treatment Timing ---\n")

for (placebo_year in c(2019, 2020)) {
  tm_p <- tm[YEAR <= 2021]  # Only pre-treatment data
  tm_p[, post_placebo := as.integer(YEAR > placebo_year | (YEAR == placebo_year & MONTH >= 7))]
  tm_p[, treat_placebo := ca * post_placebo]

  placebo_time <- feols(fatality_rate ~ treat_placebo | STATE + t,
                        data = tm_p, cluster = ~STATE)
  cat(sprintf("Placebo treatment at July %d: beta=%.4f, SE=%.4f, p=%.4f\n",
              placebo_year, coef(placebo_time)["treat_placebo"],
              sqrt(vcov(placebo_time)["treat_placebo", "treat_placebo"]),
              2 * pnorm(-abs(coef(placebo_time)["treat_placebo"] /
                             sqrt(vcov(placebo_time)["treat_placebo", "treat_placebo"])))))
}

# ============================================================
# 7. Event study (dynamic treatment effects)
# ============================================================
cat("\n--- Event Study ---\n")

# Create relative time indicators (quarters relative to July 2022)
tm[, rel_quarter := floor((YEAR - 2022) * 4 + (MONTH - 7) / 3)]
# Bin endpoints
tm[, rel_q_binned := pmax(-8, pmin(6, rel_quarter))]

# Event study with quarterly leads/lags
es_reg <- feols(fatality_rate ~ i(rel_q_binned, ca, ref = -1) | STATE + t,
                data = tm, cluster = ~STATE)
cat("Event study coefficients:\n")
print(summary(es_reg))

# ============================================================
# 8. Save robustness results
# ============================================================
robustness <- list(
  placebo_adult = list(beta = coef(placebo_adult)["treat"],
                       se = sqrt(vcov(placebo_adult)["treat", "treat"])),
  placebo_evening = list(beta = coef(placebo_evening)["treat"],
                         se = sqrt(vcov(placebo_evening)["treat", "treat"])),
  permutation_p = perm_p,
  perm_betas = perm_betas_valid,
  twfe_wide = list(beta = coef(twfe_wide)["treat"],
                   se = sqrt(vcov(twfe_wide)["treat", "treat"])),
  twfe_narrow = list(beta = coef(twfe_narrow)["treat"],
                     se = sqrt(vcov(twfe_narrow)["treat", "treat"])),
  event_study = es_reg,
  hour_dist_pre = ca_hours_pre,
  hour_dist_post = ca_hours_post
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
saveRDS(es_reg, file.path(data_dir, "event_study.rds"))

cat("\n=== Robustness checks complete ===\n")
