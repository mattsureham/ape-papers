## 01_fetch_data.R — Download IPEDS data directly from NCES
## apep_1022: Affirmative action bans and minority enrollment cascades

source("00_packages.R")

cat("=== Downloading IPEDS data from NCES ===\n")

raw_dir <- "../data/ipeds_raw"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

## -------------------------------------------------------------------
## Helper: download and extract IPEDS zip, return path to main CSV
## -------------------------------------------------------------------
download_ipeds <- function(fname, outdir) {
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  zip_path <- file.path(outdir, paste0(fname, ".zip"))

  # Check for any existing CSV matching this table
  existing <- list.files(outdir, pattern = paste0("(?i)^", fname, "\\.csv$"),
                         full.names = TRUE)
  if (length(existing) > 0) {
    cat(sprintf("  %s: cached\n", fname))
    return(existing[1])
  }

  url <- sprintf("https://nces.ed.gov/ipeds/datacenter/data/%s.zip", fname)
  resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE), httr::timeout(120))

  if (httr::status_code(resp) != 200) {
    file.remove(zip_path)
    stop(sprintf("HTTP %d for %s", httr::status_code(resp), fname))
  }

  # Check file size — tiny files are error pages, not zips
  if (file.info(zip_path)$size < 1000) {
    file.remove(zip_path)
    stop(sprintf("Downloaded file too small for %s (likely error page)", fname))
  }

  unzip(zip_path, exdir = outdir, overwrite = TRUE)
  file.remove(zip_path)

  # Find the main data CSV (not _rv revision, not _dict, not _varlist)
  all_csvs <- list.files(outdir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  main_csvs <- all_csvs[!grepl("_rv|_dict|_varlist|flags", all_csvs, ignore.case = TRUE)]

  # Prefer exact match to fname
  exact <- main_csvs[grepl(paste0("(?i)^", fname, "\\.csv$"), basename(main_csvs))]
  if (length(exact) > 0) return(exact[1])
  if (length(main_csvs) > 0) return(main_csvs[1])

  stop(sprintf("No CSV found after unzipping %s", fname))
}

## -------------------------------------------------------------------
## 1. Fall enrollment by race: EF{year}A files (2001-2022)
## -------------------------------------------------------------------
cat("Downloading Fall Enrollment (EF*A) files...\n")

ef_list <- list()
for (yr in 2001:2022) {
  fname <- sprintf("EF%dA", yr)
  tryCatch({
    csv_path <- download_ipeds(fname, file.path(raw_dir, "ef"))
    d <- data.table::fread(csv_path, header = TRUE, showProgress = FALSE)
    names(d) <- tolower(names(d))
    d$year <- yr
    ef_list[[as.character(yr)]] <- d
    cat(sprintf("  %s: %d rows, %d cols\n", fname, nrow(d), ncol(d)))
  }, error = function(e) {
    cat(sprintf("  WARNING: %s failed: %s\n", fname, e$message))
  })
}

stopifnot("FATAL: No enrollment data" = length(ef_list) > 0)
cat(sprintf("Downloaded EF files for %d years\n", length(ef_list)))
saveRDS(ef_list, "../data/ef_raw_list.rds")

## -------------------------------------------------------------------
## 2. Directory (HD) — state FIPS, sector, Carnegie class (2001-2022)
## -------------------------------------------------------------------
cat("Downloading Directory (HD) files...\n")

hd_list <- list()
for (yr in 2001:2022) {
  fname <- sprintf("HD%d", yr)
  tryCatch({
    csv_path <- download_ipeds(fname, file.path(raw_dir, "hd"))
    d <- data.table::fread(csv_path, header = TRUE, showProgress = FALSE)
    names(d) <- tolower(names(d))
    d$year <- yr
    hd_list[[as.character(yr)]] <- d
  }, error = function(e) {
    cat(sprintf("  WARNING: %s failed: %s\n", fname, e$message))
  })
}

stopifnot("FATAL: No directory data" = length(hd_list) > 0)
cat(sprintf("Downloaded HD files for %d years\n", length(hd_list)))
saveRDS(hd_list, "../data/hd_raw_list.rds")

## -------------------------------------------------------------------
## 3. Admissions (ADM 2014+, IC_AY earlier) — selectivity
## -------------------------------------------------------------------
cat("Downloading Admissions/IC files...\n")

adm_list <- list()
for (yr in 2014:2022) {
  fname <- sprintf("ADM%d", yr)
  tryCatch({
    csv_path <- download_ipeds(fname, file.path(raw_dir, "adm"))
    d <- data.table::fread(csv_path, header = TRUE, showProgress = FALSE)
    names(d) <- tolower(names(d))
    d$year <- yr
    adm_list[[as.character(yr)]] <- d
  }, error = function(e) {
    cat(sprintf("  WARNING: %s failed: %s\n", fname, e$message))
  })
}

for (yr in 2001:2013) {
  fname <- sprintf("IC%d_AY", yr)
  tryCatch({
    csv_path <- download_ipeds(fname, file.path(raw_dir, "ic"))
    d <- data.table::fread(csv_path, header = TRUE, showProgress = FALSE)
    names(d) <- tolower(names(d))
    if (any(grepl("admssn|applcn", names(d)))) {
      d$year <- yr
      adm_list[[as.character(yr)]] <- d
    }
  }, error = function(e) {
    # Try without _AY suffix
    fname2 <- sprintf("IC%d", yr)
    tryCatch({
      csv_path2 <- download_ipeds(fname2, file.path(raw_dir, "ic"))
      d2 <- data.table::fread(csv_path2, header = TRUE, showProgress = FALSE)
      names(d2) <- tolower(names(d2))
      if (any(grepl("admssn|applcn", names(d2)))) {
        d2$year <- yr
        adm_list[[as.character(yr)]] <- d2
      }
    }, error = function(e2) {
      cat(sprintf("  WARNING: IC%d failed: %s\n", yr, e2$message))
    })
  })
}

cat(sprintf("Downloaded admissions files for %d years\n", length(adm_list)))
saveRDS(adm_list, "../data/adm_raw_list.rds")

## -------------------------------------------------------------------
## 4. ACS state demographics (18-24 population by race)
## -------------------------------------------------------------------
cat("Fetching ACS state demographics...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not set")

acs_list <- list()
for (yr in 2005:2022) {
  cat(sprintf("  ACS %d...\n", yr))

  vars_t <- paste0("B01001_", sprintf("%03d", c(7:10, 31:34)), "E")
  vars_b <- paste0("B01001B_", sprintf("%03d", c(3:6, 18:21)), "E")
  vars_h <- paste0("B01001I_", sprintf("%03d", c(3:6, 18:21)), "E")
  all_vars <- c(vars_t, vars_b, vars_h)

  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=NAME,%s&for=state:*&key=%s",
    yr, paste(all_vars, collapse = ","), census_key
  )

  resp <- tryCatch({
    r <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(r) != 200) NULL
    else httr::content(r, "text", encoding = "UTF-8")
  }, error = function(e) NULL)

  if (!is.null(resp)) {
    parsed <- jsonlite::fromJSON(resp)
    df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    for (v in all_vars) df[[v]] <- as.numeric(df[[v]])

    df$pop_18_24 <- rowSums(df[, vars_t], na.rm = TRUE)
    df$pop_18_24_black <- rowSums(df[, vars_b], na.rm = TRUE)
    df$pop_18_24_hisp <- rowSums(df[, vars_h], na.rm = TRUE)
    df$year <- yr
    df$fips <- as.integer(df$state)

    acs_list[[as.character(yr)]] <- df[, c("NAME", "fips", "year",
                                            "pop_18_24", "pop_18_24_black",
                                            "pop_18_24_hisp")]
  }
}

acs_raw <- bind_rows(acs_list)
cat(sprintf("ACS: %d state-years\n", nrow(acs_raw)))
saveRDS(acs_raw, "../data/acs_demographics.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("EF files: %d years\n", length(ef_list)))
cat(sprintf("HD files: %d years\n", length(hd_list)))
cat(sprintf("ADM files: %d years\n", length(adm_list)))
cat(sprintf("ACS: %d state-years\n", nrow(acs_raw)))
