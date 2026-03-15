# 03_main_analysis.R — RDD estimation at 25% revenue decline threshold
# PPP Nonprofit Employment RDD (apep_0698)

source("00_packages.R")
library(rdrobust)
library(fixest)
library(data.table)

data_dir <- "../data"
fig_dir <- "../figures"  # Not used in V1, but save diagnostic plots as reference
tab_dir <- "../tables"
dir.create(fig_dir, showWarnings = FALSE)
dir.create(tab_dir, showWarnings = FALSE)

# Load RDD sample
rdd <- fread(file.path(data_dir, "rdd_sample.csv"))
cat("RDD sample:", nrow(rdd), "organizations\n")

# ============================================================
# 1. First Stage: P(Second Draw) vs Revenue Decline
# ============================================================
cat("\n=== First Stage Analysis ===\n")

# Center running variable at -25% (the eligibility threshold)
rdd[, x := rev_decline_pct - (-25)]  # x > 0 means decline > 25% (eligible)
rdd[, above_threshold := as.integer(x >= 0)]

cat("Above threshold (decline >= 25%):", sum(rdd$above_threshold), "\n")
cat("Below threshold (decline < 25%):", sum(rdd$above_threshold == 0), "\n")
cat("P(Second Draw | above):", round(mean(rdd[above_threshold == 1]$ppp_second_draw), 3), "\n")
cat("P(Second Draw | below):", round(mean(rdd[above_threshold == 0]$ppp_second_draw), 3), "\n")

# First stage RDD
cat("\nFirst stage: P(Second Draw PPP)\n")
fs <- rdrobust(y = rdd$ppp_second_draw, x = rdd$x, c = 0, kernel = "triangular")
cat("  Estimate:", round(fs$coef[1], 4), "\n")
cat("  SE:", round(fs$se[1], 4), "\n")
cat("  p-value:", round(fs$pv[1], 4), "\n")
cat("  BW left:", round(fs$bws[1, 1], 1), " BW right:", round(fs$bws[1, 2], 1), "\n")
cat("  N left:", fs$N_h[1], " N right:", fs$N_h[2], "\n")

# Also check first stage for any PPP receipt
cat("\nFirst stage: P(Any PPP)\n")
fs_any <- rdrobust(y = rdd$ppp_any, x = rdd$x, c = 0, kernel = "triangular")
cat("  Estimate:", round(fs_any$coef[1], 4), "\n")
cat("  p-value:", round(fs_any$pv[1], 4), "\n")

# ============================================================
# 2. Reduced-Form RDD: Employment Outcomes
# ============================================================
cat("\n=== Reduced-Form RDD ===\n")

# Main outcomes: log employment in 2021, 2022, 2023
outcomes <- c("log_emp_2021", "log_emp_2022", "log_emp_2023")
outcome_labels <- c("Log Employment 2021", "Log Employment 2022", "Log Employment 2023")

rdd_results <- list()
for (i in seq_along(outcomes)) {
  y_var <- outcomes[i]
  if (!y_var %in% names(rdd)) next
  y <- rdd[[y_var]]
  valid <- !is.na(y) & !is.na(rdd$x)

  cat("\n", outcome_labels[i], ":\n")
  res <- rdrobust(y = y[valid], x = rdd$x[valid], c = 0, kernel = "triangular")
  cat("  Estimate:", round(res$coef[1], 4), "\n")
  cat("  SE:", round(res$se[1], 4), "\n")
  cat("  p-value:", round(res$pv[1], 4), "\n")
  cat("  N (left, right):", res$N_h[1], ",", res$N_h[2], "\n")
  cat("  BW:", round(res$bws[1, 1], 1), "\n")

  rdd_results[[y_var]] <- res
}

# Employment growth outcomes (levels, not logs)
cat("\n=== Employment Growth RDD ===\n")
growth_outcomes <- c("emp_growth_2021", "emp_growth_2022")
for (gv in growth_outcomes) {
  if (!gv %in% names(rdd)) next
  y <- rdd[[gv]]
  # Winsorize extreme growth
  y[y < -1] <- -1
  y[y > 2] <- 2
  valid <- !is.na(y) & !is.na(rdd$x) & is.finite(y)
  cat("\n", gv, ":\n")
  res <- rdrobust(y = y[valid], x = rdd$x[valid], c = 0, kernel = "triangular")
  cat("  Estimate:", round(res$coef[1], 4), "\n")
  cat("  p-value:", round(res$pv[1], 4), "\n")
  rdd_results[[gv]] <- res
}

# ============================================================
# 3. Fuzzy RDD (IV: threshold → Second Draw → employment)
# ============================================================
cat("\n=== Fuzzy RDD (IV) ===\n")

# Only if first stage is strong enough
if (abs(fs$coef[1]) > 0.01) {
  for (i in seq_along(outcomes)) {
    y_var <- outcomes[i]
    if (!y_var %in% names(rdd)) next
    y <- rdd[[y_var]]
    valid <- !is.na(y) & !is.na(rdd$x) & !is.na(rdd$ppp_second_draw)

    cat("\nFuzzy RDD:", outcome_labels[i], "\n")
    tryCatch({
      res_fuzzy <- rdrobust(y = y[valid], x = rdd$x[valid], c = 0,
                            fuzzy = rdd$ppp_second_draw[valid],
                            kernel = "triangular")
      cat("  LATE estimate:", round(res_fuzzy$coef[1], 4), "\n")
      cat("  SE:", round(res_fuzzy$se[1], 4), "\n")
      cat("  p-value:", round(res_fuzzy$pv[1], 4), "\n")
      rdd_results[[paste0("fuzzy_", y_var)]] <- res_fuzzy
    }, error = function(e) cat("  Fuzzy RDD failed:", conditionMessage(e), "\n"))
  }
} else {
  cat("First stage too weak for fuzzy RDD. Relying on reduced form.\n")
}

# ============================================================
# 4. Bandwidth Sensitivity
# ============================================================
cat("\n=== Bandwidth Sensitivity ===\n")

# Primary outcome: log_emp_2021
y_main <- rdd$log_emp_2021
valid_main <- !is.na(y_main) & !is.na(rdd$x)

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
opt_bw <- rdd_results[["log_emp_2021"]]$bws[1, 1]

bw_table <- data.frame(
  BW = numeric(), Estimate = numeric(), SE = numeric(),
  pval = numeric(), N_left = integer(), N_right = integer()
)

for (m in bw_multipliers) {
  bw <- opt_bw * m
  res <- rdrobust(y = y_main[valid_main], x = rdd$x[valid_main], c = 0,
                  h = bw, kernel = "triangular")
  bw_table <- rbind(bw_table, data.frame(
    BW = round(bw, 1), Estimate = round(res$coef[1], 4),
    SE = round(res$se[1], 4), pval = round(res$pv[1], 4),
    N_left = res$N_h[1], N_right = res$N_h[2]
  ))
}

cat("Bandwidth sensitivity for log_emp_2021:\n")
print(bw_table)

# ============================================================
# 5. Heterogeneity by Organization Size
# ============================================================
cat("\n=== Heterogeneity by Size ===\n")

for (sz in c("Micro (1-10)", "Small (11-50)", "Medium (51-250)", "Large (251+)")) {
  subset_idx <- rdd$size_cat == sz & !is.na(rdd$log_emp_2021) & !is.na(rdd$x)
  if (sum(subset_idx) < 200) {
    cat(sz, ": too few observations (", sum(subset_idx), ")\n")
    next
  }
  cat("\n", sz, "(N =", sum(subset_idx), "):\n")
  tryCatch({
    res <- rdrobust(y = rdd$log_emp_2021[subset_idx],
                    x = rdd$x[subset_idx], c = 0, kernel = "triangular")
    cat("  Estimate:", round(res$coef[1], 4), " (p =", round(res$pv[1], 4), ")\n")
  }, error = function(e) cat("  Failed:", conditionMessage(e), "\n"))
}

# ============================================================
# 6. Diagnostics JSON
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(rdd$ppp_second_draw == 1),
  n_pre = 3L,  # 2018, 2019 as pre-periods for 2019 baseline
  n_obs = nrow(rdd),
  n_above_threshold = sum(rdd$above_threshold),
  n_below_threshold = sum(rdd$above_threshold == 0),
  first_stage_coef = round(fs$coef[1], 4),
  first_stage_pval = round(fs$pv[1], 4),
  main_estimate = round(rdd_results[["log_emp_2021"]]$coef[1], 4),
  main_pval = round(rdd_results[["log_emp_2021"]]$pv[1], 4),
  optimal_bw = round(opt_bw, 1)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics written to data/diagnostics.json\n")

# ============================================================
# 7. Summary Statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Overall sample
sum_stats <- rdd[, .(
  N = .N,
  emp_mean = round(mean(emp_2019, na.rm = TRUE), 1),
  emp_sd = round(sd(emp_2019, na.rm = TRUE), 1),
  emp_median = round(median(emp_2019, na.rm = TRUE), 1),
  rev_mean = round(mean(rev_base, na.rm = TRUE) / 1e6, 2),
  rev_sd = round(sd(rev_base, na.rm = TRUE) / 1e6, 2),
  decline_mean = round(mean(rev_decline_pct, na.rm = TRUE), 1),
  decline_sd = round(sd(rev_decline_pct, na.rm = TRUE), 1),
  ppp_rate = round(mean(ppp_any), 3),
  second_draw_rate = round(mean(ppp_second_draw), 3)
)]

cat("Full sample:\n")
print(sum_stats)

# By treatment status
cat("\nBy Second Draw status:\n")
sum_by_treat <- rdd[, .(
  N = .N,
  emp_2019 = round(mean(emp_2019, na.rm = TRUE), 1),
  rev_2019_M = round(mean(rev_base, na.rm = TRUE) / 1e6, 2),
  decline_pct = round(mean(rev_decline_pct, na.rm = TRUE), 1),
  emp_2021 = round(mean(emp_2021, na.rm = TRUE), 1),
  emp_2022 = round(mean(emp_2022, na.rm = TRUE), 1)
), by = ppp_second_draw]
print(sum_by_treat)

# Save results for table generation
saveRDS(rdd_results, file.path(data_dir, "rdd_results.rds"))
saveRDS(bw_table, file.path(data_dir, "bw_sensitivity.rds"))
saveRDS(list(fs = fs, fs_any = fs_any), file.path(data_dir, "first_stage.rds"))

cat("\n=== Main analysis complete ===\n")
