## 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
## apep_0806: Ireland Rent Pressure Zones

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat("Panel dimensions:", nrow(panel), "obs,", n_distinct(panel$county), "counties\n")
cat("Treatment cohorts:\n")
print(table(panel$first_treat[!duplicated(panel$county)]))

# ── 1. Callaway-Sant'Anna: log rent levels ───────────────────────────────
# Use not-yet-treated as control group (no pure never-treated after 2021Q3)
cat("\n=== Callaway-Sant'Anna: Log Rent ===\n")

cs_level <- att_gt(
  yname      = "log_rent",
  tname      = "time_id",
  idname     = "county_id",
  gname      = "first_treat",
  data       = panel,
  control_group = "notyettreated",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
summary(cs_level)

# ── 2. Aggregate: overall ATT ────────────────────────────────────────────
agg_overall <- aggte(cs_level, type = "simple")
cat("\nOverall ATT (log rent):\n")
summary(agg_overall)

# ── 3. Dynamic/event-study aggregation ───────────────────────────────────
agg_dynamic <- aggte(cs_level, type = "dynamic", min_e = -12, max_e = 20)
cat("\nDynamic ATT (event study):\n")
summary(agg_dynamic)

# ── 4. Group-specific ATTs ───────────────────────────────────────────────
agg_group <- aggte(cs_level, type = "group")
cat("\nGroup-specific ATTs:\n")
summary(agg_group)

# ── 5. Year-on-year rent growth as outcome ───────────────────────────────
cat("\n=== Callaway-Sant'Anna: YoY Rent Growth ===\n")

panel_growth <- panel %>% filter(!is.na(rent_growth_yy))

cs_growth <- att_gt(
  yname      = "rent_growth_yy",
  tname      = "time_id",
  idname     = "county_id",
  gname      = "first_treat",
  data       = panel_growth,
  control_group = "notyettreated",
  base_period = "universal"
)

agg_growth_overall <- aggte(cs_growth, type = "simple")
cat("\nOverall ATT (YoY growth):\n")
summary(agg_growth_overall)

agg_growth_dynamic <- aggte(cs_growth, type = "dynamic", min_e = -12, max_e = 20)

# ── 6. TWFE for comparison (with caveats) ────────────────────────────────
cat("\n=== TWFE OLS (for comparison) ===\n")

twfe <- feols(
  log_rent ~ post_rpz | county_id + time_id,
  data = panel,
  cluster = ~county_id
)
cat("\nTWFE coefficient:\n")
print(summary(twfe))

# ── 7. Save results ──────────────────────────────────────────────────────
results <- list(
  cs_level         = cs_level,
  agg_overall      = agg_overall,
  agg_dynamic      = agg_dynamic,
  agg_group        = agg_group,
  cs_growth        = cs_growth,
  agg_growth_overall = agg_growth_overall,
  agg_growth_dynamic = agg_growth_dynamic,
  twfe             = twfe
)

saveRDS(results, "../data/main_results.rds")

# ── 8. Diagnostics for validator ─────────────────────────────────────────
diag <- list(
  n_treated = n_distinct(panel$county),  # All 26 counties eventually treated
  n_pre     = sum(panel$time_id[!duplicated(panel$time_id)] < min(panel$first_treat)),
  n_obs     = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n✓ Results saved to data/main_results.rds\n")
cat("  Overall ATT (log rent):", round(agg_overall$overall.att, 4),
    "(SE:", round(agg_overall$overall.se, 4), ")\n")
cat("  Overall ATT (YoY growth):", round(agg_growth_overall$overall.att, 2),
    "(SE:", round(agg_growth_overall$overall.se, 2), ")\n")
cat("  TWFE coefficient:", round(coef(twfe), 4), "\n")
