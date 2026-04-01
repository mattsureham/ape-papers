## 01_fetch_data.R — Fetch INE BPIHE and Eurostat HPI data
## apep_1254: Portugal Golden Visa Geographic Restriction

source("00_packages.R")

cat("=== Fetching INE BPIHE data (monthly bank appraisal values by NUTS3) ===\n")

# INE Portugal JSON API for indicator 0012248
# Median bank appraisal value (EUR/m2) by NUTS3, monthly
BASE_URL <- "https://www.ine.pt/ine/json_indicador/pindica.jsp"

# NUTS3 region codes (2013 NUTS revision)
nuts3_codes <- c(
  "111",  # Alto Minho
  "112",  # Cávado
  "119",  # Ave
  "11A",  # Área Metropolitana do Porto
  "11B",  # Alto Tâmega e Barroso (added 2024 — was part of Alto Trás-os-Montes)
  "11C",  # Tâmega e Sousa
  "11D",  # Douro
  "11E",  # Terras de Trás-os-Montes
  "150",  # Algarve
  "16I",  # Região de Aveiro
  "16J",  # Região de Coimbra
  "16B",  # Região de Leiria
  "16D",  # Viseu Dão Lafões
  "16E",  # Beira Baixa
  "16F",  # Beiras e Serra da Estrela
  "170",  # Área Metropolitana de Lisboa (Grande Lisboa + Setúbal — if reported together)
  "1A0",  # Grande Lisboa (if separate)
  "1B0",  # Península de Setúbal (if separate)
  "181",  # Alentejo Litoral
  "182",  # Baixo Alentejo
  "183",  # Lezíria do Tejo
  "184",  # Alto Alentejo
  "185",  # Alentejo Central
  "1D1",  # Oeste
  "1D2",  # Médio Tejo
  "200",  # Região Autónoma dos Açores
  "300"   # Região Autónoma da Madeira
)

# Time periods: Jan 2015 to Dec 2024 (monthly)
# INE format: S3A{YYYYMM}
months_seq <- seq(as.Date("2015-01-01"), as.Date("2024-12-01"), by = "month")
time_codes <- paste0("S3A", format(months_seq, "%Y%m"))

cat(sprintf("Fetching %d months × %d regions...\n", length(time_codes), length(nuts3_codes)))

# Fetch data iterating over months (INE returns all regions per request)
all_data <- list()
errors <- character()

for (i in seq_along(time_codes)) {
  tc <- time_codes[i]
  url <- paste0(BASE_URL, "?op=2&varcd=0012248&Dim1=", tc, "&lang=EN")

  res <- tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("HTTP %d for %s", httr::status_code(resp), tc))
    }
    content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content_text, simplifyVector = FALSE)
    parsed
  }, error = function(e) {
    errors <<- c(errors, sprintf("%s: %s", tc, e$message))
    NULL
  })

  if (is.null(res)) next

  # Parse the nested JSON structure
  # Structure: list with Dados -> period -> array of {geocod, geodsg, dim_3, dim_3_t, valor}
  dados <- res[[1]]$Dados
  if (is.null(dados)) next

  for (period_key in names(dados)) {
    records <- dados[[period_key]]
    for (rec in records) {
      geocod <- rec$geocod
      geodsg <- rec$geodsg
      valor <- rec$valor
      dim3 <- rec$dim_3_t  # category (e.g., "Total", "Apartments", "Houses")

      if (!is.null(valor) && !is.na(valor) && !is.null(geocod)) {
        all_data[[length(all_data) + 1]] <- data.frame(
          time_code = tc,
          period_key = period_key,
          geocod = as.character(geocod),
          geodsg = as.character(geodsg),
          category = as.character(dim3 %||% "Total"),
          value = as.numeric(valor),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (i %% 12 == 0) {
    cat(sprintf("  Fetched %d/%d months...\n", i, length(time_codes)))
  }
  Sys.sleep(0.3)  # Rate limiting
}

if (length(all_data) == 0) {
  stop("FATAL: No data retrieved from INE API. Cannot proceed with simulated data.")
}

df_ine <- bind_rows(all_data)
cat(sprintf("Retrieved %d records from INE API.\n", nrow(df_ine)))

if (length(errors) > 0) {
  cat(sprintf("WARNING: %d fetch errors:\n", length(errors)))
  cat(paste("  ", head(errors, 5), collapse = "\n"), "\n")
}

# Parse dates from time_code
df_ine <- df_ine %>%
  mutate(
    year = as.integer(substr(time_code, 4, 7)),
    month = as.integer(substr(time_code, 8, 9)),
    date = as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))
  )

# Save raw INE data
write_csv(df_ine, "../data/ine_bpihe_raw.csv")
cat(sprintf("Saved INE data: %d rows, %d unique regions, %d months\n",
            nrow(df_ine), n_distinct(df_ine$geocod), n_distinct(df_ine$date)))

# === Fetch Eurostat HPI (quarterly, national) ===
cat("\n=== Fetching Eurostat HPI data ===\n")

eurostat_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hpi_q",
  "?format=JSON&geo=PT&geo=ES&geo=IT&geo=NL&geo=IE",
  "&unit=I15_Q&purchase=TOTAL"
)

resp_eu <- httr::GET(eurostat_url, httr::timeout(60))
if (httr::status_code(resp_eu) != 200) {
  stop(sprintf("FATAL: Eurostat API returned HTTP %d", httr::status_code(resp_eu)))
}

eu_json <- jsonlite::fromJSON(httr::content(resp_eu, as = "text", encoding = "UTF-8"))

# Parse Eurostat JSON-stat format
eu_values <- eu_json$value
eu_dims <- eu_json$dimension
geo_labels <- eu_dims$geo$category$label
time_labels <- eu_dims$time$category$label
geo_idx <- eu_dims$geo$category$index
time_idx <- eu_dims$time$category$index

n_geo <- length(geo_labels)
n_time <- length(time_labels)

eu_records <- list()
for (g_name in names(geo_idx)) {
  for (t_name in names(time_idx)) {
    flat_idx <- as.character(geo_idx[[g_name]] * n_time + time_idx[[t_name]])
    val <- eu_values[[flat_idx]]
    if (!is.null(val)) {
      eu_records[[length(eu_records) + 1]] <- data.frame(
        geo = g_name,
        geo_label = geo_labels[[g_name]],
        time = t_name,
        hpi = as.numeric(val),
        stringsAsFactors = FALSE
      )
    }
  }
}

df_eurostat <- bind_rows(eu_records)
cat(sprintf("Retrieved %d Eurostat HPI records.\n", nrow(df_eurostat)))

write_csv(df_eurostat, "../data/eurostat_hpi_raw.csv")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("INE BPIHE: %d records\n", nrow(df_ine)))
cat(sprintf("Eurostat HPI: %d records\n", nrow(df_eurostat)))
