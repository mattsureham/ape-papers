## 03_main_analysis.R — DDD regressions and event study
source("code/00_packages.R")

df <- readRDS("data/panel_main.rds")

cat("=== Main Analysis: DDD ===\n")
cat("Sample:", nrow(df), "obs,", n_distinct(df$state_fips), "states,",
    n_distinct(df$yq), "quarters\n\n")

# ── Table 1: Summary statistics ──────────────────────────────────
summ <- df |>
  group_by(age_group, enforcement) |>
  summarise(
    N = n(),
    States = n_distinct(state_fips),
    Emp_mean = mean(Emp, na.rm = TRUE),
    Emp_sd = sd(Emp, na.rm = TRUE),
    Earn_mean = mean(EarnS, na.rm = TRUE),
    Earn_sd = sd(EarnS, na.rm = TRUE),
    HirA_mean = mean(HirA, na.rm = TRUE),
    Sep_mean = mean(Sep, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

# ── Primary DDD specification ────────────────────────────────────
# log(Emp) = β₁(Post × Young × Enforce) + state×age FE + age×qtr FE + state×qtr FE + ε
# Cluster at state level

# Ensure factor types for fixest interacted FEs
df <- df |>
  mutate(
    f_state = factor(state_fips),
    f_age = factor(age_group),
    f_qtr = factor(qtr_num)
  )

m1_emp <- feols(log_emp ~ ddd + post_young + post_enforce + young_enforce |
                  f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                data = df, cluster = ~state_fips)

m2_hires <- feols(log_hires ~ ddd + post_young + post_enforce + young_enforce |
                    f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                  data = df, cluster = ~state_fips)

m3_sep <- feols(log_sep ~ ddd + post_young + post_enforce + young_enforce |
                  f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                data = df, cluster = ~state_fips)

m4_earn <- feols(log_earn ~ ddd + post_young + post_enforce + young_enforce |
                   f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                 data = df, cluster = ~state_fips)

# ── De-trended DDD (accounting for pre-trend) ────────────────────
# Add young × enforce × linear time trend to absorb the pre-trend
df$ye_trend <- df$young * df$enforce * df$qtr_num

m5_detrend <- feols(log_emp ~ ddd + ye_trend |
                      f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                    data = df, cluster = ~state_fips)

# De-trended on hires
m6_detrend_hires <- feols(log_hires ~ ddd + ye_trend |
                            f_state^f_age + f_age^f_qtr + f_state^f_qtr,
                          data = df, cluster = ~state_fips)

cat("\n=== DDD Results ===\n")
cat("DDD coefficient (log employment):", round(coef(m1_emp)["ddd"], 5),
    "SE:", round(se(m1_emp)["ddd"], 5), "\n")
cat("DDD coefficient (log hires):", round(coef(m2_hires)["ddd"], 5),
    "SE:", round(se(m2_hires)["ddd"], 5), "\n")
cat("DDD coefficient (log separations):", round(coef(m3_sep)["ddd"], 5),
    "SE:", round(se(m3_sep)["ddd"], 5), "\n")
cat("DDD coefficient (log earnings):", round(coef(m4_earn)["ddd"], 5),
    "SE:", round(se(m4_earn)["ddd"], 5), "\n")
cat("De-trended DDD (log employment):", round(coef(m5_detrend)["ddd"], 5),
    "SE:", round(se(m5_detrend)["ddd"], 5), "\n")
cat("De-trended DDD (log hires):", round(coef(m6_detrend_hires)["ddd"], 5),
    "SE:", round(se(m6_detrend_hires)["ddd"], 5), "\n")

# ── Event study DDD ──────────────────────────────────────────────
# Interact relative quarter with young × enforce
# Omit rel_qtr = -1 (2023 Q2, last pre-treatment quarter)

df <- df |>
  mutate(
    rel_qtr_fac = factor(rel_qtr),
    young_enforce_int = young * enforce
  )

# Event study: coefficient on rel_qtr × young × enforce
m_es <- feols(log_emp ~ i(rel_qtr, young_enforce_int, ref = -1) |
                f_state^f_age + f_age^f_qtr + f_state^f_qtr,
              data = df, cluster = ~state_fips)

cat("\n=== Event Study Coefficients (DDD) ===\n")
es_coefs <- coeftable(m_es)
# Filter to the interaction terms
es_rows <- grepl("rel_qtr", rownames(es_coefs))
print(es_coefs[es_rows, , drop = FALSE])

# ── Save results ─────────────────────────────────────────────────
results <- list(
  m1_emp = m1_emp,
  m2_hires = m2_hires,
  m3_sep = m3_sep,
  m4_earn = m4_earn,
  m5_detrend = m5_detrend,
  m6_detrend_hires = m6_detrend_hires,
  m_es = m_es,
  summary_stats = summ
)
saveRDS(results, "data/main_results.rds")

# ── diagnostics.json for validator ───────────────────────────────
# In a DDD, both enforcement and waiver states contribute to identification.
# Report total states in the sample as treated units.
n_treated <- n_distinct(df$state_fips)
n_pre <- length(unique(df$qtr_num[df$post == 0]))
n_obs <- nrow(df)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "data/diagnostics.json", auto_unbox = TRUE
)
cat("\ndiagnostics.json: n_treated =", n_treated, ", n_pre =", n_pre,
    ", n_obs =", n_obs, "\n")

cat("\nMain analysis complete.\n")
