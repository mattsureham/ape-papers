# 02_clean_data.R — Clean data and construct variables
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"

# ============================================================
# 1. LOAD RAW DATA
# ============================================================

turnover <- fread(file.path(data_dir, "retail_turnover.csv"))
vat <- fread(file.path(data_dir, "vat_revenue.csv"))
gdp <- fread(file.path(data_dir, "gdp_per_capita.csv"))
unemp <- fread(file.path(data_dir, "unemployment.csv"))

cat("Loaded turnover:", nrow(turnover), "rows\n")
cat("Loaded VAT:", nrow(vat), "rows\n")

# ============================================================
# 2. CONSTRUCT SCM PANEL
# ============================================================

# Create numeric time index for Synth package
# Treatment month: July 2015 (first full month under controls)
treatment_date <- as.Date("2015-07-01")

scm_panel <- turnover %>%
  filter(nace == "G47") %>%
  mutate(
    time_index = (year - 2010) * 12 + month,
    treated = as.integer(country == "EL"),
    post = as.integer(date >= treatment_date),
    country_id = as.integer(factor(country))
  ) %>%
  arrange(country, date)

# Country ID mapping
country_map <- scm_panel %>%
  distinct(country, country_id) %>%
  arrange(country_id)

cat("\nSCM panel:\n")
cat("  Countries:", n_distinct(scm_panel$country), "\n")
cat("  Time periods:", n_distinct(scm_panel$time_index), "\n")
cat("  Greece country_id:", country_map$country_id[country_map$country == "EL"], "\n")

# ============================================================
# 3. CONSTRUCT CROSS-SECTOR DiD PANEL
# ============================================================

# Cash intensity by sector (from ECB/Bank of Greece data cited in idea)
# G473 (fuel): ~90% cash pre-2015 (petrol stations were almost entirely cash)
# G472 (food/beverages): ~75% cash pre-2015
# G471 (non-specialized): ~55% cash pre-2015
# G47 (total): ~65% cash pre-2015

cash_intensity <- tibble(
  nace = c("G471", "G472", "G473", "G47"),
  cash_share = c(0.55, 0.75, 0.90, 0.65),
  sector_label = c("Non-specialized retail",
                   "Food, beverages, tobacco",
                   "Automotive fuel",
                   "Total retail trade")
)

sector_panel <- turnover %>%
  filter(country == "EL", nace %in% c("G471", "G472", "G473")) %>%
  left_join(cash_intensity, by = "nace") %>%
  mutate(
    post = as.integer(date >= treatment_date),
    time_index = (year - 2010) * 12 + month,
    sector_id = as.integer(factor(nace))
  ) %>%
  arrange(nace, date)

cat("\nSector panel (Greece only):\n")
cat("  Sectors:", n_distinct(sector_panel$nace), "\n")
cat("  Time periods:", n_distinct(sector_panel$time_index), "\n")

# ============================================================
# 4. ADD COVARIATES FOR SCM MATCHING
# ============================================================

# Merge annual covariates onto the panel
annual_covariates <- gdp %>%
  left_join(vat, by = c("country", "year")) %>%
  mutate(
    # Normalize VAT to 2014 level for each country
    log_gdp_pc = log(gdp_pc)
  )

# Annual unemployment
annual_unemp <- unemp %>%
  group_by(country, year) %>%
  summarise(unemp_rate = mean(unemp_rate, na.rm = TRUE), .groups = "drop")

annual_covariates <- annual_covariates %>%
  left_join(annual_unemp, by = c("country", "year"))

fwrite(annual_covariates, file.path(data_dir, "annual_covariates.csv"))

# ============================================================
# 5. PRE-TREATMENT AVERAGES FOR SCM PREDICTORS
# ============================================================

# Pre-treatment: 2010-2014 annual averages
pre_treat_covariates <- annual_covariates %>%
  filter(year >= 2010, year <= 2014) %>%
  group_by(country) %>%
  summarise(
    mean_gdp_pc = mean(gdp_pc, na.rm = TRUE),
    mean_unemp = mean(unemp_rate, na.rm = TRUE),
    mean_vat = mean(vat_revenue, na.rm = TRUE),
    .groups = "drop"
  )

# Pre-treatment turnover trajectory (quarterly averages for predictor)
pre_treat_turnover <- turnover %>%
  filter(nace == "G47", year >= 2010, year <= 2014) %>%
  mutate(quarter = ceiling(month / 3),
         year_q = paste0(year, "Q", quarter)) %>%
  group_by(country, year) %>%
  summarise(mean_turnover = mean(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = year, values_from = mean_turnover,
              names_prefix = "turnover_")

pre_treat <- pre_treat_covariates %>%
  left_join(pre_treat_turnover, by = "country")

fwrite(pre_treat, file.path(data_dir, "pre_treatment_covariates.csv"))

# ============================================================
# 6. CONSTRUCT VAT MECHANISM PANEL
# ============================================================

# Normalize VAT revenue to 2014 level for each country
vat_panel <- vat %>%
  group_by(country) %>%
  mutate(
    vat_2014 = vat_revenue[year == 2014][1],
    vat_index = vat_revenue / vat_2014 * 100
  ) %>%
  ungroup() %>%
  filter(!is.na(vat_index)) %>%
  mutate(
    post = as.integer(year >= 2015),
    treated = as.integer(country == "EL")
  )

fwrite(vat_panel, file.path(data_dir, "vat_panel.csv"))

cat("\nVAT mechanism panel:", nrow(vat_panel), "observations\n")

# ============================================================
# 7. SUMMARY STATISTICS
# ============================================================

summary_stats <- turnover %>%
  filter(nace == "G47") %>%
  group_by(country) %>%
  summarise(
    n_months = n(),
    mean_turnover = mean(value, na.rm = TRUE),
    sd_turnover = sd(value, na.rm = TRUE),
    min_turnover = min(value, na.rm = TRUE),
    max_turnover = max(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(country)

cat("\nSummary statistics by country:\n")
print(summary_stats)

fwrite(summary_stats, file.path(data_dir, "summary_stats.csv"))

# Greece sector summary
sector_summary <- sector_panel %>%
  group_by(nace, sector_label, cash_share) %>%
  summarise(
    n_months = n(),
    mean_turnover = mean(value, na.rm = TRUE),
    sd_turnover = sd(value, na.rm = TRUE),
    jul_2015 = value[date == as.Date("2015-07-01")][1],
    jun_2015 = value[date == as.Date("2015-06-01")][1],
    pct_drop = (jul_2015 - jun_2015) / jun_2015 * 100,
    .groups = "drop"
  )

cat("\nGreece sector summary (July 2015 drop by cash intensity):\n")
print(sector_summary %>% select(nace, sector_label, cash_share, pct_drop))

fwrite(sector_summary, file.path(data_dir, "sector_summary.csv"))

# Save cleaned panels
fwrite(scm_panel, file.path(data_dir, "scm_panel.csv"))
fwrite(sector_panel, file.path(data_dir, "sector_panel.csv"))
fwrite(as.data.frame(country_map), file.path(data_dir, "country_map.csv"))
fwrite(cash_intensity, file.path(data_dir, "cash_intensity.csv"))

cat("\n=== DATA CLEANING COMPLETE ===\n")
cat("Files saved to:", data_dir, "\n")
