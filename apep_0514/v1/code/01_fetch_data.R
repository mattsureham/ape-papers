##########################################################################
# 01_fetch_data.R — Fetch all data sources for the cumul des mandats paper
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
#
# Sources:
#   1. DGFiP Comptes individuels des communes 2000-2017 (aggregated)
#   2. OFGL Consolidated commune accounts 2017-2024
#   3. NosDéputés.fr (deputies XIV and XV legislatures)
#   4. Commune-constituency crosswalk (2012 and 2017)
#   5. DVF property transactions (2014-2022)
#   6. RNE elected officials (deputies + mayors)
#   7. Legislative election results (2012, 2017)
##########################################################################

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Helper for downloading with retry
safe_download <- function(url, destfile, description, mode = "wb") {
  if (file.exists(destfile) && file.info(destfile)$size > 1000) {
    cat("  Already exists:", basename(destfile),
        round(file.info(destfile)$size / 1e6, 1), "MB\n")
    return(invisible(TRUE))
  }
  cat("  Downloading", description, "...\n")
  tryCatch({
    download.file(url, destfile, mode = mode, quiet = TRUE)
    fsize <- file.info(destfile)$size
    if (fsize < 500) {
      stop("File too small (", fsize, " bytes) — likely error page")
    }
    cat("  OK:", round(fsize / 1e6, 2), "MB\n")
    invisible(TRUE)
  }, error = function(e) {
    cat("  FAILED:", e$message, "\n")
    if (file.exists(destfile)) file.remove(destfile)
    invisible(FALSE)
  })
}

# ============================================================================
# 1. DGFiP COMMUNE BUDGETS 2000-2017 (aggregated CSV, ~103MB)
# ============================================================================
cat("\n=== 1. DGFiP commune budgets 2000-2017 ===\n")

dgfip_url <- "https://static.data.gouv.fr/resources/comptes-individuels-des-communes/20181019-174552/comptes-communes-2000-2017.csv"
dgfip_file <- paste0(data_dir, "comptes_communes_2000_2017.csv")

ok <- safe_download(dgfip_url, dgfip_file, "DGFiP commune budgets 2000-2017")
if (!ok) stop("FATAL: Cannot download commune budget data 2000-2017. Cannot proceed.")

# ============================================================================
# 2. OFGL CONSOLIDATED COMMUNE ACCOUNTS 2017-2024
# ============================================================================
cat("\n=== 2. OFGL consolidated accounts 2017-2024 ===\n")

# The OFGL API export — this returns the full dataset in CSV
ofgl_url <- "https://data.ofgl.fr/api/explore/v2.1/catalog/datasets/ofgl-base-communes-consolidee/exports/csv?use_labels=true&delimiter=%3B"
ofgl_file <- paste0(data_dir, "ofgl_communes_2017_2024.csv")

ok <- safe_download(ofgl_url, ofgl_file, "OFGL consolidated communes 2017-2024")
if (!ok) {
  cat("  OFGL API export failed. Trying alternate approach with yearly requests...\n")
  # Fall back to yearly requests
  ofgl_parts <- list()
  for (yr in 2018:2023) {
    yr_url <- paste0(
      "https://data.ofgl.fr/api/explore/v2.1/catalog/datasets/",
      "ofgl-base-communes-consolidee/exports/csv?",
      "where=exer%3D", yr, "&use_labels=true&delimiter=%3B&limit=-1"
    )
    yr_file <- paste0(data_dir, "ofgl_communes_", yr, ".csv")
    safe_download(yr_url, yr_file, paste("OFGL", yr))
  }
}

# ============================================================================
# 3. DEPUTIES — NosDéputés.fr (XIV and XV legislatures)
# ============================================================================
cat("\n=== 3. Deputy data from NosDéputés.fr ===\n")

# XIV legislature (2012-2017): The key legislature for identifying cumulards
nds_xiv_url <- "https://www.nosdeputes.fr/synthese/data/json"
nds_xiv_file <- paste0(data_dir, "nosdeputes_xiv.json")
ok <- safe_download(nds_xiv_url, nds_xiv_file, "NosDéputés XIV (2012-2017)")
if (!ok) stop("FATAL: Cannot download deputy data. Cannot proceed.")

# XV legislature (2017-2022): Post-ban deputies
nds_xv_url <- "https://www.nosdeputes.fr/15/synthese/data/json"
nds_xv_file <- paste0(data_dir, "nosdeputes_xv.json")
safe_download(nds_xv_url, nds_xv_file, "NosDéputés XV (2017-2022)")

# ============================================================================
# 4. COMMUNE-CONSTITUENCY CROSSWALK
# ============================================================================
cat("\n=== 4. Commune-constituency crosswalk ===\n")

# 2017 crosswalk (XLSX)
cw_2017_url <- "https://static.data.gouv.fr/resources/circonscriptions-legislatives-table-de-correspondance-des-communes-et-des-cantons-pour-les-elections-legislatives-de-2012-et-sa-mise-a-jour-pour-les-elections-legislatives-2017/20170411-141128/Table_de_correspondance_circo_legislatives2017-1.xlsx"
cw_2017_file <- paste0(data_dir, "crosswalk_circo_2017.xlsx")
ok <- safe_download(cw_2017_url, cw_2017_file, "Constituency crosswalk 2017")
if (!ok) {
  # Try 2012 version
  cw_2012_url <- "https://static.data.gouv.fr/resources/circonscriptions-legislatives-table-de-correspondance-des-communes-et-des-cantons-pour-les-elections-legislatives-de-2012-et-sa-mise-a-jour-pour-les-elections-legislatives-2017/20170411-141945/Tableau_de_correspondance_communes_cantons_circonscriptions_2012.xls"
  cw_2012_file <- paste0(data_dir, "crosswalk_circo_2012.xls")
  ok <- safe_download(cw_2012_url, cw_2012_file, "Constituency crosswalk 2012")
  if (!ok) stop("FATAL: Cannot download commune-constituency crosswalk. Cannot proceed.")
}

# ============================================================================
# 5. DVF PROPERTY TRANSACTIONS
# ============================================================================
cat("\n=== 5. DVF property transactions ===\n")

# DVF files from geo-dvf. Download years 2014-2022.
# These files can be large (500MB+). For low-RAM, we'll process them
# incrementally in 02_clean_data.R.

dvf_years <- 2014:2022
dvf_count <- 0

for (yr in dvf_years) {
  dvf_file_gz <- paste0(data_dir, "dvf_", yr, ".csv.gz")
  dvf_file_csv <- paste0(data_dir, "dvf_", yr, ".csv")

  if (file.exists(dvf_file_gz) || file.exists(dvf_file_csv)) {
    dvf_count <- dvf_count + 1
    next
  }

  dvf_url <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/", yr, "/full.csv.gz")
  ok <- safe_download(dvf_url, dvf_file_gz, paste("DVF", yr))
  if (ok) {
    dvf_count <- dvf_count + 1
  } else {
    # Try uncompressed
    dvf_url2 <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/", yr, "/full.csv")
    ok2 <- safe_download(dvf_url2, dvf_file_csv, paste("DVF", yr, "(csv)"))
    if (ok2) dvf_count <- dvf_count + 1
  }
}
cat("  DVF years downloaded:", dvf_count, "of", length(dvf_years), "\n")

# ============================================================================
# 6. RNE — RÉPERTOIRE NATIONAL DES ÉLUS
# ============================================================================
cat("\n=== 6. RNE elected officials ===\n")

rne_dep_url <- "https://static.data.gouv.fr/resources/repertoire-national-des-elus-1/20251223-104106/elus-deputes-dep.csv"
rne_dep_file <- paste0(data_dir, "rne_deputes.csv")
safe_download(rne_dep_url, rne_dep_file, "RNE Députés")

rne_maires_url <- "https://static.data.gouv.fr/resources/repertoire-national-des-elus-1/20251223-104211/elus-maires-mai.csv"
rne_maires_file <- paste0(data_dir, "rne_maires.csv")
safe_download(rne_maires_url, rne_maires_file, "RNE Maires")

# ============================================================================
# 7. LEGISLATIVE ELECTION RESULTS (2012, 2017)
# ============================================================================
cat("\n=== 7. Legislative election results ===\n")

# 2012 results (XLS)
leg2012_url <- "https://static.data.gouv.fr/7b/7e916e0ab5bf0dc817a679c838dae7c2db500c1f8e831f09a6d157078860c9.xls"
leg2012_file <- paste0(data_dir, "legislatives_2012.xls")
safe_download(leg2012_url, leg2012_file, "Legislative 2012 results")

# 2017 T1 results (XLSX)
leg2017_url <- "https://static.data.gouv.fr/resources/elections-legislatives-des-11-et-18-juin-2017-resultats-du-1er-tour/20170613-095447/Leg_2017_Resultats_T1_c.xlsx"
leg2017_file <- paste0(data_dir, "legislatives_2017_T1.xlsx")
safe_download(leg2017_url, leg2017_file, "Legislative 2017 T1 results")

# ============================================================================
# VALIDATION
# ============================================================================
cat("\n=== Data Validation ===\n")

essential <- c(dgfip_file, nds_xiv_file)

# Check crosswalk (either 2017 or 2012 version)
if (file.exists(cw_2017_file)) {
  essential <- c(essential, cw_2017_file)
} else if (file.exists(paste0(data_dir, "crosswalk_circo_2012.xls"))) {
  essential <- c(essential, paste0(data_dir, "crosswalk_circo_2012.xls"))
} else {
  stop("FATAL: No commune-constituency crosswalk available.")
}

for (f in essential) {
  stopifnot(
    "Essential file missing" = file.exists(f),
    "Essential file too small" = file.info(f)$size > 1000
  )
  cat("  OK:", basename(f), "-",
      round(file.info(f)$size / 1e6, 2), "MB\n")
}

# Check DVF
dvf_available <- length(list.files(data_dir, pattern = "^dvf_\\d{4}\\.(csv|csv\\.gz)$"))
cat("  DVF years available:", dvf_available, "\n")
stopifnot("Need at least 3 DVF years for analysis" = dvf_available >= 3)

# Check OFGL
ofgl_available <- file.exists(ofgl_file) ||
  any(file.exists(paste0(data_dir, "ofgl_communes_", 2018:2023, ".csv")))
cat("  OFGL post-2017 data:", ifelse(ofgl_available, "YES", "NO"), "\n")

cat("\n=== All essential data downloaded successfully ===\n")
cat("Ready for 02_clean_data.R\n")
