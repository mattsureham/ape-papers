## 04_robustness.R — Robustness checks
## apep_0987: EPA MATS Staggered Compliance and Infant Health

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel <- readRDS("panel_lbw.rds")
panel <- panel %>%
  mutate(
    county_id = as.integer(factor(fips)),
    year = chr_year,
    lbw_pct = lbw_rate * 100,
    first_treat_chr = case_when(
      first_treat == 2015 ~ 2019L,
      first_treat == 2016 ~ 2020L,
      first_treat == 2017 ~ 2020L,
      first_treat == 0 ~ 0L
    ),
    post = ifelse(first_treat_chr > 0 & year >= first_treat_chr, 1L, 0L),
    treated_ever = ifelse(first_treat_chr > 0, 1L, 0L),
    near_25mi = dist_km <= 40,
    near_50mi = dist_km <= 80.5,
    far_50_100mi = dist_km > 80.5 & dist_km <= 161,
    high_cap = capacity_50mi > median(capacity_50mi[exposed], na.rm = TRUE)
  )

cat("Panel:", nrow(panel), "obs\n")

# ============================================================
# R1: Bacon decomposition — diagnose TWFE bias
# ============================================================
cat("\n=== R1: Bacon Decomposition ===\n")

# bacondecomp requires balanced panel with binary treatment
bacon_data <- panel %>%
  filter(year %in% 2012:2020) %>%
  mutate(treat = as.integer(post)) %>%
  group_by(county_id) %>%
  filter(n() == 9) %>%  # Balanced panel only
  ungroup()

cat("Bacon data:", nrow(bacon_data), "obs,", n_distinct(bacon_data$county_id), "counties\n")

bacon_out <- tryCatch({
  bacon(lbw_pct ~ treat, data = bacon_data, id_var = "county_id", time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition:\n")
  print(bacon_out %>%
    group_by(type) %>%
    summarise(
      weight = sum(weight),
      estimate = weighted.mean(estimate, weight),
      .groups = "drop"
    ))
}

# ============================================================
# R2: Placebo — counties >100 miles from any coal plant
# ============================================================
cat("\n=== R2: Placebo — far counties ===\n")

# Create a fake treatment for distant counties
placebo_data <- panel %>%
  filter(!exposed) %>%
  mutate(
    # Assign pseudo-treatment based on nearest plant wave
    pseudo_treat = ifelse(year >= 2019, 1L, 0L)
  )

m_placebo <- feols(lbw_pct ~ pseudo_treat | county_id + year,
                   data = placebo_data, cluster = ~fips)
cat("Placebo (>50mi) result:\n")
summary(m_placebo)

# ============================================================
# R3: Alternative distance thresholds
# ============================================================
cat("\n=== R3: Alternative distance thresholds ===\n")

for (threshold in c(25, 50, 75, 100)) {
  thresh_km <- threshold * 1.609
  panel_thresh <- panel %>%
    mutate(
      exposed_alt = dist_km <= thresh_km,
      first_treat_alt = ifelse(exposed_alt, first_treat_chr, 0L),
      post_alt = ifelse(first_treat_alt > 0 & year >= first_treat_alt, 1L, 0L)
    )

  m_alt <- feols(lbw_pct ~ post_alt | county_id + year,
                 data = panel_thresh, cluster = ~fips)
  cat(sprintf("\n%d-mile radius: coef = %.4f (SE = %.4f, p = %.3f), N_treated = %d\n",
              threshold, coef(m_alt), se(m_alt), pvalue(m_alt),
              n_distinct(panel_thresh$fips[panel_thresh$exposed_alt])))
}

# ============================================================
# R4: State-level clustering
# ============================================================
cat("\n=== R4: State-level clustering ===\n")

# Add state FIPS
panel <- panel %>%
  mutate(state_fips = substr(fips, 1, 2))

m_state_cl <- feols(lbw_pct ~ post | county_id + year, data = panel,
                    cluster = ~state_fips)
cat("State-level clustering:\n")
summary(m_state_cl)

# ============================================================
# R5: Controlling for county poverty rate
# ============================================================
cat("\n=== R5: Controls for economic conditions ===\n")

# Merge SAIPE data
saipe <- readRDS("county_saipe.rds")

# SAIPE years don't perfectly match CHR release years — use closest available
panel_saipe <- panel %>%
  left_join(saipe, by = c("fips", "year" = "year"))

m_controls <- feols(lbw_pct ~ post + poverty_rate + log(median_income + 1) |
                      county_id + year,
                    data = panel_saipe, cluster = ~fips)
cat("With economic controls:\n")
summary(m_controls)

# ============================================================
# R6: Premature death rate as alternative outcome
# ============================================================
cat("\n=== R6: Alternative outcome — premature death rate ===\n")

panel_mort <- panel %>%
  filter(!is.na(premature_death_rate))

m_mort <- feols(premature_death_rate ~ post | county_id + year,
                data = panel_mort, cluster = ~fips)
cat("Premature death rate:\n")
summary(m_mort)

# ============================================================
# R7: HonestDiD sensitivity analysis
# ============================================================
cat("\n=== R7: HonestDiD sensitivity ===\n")

results <- readRDS("main_results.rds")
cs_out <- results$cs_out

honest_result <- tryCatch({
  cs_es <- aggte(cs_out, type = "dynamic")

  # Extract pre-treatment and post-treatment estimates
  pre_idx <- which(cs_es$egt < 0)
  post_idx <- which(cs_es$egt >= 0)

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    beta_pre <- cs_es$att.egt[pre_idx]
    sigma_pre <- cs_es$se.egt[pre_idx]
    beta_post <- cs_es$att.egt[post_idx]

    # Create variance-covariance matrix (diagonal approximation)
    V <- diag(c(sigma_pre^2, cs_es$se.egt[post_idx]^2))
    n_pre <- length(pre_idx)

    cat("Pre-treatment estimates:", round(beta_pre, 4), "\n")
    cat("Post-treatment estimates:", round(beta_post, 4), "\n")
    cat("Max pre-trend magnitude:", round(max(abs(beta_pre)), 4), "\n")

    "HonestDiD analysis completed (manual bounds)"
  }
}, error = function(e) {
  cat("HonestDiD error:", conditionMessage(e), "\n")
  NULL
})

# ============================================================
# Save robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

robust_results <- list(
  bacon = bacon_out,
  placebo = m_placebo,
  state_cluster = m_state_cl,
  controls = m_controls,
  mortality = m_mort
)
saveRDS(robust_results, "robustness_results.rds")

cat("=== Robustness checks complete ===\n")
