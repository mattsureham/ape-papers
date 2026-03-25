# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure + CBP from Census
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

source("00_packages.R")

# Fix Azure connection string (contains semicolons and '=' which confuse .env parser)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub("^[\"']|[\"']$", "", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

# --- 1. QWI: NAICS 522 (Credit Intermediation) from Azure -----------------

cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# Query NAICS 3-digit data for industry 522 (Credit Intermediation)
# and 523 (Securities/Investments — placebo, unaffected by payday rule)
# sa = sex × age demographic breakdown, n3 = NAICS 3-digit
cat("Fetching QWI NAICS 522 + 523 from Azure (all states)...\n")

qwi_raw <- dbGetQuery(con, "
  SELECT
    geography,
    year,
    quarter,
    sex,
    agegrp,
    industry,
    EmpEnd,
    HirN,
    Sep,
    EarnS,
    FrmJbLs,
    FrmJbGn
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('522', '523')
    AND year BETWEEN 2014 AND 2022
    AND sex = '0'
    AND agegrp = 'A00'
")

cat(sprintf("QWI rows fetched: %d\n", nrow(qwi_raw)))
stopifnot("QWI data must have rows" = nrow(qwi_raw) > 0)

apep_azure_disconnect(con)

# Clean geography (FIPS codes)
qwi <- qwi_raw %>%
  mutate(
    fips = sprintf("%05d", as.integer(geography)),
    state_fips = substr(fips, 1, 2),
    year_quarter = as.numeric(year) + (as.numeric(quarter) - 1) / 4,
    period = paste0(year, "Q", quarter)
  ) %>%
  filter(nchar(fips) == 5) %>%
  # Drop state-level aggregates (county FIPS ending in 000)
  filter(substr(fips, 3, 5) != "000")

cat(sprintf("QWI after cleaning: %d rows, %d unique counties\n",
            nrow(qwi), n_distinct(qwi$fips)))

# --- 2. County Business Patterns: Payday density (NAICS 522390) -----------

# Download 2017 CBP complete county file from Census (zip format)
cbp_url <- "https://www2.census.gov/programs-surveys/cbp/datasets/2017/cbp17co.zip"
cat("Downloading 2017 County Business Patterns...\n")

cbp_zip <- "../data/cbp17co.zip"
cbp_file <- "../data/cbp17co.txt"
if (!file.exists(cbp_file)) {
  download.file(cbp_url, cbp_zip, mode = "wb")
  unzip(cbp_zip, exdir = "../data/")
}

cbp_raw <- read_csv(cbp_file, show_col_types = FALSE)
cat(sprintf("CBP rows: %d\n", nrow(cbp_raw)))

# Filter for NAICS 522390 (Activities Related to Credit Intermediation)
# and 522 (Credit Intermediation overall) for total sector size
cbp_payday <- cbp_raw %>%
  filter(naics %in% c("522390", "522///")) %>%
  mutate(
    fips = sprintf("%05d", as.integer(paste0(fipstate, fipscty))),
    est = as.numeric(est)
  ) %>%
  select(fips, naics, est) %>%
  pivot_wider(names_from = naics, values_from = est, values_fill = 0) %>%
  rename(
    payday_est = `522390`,
    credit_est = `522///`
  )

cat(sprintf("CBP counties with payday data: %d\n", nrow(cbp_payday)))
stopifnot("CBP must have counties" = nrow(cbp_payday) > 0)

# --- 3. County population for density calculation -------------------------

# Use Census population estimates (2017)
pop_url <- "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv"
pop_file <- "../data/county_pop_2017.csv"
if (!file.exists(pop_file)) {
  download.file(pop_url, pop_file, mode = "w")
}

pop_raw <- read_csv(pop_file, show_col_types = FALSE)
county_pop <- pop_raw %>%
  mutate(
    STATE = as.integer(STATE),
    COUNTY = as.integer(COUNTY),
    fips = sprintf("%05d", STATE * 1000 + COUNTY)
  ) %>%
  filter(COUNTY > 0) %>%
  select(fips, pop2017 = POPESTIMATE2017)

cat(sprintf("Population data: %d counties\n", nrow(county_pop)))

# --- 4. Merge treatment intensity with QWI --------------------------------

# Create treatment intensity: payday establishments per 10,000 pop
treatment <- cbp_payday %>%
  left_join(county_pop, by = "fips") %>%
  mutate(
    payday_density = ifelse(is.na(pop2017) | pop2017 == 0, 0,
                            payday_est / pop2017 * 10000)
  ) %>%
  select(fips, payday_est, credit_est, pop2017, payday_density)

cat(sprintf("Treatment intensity: mean density = %.3f, max = %.3f\n",
            mean(treatment$payday_density, na.rm = TRUE),
            max(treatment$payday_density, na.rm = TRUE)))

# Merge with QWI
df <- qwi %>%
  left_join(treatment, by = "fips") %>%
  filter(!is.na(payday_density))

cat(sprintf("Final merged dataset: %d rows, %d counties\n",
            nrow(df), n_distinct(df$fips)))

# --- 5. Save ---------------------------------------------------------------

saveRDS(df, "../data/analysis_panel.rds")
saveRDS(treatment, "../data/treatment_intensity.rds")

cat("Data saved to ../data/\n")
cat(sprintf("Summary:\n  Counties: %d\n  Quarters: %s to %s\n  Industries: %s\n",
            n_distinct(df$fips),
            min(df$period), max(df$period),
            paste(unique(df$industry), collapse = ", ")))
