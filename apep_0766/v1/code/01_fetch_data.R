## 01_fetch_data.R — Fetch Brazilian municipal data
## apep_0766: Council size thresholds and infant mortality in Brazil
##
## Sources:
##   1. IBGE Sidra API — Municipal population estimates
##   2. Google BigQuery (basedosdados) — DATASUS SIM (deaths) + SINASC (births)
##   3. TSE — Council size by municipality and election year

source("00_packages.R")

if (!requireNamespace("bigrquery", quietly = TRUE)) {
  install.packages("bigrquery", repos = "https://cloud.r-project.org")
}
library(bigrquery)

set.seed(20260322)

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. IBGE POPULATION ESTIMATES (2001-2020)
# ============================================================
cat("=== Fetching IBGE population estimates ===\n")

pop_all <- list()

for (yr in 2001:2020) {
  cat(sprintf("  Population %d... ", yr))

  url <- sprintf(
    "https://apisidra.ibge.gov.br/values/t/6579/n6/all/v/9324/p/%d",
    yr
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(120)),
    error = function(e) {
      cat(sprintf("HTTP error: %s\n", e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat(sprintf("FAILED (status %s)\n",
                ifelse(is.null(resp), "NULL", httr::status_code(resp))))
    next
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  dt <- tryCatch(jsonlite::fromJSON(raw), error = function(e) NULL)

  if (is.null(dt) || nrow(dt) < 100) {
    cat(sprintf("Parse failed or too few rows (%d)\n",
                ifelse(is.null(dt), 0, nrow(dt))))
    next
  }

  # First row is header in IBGE API; skip it
  dt <- dt[-1, , drop = FALSE]

  pop_yr <- data.table(
    muni_code = as.integer(dt[["D1C"]]),
    muni_name = dt[["D1N"]],
    year = yr,
    population = as.integer(gsub("[^0-9]", "", dt[["V"]]))
  )

  pop_yr <- pop_yr[!is.na(population) & population > 0]
  cat(sprintf("OK (%d municipalities)\n", nrow(pop_yr)))
  pop_all[[as.character(yr)]] <- pop_yr
}

pop_df <- rbindlist(pop_all)
stopifnot("Population data must have >50K rows" = nrow(pop_df) > 50000)
cat(sprintf("Total population records: %d\n", nrow(pop_df)))

fwrite(pop_df, file.path(data_dir, "ibge_population.csv"))

# ============================================================
# 2. VITAL STATISTICS VIA BIGQUERY (basedosdados)
# ============================================================
cat("\n=== Fetching DATASUS vital statistics via BigQuery ===\n")

bq_auth(path = "~/.config/gcloud/application_default_credentials.json")

# --- 2a. Infant deaths from SIM ---
cat("Querying SIM (infant deaths by municipality-year)...\n")

# ICD-10 codes for infant deaths: we select deaths where the cause is
# classified as "P" (perinatal conditions) OR any cause for ages < 1 year.
# However, the basedosdados table is aggregate by municipality-cause.
# We need to sum ALL deaths for infants. The SIM municipio_causa table
# has all causes — we need to filter for infant-specific causes (chapter XVI: P00-P96)
# OR use the broader approach: sum all deaths from SIM microdata with age < 1.
# Since we're using the municipio_causa aggregate, we'll use perinatal (P*) + congenital (Q*)
# + external causes common in infants. But a cleaner approach is the microdata.

# Use SIM microdados for age filtering
sql_deaths <- "
SELECT
  ano,
  SUBSTR(id_municipio_residencia, 1, 6) AS muni_code6,
  COUNT(*) AS infant_deaths
FROM `basedosdados.br_ms_sim.microdados`
WHERE ano BETWEEN 2003 AND 2020
  AND idade < 1
GROUP BY ano, muni_code6
ORDER BY ano, muni_code6
"

# Check if SIM microdados exists with age field
sql_check <- "SELECT column_name FROM `basedosdados.br_ms_sim.INFORMATION_SCHEMA.COLUMNS` WHERE table_name = 'microdados' AND column_name = 'idade'"
check_result <- tryCatch({
  tb <- bq_project_query("scl-librechat", sql_check)
  bq_table_download(tb)
}, error = function(e) NULL)

if (!is.null(check_result) && nrow(check_result) > 0) {
  cat("  SIM microdados has age field. Querying...\n")
  deaths_tb <- bq_project_query("scl-librechat", sql_deaths)
  deaths_df <- as.data.table(bq_table_download(deaths_tb, n_max = Inf))
} else {
  cat("  SIM microdados age field not found. Using cause-based approach...\n")

  # Alternative: use municipio_causa table, filtering for perinatal causes (P00-P96)
  # These account for ~90% of infant deaths
  sql_deaths_alt <- "
  SELECT
    ano,
    SUBSTR(id_municipio, 1, 6) AS muni_code6,
    SUM(numero_obitos) AS infant_deaths
  FROM `basedosdados.br_ms_sim.municipio_causa`
  WHERE ano BETWEEN 2003 AND 2020
    AND (causa_basica LIKE 'P%' OR causa_basica LIKE 'Q%'
         OR causa_basica LIKE 'A0%' OR causa_basica LIKE 'J1%')
  GROUP BY ano, muni_code6
  ORDER BY ano, muni_code6
  "
  deaths_tb <- bq_project_query("scl-librechat", sql_deaths_alt)
  deaths_df <- as.data.table(bq_table_download(deaths_tb, n_max = Inf))
}

deaths_df[, muni_code6 := as.integer(muni_code6)]
deaths_df <- deaths_df[!is.na(muni_code6) & !is.na(infant_deaths)]

cat(sprintf("  Infant death records: %d municipality-years\n", nrow(deaths_df)))
cat(sprintf("  Years: %d to %d\n", min(deaths_df$ano), max(deaths_df$ano)))
cat(sprintf("  Total deaths: %s\n", format(sum(deaths_df$infant_deaths), big.mark = ",")))

stopifnot("Must have >10K death records" = nrow(deaths_df) > 10000)
fwrite(deaths_df, file.path(data_dir, "infant_deaths.csv"))

# --- 2b. Live births from SINASC ---
cat("\nQuerying SINASC (live births by municipality-year)...\n")

sql_births <- "
SELECT
  ano,
  SUBSTR(id_municipio_residencia, 1, 6) AS muni_code6,
  COUNT(*) AS live_births,
  AVG(peso) AS mean_birthweight,
  SUM(CASE WHEN pre_natal_agr = '1' THEN 1 ELSE 0 END) AS adequate_prenatal,
  SUM(CASE WHEN peso < 2500 THEN 1 ELSE 0 END) AS low_birthweight
FROM `basedosdados.br_ms_sinasc.microdados`
WHERE ano BETWEEN 2003 AND 2020
GROUP BY ano, muni_code6
ORDER BY ano, muni_code6
"

births_tb <- bq_project_query("scl-librechat", sql_births)
births_df <- as.data.table(bq_table_download(births_tb, n_max = Inf))

births_df[, muni_code6 := as.integer(muni_code6)]
births_df <- births_df[!is.na(muni_code6) & !is.na(live_births)]

cat(sprintf("  Birth records: %d municipality-years\n", nrow(births_df)))
cat(sprintf("  Years: %d to %d\n", min(births_df$ano), max(births_df$ano)))
cat(sprintf("  Total births: %s\n", format(sum(births_df$live_births), big.mark = ",")))

stopifnot("Must have >50K birth records" = nrow(births_df) > 50000)
fwrite(births_df, file.path(data_dir, "live_births.csv"))

# ============================================================
# 3. TSE — COUNCIL SIZE BY MUNICIPALITY AND ELECTION YEAR
# ============================================================
cat("\n=== Fetching TSE election data ===\n")

# Check if TSE data available on BigQuery
sql_tse_check <- "
SELECT COUNT(*) as n
FROM `basedosdados.br_tse_eleicoes.candidatos`
WHERE ano = 2016 AND cargo = 'vereador' AND resultado = 'eleito'
"

tse_result <- tryCatch({
  tb <- bq_project_query("scl-librechat", sql_tse_check)
  bq_table_download(tb)
}, error = function(e) NULL)

if (!is.null(tse_result) && tse_result$n > 0) {
  cat("  TSE data found on BigQuery. Querying elected vereadores...\n")

  sql_tse <- "
  SELECT
    ano AS election_year,
    SUBSTR(id_municipio, 1, 6) AS muni_code6,
    COUNT(*) AS council_size
  FROM `basedosdados.br_tse_eleicoes.candidatos`
  WHERE cargo = 'vereador'
    AND resultado IN ('eleito', 'eleito por media', 'eleito por qp')
    AND ano IN (2000, 2004, 2008, 2012, 2016, 2020)
  GROUP BY election_year, muni_code6
  ORDER BY election_year, muni_code6
  "

  council_tb <- bq_project_query("scl-librechat", sql_tse)
  council_df <- as.data.table(bq_table_download(council_tb, n_max = Inf))
  council_df[, muni_code6 := as.integer(muni_code6)]

  cat(sprintf("  Council records: %d municipality-elections\n", nrow(council_df)))
  fwrite(council_df, file.path(data_dir, "council_sizes.csv"))
} else {
  cat("  TSE BigQuery tables not accessible. Will use constitutional thresholds.\n")
}

# ============================================================
# 4. CONSTITUTIONAL THRESHOLDS (deterministic)
# ============================================================
cat("\n=== Constructing constitutional council size thresholds ===\n")

thresholds <- data.table(
  pop_min = c(0,     15001, 30001, 50001, 80001, 120001, 160001, 300001, 450001, 600001),
  pop_max = c(15000, 30000, 50000, 80000, 120000, 160000, 300000, 450000, 600000, 750000),
  min_seats = c(9,   11,    13,    15,    17,     19,     21,     23,     25,     27)
)

fwrite(thresholds, file.path(data_dir, "constitutional_thresholds.csv"))
cat("Constitutional thresholds saved.\n")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Population: %d rows\n", nrow(pop_df)))
cat(sprintf("Deaths: %d rows\n", nrow(deaths_df)))
cat(sprintf("Births: %d rows\n", nrow(births_df)))
if (exists("council_df")) cat(sprintf("Council: %d rows\n", nrow(council_df)))
