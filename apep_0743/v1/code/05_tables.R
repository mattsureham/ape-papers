# 05_tables.R — Generate all LaTeX tables
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

source("00_packages.R")
load("../data/models.RData")
load("../data/robustness_models.RData")

# ─── Table 1: Summary Statistics ───
cat("Generating Table 1: Summary Statistics\n")

summ_vars <- c("estab_pc", "emp_pc", "emp_per_estab", "payroll_per_emp",
               "crem_estab_pc", "total_pop", "median_income", "pct_65plus")
summ_labels <- c("Funeral homes per 10K pop.", "Funeral home emp. per 10K pop.",
                 "Employees per funeral home", "Payroll per employee (\\$)",
                 "Crematories per 10K pop.", "Total population",
                 "Median household income (\\$)", "Population 65+ (\\%)")

make_summ_row <- function(df, var, label) {
  x <- df[[var]]
  x <- x[!is.na(x)]
  sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
          label, mean(x), sd(x), mean(x), sd(x))
}

fd1 <- analysis %>% filter(fd_required == 1)
fd0 <- analysis %>% filter(fd_required == 0)

tab1_rows <- character()
for (i in seq_along(summ_vars)) {
  v <- summ_vars[i]
  x1 <- fd1[[v]]; x1 <- x1[!is.na(x1)]
  x0 <- fd0[[v]]; x0 <- x0[!is.na(x0)]
  row <- sprintf("  %s & %.2f & %.2f & %.2f & %.2f \\\\",
                 summ_labels[i],
                 mean(x1), sd(x1), mean(x0), sd(x0))
  tab1_rows <- c(tab1_rows, row)
}

n_fd <- n_distinct(fd1$fips)
n_nfd <- n_distinct(fd0$fips)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Border Counties by Funeral Director Mandate Status}\n",
  "\\label{tab:summ}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{FD-Required} & \\multicolumn{2}{c}{Non-FD} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Death Care Market Outcomes}} \\\\\n",
  "\\addlinespace\n",
  paste(tab1_rows[1:5], collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: County Demographics}} \\\\\n",
  "\\addlinespace\n",
  paste(tab1_rows[6:8], collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\hline\n",
  sprintf("  Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n", n_fd, n_nfd),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Statistics computed from Census County Business Patterns (2017--2022, averaged) ",
  "and American Community Survey (2021 5-year estimates). Border counties defined as those within 75km of ",
  "a state border separating FD-required from non-FD states. Payroll per employee in thousands of dollars, ",
  "annualized. FD-required states: CT, IL, IN, IA, LA, MI, NE, NJ, NY.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ─── Table 2: Main Results ───
cat("Generating Table 2: Main Results\n")

format_coef <- function(coef_val, se_val) {
  stars <- ""
  t <- abs(coef_val / se_val)
  if (t > 2.576) stars <- "^{***}"
  else if (t > 1.96) stars <- "^{**}"
  else if (t > 1.645) stars <- "^{*}"

  sprintf("%.3f%s", coef_val, stars)
}

format_se <- function(se_val) {
  sprintf("(%.3f)", se_val)
}

# Get coefficients
coefs <- list(m1, m2, m3, m4, m5, m6)
fd_coefs <- sapply(coefs, function(m) coef(m)["fd_required"])
fd_ses <- sapply(coefs, function(m) se(m)["fd_required"])

dep_means <- c(
  mean(analysis$estab_pc, na.rm = TRUE),
  mean(analysis$estab_pc, na.rm = TRUE),
  mean(analysis$emp_pc, na.rm = TRUE),
  mean(analysis$emp_per_estab, na.rm = TRUE),
  mean(analysis$payroll_per_emp, na.rm = TRUE),
  mean(analysis$crem_estab_pc, na.rm = TRUE)
)

n_obs <- c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5), nobs(m6))

col_labels <- c("Estab./10K", "Estab./10K", "Emp./10K",
                "Emp./Estab.", "Payroll/Emp.", "Crem./10K")

tab2_header <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Funeral Director Mandates on Death Care Markets: Border Discontinuity Estimates}\n",
  "\\label{tab:main}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  sprintf(" & %s \\\\\n", paste(col_labels, collapse = " & ")),
  "\\hline\n",
  "\\addlinespace\n"
)

tab2_body <- paste0(
  sprintf("  FD Required & %s & %s & %s & %s & %s & %s \\\\\n",
          format_coef(fd_coefs[1], fd_ses[1]),
          format_coef(fd_coefs[2], fd_ses[2]),
          format_coef(fd_coefs[3], fd_ses[3]),
          format_coef(fd_coefs[4], fd_ses[4]),
          format_coef(round(fd_coefs[5], 0), fd_ses[5]),
          format_coef(fd_coefs[6], fd_ses[6])),
  sprintf("  & %s & %s & %s & %s & %s & %s \\\\\n",
          format_se(fd_ses[1]),
          format_se(fd_ses[2]),
          format_se(fd_ses[3]),
          format_se(fd_ses[4]),
          format_se(round(fd_ses[5], 0)),
          format_se(fd_ses[6])),
  "\\addlinespace\n",
  sprintf("  Controls & No & Yes & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("  Pair FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("  Dep. var. mean & %.2f & %.2f & %.2f & %.2f & %.0f & %.2f \\\\\n",
          dep_means[1], dep_means[2], dep_means[3], dep_means[4], dep_means[5], dep_means[6]),
  sprintf("  Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          format(n_obs[1], big.mark = ","),
          format(n_obs[2], big.mark = ","),
          format(n_obs[3], big.mark = ","),
          format(n_obs[4], big.mark = ","),
          format(n_obs[5], big.mark = ","),
          format(n_obs[6], big.mark = ","))
)

tab2_footer <- paste0(
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports estimates from a border-pair fixed effects regression comparing ",
  "adjacent counties across state borders where one state requires funeral director involvement and the other ",
  "does not. Controls include log population, log median household income, and percent of population aged 65+. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(paste0(tab2_header, tab2_body, tab2_footer), "../tables/tab2_main.tex")

# ─── Table 3: Robustness and Placebo ───
cat("Generating Table 3: Robustness\n")

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robust}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Coefficient & SE & Observations \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Bandwidth Sensitivity (Dep. Var: Estab./10K)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("  50km bandwidth & %s & %s & %s \\\\\n",
          format_coef(coef(m_bw50)["fd_required"], se(m_bw50)["fd_required"]),
          format_se(se(m_bw50)["fd_required"]),
          format(nobs(m_bw50), big.mark = ",")),
  sprintf("  75km bandwidth (baseline) & %s & %s & %s \\\\\n",
          format_coef(coef(m2)["fd_required"], se(m2)["fd_required"]),
          format_se(se(m2)["fd_required"]),
          format(nobs(m2), big.mark = ",")),
  sprintf("  Segment FE (not pair FE) & %s & %s & %s \\\\\n",
          format_coef(coef(m2_seg)["fd_required"], se(m2_seg)["fd_required"]),
          format_se(se(m2_seg)["fd_required"]),
          format(nobs(m2_seg), big.mark = ",")),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Covariate Balance (Pair FE, No Controls)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("  Median household income & %s & %s & %s \\\\\n",
          format_coef(coef(m_placebo_income)["fd_required"], se(m_placebo_income)["fd_required"]),
          format_se(se(m_placebo_income)["fd_required"]),
          format(nobs(m_placebo_income), big.mark = ",")),
  sprintf("  Population 65+ (\\%%) & %s & %s & %s \\\\\n",
          format_coef(coef(m_placebo_elderly)["fd_required"], se(m_placebo_elderly)["fd_required"]),
          format_se(se(m_placebo_elderly)["fd_required"]),
          format(nobs(m_placebo_elderly), big.mark = ",")),
  sprintf("  Total population & %s & %s & %s \\\\\n",
          format_coef(coef(m_placebo_pop)["fd_required"], se(m_placebo_pop)["fd_required"]),
          format_se(se(m_placebo_pop)["fd_required"]),
          format(nobs(m_placebo_pop), big.mark = ",")),
  "\\addlinespace\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A varies the bandwidth for defining border county pairs (distance between ",
  "county centroids). Panel B tests for discontinuities in predetermined covariates at state borders. ",
  "All specifications include border-pair fixed effects unless noted. Controls (Panel A): log population, ",
  "log median income, percent 65+. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ─── Table 4: Segment-level Estimates ───
cat("Generating Table 4: Segment Heterogeneity\n")

# Show largest segments
seg_show <- seg_results %>%
  arrange(desc(n)) %>%
  head(12)

seg_rows <- character()
for (j in seq_len(nrow(seg_show))) {
  r <- seg_show[j, ]
  seg_rows <- c(seg_rows,
    sprintf("  %s & %s & %s & %d \\\\",
            r$segment_id,
            format_coef(r$coef, r$se),
            format_se(r$se),
            r$n))
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Funeral Home Density at Each Border Segment}\n",
  "\\label{tab:segments}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " Border Segment & FD Required & SE & N \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  paste(seg_rows, collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\hline\n",
  sprintf("  Positive / Total & \\multicolumn{3}{c}{%d / %d} \\\\\n",
          sum(seg_results$coef > 0), nrow(seg_results)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on FD Required from an OLS regression of funeral ",
  "homes per 10,000 population on the mandate indicator, log population, log median income, and percent 65+, ",
  "estimated separately for each border segment. Segments sorted by sample size. Standard errors are ",
  "heteroskedasticity-robust.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_segments.tex")

# ─── Table F1: SDE Appendix ───
cat("Generating SDE Table\n")

results <- read_csv("../data/main_results.csv", show_col_types = FALSE)

# SDE rows: main outcomes
sde_outcomes <- results %>%
  filter(model %in% c("Estab/10K (ctrl)", "Emp/10K", "Emp/Estab",
                       "Payroll/Emp", "Crem Estab/10K"))

sde_labels <- c("Funeral homes per 10K pop.", "Funeral home emp. per 10K pop.",
                "Employees per funeral home", "Payroll per employee",
                "Crematories per 10K pop.")

sde_classify <- function(sde_val) {
  if (abs(sde_val) < 0.005) return("Null")
  if (sde_val > 0.15) return("Large positive")
  if (sde_val > 0.05) return("Moderate positive")
  if (sde_val > 0.005) return("Small positive")
  if (sde_val < -0.15) return("Large negative")
  if (sde_val < -0.05) return("Moderate negative")
  return("Small negative")
}

sde_rows <- character()
for (i in seq_len(nrow(sde_outcomes))) {
  r <- sde_outcomes[i, ]
  se_sde <- r$se / r$sd_dep
  cls <- sde_classify(r$sde)

  if (r$model == "Payroll/Emp") {
    row <- sprintf("  %s & %.0f & %.0f & %.0f & %.4f & %.4f & %s \\\\",
                   sde_labels[i], r$coef, r$se, r$sd_dep, r$sde, se_sde, cls)
  } else {
    row <- sprintf("  %s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
                   sde_labels[i], r$coef, r$se, r$sd_dep, r$sde, se_sde, cls)
  }
  sde_rows <- c(sde_rows, row)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level mandatory funeral director requirements affect the structure ",
  "and pricing of local death care markets? ",
  "\\textbf{Policy mechanism:} Nine states require families to hire a licensed funeral director for all body ",
  "disposition tasks including filing death certificates, obtaining burial and transit permits, and transporting ",
  "remains; the remaining 41 states allow families to perform these tasks independently. ",
  "\\textbf{Outcome definition:} Funeral home establishments per 10,000 population, funeral home employment ",
  "per 10,000 population, employees per establishment, annual payroll per employee, and crematory establishments ",
  "per 10,000 population, all from Census County Business Patterns NAICS 812210 and 812220. ",
  "\\textbf{Treatment:} Binary --- county located in a state with mandatory funeral director requirements versus not. ",
  "\\textbf{Data:} Census County Business Patterns 2017--2022 (averaged), American Community Survey 2021 5-year estimates, ",
  "Census Gazetteer county centroids; 800 border county pairs across 26 state-border segments. ",
  "\\textbf{Method:} Border-pair fixed effects OLS with controls for log population, log median household income, ",
  "and percent population aged 65+; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties within 75km of a state border separating FD-required from non-FD states; ",
  "counties with zero CBP funeral home establishments included as zeros. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-county ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  paste(sde_rows, collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat(sprintf("\nAll tables saved to ../tables/\n"))
cat(sprintf("Files: %s\n", paste(list.files("../tables/"), collapse = ", ")))
