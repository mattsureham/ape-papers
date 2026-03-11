# ============================================================================
# 04_robustness.R — Robustness checks and mechanism tests
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_main <- panel[time >= 2012 & time <= 2019]

# -----------------------------------------------------------------------
# 1. LEAVE-ONE-COUNTRY-OUT
# -----------------------------------------------------------------------
cat("=== LEAVE-ONE-COUNTRY-OUT ===\n")

countries <- unique(panel_main$country)
loo_results <- rbindlist(lapply(countries, function(c) {
  sub <- panel_main[country != c]
  m <- feols(log_foreign ~ border_post | geo + time,
             data = sub, cluster = ~country)
  data.table(
    excluded = c,
    beta = coef(m)[1],
    se = se(m)[1],
    n_obs = nobs(m),
    n_regions = uniqueN(sub$geo)
  )
}))

cat("Leave-one-out range:", round(range(loo_results$beta), 4), "\n")
fwrite(loo_results, file.path(data_dir, "loo_results.csv"))

# -----------------------------------------------------------------------
# 2. MATCHING (Coarsened Exact Matching on pre-treatment levels)
# -----------------------------------------------------------------------
cat("\n=== MATCHED SAMPLE ===\n")

# Match border and interior regions on pre-treatment foreign nights level
pre_avg <- panel_main[time <= 2016, .(
  pre_foreign = mean(foreign_nights, na.rm = TRUE),
  pre_domestic = mean(domestic_nights, na.rm = TRUE),
  pre_pop = mean(population, na.rm = TRUE)
), by = .(geo, border, country)]

# Quartile-based CEM
pre_avg[, foreign_q := cut(pre_foreign, breaks = quantile(pre_foreign, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                           include.lowest = TRUE, labels = FALSE)]
pre_avg[, pop_q := cut(pre_pop, breaks = quantile(pre_pop, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                       include.lowest = TRUE, labels = FALSE)]

# Keep strata with both border=1 and border=0
pre_avg[, strata := paste(foreign_q, pop_q, sep = "_")]
strata_counts <- pre_avg[, .(n_border = sum(border == 1),
                              n_interior = sum(border == 0)), by = strata]
good_strata <- strata_counts[n_border > 0 & n_interior > 0]$strata
matched_geos <- pre_avg[strata %in% good_strata]$geo

cat("Matched sample:", length(matched_geos), "regions (",
    sum(pre_avg[geo %in% matched_geos]$border), "border)\n")

m_matched <- feols(log_foreign ~ border_post | geo + time,
                   data = panel_main[geo %in% matched_geos], cluster = ~country)
cat("Matched DiD:\n")
print(summary(m_matched))

# -----------------------------------------------------------------------
# 3. PLACEBO TIMING (pre-treatment fake treatment at 2015)
# -----------------------------------------------------------------------
cat("\n=== PLACEBO TIMING ===\n")

panel_placebo <- panel_main[time >= 2012 & time <= 2016]
panel_placebo[, fake_post := as.integer(time >= 2015)]
panel_placebo[, fake_treat := border * fake_post]

m_placebo <- feols(log_foreign ~ fake_treat | geo + time,
                   data = panel_placebo, cluster = ~country)
cat("Placebo (fake treatment 2015):\n")
print(summary(m_placebo))

# -----------------------------------------------------------------------
# 4. ALTERNATIVE TREATMENT: Distance to nearest EU internal border
# -----------------------------------------------------------------------
cat("\n=== DISTANCE-BASED TREATMENT ===\n")

# Load NUTS2 shapefile for centroid distances
nuts2_sf <- sf::st_read(file.path(data_dir, "nuts2_2016.gpkg"), quiet = TRUE)
border_pairs_dt <- fread(file.path(data_dir, "border_pairs.csv"))

# Get centroids of border regions
border_ids <- unique(c(border_pairs_dt$region1, border_pairs_dt$region2))
border_centroids <- sf::st_centroid(nuts2_sf[nuts2_sf$id %in% border_ids, ])

# For each region, compute distance to nearest border-region centroid
all_centroids <- sf::st_centroid(nuts2_sf[nuts2_sf$id %in% unique(panel_main$geo), ])

if (nrow(border_centroids) > 0 && nrow(all_centroids) > 0) {
  dist_matrix <- sf::st_distance(all_centroids, border_centroids)
  min_dist <- apply(dist_matrix, 1, min)
  dist_dt <- data.table(
    geo = all_centroids$id,
    dist_to_border_km = as.numeric(min_dist) / 1000
  )

  panel_main <- merge(panel_main, dist_dt, by = "geo", all.x = TRUE)

  # Inverse distance treatment (closer = more treated)
  panel_main[, inv_dist := 1 / (1 + dist_to_border_km)]
  panel_main[, inv_dist_post := inv_dist * post]

  m_dist <- feols(log_foreign ~ inv_dist_post | geo + time,
                  data = panel_main, cluster = ~country)
  cat("Distance-based treatment:\n")
  print(summary(m_dist))

  fwrite(dist_dt, file.path(data_dir, "distance_to_border.csv"))
}

# -----------------------------------------------------------------------
# 5. EXTENDED SAMPLE (2012-2022, including COVID period)
# -----------------------------------------------------------------------
cat("\n=== EXTENDED SAMPLE (with COVID) ===\n")

panel_ext <- panel[time >= 2012 & time <= 2022]
panel_ext[, covid := as.integer(time %in% c(2020, 2021))]

m_ext_full <- feols(log_foreign ~ border_post + border:covid | geo + time,
                    data = panel_ext, cluster = ~country)
cat("Extended sample (2012-2022, COVID controls):\n")
print(summary(m_ext_full))

# -----------------------------------------------------------------------
# 6. MECHANISM: Heterogeneity by average length of stay
# -----------------------------------------------------------------------
cat("\n=== MECHANISM: LENGTH OF STAY ===\n")

arnts_file <- file.path(data_dir, "avg_nights_nuts2.csv")
if (file.exists(arnts_file)) {
  arnts <- fread(arnts_file)
  # Pre-treatment average nights
  arnts_pre <- arnts[time <= 2016 & c_resid == "FOR",
                     .(avg_stay = mean(values, na.rm = TRUE)), by = geo]
  panel_main <- merge(panel_main, arnts_pre, by = "geo", all.x = TRUE)

  # Short-stay regions (below median)
  median_stay <- median(panel_main$avg_stay, na.rm = TRUE)
  panel_main[, short_stay := as.integer(avg_stay <= median_stay)]
  panel_main[, short_stay_border_post := short_stay * border_post]

  m_stay <- feols(log_foreign ~ border_post + short_stay_border_post | geo + time,
                  data = panel_main[!is.na(short_stay)], cluster = ~country)
  cat("Short-stay heterogeneity:\n")
  print(summary(m_stay))
}

# -----------------------------------------------------------------------
# 7. RAMBACHAN-ROTH SENSITIVITY (HonestDiD)
# -----------------------------------------------------------------------
cat("\n=== RAMBACHAN-ROTH SENSITIVITY ===\n")

# Re-estimate event study for HonestDiD
m_es_rr <- feols(log_foreign ~ i(event_time, border, ref = -1) | geo + time,
                 data = panel_main, cluster = ~country)

tryCatch({
  # Extract coefficients and variance-covariance matrix
  es_beta <- coef(m_es_rr)
  es_vcov <- vcov(m_es_rr)

  # Identify pre and post indices
  coef_names <- names(es_beta)
  pre_idx <- grep("::-[2-5]", coef_names)
  post_idx <- grep("::[0-2]", coef_names)

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    # HonestDiD sensitivity
    rr_result <- HonestDiD::createSensitivityResults(
      betahat = es_beta,
      sigma = es_vcov,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("Rambachan-Roth results:\n")
    print(rr_result)

    rr_dt <- as.data.table(rr_result)
    fwrite(rr_dt, file.path(data_dir, "rambachan_roth.csv"))
  }
}, error = function(e) {
  cat("HonestDiD sensitivity skipped:", e$message, "\n")
})

# -----------------------------------------------------------------------
# 8. WILD CLUSTER BOOTSTRAP (few-cluster robust inference)
# -----------------------------------------------------------------------
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Load main models
load(file.path(data_dir, "main_models.RData"))

# fwildclusterboot v0.14 has a bug with feols objects.
# Workaround: use fixest::demean() for proper iterative FWL projection, then lm()
panel_main[, country_chr := as.character(country)]

# Identify and exclude singleton country-year cells for cty×yr spec
panel_main[, cty_yr := paste0(country, "_", time)]
cty_yr_counts <- panel_main[!is.na(log_foreign), .N, by = cty_yr]
singleton_cells <- cty_yr_counts[N == 1]$cty_yr
panel_no_sing <- panel_main[!cty_yr %in% singleton_cells]

# --- WCB for baseline DiD (geo + time FE) ---
pm <- panel_main[!is.na(log_foreign)]
dm_x1 <- fixest::demean(X = pm[, .(border_post)], f = pm[, .(geo, time)])
dm_y1 <- fixest::demean(X = pm[, .(log_foreign)], f = pm[, .(geo, time)])
df1 <- data.frame(y = dm_y1[[1]], x = dm_x1[[1]], country = pm$country)
lm_m1 <- lm(y ~ x, data = df1)

cat("WCB for baseline DiD (m1)...\n")
wcb_m1 <- tryCatch({
  set.seed(12345); dqrng::dqset.seed(12345)
  boot_m1 <- fwildclusterboot::boottest(
    lm_m1, param = "x", clustid = c("country"),
    B = 9999, type = "rademacher", impose_null = TRUE
  )
  list(p = boot_m1$p_val, ci_lo = boot_m1$conf_int[1], ci_hi = boot_m1$conf_int[2])
}, error = function(e) {
  cat("WCB m1 error:", e$message, "\n")
  list(p = NA, ci_lo = NA, ci_hi = NA)
})
cat("  WCB p-value (m1):", wcb_m1$p, "\n")
cat("  WCB 95% CI:", wcb_m1$ci_lo, "to", wcb_m1$ci_hi, "\n")

# --- WCB for country×year FE ---
pns <- panel_no_sing[!is.na(log_foreign)]
dm_x2 <- fixest::demean(X = pns[, .(border_post)],
                         f = pns[, .(geo = as.factor(geo), cty_yr = as.factor(cty_yr))])
dm_y2 <- fixest::demean(X = pns[, .(log_foreign)],
                         f = pns[, .(geo = as.factor(geo), cty_yr = as.factor(cty_yr))])
df2 <- data.frame(y = dm_y2[[1]], x = dm_x2[[1]], country = pns$country)
lm_cty <- lm(y ~ x, data = df2)

cat("WCB for country×year FE (m_cty)...\n")
wcb_cty <- tryCatch({
  set.seed(12345); dqrng::dqset.seed(12345)
  boot_cty <- fwildclusterboot::boottest(
    lm_cty, param = "x", clustid = c("country"),
    B = 9999, type = "rademacher", impose_null = TRUE
  )
  list(p = boot_cty$p_val, ci_lo = boot_cty$conf_int[1], ci_hi = boot_cty$conf_int[2])
}, error = function(e) {
  cat("WCB m_cty error:", e$message, "\n")
  list(p = NA, ci_lo = NA, ci_hi = NA)
})
cat("  WCB p-value (m_cty):", wcb_cty$p, "\n")
cat("  WCB 95% CI:", wcb_cty$ci_lo, "to", wcb_cty$ci_hi, "\n")

# --- WCB for domestic placebo ---
pm_dom <- panel_main[!is.na(log_domestic)]
dm_xd <- fixest::demean(X = pm_dom[, .(border_post)], f = pm_dom[, .(geo, time)])
dm_yd <- fixest::demean(X = pm_dom[, .(log_domestic)], f = pm_dom[, .(geo, time)])
df_dom <- data.frame(y = dm_yd[[1]], x = dm_xd[[1]], country = pm_dom$country)
lm_dom <- lm(y ~ x, data = df_dom)

cat("WCB for domestic placebo (m_dom)...\n")
wcb_dom <- tryCatch({
  set.seed(12345); dqrng::dqset.seed(12345)
  boot_dom <- fwildclusterboot::boottest(
    lm_dom, param = "x", clustid = c("country"),
    B = 9999, type = "rademacher", impose_null = TRUE
  )
  list(p = boot_dom$p_val, ci_lo = boot_dom$conf_int[1], ci_hi = boot_dom$conf_int[2])
}, error = function(e) {
  cat("WCB m_dom error:", e$message, "\n")
  list(p = NA, ci_lo = NA, ci_hi = NA)
})
cat("  WCB p-value (m_dom):", wcb_dom$p, "\n")

# Save WCB results
wcb_results <- data.table(
  spec = c("Baseline DiD", "Country x Year FE", "Domestic Placebo"),
  wcb_p = c(wcb_m1$p, wcb_cty$p, wcb_dom$p),
  wcb_ci_lo = c(wcb_m1$ci_lo, wcb_cty$ci_lo, wcb_dom$ci_lo),
  wcb_ci_hi = c(wcb_m1$ci_hi, wcb_cty$ci_hi, wcb_dom$ci_hi)
)
fwrite(wcb_results, file.path(data_dir, "wcb_results.csv"))

# -----------------------------------------------------------------------
# 9. EXCLUDE 2017 (half-treated year)
# -----------------------------------------------------------------------
cat("\n=== EXCLUDE 2017 ===\n")

panel_ex17 <- panel_main[time != 2017]
panel_ex17[, post_1819 := as.integer(time >= 2018)]
panel_ex17[, border_post_1819 := border * post_1819]

m_ex17 <- feols(log_foreign ~ border_post_1819 | geo + time,
                data = panel_ex17, cluster = ~country)
cat("Excluding 2017 (post = 2018-2019 only):\n")
print(summary(m_ex17))

m_ex17_cty <- feols(log_foreign ~ border_post_1819 | geo + country^time,
                    data = panel_ex17, cluster = ~country)
cat("Excluding 2017 + Country×Year FE:\n")
print(summary(m_ex17_cty))

# -----------------------------------------------------------------------
# 10. COMMON SAMPLE (restrict baseline to non-singleton sample)
# -----------------------------------------------------------------------
cat("\n=== COMMON SAMPLE ===\n")

# Use the panel without singletons (same sample as country×year FE spec)
panel_common <- copy(panel_no_sing[!is.na(log_foreign)])

# Re-estimate baseline on common sample
m1_common <- feols(log_foreign ~ border_post | geo + time,
                   data = panel_common, cluster = ~country)
cat("Common sample N:", nobs(m1_common), "\n")
cat("Baseline DiD on common sample (1,661 obs):\n")
print(summary(m1_common))

# -----------------------------------------------------------------------
# 11. POPULATION-WEIGHTED SPECIFICATION
# -----------------------------------------------------------------------
cat("\n=== POPULATION-WEIGHTED ===\n")

# Use pre-treatment average population as weight
pre_pop <- panel_main[time <= 2016, .(pre_pop = mean(population, na.rm = TRUE)), by = geo]
panel_main <- merge(panel_main, pre_pop, by = "geo", all.x = TRUE)

m_wt <- feols(log_foreign ~ border_post | geo + time,
              data = panel_main[!is.na(pre_pop)],
              weights = ~pre_pop, cluster = ~country)
cat("Population-weighted DiD:\n")
print(summary(m_wt))

m_wt_cty <- feols(log_foreign ~ border_post | geo + country^time,
                  data = panel_main[!is.na(pre_pop)],
                  weights = ~pre_pop, cluster = ~country)
cat("Population-weighted + Country×Year FE:\n")
print(summary(m_wt_cty))

# Save new robustness models
save(m_ex17, m_ex17_cty, m1_common, m_wt, m_wt_cty, wcb_results,
     file = file.path(data_dir, "robustness_revision_models.RData"))

# -----------------------------------------------------------------------
# 12. Save all robustness results
# -----------------------------------------------------------------------
rob_results <- data.table(
  check = c("Matched CEM", "Placebo timing (2015)",
            "Extended 2012-2022", "Leave-one-out (range)"),
  beta = c(coef(m_matched)[1], coef(m_placebo)[1],
           coef(m_ext_full)["border_post"],
           paste(round(range(loo_results$beta), 4), collapse = " to ")),
  se = c(se(m_matched)[1], se(m_placebo)[1],
         se(m_ext_full)["border_post"], "")
)
fwrite(rob_results, file.path(data_dir, "robustness_results.csv"))

# Save model objects
save(m_matched, m_placebo, m_ext_full, m_es_rr, loo_results,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nAll robustness checks complete.\n")
