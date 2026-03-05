# ==============================================================================
# 01_fetch_data.R — Load pre-downloaded DVF and REI data
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# PART 1A: Commune-level DVF data (2014-2020)
# Source: Caisse des Dépôts via opendata.caissedesdepots.fr (pre-aggregated)
# Downloaded via curl from Opendatasoft export endpoint
# ==============================================================================

cat("=== Loading commune-level DVF (2014-2020) ===\n")

dvf_commune_file <- file.path(data_dir, "dvf_commune_all.csv")
stopifnot("dvf_commune_all.csv must exist" = file.exists(dvf_commune_file))

dvf_commune <- fread(dvf_commune_file, sep = ";", encoding = "UTF-8")
cat("  Commune-level DVF:", nrow(dvf_commune), "rows,", ncol(dvf_commune), "cols\n")
cat("  Columns:", paste(names(dvf_commune), collapse = ", "), "\n")
cat("  Years:", paste(sort(unique(dvf_commune$anneemut)), collapse = ", "), "\n")

# ==============================================================================
# PART 1B: Transaction-level DVF data (2021-2024)
# Source: data.gouv.fr bulk files (pipe-delimited text in zip)
# ==============================================================================

cat("\n=== Loading transaction-level DVF (2021-2024) ===\n")

dvf_dir <- file.path(data_dir, "dvf_raw")
dvf_list <- list()

for (yr in 2021:2024) {
  zipf <- file.path(dvf_dir, paste0("dvf_", yr, ".txt.zip"))
  if (!file.exists(zipf)) stop("DVF zip must exist for ", yr)

  tmpdir <- tempdir()
  unzipped <- unzip(zipf, exdir = tmpdir)
  txt_file <- unzipped[grepl("\\.txt$", unzipped)][1]

  dt <- tryCatch({
    fread(txt_file, sep = "|", encoding = "Latin-1", fill = TRUE,
          select = c("Date mutation", "Nature mutation", "Valeur fonciere",
                      "Code postal", "Code commune", "Code departement",
                      "Type local", "Surface reelle bati",
                      "Nombre pieces principales"))
  }, error = function(e) {
    stop("Failed to read DVF ", yr, ": ", e$message)
  })

  dt[, year := as.integer(yr)]
  dvf_list[[as.character(yr)]] <- dt
  cat("  DVF", yr, ":", nrow(dt), "rows\n")
  file.remove(txt_file)
}

dvf_transactions <- rbindlist(dvf_list, fill = TRUE)
cat("Total transaction-level DVF rows:", nrow(dvf_transactions), "\n")

fwrite(dvf_transactions, file.path(data_dir, "dvf_transactions_2021_2024.csv"))
cat("Saved dvf_transactions_2021_2024.csv\n")

# ==============================================================================
# PART 2: REI — Commune Tax Rates (2014-2024)
# Source: data.economie.gouv.fr REI attachments (extracted via Python)
# Fields: DEP, COM, LIBCOM, H12 (TH rate), E12 (TF bâti rate),
#          H11 (TH base), E11 (TF base), H13 (TH revenue), E13 (TF revenue)
# ==============================================================================

cat("\n=== Loading REI data (2014-2024) ===\n")

rei_file <- file.path(data_dir, "rei_all_years.csv")
stopifnot("rei_all_years.csv must exist" = file.exists(rei_file))

rei_raw <- fread(rei_file)
cat("  REI:", nrow(rei_raw), "rows\n")
cat("  Years:", paste(sort(unique(rei_raw$year)), collapse = ", "), "\n")
cat("  Columns:", paste(names(rei_raw), collapse = ", "), "\n")

# Save as the standardized filename for downstream scripts
fwrite(rei_raw, file.path(data_dir, "rei_commune_rates.csv"))
cat("Saved rei_commune_rates.csv\n")

# ==============================================================================
# DATA VALIDATION
# ==============================================================================

cat("\n=== Data Validation ===\n")

# Commune-level DVF
stopifnot("Commune DVF must have 100K+ rows" = nrow(dvf_commune) > 100000)
n_years_com <- length(unique(dvf_commune$anneemut))
stopifnot("Expected 5+ commune DVF years" = n_years_com >= 5)
cat("  Commune DVF: OK (", nrow(dvf_commune), "rows,", n_years_com, "years)\n")

# Transaction-level DVF
n_years_txn <- dvf_transactions[, uniqueN(year)]
stopifnot("Expected 3+ transaction DVF years" = n_years_txn >= 3)
stopifnot("Expected 1M+ transaction rows" = nrow(dvf_transactions) > 1e6)
cat("  Transaction DVF:", nrow(dvf_transactions), "rows across", n_years_txn, "years\n")

# REI
n_years_rei <- rei_raw[, uniqueN(year)]
stopifnot("Expected 8+ REI years" = n_years_rei >= 8)
stopifnot("Expected 300K+ REI rows" = nrow(rei_raw) > 300000)
cat("  REI:", nrow(rei_raw), "rows across", n_years_rei, "years\n")

cat("\n=== Data loading complete ===\n")
