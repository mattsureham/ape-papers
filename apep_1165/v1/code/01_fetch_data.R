## 01_fetch_data.R — Fetch Swiss municipal merger and finance data
## apep_1165: Swiss Municipal Mergers and Functional Spending
## Data already downloaded via Python preprocessing. This script validates.

source("00_packages.R")

data_dir <- "../data"

cat("=== Validating data files ===\n")

# Required files
required <- c(
  "mutations_all.json",
  "zh_420.csv", "zh_421.csv", "zh_422.csv", "zh_423.csv",
  "zh_424.csv", "zh_425.csv", "zh_426.csv", "zh_427.csv",
  "zh_428.csv", "zh_429.csv",
  "zh_400.csv", "zh_401.csv",
  "bl_finance.csv"
)

for (f in required) {
  fpath <- file.path(data_dir, f)
  if (!file.exists(fpath)) {
    stop(paste("FATAL: Missing required file:", fpath))
  }
  cat("  OK:", f, "-", file.size(fpath), "bytes\n")
}

cat("\n=== All required data files present ===\n")
