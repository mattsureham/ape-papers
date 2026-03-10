## ==============================================================
## 02_clean_data.R — Harmonize all five reform panels
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"

## ---------------------------------------------------------------
## REFORM 1: Denmark fat tax
## ---------------------------------------------------------------
cat("=== Cleaning Denmark fat tax panel ===\n")

dk <- fread(file.path(data_dir, "dk_hicp_panel.csv"))
dk[, date := as.Date(date)]
dk[, year := year(date)]
dk[, month := month(date)]
dk[, ym := year + (month - 1) / 12]

# Policy dates
dk_on  <- as.Date("2011-10-01")
dk_off <- as.Date("2013-01-01")

# Event time relative to ON
dk[, event_time_on := as.numeric(difftime(date, dk_on, units = "days")) / 30.44]
dk[, event_time_on := round(event_time_on)]

# Event time relative to OFF
dk[, event_time_off := as.numeric(difftime(date, dk_off, units = "days")) / 30.44]
dk[, event_time_off := round(event_time_off)]

# Period indicators
dk[, period := fifelse(date < dk_on, "pre",
                fifelse(date < dk_off, "policy_on", "post_repeal"))]
dk[, period := factor(period, levels = c("pre", "policy_on", "post_repeal"))]

# Normalize index to pre-policy mean by COICOP
dk[, pre_mean := mean(values[period == "pre"], na.rm = TRUE), by = coicop]
dk[, y_norm := (values / pre_mean - 1) * 100]  # % deviation from pre-policy mean

cat("  Denmark:", nrow(dk), "obs, date range:", as.character(min(dk$date)),
    "to", as.character(max(dk$date)), "\n")

fwrite(dk, file.path(data_dir, "dk_clean.csv"))

## ---------------------------------------------------------------
## REFORM 2: Czech Republic healthcare co-payments
## ---------------------------------------------------------------
cat("=== Cleaning Czech healthcare co-payments panel ===\n")

cz <- fread(file.path(data_dir, "cz_health_panel.csv"))
cz[, date := as.Date(date)]
cz[, year := year(date)]

# Policy dates (annual data)
cz_on_year  <- 2008
cz_off_year <- 2015

cz[, event_time_on := year - cz_on_year]
cz[, event_time_off := year - cz_off_year]

cz[, period := fifelse(year < cz_on_year, "pre",
                 fifelse(year < cz_off_year, "policy_on", "post_repeal"))]
cz[, period := factor(period, levels = c("pre", "policy_on", "post_repeal"))]

# Normalize to pre-policy mean
cz[, pre_mean := mean(values[period == "pre"], na.rm = TRUE), by = icha11_hf]
cz[, y_norm := (values / pre_mean - 1) * 100]

cat("  Czech Republic:", nrow(cz), "obs, year range:", min(cz$year),
    "to", max(cz$year), "\n")

fwrite(cz, file.path(data_dir, "cz_clean.csv"))

## ---------------------------------------------------------------
## REFORM 3: Italy RdC
## ---------------------------------------------------------------
cat("=== Cleaning Italy RdC panel ===\n")

it <- fread(file.path(data_dir, "it_poverty_panel.csv"))
it[, date := as.Date(date)]
it[, year := year(date)]

# Policy dates (annual data)
it_on_year  <- 2019
it_off_year <- 2024

it[, event_time_on := year - it_on_year]
it[, event_time_off := year - it_off_year]

it[, period := fifelse(year < it_on_year, "pre",
                fifelse(year < it_off_year, "policy_on", "post_repeal"))]
it[, period := factor(period, levels = c("pre", "policy_on", "post_repeal"))]

# Normalize to pre-policy mean
it[, pre_mean := mean(values[period == "pre"], na.rm = TRUE), by = geo]
it[, y_norm := (values / pre_mean - 1) * 100]

cat("  Italy:", nrow(it), "obs,", uniqueN(it$geo), "regions,",
    "year range:", min(it$year), "to", max(it$year), "\n")

fwrite(it, file.path(data_dir, "it_clean.csv"))

## ---------------------------------------------------------------
## REFORM 4: Poland retirement age
## ---------------------------------------------------------------
cat("=== Cleaning Poland retirement age panel ===\n")

pl <- fread(file.path(data_dir, "pl_employment_panel.csv"))
pl[, date := as.Date(date)]

# Filter to TOTAL citizen only (raw data includes multiple citizenship breakdowns)
if ("citizen" %in% names(pl)) {
  cat("  Citizen categories in raw data:", paste(unique(pl$citizen), collapse = ", "), "\n")
  pl <- pl[citizen == "TOTAL"]
  cat("  Filtered to citizen=TOTAL:", nrow(pl), "rows\n")
}

# Policy dates
pl_on  <- as.Date("2013-01-01")
pl_off <- as.Date("2017-10-01")

pl[, event_time_on := as.numeric(difftime(date, pl_on, units = "days")) / 91.31]
pl[, event_time_on := round(event_time_on)]
pl[, event_time_off := as.numeric(difftime(date, pl_off, units = "days")) / 91.31]
pl[, event_time_off := round(event_time_off)]

pl[, period := fifelse(date < pl_on, "pre",
                fifelse(date < pl_off, "policy_on", "post_repeal"))]
pl[, period := factor(period, levels = c("pre", "policy_on", "post_repeal"))]

# Create sex-age group ID
pl[, group := paste(sex, age, sep = "_")]

# Normalize to pre-policy mean
pl[, pre_mean := mean(values[period == "pre"], na.rm = TRUE), by = group]
pl[, y_norm := (values / pre_mean - 1) * 100]

cat("  Poland:", nrow(pl), "obs,", uniqueN(pl$group), "sex-age groups,",
    "date range:", as.character(min(pl$date)), "to", as.character(max(pl$date)), "\n")

fwrite(pl, file.path(data_dir, "pl_clean.csv"))

## ---------------------------------------------------------------
## REFORM 5: France supertax
## ---------------------------------------------------------------
cat("=== Cleaning France supertax panel ===\n")

fr <- fread(file.path(data_dir, "fr_lci_panel.csv"))
fr[, date := as.Date(date)]

# Policy dates
fr_on  <- as.Date("2013-01-01")
fr_off <- as.Date("2015-01-01")

fr[, event_time_on := as.numeric(difftime(date, fr_on, units = "days")) / 91.31]
fr[, event_time_on := round(event_time_on)]
fr[, event_time_off := as.numeric(difftime(date, fr_off, units = "days")) / 91.31]
fr[, event_time_off := round(event_time_off)]

fr[, period := fifelse(date < fr_on, "pre",
                fifelse(date < fr_off, "policy_on", "post_repeal"))]
fr[, period := factor(period, levels = c("pre", "policy_on", "post_repeal"))]

# Normalize to pre-policy mean
fr[, pre_mean := mean(values[period == "pre"], na.rm = TRUE), by = .(geo, nace_r2, lcstruct)]
fr[, y_norm := (values / pre_mean - 1) * 100]

cat("  France:", nrow(fr), "obs,", uniqueN(fr$geo), "countries,",
    "date range:", as.character(min(fr$date)), "to", as.character(max(fr$date)), "\n")

fwrite(fr, file.path(data_dir, "fr_clean.csv"))

cat("\nAll panels cleaned and saved.\n")
