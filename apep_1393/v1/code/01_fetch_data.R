## 01_fetch_data.R — Fetch FDIC SOD, FDIC mergers, and HMDA data
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. FDIC Summary of Deposits (SOD) — branch-level panel
# ============================================================================
cat("=== Fetching FDIC SOD data ===\n")

# API migrated to api.fdic.gov (banks.data.fdic.gov redirects)
fetch_sod_year <- function(year) {
  all_rows <- list()
  offset <- 0
  repeat {
    url <- paste0("https://api.fdic.gov/banks/sod?filters=YEAR%3A", year,
                   "&fields=CERT,BRNUM,UNINUMBR,STCNTYBR,SIMS_LATITUDE,SIMS_LONGITUDE,DEPSUMBR,YEAR,NAMEFULL,STALPBR,MSABR",
                   "&limit=10000&offset=", offset, "&sort_by=CERT&sort_order=ASC")
    resp <- httr::GET(url)
    if (httr::status_code(resp) != 200) {
      stop("FDIC SOD API returned status ", httr::status_code(resp), " for year ", year)
    }
    body <- httr::content(resp, as = "parsed")
    rows <- body$data
    if (length(rows) == 0) break

    df <- bind_rows(lapply(rows, function(r) {
      d <- r$data
      tibble(
        cert = as.integer(d$CERT %||% NA),
        brnum = d$BRNUM %||% NA_character_,
        stcntybr = d$STCNTYBR %||% NA_character_,
        lat = as.numeric(d$SIMS_LATITUDE %||% NA),
        lon = as.numeric(d$SIMS_LONGITUDE %||% NA),
        deposits = as.numeric(d$DEPSUMBR %||% NA),
        year = as.integer(d$YEAR %||% NA),
        bank_name = d$NAMEFULL %||% NA_character_,
        state = d$STALPBR %||% NA_character_,
        msa = d$MSABR %||% NA_character_
      )
    }))

    all_rows[[length(all_rows) + 1]] <- df
    offset <- offset + 10000
    cat("  Year", year, "- fetched", offset, "records so far\n")
    if (length(rows) < 10000) break
    Sys.sleep(0.3)
  }

  result <- bind_rows(all_rows)
  cat("  Year", year, ":", nrow(result), "branches\n")
  result
}

# Check if SOD data already exists
if (file.exists(file.path(data_dir, "fdic_sod.rds"))) {
  cat("SOD data already exists, loading...\n")
  sod <- readRDS(file.path(data_dir, "fdic_sod.rds"))
  cat("Loaded", nrow(sod), "records\n")
} else {
  sod_years <- 2015:2023
  sod_list <- list()
  for (yr in sod_years) {
    sod_list[[as.character(yr)]] <- fetch_sod_year(yr)
    Sys.sleep(1)
  }
  sod <- bind_rows(sod_list)
  cat("Total SOD records:", nrow(sod), "\n")
  stopifnot("SOD data is empty" = nrow(sod) > 0)
  saveRDS(sod, file.path(data_dir, "fdic_sod.rds"))
}

# ============================================================================
# 2. FDIC Merger Events (CHANGECODE 711=assisted, 713=unassisted mergers)
# ============================================================================
cat("\n=== Fetching FDIC merger events ===\n")

# For mergers, CERT is the target (disappearing) institution
# We need CERT of targets + any info about acquirers
# CHANGECODE 711 = merger with assistance, 713 = merger without assistance
all_mergers <- list()
for (code in c(711, 713)) {
  offset <- 0
  repeat {
    url <- paste0("https://api.fdic.gov/banks/history?",
                  "filters=CHANGECODE%3A", code,
                  "&fields=CERT,INSTNAME,EFFDATE,CHANGECODE,PSTALP,PCITY,ACQ_UNINUM,OUT_UNINUM",
                  "&limit=10000&offset=", offset,
                  "&sort_by=EFFDATE&sort_order=DESC")
    resp <- httr::GET(url)
    if (httr::status_code(resp) != 200) {
      cat("WARNING: API returned", httr::status_code(resp), "for code", code, "\n")
      break
    }
    body <- httr::content(resp, as = "parsed")
    rows <- body$data
    if (length(rows) == 0) break

    df <- bind_rows(lapply(rows, function(r) {
      d <- r$data
      tibble(
        target_cert = as.integer(d$CERT %||% NA),
        target_name = d$INSTNAME %||% NA_character_,
        target_state = d$PSTALP %||% NA_character_,
        target_city = d$PCITY %||% NA_character_,
        eff_date = d$EFFDATE %||% NA_character_,
        change_code = as.integer(d$CHANGECODE %||% NA),
        acq_uninum = d$ACQ_UNINUM %||% NA_character_,
        out_uninum = d$OUT_UNINUM %||% NA_character_
      )
    }))

    all_mergers[[length(all_mergers) + 1]] <- df
    offset <- offset + 10000
    cat("  Code", code, "- fetched", offset, "records\n")
    if (length(rows) < 10000) break
    Sys.sleep(0.3)
  }
}

mergers <- bind_rows(all_mergers)
cat("Total merger records:", nrow(mergers), "\n")

# Parse ISO dates and filter to 2012-2023
mergers <- mergers %>%
  mutate(eff_date = as.Date(substr(eff_date, 1, 10), format = "%Y-%m-%d")) %>%
  filter(!is.na(eff_date),
         eff_date >= as.Date("2012-01-01"),
         eff_date <= as.Date("2023-12-31"))

cat("Mergers in 2012-2023:", nrow(mergers), "\n")
stopifnot("No mergers found" = nrow(mergers) > 100)

# For the instrument, we need both target CERTs (which disappear) AND
# we need to identify which CERTs are "merger-involved"
# The target CERT disappears after the merger date, so pre-merger SOD
# will show these branches under the target CERT
# Post-merger, branches transfer to the acquirer or close

# Since we can't directly get acquirer CERT, we use a different approach:
# Track which CERTs disappear from SOD between consecutive years
# CERTs that were in SOD year t but not t+1, AND have a merger record, are confirmed mergers
# Their branches either transferred to another CERT or closed

mergers <- mergers %>%
  mutate(merger_year = as.integer(format(eff_date, "%Y")))

saveRDS(mergers, file.path(data_dir, "fdic_mergers.rds"))
cat("Saved fdic_mergers.rds\n")

# ============================================================================
# 3. HMDA Loan-Level Data
# ============================================================================
cat("\n=== Fetching HMDA data ===\n")

hmda_years <- 2018:2023
states <- c("CA", "TX", "FL", "NY", "IL", "PA", "OH", "GA", "NC", "MI",
            "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI")

fetch_hmda_year <- function(year) {
  cat("  Fetching HMDA", year, "...\n")
  state_data <- list()

  for (st in states) {
    # CFPB API allows max 2 filter criteria; use states + actions_taken only
    url <- paste0("https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?",
                  "years=", year,
                  "&states=", st,
                  "&actions_taken=1,3")

    tryCatch({
      temp_file <- tempfile(fileext = ".csv")
      # Must follow redirects (301 → S3 bucket)
      resp <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE),
                        httr::timeout(300), httr::config(followlocation = TRUE))
      if (httr::status_code(resp) != 200) {
        cat("    WARNING: State", st, "returned status", httr::status_code(resp), "\n")
        next
      }

      # Read CSV, selecting needed columns
      df <- fread(temp_file, select = c(
        "census_tract", "derived_race", "action_taken",
        "interest_rate", "rate_spread", "loan_amount",
        "income", "debt_to_income_ratio", "property_value",
        "county_code", "state_code", "loan_type", "loan_purpose",
        "derived_dwelling_category"
      ), showProgress = FALSE)

      # Filter in R: conventional, home purchase, single-family site-built
      df <- df[loan_type == 1 & loan_purpose == 1 &
               grepl("Single Family.*Site-Built", derived_dwelling_category)]
      df[, c("loan_type", "loan_purpose", "derived_dwelling_category") := NULL]

      # Ensure consistent types across states
      df[, census_tract := as.character(census_tract)]
      df[, county_code := as.character(county_code)]
      df[, state_code := as.character(state_code)]

      df$year <- year
      state_data[[st]] <- df
      cat("    State", st, ":", nrow(df), "records\n")
      unlink(temp_file)
      Sys.sleep(0.5)
    }, error = function(e) {
      cat("    ERROR fetching", st, ":", e$message, "\n")
    })
  }

  bind_rows(state_data)
}

hmda_list <- list()
for (yr in hmda_years) {
  hmda_list[[as.character(yr)]] <- fetch_hmda_year(yr)
  cat("  Year", yr, "total:", nrow(hmda_list[[as.character(yr)]]), "records\n\n")
}

hmda_raw <- bind_rows(hmda_list)
cat("Total HMDA records:", nrow(hmda_raw), "\n")
stopifnot("HMDA data is empty" = nrow(hmda_raw) > 0)

saveRDS(hmda_raw, file.path(data_dir, "hmda_raw.rds"))
cat("Saved hmda_raw.rds\n")

cat("\n=== Data fetch complete ===\n")
cat("Files saved:\n")
cat("  fdic_sod.rds:", round(file.size(file.path(data_dir, "fdic_sod.rds")) / 1e6, 1), "MB\n")
cat("  fdic_mergers.rds:", round(file.size(file.path(data_dir, "fdic_mergers.rds")) / 1e6, 1), "MB\n")
cat("  hmda_raw.rds:", round(file.size(file.path(data_dir, "hmda_raw.rds")) / 1e6, 1), "MB\n")
