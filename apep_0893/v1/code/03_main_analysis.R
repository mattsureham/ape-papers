## 03_main_analysis.R — Main DiD analysis
## Continuous-treatment DiD: EO 13771 × pre-period significance share

source("00_packages.R")

DATA_DIR <- "../data"

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
agency_intensity <- readRDS(file.path(DATA_DIR, "agency_intensity.rds"))

# ---------------------------------------------------------------------------
# Descriptive: treatment rollout
# ---------------------------------------------------------------------------
cat("=== Treatment intensity distribution ===\n")
cat(sprintf("Agencies: %d\n", n_distinct(panel$primary_agency)))
cat(sprintf("Sig share: mean=%.3f, sd=%.3f, p25=%.3f, p50=%.3f, p75=%.3f\n",
            mean(agency_intensity$sig_share),
            sd(agency_intensity$sig_share),
            quantile(agency_intensity$sig_share, 0.25),
            quantile(agency_intensity$sig_share, 0.50),
            quantile(agency_intensity$sig_share, 0.75)))

# ---------------------------------------------------------------------------
# Main specification: Continuous DiD
# ---------------------------------------------------------------------------
# Y_at = α_a + δ_t + β₁(Post2017 × SigShare) + β₂(Post2021 × SigShare) + ε_at

# Model 1: NPRM Count (extensive margin)
m1_count <- feols(
  log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel,
  cluster = ~primary_agency
)

# Model 2: Completion rate (conditional on >0 NPRMs)
panel_pos <- panel |> filter(n_nprm > 0)

m2_complete <- feols(
  completion_rate ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_pos,
  cluster = ~primary_agency
)

# Model 3: Mean duration (conditional on completed rules)
panel_dur <- panel |> filter(!is.na(mean_duration) & mean_duration > 0)

m3_duration <- feols(
  log(mean_duration) ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_dur,
  cluster = ~primary_agency
)

# Model 4: Share significant (composition)
panel_pos <- panel_pos |>
  mutate(sig_rate = n_significant / n_nprm)

m4_composition <- feols(
  sig_rate ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_pos,
  cluster = ~primary_agency
)

cat("\n=== MAIN RESULTS ===\n")
cat("\nModel 1: log(NPRM count + 1)\n")
print(summary(m1_count))

cat("\nModel 2: Completion rate\n")
print(summary(m2_complete))

cat("\nModel 3: log(Duration in days)\n")
print(summary(m3_duration))

cat("\nModel 4: Share significant rules\n")
print(summary(m4_composition))

# ---------------------------------------------------------------------------
# Event study: semester-level leads and lags
# ---------------------------------------------------------------------------
# Create event-time dummies interacted with treatment intensity
panel_es <- panel |>
  mutate(
    # Event time in semesters relative to 2017H1
    event_time = time_idx,
    # Cap at -7 and +14 (7 pre, 14 post semesters)
    event_time_c = pmax(pmin(event_time, 14), -7),
    # Interact with continuous treatment
    et_treat = event_time_c * sig_share
  )

# Use fixest sunab-style event study with continuous treatment
# Create event time factor, omitting t=-1 as reference
panel_es$et_factor <- factor(panel_es$event_time_c)

# Event study for NPRM count
es_count <- feols(
  log_nprm ~ i(et_factor, sig_share, ref = "-1") | primary_agency + year_sem,
  data = panel_es,
  cluster = ~primary_agency
)

# Event study for completion rate
panel_es_pos <- panel_es |> filter(n_nprm > 0)

es_complete <- feols(
  completion_rate ~ i(et_factor, sig_share, ref = "-1") | primary_agency + year_sem,
  data = panel_es_pos,
  cluster = ~primary_agency
)

# Event study for duration
panel_es_dur <- panel_es |> filter(!is.na(mean_duration) & mean_duration > 0)

es_duration <- feols(
  log(mean_duration) ~ i(et_factor, sig_share, ref = "-1") | primary_agency + year_sem,
  data = panel_es_dur,
  cluster = ~primary_agency
)

cat("\n=== EVENT STUDY: NPRM Count ===\n")
print(summary(es_count))

cat("\n=== EVENT STUDY: Completion Rate ===\n")
print(summary(es_complete))

cat("\n=== EVENT STUDY: Duration ===\n")
print(summary(es_duration))

# ---------------------------------------------------------------------------
# Save results
# ---------------------------------------------------------------------------
results <- list(
  m1_count = m1_count,
  m2_complete = m2_complete,
  m3_duration = m3_duration,
  m4_composition = m4_composition,
  es_count = es_count,
  es_complete = es_complete,
  es_duration = es_duration
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# ---------------------------------------------------------------------------
# Diagnostics for validation
# ---------------------------------------------------------------------------
diagnostics <- list(
  n_treated = n_distinct(panel$primary_agency[panel$sig_share > median(agency_intensity$sig_share)]),
  n_pre = length(unique(panel$year_sem[panel$year_sem < 2017])),
  n_obs = nrow(panel)
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("Main analysis complete.\n")
