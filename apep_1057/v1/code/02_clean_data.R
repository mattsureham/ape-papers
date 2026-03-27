# 02_clean_data.R — Clean and construct analysis panel
# apep_1057: The Consolidation Trap

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load raw data
# ============================================================================
cat("Loading raw data...\n")
systems <- fread(file.path(data_dir, "water_systems_raw.csv"))
violations <- fread(file.path(data_dir, "violations_raw.csv"))

cat("Systems:", nrow(systems), "rows,", ncol(systems), "cols\n")
cat("Violations:", nrow(violations), "rows,", ncol(violations), "cols\n")

# ============================================================================
# 2. Clean water systems
# ============================================================================
cat("\n=== Cleaning water systems ===\n")

# Activity status
systems[, active := (pws_activity_code == "A")]
systems[, inactive := (pws_activity_code == "I")]

# Parse deactivation date: format is "YYYY-MM-DD HH:MM:SS" or similar
systems[, deact_date := as.Date(substr(pws_deactivation_date, 1, 10))]

# Population served
systems[, pop_served := as.numeric(population_served_count)]

# Clean ZIP: take first 5 digits
systems[, zip5 := substr(gsub("[^0-9]", "", as.character(zip_code)), 1, 5)]

# Extract state from PWSID (first 2 chars)
systems[, state := substr(pwsid, 1, 2)]

cat("Active CWS:", sum(systems$active), "\n")
cat("Inactive CWS:", sum(systems$inactive), "\n")
cat("Inactive with deactivation date:", sum(!is.na(systems$deact_date) & systems$inactive), "\n")

# ============================================================================
# 3. Identify treatment events: deactivated CWS matched to active CWS by ZIP
# ============================================================================
cat("\n=== Matching deactivated systems to receivers ===\n")

# Deactivated systems with valid date and ZIP, 2006-2024
deactivated <- systems[inactive == TRUE & !is.na(deact_date) & nchar(zip5) == 5 &
                          deact_date >= as.Date("2006-01-01") &
                          deact_date <= as.Date("2024-12-31")]
cat("Deactivated CWS (2006-2024, with ZIP):", nrow(deactivated), "\n")

# Active systems with valid ZIP
active_sys <- systems[active == TRUE & nchar(zip5) == 5]
cat("Active CWS (with ZIP):", nrow(active_sys), "\n")

# Treatment: for each deactivated system's ZIP, find the deactivation event
zip_events <- deactivated[, .(
  n_deactivated = .N,
  first_deact_date = min(deact_date),
  total_pop_deactivated = sum(pop_served, na.rm = TRUE)
), by = zip5]

cat("ZIPs with deactivation events:", nrow(zip_events), "\n")

# Merge treatment info onto active systems
active_panel <- merge(active_sys, zip_events, by = "zip5", all.x = TRUE)
active_panel[, treated := !is.na(first_deact_date)]

cat("\nTreatment summary:\n")
cat("  Treated active CWS:", sum(active_panel$treated), "\n")
cat("  Never-treated active CWS:", sum(!active_panel$treated), "\n")

# ============================================================================
# 4. Clean violations and construct quarterly panel
# ============================================================================
cat("\n=== Constructing quarterly violation panel ===\n")

# Parse violation dates: format "YYYY-MM-DD HH:MM:SS"
violations[, viol_date := as.Date(substr(compl_per_begin_date, 1, 10))]
violations[, viol_year := year(viol_date)]
violations[, viol_qtr_num := quarter(viol_date)]
violations[, qtr := paste0(viol_year, "Q", viol_qtr_num)]

# Filter to 2005-2024 (include 2005 for pre-treatment periods)
violations <- violations[!is.na(viol_year) & viol_year >= 2005 & viol_year <= 2024]
cat("Violations after date filter:", nrow(violations), "\n")

# Count health-based violations per system-quarter
viol_counts <- violations[, .(
  n_health_viols = .N
), by = .(pwsid, qtr)]

# ============================================================================
# 5. Build balanced panel: system × quarter
# ============================================================================
cat("Building system-quarter panel...\n")

# Generate all quarters 2005Q1 to 2024Q4
all_qtrs <- data.table(expand.grid(
  year = 2005:2024,
  q = 1:4,
  stringsAsFactors = FALSE
))
all_qtrs[, qtr := paste0(year, "Q", q)]
setorder(all_qtrs, year, q)
all_qtrs[, qtr_idx := .I]

# Cross join: all active systems × all quarters
panel <- CJ(
  pwsid = active_panel$pwsid,
  qtr = all_qtrs$qtr
)

# Merge system info
panel <- merge(panel, active_panel[, .(pwsid, zip5, state, pop_served,
                                        treated, first_deact_date,
                                        n_deactivated, total_pop_deactivated)],
               by = "pwsid", all.x = TRUE)

# Merge quarter index
panel <- merge(panel, all_qtrs[, .(qtr, qtr_idx)], by = "qtr", all.x = TRUE)

# Merge violations
panel <- merge(panel, viol_counts, by = c("pwsid", "qtr"), all.x = TRUE)
panel[is.na(n_health_viols), n_health_viols := 0]

# Binary violation indicator
panel[, has_violation := as.integer(n_health_viols > 0)]

# Treatment timing: quarter index of first deactivation
panel[treated == TRUE, treat_qtr := paste0(year(first_deact_date), "Q",
                                            quarter(first_deact_date))]
treat_map <- unique(all_qtrs[, .(qtr, qtr_idx)])
setnames(treat_map, c("treat_qtr", "first_treat_idx"))
panel <- merge(panel, treat_map, by.x = "treat_qtr", by.y = "treat_qtr",
               all.x = TRUE)

# Never-treated: set first_treat to 0
panel[is.na(first_treat_idx), first_treat_idx := 0L]

# Post-treatment indicator
panel[, post := as.integer(first_treat_idx > 0 & qtr_idx >= first_treat_idx)]

cat("\nPanel dimensions:", nrow(panel), "rows\n")
cat("Unique systems:", uniqueN(panel$pwsid), "\n")
cat("Unique quarters:", uniqueN(panel$qtr), "\n")
cat("Treated systems:", uniqueN(panel$pwsid[panel$treated == TRUE]), "\n")
cat("Mean violation rate:", round(mean(panel$has_violation), 4), "\n")

# ============================================================================
# 6. Sample restrictions
# ============================================================================
cat("\n=== Applying sample restrictions ===\n")

# Require treated systems to have >= 8 pre-treatment quarters
panel[, n_pre := fifelse(first_treat_idx > 0,
                          as.integer(sum(qtr_idx < first_treat_idx)),
                          999L),
      by = pwsid]

# Keep all never-treated + treated with 8+ pre periods
panel_clean <- panel[n_pre >= 8]

# Drop zero-population systems
panel_clean <- panel_clean[!is.na(pop_served) & pop_served > 0]

# Focus on 2006Q1-2024Q4
qtr_2006q1 <- all_qtrs[year == 2006 & q == 1, qtr_idx]
qtr_2024q4 <- all_qtrs[year == 2024 & q == 4, qtr_idx]
panel_clean <- panel_clean[qtr_idx >= qtr_2006q1 & qtr_idx <= qtr_2024q4]

cat("Panel after restrictions:", nrow(panel_clean), "rows\n")
cat("Systems after restrictions:", uniqueN(panel_clean$pwsid), "\n")
cat("Treated systems after restrictions:",
    uniqueN(panel_clean$pwsid[panel_clean$treated == TRUE]), "\n")
cat("Never-treated systems:",
    uniqueN(panel_clean$pwsid[panel_clean$treated == FALSE]), "\n")

# ============================================================================
# 7. Save analysis dataset
# ============================================================================
fwrite(panel_clean, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis_panel.csv\n")

# Summary statistics
sumstats <- panel_clean[, .(
  mean_viols = mean(n_health_viols),
  sd_viols = sd(n_health_viols),
  mean_has_viol = mean(has_violation),
  sd_has_viol = sd(has_violation),
  mean_pop = mean(pop_served, na.rm = TRUE),
  sd_pop = sd(pop_served, na.rm = TRUE),
  n_systems = uniqueN(pwsid),
  n_treated = uniqueN(pwsid[treated == TRUE]),
  n_control = uniqueN(pwsid[treated == FALSE]),
  n_obs = .N,
  n_qtrs = uniqueN(qtr)
)]

cat("\n=== Summary Statistics ===\n")
print(sumstats)

write_json(as.list(sumstats), file.path(data_dir, "summary_stats.json"),
           auto_unbox = TRUE)
cat("Saved summary_stats.json\n")
