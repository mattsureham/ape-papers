## =============================================================================
## 05_tables.R — Generate all LaTeX tables
## Paper: Rejected and Relocated (apep_1221)
## =============================================================================

library(data.table)
library(fixest)
library(modelsummary)
library(jsonlite)

dt <- fread("../data/analysis_data.csv")
load("../data/models.RData")
load("../data/robustness_models.RData")
main <- fromJSON("../data/main_results.json")
hetero <- fromJSON("../data/robustness_results.json")
quintile <- fread("../data/quintile_stats.csv")

## =============================================================================
## Table 1: Summary Statistics
## =============================================================================

cat("Generating Table 1: Summary Statistics\n")

sumstat_vars <- c("moved", "rejected", "examiner_leniency", "solo",
                  "prior_grants", "team_size")
sumstat_labels <- c("Moved State (Next App.)", "Application Rejected",
                    "Examiner Leniency (LOO)", "Solo Inventor",
                    "Prior Grants", "Team Size")

ss <- data.frame(
  Variable = sumstat_labels,
  Mean = sapply(sumstat_vars, function(v) sprintf("%.3f", mean(dt[[v]]))),
  SD = sapply(sumstat_vars, function(v) sprintf("%.3f", sd(dt[[v]]))),
  Min = sapply(sumstat_vars, function(v) sprintf("%.3f", min(dt[[v]]))),
  Max = sapply(sumstat_vars, function(v) sprintf("%.3f", max(dt[[v]]))),
  stringsAsFactors = FALSE
)
rownames(ss) <- NULL

# LaTeX output
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max \\\\",
  "\\hline"
)

for (i in 1:nrow(ss)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            ss$Variable[i], ss$Mean[i], ss$SD[i], ss$Min[i], ss$Max[i]))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("\\multicolumn{5}{l}{\\footnotesize Observations: %s inventor-application pairs.} \\\\",
          format(nrow(dt), big.mark = ",")),
  sprintf("\\multicolumn{5}{l}{\\footnotesize Unique inventors: %s. Unique applications: %s. Filing years: 2002--2014.} \\\\",
          format(uniqueN(dt$inventor_id), big.mark = ","),
          format(uniqueN(dt$application_number), big.mark = ",")),
  "\\multicolumn{5}{l}{\\footnotesize Examiner leniency is the leave-one-out grant rate within art-unit $\\times$ filing-year.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

## =============================================================================
## Table 2: Main Results (OLS and IV)
## =============================================================================

cat("Generating Table 2: Main Results\n")

# Use fixest's etable for clean output
setFixest_dict(c(
  moved = "Moved State",
  rejected = "Rejected",
  fit_rejected = "Rejected",
  examiner_leniency = "Examiner Leniency (LOO)",
  solo = "Solo Inventor",
  prior_grants = "Prior Grants",
  team_size = "Team Size",
  small_entity = "Small Entity"
))

etable(ols_nfe, ols_fe, ols_ctrl, iv_fe, iv_ctrl,
       headers = c("OLS", "OLS", "OLS", "IV", "IV"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       style.tex = style.tex("aer"),
       file = "../tables/tab2_main.tex",
       replace = TRUE,
       title = "Patent Rejection and Inventor Interstate Mobility",
       label = "tab:main",
       notes = c(
         paste0("Observations: ", format(nrow(dt), big.mark = ","),
                " inventor-application pairs from USPTO PAIR (2002--2014). "),
         "Dependent variable: indicator for inventor filing next patent from a different state. ",
         "Columns (1)--(3): OLS. Columns (4)--(5): 2SLS using leave-one-out examiner grant rate ",
         "within art-unit $\\times$ filing-year as instrument. ",
         "Standard errors clustered at the art-unit $\\times$ filing-year level in parentheses."
       ),
       extralines = list(
         "_^Art-unit $\\times$ Year FE" = c("", "\\checkmark", "\\checkmark", "\\checkmark", "\\checkmark"),
         "_^Controls" = c("", "", "\\checkmark", "", "\\checkmark"),
         "_^First-stage F" = c("", "", "", sprintf("%.0f", main$fs_fstat), sprintf("%.0f", main$fs_fstat))
       ))

## =============================================================================
## Table 3: Reduced Form by Examiner Leniency Quintile
## =============================================================================

cat("Generating Table 3: Reduced Form by Quintile\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Reduced Form: Inventor Mobility by Examiner Leniency Quintile}",
  "\\label{tab:quintile}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Q1 (Strict) & Q2 & Q3 & Q4 & Q5 (Lenient) \\\\",
  "\\hline"
)

tab3_lines <- c(tab3_lines,
  sprintf("Mean Leniency & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          quintile$mean_leniency[1], quintile$mean_leniency[2],
          quintile$mean_leniency[3], quintile$mean_leniency[4],
          quintile$mean_leniency[5]),
  sprintf("Rejection Rate & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          quintile$rejection_rate[1], quintile$rejection_rate[2],
          quintile$rejection_rate[3], quintile$rejection_rate[4],
          quintile$rejection_rate[5]),
  sprintf("Mobility Rate & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          quintile$mobility_rate[1], quintile$mobility_rate[2],
          quintile$mobility_rate[3], quintile$mobility_rate[4],
          quintile$mobility_rate[5]),
  sprintf("N & %s & %s & %s & %s & %s \\\\",
          format(quintile$n[1], big.mark = ","),
          format(quintile$n[2], big.mark = ","),
          format(quintile$n[3], big.mark = ","),
          format(quintile$n[4], big.mark = ","),
          format(quintile$n[5], big.mark = ",")),
  "\\hline",
  "\\multicolumn{6}{l}{\\footnotesize Leniency quintiles defined by leave-one-out examiner grant rate within art-unit $\\times$ filing-year.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Mobility rate declines monotonically from Q1 (13.6\\%) to Q5 (9.7\\%), confirming the first stage.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_quintile.tex")

## =============================================================================
## Table 4: Heterogeneity (Solo/Team, Experienced/Novice)
## =============================================================================

cat("Generating Table 4: Heterogeneity\n")

etable(iv_solo, iv_team, iv_exp, iv_nov,
       headers = c("Solo", "Team", "Experienced", "Novice"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       style.tex = style.tex("aer"),
       file = "../tables/tab4_heterogeneity.tex",
       replace = TRUE,
       title = "Heterogeneity: Patent Rejection and Mobility by Inventor Type",
       label = "tab:hetero",
       notes = c(
         "2SLS estimates using leave-one-out examiner grant rate as instrument. ",
         "Solo: single inventor on application. Team: multiple inventors. ",
         "Experienced: at least one prior granted patent. Novice: no prior grants. ",
         "All specifications include art-unit $\\times$ filing-year fixed effects. ",
         "Standard errors clustered at the art-unit $\\times$ filing-year level."
       ),
       extralines = list(
         "_^Art-unit $\\times$ Year FE" = c("\\checkmark", "\\checkmark", "\\checkmark", "\\checkmark")
       ))

## =============================================================================
## Table 5: Examiner Balance and Placebo Tests
## =============================================================================

cat("Generating Table 5: Balance and Placebo\n")

etable(bal_solo, bal_prior, bal_team, placebo_rf,
       headers = c("Solo", "Prior Grants", "Team Size", "Prior Move"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       style.tex = style.tex("aer"),
       file = "../tables/tab5_balance.tex",
       replace = TRUE,
       title = "Examiner Balance and Placebo Tests",
       label = "tab:balance",
       notes = c(
         "Columns (1)--(3): reduced-form regressions of pre-determined inventor characteristics on examiner ",
         "leniency (leave-one-out grant rate). Column (4): placebo test regressing an indicator for whether ",
         "the inventor changed states \\textit{before} the current application on current-examiner leniency. ",
         "A valid instrument should produce zeros in all columns. See Section~\\ref{sec:threats} for discussion. ",
         "All specifications include art-unit $\\times$ filing-year fixed effects. ",
         "Standard errors clustered at the art-unit $\\times$ filing-year level."
       ),
       extralines = list(
         "_^Art-unit $\\times$ Year FE" = c("\\checkmark", "\\checkmark", "\\checkmark", "\\checkmark")
       ))

## =============================================================================
## Appendix Table F1: Standardized Effect Sizes
## =============================================================================

cat("Generating SDE Appendix Table\n")

# Compute SDEs
sd_y_full <- sd(dt$moved)
sd_y_solo <- sd(dt$moved[dt$solo == 1])
sd_y_team <- sd(dt$moved[dt$solo == 0])
sd_y_exp <- sd(dt$moved[dt$prior_grants >= 1])
sd_y_nov <- sd(dt$moved[dt$prior_grants == 0])

# Main estimate (full sample, IV with controls)
beta_main <- main$iv_ctrl_coef
se_main <- main$iv_ctrl_se
sde_main <- beta_main / sd_y_full
se_sde_main <- se_main / sd_y_full

# Heterogeneous: solo
sde_solo <- hetero$solo_coef / sd_y_solo
se_sde_solo <- hetero$solo_se / sd_y_solo

# Heterogeneous: team
sde_team <- hetero$team_coef / sd_y_team
se_sde_team <- hetero$team_se / sd_y_team

# Heterogeneous: experienced
sde_exp <- hetero$exp_coef / sd_y_exp
se_sde_exp <- hetero$exp_se / sd_y_exp

# Heterogeneous: novice
sde_nov <- hetero$nov_coef / sd_y_nov
se_sde_nov <- hetero$nov_se / sd_y_nov

# Classification function
classify_sde <- function(s) {
  if (is.na(s)) return("---")
  abs_s <- abs(s)
  if (abs_s < 0.005) return("Null")
  if (abs_s < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (abs_s < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

star <- function(beta, se) {
  z <- abs(beta / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.96) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

# Build table rows
sde_rows <- data.frame(
  Outcome = c(
    "\\textit{Panel A: Pooled}",
    "\\quad Interstate mobility (full sample)",
    "",
    "\\textit{Panel B: Heterogeneous}",
    "\\quad Interstate mobility (solo inventors)",
    "\\quad Interstate mobility (team inventors)",
    "\\quad Interstate mobility (experienced)",
    "\\quad Interstate mobility (novice)"
  ),
  Beta = c("", sprintf("%.4f%s", beta_main, star(beta_main, se_main)), "",
           "", sprintf("%.4f%s", hetero$solo_coef, star(hetero$solo_coef, hetero$solo_se)),
           sprintf("%.4f%s", hetero$team_coef, star(hetero$team_coef, hetero$team_se)),
           sprintf("%.4f%s", hetero$exp_coef, star(hetero$exp_coef, hetero$exp_se)),
           sprintf("%.4f%s", hetero$nov_coef, star(hetero$nov_coef, hetero$nov_se))),
  SE = c("", sprintf("(%.4f)", se_main), "",
         "", sprintf("(%.4f)", hetero$solo_se),
         sprintf("(%.4f)", hetero$team_se),
         sprintf("(%.4f)", hetero$exp_se),
         sprintf("(%.4f)", hetero$nov_se)),
  SDY = c("", sprintf("%.3f", sd_y_full), "",
          "", sprintf("%.3f", sd_y_solo), sprintf("%.3f", sd_y_team),
          sprintf("%.3f", sd_y_exp), sprintf("%.3f", sd_y_nov)),
  SDE = c("", sprintf("%.4f", sde_main), "",
          "", sprintf("%.4f", sde_solo), sprintf("%.4f", sde_team),
          sprintf("%.4f", sde_exp), sprintf("%.4f", sde_nov)),
  SESDE = c("", sprintf("(%.4f)", se_sde_main), "",
            "", sprintf("(%.4f)", se_sde_solo), sprintf("(%.4f)", se_sde_team),
            sprintf("(%.4f)", se_sde_exp), sprintf("(%.4f)", se_sde_nov)),
  Class = c("", classify_sde(sde_main), "",
            "", classify_sde(sde_solo), classify_sde(sde_team),
            classify_sde(sde_exp), classify_sde(sde_nov)),
  stringsAsFactors = FALSE
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does patent application rejection at the USPTO cause inventors to relocate across state lines, redistributing knowledge workers geographically? ",
  "\\textbf{Policy mechanism:} The USPTO assigns patent applications to examiners who vary in grant propensity within technology-specific art units; stricter examiners reject more applications, destroying location-specific intellectual property rents and triggering job search in other states. ",
  "\\textbf{Outcome definition:} Binary indicator equal to one if the inventor's next patent filing (within 10 years) lists a different US state than the current filing. ",
  "\\textbf{Treatment:} Binary --- application rejected (abandoned) versus granted (issued). ",
  "\\textbf{Data:} USPTO PAIR via Google BigQuery, 2002--2014 filings, inventor-application level, 4,452,425 observations. ",
  "\\textbf{Method:} 2SLS using leave-one-out examiner grant rate within art-unit $\\times$ filing-year as instrument; clustered standard errors at art-unit $\\times$ year level. ",
  "\\textbf{Sample:} US utility patent applications with resolved outcomes (granted or abandoned), examiners with $\\geq$2 decisions per art-unit-year, art-unit-years with $\\geq$3 examiners. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the sample standard deviation of the mobility indicator. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Patent Rejection and Inventor Mobility}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_rows)) {
  if (sde_rows$Beta[i] == "") {
    sde_lines <- c(sde_lines,
      sprintf("%s & & & & & & \\\\", sde_rows$Outcome[i]))
  } else {
    sde_lines <- c(sde_lines,
      sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
              sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
              sde_rows$SDY[i], sde_rows$SDE[i], sde_rows$SESDE[i],
              sde_rows$Class[i]))
  }
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  sprintf("\\begin{itemize}[leftmargin=*,noitemsep,topsep=2pt] %s \\end{itemize}", sde_notes),
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat("Done.\n")
