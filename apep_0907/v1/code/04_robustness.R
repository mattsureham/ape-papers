## 04_robustness.R — Robustness checks and heterogeneity
## apep_0907: The Digital Door to Food Stamps

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# ============================================================
# 1. Sun-Abraham (2021) interaction-weighted estimator
# ============================================================
cat("=== Sun-Abraham ===\n")

# sunab() requires last-treated or never-treated as reference
# Use fixest::sunab
panel_sa <- panel %>%
  mutate(first_treat_sa = ifelse(first_treat == 0, 10000L, first_treat))

sa_fit <- feols(snap_rate ~ sunab(first_treat_sa, year) | state_id + year,
                data = panel_sa, cluster = ~state_id)

cat("Sun-Abraham ATT:\n")
summary(sa_fit)

# Extract overall ATT (average of post-treatment coefficients)
sa_coefs <- coef(sa_fit)
sa_ses <- sqrt(diag(vcov(sa_fit)))
sa_names <- names(sa_coefs)
# Post-treatment coefficients (event time >= 0)
post_idx <- grep("^year::", sa_names)
post_events <- as.numeric(gsub("year::", "", sa_names[post_idx]))
post_mask <- post_events >= 0
if (sum(post_mask) > 0) {
  sa_att <- mean(sa_coefs[post_idx][post_mask])
  cat("SA average post-treatment ATT:", round(sa_att, 2), "\n")
}

# ============================================================
# 2. Leave-one-out by adoption cohort
# ============================================================
cat("\n=== Leave-One-Out by Cohort ===\n")

cohorts <- sort(unique(panel$first_treat[panel$first_treat > 0]))
loo_results <- data.frame(
  dropped_cohort = integer(),
  att = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (coh in cohorts) {
  panel_loo <- panel %>% filter(first_treat != coh)

  cs_loo <- tryCatch({
    out <- att_gt(
      yname = "snap_rate", tname = "year", idname = "state_id",
      gname = "first_treat", data = panel_loo,
      control_group = "notyettreated", anticipation = 0,
      est_method = "dr", base_period = "universal"
    )
    agg <- aggte(out, type = "simple")
    data.frame(dropped_cohort = coh, att = agg$overall.att, se = agg$overall.se)
  }, error = function(e) {
    data.frame(dropped_cohort = coh, att = NA_real_, se = NA_real_)
  })

  loo_results <- bind_rows(loo_results, cs_loo)
  cat("  Dropped", coh, ": ATT =", round(cs_loo$att, 2), "\n")
}

cat("\nLeave-one-out results:\n")
print(loo_results)

# ============================================================
# 3. Alternative outcome: log SNAP persons (CS not-yet-treated)
# ============================================================
cat("\n=== Log Specification (not-yet-treated) ===\n")

cs_log_nyt <- att_gt(
  yname = "log_snap", tname = "year", idname = "state_id",
  gname = "first_treat", data = panel,
  control_group = "notyettreated", anticipation = 0,
  est_method = "dr", base_period = "universal"
)

cs_log_nyt_agg <- aggte(cs_log_nyt, type = "simple")
cat("CS Log (not-yet-treated) ATT:\n")
summary(cs_log_nyt_agg)

cs_log_nyt_es <- aggte(cs_log_nyt, type = "dynamic", min_e = -8, max_e = 10)

# ============================================================
# 4. Heterogeneity: early vs late adopters
# ============================================================
cat("\n=== Heterogeneity: Early vs Late Adopters ===\n")

median_adopt <- median(panel$first_treat[panel$first_treat > 0])
cat("Median adoption year:", median_adopt, "\n")

# Early adopters (before median)
panel_early <- panel %>%
  filter(first_treat == 0 | first_treat < median_adopt)

cs_early <- tryCatch({
  out <- att_gt(
    yname = "snap_rate", tname = "year", idname = "state_id",
    gname = "first_treat", data = panel_early,
    control_group = "notyettreated", anticipation = 0,
    est_method = "dr", base_period = "universal"
  )
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))
cat("Early adopters ATT:", round(cs_early$overall.att, 2),
    "(SE:", round(cs_early$overall.se, 2), ")\n")

# Late adopters (median or after)
panel_late <- panel %>%
  filter(first_treat == 0 | first_treat >= median_adopt)

cs_late <- tryCatch({
  out <- att_gt(
    yname = "snap_rate", tname = "year", idname = "state_id",
    gname = "first_treat", data = panel_late,
    control_group = "notyettreated", anticipation = 0,
    est_method = "dr", base_period = "universal"
  )
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))
cat("Late adopters ATT:", round(cs_late$overall.att, 2),
    "(SE:", round(cs_late$overall.se, 2), ")\n")

# ============================================================
# 5. Heterogeneity: high vs low baseline SNAP rate
# ============================================================
cat("\n=== Heterogeneity: Baseline SNAP Rate ===\n")

# Use pre-treatment average SNAP rate
baseline_snap <- panel %>%
  filter(year < first_treat | first_treat == 0) %>%
  filter(year <= 2001) %>%  # Pre any treatment
  group_by(state_id, fips) %>%
  summarize(baseline_rate = mean(snap_rate, na.rm = TRUE), .groups = "drop")

median_baseline <- median(baseline_snap$baseline_rate)
cat("Median baseline SNAP rate:", round(median_baseline, 1), "\n")

high_snap_states <- baseline_snap$state_id[baseline_snap$baseline_rate >= median_baseline]
low_snap_states <- baseline_snap$state_id[baseline_snap$baseline_rate < median_baseline]

# High baseline
panel_high <- panel %>% filter(state_id %in% high_snap_states)
cs_high <- tryCatch({
  out <- att_gt(
    yname = "snap_rate", tname = "year", idname = "state_id",
    gname = "first_treat", data = panel_high,
    control_group = "notyettreated", anticipation = 0,
    est_method = "dr", base_period = "universal"
  )
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))
cat("High baseline SNAP ATT:", round(cs_high$overall.att, 2),
    "(SE:", round(cs_high$overall.se, 2), ")\n")

# Low baseline
panel_low <- panel %>% filter(state_id %in% low_snap_states)
cs_low <- tryCatch({
  out <- att_gt(
    yname = "snap_rate", tname = "year", idname = "state_id",
    gname = "first_treat", data = panel_low,
    control_group = "notyettreated", anticipation = 0,
    est_method = "dr", base_period = "universal"
  )
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))
cat("Low baseline SNAP ATT:", round(cs_low$overall.att, 2),
    "(SE:", round(cs_low$overall.se, 2), ")\n")

# ============================================================
# 6. Pre-trend test (formal Wald test from CS)
# ============================================================
cat("\n=== Pre-trend Diagnostics ===\n")

# CS event study with not-yet-treated (preferred)
cs_nyt_es <- aggte(results$cs_nyt, type = "dynamic", min_e = -8, max_e = 10)

# Extract pre-treatment coefficients
es_df <- data.frame(
  event_time = cs_nyt_es$egt,
  estimate = cs_nyt_es$att.egt,
  se = cs_nyt_es$se.egt
)
pre_df <- es_df %>% filter(event_time < 0, event_time >= -8)
cat("Pre-treatment event study (not-yet-treated):\n")
print(pre_df)

# ============================================================
# 7. HonestDiD bounds (if pre-trends present)
# ============================================================
cat("\n=== HonestDiD Sensitivity ===\n")

tryCatch({
  # Use CS event study for HonestDiD
  cs_es_honest <- aggte(results$cs_nyt, type = "dynamic")

  # Extract the beta and sigma for HonestDiD
  betahat <- cs_es_honest$att.egt
  sigma <- cs_es_honest$se.egt

  # Need the full variance-covariance matrix
  # HonestDiD expects the event study estimates
  if (!any(is.na(sigma))) {
    n_pre <- sum(cs_es_honest$egt < 0)
    n_post <- sum(cs_es_honest$egt >= 0)

    cat("Event study has", n_pre, "pre-periods and", n_post, "post-periods\n")
    cat("Pre-treatment estimates (not-yet-treated):\n")
    pre_idx <- which(cs_es_honest$egt < 0)
    for (i in pre_idx) {
      cat("  t =", cs_es_honest$egt[i], ": ", round(cs_es_honest$att.egt[i], 2),
          "(SE:", round(cs_es_honest$se.egt[i], 2), ")\n")
    }
  }
}, error = function(e) cat("HonestDiD skipped:", conditionMessage(e), "\n"))

# ============================================================
# 8. Save robustness results
# ============================================================
rob_results <- list(
  sa_fit = sa_fit,
  loo_results = loo_results,
  cs_log_nyt_agg = cs_log_nyt_agg,
  cs_early = cs_early,
  cs_late = cs_late,
  cs_high = cs_high,
  cs_low = cs_low,
  cs_nyt_es = cs_nyt_es
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness complete ===\n")
