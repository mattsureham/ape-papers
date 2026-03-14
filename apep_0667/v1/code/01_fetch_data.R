# 01_fetch_data.R — Fetch EBT dates, mortality data, and population
# apep_0667: EBT rollout and drug-market activity
#
# Data sources:
#   1. EBT dates: Hard-coded from USDA FNS / Currie & Gahvari (2008)
#   2. Drug poisoning mortality: CDC data.cdc.gov (jx6g-fdh6)
#   3. Placebo outcomes: CDC Leading Causes of Death (bi63-dtpu)
#   4. Population: FRED API (state population)

source("00_packages.R")

# --- Load .env ---
d <- getwd()
while (nchar(d) > 1) {
  candidate <- file.path(d, ".env")
  if (file.exists(candidate)) {
    env_lines <- readLines(candidate, warn = FALSE)
    for (line in env_lines) {
      line <- trimws(line)
      if (nchar(line) == 0 || startsWith(line, "#")) next
      eq_pos <- regexpr("=", line, fixed = TRUE)
      if (eq_pos > 0) {
        key <- trimws(substr(line, 1, eq_pos - 1))
        val <- trimws(substr(line, eq_pos + 1, nchar(line)))
        val <- gsub("^['\"]|['\"]$", "", val)
        do.call(Sys.setenv, setNames(list(val), key))
      }
    }
    cat("Loaded .env\n")
    break
  }
  d <- dirname(d)
}

# ===================================================================
cat("=== STEP 1: EBT Rollout Dates ===\n")
# ===================================================================
# Sources: USDA FNS EBT Status Reports; Currie & Gahvari (2008, JEL);
# Ratcliffe et al. (2011, USDA-ERS); Wright et al. (2017, JLE)
ebt_dates <- tribble(
  ~state_abbr, ~state_name,           ~ebt_year,
  "AL", "Alabama",              2001,
  "AK", "Alaska",               2003,
  "AZ", "Arizona",              2000,
  "AR", "Arkansas",             2000,
  "CA", "California",           2004,
  "CO", "Colorado",             2001,
  "CT", "Connecticut",          1999,
  "DE", "Delaware",             1999,
  "DC", "District of Columbia", 2001,
  "FL", "Florida",              2000,
  "GA", "Georgia",              2001,
  "HI", "Hawaii",               2002,
  "ID", "Idaho",                2001,
  "IL", "Illinois",             2000,
  "IN", "Indiana",              2002,
  "IA", "Iowa",                 2002,
  "KS", "Kansas",               2001,
  "KY", "Kentucky",             2001,
  "LA", "Louisiana",            2000,
  "ME", "Maine",                2001,
  "MD", "Maryland",             1998,
  "MA", "Massachusetts",        2002,
  "MI", "Michigan",             2001,
  "MN", "Minnesota",            2001,
  "MS", "Mississippi",          2001,
  "MO", "Missouri",             2002,
  "MT", "Montana",              2002,
  "NE", "Nebraska",             2001,
  "NV", "Nevada",               2002,
  "NH", "New Hampshire",        2002,
  "NJ", "New Jersey",           1999,
  "NM", "New Mexico",           1999,
  "NY", "New York",             2003,
  "NC", "North Carolina",       2001,
  "ND", "North Dakota",         2001,
  "OH", "Ohio",                 2003,
  "OK", "Oklahoma",             2001,
  "OR", "Oregon",               2002,
  "PA", "Pennsylvania",         2002,
  "RI", "Rhode Island",         2000,
  "SC", "South Carolina",       1998,
  "SD", "South Dakota",         2001,
  "TN", "Tennessee",            2001,
  "TX", "Texas",                2004,
  "UT", "Utah",                 2001,
  "VT", "Vermont",              2002,
  "VA", "Virginia",             2001,
  "WA", "Washington",           2001,
  "WV", "West Virginia",        2002,
  "WI", "Wisconsin",            2001,
  "WY", "Wyoming",              1998
)
stopifnot(nrow(ebt_dates) == 51)
cat("  51 states/DC. Range:", min(ebt_dates$ebt_year), "-", max(ebt_dates$ebt_year), "\n")
write_csv(ebt_dates, "../data/ebt_dates.csv")

# ===================================================================
cat("\n=== STEP 2: Drug Poisoning Mortality (CDC) ===\n")
# ===================================================================
# NCHS Drug Poisoning Mortality by State (dataset: jx6g-fdh6)
# Age-adjusted death rates per 100,000, by state and year

drug_raw <- request("https://data.cdc.gov/resource/jx6g-fdh6.json") %>%
  req_url_query(
    `$where` = "year >= '1999' AND year <= '2010'",
    `$limit` = 50000
  ) %>%
  req_perform() %>%
  resp_body_json(simplifyVector = TRUE)

stopifnot(is.data.frame(drug_raw), nrow(drug_raw) > 0)
cat("  Raw drug poisoning data:", nrow(drug_raw), "rows\n")

# Filter to overall (both sexes, all ages, all races)
drug_df <- drug_raw %>%
  filter(sex == "Both Sexes",
         age == "All Ages",
         race_hispanic_origin == "All Races-All Origins") %>%
  mutate(
    year = as.integer(year),
    deaths = as.integer(deaths),
    population = as.numeric(population),
    crude_rate = as.numeric(crude_death_rate),
    aadr = as.numeric(age_adjusted_rate)
  ) %>%
  # Exclude US total
  filter(state != "United States") %>%
  select(year, state, deaths, population, crude_rate, aadr)

cat("  Filtered (overall):", nrow(drug_df), "state-years\n")
cat("  States:", n_distinct(drug_df$state), "\n")
cat("  Year range:", min(drug_df$year), "-", max(drug_df$year), "\n")
cat("  Mean drug death rate:", round(mean(drug_df$aadr, na.rm = TRUE), 2), "per 100k\n")

stopifnot(nrow(drug_df) >= 400)  # Should have ~600 state-years
write_csv(drug_df, "../data/drug_poisoning.csv")

# ===================================================================
cat("\n=== STEP 3: Placebo Outcomes (CDC Leading Causes) ===\n")
# ===================================================================
# Dataset: bi63-dtpu
# Available causes: Suicide, Unintentional injuries, Heart disease,
# Cancer, Stroke, Diabetes, CLRD, Alzheimer's disease, Kidney disease,
# Influenza and pneumonia, All causes

placebo_causes <- c("Suicide", "Unintentional injuries", "Heart disease")

placebo_list <- list()
for (cause in placebo_causes) {
  cat("  Fetching:", cause, "... ")

  result <- tryCatch({
    resp <- request("https://data.cdc.gov/resource/bi63-dtpu.json") %>%
      req_url_query(
        cause_name = cause,
        `$limit` = 50000,
        `$where` = "year >= '1999' AND year <= '2010'"
      ) %>%
      req_perform()
    resp_body_json(resp, simplifyVector = TRUE)
  }, error = function(e) {
    cat("Error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(result) && is.data.frame(result) && nrow(result) > 0) {
    placebo_list[[cause]] <- result %>%
      filter(state != "United States") %>%
      mutate(
        year = as.integer(year),
        deaths = as.integer(deaths),
        aadr = as.numeric(aadr),
        cause = cause
      ) %>%
      select(year, state, cause, deaths, aadr)
    cat(nrow(placebo_list[[cause]]), "rows\n")
  } else {
    cat("No data\n")
  }
}

if (length(placebo_list) > 0) {
  placebo_df <- bind_rows(placebo_list)
  cat("  Total placebo rows:", nrow(placebo_df), "\n")
  write_csv(placebo_df, "../data/placebo_outcomes.csv")
} else {
  cat("  WARNING: No placebo outcome data obtained\n")
  placebo_df <- tibble()
}

# ===================================================================
cat("\n=== STEP 4: State Population (FRED) ===\n")
# ===================================================================
fred_key <- Sys.getenv("FRED_API_KEY")
stopifnot(nchar(fred_key) > 0)
fredr_set_key(fred_key)

state_abbrs <- c(state.abb, "DC")
pop_list <- list()

for (st in state_abbrs) {
  result <- tryCatch({
    fredr_series_observations(
      series_id = paste0(st, "POP"),
      observation_start = as.Date("1995-01-01"),
      observation_end = as.Date("2010-12-31")
    ) %>%
      mutate(
        state_abbr = st,
        year = as.integer(format(date, "%Y")),
        population = value * 1000
      ) %>%
      select(state_abbr, year, population)
  }, error = function(e) NULL)

  if (!is.null(result)) pop_list[[st]] <- result
}

pop_df <- bind_rows(pop_list)
cat("  Population:", nrow(pop_df), "state-years,", n_distinct(pop_df$state_abbr), "states\n")
write_csv(pop_df, "../data/population.csv")

# ===================================================================
cat("\n=== STEP 5: State Mapping ===\n")
# ===================================================================
# CDC uses full state names; FRED/EBT use abbreviations
state_map <- tibble(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC")
)
write_csv(state_map, "../data/state_map.csv")

# ===================================================================
cat("\n=== DATA SUMMARY ===\n")
# ===================================================================
cat("EBT dates:       51 states ✓\n")
cat("Drug poisoning:  ", nrow(drug_df), "state-years ✓\n")
cat("Placebo causes:  ", nrow(placebo_df), "state-year-cause rows",
    ifelse(nrow(placebo_df) > 0, "✓", "⚠"), "\n")
cat("Population:      ", nrow(pop_df), "state-years ✓\n")
cat("\n=== Data fetch complete ===\n")
