# =============================================================================
# 01_fetch_data.R — Fetch treatment and outcome data
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
UA <- "APEP-Research/1.0 (scl@econ.uzh.ch)"

# Load env vars
env_file <- normalizePath(file.path("..", "..", "..", "..", ".env"), mustWork = TRUE)
env_lines <- readLines(env_file, warn = FALSE)
env_vars <- list()
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  eq <- regexpr("=", line, fixed = TRUE)
  if (eq > 0) {
    key <- substr(line, 1, eq - 1)
    val <- substr(line, eq + 1, nchar(line))
    val <- gsub("^[\"']|[\"']$", "", val)
    env_vars[[key]] <- val
  }
}

# =============================================================================
# PART 1: QWI from Azure — county × quarter × sector employment
# =============================================================================
cat("=== Querying QWI from Azure ===\n")

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET az1 (TYPE azure, CONNECTION_STRING '%s');",
                        env_vars[["AZURE_STORAGE_CONNECTION_STRING"]]))
cat("  Azure connected\n")

qwi_query <- "
  SELECT
    geography AS county_fips,
    year,
    quarter,
    industry,
    Emp,
    EmpEnd,
    HirA,
    HirN,
    Sep,
    EarnS,
    FrmJbGn,
    FrmJbLs
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry IN ('21', '22', '23', '31-33', '44-45', '72', '00')
    AND year >= 2018
    AND sex = 0
    AND agegrp = 'A00'
  ORDER BY county_fips, year, quarter, industry
"

cat("  Running QWI query...\n")
qwi_dt <- as.data.table(dbGetQuery(con, qwi_query))
cat(sprintf("  QWI: %s rows, %d counties, years %d-%d\n",
            format(nrow(qwi_dt), big.mark = ","),
            uniqueN(qwi_dt$county_fips),
            min(qwi_dt$year), max(qwi_dt$year)))

stopifnot("QWI empty" = nrow(qwi_dt) > 0)
dbDisconnect(con, shutdown = TRUE)

# Separate total employment (industry 00) from sectors
qwi_total <- qwi_dt[industry == "00", .(county_fips, year, quarter,
                                          total_emp = Emp, total_emp_end = EmpEnd)]
qwi_sectors <- qwi_dt[industry != "00"]

# Fossil fuel employment share: Mining (21) / Total (00)
mining_emp <- qwi_sectors[industry == "21", .(county_fips, year, quarter, mining_emp = Emp)]
mining_share <- merge(mining_emp, qwi_total, by = c("county_fips", "year", "quarter"))
mining_share[, ff_emp_share := mining_emp / total_emp]

# Annual average (2018-2022) for predetermined fossil fuel criterion
ff_share_annual <- mining_share[year %in% 2018:2022 & !is.na(ff_emp_share),
  .(ff_emp_share = mean(ff_emp_share, na.rm = TRUE),
    avg_mining_emp = mean(mining_emp, na.rm = TRUE),
    avg_total_emp = mean(total_emp, na.rm = TRUE)),
  by = county_fips
]

n_above <- sum(ff_share_annual$ff_emp_share >= 0.0017, na.rm = TRUE)
cat(sprintf("  Counties above 0.17%% FF threshold: %d\n", n_above))

# Save QWI
arrow::write_parquet(qwi_sectors, file.path(DATA_DIR, "qwi_sectors.parquet"))
arrow::write_parquet(qwi_total, file.path(DATA_DIR, "qwi_total.parquet"))
fwrite(ff_share_annual, file.path(DATA_DIR, "ff_employment_share.csv"))

# =============================================================================
# PART 2: County unemployment from FRED (only for FF-threshold counties)
# =============================================================================
cat("\n=== Fetching county unemployment from FRED ===\n")

fred_key <- env_vars[["FRED_API_KEY"]]
stopifnot("FRED_API_KEY missing" = !is.null(fred_key) && nchar(fred_key) > 0)

# Only need unemployment for counties above the FF threshold
ff_counties <- ff_share_annual[ff_emp_share >= 0.0017]$county_fips
cat(sprintf("  Fetching FRED annual unemployment for %d counties...\n", length(ff_counties)))

# FRED annual series: LAUCN{5-digit FIPS}0000000003A
fred_results <- list()
errors <- 0
for (i in seq_along(ff_counties)) {
  fips <- ff_counties[i]
  series_id <- sprintf("LAUCN%05d0000000003A", fips)
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2018-01-01&observation_end=2024-12-31",
    series_id, fred_key
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(15), httr::user_agent(UA)),
                   error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    json <- httr::content(resp, "parsed")
    if (!is.null(json$observations) && length(json$observations) > 0) {
      for (obs in json$observations) {
        if (obs$value != ".") {
          fred_results[[length(fred_results) + 1]] <- list(
            county_fips = fips,
            year = as.integer(substr(obs$date, 1, 4)),
            unemp_rate = as.numeric(obs$value)
          )
        }
      }
    }
  } else {
    errors <- errors + 1
  }
  if (i %% 100 == 0) {
    cat(sprintf("    %d/%d counties (%d errors, %d observations)...\n",
                i, length(ff_counties), errors, length(fred_results)))
    Sys.sleep(0.5)
  }
}

stopifnot("FRED returned no unemployment data" = length(fred_results) > 100)

unemp_dt <- rbindlist(fred_results)
cat(sprintf("  FRED: %d county-year observations for %d counties\n",
            nrow(unemp_dt), uniqueN(unemp_dt$county_fips)))

fwrite(unemp_dt, file.path(DATA_DIR, "county_unemployment.csv"))

# =============================================================================
# PART 3: National unemployment rate
# =============================================================================
nat_unemp <- data.table(
  year = 2018:2024,
  national_unemp_rate = c(3.9, 3.7, 8.1, 5.3, 3.6, 3.6, 4.0)
)
fwrite(nat_unemp, file.path(DATA_DIR, "national_unemployment.csv"))

# =============================================================================
# Summary
# =============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("  QWI sectors: %s rows, %d counties\n",
            format(nrow(qwi_sectors), big.mark = ","), uniqueN(qwi_sectors$county_fips)))
cat(sprintf("  FF threshold counties: %d\n", n_above))
cat(sprintf("  Unemployment data: %d county-years (%d counties)\n",
            nrow(unemp_dt), uniqueN(unemp_dt$county_fips)))
cat("\nData fetch complete.\n")
