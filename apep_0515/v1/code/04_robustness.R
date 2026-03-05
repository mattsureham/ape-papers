## ============================================================================
## 04_robustness.R — Robustness Checks & Sensitivity
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

panel_clean <- panel[!is.na(bite_kaitz) & !is.na(closure_rate)]
panel_clean[, la_id := as.integer(factor(la_name))]

cat("=== Robustness Checks ===\n")
cat(sprintf("  Panel: %d obs, %d LAs\n", nrow(panel_clean), length(unique(panel_clean$la_name))))

## ---- 1. Pre-Trend Test (Joint F-test) ----
cat("\n=== 1. Pre-Trend Test ===\n")

es_model <- feols(closure_rate ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                  data = panel_clean, cluster = ~la_id)

# Joint test of pre-treatment coefficients = 0
pre_coefs <- grep("201[234]", names(coef(es_model)), value = TRUE)
if (length(pre_coefs) > 0) {
  pre_test <- wald(es_model, keep = pre_coefs)
  cat(sprintf("  Joint F-test of pre-trends: F = %.3f, p = %.4f\n",
              pre_test$stat, pre_test$p))
  if (pre_test$p > 0.05) {
    cat("  RESULT: Cannot reject parallel pre-trends (good)\n")
  } else {
    cat("  WARNING: Pre-trends may differ\n")
  }
}

## ---- 2. Tercile-Based Treatment ----
cat("\n=== 2. Tercile-Based Treatment ===\n")

bite_terciles <- quantile(panel_clean[year == 2015]$bite_kaitz, probs = c(1/3, 2/3), na.rm = TRUE)
panel_clean[, bite_tercile := findInterval(bite_kaitz, bite_terciles) + 1L]
panel_clean[, high_bite := as.integer(bite_tercile == 3)]

m_tercile <- feols(closure_rate ~ high_bite:post | la_id + year,
                   data = panel_clean, cluster = ~la_id)
cat(sprintf("  High-bite tercile × Post: beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_tercile)["high_bite:post"],
            se(m_tercile)["high_bite:post"],
            fixest::pvalue(m_tercile)["high_bite:post"]))

## ---- 3. Quartile-Based Treatment ----
cat("\n=== 3. Quartile-Based Treatment ===\n")

bite_quartiles <- quantile(panel_clean[year == 2015]$bite_kaitz, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
panel_clean[, bite_quartile := findInterval(bite_kaitz, bite_quartiles) + 1L]
panel_clean[, top_quartile := as.integer(bite_quartile == 4)]

m_quartile <- feols(closure_rate ~ top_quartile:post | la_id + year,
                    data = panel_clean, cluster = ~la_id)
cat(sprintf("  Top-quartile bite × Post: beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_quartile)["top_quartile:post"],
            se(m_quartile)["top_quartile:post"],
            fixest::pvalue(m_quartile)["top_quartile:post"]))

## ---- 4. Alternative Time Windows ----
cat("\n=== 4. Alternative Time Windows ===\n")

# 4a. Narrow window (2014-2017)
panel_narrow <- panel_clean[year >= 2014 & year <= 2017]
m_narrow <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
                  data = panel_narrow, cluster = ~la_id)
cat(sprintf("  Narrow window (2014-2017): beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_narrow)["bite_kaitz:post"],
            se(m_narrow)["bite_kaitz:post"],
            fixest::pvalue(m_narrow)["bite_kaitz:post"]))

# 4b. Symmetric window (2013-2018)
panel_sym <- panel_clean[year >= 2013 & year <= 2018]
m_sym <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
               data = panel_sym, cluster = ~la_id)
cat(sprintf("  Symmetric window (2013-2018): beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_sym)["bite_kaitz:post"],
            se(m_sym)["bite_kaitz:post"],
            fixest::pvalue(m_sym)["bite_kaitz:post"]))

## ---- 5. Dropping Outlier LAs ----
cat("\n=== 5. Dropping Outlier LAs ===\n")

# Drop LAs with very few or very many homes (bottom/top 5%)
home_dist <- panel_clean[year == 2015, .(mean_homes = mean(n_homes)), by = la_name]
q05 <- quantile(home_dist$mean_homes, 0.05)
q95 <- quantile(home_dist$mean_homes, 0.95)
keep_las <- home_dist[mean_homes >= q05 & mean_homes <= q95]$la_name

panel_trimmed <- panel_clean[la_name %in% keep_las]
m_trimmed <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
                   data = panel_trimmed, cluster = ~la_id)
cat(sprintf("  Trimmed (drop 5%%/95%% by homes): beta = %.3f (SE = %.3f, p = %.4f) [%d LAs]\n",
            coef(m_trimmed)["bite_kaitz:post"],
            se(m_trimmed)["bite_kaitz:post"],
            fixest::pvalue(m_trimmed)["bite_kaitz:post"],
            length(unique(panel_trimmed$la_name))))

## ---- 6. Region-Year Fixed Effects ----
cat("\n=== 6. Region-Year Fixed Effects ===\n")

# Load CQC data to get regions
cqc <- fread(file.path(data_dir, "cqc_all_care_homes_england.csv"))
la_region <- unique(cqc[, .(la_name, region)])[!is.na(region) & region != ""]
la_region <- la_region[, .SD[1], by = la_name]  # deduplicate

panel_reg <- merge(panel_clean, la_region, by = "la_name", all.x = TRUE)
panel_reg <- panel_reg[!is.na(region)]
panel_reg[, region_year := paste(region, year)]

if (length(unique(panel_reg$region)) >= 3) {
  m_region <- feols(closure_rate ~ bite_kaitz:post | la_id + region_year,
                    data = panel_reg, cluster = ~la_id)
  cat(sprintf("  Region × Year FE: beta = %.3f (SE = %.3f, p = %.4f)\n",
              coef(m_region)["bite_kaitz:post"],
              se(m_region)["bite_kaitz:post"],
              fixest::pvalue(m_region)["bite_kaitz:post"]))
} else {
  cat("  Insufficient region data for region-year FE\n")
}

## ---- 7. Placebo Outcome: Entry Rate ----
cat("\n=== 7. Placebo: Entry Rate ===\n")

m_entry_placebo <- feols(entry_rate ~ bite_kaitz:post | la_id + year,
                         data = panel_clean, cluster = ~la_id)
cat(sprintf("  Entry rate (should be null): beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_entry_placebo)["bite_kaitz:post"],
            se(m_entry_placebo)["bite_kaitz:post"],
            fixest::pvalue(m_entry_placebo)["bite_kaitz:post"]))

## ---- 8. Placebo Treatment Year (2014) ----
cat("\n=== 8. Placebo Treatment Year ===\n")

panel_pre <- panel_clean[year <= 2015]
panel_pre[, post_placebo := as.integer(year >= 2014)]

m_placebo <- feols(closure_rate ~ bite_kaitz:post_placebo | la_id + year,
                   data = panel_pre, cluster = ~la_id)
cat(sprintf("  Placebo treatment (2014): beta = %.3f (SE = %.3f, p = %.4f)\n",
            coef(m_placebo)["bite_kaitz:post_placebo"],
            se(m_placebo)["bite_kaitz:post_placebo"],
            fixest::pvalue(m_placebo)["bite_kaitz:post_placebo"]))

## ---- 9. Sector Heterogeneity ----
cat("\n=== 9. Sector Heterogeneity ===\n")

# Count private vs non-private homes per LA-year
la_sector <- cqc[, .(
  n_private = sum(sector == "Social Care Org - Independent", na.rm = TRUE),
  n_vol = sum(sector == "Social Care Org - Voluntary/Not for Profit", na.rm = TRUE),
  n_la_sector = sum(sector == "Social Care Org - Local Authority", na.rm = TRUE)
), by = la_name]

panel_sector <- merge(panel_clean, la_sector, by = "la_name", all.x = TRUE)
panel_sector[, pct_private := n_private / (n_private + n_vol + n_la_sector)]

# Above/below median private share
med_private <- median(panel_sector[year == 2015]$pct_private, na.rm = TRUE)
panel_sector[, high_private := as.integer(pct_private > med_private)]

if (sum(!is.na(panel_sector$high_private)) > 200) {
  m_high_priv <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
                       data = panel_sector[high_private == 1], cluster = ~la_id)
  m_low_priv <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
                      data = panel_sector[high_private == 0], cluster = ~la_id)
  cat(sprintf("  High-private LAs: beta = %.3f (SE = %.3f, p = %.4f)\n",
              coef(m_high_priv)["bite_kaitz:post"],
              se(m_high_priv)["bite_kaitz:post"],
              fixest::pvalue(m_high_priv)["bite_kaitz:post"]))
  cat(sprintf("  Low-private LAs:  beta = %.3f (SE = %.3f, p = %.4f)\n",
              coef(m_low_priv)["bite_kaitz:post"],
              se(m_low_priv)["bite_kaitz:post"],
              fixest::pvalue(m_low_priv)["bite_kaitz:post"]))
}

## ---- 10. Beds Lost (Intensive Margin) ----
cat("\n=== 10. Beds Lost (Intensive Margin) ===\n")

m_beds_lost <- feols(beds_lost ~ bite_kaitz:post | la_id + year,
                     data = panel_clean, cluster = ~la_id)
cat(sprintf("  Beds lost per year: beta = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_beds_lost)["bite_kaitz:post"],
            se(m_beds_lost)["bite_kaitz:post"],
            fixest::pvalue(m_beds_lost)["bite_kaitz:post"]))

## ---- 11. HonestDiD Sensitivity ----
cat("\n=== 11. HonestDiD Sensitivity Analysis ===\n")

tryCatch({
  # Get event study for HonestDiD
  es_for_honest <- feols(closure_rate ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                         data = panel_clean, cluster = ~la_id)

  betahat <- coef(es_for_honest)
  sigma <- vcov(es_for_honest)

  # Identify pre and post indices
  coef_names <- names(betahat)
  pre_idx <- grep("201[234]", coef_names)
  post_idx <- grep("201[6789]", coef_names)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Relative magnitudes approach
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 2, by = 0.5),
      alpha = 0.05
    )
    cat("  HonestDiD sensitivity (Relative Magnitudes):\n")
    print(honest_result)

    saveRDS(honest_result, file.path(data_dir, "honestdid_results.rds"))
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
})

## ---- 12. Weighted Regression ----
cat("\n=== 12. Population-Weighted Regression ===\n")

panel_pop <- panel_clean[!is.na(pop_total) & pop_total > 0]
if (nrow(panel_pop) > 100) {
  m_weighted <- feols(closure_rate ~ bite_kaitz:post | la_id + year,
                      data = panel_pop, cluster = ~la_id, weights = ~pop_total)
  cat(sprintf("  Population-weighted: beta = %.3f (SE = %.3f, p = %.4f)\n",
              coef(m_weighted)["bite_kaitz:post"],
              se(m_weighted)["bite_kaitz:post"],
              fixest::pvalue(m_weighted)["bite_kaitz:post"]))
}

## ---- Save Robustness Results ----
cat("\n=== Saving Robustness Results ===\n")

robustness <- list(
  es_model = es_model,
  m_tercile = m_tercile,
  m_quartile = m_quartile,
  m_narrow = m_narrow,
  m_sym = m_sym,
  m_trimmed = m_trimmed,
  m_entry_placebo = m_entry_placebo,
  m_placebo = m_placebo,
  m_beds_lost = m_beds_lost
)

# Add conditional results
if (exists("m_region")) robustness$m_region <- m_region
if (exists("m_high_priv")) robustness$m_high_priv <- m_high_priv
if (exists("m_low_priv")) robustness$m_low_priv <- m_low_priv
if (exists("m_weighted")) robustness$m_weighted <- m_weighted
if (exists("panel_sector")) {
  saveRDS(panel_sector, file.path(data_dir, "panel_with_sector.rds"))
}
if (exists("panel_reg")) {
  saveRDS(panel_reg, file.path(data_dir, "panel_with_region.rds"))
}

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("Robustness checks complete. Results saved.\n")
