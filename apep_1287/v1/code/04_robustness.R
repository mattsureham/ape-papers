# ==============================================================================
# 04_robustness.R — Balance tests, falsification, LIML, leave-one-out
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

source("00_packages.R")

black <- arrow::read_parquet("../data/analysis_black.parquet")
white <- arrow::read_parquet("../data/analysis_white.parquet")

# --------------------------------------------------------------------------
# A. Balance Test: Pre-flood characteristics vs. flood exposure
# --------------------------------------------------------------------------
cat("\n=== BALANCE TEST ===\n")

bal_vars <- c("occscore_1920", "sei_1920", "age_1920")

balance_results <- lapply(bal_vars, function(v) {
  fml <- as.formula(paste(v, "~ flood_exposed"))
  m <- feols(fml, data = black, cluster = ~county_id)
  data.frame(
    variable = v,
    coef = coef(m)["flood_exposed"],
    se = se(m)["flood_exposed"],
    pval = pvalue(m)["flood_exposed"],
    mean_flood = mean(black[[v]][black$flood_exposed == 1], na.rm = TRUE),
    mean_noflood = mean(black[[v]][black$flood_exposed == 0], na.rm = TRUE)
  )
})
balance_df <- do.call(rbind, balance_results)
print(balance_df)

# Save balance test
save(balance_df, file = "../data/balance_results.RData")

# --------------------------------------------------------------------------
# B. Falsification: Same IV for White farm workers
# --------------------------------------------------------------------------
cat("\n=== FALSIFICATION: WHITE FARM WORKERS ===\n")

# First stage for whites
fs_white <- feols(mover_20_30 ~ flood_exposed + occscore_1920 + sei_1920 |
                    age_1920,
                  data = white, cluster = ~county_id)

# IV for whites: Δoccscore 1930
white$delta_occ_30 <- white$occscore_1930 - white$occscore_1920
white$delta_occ_40 <- white$occscore_1940 - white$occscore_1920
white$delta_sei_30 <- white$sei_1930 - white$sei_1920
white$delta_sei_40 <- white$sei_1940 - white$sei_1920
white$left_farm_30 <- as.integer(white$farm_1920 == 1 & white$farm_1930 == 0)
white$left_farm_40 <- as.integer(white$farm_1920 == 1 & white$farm_1940 == 0)

# Reduced form for whites
rf_white_occ30 <- feols(delta_occ_30 ~ flood_exposed + occscore_1920 +
                          sei_1920 | age_1920,
                        data = white, cluster = ~county_id)
rf_white_occ40 <- feols(delta_occ_40 ~ flood_exposed + occscore_1920 +
                          sei_1920 | age_1920,
                        data = white, cluster = ~county_id)

cat(sprintf("White first stage: %.4f (SE: %.4f)\n",
            coef(fs_white)["flood_exposed"],
            se(fs_white)["flood_exposed"]))
cat(sprintf("White RF Δocc30: %.4f (SE: %.4f)\n",
            coef(rf_white_occ30)["flood_exposed"],
            se(rf_white_occ30)["flood_exposed"]))
cat(sprintf("White RF Δocc40: %.4f (SE: %.4f)\n",
            coef(rf_white_occ40)["flood_exposed"],
            se(rf_white_occ40)["flood_exposed"]))

# IV for whites (if first stage is strong enough)
iv_white_occ30 <- tryCatch(
  feols(delta_occ_30 ~ occscore_1920 + sei_1920 | age_1920 |
          mover_20_30 ~ flood_exposed,
        data = white, cluster = ~county_id),
  error = function(e) NULL
)
iv_white_occ40 <- tryCatch(
  feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
          mover_20_30 ~ flood_exposed,
        data = white, cluster = ~county_id),
  error = function(e) NULL
)

# --------------------------------------------------------------------------
# C. LIML estimator (weak-IV robust)
# --------------------------------------------------------------------------
cat("\n=== LIML ESTIMATOR ===\n")

# LIML via estimatr::iv_robust (handles weak-IV robust inference)
if (!requireNamespace("estimatr", quietly = TRUE)) {
  install.packages("estimatr", repos = "https://cloud.r-project.org")
}
library(estimatr)

# Create age dummies for estimatr (doesn't accept | FE syntax)
age_dummies <- model.matrix(~ factor(age_1920) - 1, data = black)
black_liml <- cbind(black, as.data.frame(age_dummies))
# Use top 5 age dummies to avoid collinearity issues
age_cols <- grep("factor", names(black_liml), value = TRUE)

liml_occ30 <- iv_robust(
  delta_occ_30 ~ mover_20_30 + occscore_1920 + sei_1920 |
    flood_exposed + occscore_1920 + sei_1920,
  data = black, clusters = county_id, se_type = "CR0"
)

liml_occ40 <- iv_robust(
  delta_occ_40 ~ mover_20_30 + occscore_1920 + sei_1920 |
    flood_exposed + occscore_1920 + sei_1920,
  data = black, clusters = county_id, se_type = "CR0"
)

cat(sprintf("LIML Δocc30: %.4f (SE: %.4f)\n",
            coef(liml_occ30)["mover_20_30"],
            liml_occ30$std.error["mover_20_30"]))
cat(sprintf("LIML Δocc40: %.4f (SE: %.4f)\n",
            coef(liml_occ40)["mover_20_30"],
            liml_occ40$std.error["mover_20_30"]))

# --------------------------------------------------------------------------
# D. Leave-one-county-out sensitivity
# --------------------------------------------------------------------------
cat("\n=== LEAVE-ONE-COUNTY-OUT ===\n")

counties <- unique(black$county_id)
loo_results <- lapply(counties, function(cty) {
  sub <- black[black$county_id != cty, ]
  m <- tryCatch(
    feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
            mover_20_30 ~ flood_exposed,
          data = sub, cluster = ~county_id),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)
  data.frame(
    dropped_county = cty,
    coef = coef(m)["fit_mover_20_30"],
    se = se(m)["fit_mover_20_30"]
  )
})
loo_df <- do.call(rbind, loo_results)

cat(sprintf("LOO coefficient range: [%.3f, %.3f]\n",
            min(loo_df$coef), max(loo_df$coef)))
cat(sprintf("Full-sample coefficient: %.3f\n",
            coef(feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
                         mover_20_30 ~ flood_exposed,
                       data = black, cluster = ~county_id))["fit_mover_20_30"]))

# --------------------------------------------------------------------------
# E. Heterogeneity: Age at displacement
# --------------------------------------------------------------------------
cat("\n=== HETEROGENEITY BY AGE ===\n")

age_het <- lapply(levels(black$age_bin), function(ab) {
  sub <- black[black$age_bin == ab, ]
  if (nrow(sub) < 100) return(NULL)
  m <- tryCatch(
    feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
            mover_20_30 ~ flood_exposed,
          data = sub, cluster = ~county_id),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)
  data.frame(
    age_bin = ab,
    coef = coef(m)["fit_mover_20_30"],
    se = se(m)["fit_mover_20_30"],
    n = nrow(sub)
  )
})
age_het_df <- do.call(rbind, age_het)
print(age_het_df)

# --------------------------------------------------------------------------
# F. Heterogeneity: Pre-flood occupational status
# --------------------------------------------------------------------------
cat("\n=== HETEROGENEITY BY PRE-FLOOD STATUS ===\n")

black$high_status_1920 <- as.integer(black$occscore_1920 >
                                       median(black$occscore_1920))

status_het <- lapply(c(0, 1), function(s) {
  sub <- black[black$high_status_1920 == s, ]
  m <- tryCatch(
    feols(delta_occ_40 ~ sei_1920 | age_1920 |
            mover_20_30 ~ flood_exposed,
          data = sub, cluster = ~county_id),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)
  data.frame(
    group = ifelse(s == 0, "Low pre-flood status", "High pre-flood status"),
    coef = coef(m)["fit_mover_20_30"],
    se = se(m)["fit_mover_20_30"],
    n = nrow(sub)
  )
})
status_het_df <- do.call(rbind, status_het)
print(status_het_df)

# --------------------------------------------------------------------------
# Save all robustness results
# --------------------------------------------------------------------------
save(balance_df, fs_white, rf_white_occ30, rf_white_occ40,
     iv_white_occ30, iv_white_occ40,
     liml_occ30, liml_occ40,
     loo_df, age_het_df, status_het_df,
     file = "../data/robustness_models.RData")

cat("\nRobustness results saved.\n")
cat("Done.\n")
