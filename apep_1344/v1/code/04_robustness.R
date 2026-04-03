# 04_robustness.R — Robustness checks and falsification tests
# apep_1344: The Potency Arms Race

source("00_packages.R")

cat("=== Loading data ===\n")
analysis_df <- readRDS("../data/analysis_clean.rds")
panel_df <- readRDS("../data/panel_clean.rds")

# ============================================================
# 1. HYDROCODONE PLACEBO
# ============================================================
cat("\n=== Robustness 1: Hydrocodone Placebo ===\n")

# Mallinckrodt did NOT expand hydrocodone product lines in 2008
# If the instrument is valid, 2006 Mallinckrodt oxy share should NOT predict
# hydrocodone potency changes
placebo_hydro <- feols(delta_hydro_mme ~ malli_share_2006 | BUYER_STATE,
                       data = analysis_df %>% filter(!is.na(delta_hydro_mme)),
                       vcov = ~BUYER_STATE)

cat(sprintf("Hydrocodone placebo: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(placebo_hydro)["malli_share_2006"],
            sqrt(vcov(placebo_hydro)["malli_share_2006", "malli_share_2006"]),
            fixest::pvalue(placebo_hydro)["malli_share_2006"]))

# ============================================================
# 2. BALANCE TEST — Pre-period characteristics
# ============================================================
cat("\n=== Robustness 2: Balance Test ===\n")

# Test whether 2006 Mallinckrodt share correlates with pre-period outcomes
bal1 <- feols(mme_per_pill_pre ~ malli_share_2006 | BUYER_STATE,
              data = analysis_df, vcov = ~BUYER_STATE)
bal2 <- feols(log_pills_pre ~ malli_share_2006 | BUYER_STATE,
              data = analysis_df, vcov = ~BUYER_STATE)
bal3 <- feols(high_dose_share_pre ~ malli_share_2006 | BUYER_STATE,
              data = analysis_df, vcov = ~BUYER_STATE)

cat(sprintf("  Pre-period MME/pill:       β = %.4f (p = %.3f)\n",
            coef(bal1)["malli_share_2006"], fixest::pvalue(bal1)["malli_share_2006"]))
cat(sprintf("  Pre-period log pills:      β = %.4f (p = %.3f)\n",
            coef(bal2)["malli_share_2006"], fixest::pvalue(bal2)["malli_share_2006"]))
cat(sprintf("  Pre-period high-dose share: β = %.4f (p = %.3f)\n",
            coef(bal3)["malli_share_2006"], fixest::pvalue(bal3)["malli_share_2006"]))

# ============================================================
# 3. LEAVE-ONE-STATE-OUT
# ============================================================
cat("\n=== Robustness 3: Leave-One-State-Out ===\n")

states <- unique(analysis_df$BUYER_STATE)
loo_coefs <- numeric(length(states))

for (i in seq_along(states)) {
  loo_data <- analysis_df %>% filter(BUYER_STATE != states[i])
  loo_model <- feols(delta_mme ~ malli_share_2006 | BUYER_STATE, data = loo_data)
  loo_coefs[i] <- coef(loo_model)["malli_share_2006"]
}

cat(sprintf("LOO coefficients: min = %.3f, max = %.3f, mean = %.3f\n",
            min(loo_coefs), max(loo_coefs), mean(loo_coefs)))
cat(sprintf("All same sign: %s (N = %d/%d)\n",
            ifelse(all(loo_coefs > 0) || all(loo_coefs < 0), "YES", "NO"),
            sum(sign(loo_coefs) == sign(mean(loo_coefs))), length(loo_coefs)))

# ============================================================
# 4. ALTERNATIVE POTENCY MEASURE
# ============================================================
cat("\n=== Robustness 4: Alternative Potency Measure (High-Dose Share) ===\n")

alt1 <- feols(delta_high_dose ~ malli_share_2006 | BUYER_STATE,
              data = analysis_df, vcov = ~BUYER_STATE)
cat(sprintf("High-dose share change: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(alt1)["malli_share_2006"],
            sqrt(vcov(alt1)["malli_share_2006", "malli_share_2006"]),
            fixest::pvalue(alt1)["malli_share_2006"]))

# ============================================================
# 5. DOSE-SPECIFIC DECOMPOSITION
# ============================================================
cat("\n=== Robustness 5: Dose-Specific Decomposition ===\n")

# delta_40plus already computed in 02_clean_data.R
dose_spec <- feols(delta_40plus ~ malli_share_2006 | BUYER_STATE,
                   data = analysis_df %>% filter(!is.na(delta_40plus)),
                   vcov = ~BUYER_STATE)
cat(sprintf("40mg+ share change: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(dose_spec)["malli_share_2006"],
            sqrt(vcov(dose_spec)["malli_share_2006", "malli_share_2006"]),
            fixest::pvalue(dose_spec)["malli_share_2006"]))

# ============================================================
# Save robustness models
# ============================================================
cat("\n=== Saving robustness models ===\n")

rob_models <- list(
  placebo_hydro = placebo_hydro,
  bal1 = bal1, bal2 = bal2, bal3 = bal3,
  alt_high_dose = alt1,
  dose_40plus = dose_spec,
  loo_coefs = loo_coefs,
  loo_states = states
)
saveRDS(rob_models, "../data/robustness_models.rds")
saveRDS(analysis_df, "../data/analysis_final.rds")
cat("Robustness complete.\n")
