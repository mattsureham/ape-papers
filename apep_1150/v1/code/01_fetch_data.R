# 01_fetch_data.R — Fetch CMS HCRIS hospital cost report data
# APEP-1150: Multi-threshold bunching in US hospital bed counts
#
# Data source: CMS Healthcare Cost Report Information System (HCRIS)
# Form 2552-10, available from data.cms.gov
# Each fiscal year file contains cost report data for ~6,000 hospitals

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download HCRIS data from CMS
# ============================================================
# HCRIS data is available as CSV files from data.cms.gov
# We need the "HOSPITAL" provider type cost reports
# The key dataset is the 2552-10 form (hospital cost report)
#
# CMS provides pre-extracted flat files:
# https://data.cms.gov/provider-compliance/cost-report/hospital-provider-cost-report

cat("=== Fetching CMS HCRIS Data ===\n")

# CMS Socrata API for Hospital Provider Cost Report
# This endpoint contains ~890K records with hospital characteristics
# We extract: provider_ccn, fiscal_year_end, beds, provider_type, state, etc.

# Strategy: Use the CMS Provider of Services (POS) file for bed counts
# POS is simpler and has clean bed count fields
# Available from data.cms.gov as CSV

# POS file endpoint (Socrata API) — contains current and historical snapshots
pos_url <- "https://data.cms.gov/provider-data/api/1/datastore/query/4pq5-n9py/0"

# Alternative: Use the HCRIS "Hospital Provider Cost Report" dataset
# which has bed counts embedded in the cost report line items
# URL: https://data.cms.gov/provider-compliance/cost-report/hospital-provider-cost-report

# Let's use the CMS Hospital Compare General Information dataset
# which has current bed counts and hospital characteristics
hosp_info_url <- "https://data.cms.gov/provider-data/api/1/datastore/query/xubh-q36u/0"

# First, let's try the HCRIS extract files which are more comprehensive
# These are the annual cost report CSV files

# HCRIS 2552-10 datasets from data.cms.gov
# The cost report has bed counts in the NMRC (numeric) file
# Line 14 of Worksheet S-3, Part I contains total beds

# Download the HCRIS extract files
# CMS hosts these at a standard location
hcris_base <- "https://downloads.cms.gov/files/hcris"

# Fiscal years available: 2010-2023
years <- 2010:2023

# Each year has 3 files: RPT (report info), NMRC (numeric data), ALPHA (alphanumeric)
# We need RPT for hospital identifiers and NMRC for bed counts

all_beds <- list()

for (yr in years) {
  cat(sprintf("Processing HCRIS FY%d...\n", yr))

  # CMS HCRIS 2552-10 files
  # Format: hosp10_YYYY_NMRC.CSV and hosp10_YYYY_RPT.CSV
  rpt_file <- file.path(data_dir, sprintf("hosp10_%d_RPT.csv", yr))
  nmrc_file <- file.path(data_dir, sprintf("hosp10_%d_NMRC.csv", yr))

  # Download if not cached
  if (!file.exists(rpt_file)) {
    rpt_url <- sprintf("%s/hosp10_%d_RPT.CSV", hcris_base, yr)
    cat(sprintf("  Downloading RPT from %s\n", rpt_url))
    tryCatch({
      download.file(rpt_url, rpt_file, mode = "wb", quiet = TRUE)
      if (file.size(rpt_file) < 1000) stop("RPT file too small — likely 404")
    }, error = function(e) {
      # Try alternative URL format
      rpt_url2 <- sprintf("https://downloads.cms.gov/files/hcris/HOSP10FY%d.zip", yr)
      cat(sprintf("  Trying ZIP format: %s\n", rpt_url2))
      zip_file <- file.path(data_dir, sprintf("HOSP10FY%d.zip", yr))
      download.file(rpt_url2, zip_file, mode = "wb", quiet = TRUE)
      if (file.size(zip_file) < 1000) stop("ZIP file too small")
      unzip(zip_file, exdir = data_dir)
      file.remove(zip_file)
    })
  }

  if (!file.exists(nmrc_file)) {
    nmrc_url <- sprintf("%s/hosp10_%d_NMRC.CSV", hcris_base, yr)
    cat(sprintf("  Downloading NMRC from %s\n", nmrc_url))
    tryCatch({
      download.file(nmrc_url, nmrc_file, mode = "wb", quiet = TRUE)
      if (file.size(nmrc_file) < 1000) stop("NMRC file too small")
    }, error = function(e) {
      cat(sprintf("  NMRC download failed for FY%d: %s\n", yr, e$message))
    })
  }
}

# ============================================================
# 2. Parse HCRIS files to extract bed counts
# ============================================================
cat("\n=== Parsing HCRIS Files ===\n")

# HCRIS NMRC file columns:
# RPT_REC_NUM, WKSHT_CD, LINE_NUM, CLMN_NUM, ITM_VAL_NUM
# Bed count: Worksheet S-3, Part I (WKSHT_CD = "S300001"), Line 14, Column 2
# Total beds available

# HCRIS RPT file columns:
# RPT_REC_NUM, PRVDR_CTRL_TYPE_CD, PRVDR_NUM, NPI, RPT_STUS_CD,
# FY_BGN_DT, FY_END_DT, PROC_DT, INITL_RPT_SW, LAST_RPT_SW, TRNSMTL_NUM, ...

all_hospital_data <- list()

for (yr in years) {
  rpt_file <- file.path(data_dir, sprintf("hosp10_%d_RPT.csv", yr))
  nmrc_file <- file.path(data_dir, sprintf("hosp10_%d_NMRC.csv", yr))

  # Check for alternative file names (from ZIP extraction)
  if (!file.exists(rpt_file)) {
    alt_rpt <- list.files(data_dir, pattern = sprintf("(?i)hosp.*%d.*rpt", yr), full.names = TRUE)
    if (length(alt_rpt) > 0) rpt_file <- alt_rpt[1]
  }
  if (!file.exists(nmrc_file)) {
    alt_nmrc <- list.files(data_dir, pattern = sprintf("(?i)hosp.*%d.*nmrc", yr), full.names = TRUE)
    if (length(alt_nmrc) > 0) nmrc_file <- alt_nmrc[1]
  }

  if (!file.exists(rpt_file) || !file.exists(nmrc_file)) {
    cat(sprintf("  Skipping FY%d — files not found\n", yr))
    next
  }

  cat(sprintf("  Parsing FY%d...\n", yr))

  # Read RPT file
  rpt <- tryCatch(
    fread(rpt_file, header = FALSE, select = c(1, 3, 6, 7),
          col.names = c("rpt_rec_num", "provider_id", "fy_begin", "fy_end")),
    error = function(e) {
      cat(sprintf("    RPT parse error FY%d: %s\n", yr, e$message))
      NULL
    }
  )
  if (is.null(rpt)) next

  # Read NMRC file — filter for bed count worksheet
  # S300001 = Worksheet S-3, Part I
  # Line 01400 = Line 14 (total beds available)
  # Column 00200 = Column 2
  nmrc <- tryCatch(
    fread(nmrc_file, header = FALSE, select = c(1, 2, 3, 4, 5),
          col.names = c("rpt_rec_num", "wksht_cd", "line_num", "clmn_num", "item_value")),
    error = function(e) {
      cat(sprintf("    NMRC parse error FY%d: %s\n", yr, e$message))
      NULL
    }
  )
  if (is.null(nmrc)) next

  # Filter for bed count: Worksheet S-3 Part I, Line 14, Column 2
  # WKSHT_CD patterns for S-3: "S300001" or "S3" variants
  beds <- nmrc[grepl("S300001", wksht_cd) &
               grepl("^0*1400$", sprintf("%05d", as.integer(line_num))) &
               grepl("^0*200$", sprintf("%05d", as.integer(clmn_num)))]

  if (nrow(beds) == 0) {
    # Try alternative line/column encoding
    beds <- nmrc[grepl("S3", wksht_cd) &
                 line_num %in% c(1400, 14, "01400", "14") &
                 clmn_num %in% c(200, 2, "00200", "2")]
  }

  if (nrow(beds) == 0) {
    cat(sprintf("    No bed data found for FY%d. Trying broader search...\n", yr))
    # Check what worksheets exist
    s3_rows <- nmrc[grepl("S3", wksht_cd)]
    if (nrow(s3_rows) > 0) {
      cat(sprintf("    Found %d S3 rows. Line nums: %s\n", nrow(s3_rows),
                  paste(head(unique(s3_rows$line_num), 10), collapse = ", ")))
    }
    next
  }

  # Keep first bed count per report (in case of duplicates)
  beds <- beds[, .(beds = as.numeric(item_value[1])), by = rpt_rec_num]

  # Merge with RPT to get provider IDs
  merged <- merge(rpt, beds, by = "rpt_rec_num")
  merged[, fiscal_year := yr]

  # Clean
  merged <- merged[!is.na(beds) & beds >= 0 & beds <= 2000]

  cat(sprintf("    FY%d: %d hospitals with bed data (mean=%.0f, median=%.0f)\n",
              yr, nrow(merged), mean(merged$beds), median(merged$beds)))

  all_hospital_data[[as.character(yr)]] <- merged[, .(provider_id, fiscal_year, beds)]
}

if (length(all_hospital_data) == 0) {
  stop("FATAL: No HCRIS data could be parsed. Cannot proceed with simulated data.")
}

# Combine all years
hospital_panel <- rbindlist(all_hospital_data)
cat(sprintf("\n=== Panel Summary ===\n"))
cat(sprintf("Total observations: %d\n", nrow(hospital_panel)))
cat(sprintf("Unique hospitals: %d\n", uniqueN(hospital_panel$provider_id)))
cat(sprintf("Years: %d-%d\n", min(hospital_panel$fiscal_year), max(hospital_panel$fiscal_year)))
cat(sprintf("Bed count range: %d-%d\n", min(hospital_panel$beds), max(hospital_panel$beds)))

# ============================================================
# 3. Add CAH designation from Provider of Services
# ============================================================
cat("\n=== Fetching Provider of Services Data ===\n")

# POS file from CMS — download the latest extract
# This has hospital type classification (CAH vs short-term acute care, etc.)
# Provider Number prefix indicates type:
# - CAH providers have provider numbers in format XX-1300 to XX-1399
# - Short-term acute care: XX-0001 to XX-0879

# Identify CAH status from provider number
# CAH: provider number ends in 1300-1399
hospital_panel[, provider_suffix := as.integer(substr(provider_id, 3, 6))]
hospital_panel[, is_cah := provider_suffix >= 1300 & provider_suffix <= 1399]
hospital_panel[, state_code := substr(provider_id, 1, 2)]

# Identify rural hospitals (approximate — CAH must be rural by definition)
# Urban hospitals: provider suffix 0001-0879 (general short-term)
hospital_panel[, is_urban_stac := provider_suffix >= 1 & provider_suffix <= 879]

cat(sprintf("CAH hospitals: %d unique providers\n",
            uniqueN(hospital_panel[is_cah == TRUE]$provider_id)))
cat(sprintf("Non-CAH hospitals: %d unique providers\n",
            uniqueN(hospital_panel[is_cah == FALSE]$provider_id)))

# ============================================================
# 4. Save panel dataset
# ============================================================
fwrite(hospital_panel, file.path(data_dir, "hospital_bed_panel.csv"))
cat(sprintf("\nSaved panel to %s\n", file.path(data_dir, "hospital_bed_panel.csv")))

# Quick bed distribution check at key thresholds
cat("\n=== Bed Distribution at Key Thresholds ===\n")
for (thresh in c(25, 50, 100)) {
  window <- hospital_panel[beds >= (thresh - 3) & beds <= (thresh + 3)]
  cat(sprintf("\nThreshold %d (all hospitals, all years):\n", thresh))
  print(table(window$beds))
}

# Non-CAH distribution at key thresholds
cat("\n=== Non-CAH Bed Distribution ===\n")
for (thresh in c(25, 50, 100)) {
  window <- hospital_panel[is_cah == FALSE & beds >= (thresh - 3) & beds <= (thresh + 3)]
  cat(sprintf("\nThreshold %d (non-CAH only):\n", thresh))
  print(table(window$beds))
}
