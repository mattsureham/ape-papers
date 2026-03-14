## 05_tables.R — Generate all LaTeX tables
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out

source("00_packages.R")

paper_dir <- dirname(getwd())
data_dir <- file.path(paper_dir, "data")
tables_dir <- file.path(paper_dir, "tables")
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

N_la <- n_distinct(panel$la_code)
N_obs <- nrow(panel)

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[post_levy == 0]
post <- panel[post_levy == 1]
levy_vals <- unique(panel[, .(la_code, levy_exposure)])

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome variable}} \\\\\n",
  sprintf("Apprenticeship starts (pre-Levy) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          mean(pre$starts), sd(pre$starts), min(pre$starts), max(pre$starts)),
  sprintf("Apprenticeship starts (post-Levy) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          mean(post$starts), sd(post$starts), min(post$starts), max(post$starts)),
  sprintf("Change (\\%%) & \\multicolumn{4}{c}{%.1f\\%%} \\\\\n",
          (mean(post$starts) / mean(pre$starts) - 1) * 100),
  "[4pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment variable (cross-sectional)}} \\\\\n",
  sprintf("Share of 250+ employee enterprises & %.4f & %.4f & %.4f & %.4f \\\\\n",
          mean(levy_vals$levy_exposure), sd(levy_vals$levy_exposure),
          min(levy_vals$levy_exposure), max(levy_vals$levy_exposure)),
  "[4pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Panel dimensions}} \\\\\n",
  sprintf("Local Authorities & \\multicolumn{4}{c}{%d} \\\\\n", N_la),
  sprintf("Academic years & \\multicolumn{4}{c}{%d-%d} \\\\\n",
          min(panel$acad_year), max(panel$acad_year)),
  sprintf("Pre-Levy years & \\multicolumn{4}{c}{%d} \\\\\n",
          length(unique(pre$acad_year))),
  sprintf("Post-Levy years & \\multicolumn{4}{c}{%d} \\\\\n",
          length(unique(post$acad_year))),
  sprintf("Total observations & \\multicolumn{4}{c}{%s} \\\\\n",
          format(N_obs, big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Data from GOV.UK FE Data Library (apprenticeship starts by Local Authority, ",
  "2010/11--2019/20) and NOMIS UK Business Counts (2016). Apprenticeship starts are total starts ",
  "across all levels per Local Authority per academic year. Levy exposure is the share of enterprises ",
  "with 250+ employees, measured in 2016 (pre-Levy). The Apprenticeship Levy was introduced in ",
  "April 2017, corresponding to academic year 2017/18.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ==============================================================================
# Table 2: Main Results
# ==============================================================================
cat("=== Table 2: Main Results ===\n")

etable(models$m1, models$m4, models$m2,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main.tex"),
       title = "The Apprenticeship Levy and Local Training Volume",
       label = "tab:main",
       headers = c("log(Starts)", "asinh(Starts)", "Starts"),
       dict = c(levy_x_post = "Levy Exposure $\\times$ Post"),
       notes = paste0(
         "Cluster-robust standard errors at the Local Authority level. ",
         "Levy Exposure is the 2016 share of enterprises with 250+ employees. ",
         "Post equals one for academic years 2017/18 and later. ",
         "All specifications include LA and year fixed effects. ",
         "Sample: ", N_la, " English LAs, 2010/11--2019/20."
       ),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "r2", "ar2"))

# ==============================================================================
# Table 3: Event Study Coefficients
# ==============================================================================
cat("=== Table 3: Event Study ===\n")

es <- fread(file.path(data_dir, "event_study_coefs.csv"))

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of Levy Exposure}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event Time & Estimate & SE & 95\\% CI \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es))) {
  r <- es[i]
  if (r$event_time == -1) {
    tab3_tex <- paste0(tab3_tex, sprintf(
      "$t = %d$ (ref.) & --- & --- & --- \\\\\n", r$event_time))
  } else {
    tab3_tex <- paste0(tab3_tex, sprintf(
      "$t = %d$ & %.4f & (%.4f) & [%.4f, %.4f] \\\\\n",
      r$event_time, r$estimate, r$se, r$ci_lo, r$ci_hi))
  }
}

tab3_tex <- paste0(
  tab3_tex,
  "\\hline\n",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\\n", format(N_obs, big.mark = ",")),
  sprintf("Local Authorities & \\multicolumn{3}{c}{%d} \\\\\n", N_la),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Coefficients from regressing log(starts) on interactions of levy exposure ",
  "with event-time indicators, with LA and year FE. $t = -1$ (2016/17) is the reference period. ",
  "Cluster-robust SEs at the LA level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_eventstudy.tex"))

# ==============================================================================
# Table 4: Robustness
# ==============================================================================
cat("=== Table 4: Robustness ===\n")

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Estimate & SE & $p$-value & $N$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Specification}} \\\\\n",
  sprintf("Baseline & %.4f & (%.4f) & %.4f & %s \\\\\n",
          coef(models$m1)[[1]], se(models$m1)[[1]], pvalue(models$m1)[[1]],
          format(nobs(models$m1), big.mark = ",")),
  sprintf("Drop 2019/20 (COVID truncated) & %.4f & (%.4f) & %.4f & %s \\\\\n",
          coef(rob$m_no2019)[[1]], se(rob$m_no2019)[[1]], pvalue(rob$m_no2019)[[1]],
          format(nobs(rob$m_no2019), big.mark = ",")),
  sprintf("Trim extreme exposure (5--95\\%%) & %.4f & (%.4f) & %.4f & %s \\\\\n",
          coef(rob$m_trim)[[1]], se(rob$m_trim)[[1]], pvalue(rob$m_trim)[[1]],
          format(nobs(rob$m_trim), big.mark = ",")),
  "[4pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Inference}} \\\\\n",
  sprintf("RI $p$-value (500 permutations) & \\multicolumn{4}{c}{%.4f} \\\\\n",
          rob$ri_pvalue),
  "[4pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Leave-one-out}} \\\\\n"
)

loo <- rob$loo_dt
for (i in seq_len(nrow(loo))) {
  tab4_tex <- paste0(tab4_tex, sprintf(
    "Drop %s & %.4f & (%.4f) & %.4f & \\\\\n",
    loo$dropped_name[i], loo$coef[i], loo$se[i], loo$pval[i]))
}

tab4_tex <- paste0(
  tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(apprenticeship starts). ",
  "All specifications include LA and year FE with cluster-robust SEs. ",
  "Panel B permutes levy exposure across LAs. ",
  "Panel C drops the five largest LAs.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))

# ==============================================================================
# SDE Table (Appendix — MANDATORY)
# ==============================================================================
cat("=== SDE Table ===\n")

sd_y <- sd(panel$log_starts, na.rm = TRUE)
sd_x <- sd(panel$levy_exposure, na.rm = TRUE)
beta_main <- coef(models$m1)[[1]]
se_main <- se(models$m1)[[1]]
sde_main <- beta_main * sd_x / sd_y
se_sde <- se_main * sd_x / sd_y

# Levels
sd_y_lev <- sd(panel$starts, na.rm = TRUE)
beta_lev <- coef(models$m2)[[1]]
se_lev <- se(models$m2)[[1]]
sde_lev <- beta_lev * sd_x / sd_y_lev
se_sde_lev <- se_lev * sd_x / sd_y_lev

classify <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde < 0.005) "Null"
  else if (sde < 0.05) "Small positive"
  else if (sde < 0.15) "Moderate positive"
  else "Large positive"
}

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  sprintf("log(Starts) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_main, se_main, sd_y, sde_main, se_sde, classify(sde_main)),
  sprintf("Starts (levels) & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\\n",
          beta_lev, se_lev, sd_y_lev, sde_lev, se_sde_lev, classify(sde_lev)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\small\n",
  "\\item \\textit{Notes:} SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ ",
  "(continuous treatment). Treatment: share of 250+ employee enterprises (2016). ",
  sprintf("Sample: %s observations, %d LAs, 2010/11--2019/20. ",
          format(N_obs, big.mark = ","), N_la),
  "Classification refers to effect magnitude, not statistical significance.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
for (f in list.files(tables_dir)) cat(sprintf("  %s\n", f))
