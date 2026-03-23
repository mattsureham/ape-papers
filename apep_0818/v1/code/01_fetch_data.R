## 01_fetch_data.R — Fetch IRS revocation list, EO BMF, SOI county data, QWI
## apep_0818: Zombie Nonprofits

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. IRS Auto-Revocation List (pipe-delimited ZIP from IRS bulk downloads)
# ============================================================================
cat("=== Fetching IRS Auto-Revocation List ===\n")
revocation_file <- file.path(data_dir, "irs_revocation_list.csv")

if (!file.exists(revocation_file)) {
  zip_url <- "https://apps.irs.gov/pub/epostcard/data-download-revocation.zip"
  zip_file <- file.path(data_dir, "revocation_download.zip")

  cat("Downloading revocation ZIP from:", zip_url, "\n")
  resp <- httr::GET(zip_url, httr::timeout(300),
                    httr::write_disk(zip_file, overwrite = TRUE))

  if (httr::status_code(resp) != 200 || file.size(zip_file) < 100000) {
    stop("FATAL: Cannot download IRS revocation ZIP. Status: ", httr::status_code(resp))
  }
  cat("ZIP downloaded:", round(file.size(zip_file) / 1e6, 1), "MB\n")

  # Unzip
  txt_file <- unzip(zip_file, exdir = data_dir)
  cat("Unzipped:", txt_file, "\n")

  # Read pipe-delimited text (no header row)
  col_names <- c("ein", "org_name", "sort_name", "address", "city", "state",
                 "zip_code", "country", "subsection_code", "revocation_date",
                 "revocation_posting_date", "reinstatement_date")

  revocations_raw <- fread(
    txt_file[1],
    sep = "|",
    header = FALSE,
    col.names = col_names,
    encoding = "Latin-1",
    fill = TRUE
  )

  # Remove trailing empty column if present (trailing |)
  if (ncol(revocations_raw) > 12) {
    revocations_raw <- revocations_raw[, 1:12]
  }

  fwrite(revocations_raw, revocation_file)
  cat("Revocation list saved:", nrow(revocations_raw), "rows\n")
} else {
  revocations_raw <- fread(revocation_file, encoding = "Latin-1")
  cat("Loaded cached revocation list:", nrow(revocations_raw), "rows\n")
}

cat("Revocation list rows:", nrow(revocations_raw), "\n")
stopifnot("Revocation list has fewer than 100K rows — likely wrong file" = nrow(revocations_raw) > 100000)

# ============================================================================
# 2. IRS Exempt Organizations Business Master File (EO BMF)
# ============================================================================
cat("\n=== Fetching IRS EO BMF ===\n")
bmf_file <- file.path(data_dir, "eo_bmf.csv")

if (!file.exists(bmf_file)) {
  # EO BMF is published as regional files; download all 4 regions
  regions <- c("1", "2", "3", "4")
  bmf_parts <- list()

  for (region in regions) {
    url <- paste0("https://www.irs.gov/pub/irs-soi/eo", region, ".csv")
    tmp_file <- file.path(data_dir, paste0("eo_bmf_region", region, ".csv"))
    cat("Downloading BMF region", region, "from:", url, "\n")

    resp <- tryCatch(
      httr::GET(url, httr::timeout(180), httr::write_disk(tmp_file, overwrite = TRUE)),
      error = function(e) NULL
    )

    if (is.null(resp) || httr::status_code(resp) != 200 || file.size(tmp_file) < 1000) {
      stop("FATAL: Cannot download EO BMF region ", region, " from ", url)
    }

    bmf_parts[[region]] <- fread(tmp_file, encoding = "Latin-1")
    cat("  Region", region, "rows:", nrow(bmf_parts[[region]]), "\n")
  }

  bmf_all <- rbindlist(bmf_parts, fill = TRUE)
  fwrite(bmf_all, bmf_file)
  cat("Combined BMF rows:", nrow(bmf_all), "\n")
} else {
  bmf_all <- fread(bmf_file, encoding = "Latin-1")
  cat("Loaded cached BMF rows:", nrow(bmf_all), "\n")
}

stopifnot("BMF has fewer than 500K rows" = nrow(bmf_all) > 500000)

# ============================================================================
# 3. IRS SOI County Income Data (charitable deductions)
# ============================================================================
cat("\n=== Fetching IRS SOI County Data ===\n")
soi_dir <- file.path(data_dir, "soi_county")
dir.create(soi_dir, showWarnings = FALSE)

# SOI county data files are published annually
# Download for 2006-2020
soi_years <- 2006:2020

for (yr in soi_years) {
  # File naming convention varies by year
  # Pre-2017: https://www.irs.gov/pub/irs-soi/YYincyallnoagi.csv
  # Post-2017: different naming
  yy <- substr(as.character(yr), 3, 4)

  soi_file <- file.path(soi_dir, paste0("soi_county_", yr, ".csv"))
  if (file.exists(soi_file)) {
    cat("SOI", yr, "already cached.\n")
    next
  }

  # Try multiple URL patterns
  urls <- c(
    paste0("https://www.irs.gov/pub/irs-soi/", yy, "incyallnoagi.csv"),
    paste0("https://www.irs.gov/pub/irs-soi/", yy, "cy1allnoagi.csv"),
    paste0("https://www.irs.gov/pub/irs-soi/", yy, "incyallagi.csv")
  )

  downloaded <- FALSE
  for (url in urls) {
    resp <- tryCatch(
      httr::GET(url, httr::timeout(120), httr::write_disk(soi_file, overwrite = TRUE)),
      error = function(e) NULL
    )
    if (!is.null(resp) && httr::status_code(resp) == 200 && file.size(soi_file) > 1000) {
      cat("SOI", yr, "downloaded from:", url, "\n")
      downloaded <- TRUE
      break
    }
  }

  if (!downloaded) {
    cat("WARNING: SOI county data for", yr, "not found at standard URLs. Skipping.\n")
    file.remove(soi_file)
  }
}

# ============================================================================
# 4. Census QWI — NAICS 813 (Nonprofit employment)
# ============================================================================
cat("\n=== Fetching QWI NAICS 813 Data ===\n")
qwi_file <- file.path(data_dir, "qwi_naics813.csv")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  stop("FATAL: CENSUS_API_KEY not set in .env")
}

if (!file.exists(qwi_file)) {
  # QWI: fetch state-by-state, year-by-year (multi-year requests return 400)
  # NAICS 813 = Religious, Grantmaking, Civic, Professional, and Similar Organizations
  all_states <- formatC(c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56), width = 2, flag = "0")
  # Exclude DC (11) which has known parsing issues
  all_states <- setdiff(all_states, "11")

  qwi_parts <- list()
  idx <- 0

  for (st in all_states) {
    for (yr in 2006:2020) {
      url <- paste0(
        "https://api.census.gov/data/timeseries/qwi/se?",
        "get=Emp,EarnS&",
        "for=county:*&",
        "in=state:", st, "&",
        "industry=813&",
        "year=", yr, "&",
        "quarter=1&",
        "ownercode=A05&",
        "sex=0&agegrp=A00&race=A0&ethnicity=A0&education=E0&",
        "key=", census_key
      )

      resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)

      if (is.null(resp) || httr::status_code(resp) != 200) next

      content <- httr::content(resp, as = "text", encoding = "UTF-8")
      if (nchar(content) < 10) next

      parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
      if (is.null(parsed) || nrow(parsed) < 2) next

      df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
      names(df) <- parsed[1, ]
      df$state_fips <- st
      df$year <- yr
      idx <- idx + 1
      qwi_parts[[idx]] <- df

      Sys.sleep(0.2)
    }
    cat("QWI state:", st, "done\n")
  }

  if (length(qwi_parts) == 0) {
    stop("FATAL: No QWI data retrieved for any state")
  }

  qwi_all <- rbindlist(qwi_parts, fill = TRUE)
  fwrite(qwi_all, qwi_file)
  cat("QWI total rows:", nrow(qwi_all), "\n")
} else {
  qwi_all <- fread(qwi_file)
  cat("Loaded cached QWI rows:", nrow(qwi_all), "\n")
}

# ============================================================================
# 5. Census County Population Estimates
# ============================================================================
cat("\n=== Fetching County Population Estimates ===\n")
pop_file <- file.path(data_dir, "county_population.csv")

if (!file.exists(pop_file)) {
  pop_parts <- list()

  # 2000s intercensal estimates (covers 2006-2009)
  url_00s <- "https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/county/co-est00int-tot.csv"
  tmp_00s <- file.path(data_dir, "pop_00s.csv")
  resp <- httr::GET(url_00s, httr::timeout(120), httr::write_disk(tmp_00s, overwrite = TRUE))

  if (httr::status_code(resp) == 200 && file.size(tmp_00s) > 1000) {
    pop_00s <- fread(tmp_00s, encoding = "Latin-1")
    names(pop_00s) <- tolower(names(pop_00s))
    cat("2000s intercensal file loaded:", nrow(pop_00s), "rows\n")

    # Build FIPS and reshape years
    pop_year_cols <- grep("^popestimate", names(pop_00s), value = TRUE)
    if (length(pop_year_cols) > 0) {
      pop_00s_long <- pop_00s %>%
        as_tibble() %>%
        mutate(
          county_fips = paste0(
            str_pad(as.character(state), 2, pad = "0"),
            str_pad(as.character(county), 3, pad = "0")
          )
        ) %>%
        filter(county != 0) %>%
        select(county_fips, all_of(pop_year_cols)) %>%
        pivot_longer(cols = all_of(pop_year_cols), names_to = "year_col", values_to = "population") %>%
        mutate(year = as.integer(gsub("popestimate", "", year_col))) %>%
        filter(year >= 2006, year <= 2010) %>%
        select(county_fips, year, population)

      pop_parts[["00s"]] <- pop_00s_long
      cat("2000s intercensal years:", sort(unique(pop_00s_long$year)), "\n")
    }
  } else {
    cat("WARNING: 2000s intercensal download failed\n")
  }

  # 2010s estimates (covers 2010-2020)
  url_10s <- "https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/counties/totals/co-est2020-alldata.csv"
  tmp_10s <- file.path(data_dir, "pop_10s.csv")
  resp <- httr::GET(url_10s, httr::timeout(120), httr::write_disk(tmp_10s, overwrite = TRUE))

  if (httr::status_code(resp) == 200 && file.size(tmp_10s) > 1000) {
    pop_10s <- fread(tmp_10s, encoding = "Latin-1")
    names(pop_10s) <- tolower(names(pop_10s))
    cat("2010s estimates file loaded:", nrow(pop_10s), "rows\n")

    pop_year_cols <- grep("^popestimate", names(pop_10s), value = TRUE)
    if (length(pop_year_cols) > 0) {
      pop_10s_long <- pop_10s %>%
        as_tibble() %>%
        mutate(
          county_fips = paste0(
            str_pad(as.character(state), 2, pad = "0"),
            str_pad(as.character(county), 3, pad = "0")
          )
        ) %>%
        filter(county != 0) %>%
        select(county_fips, all_of(pop_year_cols)) %>%
        pivot_longer(cols = all_of(pop_year_cols), names_to = "year_col", values_to = "population") %>%
        mutate(year = as.integer(gsub("popestimate", "", year_col))) %>%
        filter(year >= 2010, year <= 2020) %>%
        select(county_fips, year, population)

      pop_parts[["10s"]] <- pop_10s_long
      cat("2010s estimate years:", sort(unique(pop_10s_long$year)), "\n")
    }
  } else {
    cat("WARNING: 2010s estimates download failed\n")
  }

  if (length(pop_parts) == 0) {
    stop("FATAL: No population data retrieved")
  }

  pop_all <- rbindlist(pop_parts, fill = TRUE) %>% as_tibble()
  # Remove duplicates (2010 might appear in both)
  pop_all <- pop_all %>% distinct(county_fips, year, .keep_all = TRUE)
  fwrite(pop_all, pop_file)
  cat("Population total rows:", nrow(pop_all), "\n")
} else {
  pop_all <- fread(pop_file)
  cat("Loaded cached population rows:", nrow(pop_all), "\n")
}

cat("\n=== All data fetched successfully ===\n")
