# ==============================================================================
# 01_fetch_data.R — Data Acquisition from Eurostat
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

source("00_packages.R")

# Italian NUTS2 codes (21 regions)
italy_nuts2 <- c("ITC1", "ITC2", "ITC3", "ITC4", "ITF1", "ITF2", "ITF3",
                 "ITF4", "ITF5", "ITF6", "ITG1", "ITG2", "ITH1", "ITH2",
                 "ITH3", "ITH4", "ITH5", "ITI1", "ITI2", "ITI3", "ITI4")

# ---- 1. Deaths by single year of age, sex, NUTS2 ----
cat("Fetching mortality data (demo_r_magec3)...\n")

# demo_r_magec has single-year-of-age data from 1990-2024
deaths_raw <- get_eurostat("demo_r_magec",
                           filters = list(
                             geo = italy_nuts2,
                             time = 2000:2020
                           ),
                           time_format = "num")

stopifnot(nrow(deaths_raw) > 0)
cat(sprintf("  Deaths data: %d rows\n", nrow(deaths_raw)))

# ---- 2. Population by age group, sex, NUTS2 ----
cat("Fetching population data (demo_r_pjangroup)...\n")

pop_raw <- get_eurostat("demo_r_pjangroup",
                        filters = list(
                          geo = italy_nuts2,
                          time = 2000:2021
                        ),
                        time_format = "num")

stopifnot(nrow(pop_raw) > 0)
cat(sprintf("  Population data: %d rows\n", nrow(pop_raw)))

# ---- 3. Employment rates by age, sex, NUTS2 ----
cat("Fetching employment data (lfst_r_lfe2emprt)...\n")

emp_raw <- get_eurostat("lfst_r_lfe2emprt",
                        filters = list(
                          geo = italy_nuts2,
                          time = 2000:2023
                        ),
                        time_format = "num")

stopifnot(nrow(emp_raw) > 0)
cat(sprintf("  Employment data: %d rows\n", nrow(emp_raw)))

# ---- 4. Save raw data ----
saveRDS(deaths_raw, "../data/deaths_raw.rds")
saveRDS(pop_raw, "../data/pop_raw.rds")
saveRDS(emp_raw, "../data/emp_raw.rds")

cat("Data fetch complete.\n")
