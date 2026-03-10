# 04_robustness.R — Robustness checks for Egypt devaluation paper
# APEP-0569: Egypt Devaluation Import Compression

source("00_packages.R")
DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, bec3 := factor(bec3, levels = c("intermediate", "capital", "final"))]
panel[, year := as.integer(year)]
panel[, product_id := as.integer(factor(hs6))]

# Exclude fuels for main sample
panel_nf <- panel[bec_category != "fuels"]

cat("=== Robustness Checks ===\n")

# ============================================================
# R1: Pre-trend test (F-test on pre-period interactions)
# ============================================================
cat("\n--- R1: Pre-trend F-test ---\n")

panel_pre <- panel_nf[year <= 2016]
m_pre <- feols(log_imports ~ i(year, is_intermediate, ref = 2015) +
  i(year, is_capital, ref = 2015) |
  product_id + year,
data = panel_pre, cluster = ~hs2)

# Test joint significance of pre-period interactions
pre_coefs <- coeftable(m_pre)
pre_int <- grep("is_intermediate", rownames(pre_coefs))
pre_cap <- grep("is_capital", rownames(pre_coefs))

cat("Pre-trend coefficients (intermediate vs. final):\n")
print(pre_coefs[pre_int, , drop = FALSE])
cat("\nPre-trend coefficients (capital vs. final):\n")
print(pre_coefs[pre_cap, , drop = FALSE])

# Wald test for joint significance of pre-trends
wald_pre <- wald(m_pre, "is_intermediate")
cat("\nWald test (pre-trend intermediate):\n")
print(wald_pre)

wald_pre_cap <- wald(m_pre, "is_capital")
cat("\nWald test (pre-trend capital):\n")
print(wald_pre_cap)

# ============================================================
# R2: Leave-one-out HS2 chapter
# ============================================================
cat("\n--- R2: Leave-one-out HS2 ---\n")

hs2_chapters <- unique(panel_nf$hs2)
loo_results <- list()

for (ch in hs2_chapters) {
  m_loo <- tryCatch(
    feols(log_imports ~ post:is_intermediate + post:is_capital |
      product_id + year,
    data = panel_nf[hs2 != ch], cluster = ~hs2),
    error = function(e) NULL
  )

  if (!is.null(m_loo)) {
    ct <- coeftable(m_loo)
    loo_results[[ch]] <- data.table(
      dropped_hs2 = ch,
      beta_int = ct["post:is_intermediate", "Estimate"],
      se_int = ct["post:is_intermediate", "Std. Error"],
      beta_cap = ct["post:is_capital", "Estimate"],
      se_cap = ct["post:is_capital", "Std. Error"],
      n_obs = nobs(m_loo)
    )
  }
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, file.path(DATA_DIR, "robustness_loo_hs2.csv"))

cat(sprintf("Leave-one-out: β_intermediate range [%.3f, %.3f]\n",
  min(loo_dt$beta_int), max(loo_dt$beta_int)))
cat(sprintf("Leave-one-out: β_capital range [%.3f, %.3f]\n",
  min(loo_dt$beta_cap), max(loo_dt$beta_cap)))

# ============================================================
# R3: Randomization inference (permute treatment year)
# ============================================================
cat("\n--- R3: Randomization inference ---\n")

set.seed(42)
n_perms <- 200
true_beta_int <- coeftable(feols(log_imports ~ post:is_intermediate + post:is_capital |
  product_id + year,
data = panel_nf, cluster = ~hs2))["post:is_intermediate", "Estimate"]

ri_betas <- numeric(n_perms)
placebo_years <- setdiff(2011:2022, 2016:2017) # exclude actual treatment window

for (i in seq_len(n_perms)) {
  fake_year <- sample(placebo_years, 1)
  panel_nf[, post_fake := as.integer(year >= fake_year)]

  m_ri <- tryCatch(
    feols(log_imports ~ post_fake:is_intermediate + post_fake:is_capital |
      product_id + year,
    data = panel_nf, cluster = ~hs2),
    error = function(e) NULL
  )

  if (!is.null(m_ri)) {
    ri_betas[i] <- coeftable(m_ri)["post_fake:is_intermediate", "Estimate"]
  }
}

panel_nf[, post_fake := NULL]
ri_pvalue <- mean(abs(ri_betas) >= abs(true_beta_int), na.rm = TRUE)
cat(sprintf("RI p-value (intermediate): %.4f (based on %d permutations)\n",
  ri_pvalue, n_perms))

ri_dt <- data.table(permutation = 1:n_perms, beta_int = ri_betas)
ri_dt[, true_beta := true_beta_int]
fwrite(ri_dt, file.path(DATA_DIR, "robustness_ri.csv"))

# ============================================================
# R4: Alternative BEC classification (2-way: intermediate vs. final)
# ============================================================
cat("\n--- R4: Two-way BEC classification ---\n")

# Combine capital with intermediate
panel_nf[, is_industrial := as.integer(bec3 %in% c("intermediate", "capital"))]

m_2way <- feols(log_imports ~ post:is_industrial |
  product_id + year,
data = panel_nf, cluster = ~hs2)

summary(m_2way)
fwrite(data.table(
  classification = "2-way",
  beta_industrial = coeftable(m_2way)["post:is_industrial", "Estimate"],
  se_industrial = coeftable(m_2way)["post:is_industrial", "Std. Error"],
  n_obs = nobs(m_2way)
), file.path(DATA_DIR, "robustness_alt_bec.csv"))

# ============================================================
# R5: Fuels included (full sample)
# ============================================================
cat("\n--- R5: Full sample including fuels ---\n")

m_full <- feols(log_imports ~ post:is_intermediate + post:is_capital +
  post:is_fuels |
  product_id + year,
data = panel, cluster = ~hs2)

summary(m_full)

# ============================================================
# R6: Asinh transformation
# ============================================================
cat("\n--- R6: Asinh transformation ---\n")

m_asinh <- feols(asinh_imports ~ post:is_intermediate + post:is_capital |
  product_id + year,
data = panel_nf, cluster = ~hs2)

summary(m_asinh)

# ============================================================
# R7: Placebo test — pre-period fake treatment (2013)
# ============================================================
cat("\n--- R7: Placebo test (fake treatment 2013) ---\n")

panel_placebo <- panel_nf[year <= 2015]
panel_placebo[, post_placebo := as.integer(year >= 2013)]

m_placebo <- feols(log_imports ~ post_placebo:is_intermediate +
  post_placebo:is_capital |
  product_id + year,
data = panel_placebo, cluster = ~hs2)

summary(m_placebo)

placebo_coefs <- coeftable(m_placebo)
fwrite(data.table(
  test = "Placebo 2013",
  beta_int = placebo_coefs["post_placebo:is_intermediate", "Estimate"],
  se_int = placebo_coefs["post_placebo:is_intermediate", "Std. Error"],
  pval_int = placebo_coefs["post_placebo:is_intermediate", "Pr(>|t|)"],
  beta_cap = placebo_coefs["post_placebo:is_capital", "Estimate"],
  se_cap = placebo_coefs["post_placebo:is_capital", "Std. Error"],
  pval_cap = placebo_coefs["post_placebo:is_capital", "Pr(>|t|)"]
), file.path(DATA_DIR, "robustness_placebo.csv"))

# ============================================================
# R8: Heterogeneity within categories
# ============================================================
cat("\n--- R8: Heterogeneity by HS2 chapter (within intermediate) ---\n")

# Mean log import change pre vs. post by HS2 chapter within intermediate goods
panel_int <- panel_nf[bec3 == "intermediate"]
het_dt <- panel_int[, .(
  mean_pre = mean(log_imports[year <= 2016], na.rm = TRUE),
  mean_post = mean(log_imports[year >= 2017], na.rm = TRUE),
  n_obs = .N
), by = hs2]
het_dt[, change := mean_post - mean_pre]
setorder(het_dt, change)
fwrite(het_dt, file.path(DATA_DIR, "robustness_het_hs2.csv"))

# ============================================================
# Save robustness model objects
# ============================================================
save(m_pre, m_2way, m_full, m_asinh, m_placebo,
  loo_dt, ri_dt,
  file = file.path(DATA_DIR, "robustness_models.RData"))

cat("\n=== All robustness checks complete ===\n")
