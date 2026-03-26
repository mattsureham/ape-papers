## 01_fetch_data.R — Fetch OSHA SIR + BLS QCEW + FEMA Disasters
## apep_1018: The Spotlight Effect on Safety Reporting
## ALL DATA FROM REAL SOURCES.

source("00_packages.R")

# --------------------------------------------------------------------------
# 1. OSHA Severe Injury Reports (already downloaded)
# --------------------------------------------------------------------------
cat("=== Loading OSHA SIR Data ===\n")

sir_file <- "../data/January2015toJuly2025.csv"
stopifnot(file.exists(sir_file))  # Must exist from prior download

sir <- read_csv(sir_file, show_col_types = FALSE)
cat("OSHA SIR loaded:", nrow(sir), "rows,", ncol(sir), "cols\n")
cat("Columns:", paste(names(sir), collapse = ", "), "\n")

# Standardize column names
names(sir) <- gsub(" ", "_", tolower(names(sir)))
cat("Date range:", min(sir$eventdate, na.rm = TRUE), "to",
    max(sir$eventdate, na.rm = TRUE), "\n")

# Parse dates
sir <- sir %>%
  mutate(
    event_date = mdy(eventdate),
    event_year = year(event_date),
    event_quarter = quarter(event_date),
    event_week = isoweek(event_date),
    event_yearqtr = paste0(event_year, "Q", event_quarter),
    naics4 = substr(as.character(primary_naics), 1, 4),
    naics2 = substr(as.character(primary_naics), 1, 2),
    hospitalized = as.numeric(hospitalized),
    amputation = as.numeric(amputation),
    loss_of_eye = as.numeric(loss_of_eye),
    severe = as.integer(hospitalized > 0 | amputation > 0 | loss_of_eye > 0)
  ) %>%
  filter(!is.na(event_date), event_year >= 2015, event_year <= 2024)

cat("After filtering:", nrow(sir), "rows\n")
cat("Years:", paste(sort(unique(sir$event_year)), collapse = ", "), "\n")
cat("States:", n_distinct(sir$state), "\n")
cat("NAICS 2-digit sectors:", n_distinct(sir$naics2), "\n")
cat("NAICS 4-digit industries:", n_distinct(sir$naics4), "\n")

# Show top sectors
cat("\nTop 10 NAICS 2-digit sectors:\n")
sir %>% count(naics2, sort = TRUE) %>% head(10) %>% print()

# Injury type breakdown
cat("\nInjury types:\n")
cat("  Hospitalizations:", sum(sir$hospitalized > 0, na.rm = TRUE), "\n")
cat("  Amputations:", sum(sir$amputation > 0, na.rm = TRUE), "\n")
cat("  Eye losses:", sum(sir$loss_of_eye > 0, na.rm = TRUE), "\n")

# Save processed SIR
write_csv(sir, "../data/sir_processed.csv")

# --------------------------------------------------------------------------
# 2. BLS QCEW — Already fetched, now process
# --------------------------------------------------------------------------
cat("\n=== Processing BLS QCEW Data ===\n")

qcew_file <- "../data/qcew_national.csv"
stopifnot(file.exists(qcew_file))

qcew <- read_csv(qcew_file, show_col_types = FALSE, col_types = cols(.default = "c"))
cat("QCEW loaded:", nrow(qcew), "rows\n")
cat("Columns:", paste(names(qcew), collapse = ", "), "\n")

# Extract NAICS employment by year-quarter
# QCEW has own_code (ownership), industry_code, size_code, year, qtr
# We want private sector (own_code = 5), all sizes
qcew_clean <- qcew %>%
  filter(own_code == "5",   # Private
         size_code == "0",   # All sizes
         agglvl_code == "14" | agglvl_code == "74") %>%  # National or industry level
  mutate(
    year = as.integer(api_year),
    qtr = as.integer(api_qtr),
    naics4 = substr(industry_code, 1, 4),
    naics2 = substr(industry_code, 1, 2),
    avg_emp = as.numeric(month3_emplvl),  # Use third month of quarter
    total_wages = as.numeric(total_qtrly_wages),
    establishments = as.numeric(qtrly_estabs)
  ) %>%
  select(year, qtr, industry_code, naics4, naics2, avg_emp, total_wages,
         establishments, agglvl_code) %>%
  filter(!is.na(avg_emp))

cat("QCEW processed:", nrow(qcew_clean), "rows\n")
cat("Industries:", n_distinct(qcew_clean$industry_code), "\n")

write_csv(qcew_clean, "../data/qcew_processed.csv")

# --------------------------------------------------------------------------
# 3. FEMA Disaster Declarations (competing-attention instrument)
# --------------------------------------------------------------------------
cat("\n=== Fetching FEMA Disaster Declarations ===\n")

# The Eisensee-Stromberg competing-news IV uses total news volume to
# instrument for media coverage of specific events. We use FEMA major
# disaster declarations as an alternative measure of competing news.
# Rationale: Major disasters (hurricanes, floods, fires) dominate news
# cycles and crowd out coverage of workplace injuries.

fema_file <- "../data/fema_disasters.csv"

if (!file.exists(fema_file) || file.size(fema_file) < 100) {
  cat("Fetching from FEMA API...\n")

  # Fetch all declarations 2014-2025
  all_disasters <- list()
  skip <- 0
  batch_size <- 1000

  repeat {
    url <- sprintf(
      "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries?$filter=declarationDate%%20ge%%20'2014-01-01T00:00:00.000z'%%20and%%20declarationDate%%20le%%20'2025-12-31T00:00:00.000z'&$select=disasterNumber,declarationDate,state,incidentType,declarationTitle,fyDeclared,incidentBeginDate,incidentEndDate&$top=%d&$skip=%d&$orderby=declarationDate",
      batch_size, skip
    )

    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) != 200) break

    content <- httr::content(resp, as = "parsed")
    records <- content$DisasterDeclarationsSummaries
    if (length(records) == 0) break

    batch_df <- bind_rows(lapply(records, function(r) {
      tibble(
        disaster_number = r$disasterNumber,
        declaration_date = r$declarationDate,
        state = r$state,
        incident_type = r$incidentType,
        title = r$declarationTitle,
        incident_begin = r$incidentBeginDate,
        incident_end = r$incidentEndDate
      )
    }))

    all_disasters[[length(all_disasters) + 1]] <- batch_df
    skip <- skip + batch_size
    cat("  Fetched", skip, "records...\n")

    if (nrow(batch_df) < batch_size) break
    Sys.sleep(0.5)
  }

  fema <- bind_rows(all_disasters)
  cat("FEMA declarations fetched:", nrow(fema), "\n")

  # Parse dates
  fema <- fema %>%
    mutate(
      declaration_date = as.Date(substr(declaration_date, 1, 10)),
      incident_begin = as.Date(substr(incident_begin, 1, 10)),
      incident_end = as.Date(substr(incident_end, 1, 10)),
      year = year(declaration_date),
      week = isoweek(declaration_date),
      quarter = quarter(declaration_date),
      yearqtr = paste0(year, "Q", quarter)
    )

  write_csv(fema, fema_file)
} else {
  fema <- read_csv(fema_file, show_col_types = FALSE)
  cat("Loaded cached FEMA data:", nrow(fema), "rows\n")
}

cat("FEMA data:\n")
cat("  Total declarations:", nrow(fema), "\n")
cat("  Years:", min(fema$year, na.rm = TRUE), "-", max(fema$year, na.rm = TRUE), "\n")
cat("  Incident types:\n")
fema %>% count(incident_type, sort = TRUE) %>% head(10) %>% print()

# Aggregate to quarter level: number of active disaster declarations per quarter
# This is our competing-attention instrument
fema_quarterly <- fema %>%
  filter(!is.na(declaration_date)) %>%
  group_by(year, quarter) %>%
  summarize(
    n_disasters = n_distinct(disaster_number),
    n_major_disasters = n_distinct(disaster_number[incident_type %in%
      c("Hurricane", "Fire", "Flood", "Severe Storm(s)", "Tornado")]),
    n_states_affected = n_distinct(state),
    .groups = "drop"
  ) %>%
  mutate(yearqtr = paste0(year, "Q", quarter))

# Also compute weekly counts for finer-grained analysis
fema_weekly <- fema %>%
  filter(!is.na(declaration_date)) %>%
  group_by(year, week) %>%
  summarize(
    n_disasters_week = n_distinct(disaster_number),
    n_major_week = n_distinct(disaster_number[incident_type %in%
      c("Hurricane", "Fire", "Flood", "Severe Storm(s)", "Tornado")]),
    .groups = "drop"
  )

write_csv(fema_quarterly, "../data/fema_quarterly.csv")
write_csv(fema_weekly, "../data/fema_weekly.csv")

cat("\nFEMA quarterly disaster counts range:",
    min(fema_quarterly$n_disasters), "-",
    max(fema_quarterly$n_disasters), "\n")

# --------------------------------------------------------------------------
# 4. Data Validation
# --------------------------------------------------------------------------
cat("\n=== Final Data Validation ===\n")

# SIR: Must have real data
stopifnot(nrow(sir) > 50000)
cat("✓ SIR:", nrow(sir), "records\n")

# QCEW: Must have employment data
stopifnot(nrow(qcew_clean) > 100)
cat("✓ QCEW:", nrow(qcew_clean), "records\n")

# FEMA: Must have disaster data
stopifnot(nrow(fema) > 100)
cat("✓ FEMA:", nrow(fema), "declarations\n")

# List all data files
cat("\nData files:\n")
data_files <- list.files("../data/", pattern = "\\.(csv|rds)$", full.names = TRUE)
for (f in data_files) {
  cat(sprintf("  %-40s %.1f MB\n", basename(f), file.size(f) / 1e6))
}

cat("\n=== Data fetch complete ===\n")
