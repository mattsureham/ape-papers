## 03_main_analysis.R — Main regressions
## apep_1209: Cannabis dispensary lotteries and property values

source("00_packages.R")

cat("=== Loading cleaned data ===\n")
sales <- readRDS("../data/sales_clean.rds")
disp <- readRDS("../data/dispensary_clean.rds")

cat("  Sales:", nrow(sales), "\n")
cat("  Dispensaries:", nrow(disp), "\n")
cat("  Treated (0.50mi x post):", sum(sales$treat_050), "\n")

## ---------------------------------------------------------------
## 3A. Summary statistics
## ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Overall summary
summ <- sales[, .(
  mean_price = mean(sale_price, na.rm = TRUE),
  sd_price = sd(sale_price, na.rm = TRUE),
  median_price = median(sale_price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE),
  mean_dist = mean(dist_nearest, na.rm = TRUE),
  sd_dist = sd(dist_nearest, na.rm = TRUE),
  n = .N
)]

cat("  Mean sale price: $", format(summ$mean_price, big.mark = ","), "\n")
cat("  SD sale price: $", format(summ$sd_price, big.mark = ","), "\n")
cat("  Mean log price:", round(summ$mean_log_price, 3), "\n")
cat("  SD log price:", round(summ$sd_log_price, 3), "\n")
cat("  Mean distance to nearest dispensary:", round(summ$mean_dist, 2), "mi\n")

# Pre/post comparison for treated ring
cat("\n  Pre/post comparison (within 0.50mi):\n")
near_pp <- sales[near_050 == 1, .(
  mean_price = mean(sale_price, na.rm = TRUE),
  n = .N
), by = post_open]
print(near_pp)

# Save summary stats for later use
saveRDS(summ, "../data/summary_stats.rds")

## ---------------------------------------------------------------
## 3B. Main DiD Regressions
## ---------------------------------------------------------------
cat("\n=== Main DiD Regressions ===\n")

# Specification 1: Basic DiD (0.25mi ring)
cat("  Model 1: Basic DiD (0.25mi)...\n")
m1 <- feols(log_price ~ treat_025 | disp_cluster + yq, data = sales,
            cluster = ~disp_cluster)
cat("    Coefficient:", round(coef(m1)["treat_025"], 4),
    "SE:", round(se(m1)["treat_025"], 4), "\n")

# Specification 2: DiD with distance rings (0.50mi)
cat("  Model 2: DiD (0.50mi ring)...\n")
m2 <- feols(log_price ~ treat_050 | disp_cluster + yq, data = sales,
            cluster = ~disp_cluster)
cat("    Coefficient:", round(coef(m2)["treat_050"], 4),
    "SE:", round(se(m2)["treat_050"], 4), "\n")

# Specification 3: Continuous distance treatment
cat("  Model 3: Continuous distance...\n")
sales[, inv_dist := 1 / (dist_nearest + 0.1)]  # Inverse distance
sales[, inv_dist_post := inv_dist * post_open]
m3 <- feols(log_price ~ inv_dist_post | disp_cluster + yq, data = sales,
            cluster = ~disp_cluster)
cat("    Coefficient:", round(coef(m3)["inv_dist_post"], 4),
    "SE:", round(se(m3)["inv_dist_post"], 4), "\n")

# Specification 4: Multiple distance rings
cat("  Model 4: Ring decomposition...\n")
sales[, treat_025_050 := ring_025_050 * post_open]
sales[, treat_050_100 := ring_050_100 * post_open]
m4 <- feols(log_price ~ treat_025 + treat_025_050 + treat_050_100 |
            disp_cluster + yq, data = sales, cluster = ~disp_cluster)

# Specification 5: Lottery-era dispensaries only
cat("  Model 5: Lottery-era dispensaries only...\n")
sales_lottery <- sales[nearest_lottery == TRUE]
m5 <- feols(log_price ~ treat_050 | disp_cluster + yq, data = sales_lottery,
            cluster = ~disp_cluster)
cat("    Coefficient:", round(coef(m5)["treat_050"], 4),
    "SE:", round(se(m5)["treat_050"], 4), "\n")

# Save models
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5)
saveRDS(models, "../data/main_models.rds")

## ---------------------------------------------------------------
## 3C. Event Study
## ---------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Restrict to sales within 1 mile of a dispensary
sales_es <- sales[dist_nearest <= 1.0 & !is.na(event_q_bin)]

# Create event-time dummies (omit q = -1 as reference)
sales_es[, eq := factor(event_q_bin)]

cat("  Event study sample:", nrow(sales_es), "sales\n")
cat("  Event quarter distribution:\n")
print(table(sales_es$event_q_bin))

# Event study: near ring (0-0.25mi) vs far ring (0.50-1mi) by event time
sales_es[, near := as.integer(dist_nearest <= 0.25)]
m_es <- feols(log_price ~ i(event_q_bin, near, ref = -1) | disp_cluster + yq,
              data = sales_es, cluster = ~disp_cluster)

# Extract event study coefficients
es_coefs <- data.table(
  quarter = as.integer(names(coef(m_es))),
  coef = as.numeric(coef(m_es)),
  se = as.numeric(se(m_es))
)
# Clean quarter names from interaction notation
es_coefs <- tryCatch({
  cf <- coef(m_es)
  se_vals <- se(m_es)
  # Parse quarter from names like "event_q_bin::-8:near"
  nm <- names(cf)
  quarters <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", nm))
  data.table(quarter = quarters, coef = as.numeric(cf), se = as.numeric(se_vals))
}, error = function(e) {
  cat("  Event study coefficient extraction warning:", conditionMessage(e), "\n")
  data.table(quarter = integer(0), coef = numeric(0), se = numeric(0))
})

es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]

saveRDS(es_coefs, "../data/event_study_coefs.rds")
saveRDS(m_es, "../data/event_study_model.rds")

cat("  Event study coefficients:\n")
print(es_coefs[order(quarter)])

## ---------------------------------------------------------------
## 3D. Diagnostics
## ---------------------------------------------------------------
cat("\n=== Diagnostics ===\n")

# Count treated units and pre-periods for validation
n_treated_disp <- length(unique(sales[treat_050 == 1, nearest_disp_id]))
n_pre_quarters <- length(unique(sales[post_open == 0, sale_yq]))
n_obs <- nrow(sales)

cat("  Treated dispensary clusters:", n_treated_disp, "\n")
cat("  Pre-treatment quarters:", n_pre_quarters, "\n")
cat("  Total observations:", n_obs, "\n")

diagnostics <- list(
  n_treated = n_treated_disp,
  n_pre = n_pre_quarters,
  n_obs = n_obs,
  n_dispensaries = nrow(disp),
  n_lottery_disp = sum(disp$lottery_era, na.rm = TRUE),
  n_sales_025 = sum(sales$near_025),
  n_sales_050 = sum(sales$near_050),
  n_treated_025 = sum(sales$treat_025),
  n_treated_050 = sum(sales$treat_050),
  sd_log_price = summ$sd_log_price
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("  Saved diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
