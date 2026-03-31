# =============================================================================
# 04_robustness.R — Robustness checks
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
load("../data/models.RData")

# ============================================================================
# 1. PLACEBO CUTOFF: Use 20-49 employee share instead of 10-19
#    Firms with 20-49 employees were ALWAYS subject to the audit mandate.
#    If our results are driven by the 2017 reform (lowering threshold from
#    25 to 10), then using always-treated firms should yield a null.
# ============================================================================
cat("=== 1. Placebo Treatment: 20-49 employee share ===\n")

firm_data <- readRDS("../data/firm_counts_by_size.rds")
names(firm_data) <- c("industry", "size_class", "year", "n_firms")
firm_data$year <- as.integer(firm_data$year)

# Compute pre-reform share of 20-49 employee firms
firm_totals <- firm_data %>%
  filter(size_class != "SGR0") %>%
  group_by(industry, year) %>%
  summarise(total = sum(n_firms, na.rm = TRUE), .groups = "drop")

firms_20_49 <- firm_data %>%
  filter(size_class == "SGR4") %>%
  select(industry, year, n_20_49 = n_firms)

placebo_treat <- firm_totals %>%
  left_join(firms_20_49, by = c("industry", "year")) %>%
  mutate(share_20_49 = n_20_49 / total) %>%
  filter(year >= 2010, year <= 2016) %>%
  group_by(industry) %>%
  summarise(placebo_intensity = mean(share_20_49, na.rm = TRUE), .groups = "drop")

df_placebo <- df %>%
  left_join(placebo_treat, by = "industry") %>%
  mutate(post_placebo = post * placebo_intensity)

m_placebo <- feols(gap_monthly ~ post_placebo | industry + year,
                   data = df_placebo, cluster = ~industry)
cat("Placebo (20-49 employee share):\n")
summary(m_placebo)

# ============================================================================
# 2. PLACEBO TIMING: Apply reform at 2014 (in pre-period)
#    If results are driven by the 2017 reform, a fake reform date should
#    yield null effects in the pre-period
# ============================================================================
cat("\n=== 2. Placebo Timing: Fake reform at 2014 ===\n")

df_pre <- df %>%
  filter(year <= 2016) %>%
  mutate(
    fake_post = as.integer(year >= 2015),
    fake_post_treat = fake_post * treat_intensity_pre
  )

m_timing <- feols(gap_monthly ~ fake_post_treat | industry + year,
                  data = df_pre, cluster = ~industry)
cat("Placebo timing (fake reform 2014→2015):\n")
summary(m_timing)

# ============================================================================
# 3. ALTERNATIVE OUTCOME: Female wage growth vs. male wage growth
#    Decompose: does the gap narrow because female wages rise faster?
# ============================================================================
cat("\n=== 3. Wage Growth Decomposition ===\n")

# Within-industry year-over-year growth
df <- df %>%
  arrange(industry, year) %>%
  group_by(industry) %>%
  mutate(
    growth_female = (monthly_salary_female - lag(monthly_salary_female)) /
                    lag(monthly_salary_female) * 100,
    growth_male = (monthly_salary_male - lag(monthly_salary_male)) /
                  lag(monthly_salary_male) * 100,
    growth_diff = growth_female - growth_male
  ) %>%
  ungroup()

m_growth_f <- feols(growth_female ~ post_treat | industry + year,
                    data = df, cluster = ~industry)
m_growth_m <- feols(growth_male ~ post_treat | industry + year,
                    data = df, cluster = ~industry)
m_growth_d <- feols(growth_diff ~ post_treat | industry + year,
                    data = df, cluster = ~industry)

cat("Female wage growth:\n")
summary(m_growth_f)
cat("\nMale wage growth:\n")
summary(m_growth_m)
cat("\nDifferential growth (F - M):\n")
summary(m_growth_d)

# ============================================================================
# 4. WEIGHTED REGRESSION: Weight by industry employment
# ============================================================================
cat("\n=== 4. Employment-Weighted Regression ===\n")

# Use total firm count as proxy for industry size
firm_size_proxy <- firm_data %>%
  filter(size_class != "SGR0") %>%
  group_by(industry, year) %>%
  summarise(total_firms = sum(n_firms, na.rm = TRUE), .groups = "drop")

df_w <- df %>%
  left_join(firm_size_proxy, by = c("industry", "year"), suffix = c("", ".fw")) %>%
  mutate(weight = total_firms.fw)

m_weighted <- feols(gap_monthly ~ post_treat | industry + year,
                    data = df_w %>% filter(!is.na(weight)),
                    weights = ~weight, cluster = ~industry)
cat("Employment-weighted:\n")
summary(m_weighted)

# ============================================================================
# 5. LEAVE-ONE-OUT: Drop each industry and re-estimate
# ============================================================================
cat("\n=== 5. Leave-One-Out ===\n")

industries <- unique(df$industry)
loo_coefs <- numeric(length(industries))
names(loo_coefs) <- industries

for (ind in industries) {
  m_loo <- feols(gap_monthly ~ post_treat | industry + year,
                 data = df %>% filter(industry != ind), cluster = ~industry)
  loo_coefs[ind] <- coef(m_loo)["post_treat"]
}

cat("Leave-one-out coefficients:\n")
cat(sprintf("  Full sample: %.3f\n", coef(m1)["post_treat"]))
cat(sprintf("  LOO range: [%.3f, %.3f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("  LOO mean: %.3f\n", mean(loo_coefs)))
cat("Most influential industries:\n")
loo_influence <- sort(abs(loo_coefs - coef(m1)["post_treat"]), decreasing = TRUE)
print(head(loo_influence))

# ============================================================================
# 6. BASIC SALARY (excludes variable compensation)
# ============================================================================
cat("\n=== 6. Basic Salary Results ===\n")

m_basic <- feols(gap_basic ~ post_treat | industry + year,
                 data = df, cluster = ~industry)
cat("Basic salary gap:\n")
summary(m_basic)

# Save all robustness models
save(m_placebo, m_timing, m_growth_f, m_growth_m, m_growth_d,
     m_weighted, m_basic, loo_coefs,
     file = "../data/robustness_models.RData")
cat("\nAll robustness checks saved.\n")
