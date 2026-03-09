## =============================================================================
## 02_clean_data.R — Construct Analysis Variables
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"

## ---------------------------------------------------------------------------
## A. Process Judge-Court Assignments → Court-Level Leniency Instrument
## ---------------------------------------------------------------------------

cat("Processing judge-court assignment data...\n")

# Load scraped judge-court assignments (from OpenImmigration)
jca <- fread(file.path(data_dir, "judge_court_assignments.csv"))
cat("Judge-court assignments:", nrow(jca), "rows\n")
cat("Unique judges:", n_distinct(jca$judge_slug), "\n")

# Create combined court_city_state if needed
if (!"court_city_state" %in% names(jca) && "court_name" %in% names(jca)) {
  jca[, court_city := court_name]
  jca[, court_city_state := paste0(court_name, ", ", court_state)]
}
cat("Unique courts:", n_distinct(jca$court_city_state), "\n")

# Validate: we need judges with positive hearings and valid grant rates
jca <- jca[court_hearings > 0 & !is.na(judge_grant_rate)]

# Step 1: Compute court-level average judge leniency
# Instrument = caseload-weighted average grant rate of judges at each court
# This captures the composition of the judge pool (exogenous to local economy)

# Leave-one-out at the court level: for each judge at a court,
# the court leniency excludes that judge's own cases
court_stats <- jca[, {
  n_judges <- .N
  total_hearings <- sum(court_hearings)

  # For each judge, compute leave-one-out court leniency
  if (n_judges >= 2) {
    loo_vals <- sapply(1:.N, function(i) {
      other_grants <- sum(judge_grant_rate[-i] / 100 * court_hearings[-i])
      other_hearings <- sum(court_hearings[-i])
      other_grants / other_hearings
    })
    avg_loo_leniency <- weighted.mean(loo_vals, w = court_hearings)
  } else {
    avg_loo_leniency <- NA_real_
  }

  # Simple weighted mean leniency
  simple_leniency <- weighted.mean(judge_grant_rate / 100, w = court_hearings)

  # Leniency dispersion (SD of judge grant rates within court)
  if (n_judges >= 2) {
    leniency_sd <- sqrt(sum(court_hearings / total_hearings *
                             (judge_grant_rate / 100 - simple_leniency)^2))
  } else {
    leniency_sd <- NA_real_
  }

  list(
    avg_judge_leniency = simple_leniency,
    loo_leniency = avg_loo_leniency,
    leniency_sd = leniency_sd,
    n_judges = n_judges,
    total_hearings = total_hearings,
    min_judge_rate = min(judge_grant_rate) / 100,
    max_judge_rate = max(judge_grant_rate) / 100
  )
}, by = .(court_city, court_state)]

cat("\nCourt-level leniency statistics:\n")
cat("  Courts:", nrow(court_stats), "\n")
cat("  Courts with 2+ judges:", sum(court_stats$n_judges >= 2), "\n")
cat("  Mean leniency:", round(mean(court_stats$avg_judge_leniency, na.rm = TRUE), 3), "\n")
cat("  SD leniency:", round(sd(court_stats$avg_judge_leniency, na.rm = TRUE), 3), "\n")
cat("  Range:", round(range(court_stats$avg_judge_leniency, na.rm = TRUE), 3), "\n")

# Require at least 2 judges for valid instrument
court_stats <- court_stats[n_judges >= 2]

## ---------------------------------------------------------------------------
## B. Load Court-Level Statistics from OpenImmigration
## ---------------------------------------------------------------------------

cat("\nLoading court-level statistics...\n")

court_index <- fromJSON(file.path(data_dir, "court_index.json"))
court_index <- as.data.table(court_index)

# Clean city names for merging
court_index[, court_city := tools::toTitleCase(tolower(city))]
# Fix specific cases
court_index[court_city == "Immigration Court", court_city := tools::toTitleCase(tolower(name))]

# Court-level grant rates and caseloads from the aggregate data
court_agg <- court_index[, .(
  court_code = code,
  court_city,
  court_state = state,
  total_cases_court = cases,
  total_completed = completed,
  court_grants = grants,
  court_denials = denials,
  court_removals = removals,
  court_grant_rate = grantRate / 100,
  court_slug = slug
)]

cat("Courts from index:", nrow(court_agg), "\n")

## ---------------------------------------------------------------------------
## C. Merge Court Statistics with Judge Leniency
## ---------------------------------------------------------------------------

cat("\nMerging court stats with judge leniency...\n")

# Merge on city + state
court_panel <- merge(court_agg, court_stats,
                     by = c("court_city", "court_state"), all.x = TRUE)

cat("Merged courts:", sum(!is.na(court_panel$avg_judge_leniency)), "of",
    nrow(court_panel), "\n")

# For unmatched, try city-only merge
unmatched <- court_panel[is.na(avg_judge_leniency)]
if (nrow(unmatched) > 0) {
  cat("Unmatched courts:", paste(head(unmatched$court_city, 10), collapse = ", "), "\n")
  # Try fuzzy match on city name
  for (i in seq_len(nrow(unmatched))) {
    city <- tolower(unmatched$court_city[i])
    best <- court_stats[, .(
      dist = adist(tolower(court_city), city, ignore.case = TRUE)[,1],
      court_city, court_state, avg_judge_leniency, loo_leniency,
      leniency_sd, n_judges, total_hearings, min_judge_rate, max_judge_rate
    )]
    best <- best[dist <= 3][order(dist)]
    if (nrow(best) > 0) {
      idx <- which(court_panel$court_city == unmatched$court_city[i] &
                     court_panel$court_state == unmatched$court_state[i])
      if (length(idx) == 1) {
        court_panel[idx, `:=`(
          avg_judge_leniency = best$avg_judge_leniency[1],
          loo_leniency = best$loo_leniency[1],
          leniency_sd = best$leniency_sd[1],
          n_judges = best$n_judges[1],
          total_hearings = best$total_hearings[1],
          min_judge_rate = best$min_judge_rate[1],
          max_judge_rate = best$max_judge_rate[1]
        )]
      }
    }
  }
  cat("After fuzzy matching:", sum(!is.na(court_panel$avg_judge_leniency)),
      "courts with leniency\n")
}

# Keep only courts with valid leniency
court_panel <- court_panel[!is.na(avg_judge_leniency)]

## ---------------------------------------------------------------------------
## D. Map Courts to Counties via Crosswalk
## ---------------------------------------------------------------------------

cat("\nMapping courts to counties...\n")

crosswalk <- fread(file.path(data_dir, "court_county_crosswalk.csv"))
crosswalk[, county_fips := str_pad(as.character(county_fips), 5, pad = "0")]

# Normalize court names for merging
crosswalk[, court_city_norm := tolower(court_name)]
court_panel[, court_city_norm := tolower(court_city)]

# Merge
court_county <- merge(court_panel, crosswalk,
                       by.x = "court_city_norm", by.y = "court_city_norm",
                       all.x = TRUE)

# For courts in same city, keep the main one
court_county <- court_county[!is.na(county_fips)]
court_county <- unique(court_county, by = c("court_city", "county_fips"))

cat("Court-county pairs:", nrow(court_county), "\n")
cat("Unique counties:", n_distinct(court_county$county_fips), "\n")

## ---------------------------------------------------------------------------
## E. Process QCEW County Employment Data
## ---------------------------------------------------------------------------

cat("\nProcessing QCEW data...\n")

# Combine bulk and API QCEW data
qcew_files <- list.files(data_dir, pattern = "^qcew_annual_\\d{4}\\.csv$",
                          full.names = TRUE)

if (length(qcew_files) > 0) {
  qcew_bulk <- rbindlist(lapply(qcew_files, fread), fill = TRUE)
  cat("  Bulk QCEW:", nrow(qcew_bulk), "rows,",
      n_distinct(qcew_bulk$year), "years\n")
} else {
  qcew_bulk <- data.table()
}

# Also load API data
qcew_api_file <- file.path(data_dir, "qcew_api_combined.csv")
if (file.exists(qcew_api_file)) {
  qcew_api <- fread(qcew_api_file)
  cat("  API QCEW:", nrow(qcew_api), "rows\n")
} else {
  qcew_api <- data.table()
}

# Combine both sources
common_cols <- c("area_fips", "industry_code", "annual_avg_emplvl",
                 "annual_avg_estabs", "annual_avg_wkly_wage", "year")
bulk_cols <- intersect(common_cols, names(qcew_bulk))
api_cols <- intersect(common_cols, names(qcew_api))

if (nrow(qcew_bulk) > 0 && nrow(qcew_api) > 0) {
  qcew <- rbindlist(list(
    qcew_bulk[, ..bulk_cols],
    qcew_api[, ..api_cols]
  ), fill = TRUE)
  # Remove duplicates (prefer bulk which has more complete data)
  qcew <- unique(qcew, by = c("area_fips", "industry_code", "year"))
} else if (nrow(qcew_bulk) > 0) {
  qcew <- qcew_bulk[, ..bulk_cols]
} else {
  qcew <- qcew_api[, ..api_cols]
}

# Standardize names
names(qcew) <- tolower(names(qcew))
qcew[, county_fips := str_pad(as.character(area_fips), 5, pad = "0")]

# Filter to target counties (from crosswalk)
target_fips <- unique(court_county$county_fips)
qcew_target <- qcew[county_fips %in% target_fips]

cat("QCEW for target counties:", nrow(qcew_target), "rows,",
    n_distinct(qcew_target$county_fips), "counties,",
    n_distinct(qcew_target$year), "years\n")

# Reshape to wide by industry
qcew_wide <- dcast(
  qcew_target,
  county_fips + year ~ industry_code,
  value.var = c("annual_avg_emplvl", "annual_avg_estabs", "annual_avg_wkly_wage"),
  fun.aggregate = function(x) if(length(x) > 0) sum(x, na.rm = TRUE) else NA_real_
)

# Rename columns clearly
rename_map <- c(
  "annual_avg_emplvl_10" = "emp_total",
  "annual_avg_emplvl_72" = "emp_accom_food",
  "annual_avg_emplvl_56" = "emp_admin_svc",
  "annual_avg_emplvl_52" = "emp_finance",
  "annual_avg_emplvl_54" = "emp_professional",
  "annual_avg_estabs_10" = "estabs_total",
  "annual_avg_estabs_72" = "estabs_accom_food",
  "annual_avg_estabs_56" = "estabs_admin_svc",
  "annual_avg_estabs_52" = "estabs_finance",
  "annual_avg_estabs_54" = "estabs_professional",
  "annual_avg_wkly_wage_10" = "wage_total",
  "annual_avg_wkly_wage_72" = "wage_accom_food",
  "annual_avg_wkly_wage_56" = "wage_admin_svc",
  "annual_avg_wkly_wage_52" = "wage_finance",
  "annual_avg_wkly_wage_54" = "wage_professional"
)

for (old in names(rename_map)) {
  if (old %in% names(qcew_wide)) {
    setnames(qcew_wide, old, rename_map[old])
  }
}

cat("QCEW wide:", nrow(qcew_wide), "county-years\n")

## ---------------------------------------------------------------------------
## F. Process ACS County Demographics
## ---------------------------------------------------------------------------

cat("\nProcessing ACS data...\n")

acs <- fread(file.path(data_dir, "acs_combined.csv"))

# Create county FIPS
acs[, county_fips := paste0(str_pad(state, 2, pad = "0"),
                             str_pad(county, 3, pad = "0"))]

# Convert to numeric
num_vars <- c("B05001_006E", "B05001_001E", "B05002_013E", "B05002_001E",
              "B17001_002E", "B17001_001E", "B01003_001E",
              "B23025_002E", "B23025_005E")
for (v in intersect(num_vars, names(acs))) {
  acs[, (v) := as.numeric(get(v))]
}

# Construct variables
acs[, `:=`(
  noncitizen_pop = B05001_006E,
  total_pop = B01003_001E,
  foreign_born = B05002_013E,
  poverty_pop = B17001_002E,
  labor_force = B23025_002E,
  unemployed = B23025_005E
)]

acs[, `:=`(
  noncitizen_share = noncitizen_pop / total_pop,
  foreign_born_share = foreign_born / total_pop,
  poverty_rate = poverty_pop / B17001_001E,
  unemployment_rate = unemployed / labor_force
)]

acs_clean <- acs[, .(county_fips, year, total_pop, noncitizen_pop, noncitizen_share,
                      foreign_born, foreign_born_share, poverty_rate, unemployment_rate,
                      labor_force)]

# Filter to target counties
acs_target <- acs_clean[county_fips %in% target_fips]
cat("ACS for target counties:", nrow(acs_target), "rows,",
    n_distinct(acs_target$county_fips), "counties\n")

## ---------------------------------------------------------------------------
## G. Build Analysis Panel: Court-County × Year
## ---------------------------------------------------------------------------

cat("\nBuilding analysis panel...\n")

# The panel is: court-county (cross-section) × year (from QCEW/ACS)
# Court-level instrument is cross-sectional (fixed per court)
# Outcomes vary by county × year

# Get all county-year combinations from QCEW
county_years <- qcew_wide[, .(county_fips, year)]

# Merge with court-county mapping
panel <- merge(county_years, court_county[, .(county_fips, court_city, court_state,
                                               court_code, court_grant_rate,
                                               avg_judge_leniency, loo_leniency,
                                               leniency_sd, n_judges, total_hearings)],
               by = "county_fips", allow.cartesian = TRUE)

# Merge with QCEW outcomes
panel <- merge(panel, qcew_wide, by = c("county_fips", "year"), all.x = TRUE)

# Merge with ACS controls
panel <- merge(panel, acs_target, by = c("county_fips", "year"), all.x = TRUE)

# Log-transform outcomes
for (v in c("emp_total", "emp_accom_food", "emp_admin_svc", "emp_finance",
            "emp_professional", "estabs_total")) {
  log_v <- paste0("log_", sub("emp_", "", sub("estabs_", "est_", v)))
  panel[get(v) > 0, (log_v) := log(get(v))]
}
panel[wage_total > 0, log_wage_total := log(wage_total)]
panel[wage_accom_food > 0, log_wage_accom := log(wage_accom_food)]

# Create state FIPS for state FE
panel[, state_fips := substr(county_fips, 1, 2)]

# Create region variable
panel[, region := fcase(
  state_fips %in% c("09","23","25","33","34","36","42","44","50"), "Northeast",
  state_fips %in% c("17","18","19","20","26","27","29","31","38","39","46","55"), "Midwest",
  state_fips %in% c("01","05","10","11","12","13","21","22","24","28","37","40","45","47","48","51","54"), "South",
  default = "West"
)]

# Summary
cat("\n=== ANALYSIS PANEL ===\n")
cat("Observations:", format(nrow(panel), big.mark = ","), "\n")
cat("Courts:", n_distinct(panel$court_city), "\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Mean court grant rate:", round(mean(panel$court_grant_rate, na.rm = TRUE), 3), "\n")
cat("Mean judge leniency:", round(mean(panel$avg_judge_leniency, na.rm = TRUE), 3), "\n")
cat("Correlation (grant rate, leniency):",
    round(cor(panel$court_grant_rate, panel$avg_judge_leniency, use = "complete"), 3), "\n")
cat("Mean log employment:", round(mean(panel$log_total, na.rm = TRUE), 2), "\n")

# Save analysis panel
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

# Save summary statistics for later use
summary_vars <- c("court_grant_rate", "avg_judge_leniency", "loo_leniency",
                   "leniency_sd", "n_judges",
                   "emp_total", "emp_accom_food", "emp_admin_svc",
                   "emp_finance", "emp_professional",
                   "wage_total", "wage_accom_food",
                   "estabs_total", "total_pop",
                   "noncitizen_share", "foreign_born_share",
                   "poverty_rate", "unemployment_rate")

summary_stats <- panel[, lapply(.SD, function(x) {
  list(mean = mean(x, na.rm = TRUE),
       sd = sd(x, na.rm = TRUE),
       min = min(x, na.rm = TRUE),
       max = max(x, na.rm = TRUE),
       n_nonmissing = sum(!is.na(x)))
}), .SDcols = intersect(summary_vars, names(panel))]

# Convert to long format for saving
stats_long <- data.table(
  variable = character(),
  mean = numeric(),
  sd = numeric(),
  min = numeric(),
  max = numeric(),
  n = integer()
)

for (v in intersect(summary_vars, names(panel))) {
  vals <- panel[[v]]
  vals <- vals[!is.na(vals)]
  if (length(vals) > 0) {
    stats_long <- rbind(stats_long, data.table(
      variable = v,
      mean = mean(vals),
      sd = sd(vals),
      min = min(vals),
      max = max(vals),
      n = length(vals)
    ))
  }
}

fwrite(stats_long, file.path(data_dir, "summary_stats.csv"))

cat("\nAnalysis panel and summary stats saved.\n")

# Validation
stopifnot("Panel must have 100+ observations" = nrow(panel) >= 100)
stopifnot("Panel must cover 20+ courts" = n_distinct(panel$court_city) >= 20)
stopifnot("Leniency must vary" = sd(panel$avg_judge_leniency, na.rm = TRUE) > 0.01)
cat("Panel validation passed.\n")
