# 03_main_analysis.R — Main regressions for apep_0822
# Cohort-exposure design: FeA intensity → literacy gap and education

setwd(file.path(dirname(sys.frame(1)$ofile %||% "."), "."))
source("00_packages.R")

data_dir <- "../data/"
df <- readRDS(file.path(data_dir, "analysis.rds"))

cat("Analysis sample:", nrow(df), "municipalities\n")
cat("Departments:", n_distinct(df$dept), "\n")

# ===========================================================================
# 1. Main outcome: Cohort literacy gap
# ===========================================================================
cat("\n=== PANEL A: Cohort Literacy Gap ===\n")
cat("Does higher FeA intensity predict a larger improvement in literacy\n")
cat("for the young cohort (15-24) relative to the older cohort (25+)?\n\n")

# Scale FeA per capita by 10pp for interpretability
df <- df %>%
  mutate(
    fea_pc_10 = fea_per_capita * 10,  # effect of 10pp increase
    log_pop = log(total_pop)
  )

# Model 1: No controls
m1 <- feols(lit_cohort_gap ~ fea_pc_10, data = df)

# Model 2: Department FE
m2 <- feols(lit_cohort_gap ~ fea_pc_10 | dept, data = df)

# Model 3: Department FE + population + urban share
m3 <- feols(lit_cohort_gap ~ fea_pc_10 + log_pop + urban_share | dept, data = df)

# Model 4: Department FE + all controls
m4 <- feols(lit_cohort_gap ~ fea_pc_10 + log_pop + urban_share +
              share_female_head | dept, data = df)

cat("Model 1 (No controls):\n")
print(summary(m1, se = "hetero"))
cat("\nModel 2 (Dept FE):\n")
print(summary(m2, se = "hetero"))
cat("\nModel 3 (Dept FE + controls):\n")
print(summary(m3, se = "hetero"))

# ===========================================================================
# 2. Young cohort literacy level
# ===========================================================================
cat("\n=== PANEL B: Young Cohort Literacy Level ===\n")

m5 <- feols(lit_young ~ fea_pc_10 | dept, data = df)
m6 <- feols(lit_young ~ fea_pc_10 + log_pop + urban_share | dept, data = df)

cat("Young literacy ~ FeA (Dept FE):\n")
print(summary(m5, se = "hetero"))
cat("\nYoung literacy ~ FeA (Dept FE + controls):\n")
print(summary(m6, se = "hetero"))

# ===========================================================================
# 3. Old cohort literacy level (placebo — should NOT respond to FeA)
# ===========================================================================
cat("\n=== PANEL C: Old Cohort Literacy (Placebo) ===\n")

m7 <- feols(lit_old ~ fea_pc_10 | dept, data = df)
m8 <- feols(lit_old ~ fea_pc_10 + log_pop + urban_share | dept, data = df)

cat("Old literacy ~ FeA (Dept FE):\n")
print(summary(m7, se = "hetero"))
cat("\nOld literacy ~ FeA (Dept FE + controls):\n")
print(summary(m8, se = "hetero"))

# ===========================================================================
# 4. Education attainment outcomes
# ===========================================================================
cat("\n=== PANEL D: Education Attainment ===\n")

m9  <- feols(share_secondary_plus ~ fea_pc_10 + log_pop + urban_share | dept, data = df)
m10 <- feols(share_tertiary ~ fea_pc_10 + log_pop + urban_share | dept, data = df)
m11 <- feols(share_none ~ fea_pc_10 + log_pop + urban_share | dept, data = df)

cat("Secondary+ ~ FeA:\n"); print(summary(m9, se = "hetero"))
cat("\nTertiary ~ FeA:\n"); print(summary(m10, se = "hetero"))
cat("\nNo education ~ FeA:\n"); print(summary(m11, se = "hetero"))

# ===========================================================================
# 5. Employment outcomes
# ===========================================================================
cat("\n=== PANEL E: Employment ===\n")

m12 <- feols(emp_rate ~ fea_pc_10 + log_pop + urban_share | dept, data = df)
m13 <- feols(study_rate ~ fea_pc_10 + log_pop + urban_share | dept, data = df)

cat("Employment rate ~ FeA:\n"); print(summary(m12, se = "hetero"))
cat("\nStudy rate ~ FeA:\n"); print(summary(m13, se = "hetero"))

# ===========================================================================
# 6. Save all models and diagnostics
# ===========================================================================
models <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m5 = m5, m6 = m6, m7 = m7, m8 = m8,
  m9 = m9, m10 = m10, m11 = m11,
  m12 = m12, m13 = m13
)
saveRDS(models, file.path(data_dir, "models.rds"))

# Write diagnostics.json for validator
diag <- list(
  n_treated = sum(df$fea_per_capita > median(df$fea_per_capita)),
  n_pre = 1L,  # cross-sectional design
  n_obs = nrow(df),
  n_municipalities = nrow(df),
  n_departments = n_distinct(df$dept)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== All models saved ===\n")
cat("Diagnostics: n_obs =", diag$n_obs, ", n_municipalities =",
    diag$n_municipalities, "\n")
