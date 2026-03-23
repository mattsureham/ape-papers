## 01_fetch_data.R — Fetch all data from public sources
## apep_0812: Pump Prices and Le Pen
## Sources: data.gouv.fr (elections), INSEE (census transport mode, income)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

dl <- function(url, dest, label) {
  fp <- file.path(data_dir, dest)
  if (file.exists(fp) && file.info(fp)$size > 1000) {
    cat(sprintf("  SKIP (cached): %s\n", label))
    return(invisible(fp))
  }
  cat(sprintf("  Downloading: %s ...\n", label))
  download.file(url, fp, mode = "wb", quiet = TRUE)
  if (!file.exists(fp) || file.info(fp)$size < 100) {
    stop(sprintf("FAILED: %s — download produced empty file!", label))
  }
  cat(sprintf("  OK: %s (%.1f MB)\n", label, file.info(fp)$size / 1e6))
  invisible(fp)
}

# ============================================================
# 1) ELECTION DATA — Ministère de l'Intérieur via data.gouv.fr
# ============================================================
cat("=== Election data ===\n")

# 2022 T1 definitifs (sub-commune XLSX, commune cols present)
dl("https://static.data.gouv.fr/resources/election-presidentielle-des-10-et-24-avril-2022-resultats-definitifs-du-1er-tour/20220414-152517/resultats-par-niveau-subcom-t1-france-entiere.xlsx",
   "pres_2022_t1.xlsx", "2022 Presidential T1")

# 2017 T1 commune level
dl("https://static.data.gouv.fr/resources/election-presidentielle-des-23-avril-et-7-mai-2017-resultats-du-1er-tour-1/20170424-100045/Presidentielle_2017_Resultats_Communes_Tour_1.xls",
   "pres_2017_t1.xls", "2017 Presidential T1 Communes")

# 2012 T1 commune level (file with "Tour 1" sheet = commune-level results)
dl("https://static.data.gouv.fr/15/56da0680db5a23d2d1601aed81359f21e0dc8ed9f8abd49e2a7c66b5c02b6f.xls",
   "pres_2012_communes.xls", "2012 Presidential T1 Communes")

# 2007 T1 commune level (file with "Tour 1" sheet = commune-level results)
dl("https://static.data.gouv.fr/88/523001571e33cd204af5959a5387961121f2a1f765d2ea9197190fcdf02778.xls",
   "pres_2007_communes.xls", "2007 Presidential T1 Communes")

# ============================================================
# 2) CENSUS — Transport mode to work
# ============================================================
cat("\n=== Census transport mode data ===\n")
dl("https://www.insee.fr/fr/statistiques/fichier/8581424/base-cc-caract_emp-2022_csv.zip",
   "census_emp_2022.zip", "Census employment 2022")
unzip(file.path(data_dir, "census_emp_2022.zip"),
      exdir = file.path(data_dir, "census_raw"), overwrite = TRUE)

# ============================================================
# 3) FILOSOFI — Commune-level income
# ============================================================
cat("\n=== Filosofi income data ===\n")
dl("https://www.insee.fr/fr/statistiques/fichier/6036907/indic-struct-distrib-revenu-2019-COMMUNES.zip",
   "filosofi_2019.zip", "Filosofi 2019")
unzip(file.path(data_dir, "filosofi_2019.zip"),
      exdir = file.path(data_dir, "filosofi_raw"), overwrite = TRUE)

# ============================================================
# 4) POPULATION
# ============================================================
cat("\n=== Population data ===\n")
dl("https://www.insee.fr/fr/statistiques/fichier/6683035/ensemble.zip",
   "pop_communes.zip", "Commune populations")
unzip(file.path(data_dir, "pop_communes.zip"),
      exdir = file.path(data_dir, "pop_raw"), overwrite = TRUE)

# ============================================================
# Verify
# ============================================================
cat("\n=== Verification ===\n")
for (f in c("pres_2022_t1.xlsx", "pres_2017_t1.xls",
            "pres_2012_communes.xls", "pres_2007_communes.xls")) {
  fp <- file.path(data_dir, f)
  stopifnot(file.exists(fp))
  cat(sprintf("  OK: %s (%.1f MB)\n", f, file.info(fp)$size / 1e6))
}
for (d in c("census_raw", "filosofi_raw", "pop_raw")) {
  dp <- file.path(data_dir, d)
  stopifnot(length(list.files(dp, recursive = TRUE)) > 0)
  cat(sprintf("  OK: %s/\n", d))
}
cat("\nAll data fetched successfully.\n")
