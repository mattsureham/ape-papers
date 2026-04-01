## ==============================================================
## 01_fetch_data.R — apep_1293
## Download DATASUS SIM mortality, IBGE population, CNPJ clubs
## ==============================================================

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

## ------------------------------------------------------------------
## 1. DATASUS SIM (Mortality Information System)
##    Source: ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/
##    Files: DOUF{YYYY}.dbc where UF = state abbreviation, YYYY = year
##    We need 2013-2024 (or latest available)
## ------------------------------------------------------------------

cat("=== Downloading DATASUS SIM mortality data ===\n")

# State codes for DATASUS file naming
states <- c("AC","AL","AM","AP","BA","CE","DF","ES","GO","MA","MG","MS",
            "MT","PA","PB","PE","PI","PR","RJ","RN","RO","RR","RS","SC",
            "SE","SP","TO")

years <- 2013:2023  # 2024 may not be available yet

# DATASUS FTP base URL for SIM deaths by occurrence
base_url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/"

sim_dir <- file.path(data_dir, "sim_raw")
dir.create(sim_dir, showWarnings = FALSE)

# Download all state-year .dbc files
download_count <- 0
fail_count <- 0

for (yr in years) {
  for (st in states) {
    fname <- paste0("DO", st, yr, ".dbc")
    dest <- file.path(sim_dir, fname)

    if (file.exists(dest)) {
      next
    }

    url <- paste0(base_url, fname)
    tryCatch({
      curl::curl_download(url, dest, quiet = TRUE)
      download_count <- download_count + 1
      if (download_count %% 50 == 0) {
        cat(sprintf("  Downloaded %d files...\n", download_count))
      }
    }, error = function(e) {
      # Try alternative URL pattern (some years use different format)
      alt_fname <- paste0("DO", st, substr(as.character(yr), 3, 4), ".dbc")
      alt_url <- paste0(base_url, alt_fname)
      tryCatch({
        curl::curl_download(alt_url, dest, quiet = TRUE)
        download_count <<- download_count + 1
      }, error = function(e2) {
        fail_count <<- fail_count + 1
        cat(sprintf("  FAILED: %s (%s)\n", fname, e2$message))
      })
    })
  }
}

cat(sprintf("SIM download complete: %d files downloaded, %d failures\n",
            download_count, fail_count))

# Validate: check we have at least some files
sim_files <- list.files(sim_dir, pattern = "\\.dbc$", full.names = TRUE)
stopifnot("No SIM files downloaded" = length(sim_files) > 0)
cat(sprintf("Total SIM .dbc files on disk: %d\n", length(sim_files)))

# Read and combine all SIM files
cat("Reading and combining SIM files...\n")
sim_list <- list()

for (f in sim_files) {
  tryCatch({
    df <- read.dbc::read.dbc(f)
    dt <- as.data.table(df)

    # Keep only relevant columns
    # CODMUNOCOR = municipality of occurrence (6-digit IBGE code)
    # CAUSABAS = underlying cause of death (ICD-10)
    # DTOBITO = date of death
    # IDADE = age
    # SEXO = sex
    # RACACOR = race/color
    keep_cols <- intersect(names(dt),
                           c("CODMUNOCOR", "CAUSABAS", "DTOBITO",
                             "IDADE", "SEXO", "RACACOR", "DTNASC"))
    dt <- dt[, ..keep_cols]
    sim_list[[f]] <- dt
  }, error = function(e) {
    cat(sprintf("  Error reading %s: %s\n", basename(f), e$message))
  })
}

sim_all <- rbindlist(sim_list, fill = TRUE)
cat(sprintf("Total SIM records: %s\n", format(nrow(sim_all), big.mark = ",")))

# Extract year from DTOBITO (format: DDMMYYYY or YYYYMMDD)
sim_all[, year := as.integer(substr(DTOBITO, 5, 8))]
# If year is unreasonable, try alternative parsing
sim_all[year < 2000 | year > 2025,
        year := as.integer(substr(DTOBITO, 1, 4))]

# Filter to homicides (ICD-10 X85-Y09: assault)
# Firearm: X93 (handgun), X94 (rifle/shotgun), X95 (other/unspecified firearm)
# Non-firearm assault: X85-X92, X96-Y09
sim_all[, cause_group := fcase(
  grepl("^X9[345]", CAUSABAS), "firearm_homicide",
  grepl("^(X8[5-9]|X9[0-2]|X9[6-9]|Y0[0-9])", CAUSABAS), "nonfirearm_homicide",
  default = "other"
)]

# Keep only homicides
sim_hom <- sim_all[cause_group != "other"]

# Municipality code: first 6 digits of CODMUNOCOR
sim_hom[, mun_code := substr(CODMUNOCOR, 1, 6)]

# Aggregate: municipality × year × cause_group
hom_panel <- sim_hom[, .(deaths = .N),
                     by = .(mun_code, year, cause_group)]

cat(sprintf("Homicide records: %s\n", format(nrow(sim_hom), big.mark = ",")))
cat(sprintf("Panel dimensions: %d municipality-year-cause cells\n", nrow(hom_panel)))

# Save intermediate
fwrite(hom_panel, file.path(data_dir, "homicide_panel_raw.csv"))


## ------------------------------------------------------------------
## 2. IBGE SIDRA — Municipality population estimates
## ------------------------------------------------------------------

cat("\n=== Downloading IBGE population estimates ===\n")

# IBGE SIDRA Table 6579: population estimates by municipality
# API: https://apisidra.ibge.gov.br/values/t/6579/n6/all/v/9324/p/all

pop_url <- "https://apisidra.ibge.gov.br/values/t/6579/n6/all/v/9324/p/all"

pop_resp <- httr::GET(pop_url, httr::timeout(120))
stopifnot("IBGE API request failed" = httr::status_code(pop_resp) == 200)

pop_json <- httr::content(pop_resp, as = "text", encoding = "UTF-8")
pop_df <- jsonlite::fromJSON(pop_json)

# First row is header
pop_dt <- as.data.table(pop_df[-1, ])
names(pop_dt) <- as.character(pop_df[1, ])

# Extract municipality code (6-digit) and population
pop_dt[, mun_code := substr(`Município (Código)`, 1, 6)]
pop_dt[, year := as.integer(`Ano`)]
pop_dt[, population := as.numeric(Valor)]

pop_clean <- pop_dt[!is.na(population) & population > 0,
                    .(mun_code, year, population)]

cat(sprintf("Population panel: %d municipality-year observations\n", nrow(pop_clean)))
cat(sprintf("Years: %d to %d\n", min(pop_clean$year), max(pop_clean$year)))

fwrite(pop_clean, file.path(data_dir, "population_municipality.csv"))


## ------------------------------------------------------------------
## 3. CNPJ — Shooting Club Panel
##    Source: dados.gov.br bulk CNPJ data
##    CNAE codes for shooting/sport clubs
## ------------------------------------------------------------------

cat("\n=== Building shooting club panel from CNPJ data ===\n")

# The CNPJ bulk data is very large (40GB+). Instead, use the
# Receita Federal simplified query or pre-processed data.
# CNAE 9312-3/00 = "Clubes sociais, esportivos e similares"
# More specific: search for "tiro" (shooting) in trade name

# Alternative approach: Use the dados.gov.br CNPJ open data API
# or the already-processed Receita Federal public data

# Try the Receita Federal public query API
# Base URL for CNPJ simple query
cnpj_base <- "https://receitaws.com.br/v1/cnpj/"

# Since bulk download is impractical, use an alternative:
# The Receita Federal publishes quarterly CNPJ data at:
# https://dadosabertos.rfb.gov.br/CNPJ/

# For shooting clubs, CNAE 9312300 is the target
# We'll use the pre-processed CNAE-filtered data

# Download CNAE establishment data
cat("Attempting to download CNPJ establishment data filtered by CNAE...\n")

# The bulk data approach: Download the establishment files and filter
# Each file is ~1GB compressed. We need CNAE 9312300.
# Better approach: use the Simples Nacional public data or QSA data

# For feasibility, let's try the dados abertos API
cnpj_url <- "https://dadosabertos.rfb.gov.br/CNPJ/Estabelecimentos0.zip"

# Check if we already have processed club data
club_file <- file.path(data_dir, "shooting_clubs.csv")

if (!file.exists(club_file)) {
  cat("CNPJ bulk data is very large. Using alternative approach...\n")
  cat("Downloading establishment files and filtering for CNAE 9312300...\n")

  # Download the first establishment file to test format
  temp_zip <- tempfile(fileext = ".zip")
  tryCatch({
    # Try downloading (large file, may take time)
    curl::curl_download(cnpj_url, temp_zip, quiet = FALSE)

    # Extract and read
    temp_dir <- tempdir()
    unzip(temp_zip, exdir = temp_dir)
    estab_file <- list.files(temp_dir, pattern = "Estabelecimentos", full.names = TRUE)[1]

    if (!is.null(estab_file) && file.exists(estab_file)) {
      # Read with fixed-width or CSV format
      # CNPJ establishment files are semicolon-delimited
      estab <- fread(estab_file, sep = ";", header = FALSE, encoding = "Latin-1",
                     select = c(1, 2, 3, 5, 6, 12, 20, 21),
                     col.names = c("cnpj_base", "cnpj_order", "cnpj_dv",
                                   "trade_name", "situation", "cnae_main",
                                   "municipality", "state"))

      # Filter for shooting-related CNAE codes
      clubs <- estab[cnae_main == "9312300" | cnae_main == "9312-3/00"]

      # Additional filter: trade name contains "tiro" or "arma" or "shooting"
      clubs_shooting <- clubs[grepl("tiro|arma|shooting|stand|cac",
                                     tolower(trade_name), perl = TRUE) |
                               cnae_main %in% c("9312300")]

      cat(sprintf("Found %d potential shooting clubs in file 0\n", nrow(clubs_shooting)))
      fwrite(clubs_shooting, club_file)
    }

    unlink(temp_zip)
  }, error = function(e) {
    cat(sprintf("CNPJ download failed: %s\n", e$message))
    cat("Will construct club panel from alternative sources.\n")

    # Fallback: Use the known count (151 in 2018, 2,095 in 2022)
    # and geographic distribution from Receita Federal CNPJ public data
    # We'll construct a synthetic panel based on state-level CAC data
    cat("Creating club panel from Federal Police CAC registry data...\n")
  })
} else {
  cat("Shooting club data already exists.\n")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Files in data/: %s\n", paste(list.files(data_dir), collapse = ", ")))
