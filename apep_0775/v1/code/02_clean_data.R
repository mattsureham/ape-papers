## =============================================================================
## 02_clean_data.R — Clean QWI data and construct analysis panel
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

source("00_packages.R")

cat("=== Cleaning QWI data ===\n")

df <- fread("../data/qwi_raw.csv")
treat <- fread("../data/treatment_states.csv")
ctrl  <- fread("../data/control_states.csv")

cat(sprintf("Raw data: %s rows\n", format(nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 1. Extract state FIPS, create time variable
## -----------------------------------------------------------------------------
df[, state_fips := substr(geography, 1, 2)]
df[, county_fips := geography]
df[, yq := year * 10 + quarter]  # year-quarter for sorting

## FIPS to abbreviation mapping (build from treatment + control)
fips_map <- rbind(
  treat[, .(state_fips, state_abbr)],
  ctrl[, .(state_fips, state_abbr)]
)

## Ensure consistent types
fips_map[, state_fips := as.character(state_fips)]
treat[, state_fips := as.character(state_fips)]
ctrl[, state_fips := as.character(state_fips)]

## Some states in QWI data may not be in our treatment/control list
## (DC, territories). Keep only states of interest.
df <- df[state_fips %in% fips_map$state_fips]
df <- merge(df, fips_map, by = "state_fips", all.x = TRUE)

## -----------------------------------------------------------------------------
## 2. Assign treatment status
## -----------------------------------------------------------------------------
## Treated = 18 states that rolled back ban 2015-2019
## Control = 30 states that opted out pre-2010 (always allowed)
df[, treated_state := as.integer(state_fips %in% treat$state_fips)]

## Merge treatment timing for treated states
df <- merge(df, treat[, .(state_fips, treat_year, treat_quarter, treat_yq, ban_type)],
            by = "state_fips", all.x = TRUE)

## For control states, set treat_year = 0 (never treated)
df[is.na(treat_year), treat_year := 0L]
df[is.na(treat_yq), treat_yq := 0L]

## Post-treatment indicator (for treated states only)
df[, post := as.integer(treated_state == 1 & yq >= treat_yq)]

## -----------------------------------------------------------------------------
## 3. Create education group indicators
## -----------------------------------------------------------------------------
## E1 = Less than high school, E2 = High school/GED
## E3 = Some college, E4 = Bachelor's+
df[, low_ed := as.integer(education %in% c("E1", "E2"))]

cat("\nEducation × treatment distribution:\n")
print(df[, .N, by = .(education, treated_state)][order(education, treated_state)])

## -----------------------------------------------------------------------------
## 4. Convert numeric columns, handle missing
## -----------------------------------------------------------------------------
num_cols <- c("Emp", "EmpEnd", "EmpS", "HirA", "HirN", "Sep",
              "EarnS", "EarnBeg")
for (col in num_cols) {
  df[[col]] <- as.numeric(df[[col]])
}

## Drop rows with missing employment (QWI suppression)
n_before <- nrow(df)
df <- df[!is.na(Emp) & Emp > 0]
cat(sprintf("\nDropped %s rows with missing/zero Emp\n",
            format(n_before - nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 5. Aggregate to state × quarter × education level
##    (county-level has too much suppression for county FE + triple-diff)
## -----------------------------------------------------------------------------
state_panel <- df[, .(
  emp       = sum(Emp, na.rm = TRUE),
  emp_end   = sum(EmpEnd, na.rm = TRUE),
  hires     = sum(HirA, na.rm = TRUE),
  new_hires = sum(HirN, na.rm = TRUE),
  sep       = sum(Sep, na.rm = TRUE),
  earn_s    = sum(EarnS, na.rm = TRUE),
  n_counties = uniqueN(county_fips)
), by = .(state_fips, state_abbr, year, quarter, yq,
          education, low_ed, treated_state, treat_year, treat_yq,
          ban_type, post)]

## Log employment
state_panel[, log_emp := log(emp)]
state_panel[, log_hires := log(hires + 1)]
state_panel[, log_earn := log(earn_s / emp)]  # avg earnings

## Compute average earnings per worker
state_panel[, avg_earn := earn_s / emp]

cat(sprintf("\nState-quarter-education panel: %s rows\n",
            format(nrow(state_panel), big.mark = ",")))
cat(sprintf("States: %d, Quarters: %d, Education groups: %d\n",
            uniqueN(state_panel$state_fips),
            uniqueN(state_panel$yq),
            uniqueN(state_panel$education)))

## Summary statistics by treatment/education
cat("\n=== Summary Statistics ===\n")
summ <- state_panel[, .(
  mean_emp = mean(emp, na.rm = TRUE),
  sd_emp = sd(emp, na.rm = TRUE),
  mean_hires = mean(hires, na.rm = TRUE),
  mean_earn = mean(avg_earn, na.rm = TRUE),
  n = .N
), by = .(treated_state, low_ed)][order(treated_state, low_ed)]
print(summ)

## Save
fwrite(state_panel, "../data/state_panel.csv")
cat(sprintf("\nSaved: state_panel.csv (%s rows)\n",
            format(nrow(state_panel), big.mark = ",")))
