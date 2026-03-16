## 01_fetch_data.R — Fetch real data from IPEA and IBGE
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates
## Data sources:
##   - IPEADATA API: municipality-level homicide counts (SIM-DATASUS processed)
##   - IBGE SIDRA API: municipality population estimates

source("00_packages.R")

cat("=== Fetching mortality and population data ===\n")

# ─────────────────────────────────────────────────────────────────────
# 1. IBGE Population Estimates (SIDRA API — Table 6579)
# ─────────────────────────────────────────────────────────────────────
cat("Fetching IBGE population estimates...\n")

pop_list <- list()
years_pop <- 2001:2021

for (yr in years_pop) {
  cat(sprintf("  Population %d...\n", yr))
  url <- sprintf(
    "https://apisidra.ibge.gov.br/values/t/6579/n6/all/p/%d/v/9324",
    yr
  )
  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) {
      stop(sprintf("FATAL: IBGE API failed for year %d: %s", yr, e$message))
    }
  )
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: IBGE API returned status %d for year %d",
                 httr::status_code(resp), yr))
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  df_yr <- jsonlite::fromJSON(raw, simplifyDataFrame = TRUE)

  if (nrow(df_yr) > 1) {
    df_yr <- df_yr[-1, ]
    pop_list[[as.character(yr)]] <- data.frame(
      mun_code = df_yr[["D1C"]],
      mun_name = df_yr[["D1N"]],
      year = yr,
      population = as.numeric(df_yr[["V"]]),
      stringsAsFactors = FALSE
    )
  }
  Sys.sleep(0.5)
}

pop_df <- bind_rows(pop_list)
pop_df <- pop_df %>%
  filter(!is.na(population), nchar(mun_code) == 7) %>%
  mutate(mun_code6 = substr(mun_code, 1, 6))

cat(sprintf("Population data: %d municipality-year observations\n", nrow(pop_df)))
stopifnot("Population data is empty" = nrow(pop_df) > 50000)
saveRDS(pop_df, "../data/population_raw.rds")
cat("Saved population_raw.rds\n")

# ─────────────────────────────────────────────────────────────────────
# 2. IPEADATA — Municipality-level homicide counts
# ─────────────────────────────────────────────────────────────────────
# Series HOMIC: absolute homicide count by municipality-year (SIM-DATASUS)
# 204,928 municipality-level records, 1980-2022

cat("\nFetching homicide counts from IPEADATA API...\n")

# IPEADATA OData4 API — fetch all municipality-level records
# The API returns all levels; we filter for Municípios

ipea_url <- "http://www.ipeadata.gov.br/api/odata4/ValoresSerie(SERCODIGO='HOMIC')"

resp_ipea <- httr::GET(
  ipea_url,
  httr::timeout(300),
  httr::add_headers(`User-Agent` = "R APEP/1.0")
)

if (httr::status_code(resp_ipea) != 200) {
  stop(sprintf("FATAL: IPEADATA API returned status %d", httr::status_code(resp_ipea)))
}

raw_ipea <- httr::content(resp_ipea, as = "text", encoding = "UTF-8")
ipea_data <- jsonlite::fromJSON(raw_ipea, simplifyDataFrame = TRUE)
ipea_df <- ipea_data$value

cat(sprintf("Total IPEADATA records: %d\n", nrow(ipea_df)))

# Filter for municipality level (TERCODIGO length = 7)
homicide_df <- ipea_df %>%
  filter(NIVNOME == "Municípios") %>%
  mutate(
    mun_code = as.character(TERCODIGO),
    year = as.integer(substr(VALDATA, 1, 4)),
    homicides = as.numeric(VALVALOR)
  ) %>%
  filter(nchar(mun_code) == 7, !is.na(homicides)) %>%
  select(mun_code, year, homicides) %>%
  mutate(mun_code6 = substr(mun_code, 1, 6))

cat(sprintf("Municipality-level homicide records: %d\n", nrow(homicide_df)))
cat(sprintf("Year range: %d to %d\n", min(homicide_df$year), max(homicide_df$year)))
cat(sprintf("Unique municipalities: %d\n", n_distinct(homicide_df$mun_code)))
cat(sprintf("Total homicides in dataset: %s\n",
            format(sum(homicide_df$homicides), big.mark = ",")))

stopifnot("Homicide data is empty" = nrow(homicide_df) > 100000)
saveRDS(homicide_df, "../data/homicides_raw.rds")
cat("Saved homicides_raw.rds\n")

# ─────────────────────────────────────────────────────────────────────
# 3. Youth homicides (15-29, for mechanism test)
# ─────────────────────────────────────────────────────────────────────
cat("\nFetching youth homicide counts (HOMICJ series)...\n")

resp_youth <- httr::GET(
  "http://www.ipeadata.gov.br/api/odata4/ValoresSerie(SERCODIGO='HOMICJ')",
  httr::timeout(300),
  httr::add_headers(`User-Agent` = "R APEP/1.0")
)

if (httr::status_code(resp_youth) == 200) {
  raw_youth <- httr::content(resp_youth, as = "text", encoding = "UTF-8")
  youth_data <- jsonlite::fromJSON(raw_youth, simplifyDataFrame = TRUE)
  youth_df <- youth_data$value

  youth_hom <- youth_df %>%
    filter(NIVNOME == "Municípios") %>%
    mutate(
      mun_code = as.character(TERCODIGO),
      year = as.integer(substr(VALDATA, 1, 4)),
      youth_homicides = as.numeric(VALVALOR)
    ) %>%
    filter(nchar(mun_code) == 7, !is.na(youth_homicides)) %>%
    select(mun_code, year, youth_homicides)

  cat(sprintf("Youth homicide records: %d\n", nrow(youth_hom)))
  saveRDS(youth_hom, "../data/youth_homicides_raw.rds")
  cat("Saved youth_homicides_raw.rds\n")
} else {
  cat("Warning: Could not fetch youth homicide data.\n")
}

# ─────────────────────────────────────────────────────────────────────
# 4. Homicide rates (THOMIC series — for cross-validation)
# ─────────────────────────────────────────────────────────────────────
cat("\nFetching homicide rates (THOMIC series) for cross-validation...\n")

resp_rate <- httr::GET(
  "http://www.ipeadata.gov.br/api/odata4/ValoresSerie(SERCODIGO='THOMIC')",
  httr::timeout(300),
  httr::add_headers(`User-Agent` = "R APEP/1.0")
)

if (httr::status_code(resp_rate) == 200) {
  raw_rate <- httr::content(resp_rate, as = "text", encoding = "UTF-8")
  rate_data <- jsonlite::fromJSON(raw_rate, simplifyDataFrame = TRUE)
  rate_df <- rate_data$value

  hom_rate <- rate_df %>%
    filter(NIVNOME == "Municípios") %>%
    mutate(
      mun_code = as.character(TERCODIGO),
      year = as.integer(substr(VALDATA, 1, 4)),
      homicide_rate_ipea = as.numeric(VALVALOR)
    ) %>%
    filter(nchar(mun_code) == 7, !is.na(homicide_rate_ipea)) %>%
    select(mun_code, year, homicide_rate_ipea)

  cat(sprintf("Homicide rate records: %d\n", nrow(hom_rate)))
  saveRDS(hom_rate, "../data/homicide_rates_raw.rds")
  cat("Saved homicide_rates_raw.rds\n")
} else {
  cat("Warning: Could not fetch homicide rate data.\n")
}

# ─────────────────────────────────────────────────────────────────────
# 5. Verify data completeness
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Data fetch summary ===\n")
cat(sprintf("Population: %d mun-years (%d-%d), %d municipalities\n",
            nrow(pop_df), min(pop_df$year), max(pop_df$year),
            n_distinct(pop_df$mun_code)))
cat(sprintf("Homicides: %d mun-years (%d-%d), %d municipalities\n",
            nrow(homicide_df), min(homicide_df$year), max(homicide_df$year),
            n_distinct(homicide_df$mun_code)))

# Check overlap
shared_years <- intersect(unique(pop_df$year), unique(homicide_df$year))
cat(sprintf("Overlapping years: %d-%d (%d years)\n",
            min(shared_years), max(shared_years), length(shared_years)))

cat("\n=== Data fetch complete ===\n")
