## 03_main_analysis.R — Primary RDD estimation
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ---- Load data ----
crashes <- fread(file.path(data_dir, "analysis_crash_level.csv"))
county_month <- fread(file.path(data_dir, "analysis_county_month.csv"))

cat("Crash-level observations:", nrow(crashes), "\n")
cat("County-month observations:", nrow(county_month), "\n")

## ---- Summary statistics ----
# Table 1: Summary statistics by treatment side
sumstats <- crashes[, .(
  N = .N,
  Fatalities = sum(FATALS),
  Pct_Phone_Distracted = round(100 * mean(phone_distracted), 2),
  Pct_Any_Distracted = round(100 * mean(any_distraction), 2),
  Pct_Drunk_Driver = round(100 * mean(DRUNK_DR > 0, na.rm = TRUE), 2),
  Mean_Dist_km = round(mean(dist_km), 1)
), by = .(Side = ifelse(treated_side == 1, "Treated", "Control"))]

cat("\n=== Summary Statistics ===\n")
print(sumstats)

# Full sample stats
full_stats <- crashes[, .(
  N = .N,
  Fatalities = sum(FATALS),
  Pct_Phone_Distracted = round(100 * mean(phone_distracted), 2),
  Pct_Any_Distracted = round(100 * mean(any_distraction), 2),
  Pct_Drunk_Driver = round(100 * mean(DRUNK_DR > 0, na.rm = TRUE), 2),
  Mean_Dist_km = round(mean(dist_km), 1)
)]
full_stats[, Side := "Full Sample"]

sumstats <- rbind(sumstats, full_stats, use.names = TRUE)

## ---- Main RDD: Difference-in-Discontinuities ----
# Strategy: compare the border discontinuity post-treatment to pre-treatment
# This is a spatial difference-in-discontinuities (diff-in-disc)

# For the diff-in-disc, we stack all border pairs and use:
# Y_i = a + b*Post_i + c*Treated_side_i + tau*(Post*Treated_side) + f(dist) + FE + e
# where tau is the diff-in-disc estimate

cat("\n=== Main Analysis: Difference-in-Discontinuities ===\n")

# Crash-level analysis with different bandwidths
bandwidths <- c(10, 20, 30, 50)
results_list <- list()

for (bw in bandwidths) {
  sub <- crashes[dist_km <= bw]
  cat("\nBandwidth:", bw, "km | N =", nrow(sub), "\n")

  # Main diff-in-disc specification
  # Outcome: all fatal crashes (binary at crash level is trivially 1)
  # We need to work at grid-cell or county-month level for counts

  # Use county-month panel for count regressions
  cm <- county_month[mean_dist <= bw]

  # Spec 1: All crashes
  m1 <- feols(n_crashes ~ treated_side * post | pair_id + YEAR:MONTH,
              data = cm, cluster = ~STATE + COUNTY)

  # Spec 2: Phone-distracted crashes (mechanism)
  m2 <- feols(n_phone ~ treated_side * post | pair_id + YEAR:MONTH,
              data = cm, cluster = ~STATE + COUNTY)

  # Spec 3: Any distraction crashes
  m3 <- feols(n_distracted ~ treated_side * post | pair_id + YEAR:MONTH,
              data = cm, cluster = ~STATE + COUNTY)

  results_list[[as.character(bw)]] <- list(
    bw = bw,
    n_obs = nrow(cm),
    n_counties = uniqueN(cm, by = c("STATE", "COUNTY")),
    all_crashes = m1,
    phone = m2,
    distracted = m3
  )

  cat("  All crashes: coef =", round(coef(m1)["treated_side:post"], 4),
      "se =", round(se(m1)["treated_side:post"], 4), "\n")
  cat("  Phone-dist:  coef =", round(coef(m2)["treated_side:post"], 4),
      "se =", round(se(m2)["treated_side:post"], 4), "\n")
}

## ---- Preferred specification: 30km bandwidth ----
pref <- results_list[["30"]]
cat("\n=== Preferred Specification (30km bandwidth) ===\n")
summary(pref$all_crashes)
summary(pref$phone)
summary(pref$distracted)

## ---- RDD using rdrobust at border ----
# For each post-treatment period, run rdrobust with signed distance
cat("\n=== RDD (rdrobust) on post-treatment crashes ===\n")

post_crashes <- crashes[post == 1]
pre_crashes <- crashes[post == 0]

if (nrow(post_crashes) > 100) {
  # Post-treatment: should see discontinuity
  rdd_post <- rdrobust(y = post_crashes$phone_distracted,
                       x = post_crashes$signed_dist,
                       c = 0, kernel = "triangular",
                       bwselect = "mserd")
  cat("\nPost-treatment RDD (phone distracted):\n")
  cat("  Estimate:", round(rdd_post$coef[1], 4), "\n")
  cat("  SE:", round(rdd_post$se[1], 4), "\n")
  cat("  p-value:", round(rdd_post$pv[1], 4), "\n")
  cat("  Bandwidth:", round(rdd_post$bws[1,1], 2), "km\n")
  cat("  N (left/right):", rdd_post$N_h[1], "/", rdd_post$N_h[2], "\n")
}

if (nrow(pre_crashes) > 100) {
  # Pre-treatment: should see NO discontinuity (placebo)
  rdd_pre <- rdrobust(y = pre_crashes$phone_distracted,
                      x = pre_crashes$signed_dist,
                      c = 0, kernel = "triangular",
                      bwselect = "mserd")
  cat("\nPre-treatment RDD (phone distracted, PLACEBO):\n")
  cat("  Estimate:", round(rdd_pre$coef[1], 4), "\n")
  cat("  SE:", round(rdd_pre$se[1], 4), "\n")
  cat("  p-value:", round(rdd_pre$pv[1], 4), "\n")
}

## ---- Placebo: Non-phone distractions ----
cat("\n=== Placebo: Non-phone distractions ===\n")

# Non-phone distraction = any_distraction - phone_distracted
crashes[, nonphone_distracted := pmax(any_distraction - phone_distracted, 0L)]

post_crashes_np <- crashes[post == 1]

if (nrow(post_crashes_np) > 100) {
  rdd_placebo <- rdrobust(y = post_crashes_np$nonphone_distracted,
                          x = post_crashes_np$signed_dist,
                          c = 0, kernel = "triangular",
                          bwselect = "mserd")
  cat("Post-treatment RDD (non-phone distraction, PLACEBO):\n")
  cat("  Estimate:", round(rdd_placebo$coef[1], 4), "\n")
  cat("  SE:", round(rdd_placebo$se[1], 4), "\n")
  cat("  p-value:", round(rdd_placebo$pv[1], 4), "\n")
}

## ---- Save results for tables ----
# Collect coefficients for Table 2
table2_data <- data.table(
  bandwidth = integer(),
  outcome = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric(),
  n_obs = integer(),
  n_counties = integer()
)

for (bw_str in names(results_list)) {
  r <- results_list[[bw_str]]
  for (outcome_name in c("all_crashes", "phone", "distracted")) {
    m <- r[[outcome_name]]
    cf <- coef(m)["treated_side:post"]
    s <- se(m)["treated_side:post"]
    p <- pvalue(m)["treated_side:post"]
    table2_data <- rbind(table2_data, data.table(
      bandwidth = as.integer(bw_str),
      outcome = outcome_name,
      coef = cf,
      se = s,
      pval = p,
      n_obs = r$n_obs,
      n_counties = r$n_counties
    ))
  }
}

cat("\n=== Results across bandwidths ===\n")
print(table2_data)

## ---- Save diagnostics ----
n_treated_counties <- uniqueN(
  county_month[treated_side == 1 & post == 1], by = c("STATE", "COUNTY")
)
n_pre <- uniqueN(crashes[post == 0], by = c("YEAR", "MONTH"))
n_obs <- nrow(county_month[mean_dist <= 30])

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = n_obs,
  n_crashes_total = nrow(crashes),
  n_border_pairs = length(unique(crashes$pair_id)),
  n_phone_distracted = sum(crashes$phone_distracted),
  preferred_bw = 30
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

## ---- Save R objects for later scripts ----
save(results_list, table2_data, sumstats, crashes, county_month,
     file = file.path(data_dir, "analysis_results.RData"))
cat("Analysis results saved.\n")
cat("Done.\n")
