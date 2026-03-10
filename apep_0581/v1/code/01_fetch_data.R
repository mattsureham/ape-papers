# 01_fetch_data.R — Fetch E-PRTR facility-level pollution data and Eurostat SBS
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# PART 1: BAT Conclusion Dates (from EU Official Journal — manually coded)
# ============================================================================

bat_conclusions <- data.table(
  bat_sector = c(
    "Iron and Steel Production",
    "Manufacture of Glass",
    "Production of Cement, Lime and Magnesium Oxide",
    "Production of Chlor-alkali",
    "Tanning of Hides and Skins",
    "Production of Pulp, Paper and Board",
    "Refining of Mineral Oil and Gas",
    "Common Waste Water/Gas Treatment",
    "Non-ferrous Metals Industries",
    "Large Combustion Plants",
    "Waste Treatment",
    "Food, Drink and Milk Industries",
    "Waste Incineration"
  ),
  bat_adopted = as.Date(c(
    "2012-03-08",  # 2012/135/EU
    "2012-03-08",  # 2012/134/EU
    "2013-04-09",  # 2013/163/EU
    "2013-12-11",  # 2013/732/EU
    "2013-02-11",  # 2013/84/EU
    "2014-09-26",  # 2014/687/EU
    "2014-10-09",  # 2014/738/EU
    "2016-06-30",  # (EU) 2016/902
    "2016-06-30",  # (EU) 2016/1032
    "2017-08-17",  # (EU) 2017/1442
    "2018-08-10",  # (EU) 2018/1147
    "2019-12-12",  # (EU) 2019/2031
    "2019-12-03"   # (EU) 2019/2010
  ))
)
bat_conclusions[, compliance_deadline := bat_adopted + years(4)]
bat_conclusions[, bat_year := year(bat_adopted)]
bat_conclusions[, compliance_year := year(compliance_deadline)]

fwrite(bat_conclusions, file.path(data_dir, "bat_conclusions.csv"))
cat("BAT conclusion dates saved:", nrow(bat_conclusions), "sectors\n")

# ============================================================================
# PART 2: E-PRTR Facility-Level Pollution Data via DiscoData SQL
# ============================================================================

# The EEA DiscoData endpoint supports SQL queries over the IED database.
# We need two tables joined:
#   [IED].[latest].[PollutantRelease] — emission quantities per facility-report
#   [IED].[latest].[FacilityReport]   — facility metadata (country, year, activity)

cat("\n=== Fetching E-PRTR data via DiscoData SQL ===\n")

fetch_discodata <- function(sql_query, max_pages = 20, hits_per_page = 100000) {
  all_pages <- list()
  for (page in seq_len(max_pages)) {
    url <- paste0(
      "https://discodata.eea.europa.eu/sql?query=",
      URLencode(sql_query, reserved = TRUE),
      "&p=", page,
      "&nrOfHits=", hits_per_page
    )
    cat("  Page", page, "...")

    resp <- tryCatch({
      request(url) |>
        req_timeout(300) |>
        req_perform()
    }, error = function(e) {
      cat(" FAILED:", e$message, "\n")
      NULL
    })

    if (is.null(resp)) break

    body <- tryCatch(resp_body_json(resp), error = function(e) NULL)
    if (is.null(body) || is.null(body$results) || length(body$results) == 0) {
      cat(" empty response.\n")
      break
    }

    page_dt <- rbindlist(body$results, fill = TRUE)
    all_pages[[page]] <- page_dt
    cat(" ", nrow(page_dt), "records\n")

    if (nrow(page_dt) < hits_per_page) break
    Sys.sleep(1)
  }

  if (length(all_pages) == 0) return(NULL)
  rbindlist(all_pages, fill = TRUE)
}

# Step 1: Fetch facility reports (metadata: country, year, activity code)
cat("\nStep 1: Fetching facility reports...\n")
facility_sql <- "SELECT Id, countryCode, reportingYear, mainIAActivityCode, City, PostalCode FROM [IED].[latest].[FacilityReport]"
facility_reports <- fetch_discodata(facility_sql, max_pages = 20)

if (is.null(facility_reports) || nrow(facility_reports) == 0) {
  # Try alternative table name
  cat("Primary query failed. Trying alternative table names...\n")
  alt_queries <- c(
    "SELECT TOP 100000 * FROM [IED].[latest].[FacilityReport]",
    "SELECT TOP 100000 * FROM [EPRTR_V2].[latest].[FacilityReport]",
    "SELECT TOP 100000 * FROM [IED].[latest].[ProductionFacility]"
  )
  for (q in alt_queries) {
    cat("  Trying:", substr(q, 1, 60), "\n")
    facility_reports <- fetch_discodata(q, max_pages = 1)
    if (!is.null(facility_reports) && nrow(facility_reports) > 0) {
      cat("  Success:", nrow(facility_reports), "records\n")
      break
    }
  }
}

if (!is.null(facility_reports) && nrow(facility_reports) > 0) {
  cat("Facility reports:", nrow(facility_reports), "records\n")
  cat("Columns:", paste(names(facility_reports), collapse = ", "), "\n")
  fwrite(facility_reports, file.path(data_dir, "facility_reports_raw.csv"))
}

# Step 2: Fetch pollutant releases
cat("\nStep 2: Fetching pollutant releases...\n")
release_sql <- "SELECT Id, facilityReportId, mediumCode, pollutant, totalPollutantQuantityKg, accidentalPollutantQuantityKg, methodCode FROM [IED].[latest].[PollutantRelease]"
releases <- fetch_discodata(release_sql, max_pages = 20)

if (is.null(releases) || nrow(releases) == 0) {
  alt_release_queries <- c(
    "SELECT TOP 100000 * FROM [IED].[latest].[PollutantRelease]",
    "SELECT TOP 100000 * FROM [EPRTR_V2].[latest].[PollutantRelease]"
  )
  for (q in alt_release_queries) {
    cat("  Trying:", substr(q, 1, 60), "\n")
    releases <- fetch_discodata(q, max_pages = 1)
    if (!is.null(releases) && nrow(releases) > 0) break
  }
}

if (!is.null(releases) && nrow(releases) > 0) {
  cat("Pollutant releases:", nrow(releases), "records\n")
  cat("Columns:", paste(names(releases), collapse = ", "), "\n")
  fwrite(releases, file.path(data_dir, "releases_raw.csv"))
}

# Step 3: Join releases with facility reports
cat("\nStep 3: Joining releases with facility metadata...\n")

if (!is.null(facility_reports) && nrow(facility_reports) > 0 &&
    !is.null(releases) && nrow(releases) > 0) {

  # Identify join key
  release_join_col <- intersect(c("facilityReportId", "FacilityReportId"), names(releases))[1]
  facility_id_col <- intersect(c("Id", "id", "ID"), names(facility_reports))[1]

  if (!is.na(release_join_col) && !is.na(facility_id_col)) {
    eprtr_data <- merge(
      releases,
      facility_reports,
      by.x = release_join_col, by.y = facility_id_col,
      all.x = TRUE
    )
    cat("Joined dataset:", nrow(eprtr_data), "records\n")
  } else {
    cat("Could not identify join keys. Using releases only.\n")
    eprtr_data <- releases
  }
} else if (!is.null(releases) && nrow(releases) > 0) {
  eprtr_data <- releases
} else {
  # Last resort: try the full join query directly
  cat("\nTrying direct JOIN query...\n")
  join_sql <- paste0(
    "SELECT r.Id, r.mediumCode, r.pollutant, r.totalPollutantQuantityKg, ",
    "r.accidentalPollutantQuantityKg, r.methodCode, r.facilityReportId, ",
    "f.countryCode, f.reportingYear, f.mainIAActivityCode ",
    "FROM [IED].[latest].[PollutantRelease] r ",
    "INNER JOIN [IED].[latest].[FacilityReport] f ON r.facilityReportId = f.Id"
  )
  eprtr_data <- fetch_discodata(join_sql, max_pages = 20)
}

# Final check
if (is.null(eprtr_data) || nrow(eprtr_data) == 0) {
  stop("FATAL: Could not fetch E-PRTR facility-level data from any EEA source.\n",
       "Cannot proceed without real facility-level pollution data.\n",
       "Pivot research question or investigate EEA data access.")
}

cat("\n=== E-PRTR data fetched:", nrow(eprtr_data), "records ===\n")
cat("Columns:", paste(names(eprtr_data), collapse = ", "), "\n")
fwrite(eprtr_data, file.path(data_dir, "eprtr_raw.csv"))

# ============================================================================
# PART 3: Eurostat SBS (Structural Business Statistics)
# ============================================================================

cat("\nFetching Eurostat SBS data...\n")

sbs_data <- tryCatch({
  get_eurostat("sbs_na_ind_r2", time_format = "num")
}, error = function(e) {
  cat("SBS failed:", e$message, "\n")
  stop("Could not fetch Eurostat SBS data.")
})

cat("Eurostat SBS data:", nrow(sbs_data), "observations\n")
sbs_dt <- as.data.table(sbs_data)
fwrite(sbs_dt, file.path(data_dir, "eurostat_sbs.csv"))

# ============================================================================
# PART 4: Eurostat Air Emissions Accounts (sector-level backup)
# ============================================================================

cat("\nFetching Eurostat air emissions accounts...\n")

air_emissions <- tryCatch({
  get_eurostat("env_ac_ainah_r2", time_format = "num")
}, error = function(e) {
  cat("Air emissions accounts failed:", e$message, "\n")
  NULL
})

if (!is.null(air_emissions)) {
  air_dt <- as.data.table(air_emissions)
  fwrite(air_dt, file.path(data_dir, "eurostat_air_emissions.csv"))
  cat("Eurostat air emissions:", nrow(air_dt), "observations\n")
}

# ============================================================================
# DATA VALIDATION
# ============================================================================

cat("\n=== DATA VALIDATION ===\n")

eprtr_raw <- fread(file.path(data_dir, "eprtr_raw.csv"))
cat("E-PRTR records:", nrow(eprtr_raw), "\n")
cat("Columns:", paste(names(eprtr_raw), collapse = ", "), "\n")

# Check for key fields
for (p in c("country|Country", "year|Year|report", "pollut|Pollut", "quantit|Quantit|total")) {
  matched <- grep(p, names(eprtr_raw), ignore.case = TRUE, value = TRUE)
  cat("  Pattern '", p, "':", ifelse(length(matched) > 0,
      paste(matched, collapse = ", "), "NOT FOUND"), "\n")
}

stopifnot("E-PRTR data has at least 1000 records" = nrow(eprtr_raw) >= 1000)

cat("\n=== DATA FETCH COMPLETE ===\n")
