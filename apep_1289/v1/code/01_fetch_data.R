## 01_fetch_data.R — Fetch child maltreatment data and DR adoption dates
## APEP paper apep_1289

source("00_packages.R")

cat("=== Fetching data for apep_1289 ===\n")

# ============================================================
# 1. DR Adoption Dates (from published literature)
# ============================================================
# Sources: Child Welfare Information Gateway (2014), Merkel-Holguin et al. (2006),
# National Quality Improvement Center on DR (2014), Kaplan & Merkel-Holguin (2008)
# Cross-referenced with National Conference of State Legislatures

dr_adoption <- tribble(
  ~state, ~state_abbr, ~fips, ~dr_year,
  "Florida",          "FL", "12", 1993,
  "Missouri",         "MO", "29", 1994,
  "Virginia",         "VA", "51", 1999,
  "Kentucky",         "KY", "21", 2000,
  "New Jersey",       "NJ", "34", 2001,
  "Wyoming",          "WY", "56", 2001,
  "Oklahoma",         "OK", "40", 2002,
  "Washington",       "WA", "53", 2002,
  "Minnesota",        "MN", "27", 2004,
  "North Carolina",   "NC", "37", 2005,
  "Tennessee",        "TN", "47", 2005,
  "Louisiana",        "LA", "22", 2006,
  "Ohio",             "OH", "39", 2006,
  "Nevada",           "NV", "32", 2007,
  "West Virginia",    "WV", "54", 2007,
  "Colorado",         "CO", "08", 2008,
  "Hawaii",           "HI", "15", 2008,
  "Vermont",          "VT", "50", 2008,
  "Arkansas",         "AR", "05", 2009,
  "Indiana",          "IN", "18", 2009,
  "Maine",            "ME", "23", 2009,
  "New York",         "NY", "36", 2009,
  "Oregon",           "OR", "41", 2010,
  "Connecticut",      "CT", "09", 2011,
  "Illinois",         "IL", "17", 2011,
  "Maryland",         "MD", "24", 2011,
  "Pennsylvania",     "PA", "42", 2011,
  "Wisconsin",        "WI", "55", 2012,
  "Arizona",          "AZ", "04", 2013,
  "Massachusetts",    "MA", "25", 2014,
  "Michigan",         "MI", "26", 2014,
  "Montana",          "MT", "30", 2015
)

cat(sprintf("DR adoption dates compiled: %d states adopted DR (1993-2015)\n", nrow(dr_adoption)))

# All 50 states + DC
all_states <- tibble(
  state = c("Alabama", "Alaska", "Arizona", "Arkansas", "California",
            "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
            "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
            "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
            "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
            "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
            "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
            "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
            "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
            "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming",
            "District of Columbia"),
  state_abbr = c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                  "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                  "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                  "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                  "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
                  "DC"),
  fips = c("01", "02", "04", "05", "06", "08", "09", "10", "12", "13",
           "15", "16", "17", "18", "19", "20", "21", "22", "23", "24",
           "25", "26", "27", "28", "29", "30", "31", "32", "33", "34",
           "35", "36", "37", "38", "39", "40", "41", "42", "44", "45",
           "46", "47", "48", "49", "50", "51", "53", "54", "55", "56",
           "11")
)

state_panel <- all_states %>%
  left_join(dr_adoption %>% select(state, dr_year), by = "state") %>%
  mutate(dr_year = replace_na(dr_year, 0))

cat(sprintf("Never-adopters: %d states\n", sum(state_panel$dr_year == 0)))

# ============================================================
# 2. Fetch Kids Count Data (Real State-Level Data)
# ============================================================
cat("\n--- Fetching Kids Count Data ---\n")

# Indicator 6222: Victims by maltreatment type (state-level, 2000-2014)
resp_victims <- GET("https://datacenter.aecf.org/rawdata.axd?ind=6222&dtm=431", timeout(60))
stopifnot("Kids Count victim data failed" = status_code(resp_victims) == 200)
cat(sprintf("Victim data: HTTP %d, %d bytes\n", status_code(resp_victims),
            length(content(resp_victims, "raw"))))

tmp_v <- tempfile(fileext = ".xlsx")
writeBin(content(resp_victims, "raw"), tmp_v)
kc_victims <- read_excel(tmp_v, sheet = 1)
file.remove(tmp_v)

cat(sprintf("  Parsed: %d rows, columns: %s\n", nrow(kc_victims),
            paste(names(kc_victims), collapse = ", ")))

# Indicator 6224: Victim rates (state-level, 2000-2014)
resp_rates <- GET("https://datacenter.aecf.org/rawdata.axd?ind=6224&dtm=431", timeout(60))
stopifnot("Kids Count rate data failed" = status_code(resp_rates) == 200)

tmp_r <- tempfile(fileext = ".xlsx")
writeBin(content(resp_rates, "raw"), tmp_r)
kc_rates <- read_excel(tmp_r, sheet = 1)
file.remove(tmp_r)

cat(sprintf("  Rate data: %d rows\n", nrow(kc_rates)))

# Indicator 6223: Referrals (state-level, 2000-2014)
resp_refs <- GET("https://datacenter.aecf.org/rawdata.axd?ind=6223&dtm=431", timeout(60))
stopifnot("Kids Count referral data failed" = status_code(resp_refs) == 200)

tmp_ref <- tempfile(fileext = ".xlsx")
writeBin(content(resp_refs, "raw"), tmp_ref)
kc_referrals <- read_excel(tmp_ref, sheet = 1)
file.remove(tmp_ref)

cat(sprintf("  Referral data: %d rows\n", nrow(kc_referrals)))

# ============================================================
# 3. Parse Kids Count: Total Victims by State-Year
# ============================================================
cat("\n--- Parsing victim counts ---\n")

# Total victim numbers by state-year
state_victims <- kc_victims %>%
  filter(LocationType == "State",
         Category == "Total",
         DataFormat == "Number") %>%
  mutate(
    year = as.integer(TimeFrame),
    victims = as.numeric(Data)
  ) %>%
  filter(!is.na(victims)) %>%
  select(state = Location, year, victims)

cat(sprintf("Total victim counts: %d state-year obs, %d states, years %d-%d\n",
            nrow(state_victims), n_distinct(state_victims$state),
            min(state_victims$year), max(state_victims$year)))

# ============================================================
# 4. Parse Kids Count: Maltreatment by Type (for decomposition)
# ============================================================
cat("\n--- Parsing maltreatment types ---\n")

# Neglect and Physical abuse percentages
type_data <- kc_victims %>%
  filter(LocationType == "State",
         Category %in% c("Neglect", "Physical abuse", "Sexual abuse"),
         DataFormat == "Percent") %>%
  mutate(
    year = as.integer(TimeFrame),
    pct = as.numeric(Data)
  ) %>%
  filter(!is.na(pct)) %>%
  select(state = Location, year, type = Category, pct)

# Pivot wider
type_wide <- type_data %>%
  pivot_wider(names_from = type, values_from = pct,
              names_prefix = "pct_") %>%
  rename(pct_neglect = `pct_Neglect`,
         pct_physical = `pct_Physical abuse`,
         pct_sexual = `pct_Sexual abuse`)

cat(sprintf("Type decomposition: %d state-year obs\n", nrow(type_wide)))

# Compute type-specific victim counts
type_victims <- state_victims %>%
  left_join(type_wide, by = c("state", "year")) %>%
  mutate(
    victims_neglect = victims * pct_neglect / 100,
    victims_physical = victims * pct_physical / 100,
    victims_sexual = victims * pct_sexual / 100
  )

# ============================================================
# 5. Parse Kids Count: Referrals by State-Year
# ============================================================
cat("\n--- Parsing referrals ---\n")

state_referrals <- kc_referrals %>%
  filter(LocationType == "State",
         Gender == "Total",
         DataFormat == "Number") %>%
  mutate(
    year = as.integer(TimeFrame),
    referrals = as.numeric(Data)
  ) %>%
  filter(!is.na(referrals)) %>%
  select(state = Location, year, referrals)

cat(sprintf("Referral counts: %d state-year obs\n", nrow(state_referrals)))

# ============================================================
# 6. Parse Kids Count: Victim Rates per 1,000
# ============================================================
cat("\n--- Parsing victim rates ---\n")

state_rates_kc <- kc_rates %>%
  filter(LocationType == "State",
         DataFormat == "Number") %>%
  mutate(
    year = as.integer(TimeFrame),
    victim_rate = as.numeric(Data)
  ) %>%
  filter(!is.na(victim_rate)) %>%
  select(state = Location, year, victim_rate)

# The "Percent" format in 6224 gives the rate as a percentage of children
# Convert to per 1,000 by multiplying by 10
state_rates_kc <- kc_rates %>%
  filter(LocationType == "State",
         DataFormat == "Percent") %>%
  mutate(
    year = as.integer(TimeFrame),
    victim_rate = as.numeric(Data) * 10  # Convert from % to per 1,000
  ) %>%
  filter(!is.na(victim_rate)) %>%
  select(state = Location, year, victim_rate)

cat(sprintf("Victim rates (per 1,000): %d state-year obs\n", nrow(state_rates_kc)))
cat(sprintf("  Mean rate: %.2f per 1,000\n", mean(state_rates_kc$victim_rate)))

# ============================================================
# 7. Census Child Population
# ============================================================
census_api_key <- Sys.getenv("CENSUS_API_KEY")
pop_data <- tibble()

if (nchar(census_api_key) > 0) {
  cat("\nFetching Census child population (B09001_001E)...\n")
  years_to_fetch <- 2005:2014

  pop_data <- map_dfr(years_to_fetch, function(yr) {
    url <- sprintf(
      "https://api.census.gov/data/%d/acs/acs1?get=NAME,B09001_001E&for=state:*&key=%s",
      yr, census_api_key
    )
    resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)
    if (is.null(resp) || status_code(resp) != 200) return(tibble())
    json <- content(resp, "text", encoding = "UTF-8")
    mat <- fromJSON(json)
    tibble(state_name = mat[-1, 1], child_pop = as.numeric(mat[-1, 2]),
           fips = mat[-1, 3], year = yr)
  })

  if (nrow(pop_data) > 0) {
    cat(sprintf("  Census child pop: %d state-year obs (%d-%d)\n",
                nrow(pop_data), min(pop_data$year), max(pop_data$year)))
  }
}

# ============================================================
# 8. National-level data for context
# ============================================================
national_data <- tribble(
  ~year, ~referrals_national, ~victims_national, ~victim_rate_national,
  2000, 2861000, 862479, 12.2,
  2001, 2673000, 903395, 12.4,
  2002, 2610000, 896256, 12.3,
  2003, 2590000, 906193, 12.4,
  2004, 3509000, 869765, 11.9,
  2005, 3575000, 899363, 12.1,
  2006, 3573000, 905041, 12.1,
  2007, 3478000, 794069, 10.6,
  2008, 3324000, 772051, 10.3,
  2009, 3285000, 763440, 10.1,
  2010, 3313000, 698925, 9.2,
  2011, 3380000, 683080, 9.1,
  2012, 3405000, 686537, 9.2,
  2013, 3185000, 679076, 9.1,
  2014, 3248000, 702208, 9.4
)

# Child fatality data (always investigated, never diverted)
child_fatalities <- tribble(
  ~year, ~fatalities_national, ~fatality_rate_per_100k,
  2000, 1236, 1.71,
  2001, 1300, 1.81,
  2002, 1400, 1.96,
  2003, 1500, 2.00,
  2004, 1490, 2.03,
  2005, 1460, 1.96,
  2006, 1530, 2.04,
  2007, 1760, 2.35,
  2008, 1740, 2.33,
  2009, 1770, 2.34,
  2010, 1560, 2.07,
  2011, 1570, 2.10,
  2012, 1640, 2.20,
  2013, 1520, 2.04,
  2014, 1580, 2.13
)

# ============================================================
# 9. Build Analysis Panel
# ============================================================
cat("\n--- Building analysis panel ---\n")

# Merge victim counts with referrals, types, and rates
analysis_raw <- state_victims %>%
  left_join(state_referrals, by = c("state", "year")) %>%
  left_join(type_wide, by = c("state", "year")) %>%
  left_join(state_rates_kc, by = c("state", "year"))

# Where KidsCount rate is missing, compute from Census pop
if (nrow(pop_data) > 0) {
  analysis_raw <- analysis_raw %>%
    left_join(pop_data %>% select(state_name, year, child_pop),
              by = c("state" = "state_name", "year")) %>%
    mutate(
      victim_rate_computed = ifelse(!is.na(child_pop) & child_pop > 0,
                                    (victims / child_pop) * 1000,
                                    NA_real_),
      victim_rate = coalesce(victim_rate, victim_rate_computed)
    )
}

# Merge with DR adoption dates
analysis_df <- analysis_raw %>%
  left_join(state_panel %>% select(state, state_abbr, fips, dr_year), by = "state") %>%
  filter(!is.na(state_abbr)) %>%  # Drop if state name doesn't match
  mutate(
    dr_adopted = as.integer(!is.na(dr_year) & dr_year > 0 & year >= dr_year),
    first_treat = dr_year,
    state_id = as.numeric(factor(state)),
    # Victim-to-referral ratio
    victim_referral_ratio = ifelse(!is.na(referrals) & referrals > 0,
                                   victims / referrals, NA_real_),
    # Type-specific victim counts
    victims_neglect = victims * pct_neglect / 100,
    victims_physical = victims * pct_physical / 100
  )

# Drop observations with missing victim rate
analysis_df <- analysis_df %>% filter(!is.na(victim_rate))

# Validate
cat(sprintf("\n=== Final analysis dataset ===\n"))
cat(sprintf("  Observations: %d\n", nrow(analysis_df)))
cat(sprintf("  States: %d\n", n_distinct(analysis_df$state)))
cat(sprintf("  Years: %d-%d\n", min(analysis_df$year), max(analysis_df$year)))
cat(sprintf("  Treated states in panel: %d\n",
            n_distinct(analysis_df$state[analysis_df$first_treat > 0])))
cat(sprintf("  Never-treated states: %d\n",
            n_distinct(analysis_df$state[analysis_df$first_treat == 0])))
cat(sprintf("  Obs with referral data: %d\n",
            sum(!is.na(analysis_df$referrals))))
cat(sprintf("  Obs with type decomposition: %d\n",
            sum(!is.na(analysis_df$pct_neglect))))

# ============================================================
# 10. Save everything
# ============================================================
saveRDS(analysis_df, "../data/analysis_panel.rds")
saveRDS(national_data, "../data/national_data.rds")
saveRDS(child_fatalities, "../data/child_fatalities.rds")
saveRDS(dr_adoption, "../data/dr_adoption.rds")

cat("\n=== Data saved ===\n")
