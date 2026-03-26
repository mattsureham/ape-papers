# 02_clean_data.R — Build analysis panel from fetched data
# Merges Comtrade product-level exports with energy intensity measures

library(dplyr)
library(tidyr)
library(readr)

data_dir <- file.path(dirname(getwd()), "data")

# ============================================================
# Load raw data
# ============================================================
comtrade <- readRDS(file.path(data_dir, "comtrade_egypt_exports.rds"))
energy_int <- readRDS(file.path(data_dir, "energy_intensity.rds"))
hs_isic <- readRDS(file.path(data_dir, "hs_to_isic.rds"))
wb_macro <- readRDS(file.path(data_dir, "wb_egypt_macro.rds"))

cat("Raw Comtrade records:", nrow(comtrade), "\n")
cat("Columns:", paste(names(comtrade), collapse = ", "), "\n")

# ============================================================
# 1. Clean Comtrade export data
# ============================================================

# Identify key columns (API v1 uses different names than legacy)
# Common columns: cmdCode (HS code), primaryValue (trade value), period (year)
ct_cols <- names(comtrade)
cat("Comtrade columns:\n")
print(ct_cols)

# Standardize column names
ct_clean <- comtrade %>%
  mutate(
    year = as.integer(
      if ("period" %in% ct_cols) period
      else if ("yr" %in% ct_cols) yr
      else fetch_year
    ),
    hs_code = as.character(
      if ("cmdCode" %in% ct_cols) cmdCode
      else if ("cmdcode" %in% ct_cols) cmdcode
      else if ("Commodity.Code" %in% ct_cols) Commodity.Code
      else NA
    ),
    export_value = as.numeric(
      if ("primaryValue" %in% ct_cols) primaryValue
      else if ("TradeValue" %in% ct_cols) TradeValue
      else if ("fobvalue" %in% ct_cols) fobvalue
      else 0
    ),
    hs_desc = if ("cmdDesc" %in% ct_cols) cmdDesc
              else if ("Commodity" %in% ct_cols) Commodity
              else ""
  ) %>%
  filter(
    !is.na(hs_code),
    hs_code != "TOTAL",
    nchar(hs_code) <= 4,  # Keep 2-digit level
    export_value > 0
  )

cat("After initial clean:", nrow(ct_clean), "records\n")

# Extract 2-digit HS code
ct_clean <- ct_clean %>%
  mutate(
    hs2 = substr(gsub("[^0-9]", "", hs_code), 1, 2),
    hs2 = sprintf("%02d", as.integer(hs2))
  ) %>%
  filter(as.integer(hs2) >= 25 & as.integer(hs2) <= 96)  # Manufacturing chapters only

cat("Manufacturing HS chapters:", nrow(ct_clean), "records\n")

# ============================================================
# 2. Merge with energy intensity via HS-ISIC concordance
# ============================================================
panel <- ct_clean %>%
  left_join(hs_isic, by = "hs2") %>%
  left_join(energy_int, by = "isic2") %>%
  filter(!is.na(energy_intensity))

cat("After merging with energy intensity:", nrow(panel), "records\n")
cat("Unique HS2 codes:", n_distinct(panel$hs2), "\n")
cat("Unique ISIC2 sectors:", n_distinct(panel$isic2), "\n")
cat("Year range:", min(panel$year), "-", max(panel$year), "\n")

# ============================================================
# 3. Construct analysis variables
# ============================================================
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2014),
    post_phase2 = as.integer(year >= 2016),  # After EGP devaluation + further tranches
    treat_cont = energy_intensity,  # Continuous treatment
    treat_binary = as.integer(energy_group == "high"),
    log_exports = log(export_value + 1),
    # Interaction terms
    treat_x_post = treat_cont * post,
    treat_binary_x_post = treat_binary * post,
    # Time-varying treatment (phased reform)
    reform_intensity = case_when(
      year < 2014 ~ 0,
      year == 2014 ~ 0.5,   # July 2014 = half year
      year == 2015 ~ 1.0,   # Full first tranche
      year == 2016 ~ 1.3,   # Second tranche
      year >= 2017 ~ 1.5    # Third+ tranches
    ),
    treat_x_reform = treat_cont * reform_intensity
  )

# ============================================================
# 4. Build sector-level aggregated panel
# ============================================================
sector_panel <- panel %>%
  group_by(isic2, sector_name, energy_intensity, energy_group, year) %>%
  summarise(
    total_exports = sum(export_value, na.rm = TRUE),
    n_products = n_distinct(hs2),
    .groups = "drop"
  ) %>%
  mutate(
    post = as.integer(year >= 2014),
    log_exports = log(total_exports + 1),
    treat_cont = energy_intensity,
    treat_binary = as.integer(energy_group == "high"),
    treat_x_post = treat_cont * post
  )

cat("Sector panel:", nrow(sector_panel), "obs (",
    n_distinct(sector_panel$isic2), "sectors x",
    n_distinct(sector_panel$year), "years)\n")

# ============================================================
# 5. Compute pre-reform trends for parallel trends test
# ============================================================
pre_reform <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(isic2) %>%
  mutate(
    year_centered = year - 2013,
    log_exports_demeaned = log_exports - mean(log_exports, na.rm = TRUE)
  ) %>%
  ungroup()

# Pre-reform correlation between energy intensity and export growth
pre_trends <- pre_reform %>%
  group_by(isic2, energy_intensity) %>%
  summarise(
    avg_log_exports = mean(log_exports, na.rm = TRUE),
    export_growth_0510 = (log_exports[year == min(2013, max(year))] -
                           log_exports[year == max(2005, min(year))]) /
      (max(min(2013, max(year)), min(year) + 1) - max(2005, min(year))),
    .groups = "drop"
  )

cat("Pre-reform trends computed for", nrow(pre_trends), "sectors\n")

# ============================================================
# 6. Add macro controls to sector panel
# ============================================================
# Join available macro controls (exchange rate/inflation not in WB data)
macro_cols <- intersect(
  names(wb_macro),
  c("year", "NY.GDP.MKTP.KD.ZG", "NE.EXP.GNFS.KD", "NV.IND.MANF.KD")
)
sector_panel <- sector_panel %>%
  left_join(
    wb_macro %>%
      select(all_of(macro_cols)) %>%
      rename_with(~ case_when(
        . == "NY.GDP.MKTP.KD.ZG" ~ "gdp_growth",
        . == "NE.EXP.GNFS.KD" ~ "total_exports_const",
        . == "NV.IND.MANF.KD" ~ "manuf_va_const",
        TRUE ~ .
      )),
    by = "year"
  )

# ============================================================
# 7. Save analysis-ready datasets
# ============================================================
saveRDS(panel, file.path(data_dir, "product_panel.rds"))
saveRDS(sector_panel, file.path(data_dir, "sector_panel.rds"))
saveRDS(pre_reform, file.path(data_dir, "pre_reform.rds"))

cat("\n=== PANEL SUMMARY ===\n")
cat("Product-level panel:", nrow(panel), "obs\n")
cat("Sector-level panel:", nrow(sector_panel), "obs\n")
cat("  High energy-intensity sectors:", sum(sector_panel$treat_binary == 1), "obs\n")
cat("  Low energy-intensity sectors:", sum(sector_panel$treat_binary == 0), "obs\n")
cat("  Pre-reform obs:", sum(sector_panel$year < 2014), "\n")
cat("  Post-reform obs:", sum(sector_panel$year >= 2014), "\n")

cat("\nData cleaning complete.\n")
