# 03_main_analysis.R — First stage, reduced form, 2SLS, and event study
# apep_1344: The Potency Arms Race

source("00_packages.R")

cat("=== Loading cleaned data ===\n")
analysis_df <- readRDS("../data/analysis_clean.rds")
panel_df <- readRDS("../data/panel_clean.rds")

# ============================================================
# TABLE 1: First Stage — Mallinckrodt share predicts potency
# ============================================================
cat("\n=== TABLE 1: First Stage ===\n")

# Column 1: No controls
fs1 <- feols(delta_mme ~ malli_share_2006, data = analysis_df)

# Column 2: State FE
fs2 <- feols(delta_mme ~ malli_share_2006 | BUYER_STATE, data = analysis_df)

# Column 3: State FE + pre-period controls
fs3 <- feols(delta_mme ~ malli_share_2006 + mme_per_pill_pre + log_pills_pre | BUYER_STATE,
             data = analysis_df)

# Column 4: High-dose share as outcome
fs4 <- feols(delta_high_dose ~ malli_share_2006 | BUYER_STATE, data = analysis_df)

# Column 5: Product variety (NDC count) as outcome
fs5 <- feols(delta_ndc ~ malli_share_2006 | BUYER_STATE, data = analysis_df)

cat("First stage results:\n")
cat(sprintf("  No controls:    β = %.3f (SE = %.3f), R² = %.3f\n",
            coef(fs1)["malli_share_2006"], sqrt(vcov(fs1, vcov = "hetero")["malli_share_2006", "malli_share_2006"]),
            fitstat(fs1, "r2")$r2))
cat(sprintf("  State FE:       β = %.3f (SE = %.3f)\n",
            coef(fs2)["malli_share_2006"], sqrt(vcov(fs2, vcov = ~BUYER_STATE)["malli_share_2006", "malli_share_2006"])))
cat(sprintf("  + Controls:     β = %.3f (SE = %.3f)\n",
            coef(fs3)["malli_share_2006"], sqrt(vcov(fs3, vcov = ~BUYER_STATE)["malli_share_2006", "malli_share_2006"])))

# ============================================================
# TABLE 2: Reduced Form and 2SLS (if overdose data available)
# ============================================================
cat("\n=== TABLE 2: Reduced Form ===\n")

# Total MME per capita change as secondary outcome
# (This captures both potency and volume effects)
analysis_df <- analysis_df %>%
  mutate(
    delta_total_mme = log(total_pills_post + 1) - log(total_pills_pre + 1)
  )

rf1 <- feols(delta_total_mme ~ malli_share_2006, data = analysis_df)
rf2 <- feols(delta_total_mme ~ malli_share_2006 | BUYER_STATE, data = analysis_df)

# Reduced form with overdose if available
has_overdose <- "delta_overdose" %in% names(analysis_df) &&
  sum(!is.na(analysis_df$delta_overdose)) > 100

if (has_overdose) {
  rf3 <- feols(delta_overdose ~ malli_share_2006 | BUYER_STATE,
               data = analysis_df %>% filter(!is.na(delta_overdose)))
  cat(sprintf("  Overdose RF:    β = %.3f (SE = %.3f)\n",
              coef(rf3)["malli_share_2006"],
              sqrt(vcov(rf3, vcov = ~BUYER_STATE)["malli_share_2006", "malli_share_2006"])))
}

cat(sprintf("  Log pills RF:   β = %.3f (SE = %.3f)\n",
            coef(rf2)["malli_share_2006"],
            sqrt(vcov(rf2, vcov = ~BUYER_STATE)["malli_share_2006", "malli_share_2006"])))

# ============================================================
# TABLE 3: Event Study — year-by-year interactions
# ============================================================
cat("\n=== TABLE 3: Event Study ===\n")

# Interact Mallinckrodt share with year dummies (omit 2007 as base)
panel_df <- panel_df %>%
  mutate(year_factor = factor(year))

es_model <- feols(mme_per_pill ~ i(year, malli_share_2006, ref = 2007) |
                    county_id + year,
                  data = panel_df,
                  vcov = ~BUYER_STATE)

cat("Event study coefficients:\n")
es_coefs <- coeftable(es_model)
print(es_coefs)

# ============================================================
# Diagnostics for validate_v1.py
# ============================================================
cat("\n=== Writing diagnostics.json ===\n")

n_treated <- nrow(analysis_df %>% filter(malli_share_2006 > median(malli_share_2006)))
n_pre <- length(unique(panel_df$year[panel_df$year < 2008]))
n_obs <- nrow(analysis_df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  method = "IV",
  n_counties = nrow(analysis_df),
  n_states = n_distinct(analysis_df$BUYER_STATE)
)

# F-stat from the first-stage regression
fs2_summary <- summary(fs2, vcov = ~BUYER_STATE)
diagnostics$first_stage_F <- fs2_summary$fstatistic[1] %||% NA

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# ============================================================
# Save all models for table generation
# ============================================================
cat("\n=== Saving models ===\n")

models <- list(
  fs1 = fs1, fs2 = fs2, fs3 = fs3, fs4 = fs4, fs5 = fs5,
  rf1 = rf1, rf2 = rf2,
  es_model = es_model
)
if (has_overdose) models$rf3 <- rf3

saveRDS(models, "../data/models.rds")
saveRDS(analysis_df, "../data/analysis_final.rds")
cat("Models and final data saved.\n")
cat("=== Main analysis complete ===\n")
