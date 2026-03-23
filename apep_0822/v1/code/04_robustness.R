# 04_robustness.R — Robustness checks for apep_0822

setwd(file.path(dirname(sys.frame(1)$ofile %||% "."), "."))
source("00_packages.R")

data_dir <- "../data/"
df <- readRDS(file.path(data_dir, "analysis.rds"))
df <- df %>% mutate(fea_pc_10 = fea_per_capita * 10, log_pop = log(total_pop))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ===========================================================================
# 1. Control for old-cohort literacy (baseline proxy)
# ===========================================================================
cat("--- R1: Controlling for old-cohort literacy ---\n")
# Key test: Does FeA predict young-cohort literacy ABOVE baseline?
r1 <- feols(lit_young ~ fea_pc_10 + lit_old + log_pop + urban_share | dept, data = df)
cat("Young literacy ~ FeA + Old literacy:\n")
print(summary(r1, se = "hetero"))

# ===========================================================================
# 2. Binary treatment (above/below median FeA)
# ===========================================================================
cat("\n--- R2: Binary treatment (high vs low FeA) ---\n")
df <- df %>% mutate(high_fea = as.integer(fea_per_capita > median(fea_per_capita)))
r2 <- feols(lit_cohort_gap ~ high_fea + log_pop + urban_share | dept, data = df)
print(summary(r2, se = "hetero"))

# ===========================================================================
# 3. Rural municipalities only (pop < 30,000)
# ===========================================================================
cat("\n--- R3: Rural municipalities only (pop < 30,000) ---\n")
df_rural <- df %>% filter(total_pop < 30000)
cat("Rural sample:", nrow(df_rural), "municipalities\n")
r3 <- feols(lit_cohort_gap ~ fea_pc_10 + log_pop + urban_share | dept, data = df_rural)
print(summary(r3, se = "hetero"))

# ===========================================================================
# 4. Exclude outliers (trim top/bottom 5% of FeA)
# ===========================================================================
cat("\n--- R4: Trimmed sample (5th-95th pctile FeA) ---\n")
q05 <- quantile(df$fea_per_capita, 0.05)
q95 <- quantile(df$fea_per_capita, 0.95)
df_trim <- df %>% filter(fea_per_capita >= q05, fea_per_capita <= q95)
cat("Trimmed sample:", nrow(df_trim), "municipalities\n")
r4 <- feols(lit_cohort_gap ~ fea_pc_10 + log_pop + urban_share | dept, data = df_trim)
print(summary(r4, se = "hetero"))

# ===========================================================================
# 5. Log FeA beneficiaries (alternative functional form)
# ===========================================================================
cat("\n--- R5: Log FeA beneficiaries ---\n")
df <- df %>% mutate(log_fea = log(fea_beneficiaries + 1))
r5 <- feols(lit_cohort_gap ~ log_fea + log_pop + urban_share | dept, data = df)
print(summary(r5, se = "hetero"))

# ===========================================================================
# 6. Placebo: Gender gap in literacy (FeA should not affect)
# ===========================================================================
cat("\n--- R6: Placebo — gender literacy gap ---\n")

# Construct gender literacy gap from raw data
literacy <- readRDS(file.path(data_dir, "census_literacy.rds"))

gender_lit <- literacy %>%
  filter(area == "total", grupo_de_edad == "de_15_anos_y_mas",
         sabe_leer_y_escribir %in% c("si", "total")) %>%
  mutate(val = as.numeric(total)) %>%
  select(codigo_municipio, sexo, sabe_leer_y_escribir, val) %>%
  pivot_wider(names_from = c(sexo, sabe_leer_y_escribir), values_from = val) %>%
  mutate(
    muni_code = codigo_municipio,
    lit_male = hombre_si / hombre_total,
    lit_female = mujer_si / mujer_total,
    gender_gap = lit_male - lit_female
  ) %>%
  select(muni_code, lit_male, lit_female, gender_gap)

df_gender <- df %>% left_join(gender_lit, by = "muni_code")

r6 <- feols(gender_gap ~ fea_pc_10 + log_pop + urban_share | dept,
            data = df_gender)
cat("Gender literacy gap ~ FeA (expect NULL):\n")
print(summary(r6, se = "hetero"))

# ===========================================================================
# 7. Panel specification (long form: two obs per municipality)
# ===========================================================================
cat("\n--- R7: Panel specification (municipality × cohort) ---\n")

panel <- bind_rows(
  df %>% mutate(cohort = "young", literacy = lit_young, young = 1),
  df %>% mutate(cohort = "old", literacy = lit_old, young = 0)
)

r7 <- feols(literacy ~ young:fea_pc_10 + young | muni_code,
            data = panel, cluster = ~ muni_code)
cat("Panel DiD (municipality FE):\n")
print(summary(r7))

# ===========================================================================
# 8. Quadratic FeA (nonlinearity check)
# ===========================================================================
cat("\n--- R8: Quadratic FeA intensity ---\n")
df <- df %>% mutate(fea_pc_10_sq = fea_pc_10^2)
r8 <- feols(lit_cohort_gap ~ fea_pc_10 + fea_pc_10_sq + log_pop + urban_share | dept,
            data = df)
print(summary(r8, se = "hetero"))

# Save robustness models
rob_models <- list(r1 = r1, r2 = r2, r3 = r3, r4 = r4, r5 = r5,
                   r6 = r6, r7 = r7, r8 = r8)
saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))

cat("\n=== All robustness checks complete ===\n")
