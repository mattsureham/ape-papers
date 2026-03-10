## ============================================================
## 03_main_analysis.R — Primary regressions
## apep_0573: EU Procurement Reform and Competition
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

cat("=== Loading clean data ===\n")
panel <- fread(file.path(data_dir, "panel_country_quarter.csv"))
panel_year <- fread(file.path(data_dir, "panel_country_year.csv"))

cat("  Panel:", nrow(panel), "country-quarter obs\n")
cat("  Countries:", uniqueN(panel$country), "\n")
cat("  Time range:", min(panel$contract_year), "-", max(panel$contract_year), "\n")

# ============================================================
# PART 1: TWFE baseline (for comparison, known issues with staggered)
# ============================================================
cat("\n=== TWFE Baseline Estimates ===\n")

# Primary: single-bidder share
twfe_single <- feols(single_bidder_share ~ treated | country + time_period,
                     data = panel, cluster = ~country,
                     weights = ~n_contracts)

# Secondary outcomes
twfe_bids <- feols(log_mean_bids ~ treated | country + time_period,
                   data = panel, cluster = ~country,
                   weights = ~n_contracts)

twfe_sme <- feols(sme_winner_share ~ treated | country + time_period,
                  data = panel[!is.na(sme_winner_share)], cluster = ~country,
                  weights = ~n_contracts)

twfe_ratio <- feols(mean_award_ratio ~ treated | country + time_period,
                    data = panel[!is.na(mean_award_ratio)], cluster = ~country,
                    weights = ~n_contracts)

twfe_open <- tryCatch({
  feols(open_proc_share ~ treated | country + time_period,
        data = panel[!is.na(open_proc_share) & is.finite(open_proc_share)],
        cluster = ~country, weights = ~n_contracts)
}, error = function(e) {
  cat("  open_proc_share model failed:", e$message, "\n")
  NULL
})

twfe_time <- tryCatch({
  feols(mean_processing_days ~ treated | country + time_period,
        data = panel[!is.na(mean_processing_days) & is.finite(mean_processing_days)],
        cluster = ~country, weights = ~n_contracts)
}, error = function(e) {
  cat("  processing_days model failed:", e$message, "\n")
  NULL
})

cat("\n--- TWFE Results (comparison only) ---\n")
twfe_models <- Filter(Negate(is.null), list(twfe_single, twfe_bids, twfe_sme, twfe_ratio))
if (length(twfe_models) >= 2) etable(twfe_models[[1]], twfe_models[[2]], twfe_models[[3]], twfe_models[[4]])
for (m in c("twfe_single", "twfe_bids", "twfe_sme", "twfe_ratio")) {
  obj <- get(m)
  if (!is.null(obj)) cat("  ", m, ": coef =", round(coef(obj)["treated"], 4),
                          "SE =", round(se(obj)["treated"], 4), "\n")
}

# ============================================================
# PART 2: Callaway-Sant'Anna staggered DiD (preferred)
# ============================================================
cat("\n=== Callaway-Sant'Anna Estimates ===\n")

# Prepare data for did::att_gt
# Need: yname (outcome), tname (time), idname (unit), gname (first treatment period)
panel_cs <- panel[, .(
  country_id, time_period, first_treat_period,
  single_bidder_share, log_mean_bids, sme_winner_share,
  mean_award_ratio, open_proc_share, mean_processing_days,
  n_contracts
)]

# Drop rows with missing key variables
panel_cs <- panel_cs[!is.na(single_bidder_share) & !is.na(first_treat_period)]

# Ensure balanced panel (C-S requires it or handles unbalanced carefully)
cat("  Balanced check: ", panel_cs[, .(n = .N), by = country_id][, uniqueN(n)], "unique counts\n")

# --- Primary outcome: single-bidder share ---
cat("\n  Estimating C-S for single-bidder share...\n")
cs_single <- tryCatch({
  att_gt(
    yname = "single_bidder_share",
    tname = "time_period",
    idname = "country_id",
    gname = "first_treat_period",
    data = as.data.frame(panel_cs),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal",
    panel = FALSE
  )
}, error = function(e) {
  cat("  C-S failed:", e$message, "\n")
  cat("  Trying with nevertreated control...\n")
  # All countries eventually treated, so use notyettreated
  # If that fails, try simpler options
  tryCatch({
    att_gt(
      yname = "single_bidder_share",
      tname = "time_period",
      idname = "country_id",
      gname = "first_treat_period",
      data = as.data.frame(panel_cs),
      control_group = "notyettreated",
      anticipation = 0,
      est_method = "reg",
      base_period = "universal",
      panel = FALSE
    )
  }, error = function(e2) {
    cat("  C-S reg also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(cs_single)) {
  cat("\n  C-S ATT(g,t) summary:\n")
  summary(cs_single)

  # Aggregate to simple ATT
  cs_agg_single <- aggte(cs_single, type = "simple")
  cat("\n  Aggregate ATT (single-bidder share):\n")
  summary(cs_agg_single)

  # Dynamic event-study aggregation
  cs_es_single <- aggte(cs_single, type = "dynamic", min_e = -8, max_e = 12)
  cat("\n  Event study ATT:\n")
  summary(cs_es_single)
}

# --- Secondary: log mean bids ---
cat("\n  Estimating C-S for log mean bids...\n")
cs_bids <- tryCatch({
  att_gt(
    yname = "log_mean_bids",
    tname = "time_period",
    idname = "country_id",
    gname = "first_treat_period",
    data = as.data.frame(panel_cs[!is.na(log_mean_bids)]),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal",
    panel = FALSE
  )
}, error = function(e) {
  cat("  C-S for bids failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_bids)) {
  cs_agg_bids <- aggte(cs_bids, type = "simple")
  cs_es_bids <- aggte(cs_bids, type = "dynamic", min_e = -8, max_e = 12)
  cat("\n  Aggregate ATT (log bids):\n")
  summary(cs_agg_bids)
}

# --- Secondary: SME winner share ---
cat("\n  Estimating C-S for SME winner share...\n")
cs_sme <- tryCatch({
  att_gt(
    yname = "sme_winner_share",
    tname = "time_period",
    idname = "country_id",
    gname = "first_treat_period",
    data = as.data.frame(panel_cs[!is.na(sme_winner_share)]),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal",
    panel = FALSE
  )
}, error = function(e) {
  cat("  C-S for SME failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_sme)) {
  cs_agg_sme <- tryCatch(aggte(cs_sme, type = "simple", na.rm = TRUE), error = function(e) NULL)
  cs_es_sme <- tryCatch(aggte(cs_sme, type = "dynamic", min_e = -8, max_e = 12, na.rm = TRUE), error = function(e) NULL)
  if (!is.null(cs_agg_sme)) {
    cat("\n  Aggregate ATT (SME share):\n")
    summary(cs_agg_sme)
  } else {
    cat("  SME aggregation failed (sparse pre-treatment data)\n")
  }
}

# ============================================================
# PART 3: Event study with fixest (Sun & Abraham style)
# ============================================================
cat("\n=== fixest Event Study (Sun-Abraham) ===\n")

# Trim event time for clean estimation
panel[, et_trim := pmin(pmax(event_time, -8), 12)]

# Sun-Abraham using fixest's sunab()
sa_single <- tryCatch({
  feols(single_bidder_share ~ sunab(cohort_yq, yq) | country + time_period,
        data = panel, cluster = ~country,
        weights = ~n_contracts)
}, error = function(e) {
  cat("  sunab failed:", e$message, "\n")
  # Fallback: standard event study with leads/lags
  feols(single_bidder_share ~ i(et_trim, ref = -1) | country + time_period,
        data = panel, cluster = ~country,
        weights = ~n_contracts)
})

cat("\n  Sun-Abraham event study (single-bidder share):\n")
summary(sa_single)

sa_bids <- tryCatch({
  feols(log_mean_bids ~ sunab(cohort_yq, yq) | country + time_period,
        data = panel, cluster = ~country,
        weights = ~n_contracts)
}, error = function(e) {
  feols(log_mean_bids ~ i(et_trim, ref = -1) | country + time_period,
        data = panel, cluster = ~country,
        weights = ~n_contracts)
})

# ============================================================
# PART 4: Heterogeneity by administrative capacity
# ============================================================
cat("\n=== Heterogeneity by Administrative Capacity ===\n")

# Split by median governance effectiveness
panel[, high_capacity := as.integer(gov_effectiveness_2014 >= median(gov_effectiveness_2014, na.rm = TRUE))]

het_high <- feols(single_bidder_share ~ treated | country + time_period,
                  data = panel[high_capacity == 1], cluster = ~country,
                  weights = ~n_contracts)

het_low <- feols(single_bidder_share ~ treated | country + time_period,
                 data = panel[high_capacity == 0], cluster = ~country,
                 weights = ~n_contracts)

cat("\n  Heterogeneity results:\n")
etable(het_high, het_low,
       headers = c("High capacity", "Low capacity"))

# ============================================================
# PART 5: Procedural channel (mechanism)
# ============================================================
cat("\n=== Mechanism: Procedure Type Shift ===\n")

# Did the reform shift contracts toward negotiated procedures?
mech_open <- tryCatch(
  feols(open_proc_share ~ treated | country + time_period,
        data = panel[!is.na(open_proc_share) & open_proc_share > 0],
        cluster = ~country, weights = ~n_contracts),
  error = function(e) { cat("  mech_open failed:", e$message, "\n"); NULL })

mech_time <- tryCatch(
  feols(mean_processing_days ~ treated | country + time_period,
        data = panel[!is.na(mean_processing_days) & mean_processing_days > 0],
        cluster = ~country, weights = ~n_contracts),
  error = function(e) { cat("  mech_time failed:", e$message, "\n"); NULL })

cat("\n  Mechanism results:\n")
for (m in list(mech_open, mech_time)) {
  if (!is.null(m)) cat("  coef =", round(coef(m)["treated"], 4),
                        "SE =", round(se(m)["treated"], 4), "\n")
}

# ============================================================
# PART 6: Save results
# ============================================================
cat("\n=== Saving results ===\n")

# Save TWFE coefficients
safe_coef <- function(m) if (!is.null(m)) coef(m)["treated"] else NA_real_
safe_se <- function(m) if (!is.null(m)) se(m)["treated"] else NA_real_

twfe_results <- data.table(
  outcome = c("single_bidder_share", "log_mean_bids", "sme_winner_share",
              "award_ratio", "open_proc_share", "processing_days"),
  coef = c(safe_coef(twfe_single), safe_coef(twfe_bids),
           safe_coef(twfe_sme), safe_coef(twfe_ratio),
           safe_coef(twfe_open), safe_coef(twfe_time)),
  se = c(safe_se(twfe_single), safe_se(twfe_bids),
         safe_se(twfe_sme), safe_se(twfe_ratio),
         safe_se(twfe_open), safe_se(twfe_time))
)
twfe_results[, t_stat := coef / se]
twfe_results[, p_value := 2 * pnorm(-abs(t_stat))]
twfe_results[, stars := fifelse(p_value < 0.01, "***",
                         fifelse(p_value < 0.05, "**",
                           fifelse(p_value < 0.10, "*", "")))]

fwrite(twfe_results, file.path(data_dir, "twfe_results.csv"))

# Save C-S results if available
if (!is.null(cs_single)) {
  cs_results <- data.table(
    outcome = "single_bidder_share",
    att = cs_agg_single$overall.att,
    se = cs_agg_single$overall.se,
    n_groups = length(unique(cs_single$group))
  )
  if (!is.null(cs_bids)) {
    cs_results <- rbind(cs_results, data.table(
      outcome = "log_mean_bids",
      att = cs_agg_bids$overall.att,
      se = cs_agg_bids$overall.se,
      n_groups = length(unique(cs_bids$group))
    ))
  }
  if (!is.null(cs_sme) && !is.null(cs_agg_sme)) {
    cs_results <- rbind(cs_results, data.table(
      outcome = "sme_winner_share",
      att = cs_agg_sme$overall.att,
      se = cs_agg_sme$overall.se,
      n_groups = length(unique(cs_sme$group))
    ))
  }
  fwrite(cs_results, file.path(data_dir, "cs_att_results.csv"))

  # Save event study data for plotting
  if (!is.null(cs_es_single)) {
    es_data <- data.table(
      event_time = cs_es_single$egt,
      att = cs_es_single$att.egt,
      se = cs_es_single$se.egt
    )
    es_data[, ci_lower := att - 1.96 * se]
    es_data[, ci_upper := att + 1.96 * se]
    fwrite(es_data, file.path(data_dir, "cs_event_study_single_bidder.csv"))
  }

  if (!is.null(cs_bids) && !is.null(cs_es_bids)) {
    es_bids <- data.table(
      event_time = cs_es_bids$egt,
      att = cs_es_bids$att.egt,
      se = cs_es_bids$se.egt
    )
    es_bids[, ci_lower := att - 1.96 * se]
    es_bids[, ci_upper := att + 1.96 * se]
    fwrite(es_bids, file.path(data_dir, "cs_event_study_log_bids.csv"))
  }

  if (!is.null(cs_sme) && !is.null(cs_es_sme)) {
    es_sme <- data.table(
      event_time = cs_es_sme$egt,
      att = cs_es_sme$att.egt,
      se = cs_es_sme$se.egt
    )
    es_sme[, ci_lower := att - 1.96 * se]
    es_sme[, ci_upper := att + 1.96 * se]
    fwrite(es_sme, file.path(data_dir, "cs_event_study_sme.csv"))
  }
}

# Save heterogeneity results
het_results <- data.table(
  group = c("High admin capacity", "Low admin capacity"),
  coef = c(coef(het_high)["treated"], coef(het_low)["treated"]),
  se = c(se(het_high)["treated"], se(het_low)["treated"]),
  n_countries = c(uniqueN(panel[high_capacity == 1]$country),
                  uniqueN(panel[high_capacity == 0]$country))
)
fwrite(het_results, file.path(data_dir, "heterogeneity_capacity.csv"))

# Save mechanism results
mech_results <- data.table(
  outcome = c("open_proc_share", "processing_days"),
  coef = c(safe_coef(mech_open), safe_coef(mech_time)),
  se = c(safe_se(mech_open), safe_se(mech_time))
)
fwrite(mech_results, file.path(data_dir, "mechanism_results.csv"))

# Save fixest models for later use (filter out NULLs)
model_list <- list(
  twfe_single = twfe_single, twfe_bids = twfe_bids, twfe_sme = twfe_sme,
  twfe_ratio = twfe_ratio, twfe_open = twfe_open, twfe_time = twfe_time,
  sa_single = sa_single, sa_bids = sa_bids,
  het_high = het_high, het_low = het_low,
  mech_open = mech_open, mech_time = mech_time
)
if (exists("cs_single")) model_list$cs_single <- cs_single
if (exists("cs_bids")) model_list$cs_bids <- cs_bids
if (exists("cs_sme")) model_list$cs_sme <- cs_sme
saveRDS(model_list, file.path(data_dir, "models.rds"))

cat("\n03_main_analysis.R complete.\n")
