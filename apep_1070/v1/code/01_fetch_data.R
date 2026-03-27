# =============================================================================
# 01_fetch_data.R — Fetch DOL H-2A and QWI data
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

source("00_packages.R")

# --- Manual Azure connection (azure_data.R has parsing issue with semicolons) ---
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING", line)) {
    val <- sub("^[^=]+=", "", line)
    val <- gsub("^[\"']|[\"']$", "", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
  }
}

# ---------------------------------------------------------------------------
# 1. DOL H-2A Foreign Labor Certification disclosure data
# ---------------------------------------------------------------------------
h2a_dir <- "../data/h2a_raw"
dir.create(h2a_dir, recursive = TRUE, showWarnings = FALSE)

base_url <- "https://www.dol.gov/sites/dolgov/files/ETA/oflc/pdfs"

# Confirmed working URLs for each fiscal year
h2a_urls <- c(
  "2023" = paste0(base_url, "/H-2A_Disclosure_Data_FY2023_Q4.xlsx"),
  "2022" = paste0(base_url, "/H-2A_Disclosure_Data_FY2022_Q4.xlsx"),
  "2021" = paste0(base_url, "/H-2A_Disclosure_Data_FY2021.xlsx"),
  "2020" = paste0(base_url, "/H-2A_Disclosure_Data_FY2020.xlsx"),
  "2019" = paste0(base_url, "/H-2A_Disclosure_Data_FY2019.xlsx"),
  "2018" = paste0(base_url, "/H-2A_FY2018.xlsx")
)

cat("Downloading DOL H-2A disclosure files...\n")
h2a_files <- list()

for (fy in names(h2a_urls)) {
  dest <- file.path(h2a_dir, paste0("h2a_fy", fy, ".xlsx"))
  if (!file.exists(dest) || file.size(dest) < 10000) {
    cat(sprintf("  Downloading FY%s...\n", fy))
    tryCatch({
      download.file(h2a_urls[[fy]], dest, mode = "wb", quiet = TRUE)
    }, error = function(e) {
      cat(sprintf("  ERROR downloading FY%s: %s\n", fy, e$message))
    })
  } else {
    cat(sprintf("  FY%s already cached.\n", fy))
  }
  if (file.exists(dest) && file.size(dest) > 10000) {
    h2a_files[[fy]] <- dest
  }
}

if (length(h2a_files) == 0) {
  stop("FATAL: No H-2A disclosure files downloaded. Cannot proceed without real data.")
}
cat(sprintf("Successfully obtained %d fiscal year files.\n", length(h2a_files)))

# ---------------------------------------------------------------------------
# 2. Parse H-2A files → county-year certified positions
# ---------------------------------------------------------------------------
cat("\nParsing H-2A disclosure files...\n")

parse_h2a_file <- function(filepath, fy) {
  df <- readxl::read_excel(filepath, sheet = 1, guess_max = 5000)
  names(df) <- toupper(gsub("\\s+", "_", names(df)))

  # Filter to certified (not expired, denied, withdrawn)
  certified <- grepl("CERTIF", df[["CASE_STATUS"]], ignore.case = TRUE) &
               !grepl("EXPIRED|DENIED|WITHDRAWN", df[["CASE_STATUS"]], ignore.case = TRUE)
  df <- df[certified, ]

  if (nrow(df) == 0) {
    cat(sprintf("  FY%s: No certified cases.\n", fy))
    return(NULL)
  }

  # Workers column (varies by year)
  w_col <- grep("H2A_CERTIFIED|NBR_WORKERS_CERTIFIED", names(df), value = TRUE)
  if (length(w_col) == 0) w_col <- grep("WORKERS_NEEDED|TOTAL_WORKERS", names(df), value = TRUE)
  if (length(w_col) > 0) {
    df$workers <- suppressWarnings(as.numeric(df[[w_col[1]]]))
    df$workers[is.na(df$workers)] <- 1
  } else {
    df$workers <- 1
  }

  # Worksite state: WORKSITE_STATE or EMPLOYER_STATE
  state_col <- grep("WORKSITE_STATE", names(df), value = TRUE)
  if (length(state_col) == 0) state_col <- grep("EMPLOYER_STATE", names(df), value = TRUE)
  if (length(state_col) > 0) {
    df$ws_state <- toupper(trimws(as.character(df[[state_col[1]]])))
  } else {
    df$ws_state <- NA_character_
  }

  # Worksite county
  county_col <- grep("WORKSITE_COUNTY", names(df), value = TRUE)
  if (length(county_col) == 0) county_col <- grep("EMPLOYER_COUNTY", names(df), value = TRUE)
  if (length(county_col) > 0) {
    df$ws_county <- toupper(trimws(as.character(df[[county_col[1]]])))
  } else {
    df$ws_county <- NA_character_
  }

  df$fiscal_year <- as.integer(fy)
  out <- df[, c("fiscal_year", "ws_state", "ws_county", "workers")]
  out <- out[!is.na(out$ws_state) & !is.na(out$ws_county) & nchar(out$ws_county) > 0, ]

  cat(sprintf("  FY%s: %d certified employer-records, %s positions\n",
              fy, nrow(out), format(sum(out$workers, na.rm = TRUE), big.mark = ",")))
  return(as.data.frame(out))
}

h2a_all <- list()
for (fy in sort(names(h2a_files))) {
  parsed <- parse_h2a_file(h2a_files[[fy]], fy)
  if (!is.null(parsed) && nrow(parsed) > 0) h2a_all[[fy]] <- parsed
}

if (length(h2a_all) == 0) {
  stop("FATAL: Could not parse any H-2A disclosure files.")
}

h2a_combined <- bind_rows(h2a_all)
cat(sprintf("\nCombined H-2A: %d records, FY%s to FY%s\n",
            nrow(h2a_combined), min(h2a_combined$fiscal_year), max(h2a_combined$fiscal_year)))

# State name → abbreviation mapping
state_names <- data.frame(
  state_name = c("ALABAMA","ALASKA","ARIZONA","ARKANSAS","CALIFORNIA","COLORADO",
                  "CONNECTICUT","DELAWARE","FLORIDA","GEORGIA","HAWAII","IDAHO",
                  "ILLINOIS","INDIANA","IOWA","KANSAS","KENTUCKY","LOUISIANA",
                  "MAINE","MARYLAND","MASSACHUSETTS","MICHIGAN","MINNESOTA",
                  "MISSISSIPPI","MISSOURI","MONTANA","NEBRASKA","NEVADA",
                  "NEW HAMPSHIRE","NEW JERSEY","NEW MEXICO","NEW YORK",
                  "NORTH CAROLINA","NORTH DAKOTA","OHIO","OKLAHOMA","OREGON",
                  "PENNSYLVANIA","RHODE ISLAND","SOUTH CAROLINA","SOUTH DAKOTA",
                  "TENNESSEE","TEXAS","UTAH","VERMONT","VIRGINIA","WASHINGTON",
                  "WEST VIRGINIA","WISCONSIN","WYOMING","DISTRICT OF COLUMBIA"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                  "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                  "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                  "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  stringsAsFactors = FALSE
)

# Convert full state names to abbreviations where needed
h2a_combined <- h2a_combined %>%
  mutate(ws_state = ifelse(
    nchar(ws_state) > 2,
    state_names$state_abbr[match(ws_state, state_names$state_name)],
    ws_state
  )) %>%
  filter(!is.na(ws_state))

# Aggregate to state-county_name-year
h2a_county <- h2a_combined %>%
  group_by(fiscal_year, ws_state, ws_county) %>%
  summarise(h2a_positions = sum(workers, na.rm = TRUE),
            n_employers = n(), .groups = "drop")

cat(sprintf("\nH-2A county-year panel: %d rows, %d unique state-county pairs\n",
            nrow(h2a_county),
            n_distinct(paste(h2a_county$ws_state, h2a_county$ws_county))))

h2a_county %>%
  group_by(fiscal_year) %>%
  summarise(total = sum(h2a_positions),
            counties = n_distinct(paste(ws_state, ws_county))) %>%
  print()

saveRDS(h2a_county, "../data/h2a_county_year.rds")

# ---------------------------------------------------------------------------
# 3. Fetch QWI from Azure
# ---------------------------------------------------------------------------
cat("\nConnecting to Azure for QWI data...\n")
conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
stopifnot("Azure connection string not found" = nchar(conn_str) > 50)

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_az (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure via DuckDB\n")

cat("Querying QWI NAICS 11 (agriculture), race/ethnicity panel...\n")
qwi_ag <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity,
         industry, Emp, EmpEnd, EmpS, HirA, HirN,
         Sep, EarnS, EarnBeg, FrmJbGn, FrmJbLs
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '11'
    AND geography >= 1000
    AND race = 'A0'
    AND ethnicity IN ('A1', 'A2')
")
cat(sprintf("QWI agriculture: %d rows\n", nrow(qwi_ag)))
stopifnot("No QWI agriculture data" = nrow(qwi_ag) > 0)

cat("Querying QWI NAICS 23 and 72 for placebos...\n")
qwi_placebo <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity,
         industry, Emp, EmpEnd, EmpS, HirA, HirN,
         Sep, EarnS, EarnBeg, FrmJbGn, FrmJbLs
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('23', '72')
    AND geography >= 1000
    AND race = 'A0'
    AND ethnicity IN ('A1', 'A2')
")
cat(sprintf("QWI placebo: %d rows\n", nrow(qwi_placebo)))

dbDisconnect(con, shutdown = TRUE)

saveRDS(qwi_ag, "../data/qwi_agriculture.rds")
saveRDS(qwi_placebo, "../data/qwi_placebo.rds")

cat("\nData fetch complete.\n")
