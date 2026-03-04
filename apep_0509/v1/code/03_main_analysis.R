# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 03_main_analysis.R — Primary regressions
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
crop_long <- readRDS(file.path(data_dir, "crop_panel.rds"))
agg_panel <- readRDS(file.path(data_dir, "agg_panel.rds"))
wage_panel <- readRDS(file.path(data_dir, "wage_panel.rds"))
fert_panel <- readRDS(file.path(data_dir, "fert_panel.rds"))
baseline <- readRDS(file.path(data_dir, "baseline.rds"))

# ==============================================================================
# 1. FIRST STAGE: MGNREGA → Agricultural Wages
# ==============================================================================
cat("=== FIRST STAGE: MGNREGA → Agricultural Wages ===\n")

# --- 1a. Event study for wages using Sun & Abraham (2021) via fixest ---
wage_es <- feols(
  log_wage_male ~ sunab(first_treat_year, year) | dist_code + year,
  data = wage_panel,
  cluster = ~state_code
)
cat("\nFirst stage (Male wages, Sun & Abraham):\n")
summary(wage_es)

# --- 1b. Static DiD for wages ---
wage_static <- feols(
  log_wage_male ~ post | dist_code + year,
  data = wage_panel,
  cluster = ~state_code
)
cat("\nFirst stage (Static DiD):\n")
summary(wage_static)

# --- 1c. Female wages ---
wage_female_es <- feols(
  log_wage_female ~ sunab(first_treat_year, year) | dist_code + year,
  data = wage_panel[!is.na(log_wage_female)],
  cluster = ~state_code
)

# ==============================================================================
# 2. MAIN RESULTS: Crop-Specific Yield Effects
# ==============================================================================
cat("\n\n=== MAIN RESULTS: Crop-Specific Yield Effects ===\n")

# Key crops for detailed analysis
main_crops <- c("RICE", "WHEAT", "COTTON", "SUGARCANE",
                "MAIZE", "SORGHUM", "CHICKPEA", "GROUNDNUT")

# --- 2a. Event study for each crop ---
crop_es_results <- list()
for (crop_name in main_crops) {
  cat(sprintf("\n--- Event study: %s ---\n", crop_name))
  dt <- crop_long[crop == crop_name]
  if (nrow(dt) < 100) {
    cat("  Insufficient observations, skipping.\n")
    next
  }

  fit <- tryCatch(
    feols(log_yield ~ sunab(first_treat_year, year) | dist_code + year,
          data = dt, cluster = ~state_code),
    error = function(e) { cat("  Error:", e$message, "\n"); NULL }
  )

  if (!is.null(fit)) {
    crop_es_results[[crop_name]] <- fit
    cat(sprintf("  N = %d, ATT coefs estimated\n", nobs(fit)))
  }
}

# --- 2b. Static DiD by crop ---
crop_static_results <- list()
for (crop_name in main_crops) {
  dt <- crop_long[crop == crop_name]
  if (nrow(dt) < 100) next

  fit <- tryCatch(
    feols(log_yield ~ post | dist_code + year,
          data = dt, cluster = ~state_code),
    error = function(e) NULL
  )

  if (!is.null(fit)) {
    crop_static_results[[crop_name]] <- fit
  }
}

# Print static DiD results
cat("\n=== Static DiD Results by Crop ===\n")
for (crop_name in names(crop_static_results)) {
  fit <- crop_static_results[[crop_name]]
  coef_val <- coef(fit)["post"]
  se_val <- se(fit)["post"]
  pval <- pvalue(fit)["post"]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**",
                  ifelse(pval < 0.1, "*", "")))
  cat(sprintf("  %-20s: β = %7.4f (%7.4f) %s  [N = %d]\n",
              crop_name, coef_val, se_val, stars, nobs(fit)))
}

# --- 2c. Heterogeneous effects: Labor-intensive vs not ---
cat("\n\n=== HETEROGENEITY: Labor-Intensive vs Non-Labor-Intensive ===\n")

het_fit <- feols(
  log_yield ~ post:labor_intensive + post:i(labor_intensive, ref = FALSE) |
    dist_code^crop + year^crop,
  data = crop_long,
  cluster = ~state_code
)
cat("\nHeterogeneity (labor intensity interaction):\n")
summary(het_fit)

# Alternative: split-sample
labor_int_fit <- feols(
  log_yield ~ sunab(first_treat_year, year) | dist_code + year,
  data = crop_long[labor_intensive == TRUE],
  cluster = ~state_code
)

non_labor_int_fit <- feols(
  log_yield ~ sunab(first_treat_year, year) | dist_code + year,
  data = crop_long[labor_intensive == FALSE],
  cluster = ~state_code
)

# ==============================================================================
# 3. MECHANISM: Input Substitution
# ==============================================================================
cat("\n\n=== MECHANISM: Fertilizer Intensification ===\n")

# --- 3a. Fertilizer event study ---
fert_es <- feols(
  log_fert_total ~ sunab(first_treat_year, year) | dist_code + year,
  data = fert_panel[!is.na(log_fert_total)],
  cluster = ~state_code
)
cat("\nFertilizer per ha (event study):\n")
summary(fert_es)

# --- 3b. Fertilizer static ---
fert_static <- feols(
  log_fert_total ~ post | dist_code + year,
  data = fert_panel[!is.na(log_fert_total)],
  cluster = ~state_code
)
cat("\nFertilizer per ha (static DiD):\n")
summary(fert_static)

# --- 3c. By component (N, P, K) ---
fert_n <- feols(log(nitrogen_ha + 1) ~ sunab(first_treat_year, year) | dist_code + year,
                data = fert_panel[nitrogen_ha >= 0], cluster = ~state_code)
fert_p <- feols(log(phosphate_ha + 1) ~ sunab(first_treat_year, year) | dist_code + year,
                data = fert_panel[phosphate_ha >= 0], cluster = ~state_code)

# ==============================================================================
# 4. AGGREGATE RESULTS
# ==============================================================================
cat("\n\n=== AGGREGATE: Area-Weighted Average Yield ===\n")

agg_es <- feols(
  log_avg_yield ~ sunab(first_treat_year, year) | dist_code + year,
  data = agg_panel,
  cluster = ~state_code
)
summary(agg_es)

# Labor-intensive crop share
li_share_es <- feols(
  labor_intensive_share ~ sunab(first_treat_year, year) | dist_code + year,
  data = agg_panel,
  cluster = ~state_code
)

# ==============================================================================
# 5. Save all results
# ==============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  wage_es = wage_es,
  wage_static = wage_static,
  wage_female_es = wage_female_es,
  crop_es = crop_es_results,
  crop_static = crop_static_results,
  het_fit = het_fit,
  labor_int_fit = labor_int_fit,
  non_labor_int_fit = non_labor_int_fit,
  fert_es = fert_es,
  fert_static = fert_static,
  fert_n = fert_n,
  fert_p = fert_p,
  agg_es = agg_es,
  li_share_es = li_share_es
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("All results saved to main_results.rds\n")
