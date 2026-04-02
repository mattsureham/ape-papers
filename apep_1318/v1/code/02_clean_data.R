# 02_clean_data.R — Construct analysis panel from quarterly registrations
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

source("00_packages.R")

cat("=== Loading raw data ===\n")

# Load AMLD5 panel (treatment assignments)
amld5 <- fread("../data/amld5_transposition_panel.csv")

# Load quarterly business registrations (primary outcome)
qreg_raw <- fread("../data/eurostat_quarterly_registrations.csv")
cat("Quarterly registrations raw:", nrow(qreg_raw), "rows\n")

# Parse dates
qreg_raw[, year := as.integer(format(as.IDate(TIME_PERIOD), "%Y"))]
qreg_raw[, quarter := as.integer(format(as.IDate(TIME_PERIOD), "%m")) %/% 3]
qreg_raw[quarter == 0, quarter := 4]
# Create year-quarter numeric
qreg_raw[, yq := year + (quarter - 1) / 4]

# Focus on REG (registrations), total business economy, seasonally adjusted index
eu_codes <- amld5$geo

# Use seasonally/calendar adjusted data (SCA) with index base 2015/2021
reg <- qreg_raw[indic_bt == "REG" & geo %in% eu_codes]
cat("After filtering EU27+UK, REG:", nrow(reg), "\n")

# Check what units and adjustments are available
cat("Units:", paste(unique(reg$unit), collapse = ", "), "\n")
cat("S_adj:", paste(unique(reg$s_adj), collapse = ", "), "\n")
cat("NACE:", paste(unique(reg$nace_r2), collapse = ", "), "\n")

# Prefer: SCA (seasonally+calendar adjusted), total economy, index
reg_main <- reg[s_adj == "SCA" & nace_r2 == "B-S_X_O_S94" & unit == "I15"]
cat("Main panel (SCA, total, I15):", nrow(reg_main), "rows\n")

# If I15 not available, try I21 (2021 base)
if (nrow(reg_main) < 100) {
  reg_main <- reg[s_adj == "SCA" & nace_r2 == "B-S_X_O_S94" & unit == "I21"]
  cat("Trying I21 base:", nrow(reg_main), "rows\n")
}

# If SCA not available, fall back to NSA
if (nrow(reg_main) < 100) {
  reg_main <- reg[s_adj == "NSA" & nace_r2 == "B-S_X_O_S94" & unit %in% c("I15", "I21")]
  cat("Falling back to NSA:", nrow(reg_main), "rows\n")
}

# If total economy not available, aggregate
if (nrow(reg_main) < 100) {
  reg_main <- reg[s_adj %in% c("SCA", "NSA") & unit %in% c("I15", "I21")]
  reg_main <- reg_main[, .(values = mean(values, na.rm = TRUE)), by = .(geo, year, quarter, yq)]
  cat("Aggregated across NACE:", nrow(reg_main), "rows\n")
}

stopifnot(nrow(reg_main) > 0)

# Clean
reg_panel <- reg_main[!is.na(values), .(geo, year, quarter, yq, reg_index = values)]
cat("Clean registration panel:", nrow(reg_panel), "rows\n")
cat("Countries:", length(unique(reg_panel$geo)), "\n")
cat("Year range:", paste(range(reg_panel$year), collapse = " - "), "\n")

# Financial sector registrations (mechanism: opacity-sensitive sectors)
reg_fin <- reg[nace_r2 %in% c("K-N") & s_adj == "SCA" & unit %in% c("I15", "I21") &
                 geo %in% eu_codes & !is.na(values)]
if (nrow(reg_fin) > 50) {
  reg_fin <- reg_fin[, .(geo, year, quarter, yq, reg_index_finance = values)]
  cat("Financial sector panel:", nrow(reg_fin), "rows\n")
} else {
  reg_fin <- NULL
  cat("Financial sector: insufficient data\n")
}

# Manufacturing registrations (placebo: should not respond to ownership transparency)
reg_mfg <- reg[nace_r2 %in% c("B-E") & s_adj == "SCA" & unit %in% c("I15", "I21") &
                 geo %in% eu_codes & !is.na(values)]
if (nrow(reg_mfg) > 50) {
  reg_mfg <- reg_mfg[, .(geo, year, quarter, yq, reg_index_mfg = values)]
  cat("Manufacturing sector panel:", nrow(reg_mfg), "rows\n")
} else {
  reg_mfg <- NULL
  cat("Manufacturing sector: insufficient data\n")
}

# Load World Bank FDI (annual — for secondary outcome)
fdi_raw <- fread("../data/worldbank_fdi_raw.csv")
fdi <- merge(fdi_raw, amld5[, .(geo, country_iso3)], by = "country_iso3")
cat("FDI panel:", nrow(fdi), "rows\n")

# Also load annual enterprise births for robustness
bd_raw <- fread("../data/eurostat_enterprise_births_raw.csv")
# Parse the time column
bd_raw[, year := as.integer(format(as.IDate(time), "%Y"))]
bd_annual <- bd_raw[geo %in% eu_codes & !is.na(values),
                    .(enterprise_births = sum(values, na.rm = TRUE)),
                    by = .(geo, year)]
cat("Annual enterprise births:", nrow(bd_annual), "rows, years",
    paste(range(bd_annual$year), collapse = "-"), "\n")

cat("\n=== Constructing quarterly analysis panel ===\n")

# Expand treatment to quarterly
panel <- merge(reg_panel, amld5, by = "geo", all.x = TRUE)

# Treatment indicators at quarterly level
# register_open_quarter: Q1 of the open year (conservative)
panel[, register_open_yq := register_open_year]
panel[, register_closed_yq := register_closed_year]

# register_public: 1 if public register is accessible in that quarter
panel[, register_public := fifelse(
  yq >= register_open_yq &
    (is.na(register_closed_yq) | yq < register_closed_yq),
  1L, 0L
)]

# Callaway-Sant'Anna: first treatment period (year for simplicity)
panel[, first_treat_year := register_open_year]
# UK pre-AMLD5, set to 0 for never-treated in CS
panel[geo == "UK", first_treat_year := 0L]

# Post-CJEU reversal indicator
panel[, post_cjeu := fifelse(year >= 2023, 1L, 0L)]
panel[, rolled_back := fifelse(!is.na(register_closed_year) & yq >= register_closed_yq, 1L, 0L)]

# High secrecy
median_fsi <- median(amld5$fsi_score, na.rm = TRUE)
panel[, high_secrecy := fifelse(fsi_score > median_fsi, 1L, 0L)]

# Log registration index
panel[, log_reg := log(reg_index)]

# Merge financial and manufacturing sector data
if (!is.null(reg_fin)) {
  panel <- merge(panel, reg_fin, by = c("geo", "year", "quarter", "yq"), all.x = TRUE)
  panel[, log_reg_finance := log(reg_index_finance)]
}
if (!is.null(reg_mfg)) {
  panel <- merge(panel, reg_mfg, by = c("geo", "year", "quarter", "yq"), all.x = TRUE)
  panel[, log_reg_mfg := log(reg_index_mfg)]
}

# Drop UK (always treated, use as separate comparison)
panel_main <- panel[geo != "UK"]

cat("\n=== Panel Summary ===\n")
cat("Main panel (ex-UK):", nrow(panel_main), "rows\n")
cat("Countries:", length(unique(panel_main$geo)), "\n")
cat("Quarters:", length(unique(panel_main$yq)), "\n")
cat("Year range:", paste(range(panel_main$year), collapse = " - "), "\n")
cat("Mean reg index:", round(mean(panel_main$reg_index, na.rm = TRUE), 1), "\n")
cat("SD reg index:", round(sd(panel_main$reg_index, na.rm = TRUE), 1), "\n")
cat("Register public (obs):", sum(panel_main$register_public == 1), "\n")
cat("Register rolled back (obs):", sum(panel_main$rolled_back == 1), "\n")

# Treatment status by year
cat("\nTreatment status by year:\n")
print(panel_main[, .(n = .N,
                      pct_public = round(mean(register_public) * 100, 1),
                      pct_rolled_back = round(mean(rolled_back) * 100, 1)),
                 by = year][order(year)])

# Countries by treatment group
cat("\nCountries that rolled back:\n")
print(amld5[!is.na(register_closed_year), .(geo, register_open_year, register_closed_year, fsi_score)])
cat("\nCountries that maintained:\n")
print(amld5[is.na(register_closed_year) & geo != "UK", .(geo, register_open_year, fsi_score)])

# Save
fwrite(panel_main, "../data/analysis_panel.csv")
fwrite(panel, "../data/analysis_panel_with_uk.csv")

# Also save annual FDI panel for secondary analysis
fdi_panel <- merge(
  CJ(geo = amld5[geo != "UK"]$geo, year = 2008:2023),
  amld5, by = "geo", all.x = TRUE
)
fdi_panel <- merge(fdi_panel, fdi[, .(geo, year, fdi)], by = c("geo", "year"), all.x = TRUE)
fdi_panel[, register_public := fifelse(
  year >= register_open_year & (is.na(register_closed_year) | year < register_closed_year),
  1L, 0L
)]
fdi_panel[, log_fdi := log(pmax(fdi, 1))]
fdi_panel[, rolled_back := fifelse(!is.na(register_closed_year) & year >= register_closed_year, 1L, 0L)]
fdi_panel[, high_secrecy := fifelse(fsi_score > median_fsi, 1L, 0L)]
fwrite(fdi_panel, "../data/fdi_panel.csv")
cat("Saved analysis_panel.csv, analysis_panel_with_uk.csv, fdi_panel.csv\n")
