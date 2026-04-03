# 01b_retry_fetch.R — Retry failed 2023/2024 state downloads with longer timeouts
source("00_packages.R")

data_dir <- "../data"

# Load existing data
existing <- fread(file.path(data_dir, "hmda_tract_year.csv"))
cat("Existing data:", nrow(existing), "rows\n")

# Check what we have for 2023 and 2024
for (yr in 2023:2024) {
  states_present <- unique(existing[year == yr]$state)
  cat(sprintf("Year %d: %d states present (%s)\n", yr, length(states_present),
              paste(states_present, collapse = ", ")))
}

# States we need
all_states <- c("NY", "PA", "OH", "IL", "GA", "NC", "MI",
                "NJ", "VA", "WA", "AZ", "CO")

# Identify missing state-years
missing <- list()
for (yr in 2023:2024) {
  states_present <- unique(existing[year == yr]$state)
  states_missing <- setdiff(all_states, states_present)
  if (length(states_missing) > 0) {
    for (st in states_missing) {
      missing <- c(missing, list(list(year = yr, state = st)))
    }
  }
}

cat("\nMissing state-years:", length(missing), "\n")
for (m in missing) {
  cat(sprintf("  %s %d\n", m$state, m$year))
}

if (length(missing) == 0) {
  cat("Nothing to retry!\n")
  q(save = "no")
}

# Retry with longer timeout and delays between requests
new_rows <- list()
for (i in seq_along(missing)) {
  m <- missing[[i]]
  cat(sprintf("\n[%d/%d] Retrying %s %d...\n", i, length(missing), m$state, m$year))

  url <- sprintf(
    "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?years=%d&states=%s",
    m$year, m$state
  )

  tmp <- tempfile(fileext = ".csv")

  # Try up to 3 times with increasing delays
  success <- FALSE
  for (attempt in 1:3) {
    cat(sprintf("  Attempt %d...", attempt))

    resp <- tryCatch({
      download.file(url, tmp, mode = "w", quiet = TRUE, timeout = 600)
      0
    }, error = function(e) {
      cat(sprintf(" error: %s\n", conditionMessage(e)))
      1
    })

    if (resp == 0 && file.exists(tmp) && file.size(tmp) > 1000) {
      success <- TRUE
      cat(" OK\n")
      break
    }

    # Wait longer between retries
    wait_time <- 10 * attempt
    cat(sprintf(" Failed. Waiting %ds...\n", wait_time))
    Sys.sleep(wait_time)
  }

  if (!success) {
    cat("  GIVING UP on", m$state, m$year, "\n")
    next
  }

  # Read and aggregate
  raw <- fread(tmp, select = c(
    "census_tract", "action_taken", "loan_amount",
    "derived_race", "rate_spread", "loan_purpose",
    "tract_to_msa_income_percentage", "ffiec_msa_md_median_family_income",
    "derived_msa-md", "state_code", "county_code",
    "tract_population", "tract_minority_population_percent",
    "tract_owner_occupied_units", "tract_one_to_four_family_homes"
  ), colClasses = list(character = c("census_tract", "derived_msa-md",
                                      "state_code", "county_code")))

  tract_agg <- raw[, .(
    n_applications   = .N,
    n_originated     = sum(action_taken == 1, na.rm = TRUE),
    n_denied         = sum(action_taken == 3, na.rm = TRUE),
    n_approved_not_accepted = sum(action_taken == 2, na.rm = TRUE),
    total_loan_amount = sum(as.numeric(loan_amount[action_taken == 1]), na.rm = TRUE),
    mean_loan_amount  = mean(as.numeric(loan_amount[action_taken == 1]), na.rm = TRUE),
    n_purchase    = sum(action_taken == 1 & loan_purpose == 1, na.rm = TRUE),
    n_refinance   = sum(action_taken == 1 & loan_purpose %in% c(31, 32, 3), na.rm = TRUE),
    n_white       = sum(action_taken == 1 & derived_race == "White", na.rm = TRUE),
    n_black       = sum(action_taken == 1 & derived_race == "Black or African American", na.rm = TRUE),
    n_hispanic    = sum(action_taken == 1 & derived_race == "Hispanic or Latino", na.rm = TRUE),
    n_asian       = sum(action_taken == 1 & derived_race == "Asian", na.rm = TRUE),
    mean_rate_spread = mean(as.numeric(rate_spread[action_taken == 1 &
                              rate_spread != "NA" & rate_spread != "Exempt"]),
                            na.rm = TRUE),
    income_pct     = as.numeric(tract_to_msa_income_percentage[1]),
    msa_mfi        = as.numeric(ffiec_msa_md_median_family_income[1]),
    msa_md         = `derived_msa-md`[1],
    state          = state_code[1],
    county         = county_code[1],
    tract_pop      = as.numeric(tract_population[1]),
    minority_pct   = as.numeric(tract_minority_population_percent[1]),
    owner_occ      = as.numeric(tract_owner_occupied_units[1]),
    sfr_units      = as.numeric(tract_one_to_four_family_homes[1])
  ), by = .(census_tract)]

  tract_agg[, year := m$year]
  new_rows[[length(new_rows) + 1]] <- tract_agg
  cat(sprintf("  Got %d tracts, %d loans\n", nrow(tract_agg), nrow(raw)))

  rm(raw); gc(verbose = FALSE)
  unlink(tmp)

  # Generous delay between states
  Sys.sleep(5)
}

if (length(new_rows) > 0) {
  new_data <- rbindlist(new_rows, fill = TRUE)
  cat("\nNew data:", nrow(new_data), "rows\n")

  # Append to existing
  combined <- rbindlist(list(existing, new_data), fill = TRUE)
  cat("Combined:", nrow(combined), "rows\n")
  fwrite(combined, file.path(data_dir, "hmda_tract_year.csv"))
  cat("Saved updated dataset.\n")
} else {
  cat("\nNo new data retrieved.\n")
  combined <- existing
}

# Re-run reclassification identification
cat("\n=== Re-identifying reclassified tracts ===\n")
df <- combined
df[, lmi := as.integer(income_pct <= 80)]

tracts_23 <- df[year == 2023, .(census_tract, lmi_2023 = lmi, pct_2023 = income_pct, msa_2023 = msa_md)]
tracts_24 <- df[year == 2024, .(census_tract, lmi_2024 = lmi, pct_2024 = income_pct, msa_2024 = msa_md)]

reclassified <- merge(tracts_23, tracts_24, by = "census_tract")
reclassified[, status_changed := lmi_2023 != lmi_2024]
reclassified[, gained_lmi := lmi_2023 == 0 & lmi_2024 == 1]
reclassified[, lost_lmi   := lmi_2023 == 1 & lmi_2024 == 0]
reclassified[, msa_changed := msa_2023 != msa_2024]
reclassified[, pct_change := pct_2024 - pct_2023]

cat("Total tracts matched 2023-2024:", nrow(reclassified), "\n")
cat("Status changed:", sum(reclassified$status_changed), "\n")
cat("  Gained LMI:", sum(reclassified$gained_lmi), "\n")
cat("  Lost LMI:", sum(reclassified$lost_lmi), "\n")
cat("  MSA assignment changed:", sum(reclassified$msa_changed, na.rm = TRUE), "\n")

fwrite(reclassified, file.path(data_dir, "reclassified_tracts.csv"))
cat("Saved reclassification data.\n")
