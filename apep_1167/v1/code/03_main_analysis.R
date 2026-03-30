## 03_main_analysis.R — Main regressions and IV estimation

library(dplyr)
library(readr)
library(fixest)
library(sandwich)
library(lmtest)
library(jsonlite)

df <- read_csv("data/analysis_df.csv", show_col_types = FALSE)
cat(sprintf("Analysis dataset: %d counties, %d states\n", nrow(df), n_distinct(df$buyer_state)))

# ─────────────────────────────────────────────────────────
# Construct variables
# ─────────────────────────────────────────────────────────
# Normalize pills by boom-period population proxy (use pre-period institutions as scale)
# Use log pills per institution as intensity measure
df <- df |>
  mutate(
    pills_pc = pills_boom / (pre_inst * 1000),  # pills per 1000 per institution (scale)
    log_pills_total = log(pills_boom + 1),
    log_delta_sa = log(post_comp + 1) - log(pre_comp + 1),
    has_pre_sa = pre_comp > 0,
    state_fe = as.factor(buyer_state)
  )

cat(sprintf("Counties with pre-period SA programs: %d (%.0f%%)\n",
            sum(df$has_pre_sa), 100*mean(df$has_pre_sa)))

# ─────────────────────────────────────────────────────────
# Table 1: OLS — Long Difference
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("TABLE 1: OLS Long Differences\n")
cat("═══════════════════════════════════════════════════════\n\n")

# (1) Simple OLS: delta SA completions on log pills
m1 <- feols(delta_comp ~ log_pills_total, data = df, vcov = "HC1")

# (2) Add state FE
m2 <- feols(delta_comp ~ log_pills_total | state_fe, data = df, vcov = "HC1")

# (3) Control for baseline
m3 <- feols(delta_comp ~ log_pills_total + pre_comp | state_fe, data = df, vcov = "HC1")

# (4) Log-log specification
m4 <- feols(log_delta_sa ~ log_pills_total, data = df |> filter(has_pre_sa), vcov = "HC1")

# (5) Log-log with state FE
m5 <- feols(log_delta_sa ~ log_pills_total | state_fe,
            data = df |> filter(has_pre_sa), vcov = "HC1")

cat("Model 1 (OLS, no controls):\n")
summary(m1)
cat("\nModel 2 (OLS, state FE):\n")
summary(m2)
cat("\nModel 3 (OLS, state FE + baseline):\n")
summary(m3)

# ─────────────────────────────────────────────────────────
# Table 2: IV — Triplicate State Instrument
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("TABLE 2: IV Using Triplicate-Prescription State Instrument\n")
cat("═══════════════════════════════════════════════════════\n\n")

# First stage: triplicate → log pills
fs1 <- feols(log_pills_total ~ triplicate, data = df, vcov = "HC1")
cat("First stage (no FE):\n")
summary(fs1)
cat(sprintf("First-stage F-stat: %.1f\n\n", fitstat(fs1, "f")$f$stat))

# IV: delta SA completions instrumented by triplicate
iv1 <- feols(delta_comp ~ 1 | log_pills_total ~ triplicate, data = df, vcov = "HC1")

# IV with state FE — note: triplicate is state-level so collinear with state FE
# Use region FE instead for IV
df <- df |>
  mutate(region = case_when(
    buyer_state %in% c("CT","ME","MA","NH","RI","VT","NJ","NY","PA") ~ "Northeast",
    buyer_state %in% c("IN","IL","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD") ~ "Midwest",
    buyer_state %in% c("DE","DC","FL","GA","MD","NC","SC","VA","WV","AL","KY","MS","TN","AR","LA","OK","TX") ~ "South",
    buyer_state %in% c("AZ","CO","ID","MT","NV","NM","UT","WY","AK","CA","HI","OR","WA") ~ "West",
    TRUE ~ "Other"
  ))

# IV with region FE
iv2 <- feols(delta_comp ~ 1 | region | log_pills_total ~ triplicate, data = df, vcov = "HC1")

cat("IV (no FE):\n")
summary(iv1)
cat("\nIV (region FE):\n")
summary(iv2)

# ─────────────────────────────────────────────────────────
# Table 3: Placebo — Engineering and Business Completions
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("TABLE 3: Placebo Outcomes\n")
cat("═══════════════════════════════════════════════════════\n\n")

# Engineering placebo
m_eng <- feols(delta_eng ~ log_pills_total, data = df |> filter(!is.na(delta_eng)), vcov = "HC1")
cat("Engineering (placebo):\n")
summary(m_eng)

# Business placebo
m_bus <- feols(delta_bus ~ log_pills_total, data = df |> filter(!is.na(delta_bus)), vcov = "HC1")
cat("\nBusiness (placebo):\n")
summary(m_bus)

# ─────────────────────────────────────────────────────────
# Diagnostics for validation
# ─────────────────────────────────────────────────────────
write_json(list(
  n_treated = n_distinct(df$county_fips[df$log_pills_total > median(df$log_pills_total)]),
  n_pre = 6L,  # 2000-2005 pre-exposure periods (IPEDS available since 2000)
  n_obs = nrow(df),
  n_states = n_distinct(df$buyer_state),
  n_triplicate = sum(df$triplicate),
  n_sa_counties = sum(df$has_pre_sa),
  ols_coef = coef(m1)["log_pills_total"],
  ols_se = sqrt(vcov(m1)["log_pills_total", "log_pills_total"]),
  iv_coef = coef(iv1)["fit_log_pills_total"],
  first_stage_f = fitstat(fs1, "f")$f$stat
), "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save regression objects for table generation
save(m1, m2, m3, m4, m5, iv1, iv2, fs1, m_eng, m_bus, df,
     file = "data/regression_results.RData")
cat("Regression results saved.\n")
