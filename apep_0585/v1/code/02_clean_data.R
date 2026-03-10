## 02_clean_data.R — Variable construction for DiD analysis
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1) CONSTRUCT PRODUCTION INDEX PANEL
# ============================================================================

cat("=== Constructing production index panel ===\n")

prod <- fread(paste0(data_dir, "eurostat_prod_index.csv"))

# EU member states that are subject to MDR
eu27 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
          "NL", "PL", "PT", "RO", "SE", "SI", "SK")

# Filter to individual countries only (remove aggregates)
aggregates <- c("EU27_2020", "EU28", "EU27_2007", "EA19", "EA20", "EA21")
prod <- prod[!geo %in% aggregates]

# Add treatment variables
prod[, `:=`(
  is_eu = geo %in% eu27,
  is_meddev = nace == "C325",
  post_mdr = year >= 2021,
  # For event study: relative time to MDR
  event_time = year - 2021,
  # Country identifiers
  country_sector = paste0(geo, "_", nace)
)]

# Summary of available data
cat("  Panel dimensions:\n")
cat("    Countries:", n_distinct(prod$geo), "\n")
cat("    EU countries with C325 data:",
    paste(sort(unique(prod$geo[prod$is_meddev & prod$is_eu])), collapse = ", "), "\n")
cat("    Non-EU countries with C325 data:",
    paste(sort(unique(prod$geo[prod$is_meddev & !prod$is_eu])), collapse = ", "), "\n")
cat("    Sectors:", paste(sort(unique(prod$nace)), collapse = ", "), "\n")
cat("    Years:", paste(range(prod$year), collapse = "-"), "\n")
cat("    Total obs:", nrow(prod), "\n")

# Create balanced panel indicator
balanced <- prod[, .(n_years = n_distinct(year)), by = .(geo, nace)]
prod <- merge(prod, balanced, by = c("geo", "nace"))
prod[, balanced := n_years == max(n_years)]

cat("  Balanced panel obs:", sum(prod$balanced), "\n")

fwrite(prod, paste0(data_dir, "panel_production.csv"))


# ============================================================================
# 2) CONSTRUCT EUDAMED COUNTRY-RISK DISTRIBUTION
# ============================================================================

cat("\n=== Constructing EUDAMED country-risk distribution ===\n")

devices <- fread(paste0(data_dir, "eudamed_device_sample.csv"))

# Clean risk class labels
devices[, risk_class_clean := fcase(
  risk_class == "class-i", "Class I",
  risk_class == "class-iia", "Class IIa",
  risk_class == "class-iib", "Class IIb",
  risk_class == "class-iii", "Class III",
  default = risk_class
)]

# Higher risk = Class IIb or III (most affected by MDR reclassification)
devices[, higher_risk := risk_class %in% c("class-iib", "class-iii")]

# Manufacturer country distribution
mfr_country_dist <- devices[!is.na(mfr_country), .(
  n_devices = .N,
  n_higher_risk = sum(higher_risk),
  pct_higher_risk = mean(higher_risk) * 100
), by = mfr_country][order(-n_devices)]

cat("  Top manufacturer countries:\n")
print(head(mfr_country_dist, 15))

# Rename device_status for consistency
setnames(devices, "device_status", "device_status_clean", skip_absent = TRUE)

# Device status distribution by risk class
status_dist <- devices[!is.na(device_status_clean), .(
  n = .N
), by = .(risk_class_clean, device_status_clean)][order(risk_class_clean, -n)]

cat("\n  Device status by risk class:\n")
print(status_dist)

# Risk class distribution overall
risk_dist <- devices[, .(
  n_sampled = .N,
  pct = round(.N / nrow(devices) * 100, 1)
), by = risk_class_clean][order(risk_class_clean)]

# Merge with population totals
risk_totals <- fread(paste0(data_dir, "eudamed_risk_class_summary.csv"))
risk_totals[, risk_class_clean := fcase(
  risk_class == "class-i", "Class I",
  risk_class == "class-iia", "Class IIa",
  risk_class == "class-iib", "Class IIb",
  risk_class == "class-iii", "Class III"
)]
risk_dist <- merge(risk_dist, risk_totals[, .(risk_class_clean, total_devices)],
                   by = "risk_class_clean", all.x = TRUE)

# Filter to standard risk classes only (remove invalid categories like "class-a",
# "ivd-devices-self-testing", "ivd-general" which have NA total_devices)
risk_dist <- risk_dist[risk_class_clean %in% c("Class I", "Class IIa", "Class IIb", "Class III")]

cat("\n  Risk class distribution:\n")
print(risk_dist)

fwrite(mfr_country_dist, paste0(data_dir, "eudamed_mfr_country_dist.csv"))
fwrite(status_dist, paste0(data_dir, "eudamed_status_by_risk.csv"))
fwrite(risk_dist, paste0(data_dir, "eudamed_risk_distribution.csv"))


# ============================================================================
# 3) CONSTRUCT TREATMENT INTENSITY MEASURE
# ============================================================================

cat("\n=== Constructing treatment intensity ===\n")

# For each EU country with production data, compute their share of higher-risk
# devices in EUDAMED as a cross-sectional measure of MDR exposure

# Map 2-letter EUDAMED country codes to Eurostat geo codes
# (some mismatches: EL vs GR for Greece)
prod_countries <- unique(prod$geo[prod$is_meddev & prod$is_eu])

# Compute treatment intensity from EUDAMED
intensity <- mfr_country_dist[mfr_country %in% c(prod_countries, "GR"), .(
  mfr_country,
  n_devices,
  pct_higher_risk
)]

# Fix Greece code
intensity[mfr_country == "GR", mfr_country := "EL"]

# Merge intensity into panel
prod_panel <- fread(paste0(data_dir, "panel_production.csv"))
prod_panel <- merge(prod_panel, intensity[, .(geo = mfr_country, mdr_exposure = pct_higher_risk)],
                    by = "geo", all.x = TRUE)

# For non-EU or countries without EUDAMED data, set exposure to 0
prod_panel[is.na(mdr_exposure) & !is_eu, mdr_exposure := 0]
prod_panel[is.na(mdr_exposure) & is_eu, mdr_exposure := median(intensity$pct_higher_risk, na.rm = TRUE)]

fwrite(prod_panel, paste0(data_dir, "panel_production_with_intensity.csv"))

cat("  Treatment intensity (% higher-risk devices) by country:\n")
print(prod_panel[is_meddev == TRUE & year == 2021, .(geo, is_eu, mdr_exposure)][order(-mdr_exposure)])


# ============================================================================
# 4) CONSTRUCT FDA TIME SERIES
# ============================================================================

cat("\n=== Constructing FDA time series ===\n")

fda <- fread(paste0(data_dir, "fda_510k_annual.csv"))

# Normalize to 2021 = 100 to match Eurostat production index
fda_total <- fda[device_class == 0]
base_2021 <- fda_total[year == 2021, clearances]

fda_total[, `:=`(
  index_2021 = clearances / base_2021 * 100,
  source = "FDA 510(k)"
)]

# By device class
for (cls in 1:3) {
  base <- fda[device_class == cls & year == 2021, clearances]
  if (length(base) > 0 && base > 0) {
    fda[device_class == cls, index_2021 := clearances / base * 100]
  }
}

fwrite(fda, paste0(data_dir, "fda_510k_indexed.csv"))

cat("  FDA clearances (2021=100):\n")
print(fda_total[, .(year, clearances, index_2021)])


# ============================================================================
# 5) SUMMARY STATISTICS
# ============================================================================

cat("\n=== Computing summary statistics ===\n")

panel <- fread(paste0(data_dir, "panel_production_with_intensity.csv"))

# Summary by treatment status
summ <- panel[, .(
  mean_prod = mean(prod_index, na.rm = TRUE),
  sd_prod = sd(prod_index, na.rm = TRUE),
  n_obs = .N,
  n_countries = n_distinct(geo),
  n_years = n_distinct(year)
), by = .(is_meddev, post_mdr, is_eu)]

cat("  Summary statistics:\n")
print(summ)

# Pre-period balance check
pre <- panel[!post_mdr & is_eu]
pre_balance <- pre[, .(
  mean_prod = mean(prod_index, na.rm = TRUE),
  sd_prod = sd(prod_index, na.rm = TRUE)
), by = .(nace)]
cat("\n  Pre-period means by sector (EU countries):\n")
print(pre_balance)

fwrite(summ, paste0(data_dir, "summary_statistics.csv"))

cat("\nData cleaning complete.\n")
