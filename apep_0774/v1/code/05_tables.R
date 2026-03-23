# 05_tables.R — Generate all tables for apep_0774
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "panel.rds"))
panel[, treated := as.integer(event_treatment == "severe")]
panel[, post := as.integer(event_time >= 0)]
main <- readRDS(file.path(data_dir, "main_models.rds"))
rob <- readRDS(file.path(data_dir, "robustness_models.rds"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
t0 <- panel[event_time == 0]

tab1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics by Inspection Outcome}\n\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n\\toprule\n",
  " & Severe ($\\geq$3 S\\&S) & Clean (0 S\\&S) \\\\\n\\midrule\n",
  sprintf("Inspection events & %s & %s \\\\\n",
          formatC(t0[event_treatment == "severe", .N], big.mark = ","),
          formatC(t0[event_treatment == "clean", .N], big.mark = ",")),
  sprintf("Unique mines & %s & %s \\\\\n",
          formatC(t0[event_treatment == "severe", uniqueN(MINE_ID)], big.mark = ","),
          formatC(t0[event_treatment == "clean", uniqueN(MINE_ID)], big.mark = ",")),
  sprintf("Mean employees & %.1f & %.1f \\\\\n",
          t0[event_treatment == "severe", mean(emp)],
          t0[event_treatment == "clean", mean(emp)]),
  sprintf("Median employees & %.0f & %.0f \\\\\n",
          t0[event_treatment == "severe", median(emp)],
          t0[event_treatment == "clean", median(emp)]),
  sprintf("Mean quarterly hours & %s & %s \\\\\n",
          formatC(t0[event_treatment == "severe", round(mean(hours))], big.mark = ","),
          formatC(t0[event_treatment == "clean", round(mean(hours))], big.mark = ",")),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Statistics at event time zero (the quarter of the inspection). ",
  "``Severe'' inspections found $\\geq$3 Significant \\& Substantial violations. ",
  "``Clean'' inspections found zero S\\&S violations. ",
  "Sample restricted to regular (E01) MSHA safety inspections, 2000--2024.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))


# =============================================================================
# Table 2: Main Results
# =============================================================================
m2 <- main$m2  # DiD log emp
m4 <- main$m4  # DiD level emp
m5 <- main$m5  # DiD log hours

tab2 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Effect of Severe Inspection Findings on Mine Employment}\n\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Log Employees & Employees & Log Hours \\\\\n\\midrule\n",
  sprintf("Severe $\\times$ Post & %.4f$^{***}$ & %.3f$^{***}$ & %.4f$^{***}$ \\\\\n",
          coef(m2)[1], coef(m4)[1], coef(m5)[1]),
  sprintf(" & (%.4f) & (%.3f) & (%.4f) \\\\\n",
          se(m2)[1], se(m4)[1], se(m5)[1]),
  "\\midrule\n",
  "Mine FE & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Event FE & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(nobs(m2), big.mark = ","),
          formatC(nobs(m4), big.mark = ","),
          formatC(nobs(m5), big.mark = ",")),
  sprintf("Mines & %s & %s & %s \\\\\n",
          formatC(24109, big.mark = ","),
          formatC(24109, big.mark = ","),
          formatC(24109, big.mark = ",")),
  "Clustering & Mine & Mine & Mine \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Stacked event-study DiD comparing mines receiving severe ",
  "($\\geq$3 S\\&S violations) vs.\\ clean (0 S\\&S) regular MSHA inspections. ",
  "``Post'' indicates quarters 0--8 after the inspection. Event FE absorb ",
  "event-specific levels; mine FE absorb time-invariant mine characteristics. ",
  "Standard errors clustered at the mine level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))


# =============================================================================
# Table 3: Event Study Coefficients
# =============================================================================
m1 <- main$m1
es_coefs <- data.table(
  event_time = c(-4:-2, 0:8),
  coef = coef(m1),
  se = se(m1)
)

tab3 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Event-Study Coefficients: Log Employment}\n\\label{tab:event_study}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  "Event Quarter & Coefficient & SE & 95\\% CI \\\\\n\\midrule\n",
  paste(sprintf("$t%+d$ & %.4f & (%.4f) & [%.4f, %.4f] \\\\\n",
                es_coefs$event_time, es_coefs$coef, es_coefs$se,
                es_coefs$coef - 1.96 * es_coefs$se,
                es_coefs$coef + 1.96 * es_coefs$se), collapse = ""),
  "\\midrule\n",
  "$t-1$ (reference) & 0 & --- & --- \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Coefficients from interacting event-time dummies with a ",
  "``severe'' indicator ($\\geq$3 S\\&S violations). Reference period is $t-1$. ",
  "Mine and event fixed effects included. Standard errors clustered at the mine level.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab3, file.path(table_dir, "tab3_event_study.tex"))


# =============================================================================
# Table 4: Robustness
# =============================================================================
tab4 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coefficient & SE & $N$ \\\\\n\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: By Mine Type}} \\\\\n",
  sprintf("Coal mines & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$coal)[1], se(rob$coal)[1],
          formatC(nobs(rob$coal), big.mark = ",")),
  sprintf("Metal/nonmetal mines & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$metal)[1], se(rob$metal)[1],
          formatC(nobs(rob$metal), big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Dose-Response (Ref: 0 S\\&S)}} \\\\\n",
  sprintf("3--5 S\\&S $\\times$ Post & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$dose)[2], se(rob$dose)[2],
          formatC(nobs(rob$dose), big.mark = ",")),
  sprintf("6--10 S\\&S $\\times$ Post & %.4f$^{***}$ & (%.4f) & \\\\\n",
          coef(rob$dose)[3], se(rob$dose)[3]),
  sprintf("10+ S\\&S $\\times$ Post & %.4f$^{***}$ & (%.4f) & \\\\\n",
          coef(rob$dose)[1], se(rob$dose)[1]),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Sample Restrictions}} \\\\\n",
  sprintf("Large mines ($\\geq$20 emp.) & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$large)[1], se(rob$large)[1],
          formatC(nobs(rob$large), big.mark = ",")),
  sprintf("Post-2010 sample & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$post2010)[1], se(rob$post2010)[1],
          formatC(nobs(rob$post2010), big.mark = ",")),
  sprintf("State-clustered SE & %.4f$^{***}$ & (%.4f) & %s \\\\\n",
          coef(rob$state_cluster)[1], se(rob$state_cluster)[1],
          formatC(nobs(rob$state_cluster), big.mark = ",")),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include mine and event fixed effects. ",
  "Dependent variable is log(employees). Panels A and C use the binary severe$\\times$post treatment. ",
  "Panel B uses dose bins of S\\&S violation counts. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))


# =============================================================================
# Table F1: Standardized Effect Size (SDE)
# =============================================================================
sd_y <- sd(panel$log_emp, na.rm = TRUE)
beta <- coef(main$m2)[1]
se_beta <- se(main$m2)[1]
sde <- beta / sd_y
se_sde <- se_beta / sd_y

sd_y_hrs <- sd(panel[, log(pmax(hours, 1))], na.rm = TRUE)
beta_hrs <- coef(main$m5)[1]
se_hrs <- se(main$m5)[1]
sde_hrs <- beta_hrs / sd_y_hrs
se_sde_hrs <- se_hrs / sd_y_hrs

classify <- function(s) {
  a <- abs(s)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (a < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do workers reduce employment at mines where mandatory ",
  "safety inspections reveal serious violations, testing the worker information channel ",
  "of compensating differentials at the establishment level? ",
  "\\textbf{Policy mechanism:} MSHA conducts mandatory regular safety inspections of ",
  "every active mine (4x/year underground, 2x/year surface); inspection results, including ",
  "Significant \\& Substantial violation citations, are publicly posted within days, ",
  "revealing pre-existing hazardous conditions to workers. ",
  "\\textbf{Outcome definition:} (Row 1) Log average quarterly employee count from MSHA ",
  "administrative employment records; (Row 2) Log total quarterly hours worked. ",
  "\\textbf{Treatment:} Binary: regular inspection finding $\\geq$3 S\\&S violations ",
  "(``severe'') vs.\\ 0 S\\&S violations (``clean''). ",
  "\\textbf{Data:} MSHA Open Government Data: Inspections (516K regular inspections), ",
  "Violations (3.06M records), MinesProdQuarterly (2.71M mine-quarter records), 2000--2024. ",
  "Panel of 4.1M mine-event-quarter observations. ",
  "\\textbf{Method:} Stacked event-study DiD with mine and event fixed effects, ",
  "standard errors clustered at mine level (24,109 mines). ",
  "\\textbf{Sample:} All active US mines receiving regular MSHA safety inspections, ",
  "restricted to events with at least 10 of 13 quarters observable. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard ",
  "deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), ",
  "Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  sprintf("Log employees & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\\n",
          beta, se_beta, sd_y, sde, se_sde, classify(sde)),
  sprintf("Log hours worked & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_hrs, se_hrs, sd_y_hrs, sde_hrs, se_sde_hrs, classify(sde_hrs)),
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))


cat("All tables generated:\n")
for (f in list.files(table_dir)) cat("  ", f, "\n")
