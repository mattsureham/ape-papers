# 01_fetch_data.R — Download FCC ULS cellular license data + County Business Patterns
# apep_0660: FCC Cellular Lottery and Local Economic Development

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. FCC ULS Cellular License Data
# ==============================================================================
cat("=== Downloading FCC ULS cellular license data ===\n")

fcc_zip <- file.path(data_dir, "l_cell.zip")
if (!file.exists(fcc_zip)) {
  download.file(
    "https://data.fcc.gov/download/pub/uls/complete/l_cell.zip",
    fcc_zip, mode = "wb", quiet = FALSE
  )
}
stopifnot("FCC download failed" = file.exists(fcc_zip) && file.size(fcc_zip) > 1e6)

# Extract HD.dat and MK.dat
unzip(fcc_zip, files = c("HD.dat", "MK.dat"), exdir = data_dir, overwrite = TRUE)
stopifnot("HD.dat missing" = file.exists(file.path(data_dir, "HD.dat")))
stopifnot("MK.dat missing" = file.exists(file.path(data_dir, "MK.dat")))
cat("FCC ULS files extracted successfully\n")

# ==============================================================================
# 2. County Business Patterns — Direct CSV Downloads (1986-1997)
# ==============================================================================
cat("\n=== Downloading CBP county data (direct files) ===\n")

# Census FTP hosts annual CBP files. Pre-1998 uses SIC codes.
# Files are at: https://www2.census.gov/programs-surveys/cbp/datasets/{year}/

fetch_cbp_direct <- function(year) {
  cat(sprintf("  Fetching CBP %d (direct)...\n", year))

  yy <- sprintf("%02d", year %% 100)

  # Try multiple URL patterns
  urls_to_try <- c(
    sprintf("https://www2.census.gov/programs-surveys/cbp/datasets/%d/cbp%sco.txt", year, yy),
    sprintf("https://www2.census.gov/programs-surveys/cbp/datasets/%d/cbp%sco.zip", year, yy),
    sprintf("https://www2.census.gov/programs-surveys/cbp/datasets/%d/CBP%sCO.txt", year, yy)
  )

  for (url in urls_to_try) {
    local_file <- file.path(data_dir, basename(url))
    if (!file.exists(local_file)) {
      dl_ok <- tryCatch({
        download.file(url, local_file, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) FALSE)
    } else {
      dl_ok <- TRUE
    }

    if (dl_ok && file.exists(local_file) && file.size(local_file) > 1000) {
      # If zip, extract
      if (grepl("\\.zip$", local_file)) {
        txt_name <- gsub("\\.zip$", ".txt", basename(local_file))
        unzip(local_file, exdir = data_dir, overwrite = TRUE)
        local_file <- file.path(data_dir, txt_name)
        if (!file.exists(local_file)) {
          # Try uppercase
          txt_files <- list.files(data_dir, pattern = sprintf("cbp%sco", yy), ignore.case = TRUE)
          if (length(txt_files) > 0) local_file <- file.path(data_dir, txt_files[1])
        }
      }

      if (file.exists(local_file) && file.size(local_file) > 1000) {
        # Read the file — format varies by year
        dat <- tryCatch({
          # Try comma-delimited first (most years)
          d <- read.csv(local_file, stringsAsFactors = FALSE, colClasses = "character")
          names(d) <- toupper(names(d))
          d
        }, error = function(e) {
          # Try fixed-width or tab-delimited
          tryCatch({
            d <- read.delim(local_file, stringsAsFactors = FALSE, colClasses = "character")
            names(d) <- toupper(names(d))
            d
          }, error = function(e2) NULL)
        })

        if (!is.null(dat) && nrow(dat) > 0) {
          cat(sprintf("    Downloaded %d: %d rows, cols: %s\n",
                      year, nrow(dat), paste(head(names(dat), 8), collapse = ", ")))

          # Standardize column names across years
          # FIPSTATE, FIPSCTY (or FIPST, FIPSCNTY, or STATE, COUNTY)
          # EMP, EST (or ESTAB), AP (annual payroll)
          # SIC (industry code)

          # Find FIPS columns
          st_col <- intersect(names(dat), c("FIPSTATE", "FIPST", "STATE"))[1]
          cty_col <- intersect(names(dat), c("FIPSCTY", "FIPSCNTY", "COUNTY"))[1]
          emp_col <- intersect(names(dat), c("EMP", "EMPL"))[1]
          est_col <- intersect(names(dat), c("EST", "ESTAB"))[1]
          pay_col <- intersect(names(dat), c("AP", "PAYANN"))[1]
          sic_col <- intersect(names(dat), c("SIC", "NAICS"))[1]

          if (!is.na(st_col) && !is.na(cty_col)) {
            out <- data.frame(
              state = trimws(dat[[st_col]]),
              county = trimws(dat[[cty_col]]),
              stringsAsFactors = FALSE
            )
            out$fips <- paste0(
              sprintf("%02s", out$state),
              sprintf("%03s", out$county)
            )

            if (!is.na(emp_col)) out$emp <- as.integer(gsub("[^0-9]", "", dat[[emp_col]]))
            if (!is.na(est_col)) out$estab <- as.integer(gsub("[^0-9]", "", dat[[est_col]]))
            if (!is.na(pay_col)) out$payann <- as.numeric(gsub("[^0-9.]", "", dat[[pay_col]]))
            if (!is.na(sic_col)) out$sic <- trimws(dat[[sic_col]])

            # Filter to total (all industries) — SIC = "--" or "----" or "0" or missing
            if ("sic" %in% names(out)) {
              total_rows <- out %>%
                filter(sic %in% c("--", "----", "0", "", "00") | is.na(sic))
              if (nrow(total_rows) > 100) {
                out <- total_rows
              } else {
                # Some years use different total codes; take the one with most rows
                sic_counts <- table(out$sic)
                total_sic <- names(which.max(sic_counts))
                out <- out %>% filter(sic == total_sic)
              }
            }

            # Filter to county-level (county != "000" or "999")
            out <- out %>%
              filter(county != "000" & county != "999") %>%
              filter(nchar(fips) == 5)

            out$year <- year
            out <- out[, intersect(names(out), c("fips", "state", "county", "year", "emp", "estab", "payann"))]

            cat(sprintf("    Parsed: %d counties for %d\n", nrow(out), year))
            return(out)
          }
        }
      }
    }
  }

  cat(sprintf("    FAILED for %d\n", year))
  return(NULL)
}

# Fetch 1986-1997 via direct download
cbp_direct_list <- list()
for (yr in 1986:1997) {
  result <- fetch_cbp_direct(yr)
  if (!is.null(result) && nrow(result) > 0) {
    cbp_direct_list[[as.character(yr)]] <- result
  }
  Sys.sleep(0.3)
}

cbp_direct <- bind_rows(cbp_direct_list)
cat(sprintf("\nDirect download CBP: %d county-years across %d years\n",
            nrow(cbp_direct), n_distinct(cbp_direct$year)))

# ==============================================================================
# 3. CBP via Census API (1998-2005)
# ==============================================================================
cat("\n=== Downloading CBP via Census API (1998-2005) ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) census_key <- Sys.getenv("CENSUS_KEY")

fetch_cbp_api <- function(year) {
  cat(sprintf("  Fetching CBP %d (API)...\n", year))

  base_url <- sprintf("https://api.census.gov/data/%d/cbp", year)

  # Determine NAICS parameter
  naics_param <- if (year >= 2017) {
    list(NAICS2017 = "00")
  } else if (year >= 2012) {
    list(NAICS2012 = "00")
  } else if (year >= 2008) {
    list(NAICS2007 = "00")
  } else if (year >= 2003) {
    list(NAICS2002 = "00")
  } else {
    list(NAICS1997 = "00")
  }

  params <- c(
    list(get = "ESTAB,EMP,PAYANN", `for` = "county:*"),
    naics_param
  )
  if (nchar(census_key) > 0) params$key <- census_key

  resp <- tryCatch(
    GET(base_url, query = params, timeout(120)),
    error = function(e) NULL
  )

  if (is.null(resp) || status_code(resp) != 200) {
    cat(sprintf("    Failed (status: %s)\n",
                if (!is.null(resp)) status_code(resp) else "NULL"))
    return(NULL)
  }

  raw <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)
  header <- parsed[1, ]
  dat <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(dat) <- header

  dat$year <- year
  dat$fips <- paste0(dat$state, dat$county)
  dat$estab <- as.integer(dat$ESTAB)
  dat$emp <- as.integer(dat$EMP)
  dat$payann <- as.numeric(dat$PAYANN)
  dat <- dat[, c("fips", "state", "county", "year", "estab", "emp", "payann")]

  cat(sprintf("    %d: %d counties\n", year, nrow(dat)))
  return(dat)
}

cbp_api_list <- list()
for (yr in 1998:2005) {
  result <- fetch_cbp_api(yr)
  if (!is.null(result)) cbp_api_list[[as.character(yr)]] <- result
  Sys.sleep(0.5)
}

cbp_api <- bind_rows(cbp_api_list)
cat(sprintf("API CBP: %d county-years across %d years\n",
            nrow(cbp_api), n_distinct(cbp_api$year)))

# ==============================================================================
# 4. Combine all CBP data
# ==============================================================================
cbp_all <- bind_rows(cbp_direct, cbp_api)

# Clean: ensure consistent types
cbp_all <- cbp_all %>%
  mutate(
    emp = as.integer(emp),
    estab = as.integer(estab),
    payann = as.numeric(payann)
  ) %>%
  filter(!is.na(fips) & nchar(fips) == 5 & !is.na(emp))

cat(sprintf("\n=== Combined CBP: %d county-years, %d counties, years %d-%d ===\n",
            nrow(cbp_all), n_distinct(cbp_all$fips),
            min(cbp_all$year), max(cbp_all$year)))
cat("Year distribution:\n")
print(table(cbp_all$year))

saveRDS(cbp_all, file.path(data_dir, "cbp_raw.rds"))

# ==============================================================================
# 5. Sector-level CBP (from direct downloads, SIC era)
# ==============================================================================
cat("\n=== Extracting sector-level CBP ===\n")

# Re-read the 1986-1997 files and extract sector breakdowns
fetch_cbp_sector_direct <- function(year, sic_range, sector_name) {
  yy <- sprintf("%02d", year %% 100)
  local_file <- file.path(data_dir, sprintf("cbp%sco.txt", yy))

  # Check uppercase too
  if (!file.exists(local_file)) {
    files <- list.files(data_dir, pattern = sprintf("cbp%sco", yy), ignore.case = TRUE)
    if (length(files) > 0) local_file <- file.path(data_dir, files[1])
  }

  if (!file.exists(local_file)) return(NULL)

  dat <- tryCatch(
    read.csv(local_file, stringsAsFactors = FALSE, colClasses = "character"),
    error = function(e) NULL
  )
  if (is.null(dat)) return(NULL)
  names(dat) <- toupper(names(dat))

  sic_col <- intersect(names(dat), c("SIC", "NAICS"))[1]
  if (is.na(sic_col)) return(NULL)

  st_col <- intersect(names(dat), c("FIPSTATE", "FIPST", "STATE"))[1]
  cty_col <- intersect(names(dat), c("FIPSCTY", "FIPSCNTY", "COUNTY"))[1]
  emp_col <- intersect(names(dat), c("EMP", "EMPL"))[1]
  est_col <- intersect(names(dat), c("EST", "ESTAB"))[1]

  if (is.na(st_col) || is.na(cty_col) || is.na(emp_col)) return(NULL)

  # Filter to the SIC range (2-digit codes)
  dat_filtered <- dat %>%
    mutate(sic_clean = trimws(.data[[sic_col]])) %>%
    filter(nchar(sic_clean) == 2) %>%
    filter(as.integer(sic_clean) >= sic_range[1] & as.integer(sic_clean) <= sic_range[2])

  if (nrow(dat_filtered) == 0) return(NULL)

  out <- dat_filtered %>%
    mutate(
      fips = paste0(sprintf("%02s", trimws(.data[[st_col]])),
                    sprintf("%03s", trimws(.data[[cty_col]]))),
      emp = as.integer(gsub("[^0-9]", "", .data[[emp_col]])),
      estab = if (!is.na(est_col)) as.integer(gsub("[^0-9]", "", .data[[est_col]])) else NA_integer_
    ) %>%
    filter(nchar(fips) == 5 & .data[[cty_col]] != "000") %>%
    group_by(fips) %>%
    summarize(emp = sum(emp, na.rm = TRUE),
              estab = sum(estab, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(year = year, sector = sector_name)

  return(out)
}

sector_defs <- list(
  manufacturing = c(20, 39),
  retail = c(52, 59),
  fire = c(60, 67),
  services = c(70, 89)
)

sector_list <- list()
for (yr in c(1988, 1990, 1993, 1996)) {
  for (sec_name in names(sector_defs)) {
    result <- fetch_cbp_sector_direct(yr, sector_defs[[sec_name]], sec_name)
    if (!is.null(result) && nrow(result) > 0) {
      sector_list[[paste(yr, sec_name)]] <- result
      cat(sprintf("  %d %s: %d counties\n", yr, sec_name, nrow(result)))
    }
  }
}

sector_raw <- bind_rows(sector_list)
cat(sprintf("Sector CBP: %d county-year-sector observations\n", nrow(sector_raw)))
saveRDS(sector_raw, file.path(data_dir, "sector_raw.rds"))

# ==============================================================================
# 6. Download CBSA delineation for crosswalk
# ==============================================================================
cat("\n=== Downloading CBSA delineation ===\n")

cbsa_file <- file.path(data_dir, "cbsa_delineation.csv")
if (!file.exists(cbsa_file) || file.size(cbsa_file) < 100) {
  # Try multiple sources
  urls <- c(
    "https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2023/delineation-files/list1_2023.csv",
    "https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2020/delineation-files/list1_2020.csv"
  )
  for (url in urls) {
    tryCatch({
      download.file(url, cbsa_file, quiet = TRUE)
      if (file.size(cbsa_file) > 100) break
    }, error = function(e) NULL)
  }
}

if (file.exists(cbsa_file) && file.size(cbsa_file) > 100) {
  cat("CBSA delineation downloaded\n")
} else {
  cat("CBSA delineation download failed — will construct crosswalk from data\n")
}

cat("\n=== Data fetch complete ===\n")
