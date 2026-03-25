## 04_robustness.R — Robustness checks
## APEP-0923: The End of Banking Secrecy

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, date := as.Date(date)]

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# 1. Placebo test: Fake treatment dates (2 years early)
# ---------------------------------------------------------------
cat("\n--- Placebo: Fake treatment 2 years early ---\n")
panel[, placebo_active := as.integer(!is.na(aeoi_start) &
        date >= (as.Date(aeoi_start) - years(2)))]
# Restrict to pre-actual-treatment period
panel_pre <- panel[is.na(aeoi_start) | date < as.Date(aeoi_start)]

m_placebo <- feols(log_deposits ~ placebo_active | country_id + time_id,
                   data = panel_pre, cluster = ~cp_country)
cat("Placebo coefficient:", round(coef(m_placebo), 4), "\n")
cat("Placebo SE:", round(se(m_placebo), 4), "\n")
cat("Placebo p-value:", round(pvalue(m_placebo), 4), "\n")

# ---------------------------------------------------------------
# 2. Leave-one-cohort-out
# ---------------------------------------------------------------
cat("\n--- Leave-one-cohort-out ---\n")
waves <- c(1, 2, 3, 4)
loco_results <- list()

for (w in waves) {
  m_loco <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                  data = panel[wave != w], cluster = ~cp_country)
  loco_results[[as.character(w)]] <- data.table(
    dropped_wave = w,
    coef = round(coef(m_loco)["aeoi_active"], 4),
    se = round(se(m_loco)["aeoi_active"], 4)
  )
  cat("Drop wave", w, ": coef =", round(coef(m_loco)["aeoi_active"], 4),
      "SE =", round(se(m_loco)["aeoi_active"], 4), "\n")
}

loco_dt <- rbindlist(loco_results)

# ---------------------------------------------------------------
# 3. Alternative clustering: Wave level
# ---------------------------------------------------------------
cat("\n--- Alternative clustering ---\n")
panel[, wave_cluster := ifelse(wave == 0, cp_country, paste0("wave_", wave))]

m_wave_cluster <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                        data = panel, cluster = ~wave_cluster)
cat("Wave-level clustering: coef =", round(coef(m_wave_cluster), 4),
    "SE =", round(se(m_wave_cluster), 4), "\n")

# Country-year double clustering
m_double <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                  data = panel, cluster = ~cp_country + time_id)
cat("Double clustering (country + time): coef =", round(coef(m_double), 4),
    "SE =", round(se(m_double), 4), "\n")

# ---------------------------------------------------------------
# 4. Wild cluster bootstrap (few treated cohorts concern)
# ---------------------------------------------------------------
cat("\n--- Wild cluster bootstrap ---\n")
m_base <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                data = panel, cluster = ~cp_country)

wcb_result <- tryCatch({
  boottest(m_base, param = "aeoi_active",
           B = 999, clustid = ~cp_country,
           type = "webb")
}, error = function(e) {
  cat("Wild bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(wcb_result)) {
  cat("Wild bootstrap p-value:", round(wcb_result$p_val, 4), "\n")
  cat("Wild bootstrap CI:", round(wcb_result$conf_int, 4), "\n")
}

# ---------------------------------------------------------------
# 5. Excluding 2020+ (COVID contamination)
# ---------------------------------------------------------------
cat("\n--- Excluding COVID period (2020+) ---\n")
m_precovid <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                    data = panel[year < 2020], cluster = ~cp_country)
cat("Pre-COVID only: coef =", round(coef(m_precovid), 4),
    "SE =", round(se(m_precovid), 4),
    "p =", round(pvalue(m_precovid), 4), "\n")

# ---------------------------------------------------------------
# 6. Levels and growth rate specifications
# ---------------------------------------------------------------
cat("\n--- Alternative outcome measures ---\n")

# Asinh transformation (handles zeros)
panel[, asinh_deposits := asinh(deposits_usd_mn)]
m_asinh <- feols(asinh_deposits ~ aeoi_active | country_id + time_id,
                 data = panel, cluster = ~cp_country)
cat("Asinh: coef =", round(coef(m_asinh), 4),
    "SE =", round(se(m_asinh), 4), "\n")

# Growth rate
m_growth <- feols(deposit_growth ~ aeoi_active | country_id + time_id,
                  data = panel[is.finite(deposit_growth)], cluster = ~cp_country)
cat("Growth rate: coef =", round(coef(m_growth), 4),
    "SE =", round(se(m_growth), 4), "\n")

# ---------------------------------------------------------------
# 7. Wave-specific effects
# ---------------------------------------------------------------
cat("\n--- Wave-specific treatment effects ---\n")
panel[, aeoi_w1 := as.integer(wave == 1 & aeoi_active == 1)]
panel[, aeoi_w2 := as.integer(wave == 2 & aeoi_active == 1)]
panel[, aeoi_w3 := as.integer(wave == 3 & aeoi_active == 1)]
panel[, aeoi_w4 := as.integer(wave == 4 & aeoi_active == 1)]

m_waves <- feols(log_deposits ~ aeoi_w1 + aeoi_w2 + aeoi_w3 + aeoi_w4 |
                   country_id + time_id,
                 data = panel, cluster = ~cp_country)
cat("Wave-specific effects:\n")
print(coeftable(m_waves))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
robustness <- list(
  placebo_coef = round(coef(m_placebo), 4),
  placebo_se = round(se(m_placebo), 4),
  precovid_coef = round(coef(m_precovid), 4),
  precovid_se = round(se(m_precovid), 4),
  asinh_coef = round(coef(m_asinh), 4),
  asinh_se = round(se(m_asinh), 4),
  loco = loco_dt
)

saveRDS(list(
  m_placebo = m_placebo,
  m_precovid = m_precovid,
  m_asinh = m_asinh,
  m_growth = m_growth,
  m_waves = m_waves,
  m_double = m_double,
  wcb_result = wcb_result,
  loco_dt = loco_dt
), "../data/robustness_objects.rds")

cat("\nRobustness objects saved.\n")
