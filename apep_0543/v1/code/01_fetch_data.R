##============================================================
## 01_fetch_data.R — Fetch DVF property transaction data
## APEP-0543: Rent Control and Property Values in France
##============================================================
## DVF = Demandes de Valeurs Foncières
## Universe of property transactions in metropolitan France
## Available 2020H2–2024 on data.gouv.fr (5-year rolling window)
## Excludes: Alsace (67, 68), Moselle (57), Mayotte (976)
##============================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ─── DVF download URLs from data.gouv.fr ─────────────────
dvf_urls <- list(
  "2020s2" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234831/valeursfoncieres-2020-s2.txt.zip",
  "2021" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234836/valeursfoncieres-2021.txt.zip",
  "2022" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234844/valeursfoncieres-2022.txt.zip",
  "2023" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234851/valeursfoncieres-2023.txt.zip",
  "2024" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234857/valeursfoncieres-2024.txt.zip"
)

for (label in names(dvf_urls)) {
  dest_file <- file.path(data_dir, paste0("dvf_", label, ".txt.zip"))
  if (file.exists(dest_file)) {
    cat("Already downloaded:", dest_file, "\n")
    next
  }
  url <- dvf_urls[[label]]
  cat("Downloading DVF", label, "...\n")
  tryCatch({
    download.file(url, dest_file, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", dest_file, "(", round(file.size(dest_file) / 1e6, 1), "MB)\n")
  }, error = function(e) {
    stop("DVF download failed for ", label, ": ", e$message,
         "\nCannot proceed without real transaction data.")
  })
}

## ─── Parse DVF files ─────────────────────────────────────
## DVF is pipe-delimited (|), French decimal commas
## Multi-row per mutation: land parcels, buildings, lots
## We keep only rows with Type local (building transactions)

cat("\nProcessing DVF files...\n")
all_data <- list()

for (label in names(dvf_urls)) {
  zip_file <- file.path(data_dir, paste0("dvf_", label, ".txt.zip"))
  cat("Processing", label, "... ")

  tmp_dir <- tempdir()
  unzip(zip_file, exdir = tmp_dir, overwrite = TRUE)
  txt_files <- list.files(tmp_dir, pattern = "[.]txt$", full.names = TRUE, recursive = TRUE)
  txt_file <- txt_files[which.max(file.size(txt_files))]

  dt <- fread(txt_file, sep = "|", dec = ",", na.strings = c("", "NA"),
              showProgress = FALSE, encoding = "UTF-8")

  ## Standardize column names
  setnames(dt, names(dt), gsub(" ", "_", tolower(names(dt))))

  ## Build proper 5-digit INSEE commune code
  ## code_departement: integer (e.g., 1, 75, 93)
  ## code_commune: integer (e.g., 367, 101, 47)
  ## INSEE code = sprintf("%02d%03d", dept, commune)
  dt[, code_departement := as.integer(code_departement)]
  dt[, code_commune_raw := as.integer(code_commune)]
  dt[, code_commune := sprintf("%02d%03d", code_departement, code_commune_raw)]

  ## Filter: residential sales with building info
  dt <- dt[
    nature_mutation == "Vente" &
    type_local %in% c("Maison", "Appartement") &
    !is.na(valeur_fonciere) &
    valeur_fonciere > 0 &
    !code_departement %in% c(57L, 67L, 68L)
  ]

  ## Parse date (DD/MM/YYYY format)
  dt[, date_mutation := as.Date(date_mutation, format = "%d/%m/%Y")]
  dt[, year := year(date_mutation)]
  dt[, year_quarter := paste0(year, "Q", quarter(date_mutation))]

  ## Clean numeric fields
  dt[, surface_reelle_bati := as.double(surface_reelle_bati)]
  dt[, nombre_pieces_principales := as.integer(nombre_pieces_principales)]
  dt[, nombre_de_lots := as.integer(nombre_de_lots)]
  dt[, surface_terrain := as.double(surface_terrain)]
  dt[, code_postal := as.integer(code_postal)]

  ## Drop implausible values
  dt <- dt[
    valeur_fonciere >= 10000 &
    valeur_fonciere <= 50000000 &
    (is.na(surface_reelle_bati) | surface_reelle_bati > 5) &
    (is.na(surface_reelle_bati) | surface_reelle_bati < 5000)
  ]

  ## Price per m²
  dt[, price_sqm := fifelse(
    !is.na(surface_reelle_bati) & surface_reelle_bati > 0,
    valeur_fonciere / surface_reelle_bati, NA_real_
  )]
  dt <- dt[is.na(price_sqm) | (price_sqm >= 200 & price_sqm <= 30000)]

  ## Département code as padded string
  dt[, code_dept_str := sprintf("%02d", code_departement)]

  ## Keep needed columns
  keep <- c("date_mutation", "valeur_fonciere", "code_commune",
            "code_dept_str", "code_postal", "type_local",
            "nombre_pieces_principales", "surface_reelle_bati",
            "surface_terrain", "nombre_de_lots",
            "year", "year_quarter", "price_sqm")
  dt <- dt[, ..keep]

  cat(nrow(dt), "transactions\n")
  all_data[[label]] <- dt
  file.remove(txt_file)
}

dvf <- rbindlist(all_data, use.names = TRUE, fill = TRUE)
rm(all_data); gc()

cat("\n=== DVF COMBINED ===\n")
cat("Total transactions:", nrow(dvf), "\n")
cat("Date range:", as.character(min(dvf$date_mutation, na.rm = TRUE)), "to",
    as.character(max(dvf$date_mutation, na.rm = TRUE)), "\n")
cat("Departements:", uniqueN(dvf$code_dept_str), "\n")
cat("Communes:", uniqueN(dvf$code_commune), "\n")
cat("\nSample commune codes:", head(unique(dvf$code_commune), 10), "\n")

## ─── DATA VALIDATION ─────────────────────────────────────
stopifnot("Expected 85+ departements" = uniqueN(dvf$code_dept_str) >= 85)
stopifnot("Expected data from 2020-2024" = all(2020:2024 %in% dvf$year))
stopifnot("Expected 1M+ transactions" = nrow(dvf) > 1000000)
stopifnot("Expected valid prices" = all(dvf$valeur_fonciere > 0))
## Some DOM-TOM have different code formats; check metropolitan France
cat("Commune code lengths:", table(nchar(dvf$code_commune)), "\n")
## Drop any non-5-digit codes (overseas territories)
dvf <- dvf[nchar(code_commune) == 5]

## Check for Paris
paris_n <- sum(grepl("^751", dvf$code_commune))
cat("Paris transactions:", paris_n, "\n")
stopifnot("Expected Paris data" = paris_n > 10000)

cat("Data validation passed:", nrow(dvf), "transactions,",
    uniqueN(dvf$code_dept_str), "departements,",
    uniqueN(dvf$code_commune), "communes,",
    uniqueN(dvf$year), "years\n")

## ─── Save as Parquet ─────────────────────────────────────
parquet_path <- file.path(data_dir, "dvf_residential.parquet")
write_parquet(as.data.frame(dvf), parquet_path)
cat("Saved to:", parquet_path, "(", round(file.size(parquet_path) / 1e6, 1), "MB)\n")

## ─── Summary statistics ─────────────────────────────────
summary_stats <- dvf[, .(
  n_transactions = .N,
  median_price = median(valeur_fonciere),
  mean_price = round(mean(valeur_fonciere)),
  pct_apartments = round(mean(type_local == "Appartement") * 100, 1),
  median_surface = round(median(surface_reelle_bati, na.rm = TRUE), 1),
  median_price_sqm = round(median(price_sqm, na.rm = TRUE))
), by = year]

fwrite(summary_stats, file.path(data_dir, "dvf_summary_by_year.csv"))
cat("\nAnnual summary:\n")
print(summary_stats)

cat("\nDVF data fetch complete.\n")
