## 04_robustness.R — Robustness checks
## apep_1317: Colombia draft lottery and wartime conscription

source("00_packages.R")
data_dir <- "../data"

saber11 <- readRDS(file.path(data_dir, "saber11_analysis.rds"))
saberpro <- readRDS(file.path(data_dir, "saberpro_analysis.rds"))

cat("=== ROBUSTNESS CHECKS ===\n")

# ===========================================================================
# 1. Placebo test: Female-only sample (should show no DDD effect)
# ===========================================================================
cat("\n--- Placebo: Effect on females only ---\n")

# If identification is correct, high-conflict × conflict-cohort should NOT
# affect female scores (since women are never drafted)
females <- saber11 %>% filter(male == 0)

placebo_f <- feols(math_score ~ high_conflict * conflict_cohort +
                     public_school + rural + stratum |
                     exam_year + dept_std,
                   data = females, cluster = ~dept_std)

cat("Placebo (females only):\n")
print(summary(placebo_f))

# ===========================================================================
# 2. Alternative cohort cutoffs
# ===========================================================================
cat("\n--- Alternative cohort cutoffs ---\n")

# Test sensitivity to the 1998 birth-year cutoff
cutoffs <- c(1996, 1997, 1998, 1999, 2000)
cutoff_results <- list()

for (cut in cutoffs) {
  saber11$alt_cohort <- as.integer(saber11$birth_year <= cut)
  m <- feols(math_score ~ male * high_conflict * alt_cohort +
               public_school + rural + stratum |
               exam_year + dept_std,
             data = saber11, cluster = ~dept_std)

  ddd_var <- "male:high_conflictTRUE:alt_cohort"
  if (ddd_var %in% names(coef(m))) {
    cutoff_results[[as.character(cut)]] <- data.frame(
      cutoff = cut,
      coef = coef(m)[ddd_var],
      se = sqrt(vcov(m)[ddd_var, ddd_var]),
      stringsAsFactors = FALSE
    )
    cat(sprintf("  Cutoff %d: DDD = %.3f (SE = %.3f)\n",
                cut, coef(m)[ddd_var], sqrt(vcov(m)[ddd_var, ddd_var])))
  }
}

cutoff_df <- bind_rows(cutoff_results)
saveRDS(cutoff_df, file.path(data_dir, "cutoff_robustness.rds"))

# ===========================================================================
# 3. Birth-year event study (cohort-by-cohort DDD)
# ===========================================================================
cat("\n--- Birth-year event study ---\n")

# Estimate DDD for each birth year (relative to 1998 = peace cutoff)
saber11$birth_year_rel <- saber11$birth_year - 1998

# Create male × high_conflict interaction as a single variable
saber11$male_hc <- saber11$male * as.integer(saber11$high_conflict)

event_study <- feols(
  math_score ~ i(birth_year, male_hc, ref = 1998) +
    male + as.integer(high_conflict) +
    public_school + rural + stratum |
    exam_year + dept_std,
  data = saber11, cluster = ~dept_std
)

cat("Event study (birth-year × male × high_conflict):\n")
es_coefs <- coeftable(event_study)
es_rows <- grep("birth_year", rownames(es_coefs))
if (length(es_rows) > 0) {
  es_df <- data.frame(
    birth_year = as.integer(gsub(".*::(-?\\d+):.*", "\\1",
                                  rownames(es_coefs)[es_rows])),
    coef = es_coefs[es_rows, 1],
    se = es_coefs[es_rows, 2]
  )
  es_df <- es_df %>% arrange(birth_year)
  print(es_df)
  saveRDS(es_df, file.path(data_dir, "event_study.rds"))
}

# ===========================================================================
# 4. SES heterogeneity: Low vs high stratum
# ===========================================================================
cat("\n--- SES heterogeneity ---\n")

saber11$low_ses <- as.integer(saber11$stratum <= 2)

m_low <- feols(math_score ~ male * high_conflict * conflict_cohort |
                 exam_year + dept_std,
               data = saber11 %>% filter(low_ses == 1),
               cluster = ~dept_std)

m_high <- feols(math_score ~ male * high_conflict * conflict_cohort |
                  exam_year + dept_std,
                data = saber11 %>% filter(low_ses == 0),
                cluster = ~dept_std)

ddd_var <- "male:high_conflictTRUE:conflict_cohort"
cat(sprintf("  Low SES (stratum 1-2): DDD = %.3f (SE = %.3f)\n",
            coef(m_low)[ddd_var], sqrt(vcov(m_low)[ddd_var, ddd_var])))
cat(sprintf("  High SES (stratum 3+): DDD = %.3f (SE = %.3f)\n",
            coef(m_high)[ddd_var], sqrt(vcov(m_high)[ddd_var, ddd_var])))

# ===========================================================================
# 5. Public vs private school
# ===========================================================================
cat("\n--- School type heterogeneity ---\n")

m_pub <- feols(math_score ~ male * high_conflict * conflict_cohort |
                 exam_year + dept_std,
               data = saber11 %>% filter(public_school == 1),
               cluster = ~dept_std)

m_priv <- feols(math_score ~ male * high_conflict * conflict_cohort |
                  exam_year + dept_std,
                data = saber11 %>% filter(public_school == 0),
                cluster = ~dept_std)

cat(sprintf("  Public schools: DDD = %.3f (SE = %.3f)\n",
            coef(m_pub)[ddd_var], sqrt(vcov(m_pub)[ddd_var, ddd_var])))
cat(sprintf("  Private schools: DDD = %.3f (SE = %.3f)\n",
            coef(m_priv)[ddd_var], sqrt(vcov(m_priv)[ddd_var, ddd_var])))

# ===========================================================================
# 6. Save robustness results
# ===========================================================================
robust_results <- list(
  placebo_female = placebo_f,
  cutoff_sensitivity = cutoff_df,
  ses_low = m_low, ses_high = m_high,
  school_public = m_pub, school_private = m_priv
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
