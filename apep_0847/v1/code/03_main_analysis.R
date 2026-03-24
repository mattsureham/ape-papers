# 03_main_analysis.R — Main analysis for apep_0847
# Continuous treatment DiD: baseline grant intensity × post-austerity
# Outcome: smoking prevalence, quit rates, COPD admissions

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
tab_dir  <- file.path(dirname(getwd()), "tables")

smoking_panel  <- readRDS(file.path(data_dir, "smoking_panel.rds"))
quits_panel    <- readRDS(file.path(data_dir, "quits_panel.rds"))
copd_panel     <- readRDS(file.path(data_dir, "copd_panel.rds"))
lung_panel     <- readRDS(file.path(data_dir, "lung_panel.rds"))
placebo_panel  <- readRDS(file.path(data_dir, "placebo_panel.rds"))
baseline       <- readRDS(file.path(data_dir, "grants_baseline.rds"))

cat("=== Main Analysis ===\n")

# ---- 1. Primary specification: Smoking prevalence ----
# Y_it = α_i + δ_t + β(baseline_z_i × post_t) + ε_it
# β < 0 means: LAs with higher baseline grants saw SLOWER smoking decline post-austerity
# β > 0 means: LAs with higher baseline grants saw FASTER smoking decline post-austerity
# We expect β > 0 (higher grants → worse austerity effect → LESS decline → higher prevalence)
# Wait: higher baseline_z means LA had MORE grant funding. After cuts, they lost more.
# If services were effective, losing more → less smoking decline → higher prevalence relative to trend
# So we expect β > 0 on smoking prevalence

cat("\n--- Smoking Prevalence ---\n")

# (1a) Simple DiD: continuous treatment × post
m_smoke_1 <- feols(value ~ treat_post | area_code + year_start,
                   data = smoking_panel, cluster = ~area_code)

# (1b) Event study: year-specific interactions
smoking_panel <- smoking_panel %>%
  mutate(
    # Omit 2014 as reference year (last pre-treatment year)
    year_x_treat = ifelse(year_start != 2014, baseline_z * 1, 0),
    es_year = ifelse(year_start == 2014, NA, year_start)
  )

m_smoke_es <- feols(value ~ i(year_start, baseline_z, ref = 2014) |
                      area_code + year_start,
                    data = smoking_panel, cluster = ~area_code)

cat("Smoking prevalence - DiD:\n")
summary(m_smoke_1)
cat("\nEvent study coefficients:\n")
print(coeftable(m_smoke_es))

# ---- 2. Quit rate ----
cat("\n--- Quit Rate ---\n")
# Quit rate data starts in 2013/14 — ref year = 2014 (i.e., 2014/15)
# Note: higher baseline_z + post → expect NEGATIVE coefficient
# (LAs that lost more funding → fewer quits)

m_quit_1 <- feols(value ~ treat_post | area_code + year_start,
                  data = quits_panel, cluster = ~area_code)

m_quit_es <- feols(value ~ i(year_start, baseline_z, ref = 2014) |
                     area_code + year_start,
                   data = quits_panel, cluster = ~area_code)

cat("Quit rate - DiD:\n")
summary(m_quit_1)
cat("\nEvent study coefficients:\n")
print(coeftable(m_quit_es))

# ---- 3. COPD emergency admissions ----
cat("\n--- COPD Emergency Admissions ---\n")
# Higher baseline_z + post → expect POSITIVE coefficient
# (LAs that lost more → more COPD admissions)

m_copd_1 <- feols(value ~ treat_post | area_code + year_start,
                  data = copd_panel, cluster = ~area_code)

m_copd_es <- feols(value ~ i(year_start, baseline_z, ref = 2014) |
                     area_code + year_start,
                   data = copd_panel, cluster = ~area_code)

cat("COPD admissions - DiD:\n")
summary(m_copd_1)
cat("\nEvent study coefficients:\n")
print(coeftable(m_copd_es))

# ---- 4. Lung cancer mortality ----
cat("\n--- Lung Cancer Mortality ---\n")

m_lung_1 <- feols(value ~ treat_post | area_code + year_start,
                  data = lung_panel, cluster = ~area_code)

m_lung_es <- feols(value ~ i(year_start, baseline_z, ref = 2014) |
                     area_code + year_start,
                   data = lung_panel, cluster = ~area_code)

cat("Lung cancer mortality - DiD:\n")
summary(m_lung_1)

# ---- 5. Placebo: Sexual health ----
cat("\n--- Placebo: Sexual Health Screening ---\n")

m_placebo_1 <- feols(value ~ treat_post | area_code + year_start,
                     data = placebo_panel, cluster = ~area_code)

cat("Placebo (sexual health) - DiD:\n")
summary(m_placebo_1)

# ---- 6. Save results ----
results <- list(
  smoking_did   = m_smoke_1,
  smoking_es    = m_smoke_es,
  quit_did      = m_quit_1,
  quit_es       = m_quit_es,
  copd_did      = m_copd_1,
  copd_es       = m_copd_es,
  lung_did      = m_lung_1,
  lung_es       = m_lung_es,
  placebo_did   = m_placebo_1
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ---- 7. Diagnostics for validator ----
n_treated <- n_distinct(smoking_panel$area_code[smoking_panel$post == 1])
n_pre     <- n_distinct(smoking_panel$year_start[smoking_panel$year_start < 2015])
n_obs     <- nrow(smoking_panel)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_clusters = n_distinct(smoking_panel$area_code),
    design = "continuous_treatment_did",
    treatment = "baseline_grant_pc_z_x_post",
    outcome_smoking = nrow(smoking_panel),
    outcome_quits = nrow(quits_panel),
    outcome_copd = nrow(copd_panel)
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("N treated LAs: %d, N pre-periods: %d, N obs: %d\n",
            n_treated, n_pre, n_obs))
