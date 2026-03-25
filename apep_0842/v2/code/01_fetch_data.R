# 01_fetch_data.R — Fetch Eurostat asylum data
# apep_0842: The Safe Country Lottery

source("00_packages.R")

cat("=== Fetching Eurostat asylum decision data (migr_asydcfsta) ===\n")
decisions_raw <- get_eurostat("migr_asydcfsta", time_format = "num")
stopifnot("Failed to fetch migr_asydcfsta" = nrow(decisions_raw) > 0)
cat(sprintf("  Fetched %d rows from migr_asydcfsta\n", nrow(decisions_raw)))

cat("=== Fetching Eurostat asylum application data (migr_asyappctza) ===\n")
applications_raw <- get_eurostat("migr_asyappctza", time_format = "num")
stopifnot("Failed to fetch migr_asyappctza" = nrow(applications_raw) > 0)
cat(sprintf("  Fetched %d rows from migr_asyappctza\n", nrow(applications_raw)))

# Save raw data
saveRDS(decisions_raw, "../data/decisions_raw.rds")
saveRDS(applications_raw, "../data/applications_raw.rds")

cat("=== Raw data saved to data/ ===\n")
cat(sprintf("  Decisions: %d rows, %d cols\n", nrow(decisions_raw), ncol(decisions_raw)))
cat(sprintf("  Applications: %d rows, %d cols\n", nrow(applications_raw), ncol(applications_raw)))
cat(sprintf("  Decision columns: %s\n", paste(names(decisions_raw), collapse = ", ")))
cat(sprintf("  Application columns: %s\n", paste(names(applications_raw), collapse = ", ")))

# Quick diagnostic on decision types
cat("\n=== Decision type codes ===\n")
print(table(decisions_raw$decision))
