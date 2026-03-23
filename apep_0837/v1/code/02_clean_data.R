# 02_clean_data.R — Build analysis panel for R2D triple-diff
source("00_packages.R")

# ============================================================================
# Load raw data
# ============================================================================
long_hours_raw <- readRDS("../data/long_hours_raw.rds")
usual_hours_raw <- readRDS("../data/usual_hours_raw.rds")

# ============================================================================
# Define sample
# ============================================================================

# Treatment country
treated_country <- "FR"

# Control countries: EU members without R2D laws during sample period
# Excluded: ES (2018 R2D), PT (2021), BE (2023), IT (2017 partial)
control_countries <- c("DE", "NL", "AT", "FI", "DK", "CZ", "PL", "HU")

sample_countries <- c(treated_country, control_countries)

# ISCO-08 major groups
# High-connectivity: 1 (Managers), 2 (Professionals), 3 (Technicians)
# Low-connectivity: 7 (Craft), 8 (Plant operators), 9 (Elementary)
# Medium (placebo): 5 (Services/Sales)
isco_high <- c("OC1", "OC2", "OC3")
isco_low  <- c("OC7", "OC8", "OC9")
isco_mid  <- c("OC5")
isco_all  <- c(isco_high, isco_low, isco_mid)

# Year range
year_range <- 2010:2024

# ============================================================================
# 1. Clean long hours data (lfsa_qoe_3a2)
#    Dimensions: sex, isco08, unit, geo, time
# ============================================================================
cat("Cleaning long hours data...\n")
cat("Columns:", paste(names(long_hours_raw), collapse=", "), "\n")

# Check available ISCO codes
avail_isco <- unique(long_hours_raw$isco08)
cat("Available ISCO codes:", paste(sort(avail_isco), collapse=", "), "\n")

# Check available countries
avail_geo <- unique(long_hours_raw$geo)
cat("Available countries:", paste(sort(intersect(avail_geo, sample_countries)), collapse=", "), "\n")

cat("Long hours dimensions:\n")
cat("  age:", paste(sort(unique(long_hours_raw$age)), collapse=", "), "\n")
cat("  wstatus:", paste(sort(unique(long_hours_raw$wstatus)), collapse=", "), "\n")
cat("  unit:", paste(sort(unique(long_hours_raw$unit)), collapse=", "), "\n")

long_hours <- long_hours_raw %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  filter(
    geo %in% sample_countries,
    isco08 %in% isco_all,
    sex == "T",               # Total (both sexes)
    age == "Y15-64",          # Working-age total
    wstatus == "EMP",         # All employed
    unit == "PC",             # Percentage
    year >= min(year_range),
    year <= max(year_range)
  ) %>%
  rename(country = geo, isco = isco08, long_hours_pct = values) %>%
  select(country, isco, year, long_hours_pct) %>%
  filter(!is.na(long_hours_pct))

cat(sprintf("Long hours panel: %d obs, %d countries, %d occupations, years %d-%d\n",
            nrow(long_hours), n_distinct(long_hours$country),
            n_distinct(long_hours$isco),
            min(long_hours$year), max(long_hours$year)))

# ============================================================================
# 2. Clean usual hours data (lfsa_ewhais)
# ============================================================================
cat("\nCleaning usual hours data...\n")
cat("Columns:", paste(names(usual_hours_raw), collapse=", "), "\n")

# Check available ISCO codes in this dataset
avail_isco2 <- unique(usual_hours_raw$isco08)
cat("Available ISCO codes:", paste(sort(intersect(avail_isco2, isco_all)), collapse=", "), "\n")

usual_hours <- usual_hours_raw %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  filter(
    geo %in% sample_countries,
    isco08 %in% isco_all,
    sex == "T",
    worktime == "FT",         # Full-time only
    age == "Y15-64",          # Working-age total
    wstatus == "EMP",         # All employed
    year >= min(year_range),
    year <= max(year_range)
  ) %>%
  rename(country = geo, isco = isco08, usual_hours = values) %>%
  select(country, isco, year, usual_hours) %>%
  filter(!is.na(usual_hours))

cat(sprintf("Usual hours panel: %d obs, %d countries, %d occupations, years %d-%d\n",
            nrow(usual_hours), n_distinct(usual_hours$country),
            n_distinct(usual_hours$isco),
            min(usual_hours$year), max(usual_hours$year)))

# ============================================================================
# 3. Merge and create treatment variables
# ============================================================================
cat("\nMerging panels...\n")

panel <- long_hours %>%
  left_join(usual_hours, by = c("country", "isco", "year"))

# Treatment indicators
panel <- panel %>%
  mutate(
    france     = as.integer(country == "FR"),
    high_conn  = as.integer(isco %in% isco_high),
    low_conn   = as.integer(isco %in% isco_low),
    mid_conn   = as.integer(isco %in% isco_mid),
    post       = as.integer(year >= 2017),
    # Connectivity group label
    conn_group = case_when(
      isco %in% isco_high ~ "High",
      isco %in% isco_low  ~ "Low",
      isco %in% isco_mid  ~ "Medium",
      TRUE ~ "Other"
    ),
    # Triple-diff interaction
    france_high_post = france * high_conn * post,
    # Double interactions
    france_post      = france * post,
    high_post        = high_conn * post,
    france_high      = france * high_conn,
    # Country-occupation FE
    country_isco     = paste0(country, "_", isco),
    # Country-year FE
    country_year     = paste0(country, "_", year),
    # Occupation-year FE
    isco_year        = paste0(isco, "_", year)
  )

cat(sprintf("Final panel: %d obs\n", nrow(panel)))
cat("Country-year cells:\n")
print(table(panel$country, panel$year))

# ============================================================================
# 4. Descriptive statistics for field notes
# ============================================================================
cat("\n--- Key descriptive stats ---\n")
fr_managers <- panel %>%
  filter(country == "FR", isco == "OC1") %>%
  arrange(year) %>%
  select(year, long_hours_pct, usual_hours)
cat("France Managers (ISCO 1) long hours %:\n")
print(as.data.frame(fr_managers))

de_managers <- panel %>%
  filter(country == "DE", isco == "OC1") %>%
  arrange(year) %>%
  select(year, long_hours_pct, usual_hours)
cat("\nGermany Managers (ISCO 1) long hours %:\n")
print(as.data.frame(de_managers))

# ============================================================================
# Save
# ============================================================================
saveRDS(panel, "../data/panel.rds")
cat("\nPanel saved to data/panel.rds\n")
