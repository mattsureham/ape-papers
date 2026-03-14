## 04_robustness.R — Robustness checks for EUDR DDD

source("code/00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n")

panel <- fread("data/panel.csv")
shares <- fread("data/eu_shares.csv")

# ── 1. Leave-one-out commodity ─────────────────────────────────────
cat("\n--- Leave-one-out commodity sensitivity ---\n")

regulated_codes <- c("0102", "0901", "1201", "1511", "1801", "4001", "4403")
loo_results <- list()

for (drop_hs in regulated_codes) {
  panel_loo <- panel[hs4 != drop_hs]
  m_loo <- feols(ln_value ~ ddd_proposal |
                   cmd_dest + cmd_year + dest_year + reporter_code,
                 data = panel_loo,
                 cluster = ~hs4 + dest_group)
  loo_results[[drop_hs]] <- data.table(
    dropped_commodity = drop_hs,
    coef = coef(m_loo)["ddd_proposal"],
    se = sqrt(vcov(m_loo)["ddd_proposal", "ddd_proposal"]),
    nobs = nobs(m_loo)
  )
  cat(sprintf("  Drop %s: β = %.3f (SE = %.3f)\n", drop_hs,
              coef(m_loo)["ddd_proposal"],
              sqrt(vcov(m_loo)["ddd_proposal", "ddd_proposal"])))
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, "data/loo_results.csv")

# ── 2. Placebo: Non-regulated commodities only ────────────────────
cat("\n--- Placebo: control commodities only ---\n")

control_codes <- c("0902", "0904", "1513", "2009", "2401")
panel_ctrl <- panel[hs4 %in% control_codes]

# Randomly assign "placebo regulated" to first 3 controls
panel_ctrl[, placebo_reg := as.integer(hs4 %in% control_codes[1:3])]
panel_ctrl[, placebo_ddd := placebo_reg * eu_dest * post_proposal]

m_placebo <- feols(ln_value ~ placebo_ddd |
                     cmd_dest + cmd_year + dest_year + reporter_code,
                   data = panel_ctrl,
                   cluster = ~hs4 + dest_group)
cat("Placebo DDD (should be null):\n")
summary(m_placebo)

# ── 3. Exporter heterogeneity: Standard-risk vs Low-risk ──────────
cat("\n--- Exporter heterogeneity ---\n")

# Standard-risk exporters (Brazil, Indonesia, Colombia, Côte d'Ivoire, Ghana)
standard_risk <- c(76, 360, 170, 384, 288)
panel[, standard_risk := as.integer(reporter_code %in% standard_risk)]

m_high <- feols(ln_value ~ ddd_proposal |
                  cmd_dest + cmd_year + dest_year + reporter_code,
                data = panel[standard_risk == 1],
                cluster = ~hs4 + dest_group)

m_low <- feols(ln_value ~ ddd_proposal |
                 cmd_dest + cmd_year + dest_year + reporter_code,
               data = panel[standard_risk == 0],
               cluster = ~hs4 + dest_group)

cat(sprintf("Standard-risk exporters: β = %.3f (SE = %.3f)\n",
            coef(m_high)["ddd_proposal"],
            sqrt(vcov(m_high)["ddd_proposal", "ddd_proposal"])))
cat(sprintf("Other exporters: β = %.3f (SE = %.3f)\n",
            coef(m_low)["ddd_proposal"],
            sqrt(vcov(m_low)["ddd_proposal", "ddd_proposal"])))

# ── 4. Permutation test ───────────────────────────────────────────
cat("\n--- Permutation test (commodity reassignment, 200 iterations) ---\n")

set.seed(42)
all_hs <- unique(panel$hs4)
n_reg <- sum(unique(panel$hs4) %in% c("0102", "0901", "1201", "1511", "1801", "4001", "4403"))
n_perms <- 200

actual_coef <- coef(feols(ln_value ~ ddd_proposal |
                            cmd_dest + cmd_year + dest_year + reporter_code,
                          data = panel))["ddd_proposal"]

perm_coefs <- numeric(n_perms)
for (i in 1:n_perms) {
  perm_regulated <- sample(all_hs, n_reg)
  panel_perm <- copy(panel)
  panel_perm[, perm_reg := as.integer(hs4 %in% perm_regulated)]
  panel_perm[, perm_ddd := perm_reg * eu_dest * post_proposal]

  m_perm <- tryCatch(
    feols(ln_value ~ perm_ddd |
            cmd_dest + cmd_year + dest_year + reporter_code,
          data = panel_perm),
    error = function(e) NULL
  )

  if (!is.null(m_perm) && "perm_ddd" %in% names(coef(m_perm))) {
    perm_coefs[i] <- coef(m_perm)["perm_ddd"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pval <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Randomization inference p-value: %.3f (based on %d valid permutations)\n",
            ri_pval, length(perm_coefs)))

# ── 5. Alternative post-period: passage (2023+) instead of proposal
cat("\n--- Alternative timing: passage (2023+) ---\n")

m_alt <- feols(ln_value ~ ddd_passage |
                 cmd_dest + cmd_year + dest_year + reporter_code,
               data = panel,
               cluster = ~hs4 + dest_group)
cat(sprintf("DDD (passage): β = %.3f (SE = %.3f)\n",
            coef(m_alt)["ddd_passage"],
            sqrt(vcov(m_alt)["ddd_passage", "ddd_passage"])))

# ── Save robustness results ────────────────────────────────────────
rob <- list(
  loo = loo_dt,
  placebo_coef = coef(m_placebo),
  placebo_se = sqrt(diag(vcov(m_placebo))),
  standard_risk_coef = coef(m_high)["ddd_proposal"],
  other_risk_coef = coef(m_low)["ddd_proposal"],
  ri_pval = ri_pval,
  passage_coef = coef(m_alt)["ddd_passage"]
)
saveRDS(rob, "data/robustness_results.rds")
saveRDS(list(m_placebo = m_placebo, m_high = m_high, m_low = m_low,
             m_alt = m_alt, perm_coefs = perm_coefs, actual_coef = actual_coef),
        "data/robustness_models.rds")

cat("\nRobustness checks complete. Saved to data/robustness_results.rds\n")
