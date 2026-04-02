# 04_robustness.R — Robustness checks and permutation inference
source("00_packages.R")

dt <- fread("../data/wages_estimation.csv")
dt[, high_exposure := as.integer(exposure >= 0.5)]

# ============================================================
# 1. LEAVE-ONE-OUT: Drop each high-exposure sector
# ============================================================
cat("\n=== Leave-One-Out Sensitivity ===\n")

high_sectors <- unique(dt[high_exposure == 1, sector])
loo_results <- list()

for (s in high_sectors) {
  dt_loo <- dt[sector != s]
  dt_loo[, reform_x_exp_loo := reform_2019 * exposure]
  dt_loo[, post_x_exp_loo := post_2020 * exposure]
  m_loo <- feols(ln_gross ~ reform_x_exp_loo + post_x_exp_loo | sector + ym,
                 data = dt_loo, cluster = ~sector)
  loo_results[[s]] <- data.table(
    dropped = s,
    coef_reform = coef(m_loo)["reform_x_exp_loo"],
    se_reform = se(m_loo)["reform_x_exp_loo"],
    coef_post = coef(m_loo)["post_x_exp_loo"],
    se_post = se(m_loo)["post_x_exp_loo"]
  )
  cat(sprintf("Drop %s: β_reform=%.4f (%.4f), β_post=%.4f (%.4f)\n",
              s, coef(m_loo)["reform_x_exp_loo"], se(m_loo)["reform_x_exp_loo"],
              coef(m_loo)["post_x_exp_loo"], se(m_loo)["post_x_exp_loo"]))
}

dt_loo_results <- rbindlist(loo_results)
fwrite(dt_loo_results, "../data/loo_results.csv")

# ============================================================
# 2. PERMUTATION INFERENCE: Randomize treatment timing
# ============================================================
cat("\n=== Permutation Inference (500 draws) ===\n")

# True coefficient from main spec
m_true <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
                data = dt, cluster = ~sector)
true_coef <- coef(m_true)["reform_x_exposure"]

# Permute: assign random 12-month treatment windows
set.seed(42)
n_perm <- 500
perm_coefs <- numeric(n_perm)

# Available years for placebo treatment: 2013-2018, 2020-2023 (exclude 2012 endpoint, 2019 real)
placebo_years <- c(2013:2018, 2020:2023)

for (i in seq_len(n_perm)) {
  py <- sample(placebo_years, 1)
  dt[, perm_reform := as.integer(year == py)]
  dt[, perm_post := as.integer(year > py)]
  dt[, perm_rx := perm_reform * exposure]
  dt[, perm_px := perm_post * exposure]

  m_perm <- feols(ln_gross ~ perm_rx + perm_px | sector + ym,
                  data = dt, cluster = ~sector, warn = FALSE)
  perm_coefs[i] <- coef(m_perm)["perm_rx"]
}

perm_p <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("Permutation p-value: %.4f (|true|=%.4f, mean|perm|=%.4f)\n",
            perm_p, abs(true_coef), mean(abs(perm_coefs))))

# ============================================================
# 3. ALTERNATIVE SAMPLE PERIODS
# ============================================================
cat("\n=== Sample period robustness ===\n")

# Short window: 2016-2022
dt_short <- dt[year >= 2016 & year <= 2022]
m_short <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
                 data = dt_short, cluster = ~sector)
cat(sprintf("2016-2022: β_reform=%.4f (%.4f)\n",
            coef(m_short)["reform_x_exposure"], se(m_short)["reform_x_exposure"]))

# Long window: full sample
dt_long <- fread("../data/wages_clean.csv")
dt_long[, reform_x_exposure := reform_2019 * exposure]
dt_long[, post_x_exposure := post_2020 * exposure]
m_long <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
                data = dt_long, cluster = ~sector)
cat(sprintf("Full sample: β_reform=%.4f (%.4f)\n",
            coef(m_long)["reform_x_exposure"], se(m_long)["reform_x_exposure"]))

# ============================================================
# 4. PLACEBO: Low-exposure sectors only (should show no effect)
# ============================================================
cat("\n=== Placebo: Low-exposure sectors ===\n")
dt_low <- dt[high_exposure == 0]
dt_low[, reform_x_exp_low := reform_2019 * exposure]
dt_low[, post_x_exp_low := post_2020 * exposure]
m_placebo <- feols(ln_gross ~ reform_x_exp_low + post_x_exp_low | sector + ym,
                   data = dt_low, cluster = ~sector)
summary(m_placebo)

# ============================================================
# 5. MONTHLY SEASONALITY CHECK
# ============================================================
cat("\n=== January effect check ===\n")
# Is the Jan 2019 drop just seasonal? Check Jan vs other months across years
dt[, january := as.integer(month == 1)]
dt[, jan_x_exposure := january * exposure]
m_jan <- feols(ln_gross ~ jan_x_exposure | sector + ym,
               data = dt[year < 2019], cluster = ~sector)
cat(sprintf("Pre-2019 January × Exposure: %.4f (%.4f) — should be near zero\n",
            coef(m_jan)["jan_x_exposure"], se(m_jan)["jan_x_exposure"]))

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================
robustness <- list(
  loo = dt_loo_results,
  perm_p = perm_p,
  perm_coefs = perm_coefs,
  true_coef = true_coef,
  short_window = list(coef = coef(m_short)["reform_x_exposure"],
                      se = se(m_short)["reform_x_exposure"]),
  long_window = list(coef = coef(m_long)["reform_x_exposure"],
                     se = se(m_long)["reform_x_exposure"]),
  placebo = list(coef = coef(m_placebo)["reform_x_exp_low"],
                 se = se(m_placebo)["reform_x_exp_low"]),
  january = list(coef = coef(m_jan)["jan_x_exposure"],
                 se = se(m_jan)["jan_x_exposure"])
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
