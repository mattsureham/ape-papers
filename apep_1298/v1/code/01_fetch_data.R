# ==============================================================================
# 01_fetch_data.R — Fetch QWI via Python helper + QCEW from BLS
# ==============================================================================

source("00_packages.R")

# --- 1. QWI private-sector employment via Python DuckDB (Azure) ---
cat("Fetching QWI from Azure via Python...\n")
py_exit <- system2("python3", "01a_fetch_qwi.py", stdout = TRUE, stderr = TRUE)
cat(py_exit, sep = "\n")
if (!file.exists("../data/qwi_total.parquet")) {
  stop("QWI fetch failed: qwi_total.parquet not found")
}

# Read the parquet files into R
qwi_total <- arrow::read_parquet("../data/qwi_total.parquet")
qwi_sector <- arrow::read_parquet("../data/qwi_sector.parquet")
cat(sprintf("QWI total: %d rows, %d counties\n", nrow(qwi_total), length(unique(qwi_total$geography))))
cat(sprintf("QWI sector: %d rows\n", nrow(qwi_sector)))

# --- 2. QCEW federal employment from BLS ---
cat("Fetching QCEW federal employment data from BLS...\n")

fetch_qcew_year <- function(yr) {
  url <- sprintf("https://data.bls.gov/cew/data/files/%d/csv/%d_annual_singlefile.zip", yr, yr)
  zip_file <- sprintf("../data/qcew_%d.zip", yr)
  csv_dir <- "../data/"

  if (!file.exists(zip_file)) {
    cat(sprintf("Downloading QCEW %d (~75MB)...\n", yr))
    resp <- httr::GET(url, httr::write_disk(zip_file, overwrite = TRUE), httr::timeout(600))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("QCEW download failed for %d: HTTP %d", yr, httr::status_code(resp)))
    }
  }

  csv_files <- unzip(zip_file, list = TRUE)$Name
  target <- csv_files[grepl("singlefile", csv_files, ignore.case = TRUE)]
  if (length(target) == 0) target <- csv_files[1]

  csv_path <- file.path(csv_dir, target)
  if (!file.exists(csv_path)) {
    cat(sprintf("Extracting %s...\n", target))
    unzip(zip_file, files = target, exdir = csv_dir, overwrite = TRUE)
  }

  cat(sprintf("Reading QCEW %d...\n", yr))
  df <- fread(csv_path,
              select = c("area_fips", "own_code", "industry_code", "agglvl_code",
                         "annual_avg_emplvl"),
              showProgress = FALSE)

  # County-level: agglvl 70 = total all ownership, agglvl 71 = by ownership
  # own_code: 0=Total all, 1=Federal, 2=State, 3=Local, 5=Private
  total <- df[agglvl_code == 70 & industry_code == "10" & own_code == 0,
              .(area_fips, total_emp = annual_avg_emplvl)]
  federal <- df[agglvl_code == 71 & industry_code == "10" & own_code == 1,
                .(area_fips, fed_emp = annual_avg_emplvl)]

  merged <- merge(total, federal, by = "area_fips", all.x = TRUE)
  merged[is.na(fed_emp), fed_emp := 0]
  merged[, year := yr]

  return(merged)
}

qcew_2012 <- fetch_qcew_year(2012)
qcew_2010 <- fetch_qcew_year(2010)

cat(sprintf("QCEW 2012: %d counties, mean fed share = %.3f\n",
            nrow(qcew_2012), mean(qcew_2012[total_emp > 0]$fed_emp / qcew_2012[total_emp > 0]$total_emp)))

# --- 3. County population from Census API ---
cat("Fetching county population...\n")
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  # Try reading from .env
  env_lines <- readLines("../../../../.env", warn = FALSE)
  for (l in env_lines) {
    if (grepl("^CENSUS_API_KEY=", l)) {
      census_key <- sub("^CENSUS_API_KEY=", "", l)
      census_key <- gsub("[\"']", "", census_key)
    }
  }
}
pop_url <- sprintf(
  "https://api.census.gov/data/2012/acs/acs5?get=B01003_001E,NAME&for=county:*&key=%s",
  census_key
)
pop_resp <- httr::GET(pop_url)
stopifnot("Census API failed" = httr::status_code(pop_resp) == 200)

pop_json <- httr::content(pop_resp, "text", encoding = "UTF-8")
pop_mat <- jsonlite::fromJSON(pop_json)
pop_df <- as.data.frame(pop_mat[-1, ], stringsAsFactors = FALSE)
names(pop_df) <- pop_mat[1, ]
pop_df$fips <- paste0(pop_df$state, pop_df$county)
pop_df$population <- as.numeric(pop_df$B01003_001E)
pop_df <- pop_df[, c("fips", "population")]
cat(sprintf("Census population: %d counties\n", nrow(pop_df)))

# --- 4. Save ---
saveRDS(as.data.table(qwi_total), "../data/qwi_total.rds")
saveRDS(as.data.table(qwi_sector), "../data/qwi_sector.rds")
saveRDS(qcew_2012, "../data/qcew_2012.rds")
saveRDS(qcew_2010, "../data/qcew_2010.rds")
saveRDS(pop_df, "../data/pop_df.rds")

cat("All data saved successfully.\n")

# Validation
stopifnot("QWI total has data" = nrow(qwi_total) > 10000)
stopifnot("QCEW has counties" = nrow(qcew_2012) > 1000)
stopifnot("Population data exists" = nrow(pop_df) > 1000)
cat("All assertions passed.\n")
