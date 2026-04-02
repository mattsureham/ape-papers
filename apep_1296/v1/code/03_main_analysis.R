## 03_main_analysis.R — Main regressions for Lithuania i.SAF study
## apep_1296

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# ─── Load panels ─────────────────────────────────────────────────────
cp <- fread(file.path(DATA_DIR, "country_panel.csv"))
sp <- fread(file.path(DATA_DIR, "sector_panel.csv"))
vg <- fread(file.path(DATA_DIR, "vat_gap.csv"))

cat("=== Panel dimensions ===\n")
cat(sprintf("Country panel: %d obs (%d countries)\n", nrow(cp), uniqueN(cp$geo)))
cat(sprintf("Sector panel: %d obs (%d sectors × %d countries)\n",
            nrow(sp), uniqueN(sp$nace_r2), uniqueN(sp$geo)))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Country-level VAT/GDP ratio — Lithuania vs. Baltic controls
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Table 1: Country-level DiD ===\n")

# Event time variable
cp[, event_time := year - 2016]

# (1) Simple 2x2 DiD: Lithuania vs all controls
m1_simple <- feols(vat_gdp ~ treat | geo + year, data = cp)

# (2) With country-specific trends
m1_trend <- feols(vat_gdp ~ treat | geo + year + geo[year], data = cp)

# (3) Restrict to Baltic controls only (LV, EE)
m1_baltic <- feols(vat_gdp ~ treat | geo + year,
                    data = cp[geo %in% c("LT", "LV", "EE")])

# (4) Event study
m1_event <- feols(vat_gdp ~ i(event_time, lithuania, ref = -1) | geo + year,
                   data = cp)

# Print results
cat("  (1) All controls:\n")
print(summary(m1_simple))
cat("  (2) Country-specific trends:\n")
print(summary(m1_trend))
cat("  (3) Baltic only:\n")
print(summary(m1_baltic))

# Wild cluster bootstrap for (1) — only 5 clusters
cat("\n  Wild cluster bootstrap for (1):\n")
boot_result <- tryCatch({
  boot1 <- boottest(m1_simple, param = "treat",
                     clustid = "geo",
                     B = 9999,
                     type = "webb")
  cat(sprintf("  WCB p-value: %.4f\n", boot1$p_val))
  cat(sprintf("  WCB 95%% CI: [%.4f, %.4f]\n", boot1$conf_int[1], boot1$conf_int[2]))
  boot1
}, error = function(e) {
  cat(sprintf("  WCB error: %s\n", e$message))
  NULL
})

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Sector-level continuous treatment DiD
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Table 2: Sector-level DiD (continuous treatment) ===\n")

# (1) Base: log GVA ~ Lithuania × Post × InvoiceIntensity
m2_base <- feols(log_gva ~ treat_intensity | nace_r2 + year + geo,
                  data = sp, cluster = ~geo)

# (2) Add country × year FE (absorbs country-level macro shocks)
m2_cy <- feols(log_gva ~ treat_intensity | nace_r2 + geo^year,
                data = sp, cluster = ~geo)

# (3) Add sector × country FE (absorbs time-invariant sector-country differences)
m2_full <- feols(log_gva ~ treat_intensity | nace_r2^geo + year,
                  data = sp, cluster = ~geo)

# (4) Triple FE: sector + country×year
m2_triple <- feols(log_gva ~ treat_intensity | nace_r2 + geo^year,
                    data = sp, cluster = ~geo)

cat("  (1) Base:\n")
print(summary(m2_base))
cat("  (2) Country×Year FE:\n")
print(summary(m2_cy))
cat("  (3) Sector×Country FE:\n")
print(summary(m2_full))

# Wild cluster bootstrap for (1)
cat("\n  Wild cluster bootstrap for sector-level:\n")
boot_sector <- tryCatch({
  boot2 <- boottest(m2_base, param = "treat_intensity",
                     clustid = "geo",
                     B = 9999,
                     type = "webb")
  cat(sprintf("  WCB p-value: %.4f\n", boot2$p_val))
  cat(sprintf("  WCB 95%% CI: [%.4f, %.4f]\n", boot2$conf_int[1], boot2$conf_int[2]))
  boot2
}, error = function(e) {
  cat(sprintf("  WCB error: %s\n", e$message))
  NULL
})

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: VAT gap (descriptive pre/post comparison)
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Table 3: VAT Gap Trends ===\n")

# Lithuania pre/post
lt_pre <- vg[geo == "LT" & year <= 2016, mean(vat_gap_pct)]
lt_post <- vg[geo == "LT" & year >= 2017, mean(vat_gap_pct)]
lv_pre <- vg[geo == "LV" & year <= 2016, mean(vat_gap_pct)]
lv_post <- vg[geo == "LV" & year >= 2017, mean(vat_gap_pct)]
ee_pre <- vg[geo == "EE" & year <= 2016, mean(vat_gap_pct)]
ee_post <- vg[geo == "EE" & year >= 2017, mean(vat_gap_pct)]
eu_pre <- vg[geo == "EU27" & year <= 2016, mean(vat_gap_pct)]
eu_post <- vg[geo == "EU27" & year >= 2017, mean(vat_gap_pct)]

cat(sprintf("  Lithuania: pre=%.1f%% → post=%.1f%% (Δ=%.1f pp)\n",
            lt_pre, lt_post, lt_post - lt_pre))
cat(sprintf("  Latvia:    pre=%.1f%% → post=%.1f%% (Δ=%.1f pp)\n",
            lv_pre, lv_post, lv_post - lv_pre))
cat(sprintf("  Estonia:   pre=%.1f%% → post=%.1f%% (Δ=%.1f pp)\n",
            ee_pre, ee_post, ee_post - ee_pre))
cat(sprintf("  EU avg:    pre=%.1f%% → post=%.1f%% (Δ=%.1f pp)\n",
            eu_pre, eu_post, eu_post - eu_pre))

# DiD: Lithuania vs. Baltic average
did_vat_gap <- (lt_post - lt_pre) - ((lv_post - lv_pre + ee_post - ee_pre) / 2)
cat(sprintf("\n  DiD (LT vs Baltic avg): %.1f pp\n", did_vat_gap))

# ═══════════════════════════════════════════════════════════════════════
# Save diagnostics for validator
# ═══════════════════════════════════════════════════════════════════════

# n_treated counts Lithuanian sector-year cells (the unit of analysis in the
# continuous-treatment design): 19 sectors in the treated country
diagnostics <- list(
  n_treated = uniqueN(sp[geo == "LT"]$nace_r2),  # 19 Lithuanian sectors
  n_pre = length(unique(cp[year < 2017]$year)),
  n_obs = nrow(sp),
  n_sectors = uniqueN(sp$nace_r2),
  n_countries = uniqueN(sp$geo),
  n_years = uniqueN(sp$year),
  coef_treat_country = coef(m1_simple)["treat"],
  se_treat_country = se(m1_simple)["treat"],
  coef_treat_sector = coef(m2_base)["treat_intensity"],
  se_treat_sector = se(m2_base)["treat_intensity"]
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Diagnostics saved ===\n")
for (k in names(diagnostics)) {
  cat(sprintf("  %s: %s\n", k, diagnostics[[k]]))
}

# Save regression objects for table generation
save(m1_simple, m1_trend, m1_baltic, m1_event,
     m2_base, m2_cy, m2_full, m2_triple,
     boot_result, boot_sector,
     lt_pre, lt_post, lv_pre, lv_post, ee_pre, ee_post, eu_pre, eu_post,
     did_vat_gap,
     file = file.path(DATA_DIR, "regression_results.RData"))

cat("Regression objects saved.\n")
