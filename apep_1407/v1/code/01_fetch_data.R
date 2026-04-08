## 01_fetch_data.R — Fetch FEMA OpenFEMA NFIP policy data
## apep_1407: The Insurance Denominator
##
## Uses checkpointing — saves each state/year batch to disk.
## If interrupted, re-run and it skips already-fetched batches.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

base_url <- "https://www.fema.gov/api/open/v2/FimaNfipPolicies"
batch_size <- 1000

## Focus on 5 highest-volume NFIP states for tractability
target_states <- c("FL", "TX", "LA", "NJ", "NY")

fields <- c(
  "policyEffectiveDate", "policyTerminationDate",
  "cancellationDateOfFloodPolicy",
  "totalInsurancePremiumOfThePolicy", "totalBuildingInsuranceCoverage",
  "floodZoneCurrent", "ratedFloodZone",
  "propertyState", "countyCode",
  "grandfatheringTypeCode", "mandatoryPurchaseFlag",
  "primaryResidenceIndicator", "occupancyType",
  "buildingReplacementCost", "policyCount"
)

select_str <- paste(fields, collapse = ",")

fetch_one_batch <- function(filter_str, skip_val) {
  req <- request(base_url) |>
    req_url_query(
      `$filter` = filter_str,
      `$select` = select_str,
      `$top` = batch_size,
      `$skip` = skip_val
    ) |>
    req_timeout(120) |>
    req_retry(max_tries = 5, backoff = ~10)

  resp <- req_perform(req)
  if (resp_status(resp) != 200) return(NULL)
  body <- resp_body_json(resp)
  body$FimaNfipPolicies
}

fetch_state_year <- function(state, yr_start, yr_end, max_records = 100000) {
  checkpoint_file <- file.path(data_dir, sprintf("checkpoint_%s_%d.rds", state, yr_start))

  if (file.exists(checkpoint_file)) {
    cat(sprintf("  [cached] %s %d-%d\n", state, yr_start, yr_end))
    return(readRDS(checkpoint_file))
  }

  filter_str <- sprintf(
    "propertyState eq '%s' and policyEffectiveDate ge '%d-01-01T00:00:00.000Z' and policyEffectiveDate lt '%d-01-01T00:00:00.000Z'",
    state, yr_start, yr_end + 1
  )

  all_data <- list()
  skip <- 0

  repeat {
    cat(sprintf("  %s %d-%d skip=%d ...", state, yr_start, yr_end, skip))

    records <- tryCatch(
      fetch_one_batch(filter_str, skip),
      error = function(e) {
        cat(sprintf(" ERROR: %s\n", e$message))
        NULL
      }
    )

    if (is.null(records) || length(records) == 0) {
      cat(" done\n")
      break
    }

    all_data <- c(all_data, records)
    cat(sprintf(" +%d (total=%d)\n", length(records), length(all_data)))
    skip <- skip + batch_size

    if (skip >= max_records) {
      cat(sprintf("  max=%d reached\n", max_records))
      break
    }

    Sys.sleep(0.5)  # Be nice to the API
  }

  if (length(all_data) == 0) {
    saveRDS(data.frame(), checkpoint_file)
    return(data.frame())
  }

  df <- bind_rows(lapply(all_data, function(x) {
    x[sapply(x, is.null)] <- NA
    as.data.frame(x, stringsAsFactors = FALSE)
  }))

  saveRDS(df, checkpoint_file)
  df
}

## ---- Main fetch loop ----
all_dfs <- list()

for (st in target_states) {
  cat(sprintf("\n=== State: %s ===\n", st))
  for (yr_start in c(2019, 2021, 2023)) {
    yr_end <- yr_start + 1
    df_batch <- fetch_state_year(st, yr_start, yr_end, max_records = 100000)
    if (nrow(df_batch) > 0) {
      all_dfs[[paste0(st, "_", yr_start)]] <- df_batch
    }
  }
}

df_raw <- bind_rows(all_dfs)
cat(sprintf("\n=== Total raw records: %s ===\n", format(nrow(df_raw), big.mark = ",")))

if (nrow(df_raw) == 0) stop("FATAL: No data retrieved from FEMA API.")

stopifnot("grandfatheringTypeCode" %in% names(df_raw))
stopifnot("totalInsurancePremiumOfThePolicy" %in% names(df_raw))

cat("Grandfathering distribution:\n")
print(table(df_raw$grandfatheringTypeCode, useNA = "always"))

## ---- Penetration rates ----
cat("\n=== Fetching penetration rates ===\n")
pen_req <- request("https://www.fema.gov/api/open/v1/NfipResidentialPenetrationRates") |>
  req_url_query(`$top` = 5000) |> req_timeout(60)
pen_resp <- req_perform(pen_req)
pen_data <- resp_body_json(pen_resp)$NfipResidentialPenetrationRates
df_penetration <- bind_rows(lapply(pen_data, function(x) {
  x[sapply(x, is.null)] <- NA
  as.data.frame(x, stringsAsFactors = FALSE)
}))
cat(sprintf("Penetration records: %d\n", nrow(df_penetration)))

## ---- Save final combined ----
saveRDS(df_raw, file.path(data_dir, "fema_policies_raw.rds"))
saveRDS(df_penetration, file.path(data_dir, "fema_penetration.rds"))

cat(sprintf("\n=== Done: %s policy + %d penetration records ===\n",
            format(nrow(df_raw), big.mark = ","), nrow(df_penetration)))
