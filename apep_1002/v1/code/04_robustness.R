# 04_robustness.R — Robustness checks
# apep_1002: Czech EET Abolition and Formalization Hysteresis

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/main_models.rds")

# =====================================================================
# 1. WILD CLUSTER BOOTSTRAP (mandatory with 6 clusters)
# =====================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# Main specification
m1 <- models$m1

# Manual wild cluster bootstrap (6 clusters, Rademacher weights)
set.seed(42)
country_list <- unique(panel$geo)
n_boot <- 999
orig_coef <- coef(m1)["treat"]

# Residualize under H0
panel_h0 <- panel
panel_h0$resid_h0 <- residuals(feols(reg_index ~ 1 | cs_id + TIME_PERIOD, data = panel))

boot_stats <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  # Rademacher weights at cluster level
  weights <- setNames(sample(c(-1, 1), length(country_list), replace = TRUE), country_list)
  panel_h0$y_boot <- fitted(feols(reg_index ~ 1 | cs_id + TIME_PERIOD, data = panel)) +
    panel_h0$resid_h0 * weights[panel_h0$geo]
  boot_fit <- tryCatch(
    feols(y_boot ~ treat | cs_id + TIME_PERIOD, data = panel_h0, cluster = ~geo),
    error = function(e) NULL
  )
  boot_stats[b] <- if (!is.null(boot_fit)) coef(boot_fit)["treat"] else NA
}
boot_stats <- na.omit(boot_stats)
wcb_pval <- mean(abs(boot_stats) >= abs(orig_coef))
wcb_ci <- quantile(boot_stats, c(0.025, 0.975))
cat("Wild cluster bootstrap p-value:", wcb_pval, "\n")
cat("WCB 95% CI: [", wcb_ci[1], ",", wcb_ci[2], "]\n")

wcb_result <- list(p_val = wcb_pval, conf_int = as.numeric(wcb_ci), method = "rademacher_wcb")

# =====================================================================
# 2. LEAVE-ONE-OUT: Drop each control country
# =====================================================================
cat("\n=== Leave-One-Out ===\n")

control_countries <- c("HU", "HR", "IT", "PL", "SE")
loo_results <- list()

for (drop_country in control_countries) {
  loo_data <- panel %>% filter(geo != drop_country)
  loo_fit <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                   data = loo_data, cluster = ~geo)
  loo_results[[drop_country]] <- tibble(
    dropped = drop_country,
    estimate = coef(loo_fit)["treat"],
    se = se(loo_fit)["treat"],
    pval = pvalue(loo_fit)["treat"],
    n_obs = nobs(loo_fit)
  )
  cat("Drop", drop_country, ": β =", round(coef(loo_fit)["treat"], 3),
      " (SE =", round(se(loo_fit)["treat"], 3), ")\n")
}

loo_df <- bind_rows(loo_results)
print(loo_df)

# =====================================================================
# 3. PLACEBO TEST: Fake treatment at Q1 2020 (COVID onset)
# =====================================================================
cat("\n=== Placebo Test: Fake treatment Q1 2020 ===\n")

panel_placebo <- panel %>%
  filter(TIME_PERIOD < as.Date("2023-01-01")) %>%
  mutate(
    post_placebo = as.integer(TIME_PERIOD >= as.Date("2020-01-01")),
    treat_placebo = czech * post_placebo
  )

m_placebo <- feols(reg_index ~ treat_placebo | cs_id + TIME_PERIOD,
                   data = panel_placebo, cluster = ~geo)
cat("Placebo (fake Q1 2020 treatment):\n")
summary(m_placebo)

# =====================================================================
# 4. PLACEBO TEST: Fake treatment at Q1 2019
# =====================================================================
cat("\n=== Placebo Test: Fake treatment Q1 2019 ===\n")

panel_placebo2 <- panel %>%
  filter(TIME_PERIOD < as.Date("2020-01-01")) %>%
  mutate(
    post_placebo2 = as.integer(TIME_PERIOD >= as.Date("2019-01-01")),
    treat_placebo2 = czech * post_placebo2
  )

m_placebo2 <- feols(reg_index ~ treat_placebo2 | cs_id + TIME_PERIOD,
                    data = panel_placebo2, cluster = ~geo)
cat("Placebo (fake Q1 2019 treatment):\n")
summary(m_placebo2)

# =====================================================================
# 5. EXCLUDING COVID PERIOD (Q1 2020 - Q4 2021)
# =====================================================================
cat("\n=== Excluding COVID period ===\n")

panel_nocovid <- panel %>%
  filter(!(TIME_PERIOD >= as.Date("2020-01-01") & TIME_PERIOD < as.Date("2022-01-01")))

m_nocovid <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                   data = panel_nocovid, cluster = ~geo)
cat("Excluding COVID (Q1 2020 - Q4 2021):\n")
summary(m_nocovid)

# =====================================================================
# 6. ALTERNATIVE CLUSTERING: Country × Sector
# =====================================================================
cat("\n=== Alternative clustering: country × sector ===\n")

m_alt_cluster <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                       data = panel, cluster = ~cs_id)
cat("Clustered at country-sector level:\n")
summary(m_alt_cluster)

# =====================================================================
# 7. SAVE ROBUSTNESS RESULTS
# =====================================================================

robustness <- list(
  wcb = wcb_result,
  loo = loo_df,
  placebo_2020 = m_placebo,
  placebo_2019 = m_placebo2,
  no_covid = m_nocovid,
  alt_cluster = m_alt_cluster
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
