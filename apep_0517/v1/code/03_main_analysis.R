#' 03_main_analysis.R — Boundary Discontinuity Design
#' Main RDD estimates at PFA boundaries

source("00_packages.R")

DATA_DIR <- "../data"
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

cat("=== Panel loaded:", nrow(panel), "LSOA-years ===\n")

# ===================================================================
# 1. Construct the signed running variable
# ===================================================================
cat("\n=== 1. Constructing signed distance ===\n")

# For the BDD, we need a signed running variable:
# Positive = on the HIGH-CUT force side of the boundary
# Negative = on the LOW-CUT force side

# Get officer change by force (2010 to 2018)
wf <- fread(file.path(DATA_DIR, "police_workforce.csv"))

# Compute percentage change in officers 2010-2018
wf_change <- wf[year %in% c(2010, 2018),
  .(officers = officers[1]), by = .(force, year)]
wf_change <- dcast(wf_change, force ~ year, value.var = "officers")
setnames(wf_change, c("force", "off_2010", "off_2018"))
wf_change[, pct_change := (off_2018 - off_2010) / off_2010 * 100]

cat("  Officer changes (2010-2018):\n")
cat("  Most cut:", wf_change[which.min(pct_change), paste(force, round(pct_change, 1), "%")], "\n")
cat("  Least cut:", wf_change[which.max(pct_change), paste(force, round(pct_change, 1), "%")], "\n")
cat("  Median cut:", round(median(wf_change$pct_change, na.rm = TRUE), 1), "%\n")

fwrite(wf_change, file.path(DATA_DIR, "workforce_change.csv"))

# For each LSOA near a boundary, determine which side has more cuts
# Focus on LSOAs with a boundary pair assignment
bdd_panel <- panel[!is.na(boundary_pair)]

# Parse boundary pair to get the two PFA names
bdd_panel[, c("bp_pfa1", "bp_pfa2") := tstrsplit(boundary_pair, " \\| ")]

# Match force names to workforce change
# Standardize names
wf_change[, force_key := tolower(gsub(" ", "-", force))]
bdd_panel[, own_force_key := tolower(gsub(" ", "-", pfa_name))]
bdd_panel[, neighbor_force_key := tolower(gsub(" ", "-", nearest_neighbor_pfa))]

bdd_panel <- merge(bdd_panel,
  wf_change[, .(force_key, own_pct_change = pct_change)],
  by.x = "own_force_key", by.y = "force_key", all.x = TRUE)

bdd_panel <- merge(bdd_panel,
  wf_change[, .(force_key, neighbor_pct_change = pct_change)],
  by.x = "neighbor_force_key", by.y = "force_key", all.x = TRUE)

# Signed distance: positive if on the more-cut side
bdd_panel[, high_cut_side := own_pct_change < neighbor_pct_change]
bdd_panel[, signed_dist_km := ifelse(high_cut_side, dist_km, -dist_km)]

# Differential cut (absolute difference between forces at boundary)
bdd_panel[, cut_differential := abs(own_pct_change - neighbor_pct_change)]

cat("  BDD panel:", nrow(bdd_panel), "LSOA-years\n")
cat("  Mean cut differential:", round(mean(bdd_panel$cut_differential, na.rm = TRUE), 1),
    "pp\n")
cat("  High-cut side:", sum(bdd_panel$high_cut_side, na.rm = TRUE), "obs\n")

# ===================================================================
# 2. Main RDD: Total crime at boundary
# ===================================================================
cat("\n=== 2. Main RDD estimates ===\n")

# Restrict to post-austerity period for main results
bdd_post <- bdd_panel[year >= 2015 & year <= 2023]

# Pooled RDD across all boundary pairs
# Using rdrobust with boundary-pair clustering
if (nrow(bdd_post[!is.na(signed_dist_km) & !is.na(log_total_crime)]) > 100) {

  # Note: MSE-optimal bandwidth with pooled data is ~0.25km due to mass points
  # in LSOA centroids. This ultra-narrow bandwidth produces unreliable estimates
  # because local polynomial fitting is dominated by a handful of mass points.
  # We use a fixed bandwidth of 2km, consistent with geographic RDD practice
  # (Keele and Titiunik 2015). Bandwidth sensitivity is reported in Table 3.
  rdd_main <- rdrobust(
    y = bdd_post$log_total_crime,
    x = bdd_post$signed_dist_km,
    c = 0,
    h = 2,
    kernel = "triangular",
    cluster = bdd_post$boundary_pair,
    masspoints = "adjust",
    all = TRUE
  )

  cat("\n--- Main RDD: Log Total Crime ---\n")
  summary(rdd_main)

  # Save main result
  main_result <- data.table(
    outcome = "log_total_crime",
    coef = rdd_main$coef["Conventional", ],
    se = rdd_main$se["Conventional", ],
    ci_lower = rdd_main$ci["Conventional", 1],
    ci_upper = rdd_main$ci["Conventional", 2],
    p_value = rdd_main$pv["Conventional", ],
    bw_left = rdd_main$bws[1, 1],
    bw_right = rdd_main$bws[1, 2],
    n_left = rdd_main$N_h[1],
    n_right = rdd_main$N_h[2],
    n_eff = rdd_main$N_h[1] + rdd_main$N_h[2]
  )

} else {
  cat("  WARNING: Insufficient observations for RDD\n")
  main_result <- data.table(outcome = "log_total_crime", coef = NA_real_)
}

# ===================================================================
# 3. RDD by crime type
# ===================================================================
cat("\n=== 3. Crime type decomposition ===\n")

crime_outcomes <- intersect(
  c("log_anti_social_behaviour", "log_violent_crime",
    "log_violence_and_sexual_offences",
    "log_burglary", "log_robbery", "log_vehicle_crime",
    "log_criminal_damage_and_arson", "log_drugs",
    "log_other_theft", "log_shoplifting", "log_public_order",
    "log_other_crime"),
  names(bdd_post)
)

type_results <- list()
for (outcome in crime_outcomes) {
  y <- bdd_post[[outcome]]
  x <- bdd_post$signed_dist_km
  valid <- !is.na(y) & !is.na(x) & is.finite(y) & is.finite(x)

  if (sum(valid) > 100) {
    tryCatch({
      rdd_out <- rdrobust(
        y = y[valid],
        x = x[valid],
        c = 0,
        h = 2,
        kernel = "triangular",
        cluster = bdd_post$boundary_pair[valid],
        masspoints = "adjust",
        all = TRUE
      )

      type_results[[outcome]] <- data.table(
        outcome = outcome,
        coef = rdd_out$coef["Conventional", ],
        se = rdd_out$se["Conventional", ],
        p_value = rdd_out$pv["Conventional", ],
        n_eff = rdd_out$N_h[1] + rdd_out$N_h[2]
      )

      cat("  ", outcome, ": coef =", round(rdd_out$coef["Conventional", ], 4),
          " (se =", round(rdd_out$se["Conventional", ], 4), ")\n")
    }, error = function(e) {
      cat("  ", outcome, ": FAILED (", conditionMessage(e), ")\n")
    })
  }
}

type_dt <- rbindlist(type_results, fill = TRUE)

# ===================================================================
# 4. Event study: RDD by year
# ===================================================================
cat("\n=== 4. Event study (RDD by year) ===\n")

event_results <- list()
for (yr in sort(unique(bdd_panel$year))) {
  bdd_yr <- bdd_panel[year == yr]
  y <- bdd_yr$log_total_crime
  x <- bdd_yr$signed_dist_km
  valid <- !is.na(y) & !is.na(x) & is.finite(y) & is.finite(x)

  if (sum(valid) > 100) {
    tryCatch({
      rdd_yr <- rdrobust(
        y = y[valid], x = x[valid], c = 0,
        kernel = "triangular",
        cluster = bdd_yr$boundary_pair[valid],
        masspoints = "adjust"
      )

      event_results[[as.character(yr)]] <- data.table(
        year = yr,
        coef = rdd_yr$coef["Conventional", ],
        se = rdd_yr$se["Conventional", ],
        ci_lower = rdd_yr$ci["Conventional", 1],
        ci_upper = rdd_yr$ci["Conventional", 2],
        n_eff = rdd_yr$N_h[1] + rdd_yr$N_h[2]
      )

      cat("  ", yr, ": coef =", round(rdd_yr$coef["Conventional", ], 4),
          " (se =", round(rdd_yr$se["Conventional", ], 4), ")\n")
    }, error = function(e) {
      cat("  ", yr, ": FAILED\n")
    })
  }
}

event_dt <- rbindlist(event_results, fill = TRUE)

# ===================================================================
# 5. Save results
# ===================================================================
cat("\n=== Saving results ===\n")

fwrite(main_result, file.path(DATA_DIR, "rdd_main_result.csv"))
fwrite(type_dt, file.path(DATA_DIR, "rdd_by_crime_type.csv"))
fwrite(event_dt, file.path(DATA_DIR, "rdd_event_study.csv"))
fwrite(wf_change, file.path(DATA_DIR, "workforce_change.csv"))

# Save the BDD panel for robustness checks
fwrite(bdd_panel, file.path(DATA_DIR, "bdd_panel.csv"))

cat("  Results saved.\n")
cat("  Main RDD coefficient:", round(main_result$coef[1], 4), "\n")
cat("  Crime types estimated:", nrow(type_dt), "\n")
cat("  Event study years:", nrow(event_dt), "\n")
