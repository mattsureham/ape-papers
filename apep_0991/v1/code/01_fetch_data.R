## 01_fetch_data.R — Fetch Eurostat fisheries data
## APEP-0991: EU Landing Obligation

source("00_packages.R")

cat("=== Fetching Eurostat fisheries data ===\n")

# ---- 1. Catches by species, area, country (fish_ca_main) ----
cat("Fetching fish_ca_main (catches)...\n")
catches_raw <- get_eurostat("fish_ca_main", time_format = "num")
if (is.null(catches_raw) || nrow(catches_raw) == 0) {
  stop("FATAL: fish_ca_main returned empty. Cannot proceed without catch data.")
}
cat(sprintf("  fish_ca_main: %d rows\n", nrow(catches_raw)))

# ---- 2. Landings by species, area, country (fish_ld_main) ----
cat("Fetching fish_ld_main (landings)...\n")
landings_raw <- get_eurostat("fish_ld_main", time_format = "num")
if (is.null(landings_raw) || nrow(landings_raw) == 0) {
  stop("FATAL: fish_ld_main returned empty. Cannot proceed without landings data.")
}
cat(sprintf("  fish_ld_main: %d rows\n", nrow(landings_raw)))

# ---- 3. Fleet capacity (fish_fleet_gp) ----
cat("Fetching fish_fleet_gp (fleet capacity)...\n")
fleet_raw <- get_eurostat("fish_fleet_gp", time_format = "num")
if (is.null(fleet_raw) || nrow(fleet_raw) == 0) {
  warning("fish_fleet_gp returned empty. Fleet analysis will be limited.")
  fleet_raw <- data.frame()
}
cat(sprintf("  fish_fleet_gp: %d rows\n", nrow(fleet_raw)))

# ---- Save raw data ----
saveRDS(catches_raw, "../data/catches_raw.rds")
saveRDS(landings_raw, "../data/landings_raw.rds")
saveRDS(fleet_raw, "../data/fleet_raw.rds")

cat("=== Raw data saved to data/ ===\n")
cat(sprintf("Catches: %d rows | Landings: %d rows | Fleet: %d rows\n",
            nrow(catches_raw), nrow(landings_raw), nrow(fleet_raw)))
