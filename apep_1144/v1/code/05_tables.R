# ─── Generate LaTeX Tables for Patent Payroll Illusion ───────────────────────
source("code/00_packages.R")

load("data/models.RData")
load("data/robustness_models.RData")
panel <- fread("data/county_analysis_panel.csv")
panel_main <- panel[!is.na(log_Emp_t1) & !is.na(log_grants) & !is.na(bartik) & is.finite(log_Emp_t1)]

dir.create("tables", showWarnings = FALSE)

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics...\n")

sumstat <- function(x, label) {
  x <- x[!is.na(x) & is.finite(x)]
  sprintf("%-45s & %s & %s & %s & %s & %s \\\\",
          label,
          formatC(mean(x), format = "f", digits = 1, big.mark = ","),
          formatC(sd(x), format = "f", digits = 1, big.mark = ","),
          formatC(min(x), format = "f", digits = 0, big.mark = ","),
          formatC(max(x), format = "f", digits = 0, big.mark = ","),
          formatC(length(x), format = "d", big.mark = ","))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstat}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & $N$ \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Patent Variables}} \\\\[3pt]",
  sumstat(panel_main$grants, "Patent grants (county-year)"),
  sumstat(panel_main$bartik, "Bartik instrument"),
  "[6pt]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Employment Outcomes ($t+1$)}} \\\\[3pt]",
  sumstat(panel_main$Emp_t1 / 1000, "Employment (thousands)"),
  sumstat(panel_main$HirN_t1 / 1000, "New hires (thousands, annual)"),
  sumstat(panel_main$EarnS_t1, "Monthly earnings (\\$)"),
  "[6pt]",
  "\\multicolumn{6}{l}{\\textit{Panel C: Sector Employment ($t+1$, thousands)}} \\\\[3pt]",
  sumstat(panel_main$Emp_exposed_t1[!is.na(panel_main$Emp_exposed_t1)] / 1000,
          "Exposed sectors (Mfg + Info + Prof/Sci)"),
  sumstat(panel_main$Emp_local_svc_t1[!is.na(panel_main$Emp_local_svc_t1)] / 1000,
          "Local services (Retail + Accom + Other)"),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\begin{flushleft}\\small",
  "Notes: Sample consists of 876 US counties with at least 20 patent applications during the 2001--2003 share-construction window, observed annually over 2004--2012. Patent grants are counted by first-inventor county using PatentsView geocoded locations linked to USPTO Patent Examination Research data. Employment outcomes are from the Census Bureau Quarterly Workforce Indicators (QWI), aggregated from quarterly to annual frequency (employment: mean of four quarters; hires: sum). The Bartik instrument is the county-level shift-share instrument constructed from pre-determined (2001--2003) county art-unit patent application shares interacted with leave-one-out examiner leniency shocks.",
  "\\end{flushleft}}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_sumstat.tex")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results (First Stage + OLS + 2SLS)
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results...\n")

fmt_coef <- function(c, s, stars = TRUE) {
  p <- 2 * pnorm(-abs(c / s))
  st <- ""
  if (stars) {
    if (p < 0.01) st <- "^{***}" else if (p < 0.05) st <- "^{**}" else if (p < 0.1) st <- "^{*}"
  }
  sprintf("%.4f%s", c, st)
}
fmt_se <- function(s) sprintf("(%.4f)", s)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Patent Grants and Local Employment: OLS and IV Estimates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & First Stage & OLS & 2SLS & Reduced Form \\\\",
  " & $\\log(\\text{Grants}_{ct})$ & $\\log(\\text{Emp}_{c,t+1})$ & $\\log(\\text{Emp}_{c,t+1})$ & $\\log(\\text{Emp}_{c,t+1})$ \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("Bartik instrument & %s & & & %s \\\\",
          fmt_coef(coef(fs)["bartik"], se(fs)["bartik"]),
          fmt_coef(coef(rf)["bartik"], se(rf)["bartik"])),
  sprintf(" & %s & & & %s \\\\", fmt_se(se(fs)["bartik"]), fmt_se(se(rf)["bartik"])),
  sprintf("$\\log(\\text{Grants}_{ct})$ & & %s & %s & \\\\",
          fmt_coef(coef(ols)["log_grants"], se(ols)["log_grants"]),
          fmt_coef(coef(iv_emp)["fit_log_grants"], se(iv_emp)["fit_log_grants"])),
  sprintf(" & & %s & %s & \\\\",
          fmt_se(se(ols)["log_grants"]), fmt_se(se(iv_emp)["fit_log_grants"])),
  "[6pt]",
  sprintf("County FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("First-stage $F$ & %.1f & & %.1f & \\\\",
          (coef(fs)["bartik"]/se(fs)["bartik"])^2,
          (coef(fs)["bartik"]/se(fs)["bartik"])^2),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(fs), big.mark = ","),
          formatC(nobs(ols), big.mark = ","),
          formatC(nobs(iv_emp), big.mark = ","),
          formatC(nobs(rf), big.mark = ",")),
  sprintf("Counties & %d & %d & %d & %d \\\\", 876, 876, 876, 876),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\begin{flushleft}\\small",
  "Notes: The dependent variable in columns (2)--(4) is log county employment in year $t+1$, measured as the mean of four quarterly QWI observations. Column (1) reports the first stage: the Bartik instrument predicts log patent grants. The Bartik instrument interacts pre-determined (2001--2003) county patent-technology shares with leave-one-out examiner leniency shocks within art-unit-year cells. Column (2) is OLS. Column (3) is 2SLS using the Bartik instrument. Column (4) is the reduced-form effect of the instrument on employment. Standard errors clustered at the county level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{flushleft}}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Robustness...\n")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Null Employment Effect}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Baseline & LIML & State$\\times$Year FE & Contemp. ($t$) & IHS(Grants) \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  sprintf("$\\log(\\text{Grants})$ & %s & %s & %s & %s & \\\\",
          fmt_coef(coef(iv_emp)["fit_log_grants"], se(iv_emp)["fit_log_grants"]),
          fmt_coef(coef_liml, se_liml),
          fmt_coef(coef(iv_sxyr)["fit_log_grants"], se(iv_sxyr)["fit_log_grants"]),
          fmt_coef(coef(iv_contemp)["fit_log_grants"], se(iv_contemp)["fit_log_grants"])),
  sprintf(" & %s & %s & %s & %s & \\\\",
          fmt_se(se(iv_emp)["fit_log_grants"]),
          fmt_se(se_liml),
          fmt_se(se(iv_sxyr)["fit_log_grants"]),
          fmt_se(se(iv_contemp)["fit_log_grants"])),
  sprintf("IHS(Grants) & & & & & %s \\\\",
          fmt_coef(coef(iv_ihs)["fit_ihs_grants"], se(iv_ihs)["fit_ihs_grants"])),
  sprintf(" & & & & & %s \\\\", fmt_se(se(iv_ihs)["fit_ihs_grants"])),
  "[6pt]",
  sprintf("AR $p$-value ($\\beta=0$) & %.3f & & & & \\\\", ar_pval),
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & & Yes & Yes \\\\",
  "State$\\times$Year FE & & & Yes & & \\\\",
  sprintf("First-stage $F$ & %.1f & & %.1f & %.1f & %.1f \\\\",
          (coef(fs)["bartik"]/se(fs)["bartik"])^2,
          fitstat(iv_sxyr, "ivf")[[1]]$stat,
          (coef(fs)["bartik"]/se(fs)["bartik"])^2,
          (coef(fs_ihs)["bartik"]/se(fs_ihs)["bartik"])^2),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(nobs(iv_emp), big.mark = ","),
          formatC(nrow(panel_main), big.mark = ","),
          formatC(nobs(iv_sxyr), big.mark = ","),
          formatC(nobs(iv_contemp), big.mark = ","),
          formatC(nobs(iv_ihs), big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\begin{flushleft}\\small",
  "Notes: All specifications instrument log patent grants with the Bartik examiner-leniency instrument. Column (1) reproduces the baseline from Table \\ref{tab:main}. Column (2) uses LIML estimation with heteroskedasticity-robust standard errors. Column (3) replaces year fixed effects with state$\\times$year fixed effects, exploiting only within-state variation across counties. Column (4) uses contemporaneous employment ($t$) rather than $t+1$. Column (5) uses the inverse hyperbolic sine transformation of grants. The Anderson-Rubin $p$-value tests the null $\\beta = 0$ and is robust to weak instruments. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{flushleft}}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_robust.tex")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Mechanism — Sector Splits + Placebo
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Mechanism...\n")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Mechanism: Sector Heterogeneity and Pre-Trend Placebo}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & All Sectors & Exposed & Local Service & Placebo ($t-1$) \\\\",
  " & $\\log(\\text{Emp}_{c,t+1})$ & $\\log(\\text{Emp}_{c,t+1})$ & $\\log(\\text{Emp}_{c,t+1})$ & $\\log(\\text{Emp}_{c,t-1})$ \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("$\\log(\\text{Grants}_{ct})$ & %s & %s & %s & \\\\",
          fmt_coef(coef(iv_emp)["fit_log_grants"], se(iv_emp)["fit_log_grants"]),
          fmt_coef(coef(iv_exposed)["fit_log_grants"], se(iv_exposed)["fit_log_grants"]),
          fmt_coef(coef(iv_local)["fit_log_grants"], se(iv_local)["fit_log_grants"])),
  sprintf(" & %s & %s & %s & \\\\",
          fmt_se(se(iv_emp)["fit_log_grants"]),
          fmt_se(se(iv_exposed)["fit_log_grants"]),
          fmt_se(se(iv_local)["fit_log_grants"])),
  sprintf("Bartik instrument & & & & %s \\\\",
          fmt_coef(coef(placebo)["bartik"], se(placebo)["bartik"])),
  sprintf(" & & & & %s \\\\", fmt_se(se(placebo)["bartik"])),
  "[6pt]",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(iv_emp), big.mark = ","),
          formatC(nobs(iv_exposed), big.mark = ","),
          formatC(nobs(iv_local), big.mark = ","),
          formatC(nobs(placebo), big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\begin{flushleft}\\small",
  "Notes: Columns (1)--(3) report 2SLS estimates of the effect of log patent grants on log employment in year $t+1$, separately for all sectors, exposed sectors (manufacturing, information, professional/scientific/technical services), and local-service sectors (retail, accommodation/food, other services). Column (4) reports the reduced-form effect of the Bartik instrument on log employment at $t-1$ (pre-treatment placebo). A zero in column (4) supports the identifying assumption that the instrument does not predict pre-existing employment trends. Standard errors clustered at the county level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{flushleft}}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_mechanism.tex")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE F1: SDE Appendix
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table F1: SDE Appendix...\n")

# Compute SDE for main outcomes
compute_sde <- function(beta, se_beta, y_var) {
  sd_y <- sd(y_var, na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- abs(se_beta / sd_y)
  class_label <- if (abs(sde) > 0.15) "Large"
                 else if (abs(sde) > 0.05) "Moderate"
                 else if (abs(sde) > 0.005) "Small"
                 else "Null"
  list(sde = sde, se_sde = se_sde, sd_y = sd_y, class = class_label)
}

# Panel A: Pooled
sde_emp <- compute_sde(coef(iv_emp)["fit_log_grants"], se(iv_emp)["fit_log_grants"], panel_main$log_Emp_t1)
sde_hirn <- compute_sde(coef(iv_hires)["fit_log_grants"], se(iv_hires)["fit_log_grants"],
                        panel_main[!is.na(log_HirN_t1) & is.finite(log_HirN_t1)]$log_HirN_t1)
sde_earn <- compute_sde(coef(iv_earn)["fit_log_grants"], se(iv_earn)["fit_log_grants"],
                        panel_main[!is.na(log_EarnS_t1) & is.finite(log_EarnS_t1)]$log_EarnS_t1)

# Panel B: Heterogeneous (by sector)
sde_exposed <- compute_sde(coef(iv_exposed)["fit_log_grants"], se(iv_exposed)["fit_log_grants"],
                           panel_main[!is.na(log_Emp_exposed_t1) & is.finite(log_Emp_exposed_t1)]$log_Emp_exposed_t1)
sde_local <- compute_sde(coef(iv_local)["fit_log_grants"], se(iv_local)["fit_log_grants"],
                         panel_main[!is.na(log_Emp_local_svc_t1) & is.finite(log_Emp_local_svc_t1)]$log_Emp_local_svc_t1)

fmt_sde_row <- function(label, beta, se_b, sd_y, sde_val, se_sde, cl) {
  sprintf("%-40s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          label, beta, se_b, sd_y, sde_val, se_sde, cl)
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Distributional Effects}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  fmt_sde_row("Employment ($t+1$)", coef(iv_emp)["fit_log_grants"], se(iv_emp)["fit_log_grants"],
              sde_emp$sd_y, sde_emp$sde, sde_emp$se_sde, sde_emp$class),
  fmt_sde_row("New hires ($t+1$)", coef(iv_hires)["fit_log_grants"], se(iv_hires)["fit_log_grants"],
              sde_hirn$sd_y, sde_hirn$sde, sde_hirn$se_sde, sde_hirn$class),
  fmt_sde_row("Monthly earnings ($t+1$)", coef(iv_earn)["fit_log_grants"], se(iv_earn)["fit_log_grants"],
              sde_earn$sd_y, sde_earn$sde, sde_earn$se_sde, sde_earn$class),
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sector Splits)}} \\\\[3pt]",
  fmt_sde_row("Exposed sectors ($t+1$)", coef(iv_exposed)["fit_log_grants"], se(iv_exposed)["fit_log_grants"],
              sde_exposed$sd_y, sde_exposed$sde, sde_exposed$se_sde, sde_exposed$class),
  fmt_sde_row("Local-service sectors ($t+1$)", coef(iv_local)["fit_log_grants"], se(iv_local)["fit_log_grants"],
              sde_local$sd_y, sde_local$sde, sde_local$se_sde, sde_local$class),
  "\\hline\\hline",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\begin{flushleft}\\small",
  paste0("\\textbf{Country:} United States. ",
         "\\textbf{Research question:} Do examiner-induced patent grants cause local employment growth? ",
         "\\textbf{Policy mechanism:} USPTO patent examination quasi-random examiner assignment. ",
         "\\textbf{Outcome definition:} Log county-level QWI employment, hires, and earnings at $t+1$. ",
         "\\textbf{Treatment:} Log patent grants instrumented by Bartik examiner-leniency shock. ",
         "\\textbf{Data:} USPTO PatEx (BigQuery) linked to PatentsView for county geography; Census QWI (LEHD). ",
         "\\textbf{Method:} 2SLS with Bartik shift-share IV (pre-determined county art-unit shares $\\times$ LOO examiner leniency shocks). ",
         "\\textbf{Sample:} 876 US counties with $\\geq$20 patent applications in 2001--2003, observed 2004--2012. ",
         "Classification refers to magnitude, not statistical significance. ",
         "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
         "Large: $|\\text{SDE}| > 0.15$; Moderate: $0.05$--$0.15$; Small: $0.005$--$0.05$; Null: $< 0.005$."),
  "\\end{flushleft}}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
