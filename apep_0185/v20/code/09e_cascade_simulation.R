################################################################################
# 09e_cascade_simulation.R
# Cascade / Multiplier Analysis
#
# Only meaningful if the IV coefficient from 09d is positive and significant.
# If the effect is null, this script reports that and exits.
#
# If warranted:
#   - Closed-form: spectral radius of β×W gives cascade parameter
#   - Simulation: CA raises MW by $1 → trace network propagation
#     → iterate until cascade dies → 10,000 draws → median states affected + 90% CI
#
# Input:  ../data/state_diffusion_panel.rds, state_sci_weights.rds,
#         diffusion_scenario.txt (from 09d)
# Output: Console results + ../data/cascade_results.rds (if warranted)
################################################################################

source("00_packages.R")

cat("=== Cascade / Multiplier Analysis ===\n\n")

# ============================================================================
# 1. Check Scenario
# ============================================================================

scenario <- readLines("../data/diffusion_scenario.txt")[1]
cat("Scenario from 09d:", scenario, "\n\n")

if (scenario != "A") {
  cat("Scenario is not A (effect does not survive IV).\n")
  cat("Cascade multiplier is not meaningful — skipping.\n")
  cat("=== Cascade Analysis Skipped ===\n")
  # Save null results for downstream
  saveRDS(list(scenario = scenario, cascade_computed = FALSE), "../data/cascade_results.rds")
  quit(save = "no", status = 0)
}

# ============================================================================
# 2. Load Data
# ============================================================================

cat("2. Loading state SCI weights and diffusion estimates...\n")

state_sci <- readRDS("../data/state_sci_weights.rds")
df <- readRDS("../data/state_diffusion_panel.rds")

# Re-estimate the IV model to get β
df_main <- df %>% filter(!at_ceiling)

m_iv <- feols(mw_increased ~ log_own_mw +
                gov_dem + trifecta_dem + trifecta_rep +
                union_density + unemp_rate |
                state_fips + census_region^year |
                network_mw_full ~ network_mw_nonadj,
              data = df_main, cluster = ~state_fips)

beta_hat <- coef(m_iv)["fit_network_mw_full"]
beta_se <- sqrt(vcov(m_iv)["fit_network_mw_full", "fit_network_mw_full"])

cat("  IV coefficient: β =", round(beta_hat, 4), "(SE =", round(beta_se, 4), ")\n")

# ============================================================================
# 3. Construct State Weight Matrix W
# ============================================================================

cat("\n3. Constructing state weight matrix W...\n")

states <- sort(unique(c(state_sci$state_fips_1, state_sci$state_fips_2)))
n_states <- length(states)
state_idx <- setNames(1:n_states, states)

# Build W matrix
W <- matrix(0, n_states, n_states)
for (i in 1:nrow(state_sci)) {
  s1 <- state_idx[state_sci$state_fips_1[i]]
  s2 <- state_idx[state_sci$state_fips_2[i]]
  if (!is.na(s1) && !is.na(s2)) {
    W[s1, s2] <- state_sci$w_state[i]
  }
}

cat("  Weight matrix:", n_states, "x", n_states, "\n")
cat("  Row sums (should be ~1):", round(mean(rowSums(W)), 4), "\n")

# ============================================================================
# 4. Closed-Form: Spectral Radius
# ============================================================================

cat("\n4. Spectral radius analysis...\n")

# β×W: the cascade matrix
cascade_matrix <- beta_hat * W
eigenvalues <- eigen(cascade_matrix)$values
spectral_radius <- max(Mod(eigenvalues))

cat("  Spectral radius of β×W:", round(spectral_radius, 4), "\n")

if (spectral_radius < 1) {
  cat("  Cascade is CONVERGENT (ρ < 1) — shocks dampen over iterations\n")
  # Long-run multiplier: (I - β×W)^{-1}
  I <- diag(n_states)
  multiplier_matrix <- solve(I - cascade_matrix)
  # Average multiplier: mean of row sums of multiplier matrix
  avg_multiplier <- mean(rowSums(multiplier_matrix))
  cat("  Average long-run multiplier:", round(avg_multiplier, 3), "\n")
  cat("  Interpretation: a $1 MW increase in one state eventually causes\n")
  cat("  the equivalent of", round(avg_multiplier, 2), "total state MW events\n")
} else {
  cat("  WARNING: Spectral radius >= 1 — cascade is explosive (unstable model)\n")
  cat("  This suggests the model may be misspecified at these parameter values\n")
}

# ============================================================================
# 5. Monte Carlo Simulation: CA Raises MW by $1
# ============================================================================

cat("\n5. Simulating cascade from California $1 MW increase...\n")

# California shock
ca_idx <- state_idx["06"]
if (is.na(ca_idx)) {
  cat("  ERROR: California not found in state list\n")
} else {
  set.seed(2024)
  n_sims <- 10000
  max_rounds <- 20  # Max cascade iterations

  sim_results <- matrix(0, n_sims, max_rounds)
  total_states_affected <- rep(0, n_sims)

  for (sim in 1:n_sims) {
    # Draw β from its sampling distribution
    beta_draw <- rnorm(1, mean = beta_hat, sd = beta_se)

    # Initial shock: CA raises MW
    affected <- rep(FALSE, n_states)
    new_shocks <- rep(0, n_states)
    new_shocks[ca_idx] <- 1  # $1 increase in log-MW space (approximately)

    round_count <- 0
    for (r in 1:max_rounds) {
      # Propagation: probability of adoption = β × (W × shocks)
      propagation <- beta_draw * (W %*% new_shocks)

      # Each state adopts with probability = propagation (capped at [0,1])
      adopt_prob <- pmin(pmax(propagation, 0), 1)
      new_adopters <- rbinom(n_states, 1, adopt_prob)

      # Only count states that haven't already been affected
      new_adopters[affected | (1:n_states == ca_idx)] <- 0

      if (sum(new_adopters) == 0) break  # Cascade died

      affected[new_adopters == 1] <- TRUE
      new_shocks <- new_adopters  # Next round's shocks
      sim_results[sim, r] <- sum(new_adopters)
      round_count <- r
    }

    total_states_affected[sim] <- sum(affected)
  }

  # Summary statistics
  cat("  Simulations:", n_sims, "\n")
  cat("  Median states affected:", median(total_states_affected), "\n")
  cat("  Mean states affected:", round(mean(total_states_affected), 1), "\n")
  cat("  90% CI: [", quantile(total_states_affected, 0.05), ",",
      quantile(total_states_affected, 0.95), "]\n")
  cat("  Probability of zero cascade:", round(mean(total_states_affected == 0), 3), "\n")

  # By round
  cat("\n  Cascade by round:\n")
  for (r in 1:min(5, max_rounds)) {
    cat("    Round", r, ": median =", median(sim_results[, r]),
        ", mean =", round(mean(sim_results[, r]), 2), "\n")
  }
}

# ============================================================================
# 6. Save Results
# ============================================================================

cat("\n6. Saving cascade results...\n")

cascade_results <- list(
  scenario = scenario,
  cascade_computed = TRUE,
  beta_hat = beta_hat,
  beta_se = beta_se,
  spectral_radius = spectral_radius,
  avg_multiplier = if (spectral_radius < 1) avg_multiplier else NA,
  median_states_affected = median(total_states_affected),
  mean_states_affected = mean(total_states_affected),
  ci_90 = quantile(total_states_affected, c(0.05, 0.95)),
  prob_zero_cascade = mean(total_states_affected == 0),
  sim_by_round = colMeans(sim_results),
  total_states_distribution = total_states_affected
)

saveRDS(cascade_results, "../data/cascade_results.rds")

cat("\nSaved ../data/cascade_results.rds\n")
cat("=== Cascade Analysis Complete ===\n")
