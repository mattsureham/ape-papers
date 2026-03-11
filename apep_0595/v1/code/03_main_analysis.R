# ==============================================================================
# 03_main_analysis.R — Main DiD regressions
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Load analysis data ---
nga_rice <- fread(file.path(DATA_DIR, "nga_rice.csv"))
nga_cereals <- fread(file.path(DATA_DIR, "nga_cereals.csv"))
nga_analysis <- fread(file.path(DATA_DIR, "nga_analysis.csv"))
nga_placebo <- fread(file.path(DATA_DIR, "nga_placebo.csv"))
ben <- fread(file.path(DATA_DIR, "ben_analysis.csv"))

nga_rice[, year_month := as.Date(year_month)]
nga_cereals[, year_month := as.Date(year_month)]
nga_analysis[, year_month := as.Date(year_month)]
nga_placebo[, year_month := as.Date(year_month)]
ben[, year_month := as.Date(year_month)]

# ==============================================================================
# 1. MAIN SPECIFICATION: Rice prices — binary border treatment
# ==============================================================================

# Basic DiD: border × post
m1_basic <- feols(log_price ~ border_market:post | market + year_month,
                  data = nga_rice, cluster = ~market)

# Add commodity fixed effects (rice subtypes)
m1_commodity <- feols(log_price ~ border_market:post | market + year_month + commodity,
                      data = nga_rice, cluster = ~market)

# Continuous treatment: distance gradient
nga_rice[, inv_dist := 1 / (dist_to_border_km + 1)]
nga_rice[, dist_100 := dist_to_border_km / 100]

m1_continuous <- feols(log_price ~ inv_dist:post | market + year_month,
                       data = nga_rice, cluster = ~market)

m1_dist100 <- feols(log_price ~ dist_100:post | market + year_month,
                    data = nga_rice, cluster = ~market)

cat("=== MAIN RESULTS: Rice ===\n")
cat("Binary DiD (border × post):\n")
summary(m1_basic)
cat("\nWith commodity FE:\n")
summary(m1_commodity)
cat("\nContinuous (1/distance × post):\n")
summary(m1_continuous)

# ==============================================================================
# 2. EVENT STUDY: Monthly leads and lags
# ==============================================================================

# Create event-time dummies (omit t = -1)
nga_rice[, event_time_factor := relevel(factor(event_time), ref = "-1")]

# Trim event-time window to -12 to +17
nga_rice_es <- nga_rice[event_time >= -12 & event_time <= 17]

m_es <- feols(log_price ~ i(event_time, border_market, ref = -1) | market + year_month,
              data = nga_rice_es, cluster = ~market)

cat("\n=== EVENT STUDY ===\n")
summary(m_es)

# Save event study coefficients
es_coefs <- as.data.table(coeftable(m_es))
es_coefs[, term := rownames(coeftable(m_es))]
es_coefs <- es_coefs[grepl("event_time", term)]
es_coefs[, event_time := as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))]
setnames(es_coefs, c("estimate", "se", "t_stat", "p_value", "term", "event_time"))
fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

# ==============================================================================
# 3. DISTANCE GRADIENT: Bin-level effects
# ==============================================================================

# Distance bin × post interactions
nga_rice[, dist_bin := factor(dist_bin, levels = c("200+km", "0-100km", "100-200km"))]

m_bins <- feols(log_price ~ i(dist_bin, post, ref = "200+km") | market + year_month,
                data = nga_rice, cluster = ~market)

cat("\n=== DISTANCE GRADIENT ===\n")
summary(m_bins)

# Save bin coefficients
bin_coefs <- as.data.table(coeftable(m_bins))
bin_coefs[, term := rownames(coeftable(m_bins))]
bin_coefs <- bin_coefs[grepl("dist_bin", term)]
fwrite(bin_coefs, file.path(DATA_DIR, "distance_bin_coefs.csv"))

# ==============================================================================
# 4. COMMODITY HETEROGENEITY: By commodity group
# ==============================================================================

# Individual commodity regressions
commodities <- c("rice", "maize", "sorghum", "millet")
commodity_results <- list()

for (cg in commodities) {
  cg_data <- nga_cereals[commodity_group == cg]
  if (nrow(cg_data) > 50 & n_distinct(cg_data$market) >= 5) {
    cg_model <- feols(log_price ~ border_market:post | market + year_month,
                      data = cg_data, cluster = ~market)
    commodity_results[[cg]] <- data.table(
      commodity = cg,
      estimate = coef(cg_model)["border_market:post"],
      se = se(cg_model)["border_market:post"],
      n = nobs(cg_model),
      n_markets = n_distinct(cg_data$market)
    )
    cat("\n", toupper(cg), ":\n")
    print(summary(cg_model))
  }
}

commodity_results_dt <- rbindlist(commodity_results)
fwrite(commodity_results_dt, file.path(DATA_DIR, "commodity_results.csv"))

# ==============================================================================
# 5. NON-TRADEABLE PLACEBO
# ==============================================================================

if (nrow(nga_placebo) > 50 & n_distinct(nga_placebo$market) >= 3) {
  m_placebo <- feols(log_price ~ border_market:post | market + year_month,
                     data = nga_placebo, cluster = ~market)
  cat("\n=== NON-TRADEABLE PLACEBO ===\n")
  summary(m_placebo)

  placebo_result <- data.table(
    commodity = "non_tradeable",
    estimate = coef(m_placebo)["border_market:post"],
    se = se(m_placebo)["border_market:post"],
    n = nobs(m_placebo),
    n_markets = n_distinct(nga_placebo$market)
  )
  fwrite(placebo_result, file.path(DATA_DIR, "placebo_result.csv"))
} else {
  cat("\n=== NON-TRADEABLE PLACEBO: Insufficient data ===\n")
  cat("Non-tradeable obs:", nrow(nga_placebo), "markets:", n_distinct(nga_placebo$market), "\n")
  # Save empty result for downstream
  placebo_result <- data.table(
    commodity = "non_tradeable",
    estimate = NA_real_,
    se = NA_real_,
    n = nrow(nga_placebo),
    n_markets = n_distinct(nga_placebo$market)
  )
  fwrite(placebo_result, file.path(DATA_DIR, "placebo_result.csv"))
}

# ==============================================================================
# 6. CROSS-BORDER VALIDATION: Benin rice prices
# ==============================================================================

ben_rice <- ben[commodity_group == "rice"]

if (nrow(ben_rice) > 50) {
  # For Benin, "border_market_ben" = close to Nigeria border
  # Post-closure, Benin border prices should FALL (goods trapped on supply side)
  if ("border_market_ben" %in% names(ben_rice) & sum(!is.na(ben_rice$border_market_ben)) > 0) {
    m_benin <- feols(log_price ~ border_market_ben:post | market + year_month,
                     data = ben_rice[!is.na(border_market_ben)], cluster = ~market)
    cat("\n=== BENIN CROSS-BORDER (border proximity) ===\n")
    summary(m_benin)
  }

  # Simple pre/post for all Benin rice markets
  m_benin_simple <- feols(log_price ~ post | market,
                          data = ben_rice, cluster = ~market)
  cat("\n=== BENIN CROSS-BORDER (pre/post all markets) ===\n")
  summary(m_benin_simple)

  benin_result <- data.table(
    country = "Benin",
    commodity = "rice",
    estimate = coef(m_benin_simple)["post"],
    se = se(m_benin_simple)["post"],
    n = nobs(m_benin_simple),
    n_markets = n_distinct(ben_rice$market)
  )
  fwrite(benin_result, file.path(DATA_DIR, "benin_result.csv"))
}

# ==============================================================================
# 7. Save main model objects for figures/tables
# ==============================================================================

saveRDS(m1_basic, file.path(DATA_DIR, "model_main_basic.rds"))
saveRDS(m1_commodity, file.path(DATA_DIR, "model_main_commodity.rds"))
saveRDS(m1_continuous, file.path(DATA_DIR, "model_main_continuous.rds"))
saveRDS(m_es, file.path(DATA_DIR, "model_event_study.rds"))
saveRDS(m_bins, file.path(DATA_DIR, "model_distance_bins.rds"))

# ==============================================================================
# 8. NATIONWIDE PRICE LEVEL: Did ALL rice prices rise?
# ==============================================================================

# Simple pre/post comparison for all markets
nga_rice_summary <- nga_rice[, .(
  mean_price = mean(price, na.rm = TRUE),
  median_price = median(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  n_obs = .N
), by = .(post, border_market)]

cat("\n=== NATIONWIDE PRICE LEVELS ===\n")
print(nga_rice_summary)

# DiD in levels (not just log)
m_levels <- feols(price ~ border_market:post | market + year_month,
                  data = nga_rice, cluster = ~market)
cat("\nDiD in levels (price, not log):\n")
summary(m_levels)

# Check by rice subtype (imported vs local)
cat("\n=== RICE SUBTYPES ===\n")
print(nga_rice[, .N, by = commodity][order(-N)])

# Separate imported vs local rice
nga_rice[, rice_type := fcase(
  grepl("imported|import", commodity_lower), "imported",
  grepl("local", commodity_lower), "local",
  default = "other_rice"
)]
print(nga_rice[, .N, by = rice_type])

for (rt in unique(nga_rice$rice_type)) {
  rt_data <- nga_rice[rice_type == rt]
  if (nrow(rt_data) > 30 & n_distinct(rt_data$market) >= 5) {
    rt_model <- feols(log_price ~ border_market:post | market + year_month,
                      data = rt_data, cluster = ~market)
    cat("\nRice type:", rt, "\n")
    print(summary(rt_model))
  }
}

# Save rice type results
rice_type_results <- list()
for (rt in unique(nga_rice$rice_type)) {
  rt_data <- nga_rice[rice_type == rt]
  if (nrow(rt_data) > 30 & n_distinct(rt_data$market) >= 5) {
    rt_model <- feols(log_price ~ border_market:post | market + year_month,
                      data = rt_data, cluster = ~market)
    rice_type_results[[rt]] <- data.table(
      rice_type = rt,
      estimate = coef(rt_model)["border_market:post"],
      se = se(rt_model)["border_market:post"],
      n = nobs(rt_model),
      n_markets = n_distinct(rt_data$market)
    )
  }
}
if (length(rice_type_results) > 0) {
  fwrite(rbindlist(rice_type_results), file.path(DATA_DIR, "rice_type_results.csv"))
}

# ==============================================================================
# 9. TRIPLE-DIFFERENCE: Imported rice vs local rice × border × post
# ==============================================================================

# If we have both imported and local rice, use triple-diff
if (sum(nga_rice$rice_type == "imported") > 30 & sum(nga_rice$rice_type == "local") > 30) {
  nga_rice[, imported := as.integer(rice_type == "imported")]
  m_ddd <- feols(log_price ~ border_market:post:imported + border_market:post +
                   imported:post | market + year_month + commodity,
                 data = nga_rice, cluster = ~market)
  cat("\n=== TRIPLE DIFFERENCE (imported × border × post) ===\n")
  summary(m_ddd)
  saveRDS(m_ddd, file.path(DATA_DIR, "model_triple_diff.rds"))
}

cat("\n=== All main analysis complete. Models saved. ===\n")
