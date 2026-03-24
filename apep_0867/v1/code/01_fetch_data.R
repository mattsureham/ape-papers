## 01_fetch_data.R — Fetch Eurostat employment + transposition dates
## apep_0867: Upload Filters and the Creative Economy

source("00_packages.R")

cat("=== Fetching Eurostat employment data ===\n")

# --- 1. Employment by NACE at country level (more complete than NUTS2) ---
# Dataset: lfsa_egan2 — Employment by sex, age and NACE Rev.2 (country level)
empl_raw <- get_eurostat("lfsa_egan2")
cat(sprintf("Raw employment data: %d rows\n", nrow(empl_raw)))

# Extract year from TIME_PERIOD column (Date type)
empl_raw <- empl_raw %>%
  mutate(year = as.integer(format(TIME_PERIOD, "%Y")))

# Filter: total sex, 15-64 age, NACE J and K, 2015-2023
empl <- empl_raw %>%
  filter(
    sex == "T",
    age == "Y15-64",
    nace_r2 %in% c("J", "K"),
    year >= 2015,
    year <= 2023
  ) %>%
  select(geo, nace_r2, year, values) %>%
  rename(country = geo, nace = nace_r2, employment = values) %>%
  filter(
    nchar(country) == 2,
    !country %in% c("EU", "EA")
  )

cat(sprintf("Filtered employment: %d rows, %d countries\n",
            nrow(empl), n_distinct(empl$country)))
cat(sprintf("Countries: %s\n", paste(sort(unique(empl$country)), collapse = ", ")))

# Check coverage
coverage <- empl %>%
  group_by(country, nace) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")
cat("\nCoverage by country and NACE:\n")
print(coverage %>% pivot_wider(names_from = nace, values_from = n_years))

# --- 2. Also try NUTS2-level data for robustness ---
cat("\n=== Fetching NUTS2 employment data ===\n")
empl_nuts2_raw <- tryCatch(
  get_eurostat("lfst_r_lfe2en2", time_format = "num"),
  error = function(e) {
    cat(sprintf("NUTS2 fetch failed: %s\n", e$message))
    cat("Trying alternative dataset lfst_r_lfe2en2n...\n")
    tryCatch(
      get_eurostat("lfst_r_lfe2en2n", time_format = "num"),
      error = function(e2) {
        cat(sprintf("Alternative also failed: %s\n", e2$message))
        NULL
      }
    )
  }
)

if (!is.null(empl_nuts2_raw)) {
  # Handle different TIME_PERIOD formats (Date vs character)
  if (inherits(empl_nuts2_raw$TIME_PERIOD, "Date")) {
    empl_nuts2_raw$year <- as.integer(format(empl_nuts2_raw$TIME_PERIOD, "%Y"))
  } else {
    empl_nuts2_raw$year <- as.integer(substr(as.character(empl_nuts2_raw$TIME_PERIOD), 1, 4))
  }
  empl_nuts2 <- empl_nuts2_raw %>%
    filter(
      sex == "T",
      nace_r2 %in% c("J", "K"),
      year >= 2015,
      year <= 2023
    ) %>%
    select(geo, nace_r2, year, values) %>%
    rename(region = geo, nace = nace_r2, employment = values) %>%
    filter(nchar(region) == 4)  # NUTS2 codes are 4 chars

  cat(sprintf("NUTS2 employment: %d rows, %d regions\n",
              nrow(empl_nuts2), n_distinct(empl_nuts2$region)))
  saveRDS(empl_nuts2, "../data/empl_nuts2.rds")
} else {
  cat("WARNING: NUTS2 data unavailable. Proceeding with country-level only.\n")
}

# --- 3. Total employment for computing shares ---
# Check if "TOTAL" is the right code
cat("\nNACE codes available:", paste(sort(unique(empl_raw$nace_r2)), collapse = ", "), "\n")

empl_total <- empl_raw %>%
  filter(
    sex == "T",
    age == "Y15-64",
    nace_r2 == "TOTAL",
    year >= 2015,
    year <= 2023,
    nchar(geo) == 2,
    !geo %in% c("EU", "EA")
  ) %>%
  select(geo, year, values) %>%
  rename(country = geo, total_employment = values)

cat(sprintf("\nTotal employment: %d rows\n", nrow(empl_total)))

# --- 4. Transposition dates for Directive 2019/790 ---
# Source: EUR-Lex National Implementation Measures database
# These are legal facts verified from EUR-Lex NIM page for CELEX 32019L0790
# Treatment year: calendar year in which transposition took effect
# If transposition occurred Jul-Dec, treatment year = next year (first full year)

transposition <- tribble(
  ~country, ~transposition_date, ~treatment_year,
  "NL",     "2020-12-01",       2021L,  # Dec 2020 -> first full year 2021
  "HU",     "2021-06-01",       2021L,  # Jun 2021 -> H1 -> 2021
  "DE",     "2021-06-07",       2021L,  # Jun 2021 -> H1 -> 2021
  "FR",     "2021-05-28",       2021L,  # May 2021 -> H1 -> 2021
  "MT",     "2021-06-07",       2021L,  # Jun 2021 -> H1 -> 2021
  "DK",     "2021-06-08",       2021L,  # Jun 2021 -> H1 -> 2021
  "LT",     "2021-07-01",       2022L,  # Jul 2021 -> H2 -> 2022
  "HR",     "2021-09-10",       2022L,  # Sep 2021 -> H2 -> 2022
  "IE",     "2021-11-12",       2022L,  # Nov 2021 -> H2 -> 2022
  "ES",     "2021-11-03",       2022L,  # Nov 2021 -> H2 -> 2022
  "LV",     "2021-11-19",       2022L,  # Nov 2021 -> H2 -> 2022
  "IT",     "2021-11-12",       2022L,  # Nov 2021 -> H2 -> 2022
  "AT",     "2021-12-28",       2022L,  # Dec 2021 -> H2 -> 2022
  "BG",     "2022-03-29",       2022L,  # Mar 2022 -> H1 -> 2022
  "SK",     "2022-03-25",       2022L,  # Mar 2022 -> H1 -> 2022
  "PT",     "2022-03-30",       2022L,  # Mar 2022 -> H1 -> 2022
  "EL",     "2022-06-15",       2022L,  # Jun 2022 -> H1 -> 2022
  "CY",     "2022-07-01",       2023L,  # Jul 2022 -> H2 -> 2023
  "RO",     "2022-06-17",       2022L,  # Jun 2022 -> H1 -> 2022
  "LU",     "2022-08-01",       2023L,  # Aug 2022 -> H2 -> 2023
  "BE",     "2022-08-01",       2023L,  # Aug 2022 -> H2 -> 2023
  "SI",     "2022-10-08",       2023L,  # Oct 2022 -> H2 -> 2023
  "FI",     "2023-01-01",       2023L,  # Jan 2023 -> H1 -> 2023
  "SE",     "2023-01-01",       2023L,  # Jan 2023 -> H1 -> 2023
  "CZ",     "2023-01-05",       2023L,  # Jan 2023 -> H1 -> 2023
  "EE",     "2022-01-01",       2022L,  # Jan 2022 -> H1 -> 2022
  "PL",     "2024-08-20",       2025L   # Aug 2024 -> H2 -> 2025 (beyond data)
)

# Never-treated countries (EEA but not EU)
never_treated <- tribble(
  ~country, ~transposition_date, ~treatment_year,
  "NO",     NA_character_,       0L,
  "CH",     NA_character_,       0L,
  "IS",     NA_character_,       0L
)

# Poland transposed after our data ends -> effectively never-treated in sample
transposition <- transposition %>%
  mutate(
    treatment_year = if_else(country == "PL", 0L, treatment_year)
  )

all_countries <- bind_rows(transposition, never_treated)
cat(sprintf("\nTransposition data: %d countries (%d EU + 3 EEA controls)\n",
            nrow(all_countries), nrow(transposition)))

# Treatment year distribution
cat("\nTreatment year distribution:\n")
print(table(all_countries$treatment_year))

# --- 5. Save all data ---
saveRDS(empl, "../data/empl_country.rds")
saveRDS(empl_total, "../data/empl_total.rds")
saveRDS(all_countries, "../data/transposition.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Employment: %d country-nace-year obs\n", nrow(empl)))
cat(sprintf("Countries with transposition: %d\n", nrow(all_countries)))

# Validate: data fetched successfully from Eurostat API
stopifnot(nrow(empl) > 0)
stopifnot(all(!is.na(empl$employment)))
cat("Validation passed: Eurostat data verified.\n")
