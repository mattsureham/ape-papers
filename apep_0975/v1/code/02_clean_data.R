## 02_clean_data.R — Build analysis panel
## apep_0975: European Investigation Order and Crime Deterrence

source("00_packages.R")
setwd(file.path(dirname(getwd())))

# Load raw data
crime <- fread("data/crime_raw.csv")
pop   <- fread("data/population.csv")
eio   <- fread("data/eio_transposition.csv")

cat("Building analysis panel...\n")

# ===========================================================================
# 1. Merge crime + population → crime rate per 100k
# ===========================================================================
panel <- merge(crime, pop, by = c("geo", "year"), all.x = TRUE)
panel[, rate := (values / population) * 100000]

# Drop observations with missing rate
n_before <- nrow(panel)
panel <- panel[!is.na(rate) & !is.na(values) & population > 0]
cat(sprintf("  Dropped %d rows with missing rate (%.1f%%)\n",
            n_before - nrow(panel), 100 * (n_before - nrow(panel)) / n_before))

# ===========================================================================
# 2. Add EIO treatment status
# ===========================================================================

# Denmark and Ireland opted out — they are never-treated
# Set their transposition_year to 0 (never-treated in did package)
eio_full <- data.table(geo = unique(panel$geo))
eio_full <- merge(eio_full, eio[, .(geo = iso2, transposition_year, transposition_date)],
                  by = "geo", all.x = TRUE)

# DK and IE opted out entirely
eio_full[geo %in% c("DK", "IE"), transposition_year := 0L]

# Countries with no transposition data but NOT DK/IE — check manually
missing <- eio_full[is.na(transposition_year) & !geo %in% c("DK", "IE")]
if (nrow(missing) > 0) {
  cat("  Countries missing transposition data:\n")
  print(missing)
  # For countries that participated but have no CELLAR data,
  # we'll need to code manually from EUR-Lex NIM page
  # Known transposition dates from legal databases:
  # Reference: https://eur-lex.europa.eu/legal-content/EN/NIM/?uri=celex:32014L0041
  manual_dates <- data.table(
    geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "EE", "FI", "FR",
            "DE", "EL", "HU", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE"),
    manual_year = c(2018L, 2017L, 2018L, 2017L, 2017L, 2018L, 2017L, 2017L, 2017L,
                    2017L, 2018L, 2018L, 2017L, 2018L, 2017L, 2018L, 2018L, 2017L,
                    2018L, 2018L, 2018L, 2018L, 2017L, 2018L, 2017L)
  )
  eio_full <- merge(eio_full, manual_dates, by = "geo", all.x = TRUE)
  eio_full[is.na(transposition_year) & !is.na(manual_year),
           transposition_year := manual_year]
  eio_full[, manual_year := NULL]
}

# Final: ensure DK and IE are 0 (never-treated)
eio_full[geo %in% c("DK", "IE"), transposition_year := 0L]

# Any remaining NAs? If so, exclude those countries
still_missing <- eio_full[is.na(transposition_year)]
if (nrow(still_missing) > 0) {
  cat("  WARNING: Excluding countries with unknown transposition:\n")
  print(still_missing)
  eio_full <- eio_full[!is.na(transposition_year)]
}

cat("\nTransposition cohorts:\n")
print(eio_full[, .N, by = transposition_year][order(transposition_year)])

# Merge treatment into panel
panel <- merge(panel, eio_full[, .(geo, transposition_year)],
               by = "geo", all.x = FALSE)  # inner join: only countries with treatment info

# Binary treatment indicator
panel[, treated := fifelse(transposition_year > 0 & year >= transposition_year, 1L, 0L)]

# For C-S: first_treat = transposition_year (0 = never treated)
panel[, first_treat := transposition_year]

# ===========================================================================
# 3. Crime category labels
# ===========================================================================
panel[, crime_label := fcase(
  iccs == "ICCS0701", "Fraud",
  iccs == "ICCS0601", "Drug offences",
  iccs == "ICCS0502", "Theft",
  iccs == "ICCS0101", "Homicide",
  iccs == "ICCS020111", "Serious assault",
  iccs == "ICCS02011", "Assault",
  iccs == "ICCS0401", "Robbery",
  default = iccs
)]

# Cross-border indicator (for triple-diff)
panel[, cross_border := fifelse(iccs %in% c("ICCS0701", "ICCS0601", "ICCS0502"), 1L, 0L)]

# Log rate (add 0.01 for zeros)
panel[, log_rate := log(rate + 0.01)]

# ===========================================================================
# 4. Create numeric country ID for did package
# ===========================================================================
panel[, country_id := as.integer(factor(geo))]

# ===========================================================================
# 5. Summary statistics
# ===========================================================================
cat("\n=== Panel Summary ===\n")
cat(sprintf("  Observations: %d\n", nrow(panel)))
cat(sprintf("  Countries: %d\n", length(unique(panel$geo))))
cat(sprintf("  Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Crime categories: %d\n", length(unique(panel$iccs))))
cat(sprintf("  Treated countries: %d\n", sum(eio_full$transposition_year > 0)))
cat(sprintf("  Never-treated: %d (DK, IE)\n", sum(eio_full$transposition_year == 0)))

cat("\nMean crime rates (per 100k) by category:\n")
print(panel[, .(mean_rate = mean(rate, na.rm = TRUE),
                sd_rate = sd(rate, na.rm = TRUE),
                n_obs = .N),
            by = crime_label][order(-mean_rate)])

# Save
fwrite(panel, "data/analysis_panel.csv")
cat("\nAnalysis panel saved: data/analysis_panel.csv\n")
