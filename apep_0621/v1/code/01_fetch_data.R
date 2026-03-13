# =============================================================================
# 01_fetch_data.R — Fetch data from Azure MLP panels via DuckDB
# APEP Working Paper apep_0621
# =============================================================================
# Data source: IPUMS Multigenerational Longitudinal Panel on Azure Blob Storage
# All queries run out-of-core via DuckDB — no full dataset loaded into R memory.
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

stopifnot(apep_azure_available())
con <- apep_azure_connect()

# =============================================================================
# Mothers' Pension Adoption Dates (from Aizer et al. 2016 AER / Children's Bureau)
# =============================================================================
mp_dates <- data.frame(
  statefip = c(17, 6, 8, 16, 19, 25, 26, 27, 31, 33, 34, 32, 39, 41, 42, 46,
               49, 53, 55, 20, 30, 36, 38, 40, 47, 54, 56, 24, 4, 5, 10, 23,
               29, 48, 50, 51, 9, 12, 18, 22, 37, 44, 11, 21, 28, 1, 35),
  state_name = c("IL", "CA", "CO", "ID", "IA", "MA", "MI", "MN", "NE", "NH",
                 "NJ", "NV", "OH", "OR", "PA", "SD", "UT", "WA", "WI",
                 "KS", "MT", "NY", "ND", "OK", "TN", "WV", "WY", "MD",
                 "AZ", "AR", "DE", "ME", "MO", "TX", "VT", "VA",
                 "CT", "FL", "IN", "LA", "NC", "RI", "DC", "KY", "MS",
                 "AL", "NM"),
  mp_year = c(1911, 1913, 1913, 1913, 1913, 1913, 1913, 1913, 1913, 1913,
              1913, 1913, 1913, 1913, 1913, 1913, 1913, 1913, 1913,
              1915, 1915, 1915, 1915, 1915, 1915, 1915, 1915, 1916,
              1917, 1917, 1917, 1917, 1917, 1917, 1917, 1918,
              1919, 1919, 1919, 1920, 1920, 1920, 1926, 1928, 1928,
              1931, 1931),
  stringsAsFactors = FALSE
)

saveRDS(mp_dates, "../data/mp_adoption_dates.rds")
cat("Mothers' pension adoption dates: ", nrow(mp_dates), " states\n")
cat("Adopted by 1919 (treated in primary design): ",
    sum(mp_dates$mp_year <= 1919), " states\n")

# =============================================================================
# Design 1 (Short-run): State-level child labor & schooling from 1910-1920 panel
# =============================================================================
# Available columns: statefip_1910, age_1910, sex_1910, race_1910, school_1910,
#   occ1950_1910, occscore_1910, classwkr_1910, farm_1910, lit_1910,
#   statefip_1920, age_1920, sex_1920, occ1950_1920, school_1920, etc.
# No labforce variable — use occ1950 > 0 AND occ1950 < 979 as working indicator
# =============================================================================
cat("\n=== Fetching 1910-1920 state-level aggregates ===\n")

state_child_labor <- apep_azure_query(con, "
  SELECT
    statefip_1910 AS statefip,
    COUNT(*) AS n_children,
    -- 1910 outcomes (pre-treatment)
    AVG(CASE WHEN occ1950_1910 > 0 AND occ1950_1910 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1910,
    AVG(CASE WHEN school_1910 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1910,
    AVG(age_1910) AS mean_age_1910,
    AVG(CASE WHEN sex_1910 = 1 THEN 1.0 ELSE 0.0 END) AS share_male,
    AVG(CASE WHEN race_1910 = 1 THEN 1.0 ELSE 0.0 END) AS share_white,
    AVG(lit_1910) AS mean_literacy_1910,
    -- 1920 outcomes (post-treatment for early adopters)
    AVG(CASE WHEN occ1950_1920 > 0 AND occ1950_1920 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1920,
    AVG(CASE WHEN school_1920 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1920,
    AVG(CASE WHEN occ1950_1920 > 0 AND occ1950_1920 < 979 THEN occscore_1920 ELSE NULL END) AS mean_occscore_1920
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE age_1910 BETWEEN 8 AND 14
  GROUP BY statefip_1910
  HAVING COUNT(*) >= 100
  ORDER BY statefip_1910
")

cat("Short-run panel: ", nrow(state_child_labor), " states\n")
cat("Total children: ", format(sum(state_child_labor$n_children), big.mark = ","), "\n")

# Reshape to long panel (state × year)
panel_short <- rbind(
  data.frame(
    statefip = state_child_labor$statefip,
    year = 1910,
    child_labor = state_child_labor$child_labor_1910,
    school_attend = state_child_labor$school_attend_1910,
    n_children = state_child_labor$n_children
  ),
  data.frame(
    statefip = state_child_labor$statefip,
    year = 1920,
    child_labor = state_child_labor$child_labor_1920,
    school_attend = state_child_labor$school_attend_1920,
    n_children = state_child_labor$n_children
  )
)

# Merge MP adoption dates
panel_short <- merge(panel_short, mp_dates[, c("statefip", "mp_year")],
                     by = "statefip", all.x = TRUE)
panel_short$mp_year[is.na(panel_short$mp_year)] <- 0
panel_short$first_treat <- ifelse(panel_short$mp_year <= 1919, panel_short$mp_year, 0)

saveRDS(panel_short, "../data/panel_short.rds")
saveRDS(state_child_labor, "../data/state_child_labor_raw.rds")

# =============================================================================
# Design 2 (Long-run): State-level adult outcomes from 1920-1940 panel
# =============================================================================
cat("\n=== Fetching 1920-1940 state-level aggregates ===\n")

state_long_run <- apep_azure_query(con, "
  SELECT
    statefip_1920 AS statefip,
    COUNT(*) AS n_children,
    -- 1920 baseline characteristics
    AVG(age_1920) AS mean_age_1920,
    AVG(CASE WHEN sex_1920 = 1 THEN 1.0 ELSE 0.0 END) AS share_male,
    AVG(CASE WHEN race_1920 = 1 THEN 1.0 ELSE 0.0 END) AS share_white,
    AVG(CASE WHEN school_1920 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1920,
    -- 1930 intermediate outcomes
    AVG(CASE WHEN school_1930 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1930,
    -- 1940 adult outcomes
    AVG(sei_1940) AS mean_sei_1940,
    AVG(occscore_1940) AS mean_occscore_1940,
    STDDEV(sei_1940) AS sd_sei_1940,
    STDDEV(occscore_1940) AS sd_occscore_1940,
    AVG(CASE WHEN occ1950_1940 > 0 AND occ1950_1940 < 979 THEN 1.0 ELSE 0.0 END) AS lfp_1940,
    AVG(CASE WHEN farm_1940 = 2 THEN 1.0 ELSE 0.0 END) AS farm_1940,
    AVG(CASE WHEN ownershp_1940 = 1 THEN 1.0 ELSE 0.0 END) AS homeowner_1940
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE age_1920 BETWEEN 0 AND 10
  GROUP BY statefip_1920
  HAVING COUNT(*) >= 100
  ORDER BY statefip_1920
")

cat("Long-run panel: ", nrow(state_long_run), " states\n")
cat("Total children: ", format(sum(state_long_run$n_children), big.mark = ","), "\n")

# Merge MP adoption dates
state_long_run <- merge(state_long_run, mp_dates[, c("statefip", "mp_year", "state_name")],
                        by = "statefip", all.x = TRUE)
state_long_run$mp_year[is.na(state_long_run$mp_year)] <- 0

saveRDS(state_long_run, "../data/state_long_run.rds")

# =============================================================================
# Design 2b: Heterogeneity by sex (long-run)
# =============================================================================
cat("\n=== Fetching sex-specific long-run aggregates ===\n")

state_long_bysex <- apep_azure_query(con, "
  SELECT
    statefip_1920 AS statefip,
    sex_1920 AS sex,
    COUNT(*) AS n_children,
    AVG(sei_1940) AS mean_sei_1940,
    AVG(occscore_1940) AS mean_occscore_1940,
    STDDEV(sei_1940) AS sd_sei_1940,
    AVG(CASE WHEN occ1950_1940 > 0 AND occ1950_1940 < 979 THEN 1.0 ELSE 0.0 END) AS lfp_1940,
    AVG(CASE WHEN school_1930 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1930
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE age_1920 BETWEEN 0 AND 10
  GROUP BY statefip_1920, sex_1920
  HAVING COUNT(*) >= 50
  ORDER BY statefip_1920, sex_1920
")

saveRDS(state_long_bysex, "../data/state_long_bysex.rds")
cat("Sex-specific aggregates: ", nrow(state_long_bysex), " state-sex cells\n")

# =============================================================================
# Design 2c: Heterogeneity by race (long-run)
# =============================================================================
cat("\n=== Fetching race-specific long-run aggregates ===\n")

state_long_byrace <- apep_azure_query(con, "
  SELECT
    statefip_1920 AS statefip,
    CASE WHEN race_1920 = 1 THEN 'white' ELSE 'nonwhite' END AS race_group,
    COUNT(*) AS n_children,
    AVG(sei_1940) AS mean_sei_1940,
    AVG(occscore_1940) AS mean_occscore_1940,
    STDDEV(sei_1940) AS sd_sei_1940,
    AVG(CASE WHEN occ1950_1940 > 0 AND occ1950_1940 < 979 THEN 1.0 ELSE 0.0 END) AS lfp_1940
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE age_1920 BETWEEN 0 AND 10
  GROUP BY statefip_1920, CASE WHEN race_1920 = 1 THEN 'white' ELSE 'nonwhite' END
  HAVING COUNT(*) >= 50
  ORDER BY statefip_1920
")

saveRDS(state_long_byrace, "../data/state_long_byrace.rds")
cat("Race-specific aggregates: ", nrow(state_long_byrace), " state-race cells\n")

# =============================================================================
# Design 1b: Heterogeneity by sex (short-run child labor)
# =============================================================================
cat("\n=== Fetching sex-specific short-run aggregates ===\n")

state_short_bysex <- apep_azure_query(con, "
  SELECT
    statefip_1910 AS statefip,
    sex_1910 AS sex,
    COUNT(*) AS n_children,
    AVG(CASE WHEN occ1950_1910 > 0 AND occ1950_1910 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1910,
    AVG(CASE WHEN school_1910 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1910,
    AVG(CASE WHEN occ1950_1920 > 0 AND occ1950_1920 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1920,
    AVG(CASE WHEN school_1920 = 2 THEN 1.0 ELSE 0.0 END) AS school_attend_1920
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE age_1910 BETWEEN 8 AND 14
  GROUP BY statefip_1910, sex_1910
  HAVING COUNT(*) >= 50
  ORDER BY statefip_1910, sex_1910
")

saveRDS(state_short_bysex, "../data/state_short_bysex.rds")
cat("Sex-specific short-run aggregates: ", nrow(state_short_bysex), " state-sex cells\n")

# =============================================================================
# Placebo: Children aged 15-18 in 1910 (already working age)
# =============================================================================
cat("\n=== Fetching placebo data (older children) ===\n")

placebo_old <- apep_azure_query(con, "
  SELECT
    statefip_1910 AS statefip,
    COUNT(*) AS n_children,
    AVG(CASE WHEN occ1950_1910 > 0 AND occ1950_1910 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1910,
    AVG(CASE WHEN occ1950_1920 > 0 AND occ1950_1920 < 979 THEN 1.0 ELSE 0.0 END) AS child_labor_1920
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE age_1910 BETWEEN 15 AND 18
  GROUP BY statefip_1910
  HAVING COUNT(*) >= 100
  ORDER BY statefip_1910
")

saveRDS(placebo_old, "../data/placebo_old.rds")
cat("Placebo data: ", nrow(placebo_old), " states, ",
    format(sum(placebo_old$n_children), big.mark = ","), " older children\n")

# =============================================================================
# Cleanup
# =============================================================================
apep_azure_disconnect(con)
cat("\n=== Data fetch complete ===\n")
cat("Files saved to ../data/\n")
