# =============================================================================
# 01_fetch_data.R — Data Acquisition
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================
# Sources:
#   1. HM Land Registry Price Paid Data (bulk CSV, 2017-2025)
#   2. ONS National Statistics Postcode Lookup (postcode → LA mapping)
#   3. Census 2021 tenure data via NOMIS (PRS share by LA)
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. HM LAND REGISTRY PRICE PAID DATA
# =============================================================================
# Download annual CSVs for 2017-2025
# Columns: TxID, Price, Date, Postcode, PropType, Old/New, Duration,
#           PAON, SAON, Street, Locality, Town, District, County, PPDCat, RecStatus

lr_years <- 2017:2025
lr_col_names <- c("txid", "price", "date", "postcode", "prop_type",
                   "old_new", "duration", "paon", "saon", "street",
                   "locality", "town", "district", "county", "ppd_cat",
                   "rec_status")

cat("=== Downloading Land Registry Price Paid Data ===\n")

lr_files <- character(0)
for (yr in lr_years) {
  dest <- file.path(data_dir, paste0("pp-", yr, ".csv"))

  if (!file.exists(dest)) {
    url <- paste0("http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-",
                   yr, ".csv")
    cat("Downloading:", yr, "...\n")
    tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      cat("  Downloaded:", yr, "-", round(file.size(dest) / 1e6, 1), "MB\n")
    }, error = function(e) {
      stop("FATAL: Cannot download Land Registry data for ", yr, ": ", e$message,
           "\nCannot proceed without real data. Fix the source or pivot the research question.")
    })
  } else {
    cat("  Already exists:", yr, "-", round(file.size(dest) / 1e6, 1), "MB\n")
  }

  lr_files <- c(lr_files, dest)
}

cat("\nReading and combining Land Registry files...\n")

# Read all years into a single data.table
lr_list <- lapply(lr_files, function(f) {
  dt <- fread(f, header = FALSE, col.names = lr_col_names,
              showProgress = FALSE)
  # Keep only needed columns (drop address detail)
  dt <- dt[, .(txid, price, date, postcode, prop_type, old_new, duration,
               town, district, county, ppd_cat, rec_status)]
  dt
})

lr <- rbindlist(lr_list, use.names = TRUE, fill = TRUE)
rm(lr_list)
gc()

cat("Land Registry raw rows:", format(nrow(lr), big.mark = ","), "\n")

# Parse date
lr[, date := as.Date(date)]
lr[, year := year(date)]
lr[, month := month(date)]
lr[, ym := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

# Clean postcode (uppercase, trim whitespace)
lr[, postcode := str_trim(toupper(postcode))]

# Filter to study period: Jan 2018 – Dec 2025
lr <- lr[date >= as.Date("2018-01-01") & date <= as.Date("2025-12-31")]
cat("After date filter (2018-2025):", format(nrow(lr), big.mark = ","), "rows\n")

# =============================================================================
# 2. IDENTIFY WALES vs ENGLAND
# =============================================================================
# Wales postcodes start with: CF, SA, NP, LD, SY, LL, HR (some HR are English)
# More precise: ONS NSPL maps postcode → country
# For initial classification, use postcode prefix approach, then validate with NSPL

# Welsh postcode areas (first 1-2 letters)
# CF = Cardiff, SA = Swansea, NP = Newport, LD = Llandrindod Wells,
# LL = Llandudno/North Wales, SY = Shrewsbury (some Welsh)
# NOTE: SY and HR span the border. We need NSPL for precise country assignment.

cat("\n=== Downloading ONS National Statistics Postcode Lookup ===\n")

# Download NSPL or use a lighter postcode-to-LA lookup
# The full NSPL is large (~500MB). Instead, use postcodes.io bulk lookup
# or download the postcode directory CSV from ONS Open Geography

# Strategy: Extract unique postcodes from Land Registry, then batch-lookup
# via postcodes.io (free, no key needed)

unique_pcs <- unique(lr$postcode)
cat("Unique postcodes to classify:", format(length(unique_pcs), big.mark = ","), "\n")

# Use the district column from Land Registry as LA proxy
# The "district" field in PPD IS the Local Authority name
# This avoids needing NSPL entirely for LA assignment

cat("\n=== Classifying postcodes into Wales/England ===\n")

# Welsh Local Authorities (all 22 unitary authorities)
welsh_las <- c(
  "ISLE OF ANGLESEY", "GWYNEDD", "CONWY", "DENBIGHSHIRE",
  "FLINTSHIRE", "WREXHAM", "POWYS", "CEREDIGION",
  "PEMBROKESHIRE", "CARMARTHENSHIRE", "SWANSEA", "NEATH PORT TALBOT",
  "BRIDGEND", "VALE OF GLAMORGAN", "CARDIFF", "RHONDDA CYNON TAF",
  "MERTHYR TYDFIL", "CAERPHILLY", "BLAENAU GWENT", "TORFAEN",
  "MONMOUTHSHIRE", "NEWPORT"
)

# Clean district names
lr[, district_clean := str_trim(toupper(district))]

# Fix known name variants in the data
lr[district_clean == "THE VALE OF GLAMORGAN", district_clean := "VALE OF GLAMORGAN"]
lr[district_clean == "RHONDDA CYNON TAFF", district_clean := "RHONDDA CYNON TAF"]

# Classify
lr[, country := fifelse(district_clean %in% welsh_las, "Wales", "England")]

# Verify counts
cat("\nCountry distribution:\n")
print(lr[, .N, by = country])
cat("\n")

# Check Welsh LA names found in data
welsh_found <- intersect(welsh_las, unique(lr$district_clean))
welsh_missing <- setdiff(welsh_las, unique(lr$district_clean))
cat("Welsh LAs found in data:", length(welsh_found), "of 22\n")
if (length(welsh_missing) > 0) {
  cat("WARNING: Missing Welsh LAs:", paste(welsh_missing, collapse = ", "), "\n")
  # Try fuzzy matching for common name variants
  all_districts <- unique(lr$district_clean)
  for (missing_la in welsh_missing) {
    candidates <- all_districts[agrepl(missing_la, all_districts, max.distance = 0.2)]
    if (length(candidates) > 0) {
      cat("  Possible match for", missing_la, ":", paste(candidates, collapse = ", "), "\n")
    }
  }
}

# =============================================================================
# 3. PRS INTENSITY FROM LAND REGISTRY (Category B share in pre-period)
# =============================================================================
cat("\n=== Computing PRS intensity from Land Registry data ===\n")

# Category B in Land Registry PPD = "additional price paid" which includes
# buy-to-let, second homes, and non-standard purchases.
# This is the best available proxy for PRS intensity using Land Registry alone.
# Compute share of Category B transactions per LA in the pre-treatment period.

pre_lr <- lr[date < as.Date("2022-12-01")]

prs_share <- pre_lr[, .(
  total_tx = .N,
  cat_b_tx = sum(ppd_cat == "B", na.rm = TRUE),
  leasehold_tx = sum(duration == "L", na.rm = TRUE),
  flat_tx = sum(prop_type == "F", na.rm = TRUE)
), by = .(la = district_clean)]

prs_share[, prs_share := cat_b_tx / pmax(total_tx, 1)]
prs_share[, leasehold_share := leasehold_tx / pmax(total_tx, 1)]
prs_share[, flat_share_pre := flat_tx / pmax(total_tx, 1)]

# PRS share here = Cat B share (buy-to-let + additional property proxy)
cat("\nPRS intensity (Cat B share) summary:\n")
cat("  N LAs:", nrow(prs_share), "\n")
cat("  Mean Cat B share:", round(mean(prs_share$prs_share), 3), "\n")
cat("  SD Cat B share:", round(sd(prs_share$prs_share), 3), "\n")
cat("  Min:", round(min(prs_share$prs_share), 3), "\n")
cat("  Max:", round(max(prs_share$prs_share), 3), "\n")

fwrite(prs_share, file.path(data_dir, "prs_share_by_la.csv"))
cat("Saved PRS intensity data.\n")

# =============================================================================
# 4. SAVE PROCESSED LAND REGISTRY DATA
# =============================================================================
cat("\n=== Saving processed Land Registry data ===\n")

# Keep essential columns
lr_clean <- lr[, .(txid, price, date, year, month, ym, postcode,
                    prop_type, old_new, duration, district_clean,
                    county, ppd_cat, rec_status, country)]

fwrite(lr_clean, file.path(data_dir, "lr_clean.csv"))
cat("Saved lr_clean.csv:", format(nrow(lr_clean), big.mark = ","), "rows\n")

# =============================================================================
# 5. DATA VALIDATION
# =============================================================================
cat("\n=== DATA VALIDATION ===\n")

n_wales <- lr_clean[country == "Wales", .N]
n_england <- lr_clean[country == "England", .N]
n_welsh_las <- lr_clean[country == "Wales", uniqueN(district_clean)]
n_english_las <- lr_clean[country == "England", uniqueN(district_clean)]
n_years <- lr_clean[, uniqueN(year)]
n_months <- lr_clean[, uniqueN(ym)]

stopifnot("Expected Wales transactions" = n_wales > 100000)
stopifnot("Expected England transactions" = n_england > 1000000)
stopifnot("Expected 22 Welsh LAs" = n_welsh_las >= 22)
stopifnot("Expected 200+ English LAs" = n_english_las >= 200)
stopifnot("Expected 8 years of data" = n_years >= 7)

cat("Data validation passed:\n")
cat("  Wales transactions:", format(n_wales, big.mark = ","), "\n")
cat("  England transactions:", format(n_england, big.mark = ","), "\n")
cat("  Welsh LAs:", n_welsh_las, "\n")
cat("  English LAs:", n_english_las, "\n")
cat("  Years:", n_years, "\n")
cat("  Month-years:", n_months, "\n")

cat("\n=== Data acquisition complete ===\n")
