## 02_clean_data.R — Clean and prepare analysis dataset
## apep_1054: Mexico DST Abolition and Crime

source("00_packages.R")

cat("=== Loading Panel Data ===\n")
panel <- fread("../data/panel_split_states.csv")

cat("Dimensions:", nrow(panel), "x", ncol(panel), "\n")
cat("Municipalities:", uniqueN(panel$muni_id), "\n")
cat("  Border:", uniqueN(panel[border == 1]$muni_id), "\n")
cat("  Non-border:", uniqueN(panel[border == 0]$muni_id), "\n")

## ---------------------------------------------------------------
## 1. Create balanced panel
## ---------------------------------------------------------------
cat("\n=== Creating Balanced Panel ===\n")

## Identify municipalities with complete time series
panel[, date := as.Date(date)]
panel[, n_months := .N, by = muni_id]
max_months <- panel[, max(n_months)]
cat("Max months per municipality:", max_months, "\n")

## Keep municipalities with at least 80% of months
threshold <- floor(max_months * 0.8)
panel_bal <- panel[n_months >= threshold]

cat("After balance filter (>= ", threshold, " months):\n")
cat("  Municipalities:", uniqueN(panel_bal$muni_id), "\n")
cat("  Border:", uniqueN(panel_bal[border == 1]$muni_id), "\n")
cat("  Non-border:", uniqueN(panel_bal[border == 0]$muni_id), "\n")
cat("  Obs:", nrow(panel_bal), "\n")

## ---------------------------------------------------------------
## 2. Create relative time variable
## ---------------------------------------------------------------
## Reform date: October 2022 (last month with DST)
## First affected period: November 2022
## But the real treatment contrast starts March 2023 (first spring without DST)

## For event study: relative months from November 2022
panel_bal[, reform_date := as.Date("2022-11-01")]
panel_bal[, rel_month := as.integer(round(difftime(date, reform_date, units = "days") / 30.44))]

cat("\nRelative time range:", min(panel_bal$rel_month), "to", max(panel_bal$rel_month), "\n")

## ---------------------------------------------------------------
## 3. Create event-study bins
## ---------------------------------------------------------------
## Bin endpoints for event study
panel_bal[, rel_month_bin := rel_month]
panel_bal[rel_month < -24, rel_month_bin := -24L]  # bin endpoints
panel_bal[rel_month > 24, rel_month_bin := 24L]

## Reference period: t = -1 (October 2022, last month pre-reform)
## This is automatic with fixest i() syntax

## ---------------------------------------------------------------
## 4. Pre-treatment summary statistics
## ---------------------------------------------------------------
cat("\n=== Pre-Treatment Summary Statistics ===\n")

pre <- panel_bal[post == 0]

cat("\nBorder municipalities (control):\n")
cat("  Mean total crime:", round(mean(pre[border == 1]$total_crime), 1), "\n")
cat("  Mean street crime:", round(mean(pre[border == 1]$street_crime), 1), "\n")
cat("  SD total crime:", round(sd(pre[border == 1]$total_crime), 1), "\n")

cat("\nNon-border municipalities (treatment):\n")
cat("  Mean total crime:", round(mean(pre[border == 0]$total_crime), 1), "\n")
cat("  Mean street crime:", round(mean(pre[border == 0]$street_crime), 1), "\n")
cat("  SD total crime:", round(sd(pre[border == 0]$total_crime), 1), "\n")

## ---------------------------------------------------------------
## 5. State-level summary
## ---------------------------------------------------------------
cat("\n=== State-Level Summary ===\n")

state_names <- c("5" = "Coahuila", "8" = "Chihuahua", "19" = "Nuevo León",
                 "26" = "Sonora", "28" = "Tamaulipas")

state_sum <- panel_bal[, .(
  n_muni = uniqueN(muni_id),
  n_border = uniqueN(muni_id[border == 1]),
  n_nonborder = uniqueN(muni_id[border == 0]),
  mean_crime = round(mean(total_crime), 1)
), by = cve_ent]

state_sum[, state_name := state_names[as.character(cve_ent)]]
print(state_sum[order(cve_ent)])

## ---------------------------------------------------------------
## 6. Save analysis dataset
## ---------------------------------------------------------------
fwrite(panel_bal, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved:", nrow(panel_bal), "observations\n")
cat("Municipalities:", uniqueN(panel_bal$muni_id), "\n")
cat("Time span:", min(panel_bal$year), "-", max(panel_bal$year), "\n")
