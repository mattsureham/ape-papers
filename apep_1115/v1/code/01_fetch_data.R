# ==============================================================================
# 01_fetch_data.R — Fetch QWI from Azure + SC activation dates from ICE
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# --- 1. Fetch Secure Communities activation dates from ICE FOIA ---
cat("Downloading SC activation dates from ICE...\n")

sc_url <- "https://www.ice.gov/doclib/foia/reports/identIafisInteroperabilityStatsThroughDec2014.xlsx"
sc_file <- "../data/sc_activation_raw.xlsx"

resp <- httr::GET(sc_url, httr::write_disk(sc_file, overwrite = TRUE),
                  httr::timeout(120))
stopifnot("ICE FOIA download failed" = httr::status_code(resp) == 200)
cat("SC activation file downloaded:", file.info(sc_file)$size, "bytes\n")

# Read the County sheet (tab 7)
sheets <- readxl::excel_sheets(sc_file)
cat("Available sheets:", paste(sheets, collapse = ", "), "\n")

# Find the County sheet
county_sheet <- grep("[Cc]ounty", sheets, value = TRUE)
if (length(county_sheet) == 0) {
  # Try all sheets to find one with activation dates
  cat("No 'County' sheet found. Trying all sheets...\n")
  for (s in sheets) {
    df_test <- tryCatch(readxl::read_excel(sc_file, sheet = s, n_max = 5),
                        error = function(e) NULL)
    if (!is.null(df_test)) {
      cat("Sheet:", s, "— Cols:", paste(names(df_test), collapse = ", "), "\n")
    }
  }
  stop("Cannot find county activation sheet. Check sheet names above.")
}

# Skip 4 header rows, read with actual column positions
sc_raw <- readxl::read_excel(sc_file, sheet = county_sheet[1], skip = 4,
                              col_names = FALSE)
cat("SC raw data:", nrow(sc_raw), "rows,", ncol(sc_raw), "cols\n")

# Columns: 1=State, 2=County, 3=AOR, 4=Activation Date (Excel serial), 5+=stats
# Row 1 is the sub-header, data starts row 2
sc_raw <- sc_raw[-1, ]  # drop sub-header row
names(sc_raw)[1:4] <- c("state", "county", "aor", "activation_date_raw")
cat("First few rows:\n")
print(head(sc_raw[, 1:4], 5))

# --- 2. Build FIPS crosswalk from tidycensus ---
fips_data <- tidycensus::fips_codes
fips_xwalk <- fips_data |>
  mutate(
    state_abb = state,
    county_name_clean = tolower(gsub(" County| Parish| Borough| Census Area| Municipality| city| City and Borough", "",
                                     county)),
    county_fips = paste0(state_code, county_code)
  ) |>
  select(state_abb, county_name_clean, county_fips, state_code) |>
  distinct()

cat("FIPS crosswalk:", nrow(fips_xwalk), "entries\n")

# --- 3. Clean SC activation dates and merge FIPS ---
sc_clean <- sc_raw |>
  select(state, county, activation_date_raw) |>
  filter(!is.na(activation_date_raw), !is.na(state), nchar(state) == 2) |>
  mutate(
    # Convert Excel serial number to date
    activation_date = as.Date(as.numeric(activation_date_raw), origin = "1899-12-30"),
    county_clean = tolower(gsub("\\s+", " ", trimws(county))),
    county_clean = gsub(" county$| parish$| borough$| census area$| municipality$", "",
                        county_clean),
    state = trimws(state)
  ) |>
  filter(!is.na(activation_date))

cat("SC clean data:", nrow(sc_clean), "counties with activation dates\n")
cat("Date range:", as.character(min(sc_clean$activation_date)),
    "to", as.character(max(sc_clean$activation_date)), "\n")

# Merge with FIPS
sc_merged <- sc_clean |>
  left_join(fips_xwalk, by = c("state" = "state_abb",
                                "county_clean" = "county_name_clean"))

matched <- sum(!is.na(sc_merged$county_fips))
cat("FIPS matched:", matched, "of", nrow(sc_merged),
    sprintf("(%.1f%%)\n", 100 * matched / nrow(sc_merged)))

# For unmatched, try fuzzy matching
unmatched <- sc_merged |> filter(is.na(county_fips))
if (nrow(unmatched) > 0) {
  cat("Unmatched counties:", nrow(unmatched), "\n")
  # Try common name variations
  for (i in seq_len(nrow(unmatched))) {
    st <- unmatched$state[i]
    cn <- unmatched$county_clean[i]
    # Try without "st." -> "saint", "de " removal, etc.
    candidates <- fips_xwalk |> filter(state_abb == st)
    # Fuzzy match: find closest
    dists <- adist(cn, candidates$county_name_clean)
    best <- which.min(dists)
    if (dists[best] <= 3) {
      idx <- which(sc_merged$state == st & sc_merged$county_clean == cn &
                     is.na(sc_merged$county_fips))
      sc_merged$county_fips[idx[1]] <- candidates$county_fips[best]
      sc_merged$state_code[idx[1]] <- candidates$state_code[best]
    }
  }
  matched2 <- sum(!is.na(sc_merged$county_fips))
  cat("After fuzzy matching:", matched2, "of", nrow(sc_merged), "matched\n")
}

# Keep only matched US counties (drop territories)
sc_final <- sc_merged |>
  filter(!is.na(county_fips)) |>
  mutate(
    activation_quarter = paste0(format(activation_date, "%Y"), "Q",
                                ceiling(as.numeric(format(activation_date, "%m")) / 3))
  ) |>
  select(county_fips, state_code, activation_date, activation_quarter) |>
  distinct(county_fips, .keep_all = TRUE)

cat("Final SC activation data:", nrow(sc_final), "counties\n")
cat("Activation quarters:\n")
print(table(sc_final$activation_quarter))

saveRDS(sc_final, "../data/sc_activation_dates.rds")

# --- 4. Fetch QWI data from Azure ---
cat("\nConnecting to Azure for QWI data...\n")

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

# Read connection string directly from .env (avoid sprintf mangling of +/= chars)
envlines <- readLines("../../../../.env", warn = FALSE)
conn_str <- ""
for (l in envlines) {
  l <- trimws(l)
  if (startsWith(l, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", l)
    conn_str <- gsub('^["\']|["\']$', '', conn_str)
    break
  }
}
stopifnot("AZURE_STORAGE_CONNECTION_STRING not found in .env" = nchar(conn_str) > 0)

sql <- paste0("CREATE SECRET apep (TYPE azure, CONNECTION_STRING '", conn_str, "');")
DBI::dbExecute(con, sql)
cat("Azure connected.\n")

# QWI data at derived/qwi/rh/n3/{state}.parquet (lowercase state abbreviations)
# Pull Hispanic (ethnicity=2) and non-Hispanic (ethnicity=1) data
# Time window: 2005Q1 to 2015Q4

cat("Querying QWI race/ethnicity x NAICS-3 data from Azure...\n")
cat("Iterating over states (51 files)...\n")

all_states <- c("al","ak","az","ar","ca","co","ct","de","dc","fl",
                "ga","hi","id","il","in","ia","ks","ky","la","me",
                "md","ma","mi","mn","ms","mo","mt","ne","nv","nh",
                "nj","nm","ny","nc","nd","oh","ok","or","pa","ri",
                "sc","sd","tn","tx","ut","vt","va","wa","wv","wi","wy")

qwi_list <- list()
for (st in all_states) {
  path <- sprintf("az://derived/qwi/rh/n3/%s.parquet", st)
  q <- sprintf("SELECT geography AS county_fips, year, quarter, industry, ethnicity, Emp, HirA, Sep, EarnS FROM '%s' WHERE year BETWEEN 2005 AND 2015 AND ethnicity IN ('A1', 'A2') AND race = 'A0' AND Emp IS NOT NULL AND Emp > 0", path)
  df <- tryCatch(DBI::dbGetQuery(con, q), error = function(e) {
    cat("  Error for", st, ":", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(df) && nrow(df) > 0) {
    qwi_list[[st]] <- df
    cat("  ", toupper(st), ":", nrow(df), "rows\n")
  }
}

qwi_raw <- data.table::rbindlist(qwi_list, use.names = TRUE)
cat("QWI raw data:", nrow(qwi_raw), "rows from", length(qwi_list), "states\n")

# Total employment by county × quarter × ethnicity
cat("Computing county-level totals...\n")
qwi_totals <- qwi_raw[, .(
  total_emp = sum(Emp, na.rm = TRUE),
  total_hires = sum(HirA, na.rm = TRUE),
  avg_earn = sum(EarnS * Emp, na.rm = TRUE) / sum(Emp[!is.na(EarnS)], na.rm = TRUE)
), by = .(county_fips, year, quarter, ethnicity)]
cat("QWI totals:", nrow(qwi_totals), "rows\n")

DBI::dbDisconnect(con, shutdown = TRUE)

# --- 5. Save raw data ---
saveRDS(qwi_raw, "../data/qwi_raw.rds")
saveRDS(qwi_totals, "../data/qwi_totals.rds")

cat("\nData fetch complete.\n")
cat("  SC activation dates:", nrow(sc_final), "counties\n")
cat("  QWI industry data:", nrow(qwi_raw), "rows\n")
cat("  QWI totals:", nrow(qwi_totals), "rows\n")
