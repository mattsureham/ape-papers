# 03_main_analysis.R — Main DDD regressions
# apep_0900: CBAM product-scope loophole

source("00_packages.R")

panel <- fread("../data/panel_hs2.csv")
panel_hs4 <- fread("../data/panel_hs4.csv")

# --- Factor variables for FE ---
panel[, partner_f := factor(partner_code)]
panel[, hs2_f := factor(hs2)]
panel[, year_f := factor(year)]
panel[, hs2_partner := interaction(hs2_f, partner_f)]
panel[, hs2_year := interaction(hs2_f, year_f)]
panel[, partner_year := interaction(partner_f, year_f)]

panel_hs4[, partner_f := factor(partner_code)]
panel_hs4[, hs4_f := factor(hs4)]
panel_hs4[, year_f := factor(year)]
panel_hs4[, hs4_partner := interaction(hs4_f, partner_f)]
panel_hs4[, hs4_year := interaction(hs4_f, year_f)]
panel_hs4[, partner_year := interaction(partner_f, year_f)]

# ========================================================
# TABLE 2: Main DDD Results
# ========================================================

cat("=== MAIN DDD REGRESSIONS ===\n\n")

# --- Col 1: Simple DD (covered × post) ---
m1 <- feols(log_value ~ covered:post | hs2_f + year_f + partner_f,
            data = panel, cluster = ~hs2_partner)

# --- Col 2: DDD (covered × high_carbon × post) ---
m2 <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs2_f + year_f + partner_f,
            data = panel, cluster = ~hs2_partner)

# --- Col 3: DDD with full two-way FE ---
m3 <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs2_partner + hs2_year + partner_year,
            data = panel, cluster = ~hs2_partner)

# --- Col 4: HS4-level DDD with full FE (main specification) ---
m4 <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs4_partner + hs4_year + partner_year,
            data = panel_hs4, cluster = ~hs4_partner)

# --- Col 5: HS4-level quantity ---
m5 <- feols(log_qty ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs4_partner + hs4_year + partner_year,
            data = panel_hs4[qty_kg > 0], cluster = ~hs4_partner)

cat("Model 1 (DD): covered × post\n")
print(summary(m1))
cat("\nModel 2 (DDD, HS2): covered × high_carbon × post\n")
print(summary(m2))
cat("\nModel 3 (DDD, HS2, full FE): covered × high_carbon × post\n")
print(summary(m3))
cat("\nModel 4 (DDD, HS4, full FE): MAIN SPECIFICATION\n")
print(summary(m4))
cat("\nModel 5 (DDD, HS4, quantity): covered × high_carbon × post\n")
print(summary(m5))

# ========================================================
# EVENT STUDY for pre-trends (HS4 panel)
# ========================================================

cat("\n=== EVENT STUDY ===\n")

# Create year indicators (base: 2022, the last full pre-treatment year)
panel_hs4[, rel_year := year - 2023]  # 2023 = transition year
# Drop 2023 for cleaner event study
es_data <- panel_hs4[year != 2023]
es_data[, year_f := factor(year)]

# Event study: interact covered × high_carbon with each year (omit 2022)
es_data[, treat := covered * high_carbon]
es <- feols(log_value ~ i(year, treat, ref = 2022) |
              hs4_partner + hs4_year + partner_year,
            data = es_data, cluster = ~hs4_partner)

cat("Event study coefficients:\n")
print(summary(es))

# ========================================================
# Save results for table generation
# ========================================================

save(m1, m2, m3, m4, m5, es, panel, panel_hs4,
     file = "../data/main_results.RData")

# --- Write diagnostics.json ---
n_treated_products <- uniqueN(panel_hs4[covered == 1]$hs4)
n_exempt_products <- uniqueN(panel_hs4[covered == 0]$hs4)
n_partners <- uniqueN(panel_hs4$partner_code)
n_high_carbon <- uniqueN(panel_hs4[high_carbon == 1]$partner_code)
n_pre <- length(unique(panel_hs4$year[panel_hs4$year < 2024]))
n_obs <- nrow(panel_hs4)

diag <- list(
  n_treated = n_treated_products * n_high_carbon,  # treated product-partner cells
  n_pre = n_pre,
  n_obs = n_obs,
  n_treated_products = n_treated_products,
  n_exempt_products = n_exempt_products,
  n_partners = n_partners,
  n_high_carbon = n_high_carbon,
  n_years = length(unique(panel_hs4$year))
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: %d treated product-partner cells, %d pre-periods, %d total obs\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
