## 01_fetch_data.R — Download all data sources
## apep_1222: When the Mine Money Stops

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- 1. SESNSP Municipal Crime Data ----
cat("Downloading SESNSP municipal crime data...\n")
sesnsp_url <- "https://raw.githubusercontent.com/lapanquecita/incidencia-delictiva/main/data/timeseries_municipal.csv"
sesnsp_file <- file.path(data_dir, "sesnsp_municipal.csv")
download.file(sesnsp_url, sesnsp_file, quiet = TRUE)
sesnsp <- fread(sesnsp_file)
cat(sprintf("  SESNSP: %s rows, %d municipalities, years %d-%d\n",
            format(nrow(sesnsp), big.mark = ","),
            length(unique(sesnsp$CVE_MUN)),
            min(sesnsp$AÑO), max(sesnsp$AÑO)))
stopifnot("SESNSP data too small" = nrow(sesnsp) > 100000)

## ---- 2. Fondo Minero PDF ----
cat("Downloading Fondo Minero 2017 distribution PDF from SEDATU...\n")
fm_url <- "https://www.gob.mx/cms/uploads/attachment/file/439047/Distribuci_n_por_Estados_y_Municipios_2017.pdf"
fm_file <- file.path(data_dir, "fondo_minero_2017.pdf")
download.file(fm_url, fm_file, quiet = TRUE, mode = "wb")
stopifnot("Fondo Minero PDF download failed" = file.size(fm_file) > 50000)
cat(sprintf("  Fondo Minero PDF: %s bytes\n", format(file.size(fm_file), big.mark = ",")))

## ---- 3. Municipality Catalogue (INEGI AGEEML via GitHub) ----
cat("Downloading INEGI municipality catalogue...\n")
cat_url <- "https://raw.githubusercontent.com/eduardoarandah/coordenadas-estados-municipios-localidades-de-mexico-json/master/data.csv"
cat_file <- file.path(data_dir, "inegi_catalogue.csv")
download.file(cat_url, cat_file, quiet = TRUE)
catalogue <- fread(cat_file, select = c("CVE_ENT", "NOM_ENT", "CVE_MUN", "NOM_MUN"))
# Aggregate to municipality level (unique combinations)
catalogue <- unique(catalogue)
cat(sprintf("  Catalogue: %d unique municipality records\n", nrow(catalogue)))
stopifnot("Catalogue too small" = nrow(catalogue) > 2000)

## ---- 4. Population Data (INEGI Census 2020 — optional) ----
# Try to get CONAPO population estimates from datos.gob.mx
# If unavailable, we'll use log(count+1) as primary specification
cat("Attempting to download population data...\n")
pop_file <- file.path(data_dir, "population.csv")
pop_available <- FALSE

# CONAPO municipal population projections
tryCatch({
  pop_url <- "https://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2024/pob_mun_mitad.csv"
  download.file(pop_url, pop_file, quiet = TRUE, timeout = 30)
  if (file.size(pop_file) > 10000) {
    pop_available <- TRUE
    cat("  Population data downloaded successfully.\n")
  }
}, error = function(e) {
  message("  Population download failed: ", e$message)
  message("  Will use log(count+1) as primary specification.")
})

if (!pop_available) {
  # Try alternative URL
  tryCatch({
    pop_url2 <- "https://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/Proyecciones2018/pob_mun_mitad_proyecciones.csv"
    download.file(pop_url2, pop_file, quiet = TRUE, timeout = 30)
    if (file.size(pop_file) > 10000) {
      pop_available <- TRUE
      cat("  Population data (2018 projections) downloaded.\n")
    }
  }, error = function(e) {
    message("  Alternative population download also failed.")
    message("  Proceeding without population data — will use log(count+1).")
  })
}

## ---- Save metadata ----
meta <- list(
  sesnsp_url = sesnsp_url,
  fm_url = fm_url,
  catalogue_url = cat_url,
  sesnsp_rows = nrow(sesnsp),
  sesnsp_municipalities = length(unique(sesnsp$CVE_MUN)),
  catalogue_municipalities = nrow(catalogue),
  population_available = pop_available,
  download_date = Sys.time()
)
write_json(meta, file.path(data_dir, "fetch_metadata.json"), auto_unbox = TRUE, pretty = TRUE)
cat("All data downloaded. Metadata saved.\n")
