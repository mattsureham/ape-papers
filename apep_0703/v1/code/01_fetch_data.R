# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure
# Marijuana legalization and labor market firm dynamics
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

stopifnot(apep_azure_available())
con <- apep_azure_connect()

# ---------------------------------------------------------------------------
# QWI sex x age x NAICS sector — primary dataset for firm dynamics
# Columns: year, quarter, geography (state FIPS), industry, ind_level,
#   Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs, EarnS, etc.
# ---------------------------------------------------------------------------
cat("Fetching QWI sa/ns from Azure (aggregating over sex and age)...\n")

qwi_sa <- apep_azure_query(con, "
  SELECT
    geography AS state_fips,
    year,
    quarter,
    ind_level,
    industry,
    SUM(\"Emp\") AS emp,
    SUM(\"EmpEnd\") AS emp_end,
    SUM(\"HirA\") AS hir_a,
    SUM(\"HirN\") AS hir_n,
    SUM(\"Sep\") AS sep,
    SUM(\"FrmJbGn\") AS frm_jb_gn,
    SUM(\"FrmJbLs\") AS frm_jb_ls,
    AVG(\"EarnS\") AS earn_s
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE ind_level IN ('S', 'A')
    AND \"Emp\" IS NOT NULL
    AND geo_level = 'S'
    AND year >= 2005
    AND year <= 2024
  GROUP BY geography, year, quarter, ind_level, industry
  ORDER BY geography, year, quarter, industry
")

cat("QWI sa/ns rows after aggregation:", nrow(qwi_sa), "\n")
stopifnot(nrow(qwi_sa) > 50000)

# ---------------------------------------------------------------------------
# QWI race x ethnicity — for demographic heterogeneity (all-industry only)
# ---------------------------------------------------------------------------
cat("Fetching QWI rh/ns from Azure...\n")

qwi_rh <- apep_azure_query(con, "
  SELECT
    geography AS state_fips,
    year,
    quarter,
    industry,
    race,
    ethnicity,
    SUM(\"Emp\") AS emp,
    SUM(\"HirA\") AS hir_a,
    AVG(\"EarnS\") AS earn_s
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE ind_level = 'A'
    AND \"Emp\" IS NOT NULL
    AND industry = '00'
    AND geo_level = 'S'
    AND year >= 2005
    AND year <= 2024
  GROUP BY geography, year, quarter, industry, race, ethnicity
  ORDER BY geography, year, quarter, race, ethnicity
")

cat("QWI rh/ns rows after aggregation:", nrow(qwi_rh), "\n")

# ---------------------------------------------------------------------------
# QWI sex x age — for age heterogeneity (all industries aggregated)
# ---------------------------------------------------------------------------
cat("Fetching QWI sa/ns age breakdown from Azure...\n")

qwi_age <- apep_azure_query(con, "
  SELECT
    geography AS state_fips,
    year,
    quarter,
    agegrp,
    SUM(\"Emp\") AS emp,
    SUM(\"HirA\") AS hir_a,
    AVG(\"EarnS\") AS earn_s
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE ind_level = 'A'
    AND industry = '00'
    AND \"Emp\" IS NOT NULL
    AND geo_level = 'S'
    AND year >= 2005
    AND year <= 2024
  GROUP BY geography, year, quarter, agegrp
  ORDER BY geography, year, quarter, agegrp
")

cat("QWI age breakdown rows:", nrow(qwi_age), "\n")

apep_azure_disconnect(con)

# ---------------------------------------------------------------------------
# Save to local data/
# ---------------------------------------------------------------------------
saveRDS(qwi_sa, "../data/qwi_state_industry.rds")
saveRDS(qwi_rh, "../data/qwi_race_ethnicity.rds")
saveRDS(qwi_age, "../data/qwi_age.rds")

cat("Data saved to data/\n")
cat("  qwi_state_industry.rds:", nrow(qwi_sa), "rows\n")
cat("  qwi_race_ethnicity.rds:", nrow(qwi_rh), "rows\n")
cat("  qwi_age.rds:", nrow(qwi_age), "rows\n")
