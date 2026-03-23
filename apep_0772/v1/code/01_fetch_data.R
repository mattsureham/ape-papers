# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ---------------------------------------------------------------------------
# 1. NAICS 72 (Accommodation and Food Services) — race x ethnicity panel
# ---------------------------------------------------------------------------
cat("Fetching NAICS 72 race/ethnicity data from Azure...\n")
qwi_72 <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity, industry,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, EarnS, TurnOvrS,
         sEmp, sEmpEnd, sHirA, sSep, sEarnS, sTurnOvrS
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '72'
    AND geo_level = 'C'
    AND ownercode = 'A05'
    AND year BETWEEN 2013 AND 2022
    AND race IN ('A0', 'A2')
    AND ethnicity = 'A1'
")
cat(sprintf("NAICS 72: %d rows fetched.\n", nrow(qwi_72)))

# ---------------------------------------------------------------------------
# 2. NAICS 23 (Construction) — placebo industry
# ---------------------------------------------------------------------------
cat("Fetching NAICS 23 placebo data...\n")
qwi_23 <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity, industry,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, EarnS, TurnOvrS,
         sEmp, sEmpEnd, sHirA, sSep, sEarnS, sTurnOvrS
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '23'
    AND geo_level = 'C'
    AND ownercode = 'A05'
    AND year BETWEEN 2013 AND 2022
    AND race IN ('A0', 'A2')
    AND ethnicity = 'A1'
")
cat(sprintf("NAICS 23: %d rows fetched.\n", nrow(qwi_23)))

apep_azure_disconnect(con)

# ---------------------------------------------------------------------------
# 3. Combine and save
# ---------------------------------------------------------------------------
qwi <- bind_rows(qwi_72, qwi_23)

# Validate: no empty data
stopifnot("No NAICS 72 data fetched" = nrow(qwi_72) > 0)
stopifnot("No NAICS 23 data fetched" = nrow(qwi_23) > 0)

saveRDS(qwi, "../data/qwi_raw.rds")
cat(sprintf("Saved %d total rows to data/qwi_raw.rds\n", nrow(qwi)))
cat(sprintf("  NAICS 72: %d rows\n", nrow(qwi_72)))
cat(sprintf("  NAICS 23: %d rows\n", nrow(qwi_23)))
cat(sprintf("  Race A0 (all): %d | Race A2 (Black): %d\n",
            sum(qwi$race == "A0"), sum(qwi$race == "A2")))
cat(sprintf("  Year range: %d-%d\n", min(qwi$year), max(qwi$year)))
cat(sprintf("  Counties: %d\n", n_distinct(qwi$geography)))
