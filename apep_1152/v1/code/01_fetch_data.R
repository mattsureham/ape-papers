## 01_fetch_data.R — The Stranded Signal (apep_1152)
## Downloads EIA-860 generator data and CES enactment dates
source(file.path(here::here(), "output", "apep_1152", "v1", "code", "00_packages.R"))

DATA_DIR <- file.path(here::here(), "output", "apep_1152", "v1", "data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

EIA_KEY <- Sys.getenv("EIA_API_KEY")
stopifnot(nchar(EIA_KEY) > 0)

# =============================================================================
# 1. EIA-860: Generator Inventory via Bulk Download
# =============================================================================
cat("Downloading EIA-860 generator data...\n")

# Download the EIA-860 bulk ZIP files for recent years
# These contain 3_1_Generator_Y20XX.xlsx with all generators
eia860_file <- file.path(DATA_DIR, "eia860_2023.zip")
if (!file.exists(eia860_file)) {
  download.file(
    "https://www.eia.gov/electricity/data/eia860/xls/eia8602023.zip",
    eia860_file, mode = "wb", quiet = TRUE
  )
  cat(sprintf("  Downloaded EIA-860 2023: %d bytes\n", file.info(eia860_file)$size))
}

# Also fetch the retired generators file
eia860r_file <- file.path(DATA_DIR, "eia860_retired.zip")
if (!file.exists(eia860r_file)) {
  download.file(
    "https://www.eia.gov/electricity/data/eia860/xls/eia860RetiredGenerators.zip",
    eia860r_file, mode = "wb", quiet = TRUE
  )
  cat(sprintf("  Downloaded EIA-860 retired: %d bytes\n", file.info(eia860r_file)$size))
}

# Extract and read generator data
cat("  Extracting generator data...\n")
eia_dir <- file.path(DATA_DIR, "eia860_extract")
dir.create(eia_dir, showWarnings = FALSE)

# Unzip
unzip(eia860_file, exdir = eia_dir, overwrite = TRUE)
unzip(eia860r_file, exdir = eia_dir, overwrite = TRUE)

# Find generator files
gen_files <- list.files(eia_dir, pattern = "Generator", full.names = TRUE, recursive = TRUE)
cat(sprintf("  Found %d generator files\n", length(gen_files)))

# Read with readxl (install if needed)
if (!requireNamespace("readxl", quietly = TRUE))
  install.packages("readxl", repos = "https://cloud.r-project.org")
library(readxl)

all_sheets <- list()
for (f in gen_files) {
  # Try to read the generator sheet
  sheets <- tryCatch(excel_sheets(f), error = function(e) character(0))
  for (s in sheets) {
    if (grepl("Generator", s, ignore.case = TRUE) || grepl("Operable", s, ignore.case = TRUE) ||
        grepl("Retired", s, ignore.case = TRUE)) {
      dt <- tryCatch({
        as.data.table(read_excel(f, sheet = s, skip = 1))
      }, error = function(e) NULL)
      if (!is.null(dt) && nrow(dt) > 0) {
        all_sheets[[paste0(basename(f), "_", s)]] <- dt
        cat(sprintf("  Read %s/%s: %d rows\n", basename(f), s, nrow(dt)))
      }
    }
  }
}

if (length(all_sheets) > 0) {
  # Combine all generator data
  # Column names may vary; identify coal generators by fuel type
  for (i in seq_along(all_sheets)) {
    dt <- all_sheets[[i]]
    # Standardize key column names
    names(dt) <- gsub("\\s+", "_", trimws(names(dt)))
    all_sheets[[i]] <- dt
  }

  eia_raw <- rbindlist(all_sheets, fill = TRUE, use.names = TRUE)
  cat(sprintf("Total EIA generator records: %d\n", nrow(eia_raw)))
  cat("Columns:", paste(head(names(eia_raw), 20), collapse = ", "), "\n")

  fwrite(eia_raw, file.path(DATA_DIR, "eia860_all_generators.csv"))
  cat("Saved eia860_all_generators.csv\n")
} else {
  stop("No generator data extracted!")
}

# =============================================================================
# 2. CES ENACTMENT DATES
# =============================================================================
cat("\nBuilding CES enactment dates...\n")

# 100% Clean Energy Standard adoption dates
# Source: NCSL, DSIRE, state legislative records
ces_dates <- data.table(
  state = c("HI", "CA", "NM", "WA", "NY", "CO", "ME", "VA", "OR", "NC",
            "IL", "RI", "CT", "MD", "MN", "MI"),
  state_name = c("Hawaii", "California", "New Mexico", "Washington", "New York",
                 "Colorado", "Maine", "Virginia", "Oregon", "North Carolina",
                 "Illinois", "Rhode Island", "Connecticut", "Maryland",
                 "Minnesota", "Michigan"),
  ces_year = c(2015, 2018, 2019, 2019, 2019, 2019, 2019, 2020, 2021, 2021,
               2021, 2022, 2022, 2022, 2023, 2023),
  ces_target_year = c(2045, 2045, 2045, 2045, 2040, 2040, 2050, 2045, 2040, 2050,
                      2045, 2033, 2040, 2035, 2040, 2040),
  bill = c("HB 623", "SB 100", "ETA", "CETA", "CLCPA", "SB 236", "LD 1494",
           "VCEA", "HB 2021", "HB 951", "CEJA", "Act on Climate", "PA 22-5",
           "CSNA", "SF 4", "PA 229")
)

fwrite(ces_dates, file.path(DATA_DIR, "ces_enactment_dates.csv"))
cat(sprintf("CES dates: %d states\n", nrow(ces_dates)))

# Never-treated states (major coal states without 100% CES)
never_treated <- c("TX", "WY", "WV", "IN", "OH", "KY", "MO", "PA", "GA",
                   "AL", "FL", "MS", "ND", "SD", "MT", "NE", "OK", "AR",
                   "LA", "SC", "TN", "UT", "AZ", "IA", "WI", "KS", "ID")

cat(sprintf("Never-treated states: %d\n", length(never_treated)))

# =============================================================================
# 3. STATE GAS PRICES (EIA API)
# =============================================================================
cat("\nFetching state natural gas prices...\n")

gas_url <- paste0(
  "https://api.eia.gov/v2/natural-gas/pri/sum/data/",
  "?api_key=", EIA_KEY,
  "&frequency=annual",
  "&data[0]=value",
  "&facets[process][]=PEU",  # electric utility price
  "&sort[0][column]=period&sort[0][direction]=desc",
  "&length=5000"
)

gas_resp <- tryCatch(jsonlite::fromJSON(gas_url), error = function(e) NULL)

if (!is.null(gas_resp) && !is.null(gas_resp$response$data)) {
  gas_prices <- as.data.table(gas_resp$response$data)
  fwrite(gas_prices, file.path(DATA_DIR, "state_gas_prices.csv"))
  cat(sprintf("Gas prices: %d records\n", nrow(gas_prices)))
}

cat("\nData fetch complete.\n")
