# 03_main_analysis.R — Bunching estimation at the 25% PSC disclosure threshold

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_ready.csv"))
cat(sprintf("Analysis sample: %s companies\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. PSC Count Distribution and Polynomial Counterfactual
# ============================================================================
# The running variable is the number of individual PSCs per company.
# The threshold is effectively between 4 (each holds 25%, must disclose)
# and 5 (each holds 20%, no disclosure required).
# Strategic avoidance: shift from 4 to 5 shareholders.

# Distribution of individual PSC counts (capped at 10 for analysis)
dist <- df[n_individual > 0, .N, by = .(n_pscs = pmin(n_individual, 10))][order(n_pscs)]
dist[, log_N := log(N)]
dist[, pct := 100 * N / sum(N)]

cat("\n=== Individual PSC Count Distribution ===\n")
print(dist)

# Fit polynomial counterfactual EXCLUDING the bunching region (n=4,5)
# Following Kleven (2016) approach for discrete distributions
bunching_region <- 4:5
dist[, in_bunching := n_pscs %in% bunching_region]

# Polynomial of degree 3 fitted to the distribution excluding bunching region
poly_fit <- lm(log_N ~ poly(n_pscs, 3), data = dist[!in_bunching & n_pscs <= 10])
dist[, log_N_cf := predict(poly_fit, newdata = .SD)]
dist[, N_cf := exp(log_N_cf)]

# Excess mass
dist[, excess := N - N_cf]
dist[, excess_pct := 100 * excess / N_cf]

cat("\n=== Bunching Estimation ===\n")
print(dist[, .(n_pscs, N, N_cf = round(N_cf), excess = round(excess),
               excess_pct = round(excess_pct, 1))])

# Parametric bootstrap for standard errors (multinomial resampling of counts)
B <- 500
boot_excess <- matrix(NA, B, 10)
set.seed(42)

total_n <- sum(dist$N)
obs_probs <- dist$N / total_n

for (b in seq_len(B)) {
  # Draw from multinomial with observed probabilities
  boot_counts <- rmultinom(1, total_n, obs_probs)[, 1]
  boot_dist <- data.table(n_pscs = dist$n_pscs, N = boot_counts)
  boot_dist[, log_N := ifelse(N > 0, log(N), NA_real_)]

  # Fit polynomial excluding bunching region
  boot_fit <- tryCatch(
    lm(log_N ~ poly(n_pscs, 3),
       data = boot_dist[!n_pscs %in% bunching_region & !is.na(log_N)]),
    error = function(e) NULL
  )
  if (is.null(boot_fit)) next

  boot_dist[, N_cf := exp(predict(boot_fit, newdata = .SD))]
  boot_dist[, excess := N - N_cf]

  for (i in seq_len(nrow(boot_dist))) {
    boot_excess[b, i] <- boot_dist$excess[i]
  }
}

# Standard errors
boot_se <- apply(boot_excess, 2, sd, na.rm = TRUE)
dist[, se_excess := boot_se[n_pscs]]
dist[, t_stat := excess / se_excess]

cat("\n=== Bunching Results with Bootstrap SEs ===\n")
print(dist[, .(n_pscs, N, N_cf = round(N_cf), excess = round(excess),
               se = round(se_excess), t = round(t_stat, 2))])

# Total excess mass in bunching region
total_excess_4 <- dist[n_pscs == 4, excess]
total_excess_5 <- dist[n_pscs == 5, excess]
se_4 <- dist[n_pscs == 4, se_excess]
se_5 <- dist[n_pscs == 5, se_excess]

cat(sprintf("\n=== Key Results ===\n"))
cat(sprintf("Excess mass at n=4: %.0f (SE: %.0f, t=%.2f)\n",
            total_excess_4, se_4, total_excess_4 / se_4))
cat(sprintf("Excess mass at n=5: %.0f (SE: %.0f, t=%.2f)\n",
            total_excess_5, se_5, total_excess_5 / se_5))

# Normalized excess mass (b parameter from Kleven-Waseem)
b_hat <- dist[n_pscs %in% bunching_region, sum(excess)] /
  dist[n_pscs %in% bunching_region, sum(N_cf)]
cat(sprintf("Normalized excess mass (b): %.3f\n", b_hat))

# ============================================================================
# 2. Configuration Test: Equal Splitting at Threshold
# ============================================================================
# Among 4-PSC companies: what fraction have ALL 4 in the 25-50% band?
# Under no manipulation: this fraction should be small
# Under threshold avoidance: this fraction should be large

four_psc <- df[n_individual == 4]
n_four <- nrow(four_psc)
n_equal_4 <- sum(four_psc$n_band_25_50 == 4, na.rm = TRUE)
share_equal_4 <- n_equal_4 / n_four

cat("\n=== Configuration Test ===\n")
cat(sprintf("4-individual-PSC companies: %d\n", n_four))
cat(sprintf("All 4 in 25-50%% band (equal split): %d (%.1f%%)\n",
            n_equal_4, 100 * share_equal_4))

# Counterfactual: if ownership bands were independent of number of PSCs,
# what fraction of 4-PSC companies would have all 4 in 25-50%?
# Use the overall distribution of ownership bands among individual PSCs
band_dist <- df[n_individual > 0, .(
  total_25_50 = sum(n_band_25_50),
  total_50_75 = sum(n_band_50_75),
  total_75_100 = sum(n_band_75_100),
  total_other = sum(n_band_25plus + n_band_unknown)
)]
total_indiv <- band_dist$total_25_50 + band_dist$total_50_75 +
  band_dist$total_75_100 + band_dist$total_other
p_25_50 <- band_dist$total_25_50 / total_indiv

# Under independence, P(all 4 in 25-50%) = p^4
expected_share <- p_25_50^4
cat(sprintf("P(25-50%% band): %.3f\n", p_25_50))
cat(sprintf("Expected P(all 4 in 25-50%%) under independence: %.4f (%.1f%%)\n",
            expected_share, 100 * expected_share))
cat(sprintf("Observed/Expected ratio: %.1f\n", share_equal_4 / expected_share))

# Test: binomial test of equal-split rate
binom_test <- binom.test(n_equal_4, n_four, p = expected_share)
cat(sprintf("Binomial test p-value: %s\n",
            format.pval(binom_test$p.value, digits = 3)))

# ============================================================================
# 3. Sector Heterogeneity
# ============================================================================
# High-risk sectors (financial, real estate, professional services) should
# show more avoidance because transparency is more costly

cat("\n=== Sector Heterogeneity ===\n")

sector_results <- df[!is.na(high_risk) & n_individual > 0, .(
  n_companies = .N,
  pct_4psc = 100 * mean(n_individual == 4),
  pct_4equal = 100 * mean(n_individual == 4 & n_band_25_50 == 4),
  pct_5plus = 100 * mean(n_individual >= 5),
  pct_foreign = 100 * mean(n_foreign > 0),
  pct_corporate = 100 * mean(has_corporate_psc)
), by = .(high_risk)]
print(sector_results)

# Detailed sector breakdown
sector_detail <- df[!is.na(sic_section) & n_individual > 0 &
                      sic_section != "Other", .(
  n_companies = .N,
  pct_4equal = 100 * mean(n_individual == 4 & n_band_25_50 == 4),
  pct_5plus = 100 * mean(n_individual >= 5),
  pct_foreign = 100 * mean(n_foreign > 0)
), by = sic_section][order(-pct_4equal)]
cat("\n=== Sector Detail ===\n")
print(sector_detail)

# Regression: 4-way equal split ~ high_risk + controls
df[, y_equal_4 := as.integer(n_individual == 4 & n_band_25_50 == 4)]
df[, y_4plus := as.integer(n_individual >= 4)]
df[, y_5plus := as.integer(n_individual >= 5)]
df[, y_foreign_psc := as.integer(n_foreign > 0)]

# Among multi-PSC companies (n >= 2)
multi <- df[n_individual >= 2 & !is.na(high_risk) & !is.na(inc_year)]

reg1 <- feols(y_equal_4 ~ high_risk, data = multi, vcov = "hetero")
reg2 <- feols(y_equal_4 ~ high_risk + y_foreign_psc + has_corporate_psc,
              data = multi, vcov = "hetero")
reg3 <- feols(y_equal_4 ~ high_risk + y_foreign_psc + has_corporate_psc |
                inc_year, data = multi, vcov = "hetero")

cat("\n=== Regression: Equal-split probability ===\n")
etable(reg1, reg2, reg3, headers = c("(1)", "(2)", "(3)"))

# ============================================================================
# 4. Temporal Variation (Difference-in-Bunching)
# ============================================================================
# Compare ownership structures of companies incorporated pre vs post PSC register

cat("\n=== Temporal Variation ===\n")

# Distribution by era
era_dist <- df[!is.na(era) & n_individual > 0, .(
  N = .N
), by = .(era, n_pscs = pmin(n_individual, 8))][order(era, n_pscs)]

era_dist[, pct := 100 * N / sum(N), by = era]
cat("PSC count distribution by era:\n")
print(dcast(era_dist, n_pscs ~ era, value.var = "pct"))

# Key test: is the 5+ share higher post-2016 CONDITIONAL on having 3+ PSCs?
multi3 <- df[n_individual >= 3 & !is.na(era)]
era_multi <- multi3[, .(
  n = .N,
  pct_4 = 100 * mean(n_individual == 4),
  pct_5plus = 100 * mean(n_individual >= 5),
  pct_equal_4 = 100 * mean(n_individual == 4 & n_band_25_50 == 4)
), by = era]

cat("\nAmong companies with 3+ individual PSCs:\n")
print(era_multi)

# ============================================================================
# 5. Foreign Ownership Channel
# ============================================================================

cat("\n=== Foreign Ownership and Threshold Avoidance ===\n")

# Companies with foreign PSCs may value opacity more
foreign_test <- df[n_individual >= 2 & !is.na(high_risk), .(
  n = .N,
  pct_equal_4 = 100 * mean(y_equal_4),
  pct_5plus = 100 * mean(y_5plus),
  mean_pscs = mean(n_individual)
), by = has_foreign]
print(foreign_test)

# Interaction: foreign × high-risk
reg4 <- feols(y_equal_4 ~ high_risk * y_foreign_psc | inc_year,
              data = multi, vcov = "hetero")

cat("\n=== Foreign × High-Risk Interaction ===\n")
etable(reg4)

# ============================================================================
# 6. Save diagnostics for validator
# ============================================================================

diagnostics <- list(
  n_treated = nrow(df[n_individual == 4 & n_band_25_50 == 4]),
  n_pre = length(unique(df[!is.na(era) & era == "Pre-PSC", inc_year])),
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# ============================================================================
# 7. Save key objects for tables
# ============================================================================

save(dist, four_psc, sector_results, sector_detail, era_dist, era_multi,
     foreign_test, reg1, reg2, reg3, reg4, b_hat,
     n_four, n_equal_4, share_equal_4, expected_share, p_25_50,
     total_excess_4, total_excess_5, se_4, se_5,
     file = file.path(data_dir, "analysis_results.RData"))
cat("Analysis objects saved.\n")
