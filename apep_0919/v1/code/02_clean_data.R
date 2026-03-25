# ===========================================================================
# 02_clean_data.R — Data cleaning and panel construction for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

source("00_packages.R")

data_dir <- "../data/"

# --- Load all datasets ---
transposition <- fread(paste0(data_dir, "transposition_dates.csv"))
crime <- fread(paste0(data_dir, "crime_data.csv"))
cpi <- fread(paste0(data_dir, "cpi_data.csv"))
court_exp <- fread(paste0(data_dir, "court_expenditure.csv"))
gdp <- fread(paste0(data_dir, "gdp_data.csv"))
pop <- fread(paste0(data_dir, "population_data.csv"))

# --- EU-27 reference ---
eu27 <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)

# ===========================================================================
# 1. Process transposition treatment
# ===========================================================================

cat("Processing transposition treatment variable...\n")

# For countries missing from CELLAR, use known transposition dates from
# EUR-Lex compliance tracker and legal databases
# https://eur-lex.europa.eu/legal-content/EN/NIM/?uri=celex:32019L1937

# Known transposition dates from legal databases (as fallback)
known_dates <- data.table(
  iso2 = c("DK", "SE", "CY", "LV", "LT", "HR", "FR", "IE", "IT",
           "PT", "EL", "AT", "BG", "CZ", "FI", "DE", "HU", "LU",
           "NL", "SK", "SI", "ES", "EE", "PL", "BE", "MT", "RO"),
  known_year = c(2021L, 2021L, 2022L, 2022L, 2022L, 2022L, 2022L, 2022L, 2023L,
                 2022L, 2022L, 2023L, 2023L, 2023L, 2023L, 2023L, 2023L, 2023L,
                 2023L, 2023L, 2023L, 2023L, 2024L, 2024L, 2024L, 2024L, 2024L)
)

# Merge CELLAR data with known dates
treatment <- merge(eu27, transposition[, .(iso2, transposition_year, transposition_date, n_measures)],
                   by = "iso2", all.x = TRUE)
treatment <- merge(treatment, known_dates, by = "iso2", all.x = TRUE)

# Use CELLAR year only if it's after the directive's transposition deadline (Dec 2021)
# Earlier CELLAR dates are from pre-existing national measures, not the WPD
# Slovakia's 2020 date is pre-existing legislation (Act No. 54/2019 on whistleblower
# protection predates the EU directive); use known_year (2023) instead
treatment[, treat_year := fifelse(
  !is.na(transposition_year) & transposition_year >= 2021, transposition_year, known_year
)]

cat("Treatment timing:\n")
print(treatment[order(treat_year), .(iso2, name, treat_year, transposition_year, known_year)])

# Check cohort counts
cat("\nCohort sizes:\n")
print(treatment[, .N, by = treat_year][order(treat_year)])

# ===========================================================================
# 2. Build country-year panel
# ===========================================================================

cat("\nBuilding country-year panel...\n")

panel <- CJ(iso2 = eu27$iso2, year = 2015:2023)

# Add treatment
panel <- merge(panel, treatment[, .(iso2, name, treat_year)], by = "iso2", all.x = TRUE)
panel[, treated := fifelse(!is.na(treat_year) & year >= treat_year, 1L, 0L)]

# Group variable for Callaway-Sant'Anna (0 = never-treated)
panel[, g := fifelse(!is.na(treat_year), treat_year, 0L)]

# Relative time
panel[, rel_time := fifelse(g > 0, year - treat_year, NA_integer_)]

# ===========================================================================
# 3. Add crime outcomes (per capita)
# ===========================================================================

cat("Merging crime outcomes...\n")

# Corruption per capita
corruption <- crime[iccs == "ICCS0703", .(corruption_count = sum(values, na.rm = TRUE)),
                    by = .(geo, year)]
panel <- merge(panel, corruption, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

# Fraud per capita
fraud <- crime[iccs == "ICCS0701", .(fraud_count = sum(values, na.rm = TRUE)),
               by = .(geo, year)]
panel <- merge(panel, fraud, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

# ===========================================================================
# 4. Add CPI
# ===========================================================================

cat("Merging CPI...\n")

cpi_clean <- cpi[, .(cpi_score = values[1]), by = .(geo, year)]
panel <- merge(panel, cpi_clean, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

# ===========================================================================
# 5. Add court expenditure
# ===========================================================================

cat("Merging court expenditure...\n")

court_clean <- court_exp[, .(court_exp_meur = values[1]), by = .(geo, year)]
panel <- merge(panel, court_clean, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

# ===========================================================================
# 6. Add GDP and population → per-capita variables
# ===========================================================================

cat("Merging GDP and population controls...\n")

gdp_clean <- gdp[, .(gdp_meur = values[1]), by = .(geo, year)]
panel <- merge(panel, gdp_clean, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

pop_clean <- pop[, .(population = values[1]), by = .(geo, year)]
panel <- merge(panel, pop_clean, by.x = c("iso2", "year"), by.y = c("geo", "year"), all.x = TRUE)

# Per-capita crime rates (per 100,000)
panel[, corruption_pc := (corruption_count / population) * 1e5]
panel[, fraud_pc := (fraud_count / population) * 1e5]

# GDP per capita (EUR)
panel[, gdp_pc := (gdp_meur * 1e6) / population]

# Log transformations
panel[, ln_corruption_pc := log(corruption_pc + 1)]
panel[, ln_fraud_pc := log(fraud_pc + 1)]
panel[, ln_gdp_pc := log(gdp_pc)]

# Court expenditure per capita
panel[, court_exp_pc := (court_exp_meur * 1e6) / population]

# ===========================================================================
# 7. Data quality checks
# ===========================================================================

cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Countries:", panel[, uniqueN(iso2)], "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Treated countries:", panel[treated == 1, uniqueN(iso2)], "\n")

cat("\nMissingness:\n")
miss <- panel[, lapply(.SD, function(x) sum(is.na(x))),
  .SDcols = c("corruption_pc", "fraud_pc", "cpi_score", "court_exp_pc", "gdp_pc", "population")]
print(miss)

cat("\nCorruption coverage by year:\n")
print(panel[!is.na(corruption_pc), .N, by = year][order(year)])

cat("\nCPI coverage by year:\n")
print(panel[!is.na(cpi_score), .N, by = year][order(year)])

# ===========================================================================
# 8. Save analytical panel
# ===========================================================================

fwrite(panel, paste0(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved:", nrow(panel), "obs\n")
