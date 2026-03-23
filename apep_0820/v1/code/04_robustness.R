## 04_robustness.R — Robustness and placebo tests
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

source("00_packages.R")

DATA_DIR <- normalizePath("../data", mustWork = FALSE)
TABLE_DIR <- normalizePath("../tables", mustWork = FALSE)

df <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

df <- df %>%
  mutate(close = mean_dist_km <= 25,
         many_fac = n_facilities >= median(n_facilities, na.rm = TRUE),
         low_exposure = pred_exposure <= quantile(pred_exposure, 0.25, na.rm = TRUE))

cat("=== Distance Heterogeneity ===\n")
rob_close <- feols(test_score_std ~ pred_exposure_std | ncessch + year,
                    data = filter(df, close), cluster = ~fips_county)
rob_far <- feols(test_score_std ~ pred_exposure_std | ncessch + year,
                  data = filter(df, !close), cluster = ~fips_county)
cat("Close (≤25km):", round(coef(rob_close)["pred_exposure_std"], 4),
    "SE:", round(se(rob_close)["pred_exposure_std"], 4), "\n")
cat("Far (>25km):", round(coef(rob_far)["pred_exposure_std"], 4),
    "SE:", round(se(rob_far)["pred_exposure_std"], 4), "\n")

cat("\n=== Placebo: Low Exposure Schools ===\n")
rob_placebo <- feols(test_score_std ~ pred_exposure_std | ncessch + year,
                      data = filter(df, low_exposure), cluster = ~fips_county)
cat("Low exposure:", round(coef(rob_placebo)["pred_exposure_std"], 4),
    "SE:", round(se(rob_placebo)["pred_exposure_std"], 4), "\n")

cat("\n=== State Clustering ===\n")
rob_state <- feols(test_score_std ~ pred_exposure_std | ncessch + year,
                    data = df, cluster = ~fips_state)
cat("State cluster:", round(coef(rob_state)["pred_exposure_std"], 4),
    "SE:", round(se(rob_state)["pred_exposure_std"], 4), "\n")

cat("\n=== Placebo Outcome: Facility Count ===\n")
rob_fac <- feols(n_facilities ~ pred_exposure_std | ncessch + year,
                  data = df, cluster = ~fips_county)
cat("Facility count:", round(coef(rob_fac)["pred_exposure_std"], 4),
    "SE:", round(se(rob_fac)["pred_exposure_std"], 4), "\n")

# Robustness table
rob_models <- list(
  "Baseline" = feols(test_score_std ~ pred_exposure_std | ncessch + year,
                      data = df, cluster = ~fips_county),
  "Close (≤25km)" = rob_close,
  "Far (>25km)" = rob_far,
  "State×Year FE" = feols(test_score_std ~ pred_exposure_std | ncessch + fips_state^year,
                            data = df, cluster = ~fips_county),
  "State Cluster" = rob_state
)

msummary(rob_models,
         output = file.path(TABLE_DIR, "tab3_robustness.tex"),
         stars = c('*' = 0.10, '**' = 0.05, '***' = 0.01),
         coef_map = c("pred_exposure_std" = "Predicted exposure (std.)"),
         gof_map = c("nobs", "r.squared"),
         title = "Robustness: Distance Heterogeneity and Alternative Specifications",
         notes = "Clustered SE in parentheses. All specs include school + year FE unless noted.")

# Placebo table
placebo_models <- list(
  "Baseline" = feols(test_score_std ~ pred_exposure_std | ncessch + year,
                      data = df, cluster = ~fips_county),
  "Low Exposure" = rob_placebo,
  "Facility Count" = rob_fac
)

msummary(placebo_models,
         output = file.path(TABLE_DIR, "tab4_placebo.tex"),
         stars = c('*' = 0.10, '**' = 0.05, '***' = 0.01),
         coef_map = c("pred_exposure_std" = "Predicted exposure (std.)"),
         gof_map = c("nobs", "r.squared"),
         title = "Placebo and Falsification Tests",
         notes = "Col 1: baseline. Col 2: bottom quartile of exposure. Col 3: placebo outcome.")

saveRDS(list(rob_close = rob_close, rob_far = rob_far,
             rob_state = rob_state, rob_placebo = rob_placebo, rob_fac = rob_fac),
        file.path(DATA_DIR, "robustness_models.rds"))

cat("\n04_robustness.R COMPLETE\n")
