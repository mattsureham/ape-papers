# 01_fetch_data.R — Data acquisition wrapper
# Calls Python script for bulk archive download (faster parallel I/O)
# then verifies output files exist

cat("Running Python bulk data fetcher...\n")
ret <- system("python3 01_fetch_data.py", intern = FALSE)
if (ret != 0) {
  stop("FATAL: Python data fetch failed with exit code ", ret)
}

# Verify output files
required_files <- c(
  "../data/ss_force_month.csv",
  "../data/crime_force_month.csv",
  "../data/force_population.csv",
  "../data/contiguity.json"
)

for (f in required_files) {
  if (!file.exists(f)) {
    stop("FATAL: Missing required file: ", f)
  }
  cat(sprintf("  OK: %s (%s bytes)\n", f, file.size(f)))
}

cat("Data fetch verified.\n")
