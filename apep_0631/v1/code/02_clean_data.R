## 02_clean_data.R — Construct treatment variable and analysis panel
## APEP paper apep_0631

source("00_packages.R")

data_dir <- "../data"

## ── 1. Load and reshape Zillow ZHVI ──
cat("Loading Zillow ZHVI...\n")
zhvi_raw <- fread(file.path(data_dir, "zhvi_zip.csv"))
cat("ZHVI raw dimensions:", nrow(zhvi_raw), "zips x", ncol(zhvi_raw), "columns\n")

# Identify date columns (format: YYYY-MM-DD)
date_cols <- names(zhvi_raw)[grepl("^\\d{4}-\\d{2}-\\d{2}$", names(zhvi_raw))]
id_cols <- c("RegionID", "SizeRank", "RegionName", "RegionType", "StateName",
             "State", "City", "Metro", "CountyName")
id_cols <- intersect(id_cols, names(zhvi_raw))

# Reshape to long format
zhvi_long <- melt(zhvi_raw,
                  id.vars = id_cols,
                  measure.vars = date_cols,
                  variable.name = "date_str",
                  value.name = "zhvi")

zhvi_long[, `:=`(
  zip = sprintf("%05d", as.integer(RegionName)),
  date = as.Date(as.character(date_str)),
  state = State
)]

# Drop missing ZHVI values
zhvi_long <- zhvi_long[!is.na(zhvi) & zhvi > 0]
zhvi_long[, `:=`(
  year = year(date),
  month = month(date),
  ym = as.integer(format(date, "%Y%m")),
  log_zhvi = log(zhvi)
)]

cat("ZHVI long panel:", nrow(zhvi_long), "obs,",
    uniqueN(zhvi_long$zip), "zips,",
    length(date_cols), "months\n")

## ── 2. Load IRS SOI 2017 and construct SALT treatment variable ──
cat("\nLoading IRS SOI 2017...\n")
irs <- fread(file.path(data_dir, "irs_soi_2017.csv"))
cat("IRS SOI columns:", paste(head(names(irs), 20), collapse = ", "), "...\n")

# Column names are mixed case; standardize
setnames(irs, tolower(names(irs)))

# Data structure: one row per (zipcode × agi_stub). No total row (stub=0).
# Must aggregate across agi_stub values to get zip-code totals.
# Key fields:
#   a18300 / n18300 = Total taxes paid (SALT deduction), amount in $K / count of returns
#   n1 = total returns

cat("agi_stub values:", sort(unique(irs$agi_stub)), "\n")
cat("zipcode sample:", head(unique(irs$zipcode[irs$zipcode > 0])), "\n")

# Aggregate across AGI classes to get zip-code totals
# Remove state-total rows (zipcode = 0)
irs_zips <- irs[zipcode > 0]

irs_zip <- irs_zips[, .(
  n_returns = sum(n1, na.rm = TRUE),
  salt_amount_k = sum(a18300, na.rm = TRUE),  # in thousands of dollars
  salt_n_returns = sum(n18300, na.rm = TRUE),
  statefips = first(statefips)
), by = zipcode]

# Format zip code as 5-digit string
irs_zip[, zip := sprintf("%05d", as.integer(zipcode))]

# IRS reports amounts in thousands — convert to dollars
irs_zip[, salt_amount_dollars := salt_amount_k * 1000]

# Average SALT per itemizing return (those claiming SALT)
irs_zip[, avg_salt := fifelse(salt_n_returns > 0, salt_amount_dollars / salt_n_returns, 0)]

# Treatment intensity: "SALT bite" = dollars above $10K cap, in $10K units
irs_zip[, salt_bite := pmax(0, avg_salt - 10000) / 10000]

# Remove non-geographic zips
irs_zip <- irs_zip[zip != "00000" & zip != "99999" & nchar(zip) == 5]

cat("IRS zip-level SALT:\n")
cat("  Total zips:", nrow(irs_zip), "\n")
cat("  Zips with avg SALT > $10K:", sum(irs_zip$avg_salt > 10000), "\n")
cat("  Avg SALT (all zips):", round(mean(irs_zip$avg_salt, na.rm = TRUE)), "\n")
cat("  Avg SALT (bite > 0):", round(mean(irs_zip$avg_salt[irs_zip$salt_bite > 0], na.rm = TRUE)), "\n")
cat("  SALT bite range:", round(range(irs_zip$salt_bite), 2), "\n")

## ── 3. Merge ZHVI panel with IRS treatment ──
cat("\nMerging ZHVI with IRS treatment variable...\n")
panel <- merge(zhvi_long, irs_zip[, .(zip, n_returns, avg_salt, salt_bite, salt_n_returns, statefips)],
               by = "zip", all.x = FALSE)

cat("Merged panel:", nrow(panel), "obs,", uniqueN(panel$zip), "zips\n")

# Restrict to analysis window: Jan 2012 - Jan 2026
panel <- panel[year >= 2012 & year <= 2026]
cat("After restricting to 2012-2026:", nrow(panel), "obs\n")

# Create treatment timing indicators
panel[, `:=`(
  post_tcja = as.integer(date >= as.Date("2018-01-01")),
  post_obbb = as.integer(date >= as.Date("2025-07-01")),
  # For event study: years relative to TCJA (2018 = 0)
  year_rel_tcja = year - 2018
)]

# Create SALT exposure groups for summary statistics
# Many zips have bite=0, so use meaningful economic thresholds
panel[, salt_group := fcase(
  salt_bite == 0, "Under cap",
  salt_bite <= 0.5, "$0-5K above",
  salt_bite <= 1.0, "$5-10K above",
  salt_bite > 1.0, "$10K+ above"
)]
panel[, salt_group := factor(salt_group,
                              levels = c("Under cap", "$0-5K above", "$5-10K above", "$10K+ above"))]

# State identifier for clustering — use IRS FIPS
panel[, state_fips := sprintf("%02d", as.integer(statefips))]

# Create numeric identifiers for fixest
panel[, `:=`(
  zip_id = as.integer(factor(zip)),
  metro_id = as.integer(factor(Metro)),
  state_id = as.integer(factor(state_fips)),
  time_id = as.integer(factor(date))
)]

# Create metro × month FE identifier
panel[, metro_time := paste0(metro_id, "_", time_id)]
panel[, metro_time_id := as.integer(factor(metro_time))]

cat("\n=== Panel summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Zip codes:", uniqueN(panel$zip), "\n")
cat("Months:", uniqueN(panel$date), "\n")
cat("Date range:", as.character(min(panel$date)), "to", as.character(max(panel$date)), "\n")
cat("States:", uniqueN(panel$state), "\n")
cat("Metros:", uniqueN(panel$Metro[!is.na(panel$Metro)]), "\n")

## ── 4. Save analysis panel ──
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
saveRDS(irs_zip, file.path(data_dir, "irs_zip_salt.rds"))
cat("Saved analysis_panel.csv and irs_zip_salt.rds\n")
