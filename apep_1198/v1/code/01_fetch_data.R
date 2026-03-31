## 01_fetch_data.R — Download Ofgem FIT Installation Report
## apep_1198: UK FIT Solar Bunching (Triple-Threshold Design)
##
## Source: Ofgem Feed-in Tariff Installation Report (30 September 2025)
## Three XLSX files, ~101 MB total, freely downloadable (no auth)
## Contains all FIT-accredited installations in Great Britain

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# DOWNLOAD OFGEM FIT INSTALLATION REPORT (Sep 2025 release)
# ============================================================

base_url <- "https://www.ofgem.gov.uk/sites/default/files/2025-10"
files <- c(
  "Feed-in%20Tariff%20Installation%20Report%20Part%201.xlsx",
  "Feed-in%20Tariff%20Installation%20Report%20Part%202.xlsx",
  "Feed-in%20Tariff%20Installation%20Report%20Part%203.xlsx"
)

local_files <- file.path(data_dir, c(
  "fit_report_part1.xlsx",
  "fit_report_part2.xlsx",
  "fit_report_part3.xlsx"
))

for (i in seq_along(files)) {
  if (!file.exists(local_files[i])) {
    cat(sprintf("Downloading Part %d...\n", i))
    url <- paste0(base_url, "/", files[i])
    download.file(url, local_files[i], mode = "wb", quiet = FALSE)
    cat(sprintf("  -> %s (%.1f MB)\n", local_files[i],
                file.size(local_files[i]) / 1e6))
  } else {
    cat(sprintf("Part %d already exists: %s\n", i, local_files[i]))
  }
}

# ============================================================
# READ AND COMBINE
# ============================================================

cat("\nReading Excel files (skipping header rows)...\n")
parts <- lapply(local_files, function(f) {
  cat(sprintf("  Reading %s...\n", basename(f)))
  # Row 4 contains the actual column headers; skip rows 1-3
  as.data.table(read_excel(f, skip = 3))
})

# Check column names are consistent
stopifnot(
  identical(names(parts[[1]]), names(parts[[2]])),
  identical(names(parts[[1]]), names(parts[[3]]))
)

dt_raw <- rbindlist(parts)
cat(sprintf("Total rows: %s\n", format(nrow(dt_raw), big.mark = ",")))
cat(sprintf("Columns: %s\n", paste(names(dt_raw), collapse = ", ")))

# ============================================================
# INSPECT COLUMN NAMES AND TYPES
# ============================================================

cat("\nColumn summary:\n")
print(str(dt_raw))

# Save column names for reference
writeLines(names(dt_raw), file.path(data_dir, "column_names.txt"))

# ============================================================
# FILTER TO SOLAR PV
# ============================================================

# Identify technology column (may vary by report version)
tech_cols <- grep("tech", names(dt_raw), ignore.case = TRUE, value = TRUE)
cat(sprintf("\nTechnology columns found: %s\n", paste(tech_cols, collapse = ", ")))

# Check unique technology values
if (length(tech_cols) > 0) {
  tech_col <- tech_cols[1]
  cat(sprintf("Technology values:\n"))
  print(table(dt_raw[[tech_col]]))

  # Filter to Solar PV (exact string may vary)
  solar_values <- grep("solar|photovoltaic|pv",
                        unique(dt_raw[[tech_col]]),
                        ignore.case = TRUE, value = TRUE)
  cat(sprintf("Solar PV values: %s\n", paste(solar_values, collapse = ", ")))

  dt_solar <- dt_raw[get(tech_col) %in% solar_values]
  cat(sprintf("Solar PV installations: %s\n",
              format(nrow(dt_solar), big.mark = ",")))
} else {
  stop("No technology column found! Check column names.")
}

# ============================================================
# IDENTIFY KEY VARIABLES
# ============================================================

# Capacity column
cap_cols <- grep("capacity|dnc|declared", names(dt_solar),
                  ignore.case = TRUE, value = TRUE)
cat(sprintf("\nCapacity columns: %s\n", paste(cap_cols, collapse = ", ")))

# Date column
date_cols <- grep("date|commission|confirm", names(dt_solar),
                   ignore.case = TRUE, value = TRUE)
cat(sprintf("Date columns: %s\n", paste(date_cols, collapse = ", ")))

# Tariff column
tariff_cols <- grep("tariff", names(dt_solar),
                     ignore.case = TRUE, value = TRUE)
cat(sprintf("Tariff columns: %s\n", paste(tariff_cols, collapse = ", ")))

# Geography columns
geo_cols <- grep("postcode|lsoa|local.auth|la_|region|country",
                  names(dt_solar), ignore.case = TRUE, value = TRUE)
cat(sprintf("Geography columns: %s\n", paste(geo_cols, collapse = ", ")))

# ============================================================
# SAVE RAW SOLAR DATA
# ============================================================

fwrite(dt_solar, file.path(data_dir, "ofgem_fit_solar_raw.csv"))
cat(sprintf("\nSaved: data/ofgem_fit_solar_raw.csv (%s rows)\n",
            format(nrow(dt_solar), big.mark = ",")))

# ============================================================
# QUICK VALIDATION: Check bunching at thresholds
# ============================================================

if (length(cap_cols) > 0) {
  cap_col <- cap_cols[1]
  dt_solar[, capacity_kw := as.numeric(get(cap_col))]

  cat("\n=== QUICK BUNCHING CHECK ===\n")

  # 4 kW threshold
  n_4_0 <- nrow(dt_solar[capacity_kw == 4.0])
  n_4_1 <- nrow(dt_solar[capacity_kw > 4.0 & capacity_kw <= 4.1])
  cat(sprintf("At 4.0 kW: %d | At 4.0-4.1 kW: %d | Raw ratio: %.0f:1\n",
              n_4_0, n_4_1, ifelse(n_4_1 > 0, n_4_0 / n_4_1, Inf)))

  # 10 kW threshold
  n_10_0 <- nrow(dt_solar[capacity_kw == 10.0])
  n_10_1 <- nrow(dt_solar[capacity_kw > 10.0 & capacity_kw <= 10.1])
  cat(sprintf("At 10.0 kW: %d | At 10.0-10.1 kW: %d | Raw ratio: %.0f:1\n",
              n_10_0, n_10_1, ifelse(n_10_1 > 0, n_10_0 / n_10_1, Inf)))

  # 50 kW threshold
  n_50_0 <- nrow(dt_solar[capacity_kw == 50.0])
  n_50_1 <- nrow(dt_solar[capacity_kw > 50.0 & capacity_kw <= 51.0])
  cat(sprintf("At 50.0 kW: %d | At 50.0-51.0 kW: %d | Raw ratio: %.0f:1\n",
              n_50_0, n_50_1, ifelse(n_50_1 > 0, n_50_0 / n_50_1, Inf)))

  # Capacity distribution summary
  cat("\nCapacity distribution (quantiles):\n")
  print(quantile(dt_solar$capacity_kw, probs = c(0, 0.01, 0.05, 0.25, 0.5,
                                                    0.75, 0.95, 0.99, 1),
                  na.rm = TRUE))
}

cat("\n01_fetch_data.R complete.\n")
