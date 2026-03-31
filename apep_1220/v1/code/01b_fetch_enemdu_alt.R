## 01b_fetch_enemdu_alt.R — More aggressive ENEMDU fetch
source("00_packages.R")
data_dir <- "../data"

cat("=== Trying INEC ecuadorencifras.gob.ec direct downloads ===\n")

# INEC publishes CSVs and SAV files at various paths
# Try the comprehensive ENEMDU annual compilation pages

urls_to_try <- c(
  # CSV format attempts
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2019/Diciembre/201912_Empleo_BDD_CSV.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2018/Diciembre/201812_Empleo_BDD_CSV.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2017/Diciembre/201712_Empleo_BDD_CSV.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2016/Diciembre/201612_Empleo_BDD_CSV.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2015/Diciembre/201512_Empleo_BDD_CSV.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2014/Diciembre/201412_Empleo_BDD_CSV.zip",
  # SAV format
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2019/Diciembre/201912_Empleo_BDD_SPSS.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/2018/Diciembre/201812_Empleo_BDD_SPSS.zip",
  # Anual format
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/Empleo-Diciembre-2019/BDD_ENEMDU_2019.sav",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/Empleo-Diciembre-2018/BDD_ENEMDU_2018.sav",
  # Alternative paths
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/ENEMDU/2019/201912_Empleo_BDD_SPSS.zip",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/ENEMDU/2019/BDD_ENEMDU_2019_Anual.sav",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/ENEMDU/ENEMDU_2019/BDD_ENEMDU_2019_Anual.sav",
  "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO/ENEMDU/ENEMDU-2019-12/BDD_ENEMDU_2019_Anual.sav"
)

for (url in urls_to_try) {
  resp <- tryCatch(httr::HEAD(url, httr::timeout(10)), error = function(e) NULL)
  status <- if (!is.null(resp)) httr::status_code(resp) else "error"
  cat(sprintf("  %s -> %s\n", basename(url), status))
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    cat(sprintf("  *** FOUND: %s ***\n", url))
    dest <- file.path(data_dir, basename(url))
    httr::GET(url, httr::write_disk(dest, overwrite=TRUE), httr::timeout(300))
    cat(sprintf("  Downloaded: %.1f MB\n", file.size(dest)/1e6))
  }
}

cat("\n=== Trying ANDA direct data file downloads ===\n")

# ANDA microdata access typically requires clicking through a form
# But some files are accessible via direct DDI links
# Try the DDI documentation pages which sometimes include data links

for (cat_id in c("906", "831", "782")) {
  ddi_url <- sprintf("https://anda.inec.gob.ec/anda/index.php/catalog/%s/get-microdata", cat_id)
  resp <- tryCatch(httr::GET(ddi_url, httr::timeout(15)), error = function(e) NULL)
  if (!is.null(resp)) {
    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    # Check if it has download links
    links <- regmatches(content, gregexpr('href="[^"]*\\.(sav|csv|dta|zip)"', content))[[1]]
    cat(sprintf("  ANDA %s: found %d data links\n", cat_id, length(links)))
    if (length(links) > 0) cat(sprintf("    %s\n", paste(links, collapse="\n    ")))
  }
}

cat("\n=== Trying ILO LFS microdata bulk download ===\n")

# ILO provides harmonized microdata from national LFS for member countries
# These are typically at: https://ilostat.ilo.org/data/bulk/

bulk_indicators <- c(
  "EMP_TEMP_SEX_STE_ECO_NB_A",  # Employment by status and sector
  "EMP_TEMP_SEX_STE_OCU_NB_A",  # Employment by status and occupation
  "EAP_2EAP_SEX_AGE_NB_A"       # Economically active population
)

for (ind in bulk_indicators) {
  url <- sprintf("https://www.ilo.org/ilostat-files/WEB_bulk_download/indicator/%s.csv.gz", ind)
  resp <- tryCatch(httr::HEAD(url, httr::timeout(15)), error = function(e) NULL)
  status <- if (!is.null(resp)) httr::status_code(resp) else "error"
  cat(sprintf("  %s -> %s\n", ind, status))
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    dest <- file.path(data_dir, sprintf("ilo_%s.csv.gz", tolower(ind)))
    cat(sprintf("  Downloading %s...\n", ind))
    httr::GET(url, httr::write_disk(dest, overwrite=TRUE), httr::timeout(300))
    size_mb <- file.size(dest)/1e6
    cat(sprintf("  Downloaded: %.1f MB\n", size_mb))
    # Read just Ecuador data
    if (size_mb > 0.01) {
      df <- fread(cmd = sprintf("gzip -dc '%s' | grep 'ECU'", dest), header=FALSE)
      cat(sprintf("  Ecuador rows: %d\n", nrow(df)))
      if (nrow(df) > 50) {
        # Read full with headers
        full <- fread(cmd = sprintf("gzip -dc '%s' | head -1; gzip -dc '%s' | grep 'ECU'", dest, dest))
        saveRDS(full, file.path(data_dir, sprintf("ilo_%s_ecu.rds", tolower(ind))))
        cat(sprintf("  Saved Ecuador subset: %d rows\n", nrow(full)))
      }
    }
  }
}

cat("\nAlternative fetch complete.\n")
