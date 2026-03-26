# =============================================================================
# 02_clean_data.R — Construct treatment variable and analysis panel
# apep_0998: USAID contract terminations and local employment
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

# ---------------------------------------------------------------------------
# 1. Construct USAID treatment intensity
# ---------------------------------------------------------------------------
cat("=== Constructing USAID treatment intensity ===\n")

usaid_recip <- readRDS(file.path(DATA_DIR, "usaid_recipient.rds"))

# Average USAID contract dollars per county across FY2022-2024
# shape_code is the 5-digit county FIPS
usaid_intensity <- usaid_recip %>%
  mutate(
    county_fips = as.character(shape_code),
    amount = as.numeric(aggregated_amount)
  ) %>%
  filter(!is.na(county_fips) & nchar(county_fips) == 5 & !is.na(amount)) %>%
  group_by(county_fips) %>%
  summarise(
    usaid_total = sum(amount, na.rm = TRUE),
    usaid_avg_annual = mean(amount, na.rm = TRUE),
    n_years = n_distinct(fiscal_year),
    .groups = "drop"
  )

cat(sprintf("Counties with USAID contracts: %d\n", nrow(usaid_intensity)))
cat(sprintf("Total USAID contract value: $%.1fB\n", sum(usaid_intensity$usaid_total) / 1e9))

# ---------------------------------------------------------------------------
# 2. Load and process QWI data
# ---------------------------------------------------------------------------
cat("\n=== Processing QWI data ===\n")

qwi_dt <- readRDS(file.path(DATA_DIR, "qwi_raw.rds"))

# Ensure county_fips is character (5-digit, zero-padded)
qwi_dt[, county_fips := sprintf("%05d", as.integer(county_fips))]

# Create time variable: year-quarter as numeric
qwi_dt[, yq := year + (quarter - 1) / 4]
qwi_dt[, time_id := (year - 2015) * 4 + quarter]  # 1-indexed from 2015Q1

# Separate total employment for normalization
total_emp <- qwi_dt[naics == "00", .(county_fips, year, quarter, time_id,
                                      total_emp = emp)]

# Filter to sector-level outcomes
qwi_sectors <- qwi_dt[naics != "00"]

cat(sprintf("Sector records: %s\n", format(nrow(qwi_sectors), big.mark = ",")))

# ---------------------------------------------------------------------------
# 3. Merge treatment intensity with QWI
# ---------------------------------------------------------------------------
cat("\n=== Merging treatment with outcomes ===\n")

# Get pre-treatment total employment (avg 2022-2024) for normalization
pre_emp <- total_emp[year >= 2022 & year <= 2024,
                     .(avg_total_emp = mean(total_emp, na.rm = TRUE)),
                     by = county_fips]
pre_emp[, county_fips := as.character(county_fips)]

# Merge USAID intensity with employment for normalization
treatment <- as.data.table(merge(usaid_intensity, pre_emp, by = "county_fips", all.x = TRUE))
treatment[, usaid_per_emp := usaid_avg_annual / avg_total_emp]

# Counties without USAID contracts get zero treatment
all_counties <- unique(qwi_dt$county_fips)
treatment_full <- data.table(county_fips = all_counties)
treatment_full <- merge(treatment_full, treatment, by = "county_fips", all.x = TRUE)
treatment_full[is.na(usaid_total), `:=`(
  usaid_total = 0, usaid_avg_annual = 0, n_years = 0, usaid_per_emp = 0
)]

cat(sprintf("Total counties: %d\n", nrow(treatment_full)))
cat(sprintf("Counties with USAID exposure: %d\n", sum(treatment_full$usaid_total > 0)))
cat(sprintf("Counties with zero USAID: %d\n", sum(treatment_full$usaid_total == 0)))

# Create treatment quintiles for event study
treatment_full[usaid_per_emp > 0,
               treat_quintile := cut(usaid_per_emp,
                                     breaks = quantile(usaid_per_emp, probs = c(0, 0.5, 1)),
                                     labels = c("Low", "High"),
                                     include.lowest = TRUE)]
treatment_full[usaid_per_emp == 0, treat_quintile := "None"]

# Handle NAs in usaid_per_emp (counties without employment denominator)
treatment_full[is.na(usaid_per_emp) & usaid_total > 0, usaid_per_emp := 0]

# Binary treatment: top quartile of USAID-exposed counties
threshold <- quantile(treatment_full[usaid_per_emp > 0]$usaid_per_emp, 0.75, na.rm = TRUE)
treatment_full[, high_usaid := as.integer(usaid_per_emp >= threshold & usaid_per_emp > 0)]
treatment_full[is.na(high_usaid), high_usaid := 0L]

cat(sprintf("\nTreatment distribution:\n"))
print(treatment_full[, .N, by = treat_quintile])
cat(sprintf("High-USAID counties (binary): %d\n", sum(treatment_full$high_usaid)))

# Post indicator: 2025Q1 onward
qwi_sectors[, post := as.integer(year >= 2025)]

# State FIPS for clustering
qwi_sectors[, state_fips := substr(county_fips, 1, 2)]

# DMV indicator (DC=11, MD=24, VA=51)
treatment_full[, dmv := as.integer(substr(county_fips, 1, 2) %in% c("11", "24", "51"))]

# ---------------------------------------------------------------------------
# 4. Create analysis panel for NAICS 54 (primary)
# ---------------------------------------------------------------------------
cat("\n=== Building NAICS 54 analysis panel ===\n")

panel_54 <- qwi_sectors[naics == "54"]
panel_54 <- merge(panel_54, treatment_full, by = "county_fips", all.x = TRUE)

# Log employment (adding 1 for zeros)
panel_54[, log_emp := log(emp + 1)]
panel_54[, log_hirn := log(hirn + 1)]
panel_54[, log_sep := log(sep + 1)]

# Asinh transformation (handles zeros better)
panel_54[, asinh_emp := asinh(emp)]
panel_54[, asinh_hirn := asinh(hirn)]

cat(sprintf("NAICS 54 panel: %s rows, %d counties, %d time periods\n",
            format(nrow(panel_54), big.mark = ","),
            uniqueN(panel_54$county_fips),
            uniqueN(panel_54$time_id)))

# ---------------------------------------------------------------------------
# 5. Create panels for other sectors (mechanism + placebo)
# ---------------------------------------------------------------------------
panel_72 <- qwi_sectors[naics == "72"]
panel_72 <- merge(panel_72, treatment_full, by = "county_fips", all.x = TRUE)
panel_72[, log_emp := log(emp + 1)]

panel_mfg <- qwi_sectors[naics == "31-33"]
panel_mfg <- merge(panel_mfg, treatment_full, by = "county_fips", all.x = TRUE)
panel_mfg[, log_emp := log(emp + 1)]

panel_retail <- qwi_sectors[naics == "44-45"]
panel_retail <- merge(panel_retail, treatment_full, by = "county_fips", all.x = TRUE)
panel_retail[, log_emp := log(emp + 1)]

cat(sprintf("NAICS 72 panel: %s rows\n", format(nrow(panel_72), big.mark = ",")))
cat(sprintf("NAICS 31-33 panel: %s rows\n", format(nrow(panel_mfg), big.mark = ",")))
cat(sprintf("NAICS 44-45 panel: %s rows\n", format(nrow(panel_retail), big.mark = ",")))

# ---------------------------------------------------------------------------
# 6. Summary statistics
# ---------------------------------------------------------------------------
cat("\n=== Summary statistics ===\n")

# Pre-treatment (2022-2024) means by treatment group
pre_stats <- panel_54[year >= 2022 & year <= 2024,
                       .(mean_emp = mean(emp, na.rm = TRUE),
                         sd_emp = sd(emp, na.rm = TRUE),
                         mean_hirn = mean(hirn, na.rm = TRUE),
                         mean_sep = mean(sep, na.rm = TRUE),
                         mean_earns = mean(earns, na.rm = TRUE),
                         n_counties = uniqueN(county_fips)),
                       by = high_usaid]

cat("Pre-treatment means by treatment group:\n")
print(pre_stats)

# Save all panels
saveRDS(panel_54, file.path(DATA_DIR, "panel_54.rds"))
saveRDS(panel_72, file.path(DATA_DIR, "panel_72.rds"))
saveRDS(panel_mfg, file.path(DATA_DIR, "panel_mfg.rds"))
saveRDS(panel_retail, file.path(DATA_DIR, "panel_retail.rds"))
saveRDS(treatment_full, file.path(DATA_DIR, "treatment.rds"))

cat("\n=== Cleaning complete ===\n")
