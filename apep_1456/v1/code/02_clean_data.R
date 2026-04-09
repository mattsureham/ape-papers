# 02_clean_data.R — Clean and merge all data sources
# APEP 1456: DPA Enforcement Intensity and Startup Survival

source("00_packages.R")

cat("=== Cleaning data for APEP 1456 ===\n")

# ---------------------------------------------------------------
# 1. Clean Enforcement Tracker data
# ---------------------------------------------------------------
enforcement_raw <- readRDS("../data/enforcement_raw.rds")

# Actual column layout from JSON (columns are offset from assumed names):
# Col 1 = empty/index, Col 2 = ETid, Col 3 = country+flag HTML, Col 4 = DPA name,
# Col 5 = date, Col 6 = fine amount, Col 7 = controller, Col 8 = sector,
# Col 9 = articles, Col 10 = type/summary
enforcement <- enforcement_raw
colnames(enforcement) <- paste0("V", 1:ncol(enforcement))

# Extract country from flag HTML: alt='COUNTRY' or text after <br />
enforcement <- enforcement %>%
  mutate(
    country = str_extract(V3, "(?<=alt=')[^']+"),
    country = str_to_title(country),
    country = str_trim(country)
  )

# Parse fine amount from V6 (remove commas)
enforcement <- enforcement %>%
  mutate(
    fine_eur = str_replace_all(V6, "[^0-9.]", ""),
    fine_eur = as.numeric(fine_eur),
    fine_eur = ifelse(is.na(fine_eur), 0, fine_eur)
  )

# Parse date from V5
enforcement <- enforcement %>%
  mutate(
    date = as.Date(V5, format = "%Y-%m-%d"),
    year = as.integer(format(date, "%Y"))
  ) %>%
  filter(!is.na(year), year >= 2018, year <= 2023)

cat(sprintf("  Unique countries found: %s\n", paste(sort(unique(enforcement$country)), collapse = ", ")))

# Map country names to ISO2 codes for merging with Eurostat
country_map <- c(
  "Austria" = "AT", "Belgium" = "BE", "Bulgaria" = "BG", "Croatia" = "HR",
  "Cyprus" = "CY", "Czech Republic" = "CZ", "Czechia" = "CZ",
  "Denmark" = "DK", "Estonia" = "EE", "Finland" = "FI",
  "France" = "FR", "Germany" = "DE", "Greece" = "EL", "Hungary" = "HU",
  "Ireland" = "IE", "Italy" = "IT", "Latvia" = "LV", "Lithuania" = "LT",
  "Luxembourg" = "LU", "Malta" = "MT", "Netherlands" = "NL",
  "Poland" = "PL", "Portugal" = "PT", "Romania" = "RO",
  "Slovakia" = "SK", "Slovenia" = "SI", "Spain" = "ES", "Sweden" = "SE",
  # Title-case variants from str_to_title
  "Czech republic" = "CZ", "The Netherlands" = "NL"
)

enforcement <- enforcement %>%
  mutate(geo = country_map[country]) %>%
  filter(!is.na(geo))

cat(sprintf("  Parsed %d enforcement records across %d countries\n",
            nrow(enforcement), n_distinct(enforcement$geo)))

# Build country-year enforcement panel
enforcement_panel <- enforcement %>%
  group_by(geo, year) %>%
  summarise(
    n_fines = n(),
    total_fines_eur = sum(fine_eur, na.rm = TRUE),
    .groups = "drop"
  )

# Compute cumulative enforcement measures
enforcement_cumul <- enforcement_panel %>%
  arrange(geo, year) %>%
  group_by(geo) %>%
  mutate(
    cum_fines = cumsum(n_fines),
    cum_fine_eur = cumsum(total_fines_eur)
  ) %>%
  ungroup()

# Determine first enforcement year per country (first year with any fine)
first_enforcement <- enforcement %>%
  group_by(geo) %>%
  summarise(first_fine_year = min(year), .groups = "drop")

cat("  First enforcement years:\n")
print(first_enforcement %>% arrange(first_fine_year))

# ---------------------------------------------------------------
# 2. Clean Eurostat Business Demography
# ---------------------------------------------------------------
bd_data <- readRDS("../data/eurostat_bd.rds")

# Eurostat uses TIME_PERIOD or time — standardize
bd_clean <- bd_data %>%
  rename(year = time) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2008, year <= 2022) %>%
  select(geo, nace_r2, indic_sb, year, values) %>%
  pivot_wider(names_from = indic_sb, values_from = values) %>%
  rename(
    birth_rate = V97020,
    surv_1yr = V97041,
    surv_3yr = V97043,
    emp_share_births = V97120,
    avg_size_births = V97121
  )

# Keep only EU27 countries
eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
           "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
           "PL", "PT", "RO", "SK", "SI", "ES", "SE")

bd_clean <- bd_clean %>%
  filter(geo %in% eu27)

cat(sprintf("  Business demography: %d obs, %d countries, years %d-%d\n",
            nrow(bd_clean), n_distinct(bd_clean$geo),
            min(bd_clean$year), max(bd_clean$year)))

# ---------------------------------------------------------------
# 3. Clean GDP data
# ---------------------------------------------------------------
gdp_data <- readRDS("../data/eurostat_gdp.rds")

gdp_clean <- gdp_data %>%
  rename(year = time) %>%
  mutate(year = as.integer(year)) %>%
  filter(geo %in% eu27, year >= 2008, year <= 2022) %>%
  select(geo, year, values) %>%
  rename(gdp_meur = values)

# ---------------------------------------------------------------
# 4. Clean Unemployment data
# ---------------------------------------------------------------
unemp_data <- readRDS("../data/eurostat_unemp.rds")

unemp_clean <- unemp_data %>%
  rename(year = time) %>%
  mutate(year = as.integer(year)) %>%
  filter(geo %in% eu27, year >= 2008, year <= 2022) %>%
  select(geo, year, values) %>%
  rename(unemp_rate = values)

# ---------------------------------------------------------------
# 5. Merge everything into analysis panel
# ---------------------------------------------------------------

# Expand enforcement panel to include zero-enforcement years for all EU27
full_grid <- expand.grid(
  geo = eu27,
  year = 2008:2022,
  stringsAsFactors = FALSE
)

enforcement_full <- full_grid %>%
  left_join(enforcement_cumul, by = c("geo", "year")) %>%
  mutate(
    n_fines = replace_na(n_fines, 0L),
    total_fines_eur = replace_na(total_fines_eur, 0),
    cum_fines = replace_na(cum_fines, 0L),
    cum_fine_eur = replace_na(cum_fine_eur, 0)
  ) %>%
  # Fix cumulative: fill forward from last observed year
  arrange(geo, year) %>%
  group_by(geo) %>%
  mutate(
    cum_fines = cummax(cum_fines),
    cum_fine_eur = cummax(cum_fine_eur)
  ) %>%
  ungroup()

# Add first enforcement year
enforcement_full <- enforcement_full %>%
  left_join(first_enforcement, by = "geo") %>%
  mutate(
    # Countries that never enforced get 9999L (sentinel for never-treated)
    first_fine_year = replace_na(first_fine_year, 9999L),
    # Binary post-enforcement indicator
    post_enforcement = as.integer(year >= first_fine_year),
    # For CS-DiD: treatment group cohort (0 = never treated)
    cohort = ifelse(first_fine_year < 9999L, first_fine_year, 0L)
  )

# ICT panel (NACE J)
ict_panel <- bd_clean %>%
  filter(nace_r2 == "J") %>%
  left_join(enforcement_full, by = c("geo", "year")) %>%
  left_join(gdp_clean, by = c("geo", "year")) %>%
  left_join(unemp_clean, by = c("geo", "year")) %>%
  mutate(
    log_gdp = log(gdp_meur),
    cum_fines_per_gdp = cum_fine_eur / (gdp_meur * 1e6) * 1e9  # fines per billion GDP
  )

# Construction placebo panel (NACE F)
construction_panel <- bd_clean %>%
  filter(nace_r2 == "F") %>%
  left_join(enforcement_full, by = c("geo", "year")) %>%
  left_join(gdp_clean, by = c("geo", "year")) %>%
  left_join(unemp_clean, by = c("geo", "year")) %>%
  mutate(
    log_gdp = log(gdp_meur),
    cum_fines_per_gdp = cum_fine_eur / (gdp_meur * 1e6) * 1e9
  )

cat(sprintf("\n  ICT panel: %d obs, %d countries\n", nrow(ict_panel), n_distinct(ict_panel$geo)))
cat(sprintf("  Construction panel: %d obs, %d countries\n",
            nrow(construction_panel), n_distinct(construction_panel$geo)))

# ---------------------------------------------------------------
# 6. Save analysis-ready panels
# ---------------------------------------------------------------
saveRDS(ict_panel, "../data/ict_panel.rds")
saveRDS(construction_panel, "../data/construction_panel.rds")
saveRDS(enforcement_full, "../data/enforcement_panel.rds")
saveRDS(first_enforcement, "../data/first_enforcement.rds")

cat("=== Data cleaning complete ===\n")
