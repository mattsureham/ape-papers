# 01_fetch_data.R — Fetch QWI data from Azure for NAICS 312 and 311
# apep_0972: Craft brewery self-distribution deregulation

source("00_packages.R")

# ── Load .env for Azure connection ──────────────────────────────────
env_file <- "../../../../.env"
stopifnot(file.exists(env_file))
lines <- readLines(env_file, warn = FALSE)
az_conn <- NULL
for (line in lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    az_conn <- gsub('^["\']|["\']$', '', az_conn)
    break
  }
}
stopifnot("Azure connection string not found" = !is.null(az_conn))

# ── Connect via DuckDB ──────────────────────────────────────────────
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))
cat("Azure connection configured.\n")

# ══════════════════════════════════════════════════════════════════════
# Panel 1: Sex × Age — NAICS 312 (Beverage Mfg) + 311 (Food Mfg)
# Aggregate to state × quarter × industry for main DiD
# ══════════════════════════════════════════════════════════════════════
cat("Fetching NAICS 312+311 sex×age panel...\n")
panel_sa <- dbGetQuery(con, "
  SELECT
    CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER) AS statefips,
    geography AS countyfips,
    year,
    quarter,
    CAST(industry AS VARCHAR) AS industry,
    CAST(sex AS VARCHAR) AS sex,
    CAST(agegrp AS VARCHAR) AS agegrp,
    Emp,
    EmpEnd,
    HirA,
    HirN,
    Sep,
    EarnS,
    FrmJbGn,
    FrmJbLs,
    TurnOvrS
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) IN ('311', '312')
    AND year BETWEEN 2001 AND 2024
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(agegrp AS VARCHAR) = 'A00'
    AND geography IS NOT NULL
    AND CAST(geography AS INTEGER) > 999
")
cat(sprintf("  SA panel: %d rows, %d counties\n", nrow(panel_sa), n_distinct(panel_sa$countyfips)))

# ══════════════════════════════════════════════════════════════════════
# Panel 2: Sex × Education — NAICS 312 only, for heterogeneity
# ══════════════════════════════════════════════════════════════════════
cat("Fetching NAICS 312 sex×education panel...\n")
panel_se <- dbGetQuery(con, "
  SELECT
    CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER) AS statefips,
    geography AS countyfips,
    year,
    quarter,
    CAST(education AS VARCHAR) AS education,
    Emp,
    HirN,
    EarnS
  FROM read_parquet('az://derived/qwi/se/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) = '312'
    AND year BETWEEN 2001 AND 2024
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(education AS VARCHAR) IN ('E1', 'E2', 'E3', 'E4')
    AND geography IS NOT NULL
    AND CAST(geography AS INTEGER) > 999
")
cat(sprintf("  SE panel: %d rows\n", nrow(panel_se)))

# ══════════════════════════════════════════════════════════════════════
# Panel 3: Race × Ethnicity — NAICS 312 only, for heterogeneity
# ══════════════════════════════════════════════════════════════════════
cat("Fetching NAICS 312 race×ethnicity panel...\n")
panel_rh <- dbGetQuery(con, "
  SELECT
    CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER) AS statefips,
    geography AS countyfips,
    year,
    quarter,
    CAST(ethnicity AS VARCHAR) AS ethnicity,
    CAST(race AS VARCHAR) AS race,
    Emp,
    HirN,
    EarnS
  FROM read_parquet('az://derived/qwi/rh/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) = '312'
    AND year BETWEEN 2001 AND 2024
    AND CAST(race AS VARCHAR) = 'A0'
    AND CAST(ethnicity AS VARCHAR) IN ('A1', 'A2')
    AND geography IS NOT NULL
    AND CAST(geography AS INTEGER) > 999
")
cat(sprintf("  RH panel: %d rows\n", nrow(panel_rh)))

dbDisconnect(con, shutdown = TRUE)

# ── Save raw panels ─────────────────────────────────────────────────
saveRDS(panel_sa, "../data/panel_sa_raw.rds")
saveRDS(panel_se, "../data/panel_se_raw.rds")
saveRDS(panel_rh, "../data/panel_rh_raw.rds")

cat(sprintf("\nData fetch complete. Panels saved to data/\n"))
cat(sprintf("  SA: %d rows (%d counties, %d states)\n",
            nrow(panel_sa), n_distinct(panel_sa$countyfips), n_distinct(panel_sa$statefips)))
cat(sprintf("  SE: %d rows\n", nrow(panel_se)))
cat(sprintf("  RH: %d rows\n", nrow(panel_rh)))
