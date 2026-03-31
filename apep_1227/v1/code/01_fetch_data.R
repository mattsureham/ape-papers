# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure + construct treatment timing
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# --- Connect to Azure (manual to avoid library path issues) ---
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("AZURE_STORAGE_CONNECTION_STRING", lines, value = TRUE)
cs <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
DBI::dbExecute(con, sprintf("CREATE SECRET (TYPE azure, CONNECTION_STRING '%s');", cs))
cat("Connected to Azure.\n")

# --- Define industries of interest ---
# Licensed: Construction (23), Health Care (62), Other Services (81)
# Placebo (low licensing): Retail (44-45), Accommodation/Food (72), Manufacturing (31-33)
industries <- c("23", "62", "81", "44-45", "72", "31-33")

# State abbreviations (lowercase, matching Azure blob naming)
all_states <- c(
  "al", "ak", "az", "ar", "ca", "co", "ct", "de", "dc", "fl",
  "ga", "hi", "id", "il", "in", "ia", "ks", "ky", "la", "me",
  "md", "ma", "mi", "mn", "ms", "mo", "mt", "ne", "nv", "nh",
  "nj", "nm", "ny", "nc", "nd", "oh", "ok", "or", "pa", "ri",
  "sc", "sd", "tn", "tx", "ut", "vt", "va", "wa", "wv", "wi",
  "wy"
)

cat("Fetching QWI race×ethnicity data from Azure...\n")

# Query each state file individually (wildcard * doesn't work with this Azure setup)
qwi_list <- list()
for (st in all_states) {
  tryCatch({
    q <- sprintf("
      SELECT
        CAST(geography / 1000 AS INTEGER) AS state_fips,
        year,
        quarter,
        industry,
        ethnicity,
        SUM(Emp) AS Emp,
        SUM(EmpS) AS EmpS,
        SUM(HirA) AS HirA,
        SUM(CASE WHEN Emp > 0 THEN Emp * EarnS ELSE 0 END) / NULLIF(SUM(CASE WHEN Emp > 0 AND EarnS > 0 THEN Emp ELSE 0 END), 0) AS EarnS,
        SUM(EmpEnd) AS EmpEnd,
        SUM(Sep) AS Sep
      FROM 'az://derived/qwi/rh/ns/%s.parquet'
      WHERE industry IN (%s)
        AND ethnicity IN ('A1', 'A2')
        AND race = 'A0'
        AND sex = 0
        AND agegrp = 'A00'
        AND geo_level = 'C'
        AND year >= 2009
        AND year <= 2025
      GROUP BY state_fips, year, quarter, industry, ethnicity
    ", st, paste0("'", industries, "'", collapse = ", "))
    df <- DBI::dbGetQuery(con, q)
    qwi_list[[st]] <- df
    cat(sprintf("  %s: %d rows\n", toupper(st), nrow(df)))
  }, error = function(e) {
    cat(sprintf("  %s: FAILED - %s\n", toupper(st), substr(e$message, 1, 80)))
  })
}

qwi_raw <- rbindlist(qwi_list, use.names = TRUE)

cat(sprintf("\nTotal rows: %s\n", format(nrow(qwi_raw), big.mark = ",")))
cat(sprintf("States: %d\n", length(unique(qwi_raw$state_fips))))
cat(sprintf("Year range: %d-%d\n", min(qwi_raw$year), max(qwi_raw$year)))
cat(sprintf("Industries: %s\n", paste(sort(unique(qwi_raw$industry)), collapse = ", ")))
cat(sprintf("Ethnicity groups: %s\n", paste(unique(qwi_raw$ethnicity), collapse = ", ")))

# Validate: no empty result
stopifnot("QWI query returned empty data" = nrow(qwi_raw) > 0)
stopifnot("Missing ethnicity groups" = all(c("A1", "A2") %in% qwi_raw$ethnicity))

# --- Construct treatment timing ---
# Universal license recognition laws — state enactment dates
# Sources: Institute for Justice legislative tracker, Goldwater Institute tracker,
#          CSOR WVU 2024 survey, state session laws
treatment_df <- data.frame(
  state_fips = c(
    4,   # Arizona — HB 2569, signed Apr 2019, effective Sep 2019
    30,  # Montana — HB 279, signed Mar 2019
    42,  # Pennsylvania — SB 534, signed Jul 2019
    49,  # Utah — HB 288, signed Mar 2020
    12,  # Florida — SB 1336, signed Jun 2020
    29,  # Missouri — SB 600, signed Jul 2020
    19,  # Iowa — HF 2627, signed Jun 2020
    16,  # Idaho — HB 241, signed Mar 2020
    28,  # Mississippi — HB 1263, signed Mar 2020
    20,  # Kansas — SB 66, signed Apr 2021
    56,  # Wyoming — HB 129, signed Mar 2021
    34,  # New Jersey — S3617, signed Jan 2021
    8,   # Colorado — SB 21-077, signed May 2021
    55,  # Wisconsin — AB 48, signed Jul 2021
    54,  # West Virginia — HB 2006, signed Feb 2021
    38,  # North Dakota — SB 2084, signed Apr 2021
    39,  # Ohio — SB 131, signed Jan 2022
    5,   # Arkansas — SB 439, signed Apr 2021
    13,  # Georgia — HB 1095, signed May 2022
    18,  # Indiana — HB 1236, signed Mar 2022
    22,  # Louisiana — HB 448, signed Jun 2022
    31,  # Nebraska — LB 890, signed Apr 2022
    51   # Virginia — HB 2045, signed Mar 2023
  ),
  treat_year = c(
    2019, 2019, 2019,
    2020, 2020, 2020, 2020, 2020, 2020,
    2021, 2021, 2021, 2021, 2021, 2021, 2021,
    2022, 2021, 2022, 2022, 2022, 2022,
    2023
  ),
  treat_quarter = c(
    3, 2, 3,
    1, 2, 3, 2, 1, 1,
    2, 1, 1, 2, 3, 1, 2,
    1, 2, 2, 1, 2, 2,
    1
  ),
  state_abbr = c(
    "AZ", "MT", "PA",
    "UT", "FL", "MO", "IA", "ID", "MS",
    "KS", "WY", "NJ", "CO", "WI", "WV", "ND",
    "OH", "AR", "GA", "IN", "LA", "NE",
    "VA"
  ),
  stringsAsFactors = FALSE
)

cat(sprintf("\nTreatment states: %d\n", nrow(treatment_df)))
cat(sprintf("Control states: %d\n",
    length(unique(qwi_raw$state_fips)) - nrow(treatment_df)))
cat(sprintf("Cohorts: 2019=%d, 2020=%d, 2021=%d, 2022=%d, 2023=%d\n",
    sum(treatment_df$treat_year == 2019),
    sum(treatment_df$treat_year == 2020),
    sum(treatment_df$treat_year == 2021),
    sum(treatment_df$treat_year == 2022),
    sum(treatment_df$treat_year == 2023)))

# Save treatment timing
saveRDS(treatment_df, "../data/treatment_timing.rds")

# --- Merge treatment with QWI ---
qwi_dt <- as.data.table(qwi_raw)

# Create year-quarter variable
qwi_dt[, yq := year + (quarter - 1) / 4]

# Merge treatment timing
qwi_dt <- merge(qwi_dt, treatment_df[, c("state_fips", "treat_year", "treat_quarter")],
                by = "state_fips", all.x = TRUE)

# Create treatment indicators
qwi_dt[, treat_yq := ifelse(!is.na(treat_year),
                             treat_year + (treat_quarter - 1) / 4, Inf)]
qwi_dt[, post := as.integer(yq >= treat_yq)]
qwi_dt[, treated_state := as.integer(!is.na(treat_year))]
qwi_dt[, hispanic := as.integer(ethnicity == "A2")]

# Create log earnings (primary outcome)
qwi_dt[, log_earn := log(EarnS)]
# Drop cells with missing/zero earnings
qwi_dt <- qwi_dt[!is.na(EarnS) & EarnS > 0]

# State FIPS to name lookup
state_fips_names <- c(
  "1"="Alabama", "2"="Alaska", "4"="Arizona", "5"="Arkansas",
  "6"="California", "8"="Colorado", "9"="Connecticut", "10"="Delaware",
  "11"="DC", "12"="Florida", "13"="Georgia", "15"="Hawaii",
  "16"="Idaho", "17"="Illinois", "18"="Indiana", "19"="Iowa",
  "20"="Kansas", "21"="Kentucky", "22"="Louisiana", "23"="Maine",
  "24"="Maryland", "25"="Massachusetts", "26"="Michigan", "27"="Minnesota",
  "28"="Mississippi", "29"="Missouri", "30"="Montana", "31"="Nebraska",
  "32"="Nevada", "33"="New Hampshire", "34"="New Jersey", "35"="New Mexico",
  "36"="New York", "37"="North Carolina", "38"="North Dakota", "39"="Ohio",
  "40"="Oklahoma", "41"="Oregon", "42"="Pennsylvania", "44"="Rhode Island",
  "45"="South Carolina", "46"="South Dakota", "47"="Tennessee", "48"="Texas",
  "49"="Utah", "50"="Vermont", "51"="Virginia", "53"="Washington",
  "54"="West Virginia", "55"="Wisconsin", "56"="Wyoming"
)
qwi_dt[, state_name := state_fips_names[as.character(state_fips)]]

cat(sprintf("\nPanel dimensions:\n"))
cat(sprintf("  Total rows: %s\n", format(nrow(qwi_dt), big.mark = ",")))
cat(sprintf("  Treated state cells: %s\n",
    format(sum(qwi_dt$treated_state == 1), big.mark = ",")))
cat(sprintf("  Control state cells: %s\n",
    format(sum(qwi_dt$treated_state == 0), big.mark = ",")))
cat(sprintf("  Quarters: %d\n", length(unique(qwi_dt$yq))))

# Save merged panel
saveRDS(qwi_dt, "../data/qwi_panel.rds")
cat("\nData saved to data/qwi_panel.rds\n")

DBI::dbDisconnect(con, shutdown = TRUE)
cat("Done.\n")
