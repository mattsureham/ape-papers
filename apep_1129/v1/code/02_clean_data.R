# ==============================================================================
# 02_clean_data.R — Construct county-year panel with HHI, shift-share IV
# ==============================================================================

source("00_packages.R")

# --- 1. Load data ---
arcos_agg <- fread("../data/arcos_county_distributor_year.csv")
arcos_cy <- fread("../data/arcos_county_year.csv")
county_xw <- fread("../data/county_fips_crosswalk.csv")

cat(sprintf("ARCOS agg: %d rows\n", nrow(arcos_agg)))
cat(sprintf("County crosswalk: %d rows, %.1f%% matched\n",
            nrow(county_xw), 100 * mean(!is.na(county_xw$fips))))

# Merge FIPS codes into ARCOS data
arcos_agg <- merge(arcos_agg, county_xw[!is.na(fips), .(state_abbr, county_name, fips)],
                   by = c("state_abbr", "county_name"), all.x = FALSE)
arcos_cy <- merge(arcos_cy, county_xw[!is.na(fips), .(state_abbr, county_name, fips)],
                  by = c("state_abbr", "county_name"), all.x = FALSE)

cat(sprintf("After FIPS merge: %d agg rows, %d cy rows\n", nrow(arcos_agg), nrow(arcos_cy)))

# --- 2. Compute county-level distributor HHI ---
cat("Computing county-level distributor HHI...\n")

arcos_agg[, county_year_pills := sum(total_pills), by = .(fips, year)]
arcos_agg[, share := total_pills / county_year_pills]
arcos_agg[, share_sq := share^2]

hhi_panel <- arcos_agg[, .(
  hhi = sum(share_sq),
  n_distributors = .N,
  total_pills = sum(total_pills)
), by = .(fips, year)]

cat(sprintf("HHI panel: %d county-years, %d unique counties\n",
            nrow(hhi_panel), uniqueN(hhi_panel$fips)))
cat(sprintf("HHI: mean=%.3f, median=%.3f, p10=%.3f, p90=%.3f\n",
            mean(hhi_panel$hhi), median(hhi_panel$hhi),
            quantile(hhi_panel$hhi, 0.10), quantile(hhi_panel$hhi, 0.90)))

# --- 3. Construct shift-share (Bartik) instrument ---
cat("Constructing shift-share instrument...\n")

# Step 3a: Pre-period (2006) county-level distributor shares
shares_2006 <- arcos_agg[year == 2006, .(fips, distributor, share_2006 = share)]
cat(sprintf("2006 baseline: %d county-distributor pairs in %d counties\n",
            nrow(shares_2006), uniqueN(shares_2006$fips)))

# Step 3b: National-level distributor share changes (shifts)
national_shares <- arcos_agg[, .(national_pills = sum(total_pills)), by = .(distributor, year)]
national_total <- national_shares[, .(total_national = sum(national_pills)), by = year]
national_shares <- merge(national_shares, national_total, by = "year")
national_shares[, national_share := national_pills / total_national]

# Shift: change in national share from 2006 baseline
national_2006 <- national_shares[year == 2006, .(distributor, national_share_2006 = national_share)]
national_shares <- merge(national_shares, national_2006, by = "distributor", all.x = TRUE)
national_shares[is.na(national_share_2006), national_share_2006 := 0]
national_shares[, shift := national_share - national_share_2006]

# Top distributors and their shifts
top_dist <- national_shares[year == 2012][order(-national_share)][1:10]
cat("\nTop 10 distributors (2012 national share):\n")
print(top_dist[, .(distributor, national_share = round(national_share, 4),
                    shift = round(shift, 4))])

# Step 3c: Predicted HHI instrument
# Apply national share changes to local 2006 shares to predict local shares
# Then compute predicted HHI from the predicted local shares
bartik_data <- merge(shares_2006,
                     national_shares[, .(distributor, year, national_share, national_share_2006, shift)],
                     by = "distributor", allow.cartesian = TRUE)

# Predicted local share: scale 2006 local share by ratio of national share changes
# predicted_share_{d,c,t} = share_{d,c,2006} * (national_share_{d,t} / national_share_{d,2006})
bartik_data[national_share_2006 > 0,
            predicted_share := share_2006 * (national_share / national_share_2006)]
bartik_data[national_share_2006 == 0, predicted_share := 0]

# Renormalize so predicted shares sum to 1 within county-year
bartik_data[, share_sum := sum(predicted_share, na.rm = TRUE), by = .(fips, year)]
bartik_data[share_sum > 0, predicted_share := predicted_share / share_sum]

# Predicted HHI = sum of squared predicted shares
bartik_iv <- bartik_data[, .(
  bartik_hhi = sum(predicted_share^2, na.rm = TRUE),
  bartik_linear = sum(share_2006 * shift, na.rm = TRUE)
), by = .(fips, year)]

cat(sprintf("\nPredicted HHI IV: %d county-years\n", nrow(bartik_iv)))
cat(sprintf("Predicted HHI: mean=%.4f, sd=%.4f\n",
            mean(bartik_iv$bartik_hhi), sd(bartik_iv$bartik_hhi)))
cat(sprintf("Correlation(predicted HHI, actual HHI): will be checked in analysis\n"))

# --- 4. Merge panel ---
cat("Merging panel...\n")
panel <- merge(hhi_panel, bartik_iv, by = c("fips", "year"), all.x = TRUE)

# Load ACS controls
acs <- fread("../data/acs_controls.csv")

# For years without ACS (2006-2009), use earliest available year
earliest_acs <- min(acs$year)
for (yr in 2006:(earliest_acs - 1)) {
  proxy <- copy(acs[year == earliest_acs])
  proxy[, year := yr]
  acs <- rbindlist(list(acs, proxy), fill = TRUE)
}

acs[, fips := as.character(fips)]
panel[, fips := as.character(fips)]
panel <- merge(panel, acs[, .(fips, year, population, median_income, white_pop, hs_pop)],
               by = c("fips", "year"), all.x = TRUE)

# Compute derived variables
panel[, pills_per_cap := total_pills / population]
panel[, log_pills_per_cap := log(pills_per_cap + 1)]
panel[, pct_white := white_pop / population * 100]
panel[, pct_hs := hs_pop / population * 100]
panel[, log_med_income := log(median_income + 1)]

# State FIPS for clustering
panel[, state_fips := substr(fips, 1, 2)]

# --- 5. Load CDC overdose data ---
cat("Processing CDC overdose data...\n")
if (file.exists("../data/cdc_overdose_raw.csv")) {
  cdc <- fread("../data/cdc_overdose_raw.csv")
  cat(sprintf("CDC columns: %s\n", paste(names(cdc), collapse = ", ")))

  # Format FIPS
  cdc[, fips := formatC(as.integer(FIPS), width = 5, flag = "0")]
  cdc[, year := as.integer(Year)]
  cdc[, overdose_rate := as.numeric(`Model-based Death Rate`)]

  cdc_clean <- cdc[year %between% c(2006, 2012) & !is.na(overdose_rate),
                   .(fips, year, overdose_rate)]

  panel <- merge(panel, cdc_clean, by = c("fips", "year"), all.x = TRUE)
  cat(sprintf("Overdose data merged: %d/%d county-years (%.0f%%)\n",
              sum(!is.na(panel$overdose_rate)), nrow(panel),
              100 * mean(!is.na(panel$overdose_rate))))
} else {
  panel[, overdose_rate := NA_real_]
  cat("No CDC data file found.\n")
}

# --- 6. Drop counties with missing key variables ---
n_before <- nrow(panel)
panel <- panel[!is.na(population) & population >= 1000 & !is.na(bartik_hhi)]
cat(sprintf("\nDropped %d rows with missing population/IV. Panel: %d county-years\n",
            n_before - nrow(panel), nrow(panel)))

# --- 7. Summary statistics ---
cat("\n=== Final Panel Summary ===\n")
cat(sprintf("Counties: %d | Years: %d | County-years: %d | States: %d\n",
            uniqueN(panel$fips), uniqueN(panel$year), nrow(panel),
            uniqueN(panel$state_fips)))
cat(sprintf("Pills per capita: mean=%.1f, sd=%.1f, median=%.1f\n",
            mean(panel$pills_per_cap, na.rm = TRUE),
            sd(panel$pills_per_cap, na.rm = TRUE),
            median(panel$pills_per_cap, na.rm = TRUE)))
cat(sprintf("HHI: mean=%.3f, sd=%.3f\n", mean(panel$hhi), sd(panel$hhi)))
cat(sprintf("Bartik IV: mean=%.5f, sd=%.5f\n",
            mean(panel$bartik_hhi), sd(panel$bartik_hhi)))
cat(sprintf("Overdose rate coverage: %d/%d county-years (%.0f%%)\n",
            sum(!is.na(panel$overdose_rate)), nrow(panel),
            100 * mean(!is.na(panel$overdose_rate))))

# Save final panel
fwrite(panel, "../data/analysis_panel.csv")
cat("Analysis panel saved.\n")
