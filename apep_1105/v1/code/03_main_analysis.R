# =============================================================================
# 03_main_analysis.R — Main regressions
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================
source("00_packages.R")

df <- fread("../data/analysis_dataset.csv")
cat(sprintf("Analysis dataset: %d counties, %d states\n", nrow(df), uniqueN(df$state_fips)))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

sumstat_vars <- c("hcp_share", "pills_per_cap", "mat_rate", "methadone_rate",
                  "buprenorphine_rate", "naltrexone_rate", "sud_placebo_rate",
                  "population", "poverty_rate", "pct_black", "pct_hispanic",
                  "median_age")

sumstat <- df[, lapply(.SD, function(x) {
  list(mean = mean(x, na.rm=TRUE),
       sd = sd(x, na.rm=TRUE),
       p25 = quantile(x, 0.25, na.rm=TRUE),
       p50 = quantile(x, 0.50, na.rm=TRUE),
       p75 = quantile(x, 0.75, na.rm=TRUE))
}), .SDcols = sumstat_vars]

# =============================================================================
# Table 2: Balance Test (HCP share vs. controls)
# =============================================================================
cat("\n=== Table 2: Balance Test ===\n")

# Residualize on state FE, then regress controls on HCP share
balance_vars <- c("poverty_rate", "pct_black", "pct_hispanic", "median_age", "log_pop")
balance_results <- list()
for (v in balance_vars) {
  fml <- as.formula(paste(v, "~ hcp_share | state_fips"))
  m <- feols(fml, data = df, vcov = ~state_fips)
  balance_results[[v]] <- list(
    coef = coef(m)["hcp_share"],
    se = sqrt(vcov(m)["hcp_share", "hcp_share"]),
    pval = pvalue(m)["hcp_share"]
  )
  cat(sprintf("  %s ~ hcp_share: β=%.4f (se=%.4f), p=%.3f\n",
              v, balance_results[[v]]$coef, balance_results[[v]]$se, balance_results[[v]]$pval))
}

# F-test for joint significance
joint_fml <- as.formula("hcp_share ~ poverty_rate + pct_black + pct_hispanic + median_age + log_pop | state_fips")
joint_m <- feols(joint_fml, data = df, vcov = ~state_fips)
joint_wald <- wald(joint_m, keep = c("poverty_rate", "pct_black", "pct_hispanic", "median_age", "log_pop"))
cat(sprintf("\nJoint F-test (controls → HCP share | state FE): F=%.2f, p=%.3f\n",
            joint_wald$stat, joint_wald$p))

# =============================================================================
# Table 3: Main Results — MAT Rate on HCP Share
# =============================================================================
cat("\n=== Table 3: Main Results ===\n")

# (1) Bivariate
m1 <- feols(mat_rate ~ hcp_share, data = df, vcov = ~state_fips)

# (2) + State FE
m2 <- feols(mat_rate ~ hcp_share | state_fips, data = df, vcov = ~state_fips)

# (3) + Controls
m3 <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black + pct_hispanic +
              median_age + pills_per_cap | state_fips, data = df, vcov = ~state_fips)

# (4) + Urban indicator
m4 <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black + pct_hispanic +
              median_age + pills_per_cap + urban | state_fips, data = df, vcov = ~state_fips)

# (5) Log outcome
m5 <- feols(log_mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black + pct_hispanic +
              median_age + pills_per_cap + urban | state_fips, data = df, vcov = ~state_fips)

cat("Model 1 (bivariate):\n"); print(summary(m1))
cat("\nModel 2 (+ state FE):\n"); print(summary(m2))
cat("\nModel 3 (+ controls):\n"); print(summary(m3))
cat("\nModel 4 (+ urban):\n"); print(summary(m4))
cat("\nModel 5 (log outcome):\n"); print(summary(m5))

# =============================================================================
# Table 4: Placebo and Mechanism
# =============================================================================
cat("\n=== Table 4: Placebo and Mechanism ===\n")

# (1) Placebo: non-opioid SUD
m_placebo <- feols(sud_placebo_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                     pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                   data = df, vcov = ~state_fips)
cat("Placebo (non-opioid SUD):\n"); print(summary(m_placebo))

# (2) Methadone
m_meth <- feols(methadone_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                  pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                data = df, vcov = ~state_fips)

# (3) Buprenorphine
m_bup <- feols(buprenorphine_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                 pct_hispanic + median_age + pills_per_cap + urban | state_fips,
               data = df, vcov = ~state_fips)

# (4) Naltrexone
m_nalt <- feols(naltrexone_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                  pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                data = df, vcov = ~state_fips)

cat("\nMethadone:\n"); print(summary(m_meth))
cat("\nBuprenorphine:\n"); print(summary(m_bup))
cat("\nNaltrexone:\n"); print(summary(m_nalt))

# =============================================================================
# Save models for table generation
# =============================================================================
save(m1, m2, m3, m4, m5, m_placebo, m_meth, m_bup, m_nalt,
     balance_results, df,
     file = "../data/models.RData")

# =============================================================================
# Write diagnostics.json
# =============================================================================
diag <- list(
  n_treated = nrow(df[hcp_share > median(df$hcp_share)]),
  n_pre = 7L,  # ARCOS years 2006-2012
  n_obs = nrow(df),
  n_states = uniqueN(df$state_fips),
  n_counties = nrow(df),
  mean_hcp_share = round(mean(df$hcp_share), 3),
  sd_hcp_share = round(sd(df$hcp_share), 3),
  main_coef = round(coef(m4)["hcp_share"], 4),
  main_se = round(sqrt(vcov(m4)["hcp_share", "hcp_share"]), 4)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat(sprintf("Key result: MAT rate ~ HCP share (model 4): β=%.4f (se=%.4f)\n",
            diag$main_coef, diag$main_se))
