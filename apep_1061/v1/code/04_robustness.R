# 04_robustness.R — Robustness checks for apep_1061
# Polish abortion ruling border-distance DiD

source("00_packages.R")

panel <- readRDS("../data/panel_nuts2.rds")

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# 1. Alternative distance measures
# ---------------------------------------------------------------
cat("\n--- Alternative distance: German clinics only ---\n")
panel$post_x_dist_de <- panel$post * panel$dist_de_km
m_de <- feols(tfr ~ post_x_dist_de | geo + year, data = panel, cluster = ~geo)
summary(m_de)

cat("\n--- Alternative distance: Czech clinics only ---\n")
panel$post_x_dist_cz <- panel$post * panel$dist_cz_km
m_cz <- feols(tfr ~ post_x_dist_cz | geo + year, data = panel, cluster = ~geo)
summary(m_cz)

# ---------------------------------------------------------------
# 2. Alternative treatment timing
# ---------------------------------------------------------------
cat("\n--- Placebo: Fake treatment in 2018 (pre-ruling) ---\n")
panel_pre <- panel[panel$year <= 2020, ]
panel_pre$fake_post <- as.integer(panel_pre$year >= 2018)
panel_pre$fake_post_x_dist <- panel_pre$fake_post * panel_pre$dist_min_km

m_placebo <- feols(tfr ~ fake_post_x_dist | geo + year,
                   data = panel_pre, cluster = ~geo)
summary(m_placebo)

cat("\n--- Placebo: Fake treatment in 2017 ---\n")
panel_pre$fake_post_17 <- as.integer(panel_pre$year >= 2017)
panel_pre$fake_post_x_dist_17 <- panel_pre$fake_post_17 * panel_pre$dist_min_km

m_placebo17 <- feols(tfr ~ fake_post_x_dist_17 | geo + year,
                     data = panel_pre, cluster = ~geo)
summary(m_placebo17)

# ---------------------------------------------------------------
# 3. Alternative sample periods
# ---------------------------------------------------------------
cat("\n--- Dropping 2020 (COVID onset year) ---\n")
panel_no2020 <- panel[panel$year != 2020, ]
m_no2020 <- feols(tfr ~ post_x_dist | geo + year,
                  data = panel_no2020, cluster = ~geo)
summary(m_no2020)

cat("\n--- Shorter pre-period (2017-2023) ---\n")
panel_short <- panel[panel$year >= 2017, ]
m_short <- feols(tfr ~ post_x_dist | geo + year,
                 data = panel_short, cluster = ~geo)
summary(m_short)

cat("\n--- Extended pre-period (2013-2023) ---\n")
m_long <- feols(tfr ~ post_x_dist | geo + year, data = panel, cluster = ~geo)
summary(m_long)

# ---------------------------------------------------------------
# 4. NUTS3 analysis (if available)
# ---------------------------------------------------------------
if (file.exists("../data/panel_nuts3.rds")) {
  cat("\n--- NUTS3 specification ---\n")
  nuts3 <- readRDS("../data/panel_nuts3.rds")

  # Cluster at NUTS2 level (voivodship) for NUTS3 data
  nuts3$nuts2 <- substr(nuts3$geo, 1, 4)

  m_nuts3 <- feols(cbr ~ post_x_dist | geo + year,
                   data = nuts3, cluster = ~nuts2)
  summary(m_nuts3)

  # Binary version
  m_nuts3_bin <- feols(cbr ~ i(post, far_from_border) | geo + year,
                       data = nuts3, cluster = ~nuts2)
  summary(m_nuts3_bin)

  saveRDS(list(m_nuts3 = m_nuts3, m_nuts3_bin = m_nuts3_bin),
          "../data/models_nuts3.rds")
}

# ---------------------------------------------------------------
# 5. Population-weighted regression
# ---------------------------------------------------------------
if ("population" %in% names(panel)) {
  cat("\n--- Population-weighted ---\n")
  panel_w <- panel[!is.na(panel$population), ]
  m_weighted <- feols(tfr ~ post_x_dist | geo + year,
                      data = panel_w, weights = ~population, cluster = ~geo)
  summary(m_weighted)
} else {
  m_weighted <- NULL
}

# ---------------------------------------------------------------
# 6. Leave-one-out (drop each voivodship)
# ---------------------------------------------------------------
cat("\n--- Leave-one-out sensitivity ---\n")
regions <- unique(panel$geo)
loo_results <- data.frame(
  dropped = character(),
  voivodship = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (r in regions) {
  m_loo <- feols(tfr ~ post_x_dist | geo + year,
                 data = panel[panel$geo != r, ], cluster = ~geo)
  voiv_name <- unique(panel$voivodship[panel$geo == r])
  loo_results <- rbind(loo_results, data.frame(
    dropped = r,
    voivodship = voiv_name,
    coef = coef(m_loo)["post_x_dist"],
    se = se(m_loo)["post_x_dist"],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out coefficients:\n")
print(loo_results[order(loo_results$coef), ])
cat(sprintf("Range: [%.6f, %.6f]\n", min(loo_results$coef), max(loo_results$coef)))

# ---------------------------------------------------------------
# 7. HonestDiD sensitivity (if pre-trends are borderline)
# ---------------------------------------------------------------
cat("\n--- HonestDiD sensitivity analysis ---\n")
tryCatch({
  # Use event study for HonestDiD
  models <- readRDS("../data/models.rds")
  m_es <- models$m_es

  # Extract event study coefficients and variance-covariance
  es_coefs <- coef(m_es)
  es_vcov <- vcov(m_es)

  # Identify pre-trend and post-treatment coefficients
  pre_names <- grep("event_time_f::-[2-9]|event_time_f::-[1-9][0-9]", names(es_coefs), value = TRUE)
  post_names <- grep("event_time_f::[0-9]", names(es_coefs), value = TRUE)

  if (length(pre_names) > 0 && length(post_names) > 0) {
    all_names <- c(pre_names, post_names)
    beta <- es_coefs[all_names]
    sigma <- es_vcov[all_names, all_names]
    n_pre <- length(pre_names)

    # Relative magnitude approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta,
      sigma = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = length(post_names),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes:\n")
    print(honest_rm)

    saveRDS(honest_rm, "../data/honest_did.rds")
  }
}, error = function(e) {
  cat("HonestDiD failed:", conditionMessage(e), "\n")
})

# ---------------------------------------------------------------
# 8. Save robustness models
# ---------------------------------------------------------------
rob_models <- list(
  m_de = m_de, m_cz = m_cz,
  m_placebo = m_placebo, m_placebo17 = m_placebo17,
  m_no2020 = m_no2020, m_short = m_short,
  m_weighted = m_weighted,
  loo = loo_results
)
saveRDS(rob_models, "../data/robustness_models.rds")

cat("\n=== Robustness Complete ===\n")
