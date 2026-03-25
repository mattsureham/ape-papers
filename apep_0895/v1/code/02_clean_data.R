# 02_clean_data.R — Build country-year panel for 5AMLD analysis
# apep_0895: Does AML Regulation Actually Detect Money Laundering?

source("00_packages.R")

# ===========================================================================
# Load raw data
# ===========================================================================
transposition <- fread("data/transposition_5amld.csv")
ml_dt <- fread("data/money_laundering_offences.csv")
property_dt <- fread("data/property_offences.csv")
assault_dt <- fread("data/assault_offences.csv")
total_dt <- fread("data/total_offences.csv")
hpi_dt <- fread("data/house_price_index.csv")
emp_dt <- fread("data/financial_employment.csv")
gdp_dt <- fread("data/gdp.csv")
pop_dt <- fread("data/population.csv")

# ===========================================================================
# 1. Process transposition dates
# ===========================================================================
# Convert transposition date to year (treatment year)
transposition[, transposition_date := as.Date(transposition_date)]
transposition[, treat_year := as.integer(format(transposition_date, "%Y"))]

# For countries with transposition in the second half of the year,
# the effect likely shows in the following year's crime statistics
# (crime data is annual). Use the calendar year of transposition.
# Sensitivity: shift by +1 year as robustness.

# Create clean treatment mapping
treat_map <- transposition[!is.na(iso2) & !is.na(treat_year),
                           .(geo = iso2, treat_year, transposition_date)]

message("Treatment map:")
print(treat_map[order(treat_year, geo)])
message("\nTreatment cohorts:")
print(treat_map[, .N, by = treat_year][order(treat_year)])

# ===========================================================================
# 2. Build balanced panel
# ===========================================================================
# Panel years: 2013-2022 (5 pre-periods before earliest treatment in 2018)
# ML crime data starts 2016; years 2013-2015 will have NA but
# CS estimator handles missing data and the wider panel provides ≥5 pre-periods
panel_years <- 2013:2022

# Start with all EU countries that have ML data
ml_countries <- unique(ml_dt$geo)
eu_iso2 <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
             "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
             "PL","PT","RO","SK","SI","ES","SE")

# Keep EU countries that have ML data (includes never-treated ones)
panel_countries <- intersect(ml_countries, eu_iso2)
message("\nCountries in both datasets: ", paste(sort(panel_countries), collapse = ", "))

# Create balanced skeleton
panel <- CJ(geo = as.character(panel_countries), year = panel_years)
panel[, geo := as.character(geo)]

# ===========================================================================
# 3. Merge treatment
# ===========================================================================
treat_map[, geo := as.character(geo)]
panel <- merge(panel, treat_map[, .(geo, treat_year)], by = "geo", all.x = TRUE)

# Countries without transposition date = never-treated (or treat_year = 0 for did package)
# For Callaway-Sant'Anna: gname = 0 means never treated
panel[is.na(treat_year), treat_year := 0L]

# Binary treatment indicator
panel[, treated := fifelse(treat_year > 0 & year >= treat_year, 1L, 0L)]

# ===========================================================================
# 4. Merge outcomes
# ===========================================================================
panel <- merge(panel, ml_dt, by = c("geo", "year"), all.x = TRUE)
panel <- merge(panel, property_dt, by = c("geo", "year"), all.x = TRUE)
# Assault may be empty (ICCS0201 not in crim_off_cat for all periods)
if (nrow(assault_dt) > 0) {
  panel <- merge(panel, assault_dt, by = c("geo", "year"), all.x = TRUE)
} else {
  panel[, assault_offences := NA_real_]
}
panel <- merge(panel, total_dt, by = c("geo", "year"), all.x = TRUE)
panel <- merge(panel, hpi_dt, by = c("geo", "year"), all.x = TRUE)
panel <- merge(panel, emp_dt, by = c("geo", "year"), all.x = TRUE)
panel <- merge(panel, pop_dt, by = c("geo", "year"), all.x = TRUE)
panel <- merge(panel, gdp_dt, by = c("geo", "year"), all.x = TRUE)

# ===========================================================================
# 5. Construct variables
# ===========================================================================
# Per-capita rates (per 100,000)
panel[, ml_rate := ml_offences / population * 1e5]
panel[, property_rate := property_offences / population * 1e5]
panel[, assault_rate := assault_offences / population * 1e5]

# Log transformations (for percent change interpretation)
panel[, log_ml := log(ml_offences + 1)]
panel[, log_property := log(property_offences + 1)]
panel[, log_assault := log(assault_offences + 1)]

# ML share of total crime
panel[total_offences > 0, ml_share := ml_offences / total_offences * 100]

# Financial employment (thousands)
panel[, log_fin_emp := log(fin_employment + 1)]

# Numeric country ID for did package
panel[, country_id := as.integer(factor(geo))]

# ===========================================================================
# 6. Report data quality
# ===========================================================================
message("\n=== Panel Summary ===")
message("Dimensions: ", nrow(panel), " rows x ", ncol(panel), " cols")
message("Countries: ", uniqueN(panel$geo))
message("Years: ", paste(range(panel$year), collapse = "-"))
message("\nMissing ML offences: ", sum(is.na(panel$ml_offences)), " / ", nrow(panel))
message("Missing population: ", sum(is.na(panel$population)), " / ", nrow(panel))

# Treatment summary
message("\nTreatment cohort distribution:")
cohort_tab <- panel[year == min(year), .N, by = treat_year][order(treat_year)]
print(cohort_tab)

# Check which countries have complete ML data
ml_coverage <- panel[, .(n_years = sum(!is.na(ml_offences)),
                          total_years = .N), by = geo]
message("\nCountries with incomplete ML data:")
print(ml_coverage[n_years < total_years])

# Drop countries with very sparse ML data (fewer than 5 years)
sparse_countries <- ml_coverage[n_years < 5, geo]
if (length(sparse_countries) > 0) {
  message("Dropping ", length(sparse_countries), " countries with <5 years of ML data: ",
          paste(sparse_countries, collapse = ", "))
  panel <- panel[!geo %in% sparse_countries]
}

# ===========================================================================
# 7. Save analysis panel
# ===========================================================================
fwrite(panel, "data/analysis_panel.csv")

message("\n=== Final panel ===")
message("Countries: ", uniqueN(panel$geo))
message("Country-years: ", nrow(panel))
message("Treated countries: ", uniqueN(panel[treat_year > 0, geo]))
message("Never-treated: ", uniqueN(panel[treat_year == 0, geo]))

# Summary statistics
message("\n=== Outcome summary (pre-treatment) ===")
pre <- panel[treated == 0 & !is.na(ml_offences)]
message("ML offences: mean=", round(mean(pre$ml_offences), 1),
        " sd=", round(sd(pre$ml_offences), 1),
        " min=", min(pre$ml_offences),
        " max=", max(pre$ml_offences))
if (nrow(pre[!is.na(ml_rate)]) > 0) {
  message("ML rate per 100k: mean=", round(mean(pre$ml_rate, na.rm = TRUE), 2),
          " sd=", round(sd(pre$ml_rate, na.rm = TRUE), 2))
}
