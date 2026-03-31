## 01_fetch_data.R — Fetch OpenFEMA data via REST API
## APEP-1204: Stretched Thin
## Data: Disaster Declarations, IHP Housing Assistance, PA Funded Projects

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Helper: paginated OpenFEMA fetch with retry on 503
# ============================================================================
fetch_openfema <- function(dataset, fields = NULL, filter_str = NULL,
                           batch_size = 1000, max_records = Inf, max_retries = 3) {
  base_url <- paste0("https://www.fema.gov/api/open/v2/", dataset)
  all_records <- list()
  skip <- 0

  repeat {
    params <- list(`$skip` = skip, `$top` = batch_size, `$format` = "json")
    if (!is.null(fields)) params[["$select"]] <- fields
    if (!is.null(filter_str)) params[["$filter"]] <- filter_str

    success <- FALSE
    for (attempt in 1:max_retries) {
      resp <- httr::GET(base_url, query = params)
      sc <- httr::status_code(resp)
      if (sc == 200) { success <- TRUE; break }
      if (sc == 503) {
        cat(sprintf("    503 at skip=%d, retry %d/%d...\n", skip, attempt, max_retries))
        Sys.sleep(5 * attempt)
      } else {
        stop(sprintf("OpenFEMA API error %d for %s (skip=%d)", sc, dataset, skip))
      }
    }
    if (!success) {
      cat(sprintf("    Giving up on %s at skip=%d after %d retries\n",
                  dataset, skip, max_retries))
      break
    }

    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content, flatten = TRUE)
    records <- parsed[[dataset]]
    if (is.null(records) || nrow(records) == 0) break

    all_records[[length(all_records) + 1]] <- as_tibble(records)
    skip <- skip + nrow(records)
    if (nrow(records) < batch_size || skip >= max_records) break
    if (skip %% 5000 == 0) cat(sprintf("  %d records...\n", skip))
    Sys.sleep(0.3)
  }

  if (length(all_records) == 0) stop(sprintf("No records from %s", dataset))
  result <- bind_rows(all_records)
  cat(sprintf("  DONE: %d records from %s\n", nrow(result), dataset))
  result
}

# ============================================================================
# 1. Disaster Declarations Summary (complete universe)
# ============================================================================
decl_file <- file.path(data_dir, "declarations.rds")
if (file.exists(decl_file)) {
  cat("Loading cached declarations...\n")
  declarations <- readRDS(decl_file)
} else {
  cat("Fetching Disaster Declarations Summary...\n")
  declarations <- fetch_openfema(
    "DisasterDeclarationsSummaries",
    fields = paste0(
      "disasterNumber,declarationDate,fyDeclared,incidentType,",
      "declarationType,state,incidentBeginDate,incidentEndDate,",
      "fipsStateCode,fipsCountyCode,designatedArea,",
      "ihProgramDeclared,iaProgramDeclared,paProgramDeclared"
    )
  )
  stopifnot(nrow(declarations) > 10000)
  saveRDS(declarations, decl_file)
}
cat(sprintf("Declarations: %d rows, %d unique disasters\n",
            nrow(declarations), n_distinct(declarations$disasterNumber)))

# ============================================================================
# 2. IHP Housing Assistance (Owners — zip-level aggregates per disaster)
# ============================================================================
ihp_file <- file.path(data_dir, "ihp_owners.rds")
if (file.exists(ihp_file)) {
  cat("Loading cached IHP data...\n")
  ihp <- readRDS(ihp_file)
} else {
  cat("Fetching IHP Housing Assistance Owners (batched by state)...\n")
  ihp_fields <- paste0(
    "disasterNumber,state,county,city,zipCode,",
    "validRegistrations,totalInspected,",
    "approvedForFemaAssistance,totalApprovedIhpAmount,totalMaxGrants,",
    "repairReplaceAmount,rentalAmount,otherNeedsAmount,",
    "averageFemaInspectedDamage,totalDamage"
  )
  states <- sort(unique(declarations$state))
  ihp_all <- list()
  for (st in states) {
    cat(sprintf("  State %s: ", st))
    filt <- sprintf("state eq '%s'", st)
    tryCatch({
      batch <- fetch_openfema("HousingAssistanceOwners",
                              fields = ihp_fields, filter_str = filt,
                              max_retries = 5)
      ihp_all[[length(ihp_all) + 1]] <- batch
    }, error = function(e) {
      cat(sprintf("SKIP (%s)\n", conditionMessage(e)))
    })
    Sys.sleep(0.5)
  }
  ihp <- bind_rows(ihp_all)
  stopifnot(nrow(ihp) > 10000)
  saveRDS(ihp, ihp_file)
}
cat(sprintf("IHP Owner Records: %d rows, %d disasters\n",
            nrow(ihp), n_distinct(ihp$disasterNumber)))

# ============================================================================
# 3. PA Funded Projects (fetch with generous retry; save whatever we get)
# ============================================================================
pa_file <- file.path(data_dir, "pa_projects.rds")
if (file.exists(pa_file)) {
  cat("Loading cached PA data...\n")
  pa_projects <- readRDS(pa_file)
} else {
  cat("Fetching PA Funded Projects (post-2005, batched by year)...\n")
  pa_fields <- paste0(
    "disasterNumber,stateAbbreviation,county,countyCode,projectAmount,",
    "federalShareObligated,totalObligated,firstObligationDate,lastObligationDate,",
    "incidentType,declarationDate,damageCategoryCode,projectSize"
  )
  pa_all <- list()
  for (yr in 2005:2024) {
    cat(sprintf("  Year %d: ", yr))
    filt <- sprintf(
      "declarationDate ge '%d-01-01T00:00:00.000Z' and declarationDate lt '%d-01-01T00:00:00.000Z'",
      yr, yr + 1
    )
    tryCatch({
      batch <- fetch_openfema("PublicAssistanceFundedProjectsDetails",
                              fields = pa_fields, filter_str = filt,
                              max_retries = 5)
      pa_all[[length(pa_all) + 1]] <- batch
    }, error = function(e) {
      cat(sprintf("SKIP (%s)\n", conditionMessage(e)))
    })
    Sys.sleep(2)
  }
  pa_projects <- bind_rows(pa_all)
  if (nrow(pa_projects) > 0) {
    saveRDS(pa_projects, pa_file)
    cat(sprintf("PA Projects: %d rows saved\n", nrow(pa_projects)))
  } else {
    cat("WARNING: No PA projects fetched\n")
  }
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("Declarations:  %d rows, %d disasters\n",
            nrow(declarations), n_distinct(declarations$disasterNumber)))
cat(sprintf("IHP Owners:    %d rows, %d disasters\n",
            nrow(ihp), n_distinct(ihp$disasterNumber)))
if (exists("pa_projects") && nrow(pa_projects) > 0) {
  cat(sprintf("PA Projects:   %d rows, %d disasters\n",
              nrow(pa_projects), n_distinct(pa_projects$disasterNumber)))
}
