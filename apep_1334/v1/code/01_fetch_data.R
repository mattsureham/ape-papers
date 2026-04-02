##############################################################################
# 01_fetch_data.R — Fetch patent examination + assignment data from BigQuery
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

library(bigrquery)
library(DBI)
library(arrow)

# Authenticate via ADC
bq_auth(path = "~/.config/gcloud/application_default_credentials.json")
project_id <- "scl-librechat"

cat("=== Fetching Patent Application Data from BigQuery ===\n")

# -----------------------------------------------------------------------
# Step 1: Fetch resolved applications with examiner data
# -----------------------------------------------------------------------
# PatEx: application_data contains examiner_id, disposal_type, art_unit
app_query <- "
SELECT
  application_number,
  filing_date,
  disposal_type,
  examiner_id,
  examiner_art_unit,
  uspc_class,
  uspc_subclass,
  patent_number,
  small_entity_indicator,
  EXTRACT(YEAR FROM filing_date) AS filing_year
FROM `patents-public-data.uspto_oce_pair.application_data`
WHERE disposal_type IN ('ISS', 'ABN')
  AND examiner_id IS NOT NULL
  AND examiner_art_unit IS NOT NULL
  AND filing_date IS NOT NULL
  AND EXTRACT(YEAR FROM filing_date) BETWEEN 2000 AND 2016
"

cat("Querying application data...\n")
app_result <- bq_project_query(project_id, app_query)
cat("Downloading application data...\n")
apps <- bq_table_download(app_result, bigint = "integer64")
cat(sprintf("  Applications fetched: %s rows\n", format(nrow(apps), big.mark = ",")))

if (nrow(apps) < 100000) {
  stop("FATAL: Expected millions of applications, got ", nrow(apps), ". Data fetch failed.")
}

# -----------------------------------------------------------------------
# Step 2: Fetch assignment records
# -----------------------------------------------------------------------
# Check available assignment tables first
cat("\n=== Fetching Assignment Data from BigQuery ===\n")

# The assignment data may be in different table names. Try the documented path.
assignment_query <- "
SELECT
  a.application_number_text AS application_number,
  a.conveyance_text,
  a.recorded_date,
  a.employer_assign_flag
FROM `patents-public-data.uspto_oce_assignment.assignment` a
WHERE a.application_number_text IS NOT NULL
"

tryCatch({
  cat("Querying assignment data (primary path)...\n")
  assign_result <- bq_project_query(project_id, assignment_query)
  assignments <- bq_table_download(assign_result, bigint = "integer64")
  cat(sprintf("  Assignments fetched: %s rows\n", format(nrow(assignments), big.mark = ",")))
}, error = function(e) {
  cat("Primary assignment path failed:", conditionMessage(e), "\n")
  cat("Trying alternative table paths...\n")

  # Try alternative: patents-public-data.patents.publications has some assignment data
  # Or the assignment data may be under a different dataset
  alt_query <- "
  SELECT table_name
  FROM `patents-public-data.INFORMATION_SCHEMA.TABLES`
  WHERE table_name LIKE '%assign%'
  "
  tryCatch({
    alt_result <- bq_project_query(project_id, alt_query)
    alt_tables <- bq_table_download(alt_result)
    cat("Available assignment-related tables:\n")
    print(alt_tables)
  }, error = function(e2) {
    cat("Schema query also failed:", conditionMessage(e2), "\n")
  })

  stop("Cannot fetch assignment data. Aborting.")
})

if (nrow(assignments) < 100000) {
  stop("FATAL: Expected millions of assignments, got ", nrow(assignments), ". Data fetch failed.")
}

# -----------------------------------------------------------------------
# Step 3: Classify conveyance types
# -----------------------------------------------------------------------
cat("\n=== Classifying Conveyance Types ===\n")

assignments$conveyance_type <- "other"
assignments$conveyance_type[grepl("ASSIGN", assignments$conveyance_text, ignore.case = TRUE) &
                            !grepl("SECUR", assignments$conveyance_text, ignore.case = TRUE)] <- "assignment"
assignments$conveyance_type[grepl("SECUR|LIEN|MORTGAGE", assignments$conveyance_text, ignore.case = TRUE)] <- "security"
assignments$conveyance_type[grepl("MERGER|MERGE", assignments$conveyance_text, ignore.case = TRUE)] <- "merger"
assignments$conveyance_type[grepl("RELEASE|LIEN RELEASE", assignments$conveyance_text, ignore.case = TRUE)] <- "release"

cat("Conveyance type distribution:\n")
print(table(assignments$conveyance_type))

# -----------------------------------------------------------------------
# Step 4: Collapse to application level (any market event)
# -----------------------------------------------------------------------
cat("\n=== Collapsing to application level ===\n")

# For each application: was it ever assigned, collateralized, merged?
app_assign <- assignments |>
  dplyr::group_by(application_number) |>
  dplyr::summarise(
    has_any_assignment = any(conveyance_type == "assignment"),
    has_security = any(conveyance_type == "security"),
    has_merger = any(conveyance_type == "merger"),
    n_conveyances = dplyr::n(),
    .groups = "drop"
  )

cat(sprintf("  Unique applications with assignment records: %s\n",
            format(nrow(app_assign), big.mark = ",")))

# -----------------------------------------------------------------------
# Step 5: Merge applications with assignment outcomes
# -----------------------------------------------------------------------
cat("\n=== Merging applications with assignment outcomes ===\n")

df <- merge(apps, app_assign, by = "application_number", all.x = TRUE)

# Applications without assignment records: no market activity
df$has_any_assignment[is.na(df$has_any_assignment)] <- FALSE
df$has_security[is.na(df$has_security)] <- FALSE
df$has_merger[is.na(df$has_merger)] <- FALSE
df$n_conveyances[is.na(df$n_conveyances)] <- 0

# Create key outcome variables
df$granted <- as.integer(df$disposal_type == "ISS")
df$market_transfer <- as.integer(df$has_any_assignment)
df$collateralized <- as.integer(df$has_security)
df$small_entity <- as.integer(df$small_entity_indicator == "YES")
df$small_entity[is.na(df$small_entity_indicator)] <- NA

cat(sprintf("  Final merged dataset: %s rows\n", format(nrow(df), big.mark = ",")))
cat(sprintf("  Granted: %s (%.1f%%)\n",
            format(sum(df$granted), big.mark = ","),
            100 * mean(df$granted)))
cat(sprintf("  Market transfer (any assignment): %s (%.1f%%)\n",
            format(sum(df$market_transfer), big.mark = ","),
            100 * mean(df$market_transfer)))
cat(sprintf("  Among granted: %.1f%%\n", 100 * mean(df$market_transfer[df$granted == 1])))
cat(sprintf("  Among abandoned: %.1f%%\n", 100 * mean(df$market_transfer[df$granted == 0])))

# -----------------------------------------------------------------------
# Step 6: Save
# -----------------------------------------------------------------------
cat("\n=== Saving data ===\n")
write_parquet(df, "data/patent_market_data.parquet")
cat("Saved data/patent_market_data.parquet\n")

cat("\n=== Data fetch complete ===\n")
