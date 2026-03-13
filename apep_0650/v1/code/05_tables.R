## 05_tables.R — Generate all LaTeX tables
## apep_0650: Creative Destruction at the Border

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))
source("code/00_packages.R")

cat("=== Loading model results ===\n")
t1 <- readRDS("data/table1_models.rds")
t2 <- readRDS("data/table2_models.rds")
t3 <- readRDS("data/table3_models.rds")
t4 <- readRDS("data/table4_models.rds")
ss <- readRDS("data/summary_stats.rds")
df <- readRDS("data/pair_panel.rds")

##############################################################################
## Table 1: Summary Statistics
##############################################################################
cat("\n=== Generating Table 1: Summary Statistics ===\n")

# Compute summary stats from data
df_summ <- df |>
  filter(industry == "00", agegrp == "A00")

vars_df <- data.frame(
  Variable = c("Employment", "Average Monthly Earnings (\\$)",
               "Effective Min. Wage (\\$)", "Job Creation Rate (\\%)",
               "Job Destruction Rate (\\%)", "Hiring Rate (\\%)",
               "Separation Rate (\\%)"),
  stringsAsFactors = FALSE
)

make_stat <- function(x) {
  c(Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    Min = min(x, na.rm = TRUE),
    Max = max(x, na.rm = TRUE))
}

stats_mat <- rbind(
  make_stat(df_summ$Emp),
  make_stat(df_summ$EarnS),
  make_stat(df_summ$eff_mw),
  make_stat(df_summ$jc_rate),
  make_stat(df_summ$jd_rate),
  make_stat(df_summ$hire_rate),
  make_stat(df_summ$sep_rate)
)

# Format numbers
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Border County-Pair Panel}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Variable & Mean & Std. Dev. & Min & Max \\\\",
  "\\midrule"
)

for (i in 1:nrow(stats_mat)) {
  d <- ifelse(i <= 2, 0, 2)
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s \\\\",
    vars_df$Variable[i],
    fmt(stats_mat[i, 1], d), fmt(stats_mat[i, 2], d),
    fmt(stats_mat[i, 3], d), fmt(stats_mat[i, 4], d)
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: N = %s county-pair-quarter observations from %s unique border county pairs spanning %s counties across %s state border segments. Panel covers 2001Q1--2022Q4. All variables from Census LEHD Quarterly Workforce Indicators (QWI). Employment is beginning-of-quarter count. Earnings are average monthly. Job creation and destruction rates are firm-level job gains and losses as a percentage of employment. Hiring and separation rates are worker flows as a percentage of employment.",
    formatC(nrow(df_summ), big.mark = ","),
    formatC(n_distinct(df_summ$pair_id), big.mark = ","),
    formatC(n_distinct(df_summ$fips), big.mark = ","),
    formatC(n_distinct(paste(pmin(df_summ$state_a, df_summ$state_b), pmax(df_summ$state_a, df_summ$state_b))), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Written tables/tab1_summary.tex\n")

##############################################################################
## Table 2: Main Results — Employment and Earnings
##############################################################################
cat("\n=== Generating Table 2: Employment and Earnings ===\n")

make_reg_row <- function(models, var = "log_mw") {
  rows <- list()
  coefs <- sapply(models, function(m) formatC(coef(m)[var], format = "f", digits = 4))
  ses <- sapply(models, function(m) paste0("(", formatC(se(m)[var], format = "f", digits = 4), ")"))
  stars <- sapply(models, function(m) {
    p <- pvalue(m)[var]
    if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.10) "*" else ""
  })
  ns <- sapply(models, function(m) formatC(m$nobs, big.mark = ","))
  r2s <- sapply(models, function(m) formatC(fitstat(m, "r2")[[1]], format = "f", digits = 3))
  ncl <- sapply(models, function(m) formatC(length(unique(m$fixef_sizes)), format = "d"))

  coef_row <- paste(paste0(coefs, stars), collapse = " & ")
  se_row <- paste(ses, collapse = " & ")
  n_row <- paste(ns, collapse = " & ")
  r2_row <- paste(r2s, collapse = " & ")

  list(coef = coef_row, se = se_row, n = n_row, r2 = r2_row)
}

tab2_models <- list(t1$emp_all, t1$earn_all, t1$emp_72, t1$earn_72, t1$emp_retail)
tab2_headers <- c("Log Emp.", "Log Earn.", "Log Emp.", "Log Earn.", "Log Emp.")
tab2_panels <- c("\\multicolumn{3}{l}{\\textit{All Industries}}", "",
                 "\\multicolumn{3}{l}{\\textit{Restaurants (NAICS 72)}}", "",
                 "\\multicolumn{1}{l}{\\textit{Retail}}")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Minimum Wages on Employment and Earnings}",
  "\\label{tab:emp_earn}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0(" & \\multicolumn{2}{c}{All Industries} & \\multicolumn{2}{c}{Restaurants} & Retail \\\\"),
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-6}",
  paste0(" & ", paste(tab2_headers, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) & (5) \\\\"),
  "\\midrule"
)

for (i in seq_along(tab2_models)) {
  m <- tab2_models[[i]]
  b <- coef(m)["log_mw"]
  s <- se(m)["log_mw"]
  p <- pvalue(m)["log_mw"]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  if (i == 1) {
    coef_line <- sprintf("Log(Min. Wage) & %s%s", formatC(b, format = "f", digits = 4), star)
    se_line <- sprintf(" & (%s)", formatC(s, format = "f", digits = 4))
    n_line <- sprintf("N & %s", formatC(m$nobs, big.mark = ","))
  } else {
    coef_line <- paste0(coef_line, sprintf(" & %s%s", formatC(b, format = "f", digits = 4), star))
    se_line <- paste0(se_line, sprintf(" & (%s)", formatC(s, format = "f", digits = 4)))
    n_line <- paste0(n_line, sprintf(" & %s", formatC(m$nobs, big.mark = ",")))
  }
}

tab2_lines <- c(tab2_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0(n_line, " \\\\"),
  "Pair FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & Border seg. & Border seg. & Border seg. & Border seg. & Border seg. \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each column reports the coefficient on log(effective minimum wage) from a regression with county-pair and calendar-quarter fixed effects. Standard errors in parentheses, clustered at the state-border-segment level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Employment is beginning-of-quarter count from QWI. Earnings are average monthly. Sample: contiguous county pairs at state borders, 2001Q1--2022Q4.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_emp_earn.tex")
cat("Written tables/tab2_emp_earn.tex\n")

##############################################################################
## Table 3: Firm Dynamics (Main Results)
##############################################################################
cat("\n=== Generating Table 3: Firm Dynamics ===\n")

tab3_models <- list(t2$jc_all, t2$jd_all, t2$net_all, t2$hire_all, t2$sep_all)
tab3_labels <- c("JC Rate", "JD Rate", "Net JC", "Hire Rate", "Sep. Rate")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Minimum Wages on Firm Dynamics and Worker Flows}",
  "\\label{tab:firm_dynamics}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0(" & ", paste(tab3_labels, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) & (5) \\\\"),
  "\\midrule"
)

coef_line <- "Log(Min. Wage)"
se_line <- ""
n_line <- "N"

for (i in seq_along(tab3_models)) {
  m <- tab3_models[[i]]
  b <- coef(m)["log_mw"]
  s <- se(m)["log_mw"]
  p <- pvalue(m)["log_mw"]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  coef_line <- paste0(coef_line, sprintf(" & %s%s", formatC(b, format = "f", digits = 3), star))
  se_line <- paste0(se_line, sprintf(" & (%s)", formatC(s, format = "f", digits = 3)))
  n_line <- paste0(n_line, sprintf(" & %s", formatC(m$nobs, big.mark = ",")))
}

tab3_lines <- c(tab3_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0(n_line, " \\\\"),
  "Pair FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & Border seg. & Border seg. & Border seg. & Border seg. & Border seg. \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each column reports the coefficient on log(effective minimum wage) from a county-pair fixed effects regression. JC Rate = firm job creation (positions at expanding/entering firms) as \\% of employment. JD Rate = firm job destruction (positions at contracting/exiting firms) as \\% of employment. Net JC = JC Rate $-$ JD Rate. Hire Rate = all hires as \\% of employment. Sep. Rate = separations as \\% of employment. Standard errors in parentheses, clustered at the state-border-segment level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_firm_dynamics.tex")
cat("Written tables/tab3_firm_dynamics.tex\n")

##############################################################################
## Table 4: Industry Decomposition
##############################################################################
cat("\n=== Generating Table 4: Industry Decomposition ===\n")

tab4_models <- list(
  t3$jc_72, t3$jd_72,
  t3$jc_retail, t3$jd_retail,
  t3$jc_mfg, t3$jd_mfg
)
tab4_labels <- c("JC Rate", "JD Rate", "JC Rate", "JD Rate", "JC Rate", "JD Rate")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Firm Dynamics by Industry}",
  "\\label{tab:industry}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Restaurants (72)} & \\multicolumn{2}{c}{Retail (44-45)} & \\multicolumn{2}{c}{Manufacturing (31-33)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  paste0(" & ", paste(tab4_labels, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\"),
  "\\midrule"
)

coef_line <- "Log(Min. Wage)"
se_line <- ""
n_line <- "N"

for (i in seq_along(tab4_models)) {
  m <- tab4_models[[i]]
  b <- coef(m)["log_mw"]
  s <- se(m)["log_mw"]
  p <- pvalue(m)["log_mw"]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  coef_line <- paste0(coef_line, sprintf(" & %s%s", formatC(b, format = "f", digits = 3), star))
  se_line <- paste0(se_line, sprintf(" & (%s)", formatC(s, format = "f", digits = 3)))
  n_line <- paste0(n_line, sprintf(" & %s", formatC(m$nobs, big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0(n_line, " \\\\"),
  "Pair FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each column reports the coefficient on log(effective minimum wage) from a county-pair fixed effects regression within the indicated industry. Manufacturing serves as a placebo sector where few workers earn near the minimum wage. Standard errors clustered at the state-border-segment level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_industry.tex")
cat("Written tables/tab4_industry.tex\n")

##############################################################################
## Table 5: Age-Specific Effects
##############################################################################
cat("\n=== Generating Table 5: Age-Specific Effects ===\n")

tab5_models <- list(
  t4$emp_young, t4$earn_young, t4$jc_young, t4$jd_young,
  t4$emp_prime, t4$earn_prime,
  t4$emp_old, t4$earn_old
)
tab5_labels <- c("Log Emp.", "Log Earn.", "JC Rate", "JD Rate",
                 "Log Emp.", "Log Earn.",
                 "Log Emp.", "Log Earn.")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Age-Specific Effects of Minimum Wages}",
  "\\label{tab:age}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccccc}",
  "\\toprule",
  " & \\multicolumn{4}{c}{Young (14--24)} & \\multicolumn{2}{c}{Prime-Age (25--44)} & \\multicolumn{2}{c}{Older (45+)} \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}",
  paste0(" & ", paste(tab5_labels, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\\\"),
  "\\midrule"
)

coef_line <- "Log(Min. Wage)"
se_line <- ""
n_line <- "N"

for (i in seq_along(tab5_models)) {
  m <- tab5_models[[i]]
  b <- coef(m)["log_mw"]
  s <- se(m)["log_mw"]
  p <- pvalue(m)["log_mw"]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  coef_line <- paste0(coef_line, sprintf(" & %s%s", formatC(b, format = "f", digits = 4), star))
  se_line <- paste0(se_line, sprintf(" & (%s)", formatC(s, format = "f", digits = 4)))
  n_line <- paste0(n_line, sprintf(" & %s", formatC(m$nobs, big.mark = ",")))
}

tab5_lines <- c(tab5_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0(n_line, " \\\\"),
  "Pair FE & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Young = ages 14--24 (QWI groups A01--A03); Prime-age = 25--44 (A04--A05); Older = 45+ (A06--A08). Each column reports the coefficient on log(effective minimum wage) from a county-pair fixed effects regression. Standard errors clustered at the state-border-segment level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_age.tex")
cat("Written tables/tab5_age.tex\n")

##############################################################################
## SDE Table (Appendix)
##############################################################################
cat("\n=== Generating SDE Table ===\n")

df_all <- df |> filter(industry == "00", agegrp == "A00")

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_rows <- list()

# Employment (all industries)
b <- coef(t1$emp_all)["log_mw"]
s <- se(t1$emp_all)["log_mw"]
sd_y <- sd(df_all$log_emp, na.rm = TRUE)
sd_x <- sd(df_all$log_mw, na.rm = TRUE)
sde <- b * sd_x / sd_y
se_sde <- s * sd_x / sd_y
sde_rows[[1]] <- c("Log Employment", formatC(b, format = "f", digits = 4),
                    formatC(sd_x, format = "f", digits = 3),
                    formatC(sd_y, format = "f", digits = 3),
                    formatC(sde, format = "f", digits = 4),
                    formatC(se_sde, format = "f", digits = 4),
                    classify_sde(sde))

# Earnings
b <- coef(t1$earn_all)["log_mw"]
s <- se(t1$earn_all)["log_mw"]
sd_y <- sd(df_all$log_earn, na.rm = TRUE)
sde <- b * sd_x / sd_y
se_sde <- s * sd_x / sd_y
sde_rows[[2]] <- c("Log Earnings", formatC(b, format = "f", digits = 4),
                    formatC(sd_x, format = "f", digits = 3),
                    formatC(sd_y, format = "f", digits = 3),
                    formatC(sde, format = "f", digits = 4),
                    formatC(se_sde, format = "f", digits = 4),
                    classify_sde(sde))

# JC rate
b <- coef(t2$jc_all)["log_mw"]
s <- se(t2$jc_all)["log_mw"]
sd_y <- sd(df_all$jc_rate, na.rm = TRUE)
sde <- b * sd_x / sd_y
se_sde <- s * sd_x / sd_y
sde_rows[[3]] <- c("Job Creation Rate", formatC(b, format = "f", digits = 3),
                    formatC(sd_x, format = "f", digits = 3),
                    formatC(sd_y, format = "f", digits = 3),
                    formatC(sde, format = "f", digits = 4),
                    formatC(se_sde, format = "f", digits = 4),
                    classify_sde(sde))

# JD rate
b <- coef(t2$jd_all)["log_mw"]
s <- se(t2$jd_all)["log_mw"]
sd_y <- sd(df_all$jd_rate, na.rm = TRUE)
sde <- b * sd_x / sd_y
se_sde <- s * sd_x / sd_y
sde_rows[[4]] <- c("Job Destruction Rate", formatC(b, format = "f", digits = 3),
                    formatC(sd_x, format = "f", digits = 3),
                    formatC(sd_y, format = "f", digits = 3),
                    formatC(sde, format = "f", digits = 4),
                    formatC(se_sde, format = "f", digits = 4),
                    classify_sde(sde))

# Hire rate
b <- coef(t2$hire_all)["log_mw"]
s <- se(t2$hire_all)["log_mw"]
sd_y <- sd(df_all$hire_rate, na.rm = TRUE)
sde <- b * sd_x / sd_y
se_sde <- s * sd_x / sd_y
sde_rows[[5]] <- c("Hiring Rate", formatC(b, format = "f", digits = 3),
                    formatC(sd_x, format = "f", digits = 3),
                    formatC(sd_y, format = "f", digits = 3),
                    formatC(sde, format = "f", digits = 4),
                    formatC(se_sde, format = "f", digits = 4),
                    classify_sde(sde))

sde_tab <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (r in sde_rows) {
  sde_tab <- c(sde_tab, paste0(paste(r, collapse = " & "), " \\\\"))
}

sde_tab <- c(sde_tab,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. Treatment is continuous (log effective minimum wage); SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, giving the effect of a one-standard-deviation change in the treatment, measured in standard deviations of the outcome. SD($Y$) and SD($X$) are unconditional standard deviations from the full estimation sample.",
  "",
  "\\textbf{Research question:} What is the effect of minimum wages on employment, earnings, and firm dynamics (job creation/destruction) in contiguous border counties?",
  "\\textbf{Treatment:} Continuous; log of effective state minimum wage (higher of state or federal).",
  sprintf("\\textbf{Data:} Census LEHD Quarterly Workforce Indicators (QWI), 2001--2022, county-pair-quarter level, N = %s.", formatC(t1$emp_all$nobs, big.mark = ",")),
  "\\textbf{Method:} County-pair fixed effects with calendar-quarter FE; SEs clustered at state-border-segment level.",
  "\\textbf{Sample:} Contiguous county pairs straddling U.S. state borders with differing minimum wages.",
  "",
  "Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$).",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)

writeLines(sde_tab, "tables/tabF1_sde.tex")
cat("Written tables/tabF1_sde.tex\n")

cat("\n=== All Tables Generated ===\n")
