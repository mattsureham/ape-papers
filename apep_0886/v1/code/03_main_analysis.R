# =============================================================================
# 03_main_analysis.R — DDD Regressions
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat("=== Main Analysis: DDD Specification ===\n\n")

# ---- Specification 1: Basic DDD (Post × Female × Childcare) ---- #
# Comparing childcare (624) vs manufacturing (311, 332)
# Using female vs male as within-industry control

df_main <- panel %>%
  filter(industry_code %in% c("624", "311", "332"))

cat("Main sample: childcare (624) vs manufacturing (311, 332)\n")
cat("Observations:", nrow(df_main), "\n\n")

# DDD with fixest
# Y = log(emp)
# FE: cell_id (state×industry×sex), industry×quarter, state×quarter
m1 <- feols(
  log_emp ~ ddd + post_female + post_childcare + female_childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_main,
  cluster = ~state_fips
)

cat("Model 1: Basic DDD (log employment)\n")
summary(m1)

# ---- Specification 2: Earnings DDD ---- #
m2 <- feols(
  earn ~ ddd + post_female + post_childcare + female_childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_main,
  cluster = ~state_fips
)

cat("\nModel 2: Earnings DDD\n")
summary(m2)

# ---- Specification 3: Hires DDD ---- #
m3 <- feols(
  log_hires ~ ddd + post_female + post_childcare + female_childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_main,
  cluster = ~state_fips
)

cat("\nModel 3: Hires DDD\n")
summary(m3)

# ---- Specification 4: Dose-Response DDD (allocation per capita) ---- #
# Continuous treatment: how much more did high-allocation states respond?
m4 <- feols(
  log_emp ~ dose_ddd + post_female + post_childcare + female_childcare +
    i(high_alloc, post, ref = 0) + i(high_alloc, female, ref = 0) |
    cell_id + industry_code^yq,
  data = df_main,
  cluster = ~state_fips
)

cat("\nModel 4: Dose-response DDD (log employment)\n")
summary(m4)

# ---- Specification 5: Broad childcare (624 + 623 + 611) vs manufacturing ---- #
df_broad <- panel %>%
  mutate(childcare_sector = as.integer(industry_code %in% c("624", "623", "611")),
         ddd_broad = post * female * childcare_sector,
         post_childcare_b = post * childcare_sector,
         female_childcare_b = female * childcare_sector)

m5 <- feols(
  log_emp ~ ddd_broad + post_female + post_childcare_b + female_childcare_b |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_broad,
  cluster = ~state_fips
)

cat("\nModel 5: Broad childcare sector DDD\n")
summary(m5)

# ---- Event Study: Dynamic DDD ---- #
# Interact event_time with female × childcare
df_es <- df_main %>%
  mutate(
    # Bin endpoints
    et = pmax(pmin(event_time, 10), -8),
    # Reference period: -1 (2021Q3, just before first disbursements)
    et = as.factor(et)
  )

m_es <- feols(
  log_emp ~ i(et, female_childcare, ref = "-1") +
    post_female + post_childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_es,
  cluster = ~state_fips
)

cat("\nEvent Study: Dynamic DDD coefficients\n")
summary(m_es)

# ---- Save results ---- #
results <- list(
  m1_ddd_emp = m1,
  m2_ddd_earn = m2,
  m3_ddd_hires = m3,
  m4_dose = m4,
  m5_broad = m5,
  m_es = m_es
)
saveRDS(results, "../data/results_main.rds")

# ---- Diagnostics for validator ---- #
diagnostics <- list(
  n_treated = n_distinct(df_main$state_fips[df_main$post == 1 & df_main$childcare == 1]),
  n_pre = length(unique(df_main$yq[df_main$post == 0])),
  n_obs = nrow(df_main),
  n_states = n_distinct(df_main$state_fips),
  n_industries = n_distinct(df_main$industry_code),
  ddd_coef = coef(m1)["ddd"],
  ddd_se = se(m1)["ddd"],
  ddd_pval = pvalue(m1)["ddd"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Print key results
cat("\n=== KEY RESULTS ===\n")
cat("DDD (log emp):", round(coef(m1)["ddd"], 4),
    " SE:", round(se(m1)["ddd"], 4),
    " p:", round(pvalue(m1)["ddd"], 4), "\n")
cat("DDD (earnings):", round(coef(m2)["ddd"], 2),
    " SE:", round(se(m2)["ddd"], 2), "\n")
cat("DDD (log hires):", round(coef(m3)["ddd"], 4),
    " SE:", round(se(m3)["ddd"], 4), "\n")
