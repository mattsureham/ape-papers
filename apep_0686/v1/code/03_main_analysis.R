## 03_main_analysis.R — RDD estimation at 75% HDT threshold
## apep_0686: UK Housing Delivery Test RDD

source("code/00_packages.R")

data_dir <- "data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat(sprintf("Analysis panel: %d observations, %d below 75%%\n",
            nrow(panel), sum(panel$below_75)))

## ============================================================
## 1. McCrary Density Test
## ============================================================

cat("\n=== McCrary Density Test ===\n")
density_test <- rddensity::rddensity(panel$running_var, c = 0)
cat(sprintf("  T-statistic: %.3f\n", density_test$test$t_jk))
cat(sprintf("  P-value: %.4f\n", density_test$test$p_jk))
cat(sprintf("  Interpretation: %s\n",
            ifelse(density_test$test$p_jk > 0.05,
                   "No evidence of manipulation (PASS)",
                   "WARNING: Possible manipulation at cutoff")))

## ============================================================
## 2. Main RDD Estimates — rdrobust
## ============================================================

cat("\n=== Main RDD Estimates (rdrobust) ===\n")

outcomes <- c("approval_rate_all", "approval_rate_major",
              "approval_rate_major_dwell", "approval_rate_householder")
outcome_labels <- c("All Applications", "Major (All)",
                     "Major Dwellings", "Householder (Placebo)")

rdd_results <- list()

for (i in seq_along(outcomes)) {
  y <- panel[[outcomes[i]]]
  x <- panel$running_var
  valid <- !is.na(y) & !is.na(x)

  if (sum(valid) < 50) {
    cat(sprintf("\n%s: SKIPPED (insufficient observations)\n", outcome_labels[i]))
    next
  }

  rd <- rdrobust::rdrobust(y[valid], x[valid], c = 0, kernel = "triangular", p = 1,
                            cluster = panel$la_code[valid])

  rdd_results[[outcomes[i]]] <- list(
    outcome = outcome_labels[i],
    tau = rd$coef[1],             # Conventional estimate
    tau_bc = rd$coef[2],          # Bias-corrected estimate
    se = rd$se[3],                # Robust SE
    ci_lower = rd$ci[3, 1],       # Robust CI
    ci_upper = rd$ci[3, 2],
    pval = rd$pv[3],              # Robust p-value
    bw = rd$bws[1, 1],            # Bandwidth (left)
    n_left = rd$N_h[1],           # Obs below cutoff in bandwidth
    n_right = rd$N_h[2],          # Obs above cutoff in bandwidth
    n_eff = rd$N_h[1] + rd$N_h[2]
  )

  cat(sprintf("\n%s:\n", outcome_labels[i]))
  cat(sprintf("  Conventional estimate: %.2f (SE=%.2f)\n", rd$coef[1], rd$se[1]))
  cat(sprintf("  Bias-corrected:        %.2f (SE=%.2f)\n", rd$coef[2], rd$se[3]))
  cat(sprintf("  Robust 95%% CI:         [%.2f, %.2f]\n", rd$ci[3, 1], rd$ci[3, 2]))
  cat(sprintf("  Robust p-value:        %.4f\n", rd$pv[3]))
  cat(sprintf("  Bandwidth:             %.1f pp\n", rd$bws[1, 1]))
  cat(sprintf("  Effective N:           %d (left=%d, right=%d)\n",
              rd$N_h[1] + rd$N_h[2], rd$N_h[1], rd$N_h[2]))
}

## ============================================================
## 3. RDD with Year Fixed Effects (parametric check)
## ============================================================

cat("\n=== Parametric RDD with Year FE (fixest) ===\n")

## Linear specification with year FE, clustered at LA level
panel_bw <- panel %>%
  filter(abs(running_var) <= rdd_results[["approval_rate_major_dwell"]]$bw)

## Main outcome: major dwelling approval rate
fe_main <- feols(approval_rate_major_dwell ~ below_75 + running_var +
                   below_75:running_var | hdt_year,
                 data = panel_bw, cluster = ~la_code)

cat("\nParametric RDD (major dwellings, within optimal bandwidth):\n")
print(summary(fe_main))

## All outcomes
fe_all <- feols(approval_rate_all ~ below_75 + running_var +
                  below_75:running_var | hdt_year,
                data = panel_bw, cluster = ~la_code)

fe_householder <- feols(approval_rate_householder ~ below_75 + running_var +
                          below_75:running_var | hdt_year,
                        data = panel_bw, cluster = ~la_code)

## ============================================================
## 4. Covariate Balance at Cutoff
## ============================================================

cat("\n=== Covariate Balance (Pre-Treatment Characteristics) ===\n")

## Use pre-period (2018-2019) planning data as "covariates"
## These should be smooth across the 2020+ threshold
hdt_pre <- readRDS(file.path(data_dir, "hdt_pre.rds"))

## Match to pre-period PS2 (2017-2019 averages)
ps2_clean <- read_csv(file.path(data_dir, "ps2_full.csv"), skip = 2,
                      show_col_types = FALSE, name_repair = "unique")

pre_ps2 <- ps2_clean %>%
  select(la_code = 3, quarter = 4, all_decisions = 5, all_granted = 6,
         major_dwell_decisions = 33, major_dwell_granted = 34) %>%
  mutate(across(c(all_decisions:major_dwell_granted), ~as.numeric(as.character(.))),
         year = as.integer(str_extract(quarter, "\\d{4}"))) %>%
  filter(year %in% 2017:2019, grepl("^E", la_code)) %>%
  group_by(la_code) %>%
  summarise(
    pre_total_decisions = sum(all_decisions, na.rm = TRUE),
    pre_approval_rate = sum(all_granted, na.rm = TRUE) / sum(all_decisions, na.rm = TRUE) * 100,
    pre_major_decisions = sum(major_dwell_decisions, na.rm = TRUE),
    pre_major_approval = ifelse(sum(major_dwell_decisions, na.rm = TRUE) > 0,
                                sum(major_dwell_granted, na.rm = TRUE) /
                                  sum(major_dwell_decisions, na.rm = TRUE) * 100, NA),
    .groups = "drop"
  )

## Merge pre-period covariates with 2020 HDT scores for balance test
panel_2020 <- panel %>%
  filter(hdt_year == 2020) %>%
  left_join(pre_ps2, by = "la_code") %>%
  filter(!is.na(pre_approval_rate))

## RDD covariate balance tests
for (cov in c("pre_approval_rate", "pre_major_approval", "pre_total_decisions")) {
  y <- panel_2020[[cov]]
  x <- panel_2020$running_var
  valid <- !is.na(y)
  if (sum(valid) < 30) next

  rd_cov <- rdrobust::rdrobust(y[valid], x[valid], c = 0, p = 1)
  cat(sprintf("  %s: coef=%.2f, p=%.3f %s\n",
              cov, rd_cov$coef[1], rd_cov$pv[3],
              ifelse(rd_cov$pv[3] > 0.1, "(balanced)", "(!)")))
}

## ============================================================
## 5. Save Results and Diagnostics
## ============================================================

## Write diagnostics.json for validation
n_treated <- n_distinct(panel$la_code[panel$below_75 == 1])
n_pre <- length(unique(panel$hdt_year)) # Each year is a "period"
diagnostics <- list(
  n_treated = n_treated,
  n_pre = 4,  # 4 HDT rounds (2020-2023)
  n_obs = nrow(panel),
  n_within_bw = rdd_results[["approval_rate_major_dwell"]]$n_eff
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

## Save RDD results for table generation
saveRDS(rdd_results, file.path(data_dir, "rdd_results.rds"))
saveRDS(density_test, file.path(data_dir, "density_test.rds"))
saveRDS(list(fe_main = fe_main, fe_all = fe_all, fe_householder = fe_householder),
        file.path(data_dir, "fe_results.rds"))

cat("\nMain analysis complete. Results saved.\n")
