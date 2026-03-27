# 02_clean_data.R — Construct analysis panel
# apep_1077: Child Labor Law Rollbacks DDD

source("00_packages.R")

dt <- fread("../data/qwi_raw.csv")
cat(sprintf("Loaded %s rows.\n", format(nrow(dt), big.mark = ",")))

# --- State FIPS mapping ---
# Extract state FIPS from county FIPS (first 1-2 digits, county FIPS is 4-5 digits)
dt[, state_fips := as.integer(fips %/% 1000)]

# State FIPS to state abbreviation (all 50 + DC)
state_map <- data.table(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
                 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,
                 47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
                 "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN",
                 "MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH",
                 "OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
                 "WV","WI","WY")
)
dt <- merge(dt, state_map, by = "state_fips", all.x = TRUE)
dt <- dt[!is.na(state_abbr)]

# --- Treatment coding ---
# States that weakened child labor protections, with effective quarter
# Sources: EPI, NCSL compilations
treatment <- data.table(
  state_abbr = c("NH", "NJ", "IA", "AR", "TN", "AL", "FL", "IN", "KY", "WV",
                 "OH", "MO"),
  treat_year = c(2022, 2022, 2023, 2023, 2023, 2024, 2024, 2024, 2024, 2024,
                 2024, 2024),
  treat_quarter = c(3, 1, 3, 3, 3, 1, 3, 3, 3, 3, 1, 1)
)

# Create treatment period (year-quarter as numeric: 2022Q3 = 2022.75)
treatment[, treat_yq := treat_year + (treat_quarter - 1) / 4]

dt <- merge(dt, treatment, by = "state_abbr", all.x = TRUE)
dt[is.na(treat_year), treat_year := 0]
dt[is.na(treat_yq), treat_yq := 0]

# Time variable
dt[, yq := year + (quarter - 1) / 4]

# Binary treatment indicators
dt[, treated_state := as.integer(treat_year > 0)]
dt[, post := as.integer(treat_yq > 0 & yq >= treat_yq)]
dt[, teen := as.integer(agegrp == "A01")]
dt[, food_retail := as.integer(industry %in% c("72", "44-45"))]

# Cohort variable for CS estimator (0 = never-treated)
dt[, cohort_yq := fifelse(treated_state == 1, treat_yq, 0)]

# --- Aggregate to state-quarter-industry-age level ---
# Some counties have suppressed cells (NA emp). Aggregate at state level for power.
panel <- dt[, .(
  emp = sum(emp, na.rm = TRUE),
  hires = sum(hires, na.rm = TRUE),
  separations = sum(separations, na.rm = TRUE),
  earnings = weighted.mean(earnings, emp, na.rm = TRUE),
  n_counties = .N
), by = .(state_fips, state_abbr, industry, agegrp, year, quarter, yq,
          treated_state, post, teen, food_retail, cohort_yq, treat_yq)]

# Log employment (main outcome)
panel[, log_emp := log(emp + 1)]

# Employment share (teen share of employment)
panel[, emp_share := emp / sum(emp), by = .(state_fips, industry, year, quarter)]

# Separation rate
panel[, sep_rate := separations / (emp + 1)]

# --- Panel identifiers ---
# Unique panel ID for state x industry x age
panel[, panel_id := paste(state_fips, industry, agegrp, sep = "_")]

# Integer time period (quarters since 2018Q1)
panel[, time_period := as.integer((year - 2018) * 4 + quarter)]

# --- Summary statistics ---
cat("\n--- Panel Summary ---\n")
cat(sprintf("States: %d\n", uniqueN(panel$state_fips)))
cat(sprintf("Treated states: %d\n", uniqueN(panel[treated_state == 1]$state_abbr)))
cat(sprintf("Control states: %d\n", uniqueN(panel[treated_state == 0]$state_abbr)))
cat(sprintf("Treated state list: %s\n", paste(sort(unique(panel[treated_state == 1]$state_abbr)), collapse = ", ")))
cat(sprintf("Industries: %s\n", paste(unique(panel$industry), collapse = ", ")))
cat(sprintf("Age groups: %s\n", paste(unique(panel$agegrp), collapse = ", ")))
cat(sprintf("Quarters: %d-%d (%d total)\n", min(panel$time_period), max(panel$time_period),
            uniqueN(panel$time_period)))
cat(sprintf("Panel rows: %s\n", format(nrow(panel), big.mark = ",")))

# Mean employment by group
cat("\n--- Mean Employment by Group ---\n")
print(panel[, .(mean_emp = mean(emp, na.rm = TRUE),
                sd_emp = sd(emp, na.rm = TRUE)),
            by = .(teen, food_retail, treated_state)])

# --- Save ---
fwrite(panel, "../data/analysis_panel.csv")
cat("\nSaved analysis panel to data/analysis_panel.csv\n")
