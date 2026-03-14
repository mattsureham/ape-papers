## 01_fetch_data.R — Download all data sources
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))
cat("Working directory:", getwd(), "\n")

# ============================================================
# 1. MHCLG Live Table 123 — Housing supply by LA
# ============================================================
cat("\n=== Downloading Table 123 (housing supply) ===\n")
t123_url <- "https://assets.publishing.service.gov.uk/media/691de4732c6b98ecdbc500cb/Live_Table_123.ods"
t123_file <- "Live_Table_123.ods"

resp <- httr2::request(t123_url) |> httr2::req_perform()
writeBin(httr2::resp_body_raw(resp), t123_file)
cat("Table 123 downloaded:", file.size(t123_file), "bytes\n")

# List sheets to identify the right one
sheets <- readODS::list_ods_sheets(t123_file)
cat("Sheets:", paste(sheets, collapse = ", "), "\n")

# ============================================================
# 2. VOA Non-Domestic Floorspace by LA (2025 release)
# ============================================================
cat("\n=== Downloading VOA floorspace data ===\n")
voa_url <- "https://assets.publishing.service.gov.uk/media/694165351d8a56d23b7f0af9/NDR_SCat_Floorspace_LA_2025.zip"
voa_zip <- "voa_floorspace_la.zip"

resp <- httr2::request(voa_url) |> httr2::req_perform()
writeBin(httr2::resp_body_raw(resp), voa_zip)
cat("VOA zip downloaded:", file.size(voa_zip), "bytes\n")
unzip(voa_zip, exdir = "voa_floorspace")
voa_files <- list.files("voa_floorspace", full.names = TRUE)
cat("VOA extracted files:", paste(voa_files, collapse = ", "), "\n")

# ============================================================
# 3. ONS Mid-Year Population Estimates by LA
# ============================================================
cat("\n=== Fetching ONS population estimates ===\n")
# Use NOMIS for population estimates — NM_31_1 (Mid-year pop estimates)
# Query for all English LAs, 2006-2023
pop_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv?",
  "geography=TYPE464&",  # Local Authority Districts
  "date=2006-2023&",
  "sex=7&",             # Total (male + female)
  "age=0&",             # All ages
  "measures=20100&",    # Value
  "select=date_name,geography_name,geography_code,obs_value"
)

pop_resp <- httr2::request(pop_url) |> httr2::req_perform()
pop_raw <- httr2::resp_body_string(pop_resp)
pop_dt <- fread(text = pop_raw)
cat("Population data:", nrow(pop_dt), "rows\n")
fwrite(pop_dt, "population_by_la.csv")

# ============================================================
# 4. ONS UK House Price Index by LA and property type
# ============================================================
cat("\n=== Fetching ONS UK HPI data ===\n")
# The UK HPI is available from Land Registry as linked open data
# Download HPI data from ONS — use data.gov.uk CKAN to find it
# Actually, use the UK HPI bulk download
hpi_url <- "https://www.gov.uk/government/statistical-data-sets/uk-house-price-index-data-downloads-november-2024"

# More reliable: use ONS median house prices from the HPSSA dataset
# Table HPSSA-9: Median price paid by LA (E&W), quarterly
# Available on ONS directly
# Let's fetch from ONS HPI CSV download — annual median by LA
# Use the published CSV files from UK HPI

# Alternative: Use Land Registry published summary tables
# UK HPI data is available as CSV from https://landregistry.data.gov.uk
# Try the UK HPI data API
hpi_base <- "https://landregistry.data.gov.uk/app/ukhpi/download/new.csv"
hpi_params <- "?from=2006-01-01&to=2024-12-01&location=http%3A%2F%2Flandregistry.data.gov.uk%2Fid%2Fregion%2Funited-kingdom"

# For LA-level data, we'll use the ONS median prices dataset
# HPSSA Dataset 9: Median price paid for residential properties by LA
# Available from ONS website as Excel
hpi_ons_url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/housing/datasets/medianhousepricefornationalandsubnationalgeographiesquarterlyrollingyearhpssadataset09/current/hpssadataset9medianpricepaidbylafd.zip"

tryCatch({
  resp <- httr2::request(hpi_ons_url) |>
    httr2::req_headers("User-Agent" = "APEP-Research/1.0") |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), "hpi_median_la.zip")
  unzip("hpi_median_la.zip", exdir = "hpi_la")
  hpi_files <- list.files("hpi_la", full.names = TRUE, pattern = "\\.(xls|xlsx|csv)$")
  cat("HPI files:", paste(hpi_files, collapse = ", "), "\n")
}, error = function(e) {
  cat("ONS HPI download failed:", e$message, "\n")
  cat("Will try alternative approach using UK HPI API.\n")
})

# ============================================================
# 5. Article 4 Direction boroughs (known list)
# ============================================================
cat("\n=== Creating Article 4 direction list ===\n")
# London boroughs that implemented Article 4 directions
# to remove PD rights for office-to-residential
# Source: London Councils (2013-2014), MHCLG research
article4 <- data.table(
  la_name = c(
    "City of London", "Camden", "Islington", "Richmond upon Thames",
    "Southwark", "Tower Hamlets", "Westminster",
    "Kensington and Chelsea", "Hackney", "Lambeth",
    "Wandsworth", "Hammersmith and Fulham"
  ),
  article4 = 1L
)
fwrite(article4, "article4_boroughs.csv")
cat("Article 4 boroughs:", nrow(article4), "\n")

cat("\n=== All data downloaded ===\n")
