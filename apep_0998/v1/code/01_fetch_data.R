# =============================================================================
# 01_fetch_data.R — Fetch USAID contract data and QWI employment data
# apep_0998: USAID contract terminations and local employment
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

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

# ---------------------------------------------------------------------------
# 1. Fetch USASpending USAID contract data
# ---------------------------------------------------------------------------
cat("=== Fetching USAID contract data from USASpending API ===\n")

base_url <- "https://api.usaspending.gov/api/v2/search/spending_by_geography/"

fetch_usaid_by_county <- function(fiscal_year, scope = "place_of_performance") {
  cat(sprintf("  Fetching %s FY%d...\n", scope, fiscal_year))
  body <- list(
    scope = scope,
    geo_layer = "county",
    filters = list(
      time_period = list(list(
        start_date = sprintf("%d-10-01", fiscal_year - 1),
        end_date = sprintf("%d-09-30", fiscal_year)
      )),
      award_type_codes = c("A", "B", "C", "D"),
      agencies = list(list(
        type = "awarding",
        tier = "toptier",
        name = "Agency for International Development"
      ))
    )
  )

  resp <- httr::POST(
    url = base_url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(120)
  )

  if (httr::status_code(resp) != 200) {
    stop(sprintf("USASpending API returned status %d for FY%d",
                 httr::status_code(resp), fiscal_year))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)

  if (is.null(parsed$results) || length(parsed$results) == 0) {
    stop(sprintf("No results returned for FY%d — cannot proceed without real data", fiscal_year))
  }

  results <- as_tibble(parsed$results)
  results$fiscal_year <- fiscal_year
  results$scope <- scope

  cat(sprintf("    Got %d county records, $%.1fM total\n",
              nrow(results), sum(as.numeric(results$aggregated_amount), na.rm = TRUE) / 1e6))
  return(results)
}

# Fetch by place of performance (FY2022-2024)
usaid_perf <- bind_rows(lapply(2022:2024, function(y) fetch_usaid_by_county(y, "place_of_performance")))

# Fetch by recipient location (where contractor HQ is)
usaid_recip <- bind_rows(lapply(2022:2024, function(y) fetch_usaid_by_county(y, "recipient_location")))

stopifnot("No USAID performance data" = nrow(usaid_perf) > 0)
stopifnot("No USAID recipient data" = nrow(usaid_recip) > 0)

cat(sprintf("\nUSAID performance: %d records, %d counties\n",
            nrow(usaid_perf), n_distinct(usaid_perf$shape_code)))
cat(sprintf("USAID recipient: %d records, %d counties\n",
            nrow(usaid_recip), n_distinct(usaid_recip$shape_code)))

saveRDS(usaid_perf, file.path(DATA_DIR, "usaid_performance.rds"))
saveRDS(usaid_recip, file.path(DATA_DIR, "usaid_recipient.rds"))

# ---------------------------------------------------------------------------
# 2. Fetch QWI data from Azure
# ---------------------------------------------------------------------------
cat("\n=== Querying QWI from Azure ===\n")

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET az1 (TYPE azure, CONNECTION_STRING '%s');",
                        env_vars[["AZURE_STORAGE_CONNECTION_STRING"]]))
cat("  Azure connected\n")

# NAICS sectors: 54 (Professional Services), 72 (Accommodation/Food),
# 44-45 (Retail), 31-33 (Manufacturing, placebo), 00 (Total)
qwi_query <- "
  SELECT
    geography AS county_fips,
    year,
    quarter,
    industry AS naics,
    Emp AS emp,
    EmpEnd AS emp_end,
    HirA AS hira,
    HirN AS hirn,
    Sep AS sep,
    EarnS AS earns,
    FrmJbGn AS firm_job_gain,
    FrmJbLs AS firm_job_loss
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry IN ('54', '72', '44-45', '31-33', '00')
    AND year >= 2015
    AND year <= 2025
    AND sex = 0
    AND agegrp = 'A00'
  ORDER BY county_fips, year, quarter, industry
"

cat("  Running QWI query (may take a few minutes)...\n")
qwi_dt <- as.data.table(dbGetQuery(con, qwi_query))

stopifnot("QWI query returned no data" = nrow(qwi_dt) > 0)

cat(sprintf("  QWI: %s rows, %d counties, years %d-%d\n",
            format(nrow(qwi_dt), big.mark = ","),
            uniqueN(qwi_dt$county_fips),
            min(qwi_dt$year), max(qwi_dt$year)))

cat(sprintf("  Industries: %s\n", paste(sort(unique(qwi_dt$naics)), collapse = ", ")))

# Check data coverage by year-quarter
cat("  Coverage by year:\n")
print(qwi_dt[, .(counties = uniqueN(county_fips), total_emp = sum(emp, na.rm = TRUE)),
              by = .(year, quarter)][order(year, quarter)])

dbDisconnect(con, shutdown = TRUE)

saveRDS(qwi_dt, file.path(DATA_DIR, "qwi_raw.rds"))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("USAID performance: %d records across %d counties\n",
            nrow(usaid_perf), n_distinct(usaid_perf$shape_code)))
cat(sprintf("USAID recipient: %d records across %d counties\n",
            nrow(usaid_recip), n_distinct(usaid_recip$shape_code)))
cat(sprintf("QWI: %s records, %d counties, %d-%d\n",
            format(nrow(qwi_dt), big.mark = ","),
            uniqueN(qwi_dt$county_fips),
            min(qwi_dt$year), max(qwi_dt$year)))
