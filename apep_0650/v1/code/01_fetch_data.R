## 01_fetch_data.R — Fetch all data for apep_0650
## MW border-pair firm dynamics
## Sources: (1) Census county adjacency, (2) State MW panel, (3) QWI from Azure

## Determine project root and working directory
args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))
source("code/00_packages.R")

# Find project root (has .env) — output/apep_XXXX/v1 is 3 levels down
proj_root <- normalizePath("../../..")
source(file.path(proj_root, "scripts/lib/azure_data.R"))

cat("=== Step 1: County Adjacency File ===\n")
# Census Bureau county adjacency file
adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
adj_file <- "data/county_adjacency.txt"
if (!file.exists(adj_file)) {
  download.file(adj_url, adj_file, mode = "wb")
}
stopifnot("County adjacency file not downloaded" = file.exists(adj_file))

# Parse the adjacency file (tab-delimited, hierarchical format)
raw_lines <- readLines(adj_file, warn = FALSE)
adj_records <- list()
current_county <- NULL
current_fips <- NULL

for (line in raw_lines) {
  parts <- strsplit(line, "\t")[[1]]
  # Remove empty parts
  parts <- parts[nchar(parts) > 0]
  if (length(parts) >= 2) {
    # Check if this line has a county name in first position (new county)
    # The format is: County Name\tFIPS\tAdjacent County\tAdjacent FIPS
    # Or continuation: \t\tAdjacent County\tAdjacent FIPS
    if (!startsWith(line, "\t")) {
      current_county <- parts[1]
      current_fips <- parts[2]
      if (length(parts) >= 4) {
        adj_records[[length(adj_records) + 1]] <- data.frame(
          county = current_county, fips = current_fips,
          adj_county = parts[3], adj_fips = parts[4],
          stringsAsFactors = FALSE
        )
      }
    } else {
      # Continuation line — adjacent county
      if (!is.null(current_fips) && length(parts) >= 2) {
        adj_records[[length(adj_records) + 1]] <- data.frame(
          county = current_county, fips = current_fips,
          adj_county = parts[1], adj_fips = parts[2],
          stringsAsFactors = FALSE
        )
      }
    }
  }
}

adj_df <- bind_rows(adj_records) |>
  mutate(
    fips = str_pad(fips, 5, "left", "0"),
    adj_fips = str_pad(adj_fips, 5, "left", "0"),
    state_fips = substr(fips, 1, 2),
    adj_state_fips = substr(adj_fips, 1, 2)
  )

cat("Adjacency records:", nrow(adj_df), "\n")
cat("Unique counties:", n_distinct(adj_df$fips), "\n")

# Cross-state border pairs only (different state FIPS)
border_pairs <- adj_df |>
  filter(state_fips != adj_state_fips) |>
  # Create canonical pair ID (smaller FIPS first)
  mutate(
    fips_a = pmin(fips, adj_fips),
    fips_b = pmax(fips, adj_fips),
    pair_id = paste(fips_a, fips_b, sep = "_")
  ) |>
  distinct(pair_id, .keep_all = TRUE) |>
  select(pair_id, fips_a, fips_b,
         state_a = state_fips, state_b = adj_state_fips)

cat("Cross-state border county pairs:", nrow(border_pairs), "\n")

# Get all border county FIPS
border_fips <- unique(c(border_pairs$fips_a, border_pairs$fips_b))
cat("Unique border counties:", length(border_fips), "\n")

saveRDS(border_pairs, "data/border_pairs.rds")

cat("\n=== Step 2: State Minimum Wage Panel ===\n")
# Vaghul-Zipperer (2021) historical minimum wage data
# Download Stata files from GitHub release (CSV no longer available)
if (!requireNamespace("haven", quietly = TRUE)) {
  install.packages("haven", repos = "https://cloud.r-project.org")
}
library(haven)

mw_zip <- "data/mw_state_stata.zip"
mw_dta <- "data/mw_state_quarterly.dta"
if (!file.exists(mw_dta)) {
  download.file(
    "https://github.com/benzipperer/historicalminwage/releases/download/v1.4.0/mw_state_stata.zip",
    mw_zip, mode = "wb"
  )
  unzip(mw_zip, exdir = "data/")
  # List extracted files
  cat("Extracted files:", paste(list.files("data/", pattern = "\\.dta$"), collapse = ", "), "\n")
}

# Find the quarterly state MW dta file
dta_files <- list.files("data/", pattern = "\\.dta$", full.names = TRUE)
cat("DTA files found:", paste(dta_files, collapse = ", "), "\n")

# Read the quarterly file (most granular)
mw_file <- dta_files[grepl("quarterly|quarter|qtr", dta_files, ignore.case = TRUE)]
if (length(mw_file) == 0) {
  # Try annual if quarterly not found
  mw_file <- dta_files[grepl("annual|year", dta_files, ignore.case = TRUE)]
}
if (length(mw_file) == 0) mw_file <- dta_files[1]  # fallback to first file

cat("Using MW file:", mw_file, "\n")
mw_raw <- read_dta(mw_file)
cat("MW raw columns:", paste(names(mw_raw), collapse = ", "), "\n")
cat("MW raw rows:", nrow(mw_raw), "\n")

# State FIPS mapping
state_fips_map <- data.frame(
  state_abb = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  state_fips = c("01","02","04","05","06","08","09","10","12","13",
                 "15","16","17","18","19","20","21","22","23","24",
                 "25","26","27","28","29","30","31","32","33","34",
                 "35","36","37","38","39","40","41","42","44","45",
                 "46","47","48","49","50","51","53","54","55","56","11"),
  stringsAsFactors = FALSE
)

# Columns: statefips, stateabb, quarterly_date, mean_mw, mean_fed_mw, etc.
# quarterly_date is Stata quarterly: 0 = 1960Q1, so year = 1960 + floor(q/4), quarter = (q %% 4) + 1
# effective MW = max(state MW, federal MW) for each quarter
# Use mean_mw (average within quarter) for smooth variation
mw_panel <- mw_raw |>
  mutate(
    state_fips = str_pad(as.character(as.integer(statefips)), 2, "left", "0"),
    year = 1960L + as.integer(floor(quarterly_date / 4)),
    quarter = as.integer((quarterly_date %% 4) + 1),
    eff_mw = pmax(mean_mw, mean_fed_mw, na.rm = TRUE),
    log_mw = log(eff_mw)
  ) |>
  filter(year >= 2001, year <= 2022, !is.na(eff_mw)) |>
  mutate(year_quarter = paste0(year, "Q", quarter)) |>
  select(state_fips, state = stateabb, year, quarter, year_quarter, eff_mw, log_mw)

cat("MW panel: ", nrow(mw_panel), " state-quarter obs\n")
cat("MW range: $", min(mw_panel$eff_mw, na.rm = TRUE), " - $",
    max(mw_panel$eff_mw, na.rm = TRUE), "\n")

saveRDS(mw_panel, "data/mw_panel.rds")

cat("\n=== Step 3: Construct Border Pair MW Differentials ===\n")
# Merge MW to each side of each border pair
pair_mw <- border_pairs |>
  inner_join(
    mw_panel |> select(state_fips, year, quarter, eff_mw_a = eff_mw, log_mw_a = log_mw),
    by = c("state_a" = "state_fips")
  ) |>
  inner_join(
    mw_panel |> select(state_fips, year, quarter, eff_mw_b = eff_mw, log_mw_b = log_mw),
    by = c("state_b" = "state_fips", "year", "quarter")
  ) |>
  mutate(
    mw_diff = abs(eff_mw_a - eff_mw_b),
    log_mw_diff = abs(log_mw_a - log_mw_b)
  )

# Focus on pairs with meaningful MW differential (>= $1 at some point)
pairs_with_diff <- pair_mw |>
  group_by(pair_id) |>
  summarise(max_diff = max(mw_diff), .groups = "drop") |>
  filter(max_diff >= 1.0)

cat("Pairs with MW diff >= $1:", nrow(pairs_with_diff), "\n")
cat("Pairs with MW diff >= $2:", sum(pairs_with_diff$max_diff >= 2), "\n")

# Keep all border pairs for analysis (including placebo pairs with diff = 0)
active_pair_ids <- pairs_with_diff$pair_id
active_border_fips <- border_pairs |>
  filter(pair_id %in% active_pair_ids) |>
  {\(x) unique(c(x$fips_a, x$fips_b))}()

cat("Active border counties:", length(active_border_fips), "\n")

saveRDS(pair_mw, "data/pair_mw.rds")

cat("\n=== Step 4: QWI Data from Azure ===\n")
con <- apep_azure_connect()

# Query ALL county-level QWI data for key industries, then filter in R
# Key industries: 00 (all), 72 (accommodation/food), 44-45 (retail), 62 (health), 81 (services)
cat("Querying QWI for all counties, key industries...\n")

qwi_query <- "
  SELECT geography, year, quarter, agegrp, industry,
         Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs, FrmJbC,
         EarnS, TurnOvrS, sEmp, sHirA, sFrmJbGn, sFrmJbLs, sEarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE geo_level = 'C'
    AND sex = 0
    AND industry IN ('00', '72', '44-45', '62', '81', '31-33', '23')
    AND year >= 2001
    AND year <= 2022
"

qwi_raw <- dbGetQuery(con, qwi_query)
cat("QWI rows (all state counties):", nrow(qwi_raw), "\n")
cat("QWI unique counties (all):", n_distinct(qwi_raw$geography), "\n")

stopifnot("QWI data is empty — Azure query failed" = nrow(qwi_raw) > 0)

# Format FIPS to 5-digit string, then filter to border counties only
qwi_raw <- qwi_raw |>
  mutate(fips = str_pad(as.character(geography), 5, "left", "0")) |>
  filter(fips %in% border_fips)

cat("QWI rows (border counties only):", nrow(qwi_raw), "\n")
cat("QWI unique border counties:", n_distinct(qwi_raw$fips), "\n")
cat("QWI year range:", range(qwi_raw$year), "\n")
cat("QWI age groups:", paste(sort(unique(qwi_raw$agegrp)), collapse = ", "), "\n")

stopifnot("Too few border counties in QWI" = n_distinct(qwi_raw$fips) >= 100)

saveRDS(qwi_raw, "data/qwi_border.rds")

apep_azure_disconnect(con)

cat("\n=== Data Fetch Complete ===\n")
cat("Files saved:\n")
cat("  data/border_pairs.rds\n")
cat("  data/mw_panel.rds\n")
cat("  data/pair_mw.rds\n")
cat("  data/qwi_border.rds\n")
