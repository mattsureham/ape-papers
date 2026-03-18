## 03_main_analysis.R — RDD estimation for YEI
## apep_0723: EU Youth Employment Initiative RDD

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
neet_yearly <- readRDS("../data/neet_yearly.rds")

cat(sprintf("Analysis sample: %d NUTS2 regions\n", nrow(df)))
cat(sprintf("Treated (rv >= 0): %d | Control (rv < 0): %d\n",
            sum(df$treated), sum(df$treated == 0)))
cat(sprintf("Running variable (rv) range: [%.2f, %.2f]\n",
            min(df$rv, na.rm=TRUE), max(df$rv, na.rm=TRUE)))

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Extract RDD coefficients from rdrobust output
rdd_coef_table <- function(rdd_obj, outcome_label) {
  coef_val <- rdd_obj$coef["Conventional"]
  se_val   <- rdd_obj$se["Conventional"]
  pval_val <- rdd_obj$pv["Conventional"]
  ci_lo    <- rdd_obj$ci["Conventional", "CI Lower"]
  ci_hi    <- rdd_obj$ci["Conventional", "CI Upper"]
  bw_left  <- rdd_obj$bws["h", "left"]
  bw_right <- rdd_obj$bws["h", "right"]
  n_left   <- rdd_obj$N_h["left"]
  n_right  <- rdd_obj$N_h["right"]

  data.frame(
    outcome  = outcome_label,
    coef     = as.numeric(coef_val),
    se       = as.numeric(se_val),
    pval     = as.numeric(pval_val),
    ci_lo    = as.numeric(ci_lo),
    ci_hi    = as.numeric(ci_hi),
    bw       = as.numeric(bw_left),
    n_left   = as.numeric(n_left),
    n_right  = as.numeric(n_right),
    n_total  = as.numeric(n_left) + as.numeric(n_right),
    stringsAsFactors = FALSE
  )
}

# ============================================================
# 1. MAIN RDD: NEET RATE CHANGE
# ============================================================

cat("\n=== MAIN RDD: NEET RATE CHANGE ===\n")

rdd_neet <- tryCatch({
  rdrobust::rdrobust(
    y = df$d_neet,
    x = df$rv,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df$country
  )
}, error = function(e) {
  stop(sprintf("FATAL: rdrobust failed for NEET: %s", e$message))
})

cat("NEET RDD result:\n")
print(summary(rdd_neet))

# ============================================================
# 2. SECONDARY RDD: YOUTH EMPLOYMENT RATE CHANGE
# ============================================================

cat("\n=== SECONDARY RDD: YOUTH EMPLOYMENT RATE CHANGE ===\n")

df_emp <- df %>% filter(!is.na(d_emp))
cat(sprintf("Employment rate sample: %d regions\n", nrow(df_emp)))

rdd_emp <- tryCatch({
  rdrobust::rdrobust(
    y = df_emp$d_emp,
    x = df_emp$rv,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df_emp$country
  )
}, error = function(e) {
  stop(sprintf("FATAL: rdrobust failed for employment rate: %s", e$message))
})

cat("Employment rate RDD result:\n")
print(summary(rdd_emp))

# ============================================================
# 3. SECONDARY RDD: EARLY SCHOOL LEAVING CHANGE
# ============================================================

cat("\n=== SECONDARY RDD: EARLY SCHOOL LEAVING CHANGE ===\n")

df_esl <- df %>% filter(!is.na(d_esl))
cat(sprintf("Early school leaving sample: %d regions\n", nrow(df_esl)))

rdd_esl <- tryCatch({
  rdrobust::rdrobust(
    y = df_esl$d_esl,
    x = df_esl$rv,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df_esl$country
  )
}, error = function(e) {
  cat(sprintf("WARNING: rdrobust failed for ESL: %s\n", e$message))
  NULL
})

if (!is.null(rdd_esl)) {
  cat("Early school leaving RDD result:\n")
  print(summary(rdd_esl))
}

# ============================================================
# 4. OLS COMPARISON: POLYNOMIAL IN RUNNING VARIABLE + TREATMENT
# ============================================================

cat("\n=== OLS POLYNOMIAL SPECIFICATIONS ===\n")

# Spec 1: Linear control function
ols_lin <- feols(
  d_neet ~ treated + rv + I(rv * treated),
  data = df,
  cluster = ~country
)

# Spec 2: Quadratic control function
ols_quad <- feols(
  d_neet ~ treated + rv + I(rv^2) + I(rv * treated) + I(rv^2 * treated),
  data = df,
  cluster = ~country
)

# Spec 3: Linear, bandwidth-restricted (use IK bandwidth from main RDD)
bw_main <- rdd_neet$bws["h", "left"]
df_bw <- df %>% filter(abs(rv) <= bw_main)

ols_bw <- feols(
  d_neet ~ treated + rv + I(rv * treated),
  data = df_bw,
  cluster = ~country
)

# Spec 4: Employment rate (secondary, linear)
ols_emp <- feols(
  d_emp ~ treated + rv + I(rv * treated),
  data = df_emp,
  cluster = ~country
)

cat("OLS Linear (NEET):\n"); print(coeftable(ols_lin))
cat("OLS Quadratic (NEET):\n"); print(coeftable(ols_quad))
cat("OLS BW-restricted (NEET):\n"); print(coeftable(ols_bw))
cat("OLS Linear (Emp Rate):\n"); print(coeftable(ols_emp))

# ============================================================
# 5. EVENT STUDY: YEAR-BY-YEAR RDD ESTIMATES
# ============================================================

cat("\n=== YEAR-BY-YEAR EVENT STUDY ===\n")

years_available <- sort(unique(neet_yearly$TIME_PERIOD))
years_est <- years_available[years_available >= 2008 & years_available <= 2022]

event_results <- list()

for (yr in years_est) {
  # For each year, construct level outcome: NEET_t - NEET_pre
  # Pre = average 2010-2012
  yr_data <- neet_yearly %>%
    filter(TIME_PERIOD == yr) %>%
    inner_join(
      neet_yearly %>%
        filter(TIME_PERIOD %in% 2010:2012) %>%
        group_by(geo) %>%
        summarise(neet_baseline = mean(neet_rate, na.rm=TRUE), .groups="drop"),
      by = "geo"
    ) %>%
    mutate(
      d_neet_yr = neet_rate - neet_baseline
    ) %>%
    filter(!is.na(d_neet_yr), !is.na(rv))

  if (nrow(yr_data) < 20 || length(unique(yr_data$country)) < 3) {
    cat(sprintf("  Skipping year %d: insufficient obs (%d) or countries (%d)\n",
                yr, nrow(yr_data), length(unique(yr_data$country))))
    next
  }

  # OLS for event study (rdrobust by year can be unstable with small N)
  ols_yr <- tryCatch({
    feols(d_neet_yr ~ treated + rv + I(rv * treated), data = yr_data, cluster = ~country)
  }, error = function(e) NULL)

  if (!is.null(ols_yr)) {
    ct <- coeftable(ols_yr)
    if ("treated" %in% rownames(ct)) {
      event_results[[as.character(yr)]] <- data.frame(
        year     = yr,
        coef     = ct["treated", "Estimate"],
        se       = ct["treated", "Std. Error"],
        pval     = ct["treated", "Pr(>|t|)"],
        n_obs    = nrow(yr_data),
        stringsAsFactors = FALSE
      )
    }
  }
}

es_df <- if (length(event_results) > 0) {
  bind_rows(event_results) %>% arrange(year)
} else {
  data.frame(year=integer(0), coef=numeric(0), se=numeric(0), pval=numeric(0), n_obs=integer(0))
}

cat(sprintf("Event study estimates: %d years\n", nrow(es_df)))
print(es_df)

# ============================================================
# 6. COLLECT RDD RESULTS TABLE
# ============================================================

rdd_results <- rdd_coef_table(rdd_neet, "Change in NEET rate (pp)")
rdd_results <- bind_rows(
  rdd_results,
  rdd_coef_table(rdd_emp, "Change in youth employment rate (pp)")
)
if (!is.null(rdd_esl)) {
  rdd_results <- bind_rows(
    rdd_results,
    rdd_coef_table(rdd_esl, "Change in early school leaving (pp)")
  )
}

cat("\nRDD Results Summary:\n")
print(rdd_results)

# ============================================================
# 7. DIAGNOSTICS JSON
# ============================================================

diagnostics <- list(
  n_treated   = sum(df$treated),
  n_control   = sum(df$treated == 0),
  n_obs       = nrow(df),
  n_countries = length(unique(df$country)),
  n_pre       = 3,   # 2010, 2011, 2012 pre-period years
  threshold   = 25,
  bw_main     = as.numeric(bw_main),
  rdd_neet_coef = as.numeric(rdd_neet$coef["Conventional"]),
  rdd_neet_se   = as.numeric(rdd_neet$se["Conventional"]),
  rdd_neet_pval = as.numeric(rdd_neet$pv["Conventional"]),
  rdd_emp_coef  = as.numeric(rdd_emp$coef["Conventional"]),
  rdd_emp_se    = as.numeric(rdd_emp$se["Conventional"]),
  rdd_emp_pval  = as.numeric(rdd_emp$pv["Conventional"])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("Treated regions: %d (>= 25%% unemployment)\n", diagnostics$n_treated))
cat(sprintf("Control regions: %d\n", diagnostics$n_control))
cat(sprintf("Total regions: %d\n", diagnostics$n_obs))
cat(sprintf("Countries: %d\n", diagnostics$n_countries))
cat(sprintf("Pre-periods: %d\n", diagnostics$n_pre))
cat(sprintf("Main bandwidth: %.2f pp\n", diagnostics$bw_main))
cat(sprintf("RDD NEET coef: %.4f (SE: %.4f, p=%.4f)\n",
            diagnostics$rdd_neet_coef, diagnostics$rdd_neet_se, diagnostics$rdd_neet_pval))

# ============================================================
# 8. SAVE
# ============================================================

saveRDS(list(
  rdd_neet  = rdd_neet,
  rdd_emp   = rdd_emp,
  rdd_esl   = rdd_esl,
  ols_lin   = ols_lin,
  ols_quad  = ols_quad,
  ols_bw    = ols_bw,
  ols_emp   = ols_emp,
  rdd_results = rdd_results,
  es_df     = es_df,
  bw_main   = bw_main
), "../data/models.rds")

cat("\nMain analysis complete.\n")
