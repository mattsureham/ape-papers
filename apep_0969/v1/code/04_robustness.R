# 04_robustness.R — Robustness checks and event study diagnostics
# Paper: The Compliance Cliff (apep_0969)

source("00_packages.R")

load("../data/models.RData")
panel[, ym := as.Date(ym)]
panel[, industry_code := sprintf("%02d", as.integer(industry_code))]

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. EVENT STUDY — Fix coefficient extraction
# ============================================================================
cat("\n--- 1. Event Study (fixed extraction) ---\n")

# Re-run event study with explicit extraction
panel[, rel_month_b := pmax(pmin(rel_month, 21), -36)]

m_es <- feols(hours ~ i(rel_month_b, exempt, ref = -1) | industry_code + ym,
              data = panel, cluster = ~industry_code)

# Use fixest's coeftable for proper extraction
ct <- coeftable(m_es)
es_df <- data.table(
  coef_name = rownames(ct),
  coef = ct[, "Estimate"],
  se = ct[, "Std. Error"]
)

# Parse: names are like "rel_month_b::-36:exempt"
es_df[, rel_month := as.integer(gsub("rel_month_b::([-0-9]+):exempt", "\\1", coef_name))]
es_df <- es_df[!is.na(rel_month)]
es_df[, ci_lo := coef - 1.96 * se]
es_df[, ci_hi := coef + 1.96 * se]
es_df <- es_df[order(rel_month)]

# Add the reference period
ref_row <- data.table(coef_name = "ref", coef = 0, se = 0,
                      rel_month = -1, ci_lo = 0, ci_hi = 0)
es_df <- rbind(es_df, ref_row)
es_df <- es_df[order(rel_month)]

fwrite(es_df, "../data/event_study_coefs.csv")

cat("Pre-treatment coefficients (rel_month -24 to -2):\n")
pre <- es_df[rel_month >= -24 & rel_month < -1]
if (nrow(pre) > 0) {
  cat(sprintf("  N: %d, Mean: %.2f, SD: %.2f, Max |coef|: %.2f\n",
              nrow(pre), mean(pre$coef), sd(pre$coef), max(abs(pre$coef))))
  # Joint F-test for pre-trends
  cat("  Pre-treatment coefficients:\n")
  for (i in seq_len(min(10, nrow(pre)))) {
    cat(sprintf("    t=%d: %.2f (%.2f)\n", pre$rel_month[i], pre$coef[i], pre$se[i]))
  }
}

cat("\nPost-treatment coefficients (rel_month 0 to 21):\n")
post <- es_df[rel_month >= 0]
if (nrow(post) > 0) {
  cat(sprintf("  N: %d, Mean: %.2f, SD: %.2f\n",
              nrow(post), mean(post$coef), sd(post$coef)))
  for (i in seq_len(min(12, nrow(post)))) {
    cat(sprintf("    t=%d: %.2f (%.2f)\n", post$rel_month[i], post$coef[i], post$se[i]))
  }
}

# ============================================================================
# 2. RANDOMIZATION INFERENCE
# ============================================================================
cat("\n--- 2. Randomization Inference ---\n")

actual_coef <- coef(m1)["exempt:post"]
cat(sprintf("Actual DiD coefficient: %.3f\n", actual_coef))

set.seed(42)
industries <- unique(panel$industry_code)
n_industries <- length(industries)
n_exempt <- sum(industries %in% c("09", "42", "78"))
n_perms <- 2000

perm_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  fake_treated <- sample(industries, n_exempt)
  panel[, fake_exempt := as.integer(industry_code %in% fake_treated)]

  m_perm <- tryCatch(
    feols(hours ~ fake_exempt:post | industry_code + ym,
          data = panel, cluster = ~industry_code),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["fake_exempt:post"]
  } else {
    perm_coefs[i] <- NA
  }
}
panel[, fake_exempt := NULL]

perm_valid <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_valid) >= abs(actual_coef))
cat(sprintf("RI p-value (2000 permutations): %.4f\n", ri_pvalue))
cat(sprintf("Permutation dist: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
            mean(perm_valid), sd(perm_valid), min(perm_valid), max(perm_valid)))

# ============================================================================
# 3. EXCLUDE COVID PERIOD (2022+)
# ============================================================================
cat("\n--- 3. Excluding COVID Period ---\n")
panel_nocovid <- panel[ym >= as.Date("2022-01-01")]
m_nocovid <- feols(hours ~ exempt:post | industry_code + ym,
                   data = panel_nocovid, cluster = ~industry_code)
summary(m_nocovid)

# ============================================================================
# 4. PLACEBO TEST: Fake treatment April 2022
# ============================================================================
cat("\n--- 4. Placebo Test: April 2022 ---\n")
panel_pre <- panel[ym < as.Date("2024-04-01")]
panel_pre[, fake_post := as.integer(ym >= as.Date("2022-04-01"))]
m_placebo <- feols(hours ~ exempt:fake_post | industry_code + ym,
                   data = panel_pre, cluster = ~industry_code)
summary(m_placebo)

# ============================================================================
# 5. PLACEBO TEST: Fake treatment April 2021
# ============================================================================
cat("\n--- 5. Placebo Test: April 2021 ---\n")
panel_pre[, fake_post2 := as.integer(ym >= as.Date("2021-04-01"))]
m_placebo2 <- feols(hours ~ exempt:fake_post2 | industry_code + ym,
                    data = panel_pre, cluster = ~industry_code)
summary(m_placebo2)

# ============================================================================
# 6. ANTICIPATION TEST (last 6 months before treatment)
# ============================================================================
cat("\n--- 6. Anticipation Test ---\n")
panel_antic <- panel[ym >= as.Date("2023-01-01") & ym < as.Date("2024-04-01")]
panel_antic[, antic_post := as.integer(ym >= as.Date("2024-01-01"))]
m_antic <- feols(hours ~ exempt:antic_post | industry_code + ym,
                 data = panel_antic, cluster = ~industry_code)
summary(m_antic)

# ============================================================================
# 7. BY EXEMPT INDUSTRY
# ============================================================================
cat("\n--- 7. Effects by Exempt Industry ---\n")

# For individual industry effects, compare each exempt industry against
# the mean of control industries using a simple DD calculation
for (ind_code in c("09", "42", "78")) {
  ind_name <- unique(panel[industry_code == ind_code, industry_name])

  # Simple DiD: (Y_treat_post - Y_treat_pre) - (Y_control_post - Y_control_pre)
  treat_pre <- mean(panel[industry_code == ind_code & post == 0, hours], na.rm = TRUE)
  treat_post <- mean(panel[industry_code == ind_code & post == 1, hours], na.rm = TRUE)
  ctrl_pre <- mean(panel[exempt == 0 & post == 0, hours], na.rm = TRUE)
  ctrl_post <- mean(panel[exempt == 0 & post == 1, hours], na.rm = TRUE)
  did_est <- (treat_post - treat_pre) - (ctrl_post - ctrl_pre)

  cat(sprintf("\n%s (%s):\n", ind_name, ind_code))
  cat(sprintf("  Treat: pre=%.1f, post=%.1f, diff=%.1f\n",
              treat_pre, treat_post, treat_post - treat_pre))
  cat(sprintf("  Control: pre=%.1f, post=%.1f, diff=%.1f\n",
              ctrl_pre, ctrl_post, ctrl_post - ctrl_pre))
  cat(sprintf("  DiD estimate: %.2f hours\n", did_est))
}

# ============================================================================
# 8. MDE CALCULATION (for powered null)
# ============================================================================
cat("\n--- 8. Minimum Detectable Effect ---\n")
se_main <- sqrt(diag(vcov(m1)))["exempt:post"]
mde_05 <- 2.8 * se_main  # MDE at 80% power, alpha=0.05
mde_10 <- 2.5 * se_main  # MDE at 80% power, alpha=0.10
sd_y <- sd(panel[post == 0 & exempt == 1, hours], na.rm = TRUE)
mean_y <- mean(panel[post == 0 & exempt == 1, hours], na.rm = TRUE)

cat(sprintf("SE of DiD estimate: %.3f\n", se_main))
cat(sprintf("MDE (alpha=0.05, power=80%%): %.2f hours (%.1f%% of exempt mean)\n",
            mde_05, 100 * mde_05 / mean_y))
cat(sprintf("MDE (alpha=0.10, power=80%%): %.2f hours (%.1f%% of exempt mean)\n",
            mde_10, 100 * mde_10 / mean_y))
cat(sprintf("Pre-treatment exempt mean hours: %.1f (SD=%.1f)\n", mean_y, sd_y))

# ============================================================================
# SAVE
# ============================================================================
save(m_nocovid, m_placebo, m_placebo2, m_antic, ri_pvalue, perm_valid, es_df,
     file = "../data/robustness.RData")
cat("\nAll robustness checks complete.\n")
