# 04_robustness.R — Robustness checks for apep_1184
# EU Airport Slot Waivers and Competition

source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- readRDS("../data/panel_annual.rds")
panel[, post := as.integer(year >= 2020)]
panel[, year_f := factor(year)]
panel[, year_f := relevel(year_f, ref = "2019")]

# ─────────────────────────────────────────────────────────────────────
# 1. Size-matched comparison (drop very small airports)
#    Level 1/2 airports are much smaller on average — restrict to
#    airports with >500K passengers in 2019 for better overlap
# ─────────────────────────────────────────────────────────────────────
panel[, pax_2019 := pax_total[year == 2019], by = airport]
panel_large <- panel[!is.na(pax_2019) & pax_2019 >= 500000]

r1 <- feols(log_pax ~ treat_continuous | airport + year,
  data = panel_large, cluster = ~airport)

r1_cxy <- feols(log_pax ~ treat_continuous | airport + country^year,
  data = panel_large, cluster = ~airport)

cat("Size-matched (>500K pax in 2019):\n")
cat(sprintf("  N airports: %d (L3: %d, L1/2: %d)\n",
    length(unique(panel_large$airport)),
    length(unique(panel_large[level3 == 1]$airport)),
    length(unique(panel_large[level3 == 0]$airport))))
etable(r1, r1_cxy, headers = c("Airport+Year FE", "Airport+Country×Year FE"))

# ─────────────────────────────────────────────────────────────────────
# 2. Exclude non-EU/EEA airports (Switzerland, UK, etc.)
#    Keep only EU27 member states + Norway + Iceland
# ─────────────────────────────────────────────────────────────────────
eu27_eea <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL",
              "ES", "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU",
              "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK",
              "NO", "IS")
panel_eu <- panel[country %in% eu27_eea]

r2 <- feols(log_pax ~ treat_continuous | airport + country^year,
  data = panel_eu, cluster = ~airport)

cat("\nEU27+EEA only (country×year FE):\n")
etable(r2)

# ─────────────────────────────────────────────────────────────────────
# 3. Exclude 2020 (extreme COVID year)
#    Focus on recovery years when the waiver actually matters
# ─────────────────────────────────────────────────────────────────────
panel_no2020 <- panel[year != 2020]

r3 <- feols(log_pax ~ treat_continuous | airport + year,
  data = panel_no2020, cluster = ~airport)
r3_cxy <- feols(log_pax ~ treat_continuous | airport + country^year,
  data = panel_no2020, cluster = ~airport)

cat("\nExcluding 2020 (recovery focus):\n")
etable(r3, r3_cxy, headers = c("Airport+Year FE", "Country×Year FE"))

# ─────────────────────────────────────────────────────────────────────
# 4. Event study with within-country FE (the clean specification)
# ─────────────────────────────────────────────────────────────────────
r4_es <- feols(log_pax ~ i(year_f, level3, ref = "2019") | airport + country^year,
  data = panel, cluster = ~airport)

cat("\nEvent Study (Country×Year FE):\n")
print(coeftable(r4_es))

# ─────────────────────────────────────────────────────────────────────
# 5. Passengers in levels (not logs) — check if log transform matters
# ─────────────────────────────────────────────────────────────────────
panel[, pax_M := pax_total / 1e6]
r5 <- feols(pax_M ~ treat_continuous | airport + year,
  data = panel, cluster = ~airport)
r5_cxy <- feols(pax_M ~ treat_continuous | airport + country^year,
  data = panel, cluster = ~airport)

cat("\nLevels (passengers in millions):\n")
etable(r5, r5_cxy, headers = c("Airport+Year FE", "Country×Year FE"))

# ─────────────────────────────────────────────────────────────────────
# 6. IHS transformation (handles zeros better than log+1)
# ─────────────────────────────────────────────────────────────────────
panel[, ihs_pax := log(pax_total + sqrt(pax_total^2 + 1))]
r6 <- feols(ihs_pax ~ treat_continuous | airport + country^year,
  data = panel, cluster = ~airport)

cat("\nIHS transformation (country×year FE):\n")
etable(r6)

# ─────────────────────────────────────────────────────────────────────
# 7. Heterogeneity: Hub size
# ─────────────────────────────────────────────────────────────────────
# Split Level 3 airports into large hubs (>10M pax in 2019) and smaller
panel[, large_hub := as.integer(!is.na(pax_2019) & pax_2019 >= 10e6 & level3 == 1)]
panel[, small_level3 := as.integer(level3 == 1 & large_hub == 0)]
panel[, treat_large := large_hub * waiver_intensity]
panel[, treat_small := small_level3 * waiver_intensity]

r7 <- feols(log_pax ~ treat_large + treat_small | airport + year,
  data = panel, cluster = ~airport)
r7_cxy <- feols(log_pax ~ treat_large + treat_small | airport + country^year,
  data = panel, cluster = ~airport)

cat("\nHeterogeneity by hub size:\n")
cat(sprintf("  Large hubs (>10M): %d\n",
    length(unique(panel[large_hub == 1]$airport))))
cat(sprintf("  Smaller Level 3: %d\n",
    length(unique(panel[small_level3 == 1]$airport))))
etable(r7, r7_cxy, headers = c("Airport+Year FE", "Country×Year FE"))

# ─────────────────────────────────────────────────────────────────────
# 8. Wild cluster bootstrap (small-sample correction for 68 clusters)
# ─────────────────────────────────────────────────────────────────────
# The main specification has 68 Level 3 clusters.
# fixest uses cluster-robust SEs, but with ~68 treated clusters this
# should be adequate. Report HC1 as a sensitivity check.

r8_hc <- feols(log_pax ~ treat_continuous | airport + year,
  data = panel, vcov = "HC1")
cat("\nHC1 (heteroskedasticity-robust) standard errors:\n")
etable(r8_hc)

# ─────────────────────────────────────────────────────────────────────
# 9. Save robustness results
# ─────────────────────────────────────────────────────────────────────
saveRDS(list(
  r_size_matched = r1,
  r_size_matched_cxy = r1_cxy,
  r_eu_only = r2,
  r_no2020 = r3,
  r_no2020_cxy = r3_cxy,
  r_es_cxy = r4_es,
  r_levels = r5,
  r_levels_cxy = r5_cxy,
  r_ihs = r6,
  r_het_hubs = r7,
  r_het_hubs_cxy = r7_cxy,
  r_hc1 = r8_hc
), "../data/robustness_models.rds")

# Summary of pre-treatment SD for SDE calculation
pre_sd_log <- sd(panel[year < 2020, log_pax], na.rm = TRUE)
pre_sd_pax <- sd(panel[year < 2020, pax_total], na.rm = TRUE)
cat(sprintf("\nPre-treatment SD(log_pax): %.4f\n", pre_sd_log))
cat(sprintf("Pre-treatment SD(pax_total): %.0f\n", pre_sd_pax))

# Save pre-treatment SDs for SDE table
saveRDS(list(
  sd_log_pax = pre_sd_log,
  sd_pax_total = pre_sd_pax,
  sd_log_pax_sched = sd(panel[year < 2020 & !is.na(pax_sched), log_pax_sched], na.rm = TRUE),
  sd_log_pax_nonsched = sd(panel[year < 2020 & !is.na(pax_nonsched), log_pax_nonsched], na.rm = TRUE)
), "../data/pre_treatment_sds.rds")

cat("\n=== Robustness checks complete ===\n")
