# ==============================================================================
# 04_robustness.R — Robustness checks
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

# Load only needed columns to minimize memory
rob_cols <- c("delta_occscore", "treatment", "alc_share", "treated_state",
              "age_1910", "age_sq", "immigrant", "black", "married", "literate",
              "occscore_1910", "region", "statefip_1910", "male",
              "bartender_share", "bev_manuf_share", "alc_quartile")
dt <- fread("../data/analysis_sample.csv", select = rob_cols)
males <- dt[male == 1]
males[, male := NULL]
rm(dt); gc()

# ==============================================================================
# 1. Non-Southern States Only (Preferred Specification)
# ==============================================================================
cat("=== ROBUSTNESS: Non-South Sample ===\n")

nonsouth <- males[region != "South"]
rob_nonsouth <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                        age_1910 + age_sq + immigrant + black + married + literate +
                        occscore_1910 | region,
                      data = nonsouth, cluster = ~statefip_1910)
rm(nonsouth); gc()

# ==============================================================================
# 2. Leave-One-Out by State
# ==============================================================================
cat("=== ROBUSTNESS: Leave-One-Out ===\n")

states <- unique(males$statefip_1910)
loo_results <- rbindlist(lapply(states, function(s) {
  fit <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                 age_1910 + age_sq + immigrant + black + married + literate +
                 occscore_1910 | region,
               data = males[statefip_1910 != s], cluster = ~statefip_1910)
  data.table(excluded_state = s,
             beta = coef(fit)["treatment"],
             se = se(fit)["treatment"])
}))

fwrite(loo_results, "../data/loo_results.csv")
cat("LOO range: [", round(min(loo_results$beta), 3), ",",
    round(max(loo_results$beta), 3), "]\n")

# ==============================================================================
# 3. Zero-Exposure Placebo
# ==============================================================================
cat("=== ROBUSTNESS: Zero-Exposure Placebo ===\n")

zero_exp <- males[alc_share == 0]
rob_zero <- feols(delta_occscore ~ treated_state +
                    age_1910 + age_sq + immigrant + black + married + literate +
                    occscore_1910 | region,
                  data = zero_exp, cluster = ~statefip_1910)
cat("Zero-exposure placebo: beta =", round(coef(rob_zero)["treated_state"], 3),
    ", se =", round(se(rob_zero)["treated_state"], 3), "\n")
rm(zero_exp); gc()

# ==============================================================================
# 4. Randomization Inference
# ==============================================================================
cat("=== ROBUSTNESS: Randomization Inference ===\n")

# True treatment effect
true_beta <- coef(feols(delta_occscore ~ treatment + alc_share + treated_state +
                          age_1910 + age_sq + immigrant + black + married + literate +
                          occscore_1910 | region,
                        data = males, cluster = ~statefip_1910))["treatment"]

# Permute state prohibition assignments 500 times
n_perms <- 500
perm_betas <- numeric(n_perms)

# Get unique treated/control states
state_treat <- unique(males[, .(statefip_1910, treated_state)])
n_treated <- sum(state_treat$treated_state == 1)

# Use only needed columns for merge to save memory
males_slim <- males[, .(delta_occscore, alc_share, statefip_1910,
                         age_1910, age_sq, immigrant, black, married,
                         literate, occscore_1910, region)]

for (i in 1:n_perms) {
  perm_assignment <- state_treat[, .(statefip_1910,
                                      perm_treated = sample(treated_state))]
  perm_data <- merge(males_slim, perm_assignment, by = "statefip_1910")
  perm_data[, perm_treatment := alc_share * perm_treated]

  fit <- tryCatch(
    feols(delta_occscore ~ perm_treatment + alc_share + perm_treated +
            age_1910 + age_sq + immigrant + black + married + literate +
            occscore_1910 | region,
          data = perm_data, cluster = ~statefip_1910),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    perm_betas[i] <- coef(fit)["perm_treatment"]
    rm(fit)
  } else {
    perm_betas[i] <- NA
  }
  rm(perm_data, perm_assignment)

  if (i %% 100 == 0) { gc(); cat("  Permutation", i, "of", n_perms, "\n") }
}

rm(males_slim); gc()
perm_betas <- perm_betas[!is.na(perm_betas)]
ri_pval <- mean(abs(perm_betas) >= abs(true_beta))
cat("RI p-value:", round(ri_pval, 3), "(", length(perm_betas), "valid permutations)\n")

ri_results <- data.table(perm_beta = perm_betas)
ri_results[, true_beta := true_beta]
fwrite(ri_results, "../data/ri_results.csv")

# ==============================================================================
# 5. Alternative Treatment Definitions
# ==============================================================================
cat("=== ROBUSTNESS: Alternative Treatments ===\n")

# Free RI objects to reclaim memory
rm(perm_betas, ri_results)
gc()

# 5a. Bartender share only (narrow definition, OCC1950=730)
males[, treatment_bartender := bartender_share * treated_state]
rob_bartender <- feols(delta_occscore ~ treatment_bartender + bartender_share + treated_state +
                       age_1910 + age_sq + immigrant + black + married + literate +
                       occscore_1910 | region,
                     data = males, cluster = ~statefip_1910)

# Extract coefficients immediately
bart_beta <- coef(rob_bartender)["treatment_bartender"]
bart_se <- se(rob_bartender)["treatment_bartender"]
rm(rob_bartender); gc()

# 5b. Beverage manufacturing share (IND1950=216)
males[, treatment_bevmanuf := bev_manuf_share * treated_state]
rob_bevmanuf <- feols(delta_occscore ~ treatment_bevmanuf + bev_manuf_share + treated_state +
                      age_1910 + age_sq + immigrant + black + married + literate +
                      occscore_1910 | region,
                    data = males, cluster = ~statefip_1910)

bev_beta <- coef(rob_bevmanuf)["treatment_bevmanuf"]
bev_se <- se(rob_bevmanuf)["treatment_bevmanuf"]
rm(rob_bevmanuf); gc()

# 5c. Top vs bottom quartile of exposure (discrete treatment)
# Use high vs low binary to avoid memory-expensive factor interaction
males[, high_exposure := as.integer(alc_share > median(males[alc_share > 0, alc_share]))]
males[, treatment_high := high_exposure * treated_state]
rob_discrete <- feols(delta_occscore ~ treatment_high + high_exposure + treated_state +
                        age_1910 + age_sq + immigrant + black + married + literate +
                        occscore_1910 | region,
                      data = males[alc_share > 0], cluster = ~statefip_1910)
disc_beta <- coef(rob_discrete)["treatment_high"]
disc_se <- se(rob_discrete)["treatment_high"]
rm(rob_discrete); gc()

# Remove temp columns
males[, c("treatment_bartender", "treatment_bevmanuf", "high_exposure", "treatment_high") := NULL]

# ==============================================================================
# 6. Wild Cluster Bootstrap (for few-cluster robustness)
# ==============================================================================
cat("=== ROBUSTNESS: Wild Cluster Bootstrap ===\n")

# Count clusters
n_clusters <- uniqueN(males$statefip_1910)
cat("Number of state clusters:", n_clusters, "\n")

# Wild bootstrap with Rademacher weights — reduced to 499 for memory
n_boot <- 499
boot_betas <- numeric(n_boot)

# Base fit for reference
base_fit <- feols(delta_occscore ~ treatment + alc_share + treated_state +
                    age_1910 + age_sq + immigrant + black + married + literate +
                    occscore_1910 | region,
                  data = males, cluster = ~statefip_1910)
base_beta <- coef(base_fit)["treatment"]
base_se <- se(base_fit)["treatment"]

# Restricted residuals under H0: treatment = 0
restricted_fit <- feols(delta_occscore ~ alc_share + treated_state +
                          age_1910 + age_sq + immigrant + black + married + literate +
                          occscore_1910 | region,
                        data = males)
males[, resid_r := residuals(restricted_fit)]
males[, fitted_r := delta_occscore - resid_r]
rm(restricted_fit); gc()

cluster_ids <- unique(males$statefip_1910)

for (b in 1:n_boot) {
  # Rademacher weights by cluster
  weights <- sample(c(-1, 1), length(cluster_ids), replace = TRUE)
  names(weights) <- cluster_ids
  males[, boot_y := fitted_r + resid_r * weights[as.character(statefip_1910)]]

  fit_b <- tryCatch(
    feols(boot_y ~ treatment + alc_share + treated_state +
            age_1910 + age_sq + immigrant + black + married + literate +
            occscore_1910 | region,
          data = males, cluster = ~statefip_1910),
    error = function(e) NULL
  )
  if (!is.null(fit_b)) {
    boot_betas[b] <- coef(fit_b)["treatment"]
    rm(fit_b)
  } else {
    boot_betas[b] <- NA
  }

  if (b %% 100 == 0) {
    gc()
    cat("  Bootstrap", b, "of", n_boot, "\n")
  }
}

boot_betas <- boot_betas[!is.na(boot_betas)]
boot_se <- sd(boot_betas)
boot_pval <- mean(abs(boot_betas) >= abs(true_beta))
cat("Wild cluster bootstrap SE:", round(boot_se, 4), "\n")
cat("Wild cluster bootstrap p-value:", round(boot_pval, 3), "\n")

# Clean up temp columns
males[, c("resid_r", "fitted_r", "boot_y") := NULL]
gc()

# ==============================================================================
# 7. Compile All Robustness Results
# ==============================================================================
rob_results <- data.table(
  check = c("Main (region FE)", "Non-South only", "Bartender share",
            "Bev. manuf. share", "High-exposure interaction",
            "Zero-exposure placebo", "RI p-value",
            "Wild bootstrap SE", "LOO min", "LOO max"),
  beta = c(true_beta, coef(rob_nonsouth)["treatment"],
           bart_beta, bev_beta, disc_beta,
           coef(rob_zero)["treated_state"], NA, NA,
           min(loo_results$beta), max(loo_results$beta)),
  se = c(base_se, se(rob_nonsouth)["treatment"],
         bart_se, bev_se, disc_se,
         se(rob_zero)["treated_state"], NA, boot_se, NA, NA),
  pval = c(NA, NA, NA, NA, NA, NA, ri_pval, boot_pval, NA, NA)
)

fwrite(rob_results, "../data/robustness_results.csv")

# Save key results (not full model objects to save memory)
save(rob_nonsouth, rob_zero, loo_results,
     ri_pval, boot_se, boot_pval, true_beta, base_se,
     bart_beta, bart_se, bev_beta, bev_se, disc_beta, disc_se,
     file = "../data/robustness_objects.RData")

cat("\nAll robustness checks complete.\n")
