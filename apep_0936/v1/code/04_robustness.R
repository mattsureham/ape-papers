# 04_robustness.R — Robustness checks and diagnostics

source("00_packages.R")
library(fixest)

data_dir <- "../data/"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "main_models.RData"))

# ===========================================================================
# 1. Wild cluster bootstrap (few clusters correction)
# ===========================================================================
message("=== 1. Wild cluster bootstrap ===")

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  # Bootstrap the main TWFE specification
  twfe_boot <- feols(berd_gdp_pct ~ post | geo + year,
                     data = panel,
                     cluster = ~country)

  boot_result <- tryCatch({
    boottest(twfe_boot, param = "post",
             clustid = ~country,
             B = 9999,
             type = "webb")
  }, error = function(e) {
    message("Wild bootstrap error: ", e$message)
    NULL
  })

  if (!is.null(boot_result)) {
    message("Wild cluster bootstrap p-value: ", round(boot_result$p_val, 4))
    message("Bootstrap CI: [", round(boot_result$conf_int[1], 4), ", ",
            round(boot_result$conf_int[2], 4), "]")
  }
} else {
  message("fwildclusterboot not available — skipping")
  boot_result <- NULL
}

# ===========================================================================
# 2. Placebo test: pre-treatment trend test
# ===========================================================================
message("\n=== 2. Pre-trend test ===")

# Create a fake "treatment" 2 years before actual transposition
panel[, placebo_post := fifelse(!is.na(transposition_year) &
                                  year >= (transposition_year - 2), 1L, 0L)]
# But only in the pre-treatment period
panel[, placebo_post := fifelse(year >= transposition_year, NA_integer_, placebo_post)]

placebo_twfe <- feols(berd_gdp_pct ~ placebo_post | geo + year,
                      data = panel[!is.na(placebo_post)],
                      cluster = ~country)
message("Placebo (2yr early): ", round(coef(placebo_twfe)["placebo_post"], 4),
        " (SE: ", round(se(placebo_twfe)["placebo_post"], 4), ")")

# ===========================================================================
# 3. Leave-one-country-out
# ===========================================================================
message("\n=== 3. Leave-one-country-out ===")

countries_treated <- unique(panel[first_treat > 0, country])
loo_results <- data.table(
  dropped = character(),
  coef = numeric(),
  se = numeric()
)

for (cc in countries_treated) {
  loo_fit <- feols(berd_gdp_pct ~ post | geo + year,
                   data = panel[country != cc],
                   cluster = ~country)
  loo_results <- rbind(loo_results, data.table(
    dropped = cc,
    coef = coef(loo_fit)["post"],
    se = se(loo_fit)["post"]
  ))
}

message("Leave-one-out range: [",
        round(min(loo_results$coef), 4), ", ",
        round(max(loo_results$coef), 4), "]")
print(loo_results[order(coef)])

# ===========================================================================
# 4. Alternative clustering: NUTS1 level
# ===========================================================================
message("\n=== 4. Alternative clustering ===")

panel[, nuts1 := substr(geo, 1, 3)]

twfe_nuts1 <- feols(berd_gdp_pct ~ post | geo + year,
                    data = panel,
                    cluster = ~nuts1)
message("Clustering at NUTS1: coef = ", round(coef(twfe_nuts1)["post"], 4),
        " SE = ", round(se(twfe_nuts1)["post"], 4))

twfe_region <- feols(berd_gdp_pct ~ post | geo + year,
                     data = panel,
                     cluster = ~geo)
message("Clustering at region: coef = ", round(coef(twfe_region)["post"], 4),
        " SE = ", round(se(twfe_region)["post"], 4))

# ===========================================================================
# 5. Sun-Abraham estimator (alternative heterogeneity-robust)
# ===========================================================================
message("\n=== 5. Sun-Abraham ===")

# Create cohort variable for sunab
panel[, cohort := fifelse(first_treat == 0, 10000L, first_treat)]

sa_fit <- feols(berd_gdp_pct ~ sunab(cohort, year) | geo + year,
                data = panel,
                cluster = ~country)
message("Sun-Abraham results:")
summary(sa_fit, agg = "att")

# ===========================================================================
# 6. Balanced panel check
# ===========================================================================
message("\n=== 6. Balanced panel ===")

# Keep only regions observed in all years
region_counts <- panel[, .N, by = geo]
balanced_regions <- region_counts[N == max(N), geo]
panel_balanced <- panel[geo %in% balanced_regions]

message("Balanced panel: ", uniqueN(panel_balanced$geo), " regions (from ",
        uniqueN(panel$geo), ")")

twfe_balanced <- feols(berd_gdp_pct ~ post | geo + year,
                       data = panel_balanced,
                       cluster = ~country)
message("Balanced TWFE: ", round(coef(twfe_balanced)["post"], 4),
        " (SE: ", round(se(twfe_balanced)["post"], 4), ")")

# ===========================================================================
# 7. Heterogeneity: by pre-existing protection level
# ===========================================================================
message("\n=== 7. Heterogeneity by pre-existing protection ===")

for (level in 1:3) {
  sub <- panel[protection_pre == level | first_treat == 0]
  fit_sub <- feols(berd_gdp_pct ~ post | geo + year,
                   data = sub,
                   cluster = ~country)
  label <- c("High", "Medium", "Low")[level]
  message(label, " pre-existing protection: coef = ",
          round(coef(fit_sub)["post"], 4),
          " SE = ", round(se(fit_sub)["post"], 4))
}

# ===========================================================================
# 8. Eurozone vs non-Eurozone heterogeneity
# ===========================================================================
message("\n=== 8. Eurozone heterogeneity ===")

eurozone <- c("AT","BE","CY","EE","FI","FR","DE","EL","IE","IT",
              "LV","LT","LU","MT","NL","PT","SK","SI","ES","HR")
panel[, eurozone := fifelse(country %in% eurozone, 1L, 0L)]

twfe_ez <- feols(berd_gdp_pct ~ post:eurozone + post:i(eurozone, ref = 1) | geo + year,
                 data = panel,
                 cluster = ~country)
summary(twfe_ez)

# ===========================================================================
# Save robustness results
# ===========================================================================
message("\n=== Saving robustness results ===")

rob_results <- list(
  boot_pval = if (!is.null(boot_result)) boot_result$p_val else NA,
  boot_ci = if (!is.null(boot_result)) boot_result$conf_int else c(NA, NA),
  placebo_coef = coef(placebo_twfe)["placebo_post"],
  placebo_se = se(placebo_twfe)["placebo_post"],
  loo_min = min(loo_results$coef),
  loo_max = max(loo_results$coef),
  balanced_n_regions = uniqueN(panel_balanced$geo),
  balanced_coef = coef(twfe_balanced)["post"],
  balanced_se = se(twfe_balanced)["post"]
)

save(rob_results, loo_results, boot_result,
     placebo_twfe, twfe_nuts1, twfe_region, sa_fit,
     twfe_balanced,
     file = file.path(data_dir, "robustness_models.RData"))

message("Robustness checks complete.")
