## ============================================================================
## 02_clean_data.R — Data cleaning for apep_1327
## Variables already constructed in 01_fetch_data.R; this adds sample
## restrictions, pre-treatment stats, and final validation.
## ============================================================================

source("00_packages.R")

DATA <- "../data"
panel <- readRDS(file.path(DATA, "panel.rds"))

cat(sprintf("Loaded panel: %s rows, %s ZIPs\n",
            format(nrow(panel), big.mark = ","),
            format(uniqueN(panel$zip5), big.mark = ",")))

## ---- 1. Sample restrictions ----
# Drop ZIPs with zero pharmacy claims across all months
zip_ever_pharmacy <- panel[pharmacy_claims > 0, .(has_pharmacy = TRUE), by = zip5]
panel <- merge(panel, zip_ever_pharmacy, by = "zip5", all.x = TRUE)
n_before <- uniqueN(panel$zip5)
panel <- panel[has_pharmacy == TRUE]
panel[, has_pharmacy := NULL]
n_after <- uniqueN(panel$zip5)
cat(sprintf("Sample restriction (ZIPs with any pharmacy claims): %s → %s\n",
            format(n_before, big.mark = ","), format(n_after, big.mark = ",")))

## ---- 2. Pre-treatment standard deviations ----
pre_stats <- panel[pre_treatment == TRUE, .(
  sd_pharmacy_claims = sd(pharmacy_claims, na.rm = TRUE),
  sd_ed_claims = sd(ed_claims, na.rm = TRUE),
  sd_pharmacy_beneficiaries = sd(pharmacy_beneficiaries, na.rm = TRUE),
  mean_pharmacy_claims = mean(pharmacy_claims, na.rm = TRUE),
  mean_ed_claims = mean(ed_claims, na.rm = TRUE),
  mean_pharmacy_beneficiaries = mean(pharmacy_beneficiaries, na.rm = TRUE)
)]

cat(sprintf("\nPre-treatment statistics:\n"))
cat(sprintf("  Pharmacy claims: mean=%.1f, sd=%.1f\n",
            pre_stats$mean_pharmacy_claims, pre_stats$sd_pharmacy_claims))
cat(sprintf("  ED claims: mean=%.1f, sd=%.1f\n",
            pre_stats$mean_ed_claims, pre_stats$sd_ed_claims))
cat(sprintf("  Pharmacy beneficiaries: mean=%.1f, sd=%.1f\n",
            pre_stats$mean_pharmacy_beneficiaries, pre_stats$sd_pharmacy_beneficiaries))

## ---- 3. Panel balance check ----
cat(sprintf("\n=== Final Panel ===\n"))
cat(sprintf("Rows: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("ZIPs: %s (treated=%d, control=%d)\n",
            format(uniqueN(panel$zip5), big.mark = ","),
            uniqueN(panel[ever_treated == TRUE]$zip5),
            uniqueN(panel[control == TRUE]$zip5)))
cat(sprintf("Months: %d\n", uniqueN(panel$month_date)))
cat(sprintf("Last-pharmacy ZIPs: %d\n", uniqueN(panel[last_pharm == TRUE]$zip5)))

## ---- 4. Save ----
saveRDS(panel, file.path(DATA, "panel_clean.rds"))
saveRDS(pre_stats, file.path(DATA, "pre_stats.rds"))

cat("\n=== Cleaning complete ===\n")
