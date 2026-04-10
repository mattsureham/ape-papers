source("code/00_packages.R")

enoe <- readRDS("data/enoe_analysis.rds")

cat("=== TABLE 2: MAIN DiD RESULTS ===\n\n")

m1_hours <- feols(hrsocup ~ formal + treat_post | state + period,
                  data = enoe, cluster = ~state)

m2_hours_controls <- feols(hrsocup ~ formal + treat_post + i(sex) + eda + I(eda^2) | state + period,
                           data = enoe, cluster = ~state)

m3_formal <- feols(formal ~ post | state,
                   data = enoe, cluster = ~state)

m4_formal_controls <- feols(formal ~ post + i(sex) + eda + I(eda^2) | state,
                            data = enoe, cluster = ~state)

if ("log_wage" %in% names(enoe) & "high_dose" %in% names(enoe)) {
  m5_wage <- feols(log_wage ~ post:high_dose | state + period,
                   data = enoe[formal == 1], cluster = ~state)
} else {
  m5_wage <- NULL
}

cat("\n--- Hours worked (DiD) ---\n")
summary(m1_hours)
summary(m2_hours_controls)

cat("\n--- Formality rate ---\n")
summary(m3_formal)
summary(m4_formal_controls)

if (!is.null(m5_wage)) {
  cat("\n--- Wages (formal workers only) ---\n")
  summary(m5_wage)
}

cat("\n=== TABLE 3: EVENT STUDY ===\n\n")

enoe[, event_time := period - 20231]
enoe[, rel_quarter := (year - 2023) * 4 + (quarter - 1)]
enoe[formal == 0, rel_quarter := NA_integer_]

enoe[, yq_factor := factor(period)]
ref_period <- "20224"

es_hours <- feols(hrsocup ~ i(yq_factor, formal, ref = ref_period) | state + period,
                  data = enoe, cluster = ~state)

cat("Event study coefficients:\n")
summary(es_hours)

cat("\n=== TABLE 4: TRIPLE DIFFERENCE ===\n\n")

if ("high_inf_sector" %in% names(enoe)) {
  m_ddd <- feols(hrsocup ~ formal * post * high_inf_sector | state + period,
                 data = enoe, cluster = ~state)
  cat("Triple-diff (formal x post x high-informality sector):\n")
  summary(m_ddd)

  m_formal_ddd <- feols(formal ~ post * high_inf_sector | state,
                        data = enoe, cluster = ~state)
  summary(m_formal_ddd)
}

cat("\n=== SENIORITY DOSE ===\n\n")

if ("high_dose" %in% names(enoe)) {
  m_dose <- feols(hrsocup ~ treat_post * high_dose | state + period,
                  data = enoe[formal == 1], cluster = ~state)
  cat("Dose response (high dose = short tenure):\n")
  summary(m_dose)
}

n_treated <- uniqueN(enoe[formal == 1, person_id])
n_pre <- length(unique(enoe[post == 0, period]))
n_obs <- nrow(enoe)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_states = length(unique(enoe$state)),
  formality_rate_pre = mean(enoe[post == 0, formal]),
  formality_rate_post = mean(enoe[post == 1, formal]),
  mean_hours_formal_pre = mean(enoe[formal == 1 & post == 0, hrsocup], na.rm = TRUE),
  mean_hours_informal_pre = mean(enoe[formal == 0 & post == 0, hrsocup], na.rm = TRUE)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

results <- list(
  m1_hours = m1_hours,
  m2_hours_controls = m2_hours_controls,
  m3_formal = m3_formal,
  m4_formal_controls = m4_formal_controls,
  m5_wage = m5_wage,
  es_hours = es_hours,
  m_ddd = if (exists("m_ddd")) m_ddd else NULL,
  m_formal_ddd = if (exists("m_formal_ddd")) m_formal_ddd else NULL,
  m_dose = if (exists("m_dose")) m_dose else NULL,
  diagnostics = diagnostics
)

saveRDS(results, "data/results.rds")
cat("Results saved to data/results.rds\n")
