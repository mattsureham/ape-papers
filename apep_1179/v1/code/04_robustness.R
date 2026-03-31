## 04_robustness.R — Robustness checks and placebos
## apep_1179: Anti-corruption enforcement and fiscal composition in China

source("00_packages.R")
panel <- readRDS("../data/analysis_panel.rds")

panel <- panel %>%
  mutate(
    campaign = as.integer(year >= 2013),
    post_x_intensity = campaign * log_intensity
  )

# =============================================================================
# 1. EVENT STUDY (TWFE with leads and lags for intensity specification)
# =============================================================================

cat("=== Event Study: Intensity × Year Interactions ===\n\n")

# Interact log_intensity with year dummies (relative to 2012 as base)
panel <- panel %>%
  mutate(rel_year = year - 2013)

# Use sunab() equivalent: interact intensity with year
# This is the continuous-treatment event study
es_edu <- feols(edu_share ~ i(year, log_intensity, ref = 2012) | city_id + year,
                data = panel, cluster = ~city_id)

es_sci <- feols(sci_share ~ i(year, log_intensity, ref = 2012) | city_id + year,
                data = panel, cluster = ~city_id)

cat("Education share event study:\n")
etable(es_edu, fitstat = ~ n + r2)

cat("\nScience share event study:\n")
etable(es_sci, fitstat = ~ n + r2)

# Save event study coefficients for table
es_edu_coefs <- data.frame(
  year = as.integer(gsub("year::", "", names(coef(es_edu)))),
  estimate = coef(es_edu),
  se = se(es_edu)
) %>%
  mutate(year = as.integer(gsub(".*::", "", row.names(.)))) %>%
  filter(!is.na(year))

# =============================================================================
# 2. PLACEBO: Pre-campaign intensity and post-campaign outcomes
# =============================================================================

cat("\n=== Placebo: Pre-campaign (2004-2012) investigation intensity ===\n\n")

# Count investigations BEFORE the campaign (2004-2012) per prefecture
corr_raw <- readRDS("../data/corruption_raw.rds")
pre_inv <- corr_raw %>%
  as_tibble() %>%
  filter(!is.na(Year), !is.na(prefectureid), Year < 2013) %>%
  mutate(
    pref_code = as.integer(substr(sprintf("%06d", as.integer(prefectureid)), 1, 4)),
    pref_name = gsub('"', '', prefecture)
  ) %>%
  group_by(pref_code) %>%
  summarise(pre_inv = n(), .groups = "drop") %>%
  mutate(
    city_match = NA_character_  # Will need to match via panel
  )

# Merge pre-campaign intensity via the existing panel concordance
panel_match <- panel %>%
  distinct(city_id, city_clean, pref_code) %>%
  filter(!is.na(pref_code))

pre_inv_matched <- pre_inv %>%
  inner_join(panel_match %>% select(pref_code, city_id), by = "pref_code")

panel_placebo <- panel %>%
  left_join(pre_inv_matched %>% select(city_id, pre_inv), by = "city_id") %>%
  mutate(
    pre_inv = ifelse(is.na(pre_inv), 0, pre_inv),
    log_pre_inv = log1p(pre_inv),
    post_x_pre_inv = campaign * log_pre_inv
  )

# If pre-campaign corruption ALSO predicts post-2013 fiscal changes,
# it would challenge our interpretation (selection, not enforcement effect)
m_placebo_edu <- feols(edu_share ~ post_x_pre_inv | city_id + year,
                       data = panel_placebo, cluster = ~city_id)
m_placebo_sci <- feols(sci_share ~ post_x_pre_inv | city_id + year,
                       data = panel_placebo, cluster = ~city_id)

cat("Placebo (pre-campaign intensity):\n")
etable(m_placebo_edu, m_placebo_sci,
       se.below = TRUE,
       headers = c("Edu Share", "Sci Share"),
       fitstat = ~ n + r2)

# =============================================================================
# 3. ALTERNATIVE TREATMENT MEASURE: High-rank investigations only
# =============================================================================

cat("\n=== Alternative: High-rank investigations only ===\n\n")

# Only count officials rank >= 7 (provincial-ministerial and above)
panel <- panel %>%
  mutate(
    log_high_rank = log1p(ifelse(is.na(high_rank_inv), 0, high_rank_inv)),
    post_x_highrank = campaign * log_high_rank
  )

m_hr_edu <- feols(edu_share ~ post_x_highrank | city_id + year,
                  data = panel, cluster = ~city_id)
m_hr_sci <- feols(sci_share ~ post_x_highrank | city_id + year,
                  data = panel, cluster = ~city_id)
m_hr_fai <- feols(fai_share ~ post_x_highrank | city_id + year,
                  data = panel, cluster = ~city_id)

cat("High-rank investigations:\n")
etable(m_hr_edu, m_hr_sci, m_hr_fai,
       se.below = TRUE,
       headers = c("Edu Share", "Sci Share", "FAI/GDP"),
       fitstat = ~ n + r2)

# =============================================================================
# 4. LEAVE-ONE-PROVINCE-OUT
# =============================================================================

cat("\n=== Leave-one-province-out sensitivity ===\n\n")

# Identify province from city_id (first digit of pref_code)
panel <- panel %>%
  mutate(province = as.integer(substr(sprintf("%04d", pref_code), 1, 2)))

provinces <- unique(panel$province[!is.na(panel$province)])

loo_results <- data.frame()
for (prov in provinces) {
  df_loo <- panel %>% filter(province != prov | is.na(province))
  m_loo <- feols(sci_share ~ post_x_intensity | city_id + year,
                 data = df_loo, cluster = ~city_id)
  loo_results <- bind_rows(loo_results, data.frame(
    province_excluded = prov,
    coef = coef(m_loo)["post_x_intensity"],
    se = se(m_loo)["post_x_intensity"]
  ))
}

cat(sprintf("Science share coefficient range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("All positive: %s\n", all(loo_results$coef > 0)))
cat(sprintf("All significant (p < 0.05): %s\n",
            all(abs(loo_results$coef / loo_results$se) > 1.96)))

# =============================================================================
# 5. BACON DECOMPOSITION (diagnostic for TWFE)
# =============================================================================

cat("\n=== Goodman-Bacon decomposition ===\n\n")

# Install bacondecomp if needed
if (!requireNamespace("bacondecomp", quietly = TRUE)) {
  install.packages("bacondecomp", repos = "https://cloud.r-project.org")
}
library(bacondecomp)

# Need binary treatment and balanced panel for bacon
bacon_data <- panel %>%
  filter(!is.na(edu_share)) %>%
  mutate(treat = as.integer(first_treat > 0 & year >= first_treat)) %>%
  group_by(city_id) %>%
  filter(n() == 10) %>%  # Balanced panel
  ungroup()

tryCatch({
  bacon_out <- bacon(edu_share ~ treat,
                     data = as.data.frame(bacon_data),
                     id_var = "city_id",
                     time_var = "year")
  cat("Bacon decomposition:\n")
  print(bacon_out %>% group_by(type) %>%
          summarise(
            n_2x2 = n(),
            avg_weight = mean(weight),
            avg_estimate = weighted.mean(estimate, weight),
            .groups = "drop"
          ))
}, error = function(e) {
  cat("Bacon decomposition error:", conditionMessage(e), "\n")
  cat("(This is expected with few treatment timing groups)\n")
})

# =============================================================================
# 6. SAVE ROBUSTNESS RESULTS
# =============================================================================

robust_results <- list(
  event_study_edu = es_edu,
  event_study_sci = es_sci,
  placebo_edu = m_placebo_edu,
  placebo_sci = m_placebo_sci,
  highrank_edu = m_hr_edu,
  highrank_sci = m_hr_sci,
  highrank_fai = m_hr_fai,
  loo = loo_results
)

saveRDS(robust_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
