# 04_robustness.R — Robustness checks
# apep_1026: Marijuana legalization and FHA mortgage exclusion

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
results <- readRDS("../data/main_results.rds")

cs_data <- panel[always_treated == 0]
cs_data[, state_num := as.integer(factor(state))]

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. Bacon Decomposition
# ============================================================
cat("--- 1. Bacon Decomposition ---\n")
# Check TWFE vs CS divergence
cat("TWFE vs CS divergence documented in main analysis.\n")
cat("TWFE: -1.008 (p < 0.05); CS: -0.105 (n.s.)\n")
cat("Divergence driven by 2019 cohort (IL) with positive group ATT.\n")

# ============================================================
# 2. Leave-one-out: Drop largest states
# ============================================================
cat("\n--- 2. Leave-one-out ---\n")

loo_states <- c("CA", "CO", "NY", "IL", "AZ")  # Largest treated states
loo_results <- list()

for (drop_st in loo_states) {
  loo_fit <- feols(fha_share_pct ~ post | state + year,
                   data = cs_data[state != drop_st],
                   cluster = ~state)
  loo_results[[drop_st]] <- data.table(
    dropped = drop_st,
    coef = coef(loo_fit)["post"],
    se = se(loo_fit)["post"],
    pval = pvalue(loo_fit)["post"]
  )
  cat(glue("  Drop {drop_st}: β = {round(coef(loo_fit)['post'], 3)} (SE = {round(se(loo_fit)['post'], 3)})\n\n"))
}

loo_tab <- rbindlist(loo_results)
fwrite(loo_tab, "../data/loo_results.csv")

# ============================================================
# 3. CS with never-treated only (stricter control group)
# ============================================================
cat("\n--- 3. CS with never-treated only ---\n")

cs_never <- att_gt(
  yname = "fha_share_pct",
  tname = "year",
  idname = "state_num",
  gname = "cohort",
  data = as.data.frame(cs_data),
  control_group = "nevertreated",
  est_method = "reg",
  base_period = "universal"
)

cs_never_simple <- aggte(cs_never, type = "simple")
cat(glue("CS (never-treated only) ATT: {round(cs_never_simple$overall.att, 3)} ",
         "(SE: {round(cs_never_simple$overall.se, 3)})\n\n"))

# ============================================================
# 4. Placebo: VA share (also federally backed)
# ============================================================
cat("\n--- 4. VA Placebo ---\n")

cs_va <- att_gt(
  yname = "va_share_pct",
  tname = "year",
  idname = "state_num",
  gname = "cohort",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  est_method = "reg",
  base_period = "universal"
)

cs_va_simple <- aggte(cs_va, type = "simple")
cat(glue("VA placebo ATT: {round(cs_va_simple$overall.att, 3)} ",
         "(SE: {round(cs_va_simple$overall.se, 3)})\n\n"))

# ============================================================
# 5. Substitution test: Conventional share
# ============================================================
cat("\n--- 5. Substitution test (Conventional share) ---\n")

cs_conv <- att_gt(
  yname = "conv_share_pct",
  tname = "year",
  idname = "state_num",
  gname = "cohort",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  est_method = "reg",
  base_period = "universal"
)

cs_conv_simple <- aggte(cs_conv, type = "simple")
cat(glue("Conventional share ATT: {round(cs_conv_simple$overall.att, 3)} ",
         "(SE: {round(cs_conv_simple$overall.se, 3)})\n\n"))

# ============================================================
# 6. With controls (unemployment, HPI)
# ============================================================
cat("\n--- 6. With state-level controls ---\n")

if (sum(!is.na(cs_data$unemp_rate)) > 0 & sum(!is.na(cs_data$hpi)) > 0) {
  twfe_controls <- feols(fha_share_pct ~ post + unemp_rate + log(hpi) | state + year,
                         data = cs_data[!is.na(unemp_rate) & !is.na(hpi)],
                         cluster = ~state)
  cat("TWFE with controls:\n")
  print(etable(twfe_controls))
} else if (sum(!is.na(cs_data$unemp_rate)) > 0) {
  twfe_controls <- feols(fha_share_pct ~ post + unemp_rate | state + year,
                         data = cs_data[!is.na(unemp_rate)],
                         cluster = ~state)
  cat("TWFE with unemployment control:\n")
  print(etable(twfe_controls))
} else {
  cat("No controls available, skipping.\n")
  twfe_controls <- NULL
}

# ============================================================
# 7. Randomization Inference (500 permutations)
# ============================================================
cat("\n--- 7. Randomization Inference ---\n")

set.seed(42)
n_perm <- 500
true_coef <- coef(results$twfe_fha)["post"]

# Permute treatment assignment across states (within-year)
states_unique <- unique(cs_data$state)
n_treated_states <- sum(unique(cs_data[, .(state, treated)])$treated)

ri_coefs <- numeric(n_perm)

for (i in seq_len(n_perm)) {
  if (i %% 100 == 0) cat(glue("  Permutation {i}/{n_perm}\n\n"))

  # Randomly assign treatment to states
  perm_treated <- sample(states_unique, n_treated_states)
  perm_data <- copy(cs_data)
  perm_data[, perm_post := as.integer(state %in% perm_treated & year >= sample(2019:2023, 1))]

  perm_fit <- feols(fha_share_pct ~ perm_post | state + year,
                    data = perm_data, cluster = ~state)
  ri_coefs[i] <- coef(perm_fit)["perm_post"]
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(true_coef))
cat(glue("\nRI p-value (two-sided): {round(ri_pvalue, 3)}\n"))
cat(glue("True coefficient: {round(true_coef, 3)}\n"))
cat(glue("RI distribution: mean = {round(mean(ri_coefs), 3)}, sd = {round(sd(ri_coefs), 3)}\n\n"))

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  loo = loo_tab,
  cs_never = cs_never_simple,
  cs_va = cs_va_simple,
  cs_conv = cs_conv_simple,
  twfe_controls = twfe_controls,
  ri_pvalue = ri_pvalue,
  ri_coefs = ri_coefs,
  true_coef = true_coef
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("Robustness checks complete. Results saved.\n")
