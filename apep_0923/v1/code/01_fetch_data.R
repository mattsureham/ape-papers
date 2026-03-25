## 01_fetch_data.R — Parse BIS bulk CSV + construct AEOI dates
## APEP-0923: The End of Banking Secrecy

source("00_packages.R")

# ---------------------------------------------------------------
# 1. AEOI Activation Dates (Switzerland bilateral)
# ---------------------------------------------------------------
cat("=== Constructing AEOI activation dates ===\n")

aeoi_dates <- data.table(
  cp_country = c(
    # Wave 1: Data collection from Jan 1, 2017 (first exchange Sep 2018)
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE",
    "GB", "GG", "JE", "IM", "IS", "NO", "LI", "KR", "JP", "AU", "CA",
    # Wave 2: Data collection from Jan 1, 2018
    "AR", "BR", "CL", "CN", "CO", "CR", "IN", "ID", "IL", "MY",
    "MX", "NZ", "PA", "PE", "RU", "SA", "SG", "ZA", "TH", "TR", "AE", "UY",
    # Wave 3: Data collection from Jan 1, 2019
    "GH", "KE", "NG", "PK", "PH", "UA", "KZ", "DO", "EC", "JM",
    # Wave 4: Data collection from Jan 1, 2020
    "TT", "MU", "BH", "LB"
  ),
  aeoi_start = as.Date(c(
    rep("2017-01-01", 38),
    rep("2018-01-01", 22),
    rep("2019-01-01", 10),
    rep("2020-01-01", 4)
  ))
)

# Assign wave for grouping
aeoi_dates[, wave := as.integer(format(aeoi_start, "%Y")) - 2016]

cat("AEOI dates for", nrow(aeoi_dates), "countries\n")
cat("Wave 1 (2017):", sum(aeoi_dates$wave == 1), "\n")
cat("Wave 2 (2018):", sum(aeoi_dates$wave == 2), "\n")
cat("Wave 3 (2019):", sum(aeoi_dates$wave == 3), "\n")
cat("Wave 4 (2020):", sum(aeoi_dates$wave == 4), "\n")

fwrite(aeoi_dates, "../data/aeoi_activation_dates.csv")

# ---------------------------------------------------------------
# 2. Parse BIS LBS bulk CSV (already downloaded via curl)
# ---------------------------------------------------------------
cat("\n=== Parsing BIS LBS bulk CSV ===\n")

bis_file <- "../data/WS_LBS_D_PUB_csv_col.csv"
stopifnot("BIS CSV not found — run: curl -L -o data/bis_lbs_bulk.zip 'https://data.bis.org/static/bulk/WS_LBS_D_PUB_csv_col.zip' && unzip data/bis_lbs_bulk.zip -d data/" =
            file.exists(bis_file))

cat("Reading BIS file (511MB, filtering on read)...\n")

# Read just header to find column positions
header <- fread(bis_file, nrows = 0)
all_cols <- names(header)
cat("Total columns:", length(all_cols), "\n")

# Identify period columns (YYYY-QN format)
period_cols <- grep("^\\d{4}-Q\\d$", all_cols, value = TRUE)
cat("Period columns:", length(period_cols), "(", min(period_cols), "to", max(period_cols), ")\n")

# Restrict to 2005 onward for manageable size
keep_periods <- period_cols[as.integer(substr(period_cols, 1, 4)) >= 2005]
cat("Keeping periods from 2005:", length(keep_periods), "\n")

# Columns to keep: metadata + period values
meta_cols <- c("FREQ", "L_MEASURE", "L_POSITION", "L_INSTR", "L_DENOM",
               "L_CURR_TYPE", "L_PARENT_CTY", "L_REP_BANK_TYPE",
               "L_REP_CTY", "L_CP_SECTOR", "L_CP_COUNTRY", "L_POS_TYPE")
keep_cols <- c(meta_cols, keep_periods)

# Read full file but only keep needed columns
# Use grep to pre-filter for CH (Switzerland as reporting country)
cat("Reading and filtering for CH as reporting country...\n")
bis_raw <- fread(
  bis_file,
  select = keep_cols,
  showProgress = FALSE
)
cat("Raw BIS data:", nrow(bis_raw), "rows\n")

# Filter: Switzerland reporting, cross-border liabilities, stocks, all instruments
ch_liab <- bis_raw[
  L_REP_CTY == "CH" &
  L_POSITION == "L" &
  L_MEASURE == "S" &
  L_POS_TYPE == "N" &
  L_INSTR == "A" &
  L_DENOM == "TO1" &
  L_CP_SECTOR == "A" &
  L_REP_BANK_TYPE == "A" &
  L_CURR_TYPE == "A" &
  L_PARENT_CTY == "5J"
]

cat("Swiss cross-border liabilities (filtered):", nrow(ch_liab), "rows\n")
cat("Counterparty countries:", uniqueN(ch_liab$L_CP_COUNTRY), "\n")

# Reshape wide → long
ch_long <- melt(
  ch_liab,
  id.vars = "L_CP_COUNTRY",
  measure.vars = keep_periods,
  variable.name = "period",
  value.name = "deposits_usd_mn"
)
ch_long[, period := as.character(period)]
ch_long[, deposits_usd_mn := as.numeric(deposits_usd_mn)]

# Parse period to year/quarter/date
ch_long[, year := as.integer(substr(period, 1, 4))]
ch_long[, quarter := as.integer(substr(period, 7, 7))]
ch_long[, date := as.Date(paste0(year, "-", (quarter - 1) * 3 + 1, "-01"))]

# Rename counterparty
setnames(ch_long, "L_CP_COUNTRY", "cp_country")

# Drop rows with missing deposits
ch_long <- ch_long[!is.na(deposits_usd_mn)]

cat("Long-format panel:", nrow(ch_long), "country-quarter obs\n")
cat("Countries:", uniqueN(ch_long$cp_country), "\n")
cat("Years:", min(ch_long$year), "-", max(ch_long$year), "\n")

# Validation: check known values
cat("\nSample values (DE, US, GB):\n")
print(ch_long[cp_country == "DE" & year == 2015 & quarter == 1])
print(ch_long[cp_country == "US" & year == 2015 & quarter == 1])
print(ch_long[cp_country == "GB" & year == 2015 & quarter == 1])

# Check aggregate: total foreign deposits ~$750bn range
agg_2015 <- ch_long[year == 2015 & quarter == 1 & !cp_country %in% c("5J", "5A", "5S"),
                     .(total = sum(deposits_usd_mn, na.rm = TRUE))]
cat("Total Swiss foreign liabilities 2015-Q1:", round(agg_2015$total), "USD mn\n")

# Save
fwrite(ch_long, "../data/bis_ch_liabilities.csv")
cat("\nBIS panel saved:", nrow(ch_long), "observations\n")

# ---------------------------------------------------------------
# 3. SNB Aggregate Statistics
# ---------------------------------------------------------------
cat("\n=== Fetching SNB aggregate data ===\n")

snb_banks_url <- "https://data.snb.ch/api/cube/bastrbwka/data/csv/en"
resp_banks <- httr::GET(snb_banks_url, httr::timeout(60))
cat("SNB banks API status:", httr::status_code(resp_banks), "\n")

if (httr::status_code(resp_banks) == 200) {
  writeLines(httr::content(resp_banks, "text", encoding = "UTF-8"),
             "../data/snb_banks_raw.csv")
  cat("SNB bank count data saved.\n")
}

snb_dep_url <- "https://data.snb.ch/api/cube/frekgbgpa/data/csv/en"
resp_dep <- httr::GET(snb_dep_url, httr::timeout(60))
cat("SNB deposits API status:", httr::status_code(resp_dep), "\n")

if (httr::status_code(resp_dep) == 200) {
  writeLines(httr::content(resp_dep, "text", encoding = "UTF-8"),
             "../data/snb_deposits_raw.csv")
  cat("SNB deposit data saved.\n")
}

cat("\n=== All data fetched and saved ===\n")
cat("Files in data/:\n")
cat(paste(list.files("../data/", pattern = "\\.(csv|json)$"), collapse = "\n"), "\n")

# Clean up bulk file to save space (keep only the processed output)
cat("\nRemoving bulk CSV to save disk space...\n")
file.remove("../data/WS_LBS_D_PUB_csv_col.csv")
file.remove("../data/bis_lbs_bulk.zip")
cat("Done.\n")
