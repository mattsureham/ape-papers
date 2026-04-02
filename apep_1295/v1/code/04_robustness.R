# 04_robustness.R — Robustness checks and mechanism tests
# APEP Paper apep_1292: Sunshine Through the Alps

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load data
# ============================================================
panel <- fread(file.path(data_dir, "panel_main.csv"))
panel[, L_REP_CTY := as.character(L_REP_CTY)]
panel[, unit_id := as.character(unit_id)]
panel[, country_id := as.integer(factor(L_REP_CTY))]
panel[, time_period := as.integer((year - 2000) * 4 + qtr_num)]

# Reconstruct Sun-Abraham cohort variable
panel[, first_treat_sa := fcase(
  aeoi_group %in% c("EU_2017", "CRS_2017"), 71L,
  aeoi_group == "CRS_2018", 75L,
  aeoi_group == "CRS_2020", 83L,
  default = 10000L
)]

cat("Loaded panel:", nrow(panel), "obs\n")

# Load AEOI dates
aeoi <- fread(file.path(data_dir, "aeoi_treatment_dates.csv"))
aeoi[, aeoi_time := as.integer(substr(aeoi_quarter, 1, 4)) +
       (as.integer(substr(aeoi_quarter, 7, 7)) - 1) / 4]
aeoi[, first_treat_period := as.integer(
  (as.integer(substr(aeoi_quarter, 1, 4)) - 2000) * 4 +
    as.integer(substr(aeoi_quarter, 7, 7))
)]

# ============================================================
# 2. Randomization inference (permute treatment timing)
# ============================================================
cat("\n=== Randomization Inference ===\n")

# Observed TWFE coefficient (pooled)
twfe_obs <- feols(log_position ~ treated | unit_id + time_period,
                  data = panel, cluster = ~L_REP_CTY)
obs_coef <- coef(twfe_obs)["treated"]
cat("Observed pooled TWFE coefficient:", round(obs_coef, 4), "\n")

# Permute AEOI timing across countries (999 draws)
set.seed(20260402)
n_perms <- 999
perm_coefs <- numeric(n_perms)

# Get actual treatment assignments per country
actual_treats <- unique(panel[, .(L_REP_CTY, first_treat_sa)])
treat_vals <- actual_treats$first_treat_sa

for (i in seq_len(n_perms)) {
  # Shuffle treatment timing across countries
  perm_treats <- data.table(
    L_REP_CTY = actual_treats$L_REP_CTY,
    perm_first = sample(treat_vals)
  )
  panel_perm <- merge(panel, perm_treats, by = "L_REP_CTY")
  panel_perm[, perm_treated := as.integer(time_period >= perm_first)]

  perm_fit <- tryCatch({
    feols(log_position ~ perm_treated | unit_id + time_period,
          data = panel_perm, cluster = ~L_REP_CTY)
  }, error = function(e) NULL)

  perm_coefs[i] <- if (!is.null(perm_fit)) coef(perm_fit)["perm_treated"] else NA_real_
}

perm_coefs_clean <- perm_coefs[!is.na(perm_coefs)]
ri_pval <- mean(abs(perm_coefs_clean) >= abs(obs_coef))
cat("RI p-value (two-sided):", round(ri_pval, 4), "\n")

# ============================================================
# 3. Leave-one-out: drop each country
# ============================================================
cat("\n=== Leave-One-Out ===\n")

countries <- unique(panel$L_REP_CTY)
loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (ctry in countries) {
  panel_loo <- panel[L_REP_CTY != ctry]
  fit_loo <- feols(log_position ~ treated | unit_id + time_period,
                   data = panel_loo, cluster = ~L_REP_CTY)
  loo_results <- rbind(loo_results, data.frame(
    dropped = ctry,
    coef = coef(fit_loo)["treated"],
    se = se(fit_loo)["treated"],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out results:\n")
print(loo_results)
cat("Coefficient range:", round(range(loo_results$coef), 4), "\n")

# ============================================================
# 4. Anticipation test
# ============================================================
cat("\n=== Anticipation Test ===\n")

panel[, anticipation := as.integer(!is.na(aeoi_time) &
                                     time_num >= (aeoi_time - 1) &
                                     time_num < aeoi_time)]
panel[, post_only := as.integer(!is.na(aeoi_time) & time_num >= aeoi_time)]

antic_fit <- feols(log_position ~ anticipation + post_only | unit_id + time_period,
                   data = panel, cluster = ~L_REP_CTY)
cat("Anticipation test:\n")
print(summary(antic_fit))

# ============================================================
# 5. Save robustness results
# ============================================================
rob_results <- list(
  ri_pval = ri_pval,
  ri_n_perms = length(perm_coefs_clean),
  loo_min = min(loo_results$coef),
  loo_max = max(loo_results$coef),
  loo_results = loo_results,
  anticipation_coef = coef(antic_fit)["anticipation"],
  anticipation_se = se(antic_fit)["anticipation"],
  post_only_coef = coef(antic_fit)["post_only"],
  post_only_se = se(antic_fit)["post_only"]
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\n=== Robustness checks complete ===\n")
