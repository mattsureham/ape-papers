# ==============================================================================
# 04_robustness.R — Robustness Checks
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

source("00_packages.R")

panel <- readRDS(file.path("..", "data", "analysis_panel.rds"))
panel_all <- readRDS(file.path("..", "data", "analysis_panel_all_awards.rds"))

# ---- 1. Placebo: Pre-period false treatment (2011 cutoff) ----
cat("=== Placebo: Pre-period false treatment ===\n")
pre_data <- panel[year <= 2014]
pre_data[, fake_post := as.integer(year >= 2011)]
m_placebo_pre <- feols(minority_share ~ forprofit:fake_post | unitid + year,
                       data = pre_data, cluster = ~unitid)
print(summary(m_placebo_pre))

# ---- 2. All award levels (not just sub-bachelor) ----
cat("\n=== Robustness: All award levels ===\n")
m_all_awards <- feols(minority_share_all ~ forprofit:ge_active + forprofit:post_repeal |
                        unitid + year,
                      data = panel_all, cluster = ~unitid)
print(summary(m_all_awards))

# ---- 3. Separate Black and Hispanic effects ----
cat("\n=== Heterogeneity: Black share ===\n")
m_black <- feols(black_share ~ forprofit:ge_active + forprofit:post_repeal |
                   unitid + year,
                 data = panel, cluster = ~unitid)
print(summary(m_black))

cat("\n=== Heterogeneity: Hispanic share ===\n")
m_hisp <- feols(hisp_share ~ forprofit:ge_active + forprofit:post_repeal |
                  unitid + year,
                data = panel, cluster = ~unitid)
print(summary(m_hisp))

# ---- 4. State × year fixed effects ----
cat("\n=== Robustness: State × Year FE ===\n")
panel[, state_year := paste0(state, "_", year)]
m_state_yr <- feols(minority_share ~ forprofit:ge_active + forprofit:post_repeal |
                      unitid + state_year,
                    data = panel, cluster = ~unitid)
print(summary(m_state_yr))

# ---- 5. Drop Great Recession years (KEY: clean pre-trends) ----
cat("\n=== KEY: Drop 2008-2010 (clean pre-trends sample) ===\n")
panel_clean <- panel[!(year %in% 2008:2010)]
m_clean <- feols(minority_share ~ forprofit:ge_active + forprofit:post_repeal |
                   unitid + year,
                 data = panel_clean, cluster = ~unitid)
print(summary(m_clean))

# ---- 6. Intensive margin: Among institutions with >0 minority completions ----
cat("\n=== Intensive margin ===\n")
panel_pos <- panel[minority_comp > 0]
m_intensive <- feols(minority_share ~ forprofit:ge_active + forprofit:post_repeal |
                       unitid + year,
                     data = panel_pos, cluster = ~unitid)
print(summary(m_intensive))

# ---- 7. Drop 2007-2010 entirely (2011-2023 only) ----
cat("\n=== 2011-2023 sample only ===\n")
panel_2011 <- panel[year >= 2011]
m_2011 <- feols(minority_share ~ forprofit:ge_active + forprofit:post_repeal |
                  unitid + year,
                data = panel_2011, cluster = ~unitid)
print(summary(m_2011))

# ---- 8. Save robustness models ----
rob_models <- list(
  placebo_pre = m_placebo_pre,
  all_awards = m_all_awards,
  black = m_black,
  hispanic = m_hisp,
  state_year_fe = m_state_yr,
  clean_pretrends = m_clean,
  intensive = m_intensive,
  sample_2011 = m_2011
)
saveRDS(rob_models, file.path("..", "data", "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
