# 02_clean_data.R — Clean and construct analysis datasets
# Two-pronged approach:
# 1. NOMIS aggregate: Size-band enterprise counts by region×year×industry
# 2. Companies House micro: Exact employee counts from iXBRL filings

source("00_packages.R")

cat("=== Cleaning Data for Bunching Analysis ===\n")

# =========================================================================
# PART 1: Parse ALL Companies House iXBRL for exact employee counts
# The initial fetch only parsed 5,000 of 15,551 files. Parse all now,
# then download and parse additional days for a larger sample.
# =========================================================================

cat("\n--- Part 1: Expanding Companies House microdata ---\n")

parse_employee_count <- function(file_path) {
  tryCatch({
    lines <- readLines(file_path, warn = FALSE, n = 500)
    text <- paste(lines, collapse = "\n")

    patterns <- c(
      "AverageNumberEmployeesDuringPeriod[^>]*>\\s*([0-9,]+)\\s*<",
      "NumberOfEmployees[^>]*>\\s*([0-9,]+)\\s*<",
      "AverageNumberOfEmployees[^>]*>\\s*([0-9,]+)\\s*<",
      "EmployeesTotal[^>]*>\\s*([0-9,]+)\\s*<"
    )

    for (pat in patterns) {
      m <- regmatches(text, regexpr(pat, text, perl = TRUE))
      if (length(m) > 0) {
        num_str <- sub(".*>\\s*([0-9,]+)\\s*<.*", "\\1", m[1])
        num <- as.numeric(gsub(",", "", num_str))
        if (!is.na(num) && num > 0 && num < 1e6) {
          return(num)
        }
      }
    }
    return(NA_real_)
  }, error = function(e) NA_real_)
}

# Parse turnover from iXBRL
parse_turnover <- function(file_path) {
  tryCatch({
    lines <- readLines(file_path, warn = FALSE, n = 800)
    text <- paste(lines, collapse = "\n")

    patterns <- c(
      "TurnoverRevenue[^>]*>\\s*([0-9,]+)\\s*<",
      "Turnover[^>]*contextRef[^>]*>\\s*([0-9,]+)\\s*<",
      "Revenue[^>]*>\\s*([0-9,]+)\\s*<"
    )

    for (pat in patterns) {
      m <- regmatches(text, regexpr(pat, text, perl = TRUE))
      if (length(m) > 0) {
        num_str <- sub(".*>\\s*([0-9,]+)\\s*<.*", "\\1", m[1])
        num <- as.numeric(gsub(",", "", num_str))
        if (!is.na(num) && num > 0 && num < 1e12) {
          return(num)
        }
      }
    }
    return(NA_real_)
  }, error = function(e) NA_real_)
}

# Extract company number from filename
parse_company_number <- function(file_path) {
  bn <- basename(file_path)
  # Pattern: Prod???_????_CompanyNumber_...
  m <- regmatches(bn, regexpr("[0-9]{6,8}", bn))
  if (length(m) > 0) return(m[1])
  return(NA_character_)
}

# Parse all available CH filings
ch_zip <- list.files("../data", pattern = "ch_accounts_.*\\.zip$",
                      full.names = TRUE)

all_emp_data <- list()

for (zf in ch_zip) {
  date_str <- sub(".*ch_accounts_(.*)\\.zip", "\\1", basename(zf))
  cat("Processing filings from", date_str, "...\n")

  extract_dir <- paste0("../data/ch_extract_", date_str)
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
  unzip(zf, exdir = extract_dir, overwrite = TRUE)

  html_files <- list.files(extract_dir, pattern = "\\.(html|htm|xbrl)$",
                           recursive = TRUE, full.names = TRUE)
  cat("  Found", length(html_files), "filings\n")

  # Parse ALL files (not a sample)
  emp_counts <- vapply(html_files, parse_employee_count, numeric(1))
  turnover <- vapply(html_files, parse_turnover, numeric(1))
  co_nums <- vapply(html_files, parse_company_number, character(1))

  day_df <- data.frame(
    company_number = co_nums,
    employees = emp_counts,
    turnover = turnover,
    filing_date = date_str,
    stringsAsFactors = FALSE
  )

  # Keep firms with at least employee count
  day_df <- day_df[!is.na(day_df$employees), ]
  cat("  Valid employee counts:", nrow(day_df), "\n")

  all_emp_data[[date_str]] <- day_df
  unlink(extract_dir, recursive = TRUE)
}

# Download additional days if we have fewer than 5,000 observations
current_n <- sum(sapply(all_emp_data, nrow))
cat("\nCurrent total observations:", current_n, "\n")

if (current_n < 5000) {
  cat("Need more data. Downloading additional filing days...\n")

  # Try more dates
  extra_dates <- format(Sys.Date() - 15:45, "%Y-%m-%d")
  for (d in extra_dates) {
    if (current_n >= 8000) break

    dest <- paste0("../data/ch_accounts_", d, ".zip")
    if (file.exists(dest)) next

    url <- paste0("http://download.companieshouse.gov.uk/Accounts_Bulk_Data-",
                  d, ".zip")
    resp <- tryCatch(httr::HEAD(url, httr::timeout(10)), error = function(e) NULL)
    if (is.null(resp) || httr::status_code(resp) != 200) next

    tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      cat("  Downloaded", d, "(", round(file.size(dest)/1e6, 1), "MB)\n")

      extract_dir <- paste0("../data/ch_extract_", d)
      dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
      unzip(dest, exdir = extract_dir, overwrite = TRUE)

      html_files <- list.files(extract_dir, pattern = "\\.(html|htm|xbrl)$",
                               recursive = TRUE, full.names = TRUE)

      emp_counts <- vapply(html_files, parse_employee_count, numeric(1))
      turnover <- vapply(html_files, parse_turnover, numeric(1))
      co_nums <- vapply(html_files, parse_company_number, character(1))

      day_df <- data.frame(
        company_number = co_nums,
        employees = emp_counts,
        turnover = turnover,
        filing_date = d,
        stringsAsFactors = FALSE
      )
      day_df <- day_df[!is.na(day_df$employees), ]
      cat("    Valid counts:", nrow(day_df), "\n")

      all_emp_data[[d]] <- day_df
      current_n <- current_n + nrow(day_df)
      unlink(extract_dir, recursive = TRUE)
    }, error = function(e) {
      cat("    Error processing", d, ":", conditionMessage(e), "\n")
    })
  }
}

# Combine all microdata
micro_df <- do.call(rbind, all_emp_data)
cat("\n=== Microdata Summary ===\n")
cat("Total observations with employee counts:", nrow(micro_df), "\n")
cat("Unique companies:", length(unique(micro_df$company_number)), "\n")
cat("Filing dates:", length(unique(micro_df$filing_date)), "\n")

cat("\nEmployee count distribution:\n")
print(summary(micro_df$employees))

# Histogram of exact employee counts
cat("\nCounts by employee number (1-300):\n")
emp_tab <- table(factor(pmin(micro_df$employees, 300),
                         levels = 1:300))
# Show counts near thresholds
cat("  Employees 1-15:\n")
print(emp_tab[1:15])
cat("  Employees 40-60:\n")
print(emp_tab[40:60])
cat("  Employees 200-300:\n")
print(emp_tab[200:300])

fwrite(micro_df, "../data/ch_microdata_clean.csv")
cat("\nSaved microdata:", nrow(micro_df), "rows\n")

# =========================================================================
# PART 2: Clean NOMIS aggregate data
# =========================================================================

cat("\n--- Part 2: Cleaning NOMIS aggregate data ---\n")

# Enterprise counts by size band
ent_raw <- fread("../data/nomis_business_counts_raw.csv")

# Keep only detailed size bands (not aggregated categories)
detailed_bands <- c("0 to 4", "5 to 9", "10 to 19", "20 to 49",
                    "50 to 99", "100 to 249", "250 to 499",
                    "500 to 999", "1000+")

ent <- ent_raw %>%
  filter(EMPLOYMENT_SIZEBAND_NAME %in% detailed_bands) %>%
  mutate(
    year = as.integer(DATE_NAME),
    size_band = EMPLOYMENT_SIZEBAND_NAME,
    n_enterprises = as.numeric(OBS_VALUE),
    # Create midpoint for each band (for density plotting)
    band_lower = case_when(
      size_band == "0 to 4" ~ 0,
      size_band == "5 to 9" ~ 5,
      size_band == "10 to 19" ~ 10,
      size_band == "20 to 49" ~ 20,
      size_band == "50 to 99" ~ 50,
      size_band == "100 to 249" ~ 100,
      size_band == "250 to 499" ~ 250,
      size_band == "500 to 999" ~ 500,
      size_band == "1000+" ~ 1000
    ),
    band_upper = case_when(
      size_band == "0 to 4" ~ 4,
      size_band == "5 to 9" ~ 9,
      size_band == "10 to 19" ~ 19,
      size_band == "20 to 49" ~ 49,
      size_band == "50 to 99" ~ 99,
      size_band == "100 to 249" ~ 249,
      size_band == "250 to 499" ~ 499,
      size_band == "500 to 999" ~ 999,
      size_band == "1000+" ~ 5000
    ),
    band_width = band_upper - band_lower + 1,
    band_midpoint = (band_lower + pmin(band_upper, 1000)) / 2,
    # Density = enterprises per employee-count bin
    density = n_enterprises / band_width
  ) %>%
  select(year, size_band, band_lower, band_upper, band_width,
         band_midpoint, n_enterprises, density)

cat("NOMIS enterprise data: years", min(ent$year), "-", max(ent$year), "\n")
cat("Size bands:", length(unique(ent$size_band)), "\n")

# Show UK-level totals for recent year
cat("\nEnterprise counts by size band (UK total, 2024):\n")
ent_2024 <- ent %>%
  filter(year == max(year)) %>%
  group_by(size_band, band_lower) %>%
  summarise(total = sum(n_enterprises, na.rm = TRUE),
            density = sum(density, na.rm = TRUE),
            .groups = "drop") %>%
  arrange(band_lower)
print(as.data.frame(ent_2024))

# Local units (establishments rather than enterprises)
lu_raw <- fread("../data/nomis_local_units_raw.csv")

lu <- lu_raw %>%
  filter(EMPLOYMENT_SIZEBAND_NAME %in% detailed_bands) %>%
  mutate(
    year = as.integer(DATE_NAME),
    size_band = EMPLOYMENT_SIZEBAND_NAME,
    n_units = as.numeric(OBS_VALUE),
    band_lower = case_when(
      size_band == "0 to 4" ~ 0,
      size_band == "5 to 9" ~ 5,
      size_band == "10 to 19" ~ 10,
      size_band == "20 to 49" ~ 20,
      size_band == "50 to 99" ~ 50,
      size_band == "100 to 249" ~ 100,
      size_band == "250 to 499" ~ 250,
      size_band == "500 to 999" ~ 500,
      size_band == "1000+" ~ 1000
    ),
    band_upper = case_when(
      size_band == "0 to 4" ~ 4,
      size_band == "5 to 9" ~ 9,
      size_band == "10 to 19" ~ 19,
      size_band == "20 to 49" ~ 49,
      size_band == "50 to 99" ~ 99,
      size_band == "100 to 249" ~ 249,
      size_band == "250 to 499" ~ 499,
      size_band == "500 to 999" ~ 999,
      size_band == "1000+" ~ 5000
    ),
    band_width = band_upper - band_lower + 1,
    density = n_units / band_width
  ) %>%
  select(year, size_band, band_lower, band_upper, band_width,
         n_units, density)

cat("\nLocal units by size band (UK total, 2024):\n")
lu_2024 <- lu %>%
  filter(year == max(year)) %>%
  group_by(size_band, band_lower) %>%
  summarise(total = sum(n_units, na.rm = TRUE),
            density = sum(density, na.rm = TRUE),
            .groups = "drop") %>%
  arrange(band_lower)
print(as.data.frame(lu_2024))

# =========================================================================
# PART 3: Construct bunching analysis variables
# =========================================================================

cat("\n--- Part 3: Constructing bunching variables ---\n")

# For NOMIS: compute density ratios at regulatory thresholds
# Key idea: If firms bunch below threshold k, the band just below k
# will have higher density than predicted by a smooth curve

# Create panel: geography × year × size_band
# Using enterprise data at geography level
ent_panel <- ent_raw %>%
  filter(EMPLOYMENT_SIZEBAND_NAME %in% detailed_bands) %>%
  mutate(
    year = as.integer(DATE_NAME),
    geography = GEOGRAPHY_NAME,
    size_band = EMPLOYMENT_SIZEBAND_NAME,
    n_enterprises = as.numeric(OBS_VALUE)
  ) %>%
  filter(!is.na(n_enterprises)) %>%
  select(year, geography, size_band, n_enterprises)

# Create density ratios at thresholds
# Threshold 1 (10 employees): Compare density in 5-9 vs 10-19
# Threshold 2 (50 employees): Compare density in 20-49 vs 50-99
# Threshold 3 (250 employees): Compare density in 100-249 vs 250-499

# First aggregate to geography×year level (collapse any duplicates)
ent_agg <- ent_panel %>%
  group_by(year, geography, size_band) %>%
  summarise(n_enterprises = sum(n_enterprises, na.rm = TRUE), .groups = "drop")

threshold_ratios <- ent_agg %>%
  pivot_wider(names_from = size_band, values_from = n_enterprises,
              values_fill = 0) %>%
  mutate(
    # Density per employee-number bin
    d_5_9 = `5 to 9` / 5,
    d_10_19 = `10 to 19` / 10,
    d_20_49 = `20 to 49` / 30,
    d_50_99 = `50 to 99` / 50,
    d_100_249 = `100 to 249` / 150,
    d_250_499 = `250 to 499` / 250,
    # Ratios: below/above at each threshold
    ratio_10 = d_5_9 / d_10_19,
    ratio_50 = d_20_49 / d_50_99,
    ratio_250 = d_100_249 / d_250_499,
    # Log ratios for regression
    log_ratio_10 = log(ratio_10),
    log_ratio_50 = log(ratio_50),
    log_ratio_250 = log(ratio_250)
  )

cat("Threshold ratios (UK total, latest year):\n")
uk_ratios <- threshold_ratios %>%
  filter(geography == "United Kingdom",
         year == max(year))
cat(sprintf("  10-employee: below/above density ratio = %.3f\n",
            uk_ratios$ratio_10))
cat(sprintf("  50-employee: below/above density ratio = %.3f\n",
            uk_ratios$ratio_50))
cat(sprintf("  250-employee: below/above density ratio = %.3f\n",
            uk_ratios$ratio_250))

# Time series of ratios for UK
uk_ts <- threshold_ratios %>%
  filter(geography == "United Kingdom") %>%
  select(year, ratio_10, ratio_50, ratio_250)

cat("\nThreshold ratios over time (UK):\n")
print(as.data.frame(uk_ts))

# Save cleaned datasets
fwrite(ent, "../data/enterprises_by_sizeband.csv")
fwrite(lu, "../data/local_units_by_sizeband.csv")
fwrite(threshold_ratios, "../data/threshold_ratios.csv")

cat("\n=== Data Cleaning Complete ===\n")
cat("Files saved:\n")
print(list.files("../data", pattern = "\\.csv$"))
