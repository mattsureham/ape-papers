# 01_fetch_data.R — Download IRS Exempt Organizations Business Master File
# apep_0716: Nonprofit Disclosure Cost Bunching

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----- IRS EO BMF: Four regional CSV files -----
# Documentation: https://www.irs.gov/charities-non-profits/exempt-organizations-business-master-file-extract-eo-bmf
base_url <- "https://www.irs.gov/pub/irs-soi/"
files <- paste0("eo", 1:4, ".csv")

all_data <- list()

for (f in files) {
  dest <- file.path(data_dir, f)
  url <- paste0(base_url, f)

  if (!file.exists(dest)) {
    cat(sprintf("Downloading %s...\n", f))
    download.file(url, dest, mode = "wb", quiet = FALSE)
  } else {
    cat(sprintf("%s already exists, skipping download.\n", f))
  }

  # Read with data.table for speed
  dt <- fread(dest, showProgress = FALSE)
  cat(sprintf("  %s: %d rows, %d cols\n", f, nrow(dt), ncol(dt)))
  all_data[[f]] <- dt
}

# Combine all four regional files
eo_bmf <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\nCombined EO BMF: %d total organizations\n", nrow(eo_bmf)))

# ----- Basic validation -----
# Check required columns exist
required_cols <- c("EIN", "STATE", "REVENUE_AMT", "ASSET_AMT", "NTEE_CD")
missing <- setdiff(required_cols, names(eo_bmf))
if (length(missing) > 0) {
  # Try alternative column names (IRS sometimes changes headers)
  cat("WARNING: Missing expected columns:", paste(missing, collapse = ", "), "\n")
  cat("Available columns:", paste(names(eo_bmf), collapse = ", "), "\n")
  stop("Cannot proceed without revenue data. Check IRS BMF column names.")
}

# Report revenue distribution
cat(sprintf("\nOrganizations with positive revenue: %d\n",
            sum(eo_bmf$REVENUE_AMT > 0, na.rm = TRUE)))
cat(sprintf("Organizations with revenue $50K-$300K: %d\n",
            sum(eo_bmf$REVENUE_AMT >= 50000 & eo_bmf$REVENUE_AMT <= 300000, na.rm = TRUE)))
cat(sprintf("Organizations with revenue $150K-$250K: %d\n",
            sum(eo_bmf$REVENUE_AMT >= 150000 & eo_bmf$REVENUE_AMT <= 250000, na.rm = TRUE)))

# Quick bunching check at $200K
rev <- eo_bmf$REVENUE_AMT
bin_below <- sum(rev >= 195000 & rev < 200000, na.rm = TRUE)
bin_above <- sum(rev >= 200000 & rev < 205000, na.rm = TRUE)
cat(sprintf("\nQuick bunching check ($5K bins):\n"))
cat(sprintf("  $195K-$200K: %d\n", bin_below))
cat(sprintf("  $200K-$205K: %d\n", bin_above))
cat(sprintf("  Ratio (below/above): %.2f\n", bin_below / bin_above))

# Save combined data
saveRDS(eo_bmf, file.path(data_dir, "eo_bmf_combined.rds"))
cat(sprintf("\nSaved combined data to %s\n", file.path(data_dir, "eo_bmf_combined.rds")))
