# =============================================================================
# 01_fetch_data.R — Fetch MLP panel, classify occupations, build analysis panel
# =============================================================================
# All heavy lifting done in DuckDB SQL to avoid loading 10M+ rows into R memory.
# Only the analysis-ready panel is pulled into R.
# =============================================================================

source("00_packages.R")
con <- azure_connect()

cat("=== Building Analysis Panel via DuckDB ===\n")

# -------------------------------------------------------------------------
# Create stacked decade-transition panel directly in SQL
# Transition 1: 1920→1930 (pre-SSA)
# Transition 2: 1930→1940 (post-SSA)
#
# OCC1950 SSA exclusion:
#   Farmers/Farm Managers: 100-123
#   Farm Laborers (wage): 820
#   Farm Laborers (unpaid): 830
#   Private Household: 700-720
# -------------------------------------------------------------------------

query <- "
WITH base AS (
  SELECT *,
    -- Classify 1920 occupation
    CASE
      WHEN occ1950_1920 BETWEEN 100 AND 123 THEN 'farmer'
      WHEN occ1950_1920 IN (810, 820, 830, 840) THEN 'farm_labor'
      WHEN occ1950_1920 BETWEEN 700 AND 720 THEN 'domestic'
      ELSE 'covered'
    END AS occ_cat_1920,
    -- Classify 1930 occupation
    CASE
      WHEN occ1950_1930 BETWEEN 100 AND 123 THEN 'farmer'
      WHEN occ1950_1930 IN (810, 820, 830, 840) THEN 'farm_labor'
      WHEN occ1950_1930 BETWEEN 700 AND 720 THEN 'domestic'
      ELSE 'covered'
    END AS occ_cat_1930,
    -- Classify 1940 occupation
    CASE
      WHEN occ1950_1940 BETWEEN 100 AND 123 THEN 'farmer'
      WHEN occ1950_1940 IN (810, 820, 830, 840) THEN 'farm_labor'
      WHEN occ1950_1940 BETWEEN 700 AND 720 THEN 'domestic'
      ELSE 'covered'
    END AS occ_cat_1940,
    -- Excluded flags
    (occ1950_1920 BETWEEN 100 AND 123 OR occ1950_1920 IN (810,820,830,840) OR occ1950_1920 BETWEEN 700 AND 720) AS excluded_1920,
    (occ1950_1930 BETWEEN 100 AND 123 OR occ1950_1930 IN (810,820,830,840) OR occ1950_1930 BETWEEN 700 AND 720) AS excluded_1930,
    (occ1950_1940 BETWEEN 100 AND 123 OR occ1950_1940 IN (810,820,830,840) OR occ1950_1940 BETWEEN 700 AND 720) AS excluded_1940
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE race_1930 IN (1, 2)
    AND age_1930 BETWEEN 15 AND 64
    AND occ1950_1930 BETWEEN 1 AND 970
    AND occ1950_1920 BETWEEN 1 AND 970
    AND occ1950_1940 BETWEEN 1 AND 970
)
-- Transition 1: 1920 → 1930 (pre-SSA)
SELECT
  histid_1930 AS histid,
  0 AS post_ssa,
  CASE WHEN race_1930 = 2 THEN 1 ELSE 0 END AS black,
  age_1920 AS age_start,
  sex_1920 AS sex,
  statefip_1920 AS state_start,
  countyicp_1920 AS county_start,
  occ1950_1920 AS occ_start,
  occ1950_1930 AS occ_end,
  occ_cat_1920 AS occ_cat_start,
  excluded_1920 AS excluded_start,
  CASE WHEN excluded_1920 AND NOT excluded_1930 THEN 1 ELSE 0 END AS switch_to_covered,
  CASE WHEN occ1950_1920 != occ1950_1930 THEN 1 ELSE 0 END AS occ_changed,
  sei_1920 AS sei_start,
  sei_1930 AS sei_end,
  sei_1930 - sei_1920 AS sei_gain,
  occscore_1920 AS occscore_start,
  marst_1920 AS marst_start,
  mover_20_30 AS mover,
  -- Manufacturing entry: operatives (600-690) or craftsmen (500-595)
  CASE WHEN excluded_1920 AND occ1950_1930 BETWEEN 500 AND 690 THEN 1 ELSE 0 END AS enter_manufacturing
FROM base

UNION ALL

-- Transition 2: 1930 → 1940 (post-SSA)
SELECT
  histid_1930 AS histid,
  1 AS post_ssa,
  CASE WHEN race_1930 = 2 THEN 1 ELSE 0 END AS black,
  age_1930 AS age_start,
  sex_1930 AS sex,
  statefip_1930 AS state_start,
  countyicp_1930 AS county_start,
  occ1950_1930 AS occ_start,
  occ1950_1940 AS occ_end,
  occ_cat_1930 AS occ_cat_start,
  excluded_1930 AS excluded_start,
  CASE WHEN excluded_1930 AND NOT excluded_1940 THEN 1 ELSE 0 END AS switch_to_covered,
  CASE WHEN occ1950_1930 != occ1950_1940 THEN 1 ELSE 0 END AS occ_changed,
  sei_1930 AS sei_start,
  sei_1940 AS sei_end,
  sei_1940 - sei_1930 AS sei_gain,
  occscore_1930 AS occscore_start,
  marst_1930 AS marst_start,
  mover_30_40 AS mover,
  CASE WHEN excluded_1930 AND occ1950_1940 BETWEEN 500 AND 690 THEN 1 ELSE 0 END AS enter_manufacturing
FROM base
"

cat("Running DuckDB query (this streams ~5GB from Azure)...\n")
panel <- dbGetQuery(con, query)
setDT(panel)
dbDisconnect(con, shutdown = TRUE)

cat("Panel extracted:", format(nrow(panel), big.mark = ","), "person-decade obs\n")

# -------------------------------------------------------------------------
# Derived variables (lightweight, in R)
# -------------------------------------------------------------------------
panel[, excluded_start := as.logical(excluded_start)]

# Detailed excluded category
panel[, excl_type := fifelse(occ_cat_start == "farmer", "farmer",
  fifelse(occ_cat_start == "farm_labor", "farm_labor",
    fifelse(occ_cat_start == "domestic", "domestic", "covered")))]

# Age bins
panel[, age_bin := cut(age_start, breaks = c(14, 24, 34, 44, 54, 65),
  labels = c("15-24", "25-34", "35-44", "45-54", "55-64"))]

# Young worker (under 45 = long pension horizon)
panel[, young := as.integer(age_start < 45)]

# South indicator
south_fips <- c(1, 5, 12, 13, 22, 28, 37, 45, 47, 48, 51)
panel[, south := as.integer(state_start %in% south_fips)]

# -------------------------------------------------------------------------
# Summary statistics
# -------------------------------------------------------------------------
cat("\n=== Summary: Switching Rates by Race × Occupation × Decade ===\n")
summ <- panel[excluded_start == TRUE,
  .(switch_rate = mean(switch_to_covered), n = .N),
  by = .(black, occ_cat_start, post_ssa)]
print(summ[order(black, occ_cat_start, post_ssa)])

cat("\n=== Raw DiD (all excluded workers) ===\n")
dd <- panel[excluded_start == TRUE,
  .(switch_rate = mean(switch_to_covered)),
  by = .(black, post_ssa)]
print(dd[order(black, post_ssa)])

w_pre <- dd[black == 0 & post_ssa == 0, switch_rate]
w_post <- dd[black == 0 & post_ssa == 1, switch_rate]
b_pre <- dd[black == 1 & post_ssa == 0, switch_rate]
b_post <- dd[black == 1 & post_ssa == 1, switch_rate]
cat(sprintf("White: %.3f → %.3f (Δ=%.3f)\n", w_pre, w_post, w_post - w_pre))
cat(sprintf("Black: %.3f → %.3f (Δ=%.3f)\n", b_pre, b_post, b_post - b_pre))
cat(sprintf("DiD: %.4f\n", (b_post - b_pre) - (w_post - w_pre)))

# -------------------------------------------------------------------------
# Validate
# -------------------------------------------------------------------------
stopifnot(sum(panel$black == 1) > 10000)
stopifnot(sum(panel$excluded_start) > 100000)
stopifnot(nrow(panel) > 1000000)
cat("\n=== Validation passed ===\n")

# -------------------------------------------------------------------------
# Save (should be ~200-400MB as RDS)
# -------------------------------------------------------------------------
cat("Saving analysis panel...\n")
saveRDS(panel, "../data/analysis_panel.rds")
cat("Saved to data/analysis_panel.rds\n")
cat("Final N:", format(nrow(panel), big.mark = ","), "\n")
