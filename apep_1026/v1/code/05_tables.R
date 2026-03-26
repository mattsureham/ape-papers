# 05_tables.R — Generate all tables for paper
# apep_1026: Marijuana legalization and FHA mortgage exclusion

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Restrict to analysis sample (drop always-treated)
cs_data <- panel[always_treated == 0]

# By treatment status
sum_stats <- cs_data[, .(
  `FHA Share (\\%)` = sprintf("%.1f", mean(fha_share_pct)),
  `Conv. Share (\\%)` = sprintf("%.1f", mean(conv_share_pct)),
  `VA Share (\\%)` = sprintf("%.1f", mean(va_share_pct)),
  `Total Originations` = format(round(mean(n_total)), big.mark = ","),
  `Mean Income (\\$000s)` = sprintf("%.0f", mean(mean_income_conv, na.rm = TRUE)),
  `N (state-years)` = .N
), by = .(Group = fifelse(treated == 1, "Legalized (2019--2023)", "Never legalized"))]

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Purchase Mortgage Originations, 2018--2023}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Legalized & Never \\\\",
  " & (2019--2023) & Legalized \\\\"
)

var_names <- c("FHA Share (\\%)", "Conv. Share (\\%)", "VA Share (\\%)",
               "Total Originations", "Mean Income (\\$000s)", "N (state-years)")

tab1_lines <- c(tab1_lines, "\\hline")

for (v in var_names) {
  val_t <- sum_stats[Group == "Legalized (2019--2023)", get(v)]
  val_c <- sum_stats[Group == "Never legalized", get(v)]
  tab1_lines <- c(tab1_lines, paste0(gsub("\\\\", "\\\\", v), " & ", val_t, " & ", val_c, " \\\\"))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample includes 51 states/DC. ``Legalized'' states adopted recreational marijuana between 2019 and 2023 (14 states). States legalizing before 2019 are excluded (always-treated in sample window). Data from HMDA via CFPB, purchase originations only.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  → tables/tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results (TWFE + CS)
# ============================================================
cat("Generating Table 2: Main Results\n")

twfe_est <- coef(results$twfe_fha)["post"]
twfe_se <- se(results$twfe_fha)["post"]
twfe_n <- results$twfe_fha$nobs
twfe_r2 <- fitstat(results$twfe_fha, "r2")$r2

cs_att <- results$cs_simple$overall.att
cs_se <- results$cs_simple$overall.se

# Stars helper
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

twfe_pval <- pvalue(results$twfe_fha)["post"]
cs_pval <- 2 * pnorm(-abs(cs_att / cs_se))

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Recreational Marijuana Legalization on FHA Mortgage Share}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & TWFE & Callaway--Sant'Anna \\\\",
  "\\hline",
  "\\addlinespace",
  paste0("Post-Legalization & ", sprintf("%.3f", twfe_est), stars(twfe_pval),
         " & ", sprintf("%.3f", cs_att), stars(cs_pval), " \\\\"),
  paste0(" & (", sprintf("%.3f", twfe_se), ") & (", sprintf("%.3f", cs_se), ") \\\\"),
  "\\addlinespace",
  paste0("Observations & ", format(twfe_n, big.mark=","), " & ", format(twfe_n, big.mark=","), " \\\\"),
  paste0("$R^2$ & ", sprintf("%.3f", twfe_r2), " & --- \\\\"),
  "State FE & Yes & --- \\\\",
  "Year FE & Yes & --- \\\\",
  "Control group & All & Not-yet-treated \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is FHA share of purchase mortgage originations (percentage points). Column (1) estimates a TWFE model with state and year fixed effects. Column (2) uses the Callaway and Sant'Anna (2021) estimator with not-yet-treated states as the control group. Both exclude states that legalized before 2019 (always-treated in our 2018--2023 window). Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  → tables/tab2_main.tex\n")

# ============================================================
# Table 3: Substitution and Placebo Tests
# ============================================================
cat("Generating Table 3: Substitution & Placebo\n")

# CS results for different outcomes
conv_att <- robustness$cs_conv$overall.att
conv_se <- robustness$cs_conv$overall.se
conv_pval <- 2 * pnorm(-abs(conv_att / conv_se))

va_att <- robustness$cs_va$overall.att
va_se <- robustness$cs_va$overall.se
va_pval <- 2 * pnorm(-abs(va_att / va_se))

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Substitution and Placebo Tests}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  " & FHA Share & Conv. Share & VA Share \\\\",
  " & (Main) & (Substitution) & (Placebo) \\\\",
  "\\hline",
  "\\addlinespace",
  paste0("Post-Legalization & ",
         sprintf("%.3f", cs_att), stars(cs_pval), " & ",
         sprintf("%.3f", conv_att), stars(conv_pval), " & ",
         sprintf("%.3f", va_att), stars(va_pval), " \\\\"),
  paste0(" & (", sprintf("%.3f", cs_se), ") & (",
         sprintf("%.3f", conv_se), ") & (",
         sprintf("%.3f", va_se), ") \\\\"),
  "\\addlinespace",
  "Estimator & CS (2021) & CS (2021) & CS (2021) \\\\",
  "Control group & Not-yet-treated & Not-yet-treated & Not-yet-treated \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns use Callaway and Sant'Anna (2021) with not-yet-treated controls. Column (1) reproduces the main result. Column (2) tests for substitution: if FHA share falls, conventional share should rise symmetrically. Column (3) is a placebo: VA loans face the same federal cannabis income exclusion as FHA, so we expect a similar (negative) effect. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_placebo.tex")
cat("  → tables/tab3_placebo.tex\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness\n")

# Collect robustness estimates
never_att <- robustness$cs_never$overall.att
never_se <- robustness$cs_never$overall.se
never_pval <- 2 * pnorm(-abs(never_att / never_se))

# Controls
if (!is.null(robustness$twfe_controls)) {
  ctrl_coef <- coef(robustness$twfe_controls)["post"]
  ctrl_se <- se(robustness$twfe_controls)["post"]
  ctrl_pval <- pvalue(robustness$twfe_controls)["post"]
} else {
  ctrl_coef <- NA; ctrl_se <- NA; ctrl_pval <- NA
}

ri_p <- robustness$ri_pvalue

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccl}",
  "\\hline\\hline",
  "Specification & Estimate & SE & Notes \\\\",
  "\\hline",
  "\\addlinespace",
  paste0("Main (CS, not-yet-treated) & ", sprintf("%.3f", cs_att), stars(cs_pval),
         " & (", sprintf("%.3f", cs_se), ") & Baseline \\\\"),
  paste0("CS, never-treated only & ", sprintf("%.3f", never_att), stars(never_pval),
         " & (", sprintf("%.3f", never_se), ") & Stricter control \\\\")
)

if (!is.na(ctrl_coef)) {
  tab4_lines <- c(tab4_lines,
    paste0("TWFE + controls & ", sprintf("%.3f", ctrl_coef), stars(ctrl_pval),
           " & (", sprintf("%.3f", ctrl_se), ") & +Unemp., HPI \\\\"))
}

# LOO results
for (i in seq_len(nrow(robustness$loo))) {
  row <- robustness$loo[i]
  tab4_lines <- c(tab4_lines,
    paste0("Drop ", row$dropped, " & ", sprintf("%.3f", row$coef), stars(row$pval),
           " & (", sprintf("%.3f", row$se), ") & Leave-one-out \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  paste0("Randomization Inference & \\multicolumn{2}{c}{$p = ", sprintf("%.3f", ri_p),
         "$} & 500 permutations \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each row re-estimates the effect of recreational marijuana legalization on FHA share (percentage points). Baseline uses Callaway--Sant'Anna with not-yet-treated controls. Randomization inference permutes treatment assignment across states 500 times. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")
cat("  → tables/tab4_robust.tex\n")

# ============================================================
# Table 5: Cohort-level ATTs
# ============================================================
cat("Generating Table 5: Cohort-level ATTs\n")

cs_group <- results$cs_group
group_dt <- data.table(
  cohort = cs_group$egt,
  att = cs_group$att.egt,
  se = cs_group$se.egt
)
group_dt[, pval := 2 * pnorm(-abs(att / se))]

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Cohort-Level Treatment Effects}",
  "\\label{tab:cohort}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Legalization Cohort & ATT & SE & States \\\\",
  "\\hline",
  "\\addlinespace"
)

# Count states per cohort
cohort_counts <- panel[always_treated == 0 & treated == 1,
                       .(n_states = uniqueN(state)), by = cohort]

for (i in seq_len(nrow(group_dt))) {
  g <- group_dt[i]
  n_st <- cohort_counts[cohort == g$cohort]$n_states
  if (length(n_st) == 0) n_st <- "---"
  tab5_lines <- c(tab5_lines,
    paste0(g$cohort, " & ", sprintf("%.3f", g$att), stars(g$pval),
           " & (", sprintf("%.3f", g$se), ") & ", n_st, " \\\\"))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  paste0("\\textit{Overall ATT} & ", sprintf("%.3f", cs_att), stars(cs_pval),
         " & (", sprintf("%.3f", cs_se), ") & \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the group-level average treatment effect on the treated (ATT) from Callaway and Sant'Anna (2021). Cohort = year of recreational marijuana legalization. Control group: not-yet-treated states. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_cohort.tex")
cat("  → tables/tab5_cohort.tex\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — Appendix
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD of each outcome
pre_sd_fha <- panel[always_treated == 0 & (post == 0 | treated == 0), sd(fha_share_pct, na.rm = TRUE)]
pre_sd_conv <- panel[always_treated == 0 & (post == 0 | treated == 0), sd(conv_share_pct, na.rm = TRUE)]
pre_sd_va <- panel[always_treated == 0 & (post == 0 | treated == 0), sd(va_share_pct, na.rm = TRUE)]
pre_sd_govt <- panel[always_treated == 0 & (post == 0 | treated == 0), sd(govt_share_pct, na.rm = TRUE)]

# SDE = beta / SD(Y)
sde_fha <- cs_att / pre_sd_fha
sde_se_fha <- cs_se / pre_sd_fha
sde_conv <- conv_att / pre_sd_conv
sde_se_conv <- conv_se / pre_sd_conv
sde_va <- va_att / pre_sd_va
sde_se_va <- va_se / pre_sd_va

# Government share: use TWFE since we don't have CS for it
twfe_govt_coef <- coef(results$twfe_govt)["post"]
twfe_govt_se <- se(results$twfe_govt)["post"]
sde_govt <- twfe_govt_coef / pre_sd_govt
sde_se_govt <- twfe_govt_se / pre_sd_govt

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- data.table(
  outcome = c("FHA share", "Conventional share", "VA share"),
  beta = c(cs_att, conv_att, va_att),
  se = c(cs_se, conv_se, va_se),
  sd_y = c(pre_sd_fha, pre_sd_conv, pre_sd_va),
  sde = c(sde_fha, sde_conv, sde_va),
  sde_se = c(sde_se_fha, sde_se_conv, sde_se_va),
  classification = c(classify_sde(sde_fha), classify_sde(sde_conv), classify_sde(sde_va))
)

# Panel B: Heterogeneous (by early vs late cohorts)
# Early: 2019-2020 cohorts; Late: 2021-2023 cohorts
early_data <- panel[always_treated == 0 & (treated == 0 | cohort %in% c(2019, 2020))]
early_data[, state_num := as.integer(factor(state))]
late_data <- panel[always_treated == 0 & (treated == 0 | cohort %in% c(2021, 2022, 2023))]
late_data[, state_num := as.integer(factor(state))]

cs_early <- tryCatch({
  out <- att_gt(yname = "fha_share_pct", tname = "year", idname = "state_num",
                gname = "cohort", data = as.data.frame(early_data),
                control_group = "notyettreated", est_method = "reg", base_period = "universal")
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

cs_late <- tryCatch({
  out <- att_gt(yname = "fha_share_pct", tname = "year", idname = "state_num",
                gname = "cohort", data = as.data.frame(late_data),
                control_group = "notyettreated", est_method = "reg", base_period = "universal")
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

sde_early <- if (!is.na(cs_early$overall.att)) cs_early$overall.att / pre_sd_fha else NA
sde_late <- if (!is.na(cs_late$overall.att)) cs_late$overall.att / pre_sd_fha else NA

sde_rows_b <- data.table(
  outcome = c("FHA share (early cohorts 2019--2020)", "FHA share (late cohorts 2021--2023)"),
  beta = c(cs_early$overall.att, cs_late$overall.att),
  se = c(cs_early$overall.se, cs_late$overall.se),
  sd_y = c(pre_sd_fha, pre_sd_fha),
  sde = c(sde_early, sde_late),
  sde_se = c(if (!is.na(cs_early$overall.se)) cs_early$overall.se / pre_sd_fha else NA,
             if (!is.na(cs_late$overall.se)) cs_late$overall.se / pre_sd_fha else NA),
  classification = c(classify_sde(sde_early), classify_sde(sde_late))
)

# Build SDE LaTeX table
fmt <- function(x) if (is.na(x)) "---" else sprintf("%.3f", x)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level recreational marijuana legalization reduce the share of FHA-insured purchase mortgages by excluding cannabis-derived income from federal loan qualification? ",
  "\\textbf{Policy mechanism:} HUD Handbook 4000.1 bars income from marijuana production or sale from FHA mortgage underwriting, while Fannie Mae and Freddie Mac accept legally earned cannabis income for conventional conforming loans, creating a substitution channel as state legalization expands the cannabis workforce. ",
  "\\textbf{Outcome definition:} FHA share of purchase mortgage originations at the state-year level, computed as FHA originations divided by total (conventional + FHA) originations from HMDA. ",
  "\\textbf{Treatment:} Binary indicator for state recreational marijuana legalization (staggered across 14 states, 2019--2023). ",
  "\\textbf{Data:} HMDA via CFPB Data Browser API, 2018--2023, state-year panel of purchase originations across 40 states (excluding always-treated), approximately 240 state-year observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) group-time ATT with not-yet-treated controls, standard errors clustered at the state level. ",
  "\\textbf{Sample:} States that legalized recreational marijuana between 2019 and 2023 plus never-legalizing states; states legalizing before 2019 excluded as always-treated in the sample window. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(sde_rows_a))) {
  r <- sde_rows_a[i]
  tabF1_lines <- c(tabF1_lines,
    paste0(r$outcome, " & ", fmt(r$beta), " & ", fmt(r$se), " & ",
           fmt(r$sd_y), " & ", fmt(r$sde), " & ", fmt(r$sde_se), " & ",
           r$classification, " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by legalization cohort)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(sde_rows_b))) {
  r <- sde_rows_b[i]
  tabF1_lines <- c(tabF1_lines,
    paste0(r$outcome, " & ", fmt(r$beta), " & ", fmt(r$se), " & ",
           fmt(r$sd_y), " & ", fmt(r$sde), " & ", fmt(r$sde_se), " & ",
           r$classification, " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  → tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
