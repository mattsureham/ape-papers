# 01_fetch_data.R — Fetch Eurostat bankruptcy data + transposition dates
# APEP-0750: Rescue or Ruin?

source("00_packages.R")

cat("=== Step 1: Fetch Eurostat bankruptcy declarations (sts_rb_q) ===\n")

# Install eurostat package if needed
if (!requireNamespace("eurostat", quietly = TRUE)) {
  install.packages("eurostat", repos = "https://cloud.r-project.org")
}
library(eurostat)

# Fetch quarterly bankruptcy declarations index
bkrt_raw <- get_eurostat("sts_rb_q", time_format = "date")

if (is.null(bkrt_raw) || nrow(bkrt_raw) == 0) {
  stop("FATAL: Failed to fetch sts_rb_q from Eurostat. Cannot proceed.")
}

cat(sprintf("  Raw data: %d rows, %d countries\n",
            nrow(bkrt_raw), n_distinct(bkrt_raw$geo)))

# Filter to bankruptcy declarations (BKRT), seasonally + calendar adjusted
# Keep relevant NACE sectors
bkrt <- bkrt_raw %>%
  filter(
    indic_bt == "BKRT",          # Bankruptcy declarations
    s_adj == "SCA",              # Seasonally and calendar adjusted
    nace_r2 %in% c("B-S_X_O_S94", "B-E", "F", "G-N"),  # Total, Industry, Construction, Services
    unit == "I21"                 # Index 2021=100
  ) %>%
  mutate(
    year = as.integer(format(TIME_PERIOD, "%Y")),
    quarter = as.integer(format(TIME_PERIOD, "%m")) %/% 3,
    quarter = ifelse(quarter == 0, 4, quarter),  # Handle edge case
    yq = paste0(year, "Q", quarter)
  ) %>%
  filter(year >= 2015, year <= 2025) %>%
  rename(country = geo, sector = nace_r2, bkrt_index = values) %>%
  select(country, sector, year, quarter, yq, TIME_PERIOD, bkrt_index)

cat(sprintf("  Filtered data: %d rows\n", nrow(bkrt)))
cat(sprintf("  Countries: %s\n", paste(sort(unique(bkrt$country)), collapse = ", ")))
cat(sprintf("  Sectors: %s\n", paste(unique(bkrt$sector), collapse = ", ")))
cat(sprintf("  Time range: %s to %s\n", min(bkrt$yq), max(bkrt$yq)))

# Validate: at least 20 countries and 100 obs
stopifnot(
  "Too few countries" = n_distinct(bkrt$country) >= 15,
  "Too few observations" = nrow(bkrt) >= 200
)

write_csv(bkrt, "../data/bankruptcy_index.csv")
cat("  Saved: data/bankruptcy_index.csv\n")

cat("\n=== Step 2: Construct transposition dates ===\n")

# Directive 2019/1023 transposition dates (from EUR-Lex NIM database and official sources)
# These are entry-into-force dates of national implementing legislation
transposition <- tribble(
  ~country, ~transpose_date, ~transpose_law,
  "DE", "2021-01-01", "StaRUG (Stabilization and Restructuring Framework)",
  "NL", "2021-01-01", "WHOA (Wet Homologatie Onderhands Akkoord)",
  "EL", "2021-06-01", "Law 4738/2020",
  "FR", "2021-10-01", "Ordonnance 2021-1193",
  "AT", "2021-07-17", "Restrukturierungsordnung (ReO)",
  "LT", "2022-01-01", "Law on Restructuring of Legal Entities",
  "HR", "2022-01-01", "Zakon o postupku izvanredne uprave",
  "RO", "2022-07-01", "Law 216/2022",
  "DK", "2022-07-17", "Lov om rekonstruktion",
  "EE", "2022-07-17", "Saneerimisseadus amendment",
  "LV", "2022-07-17", "Insolvency Law amendments",
  "FI", "2022-07-17", "Restructuring of Enterprises Act reform",
  "IT", "2022-07-15", "Codice della crisi d'impresa (D.Lgs 83/2022)",
  "IE", "2022-07-26", "Companies (Rescue Process for Small Companies) Act",
  "HU", "2022-07-01", "Act on restructuring proceedings",
  "SK", "2022-07-17", "Act on preventive restructuring",
  "SI", "2022-11-01", "ZFPPIPP amendments",
  "ES", "2022-09-26", "Ley 16/2022 reforma concursal",
  "PT", "2022-04-12", "DL 2022 RERE reform",
  "LU", "2023-01-01", "Loi sur la preservation des entreprises",
  "PL", "2023-12-01", "Prawo restrukturyzacyjne amendments",
  "SE", "2022-08-01", "Lag om företagsrekonstruktion (SFS 2022:964)",
  "CZ", "2023-09-23", "Zákon o preventivní restrukturalizaci",
  "BG", "2023-02-14", "Commercial Act amendments",
  "BE", "2023-09-01", "Boek XX WER amendments",
  "MT", "2022-07-17", "Companies Act (Cap.386) amendments"
) %>%
  mutate(
    transpose_date = as.Date(transpose_date),
    transpose_year = as.integer(format(transpose_date, "%Y")),
    transpose_quarter = ceiling(as.integer(format(transpose_date, "%m")) / 3),
    # For CS-DiD: treatment quarter as numeric (quarters since 2015Q1)
    treat_yq = paste0(transpose_year, "Q", transpose_quarter)
  )

cat(sprintf("  Transposition dates for %d countries\n", nrow(transposition)))
cat(sprintf("  Earliest: %s (%s)\n", min(transposition$transpose_date),
            transposition$country[which.min(transposition$transpose_date)]))
cat(sprintf("  Latest: %s (%s)\n", max(transposition$transpose_date),
            transposition$country[which.max(transposition$transpose_date)]))

write_csv(transposition, "../data/transposition_dates.csv")
cat("  Saved: data/transposition_dates.csv\n")

cat("\n=== Step 3: Fetch business demography (compositional check) ===\n")

# Business demography — annual, will use for mechanism/composition
bd_raw <- tryCatch(
  get_eurostat("bd_9bd_sz_cl_r2", time_format = "date"),
  error = function(e) {
    cat(sprintf("  Warning: Could not fetch bd_9bd_sz_cl_r2: %s\n", e$message))
    cat("  Trying alternative dataset...\n")
    tryCatch(
      get_eurostat("bd_9b_sz_cl_r2", time_format = "date"),
      error = function(e2) {
        cat(sprintf("  Alternative also failed: %s. Continuing without business demography.\n", e2$message))
        NULL
      }
    )
  }
)

if (!is.null(bd_raw) && nrow(bd_raw) > 0) {
  bd <- bd_raw %>%
    filter(
      indic_sb %in% c("V11910", "V11920"),  # births and deaths of enterprises
      sizeclas == "TOTAL",
      nace_r2 %in% c("B-S_X_K642", "B-E", "F", "G-N")
    ) %>%
    mutate(year = as.integer(format(TIME_PERIOD, "%Y"))) %>%
    filter(year >= 2015) %>%
    rename(country = geo, sector = nace_r2, indicator = indic_sb) %>%
    select(country, sector, year, indicator, values)

  write_csv(bd, "../data/business_demography.csv")
  cat(sprintf("  Business demography: %d rows saved\n", nrow(bd)))
} else {
  cat("  Skipping business demography — not critical for main analysis.\n")
}

cat("\n=== Step 4: Fetch COVID stringency index ===\n")

# Oxford COVID stringency index — direct download
covid_url <- "https://raw.githubusercontent.com/OxCGRT/covid-policy-dataset/main/data/OxCGRT_compact_national_v1.csv"
covid_raw <- tryCatch(
  read_csv(covid_url, show_col_types = FALSE),
  error = function(e) {
    cat(sprintf("  Warning: Could not fetch COVID stringency: %s\n", e$message))
    NULL
  }
)

if (!is.null(covid_raw) && nrow(covid_raw) > 0) {
  # Map country codes to Eurostat 2-letter codes
  iso3_to_eu <- c(
    "AUT" = "AT", "BEL" = "BE", "BGR" = "BG", "HRV" = "HR", "CYP" = "CY",
    "CZE" = "CZ", "DNK" = "DK", "EST" = "EE", "FIN" = "FI", "FRA" = "FR",
    "DEU" = "DE", "GRC" = "EL", "HUN" = "HU", "IRL" = "IE", "ITA" = "IT",
    "LVA" = "LV", "LTU" = "LT", "LUX" = "LU", "MLT" = "MT", "NLD" = "NL",
    "POL" = "PL", "PRT" = "PT", "ROU" = "RO", "SVK" = "SK", "SVN" = "SI",
    "ESP" = "ES", "SWE" = "SE"
  )

  covid <- covid_raw %>%
    filter(CountryCode %in% names(iso3_to_eu)) %>%
    mutate(
      country = iso3_to_eu[CountryCode],
      date = as.Date(as.character(Date), format = "%Y%m%d"),
      year = as.integer(format(date, "%Y")),
      quarter = ceiling(as.integer(format(date, "%m")) / 3)
    ) %>%
    group_by(country, year, quarter) %>%
    summarise(
      stringency_mean = mean(StringencyIndex_Average, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(year >= 2020, year <= 2023)

  write_csv(covid, "../data/covid_stringency.csv")
  cat(sprintf("  COVID stringency: %d rows saved\n", nrow(covid)))
} else {
  cat("  Skipping COVID stringency — will proceed without.\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Files saved:\n")
for (f in list.files("../data/", pattern = "\\.csv$")) {
  cat(sprintf("  data/%s (%s)\n", f,
              format(file.size(file.path("../data", f)), big.mark = ",")))
}
