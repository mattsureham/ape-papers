## 03_main_analysis.R — Main regressions
## apep_1314: The Prudential Drag
source("00_packages.R")
setwd("..")

panel <- fread("data/analysis_panel.csv")
cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d obs, %d regions, %d countries\n",
            nrow(panel), uniqueN(panel$nuts2), uniqueN(panel$country)))

# ============================================================================
# 1. First-stage: Financial employment share predicts financial sector decline
# ============================================================================
cat("\n--- First Stage ---\n")

# Construct interaction: pre-shock share × post-CRD IV
panel[, treat := fin_share_2008 * post_crd]

# First stage: Change in financial employment ~ share × post
# Using continuous treatment intensity (share_2008) interacted with post
fs_fin_emp <- feols(
  emp_financial ~ treat | nuts2 + year,
  data = panel[!is.na(emp_financial)],
  cluster = ~country
)
cat("First stage (financial employment):\n")
summary(fs_fin_emp)

# ============================================================================
# 2. Reduced-form: Bartik exposure → economic outcomes
# ============================================================================
cat("\n--- Reduced Form Regressions ---\n")

# Main specification: Y_rt = β × (share_2008_r × post_t) + α_r + δ_t + ε_rt
# Clustered at country level (27 clusters → sufficient for cluster-robust)

# Outcome 1: Total employment change
rf_emp <- feols(
  d_emp_total ~ treat | nuts2 + year,
  data = panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("\nReduced form — Total employment (% change from 2008):\n")
summary(rf_emp)

# Outcome 2: Unemployment rate change
rf_unemp <- feols(
  d_unemp ~ treat | nuts2 + year,
  data = panel[!is.na(d_unemp)],
  cluster = ~country
)
cat("\nReduced form — Unemployment rate change (pp):\n")
summary(rf_unemp)

# Outcome 3: Log GDP per capita change
rf_gdp <- feols(
  d_log_gdp ~ treat | nuts2 + year,
  data = panel[!is.na(d_log_gdp)],
  cluster = ~country
)
cat("\nReduced form — Log GDP per capita change:\n")
summary(rf_gdp)

# ============================================================================
# 3. Event study (dynamic effects)
# ============================================================================
cat("\n--- Event Study ---\n")

# Create year-by-share interactions (2008 = omitted base year)
panel[, year_f := factor(year)]
years <- sort(unique(panel$year))
for (y in years[years != 2008]) {
  panel[, paste0("share_x_", y) := fin_share_2008 * (year == y)]
}

# Event study for total employment
share_vars <- paste0("share_x_", years[years != 2008])
es_formula <- as.formula(paste0(
  "d_emp_total ~ ", paste(share_vars, collapse = " + "),
  " | nuts2 + year"
))

es_emp <- feols(
  es_formula,
  data = panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("\nEvent study — Total employment:\n")
summary(es_emp)

# Extract event study coefficients
es_coefs <- data.table(
  year = years[years != 2008],
  coef = coef(es_emp),
  se = sqrt(diag(vcov(es_emp)))
)
es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
# Add base year
es_coefs <- rbind(
  data.table(year = 2008, coef = 0, se = 0, ci_lo = 0, ci_hi = 0),
  es_coefs
)
fwrite(es_coefs, "data/event_study_coefficients.csv")

# ============================================================================
# 4. Heterogeneity: Eurozone vs non-Eurozone
# ============================================================================
cat("\n--- Heterogeneity: Eurozone vs Non-Eurozone ---\n")

# Eurozone regions face SSM supervision (2014) on top of CRD IV
panel[, treat_ez := treat * eurozone]
panel[, treat_nez := treat * (1 - eurozone)]

het_emp <- feols(
  d_emp_total ~ treat_ez + treat_nez | nuts2 + year,
  data = panel[!is.na(d_emp_total)],
  cluster = ~country
)
cat("\nEurozone vs non-Eurozone — Total employment:\n")
summary(het_emp)

het_unemp <- feols(
  d_unemp ~ treat_ez + treat_nez | nuts2 + year,
  data = panel[!is.na(d_unemp)],
  cluster = ~country
)
cat("\nEurozone vs non-Eurozone — Unemployment:\n")
summary(het_unemp)

# ============================================================================
# 5. Save results for tables
# ============================================================================
results <- list(
  fs_fin_emp = fs_fin_emp,
  rf_emp = rf_emp,
  rf_unemp = rf_unemp,
  rf_gdp = rf_gdp,
  es_emp = es_emp,
  het_emp = het_emp,
  het_unemp = het_unemp,
  es_coefs = es_coefs
)
saveRDS(results, "data/main_results.rds")

# ============================================================================
# 6. Diagnostics for validator
# ============================================================================
diag <- list(
  n_treated = uniqueN(panel$nuts2[panel$fin_share_2008 > median(panel$fin_share_2008)]),
  n_pre = length(unique(panel$year[panel$year < 2014])),
  n_obs = nrow(panel[!is.na(d_emp_total)])
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
