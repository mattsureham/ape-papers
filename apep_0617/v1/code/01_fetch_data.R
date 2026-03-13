## 01_fetch_data.R — Fetch QWI data from Azure and construct state-year panel
## Data source: Census QWI on Azure Blob Storage (derived/qwi/se/ns/*.parquet)

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

stopifnot(apep_azure_available())
con <- apep_azure_connect()

# ============================================================
# Step 1: Explore data structure
# ============================================================
cat("=== Checking QWI data structure ===\n")
sample_df <- DBI::dbGetQuery(con, "
  SELECT * FROM 'az://derived/qwi/se/ns/ny.parquet' LIMIT 5
")
cat("Columns:", paste(names(sample_df), collapse = ", "), "\n")
cat("Sample rows:\n")
print(head(sample_df, 3))

# ============================================================
# Step 2: Aggregate QWI to state x year x industry x sex x education
# ============================================================
cat("\n=== Aggregating QWI data from all states ===\n")
cat("This reads ~123M rows across 51 state files...\n")

# Read and aggregate using DuckDB SQL (memory-efficient)
df_qwi <- DBI::dbGetQuery(con, "
  SELECT
    SUBSTR(CAST(geography AS VARCHAR), 1, 2) as statefip,
    year,
    industry,
    sex,
    education,
    SUM(\"Emp\") as total_emp,
    -- Weighted average earnings (weight by employment)
    SUM(\"Emp\" * \"EarnS\") / NULLIF(SUM(\"Emp\"), 0) as avg_earnings,
    SUM(\"HirA\") as total_hires,
    SUM(\"Sep\") as total_sep,
    COUNT(DISTINCT geography) as n_counties
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE year >= 2001
    AND year <= 2023
    AND sex IN (1, 2)
    AND education IN ('E1', 'E2', 'E3', 'E4', 'E5')
    AND industry != '00'
  GROUP BY 1, 2, 3, 4, 5
  ORDER BY 1, 2, 3, 4, 5
")

cat(sprintf("  Fetched %s state-year-industry-sex-education cells\n", format(nrow(df_qwi), big.mark = ",")))
cat(sprintf("  States: %d\n", length(unique(df_qwi$statefip))))
cat(sprintf("  Years: %d-%d\n", min(df_qwi$year), max(df_qwi$year)))
cat(sprintf("  Industries: %d\n", length(unique(df_qwi$industry))))

apep_azure_disconnect(con)

# ============================================================
# Step 3: Save raw aggregated data
# ============================================================
df_qwi <- as.data.table(df_qwi)

# Convert types
df_qwi[, statefip := as.character(statefip)]
df_qwi[, total_emp := as.numeric(total_emp)]
df_qwi[, avg_earnings := as.numeric(avg_earnings)]
df_qwi[, total_hires := as.numeric(total_hires)]
df_qwi[, total_sep := as.numeric(total_sep)]

fwrite(df_qwi, "../data/qwi_state_year_ind_sex_edu.csv")
cat(sprintf("\nSaved: ../data/qwi_state_year_ind_sex_edu.csv (%s rows)\n",
            format(nrow(df_qwi), big.mark = ",")))

# ============================================================
# Step 4: Quick validation
# ============================================================
cat("\n=== Validation checks ===\n")

# Check women employment by education
women <- df_qwi[sex == 2 & year == 2015]
low_edu <- women[education %in% c("E1", "E2")]
high_edu <- women[education %in% c("E4", "E5")]

cat(sprintf("Low-edu women (E1+E2) total employment 2015: %s\n",
            format(sum(low_edu$total_emp, na.rm = TRUE), big.mark = ",")))
cat(sprintf("High-edu women (E4+E5) total employment 2015: %s\n",
            format(sum(high_edu$total_emp, na.rm = TRUE), big.mark = ",")))

# Top industries for low-edu women
ind_emp <- low_edu[, .(emp = sum(total_emp, na.rm = TRUE)), by = industry]
setorder(ind_emp, -emp)
cat("\nTop 5 industries for low-edu women (2015):\n")
print(head(ind_emp, 5))

cat("\n=== Data fetch complete ===\n")
