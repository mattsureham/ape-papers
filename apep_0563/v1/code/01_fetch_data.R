## ============================================================================
## 01_fetch_data.R — Data Acquisition
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================
## Data sources:
## 1. Japan CPI by food subcategory (chain-linked 2020=100), monthly 2015-2024
##    Source: Japan Statistics Bureau via stat.go.jp/data/cpi/
##    Categories: eating_out (10%), cooked_food (8%), alcoholic_beverages (10%)
## 2. Detailed CPI with individual food items for heterogeneity analysis
## 3. OECD COICOP CPI for cross-validation
## ============================================================================

source("00_packages.R")

data_dir <- "../data"

## --- 1. Primary CPI Data: Food Subcategories ---
cat("=== Loading primary CPI data ===\n")
cpi_file <- file.path(data_dir, "japan_cpi_food_subcategories_2015_2024.csv")
if (!file.exists(cpi_file)) {
  stop("Primary CPI data not found: ", cpi_file,
       "\nThis file must be downloaded from stat.go.jp CPI archives.")
}
cpi <- fread(cpi_file)
cat("CPI data loaded:", nrow(cpi), "rows,", ncol(cpi), "columns\n")
cat("Date range:", min(cpi$yyyymm), "to", max(cpi$yyyymm), "\n")

## --- 2. Detailed CPI Data: Individual Food Items ---
cat("\n=== Loading detailed CPI data ===\n")
detail_file <- file.path(data_dir, "japan_cpi_detailed_food_2015_2024.csv")
if (!file.exists(detail_file)) {
  stop("Detailed CPI data not found: ", detail_file)
}
cpi_detail <- fread(detail_file)
cat("Detailed CPI loaded:", nrow(cpi_detail), "rows,", ncol(cpi_detail), "columns\n")

## --- 3. OECD Cross-Validation Data ---
cat("\n=== Loading OECD cross-validation data ===\n")
oecd_file <- file.path(data_dir, "oecd_japan_cpi_coicop_wide.csv")
if (file.exists(oecd_file)) {
  oecd <- fread(oecd_file)
  cat("OECD data loaded:", nrow(oecd), "rows\n")
} else {
  cat("WARNING: OECD cross-validation data not found. Proceeding without.\n")
  oecd <- NULL
}

## --- 4. FIES Expenditure Growth Rates (2018-2019) ---
cat("\n=== Loading FIES expenditure growth rates ===\n")
fies_file <- file.path(data_dir, "disc_adj.xls")
if (file.exists(fies_file)) {
  library(readxl)
  fies_raw <- read_excel(fies_file, sheet = "二人以上-名目（月）", col_names = FALSE)

  # Extract year-over-year nominal growth rates for key categories
  # Rows: 15=food, 45=prepared food, 52=alcohol, 53=eating out
  # Cols: 11-22 = Jan-Dec 2018, 23-34 = Jan-Dec 2019
  extract_fies_row <- function(row_num, category_name) {
    vals_2018 <- as.numeric(fies_raw[row_num, 11:22])
    vals_2019 <- as.numeric(fies_raw[row_num, 23:34])
    data.table(
      category = category_name,
      year = c(rep(2018, 12), rep(2019, 12)),
      month = rep(1:12, 2),
      yoy_growth_pct = c(vals_2018, vals_2019)
    )
  }

  fies <- rbindlist(list(
    extract_fies_row(15, "food"),
    extract_fies_row(45, "cooked_food"),
    extract_fies_row(52, "alcoholic_beverages"),
    extract_fies_row(53, "eating_out")
  ))
  fies[, yyyymm := year * 100 + month]
  cat("FIES growth rates loaded:", nrow(fies), "rows\n")
} else {
  cat("WARNING: FIES data not found. CPI analysis will be primary.\n")
  fies <- NULL
}

## --- Save processed data ---
cat("\n=== Saving processed data ===\n")
fwrite(cpi, file.path(data_dir, "cpi_clean.csv"))
fwrite(cpi_detail, file.path(data_dir, "cpi_detail_clean.csv"))
if (!is.null(fies)) fwrite(fies, file.path(data_dir, "fies_growth_clean.csv"))

## === DATA VALIDATION (required) ===
stopifnot("Expected 120 monthly observations" = nrow(cpi) == 120)
stopifnot("Expected 2015-2024 range" = min(cpi$year) == 2015 & max(cpi$year) == 2024)
stopifnot("Key columns present" = all(c("eating_out", "cooked_food", "alcoholic_beverages") %in% names(cpi)))
stopifnot("No missing values in key series" = !any(is.na(cpi$eating_out)) &
            !any(is.na(cpi$cooked_food)) & !any(is.na(cpi$alcoholic_beverages)))

cat("\nData validation passed:", nrow(cpi), "months,",
    "eating_out range:", round(range(cpi$eating_out), 1),
    "cooked_food range:", round(range(cpi$cooked_food), 1),
    "alcohol range:", round(range(cpi$alcoholic_beverages), 1), "\n")
cat("\n✓ All data loaded and validated.\n")
