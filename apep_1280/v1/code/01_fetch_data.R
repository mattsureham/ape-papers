# ==============================================================================
# 01_fetch_data.R — QWI data already fetched via Python DuckDB.
# This script builds the minimum wage treatment panel.
# ==============================================================================

source("00_packages.R")

# --- Read QWI parquet (fetched by Python script) ---
con <- dbConnect(duckdb::duckdb())
qwi_raw <- dbGetQuery(con, "SELECT * FROM read_parquet('../data/qwi_race_industry.parquet')")
dbDisconnect(con)

cat("QWI rows loaded:", nrow(qwi_raw), "\n")

# Classify industries
qwi_raw <- qwi_raw |>
  mutate(
    naics2 = substr(naics3, 1, 2),
    industry_group = case_when(
      naics2 %in% c("44", "45", "72", "56") ~ "low_wage",
      naics2 %in% c("52", "54") ~ "high_wage",
      TRUE ~ "other"
    ),
    state_fips = substr(as.character(county_fips), 1, 2),
    # Pad state_fips to 2 chars
    state_fips = sprintf("%02s", state_fips),
    period = year * 4L + quarter
  )

cat("Industry group distribution:\n")
print(table(qwi_raw$industry_group))

# ==============================================================================
# State Minimum Wage History
# ==============================================================================
# Detailed quarterly state MW data (nominal dollars/hr)
# Sources: DOL WHD, EPI MW Tracker, Vaghul & Zipperer

# Treated states: first large hike above 115% of $7.25 = $8.34
# Treatment timing: first quarter effective_mw > 8.34
mw_states <- tribble(
  ~state_fips, ~y2005, ~y2008, ~y2010, ~y2012, ~y2014, ~y2016, ~y2018, ~y2020, ~y2022,
  "06",         6.75,   8.00,   8.00,   8.00,   9.00,  10.00,  11.00,  13.00,  15.00,  # CA
  "08",         5.15,   7.02,   7.24,   7.64,   8.00,   8.31,  10.20,  12.00,  12.56,  # CO
  "09",         7.10,   7.65,   8.25,   8.25,   8.70,   9.60,  10.10,  12.00,  15.00,  # CT
  "10",         6.15,   7.15,   7.25,   7.25,   7.75,   8.25,   8.25,   9.25,  10.50,  # DE
  "15",         6.25,   7.25,   7.25,   7.25,   7.25,   8.50,  10.10,  10.10,  12.00,  # HI
  "17",         6.50,   7.75,   8.25,   8.25,   8.25,   8.25,   8.25,  10.00,  12.00,  # IL
  "23",         6.35,   7.25,   7.50,   7.50,   7.50,   7.50,  10.00,  12.00,  12.75,  # ME
  "24",         6.15,   6.55,   7.25,   7.25,   8.00,   8.75,  10.10,  11.00,  12.50,  # MD
  "25",         6.75,   8.00,   8.00,   8.00,   8.00,   10.00, 11.00,  12.75,  14.25,  # MA
  "27",         6.15,   6.15,   6.15,   6.15,   8.00,   9.50,   9.65,  10.00,  10.59,  # MN
  "32",         5.15,   6.55,   7.55,   8.25,   8.25,   8.25,   8.25,   9.00,  10.50,  # NV
  "34",         6.15,   7.15,   7.25,   7.25,   8.25,   8.38,   8.60,  12.00,  13.00,  # NJ
  "36",         6.00,   7.15,   7.25,   7.25,   8.00,   9.00,  10.40,  11.80,  13.20,  # NY
  "41",         7.25,   7.95,   8.40,   8.80,   9.10,   9.75,  10.75,  12.00,  13.50,  # OR
  "44",         6.75,   7.40,   7.40,   7.40,   8.00,   9.60,  10.10,  11.50,  12.25,  # RI
  "50",         7.00,   7.68,   8.06,   8.46,   8.73,   9.60,  10.50,  11.75,  12.55,  # VT
  "53",         7.35,   8.07,   8.55,   9.04,   9.32,   9.47,  11.50,  13.50,  14.49   # WA
)

# Additional treated states with smaller hikes
mw_states2 <- tribble(
  ~state_fips, ~y2005, ~y2008, ~y2010, ~y2012, ~y2014, ~y2016, ~y2018, ~y2020, ~y2022,
  "02",        7.15,   7.15,   7.75,   7.75,   7.75,   9.75,   9.84,  10.19,  10.34,  # AK
  "05",        5.15,   6.25,   7.25,   7.25,   7.25,   8.00,   8.50,   10.00, 11.00,  # AR
  "12",        6.15,   6.79,   7.25,   7.67,   7.93,   8.05,   8.25,   8.56,  11.00,  # FL
  "26",        5.15,   7.40,   7.40,   7.40,   8.15,   8.50,   9.25,   9.65,   9.87,  # MI
  "29",        5.15,   6.50,   7.25,   7.25,   7.50,   7.65,   7.85,   9.45,  12.00,  # MO
  "31",        5.15,   5.85,   7.25,   7.25,   7.25,   9.00,   9.00,   9.00,  10.50,  # NE
  "39",        4.25,   7.00,   7.30,   7.70,   7.95,   8.10,   8.30,   8.70,   9.30,  # OH
  "46",        5.15,   6.55,   7.25,   7.25,   7.25,   8.55,   8.85,   9.30,   9.95   # SD
)

# Never-treated: states at federal $7.25 through at least 2020
never_treated_fips <- c("01","13","16","18","19","20","21","22",
                        "28","30","33","35","37","38","40",
                        "42","45","47","48","49","51","54","55","56")

# Build quarterly MW for each state
years_grid <- c(2005, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022)

all_mw_states <- bind_rows(mw_states, mw_states2)

mw_quarterly <- list()
for (i in seq_len(nrow(all_mw_states))) {
  st <- all_mw_states$state_fips[i]
  vals <- as.numeric(all_mw_states[i, -1])

  # Create quarterly grid and interpolate
  quarters <- expand.grid(year = 2005:2023, quarter = 1:4)
  quarters$year_q <- quarters$year + (quarters$quarter - 1) / 4
  quarters$effective_mw <- approx(years_grid, vals, xout = quarters$year_q, rule = 2)$y
  quarters$state_fips <- st
  mw_quarterly[[i]] <- quarters
}

# Add never-treated states
for (st in never_treated_fips) {
  quarters <- expand.grid(year = 2005:2023, quarter = 1:4)
  quarters$year_q <- quarters$year + (quarters$quarter - 1) / 4
  quarters$effective_mw <- 7.25  # Federal floor
  quarters$state_fips <- st
  mw_quarterly[[length(mw_quarterly) + 1]] <- quarters
}

mw_panel <- bind_rows(mw_quarterly) |>
  mutate(
    federal_mw = 7.25,
    log_mw = log(effective_mw),
    mw_ratio = effective_mw / federal_mw,
    period = year * 4L + quarter,
    treated = effective_mw > 1.15 * federal_mw  # > $8.34
  )

# First treatment quarter
first_treat <- mw_panel |>
  filter(treated) |>
  group_by(state_fips) |>
  summarize(first_treat_period = min(period), .groups = "drop")

mw_panel <- mw_panel |>
  left_join(first_treat, by = "state_fips") |>
  mutate(first_treat_period = replace_na(first_treat_period, 0L))

cat("MW panel: ", nrow(mw_panel), " state-quarters\n")
cat("Treated states: ", sum(first_treat$first_treat_period > 0), "\n")
cat("Never-treated states: ", length(never_treated_fips), "\n")

saveRDS(qwi_raw, "../data/qwi_classified.rds")
saveRDS(mw_panel, "../data/mw_quarterly.rds")
cat("\nData preparation complete.\n")
