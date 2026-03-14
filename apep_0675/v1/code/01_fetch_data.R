## 01_fetch_data.R — Fetch Eurostat data for carbon tax analysis
## apep_0675

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

## 1. Gas prices for household consumers (semi-annual, decomposed)
cat("Fetching nrg_pc_202 (gas prices)...\n")
gas_prices <- get_eurostat("nrg_pc_202", time_format = "raw")
cat(sprintf("  nrg_pc_202: %d rows\n", nrow(gas_prices)))
stopifnot("nrg_pc_202 returned no data" = nrow(gas_prices) > 0)

## 2. Household gas consumption (annual)
cat("Fetching nrg_d_hhq (household energy consumption)...\n")
hh_energy <- get_eurostat("nrg_d_hhq", time_format = "raw")
cat(sprintf("  nrg_d_hhq: %d rows\n", nrow(hh_energy)))
stopifnot("nrg_d_hhq returned no data" = nrow(hh_energy) > 0)

## 3. Energy poverty: inability to keep home warm
cat("Fetching ilc_mdes01 (energy poverty)...\n")
energy_poverty <- get_eurostat("ilc_mdes01", time_format = "raw")
cat(sprintf("  ilc_mdes01: %d rows\n", nrow(energy_poverty)))
stopifnot("ilc_mdes01 returned no data" = nrow(energy_poverty) > 0)

## 4. Heating degree days (annual)
cat("Fetching nrg_chdd_a (heating degree days)...\n")
hdd <- get_eurostat("nrg_chdd_a", time_format = "raw")
cat(sprintf("  nrg_chdd_a: %d rows\n", nrow(hdd)))
stopifnot("nrg_chdd_a returned no data" = nrow(hdd) > 0)

## Save raw data
saveRDS(gas_prices, "../data/gas_prices_raw.rds")
saveRDS(hh_energy, "../data/hh_energy_raw.rds")
saveRDS(energy_poverty, "../data/energy_poverty_raw.rds")
saveRDS(hdd, "../data/hdd_raw.rds")

cat("=== All data fetched and saved ===\n")
