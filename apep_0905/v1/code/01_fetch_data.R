## 01_fetch_data.R — Download ANAC aviation microdata
## apep_0905: Argentina Aviation Deregulation

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Download main microdata ----
micro_url <- "https://datos.yvera.gob.ar/dataset/c0e7bc3d-553c-405c-8b32-79282b28ffd5/resource/aab49234-28c9-48ab-a978-a83485139290/download/base_microdatos.csv"
micro_file <- file.path(data_dir, "base_microdatos.csv")

if (!file.exists(micro_file)) {
  cat("Downloading ANAC microdata (~253 MB)...\n")
  download.file(micro_url, micro_file, mode = "wb", quiet = FALSE)
  stopifnot("Download failed: microdata file missing" = file.exists(micro_file))
  cat("Download complete:", file.size(micro_file), "bytes\n")
} else {
  cat("Microdata already exists:", file.size(micro_file), "bytes\n")
}

## ---- Airport reference (skip if unavailable) ----
# Geographic info available in main data via province/city columns

## ---- Read and validate microdata ----
cat("Reading microdata...\n")
raw <- fread(micro_file, encoding = "UTF-8")

cat("Rows:", nrow(raw), "\n")
cat("Columns:", ncol(raw), "\n")
cat("Column names:", paste(names(raw), collapse = ", "), "\n")
cat("Date range:", as.character(range(raw$indice_tiempo)), "\n")

# Filter to domestic regular flights only
domestic <- raw[clasificacion_vuelo == "Cabotaje" & clase_vuelo == "Regular"]
cat("Domestic regular flights:", nrow(domestic), "\n")

stopifnot("No domestic flights found" = nrow(domestic) > 0)
stopifnot("Expected columns missing" = all(c("pasajeros", "asientos", "vuelos") %in% names(domestic)))

## ---- Validate key variables ----
cat("\nAirline distribution (top 10):\n")
print(domestic[, .(total_pax = sum(pasajeros, na.rm = TRUE)), by = aerolinea][order(-total_pax)][1:10])

cat("\nYear distribution:\n")
domestic[, year := year(indice_tiempo)]
print(domestic[, .(rows = .N, total_pax = sum(pasajeros, na.rm = TRUE)), by = year][order(year)])

## ---- Save cleaned domestic data ----
fwrite(domestic, file.path(data_dir, "domestic_flights.csv"))
cat("\nSaved domestic_flights.csv:", nrow(domestic), "rows\n")

## ---- Extract airport reference from main data ----
airports <- unique(rbind(
  domestic[, .(oaci = origen_oaci, airport = origen_aeropuerto,
               city = origen_localidad, province = origen_provincia)],
  domestic[, .(oaci = destino_oaci, airport = destino_aeropuerto,
               city = destino_localidad, province = destino_provincia)]
))
airports <- unique(airports, by = "oaci")
cat("\nUnique domestic airports:", nrow(airports), "\n")
fwrite(airports, file.path(data_dir, "airports_clean.csv"))

cat("\n01_fetch_data.R complete.\n")
