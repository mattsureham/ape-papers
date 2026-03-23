## 03_main_analysis.R — Main regressions
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

source("00_packages.R")

df <- readRDS("../data/analysis.rds")

cat("=== Main Analysis: Difference-in-Differences ===\n")
cat(sprintf("Observations: %s\n", format(nrow(df), big.mark = ",")))

## ========================================================
## Filter to estimation sample
## ========================================================
reg_df <- df %>%
  filter(!is.na(log_earn) & is.finite(log_earn))

cat(sprintf("Regression sample (non-missing log earnings): %s rows\n",
            format(nrow(reg_df), big.mark = ",")))

## ========================================================
## Main Specifications
## With sector-level QWI (industry = "31-33"), variation is county × race × quarter.
## Treatment: county-level exposure from CBP (share of 2016 employment in NAICS 331+332)
## ========================================================

cat("\n--- Model 1: DiD (Exposure × Post) on all mfg workers ---\n")
m1 <- feols(
  log_earn ~ post_exposure | fips + yq,
  data = reg_df,
  cluster = ~state_fips
)
print(summary(m1))

cat("\n--- Model 2: Triple-diff (Exposure × Post × Black) ---\n")
m2 <- feols(
  log_earn ~ post_exposure + post_black + post_exposure_black | fips + yq,
  data = reg_df,
  cluster = ~state_fips
)
print(summary(m2))

cat("\n--- Model 3: Triple-diff with county×race FEs ---\n")
m3 <- feols(
  log_earn ~ post_exposure + post_black + post_exposure_black | county_race + yq,
  data = reg_df,
  cluster = ~state_fips
)
print(summary(m3))

cat("\n--- Model 4: Triple-diff with county×race + race×quarter FEs ---\n")
## Create race-quarter FE to absorb national race-specific time trends
reg_df <- reg_df %>%
  mutate(race_yq = paste0(race, "_", yq))

m4 <- feols(
  log_earn ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = reg_df,
  cluster = ~state_fips
)
print(summary(m4))

## ========================================================
## Event Study (quarter-by-quarter triple-diff)
## ========================================================
cat("\n--- Event Study ---\n")

reg_df <- reg_df %>%
  mutate(
    rel_q = (year - 2018) * 4 + quarter - 2  # 2018Q2 = 0
  )

## Event study: exposure × black × quarter dummies
reg_df <- reg_df %>%
  mutate(exp_black = exposure * black)

m_es <- feols(
  log_earn ~ i(rel_q, exp_black, ref = -1) +
    i(rel_q, exposure, ref = -1) |
    county_race + race_yq,
  data = reg_df,
  cluster = ~state_fips
)
cat("Event study model:\n")
print(summary(m_es))

## Extract triple-interaction coefficients
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)

triple_terms <- es_coefs %>%
  filter(grepl("exp_black", term)) %>%
  mutate(
    rel_q = as.numeric(gsub(".*rel_q::(-?\\d+):.*", "\\1", term))
  ) %>%
  arrange(rel_q)

cat("\nTriple-diff event study coefficients:\n")
print(triple_terms %>% select(rel_q, Estimate, `Std. Error`, `Pr(>|t|)`))

saveRDS(triple_terms, "../data/event_study_coefs.rds")

## ========================================================
## Employment outcome (extensive margin)
## ========================================================
cat("\n--- Employment as outcome ---\n")

emp_df <- df %>% filter(!is.na(emp) & emp > 0)
emp_df <- emp_df %>% mutate(race_yq = paste0(race, "_", yq))

m_emp <- feols(
  log(emp) ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = emp_df,
  cluster = ~state_fips
)
cat("Employment outcome:\n")
print(summary(m_emp))

## ========================================================
## Hires as outcome (labor market tightness)
## ========================================================
cat("\n--- Hires as outcome ---\n")

hire_df <- df %>% filter(!is.na(hires) & hires > 0)
hire_df <- hire_df %>% mutate(race_yq = paste0(race, "_", yq))

m_hires <- feols(
  log(hires) ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = hire_df,
  cluster = ~state_fips
)
cat("Hires outcome:\n")
print(summary(m_hires))

## ========================================================
## Save models and diagnostics
## ========================================================
models <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m_es = m_es, m_emp = m_emp, m_hires = m_hires
)
saveRDS(models, "../data/models.rds")

## Diagnostics for validate_v1.py
n_high <- n_distinct(reg_df$fips[reg_df$high_exposure == 1])
n_pre <- length(unique(reg_df$yq[reg_df$post == 0]))
n_obs <- nrow(reg_df)

diagnostics <- list(
  n_treated = n_high,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%s\n",
            n_high, n_pre, format(n_obs, big.mark = ",")))
cat("Models saved.\nDone.\n")
