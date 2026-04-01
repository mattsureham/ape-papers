# =============================================================================
# 02_clean_data.R — Construct analysis panels
# =============================================================================

source("00_packages.R")

qwi_sa <- readRDS("../data/qwi_sa_raw.rds")
qwi_rh <- readRDS("../data/qwi_rh_raw.rds")
mandate_states <- readRDS("../data/mandate_states.rds")

setDT(qwi_sa)
setDT(qwi_rh)

# -----------------------------------------------------------------------
# 1. Create state FIPS from county FIPS
# -----------------------------------------------------------------------
qwi_sa[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_sa[, state_fips := substr(county_fips, 1, 2)]

qwi_rh[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_rh[, state_fips := substr(county_fips, 1, 2)]

# -----------------------------------------------------------------------
# 2. Create time variables
# -----------------------------------------------------------------------
# Calendar quarter index (2015Q1 = 1)
qwi_sa[, qtr := (year - 2015L) * 4L + quarter]
qwi_rh[, qtr := (year - 2015L) * 4L + quarter]

# Create a date-like label for quarters
qwi_sa[, yq := paste0(year, "Q", quarter)]
qwi_rh[, yq := paste0(year, "Q", quarter)]

# -----------------------------------------------------------------------
# 3. Merge mandate treatment status
# -----------------------------------------------------------------------
# State-level mandate indicator
qwi_sa <- merge(qwi_sa, mandate_states[, .(state_fips, mandate_qtr)],
                by = "state_fips", all.x = TRUE)
qwi_sa[is.na(mandate_qtr), mandate_qtr := 0L]  # 0 = no state mandate (only CMS)
qwi_sa[, has_state_mandate := as.integer(mandate_qtr > 0)]

qwi_rh <- merge(qwi_rh, mandate_states[, .(state_fips, mandate_qtr)],
                by = "state_fips", all.x = TRUE)
qwi_rh[is.na(mandate_qtr), mandate_qtr := 0L]
qwi_rh[, has_state_mandate := as.integer(mandate_qtr > 0)]

# Post-mandate indicator (relative to state's own mandate quarter, or 2022Q1 for CMS-only states)
# For CS-DiD: treatment group = mandate_qtr for early states, never-treated = 0
qwi_sa[, post_mandate := as.integer(
  (has_state_mandate == 1 & qtr >= mandate_qtr) |
  (has_state_mandate == 0 & qtr >= 29L)  # 2022Q1 = CMS mandate
)]

qwi_rh[, post_mandate := as.integer(
  (has_state_mandate == 1 & qtr >= mandate_qtr) |
  (has_state_mandate == 0 & qtr >= 29L)
)]

# -----------------------------------------------------------------------
# 4. Create sector indicator
# -----------------------------------------------------------------------
qwi_sa[, naics623 := as.integer(industry == "623")]
qwi_rh[, naics623 := as.integer(industry == "623")]

# -----------------------------------------------------------------------
# 5. Aggregate to county-quarter-sector level (pooled demographics)
# -----------------------------------------------------------------------
# Panel A: Pooled employment by county × quarter × sector
panel_pooled <- qwi_sa[, .(
  emp = sum(Emp, na.rm = TRUE),
  hires = sum(HirA, na.rm = TRUE),
  seps = sum(Sep, na.rm = TRUE),
  earn = weighted.mean(EarnS, w = pmax(Emp, 1, na.rm = TRUE), na.rm = TRUE)
), by = .(county_fips, state_fips, year, quarter, qtr, yq,
          industry, naics623, has_state_mandate, mandate_qtr, post_mandate)]

# Drop cells with zero employment
panel_pooled <- panel_pooled[emp > 0]

cat(sprintf("Pooled panel: %s rows, %d counties\n",
            format(nrow(panel_pooled), big.mark = ","),
            uniqueN(panel_pooled$county_fips)))

# -----------------------------------------------------------------------
# 6. Create age-specific panels for demographic decomposition
# -----------------------------------------------------------------------
# Map QWI age groups to broader categories
age_map <- data.table(
  agegrp = c("A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08"),
  age_label = c("14-18", "19-21", "22-24", "25-34", "35-44", "45-54", "55-64", "65+"),
  age_broad = c("Under25", "Under25", "Under25", "25-34", "35-44", "45-54", "55+", "55+")
)

qwi_sa <- merge(qwi_sa, age_map, by = "agegrp", all.x = TRUE)

panel_age <- qwi_sa[!is.na(age_broad), .(
  emp = sum(Emp, na.rm = TRUE),
  hires = sum(HirA, na.rm = TRUE),
  seps = sum(Sep, na.rm = TRUE),
  earn = weighted.mean(EarnS, w = pmax(Emp, 1, na.rm = TRUE), na.rm = TRUE)
), by = .(county_fips, state_fips, year, quarter, qtr, yq,
          industry, naics623, has_state_mandate, mandate_qtr, post_mandate,
          age_broad)]

panel_age <- panel_age[emp > 0]

cat(sprintf("Age panel: %s rows\n", format(nrow(panel_age), big.mark = ",")))

# -----------------------------------------------------------------------
# 7. Create race-specific panel for demographic decomposition
# -----------------------------------------------------------------------
# Map QWI race codes
race_map <- data.table(
  race = c("A1", "A2", "A3", "A4", "A5", "A6", "A7"),
  race_label = c("White", "Black", "AIAN", "Asian", "NHPI", "TwoOrMore", "Other")
)

qwi_rh <- merge(qwi_rh, race_map, by = "race", all.x = TRUE)

# Focus on White and Black (largest groups in NAICS 623)
panel_race <- qwi_rh[race_label %in% c("White", "Black"), .(
  emp = sum(Emp, na.rm = TRUE),
  hires = sum(HirA, na.rm = TRUE),
  seps = sum(Sep, na.rm = TRUE),
  earn = weighted.mean(EarnS, w = pmax(Emp, 1, na.rm = TRUE), na.rm = TRUE)
), by = .(county_fips, state_fips, year, quarter, qtr, yq,
          industry, naics623, has_state_mandate, mandate_qtr, post_mandate,
          race_label)]

panel_race <- panel_race[emp > 0]

cat(sprintf("Race panel: %s rows\n", format(nrow(panel_race), big.mark = ",")))

# -----------------------------------------------------------------------
# 8. Create county-sector fixed effects and log outcomes
# -----------------------------------------------------------------------
for (dt in list(panel_pooled, panel_age, panel_race)) {
  dt[, cs_id := paste0(county_fips, "_", industry)]
  dt[, log_emp := log(emp + 1)]
  dt[, log_earn := log(earn + 1)]
  dt[, sep_rate := seps / emp]
  dt[, hire_rate := hires / emp]
}

# -----------------------------------------------------------------------
# 9. Restrict to balanced panel (counties present in all quarters)
# -----------------------------------------------------------------------
# Count quarters per county-sector
qtr_counts <- panel_pooled[, .N, by = .(county_fips, industry)]
max_qtrs <- panel_pooled[, uniqueN(qtr)]
balanced_ids <- qtr_counts[N >= max_qtrs * 0.9, paste0(county_fips, "_", industry)]

panel_pooled_bal <- panel_pooled[cs_id %in% balanced_ids]
cat(sprintf("Balanced pooled panel: %s rows (%d county-sectors, 90%% threshold)\n",
            format(nrow(panel_pooled_bal), big.mark = ","),
            uniqueN(panel_pooled_bal$cs_id)))

# -----------------------------------------------------------------------
# 10. Pre-treatment summary statistics for SDE table
# -----------------------------------------------------------------------
pre_stats <- panel_pooled[qtr < 27, .(  # Pre 2021Q3
  mean_emp = mean(emp, na.rm = TRUE),
  sd_emp = sd(emp, na.rm = TRUE),
  mean_log_emp = mean(log_emp, na.rm = TRUE),
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  mean_earn = mean(earn, na.rm = TRUE),
  sd_earn = sd(earn, na.rm = TRUE),
  mean_sep_rate = mean(sep_rate, na.rm = TRUE),
  sd_sep_rate = sd(sep_rate, na.rm = TRUE),
  n_obs = .N
), by = .(industry)]

cat("\nPre-treatment summary (by sector):\n")
print(pre_stats)

# -----------------------------------------------------------------------
# 11. Save analysis panels
# -----------------------------------------------------------------------
saveRDS(panel_pooled, "../data/panel_pooled.rds")
saveRDS(panel_pooled_bal, "../data/panel_pooled_bal.rds")
saveRDS(panel_age, "../data/panel_age.rds")
saveRDS(panel_race, "../data/panel_race.rds")
saveRDS(pre_stats, "../data/pre_stats.rds")

cat("\nAll panels saved.\n")
