## 01_fetch_data.R — Fetch QWI data from Azure for PSL analysis
## apep_0704: Paid Sick Leave and Worker Separation Dynamics

source("00_packages.R")

cat("=== Fetching QWI data from Azure ===\n")

# ── Connect to Azure ──
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# ── Query QWI: state × NAICS sector × quarter (sex × age demographics) ──
# Industries of interest:
#   High-exposure: 72 (Accommodation/Food), 44-45 (Retail), 62 (Healthcare)
#   Low-exposure (placebo): 52 (Finance), 54 (Professional Services)
#   Additional: 23 (Construction), 31-33 (Manufacturing), 11 (Agriculture)

cat("Querying Azure QWI sa/ns (all states, all industries, 2005-2023)...\n")

qwi <- dbGetQuery(con, "
  SELECT
    geography AS fips_state,
    year,
    quarter,
    industry,
    sex,
    agegrp,
    Emp,
    EmpEnd,
    HirA,
    HirN,
    Sep,
    EarnS,
    EarnHirAS,
    TurnOvrS,
    FrmJbGn,
    FrmJbLs,
    sEmp,
    sSep,
    sHirA,
    sHirN,
    sEarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE year BETWEEN 2005 AND 2023
    AND agegrp IN ('A00', 'A01', 'A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08')
    AND sex IN ('0', '1', '2')
")

cat(sprintf("QWI rows fetched: %s\n", format(nrow(qwi), big.mark = ",")))

# ── Validate: no empty result ──
stopifnot("QWI data is empty — Azure query failed" = nrow(qwi) > 0)
stopifnot("Missing separation data" = sum(!is.na(qwi$Sep)) > 0)

# ── Create state FIPS to abbreviation mapping ──
state_fips <- data.frame(
  fips_state = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  stringsAsFactors = FALSE
)

# ── PSL treatment dates ──
# First quarter of mandatory PSL enforcement
psl_dates <- data.frame(
  state_abbr = c("CT","CA","MA","OR","VT","AZ","WA","MD","RI","NJ",
                 "MI","NV","NY","CO","ME","NM"),
  first_treat_yq = c(
    2012.00,  # CT: Jan 2012
    2015.50,  # CA: Jul 2015
    2015.50,  # MA: Jul 2015
    2016.00,  # OR: Jan 2016
    2017.00,  # VT: Jan 2017
    2017.50,  # AZ: Jul 2017
    2018.00,  # WA: Jan 2018
    2018.00,  # MD: Feb 2018
    2018.50,  # RI: Jul 2018
    2018.75,  # NJ: Oct 2018
    2019.00,  # MI: Mar 2019
    2020.00,  # NV: Jan 2020
    2020.50,  # NY: Sep 2020
    2021.00,  # CO: Jan 2021
    2021.00,  # ME: Jan 2021
    2022.50   # NM: Jul 2022
  ),
  stringsAsFactors = FALSE
)

# Convert to integer year-quarter for CS-DiD
# first_treat_yq: year + (quarter-1)/4, so 2012.00 = 2012Q1, 2015.50 = 2015Q3
psl_dates$first_treat_year <- floor(psl_dates$first_treat_yq)
psl_dates$first_treat_quarter <- round((psl_dates$first_treat_yq - psl_dates$first_treat_year) * 4) + 1

cat(sprintf("PSL treatment states: %d\n", nrow(psl_dates)))
cat("Treatment dates:\n")
print(psl_dates)

# ── Save raw data ──
saveRDS(qwi, "../data/qwi_raw.rds")
saveRDS(psl_dates, "../data/psl_dates.rds")
saveRDS(state_fips, "../data/state_fips.rds")

cat("Data saved to data/ directory.\n")
cat(sprintf("QWI dimensions: %d rows x %d cols\n", nrow(qwi), ncol(qwi)))
cat(sprintf("States in QWI: %d\n", length(unique(qwi$fips_state))))
cat(sprintf("Industries in QWI: %d\n", length(unique(qwi$industry))))
cat(sprintf("Year range: %d - %d\n", min(qwi$year), max(qwi$year)))

dbDisconnect(con)
cat("=== Data fetch complete ===\n")
