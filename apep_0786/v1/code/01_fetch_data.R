## 01_fetch_data.R — Fetch HMDA data from CFPB, aggregate on the fly
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending
##
## Downloads state by state, filters, identifies exempt lenders via
## "Exempt" markers in total_loan_costs, aggregates to lender-county-year-race level.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

states <- c(
  "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL",
  "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME",
  "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH",
  "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI",
  "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
)

sel_cols <- c("lei", "state_code", "county_code", "action_taken",
              "loan_type", "loan_purpose", "lien_status",
              "derived_race", "total_loan_costs",
              "loan_amount", "income", "activity_year")

fetch_state <- function(state, year, tmpdir) {
  tmpfile <- file.path(tmpdir, paste0("hmda_", state, "_", year, ".csv"))
  resp <- httr::GET(
    "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv",
    query = list(years = year, states = state),
    httr::write_disk(tmpfile, overwrite = TRUE),
    httr::timeout(600)
  )
  if (httr::status_code(resp) != 200 || file.size(tmpfile) < 500) {
    unlink(tmpfile)
    return(NULL)
  }

  avail <- names(fread(tmpfile, nrows = 0))
  dt <- fread(tmpfile, select = intersect(sel_cols, avail), showProgress = FALSE)
  unlink(tmpfile)

  if (nrow(dt) == 0) return(NULL)

  # Filter: conventional home purchase, first lien, originated or denied
  dt <- dt[action_taken %in% c(1L, 3L)]
  if ("loan_type" %in% names(dt)) dt <- dt[loan_type == 1L]
  if ("loan_purpose" %in% names(dt)) dt <- dt[loan_purpose == 1L]
  if ("lien_status" %in% names(dt)) dt <- dt[lien_status == 1L]
  if (nrow(dt) == 0) return(NULL)

  # Exempt flag: lender-level (if ANY loan reports "Exempt", lender is exempt)
  if ("total_loan_costs" %in% names(dt)) {
    dt[, exempt := as.integer(any(total_loan_costs == "Exempt", na.rm = TRUE)), by = lei]
  } else {
    dt[, exempt := NA_integer_]
  }

  # Simplify race
  dt[, race := fcase(
    derived_race == "White", "White",
    derived_race == "Black or African American", "Black",
    derived_race == "Asian", "Asian",
    default = "Other"
  )]

  # Add year column if not present
  if ("activity_year" %in% names(dt)) {
    dt[, yr := as.integer(activity_year)]
  } else {
    dt[, yr := year]
  }

  # Aggregate to lender-county-year-race-action level
  agg <- dt[, .(
    n = .N,
    mean_loan_amt = mean(as.numeric(loan_amount), na.rm = TRUE),
    mean_income = mean(as.numeric(income), na.rm = TRUE)
  ), by = .(year = yr, lei, state_code, county_code, race,
            action = action_taken, exempt)]

  agg
}

# ---------------------------------------------------------------
# Main download loop
# ---------------------------------------------------------------
tmpdir <- tempdir()
all_years_data <- list()

for (year in 2018:2022) {
  outfile <- file.path(data_dir, paste0("hmda_agg_", year, ".parquet"))
  if (file.exists(outfile)) {
    cat("Already have", basename(outfile), "\n")
    next
  }

  cat(sprintf("\n=== Year %d ===\n", year))
  chunks <- list()
  t0 <- Sys.time()

  for (st in states) {
    agg <- fetch_state(st, year, tmpdir)
    if (!is.null(agg) && nrow(agg) > 0) {
      chunks[[st]] <- agg
      cat(sprintf("%s(%dk) ", st, round(nrow(agg) / 1000)))
    } else {
      cat(st, "- ")
    }
  }

  combined <- rbindlist(chunks, fill = TRUE)
  elapsed <- round(difftime(Sys.time(), t0, units = "mins"), 1)
  cat(sprintf("\nYear %d: %s rows, %d lenders (%d exempt), %d counties [%.1f min]\n",
              year, format(nrow(combined), big.mark = ","),
              uniqueN(combined$lei),
              uniqueN(combined[exempt == 1]$lei),
              uniqueN(combined$county_code),
              elapsed))

  if (nrow(combined) == 0) {
    stop("FATAL: No data for year ", year)
  }

  arrow::write_parquet(combined, outfile)
  rm(chunks, combined); gc()
}

# ---------------------------------------------------------------
# Validation
# ---------------------------------------------------------------
cat("\n=== Validation Summary ===\n")
for (yr in 2018:2022) {
  f <- file.path(data_dir, paste0("hmda_agg_", yr, ".parquet"))
  if (!file.exists(f)) stop("Missing: ", f)
  d <- as.data.table(arrow::read_parquet(f))
  cat(sprintf("  %d: %s agg rows | %d lenders (%d exempt, %d non-exempt) | %d counties\n",
              yr, format(nrow(d), big.mark = ","),
              uniqueN(d$lei),
              uniqueN(d[exempt == 1]$lei),
              uniqueN(d[exempt == 0]$lei),
              uniqueN(d$county_code)))
}

cat("\nDone.\n")
