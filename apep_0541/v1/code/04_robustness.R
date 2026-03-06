###############################################################################
# 04_robustness.R — Robustness checks
# APEP-0541: How Many Generics Does It Take?
###############################################################################

source("00_packages.R")

data_dir <- "../data"
panel  <- fread(file.path(data_dir, "analysis_panel.csv"))
events <- fread(file.path(data_dir, "event_panel.csv"))

cat("Panel:", nrow(panel), "obs\n")

# ==========================================================================
# 1. Alternative outcome: minimum price (lowest-cost NDC)
# ==========================================================================

cat("\n=== Robustness: Minimum price ===\n")

est_min <- feols(log_min_price ~ n_competitors | market_id + week,
                 data = panel, cluster = ~market_id)
cat("log(min_price) ~ N | market + week FE\n")
cat("  Coefficient:", round(coef(est_min)["n_competitors"], 4),
    " SE:", round(se(est_min)["n_competitors"], 4), "\n")

# Non-parametric with min price
panel[, n_bin := pmin(n_competitors, 15)]
est_min_np <- feols(log_min_price ~ i(n_bin, ref = 1) | market_id + week,
                    data = panel, cluster = ~market_id)

min_coefs <- as.data.table(coeftable(est_min_np), keep.rownames = "term")
setnames(min_coefs, c("term", "estimate", "se", "tstat", "pval"))
min_coefs[, n_competitors := as.integer(gsub("n_bin::", "", term))]
min_coefs <- min_coefs[!is.na(n_competitors)]
min_coefs[, specification := "min_price"]
fwrite(min_coefs, file.path(data_dir, "robustness_min_price.csv"))

# ==========================================================================
# 2. Cross-sectional OLS (for comparison — shows selection)
# ==========================================================================

cat("\n=== Cross-sectional comparison (without market FE) ===\n")

# Without market FE — just week FE
est_cross <- feols(log_price ~ n_competitors | week,
                   data = panel, cluster = ~market_id)
cat("Cross-section: log(price) ~ N | week FE only\n")
cat("  Coefficient:", round(coef(est_cross)["n_competitors"], 4),
    " SE:", round(se(est_cross)["n_competitors"], 4), "\n")

# Non-parametric cross-section
est_cross_np <- feols(log_price ~ i(n_bin, ref = 1) | week,
                      data = panel, cluster = ~market_id)

cross_coefs <- as.data.table(coeftable(est_cross_np), keep.rownames = "term")
setnames(cross_coefs, c("term", "estimate", "se", "tstat", "pval"))
cross_coefs[, n_competitors := as.integer(gsub("n_bin::", "", term))]
cross_coefs <- cross_coefs[!is.na(n_competitors)]
cross_coefs[, specification := "cross_section"]

# Main specification (with market FE)
main_coefs <- fread(file.path(data_dir, "nonparam_curve.csv"))
main_coefs[, specification := "within_market"]

# Compare cross-section vs within-market
compare <- rbind(
  cross_coefs[, .(n_competitors, estimate, se, specification)],
  main_coefs[, .(n_competitors, estimate, se, specification)]
)
fwrite(compare, file.path(data_dir, "cross_vs_within.csv"))

cat("\nCross-section vs Within-market comparison:\n")
cat(sprintf("%-5s %-15s %-15s\n", "N", "Cross-section", "Within-market"))
for (n in 2:15) {
  cs <- cross_coefs[n_competitors == n]
  wm <- main_coefs[n_competitors == n]
  if (nrow(cs) > 0 && nrow(wm) > 0) {
    cat(sprintf("%-5d %-15.4f %-15.4f\n",
                n, cs$estimate, wm$estimate))
  }
}

# ==========================================================================
# 3. Placebo: shuffle market labels
# ==========================================================================

cat("\n=== Placebo: permuted market assignments ===\n")

set.seed(20260306)
n_perms <- 100

perm_coefs <- numeric(n_perms)
# Get market-level competitor count (time-average) for shuffling
market_avg_n <- panel[, .(avg_n = mean(n_competitors)), by = market_id]

for (p in seq_len(n_perms)) {
  # Randomly reassign market-average competitor counts across markets
  perm_map <- copy(market_avg_n)
  perm_map[, shuffled_n := sample(avg_n)]

  perm_data <- merge(panel, perm_map[, .(market_id, shuffled_n)], by = "market_id")

  est_perm <- tryCatch({
    feols(log_price ~ shuffled_n | market_id + week,
          data = perm_data, cluster = ~market_id)
  }, error = function(e) NULL)

  if (!is.null(est_perm)) {
    perm_coefs[p] <- coef(est_perm)["shuffled_n"]
  }
}

actual_coef <- coef(feols(log_price ~ n_competitors | market_id + week,
                           data = panel, cluster = ~market_id))["n_competitors"]

placebo_results <- data.table(
  entry_position = 0,
  actual_effect = actual_coef,
  placebo_mean = mean(perm_coefs, na.rm = TRUE),
  placebo_sd = sd(perm_coefs, na.rm = TRUE),
  placebo_p = mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE),
  n_perms = sum(!is.na(perm_coefs))
)

cat(sprintf("  Actual: %.5f, Placebo mean: %.5f, p = %.3f\n",
            actual_coef, mean(perm_coefs, na.rm = TRUE),
            mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)))

fwrite(placebo_results, file.path(data_dir, "placebo_results.csv"))

# ==========================================================================
# 4. Event study: different pre/post windows
# ==========================================================================

cat("\n=== Event study window sensitivity ===\n")

events[, event_time_int := as.integer(event_time)]

# Short window (8 pre, 12 post)
events_short <- events[event_time >= -8 & event_time <= 12]
est_short <- tryCatch({
  feols(log_price ~ i(event_time_int, ref = -1) | event_id + week,
        data = events_short, cluster = ~event_id)
}, error = function(e) NULL)

if (!is.null(est_short)) {
  short_ct <- as.data.table(coeftable(est_short), keep.rownames = "term")
  setnames(short_ct, c("term", "estimate", "se", "tstat", "pval"))
  short_ct[, event_time := as.integer(gsub("event_time_int::", "", term))]
  short_ct <- short_ct[!is.na(event_time)]
  short_ct[, specification := "short_window"]
  fwrite(short_ct, file.path(data_dir, "event_study_short.csv"))
  cat("  Short window avg post:", round(mean(short_ct[event_time > 0]$estimate), 4), "\n")
}

# ==========================================================================
# 5. Exclude markets with very high competitor counts
# ==========================================================================

cat("\n=== Robustness: exclude markets with N > 20 ===\n")

panel_trim <- panel[n_competitors <= 20]
est_trim <- feols(log_price ~ n_competitors | market_id + week,
                  data = panel_trim, cluster = ~market_id)
cat("Trimmed: coefficient =", round(coef(est_trim)["n_competitors"], 4),
    " SE =", round(se(est_trim)["n_competitors"], 4), "\n")

# ==========================================================================
# 6. Save robustness summary
# ==========================================================================

rob_summary <- data.table(
  specification = c("Main (avg price, market + week FE)",
                     "Min price outcome",
                     "Cross-section (no market FE)",
                     "Trimmed (N <= 20)",
                     "Placebo (shuffled markets)",
                     "Event study (pooled, short window)"),
  coefficient = c(
    round(coef(feols(log_price ~ n_competitors | market_id + week,
                      data = panel, cluster = ~market_id))["n_competitors"], 5),
    round(coef(est_min)["n_competitors"], 5),
    round(coef(est_cross)["n_competitors"], 5),
    round(coef(est_trim)["n_competitors"], 5),
    round(actual_coef, 5),
    if (!is.null(est_short)) {
      round(mean(short_ct[event_time > 0]$estimate, na.rm = TRUE), 5)
    } else NA
  ),
  status = "Complete"
)

fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))
cat("\nRobustness Summary:\n")
print(rob_summary)

cat("\nRobustness checks complete.\n")
