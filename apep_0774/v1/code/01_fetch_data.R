# 01_fetch_data.R — Download MSHA data files
# All from arlweb.msha.gov/OpenGovernmentData/

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

base_url <- "https://arlweb.msha.gov/OpenGovernmentData/DataSets"

datasets <- list(
  list(name = "Inspections", file = "Inspections.zip"),
  list(name = "Violations", file = "Violations.zip"),
  list(name = "MinesProdQuarterly", file = "MinesProdQuarterly.zip")
)

for (ds in datasets) {
  url <- paste0(base_url, "/", ds$file)
  dest <- file.path(data_dir, ds$file)
  cat(sprintf("Downloading %s...\n", ds$name))

  result <- tryCatch(
    download.file(url, dest, mode = "wb", quiet = TRUE),
    error = function(e) {
      stop(sprintf("FATAL: Failed to download %s: %s", ds$name, conditionMessage(e)))
    }
  )

  if (result != 0) stop(sprintf("FATAL: Download of %s returned non-zero status", ds$name))

  sz <- file.info(dest)$size
  if (sz < 1e6) stop(sprintf("FATAL: %s is only %.0f bytes — likely a failed download", ds$name, sz))
  cat(sprintf("  -> %.1f MB\n", sz / 1e6))

  # Unzip
  cat(sprintf("  Unzipping %s...\n", ds$name))
  unzip(dest, exdir = data_dir, overwrite = TRUE)
}

# Verify extracted files
cat("\nExtracted files:\n")
for (f in list.files(data_dir, pattern = "\\.txt$")) {
  sz <- file.info(file.path(data_dir, f))$size
  cat(sprintf("  %s: %.1f MB\n", f, sz / 1e6))
}

cat("\nAll MSHA data downloaded and extracted.\n")
