## =============================================================================
## 02_clean_data.R — Parse HMRC ODS files and construct analysis datasets
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir <- "../data"
hmrc_dir <- file.path(data_dir, "hmrc")

## ---- 1. Parse HMRC Table 3.1a: 99 percentile points for total income --------

raw_pct <- as.data.frame(read_ods(file.path(hmrc_dir, "Table_3_1a_percentiles.ods"),
                                   sheet = "Table_3_1a_before_tax",
                                   col_names = FALSE))

# Find the header row: must have "Percentile point" AND non-NA values in col 2
candidate_rows <- which(grepl("Percentile point", raw_pct[, 1]))
hdr_idx <- NA
for (r in candidate_rows) {
  if (!is.na(raw_pct[r, 2])) { hdr_idx <- r; break }
}
stopifnot("Cannot find header" = !is.na(hdr_idx))
cat("Header row found at index:", hdr_idx, "\n")

# Extract year names from header
year_names <- as.character(raw_pct[hdr_idx, 2:ncol(raw_pct)])
year_names <- year_names[!is.na(year_names) & year_names != ""]
n_years <- length(year_names)
cat("Found", n_years, "year columns\n")

# Parse tax year start from "YYYY to YYYY" format, removing any [note] tags
parse_year <- function(s) {
  s <- gsub("\\[.*\\]", "", s)
  as.integer(trimws(sub(" to .*", "", s)))
}
year_values <- sapply(year_names, parse_year)
cat("Years:", paste(range(year_values, na.rm = TRUE), collapse = "-"), "\n")

# Extract data starting after header
data_start <- hdr_idx + 1
data_end <- nrow(raw_pct)

# Build long-format percentile data
pct_list <- list()
for (i in data_start:data_end) {
  pctile <- suppressWarnings(as.integer(raw_pct[i, 1]))
  if (is.na(pctile) || pctile < 1 || pctile > 99) next

  for (j in seq_len(n_years)) {
    yr <- year_values[j]
    if (is.na(yr)) next

    val_raw <- as.character(raw_pct[i, j + 1])
    if (is.na(val_raw) || grepl("Not available", val_raw, fixed = TRUE)) next

    val <- suppressWarnings(as.numeric(gsub(",", "", val_raw)))
    if (is.na(val)) next

    pct_list[[length(pct_list) + 1]] <- list(
      tax_year = yr, percentile = pctile, income = val
    )
  }
}

spi_pct <- rbindlist(pct_list)
stopifnot("SPI percentile data insufficient" = nrow(spi_pct) > 500)
cat("SPI percentiles:", nrow(spi_pct), "observations across",
    uniqueN(spi_pct$tax_year), "years\n")

# Verify data makes sense: P50 should be between 15k-30k for recent years
check <- spi_pct[percentile == 50 & tax_year == 2022]
cat("Sanity check — P50 income (2022):", check$income, "\n")
stopifnot("P50 income unreasonable" = check$income > 10000 & check$income < 50000)

# Add endpoints: P0 = 0 and P100 = 1.5x P99
spi_pct <- rbind(
  spi_pct,
  spi_pct[, .(percentile = 0L, income = 0), by = tax_year],
  spi_pct[percentile == 99, .(percentile = 100L, income = income * 1.5), by = tax_year]
)
setorder(spi_pct, tax_year, percentile)

## ---- 2. Construct density from percentile data ------------------------------

compute_density <- function(dt) {
  dt <- dt[order(percentile)]
  n <- nrow(dt)
  if (n < 10) return(data.table())

  midpoints <- (dt$income[-1] + dt$income[-n]) / 2
  bin_widths <- diff(dt$income)
  pct_widths <- diff(dt$percentile) / 100

  density <- ifelse(bin_widths > 0, pct_widths / bin_widths, NA_real_)

  data.table(
    income_midpoint = midpoints,
    income_lower = dt$income[-n],
    income_upper = dt$income[-1],
    bin_width = bin_widths,
    pct_width = pct_widths,
    density = density,
    percentile_lower = dt$percentile[-n],
    percentile_upper = dt$percentile[-1]
  )
}

spi_density <- spi_pct[, compute_density(.SD), by = tax_year]
spi_density <- spi_density[!is.na(density) & density > 0]

cat("SPI density:", nrow(spi_density), "bins across",
    uniqueN(spi_density$tax_year), "years\n")

# Check density near £50k for a recent year
dens_50k <- spi_density[tax_year == 2022 & income_lower <= 50000 & income_upper > 50000]
cat("Density bin at £50k (2022):", dens_50k$income_lower, "-", dens_50k$income_upper,
    "density =", dens_50k$density, "\n")

## ---- 3. Construct ASHE percentile dataset -----------------------------------
ashe_ft <- fread(file.path(data_dir, "ashe_ft_all.csv"))

item_to_pctile <- c(
  "6" = 10, "7" = 20, "8" = 25, "9" = 30, "10" = 40,
  "2" = 50, "11" = 60, "12" = 70, "13" = 75, "14" = 80, "15" = 90
)

ashe_pct <- ashe_ft[item_code %in% as.integer(names(item_to_pctile))]
ashe_pct[, percentile := item_to_pctile[as.character(item_code)]]
setnames(ashe_pct, "value", "income")
ashe_pct <- ashe_pct[!is.na(income) & income > 0, .(year, percentile, income)]

ashe_njobs <- ashe_ft[item_code == 1, .(year, n_jobs_k = value)]

# Add endpoints
ashe_pct_ext <- rbind(
  ashe_pct,
  ashe_pct[, .(percentile = 0L, income = 0), by = year],
  ashe_pct[percentile == 90, .(percentile = 100L, income = income * 2), by = year]
)
setorder(ashe_pct_ext, year, percentile)

ashe_density <- ashe_pct_ext[, compute_density(.SD), by = year]
ashe_density <- ashe_density[!is.na(density) & density > 0]

cat("ASHE density:", nrow(ashe_density), "bins across",
    uniqueN(ashe_density$year), "years\n")

## ---- 4. Gender-specific ASHE density ----------------------------------------
ashe_m <- fread(file.path(data_dir, "ashe_ft_male.csv"))
ashe_f <- fread(file.path(data_dir, "ashe_ft_female.csv"))

build_gender_density <- function(dt, label) {
  pct <- dt[item_code %in% as.integer(names(item_to_pctile))]
  pct[, percentile := item_to_pctile[as.character(item_code)]]
  setnames(pct, "value", "income")
  pct <- pct[!is.na(income) & income > 0, .(year, percentile, income)]
  pct_ext <- rbind(
    pct,
    pct[, .(percentile = 0L, income = 0), by = year],
    pct[percentile == 90, .(percentile = 100L, income = income * 2), by = year]
  )
  setorder(pct_ext, year, percentile)
  dens <- pct_ext[, compute_density(.SD), by = year]
  dens[, sex := label]
  dens[!is.na(density) & density > 0]
}

ashe_gender_density <- rbind(
  build_gender_density(ashe_m, "Male"),
  build_gender_density(ashe_f, "Female")
)
cat("ASHE gender density:", nrow(ashe_gender_density), "bins\n")

## ---- 5. Parse Table 3.5: Pension contributions by income band ---------------
raw_3_5 <- as.data.frame(read_ods(file.path(hmrc_dir, "Tables_3_1_to_3_17.ods"),
                                   sheet = "Table_3_5", col_names = FALSE))

hdr_3_5 <- which(grepl("Range of total income", raw_3_5[, 1]))[1]
col_names_raw <- as.character(raw_3_5[hdr_3_5, ])

data_3_5 <- raw_3_5[(hdr_3_5 + 1):nrow(raw_3_5), ]
data_3_5 <- data_3_5[!grepl("All ranges|End of", data_3_5[, 1], ignore.case = TRUE) &
                       !is.na(data_3_5[, 1]) & data_3_5[, 1] != "", ]

# Parse: col1 = income_lower, col2 = n_individuals, col3 = total_income
# Need to identify pension columns from header
cat("Table 3.5 columns:", paste(col_names_raw[1:min(10, length(col_names_raw))], collapse = " | "), "\n")

pension_dt <- data.table(
  income_lower = suppressWarnings(as.numeric(gsub(",", "", data_3_5[, 1]))),
  n_total_k = suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", data_3_5[, 2]))),
  total_income_m = suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", data_3_5[, 3])))
)

# Columns 5 and 6: pension relief (number and amount)
if (ncol(data_3_5) >= 6) {
  pension_dt[, n_with_pension_k := suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", data_3_5[, 5])))]
  pension_dt[, pension_relief_m := suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", data_3_5[, 6])))]
}
pension_dt <- pension_dt[!is.na(income_lower)]
cat("Pension data:", nrow(pension_dt), "bands\n")

## ---- 6. Parse Table 3.11: Self-employment by income band --------------------
raw_3_11 <- as.data.frame(read_ods(file.path(hmrc_dir, "Tables_3_1_to_3_17.ods"),
                                    sheet = "Table_3_11", col_names = FALSE))

hdr_3_11 <- which(grepl("Region or country", raw_3_11[, 1]))[1]
data_3_11 <- raw_3_11[(hdr_3_11 + 1):nrow(raw_3_11), ]
data_3_11 <- data_3_11[!grepl("End of", data_3_11[, 1], ignore.case = TRUE) &
                         !is.na(data_3_11[, 1]) & data_3_11[, 1] != "", ]

# UK-level, All population
uk_all <- data_3_11[data_3_11[, 1] == "United Kingdom" & data_3_11[, 2] == "All", ]

se_income <- data.table(
  income_lower = suppressWarnings(as.numeric(gsub(",", "", uk_all[, 3]))),
  n_se_k = suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", uk_all[, 4]))),
  se_income_m = suppressWarnings(as.numeric(gsub(",|\\[.*\\]", "", uk_all[, 5])))
)
se_income <- se_income[!is.na(income_lower)]
cat("Self-employment data:", nrow(se_income), "bands\n")

## ---- 7. Period indicators and save ------------------------------------------
spi_density[, period := fifelse(tax_year < 2013, "pre_hicbc", "post_hicbc")]
ashe_density[, period := fifelse(year < 2013, "pre_hicbc", "post_hicbc")]
ashe_gender_density[, period := fifelse(year < 2013, "pre_hicbc", "post_hicbc")]

fwrite(spi_pct, file.path(data_dir, "spi_percentiles.csv"))
fwrite(spi_density, file.path(data_dir, "spi_density.csv"))
fwrite(ashe_density, file.path(data_dir, "ashe_density.csv"))
fwrite(ashe_gender_density, file.path(data_dir, "ashe_gender_density.csv"))
fwrite(ashe_njobs, file.path(data_dir, "ashe_njobs.csv"))
fwrite(pension_dt, file.path(data_dir, "pension_by_income.csv"))
fwrite(se_income, file.path(data_dir, "selfemployment_by_income.csv"))

cat("\n=== CLEANING COMPLETE ===\n")
cat("SPI: ", nrow(spi_pct), "percentile obs,", nrow(spi_density), "density bins\n")
cat("ASHE:", nrow(ashe_density), "density bins\n")
cat("Pension:", nrow(pension_dt), "bands\n")
cat("Self-employment:", nrow(se_income), "bands\n")
