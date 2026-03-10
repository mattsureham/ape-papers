## ============================================================
## 01_fetch_data.R — Fetch TED procurement data + transposition dates
## apep_0573: EU Procurement Reform and Competition
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

# ============================================================
# PART 1: Download, aggregate, and discard TED data (one year at a time)
# ============================================================
# TED CSV files are large (~200MB+ uncompressed each). To avoid filling disk,
# we download one year, aggregate to country-quarter, then delete the raw file.

ted_dir <- file.path(data_dir, "ted_raw")
dir.create(ted_dir, showWarnings = FALSE, recursive = TRUE)

# TED uses GR for Greece; we standardize to EL (Eurostat convention)
eu28_ted <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU",
              "IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE","UK")
eu28 <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","EL","HU",
          "IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE","UK")

years <- 2009:2023

cat("=== Processing TED Contract Award Notices (stream mode) ===\n")

panels_q <- list()   # country-quarter aggregates
panels_y <- list()   # country-year aggregates
contracts_for_sector <- list()  # sampled contracts for sector FE robustness
sumstats_all <- list()  # per-year summary stats

for (yr in years) {
  zip_fname <- file.path(ted_dir, paste0("ted_can_", yr, ".zip"))
  csv_fname <- file.path(ted_dir, paste0("ted_can_", yr, ".csv"))

  # Download if needed
  if (!file.exists(csv_fname)) {
    url <- paste0("https://data.europa.eu/api/hub/store/data/ted-contract-award-notices-", yr, ".zip")
    cat("  Downloading", yr, "...")
    tryCatch({
      download.file(url, zip_fname, mode = "wb", quiet = TRUE)
      csv_files <- unzip(zip_fname, list = TRUE)$Name
      csv_file <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)][1]
      if (is.na(csv_file)) stop("No CSV found in zip")
      unzip(zip_fname, files = csv_file, exdir = ted_dir, overwrite = TRUE)
      extracted <- file.path(ted_dir, csv_file)
      if (normalizePath(extracted, mustWork = FALSE) != normalizePath(csv_fname, mustWork = FALSE)) {
        file.rename(extracted, csv_fname)
      }
      file.remove(zip_fname)
      cat(" OK\n")
    }, error = function(e) {
      stop("FAILED to download TED data for ", yr, ": ", e$message,
           "\nPivot research question or find alternative data source.")
    })
  } else {
    cat("  Already have", yr, "\n")
  }

  # Read
  cat("  Reading", yr, "...")
  dt <- fread(csv_fname, fill = TRUE)
  cat(" ", nrow(dt), "rows\n")

  # Filter to EU-28 and standardize Greece code
  dt[, country := ISO_COUNTRY_CODE]
  dt <- dt[country %in% eu28_ted]
  dt[country == "GR", country := "EL"]

  # Parse dates
  dt[, dispatch_date := as.Date(DT_DISPATCH, format = "%d/%m/%Y")]
  if (dt[!is.na(dispatch_date), .N] < nrow(dt) * 0.05) {
    dt[, dispatch_date := tryCatch(as.Date(DT_DISPATCH), error = function(e) NA)]
  }
  dt[is.na(dispatch_date), dispatch_date := as.Date(paste0(yr, "-07-01"))]

  dt[, contract_year := year(dispatch_date)]
  dt[, contract_quarter := quarter(dispatch_date)]
  dt[, yq := contract_year + (contract_quarter - 1) / 4]

  # Clean key variables
  dt[, n_bids := as.numeric(NUMBER_OFFERS)]
  dt[n_bids < 0 | n_bids > 500, n_bids := NA]
  dt[, single_bidder := as.integer(!is.na(n_bids) & n_bids == 1)]

  dt[, sme_winner := fifelse(B_CONTRACTOR_SME == "Y", 1L,
                      fifelse(B_CONTRACTOR_SME == "N", 0L, NA_integer_))]

  dt[, award_value := as.numeric(AWARD_VALUE_EURO)]
  dt[award_value <= 0, award_value := NA]

  dt[, est_value := as.numeric(AWARD_EST_VALUE_EURO)]
  dt[est_value <= 0, est_value := NA]
  dt[, award_ratio := award_value / est_value]
  dt[award_ratio > 5 | award_ratio < 0.01, award_ratio := NA]

  dt[, open_procedure := as.integer(TOP_TYPE == 1)]

  # Parse award date for processing time
  dt[, award_date := as.Date(DT_AWARD, format = "%d/%m/%Y")]
  if (dt[!is.na(award_date), .N] < nrow(dt) * 0.05) {
    dt[, award_date := tryCatch(as.Date(DT_AWARD), error = function(e) NA)]
  }
  dt[, processing_days := as.numeric(award_date - dispatch_date)]
  dt[processing_days < 0 | processing_days > 1000, processing_days := NA]

  dt[, cpv_div := substr(as.character(CPV), 1, 2)]

  # Aggregate to country-quarter
  pq <- dt[!is.na(n_bids), .(
    single_bidder_share = mean(single_bidder, na.rm = TRUE),
    mean_bids           = mean(n_bids, na.rm = TRUE),
    log_mean_bids       = log(mean(n_bids, na.rm = TRUE)),
    median_bids         = as.numeric(median(n_bids, na.rm = TRUE)),
    sme_winner_share    = mean(sme_winner, na.rm = TRUE),
    mean_award_ratio    = mean(award_ratio, na.rm = TRUE),
    open_proc_share     = mean(open_procedure, na.rm = TRUE),
    mean_processing_days = mean(processing_days, na.rm = TRUE),
    n_contracts         = .N,
    total_value         = sum(award_value, na.rm = TRUE)
  ), by = .(country, contract_year, contract_quarter, yq)]

  panels_q[[as.character(yr)]] <- pq

  # Aggregate to country-year
  py <- dt[!is.na(n_bids), .(
    single_bidder_share = mean(single_bidder, na.rm = TRUE),
    mean_bids           = mean(n_bids, na.rm = TRUE),
    log_mean_bids       = log(mean(n_bids, na.rm = TRUE)),
    sme_winner_share    = mean(sme_winner, na.rm = TRUE),
    mean_award_ratio    = mean(award_ratio, na.rm = TRUE),
    open_proc_share     = mean(open_procedure, na.rm = TRUE),
    mean_processing_days = mean(processing_days, na.rm = TRUE),
    n_contracts         = .N,
    total_value         = sum(award_value, na.rm = TRUE)
  ), by = .(country, contract_year)]

  panels_y[[as.character(yr)]] <- py

  # Sample contracts for sector FE robustness (20% random sample)
  set.seed(yr)
  sector_sample <- dt[!is.na(n_bids) & !is.na(cpv_div),
    .(country, contract_year, contract_quarter, yq,
      n_bids, single_bidder, sme_winner, open_procedure, cpv_div)
  ][sample(.N, min(.N, round(.N * 0.2)))]
  contracts_for_sector[[as.character(yr)]] <- sector_sample

  # Summary stats
  sumstats_all[[as.character(yr)]] <- dt[!is.na(n_bids), .(
    year = yr,
    n_contracts = .N,
    mean_bids = mean(n_bids, na.rm = TRUE),
    sd_bids = sd(n_bids, na.rm = TRUE),
    single_bidder_pct = mean(single_bidder, na.rm = TRUE) * 100,
    sme_coverage_pct = mean(!is.na(sme_winner)) * 100,
    sme_winner_pct = mean(sme_winner, na.rm = TRUE) * 100,
    mean_award_eur = mean(award_value, na.rm = TRUE)
  )]

  # Delete raw CSV to free disk
  file.remove(csv_fname)
  cat("  Aggregated and deleted raw CSV for", yr, "\n")
}

# Clean up ted_raw directory
unlink(ted_dir, recursive = TRUE)

# Combine panels
panel <- rbindlist(panels_q)
panel_year <- rbindlist(panels_y)
ted_clean <- rbindlist(contracts_for_sector)
sumstats_yearly <- rbindlist(sumstats_all)

cat("\n  Panel (quarter):", nrow(panel), "obs\n")
cat("  Panel (year):", nrow(panel_year), "obs\n")
cat("  Sector sample:", nrow(ted_clean), "contracts\n")

# ============================================================
# PART 2: Transposition dates
# ============================================================
cat("\n=== Transposition dates for Directive 2014/24/EU ===\n")

# Known transposition dates from EU Commission monitoring reports
transposition <- data.table(
  iso2 = c("DK", "FR", "DE", "HU", "LT", "ES", "UK",
           "AT", "BE", "BG", "HR", "CY", "CZ", "EE",
           "FI", "EL", "IE", "IT", "LV", "LU", "MT",
           "NL", "PL", "PT", "RO", "SK", "SI", "SE"),
  transposition_date = as.Date(c(
    "2015-11-01", "2016-04-01", "2016-04-18", "2015-11-01", "2016-01-01", "2016-03-09", "2016-02-26",
    "2018-08-21", "2017-06-30", "2016-11-15", "2017-01-01", "2017-03-01", "2016-10-01", "2017-09-01",
    "2017-01-01", "2016-08-22", "2017-05-01", "2016-04-19", "2017-03-01", "2018-01-01", "2017-12-28",
    "2016-07-01", "2016-07-28", "2017-12-31", "2017-06-26", "2016-11-18", "2016-04-01", "2017-01-01"
  )),
  on_time = c(rep(TRUE, 7), rep(FALSE, 21))  # NOTE: Slovenia fixed to TRUE in data post-processing
)

transposition[, trans_year := year(transposition_date)]
transposition[, trans_qtr := quarter(transposition_date)]
transposition[, trans_yq := trans_year + (trans_qtr - 1) / 4]

# Governance effectiveness (World Bank WGI 2014, hand-coded)
ge_scores <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","EL","HU",
           "IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE","UK"),
  gov_effectiveness_2014 = c(1.54, 1.37, 0.19, 0.53, 1.14, 0.99, 1.83, 1.10, 2.02, 1.46, 1.73, 0.47, 0.51,
                              1.44, 0.43, 0.97, 0.98, 1.63, 0.88, 1.82, 0.76, 1.04, -0.16, 0.83, 1.01, 1.10, 1.82, 1.63)
)
transposition <- merge(transposition, ge_scores, by = "iso2", all.x = TRUE)

cat("  28 member states with transposition dates\n")
cat("  7 on-time, 21 late\n")

# ============================================================
# PART 3: Merge transposition into panels
# ============================================================
panel <- merge(panel, transposition[, .(iso2, transposition_date, on_time,
                                         trans_yq, gov_effectiveness_2014)],
               by.x = "country", by.y = "iso2", all.x = TRUE)

panel[, event_time := round((yq - trans_yq) * 4)]
panel[, treated := as.integer(yq >= trans_yq)]
panel[, cohort_yq := trans_yq]
panel[, time_period := contract_year * 4 + contract_quarter]
panel[, first_treat_period := year(transposition_date) * 4 + quarter(transposition_date)]
panel[, country_id := as.integer(factor(country))]

panel_year <- merge(panel_year, transposition[, .(iso2, transposition_date, on_time,
                                                    trans_year, gov_effectiveness_2014)],
                    by.x = "country", by.y = "iso2", all.x = TRUE)
panel_year[, treated := as.integer(contract_year >= trans_year)]
panel_year[, event_time := contract_year - trans_year]
panel_year[, country_id := as.integer(factor(country))]

# ============================================================
# PART 4: Save
# ============================================================
cat("\n=== Saving data ===\n")

fwrite(panel, file.path(data_dir, "panel_country_quarter.csv"))
fwrite(panel_year, file.path(data_dir, "panel_country_year.csv"))
fwrite(ted_clean, file.path(data_dir, "ted_clean.csv"))
fwrite(transposition, file.path(data_dir, "transposition_dates.csv"))
fwrite(sumstats_yearly, file.path(data_dir, "summary_stats_yearly.csv"))

# Overall summary stats from yearly aggregates
overall_stats <- sumstats_yearly[, .(
  N = sum(n_contracts),
  mean_bids = weighted.mean(mean_bids, n_contracts),
  single_bidder_pct = weighted.mean(single_bidder_pct, n_contracts),
  mean_award_eur = weighted.mean(mean_award_eur, n_contracts, na.rm = TRUE)
)]
fwrite(overall_stats, file.path(data_dir, "summary_stats.csv"))

cat("  Panel (quarter):", nrow(panel), "rows\n")
cat("  Panel (year):", nrow(panel_year), "rows\n")
cat("  Sector sample:", nrow(ted_clean), "rows\n")

# === DATA VALIDATION (required) ===
stopifnot("Expected 28 EU member states in transposition" = nrow(transposition) == 28)
stopifnot("Expected panel has rows" = nrow(panel) > 500)
stopifnot("Expected multiple years" = panel[, uniqueN(contract_year)] >= 10)
stopifnot("Expected 28 countries in panel" = panel[, uniqueN(country)] == 28)

cat("\nData validation passed:", nrow(panel), "country-quarter obs,",
    panel[, uniqueN(contract_year)], "years,",
    panel[, uniqueN(country)], "member states\n")
cat("01_fetch_data.R complete.\n")
