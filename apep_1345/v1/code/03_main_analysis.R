## 03_main_analysis.R — Event Study & DiD: Ofsted Ratings and House Prices
## apep_1345: The Inspector Lottery

source("00_packages.R")
library(fixest)
library(data.table)
setwd(here::here("output", "apep_1345", "v1"))

dir.create("tables", showWarnings = FALSE)

## ── 1. Load Data ─────────────────────────────────────────────────────────────

panel <- fread("data/analysis_panel.csv")
ofsted <- fread("data/ofsted_clean.csv")

cat("Panel:", nrow(panel), "rows |", uniqueN(panel$urn), "schools\n")

# Ensure proper types
panel[, event_month := as.integer(event_month)]
panel[, rating := as.integer(rating)]
panel[, good_rating := as.integer(good_rating)]
panel[, post := as.integer(event_month >= 0)]

# Create bad_rating indicator (RI or Inadequate)
panel[, bad_rating := as.integer(rating >= 3)]

# Create year-quarter FE
panel[, txn_yq := paste0(year(txn_month), "Q", quarter(txn_month))]

## ── 2. Event Study: Dynamic DiD ──────────────────────────────────────────────

cat("\n=== Event Study Specification ===\n")

# Normalize: omit event_month == -1 (last month before publication)
# Dependent variable: log mean house price in postcode district x month
# Estimate: interaction of event_month dummies x bad_rating

# Drop missing outcome
panel_est <- panel[!is.na(log_mean_price)]
cat("Estimation sample:", nrow(panel_est), "rows |",
    uniqueN(panel_est$urn), "schools\n")

# Event study: coefficients on event_month x bad_rating
# FE: school (urn) + calendar month
# Cluster: postcode district

# Create event_month factor with -1 as reference
panel_est[, em_factor := relevel(factor(event_month), ref = "-1")]

# Event study regression
cat("Running event study regression...\n")
es_model <- feols(
  log_mean_price ~ i(event_month, bad_rating, ref = -1) |
    urn + txn_month,
  data = panel_est,
  cluster = ~pc_district
)

cat("\nEvent study summary:\n")
summary(es_model)

## ── 3. Simple DiD: Pre/Post x Bad Rating ─────────────────────────────────────

cat("\n=== DiD Specification ===\n")

# Main DiD: post x bad_rating with school + calendar FE
did_model <- feols(
  log_mean_price ~ post:bad_rating |
    urn + txn_month,
  data = panel_est,
  cluster = ~pc_district
)

cat("\nDiD result:\n")
summary(did_model)

# Triple-diff: also control for school characteristics
# Interact post x bad_rating, with school and calendar FE
# Additional model: narrower window (12 months pre/post)
panel_narrow <- panel_est[abs(event_month) <= 12]
did_narrow <- feols(
  log_mean_price ~ post:bad_rating |
    urn + txn_month,
  data = panel_narrow,
  cluster = ~pc_district
)

cat("\nDiD (narrow window, +/- 12 months):\n")
summary(did_narrow)

## ── 4. Heterogeneity: By Rating Category ────────────────────────────────────

cat("\n=== Heterogeneity by Rating ===\n")

# Create rating indicators
panel_est[, outstanding := as.integer(rating == 1)]
panel_est[, ri := as.integer(rating == 3)]
panel_est[, inadequate := as.integer(rating == 4)]

# Model with separate treatment effects by rating
# Reference: Good (rating == 2)
het_model <- feols(
  log_mean_price ~ post:outstanding + post:ri + post:inadequate |
    urn + txn_month,
  data = panel_est,
  cluster = ~pc_district
)

cat("\nHeterogeneity by rating:\n")
summary(het_model)

## ── 5. Heterogeneity: By Deprivation ────────────────────────────────────────

cat("\n=== Heterogeneity by Deprivation (IDACI) ===\n")

# IDACI quintile 1 = most deprived, 5 = least deprived
panel_est[, high_deprivation := as.integer(idaci %in% c(1, 2))]

did_deprived <- feols(
  log_mean_price ~ post:bad_rating + post:bad_rating:high_deprivation |
    urn + txn_month,
  data = panel_est[!is.na(idaci)],
  cluster = ~pc_district
)

cat("\nDiD x Deprivation:\n")
summary(did_deprived)

## ── 6. Save Diagnostics ─────────────────────────────────────────────────────

cat("\n=== Saving diagnostics ===\n")

diagnostics <- list(
  n_treated = uniqueN(panel_est$urn[panel_est$bad_rating == 1]),
  n_control = uniqueN(panel_est$urn[panel_est$bad_rating == 0]),
  n_pre = length(unique(panel_est$event_month[panel_est$event_month < 0])),
  n_obs = nrow(panel_est),
  n_schools = uniqueN(panel_est$urn),
  n_pc_districts = uniqueN(panel_est$pc_district),
  did_coef = coef(did_model)["post:bad_rating"],
  did_se = se(did_model)["post:bad_rating"],
  did_pval = pvalue(did_model)["post:bad_rating"]
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")

# Save model objects for table generation
save(es_model, did_model, did_narrow, het_model, did_deprived,
     file = "data/models.RData")
cat("Model objects saved.\n")

cat("\n=== Main analysis complete ===\n")
cat("Key result: DiD coefficient (post x bad_rating):",
    round(coef(did_model)["post:bad_rating"], 4),
    "(SE:", round(se(did_model)["post:bad_rating"], 4), ")\n")
cat("Interpretation: A bad Ofsted rating (RI/Inadequate) is associated with a",
    round(coef(did_model)["post:bad_rating"] * 100, 2),
    "% change in house prices post-inspection.\n")
