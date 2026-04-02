## 03_main_analysis.R — Main regressions
## apep_1317: Colombia draft lottery and wartime conscription

source("00_packages.R")
data_dir <- "../data"

saber11 <- readRDS(file.path(data_dir, "saber11_analysis.rds"))
saberpro <- readRDS(file.path(data_dir, "saberpro_analysis.rds"))

cat("=== MAIN ANALYSIS ===\n")
cat(sprintf("Saber 11: N = %d\n", nrow(saber11)))
cat(sprintf("Saber Pro: N = %d\n", nrow(saberpro)))

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

# Panel A: Full sample
sumstats <- saber11 %>%
  group_by(male) %>%
  summarise(
    N = n(),
    mean_math = mean(math_score, na.rm = TRUE),
    sd_math = sd(math_score, na.rm = TRUE),
    mean_eng = mean(eng_score, na.rm = TRUE),
    sd_eng = sd(eng_score, na.rm = TRUE),
    mean_stratum = mean(stratum, na.rm = TRUE),
    pct_public = 100 * mean(public_school, na.rm = TRUE),
    pct_rural = 100 * mean(rural, na.rm = TRUE),
    pct_conflict_cohort = 100 * mean(conflict_cohort),
    pct_high_conflict = 100 * mean(high_conflict),
    .groups = "drop"
  )

print(sumstats)

# Panel B: By conflict intensity and cohort
sumstats_treat <- saber11 %>%
  group_by(high_conflict, conflict_cohort, male) %>%
  summarise(
    N = n(),
    mean_math = mean(math_score, na.rm = TRUE),
    sd_math = sd(math_score, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nMean math scores by treatment group:\n")
print(sumstats_treat %>% arrange(high_conflict, conflict_cohort, male))

# ===========================================================================
# TABLE 2: Main DDD Results — Math Scores
# ===========================================================================
cat("\n--- Table 2: Triple-Difference (Math Scores) ---\n")

# Model 1: Simple DD (Male × Conflict Cohort)
m1 <- feols(math_score ~ male * conflict_cohort |
              exam_year + dept_std,
            data = saber11, cluster = ~dept_std)

# Model 2: DD with controls
m2 <- feols(math_score ~ male * conflict_cohort +
              public_school + rural + stratum |
              exam_year + dept_std,
            data = saber11, cluster = ~dept_std)

# Model 3: Full DDD (Male × High Conflict × Conflict Cohort)
m3 <- feols(math_score ~ male * high_conflict * conflict_cohort |
              exam_year + dept_std,
            data = saber11, cluster = ~dept_std)

# Model 4: DDD with controls
m4 <- feols(math_score ~ male * high_conflict * conflict_cohort +
              public_school + rural + stratum |
              exam_year + dept_std,
            data = saber11, cluster = ~dept_std)

# Model 5: Continuous conflict intensity
m5 <- feols(math_score ~ male * conflict_intensity * conflict_cohort +
              public_school + rural + stratum |
              exam_year + dept_std,
            data = saber11, cluster = ~dept_std)

cat("\n=== DDD RESULTS: MATH SCORES ===\n")
cat("\nModel 1 (DD: Male x Conflict Cohort):\n")
print(summary(m1))
cat("\nModel 3 (DDD: Male x High Conflict x Conflict Cohort):\n")
print(summary(m3))
cat("\nModel 4 (DDD with controls):\n")
print(summary(m4))
cat("\nModel 5 (Continuous intensity):\n")
print(summary(m5))

# ===========================================================================
# TABLE 3: English Score Results
# ===========================================================================
cat("\n--- Table 3: English Scores ---\n")

eng_data <- saber11 %>% filter(!is.na(eng_score))

m_eng1 <- feols(eng_score ~ male * conflict_cohort |
                  exam_year + dept_std,
                data = eng_data, cluster = ~dept_std)

m_eng2 <- feols(eng_score ~ male * high_conflict * conflict_cohort |
                  exam_year + dept_std,
                data = eng_data, cluster = ~dept_std)

m_eng3 <- feols(eng_score ~ male * high_conflict * conflict_cohort +
                  public_school + rural + stratum |
                  exam_year + dept_std,
                data = eng_data, cluster = ~dept_std)

cat("\nDD (English):\n")
print(summary(m_eng1))
cat("\nDDD (English):\n")
print(summary(m_eng3))

# ===========================================================================
# TABLE 4: Saber Pro Results (University Exit Exam)
# ===========================================================================
cat("\n--- Table 4: Saber Pro (University Exit) ---\n")

if (nrow(saberpro) > 500) {
  sp_m1 <- feols(quant_score ~ male * conflict_cohort |
                   exam_year + dept_std,
                 data = saberpro, cluster = ~dept_std)

  sp_m2 <- feols(quant_score ~ male * as.integer(high_conflict) * conflict_cohort |
                   exam_year + dept_std,
                 data = saberpro, cluster = ~dept_std)

  cat("\nSaber Pro DD (Quantitative Reasoning):\n")
  print(summary(sp_m1))
  cat("\nSaber Pro DDD:\n")
  print(summary(sp_m2))
}

# ===========================================================================
# Save results for tables
# ===========================================================================

results <- list(
  # Summary stats
  sumstats = sumstats,
  sumstats_treat = sumstats_treat,
  # Main math models
  math_dd = m1, math_dd_ctrl = m2,
  math_ddd = m3, math_ddd_ctrl = m4,
  math_continuous = m5,
  # English models
  eng_dd = m_eng1, eng_ddd = m_eng2, eng_ddd_ctrl = m_eng3,
  # Saber Pro
  sp_dd = if (nrow(saberpro) > 500) sp_m1 else NULL,
  sp_ddd = if (nrow(saberpro) > 500) sp_m2 else NULL
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ===========================================================================
# Diagnostics for validation
# ===========================================================================
n_treated <- sum(saber11$ddd == 1)
n_pre <- length(unique(saber11$exam_year[saber11$conflict_cohort == 0]))
n_obs <- nrow(saber11)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_departments = n_distinct(saber11$dept_std),
  n_high_conflict_depts = sum(unique(saber11[saber11$high_conflict == TRUE, "dept_std"]) != ""),
  birth_year_range = paste(range(saber11$birth_year), collapse = "-"),
  exam_year_range = paste(range(saber11$exam_year), collapse = "-"),
  ddd_coef_math = coef(m4)["male:high_conflictTRUE:conflict_cohort"],
  ddd_se_math = sqrt(vcov(m4)["male:high_conflictTRUE:conflict_cohort",
                                "male:high_conflictTRUE:conflict_cohort"]),
  sd_math = sd(saber11$math_score, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("N treated (DDD=1): %d\n", n_treated))
cat(sprintf("N pre-periods (post-peace exam years): %d\n", n_pre))
cat(sprintf("N total: %d\n", n_obs))
cat(sprintf("DDD coefficient (math): %.3f (SE: %.3f)\n",
            diagnostics$ddd_coef_math, diagnostics$ddd_se_math))
cat(sprintf("SD(math): %.2f\n", diagnostics$sd_math))
cat(sprintf("SDE: %.4f\n", diagnostics$ddd_coef_math / diagnostics$sd_math))

cat("\nMain analysis complete.\n")
