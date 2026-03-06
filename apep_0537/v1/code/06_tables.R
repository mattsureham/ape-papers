## 06_tables.R — Generate all tables for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")
data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
res_entry <- readRDS(file.path(data_dir, "results_oews_entry_share.rds"))
res_ddd <- readRDS(file.path(data_dir, "results_ddd.rds"))
res_qcew <- readRDS(file.path(data_dir, "results_qcew.rds"))
res_het <- readRDS(file.path(data_dir, "results_heterogeneity.rds"))
rob <- readRDS(file.path(data_dir, "results_robustness.rds"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("--- Table 1: Summary Statistics ---\n")

seniority_trends <- fread(file.path(data_dir, "summary_seniority_trends.csv"))
ddd_panel <- fread(file.path(data_dir, "ddd_panel.csv"))

# Panel A: OEWS Employment Shares
tab1a <- seniority_trends[seniority %in% c("Entry-Level", "Mid-Level", "Senior"),
  .(Mean = mean(emp_share), SD = sd(emp_share),
    Min = min(emp_share), Max = max(emp_share),
    N_Years = .N),
  by = seniority
]

# Panel B: Industry AIOE
ind_aioe <- unique(ddd_panel[!is.na(aioe_industry), .(naics_2d, aioe_industry)])
tab1b <- data.table(
  Variable = c("AI Industry Exposure (AIIE)", "N Industries"),
  Mean = c(mean(ind_aioe$aioe_industry), nrow(ind_aioe)),
  SD = c(sd(ind_aioe$aioe_industry), NA),
  Min = c(min(ind_aioe$aioe_industry), NA),
  Max = c(max(ind_aioe$aioe_industry), NA)
)

fwrite(tab1a, file.path(tab_dir, "tab1a_summary_seniority.csv"))
fwrite(tab1b, file.path(tab_dir, "tab1b_summary_aioe.csv"))

# LaTeX table
sink(file.path(tab_dir, "table1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & Mean & SD & Min & Max & N \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Employment Shares by Seniority (OEWS, 2015--2024)}} \\\\\n")
for (i in seq_len(nrow(tab1a))) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %d \\\\\n",
              tab1a$seniority[i], tab1a$Mean[i], tab1a$SD[i],
              tab1a$Min[i], tab1a$Max[i], tab1a$N_Years[i]))
}
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: AI Industry Exposure (AIIE)}} \\\\\n")
cat(sprintf("AIIE Score & %.3f & %.3f & %.3f & %.3f & %d \\\\\n",
            mean(ind_aioe$aioe_industry), sd(ind_aioe$aioe_industry),
            min(ind_aioe$aioe_industry), max(ind_aioe$aioe_industry),
            nrow(ind_aioe)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\end{table}\n")
sink()

cat("  Saved table1_summary.tex\n")

# ===========================================================================
# Table 2: Main Results — Entry-Level and Senior Share DiD
# ===========================================================================
cat("--- Table 2: Main Results ---\n")

models_main <- list(
  "(1)" = res_entry$m1a,
  "(2)" = res_entry$m1c,
  "(3)" = res_entry$m1d
)

# Create Table 2 manually for precise control
sink(file.path(tab_dir, "table2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of AI Exposure on Entry-Level Employment}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & Entry Share & Entry Share & ln(Entry Emp) \\\\\n")
cat("\\hline\n")

# Extract coefficients
for (m_name in names(models_main)) {
  m <- models_main[[m_name]]
  ct <- coeftable(m)
  coef_val <- ct[1, 1]
  se_val <- ct[1, 2]
  p_val <- ct[1, 4]
  stars <- ifelse(p_val < 0.01, "***",
           ifelse(p_val < 0.05, "**",
           ifelse(p_val < 0.1, "*", "")))
  if (m_name == "(1)") {
    cat(sprintf("AIOE $\\times$ Post & %.4f%s & & \\\\\n", coef_val, stars))
    cat(sprintf(" & (%.4f) & & \\\\\n", se_val))
  } else if (m_name == "(2)") {
    cat(sprintf("High AIOE $\\times$ Post & & %.4f%s & \\\\\n", coef_val, stars))
    cat(sprintf(" & & (%.4f) & \\\\\n", se_val))
  } else {
    cat(sprintf("AIOE $\\times$ Post & & & %.4f%s \\\\\n", coef_val, stars))
    cat(sprintf(" & & & (%.4f) \\\\\n", se_val))
  }
}

# Senior share comparison
ct_senior <- coeftable(readRDS(file.path(data_dir, "results_oews_entry_share.rds"))$m1a)

cat("\\hline\n")
cat("Industry FE & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes \\\\\n")
nobs <- sapply(models_main, function(m) m$nobs)
cat(sprintf("N & %d & %d & %d \\\\\n", nobs[1], nobs[2], nobs[3]))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item Notes: Standard errors clustered at the 2-digit NAICS level in parentheses.\n")
cat("* p < 0.10, ** p < 0.05, *** p < 0.01.\n")
cat("AIOE is the Felten-Raj-Seamans AI Occupational Exposure score aggregated to the industry level.\n")
cat("Post = 1 for years 2023--2024. Entry-level occupations are O*NET Job Zones 1--2.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved table2_main_results.tex\n")

# ===========================================================================
# Table 3: Triple-Difference Results
# ===========================================================================
cat("--- Table 3: Triple-Difference ---\n")

sink(file.path(tab_dir, "table3_ddd.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Triple-Difference: AI Exposure $\\times$ Seniority $\\times$ Post}\n")
cat("\\label{tab:ddd}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & ln(Employment) & ln(Employment) \\\\\n")
cat(" & Continuous AIOE & Binary AIOE \\\\\n")
cat("\\hline\n")

# DDD continuous
ct2a <- coeftable(res_ddd$m2a)
for (i in seq_len(nrow(ct2a))) {
  p <- ct2a[i, 4]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  rn <- rownames(ct2a)[i]
  if (i == 1) {
    cat(sprintf("AIOE $\\times$ Junior $\\times$ Post & %.4f%s & \\\\\n", ct2a[i, 1], stars))
    cat(sprintf(" & (%.4f) & \\\\\n", ct2a[i, 2]))
  }
}

ct2c <- coeftable(res_ddd$m2c)
cat(sprintf("High AIOE $\\times$ Junior $\\times$ Post & & %.4f \\\\\n", ct2c[1, 1]))
cat(sprintf(" & & (%.4f) \\\\\n", ct2c[1, 2]))

cat("\\hline\n")
cat("Industry $\\times$ Seniority FE & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes \\\\\n")
cat(sprintf("N & %d & %d \\\\\n", res_ddd$m2a$nobs, res_ddd$m2c$nobs))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item Notes: Standard errors clustered at the 2-digit NAICS level.\n")
cat("Junior = O*NET Job Zones 1--2. Post = 2023--2024.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved table3_ddd.tex\n")

# ===========================================================================
# Table 4: Robustness
# ===========================================================================
cat("--- Table 4: Robustness ---\n")

rob_results <- fread(file.path(data_dir, "robustness_results.csv"))
sink(file.path(tab_dir, "table4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Coefficient & Std. Error & t-stat \\\\\n")
cat("\\hline\n")
for (i in seq_len(nrow(rob_results))) {
  p_approx <- 2 * (1 - pnorm(abs(rob_results$t_stat[i])))
  stars <- ifelse(p_approx < 0.01, "***", ifelse(p_approx < 0.05, "**", ifelse(p_approx < 0.1, "*", "")))
  cat(sprintf("%s & %.4f%s & %.4f & %.2f \\\\\n",
              rob_results$spec[i], rob_results$coef[i], stars,
              rob_results$se[i], rob_results$t_stat[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item Notes: All specifications include industry and year fixed effects.\n")
cat("Standard errors clustered at the 2-digit NAICS level.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved table4_robustness.tex\n")

cat("\n=== All tables generated ===\n")
