## 03_main_analysis.R — Primary analysis for apep_0963
## Continuous DiD: TFP revision effect on food insecurity

source("00_packages.R")
library(fixest)

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_clean.rds"))  # 2018-19, 2022-23 only
df_full <- readRDS(file.path(data_dir, "analysis_data.rds"))  # All years

cat(sprintf("Clean sample: %d obs, %d states\n", nrow(df), n_distinct(df$statefip)))

## =========================================================================
## Specification 1: Basic DiD (no controls)
## Y_ist = β₁(SNAP_rate_s × Post_t) + δ_s + θ_t + ε_ist
## =========================================================================
cat("\n=== Specification 1: Basic DiD ===\n")
m1 <- feols(food_insecure ~ post_treat | statefip + year,
            data = df, cluster = ~statefip,
            weights = ~hh_weight)
summary(m1)

## =========================================================================
## Specification 2: With household controls
## =========================================================================
cat("\n=== Specification 2: With controls ===\n")
m2 <- feols(food_insecure ~ post_treat + age + college + black + hispanic +
              hh_size + has_children + low_income | statefip + year,
            data = df, cluster = ~statefip,
            weights = ~hh_weight)
summary(m2)

## =========================================================================
## Specification 3: With state-level controls (unemployment)
## =========================================================================
cat("\n=== Specification 3: With state + HH controls ===\n")
m3 <- feols(food_insecure ~ post_treat + age + college + black + hispanic +
              hh_size + has_children + low_income + unemp_rate | statefip + year,
            data = df, cluster = ~statefip,
            weights = ~hh_weight)
summary(m3)

## =========================================================================
## Specification 4: Very low food security (more severe outcome)
## =========================================================================
cat("\n=== Specification 4: Very low food security ===\n")
m4 <- feols(very_low_fs ~ post_treat + age + college + black + hispanic +
              hh_size + has_children + low_income + unemp_rate | statefip + year,
            data = df, cluster = ~statefip,
            weights = ~hh_weight)
summary(m4)

## =========================================================================
## Specification 5: SNAP receipt (mechanism — did take-up change?)
## =========================================================================
cat("\n=== Specification 5: SNAP receipt (mechanism) ===\n")
m5 <- feols(snap_receipt ~ post_treat + age + college + black + hispanic +
              hh_size + has_children + low_income + unemp_rate | statefip + year,
            data = df, cluster = ~statefip,
            weights = ~hh_weight)
summary(m5)

## =========================================================================
## Event Study: Year-by-year × SNAP_rate (using all 6 years)
## Reference year: 2019
## =========================================================================
cat("\n=== Event Study (all 9 years, 2015-2023) ===\n")
df_full <- df_full %>%
  mutate(
    year_factor = relevel(factor(year), ref = "2019")
  )

m_es <- feols(food_insecure ~ i(year_factor, treat_intensity, ref = "2019") +
                age + college + black + hispanic + hh_size + has_children +
                low_income + unemp_rate | statefip + year,
              data = df_full, cluster = ~statefip,
              weights = ~hh_weight)
cat("Event study coefficients:\n")
summary(m_es)

## =========================================================================
## Triple-Difference: Post × SNAP_rate × early_EA_end
## =========================================================================
cat("\n=== Triple Difference (EA timing) ===\n")
m_ddd <- feols(food_insecure ~ post_treat + post_treat:early_ea_end +
                 post:early_ea_end + age + college + black + hispanic +
                 hh_size + has_children + low_income + unemp_rate |
                 statefip + year,
               data = df, cluster = ~statefip,
               weights = ~hh_weight)
summary(m_ddd)

## =========================================================================
## Heterogeneity: By income level
## =========================================================================
cat("\n=== Heterogeneity: By income ===\n")
m_het_lowinc <- feols(food_insecure ~ post_treat + age + college + black +
                        hispanic + hh_size + has_children + unemp_rate |
                        statefip + year,
                      data = df %>% filter(low_income == 1),
                      cluster = ~statefip, weights = ~hh_weight)

m_het_highinc <- feols(food_insecure ~ post_treat + age + college + black +
                         hispanic + hh_size + has_children + unemp_rate |
                         statefip + year,
                       data = df %>% filter(low_income == 0),
                       cluster = ~statefip, weights = ~hh_weight)

cat("Low income (< $25K):\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_het_lowinc)["post_treat"],
            se(m_het_lowinc)["post_treat"]))
cat("Higher income (≥ $25K):\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_het_highinc)["post_treat"],
            se(m_het_highinc)["post_treat"]))

## =========================================================================
## Heterogeneity: By children
## =========================================================================
cat("\n=== Heterogeneity: By children ===\n")
m_het_kids <- feols(food_insecure ~ post_treat + age + college + black +
                      hispanic + hh_size + low_income + unemp_rate |
                      statefip + year,
                    data = df %>% filter(has_children == 1),
                    cluster = ~statefip, weights = ~hh_weight)

m_het_nokids <- feols(food_insecure ~ post_treat + age + college + black +
                        hispanic + hh_size + low_income + unemp_rate |
                        statefip + year,
                      data = df %>% filter(has_children == 0),
                      cluster = ~statefip, weights = ~hh_weight)

cat("Households with children:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_het_kids)["post_treat"],
            se(m_het_kids)["post_treat"]))
cat("Households without children:\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n", coef(m_het_nokids)["post_treat"],
            se(m_het_nokids)["post_treat"]))

## =========================================================================
## Save results
## =========================================================================
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m_es = m_es, m_ddd = m_ddd,
  m_het_lowinc = m_het_lowinc, m_het_highinc = m_het_highinc,
  m_het_kids = m_het_kids, m_het_nokids = m_het_nokids
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## =========================================================================
## Write diagnostics.json for validator
## =========================================================================
## Use full sample for diagnostics (pre = all years before 2022)
n_treated_states <- n_distinct(df_full$statefip[df_full$post == 1])
n_pre <- length(unique(df_full$year[df_full$post == 0]))  # 2015-2021 = 7 pre-periods
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs,
  n_states = n_distinct(df$statefip),
  food_insecure_pre = round(weighted.mean(df$food_insecure[df$post == 0],
                                           df$hh_weight[df$post == 0], na.rm = TRUE), 4),
  food_insecure_post = round(weighted.mean(df$food_insecure[df$post == 1],
                                            df$hh_weight[df$post == 1], na.rm = TRUE), 4),
  main_coef = round(coef(m3)["post_treat"], 6),
  main_se = round(se(m3)["post_treat"], 6)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Summary of main results ===\n")
cat(sprintf("Main coefficient (β₁): %.4f\n", coef(m3)["post_treat"]))
cat(sprintf("Standard error: %.4f\n", se(m3)["post_treat"]))
cat(sprintf("t-stat: %.2f\n", coef(m3)["post_treat"] / se(m3)["post_treat"]))
cat(sprintf("Pre-period food insecurity: %.1f%%\n", 100 * diagnostics$food_insecure_pre))
cat(sprintf("Post-period food insecurity: %.1f%%\n", 100 * diagnostics$food_insecure_post))
cat(sprintf("SD(Y): %.4f\n", sd(df$food_insecure)))
cat(sprintf("SD(treat_intensity): %.4f\n", sd(df$treat_intensity)))
cat(sprintf("SDE (continuous): %.4f\n",
            coef(m3)["post_treat"] * sd(df$treat_intensity) / sd(df$food_insecure)))

cat("\nDiagnostics saved.\n")
