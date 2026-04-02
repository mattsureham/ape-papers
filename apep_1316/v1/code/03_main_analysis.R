# 03_main_analysis.R — IV/2SLS analysis: VLJ leniency → appeal outcomes
# apep_1316: BVA Judge Leniency IV

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

df <- read_csv(file.path(DATA_DIR, "analysis_data.csv"), show_col_types = FALSE)
cat(sprintf("Analysis dataset: %d observations, %d VLJs\n",
            nrow(df), n_distinct(df$vlj_name)))

# =============================================================================
# FIRST STAGE: VLJ Leniency → Grant Decision
# =============================================================================

# --- Raw first stage: VLJ leniency predicts grants ---
# (1) No controls
fs_1 <- feols(grant ~ leniency_loo, data = df, vcov = ~vlj_name)

# (2) Year FE
fs_2 <- feols(grant ~ leniency_loo | year, data = df, vcov = ~vlj_name)

# (3) Year FE + RO FE
fs_3 <- feols(grant ~ leniency_loo | year + ro_fe, data = df, vcov = ~vlj_name)

# (4) Year FE + RO FE + Issue category FE
fs_4 <- feols(grant ~ leniency_loo | year + ro_fe + issue_category,
              data = df, vcov = ~vlj_name)

cat("\n=== FIRST STAGE RESULTS ===\n")
cat(sprintf("(1) No controls:        β=%.3f (SE=%.3f), F=%.1f\n",
            coef(fs_1)["leniency_loo"], se(fs_1)["leniency_loo"],
            (coef(fs_1)["leniency_loo"] / se(fs_1)["leniency_loo"])^2))
cat(sprintf("(2) Year FE:            β=%.3f (SE=%.3f), F=%.1f\n",
            coef(fs_2)["leniency_loo"], se(fs_2)["leniency_loo"],
            (coef(fs_2)["leniency_loo"] / se(fs_2)["leniency_loo"])^2))
cat(sprintf("(3) Year + RO FE:       β=%.3f (SE=%.3f), F=%.1f\n",
            coef(fs_3)["leniency_loo"], se(fs_3)["leniency_loo"],
            (coef(fs_3)["leniency_loo"] / se(fs_3)["leniency_loo"])^2))
cat(sprintf("(4) Year + RO + Issue:  β=%.3f (SE=%.3f), F=%.1f\n",
            coef(fs_4)["leniency_loo"], se(fs_4)["leniency_loo"],
            (coef(fs_4)["leniency_loo"] / se(fs_4)["leniency_loo"])^2))

# =============================================================================
# BALANCE TESTS: Leniency should not predict case characteristics
# =============================================================================

cat("\n=== BALANCE TESTS ===\n")
cat("Testing whether VLJ leniency predicts case characteristics (should be ~0):\n")

# Balance on issue type
bal_mh <- feols(I(issue_category == "mental_health") ~ leniency_loo | year,
                data = df, vcov = ~vlj_name)
bal_tdiu <- feols(I(issue_category == "tdiu") ~ leniency_loo | year,
                  data = df, vcov = ~vlj_name)
bal_sc <- feols(I(issue_category == "service_connection") ~ leniency_loo | year,
                data = df, vcov = ~vlj_name)
bal_issues <- feols(n_issues ~ leniency_loo | year,
                    data = df, vcov = ~vlj_name)

cat(sprintf("  Mental health issue:    β=%.4f (SE=%.4f, p=%.3f)\n",
            coef(bal_mh)["leniency_loo"], se(bal_mh)["leniency_loo"],
            pvalue(bal_mh)["leniency_loo"]))
cat(sprintf("  TDIU issue:             β=%.4f (SE=%.4f, p=%.3f)\n",
            coef(bal_tdiu)["leniency_loo"], se(bal_tdiu)["leniency_loo"],
            pvalue(bal_tdiu)["leniency_loo"]))
cat(sprintf("  Service connection:     β=%.4f (SE=%.4f, p=%.3f)\n",
            coef(bal_sc)["leniency_loo"], se(bal_sc)["leniency_loo"],
            pvalue(bal_sc)["leniency_loo"]))
cat(sprintf("  Number of issues:       β=%.4f (SE=%.4f, p=%.3f)\n",
            coef(bal_issues)["leniency_loo"], se(bal_issues)["leniency_loo"],
            pvalue(bal_issues)["leniency_loo"]))

# Joint F-test for balance
bal_joint <- feols(leniency_loo ~ I(issue_category == "mental_health") +
                     I(issue_category == "tdiu") +
                     I(issue_category == "service_connection") +
                     n_issues | year,
                   data = df, vcov = ~vlj_name)
cat(sprintf("  Joint F-test p-value:   %.3f\n", fitstat(bal_joint, "f")$f$p))

# =============================================================================
# REDUCED FORM: VLJ leniency → downstream outcomes
# =============================================================================
# In this V1, the "outcome" we can measure from the decisions is the grant itself.
# But we can examine heterogeneity in the leniency effect across case types.
# The reduced form IS the first stage in this context (outcome = grant decision).

# For the paper, the key economic question is:
# How much does the "judge lottery" matter for veterans?
# We quantify the variance in grant rates attributable to judge assignment.

# =============================================================================
# VARIANCE DECOMPOSITION: How much does judge identity matter?
# =============================================================================

cat("\n=== VARIANCE DECOMPOSITION ===\n")

# Model with all controls but no VLJ FE
m_no_vlj <- feols(grant ~ 1 | year + ro_fe + issue_category,
                   data = df, vcov = ~vlj_name)

# Model with VLJ FE
m_with_vlj <- feols(grant ~ 1 | year + ro_fe + issue_category + vlj_name,
                     data = df, vcov = ~vlj_name)

# Partial R-squared from adding VLJ FE
r2_no <- fitstat(m_no_vlj, "r2")$r2
r2_with <- fitstat(m_with_vlj, "r2")$r2
partial_r2_vlj <- (r2_with - r2_no) / (1 - r2_no)

cat(sprintf("R² without VLJ FE: %.4f\n", r2_no))
cat(sprintf("R² with VLJ FE:    %.4f\n", r2_with))
cat(sprintf("Partial R² of VLJ: %.4f\n", partial_r2_vlj))

# =============================================================================
# HETEROGENEITY: Leniency effects by issue type
# =============================================================================

cat("\n=== HETEROGENEITY BY ISSUE TYPE ===\n")

# Split samples
issue_types <- c("service_connection", "mental_health", "increased_rating", "tdiu")
het_results <- list()

for (itype in issue_types) {
  sub <- df |> filter(issue_category == itype)
  if (nrow(sub) < 100) next
  m <- feols(grant ~ leniency_loo | year + ro_fe, data = sub, vcov = ~vlj_name)
  het_results[[itype]] <- list(
    n = nrow(sub),
    beta = coef(m)["leniency_loo"],
    se = se(m)["leniency_loo"],
    mean_grant = mean(sub$grant)
  )
  cat(sprintf("  %s: β=%.3f (SE=%.3f), N=%d, mean_grant=%.3f\n",
              itype, het_results[[itype]]$beta, het_results[[itype]]$se,
              het_results[[itype]]$n, het_results[[itype]]$mean_grant))
}

# =============================================================================
# SAVE KEY OBJECTS
# =============================================================================

# Preferred specification is (4): Year + RO + Issue FE
preferred_fs <- fs_4

# Save diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(df$vlj_name),  # "treated units" = VLJs
  n_pre = as.integer(n_distinct(paste0(year(df$decision_date), "-", month(df$decision_date)))),  # distinct year-months
  n_obs = nrow(df),
  n_vljs = n_distinct(df$vlj_name),
  n_ros = n_distinct(df$ro_fe),
  mean_grant_rate = mean(df$grant),
  first_stage_f = (coef(preferred_fs)["leniency_loo"] / se(preferred_fs)["leniency_loo"])^2,
  partial_r2_vlj = partial_r2_vlj
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE)

# Save model objects for tables
save(fs_1, fs_2, fs_3, fs_4,
     bal_mh, bal_tdiu, bal_sc, bal_issues, bal_joint,
     m_no_vlj, m_with_vlj,
     het_results, diagnostics, preferred_fs,
     file = file.path(DATA_DIR, "model_objects.RData"))

cat("\nAnalysis complete. Models saved to data/model_objects.RData\n")
cat(sprintf("First-stage F (preferred): %.1f\n", diagnostics$first_stage_f))
