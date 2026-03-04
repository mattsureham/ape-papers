## ============================================================
## 02_clean_data.R — Data cleaning and panel construction
## APEP Paper: Does Naming Work?
## ============================================================

source("00_packages.R")
library(data.table)

data_dir <- "../data/"

## ============================================================
## 1. Load raw data
## ============================================================
cat("Loading raw data...\n")

ch <- fread(file.path(data_dir, "ch_food_nonfood.csv"))
postcode_lookup <- fread(file.path(data_dir, "postcode_la_lookup.csv"))
fhrs <- fread(file.path(data_dir, "fhrs_establishments.csv"))
pop <- fread(file.path(data_dir, "nomis_population.csv"))

## ============================================================
## 2. Merge Companies House with geographic data
## ============================================================
cat("Merging Companies House with postcode lookup...\n")

ch <- merge(ch, postcode_lookup[, .(postcode, la_code, la_name, country, region)],
            by = "postcode", all.x = TRUE)

# Keep only England, Wales, Northern Ireland
ch <- ch[country %in% c("England", "Wales", "Northern Ireland")]
cat("Companies after country filter:", format(nrow(ch), big.mark = ","), "\n")

# Parse incorporation date
ch[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
# If that fails, try ISO format
if (all(is.na(ch$inc_date[1:100]))) {
  ch[, inc_date := as.Date(IncorporationDate)]
}

## ============================================================
## 3. Define treatment variables
## ============================================================

ch[, treated := fifelse(country %in% c("Wales", "Northern Ireland"), 1L, 0L)]
ch[, cohort := fifelse(country == "Wales", 2013L,
                fifelse(country == "Northern Ireland", 2016L, 0L))]

## ============================================================
## 4. Exit proxy: Companies that are no longer fully active
## ============================================================
cat("Constructing exit proxy from CompanyStatus...\n")

# CompanyStatus categories
ch[, exit_status := fifelse(
  CompanyStatus %in% c("Active"), 0L, 1L  # Anything not "Active" is exit-adjacent
)]

cat("Exit status distribution:\n")
print(ch[, .N, by = .(CompanyStatus, exit_status)][order(-N)])

# For exit TIMING, we don't have dissolution dates.
# But we can construct:
# (a) Entries: directly from IncorporationDate (excellent data)
# (b) Survival: fraction of cohort still Active (cross-sectional)
# (c) Stock changes: count of active food businesses per LA over time
#     (approximated by cumulative entries minus cumulative exits-in-progress)

## ============================================================
## 5. Construct quarterly ENTRY panel
## ============================================================
cat("Constructing quarterly entry panel...\n")

# Quarter-year grid: 2008Q1 to 2025Q4
quarters <- data.table(
  yq = seq(as.Date("2008-01-01"), as.Date("2025-10-01"), by = "quarter")
)
quarters[, year := year(yq)]
quarters[, quarter := quarter(yq)]
quarters[, period := as.integer(difftime(yq, as.Date("2013-10-01"),
                                          units = "days") / 91.25)]

# Entry: count of new incorporations per LA × quarter × food/nonfood
ch[, inc_yq := floor_date(inc_date, "quarter")]
entries <- ch[!is.na(inc_yq) & inc_yq >= as.Date("2008-01-01") &
              inc_yq <= as.Date("2025-10-01"),
  .(n_entry = .N),
  by = .(la_code, inc_yq, is_food)
]
setnames(entries, "inc_yq", "yq")

# For exits, use a stock-based approach:
# Count active food companies in each LA as of each quarter
# A company is "active" in quarter q if inc_date <= q AND (still Active OR exit_status date > q)
# Since we don't have exit dates, we approximate:
# n_exit_proxy = count of companies incorporated in quarter q that are now in exit status
# This is a "cohort exit rate" — measures whether the mandate affected survival of new entrants

exit_proxy <- ch[!is.na(inc_yq) & inc_yq >= as.Date("2008-01-01") &
                  inc_yq <= as.Date("2025-10-01"),
  .(n_exit_proxy = sum(exit_status)),
  by = .(la_code, inc_yq, is_food)
]
setnames(exit_proxy, "inc_yq", "yq")

# Create balanced panel: all LA × quarter × food/nonfood combinations
la_info <- unique(ch[!is.na(la_code), .(la_code, la_name, country, region,
                                         treated, cohort)])
la_info <- la_info[!duplicated(la_code)]

panel_grid <- CJ(la_code = la_info$la_code,
                 yq = quarters$yq,
                 is_food = c(TRUE, FALSE))

panel <- merge(panel_grid, la_info, by = "la_code", all.x = TRUE)
panel <- merge(panel, entries, by = c("la_code", "yq", "is_food"), all.x = TRUE)
panel <- merge(panel, exit_proxy, by = c("la_code", "yq", "is_food"), all.x = TRUE)

# Fill NAs with 0
panel[is.na(n_entry), n_entry := 0L]
panel[is.na(n_exit_proxy), n_exit_proxy := 0L]

# Net formation: entries minus exit-destined entries
panel[, n_survivors := n_entry - n_exit_proxy]

# Cohort exit rate: fraction of quarter's entrants that eventually exited
panel[n_entry > 0, cohort_exit_rate := n_exit_proxy / n_entry]

# Time variables
panel[, year := year(yq)]
panel[, quarter := quarter(yq)]
panel[, yq_label := paste0(year, "Q", quarter)]

# Post-treatment indicator
panel[, post := fifelse(
  country == "Wales" & yq >= as.Date("2013-10-01"), 1L,
  fifelse(
    country == "Northern Ireland" & yq >= as.Date("2016-10-01"), 1L,
    0L
  )
)]

# DiD interaction
panel[, did := treated * post]

# Food × DiD (triple diff)
panel[, food := as.integer(is_food)]
panel[, ddd := did * food]

# Relative time (quarters since treatment)
panel[, rel_time := fifelse(
  country == "Wales",
  as.integer(difftime(yq, as.Date("2013-10-01"), units = "days")) %/% 91L,
  fifelse(
    country == "Northern Ireland",
    as.integer(difftime(yq, as.Date("2016-10-01"), units = "days")) %/% 91L,
    NA_integer_
  )
)]

## ============================================================
## 6. Merge population for rate normalization
## ============================================================
cat("Merging population data...\n")

panel <- merge(panel, pop[, .(la_code, year, population)],
               by = c("la_code", "year"), all.x = TRUE)

panel[, population := nafill(population, type = "locf"), by = la_code]
panel[, population := nafill(population, type = "nocb"), by = la_code]

# Rates per 10,000 population
panel[population > 0, entry_rate := n_entry / population * 10000]

## ============================================================
## 7. Cohort survival analysis (cross-sectional)
## ============================================================
cat("Building cohort survival table...\n")

# For each incorporation year × country × food, compute survival rates
survival <- ch[!is.na(inc_date) & year(inc_date) >= 2005 & year(inc_date) <= 2022,
  .(n_total = .N,
    n_active = sum(CompanyStatus == "Active"),
    n_exit = sum(exit_status == 1)),
  by = .(country, is_food, inc_year = year(inc_date))
]
survival[, survival_rate := n_active / n_total]
survival[, exit_rate := n_exit / n_total]

fwrite(survival, file.path(data_dir, "cohort_survival.csv"))

## ============================================================
## 8. FHRS quality panel (cross-sectional snapshot)
## ============================================================
cat("Processing FHRS quality data...\n")

fhrs[, rating_numeric := suppressWarnings(as.integer(rating_value))]
fhrs[, is_low_rated := rating_numeric %in% c(0, 1, 2)]
fhrs[, is_high_rated := rating_numeric %in% c(4, 5)]

# LA-level quality summary
fhrs_quality <- fhrs[!is.na(rating_numeric),
  .(mean_rating = mean(rating_numeric, na.rm = TRUE),
    pct_low = mean(is_low_rated, na.rm = TRUE) * 100,
    pct_high = mean(is_high_rated, na.rm = TRUE) * 100,
    n_establishments = .N),
  by = .(country, la_name)
]

fwrite(fhrs_quality, file.path(data_dir, "fhrs_quality_by_la.csv"))

## ============================================================
## 9. Save analysis panel
## ============================================================
cat("Saving analysis panel...\n")

panel[, la_id := as.integer(factor(la_code))]
panel[, time_id := as.integer(factor(yq))]

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

cat("\n=== PANEL SUMMARY ===\n")
cat("Total observations:", format(nrow(panel), big.mark = ","), "\n")
cat("LAs:", uniqueN(panel$la_code), "\n")
cat("Quarters:", uniqueN(panel$yq), "\n")
cat("Countries:", paste(unique(panel$country), collapse = ", "), "\n")
cat("Country × food counts:\n")
print(panel[, .(N = .N, mean_entry = round(mean(n_entry), 2),
                mean_exit_proxy = round(mean(n_exit_proxy), 2)),
            by = .(country, is_food)])

cat("\nTreatment summary (food businesses):\n")
print(panel[is_food == TRUE, .(
  n_la = uniqueN(la_code),
  mean_entry = round(mean(n_entry), 2),
  mean_exit_proxy = round(mean(n_exit_proxy), 2)
), by = .(country)])

cat("\nCohort survival summary (food businesses):\n")
print(survival[is_food == TRUE, .(
  n_total = sum(n_total),
  survival_pct = round(sum(n_active) / sum(n_total) * 100, 1)
), by = country])
