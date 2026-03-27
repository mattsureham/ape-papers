## 03_main_analysis.R — Primary DiD regressions
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations

source("00_packages.R")

data_dir <- "../data/"
df <- readRDS(file.path(data_dir, "analysis_clean.rds"))

cat("=== Main Analysis ===\n")
cat(sprintf("Analysis data: %d obs, %d counties, years %s\n",
            nrow(df), n_distinct(df$fips),
            paste(range(df$year), collapse = "-")))

# ============================================================================
# 1. PRIMARY SPECIFICATION — Continuous Treatment DiD
# ============================================================================
cat("\n--- Model 1: Basic DiD (continuous treatment x post) ---\n")

# Y_{ct} = β₁ MailSlowdown_c × Post_t + county FE + year FE + ε_{ct}
m1 <- feols(
  prev_hosp_rate ~ mail_slowdown:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m1)

# ============================================================================
# 2. TRIPLE-DIFFERENCE — Treatment x Post x Pharmacy Desert
# ============================================================================
cat("\n--- Model 2: Triple-difference (Treatment x Post x Pharmacy Desert) ---\n")

# Include all lower-order interactions
m2 <- feols(
  prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m2)

# ============================================================================
# 3. BINARY TREATMENT VERSION
# ============================================================================
cat("\n--- Model 3: Binary treatment (any slowdown) x Post ---\n")

m3 <- feols(
  prev_hosp_rate ~ treated:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m3)

# Binary triple-diff
m3b <- feols(
  prev_hosp_rate ~ treated:post + treated:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m3b)

# ============================================================================
# 4. EVENT STUDY — Year-by-Year Effects
# ============================================================================
cat("\n--- Model 4: Event study (year-by-year treatment effects) ---\n")

# Interact treatment with year dummies (omit 2021 as reference)
df$rel_year_factor <- relevel(factor(df$rel_year), ref = "0")

m4 <- feols(
  prev_hosp_rate ~ i(rel_year, mail_slowdown, ref = 0) | fips + year,
  data = df,
  cluster = ~state
)
summary(m4)

# Event study for triple-diff
df$mail_x_desert <- df$mail_slowdown * df$pharm_desert

m4b <- feols(
  prev_hosp_rate ~ i(rel_year, mail_slowdown, ref = 0) +
    i(rel_year, mail_x_desert, ref = 0) | fips + year,
  data = df,
  cluster = ~state
)
summary(m4b)

# ============================================================================
# 5. LOG OUTCOME
# ============================================================================
cat("\n--- Model 5: Log outcome specification ---\n")

m5 <- feols(
  log_prev_hosp ~ mail_slowdown:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m5)

m5b <- feols(
  log_prev_hosp ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m5b)

# ============================================================================
# 6. WITH CONTROLS
# ============================================================================
cat("\n--- Model 6: With time-varying controls ---\n")

# Add controls interacted with post (county characteristics × post)
m6 <- feols(
  prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post +
    log_pop:post + pct_65plus:post + pct_uninsured:post +
    median_hh_income:post | fips + year,
  data = df,
  cluster = ~state
)
summary(m6)

# ============================================================================
# 7. SAVE RESULTS
# ============================================================================
cat("\n=== Saving main results ===\n")

results <- list(
  m1_basic_did = m1,
  m2_triple_diff = m2,
  m3_binary_did = m3,
  m3b_binary_triple = m3b,
  m4_event_study = m4,
  m4b_event_triple = m4b,
  m5_log = m5,
  m5b_log_triple = m5b,
  m6_controls = m6
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# 8. DIAGNOSTICS for validate_v1.py
# ============================================================================

diagnostics <- list(
  n_treated = n_distinct(df$fips[df$treated == 1]),
  n_pre = sum(unique(df$year) < 2022),
  n_obs = nrow(df)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n✓ Main analysis complete. Results saved.\n")
cat(sprintf("  n_treated = %d, n_pre = %d, n_obs = %d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
