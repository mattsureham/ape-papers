# 03_main_analysis.R — Main regressions for Egypt devaluation paper
# APEP-0569: Egypt Devaluation Import Compression

source("00_packages.R")
DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, bec3 := factor(bec3, levels = c("intermediate", "capital", "final"))]
panel[, year := as.integer(year)]
panel[, product_id := as.integer(factor(hs6))]

cat(sprintf("Analysis panel: %d obs, %d products, %d years\n",
  nrow(panel), uniqueN(panel$hs6), uniqueN(panel$year)))

# ============================================================
# MODEL 1: Basic DiD — Post × BEC category
# ============================================================
cat("\n=== Model 1: Basic Post × BEC ===\n")

# Final consumption is the omitted category
m1 <- feols(log_imports ~ post:is_intermediate + post:is_capital |
  product_id + year,
data = panel[bec3 != "fuels" | bec_category != "fuels"],
cluster = ~hs2)

summary(m1)

# With fuels excluded entirely (cleaner sample)
m1b <- feols(log_imports ~ post:is_intermediate + post:is_capital |
  product_id + year,
data = panel[bec_category != "fuels"],
cluster = ~hs2)

summary(m1b)

# ============================================================
# MODEL 2: Event study — Year × BEC interactions
# ============================================================
cat("\n=== Model 2: Event Study ===\n")

# Create year factor (omit 2015 as reference)
panel[, year_f := factor(year)]

m2 <- feols(log_imports ~ i(year, is_intermediate, ref = 2015) +
  i(year, is_capital, ref = 2015) |
  product_id + year,
data = panel[bec_category != "fuels"],
cluster = ~hs2)

summary(m2)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(m2), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))

# Parse year and BEC from coefficient names
es_coefs[, bec_type := fifelse(grepl("is_intermediate", term), "Intermediate",
  fifelse(grepl("is_capital", term), "Capital", NA_character_))]
es_coefs[, yr := as.integer(gsub(".*year::([0-9]+).*", "\\1", term))]
es_coefs <- es_coefs[!is.na(bec_type) & !is.na(yr)]

# Add reference year (2015) with zero
ref_rows <- data.table(
  term = c("ref_int", "ref_cap"),
  estimate = c(0, 0), se = c(0, 0), tstat = c(0, 0), pval = c(1, 1),
  bec_type = c("Intermediate", "Capital"),
  yr = c(2015, 2015)
)
es_coefs <- rbind(es_coefs, ref_rows, fill = TRUE)

# CI
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))
cat("Event study coefficients saved.\n")

# ============================================================
# MODEL 3: Triple-difference with continuous treatment
# ============================================================
cat("\n=== Model 3: Continuous treatment (pre-period import level) ===\n")

m3 <- feols(log_imports ~ post:is_intermediate:log_pre_import +
  post:is_capital:log_pre_import +
  post:is_intermediate + post:is_capital +
  post:log_pre_import |
  product_id + year,
data = panel[bec_category != "fuels" & !is.na(log_pre_import)],
cluster = ~hs2)

summary(m3)

# ============================================================
# MODEL 4: Extensive margin — product entry/exit
# ============================================================
cat("\n=== Model 4: Extensive margin ===\n")

# Create balanced panel skeleton
all_products <- unique(panel$hs6)
all_years <- unique(panel$year)
skeleton <- CJ(hs6 = all_products, year = all_years)

# Merge with actual data
skeleton <- merge(skeleton, panel[, .(hs6, year, import_value, bec3, bec_category,
  is_intermediate, is_capital, is_final, hs2)],
by = c("hs6", "year"), all.x = TRUE)

# Fill BEC classification from any year
bec_lookup <- unique(panel[, .(hs6, bec3_fill = bec3, bec_cat_fill = bec_category,
  is_int_fill = is_intermediate, is_cap_fill = is_capital,
  is_fin_fill = is_final, hs2_fill = hs2)])
bec_lookup <- bec_lookup[!duplicated(hs6)]
skeleton <- merge(skeleton, bec_lookup, by = "hs6", all.x = TRUE)

skeleton[is.na(bec3), bec3 := bec3_fill]
skeleton[is.na(is_intermediate), is_intermediate := is_int_fill]
skeleton[is.na(is_capital), is_capital := is_cap_fill]
skeleton[is.na(is_final), is_final := is_fin_fill]
skeleton[is.na(hs2), hs2 := hs2_fill]
skeleton[is.na(bec_category), bec_category := bec_cat_fill]

# Indicator for product being imported
skeleton[, imported := as.integer(!is.na(import_value) & import_value > 0)]
skeleton[, post := as.integer(year >= 2017)]
skeleton[, product_id := as.integer(factor(hs6))]

# Extensive margin regression
m4 <- feols(imported ~ post:is_intermediate + post:is_capital |
  product_id + year,
data = skeleton[bec_category != "fuels" | is.na(bec_category)],
cluster = ~hs2)

summary(m4)

# Count active products by BEC × year
variety_counts <- skeleton[, .(n_varieties = sum(imported, na.rm = TRUE)),
  by = .(year, bec3)]
fwrite(variety_counts, file.path(DATA_DIR, "variety_counts.csv"))

# ============================================================
# MODEL 5: Separate value and weight effects
# ============================================================
cat("\n=== Model 5: Value vs. weight decomposition ===\n")

panel_wgt <- panel[!is.na(netWgt) & netWgt > 0 & bec_category != "fuels"]
panel_wgt[, log_weight := log(netWgt)]
panel_wgt[, log_unit_value := log(import_value / netWgt)]

if (nrow(panel_wgt) > 1000) {
  m5_weight <- feols(log_weight ~ post:is_intermediate + post:is_capital |
    product_id + year,
  data = panel_wgt, cluster = ~hs2)

  m5_uv <- feols(log_unit_value ~ post:is_intermediate + post:is_capital |
    product_id + year,
  data = panel_wgt, cluster = ~hs2)

  cat("\nWeight effect:\n")
  summary(m5_weight)
  cat("\nUnit value effect:\n")
  summary(m5_uv)
} else {
  cat("Insufficient weight data for decomposition.\n")
  m5_weight <- NULL
  m5_uv <- NULL
}

# ============================================================
# Save all models
# ============================================================
cat("\n=== Saving regression results ===\n")

# Main results table data
main_results <- data.table(
  model = c("Basic DiD", "Event Study", "Continuous Trt", "Extensive Margin"),
  n_obs = c(nobs(m1b), nobs(m2), nobs(m3), nobs(m4)),
  n_products = c(
    panel[bec_category != "fuels", uniqueN(hs6)],
    panel[bec_category != "fuels", uniqueN(hs6)],
    panel[bec_category != "fuels" & !is.na(log_pre_import), uniqueN(hs6)],
    skeleton[bec_category != "fuels" | is.na(bec_category), uniqueN(hs6)]
  )
)

# Extract key coefficients from m1b
coefs_m1 <- coeftable(m1b)
main_results[model == "Basic DiD", `:=`(
  beta_intermediate = coefs_m1["post:is_intermediate", "Estimate"],
  se_intermediate = coefs_m1["post:is_intermediate", "Std. Error"],
  beta_capital = coefs_m1["post:is_capital", "Estimate"],
  se_capital = coefs_m1["post:is_capital", "Std. Error"]
)]

# Extract from m4
coefs_m4 <- coeftable(m4)
main_results[model == "Extensive Margin", `:=`(
  beta_intermediate = coefs_m4["post:is_intermediate", "Estimate"],
  se_intermediate = coefs_m4["post:is_intermediate", "Std. Error"],
  beta_capital = coefs_m4["post:is_capital", "Estimate"],
  se_capital = coefs_m4["post:is_capital", "Std. Error"]
)]

fwrite(main_results, file.path(DATA_DIR, "main_results.csv"))

# Save model objects for tables
save(m1, m1b, m2, m3, m4, m5_weight, m5_uv,
  file = file.path(DATA_DIR, "models.RData"))

# Compute SD of outcome for SDE calculation
panel_nofuel <- panel[bec_category != "fuels"]
sd_y <- sd(panel_nofuel$log_imports, na.rm = TRUE)
cat(sprintf("\nSD(log imports) = %.4f\n", sd_y))
cat(sprintf("SDE(intermediate) = %.4f\n",
  coefs_m1["post:is_intermediate", "Estimate"] / sd_y))
cat(sprintf("SDE(capital) = %.4f\n",
  coefs_m1["post:is_capital", "Estimate"] / sd_y))

sde_data <- data.table(
  outcome = c("Log imports (intermediate)", "Log imports (capital)"),
  specification = c("Table 2, Col. 2", "Table 2, Col. 2"),
  beta = c(coefs_m1["post:is_intermediate", "Estimate"],
           coefs_m1["post:is_capital", "Estimate"]),
  sd_y = sd_y,
  sde = c(coefs_m1["post:is_intermediate", "Estimate"] / sd_y,
          coefs_m1["post:is_capital", "Estimate"] / sd_y)
)
fwrite(sde_data, file.path(DATA_DIR, "sde_table.csv"))

cat("\n=== Main analysis complete ===\n")
