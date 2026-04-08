# 01_fetch_data.R — Fetch CMS Medicare Inpatient Hospitals PUF
# APEP-1420: The Coding Dividend
#
# Data: CMS Medicare Inpatient Hospitals — By Provider and Service
# Source: data.cms.gov (direct CSV downloads)
# Contains: hospital × DRG × year with discharges, charges, payments
# Coverage: FY2014–FY2022 (9 fiscal years)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download Medicare Inpatient Hospitals PUF
# ============================================================
cat("=== Fetching CMS Medicare Inpatient PUF Data ===\n\n")

# Direct CSV download URLs from data.cms.gov catalog
# Found via https://data.cms.gov/data.json (machine-readable catalog)
cms_urls <- list(
  "2014" = "https://data.cms.gov/sites/default/files/2023-05/dd6961c6-0eed-4a33-8527-8f66638819b8/MUP_IHP_RY23_P03_V10_DY14_PRVSVC.CSV",
  "2015" = "https://data.cms.gov/sites/default/files/2023-05/81895338-4c5c-4ad7-a490-8e5a9a972825/MUP_IHP_RY23_P03_V10_DY15_PRVSVC.CSV",
  "2016" = "https://data.cms.gov/sites/default/files/2023-05/4f20bce0-607a-46c1-bd0d-78021b0624ec/MUP_IHP_RY23_P03_V10_DY16_PRVSVC.CSV",
  "2017" = "https://data.cms.gov/sites/default/files/2023-05/ec9287b0-68e6-4818-8c64-3a0c68fcde49/MUP_IHP_RY23_P03_V10_DY17_PRVSVC.CSV",
  "2018" = "https://data.cms.gov/sites/default/files/2023-05/78d80cf4-fc5b-40db-8e88-ca44bc86102f/MUP_IHP_RY23_P03_V10_DY18_PRVSVC.CSV",
  "2019" = "https://data.cms.gov/sites/default/files/2023-05/6602e715-b301-4a38-954d-b8d5aec12b87/MUP_IHP_RY23_P03_V10_DY19_PRVSVC.CSV",
  "2020" = "https://data.cms.gov/sites/default/files/2023-05/e57818f2-318c-4979-a612-c91eba44b011/MUP_IHP_RY23_P03_V10_DY20_PRVSVC.CSV",
  "2021" = "https://data.cms.gov/sites/default/files/2023-05/a754bf0b-0c51-4daf-876e-272f90a11c05/MUP_IHP_RY23_P03_V10_DY21_PRVSVC.CSV",
  "2022" = "https://data.cms.gov/sites/default/files/2024-05/7d1f4bcd-7dd9-4fd1-aa7f-91cd69e452d3/MUP_INP_RY24_P03_V10_DY22_PrvSvc.CSV"
)

# Download each year
all_years <- list()
for (year in names(cms_urls)) {
  cache_file <- file.path(data_dir, sprintf("cms_puf_%s.csv", year))

  if (file.exists(cache_file) && file.size(cache_file) > 10000) {
    cat(sprintf("FY%s: Using cached file\n", year))
    all_years[[year]] <- fread(cache_file)
    next
  }

  cat(sprintf("FY%s: Downloading from CMS...\n", year))
  url <- cms_urls[[year]]

  download_result <- tryCatch({
    download.file(url, cache_file, mode = "wb", method = "curl", quiet = TRUE)
    TRUE
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
    FALSE
  })

  if (!download_result || !file.exists(cache_file) || file.size(cache_file) < 10000) {
    stop(sprintf("FATAL: Could not download PUF data for FY%s from %s", year, url))
  }

  dt <- fread(cache_file)
  cat(sprintf("  Downloaded: %s rows, %d columns\n",
              format(nrow(dt), big.mark = ","), ncol(dt)))
  all_years[[year]] <- dt
}

# ============================================================
# 2. Standardize column names across years
# ============================================================
cat("\n=== Standardizing Column Names ===\n")

standardize_cols <- function(dt, year) {
  # Print original column names for debugging
  cat(sprintf("  FY%s columns: %s\n", year, paste(names(dt), collapse = ", ")))

  names_lower <- tolower(names(dt))
  names(dt) <- names_lower

  # Map various column name formats to standard names
  name_map <- c(
    # Provider ID
    "rndrng_prvdr_ccn" = "provider_id",
    "provider_ccn" = "provider_id",
    "prvdr_id" = "provider_id",
    "provider id" = "provider_id",
    # DRG code
    "drg_cd" = "drg_code",
    "drg code" = "drg_code",
    "drg" = "drg_code",
    # DRG description
    "drg_desc" = "drg_desc",
    "drg_definition" = "drg_desc",
    "drg definition" = "drg_desc",
    # Discharges
    "tot_dschrgs" = "discharges",
    "total_discharges" = "discharges",
    "total discharges" = "discharges",
    # Charges
    "avg_submtd_cvrd_chrg" = "avg_charges",
    "avg_submtd_cvrd_chrgs" = "avg_charges",
    "avg_submtd_chrgs" = "avg_charges",
    "average covered charges" = "avg_charges",
    "average submitted charges" = "avg_charges",
    # Total payment
    "avg_tot_pymt_amt" = "avg_total_payment",
    "avg_ttl_pymt_amt" = "avg_total_payment",
    "average total payments" = "avg_total_payment",
    # Medicare payment
    "avg_mdcr_pymt_amt" = "avg_medicare_payment",
    "avg_mdcr_pymts" = "avg_medicare_payment",
    "average medicare payments" = "avg_medicare_payment",
    # Provider name and state
    "rndrng_prvdr_org_name" = "provider_name",
    "provider_name" = "provider_name",
    "provider name" = "provider_name",
    "rndrng_prvdr_state_abrvtn" = "state",
    "provider_state" = "state",
    "provider state" = "state"
  )

  # Apply mapping
  current_names <- names(dt)
  for (i in seq_along(current_names)) {
    if (current_names[i] %in% names(name_map)) {
      current_names[i] <- name_map[current_names[i]]
    }
  }
  names(dt) <- current_names

  # Extract DRG code from description if drg_code not yet set
  if (!"drg_code" %in% names(dt) && "drg_desc" %in% names(dt)) {
    dt[, drg_code := as.integer(sub("^(\\d+)\\s*-.*", "\\1", drg_desc))]
  }

  # Ensure drg_code is integer
  if ("drg_code" %in% names(dt) && !is.integer(dt$drg_code)) {
    dt[, drg_code := as.integer(gsub("[^0-9]", "", as.character(drg_code)))]
  }

  # Ensure numeric types for financial columns
  num_cols <- c("discharges", "avg_charges", "avg_total_payment", "avg_medicare_payment")
  for (col in num_cols) {
    if (col %in% names(dt) && is.character(dt[[col]])) {
      dt[, (col) := as.numeric(gsub("[,$]", "", get(col)))]
    }
  }

  dt[, year := as.integer(year)]

  # Keep only needed columns
  keep_cols <- c("provider_id", "provider_name", "state", "drg_code", "drg_desc",
                 "discharges", "avg_charges", "avg_total_payment",
                 "avg_medicare_payment", "year")
  keep_cols <- intersect(keep_cols, names(dt))
  dt[, ..keep_cols]
}

puf_list <- list()
for (year in names(all_years)) {
  puf_list[[year]] <- standardize_cols(copy(all_years[[year]]), year)
}

# Combine all years
puf <- rbindlist(puf_list, fill = TRUE)

cat(sprintf("\nCombined PUF: %s rows, %d years, %d hospitals, %d DRGs\n",
            format(nrow(puf), big.mark = ","),
            length(unique(puf$year)),
            length(unique(puf$provider_id)),
            length(unique(puf$drg_code))))

# Validate: fail loudly if data is insufficient
stopifnot("FATAL: No data rows" = nrow(puf) > 0)
stopifnot("FATAL: Missing discharges" = sum(!is.na(puf$discharges)) > nrow(puf) * 0.5)
stopifnot("FATAL: Missing charges" = sum(!is.na(puf$avg_charges)) > nrow(puf) * 0.5)
stopifnot("FATAL: Missing payments" = sum(!is.na(puf$avg_medicare_payment)) > nrow(puf) * 0.5)
stopifnot("FATAL: Too few years" = length(unique(puf$year)) >= 5)

# Save
fwrite(puf, file.path(data_dir, "puf_combined.csv"))
cat(sprintf("\nSaved combined PUF to %s\n", file.path(data_dir, "puf_combined.csv")))

# ============================================================
# 3. Summary statistics
# ============================================================
cat("\n=== PUF Summary by Year ===\n")
puf[, .(
  n_rows = .N,
  n_hospitals = uniqueN(provider_id),
  n_drgs = uniqueN(drg_code),
  mean_discharges = round(mean(discharges, na.rm = TRUE), 1),
  mean_charges = round(mean(avg_charges, na.rm = TRUE), 0),
  mean_medicare_pymt = round(mean(avg_medicare_payment, na.rm = TRUE), 0)
), by = year][order(year)] |> print()

cat("\nData fetch complete.\n")
