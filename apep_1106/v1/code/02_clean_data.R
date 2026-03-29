# 02_clean_data.R — Construct analysis panel
# APEP-1106: The Pollinator Dividend

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Load raw data
# -------------------------------------------------------------------
bee_counts <- readRDS("../data/gbif_bee_counts.rds")
beetle_counts <- readRDS("../data/gbif_beetle_counts.rds")
insecta_counts <- readRDS("../data/gbif_insecta_counts.rds")
sugar_beet <- readRDS("../data/eurostat_sugar_beet.rds")
derog_panel <- readRDS("../data/derogation_panel.rds")
first_derog <- readRDS("../data/first_derogation.rds")

# -------------------------------------------------------------------
# 2. Classify countries as sugar beet producers
# -------------------------------------------------------------------
# Identify EU countries with substantial sugar beet production
# Eurostat geo codes are ISO-2 for country-level
sb_country <- sugar_beet %>%
  filter(nchar(as.character(geo)) == 2) %>%  # Country-level only
  mutate(country_iso2 = as.character(geo),
         year = as.numeric(time)) %>%
  filter(year >= 2013, year <= 2018) %>%  # Pre-ban average
  group_by(country_iso2) %>%
  summarize(avg_sb_area_ha = mean(values, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(avg_sb_area_ha))

# Median split for "sugar beet country" classification
sb_median <- median(sb_country$avg_sb_area_ha[sb_country$avg_sb_area_ha > 0], na.rm = TRUE)
sb_country <- sb_country %>%
  mutate(sugar_beet_country = as.integer(avg_sb_area_ha >= sb_median))

cat("Sugar beet area median threshold:", sb_median, "ha\n")
cat("Countries above median:", sum(sb_country$sugar_beet_country == 1), "\n")
cat("Countries below median:", sum(sb_country$sugar_beet_country == 0), "\n")

# -------------------------------------------------------------------
# 3. Build country-year panel
# -------------------------------------------------------------------
eu_countries <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE",
                  "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV",
                  "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
                  "SI", "ES", "SE")

panel <- expand.grid(
  country_iso2 = eu_countries,
  year = 2013:2022,
  stringsAsFactors = FALSE
)

# Merge bee counts
panel <- panel %>%
  left_join(bee_counts %>% rename(bee_obs = count), by = c("country_iso2", "year"))

# Merge beetle counts (placebo)
panel <- panel %>%
  left_join(beetle_counts %>% rename(beetle_obs = count), by = c("country_iso2", "year"))

# Merge insecta counts (normalization)
panel <- panel %>%
  left_join(insecta_counts %>% rename(insecta_obs = count), by = c("country_iso2", "year"))

# Merge derogation indicator
panel <- panel %>%
  left_join(derog_panel, by = c("country_iso2", "year")) %>%
  mutate(has_derogation = ifelse(is.na(has_derogation), 0L, has_derogation))

# Merge first derogation year
panel <- panel %>%
  left_join(first_derog, by = "country_iso2") %>%
  mutate(first_derog_year = ifelse(is.na(first_derog_year), 0L, first_derog_year))

# Merge sugar beet classification
panel <- panel %>%
  left_join(sb_country %>% select(country_iso2, sugar_beet_country, avg_sb_area_ha),
            by = "country_iso2") %>%
  mutate(sugar_beet_country = ifelse(is.na(sugar_beet_country), 0L, sugar_beet_country))

# -------------------------------------------------------------------
# 4. Construct outcome variables
# -------------------------------------------------------------------
panel <- panel %>%
  mutate(
    # Bee share of insecta observations (effort-normalized)
    bee_share = ifelse(insecta_obs > 0, bee_obs / insecta_obs, NA_real_),
    # Log bee observations (with small constant for zeros)
    log_bee_obs = log(bee_obs + 1),
    # Log insecta (effort control)
    log_insecta = log(insecta_obs + 1),
    # Beetle share (placebo outcome)
    beetle_share = ifelse(insecta_obs > 0, beetle_obs / insecta_obs, NA_real_),
    # Treatment variables
    # Post-ban period (ban effective Dec 2018, so 2019+ is post)
    post_ban = as.integer(year >= 2019),
    # Country ever received derogation
    ever_derog = as.integer(first_derog_year > 0),
    # Derogation × sugar beet interaction (triple-diff treatment)
    treat_dd = has_derogation,
    treat_ddd = has_derogation * sugar_beet_country,
    # Event time for Callaway-Sant'Anna
    # For never-treated: first_derog_year stays 0 (never-treated group)
    gvar = ifelse(first_derog_year > 0, first_derog_year, 0)
  )

# -------------------------------------------------------------------
# 5. Country name mapping for tables
# -------------------------------------------------------------------
country_names <- c(
  AT = "Austria", BE = "Belgium", BG = "Bulgaria", HR = "Croatia",
  CY = "Cyprus", CZ = "Czechia", DK = "Denmark", EE = "Estonia",
  FI = "Finland", FR = "France", DE = "Germany", GR = "Greece",
  HU = "Hungary", IE = "Ireland", IT = "Italy", LV = "Latvia",
  LT = "Lithuania", LU = "Luxembourg", MT = "Malta", NL = "Netherlands",
  PL = "Poland", PT = "Portugal", RO = "Romania", SK = "Slovakia",
  SI = "Slovenia", ES = "Spain", SE = "Sweden"
)
panel$country_name <- country_names[panel$country_iso2]

# -------------------------------------------------------------------
# 6. Validation checks
# -------------------------------------------------------------------
cat("\n=== PANEL DIAGNOSTICS ===\n")
cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Countries:", n_distinct(panel$country_iso2), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Derogation countries:", sum(panel$ever_derog == 1 & panel$year == 2019), "\n")
cat("Never-treated countries:", sum(panel$ever_derog == 0 & panel$year == 2019), "\n")
cat("Sugar beet countries:", sum(panel$sugar_beet_country == 1 & panel$year == 2019), "\n")

# Check for zeros/NAs
cat("Bee obs = 0:", sum(panel$bee_obs == 0, na.rm = TRUE), "\n")
cat("Bee obs = NA:", sum(is.na(panel$bee_obs)), "\n")

# Drop country-years with zero insecta observations (no GBIF coverage)
n_before <- nrow(panel)
panel <- panel %>% filter(!is.na(insecta_obs) & insecta_obs > 0)
cat("Dropped", n_before - nrow(panel), "rows with zero/NA insecta observations\n")
cat("Final panel:", nrow(panel), "rows\n")

# Treated units count
n_treated <- panel %>%
  filter(treat_dd == 1) %>%
  n_distinct()
cat("Treated country-years:", n_treated, "\n")

# -------------------------------------------------------------------
# 7. Save analysis dataset
# -------------------------------------------------------------------
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nAnalysis panel saved to data/analysis_panel.rds\n")
