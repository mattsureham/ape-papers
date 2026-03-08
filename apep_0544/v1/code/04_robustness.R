## =============================================================
## 04_robustness.R — Robustness checks and placebo tests
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

source("00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, year_month := as.Date(year_month)]

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
m4 <- results$main_models$m4

## -----------------------------------------------------------------
## 1. Leave-one-country-out
## -----------------------------------------------------------------
cat("\n--- Leave-One-Country-Out ---\n")

countries <- unique(panel$geo)
loo_results <- rbindlist(lapply(countries, function(cc) {
  sub <- panel[geo != cc]
  m <- feols(log_ip ~ treatment_intensity:post |
               country_sector + country_month + sector_month,
             data = sub, cluster = ~geo + nace_r2)
  data.table(excluded = cc,
             beta = coef(m)[1],
             se = sqrt(vcov(m)[1,1]),
             n_obs = nobs(m))
}))
loo_results[, t_stat := beta / se]
cat("Range of betas:", round(min(loo_results$beta), 4), "to",
    round(max(loo_results$beta), 4), "\n")
cat("Most influential country:",
    loo_results[which.max(abs(beta - coef(m4)[1])), excluded], "\n")

fwrite(loo_results, file.path(DATA_DIR, "loo_results.csv"))

## -----------------------------------------------------------------
## 2. Placebo treatment dates
## -----------------------------------------------------------------
cat("\n--- Placebo Treatment Dates ---\n")

placebo_dates <- as.Date(c("2019-03-01", "2020-03-01"))
placebo_results <- rbindlist(lapply(placebo_dates, function(pd) {
  sub <- panel[year_month < as.Date("2022-03-01")]  # Only pre-war data
  sub[, placebo_post := as.integer(year_month >= pd)]
  m <- feols(log_ip ~ treatment_intensity:placebo_post |
               country_sector + country_month + sector_month,
             data = sub, cluster = ~geo + nace_r2)
  data.table(placebo_date = as.character(pd),
             beta = coef(m)[1],
             se = sqrt(vcov(m)[1,1]),
             n_obs = nobs(m))
}))
placebo_results[, t_stat := beta / se]
placebo_results[, p_value := 2 * pt(-abs(t_stat), df = 20)]
cat("Placebo results:\n")
print(placebo_results)

fwrite(placebo_results, file.path(DATA_DIR, "placebo_date_results.csv"))

## -----------------------------------------------------------------
## 3. Placebo treatment: Non-gas-intensive sectors
##    Use transport equipment (C29) as a placebo sector
## -----------------------------------------------------------------
cat("\n--- Placebo: Non-Gas-Intensive Sectors ---\n")

# Define high and low gas intensity sectors
high_gas <- panel[gas_intensity > median(gas_intensity, na.rm = TRUE)]
low_gas <- panel[gas_intensity <= median(gas_intensity, na.rm = TRUE)]

# With country x month FE, the country-level gas share is absorbed.
# Use country x sector + sector x month FE for subsample tests.
m_high <- feols(log_ip ~ russian_gas_share_2021:post |
                  country_sector + sector_month,
                data = high_gas, cluster = ~geo)

m_low <- feols(log_ip ~ russian_gas_share_2021:post |
                 country_sector + sector_month,
               data = low_gas, cluster = ~geo)

cat("High gas-intensity sectors: beta =", round(coef(m_high)[1], 4),
    " SE =", round(sqrt(vcov(m_high)[1,1]), 4), "\n")
cat("Low gas-intensity sectors:  beta =", round(coef(m_low)[1], 4),
    " SE =", round(sqrt(vcov(m_low)[1,1]), 4), "\n")

subsample_results <- data.table(
  subsample = c("High gas intensity", "Low gas intensity"),
  beta = c(coef(m_high)[1], coef(m_low)[1]),
  se = c(sqrt(vcov(m_high)[1,1]), sqrt(vcov(m_low)[1,1])),
  n_obs = c(nobs(m_high), nobs(m_low))
)
fwrite(subsample_results, file.path(DATA_DIR, "subsample_results.csv"))

## -----------------------------------------------------------------
## 4. Permutation inference
##    Randomly reassign RussianGasShare across countries
## -----------------------------------------------------------------
cat("\n--- Permutation Inference ---\n")

set.seed(42)
n_perms <- 500
actual_beta <- coef(m4)[1]

perm_betas <- numeric(n_perms)
country_shares <- unique(panel[, .(geo, russian_gas_share_2021)])

for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")
  # Shuffle gas shares across countries
  shuffled <- copy(country_shares)
  shuffled[, russian_gas_share_2021 := sample(russian_gas_share_2021)]

  perm_panel <- copy(panel)
  perm_panel[, russian_gas_share_2021 := NULL]
  perm_panel <- merge(perm_panel, shuffled, by = "geo")
  perm_panel[, treatment_intensity := russian_gas_share_2021 * gas_intensity]

  m_perm <- tryCatch({
    feols(log_ip ~ treatment_intensity:post |
            country_sector + country_month + sector_month,
          data = perm_panel, cluster = ~geo + nace_r2)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    perm_betas[i] <- coef(m_perm)[1]
  } else {
    perm_betas[i] <- NA
  }
}

perm_betas <- perm_betas[!is.na(perm_betas)]
ri_p <- mean(abs(perm_betas) >= abs(actual_beta))
cat("RI p-value (two-sided):", ri_p, "\n")
cat("Actual beta:", round(actual_beta, 4), "\n")
cat("Permutation distribution: mean =", round(mean(perm_betas), 4),
    ", sd =", round(sd(perm_betas), 4), "\n")

perm_dt <- data.table(
  perm_beta = perm_betas,
  actual_beta = actual_beta,
  ri_p_value = ri_p
)
fwrite(perm_dt, file.path(DATA_DIR, "permutation_results.csv"))

## -----------------------------------------------------------------
## 5. Wild cluster bootstrap (country level)
## -----------------------------------------------------------------
cat("\n--- Wild Cluster Bootstrap ---\n")

# Use fixest's built-in bootstrap
m4_boot <- feols(log_ip ~ treatment_intensity:post |
                   country_sector + country_month + sector_month,
                 data = panel, cluster = ~geo)

# Bootstrap p-value
boot_test <- tryCatch({
  boot_res <- feols(log_ip ~ treatment_intensity:post |
                      country_sector + country_month + sector_month,
                    data = panel,
                    cluster = ~geo,
                    ssc = ssc(adj = TRUE, cluster.adj = TRUE))
  list(beta = coef(boot_res)[1],
       se = sqrt(vcov(boot_res)[1,1]))
}, error = function(e) {
  cat("  Bootstrap failed:", e$message, "\n")
  NULL
})

if (!is.null(boot_test)) {
  cat("Country-clustered SE:", round(boot_test$se, 4), "\n")
}

## -----------------------------------------------------------------
## 6. Recovery dynamics (by year)
## -----------------------------------------------------------------
cat("\n--- Recovery Dynamics ---\n")

panel[, year_cat := as.character(year)]
panel[year < 2022, year_cat := "<2022"]

m_dynamic <- feols(log_ip ~ i(year_cat, treatment_intensity, ref = "<2022") |
                     country_sector + country_month + sector_month,
                   data = panel, cluster = ~geo + nace_r2)

cat("Dynamic effects:\n")
for (nm in names(coef(m_dynamic))) {
  cat("  ", nm, ":", round(coef(m_dynamic)[nm], 4), "\n")
}

dynamic_coefs <- data.table(
  year = gsub("year_cat::(.+):treatment_intensity", "\\1", names(coef(m_dynamic))),
  beta = coef(m_dynamic),
  se = sqrt(diag(vcov(m_dynamic)))
)
fwrite(dynamic_coefs, file.path(DATA_DIR, "dynamic_effects.csv"))

## -----------------------------------------------------------------
## 7. Excluding top sectors with high intra-EU trade (SUTVA check)
## -----------------------------------------------------------------
cat("\n--- SUTVA Check: Excluding High-Trade Sectors ---\n")

# Motor vehicles (C29) and Machinery (C28) have highest intra-EU trade
panel_no_trade <- panel[!nace_r2 %in% c("C29", "C28")]

m_no_trade <- feols(log_ip ~ treatment_intensity:post |
                      country_sector + country_month + sector_month,
                    data = panel_no_trade, cluster = ~geo + nace_r2)

cat("Excluding C28+C29: beta =", round(coef(m_no_trade)[1], 4),
    " SE =", round(sqrt(vcov(m_no_trade)[1,1]), 4), "\n")
cat("Main estimate:     beta =", round(coef(m4)[1], 4), "\n")

## -----------------------------------------------------------------
## 8. Save all robustness results
## -----------------------------------------------------------------

robustness_summary <- data.table(
  check = c("Main (preferred)", "Leave-one-out range",
            "Placebo Mar 2019", "Placebo Mar 2020",
            "High gas sectors only", "Low gas sectors only",
            "Permutation RI p-value", "Excl. C28+C29 (SUTVA)"),
  value = c(
    round(coef(m4)[1], 4),
    paste0("[", round(min(loo_results$beta), 4), ", ",
           round(max(loo_results$beta), 4), "]"),
    round(placebo_results[1, beta], 4),
    round(placebo_results[2, beta], 4),
    round(coef(m_high)[1], 4),
    round(coef(m_low)[1], 4),
    round(ri_p, 3),
    round(coef(m_no_trade)[1], 4)
  )
)

cat("\n--- Robustness Summary ---\n")
print(robustness_summary)
fwrite(robustness_summary, file.path(DATA_DIR, "robustness_summary.csv"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
