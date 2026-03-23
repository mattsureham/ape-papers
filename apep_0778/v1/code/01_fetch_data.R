## =============================================================================
## 01_fetch_data.R — Fetch SNAP data via Census ACS API + treatment assignment
## apep_0778
## =============================================================================

source("00_packages.R")

## Load .env for API keys
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#") || !grepl("=", line)) next
  eq_pos <- regexpr("=", line)
  key <- trimws(substr(line, 1, eq_pos - 1))
  val <- trimws(substr(line, eq_pos + 1, nchar(line)))
  val <- gsub("^['\"]|['\"]$", "", val)
  if (nchar(key) > 0) do.call(Sys.setenv, setNames(list(val), key))
}

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("FATAL: CENSUS_API_KEY not set")

cat("=== Step 1: Build treatment assignment ===\n")

## Transitional SNAP benefits adoption dates
## Source: USDA ERS SNAP Policy Database, transben variable
transben_states <- tribble(
  ~state_abbr, ~state_name,            ~adoption_year,
  "NY",        "New York",              2001,
  "PA",        "Pennsylvania",          2002,
  "AZ",        "Arizona",               2003,
  "CO",        "Colorado",              2003,
  "MD",        "Maryland",              2003,
  "MA",        "Massachusetts",         2003,
  "FL",        "Florida",               2004,
  "IL",        "Illinois",              2004,
  "NJ",        "New Jersey",            2004,
  "TX",        "Texas",                 2004,
  "VA",        "Virginia",              2004,
  "WA",        "Washington",            2004,
  "GA",        "Georgia",               2005,
  "MI",        "Michigan",              2005,
  "OH",        "Ohio",                  2005,
  "MN",        "Minnesota",             2006,
  "NC",        "North Carolina",        2006,
  "OR",        "Oregon",                2006,
  "WI",        "Wisconsin",             2006,
  "IN",        "Indiana",               2007,
  "KY",        "Kentucky",              2008,
  "TN",        "Tennessee",             2009,
  "CT",        "Connecticut",           2016,
  "DC",        "District of Columbia",  2016
)

cat(sprintf("  Treated states: %d, Adoption range: %d-%d\n",
            nrow(transben_states), min(transben_states$adoption_year),
            max(transben_states$adoption_year)))

## State FIPS mapping
state_fips <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                  "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                  "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                  "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  fips = c("01","02","04","05","06","08","09","10","12","13","15","16",
           "17","18","19","20","21","22","23","24","25","26","27","28",
           "29","30","31","32","33","34","35","36","37","38","39","40",
           "41","42","44","45","46","47","48","49","50","51","53","54",
           "55","56","11")
)

## ---- Step 2: Fetch SNAP participation from Census ACS API ----
cat("\n=== Step 2: Fetch SNAP households from Census ACS (2005-2023) ===\n")

## ACS 1-year variables:
## B22001_001E = Total households
## B22001_002E = Households received food stamps/SNAP in past 12 months
## Available from 2005 onward (1-year ACS)

acs_years <- 2005:2023
all_acs <- list()

for (yr in acs_years) {
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=B22001_001E,B22001_002E,NAME&for=state:*&key=%s",
    yr, census_key
  )

  resp <- tryCatch(GET(url), error = function(e) NULL)

  if (is.null(resp) || status_code(resp) != 200) {
    cat(sprintf("  Year %d: API error (skipping)\n", yr))
    next
  }

  dat <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(dat)

  if (is.null(parsed) || nrow(parsed) < 2) {
    cat(sprintf("  Year %d: empty response (skipping)\n", yr))
    next
  }

  header <- parsed[1, ]
  body <- parsed[-1, , drop = FALSE]
  colnames(body) <- header

  df_yr <- as_tibble(body) %>%
    mutate(
      year = yr,
      total_hh = as.numeric(B22001_001E),
      snap_hh = as.numeric(B22001_002E),
      state_fips = state
    ) %>%
    filter(!is.na(total_hh), !is.na(snap_hh))

  all_acs[[as.character(yr)]] <- df_yr
  cat(sprintf("  Year %d: %d states fetched\n", yr, nrow(df_yr)))
}

if (length(all_acs) == 0) {
  stop("FATAL: No ACS data retrieved. Cannot proceed without real data.")
}

acs_df <- bind_rows(all_acs) %>%
  left_join(state_fips, by = c("state_fips" = "fips")) %>%
  filter(!is.na(state_abbr)) %>%
  mutate(
    snap_rate = snap_hh / total_hh,
    log_snap_hh = log(snap_hh),
    log_total_hh = log(total_hh)
  )

cat(sprintf("\n  ACS panel: %d state-year obs, %d states, %d-%d\n",
            nrow(acs_df), n_distinct(acs_df$state_abbr),
            min(acs_df$year), max(acs_df$year)))

## Validate
test <- acs_df %>% filter(state_abbr == "NY", year == 2010)
if (nrow(test) == 0) stop("FATAL: Data validation failed — NY 2010 not found")
cat(sprintf("  Validation: NY 2010 SNAP rate = %.1f%%\n", test$snap_rate * 100))

## ---- Step 3: Merge treatment assignment ----
cat("\n=== Step 3: Merge treatment assignment ===\n")

panel <- acs_df %>%
  left_join(transben_states %>% select(state_abbr, adoption_year),
            by = "state_abbr") %>%
  mutate(
    treated = ifelse(!is.na(adoption_year), 1, 0),
    first_treat = ifelse(treated == 1, adoption_year, 0),
    post = ifelse(treated == 1 & year >= adoption_year, 1, 0),
    state_id = as.numeric(factor(state_abbr))
  )

cat(sprintf("  Treated states in panel: %d\n",
            n_distinct(panel$state_abbr[panel$treated == 1])))
cat(sprintf("  Control states in panel: %d\n",
            n_distinct(panel$state_abbr[panel$treated == 0])))
cat(sprintf("  Treatment cohorts in data: %s\n",
            paste(sort(unique(panel$first_treat[panel$first_treat > 0 &
                                                  panel$first_treat >= 2005])),
                  collapse = ", ")))

## ---- Save ----
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(transben_states, "../data/treatment_states.rds")

cat("  Saved: analysis_panel.rds, treatment_states.rds\n")
cat("  DONE.\n")
