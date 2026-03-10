# ============================================================================
# 04_robustness.R — Robustness checks
# APEP Paper apep_0566
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))
panel_states <- panel[is_state == TRUE]
cs_result <- readRDS(paste0(data_dir, "cs_result.rds"))

# ============================================================================
# 1. Bacon Decomposition
# ============================================================================

cat("\n=== Bacon Decomposition ===\n")

bacon_out <- tryCatch({
  bacon(drug_od_rate ~ treated,
        data = as.data.frame(panel_states),
        id_var = "state_fips",
        time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  bacon_df <- as.data.table(bacon_out)
  cat("Bacon components:\n")
  bacon_summary <- bacon_df[, .(
    weight = sum(weight),
    weighted_est = sum(estimate * weight) / sum(weight)
  ), by = type]
  print(bacon_summary)
  fwrite(bacon_df, paste0(data_dir, "bacon_decomposition.csv"))
}

# ============================================================================
# 2. HonestDiD Sensitivity Analysis
# ============================================================================

cat("\n=== HonestDiD Sensitivity ===\n")

agg_dynamic <- aggte(cs_result, type = "dynamic", min_e = -8, max_e = 6)

honest_result <- tryCatch({
  # Extract event study for HonestDiD
  es_coefs <- agg_dynamic$att.egt
  es_se <- agg_dynamic$se.egt
  es_times <- agg_dynamic$egt

  # Need V-Cov matrix - approximate with diagonal
  V <- diag(es_se^2)

  # Indices: pre-treatment and post-treatment
  pre_idx <- which(es_times < 0)
  post_idx <- which(es_times >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Relative magnitudes approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = es_coefs,
      sigma = V,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes:\n")
    print(honest_rm)
    as.data.table(honest_rm)
  } else {
    cat("Not enough pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  NULL
})

if (!is.null(honest_result)) {
  fwrite(honest_result, paste0(data_dir, "honestdid_results.csv"))
}

# ============================================================================
# 3. Randomization Inference
# ============================================================================

cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_perm <- 500

# Actual ATT
actual_att <- aggte(cs_result, type = "simple")$overall.att

# Permute treatment assignment
ri_atts <- numeric(n_perm)
treated_states <- unique(panel_states[treated_ever == TRUE]$state_fips)
all_states <- unique(panel_states$state_fips)
n_treated <- length(treated_states)

for (i in 1:n_perm) {
  if (i %% 50 == 0) cat("  RI iteration", i, "/", n_perm, "\n")

  # Random assignment of treatment status
  fake_treated <- sample(all_states, n_treated)
  panel_perm <- copy(panel_states)

  # Assign reform years randomly from actual distribution
  reform_yrs <- panel_states[treated_ever == TRUE, unique(reform_year)]
  fake_reforms <- data.table(
    state_fips = fake_treated,
    fake_gvar = sample(reform_yrs, n_treated, replace = TRUE)
  )

  panel_perm <- merge(panel_perm, fake_reforms, by = "state_fips", all.x = TRUE)
  panel_perm[, perm_gvar := ifelse(!is.na(fake_gvar), fake_gvar, 0)]

  cs_perm <- tryCatch(
    att_gt(yname = "drug_od_rate", tname = "year", idname = "state_fips",
           gname = "perm_gvar", data = as.data.frame(panel_perm),
           control_group = "notyettreated", anticipation = 0,
           est_method = "dr", base_period = "universal",
           print_details = FALSE),
    error = function(e) NULL
  )

  if (!is.null(cs_perm)) {
    agg_perm <- tryCatch(aggte(cs_perm, type = "simple"), error = function(e) NULL)
    ri_atts[i] <- if (!is.null(agg_perm)) agg_perm$overall.att else NA
  } else {
    ri_atts[i] <- NA
  }

  # Cleanup
  rm(panel_perm, fake_reforms)
}

ri_atts <- ri_atts[!is.na(ri_atts)]
ri_pvalue <- mean(abs(ri_atts) >= abs(actual_att))
cat("RI p-value:", round(ri_pvalue, 4), "(", length(ri_atts), "valid permutations)\n")

ri_df <- data.table(
  actual_att = actual_att,
  ri_p_value = ri_pvalue,
  n_permutations = length(ri_atts),
  ri_mean = mean(ri_atts),
  ri_sd = sd(ri_atts)
)
fwrite(ri_df, paste0(data_dir, "ri_results.csv"))
fwrite(data.table(perm_att = ri_atts), paste0(data_dir, "ri_distribution.csv"))

# ============================================================================
# 4. Leave-One-Out
# ============================================================================

cat("\n=== Leave-One-Out ===\n")

loo_results <- list()
for (st in unique(panel_states$state_fips)) {
  panel_loo <- panel_states[state_fips != st]

  cs_loo <- tryCatch(
    att_gt(yname = "drug_od_rate", tname = "year", idname = "state_fips",
           gname = "gvar", data = as.data.frame(panel_loo),
           control_group = "notyettreated", anticipation = 0,
           est_method = "dr", base_period = "universal",
           print_details = FALSE),
    error = function(e) NULL
  )

  if (!is.null(cs_loo)) {
    agg_loo <- tryCatch(aggte(cs_loo, type = "simple"), error = function(e) NULL)
    if (!is.null(agg_loo)) {
      loo_results[[length(loo_results) + 1]] <- data.table(
        dropped_state = st,
        att = agg_loo$overall.att,
        se = agg_loo$overall.se
      )
    }
  }
}

if (length(loo_results) > 0) {
  loo_df <- rbindlist(loo_results)
  loo_df <- merge(loo_df,
                  unique(panel_states[, .(state_fips, state_abbr)]),
                  by.x = "dropped_state", by.y = "state_fips")
  cat("LOO range:", round(range(loo_df$att), 4), "\n")
  fwrite(loo_df, paste0(data_dir, "leave_one_out.csv"))
}

# ============================================================================
# 5. Wild Cluster Bootstrap
# ============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

twfe_base <- feols(drug_od_rate ~ treated | state_fips + year,
                   data = panel_states, cluster = ~state_fips)

wcb <- tryCatch({
  boottest(twfe_base, param = "treated", B = 999,
           clustid = ~state_fips, type = "webb")
}, error = function(e) {
  cat("WCB error:", e$message, "\n")
  NULL
})

if (!is.null(wcb)) {
  cat("WCB p-value:", round(pvalue(wcb), 4), "\n")
  wcb_df <- data.table(
    estimate = coef(twfe_base)["treated"],
    wcb_p_value = pvalue(wcb),
    wcb_ci_lower = wcb$conf_int[1],
    wcb_ci_upper = wcb$conf_int[2]
  )
  fwrite(wcb_df, paste0(data_dir, "wcb_results.csv"))
}

# ============================================================================
# 6. Alternative Treatment Definitions
# ============================================================================

cat("\n=== Alternative Treatment: Abolition + Conviction Only ===\n")

# Strict treatment: only abolition or conviction requirement (intensity >= 2)
panel_states[, treated_strict := as.integer(treated_ever & reform_intensity >= 2 & year >= reform_year)]
panel_states[, gvar_strict := ifelse(treated_ever & reform_intensity >= 2, reform_year, 0)]

cs_strict <- tryCatch(
  att_gt(yname = "drug_od_rate", tname = "year", idname = "state_fips",
         gname = "gvar_strict", data = as.data.frame(panel_states),
         control_group = "notyettreated", anticipation = 0,
         est_method = "dr", base_period = "universal",
         print_details = FALSE),
  error = function(e) { cat("Strict CS error:", e$message, "\n"); NULL }
)

if (!is.null(cs_strict)) {
  agg_strict <- aggte(cs_strict, type = "simple")
  cat("Strict ATT:", round(agg_strict$overall.att, 4),
      "(SE:", round(agg_strict$overall.se, 4), ")\n")

  strict_df <- data.table(
    spec = "Strict (abolish + conviction)",
    estimate = agg_strict$overall.att,
    se = agg_strict$overall.se
  )
  fwrite(strict_df, paste0(data_dir, "alt_treatment_strict.csv"))
}

# ============================================================================
# 7. Never-Treated Only as Controls
# ============================================================================

cat("\n=== Never-Treated Controls Only ===\n")

cs_never <- tryCatch(
  att_gt(yname = "drug_od_rate", tname = "year", idname = "state_fips",
         gname = "gvar", data = as.data.frame(panel_states),
         control_group = "nevertreated", anticipation = 0,
         est_method = "dr", base_period = "universal",
         print_details = FALSE),
  error = function(e) { cat("Never-treated CS error:", e$message, "\n"); NULL }
)

if (!is.null(cs_never)) {
  agg_never <- aggte(cs_never, type = "simple")
  cat("Never-treated ATT:", round(agg_never$overall.att, 4),
      "(SE:", round(agg_never$overall.se, 4), ")\n")

  never_es <- aggte(cs_never, type = "dynamic", min_e = -8, max_e = 6)
  never_es_df <- data.table(
    event_time = never_es$egt,
    att = never_es$att.egt,
    se = never_es$se.egt,
    ci_lower = never_es$att.egt - 1.96 * never_es$se.egt,
    ci_upper = never_es$att.egt + 1.96 * never_es$se.egt
  )
  fwrite(never_es_df, paste0(data_dir, "cs_event_study_nevertreated.csv"))
}

# ============================================================================
# 8. Heterogeneity: Pre-Reform Drug Overdose Rate
# ============================================================================

cat("\n=== Heterogeneity by Pre-Reform OD Rate ===\n")

for (grp in c(0, 1)) {
  label <- if (grp == 1) "high" else "low"
  panel_sub <- panel_states[high_pre_drug == grp | treated_ever == FALSE]

  cs_sub <- tryCatch(
    att_gt(yname = "drug_od_rate", tname = "year", idname = "state_fips",
           gname = "gvar", data = as.data.frame(panel_sub),
           control_group = "notyettreated", anticipation = 0,
           est_method = "dr", base_period = "universal",
           print_details = FALSE),
    error = function(e) { cat("Hetero CS error:", e$message, "\n"); NULL }
  )

  if (!is.null(cs_sub)) {
    agg_sub <- aggte(cs_sub, type = "simple")
    cat("  ", label, "pre-reform OD ATT:", round(agg_sub$overall.att, 4),
        "(SE:", round(agg_sub$overall.se, 4), ")\n")
  }
}

cat("\nRobustness checks complete.\n")
