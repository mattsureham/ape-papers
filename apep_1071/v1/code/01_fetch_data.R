# 01_fetch_data.R — Fetch Eurostat HPI data
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

source("00_packages.R")

# ── Fetch Eurostat prc_hpi_q ──────────────────────────────────────
cat("Fetching Eurostat prc_hpi_q (House Price Index, quarterly)...\n")

hpi_raw <- get_eurostat("prc_hpi_q", time_format = "date")

if (is.null(hpi_raw) || nrow(hpi_raw) == 0) {
  stop("FATAL: Eurostat prc_hpi_q returned no data. Cannot proceed.")
}

cat("Raw data:", nrow(hpi_raw), "rows\n")

# ── Filter to individual countries with both dwelling types ───────
# Exclude aggregate codes (EA, EU, etc.) and Turkey
aggregate_codes <- c("EA", "EA19", "EA20", "EA21", "EU", "EU27_2020", "EU28", "TR")

# Countries with comparable real estate golden visa programs active by 2012-2016:
# - Greece (EL): golden visa from 2013 (EUR 250K) — similar program, must exclude
# - Latvia (LV): golden visa from 2010 (EUR 143K) — exclude
# - Malta (MT): citizenship by investment from 2014 — exclude
# - Cyprus (CY): citizenship by investment from 2013 — exclude
# - Hungary (HU): residency bond scheme 2013-2017 — different mechanism, keep
# - Spain (ES): golden visa from 2013 (EUR 500K) — BUT much smaller uptake and
#   NOT concentrated in existing dwellings → keep as comparator with robustness check
golden_visa_countries <- c("EL", "LV", "MT", "CY")

# Get all individual countries with both DW_EXST and DW_NEW
dwelling_types <- c("DW_EXST", "DW_NEW")

hpi <- hpi_raw %>%
  filter(
    !(geo %in% c(aggregate_codes, golden_visa_countries)),
    purchase %in% dwelling_types,
    unit == "I15_Q"  # Index 2015=100, quarterly
  ) %>%
  select(geo, purchase, time = TIME_PERIOD, values) %>%
  rename(country = geo, dwelling_type = purchase, hpi = values) %>%
  filter(!is.na(hpi))

# Keep only countries with BOTH dwelling types
both_types <- hpi %>%
  group_by(country) %>%
  summarise(n_types = n_distinct(dwelling_type), .groups = "drop") %>%
  filter(n_types == 2) %>%
  pull(country)

hpi <- hpi %>% filter(country %in% both_types)

# Create time variables
hpi <- hpi %>%
  mutate(
    year = as.integer(format(time, "%Y")),
    quarter = as.integer(format(time, "%m")) %/% 3
  ) %>%
  arrange(country, dwelling_type, time)

# ── Validate data completeness ────────────────────────────────────
cat("\n=== DATA VALIDATION ===\n")

completeness <- hpi %>%
  group_by(country, dwelling_type) %>%
  summarise(
    n_quarters = n(),
    min_date = min(time),
    max_date = max(time),
    .groups = "drop"
  )

# Show country coverage
country_coverage <- completeness %>%
  group_by(country) %>%
  summarise(min_q = min(n_quarters), .groups = "drop") %>%
  arrange(desc(min_q))

cat("\nCountries and minimum quarters:\n")
print(country_coverage, n = 40)

cat("\nFinal dataset:", nrow(hpi), "observations\n")
cat("Countries:", length(unique(hpi$country)), "\n")
cat("  ", paste(sort(unique(hpi$country)), collapse = ", "), "\n")
cat("Dwelling types:", paste(unique(hpi$dwelling_type), collapse = ", "), "\n")
cat("Time range:", as.character(min(hpi$time)), "to", as.character(max(hpi$time)), "\n")

# ── Save ──────────────────────────────────────────────────────────
write_csv(hpi, "../data/hpi_quarterly.csv")
cat("\nSaved to data/hpi_quarterly.csv\n")
