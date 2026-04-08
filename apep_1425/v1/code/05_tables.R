## 05_tables.R — apep_1425
## Generate all tables for the paper from saved results

this_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) {
  # Fallback for Rscript invocation
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) normalizePath(sub("--file=", "", file_arg)) else getwd()
})
SCRIPT_DIR <- dirname(this_script)
source(file.path(SCRIPT_DIR, "00_packages.R"))
WORK_DIR <- file.path(SCRIPT_DIR, "..")

# ── Load data and results ──
dt <- fread(file.path(WORK_DIR, "data", "analysis_sample.csv"))
results <- fread(file.path(WORK_DIR, "data", "main_results.csv"))
comp <- fread(file.path(WORK_DIR, "data", "compression_stats.csv"))
rob <- fromJSON(file.path(WORK_DIR, "data", "robustness_results.json"))

REFORM_DATE <- as.POSIXct("2017-11-11", tz = "America/Sao_Paulo")
dt[, filing_date_str := as.character(filing_date)]
dt[, filing_dt := as.POSIXct(filing_date_str, format = "%Y%m%d%H%M%S", tz = "America/Sao_Paulo")]
dt[is.na(filing_dt), filing_dt := as.POSIXct(filing_date_str, format = "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")]
dt[, filing_date_str := NULL]
dt[, post := as.integer(filing_dt >= REFORM_DATE)]
dt[, filing_year := year(filing_dt)]
dt[, pro_worker := as.integer(verdict_code %in% c(219L, 221L))]

dir.create(file.path(WORK_DIR, "tables"), showWarnings = FALSE)

# Helper: format coefficient with stars
fmt_coef <- function(g, s) {
  p <- 2 * pnorm(-abs(g / s))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.4f%s", g, stars)
}

fmt_se <- function(s) sprintf("(%.4f)", s)
fmt_n <- function(n) format(as.integer(n), big.mark = ",")

# ══════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════
cat("=== Table 1: Summary Statistics ===\n")

pre_dt <- dt[post == 0]
post_dt <- dt[post == 1]

make_row <- function(label, data_pre, data_post) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %s & %s \\\\",
          label,
          mean(data_pre, na.rm = TRUE), sd(data_pre, na.rm = TRUE),
          mean(data_post, na.rm = TRUE), sd(data_post, na.rm = TRUE),
          fmt_n(sum(!is.na(data_pre))),
          fmt_n(sum(!is.na(data_post))))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-Reform} & \\multicolumn{2}{c}{Post-Reform} & \\multicolumn{2}{c}{N} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Pre & Post \\\\",
  "\\hline",
  make_row("Pro-Worker Verdict", pre_dt$pro_worker, post_dt$pro_worker),
  make_row("Full Proced\\^{e}ncia",
           as.integer(pre_dt$verdict_code == 219L),
           as.integer(post_dt$verdict_code == 219L)),
  make_row("Improced\\^{e}ncia",
           as.integer(pre_dt$verdict_code == 220L),
           as.integer(post_dt$verdict_code == 220L)),
  make_row("Partial Proced\\^{e}ncia",
           as.integer(pre_dt$verdict_code == 221L),
           as.integer(post_dt$verdict_code == 221L)),
  "\\hline",
  sprintf("Unique Varas & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & & \\\\",
          fmt_n(uniqueN(pre_dt$vara_code)), fmt_n(uniqueN(post_dt$vara_code))),
  "\\hline",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Notes: Summary statistics for labor court cases assigned by lottery (\\textit{sorteio}) in TRT2 (S\\~{a}o Paulo), TRT4 (Rio Grande do Sul), and TRT15 (Campinas). Pre-reform: cases filed before November 11, 2017. Post-reform: cases filed on or after November 11, 2017. Pro-Worker Verdict includes Proced\\^{e}ncia (full) and Proced\\^{e}ncia em Parte (partial).",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab1, file.path(WORK_DIR, "tables", "tab1_summary.tex"))
cat("Saved tab1_summary.tex\n")

# ══════════════════════════════════════════════════════════════
# Table 2: Assignment Pool Balance Test
# ══════════════════════════════════════════════════════════════
cat("\n=== Table 2: Assignment Pool Balance ===\n")

# Run balance test here to get actual numbers
dt[, rito := fifelse(grepl("Sumar", classe, ignore.case = TRUE), "sumarissimo",
                     fifelse(grepl("Ordin", classe, ignore.case = TRUE), "ordinario", "other"))]
dt[, pool := paste0(muni_ibge, "_", rito)]

pool_vara_counts <- dt[, .(n_varas = uniqueN(vara_code), n_cases = .N), by = pool]
multi_vara_pools <- pool_vara_counts[n_varas >= 2]

set.seed(42)
sample_pools <- multi_vara_pools[n_cases >= 100][sample(.N, min(.N, 50))]$pool

balance_pvals <- numeric(length(sample_pools))
for (i in seq_along(sample_pools)) {
  p <- sample_pools[i]
  pool_data <- dt[pool == p]
  top_subjects <- pool_data[, .N, by = subject_codes][order(-N)][1:min(.N, 5)]$subject_codes
  pool_data[, subj_cat := fifelse(subject_codes %in% top_subjects, subject_codes, "other")]
  tab <- table(pool_data$vara_code, pool_data$subj_cat)
  if (nrow(tab) >= 2 && ncol(tab) >= 2) {
    test <- chisq.test(tab, simulate.p.value = TRUE, B = 1000)
    balance_pvals[i] <- test$p.value
  } else {
    balance_pvals[i] <- NA
  }
}

n_tested <- sum(!is.na(balance_pvals))
n_pass <- sum(balance_pvals > 0.05, na.rm = TRUE)
med_p <- median(balance_pvals, na.rm = TRUE)

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Assignment Pool Balance Test}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Pools Tested & Pass at 5\\% & Expected Pass & Median $p$-value \\\\",
  "\\hline",
  sprintf("Subject Distribution & %d & %d (%.0f\\%%) & 95\\%% & %.3f \\\\",
          n_tested, n_pass, 100 * n_pass / n_tested, med_p),
  "\\hline",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Notes: Chi-squared tests of subject-matter distribution across varas within assignment pools (municipality $\\times$ case class). Each test checks whether cases assigned to different varas within the same pool have similar subject compositions. Under random assignment, 95\\% of pools should pass at the 5\\% level.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab2, file.path(WORK_DIR, "tables", "tab2_balance.tex"))
cat("Saved tab2_balance.tex\n")

# ══════════════════════════════════════════════════════════════
# Table 3: Main Results — Leniency Compression
# ══════════════════════════════════════════════════════════════
cat("\n=== Table 3: Main Results ===\n")

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Leniency Compression: Pre-Reform Court Leniency $\\times$ Post-Reform}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("$L_j \\times \\text{Post}$ & %s & %s & %s & %s \\\\",
          fmt_coef(results$gamma[1], results$se[1]),
          fmt_coef(results$gamma[2], results$se[2]),
          fmt_coef(results$gamma[3], results$se[3]),
          fmt_coef(results$gamma[4], results$se[4])),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(results$se[1]), fmt_se(results$se[2]),
          fmt_se(results$se[3]), fmt_se(results$se[4])),
  "\\hline",
  "Year-Month FE & Yes & Yes & Yes & Yes \\\\",
  "Pool FE & No & Yes & Yes & --- \\\\",
  "Rito Controls & No & No & Yes & --- \\\\",
  "Vara FE & No & No & No & Yes \\\\",
  sprintf("N & %s & %s & %s & %s \\\\",
          fmt_n(results$n_cases[1]), fmt_n(results$n_cases[2]),
          fmt_n(results$n_cases[3]), fmt_n(results$n_cases[4])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Notes: Dependent variable is an indicator for pro-worker verdict (Proced\\^{e}ncia or Proced\\^{e}ncia em Parte). $L_j$ is the pre-reform empirical Bayes-shrunk pro-worker rate for vara $j$, standardized (mean zero, unit SD). Post indicates cases filed on or after November 11, 2017. Column (4) absorbs $L_j$ with vara fixed effects. Standard errors clustered by vara in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab3, file.path(WORK_DIR, "tables", "tab3_main.tex"))
cat("Saved tab3_main.tex\n")

# ══════════════════════════════════════════════════════════════
# Table 4: Compression by Claim Discretion Level
# ══════════════════════════════════════════════════════════════
cat("\n=== Table 4: Heterogeneity by Claim Type ===\n")

het_high <- rob$high_disc
het_low <- rob$low_disc
het_diff <- rob$disc_diff

# Build difference row
diff_gamma_str <- if (!is.null(het_diff)) fmt_coef(het_diff$gamma, het_diff$se) else "---"
diff_se_str <- if (!is.null(het_diff)) fmt_se(het_diff$se) else ""

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Leniency Compression by Claim Discretion Level}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & High Discretion & Low Discretion & Difference \\\\",
  "\\hline",
  sprintf("$L_j \\times \\text{Post}$ & %s & %s & %s \\\\",
          fmt_coef(het_high$gamma, het_high$se),
          fmt_coef(het_low$gamma, het_low$se),
          diff_gamma_str),
  sprintf(" & %s & %s & %s \\\\",
          fmt_se(het_high$se), fmt_se(het_low$se), diff_se_str),
  "\\hline",
  sprintf("N & %s & %s & --- \\\\", fmt_n(het_high$n), fmt_n(het_low$n)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Notes: High-discretion claims include indirect dismissal (\\textit{rescis\\~{a}o indireta}), moral damages, and overtime disputes. Low-discretion claims include statutory separation payments (\\textit{verbas rescis\\'orias}), FGTS deposits, and unemployment insurance. Classification fixed ex ante from pre-reform subject codes. Column (3) reports the difference and its standard error from a pooled regression with a triple interaction. Vara FE and year-month FE included. Standard errors clustered by vara.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab4, file.path(WORK_DIR, "tables", "tab4_heterogeneity.tex"))
cat("Saved tab4_heterogeneity.tex\n")

# ══════════════════════════════════════════════════════════════
# Table 5: Robustness
# ══════════════════════════════════════════════════════════════
cat("\n=== Table 5: Robustness ===\n")

rob_row <- function(label, r) {
  if (is.null(r)) return(sprintf("%s & --- & --- & --- & --- \\\\", label))
  sprintf("%s & %s & %s & %s & %s \\\\",
          label, fmt_coef(r$gamma, r$se), fmt_se(r$se),
          fmt_n(r$n), if (!is.null(r$varas)) fmt_n(r$varas) else "---")
}

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & $\\hat{\\gamma}$ & SE & N & Varas \\\\",
  "\\hline",
  "\\textit{Panel A: Baseline} & & & & \\\\",
  rob_row("Main specification", rob$main),
  "{}[0.5em]",
  "\\textit{Panel B: Placebo} & & & & \\\\",
  rob_row("False reform: Jan 2016", rob$placebo),
  "{}[0.5em]",
  "\\textit{Panel C: Min.\\ cases threshold} & & & & \\\\",
  rob_row("$\\geq$50 pre-reform cases", rob$min50),
  rob_row("$\\geq$100 pre-reform cases", rob$min100),
  rob_row("$\\geq$200 pre-reform cases", rob$min200),
  "{}[0.5em]",
  "\\textit{Panel D: Alternative outcomes} & & & & \\\\",
  rob_row("Settlement as outcome", rob$settlement),
  rob_row("Rito Ordin\\'ario only", rob$rito_ordinario),
  rob_row("Rito Sumar\\'issimo only", rob$rito_sumarissimo),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{flushleft}\\small",
  "Notes: All specifications include vara fixed effects and year-month fixed effects. $L_j$ is standardized pre-reform vara leniency (empirical Bayes-shrunk). Placebo test uses pre-reform data only with a false break at January 1, 2016. Standard errors clustered by vara.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tab5, file.path(WORK_DIR, "tables", "tab5_robustness.tex"))
cat("Saved tab5_robustness.tex\n")

# ══════════════════════════════════════════════════════════════
# Table F1: SDE Appendix (mandatory)
# ══════════════════════════════════════════════════════════════
cat("\n=== Table F1: SDE Appendix ===\n")

sde_classify <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde > 0.15) return("Large")
  if (abs_sde > 0.05) return("Moderate")
  if (abs_sde > 0.005) return("Small")
  return("Null")
}

sde_row <- function(label, beta, se_beta, sd_y) {
  if (is.null(beta) || is.null(se_beta) || is.null(sd_y) || is.na(sd_y) || sd_y == 0) {
    return(sprintf("%s & --- & --- & --- & --- & --- & --- \\\\", label))
  }
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  cl <- sde_classify(sde)
  sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          label, beta, se_beta, sd_y, sde, se_sde, cl)
}

# Get values from robustness results
sd_y <- rob$sd_y

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Distributional Effect (SDE) Appendix}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sde_row("Pro-Worker Verdict", rob$main$gamma, rob$main$se, sd_y$pro_worker),
  sde_row("Full Proced\\^{e}ncia", rob$full_pro$gamma, rob$full_pro$se, sd_y$full_pro),
  "{}[0.5em]",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\",
  sde_row("High Discretion", rob$high_disc$gamma, rob$high_disc$se, sd_y$high_disc),
  sde_row("Low Discretion", rob$low_disc$gamma, rob$low_disc$se, sd_y$low_disc),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}\\small",
  "\\textbf{Country:} Brazil.",
  "\\textbf{Research question:} Does the 2017 labor reform compress cross-court heterogeneity in adjudication?",
  "\\textbf{Policy mechanism:} Lei 13.467 shifted litigation costs to losing plaintiffs, changing the equilibrium filing pool and potentially disciplining judicial discretion.",
  "\\textbf{Outcome definition:} Pro-worker verdict (Proced\\^{e}ncia or Proced\\^{e}ncia em Parte vs.\\ Improced\\^{e}ncia).",
  "\\textbf{Treatment:} Pre-reform vara leniency $L_j$ (empirical Bayes-shrunk, standardized) interacted with post-reform indicator.",
  "\\textbf{Data:} DataJud API (CNJ), TRT2/TRT4/TRT15, 2012--2023.",
  "\\textbf{Method:} Case-level OLS with vara and year-month fixed effects; standard errors clustered by vara.",
  "\\textbf{Sample:} First-instance labor cases assigned by lottery (\\textit{sorteio}).",
  "Classification refers to magnitude, not statistical significance. Large: $|\\text{SDE}| > 0.15$; Moderate: $0.05$--$0.15$; Small: $0.005$--$0.05$; Null: $< 0.005$.",
  "\\end{flushleft}",
  "\\end{table}"
)

writeLines(tabF1, file.path(WORK_DIR, "tables", "tabF1_sde.tex"))
cat("Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
