## 01_fetch_data.R — Fetch FEMA disaster and assistance data from OpenFEMA APIs
## APEP Working Paper apep_0817

source("00_packages.R")

cat("=== Fetching FEMA Data ===\n")

# ---- Helper: paginated OpenFEMA fetch via httr2 ----
fetch_openfema <- function(endpoint, filter_str = NULL, select_fields = NULL,
                           max_records = 200000) {
  base_url <- paste0("https://www.fema.gov/api/open/v2/", endpoint)
  page_size <- 1000
  skip <- 0
  all_data <- list()

  repeat {
    req <- httr2::request(base_url) |>
      httr2::req_url_query(`$skip` = as.character(skip),
                           `$top` = as.character(page_size),
                           `$format` = "json")

    if (!is.null(filter_str)) {
      req <- httr2::req_url_query(req, `$filter` = filter_str)
    }
    if (!is.null(select_fields)) {
      req <- httr2::req_url_query(req, `$select` = select_fields)
    }

    resp <- tryCatch({
      req |>
        httr2::req_timeout(180) |>
        httr2::req_retry(max_tries = 5, backoff = ~3) |>
        httr2::req_perform()
    }, error = function(e) {
      stop(paste("API request failed for", endpoint, "at skip=", skip, ":", e$message))
    })

    if (httr2::resp_status(resp) != 200) {
      stop(paste("API returned status", httr2::resp_status(resp), "for", endpoint))
    }

    body <- httr2::resp_body_json(resp)
    dataset_key <- names(body)[!names(body) %in% c("metadata")]
    records <- body[[dataset_key]]

    if (length(records) == 0) break

    all_data <- c(all_data, records)
    skip <- skip + page_size

    if (length(all_data) >= max_records) break
    if (length(records) < page_size) break

    if (skip %% 10000 == 0) {
      cat(sprintf("  ... %d records from %s\n", length(all_data), endpoint))
    }
  }

  cat(sprintf("  Total: %d records from %s\n", length(all_data), endpoint))

  df <- bind_rows(lapply(all_data, function(rec) {
    rec[sapply(rec, is.null)] <- NA
    rec[sapply(rec, function(x) length(x) == 0)] <- NA
    as_tibble(rec)
  }))
  return(df)
}

# ---- 1. Disaster Declarations (DR + IHP only, since 2005) ----
cat("\n1. Fetching IHP major disaster declarations...\n")
declarations_raw <- fetch_openfema(
  "DisasterDeclarationsSummaries",
  filter_str = "declarationType eq 'DR' and ihProgramDeclared eq true",
  select_fields = paste0("disasterNumber,state,declarationDate,incidentBeginDate,",
                         "incidentEndDate,incidentType,fipsStateCode,fipsCountyCode,",
                         "designatedArea,declarationType,ihProgramDeclared,",
                         "iaProgramDeclared,hmProgramDeclared")
)

stopifnot("Got zero declaration records" = nrow(declarations_raw) > 0)

declarations <- declarations_raw |>
  mutate(
    declarationDate = as.Date(substr(declarationDate, 1, 10)),
    incidentBeginDate = as.Date(substr(incidentBeginDate, 1, 10)),
    incidentEndDate = as.Date(substr(incidentEndDate, 1, 10)),
    declaration_lag = as.numeric(declarationDate - incidentBeginDate),
    year = as.integer(format(declarationDate, "%Y"))
  )

# Get unique disasters (declarations are per-county)
disasters <- declarations |>
  filter(year >= 2010, declaration_lag >= 0, declaration_lag <= 365) |>
  group_by(disasterNumber) |>
  summarise(
    state = first(state),
    declarationDate = first(declarationDate),
    incidentBeginDate = first(incidentBeginDate),
    incidentEndDate = first(incidentEndDate),
    incidentType = first(incidentType),
    declaration_lag = first(declaration_lag),
    year = first(year),
    n_counties = n_distinct(fipsCountyCode),
    .groups = "drop"
  )

cat(sprintf("  IHP disasters since 2010: %d\n", nrow(disasters)))
cat(sprintf("  Declaration lag stats:\n"))
cat(sprintf("    Mean=%.1f, Median=%.0f, SD=%.1f, Min=%d, Max=%d\n",
            mean(disasters$declaration_lag), median(disasters$declaration_lag),
            sd(disasters$declaration_lag), min(disasters$declaration_lag),
            max(disasters$declaration_lag)))
cat(sprintf("  Incident types: %s\n",
            paste(names(sort(table(disasters$incidentType), decreasing=TRUE)[1:5]),
                  collapse=", ")))

stopifnot("Need at least 50 IHP disasters" = nrow(disasters) >= 50)

# ---- 2. Compute concurrent disaster load (IV) ----
cat("\n2. Computing concurrent disaster load instrument...\n")

disasters$concurrent_disasters <- sapply(1:nrow(disasters), function(i) {
  this_start <- disasters$incidentBeginDate[i]
  window_start <- this_start - 30
  window_end <- this_start + 30
  sum(disasters$disasterNumber != disasters$disasterNumber[i] &
      disasters$incidentBeginDate <= window_end &
      (is.na(disasters$incidentEndDate) | disasters$incidentEndDate >= window_start))
})

disasters$recent_declarations <- sapply(1:nrow(disasters), function(i) {
  this_start <- disasters$incidentBeginDate[i]
  sum(disasters$disasterNumber != disasters$disasterNumber[i] &
      disasters$declarationDate >= (this_start - 60) &
      disasters$declarationDate < this_start)
})

cat(sprintf("  Concurrent load: mean=%.1f, SD=%.1f, range=%d-%d\n",
            mean(disasters$concurrent_disasters),
            sd(disasters$concurrent_disasters),
            min(disasters$concurrent_disasters),
            max(disasters$concurrent_disasters)))
cat(sprintf("  Recent declarations (60d): mean=%.1f, SD=%.1f\n",
            mean(disasters$recent_declarations),
            sd(disasters$recent_declarations)))

# ---- 3. HousingAssistanceOwners (batched by disaster) ----
cat("\n3. Fetching HousingAssistanceOwners...\n")

target_disasters <- unique(disasters$disasterNumber)
housing_list <- list()
batch_size <- 10

groups <- split(target_disasters, ceiling(seq_along(target_disasters) / batch_size))

for (g in seq_along(groups)) {
  disaster_filter <- paste0("disasterNumber eq ", groups[[g]], collapse = " or ")

  batch <- tryCatch({
    fetch_openfema("HousingAssistanceOwners",
                   filter_str = disaster_filter)
  }, error = function(e) {
    cat(sprintf("    Batch %d failed: %s\n", g, e$message))
    tibble()
  })

  if (nrow(batch) > 0) housing_list[[g]] <- batch

  if (g %% 5 == 0) cat(sprintf("  Batch %d/%d done\n", g, length(groups)))
}

housing <- bind_rows(housing_list)

if (nrow(housing) > 0) {
  housing <- housing |>
    mutate(across(any_of(c("validRegistrations", "averageFemaInspectedDamage",
                           "totalDamage", "approvedForFemaAssistance",
                           "totalApprovedIhpAmount", "totalMaxGrants")),
                  ~as.numeric(as.character(.))))
}

cat(sprintf("  Housing records: %d across %d disasters\n",
            nrow(housing), n_distinct(housing$disasterNumber)))
stopifnot("Got zero housing records" = nrow(housing) > 0)

# ---- 4. RegistrationIntakeIndividualsHouseholdPrograms ----
cat("\n4. Fetching IHP registration intake...\n")

ihp_list <- list()
for (g in seq_along(groups)) {
  disaster_filter <- paste0("disasterNumber eq ", groups[[g]], collapse = " or ")

  batch <- tryCatch({
    fetch_openfema("RegistrationIntakeIndividualsHouseholdPrograms",
                   filter_str = disaster_filter)
  }, error = function(e) {
    cat(sprintf("    Batch %d failed: %s\n", g, e$message))
    tibble()
  })

  if (nrow(batch) > 0) ihp_list[[g]] <- batch

  if (g %% 5 == 0) cat(sprintf("  Batch %d/%d done\n", g, length(groups)))
}

ihp_intake <- bind_rows(ihp_list)

if (nrow(ihp_intake) > 0) {
  ihp_intake <- ihp_intake |>
    mutate(across(any_of(c("totalValidRegistrations", "ihpAmount",
                           "haAmount", "onaAmount", "ihpEligible")),
                  ~as.numeric(as.character(.))))
}

cat(sprintf("  IHP intake records: %d\n", nrow(ihp_intake)))

# ---- 5. Save ----
cat("\n5. Saving data...\n")
saveRDS(declarations, "../data/declarations_all.rds")
saveRDS(disasters, "../data/disasters.rds")
saveRDS(housing, "../data/housing_owners.rds")
saveRDS(ihp_intake, "../data/ihp_intake.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Unique IHP disasters: %d\n", nrow(disasters)))
cat(sprintf("Housing city-level records: %d\n", nrow(housing)))
cat(sprintf("IHP intake records: %d\n", nrow(ihp_intake)))
