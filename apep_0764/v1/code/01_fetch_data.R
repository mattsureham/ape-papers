# 01_fetch_data.R — Fetch RAIS data from BigQuery + SIDRA supplementary data
# apep_0764: Brazil Intermittent Contracts

source("00_packages.R")

# =============================================================================
# 1. RAIS DATA VIA BIGQUERY
# =============================================================================
# Aggregate RAIS worker-year records to municipality-CNAE2-year cells
# This avoids downloading 2B+ rows — aggregation happens on BigQuery servers

cat("Connecting to BigQuery...\n")
bq_auth()  # Uses ADC from ~/.config/gcloud/application_default_credentials.json

project <- "scl-librechat"

# Step 1a: Get municipality × CNAE2 × year aggregates (2014-2022)
# Including intermittent contract flag (available from 2017)
cat("Querying RAIS municipality-CNAE2-year aggregates (2014-2022)...\n")

query_rais <- "
SELECT
  ano AS year,
  id_municipio AS muni_code,
  SUBSTR(CAST(cnae_2_subclasse AS STRING), 1, 2) AS cnae2,
  COUNT(*) AS n_workers,
  AVG(valor_remuneracao_media) AS avg_wage,
  STDDEV(valor_remuneracao_media) AS sd_wage,
  AVG(quantidade_horas_contratadas) AS avg_hours,
  SUM(CASE WHEN indicador_trabalho_intermitente = '1' THEN 1 ELSE 0 END) AS n_intermittent,
  SUM(CASE WHEN vinculo_ativo_3112 = '1' THEN 1 ELSE 0 END) AS n_active_dec31
FROM `basedosdados.br_me_rais.microdados_vinculos`
WHERE ano BETWEEN 2012 AND 2022
  AND id_municipio IS NOT NULL
  AND valor_remuneracao_media > 0
  AND valor_remuneracao_media < 500000
GROUP BY ano, id_municipio, cnae2
HAVING COUNT(*) >= 5
ORDER BY ano, id_municipio, cnae2
"

rais_result <- bq_project_query(project, query_rais)
rais_dt <- as.data.table(bq_table_download(rais_result, bigint = "integer"))

# Convert columns to standard types
rais_dt[, year := as.integer(year)]
rais_dt[, muni_code := as.character(muni_code)]
rais_dt[, n_workers := as.integer(n_workers)]
rais_dt[, n_intermittent := as.integer(n_intermittent)]
rais_dt[, n_active_dec31 := as.integer(n_active_dec31)]
rais_dt[, avg_wage := as.numeric(avg_wage)]
rais_dt[, sd_wage := as.numeric(sd_wage)]
rais_dt[, avg_hours := as.numeric(avg_hours)]

cat(sprintf("RAIS data: %d rows, %d municipalities, years %d-%d\n",
            nrow(rais_dt), uniqueN(rais_dt$muni_code),
            min(rais_dt$year), max(rais_dt$year)))

if (nrow(rais_dt) < 1000) {
  stop("FATAL: RAIS query returned too few rows. Data fetch failed.")
}

# Step 1b: Compute 2019 sector-level intermittent adoption rates
# (used as the Bartik "shift" component)
cat("Computing sector-level intermittent adoption rates (2019)...\n")

sector_rates <- rais_dt[year == 2019,
  .(total_workers = sum(n_workers),
    total_intermittent = sum(n_intermittent)),
  by = cnae2
]
sector_rates[, intermittent_rate := total_intermittent / total_workers]

cat(sprintf("Sector adoption rates: %d CNAE2 sectors, range %.4f to %.4f\n",
            nrow(sector_rates),
            min(sector_rates$intermittent_rate),
            max(sector_rates$intermittent_rate)))

# Step 1c: Compute pre-reform (2016) municipality employment structure
# (used as Bartik "share" weights)
cat("Computing pre-reform (2016) municipality employment structure...\n")

muni_structure_2016 <- rais_dt[year == 2016,
  .(emp_2016 = sum(n_workers)),
  by = .(muni_code, cnae2)
]
muni_total_2016 <- muni_structure_2016[, .(total_emp_2016 = sum(emp_2016)), by = muni_code]
muni_structure_2016 <- merge(muni_structure_2016, muni_total_2016, by = "muni_code")
muni_structure_2016[, emp_share_2016 := emp_2016 / total_emp_2016]

# Step 1d: Construct municipality-level Bartik exposure
cat("Constructing Bartik exposure measure...\n")

exposure <- merge(muni_structure_2016, sector_rates[, .(cnae2, intermittent_rate)],
                  by = "cnae2", all.x = TRUE)
exposure[is.na(intermittent_rate), intermittent_rate := 0]

muni_exposure <- exposure[,
  .(bartik_exposure = sum(emp_share_2016 * intermittent_rate),
    total_emp_2016 = first(total_emp_2016)),
  by = muni_code
]

cat(sprintf("Municipality exposure: %d municipalities, mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
            nrow(muni_exposure),
            mean(muni_exposure$bartik_exposure),
            sd(muni_exposure$bartik_exposure),
            min(muni_exposure$bartik_exposure),
            max(muni_exposure$bartik_exposure)))

if (nrow(muni_exposure) < 100) {
  stop("FATAL: Too few municipalities with valid exposure. Aborting.")
}

# =============================================================================
# 2. AGGREGATE TO MUNICIPALITY-YEAR PANEL
# =============================================================================
cat("Aggregating to municipality-year panel...\n")

panel <- rais_dt[,
  .(avg_wage = weighted.mean(avg_wage, n_workers),
    sd_wage_across_sectors = sd(avg_wage),
    total_employment = sum(n_workers),
    total_intermittent = sum(n_intermittent),
    total_active_dec31 = sum(n_active_dec31),
    avg_hours = weighted.mean(avg_hours, n_workers),
    n_sectors = .N),
  by = .(muni_code, year)
]
panel[, intermittent_share := total_intermittent / total_employment]
panel[, log_avg_wage := log(avg_wage)]
panel[, log_employment := log(total_employment)]

# Merge exposure
panel <- merge(panel, muni_exposure, by = "muni_code", all.x = TRUE)
panel <- panel[!is.na(bartik_exposure)]

# Create post-reform indicator
panel[, post := as.integer(year >= 2018)]

# Create state code (first 2 digits of municipality code)
panel[, state_code := substr(as.character(muni_code), 1, 2)]

cat(sprintf("Final panel: %d rows, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$muni_code), uniqueN(panel$year)))

# =============================================================================
# 3. SIDRA / PNAD CONTÍNUA SUPPLEMENTARY DATA
# =============================================================================
# State-quarter level formality data from PNAD Contínua (Table 4097)
cat("Fetching PNAD Contínua formality data from SIDRA...\n")

# Table 4097: employed population by formal/informal status
# Variable 4090: employed population
# Classification 12896: position in occupation (formal vs informal)
# Periods: quarterly 2012Q1 - 2023Q4

sidra_url <- paste0(
  "https://apisidra.ibge.gov.br/values/t/4097",
  "/n3/all",                    # All states
  "/v/4090",                    # Employed population (thousands)
  "/p/201201-202304",           # Quarters
  "/c12896/allxt",              # All occupation positions
  "/d/v4090%201"                # One decimal
)

sidra_resp <- tryCatch({
  resp <- GET(sidra_url, timeout(120))
  if (http_error(resp)) {
    warning(sprintf("SIDRA API returned HTTP %d. Proceeding without PNAD data.", status_code(resp)))
    NULL
  } else {
    content(resp, as = "text", encoding = "UTF-8")
  }
}, error = function(e) {
  warning(paste("SIDRA API request failed:", e$message, "Proceeding without PNAD data."))
  NULL
})

if (!is.null(sidra_resp)) {
  sidra_json <- fromJSON(sidra_resp)
  if (is.data.frame(sidra_json) && nrow(sidra_json) > 1) {
    sidra_dt <- as.data.table(sidra_json[-1, ])  # Remove header row
    names(sidra_dt) <- c("nivel_territorial", "cod_territorio", "territorio",
                         "cod_variavel", "variavel",
                         "cod_ano_trimestre", "ano_trimestre",
                         "cod_posicao", "posicao",
                         "unidade_medida", "valor")
    sidra_dt[, valor := as.numeric(gsub("[^0-9.-]", "", valor))]
    sidra_dt <- sidra_dt[!is.na(valor)]
    fwrite(sidra_dt, "../data/pnad_formality.csv")
    cat(sprintf("PNAD data: %d rows saved\n", nrow(sidra_dt)))
  } else {
    cat("SIDRA response not in expected format. Proceeding without PNAD data.\n")
  }
} else {
  cat("Proceeding without PNAD supplementary data (non-essential).\n")
}

# =============================================================================
# 4. SAVE
# =============================================================================
cat("Saving datasets...\n")

fwrite(rais_dt, "../data/rais_muni_cnae2_year.csv")
fwrite(sector_rates, "../data/sector_intermittent_rates.csv")
fwrite(muni_exposure, "../data/muni_exposure.csv")
fwrite(panel, "../data/panel_muni_year.csv")

cat("Data fetch complete.\n")
cat(sprintf("  RAIS raw: %d rows\n", nrow(rais_dt)))
cat(sprintf("  Sector rates: %d CNAE2 sectors\n", nrow(sector_rates)))
cat(sprintf("  Municipality exposure: %d municipalities\n", nrow(muni_exposure)))
cat(sprintf("  Panel: %d municipality-years\n", nrow(panel)))
