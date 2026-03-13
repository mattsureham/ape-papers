# 05_tables.R — Generate all LaTeX tables
# apep_0620: Second-generation refugee dispersal outcomes in Denmark

source("00_packages.R")

analysis <- readRDS("../data/analysis_cross_section.rds")
models <- readRDS("../data/model_objects.rds")
robust <- readRDS("../data/robustness_objects.rds")

dir.create("../tables", showWarnings = FALSE)

# ─────────────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- analysis %>%
  summarise(
    # Treatment
    imm_share_mean = mean(imm_share_2008) * 100,
    imm_share_sd = sd(imm_share_2008) * 100,
    imm_share_min = min(imm_share_2008) * 100,
    imm_share_max = max(imm_share_2008) * 100,
    # Employment
    emp_mean = mean(emp_rate_desc, na.rm = TRUE),
    emp_sd = sd(emp_rate_desc, na.rm = TRUE),
    emp_min = min(emp_rate_desc, na.rm = TRUE),
    emp_max = max(emp_rate_desc, na.rm = TRUE),
    # Education
    edu_mean = mean(share_tertiary, na.rm = TRUE) * 100,
    edu_sd = sd(share_tertiary, na.rm = TRUE) * 100,
    edu_min = min(share_tertiary, na.rm = TRUE) * 100,
    edu_max = max(share_tertiary, na.rm = TRUE) * 100,
    # Primary
    prim_mean = mean(share_primary, na.rm = TRUE) * 100,
    prim_sd = sd(share_primary, na.rm = TRUE) * 100,
    prim_min = min(share_primary, na.rm = TRUE) * 100,
    prim_max = max(share_primary, na.rm = TRUE) * 100,
    # Gap
    gap_mean = mean(emp_gap, na.rm = TRUE),
    gap_sd = sd(emp_gap, na.rm = TRUE),
    gap_min = min(emp_gap, na.rm = TRUE),
    gap_max = max(emp_gap, na.rm = TRUE),
    # Population
    pop_mean = mean(total_pop),
    pop_sd = sd(total_pop),
    pop_min = min(total_pop),
    pop_max = max(total_pop),
    # Descendant count
    desc_mean = mean(descendant_pop),
    desc_sd = sd(descendant_pop),
    desc_min = min(descendant_pop),
    desc_max = max(descendant_pop),
    # Employment (Danish origin)
    dk_emp_mean = mean(dk_emp_rate, na.rm = TRUE),
    dk_emp_sd = sd(dk_emp_rate, na.rm = TRUE)
  )

tab1_tex <- sprintf('
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & SD & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Treatment}} \\\\
Immigrant share, 2008 (\\%%) & %.2f & %.2f & %.2f & %.2f \\\\[0.5em]
\\multicolumn{5}{l}{\\textit{Panel B: Second-generation outcomes}} \\\\
Employment rate, 2022 (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\
Tertiary education share, 2023 (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\
Primary-only education share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\
Employment gap vs.\\ Danish origin (pp) & %.1f & %.1f & %.1f & %.1f \\\\[0.5em]
\\multicolumn{5}{l}{\\textit{Panel C: Municipality characteristics}} \\\\
Total population (2008) & %s & %s & %s & %s \\\\
Non-Western descendant count & %s & %s & %s & %s \\\\
Danish-origin employment rate (\\%%) & %.1f & %.1f & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %d municipalities. The sample includes all Danish municipalities (post-2007 boundaries) with at least 50 non-Western descendants in 2008. Immigrant share is the number of non-Western immigrants divided by total population in 2008Q1 (FOLK1C). Employment rates are from Statistics Denmark RAS200 for non-Western descendants aged 25--39. Tertiary education includes short-cycle higher education, bachelor, and master/PhD programs (HFUDD11). Employment gap is the difference between Danish-origin and non-Western descendant employment rates.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}',
  summ_vars$imm_share_mean, summ_vars$imm_share_sd,
  summ_vars$imm_share_min, summ_vars$imm_share_max,
  summ_vars$emp_mean, summ_vars$emp_sd, summ_vars$emp_min, summ_vars$emp_max,
  summ_vars$edu_mean, summ_vars$edu_sd, summ_vars$edu_min, summ_vars$edu_max,
  summ_vars$prim_mean, summ_vars$prim_sd, summ_vars$prim_min, summ_vars$prim_max,
  summ_vars$gap_mean, summ_vars$gap_sd, summ_vars$gap_min, summ_vars$gap_max,
  format(round(summ_vars$pop_mean), big.mark = ","),
  format(round(summ_vars$pop_sd), big.mark = ","),
  format(round(summ_vars$pop_min), big.mark = ","),
  format(round(summ_vars$pop_max), big.mark = ","),
  format(round(summ_vars$desc_mean), big.mark = ","),
  format(round(summ_vars$desc_sd), big.mark = ","),
  format(round(summ_vars$desc_min), big.mark = ","),
  format(round(summ_vars$desc_max), big.mark = ","),
  summ_vars$dk_emp_mean, summ_vars$dk_emp_sd,
  nrow(analysis))

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 2: Main Results (Employment)
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main Employment Results...\n")

setFixest_dict(c(
  imm_share_2008 = "Immigrant share (2008)",
  emp_rate_desc = "Descendant employment rate",
  log_pop = "Log population",
  total_emp_rate = "Total employment rate",
  share_tertiary = "Descendant tertiary share",
  emp_gap = "Employment gap"
))

tab2 <- etable(
  models$emp$m1, models$emp$m2, models$emp$m3, models$emp$m4,
  tex = TRUE,
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  drop = "Intercept",
  title = "Effect of Immigrant Concentration on Non-Western Descendant Employment",
  label = "tab:employment",
  notes = c(
    "Heteroskedasticity-robust standard errors in parentheses.",
    "The dependent variable is the employment rate (\\%) of non-Western descendants aged 25--39 in 2022.",
    "Immigrant share is the non-Western immigrant population divided by total population in 2008Q1.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)
writeLines(tab2, "../tables/tab2_employment.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 3: Main Results (Education)
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 3: Main Education Results...\n")

tab3 <- etable(
  models$edu$m1, models$edu$m2, models$edu$m3, models$edu$m4,
  tex = TRUE,
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  drop = "Intercept",
  title = "Effect of Immigrant Concentration on Non-Western Descendant Tertiary Education",
  label = "tab:education",
  notes = c(
    "Heteroskedasticity-robust standard errors in parentheses.",
    "The dependent variable is the share of descendants aged 25--39 with tertiary education in 2023.",
    "Tertiary education includes short-cycle higher education, bachelor, and master/PhD programs.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)
writeLines(tab3, "../tables/tab3_education.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 4: Robustness
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

tab4 <- etable(
  models$emp$m4, robust$nocity_emp, robust$weighted_emp,
  models$edu$m4, robust$nocity_edu, robust$weighted_edu,
  tex = TRUE,
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  keep = c("Immigrant share"),
  drop = "Intercept",
  headers = c("Baseline", "Excl. cities", "Weighted",
              "Baseline", "Excl. cities", "Weighted"),
  title = "Robustness: Alternative Samples and Weighting",
  label = "tab:robustness",
  notes = c(
    "All specifications include log population, total employment rate, and region fixed effects.",
    "Heteroskedasticity-robust standard errors in parentheses.",
    "Columns 1--3: dependent variable is descendant employment rate (\\%).",
    "Columns 4--6: dependent variable is descendant tertiary education share.",
    "``Excl.\\ cities'' drops Copenhagen, Frederiksberg, Aarhus, Odense, and Aalborg.",
    "``Weighted'' uses total 2008 population as analytic weights.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 5: Placebo and Mechanism
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 5: Placebo and Mechanism...\n")

tab5 <- etable(
  models$gap$m3, robust$placebo_dk,
  tex = TRUE,
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  keep = c("Immigrant share"),
  drop = "Intercept",
  headers = c("Employment gap", "Danish-origin employment"),
  title = "Mechanism and Placebo Tests",
  label = "tab:placebo",
  notes = c(
    "Heteroskedasticity-robust standard errors in parentheses.",
    "Column 1: dependent variable is the employment gap (Danish-origin minus descendant rate, pp).",
    "Column 2: dependent variable is the Danish-origin employment rate (\\%, placebo).",
    "Both specifications include log population and region fixed effects.",
    "The null result in Column 2 suggests that immigrant share does not merely proxy for local labor market conditions.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)
writeLines(tab5, "../tables/tab5_placebo.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table F1: SDE...\n")

# Extract coefficients from preferred specifications (model 4)
emp_fit <- models$emp$m4
edu_fit <- models$edu$m4
gap_fit <- models$gap$m3

# Employment
beta_emp <- coef(emp_fit)["imm_share_2008"]
se_emp <- sqrt(diag(vcov(emp_fit)))["imm_share_2008"]
sd_y_emp <- sd(analysis$emp_rate_desc, na.rm = TRUE)
sd_x <- sd(analysis$imm_share_2008)
sde_emp <- beta_emp * sd_x / sd_y_emp
se_sde_emp <- se_emp * sd_x / sd_y_emp

# Education
beta_edu <- coef(edu_fit)["imm_share_2008"]
se_edu <- sqrt(diag(vcov(edu_fit)))["imm_share_2008"]
sd_y_edu <- sd(analysis$share_tertiary, na.rm = TRUE)
sde_edu <- beta_edu * sd_x / sd_y_edu
se_sde_edu <- se_edu * sd_x / sd_y_edu

# Employment gap
beta_gap <- coef(gap_fit)["imm_share_2008"]
se_gap <- sqrt(diag(vcov(gap_fit)))["imm_share_2008"]
sd_y_gap <- sd(analysis$emp_gap, na.rm = TRUE)
sde_gap <- beta_gap * sd_x / sd_y_gap
se_sde_gap <- se_gap * sd_x / sd_y_gap

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Employment rate & OLS + region FE & %.2f & %.4f & %.2f & %.3f & %.3f & %s \\\\",
    beta_emp, sd_x, sd_y_emp, sde_emp, se_sde_emp, classify(sde_emp)),
  sprintf("Tertiary share & OLS + region FE & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    beta_edu, sd_x, sd_y_edu, sde_edu, se_sde_edu, classify(sde_edu)),
  sprintf("Employment gap & OLS + region FE & %.2f & %.4f & %.2f & %.3f & %.3f & %s \\\\",
    beta_gap, sd_x, sd_y_gap, sde_gap, se_sde_gap, classify(sde_gap)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE). ",
    "The treatment is continuous (non-Western immigrant share, 2008), so ",
    "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
    "\\textbf{Research question:} Does refugee placement intensity affect second-generation outcomes? ",
    "\\textbf{Treatment:} Non-Western immigrant share of total municipality population (2008Q1). ",
    "\\textbf{Data:} Statistics Denmark StatBank, 99 municipalities, 2008--2023. ",
    "\\textbf{Method:} OLS with region FE, heteroskedasticity-robust SEs. ",
    "Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
    "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), ",
    "moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). ",
    "Classification labels refer to the magnitude of the standardized point estimate, ",
    "not to statistical significance.}"),
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")

# (sde_lines written above)

cat("\n=== All tables generated ===\n")
cat("Tables saved in ../tables/:\n")
for (f in list.files("../tables/", pattern = "\\.tex$")) {
  cat(sprintf("  %s\n", f))
}
