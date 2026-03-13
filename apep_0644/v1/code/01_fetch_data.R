# 01_fetch_data.R — Fetch QWI data from Azure
# apep_0644: Pay Transparency Mandates and Employer Adjustment

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("=== Fetching QWI data from Azure ===\n")

con <- apep_azure_connect()

# ---- 1. Fetch QWI industry-level data (sex x age, all industries, 2-digit NAICS) ----
cat("Fetching QWI industry-level data (2-digit NAICS)...\n")

qwi_raw <- DBI::dbGetQuery(con, "
  SELECT geography, year, quarter, industry, sex, agegrp,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, HirAEnd,
         FrmJbGn, FrmJbLs, FrmJbC,
         EarnS, EarnBeg, EarnHirAS, EarnHirNS,
         TurnOvrS, Payroll
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE sex = 0 AND agegrp = 'A00'
  AND year BETWEEN 2015 AND 2024
")

cat("  Raw QWI rows (all industries, all demographics): ", nrow(qwi_raw), "\n")

# Verify we have the key variables
stopifnot("Emp" %in% names(qwi_raw))
stopifnot("HirN" %in% names(qwi_raw))
stopifnot("FrmJbGn" %in% names(qwi_raw))
stopifnot(nrow(qwi_raw) > 100000)

# ---- 2. Fetch QWI by sex (for gender heterogeneity) ----
cat("Fetching QWI sex-disaggregated data...\n")

qwi_sex <- DBI::dbGetQuery(con, "
  SELECT geography, year, quarter, industry, sex, agegrp,
         Emp, HirA, HirN, Sep, FrmJbGn, FrmJbLs,
         EarnS, EarnHirNS, TurnOvrS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE sex IN (1, 2) AND agegrp = 'A00'
  AND year BETWEEN 2015 AND 2024
")

cat("  Sex-disaggregated rows: ", nrow(qwi_sex), "\n")

# ---- 3. Save raw data ----
cat("Saving raw data...\n")
saveRDS(qwi_raw, "../data/qwi_raw.rds")
saveRDS(qwi_sex, "../data/qwi_sex.rds")

apep_azure_disconnect(con)

cat("=== Data fetch complete ===\n")
cat("Main dataset: ", nrow(qwi_raw), " rows\n")
cat("Sex dataset: ", nrow(qwi_sex), " rows\n")
cat("Counties: ", n_distinct(qwi_raw$geography), "\n")
cat("Industries: ", n_distinct(qwi_raw$industry), "\n")
cat("Year range: ", min(qwi_raw$year), "-", max(qwi_raw$year), "\n")
