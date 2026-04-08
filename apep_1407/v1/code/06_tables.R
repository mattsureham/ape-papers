## 06_tables.R — Generate all LaTeX tables
## apep_1407: The Insurance Denominator

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "fema_analysis.rds"))
models <- readRDS(file.path(data_dir, "model_objects.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================

summ_vars <- c("premium", "log_premium_w", "lapsed", "coverage_ratio",
               "mandatory", "primary_res")

## Compute stats by group
compute_stats <- function(d, label) {
  data.frame(
    Group = label,
    N = format(nrow(d), big.mark = ","),
    `Mean Premium` = sprintf("%.0f", mean(d$premium, na.rm = TRUE)),
    `SD Premium` = sprintf("%.0f", sd(d$premium, na.rm = TRUE)),
    `Lapse Rate` = sprintf("%.3f", mean(d$lapsed, na.rm = TRUE)),
    `Coverage Ratio` = sprintf("%.2f", mean(d$coverage_ratio, na.rm = TRUE)),
    `Pct Mandatory` = sprintf("%.3f", mean(d$mandatory, na.rm = TRUE)),
    `Pct Primary Res` = sprintf("%.3f", mean(d$primary_res, na.rm = TRUE)),
    check.names = FALSE
  )
}

tab1_data <- bind_rows(
  compute_stats(df, "Full Sample"),
  compute_stats(df |> filter(grandfathered == 1), "Grandfathered"),
  compute_stats(df |> filter(grandfathered == 0), "Non-Grandfathered"),
  compute_stats(df |> filter(post_rr2 == 0), "Pre-RR2.0"),
  compute_stats(df |> filter(post_rr2 == 1), "Post-RR2.0")
)

tab1_tex <- kbl(tab1_data, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics",
                label = "summary",
                linesep = "") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = sprintf("N = %s policy observations across %d states, %d---%d. Premium is the annual total insurance premium. Lapse Rate is the fraction of policies with a recorded cancellation date. Coverage Ratio is total building insurance coverage divided by building replacement cost. Mandatory indicates properties in Special Flood Hazard Areas with federally backed mortgages.",
                             format(nrow(df), big.mark = ","),
                             length(unique(df$propertyState)),
                             min(df$year), max(df$year)),
           threeparttable = TRUE)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

## ============================================================
## Table 2: First Stage — Premium Impact of RR2.0
## ============================================================

tab2 <- etable(models$first_stage$m1, models$first_stage$m2, models$first_stage$m3,
               tex = TRUE,
               title = "First Stage: Effect of RR2.0 on Log Premiums",
               label = "tab:first_stage",
               style.tex = style.tex("aer"),
               fitstat = ~ n + r2,
               dict = c("grandfathered:post_rr2" = "Grandfathered $\\times$ Post-RR2.0",
                         "mandatory" = "Mandatory Purchase",
                         "primary_res" = "Primary Residence"),
               notes = "Standard errors clustered at county level in parentheses. Outcome is log(premium + 1). All specifications include county and year-quarter fixed effects. Column (3) adds flood zone fixed effects.")

writeLines(tab2, file.path(tables_dir, "tab2_first_stage.tex"))
cat("Table 2 saved.\n")

## ============================================================
## Table 3: Main Results — Lapse
## ============================================================

tab3 <- etable(models$lapse$m1, models$lapse$m2, models$lapse$m3,
               tex = TRUE,
               title = "Effect of RR2.0 on Policy Lapse",
               label = "tab:lapse",
               style.tex = style.tex("aer"),
               fitstat = ~ n + r2,
               dict = c("grandfathered:post_rr2" = "Grandfathered $\\times$ Post-RR2.0",
                         "mandatory" = "Mandatory Purchase",
                         "primary_res" = "Primary Residence"),
               notes = "Standard errors clustered at county level in parentheses. Outcome is an indicator for policy cancellation. All specifications include county and year-quarter fixed effects. Column (3) adds flood zone fixed effects.")

writeLines(tab3, file.path(tables_dir, "tab3_lapse.tex"))
cat("Table 3 saved.\n")

## ============================================================
## Table 4: Heterogeneity
## ============================================================

tab4 <- etable(models$heterogeneity$mand, models$heterogeneity$vol,
               models$heterogeneity$prim, models$heterogeneity$inv,
               tex = TRUE,
               title = "Heterogeneity: Lapse by Purchase Mandate and Residence Type",
               label = "tab:heterogeneity",
               style.tex = style.tex("aer"),
               fitstat = ~ n + r2,
               headers = c("Mandatory", "Voluntary", "Primary Res.", "Investment"),
               dict = c("grandfathered:post_rr2" = "Grandfathered $\\times$ Post-RR2.0"),
               notes = "Standard errors clustered at county level in parentheses. Outcome is an indicator for policy cancellation. All specifications include county and year-quarter fixed effects.")

writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))
cat("Table 4 saved.\n")

## ============================================================
## Table 5: Robustness
## ============================================================

rob_list <- list(
  rob_models$placebo_xzone,
  rob_models$placebo_time,
  rob_models$state_cluster,
  rob_models$no_fl_tx
)
rob_list <- rob_list[!sapply(rob_list, is.null)]

if (length(rob_list) >= 2) {
  tab5 <- etable(rob_list,
                 tex = TRUE,
                 title = "Robustness Checks",
                 label = "tab:robustness",
                 style.tex = style.tex("aer"),
                 fitstat = ~ n + r2,
                 headers = c("X-Zone Placebo", "Time Placebo", "State SEs", "Excl. FL/TX")[1:length(rob_list)],
                 notes = "Column (1): Placebo using non-SFHA (X/B/C zone) properties. Column (2): Fake treatment date of Oct 2020 using only pre-RR2.0 data. Column (3): Main specification with state-clustered standard errors. Column (4): Dropping Florida and Texas.")

  writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))
  cat("Table 5 saved.\n")
}

## ============================================================
## SDE Table (Mandatory Appendix)
## ============================================================

## Extract coefficients from preferred specifications
beta_prem <- coef(models$first_stage$m3)["grandfathered:post_rr2"]
se_prem <- se(models$first_stage$m3)["grandfathered:post_rr2"]
sd_y_prem <- sd(df$log_premium_w, na.rm = TRUE)

beta_lapse <- coef(models$lapse$m3)["grandfathered:post_rr2"]
se_lapse <- se(models$lapse$m3)["grandfathered:post_rr2"]
sd_y_lapse <- sd(df$lapsed, na.rm = TRUE)

beta_cov <- coef(models$coverage$m2)["grandfathered:post_rr2"]
se_cov <- se(models$coverage$m2)["grandfathered:post_rr2"]
sd_y_cov <- sd(df$coverage_ratio[!is.na(df$coverage_ratio) & df$coverage_ratio > 0 & df$coverage_ratio < 5], na.rm = TRUE)

## Heterogeneity: mandatory vs voluntary lapse
beta_mand <- coef(models$heterogeneity$mand)["grandfathered:post_rr2"]
se_mand <- se(models$heterogeneity$mand)["grandfathered:post_rr2"]
sd_y_mand <- sd(df$lapsed[df$mandatory == 1], na.rm = TRUE)

beta_vol <- coef(models$heterogeneity$vol)["grandfathered:post_rr2"]
se_vol <- se(models$heterogeneity$vol)["grandfathered:post_rr2"]
sd_y_vol <- sd(df$lapsed[df$mandatory == 0], na.rm = TRUE)

## SDE computation
compute_sde <- function(beta, se, sd_y) {
  sde <- beta / sd_y
  se_sde <- se / sd_y
  classify <- dplyr::case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )
  list(beta = beta, se = se, sd_y = sd_y, sde = sde, se_sde = se_sde, class = classify)
}

sde_prem <- compute_sde(beta_prem, se_prem, sd_y_prem)
sde_lapse <- compute_sde(beta_lapse, se_lapse, sd_y_lapse)
sde_cov <- compute_sde(beta_cov, se_cov, sd_y_cov)
sde_mand <- compute_sde(beta_mand, se_mand, sd_y_mand)
sde_vol <- compute_sde(beta_vol, se_vol, sd_y_vol)

## Format row
fmt_row <- function(outcome, s) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          outcome, s$beta, s$se, s$sd_y, s$sde, s$se_sde, s$class)
}

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does eliminating below-risk flood insurance pricing (grandfathering) ",
  "cause policyholders to lapse coverage, and what is the price elasticity of flood insurance demand? ",
  "\\textbf{Policy mechanism:} FEMA's Risk Rating 2.0 (October 2021) replaced map-based pricing with ",
  "individual-property actuarial rates, eliminating the grandfathering rule that allowed properties with ",
  "continuous coverage through a prior flood map revision to pay below-risk premiums; all renewing ",
  "policies transition to actuarial levels subject to an 18\\% annual cap on increases, while new ",
  "policies receive full actuarial rates immediately. ",
  "\\textbf{Outcome definition:} (1) Log annual premium --- total insurance premium of the NFIP policy; ",
  "(2) Policy lapse --- indicator for recorded cancellation date; ",
  "(3) Coverage ratio --- total building insurance coverage divided by building replacement cost. ",
  "\\textbf{Treatment:} Binary --- grandfathered status (grandfatheringTypeCode = 3 vs 1), determined by ",
  "whether the property held continuous NFIP coverage at the time of a prior flood map revision. ",
  "\\textbf{Data:} FEMA OpenFEMA FimaNfipPolicies, 2019--2024, policy-level observations across 5 states ",
  "(FL, TX, LA, NJ, NY), N = ", format(nrow(df), big.mark = ","), ". ",
  "\\textbf{Method:} Difference-in-differences with county and year-quarter fixed effects, flood zone ",
  "fixed effects, county-clustered standard errors. ",
  "\\textbf{Sample:} NFIP policies with valid premium and grandfathering status, effective 2019--2024, ",
  "restricted to 5 highest-volume states for tractability. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$---$0.15$), Small ($0.005$---$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  fmt_row("Log Premium", sde_prem), "\n",
  fmt_row("Policy Lapse", sde_lapse), "\n",
  fmt_row("Coverage Ratio", sde_cov), "\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Lapse by Purchase Mandate)}} \\\\\n",
  fmt_row("Lapse: Mandatory", sde_mand), "\n",
  fmt_row("Lapse: Voluntary", sde_vol), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
