# ─── Build county-level analysis panel: patent Bartik + QWI employment ───────
source("code/00_packages.R")
source(file.path(Sys.getenv("HOME"), "auto-policy-evals/scripts/lib/azure_data.R"))

# ─── 1. Read county-level patent panel from Python ──────────────────────────
cat("Reading county patent panel...\n")
patent <- fread("data/county_panel.csv")
cat(sprintf("  Counties: %d, Obs: %d\n", uniqueN(patent$county_fips), nrow(patent)))

# ─── 2. Fetch QWI at county level from Azure ────────────────────────────────
cat("Connecting to Azure...\n")
con <- apep_azure_connect()

cat("Fetching county × quarter QWI (all sectors)...\n")
qwi <- DBI::dbGetQuery(con, "
  SELECT geography AS county_fips, year, quarter,
         Emp, HirN, EarnS
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE industry = '00'
    AND sex = 0 AND education = 'E0'
    AND ownercode = 'A05'
    AND year BETWEEN 2004 AND 2014
")
qwi <- as.data.table(qwi)
# Convert county_fips to string with leading zeros (5 digits)
qwi[, county_fips := sprintf("%05d", as.integer(county_fips))]
cat(sprintf("  QWI rows: %d, counties: %d\n", nrow(qwi), uniqueN(qwi$county_fips)))

# Aggregate to county × year
cat("Aggregating to county × year...\n")
qwi_annual <- qwi[, .(
  Emp   = mean(Emp, na.rm = TRUE),
  HirN  = sum(HirN, na.rm = TRUE),
  EarnS = mean(EarnS, na.rm = TRUE)
), by = .(county_fips, year)]
cat(sprintf("  County-year obs: %d\n", nrow(qwi_annual)))

# Also fetch sector-level for mechanism split
cat("Fetching sector-level QWI...\n")
qwi_sec <- DBI::dbGetQuery(con, "
  SELECT geography AS county_fips, year, quarter, industry,
         Emp, HirN
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE sex = 0 AND education = 'E0'
    AND ownercode = 'A05'
    AND industry IN ('31-33', '51', '54', '44-45', '72', '81')
    AND year BETWEEN 2004 AND 2014
")
qwi_sec <- as.data.table(qwi_sec)
qwi_sec[, county_fips := sprintf("%05d", as.integer(county_fips))]

exposed <- c("31-33", "51", "54")
local_svc <- c("44-45", "72", "81")

sec_annual <- qwi_sec[, .(
  Emp = mean(Emp, na.rm = TRUE),
  HirN = sum(HirN, na.rm = TRUE)
), by = .(county_fips, year, industry)]

sec_wide <- sec_annual[, .(
  Emp_exposed   = sum(Emp[industry %in% exposed], na.rm = TRUE),
  Emp_local_svc = sum(Emp[industry %in% local_svc], na.rm = TRUE)
), by = .(county_fips, year)]

DBI::dbDisconnect(con, shutdown = TRUE)

# ─── 3. Merge patent panel with QWI outcomes ────────────────────────────────
cat("Merging patent panel with QWI...\n")

# Match patent county_fips format
patent[, county_fips := as.character(county_fips)]
# Pad to 5 digits if needed
patent[nchar(county_fips) == 4, county_fips := paste0("0", county_fips)]

# Current-year employment
panel <- merge(patent, qwi_annual, by = c("county_fips", "year"), all.x = TRUE)
setnames(panel, c("Emp", "HirN", "EarnS"), c("Emp_t", "HirN_t", "EarnS_t"))

# t+1 employment
qwi_t1 <- qwi_annual[, .(county_fips, year_t = year - 1L, Emp_t1 = Emp, HirN_t1 = HirN, EarnS_t1 = EarnS)]
panel <- merge(panel, qwi_t1, by.x = c("county_fips", "year"), by.y = c("county_fips", "year_t"), all.x = TRUE)

# t-1 employment (placebo)
qwi_tm1 <- qwi_annual[, .(county_fips, year_tp1 = year + 1L, Emp_tm1 = Emp)]
panel <- merge(panel, qwi_tm1, by.x = c("county_fips", "year"), by.y = c("county_fips", "year_tp1"), all.x = TRUE)

# Sector splits (t+1)
sec_t1 <- sec_wide[, .(county_fips, year_t = year - 1L, Emp_exposed_t1 = Emp_exposed, Emp_local_svc_t1 = Emp_local_svc)]
panel <- merge(panel, sec_t1, by.x = c("county_fips", "year"), by.y = c("county_fips", "year_t"), all.x = TRUE)

# Log transforms
panel[, log_grants := log(pmax(grants, 1))]
panel[, log_Emp_t1 := log(Emp_t1)]
panel[, log_HirN_t1 := log(HirN_t1)]
panel[, log_EarnS_t1 := log(EarnS_t1)]
panel[, log_Emp_tm1 := log(Emp_tm1)]
panel[, log_Emp_exposed_t1 := log(pmax(Emp_exposed_t1, 1))]
panel[, log_Emp_local_svc_t1 := log(pmax(Emp_local_svc_t1, 1))]

# State FIPS (first 2 digits)
panel[, state_fips := substr(county_fips, 1, 2)]

cat(sprintf("\nFinal panel: %d obs, %d counties, years %d-%d\n",
            nrow(panel), uniqueN(panel$county_fips), min(panel$year), max(panel$year)))
cat(sprintf("  Non-missing Emp_t1: %d (%.1f%%)\n",
            sum(!is.na(panel$Emp_t1)), 100*mean(!is.na(panel$Emp_t1))))
cat(sprintf("  Non-missing log_Emp_t1: %d\n", sum(!is.na(panel$log_Emp_t1))))

fwrite(panel, "data/county_analysis_panel.csv")
cat("Saved data/county_analysis_panel.csv\n")
