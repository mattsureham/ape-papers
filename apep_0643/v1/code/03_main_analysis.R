# =============================================================================
# 03_main_analysis.R — Main border-county-pair DiD analysis
# apep_0643: PFL Border County Pairs
# =============================================================================

source("00_packages.R")

stacked_all <- readRDS("../data/stacked_all.rds")
stacked_ind <- readRDS("../data/stacked_ind.rds")
stacked_edu <- readRDS("../data/stacked_edu.rds")

# ---- MAIN SPECIFICATION ----
# Y_{c,t,w} = α_{pair×wave} + γ_{quarter×wave} + β × PFL_{c,t} + ε_{c,t,w}
# Cluster: state level (few clusters → will also do wild cluster bootstrap)

female_all <- stacked_all %>% filter(sex == 2)

# Create interaction variable for DiD
female_all <- female_all %>%
  mutate(
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave)
  )

cat("=== MAIN RESULTS: Female Employment ===\n\n")

# --- Table 1: Main DiD estimates ---
# (1) Log employment
m1 <- feols(ln_emp ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

# (2) Log earnings
m2 <- feols(ln_earn ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

# (3) Log hires
m3 <- feols(ln_hir ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

# (4) Log separations
m4 <- feols(ln_sep ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

# (5) Hire rate
m5 <- feols(hire_rate ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

# (6) Separation rate
m6 <- feols(sep_rate ~ pfl | pair_wave + time_wave,
            data = female_all, cluster = ~state_fips)

cat("Model 1 (ln_emp):\n")
summary(m1)
cat("\nModel 2 (ln_earn):\n")
summary(m2)
cat("\nModel 3 (ln_hir):\n")
summary(m3)
cat("\nModel 4 (ln_sep):\n")
summary(m4)

# --- Event Study ---
cat("\n=== EVENT STUDY ===\n\n")

# Bin endpoints: combine all event times < -8 and > 12
female_all <- female_all %>%
  mutate(
    et_binned = case_when(
      event_time <= -9 ~ -9L,
      event_time >= 13 ~ 13L,
      TRUE ~ as.integer(event_time)
    )
  )

# Event study: ln_emp
es_emp <- feols(ln_emp ~ i(et_binned, treated, ref = -1) | pair_wave + time_wave,
                data = female_all, cluster = ~state_fips)
cat("Event study (ln_emp):\n")
summary(es_emp)

# Event study: ln_earn
es_earn <- feols(ln_earn ~ i(et_binned, treated, ref = -1) | pair_wave + time_wave,
                 data = female_all, cluster = ~state_fips)

# Event study: ln_hir
es_hir <- feols(ln_hir ~ i(et_binned, treated, ref = -1) | pair_wave + time_wave,
                data = female_all, cluster = ~state_fips)

# Event study: ln_sep
es_sep <- feols(ln_sep ~ i(et_binned, treated, ref = -1) | pair_wave + time_wave,
                data = female_all, cluster = ~state_fips)

# ---- MALE PLACEBO ----
cat("\n=== MALE PLACEBO ===\n\n")

male_all <- stacked_all %>%
  filter(sex == 1) %>%
  mutate(
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave)
  )

m_male_emp <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                    data = male_all, cluster = ~state_fips)

m_male_earn <- feols(ln_earn ~ pfl | pair_wave + time_wave,
                     data = male_all, cluster = ~state_fips)

cat("Male placebo (ln_emp):\n")
summary(m_male_emp)
cat("\nMale placebo (ln_earn):\n")
summary(m_male_earn)

# ---- WAVE-SPECIFIC ESTIMATES ----
cat("\n=== WAVE-SPECIFIC ESTIMATES ===\n\n")

wave_results <- list()
for (wn in c("NJ", "NY", "WA")) {
  wave_data <- female_all %>% filter(wave == wn)
  if (nrow(wave_data) > 0) {
    m_wave <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                    data = wave_data, cluster = ~state_fips)
    wave_results[[wn]] <- m_wave
    cat(sprintf("\nWave %s (ln_emp): coef = %.4f, se = %.4f, N = %d\n",
                wn, coef(m_wave)["pfl"], se(m_wave)["pfl"], nobs(m_wave)))
  }
}

# ---- INDUSTRY HETEROGENEITY ----
cat("\n=== INDUSTRY HETEROGENEITY (Female) ===\n\n")

stacked_ind <- stacked_ind %>%
  mutate(
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave)
  )

ind_results <- list()
for (ind_code in c("62", "44-45", "72")) {
  ind_data <- stacked_ind %>% filter(industry == ind_code)
  if (nrow(ind_data) > 50) {
    m_ind <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                   data = ind_data, cluster = ~state_fips)
    ind_results[[ind_code]] <- m_ind
    ind_name <- c("62" = "Healthcare", "44-45" = "Retail", "72" = "Accommodation")[ind_code]
    cat(sprintf("Industry %s (%s): coef = %.4f, se = %.4f, N = %d\n",
                ind_code, ind_name, coef(m_ind)["pfl"], se(m_ind)["pfl"], nobs(m_ind)))
  }
}

# ---- EDUCATION HETEROGENEITY ----
cat("\n=== EDUCATION HETEROGENEITY (Female) ===\n\n")

stacked_edu <- stacked_edu %>%
  mutate(
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave)
  )

edu_labels <- c(
  "E1" = "Less than HS",
  "E2" = "HS or equivalent",
  "E3" = "Some college",
  "E4" = "Bachelor's+",
  "E5" = "All education"
)

edu_results <- list()
for (edu_code in c("E1", "E2", "E3", "E4")) {
  edu_data <- stacked_edu %>% filter(education == edu_code)
  if (nrow(edu_data) > 50) {
    m_edu <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                   data = edu_data, cluster = ~state_fips)
    edu_results[[edu_code]] <- m_edu
    cat(sprintf("Education %s (%s): coef = %.4f, se = %.4f, N = %d\n",
                edu_code, edu_labels[edu_code],
                coef(m_edu)["pfl"], se(m_edu)["pfl"], nobs(m_edu)))
  }
}

# ---- SAVE RESULTS ----
results <- list(
  main = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
  event_study = list(es_emp = es_emp, es_earn = es_earn, es_hir = es_hir, es_sep = es_sep),
  male_placebo = list(emp = m_male_emp, earn = m_male_earn),
  wave_specific = wave_results,
  industry = ind_results,
  education = edu_results
)

saveRDS(results, "../data/main_results.rds")

# ---- DIAGNOSTICS JSON ----
n_treated <- n_distinct(female_all$fips[female_all$treated == 1])
n_control <- n_distinct(female_all$fips[female_all$treated == 0])
n_pre <- length(unique(female_all$event_time[female_all$event_time < 0]))
n_obs <- nrow(female_all)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre,
  n_obs = n_obs,
  n_pairs = n_distinct(female_all$pair_id),
  n_waves = n_distinct(female_all$wave),
  n_counties = n_distinct(female_all$fips),
  waves = unique(female_all$wave),
  main_coef_ln_emp = as.numeric(coef(m1)["pfl"]),
  main_se_ln_emp = as.numeric(se(m1)["pfl"]),
  main_coef_ln_earn = as.numeric(coef(m2)["pfl"]),
  main_se_ln_earn = as.numeric(se(m2)["pfl"])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("N treated counties: %d\n", n_treated))
cat(sprintf("N control counties: %d\n", n_control))
cat(sprintf("N pre-periods: %d\n", n_pre))
cat(sprintf("N observations: %d\n", n_obs))
cat(sprintf("Main result (ln_emp): β = %.4f (%.4f)\n",
            as.numeric(coef(m1)["pfl"]), as.numeric(se(m1)["pfl"])))

cat("\nMain analysis complete.\n")
