## ============================================================================
## 01_fetch_data.R — Fetch state-level crime data and NIBRS adoption timeline
## Sources: Disaster Center (compiled FBI UCR 1960-2020), FBI UCR 2017-2019
## ============================================================================

paper_dir <- here::here()
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
setwd(here::here())
source("code/00_packages.R")

if (!requireNamespace("rvest", quietly = TRUE))
  install.packages("rvest", repos = "https://cloud.r-project.org")
library(rvest)

cat("\n=== FETCHING STATE-LEVEL CRIME DATA ===\n")

## ---------------------------------------------------------------------------
## 1. Disaster Center: State-level FBI UCR data 1960-2020
##    Columns: Year, Population, Index, Violent, Property, Murder,
##    Forcible Rape, Robbery, Aggravated Assault, Burglary, Larceny, Vehicle Theft
## ---------------------------------------------------------------------------

state_urls <- tribble(
  ~state, ~url_slug,
  "Alabama", "alcrime", "Alaska", "akcrime", "Arizona", "azcrime",
  "Arkansas", "arcrime", "California", "cacrime", "Colorado", "cocrime",
  "Connecticut", "ctcrime", "Delaware", "decrime", "Florida", "flcrime",
  "Georgia", "gacrime", "Hawaii", "hicrime", "Idaho", "idcrime",
  "Illinois", "ilcrime", "Indiana", "incrime", "Iowa", "iacrime",
  "Kansas", "kscrime", "Kentucky", "kycrime", "Louisiana", "lacrime",
  "Maine", "mecrime", "Maryland", "mdcrime", "Massachusetts", "macrime",
  "Michigan", "micrime", "Minnesota", "mncrime", "Mississippi", "mscrime",
  "Missouri", "mocrime", "Montana", "mtcrime", "Nebraska", "necrime",
  "Nevada", "nvcrime", "New Hampshire", "nhcrime", "New Jersey", "njcrime",
  "New Mexico", "nmcrime", "New York", "nycrime", "North Carolina", "nccrime",
  "North Dakota", "ndcrime", "Ohio", "ohcrime", "Oklahoma", "okcrime",
  "Oregon", "orcrime", "Pennsylvania", "pacrime", "Rhode Island", "ricrime",
  "South Carolina", "sccrime", "South Dakota", "sdcrime",
  "Tennessee", "tncrime", "Texas", "txcrime", "Utah", "utcrime",
  "Vermont", "vtcrime", "Virginia", "vacrime", "Washington", "wacrime",
  "West Virginia", "wvcrime", "Wisconsin", "wicrime", "Wyoming", "wycrime"
)

parse_disaster_center <- function(state, url_slug) {
  url <- paste0("https://www.disastercenter.com/crime/", url_slug, ".htm")
  page <- tryCatch(read_html(url), error = function(e) {
    cat("  FAILED:", state, "-", conditionMessage(e), "\n")
    return(NULL)
  })
  if (is.null(page)) return(NULL)

  # Extract tables from the page
  tables <- html_table(page, fill = TRUE, header = FALSE)
  if (length(tables) == 0) return(NULL)

  # Find the table with Year/Population/crime data
  target <- NULL
  for (tbl in tables) {
    # Look for a table that has years (4-digit numbers) in the first column
    col1 <- as.character(tbl[[1]])
    if (any(grepl("^(19|20)\\d{2}$", trimws(col1)))) {
      target <- tbl
      break
    }
  }
  if (is.null(target)) return(NULL)

  # Standard column mapping for Disaster Center:
  # Col 1: Year, Col 2: Population, Col 3: Index (total),
  # Col 4: Violent, Col 5: Property, Col 6: Murder,
  # Col 7: Rape, Col 8: Robbery, Col 9: Aggravated Assault,
  # Col 10: Burglary, Col 11: Larceny, Col 12: Vehicle Theft

  clean_num <- function(x) {
    x <- gsub(",", "", as.character(x))
    x <- gsub("[^0-9.]", "", x)
    suppressWarnings(as.numeric(x))
  }

  # Filter to rows that look like years (1960-2025)
  year_vals <- clean_num(target[[1]])
  valid_rows <- which(!is.na(year_vals) & year_vals >= 1960 & year_vals <= 2025)

  if (length(valid_rows) < 5) return(NULL)

  data_block <- target[valid_rows, ]

  ncols <- ncol(data_block)
  result <- tibble(
    state = state,
    year = as.integer(clean_num(data_block[[1]])),
    population = clean_num(data_block[[2]]),
    violent_crime = clean_num(data_block[[if(ncols >= 4) 4 else 3]]),
    property_crime = clean_num(data_block[[if(ncols >= 5) 5 else 3]]),
    murder = clean_num(data_block[[if(ncols >= 6) 6 else 3]]),
    robbery = clean_num(data_block[[if(ncols >= 8) 8 else 3]]),
    agg_assault = clean_num(data_block[[if(ncols >= 9) 9 else 3]]),
    burglary = clean_num(data_block[[if(ncols >= 10) 10 else 3]]),
    larceny = clean_num(data_block[[if(ncols >= 11) 11 else 3]]),
    motor_theft = clean_num(data_block[[if(ncols >= 12) 12 else 3]])
  )

  # Keep only 2000-2020 for our analysis
  result <- result %>%
    filter(year >= 2000 & year <= 2020) %>%
    filter(!is.na(population) & population > 0)

  return(result)
}

all_states <- list()
for (i in seq_len(nrow(state_urls))) {
  st <- state_urls$state[i]
  slug <- state_urls$url_slug[i]
  cat("Fetching", st, "...\n")
  df <- parse_disaster_center(st, slug)
  if (!is.null(df) && nrow(df) > 0) {
    all_states[[st]] <- df
    cat("  OK:", nrow(df), "years\n")
  } else {
    cat("  WARNING: No data for", st, "\n")
  }
  Sys.sleep(0.5)
}

state_crime <- bind_rows(all_states)
cat("\n=== DISASTER CENTER DATA ===\n")
cat("Total observations:", nrow(state_crime), "\n")
cat("States:", n_distinct(state_crime$state), "\n")
cat("Years:", min(state_crime$year), "-", max(state_crime$year), "\n")

if (nrow(state_crime) < 200) {
  stop("FATAL: Insufficient crime data from Disaster Center. Cannot proceed.")
}

## ---------------------------------------------------------------------------
## 2. NIBRS Adoption Timeline
## ---------------------------------------------------------------------------

nibrs_adoption <- tribble(
  ~state, ~nibrs_year,
  "Alabama", 2020L,
  "Alaska", 2017L,
  "Arizona", 2020L,
  "Arkansas", 2013L,
  "California", 2022L,
  "Colorado", 2013L,
  "Connecticut", 2015L,
  "Delaware", 2005L,
  "Florida", 2021L,
  "Georgia", 2020L,
  "Hawaii", 2021L,
  "Idaho", 1996L,
  "Illinois", 2021L,
  "Indiana", 2019L,
  "Iowa", 1996L,
  "Kansas", 2006L,
  "Kentucky", 2012L,
  "Louisiana", 2014L,
  "Maine", 2008L,
  "Maryland", 2020L,
  "Massachusetts", 2014L,
  "Michigan", 2007L,
  "Minnesota", 2016L,
  "Mississippi", 2018L,
  "Missouri", 2017L,
  "Montana", 2009L,
  "Nebraska", 2010L,
  "Nevada", 2020L,
  "New Hampshire", 2009L,
  "New Jersey", 2021L,
  "New Mexico", 2019L,
  "New York", 2021L,
  "North Carolina", 2018L,
  "North Dakota", 2003L,
  "Ohio", 2011L,
  "Oklahoma", 2016L,
  "Oregon", 2010L,
  "Pennsylvania", 2019L,
  "Rhode Island", 2014L,
  "South Carolina", 1991L,
  "South Dakota", 2001L,
  "Tennessee", 1998L,
  "Texas", 2019L,
  "Utah", 2004L,
  "Vermont", 2005L,
  "Virginia", 1998L,
  "Washington", 2012L,
  "West Virginia", 2012L,
  "Wisconsin", 2014L,
  "Wyoming", 2016L
)

## ---------------------------------------------------------------------------
## 3. Merge and construct analysis panel
## ---------------------------------------------------------------------------

panel <- state_crime %>%
  left_join(nibrs_adoption, by = "state") %>%
  mutate(nibrs_year = replace_na(nibrs_year, 9999L))

# Treatment indicators
panel <- panel %>%
  mutate(
    treated = as.integer(year >= nibrs_year),
    # CS-DiD: first_treat = 0 for never-treated (in sample window)
    first_treat = ifelse(nibrs_year > 2020 | nibrs_year < 2000, 0L, nibrs_year)
  )

# Crime rates per 100K
panel <- panel %>%
  mutate(
    violent_rate = (violent_crime / population) * 100000,
    murder_rate = (murder / population) * 100000,
    robbery_rate = (robbery / population) * 100000,
    assault_rate = (agg_assault / population) * 100000,
    property_rate = (property_crime / population) * 100000,
    burglary_rate = (burglary / population) * 100000,
    larceny_rate = (larceny / population) * 100000,
    motor_rate = (motor_theft / population) * 100000
  )

# Log-transform rates
rate_cols <- c("violent_rate", "murder_rate", "robbery_rate", "assault_rate",
               "property_rate", "burglary_rate", "larceny_rate", "motor_rate")
for (col in rate_cols) {
  panel[[paste0("log_", col)]] <- log(pmax(panel[[col]], 0.01))
}

# State numeric ID for fixest
panel <- panel %>%
  mutate(state_id = as.integer(factor(state)))

## ---------------------------------------------------------------------------
## 4. Validation
## ---------------------------------------------------------------------------

stopifnot("No data" = nrow(panel) > 0)
stopifnot("Need >= 40 states" = n_distinct(panel$state) >= 40)
stopifnot("Need >= 10 years" = n_distinct(panel$year) >= 10)
stopifnot("Missing NIBRS" = all(!is.na(panel$nibrs_year)))

# Count treatment groups
n_treated_in_sample <- panel %>%
  filter(first_treat > 0) %>%
  distinct(state) %>%
  nrow()

n_never <- panel %>%
  filter(first_treat == 0) %>%
  distinct(state) %>%
  nrow()

cat("\n=== FINAL PANEL SUMMARY ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated (NIBRS adopted 2000-2020):", n_treated_in_sample, "\n")
cat("Never-treated (in sample):", n_never, "\n")
cat("\nAdoption cohort distribution:\n")
panel %>%
  filter(first_treat > 0) %>%
  distinct(state, first_treat) %>%
  count(first_treat) %>%
  print(n = 30)

# Save
dir.create("data", showWarnings = FALSE)
saveRDS(panel, "data/state_crime_panel.rds")
write_csv(panel, "data/state_crime_panel.csv")
cat("\nSaved to data/state_crime_panel.rds\n")
