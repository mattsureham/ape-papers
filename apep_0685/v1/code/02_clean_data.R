# 02_clean_data.R — Clean GHGRP data and construct analysis panel
# apep_0685: Canada carbon pricing backstop

source("00_packages.R")

cat("=== Cleaning GHGRP data ===\n")

ghgrp <- readRDS("../data/ghgrp_raw.rds")
wti <- readRDS("../data/wti_prices.rds")

# Rename columns to workable names
setnames(ghgrp, old = c(
  "GHGRP ID No. / No d'identification du PDGES",
  grep("Reference Year", names(ghgrp), value = TRUE)[1],
  "Facility Name / Nom de l'installation",
  grep("Facility Province", names(ghgrp), value = TRUE)[1],
  grep("NAICS Code / Code", names(ghgrp), value = TRUE)[1],
  grep("English.*NAICS.*Description", names(ghgrp), value = TRUE)[1],
  "CO2 (tonnes)",
  "CH4 (tonnes)",
  grep("CH4.*CO2e", names(ghgrp), value = TRUE)[1],
  "N2O (tonnes)",
  grep("N2O.*CO2e", names(ghgrp), value = TRUE)[1],
  grep("Total Emissions", names(ghgrp), value = TRUE)[1],
  "Latitude",
  "Longitude"
), new = c(
  "facility_id", "year", "facility_name", "province",
  "naics_code", "naics_desc",
  "co2_tonnes", "ch4_tonnes", "ch4_co2e",
  "n2o_tonnes", "n2o_co2e",
  "total_co2e", "lat", "lon"
))

# Select key columns
df <- ghgrp[, .(facility_id, year, facility_name, province,
                naics_code, naics_desc,
                co2_tonnes, ch4_tonnes, ch4_co2e,
                n2o_tonnes, n2o_co2e, total_co2e,
                lat, lon)]

cat(sprintf("Initial rows: %d\n", nrow(df)))

# Clean emissions: convert to numeric, handle missing
emission_cols <- c("co2_tonnes", "ch4_tonnes", "ch4_co2e",
                   "n2o_tonnes", "n2o_co2e", "total_co2e")
for (col in emission_cols) {
  df[[col]] <- as.numeric(df[[col]])
}

# Drop rows with missing total emissions
df <- df[!is.na(total_co2e) & total_co2e > 0]
cat(sprintf("After dropping missing/zero emissions: %d\n", nrow(df)))

# Drop blank/missing province
df <- df[province != "" & !is.na(province)]
cat(sprintf("After dropping missing province: %d\n", nrow(df)))

# === Define treatment groups ===
# Backstop provinces: ON, SK, MB, NB — received federal backstop April 2019
# Control: BC (carbon tax since 2008), QC (cap-and-trade since 2013)
# AB: own system (SGER/CCIR/TIER) — ambiguous, exclude from main spec
# NS, NL, PE, territories: mixed/late adoption

df[, treatment_group := fcase(
  province %in% c("Ontario", "Saskatchewan", "Manitoba", "New Brunswick"), "backstop",
  province %in% c("British Columbia", "Quebec"), "control",
  province == "Alberta", "alberta",
  default = "other"
)]

cat("\nTreatment groups:\n")
print(df[, .N, by = treatment_group][order(-N)])

# Post-treatment indicator (April 2019 → affects full year 2019+)
df[, post := as.integer(year >= 2019)]

# Treatment × Post
df[, treated := as.integer(treatment_group == "backstop")]
df[, treat_post := treated * post]

# First treatment year for CS-DiD
df[, first_treat := fifelse(treatment_group == "backstop", 2019L, 0L)]

# Log emissions
df[, log_total_co2e := log(total_co2e)]
df[, log_co2 := log(pmax(co2_tonnes, 1))]
df[, log_ch4_co2e := log(pmax(ch4_co2e, 1))]
df[, log_n2o_co2e := log(pmax(n2o_co2e, 1))]

# NAICS 2-digit sector
df[, naics2 := substr(as.character(naics_code), 1, 2)]

# Energy-intensive sectors
df[, energy_intensive := as.integer(naics2 %in% c("21", "22", "31", "32", "33"))]
# 21=Mining/Oil/Gas, 22=Utilities, 31-33=Manufacturing

# Merge WTI oil prices
df <- merge(df, wti, by = "year", all.x = TRUE)

# Create WTI x sector interaction
df[, wti_energy := wti_annual * energy_intensive]

# === Main analysis sample: backstop vs control ===
analysis <- df[treatment_group %in% c("backstop", "control")]
cat(sprintf("\nMain analysis sample (backstop + control): %d observations\n", nrow(analysis)))
cat(sprintf("Unique facilities: %d\n", uniqueN(analysis$facility_id)))
cat(sprintf("Backstop facilities (any year): %d\n",
            uniqueN(analysis[treatment_group == "backstop"]$facility_id)))
cat(sprintf("Control facilities (any year): %d\n",
            uniqueN(analysis[treatment_group == "control"]$facility_id)))

# Year distribution
cat("\nObservations by year:\n")
print(analysis[, .N, by = year][order(year)])

# Summary statistics
cat("\nSummary of total_co2e (tonnes) in analysis sample:\n")
print(summary(analysis$total_co2e))

# Save
saveRDS(df, "../data/panel_full.rds")
saveRDS(analysis, "../data/panel_analysis.rds")
cat("\nPanel data saved.\n")
