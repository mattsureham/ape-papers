## 01_fetch_data.R — Download ENVIPE microdata and SESNSP victim data
## APEP Paper: Mexico's Sorteo Militar and Youth Crime
##
## Data sources:
##   1. ENVIPE microdata (2021-2024): Individual-level victimization with
##      exact age, sex, state — PRIMARY
##   2. SESNSP Victimas (2015-2024): State-level victim counts by sex,
##      broad age group, crime type, month — SUPPLEMENTARY

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. ENVIPE Victimization Survey Microdata (PRIMARY)
# ============================================================
cat("=== Downloading ENVIPE microdata ===\n")

envipe_dir <- file.path(data_dir, "envipe")
dir.create(envipe_dir, showWarnings = FALSE)

envipe_years <- 2021:2024

for (yr in envipe_years) {
  yr_dir <- file.path(envipe_dir, as.character(yr))

  # Check if already extracted
  existing <- list.files(yr_dir, pattern = "\\.csv$|\\.CSV$",
                         recursive = TRUE, ignore.case = TRUE)
  if (length(existing) > 0) {
    cat("ENVIPE", yr, "already extracted:", length(existing), "CSV files\n")
    next
  }

  url <- paste0(
    "https://www.inegi.org.mx/contenidos/programas/envipe/",
    yr, "/datosabiertos/conjunto_de_datos_envipe_", yr, "_csv.zip"
  )

  zip_file <- file.path(envipe_dir, paste0("envipe_", yr, ".zip"))
  cat("Downloading ENVIPE", yr, "... ")

  resp <- tryCatch(
    GET(url, write_disk(zip_file, overwrite = TRUE),
        timeout(600), progress()),
    error = function(e) {
      cat("ERROR:", conditionMessage(e), "\n")
      NULL
    }
  )

  if (is.null(resp) || resp$status_code != 200) {
    stop("FATAL: Cannot download ENVIPE ", yr,
         ". HTTP status: ", if (!is.null(resp)) resp$status_code else "connection failed",
         "\nReal data required — cannot proceed.")
  }

  fsize <- file.size(zip_file)
  cat(round(fsize / 1e6, 1), "MB\n")

  if (fsize < 500000) {
    stop("FATAL: Downloaded file for ENVIPE ", yr, " is suspiciously small (",
         fsize, " bytes). Likely not real data.")
  }

  # Extract
  cat("  Extracting... ")
  dir.create(yr_dir, showWarnings = FALSE)
  tryCatch({
    unzip(zip_file, exdir = yr_dir, junkpaths = FALSE)
    extracted <- list.files(yr_dir, recursive = TRUE, pattern = "\\.csv$|\\.CSV$",
                            ignore.case = TRUE)
    cat("done (", length(extracted), "CSV files)\n")
  }, error = function(e) {
    stop("FATAL: Cannot extract ENVIPE ZIP for ", yr, ": ", conditionMessage(e))
  })

  # Clean up ZIP
  file.remove(zip_file)
}

# Validate
for (yr in envipe_years) {
  yr_dir <- file.path(envipe_dir, as.character(yr))
  csvs <- list.files(yr_dir, pattern = "\\.csv$|\\.CSV$",
                     recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (length(csvs) == 0) {
    stop("FATAL: No CSV files found for ENVIPE ", yr)
  }
  cat("ENVIPE", yr, ":", length(csvs), "files,",
      round(sum(file.size(csvs)) / 1e6, 1), "MB total\n")
}

# ============================================================
# 2. SESNSP Victim Data (SUPPLEMENTARY)
# ============================================================
cat("\n=== Downloading SESNSP victim data ===\n")

sesnsp_file <- file.path(data_dir, "sesnsp_victimas.csv")

if (!file.exists(sesnsp_file)) {
  sesnsp_url <- "https://raw.githubusercontent.com/lapanquecita/incidencia-delictiva/main/data/victimas.csv"
  cat("Downloading SESNSP victim data...\n")
  resp <- GET(sesnsp_url, write_disk(sesnsp_file, overwrite = TRUE),
              timeout(120), progress())

  if (resp$status_code != 200) {
    cat("WARNING: Could not download SESNSP victim data.\n")
  } else {
    fsize <- file.size(sesnsp_file)
    first_line <- readLines(sesnsp_file, n = 1)
    if (grepl("<html|<!DOCTYPE", first_line, ignore.case = TRUE)) {
      file.remove(sesnsp_file)
      stop("FATAL: SESNSP download returned HTML, not data.")
    }
    cat("Downloaded:", round(fsize / 1e6, 1), "MB\n")
  }
} else {
  cat("SESNSP data already exists:", round(file.size(sesnsp_file) / 1e6, 1), "MB\n")
}

# ============================================================
# 3. Summary
# ============================================================
cat("\n=== Data Download Summary ===\n")
all_files <- list.files(data_dir, recursive = TRUE, full.names = TRUE,
                        pattern = "\\.csv$|\\.CSV$", ignore.case = TRUE)
total_size <- sum(file.size(all_files))
cat("Total CSV files:", length(all_files), "\n")
cat("Total size:", round(total_size / 1e6, 1), "MB\n")

cat("\nData fetch complete.\n")
