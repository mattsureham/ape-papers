## 04_robustness.R — Robustness and placebo tests
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

## Load the analysis dataset (from full EOIR path)
if (file.exists(file.path(data_dir, "analysis.csv"))) {
  panel <- fread(file.path(data_dir, "analysis.csv"))
  if (!"code" %in% names(panel)) panel[, code := final_court]
  if (!"year" %in% names(panel)) panel[, year := comp_year]
} else {
  panel <- fread(file.path(data_dir, "analysis_panel.csv"))
}

if (!"log_rent" %in% names(panel)) panel[, log_rent := log(median_rent)]
if (!"log_home_value" %in% names(panel)) panel[, log_home_value := log(median_home_value)]
if (!"log_pop" %in% names(panel)) panel[, log_pop := log(total_pop)]
if (max(panel$leniency_iv, na.rm=TRUE) > 1) panel[, leniency_iv := leniency_iv / 100]

panel <- panel[!is.na(log_rent) & !is.na(log_home_value) & !is.na(grant_rate) &
               !is.na(leniency_iv) & is.finite(log_rent) & is.finite(log_home_value)]
cat(sprintf("Panel: %d obs, %d courts\n", nrow(panel), uniqueN(panel$code)))

## ============================================================
## 1. Placebo: Lagged outcomes
## ============================================================
cat("\n=== Placebo: Lagged outcomes ===\n")

setorderv(panel, c("code", "year"))
panel[, lag_log_rent := shift(log_rent, 1, type = "lag"), by = code]
panel[, lag_log_hv := shift(log_home_value, 1, type = "lag"), by = code]

placebo_rent <- feols(lag_log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                      data = panel[!is.na(lag_log_rent)], cluster = ~code)
placebo_hv <- feols(lag_log_hv ~ 1 | code + year | grant_rate ~ leniency_iv,
                    data = panel[!is.na(lag_log_hv)], cluster = ~code)

cat("Placebo lag rent:", round(coef(placebo_rent)["fit_grant_rate"], 4),
    "(", round(se(placebo_rent)["fit_grant_rate"], 4), ")\n")
cat("Placebo lag HV:", round(coef(placebo_hv)["fit_grant_rate"], 4),
    "(", round(se(placebo_hv)["fit_grant_rate"], 4), ")\n")

## ============================================================
## 2. Heterogeneity: Housing tightness
## ============================================================
cat("\n=== Heterogeneity: Housing market tightness ===\n")

panel[, high_rent := as.integer(median_rent > median(median_rent, na.rm = TRUE))]

iv_rent_high <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                      data = panel[high_rent == 1], cluster = ~code)
iv_rent_low <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                     data = panel[high_rent == 0], cluster = ~code)

cat("High-rent markets:", round(coef(iv_rent_high)["fit_grant_rate"], 4),
    "(", round(se(iv_rent_high)["fit_grant_rate"], 4), ")\n")
cat("Low-rent markets:", round(coef(iv_rent_low)["fit_grant_rate"], 4),
    "(", round(se(iv_rent_low)["fit_grant_rate"], 4), ")\n")

## ============================================================
## 3. Heterogeneity: Immigrant concentration
## ============================================================
cat("\n=== Heterogeneity: Immigrant concentration ===\n")

panel[, high_immig := as.integer(noncitizen_share > median(noncitizen_share, na.rm = TRUE))]

iv_rent_himm <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                      data = panel[high_immig == 1], cluster = ~code)
iv_rent_limm <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                      data = panel[high_immig == 0], cluster = ~code)

cat("High-immigrant:", round(coef(iv_rent_himm)["fit_grant_rate"], 4),
    "(", round(se(iv_rent_himm)["fit_grant_rate"], 4), ")\n")
cat("Low-immigrant:", round(coef(iv_rent_limm)["fit_grant_rate"], 4),
    "(", round(se(iv_rent_limm)["fit_grant_rate"], 4), ")\n")

## ============================================================
## 4. Alternative: Rent burden, levels
## ============================================================
cat("\n=== Alternative specifications ===\n")

if ("median_hh_income" %in% names(panel)) {
  panel[, rent_burden := median_rent * 12 / median_hh_income]
  iv_burden <- feols(rent_burden ~ 1 | code + year | grant_rate ~ leniency_iv,
                     data = panel[!is.na(rent_burden) & is.finite(rent_burden)], cluster = ~code)
  cat("Rent burden:", round(coef(iv_burden)["fit_grant_rate"], 4),
      "(", round(se(iv_burden)["fit_grant_rate"], 4), ")\n")
}

iv_rent_levels <- feols(median_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                        data = panel, cluster = ~code)
cat("Rent levels ($):", round(coef(iv_rent_levels)["fit_grant_rate"], 1),
    "(", round(se(iv_rent_levels)["fit_grant_rate"], 1), ")\n")

## ============================================================
## 5. Export robustness table
## ============================================================
etable(placebo_rent, placebo_hv, iv_rent_high, iv_rent_low, iv_rent_himm, iv_rent_limm,
       headers = c("Lag Rent", "Lag Value", "High Rent", "Low Rent", "High Immig", "Low Immig"),
       dict = c(fit_grant_rate = "Grant Rate",
                lag_log_rent = "Lag Log Rent",
                lag_log_hv = "Lag Log Value",
                log_rent = "Log Rent"),
       se.below = TRUE, tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       replace = TRUE)

cat("\n=== Robustness complete ===\n")
