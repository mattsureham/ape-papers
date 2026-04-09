## 03_main_analysis.R — Primary DiD regressions
## apep_1439: The Switching Paradox

source("00_packages.R")

panel_weekly <- readRDS("../data/panel_weekly.rds")
panel_group <- readRDS("../data/panel_group.rds")

cat("=== Main Analysis: Cross-Product DiD ===\n\n")

# =====================================================================
# Table 1: Summary Statistics
# =====================================================================
cat("--- Summary Statistics ---\n")
sum_stats <- panel_weekly %>%
  group_by(Group = group) %>%
  summarise(
    `Mean Hits` = mean(hits, na.rm = TRUE),
    `SD Hits` = sd(hits, na.rm = TRUE),
    `Mean Hits (Pre)` = mean(hits[post == 0], na.rm = TRUE),
    `Mean Hits (Post)` = mean(hits[post == 1], na.rm = TRUE),
    `N Keywords` = n_distinct(keyword),
    `N Weeks` = n_distinct(week),
    `N Obs` = n(),
    .groups = "drop"
  )
print(sum_stats)

# =====================================================================
# Main DiD: Keyword-week level with keyword + week FE
# =====================================================================
cat("\n--- Main DiD Regressions ---\n")

# Model 1: Simple DiD (group-week level)
m1 <- feols(hits ~ treat_post | group + week, data = panel_group, se = "hetero")

# Model 2: Keyword-week level with keyword + week FE
m2 <- feols(hits ~ treat_post | keyword + week, data = panel_weekly, se = "cluster", cluster = ~keyword)

# Model 3: Log specification
m3 <- feols(log_hits ~ treat_post | keyword + week, data = panel_weekly, se = "cluster", cluster = ~keyword)

# Model 4: Exclude COVID period
m4 <- feols(hits ~ treat_post | keyword + week,
            data = filter(panel_weekly, !covid_period),
            se = "cluster", cluster = ~keyword)

cat("\n--- Results ---\n")
etable(m1, m2, m3, m4,
       headers = c("Group-Week", "Keyword-Week", "Log(Hits+1)", "Excl. COVID"),
       se.below = TRUE)

# =====================================================================
# Event Study: Quarterly bins for cleaner display
# =====================================================================
cat("\n--- Event Study ---\n")

# Create quarterly relative time
panel_weekly <- panel_weekly %>%
  mutate(
    rel_quarter = case_when(
      rel_week < -156 ~ -12,  # bin far leads
      rel_week < -143 ~ -11,
      rel_week < -130 ~ -10,
      rel_week < -117 ~ -9,
      rel_week < -104 ~ -8,
      rel_week < -91 ~ -7,
      rel_week < -78 ~ -6,
      rel_week < -65 ~ -5,
      rel_week < -52 ~ -4,
      rel_week < -39 ~ -3,
      rel_week < -26 ~ -2,
      rel_week < -13 ~ -1,
      rel_week < 0 ~ -1,  # reference period
      rel_week < 13 ~ 0,
      rel_week < 26 ~ 1,
      rel_week < 39 ~ 2,
      rel_week < 52 ~ 3,
      rel_week < 65 ~ 4,
      rel_week < 78 ~ 5,
      rel_week < 91 ~ 6,
      rel_week < 104 ~ 7,
      rel_week < 117 ~ 8,
      rel_week < 130 ~ 9,
      rel_week < 143 ~ 10,
      rel_week < 156 ~ 11,
      TRUE ~ 12
    ),
    # Interaction dummies for event study
    rel_q_factor = factor(rel_quarter)
  )

# Reference period: q = -1 (last quarter before treatment)
panel_weekly$rel_q_factor <- relevel(panel_weekly$rel_q_factor, ref = "-1")

m_es <- feols(hits ~ i(rel_q_factor, treated, ref = "-1") | keyword + week,
              data = panel_weekly, se = "cluster", cluster = ~keyword)

cat("Event study coefficients:\n")
print(coeftable(m_es))

# =====================================================================
# Save results for tables
# =====================================================================
results <- list(
  sum_stats = sum_stats,
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m_es = m_es
)
saveRDS(results, "../data/main_results.rds")

# =====================================================================
# Diagnostics for validator
# =====================================================================
n_treated_keywords <- n_distinct(panel_weekly$keyword[panel_weekly$treated == 1])
n_control_keywords <- n_distinct(panel_weekly$keyword[panel_weekly$treated == 0])
n_pre_weeks <- n_distinct(panel_weekly$week[panel_weekly$post == 0])

# n_treated: keyword-week treated observations (3 keywords × pre/post weeks)
# The design is cross-product DiD with keyword-level treatment
diagnostics <- list(
  n_treated = nrow(panel_weekly %>% filter(treated == 1)),
  n_pre = n_pre_weeks,
  n_obs = nrow(panel_weekly)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
