## 02_clean_data.R — Assign PDR, construct analysis panel
## apep_0668: The Pollinator Penalty

source("code/00_packages.R")

cat("=== Constructing analysis panel ===\n")

crop_data <- readRDS("data/crop_data_raw.rds")

# ------------------------------------------------------------------
# 1. Define pollinator dependence ratios (Klein et al. 2007)
# ------------------------------------------------------------------
# Source: Klein, A.-M. et al. (2007). "Importance of pollinators in
# changing landscapes for world crops." Proc. R. Soc. B, 274, 303-313.
#
# PDR = proportion of crop production dependent on animal pollination
# 0 = no dependence (wind/self-pollinated)
# Values from Table 1 / supplementary classification of Klein et al.

pdr_map <- tribble(
  ~crop_code, ~crop_name,         ~pdr,  ~crop_group,
  "C1100",    "Wheat",            0.00,  "Cereal",
  "C1200",    "Barley",           0.00,  "Cereal",
  "C1300",    "Maize (grain)",    0.00,  "Cereal",
  "C1500",    "Oats",             0.00,  "Cereal",
  "C1400",    "Rye",              0.00,  "Cereal",
  "C1600",    "Triticale",        0.00,  "Cereal",
  "C1700",    "Rice",             0.00,  "Cereal",
  "R2000",    "Sugar beet",       0.00,  "Root",
  "R1000",    "Potatoes",         0.00,  "Root",
  "I1110",    "Rapeseed",         0.25,  "Oilseed",
  "I1130",    "Soybeans",         0.25,  "Oilseed",
  "I1140",    "Linseed",          0.25,  "Oilseed",
  "I1120",    "Sunflower seed",   0.65,  "Oilseed"
)

cat(sprintf("PDR map: %d crops defined\n", nrow(pdr_map)))
cat(sprintf("  Zero PDR: %d crops\n", sum(pdr_map$pdr == 0)))
cat(sprintf("  Positive PDR: %d crops\n", sum(pdr_map$pdr > 0)))

# ------------------------------------------------------------------
# 2. Define EU27 member states
# ------------------------------------------------------------------

eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE")

cat(sprintf("EU27 countries: %d\n", length(eu27)))

# ------------------------------------------------------------------
# 3. Define derogation countries
# ------------------------------------------------------------------
# Source: EFSA emergency authorization database + EC records
# Article 53 derogations for neonicotinoid use, 2019-2022
# Ended by ECJ Case C-162/21 (January 19, 2023)

derogation_countries <- c("AT", "BE", "HR", "DK", "ES", "FI", "FR",
                          "LT", "PL", "RO", "SK")

cat(sprintf("Derogation countries: %d\n", length(derogation_countries)))
cat(sprintf("Non-derogation countries: %d\n",
            length(setdiff(eu27, derogation_countries))))

# ------------------------------------------------------------------
# 4. Filter and merge
# ------------------------------------------------------------------

panel <- crop_data |>
  filter(country %in% eu27) |>
  inner_join(pdr_map, by = "crop_code") |>
  filter(year >= 2000, year <= 2023) |>
  filter(!is.na(yield), yield > 0) |>
  mutate(
    post_ban  = as.integer(year >= 2019),
    derog     = as.integer(country %in% derogation_countries),
    log_yield = log(yield),
    derog_period = as.integer(year >= 2019 & year <= 2022),
    post_ecj = as.integer(year >= 2023),
    country_crop = paste(country, crop_code, sep = "_"),
    crop_year    = paste(crop_code, year, sep = "_"),
    country_year = paste(country, year, sep = "_"),
    high_pdr     = as.integer(pdr > 0)
  )

cat(sprintf("\nAnalysis panel: %d observations\n", nrow(panel)))
cat(sprintf("Countries: %d\n", n_distinct(panel$country)))
cat(sprintf("Crops: %d\n", n_distinct(panel$crop_code)))
cat(sprintf("Years: %s - %s\n", min(panel$year), max(panel$year)))

# Country-crop panel balance
balance <- panel |>
  group_by(country, crop_code) |>
  summarise(n_years = n(), .groups = "drop")

cat(sprintf("Country-crop pairs: %d\n", nrow(balance)))
cat(sprintf("Mean years per pair: %.1f\n", mean(balance$n_years)))

# ------------------------------------------------------------------
# 5. Summary statistics
# ------------------------------------------------------------------

cat("\n=== Summary by derogation status ===\n")
panel |>
  group_by(derog) |>
  summarise(
    n_obs     = n(),
    n_country = n_distinct(country),
    n_crop    = n_distinct(crop_code),
    mean_yield = mean(yield, na.rm = TRUE),
    sd_yield   = sd(yield, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

cat("\n=== Summary by PDR group ===\n")
panel |>
  mutate(pdr_group = case_when(
    pdr == 0    ~ "Zero PDR",
    pdr <= 0.25 ~ "Low PDR (0.25)",
    TRUE        ~ "High PDR (0.65)"
  )) |>
  group_by(pdr_group) |>
  summarise(
    n_obs     = n(),
    n_crops   = n_distinct(crop_code),
    mean_yield = mean(yield, na.rm = TRUE),
    sd_yield   = sd(yield, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# ------------------------------------------------------------------
# 6. Save
# ------------------------------------------------------------------

saveRDS(panel, "data/analysis_panel.rds")
cat("\nSaved data/analysis_panel.rds\n")
