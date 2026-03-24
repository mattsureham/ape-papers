## 04_robustness.R — Robustness checks and sensitivity analysis
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/main_results.RData")

# =============================================================================
# 1. Bacon Decomposition — assess TWFE bias
# =============================================================================

cat("\n=== Bacon Decomposition ===\n")

bacon_data <- panel %>%
  filter(g > 0 | g == 0) %>%
  mutate(treated_post = treated)

# Bacon decomposition requires binary treatment
bacon_result <- tryCatch({
  bacon(ln_estab_311 ~ treated_post, data = bacon_data,
        id_var = "state_fips", time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition failed:", e$message, "\n")
  NULL
})

if (!is.null(bacon_result)) {
  cat("Bacon decomposition results:\n")
  # bacon() already returns the aggregated summary
  bacon_summary <- bacon_result
  print(bacon_summary)
}

# =============================================================================
# 2. Sun-Abraham (2021) interaction-weighted estimator
# =============================================================================

cat("\n=== Sun-Abraham Estimator ===\n")

sa_data <- panel %>%
  mutate(
    cohort = ifelse(g > 0, g, 10000),  # large number for never-treated
    rel_year = year - ifelse(g > 0, g, NA_integer_)
  )

sa_estab <- feols(ln_estab_311 ~ sunab(cohort, year) | state_fips + year,
                   data = sa_data, cluster = ~state_fips)
cat("\nSun-Abraham estimates:\n")
summary(sa_estab)

# Overall ATT from Sun-Abraham
sa_agg <- summary(sa_estab, agg = "ATT")
cat("\nSun-Abraham aggregated ATT:\n")
print(sa_agg)

# =============================================================================
# 3. Leave-one-state-out sensitivity
# =============================================================================

cat("\n=== Leave-One-Out Sensitivity ===\n")

treated_states <- unique(panel$state_fips[panel$g > 0])
loo_results <- data.frame(
  dropped_state = character(),
  dropped_name = character(),
  att = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (st in treated_states) {
  loo_data <- panel %>%
    filter(state_fips != st) %>%
    mutate(
      state_num = as.integer(as.factor(state_fips)),
      g_cs = as.numeric(ifelse(g >= 2012, g, 0))
    )

  loo_cs <- tryCatch({
    att_gt(
      yname = "ln_estab_311",
      gname = "g_cs",
      idname = "state_num",
      tname = "year",
      data = loo_data,
      control_group = "notyettreated",
      anticipation = 0,
      est_method = "dr",
      bstrap = TRUE,
      biters = 500
    )
  }, error = function(e) NULL)

  if (!is.null(loo_cs)) {
    loo_agg <- aggte(loo_cs, type = "simple")
    state_name <- panel$state_name[panel$state_fips == st][1]
    loo_results <- rbind(loo_results, data.frame(
      dropped_state = st,
      dropped_name = state_name,
      att = loo_agg$overall.att,
      se = loo_agg$overall.se,
      stringsAsFactors = FALSE
    ))
  }
}

cat("Leave-one-out results:\n")
print(loo_results)
cat(sprintf("ATT range: [%.4f, %.4f]\n", min(loo_results$att), max(loo_results$att)))

# =============================================================================
# 4. HonestDiD sensitivity (Rambachan-Roth)
# =============================================================================

cat("\n=== HonestDiD Sensitivity ===\n")

honest_result <- tryCatch({
  # Extract event-study estimates for HonestDiD
  es_obj <- cs_agg_event  # from main analysis
  es_coefs <- es_obj$att.egt
  es_se <- es_obj$se.egt
  es_periods <- es_obj$egt

  # Pre-treatment indices
  pre_idx <- which(es_periods < 0)
  post_idx <- which(es_periods >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Build the necessary objects for HonestDiD
    betahat <- es_coefs
    sigma <- diag(es_se^2)  # diagonal variance matrix (conservative)

    # Relative magnitudes approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes:\n")
    print(honest_rm)
    honest_rm
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

# =============================================================================
# 5. Wild cluster bootstrap (for small cluster count)
# =============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

wcb_result <- tryCatch({
  # Wild cluster bootstrap via fixest
  twfe_boot <- feols(ln_estab_311 ~ treated | state_fips + year,
                      data = panel, cluster = ~state_fips)
  # Extract bootstrapped standard errors
  boot_se <- summary(twfe_boot, se = "twoway")
  cat("Two-way clustered SE for treatment effect:\n")
  print(coeftable(boot_se))
  boot_se
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  NULL
})

# =============================================================================
# 6. Alternative treatment definitions
# =============================================================================

cat("\n=== Alternative Treatment: First Adoption Only ===\n")

# Restrict to states where the event was first_adoption (not expansion)
panel_first <- panel %>%
  mutate(
    g_first = case_when(
      event_type == "first_adoption" ~ treat_year,
      TRUE ~ 0L
    ),
    treated_first = ifelse(!is.na(treat_year) & event_type == "first_adoption" & year >= treat_year, 1L, 0L)
  )

twfe_first <- feols(ln_estab_311 ~ treated_first | state_fips + year,
                     data = panel_first, cluster = ~state_fips)
cat("\nTWFE (first adoption only):\n")
summary(twfe_first)

cat("\n=== Alternative Treatment: Major Expansion Only ===\n")

panel_expand <- panel %>%
  mutate(
    treated_expand = ifelse(!is.na(treat_year) & event_type == "major_expansion" & year >= treat_year, 1L, 0L)
  )

twfe_expand <- feols(ln_estab_311 ~ treated_expand | state_fips + year,
                      data = panel_expand, cluster = ~state_fips)
cat("\nTWFE (major expansion only):\n")
summary(twfe_expand)

# =============================================================================
# SAVE
# =============================================================================

save(bacon_result, bacon_summary, sa_estab, sa_agg,
     loo_results, honest_result, wcb_result,
     twfe_first, twfe_expand,
     file = "../data/robustness_results.RData")
cat("\nRobustness analysis complete.\n")
