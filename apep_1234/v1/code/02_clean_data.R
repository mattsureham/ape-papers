## 02_clean_data.R — Parse and clean SBP data
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Parse Indicadores_Financieros.xlsx
# ============================================================
cat("=== Parsing Indicadores_Financieros.xlsx ===\n")

raw <- read_excel(file.path(data_dir, "Indicadores_Financieros.xlsx"),
                  sheet = 1, col_names = FALSE)

# Row 3 has dates (Excel serial numbers) in columns 2:ncol
date_row <- as.numeric(raw[3, 2:ncol(raw)])
dates <- as.Date(date_row, origin = "1899-12-30")
dates <- dates[!is.na(dates)]
cat("Date range:", as.character(min(dates)), "to", as.character(max(dates)), "\n")
cat("Number of months:", length(dates), "\n")

# Identify bank type blocks (rows with NA in column 2 are headers)
type_names <- raw$...1[!is.na(raw$...1)]
cat("Row labels found:\n")
print(type_names)

# Manual parsing: bank types start at specific rows
# Read all row labels
all_labels <- raw$...1
cat("\nAll row labels:\n")
for (i in 1:nrow(raw)) {
  if (!is.na(all_labels[i])) {
    cat(sprintf("  Row %d: %s\n", i, all_labels[i]))
  }
}

# Parse the data by identifying bank type blocks
# Each block: header row (NA in col 2) followed by 4 indicator rows (Roa, Roaa, Roe, Min)
indicators <- c("Roa", "Roaa", "Roe", "Min")

# Find header rows (rows where col 2 is NA and col 1 is not NA, excluding title/date rows)
header_rows <- which(!is.na(all_labels) & is.na(as.numeric(raw[, 2, drop = TRUE])))
# Remove the first 3 rows (title, blank, date header)
header_rows <- header_rows[header_rows > 3]
cat("\nHeader rows identified:", header_rows, "\n")

# Extract bank type names from headers
bank_types <- all_labels[header_rows]
cat("Bank types:", paste(bank_types, collapse = " | "), "\n")

# Build panel data
panel_list <- list()

for (b in seq_along(header_rows)) {
  btype <- bank_types[b]
  start_row <- header_rows[b] + 1
  end_row <- start_row + 3  # 4 indicator rows

  for (ind_idx in 1:4) {
    row_num <- start_row + ind_idx - 1
    if (row_num > nrow(raw)) next

    ind_name <- all_labels[row_num]
    values <- as.numeric(raw[row_num, 2:(length(dates) + 1)])

    panel_list[[length(panel_list) + 1]] <- tibble(
      bank_type = btype,
      indicator = tolower(ind_name),
      date = dates,
      value = values
    )
  }
}

panel <- bind_rows(panel_list)
cat("\nPanel dimensions:", nrow(panel), "rows\n")
cat("Bank types in panel:\n")
print(table(panel$bank_type))
cat("Indicators:\n")
print(table(panel$indicator))

# Pivot wider: one row per bank_type × date, columns for each indicator
panel_wide <- panel %>%
  pivot_wider(names_from = indicator, values_from = value) %>%
  mutate(
    year = year(date),
    month = month(date),
    # FATF grey-listing: June 2019 to September 2023
    grey_list = as.integer(date >= as.Date("2019-06-01") & date < as.Date("2023-10-01")),
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    # Time index (months since Jan 2016)
    t = as.integer(difftime(date, min(date), units = "days") / 30.44)
  )

# Classify treatment status
# Treatment: International License banks (maximally exposed to cross-border compliance pressure)
# Control: domestic-focused banks
panel_wide <- panel_wide %>%
  mutate(
    international = case_when(
      grepl("Internacional", bank_type, ignore.case = TRUE) ~ 1L,
      TRUE ~ 0L
    ),
    # Simplified treatment groups
    treat_group = case_when(
      grepl("Internacional", bank_type, ignore.case = TRUE) ~ "International License",
      grepl("Paname.*Priv|Panam.*Priv", bank_type, ignore.case = TRUE) ~ "Panamanian Private",
      grepl("Extranjer.*Priv", bank_type, ignore.case = TRUE) ~ "Foreign Private",
      grepl("Oficial", bank_type, ignore.case = TRUE) ~ "Official",
      grepl("Centro", bank_type, ignore.case = TRUE) ~ "Centro Bancario",
      grepl("Sistema", bank_type, ignore.case = TRUE) ~ "Sistema Bancario",
      TRUE ~ bank_type
    )
  )

cat("\nTreatment groups:\n")
print(table(panel_wide$treat_group))

# ============================================================
# 2. Parse BANCOS.xlsx (bank counts by license type over time)
# ============================================================
cat("\n=== Parsing BANCOS.xlsx ===\n")

sheets_bancos <- excel_sheets(file.path(data_dir, "BANCOS.xlsx"))
cat("Sheets available:", length(sheets_bancos), "\n")

# Parse each sheet to count banks by license type
bank_counts <- list()

for (s in sheets_bancos) {
  sheet_data <- tryCatch(
    read_excel(file.path(data_dir, "BANCOS.xlsx"), sheet = s, col_names = FALSE),
    error = function(e) NULL
  )
  if (is.null(sheet_data)) next

  # Extract month-year from sheet name or header
  # Sheet names are like "Noviembre 2019", "Enero  2020", etc.
  sheet_name <- trimws(s)

  # Count banks in each category by scanning for license headers
  all_text <- sheet_data[[1]]
  all_text[is.na(all_text)] <- ""

  # Find license category headers
  lic_gen_idx <- grep("LICENCIA GENERAL", all_text, ignore.case = TRUE)
  lic_int_idx <- grep("LICENCIA INTERNACIONAL|INTERNACIONAL$", all_text, ignore.case = TRUE)
  oficiales_idx <- grep("BANCOS OFICIALES", all_text, ignore.case = TRUE)

  # Count numbered entries (banks with a number in column 1)
  numbered <- which(!is.na(suppressWarnings(as.numeric(sheet_data[[1]]))))

  # Classify each numbered bank by its position relative to headers
  n_oficial <- 0
  n_general <- 0
  n_international <- 0

  for (idx in numbered) {
    if (length(lic_int_idx) > 0 && idx > max(lic_int_idx)) {
      n_international <- n_international + 1
    } else if (length(lic_gen_idx) > 0 && idx > max(lic_gen_idx[lic_gen_idx < ifelse(length(lic_int_idx) > 0, min(lic_int_idx), Inf)])) {
      n_general <- n_general + 1
    } else if (length(oficiales_idx) > 0 && idx > min(oficiales_idx)) {
      n_oficial <- n_oficial + 1
    }
  }

  bank_counts[[length(bank_counts) + 1]] <- tibble(
    sheet = sheet_name,
    n_oficial = n_oficial,
    n_general = n_general,
    n_international = n_international,
    n_total = length(numbered)
  )
}

bank_count_df <- bind_rows(bank_counts)
cat("Bank counts parsed for", nrow(bank_count_df), "months\n")
cat("Summary:\n")
print(bank_count_df %>%
        summarise(across(starts_with("n_"), list(mean = mean, min = min, max = max))))

# ============================================================
# 3. Save cleaned data
# ============================================================

# Main analysis panel
write_csv(panel_wide, file.path(data_dir, "panel_indicators.csv"))
cat("\nSaved panel_indicators.csv:", nrow(panel_wide), "rows\n")

# Bank counts
write_csv(bank_count_df, file.path(data_dir, "bank_counts.csv"))
cat("Saved bank_counts.csv:", nrow(bank_count_df), "rows\n")

# Print summary statistics for key groups
cat("\n=== Summary Statistics ===\n")
panel_wide %>%
  filter(treat_group %in% c("International License", "Panamanian Private", "Foreign Private")) %>%
  group_by(treat_group) %>%
  summarise(
    n_months = n(),
    roa_mean = mean(roa, na.rm = TRUE),
    roa_sd = sd(roa, na.rm = TRUE),
    roe_mean = mean(roe, na.rm = TRUE),
    roe_sd = sd(roe, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Check parallel trends visually: pre-treatment ROA
cat("\n=== Pre-treatment ROA (before June 2019) ===\n")
panel_wide %>%
  filter(date < as.Date("2019-06-01"),
         treat_group %in% c("International License", "Panamanian Private")) %>%
  group_by(treat_group) %>%
  summarise(
    roa_mean = mean(roa, na.rm = TRUE),
    roa_sd = sd(roa, na.rm = TRUE),
    roe_mean = mean(roe, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  print()
