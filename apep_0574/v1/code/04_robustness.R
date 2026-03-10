## 04_robustness.R — Robustness checks
## APEP-0574: Gas Shock Import Substitution
## Inputs:  trade_panel.csv, production_panel.csv
## Outputs: robustness_loo.csv, robustness_binary.csv, robustness_exposure.csv,
##          pretrend_ftest.csv, robustness_food_placebo.csv

source("00_packages.R")

data_dir <- "../data/"

# =====================================================================
# 1. READ PANELS
# =====================================================================
cat("=== Reading analysis panels ===\n")

trade_panel <- fread(file.path(data_dir, "trade_panel.csv"))
prod_panel  <- fread(file.path(data_dir, "production_panel.csv"))

cat(sprintf("  Trade panel:      %d rows\n", nrow(trade_panel)))
cat(sprintf("  Production panel: %d rows\n", nrow(prod_panel)))

# Helper function for coefficient extraction
extract_coefs <- function(model, model_name) {
  ct <- as.data.frame(coeftable(model))
  ct$term <- rownames(ct)
  ct$model <- model_name
  rownames(ct) <- NULL
  setnames(ct, c("estimate", "se", "tstat", "pvalue", "term", "model"))
  as.data.table(ct)
}

# =====================================================================
# 2. LEAVE-ONE-OUT BY COUNTRY
# =====================================================================
cat("\n=== Robustness: Leave-one-out by country ===\n")

countries <- unique(trade_panel$geo)
loo_results <- list()

for (cc in countries) {
  cat(sprintf("  Dropping %s...\n", cc))
  dt_loo <- trade_panel[geo != cc]

  m_loo <- tryCatch(
    feols(
      log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
        country_year + sitc_year + country_sitc,
      data = dt_loo,
      cluster = ~geo
    ),
    error = function(e) NULL
  )

  if (!is.null(m_loo)) {
    coefs <- extract_coefs(m_loo, paste0("loo_drop_", cc))
    # Keep only the triple-diff coefficient
    triple_coef <- coefs[grepl("gas_dep.*ei.*post_shock", term)]
    if (nrow(triple_coef) > 0) {
      triple_coef[, dropped_country := cc]
      loo_results[[cc]] <- triple_coef
    }
  }
}

loo_dt <- rbindlist(loo_results)

# Add full-sample estimate for comparison
m_full <- feols(
  log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
full_coef <- extract_coefs(m_full, "full_sample")
full_coef <- full_coef[grepl("gas_dep.*ei.*post_shock", term)]
full_coef[, dropped_country := "none"]
loo_dt <- rbind(loo_dt, full_coef, fill = TRUE)

fwrite(loo_dt, file.path(data_dir, "robustness_loo.csv"))
cat(sprintf("LOO results: %d rows (dropped %d countries)\n",
            nrow(loo_dt), uniqueN(loo_dt$dropped_country) - 1))

# =====================================================================
# 3. BINARY GAS DEPENDENCE
# =====================================================================
cat("\n=== Robustness: Binary gas dependence ===\n")

# Binary: above/below median
m_binary_trade <- feols(
  log_imports ~ gas_dep_binary:ei:post_shock + gas_dep_binary:post_shock +
    ei:post_shock + gas_dep_binary:ei |
    sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("Binary gas dependence (trade):\n")
summary(m_binary_trade)

# Also run on production panel
prod_panel[, gas_dep_binary := as.integer(gas_dep > median(gas_dep))]

m_binary_prod <- feols(
  prod_index ~ gas_dep_binary:ei:post_shock + gas_dep_binary:post_shock +
    ei:post_shock + gas_dep_binary:ei |
    nace_ym + country_nace,
  data = prod_panel,
  cluster = ~geo
)
cat("\nBinary gas dependence (production):\n")
summary(m_binary_prod)

binary_results <- rbind(
  extract_coefs(m_binary_trade, "binary_trade"),
  extract_coefs(m_binary_prod, "binary_production")
)
fwrite(binary_results, file.path(data_dir, "robustness_binary.csv"))

# =====================================================================
# 4. ALTERNATIVE TREATMENT: gas_exposure (russian_share × gas_tpes_share)
# =====================================================================
cat("\n=== Robustness: Gas exposure measure ===\n")

m_exposure_trade <- feols(
  log_imports ~ gas_exposure:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)
cat("Gas exposure (trade):\n")
summary(m_exposure_trade)

prod_panel[, gas_exposure_prod := gas_dep * prod_panel[, first(gas_tpes_share), by = geo]$V1[match(geo, unique(geo))]]
# Simpler: just merge from original data
gas_dep_dt <- fread(file.path(data_dir, "gas_dependence.csv"))
prod_panel <- merge(prod_panel, gas_dep_dt[, .(geo, gas_exposure_alt = gas_exposure)],
                    by = "geo", all.x = TRUE)

m_exposure_prod <- feols(
  prod_index ~ gas_exposure_alt:ei:post_shock + ei:post_shock |
    country_nace + nace_ym,
  data = prod_panel,
  cluster = ~geo
)
cat("\nGas exposure (production):\n")
summary(m_exposure_prod)

exposure_results <- rbind(
  extract_coefs(m_exposure_trade, "exposure_trade"),
  extract_coefs(m_exposure_prod, "exposure_production")
)
fwrite(exposure_results, file.path(data_dir, "robustness_exposure.csv"))

# =====================================================================
# 5. PRE-TREND F-TEST ON TRADE PANEL
# =====================================================================
cat("\n=== Robustness: Pre-trend F-test ===\n")

# Restrict to pre-period only (2017-2021)
trade_pre <- trade_panel[year < 2022]

# Create year dummies interacted with gas_dep × ei
trade_pre[, year_f := factor(year)]

trade_pre[, gas_dep_ei := gas_dep * ei]

m_pretrend <- feols(
  log_imports ~ i(year_f, gas_dep_ei, ref = "2021") |
    country_year + sitc_year + country_sitc,
  data = trade_pre,
  cluster = ~geo
)
cat("Pre-trend test (trade panel):\n")
summary(m_pretrend)

# Joint F-test: all pre-treatment year interactions = 0
pretrend_coefs <- as.data.frame(coeftable(m_pretrend))
pretrend_coefs$term <- rownames(pretrend_coefs)
rownames(pretrend_coefs) <- NULL
setnames(pretrend_coefs, c("estimate", "se", "tstat", "pvalue", "term"))
pretrend_coefs <- as.data.table(pretrend_coefs)

# Wald test
wald_test <- tryCatch({
  wt <- wald(m_pretrend, "year_f")
  data.table(
    fstat   = wt$stat,
    pvalue  = wt$p,
    df1     = wt$df1,
    df2     = wt$df2,
    test    = "joint_pretrend"
  )
}, error = function(e) {
  cat("  Wald test error: ", e$message, "\n")
  # Manual F-test from coefficients
  data.table(
    fstat   = mean(pretrend_coefs$tstat^2, na.rm = TRUE),
    pvalue  = NA_real_,
    df1     = nrow(pretrend_coefs),
    df2     = NA_real_,
    test    = "approx_joint_pretrend"
  )
})

pretrend_out <- rbind(
  pretrend_coefs[, .(term, estimate, se, tstat, pvalue, model = "pretrend_years")],
  data.table(term = "F-test", estimate = wald_test$fstat, se = NA,
             tstat = NA, pvalue = wald_test$pvalue, model = "joint_f_test")
)

fwrite(pretrend_out, file.path(data_dir, "pretrend_ftest.csv"))
cat(sprintf("Pre-trend F-stat: %.3f, p-value: %.4f\n",
            wald_test$fstat, wald_test$pvalue))

# =====================================================================
# 6. PLACEBO: Food (SITC 0+1) as alternative control group
# =====================================================================
cat("\n=== Robustness: Food placebo ===\n")

# Read raw trade data to get food category
trade_raw <- fread(file.path(data_dir, "trade_annual.csv"))
gas_dep_raw <- fread(file.path(data_dir, "gas_dependence.csv"))

# Create alternative panel: chemicals (treated) vs food (placebo)
food_placebo <- trade_raw[sitc06 %in% c("SITC5", "SITC0_1")]
food_placebo <- merge(food_placebo, gas_dep_raw[, .(geo, russian_gas_share, gas_exposure)],
                       by = "geo", all.x = TRUE)
food_placebo[, `:=`(
  log_imports = log(pmax(import_mio_eur, 0.01)),
  gas_dep     = russian_gas_share,
  ei          = as.integer(sitc06 == "SITC5"),  # Chemicals = treated
  post_shock  = as.integer(year >= 2022),
  country_year  = paste0(geo, "_", year),
  sitc_year     = paste0(sitc06, "_", year),
  country_sitc  = paste0(geo, "_", sitc06)
)]

m_food <- feols(
  log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = food_placebo,
  cluster = ~geo
)
cat("Food placebo (chemicals vs food):\n")
summary(m_food)

# Also test: machinery vs food (both should be non-energy-intensive → null effect)
null_placebo <- trade_raw[sitc06 %in% c("SITC7", "SITC0_1")]
null_placebo <- merge(null_placebo, gas_dep_raw[, .(geo, russian_gas_share)],
                       by = "geo", all.x = TRUE)
null_placebo[, `:=`(
  log_imports = log(pmax(import_mio_eur, 0.01)),
  gas_dep     = russian_gas_share,
  ei          = as.integer(sitc06 == "SITC7"),  # Machinery vs food — both non-EI
  post_shock  = as.integer(year >= 2022),
  country_year  = paste0(geo, "_", year),
  sitc_year     = paste0(sitc06, "_", year),
  country_sitc  = paste0(geo, "_", sitc06)
)]

m_null <- feols(
  log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
    country_year + sitc_year + country_sitc,
  data = null_placebo,
  cluster = ~geo
)
cat("\nNull placebo (machinery vs food — both non-EI):\n")
summary(m_null)

food_results <- rbind(
  extract_coefs(m_food, "food_placebo_chem_vs_food"),
  extract_coefs(m_null, "null_placebo_mach_vs_food")
)
fwrite(food_results, file.path(data_dir, "robustness_food_placebo.csv"))

# =====================================================================
# 7. PRODUCTION LEAVE-ONE-OUT
# =====================================================================
cat("\n=== Robustness: Production LOO ===\n")

prod_countries <- unique(prod_panel$geo)
prod_loo_results <- list()

for (cc in prod_countries) {
  m_loo_p <- tryCatch(
    feols(
      prod_index ~ gas_dep:ei:post_shock + ei:post_shock |
        country_nace + nace_ym,
      data = prod_panel[geo != cc],
      cluster = ~geo
    ),
    error = function(e) NULL
  )

  if (!is.null(m_loo_p)) {
    coefs <- extract_coefs(m_loo_p, paste0("prod_loo_drop_", cc))
    triple_coef <- coefs[grepl("gas_dep.*ei.*post_shock", term)]
    if (nrow(triple_coef) > 0) {
      triple_coef[, dropped_country := cc]
      prod_loo_results[[cc]] <- triple_coef
    }
  }
}

prod_loo_dt <- rbindlist(prod_loo_results)

# Add full-sample
m_full_prod <- feols(
  prod_index ~ gas_dep:ei:post_shock + ei:post_shock |
    country_nace + nace_ym,
  data = prod_panel,
  cluster = ~geo
)
full_prod_coef <- extract_coefs(m_full_prod, "prod_full_sample")
full_prod_coef <- full_prod_coef[grepl("gas_dep.*ei.*post_shock", term)]
full_prod_coef[, dropped_country := "none"]
prod_loo_dt <- rbind(prod_loo_dt, full_prod_coef, fill = TRUE)

fwrite(prod_loo_dt, file.path(data_dir, "robustness_prod_loo.csv"))

# =====================================================================
# 8. RAMBACHAN-ROTH SENSITIVITY (TRADE PANEL)
# =====================================================================
cat("\n=== Robustness: Rambachan-Roth sensitivity ===\n")

# Estimate event study on trade panel for RR analysis
trade_panel[, year_f := factor(year)]
trade_panel[, gas_dep_ei := gas_dep * ei]

m_trade_es <- feols(
  log_imports ~ i(year_f, gas_dep_ei, ref = "2021") |
    country_year + sitc_year + country_sitc,
  data = trade_panel,
  cluster = ~geo
)

# Extract pre and post coefficients for manual RR bounds
es_ct <- as.data.frame(coeftable(m_trade_es))
es_ct$term <- rownames(es_ct)
rownames(es_ct) <- NULL
es_ct <- as.data.table(es_ct)
setnames(es_ct, c("estimate", "se", "tstat", "pvalue", "term"))

# Parse year from term names
es_ct[, year_val := as.integer(gsub(".*::(\\d{4}).*", "\\1", term))]
es_ct <- es_ct[!is.na(year_val)]

# Separate pre and post
pre_coefs  <- es_ct[year_val < 2021]
post_coefs <- es_ct[year_val >= 2022]

# Compute max absolute pre-trend deviation as M-bar proxy
# M-bar = max change in consecutive pre-period coefficients
pre_sorted <- pre_coefs[order(year_val)]
if (nrow(pre_sorted) > 1) {
  diffs <- abs(diff(pre_sorted$estimate))
  M_bar <- max(diffs)
} else {
  M_bar <- max(abs(pre_sorted$estimate))
}

# Conservative M-bar values: 1x, 1.5x, 2x the observed max pre-trend deviation
M_values <- c(M_bar, 1.5 * M_bar, 2 * M_bar)

# For each post-period coefficient, compute RR-style bounds:
# [beta - M*k, beta + M*k] where k = periods since treatment
rr_results <- list()
for (i in seq_len(nrow(post_coefs))) {
  yr <- post_coefs$year_val[i]
  beta <- post_coefs$estimate[i]
  se_val <- post_coefs$se[i]
  k <- yr - 2021  # periods since treatment

  for (j in seq_along(M_values)) {
    M <- M_values[j]
    # Confidence set: [beta - 1.96*SE - M*k, beta + 1.96*SE + M*k]
    lower <- beta - 1.96 * se_val - M * k
    upper <- beta + 1.96 * se_val + M * k

    rr_results[[length(rr_results) + 1]] <- data.table(
      year = yr,
      periods_post = k,
      M_bar_label = c("1x", "1.5x", "2x")[j],
      M_bar_value = round(M, 4),
      beta = round(beta, 4),
      se = round(se_val, 4),
      rr_lower = round(lower, 4),
      rr_upper = round(upper, 4),
      upper_positive = upper > 0
    )
  }
}

rr_dt <- rbindlist(rr_results)
fwrite(rr_dt, file.path(data_dir, "rambachan_roth.csv"))

cat(sprintf("Rambachan-Roth bounds computed for %d post-periods × %d M-bar values\n",
            nrow(post_coefs), length(M_values)))
cat(sprintf("Max pre-trend deviation (M-bar): %.4f\n", M_bar))
cat("Upper bounds exceed zero (import substitution):\n")
print(rr_dt[, .(any_positive_upper = any(upper_positive)), by = M_bar_label])

# =====================================================================
# 9. HETEROGENEITY: BY PRODUCT GROUP
# =====================================================================
cat("\n=== Heterogeneity: By product group ===\n")

sitc_groups <- unique(trade_panel$sitc06)
het_product <- list()

for (sg in sitc_groups) {
  # Each SITC group vs all others (or individual estimates)
  dt_sg <- trade_panel[sitc06 == sg]
  if (nrow(dt_sg) < 20) next

  # Simple DiD for this product: gas_dep × post
  m_sg <- tryCatch(
    feols(
      log_imports ~ gas_dep:post_shock |
        geo + year,
      data = dt_sg,
      cluster = ~geo
    ),
    error = function(e) NULL
  )

  if (!is.null(m_sg)) {
    ct_sg <- as.data.frame(coeftable(m_sg))
    ct_sg$term <- rownames(ct_sg)
    triple_row <- ct_sg[grepl("gas_dep.*post_shock", ct_sg$term), ]
    if (nrow(triple_row) > 0) {
      het_product[[sg]] <- data.table(
        sitc_group = sg,
        estimate = triple_row[1, 1],
        se = triple_row[1, 2],
        tstat = triple_row[1, 3],
        pvalue = triple_row[1, 4],
        n_obs = nobs(m_sg)
      )
    }
  }
}

het_product_dt <- rbindlist(het_product)
fwrite(het_product_dt, file.path(data_dir, "heterogeneity_product.csv"))
cat("Product heterogeneity:\n")
print(het_product_dt)

# =====================================================================
# 10. HETEROGENEITY: BY COUNTRY GROUP
# =====================================================================
cat("\n=== Heterogeneity: By country group ===\n")

# Define groups: Central/Eastern Europe vs Western Europe
cee_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")
trade_panel[, region := ifelse(geo %in% cee_countries, "CEE", "Western")]

het_region <- list()
for (rg in c("CEE", "Western")) {
  dt_rg <- trade_panel[region == rg]
  m_rg <- tryCatch(
    feols(
      log_imports ~ gas_dep:ei:post_shock + ei:post_shock |
        country_year + sitc_year + country_sitc,
      data = dt_rg,
      cluster = ~geo
    ),
    error = function(e) NULL
  )

  if (!is.null(m_rg)) {
    ct_rg <- as.data.frame(coeftable(m_rg))
    ct_rg$term <- rownames(ct_rg)
    triple_row <- ct_rg[grepl("gas_dep.*ei.*post_shock", ct_rg$term), ]
    if (nrow(triple_row) > 0) {
      het_region[[rg]] <- data.table(
        region = rg,
        estimate = triple_row[1, 1],
        se = triple_row[1, 2],
        tstat = triple_row[1, 3],
        pvalue = triple_row[1, 4],
        n_obs = nobs(m_rg)
      )
    }
  }
}

het_region_dt <- rbindlist(het_region)
fwrite(het_region_dt, file.path(data_dir, "heterogeneity_region.csv"))
cat("Region heterogeneity:\n")
print(het_region_dt)

# =====================================================================
# 11. Production Event Study with Country×Month FE
# Reviewer concern: original spec lacks country×month FE, leaving
# country-level monthly shocks as potential confound
# =====================================================================
cat("\n=== Section 11: Production Event Study with Saturated FE ===\n")

# Create country×year-month interaction variable
prod_panel[, country_ym := paste0(geo, "_", format(as.Date(paste0(year, "-", month, "-01")), "%Y%m"))]
prod_panel[, gas_dep_ei := gas_dep * ei]

# Full saturated FE: country×month + sector×month + country×sector
m_es_saturated <- feols(
  prod_index ~ i(rel_month_binned, gas_dep_ei, ref = -1) |
    country_nace + nace_ym + country_ym,
  data = prod_panel,
  cluster = ~geo
)
cat("Production event study with country×month FE:\n")
summary(m_es_saturated)

# Extract coefficients for comparison
es_sat_coefs <- as.data.frame(coeftable(m_es_saturated))
es_sat_coefs$term <- rownames(es_sat_coefs)
rownames(es_sat_coefs) <- NULL
setnames(es_sat_coefs, c("estimate", "se", "tstat", "pvalue", "term"))
es_sat_coefs <- as.data.table(es_sat_coefs)
es_sat_coefs[, rel_month := as.integer(gsub(".*::(-?[0-9]+).*", "\\1", term))]
es_sat_coefs[, ci_lower := estimate - 1.96 * se]
es_sat_coefs[, ci_upper := estimate + 1.96 * se]

# Add reference period
ref_sat <- data.table(estimate = 0, se = 0, tstat = NA, pvalue = NA,
                       term = "reference", rel_month = -1,
                       ci_lower = 0, ci_upper = 0)
es_sat_coefs <- rbind(es_sat_coefs, ref_sat)
es_sat_coefs <- es_sat_coefs[order(rel_month)]

fwrite(es_sat_coefs, file.path(data_dir, "event_study_saturated_fe.csv"))
cat(sprintf("Saturated FE event study: %d coefficients, N=%d\n",
    nrow(es_sat_coefs), nobs(m_es_saturated)))

# Compare key post-treatment coefficient (k=6, Aug 2022)
orig_es <- fread(file.path(data_dir, "event_study_production.csv"))
k6_orig <- orig_es[rel_month == 6]
k6_sat <- es_sat_coefs[rel_month == 6]
cat(sprintf("\nComparison at k=6 (Aug 2022):\n"))
cat(sprintf("  Original (sector×month + country×sector FE): %.3f (SE=%.3f)\n",
    k6_orig$estimate, k6_orig$se))
cat(sprintf("  Saturated (+ country×month FE):              %.3f (SE=%.3f)\n",
    k6_sat$estimate, k6_sat$se))

# =====================================================================
# SUMMARY
# =====================================================================
cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
cat("Files saved:\n")
cat("  - robustness_loo.csv (leave-one-out, trade)\n")
cat("  - robustness_prod_loo.csv (leave-one-out, production)\n")
cat("  - robustness_binary.csv (binary gas dep)\n")
cat("  - robustness_exposure.csv (gas exposure measure)\n")
cat("  - pretrend_ftest.csv (pre-trend test)\n")
cat("  - robustness_food_placebo.csv (food placebo)\n")
cat("  - rambachan_roth.csv (RR sensitivity bounds)\n")
cat("  - heterogeneity_product.csv (by product group)\n")
cat("  - heterogeneity_region.csv (by country group)\n")
