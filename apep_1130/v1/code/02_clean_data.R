## 02_clean_data.R — Construct analysis panel
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

source("00_packages.R")

cat("=== Building Analysis Panel ===\n")

# ------------------------------------------------------------------
# 1. Load raw data
# ------------------------------------------------------------------
county_raw <- fread("../data/county_procurement_raw.csv")
treatment <- fread("../data/treatment_panel.csv")

stopifnot(nrow(county_raw) > 0)
cat(sprintf("Raw procurement data: %s rows\n", format(nrow(county_raw), big.mark = ",")))

# Standardize county FIPS to 5 digits
county_raw[, county_fips := sprintf("%05s", county_fips)]
# Remove rows with missing or invalid FIPS
county_raw <- county_raw[!is.na(county_fips) & nchar(county_fips) == 5 & county_fips != "   NA"]

# ------------------------------------------------------------------
# 2. Build sector-level panel (primary analysis unit)
# ------------------------------------------------------------------
# Aggregate county data to sector × FY × type level
sector_year <- county_raw[, .(
  total_amount = sum(amount, na.rm = TRUE),
  n_counties = uniqueN(county_fips),
  n_counties_positive = sum(amount > 0)
), by = .(naics_2d, fiscal_year, type)]

# Pivot: separate columns for all_contracts and sb_setaside
sector_all <- sector_year[type == "all_contracts",
  .(naics_2d, fiscal_year, total_all = total_amount,
    n_counties_all = n_counties)]
sector_sb <- sector_year[type == "sb_setaside",
  .(naics_2d, fiscal_year, total_sb = total_amount,
    n_counties_sb = n_counties)]

sector_panel <- merge(sector_all, sector_sb,
                       by = c("naics_2d", "fiscal_year"), all = TRUE)
sector_panel[is.na(total_sb), total_sb := 0]
sector_panel[is.na(n_counties_sb), n_counties_sb := 0L]

# SB share of total procurement
sector_panel[, sb_share := fifelse(total_all > 0, total_sb / total_all, 0)]

# ------------------------------------------------------------------
# 3. Compute geographic concentration measures
# ------------------------------------------------------------------
# HHI: sum of squared county shares within each sector-year
compute_hhi <- function(amounts) {
  amounts <- amounts[amounts > 0]
  if (length(amounts) == 0) return(NA_real_)
  shares <- amounts / sum(amounts)
  sum(shares^2)
}

# Top-5 county share
compute_top5 <- function(amounts) {
  amounts <- amounts[amounts > 0]
  if (length(amounts) == 0) return(NA_real_)
  total <- sum(amounts)
  top5 <- sum(sort(amounts, decreasing = TRUE)[1:min(5, length(amounts))])
  top5 / total
}

# Compute concentration for SB set-asides
sb_data <- county_raw[type == "sb_setaside" & amount > 0]

hhi_panel <- sb_data[, .(
  hhi_sb = compute_hhi(amount),
  top5_share = compute_top5(amount),
  n_vendors_counties = .N,
  total_sb = sum(amount)
), by = .(naics_2d, fiscal_year)]

sector_panel <- merge(sector_panel, hhi_panel[, .(naics_2d, fiscal_year, hhi_sb, top5_share)],
                       by = c("naics_2d", "fiscal_year"), all.x = TRUE)

# Same for all contracts
all_data <- county_raw[type == "all_contracts" & amount > 0]
hhi_all <- all_data[, .(
  hhi_all = compute_hhi(amount),
  top5_share_all = compute_top5(amount)
), by = .(naics_2d, fiscal_year)]

sector_panel <- merge(sector_panel, hhi_all,
                       by = c("naics_2d", "fiscal_year"), all.x = TRUE)

# ------------------------------------------------------------------
# 4. Compute metro share of procurement
# ------------------------------------------------------------------
# Load RUCC data
rucc_file <- "../data/rucc2013.csv"
if (file.exists(rucc_file)) {
  rucc <- fread(rucc_file)
  if (nrow(rucc) > 0 && "county_fips" %in% names(rucc) && "metro" %in% names(rucc)) {
    rucc[, county_fips := sprintf("%05s", county_fips)]
    # Merge with county procurement
    sb_metro <- merge(sb_data, rucc[, .(county_fips, metro)],
                       by = "county_fips", all.x = TRUE)
    # Counties not in RUCC are typically metro
    sb_metro[is.na(metro), metro := 1L]

    metro_share <- sb_metro[, .(
      metro_amount = sum(amount[metro == 1], na.rm = TRUE),
      nonmetro_amount = sum(amount[metro == 0], na.rm = TRUE),
      total = sum(amount, na.rm = TRUE)
    ), by = .(naics_2d, fiscal_year)]
    metro_share[, metro_share_sb := fifelse(total > 0, metro_amount / total, NA_real_)]

    sector_panel <- merge(sector_panel, metro_share[, .(naics_2d, fiscal_year, metro_share_sb)],
                           by = c("naics_2d", "fiscal_year"), all.x = TRUE)
    cat("Metro share computed from RUCC codes.\n")
  } else {
    cat("RUCC file has unexpected format; skipping metro share.\n")
    sector_panel[, metro_share_sb := NA_real_]
  }
} else {
  cat("No RUCC file found; skipping metro share.\n")
  sector_panel[, metro_share_sb := NA_real_]
}

# ------------------------------------------------------------------
# 5. Merge treatment info and create DiD variables
# ------------------------------------------------------------------
sector_panel <- merge(sector_panel, treatment,
                       by = "naics_2d", all.x = TRUE)

# Group variable for CS: treatment cohort year (NA for never-treated → set to 0)
sector_panel[, g := fifelse(is.na(treat_year), 0L, treat_year)]

# Post-treatment indicator
sector_panel[, post := fifelse(!is.na(treat_year) & fiscal_year >= treat_year, 1L, 0L)]

# Log outcomes
sector_panel[, log_total_all := log(total_all + 1)]
sector_panel[, log_total_sb := log(total_sb + 1)]

# Sector numeric ID for panel
sector_panel[, sector_id := as.integer(factor(naics_2d))]

# ------------------------------------------------------------------
# 6. Summary statistics
# ------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("Sectors: %d (%d treated, %d control)\n",
            uniqueN(sector_panel$naics_2d),
            uniqueN(sector_panel[!is.na(treat_year)]$naics_2d),
            uniqueN(sector_panel[is.na(treat_year)]$naics_2d)))
cat(sprintf("Fiscal years: %d-%d (%d periods)\n",
            min(sector_panel$fiscal_year), max(sector_panel$fiscal_year),
            uniqueN(sector_panel$fiscal_year)))
cat(sprintf("Total observations: %d\n", nrow(sector_panel)))

cat("\nMean outcomes by treatment status:\n")
print(sector_panel[, .(
  mean_total_sb = mean(total_sb, na.rm = TRUE),
  mean_hhi = mean(hhi_sb, na.rm = TRUE),
  mean_metro_share = mean(metro_share_sb, na.rm = TRUE),
  n = .N
), by = .(treated = !is.na(treat_year))])

# ------------------------------------------------------------------
# 7. Save analysis panel
# ------------------------------------------------------------------
fwrite(sector_panel, "../data/sector_panel.csv")
cat("\nSaved: data/sector_panel.csv\n")

# Also save county-level panel for heterogeneity analysis
county_panel <- merge(county_raw, treatment, by = "naics_2d", all.x = TRUE)
county_panel[, g := fifelse(is.na(treat_year), 0L, treat_year)]
county_panel[, post := fifelse(!is.na(treat_year) & fiscal_year >= treat_year, 1L, 0L)]
county_panel[, county_fips := sprintf("%05s", county_fips)]
fwrite(county_panel, "../data/county_panel.csv")
cat("Saved: data/county_panel.csv\n")

cat("\n=== Data cleaning complete ===\n")
