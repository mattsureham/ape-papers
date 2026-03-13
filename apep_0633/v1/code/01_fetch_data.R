## 01_fetch_data.R — Download Census Annual Survey of School System Finances
## apep_0633: Marijuana tax earmarking and education spending fungibility

source("00_packages.R")

data_dir <- "../data/"

## ──────────────────────────────────────────────────
## 1. Census School Finance Data (state-level tables)
## ──────────────────────────────────────────────────

# Census ASSF state-level tables: 2008-2022
# URL pattern varies slightly across years
# Two main formats: elsecYY_sttables.xls (older) and elsecYY_sttables.xlsx (newer)

years <- 2008:2022

download_school_finance <- function(year) {
  yy <- sprintf("%02d", year %% 100)

  # Try multiple URL patterns
  urls <- c(
    sprintf("https://www2.census.gov/programs-surveys/school-finances/tables/%d/secondary-education-finance/elsec%s_sttables.xls", year, yy),
    sprintf("https://www2.census.gov/programs-surveys/school-finances/tables/%d/secondary-education-finance/elsec%s_sttables.xlsx", year, yy),
    sprintf("https://www2.census.gov/programs-surveys/school-finances/tables/%d/secondary-education-finance/elsec%s_sumtables.xls", year, yy),
    sprintf("https://www2.census.gov/programs-surveys/school-finances/tables/%d/secondary-education-finance/elsec%s_sumtables.xlsx", year, yy)
  )

  outfile <- file.path(data_dir, sprintf("elsec%s.xls", yy))

  if (file.exists(outfile) || file.exists(paste0(outfile, "x"))) {
    cat(sprintf("  %d: already downloaded\n", year))
    return(TRUE)
  }

  for (url in urls) {
    resp <- tryCatch({
      GET(url, write_disk(outfile, overwrite = TRUE), timeout(60))
    }, error = function(e) NULL)

    if (!is.null(resp) && status_code(resp) == 200 && file.size(outfile) > 1000) {
      cat(sprintf("  %d: downloaded from %s\n", year, basename(url)))
      return(TRUE)
    }
  }

  # Clean up failed download
  if (file.exists(outfile)) file.remove(outfile)
  cat(sprintf("  %d: FAILED to download\n", year))
  return(FALSE)
}

cat("Downloading Census School Finance state tables...\n")
results <- sapply(years, download_school_finance)

n_success <- sum(results)
n_fail <- sum(!results)
cat(sprintf("\nDownloaded: %d/%d years\n", n_success, length(years)))

if (n_success < 10) {
  stop("FATAL: Could not download sufficient school finance data. Need at least 10 years.")
}

## ──────────────────────────────────────────────────
## 2. Treatment Data — Marijuana legalization dates
## ──────────────────────────────────────────────────

# Treatment year = calendar year of first legal recreational marijuana sales
# Sources: NORML, MPP, Tax Foundation
# Earmarking classification from state statutes

treatment_data <- tribble(
  ~state_abbr, ~state_name,          ~treatment_year, ~earmark_education,
  "CO",        "Colorado",           2014,            TRUE,   # BEST school construction fund ($40M+)
  "WA",        "Washington",         2014,            FALSE,  # General fund, health, substance abuse
  "OR",        "Oregon",             2015,            TRUE,   # 40% to Common School Fund
  "AK",        "Alaska",             2016,            FALSE,  # General fund
  "NV",        "Nevada",             2017,            TRUE,   # Distributive School Account from license fees
  "CA",        "California",         2018,            FALSE,  # Youth programs, environment, not K-12
  "MA",        "Massachusetts",      2018,            FALSE,  # General fund + local aid
  "IL",        "Illinois",           2020,            TRUE,   # 25% to community college grants via GOMB
  "MI",        "Michigan",           2020,            TRUE,   # 35% School Aid Fund
  "ME",        "Maine",              2020,            FALSE,  # General fund + local
  "AZ",        "Arizona",            2021,            FALSE,  # Community colleges, public safety, highways
  "MT",        "Montana",            2022,            FALSE,  # General fund, conservation
  "NJ",        "New Jersey",         2022,            FALSE,  # Social equity, municipalities
  "NM",        "New Mexico",         2022,            FALSE,  # General fund, municipalities, substance abuse
  "VT",        "Vermont",            2022,            TRUE,   # Education fund (portion)
  "CT",        "Connecticut",        2023,            FALSE,  # Social equity, prevention
  "MD",        "Maryland",           2023,            TRUE,   # Blueprint for Maryland's Future (education)
  "MO",        "Missouri",           2023,            FALSE,  # Veterans, drug treatment, municipalities
  "NY",        "New York",           2023,            FALSE,  # General fund, social equity, education (portion)
  "RI",        "Rhode Island",       2023,            FALSE   # General fund, municipalities
)

# Note: DE, MN, OH, VA legalized but sales started 2024+ (beyond Census data window)
# DC legalized possession but not retail sales

cat(sprintf("Treatment states: %d\n", nrow(treatment_data)))
cat(sprintf("  Earmark education: %d\n", sum(treatment_data$earmark_education)))
cat(sprintf("  No education earmark: %d\n", sum(!treatment_data$earmark_education)))

# Save treatment data
write_csv(treatment_data, file.path(data_dir, "treatment_data.csv"))

## ──────────────────────────────────────────────────
## 3. Marijuana Tax Revenue by State-Year
## ──────────────────────────────────────────────────

# Compiled from Tax Foundation, state revenue reports, MJBizDaily
# Units: millions of nominal USD
# Note: These are total marijuana tax revenue, not just education-earmarked portion

mj_revenue <- tribble(
  ~state_abbr, ~year, ~mj_tax_revenue_m,
  # Colorado (2.9% state + 15% special + 15% excise)
  "CO", 2014,  76,  "CO", 2015, 135, "CO", 2016, 193, "CO", 2017, 247,
  "CO", 2018, 267, "CO", 2019, 302, "CO", 2020, 387, "CO", 2021, 423,
  "CO", 2022, 354,
  # Washington (37% excise)
  "WA", 2015, 65, "WA", 2016, 186, "WA", 2017, 315, "WA", 2018, 367,
  "WA", 2019, 395, "WA", 2020, 469, "WA", 2021, 559, "WA", 2022, 515,
  # Oregon (17% retail)
  "OR", 2016, 60, "OR", 2017, 85, "OR", 2018, 94, "OR", 2019, 102,
  "OR", 2020, 133, "OR", 2021, 179, "OR", 2022, 148,
  # Nevada (15% excise + 10% retail)
  "NV", 2018, 70, "NV", 2019, 98, "NV", 2020, 106, "NV", 2021, 146,
  "NV", 2022, 140,
  # California (15% excise + cultivation)
  "CA", 2018, 345, "CA", 2019, 411, "CA", 2020, 628, "CA", 2021, 817,
  "CA", 2022, 725,
  # Massachusetts (10.75% excise + 6.25% sales)
  "MA", 2019, 57, "MA", 2020, 122, "MA", 2021, 186, "MA", 2022, 168,
  # Illinois (7-25% graduated + 6.25% sales)
  "IL", 2020, 52, "IL", 2021, 296, "IL", 2022, 350,
  # Michigan (10% excise + 6% sales)
  "MI", 2020, 31, "MI", 2021, 259, "MI", 2022, 277,
  # Alaska
  "AK", 2017, 11, "AK", 2018, 15, "AK", 2019, 19, "AK", 2020, 24,
  "AK", 2021, 30, "AK", 2022, 28,
  # Arizona
  "AZ", 2021, 83, "AZ", 2022, 193
)

write_csv(mj_revenue, file.path(data_dir, "mj_revenue.csv"))
cat(sprintf("Marijuana revenue data: %d state-year observations\n", nrow(mj_revenue)))

cat("\n=== Data fetch complete ===\n")
