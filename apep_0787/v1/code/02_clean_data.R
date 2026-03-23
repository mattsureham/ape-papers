## 02_clean_data.R — Clean and harmonize OSHA ITA data, merge PSL treatment
## apep_0787: PSL mandates and workplace injuries

source("00_packages.R")

data_dir <- "../data"
raw_list <- readRDS(file.path(data_dir, "osha_ita_raw_list.rds"))

# ── Drop 2016 (404 — only 2 rows of HTML) ──────────────────────────────────
raw_list[["2016"]] <- NULL
cat("Using years:", paste(names(raw_list), collapse = ", "), "\n")

# ── Harmonize column names ──────────────────────────────────────────────────
# 2017-2022 have consistent naming; 2023 has extra columns
# Key variables: state, naics_code, annual_average_employees,
# total_hours_worked, total_dafw_cases, total_djtr_cases, total_other_cases,
# total_injuries, total_deaths

standardize_cols <- function(df, yr) {
  df <- janitor::clean_names(df)

  # Convert integer64 columns to numeric (bit64 integer64 corrupts during rbindlist)
  i64_cols <- names(df)[sapply(df, function(x) inherits(x, "integer64"))]
  if (length(i64_cols) > 0) {
    cat("  Year", yr, ": converting integer64 columns:", paste(i64_cols, collapse = ", "), "\n")
    for (col in i64_cols) {
      df[[col]] <- as.numeric(df[[col]])
    }
  }

  # Select available columns
  keep <- intersect(names(df), c(
    "state", "naics_code", "annual_average_employees",
    "total_hours_worked", "total_dafw_cases", "total_djtr_cases",
    "total_other_cases", "total_injuries", "total_deaths",
    "total_dafw_days", "total_djtr_days",
    "no_injuries_illnesses", "industry_description", "size",
    "establishment_type", "city", "zip_code", "data_year"
  ))
  df[, ..keep]
}

clean_list <- list()
for (yr in names(raw_list)) {
  cat("Standardizing", yr, "...\n")
  clean_list[[yr]] <- standardize_cols(raw_list[[yr]], yr)
}

# ── Bind all years ──────────────────────────────────────────────────────────
df <- rbindlist(clean_list, fill = TRUE)
cat("\nCombined dataset:", nrow(df), "rows\n")

# ── Basic cleaning ──────────────────────────────────────────────────────────
# Convert to numeric where needed
num_cols <- c("annual_average_employees", "total_hours_worked",
              "total_dafw_cases", "total_djtr_cases", "total_other_cases",
              "total_injuries", "total_deaths", "total_dafw_days", "total_djtr_days")
for (col in num_cols) {
  if (col %in% names(df)) {
    df[[col]] <- as.numeric(df[[col]])
  }
}
df$naics_code <- as.character(df$naics_code)

# Extract 2-digit NAICS
df[, naics2 := substr(naics_code, 1, 2)]

# Standardize state names to abbreviations
state_lookup <- setNames(state.abb, state.name)
# Add DC
state_lookup["District of Columbia"] <- "DC"

# Check what format state is in
cat("State values sample:", paste(head(unique(df$state), 10), collapse = ", "), "\n")

# If states are full names, convert to abbreviations
if (any(df$state %in% state.name)) {
  df[, state_abbr := state_lookup[state]]
} else {
  df[, state_abbr := state]
}

# Keep only valid 50 states + DC
valid_states <- c(state.abb, "DC")
df <- df[state_abbr %in% valid_states]
cat("After keeping 50 states + DC:", nrow(df), "rows\n")
cat("Unique states:", length(unique(df$state_abbr)), "\n")
cat("States:", paste(sort(unique(df$state_abbr)), collapse = ", "), "\n")

# ── Construct injury rates per 100 FTE ─────────────────────────────────────
# FTE = total_hours_worked / 2000
df[, fte := total_hours_worked / 2000]

# Total Case Rate (TCR) per 100 FTE
df[, tcr := ifelse(fte > 0, (total_injuries / fte) * 100, NA_real_)]

# DAFW Rate per 100 FTE
df[, dafw_rate := ifelse(fte > 0, (total_dafw_cases / fte) * 100, NA_real_)]

# DJTR Rate per 100 FTE
df[, djtr_rate := ifelse(fte > 0, (total_djtr_cases / fte) * 100, NA_real_)]

# Other cases rate per 100 FTE
df[, other_rate := ifelse(fte > 0, (total_other_cases / fte) * 100, NA_real_)]

# ── Define PSL treatment ───────────────────────────────────────────────────
# Treatment year = first full calendar year the mandate is in effect
# (conservative — avoids partial-year contamination)
psl_treatment <- data.table(
  state_abbr = c("CT", "CA", "MA", "DC", "OR",
                 "AZ", "VT", "WA",
                 "MD", "NJ", "RI",
                 "MI",
                 "NY",
                 "CO",
                 "NM", "MN", "IL"),
  psl_effective = c("2012-01-01", "2015-07-01", "2015-07-01", "2014-02-11", "2016-01-01",
                    "2017-07-01", "2017-01-01", "2018-01-01",
                    "2018-02-11", "2018-10-29", "2018-07-01",
                    "2019-03-29",
                    "2020-09-30",
                    "2021-01-01",
                    "2023-07-01", "2024-01-01", "2024-01-01"),
  # First FULL calendar year of treatment
  psl_treat_year = c(2013, 2016, 2016, 2015, 2016,
                     2018, 2017, 2018,
                     2019, 2019, 2019,
                     2020,
                     2021,
                     2021,
                     2024, 2024, 2024)
)

# States with treatment before or at start of data window (2017) = always-treated
# CT (2013), CA (2016), MA (2016), DC (2015), OR (2016), VT (2017=first year)
# These are EXCLUDED from CS estimation
always_treated <- c("CT", "CA", "MA", "DC", "OR", "VT")

# States with treatment after our data window (2023) = not-yet-treated in our sample
# NM, MN, IL (all 2024) — these function as never-treated
# Actually NM effective July 2023 → psl_treat_year 2024 (first FULL year)

cat("\n=== PSL Treatment Assignment ===\n")
cat("Always-treated (pre-2017):", paste(always_treated, collapse = ", "), "\n")

# Merge treatment info
df <- merge(df, psl_treatment[, .(state_abbr, psl_treat_year)],
            by = "state_abbr", all.x = TRUE)

# For CS estimation: first_treat = 0 for never-treated AND not-yet-treated
# States treated in 2024 have no post-treatment data (our window is 2017-2023)
# so they function as never-treated in the estimation
df[, first_treat := fifelse(is.na(psl_treat_year) | psl_treat_year > 2023,
                            0L, as.integer(psl_treat_year))]

# Mark always-treated
df[, always_treated := state_abbr %in% always_treated]

# Create analysis sample (exclude always-treated)
df_analysis <- df[always_treated == FALSE]

# For states treated before 2017 that are NOT in always_treated
# (shouldn't happen, but check)
cat("Treatment cohorts in analysis sample:\n")
print(df_analysis[, .N, by = first_treat][order(first_treat)])

# ── Define industry groups for triple-diff ─────────────────────────────────
# High-hazard (physical, presenteeism-sensitive)
high_hazard <- c("23",  # Construction
                 "31", "32", "33",  # Manufacturing
                 "48", "49",  # Transportation/Warehousing
                 "11",  # Agriculture
                 "21")  # Mining

# Low-hazard (office-based, presenteeism less dangerous)
low_hazard <- c("51",  # Information
                "52",  # Finance
                "53",  # Real Estate
                "54",  # Professional Services
                "55",  # Management
                "56")  # Admin/Waste Services (mixed, but mostly office)

df_analysis[, hazard_group := fcase(
  naics2 %in% high_hazard, "high_hazard",
  naics2 %in% low_hazard, "low_hazard",
  default = "other"
)]

cat("\nIndustry hazard groups:\n")
print(df_analysis[, .N, by = hazard_group])

# ── Collapse to state × NAICS2 × year panel ───────────────────────────────
# Establishment IDs may not be stable across years, so we aggregate
panel <- df_analysis[
  !is.na(total_injuries) & !is.na(total_hours_worked) & total_hours_worked > 0,
  .(
    n_estab = .N,
    total_injuries = sum(total_injuries, na.rm = TRUE),
    total_dafw = sum(total_dafw_cases, na.rm = TRUE),
    total_djtr = sum(total_djtr_cases, na.rm = TRUE),
    total_other = sum(total_other_cases, na.rm = TRUE),
    total_deaths = sum(total_deaths, na.rm = TRUE),
    total_hours = sum(total_hours_worked, na.rm = TRUE),
    total_employees = sum(annual_average_employees, na.rm = TRUE)
  ),
  by = .(state_abbr, naics2, data_year, first_treat, hazard_group)
]

# Compute rates per 100 FTE at the cell level
panel[, fte := total_hours / 2000]
panel[, tcr := (total_injuries / fte) * 100]
panel[, dafw_rate := (total_dafw / fte) * 100]
panel[, djtr_rate := (total_djtr / fte) * 100]

# Create state-level panel (collapse across industries)
state_panel <- panel[
  ,
  .(
    n_estab = sum(n_estab),
    total_injuries = sum(total_injuries),
    total_dafw = sum(total_dafw),
    total_djtr = sum(total_djtr),
    total_other = sum(total_other),
    total_deaths = sum(total_deaths),
    total_hours = sum(total_hours),
    total_employees = sum(total_employees)
  ),
  by = .(state_abbr, data_year, first_treat)
]
state_panel[, fte := total_hours / 2000]
state_panel[, tcr := (total_injuries / fte) * 100]
state_panel[, dafw_rate := (total_dafw / fte) * 100]
state_panel[, djtr_rate := (total_djtr / fte) * 100]

# Create numeric state ID for CS estimation
state_panel[, state_id := as.integer(as.factor(state_abbr))]
panel[, state_id := as.integer(as.factor(state_abbr))]

# Also create a cell ID for the industry panel
panel[, cell_id := as.integer(as.factor(paste(state_abbr, naics2)))]

# ── Summary statistics ─────────────────────────────────────────────────────
cat("\n=== Analysis Panel Summary ===\n")
cat("State-year panel:", nrow(state_panel), "obs\n")
cat("States:", length(unique(state_panel$state_abbr)), "\n")
cat("Years:", paste(sort(unique(state_panel$data_year)), collapse = ", "), "\n")
cat("Treated states:", sum(state_panel[data_year == 2017]$first_treat > 0), "\n")
cat("Never-treated states:", sum(state_panel[data_year == 2017]$first_treat == 0), "\n")

cat("\nState-NAICS2-year panel:", nrow(panel), "obs\n")
cat("Unique cells:", length(unique(panel$cell_id)), "\n")

# Drop cells with zero FTE (avoid Inf rates)
state_panel <- state_panel[is.finite(tcr) & fte > 0]
panel <- panel[is.finite(tcr) & fte > 0]

cat("\nAfter dropping zero-FTE cells:\n")
cat("State-year panel:", nrow(state_panel), "obs\n")
cat("State-NAICS2-year panel:", nrow(panel), "obs\n")

cat("\nMean injury rates (state-year panel):\n")
cat("  TCR:", round(mean(state_panel$tcr, na.rm = TRUE), 2), "\n")
cat("  DAFW:", round(mean(state_panel$dafw_rate, na.rm = TRUE), 2), "\n")
cat("  DJTR:", round(mean(state_panel$djtr_rate, na.rm = TRUE), 2), "\n")

# ── Save ───────────────────────────────────────────────────────────────────
saveRDS(state_panel, file.path(data_dir, "state_panel.rds"))
saveRDS(panel, file.path(data_dir, "industry_panel.rds"))
saveRDS(df_analysis, file.path(data_dir, "establishment_data.rds"))
cat("\nData saved.\n")
