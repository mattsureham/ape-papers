## 01_fetch_data.R — Fetch HUD PIT/HIC data and code RTC treatment
## apep_1028: Right-to-Counsel and Community-Level Homelessness

source("00_packages.R")

cat("=== Fetching HUD PIT Homeless Count Data ===\n")

# --- HUD PIT data: 2007-2024 (XLSB format from HUD User) ---
pit_coc_url <- "https://www.huduser.gov/portal/sites/default/files/xls/2007-2024-PIT-Counts-by-CoC.xlsb"
pit_file <- "../data/pit_counts_by_coc.xlsb"

if (!file.exists(pit_file)) {
  resp <- httr2::request(pit_coc_url) |>
    httr2::req_timeout(120) |>
    httr2::req_perform(path = pit_file)
}
stopifnot("PIT download failed" = file.exists(pit_file) && file.size(pit_file) > 1000)
cat("PIT CoC data:", file.size(pit_file), "bytes\n")

# --- HIC data (XLSX — can be read directly) ---
hic_url <- "https://www.huduser.gov/portal/sites/default/files/xls/2007-2024-HIC-Counts-by-CoC.xlsx"
hic_file <- "../data/hic_counts_by_coc.xlsx"

if (!file.exists(hic_file)) {
  resp3 <- httr2::request(hic_url) |>
    httr2::req_timeout(120) |>
    httr2::req_perform(path = hic_file)
}
stopifnot("HIC download failed" = file.exists(hic_file) && file.size(hic_file) > 1000)
cat("HIC CoC data:", file.size(hic_file), "bytes\n")

# --- Convert XLSB to CSV using Python pyxlsb ---
cat("\n=== Converting XLSB to CSV ===\n")

convert_script <- '
import pyxlsb
import csv
import sys
import os

xlsb_path = sys.argv[1]
out_dir = sys.argv[2]

with pyxlsb.open_workbook(xlsb_path) as wb:
    for sheet_name in wb.sheets:
        out_path = os.path.join(out_dir, f"pit_{sheet_name}.csv")
        with wb.get_sheet(sheet_name) as sheet:
            rows = list(sheet.rows())
        if not rows:
            continue
        with open(out_path, "w", newline="") as f:
            writer = csv.writer(f)
            for row in rows:
                writer.writerow([item.v for item in row])
        print(f"Wrote {out_path}: {len(rows)} rows")
'

writeLines(convert_script, "../data/convert_xlsb.py")
system2("python3", args = c("../data/convert_xlsb.py", pit_file, "../data/"),
        stdout = TRUE, stderr = TRUE) |> cat(sep = "\n")

# --- Read converted CSV files ---
cat("\n=== Reading PIT CSV data ===\n")
csv_files <- list.files("../data/", pattern = "^pit_.*\\.csv$", full.names = TRUE)
cat("Found CSV files:", paste(basename(csv_files), collapse = ", "), "\n")

pit_list <- list()
for (f in csv_files) {
  sheet_name <- gsub("^pit_|\\.csv$", "", basename(f))
  df <- read_csv(f, show_col_types = FALSE)
  cat("Sheet:", sheet_name, "—", nrow(df), "rows,", ncol(df), "cols\n")
  if (nrow(df) > 0) {
    # Print first few column names for inspection
    cat("  Cols:", paste(head(names(df), 10), collapse = ", "), "...\n")
  }
  pit_list[[sheet_name]] <- df
}

saveRDS(pit_list, "../data/pit_raw.rds")
cat("PIT raw data saved.\n")

# --- Code RTC Treatment Status ---
cat("\n=== Coding RTC Treatment ===\n")

rtc_adoptions <- tribble(
  ~city,            ~state, ~coc_code,   ~adopt_year, ~adopt_type,
  # --- City-level adoptions ---
  "New York City",  "NY",   "NY-600",    2017L,       "city",
  "San Francisco",  "CA",   "CA-501",    2018L,       "city",
  "Newark",         "NJ",   "NJ-500",    2018L,       "city",
  "Cleveland",      "OH",   "OH-502",    2019L,       "city",
  "Philadelphia",   "PA",   "PA-500",    2019L,       "city",
  "Baltimore",      "MD",   "MD-501",    2020L,       "city",
  "Boulder",        "CO",   "CO-503",    2020L,       "city",
  "Seattle",        "WA",   "WA-500",    2021L,       "city",
  "Louisville",     "KY",   "KY-501",    2021L,       "city",
  "Denver",         "CO",   "CO-503",    2021L,       "city",
  "Minneapolis",    "MN",   "MN-500",    2021L,       "city",
  "Kansas City",    "MO",   "MO-604",    2021L,       "city",
  "Toledo",         "OH",   "OH-504",    2021L,       "city",
  "New Orleans",    "LA",   "LA-503",    2022L,       "city",
  "Detroit",        "MI",   "MI-501",    2022L,       "city",
  "Jersey City",    "NJ",   "NJ-500",    2023L,       "city",
  "St. Louis",      "MO",   "MO-501",    2023L,       "city",
  # --- State-level adoptions ---
  # Connecticut: SB 1023 (2021) — statewide RTC in eviction proceedings
  "Connecticut",    "CT",   "CT-503",    2021L,       "state",
  "Connecticut",    "CT",   "CT-505",    2021L,       "state",
  # Washington: SB 5160 (2021) — statewide RTC
  "Washington",     "WA",   "WA-501",    2021L,       "state",
  "Washington",     "WA",   "WA-502",    2021L,       "state",
  "Washington",     "WA",   "WA-503",    2021L,       "state",
  "Washington",     "WA",   "WA-504",    2021L,       "state",
  "Washington",     "WA",   "WA-508",    2021L,       "state",
  # Maryland: HB 18 (2021) — Access to Counsel in Evictions Act
  "Maryland",       "MD",   "MD-503",    2021L,       "state",
  "Maryland",       "MD",   "MD-504",    2021L,       "state",
  "Maryland",       "MD",   "MD-505",    2021L,       "state",
  "Maryland",       "MD",   "MD-506",    2021L,       "state",
  "Maryland",       "MD",   "MD-511",    2021L,       "state",
  "Maryland",       "MD",   "MD-513",    2021L,       "state",
  "Maryland",       "MD",   "MD-514",    2021L,       "state",
  "Maryland",       "MD",   "MD-600",    2021L,       "state",
  "Maryland",       "MD",   "MD-601",    2021L,       "state",
  # Minnesota: Chapter 134 (2023) — statewide RTC
  "Minnesota",      "MN",   "MN-501",    2023L,       "state",
  "Minnesota",      "MN",   "MN-502",    2023L,       "state",
  "Minnesota",      "MN",   "MN-503",    2023L,       "state",
  "Minnesota",      "MN",   "MN-504",    2023L,       "state",
  "Minnesota",      "MN",   "MN-505",    2023L,       "state",
  "Minnesota",      "MN",   "MN-506",    2023L,       "state",
  "Minnesota",      "MN",   "MN-508",    2023L,       "state",
  "Minnesota",      "MN",   "MN-509",    2023L,       "state",
  "Minnesota",      "MN",   "MN-511",    2023L,       "state"
)

# Deduplicate to one row per CoC with earliest adoption year
rtc_by_coc <- rtc_adoptions |>
  group_by(coc_code) |>
  summarise(
    adopt_year = min(adopt_year),
    cities = paste(city, collapse = "; "),
    .groups = "drop"
  )

cat("\nRTC treatment by CoC:\n")
print(rtc_by_coc, n = 20)
cat("\nTotal treated CoCs:", nrow(rtc_by_coc), "\n")
cat("Cohort distribution:\n")
print(table(rtc_by_coc$adopt_year))

saveRDS(rtc_by_coc, "../data/rtc_treatment.rds")
saveRDS(rtc_adoptions, "../data/rtc_adoptions_detail.rds")

cat("\n=== Data fetch complete ===\n")
