## 03_main_analysis.R — Main DDD and CS-DiD analysis
## apep_0714: Marijuana Expungement × Black Employment DDD

source("code/00_packages.R")

df <- readRDS("data/qwi_analysis.rds")

cat("Loaded:", nrow(df), "county-quarter obs\n")

# ============================================================
# 1. PARALLEL TRENDS: EVENT STUDY (pre-trends check)
# ============================================================
# Main DDD spec: does expunge_state × Black × Post drive Black-White employment?
# We use the wide panel where each row is a county-quarter
# Outcome: log(Black employment)
# Treatment: expunge_state × post_expunge
# Key identification: comparing expunge states vs legalize-only states,
# which controls for legalization effects on Black employment

# Create event-time variable (relative to expunge date)
df <- df %>%
  mutate(
    event_time = case_when(
      group == "expunge" ~ t - cohort_expunge,
      TRUE ~ NA_real_
    )
  )

# For event study, we need county FE, state×year FE
# Binned event study: bin at -8 and +12 to preserve cell counts

df <- df %>%
  mutate(
    event_bin = case_when(
      is.na(event_time) ~ NA_real_,
      event_time <= -8  ~ -8,
      event_time >= 12  ~ 12,
      TRUE ~ event_time
    )
  )

# Create event-time dummies (for counties in expunge states only)
# Use -1 as reference period (omit)
event_levels <- setdiff(-8:12, -1)

# ============================================================
# 2. PRIMARY DDD SPECIFICATION (TWFE)
# ============================================================
# Main sample: expunge + legalize_only states (cleanest comparison)
df_clean <- df %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(!is.na(log_emp_black)) %>%
  mutate(
    county_id = as.numeric(as.factor(county_fips)),
    state_year_fe = paste0(state_fips, "_", year)
  )

cat("Clean sample (expunge + legalize-only):", nrow(df_clean), "rows\n")
cat("Treated counties:", n_distinct(df_clean$county_fips[df_clean$expunge_state == 1]), "\n")
cat("Control counties:", n_distinct(df_clean$county_fips[df_clean$expunge_state == 0]), "\n")

# DDD Table 1: Main results — Black employment (log)
# Spec A: Expunge × Post, controlling for Legal × Post
spec_a <- feols(
  log_emp_black ~ expunge_state:post_expunge + legal_state:post_legal
                 | county_fips + state_year_fe,
  data = df_clean,
  cluster = ~state_fips
)

# Spec B: Full controls
spec_b <- feols(
  log_emp_black ~ expunge_state:post_expunge + legal_state:post_legal
                 + log(total_pop + 1) + black_share + poverty_rate
                 | county_fips + state_year_fe,
  data = df_clean,
  cluster = ~state_fips
)

# Spec C: Black earnings
df_earn <- df_clean %>% filter(!is.na(log_earn_black))
spec_c <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                  | county_fips + state_year_fe,
  data = df_earn,
  cluster = ~state_fips
)

# Spec D: White employment (placebo — should be null or much smaller)
spec_d <- feols(
  log_emp_white ~ expunge_state:post_expunge + legal_state:post_legal
                  | county_fips + state_year_fe,
  data = df_clean %>% filter(!is.na(log_emp_white)),
  cluster = ~state_fips
)

# Print main results
cat("\n=== MAIN RESULTS ===\n")
cat("Spec A: Black employment, no controls\n")
print(coeftable(spec_a))
cat("\nSpec B: Black employment, with controls\n")
print(coeftable(spec_b))
cat("\nSpec C: Black earnings, no controls\n")
print(coeftable(spec_c))
cat("\nSpec D: White employment (placebo)\n")
print(coeftable(spec_d))

# ============================================================
# 3. EVENT STUDY (Pre-trends test)
# ============================================================
# Event study on expunge-state counties only (within-group pre-trends check)
df_event <- df %>%
  filter(group == "expunge", !is.na(log_emp_black)) %>%
  mutate(
    rel_time = t - cohort_expunge,
    rel_bin = pmax(-8L, pmin(12L, as.integer(rel_time))),
    state_year_fe = paste0(state_fips, "_", year)
  )

cat("Event study counties:", n_distinct(df_event$county_fips), "\n")
cat("rel_bin range:", range(df_event$rel_bin, na.rm=TRUE), "\n")

# Event study regression
event_study <- feols(
  log_emp_black ~ i(rel_bin, ref = -1)
                  | county_fips + state_year_fe,
  data = df_event,
  cluster = ~state_fips
)

cat("\n=== EVENT STUDY COEFFICIENTS ===\n")
print(coeftable(event_study))

# Extract event study estimates for plotting
ct <- coeftable(event_study)
ct_df <- data.frame(
  term = rownames(ct),
  Estimate = ct[,"Estimate"],
  SE = ct[,"Std. Error"],
  stringsAsFactors = FALSE
)

es_coefs <- ct_df %>%
  filter(grepl("rel_bin", term)) %>%
  mutate(
    time = as.numeric(str_extract(term, "-?\\d+")),
    estimate = Estimate,
    std.error = SE,
    conf_lo = Estimate - 1.96 * SE,
    conf_hi = Estimate + 1.96 * SE
  ) %>%
  select(time, estimate, std.error, conf_lo, conf_hi) %>%
  bind_rows(data.frame(time=-1, estimate=0, std.error=0, conf_lo=0, conf_hi=0)) %>%
  arrange(time)

# Pre-trend test
pre_coefs <- ct_df %>%
  filter(grepl("rel_bin", term)) %>%
  mutate(time = as.numeric(str_extract(term, "-?\\d+"))) %>%
  filter(time < -1)

cat("\n=== PRE-TREND CHECK ===\n")
cat("Pre-period coefficients (should be near zero):\n")
print(pre_coefs %>% select(time, Estimate, SE))

# ============================================================
# 4. CALLAWAY-SANT'ANNA STAGGERED DiD
# ============================================================
# Use legalize-only + never-legalized counties as "never-treated" comparison
# For CS-DiD, cohort = 0 means never-treated

# Prepare CS-DiD dataset
# Stack long by race: for each county-quarter, we have Black and White rows
# CS-DiD on Black employment separately

df_cs <- df %>%
  filter(!is.na(log_emp_black)) %>%
  mutate(
    # For CS-DiD: G = cohort (first quarter of treatment); 0 = never treated
    G = cohort_expunge,
    # Period variable (quarter index)
    period = t,
    # Unit ID
    unit = as.integer(as.factor(county_fips))
  )

cat("\nRunning Callaway-Sant'Anna CS-DiD...\n")
cs_result <- tryCatch({
  att_gt(
    yname = "log_emp_black",
    tname = "period",
    idname = "unit",
    gname = "G",
    data = df_cs,
    control_group = "nevertreated",
    est_method = "reg",
    clustervars = "state_fips"
  )
}, error = function(e) {
  cat("CS-DiD failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\n=== CS-DiD AGGREGATE ATT ===\n")
  print(summary(cs_agg))

  cs_dyn <- aggte(cs_result, type = "dynamic")
  cat("\n=== CS-DiD DYNAMIC ATT ===\n")
  print(summary(cs_dyn))

  saveRDS(cs_result, "data/cs_result.rds")
  saveRDS(cs_agg, "data/cs_agg.rds")
  saveRDS(cs_dyn, "data/cs_dyn.rds")
} else {
  cat("CS-DiD could not be estimated — using TWFE as primary\n")
}

# ============================================================
# 5. DIAGNOSTICS JSON
# ============================================================

# Extract main coefficient
main_coef <- coef(spec_a)["expunge_state:post_expunge"]
main_se <- se(spec_a)["expunge_state:post_expunge"]

diagnostics <- list(
  n_treated = n_distinct(df_clean$county_fips[df_clean$expunge_state == 1]),
  n_control = n_distinct(df_clean$county_fips[df_clean$expunge_state == 0]),
  n_pre = 24,  # 2013Q1-2018Q4 = 24 quarters pre CA treatment
  n_obs = nrow(df_clean),
  n_states_treated = 5,
  n_states_control = 4,
  main_beta = as.numeric(main_coef),
  main_se = as.numeric(main_se),
  main_pval = as.numeric(pvalue(spec_a)["expunge_state:post_expunge"]),
  pre_trend_max_abs = if (nrow(pre_coefs) > 0) max(abs(pre_coefs$Estimate)) else NA
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("Treated counties: %d (≥20 required)\n", diagnostics$n_treated))
cat(sprintf("Pre-periods: %d (≥5 required)\n", diagnostics$n_pre))
cat(sprintf("Total obs: %d (≥100 required)\n", diagnostics$n_obs))
cat(sprintf("Main coef (expunge × post): %.4f (SE: %.4f, p=%.4f)\n",
            diagnostics$main_beta, diagnostics$main_se, diagnostics$main_pval))

# Save model objects
saveRDS(list(spec_a=spec_a, spec_b=spec_b, spec_c=spec_c, spec_d=spec_d,
             event_study=event_study, es_coefs=es_coefs), "data/models.rds")

cat("\nMain analysis complete.\n")

# ============================================================
# 6. TRIPLE-DIFFERENCE (DDD) — MAIN SPECIFICATION
# ============================================================
# Load long format (stacked by race)
df_long <- readRDS("data/qwi_long.rds")

cat("\nRunning Triple-Difference (DDD) specification...\n")

marijuana_laws <- read_csv("data/marijuana_laws.csv", show_col_types = FALSE)

df_ddd <- df_long %>%
  left_join(
    marijuana_laws %>% select(state_fips, retail_year, retail_qtr),
    by = "state_fips"
  ) %>%
  mutate(
    # post_expunge: 1 if in expunge state AND t >= cohort_expunge
    post_expunge = case_when(
      expunge_state == 1 & cohort_expunge > 0 & t >= cohort_expunge ~ 1L,
      TRUE ~ 0L
    ),
    # post_legal: 1 if state has legal retail AND t >= retail quarter
    post_legal = case_when(
      !is.na(retail_year) & t >= (retail_year - 2013) * 4 + retail_qtr ~ 1L,
      TRUE ~ 0L
    ),
    legal_state = as.integer(group %in% c("expunge", "legalize_only"))
  ) %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(!is.na(log_earn)) %>%
  mutate(
    county_race_id = paste0(county_fips, "_", race),
    state_year_fe  = paste0(state_fips, "_", year)
  )

cat("DDD sample rows:", nrow(df_ddd), "\n")

# DDD: Expunge × Black × Post (main)
# FE structure that avoids collinearity:
# - county_fips: absorbs county-level baseline
# - state_fips^year: absorbs state×year (includes Expunge×Post two-way)
# - is_black^year: absorbs race×year (includes Black×Post national trend)
# Triple interaction is identified from within-state, across-race variation

ddd_earn <- feols(
  log_earn ~ expunge_state:is_black:post_expunge
             | county_fips + state_fips^year + is_black^year,
  data = df_ddd,
  cluster = ~state_fips
)

cat("\n=== TRIPLE-DIFFERENCE EARNINGS RESULT ===\n")
print(coeftable(ddd_earn))

# DDD for employment
df_ddd_emp <- df_ddd %>% filter(!is.na(log_emp))

ddd_emp <- feols(
  log_emp ~ expunge_state:is_black:post_expunge
            | county_fips + state_fips^year + is_black^year,
  data = df_ddd_emp,
  cluster = ~state_fips
)

cat("\n=== TRIPLE-DIFFERENCE EMPLOYMENT RESULT ===\n")
print(coeftable(ddd_emp))

# Save DDD results (load existing models.rds to avoid overwriting spec_a/b/c/d)
models_saved <- readRDS("data/models.rds")
models_updated <- c(models_saved, list(ddd_earn=ddd_earn, ddd_emp=ddd_emp))
saveRDS(models_updated, "data/models.rds")

cat("\nDDD analysis complete.\n")

# ============================================================
# 7. DDD via Wald Test (Difference of DD Coefficients)
# ============================================================
# Compute DDD as beta_black - beta_white using in-memory spec_c
# and a new White earnings model estimated here

cat("\n=== DDD via COEFFICIENT DIFFERENCE ===\n")

# White earnings model (estimated inline to avoid depending on 04_robustness.R)
df_earn_white <- df_clean %>% filter(!is.na(log_earn_white))
placebo_white_earn <- feols(
  log_earn_white ~ expunge_state:post_expunge + legal_state:post_legal
                  | county_fips + state_year_fe,
  data = df_earn_white,
  cluster = ~state_fips
)

beta_black <- coef(spec_c)["expunge_state:post_expunge"]
se_black   <- fixest::se(spec_c)["expunge_state:post_expunge"]
beta_white <- coef(placebo_white_earn)["expunge_state:post_expunge"]
se_white   <- fixest::se(placebo_white_earn)["expunge_state:post_expunge"]

ddd_diff <- as.numeric(beta_black) - as.numeric(beta_white)
# Conservative SE (treating estimates as independent given different data subsets)
ddd_se <- sqrt(as.numeric(se_black)^2 + as.numeric(se_white)^2)
ddd_t <- ddd_diff / ddd_se
ddd_pval <- 2 * pt(-abs(ddd_t), df = 7)  # 9 states - 2 groups = 7 df

cat(sprintf("Beta (Black earnings): %.4f (SE: %.4f)\n", as.numeric(beta_black), as.numeric(se_black)))
cat(sprintf("Beta (White earnings): %.4f (SE: %.4f)\n", as.numeric(beta_white), as.numeric(se_white)))
cat(sprintf("DDD difference: %.4f\n", ddd_diff))
cat(sprintf("DDD SE: %.4f\n", ddd_se))
cat(sprintf("DDD t-stat: %.4f (p=%.4f)\n", ddd_t, ddd_pval))

# Save for tables
ddd_results <- list(
  ddd_diff = ddd_diff,
  ddd_se = ddd_se,
  ddd_t = ddd_t,
  ddd_pval = ddd_pval,
  beta_black = as.numeric(beta_black),
  beta_white = as.numeric(beta_white)
)
saveRDS(ddd_results, "data/ddd_results.rds")
cat("DDD via Wald test complete.\n")
