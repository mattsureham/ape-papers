# =============================================================================
# 01_fetch_data.R — Download clinical trial data from ClinicalTrials.gov API
# =============================================================================
source("00_packages.R")

# ---------------------------------------------------------------------------
# A. Right-to-Try law effective dates (from Triage Cancer, validated)
# ---------------------------------------------------------------------------
rtt_laws <- data.table(
  state = c("Alabama", "Alaska", "Arizona", "Arkansas", "California",
            "Colorado", "Connecticut", "Florida", "Georgia", "Idaho",
            "Illinois", "Indiana", "Iowa", "Kentucky", "Louisiana",
            "Maine", "Maryland", "Michigan", "Minnesota", "Mississippi",
            "Missouri", "Montana", "Nebraska", "Nevada", "North Carolina",
            "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania",
            "South Carolina", "South Dakota", "Tennessee", "Texas",
            "Utah", "Virginia", "Washington", "West Virginia", "Wisconsin",
            "Wyoming"),
  rtt_date = as.Date(c(
    "2015-05-28", "2018-10-11", "2014-11-05", "2015-03-10", "2016-09-27",
    "2014-05-17", "2016-10-01", "2015-07-01", "2016-07-01", "2016-07-01",
    "2016-01-01", "2015-03-24", "2017-05-11", "2017-03-21", "2014-08-01",
    "2016-03-28", "2017-05-25", "2014-10-17", "2015-05-06", "2016-04-13",
    "2014-07-14", "2015-03-27", "2018-04-23", "2015-05-27", "2015-07-02",
    "2025-04-15", "2017-04-06", "2015-04-21", "2016-01-01", "2017-10-11",
    "2016-05-26", "2015-03-13", "2015-05-12", "2015-06-16",
    "2015-03-24", "2015-03-26", "2017-07-23", "2016-06-08", "2018-03-28",
    "2015-07-01"
  ))
)

# AZ Prop 303 was adopted Nov 2014 (ballot measure). The 2022 date on Triage Cancer
# is an expansion. Use original adoption date for identification.
rtt_laws[state == "Arizona", rtt_date := as.Date("2014-11-05")]

# North Dakota 2025 is after our panel — mark as never-treated in our window
rtt_laws <- rtt_laws[rtt_date < as.Date("2018-06-01")]

# Federal law: May 30, 2018 — all remaining states treated after this date
# States without state law before federal: DE, DC, HI, MA, NJ, NM, NY, RI, VT
# Plus: NH (2026), KS (2025), ND (2025) — effectively never-treated in our panel

# Add FIPS codes
state_fips <- data.table(
  state = state.name,
  fips = sprintf("%02d", as.integer(factor(state.name, levels = state.name)))
)
# Use actual FIPS codes
state_fips <- data.table(
  state = c(state.name, "District of Columbia"),
  fips = c("01","02","04","05","06","08","09","10","12","13",
           "15","16","17","18","19","20","21","22","23","24",
           "25","26","27","28","29","30","31","32","33","34",
           "35","36","37","38","39","40","41","42","44","45",
           "46","47","48","49","50","51","53","54","55","56","11")
)

rtt_laws <- merge(rtt_laws, state_fips, by = "state", all.x = TRUE)
rtt_laws[, rtt_quarter := paste0(year(rtt_date), "Q", quarter(rtt_date))]
rtt_laws[, rtt_year_q := year(rtt_date) + (quarter(rtt_date) - 1) / 4]

fwrite(rtt_laws, file.path(DATA_DIR, "rtt_law_dates.csv"))
cat("RTT law dates:", nrow(rtt_laws), "states with state laws before federal act\n")

# ---------------------------------------------------------------------------
# B. Download clinical trial data from ClinicalTrials.gov API v2
# ---------------------------------------------------------------------------
# We need: all US trials with start dates 2008-2017, with facility state info
# API returns paginated results. We'll query by year to manage volume.

BASE_URL <- "https://clinicaltrials.gov/api/v2/studies"

fetch_trials <- function(year, page_token = NULL) {
  params <- list(
    `filter.advanced` = paste0(
      "AREA[LocationCountry]United States AND ",
      "AREA[StartDate]RANGE[", year, "-01-01,", year, "-12-31]"
    ),
    countTotal = "true",
    pageSize = 1000,
    fields = paste(
      "protocolSection.identificationModule.nctId",
      "protocolSection.statusModule.overallStatus",
      "protocolSection.statusModule.startDateStruct",
      "protocolSection.statusModule.primaryCompletionDateStruct",
      "protocolSection.designModule.studyType",
      "protocolSection.designModule.phases",
      "protocolSection.designModule.enrollmentInfo",
      "protocolSection.sponsorCollaboratorsModule.leadSponsor",
      "protocolSection.conditionsModule.conditions",
      "protocolSection.contactsLocationsModule.locations",
      sep = ","
    )
  )
  if (!is.null(page_token)) params$pageToken <- page_token

  resp <- GET(BASE_URL, query = params)
  if (status_code(resp) != 200) {
    stop("API error for year ", year, ": HTTP ", status_code(resp))
  }
  content(resp, as = "parsed", simplifyVector = FALSE)
}

# Extract trial-level data
extract_trial_info <- function(study) {
  proto <- study$protocolSection
  id_mod <- proto$identificationModule
  stat_mod <- proto$statusModule
  design_mod <- proto$designModule
  sponsor_mod <- proto$sponsorCollaboratorsModule
  cond_mod <- proto$conditionsModule
  loc_mod <- proto$contactsLocationsModule

  nct_id <- id_mod$nctId %||% NA_character_
  status <- stat_mod$overallStatus %||% NA_character_

  # Start date
  start_date <- tryCatch({
    sd <- stat_mod$startDateStruct$date
    if (!is.null(sd)) as.character(sd) else NA_character_
  }, error = function(e) NA_character_)

  # Primary completion date
  completion_date <- tryCatch({
    cd <- stat_mod$primaryCompletionDateStruct$date
    if (!is.null(cd)) as.character(cd) else NA_character_
  }, error = function(e) NA_character_)

  # Study type and phase
  study_type <- design_mod$studyType %||% NA_character_
  phases <- tryCatch({
    p <- design_mod$phases
    if (length(p) > 0) paste(unlist(p), collapse = ";") else NA_character_
  }, error = function(e) NA_character_)

  # Enrollment
  enrollment <- tryCatch({
    e <- design_mod$enrollmentInfo$count
    if (!is.null(e)) as.integer(e) else NA_integer_
  }, error = function(e) NA_integer_)

  # Sponsor type
  sponsor_class <- tryCatch({
    sponsor_mod$leadSponsor$class %||% NA_character_
  }, error = function(e) NA_character_)

  # Conditions
  conditions <- tryCatch({
    c <- cond_mod$conditions
    if (length(c) > 0) paste(unlist(c), collapse = "; ") else NA_character_
  }, error = function(e) NA_character_)

  # Facility states (can be multiple)
  facility_states <- tryCatch({
    locs <- loc_mod$locations
    if (length(locs) > 0) {
      states <- vapply(locs, function(l) l$state %||% "", character(1))
      states <- states[states != "" & !is.na(states)]
      unique(states)
    } else {
      character(0)
    }
  }, error = function(e) character(0))

  # Return one row per facility state
  if (length(facility_states) == 0) {
    return(data.table(
      nct_id = nct_id, status = status, start_date = start_date,
      completion_date = completion_date, study_type = study_type,
      phases = phases, enrollment = enrollment, sponsor_class = sponsor_class,
      conditions = conditions, facility_state = NA_character_
    ))
  }

  data.table(
    nct_id = nct_id, status = status, start_date = start_date,
    completion_date = completion_date, study_type = study_type,
    phases = phases, enrollment = enrollment, sponsor_class = sponsor_class,
    conditions = conditions, facility_state = facility_states
  )
}

# Main download loop
all_trials <- list()
for (yr in 2008:2017) {
  cat("Fetching year", yr, "...")
  page_token <- NULL
  year_data <- list()
  page_num <- 0

  repeat {
    page_num <- page_num + 1
    result <- fetch_trials(yr, page_token)

    if (page_num == 1) {
      cat(" total:", result$totalCount, "trials")
    }

    studies <- result$studies
    if (length(studies) == 0) break

    batch <- rbindlist(lapply(studies, extract_trial_info), fill = TRUE)
    year_data[[page_num]] <- batch

    page_token <- result$nextPageToken
    if (is.null(page_token)) break

    cat(".")
    Sys.sleep(0.5)  # Be polite to the API
  }

  year_dt <- rbindlist(year_data, fill = TRUE)
  year_dt[, fetch_year := yr]
  all_trials[[as.character(yr)]] <- year_dt
  cat(" done:", nrow(year_dt), "trial-state rows\n")
}

trials <- rbindlist(all_trials, fill = TRUE)
cat("\nTotal trial-state observations:", nrow(trials), "\n")
cat("Unique trials:", uniqueN(trials$nct_id), "\n")
cat("States with facilities:", uniqueN(trials$facility_state[!is.na(trials$facility_state)]), "\n")

fwrite(trials, file.path(DATA_DIR, "clinical_trials_raw.csv"))

# === DATA VALIDATION (required) ===
stopifnot("Expected 40+ states with trial facilities" =
            uniqueN(trials$facility_state[!is.na(trials$facility_state)]) >= 40)
stopifnot("Expected 10 years of data" =
            uniqueN(trials$fetch_year) == 10)
stopifnot("Expected 10000+ unique trials" =
            uniqueN(trials$nct_id) >= 10000)
cat("Data validation passed:", uniqueN(trials$nct_id), "unique trials,",
    uniqueN(trials$facility_state[!is.na(trials$facility_state)]), "states,",
    uniqueN(trials$fetch_year), "years\n")
