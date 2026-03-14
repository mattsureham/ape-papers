## 04_robustness.R — Robustness checks for APEP-0683
## Council Tax Empty Homes Premium and Long-Term Vacancy

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ============================================================
## 1. Placebo outcome: All vacants (short-term + long-term)
## ============================================================
cat("=== Placebo: All vacants ===\n")

m_placebo <- feols(log_av ~ treated_post | la_id + year,
                   data = panel %>% filter(!is.na(log_av)),
                   cluster = ~ons_code)
cat("  Placebo (log all vacants):", round(coef(m_placebo), 4),
    "SE:", round(sqrt(diag(vcov(m_placebo))), 4), "\n")

## ============================================================
## 2. Alternative clustering: Region level
## ============================================================
cat("\n=== Alternative clustering ===\n")

# Need region indicator — infer from ONS code patterns
panel <- panel %>%
  mutate(region = case_when(
    str_detect(ons_code, "^E09") ~ "London",
    str_detect(ons_code, "^E08") ~ "Metropolitan",
    TRUE ~ substr(ons_code, 1, 3)
  ))

m_region <- feols(log_ltv ~ treated_post | la_id + year,
                  data = panel %>% filter(!is.na(log_ltv)),
                  cluster = ~region)
cat("  Region-clustered:", round(coef(m_region), 4),
    "SE:", round(sqrt(diag(vcov(m_region))), 4), "\n")

## ============================================================
## 3. Exclude London (outlier housing dynamics)
## ============================================================
cat("\n=== Exclude London ===\n")

m_no_london <- feols(log_ltv ~ treated_post | la_id + year,
                     data = panel %>% filter(!str_detect(ons_code, "^E09"), !is.na(log_ltv)),
                     cluster = ~ons_code)
cat("  Excl. London:", round(coef(m_no_london), 4),
    "SE:", round(sqrt(diag(vcov(m_no_london))), 4), "\n")

## ============================================================
## 4. Pre-treatment window only (falsification)
## ============================================================
cat("\n=== Falsification: Fake treatment at 2009 ===\n")

panel_pre <- panel %>%
  filter(year <= 2012) %>%
  mutate(fake_post = year >= 2009,
         fake_treat = ever_treated & fake_post)

m_fake <- feols(log_ltv ~ fake_treat | la_id + year,
                data = panel_pre %>% filter(!is.na(log_ltv)),
                cluster = ~ons_code)
cat("  Fake treatment (2009):", round(coef(m_fake), 4),
    "SE:", round(sqrt(diag(vcov(m_fake))), 4), "\n")

## ============================================================
## 5. Short pre/post window (2010-2016)
## ============================================================
cat("\n=== Short window (2010-2016) ===\n")

m_short <- feols(log_ltv ~ treated_post | la_id + year,
                 data = panel %>% filter(year >= 2010, year <= 2016, !is.na(log_ltv)),
                 cluster = ~ons_code)
cat("  Short window:", round(coef(m_short), 4),
    "SE:", round(sqrt(diag(vcov(m_short))), 4), "\n")

## ============================================================
## 6. HonestDiD sensitivity analysis
## ============================================================
cat("\n=== HonestDiD sensitivity ===\n")

es_model <- readRDS(file.path(data_dir, "model_es_sunab.rds"))

# Extract pre-treatment and post-treatment coefficients
es_coefs <- coef(es_model)
es_vcov <- vcov(es_model)
coef_names <- names(es_coefs)

# Identify pre-treatment and post-treatment periods
pre_idx <- which(str_detect(coef_names, "year::-\\d+"))
post_idx <- which(str_detect(coef_names, "year::\\d+") & !str_detect(coef_names, "year::-"))

if (length(pre_idx) > 0 & length(post_idx) > 0) {
  honest_result <- tryCatch({
    # Rambachan-Roth bounds: how much can the post-treatment trend deviate
    # from the pre-treatment trend while still yielding a null?
    betahat <- es_coefs[c(pre_idx, post_idx)]
    sigma <- es_vcov[c(pre_idx, post_idx), c(pre_idx, post_idx)]

    # Use HonestDiD's createSensitivityResults
    l_vec <- rep(0, length(betahat))
    l_vec[length(pre_idx) + 1] <- 1  # First post-treatment period

    honest <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      l_vec = l_vec,
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("  HonestDiD bounds:\n")
    print(honest)
    honest
  }, error = function(e) {
    cat("  HonestDiD error:", conditionMessage(e), "\n")
    NULL
  })
} else {
  cat("  Could not extract pre/post coefficients for HonestDiD.\n")
}

## ============================================================
## 7. Goodman-Bacon decomposition (TWFE diagnostics)
## ============================================================
cat("\n=== Goodman-Bacon decomposition ===\n")

# Since we have nearly common timing (all treated in 2013),
# the decomposition is nearly trivial: one 2x2 comparison
bacon_data <- panel %>%
  filter(!is.na(log_ltv)) %>%
  mutate(treated_binary = as.integer(ever_treated),
         post_binary = as.integer(post)) %>%
  select(la_id, year, log_ltv, treated_binary) %>%
  as.data.frame()

bacon_result <- tryCatch({
  bacon(log_ltv ~ treated_binary, data = bacon_data,
        id_var = "la_id", time_var = "year")
}, error = function(e) {
  cat("  Bacon decomposition error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(bacon_result)) {
  cat("  Bacon decomposition results:\n")
  print(bacon_result)
}

## ============================================================
## Save robustness results
## ============================================================
cat("\n=== Saving robustness results ===\n")

rob <- list(
  placebo = m_placebo,
  region_cluster = m_region,
  no_london = m_no_london,
  fake_2009 = m_fake,
  short_window = m_short
)
saveRDS(rob, file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness analysis complete.\n")
