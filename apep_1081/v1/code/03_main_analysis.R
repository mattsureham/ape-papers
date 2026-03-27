# 03_main_analysis.R — Main DiD analysis
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat(sprintf("Panel: %d obs, %d stations, years %d-%d\n",
            nrow(panel), n_distinct(panel$station_id),
            min(panel$year), max(panel$year)))
cat(sprintf("Treated stations: %d, Control stations: %d\n",
            n_distinct(panel$station_id[panel$treated == 1]),
            n_distinct(panel$station_id[panel$treated == 0])))

# ── 1. TWFE (primary — handles sparse panels well) ──
twfe <- feols(
  log_fluor ~ post | station_num + year,
  data = panel,
  cluster = ~state
)
cat("\n=== TWFE (primary) ===\n")
summary(twfe)

# ── 2. TWFE with controls ──
twfe_ctrl <- feols(
  log_fluor ~ post + n_samples + pct_nondetect | station_num + year,
  data = panel,
  cluster = ~state
)
cat("\n=== TWFE with controls ===\n")
summary(twfe_ctrl)

# ── 3. Event study (using fixest interaction terms) ──
# Create relative time to treatment
panel <- panel %>%
  mutate(
    rel_time = ifelse(ban_year > 0, year - ban_year, NA_integer_),
    # Bin endpoints
    rel_time_binned = case_when(
      is.na(rel_time) ~ NA_integer_,
      rel_time < -6   ~ -6L,
      rel_time > 6    ~ 6L,
      TRUE            ~ as.integer(rel_time)
    )
  )

# Event study for treated units vs control (using i() syntax)
# Ref period: t = -1
es_data <- panel %>%
  mutate(
    cohort = ifelse(ban_year == 0, 10000L, as.integer(ban_year))
  )

# Sun-Abraham interaction-weighted estimator
sa <- tryCatch({
  feols(
    log_fluor ~ sunab(cohort, year, ref.p = -1) | station_num + year,
    data = es_data,
    cluster = ~state
  )
}, error = function(e) {
  cat(sprintf("Sun-Abraham error: %s\n", e$message))
  NULL
})

if (!is.null(sa)) {
  cat("\n=== Sun-Abraham ===\n")
  summary(sa)
  sa_agg <- summary(sa, agg = "ATT")
  cat("\n=== Sun-Abraham ATT ===\n")
  print(sa_agg)
}

# ── 4. Callaway-Sant'Anna (with na.rm for sparse panel) ──
cs_data <- panel %>%
  mutate(first_treat = ifelse(ban_year == 0, 0, ban_year))

cs_out <- tryCatch({
  att_gt(
    yname      = "log_fluor",
    tname      = "year",
    idname     = "station_num",
    gname      = "first_treat",
    data       = cs_data,
    control_group = "nevertreated",
    base_period = "universal",
    clustervars = "state",
    panel       = FALSE,
    print_details = FALSE
  )
}, error = function(e) {
  cat(sprintf("CS error: %s\n", e$message))
  NULL
})

cs_agg <- NULL
cs_event <- NULL
if (!is.null(cs_out)) {
  cs_agg <- tryCatch(aggte(cs_out, type = "simple", na.rm = TRUE),
                      error = function(e) { cat(sprintf("CS agg error: %s\n", e$message)); NULL })
  cs_event <- tryCatch(aggte(cs_out, type = "dynamic", min_e = -6, max_e = 6, na.rm = TRUE),
                        error = function(e) { cat(sprintf("CS event error: %s\n", e$message)); NULL })

  if (!is.null(cs_agg)) {
    cat("\n=== Overall ATT (CS) ===\n")
    summary(cs_agg)
  }
  if (!is.null(cs_event)) {
    cat("\n=== Event Study (CS) ===\n")
    summary(cs_event)
  }
}

# ── 5. Manual event study using fixest ──
# For treated stations only, compare pre vs post
panel_es <- panel %>%
  filter(!is.na(rel_time_binned)) %>%
  mutate(rel_factor = relevel(factor(rel_time_binned), ref = "-1"))

es_manual <- tryCatch({
  feols(
    log_fluor ~ rel_factor | station_num + year,
    data = panel_es,
    cluster = ~state
  )
}, error = function(e) {
  cat(sprintf("Manual ES error: %s\n", e$message))
  NULL
})

if (!is.null(es_manual)) {
  cat("\n=== Manual Event Study ===\n")
  summary(es_manual)
}

# ── Save results ──
results <- list(
  twfe       = twfe,
  twfe_ctrl  = twfe_ctrl,
  sa         = sa,
  cs_out     = cs_out,
  cs_agg     = cs_agg,
  cs_event   = cs_event,
  es_manual  = es_manual
)
saveRDS(results, "../data/results_main.rds")

# ── Determine best estimate for diagnostics ──
# Use CS if available, otherwise TWFE
best_att <- if (!is.null(cs_agg)) cs_agg$overall.att else coef(twfe)["post"]
best_se  <- if (!is.null(cs_agg)) cs_agg$overall.se else se(twfe)["post"]

diag <- list(
  n_treated = n_distinct(panel$station_id[panel$treated == 1]),
  n_pre = length(unique(panel$year[panel$year < min(panel$ban_year[panel$ban_year > 0])])),
  n_obs = nrow(panel),
  n_stations = n_distinct(panel$station_id),
  n_clusters = n_distinct(panel$state),
  best_att = best_att,
  best_se = best_se,
  twfe_coef = coef(twfe)["post"],
  twfe_se = se(twfe)["post"]
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Summary ===\n")
cat(sprintf("TWFE:  %.4f (SE: %.4f, p=%.3f)\n",
            coef(twfe)["post"], se(twfe)["post"], pvalue(twfe)["post"]))
if (!is.null(cs_agg)) {
  cat(sprintf("CS:    %.4f (SE: %.4f)\n", cs_agg$overall.att, cs_agg$overall.se))
}
if (!is.null(sa)) {
  cat("SA:    See above\n")
}
cat("\nResults saved.\n")
