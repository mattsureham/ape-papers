# 01_fetch_data.R — Download election and fiscal data
# apep_0613: Female mayors and fiscal composition in Mexico

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ─── 1. Election data from emagar/elecRetrns ─────────────────────────────────
cat("Downloading election data from emagar/elecRetrns...\n")
elec_url <- "https://raw.githubusercontent.com/emagar/elecRetrns/master/data/aymu1989-on.incumbents.csv"
elec_file <- file.path(data_dir, "aymu1989_incumbents.csv")

download.file(elec_url, elec_file, mode = "wb")
stopifnot("Election data download failed" = file.exists(elec_file))

elec_raw <- read.csv(elec_file, stringsAsFactors = FALSE)
cat(sprintf("Election data: %d rows, %d columns\n", nrow(elec_raw), ncol(elec_raw)))
stopifnot("Election data is empty" = nrow(elec_raw) > 1000)

# Check key variables exist
cat("Column names:\n")
cat(paste(names(elec_raw), collapse = ", "), "\n")

# ─── 2. INEGI EFIPEM municipal finance data ──────────────────────────────────
cat("\nDownloading INEGI EFIPEM municipal finance data...\n")
efipem_url <- "https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_municipal_csv.zip"
efipem_zip <- file.path(data_dir, "efipem_municipal_csv.zip")
efipem_dir <- file.path(data_dir, "efipem")

download.file(efipem_url, efipem_zip, mode = "wb")
stopifnot("EFIPEM download failed" = file.exists(efipem_zip))

file_size_mb <- file.info(efipem_zip)$size / 1e6
cat(sprintf("EFIPEM zip file size: %.1f MB\n", file_size_mb))
stopifnot("EFIPEM file too small — likely download error" = file_size_mb > 10)

dir.create(efipem_dir, showWarnings = FALSE)
unzip(efipem_zip, exdir = efipem_dir)

efipem_files <- list.files(efipem_dir, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
cat(sprintf("EFIPEM extracted: %d CSV files\n", length(efipem_files)))
stopifnot("No EFIPEM CSV files found" = length(efipem_files) > 0)

# Preview first file structure
sample_file <- efipem_files[1]
sample_df <- read.csv(sample_file, nrows = 5, stringsAsFactors = FALSE)
cat(sprintf("\nSample file: %s\n", basename(sample_file)))
cat("Columns:\n")
cat(paste(names(sample_df), collapse = ", "), "\n")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Election records: %d\n", nrow(elec_raw)))
cat(sprintf("EFIPEM CSV files: %d\n", length(efipem_files)))
