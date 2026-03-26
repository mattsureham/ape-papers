## 04_robustness.R — Robustness checks and placebo tests
## apep_0993: South Korea 52-Hour Workweek Reform

source("00_packages.R")

cat("=== Robustness Checks: apep_0993 ===\n")

korea <- fread("../data/korea_panel.csv")

# ─────────────────────────────────────────────────────────
# 1. Unweighted specification
# ─────────────────────────────────────────────────────────

cat("1. Unweighted DiD...\n")

m_unw <- feols(hours ~ binding:post | industry + year,
               data = korea, cluster = ~industry)
cat("  Unweighted β:", round(coef(m_unw), 3), "\n")

# ─────────────────────────────────────────────────────────
# 2. Industry-specific trends
# ─────────────────────────────────────────────────────────

cat("2. Industry-specific linear trends...\n")

korea[, industry_num := as.integer(factor(industry))]
korea[, trend := year - 2010]

m_trends <- feols(hours ~ binding:post + i(industry_num, trend) | industry + year,
                  data = korea, weights = ~emp_weight,
                  cluster = ~industry)
cat("  With trends β:", round(coef(m_trends)["binding:post"], 3), "\n")

# ─────────────────────────────────────────────────────────
# 3. Placebo treatment years (pre-reform)
# ─────────────────────────────────────────────────────────

cat("3. Placebo treatment in 2015...\n")

korea_pre <- korea[year <= 2017]
korea_pre[, placebo_post := as.integer(year >= 2015)]

m_placebo <- feols(hours ~ binding:placebo_post | industry + year,
                   data = korea_pre, weights = ~emp_weight,
                   cluster = ~industry)
cat("  Placebo 2015 β:", round(coef(m_placebo), 3),
    " (p =", round(pvalue(m_placebo), 3), ")\n")

# ─────────────────────────────────────────────────────────
# 4. Alternative threshold: 45 hours instead of 52
# ─────────────────────────────────────────────────────────

cat("4. Alternative threshold (45 hours)...\n")

korea[, binding_45 := as.integer(baseline_hours > 45)]

m_alt <- feols(hours ~ binding_45:post | industry + year,
               data = korea, weights = ~emp_weight,
               cluster = ~industry)
cat("  Alt threshold (45h) β:", round(coef(m_alt), 3), "\n")

# ─────────────────────────────────────────────────────────
# 5. Leave-one-out: Drop each binding industry
# ─────────────────────────────────────────────────────────

cat("5. Leave-one-out sensitivity...\n")

binding_inds <- unique(korea[binding == 1, industry])
loo_results <- data.table()

for (ind in binding_inds) {
  k_sub <- korea[industry != ind]
  m_loo <- feols(hours ~ binding:post | industry + year,
                 data = k_sub, weights = ~emp_weight,
                 cluster = ~industry)
  loo_results <- rbind(loo_results, data.table(
    dropped = ind,
    beta = coef(m_loo),
    se = se(m_loo),
    pval = pvalue(m_loo)
  ))
}
cat("  LOO range: [", round(min(loo_results$beta), 3), ",",
    round(max(loo_results$beta), 3), "]\n")
print(loo_results[, .(dropped, beta = round(beta, 3), se = round(se, 3))])

# ─────────────────────────────────────────────────────────
# 6. COVID robustness: Exclude 2020
# ─────────────────────────────────────────────────────────

cat("6. Excluding 2020 (COVID year)...\n")

m_no2020 <- feols(hours ~ binding:post | industry + year,
                  data = korea[year != 2020],
                  weights = ~emp_weight, cluster = ~industry)
cat("  Without 2020 β:", round(coef(m_no2020), 3), "\n")

# ─────────────────────────────────────────────────────────
# 7. Randomization inference (permutation test)
# ─────────────────────────────────────────────────────────

cat("7. Randomization inference...\n")

set.seed(42)
actual_beta <- coef(m1<- feols(hours ~ binding:post | industry + year,
                                data = korea, weights = ~emp_weight,
                                cluster = ~industry))

n_perms <- 1000
perm_betas <- numeric(n_perms)
industries <- unique(korea$industry)
n_treated <- sum(unique(korea[, .(industry, binding)])$binding)

for (i in seq_len(n_perms)) {
  fake_treated <- sample(industries, n_treated)
  korea[, fake_binding := as.integer(industry %in% fake_treated)]
  m_perm <- feols(hours ~ fake_binding:post | industry + year,
                  data = korea, weights = ~emp_weight,
                  cluster = ~industry)
  perm_betas[i] <- coef(m_perm)
}

ri_pvalue <- mean(abs(perm_betas) >= abs(actual_beta))
cat("  RI p-value (1000 permutations):", round(ri_pvalue, 3), "\n")

# ─────────────────────────────────────────────────────────
# Save robustness results
# ─────────────────────────────────────────────────────────

save(m_unw, m_trends, m_placebo, m_alt, loo_results, m_no2020,
     ri_pvalue, perm_betas, actual_beta,
     file = "../data/robustness_results.RData")

cat("\n=== Robustness checks complete ===\n")
