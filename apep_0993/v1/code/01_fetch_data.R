## 01_fetch_data.R — Data already fetched via ILO SDMX API
## apep_0993: South Korea 52-Hour Workweek Reform
##
## Data files in ../data/:
##   ilo_hours_by_activity.csv    — Korea weekly hours by ISIC4 industry, 1980-2023
##   ilo_hours_cross_country.csv  — OECD comparator hours by industry, 2010-2023
##   ilo_employment_by_activity.csv — Korea employment by industry (thousands)
##
## Source: ILO ILOSTAT via SDMX API (sdmx.ilo.org)
## Indicator: DF_HOW_TEMP_SEX_ECO_NB (Mean weekly hours actually worked)
## Indicator: DF_EMP_TEMP_SEX_ECO_NB (Employment by economic activity)

source("00_packages.R")

cat("Verifying data files...\n")

files <- c(
  "../data/ilo_hours_by_activity.csv",
  "../data/ilo_hours_cross_country.csv",
  "../data/ilo_employment_by_activity.csv"
)

for (f in files) {
  stopifnot(file.exists(f))
  dt <- fread(f)
  stopifnot(nrow(dt) > 0)
  cat(sprintf("  %s: %d rows, %d cols\n", basename(f), nrow(dt), ncol(dt)))
}

cat("All data files verified.\n")
