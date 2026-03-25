## ── 01_fetch_data.R ──────────────────────────────────────────────
## Fetch WFP food price data (yearly files) and construct
## Indian rice import dependence from FAO trade data
## ──────────────────────────────────────────────────────────────────

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

## ── 1. WFP Global Food Prices (Yearly Files 2021-2025) ─────────
## Source: WFP VAM / HDX — data split by year, updated weekly

cat("=== Fetching WFP Global Food Prices ===\n")

wfp_urls <- c(
  "2021" = "https://data.humdata.org/dataset/31579af5-3895-4002-9ee3-c50857480785/resource/70bc3058-1ff7-41e3-b16a-3492422fcab6/download/wfp_food_prices_global_2021.csv",
  "2022" = "https://data.humdata.org/dataset/31579af5-3895-4002-9ee3-c50857480785/resource/747fe8d0-83e7-4da7-a40e-3afdd11832c9/download/wfp_food_prices_global_2022.csv",
  "2023" = "https://data.humdata.org/dataset/31579af5-3895-4002-9ee3-c50857480785/resource/e96b8f67-c4de-4173-a814-2f7d84c47475/download/wfp_food_prices_global_2023.csv",
  "2024" = "https://data.humdata.org/dataset/31579af5-3895-4002-9ee3-c50857480785/resource/5867679b-7ef4-4117-84b8-2bb4ddd7817f/download/wfp_food_prices_global_2024.csv",
  "2025" = "https://data.humdata.org/dataset/31579af5-3895-4002-9ee3-c50857480785/resource/d62af4be-cff6-437b-89a3-67f8fa4c53bf/download/wfp_food_prices_global_2025.csv"
)

all_wfp <- list()

for (yr in names(wfp_urls)) {
  fname <- file.path(data_dir, paste0("wfp_", yr, ".csv"))

  if (!file.exists(fname)) {
    cat("Downloading WFP", yr, "data...\n")
    resp <- GET(wfp_urls[[yr]], write_disk(fname, overwrite = TRUE),
                progress(), timeout(300))
    if (http_error(resp)) {
      cat("  ERROR: Failed to download", yr, "(status:", status_code(resp), ")\n")
      file.remove(fname)
      next
    }
    cat("  Downloaded:", round(file.info(fname)$size / 1e6, 1), "MB\n")
  } else {
    cat("WFP", yr, "already exists.\n")
  }

  dt <- fread(fname, encoding = "UTF-8")
  all_wfp[[yr]] <- dt
  cat("  Year", yr, ":", nrow(dt), "rows,", uniqueN(dt$adm0_name), "countries\n")
}

wfp <- rbindlist(all_wfp, fill = TRUE)
cat("\n=== WFP Combined Data ===\n")
cat("Total rows:", nrow(wfp), "\n")
cat("Countries:", uniqueN(wfp$adm0_name), "\n")
cat("Markets:", uniqueN(wfp$mkt_name), "\n")
cat("Year range:", range(wfp$mp_year), "\n")

# Save combined
fwrite(wfp, file.path(data_dir, "wfp_combined.csv"))

## ── 2. Construct Import Dependence from FAO Trade Matrix ────────
## FAO Detailed Trade Matrix has bilateral commodity trade flows
## We use this instead of COMTRADE (which requires subscription)

cat("\n=== Constructing Import Dependence from FAO ===\n")

fao_dir <- file.path(data_dir, "fao_trade")
fao_zip <- file.path(data_dir, "fao_trade_matrix.zip")

if (!dir.exists(fao_dir) || length(list.files(fao_dir, pattern = "\\.csv$")) == 0) {
  if (!file.exists(fao_zip)) {
    cat("Downloading FAO detailed trade matrix...\n")
    resp <- GET("https://bulks-faostat.fao.org/production/Trade_DetailedTradeMatrix_E_All_Data.zip",
                write_disk(fao_zip, overwrite = TRUE), progress(), timeout(900))
    stopifnot("FAO download failed" = !http_error(resp))
  }
  cat("Extracting FAO trade data...\n")
  unzip(fao_zip, exdir = fao_dir)
}

fao_files <- list.files(fao_dir, pattern = "\\.csv$", full.names = TRUE)
stopifnot("No FAO CSV found" = length(fao_files) > 0)

cat("Reading FAO trade data...\n")
fao <- fread(fao_files[1], encoding = "Latin-1")
cat("FAO total rows:", nrow(fao), "\n")
cat("FAO columns:", paste(names(fao), collapse = ", "), "\n")

# Filter for rice items:
# Item Code 27 = Rice, paddy equivalent; 28 = Rice, milled; 29 = Rice, husked
# Element: Import Quantity (5610) or Import Value (5622)
rice_items <- unique(fao[grepl("[Rr]ice", `Item`)]$`Item Code`)
cat("Rice item codes:", paste(rice_items, collapse = ", "), "\n")

# Filter for imports
import_codes <- c(5610, 5622)  # Import Quantity (tonnes), Import Value ($1000)
fao_rice <- fao[`Item Code` %in% rice_items & `Element Code` %in% import_codes]
cat("Rice import rows:", nrow(fao_rice), "\n")

# India's FAO country code
india_fao <- unique(fao[grepl("India$", `Partner Countries`)]$`Partner Country Code`)
cat("India FAO code(s):", india_fao, "\n")

# Use Import Value (5622) for 2020-2022
fao_val <- fao_rice[`Element Code` == 5622]

# Get year columns for 2020-2022
yr_cols <- c("Y2020", "Y2021", "Y2022")
avail_yr <- intersect(yr_cols, names(fao_val))
cat("Available year columns:", paste(avail_yr, collapse = ", "), "\n")

if (length(avail_yr) > 0) {
  # Sum import values across years 2020-2022 and rice types
  fao_val[, total_val := rowSums(.SD, na.rm = TRUE), .SDcols = avail_yr]

  # Total rice imports per reporter from all partners
  total_by_reporter <- fao_val[, .(total_rice = sum(total_val, na.rm = TRUE)),
                                by = .(`Reporter Country Code`, `Reporter Countries`)]

  # Rice imports from India per reporter
  india_by_reporter <- fao_val[`Partner Country Code` %in% india_fao,
                                .(india_rice = sum(total_val, na.rm = TRUE)),
                                by = .(`Reporter Country Code`, `Reporter Countries`)]

  # Merge
  import_dep <- merge(total_by_reporter, india_by_reporter,
                       by = c("Reporter Country Code", "Reporter Countries"),
                       all.x = TRUE)
  import_dep[is.na(india_rice), india_rice := 0]
  import_dep[, india_share := ifelse(total_rice > 0, india_rice / total_rice, 0)]

  # Add ISO3 codes
  import_dep[, iso3 := countrycode(`Reporter Countries`, "country.name", "iso3c",
                                    warn = FALSE)]

  cat("\n=== Import Dependence Summary ===\n")
  cat("Countries with data:", nrow(import_dep), "\n")
  cat("Countries with India share > 0:", sum(import_dep$india_share > 0), "\n")
  cat("Countries with India share > 10%:", sum(import_dep$india_share > 0.10), "\n")
  cat("Countries with India share > 50%:", sum(import_dep$india_share > 0.50), "\n")

  cat("\nTop 20 India-dependent countries:\n")
  print(import_dep[order(-india_share)][1:20, .(
    country = `Reporter Countries`, iso3, india_share = round(india_share, 3),
    india_val = round(india_rice), total_val = round(total_rice)
  )])

  fwrite(import_dep, file.path(data_dir, "india_import_dependence.csv"))
  cat("Import dependence saved.\n")
} else {
  stop("No 2020-2022 year columns found in FAO data. Cannot construct treatment variable.")
}

cat("\n=== Data Fetch Complete ===\n")
cat("Files in data directory:\n")
print(list.files(data_dir, pattern = "\\.(csv|zip)$"))
