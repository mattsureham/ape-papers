# =============================================================================
# 03_main_analysis.R — Main DDD estimation
# =============================================================================

source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")

cat("=== MAIN ANALYSIS ===\n")
cat("Panel: ", nrow(dt), " obs, ", uniqueN(dt$state_fips), " states, ",
    uniqueN(dt$cal_q), " quarters\n\n")

# ===================================================================
# 1. POOLED DDD: All industries (licensed vs unlicensed as dimension)
# ===================================================================

# Restrict to licensed industries for the main spec
licensed_dt <- dt[licensed == 1]
cat("Licensed industries panel: ", nrow(licensed_dt), " obs\n")

# Main DDD specification:
# log_earn ~ treat_post_hisp + treat_post + post_hisp | state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q
# β on treat_post_hisp = DDD estimate

# Spec 1: Basic DDD with full FEs
m1 <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
              state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
            data = licensed_dt,
            cluster = ~state_fips)

cat("\n--- Spec 1: Pooled DDD (licensed industries) ---\n")
summary(m1)

# Spec 2: Industry-specific DDD (add industry FEs and interactions)
m2 <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
              state_fips^ethnicity^industry + cal_q^ethnicity^industry + state_fips^cal_q,
            data = licensed_dt,
            cluster = ~state_fips)

cat("\n--- Spec 2: Industry-interacted DDD ---\n")
summary(m2)

# Spec 3: Full sample DDD × Licensed (Quadruple-difference)
# Tests whether effects are concentrated in licensed industries
m3 <- feols(log_earn ~ treat_post_hisp:licensed + treat_post:licensed +
              post_hisp:licensed + treat_post_hisp + treat_post + post_hisp |
              state_fips^ethnicity^industry + cal_q^ethnicity^industry + state_fips^cal_q^industry,
            data = dt,
            cluster = ~state_fips)

cat("\n--- Spec 3: DDDD (licensed vs unlicensed) ---\n")
summary(m3)

# ===================================================================
# 2. BY-INDUSTRY DDD
# ===================================================================

cat("\n=== BY-INDUSTRY DDD ===\n")
ind_results <- list()

for (ind in c("23", "62", "81")) {
  ind_dt <- dt[industry == ind]
  m <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
               state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
             data = ind_dt,
             cluster = ~state_fips)
  ind_name <- unique(ind_dt$industry_name)
  cat(sprintf("\n--- %s (NAICS %s) ---\n", ind_name, ind))
  print(summary(m))
  ind_results[[ind]] <- m
}

# ===================================================================
# 3. PLACEBO INDUSTRIES (should show no effect)
# ===================================================================

cat("\n=== PLACEBO: UNLICENSED INDUSTRIES ===\n")

for (ind in c("44-45", "72", "31-33")) {
  ind_dt <- dt[industry == ind]
  m <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
               state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
             data = ind_dt,
             cluster = ~state_fips)
  ind_name <- unique(ind_dt$industry_name)
  cat(sprintf("\n--- PLACEBO: %s (NAICS %s) ---\n", ind_name, ind))
  cat(sprintf("  DDD coef: %.4f (SE: %.4f, p: %.3f)\n",
      coef(m)["treat_post_hisp"],
      se(m)["treat_post_hisp"],
      pvalue(m)["treat_post_hisp"]))
  ind_results[[ind]] <- m
}

# ===================================================================
# 4. EVENT STUDY (licensed industries, DDD)
# ===================================================================

cat("\n=== EVENT STUDY ===\n")

# Create event time for treated states only
# For never-treated states, event_time = NA (handled by fixest)
licensed_treated <- licensed_dt[treated_state == 1]

# Cap event time at +/- 12 quarters (3 years)
licensed_treated[, et_capped := pmax(-12, pmin(12, event_time))]
licensed_treated[, et_capped := as.factor(et_capped)]

# Event study: interact event time with hispanic
# Reference period: event_time = -1
es_model <- feols(log_earn ~ i(et_capped, hispanic, ref = "-1") |
                    state_fips^ethnicity + cal_q^ethnicity,
                  data = licensed_treated,
                  cluster = ~state_fips)

cat("Event study coefficients:\n")
summary(es_model)

# Save event study coefficients for plotting
es_coefs <- data.table(
  event_time = as.integer(gsub("et_capped::(-?\\d+):hispanic", "\\1",
                                names(coef(es_model)))),
  estimate = coef(es_model),
  se = se(es_model)
)
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# ===================================================================
# 5. EMPLOYMENT AND HIRING (additional outcomes)
# ===================================================================

cat("\n=== ADDITIONAL OUTCOMES (LICENSED INDUSTRIES) ===\n")

# Log employment
m_emp <- feols(log_emp ~ treat_post_hisp + treat_post + post_hisp |
                 state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
               data = licensed_dt[!is.na(log_emp)],
               cluster = ~state_fips)
cat("\n--- Employment DDD ---\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_emp)["treat_post_hisp"],
    se(m_emp)["treat_post_hisp"],
    pvalue(m_emp)["treat_post_hisp"]))

# Hiring rate
m_hire <- feols(hire_rate ~ treat_post_hisp + treat_post + post_hisp |
                  state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                data = licensed_dt[!is.na(hire_rate)],
                cluster = ~state_fips)
cat("\n--- Hiring Rate DDD ---\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_hire)["treat_post_hisp"],
    se(m_hire)["treat_post_hisp"],
    pvalue(m_hire)["treat_post_hisp"]))

# ===================================================================
# 6. SAVE ALL MODEL OBJECTS
# ===================================================================

save(m1, m2, m3, ind_results, es_model, m_emp, m_hire,
     file = "../data/model_objects.RData")

# Write diagnostics.json for validator
n_treated_states <- uniqueN(dt[treated_state == 1, state_fips])
n_pre <- length(unique(dt[year < 2019, cal_q]))
n_obs <- nrow(dt)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nAll models saved. Diagnostics written.\n")
cat(sprintf("  n_treated: %d states\n", n_treated_states))
cat(sprintf("  n_pre: %d quarters\n", n_pre))
cat(sprintf("  n_obs: %d\n", n_obs))
