## 03_main_analysis.R — Primary regressions
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

source("00_packages.R")

cat("=== Main Analysis ===\n")

# ------------------------------------------------------------------
# 1. Load analysis panel
# ------------------------------------------------------------------
panel <- fread("../data/sector_panel.csv")
stopifnot(nrow(panel) > 0)

cat(sprintf("Panel: %d obs, %d sectors, FY%d-FY%d\n",
            nrow(panel), uniqueN(panel$naics_2d),
            min(panel$fiscal_year), max(panel$fiscal_year)))

# ------------------------------------------------------------------
# 2. Callaway-Sant'Anna group-time ATT
# ------------------------------------------------------------------
cat("\n--- Callaway-Sant'Anna DiD ---\n")

# CS requires: yname, tname, idname, gname
# g = 0 for never-treated
cs_data <- as.data.frame(panel[!is.na(log_total_sb)])

# Outcome 1: Log SB set-aside procurement
cs_out1 <- tryCatch({
  att_gt(
    yname = "log_total_sb",
    tname = "fiscal_year",
    idname = "sector_id",
    gname = "g",
    data = cs_data,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("CS DiD error (log_total_sb): %s\n", e$message))
  NULL
})

if (!is.null(cs_out1)) {
  cs_agg1 <- aggte(cs_out1, type = "dynamic", min_e = -5, max_e = 5)
  cat("\nDynamic ATT (Log SB Procurement):\n")
  print(summary(cs_agg1))

  # Overall ATT
  cs_overall1 <- aggte(cs_out1, type = "simple")
  cat(sprintf("\nOverall ATT (Log SB): %.4f (SE: %.4f)\n",
              cs_overall1$overall.att, cs_overall1$overall.se))
}

# Outcome 2: HHI of SB procurement
cs_data_hhi <- as.data.frame(panel[!is.na(hhi_sb)])

cs_out2 <- tryCatch({
  att_gt(
    yname = "hhi_sb",
    tname = "fiscal_year",
    idname = "sector_id",
    gname = "g",
    data = cs_data_hhi,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("CS DiD error (hhi_sb): %s\n", e$message))
  NULL
})

if (!is.null(cs_out2)) {
  cs_agg2 <- aggte(cs_out2, type = "dynamic", min_e = -5, max_e = 5)
  cat("\nDynamic ATT (HHI of SB Procurement):\n")
  print(summary(cs_agg2))

  cs_overall2 <- aggte(cs_out2, type = "simple")
  cat(sprintf("\nOverall ATT (HHI): %.6f (SE: %.6f)\n",
              cs_overall2$overall.att, cs_overall2$overall.se))
}

# Outcome 3: Metro share
cs_data_metro <- as.data.frame(panel[!is.na(metro_share_sb)])

cs_out3 <- tryCatch({
  att_gt(
    yname = "metro_share_sb",
    tname = "fiscal_year",
    idname = "sector_id",
    gname = "g",
    data = cs_data_metro,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("CS DiD error (metro_share_sb): %s\n", e$message))
  NULL
})

if (!is.null(cs_out3)) {
  cs_agg3 <- aggte(cs_out3, type = "dynamic", min_e = -5, max_e = 5)
  cat("\nDynamic ATT (Metro Share):\n")
  print(summary(cs_agg3))

  cs_overall3 <- aggte(cs_out3, type = "simple")
  cat(sprintf("\nOverall ATT (Metro Share): %.4f (SE: %.4f)\n",
              cs_overall3$overall.att, cs_overall3$overall.se))
}

# Outcome 4: Number of counties receiving SB procurement
cs_out4 <- tryCatch({
  att_gt(
    yname = "n_counties_sb",
    tname = "fiscal_year",
    idname = "sector_id",
    gname = "g",
    data = cs_data,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("CS DiD error (n_counties_sb): %s\n", e$message))
  NULL
})

if (!is.null(cs_out4)) {
  cs_overall4 <- aggte(cs_out4, type = "simple")
  cat(sprintf("\nOverall ATT (N Counties): %.2f (SE: %.2f)\n",
              cs_overall4$overall.att, cs_overall4$overall.se))
}

# ------------------------------------------------------------------
# 3. TWFE comparison (for transparency)
# ------------------------------------------------------------------
cat("\n--- TWFE Comparison (fixest) ---\n")

# TWFE: log SB procurement
twfe1 <- feols(log_total_sb ~ post | sector_id + fiscal_year,
               data = panel, cluster = ~sector_id)
cat("\nTWFE: Log SB Procurement\n")
print(summary(twfe1))

# TWFE: HHI
twfe2 <- feols(hhi_sb ~ post | sector_id + fiscal_year,
               data = panel[!is.na(hhi_sb)], cluster = ~sector_id)
cat("\nTWFE: HHI of SB Procurement\n")
print(summary(twfe2))

# TWFE: Metro share
if (any(!is.na(panel$metro_share_sb))) {
  twfe3 <- feols(metro_share_sb ~ post | sector_id + fiscal_year,
                 data = panel[!is.na(metro_share_sb)], cluster = ~sector_id)
  cat("\nTWFE: Metro Share\n")
  print(summary(twfe3))
}

# TWFE: Number of counties
twfe4 <- feols(n_counties_sb ~ post | sector_id + fiscal_year,
               data = panel, cluster = ~sector_id)
cat("\nTWFE: N Counties with SB Procurement\n")
print(summary(twfe4))

# ------------------------------------------------------------------
# 4. Event study (TWFE)
# ------------------------------------------------------------------
cat("\n--- Event Study ---\n")

panel[, rel_year := fiscal_year - treat_year]
# Cap at -5 and +5
panel[, rel_year_capped := pmin(pmax(rel_year, -5L), 5L)]
# Never-treated: set rel_year to large negative (will be absorbed by FE)
panel[is.na(treat_year), rel_year := NA_integer_]
panel[is.na(treat_year), rel_year_capped := NA_integer_]

# Event study using fixest sunab()
es1 <- tryCatch({
  feols(log_total_sb ~ sunab(treat_year, fiscal_year) | sector_id + fiscal_year,
        data = panel[!is.na(treat_year)], cluster = ~sector_id)
}, error = function(e) {
  cat(sprintf("Event study error: %s\n", e$message))
  NULL
})

if (!is.null(es1)) {
  cat("\nEvent Study: Log SB Procurement (Sun-Abraham)\n")
  print(summary(es1))
}

# ------------------------------------------------------------------
# 5. Save results
# ------------------------------------------------------------------
results <- list()
if (!is.null(cs_out1)) results$cs_log_sb <- cs_overall1
if (!is.null(cs_out2)) results$cs_hhi <- cs_overall2
if (!is.null(cs_out3)) results$cs_metro <- cs_overall3
if (!is.null(cs_out4)) results$cs_n_counties <- cs_overall4
results$twfe1 <- twfe1
results$twfe2 <- twfe2
if (exists("twfe3")) results$twfe3 <- twfe3
results$twfe4 <- twfe4

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
n_treated_sectors <- uniqueN(panel[!is.na(treat_year)]$naics_2d)
n_pre <- min(panel[!is.na(treat_year), .(n_pre = treat_year - min(fiscal_year)), by = naics_2d]$n_pre)
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_sectors,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_sectors, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
