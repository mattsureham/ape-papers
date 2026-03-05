# ==============================================================================
# 03_main_analysis.R — Main regressions
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# Load data
dvf <- fread(file.path(data_dir, "dvf_analysis.csv"))
commune <- fread(file.path(data_dir, "commune_panel.csv"))
treat <- fread(file.path(data_dir, "treatment_intensity.csv"))

cat("Data loaded:\n")
cat("  DVF:", nrow(dvf), "commune-years\n")
cat("  Commune panel:", nrow(commune), "rows\n")

# ==============================================================================
# PART A: TAX CAPITALIZATION INTO PROPERTY PRICES
# ==============================================================================

cat("\n=== PART A: Tax Capitalization ===\n")

# --- A1: Main specification (continuous treatment DiD) ---
# log(median price/m²) = α_c + γ_t + β(TH_rate_pre × Post) + ε
# Unit: commune-year. Weighted by number of transactions.

cat("A1: Main continuous-treatment DiD\n")

main_model <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf,
  weights = ~n_total_sales,
  cluster = ~code_insee
)

cat("  Main model estimated.\n")
print(summary(main_model))

# --- A2: Event study (year-by-treatment intensity) ---

cat("\nA2: Event study\n")

es_model <- feols(
  log_price_m2 ~ i(year, th_rate_pre, ref = 2017) | code_insee + year,
  data = dvf,
  weights = ~n_total_sales,
  cluster = ~code_insee
)

cat("  Event study model estimated.\n")
print(summary(es_model))

# --- A3: Quartile-based DiD (more transparent) ---

cat("\nA3: Quartile-based DiD\n")

dvf[, high_th := as.integer(th_quartile == "Q4")]
quartile_model <- feols(
  log_price_m2 ~ high_th:post | code_insee + year,
  data = dvf[th_quartile %in% c("Q1", "Q4")],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  Quartile model (Q4 vs Q1) estimated.\n")
print(summary(quartile_model))

# --- A4: Unweighted specification ---

cat("\nA4: Unweighted specification\n")

unweighted_model <- feols(
  log_price_m2 ~ treat_post | code_insee + year,
  data = dvf,
  cluster = ~code_insee
)
cat("  Unweighted: coef =", coef(unweighted_model)["treat_post"],
    "SE =", se(unweighted_model)["treat_post"], "\n")

# ==============================================================================
# PART B: FISCAL DISPLACEMENT
# ==============================================================================

cat("\n=== PART B: Fiscal Displacement ===\n")

commune_clean <- commune[!is.na(th_share_pre) & !is.na(taux_tfb)]

# --- B1: Main specification ---
cat("B1: TH dependence -> TF rate increase\n")

fiscal_model <- feols(
  taux_tfb ~ th_depend_post | code_insee + year,
  data = commune_clean,
  cluster = ~code_insee
)
cat("  Fiscal displacement model estimated.\n")
print(summary(fiscal_model))

# --- B2: Event study for fiscal displacement ---
cat("\nB2: Fiscal displacement event study\n")

fiscal_es <- feols(
  taux_tfb ~ i(year, th_share_pre, ref = 2017) | code_insee + year,
  data = commune_clean,
  cluster = ~code_insee
)
cat("  Fiscal displacement event study estimated.\n")
print(summary(fiscal_es))

# --- B3: TF rate change as outcome ---
cat("\nB3: TF rate change\n")

fiscal_delta <- feols(
  delta_tfb ~ th_share_pre:post | code_insee + year,
  data = commune_clean[!is.na(delta_tfb)],
  cluster = ~code_insee
)
cat("  Delta TF model estimated.\n")
print(summary(fiscal_delta))

# ==============================================================================
# PART C: NET INCIDENCE
# ==============================================================================

cat("\n=== PART C: Net Incidence ===\n")

# Estimate TF capitalization into prices
cat("C1: TF rate -> property prices\n")

tfb_cap <- feols(
  log_price_m2 ~ taux_tfb_annual | code_insee + year,
  data = dvf[!is.na(taux_tfb_annual)],
  weights = ~n_total_sales,
  cluster = ~code_insee
)
cat("  TF capitalization: coef =", coef(tfb_cap)["taux_tfb_annual"],
    "SE =", se(tfb_cap)["taux_tfb_annual"], "\n")

# Compute back-of-envelope net incidence
beta_A <- coef(main_model)["treat_post"]
beta_B <- coef(fiscal_model)["th_depend_post"]
gamma_TF <- coef(tfb_cap)["taux_tfb_annual"]

avg_th_rate <- mean(dvf$th_rate_pre, na.rm = TRUE)
avg_th_share <- mean(commune_clean$th_share_pre, na.rm = TRUE)

gross_cap <- beta_A * avg_th_rate
tf_offset <- gamma_TF * beta_B * avg_th_share
net_cap <- gross_cap - tf_offset

cat("\nNet incidence calculation:\n")
cat("  Avg TH rate (pre):", round(avg_th_rate, 2), "%\n")
cat("  Avg TH share (pre):", round(avg_th_share, 3), "\n")
cat("  Gross capitalization (Part A):", round(gross_cap, 4), "\n")
cat("  TF offset (Part B x gamma):", round(tf_offset, 4), "\n")
cat("  Net capitalization:", round(net_cap, 4), "\n")
if (gross_cap != 0) {
  cat("  Offset share:", round(tf_offset / gross_cap * 100, 1), "%\n")
}

# ==============================================================================
# SAVE RESULTS
# ==============================================================================

cat("\n=== Saving results ===\n")

results <- list(
  main_model = main_model,
  es_model = es_model,
  quartile_model = quartile_model,
  unweighted_model = unweighted_model,
  fiscal_model = fiscal_model,
  fiscal_es = fiscal_es,
  fiscal_delta = fiscal_delta,
  tfb_cap = tfb_cap
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("Results saved to main_results.rds\n")
