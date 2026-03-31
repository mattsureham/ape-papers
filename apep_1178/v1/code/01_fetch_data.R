# ==============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for CRNA opt-out analysis
# ==============================================================================

source("00_packages.R")

# Load connection string directly from .env (shell may truncate at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# --------------------------------------------------------------------------
# 1. Query QWI: sex × education, 3-digit NAICS, all states
#    Industries: 621 (Ambulatory), 622 (Hospitals), 623 (Nursing/Residential)
# --------------------------------------------------------------------------

cat("Querying QWI sex × education × 3-digit NAICS from Azure...\n")

qwi_raw <- dbGetQuery(con, "
  SELECT
    geography,
    year,
    quarter,
    sex,
    education,
    industry,
    Emp,
    EmpEnd,
    HirA,
    Sep,
    EarnS,
    FrmJbGn,
    FrmJbLs
  FROM 'az://derived/qwi/se/n3/*.parquet'
  WHERE industry IN ('621', '622', '623')
    AND year >= 1998
    AND year <= 2024
")

cat(sprintf("Raw QWI rows: %s\n", format(nrow(qwi_raw), big.mark = ",")))

apep_azure_disconnect(con)

# --------------------------------------------------------------------------
# 2. Derive state FIPS from geography (first 2 digits of 5-digit FIPS)
# --------------------------------------------------------------------------

qwi_raw$state_fips <- substr(sprintf("%05d", as.integer(qwi_raw$geography)), 1, 2)

# Drop national totals (state_fips "00") and territory codes
qwi_raw <- qwi_raw[qwi_raw$state_fips != "00", ]

# --------------------------------------------------------------------------
# 3. Aggregate to state level (sum employment, weighted-mean earnings)
#    State-level rows (geography ending in 000) may exist; aggregate all
# --------------------------------------------------------------------------

cat("Aggregating to state × quarter × education × industry...\n")

# Remove rows where Emp or EarnS is NA before aggregation
qwi_raw$Emp[is.na(qwi_raw$Emp)] <- 0
qwi_raw$EarnS[is.na(qwi_raw$EarnS)] <- 0

qwi_state <- qwi_raw %>%
  group_by(state_fips, year, quarter, sex, education, industry) %>%
  summarise(
    EarnS   = weighted.mean(EarnS, w = pmax(Emp, 0.01)),
    Emp     = sum(Emp, na.rm = TRUE),
    EmpEnd  = sum(EmpEnd, na.rm = TRUE),
    HirA    = sum(HirA, na.rm = TRUE),
    Sep     = sum(Sep, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("State-level rows: %s\n", format(nrow(qwi_state), big.mark = ",")))

# --------------------------------------------------------------------------
# 4. State FIPS to abbreviation mapping
# --------------------------------------------------------------------------

state_map <- data.frame(
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  stringsAsFactors = FALSE
)

qwi_state <- merge(qwi_state, state_map, by = "state_fips", all.x = TRUE)

# Drop observations with no state match (territories)
qwi_state <- qwi_state[!is.na(qwi_state$state_abbr), ]

# --------------------------------------------------------------------------
# 5. Save raw fetched data
# --------------------------------------------------------------------------

saveRDS(qwi_state, "../data/qwi_state_raw.rds")
cat(sprintf("Saved qwi_state_raw.rds: %s rows, %d states\n",
            format(nrow(qwi_state), big.mark = ","),
            length(unique(qwi_state$state_abbr))))

# --------------------------------------------------------------------------
# 6. Validate data
# --------------------------------------------------------------------------

stopifnot("No rows returned" = nrow(qwi_state) > 0)
stopifnot("Missing states" = length(unique(qwi_state$state_abbr)) >= 45)
stopifnot("Missing industries" = all(c("621", "622", "623") %in% unique(qwi_state$industry)))
stopifnot("Year range" = min(qwi_state$year) <= 2000 & max(qwi_state$year) >= 2020)

cat("Data fetch complete. Validation passed.\n")
