## 04_robustness.R — Robustness checks
## 1. Randomization inference (permute treatment across states)
## 2. Wild cluster bootstrap
## 3. Exclude California (pre-existing moratorium)
## 4. Placebo test: non-hospice providers (using nonprofit hospice)
## 5. Leave-one-out (drop each treated state)

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "state_quarter_panel.rds"))

valid_states <- c(state.abb, "DC")
panel <- panel[state %in% valid_states]

ppeo_states <- c("AZ", "CA", "NV", "TX")
ppeo_start_yq <- 2023.5

# ============================================================
# 1. Randomization Inference
# Permute treatment assignment across states 1000 times
# Test statistic: DiD coefficient
# ============================================================

cat("=== Randomization Inference ===\n")

set.seed(42)
n_perms <- 1000
n_treated <- 4
all_states <- unique(panel$state)

# True DiD coefficient
true_model <- feols(new_enrollments ~ did | state + year_qtr, data = panel)
true_coef <- coef(true_model)["did"]
cat(sprintf("True DiD coefficient: %.3f\n", true_coef))

perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  # Randomly assign 4 states as treated
  perm_treated <- sample(all_states, n_treated)
  panel[, perm_treat := fifelse(state %in% perm_treated, 1L, 0L)]
  panel[, perm_did := perm_treat * post]

  perm_model <- feols(new_enrollments ~ perm_did | state + year_qtr, data = panel)
  perm_coefs[i] <- coef(perm_model)["perm_did"]
}

# Two-sided p-value: fraction of permutations at least as extreme
ri_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("RI p-value (two-sided, %d permutations): %.4f\n", n_perms, ri_pval))
cat(sprintf("RI p-value (one-sided, negative): %.4f\n", mean(perm_coefs <= true_coef)))

# Save RI distribution
saveRDS(list(true_coef = true_coef, perm_coefs = perm_coefs, ri_pval = ri_pval),
        file.path(data_dir, "ri_results.rds"))

# ============================================================
# 2. Wild Cluster Bootstrap (using boot package)
# Rademacher weights at the state level
# ============================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

set.seed(123)
n_boot <- 999

# Restricted residuals (under H0: did = 0)
m_restricted <- feols(new_enrollments ~ 1 | state + year_qtr, data = panel)
panel[, resid_r := residuals(m_restricted)]

boot_coefs <- numeric(n_boot)
clusters <- unique(panel$state)
n_clusters <- length(clusters)

for (b in seq_len(n_boot)) {
  # Rademacher weights: +1 or -1 for each cluster
  weights <- sample(c(-1, 1), n_clusters, replace = TRUE)
  names(weights) <- clusters

  panel[, boot_y := fitted(m_restricted) + resid_r * weights[state]]

  boot_model <- feols(boot_y ~ did | state + year_qtr, data = panel)
  boot_coefs[b] <- coef(boot_model)["did"]
}

wcb_pval <- mean(abs(boot_coefs) >= abs(true_coef))
cat(sprintf("WCB p-value (two-sided, %d replications): %.4f\n", n_boot, wcb_pval))

# ============================================================
# 3. Exclude California
# CA imposed its own moratorium in January 2022
# ============================================================

cat("\n=== Exclude California ===\n")

panel_no_ca <- panel[state != "CA"]
ppeo_no_ca <- c("AZ", "NV", "TX")
panel_no_ca[, treated_state_noca := fifelse(state %in% ppeo_no_ca, 1L, 0L)]
panel_no_ca[, did_noca := treated_state_noca * post]

m_noca <- feols(new_enrollments ~ did_noca | state + year_qtr, data = panel_no_ca,
                cluster = ~state)
cat("Excluding CA:\n")
print(summary(m_noca))

# Exclude CA entirely + also FL (large state, potential spillover)
panel_no_ca_fl <- panel[!state %in% c("CA", "FL")]
panel_no_ca_fl[, treated_state_noca := fifelse(state %in% ppeo_no_ca, 1L, 0L)]
panel_no_ca_fl[, did_noca := treated_state_noca * post]

m_noca_fl <- feols(new_enrollments ~ did_noca | state + year_qtr, data = panel_no_ca_fl,
                   cluster = ~state)

# ============================================================
# 4. Leave-One-Out: Drop Each Treated State
# ============================================================

cat("\n=== Leave-One-Out ===\n")

loo_results <- data.table(
  dropped = character(),
  estimate = numeric(),
  se = numeric(),
  pval = numeric()
)

for (drop_st in ppeo_states) {
  panel_loo <- panel[state != drop_st]
  remaining_treated <- setdiff(ppeo_states, drop_st)
  panel_loo[, loo_treat := fifelse(state %in% remaining_treated, 1L, 0L)]
  panel_loo[, loo_did := loo_treat * post]

  m_loo <- feols(new_enrollments ~ loo_did | state + year_qtr, data = panel_loo,
                 cluster = ~state)

  loo_results <- rbind(loo_results, data.table(
    dropped = drop_st,
    estimate = coef(m_loo)["loo_did"],
    se = se(m_loo)["loo_did"],
    pval = pvalue(m_loo)["loo_did"]
  ))
}

cat("Leave-one-out results:\n")
print(loo_results)

# ============================================================
# 5. For-Profit Specific + RI
# ============================================================

cat("\n=== For-Profit RI ===\n")

true_fp_model <- feols(new_fp ~ did | state + year_qtr, data = panel)
true_fp_coef <- coef(true_fp_model)["did"]

perm_fp_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  perm_treated <- sample(all_states, n_treated)
  panel[, perm_treat := fifelse(state %in% perm_treated, 1L, 0L)]
  panel[, perm_did := perm_treat * post]
  perm_fp <- feols(new_fp ~ perm_did | state + year_qtr, data = panel)
  perm_fp_coefs[i] <- coef(perm_fp)["perm_did"]
}

ri_fp_pval <- mean(abs(perm_fp_coefs) >= abs(true_fp_coef))
cat(sprintf("For-profit RI p-value: %.4f\n", ri_fp_pval))

# ============================================================
# Save all robustness results
# ============================================================

robust_results <- list(
  ri_pval = ri_pval,
  ri_fp_pval = ri_fp_pval,
  wcb_pval = wcb_pval,
  m_noca = m_noca,
  m_noca_fl = m_noca_fl,
  loo_results = loo_results,
  n_perms = n_perms,
  n_boot = n_boot
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness complete ===\n")
cat(sprintf("  RI p-value (total): %.4f\n", ri_pval))
cat(sprintf("  RI p-value (for-profit): %.4f\n", ri_fp_pval))
cat(sprintf("  WCB p-value: %.4f\n", wcb_pval))
cat(sprintf("  Excl. CA estimate: %.3f (SE: %.3f)\n",
            coef(m_noca)["did_noca"], se(m_noca)["did_noca"]))
