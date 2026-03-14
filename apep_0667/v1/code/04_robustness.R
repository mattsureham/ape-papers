## 04_robustness.R — Robustness checks and placebo tests
## apep_0667: EBT rollout and drug-market disruption

source("00_packages.R")

cat("=== Loading data and main results ===\n")
panel        <- readRDS("../data/panel.rds")
results_main <- readRDS("../data/results_main.rds")

# Use full panel for TWFE, restricted panel for CS-DiD
# Drop 1998/1999 cohorts from CS-DiD (no pre-treatment data)
panel_main <- panel %>% filter(!is.na(drug_death_rate))
panel_cs <- panel_main %>%
  mutate(first_treat_cs = if_else(first_treat <= 1999, 0L, first_treat)) %>%
  filter(first_treat_cs > 0)

cat("  Full panel:", nrow(panel_main), "rows\n")
cat("  CS sample:", nrow(panel_cs), "rows,", n_distinct(panel_cs$state_id), "states\n")

# ===================================================================
cat("\n=== 1. Placebo tests ===\n")
# ===================================================================
# TWFE placebos (more stable with small samples than CS-DiD)
# If EBT disrupts drug markets, it should NOT affect suicide, injuries, heart disease

placebo_outcomes <- c("suicide_rate", "injury_rate", "heart_rate")
placebo_labels   <- c("Suicide", "Unintentional Injuries", "Heart Disease")
placebo_results  <- list()

for (i in seq_along(placebo_outcomes)) {
  yvar  <- placebo_outcomes[i]
  label <- placebo_labels[i]

  # TWFE on full panel
  twfe_p <- feols(
    as.formula(paste0(yvar, " ~ treated | state_id + year")),
    data    = panel_main,
    cluster = ~state_id
  )

  att <- coef(twfe_p)["treated"]
  se_val <- se(twfe_p)["treated"]
  cat(sprintf("  %-25s: β = %7.3f (SE = %6.3f), t = %5.2f\n",
              label, att, se_val, att / se_val))

  # Also try CS-DiD on restricted sample
  cs_p <- tryCatch({
    cs_tmp <- att_gt(
      yname = yvar, tname = "year", idname = "state_id",
      gname = "first_treat_cs", data = panel_cs,
      control_group = "notyettreated", anticipation = 0,
      est_method = "dr", bstrap = TRUE, biters = 500
    )
    aggte(cs_tmp, type = "simple")
  }, error = function(e) {
    cat(sprintf("    CS-DiD failed: %s\n", conditionMessage(e)))
    NULL
  })

  placebo_results[[yvar]] <- list(
    label  = label,
    twfe   = twfe_p,
    cs_att = if (!is.null(cs_p)) cs_p$overall.att else NA,
    cs_se  = if (!is.null(cs_p)) cs_p$overall.se else NA,
    n_obs  = nrow(panel_main)
  )
}

# ===================================================================
cat("\n=== 2. HonestDiD sensitivity analysis ===\n")
# ===================================================================
# TWFE event study for HonestDiD
twfe_es <- feols(
  drug_death_rate ~ i(rel_time, ref = -1) | state_id + year,
  data    = panel_main,
  cluster = ~state_id
)

beta_hat  <- coef(twfe_es)
sigma_hat <- vcov(twfe_es)
coef_names <- names(beta_hat)

pre_idx  <- grep("rel_time::-", coef_names)
post_idx <- grep("rel_time::[0-9]", coef_names)

honest_results <- tryCatch({
  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    es_honest <- HonestDiD::createSensitivityResults(
      betahat        = beta_hat,
      sigma          = sigma_hat,
      numPrePeriods  = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec           = seq(0, 2, by = 0.5)
    )
    cat("  HonestDiD (TWFE-based) results:\n")
    print(es_honest)
    list(honest = es_honest, twfe_es = twfe_es)
  } else {
    cat("  Insufficient pre/post periods\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD error:", conditionMessage(e), "\n")
  NULL
})

# ===================================================================
cat("\n=== 3. Leave-one-cohort-out (TWFE) ===\n")
# ===================================================================
cohorts <- sort(unique(panel_main$ebt_year))
loco_results <- list()

for (g in cohorts) {
  pdata <- panel_main %>% filter(ebt_year != g)
  n_st <- n_distinct(pdata$state_id)

  loco_twfe <- feols(
    drug_death_rate ~ treated | state_id + year,
    data = pdata, cluster = ~state_id
  )

  att <- coef(loco_twfe)["treated"]
  se_val <- se(loco_twfe)["treated"]
  cat(sprintf("  Drop %d (%d states remain): β = %7.3f (SE = %6.3f)\n",
              g, n_st, att, se_val))

  loco_results[[as.character(g)]] <- list(
    dropped_cohort = g,
    att = att,
    se = se_val,
    n_states = n_st,
    n_obs = nrow(pdata)
  )
}

loco_df <- bind_rows(lapply(loco_results, as.data.frame))
cat("\n  Leave-one-cohort-out summary:\n")
print(loco_df)

# ===================================================================
cat("\n=== 4. TWFE with state-specific linear trends ===\n")
# ===================================================================
twfe_trends <- feols(
  drug_death_rate ~ treated | state_id + year + state_id[year],
  data    = panel_main,
  cluster = ~state_id
)

cat("  TWFE + trends: β =", round(coef(twfe_trends)["treated"], 3),
    "(SE =", round(se(twfe_trends)["treated"], 3), ")\n")

# ===================================================================
cat("\n=== 5. TWFE event study ===\n")
# ===================================================================
twfe_es_tidy <- data.frame(
  rel_time = as.integer(gsub("rel_time::", "", coef_names)),
  estimate = beta_hat,
  se       = sqrt(diag(sigma_hat))
) %>% arrange(rel_time)
cat("  Event study coefficients:\n")
print(twfe_es_tidy)

# ===================================================================
cat("\n=== 6. Log-deaths (Poisson) specification ===\n")
# ===================================================================
panel_counts <- panel_main %>%
  filter(!is.na(drug_deaths), drug_deaths > 0, !is.na(pop_fred), pop_fred > 0) %>%
  mutate(ln_deaths = log(drug_deaths), ln_pop = log(pop_fred))

twfe_counts <- feols(
  ln_deaths ~ treated + ln_pop | state_id + year,
  data    = panel_counts,
  cluster = ~state_id
)

cat("  Log-deaths: β =", round(coef(twfe_counts)["treated"], 4),
    "(SE =", round(se(twfe_counts)["treated"], 4), ")\n")

# ===================================================================
cat("\n=== Saving robustness results ===\n")
# ===================================================================
robustness <- list(
  placebo      = placebo_results,
  honest       = honest_results,
  loco         = loco_results,
  loco_df      = loco_df,
  twfe_trends  = twfe_trends,
  twfe_es      = twfe_es,
  twfe_es_tidy = twfe_es_tidy,
  twfe_counts  = twfe_counts
)
saveRDS(robustness, "../data/results_robustness.rds")
cat("  Saved results_robustness.rds\n")
cat("\n=== Robustness analysis complete ===\n")
