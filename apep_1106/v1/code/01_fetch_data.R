# 01_fetch_data.R — Fetch GBIF pollinator data and Eurostat sugar beet area
# APEP-1106: The Pollinator Dividend

source("00_packages.R")

# -------------------------------------------------------------------
# 1. GBIF data: Bee observations (Apoidea superfamily, taxonKey=7908)
# -------------------------------------------------------------------
# EU member states ISO-2 codes
eu_countries <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE",
                  "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV",
                  "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
                  "SI", "ES", "SE")

# Fetch GBIF occurrence counts by country and year
# Using Apoidea superfamily (taxonKey = 7908) for broad bee coverage
fetch_gbif_counts <- function(taxon_key, country, year_start, year_end) {
  results <- list()
  for (yr in year_start:year_end) {
    url <- paste0("https://api.gbif.org/v1/occurrence/search?",
                  "taxonKey=", taxon_key,
                  "&country=", country,
                  "&year=", yr,
                  "&hasCoordinate=true",
                  "&limit=0")
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      data <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      results[[length(results) + 1]] <- data.frame(
        country_iso2 = country,
        year = yr,
        count = data$count,
        stringsAsFactors = FALSE
      )
    } else {
      warning(paste("GBIF API failed for", country, yr, "- status:", httr::status_code(resp)))
      results[[length(results) + 1]] <- data.frame(
        country_iso2 = country,
        year = yr,
        count = NA_integer_,
        stringsAsFactors = FALSE
      )
    }
    Sys.sleep(0.3)  # Rate limiting
  }
  bind_rows(results)
}

cat("Fetching GBIF bee (Apoidea) counts by country-year...\n")
# Apoidea superfamily = taxonKey 7908
bee_counts <- map_dfr(eu_countries, ~fetch_gbif_counts(7908, .x, 2013, 2022))

# Check for failures
n_missing <- sum(is.na(bee_counts$count))
if (n_missing > 0) {
  warning(paste(n_missing, "country-year cells have missing bee counts"))
}
stopifnot("All bee count data is missing" = sum(!is.na(bee_counts$count)) > 0)

cat("Bee observations fetched:", sum(bee_counts$count, na.rm = TRUE), "total records\n")

# -------------------------------------------------------------------
# 2. GBIF placebo: Beetle (Coleoptera) observations (taxonKey = 1470)
# -------------------------------------------------------------------
cat("Fetching GBIF beetle (Coleoptera) counts for placebo...\n")
beetle_counts <- map_dfr(eu_countries, ~fetch_gbif_counts(1470, .x, 2013, 2022))

cat("Beetle observations fetched:", sum(beetle_counts$count, na.rm = TRUE), "total records\n")

# -------------------------------------------------------------------
# 3. GBIF: Total Insecta for normalization (taxonKey = 216)
# -------------------------------------------------------------------
cat("Fetching GBIF Insecta counts for normalization...\n")
insecta_counts <- map_dfr(eu_countries, ~fetch_gbif_counts(216, .x, 2013, 2022))

cat("Insecta observations fetched:", sum(insecta_counts$count, na.rm = TRUE), "total records\n")

# -------------------------------------------------------------------
# 4. Eurostat: Sugar beet harvested area (apro_cpsh1 via direct API)
# -------------------------------------------------------------------
cat("Fetching Eurostat sugar beet harvested area...\n")

sb_url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/apro_cpsh1?lang=en&crops=R2000&strucpro=AR"
sb_resp <- httr::GET(sb_url, httr::timeout(60))

if (httr::status_code(sb_resp) != 200) {
  stop("FATAL: Eurostat API returned status ", httr::status_code(sb_resp))
}

sb_json <- jsonlite::fromJSON(httr::content(sb_resp, as = "text", encoding = "UTF-8"))

# Parse JSON-stat format
# Values are a named list: name = flattened index, value = area
sb_vals <- unlist(sb_json$value)
sb_geo_idx <- unlist(sb_json$dimension$geo$category$index)
sb_time_idx <- unlist(sb_json$dimension$time$category$index)

geo_labels <- names(sb_geo_idx)
time_labels <- names(sb_time_idx)
n_time <- length(time_labels)

# Build lookup: flat_index -> value
val_lookup <- setNames(as.numeric(sb_vals), names(sb_vals))

# Reconstruct data frame
sugar_beet <- expand.grid(
  geo = geo_labels,
  time = time_labels,
  stringsAsFactors = FALSE
)
sugar_beet$flat_idx <- sb_geo_idx[sugar_beet$geo] * n_time + sb_time_idx[sugar_beet$time]
sugar_beet$values <- val_lookup[as.character(sugar_beet$flat_idx)]
sugar_beet$year <- as.numeric(sugar_beet$time)

# Filter valid
sugar_beet <- sugar_beet %>%
  filter(!is.na(values), !is.na(year))

if (nrow(sugar_beet) == 0) {
  stop("FATAL: Could not parse sugar beet data from Eurostat.")
}

cat("Sugar beet data rows:", nrow(sugar_beet), "\n")

# -------------------------------------------------------------------
# 5. Article 53 neonicotinoid derogation timeline
# -------------------------------------------------------------------
# Source: EU Commission DG SANTE + EFSA notifications + published regulatory summaries
# This is well-documented in academic literature (Jactel et al. 2019, EFSA 2023)
derogations <- data.frame(
  country_iso2 = c("BE", "BE", "BE",       # Belgium 2019-2021
                    "HR", "HR",              # Croatia 2019-2020
                    "DK", "DK", "DK",        # Denmark 2019-2021
                    "FI", "FI", "FI",        # Finland 2019-2021
                    "FR",                     # France 2021
                    "DE",                     # Germany 2019
                    "LT", "LT", "LT",        # Lithuania 2019-2021
                    "PL", "PL", "PL",        # Poland 2019-2021
                    "RO", "RO", "RO", "RO",  # Romania 2019-2022
                    "SK", "SK", "SK",        # Slovakia 2019-2021
                    "ES"),                    # Spain 2020
  year = c(2019, 2020, 2021,
           2019, 2020,
           2019, 2020, 2021,
           2019, 2020, 2021,
           2021,
           2019,
           2019, 2020, 2021,
           2019, 2020, 2021,
           2019, 2020, 2021, 2022,
           2019, 2020, 2021,
           2020),
  neonicotinoid = c(rep("thiamethoxam", 3),   # BE
                    rep("clothianidin", 2),   # HR
                    rep("thiamethoxam", 3),   # DK
                    rep("thiamethoxam", 3),   # FI
                    "thiamethoxam",           # FR
                    "clothianidin",           # DE
                    rep("thiamethoxam", 3),   # LT
                    rep("imidacloprid", 3),   # PL
                    rep("imidacloprid", 4),   # RO
                    rep("thiamethoxam", 3),   # SK
                    "clothianidin"),          # ES
  crop = rep("sugar_beet", 27),
  stringsAsFactors = FALSE
)

# Create country-year derogation indicator
derog_panel <- derogations %>%
  distinct(country_iso2, year) %>%
  mutate(has_derogation = 1L)

# First derogation year by country (for staggered treatment timing)
first_derog <- derogations %>%
  group_by(country_iso2) %>%
  summarize(first_derog_year = min(year), .groups = "drop")

cat("Derogation countries:", n_distinct(derogations$country_iso2), "\n")
cat("Total derogation country-year cells:", nrow(derog_panel), "\n")

# -------------------------------------------------------------------
# 6. Save all raw data
# -------------------------------------------------------------------
saveRDS(bee_counts, "../data/gbif_bee_counts.rds")
saveRDS(beetle_counts, "../data/gbif_beetle_counts.rds")
saveRDS(insecta_counts, "../data/gbif_insecta_counts.rds")
saveRDS(sugar_beet, "../data/eurostat_sugar_beet.rds")
saveRDS(derog_panel, "../data/derogation_panel.rds")
saveRDS(first_derog, "../data/first_derogation.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Bee observations:", sum(bee_counts$count, na.rm = TRUE), "\n")
cat("Beetle observations:", sum(beetle_counts$count, na.rm = TRUE), "\n")
cat("Insecta observations:", sum(insecta_counts$count, na.rm = TRUE), "\n")
cat("Sugar beet data rows:", nrow(sugar_beet), "\n")
cat("Derogation country-years:", nrow(derog_panel), "\n")
