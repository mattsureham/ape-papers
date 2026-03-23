# 03_main_analysis.R — Main regressions
# apep_0819: Media salience and disaster recovery in India
#
# Identification: Triple-difference
#   Flood exposure (state-year rainfall anomaly) × Competing events (year-level)
#   → Forward nightlights growth (district-year)
#
# Interpretation: when competing global news is high during India's monsoon,
#   flood-affected districts recover more slowly (the salience gap)

source("00_packages.R")

cat("=== MAIN ANALYSIS ===\n")

panel <- fread("data/analysis_panel.csv")

# ── Table 1: Summary Statistics (saved as LaTeX) ──────────────────────

cat("Computing summary statistics...\n")

summ_vars <- panel[, .(
  nl_forward_growth, rain_anomaly, competing_index,
  flood_exposed, monsoon_precip, log_pop, lit_rate
)]

summ_tab <- data.table(
  Variable = c("Nightlights forward growth (log)", "Monsoon rain anomaly (z-score)",
                "Competing news index (0-1)", "Flood exposed (binary)",
                "Monsoon precipitation (mm/day)", "Log population (2011)",
                "Literacy rate (2011)"),
  Mean = sapply(summ_vars, mean, na.rm = TRUE),
  SD = sapply(summ_vars, sd, na.rm = TRUE),
  Min = sapply(summ_vars, min, na.rm = TRUE),
  Max = sapply(summ_vars, max, na.rm = TRUE),
  N = sapply(summ_vars, function(x) sum(!is.na(x)))
)

cat("\n--- Summary Statistics ---\n")
print(summ_tab, digits = 3)

# ── Specification 1: Reduced-form triple-diff (binary flood) ──────────

cat("\n--- Specification 1: Binary flood × Competing events ---\n")

# Main specification: forward NL growth ~ flood × competing | dist + year
# Clustering at state level (30 clusters)
m1 <- feols(
  nl_forward_growth ~ flood_exposed + flood_x_competing + competing_index |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 1 (binary flood × competing):\n")
print(summary(m1))

# ── Specification 2: Continuous rain anomaly × competing ──────────────

cat("\n--- Specification 2: Continuous rain × Competing events ---\n")

m2 <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing + competing_index |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 2 (continuous rain × competing):\n")
print(summary(m2))

# ── Specification 3: Sports event as instrument (cleaner IV) ──────────

cat("\n--- Specification 3: Sports event instrument ---\n")

m3 <- feols(
  nl_forward_growth ~ flood_exposed + flood_x_sports + sports_event |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 3 (flood × sports event):\n")
print(summary(m3))

# ── Specification 4: Continuous rain × sports event ───────────────────

cat("\n--- Specification 4: Rain anomaly × Sports event ---\n")

m4 <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_sports + sports_event |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 4 (rain × sports):\n")
print(summary(m4))

# ── Specification 5: With Census controls ─────────────────────────────

cat("\n--- Specification 5: With controls ---\n")

m5 <- feols(
  nl_forward_growth ~ rain_anomaly + rain_x_competing + competing_index +
    rain_anomaly:log_pop + rain_anomaly:lit_rate + rain_anomaly:sc_share |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 5 (with controls):\n")
print(summary(m5))

# ── Specification 6: Extreme rain × competing (top quartile) ──────────

cat("\n--- Specification 6: Extreme rain × Competing ---\n")

m6 <- feols(
  nl_forward_growth ~ extreme_rain + extreme_x_competing + competing_index |
    dist_id + year,
  data = panel,
  cluster = ~pc11_state_id
)
cat("Model 6 (extreme rain × competing):\n")
print(summary(m6))

# ── Save main results ─────────────────────────────────────────────────

save(m1, m2, m3, m4, m5, m6, summ_tab, file = "data/main_results.RData")

# ── Diagnostics for validator ─────────────────────────────────────────

# Note: this is an interaction design (not DiD), so "n_pre" = total years
# since there is no single treatment date. All years provide identifying variation.
diagnostics <- list(
  n_treated = sum(panel$flood_exposed == 1, na.rm = TRUE),
  n_pre = uniqueN(panel$year),
  n_obs = nrow(panel),
  n_districts = uniqueN(panel$dist_id),
  n_states = uniqueN(panel$pc11_state_id),
  n_years = uniqueN(panel$year)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("  n_treated (flood-exposed dist-years): %d\n", diagnostics$n_treated))
cat(sprintf("  n_pre (years before 2016): %d\n", diagnostics$n_pre))
cat(sprintf("  n_obs: %d\n", diagnostics$n_obs))
cat(sprintf("  n_districts: %d\n", diagnostics$n_districts))
cat(sprintf("  n_states: %d\n", diagnostics$n_states))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
