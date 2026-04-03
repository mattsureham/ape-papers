# 01_fetch_data.R — Fetch HMDA data via CFPB Data Browser API
# Strategy: Download state-by-state for 2018-2024, aggregate to tract-year
# level immediately to manage memory and storage.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Configuration
# ============================================================
# Focus on 15 large states with many MSAs for the V1 analysis
# These represent ~60% of US mortgage originations
# CA, TX, FL excluded: too large for API timeout (~1M+ records each)
target_states <- c("NY", "PA", "OH", "IL", "GA", "NC", "MI",
                   "NJ", "VA", "WA", "AZ", "CO")
years <- 2018:2024

agg_file <- file.path(data_dir, "hmda_tract_year.csv")

if (file.exists(agg_file)) {
  cat("Aggregated data already exists at", agg_file, "— skipping fetch.\n")
  df <- fread(agg_file)
  cat("Loaded", nrow(df), "tract-year observations.\n")
} else {

  # ============================================================
  # Part 1: Download and aggregate HMDA data
  # ============================================================
  all_agg <- list()
  idx <- 0

  for (yr in years) {
    for (st in target_states) {
      idx <- idx + 1
      cat(sprintf("[%d/%d] Fetching %s %d...", idx, length(years) * length(target_states), st, yr))

      url <- sprintf(
        "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?years=%d&states=%s",
        yr, st
      )

      # Download to temp file
      tmp <- tempfile(fileext = ".csv")
      resp <- tryCatch(
        download.file(url, tmp, mode = "w", quiet = TRUE, timeout = 300),
        error = function(e) {
          cat(" ERROR:", conditionMessage(e), "\n")
          1
        }
      )

      if (resp != 0 || !file.exists(tmp) || file.size(tmp) < 100) {
        cat(" FAILED (will retry once)\n")
        Sys.sleep(2)
        resp <- tryCatch(
          download.file(url, tmp, mode = "w", quiet = TRUE, timeout = 300),
          error = function(e) 1
        )
        if (resp != 0) {
          cat(" RETRY FAILED — skipping\n")
          next
        }
      }

      # Read and aggregate immediately
      raw <- fread(tmp, select = c(
        "census_tract", "action_taken", "loan_amount",
        "derived_race", "rate_spread", "loan_purpose",
        "tract_to_msa_income_percentage", "ffiec_msa_md_median_family_income",
        "derived_msa-md", "state_code", "county_code",
        "tract_population", "tract_minority_population_percent",
        "tract_owner_occupied_units", "tract_one_to_four_family_homes"
      ), colClasses = list(character = c("census_tract", "derived_msa-md",
                                          "state_code", "county_code")))

      # Aggregate to tract level
      tract_agg <- raw[, .(
        # Lending volume
        n_applications   = .N,
        n_originated     = sum(action_taken == 1, na.rm = TRUE),
        n_denied         = sum(action_taken == 3, na.rm = TRUE),
        n_approved_not_accepted = sum(action_taken == 2, na.rm = TRUE),

        # Loan amounts (originated only)
        total_loan_amount = sum(as.numeric(loan_amount[action_taken == 1]), na.rm = TRUE),
        mean_loan_amount  = mean(as.numeric(loan_amount[action_taken == 1]), na.rm = TRUE),

        # Purchase vs refinance (originated)
        n_purchase    = sum(action_taken == 1 & loan_purpose == 1, na.rm = TRUE),
        n_refinance   = sum(action_taken == 1 & loan_purpose %in% c(31, 32, 3), na.rm = TRUE),

        # Race (originated loans)
        n_white       = sum(action_taken == 1 & derived_race == "White", na.rm = TRUE),
        n_black       = sum(action_taken == 1 & derived_race == "Black or African American", na.rm = TRUE),
        n_hispanic    = sum(action_taken == 1 & derived_race == "Hispanic or Latino", na.rm = TRUE),
        n_asian       = sum(action_taken == 1 & derived_race == "Asian", na.rm = TRUE),

        # Rate spread (originated, non-missing)
        mean_rate_spread = mean(as.numeric(rate_spread[action_taken == 1 &
                                  rate_spread != "NA" & rate_spread != "Exempt"]),
                                na.rm = TRUE),

        # Tract characteristics (first non-NA value since same within tract-year)
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

      tract_agg[, year := yr]

      all_agg[[idx]] <- tract_agg
      cat(sprintf(" %d tracts, %d loans\n", nrow(tract_agg), nrow(raw)))

      rm(raw); gc(verbose = FALSE)
      unlink(tmp)

      # Respect rate limits
      Sys.sleep(0.5)
    }
  }

  # Combine all
  df <- rbindlist(all_agg, fill = TRUE)
  cat("\n=== Combined dataset:", nrow(df), "tract-year obs across",
      uniqueN(df$census_tract), "tracts ===\n")

  # Save
  fwrite(df, agg_file)
  cat("Saved to", agg_file, "\n")
}

# ============================================================
# Part 2: Identify reclassified tracts
# ============================================================
cat("\n=== Identifying reclassified tracts ===\n")

# LMI = income_pct <= 80
df[, lmi := as.integer(income_pct <= 80)]

# Compare 2023 vs 2024
tracts_23 <- df[year == 2023, .(census_tract, lmi_2023 = lmi, pct_2023 = income_pct, msa_2023 = msa_md)]
tracts_24 <- df[year == 2024, .(census_tract, lmi_2024 = lmi, pct_2024 = income_pct, msa_2024 = msa_md)]

reclassified <- merge(tracts_23, tracts_24, by = "census_tract")
reclassified[, status_changed := lmi_2023 != lmi_2024]
reclassified[, gained_lmi := lmi_2023 == 0 & lmi_2024 == 1]  # non-LMI -> LMI
reclassified[, lost_lmi   := lmi_2023 == 1 & lmi_2024 == 0]  # LMI -> non-LMI
reclassified[, msa_changed := msa_2023 != msa_2024]

cat("Total tracts matched 2023-2024:", nrow(reclassified), "\n")
cat("Status changed:", sum(reclassified$status_changed), "\n")
cat("  Gained LMI:", sum(reclassified$gained_lmi), "\n")
cat("  Lost LMI:", sum(reclassified$lost_lmi), "\n")
cat("  MSA assignment changed:", sum(reclassified$msa_changed, na.rm = TRUE), "\n")

# Also check for income_pct changes (regardless of LMI crossing)
reclassified[, pct_change := pct_2024 - pct_2023]
cat("Mean pct change among status changers:",
    round(mean(reclassified[status_changed == TRUE]$pct_change, na.rm = TRUE), 2), "\n")

# Save reclassification data
fwrite(reclassified, file.path(data_dir, "reclassified_tracts.csv"))
cat("Saved reclassification data.\n")

cat("\n=== Data fetch complete ===\n")
cat("Files in data directory:\n")
cat(paste(list.files(data_dir), collapse = "\n"), "\n")
