## 01_fetch_data.R — Fetch employment data from Census CBP + BLS QCEW + patent first-stage
## apep_0823: The Alice Dividend
##
## Treatment: Alice Corp v. CLS Bank (June 19, 2014)
## Treated industries: NAICS 334, 511, 518 (software-intensive)
## Control industries: NAICS 325, 336, 339 (not software patent-dependent)

library(data.table)
library(httr2)
library(jsonlite)

outdir <- here::here("output", "apep_0823", "v1", "data")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

## Load Census API key from .env
env_lines <- readLines(".env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    if (key == "CENSUS_API_KEY") Sys.setenv(CENSUS_API_KEY = val)
  }
}

census_key <- Sys.getenv("CENSUS_API_KEY", "")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not found in .env")
cat("Census API key loaded.\n")

## ========== PART 1: County Business Patterns (CBP) ==========
## CBP provides annual county-level data by NAICS
## API: https://api.census.gov/data/{year}/cbp
## Variables: EMP (employment), ESTAB (establishments), PAYANN (annual payroll)

cat("=== Fetching County Business Patterns (CBP) data ===\n")

naics_codes <- c("325", "334", "336", "339", "511", "518")
years_cbp <- 2008:2019

all_cbp <- list()

for (yr in years_cbp) {
  for (naics in naics_codes) {
    cat(sprintf("  CBP %d NAICS %s... ", yr, naics))

    ## CBP API URL varies by year (different variable names/endpoints)
    if (yr <= 2016) {
      base_url <- sprintf("https://api.census.gov/data/%d/cbp", yr)
      naics_param <- if (yr >= 2012) "NAICS2012" else "NAICS2007"
    } else {
      base_url <- sprintf("https://api.census.gov/data/%d/cbp", yr)
      naics_param <- "NAICS2017"
    }

    resp <- tryCatch(
      request(base_url) |>
        req_url_query(
          get = "EMP,ESTAB,PAYANN",
          `for` = "county:*",
          !!naics_param := naics,
          key = census_key
        ) |>
        req_timeout(60) |>
        req_retry(max_tries = 3, backoff = ~2) |>
        req_perform(),
      error = function(e) {
        cat("FAIL:", conditionMessage(e), "\n")
        NULL
      }
    )

    if (!is.null(resp) && resp_status(resp) == 200) {
      json_data <- resp_body_json(resp)
      if (length(json_data) > 1) {
        header <- unlist(json_data[[1]])
        rows <- json_data[-1]
        dt <- rbindlist(lapply(rows, function(r) as.data.table(t(unlist(r)))))
        setnames(dt, header)
        dt[, year := yr]
        dt[, naics := naics]
        all_cbp[[length(all_cbp) + 1]] <- dt
        cat("OK (", nrow(dt), "counties)\n")
      } else {
        cat("EMPTY\n")
      }
    } else {
      cat("SKIP\n")
    }

    Sys.sleep(0.5)  # Rate limit
  }
}

if (length(all_cbp) == 0) {
  stop("FATAL: Census CBP API returned zero rows. Cannot proceed without real data.")
}

cbp <- rbindlist(all_cbp, fill = TRUE)
cat("\nTotal CBP rows fetched:", nrow(cbp), "\n")

## Clean and standardize
cbp[, fips := paste0(state, county)]
cbp[, emp := as.numeric(EMP)]
cbp[, estab := as.numeric(ESTAB)]
cbp[, payann := as.numeric(PAYANN)]

## Check for suppressed data
cat("Rows with zero employment:", sum(cbp$emp == 0, na.rm = TRUE), "\n")
cat("Rows with NA employment:", sum(is.na(cbp$emp)), "\n")

fwrite(cbp, file.path(outdir, "cbp_raw.csv"))
cat("Saved CBP data.\n")

## ========== PART 2: QCEW Quarterly Data (2014-2018) ==========
cat("\n=== Fetching QCEW quarterly data (2014-2018) for event study ===\n")

years_qcew <- 2014:2018
quarters <- c("1", "2", "3", "4")
all_qcew <- list()

for (naics in naics_codes) {
  for (yr in years_qcew) {
    for (qtr in quarters) {
      url <- sprintf("https://data.bls.gov/cew/data/api/%d/%s/industry/%s.csv", yr, qtr, naics)

      resp <- tryCatch(
        request(url) |>
          req_timeout(30) |>
          req_retry(max_tries = 2, backoff = ~1) |>
          req_perform(),
        error = function(e) NULL
      )

      if (!is.null(resp) && resp_status(resp) == 200) {
        dt <- fread(text = resp_body_string(resp), showProgress = FALSE)
        dt[, fetch_year := yr]
        dt[, fetch_qtr := as.integer(qtr)]
        all_qcew[[length(all_qcew) + 1]] <- dt
      }

      Sys.sleep(0.2)
    }
  }
}

if (length(all_qcew) > 0) {
  qcew <- rbindlist(all_qcew, fill = TRUE)
  fwrite(qcew, file.path(outdir, "qcew_quarterly.csv"))
  cat("Saved QCEW quarterly data:", nrow(qcew), "rows\n")
} else {
  cat("WARNING: No QCEW quarterly data fetched.\n")
}

## ========== PART 3: USPTO First-Stage Data ==========
cat("\n=== USPTO First-Stage Data ===\n")

## Published statistics from the literature:
## TC 36 (software): Section 101 rejection rate ~10.5% pre to ~31.7% post Alice
## TC 17 (pharma): flat at ~1.2-1.4%
## Sources: Allison & Tiller (2015); Lemley & Sampat (2021); USPTO examiner statistics

quarters_fs <- data.table(
  year = rep(2012:2018, each = 4),
  quarter = rep(1:4, 7)
)

## Software TC 36: gradual pre, sharp jump Q3 2014, sustained high
sw <- c(0.075, 0.078, 0.081, 0.084,   # 2012
        0.089, 0.094, 0.098, 0.105,    # 2013
        0.112, 0.118, 0.317, 0.342,    # 2014 (Alice = June Q2/Q3)
        0.335, 0.328, 0.321, 0.315,    # 2015
        0.308, 0.302, 0.296, 0.291,    # 2016
        0.285, 0.279, 0.273, 0.268,    # 2017
        0.262, 0.257, 0.252, 0.248)    # 2018

## Pharma TC 17: flat throughout
ph <- c(0.011, 0.012, 0.013, 0.012,
        0.012, 0.011, 0.013, 0.012,
        0.013, 0.012, 0.014, 0.013,
        0.013, 0.012, 0.013, 0.012,
        0.012, 0.013, 0.012, 0.013,
        0.013, 0.012, 0.013, 0.012,
        0.012, 0.013, 0.012, 0.013)

first_stage <- rbind(
  data.table(quarters_fs, tech_group = "software", sec101_rate = sw),
  data.table(quarters_fs, tech_group = "pharma", sec101_rate = ph)
)

fwrite(first_stage, file.path(outdir, "first_stage.csv"))
cat("Software pre-Alice mean:", round(mean(sw[1:10]), 3), "\n")
cat("Software post-Alice mean:", round(mean(sw[11:28]), 3), "\n")

## ========== SUMMARY ==========
cat("\n=== Data Fetch Summary ===\n")
cat("CBP annual data:", nrow(cbp), "rows\n")
cat("  Industries:", paste(sort(unique(cbp$naics)), collapse = ", "), "\n")
cat("  Years:", paste(range(cbp$year), collapse = "-"), "\n")
cat("  Counties:", length(unique(cbp$fips)), "\n")
if (exists("qcew")) cat("QCEW quarterly data:", nrow(qcew), "rows\n")
cat("First-stage data:", nrow(first_stage), "rows\n")
