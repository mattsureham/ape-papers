## 01_fetch_data.R — Process USAspending bulk download data
## apep_0759: Simplified to Compete
##
## Strategy: Use USAspending bulk download API to get full FPDS contract data.
## We have one file already (treated band, FY2023). For remaining cells, we
## submit download requests and poll for completion.

source("00_packages.R")

out_dir <- "../data"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(out_dir, "bulk"), showWarnings = FALSE)

## Key columns from FPDS bulk CSV
cols_needed <- c(
  "contract_award_unique_key",
  "total_obligated_amount",
  "current_total_value_of_award",
  "award_base_action_date",
  "award_base_action_date_fiscal_year",
  "solicitation_date",
  "period_of_performance_start_date",
  "awarding_agency_name",
  "awarding_sub_agency_name",
  "naics_code",
  "extent_competed_code",
  "extent_competed",
  "type_of_set_aside_code",
  "type_of_set_aside",
  "number_of_offers_received",
  "solicitation_procedures_code",
  "recipient_state_code",
  "disaster_emergency_fund_codes"
)

## ---- Submit download requests ----
download_url <- "https://api.usaspending.gov/api/v2/download/awards/"

submit_download <- function(name, start, end, lo, hi) {
  cat(sprintf("Submitting %s...", name))
  body <- list(
    filters = list(
      time_period = list(list(start_date = start, end_date = end)),
      award_type_codes = list("A", "B", "C", "D"),
      award_amounts = list(list(lower_bound = lo, upper_bound = hi))
    ),
    columns = list(),
    file_format = "csv"
  )
  resp <- tryCatch({
    req <- request(download_url) |> req_body_json(body) |> req_timeout(60) |> req_perform()
    resp_body_json(req)
  }, error = function(e) list(status_url = NA, file_url = NA))
  cat(sprintf(" submitted\n"))
  return(resp)
}

## Submit for all 6 cells
cells <- list(
  below_pre  = list(start = "2017-10-01", end = "2020-09-30", lo = 50000,  hi = 149999),
  below_post = list(start = "2020-10-01", end = "2023-09-30", lo = 50000,  hi = 149999),
  treat_pre  = list(start = "2017-10-01", end = "2020-09-30", lo = 150000, hi = 249999),
  treat_post = list(start = "2020-10-01", end = "2023-09-30", lo = 150000, hi = 249999),
  above_pre  = list(start = "2017-10-01", end = "2020-09-30", lo = 250000, hi = 500000),
  above_post = list(start = "2020-10-01", end = "2023-09-30", lo = 250000, hi = 500000)
)

jobs <- list()
for (nm in names(cells)) {
  c <- cells[[nm]]
  resp <- submit_download(nm, c$start, c$end, c$lo, c$hi)
  jobs[[nm]] <- list(status_url = resp$status_url, file_url = resp$file_url, done = FALSE)
  Sys.sleep(1)
}

## ---- Poll and download ----
cat("\nPolling for completion...\n")
max_polls <- 60  # 15 minutes max

for (poll in seq_len(max_polls)) {
  n_done <- sum(sapply(jobs, function(j) j$done))
  if (n_done == length(jobs)) break

  Sys.sleep(15)
  for (nm in names(jobs)) {
    if (jobs[[nm]]$done || is.na(jobs[[nm]]$status_url)) next
    resp <- tryCatch({
      req <- request(jobs[[nm]]$status_url) |> req_timeout(30) |> req_perform()
      resp_body_json(req)
    }, error = function(e) list(status = "error"))

    if (resp$status == "finished") {
      dest <- file.path(out_dir, "bulk", paste0(nm, ".zip"))
      cat(sprintf("  %s: DONE (%s rows) - downloading\n", nm, resp$total_rows))
      tryCatch(download.file(resp$file_url, dest, mode = "wb", quiet = TRUE),
               error = function(e) cat(sprintf("    Download failed: %s\n", e$message)))
      jobs[[nm]]$done <- TRUE
      jobs[[nm]]$rows <- resp$total_rows
    }
  }

  if (poll %% 4 == 0) {
    cat(sprintf("  Poll %d: %d/%d complete\n", poll, sum(sapply(jobs, function(j) j$done)), length(jobs)))
  }
}

## ---- Extract and combine CSVs ----
cat("\nExtracting and combining CSVs...\n")

all_data <- list()

for (nm in names(jobs)) {
  zipfile <- file.path(out_dir, "bulk", paste0(nm, ".zip"))
  if (!file.exists(zipfile)) {
    cat(sprintf("  %s: ZIP not found, skipping\n", nm))
    next
  }

  tmpdir <- tempdir()
  unzip(zipfile, exdir = tmpdir, overwrite = TRUE)
  csvs <- list.files(tmpdir, pattern = "Contracts_PrimeAwardSummaries.*\\.csv$",
                     full.names = TRUE, recursive = TRUE)

  if (length(csvs) == 0) {
    cat(sprintf("  %s: No CSV found in ZIP\n", nm))
    next
  }

  dt <- fread(csvs[1], select = cols_needed)
  cat(sprintf("  %s: %s rows\n", nm, format(nrow(dt), big.mark = ",")))

  # Assign band and period based on cell name
  if (grepl("below", nm)) dt[, band := "below_control"]
  else if (grepl("treat", nm)) dt[, band := "treated"]
  else dt[, band := "above_control"]

  dt[, post := as.integer(grepl("post", nm))]
  all_data[[nm]] <- dt

  # Clean up
  file.remove(csvs)
}

if (length(all_data) == 0) {
  stop("No data files could be processed. Cannot proceed.")
}

contracts <- rbindlist(all_data, fill = TRUE)

## ---- Basic validation ----
cat(sprintf("\n\nTotal contracts: %s\n", format(nrow(contracts), big.mark = ",")))
cat(sprintf("Bands: %s\n", paste(unique(contracts$band), collapse = ", ")))
cat(sprintf("NAICS coverage: %.0f%%\n", 100 * mean(!is.na(contracts$naics_code) & contracts$naics_code != "")))
cat(sprintf("Extent competed coverage: %.0f%%\n", 100 * mean(!is.na(contracts$extent_competed_code) & contracts$extent_competed_code != "")))
cat(sprintf("Offers coverage: %.0f%%\n", 100 * mean(!is.na(contracts$number_of_offers_received))))

cat("\n--- By band × period ---\n")
print(contracts[, .N, by = .(band, post)][order(band, post)])

stopifnot("No contracts" = nrow(contracts) > 0)
stopifnot("Need both bands" = length(unique(contracts$band)) >= 2)

## ---- Save ----
fwrite(contracts, file.path(out_dir, "contracts_raw.csv"))
saveRDS(contracts, file.path(out_dir, "contracts_raw.rds"))
cat(sprintf("\nSaved %s contracts to contracts_raw\n", format(nrow(contracts), big.mark = ",")))
