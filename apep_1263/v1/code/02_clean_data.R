## 02_clean_data.R — Variable construction
## apep_1263: The Opt-Out Illusion

source("00_packages.R")

panel <- fread("../data/panel.csv")

## ---- 1. Event time variable ----
# Relative time = year - cohort (0 = first full FY of treatment)
panel[, event_time := year - cohort]

## ---- 2. Log transformations ----
panel[, ln_dd_pmp := log(dd_pmp)]
panel[, ln_tx_pmp := log(tx_pmp)]
panel[, ln_ld_pmp := log(ld_pmp)]

## ---- 3. COVID indicator ----
# 2020-21 was the primary COVID-disrupted year for transplantation
panel[, covid := as.integer(year == 2020)]

## ---- 4. Pre-treatment means for SDE computation ----
# Calculate pre-treatment SD of outcomes for each nation
pre_means <- panel[optout == 0, .(
  pre_mean_dd = mean(dd_pmp),
  pre_sd_dd = sd(dd_pmp),
  pre_mean_tx = mean(tx_pmp),
  pre_sd_tx = sd(tx_pmp),
  pre_mean_ld = mean(ld_pmp),
  pre_sd_ld = sd(ld_pmp),
  n_pre = .N
), by = nation]

cat("Pre-treatment summary statistics by nation:\n")
print(pre_means)

panel <- merge(panel, pre_means, by = "nation", all.x = TRUE)

## ---- 5. Demeaned outcome (within-nation) ----
panel[, dd_pmp_dm := dd_pmp - mean(dd_pmp), by = nation]

## ---- 6. Save cleaned panel ----
fwrite(panel, "../data/panel_clean.csv")
cat("\nCleaned panel saved. Observations:", nrow(panel), "\n")
