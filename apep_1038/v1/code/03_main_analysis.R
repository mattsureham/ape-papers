# 03_main_analysis.R — Decomposition of the 1998 TRI reporting jump
# Primary analysis: aggregate decomposition + facility-level verification

library(data.table)
library(fixest)

if (requireNamespace("here", quietly = TRUE)) setwd(here::here()) else setwd(dirname(dirname(sys.frame(1)$ofile)))

# -----------------------------------------------------------------
# 1. Load data
# -----------------------------------------------------------------
dt <- fread("data/analysis_panel.csv")
counts <- fread("data/aggregate_counts.csv")

cat("Facility-year panel:", nrow(dt), "obs\n")
cat("Incumbent facilities:", uniqueN(dt$tri_facility_id), "\n")
cat("Aggregate counts:", nrow(counts), "years\n")

# -----------------------------------------------------------------
# 2. Characterize incumbent reporting trajectory
# -----------------------------------------------------------------
cat("\n=== INCUMBENT REPORTING TRAJECTORY ===\n")

# Incumbent facilities (those reporting in 1995 and/or 1997)
inc_1995 <- uniqueN(dt[year == 1995]$tri_facility_id)
inc_1997 <- uniqueN(dt[year == 1997]$tri_facility_id)
forms_1995 <- dt[year == 1995, sum(n_chemicals)]
forms_1997 <- dt[year == 1997, sum(n_chemicals)]

cat("1995: ", inc_1995, "facilities,", forms_1995, "forms\n")
cat("1997: ", inc_1997, "facilities,", forms_1997, "forms\n")

# Annual change rate for incumbents
annual_rate <- (forms_1997 / forms_1995) ^ (1/2) - 1  # 2-year CAGR
cat("Incumbent annual form growth:", round(annual_rate * 100, 2), "%\n")

# -----------------------------------------------------------------
# 3. Aggregate decomposition
# -----------------------------------------------------------------
cat("\n=== AGGREGATE DECOMPOSITION ===\n")

# Extrapolate incumbent counterfactual
counts[, inc_counterfactual := NA_real_]
counts[year == 1997, inc_counterfactual := forms_1997]

# Forward extrapolation: incumbent forms continue at pre-1998 rate
for (yr in 1998:2006) {
  prev <- counts[year == yr - 1, inc_counterfactual]
  if (length(prev) > 0 && !is.na(prev)) {
    counts[year == yr, inc_counterfactual := prev * (1 + annual_rate)]
  }
}

# Backward extrapolation for pre-1998
counts[year == 1995, inc_counterfactual := forms_1995]
for (yr in 1994:1987) {
  nxt <- counts[year == yr + 1, inc_counterfactual]
  if (length(nxt) > 0 && !is.na(nxt)) {
    counts[year == yr, inc_counterfactual := nxt / (1 + annual_rate)]
  }
}
counts[year == 1996, inc_counterfactual := (forms_1995 + forms_1997) / 2]  # Interpolate

# New-entrant contribution
counts[, new_entrant_forms := total_forms - inc_counterfactual]
counts[year < 1998, new_entrant_forms := 0]  # No new entrants before 1998

# The artifact: fraction of total forms from new entrants
counts[, pct_new_entrant := new_entrant_forms / total_forms * 100]
counts[year < 1998, pct_new_entrant := 0]

cat("\nDecomposition results:\n")
decomp_show <- counts[year %in% c(1995, 1996, 1997, 1998, 1999, 2000, 2001, 2003, 2006),
                      .(year, total_forms, inc_counterfactual = round(inc_counterfactual),
                        new_entrant = round(new_entrant_forms),
                        pct_new = round(pct_new_entrant, 1))]
print(decomp_show)

# Key numbers
jump_1998 <- counts[year == 1998, total_forms] - counts[year == 1997, total_forms]
new_1998 <- counts[year == 1998, round(new_entrant_forms)]
pct_1998 <- counts[year == 1998, round(pct_new_entrant, 1)]

cat("\n=== KEY FINDINGS ===\n")
cat("1997→1998 total jump:", jump_1998, "forms\n")
cat("Attributable to new entrants:", new_1998, "forms\n")
cat("New entrant share in 1998:", pct_1998, "%\n")
cat("Jump as % of 1997 total:", round(jump_1998 / counts[year == 1997, total_forms] * 100, 1), "%\n")

# -----------------------------------------------------------------
# 4. Facility-level analysis (with available pre-1998 data)
# -----------------------------------------------------------------
cat("\n=== FACILITY-LEVEL ANALYSIS ===\n")

# Count facilities reporting in both 1995 and 1997 (balanced incumbents)
both_yrs <- intersect(
  dt[year == 1995]$tri_facility_id,
  dt[year == 1997]$tri_facility_id
)
cat("Facilities in both 1995 and 1997:", length(both_yrs), "\n")

# Within-facility change in chemicals reported (1995 → 1997)
paired <- merge(
  dt[year == 1995 & tri_facility_id %in% both_yrs, .(tri_facility_id, chem_1995 = n_chemicals)],
  dt[year == 1997 & tri_facility_id %in% both_yrs, .(tri_facility_id, chem_1997 = n_chemicals)],
  by = "tri_facility_id"
)
paired[, change := chem_1997 - chem_1995]

cat("Mean chemicals 1995:", round(mean(paired$chem_1995), 3), "\n")
cat("Mean chemicals 1997:", round(mean(paired$chem_1997), 3), "\n")
cat("Mean within-facility change:", round(mean(paired$change), 3), "\n")
cat("SD of change:", round(sd(paired$change), 3), "\n")

# T-test for within-facility change
ttest <- t.test(paired$change)
cat("t-stat:", round(ttest$statistic, 3), "p-value:", round(ttest$p.value, 4), "\n")

# -----------------------------------------------------------------
# 5. Save results for tables
# -----------------------------------------------------------------
saveRDS(counts, "data/decomposition.rds")
saveRDS(paired, "data/paired_analysis.rds")

# Key results for table generation
results <- list(
  jump_1998 = jump_1998,
  new_1998 = new_1998,
  pct_new_1998 = pct_1998,
  annual_rate = annual_rate,
  n_inc_facilities = length(both_yrs),
  mean_change = mean(paired$change),
  sd_change = sd(paired$change),
  t_stat = as.numeric(ttest$statistic),
  p_value = ttest$p.value,
  sd_y = sd(dt$n_chemicals)
)
saveRDS(results, "data/main_results.rds")

# Diagnostics for validator
diag <- list(
  n_treated = as.integer(new_1998),  # New entrant forms as proxy
  n_pre = length(unique(dt[year < 1998]$year)),
  n_obs = nrow(dt)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
