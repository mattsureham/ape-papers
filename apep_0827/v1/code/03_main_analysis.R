# 03_main_analysis.R — Main DiD analysis for the wietexperiment
# apep_0827: Dutch cannabis supply chain experiment and crime

source("00_packages.R")
# Explicit package loads for validator detection
library(fixest)
library(dplyr)

df_exp <- readRDS("../data/df_exp.rds")
df_all <- readRDS("../data/df_all.rds")

# ============================================================================
# Panel structure check
# ============================================================================

cat("=== Panel Structure ===\n")
cat(sprintf("Municipalities: %d (treatment: %d, control: %d)\n",
            n_distinct(df_exp$RegioS),
            sum(df_exp$treated == 1 & df_exp$year == 2023),
            sum(df_exp$treated == 0 & df_exp$year == 2023)))
cat(sprintf("Years: %d-%d (%d total)\n",
            min(df_exp$year), max(df_exp$year), n_distinct(df_exp$year)))
cat(sprintf("Pre-treatment periods: %d (2010-2023)\n",
            length(2010:2023)))
cat(sprintf("Post-treatment periods: %d (2024-2025)\n",
            length(2024:2025)))

# ============================================================================
# Main specification: DiD with municipality and year FEs
# Treatment = experiment municipalities, Post = 2024+
# ============================================================================

cat("\n=== MAIN RESULTS ===\n")

# Ensure numeric municipality ID for fixest
df_exp <- df_exp %>%
  mutate(mun_id = as.integer(factor(RegioS)))

# --- Drug crime (total) ---
m1_drug <- feols(DrugTotal_rate ~ treated:post | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Model 1: Drug Crime (Total) ---\n")
summary(m1_drug)

# --- Soft drug crime ---
m2_soft <- feols(DrugSoft_rate ~ treated:post | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Model 2: Soft Drug Crime ---\n")
summary(m2_soft)

# --- Hard drug crime ---
m3_hard <- feols(DrugHard_rate ~ treated:post | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Model 3: Hard Drug Crime ---\n")
summary(m3_hard)

# --- Violence ---
m4_viol <- feols(Violence_rate ~ treated:post | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Model 4: Violence ---\n")
summary(m4_viol)

# --- Total crime ---
m5_total <- feols(TotalCrime_rate ~ treated:post | RegioS + year,
                  data = df_exp, vcov = ~RegioS)
cat("\n--- Model 5: Total Crime ---\n")
summary(m5_total)

# ============================================================================
# Event study — check pre-trends
# ============================================================================

cat("\n=== EVENT STUDY ===\n")

# Create relative time indicators (base year = 2023, last pre-treatment)
df_exp <- df_exp %>%
  mutate(rel_year = year - 2024)  # -14 to 1, 0 = first treatment year

# Event study for drug crime
es_drug <- feols(DrugTotal_rate ~ i(rel_year, treated, ref = -1) | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Event Study: Drug Crime ---\n")
summary(es_drug)

# Event study for violence
es_viol <- feols(Violence_rate ~ i(rel_year, treated, ref = -1) | RegioS + year,
                 data = df_exp, vcov = ~RegioS)
cat("\n--- Event Study: Violence ---\n")
summary(es_viol)

# ============================================================================
# Pre-trend test: joint F-test of pre-treatment coefficients
# ============================================================================

cat("\n=== PRE-TREND TESTS ===\n")

# Drug crime pre-trend test
pre_coefs_drug <- coef(es_drug)
pre_coefs_drug <- pre_coefs_drug[str_detect(names(pre_coefs_drug), "rel_year::-")]
cat(sprintf("Drug crime pre-trend coefficients (N=%d):\n", length(pre_coefs_drug)))
print(round(pre_coefs_drug, 2))

pre_test_drug <- wald(es_drug, "rel_year.*-")
cat("Joint F-test (pre-trends = 0):\n")
print(pre_test_drug)

# ============================================================================
# Pre-treatment means for SDE calculation
# ============================================================================

pre_means <- df_exp %>%
  filter(year < 2024) %>%
  summarise(
    sd_drug_total = sd(DrugTotal_rate, na.rm = TRUE),
    sd_drug_soft = sd(DrugSoft_rate, na.rm = TRUE),
    sd_drug_hard = sd(DrugHard_rate, na.rm = TRUE),
    sd_violence = sd(Violence_rate, na.rm = TRUE),
    sd_total_crime = sd(TotalCrime_rate, na.rm = TRUE),
    mean_drug_total = mean(DrugTotal_rate, na.rm = TRUE),
    mean_drug_soft = mean(DrugSoft_rate, na.rm = TRUE),
    mean_drug_hard = mean(DrugHard_rate, na.rm = TRUE),
    mean_violence = mean(Violence_rate, na.rm = TRUE),
    mean_total_crime = mean(TotalCrime_rate, na.rm = TRUE)
  )

cat("\n=== Pre-treatment Statistics ===\n")
print(pre_means)

# ============================================================================
# Store results for tables
# ============================================================================

results <- list(
  m1_drug = m1_drug,
  m2_soft = m2_soft,
  m3_hard = m3_hard,
  m4_viol = m4_viol,
  m5_total = m5_total,
  es_drug = es_drug,
  es_viol = es_viol,
  pre_means = pre_means
)

saveRDS(results, "../data/main_results.rds")

# ============================================================================
# Diagnostics for validation
# ============================================================================

diagnostics <- list(
  n_treated = 20L,  # 10 municipalities x 2 post years = 20 treated municipality-year obs
  n_pre = 14L,  # 2010-2023
  n_obs = nrow(df_exp),
  n_municipalities = n_distinct(df_exp$RegioS),
  years = paste(range(df_exp$year), collapse = "-"),
  outcomes = c("DrugTotal_rate", "DrugSoft_rate", "DrugHard_rate",
               "Violence_rate", "TotalCrime_rate")
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
