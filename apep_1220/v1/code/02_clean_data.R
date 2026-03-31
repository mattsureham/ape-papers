## 02_clean_data.R — Clean and merge Statistics Denmark datasets
## apep_1220: Denmark Property Tax Reform and Housing Market Lock-in

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Grundskyld rates (EJDSK2)
# ============================================================

cat("=== Cleaning grundskyld rates ===\n")

ejdsk2 <- readRDS(file.path(data_dir, "ejdsk2_grundskyld.rds"))

# Parse Danish decimal format (comma -> period)
ejdsk2 <- ejdsk2 %>%
  mutate(
    value = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(TID),
    municipality = OMRÅDE,
    tax_type = SKATPRO
  ) %>%
  select(municipality, tax_type, year, value)

# Keep grundskyld promille only (the main land tax rate)
grundskyld <- ejdsk2 %>%
  filter(tax_type == "Grundskyldspromille") %>%
  select(municipality, year, grundskyld_promille = value)

# Remove national and regional aggregates (keep only municipality codes)
# Municipality codes are 3-digit (101-860)
grundskyld <- grundskyld %>%
  filter(!municipality %in% c("Hele landet")) %>%
  filter(!grepl("^Region", municipality))

cat(sprintf("  Municipalities: %d\n", n_distinct(grundskyld$municipality)))
cat(sprintf("  Years: %d (%d-%d)\n", n_distinct(grundskyld$year),
            min(grundskyld$year), max(grundskyld$year)))

# Calculate treatment dose: percentage change in grundskyld from 2023 to 2024
dose <- grundskyld %>%
  filter(year %in% c(2023, 2024)) %>%
  pivot_wider(names_from = year, values_from = grundskyld_promille,
              names_prefix = "gs_") %>%
  mutate(
    dose_pct_change = (gs_2024 - gs_2023) / gs_2023 * 100,
    dose_abs_change = gs_2024 - gs_2023
  )

cat(sprintf("\n  Treatment dose summary (pct change in grundskyld):\n"))
cat(sprintf("    Mean: %.1f%%\n", mean(dose$dose_pct_change, na.rm = TRUE)))
cat(sprintf("    Median: %.1f%%\n", median(dose$dose_pct_change, na.rm = TRUE)))
cat(sprintf("    Min: %.1f%% (%s)\n",
            min(dose$dose_pct_change, na.rm = TRUE),
            dose$municipality[which.min(dose$dose_pct_change)]))
cat(sprintf("    Max: %.1f%% (%s)\n",
            max(dose$dose_pct_change, na.rm = TRUE),
            dose$municipality[which.max(dose$dose_pct_change)]))

# ============================================================
# 2. Property taxes (ESKAT)
# ============================================================

cat("\n=== Cleaning property taxes ===\n")

eskat <- readRDS(file.path(data_dir, "eskat_taxes.rds"))

eskat <- eskat %>%
  mutate(
    value = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(TID),
    municipality = OMRÅDE,
    tax_var = SKATGRL
  ) %>%
  select(municipality, tax_var, year, value) %>%
  filter(!municipality %in% c("Hele landet"))

# Pivot to wide format
eskat_wide <- eskat %>%
  mutate(tax_var = case_when(
    grepl("Afgiftspligtig grundværdi", tax_var) ~ "assessed_land_value_mio",
    grepl("Forskelsværdi", tax_var) ~ "difference_value_mio",
    grepl("Ejendomsvurdering", tax_var) ~ "total_assessment_mio",
    grepl("Ejendomsskatter i alt", tax_var) ~ "total_property_tax_1000kr",
    TRUE ~ tax_var
  )) %>%
  pivot_wider(names_from = tax_var, values_from = value)

cat(sprintf("  ESKAT municipalities: %d\n", n_distinct(eskat_wide$municipality)))
cat(sprintf("  Years: %d-%d\n", min(eskat_wide$year), max(eskat_wide$year)))

# ============================================================
# 3. Forced sales (TVANG3)
# ============================================================

cat("\n=== Cleaning forced sales ===\n")

tvang3 <- readRDS(file.path(data_dir, "tvang3_forced_sales.rds"))

tvang3 <- tvang3 %>%
  mutate(
    forced_sales = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(TID),
    municipality = OMRÅDE
  ) %>%
  select(municipality, year, forced_sales) %>%
  filter(!municipality %in% c("Hele landet")) %>%
  filter(!grepl("^Region|^Landsdel", municipality))

cat(sprintf("  TVANG3 municipalities: %d\n", n_distinct(tvang3$municipality)))
cat(sprintf("  Years: %d-%d\n", min(tvang3$year), max(tvang3$year)))

# ============================================================
# 4. House prices (LABY22) — by municipality group
# ============================================================

cat("\n=== Cleaning house prices (LABY22) ===\n")

laby22 <- readRDS(file.path(data_dir, "laby22_prices.rds"))

laby22 <- laby22 %>%
  mutate(
    value = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(TID),
    muni_group = KOMGRP,
    property_type = EJENDOMSKATE,
    metric = BNØGLE
  ) %>%
  select(muni_group, property_type, metric, year, value)

cat(sprintf("  LABY22 rows: %d\n", nrow(laby22)))
cat(sprintf("  Years: %d-%d\n", min(laby22$year), max(laby22$year)))

# ============================================================
# 5. Monthly sales (EJ131) — by region
# ============================================================

cat("\n=== Cleaning monthly sales (EJ131) ===\n")

ej131 <- readRDS(file.path(data_dir, "ej131.rds"))

ej131 <- ej131 %>%
  mutate(
    value = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(substr(TID, 1, 4)),
    month = as.integer(substr(TID, 6, 7)),
    region = REGION,
    property_type = EJENDOMSKATE,
    metric = BNØGLE
  ) %>%
  select(region, property_type, metric, year, month, value)

cat(sprintf("  EJ131 rows: %d\n", nrow(ej131)))
cat(sprintf("  Years: %d-%d\n", min(ej131$year), max(ej131$year)))

# ============================================================
# 6. HPI quarterly (EJENEU) — national
# ============================================================

cat("\n=== Cleaning HPI (EJENEU) ===\n")

ejeneu <- readRDS(file.path(data_dir, "ejeneu_hpi.rds"))

ejeneu <- ejeneu %>%
  mutate(
    hpi = as.numeric(gsub(",", ".", INDHOLD)),
    year = as.integer(substr(TID, 1, 4)),
    quarter = as.integer(substr(TID, 6, 6)),
    urban_type = URBANGRAD,
    exp_type = UDGTYP
  ) %>%
  select(urban_type, exp_type, year, quarter, hpi)

cat(sprintf("  EJENEU rows: %d\n", nrow(ejeneu)))

# ============================================================
# 7. Build municipality-year analysis panel
# ============================================================

cat("\n=== Building analysis panel ===\n")

# Merge grundskyld rates with ESKAT property tax data
panel <- grundskyld %>%
  left_join(eskat_wide, by = c("municipality", "year"))

# Merge forced sales
panel <- panel %>%
  left_join(tvang3, by = c("municipality", "year"))

# Add treatment dose
panel <- panel %>%
  left_join(
    dose %>% select(municipality, dose_pct_change, dose_abs_change,
                     gs_2023, gs_2024),
    by = "municipality"
  )

# Create treatment variables
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2024),
    dose_x_post = dose_pct_change * post,
    # Standardize dose for regression
    dose_std = (dose_pct_change - mean(dose_pct_change, na.rm = TRUE)) /
      sd(dose_pct_change, na.rm = TRUE)
  )

# Log outcomes (handle zeros)
panel <- panel %>%
  mutate(
    log_total_tax = log(pmax(total_property_tax_1000kr, 1)),
    log_assessment = log(pmax(total_assessment_mio, 1)),
    log_forced_sales = log(pmax(forced_sales, 1))
  )

cat(sprintf("  Panel: %d municipality-years\n", nrow(panel)))
cat(sprintf("  Municipalities: %d\n", n_distinct(panel$municipality)))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Post-reform observations: %d\n", sum(panel$post == 1, na.rm = TRUE)))
cat(sprintf("  Dose coverage: %d municipalities with dose\n",
            sum(!is.na(panel$dose_pct_change) & panel$year == 2023)))

# ============================================================
# 8. Save clean datasets
# ============================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(dose, file.path(data_dir, "treatment_dose.rds"))
saveRDS(laby22, file.path(data_dir, "laby22_clean.rds"))
saveRDS(ej131, file.path(data_dir, "ej131_clean.rds"))
saveRDS(ejeneu, file.path(data_dir, "ejeneu_clean.rds"))

# ============================================================
# 9. Summary statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

# Pre-reform summary (2016-2023)
pre <- panel %>% filter(year >= 2016, year <= 2023, !is.na(dose_pct_change))
cat(sprintf("\nPre-reform period (2016-2023):\n"))
cat(sprintf("  Grundskyld promille: mean=%.1f, sd=%.1f\n",
            mean(pre$grundskyld_promille, na.rm = TRUE),
            sd(pre$grundskyld_promille, na.rm = TRUE)))
cat(sprintf("  Total property tax (1000kr): mean=%.0f, sd=%.0f\n",
            mean(pre$total_property_tax_1000kr, na.rm = TRUE),
            sd(pre$total_property_tax_1000kr, na.rm = TRUE)))
cat(sprintf("  Forced sales: mean=%.1f, sd=%.1f\n",
            mean(pre$forced_sales, na.rm = TRUE),
            sd(pre$forced_sales, na.rm = TRUE)))

# Treatment dose distribution
cat(sprintf("\nTreatment dose distribution:\n"))
cat(sprintf("  Q25: %.1f%%\n", quantile(dose$dose_pct_change, 0.25, na.rm = TRUE)))
cat(sprintf("  Q50: %.1f%%\n", quantile(dose$dose_pct_change, 0.50, na.rm = TRUE)))
cat(sprintf("  Q75: %.1f%%\n", quantile(dose$dose_pct_change, 0.75, na.rm = TRUE)))

cat("\nData cleaning complete.\n")
