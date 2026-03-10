## 03_main_analysis.R — Main regression analysis
## APEP-0574: Gas Shock Import Substitution
## Inputs:  trade_panel.csv, production_panel.csv, bec_panel.csv
## Outputs: main_tripleDiD_results.csv, event_study_production.csv,
##          persistence_results.csv, bec_event_study.csv

source("00_packages.R")

data_dir <- "../data/"

# =====================================================================
# 1. READ PANELS
# =====================================================================
cat("=== Reading analysis panels ===\n")

trade_panel <- fread(file.path(data_dir, "trade_panel.csv"))
prod_panel  <- fread(file.path(data_dir, "production_panel.csv"))
bec_panel   <- fread(file.path(data_dir, "bec_panel.csv"))

cat(sprintf("  Trade panel:      %d rows\n", nrow(trade_panel)))
cat(sprintf("  Production panel: %d rows\n", nrow(prod_panel)))
cat(sprintf("  BEC panel:        %d rows\n", nrow(bec_panel)))

# =====================================================================
# RESULT 1: Triple-Diff on Log Annual Imports
# log(imports) ~ gas_dep × ei × post + country×year FE + SITC×year FE + country×SITC FE
# =====================================================================
cat("\n=== Result 1: Triple-Difference on Annual Imports ===\n")

# Main specification: continuous gas dependence
m1_main <- feols(
  log_imports ~ gas_dep:ei:post_shock + gas_dep:post_shock + ei:post_shock +
    gas_dep:ei |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("Model 1 (main triple-diff):\n")
summary(m1_main)

# Variant with two-way interactions absorbed by FEs
# Since country×year absorbs gas_dep×post and country×SITC absorbs gas_dep×ei,
# the clean spec is:
m1_clean <- feols(
  log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("\nModel 1b (clean triple-diff, 2-way absorbed by FEs):\n")
summary(m1_clean)

# Alternative: gas_exposure (Russian share × gas TPES share)
m1_exposure <- feols(
  log_imports ~ gas_exposure:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("\nModel 1c (gas_exposure measure):\n")
summary(m1_exposure)

# Binary gas dependence
m1_binary <- feols(
  log_imports ~ gas_dep_binary:ei:post_shock + gas_dep_binary:post_shock +
    ei:post_shock + gas_dep_binary:ei |
    sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("\nModel 1d (binary gas dependence):\n")
summary(m1_binary)

# Collect results
extract_coefs <- function(model, model_name) {
  ct <- as.data.frame(coeftable(model))
  ct$term <- rownames(ct)
  ct$model <- model_name
  rownames(ct) <- NULL
  setnames(ct, c("estimate", "se", "tstat", "pvalue", "term", "model"))
  as.data.table(ct)
}

r1_results <- rbind(
  extract_coefs(m1_main, "triple_did_main"),
  extract_coefs(m1_clean, "triple_did_clean"),
  extract_coefs(m1_exposure, "triple_did_exposure"),
  extract_coefs(m1_binary, "triple_did_binary")
)

# Add model fit statistics
r1_fit <- data.table(
  model = c("triple_did_main", "triple_did_clean", "triple_did_exposure", "triple_did_binary"),
  n_obs = c(nobs(m1_main), nobs(m1_clean), nobs(m1_exposure), nobs(m1_binary)),
  r2    = c(r2(m1_main, "ar2"), r2(m1_clean, "ar2"), r2(m1_exposure, "ar2"), r2(m1_binary, "ar2")),
  n_countries = c(uniqueN(trade_panel$geo), uniqueN(trade_panel$geo),
                  uniqueN(trade_panel$geo), uniqueN(trade_panel$geo))
)

fwrite(r1_results, file.path(data_dir, "main_tripleDiD_results.csv"))
fwrite(r1_fit, file.path(data_dir, "main_tripleDiD_fit.csv"))

cat(sprintf("\nResult 1 saved: %d coefficient rows\n", nrow(r1_results)))

# =====================================================================
# RESULT 2: Event Study on Monthly Production
# prod_index ~ gas_dep × ei × month_dummies + country×NACE FE + NACE×month FE
# =====================================================================
cat("\n=== Result 2: Event Study on Monthly Production ===\n")

# Create factor for relative month (omit -1 = Jan 2022)
prod_panel[, rel_month_f := factor(rel_month_binned)]

# Event study: triple interaction with relative month dummies
# Reference period: rel_month = -1 (January 2022, just before invasion)
prod_panel[, gas_dep_ei := gas_dep * ei]

m2_event <- feols(
  prod_index ~ i(rel_month_binned, gas_dep_ei, ref = -1) |
    country_nace + nace_ym,
  data = prod_panel,
  cluster = ~geo
)
cat("Model 2 (production event study):\n")
summary(m2_event)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(m2_event))
es_coefs$term <- rownames(es_coefs)
rownames(es_coefs) <- NULL
setnames(es_coefs, c("estimate", "se", "tstat", "pvalue", "term"))
es_coefs <- as.data.table(es_coefs)

# Parse relative month from term names
es_coefs[, rel_month := as.integer(gsub(".*::(-?[0-9]+).*", "\\1", term))]
es_coefs[, ci_lower := estimate - 1.96 * se]
es_coefs[, ci_upper := estimate + 1.96 * se]

# Add reference period
ref_row <- data.table(estimate = 0, se = 0, tstat = NA, pvalue = NA,
                       term = "reference", rel_month = -1,
                       ci_lower = 0, ci_upper = 0)
es_coefs <- rbind(es_coefs, ref_row)
es_coefs <- es_coefs[order(rel_month)]

fwrite(es_coefs, file.path(data_dir, "event_study_production.csv"))

# Save event study fit stats
es_n_clusters <- tryCatch(m2_event$nobs["geo"], error = function(e) NA)
es_fit <- data.table(n_obs = nobs(m2_event), n_clusters = as.integer(es_n_clusters))
fwrite(es_fit, file.path(data_dir, "event_study_fit.csv"))

cat(sprintf("Event study: %d coefficients saved (N=%d)\n", nrow(es_coefs), nobs(m2_event)))

# Also run a simpler DiD for the production panel
m2_did <- feols(
  prod_index ~ gas_dep:ei:post_shock + ei:post_shock |
    country_nace + nace_ym,
  data = prod_panel,
  cluster = ~geo
)
cat("\nModel 2b (production DiD):\n")
summary(m2_did)

r2_did <- extract_coefs(m2_did, "production_did")
fwrite(r2_did, file.path(data_dir, "production_did_results.csv"))

# =====================================================================
# RESULT 3: Persistence Test
# Split post into shock (2022) and post-normalization (2023-2024)
# =====================================================================
cat("\n=== Result 3: Persistence Test ===\n")

# Annual trade panel: separate shock and post-normalization effects
m3_persist <- feols(
  log_imports ~ gas_dep:ei:shock_year + gas_dep:ei:post_norm +
    ei:shock_year + ei:post_norm |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("Model 3 (persistence - trade panel):\n")
summary(m3_persist)

# Also test in production panel: split post into phases
# Restrict to rel_month >= -12 to avoid COVID-era contamination of the baseline
# (pre-period: March 2021 to Feb 2022; post: March 2022 onward)
prod_panel[, `:=`(
  shock_phase    = as.integer(rel_month >= 1 & rel_month <= 10),  # Mar-Dec 2022
  post_norm_phase = as.integer(rel_month > 10)                    # 2023+
)]

prod_persist_sample <- prod_panel[rel_month >= -12]

m3_persist_prod <- feols(
  prod_index ~ gas_dep:ei:shock_phase + gas_dep:ei:post_norm_phase +
    ei:shock_phase + ei:post_norm_phase |
    country_nace + nace_ym,
  data = prod_persist_sample,
  cluster = ~geo
)
cat("\nModel 3b (persistence - production panel, post-COVID baseline):\n")
summary(m3_persist_prod)

r3_results <- rbind(
  extract_coefs(m3_persist, "persistence_trade"),
  extract_coefs(m3_persist_prod, "persistence_production")
)
fwrite(r3_results, file.path(data_dir, "persistence_results.csv"))

# Save N for persistence models
r3_fit <- data.table(
  model = c("persistence_trade", "persistence_production"),
  n_obs = c(nobs(m3_persist), nobs(m3_persist_prod))
)
fwrite(r3_fit, file.path(data_dir, "persistence_fit.csv"))

cat(sprintf("Persistence results: %d rows saved\n", nrow(r3_results)))

# =====================================================================
# RESULT 4: BEC Intermediate Imports Event Study
# Monthly timing of import shifts for intermediate goods
# =====================================================================
cat("\n=== Result 4: BEC Intermediate Imports Event Study ===\n")

# Focus on intermediate vs capital goods (treated vs placebo)
bec_analysis <- bec_panel[bclas_bec %in% c("INT", "CAP")]

bec_analysis[, gas_dep_int := gas_dep * intermediate]

m4_event <- feols(
  log_trade ~ i(rel_month_binned, gas_dep_int, ref = -1) |
    country_bec + bec_ym,
  data = bec_analysis,
  cluster = ~geo
)
cat("Model 4 (BEC intermediate event study):\n")
summary(m4_event)

# Extract coefficients
bec_coefs <- as.data.frame(coeftable(m4_event))
bec_coefs$term <- rownames(bec_coefs)
rownames(bec_coefs) <- NULL
setnames(bec_coefs, c("estimate", "se", "tstat", "pvalue", "term"))
bec_coefs <- as.data.table(bec_coefs)

bec_coefs[, rel_month := as.integer(gsub(".*::(-?[0-9]+).*", "\\1", term))]
bec_coefs[, ci_lower := estimate - 1.96 * se]
bec_coefs[, ci_upper := estimate + 1.96 * se]

# Add reference
ref_bec <- data.table(estimate = 0, se = 0, tstat = NA, pvalue = NA,
                       term = "reference", rel_month = -1,
                       ci_lower = 0, ci_upper = 0)
bec_coefs <- rbind(bec_coefs, ref_bec)
bec_coefs <- bec_coefs[order(rel_month)]

fwrite(bec_coefs, file.path(data_dir, "bec_event_study.csv"))
cat(sprintf("BEC event study: %d coefficients saved\n", nrow(bec_coefs)))

# =====================================================================
# SUMMARY
# =====================================================================
cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Files saved:\n")
cat("  - main_tripleDiD_results.csv (Result 1)\n")
cat("  - main_tripleDiD_fit.csv (Result 1 fit stats)\n")
cat("  - event_study_production.csv (Result 2)\n")
cat("  - production_did_results.csv (Result 2b)\n")
cat("  - persistence_results.csv (Result 3)\n")
cat("  - bec_event_study.csv (Result 4)\n")
