## 04_robustness.R — Robustness checks and placebo tests
## APEP Paper apep_0927: Japan Equal Pay Act

source("code/00_packages.R")

cat("=== Robustness Checks ===\n")

fs <- read_csv("data/clean_firmsize.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id),
         year_f = factor(year))
ind <- read_csv("data/clean_industry.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id),
         year_f = factor(year))

# =========================================================
# 1. COVID PLACEBO: Regular wage level (not targeted by reform)
# =========================================================

cat("\n--- 1. COVID Placebo: Regular Wage ---\n")
# The reform targets non-regular/regular gap. If regular wages show
# the same firm-size differential post-2020, it's COVID not the reform.
covid_placebo <- feols(
  regular_wage ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)
cat("Regular wage (placebo):\n")
print(summary(covid_placebo))

# =========================================================
# 2. PRE-TREND TEST: Restrict to 2014-2019
# =========================================================

cat("\n--- 2. Pre-Trend Test ---\n")

fs_pre <- fs %>%
  filter(sex == "total", year <= 2019) %>%
  mutate(
    # Fake treatment in 2017 (2 years before actual)
    fake_post = as.integer(year >= 2017),
    # Fake treatment specific to large firms
    fake_treat = as.integer(firm_size == "large" & year >= 2017)
  )

pre_trend <- feols(
  gap ~ fake_treat | panel_id + year_f,
  data = fs_pre,
  cluster = ~ firm_size
)
cat("Pre-trend (fake treatment 2017 for large firms):\n")
print(summary(pre_trend))

# =========================================================
# 3. LEVEL DECOMPOSITION: Non-regular vs Regular wage changes
# =========================================================

cat("\n--- 3. Level Decomposition ---\n")

# Did non-regular wages rise MORE in large firms after 2020?
decomp_nonreg <- feols(
  nonregular_wage ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)

decomp_reg <- feols(
  regular_wage ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)

cat("Non-regular wage (post):", round(coef(decomp_nonreg)["post"], 2),
    "(SE:", round(se(decomp_nonreg)["post"], 2), ")\n")
cat("Regular wage (post):    ", round(coef(decomp_reg)["post"], 2),
    "(SE:", round(se(decomp_reg)["post"], 2), ")\n")

# =========================================================
# 4. ALTERNATIVE OUTCOME: Log wages
# =========================================================

cat("\n--- 4. Log Wage Specification ---\n")

fs_log <- fs %>%
  filter(sex == "total") %>%
  mutate(
    log_gap = log(nonregular_wage) - log(regular_wage),
    log_nonreg = log(nonregular_wage),
    log_reg = log(regular_wage)
  )

log_gap <- feols(
  log_gap ~ post | panel_id + year_f,
  data = fs_log,
  cluster = ~ firm_size
)
cat("Log wage gap:\n")
print(summary(log_gap))

# =========================================================
# 5. STAGGERED REPLICATION TEST
# =========================================================

cat("\n--- 5. Staggered Replication Test ---\n")

# Key COVID robustness: Compare effects at two treatment dates
# If effect appears at BOTH 2020 (large) and 2021 (SMEs), harder to
# attribute to COVID alone

# Large firms only: compare 2019 vs 2020-2024
large_effect <- feols(
  gap ~ i(year_f, ref = "2019") | panel_id,
  data = fs %>% filter(sex == "total", firm_size == "large")
)
cat("Large firm year effects (ref=2019):\n")
print(coeftable(large_effect))

# SMEs only: compare 2020 vs 2021-2024
sme_effect <- feols(
  gap ~ i(year_f, ref = "2020") | panel_id,
  data = fs %>% filter(sex == "total", firm_size %in% c("medium", "small"))
)
cat("\nSME year effects (ref=2020):\n")
print(coeftable(sme_effect))

# =========================================================
# 6. WILD CLUSTER BOOTSTRAP (address few clusters concern)
# =========================================================

cat("\n--- 6. Wild Cluster Bootstrap ---\n")

# With only 3 firm-size clusters, standard cluster SEs may be unreliable
# Use wild cluster bootstrap
tryCatch({
  library(fwildclusterboot)

  twfe_boot <- feols(
    gap ~ post | panel_id + year_f,
    data = fs %>% filter(sex == "total"),
    cluster = ~ firm_size
  )

  boot_result <- boottest(
    twfe_boot,
    param = "post",
    clustid = "firm_size",
    B = 9999,
    type = "webb"  # Webb weights recommended for few clusters
  )
  cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
}, error = function(e) {
  cat("Wild cluster bootstrap not available:", e$message, "\n")
  cat("Note: With only 3 clusters, CIs should be interpreted with caution.\n")
})

# =========================================================
# 7. INDUSTRY-LEVEL ROBUSTNESS: Exclude COVID-hit sectors
# =========================================================

cat("\n--- 7. Industry Robustness ---\n")

# Exclude accommodation/food service (most COVID-affected)
ind_excl <- ind %>%
  filter(sex == "total", !industry %in% c("accommodation_food"))

ind_robust <- feols(
  gap ~ treatment_z:post_full | panel_id + year_f,
  data = ind_excl,
  cluster = ~ industry
)
cat("Industry DiD excl. accommodation/food:\n")
print(summary(ind_robust))

# =========================================================
# SAVE ROBUSTNESS RESULTS
# =========================================================

robustness <- list(
  covid_placebo_coef = coef(covid_placebo)["post"],
  covid_placebo_se = se(covid_placebo)["post"],
  pretrend_coef = coef(pre_trend)["fake_treat"],
  pretrend_se = se(pre_trend)["fake_treat"],
  log_gap_coef = coef(log_gap)["post"],
  log_gap_se = se(log_gap)["post"]
)
saveRDS(robustness, "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
