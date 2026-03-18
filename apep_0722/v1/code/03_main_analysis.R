# 03_main_analysis.R — Main DiD analysis
# apep_0722: Japan's Split-Rate Consumption Tax

source("00_packages.R")

data_dir <- "../data"

# ===================================================================
# LOAD DATA
# ===================================================================

analysis_data <- readRDS(file.path(data_dir, "cpi_analysis.rds"))
df_2019 <- analysis_data$window_2019
df_2014 <- analysis_data$window_2014

cat(sprintf("2019 window: %d obs\n", nrow(df_2019)))
cat(sprintf("2014 window: %d obs\n", nrow(df_2014)))

# ===================================================================
# MODEL 1: Restaurant (CP11) vs Food (CP01) — Main Specification
# ===================================================================

# Restrict to CP01 and CP11 only for the main spec
df_main <- df_2019 %>%
  filter(coicop %in% c("CP01", "CP11"))

cat("\n=== Model 1: Restaurant vs Food DiD (2019) ===\n")
cat(sprintf("Obs: %d | Categories: %s | Periods: %d\n",
            nrow(df_main),
            paste(unique(df_main$coicop), collapse = ", "),
            n_distinct(df_main$time_period)))

# With only 2 categories, cluster SEs are infeasible. Use heteroskedasticity-robust SEs.
m1 <- feols(log_cpi ~ restaurant:post_2019 | coicop + time_period,
            data = df_main, vcov = "hetero")

cat("\nModel 1 results:\n")
summary(m1)

# ===================================================================
# MODEL 2: All Treated (10% rate) vs Food (CP01)
# ===================================================================

# All categories except _T (total) and CP01 are treated
df_all <- df_2019 %>%
  filter(!is.na(treated_cat))

cat("\n=== Model 2: All Treated vs Food DiD (2019) ===\n")
cat(sprintf("Obs: %d | Treated cats: %d | Control: CP01\n",
            nrow(df_all),
            n_distinct(df_all$coicop[df_all$treated_cat == 1])))

# 12 treated + 1 control = 13 clusters — too few for cluster-robust SEs
# Use heteroskedasticity-robust SEs
m2 <- feols(log_cpi ~ treated_cat:post_2019 | coicop + time_period,
            data = df_all, vcov = "hetero")

cat("\nModel 2 results:\n")
summary(m2)

# ===================================================================
# MODEL 3: PLACEBO — Same specification around April 2014
# ===================================================================

# 2014: uniform increase from 5% to 8%, no reduced rate
# If identification is valid, restaurant:post_2014 should be ~0
df_placebo <- df_2014 %>%
  filter(coicop %in% c("CP01", "CP11"))

cat("\n=== Model 3: Placebo — Restaurant vs Food DiD (2014) ===\n")
cat(sprintf("Obs: %d | Periods: %d\n",
            nrow(df_placebo), n_distinct(df_placebo$time_period)))

m3 <- feols(log_cpi ~ restaurant:post_2014 | coicop + time_period,
            data = df_placebo, vcov = "hetero")

cat("\nModel 3 results:\n")
summary(m3)

# ===================================================================
# MODEL 4: Triple-Difference (2019 DiD vs 2014 DiD)
# ===================================================================

# Stack 2019 and 2014 windows, add era indicator
df_stack <- bind_rows(
  df_2019 %>%
    filter(coicop %in% c("CP01", "CP11")) %>%
    mutate(era_2019 = 1L,
           post = post_2019),
  df_2014 %>%
    filter(coicop %in% c("CP01", "CP11")) %>%
    mutate(era_2019 = 0L,
           post = post_2014)
) %>%
  # Create a unique time identifier for stacked panel
  mutate(era_time = paste0(era_2019, "_", time_period))

cat("\n=== Model 4: Triple-Difference ===\n")
cat(sprintf("Stacked obs: %d\n", nrow(df_stack)))

# Triple-diff: restaurant x post x era_2019
# FE: coicop x era, era_time (absorbs era-specific time effects)
m4 <- feols(log_cpi ~ restaurant:post:era_2019 + restaurant:post + restaurant:era_2019 + post:era_2019 |
              coicop^era_2019 + era_time,
            data = df_stack, vcov = "hetero")

cat("\nModel 4 results:\n")
summary(m4)

# ===================================================================
# PRINT SUMMARY TABLE
# ===================================================================

cat("\n\n========================================\n")
cat("SUMMARY OF MAIN RESULTS\n")
cat("========================================\n\n")

extract_coef <- function(model, pattern) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(pattern, names(cf))
  if (length(idx) == 0) {
    # Try the interaction term
    idx <- which(grepl(pattern, names(cf)))
  }
  if (length(idx) > 0) {
    i <- idx[1]
    return(list(beta = cf[i], se = se[i],
                t = cf[i] / se[i],
                p = 2 * pt(abs(cf[i] / se[i]), df = model$nobs - model$nparams, lower.tail = FALSE),
                name = names(cf)[i]))
  }
  return(list(beta = NA, se = NA, t = NA, p = NA, name = "not found"))
}

r1 <- extract_coef(m1, "restaurant.*post_2019")
r2 <- extract_coef(m2, "treated_cat.*post_2019")
r3 <- extract_coef(m3, "restaurant.*post_2014")
r4 <- extract_coef(m4, "restaurant.*post.*era_2019")

cat(sprintf("Model 1 (Restaurant vs Food):     beta = %8.5f  SE = %8.5f  t = %6.2f  p = %.4f\n",
            r1$beta, r1$se, r1$t, r1$p))
cat(sprintf("Model 2 (All Treated vs Food):     beta = %8.5f  SE = %8.5f  t = %6.2f  p = %.4f\n",
            r2$beta, r2$se, r2$t, r2$p))
cat(sprintf("Model 3 (Placebo 2014):            beta = %8.5f  SE = %8.5f  t = %6.2f  p = %.4f\n",
            r3$beta, r3$se, r3$t, r3$p))
cat(sprintf("Model 4 (Triple-Diff):             beta = %8.5f  SE = %8.5f  t = %6.2f  p = %.4f\n",
            r4$beta, r4$se, r4$t, r4$p))

# ===================================================================
# DIAGNOSTICS
# ===================================================================

# Pre-period months in 2019 window
n_pre_months <- n_distinct(df_2019$time_period[df_2019$post_2019 == 0])
n_treated_cats <- n_distinct(df_all$coicop[df_all$treated_cat == 1])

diagnostics <- list(
  n_treated = n_treated_cats,
  n_pre = n_pre_months,
  n_obs_model1 = m1$nobs,
  n_obs_model2 = m2$nobs,
  n_obs_model3 = m3$nobs,
  n_obs_model4 = m4$nobs,
  coef_model1 = unname(r1$beta),
  se_model1 = unname(r1$se),
  coef_model2 = unname(r2$beta),
  se_model2 = unname(r2$se),
  coef_model3 = unname(r3$beta),
  se_model3 = unname(r3$se),
  coef_model4 = unname(r4$beta),
  se_model4 = unname(r4$se)
)

writeLines(jsonlite::toJSON(diagnostics, auto_unbox = TRUE, pretty = TRUE),
           file.path(data_dir, "diagnostics.json"))
cat("\nDiagnostics written to ../data/diagnostics.json\n")

# ===================================================================
# SAVE RESULTS
# ===================================================================

results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m4 = m4,
  coefficients = list(r1 = r1, r2 = r2, r3 = r3, r4 = r4),
  diagnostics = diagnostics
)

saveRDS(results, file.path(data_dir, "regression_results.rds"))
cat("Results saved to ../data/regression_results.rds\n")
