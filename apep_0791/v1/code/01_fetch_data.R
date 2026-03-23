# ==============================================================================
# 01_fetch_data.R — Data Acquisition from IPEDS DuckDB
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

source("00_packages.R")

# ---- 1. Connect to local IPEDS DuckDB ----
db_path <- file.path("..", "data", "ipeds.duckdb")
stopifnot("IPEDS DuckDB not found — download from Azure first" = file.exists(db_path))

con <- dbConnect(duckdb(), dbdir = db_path, read_only = TRUE)
cat("Connected to IPEDS DuckDB\n")

# ---- 2. Query institution characteristics ----
cat("Querying institution characteristics...\n")
inst <- dbGetQuery(con, "
  SELECT unitid, year, institution_name, state, fips_state,
         sector, control, currently_active, hbcu
  FROM hd
  WHERE sector IN (3, 4, 6, 9)
    AND year BETWEEN 2007 AND 2023
")
cat(sprintf("  Institution-years: %d\n", nrow(inst)))
stopifnot(nrow(inst) > 0)

# ---- 3. Query completions by race ----
cat("Querying completions by race (sub-bachelor awards)...\n")
comp <- dbGetQuery(con, "
  SELECT unitid, year,
         SUM(COALESCE(ctotalt, 0)) AS total_comp,
         SUM(COALESCE(cbkaat, 0))  AS black_comp,
         SUM(COALESCE(chispt, 0))  AS hisp_comp,
         SUM(COALESCE(cwhitt, 0))  AS white_comp,
         SUM(COALESCE(casiat, 0))  AS asian_comp
  FROM c_a
  WHERE award_level IN (1, 2, 3)
    AND year BETWEEN 2007 AND 2023
    AND major_number = 1
  GROUP BY unitid, year
")
cat(sprintf("  Completion records: %d\n", nrow(comp)))
stopifnot(nrow(comp) > 0)

# ---- 4. Query total completions (all award levels) for robustness ----
cat("Querying total completions (all award levels)...\n")
comp_all <- dbGetQuery(con, "
  SELECT unitid, year,
         SUM(COALESCE(ctotalt, 0)) AS total_comp_all,
         SUM(COALESCE(cbkaat, 0))  AS black_comp_all,
         SUM(COALESCE(chispt, 0))  AS hisp_comp_all,
         SUM(COALESCE(cwhitt, 0))  AS white_comp_all
  FROM c_a
  WHERE year BETWEEN 2007 AND 2023
    AND major_number = 1
  GROUP BY unitid, year
")
cat(sprintf("  All-award completion records: %d\n", nrow(comp_all)))

dbDisconnect(con, shutdown = TRUE)
cat("Disconnected from DuckDB\n")

# ---- 5. Save raw extracts ----
saveRDS(inst, file.path("..", "data", "ipeds_institutions.rds"))
saveRDS(comp, file.path("..", "data", "ipeds_completions_subbachelor.rds"))
saveRDS(comp_all, file.path("..", "data", "ipeds_completions_all.rds"))

cat("Data saved to data/\n")
cat(sprintf("  Unique institutions: %d\n", length(unique(inst$unitid))))
cat(sprintf("  Year range: %d-%d\n", min(inst$year), max(inst$year)))
