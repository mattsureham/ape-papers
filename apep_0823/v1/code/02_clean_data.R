## 02_clean_data.R — Clean and construct analysis panel
## apep_0823: The Alice Dividend

library(data.table)
library(jsonlite)

outdir <- here::here("output", "apep_0823", "v1", "data")

## ========== PART 1: Clean CBP Annual Panel ==========
cat("=== Cleaning CBP data ===\n")
cbp <- fread(file.path(outdir, "cbp_raw.csv"))

## Keep county-level observations only (agglvl_code filtering not needed for CBP)
## CBP data: state + county give the FIPS code
cbp[, fips := paste0(
  formatC(as.integer(state), width = 2, flag = "0"),
  formatC(as.integer(county), width = 3, flag = "0")
)]

## Drop state-level aggregates (county = "000")
cbp <- cbp[county != "000" & county != "999"]

## Treatment classification
cbp[, treated := as.integer(naics %in% c("334", "511", "518"))]
cbp[, post := as.integer(year >= 2015)]  # Alice = June 2014; effect starts 2015
cbp[, treat_post := treated * post]

## Industry labels
cbp[, industry_label := fcase(
  naics == "325", "Chemicals/Pharma",
  naics == "334", "Computer/Electronics",
  naics == "336", "Transportation Equip",
  naics == "339", "Misc Manufacturing",
  naics == "511", "Publishing/Software",
  naics == "518", "Data Processing/Internet"
)]

## Drop observations with zero or suppressed employment
cbp_clean <- cbp[emp > 0]
cat("CBP raw:", nrow(cbp), "| After dropping zero emp:", nrow(cbp_clean), "\n")

## Create log outcomes
cbp_clean[, log_emp := log(emp)]
cbp_clean[, log_estab := log(estab)]
cbp_clean[, log_payann := log(payann + 1)]

## State FIPS
cbp_clean[, state_fips := substr(fips, 1, 2)]

## Create balanced panel: keep counties observed in all years
county_year_counts <- cbp_clean[, .(n_years = uniqueN(year)), by = .(fips, naics)]
## Require at least 8 of 12 years
balanced_counties <- county_year_counts[n_years >= 8, .(fips, naics)]
cbp_panel <- cbp_clean[balanced_counties, on = .(fips, naics)]

cat("Balanced panel (8+ years):", nrow(cbp_panel), "rows\n")
cat("  Unique county-industry cells:", uniqueN(cbp_panel[, .(fips, naics)]), "\n")
cat("  Treated industries:", sum(cbp_panel$treated == 1 & cbp_panel$year == 2014), "county-obs\n")
cat("  Control industries:", sum(cbp_panel$treated == 0 & cbp_panel$year == 2014), "county-obs\n")

## ========== PART 2: Clean QCEW Quarterly Panel ==========
cat("\n=== Cleaning QCEW data ===\n")
qcew <- fread(file.path(outdir, "qcew_quarterly.csv"))

## Keep private sector, county-level only
## own_code = 5 (private), agglvl_code = 75 (county, 3-digit NAICS)
qcew_clean <- qcew[own_code == 5 & agglvl_code == 75]

## Keep target industries
qcew_clean <- qcew_clean[industry_code %in% c("325", "334", "336", "339", "511", "518")]

## Employment = average of 3 monthly levels
qcew_clean[, emp := (month1_emplvl + month2_emplvl + month3_emplvl) / 3]
qcew_clean[, fips := area_fips]
qcew_clean[, year := fetch_year]
qcew_clean[, quarter := fetch_qtr]
qcew_clean[, yearqtr := year + (quarter - 1) / 4]

## Treatment classification
qcew_clean[, treated := as.integer(industry_code %in% c("334", "511", "518"))]
## Alice decided June 19, 2014 = during Q2
## Post starts Q3 2014 (immediate effect on patent examination)
qcew_clean[, post := as.integer(yearqtr >= 2014.5)]
qcew_clean[, treat_post := treated * post]

## Drop suppressed observations
qcew_clean <- qcew_clean[emp > 0 & disclosure_code != "N"]

## Log outcomes
qcew_clean[, log_emp := log(emp)]
qcew_clean[, log_wages := log(total_qtrly_wages + 1)]
qcew_clean[, log_estab := log(qtrly_estabs)]

## State FIPS
qcew_clean[, state_fips := substr(fips, 1, 2)]

cat("QCEW clean:", nrow(qcew_clean), "rows\n")
cat("  Quarters:", paste(sort(unique(paste0(qcew_clean$year, "Q", qcew_clean$quarter))), collapse = ", "), "\n")

## ========== PART 3: Create event-time variables ==========

## For CBP (annual): event time relative to 2014
cbp_panel[, event_time := year - 2014]

## For QCEW (quarterly): event time relative to 2014Q2 (Alice decision quarter)
qcew_clean[, event_time := (year - 2014) * 4 + (quarter - 2)]

## ========== PART 4: Summary statistics ==========
cat("\n=== Summary Statistics ===\n")

## CBP summary by treatment group and period
cbp_summary <- cbp_panel[, .(
  mean_emp = mean(as.numeric(emp), na.rm = TRUE),
  median_emp = as.double(median(as.numeric(emp), na.rm = TRUE)),
  sd_emp = sd(as.numeric(emp), na.rm = TRUE),
  mean_estab = mean(as.numeric(estab), na.rm = TRUE),
  n_counties = as.double(uniqueN(fips)),
  n_obs = as.double(.N)
), by = .(treated, post)]

cat("\nCBP Summary by Treatment × Period:\n")
print(cbp_summary)

## QCEW summary
qcew_summary <- qcew_clean[, .(
  mean_emp = mean(emp, na.rm = TRUE),
  sd_emp = sd(emp, na.rm = TRUE),
  n_counties = uniqueN(fips),
  n_obs = .N
), by = .(treated, post)]

cat("\nQCEW Summary by Treatment × Period:\n")
print(qcew_summary)

## ========== SAVE ==========
fwrite(cbp_panel, file.path(outdir, "cbp_panel.csv"))
fwrite(qcew_clean, file.path(outdir, "qcew_panel.csv"))

## Diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(cbp_panel[treated == 1, fips]),
  n_pre = length(unique(cbp_panel[year < 2015, year])),
  n_obs = nrow(cbp_panel)
)
write_json(diagnostics, file.path(outdir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("Saved analysis panels.\n")
