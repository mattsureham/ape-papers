## ============================================================
## 04_robustness.R — Robustness checks and diagnostics
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Panel:", nrow(panel), "obs ===\n")

# ============================================================
# R1: Rambachan-Roth Pre-Trend Sensitivity
# ============================================================

cat("\n=== R1: Rambachan-Roth Sensitivity ===\n")

# Prepare for HonestDiD
# First run CS-DiD to get group-time ATTs
did_data <- panel %>%
  filter(!is.na(drug_death_rate)) %>%
  mutate(state_id = as.numeric(factor(state_abbr)))

cs_drug <- tryCatch({
  att_gt(
    yname = "drug_death_rate",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = did_data,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("  CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_drug)) {
  es_drug <- aggte(cs_drug, type = "dynamic", min_e = -5, max_e = 5)

  # HonestDiD sensitivity analysis
  honest_result <- if (requireNamespace("HonestDiD", quietly = TRUE)) {
    tryCatch({
      HonestDiD::honest_did(es_drug, type = "relative_magnitude")
    }, error = function(e) {
      cat("  HonestDiD error:", e$message, "\n")
      NULL
    })
  } else {
    cat("  HonestDiD package not available. Skipping.\n")
    NULL
  }

  if (!is.null(honest_result)) {
    cat("  HonestDiD results:\n")
    cat("  Original CI: [", round(honest_result$robust_ci[1], 3), ",",
        round(honest_result$robust_ci[2], 3), "]\n")

    # Save HonestDiD results
    honest_df <- data.frame(
      Mbar = honest_result$Mbar,
      lb = honest_result$robust_ci[1],
      ub = honest_result$robust_ci[2]
    )
    fwrite(honest_df, file.path(data_dir, "honestdid_results.csv"))
  }
}

# ============================================================
# R2: Randomization Inference
# ============================================================

cat("\n=== R2: Randomization Inference ===\n")

# Permute reform timing across states
set.seed(580)
n_perms <- 500

# Main TWFE estimate for comparison
twfe_drug <- feols(
  drug_death_rate ~ treated | state_abbr + year,
  data = panel,
  cluster = ~state_abbr
)
actual_coef <- coef(twfe_drug)["treatedTRUE"]

cat("  Actual TWFE coefficient:", round(actual_coef, 4), "\n")
cat("  Running", n_perms, "permutations...\n")

# Get reform years and permute
reform_states <- panel %>%
  filter(ever_reformed) %>%
  distinct(state_abbr, reform_year, reform_type)

perm_coefs <- numeric(n_perms)
all_states <- unique(panel$state_abbr)

for (i in 1:n_perms) {
  # Randomly assign reform years to states
  perm_years <- sample(c(reform_states$reform_year, rep(0, length(all_states) - nrow(reform_states))))

  perm_panel <- panel %>%
    mutate(
      perm_reform = perm_years[match(state_abbr, all_states)],
      perm_treated = perm_reform > 0 & year >= perm_reform
    )

  perm_fit <- tryCatch({
    feols(drug_death_rate ~ perm_treated | state_abbr + year,
          data = perm_panel, cluster = ~state_abbr)
  }, error = function(e) NULL)

  if (!is.null(perm_fit)) {
    perm_coefs[i] <- coef(perm_fit)["perm_treatedTRUE"]
  }
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("  RI p-value:", round(ri_pvalue, 4), "\n")
cat("  RI 95th percentile:", round(quantile(perm_coefs, 0.975, na.rm=TRUE), 4), "\n")

ri_df <- data.frame(
  actual = actual_coef,
  ri_pvalue = ri_pvalue,
  ri_5th = quantile(perm_coefs, 0.025, na.rm=TRUE),
  ri_95th = quantile(perm_coefs, 0.975, na.rm=TRUE),
  perm_mean = mean(perm_coefs, na.rm=TRUE),
  perm_sd = sd(perm_coefs, na.rm=TRUE)
)
fwrite(ri_df, file.path(data_dir, "ri_results.csv"))

# Save permutation distribution
fwrite(data.frame(perm_coef = perm_coefs), file.path(data_dir, "ri_distribution.csv"))

# ============================================================
# R3: Placebo Outcomes
# ============================================================

cat("\n=== R3: Placebo Tests ===\n")

# Placebo: Use pre-treatment window only (2004-2013)
# Artificially assign "treatment" at 2009 (midpoint)
placebo_data <- panel %>%
  filter(year <= 2013) %>%
  mutate(
    fake_treated = ever_reformed & year >= 2009
  )

placebo_fit <- feols(
  drug_death_rate ~ fake_treated | state_abbr + year,
  data = placebo_data,
  cluster = ~state_abbr
)

cat("  Placebo (pre-period only, fake treatment 2009):\n")
cat("    Coef =", round(coef(placebo_fit)["fake_treatedTRUE"], 3), "\n")
cat("    SE   =", round(sqrt(vcov(placebo_fit)["fake_treatedTRUE","fake_treatedTRUE"]), 3), "\n")
cat("    p    =", round(2*pnorm(-abs(coef(placebo_fit)["fake_treatedTRUE"] /
    sqrt(vcov(placebo_fit)["fake_treatedTRUE","fake_treatedTRUE"]))), 4), "\n")

# ============================================================
# R4: Leave-One-State-Out Jackknife
# ============================================================

cat("\n=== R4: Jackknife ===\n")

jackknife_coefs <- numeric(51)
names(jackknife_coefs) <- unique(panel$state_abbr)

for (st in unique(panel$state_abbr)) {
  jack_data <- panel %>% filter(state_abbr != st)
  jack_fit <- tryCatch({
    feols(drug_death_rate ~ treated | state_abbr + year,
          data = jack_data, cluster = ~state_abbr)
  }, error = function(e) NULL)

  if (!is.null(jack_fit)) {
    jackknife_coefs[st] <- coef(jack_fit)["treatedTRUE"]
  }
}

jack_df <- data.frame(
  dropped_state = names(jackknife_coefs),
  coef = jackknife_coefs
) %>%
  mutate(
    deviation = coef - actual_coef,
    influential = abs(deviation) > 2 * sd(jackknife_coefs, na.rm = TRUE)
  )

cat("  Jackknife range: [", round(min(jackknife_coefs, na.rm=TRUE), 3), ",",
    round(max(jackknife_coefs, na.rm=TRUE), 3), "]\n")
cat("  Influential states:", paste(jack_df$dropped_state[jack_df$influential], collapse=", "), "\n")

fwrite(jack_df, file.path(data_dir, "jackknife_results.csv"))

# ============================================================
# R5: Alternative Control Groups
# ============================================================

cat("\n=== R5: Alternative Control Groups ===\n")

# Not-yet-treated control group
cs_nyt <- tryCatch({
  att_gt(
    yname = "drug_death_rate",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = did_data,
    control_group = "notyettreated",
    base_period = "universal"
  )
}, error = function(e) NULL)

if (!is.null(cs_nyt)) {
  agg_nyt <- aggte(cs_nyt, type = "simple")
  cat("  Not-yet-treated ATT =", round(agg_nyt$overall.att, 3),
      "(SE =", round(agg_nyt$overall.se, 3), ")\n")
}

# ============================================================
# R6: Log Outcomes
# ============================================================

cat("\n=== R6: Log Specification ===\n")

twfe_log <- feols(
  log_drug_death_rate ~ treated | state_abbr + year,
  data = panel %>% filter(!is.na(log_drug_death_rate)),
  cluster = ~state_abbr
)

cat("  Log drug death rate TWFE:\n")
cat("    Coef =", round(coef(twfe_log)["treatedTRUE"], 4),
    "(", round(100*(exp(coef(twfe_log)["treatedTRUE"])-1), 1), "% change)\n")
cat("    SE   =", round(sqrt(vcov(twfe_log)["treatedTRUE","treatedTRUE"]), 4), "\n")

# ============================================================
# R7: Wild Cluster Bootstrap
# ============================================================

cat("\n=== R7: Wild Cluster Bootstrap ===\n")

boot_result <- if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  tryCatch({
    fwildclusterboot::boottest(twfe_drug, param = "treatedTRUE", B = 999,
             clustid = "state_abbr", type = "webb")
  }, error = function(e) {
    cat("  Bootstrap error:", e$message, "\n")
    NULL
  })
} else {
  cat("  fwildclusterboot package not available. Skipping.\n")
  NULL
}

if (!is.null(boot_result)) {
  cat("  Wild cluster bootstrap p-value:", round(pval(boot_result), 4), "\n")
  cat("  Bootstrap CI:", round(confint(boot_result), 3), "\n")
}

# ============================================================
# Save Robustness Summary
# ============================================================

cat("\n=== Saving robustness summary ===\n")

robustness_summary <- data.frame(
  spec = c("Main CS-DiD (never-treated)",
           "CS-DiD (not-yet-treated)",
           "TWFE",
           "Log TWFE",
           "Placebo (pre-period)",
           "RI p-value"),
  estimate = c(
    ifelse(!is.null(cs_drug), round(aggte(cs_drug, type="simple")$overall.att, 3), NA),
    ifelse(!is.null(cs_nyt), round(agg_nyt$overall.att, 3), NA),
    round(coef(twfe_drug)["treatedTRUE"], 3),
    round(coef(twfe_log)["treatedTRUE"], 3),
    round(coef(placebo_fit)["fake_treatedTRUE"], 3),
    round(ri_pvalue, 3)
  ),
  se = c(
    ifelse(!is.null(cs_drug), round(aggte(cs_drug, type="simple")$overall.se, 3), NA),
    ifelse(!is.null(cs_nyt), round(agg_nyt$overall.se, 3), NA),
    round(sqrt(vcov(twfe_drug)["treatedTRUE","treatedTRUE"]), 3),
    round(sqrt(vcov(twfe_log)["treatedTRUE","treatedTRUE"]), 3),
    round(sqrt(vcov(placebo_fit)["fake_treatedTRUE","fake_treatedTRUE"]), 3),
    NA
  )
)

print(robustness_summary)
fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
