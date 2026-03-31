## 01_fetch_data.R — Fetch IDEB and MCMV data from official sources
## apep_1214: MCMV Housing and School Quality
## Data: INEP direct downloads + MCMV open data portal

source("00_packages.R")

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  install.packages("openxlsx", repos = "https://cloud.r-project.org")
}
library(openxlsx)

data_dir <- "../data"

# ============================================================
# Step 1: IDEB municipality-level data (2005-2023, biennial)
# ============================================================
cat("=== Step 1: Fetch IDEB municipality-level data ===\n")

# Each 2023 file contains ALL years 2005-2023 in wide format
ideb_urls <- list(
  anos_iniciais = "https://download.inep.gov.br/ideb/resultados/divulgacao_anos_iniciais_municipios_2023.xlsx",
  anos_finais   = "https://download.inep.gov.br/ideb/resultados/divulgacao_anos_finais_municipios_2023.xlsx"
)

ideb_list <- list()

for (stage in names(ideb_urls)) {
  dest_file <- file.path(data_dir, paste0("ideb_", stage, "_mun.xlsx"))
  cat(sprintf("Downloading IDEB %s...\n", stage))

  download.file(ideb_urls[[stage]], destfile = dest_file, mode = "wb", quiet = FALSE)
  if (!file.exists(dest_file) || file.size(dest_file) < 10000) {
    stop(sprintf("IDEB %s download failed", stage))
  }

  # Read xlsx — header starts at row 10, data at row 11
  raw <- read.xlsx(dest_file, sheet = 1, startRow = 10)
  dt <- as.data.table(raw)
  cat(sprintf("  %s: %d rows, %d columns\n", stage, nrow(dt), ncol(dt)))
  cat(sprintf("  Columns: %s\n", paste(head(names(dt), 20), collapse = ", ")))

  ideb_list[[stage]] <- dt
}

# Parse IDEB wide format into long panel
# Column naming pattern: VL_OBSERVADO_YYYY (IDEB score for year YYYY)
parse_ideb_wide <- function(dt, stage_label) {
  # Identify municipality ID and state columns
  id_col <- grep("CO_MUNICIPIO|CO.MUNIC", names(dt), value = TRUE)[1]
  uf_col <- grep("SG_UF|SIGLA", names(dt), value = TRUE)[1]
  name_col <- grep("NO_MUNICIPIO|NOME", names(dt), value = TRUE)[1]
  rede_col <- grep("REDE", names(dt), value = TRUE, ignore.case = TRUE)[1]

  if (is.na(id_col)) {
    cat("Available columns:\n")
    print(names(dt))
    stop("Cannot find municipality ID column")
  }

  # Find IDEB score columns (VL_OBSERVADO_YYYY pattern)
  ideb_cols <- grep("VL_OBSERVADO_\\d{4}", names(dt), value = TRUE)
  if (length(ideb_cols) == 0) {
    # Try alternative pattern
    ideb_cols <- grep("IDEB_\\d{4}|VL_INDICADOR_\\d{4}", names(dt), value = TRUE)
  }

  cat(sprintf("  Found %d IDEB year columns: %s\n", length(ideb_cols),
              paste(ideb_cols, collapse = ", ")))

  if (length(ideb_cols) == 0) {
    cat("All column names:\n")
    print(names(dt))
    stop("Cannot find IDEB year columns")
  }

  # Melt to long format
  keep_cols <- c(id_col, uf_col, name_col, rede_col, ideb_cols)
  keep_cols <- keep_cols[!is.na(keep_cols)]
  dt_sub <- dt[, ..keep_cols]

  long <- melt(dt_sub,
               id.vars = keep_cols[!keep_cols %in% ideb_cols],
               measure.vars = ideb_cols,
               variable.name = "year_col",
               value.name = "ideb")

  # Extract year from column name
  long[, year := as.integer(str_extract(year_col, "\\d{4}"))]
  long[, ideb := as.numeric(ideb)]

  # Rename columns
  setnames(long, id_col, "municipality_id")
  if (!is.na(uf_col)) setnames(long, uf_col, "state")
  if (!is.na(rede_col)) setnames(long, rede_col, "network")

  long[, municipality_id := as.character(municipality_id)]
  long[, stage := stage_label]
  long[, year_col := NULL]

  return(long[!is.na(ideb) & !is.na(year)])
}

ideb_ai <- parse_ideb_wide(ideb_list$anos_iniciais, "anos_iniciais")
ideb_af <- parse_ideb_wide(ideb_list$anos_finais, "anos_finais")
ideb <- rbind(ideb_ai, ideb_af, fill = TRUE)

cat(sprintf("\nIDEB panel: %d rows, %d municipalities, years: %s\n",
            nrow(ideb), uniqueN(ideb$municipality_id),
            paste(sort(unique(ideb$year)), collapse = ", ")))

if (nrow(ideb) < 1000) stop("IDEB parsing failed: too few rows")
fwrite(ideb, file.path(data_dir, "ideb_municipality.csv"))
cat("Saved: data/ideb_municipality.csv\n")

# ============================================================
# Step 2: MCMV project data
# ============================================================
cat("\n=== Step 2: Fetch MCMV project data ===\n")

# Try CKAN API for dadosabertos.cidades.gov.br
cat("Trying CKAN API for MCMV data...\n")

mcmv_fetched <- FALSE

# Approach 1: Direct CSV URL
mcmv_urls_try <- c(
  "https://dadosabertos.cidades.gov.br/dataset/77af53aa-c520-4e31-8161-5a0b2ce6cf62/resource/a82e2a17-9188-490c-bbc2-1fc19867d0c8/download/mcmv_empreendimentos.csv",
  "https://dadosabertos.cidades.gov.br/dataset/77af53aa-c520-4e31-8161-5a0b2ce6cf62/resource/a82e2a17-9188-490c-bbc2-1fc19867d0c8/download",
  "https://dados.gov.br/dados/conjuntos-dados/minha-casa-minha-vida"
)

for (url in mcmv_urls_try) {
  tryCatch({
    cat(sprintf("Trying: %s\n", substr(url, 1, 80)))
    resp <- httr::GET(url, httr::timeout(60),
                      httr::user_agent("APEP Research Project"))
    if (httr::status_code(resp) == 200) {
      content_type <- httr::headers(resp)$`content-type`
      cat(sprintf("  Status 200, Content-Type: %s\n", content_type))

      if (grepl("csv|text|octet", content_type, ignore.case = TRUE)) {
        writeBin(httr::content(resp, "raw"), file.path(data_dir, "mcmv_raw.csv"))
        mcmv <- fread(file.path(data_dir, "mcmv_raw.csv"), encoding = "Latin-1")
        if (nrow(mcmv) > 100) {
          mcmv_fetched <- TRUE
          cat(sprintf("  Success: %d rows\n", nrow(mcmv)))
          break
        }
      }
    }
  }, error = function(e) {
    cat(sprintf("  Failed: %s\n", e$message))
  })
}

# Approach 2: CKAN API discovery
if (!mcmv_fetched) {
  cat("\nTrying CKAN API discovery...\n")
  tryCatch({
    api_url <- "https://dadosabertos.cidades.gov.br/api/3/action/package_show?id=minha-casa-minha-vida"
    resp <- httr::GET(api_url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, "parsed")
      resources <- content$result$resources
      cat(sprintf("Found %d resources\n", length(resources)))
      for (r in resources) {
        if (grepl("csv", tolower(r$format %||% ""))) {
          cat(sprintf("  Downloading: %s\n", r$url))
          download.file(r$url, file.path(data_dir, "mcmv_raw.csv"), mode = "wb")
          mcmv <- fread(file.path(data_dir, "mcmv_raw.csv"), encoding = "Latin-1")
          if (nrow(mcmv) > 100) {
            mcmv_fetched <- TRUE
            break
          }
        }
      }
    }
  }, error = function(e) cat(sprintf("  CKAN failed: %s\n", e$message)))
}

# Approach 3: dados.gov.br API (new portal)
if (!mcmv_fetched) {
  cat("\nTrying dados.gov.br API...\n")
  tryCatch({
    api_url <- "https://dados.gov.br/dados/api/publico/conjuntos-dados?titulo=minha+casa+minha+vida"
    resp <- httr::GET(api_url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, "parsed")
      cat(sprintf("Found %d datasets\n", length(content)))
      # Explore resources
      for (ds in content) {
        cat(sprintf("  Dataset: %s\n", ds$titulo %||% "unknown"))
        if (!is.null(ds$recursos)) {
          for (r in ds$recursos) {
            if (grepl("csv", tolower(r$formato %||% ""))) {
              cat(sprintf("  Downloading: %s\n", r$link %||% r$url))
              dl_url <- r$link %||% r$url
              download.file(dl_url, file.path(data_dir, "mcmv_raw.csv"), mode = "wb")
              mcmv <- fread(file.path(data_dir, "mcmv_raw.csv"), encoding = "Latin-1")
              if (nrow(mcmv) > 100) {
                mcmv_fetched <- TRUE
                break
              }
            }
          }
        }
        if (mcmv_fetched) break
      }
    }
  }, error = function(e) cat(sprintf("  dados.gov.br failed: %s\n", e$message)))
}

# Approach 4: Construct from MCMV PDF/reports data
# The minimum we need: municipality code, delivery year, number of units
# Transparency portal endpoint
if (!mcmv_fetched) {
  cat("\nTrying MCidades transparency portal...\n")
  tryCatch({
    # MCidades open data has moved to selechabita
    portal_url <- "http://sishab.mdr.gov.br/selecao_habitacao/web/empreendimento/filtro"
    resp <- httr::GET(portal_url, httr::timeout(30))
    cat(sprintf("  SISHAB status: %d\n", httr::status_code(resp)))
  }, error = function(e) cat(sprintf("  SISHAB failed: %s\n", e$message)))
}

# Approach 5: Build MCMV treatment from available secondary sources
# Many researchers use the Caixa Econômica Federal data or
# construct treatment from Transparência Caixa
if (!mcmv_fetched) {
  cat("\nTrying Transparência Caixa for MCMV data...\n")
  tryCatch({
    caixa_url <- "https://www.caixa.gov.br/Downloads/minha-casa-minha-vida/MCMV_Contratos.csv"
    resp <- httr::GET(caixa_url, httr::timeout(60),
                      httr::user_agent("Mozilla/5.0 (Macintosh)"))
    cat(sprintf("  Caixa status: %d\n", httr::status_code(resp)))
    if (httr::status_code(resp) == 200) {
      writeBin(httr::content(resp, "raw"), file.path(data_dir, "mcmv_raw.csv"))
      mcmv <- fread(file.path(data_dir, "mcmv_raw.csv"), encoding = "Latin-1")
      mcmv_fetched <- nrow(mcmv) > 100
    }
  }, error = function(e) cat(sprintf("  Caixa failed: %s\n", e$message)))
}

if (!mcmv_fetched) {
  stop("FATAL: All MCMV data sources failed. Cannot proceed without real MCMV data.")
}

cat(sprintf("\nMCMV data: %d rows\n", nrow(mcmv)))
cat("Column names:\n")
print(names(mcmv))
cat("\nSample:\n")
print(head(mcmv, 3))

fwrite(mcmv, file.path(data_dir, "mcmv_raw.csv"))
cat("\nAll data fetched successfully.\n")
