# 04_robustness.R — Robustness checks
source("00_packages.R")

df <- readRDS("../data/analysis_dataset.rds")
df <- df %>% mutate(log_total = log(total + 1))

# ---- 1. Pre-trends test: year-by-year interaction ----
cat("=== Pre-trends test ===\n")
df <- df %>%
  mutate(
    year_rel = year - 2023,  # Relative to treatment
    year_fac = factor(year)
  )

# Interact treated × year dummies (omitting year_rel = -1 as reference)
m_pretrend <- feols(multi_unit_share ~ i(year_fac, treated, ref = "2022") | region_id + year,
                     data = df, cluster = ~region_id)
cat("\nEvent-study coefficients:\n")
summary(m_pretrend)

# ---- 2. Exclude Canterbury (Christchurch may have earthquake-related trends) ----
cat("\n=== Excluding Canterbury ===\n")
m_no_cant <- feols(multi_unit_share ~ treat_post | region_id + year,
                    data = df %>% filter(region != "Canterbury"),
                    cluster = ~region_id)
summary(m_no_cant)

# ---- 3. Exclude small regions (potential outliers) ----
cat("\n=== Excluding small regions (<200 annual consents mean) ===\n")
small_regions <- df %>%
  group_by(region) %>%
  summarise(mean_total = mean(total)) %>%
  filter(mean_total < 200) %>%
  pull(region)
cat("Small regions excluded:", paste(small_regions, collapse = ", "), "\n")

m_no_small <- feols(multi_unit_share ~ treat_post | region_id + year,
                     data = df %>% filter(!region %in% small_regions),
                     cluster = ~region_id)
summary(m_no_small)

# ---- 4. Placebo: total consents (level) as outcome ----
cat("\n=== Placebo: total consents ===\n")
m_total <- feols(log_total ~ treat_post | region_id + year, data = df,
                  cluster = ~region_id)
summary(m_total)

# ---- 5. Alternative treatment timing: use 2024 as first post ----
cat("\n=== Delayed treatment (first full year post-MDRS) ===\n")
df_delayed <- df %>%
  mutate(
    post_delayed = as.integer(year >= 2024),
    treat_post_delayed = treated * post_delayed
  )
m_delayed <- feols(multi_unit_share ~ treat_post_delayed | region_id + year,
                    data = df_delayed, cluster = ~region_id)
summary(m_delayed)

# ---- Save robustness results ----
rob_results <- list(
  pretrend = m_pretrend,
  no_canterbury = m_no_cant,
  no_small = m_no_small,
  placebo_total = m_total,
  delayed_treat = m_delayed
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nSaved robustness results.\n")
