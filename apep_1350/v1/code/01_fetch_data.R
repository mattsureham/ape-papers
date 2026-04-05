## 01_fetch_data.R — Fetch QWI race×ethnicity × 3-digit NAICS from Azure
## apep_1350: The Segregation Dividend

source("00_packages.R")

# ── Azure connection (manual to handle semicolons in connection string) ──
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)[1]
conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
conn_str <- gsub('^["\'](.*)["\']$', "\\1", conn_str)

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure; LOAD azure;")
DBI::dbExecute(con, sprintf(
  "CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');",
  gsub("'", "''", conn_str)
))
cat("Connected to Azure.\n")

# ── 1. Pull QWI rh/n3 for NAICS 624 (Social Assistance) and placebos ──
cat("Querying QWI rh/n3 from Azure for NAICS 624, 621-623, 72...\n")

qwi <- DBI::dbGetQuery(con, "
  SELECT
    geography AS fips,
    year, quarter,
    industry,
    race, ethnicity, sex,
    Emp, EmpEnd, EmpS,
    HirA, HirN, Sep,
    EarnS, EarnBeg,
    FrmJbGn, FrmJbLs,
    TurnOvrS,
    sEmp, sEmpEnd, sEmpS,
    sHirA, sHirN, sSep,
    sEarnS, sEarnBeg,
    sFrmJbGn, sFrmJbLs,
    sTurnOvrS
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry IN ('624', '621', '622', '623', '722', '721')
    AND sex = '0'
    AND ethnicity = 'A0'
    AND race IN ('A1', 'A2')
")

cat(sprintf("  Raw rows: %s\n", format(nrow(qwi), big.mark = ",")))

# ── 2. Also pull NAICS sector-level for broader comparison ──
cat("Querying QWI rh/ns sector-level for NAICS 62 and 72...\n")

qwi_sector <- DBI::dbGetQuery(con, "
  SELECT
    geography AS fips,
    year, quarter,
    industry,
    race, ethnicity, sex,
    Emp, EmpEnd, EmpS,
    EarnS, EarnBeg,
    HirA, Sep,
    sEmp, sEmpEnd, sEmpS,
    sEarnS, sEarnBeg,
    sHirA, sSep
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('62', '72')
    AND sex = '0'
    AND ethnicity = 'A0'
    AND race IN ('A1', 'A2')
")

cat(sprintf("  Sector rows: %s\n", format(nrow(qwi_sector), big.mark = ",")))

DBI::dbDisconnect(con, shutdown = TRUE)

# ── 3. Validate data ──
stopifnot("No data returned from Azure" = nrow(qwi) > 0)
stopifnot("No sector data returned" = nrow(qwi_sector) > 0)

# Check suppression rates
cat("\n── Suppression check (624, race-level) ──\n")
supp_624 <- qwi |>
  filter(industry == "624") |>
  group_by(race) |>
  summarise(
    n_cells = n(),
    n_valid_emp = sum(!is.na(Emp) & Emp > 0),
    n_valid_earn = sum(!is.na(EarnS) & EarnS > 0),
    pct_valid_emp = round(100 * n_valid_emp / n_cells, 1),
    pct_valid_earn = round(100 * n_valid_earn / n_cells, 1),
    .groups = "drop"
  )
print(supp_624)

# ── 4. Save ──
arrow::write_parquet(qwi, "../data/qwi_rh_n3_selected.parquet")
arrow::write_parquet(qwi_sector, "../data/qwi_rh_ns_selected.parquet")

cat(sprintf("\nSaved %s rows (3-digit) and %s rows (sector) to data/\n",
            format(nrow(qwi), big.mark = ","),
            format(nrow(qwi_sector), big.mark = ",")))

cat("01_fetch_data.R complete.\n")
