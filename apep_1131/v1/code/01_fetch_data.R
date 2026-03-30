# 01_fetch_data.R — Fetch all data sources
# apep_1131: The Hollow Safety Net
# Sources: Census QWI, DOL BTQ, Census ASPEP, DOL ETA 539, BEA

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
bea_key    <- Sys.getenv("BEA_API_KEY")
stopifnot("CENSUS_API_KEY not set" = nzchar(census_key))
stopifnot("BEA_API_KEY not set"    = nzchar(bea_key))

raw_dir <- "../data/raw"
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# State FIPS codes (50 states + DC)
state_fips <- c("01","02","04","05","06","08","09","10","11","12","13",
                "15","16","17","18","19","20","21","22","23","24","25",
                "26","27","28","29","30","31","32","33","34","35","36",
                "37","38","39","40","41","42","44","45","46","47","48",
                "49","50","51","53","54","55","56")

state_abbrevs <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                   "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                   "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                   "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                   "UT","VT","VA","WA","WV","WI","WY")

fips_to_abbrev <- setNames(state_abbrevs, state_fips)

# ===========================================================================
# Section 1: Census QWI — Industry employment by state-quarter (2005-2012)
# ===========================================================================
cat("=== Fetching QWI industry employment ===\n")

naics_sectors <- c("11","21","22","23","31-33","42","44-45","48-49",
                   "51","52","53","54","55","56","61","62","71","72","81")

quarters <- paste0(rep(2005:2012, each = 4), "-Q", 1:4)

all_states_str <- paste(state_fips, collapse = ",")

qwi_all <- list()
for (ind in naics_sectors) {
  cat(sprintf("  QWI industry=%s ...\n", ind))
  for (q in quarters) {
    url <- sprintf(
      "https://api.census.gov/data/timeseries/qwi/sa?get=Emp,EmpEnd&for=state:%s&time=%s&industry=%s&key=%s",
      all_states_str, q, URLencode(ind), census_key
    )
    resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
    if (is.null(resp) || httr::status_code(resp) != 200) {
      Sys.sleep(0.5)
      next
    }
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) < 20) next
    parsed <- tryCatch(jsonlite::fromJSON(txt), error = function(e) NULL)
    if (is.null(parsed) || nrow(parsed) < 2) next
    df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    qwi_all[[length(qwi_all) + 1]] <- df
  }
  Sys.sleep(0.3)  # rate limiting
}

stopifnot("QWI fetch returned no data" = length(qwi_all) > 0)
qwi_df <- bind_rows(qwi_all)
qwi_df$Emp    <- as.numeric(qwi_df$Emp)
qwi_df$EmpEnd <- as.numeric(qwi_df$EmpEnd)
qwi_df$state_fips <- qwi_df$state

cat(sprintf("  QWI: %d rows, %d states, %d industries, %d quarters\n",
            nrow(qwi_df), n_distinct(qwi_df$state_fips),
            n_distinct(qwi_df$industry), n_distinct(qwi_df$time)))
write_csv(qwi_df, file.path(raw_dir, "qwi_industry_emp.csv"))

# ===========================================================================
# Section 2: DOL BTQ — First Payment Timeliness by state-month (2005-2012)
# ===========================================================================
cat("=== Fetching DOL BTQ First Payment Timeliness ===\n")

btq_all <- list()
for (yr in 2005:2012) {
  cat(sprintf("  BTQ year=%d ...\n", yr))
  # Build POST body with all states
  params <- paste0(
    paste0("states%5B%5D=", state_abbrevs, collapse = "&"),
    "&category=1",
    sprintf("&strtmonth=01&strtyear=%d&endmonth=12&endyear=%d", yr, yr)
  )
  resp <- tryCatch(
    httr::POST(
      "https://oui.doleta.gov/unemploy/btq/btqrpt.asp",
      body = params,
      httr::content_type("application/x-www-form-urlencoded"),
      httr::timeout(60)
    ),
    error = function(e) { cat("    BTQ error:", e$message, "\n"); NULL }
  )
  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat(sprintf("    BTQ year %d failed (status=%s)\n", yr,
                ifelse(is.null(resp), "NULL", httr::status_code(resp))))
    next
  }
  page <- rvest::read_html(httr::content(resp, "text", encoding = "UTF-8"))
  tbls <- rvest::html_table(page, fill = TRUE)
  if (length(tbls) == 0) {
    cat(sprintf("    BTQ year %d: no tables found\n", yr))
    next
  }
  # Find the largest table (the data table)
  tbl_sizes <- sapply(tbls, nrow)
  main_tbl <- tbls[[which.max(tbl_sizes)]]
  main_tbl$year <- yr
  btq_all[[length(btq_all) + 1]] <- main_tbl
  Sys.sleep(1)
}

stopifnot("BTQ fetch returned no data" = length(btq_all) > 0)

# Parse and clean BTQ data
btq_raw <- bind_rows(btq_all)
write_csv(btq_raw, file.path(raw_dir, "btq_raw.csv"))
cat(sprintf("  BTQ raw: %d rows\n", nrow(btq_raw)))

# ===========================================================================
# Section 3: Census ASPEP — State government employment (2007, pre-recession)
# ===========================================================================
cat("=== Fetching Census ASPEP 2007 ===\n")

aspep_url <- "https://www2.census.gov/programs-surveys/apes/datasets/2007/annual-apes/2007_downloadable_data.zip"
aspep_zip <- file.path(raw_dir, "aspep_2007.zip")
aspep_dir <- file.path(raw_dir, "aspep_2007")

download.file(aspep_url, aspep_zip, mode = "wb", quiet = TRUE)
stopifnot("ASPEP download failed" = file.exists(aspep_zip) && file.size(aspep_zip) > 1000)

dir.create(aspep_dir, showWarnings = FALSE)
unzip(aspep_zip, exdir = aspep_dir)
aspep_files <- list.files(aspep_dir, pattern = "\\.(csv|CSV|txt|TXT|dat)$",
                          full.names = TRUE, recursive = TRUE)
cat(sprintf("  ASPEP files: %s\n", paste(basename(aspep_files), collapse = ", ")))

# Read all ASPEP files
aspep_dfs <- lapply(aspep_files, function(f) {
  tryCatch(read.csv(f, stringsAsFactors = FALSE), error = function(e) NULL)
})
aspep_dfs <- Filter(Negate(is.null), aspep_dfs)
stopifnot("Could not read ASPEP data" = length(aspep_dfs) > 0)

aspep_df <- bind_rows(aspep_dfs)
write_csv(aspep_df, file.path(raw_dir, "aspep_2007.csv"))
cat(sprintf("  ASPEP: %d rows, columns: %s\n", nrow(aspep_df),
            paste(names(aspep_df), collapse = ", ")))

# ===========================================================================
# Section 4: DOL ETA 539 — Weekly UI claims by state
# ===========================================================================
cat("=== Fetching DOL ETA 539 weekly claims ===\n")

eta539_url <- "https://oui.doleta.gov/unemploy/csv/ar539.csv"
eta539_file <- file.path(raw_dir, "eta539.csv")

tryCatch({
  download.file(eta539_url, eta539_file, mode = "wb", quiet = TRUE)
  stopifnot(file.exists(eta539_file) && file.size(eta539_file) > 1000)
  # Read and check
  eta539_raw <- fread(eta539_file, nrows = 5)
  cat(sprintf("  ETA 539: downloaded (%s bytes), columns: %s\n",
              format(file.size(eta539_file), big.mark = ","),
              paste(names(eta539_raw), collapse = ", ")))
}, error = function(e) {
  cat("  ETA 539 download failed:", e$message, "\n")
  cat("  Will proceed without weekly claims — using reduced-form approach.\n")
})

# ===========================================================================
# Section 5: BEA — State personal income (control variable)
# ===========================================================================
cat("=== Fetching BEA state personal income ===\n")

years_str <- paste(2005:2012, collapse = ",")
bea_url <- sprintf(
  "https://apps.bea.gov/api/data/?UserID=%s&method=GetData&DataSetName=Regional&TableName=SAINC1&LineCode=1&GeoFips=STATE&Year=%s&ResultFormat=JSON",
  bea_key, years_str
)

bea_resp <- tryCatch(httr::GET(bea_url, httr::timeout(30)), error = function(e) NULL)
if (!is.null(bea_resp) && httr::status_code(bea_resp) == 200) {
  bea_json <- jsonlite::fromJSON(httr::content(bea_resp, "text", encoding = "UTF-8"))
  if (!is.null(bea_json$BEAAPI$Results$Data)) {
    bea_df <- bea_json$BEAAPI$Results$Data
    write_csv(bea_df, file.path(raw_dir, "bea_state_income.csv"))
    cat(sprintf("  BEA: %d rows\n", nrow(bea_df)))
  } else {
    cat("  BEA: no data in response\n")
  }
} else {
  cat("  BEA fetch failed — proceeding without income control\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Files in raw/:\n")
cat(paste(" ", list.files(raw_dir, recursive = TRUE), collapse = "\n"), "\n")
