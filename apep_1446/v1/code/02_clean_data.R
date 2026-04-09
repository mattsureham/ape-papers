## 02_clean_data.R — Build county-month panel + desert classification
## apep_1446: X-waiver elimination and buprenorphine desert entry

source("00_packages.R")

DATA <- "../data"

## ---- 1. Load intermediate data ----
bup <- as.data.table(read_parquet(file.path(DATA, "bup_claims.parquet")))
npi_county <- as.data.table(read_parquet(file.path(DATA, "npi_county.parquet")))
hpsa_counties <- readRDS(file.path(DATA, "hpsa_mh_counties.rds"))

cat(sprintf("Bup claims: %s rows, %d unique NPIs\n",
            format(nrow(bup), big.mark = ","), uniqueN(bup$provider_npi)))

## ---- 2. Merge NPI to county ----
bup_geo <- merge(bup, npi_county[, .(npi, county_fips, state)],
                 by.x = "provider_npi", by.y = "npi", all.x = FALSE)
cat(sprintf("Claims with county: %s (%.1f%% match rate)\n",
            format(nrow(bup_geo), big.mark = ","),
            100 * nrow(bup_geo) / nrow(bup)))

## ---- 3. Identify first billing month per NPI ----
npi_entry <- bup_geo[, .(first_month = min(ym)), by = provider_npi]
cat(sprintf("Total unique buprenorphine NPIs: %d\n", nrow(npi_entry)))

# Treatment date: January 2023
treatment_date <- as.Date("2023-01-01")

# Classify NPIs as pre-existing vs new entrants
npi_entry[, new_entrant := first_month >= treatment_date]
cat(sprintf("Pre-existing NPIs (before Jan 2023): %d\n", sum(!npi_entry$new_entrant)))
cat(sprintf("New entrant NPIs (Jan 2023+): %d\n", sum(npi_entry$new_entrant)))

## ---- 4. Define desert counties ----
# Desert = county with ZERO buprenorphine billing NPIs in the 12 months before treatment
pre_window <- bup_geo[ym >= as.Date("2022-01-01") & ym < treatment_date]
served_counties <- unique(pre_window$county_fips)

# Get all counties from the crosswalk
all_counties <- unique(npi_county$county_fips)
desert_counties <- setdiff(all_counties, served_counties)

cat(sprintf("Total counties in data: %d\n", length(all_counties)))
cat(sprintf("Served counties (≥1 NPI in 2022): %d\n", length(served_counties)))
cat(sprintf("Desert counties (0 NPIs in 2022): %d\n", length(desert_counties)))
cat(sprintf("Desert share: %.1f%%\n", 100 * length(desert_counties) / length(all_counties)))

# HPSA cross-validation
if (length(hpsa_counties) > 0) {
  overlap <- length(intersect(desert_counties, hpsa_counties))
  cat(sprintf("Desert counties also HPSA MH: %d / %d (%.1f%%)\n",
              overlap, length(desert_counties),
              100 * overlap / length(desert_counties)))
}

## ---- 5. Where do new entrants go? ----
# Get county of each new entrant NPI
new_npi_county <- merge(
  npi_entry[new_entrant == TRUE, .(provider_npi)],
  npi_county[, .(npi, county_fips, state)],
  by.x = "provider_npi", by.y = "npi"
)

new_npi_county[, is_desert := county_fips %in% desert_counties]
cat(sprintf("\nNew entrant destination:\n"))
cat(sprintf("  Into desert counties: %d (%.1f%%)\n",
            sum(new_npi_county$is_desert),
            100 * mean(new_npi_county$is_desert)))
cat(sprintf("  Into served counties: %d (%.1f%%)\n",
            sum(!new_npi_county$is_desert),
            100 * (1 - mean(new_npi_county$is_desert))))

## ---- 6. Build county × month panel ----
# Create balanced panel: all counties × all months (2020-2024)
months_seq <- seq(as.Date("2020-01-01"), as.Date("2024-12-01"), by = "month")

panel_base <- CJ(county_fips = all_counties, ym = months_seq)
panel_base[, desert := county_fips %in% desert_counties]
panel_base[, post := ym >= treatment_date]
panel_base[, year := year(ym)]
panel_base[, month_num := month(ym)]
panel_base[, ym_num := year * 12 + month_num]

# Count new entrant NPIs per county-month
entry_by_cm <- bup_geo[provider_npi %in% npi_entry[new_entrant == TRUE, provider_npi],
                        .(provider_npi, county_fips, ym)]
entry_by_cm <- entry_by_cm[, .SD[ym == min(ym)], by = provider_npi]  # First month only
new_counts <- entry_by_cm[, .(new_entrants = .N), by = .(county_fips, ym)]

panel <- merge(panel_base, new_counts, by = c("county_fips", "ym"), all.x = TRUE)
panel[is.na(new_entrants), new_entrants := 0]

# Also count total active NPIs per county-month
active_npi <- bup_geo[, .(provider_npi, county_fips, ym)]
active_counts <- active_npi[, .(active_npis = uniqueN(provider_npi)), by = .(county_fips, ym)]
panel <- merge(panel, active_counts, by = c("county_fips", "ym"), all.x = TRUE)
panel[is.na(active_npis), active_npis := 0]

# Total beneficiaries per county-month
bene_counts <- bup_geo[, .(total_bene = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE)),
                        by = .(county_fips, ym)]
panel <- merge(panel, bene_counts, by = c("county_fips", "ym"), all.x = TRUE)
panel[is.na(total_bene), total_bene := 0]

# Event time relative to January 2023 (month-based)
panel[, event_time := (year(ym) - 2023) * 12 + (month(ym) - 1)]

cat(sprintf("\nPanel: %s county-months\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Counties: %d | Months: %d\n", uniqueN(panel$county_fips), uniqueN(panel$ym)))

## ---- 7. Alternative desert thresholds ----
# Desert ≤ 1 NPI
pre_npi_count <- pre_window[, .(n_pre_npi = uniqueN(provider_npi)), by = county_fips]
all_county_dt <- data.table(county_fips = all_counties)
all_county_dt <- merge(all_county_dt, pre_npi_count, by = "county_fips", all.x = TRUE)
all_county_dt[is.na(n_pre_npi), n_pre_npi := 0]

panel <- merge(panel, all_county_dt[, .(county_fips, n_pre_npi)],
               by = "county_fips", all.x = TRUE)
panel[, desert_1 := n_pre_npi <= 1]
panel[, desert_2 := n_pre_npi <= 2]

cat(sprintf("Desert (≤1 NPI): %d counties\n", sum(all_county_dt$n_pre_npi <= 1)))
cat(sprintf("Desert (≤2 NPI): %d counties\n", sum(all_county_dt$n_pre_npi <= 2)))

## ---- 8. Save ----
write_parquet(panel, file.path(DATA, "county_month_panel.parquet"))
write_parquet(npi_entry, file.path(DATA, "npi_entry.parquet"))
write_parquet(new_npi_county, file.path(DATA, "new_npi_county.parquet"))
saveRDS(desert_counties, file.path(DATA, "desert_counties.rds"))
saveRDS(all_county_dt, file.path(DATA, "county_desert_class.rds"))

cat("\n=== CLEAN DATA COMPLETE ===\n")
