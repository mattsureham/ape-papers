## 01_fetch_data.R
## apep_1428: Does Financial Parity Follow Legal Parity?
## Fetch and save INE fiscalizacion data for 2018 and 2021 local elections

source("code/00_packages.R")

dir.create("data", showWarnings = FALSE)

## ── INE URLs (confirmed HTTP 200) ──────────────────────────────────────────
URL_2021 <- paste0(
  "https://fiscalizacion.ine.mx/documents/82565/1140143/",
  "PELO_20-21_CAMPA%C3%91A_Y_RUBRO.csv/70d274ec-86db-4c21-a544-b1067d93b4e7"
)

URL_2018 <- paste0(
  "https://fiscalizacion.ine.mx/documents/82565/1140143/",
  "CL2-Anexo-Ingreso-por-Rubro-Campa%C3%B1a-LOCAL_2018_07_17.csv/",
  "b6c96ca2-b745-42af-a769-208ed7c9cf2c"
)

## ── Download 2021 data ─────────────────────────────────────────────────────
cat("Downloading 2021 local election data...\n")
if (!file.exists("data/ine_2021_local.csv")) {
  tryCatch({
    download.file(URL_2021, "data/ine_2021_local.csv", mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("FETCH FAILED for 2021 data. URL: ", URL_2021, "\nError: ", e$message)
  })
} else {
  cat("  Already downloaded: data/ine_2021_local.csv\n")
}

## ── Download 2018 data ─────────────────────────────────────────────────────
cat("Downloading 2018 local election data...\n")
if (!file.exists("data/ine_2018_local.csv")) {
  tryCatch({
    download.file(URL_2018, "data/ine_2018_local.csv", mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("FETCH FAILED for 2018 data. URL: ", URL_2018, "\nError: ", e$message)
  })
} else {
  cat("  Already downloaded: data/ine_2018_local.csv\n")
}

## ── Validation assertions ──────────────────────────────────────────────────
validate_file <- function(path, min_rows, label) {
  stopifnot("File must exist" = file.exists(path))
  df <- read.csv(path, fileEncoding = "latin1", nrows = 5)
  full_count <- system(paste("wc -l <", path), intern = TRUE)
  n_lines <- as.integer(trimws(full_count))
  if (n_lines < min_rows) {
    stop(label, " has only ", n_lines, " lines; expected >= ", min_rows)
  }
  cat("  VALIDATED:", label, "—", n_lines, "rows\n")
}

validate_file("data/ine_2021_local.csv", min_rows = 15000, label = "2021 LOCAL INE")
validate_file("data/ine_2018_local.csv", min_rows = 12000, label = "2018 LOCAL INE")

cat("\nData fetch complete.\n")
