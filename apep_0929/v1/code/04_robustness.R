# 04_robustness.R — Robustness checks for Furusato Nozei gift cap analysis

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# Reconstruct derived variables
df <- df %>%
  mutate(
    rel_time = fy - 2019,
    gift_tercile = case_when(
      fy2018_gift_rate <= 0.20 ~ "Low (<20%)",
      fy2018_gift_rate <= 0.30 ~ "Medium (20-30%)",
      TRUE ~ "High (>30%)"
    ),
    gift_tercile = factor(gift_tercile, levels = c("Medium (20-30%)", "Low (<20%)", "High (>30%)"))
  )

# ============================================================
# ROBUSTNESS 1: Municipality-specific linear time trends
# ============================================================

cat("=== Robustness 1: Municipality-specific trends ===\n")

# Create numeric time variable
df <- df %>%
  mutate(time_num = as.numeric(fy - 2015))

# Binary DiD with municipality-specific linear trends
r1 <- feols(log_donations ~ treat_binary:post | muni_id[time_num] + fy,
            data = df, cluster = ~prefecture)

cat("Binary DiD with municipality trends:\n")
summary(r1)

# ============================================================
# ROBUSTNESS 2: Shorter pre-period (FY2017-2018 only)
# ============================================================

cat("\n=== Robustness 2: Shorter pre-period ===\n")

df_short <- df %>% filter(fy >= 2017)

r2 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df_short, cluster = ~prefecture)

cat("Binary DiD, FY2017-2018 pre-period:\n")
summary(r2)

# ============================================================
# ROBUSTNESS 3: Excluding FY2020-2021 (COVID years)
# ============================================================

cat("\n=== Robustness 3: Excluding COVID years ===\n")

df_nocovid <- df %>% filter(!fy %in% c(2020, 2021))

r3 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df_nocovid, cluster = ~prefecture)

cat("Binary DiD, excluding FY2020-2021:\n")
summary(r3)

# ============================================================
# ROBUSTNESS 4: Excluding 4 banned municipalities
# ============================================================

cat("\n=== Robustness 4: Excluding banned municipalities ===\n")

df_nobanned <- df %>% filter(excluded == 0)

r4 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df_nobanned, cluster = ~prefecture)

cat("Binary DiD, excluding 4 banned municipalities:\n")
summary(r4)

# ============================================================
# ROBUSTNESS 5: Placebo treatment at FY2017
# ============================================================

cat("\n=== Robustness 5: Placebo at FY2017 ===\n")

df_placebo <- df %>%
  filter(fy <= 2018) %>%
  mutate(placebo_post = as.integer(fy >= 2017))

r5 <- feols(log_donations ~ treat_binary:placebo_post | muni_id + fy,
            data = df_placebo, cluster = ~prefecture)

cat("Placebo at FY2017:\n")
summary(r5)

# ============================================================
# ROBUSTNESS 6: Leave-one-out by prefecture
# ============================================================

cat("\n=== Robustness 6: Leave-one-out ===\n")

prefectures <- unique(df$prefecture)
loo_results <- data.frame(
  excluded_pref = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (pref in prefectures) {
  df_loo <- df %>% filter(prefecture != pref)
  m_loo <- feols(log_donations ~ treat_binary:post | muni_id + fy,
                 data = df_loo, cluster = ~prefecture)
  loo_results <- rbind(loo_results, data.frame(
    excluded_pref = pref,
    coef = coef(m_loo)["treat_binary:post"],
    se = se(m_loo)["treat_binary:post"],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out range:\n")
cat("  Min coefficient:", round(min(loo_results$coef), 3), "\n")
cat("  Max coefficient:", round(max(loo_results$coef), 3), "\n")
cat("  Main estimate:", round(coef(feols(log_donations ~ treat_binary:post | muni_id + fy,
                                         data = df, cluster = ~prefecture))["treat_binary:post"], 3), "\n")

# ============================================================
# ROBUSTNESS 7: Quintile-based treatment
# ============================================================

cat("\n=== Robustness 7: Gift rate quintiles ===\n")

df <- df %>%
  mutate(
    gift_quintile = ntile(fy2018_gift_rate, 5),
    gift_quintile_f = factor(gift_quintile)
  )

r7 <- feols(
  log_donations ~ i(gift_quintile_f, post, ref = "3") | muni_id + fy,
  data = df, cluster = ~prefecture
)

cat("Gift rate quintile effects (base: Q3):\n")
summary(r7)

# ============================================================
# Save all robustness results
# ============================================================

rob_results <- list(
  r1_trends = r1,
  r2_short = r2,
  r3_nocovid = r3,
  r4_nobanned = r4,
  r5_placebo = r5,
  r6_loo = loo_results,
  r7_quintile = r7
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
