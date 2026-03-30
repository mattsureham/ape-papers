## 01_fetch_data.R — Fetch MSHA open data
## APEP-1133: The Tenure Shield
##
## Sources: https://arlweb.msha.gov/OpenGovernmentData/OGIMSHA.asp
## All data public domain — no API key required.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE)

## ---- Download helper ----
fetch_msha <- function(filename, url_base = "https://arlweb.msha.gov/OpenGovernmentData/DataSets") {
  zip_path <- file.path(data_dir, filename)
  url <- paste0(url_base, "/", filename)
  if (!file.exists(zip_path)) {
    cat("Downloading", filename, "...\n")
    download.file(url, zip_path, mode = "wb", quiet = FALSE)
  } else {
    cat(filename, "already downloaded.\n")
  }
  zip_path
}

## ---- 1. Accidents ----
cat("\n=== Fetching Accidents ===\n")
acc_zip <- fetch_msha("Accidents.zip")
acc_files <- unzip(acc_zip, list = TRUE)$Name
acc_txt <- acc_files[grepl("\\.txt$", acc_files, ignore.case = TRUE)]
stopifnot("No text file found in Accidents.zip" = length(acc_txt) >= 1)
unzip(acc_zip, files = acc_txt, exdir = data_dir, overwrite = TRUE)

accidents <- fread(file.path(data_dir, acc_txt[1]), sep = "|", header = TRUE,
                   na.strings = c("", "NA", " "))
cat("Accidents loaded:", nrow(accidents), "rows,", ncol(accidents), "cols\n")

## Validate critical fields exist
required_cols <- c("MINE_ID", "TOT_EXPER", "MINE_EXPER", "JOB_EXPER",
                   "DEGREE_INJURY", "DAYS_LOST", "DAYS_RESTRICT",
                   "ACCIDENT_DT", "OCCUPATION_CD", "SUBUNIT_CD")
missing_cols <- setdiff(required_cols, names(accidents))
if (length(missing_cols) > 0) {
  # Try common variations
  if ("CAL_YR" %in% names(accidents) && !"ACCIDENT_DT" %in% names(accidents)) {
    cat("Note: ACCIDENT_DT not found, will use CAL_YR + CAL_QTR\n")
  } else {
    stop("Missing critical columns: ", paste(missing_cols, collapse = ", "))
  }
}

## Quick sanity: experience fields
cat("\nExperience field coverage:\n")
cat("  TOT_EXPER:  ", sum(!is.na(accidents$TOT_EXPER)), "/", nrow(accidents),
    "(", round(100*mean(!is.na(accidents$TOT_EXPER)), 1), "%)\n")
cat("  MINE_EXPER: ", sum(!is.na(accidents$MINE_EXPER)), "/", nrow(accidents),
    "(", round(100*mean(!is.na(accidents$MINE_EXPER)), 1), "%)\n")
cat("  JOB_EXPER:  ", sum(!is.na(accidents$JOB_EXPER)), "/", nrow(accidents),
    "(", round(100*mean(!is.na(accidents$JOB_EXPER)), 1), "%)\n")

## ---- 2. Mines ----
cat("\n=== Fetching Mines ===\n")
mines_zip <- fetch_msha("Mines.zip")
mines_files <- unzip(mines_zip, list = TRUE)$Name
mines_txt <- mines_files[grepl("\\.txt$", mines_files, ignore.case = TRUE)]
unzip(mines_zip, files = mines_txt, exdir = data_dir, overwrite = TRUE)
mines <- fread(file.path(data_dir, mines_txt[1]), sep = "|", header = TRUE,
               na.strings = c("", "NA", " "))
cat("Mines loaded:", nrow(mines), "rows\n")

## ---- 3. Quarterly Employment/Production ----
cat("\n=== Fetching MinesProdQuarterly ===\n")
prod_zip <- fetch_msha("MinesProdQuarterly.zip")
prod_files <- unzip(prod_zip, list = TRUE)$Name
prod_txt <- prod_files[grepl("\\.txt$", prod_files, ignore.case = TRUE)]
unzip(prod_zip, files = prod_txt, exdir = data_dir, overwrite = TRUE)
prod <- fread(file.path(data_dir, prod_txt[1]), sep = "|", header = TRUE,
              na.strings = c("", "NA", " "))
cat("Production quarterly loaded:", nrow(prod), "rows\n")

## ---- 4. Inspections (for IV approach) ----
cat("\n=== Fetching Inspections ===\n")
insp_zip <- fetch_msha("Inspections.zip")
insp_files <- unzip(insp_zip, list = TRUE)$Name
insp_txt <- insp_files[grepl("\\.txt$", insp_files, ignore.case = TRUE)]
unzip(insp_zip, files = insp_txt, exdir = data_dir, overwrite = TRUE)
inspections <- fread(file.path(data_dir, insp_txt[1]), sep = "|", header = TRUE,
                     na.strings = c("", "NA", " "))
cat("Inspections loaded:", nrow(inspections), "rows\n")

## ---- 5. Violations (for S&S citation severity) ----
cat("\n=== Fetching Violations ===\n")
viol_zip <- fetch_msha("Violations.zip")
viol_files <- unzip(viol_zip, list = TRUE)$Name
viol_txt <- viol_files[grepl("\\.txt$", viol_files, ignore.case = TRUE)]
unzip(viol_zip, files = viol_txt, exdir = data_dir, overwrite = TRUE)
violations <- fread(file.path(data_dir, viol_txt[1]), sep = "|", header = TRUE,
                    na.strings = c("", "NA", " "))
cat("Violations loaded:", nrow(violations), "rows\n")

## ---- Save compressed RDS files ----
cat("\n=== Saving RDS files ===\n")
saveRDS(accidents, file.path(data_dir, "accidents.rds"))
saveRDS(mines, file.path(data_dir, "mines.rds"))
saveRDS(prod, file.path(data_dir, "prod_quarterly.rds"))
saveRDS(inspections, file.path(data_dir, "inspections.rds"))
saveRDS(violations, file.path(data_dir, "violations.rds"))

cat("\n=== Data fetch complete ===\n")
cat("Files saved to:", data_dir, "\n")
