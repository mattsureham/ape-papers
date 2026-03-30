## 01_fetch_data.R — Data acquisition for apep_1155
## El Salvador Gang Truce (2012) — PLOS ONE municipality-level data
##
## Data source: "A Bayesian spatio-temporal model of variation in
## homicide rates for El Salvador" (PLOS ONE, 2024)
## DOI: 10.1371/journal.pone.0330215

source("00_packages.R")
set.seed(20260330)

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download PLOS ONE supplementary files
# ============================================================
cat("=== Downloading PLOS ONE supplementary files ===\n")

plos_base <- "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0330215"
plos_files <- list(
  s1_homicides  = paste0(plos_base, ".s001&type=supplementary"),
  s2_detentions = paste0(plos_base, ".s002&type=supplementary"),
  s3_population = paste0(plos_base, ".s003&type=supplementary")
)

for (fname in names(plos_files)) {
  dest <- file.path(data_dir, paste0(fname, ".csv"))
  if (file.exists(dest) && file.size(dest) > 100) {
    cat(sprintf("  %s already exists, skipping\n", fname))
    next
  }
  cat(sprintf("  Downloading %s...\n", fname))
  resp <- httr::GET(plos_files[[fname]],
                    httr::write_disk(dest, overwrite = TRUE),
                    httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: Failed to download %s (HTTP %d)", fname, httr::status_code(resp)))
  }
}

# Read files
s1_hom <- fread(file.path(data_dir, "s1_homicides.csv"))
s2_det <- fread(file.path(data_dir, "s2_detentions.csv"))
s3_pop <- fread(file.path(data_dir, "s3_population.csv"))

cat(sprintf("  S1 (homicides): %d rows x %d cols\n", nrow(s1_hom), ncol(s1_hom)))
cat(sprintf("  S2 (detentions): %d rows x %d cols\n", nrow(s2_det), ncol(s2_det)))
cat(sprintf("  S3 (population): %d rows x %d cols\n", nrow(s3_pop), ncol(s3_pop)))

# Validate
stopifnot(nrow(s1_hom) >= 5000)
stopifnot(nrow(s2_det) >= 250)
stopifnot(nrow(s3_pop) >= 250)

saveRDS(list(homicides = s1_hom, detentions = s2_det, population = s3_pop),
        file.path(data_dir, "plos_raw.rds"))

cat("=== Data fetch complete ===\n")
cat("  All data from PLOS ONE supplementary files\n")
cat("  DOI: 10.1371/journal.pone.0330215\n")
