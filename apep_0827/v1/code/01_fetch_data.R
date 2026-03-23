# 01_fetch_data.R — Fetch CBS crime and population data for the wietexperiment
# apep_0827: Dutch cannabis supply chain experiment and crime

source("00_packages.R")

# Install cbsodataR if not available
if (!requireNamespace("cbsodataR", quietly = TRUE)) {
  install.packages("cbsodataR", repos = "https://cloud.r-project.org")
}
library(cbsodataR)

# ============================================================================
# Municipality codes
# ============================================================================

treatment_gm <- c("GM0855", "GM0758", "GM0202", "GM0034", "GM0014",
                   "GM0917", "GM0268", "GM0479", "GM0935", "GM1992")
treatment_names <- c("Tilburg", "Breda", "Arnhem", "Almere", "Groningen",
                     "Heerlen", "Nijmegen", "Zaanstad", "Maastricht", "Voorne aan Zee")

control_gm <- c("GM0153", "GM0392", "GM0794", "GM0080", "GM0546",
                 "GM0995", "GM0957", "GM0281", "GM0344", "GM0301")
control_names <- c("Enschede", "Haarlem", "Helmond", "Leeuwarden", "Leiden",
                   "Lelystad", "Roermond", "Tiel", "Utrecht", "Zutphen")

experiment_gm <- c(treatment_gm, control_gm)

# ============================================================================
# Fetch CBS crime data (table 83648NED)
# ============================================================================

cat("Fetching CBS crime data (83648NED) via cbsodataR...\n")

# Fetch the full table — cbsodataR handles pagination automatically
crime_raw <- cbs_get_data("83648NED")

cat(sprintf("Fetched %d raw crime records.\n", nrow(crime_raw)))
stopifnot(nrow(crime_raw) > 0)

# Save raw data
saveRDS(crime_raw, "../data/crime_raw.rds")
cat("Crime data saved.\n")

# ============================================================================
# Fetch population data (table 03759NED)
# ============================================================================

cat("Fetching CBS population data (03759NED) via cbsodataR...\n")

pop_raw <- cbs_get_data("03759NED",
                         select = c("RegioS", "Perioden", "TotaleBevolking_1"))

cat(sprintf("Fetched %d raw population records.\n", nrow(pop_raw)))
stopifnot(nrow(pop_raw) > 0)

saveRDS(pop_raw, "../data/pop_raw.rds")

cat("Data fetch complete.\n")
