###############################################################################
# 03_main_analysis.R — Main DiD and DDD estimation
# Paper: The Invisible Tariff (apep_0628)
###############################################################################

source("00_packages.R")

# --------------------------------------------------------------------------
# Load data
# --------------------------------------------------------------------------
nigeria_balanced <- readRDS("../data/nigeria_balanced.rds")
panel <- readRDS("../data/panel.rds")

cat("=== Main Analysis: Nigeria FX Exclusion List ===\n\n")

# ==========================================================================
# PART 1: Nigeria Product-Level DiD
# ==========================================================================

cat("--- Part 1: Product-Level DiD (Nigeria only) ---\n")

# --------------------------------------------------------------------------
# 1a. Simple DiD: Banned x Post
# --------------------------------------------------------------------------
did_simple <- feols(
  log_imports ~ banned:post | hs6 + year,
  data = nigeria_balanced,
  cluster = ~hs2
)

cat("Simple DiD (log imports):\n")
summary(did_simple)

# IHS transform for robustness to zeros
did_asinh <- feols(
  asinh_imports ~ banned:post | hs6 + year,
  data = nigeria_balanced,
  cluster = ~hs2
)

cat("\nDiD with asinh(imports):\n")
summary(did_asinh)

# --------------------------------------------------------------------------
# 1b. Event study: Banned x Year indicators
# --------------------------------------------------------------------------
# Reference period: event_time = -1 (year 2014)
nigeria_balanced[, event_factor := factor(event_time)]

es_model <- feols(
  log_imports ~ i(event_time, banned, ref = -1) | hs6 + year,
  data = nigeria_balanced,
  cluster = ~hs2
)

cat("\nEvent Study:\n")
summary(es_model)

# Save event study coefficients for table generation
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)
saveRDS(es_model, "../data/es_model.rds")

# --------------------------------------------------------------------------
# 1c. Pre-trends test
# --------------------------------------------------------------------------
# Joint test of pre-treatment coefficients
pre_coefs <- grep("event_time::-[2-3]", names(coef(es_model)), value = TRUE)
if (length(pre_coefs) > 0) {
  pre_test <- wald(es_model, pre_coefs)
  cat(sprintf("\nJoint pre-trends test: F = %.3f, p = %.4f\n",
              pre_test$stat, pre_test$p))
}

# ==========================================================================
# PART 2: Triple Difference (DDD) — Nigeria vs Control Countries
# ==========================================================================

cat("\n--- Part 2: Triple Difference (DDD) ---\n")

# Use full multi-country panel
# Drop 2015 already done in 02_clean
panel[, event_time := year - 2015]

# DDD: Banned x Nigeria x Post
ddd_model <- feols(
  log_imports ~ banned:nigeria:post + banned:post + nigeria:post + banned:nigeria |
    hs6 + reporter_code^year,
  data = panel,
  cluster = ~hs2
)

cat("DDD (Banned x Nigeria x Post):\n")
summary(ddd_model)

# DDD with more saturated FE
ddd_saturated <- feols(
  log_imports ~ banned:nigeria:post |
    hs6^reporter_code + reporter_code^year + hs6^year,
  data = panel,
  cluster = ~hs2
)

cat("\nDDD with saturated FE (product-country + country-year + product-year):\n")
summary(ddd_saturated)

saveRDS(ddd_model, "../data/ddd_model.rds")
saveRDS(ddd_saturated, "../data/ddd_saturated.rds")

# ==========================================================================
# PART 3: Extensive margin — probability of positive imports
# ==========================================================================

cat("\n--- Part 3: Extensive Margin ---\n")

nigeria_balanced[, has_imports := as.integer(import_value > 0)]

extensive_did <- feols(
  has_imports ~ banned:post | hs6 + year,
  data = nigeria_balanced,
  cluster = ~hs2
)

cat("Extensive margin (Pr(imports > 0)):\n")
summary(extensive_did)

# ==========================================================================
# PART 4: Intensive margin — conditional on positive imports
# ==========================================================================

cat("\n--- Part 4: Intensive Margin ---\n")

intensive_did <- feols(
  log_imports ~ banned:post | hs6 + year,
  data = nigeria_balanced[import_value > 0],
  cluster = ~hs2
)

cat("Intensive margin (log imports | imports > 0):\n")
summary(intensive_did)

# ==========================================================================
# PART 5: Save diagnostics for validation
# ==========================================================================

diag <- list(
  n_treated = nigeria_balanced[banned == 1, uniqueN(hs6)],
  n_control = nigeria_balanced[banned == 0, uniqueN(hs6)],
  n_pre = length(unique(nigeria_balanced[post == 0]$year)),
  n_post = length(unique(nigeria_balanced[post == 1]$year)),
  n_obs = nrow(nigeria_balanced),
  n_obs_panel = nrow(panel),
  n_countries = panel[, uniqueN(reporter_code)],
  n_hs6 = nigeria_balanced[, uniqueN(hs6)],
  n_clusters = nigeria_balanced[, uniqueN(hs2)],
  did_coef = coef(did_simple)["banned:post"],
  did_se = se(did_simple)["banned:post"],
  did_pval = pvalue(did_simple)["banned:post"],
  ddd_coef = coef(ddd_saturated)["banned:nigeria:post"],
  ddd_se = se(ddd_saturated)["banned:nigeria:post"],
  ddd_pval = pvalue(ddd_saturated)["banned:nigeria:post"],
  extensive_coef = coef(extensive_did)["banned:post"],
  intensive_coef = coef(intensive_did)["banned:post"]
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save all main models
saveRDS(did_simple, "../data/did_simple.rds")
saveRDS(did_asinh, "../data/did_asinh.rds")
saveRDS(extensive_did, "../data/extensive_did.rds")
saveRDS(intensive_did, "../data/intensive_did.rds")

cat("\n=== Main analysis complete ===\n")
