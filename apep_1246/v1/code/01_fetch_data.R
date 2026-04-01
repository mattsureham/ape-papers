# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for NAICS 623 and 624
# =============================================================================

source("00_packages.R")

# Read Azure connection string directly from .env (shell may truncate at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (ln in env_lines) {
  ln <- trimws(ln)
  if (startsWith(ln, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^[^=]+=", "", ln)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}
cat("Azure CS length:", nchar(Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")), "\n")

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()
cat("Connected to Azure.\n")

# -----------------------------------------------------------------------
# 1. Fetch QWI sex-by-age data for NAICS 623 and 624 (3-digit)
# -----------------------------------------------------------------------
cat("Fetching QWI sex×age data for NAICS 623 and 624...\n")

qwi_sa <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    year, quarter,
    industry,
    sex, agegrp,
    Emp, EmpEnd, EmpS, HirA, HirN, Sep,
    EarnS, EarnBeg,
    sEmp, sEmpEnd, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('623', '624')
    AND year >= 2015
    AND agegrp != 'A00'
    AND sex != 0
")
cat(sprintf("  QWI sa: %s rows\n", format(nrow(qwi_sa), big.mark = ",")))

# -----------------------------------------------------------------------
# 2. Fetch QWI race-by-ethnicity data for NAICS 623 and 624
# -----------------------------------------------------------------------
cat("Fetching QWI race×ethnicity data for NAICS 623 and 624...\n")

qwi_rh <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    year, quarter,
    industry,
    race, ethnicity,
    Emp, EmpEnd, EmpS, HirA, HirN, Sep,
    EarnS, EarnBeg,
    sEmp, sEmpEnd, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry IN ('623', '624')
    AND year >= 2015
    AND race != 'A0'
    AND ethnicity != 'A0'
")
cat(sprintf("  QWI rh: %s rows\n", format(nrow(qwi_rh), big.mark = ",")))

apep_azure_disconnect(con)

# -----------------------------------------------------------------------
# 3. State vaccine mandate dates (from KFF, NASHP, published sources)
# -----------------------------------------------------------------------
# States that adopted healthcare worker vaccine mandates BEFORE the
# CMS federal mandate (announced Nov 5, 2021; enforced ~Jan-Mar 2022).
# Treatment quarter = quarter in which mandate became effective.

mandate_states <- data.table(
  state_fips = c(
    "06",  # California — effective 2021-09-30
    "08",  # Colorado — effective 2021-10-31
    "09",  # Connecticut — effective 2021-09-27
    "10",  # Delaware — effective 2021-11-01
    "17",  # Illinois — effective 2021-11-01
    "23",  # Maine — effective 2021-10-01
    "24",  # Maryland — effective 2021-10-01
    "25",  # Massachusetts — effective 2021-10-31
    "34",  # New Jersey — effective 2021-11-01
    "35",  # New Mexico — effective 2021-09-30
    "36",  # New York — effective 2021-09-27
    "41",  # Oregon — effective 2021-10-18
    "44",  # Rhode Island — effective 2021-10-01
    "53"   # Washington — effective 2021-10-18
  ),
  mandate_year = 2021L,
  mandate_quarter = c(
    3L, 4L, 3L, 4L, 4L,  # CA, CO, CT, DE, IL
    4L, 4L, 4L, 4L, 3L,  # ME, MD, MA, NJ, NM
    3L, 4L, 4L, 4L        # NY, OR, RI, WA
  )
)

# Create mandate quarter variable (quarters since 2015Q1)
mandate_states[, mandate_qtr := (mandate_year - 2015L) * 4L + mandate_quarter]

cat(sprintf("  %d states with pre-CMS vaccine mandates\n", nrow(mandate_states)))

# -----------------------------------------------------------------------
# 4. Save raw data
# -----------------------------------------------------------------------
dir.create("../data", showWarnings = FALSE, recursive = TRUE)
saveRDS(qwi_sa, "../data/qwi_sa_raw.rds")
saveRDS(qwi_rh, "../data/qwi_rh_raw.rds")
saveRDS(mandate_states, "../data/mandate_states.rds")

# Validate: data fetched from Azure QWI
stopifnot(nrow(qwi_sa) > 0, nrow(qwi_rh) > 0)
cat("Data saved to data/.\n")
