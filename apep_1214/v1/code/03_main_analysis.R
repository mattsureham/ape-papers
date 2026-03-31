## 03_main_analysis.R — Main causal analysis: MCMV FAR → IDEB
## apep_1214: MCMV Housing and School Quality

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Load data
# ============================================================
cat("=== Loading analysis panels ===\n")

panel <- fread(file.path(data_dir, "panel_public.csv"))
panel_mun <- fread(file.path(data_dir, "panel_municipal.csv"))
panel_state <- fread(file.path(data_dir, "panel_state.csv"))

cat(sprintf("Public panel: %d obs, %d municipalities, %d treated\n",
            nrow(panel), uniqueN(panel$mun_id),
            uniqueN(panel[first_year > 0]$mun_id)))

# ============================================================
# Main specification 1: TWFE (baseline for comparison)
# ============================================================
cat("\n=== Specification 1: TWFE ===\n")

# Focus on anos_iniciais (grades 1-5) — most directly affected by enrollment
ai <- panel[stage == "anos_iniciais"]
af <- panel[stage == "anos_finais"]

# TWFE regression
twfe_ai <- feols(ideb_score ~ treated | mun_id + year,
                 data = ai, cluster = ~mun_id)
cat("TWFE (anos iniciais):\n")
print(summary(twfe_ai))

twfe_af <- feols(ideb_score ~ treated | mun_id + year,
                 data = af, cluster = ~mun_id)
cat("\nTWFE (anos finais):\n")
print(summary(twfe_af))

# ============================================================
# Main specification 2: Callaway-Sant'Anna (2021)
# ============================================================
cat("\n=== Specification 2: Callaway-Sant'Anna ===\n")

# CS requires: yname, tname, idname, gname (first treatment period, 0 for never-treated)
# Map first_year to nearest IDEB wave for CS
ideb_waves <- c(2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)

# For CS, treatment group g is the first wave the unit was treated
ai[, g := 0L]  # Never-treated
ai[first_year > 0, g := {
  # Map first treatment year to the IDEB wave in which treatment was active
  wave_idx <- findInterval(first_year, ideb_waves)
  # If treated between waves, the effect is first observed in the next wave
  ifelse(first_year %in% ideb_waves,
         first_year,
         ideb_waves[pmin(wave_idx + 1, length(ideb_waves))])
}]

cat("Treatment cohort distribution (CS groups):\n")
print(ai[, .(n_mun = uniqueN(mun_id)), by = g][order(g)])

# Run Callaway-Sant'Anna
cs_ai <- att_gt(
  yname = "ideb_score",
  tname = "year",
  idname = "mun_id",
  gname = "g",
  data = as.data.frame(ai),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cat("\nCallaway-Sant'Anna group-time ATTs:\n")
print(summary(cs_ai))

# Aggregate to overall ATT
cs_agg <- aggte(cs_ai, type = "simple")
cat("\nOverall ATT (simple aggregation):\n")
print(summary(cs_agg))

# Dynamic aggregation (event study)
cs_dynamic <- aggte(cs_ai, type = "dynamic", min_e = -4, max_e = 8)
cat("\nDynamic ATT (event study):\n")
print(summary(cs_dynamic))

# ============================================================
# Specification 3: anos_finais (grades 6-9)
# ============================================================
cat("\n=== Specification 3: Callaway-Sant'Anna (anos finais) ===\n")

af[, g := 0L]
af[first_year > 0, g := {
  wave_idx <- findInterval(first_year, ideb_waves)
  ifelse(first_year %in% ideb_waves,
         first_year,
         ideb_waves[pmin(wave_idx + 1, length(ideb_waves))])
}]

cs_af <- att_gt(
  yname = "ideb_score",
  tname = "year",
  idname = "mun_id",
  gname = "g",
  data = as.data.frame(af),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cs_agg_af <- aggte(cs_af, type = "simple")
cat("Overall ATT (anos finais):\n")
print(summary(cs_agg_af))

cs_dynamic_af <- aggte(cs_af, type = "dynamic", min_e = -4, max_e = 8)

# ============================================================
# Specification 4: Dose-response (log units)
# ============================================================
cat("\n=== Specification 4: Dose-response ===\n")

# Continuous treatment: effect of program scale
dose_ai <- feols(ideb_score ~ treated + treated:log_units | mun_id + year,
                 data = ai[first_year > 0 | first_year == 0],
                 cluster = ~mun_id)
cat("Dose-response (anos iniciais):\n")
print(summary(dose_ai))

# ============================================================
# Specification 5: Mechanism — Municipal vs State schools
# ============================================================
cat("\n=== Specification 5: Municipal vs State school comparison ===\n")

# Municipal schools should bear most of the enrollment burden
# State schools serve as within-municipality placebo
panel_mun[, g := 0L]
panel_mun[first_year > 0, g := {
  wave_idx <- findInterval(first_year, ideb_waves)
  ifelse(first_year %in% ideb_waves,
         first_year,
         ideb_waves[pmin(wave_idx + 1, length(ideb_waves))])
}]

# Municipal schools — anos iniciais only
mun_ai <- panel_mun[stage == "anos_iniciais"]
if (nrow(mun_ai) > 0 & uniqueN(mun_ai[g > 0]$mun_id) >= 20) {
  cs_mun <- att_gt(
    yname = "ideb_score",
    tname = "year",
    idname = "mun_id",
    gname = "g",
    data = as.data.frame(mun_ai),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )
  cs_agg_mun <- aggte(cs_mun, type = "simple")
  cat("Municipal schools ATT:\n")
  print(summary(cs_agg_mun))
} else {
  cat("Insufficient municipal school data for CS estimation.\n")
}

# State schools — anos iniciais
panel_state[, g := 0L]
panel_state[first_year > 0, g := {
  wave_idx <- findInterval(first_year, ideb_waves)
  ifelse(first_year %in% ideb_waves,
         first_year,
         ideb_waves[pmin(wave_idx + 1, length(ideb_waves))])
}]

state_ai <- panel_state[stage == "anos_iniciais"]
if (nrow(state_ai) > 0 & uniqueN(state_ai[g > 0]$mun_id) >= 20) {
  cs_state <- att_gt(
    yname = "ideb_score",
    tname = "year",
    idname = "mun_id",
    gname = "g",
    data = as.data.frame(state_ai),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )
  cs_agg_state <- aggte(cs_state, type = "simple")
  cat("State schools ATT:\n")
  print(summary(cs_agg_state))
} else {
  cat("Insufficient state school data for CS estimation.\n")
}

# ============================================================
# Save results
# ============================================================
cat("\n=== Saving results ===\n")

# Store key results for table generation
results <- list(
  twfe_ai = twfe_ai,
  twfe_af = twfe_af,
  cs_ai = cs_ai,
  cs_af = cs_af,
  cs_agg_ai = cs_agg,
  cs_agg_af = cs_agg_af,
  cs_dynamic_ai = cs_dynamic,
  cs_dynamic_af = cs_dynamic_af,
  dose_ai = dose_ai
)

# Add mechanism results if available
if (exists("cs_agg_mun")) results$cs_agg_mun <- cs_agg_mun
if (exists("cs_agg_state")) results$cs_agg_state <- cs_agg_state

saveRDS(results, file.path(data_dir, "results.rds"))

# Write diagnostics.json for validator
n_treated <- uniqueN(ai[g > 0]$mun_id)
n_pre <- length(ideb_waves[ideb_waves < 2009])  # 2005, 2007
n_obs <- nrow(ai)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    att_ai = round(cs_agg$overall.att, 4),
    se_ai = round(cs_agg$overall.se, 4),
    att_af = round(cs_agg_af$overall.att, 4),
    se_af = round(cs_agg_af$overall.se, 4)
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat(sprintf("\nKey results summary:\n"))
cat(sprintf("  CS ATT (anos iniciais): %.4f (SE: %.4f)\n",
            cs_agg$overall.att, cs_agg$overall.se))
cat(sprintf("  CS ATT (anos finais): %.4f (SE: %.4f)\n",
            cs_agg_af$overall.att, cs_agg_af$overall.se))
cat(sprintf("  TWFE (anos iniciais): %.4f (SE: %.4f)\n",
            coef(twfe_ai)["treated"], se(twfe_ai)["treated"]))
cat(sprintf("  Treated municipalities: %d\n", n_treated))
cat(sprintf("  Pre-periods: %d\n", n_pre))
cat(sprintf("  Total obs: %d\n", n_obs))

cat("\nMain analysis complete.\n")
