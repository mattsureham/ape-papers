## 04_robustness.R — Robustness checks for Lithuania i.SAF study
## apep_1296

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")

cp <- fread(file.path(DATA_DIR, "country_panel.csv"))
sp <- fread(file.path(DATA_DIR, "sector_panel.csv"))
vg <- fread(file.path(DATA_DIR, "vat_gap.csv"))
load(file.path(DATA_DIR, "regression_results.RData"))

# ═══════════════════════════════════════════════════════════════════════
# 1. VAT revenue LEVELS (not ratio) — to address GDP growth confound
# ═══════════════════════════════════════════════════════════════════════

cat("=== VAT revenue levels ===\n")
cp[, log_vat := log(vat_meur)]
cp[, log_gdp := log(gdp_meur)]
cp[, event_time := year - 2016]

# DiD on log VAT revenue
m_logvat <- feols(log_vat ~ treat | geo + year, data = cp)
cat("  Log VAT revenue DiD:\n")
print(summary(m_logvat))

# DiD on log GDP (should not show differential effect if VAT is the channel)
m_loggdp <- feols(log_gdp ~ treat | geo + year, data = cp)
cat("  Log GDP DiD (placebo - should be null):\n")
print(summary(m_loggdp))

# ═══════════════════════════════════════════════════════════════════════
# 2. Placebo treatment dates (sector-level)
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Placebo treatment dates ===\n")
placebo_results <- data.table()
for (fake_year in 2012:2015) {
  sp_temp <- copy(sp)
  sp_temp[, fake_post := as.integer(year >= fake_year)]
  sp_temp[, fake_treat := lithuania * fake_post * invoice_intensity]
  m_fake <- feols(log_gva ~ fake_treat | nace_r2 + year + geo,
                   data = sp_temp[year <= 2016], cluster = ~geo)
  placebo_results <- rbind(placebo_results, data.table(
    fake_year = fake_year,
    coef = coef(m_fake)["fake_treat"],
    se = se(m_fake)["fake_treat"],
    pval = pvalue(m_fake)["fake_treat"]
  ))
}
cat("  Placebo treatment dates:\n")
print(placebo_results)

# ═══════════════════════════════════════════════════════════════════════
# 3. Leave-one-country-out
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Leave-one-out ===\n")
countries <- unique(sp$geo)
loo_results <- data.table()
for (drop_country in countries[countries != "LT"]) {
  sp_loo <- sp[geo != drop_country]
  m_loo <- feols(log_gva ~ treat_intensity | nace_r2 + year + geo,
                  data = sp_loo, cluster = ~geo)
  loo_results <- rbind(loo_results, data.table(
    dropped = drop_country,
    coef = coef(m_loo)["treat_intensity"],
    se = se(m_loo)["treat_intensity"],
    pval = pvalue(m_loo)["treat_intensity"]
  ))
}
cat("  Leave-one-out results:\n")
print(loo_results)

# ═══════════════════════════════════════════════════════════════════════
# 4. Placebo: VAT-exempt sectors (O-Q: public admin, education, health)
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Placebo: VAT-exempt sectors ===\n")
# These sectors should NOT respond to VAT enforcement
exempt_sectors <- c("O-Q", "L", "K")  # Public admin, real estate, finance
sp_exempt <- sp[nace_r2 %in% exempt_sectors]
if (nrow(sp_exempt) > 10) {
  m_exempt <- feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                     data = sp_exempt, cluster = ~geo)
  cat("  VAT-exempt sectors placebo:\n")
  print(summary(m_exempt))
} else {
  cat("  Not enough exempt sector observations\n")
}

# Non-exempt sectors (should show effect)
nonexempt_sectors <- setdiff(unique(sp$nace_r2), exempt_sectors)
sp_nonexempt <- sp[nace_r2 %in% nonexempt_sectors]
m_nonexempt <- feols(log_gva ~ treat_intensity | nace_r2 + year + geo,
                      data = sp_nonexempt, cluster = ~geo)
cat("  Non-exempt sectors:\n")
print(summary(m_nonexempt))

# ═══════════════════════════════════════════════════════════════════════
# 5. Event study (sector-level)
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Event study (sector-level) ===\n")
sp[, event_time := year - 2016]
m_event_sector <- feols(log_gva ~ i(event_time, treat_intensity, ref = -1) |
                          nace_r2 + year + geo,
                        data = sp, cluster = ~geo)
cat("  Event study coefficients:\n")
event_coefs <- data.table(
  event_time = as.integer(gsub("event_time::", "", names(coef(m_event_sector)))),
  coef = as.numeric(coef(m_event_sector)),
  se = as.numeric(se(m_event_sector))
)
event_coefs[, ci_lo := coef - 1.96 * se]
event_coefs[, ci_hi := coef + 1.96 * se]
print(event_coefs)

# ═══════════════════════════════════════════════════════════════════════
# 6. Randomization inference (permute treated country)
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Randomization inference ===\n")
# Actual estimate
actual_coef <- coef(m2_base)["treat_intensity"]

# Permute: assign treatment to each country in turn
set.seed(42)
ri_coefs <- numeric(0)
for (fake_treated in unique(sp$geo)) {
  sp_ri <- copy(sp)
  sp_ri[, ri_treat := as.integer(geo == fake_treated) * post2016 * invoice_intensity]
  m_ri <- feols(log_gva ~ ri_treat | nace_r2 + year + geo,
                 data = sp_ri, cluster = ~geo)
  ri_coefs <- c(ri_coefs, coef(m_ri)["ri_treat"])
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(actual_coef))
cat(sprintf("  Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("  RI distribution: %s\n", paste(round(ri_coefs, 4), collapse = ", ")))
cat(sprintf("  RI p-value (2-sided): %.4f\n", ri_pvalue))

# ═══════════════════════════════════════════════════════════════════════
# Save all robustness results
# ═══════════════════════════════════════════════════════════════════════

save(m_logvat, m_loggdp, placebo_results, loo_results,
     m_nonexempt, m_event_sector, event_coefs,
     ri_coefs, ri_pvalue, actual_coef,
     file = file.path(DATA_DIR, "robustness_results.RData"))

cat("\nAll robustness checks complete.\n")
