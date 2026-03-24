# 01_fetch_data.R — Fetch GIAS and DfE school characteristics data
# apep_0881: Academy Conversion and Pupil Sorting

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. GIAS (Get Information About Schools) — Academy conversion dates
# ==============================================================================
cat("Fetching GIAS establishment data (March 2026 snapshot)...\n")

gias_url <- "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata20260301.csv"
gias_file <- file.path(data_dir, "gias_establishments.csv")

resp <- httr2::request(gias_url) |>
  httr2::req_timeout(180) |>
  httr2::req_headers("User-Agent" = "Mozilla/5.0") |>
  httr2::req_error(is_error = function(resp) FALSE) |>
  httr2::req_perform()

stopifnot(httr2::resp_status(resp) == 200)
writeBin(httr2::resp_body_raw(resp), gias_file)
cat("GIAS downloaded:", file.size(gias_file) / 1e6, "MB\n")

gias <- read_csv(gias_file, show_col_types = FALSE, locale = locale(encoding = "latin1"))
cat("GIAS rows:", nrow(gias), "| Columns:", ncol(gias), "\n")

# Identify academies
academy_types <- c("Academy converter", "Academy sponsor led",
                   "Free schools", "University technical college", "Studio schools")
academies <- gias |>
  filter(`TypeOfEstablishment (name)` %in% academy_types) |>
  select(URN, EstablishmentName, TypeName = `TypeOfEstablishment (name)`,
         OpenDate, CloseDate, LA_name = `LA (name)`, LA_code = `LA (code)`,
         Phase = `PhaseOfEducation (name)`,
         StatusName = `EstablishmentStatus (name)`,
         Postcode, StatutoryLowAge, StatutoryHighAge,
         NumberOfPupils, PercentageFSM,
         SchoolCapacity) |>
  mutate(
    OpenDate = dmy(OpenDate),
    CloseDate = dmy(CloseDate),
    conversion_year = year(OpenDate)
  )

cat("\nAcademy types:\n")
print(table(academies$TypeName))
cat("\nConversions by year:\n")
print(table(academies$conversion_year))
cat("\nOpen academies:", sum(academies$StatusName == "Open", na.rm = TRUE), "\n")

saveRDS(academies, file.path(data_dir, "academies.rds"))

# ==============================================================================
# 2. Build school panel from GIAS data
# ==============================================================================
# GIAS contains PercentageFSM and NumberOfPupils for the latest snapshot.
# For a panel, we need historical snapshots. The GIAS publishes dated extracts.
# Let's download multiple annual snapshots to build the panel.

cat("\n\nBuilding historical panel from annual GIAS snapshots...\n")

# Available dates: first of each month, with some gaps
# We want annual snapshots roughly corresponding to January school census
# Try January or March of each year (January census date)

# Snapshots available from 2021 onward (earlier years return 404)
# Use January snapshots (closest to January school census date)
snapshot_dates <- c(
  "20210101", "20220101", "20230101", "20240101", "20250101", "20260301"
)

panel_list <- list()

for (snap_date in snapshot_dates) {
  snap_year <- as.integer(substr(snap_date, 1, 4))
  snap_file <- file.path(data_dir, paste0("gias_", snap_date, ".csv"))

  if (file.exists(snap_file)) {
    cat("  ", snap_date, "- cached\n")
    df <- read_csv(snap_file, show_col_types = FALSE, locale = locale(encoding = "latin1"))
  } else {
    url <- paste0("https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata", snap_date, ".csv")
    cat("  ", snap_date, "- downloading...")

    resp <- tryCatch({
      httr2::request(url) |>
        httr2::req_timeout(120) |>
        httr2::req_headers("User-Agent" = "Mozilla/5.0") |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()
    }, error = function(e) NULL)

    if (is.null(resp) || httr2::resp_status(resp) != 200) {
      cat(" FAILED (status:", if(!is.null(resp)) httr2::resp_status(resp) else "timeout", ")\n")
      next
    }

    writeBin(httr2::resp_body_raw(resp), snap_file)
    cat(" OK (", round(file.size(snap_file)/1e6, 1), "MB)\n")
    df <- read_csv(snap_file, show_col_types = FALSE, locale = locale(encoding = "latin1"))
  }

  # Extract key columns for panel
  # Column names may vary across years
  cols_needed <- c("URN", "EstablishmentName",
                   "TypeOfEstablishment (name)", "LA (code)", "LA (name)",
                   "PhaseOfEducation (name)", "EstablishmentStatus (name)",
                   "NumberOfPupils", "PercentageFSM",
                   "NumberOfBoys", "NumberOfGirls",
                   "OfstedRating (name)", "OpenDate", "CloseDate")

  available_cols <- intersect(cols_needed, names(df))

  snap_df <- df |>
    select(all_of(available_cols)) |>
    mutate(snapshot_year = snap_year)

  # Standardize names
  # Coerce all columns to character to avoid type mismatches across years
  snap_df <- snap_df |> mutate(across(everything(), as.character))

  snap_df <- snap_df |>
    rename_with(~ case_when(
      . == "TypeOfEstablishment (name)" ~ "TypeName",
      . == "LA (code)" ~ "LA_code",
      . == "LA (name)" ~ "LA_name",
      . == "PhaseOfEducation (name)" ~ "Phase",
      . == "EstablishmentStatus (name)" ~ "StatusName",
      TRUE ~ .
    ))

  panel_list[[snap_date]] <- snap_df
}

cat("\nSnapshots collected:", length(panel_list), "\n")

# Combine into panel
if (length(panel_list) == 0) {
  stop("No GIAS snapshots could be downloaded. Cannot proceed.")
}

panel_raw <- bind_rows(panel_list) |>
  mutate(
    URN = as.integer(URN),
    NumberOfPupils = as.numeric(NumberOfPupils),
    PercentageFSM = as.numeric(PercentageFSM),
    NumberOfBoys = as.numeric(NumberOfBoys),
    NumberOfGirls = as.numeric(NumberOfGirls),
    snapshot_year = as.integer(snapshot_year)
  )
cat("Raw panel rows:", nrow(panel_raw), "\n")
cat("Unique schools:", n_distinct(panel_raw$URN), "\n")
cat("Years covered:", paste(sort(unique(panel_raw$snapshot_year)), collapse = ", "), "\n")

saveRDS(panel_raw, file.path(data_dir, "panel_raw.rds"))

# ==============================================================================
# 3. Download SEN/EAL data from EES
# ==============================================================================
# The GIAS snapshots have FSM% and headcount but not SEN/EAL breakdowns.
# SEN/EAL data is in the "Special educational needs in England" and
# "Schools, pupils and their characteristics" publications.

# Search for SEN datasets on data.gov.uk
cat("\n\nSearching for SEN school-level data...\n")

sen_search <- httr2::request("https://data.gov.uk/api/action/package_search") |>
  httr2::req_url_query(q = "special educational needs school level england", rows = 5) |>
  httr2::req_timeout(30) |>
  httr2::req_perform() |>
  httr2::resp_body_json()

for (ds in sen_search$result$results) {
  cat("  -", ds$title, "\n")
  for (res in ds$resources[1:min(2, length(ds$resources))]) {
    if (!is.null(res$url) && nchar(res$url) > 0) {
      cat("    URL:", substr(res$url, 1, 100), "\n")
      cat("    Format:", res$format %||% "unknown", "\n")
    }
  }
}

# For V1, we proceed with FSM% from GIAS as our primary outcome
# SEN data can be added as a robustness check if available

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files saved in:", normalizePath(data_dir), "\n")
cat("- academies.rds: Academy conversion details\n")
cat("- gias_full.rds: Full latest GIAS extract\n")
cat("- panel_raw.rds: Multi-year school panel\n")
