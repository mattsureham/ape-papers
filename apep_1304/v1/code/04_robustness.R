# 04_robustness.R — Robustness checks and placebos
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

source("00_packages.R")

results <- readRDS("../data/results.rds")
est <- results$est_sample

cat("=== Robustness Checks ===\n")

# ===================================================================
# 1. Pre-period placebo: leniency in year t should not predict
#    remittances in year t-2 (falsification)
# ===================================================================
cat("\n--- Placebo: Lead instrument ---\n")

# Create 2-year lead of leniency
est_lead <- copy(est)
est_lead[, leniency_lead2 := shift(leniency_iv, n = 2, type = "lead"), by = iso3]

placebo_lead <- feols(log_remit ~ leniency_lead2 + gdp_growth | iso3 + year,
                      data = est_lead[!is.na(leniency_lead2)],
                      cluster = ~iso3)
cat("  Lead placebo (leniency_{t+2} → remit_t):\n")
print(summary(placebo_lead))

# ===================================================================
# 2. Lag structure: Does leniency in year t affect remittances
#    in t+1 and t+2? (Dynamic effects)
# ===================================================================
cat("\n--- Dynamic effects: lagged leniency ---\n")

est_lag <- copy(est)
est_lag[, leniency_lag1 := shift(leniency_iv, n = 1, type = "lag"), by = iso3]
est_lag[, leniency_lag2 := shift(leniency_iv, n = 2, type = "lag"), by = iso3]

# Contemporaneous + lag1
dynamic1 <- feols(log_remit ~ leniency_iv + leniency_lag1 + gdp_growth | iso3 + year,
                  data = est_lag[!is.na(leniency_lag1)],
                  cluster = ~iso3)

# Lag1 + lag2 only
dynamic2 <- feols(log_remit ~ leniency_lag1 + leniency_lag2 + gdp_growth | iso3 + year,
                  data = est_lag[!is.na(leniency_lag1) & !is.na(leniency_lag2)],
                  cluster = ~iso3)

cat("  Dynamic (contemporaneous + lag1):\n")
print(summary(dynamic1))

# ===================================================================
# 3. Leave-one-country-out (LOCO) sensitivity
# ===================================================================
cat("\n--- Leave-one-country-out ---\n")

countries_in_sample <- unique(est$iso3)
loco_coefs <- sapply(countries_in_sample, function(c) {
  est_sub <- est[iso3 != c]
  fit <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
               data = est_sub, cluster = ~iso3)
  coef(fit)["fit_grant_rate"]
})

cat(sprintf("  LOCO range: [%.3f, %.3f]\n", min(loco_coefs), max(loco_coefs)))
cat(sprintf("  Full sample IV coef: %.3f\n", coef(results$iv1)["fit_grant_rate"]))
cat(sprintf("  All LOCO same sign: %s\n",
            if (all(loco_coefs > 0) || all(loco_coefs < 0)) "YES" else "NO"))

# ===================================================================
# 4. Alternative clustering: two-way (country + year)
# ===================================================================
cat("\n--- Two-way clustering ---\n")

iv_twoway <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
                   data = est, cluster = ~iso3 + year)
cat("  Two-way clustered SE:\n")
print(summary(iv_twoway))

# ===================================================================
# 5. Wild cluster bootstrap (for small cluster count)
# ===================================================================
cat("\n--- Wild cluster bootstrap ---\n")

# Reduced form for wild bootstrap (fixest + fwildclusterboot)
rf_for_boot <- feols(log_remit ~ leniency_iv + gdp_growth | iso3 + year,
                     data = est, cluster = ~iso3)

tryCatch({
  boot_rf <- boottest(rf_for_boot, param = "leniency_iv",
                      clustid = "iso3", B = 9999, type = "webb")
  cat(sprintf("  Wild bootstrap CI: [%.4f, %.4f]\n",
              boot_rf$conf_int[1], boot_rf$conf_int[2]))
  cat(sprintf("  Wild bootstrap p-value: %.4f\n", boot_rf$p_val))
}, error = function(e) {
  cat(sprintf("  Wild bootstrap failed: %s\n", e$message))
})

# ===================================================================
# 6. Placebo outcome: FDI inflows (should NOT be affected)
# ===================================================================
cat("\n--- Placebo outcome: FDI ---\n")

# Fetch FDI data
fdi_list <- lapply(unique(est$iso3), function(iso3) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/BX.KLT.DINV.CD.WD?format=json&date=2000:2023&per_page=100",
    iso3
  )
  resp <- httr::GET(url, httr::timeout(20))
  if (httr::status_code(resp) != 200) return(NULL)
  content <- httr::content(resp, as = "parsed")
  if (length(content) < 2 || is.null(content[[2]])) return(NULL)
  records <- content[[2]]
  rbindlist(lapply(records, function(r) {
    data.table(
      iso3 = iso3,
      year = as.integer(r$date),
      fdi_usd = if (is.null(r$value)) NA_real_ else as.numeric(r$value)
    )
  }))
})
fdi <- rbindlist(fdi_list[!sapply(fdi_list, is.null)])

est_fdi <- merge(est, fdi, by = c("iso3", "year"), all.x = TRUE)
est_fdi[, log_fdi := log(pmax(fdi_usd, 1))]

placebo_fdi <- feols(log_fdi ~ leniency_iv + gdp_growth | iso3 + year,
                     data = est_fdi[!is.na(log_fdi)],
                     cluster = ~iso3)
cat("  Placebo (FDI):\n")
print(summary(placebo_fdi))

# ===================================================================
# 7. Save all robustness results
# ===================================================================
robust <- list(
  placebo_lead = placebo_lead,
  dynamic1 = dynamic1,
  dynamic2 = dynamic2,
  loco_coefs = loco_coefs,
  iv_twoway = iv_twoway,
  placebo_fdi = placebo_fdi
)
saveRDS(robust, "../data/robustness.rds")

cat("\n=== Robustness complete ===\n")
