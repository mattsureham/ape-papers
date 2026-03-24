# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for apep_0848
# =============================================================================

source("00_packages.R")

# --- Azure connection (always read from .env to avoid truncated env vars) ---
env_file <- normalizePath("../../../../.env", mustWork = TRUE)
lines <- readLines(env_file)
az_conn <- ""
for (line in lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", line)) {
    az_conn <- trimws(sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line))
    break
  }
}
stopifnot(nzchar(az_conn), nchar(az_conn) > 50)
message("Azure connection string: ", nchar(az_conn), " chars")

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, "CREATE SECRET az1 (TYPE azure, CONNECTION_STRING $1);",
          params = list(az_conn))
message("Azure secret created successfully.")

# --- eNLC treatment assignment ---
# Founding states (Jan 19, 2018): 25 states
# Later adopters: AL (2019Q3), IN (2020Q3), KS (2020Q3), WI (2021Q1), NJ (2021Q1), LA (2022Q1), OH (2023Q1)
# Never-adopted: CA, NY, IL, MI, OR, WA, CT, HI, AK, MN, MA (+ DC not in compact)

# FIPS codes for eNLC states
founding_fips <- c(
  "04", # AZ
  "05", # AR
  "08", # CO
  "10", # DE
  "12", # FL
  "13", # GA
  "16", # ID
  "19", # IA
  "21", # KY
  "23", # ME
  "24", # MD
  "28", # MS
  "29", # MO
  "30", # MT
  "31", # NE
  "33", # NH
  "35", # NM
  "37", # NC
  "38", # ND
  "40", # OK
  "45", # SC
  "46", # SD
  "47", # TN
  "48", # TX
  "49", # UT
  "51", # VA
  "54", # WV
  "56"  # WY
)

later_adopters <- data.frame(
  state_fips = c("01", "18", "20", "55", "34", "22", "39"),
  state_abbr = c("AL", "IN", "KS", "WI", "NJ", "LA", "OH"),
  adopt_year = c(2019, 2020, 2020, 2021, 2021, 2022, 2023),
  adopt_quarter = c(3, 3, 3, 1, 1, 1, 1),
  stringsAsFactors = FALSE
)

never_adopted_fips <- c(
  "06", # CA
  "36", # NY
  "17", # IL
  "26", # MI
  "41", # OR
  "53", # WA
  "09", # CT
  "15", # HI
  "02", # AK
  "27", # MN
  "25"  # MA
)

# All state FIPS we need
all_fips <- c(founding_fips, later_adopters$state_fips, never_adopted_fips)

# --- Fetch QWI data ---
# Healthcare: NAICS 621, 622, 623
# Placebo: NAICS 441-449 (retail trade subsectors), 721-722 (accommodation/food)
target_industries <- c("621", "622", "623",
                       "441", "442", "443", "444", "445", "446", "447", "448", "449",
                       "721", "722")

message("Fetching QWI sex×age, 3-digit NAICS from Azure...")

# Build SQL query to fetch all needed industries for all states
# QWI n3 parquet files are per-state: derived/qwi/sa/n3/{state}.parquet
qwi_query <- sprintf("
  SELECT
    CAST(geography AS VARCHAR) AS geography,
    CAST(industry AS VARCHAR) AS industry,
    year, quarter,
    CAST(sex AS VARCHAR) AS sex,
    CAST(agegrp AS VARCHAR) AS agegrp,
    \"Emp\", \"EmpEnd\", \"HirA\", \"HirN\", \"Sep\", \"EarnS\",
    \"FrmJbGn\", \"FrmJbLs\", \"TurnOvrS\"
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) IN (%s)
    AND year BETWEEN 2014 AND 2023
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(agegrp AS VARCHAR) = 'A00'
",
  paste0("'", target_industries, "'", collapse = ", ")
)

df_sa <- dbGetQuery(con, qwi_query)
message(sprintf("Fetched %s rows from QWI sa/n3", format(nrow(df_sa), big.mark = ",")))

stopifnot(nrow(df_sa) > 0)

# Also fetch sex×education for the education decomposition
message("Fetching QWI sex×education, 3-digit NAICS...")
qwi_se_query <- sprintf("
  SELECT
    CAST(geography AS VARCHAR) AS geography,
    CAST(industry AS VARCHAR) AS industry,
    year, quarter,
    CAST(sex AS VARCHAR) AS sex,
    CAST(education AS VARCHAR) AS education,
    \"Emp\", \"HirA\", \"HirN\", \"Sep\", \"EarnS\"
  FROM read_parquet('az://derived/qwi/se/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) IN (%s)
    AND year BETWEEN 2014 AND 2023
    AND CAST(sex AS VARCHAR) = '0'
",
  paste0("'", target_industries, "'", collapse = ", ")
)

df_se <- dbGetQuery(con, qwi_se_query)
message(sprintf("Fetched %s rows from QWI se/n3", format(nrow(df_se), big.mark = ",")))

stopifnot(nrow(df_se) > 0)

dbDisconnect(con, shutdown = TRUE)

# --- Save raw data ---
saveRDS(df_sa, "../data/qwi_sa_raw.rds")
saveRDS(df_se, "../data/qwi_se_raw.rds")

# Save treatment assignment
treatment <- data.frame(
  state_fips = c(founding_fips, later_adopters$state_fips, never_adopted_fips),
  group = c(
    rep("founding", length(founding_fips)),
    rep("later", nrow(later_adopters)),
    rep("never", length(never_adopted_fips))
  ),
  stringsAsFactors = FALSE
)

# Merge in adoption timing
# Founding states: all adopted 2018Q1
treatment$adopt_yearqtr <- NA_real_
treatment$adopt_yearqtr[treatment$group == "founding"] <- 2018 + (1 - 1) / 4  # 2018.00
for (i in seq_len(nrow(later_adopters))) {
  idx <- treatment$state_fips == later_adopters$state_fips[i]
  treatment$adopt_yearqtr[idx] <- later_adopters$adopt_year[i] +
    (later_adopters$adopt_quarter[i] - 1) / 4
}
# Never-adopted: Inf (no treatment)
treatment$adopt_yearqtr[treatment$group == "never"] <- Inf

saveRDS(treatment, "../data/treatment_assignment.rds")

message("Data fetch complete.")
message(sprintf("  SA rows: %s", format(nrow(df_sa), big.mark = ",")))
message(sprintf("  SE rows: %s", format(nrow(df_se), big.mark = ",")))
message(sprintf("  States in treatment file: %d", nrow(treatment)))
