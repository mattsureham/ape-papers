# =============================================================================
# 01_fetch_data.R — Process ARCOS data (fetched via Python from Azure)
# =============================================================================

source("00_packages.R")

cat("Loading ARCOS oxycodone data...\n")
oxy_raw <- fread("../data/oxy_raw.csv")
hydro_raw <- fread("../data/hydro_raw.csv")

cat("Oxycodone rows:", nrow(oxy_raw), "\n")
cat("Hydrocodone rows:", nrow(hydro_raw), "\n")

# ---------------------------------------------------------------------------
# Parse dosage strength (dos_str is already numeric from parquet)
# ---------------------------------------------------------------------------
oxy <- as.data.table(oxy_raw)
setnames(oxy, "dos_str", "dos_mg")

# Check dosage distribution
cat("\nDosage strength distribution (FL + GA + AL):\n")
print(oxy[, .(pills = sum(total_pills)), by = dos_mg][order(dos_mg)])

n_missing <- sum(is.na(oxy$dos_mg))
cat("\nRows with NA dosage:", n_missing, "of", nrow(oxy), "\n")
stopifnot(n_missing / nrow(oxy) < 0.05)

# ---------------------------------------------------------------------------
# Classify high-dose (>=30mg) and aggregate to county-month
# ---------------------------------------------------------------------------
oxy[, high_dose := as.integer(dos_mg >= 30)]

county_month <- oxy[!is.na(dos_mg), .(
  total_oxy_pills = sum(total_pills),
  high_dose_pills = sum(total_pills * high_dose),
  avg_mg = weighted.mean(dos_mg, total_pills)
), by = .(BUYER_STATE, BUYER_COUNTY, year, month)]

county_month[, high_dose_share := high_dose_pills / total_oxy_pills]

# Create time variables
county_month[, ym_int := (year - 2006) * 12 + month]  # months since Jan 2006
county_month[, ym_date := as.Date(sprintf("%04d-%02d-01", as.integer(year), as.integer(month)))]

# ---------------------------------------------------------------------------
# Merge hydrocodone
# ---------------------------------------------------------------------------
hydro <- as.data.table(hydro_raw)
county_month <- merge(county_month, hydro,
                      by = c("BUYER_STATE", "BUYER_COUNTY", "year", "month"),
                      all.x = TRUE)
county_month[is.na(hydro_pills), hydro_pills := 0]
county_month[, oxy_hydro_ratio := total_oxy_pills / (total_oxy_pills + hydro_pills)]

# ---------------------------------------------------------------------------
# Treatment indicators
# ---------------------------------------------------------------------------
# Treatment date: July 2011 (full enforcement of HB 7095)
treatment_ym_int <- (2011 - 2006) * 12 + 7  # = 67
county_month[, fl := as.integer(BUYER_STATE == "FL")]
county_month[, post := as.integer(ym_int >= treatment_ym_int)]
county_month[, treated := fl * post]

# Event time (months relative to July 2011)
county_month[, event_time := ym_int - treatment_ym_int]

# County ID for fixed effects
county_month[, county_id := paste0(BUYER_STATE, "_", BUYER_COUNTY)]

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
cat("\nFinal panel:", nrow(county_month), "county-month observations\n")
cat("Counties:", uniqueN(county_month$county_id), "\n")
cat("FL counties:", uniqueN(county_month[fl == 1]$county_id), "\n")
cat("Control counties:", uniqueN(county_month[fl == 0]$county_id), "\n")
cat("Months:", uniqueN(county_month$ym_int), "\n")
cat("Date range:", as.character(range(county_month$ym_date)), "\n")

fwrite(county_month, "../data/county_month_panel.csv")
cat("Saved to data/county_month_panel.csv\n")

# Also save dosage-level data for robustness (alternative thresholds)
oxy_agg <- oxy[!is.na(dos_mg), .(
  total_pills = sum(total_pills)
), by = .(BUYER_STATE, BUYER_COUNTY, year, month, dos_mg)]
fwrite(oxy_agg, "../data/oxy_by_dosage.csv")
cat("Saved dosage-level data to data/oxy_by_dosage.csv\n")
