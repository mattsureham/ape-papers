# ==============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure + construct policy timing
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# --- Policy timing: Economic nexus law adoption dates ---
nexus_dates <- tribble(
  ~state_abbr, ~nexus_date,
  "SD", "2016-05-01",
  "AL", "2018-10-01", "CT", "2018-12-01", "DC", "2018-10-01",
  "GA", "2019-01-01", "HI", "2018-07-01", "ID", "2018-07-01",
  "IL", "2018-10-01", "IN", "2018-10-01", "IA", "2019-01-01",
  "KS", "2019-10-01", "KY", "2018-10-01", "LA", "2018-07-01",
  "ME", "2018-07-01", "MD", "2018-10-01", "MA", "2018-10-01",
  "MI", "2018-10-01", "MN", "2018-10-01", "MS", "2018-09-01",
  "MO", "2023-01-01", "NE", "2019-01-01", "NV", "2018-10-01",
  "NJ", "2018-11-01", "NM", "2019-07-01", "NY", "2019-06-01",
  "NC", "2018-11-01", "ND", "2019-01-01", "OH", "2018-08-01",
  "OK", "2018-11-01", "PA", "2018-07-01", "RI", "2019-07-01",
  "SC", "2018-11-01", "TN", "2019-10-01", "TX", "2019-10-01",
  "UT", "2019-01-01", "VT", "2018-07-01", "VA", "2019-07-01",
  "WA", "2018-10-01", "WV", "2019-01-01", "WI", "2018-10-01",
  "WY", "2019-02-01", "FL", "2021-07-01", "AZ", "2019-10-01",
  "AR", "2019-07-01", "CA", "2019-04-01", "CO", "2019-06-01",
  # Never-treated (no sales tax)
  "AK", NA, "DE", NA, "MT", NA, "NH", NA, "OR", NA
) %>%
  mutate(
    nexus_date = as.Date(nexus_date),
    nexus_year = year(nexus_date),
    nexus_quarter = quarter(nexus_date),
    first_treat_yq = ifelse(is.na(nexus_date), 0,
                            nexus_year * 10L + nexus_quarter)
  )

cat("Policy timing: ", nrow(nexus_dates), "states\n")
cat("Treated:", sum(!is.na(nexus_dates$nexus_date)), "\n")
cat("Never-treated:", sum(is.na(nexus_dates$nexus_date)), "\n")

# --- FIPS crosswalk ---
state_fips <- tribble(
  ~state_abbr, ~state_fips,
  "AL",1,"AK",2,"AZ",4,"AR",5,"CA",6,"CO",8,"CT",9,"DE",10,"DC",11,"FL",12,
  "GA",13,"HI",15,"ID",16,"IL",17,"IN",18,"IA",19,"KS",20,"KY",21,"LA",22,
  "ME",23,"MD",24,"MA",25,"MI",26,"MN",27,"MS",28,"MO",29,"MT",30,"NE",31,
  "NV",32,"NH",33,"NJ",34,"NM",35,"NY",36,"NC",37,"ND",38,"OH",39,"OK",40,
  "OR",41,"PA",42,"RI",44,"SC",45,"SD",46,"TN",47,"TX",48,"UT",49,"VT",50,
  "VA",51,"WA",53,"WV",54,"WI",55,"WY",56
)

nexus_dates <- nexus_dates %>% left_join(state_fips, by = "state_abbr")

# --- Fetch QWI data from Azure ---
con <- apep_azure_connect()

# State-level aggregation: sum across counties
# Files are lowercase: az://derived/qwi/sa/ns/{state}.parquet
# geography is BIGINT (FIPS), geo_level is 'S' for state, 'C' for county

cat("Querying QWI state-level data from Azure...\n")

qwi_query <- "
SELECT
  geography AS state_fips,
  year, quarter,
  industry,
  agegrp,
  SUM(Emp) AS Emp,
  SUM(HirA) AS HirA,
  SUM(HirN) AS HirN,
  SUM(Sep) AS Sep,
  SUM(FrmJbGn) AS FrmJbGn,
  SUM(FrmJbLs) AS FrmJbLs,
  SUM(EarnS) AS EarnS
FROM read_parquet('az://derived/qwi/sa/ns/*.parquet')
WHERE geo_level = 'S'
  AND sex = 0
  AND agegrp IN ('A00', 'A01', 'A02', 'A03', 'A04')
  AND industry IN ('44-45', '48-49', '61', '62')
  AND year >= 2014
  AND year <= 2023
GROUP BY geography, year, quarter, industry, agegrp
"

qwi_raw <- DBI::dbGetQuery(con, qwi_query)
qwi <- as_tibble(qwi_raw)

cat("QWI rows fetched:", nrow(qwi), "\n")
cat("Unique states:", n_distinct(qwi$state_fips), "\n")
cat("Year range:", min(qwi$year), "-", max(qwi$year), "\n")
cat("Industries:", paste(unique(qwi$industry), collapse = ", "), "\n")

stopifnot("No data returned from Azure" = nrow(qwi) > 0)

apep_azure_disconnect(con)

# --- State sales tax rates ---
tax_rates <- tribble(
  ~state_abbr, ~sales_tax_rate,
  "AL",4.00,"AZ",5.60,"AR",6.50,"CA",7.25,"CO",2.90,"CT",6.35,"DC",6.00,
  "FL",6.00,"GA",4.00,"HI",4.00,"ID",6.00,"IL",6.25,"IN",7.00,"IA",6.00,
  "KS",6.50,"KY",6.00,"LA",4.45,"ME",5.50,"MD",6.00,"MA",6.25,"MI",6.00,
  "MN",6.88,"MS",7.00,"MO",4.23,"NE",5.50,"NV",6.85,"NJ",6.63,"NM",5.13,
  "NY",4.00,"NC",4.75,"ND",5.00,"OH",5.75,"OK",4.50,"PA",6.00,"RI",7.00,
  "SC",6.00,"SD",4.50,"TN",7.00,"TX",6.25,"UT",6.10,"VT",6.00,"VA",5.30,
  "WA",6.50,"WV",6.00,"WI",5.00,"WY",4.00,
  "AK",0.00,"DE",0.00,"MT",0.00,"NH",0.00,"OR",0.00
)

# --- Save ---
saveRDS(qwi, "../data/qwi_raw.rds")
saveRDS(nexus_dates, "../data/nexus_dates.rds")
saveRDS(tax_rates, "../data/tax_rates.rds")

cat("Data saved.\n")
cat("QWI:", format(nrow(qwi), big.mark = ","), "obs\n")
