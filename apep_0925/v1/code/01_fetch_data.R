# 01_fetch_data.R — Fetch UK Business Counts from NOMIS API
# NM_142_1: enterprises by industry, employment size band, country
# Filter: LEGAL_STATUS_NAME = "Total" to get one row per cell

source("00_packages.R")

NOMIS_KEY <- Sys.getenv("NOMIS_API_KEY")
DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- NOMIS codes (discovered from API metadata) ----
# Geography: 2092957699=England, 2092957701=Scotland, 2092957700=Wales
GEO_CODES <- "2092957699,2092957701,2092957700"

# Industries:
# 146800696 = 56: Food and beverage service activities (TREATED)
# 146800687 = 47: Retail trade (CONTROL)
# 146800695 = 55: Accommodation (CONTROL)
# 146800702 = 62: Computer programming (CONTROL)
# 146800709 = 69: Legal and accounting (CONTROL)
IND_CODES <- "146800696,146800687,146800695,146800702,146800709"

# Size bands: 0=Total,1=0-4,2=5-9,3=10-19,4=20-49,5=50-99,6=100-249,7=250-499,8=500-999,9=1000+
# We want all individual bands for the size distribution analysis
SIZE_CODES <- "1,2,3,4,5,6,7,8,9"

# Years: 2010-2024 (long pre-period for event study)
YEARS <- paste(2010:2024, collapse = ",")

# ---- Fetch function ----
fetch_nomis <- function(url, desc) {
  cat(sprintf("Fetching %s...\n", desc))
  if (nchar(NOMIS_KEY) > 0) url <- paste0(url, "&uid=", NOMIS_KEY)

  resp <- httr2::request(url) |>
    httr2::req_timeout(180) |>
    httr2::req_perform()

  body <- httr2::resp_body_string(resp)
  df <- readr::read_csv(body, show_col_types = FALSE)
  cat(sprintf("  → %d rows\n", nrow(df)))
  stopifnot("No data returned" = nrow(df) > 0)
  df
}

# ---- 1. Fetch enterprise counts ----
cat("=== Fetching NM_142_1: Enterprise counts by size band ===\n\n")

url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_142_1.data.csv?",
  "geography=", GEO_CODES,
  "&industry=", IND_CODES,
  "&employment_sizeband=", SIZE_CODES,
  "&legal_status=0",  # Total only (not private/public/company breakdown)
  "&time=", YEARS,
  "&measures=20100",
  "&select=GEOGRAPHY_NAME,GEOGRAPHY_CODE,INDUSTRY_NAME,INDUSTRY_CODE,",
  "EMPLOYMENT_SIZEBAND_NAME,EMPLOYMENT_SIZEBAND,",
  "LEGAL_STATUS_NAME,DATE_NAME,DATE,OBS_VALUE"
)

data_ent <- fetch_nomis(url, "Enterprise counts (Eng+Scot+Wales, 5 industries, 2010-2024)")

# ---- 2. Validate ----
cat("\n=== Data validation ===\n")
cat(sprintf("Total rows: %d\n", nrow(data_ent)))
cat(sprintf("Geographies: %s\n", paste(unique(data_ent$GEOGRAPHY_NAME), collapse = ", ")))
cat(sprintf("Industries: %s\n", paste(unique(data_ent$INDUSTRY_NAME), collapse = "; ")))
cat(sprintf("Size bands: %s\n", paste(unique(data_ent$EMPLOYMENT_SIZEBAND_NAME), collapse = "; ")))
cat(sprintf("Years: %s\n", paste(sort(unique(data_ent$DATE_NAME)), collapse = ", ")))
cat(sprintf("Legal status: %s\n", paste(unique(data_ent$LEGAL_STATUS_NAME), collapse = ", ")))

# Quick peek at SIC 56 around the threshold
food_threshold <- data_ent |>
  filter(INDUSTRY_CODE == "56",
         EMPLOYMENT_SIZEBAND_NAME %in% c("100 to 249", "250 to 499")) |>
  arrange(GEOGRAPHY_NAME, EMPLOYMENT_SIZEBAND_NAME, DATE_NAME) |>
  select(GEOGRAPHY_NAME, EMPLOYMENT_SIZEBAND_NAME, DATE_NAME, OBS_VALUE)

cat("\n=== Food services around 250-employee threshold ===\n")
print(as.data.frame(food_threshold))

# ---- 3. Also fetch with Total sizeband for denomination ----
cat("\n=== Fetching total enterprise counts for shares ===\n")
url_total <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_142_1.data.csv?",
  "geography=", GEO_CODES,
  "&industry=", IND_CODES,
  "&employment_sizeband=0",  # Total
  "&legal_status=0",
  "&time=", YEARS,
  "&measures=20100",
  "&select=GEOGRAPHY_NAME,GEOGRAPHY_CODE,INDUSTRY_NAME,INDUSTRY_CODE,",
  "EMPLOYMENT_SIZEBAND_NAME,EMPLOYMENT_SIZEBAND,DATE_NAME,DATE,OBS_VALUE"
)

data_total <- fetch_nomis(url_total, "Total enterprise counts")

# ---- 4. Save ----
saveRDS(data_ent, file.path(DATA_DIR, "enterprise_counts_by_sizeband.rds"))
saveRDS(data_total, file.path(DATA_DIR, "enterprise_counts_total.rds"))
write_csv(data_ent, file.path(DATA_DIR, "enterprise_counts_by_sizeband.csv"))

cat(sprintf("\n✓ Saved %d rows (by sizeband) + %d rows (totals)\n",
  nrow(data_ent), nrow(data_total)))
