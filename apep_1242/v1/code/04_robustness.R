# 04_robustness.R — Robustness checks for PSC bunching analysis

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_ready.csv"))
load(file.path(data_dir, "analysis_results.RData"))

cat(sprintf("Analysis sample: %s companies\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. Alternative Polynomial Orders
# ============================================================================
# Test sensitivity of bunching estimate to polynomial degree (2, 3, 4, 5)

dist_full <- df[n_individual > 0, .N, by = .(n_pscs = pmin(n_individual, 10))][order(n_pscs)]
dist_full[, log_N := log(N)]

bunching_region <- 4:5

poly_results <- list()
for (deg in 2:5) {
  fit <- lm(log_N ~ poly(n_pscs, deg),
            data = dist_full[!n_pscs %in% bunching_region & n_pscs <= 10])
  dist_full[, cf := exp(predict(fit, newdata = .SD))]
  excess_4 <- dist_full[n_pscs == 4, N - cf]
  excess_5 <- dist_full[n_pscs == 5, N - cf]
  b <- dist_full[n_pscs %in% bunching_region, sum(N - cf)] /
    dist_full[n_pscs %in% bunching_region, sum(cf)]
  poly_results[[deg - 1]] <- data.table(
    degree = deg,
    excess_4 = round(excess_4),
    excess_5 = round(excess_5),
    b_hat = round(b, 3)
  )
}

poly_tab <- rbindlist(poly_results)
cat("\n=== Robustness: Polynomial Order ===\n")
print(poly_tab)

# ============================================================================
# 2. Placebo Test: n=3 PSCs (no special threshold properties)
# ============================================================================
# At n=3, each shareholder holds ~33% — above threshold, no avoidance incentive.
# There should be no excess mass at 3 using the same polynomial approach.

cat("\n=== Placebo Test: n=3 ===\n")
placebo_region <- 3
fit_placebo <- lm(log_N ~ poly(n_pscs, 3),
                  data = dist_full[!n_pscs %in% placebo_region & n_pscs <= 10])
dist_full[, cf_placebo := exp(predict(fit_placebo, newdata = .SD))]
excess_3 <- dist_full[n_pscs == 3, N - cf_placebo]
cat(sprintf("Excess mass at n=3 (placebo): %.0f (observed: %d, counterfactual: %.0f)\n",
            excess_3, dist_full[n_pscs == 3, N],
            dist_full[n_pscs == 3, cf_placebo]))

# ============================================================================
# 3. Permutation Test for Configuration
# ============================================================================
# Among 4-PSC companies, is the 34% equal-split rate significantly different
# from what we'd see under random band assignment?

cat("\n=== Permutation Test: Equal-Split Rate ===\n")

# Observed rate
observed_rate <- mean(df[n_individual == 4]$n_band_25_50 == 4, na.rm = TRUE)

# Permutation: randomly shuffle ownership bands across ALL PSCs
# then reassign to 4-PSC companies
psc_raw <- fread(file.path(data_dir, "psc_records_raw.csv"))
indiv_bands <- psc_raw[grepl("individual", kind, ignore.case = TRUE), ownership_band]

n_perm <- 999
perm_rates <- numeric(n_perm)
set.seed(123)

n_four_cos <- sum(df$n_individual == 4, na.rm = TRUE)

for (p in seq_len(n_perm)) {
  # Draw 4 bands per company from the overall distribution
  perm_bands <- sample(indiv_bands, n_four_cos * 4, replace = TRUE)
  perm_matrix <- matrix(perm_bands, ncol = 4)
  perm_rates[p] <- mean(apply(perm_matrix, 1, function(x) all(x == "25-50")))
}

perm_p <- (sum(perm_rates >= observed_rate) + 1) / (n_perm + 1)
cat(sprintf("Observed equal-split rate: %.3f\n", observed_rate))
cat(sprintf("Permutation mean: %.4f (SD: %.4f)\n", mean(perm_rates), sd(perm_rates)))
cat(sprintf("Permutation p-value: %.4f\n", perm_p))

# ============================================================================
# 4. Alternative Bunching Region Definitions
# ============================================================================
# Test sensitivity to which PSC counts are in the "bunching region"

cat("\n=== Robustness: Alternative Bunching Regions ===\n")

regions <- list(
  "n=4 only" = 4,
  "n=4,5" = 4:5,
  "n=4,5,6" = 4:6,
  "n=3,4,5" = 3:5
)

region_results <- list()
for (nm in names(regions)) {
  reg <- regions[[nm]]
  fit_r <- lm(log_N ~ poly(n_pscs, 3),
              data = dist_full[!n_pscs %in% reg & n_pscs <= 10 & is.finite(log_N)])
  dist_full[, cf_r := exp(predict(fit_r, newdata = .SD))]
  b_r <- dist_full[n_pscs %in% reg, sum(N - cf_r)] /
    dist_full[n_pscs %in% reg, sum(cf_r)]
  total_excess_r <- dist_full[n_pscs %in% reg, sum(N - cf_r)]
  region_results[[nm]] <- data.table(
    region = nm,
    total_excess = round(total_excess_r),
    b_hat = round(b_r, 3)
  )
}

region_tab <- rbindlist(region_results)
print(region_tab)

# ============================================================================
# 5. Company Age Controls
# ============================================================================
# Older companies might naturally have more shareholders (succession, etc.)
# Test if bunching persists within company age cohorts

cat("\n=== Robustness: Age Cohort Analysis ===\n")

cohorts <- df[!is.na(inc_year) & n_individual > 0 & n_individual <= 10,
              .(n_pscs = n_individual, inc_decade = floor(inc_year / 10) * 10,
                y_equal_4 = as.integer(n_individual == 4 & n_band_25_50 == 4))]

cohort_results <- cohorts[, .(
  n = .N,
  pct_4psc = 100 * mean(n_pscs == 4),
  pct_equal_4 = 100 * mean(y_equal_4),
  mean_pscs = mean(n_pscs)
), by = inc_decade][order(inc_decade)]

cat("Equal-split rate by incorporation decade:\n")
print(cohort_results[inc_decade >= 1990])

# ============================================================================
# 6. Corporate PSC as Alternative Avoidance Mechanism
# ============================================================================
# Instead of splitting to 5 individuals, insert a corporate PSC layer

cat("\n=== Corporate PSC as Opacity Vehicle ===\n")

corp_test <- df[n_individual > 0, .(
  n = .N,
  pct_corp = 100 * mean(has_corporate_psc),
  mean_indiv = mean(n_individual)
), by = .(high_risk = factor(high_risk, labels = c("Low risk", "High risk")),
          n_group = fcase(n_individual == 1, "1 PSC",
                          n_individual == 2, "2 PSCs",
                          n_individual == 3, "3 PSCs",
                          n_individual >= 4, "4+ PSCs"))]
cat("Corporate PSC prevalence by sector risk and PSC count:\n")
print(dcast(corp_test, n_group ~ high_risk, value.var = "pct_corp"))

# ============================================================================
# 7. Save robustness results
# ============================================================================

save(poly_tab, excess_3, perm_p, perm_rates, observed_rate,
     region_tab, cohort_results, corp_test,
     file = file.path(data_dir, "robustness_results.RData"))
cat("\nRobustness results saved.\n")
