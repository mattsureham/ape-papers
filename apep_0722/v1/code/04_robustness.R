# 04_robustness.R — Robustness checks
# apep_0722: Japan's Split-Rate Consumption Tax

source("00_packages.R")

data_dir <- "../data"

# ===================================================================
# LOAD DATA
# ===================================================================

analysis_data <- readRDS(file.path(data_dir, "cpi_analysis.rds"))
df_full <- analysis_data$full

cat(sprintf("Full data: %d obs\n", nrow(df_full)))

# ===================================================================
# ROBUSTNESS 1: Narrow Window (Jul 2019 - Jan 2020)
# ===================================================================

cat("\n=== Robustness 1: Narrow Window ===\n")
cat("Window: 2019-07 to 2020-01 (3 months pre, 4 months post)\n")

df_narrow <- df_full %>%
  filter(
    (year == 2019 & month >= 7) | (year == 2020 & month <= 1),
    coicop %in% c("CP01", "CP11")
  )

cat(sprintf("Obs: %d | Periods: %d\n",
            nrow(df_narrow), n_distinct(df_narrow$time_period)))

r1 <- feols(log_cpi ~ restaurant:post_2019 | coicop + time_period,
            data = df_narrow, vcov = "hetero")

cat("\nNarrow window results:\n")
summary(r1)

# ===================================================================
# ROBUSTNESS 2: CPI Levels Instead of Logs
# ===================================================================

cat("\n=== Robustness 2: CPI Levels ===\n")

df_levels <- df_full %>%
  filter(
    (year >= 2018 & year <= 2019) | (year == 2020 & month <= 1),
    coicop %in% c("CP01", "CP11")
  )

r2 <- feols(cpi ~ restaurant:post_2019 | coicop + time_period,
            data = df_levels, vcov = "hetero")

cat("\nLevels results:\n")
summary(r2)

# ===================================================================
# ROBUSTNESS 3: Placebo Outcome — Health (CP06) vs Food (CP01)
# ===================================================================

cat("\n=== Robustness 3: Health vs Food Placebo ===\n")
cat("Both at 10% and 8% respectively, but health spending is inelastic\n")

df_health <- df_full %>%
  filter(
    (year >= 2018 & year <= 2019) | (year == 2020 & month <= 1),
    coicop %in% c("CP01", "CP06")
  ) %>%
  mutate(health = ifelse(coicop == "CP06", 1L, 0L))

r3 <- feols(log_cpi ~ health:post_2019 | coicop + time_period,
            data = df_health, vcov = "hetero")

cat("\nHealth placebo results:\n")
summary(r3)

# ===================================================================
# SUMMARY
# ===================================================================

cat("\n\n========================================\n")
cat("ROBUSTNESS SUMMARY\n")
cat("========================================\n\n")

extract <- function(model, pattern) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(pattern, names(cf))[1]
  list(beta = cf[idx], se = se[idx], n = model$nobs)
}

s1 <- extract(r1, "restaurant.*post_2019")
s2 <- extract(r2, "restaurant.*post_2019")
s3 <- extract(r3, "health.*post_2019")

cat(sprintf("1. Narrow window:   beta = %8.5f  SE = %8.5f  N = %d\n",
            s1$beta, s1$se, s1$n))
cat(sprintf("2. CPI levels:      beta = %8.3f  SE = %8.3f  N = %d\n",
            s2$beta, s2$se, s2$n))
cat(sprintf("3. Health placebo:  beta = %8.5f  SE = %8.5f  N = %d\n",
            s3$beta, s3$se, s3$n))

# ===================================================================
# SAVE
# ===================================================================

robustness_results <- list(
  narrow_window = r1,
  levels = r2,
  health_placebo = r3,
  summaries = list(narrow = s1, levels = s2, health = s3)
)

saveRDS(robustness_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved to ../data/robustness_results.rds\n")
