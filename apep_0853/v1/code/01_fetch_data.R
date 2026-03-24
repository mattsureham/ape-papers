## 01_fetch_data.R — Fetch Census Nonemployer Statistics + treatment coding
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot(nchar(census_key) > 0)

# =============================================================================
# PART 1: Cottage Food Law Treatment Coding
# =============================================================================
# Treatment = year of first enactment OR major legislative expansion of
# cottage food laws, for events occurring 2012-2022 (our panel window).
# Sources: Institute for Justice "Baking Bad" (2023), Harvard Food Law &
# Policy Clinic (2013), National Agricultural Law Center state compilations,
# Farm-to-Consumer Legal Defense Fund, individual state legislative records.
#
# Design: States with pre-2012 cottage food laws and no major expansion
# during the panel window serve as "always treated" → used as never-treated
# comparison in Callaway-Sant'Anna (since their treatment predates our panel).
# States with events during 2012-2022 are the staggered treated group.
# =============================================================================

treatment_data <- tribble(
  ~state_fips, ~state_abbr, ~state_name,       ~treat_year, ~event_type,
  "01", "AL", "Alabama",              2014L, "first_adoption",
  "02", "AK", "Alaska",               NA_integer_, "pre_panel",    # pre-2010 exemptions; major statute 2024
  "04", "AZ", "Arizona",              2019L, "major_expansion",  # HB 2486 expanded to TCS foods
  "05", "AR", "Arkansas",             2011L, "first_adoption",   # Act 399 of 2011; pre-panel
  "06", "CA", "California",           2013L, "major_expansion",  # AB 1616 cottage food operation
  "08", "CO", "Colorado",             2012L, "first_adoption",   # SB 12-048 Cottage Food Act
  "09", "CT", "Connecticut",          NA_integer_, "pre_panel",
  "10", "DE", "Delaware",             2015L, "first_adoption",   # HB 25 cottage food exemption
  "11", "DC", "District of Columbia", 2013L, "first_adoption",   # Cottage Food Exemption Act
  "12", "FL", "Florida",              2011L, "first_adoption",   # CS/HB 7209 cottage food expansion; pre-panel
  "13", "GA", "Georgia",              2015L, "major_expansion",  # SB 123 raised cap & expanded venues
  "15", "HI", "Hawaii",               NA_integer_, "never_treated",  # no cottage food law until 2024
  "16", "ID", "Idaho",                NA_integer_, "pre_panel",
  "17", "IL", "Illinois",             2012L, "first_adoption",   # Cottage Food Operation Act (SB 840)
  "18", "IN", "Indiana",              NA_integer_, "pre_panel",    # 2009 law, no major expansion
  "19", "IA", "Iowa",                 2017L, "major_expansion",  # HF 560 expanded products/venues
  "20", "KS", "Kansas",               NA_integer_, "pre_panel",
  "21", "KY", "Kentucky",             2015L, "major_expansion",  # SB 207 Microprocessor Permit Act
  "22", "LA", "Louisiana",            2014L, "first_adoption",   # RS 40:4.11 cottage food law
  "23", "ME", "Maine",                2017L, "major_expansion",  # LD 725 Food Sovereignty Act
  "24", "MD", "Maryland",             2012L, "first_adoption",   # SB 677/HB 1207
  "25", "MA", "Massachusetts",        NA_integer_, "pre_panel",
  "26", "MI", "Michigan",             NA_integer_, "pre_panel",    # 2010 Cottage Food Law; pre-panel if using 2012 start
  "27", "MN", "Minnesota",            2015L, "first_adoption",   # SF 803 Cottage Food Exemption
  "28", "MS", "Mississippi",          2013L, "first_adoption",   # SB 2498
  "29", "MO", "Missouri",             2019L, "major_expansion",  # HB 433 raised cap to $50K
  "30", "MT", "Montana",              2015L, "first_adoption",   # HB 564
  "31", "NE", "Nebraska",             NA_integer_, "pre_panel",
  "32", "NV", "Nevada",               2015L, "major_expansion",  # SB 240 created cottage food operation
  "33", "NH", "New Hampshire",        NA_integer_, "pre_panel",
  "34", "NJ", "New Jersey",           2021L, "first_adoption",   # A-3388 (last state to adopt)
  "35", "NM", "New Mexico",           NA_integer_, "pre_panel",
  "36", "NY", "New York",             NA_integer_, "pre_panel",
  "37", "NC", "North Carolina",       2012L, "major_expansion",  # SB 853 expanded products
  "38", "ND", "North Dakota",         2017L, "major_expansion",  # HB 1433
  "39", "OH", "Ohio",                 NA_integer_, "pre_panel",
  "40", "OK", "Oklahoma",             2013L, "first_adoption",   # HB 2170 Home Bakery Act
  "41", "OR", "Oregon",               NA_integer_, "pre_panel",
  "42", "PA", "Pennsylvania",         NA_integer_, "pre_panel",    # Act 106 of 2010; pre-panel
  "44", "RI", "Rhode Island",         NA_integer_, "pre_panel",
  "45", "SC", "South Carolina",       NA_integer_, "pre_panel",
  "46", "SD", "South Dakota",         NA_integer_, "pre_panel",
  "47", "TN", "Tennessee",            2017L, "major_expansion",  # HB 660/SB 811
  "48", "TX", "Texas",                2013L, "major_expansion",  # SB 1766 expanded to online/venues
  "49", "UT", "Utah",                 2018L, "major_expansion",  # SB 108 Utah Food Freedom Act
  "50", "VT", "Vermont",              NA_integer_, "pre_panel",
  "51", "VA", "Virginia",             2013L, "major_expansion",  # expanded products and raised cap
  "53", "WA", "Washington",           NA_integer_, "pre_panel",
  "54", "WV", "West Virginia",        2016L, "major_expansion",  # HB 4273
  "55", "WI", "Wisconsin",            NA_integer_, "pre_panel",
  "56", "WY", "Wyoming",              2015L, "major_expansion"   # SF 15 Food Freedom Act
)

cat("Treatment coding: ", sum(!is.na(treatment_data$treat_year)), "treated states\n")
cat("Pre-panel (comparison): ", sum(is.na(treatment_data$treat_year) & treatment_data$event_type == "pre_panel"), "\n")
cat("Never treated: ", sum(treatment_data$event_type == "never_treated"), "\n")

# =============================================================================
# PART 2: Census Nonemployer Statistics API (2012-2022)
# =============================================================================
# Endpoints: state-level NAICS 311 (food manufacturing) establishments & receipts
# Also fetch NAICS 3118 (bakeries/tortilla) for mechanism test
# =============================================================================

fetch_nonemp <- function(year, naics_code) {
  base_url <- sprintf("https://api.census.gov/data/%d/nonemp", year)

  # NAICS code variable changed: NAICS2012 for 2012-2016, NAICS2017 for 2017+
  if (year <= 2016) {
    naics_var <- "NAICS2012"
  } else {
    naics_var <- "NAICS2017"
  }

  url <- paste0(base_url,
    "?get=NESTAB,NRCPTOT,", naics_var,
    "&for=state:*",
    "&", naics_var, "=", naics_code,
    "&key=", census_key)

  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    warning(sprintf("NES API failed for year=%d, naics=%s (HTTP %d)", year, naics_code, httr::status_code(resp)))
    return(NULL)
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- parsed[1, ]
  # Standardize column names
  names(df)[grep("NAICS", names(df))] <- "NAICS"
  df$year <- year
  df$naics <- naics_code
  df
}

# Fetch NAICS 311 (food manufacturing) for all years
cat("Fetching Nonemployer Statistics NAICS 311...\n")
years <- 2012:2022
nes_311_list <- list()
for (yr in years) {
  cat(sprintf("  %d...", yr))
  result <- fetch_nonemp(yr, "311")
  if (!is.null(result)) {
    nes_311_list[[as.character(yr)]] <- result
    cat(" OK\n")
  } else {
    cat(" FAILED\n")
  }
  Sys.sleep(0.5)  # rate limiting
}

nes_311 <- bind_rows(nes_311_list)
stopifnot(nrow(nes_311) > 0)
cat(sprintf("NAICS 311: %d state-year observations\n", nrow(nes_311)))

# Fetch NAICS 3118 (bakeries/tortilla) for mechanism
cat("Fetching Nonemployer Statistics NAICS 3118...\n")
nes_3118_list <- list()
for (yr in years) {
  cat(sprintf("  %d...", yr))
  result <- fetch_nonemp(yr, "3118")
  if (!is.null(result)) {
    nes_3118_list[[as.character(yr)]] <- result
    cat(" OK\n")
  } else {
    cat(" FAILED\n")
  }
  Sys.sleep(0.5)
}

nes_3118 <- bind_rows(nes_3118_list)
cat(sprintf("NAICS 3118: %d state-year observations\n", nrow(nes_3118)))

# =============================================================================
# PART 3: County Business Patterns API (placebo: employer establishments)
# =============================================================================

fetch_cbp <- function(year, naics_code) {
  base_url <- sprintf("https://api.census.gov/data/%d/cbp", year)

  if (year <= 2016) {
    naics_var <- "NAICS2012"
  } else {
    naics_var <- "NAICS2017"
  }

  url <- paste0(base_url,
    "?get=ESTAB,EMP",
    "&for=state:*",
    "&", naics_var, "=", naics_code,
    "&key=", census_key)

  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    warning(sprintf("CBP API failed for year=%d (HTTP %d)", year, httr::status_code(resp)))
    return(NULL)
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- parsed[1, ]
  df$year <- year
  df
}

cat("Fetching County Business Patterns NAICS 311...\n")
cbp_list <- list()
for (yr in years) {
  cat(sprintf("  %d...", yr))
  result <- fetch_cbp(yr, "311")
  if (!is.null(result)) {
    cbp_list[[as.character(yr)]] <- result
    cat(" OK\n")
  } else {
    cat(" FAILED\n")
  }
  Sys.sleep(0.5)
}

cbp_311 <- bind_rows(cbp_list)
cat(sprintf("CBP NAICS 311: %d state-year observations\n", nrow(cbp_311)))

# BFS not used — not available by NAICS at state level
bfs_all <- data.frame()

# =============================================================================
# PART 5: State population data (for per-capita normalization)
# =============================================================================

fetch_pop <- function(year) {
  if (year >= 2020) {
    base_url <- sprintf("https://api.census.gov/data/%d/pep/population", year)
    url <- paste0(base_url, "?get=POP_2020,NAME&for=state:*&key=", census_key)
  } else if (year >= 2015) {
    base_url <- "https://api.census.gov/data/2019/pep/charagegroups"
    url <- paste0(base_url, "?get=POP,NAME&for=state:*&key=", census_key)
  } else {
    base_url <- sprintf("https://api.census.gov/data/%d/pep/population", year)
    url <- paste0(base_url, "?get=POP,DATE_DESC,NAME&for=state:*&DATE_CODE=", year - 2009, "&key=", census_key)
  }
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    return(NULL)
  }
  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- parsed[1, ]
  df$year <- year
  df
}

# Use ACS 1-year for population; 2020 unavailable (COVID), interpolate
cat("Fetching state population estimates...\n")
pop_list <- list()
for (yr in 2012:2022) {
  if (yr == 2020) {
    cat(sprintf("  %d SKIPPED (ACS not released)\n", yr))
    next
  }
  url <- paste0("https://api.census.gov/data/", yr, "/acs/acs1",
    "?get=B01001_001E,NAME&for=state:*&key=", census_key)
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(raw)
    df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
    colnames(df) <- parsed[1, ]
    df$year <- yr
    pop_list[[as.character(yr)]] <- df
    cat(sprintf("  %d OK\n", yr))
  } else {
    cat(sprintf("  %d FAILED\n", yr))
  }
  Sys.sleep(0.3)
}

pop_all <- bind_rows(pop_list)

# Interpolate 2020 population as average of 2019 and 2021
pop_2019 <- pop_all %>% filter(year == 2019) %>% select(state, B01001_001E, NAME)
pop_2021 <- pop_all %>% filter(year == 2021) %>% select(state, B01001_001E, NAME)
if (nrow(pop_2019) > 0 && nrow(pop_2021) > 0) {
  pop_2020 <- pop_2019 %>%
    inner_join(pop_2021, by = c("state", "NAME"), suffix = c("_19", "_21")) %>%
    mutate(
      B01001_001E = as.character(round((as.numeric(B01001_001E_19) + as.numeric(B01001_001E_21)) / 2)),
      year = 2020L
    ) %>%
    select(B01001_001E, NAME, state, year)
  pop_all <- bind_rows(pop_all, pop_2020)
  cat("  2020 interpolated from 2019+2021\n")
}

cat(sprintf("Population: %d state-year obs\n", nrow(pop_all)))

# =============================================================================
# SAVE
# =============================================================================

save(treatment_data, nes_311, nes_3118, cbp_311, bfs_all, pop_all,
     file = "../data/raw_data.RData")
cat("All data saved to data/raw_data.RData\n")
