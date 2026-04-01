# ==============================================================================
# 01_fetch_data.R — Fetch QWI and SNAP participation data for apep_1253
# ==============================================================================

source("00_packages.R")

# Fix Azure connection string (bash truncates at semicolons)
Sys.unsetenv("AZURE_STORAGE_CONNECTION_STRING")
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  if (startsWith(trimws(line), "AZURE_STORAGE_CONNECTION_STRING")) {
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = sub("^[^=]+=", "", trimws(line)))
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

cat("=== Fetching QWI data from Azure ===\n")

con <- apep_azure_connect()

# Query all 51 states at once from Azure Parquet files
# Filter: 7 industries, 3 age groups (25-34, 35-44, 45-54), sex=0 (all)
# Period: 2018-2023
qwi <- dbGetQuery(con, "
  SELECT
    geography AS fips,
    industry,
    agegrp,
    year,
    quarter,
    Emp AS emp,
    HirA AS hires_all,
    HirN AS hires_new,
    Sep AS separations,
    EarnS AS avg_earnings,
    FrmJbGn AS firm_job_gains,
    FrmJbLs AS firm_job_losses,
    sEmp AS emp_status,
    sHirA AS hires_status,
    sSep AS sep_status,
    sEarnS AS earn_status
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry IN ('72', '44-45', '62', '56', '31-33', '54', '52')
    AND agegrp IN ('A03', 'A04', 'A05')
    AND sex = '0'
    AND year BETWEEN 2018 AND 2023
    AND ownercode = 'A05'
    AND geo_level = 'C'
")

apep_azure_disconnect(con)

setDT(qwi)

# Convert types
qwi[, year := as.integer(year)]
qwi[, quarter := as.integer(quarter)]
num_cols <- c("emp", "hires_all", "hires_new", "separations",
              "avg_earnings", "firm_job_gains", "firm_job_losses")
for (col in num_cols) qwi[, (col) := as.numeric(get(col))]

stopifnot("QWI returned 0 rows — Azure query failed" = nrow(qwi) > 0)

cat(sprintf("QWI rows fetched: %s\n", format(nrow(qwi), big.mark = ",")))
cat(sprintf("Unique counties: %d\n", length(unique(qwi$fips))))
cat(sprintf("Industries: %s\n", paste(sort(unique(qwi$industry)), collapse = ", ")))
cat(sprintf("Year range: %d-%d\n", min(qwi$year), max(qwi$year)))

fwrite(qwi, "../data/qwi_raw.csv")
cat("Saved QWI data\n")

# ==============================================================================
# Fetch SAIPE poverty rates (2019)
# ==============================================================================

cat("\n=== Fetching SAIPE 2019 county poverty rates ===\n")

saipe_url <- "https://api.census.gov/data/timeseries/poverty/saipe"
saipe_params <- list(
  get = "SAEPOVRTALL_PT,SAEPOVRT0_17_PT,SAEMHI_PT,STABREV",
  `for` = "county:*",
  time = "2019"
)

resp <- GET(saipe_url, query = saipe_params)
stopifnot("SAIPE API request failed" = status_code(resp) == 200)

saipe_raw <- content(resp, as = "text", encoding = "UTF-8")
saipe_mat <- fromJSON(saipe_raw)

saipe_dt <- as.data.table(saipe_mat[-1, ])
names(saipe_dt) <- saipe_mat[1, ]

saipe <- saipe_dt[county != "000", .(
  fips = paste0(str_pad(state, 2, pad = "0"), str_pad(county, 3, pad = "0")),
  poverty_rate = as.numeric(SAEPOVRTALL_PT),
  child_poverty_rate = as.numeric(SAEPOVRT0_17_PT),
  median_hh_income = as.numeric(SAEMHI_PT)
)]

cat(sprintf("SAIPE counties: %d\n", nrow(saipe)))
cat(sprintf("Poverty rate range: %.1f%% to %.1f%%\n",
            min(saipe$poverty_rate, na.rm = TRUE),
            max(saipe$poverty_rate, na.rm = TRUE)))

fwrite(saipe, "../data/saipe_2019.csv")

# ==============================================================================
# Fetch county population (2019)
# ==============================================================================

cat("\n=== Fetching county population data ===\n")

pop_url <- "https://api.census.gov/data/2019/pep/population"
pop_params <- list(
  get = "POP,NAME",
  `for` = "county:*"
)

resp_pop <- GET(pop_url, query = pop_params)
stopifnot("Population API request failed" = status_code(resp_pop) == 200)

pop_raw <- content(resp_pop, as = "text", encoding = "UTF-8")
pop_mat <- fromJSON(pop_raw)

pop_dt <- as.data.table(pop_mat[-1, ])
names(pop_dt) <- pop_mat[1, ]

pop <- pop_dt[, .(
  fips = paste0(str_pad(state, 2, pad = "0"), str_pad(county, 3, pad = "0")),
  population = as.numeric(POP),
  county_name = NAME
)]

cat(sprintf("Population counties: %d\n", nrow(pop)))
fwrite(pop, "../data/population_2019.csv")

cat("\n=== Data fetch complete ===\n")
