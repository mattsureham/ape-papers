## 01_fetch_data.R — Read Home Office police recorded crime data (ODS)
## apep_0780: Last Orders for Crime?
##
## Data: Home Office Police Recorded Crime Open Data Tables
## PFA-level: prc-pfa-mar2013-onwards (Police Force Area, 43 forces, 2013-2024)
## CSP-level: prc-csp-mar16-sep24 (Community Safety Partnership, 338 LAs, 2016-2024)

source("00_packages.R")
if (!requireNamespace("readODS", quietly = TRUE)) install.packages("readODS", repos = "https://cran.r-project.org")
library(readODS)

out_dir <- "../data"

## ---- 1. Read PFA-level crime data ----
cat("Reading PFA-level crime data...\n")

# List sheets
pfa_sheets <- list_ods_sheets(file.path(out_dir, "prc_pfa.ods"))
cat(sprintf("PFA sheets: %s\n", paste(head(pfa_sheets, 10), collapse = ", ")))

# Read each sheet (one per financial year)
pfa_list <- list()
for (sheet in pfa_sheets) {
  cat(sprintf("  Reading %s...", sheet))
  dt <- tryCatch({
    as.data.table(read_ods(file.path(out_dir, "prc_pfa.ods"), sheet = sheet))
  }, error = function(e) {
    cat(sprintf(" ERROR\n"))
    NULL
  })

  if (!is.null(dt) && nrow(dt) > 5) {
    dt[, sheet_name := sheet]
    pfa_list[[sheet]] <- dt
    cat(sprintf(" %d rows, %d cols\n", nrow(dt), ncol(dt)))
  } else {
    cat(sprintf(" skipped (too small)\n"))
  }
}

if (length(pfa_list) == 0) {
  stop("No PFA data could be read. Check ODS file.")
}

# Examine first sheet structure
cat("\nFirst sheet columns:\n")
first_dt <- pfa_list[[1]]
cat(paste(names(first_dt)[1:min(15, ncol(first_dt))], collapse = "\n"), "\n")
cat("\nFirst rows:\n")
print(head(first_dt[, 1:min(8, ncol(first_dt))], 5))

## ---- 2. Identify data structure and extract ----
# The PFA tables typically have:
# Col 1: offence group/subgroup
# Remaining cols: one per police force area
# Each sheet = one year (e.g., "Year ending Mar 2024")

# We need to reshape: from wide (forces as columns) to long (force × year × crime)

# First, combine all sheets
pfa_all <- rbindlist(pfa_list, fill = TRUE)
cat(sprintf("\nCombined PFA data: %d rows, %d cols\n", nrow(pfa_all), ncol(pfa_all)))

# Save raw for inspection
fwrite(pfa_all, file.path(out_dir, "pfa_raw.csv"))
saveRDS(pfa_all, file.path(out_dir, "pfa_raw.rds"))

## ---- 3. CIA treatment assignment ----
cat("\n=== Creating CIA force-level treatment ===\n")

# Forces with CIA LAs (based on Home Office Alcohol Licensing Statistics 2018)
# ~31 of 43 forces have at least one LA with a CIA
# Key non-CIA forces: Cumbria, City of London, Cheshire, Lincolnshire,
# Warwickshire, Wiltshire, North Yorkshire, Suffolk, Dorset
cia_forces <- data.table(
  force = c(
    "Avon and Somerset", "Bedfordshire", "Cambridgeshire",
    "Cleveland", "Derbyshire", "Devon and Cornwall",
    "Durham", "Essex", "Gloucestershire", "Greater Manchester",
    "Hampshire", "Hertfordshire", "Humberside", "Kent",
    "Lancashire", "Leicestershire", "Merseyside",
    "Metropolitan Police", "Norfolk", "Northamptonshire",
    "Northumbria", "Nottinghamshire", "South Yorkshire",
    "Staffordshire", "Surrey", "Sussex",
    "Thames Valley", "West Mercia", "West Midlands",
    "West Yorkshire", "Brighton and Hove"
  ),
  has_cia = 1L
)

fwrite(cia_forces, file.path(out_dir, "cia_forces.csv"))
saveRDS(cia_forces, file.path(out_dir, "cia_forces.rds"))

cat(sprintf("CIA forces: %d\n", nrow(cia_forces)))
cat("\nData fetch complete. PFA and CIA files saved.\n")
