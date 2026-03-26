# 01_fetch_data.R — Fetch NOMIS UK Business Counts + Companies House data
# apep_0999: IR35 bunching at small company threshold
#
# Data sources:
# 1. NOMIS NM_141_1: UK Business Counts (local units) by employment sizeband,
#    5-digit SIC, and year. From the Inter-Departmental Business Register (IDBR).
# 2. Companies House BasicCompanyData: bulk CSV for company SIC codes and account categories.

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

NOMIS_KEY <- Sys.getenv("NOMIS_API_KEY")

# ============================================================
# PART 1: NOMIS UK Business Counts by employment sizeband
# ============================================================

cat("=== Fetching NOMIS UK Business Counts (NM_141_1) ===\n")

fetch_nomis <- function(dataset_id, params, api_key = "") {
  base_url <- sprintf("https://www.nomisweb.co.uk/api/v01/dataset/%s.data.csv", dataset_id)
  if (nchar(api_key) > 0) params$uid <- api_key

  query_string <- paste(names(params), params, sep = "=", collapse = "&")
  url <- paste0(base_url, "?", query_string)
  cat(sprintf("Fetching: %s\n", url))

  resp <- GET(url, timeout(120))
  if (status_code(resp) != 200) {
    stop(sprintf("NOMIS API error: HTTP %d for %s", status_code(resp), dataset_id))
  }

  content_text <- content(resp, as = "text", encoding = "UTF-8")
  dt <- fread(content_text, showProgress = FALSE)
  cat(sprintf("  -> %d rows\n", nrow(dt)))
  return(dt)
}

# Target SIC codes (2-digit NOMIS codes):
# Contractor-intensive: 62 (Computer programming), 70 (Head offices/consultancy),
#   71 (Architectural/engineering), 74 (Other professional)
# Control: 46 (Wholesale), 47 (Retail)

# NOMIS industry codes from the API:
# 62 = 146800702, 70 = 146800710, 71 = 146800711, 74 = 146800714
# 46 = 146800686, 47 = 146800687

contractor_codes <- "146800702,146800710,146800711,146800714"
control_codes <- "146800686,146800687"

# Employment sizebands: 4=20-49, 5=50-99 (plus neighbors for robustness)
# 1=0-4, 2=5-9, 3=10-19, 4=20-49, 5=50-99, 6=100-249, 7=250-499
sizebands <- "1,2,3,4,5,6,7"

# Geography: 2092957697 = United Kingdom
# Years: 2010-2025
years <- paste(2010:2025, collapse = ",")

# Fetch contractor-intensive sectors
cat("Fetching contractor-intensive SICs...\n")
nomis_contractor <- fetch_nomis(
  "NM_141_1",
  list(
    geography = "2092957697",
    industry = contractor_codes,
    employment_sizeband = sizebands,
    legal_status = "0",
    measures = "20100",
    time = years
  ),
  NOMIS_KEY
)

# Fetch control sectors
cat("Fetching control SICs...\n")
nomis_control <- fetch_nomis(
  "NM_141_1",
  list(
    geography = "2092957697",
    industry = control_codes,
    employment_sizeband = sizebands,
    legal_status = "0",
    measures = "20100",
    time = years
  ),
  NOMIS_KEY
)

# Combine and label
nomis_contractor[, sector_type := "contractor"]
nomis_control[, sector_type := "control"]
nomis_all <- rbind(nomis_contractor, nomis_control, fill = TRUE)

# Save raw
fwrite(nomis_all, file.path(DATA_DIR, "nomis_business_counts_raw.csv"))
cat(sprintf("Total NOMIS rows: %d\n", nrow(nomis_all)))

# Clean
nomis_clean <- nomis_all[, .(
  year = as.integer(DATE),
  sic_code = INDUSTRY_CODE,
  sic_name = INDUSTRY_NAME,
  sizeband_code = EMPLOYMENT_SIZEBAND,
  sizeband_name = EMPLOYMENT_SIZEBAND_NAME,
  count = as.numeric(OBS_VALUE),
  sector_type
)]

# Map sizeband codes to employee ranges
sizeband_map <- data.table(
  sizeband_code = c(1, 2, 3, 4, 5, 6, 7),
  emp_lower = c(0, 5, 10, 20, 50, 100, 250),
  emp_upper = c(4, 9, 19, 49, 99, 249, 499),
  emp_midpoint = c(2, 7, 14.5, 34.5, 74.5, 174.5, 374.5)
)

nomis_clean <- merge(nomis_clean, sizeband_map, by = "sizeband_code", all.x = TRUE)
nomis_clean <- nomis_clean[!is.na(emp_lower)]

fwrite(nomis_clean, file.path(DATA_DIR, "nomis_clean.csv"))
cat(sprintf("Cleaned NOMIS data: %d rows\n", nrow(nomis_clean)))

# Quick diagnostic: bunching ratio by sector × year
cat("\nBunching ratio (20-49 / 50-99) by sector and year:\n")
bunching_check <- dcast(
  nomis_clean[emp_lower %in% c(20, 50), .(count = sum(count)), by = .(year, sector_type, emp_lower)],
  year + sector_type ~ emp_lower,
  value.var = "count"
)
setnames(bunching_check, c("20", "50"), c("n_20_49", "n_50_99"))
bunching_check[, ratio := round(n_20_49 / n_50_99, 2)]
print(bunching_check[order(sector_type, year)])

# ============================================================
# PART 2: Companies House Bulk Data
# ============================================================

cat("\n=== Processing Companies House BasicCompanyData ===\n")

bulk_csv <- file.path(DATA_DIR, "BasicCompanyData.csv")

if (!file.exists(bulk_csv)) {
  # Try to find from previous download
  csv_files <- list.files(DATA_DIR, pattern = "BasicCompanyData.*\\.csv$",
                          full.names = TRUE, recursive = TRUE)
  if (length(csv_files) > 0) {
    file.copy(csv_files[1], bulk_csv)
    cat(sprintf("Using existing CSV: %s\n", csv_files[1]))
  } else {
    # Download
    cat("Downloading Companies House bulk data...\n")
    bulk_zip <- file.path(DATA_DIR, "BasicCompanyData.zip")
    download_ok <- FALSE
    for (month in c("03", "02", "01")) {
      url <- sprintf("http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-2026-%s-01.zip", month)
      tryCatch({
        download.file(url, bulk_zip, mode = "wb", timeout = 600, quiet = TRUE)
        download_ok <- TRUE
        break
      }, error = function(e) {
        cat(sprintf("  %s not available, trying next...\n", month))
      })
    }
    if (!download_ok) {
      # Try 2025
      for (month in c("12", "11", "10")) {
        url <- sprintf("http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-2025-%s-01.zip", month)
        tryCatch({
          download.file(url, bulk_zip, mode = "wb", timeout = 600, quiet = TRUE)
          download_ok <- TRUE
          break
        }, error = function(e) {
          cat(sprintf("  %s not available, trying next...\n", month))
        })
      }
    }
    if (!download_ok) stop("FATAL: Cannot download Companies House bulk data.")

    cat("Unzipping...\n")
    unzip(bulk_zip, exdir = DATA_DIR)
    csv_files <- list.files(DATA_DIR, pattern = "BasicCompanyData.*\\.csv$",
                            full.names = TRUE, recursive = TRUE)
    if (length(csv_files) == 0) stop("FATAL: No CSV found after unzip.")
    file.copy(csv_files[1], bulk_csv)
  }
}

cat("Reading Companies House bulk data...\n")
ch <- fread(bulk_csv,
            select = c("CompanyNumber", "CompanyName", "CompanyStatus",
                        "SICCode.SicText_1", "IncorporationDate",
                        "Accounts.AccountCategory"),
            showProgress = FALSE)

cat(sprintf("Total companies: %s\n", format(nrow(ch), big.mark = ",")))

# Extract primary SIC code
ch[, sic2 := substr(str_extract(`SICCode.SicText_1`, "^[0-9]+"), 1, 2)]

# Flag contractor-intensive vs control
contractor_sic2 <- c("62", "70", "71", "74")
control_sic2 <- c("46", "47")

ch[, contractor_sic := sic2 %in% contractor_sic2]
ch[, control_sic := sic2 %in% control_sic2]

# Filter to target sectors and active companies
ch_target <- ch[CompanyStatus == "Active" & (contractor_sic | control_sic)]
cat(sprintf("Active companies in target SICs: %s\n", format(nrow(ch_target), big.mark = ",")))

# Account category distribution (this IS the size classification)
cat("\nAccount category distribution:\n")
cat("Contractor-intensive:\n")
print(sort(table(ch_target[contractor_sic == TRUE, Accounts.AccountCategory]), decreasing = TRUE))
cat("\nControl:\n")
print(sort(table(ch_target[control_sic == TRUE, Accounts.AccountCategory]), decreasing = TRUE))

# Map to size groups
ch_target[, size_group := fcase(
  Accounts.AccountCategory %in% c("MICRO ENTITY", "TOTAL EXEMPTION SMALL",
                                    "TOTAL EXEMPTION FULL"), "micro_or_exempt",
  Accounts.AccountCategory == "SMALL", "small",
  Accounts.AccountCategory == "MEDIUM", "medium",
  Accounts.AccountCategory %in% c("FULL", "GROUP"), "large",
  Accounts.AccountCategory == "DORMANT", "dormant",
  default = "other"
)]

# Key statistic: share of firms classified as SMALL vs MEDIUM
cat("\nSize group by sector:\n")
ch_target[, sector_label := ifelse(contractor_sic, "contractor", "control")]
print(ch_target[, .N, by = .(sector_label, size_group)][order(sector_label, size_group)])

# Save company-level data
ch_panel <- ch_target[, .(CompanyNumber, CompanyName, sic2, contractor_sic, control_sic,
                           AccountCategory = Accounts.AccountCategory, size_group,
                           IncorporationDate)]
fwrite(ch_panel, file.path(DATA_DIR, "ch_company_panel.csv"))

# ============================================================
# PART 3: Construct the bunching analysis dataset
# ============================================================

cat("\n=== Constructing bunching analysis dataset ===\n")

# The main analysis uses NOMIS counts by sizeband × SIC × year
# Key outcome: ratio of firms in 20-49 to firms in 50-99

bunching_data <- nomis_clean[emp_lower %in% c(20, 50)]
bunching_wide <- dcast(
  bunching_data[, .(count = sum(count)), by = .(year, sector_type, sic_name, sic_code, emp_lower)],
  year + sector_type + sic_name + sic_code ~ emp_lower,
  value.var = "count"
)
setnames(bunching_wide, c("20", "50"), c("count_20_49", "count_50_99"))

# Bunching ratio
bunching_wide[, bunching_ratio := count_20_49 / count_50_99]

# Treatment indicators
bunching_wide[, post_2021 := as.integer(year >= 2021)]
bunching_wide[, contractor := as.integer(sector_type == "contractor")]

fwrite(bunching_wide, file.path(DATA_DIR, "bunching_ratio_panel.csv"))

# Also save the full sizeband analysis panel
analysis_panel <- nomis_clean[, .(count = sum(count)),
                               by = .(year, sector_type, emp_lower, emp_upper)]
analysis_panel[, post_2021 := as.integer(year >= 2021)]
analysis_panel[, contractor := as.integer(sector_type == "contractor")]
analysis_panel[, below_threshold := as.integer(emp_upper <= 49)]
analysis_panel[, near_threshold := as.integer(emp_lower %in% c(20, 50))]

fwrite(analysis_panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat("\n=== Data fetch complete ===\n")
cat("Files:\n")
for (f in list.files(DATA_DIR, pattern = "\\.csv$")) {
  sz <- file.size(file.path(DATA_DIR, f))
  cat(sprintf("  %s (%s)\n", f, format(sz, big.mark = ",")))
}
