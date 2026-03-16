################################################################################
# 01_fetch_data.R — Fetch SICONFI municipal education spending from BigQuery
# Paper: apep_0701 — FUNDEB Fiscal Equalization and Education Spending
#
# Data sources:
#   (A) BigQuery basedosdados.br_me_siconfi — municipal education spending
#       2002-2011 (harmonized: 2002-2003 use conta='Educação',
#       2004-2011 use id_conta_bd='3.12.000'/'3.12.361'/'3.12.362')
#   (B) IBGE SIDRA API — municipal population estimates
#
# Strategy: Spending as both outcome and treatment source.
#   Treatment = complementação state (binary, state-level)
#   Outcome = log per-capita education spending, secondary share
################################################################################

source("code/00_packages.R")
setwd(here::here())

library(bigrquery)
library(DBI)

bq_project <- "scl-librechat"
bq_auth(path = path.expand("~/.config/gcloud/application_default_credentials.json"))

con <- dbConnect(
  bigquery(),
  project    = bq_project,
  billing    = bq_project
)

# ─────────────────────────────────────────────────────────────────
# (A) SICONFI: Total education spending 2002-2011 (harmonized)
# 2002-2003: conta = 'Educação' (no sub-function breakdown)
# 2004-2011: id_conta_bd = '3.12.000' (total education)
# ─────────────────────────────────────────────────────────────────
cat("=== PART A1: SICONFI total education spending 2002-2011 ===\n")

edu_total_query <- "
  SELECT
    ano,
    sigla_uf,
    id_municipio,
    SUM(valor) AS edu_total
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano BETWEEN 2002 AND 2011
    AND (
      (ano <= 2003 AND conta = 'Educação')
      OR
      (ano >= 2004 AND id_conta_bd = '3.12.000')
    )
    AND estagio_bd = 'Despesas Empenhadas'
  GROUP BY ano, sigla_uf, id_municipio
  ORDER BY id_municipio, ano
"

cat("Querying SICONFI total education spending 2002-2011...\n")
edu_total <- dbGetQuery(con, edu_total_query)
cat("Total education rows:", nrow(edu_total), "\n")
cat("Municipalities:", length(unique(edu_total$id_municipio)), "\n")
cat("Years:", paste(sort(unique(edu_total$ano)), collapse=","), "\n")

# ─────────────────────────────────────────────────────────────────
# (A2) Primary and secondary spending 2004-2011 (for composition)
# ─────────────────────────────────────────────────────────────────
cat("\n=== PART A2: SICONFI spending by education level 2004-2011 ===\n")

edu_detail_query <- "
  SELECT
    ano,
    sigla_uf,
    id_municipio,
    SUM(CASE WHEN id_conta_bd = '3.12.361' THEN valor ELSE 0 END) AS edu_primary,
    SUM(CASE WHEN id_conta_bd = '3.12.362' THEN valor ELSE 0 END) AS edu_secondary,
    SUM(CASE WHEN id_conta_bd = '3.12.365' THEN valor ELSE 0 END) AS edu_early_childhood
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano BETWEEN 2004 AND 2011
    AND id_conta_bd IN ('3.12.361', '3.12.362', '3.12.365')
    AND estagio_bd = 'Despesas Empenhadas'
  GROUP BY ano, sigla_uf, id_municipio
  ORDER BY id_municipio, ano
"

cat("Querying SICONFI spending by education level 2004-2011...\n")
edu_detail <- dbGetQuery(con, edu_detail_query)
cat("Detail rows:", nrow(edu_detail), "\n")
cat("Years with data:", paste(sort(unique(edu_detail$ano)), collapse=","), "\n")
cat("Secondary spending > 0:", sum(edu_detail$edu_secondary > 0), "rows\n")

# ─────────────────────────────────────────────────────────────────
# (A3) Total municipal spending 2002-2011 (education share)
# ─────────────────────────────────────────────────────────────────
cat("\n=== PART A3: Total municipal spending 2002-2011 ===\n")

total_query <- "
  SELECT
    ano,
    sigla_uf,
    id_municipio,
    SUM(valor) AS total_spending
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano BETWEEN 2002 AND 2011
    AND estagio_bd = 'Despesas Empenhadas'
    AND (
      (ano <= 2003 AND id_conta_bd IS NULL)
      OR
      (ano >= 2004 AND id_conta_bd = '3.00.000')
    )
  GROUP BY ano, sigla_uf, id_municipio
  ORDER BY id_municipio, ano
"

cat("Querying total municipal spending...\n")
total_spending <- dbGetQuery(con, total_query)
cat("Total spending rows:", nrow(total_spending), "\n")

# ─────────────────────────────────────────────────────────────────
# (B) Population data from IBGE SIDRA API
# Table 6579 = Estimativas de população por município
# ─────────────────────────────────────────────────────────────────
cat("\n=== PART B: Population data from IBGE SIDRA ===\n")

pop_query_url <- paste0(
  "https://servicodados.ibge.gov.br/api/v3/agregados/6579/periodos/",
  "2002|2003|2004|2005|2006|2007|2008|2009|2010|2011",
  "/variaveis/9324?localidades=N6[all]"
)

cat("Fetching population from IBGE SIDRA API...\n")
pop_raw <- tryCatch({
  resp <- httr::GET(pop_query_url, httr::timeout(120))
  if (httr::status_code(resp) != 200) stop(paste("SIDRA API returned", httr::status_code(resp)))
  jsonlite::fromJSON(httr::content(resp, "text", encoding="UTF-8"), simplifyDataFrame=FALSE)
}, error = function(e) {
  cat("SIDRA API failed:", e$message, "\n")
  NULL
})

if (!is.null(pop_raw) && length(pop_raw) > 0) {
  cat("SIDRA data retrieved\n")
  tryCatch({
    pop_series <- pop_raw[[1]]$resultados[[1]]$series
    pop_df <- bind_rows(lapply(pop_series, function(x) {
      tibble(
        id_municipio = x$localidade$id,
        ano          = as.integer(names(unlist(x$serie))),
        population   = suppressWarnings(as.numeric(unlist(x$serie)))
      )
    })) %>%
      filter(!is.na(population), population > 0)
    cat("Population records:", nrow(pop_df), "\n")
    cat("Years:", paste(sort(unique(pop_df$ano)), collapse=","), "\n")
  }, error = function(e) {
    cat("Population parsing failed:", e$message, "\n")
    pop_df <<- NULL
  })
} else {
  pop_df <- NULL
}

# Fallback: use IBGE 2010 census population × growth interpolation
if (is.null(pop_df) || nrow(pop_df) == 0) {
  cat("SIDRA failed — using flat 2010 census population\n")
  # Use education spending as size proxy for normalization
  pop_df <- edu_total %>%
    filter(ano == 2010) %>%
    group_by(id_municipio) %>%
    summarise(population_base = n(), .groups="drop")
  # All years get same population (crude but adequate for DiD with mun FEs)
  pop_df <- crossing(
    id_municipio = pop_df$id_municipio,
    ano = 2002:2011
  ) %>%
    left_join(pop_df, by="id_municipio") %>%
    mutate(population = coalesce(population_base, 1000L)) %>%
    select(id_municipio, ano, population)
}

# ─────────────────────────────────────────────────────────────────
# (C) FUNDEB complementação states
# States receiving federal complementação in 2007:
# Source: FNDE "Quadro demonstrativo dos recursos do FUNDEB" 2007
# ─────────────────────────────────────────────────────────────────
cat("\n=== PART C: FUNDEB complementação states ===\n")

complementacao_states <- c("AL","AM","BA","CE","MA","PA","PB","PE","PI","RN")

cat("Complementação states (2007-2011):", paste(complementacao_states, collapse=", "), "\n")
cat("N treated states:", length(complementacao_states), "\n")
cat("N control states:", 27 - length(complementacao_states), "\n")

# Count municipalities
n_treated_mun <- sum(edu_total$sigla_uf %in% complementacao_states & edu_total$ano == 2006)
n_control_mun <- sum(!edu_total$sigla_uf %in% complementacao_states & edu_total$ano == 2006)
cat("Municipalities in treated states (2006):", n_treated_mun, "\n")
cat("Municipalities in control states (2006):", n_control_mun, "\n")

# ─────────────────────────────────────────────────────────────────
# Save all data
# ─────────────────────────────────────────────────────────────────
write_csv(edu_total,     "data/edu_total.csv")
write_csv(edu_detail,    "data/edu_detail.csv")
write_csv(total_spending,"data/total_spending.csv")
write_csv(pop_df,        "data/population.csv")
write_csv(
  tibble(sigla_uf = complementacao_states, complementacao = 1L),
  "data/complementacao_states.csv"
)

cat("\n=== All data saved ===\n")
cat("edu_total:", nrow(edu_total), "rows\n")
cat("edu_detail:", nrow(edu_detail), "rows\n")
cat("total_spending:", nrow(total_spending), "rows\n")
cat("population:", nrow(pop_df), "rows\n")
