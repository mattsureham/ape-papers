##############################################################################
# 01_fetch_data.R — Fetch ACS PUMS microdata for DV eligibility analysis
# APEP-1082: The Lottery Channel
##############################################################################

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# DV eligibility timeline (known institutional facts)
# ===========================================================================

cat("=== Constructing DV eligibility timeline ===\n")

dv_eligibility <- tribble(
  ~country,       ~pobp_code, ~ineligible_from_dv_year, ~region,
  # Treated countries (lost DV eligibility)
  "Nigeria",      440,        2015,                     "Africa",
  "Bangladesh",   150,        2013,                     "Asia",
  "Brazil",       362,        2012,                     "Americas",
  "Pakistan",     462,        2012,                     "Asia",
  "Peru",         354,        2018,                     "Americas",
  # Control countries (always eligible during sample)
  "Ghana",        442,        NA,                       "Africa",
  "Kenya",        450,        NA,                       "Africa",
  "Ethiopia",     432,        NA,                       "Africa",
  "Cameroon",     428,        NA,                       "Africa",
  "Nepal",        465,        NA,                       "Asia",
  "Sri Lanka",    468,        NA,                       "Asia",
  "Albania",      212,        NA,                       "Europe",
  "Ukraine",      226,        NA,                       "Europe",
  "Uzbekistan",   229,        NA,                       "Asia",
  "Egypt",        436,        NA,                       "Africa",
  "Tanzania",     470,        NA,                       "Africa",
  "Sierra Leone", 466,        NA,                       "Africa",
  "Liberia",      448,        NA,                       "Africa",
  "Togo",         474,        NA,                       "Africa"
)

write_csv(dv_eligibility, file.path(data_dir, "dv_eligibility.csv"))
cat(sprintf("  Eligibility timeline: %d treated, %d control countries\n",
            sum(!is.na(dv_eligibility$ineligible_from_dv_year)),
            sum(is.na(dv_eligibility$ineligible_from_dv_year))))

# ===========================================================================
# ACS PUMS microdata via Census API
# ===========================================================================

cat("\n=== Fetching ACS PUMS microdata ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") {
  stop("FATAL: CENSUS_API_KEY not set in .env. Cannot proceed.")
}

pobp_codes <- dv_eligibility$pobp_code
acs_all <- list()

for (yr in 2005:2023) {
  if (yr == 2020) {
    cat(sprintf("  Skipping %d (no 1-year ACS)\n", yr))
    next
  }

  base_url <- sprintf("https://api.census.gov/data/%d/acs/acs1/pums", yr)

  # Core variables
  vars <- "POBP,SCHL,WAGP,AGEP,SEX,PWGTP,NATIVITY"
  if (yr >= 2008) {
    vars <- paste0(vars, ",YOEP")
  }

  api_url <- sprintf("%s?get=%s&NATIVITY=2&key=%s", base_url, vars, census_key)

  tryCatch({
    resp <- httr::GET(api_url, httr::timeout(120))

    if (httr::status_code(resp) == 200) {
      raw <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(raw)

      # First row is column names
      col_names <- parsed[1, ]

      # Handle duplicate column names by making unique
      col_names <- make.unique(col_names)

      mat <- parsed[-1, , drop = FALSE]
      df <- as.data.frame(mat, stringsAsFactors = FALSE)
      colnames(df) <- col_names

      # Convert numeric columns
      num_cols <- c("POBP", "SCHL", "WAGP", "AGEP", "SEX", "PWGTP")
      for (col in num_cols) {
        if (col %in% names(df)) {
          df[[col]] <- as.numeric(df[[col]])
        }
      }
      if ("YOEP" %in% names(df)) {
        df$YOEP <- as.numeric(df$YOEP)
      }

      df$survey_year <- yr

      # Filter to our countries of interest
      df <- df[df$POBP %in% pobp_codes, ]

      cat(sprintf("  ACS %d: %d records from target countries\n", yr, nrow(df)))
      acs_all[[as.character(yr)]] <- df
    } else {
      cat(sprintf("  FAILED: ACS %d (status %d)\n", yr, httr::status_code(resp)))
    }
  }, error = function(e) {
    cat(sprintf("  ERROR: ACS %d: %s\n", yr, e$message))
  })

  Sys.sleep(0.5)
}

# Combine all years
acs_micro <- bind_rows(acs_all)

if (nrow(acs_micro) == 0) {
  stop("FATAL: No ACS microdata retrieved. Cannot proceed.")
}

cat(sprintf("\n  Total ACS records: %d across %d years\n",
            nrow(acs_micro), n_distinct(acs_micro$survey_year)))

# Remove NATIVITY column (all are foreign-born)
acs_micro <- acs_micro %>% select(-any_of(c("NATIVITY", "NATIVITY.1")))

write_csv(acs_micro, file.path(data_dir, "acs_microdata.csv"))
cat(sprintf("  Saved: %s (%s MB)\n",
            file.path(data_dir, "acs_microdata.csv"),
            round(file.size(file.path(data_dir, "acs_microdata.csv")) / 1e6, 1)))

# ===========================================================================
# Validation
# ===========================================================================

cat("\n=== Data validation ===\n")

treated_counts <- acs_micro %>%
  filter(POBP %in% c(440, 150, 362, 462, 354)) %>%
  group_by(POBP) %>%
  summarise(n = n(), years = n_distinct(survey_year))

cat("Treated countries:\n")
print(treated_counts)

control_counts <- acs_micro %>%
  filter(!POBP %in% c(440, 150, 362, 462, 354)) %>%
  group_by(POBP) %>%
  summarise(n = n(), years = n_distinct(survey_year))

cat("\nControl countries:\n")
print(control_counts)

by_year <- acs_micro %>%
  group_by(survey_year) %>%
  summarise(n = n())

cat("\nRecords by year:\n")
print(by_year, n = 25)

cat("\n=== Data fetch complete ===\n")
