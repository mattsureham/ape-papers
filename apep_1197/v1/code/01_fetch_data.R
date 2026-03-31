## 01_fetch_data.R — Fetch MLP linked panel from Azure (1900-1910 census)
## Strategy: DuckDB queries against Azure Parquet files
##   - MLP crosswalk links individuals across 1900 and 1910 censuses
##   - Join with full-count census files for characteristics
##   - Filter to prime-age men (18-50 in 1900)
##   - Save individual-level panel

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Step 0: Connect to Azure and check data availability
# ============================================================================
cat("=== Connecting to Azure ===\n")
con <- apep_azure_connect()

# Check MLP crosswalk schema
cat("\n--- MLP Crosswalk schema ---\n")
mlp_schema <- dbGetQuery(con, "
  SELECT * FROM 'az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet' LIMIT 5
")
cat("Columns:", paste(names(mlp_schema), collapse = ", "), "\n")
cat("Sample rows:\n")
print(mlp_schema)

# Check what census files exist
cat("\n--- Checking census files on Azure ---\n")
files_1900 <- tryCatch(
  dbGetQuery(con, "SELECT file_name FROM glob('az://raw/ipums_fullcount/us1900*')"),
  error = function(e) { cat("1900 glob error:", e$message, "\n"); NULL }
)
if (!is.null(files_1900)) cat("1900 files:", paste(files_1900$file_name, collapse = ", "), "\n")

files_1910 <- tryCatch(
  dbGetQuery(con, "SELECT file_name FROM glob('az://raw/ipums_fullcount/us1910*')"),
  error = function(e) { cat("1910 glob error:", e$message, "\n"); NULL }
)
if (!is.null(files_1910)) cat("1910 files:", paste(files_1910$file_name, collapse = ", "), "\n")

# Also check if there are other files in the fullcount directory
files_all <- tryCatch(
  dbGetQuery(con, "SELECT file_name FROM glob('az://raw/ipums_fullcount/*')"),
  error = function(e) { cat("Fullcount glob error:", e$message, "\n"); NULL }
)
if (!is.null(files_all)) {
  cat("All fullcount files:\n")
  print(files_all)
}

# Check 1900 census schema
cat("\n--- 1900 Census schema ---\n")
census_1900_schema <- tryCatch(
  dbGetQuery(con, "SELECT * FROM 'az://raw/ipums_fullcount/us1900m.parquet' LIMIT 3"),
  error = function(e) { cat("Error:", e$message, "\n"); NULL }
)
if (!is.null(census_1900_schema)) {
  cat("1900 columns:", paste(names(census_1900_schema), collapse = ", "), "\n")
}

# Check 1910 census schema (try different filename patterns)
cat("\n--- 1910 Census schema ---\n")
census_1910_schema <- tryCatch(
  dbGetQuery(con, "SELECT * FROM 'az://raw/ipums_fullcount/us1910m.parquet' LIMIT 3"),
  error = function(e) {
    cat("us1910m.parquet not found, trying alternatives...\n")
    # Try other possible names
    for (nm in c("us1910m_usa.parquet", "us1910.parquet", "usa1910m.parquet")) {
      result <- tryCatch(
        dbGetQuery(con, sprintf("SELECT * FROM 'az://raw/ipums_fullcount/%s' LIMIT 3", nm)),
        error = function(e2) NULL
      )
      if (!is.null(result)) {
        cat("Found as:", nm, "\n")
        return(result)
      }
    }
    NULL
  }
)
if (!is.null(census_1910_schema)) {
  cat("1910 columns:", paste(names(census_1910_schema), collapse = ", "), "\n")
}

# Determine actual file paths
path_1900 <- "az://raw/ipums_fullcount/us1900m.parquet"
# Determine 1910 path
path_1910 <- NULL
for (candidate in c("az://raw/ipums_fullcount/us1910m.parquet",
                     "az://raw/ipums_fullcount/us1910m_usa.parquet",
                     "az://raw/ipums_fullcount/us1910.parquet")) {
  check <- tryCatch({
    dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM '%s' LIMIT 1", candidate))
    candidate
  }, error = function(e) NULL)
  if (!is.null(check)) {
    path_1910 <- check
    break
  }
}
cat("\n1900 path:", path_1900, "\n")
cat("1910 path:", ifelse(is.null(path_1910), "NOT FOUND", path_1910), "\n")

# Save schema info for debugging
saveRDS(list(
  mlp_cols = names(mlp_schema),
  mlp_sample = mlp_schema,
  census_1900_cols = if (!is.null(census_1900_schema)) names(census_1900_schema) else NULL,
  census_1910_cols = if (!is.null(census_1910_schema)) names(census_1910_schema) else NULL,
  path_1900 = path_1900,
  path_1910 = path_1910
), file.path(data_dir, "schema_info.rds"))

# ============================================================================
# Step 1: Identify MLP crosswalk column names
# ============================================================================
# The crosswalk links individuals between censuses.
# Expected columns: some form of histid for 1900 and 1910
mlp_cols <- names(mlp_schema)
cat("\nMLP columns:", paste(mlp_cols, collapse = ", "), "\n")

# Find the histid columns (case-insensitive search)
histid_cols <- mlp_cols[grepl("histid|HISTID|hist_id|serialp|serial", mlp_cols, ignore.case = TRUE)]
cat("Potential ID columns:", paste(histid_cols, collapse = ", "), "\n")

# Identify which column is 1900 and which is 1910
# Common patterns: histid_1, histid_2, histid1900, histid1910, HISTID_A, HISTID_B
id_1900 <- NULL
id_1910 <- NULL

for (col in mlp_cols) {
  col_lower <- tolower(col)
  if (grepl("1900|_1$|_a$|histid$", col_lower) && is.null(id_1900)) id_1900 <- col
  if (grepl("1910|_2$|_b$", col_lower) && is.null(id_1910)) id_1910 <- col
}

# Fallback: if only HISTID exists, check if there are year-specific variants
if (is.null(id_1900) || is.null(id_1910)) {
  cat("WARNING: Could not auto-detect ID columns. Manual inspection needed.\n")
  cat("All columns and first values:\n")
  for (col in mlp_cols) {
    cat(sprintf("  %s: %s\n", col, paste(head(mlp_schema[[col]], 3), collapse = ", ")))
  }
}

cat("\nUsing ID columns:\n")
cat("  1900 ID:", ifelse(is.null(id_1900), "NOT FOUND", id_1900), "\n")
cat("  1910 ID:", ifelse(is.null(id_1910), "NOT FOUND", id_1910), "\n")

# ============================================================================
# Step 2: Count records in each dataset
# ============================================================================
cat("\n=== Record counts ===\n")
mlp_count <- dbGetQuery(con, "
  SELECT COUNT(*) as n FROM 'az://raw/ipums_fullcount/../ipums_mlp/v2/mlp_crosswalk_v2.parquet'
")
# Simpler:
mlp_count <- dbGetQuery(con, "
  SELECT COUNT(*) as n FROM 'az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet'
")
cat("MLP crosswalk records:", formatC(mlp_count$n, big.mark = ","), "\n")

census_1900_count <- dbGetQuery(con, sprintf(
  "SELECT COUNT(*) as n FROM '%s'", path_1900
))
cat("1900 census records:", formatC(census_1900_count$n, big.mark = ","), "\n")

if (!is.null(path_1910)) {
  census_1910_count <- dbGetQuery(con, sprintf(
    "SELECT COUNT(*) as n FROM '%s'", path_1910
  ))
  cat("1910 census records:", formatC(census_1910_count$n, big.mark = ","), "\n")
}

# ============================================================================
# Step 3: Build the linked panel via DuckDB join on Azure
# ============================================================================
cat("\n=== Building linked panel (this may take a while) ===\n")

# Determine census column names (handle case sensitivity)
# IPUMS typically uses uppercase: HISTID, AGE, SEX, RACE, etc.
# Check actual case from schema
c1900_cols <- names(census_1900_schema)
c1910_cols <- if (!is.null(census_1910_schema)) names(census_1910_schema) else c1900_cols

# Helper: find column name case-insensitively
find_col <- function(cols, target) {
  match <- cols[tolower(cols) == tolower(target)]
  if (length(match) > 0) return(match[1])
  return(target)  # fallback to target as-is
}

# Build column references for 1900
h1900 <- find_col(c1900_cols, "HISTID")
age1900 <- find_col(c1900_cols, "AGE")
sex1900 <- find_col(c1900_cols, "SEX")
race1900 <- find_col(c1900_cols, "RACE")
nativity1900 <- find_col(c1900_cols, "NATIVITY")
lit1900 <- find_col(c1900_cols, "LIT")
occ1950_1900 <- find_col(c1900_cols, "OCC1950")
occscore1900 <- find_col(c1900_cols, "OCCSCORE")
ind1950_1900 <- find_col(c1900_cols, "IND1950")
statefip1900 <- find_col(c1900_cols, "STATEFIP")
county1900 <- find_col(c1900_cols, "COUNTYICP")
marst1900 <- find_col(c1900_cols, "MARST")
farm1900 <- find_col(c1900_cols, "FARM")

# Check for OWNERSHP in census columns
ownershp1900 <- find_col(c1900_cols, "OWNERSHP")
ownershp1910 <- find_col(c1910_cols, "OWNERSHP")

# Check what columns exist for ownership
cat("Checking for ownership columns...\n")
cat("  1900 cols matching 'own':", paste(c1900_cols[grepl("own", c1900_cols, ignore.case = TRUE)], collapse = ", "), "\n")
if (!is.null(census_1910_schema)) {
  cat("  1910 cols matching 'own':", paste(c1910_cols[grepl("own", c1910_cols, ignore.case = TRUE)], collapse = ", "), "\n")
}

# Also check for urban/rural
urban1900 <- find_col(c1900_cols, "URBAN")
cat("  1900 cols matching 'urban':", paste(c1900_cols[grepl("urban", c1900_cols, ignore.case = TRUE)], collapse = ", "), "\n")

# Build the big join query
# Strategy: Join MLP crosswalk with both census years in one SQL query
# Filter prime-age men (18-50) in 1900 in the query itself

# Determine ownership column availability
has_ownershp_1900 <- tolower(ownershp1900) %in% tolower(c1900_cols)
has_ownershp_1910 <- !is.null(census_1910_schema) && tolower(ownershp1910) %in% tolower(c1910_cols)

# Build SELECT clause for 1900
select_1900 <- sprintf(
  "c00.%s AS histid_1900,
   c00.%s AS age_1900,
   c00.%s AS sex_1900,
   c00.%s AS race_1900,
   c00.%s AS nativity_1900,
   c00.%s AS lit_1900,
   c00.%s AS occ1950_1900,
   c00.%s AS occscore_1900,
   c00.%s AS ind1950_1900,
   c00.%s AS statefip_1900,
   c00.%s AS county_1900,
   c00.%s AS marst_1900,
   c00.%s AS farm_1900",
  h1900, age1900, sex1900, race1900, nativity1900, lit1900,
  occ1950_1900, occscore1900, ind1950_1900, statefip1900,
  county1900, marst1900, farm1900
)
if (has_ownershp_1900) {
  select_1900 <- paste0(select_1900, sprintf(",\n   c00.%s AS ownershp_1900", ownershp1900))
}

# Build SELECT clause for 1910
h1910 <- find_col(c1910_cols, "HISTID")
select_1910 <- sprintf(
  "c10.%s AS histid_1910,
   c10.%s AS age_1910,
   c10.%s AS occ1950_1910,
   c10.%s AS occscore_1910,
   c10.%s AS ind1950_1910,
   c10.%s AS statefip_1910,
   c10.%s AS county_1910,
   c10.%s AS marst_1910,
   c10.%s AS farm_1910,
   c10.%s AS lit_1910",
  h1910,
  find_col(c1910_cols, "AGE"),
  find_col(c1910_cols, "OCC1950"),
  find_col(c1910_cols, "OCCSCORE"),
  find_col(c1910_cols, "IND1950"),
  find_col(c1910_cols, "STATEFIP"),
  find_col(c1910_cols, "COUNTYICP"),
  find_col(c1910_cols, "MARST"),
  find_col(c1910_cols, "FARM"),
  find_col(c1910_cols, "LIT")
)
if (has_ownershp_1910) {
  select_1910 <- paste0(select_1910, sprintf(",\n   c10.%s AS ownershp_1910", ownershp1910))
}

if (!is.null(path_1910)) {
  # Full join query: MLP crosswalk -> 1900 census -> 1910 census
  query <- sprintf("
    SELECT
      %s,
      %s
    FROM 'az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet' AS mlp
    INNER JOIN '%s' AS c00
      ON mlp.%s = c00.%s
    INNER JOIN '%s' AS c10
      ON mlp.%s = c10.%s
    WHERE c00.%s >= 18 AND c00.%s <= 50
      AND c00.%s = 1
  ",
    select_1900, select_1910,
    path_1900, id_1900, h1900,
    path_1910, id_1910, h1910,
    age1900, age1900,
    sex1900  # SEX=1 is male in IPUMS
  )

  cat("Running join query...\n")
  cat("Query:\n", query, "\n")

  panel <- dbGetQuery(con, query)
  cat("Panel rows:", formatC(nrow(panel), big.mark = ","), "\n")
  cat("Panel columns:", paste(names(panel), collapse = ", "), "\n")

} else {
  # If 1910 census not available, try a two-step approach
  cat("WARNING: 1910 census file not found on Azure.\n")
  cat("Attempting to build panel with MLP crosswalk + 1900 census only,\n")
  cat("then see if 1910 data is embedded in MLP crosswalk.\n")

  # Check if MLP crosswalk already contains census variables
  cat("\nAll MLP columns:\n")
  for (col in mlp_cols) {
    vals <- mlp_schema[[col]]
    cat(sprintf("  %s: %s (class: %s)\n", col, paste(head(vals, 3), collapse=", "), class(vals)))
  }

  stop("Cannot build panel without 1910 census data. Check Azure storage.")
}

# ============================================================================
# Step 4: Save panel
# ============================================================================
cat("\n=== Saving panel ===\n")

# Convert to data.table for efficiency
panel <- as.data.table(panel)

# Basic quality checks
cat("Age range (1900):", range(panel$age_1900), "\n")
cat("Sex (1900):", table(panel$sex_1900), "\n")
cat("States represented:", length(unique(panel$statefip_1900)), "\n")
cat("Occscore range (1900):", range(panel$occscore_1900, na.rm = TRUE), "\n")
cat("Occscore range (1910):", range(panel$occscore_1910, na.rm = TRUE), "\n")

# Summary of key variables
cat("\nOccscore 1900 summary:\n")
print(summary(panel$occscore_1900))
cat("\nOccscore 1910 summary:\n")
print(summary(panel$occscore_1910))

saveRDS(panel, file.path(data_dir, "mlp_panel.rds"))

cat("\nPanel saved:", formatC(nrow(panel), big.mark = ","), "prime-age men linked 1900-1910\n")

# Disconnect
dbDisconnect(con, shutdown = TRUE)
cat("Done.\n")
