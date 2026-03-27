## 02_clean_data.R — Construct analysis panel
## apep_1087: Healthcare WVP Mandates and Worker Injuries

source("00_packages.R")

data_dir <- "../data"
osha <- data.table::fread(file.path(data_dir, "osha_ita_combined.csv"))

cat("Raw data:", nrow(osha), "rows\n")
cat("Columns:", paste(names(osha), collapse = ", "), "\n")
cat("Sample NAICS codes:", paste(head(unique(osha$naics_code), 20), collapse = ", "), "\n")

## --- Extract 2-digit NAICS ---
osha[, naics2 := substr(as.character(naics_code), 1, 2)]
cat("\n2-digit NAICS distribution:\n")
print(sort(table(osha$naics2), decreasing = TRUE)[1:20])

## --- State standardization ---
## States should be 2-letter abbreviations
## Check what format we have
cat("\nSample state values:", paste(head(unique(osha$state), 10), collapse = ", "), "\n")

## State FIPS crosswalk (for mapping if needed)
state_fips <- data.frame(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                 42,44,45,46,47,48,49,50,51,53,54,55,56),
  stringsAsFactors = FALSE
)

## Merge state abbreviation with FIPS
if (all(nchar(unique(osha$state)) <= 2)) {
  osha[, state_abbr := toupper(trimws(state))]
  osha <- merge(osha, state_fips, by = "state_abbr", all.x = TRUE)
} else {
  ## If state is a number (FIPS), convert
  osha[, state_fips := as.integer(state)]
  osha <- merge(osha, state_fips, by = "state_fips", all.x = TRUE)
}

cat("States with FIPS codes:", sum(!is.na(osha$state_fips)), "/", nrow(osha), "\n")

## --- Treatment assignment ---
## WVP mandate adoption years by state (from legislative research)
## Sources: Health Affairs Scholar (2024), OSHA state plans, state legislature records
## Coding rule: year the mandate TOOK EFFECT (not year of passage)
## States with general OSHA-plan provisions but no healthcare-specific WVP law are NOT treated

wvp_laws <- data.frame(
  state_abbr = c("CT", "CA", "WA", "IL", "MN", "MD",
                 "NJ", "NY", "OR", "MA", "TX",
                 "ME", "CO", "NM", "RI", "NH"),
  wvp_year = c(2012, 2017, 2019, 2020, 2020, 2020,
               2021, 2022, 2022, 2023, 2024,
               2022, 2022, 2023, 2023, 2023),
  stringsAsFactors = FALSE
)

cat("\nWVP mandate states:\n")
print(wvp_laws[order(wvp_laws$wvp_year), ])

## Merge treatment
osha <- merge(osha, wvp_laws, by = "state_abbr", all.x = TRUE)
osha[is.na(wvp_year), wvp_year := 0]  # Never-treated states get 0

## Treatment indicator
osha[, treated := as.integer(year >= wvp_year & wvp_year > 0)]

## --- Construct healthcare indicator ---
osha[, healthcare := as.integer(naics2 == "62")]
cat("\nHealthcare establishments:", sum(osha$healthcare == 1),
    "(", round(100 * mean(osha$healthcare == 1), 1), "%)\n")

## --- Handle missing values in outcomes ---
## Replace NA with 0 for injury counts (establishments with no injuries may report 0 or NA)
outcome_cols <- c("total_injuries", "dafw_cases", "djtr_cases", "deaths")
for (col in outcome_cols) {
  if (col %in% names(osha)) {
    osha[is.na(get(col)), (col) := 0]
  }
}

## Drop establishments with missing employees (can't compute rates)
osha <- osha[!is.na(avg_employees) & avg_employees > 0]
cat("After dropping missing employees:", nrow(osha), "rows\n")

## --- Ensure numeric types ---
osha[, dafw_cases := as.double(dafw_cases)]
osha[, total_injuries := as.double(total_injuries)]
osha[, djtr_cases := as.double(djtr_cases)]
osha[, deaths := as.double(deaths)]
osha[, avg_employees := as.double(avg_employees)]
if ("total_hours" %in% names(osha)) osha[, total_hours := as.double(total_hours)]

## --- Compute injury rates (per 100 FTE) ---
## Standard OSHA rate = (cases × 200,000) / total_hours
## If hours missing, use (cases / avg_employees × 100)
if ("total_hours" %in% names(osha) && sum(!is.na(osha$total_hours) & osha$total_hours > 0) > nrow(osha) * 0.5) {
  osha[total_hours > 0, dafw_rate := (dafw_cases * 200000) / total_hours]
  osha[total_hours > 0, injury_rate := (total_injuries * 200000) / total_hours]
  cat("Using hours-based rates (OSHA standard)\n")
} else {
  osha[, dafw_rate := dafw_cases / avg_employees * 100]
  osha[, injury_rate := total_injuries / avg_employees * 100]
  cat("Using employee-based rates (hours not available)\n")
}

## --- Aggregate to state × year level ---
## Two panels: healthcare (NAICS 62) and non-healthcare (placebo)

state_year_hc <- osha[healthcare == 1, .(
  dafw_cases = sum(dafw_cases, na.rm = TRUE),
  total_injuries = sum(total_injuries, na.rm = TRUE),
  total_employees = sum(avg_employees, na.rm = TRUE),
  n_establishments = .N,
  dafw_rate = sum(dafw_cases, na.rm = TRUE) / sum(avg_employees, na.rm = TRUE) * 100,
  injury_rate = sum(total_injuries, na.rm = TRUE) / sum(avg_employees, na.rm = TRUE) * 100
), by = .(state_abbr, state_fips, year, wvp_year)]

state_year_nonhc <- osha[healthcare == 0, .(
  dafw_cases = sum(dafw_cases, na.rm = TRUE),
  total_injuries = sum(total_injuries, na.rm = TRUE),
  total_employees = sum(avg_employees, na.rm = TRUE),
  n_establishments = .N,
  dafw_rate = sum(dafw_cases, na.rm = TRUE) / sum(avg_employees, na.rm = TRUE) * 100,
  injury_rate = sum(total_injuries, na.rm = TRUE) / sum(avg_employees, na.rm = TRUE) * 100
), by = .(state_abbr, state_fips, year, wvp_year)]

## Add sector label
state_year_hc[, sector := "healthcare"]
state_year_nonhc[, sector := "non_healthcare"]

## Combine for DDD
panel <- rbindlist(list(state_year_hc, state_year_nonhc))

## Treatment indicators
panel[, post := as.integer(year >= wvp_year & wvp_year > 0)]
panel[, hc := as.integer(sector == "healthcare")]

cat("\n=== Panel summary ===\n")
cat("States:", length(unique(panel$state_abbr)), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("State-year-sector obs:", nrow(panel), "\n")
cat("Treated states:", sum(panel$wvp_year > 0 & panel$sector == "healthcare") /
      length(unique(panel$year)), "\n")

## Save panels
data.table::fwrite(state_year_hc, file.path(data_dir, "panel_healthcare.csv"))
data.table::fwrite(panel, file.path(data_dir, "panel_full.csv"))

cat("\n=== Summary statistics: Healthcare panel ===\n")
cat("Mean DAFW rate:", round(mean(state_year_hc$dafw_rate, na.rm = TRUE), 3), "\n")
cat("SD DAFW rate:", round(sd(state_year_hc$dafw_rate, na.rm = TRUE), 3), "\n")
cat("Mean injury rate:", round(mean(state_year_hc$injury_rate, na.rm = TRUE), 3), "\n")
cat("SD injury rate:", round(sd(state_year_hc$injury_rate, na.rm = TRUE), 3), "\n")

## Validate
stopifnot("Panel is empty" = nrow(state_year_hc) > 0)
stopifnot("Too few states" = length(unique(state_year_hc$state_abbr)) >= 30)
stopifnot("Too few years" = length(unique(state_year_hc$year)) >= 5)

cat("\n=== Data cleaning complete ===\n")
