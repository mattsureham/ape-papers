## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_0686: UK Housing Delivery Test RDD

source("code/00_packages.R")

data_dir <- "data"
table_dir <- "tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
rdd_results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
density_test <- readRDS(file.path(data_dir, "density_test.rds"))
fe_results <- readRDS(file.path(data_dir, "fe_results.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("Generating Table 1: Summary Statistics...\n")

## Near cutoff (within optimal bandwidth)
main_bw <- rdd_results[["approval_rate_major_dwell"]]$bw

stats_full <- panel %>%
  summarise(
    `HDT Score (\\%)` = sprintf("%.1f (%.1f)", mean(hdt_score), sd(hdt_score)),
    `Major Dwelling Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_major_dwell, na.rm=TRUE), sd(approval_rate_major_dwell, na.rm=TRUE)),
    `All Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_all), sd(approval_rate_all)),
    `Householder Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_householder), sd(approval_rate_householder)),
    `Major Dwelling Decisions` = sprintf("%.0f (%.0f)",
      mean(major_dwell_decisions, na.rm=TRUE), sd(major_dwell_decisions, na.rm=TRUE)),
    `All Decisions` = sprintf("%.0f (%.0f)", mean(all_decisions), sd(all_decisions)),
    N = as.character(n())
  ) %>% pivot_longer(everything(), names_to="Variable", values_to="Full Sample")

stats_below <- panel %>% filter(below_75 == 1) %>%
  summarise(
    `HDT Score (\\%)` = sprintf("%.1f (%.1f)", mean(hdt_score), sd(hdt_score)),
    `Major Dwelling Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_major_dwell, na.rm=TRUE), sd(approval_rate_major_dwell, na.rm=TRUE)),
    `All Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_all), sd(approval_rate_all)),
    `Householder Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_householder), sd(approval_rate_householder)),
    `Major Dwelling Decisions` = sprintf("%.0f (%.0f)",
      mean(major_dwell_decisions, na.rm=TRUE), sd(major_dwell_decisions, na.rm=TRUE)),
    `All Decisions` = sprintf("%.0f (%.0f)", mean(all_decisions), sd(all_decisions)),
    N = as.character(n())
  ) %>% pivot_longer(everything(), names_to="Variable", values_to="Below 75\\%")

stats_above <- panel %>% filter(below_75 == 0) %>%
  summarise(
    `HDT Score (\\%)` = sprintf("%.1f (%.1f)", mean(hdt_score), sd(hdt_score)),
    `Major Dwelling Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_major_dwell, na.rm=TRUE), sd(approval_rate_major_dwell, na.rm=TRUE)),
    `All Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_all), sd(approval_rate_all)),
    `Householder Approval Rate (\\%)` = sprintf("%.1f (%.1f)",
      mean(approval_rate_householder), sd(approval_rate_householder)),
    `Major Dwelling Decisions` = sprintf("%.0f (%.0f)",
      mean(major_dwell_decisions, na.rm=TRUE), sd(major_dwell_decisions, na.rm=TRUE)),
    `All Decisions` = sprintf("%.0f (%.0f)", mean(all_decisions), sd(all_decisions)),
    N = as.character(n())
  ) %>% pivot_longer(everything(), names_to="Variable", values_to="Above 75\\%")

tab1 <- stats_full %>%
  left_join(stats_below, by="Variable") %>%
  left_join(stats_above, by="Variable")

tab1_tex <- kable(tab1, format="latex", booktabs=TRUE, escape=FALSE,
                  caption="Summary Statistics",
                  label="tab:summary") %>%
  kable_styling(latex_options="hold_position") %>%
  footnote(general="Standard deviations in parentheses. Sample: English Local Planning Authorities, HDT rounds 2020--2023. Approval rates computed from PS2 quarterly planning statistics aggregated over the 4 quarters following each HDT publication.",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Main RDD Results
## ============================================================

cat("Generating Table 2: Main RDD Results...\n")

rdd_df <- map_dfr(rdd_results, function(r) {
  tibble(
    Outcome = r$outcome,
    `Bias-Corrected` = sprintf("%.2f", r$tau_bc),
    `Robust SE` = sprintf("(%.2f)", r$se),
    `95\\% CI` = sprintf("[%.1f, %.1f]", r$ci_lower, r$ci_upper),
    `$p$-value` = sprintf("%.3f", r$pval),
    `Bandwidth` = sprintf("%.1f", r$bw),
    `Eff. $N$` = as.character(r$n_eff)
  )
})

tab2_tex <- kable(rdd_df, format="latex", booktabs=TRUE, escape=FALSE,
                  caption="RDD Estimates at the 75\\% Housing Delivery Test Threshold",
                  label="tab:rdd_main", align="lcccccc") %>%
  kable_styling(latex_options=c("hold_position", "scale_down")) %>%
  footnote(general="Local linear regression discontinuity estimates using \\\\texttt{rdrobust} with triangular kernel and MSE-optimal bandwidth (Cattaneo, Idrobo, and Titiunik 2020). Standard errors clustered at the Local Authority level. Householder applications serve as a placebo outcome---the presumption in favour should not affect small-scale extensions and alterations.",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(tab2_tex, file.path(table_dir, "tab2_rdd_main.tex"))

## ============================================================
## Table 3: Bandwidth Sensitivity
## ============================================================

cat("Generating Table 3: Bandwidth Sensitivity...\n")

bw_df <- map_dfr(robustness$bandwidth, function(r) {
  tibble(
    `BW Multiplier` = sprintf("%.2f$\\times$", r$multiplier),
    `Bandwidth (pp)` = sprintf("%.1f", r$bandwidth),
    Estimate = sprintf("%.2f", r$tau_bc),
    `Robust SE` = sprintf("(%.2f)", r$se_robust),
    `$p$-value` = sprintf("%.3f", r$pval),
    `Eff. $N$` = as.character(r$n_eff)
  )
})

tab3_tex <- kable(bw_df, format="latex", booktabs=TRUE, escape=FALSE,
                  caption="Bandwidth Sensitivity: Major Dwelling Approval Rate",
                  label="tab:bw_sensitivity", align="lccccc") %>%
  kable_styling(latex_options="hold_position") %>%
  footnote(general="Bias-corrected RDD estimates at the 75\\% HDT threshold for the major dwelling approval rate. Bandwidths are multiples of the MSE-optimal bandwidth. Standard errors clustered at the LA level.",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(tab3_tex, file.path(table_dir, "tab3_bandwidth.tex"))

## ============================================================
## Table 4: Placebo Cutoffs and Robustness
## ============================================================

cat("Generating Table 4: Placebo and Robustness...\n")

## Combine placebo cutoffs with donut hole and polynomial sensitivity
rob_rows <- list()

## Placebo cutoffs
for (r in robustness$placebo) {
  rob_rows <- c(rob_rows, list(tibble(
    Test = sprintf("Placebo: %d\\%%", r$cutoff),
    Estimate = sprintf("%.2f", r$tau_bc),
    `Robust SE` = sprintf("(%.2f)", r$se_robust),
    `$p$-value` = sprintf("%.3f", r$pval),
    `Eff. $N$` = as.character(r$n_eff)
  )))
}

## Donut hole
rob_rows <- c(rob_rows, list(tibble(
  Test = "Donut hole ($\\pm$1pp excluded)",
  Estimate = sprintf("%.2f", robustness$donut$tau_bc),
  `Robust SE` = sprintf("(%.2f)", robustness$donut$se_robust),
  `$p$-value` = sprintf("%.3f", robustness$donut$pval),
  `Eff. $N$` = as.character(robustness$donut$n_eff)
)))

rob_df <- bind_rows(rob_rows)

tab4_tex <- kable(rob_df, format="latex", booktabs=TRUE, escape=FALSE,
                  caption="Placebo Tests and Robustness Checks: Major Dwelling Approval Rate",
                  label="tab:robustness", align="lcccc") %>%
  kable_styling(latex_options="hold_position") %>%
  footnote(general="Placebo tests apply the RDD at cutoffs where no policy discontinuity should exist. The donut-hole specification excludes LAs within 1 percentage point of the 75\\% threshold. All estimates use bias-corrected local linear regression with robust standard errors clustered at the LA level.",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

## ============================================================
## Table 5: Year-by-Year Estimates
## ============================================================

cat("Generating Table 5: Year-by-Year...\n")

yr_df <- map_dfr(robustness$year_by_year, function(r) {
  tibble(
    `HDT Round` = as.character(r$year),
    Estimate = sprintf("%.2f", r$tau_bc),
    `Robust SE` = sprintf("(%.2f)", r$se_robust),
    `$p$-value` = sprintf("%.3f", r$pval),
    `Eff. $N$` = as.character(r$n_eff)
  )
})

tab5_tex <- kable(yr_df, format="latex", booktabs=TRUE, escape=FALSE,
                  caption="Year-by-Year RDD Estimates: Major Dwelling Approval Rate",
                  label="tab:year_by_year", align="lcccc") %>%
  kable_styling(latex_options="hold_position") %>%
  footnote(general="Separate RDD estimates at the 75\\% HDT threshold for each annual measurement round. Bandwidth selected independently for each year using CCT (2014). Standard errors are heteroskedasticity-robust (year-specific samples are too small for clustering).",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(tab5_tex, file.path(table_dir, "tab5_year_by_year.tex"))

## ============================================================
## SDE Appendix Table (MANDATORY)
## ============================================================

cat("Generating SDE Appendix Table...\n")

## Compute standardized effect sizes for main outcomes
sde_rows <- list()

for (outcome_name in c("approval_rate_all", "approval_rate_major",
                        "approval_rate_major_dwell", "approval_rate_householder")) {
  r <- rdd_results[[outcome_name]]
  if (is.null(r)) next

  sd_y <- sd(panel[[outcome_name]], na.rm = TRUE)
  sde <- r$tau_bc / sd_y
  se_sde <- r$se / sd_y

  ## Classification bucket
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_rows <- c(sde_rows, list(tibble(
    Outcome = r$outcome,
    `$\\hat{\\beta}$` = sprintf("%.2f", r$tau_bc),
    SE = sprintf("%.2f", r$se),
    `SD($Y$)` = sprintf("%.2f", sd_y),
    SDE = sprintf("%.3f", sde),
    `SE(SDE)` = sprintf("%.3f", se_sde),
    Classification = bucket
  )))
}

sde_df <- bind_rows(sde_rows)

sde_tex <- kable(sde_df, format="latex", booktabs=TRUE, escape=FALSE,
                 caption="Standardized Effect Sizes",
                 label="tab:sde", align="lcccccc") %>%
  kable_styling(latex_options=c("hold_position", "scale_down")) %>%
  footnote(general="Standardized Distributional Effect (SDE) = $\\hat{\\beta} / \\text{SD}(Y)$. Classification is based on the magnitude of the SDE point estimate, not statistical significance. This paper estimates the causal effect of England's Housing Delivery Test ``presumption in favour of sustainable development'' (triggered at the 75\\% HDT threshold) on Local Authority planning approval rates, using a sharp RDD on administrative data from DLUHC (2020--2023 HDT rounds, $N=1{,}184$ LA-year observations). Treatment is binary: HDT score below 75\\%.",
           general_title="Notes:", escape=FALSE, threeparttable=TRUE)

writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("Files in %s/: %s\n", table_dir, paste(list.files(table_dir), collapse = ", ")))
