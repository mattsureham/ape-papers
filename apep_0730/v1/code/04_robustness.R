# 04_robustness.R — Robustness checks and mechanism tests
# apep_0730: Time Zone Boundaries and Teen Morning Traffic Deaths

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Loading data ===\n")
df <- fread("fars_cleaned.csv")
results <- readRDS("main_results.rds")

# RDD sample
bandwidth_deg <- 1.5
rdd_df <- df[abs(dist_to_boundary) <= bandwidth_deg]

# ============================================================
# 1. BANDWIDTH SENSITIVITY
# ============================================================
cat("=== Bandwidth sensitivity ===\n")

bandwidths <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5)
bw_results <- data.table()

for (bw in bandwidths) {
  sub <- df[abs(dist_to_boundary) <= bw]
  if (nrow(sub) < 200) next

  rd <- tryCatch(
    rdrobust(y = sub$morning, x = sub$dist_to_boundary, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rd)) {
    bw_results <- rbind(bw_results, data.table(
      bandwidth = bw,
      coef = rd$coef[1],
      se = rd$se[3],  # robust SE
      ci_low = rd$ci[3, 1],
      ci_high = rd$ci[3, 2],
      n_obs = nrow(sub),
      pval = rd$pv[3]
    ))
  }
}

cat("Bandwidth sensitivity results:\n")
print(bw_results)

# ============================================================
# 2. PLACEBO CUTOFFS
# ============================================================
cat("\n=== Placebo cutoffs ===\n")

# Test at false boundaries ±1° and ±2° from true boundaries
placebo_offsets <- c(-2, -1, 1, 2)
placebo_results <- data.table()

for (offset in placebo_offsets) {
  df_temp <- copy(df)
  # Shift boundaries
  df_temp[, dist_placebo := dist_to_boundary - offset]
  sub <- df_temp[abs(dist_placebo) <= 1.5]

  if (nrow(sub) < 200) next

  rd <- tryCatch(
    rdrobust(y = sub$morning, x = sub$dist_placebo, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rd)) {
    placebo_results <- rbind(placebo_results, data.table(
      offset = offset,
      coef = rd$coef[1],
      se = rd$se[3],
      pval = rd$pv[3],
      n_obs = nrow(sub)
    ))
  }
}

cat("Placebo cutoff results:\n")
print(placebo_results)

# ============================================================
# 3. COVARIATE BALANCE AT BOUNDARY
# ============================================================
cat("\n=== Covariate balance ===\n")

# Test whether observable crash characteristics are smooth at boundary
covariates <- c("weekend", "dark", "MONTH")

balance_results <- data.table()
for (cov in covariates) {
  rd <- tryCatch(
    rdrobust(y = rdd_df[[cov]], x = rdd_df$dist_to_boundary, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rd)) {
    balance_results <- rbind(balance_results, data.table(
      covariate = cov,
      coef = rd$coef[1],
      se = rd$se[3],
      pval = rd$pv[3]
    ))
  }
}

cat("Covariate balance at boundary:\n")
print(balance_results)

# ============================================================
# 4. DONUT HOLE TEST
# ============================================================
cat("\n=== Donut hole test ===\n")

# Exclude crashes very close to boundary (±0.1°)
donut <- rdd_df[abs(dist_to_boundary) > 0.1]

rdd_donut <- tryCatch(
  rdrobust(y = donut$morning, x = donut$dist_to_boundary, c = 0,
           kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

if (!is.null(rdd_donut)) {
  cat("Donut hole RDD (excluding ±0.1°):\n")
  summary(rdd_donut)
}

# ============================================================
# 5. BOUNDARY-SPECIFIC ESTIMATES
# ============================================================
cat("\n=== Boundary-specific estimates ===\n")

boundary_results <- data.table()
for (b in c("EC", "CM", "MP")) {
  sub <- rdd_df[nearest_boundary == b]
  if (nrow(sub) < 500) next

  rd <- tryCatch(
    rdrobust(y = sub$morning, x = sub$dist_to_boundary, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rd)) {
    boundary_results <- rbind(boundary_results, data.table(
      boundary = b,
      coef = rd$coef[1],
      se = rd$se[3],
      pval = rd$pv[3],
      n_obs = nrow(sub),
      bw_opt = rd$bws[1, 1]
    ))
  }
}

cat("Boundary-specific results:\n")
print(boundary_results)

# ============================================================
# 6. WEEKDAY vs WEEKEND (MECHANISM)
# ============================================================
cat("\n=== Weekday vs Weekend ===\n")

# Social jetlag operates through school/work schedules
# Weekday mornings = forced early wake → effect should be concentrated
# Weekend mornings = can sleep in → effect should be weaker

weekday_crashes <- rdd_df[weekend == 0]
weekend_crashes <- rdd_df[weekend == 1]

rdd_weekday <- tryCatch(
  rdrobust(y = weekday_crashes$morning, x = weekday_crashes$dist_to_boundary,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

rdd_weekend <- tryCatch(
  rdrobust(y = weekend_crashes$morning, x = weekend_crashes$dist_to_boundary,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

if (!is.null(rdd_weekday)) {
  cat("Weekday morning RDD:\n")
  cat(sprintf("  Coef = %.4f, SE = %.4f, p = %.3f\n",
              rdd_weekday$coef[1], rdd_weekday$se[3], rdd_weekday$pv[3]))
}
if (!is.null(rdd_weekend)) {
  cat("Weekend morning RDD:\n")
  cat(sprintf("  Coef = %.4f, SE = %.4f, p = %.3f\n",
              rdd_weekend$coef[1], rdd_weekend$se[3], rdd_weekend$pv[3]))
}

# ============================================================
# 7. EXCLUDING COVID YEARS
# ============================================================
cat("\n=== Excluding COVID years (2020-2021) ===\n")

no_covid <- rdd_df[!(YEAR %in% c(2020, 2021))]
rdd_nocovid <- tryCatch(
  rdrobust(y = no_covid$morning, x = no_covid$dist_to_boundary,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

if (!is.null(rdd_nocovid)) {
  cat("Excluding COVID:\n")
  cat(sprintf("  Coef = %.4f, SE = %.4f, p = %.3f\n",
              rdd_nocovid$coef[1], rdd_nocovid$se[3], rdd_nocovid$pv[3]))
}

# ============================================================
# 8. SAVE ALL ROBUSTNESS RESULTS
# ============================================================

robustness <- list(
  bandwidth_sensitivity = bw_results,
  placebo_cutoffs = placebo_results,
  covariate_balance = balance_results,
  donut = if (!is.null(rdd_donut)) list(coef = rdd_donut$coef[1], se = rdd_donut$se[3], pval = rdd_donut$pv[3]) else NULL,
  boundary_specific = boundary_results,
  weekday = if (!is.null(rdd_weekday)) list(coef = rdd_weekday$coef[1], se = rdd_weekday$se[3], pval = rdd_weekday$pv[3]) else NULL,
  weekend = if (!is.null(rdd_weekend)) list(coef = rdd_weekend$coef[1], se = rdd_weekend$se[3], pval = rdd_weekend$pv[3]) else NULL,
  no_covid = if (!is.null(rdd_nocovid)) list(coef = rdd_nocovid$coef[1], se = rdd_nocovid$se[3], pval = rdd_nocovid$pv[3]) else NULL
)

saveRDS(robustness, "robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
