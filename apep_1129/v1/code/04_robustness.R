# ==============================================================================
# 04_robustness.R — Robustness checks for shift-share IV
# ==============================================================================

source("00_packages.R")

load("../data/models.RData")

# ============================================================================
# 1. Leave-one-out sensitivity (drop each state)
# ============================================================================
cat("=== Leave-one-out sensitivity ===\n")

states <- unique(panel$state_fips)
loo_results <- data.table(
  dropped_state = character(),
  iv_coef = numeric(),
  iv_se = numeric(),
  fs_f = numeric(),
  n_obs = integer()
)

for (st in states) {
  sub <- panel[state_fips != st]
  tryCatch({
    m <- feols(pills_per_cap ~ log_med_income + pct_white + pct_hs |
                 fips + year | hhi ~ bartik_hhi,
               data = sub, vcov = ~state_fips)
    loo_results <- rbind(loo_results, data.table(
      dropped_state = st,
      iv_coef = coef(m)["fit_hhi"],
      iv_se = se(m)["fit_hhi"],
      fs_f = fitstat(m, "ivf1")$ivf1$stat,
      n_obs = nobs(m)
    ))
  }, error = function(e) {
    cat(sprintf("  LOO failed for state %s: %s\n", st, e$message))
  })
}

cat(sprintf("LOO IV coef range: [%.2f, %.2f]\n",
            min(loo_results$iv_coef), max(loo_results$iv_coef)))
cat(sprintf("LOO sign stability: %d/%d positive\n",
            sum(loo_results$iv_coef > 0), nrow(loo_results)))

fwrite(loo_results, "../data/loo_results.csv")

# ============================================================================
# 2. Placebo drug: non-opioid controlled substances
# ============================================================================
cat("\n=== Placebo test: pre-period balance ===\n")

# Test: Does the Bartik IV predict pre-period (2006) pills levels?
# If so, the instrument may be correlated with pre-existing demand
panel_2006 <- panel[year == 2006]
if (nrow(panel_2006) > 100) {
  balance_pills <- lm(pills_per_cap ~ bartik_hhi, data = panel[year == 2007])
  cat(sprintf("Bartik → 2007 pills (cross-section): coef=%.3f, p=%.3f\n",
              coef(balance_pills)["bartik_hhi"],
              summary(balance_pills)$coefficients["bartik_hhi", 4]))
}

# ============================================================================
# 3. Balance tests — Bartik IV on predetermined covariates
# ============================================================================
cat("\n=== Balance tests ===\n")

balance_vars <- c("log_med_income", "pct_white", "pct_hs", "population")
balance_results <- data.table(
  variable = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (v in balance_vars) {
  tryCatch({
    f <- as.formula(paste(v, "~ bartik_hhi | fips + year"))
    m <- feols(f, data = panel, vcov = ~state_fips)
    balance_results <- rbind(balance_results, data.table(
      variable = v,
      coef = coef(m)["bartik_hhi"],
      se = se(m)["bartik_hhi"],
      pval = pvalue(m)["bartik_hhi"]
    ))
  }, error = function(e) {
    cat(sprintf("  Balance test failed for %s: %s\n", v, e$message))
  })
}

cat("Balance test results:\n")
print(balance_results)
fwrite(balance_results, "../data/balance_results.csv")

# ============================================================================
# 4. Alternative HHI measures
# ============================================================================
cat("\n=== Alternative concentration measures ===\n")

# Top-4 concentration ratio (CR4) instead of HHI
arcos_agg <- fread("../data/arcos_county_distributor_year.csv")
county_xw2 <- fread("../data/county_fips_crosswalk.csv")
arcos_agg <- merge(arcos_agg, county_xw2[!is.na(fips), .(state_abbr, county_name, fips)],
                   by = c("state_abbr", "county_name"), all.x = FALSE)
arcos_agg[, fips := as.character(fips)]
arcos_agg[, county_year_pills := sum(total_pills), by = .(fips, year)]
arcos_agg[, share := total_pills / county_year_pills]

# CR4: sum of top 4 distributor shares
cr4 <- arcos_agg[order(fips, year, -share),
                  .(cr4 = sum(head(share, 4))),
                  by = .(fips, year)]

panel_cr4 <- merge(panel, cr4, by = c("fips", "year"), all.x = TRUE)

# IV with CR4
iv_cr4 <- feols(pills_per_cap ~ log_med_income + pct_white + pct_hs |
                  fips + year | cr4 ~ bartik_hhi,
                data = panel_cr4, vcov = ~state_fips)
cat("IV with CR4:\n")
etable(iv_cr4)

# ============================================================================
# 5. Specification with population weights
# ============================================================================
cat("\n=== Population-weighted regressions ===\n")

iv_wt <- feols(pills_per_cap ~ log_med_income + pct_white + pct_hs |
                 fips + year | hhi ~ bartik_hhi,
               data = panel, vcov = ~state_fips, weights = ~population)
cat("Population-weighted 2SLS:\n")
etable(iv_wt)

# ============================================================================
# 6. Hydrocodone vs Oxycodone decomposition
# ============================================================================
cat("\n=== Drug-type decomposition ===\n")

# Load pre-fetched drug split data
drug_split <- fread("../data/arcos_drug_split.csv")
county_xw <- fread("../data/county_fips_crosswalk.csv")
drug_split <- merge(drug_split, county_xw[!is.na(fips), .(state_abbr, county_name, fips)],
                    by = c("state_abbr", "county_name"), all.x = FALSE)
drug_split[, fips := as.character(fips)]

# Aggregate by drug type
drug_agg <- drug_split[, .(pills = sum(pills)), by = .(fips, year, drug_type)]
drug_wide <- dcast(drug_agg, fips + year ~ drug_type, value.var = "pills", fill = 0)
panel_drug <- merge(panel, drug_wide, by = c("fips", "year"), all.x = TRUE)
for (col in c("HYDROCODONE", "OXYCODONE")) {
  if (col %in% names(panel_drug)) panel_drug[is.na(get(col)), (col) := 0]
}
panel_drug[, hydro_per_cap := HYDROCODONE / population]
panel_drug[, oxy_per_cap := OXYCODONE / population]

# Separate IVs
iv_hydro <- feols(hydro_per_cap ~ log_med_income + pct_white + pct_hs |
                    fips + year | hhi ~ bartik_hhi,
                  data = panel_drug, vcov = ~state_fips)
iv_oxy <- feols(oxy_per_cap ~ log_med_income + pct_white + pct_hs |
                  fips + year | hhi ~ bartik_hhi,
                data = panel_drug, vcov = ~state_fips)

cat("Drug decomposition:\n")
etable(iv_hydro, iv_oxy)

# Save robustness objects
save(loo_results, balance_results, iv_cr4, iv_wt, iv_hydro, iv_oxy,
     panel_drug, panel_cr4,
     file = "../data/robustness_models.RData")
cat("\nRobustness checks complete.\n")
