## ============================================================================
## 03_main_analysis.R — Main DiD estimation
## Effect of SRU carence declarations on RN vote share
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$code_commune), "communes\n")

## ============================================================================
## 1. SIMPLE DIFFERENCE-IN-DIFFERENCES (TWFE)
## ============================================================================

cat("\n=== TWFE Estimation ===\n")

## Primary specification: commune + year FE, clustered at commune
## Treatment: carencee × post (2022)
m1 <- feols(fn_rn_pct ~ treated:post | commune_id + year, data = panel,
            cluster = ~commune_id)
cat("Model 1 (basic TWFE):\n")
summary(m1)

## Add department × year trends
panel[, dept_year := paste0(dept, "_", year)]
m2 <- feols(fn_rn_pct ~ treated:post | commune_id + dept_year, data = panel,
            cluster = ~commune_id)
cat("\nModel 2 (dept × year FE):\n")
summary(m2)

## With housing gap as continuous treatment intensity
m3 <- feols(fn_rn_pct ~ housing_gap:post | commune_id + year, data = panel,
            cluster = ~commune_id)
cat("\nModel 3 (housing gap intensity):\n")
summary(m3)

## ============================================================================
## 2. EVENT STUDY (Pre-trends check)
## ============================================================================

cat("\n=== Event Study ===\n")

## Create relative time variable (treatment in 2018, midpoint of 2017-2019 period)
## Elections: 2002, 2007, 2012, 2017, 2022
## Relative to treatment: -16, -11, -6, -1, +4
panel[, rel_time := year - 2018]

## For treated communes, use actual relative time; for controls, assign NA treatment
## Use 2017 (rel_time = -1) as reference period
panel[, event_time := fifelse(treated == 1L, rel_time, NA_integer_)]

## Event study via interaction
panel[, year_fct := factor(year)]
panel[, treated_fct := factor(treated)]

## Manual event study: interact treated with year dummies (omit 2017)
es <- feols(fn_rn_pct ~ i(year, treated, ref = 2017) | commune_id + year,
            data = panel, cluster = ~commune_id)
cat("Event study:\n")
summary(es)

## Store coefficients for reporting
es_coefs <- as.data.table(coeftable(es), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
cat("\nEvent study coefficients:\n")
print(es_coefs)

## ============================================================================
## 3. CALLAWAY-SANT'ANNA DiD
## ============================================================================

cat("\n=== Callaway-Sant'Anna DiD ===\n")

## CS-DiD requires: outcome, time, unit id, group (first treatment time)
## With a single cohort (all treated at same time), CS reduces to standard DiD
## but provides proper inference

## Map election years to sequential periods for CS
year_map <- c("2002" = 1, "2007" = 2, "2012" = 3, "2017" = 4, "2022" = 5)
panel[, period := year_map[as.character(year)]]
panel[, cs_group := fifelse(treated == 1L, 5L, 0L)]  # treated at period 5 (2022 is first post)

## Actually: treatment is between period 4 (2017) and period 5 (2022)
## So first treated period = 5
cs_out <- tryCatch({
  att_gt(
    yname = "fn_rn_pct",
    tname = "period",
    idname = "commune_id",
    gname = "cs_group",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    est_method = "reg",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nCS-DiD group-time ATTs:\n")
  print(summary(cs_out))

  ## Aggregate: simple ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS-DiD simple aggregate ATT:\n")
  print(summary(cs_agg))

  ## Dynamic aggregation (event study)
  cs_dynamic <- aggte(cs_out, type = "dynamic")
  cat("\nCS-DiD dynamic (event study):\n")
  print(summary(cs_dynamic))
}

## ============================================================================
## 4. SAVE RESULTS
## ============================================================================

cat("\n=== Saving results ===\n")

## Save main results for table generation
results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  es = es,
  cs_out = if (!is.null(cs_out)) cs_out else NULL,
  es_coefs = es_coefs
)
saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

## Write diagnostics.json for validate_v1.py
diagnostics <- list(
  n_treated = uniqueN(panel[treated == 1]$commune_id),
  n_pre = sum(sort(unique(panel$year)) < 2022),
  n_obs = nrow(panel),
  n_communes = uniqueN(panel$commune_id),
  n_years = uniqueN(panel$year),
  outcome = "fn_rn_pct",
  treatment = "carencee_declaration",
  method = "TWFE_DiD_and_CS_DiD"
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics written:", toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\n=== Main analysis complete ===\n")
