## 04_robustness.R — Robustness checks for apep_0963

source("00_packages.R")
library(fixest)

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
df_full <- readRDS(file.path(data_dir, "analysis_data.rds"))

cat("=== Robustness Checks ===\n\n")

## =========================================================================
## 1. Placebo test: treatment at 2019 (using 2018 vs 2019 only)
## =========================================================================
cat("--- 1. Placebo test (pre-period only) ---\n")
df_pre <- df %>%
  filter(year %in% c(2018, 2019)) %>%
  mutate(
    placebo_post = as.integer(year == 2019),
    placebo_treat = placebo_post * treat_intensity
  )

m_placebo <- feols(food_insecure ~ placebo_treat + age + college + black +
                     hispanic + hh_size + has_children + low_income + unemp_rate |
                     statefip + year,
                   data = df_pre, cluster = ~statefip, weights = ~hh_weight)

cat(sprintf("Placebo β: %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_placebo)["placebo_treat"],
            se(m_placebo)["placebo_treat"],
            pvalue(m_placebo)["placebo_treat"]))

## =========================================================================
## 2. Include transition years (2020-2021) with EA control
## =========================================================================
cat("\n--- 2. Full sample with EA control ---\n")
m_full <- feols(food_insecure ~ post_treat + ea_active + age + college +
                  black + hispanic + hh_size + has_children + low_income +
                  unemp_rate | statefip + year,
                data = df_full, cluster = ~statefip, weights = ~hh_weight)

cat(sprintf("Full sample β: %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_full)["post_treat"],
            se(m_full)["post_treat"],
            pvalue(m_full)["post_treat"]))
cat(sprintf("EA active: %.4f (SE = %.4f)\n",
            coef(m_full)["ea_active"],
            se(m_full)["ea_active"]))

## =========================================================================
## 3. Wild cluster bootstrap (main specification)
## =========================================================================
cat("\n--- 3. Wild cluster bootstrap ---\n")
## Use fwildclusterboot for robust inference with 51 clusters
m_main <- feols(food_insecure ~ post_treat + age + college + black +
                  hispanic + hh_size + has_children + low_income + unemp_rate |
                  statefip + year,
                data = df, cluster = ~statefip, weights = ~hh_weight)

boot_result <- tryCatch({
  boottest(m_main, param = "post_treat", B = 9999, type = "webb",
           clustid = ~statefip)
}, error = function(e) {
  cat(sprintf("  Bootstrap error: %s\n", e$message))
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("Bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("Bootstrap CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
}

## =========================================================================
## 4. Leave-one-out state analysis
## =========================================================================
cat("\n--- 4. Leave-one-out state analysis ---\n")
states <- unique(df$statefip)
loo_coefs <- numeric(length(states))

for (i in seq_along(states)) {
  df_loo <- df %>% filter(statefip != states[i])
  m_loo <- feols(food_insecure ~ post_treat + age + college + black +
                   hispanic + hh_size + has_children + low_income + unemp_rate |
                   statefip + year,
                 data = df_loo, cluster = ~statefip, weights = ~hh_weight)
  loo_coefs[i] <- coef(m_loo)["post_treat"]
}

cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("LOO mean: %.4f, SD: %.4f\n", mean(loo_coefs), sd(loo_coefs)))
cat(sprintf("Sign changes: %d\n", sum(loo_coefs < 0)))

## =========================================================================
## 5. Unweighted specification
## =========================================================================
cat("\n--- 5. Unweighted specification ---\n")
m_unwt <- feols(food_insecure ~ post_treat + age + college + black +
                  hispanic + hh_size + has_children + low_income + unemp_rate |
                  statefip + year,
                data = df, cluster = ~statefip)

cat(sprintf("Unweighted β: %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_unwt)["post_treat"],
            se(m_unwt)["post_treat"],
            pvalue(m_unwt)["post_treat"]))

## =========================================================================
## 6. State-level aggregated regression
## =========================================================================
cat("\n--- 6. State-level aggregated regression ---\n")
state_panel <- df %>%
  group_by(statefip, year, state_name, snap_rate, post, treat_intensity,
           post_treat, early_ea_end) %>%
  summarise(
    food_insecure = weighted.mean(food_insecure, hh_weight, na.rm = TRUE),
    very_low_fs = weighted.mean(very_low_fs, hh_weight, na.rm = TRUE),
    snap_receipt = weighted.mean(snap_receipt, hh_weight, na.rm = TRUE),
    unemp_rate = first(unemp_rate),
    n_hh = n(),
    .groups = "drop"
  )

m_state <- feols(food_insecure ~ post_treat + unemp_rate | statefip + year,
                 data = state_panel, cluster = ~statefip,
                 weights = ~n_hh)

cat(sprintf("State-level β: %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_state)["post_treat"],
            se(m_state)["post_treat"],
            pvalue(m_state)["post_treat"]))

## =========================================================================
## 7. Alternative treatment: above/below median SNAP rate
## =========================================================================
cat("\n--- 7. Binary treatment (above/below median SNAP rate) ---\n")
median_snap <- median(unique(df$snap_rate))
df_binary <- df %>%
  mutate(
    high_snap = as.integer(snap_rate >= median_snap),
    post_high = post * high_snap
  )

m_binary <- feols(food_insecure ~ post_high + age + college + black +
                    hispanic + hh_size + has_children + low_income + unemp_rate |
                    statefip + year,
                  data = df_binary, cluster = ~statefip, weights = ~hh_weight)

cat(sprintf("Binary β: %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_binary)["post_high"],
            se(m_binary)["post_high"],
            pvalue(m_binary)["post_high"]))

## =========================================================================
## Save robustness results
## =========================================================================
rob_results <- list(
  m_placebo = m_placebo,
  m_full = m_full,
  m_unwt = m_unwt,
  m_state = m_state,
  m_binary = m_binary,
  boot_result = boot_result,
  loo_coefs = loo_coefs,
  state_panel = state_panel
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
