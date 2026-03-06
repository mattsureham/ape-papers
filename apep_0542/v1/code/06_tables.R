# ==============================================================================
# 06_tables.R — All tables for paper
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

# Load model objects and data
load(file.path(DATA_DIR, "model_objects.RData"))
load(file.path(DATA_DIR, "robustness_models.RData"))

sumstats <- fread(file.path(DATA_DIR, "summary_statistics.csv"))
main_res <- fread(file.path(DATA_DIR, "main_results.csv"))
rob_res <- fread(file.path(DATA_DIR, "robustness_results.csv"))

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("\n=== TABLE 1: Summary Statistics ===\n")

# Format for LaTeX
t1 <- sumstats[, .(
  Treatment,
  N = formatC(n_transactions, format = "d", big.mark = ","),
  `Mean Price` = paste0("\\pounds", formatC(round(mean_price), format = "d", big.mark = ",")),
  `Median Price` = paste0("\\pounds", formatC(round(median_price), format = "d", big.mark = ",")),
  `Mean log(Price)` = round(mean_log_price, 3),
  `\\% Detached` = round(pct_detached * 100, 1),
  `\\% Terraced` = round(pct_terraced * 100, 1),
  `\\% Flat` = round(pct_flat * 100, 1),
  `\\% Freehold` = round(pct_freehold * 100, 1),
  `\\% New Build` = round(pct_new_build * 100, 1)
)]
print(t1)
fwrite(t1, file.path(TABLE_DIR, "table1_summary.csv"))

# ==============================================================================
# Table 2: Main DiD Results
# ==============================================================================

cat("\n=== TABLE 2: Main DiD Results ===\n")

# Use etable for publication-quality regression table
etable(m1_2km, m1, m1_10km, m2, m3,
       headers = c("2km", "5km", "10km", "Phase 2 vs 1", "1/Distance"),
       keep = c("near_station|treated|inv_dist"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       file = file.path(TABLE_DIR, "table2_main.tex"),
       replace = TRUE,
       title = "Effect of HS2 Phase 2 Cancellation on Property Prices")

cat("Saved Table 2: Main DiD results (tex)\n")

# Also save CSV version
fwrite(main_res, file.path(TABLE_DIR, "table2_main.csv"))

# ==============================================================================
# Table 3: Robustness and Placebo Tests
# ==============================================================================

cat("\n=== TABLE 3: Robustness ===\n")

etable(m_base, m_placebo, m_temp_placebo, m_no_london, m_repeat,
       headers = c("Baseline", "Phase 1\nPlacebo", "Temporal\nPlacebo",
                    "Excl.\nLondon", "Repeat\nSales"),
       keep = c("near_station|near_phase1|fake"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       file = file.path(TABLE_DIR, "table3_robustness.tex"),
       replace = TRUE,
       title = "Robustness Checks and Placebo Tests")

cat("Saved Table 3: Robustness (tex)\n")

# ==============================================================================
# Table 4: Eastern vs Western leg
# ==============================================================================

cat("\n=== TABLE 4: Eastern vs Western ===\n")

etable(m_east,
       keep = c("eastern|western"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       file = file.path(TABLE_DIR, "table4_east_west.tex"),
       replace = TRUE,
       title = "Eastern vs Western Leg Treatment Effects")

cat("Saved Table 4: Eastern vs Western (tex)\n")

# ==============================================================================
# Table 5: Distance ring results
# ==============================================================================

cat("\n=== TABLE 5: Distance rings ===\n")

etable(m_rings,
       keep = "dist_ring",
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       file = file.path(TABLE_DIR, "table5_distance_rings.tex"),
       replace = TRUE,
       title = "Treatment Effects by Distance Ring")

cat("Saved Table 5: Distance rings (tex)\n")

# Summary robustness table
rob_summary <- rob_res[!is.na(estimate), .(test, estimate = round(estimate, 4),
                                            se = round(se, 4))]
fwrite(rob_summary, file.path(TABLE_DIR, "robustness_summary.csv"))

cat("\nAll tables saved to:", TABLE_DIR, "\n")
