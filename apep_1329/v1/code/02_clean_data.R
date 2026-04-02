## 02_clean_data.R — Clean and prepare FIT installation data
## APEP-1329: UK FIT Triple-Threshold Bunching

source("00_packages.R")

data_dir <- "../data"

# ── Read Excel files properly (skip header rows) ──
# The Ofgem FIT report has title rows before the actual column headers
# We need to find the header row first

cat("Inspecting file structure...\n")
f1 <- file.path(data_dir, "fit_part1.xlsx")

# Read first 10 rows to find the header
preview <- read_excel(f1, sheet = 1, n_max = 10, col_names = FALSE)
cat("First 10 rows of part 1:\n")
for (i in 1:min(10, nrow(preview))) {
  row_str <- paste(as.character(preview[i, 1:min(5, ncol(preview))]), collapse = " | ")
  cat(sprintf("  Row %d: %s\n", i, row_str))
}

# Find the header row (look for "Technology" or "Installed" or "Extension")
header_row <- NA
for (i in 1:10) {
  row_vals <- as.character(preview[i, ])
  if (any(grepl("Technology|Installed|Extension|Capacity|Postcode|Commission", row_vals, ignore.case = TRUE))) {
    header_row <- i
    cat(sprintf("\nHeader row found at row %d\n", i))
    cat("Headers:", paste(row_vals[!is.na(row_vals)], collapse = " | "), "\n")
    break
  }
}

if (is.na(header_row)) {
  # Try reading more rows
  preview <- read_excel(f1, sheet = 1, n_max = 20, col_names = FALSE)
  for (i in 1:20) {
    row_vals <- as.character(preview[i, ])
    if (any(grepl("Technology|Installed|Extension|Capacity|Postcode|Commission", row_vals, ignore.case = TRUE))) {
      header_row <- i
      cat(sprintf("\nHeader row found at row %d\n", i))
      break
    }
  }
}

stopifnot(!is.na(header_row))

# ── Read all three parts with correct skip ──
cat("\nReading all parts with skip =", header_row - 1, "(header at row", header_row, ")...\n")
all_parts <- list()

for (i in 1:3) {
  f <- file.path(data_dir, sprintf("fit_part%d.xlsx", i))
  # skip = header_row - 1 means skip the title rows, use row header_row as column names
  df_i <- read_excel(f, sheet = 1, skip = header_row - 1, guess_max = 50000)
  if (i == 1) {
    cat("Column names:", paste(names(df_i), collapse = ", "), "\n\n")
  }
  cat(sprintf("Part %d: %d rows\n", i, nrow(df_i)))
  all_parts[[i]] <- df_i
}

df <- bind_rows(all_parts)
cat(sprintf("\nCombined: %d rows, %d cols\n", nrow(df), ncol(df)))
cat("Column names:\n")
print(names(df))

# ── Standardize column names ──
# Look for key columns
names_lower <- tolower(names(df))

# Map columns
tech_col <- names(df)[grep("technol", names_lower)[1]]
cap_col <- names(df)[grep("capacity|kw", names_lower)[1]]
date_col <- names(df)[grep("commission", names_lower)[1]]
type_col <- names(df)[grep("installation type|install.*type|type.*install", names_lower)[1]]
post_col <- names(df)[grep("postcode", names_lower)[1]]
tariff_col <- names(df)[grep("tariff", names_lower)[1]]
la_col <- names(df)[grep("local auth|la name|la$|lsoa|region", names_lower)[1]]
ext_col <- names(df)[grep("extension", names_lower)[1]]

cat("\nKey columns identified:\n")
cat("  Technology:", tech_col, "\n")
cat("  Capacity:", cap_col, "\n")
cat("  Date:", date_col, "\n")
cat("  Type:", type_col, "\n")
cat("  Postcode:", post_col, "\n")
cat("  Tariff:", tariff_col, "\n")
cat("  LA:", la_col, "\n")
cat("  Extension:", ext_col, "\n")

# ── Filter to Solar PV ──
cat("\nTechnology distribution:\n")
print(table(df[[tech_col]], useNA = "always"))

df_solar <- df %>%
  filter(grepl("solar|photovoltaic|pv", .data[[tech_col]], ignore.case = TRUE))

cat(sprintf("\nSolar PV installations: %d (%.1f%% of total)\n",
            nrow(df_solar), 100 * nrow(df_solar) / nrow(df)))

# ── Create clean analysis dataset ──
df_clean <- df_solar %>%
  transmute(
    capacity_kw = as.numeric(.data[[cap_col]]),
    commission_date = as.Date(.data[[date_col]]),
    install_type = as.character(.data[[type_col]]),
    postcode = as.character(.data[[post_col]]),
    tariff_code = if (!is.null(tariff_col) && !is.na(tariff_col))
      as.character(.data[[tariff_col]]) else NA_character_,
    extension = if (!is.null(ext_col) && !is.na(ext_col))
      as.character(.data[[ext_col]]) else NA_character_
  ) %>%
  filter(
    !is.na(capacity_kw),
    capacity_kw > 0,
    !is.na(commission_date)
  )

# Add derived variables
df_clean <- df_clean %>%
  mutate(
    year = year(commission_date),
    month = month(commission_date),
    quarter = quarter(commission_date),
    year_q = paste0(year, "Q", quarter),
    # Period indicators
    pre_merger = commission_date < as.Date("2016-01-15"),
    post_merger = commission_date >= as.Date("2016-01-15"),
    period = case_when(
      year <= 2012 ~ "High tariff (2010-2012)",
      year <= 2015 ~ "Declining tariff (2013-2015)",
      TRUE ~ "Post-merger (2016-2019)"
    ),
    # Distance from each threshold
    dist_4kw = capacity_kw - 4,
    dist_10kw = capacity_kw - 10,
    dist_50kw = capacity_kw - 50
  )

cat(sprintf("\nClean dataset: %d installations\n", nrow(df_clean)))
cat("Year range:", min(df_clean$year), "-", max(df_clean$year), "\n")
cat("Capacity range:", round(min(df_clean$capacity_kw), 2), "-",
    round(max(df_clean$capacity_kw), 2), "kW\n")

cat("\nInstallations by year:\n")
print(table(df_clean$year))

cat("\nInstallation type:\n")
print(table(df_clean$install_type, useNA = "always"))

# ── Quick bunching check ──
cat("\n=== BUNCHING VALIDATION ===\n")
for (thresh in c(4, 10, 50)) {
  at <- sum(df_clean$capacity_kw == thresh, na.rm = TRUE)
  just_above <- sum(df_clean$capacity_kw > thresh & df_clean$capacity_kw <= thresh + 0.1, na.rm = TRUE)
  ratio <- if (just_above > 0) round(at / just_above) else Inf
  cat(sprintf("At %.0f kW: %d | At %.0f-%.1f kW: %d | Ratio: %s:1\n",
              thresh, at, thresh, thresh + 0.1, just_above,
              if (is.finite(ratio)) as.character(ratio) else "Inf"))
}

# ── Pre vs post merger at 4 kW ──
cat("\n=== 4 kW BUNCHING: PRE vs POST MERGER ===\n")
pre_at4 <- sum(df_clean$capacity_kw == 4 & df_clean$pre_merger, na.rm = TRUE)
pre_above4 <- sum(df_clean$capacity_kw > 4 & df_clean$capacity_kw <= 4.1 &
                    df_clean$pre_merger, na.rm = TRUE)
post_at4 <- sum(df_clean$capacity_kw == 4 & df_clean$post_merger, na.rm = TRUE)
post_above4 <- sum(df_clean$capacity_kw > 4 & df_clean$capacity_kw <= 4.1 &
                     df_clean$post_merger, na.rm = TRUE)
cat(sprintf("Pre-merger: %d at 4kW / %d at 4.0-4.1kW = %s:1\n",
            pre_at4, pre_above4,
            if (pre_above4 > 0) as.character(round(pre_at4 / pre_above4)) else "Inf"))
cat(sprintf("Post-merger: %d at 4kW / %d at 4.0-4.1kW = %s:1\n",
            post_at4, post_above4,
            if (post_above4 > 0) as.character(round(post_at4 / post_above4)) else "Inf"))

# Save
saveRDS(df_clean, file.path(data_dir, "fit_solar_clean.rds"))
cat("\nClean data saved to fit_solar_clean.rds\n")
