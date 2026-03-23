## 03_main_analysis.R — Main DiD regressions
## apep_0759: Simplified to Compete

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

contracts <- readRDS(file.path(data_dir, "contracts_clean.rds"))
cat(sprintf("Loaded %s contracts for analysis\n", format(nrow(contracts), big.mark = ",")))

# Focus on treated vs below_control (above_control not available in post-period)
contracts <- contracts[band %in% c("treated", "below_control")]
cat(sprintf("After band filter (treated + below_control): %s\n", format(nrow(contracts), big.mark = ",")))

## ========================================================================
## MAIN SPECIFICATION: DiD comparing treated band ($150K-$250K) to controls
## We use both control bands combined as the comparison group
## ========================================================================

## ---- Outcome 1: Number of offers received ----
cat("\n=== Number of Offers Received ===\n")

# (1) Basic DiD
m1_basic <- feols(n_offers_w ~ did | fiscal_year + naics2,
                  data = contracts, cluster = ~naics2 + fyq)

# (2) Add agency FE
m1_agency <- feols(n_offers_w ~ did | fiscal_year + naics2 + agency,
                   data = contracts, cluster = ~naics2 + fyq)

# (3) Fiscal year-quarter FE (finest temporal)
m1_fyq <- feols(n_offers_w ~ did | fyq + naics2,
                data = contracts, cluster = ~naics2 + fyq)

# (4) Full specification with agency × quarter
m1_full <- feols(n_offers_w ~ did | fyq + naics2 + agency,
                 data = contracts, cluster = ~naics2 + fyq)

## ---- Outcome 2: Fully competed ----
cat("\n=== Fully Competed ===\n")

m2_basic <- feols(fully_competed ~ did | fiscal_year + naics2,
                  data = contracts, cluster = ~naics2 + fyq)

m2_full <- feols(fully_competed ~ did | fyq + naics2 + agency,
                 data = contracts, cluster = ~naics2 + fyq)

## ---- Outcome 3: Small business awards ----
cat("\n=== Small Business Participation ===\n")

m3_basic <- feols(small_business ~ did | fiscal_year + naics2,
                  data = contracts, cluster = ~naics2 + fyq)

m3_full <- feols(small_business ~ did | fyq + naics2 + agency,
                 data = contracts, cluster = ~naics2 + fyq)

## ---- Outcome 4: Not competed (sole source) ----
cat("\n=== Not Competed (Sole Source) ===\n")

m4_basic <- feols(not_competed ~ did | fiscal_year + naics2,
                  data = contracts, cluster = ~naics2 + fyq)

m4_full <- feols(not_competed ~ did | fyq + naics2 + agency,
                 data = contracts, cluster = ~naics2 + fyq)

## ========================================================================
## EVENT STUDY — Year-by-year treatment effects
## ========================================================================

cat("\n=== Event Study ===\n")

# Relative time variable (event time relative to FY2021)
contracts[, rel_year := fiscal_year - 2021L]
# Drop earliest year as baseline (-6 = FY2015)
contracts[, rel_year_f := factor(rel_year)]

# Offers event study
es_offers <- feols(n_offers_w ~ i(rel_year, treated, ref = -1) | fyq + naics2 + agency,
                   data = contracts, cluster = ~naics2 + fyq)

# Competition event study
es_competed <- feols(fully_competed ~ i(rel_year, treated, ref = -1) | fyq + naics2 + agency,
                     data = contracts, cluster = ~naics2 + fyq)

# Small business event study
es_sb <- feols(small_business ~ i(rel_year, treated, ref = -1) | fyq + naics2 + agency,
               data = contracts, cluster = ~naics2 + fyq)

# Sole source event study
es_sole <- feols(not_competed ~ i(rel_year, treated, ref = -1) | fyq + naics2 + agency,
                 data = contracts, cluster = ~naics2 + fyq)

## ========================================================================
## PRINT RESULTS
## ========================================================================

cat("\n\n========== MAIN RESULTS ==========\n")
cat("\n--- Offers Received ---\n")
print(summary(m1_full))

cat("\n--- Fully Competed ---\n")
print(summary(m2_full))

cat("\n--- Small Business ---\n")
print(summary(m3_full))

cat("\n--- Not Competed ---\n")
print(summary(m4_full))

cat("\n--- Event Study (Offers) ---\n")
print(summary(es_offers))

## ========================================================================
## SAVE RESULTS
## ========================================================================

# Save model objects for tables
save(m1_basic, m1_agency, m1_fyq, m1_full,
     m2_basic, m2_full,
     m3_basic, m3_full,
     m4_basic, m4_full,
     es_offers, es_competed, es_sb, es_sole,
     file = file.path(data_dir, "main_models.rda"))

## ========================================================================
## DIAGNOSTICS JSON (required by validate_v1.py)
## ========================================================================

n_treated_units <- contracts[treated == 1, uniqueN(naics2)]  # NAICS sectors as "units"
n_pre <- length(unique(contracts[post == 0, fiscal_year]))
n_obs <- nrow(contracts)

diagnostics <- list(
  n_treated = as.integer(contracts[treated == 1, .N]),
  n_treated_units = n_treated_units,
  n_pre = n_pre,
  n_obs = n_obs,
  outcomes = c("n_offers_w", "fully_competed", "small_business", "not_competed"),
  treatment = "SAT threshold increase (treated band $150K-$250K)",
  estimator = "TWFE DiD with FYQ + NAICS + Agency FE, two-way clustered"
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics: N=%s, treated contracts=%s, pre-periods=%d\n",
            format(n_obs, big.mark = ","),
            format(diagnostics$n_treated, big.mark = ","),
            n_pre))

cat("\nMain analysis complete.\n")
