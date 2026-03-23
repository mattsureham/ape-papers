## 01_fetch_data.R — Fetch IPEDS and QWI data
## apep_0793: The Innovation Supply Chain

source("00_packages.R")

# ===========================================================================
# Azure connection
# ===========================================================================
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")

env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
cs_val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
stopifnot("Azure connection string not found" = nchar(cs_val) > 50)
dbExecute(con, paste0("CREATE SECRET apep (TYPE azure, CONNECTION_STRING '", cs_val, "');"))
cat("Azure connected.\n")

# ===========================================================================
# 1. IPEDS: CS + Engineering completions
#    Table: c_a (completions), cipcode is DOUBLE (e.g. 11.0101)
#    Table: hd (directory), county_fips is DOUBLE
#    award_level: 5 = Bachelor's, 7 = Master's
# ===========================================================================
cat("Attaching IPEDS DuckDB...\n")
stopifnot("IPEDS DuckDB not found" = file.exists("/tmp/ipeds.duckdb"))
dbExecute(con, "ATTACH '/tmp/ipeds.duckdb' AS ipeds (READ_ONLY);")

# CIP 11.xxxx = Computer/Info Sciences, CIP 14.xxxx = Engineering
# cipcode is DOUBLE: 11.0 to 11.9999 and 14.0 to 14.9999
ipeds_comp <- dbGetQuery(con, "
  SELECT c.unitid, c.year, c.cipcode, c.award_level, c.ctotalt,
         d.county_fips, d.state AS stabbr, d.institution_name AS instnm
  FROM ipeds.main.c_a c
  JOIN ipeds.main.hd d ON c.unitid = d.unitid AND c.year = d.year
  WHERE ((c.cipcode >= 11.0 AND c.cipcode < 12.0)
         OR (c.cipcode >= 14.0 AND c.cipcode < 15.0))
    AND c.award_level IN (5, 7)
    AND c.ctotalt > 0
    AND d.county_fips IS NOT NULL
    AND d.county_fips > 0
  ORDER BY c.year, d.county_fips
")

cat(sprintf("IPEDS CS+Eng completions: %d rows, %d institutions, years %d-%d\n",
            nrow(ipeds_comp), n_distinct(ipeds_comp$unitid),
            min(ipeds_comp$year), max(ipeds_comp$year)))

stopifnot("No IPEDS data" = nrow(ipeds_comp) > 1000)

# Aggregate to county-year level
ipeds_county <- ipeds_comp %>%
  mutate(county_fips = sprintf("%05d", as.integer(county_fips))) %>%
  group_by(county_fips, year) %>%
  summarise(
    stem_completions = sum(ctotalt, na.rm = TRUE),
    n_institutions = n_distinct(unitid),
    .groups = "drop"
  ) %>%
  mutate(state_fips = substr(county_fips, 1, 2))

cat(sprintf("County-year STEM completions: %d obs, %d counties\n",
            nrow(ipeds_county), n_distinct(ipeds_county$county_fips)))

# National totals per year for Bartik shift
national_stem <- ipeds_comp %>%
  group_by(year) %>%
  summarise(national_completions = sum(ctotalt, na.rm = TRUE), .groups = "drop")
cat("\nNational STEM completions:\n")
print(national_stem)

dbExecute(con, "DETACH ipeds;")

# ===========================================================================
# 2. QWI: Information sector (NAICS 51) — county × quarter
# ===========================================================================
cat("\nFetching QWI Information sector data from Azure...\n")

qwi_info_sa <- dbGetQuery(con, "
  SELECT geography, year, quarter, industry,
         Emp as emp, EmpEnd as emp_end,
         HirA as hir_all, HirN as hir_new,
         Sep as sep,
         FrmJbGn as firm_job_gain, FrmJbLs as firm_job_loss,
         EarnS as earn_s
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry = '51'
    AND sex = 0
    AND agegrp = 'A00'
    AND year BETWEEN 2005 AND 2022
")

cat(sprintf("QWI Info SA: %d rows, %d counties, years %d-%d\n",
            nrow(qwi_info_sa), n_distinct(qwi_info_sa$geography),
            min(qwi_info_sa$year), max(qwi_info_sa$year)))

stopifnot("No QWI Info data" = nrow(qwi_info_sa) > 1000)

# Sex × Education breakdown for skill premium
cat("Fetching QWI education-level data...\n")

qwi_info_se <- dbGetQuery(con, "
  SELECT geography, year, quarter, industry,
         education,
         Emp as emp, EarnS as earn_s
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE industry = '51'
    AND sex = 0
    AND year BETWEEN 2005 AND 2022
")

cat(sprintf("QWI Info SE: %d rows\n", nrow(qwi_info_se)))

# Placebo: Accommodation/Food (NAICS 72)
cat("Fetching QWI Accommodation/Food (placebo)...\n")

qwi_food_sa <- dbGetQuery(con, "
  SELECT geography, year, quarter, industry,
         Emp as emp,
         HirA as hir_all,
         FrmJbGn as firm_job_gain, FrmJbLs as firm_job_loss,
         EarnS as earn_s
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry = '72'
    AND sex = 0
    AND agegrp = 'A00'
    AND year BETWEEN 2005 AND 2022
")

cat(sprintf("QWI Food SA (placebo): %d rows\n", nrow(qwi_food_sa)))

# ===========================================================================
# 3. Save all data
# ===========================================================================
saveRDS(ipeds_county, "../data/ipeds_county.rds")
saveRDS(national_stem, "../data/national_stem.rds")
saveRDS(qwi_info_sa, "../data/qwi_info_sa.rds")
saveRDS(qwi_info_se, "../data/qwi_info_se.rds")
saveRDS(qwi_food_sa, "../data/qwi_food_sa.rds")

dbDisconnect(con, shutdown = TRUE)

cat("\nAll data saved to ../data/\n")
