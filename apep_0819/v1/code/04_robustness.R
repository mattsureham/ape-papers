# 04_robustness.R — Robustness checks and mechanism tests
# apep_0819: Media salience and disaster recovery in India

source("00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n")

panel <- fread("data/analysis_panel.csv")
load("data/main_results.RData")

# ── 1. Placebo: Non-flood districts should show no effect ─────────────

cat("--- Placebo: Non-flood districts ---\n")

# Districts with below-median average rainfall (structurally dry)
dry_districts <- panel[flood_prone == 0]
wet_districts <- panel[flood_prone == 1]

r_placebo <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing |
    dist_id + year,
  data = dry_districts,
  cluster = ~pc11_state_id
)
cat("Placebo (dry districts only):\n")
print(summary(r_placebo))

r_wet <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing |
    dist_id + year,
  data = wet_districts,
  cluster = ~pc11_state_id
)
cat("Flood-prone districts only:\n")
print(summary(r_wet))

# ── 2. Drop COVID year (2020 is extreme outlier) ──────────────────────

cat("\n--- Sensitivity: Drop COVID years ---\n")

no_covid <- panel[year < 2020]

r_nocovid <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing |
    dist_id + year,
  data = no_covid,
  cluster = ~pc11_state_id
)
cat("Without 2020:\n")
print(summary(r_nocovid))

# ── 3. Alternative outcome: Contemporaneous NL growth ─────────────────

cat("\n--- Alternative outcome: Contemporaneous NL growth ---\n")

r_contemp <- feols(
  nl_growth ~ rain_anomaly + rain_x_competing |
    dist_id + year,
  data = panel[!is.na(nl_growth)],
  cluster = ~pc11_state_id
)
cat("Contemporaneous NL growth:\n")
print(summary(r_contemp))

# ── 4. Quadratic rain anomaly (nonlinear flood effects) ───────────────

cat("\n--- Nonlinear rain effects ---\n")

panel[, rain_sq := rain_anomaly^2]
panel[, rain_sq_x_competing := rain_sq * competing_index]

r_nonlin <- feols(
  nl_forward_growth ~ rain_anomaly + rain_sq + rain_x_competing + rain_sq_x_competing |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Quadratic rainfall:\n")
print(summary(r_nonlin))

# ── 5. Drop COVID + 2019 (most recent disrupted years) ────────────────

cat("\n--- Drop 2019-2020 (COVID disruption) ---\n")

no_recent <- panel[year <= 2018]

r_stateyr <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing |
    dist_id + year,
  data = no_recent,
  cluster = ~pc11_state_id
)
cat("Drop 2019-2020:\n")
print(summary(r_stateyr))

# ── 6. Mechanism: Political alignment ─────────────────────────────────
# Hypothesis: media matters more in opposition-ruled states
# We don't have party data, so use SC/ST share as a proxy for
# disadvantaged districts where governance responsiveness may differ

cat("\n--- Mechanism: Disadvantaged districts ---\n")

panel[, high_scst := as.integer((sc_share + st_share) > median(sc_share + st_share, na.rm = TRUE))]
panel[, rain_x_competing_x_scst := rain_anomaly * competing_index * high_scst]
panel[, rain_x_scst := rain_anomaly * high_scst]

r_scst <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing +
    rain_x_scst + rain_x_competing_x_scst |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("SC/ST interaction:\n")
print(summary(r_scst))

# ── 7. Alternative competing events: Olympics only ────────────────────

cat("\n--- Olympics-only instrument ---\n")

panel[, olympics := as.integer(year %in% c(2012, 2016, 2021))]
panel[, rain_x_olympics := rain_anomaly * olympics]

r_olympics <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_olympics |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Olympics interaction:\n")
print(summary(r_olympics))

# ── 8. Leave-one-state-out (check no single state drives results) ─────

cat("\n--- Leave-one-state-out sensitivity ---\n")

states <- unique(panel$pc11_state_id)
loo_coefs <- numeric(length(states))
names(loo_coefs) <- states

for (s in states) {
  m_loo <- feols(
    nl_forward_growth ~ rain_anomaly + rain_x_competing | dist_id + year,
    data = panel[pc11_state_id != s],
    cluster = ~pc11_state_id
  )
  loo_coefs[as.character(s)] <- coef(m_loo)["rain_x_competing"]
}

cat(sprintf("  rain_x_competing range across LOO: [%.4f, %.4f]\n",
            min(loo_coefs), max(loo_coefs)))
cat(sprintf("  Main estimate: %.4f\n", coef(m2)["rain_x_competing"]))
cat(sprintf("  All LOO estimates same sign: %s\n",
            ifelse(all(loo_coefs > 0) || all(loo_coefs < 0), "YES", "NO")))

# ── Save robustness results ───────────────────────────────────────────

save(r_placebo, r_wet, r_nocovid, r_contemp, r_nonlin, r_stateyr,
     r_scst, r_olympics, loo_coefs,
     file = "data/robustness_results.RData")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
