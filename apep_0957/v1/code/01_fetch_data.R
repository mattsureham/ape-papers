## 01_fetch_data.R — Fetch QWI from Azure + build EITC treatment panel
## All data from Census QWI via Azure and NCSL published compilations

source("00_packages.R")

# --- Fix .env loading: read full connection string directly ---
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
if (length(cs_line) == 0) stop("AZURE_STORAGE_CONNECTION_STRING not found in .env")
cs <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = cs)

source("../../../../scripts/lib/azure_data.R")

cat("=== Fetching QWI Race/Ethnicity data from Azure ===\n")

stopifnot(apep_azure_available())
con <- apep_azure_connect()

# --- QWI Race/Ethnicity Panel ---
# Data is at county level; aggregate to state level (geo_level = 'S' has gaps)
# industry codes: '56', '52', '54', '44', '72', '62', '61'
# ethnicity: 'A1' (Non-Hispanic), 'A2' (Hispanic)

qwi <- apep_azure_query(con, "
  SELECT
    CAST(FLOOR(CAST(geography AS INTEGER) / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry AS ind_2d,
    ethnicity,
    SUM(Emp) AS Emp,
    SUM(EmpS) AS EmpS,
    SUM(HirA) AS HirA,
    SUM(Sep) AS Sep,
    SUM(Payroll) AS Payroll
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('56', '52', '54', '44', '72', '62', '61')
    AND ethnicity IN ('A1', 'A2')
    AND ind_level = 'S'
    AND year >= 1998
    AND year <= 2023
  GROUP BY CAST(FLOOR(CAST(geography AS INTEGER) / 1000) AS INTEGER),
           year, quarter, industry, ethnicity
  ORDER BY state_fips, year, quarter, industry, ethnicity
")

cat(sprintf("QWI rows fetched: %d\n", nrow(qwi)))
stopifnot("QWI data must have rows" = nrow(qwi) > 0)
stopifnot("Required columns present" = all(c("state_fips", "year", "quarter",
  "ind_2d", "ethnicity", "EmpS") %in% names(qwi)))

apep_azure_disconnect(con)

# --- State EITC Treatment Panel ---
# Source: NCSL State EITC compilation + Tax Policy Center
# Adoption year = year state EITC first available for tax filing
# Generosity = approximate % of federal credit at adoption

eitc_states <- tribble(
  ~state_fips, ~state_abbr, ~eitc_year, ~eitc_pct,
  # Early adopters (pre-2000)
  24L, "MD",  1987, 0.50,
  27L, "MN",  1991, 0.25,
  36L, "NY",  1994, 0.30,
  55L, "WI",  1994, 0.04,
  25L, "MA",  1997, 0.15,
  # 2000s wave
  11L, "DC",  2000, 0.40,
  50L, "VT",  2000, 0.36,
  34L, "NJ",  2000, 0.25,
  17L, "IL",  2000, 0.18,
  22L, "LA",  2003, 0.05,
  09L, "CT",  2004, 0.30,
  51L, "VA",  2004, 0.20,
  10L, "DE",  2005, 0.20,
  40L, "OK",  2005, 0.05,
  44L, "RI",  2003, 0.15,
  41L, "OR",  2006, 0.06,
  26L, "MI",  2006, 0.06,
  31L, "NE",  2006, 0.10,
  35L, "NM",  2007, 0.10,
  23L, "ME",  2000, 0.05,
  53L, "WA",  2008, 0.10,
  37L, "NC",  2008, 0.05,
  # 2010s wave
  20L, "KS",  2010, 0.17,
  08L, "CO",  2014, 0.10,
  06L, "CA",  2015, 0.45,
  45L, "SC",  2018, 0.125,
  32L, "NV",  2019, 0.10,
  15L, "HI",  2017, 0.20,
  30L, "MT",  2019, 0.03
)

# Filter to adoptions within our analysis window
eitc_states <- eitc_states %>% filter(eitc_year <= 2022)

cat(sprintf("EITC states in panel: %d\n", nrow(eitc_states)))

# --- Merge treatment status onto QWI ---
qwi <- qwi %>%
  mutate(state_fips = as.integer(state_fips)) %>%
  left_join(eitc_states %>% select(state_fips, eitc_year, eitc_pct),
            by = "state_fips") %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    has_eitc = !is.na(eitc_year) & year >= eitc_year,
    first_treat = ifelse(is.na(eitc_year), 0L, as.integer(eitc_year)),
    naics56 = as.integer(ind_2d == "56"),
    hispanic = as.integer(ethnicity == "A2"),
    ln_emp = log(pmax(EmpS, 1))
  )

# Handle missing EmpS: use Emp as fallback where EmpS is NA
qwi <- qwi %>%
  mutate(
    EmpS = coalesce(EmpS, Emp),
    ln_emp = log(pmax(EmpS, 1))
  )

cat(sprintf("Merged panel: %d rows\n", nrow(qwi)))
cat(sprintf("States with EITC: %d, Never-treated states: %d\n",
            n_distinct(qwi$state_fips[qwi$first_treat > 0]),
            n_distinct(qwi$state_fips[qwi$first_treat == 0])))
cat(sprintf("Year range: %d to %d\n", min(qwi$year), max(qwi$year)))

# --- Validation ---
stopifnot("Must have treated states" = sum(qwi$has_eitc) > 0)
stopifnot("Must have control states" = sum(qwi$first_treat == 0) > 0)
stopifnot("Must have Hispanic obs" = sum(qwi$hispanic == 1) > 0)
stopifnot("Must have NAICS 56 obs" = sum(qwi$naics56 == 1) > 0)

# --- Save ---
saveRDS(qwi, "../data/qwi_eitc_panel.rds")
saveRDS(eitc_states, "../data/eitc_states.rds")

cat("Data saved to data/qwi_eitc_panel.rds\n")
cat("=== Data fetch complete ===\n")
