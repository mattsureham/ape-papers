## 02_clean_data.R — Construct treatment indicators and analysis variables
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

# ============================================================
# Load raw data
# ============================================================

qwi <- fread(file.path(data_dir, "qwi_aggregate.csv"),
             colClasses = c(state = "character"))
qwi_ind <- fread(file.path(data_dir, "qwi_industry.csv"),
                 colClasses = c(state = "character"))

# Ensure state has leading zeros (2-digit FIPS)
qwi[, state := sprintf("%02s", state)]
qwi_ind[, state := sprintf("%02s", state)]

# ============================================================
# Treatment coding: Salary History Ban effective dates
# ============================================================

# State FIPS -> treatment quarter mapping (private employer bans)
ban_dates <- data.table(
  state = c("41", "10", "11", "06", "25", "50", "09", "15",
            "17", "23", "53", "01", "34", "36", "51", "24",
            "08", "32", "44", "27"),
  state_name = c("Oregon", "Delaware", "DC", "California",
                 "Massachusetts", "Vermont", "Connecticut", "Hawaii",
                 "Illinois", "Maine", "Washington", "Alabama",
                 "New Jersey", "New York", "Virginia", "Maryland",
                 "Colorado", "Nevada", "Rhode Island", "Minnesota"),
  ban_quarter = c("2017-Q4", "2017-Q4", "2017-Q4", "2018-Q1",
                  "2018-Q3", "2018-Q3", "2019-Q1", "2019-Q1",
                  "2019-Q4", "2019-Q4", "2019-Q3", "2019-Q3",
                  "2019-Q4", "2020-Q1", "2020-Q3", "2020-Q4",
                  "2021-Q1", "2021-Q4", "2023-Q1", "2024-Q1")
)

# Convert quarter string to numeric for CS-DiD
quarter_to_num <- function(q) {
  parts <- strsplit(q, "-Q")
  sapply(parts, function(p) (as.integer(p[1]) - 2010) * 4 + as.integer(p[2]))
}

ban_dates[, ban_period := quarter_to_num(ban_quarter)]

# ============================================================
# Process aggregate data
# ============================================================

# Create numeric time period
qwi[, period := quarter_to_num(time)]

# Merge treatment info
qwi <- merge(qwi, ban_dates[, .(state, ban_period)],
             by = "state", all.x = TRUE)

# Treatment indicator
qwi[, treated := !is.na(ban_period)]
qwi[, post := fifelse(treated & period >= ban_period, 1L, 0L)]

# Group variable for CS-DiD (treatment cohort = ban_period, 0 for never-treated)
qwi[, cohort := fifelse(treated, ban_period, 0L)]

# ============================================================
# Construct gender outcomes (state x quarter level)
# ============================================================

# Reshape to wide by sex
agg_wide <- dcast(qwi, state + time + period + treated + post + cohort + ban_period ~
                    paste0("sex", sex),
                  value.var = c("EarnS", "EarnHirNS", "EarnBeg", "Emp",
                                "HirN", "HirNs", "Sep"),
                  fun.aggregate = function(x) x[1])

# Gender earnings ratios (female / male)
agg_wide[, earn_ratio_s := EarnS_sex2 / EarnS_sex1]       # Continuing workers
agg_wide[, earn_ratio_hir := EarnHirNS_sex2 / EarnHirNS_sex1]  # New hires
agg_wide[, earn_ratio_beg := EarnBeg_sex2 / EarnBeg_sex1]  # All workers (BoQ)

# Log ratios
agg_wide[, log_ratio_s := log(earn_ratio_s)]
agg_wide[, log_ratio_hir := log(earn_ratio_hir)]
agg_wide[, log_ratio_beg := log(earn_ratio_beg)]

# Female share of new hires
agg_wide[, female_hire_share := HirN_sex2 / (HirN_sex1 + HirN_sex2)]

# Female share of employment
agg_wide[, female_emp_share := Emp_sex2 / (Emp_sex1 + Emp_sex2)]

# Total employment
agg_wide[, total_emp := Emp_sex1 + Emp_sex2]

# Log earnings by sex (for separate regressions)
agg_wide[, log_earn_f_hir := log(EarnHirNS_sex2)]
agg_wide[, log_earn_m_hir := log(EarnHirNS_sex1)]
agg_wide[, log_earn_f_s := log(EarnS_sex2)]
agg_wide[, log_earn_m_s := log(EarnS_sex1)]

# Drop rows with missing key variables
agg_wide <- agg_wide[!is.na(log_ratio_hir) & is.finite(log_ratio_hir)]

# Year and quarter variables for FE
agg_wide[, year := 2010 + (period - 1) %/% 4]
agg_wide[, qtr := ((period - 1) %% 4) + 1]

# ============================================================
# Process industry data
# ============================================================

qwi_ind[, period := quarter_to_num(time)]
qwi_ind <- merge(qwi_ind, ban_dates[, .(state, ban_period)],
                 by = "state", all.x = TRUE)
qwi_ind[, treated := !is.na(ban_period)]
qwi_ind[, post := fifelse(treated & period >= ban_period, 1L, 0L)]
qwi_ind[, cohort := fifelse(treated, ban_period, 0L)]

# Reshape industry data to wide by sex
ind_wide <- dcast(qwi_ind, state + time + period + treated + post + cohort +
                    ban_period + industry ~
                    paste0("sex", sex),
                  value.var = c("EarnS", "EarnHirNS", "Emp", "HirN"),
                  fun.aggregate = function(x) x[1])

ind_wide[, earn_ratio_s := EarnS_sex2 / EarnS_sex1]
ind_wide[, earn_ratio_hir := EarnHirNS_sex2 / EarnHirNS_sex1]
ind_wide[, log_ratio_hir := log(earn_ratio_hir)]
ind_wide[, log_ratio_s := log(earn_ratio_s)]
ind_wide[, female_hire_share := HirN_sex2 / (HirN_sex1 + HirN_sex2)]
ind_wide[, total_emp := Emp_sex1 + Emp_sex2]

ind_wide <- ind_wide[!is.na(log_ratio_hir) & is.finite(log_ratio_hir)]

ind_wide[, year := 2010 + (period - 1) %/% 4]
ind_wide[, qtr := ((period - 1) %% 4) + 1]

# Classify industries by gender composition
# Male-dominated: Construction (23), Mining (21), Transportation (48-49)
# Female-dominated: Healthcare (62), Education (61), Accommodation (72)
# High-wage: Finance (52), Professional Services (54), Information (51)
# Low-wage: Retail (44-45), Accommodation (72), Food service

ind_wide[, male_dominated := industry %in% c("23", "21", "48-49", "31-33", "22")]
ind_wide[, female_dominated := industry %in% c("62", "61", "72")]
ind_wide[, high_wage := industry %in% c("52", "54", "51", "55")]

# ============================================================
# Save cleaned data
# ============================================================

fwrite(agg_wide, file.path(data_dir, "analysis_aggregate.csv"))
fwrite(ind_wide, file.path(data_dir, "analysis_industry.csv"))

# Summary stats
cat("\n=== Aggregate Data Summary ===\n")
cat(sprintf("States: %d (treated: %d, control: %d)\n",
            uniqueN(agg_wide$state),
            uniqueN(agg_wide[treated == TRUE]$state),
            uniqueN(agg_wide[treated == FALSE]$state)))
cat(sprintf("Quarters: %d (%s to %s)\n",
            uniqueN(agg_wide$time),
            min(agg_wide$time), max(agg_wide$time)))
cat(sprintf("Observations: %d\n", nrow(agg_wide)))
cat(sprintf("\nMean gender earnings ratio (new hires): %.3f\n",
            mean(agg_wide$earn_ratio_hir, na.rm = TRUE)))
cat(sprintf("Mean gender earnings ratio (continuing): %.3f\n",
            mean(agg_wide$earn_ratio_s, na.rm = TRUE)))
cat(sprintf("Mean female hire share: %.3f\n",
            mean(agg_wide$female_hire_share, na.rm = TRUE)))

cat("\n=== Industry Data Summary ===\n")
cat(sprintf("Industries: %d\n", uniqueN(ind_wide$industry)))
cat(sprintf("Observations: %d\n", nrow(ind_wide)))
