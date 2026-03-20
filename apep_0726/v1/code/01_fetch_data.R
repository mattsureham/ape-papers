# =============================================================================
# 01_fetch_data.R — Fetch data (slim version: 5 years SIM, skip SINAN)
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

source("code/00_packages.R")

cat("=== FETCHING DATA (SLIM VERSION) ===\n")

# ---- 1. FPM THRESHOLDS (from law) ----
fpm_thresholds <- tibble(
  threshold_id = 1:17,
  pop_lower = c(0, 10189, 13585, 16981, 23773, 30565, 37357, 44149,
                50941, 61329, 71717, 82105, 92493, 115617, 138741,
                161865, 188987),
  coef_fpm = c(0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4,
               2.6, 2.8, 3.0, 3.2, 3.4, 3.6, 3.8)
)
saveRDS(fpm_thresholds, "data/fpm_thresholds.rds")

# ---- 2. IBGE POPULATION (check if already saved) ----
if (file.exists("data/ibge_population.rds")) {
  pop_df <- readRDS("data/ibge_population.rds")
  cat(sprintf("Loaded cached population data: %d records\n", nrow(pop_df)))
} else {
  cat("Fetching IBGE population...\n")
  pop_list <- list()
  for (yr in 2014:2021) {
    url <- sprintf(
      "https://servicodados.ibge.gov.br/api/v3/agregados/6579/periodos/%d/variaveis/9324?localidades=N6[all]",
      yr
    )
    resp <- tryCatch(httr::GET(url, httr::timeout(60)), error = function(e) NULL)
    if (is.null(resp) || httr::status_code(resp) != 200) next
    json <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(json, flatten = TRUE)
    if (!is.data.frame(parsed)) next
    series <- parsed$resultados[[1]]$series[[1]]
    val_col <- paste0("serie.", yr)
    if (!val_col %in% names(series)) next
    pop_list[[as.character(yr)]] <- tibble(
      mun_code = substr(series$localidade.id, 1, 6),
      mun_name = series$localidade.nome,
      year = yr,
      population = as.numeric(series[[val_col]])
    )
    cat(sprintf("  %d: %d municipalities\n", yr, nrow(pop_list[[as.character(yr)]])))
    Sys.sleep(0.3)
  }
  pop_df <- bind_rows(pop_list) %>% filter(!is.na(population), population > 0)
  saveRDS(pop_df, "data/ibge_population.rds")
}
stopifnot("No population data" = nrow(pop_df) > 0)

# ---- 3. SIM MORTALITY (5 years only: 2015-2019) ----
if (file.exists("data/sim_mortality.rds") && file.size("data/sim_mortality.rds") > 1e6) {
  sim_df <- readRDS("data/sim_mortality.rds")
  cat(sprintf("Loaded cached SIM data: %d records\n", nrow(sim_df)))
} else {
  cat("Fetching SIM mortality (2015-2019)...\n")
  mort_list <- list()
  for (yr in 2015:2019) {
    cat(sprintf("  SIM %d...\n", yr))
    df_yr <- tryCatch({
      fetch_datasus(
        year_start = yr, year_end = yr, uf = "all",
        information_system = "SIM-DO",
        timeout = 600
      )
    }, error = function(e) {
      cat(sprintf("  SIM %d failed: %s\n", yr, e$message))
      NULL
    })
    if (!is.null(df_yr) && nrow(df_yr) > 0) {
      df_yr$year <- yr
      mort_list[[as.character(yr)]] <- df_yr
      cat(sprintf("  SIM %d: %d records\n", yr, nrow(df_yr)))
    }
    Sys.sleep(1)
  }
  if (length(mort_list) == 0) stop("FATAL: No SIM data")
  sim_df <- bind_rows(mort_list)
  saveRDS(sim_df, "data/sim_mortality.rds")
}
cat(sprintf("SIM records: %d\n", nrow(sim_df)))

# ---- 4. SKIP SINAN (use SIM homicide as primary) ----
saveRDS(tibble(), "data/sinan_violence.rds")

# ---- 5. SKIP FPM TRANSFERS (construct from coefficients) ----
saveRDS(list(), "data/fpm_transfers_raw.rds")

# ---- 6. SKIP CEMPRE (mechanism evidence from literature) ----
saveRDS(list(), "data/employment_raw.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Population: %d records\n", nrow(pop_df)))
cat(sprintf("SIM: %d records\n", nrow(sim_df)))
