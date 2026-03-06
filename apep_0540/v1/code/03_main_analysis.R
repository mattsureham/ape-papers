# 03_main_analysis.R — Main estimation: spatial DiD for GPE capitalization
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 3: MAIN ANALYSIS ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# Ensure factor variables
panel[, commune := as.character(commune)]
panel[, year_quarter := as.character(year_quarter)]
panel[, prop_type := as.character(prop_type)]

# ──────────────────────────────────────────────────────────────────
# 1. HEDONIC BASELINE (pooled cross-section)
# ──────────────────────────────────────────────────────────────────

cat("=== 1. Hedonic baseline ===\n")

# Pooled hedonic regression
hedonic_baseline <- feols(
  log_price_m2 ~ surface + I(surface^2) + rooms + i(prop_type) |
    commune + year_quarter,
  data = panel,
  cluster = ~commune
)

cat("Hedonic baseline R2:", round(r2(hedonic_baseline, "ar2"), 4), "\n")

# ──────────────────────────────────────────────────────────────────
# 2. MAIN SPECIFICATION: Construction-phase DiD
# ──────────────────────────────────────────────────────────────────

cat("\n=== 2. Main DiD specification (construction start treatment) ===\n")

# Main spec: 1km ring, treatment = post-construction-start
# Uses commune + year-quarter FE, hedonic controls, clustered at commune

main_did <- feols(
  log_price_m2 ~ treated_construction +
    surface + I(surface^2) + rooms + i(prop_type) |
    commune + year_quarter,
  data = panel[ring_1km | control],
  cluster = ~commune
)

cat("Main DiD (construction phase, 1km ring):\n")
summary(main_did)

# ──────────────────────────────────────────────────────────────────
# 3. TRIPLE DECOMPOSITION: DUP + Construction + Opening
# ──────────────────────────────────────────────────────────────────

cat("\n=== 3. Phase decomposition ===\n")

# Create phase indicators (mutually exclusive)
analysis_sample <- panel[ring_1km | control]
analysis_sample[, phase := "pre"]
analysis_sample[ring_1km & post_dup & !post_construction, phase := "post_dup"]
analysis_sample[ring_1km & post_construction & !post_opening, phase := "construction"]
analysis_sample[ring_1km & post_opening, phase := "opened"]
analysis_sample[, phase := factor(phase, levels = c("pre", "post_dup", "construction", "opened"))]

phase_decomp <- feols(
  log_price_m2 ~ i(phase, ref = "pre") +
    surface + I(surface^2) + rooms + i(prop_type) |
    commune + year_quarter,
  data = analysis_sample,
  cluster = ~commune
)

cat("Phase decomposition:\n")
summary(phase_decomp)

# ──────────────────────────────────────────────────────────────────
# 4. EVENT STUDY (relative to construction start)
# ──────────────────────────────────────────────────────────────────

cat("\n=== 4. Event study (construction start) ===\n")

# Trim event time to reasonable window
es_sample <- panel[ring_1km | control]
es_sample <- es_sample[!is.na(event_quarter)]
es_sample <- es_sample[event_quarter >= -16 & event_quarter <= 20]

# Create interaction variable for event study
es_sample[, treated_x_eq := fifelse(ring_1km, event_quarter, NA_integer_)]

# Event study with fixest using i() on interaction
event_study <- feols(
  log_price_m2 ~ i(treated_x_eq, ref = -1) +
    surface + I(surface^2) + rooms + i(prop_type) |
    commune + year_quarter,
  data = es_sample,
  cluster = ~commune
)

cat("Event study coefficients (selected):\n")
es_coefs <- coeftable(event_study)
es_rows <- grepl("treated_x_eq", rownames(es_coefs))
print(head(es_coefs[es_rows, ], 20))

# Save event study coefficients
es_dt <- data.table(
  event_quarter = as.integer(str_extract(rownames(es_coefs)[es_rows], "-?\\d+$")),
  estimate = es_coefs[es_rows, "Estimate"],
  se = es_coefs[es_rows, "Std. Error"],
  ci_low = es_coefs[es_rows, "Estimate"] - 1.96 * es_coefs[es_rows, "Std. Error"],
  ci_high = es_coefs[es_rows, "Estimate"] + 1.96 * es_coefs[es_rows, "Std. Error"]
)
es_dt <- es_dt[order(event_quarter)]

fwrite(es_dt, file.path(DATA_DIR, "event_study_coefficients.csv"))

# ──────────────────────────────────────────────────────────────────
# 5. DISTANCE GRADIENT
# ──────────────────────────────────────────────────────────────────

cat("\n=== 5. Distance gradient ===\n")

# Estimate effect at different distance rings
ring_results <- list()
for (ring_km in c(0.5, 1.0, 1.5)) {
  ring_var <- paste0("ring_", gsub("\\.", "", as.character(ring_km * 1000)), "m")
  if (ring_km == 0.5) ring_var <- "ring_500m"
  if (ring_km == 1.0) ring_var <- "ring_1km"
  if (ring_km == 1.5) ring_var <- "ring_1500m"

  sample_ring <- panel[get(ring_var) | control]
  sample_ring[, treated := get(ring_var) & post_construction]

  mod <- feols(
    log_price_m2 ~ treated +
      surface + I(surface^2) + rooms + i(prop_type) |
      commune + year_quarter,
    data = sample_ring,
    cluster = ~commune
  )

  ring_results[[as.character(ring_km)]] <- data.table(
    ring_km = ring_km,
    estimate = coef(mod)["treatedTRUE"],
    se = se(mod)["treatedTRUE"],
    n_treated = sum(sample_ring$treated),
    n_control = sum(!sample_ring$treated & sample_ring$control)
  )
}

distance_gradient <- rbindlist(ring_results)
distance_gradient[, ci_low := estimate - 1.96 * se]
distance_gradient[, ci_high := estimate + 1.96 * se]

fwrite(distance_gradient, file.path(DATA_DIR, "distance_gradient.csv"))
cat("Distance gradient:\n")
print(distance_gradient)

# ──────────────────────────────────────────────────────────────────
# 6. CALLAWAY-SANT'ANNA STAGGERED DID
# ──────────────────────────────────────────────────────────────────

cat("\n=== 6. Callaway-Sant'Anna staggered DiD ===\n")

# Prepare data for CS estimator
cs_sample <- panel[ring_1km | control]
cs_sample[, treat_period := fifelse(ring_1km,
  as.integer(format(as.Date(construction_start), "%Y")) * 4 +
    as.integer(format(as.Date(construction_start), "%m")) %/% 4,
  0)]  # 0 = never treated

# Create numeric time index
cs_sample[, time_idx := year(date) * 4 + quarter(date)]

# Commune numeric ID
cs_sample[, commune_id := as.integer(factor(commune))]

# Collapse to commune-quarter level for CS (too many individual transactions)
cs_collapsed <- cs_sample[, .(
  log_price_m2 = mean(log_price_m2, na.rm = TRUE),
  n_transactions = .N,
  mean_surface = mean(surface, na.rm = TRUE),
  pct_apartment = mean(prop_type == "apartment", na.rm = TRUE),
  treat_period = first(treat_period)
), by = .(commune_id, time_idx)]

# Run CS-DiD
tryCatch({
  cs_result <- att_gt(
    yname = "log_price_m2",
    tname = "time_idx",
    idname = "commune_id",
    gname = "treat_period",
    data = as.data.frame(cs_collapsed),
    control_group = "notyettreated",
    base_period = "varying"
  )

  cat("CS-DiD group-time ATTs computed.\n")
  cat(sprintf("  Number of group-time ATTs: %d\n", length(cs_result$att)))

  # Aggregate to event time
  cs_agg <- aggte(cs_result, type = "dynamic", min_e = -12, max_e = 16)
  cat("Aggregated event-study:\n")
  summary(cs_agg)

  # Save CS results
  cs_es <- data.table(
    event_time = cs_agg$egt,
    att = cs_agg$att.egt,
    se = cs_agg$se.egt
  )
  cs_es[, ci_low := att - 1.96 * se]
  cs_es[, ci_high := att + 1.96 * se]
  fwrite(cs_es, file.path(DATA_DIR, "cs_did_event_study.csv"))

  # Overall ATT
  cs_overall <- aggte(cs_result, type = "simple")
  cat(sprintf("\nCS-DiD Overall ATT: %.4f (SE: %.4f)\n", cs_overall$overall.att, cs_overall$overall.se))

  # Save overall
  fwrite(data.table(
    estimator = "Callaway-Sant'Anna",
    att = cs_overall$overall.att,
    se = cs_overall$overall.se,
    ci_low = cs_overall$overall.att - 1.96 * cs_overall$overall.se,
    ci_high = cs_overall$overall.att + 1.96 * cs_overall$overall.se
  ), file.path(DATA_DIR, "cs_did_overall.csv"))

}, error = function(e) {
  cat(sprintf("CS-DiD failed: %s\n", e$message))
  cat("Proceeding with TWFE event study as primary specification.\n")
})

# ──────────────────────────────────────────────────────────────────
# 7. SAVE ALL MODEL OBJECTS
# ──────────────────────────────────────────────────────────────────

cat("\nSaving model results...\n")

# Main results table
main_results <- data.table(
  specification = c("Hedonic baseline", "Main DiD (1km, construction)",
                     "Phase: post-DUP", "Phase: construction", "Phase: opened"),
  estimate = c(NA,
    coef(main_did)[grep("treated_construction", names(coef(main_did)))][1],
    coef(phase_decomp)[grep("post_dup", names(coef(phase_decomp)))][1],
    coef(phase_decomp)[grep("construction$", names(coef(phase_decomp)))][1],
    coef(phase_decomp)[grep("opened", names(coef(phase_decomp)))][1]),
  se = c(NA,
    se(main_did)[grep("treated_construction", names(se(main_did)))][1],
    se(phase_decomp)[grep("post_dup", names(se(phase_decomp)))][1],
    se(phase_decomp)[grep("construction$", names(se(phase_decomp)))][1],
    se(phase_decomp)[grep("opened", names(se(phase_decomp)))][1]),
  n = c(nobs(hedonic_baseline), nobs(main_did), rep(nobs(phase_decomp), 3))
)
main_results[!is.na(estimate), pct_effect := round(100 * (exp(estimate) - 1), 2)]

fwrite(main_results, file.path(DATA_DIR, "main_results.csv"))
cat("Main results:\n")
print(main_results)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
