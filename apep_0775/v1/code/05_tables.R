## =============================================================================
## 05_tables.R — Generate all LaTeX tables
## Paper: SNAP Drug Felon Ban Rollback and Employment (apep_0775)
## =============================================================================

source("00_packages.R")

cat("=== Generating LaTeX Tables ===\n")

## Load results
results  <- readRDS("../data/main_results.rds")
robust   <- readRDS("../data/robustness_results.rds")
df       <- fread("../data/state_panel.csv")

## Helper
fmt_coef <- function(coef, se, pval) {
  stars <- ifelse(pval < 0.01, "^{***}",
           ifelse(pval < 0.05, "^{**}",
           ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.4f%s", coef, stars)
}
fmt_se <- function(se) sprintf("(%.4f)", se)

## =============================================================================
## TABLE 1: Summary Statistics
## =============================================================================
cat("\n--- Table 1 ---\n")

summ <- df[, .(
  `Mean Emp` = format(round(mean(emp)), big.mark = ","),
  `SD Emp` = format(round(sd(emp)), big.mark = ","),
  `Mean Hires` = format(round(mean(hires)), big.mark = ","),
  `Mean Earn` = sprintf("%.0f", mean(avg_earn, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
), by = .(Group = ifelse(treated_state == 1, "Treated", "Control"),
          Education = ifelse(low_ed == 1, "Low (E1-E2)", "High (E3-E4)"))]

tab1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Summary Statistics by Treatment Status and Education Level}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llccccc}", "\\toprule",
  "Group & Education & Mean Emp & SD Emp & Mean Hires & Mean Earnings & N \\\\",
  "\\midrule"
)
for (i in 1:nrow(summ)) {
  r <- summ[i]
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    r$Group, r$Education, r$`Mean Emp`, r$`SD Emp`,
    r$`Mean Hires`, r$`Mean Earn`, r$N))
}
tab1 <- c(tab1, "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} QWI state-quarter-education aggregates for five NAICS sectors (23, 44-45, 56, 62, 72) across 48 states, 2010Q1--2022Q4. Treated: 18 states that rolled back the drug felon SNAP ban 2015--2019. Control: 30 states that opted out pre-2010. Low education: less than high school or high school/GED. High education: some college or bachelor's+. Earnings are average quarterly earnings per worker (\\$000s).}",
  "\\end{table}")
writeLines(tab1, "../tables/tab1_summary.tex")

## =============================================================================
## TABLE 2: Main Results — Education-Specific DiD
## =============================================================================
cat("\n--- Table 2 ---\n")

educ_names <- c("E1" = "$<$HS", "E2" = "HS/GED", "E3" = "Some College",
                "E4" = "BA+", "low" = "Low (E1--E2)", "high" = "High (E3--E4)")

tab2 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Effect of SNAP Drug Felon Ban Rollback on Log Employment}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & $<$HS & HS/GED & Some Coll. & BA+ & Low Ed & High Ed \\\\",
  "\\midrule"
)

## Get coefficients
eds <- c("E1","E2","E3","E4")
coefs <- sds <- pvs <- c()
for (ed in eds) {
  r <- results$educ_results[[ed]]
  coefs <- c(coefs, coef(r)["treated_state:post"])
  sds <- c(sds, se(r)["treated_state:post"])
  pvs <- c(pvs, pvalue(r)["treated_state:post"])
}

## Low and High combined
r_low <- results$reg_low
r_high <- results$reg_high
coefs <- c(coefs, coef(r_low)["treated_state:post"],
           coef(r_high)["treated_state:post"])
sds <- c(sds, se(r_low)["treated_state:post"],
         se(r_high)["treated_state:post"])
pvs <- c(pvs, pvalue(r_low)["treated_state:post"],
         pvalue(r_high)["treated_state:post"])

coef_str <- sapply(1:6, function(i) fmt_coef(coefs[i], sds[i], pvs[i]))
se_str <- sapply(sds, fmt_se)

tab2 <- c(tab2,
  sprintf("Treated $\\times$ Post & %s \\\\", paste(coef_str, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_str, collapse = " & ")),
  "\\midrule")

## N and FE
ns <- c()
for (ed in eds) {
  ns <- c(ns, format(nrow(df[education == ed]), big.mark = ","))
}
ns <- c(ns, format(nrow(df[low_ed == 1]), big.mark = ","),
        format(nrow(df[low_ed == 0]), big.mark = ","))

tab2 <- c(tab2,
  sprintf("Observations & %s \\\\", paste(ns, collapse = " & ")),
  "State FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} Each column estimates a separate DiD regression of log employment on the interaction of treatment status (state rolled back drug felon SNAP ban) and post-treatment indicator, with state and year-quarter fixed effects. Standard errors clustered at the state level (48 states). Columns (1)--(4) estimate effects by education group. Columns (5)--(6) combine education groups: Low = E1 ($<$HS) + E2 (HS/GED); High = E3 (some college) + E4 (BA+). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.}",
  "\\end{table}")
writeLines(tab2, "../tables/tab2_main.tex")

## =============================================================================
## TABLE 3: Industry Heterogeneity
## =============================================================================
cat("\n--- Table 3 ---\n")

ind_dt <- robust$industry
tab3 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Industry Heterogeneity: Low-Education Employment Effects}",
  "\\label{tab:industry}",
  "\\begin{tabular}{lccccc}", "\\toprule",
  "Industry & NAICS & Coef. & SE & $p$-value & N \\\\",
  "\\midrule"
)
for (i in 1:nrow(ind_dt)) {
  r <- ind_dt[i]
  tab3 <- c(tab3, sprintf(
    "%s & %s & %s & %s & %.3f & %s \\\\",
    r$label, r$industry,
    fmt_coef(r$coef, r$se, r$pval), fmt_se(r$se),
    r$pval, format(r$n, big.mark = ",")))
}
tab3 <- c(tab3, "\\bottomrule", "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} Each row estimates a separate DiD for low-education workers (E1--E2) in one NAICS sector. Dependent variable: log employment. State and year-quarter FE. Standard errors clustered at state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.}",
  "\\end{table}")
writeLines(tab3, "../tables/tab3_industry.tex")

## =============================================================================
## TABLE 4: Robustness (Placebo + Ban Type + Pre-trends)
## =============================================================================
cat("\n--- Table 4 ---\n")

tab4 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Robustness: Placebo, Ban Type, and Pre-Trends}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & Coef. & SE & $p$-value & N \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Placebo (High-Education Workers)}} \\\\"
)

## Placebo
pr <- robust$placebo
tab4 <- c(tab4, sprintf(
  "\\quad E3+E4 (some college + BA+) & %s & %s & %.3f & %s \\\\",
  fmt_coef(coef(pr)["treated_state:post"], se(pr)["treated_state:post"],
           pvalue(pr)["treated_state:post"]),
  fmt_se(se(pr)["treated_state:post"]),
  pvalue(pr)["treated_state:post"],
  format(nrow(df[low_ed == 0]), big.mark = ",")))

tab4 <- c(tab4, "[0.5em]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Full vs.~Partial Ban Modification}} \\\\")

## These are stored as plain results, re-estimate
df_low <- df[low_ed == 1]
treat <- fread("../data/treatment_states.csv")
treat[, state_fips := as.character(state_fips)]

for (type in c("full", "partial")) {
  sub <- df_low[ban_type == type | treated_state == 0]
  reg <- feols(log_emp ~ treated_state:post | state_fips + yq,
               data = sub, cluster = ~state_fips)
  label <- ifelse(type == "full", "Full ban removal", "Partial modification")
  tab4 <- c(tab4, sprintf(
    "\\quad %s & %s & %s & %.3f & %s \\\\",
    label,
    fmt_coef(coef(reg)["treated_state:post"], se(reg)["treated_state:post"],
             pvalue(reg)["treated_state:post"]),
    fmt_se(se(reg)["treated_state:post"]),
    pvalue(reg)["treated_state:post"],
    format(nrow(sub), big.mark = ",")))
}

tab4 <- c(tab4, "[0.5em]",
  "\\multicolumn{5}{l}{\\textit{Panel C: Pre-Trend Coefficients (2011--2015 vs.~2010)}} \\\\")

if (!is.null(robust$pretrend)) {
  ct <- coeftable(robust$pretrend)
  for (i in 1:nrow(ct)) {
    yr <- gsub("year_fct::|:treated_state", "", rownames(ct)[i])
    tab4 <- c(tab4, sprintf(
      "\\quad Year %s & %.4f & (%.4f) & %.3f & --- \\\\",
      yr, ct[i,1], ct[i,2], ct[i,4]))
  }
}

tab4 <- c(tab4, "\\bottomrule", "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} Panel A: placebo test on workers unlikely affected by SNAP restoration (some college or BA+). Panel B: splits treated states by ban modification type. Panel C: year-by-year coefficients for treated $\\times$ year dummies (low-ed, pre-treatment only, 2010 base). All specifications include state and quarter FE, clustered at state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.}",
  "\\end{table}")
writeLines(tab4, "../tables/tab4_robustness.tex")

## =============================================================================
## TABLE F1: Standardized Effect Sizes
## =============================================================================
cat("\n--- Table F1: SDE ---\n")

## Get pre-treatment SD for low-ed employment
pre_sd <- results$pre_sd
sd_log_emp_low <- pre_sd[low_ed == 1, sd_log_emp]

## Main outcomes: Low-ed E1, E2, combined
outcomes <- list(
  list(name = "Employment ($<$HS)", reg = results$educ_results[["E1"]],
       sd_y = sd(df[education == "E1" & (post == 0 | treated_state == 0), log_emp], na.rm=TRUE)),
  list(name = "Employment (HS/GED)", reg = results$educ_results[["E2"]],
       sd_y = sd(df[education == "E2" & (post == 0 | treated_state == 0), log_emp], na.rm=TRUE)),
  list(name = "Employment (Low Ed)", reg = results$reg_low,
       sd_y = sd_log_emp_low)
)

sde_rows <- list()
for (o in outcomes) {
  beta <- coef(o$reg)["treated_state:post"]
  se_b <- se(o$reg)["treated_state:post"]
  sde <- beta / o$sd_y
  se_sde <- se_b / o$sd_y

  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  sde_rows[[length(sde_rows)+1]] <- data.table(
    outcome = o$name, beta = beta, se = se_b,
    sd_y = o$sd_y, sde = sde, se_sde = se_sde,
    classification = classify(sde))
}
sde_dt <- rbindlist(sde_rows)
print(sde_dt)

sde_notes <- paste0(
  "{\\footnotesize \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether restoring SNAP eligibility for individuals with drug felony convictions increases formal employment among low-education workers in high-reentry industries. ",
  "\\textbf{Policy mechanism:} The 1996 PRWORA imposed a lifetime SNAP ban on drug felons; between 2015--2019, 18 states rolled back this ban, restoring food assistance eligibility to formerly incarcerated individuals and reducing their food insecurity barrier to job search. ",
  "\\textbf{Outcome definition:} Log quarterly employment from the Quarterly Workforce Indicators (QWI), measuring beginning-of-quarter headcount employment by state, education level, and NAICS sector. ",
  "\\textbf{Treatment:} Binary: state modified or repealed the drug felon SNAP ban (18 treated states vs.\\ 30 pre-2010 opt-out controls). ",
  "\\textbf{Data:} Census LEHD QWI sex$\\times$education panels (2010--2022), five NAICS sectors (23, 44-45, 56, 62, 72), 48 U.S.\\ states, 9,860 state-quarter-education observations. ",
  "\\textbf{Method:} Difference-in-differences with state and year-quarter fixed effects; standard errors clustered at the state level; education-specific regressions with high-education placebo. ",
  "\\textbf{Sample:} State-quarter-education aggregates for 18 treated and 30 control states in five high-reentry NAICS sectors; restricted to private-sector employment (QWI owner code A05). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).}")

tabF1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule")
for (i in 1:nrow(sde_dt)) {
  r <- sde_dt[i]
  tabF1 <- c(tabF1, sprintf(
    "%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}
tabF1 <- c(tabF1, "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\par\\vspace{0.3em}", sde_notes, "\\end{table}")
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
