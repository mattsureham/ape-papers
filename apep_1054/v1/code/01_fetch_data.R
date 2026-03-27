## 01_fetch_data.R — Fetch SESNSP crime data and construct panel
## apep_1054: Mexico DST Abolition and Crime
## Data: SESNSP municipality-level monthly crime counts (2015-2025)

source("00_packages.R")

cat("=== Fetching SESNSP Crime Data ===\n")

## ---------------------------------------------------------------
## 1. Download SESNSP municipal crime data
## ---------------------------------------------------------------
## The SESNSP publishes municipal-level crime data as Excel files.
## We try the direct SharePoint download; if blocked, use the datos.gob.mx API.

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

zip_path <- file.path(data_dir, "sesnsp_municipal.zip")
csv_path <- file.path(data_dir, "sesnsp_municipal.csv")
download_success <- FALSE

## Check if data already exists (from a previous run)
existing_csv <- list.files(data_dir, pattern = "Municipal-Delitos.*\\.csv$", full.names = TRUE)
if (length(existing_csv) > 0 && max(file.size(existing_csv)) > 1e6) {
  csv_path <- existing_csv[which.max(file.size(existing_csv))]
  download_success <- TRUE
  cat("Using existing CSV file:", basename(csv_path), "\n")
}

## Alternative: read from individual year XLSX files if CSV is gone
if (!download_success) {
  xlsx_files <- sort(list.files(data_dir, pattern = "^20[0-9]{2}.*\\.xlsx$", full.names = TRUE))
  if (length(xlsx_files) >= 5) {
    cat("Found", length(xlsx_files), "year XLSX files. Reading and combining...\n")
    all_years <- rbindlist(lapply(xlsx_files, function(f) {
      cat("  Reading:", basename(f), "\n")
      as.data.table(read_excel(f))
    }), fill = TRUE)
    csv_path <- file.path(data_dir, "Municipal-Delitos-combined.csv")
    fwrite(all_years, csv_path)
    cat("Combined CSV written:", nrow(all_years), "rows\n")
    download_success <- TRUE
  }
}

if (!download_success) {
## Try downloading from datos abiertos page
## SESNSP publishes CSV/XLSX files — try multiple known URLs
download_success <- FALSE

## Approach 1: Try the datos.gob.mx resource directly
## The SESNSP municipal crime data is also available as CSV from datos.gob.mx
urls_to_try <- c(
  "https://www.gob.mx/cms/uploads/attachment/file/941463/Municipal-Delitos-2015-Dic2024.csv",
  "https://www.gob.mx/cms/uploads/attachment/file/905076/Municipal-Delitos-2015-Dic2023.csv"
)

for (url in urls_to_try) {
  cat("Trying:", url, "\n")
  tryCatch({
    resp <- GET(url, timeout(120), write_disk(csv_path, overwrite = TRUE),
                config(followlocation = TRUE))
    if (status_code(resp) == 200 && file.size(csv_path) > 1e6) {
      cat("  Downloaded successfully:", round(file.size(csv_path) / 1e6, 1), "MB\n")
      download_success <- TRUE
      break
    } else {
      cat("  Response code:", status_code(resp), "- file size:", file.size(csv_path), "\n")
      file.remove(csv_path)
    }
  }, error = function(e) {
    cat("  Error:", conditionMessage(e), "\n")
  })
}

## Approach 2: Try SharePoint link with redirect following
if (!download_success) {
  cat("Trying SharePoint link...\n")
  sp_url <- "https://sspcgob-my.sharepoint.com/:u:/g/personal/cni_sspc_gob_mx/IQDbGHcaTrGrTICk4iIup_aHAUhJ5XgjdiCMEYcXkkZXJiM?download=1"
  tryCatch({
    resp <- GET(sp_url, timeout(180), write_disk(zip_path, overwrite = TRUE),
                config(followlocation = TRUE))
    if (status_code(resp) == 200 && file.size(zip_path) > 1e6) {
      cat("  ZIP downloaded:", round(file.size(zip_path) / 1e6, 1), "MB\n")
      unzip(zip_path, exdir = data_dir)
      ## Find the full CSV inside (prefer the combined CSV over individual year XLSX files)
      extracted <- list.files(data_dir, pattern = "\\.(csv|xlsx)$", recursive = TRUE, full.names = TRUE)
      cat("  Extracted files:", paste(basename(extracted), collapse = ", "), "\n")
      ## Prefer the combined CSV file
      csv_files <- grep("\\.csv$", extracted, value = TRUE)
      if (length(csv_files) > 0) {
        csv_path <- csv_files[which.max(file.size(csv_files))]  # largest CSV
      } else if (length(extracted) > 0) {
        csv_path <- extracted[1]
      }
      if (length(extracted) > 0) {
        download_success <- TRUE
        cat("  Using:", basename(csv_path), "\n")
      }
    }
  }, error = function(e) {
    cat("  SharePoint error:", conditionMessage(e), "\n")
  })
}

## Approach 3: Use datos.gob.mx CKAN API to find the resource
if (!download_success) {
  cat("Trying datos.gob.mx CKAN API...\n")
  ## Search for SESNSP incidencia delictiva municipal dataset
  api_url <- "https://datos.gob.mx/busca/api/3/action/package_search?q=incidencia+delictiva+municipal&rows=5"
  tryCatch({
    resp <- GET(api_url, timeout(30))
    if (status_code(resp) == 200) {
      res <- content(resp, "parsed")
      if (res$result$count > 0) {
        for (pkg in res$result$results) {
          for (resource in pkg$resources) {
            if (grepl("municipal.*delitos|delitos.*municipal", resource$name, ignore.case = TRUE) &&
                grepl("csv|xlsx", resource$format, ignore.case = TRUE)) {
              cat("  Found resource:", resource$name, "\n")
              cat("  URL:", resource$url, "\n")
              resp2 <- GET(resource$url, timeout(180),
                          write_disk(csv_path, overwrite = TRUE),
                          config(followlocation = TRUE))
              if (status_code(resp2) == 200 && file.size(csv_path) > 1e6) {
                download_success <- TRUE
                break
              }
            }
          }
          if (download_success) break
        }
      }
    }
  }, error = function(e) {
    cat("  CKAN API error:", conditionMessage(e), "\n")
  })
}

}  ## end if (!download_success) guard

if (!download_success) {
  stop("FATAL: Could not download SESNSP crime data from any source. Cannot proceed.")
}

## ---------------------------------------------------------------
## 2. Read the crime data
## ---------------------------------------------------------------
cat("\n=== Reading Crime Data ===\n")

if (grepl("\\.xlsx$", csv_path)) {
  raw <- as.data.table(read_excel(csv_path))
} else {
  ## Try reading with different encodings (Latin-1 is common for Mexican data)
  raw <- tryCatch(
    fread(csv_path, encoding = "Latin-1"),
    error = function(e) fread(csv_path, encoding = "UTF-8")
  )
}

cat("Dimensions:", nrow(raw), "x", ncol(raw), "\n")
cat("Columns:", paste(names(raw), collapse = ", "), "\n")

## ---------------------------------------------------------------
## 3. Define the 33 DST-exempt border municipalities
## ---------------------------------------------------------------
## From the 2022 Federal Statute (Ley de los Husos Horarios)
## Article 4: Municipalities in the "franja fronteriza norte"
## Using INEGI municipality codes (2-digit state + 3-digit municipality)

## We focus on 4 split states (have both border and non-border municipalities)
## Baja California (02) is ALL exempt — excluded from main analysis (no within-state variation)
## Sonora (26) is excluded: Sonora was already on permanent standard time (like Arizona)
## before the 2022 reform, so neither border nor non-border municipalities experienced
## a treatment change. Including Sonora adds noise without variation.

border_munis <- data.table(
  cve_ent = c(
    ## Chihuahua (08) — 8 border municipalities
    rep(8, 8),
    ## Coahuila (05) — 7 border municipalities
    rep(5, 7),
    ## Nuevo León (19) — 2 border municipalities
    rep(19, 2),
    ## Tamaulipas (28) — 10 border municipalities
    rep(28, 10)
  ),
  cve_mun = c(
    ## Chihuahua: Ascensión, Janos, Juárez, Guadalupe, Manuel Benavides,
    ##   Ojinaga, Praxedis G. Guerrero, Coyame del Sotol
    4, 35, 37, 28, 45, 52, 55, 17,
    ## Coahuila: Acuña, Guerrero, Hidalgo, Jiménez, Nava,
    ##   Piedras Negras, Ocampo
    2, 12, 14, 15, 22, 25, 23,
    ## Nuevo León: Anáhuac, Colombia
    4, 10,
    ## Tamaulipas: Camargo, Guerrero, Gustavo Díaz Ordaz, Matamoros,
    ##   Mier, Miguel Alemán, Nuevo Laredo, Reynosa, Río Bravo, Valle Hermoso
    6, 14, 15, 22, 24, 25, 27, 32, 33, 40
  ),
  border = 1L
)

## Create unique municipality key matching SESNSP format: cve_ent * 1000 + cve_mun
border_munis[, muni_code := cve_ent * 1000L + cve_mun]

cat("\nBorder municipalities defined:", nrow(border_munis), "\n")
cat("By state:\n")
print(border_munis[, .N, by = cve_ent])

## ---------------------------------------------------------------
## 4. Standardize column names and reshape
## ---------------------------------------------------------------
cat("\n=== Processing Crime Data ===\n")

## SESNSP data typically has columns:
## Año, Clave_Ent, Entidad, Cve. Municipio, Municipio, Bien jurídico afectado,
## Tipo de delito, Subtipo de delito, Modalidad, Enero, Febrero, ..., Diciembre

## Standardize names
old_names <- names(raw)
cat("First 5 column names:", paste(head(old_names, 15), collapse = " | "), "\n")

## Find the year column
year_col <- grep("^A.o$|^Año$|^ano$|^year$", old_names, ignore.case = TRUE, value = TRUE)
if (length(year_col) == 0) year_col <- old_names[1]  # fallback

## Find state and municipality code columns
ent_col <- grep("Clave.*Ent|cve.*ent|Entidad.*clave", old_names, ignore.case = TRUE, value = TRUE)
if (length(ent_col) == 0) ent_col <- old_names[grep("ent", tolower(old_names))[1]]

mun_col <- grep("Cve.*Mun|cve.*mun|Municipio.*clave|Clave.*Mun", old_names, ignore.case = TRUE, value = TRUE)
if (length(mun_col) == 0) mun_col <- old_names[grep("mun", tolower(old_names))[1]]

## Find crime type columns
tipo_col <- grep("Tipo.*delito|tipo_delito", old_names, ignore.case = TRUE, value = TRUE)
subtipo_col <- grep("Subtipo|subtipo", old_names, ignore.case = TRUE, value = TRUE)
bien_col <- grep("Bien.*jur|bien_jur", old_names, ignore.case = TRUE, value = TRUE)

cat("Year col:", year_col, "\n")
cat("State col:", ent_col[1], "\n")
cat("Muni col:", mun_col[1], "\n")
cat("Crime type col:", tipo_col[1], "\n")

## Month columns (Spanish)
month_names_es <- c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                     "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
month_cols <- intersect(old_names, month_names_es)
if (length(month_cols) == 0) {
  ## Try lowercase
  month_cols <- old_names[tolower(old_names) %in% tolower(month_names_es)]
}

cat("Month columns found:", length(month_cols), "\n")

stopifnot("Must find 12 month columns" = length(month_cols) == 12)
stopifnot("Must find year column" = length(year_col) > 0)
stopifnot("Must find state code column" = length(ent_col) > 0)
stopifnot("Must find municipality code column" = length(mun_col) > 0)

## Rename for consistency
setnames(raw, ent_col[1], "cve_ent")
setnames(raw, mun_col[1], "cve_mun")
setnames(raw, year_col[1], "year")
if (length(tipo_col) > 0) setnames(raw, tipo_col[1], "tipo_delito")
if (length(subtipo_col) > 0) setnames(raw, subtipo_col[1], "subtipo_delito")
if (length(bien_col) > 0) setnames(raw, bien_col[1], "bien_juridico")

## Ensure numeric codes
raw[, cve_ent := as.integer(cve_ent)]
raw[, cve_mun := as.integer(cve_mun)]
raw[, year := as.integer(year)]

## Melt from wide (months as columns) to long
id_cols <- c("cve_ent", "cve_mun", "year",
             intersect(c("tipo_delito", "subtipo_delito", "bien_juridico"), names(raw)))
## Also keep entity/municipality names if present
name_cols <- grep("^Entidad$|^Municipio$", names(raw), value = TRUE)
id_cols <- c(id_cols, name_cols)
id_cols <- intersect(id_cols, names(raw))

## Ensure month columns are numeric
for (mc in month_cols) {
  raw[, (mc) := as.numeric(get(mc))]
}

long <- melt(raw, id.vars = id_cols, measure.vars = month_cols,
             variable.name = "month_name", value.name = "crime_count")

## Map month names to numbers
month_map <- setNames(1:12, month_names_es)
## Handle case sensitivity
long[, month := month_map[as.character(month_name)]]
if (any(is.na(long$month))) {
  ## Try matching by position
  month_map2 <- setNames(1:12, month_cols)
  long[is.na(month), month := month_map2[as.character(month_name)]]
}

long[, crime_count := fifelse(is.na(crime_count), 0L, as.integer(crime_count))]

cat("Long format:", nrow(long), "rows\n")

## ---------------------------------------------------------------
## 5. Classify crime types
## ---------------------------------------------------------------
## Create broad crime categories for the analysis
cat("\n=== Classifying Crime Types ===\n")

if ("tipo_delito" %in% names(long)) {
  cat("Unique crime types:", uniqueN(long$tipo_delito), "\n")
  cat("Sample types:", paste(head(unique(long$tipo_delito), 10), collapse = " | "), "\n")

  ## Street crimes (affected by darkness): robberies, assault, kidnapping
  long[, street_crime := as.integer(
    grepl("robo|asalto|lesion|secuestr|homic.*dolos", tipo_delito, ignore.case = TRUE)
  )]

  ## Property crime (robbery subcategories)
  long[, property_crime := as.integer(
    grepl("robo", tipo_delito, ignore.case = TRUE)
  )]

  ## Violent crime
  long[, violent_crime := as.integer(
    grepl("homic|lesion|secuestr|feminic", tipo_delito, ignore.case = TRUE)
  )]

  ## White-collar / non-darkness-related (placebo)
  long[, whitecollar_crime := as.integer(
    grepl("fraude|extorsi|abuso.*confianza|despo|corrupci", tipo_delito, ignore.case = TRUE)
  )]

  cat("Street crime rows:", sum(long$street_crime), "\n")
  cat("White-collar rows:", sum(long$whitecollar_crime), "\n")
}

## ---------------------------------------------------------------
## 6. Aggregate to municipality-month level by crime category
## ---------------------------------------------------------------
cat("\n=== Aggregating to Municipality-Month Panel ===\n")

## Total crime
panel_total <- long[, .(total_crime = sum(crime_count, na.rm = TRUE)),
                     by = .(cve_ent, cve_mun, year, month)]

## Street crime
if ("street_crime" %in% names(long)) {
  panel_street <- long[street_crime == 1,
                        .(street_crime = sum(crime_count, na.rm = TRUE)),
                        by = .(cve_ent, cve_mun, year, month)]

  panel_property <- long[property_crime == 1,
                          .(property_crime = sum(crime_count, na.rm = TRUE)),
                          by = .(cve_ent, cve_mun, year, month)]

  panel_violent <- long[violent_crime == 1,
                         .(violent_crime = sum(crime_count, na.rm = TRUE)),
                         by = .(cve_ent, cve_mun, year, month)]

  panel_wc <- long[whitecollar_crime == 1,
                    .(whitecollar_crime = sum(crime_count, na.rm = TRUE)),
                    by = .(cve_ent, cve_mun, year, month)]

  ## Merge all
  panel <- panel_total
  panel <- merge(panel, panel_street, by = c("cve_ent", "cve_mun", "year", "month"), all.x = TRUE)
  panel <- merge(panel, panel_property, by = c("cve_ent", "cve_mun", "year", "month"), all.x = TRUE)
  panel <- merge(panel, panel_violent, by = c("cve_ent", "cve_mun", "year", "month"), all.x = TRUE)
  panel <- merge(panel, panel_wc, by = c("cve_ent", "cve_mun", "year", "month"), all.x = TRUE)
} else {
  panel <- panel_total
}

## Fill NAs with 0
crime_vars <- c("street_crime", "property_crime", "violent_crime", "whitecollar_crime")
for (v in intersect(crime_vars, names(panel))) {
  panel[is.na(get(v)), (v) := 0L]
}

## The cve_mun in SESNSP is already the composite key (cve_ent * 1000 + local_mun_code)
## Use it directly as municipality ID
panel[, muni_id := cve_mun]

## Create year-month variable
panel[, ym := year * 100 + month]
panel[, date := as.Date(paste(year, month, "01", sep = "-"))]

## ---------------------------------------------------------------
## 7. Merge border status
## ---------------------------------------------------------------
panel[, border := as.integer(muni_id %in% border_munis$muni_code)]

cat("\nBorder status:\n")
print(panel[, .(municipalities = uniqueN(muni_id)), by = border])

## ---------------------------------------------------------------
## 8. Restrict to 5 split states
## ---------------------------------------------------------------
## Chihuahua (08), Coahuila (05), Nuevo León (19), Tamaulipas (28)
## Sonora excluded: already on permanent standard time before 2022
split_states <- c(5, 8, 19, 28)
panel_split <- panel[cve_ent %in% split_states]

cat("\nSplit-state panel:\n")
cat("Municipalities:", uniqueN(panel_split$muni_id), "\n")
cat("  Border:", uniqueN(panel_split[border == 1]$muni_id), "\n")
cat("  Non-border:", uniqueN(panel_split[border == 0]$muni_id), "\n")
cat("Year range:", min(panel_split$year), "-", max(panel_split$year), "\n")
cat("Total obs:", nrow(panel_split), "\n")

## ---------------------------------------------------------------
## 9. Treatment indicators
## ---------------------------------------------------------------
## Reform effective October 30, 2022
## First spring without DST: March 2023
## Treatment = non-border municipality AND after reform

panel_split[, post := as.integer(date >= as.Date("2022-11-01"))]
panel_split[, treated := as.integer(border == 0)]  # non-border = treated (lost DST)
panel_split[, treat_post := treated * post]

## DST-active months: March through October (when DST would normally apply)
## This is when the treatment contrast exists (1 hour difference)
panel_split[, dst_active := as.integer(month >= 3 & month <= 10)]

## Triple interaction: treated × post × DST-active
panel_split[, treat_post_dst := treated * post * dst_active]

## State-year-month FE
panel_split[, state_ym := paste0(cve_ent, "_", ym)]

cat("\nTreatment summary:\n")
print(panel_split[, .(N = .N, mean_total = mean(total_crime)), by = .(treated, post)])

## ---------------------------------------------------------------
## 10. Population data for rates
## ---------------------------------------------------------------
cat("\n=== Fetching Population Data ===\n")

## Use CONAPO municipal population projections
## Available from: https://datos.gob.mx/busca/dataset/proyecciones-de-la-poblacion-de-mexico-y-de-las-entidades-federativas
## For simplicity, use 2020 census population from INEGI API

pop_url <- "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000001/es/0700/false/BISE/2.0/[API_KEY]?type=json"

## Since INEGI API requires a key, use approximate populations from known sources
## We'll use a simpler approach: compute per-municipality crime rates using
## the pre-treatment mean as the normalizing population proxy

## For now, use log(crime + 1) as main outcome and add per-capita rates later
## if population data is available

## Try CONAPO data
pop_success <- FALSE
tryCatch({
  pop_url2 <- "https://datos.gob.mx/busca/api/3/action/package_search?q=proyecciones+poblacion+municipio&rows=5"
  resp <- GET(pop_url2, timeout(30))
  if (status_code(resp) == 200) {
    res <- content(resp, "parsed")
    cat("Population datasets found:", res$result$count, "\n")
    for (pkg in res$result$results) {
      for (resource in pkg$resources) {
        if (grepl("csv|xlsx", resource$format, ignore.case = TRUE)) {
          cat("  Resource:", resource$name, "\n")
        }
      }
    }
  }
}, error = function(e) cat("Population search error:", conditionMessage(e), "\n"))

## Use inverse hyperbolic sine (IHS) transformation as primary outcome
## This handles zeros and approximates log for large values
panel_split[, ihs_total := log(total_crime + sqrt(total_crime^2 + 1))]
panel_split[, ihs_street := log(street_crime + sqrt(street_crime^2 + 1))]
panel_split[, ihs_property := log(property_crime + sqrt(property_crime^2 + 1))]
panel_split[, ihs_violent := log(violent_crime + sqrt(violent_crime^2 + 1))]
panel_split[, ihs_whitecollar := log(whitecollar_crime + sqrt(whitecollar_crime^2 + 1))]

## Also simple log(Y+1)
panel_split[, log_total := log(total_crime + 1)]
panel_split[, log_street := log(street_crime + 1)]
panel_split[, log_property := log(property_crime + 1)]

## ---------------------------------------------------------------
## 11. Save
## ---------------------------------------------------------------
fwrite(panel_split, file.path(data_dir, "panel_split_states.csv"))
fwrite(panel, file.path(data_dir, "panel_all.csv"))

cat("\n=== Data Fetch Complete ===\n")
cat("Split-state panel saved:", nrow(panel_split), "obs\n")
cat("Full panel saved:", nrow(panel), "obs\n")
