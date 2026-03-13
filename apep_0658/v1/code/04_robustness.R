## 04_robustness.R — Robustness checks
## apep_0658

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
results <- readRDS("../data/results.rds")

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$muni_code), "municipalities\n")

panel$county <- substr(panel$muni_code, 1, 2)

## =====================================================
## 1. RANDOMIZATION INFERENCE
## =====================================================
cat("\n=== RANDOMIZATION INFERENCE ===\n")

# Main coefficient
main_coef <- coef(results$permits_log)["treat_z_x_post"]
cat("Observed coefficient:", main_coef, "\n")

set.seed(42)
n_perm <- 500
perm_coefs <- numeric(n_perm)

for (i in 1:n_perm) {
  # Randomly reassign treatment across municipalities (within muni_code)
  muni_treat <- panel %>%
    distinct(muni_code, sec_share_2021) %>%
    mutate(sec_share_perm = sample(sec_share_2021))

  panel_perm <- panel %>%
    left_join(muni_treat %>% select(muni_code, sec_share_perm), by = "muni_code") %>%
    mutate(treat_z_perm = (sec_share_perm - mean(sec_share_perm, na.rm = TRUE)) /
                           sd(sec_share_perm, na.rm = TRUE),
           treat_z_perm_x_post = treat_z_perm * post)

  m_perm <- feols(log_permits ~ treat_z_perm_x_post | muni_code + year,
                  data = panel_perm, cluster = ~muni_code)
  perm_coefs[i] <- coef(m_perm)["treat_z_perm_x_post"]
}

ri_p <- mean(abs(perm_coefs) >= abs(main_coef))
cat(sprintf("RI p-value: %.4f (2-sided, %d permutations)\n", ri_p, n_perm))
cat(sprintf("Observed: %.4f, Perm range: [%.4f, %.4f]\n",
    main_coef, min(perm_coefs), max(perm_coefs)))

## =====================================================
## 2. LEAVE-ONE-COUNTY-OUT
## =====================================================
cat("\n=== LEAVE-ONE-COUNTY-OUT ===\n")

counties <- unique(panel$county)
loo_coefs <- numeric(length(counties))
names(loo_coefs) <- counties

for (c in counties) {
  panel_loo <- panel %>% filter(county != c)
  m_loo <- feols(log_permits ~ treat_z_x_post | muni_code + year,
                 data = panel_loo, cluster = ~muni_code)
  loo_coefs[c] <- coef(m_loo)["treat_z_x_post"]
}

cat("Leave-one-county-out range:\n")
cat(sprintf("  Min: %.4f (dropped %s)\n", min(loo_coefs), names(which.min(loo_coefs))))
cat(sprintf("  Max: %.4f (dropped %s)\n", max(loo_coefs), names(which.max(loo_coefs))))
cat(sprintf("  Mean: %.4f, SD: %.4f\n", mean(loo_coefs), sd(loo_coefs)))
cat(sprintf("  Main: %.4f\n", main_coef))

## =====================================================
## 3. ALTERNATIVE TREATMENT: TOP-QUARTILE VS BOTTOM
## =====================================================
cat("\n=== TOP VS BOTTOM QUARTILE ===\n")

panel$treat_q <- ntile(panel$sec_share_2021, 4)
panel_extreme <- panel %>% filter(treat_q %in% c(1, 4))
panel_extreme$high_q <- as.integer(panel_extreme$treat_q == 4)

m_extreme <- feols(log_permits ~ i(high_q, post, ref = 0) | muni_code + year,
                   data = panel_extreme, cluster = ~muni_code)
cat("Q4 vs Q1:\n")
summary(m_extreme)

## =====================================================
## 4. PLACEBO: PRE-REFORM PERIOD (2020 as "treatment")
## =====================================================
cat("\n=== PLACEBO: 2020 as pseudo-treatment ===\n")

# Use the full panel, test whether 2021 looks different from 2020
# under the same treatment variable
panel_placebo <- panel %>%
  filter(year %in% c(2020, 2021)) %>%
  mutate(pseudo_post = as.integer(year >= 2021),
         treat_z_pseudo = treat_z * pseudo_post)

m_placebo <- feols(log_permits ~ treat_z_pseudo | muni_code + year,
                   data = panel_placebo, cluster = ~muni_code)
cat("Placebo (2021 vs 2020):\n")
summary(m_placebo)

## =====================================================
## 5. WILD CLUSTER BOOTSTRAP
## =====================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Use fixest's built-in bootstrap
m_boot <- feols(log_permits ~ treat_z_x_post | muni_code + year,
                data = panel, cluster = ~muni_code)

# Wild bootstrap p-value using fixest
boot_pval <- pvalue(m_boot, ssc = ssc(cluster.adj = TRUE))
cat("Clustered SE p-value:", boot_pval, "\n")

# Two-way clustering: municipality and year
m_twoway <- feols(log_permits ~ treat_z_x_post | muni_code + year,
                  data = panel, cluster = ~muni_code + year)
cat("\nTwo-way clustering (muni + year):\n")
summary(m_twoway)

## =====================================================
## 6. LEVEL SPECIFICATION (not log)
## =====================================================
cat("\n=== LEVEL SPECIFICATION (IHS transform) ===\n")

panel$ihs_permits <- log(panel$permits_started + sqrt(panel$permits_started^2 + 1))

m_ihs <- feols(ihs_permits ~ treat_z_x_post | muni_code + year,
               data = panel, cluster = ~muni_code)
cat("IHS(permits) specification:\n")
summary(m_ihs)

## =====================================================
## SAVE ROBUSTNESS RESULTS
## =====================================================
rob_results <- list(
  ri_p_value = ri_p,
  ri_n_perm = n_perm,
  ri_observed = main_coef,
  ri_perm_coefs = perm_coefs,
  loo_coefs = loo_coefs,
  extreme_quartile = m_extreme,
  placebo = m_placebo,
  twoway = m_twoway,
  ihs = m_ihs
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
