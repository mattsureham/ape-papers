## 04_robustness.R — Robustness checks and heterogeneity
## Paper: The Deterrence Dividend (apep_0984)

source("00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n\n")

panel   <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# -----------------------------------------------------------------------
# 1. ALTERNATIVE SPECIFICATIONS
# -----------------------------------------------------------------------
cat("1. Alternative specifications\n")

# (a) Log(1+search_index) as outcome
r1 <- feols(log1p_search ~ treated | state_id + time_num,
            data = panel, cluster = ~state_id)

# (b) Drop 2020 (COVID year)
r2 <- feols(search_index ~ treated | state_id + time_num,
            data = panel %>% filter(year != 2020), cluster = ~state_id)

# (c) State-specific linear trends
r3 <- feols(search_index ~ treated | state_id[time_num],
            data = panel, cluster = ~state_id)

# (d) Drop early adopters (TX only in 2021)
r4 <- feols(search_index ~ treated | state_id + time_num,
            data = panel %>%
              filter(!(state_abbr == "TX" & first_treat > 0)),
            cluster = ~state_id)

# (e) Restrict to states with non-trivial search volume
states_with_signal <- panel %>%
  group_by(state_abbr) %>%
  summarise(max_search = max(search_index, na.rm = TRUE), .groups = "drop") %>%
  filter(max_search >= 10) %>%
  pull(state_abbr)

r5 <- feols(search_index ~ treated | state_id + time_num,
            data = panel %>% filter(state_abbr %in% states_with_signal),
            cluster = ~state_id)

cat("Alternative specifications:\n")
etable(r1, r2, r3, r4, r5,
       headers = c("Log(1+Y)", "Drop 2020", "State trends",
                    "Drop TX", "High-signal"),
       se.below = TRUE, keep = "treated")

# -----------------------------------------------------------------------
# 2. LEAVE-ONE-OUT (by cohort)
# -----------------------------------------------------------------------
cat("\n2. Leave-one-out by treatment cohort\n")

cohorts <- unique(panel$cohort[panel$cohort != "Never treated"])
loo_results <- list()

for (coh in cohorts) {
  m <- feols(search_index ~ treated | state_id + time_num,
             data = panel %>% filter(cohort != coh),
             cluster = ~state_id)
  loo_results[[coh]] <- data.frame(
    dropped_cohort = coh,
    coef = coef(m)["treated"],
    se = se(m)["treated"],
    p = pvalue(m)["treated"]
  )
}

loo_df <- bind_rows(loo_results)
cat("Leave-one-out results:\n")
print(loo_df)

# -----------------------------------------------------------------------
# 3. HETEROGENEITY: Law type (penalty vs dealer regulation)
# -----------------------------------------------------------------------
cat("\n3. Heterogeneity by law type\n")

# Create law type indicators
law_type_df <- panel %>%
  distinct(state_abbr, law_type) %>%
  filter(!is.na(law_type))

panel_het <- panel %>%
  mutate(
    is_penalty = ifelse(!is.na(law_type) & law_type == "enhanced_penalty", 1, 0),
    is_dealer  = ifelse(!is.na(law_type) & law_type == "dealer_regulation", 1, 0),
    treated_penalty = treated * is_penalty,
    treated_dealer  = treated * is_dealer
  )

h1 <- feols(search_index ~ treated_penalty + treated_dealer |
              state_id + time_num, data = panel_het, cluster = ~state_id)

cat("Law type heterogeneity:\n")
etable(h1, se.below = TRUE, keep = c("treated_penalty", "treated_dealer"))

# -----------------------------------------------------------------------
# 4. HETEROGENEITY: Early vs late adopters
# -----------------------------------------------------------------------
cat("\n4. Heterogeneity by adoption timing\n")

panel_timing <- panel %>%
  mutate(
    early_adopter = ifelse(first_treat > 0 &
                             !is.na(effective_date) &
                             effective_date < as.Date("2023-01-01"), 1, 0),
    late_adopter  = ifelse(first_treat > 0 &
                             !is.na(effective_date) &
                             effective_date >= as.Date("2023-01-01"), 1, 0),
    treated_early = treated * early_adopter,
    treated_late  = treated * late_adopter
  )

h2 <- feols(search_index ~ treated_early + treated_late |
              state_id + time_num, data = panel_timing, cluster = ~state_id)

cat("Early vs late adopter heterogeneity:\n")
etable(h2, se.below = TRUE, keep = c("treated_early", "treated_late"))

# -----------------------------------------------------------------------
# 5. WILD CLUSTER BOOTSTRAP
# -----------------------------------------------------------------------
cat("\n5. Wild cluster bootstrap inference\n")

# Use fixest boottest via fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  bt <- boottest(results$twfe$m1, param = "treated",
                 clustid = ~state_id, B = 999, type = "webb")
  cat(sprintf("  WCB p-value: %.4f (CI: [%.3f, %.3f])\n",
              bt$p_val, bt$conf_int[1], bt$conf_int[2]))
} else {
  cat("  fwildclusterboot not installed; skipping WCB\n")
  # Manual RI-style permutation test instead
  cat("  Running permutation test (500 iterations)...\n")
  true_coef <- coef(results$twfe$m1)["treated"]
  perm_coefs <- numeric(500)

  for (iter in 1:500) {
    perm_panel <- panel %>%
      mutate(
        # Randomly reassign treatment across states
        perm_ft = sample(first_treat[!duplicated(state_id)])[state_id],
        perm_treated = ifelse(perm_ft > 0 & time_num >= perm_ft, 1, 0)
      )
    m_perm <- feols(search_index ~ perm_treated | state_id + time_num,
                    data = perm_panel, cluster = ~state_id)
    perm_coefs[iter] <- coef(m_perm)["perm_treated"]
  }

  ri_p <- mean(abs(perm_coefs) >= abs(true_coef))
  cat(sprintf("  Randomization inference p-value: %.4f\n", ri_p))
}

# -----------------------------------------------------------------------
# 6. SAVE ROBUSTNESS RESULTS
# -----------------------------------------------------------------------
rob_results <- list(
  alt_specs = list(r1 = r1, r2 = r2, r3 = r3, r4 = r4, r5 = r5),
  loo = loo_df,
  het_law_type = h1,
  het_timing = h2
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nSaved robustness_results.rds\n")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
