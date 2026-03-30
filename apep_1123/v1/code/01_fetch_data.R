## 01_fetch_data.R — Fetch interventional trials from ClinicalTrials.gov API v2
## APEP-1123: The Registration Effect

source("00_packages.R")

cat("=== Fetching data from ClinicalTrials.gov API v2 ===\n")

base_url <- "https://clinicaltrials.gov/api/v2/studies"

# Function to extract study data from API JSON
extract_study <- function(study) {
  proto <- study$protocolSection
  id_mod <- proto$identificationModule %||% list()
  status_mod <- proto$statusModule %||% list()
  sponsor_mod <- proto$sponsorCollaboratorsModule %||% list()
  design_mod <- proto$designModule %||% list()
  conditions_mod <- proto$conditionsModule %||% list()
  outcomes_mod <- proto$outcomesModule %||% list()
  contacts_mod <- proto$contactsLocationsModule %||% list()

  # Count outcomes
  n_primary <- length(outcomes_mod$primaryOutcomes %||% list())
  n_secondary <- length(outcomes_mod$secondaryOutcomes %||% list())

  # US site
  locations <- contacts_mod$locations %||% list()
  countries <- unique(sapply(locations, function(x) x$country %||% NA_character_))
  has_us <- any(countries == "United States", na.rm = TRUE)

  # Phases
  phases <- paste(design_mod$phases %||% character(0), collapse = "/")

  tibble(
    nct_id = id_mod$nctId %||% NA_character_,
    phase = phases,
    start_date = status_mod$startDateStruct$date %||% NA_character_,
    completion_date = status_mod$completionDateStruct$date %||% NA_character_,
    primary_completion_date = status_mod$primaryCompletionDateStruct$date %||% NA_character_,
    results_first_post_date = status_mod$resultsFirstPostDateStruct$date %||% NA_character_,
    overall_status = status_mod$overallStatus %||% NA_character_,
    sponsor_class = sponsor_mod$leadSponsor$class %||% NA_character_,
    allocation = design_mod$designInfo$allocation %||% NA_character_,
    masking = design_mod$designInfo$maskingInfo$masking %||% NA_character_,
    primary_purpose = design_mod$designInfo$primaryPurpose %||% NA_character_,
    enrollment = design_mod$enrollmentInfo$count %||% NA_integer_,
    enrollment_type = design_mod$enrollmentInfo$type %||% NA_character_,
    n_primary_outcomes = n_primary,
    n_secondary_outcomes = n_secondary,
    condition_first = (conditions_mod$conditions %||% c(NA_character_))[[1]],
    has_us_site = has_us,
    has_results = study$hasResults %||% FALSE
  )
}

# Fetch all studies for a given phase, paginating
fetch_phase <- function(phase_code, phase_label) {
  cat(sprintf("Fetching %s trials...\n", phase_label))
  all_data <- list()
  page_token <- NULL
  page_num <- 0

  repeat {
    page_num <- page_num + 1

    url <- paste0(base_url,
      "?format=json",
      "&pageSize=1000",
      "&countTotal=true",
      "&query.term=AREA%5BStudyType%5DInterventional",
      "&filter.advanced=AREA%5BPhase%5D", phase_code)

    if (!is.null(page_token)) {
      url <- paste0(url, "&pageToken=", URLencode(page_token, reserved = TRUE))
    }

    resp <- tryCatch({
      request(url) |>
        req_timeout(60) |>
        req_retry(max_tries = 5, backoff = ~ 3) |>
        req_perform()
    }, error = function(e) {
      cat(sprintf("  ERROR on page %d: %s\n", page_num, e$message))
      return(NULL)
    })

    if (is.null(resp)) break

    body <- resp_body_json(resp)
    studies <- body$studies %||% list()

    if (length(studies) == 0) break

    if (page_num == 1) {
      cat(sprintf("  Total available: %s\n", body$totalCount %||% "unknown"))
    }

    extracted <- map_dfr(studies, possibly(extract_study, otherwise = NULL))
    all_data[[page_num]] <- extracted

    cat(sprintf("  Page %d: %d studies (cumulative: %d)\n",
                page_num, nrow(extracted), sum(sapply(all_data, nrow))))

    page_token <- body$nextPageToken
    if (is.null(page_token)) break

    Sys.sleep(0.2)
  }

  result <- bind_rows(all_data)
  cat(sprintf("  -> %d %s trials total\n", nrow(result), phase_label))
  result
}

# Fetch all phases
phase1 <- fetch_phase("PHASE1", "Phase 1")
phase2 <- fetch_phase("PHASE2", "Phase 2")
phase3 <- fetch_phase("PHASE3", "Phase 3")

# Combine and deduplicate (some trials may be PHASE1/PHASE2)
all_trials <- bind_rows(phase1, phase2, phase3) |>
  distinct(nct_id, .keep_all = TRUE)

cat(sprintf("\nTotal unique trials: %d\n", nrow(all_trials)))

# Parse start year
all_trials <- all_trials |>
  mutate(
    start_year = as.integer(substr(start_date, 1, 4)),
    # Classify phase group for DiD
    phase_group = case_when(
      phase == "PHASE1" ~ "Phase 1",
      phase == "EARLY_PHASE1" ~ "Phase 1",
      phase %in% c("PHASE2", "PHASE3", "PHASE2/PHASE3") ~ "Phase 2/3",
      phase == "PHASE1/PHASE2" ~ "Phase 1/2",
      TRUE ~ "Other"
    )
  )

# Summary by phase group and period
cat("\nTrials by phase group:\n")
print(table(all_trials$phase_group, useNA = "ifany"))

cat("\nTrials by start year (2000-2017):\n")
year_tab <- all_trials |>
  filter(start_year >= 2000, start_year <= 2017) |>
  count(phase_group, start_year) |>
  tidyr::pivot_wider(names_from = phase_group, values_from = n, values_fill = 0)
print(year_tab, n = 20)

# Save
write.csv(all_trials, "data/trials_raw.csv", row.names = FALSE)
cat(sprintf("\nSaved %d trials to data/trials_raw.csv\n", nrow(all_trials)))

# Validation
analysis_set <- all_trials |>
  filter(start_year >= 2003, start_year <= 2015,
         phase_group %in% c("Phase 1", "Phase 2/3"))
cat(sprintf("\nAnalysis sample (2003-2015, Phase 1 + Phase 2/3): %d trials\n", nrow(analysis_set)))
cat(sprintf("  Phase 1: %d\n", sum(analysis_set$phase_group == "Phase 1")))
cat(sprintf("  Phase 2/3: %d\n", sum(analysis_set$phase_group == "Phase 2/3")))

pre <- sum(analysis_set$start_year <= 2007)
post <- sum(analysis_set$start_year >= 2008)
cat(sprintf("  Pre-period (2003-2007): %d\n", pre))
cat(sprintf("  Post-period (2008-2015): %d\n", post))

stopifnot("Insufficient pre-period data" = pre >= 1000)
stopifnot("Insufficient post-period data" = post >= 1000)

cat("\n=== Data fetch complete ===\n")
