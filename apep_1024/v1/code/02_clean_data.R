# 02_clean_data.R — Clean and prepare DPE data for bunching analysis
# apep_1024: France DPE Rental Ban Bunching

source("00_packages.R")

dt <- fread("../data/dpe_raw.csv")
cat(sprintf("Loaded %d raw records\n", nrow(dt)))

# --- Variable construction ---

# Parse date
dt[, date := as.Date(date_etablissement_dpe)]
dt[, year := year(date)]
dt[, month := month(date)]
dt[, quarter := quarter(date)]
dt[, year_quarter := paste0(year, "Q", quarter)]

# Rename consumption variable for convenience
setnames(dt, "conso_5_usages_par_m2_ep", "conso", skip_absent = TRUE)
setnames(dt, "emission_ges_5_usages_par_m2", "ghg", skip_absent = TRUE)

# Validate consumption is numeric
dt[, conso := as.numeric(conso)]
dt[, ghg := as.numeric(ghg)]

# Drop records with missing consumption
n_before <- nrow(dt)
dt <- dt[!is.na(conso) & conso > 0 & conso < 1000]
cat(sprintf("Dropped %d records with missing/extreme consumption (retained %d)\n",
            n_before - nrow(dt), nrow(dt)))

# Surface area
dt[, surface := as.numeric(surface_habitable_immeuble)]
dt[, small_property := fifelse(!is.na(surface) & surface < 40, 1L, 0L)]

# Extract departement from postal code
dt[, dept := substr(code_postal_ban, 1, 2)]

# Define rental market tightness (major urban areas)
tight_market_depts <- c("75", "92", "93", "94", "69", "13", "31", "33", "59", "67")
dt[, tight_market := fifelse(dept %in% tight_market_depts, 1L, 0L)]

# Paris IDF specifically
idf_depts <- c("75", "77", "78", "91", "92", "93", "94", "95")
dt[, idf := fifelse(dept %in% idf_depts, 1L, 0L)]

# Period indicators
dt[, post_2023 := fifelse(date >= as.Date("2023-01-01"), 1L, 0L)]
dt[, post_2024 := fifelse(date >= as.Date("2024-01-01"), 1L, 0L)]
dt[, post_jul2024 := fifelse(date >= as.Date("2024-07-01"), 1L, 0L)]

# July 2024 small-property reform indicator
dt[, reform_exposed := fifelse(small_property == 1L & post_jul2024 == 1L, 1L, 0L)]

# --- Create binned consumption variable ---
# 5 kWh/m2 bins for bunching analysis
dt[, conso_bin5 := floor(conso / 5) * 5]

# 2 kWh/m2 bins for finer analysis
dt[, conso_bin2 := floor(conso / 2) * 2]

# 1 kWh/m2 bins for the sharpest view
dt[, conso_bin1 := floor(conso)]

# --- Distance to thresholds ---
dt[, dist_420 := conso - 420]   # Negative = below (F or better), Positive = above (G)
dt[, dist_330 := conso - 330]   # Negative = below (E or better), Positive = above (F)
dt[, dist_250 := conso - 250]   # Negative = below (D or better), Positive = above (E)
dt[, dist_110 := conso - 110]   # Placebo: B/C threshold

# --- Summary statistics ---
cat("\n=== CLEANED DATA SUMMARY ===\n")
cat(sprintf("Total records: %d\n", nrow(dt)))
cat(sprintf("Date range: %s to %s\n", min(dt$date, na.rm = TRUE), max(dt$date, na.rm = TRUE)))
cat(sprintf("Consumption range: %.1f to %.1f kWh/m2/yr\n",
            min(dt$conso), max(dt$conso)))

cat("\nRecords by year:\n")
print(dt[, .N, by = year][order(year)])

cat("\nRecords by DPE label:\n")
print(dt[, .N, by = etiquette_dpe][order(etiquette_dpe)])

cat("\nSmall properties (<40m2): ", sum(dt$small_property, na.rm = TRUE), "\n")
cat("Tight market records: ", sum(dt$tight_market, na.rm = TRUE), "\n")
cat("IDF records: ", sum(dt$idf, na.rm = TRUE), "\n")

# Save cleaned data
fwrite(dt, "../data/dpe_clean.csv")
cat("\nSaved cleaned data to data/dpe_clean.csv\n")
