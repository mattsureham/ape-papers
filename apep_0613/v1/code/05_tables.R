# 05_tables.R — Generate all LaTeX tables
# apep_0613: Female mayors and fiscal composition in Mexico

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

load(file.path(data_dir, "rdd_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# ─── Table 1: Summary Statistics ──────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

# Full sample vs close elections (|margin| < 10%)
close <- analysis %>% filter(abs(female_margin) < 0.10)

sum_vars <- c("female_margin", "share_serv_pers", "share_transfers",
              "share_inv_pub", "share_mat_sum", "share_serv_gen",
              "log_total_exp")
sum_labels <- c("Female vote margin", "Admin payroll share",
                "Social transfers share", "Public investment share",
                "Materials share", "General services share",
                "Log total expenditure")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Full Sample} & \\multicolumn{3}{c}{$|$Margin$|$ $<$ 10\\%} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule"
)

for (i in seq_along(sum_vars)) {
  v <- sum_vars[i]
  full_m <- sprintf("%.3f", mean(analysis[[v]], na.rm = TRUE))
  full_sd <- sprintf("%.3f", sd(analysis[[v]], na.rm = TRUE))
  full_n <- sum(!is.na(analysis[[v]]))
  cl_m <- sprintf("%.3f", mean(close[[v]], na.rm = TRUE))
  cl_sd <- sprintf("%.3f", sd(close[[v]], na.rm = TRUE))
  cl_n <- sum(!is.na(close[[v]]))
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %d & %s & %s & %d \\\\",
            sum_labels[i], full_m, full_sd, full_n, cl_m, cl_sd, cl_n))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Female mayor wins & \\multicolumn{3}{c}{%d (%.1f\\%%)} & \\multicolumn{3}{c}{%d (%.1f\\%%)} \\\\",
          sum(analysis$dmujer == 1), 100*mean(analysis$dmujer),
          sum(close$dmujer == 1), 100*mean(close$dmujer)),
  sprintf("Unique municipalities & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          n_distinct(analysis$inegi), n_distinct(close$inegi)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample of mixed-gender municipal elections in Mexico, 2008--2022. Female vote margin is positive when the female candidate won. Spending shares are three-year term averages from INEGI EFIPEM data. Close elections defined as $|$margin$|$ $<$ 10\\%.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))

# ─── Table 2: Main RDD Results ───────────────────────────────────────────
cat("Generating Table 2: Main RDD Results\n")

main_vars <- c("share_serv_pers", "share_transfers", "share_inv_pub",
               "share_mat_sum", "share_serv_gen", "log_total_exp")
main_labels <- c("Payroll", "Transfers", "Investment",
                 "Materials", "Gen.\\ Serv.", "Log Exp.")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Effect of Female Mayors on Municipal Spending Composition}",
  "\\label{tab:main}",
  "\\footnotesize",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(main_vars)), collapse = "")),
  "\\toprule"
)

# Column headers
header <- " "
for (l in main_labels) header <- paste0(header, " & ", l)
tab2_lines <- c(tab2_lines, paste0(header, " \\\\"))

# Column numbers
nums <- " "
for (i in seq_along(main_labels)) nums <- paste0(nums, sprintf(" & (%d)", i))
tab2_lines <- c(tab2_lines, paste0(nums, " \\\\"), "\\midrule")

# RDD estimates
coef_line <- "Female Mayor"
se_line <- " "
for (v in main_vars) {
  r <- rdd_results[[v]]
  coef_line <- paste0(coef_line, sprintf(" & %.4f%s", r$coef_conv, stars(r$p_robust)))
  se_line <- paste0(se_line, sprintf(" & (%.4f)", r$se_robust))
}
tab2_lines <- c(tab2_lines, paste0(coef_line, " \\\\"), paste0(se_line, " \\\\"))

# Dep var mean
mean_line <- "Dep. var. mean"
for (v in main_vars) {
  r <- rdd_results[[v]]
  mean_line <- paste0(mean_line, sprintf(" & %.3f", r$dep_mean))
}
tab2_lines <- c(tab2_lines, "\\midrule", paste0(mean_line, " \\\\"))

# Bandwidth
bw_line <- "Bandwidth"
for (v in main_vars) {
  r <- rdd_results[[v]]
  bw_line <- paste0(bw_line, sprintf(" & %.3f", r$bw))
}
tab2_lines <- c(tab2_lines, paste0(bw_line, " \\\\"))

# Effective N
n_line <- "Eff. obs."
for (v in main_vars) {
  r <- rdd_results[[v]]
  n_line <- paste0(n_line, sprintf(" & %d", r$n_total))
}
tab2_lines <- c(tab2_lines, paste0(n_line, " \\\\"))

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Local polynomial RDD estimates using \\texttt{rdrobust} with CCT optimal bandwidth and triangular kernel. Outcomes are three-year term averages. Robust bias-corrected standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ─── Table 3: Covariate Balance & Density ─────────────────────────────────
cat("Generating Table 3: Balance Tests\n")

bal_labels <- c("Pre-period total exp.\\ (millions)", "Pre-period admin payroll share",
                "Pre-period transfers share", "Pre-period investment share",
                "Pre-period log total exp.")
bal_vars <- c("pre_total_exp", "pre_share_serv_pers",
              "pre_share_transfers", "pre_share_inv_pub",
              "pre_log_total_exp")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{RDD Validity: Covariate Balance and Manipulation Tests}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Coeff. & Robust SE & $p$-value & Bandwidth & Eff. N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Covariate balance at the cutoff}} \\\\"
)

for (i in seq_along(bal_vars)) {
  v <- bal_vars[i]
  if (!is.null(balance_results[[v]])) {
    r <- balance_results[[v]]
    if (v == "pre_total_exp") {
      # Scale to millions for readability
      tab3_lines <- c(tab3_lines,
        sprintf("%s & %.1f & %.1f & %.3f & %.3f & %d \\\\",
                bal_labels[i], r$coef / 1e6, r$se / 1e6, r$p, r$bw, r$n_eff))
    } else {
      tab3_lines <- c(tab3_lines,
        sprintf("%s & %.4f & %.4f & %.3f & %.3f & %d \\\\",
                bal_labels[i], r$coef, r$se, r$p, r$bw, r$n_eff))
    }
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: McCrary density test}} \\\\",
  sprintf("Density test & \\multicolumn{2}{c}{$t = %.3f$} & %.3f & & %d \\\\",
          density_result$t_stat, density_result$p_value,
          density_result$n_left + density_result$n_right),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A: RDD estimates of pre-election (election year) fiscal variables at the cutoff. A significant coefficient would indicate selection. Panel B: Cattaneo, Jansson, and Ma (2020) density test for manipulation of the running variable. The null hypothesis is no discontinuity in the density at the cutoff.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_balance.tex"))

# ─── Table 4: Bandwidth Sensitivity ──────────────────────────────────────
cat("Generating Table 4: Bandwidth Sensitivity\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Bandwidth Sensitivity}",
  "\\label{tab:bandwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Admin Payroll & Social Transfers & Public Investment \\\\",
  "\\midrule"
)

bw_mults <- c("0.5", "0.75", "1", "1.5", "2")
bw_names <- c("$h/2$", "$3h/4$", "$h^*$ (optimal)", "$3h/2$", "$2h$")

for (j in seq_along(bw_mults)) {
  m <- bw_mults[j]
  line <- bw_names[j]
  for (v in c("share_serv_pers", "share_transfers", "share_inv_pub")) {
    r <- bw_sensitivity[[v]][[m]]
    line <- paste0(line, sprintf(" & %.4f%s", r$coef, stars(r$p_robust)))
  }
  tab4_lines <- c(tab4_lines, paste0(line, " \\\\"))

  # SE line
  se_ln <- " "
  for (v in c("share_serv_pers", "share_transfers", "share_inv_pub")) {
    r <- bw_sensitivity[[v]][[m]]
    se_ln <- paste0(se_ln, sprintf(" & (%.4f)", r$se_robust))
  }
  tab4_lines <- c(tab4_lines, paste0(se_ln, " \\\\"))
}

# Donut RDD
tab4_lines <- c(tab4_lines, "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Donut RDD (exclude $|$margin$|$ $<$ 0.5\\%)}} \\\\")
donut_line <- "Donut"
donut_se <- " "
for (v in c("share_serv_pers", "share_transfers", "share_inv_pub")) {
  r <- donut_results[[v]]
  donut_line <- paste0(donut_line, sprintf(" & %.4f%s", r$coef, stars(r$p_robust)))
  donut_se <- paste0(donut_se, sprintf(" & (%.4f)", r$se_robust))
}
tab4_lines <- c(tab4_lines, paste0(donut_line, " \\\\"), paste0(donut_se, " \\\\"))

# Covariate-adjusted and change specification (payroll only)
if (!is.null(cov_adj_payroll)) {
  tab4_lines <- c(tab4_lines, "\\midrule",
    "\\multicolumn{4}{l}{\\textit{Covariate-adjusted RDD (payroll only)}} \\\\",
    sprintf("Residualized on pre-payroll & %.4f%s & & \\\\",
            cov_adj_payroll$coef, stars(cov_adj_payroll$p_robust)),
    sprintf(" & (%.4f) & & \\\\", cov_adj_payroll$se_robust))
}
if (!is.null(change_result)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Change from pre-period & %.4f%s & & \\\\",
            change_result$coef, stars(change_result$p_robust)),
    sprintf(" & (%.4f) & & \\\\", change_result$se_robust))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the RDD coefficient from \\texttt{rdrobust} with triangular kernel. $h^*$ is the CCT optimal bandwidth. Robust standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_bandwidth.tex"))

# ─── Table F1: Standardized Effect Sizes (SDE) ──────────────────────────
cat("Generating Table F1: Standardized Effect Sizes\n")

sde_outcomes <- c("share_serv_pers", "share_transfers", "share_inv_pub")
sde_labels <- c("Admin payroll share", "Social transfers share",
                "Public investment share")

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

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

for (i in seq_along(sde_outcomes)) {
  v <- sde_outcomes[i]
  r <- rdd_results[[v]]

  sde_val <- r$coef_conv / r$dep_sd
  sde_se <- r$se_robust / r$dep_sd
  class_label <- classify_sde(sde_val)

  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
            sde_labels[i], r$coef_conv, r$se_robust, r$dep_sd,
            sde_val, sde_se, class_label))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standardized effect sizes computed as $\\text{SDE} = \\hat{\\beta} / \\text{SD}(Y)$ where $\\hat{\\beta}$ is the RDD coefficient (binary treatment: female vs.\\ male mayor) and SD($Y$) is the standard deviation of the outcome in the full sample. Classification follows the 7-bucket system: large ($|$SDE$|$ $>$ 0.15), moderate (0.05--0.15), small (0.005--0.05), null ($<$ 0.005). Classifications refer to effect magnitude, not statistical significance. Research question: Does electing a female mayor change municipal spending composition? Data: INEGI EFIPEM municipal finances merged with emagar election data (mixed-gender races, 2008--2022). Method: Local polynomial RDD at the close-election cutoff. Sample: 468 municipality-elections; effective sample varies by bandwidth.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in tables/ directory.\n")
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
