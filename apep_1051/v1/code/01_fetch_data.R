# 01_fetch_data.R — Fetch CRP enrollment (FSA) + crop acreage (NASS) data
# apep_1051: CRP Cap Reduction and Land-Use Transitions

source("00_packages.R")

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(readxl)

# Ensure data directory exists (relative to code/)
dir.create("../data", showWarnings = FALSE, recursive = TRUE)
data_dir <- "../data"

NASS_API_KEY <- Sys.getenv("USDA_NASS_API_KEY")
if (nchar(NASS_API_KEY) == 0) stop("USDA_NASS_API_KEY not found in environment")

# ============================================================
# 1. CRP ENROLLMENT — county-level, 1986-2024 (FSA Excel)
# ============================================================
cat("Downloading CRP enrollment from FSA...\n")
crp_url <- "https://www.fsa.usda.gov/sites/default/files/2025-02/CRPHistoryCounty86-24.xlsx"
crp_file <- file.path(data_dir, "CRPHistoryCounty86-24.xlsx")
# FSA requires browser-like user-agent
ua <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
system2("curl", args = c("-sL", "-o", shQuote(crp_file), "-A", shQuote(ua),
                          "--max-time", "120", shQuote(crp_url)))
if (!file.exists(crp_file) || file.size(crp_file) < 100000) {
  stop("FATAL: CRP download failed or file too small")
}
cat("CRP file downloaded:", file.size(crp_file), "bytes\n")

crp_acres <- read_excel(crp_file, sheet = "ACRES", skip = 2)
cat("CRP Excel loaded:", nrow(crp_acres), "rows,", ncol(crp_acres), "columns\n")
cat("Column names:", paste(head(names(crp_acres), 6), collapse = ", "), "...\n")

# Columns should now be: STATE, COUNTY, FIPS, 1986, 1987, ...
year_cols <- grep("^\\d{4}$", names(crp_acres), value = TRUE)
cat("Year columns found:", length(year_cols), "| Range:", min(year_cols), "-", max(year_cols), "\n")
if (length(year_cols) == 0) stop("FATAL: No year columns found after skip=2")

crp_long <- crp_acres %>%
  select(STATE, COUNTY, FIPS, all_of(year_cols)) %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "year",
    values_to = "crp_acres"
  ) %>%
  rename(state_name = STATE, county_name = COUNTY, fips = FIPS) %>%
  mutate(
    fips = str_pad(as.character(as.integer(fips)), 5, pad = "0"),
    year = as.integer(year),
    crp_acres = as.numeric(crp_acres)
  ) %>%
  filter(year >= 2006, year <= 2022, !is.na(crp_acres), !is.na(fips), fips != "   NA")

cat("CRP panel: ", nrow(crp_long), " obs, ", n_distinct(crp_long$fips),
    " counties, years ", paste(range(crp_long$year), collapse = "-"), "\n")

# Also get contract expirations data
cat("Downloading CRP expiration data from FSA...\n")
expire_url <- "https://www.fsa.usda.gov/sites/default/files/documents/EXPIRECOUNTY.xlsx"
expire_file <- file.path(data_dir, "EXPIRECOUNTY.xlsx")
tryCatch({
  system2("curl", args = c("-sL", "-o", shQuote(expire_file), "-A", shQuote(ua),
                            "--max-time", "120", shQuote(expire_url)))
  if (file.exists(expire_file) && file.size(expire_file) > 10000) {
    cat("Expiration file downloaded:", file.size(expire_file), "bytes\n")
  }
}, error = function(e) {
  cat("WARNING: Could not download expiration data:", conditionMessage(e), "\n")
})

# ============================================================
# 2. CROP ACREAGE — corn, soybeans, wheat (NASS API)
# ============================================================
cat("Fetching crop acreage from NASS API...\n")

base_url <- "https://quickstats.nass.usda.gov/api/api_GET/"

query_nass <- function(params) {
  params$key <- NASS_API_KEY
  params$format <- "JSON"
  resp <- httr::GET(base_url, query = params, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    warning("NASS API error: ", httr::status_code(resp))
    return(data.frame())
  }
  content <- httr::content(resp, "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, flatten = TRUE)
  if (is.null(parsed$data) || length(parsed$data) == 0) {
    return(data.frame())
  }
  as.data.frame(parsed$data)
}

fetch_crop <- function(commodity, stat_cat = "AREA PLANTED") {
  cat("  Fetching", commodity, stat_cat, "...\n")
  all_data <- list()
  # Query by groups of years to avoid API limits
  year_groups <- list(c(2006, 2010), c(2011, 2015), c(2016, 2022))
  for (yg in year_groups) {
    raw <- query_nass(list(
      source_desc       = "SURVEY",
      sector_desc       = "CROPS",
      commodity_desc    = commodity,
      statisticcat_desc = stat_cat,
      unit_desc         = "ACRES",
      agg_level_desc    = "COUNTY",
      year__GE          = as.character(yg[1]),
      year__LE          = as.character(yg[2])
    ))
    if (nrow(raw) > 0) all_data[[length(all_data) + 1]] <- raw
  }
  if (length(all_data) == 0) return(data.frame())
  bind_rows(all_data) %>%
    filter(!grepl("OTHER|COMBINED", county_name, ignore.case = TRUE)) %>%
    mutate(
      fips = paste0(
        str_pad(state_fips_code, 2, pad = "0"),
        str_pad(county_code, 3, pad = "0")
      ),
      year = as.integer(year),
      acres = as.numeric(gsub(",", "", Value)),
      crop = commodity
    ) %>%
    filter(!is.na(acres), acres >= 0) %>%
    select(fips, state_name, county_name, year, crop, acres) %>%
    distinct()
}

corn <- fetch_crop("CORN")
soy  <- fetch_crop("SOYBEANS")
wheat <- fetch_crop("WHEAT")
hay  <- fetch_crop("HAY", "AREA HARVESTED")

crop_data <- bind_rows(corn, soy, wheat, hay)
cat("Total crop records:", nrow(crop_data), "| Counties:", n_distinct(crop_data$fips), "\n")
if (nrow(crop_data) == 0) stop("FATAL: No crop acreage data returned from NASS API")

# ============================================================
# 3. TOTAL CROPLAND — Census of Agriculture (2007, 2012, 2017)
# ============================================================
cat("Fetching total cropland from Census of Agriculture...\n")

cropland_data <- list()
for (yr in c(2007, 2012, 2017)) {
  cat("  Census year", yr, "...\n")
  raw <- query_nass(list(
    source_desc = "CENSUS",
    sector_desc = "ECONOMICS",
    group_desc  = "FARMS & LAND & ASSETS",
    short_desc  = "AG LAND, CROPLAND - ACRES",
    agg_level_desc = "COUNTY",
    year        = as.character(yr)
  ))
  if (nrow(raw) > 0) cropland_data[[length(cropland_data) + 1]] <- raw
}

cropland <- data.frame()
if (length(cropland_data) > 0) {
  cropland <- bind_rows(cropland_data) %>%
    filter(!grepl("OTHER|COMBINED", county_name, ignore.case = TRUE)) %>%
    mutate(
      fips = paste0(
        str_pad(state_fips_code, 2, pad = "0"),
        str_pad(county_code, 3, pad = "0")
      ),
      year = as.integer(year),
      total_cropland = as.numeric(gsub(",", "", Value))
    ) %>%
    filter(!is.na(total_cropland), total_cropland > 0) %>%
    select(fips, year, total_cropland) %>%
    distinct()
  cat("Cropland Census records:", nrow(cropland), "| Counties:", n_distinct(cropland$fips), "\n")
}

# ============================================================
# 4. SAVE RAW DATA
# ============================================================
saveRDS(crp_long, file.path(data_dir, "crp_enrollment.rds"))
saveRDS(crop_data, file.path(data_dir, "crop_acreage.rds"))
saveRDS(cropland, file.path(data_dir, "total_cropland.rds"))

cat("\n=== DATA FETCH SUMMARY ===\n")
cat("CRP enrollment:", nrow(crp_long), "obs,", n_distinct(crp_long$fips), "counties,",
    paste(range(crp_long$year), collapse = "-"), "\n")
cat("Crop acreage:", nrow(crop_data), "obs,", n_distinct(crop_data$fips), "counties\n")
cat("  Corn:", sum(crop_data$crop == "CORN"), "| Soybeans:", sum(crop_data$crop == "SOYBEANS"),
    "| Wheat:", sum(crop_data$crop == "WHEAT"), "| Hay:", sum(crop_data$crop == "HAY"), "\n")
cat("Total cropland:", nrow(cropland), "obs,", n_distinct(cropland$fips), "counties\n")
cat("All data saved to data/\n")
