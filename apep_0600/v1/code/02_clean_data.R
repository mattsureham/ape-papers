# ==============================================================================
# 02_clean_data.R — Construct analysis panels
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. Load raw data
# ==============================================================================
transposition <- fread(file.path(data_dir, "mcd_transposition.csv"))
transposition[, transposition_date := as.Date(transposition_date)]

rates <- fread(file.path(data_dir, "ecb_mortgage_rates.csv"))
consumer <- fread(file.path(data_dir, "ecb_consumer_rates.csv"))
hpi <- fread(file.path(data_dir, "eurostat_hpi.csv"))

cat("Loaded data:\n")
cat("  Transposition:", nrow(transposition), "countries\n")
cat("  Rates:", nrow(rates), "\n")
cat("  Consumer:", nrow(consumer), "\n")
cat("  HPI:", nrow(hpi), "\n")

# ==============================================================================
# 2. Process ECB MIR data (monthly panel)
# ==============================================================================

# Parse dates — date column is "YYYY-MM" format
rates[, date_str := date]
rates[, date := as.Date(paste0(date_str, "-01"))]
rates[, date_str := NULL]
rates[, year := year(date)]
rates[, month := month(date)]
rates[, ym := as.integer(format(date, "%Y%m"))]

consumer[, date_str := date]
consumer[, date := as.Date(paste0(date_str, "-01"))]
consumer[, date_str := NULL]

# Eurostat uses EL for Greece, ECB uses GR
rates[country == "GR", country := "EL"]
consumer[country == "GR", country := "EL"]

# Merge rates and consumer credit
mir_panel <- merge(rates, consumer, by = c("country", "date"), all = TRUE)

# Add transposition dates
mir_panel <- merge(mir_panel, transposition, by.x = "country", by.y = "iso2", all.x = TRUE)

# Create treatment indicator
mir_panel[, treated := as.integer(!is.na(transposition_date) & date >= transposition_date)]

# Create treatment cohort (month of transposition)
mir_panel[, cohort_date := transposition_date]

# Relative time (months since transposition)
mir_panel[!is.na(transposition_date),
          rel_month := as.integer(difftime(date, transposition_date, units = "days")) %/% 30]

# Numeric time index (months since Jan 2005)
mir_panel[, time_idx := (year(date) - 2005) * 12 + month(date)]

# Country numeric ID
mir_panel[, country_id := as.integer(factor(country))]

# Cohort as numeric (months since Jan 2005)
mir_panel[!is.na(cohort_date),
          cohort_num := (year(cohort_date) - 2005) * 12 + month(cohort_date)]
mir_panel[is.na(cohort_date), cohort_num := 0L]  # Never-treated

# Restrict to analysis window: Jan 2010 - Dec 2021
# (enough pre-treatment; avoid COVID recovery distortion)
mir_panel <- mir_panel[date >= "2010-01-01" & date <= "2021-12-31"]

cat("\nMIR panel: ", nrow(mir_panel), "observations,",
    uniqueN(mir_panel$country), "countries\n")
cat("Treatment status:\n")
print(mir_panel[, .N, by = treated])

# ==============================================================================
# 3. Process Eurostat HPI data (quarterly panel)
# ==============================================================================

# Parse date column
hpi[, date := as.Date(date)]
hpi[, year := year(date)]
hpi[, quarter := quarter(date)]
hpi[, yq := paste0(year, "Q", quarter)]

# Add transposition dates
hpi_panel <- merge(hpi, transposition, by.x = "country", by.y = "iso2", all.x = TRUE)

# Treatment indicator (quarterly — treated if transposition occurred before quarter start)
hpi_panel[, treated := as.integer(!is.na(transposition_date) & date >= transposition_date)]

# Cohort (quarter of transposition)
hpi_panel[!is.na(transposition_date), cohort_quarter := as.Date(
  paste0(year(transposition_date), "-",
         (quarter(transposition_date) - 1) * 3 + 1, "-01"))]
hpi_panel[is.na(transposition_date), cohort_quarter := NA]

# Relative time (quarters since transposition)
hpi_panel[!is.na(transposition_date),
          rel_quarter := as.integer(difftime(date, transposition_date, units = "days")) %/% 91]

# Numeric time index (quarters since 2005Q1)
hpi_panel[, time_idx := (year - 2005) * 4 + quarter]

# Country numeric ID
hpi_panel[, country_id := as.integer(factor(country))]

# Cohort as numeric
hpi_panel[!is.na(cohort_quarter),
          cohort_num := (year(cohort_quarter) - 2005) * 4 + quarter(cohort_quarter)]
hpi_panel[is.na(cohort_quarter), cohort_num := 0L]

# Log HPI
hpi_panel[hpi > 0, log_hpi := log(hpi)]

# Restrict to analysis window
hpi_panel <- hpi_panel[date >= "2005-01-01" & date <= "2021-12-31"]

cat("\nHPI panel:", nrow(hpi_panel), "observations,",
    uniqueN(hpi_panel$country), "countries\n")

# ==============================================================================
# 4. Summary statistics
# ==============================================================================

# Transposition cohort summary
trans_summary <- transposition[!is.na(transposition_date)][order(transposition_date)]
trans_summary[, year_trans := year(transposition_date)]
cat("\nTransposition cohorts:\n")
print(trans_summary[, .N, by = year_trans])

# Pre/post means for mortgage rates
cat("\nMortgage rate means by treatment status:\n")
print(mir_panel[!is.na(rate), .(mean_rate = mean(rate, na.rm = TRUE),
                                  sd_rate = sd(rate, na.rm = TRUE),
                                  n = .N), by = treated])

# Save analysis panels
fwrite(mir_panel, file.path(data_dir, "mir_panel.csv"))
fwrite(hpi_panel, file.path(data_dir, "hpi_panel.csv"))

cat("\nAnalysis panels saved.\n")
