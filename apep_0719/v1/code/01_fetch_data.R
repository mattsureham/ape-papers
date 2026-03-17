# 01_fetch_data.R — Fetch MLP linked panel data from Azure
# apep_0719: Alien Land Laws and Japanese Occupational Sorting

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Connect to Azure
con <- apep_azure_connect()

# ----- Define state treatment status -----
# Newly treated 1921-1923 (between 1920 and 1930 censuses):
# WA=53, TX=48, LA=22, NM=35, OR=41, ID=16, MT=30
newly_treated_fips <- c(53, 48, 22, 35, 41, 16, 30)

# Already treated by 1920:
# CA=6 (1913/1920), AZ=4 (1917)
already_treated_fips <- c(6, 4)

# Never-treated states (no ALL enacted):
# CO=8, UT=49, NY=36, IL=17, NV=32, WY=56, NE=31, OH=39, PA=42, MI=26, MA=25
never_treated_fips <- c(8, 49, 36, 17, 32, 56, 31, 39, 42, 26, 25)

# ----- Query 1920-1930 linked panel -----
cat("Querying 1920-1930 linked panel from Azure...\n")

# First check what columns are available
cols_query <- "SELECT column_name FROM information_schema.columns WHERE table_name = 'linked_1920_1930_view' LIMIT 50"
cols_result <- tryCatch({
  # Create view for Azure parquet
  dbExecute(con, "CREATE OR REPLACE VIEW linked_1920_1930_view AS
    SELECT * FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')")
  dbGetQuery(con, cols_query)
}, error = function(e) {
  cat("Error creating view. Trying direct query...\n")
  cat("Error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cols_result)) {
  cat("Available columns:\n")
  print(cols_result)
}

# Query Japanese individuals in relevant states
# RACE in full-count census: 4 = Chinese, 5 = Japanese
# Or RACED for detailed race codes
# BPL for birthplace (Japan = 50100 in IPUMS)
# For the linked panel, we need to check which race variable is available

# Try to get a sample to see column names
sample_query <- "SELECT * FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet') LIMIT 5"
sample_df <- tryCatch(
  dbGetQuery(con, sample_query),
  error = function(e) {
    cat("Error:", conditionMessage(e), "\n")
    NULL
  }
)

if (!is.null(sample_df)) {
  cat("\nSample columns:", paste(names(sample_df), collapse = ", "), "\n")
  cat("Sample rows:\n")
  print(head(sample_df))
}

# Query all Japanese individuals (RACE=5 in IPUMS) in relevant states
# Include both treatment waves and 1920/1930 census data
japanese_query <- sprintf("
  SELECT *
  FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
  WHERE race_1920 = 5
    AND statefip_1920 IN (%s)
",
  paste(c(newly_treated_fips, never_treated_fips), collapse = ",")
)

cat("\nFetching Japanese individuals...\n")
df_japanese <- tryCatch(
  dbGetQuery(con, japanese_query),
  error = function(e) {
    cat("Error fetching Japanese data:", conditionMessage(e), "\n")
    # Try alternative column names
    cat("Trying alternative query with lowercase columns...\n")
    alt_query <- sprintf("
      SELECT *
      FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
      WHERE race_1920 = 5
        AND statefip_1920 IN (%s)
    ", paste(c(newly_treated_fips, never_treated_fips), collapse = ","))
    dbGetQuery(con, alt_query)
  }
)

cat(sprintf("Japanese sample: %d individuals\n", nrow(df_japanese)))

# Query white subsample for placebo (random 2% of white workers in same states)
cat("\nFetching white worker placebo sample (2%% subsample)...\n")
white_query <- sprintf("
  SELECT *
  FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
  WHERE race_1920 = 1
    AND statefip_1920 IN (%s)
    AND random() < 0.02
",
  paste(c(newly_treated_fips, never_treated_fips), collapse = ",")
)

df_white <- tryCatch(
  dbGetQuery(con, white_query),
  error = function(e) {
    cat("Trying lowercase columns...\n")
    alt_query <- sprintf("
      SELECT *
      FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
      WHERE race_1920 = 1
        AND statefip_1920 IN (%s)
        AND random() < 0.02
    ", paste(c(newly_treated_fips, never_treated_fips), collapse = ","))
    dbGetQuery(con, alt_query)
  }
)

cat(sprintf("White placebo sample: %d individuals\n", nrow(df_white)))

# ----- Also fetch triple panel for persistence -----
cat("\nFetching 1920-1930-1940 triple panel (Japanese only)...\n")
triple_query <- sprintf("
  SELECT *
  FROM read_parquet('az://derived/mlp_panel/linked_1920_1930_1940.parquet')
  WHERE race_1920 = 5
    AND statefip_1920 IN (%s)
",
  paste(c(newly_treated_fips, never_treated_fips), collapse = ",")
)

df_triple <- tryCatch(
  dbGetQuery(con, triple_query),
  error = function(e) {
    cat("Trying lowercase columns...\n")
    alt_query <- sprintf("
      SELECT *
      FROM read_parquet('az://derived/mlp_panel/linked_1920_1930_1940.parquet')
      WHERE race_1920 = 5
        AND statefip_1920 IN (%s)
    ", paste(c(newly_treated_fips, never_treated_fips), collapse = ","))
    dbGetQuery(con, alt_query)
  }
)

cat(sprintf("Triple panel Japanese: %d individuals\n", nrow(df_triple)))

# ----- Save raw data -----
saveRDS(df_japanese, file.path(data_dir, "japanese_1920_1930.rds"))
saveRDS(df_white, file.path(data_dir, "white_placebo_1920_1930.rds"))
saveRDS(df_triple, file.path(data_dir, "japanese_triple_1920_1940.rds"))

# Save treatment assignment for reference
treatment_info <- list(
  newly_treated = newly_treated_fips,
  already_treated = already_treated_fips,
  never_treated = never_treated_fips
)
saveRDS(treatment_info, file.path(data_dir, "treatment_assignment.rds"))

apep_azure_disconnect(con)
cat("\nAll data fetched and saved.\n")
