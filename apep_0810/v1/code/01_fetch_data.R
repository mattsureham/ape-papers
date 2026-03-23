## 01_fetch_data.R — Fetch QWI + DBPR lottery data + population
## apep_0810: Florida Liquor License Lottery and Business Formation

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_api_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_api_key) == 0) stop("CENSUS_API_KEY not set in .env")

# ============================================================
# 1. QWI DATA — Florida counties, NAICS 7224 + 7225
# ============================================================

fetch_qwi <- function(naics_code, year, quarter) {
  base_url <- "https://api.census.gov/data/timeseries/qwi/sa"

  params <- list(
    get = "Emp,EmpEnd,EmpS,EarnS,EarnBeg,sEmp,sEmpEnd,sEmpS,sEarnS",
    `for` = "county:*",
    `in` = "state:12",
    industry = naics_code,
    ownercode = "A05",
    sex = "0",
    agegrp = "A00",
    race = "A0",
    ethnicity = "A0",
    education = "E0",
    firmage = "0",
    firmsize = "0",
    seasonadj = "U",
    year = as.character(year),
    quarter = as.character(quarter),
    key = census_api_key
  )

  resp <- httr::GET(base_url, query = params)
  if (httr::status_code(resp) != 200) return(NULL)

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- parsed[1, ]
  df$year <- year
  df$quarter <- quarter
  df$naics <- naics_code
  return(df)
}

if (file.exists(file.path(data_dir, "qwi_florida.rds"))) {
  cat("QWI data already cached, loading...\n")
  qwi_df <- readRDS(file.path(data_dir, "qwi_florida.rds"))
} else {
  cat("Fetching QWI data for Florida counties...\n")
  all_qwi <- list()
  idx <- 1
  for (naics in c("7224", "7225")) {
    for (yr in 2012:2023) {
      for (qtr in 1:4) {
        cat(sprintf("  NAICS %s, %d Q%d\n", naics, yr, qtr))
        result <- fetch_qwi(naics, yr, qtr)
        if (!is.null(result)) { all_qwi[[idx]] <- result; idx <- idx + 1 }
        Sys.sleep(0.3)
      }
    }
  }
  qwi_df <- bind_rows(all_qwi)
  numeric_cols <- c("Emp", "EmpEnd", "EmpS", "EarnS", "EarnBeg")
  for (col in numeric_cols) {
    if (col %in% names(qwi_df)) qwi_df[[col]] <- as.numeric(qwi_df[[col]])
  }
  saveRDS(qwi_df, file.path(data_dir, "qwi_florida.rds"))
}

cat(sprintf("QWI: %d rows, %d counties\n", nrow(qwi_df), n_distinct(qwi_df$county)))

# ============================================================
# 2. PARSE AVAILABLE DBPR PDFs (for validation)
# ============================================================

pdf_dir <- file.path(data_dir, "lottery_pdfs")
dir.create(pdf_dir, showWarnings = FALSE)

# Parse 2020 winners PDF (already downloaded via system curl)
winners_2020_path <- file.path(pdf_dir, "winners_2020.pdf")
if (!file.exists(winners_2020_path)) {
  stop("FATAL: winners_2020.pdf not found. Download manually with system curl.")
}

cat("Parsing 2020 winners PDF...\n")
text_2020 <- pdftools::pdf_text(winners_2020_path)
all_text <- paste(text_2020, collapse = "\n")
lines <- strsplit(all_text, "\n")[[1]]
lines <- trimws(lines)

# Extract county-winner pairs: "COUNTY: [NUM] : [NAME],   Winners: [N]"
county_pattern <- "^COUNTY:\\s*\\d+\\s*:\\s*([A-Z\\s\\-\\.]+),\\s*Winners:\\s*(\\d+)"
county_matches <- regmatches(lines, regexec(county_pattern, lines))
county_matches <- county_matches[sapply(county_matches, length) > 0]

actual_2020 <- data.frame(
  county_name = sapply(county_matches, function(x) trimws(x[2])),
  n_winners = as.integer(sapply(county_matches, function(x) x[3])),
  stringsAsFactors = FALSE
)

# Standardize county names
actual_2020$county_name <- gsub("\\s+", " ", actual_2020$county_name)
actual_2020$county_name[actual_2020$county_name == "DADE"] <- "MIAMI-DADE"

cat(sprintf("  2020 parsed: %d counties, %d total licenses\n",
            nrow(actual_2020), sum(actual_2020$n_winners)))

# Parse 2024 entrants summary
entrants_2024_path <- file.path(pdf_dir, "entrants_2024.pdf")
if (file.exists(entrants_2024_path)) {
  cat("Parsing 2024 entrants summary...\n")
  text_2024 <- pdftools::pdf_text(entrants_2024_path)
  cat(text_2024[1])
  cat("\n")
}

saveRDS(actual_2020, file.path(data_dir, "actual_2020_winners.rds"))

# ============================================================
# 3. COUNTY POPULATION DATA (ACS 5-year)
# ============================================================

if (file.exists(file.path(data_dir, "county_population.rds"))) {
  cat("\nPopulation data already cached, loading...\n")
  pop_df <- readRDS(file.path(data_dir, "county_population.rds"))
} else {
  cat("\nFetching county population from ACS 5-year...\n")
  pop_list <- list()
  for (yr in 2011:2023) {
    cat(sprintf("  ACS pop %d...\n", yr))
    base_url <- sprintf("https://api.census.gov/data/%d/acs/acs5", yr)
    params <- list(
      get = "B01003_001E,NAME",
      `for` = "county:*",
      `in` = "state:12",
      key = census_api_key
    )
    resp <- httr::GET(base_url, query = params)
    if (httr::status_code(resp) == 200) {
      raw <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(raw)
      df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
      colnames(df) <- parsed[1, ]
      df$year <- yr
      df$population <- as.numeric(df$B01003_001E)
      pop_list[[as.character(yr)]] <- df
    } else {
      cat(sprintf("    HTTP %d for ACS %d\n", httr::status_code(resp), yr))
    }
    Sys.sleep(0.3)
  }
  pop_df <- bind_rows(pop_list) %>%
    select(county_fips = county, year, population, county_name = NAME)
  saveRDS(pop_df, file.path(data_dir, "county_population.rds"))
}

cat(sprintf("Population data: %d county-year observations\n", nrow(pop_df)))

# ============================================================
# 4. CONSTRUCT TREATMENT FROM POPULATION THRESHOLD RULE
# ============================================================

cat("\nConstructing treatment from §561.19 rule (1 per 7,500 residents)...\n")

# Expected quota licenses per county-year
pop_treatment <- pop_df %>%
  arrange(county_fips, year) %>%
  group_by(county_fips) %>%
  mutate(
    expected_licenses = floor(population / 7500),
    lag_expected = lag(expected_licenses),
    new_licenses = pmax(0, expected_licenses - lag_expected),
    new_licenses = ifelse(is.na(new_licenses), 0, new_licenses)
  ) %>%
  ungroup()

# Summary of treatment variation
cat(sprintf("  Counties with any new licenses: %d of %d\n",
            sum(pop_treatment$new_licenses > 0),
            n_distinct(pop_treatment$county_fips)))
cat(sprintf("  Total new licenses (all years): %d\n", sum(pop_treatment$new_licenses)))
cat(sprintf("  Mean new licenses per county-year: %.3f\n", mean(pop_treatment$new_licenses)))
cat(sprintf("  Max new licenses in single county-year: %d\n", max(pop_treatment$new_licenses)))

# Cross-tab: new licenses by year
year_summary <- pop_treatment %>%
  group_by(year) %>%
  summarise(
    total_new = sum(new_licenses),
    counties_receiving = sum(new_licenses > 0),
    .groups = "drop"
  )
print(year_summary)

saveRDS(pop_treatment, file.path(data_dir, "population_treatment.rds"))

# ============================================================
# 5. VALIDATE AGAINST 2020 ACTUAL DATA
# ============================================================

cat("\nValidating computed vs. actual 2020 allocations...\n")

# FIPS-to-county-name crosswalk from pop_df
fips_names <- pop_df %>%
  filter(year == max(year)) %>%
  mutate(county_upper = toupper(gsub(" County, Florida", "", county_name))) %>%
  select(county_fips, county_upper)

computed_2020 <- pop_treatment %>%
  filter(year == 2019) %>%  # Drawing held in 2020 was for 2019 entry period
  left_join(fips_names, by = "county_fips") %>%
  filter(new_licenses > 0)

# Note: the 2020 drawing was "for the 2019 Entry Period" but used population data
# that would determine license counts. The match may not be exact due to timing
# of population estimates vs. license allocation.

cat(sprintf("  Computed: %d counties with new licenses, %d total\n",
            nrow(computed_2020), sum(computed_2020$new_licenses)))
cat(sprintf("  Actual: %d counties, %d total licenses\n",
            nrow(actual_2020), sum(actual_2020$n_winners)))

# Attempt fuzzy match
if (nrow(computed_2020) > 0) {
  matched <- inner_join(
    computed_2020 %>% select(county_upper, computed = new_licenses),
    actual_2020 %>% mutate(county_upper = county_name) %>%
      select(county_upper, actual = n_winners),
    by = "county_upper"
  )
  if (nrow(matched) > 0) {
    cat(sprintf("  Matched %d counties\n", nrow(matched)))
    cat(sprintf("  Correlation: %.3f\n", cor(matched$computed, matched$actual)))
    print(matched)
  }
}

# ============================================================
# Summary
# ============================================================

cat("\n=== DATA FETCH SUMMARY ===\n")
cat(sprintf("QWI: %d rows (%d counties)\n", nrow(qwi_df), n_distinct(qwi_df$county)))
cat(sprintf("Population: %d county-year obs\n", nrow(pop_df)))
cat(sprintf("Treatment: %d county-year obs with new licenses > 0\n",
            sum(pop_treatment$new_licenses > 0)))
cat(sprintf("Validation: 2020 winners PDF parsed (%d counties)\n", nrow(actual_2020)))
cat("=========================\n")
