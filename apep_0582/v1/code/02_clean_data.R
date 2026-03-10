# 02_clean_data.R — Data cleaning and panel construction
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

# ============================================================================
# 1. LOAD RAW DATA
# ============================================================================
prod_dt <- fread(file.path(data_dir, "industrial_production.csv"))
gas_wide <- fread(file.path(data_dir, "gas_imports_2021.csv"))
nrg_raw <- fread(file.path(data_dir, "sector_gas_intensity.csv"))
subsidies <- fread(file.path(data_dir, "energy_subsidies.csv"))

cat("Loaded data:\n")
cat("  Production:", nrow(prod_dt), "rows\n")
cat("  Gas imports:", nrow(gas_wide), "countries\n")
cat("  Energy balance:", nrow(nrg_raw), "rows\n")
cat("  Subsidies:", nrow(subsidies), "countries\n")

# ============================================================================
# 2. CLEAN RUSSIAN GAS SHARE
# ============================================================================
gas_share <- gas_wide[, .(geo, russian_gas_share)]
gas_share[is.na(russian_gas_share), russian_gas_share := 0]

# Winsorize at 0 and 1
gas_share[russian_gas_share < 0, russian_gas_share := 0]
gas_share[russian_gas_share > 1, russian_gas_share := 1]

cat("\nRussian gas share distribution:\n")
print(gas_share[order(-russian_gas_share)][1:15])

# ============================================================================
# 3. CONSTRUCT SECTOR GAS INTENSITY
# ============================================================================
# Map energy balance sector codes to NACE 2-digit codes
# Note: FC_IND_IS_E (Iron & steel) and FC_IND_NFM_E (Non-ferrous metals)
# both map to C24 (Basic metals). Average their gas intensities.
eb_to_nace <- data.table(
  nrg_bal = c("FC_IND_CPC_E", "FC_IND_FBT_E", "FC_IND_NMM_E", "FC_IND_IS_E",
              "FC_IND_PPP_E", "FC_IND_TE_E", "FC_IND_MAC_E",
              "FC_IND_TL_E", "FC_IND_WP_E"),
  nace = c("C20", "C10", "C23", "C24", "C17", "C29", "C28",
           "C13", "C16"),
  sector_name = c("Chemicals", "Food & beverages", "Non-metallic minerals",
                  "Basic metals", "Paper & pulp", "Transport equipment",
                  "Machinery", "Textiles", "Wood products")
)

# Compute average gas share across reference countries
if ("gas_share" %in% names(nrg_raw)) {
  sector_intensity <- nrg_raw[, .(gas_intensity = mean(gas_share, na.rm = TRUE)),
                               by = nrg_bal]
} else if ("G3000" %in% names(nrg_raw) && "TOTAL" %in% names(nrg_raw)) {
  nrg_raw[, gas_share_calc := fifelse(TOTAL > 0, G3000 / TOTAL, 0)]
  sector_intensity <- nrg_raw[, .(gas_intensity = mean(gas_share_calc, na.rm = TRUE)),
                               by = nrg_bal]
} else {
  # Use absolute gas consumption, then rank-normalize
  cat("Using absolute gas consumption as intensity measure...\n")
  val_col <- intersect(c("gas_consumption_tj", "value"), names(nrg_raw))
  if (length(val_col) == 0) stop("Cannot find gas consumption column in energy balance data")
  setnames(nrg_raw, val_col[1], "gas_val", skip_absent = TRUE)
  sector_intensity <- nrg_raw[, .(gas_consumption = mean(gas_val, na.rm = TRUE)),
                               by = nrg_bal]
  # Normalize to 0-1 scale
  sector_intensity[, gas_intensity := gas_consumption / max(gas_consumption, na.rm = TRUE)]
}

# Merge with NACE codes
sector_intensity <- merge(sector_intensity, eb_to_nace, by = "nrg_bal", all.y = TRUE)

# For sectors without direct gas intensity data, assign low default
# (C11 beverages, C14 apparel, C21 pharma, C22 rubber/plastics,
#  C25 fabricated metals, C26 electronics, C27 electrical, C30 other transport,
#  C31_C32 furniture/other, C33 repair)
low_intensity_sectors <- data.table(
  nace = c("C11", "C14", "C21", "C22", "C25", "C26", "C27", "C30", "C31_C32", "C33"),
  sector_name = c("Beverages", "Apparel", "Pharma", "Rubber/plastics",
                  "Fabricated metals", "Electronics", "Electrical equipment",
                  "Other transport", "Furniture/other mfg", "Repair/installation"),
  gas_intensity = c(0.15, 0.05, 0.10, 0.15, 0.12, 0.05, 0.08, 0.08, 0.05, 0.05)
)

sector_gas <- rbind(
  sector_intensity[!is.na(nace), .(nace, sector_name, gas_intensity)],
  low_intensity_sectors,
  fill = TRUE
)

# Average duplicates (e.g., C24 from IS + NFM)
sector_gas <- sector_gas[, .(gas_intensity = mean(gas_intensity, na.rm = TRUE),
                              sector_name = first(sector_name)),
                          by = nace]

# Normalize so max = 1
sector_gas[, gas_intensity := gas_intensity / max(gas_intensity, na.rm = TRUE)]

cat("\nSector gas intensity:\n")
print(sector_gas[order(-gas_intensity)])

fwrite(sector_gas, file.path(data_dir, "sector_gas_intensity_clean.csv"))

# ============================================================================
# 4. CONSTRUCT ANALYSIS PANEL
# ============================================================================
cat("\n=== Constructing Analysis Panel ===\n")

# Clean production data
panel <- prod_dt[, .(geo, nace, date, year, month, prod_index)]

# Parse date if needed
if (is.character(panel$date)) panel[, date := as.Date(date)]

# Create time variable (months since Jan 2017)
panel[, time_index := (year - 2017) * 12 + month]

# Merge Russian gas share
panel <- merge(panel, gas_share, by = "geo", all.x = TRUE)

# Merge sector gas intensity
panel <- merge(panel, sector_gas[, .(nace, gas_intensity, sector_name)],
               by = "nace", all.x = TRUE)

# Merge subsidies
panel <- merge(panel, subsidies[, .(geo, subsidy_pct_gdp)],
               by = "geo", all.x = TRUE)

# Drop observations with missing treatment variables
panel <- panel[!is.na(russian_gas_share) & !is.na(gas_intensity)]

# Create treatment variables
panel[, post := as.integer(date >= as.Date("2022-03-01"))]
panel[, exposure := russian_gas_share * gas_intensity]
panel[, treatment := exposure * post]

# Log production (for percent interpretation)
panel[, log_prod := log(prod_index)]

# Create high/low subsidy indicator (above/below median)
med_subsidy <- median(panel[, unique(subsidy_pct_gdp)], na.rm = TRUE)
panel[, high_subsidy := as.integer(subsidy_pct_gdp >= med_subsidy)]

# Create country-sector and time identifiers for FE
panel[, cs_id := paste0(geo, "_", nace)]
panel[, ct_id := paste0(geo, "_", format(date, "%Y-%m"))]
panel[, st_id := paste0(nace, "_", format(date, "%Y-%m"))]
panel[, ym := format(date, "%Y-%m")]

# Summary
cat("\nPanel summary:\n")
cat("  Countries:", panel[, uniqueN(geo)], "\n")
cat("  Sectors:", panel[, uniqueN(nace)], "\n")
cat("  Months:", panel[, uniqueN(date)], "\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  Pre-period obs:", panel[post == 0, .N], "\n")
cat("  Post-period obs:", panel[post == 1, .N], "\n")
cat("  Mean Russian gas share:", round(panel[, mean(unique(russian_gas_share), na.rm = TRUE)], 3), "\n")
cat("  Mean gas intensity:", round(panel[, mean(unique(gas_intensity), na.rm = TRUE)], 3), "\n")

# ============================================================================
# 5. CLEAN PRODUCER PRICE DATA
# ============================================================================
cat("\n=== Cleaning Producer Price Data ===\n")

ppi_raw <- tryCatch(fread(file.path(data_dir, "producer_prices.csv")), error = function(e) NULL)

if (!is.null(ppi_raw) && nrow(ppi_raw) > 0) {
  # Standardize column names
  ppi_names <- names(ppi_raw)
  if ("TIME_PERIOD" %in% ppi_names) setnames(ppi_raw, "TIME_PERIOD", "time")

  # Find the geo and nace columns
  geo_col <- intersect(c("geo", "GEO"), ppi_names)
  nace_col <- intersect(c("nace_r2", "NACE_R2", "nace"), ppi_names)
  val_col <- intersect(c("value", "VALUE"), ppi_names)

  if (length(geo_col) > 0) setnames(ppi_raw, geo_col[1], "geo", skip_absent = TRUE)
  if (length(nace_col) > 0) setnames(ppi_raw, nace_col[1], "nace", skip_absent = TRUE)
  if (length(val_col) > 0) setnames(ppi_raw, val_col[1], "ppi_index", skip_absent = TRUE)

  ppi_raw[, date := as.Date(paste0(time, "-01"), format = "%Y-%m-%d")]
  ppi_raw[, year := year(date)]
  ppi_raw[, month := month(date)]

  ppi_clean <- ppi_raw[, .(geo, nace, date, ppi_index)]
  ppi_clean <- ppi_clean[!is.na(ppi_index)]

  # Merge into panel
  panel <- merge(panel, ppi_clean, by = c("geo", "nace", "date"), all.x = TRUE)
  panel[, log_ppi := log(ppi_index)]
  cat("  PPI data merged:", sum(!is.na(panel$ppi_index)), "obs with PPI values\n")
} else {
  cat("  WARNING: No PPI data available. Cost pass-through analysis will be limited.\n")
  panel[, ppi_index := NA_real_]
  panel[, log_ppi := NA_real_]
}

# ============================================================================
# 6. SAVE FINAL PANEL
# ============================================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\n=== FINAL PANEL ===\n")
cat("Saved analysis_panel.csv:", nrow(panel), "observations\n")
cat("Variables:", paste(names(panel), collapse = ", "), "\n")

# Summary statistics by country
country_summary <- panel[date == max(date),
                          .(russian_gas_share = first(russian_gas_share),
                            subsidy_pct_gdp = first(subsidy_pct_gdp),
                            n_sectors = uniqueN(nace)),
                          by = geo][order(-russian_gas_share)]
cat("\nCountry treatment summary:\n")
print(country_summary)
