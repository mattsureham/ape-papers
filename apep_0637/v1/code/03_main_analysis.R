# 03_main_analysis.R — Main 2SLS estimation
# apep_0637: Patent Examiner Leniency & Defensive Patenting

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
cat(sprintf("Analysis sample: %s observations\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. FIRST STAGE: Examiner Leniency → Grant Probability
# ============================================================================
cat("\n=== FIRST STAGE ===\n")

# OLS: Granted = α + π × ExaminerLeniency + AU×Year FE
fs <- feols(granted ~ examiner_leniency | au_year,
            data = df, vcov = ~examiner_art_unit)
cat("First stage (art-unit × year FE, clustered at AU level):\n")
summary(fs)

# F-statistic (t^2 from first-stage regression)
fs_t <- coef(fs)["examiner_leniency"] / se(fs)["examiner_leniency"]
cat(sprintf("\nFirst-stage F-statistic (t^2): %.1f\n", fs_t^2))

# ============================================================================
# 2. REDUCED FORM: Examiner Leniency → Competitor Filings
# ============================================================================
cat("\n=== REDUCED FORM ===\n")

# Check which outcome variables are available
if ("log_class_filings_t1" %in% names(df)) {
  rf_1yr <- feols(log_class_filings_t1 ~ examiner_leniency | au_year,
                  data = df, vcov = ~examiner_art_unit)
  cat("Reduced form (1-year window):\n")
  summary(rf_1yr)
} else {
  cat("Outcome variables not available. Check data extraction.\n")
}

# ============================================================================
# 3. TWO-STAGE LEAST SQUARES: Grant → Competitor Filings
# ============================================================================
cat("\n=== 2SLS ESTIMATES ===\n")

# Main specification: log(class_filings_t+k) instrumented by examiner_leniency
# FE: art-unit × year
# Clustering: art-unit level

results <- list()

# 1-year window
if ("log_class_filings_t1" %in% names(df)) {
  iv_1yr <- feols(log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                  data = df, vcov = ~examiner_art_unit)
  results[["1yr"]] <- iv_1yr
  cat("\n--- 2SLS: 1-year window ---\n")
  summary(iv_1yr)
}

# 2-year window
if ("log_class_filings_2yr" %in% names(df)) {
  iv_2yr <- feols(log_class_filings_2yr ~ 1 | au_year | granted ~ examiner_leniency,
                  data = df, vcov = ~examiner_art_unit)
  results[["2yr"]] <- iv_2yr
  cat("\n--- 2SLS: 2-year window ---\n")
  summary(iv_2yr)
}

# 3-year window
if ("log_class_filings_3yr" %in% names(df)) {
  iv_3yr <- feols(log_class_filings_3yr ~ 1 | au_year | granted ~ examiner_leniency,
                  data = df, vcov = ~examiner_art_unit)
  results[["3yr"]] <- iv_3yr
  cat("\n--- 2SLS: 3-year window ---\n")
  summary(iv_3yr)
}

# ============================================================================
# 3b. CLASS-LEVEL CLUSTERING ROBUSTNESS
# ============================================================================
cat("\n=== CLASS-LEVEL CLUSTERING ===\n")

if ("log_class_filings_t1" %in% names(df)) {
  iv_class_cluster <- feols(log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                            data = df, vcov = ~uspc_class)
  results[["class_cluster"]] <- iv_class_cluster
  cat("\n--- 2SLS: 1-year window (clustered at USPC class) ---\n")
  summary(iv_class_cluster)
}

# ============================================================================
# 4. OLS COMPARISON (biased but useful benchmark)
# ============================================================================
cat("\n=== OLS COMPARISON ===\n")

if ("log_class_filings_t1" %in% names(df)) {
  ols_1yr <- feols(log_class_filings_t1 ~ granted | au_year,
                   data = df, vcov = ~examiner_art_unit)
  cat("OLS (1-year window):\n")
  summary(ols_1yr)
}

# ============================================================================
# 5. MECHANISM: Filing type decomposition
# ============================================================================
cat("\n=== MECHANISMS ===\n")

# Test 1: Small entity effect (small firms may respond differently)
if ("small_entity" %in% names(df) & "log_class_filings_t1" %in% names(df)) {
  iv_small <- feols(log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                    data = df %>% filter(small_entity == 1),
                    vcov = ~examiner_art_unit)
  iv_large <- feols(log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                    data = df %>% filter(small_entity == 0),
                    vcov = ~examiner_art_unit)
  cat("2SLS by entity size:\n")
  cat(sprintf("  Small entities: β = %.4f (SE = %.4f)\n",
              coef(iv_small)["fit_granted"], se(iv_small)["fit_granted"]))
  cat(sprintf("  Large entities: β = %.4f (SE = %.4f)\n",
              coef(iv_large)["fit_granted"], se(iv_large)["fit_granted"]))

  results[["small"]] <- iv_small
  results[["large"]] <- iv_large
}

# Test 2: By technology concentration
# Compute USPC class HHI (if we have assignee data) — skip for now
# Use number of examiners in AU as proxy for technology breadth
df <- df %>%
  group_by(examiner_art_unit) %>%
  mutate(au_total_apps = n()) %>%
  ungroup()

# Split at median AU size
median_au_size <- median(df$au_total_apps)

if ("log_class_filings_t1" %in% names(df)) {
  iv_concentrated <- feols(
    log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
    data = df %>% filter(au_total_apps <= median_au_size),
    vcov = ~examiner_art_unit
  )
  iv_diffuse <- feols(
    log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
    data = df %>% filter(au_total_apps > median_au_size),
    vcov = ~examiner_art_unit
  )
  cat("\n2SLS by AU size (proxy for concentration):\n")
  cat(sprintf("  Small AUs (concentrated): β = %.4f (SE = %.4f)\n",
              coef(iv_concentrated)["fit_granted"], se(iv_concentrated)["fit_granted"]))
  cat(sprintf("  Large AUs (diffuse): β = %.4f (SE = %.4f)\n",
              coef(iv_diffuse)["fit_granted"], se(iv_diffuse)["fit_granted"]))

  results[["concentrated"]] <- iv_concentrated
  results[["diffuse"]] <- iv_diffuse
}

# ============================================================================
# 6. Save results
# ============================================================================

saveRDS(results, "../data/main_results.rds")

# Diagnostics for validate_v1
n_treated <- n_distinct(df$examiner_art_unit[df$granted == 1])
# For IV design: n_pre counts distinct time periods (filing years) in sample
n_pre <- length(unique(df$filing_year))
n_obs <- nrow(df)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Main analysis complete.\n")
