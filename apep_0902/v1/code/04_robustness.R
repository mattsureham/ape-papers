# ============================================================================
# 04_robustness.R — Robustness checks for RTF paper
# ============================================================================

source("00_packages.R")

panel_112 <- readRDS("../data/panel_112.rds")
panel_111 <- readRDS("../data/panel_111.rds")
qwi_rh <- readRDS("../data/qwi_rh_clean.rds")
treatment_dates <- readRDS("../data/treatment_dates.rds")
twfe_main <- readRDS("../data/twfe_main.rds")

# ============================================================================
# 1. Placebo: NAICS 111 (Crop Production)
# ============================================================================

cat("=== Placebo: NAICS 111 (Crop Production) ===\n")

twfe_placebo <- feols(
  log_emp ~ treat_indicator | county_id + time_id,
  data = panel_111,
  cluster = ~state_fips
)
cat("Placebo (Crop Production):\n")
summary(twfe_placebo)

# TWFE placebo is sufficient — CS has convergence issues on crop panel

# ============================================================================
# 2. Wild Cluster Bootstrap (14 clusters → important for inference)
# ============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# boottest from fwildclusterboot
boot_result <- boottest(
  twfe_main,
  clustid = "state_fips",
  param = "treat_indicator",
  B = 9999,
  type = "rademacher",
  impose_null = TRUE
)
cat("Wild cluster bootstrap:\n")
summary(boot_result)

# ============================================================================
# 3. Leave-one-out: Drop each treated state
# ============================================================================

cat("\n=== Leave-One-Out ===\n")

treated_fips <- c("38", "37", "29", "19", "13", "48")
treated_names <- c("ND", "NC", "MO", "IA", "GA", "TX")
loo_results <- list()

for (i in seq_along(treated_fips)) {
  panel_loo <- panel_112 %>% filter(state_fips != treated_fips[i])
  fit_loo <- feols(
    log_emp ~ treat_indicator | county_id + time_id,
    data = panel_loo,
    cluster = ~state_fips
  )
  loo_results[[treated_names[i]]] <- list(
    coef = coef(fit_loo)["treat_indicator"],
    se = se(fit_loo)["treat_indicator"],
    pval = pvalue(fit_loo)["treat_indicator"],
    n = nobs(fit_loo)
  )
  cat(sprintf("Drop %s: β=%.4f, SE=%.4f, p=%.4f\n",
    treated_names[i],
    coef(fit_loo)["treat_indicator"],
    se(fit_loo)["treat_indicator"],
    pvalue(fit_loo)["treat_indicator"]
  ))
}

# ============================================================================
# 4. Hispanic/Non-Hispanic heterogeneity (Race/Ethnicity QWI)
# ============================================================================

cat("\n=== Race/Ethnicity Heterogeneity ===\n")

# Check what ethnicity/race columns are available
cat("RH columns:", paste(names(qwi_rh), collapse = ", "), "\n")

# Hispanic (ethnicity = 2) vs Non-Hispanic (ethnicity = 1)
# Ethnicity codes: A0=All, A1=Non-Hispanic, A2=Hispanic
# Hispanic workers
panel_hisp <- qwi_rh %>%
  filter(ethnicity == "A2", !is.na(Emp), Emp > 0, !is.na(county_id)) %>%
  mutate(log_emp = log(Emp))
cat(sprintf("Hispanic panel: %d obs, %d counties\n", nrow(panel_hisp), n_distinct(panel_hisp$county_id)))

if (nrow(panel_hisp) > 100) {
  twfe_hisp <- feols(
    log_emp ~ treat_indicator | county_id + time_id,
    data = panel_hisp,
    cluster = ~state_fips
  )
  cat("Hispanic workers:\n")
  summary(twfe_hisp)
} else {
  cat("Too few Hispanic observations for regression.\n")
  twfe_hisp <- NULL
}

# Non-Hispanic workers
panel_nonhisp <- qwi_rh %>%
  filter(ethnicity == "A1", !is.na(Emp), Emp > 0, !is.na(county_id)) %>%
  mutate(log_emp = log(Emp))
cat(sprintf("Non-Hispanic panel: %d obs, %d counties\n", nrow(panel_nonhisp), n_distinct(panel_nonhisp$county_id)))

if (nrow(panel_nonhisp) > 100) {
  twfe_nonhisp <- feols(
    log_emp ~ treat_indicator | county_id + time_id,
    data = panel_nonhisp,
    cluster = ~state_fips
  )
  cat("Non-Hispanic workers:\n")
  summary(twfe_nonhisp)
} else {
  cat("Too few Non-Hispanic observations for regression.\n")
  twfe_nonhisp <- NULL
}

# ============================================================================
# 5. Save robustness results
# ============================================================================

saveRDS(list(
  placebo_twfe = twfe_placebo,
  boot = boot_result,
  loo = loo_results,
  hisp = twfe_hisp,
  nonhisp = twfe_nonhisp
), "../data/robustness_results.rds")

cat("\nAll robustness results saved.\n")
