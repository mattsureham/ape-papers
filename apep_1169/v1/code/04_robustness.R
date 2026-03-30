## 04_robustness.R — Robustness checks
## apep_1169: Click to Incorporate

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# ============================================================
# A) Bacon Decomposition — TWFE weight decomposition (WBA)
# ============================================================

cat("=== Bacon Decomposition (WBA) ===\n")
bacon_out <- bacon(log_WBA ~ treated, data = panel,
                   id_var = "state_id", time_var = "ym")

bacon_summary <- bacon_out %>%
  group_by(type) %>%
  summarise(
    weight = sum(weight),
    weighted_est = sum(estimate * weight) / sum(weight),
    .groups = "drop"
  )
cat("Bacon weights:\n")
print(bacon_summary)

# ============================================================
# B) Sun-Abraham (WBA)
# ============================================================

cat("\n=== Sun-Abraham (WBA) ===\n")
panel_sa <- panel %>%
  mutate(cohort = ifelse(first_treat == 0, Inf, first_treat))

sa_wba <- feols(log_WBA ~ sunab(cohort, ym) | state_id + ym,
                data = panel_sa, cluster = ~state_id)

# Extract post-treatment coefficients
sa_coefs <- coef(sa_wba)
post_names <- names(sa_coefs)[grepl("::", names(sa_coefs))]
# Parse event times from names
event_times <- as.numeric(gsub(".*::", "", post_names))
post_att <- mean(sa_coefs[post_names[event_times >= 0]])
cat("Sun-Abraham mean post-ATT:", round(post_att, 4), "\n")

# ============================================================
# C) Leave-One-Out (WBA)
# ============================================================

cat("\n=== Leave-One-Out ===\n")
treated_states <- unique(panel$state[panel$treated_state])
loo_results <- data.frame(dropped = character(), att = numeric(),
                          se = numeric(), stringsAsFactors = FALSE)

for (st in treated_states) {
  panel_loo <- panel %>% filter(state != st)
  # Need to re-create state_id
  panel_loo$state_id <- as.integer(factor(panel_loo$state))
  cs_loo <- tryCatch({
    att_gt(
      yname = "log_WBA", tname = "ym", idname = "state_id",
      gname = "first_treat", data = panel_loo,
      control_group = "nevertreated", base_period = "universal",
      clustervars = "state_id", print_details = FALSE
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    att_loo <- aggte(cs_loo, type = "simple")
    loo_results <- rbind(loo_results,
                         data.frame(dropped = st,
                                    att = att_loo$overall.att,
                                    se = att_loo$overall.se))
    cat(sprintf("  Drop %s: ATT=%.4f (SE=%.4f)\n", st, att_loo$overall.att, att_loo$overall.se))
  } else {
    cat(sprintf("  Drop %s: FAILED\n", st))
  }
}

# ============================================================
# D) Pre-trend analysis
# ============================================================

cat("\n=== Pre-trend analysis ===\n")
es_wba <- results$es_wba
pre_idx <- which(es_wba$egt < 0)
if (length(pre_idx) > 0) {
  pre_coefs <- es_wba$att.egt[pre_idx]
  pre_se <- es_wba$se.egt[pre_idx]
  pre_egt <- es_wba$egt[pre_idx]

  cat("Pre-period event-study coefficients:\n")
  for (i in seq_along(pre_coefs)) {
    t_stat <- pre_coefs[i] / pre_se[i]
    cat(sprintf("  e=%d: %.4f (%.4f) t=%.2f\n",
                pre_egt[i], pre_coefs[i], pre_se[i], t_stat))
  }

  # Joint test
  valid <- !is.na(pre_coefs) & !is.na(pre_se) & pre_se > 0
  if (sum(valid) > 0) {
    wald <- sum((pre_coefs[valid] / pre_se[valid])^2)
    p_joint <- 1 - pchisq(wald, df = sum(valid))
    cat(sprintf("Joint Wald: chi2(%d)=%.2f, p=%.4f\n", sum(valid), wald, p_joint))
  }
}

# ============================================================
# Save
# ============================================================

rob_results <- list(
  bacon = bacon_summary,
  sa_wba = sa_wba,
  sa_att = post_att,
  loo = loo_results
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nROBUSTNESS COMPLETE.\n")
