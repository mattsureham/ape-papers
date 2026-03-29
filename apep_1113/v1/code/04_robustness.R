# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

source("00_packages.R")
df <- readRDS("../data/analysis_panel.rds")

# ==============================================================================
# PLACEBO 1: Prior-ban states (should show zero SFFA effect)
# ==============================================================================

cat("=== PLACEBO 1: Prior-Ban States ===\n\n")

# Institutions in states that banned AA before SFFA
df_prior_ban <- df %>% filter(prior_ban == 1)
df_no_prior_ban <- df %>% filter(prior_ban == 0)

# Effect in prior-ban states (should be null)
m_prior_ban <- feols(urm_share ~ intensity_x_post | unitid + year,
                     data = df_prior_ban, cluster = ~state)
cat(sprintf("Prior-ban states: β = %.3f (SE = %.3f, p = %.4f)\n",
    coef(m_prior_ban)[1], se(m_prior_ban)[1], pvalue(m_prior_ban)[1]))

# Effect in non-prior-ban states (should capture SFFA effect)
m_no_ban <- feols(urm_share ~ intensity_x_post | unitid + year,
                  data = df_no_prior_ban, cluster = ~state)
cat(sprintf("Non-ban states: β = %.3f (SE = %.3f, p = %.4f)\n",
    coef(m_no_ban)[1], se(m_no_ban)[1], pvalue(m_no_ban)[1]))

# DDD: intensity × post × non-ban-state
df <- df %>%
  mutate(non_ban = 1 - prior_ban,
         intensity_x_post_x_nonban = intensity * post * non_ban)

m_ban_ddd <- feols(urm_share ~ intensity_x_post_x_nonban + intensity_x_post |
                     unitid + year,
                   data = df, cluster = ~state)
cat("DDD (intensity × post × non-ban-state):\n")
cat(sprintf("  β = %.3f (SE = %.3f)\n",
    coef(m_ban_ddd)["intensity_x_post_x_nonban"],
    se(m_ban_ddd)["intensity_x_post_x_nonban"]))

# ==============================================================================
# PLACEBO 2: HBCUs (should show zero SFFA effect)
# ==============================================================================

cat("\n=== PLACEBO 2: HBCUs ===\n\n")

df_hbcu <- df %>% filter(is_hbcu == 1)
df_non_hbcu <- df %>% filter(is_hbcu == 0)

if (nrow(df_hbcu) > 0 && n_distinct(df_hbcu$unitid) >= 5) {
  # Use intensity × post (post alone is collinear with year FE)
  m_hbcu <- feols(urm_share ~ intensity_x_post | unitid + year,
                  data = df_hbcu, cluster = ~state)
  cat(sprintf("HBCUs (N=%d): β = %.3f (SE = %.3f)\n",
      n_distinct(df_hbcu$unitid), coef(m_hbcu)[1], se(m_hbcu)[1]))
} else {
  cat("Too few HBCUs with admission data for separate analysis\n")
  m_hbcu <- NULL
}

# ==============================================================================
# ROBUSTNESS 1: Public vs. Private
# ==============================================================================

cat("\n=== ROBUSTNESS 1: Public vs. Private ===\n\n")

m_public <- feols(urm_share ~ intensity_x_post | unitid + year,
                  data = df %>% filter(is_public == 1), cluster = ~state)
m_private <- feols(urm_share ~ intensity_x_post | unitid + year,
                   data = df %>% filter(is_public == 0), cluster = ~state)

cat(sprintf("Public: β = %.3f (SE = %.3f)\n", coef(m_public)[1], se(m_public)[1]))
cat(sprintf("Private: β = %.3f (SE = %.3f)\n", coef(m_private)[1], se(m_private)[1]))

# ==============================================================================
# ROBUSTNESS 2: Balanced panel only
# ==============================================================================

cat("\n=== ROBUSTNESS 2: Balanced Panel ===\n\n")

balanced_ids <- df %>%
  group_by(unitid) %>%
  filter(n() == n_distinct(df$year)) %>%
  pull(unitid) %>%
  unique()

m_balanced <- feols(urm_share ~ intensity_x_post | unitid + year,
                    data = df %>% filter(unitid %in% balanced_ids),
                    cluster = ~state)
cat(sprintf("Balanced panel (N=%d): β = %.3f (SE = %.3f)\n",
    length(balanced_ids), coef(m_balanced)[1], se(m_balanced)[1]))

# ==============================================================================
# ROBUSTNESS 3: Alternative intensity (selectivity quintile dummies)
# ==============================================================================

cat("\n=== ROBUSTNESS 3: Selectivity Quintile Dummies ===\n\n")

df <- df %>%
  mutate(select_q = ntile(intensity, 5))

m_quintile <- feols(urm_share ~ i(select_q, post, ref = 1) | unitid + year,
                    data = df, cluster = ~state)
cat("Quintile interactions (ref = Q1 least selective):\n")
print(coeftable(m_quintile))

# ==============================================================================
# ROBUSTNESS 4: Controlling for state-year FE
# ==============================================================================

cat("\n=== ROBUSTNESS 4: State-Year Fixed Effects ===\n\n")

m_state_year <- feols(urm_share ~ intensity_x_post | unitid + state^year,
                      data = df, cluster = ~state)
cat(sprintf("With state×year FE: β = %.3f (SE = %.3f)\n",
    coef(m_state_year)[1], se(m_state_year)[1]))

# ==============================================================================
# Save robustness results
# ==============================================================================

robustness <- list(
  prior_ban = m_prior_ban,
  no_ban = m_no_ban,
  ban_ddd = m_ban_ddd,
  hbcu = m_hbcu,
  public = m_public,
  private = m_private,
  balanced = m_balanced,
  quintile = m_quintile,
  state_year = m_state_year
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness analysis complete.\n")
