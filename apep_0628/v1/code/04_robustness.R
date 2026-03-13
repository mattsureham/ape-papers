###############################################################################
# 04_robustness.R — Robustness checks and placebo tests
# Paper: The Invisible Tariff (apep_0628)
###############################################################################

source("00_packages.R")

# --------------------------------------------------------------------------
# Load data
# --------------------------------------------------------------------------
nigeria_balanced <- readRDS("../data/nigeria_balanced.rds")
panel <- readRDS("../data/panel.rds")

cat("=== Robustness Checks ===\n\n")

# ==========================================================================
# 1. Placebo: Non-banned products in Nigeria (should show no effect)
# ==========================================================================

cat("--- 1. Control-product placebo ---\n")

# Split non-banned products into pseudo-treated and pseudo-control by HS2 chapter
non_banned <- nigeria_balanced[banned == 0]
non_banned_hs2 <- sort(unique(non_banned$hs2))

# Pseudo-treatment: top half of non-banned HS2 chapters
set.seed(20150623)  # CBN circular date
pseudo_treated_hs2 <- sample(non_banned_hs2, size = floor(length(non_banned_hs2) / 2))
non_banned[, pseudo_banned := as.integer(hs2 %in% pseudo_treated_hs2)]

placebo_product <- feols(
  log_imports ~ pseudo_banned:post | hs6 + year,
  data = non_banned,
  cluster = ~hs2
)

cat("Placebo (random HS2 split among non-banned):\n")
summary(placebo_product)

# ==========================================================================
# 2. Placebo: Banned products in CONTROL countries (should show no effect)
# ==========================================================================

cat("\n--- 2. Control-country placebo ---\n")

control_countries <- panel[nigeria == 0]

placebo_country <- feols(
  log_imports ~ banned:post | hs6 + reporter_code^year,
  data = control_countries,
  cluster = ~hs2
)

cat("Placebo (banned products in Ghana/CIV/Senegal):\n")
summary(placebo_country)

# ==========================================================================
# 3. Placebo timing: Fake treatment in 2013
# ==========================================================================

cat("\n--- 3. Placebo timing (fake treatment 2013) ---\n")

pre_data <- nigeria_balanced[year <= 2014]
pre_data[, fake_post := as.integer(year >= 2013)]

placebo_time <- feols(
  log_imports ~ banned:fake_post | hs6 + year,
  data = pre_data,
  cluster = ~hs2
)

cat("Placebo timing (fake treatment 2013, pre-period only):\n")
summary(placebo_time)

# ==========================================================================
# 4. Drop one HS2 chapter at a time (leave-one-out)
# ==========================================================================

cat("\n--- 4. Leave-one-out (drop each banned HS2 chapter) ---\n")

banned_hs2 <- readRDS("../data/banned_hs2.rds")
loo_results <- data.table(
  dropped_hs2 = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (h in banned_hs2) {
  loo_data <- nigeria_balanced[hs2 != h]
  loo_model <- feols(
    log_imports ~ banned:post | hs6 + year,
    data = loo_data,
    cluster = ~hs2
  )
  loo_results <- rbind(loo_results, data.table(
    dropped_hs2 = h,
    coef = coef(loo_model)["banned:post"],
    se = se(loo_model)["banned:post"],
    pval = pvalue(loo_model)["banned:post"]
  ))
}

cat("Leave-one-out results:\n")
cat(sprintf("  Range of coefficients: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  All significant at 5%%? %s\n",
            ifelse(all(loo_results$pval < 0.05), "YES", "NO")))
print(loo_results)

# ==========================================================================
# 5. Alternative clustering: HS4 level
# ==========================================================================

cat("\n--- 5. Alternative clustering ---\n")

nigeria_balanced[, hs4 := substr(as.character(hs6), 1, 4)]

did_hs4_cluster <- feols(
  log_imports ~ banned:post | hs6 + year,
  data = nigeria_balanced,
  cluster = ~hs4
)

cat("Clustered at HS4 level:\n")
summary(did_hs4_cluster)

# Wild cluster bootstrap for few-cluster inference (HS2 level)
cat("\n--- Wild cluster bootstrap (HS2 clusters) ---\n")

# Check if fwildclusterboot is available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  did_for_boot <- feols(
    log_imports ~ banned:post | hs6 + year,
    data = nigeria_balanced,
    cluster = ~hs2
  )

  boot_result <- tryCatch({
    boottest(did_for_boot,
             param = "banned:post",
             clustid = ~hs2,
             B = 9999,
             type = "webb")
  }, error = function(e) {
    cat(sprintf("  Bootstrap failed: %s\n", e$message))
    NULL
  })

  if (!is.null(boot_result)) {
    cat(sprintf("  Wild bootstrap p-value: %.4f\n", boot_result$p_val))
    cat(sprintf("  Wild bootstrap CI: [%.4f, %.4f]\n",
                boot_result$conf_int[1], boot_result$conf_int[2]))
  }
} else {
  cat("  fwildclusterboot not available, skipping bootstrap\n")
}

# ==========================================================================
# 6. Weight by pre-treatment import value
# ==========================================================================

cat("\n--- 6. Import-value weighted DiD ---\n")

# Compute pre-treatment mean as weight
pre_means <- nigeria_balanced[post == 0, .(
  pre_mean = mean(import_value, na.rm = TRUE)
), by = hs6]

nigeria_weighted <- merge(nigeria_balanced, pre_means, by = "hs6", all.x = TRUE)
nigeria_weighted[is.na(pre_mean), pre_mean := 0]
nigeria_weighted[, weight := pre_mean + 1]  # Add 1 to keep zero-import products

did_weighted <- feols(
  log_imports ~ banned:post | hs6 + year,
  data = nigeria_weighted,
  weights = ~weight,
  cluster = ~hs2
)

cat("Value-weighted DiD:\n")
summary(did_weighted)

# ==========================================================================
# Save robustness results
# ==========================================================================

robustness_summary <- list(
  placebo_product_coef = coef(placebo_product)[1],
  placebo_product_pval = pvalue(placebo_product)[1],
  placebo_country_coef = coef(placebo_country)["banned:post"],
  placebo_country_pval = pvalue(placebo_country)["banned:post"],
  placebo_time_coef = coef(placebo_time)["banned:fake_post"],
  placebo_time_pval = pvalue(placebo_time)["banned:fake_post"],
  loo_min = min(loo_results$coef),
  loo_max = max(loo_results$coef),
  did_weighted_coef = coef(did_weighted)["banned:post"],
  did_weighted_pval = pvalue(did_weighted)["banned:post"]
)

saveRDS(robustness_summary, "../data/robustness_summary.rds")
saveRDS(loo_results, "../data/loo_results.rds")
saveRDS(placebo_product, "../data/placebo_product.rds")
saveRDS(placebo_country, "../data/placebo_country.rds")
saveRDS(placebo_time, "../data/placebo_time.rds")
saveRDS(did_weighted, "../data/did_weighted.rds")
saveRDS(did_hs4_cluster, "../data/did_hs4_cluster.rds")

cat("\n=== Robustness checks complete ===\n")
