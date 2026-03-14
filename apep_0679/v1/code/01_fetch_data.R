## 01_fetch_data.R — Fetch apprenticeship and business data
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out
##
## Data sources:
## 1. GOV.UK FE Data Library: historical starts by LA (XLSX, 2010/11-2019/20)
## 2. NOMIS NM_142_1: UK Business Counts by LA and size band (Bartik instrument)

source("00_packages.R")

paper_dir <- dirname(getwd())
data_dir <- file.path(paper_dir, "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. GOV.UK FE Data Library — Historical apprenticeship starts by LA
# Sheet "la_2010": total starts by LA, 2010/11-2019/20 (10 academic years)
# ==============================================================================
cat("=== Fetching historical apprenticeship data ===\n")

hist_url <- "https://assets.publishing.service.gov.uk/media/5f088fe9e90e0712d0206edf/201920-July_totals-since-may-2010-and-2015.xlsx"
hist_file <- file.path(data_dir, "historical_totals.xlsx")

if (!file.exists(hist_file)) {
  download.file(hist_url, hist_file, mode = "wb", quiet = TRUE)
}

# Read la_2010 sheet — header is row 2, data starts row 3
# From preview: Row 2 = "Local Authority | Q4 2009/10 | 2010/11 | ... | 2019/20"
la_raw <- readxl::read_excel(hist_file, sheet = "la_2010", skip = 1)
cat(sprintf("Historical LA data: %d rows, %d cols\n", nrow(la_raw), ncol(la_raw)))
cat(sprintf("Columns: %s\n", paste(names(la_raw), collapse = ", ")))

# Clean column names
la_dt <- as.data.table(la_raw)
# First column is LA name; remaining are year columns
names(la_dt)[1] <- "la_name"

# Drop empty rows and summary rows
la_dt <- la_dt[!is.na(la_name) & la_name != "" &
               !grepl("Total|England|Region|Grand|Source|Note", la_name, ignore.case = TRUE)]

cat(sprintf("After cleaning: %d LAs\n", nrow(la_dt)))
cat(sprintf("First 5 LAs: %s\n", paste(head(la_dt$la_name, 5), collapse = ", ")))

# Save the raw historical data
fwrite(la_dt, file.path(data_dir, "historical_la_raw.csv"))

# Also read the la_2015 sheet for level breakdown (if available)
cat("\n  Reading la_2015 sheet for more detail...\n")
la_2015 <- readxl::read_excel(hist_file, sheet = "la_2015", skip = 1)
la_2015_dt <- as.data.table(la_2015)
cat(sprintf("la_2015: %d rows, %d cols\n", nrow(la_2015_dt), ncol(la_2015_dt)))
cat(sprintf("Columns: %s\n", paste(names(la_2015_dt), collapse = ", ")))
names(la_2015_dt)[1] <- "la_name"
la_2015_dt <- la_2015_dt[!is.na(la_name) & la_name != "" &
                          !grepl("Total|England|Region|Grand|Source|Note", la_name, ignore.case = TRUE)]
fwrite(la_2015_dt, file.path(data_dir, "historical_la_2015_raw.csv"))

# Also read the geo_code_lookup to get LA codes
cat("\n  Reading geography lookup...\n")
geo_lookup <- readxl::read_excel(hist_file, sheet = "geo_code_lookup", skip = 1)
geo_lookup_dt <- as.data.table(geo_lookup)
cat(sprintf("Geo lookup: %d rows\n", nrow(geo_lookup_dt)))
cat(sprintf("Lookup columns: %s\n", paste(names(geo_lookup_dt), collapse = ", ")))
fwrite(geo_lookup_dt, file.path(data_dir, "geo_code_lookup.csv"))

# ==============================================================================
# 2. NOMIS NM_142_1 — UK Business Counts by LA (2016, Bartik instrument)
# ==============================================================================
cat("\n=== Fetching NOMIS UK Business Counts ===\n")

nomis_key <- Sys.getenv("NOMIS_API_KEY")
nomis_auth <- if (nchar(nomis_key) > 0) paste0("&uid=", nomis_key) else ""

# Server-side filter: industry=37748736 (Total), legal_status=0
# Size bands: 0=Total, 40=Large(250+)
nomis_biz_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_142_1.data.csv",
  "?geography=TYPE464",
  "&date=2016",
  "&measures=20100",
  "&employment_sizeband=0,40",
  "&legal_status=0",
  "&industry=37748736",
  "&select=date_name,geography_name,geography_code,employment_sizeband_name,obs_value",
  nomis_auth
)

cat("  Downloading business counts (2016, industry=Total)...\n")
biz_resp <- request(nomis_biz_url) |>
  req_timeout(120) |>
  req_perform()

biz_file <- file.path(data_dir, "nomis_business_counts_2016.csv")
writeBin(resp_body_raw(biz_resp), biz_file)
biz_raw <- fread(biz_file)
cat(sprintf("  Business counts: %d rows, %d LAs\n", nrow(biz_raw), n_distinct(biz_raw$GEOGRAPHY_CODE)))
cat(sprintf("  Size bands: %s\n", paste(unique(biz_raw$EMPLOYMENT_SIZEBAND_NAME), collapse = " | ")))

# Also get population of enterprises for 2015 (robustness)
cat("  Fetching 2015 for robustness...\n")
biz_url_2015 <- gsub("date=2016", "date=2015", nomis_biz_url)
tryCatch({
  biz_2015_resp <- request(biz_url_2015) |> req_timeout(120) |> req_perform()
  writeBin(resp_body_raw(biz_2015_resp), file.path(data_dir, "nomis_business_counts_2015.csv"))
  cat("  2015 saved.\n")
}, error = function(e) cat(sprintf("  2015 failed: %s\n", e$message)))

# ==============================================================================
# 3. ONS Population — via mid-year estimates CSV bulk download
# ==============================================================================
cat("\n=== Fetching ONS population estimates ===\n")

# Use ONS mid-year population estimates — direct CSV from ONS open data
# These are published as CSVs on the ONS website
# For the Bartik DiD, we mainly need the population to normalize starts
# But we can also work with un-normalized starts (log starts)

# Try NOMIS NM_31_1 with httr2 — 5-year age bands
pop_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv",
  "?geography=TYPE464",
  "&date=2010-2020",
  "&sex=7",           # Total
  "&age=0",           # All ages
  "&measures=20100",
  "&select=date_name,geography_name,geography_code,obs_value",
  nomis_auth
)

cat("  Downloading population (NM_31_1, all ages)...\n")
tryCatch({
  pop_resp <- request(pop_url) |>
    req_timeout(120) |>
    req_perform()

  pop_raw <- resp_body_string(pop_resp)
  if (nchar(pop_raw) > 100) {
    pop_file <- file.path(data_dir, "nomis_population_la.csv")
    writeLines(pop_raw, pop_file)
    pop_dt <- fread(pop_file)
    cat(sprintf("  Population: %d rows, %d LAs\n", nrow(pop_dt), n_distinct(pop_dt$GEOGRAPHY_CODE)))

    # Check if values are present
    pop_dt[, obs_num := as.numeric(OBS_VALUE)]
    valid_pop <- sum(!is.na(pop_dt$obs_num) & pop_dt$obs_num > 0)
    cat(sprintf("  Non-zero population values: %d / %d\n", valid_pop, nrow(pop_dt)))
  } else {
    cat("  Response too short, population data may not be available via NOMIS.\n")
  }
}, error = function(e) {
  cat(sprintf("  Population download failed: %s\n", e$message))
})

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Files in %s:\n", data_dir))
for (f in list.files(data_dir, pattern = "\\.(csv|xlsx)$")) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s (%.1f KB)\n", f, sz / 1024))
}
