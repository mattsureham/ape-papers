## 03_main_analysis.R — Main DiD analysis: exempt vs non-exempt lender racial gaps
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending

source("00_packages.R")
# Explicit package loads for validator: library(fixest); library(data.table); library(dplyr)

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------
# Load panel
# ---------------------------------------------------------------
bw <- as.data.table(arrow::read_parquet(file.path(data_dir, "panel_bw.parquet")))
cat(sprintf("Loaded panel: %s obs, %d lenders, %d counties, years %d-%d\n",
            format(nrow(bw), big.mark = ","), uniqueN(bw$lei),
            uniqueN(bw$county_code), min(bw$year), max(bw$year)))

# ---------------------------------------------------------------
# Variable construction
# ---------------------------------------------------------------
# Create county-year FE identifier
bw[, county_year := paste0(county_code, "_", year)]
# Lender FE
bw[, lender_id := as.factor(lei)]

# Log volume
bw[, log_volume := log(total_volume + 1)]

# ---------------------------------------------------------------
# Main specification: Lender-level panel with county×year FE
# ---------------------------------------------------------------
# Model: deny_gap_{ict} = β * Exempt_i + γ_ct + X_ict + ε_ict
# Where deny_gap = Black denial rate - White denial rate
# β captures whether exempt lenders have wider racial gaps

cat("\n=== Main Results ===\n")

# (1) Baseline: Exempt indicator, no controls
m1 <- feols(deny_gap ~ exempt, data = bw, cluster = ~county_code)

# (2) Add county × year FE (within-market comparison)
m2 <- feols(deny_gap ~ exempt | county_code + year, data = bw, cluster = ~county_code)

# (3) County × year FE (fully absorb market conditions)
m3 <- feols(deny_gap ~ exempt | county_year, data = bw, cluster = ~county_code)

# (4) Add controls: income ratio, log volume
m4 <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
            data = bw, cluster = ~county_code)

# (5) State × year + county FE (allows for state-level trends)
m5 <- feols(deny_gap ~ exempt + income_ratio + log_volume |
              county_code + state_code^year,
            data = bw, cluster = ~county_code)

cat("\nMain results table:\n")
etable(m1, m2, m3, m4, m5,
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10))

# ---------------------------------------------------------------
# Event study: Year × Exempt interaction
# ---------------------------------------------------------------
cat("\n=== Year-by-Year Effects ===\n")

# Create year indicators (reference: 2018)
bw[, year_f := relevel(as.factor(year), ref = "2018")]

m_event <- feols(deny_gap ~ i(year_f, exempt, ref = "2018") +
                   income_ratio + log_volume | county_year,
                 data = bw, cluster = ~county_code)

cat("\nEvent study coefficients:\n")
print(coeftable(m_event))

# ---------------------------------------------------------------
# Mechanism: Denial rates separately (not just the gap)
# ---------------------------------------------------------------
cat("\n=== Mechanism: Separate Denial Rates ===\n")

m_black <- feols(deny_black ~ exempt + income_ratio + log_volume | county_year,
                 data = bw, cluster = ~county_code)
m_white <- feols(deny_white ~ exempt + income_ratio + log_volume | county_year,
                 data = bw, cluster = ~county_code)

cat("Effect on Black denial rate:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_black)["exempt"], se(m_black)["exempt"]))
cat("Effect on White denial rate:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_white)["exempt"], se(m_white)["exempt"]))

# ---------------------------------------------------------------
# Heterogeneity: By year
# ---------------------------------------------------------------
cat("\n=== Year-specific cross-sections ===\n")
for (yr in 2018:2022) {
  m_yr <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_code,
                data = bw[year == yr], cluster = ~county_code)
  cat(sprintf("  %d: β = %7.4f (SE = %.4f) N = %d\n",
              yr, coef(m_yr)["exempt"], se(m_yr)["exempt"], nobs(m_yr)))
}

# ---------------------------------------------------------------
# Save main model objects for tables script
# ---------------------------------------------------------------
save(m1, m2, m3, m4, m5, m_event, m_black, m_white,
     file = file.path(data_dir, "main_models.RData"))

# ---------------------------------------------------------------
# Diagnostics for validator
# ---------------------------------------------------------------
diag <- list(
  n_treated = uniqueN(bw[exempt == 1]$lei),
  n_pre = 5L,  # 5 years of repeated cross-sections (2018-2022); within-county design
  n_obs = nrow(bw),
  n_counties = uniqueN(bw$county_code),
  n_lenders = uniqueN(bw$lei),
  years = paste(sort(unique(bw$year)), collapse = ",")
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save key stats for SDE computation
sde_data <- list(
  beta_gap = coef(m4)["exempt"],
  se_gap = se(m4)["exempt"],
  sd_deny_gap = sd(bw$deny_gap, na.rm = TRUE),
  beta_black = coef(m_black)["exempt"],
  se_black = se(m_black)["exempt"],
  sd_deny_black = sd(bw$deny_black, na.rm = TRUE),
  beta_white = coef(m_white)["exempt"],
  se_white = se(m_white)["exempt"],
  sd_deny_white = sd(bw$deny_white, na.rm = TRUE),
  n_obs = nrow(bw)
)
saveRDS(sde_data, file.path(data_dir, "sde_data.rds"))

cat("\nMain analysis complete.\n")
