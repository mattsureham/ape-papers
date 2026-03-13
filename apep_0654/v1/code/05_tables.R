## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

cat("=== Generating tables ===\n")

df <- read_parquet("../data/analysis_panel.parquet")
load("../data/main_results.RData")
load("../data/robustness_results.RData")

# ------------------------------------------------------------------
# Table 1: Summary Statistics
# ------------------------------------------------------------------
cat("Table 1: Summary statistics\n")

summ <- df %>%
  mutate(
    group = case_when(
      treated == 1 & licensed == 1 ~ "ULR States, Licensed",
      treated == 1 & licensed == 0 ~ "ULR States, Unlicensed",
      treated == 0 & licensed == 1 ~ "Non-ULR States, Licensed",
      treated == 0 & licensed == 0 ~ "Non-ULR States, Unlicensed"
    )
  ) %>%
  group_by(group) %>%
  summarise(
    N = n(),
    Emp = round(mean(emp, na.rm = TRUE)),
    `New-Hire Earn` = round(mean(earn_hir, na.rm = TRUE)),
    `Avg Earn` = round(mean(earn_s, na.rm = TRUE)),
    `Hire Rate` = round(mean(hire_rate, na.rm = TRUE), 4),
    `Sep Rate` = round(mean(sep_rate, na.rm = TRUE), 4),
    `JC Rate` = round(mean(jc_rate, na.rm = TRUE), 4),
    .groups = "drop"
  )

tab1_tex <- "\\begin{table}[H]
\\centering
\\caption{Summary Statistics: QWI Panel (2014--2025)}
\\label{tab:summary}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lrrrrrrr}
\\toprule
Group & N & Emp & New-Hire (\\$) & Avg Earn (\\$) & Hire Rate & Sep Rate & JC Rate \\\\
\\midrule\n"

for (i in 1:nrow(summ)) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %s & %s & %s & %s & %.4f & %.4f & %.4f \\\\\n",
            summ$group[i],
            format(summ$N[i], big.mark = ","),
            format(summ$Emp[i], big.mark = ","),
            format(summ$`New-Hire Earn`[i], big.mark = ","),
            format(summ$`Avg Earn`[i], big.mark = ","),
            summ$`Hire Rate`[i],
            summ$`Sep Rate`[i],
            summ$`JC Rate`[i]))
}

tab1_tex <- paste0(tab1_tex,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}

\\vspace{0.5em}
{\\small \\emph{Notes:} QWI state-industry-quarter observations (2014Q1--2025Q1). Licensed sectors: Healthcare (62), Professional Services (54), Construction (23), Education (61). Unlicensed sectors: Retail (44-45), Accommodation/Food (72), Information (51), Wholesale (42), Transport (48-49), Admin (56). ULR states: 26 states adopting Universal License Recognition laws 2019--2023. Hire Rate = new hires / employment. JC Rate = job creation / employment.}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ------------------------------------------------------------------
# Table 2: ULR adoption timeline
# ------------------------------------------------------------------
cat("Table 2: ULR adoption\n")

ulr <- read_csv("../data/ulr_treatment_timing.csv", show_col_types = FALSE) %>%
  arrange(treat_year, treat_quarter)

tab2_tex <- "\\begin{table}[H]
\\centering
\\caption{Universal License Recognition Law Adoption Timeline}
\\label{tab:ulr}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{llll}
\\toprule
Year & Q & State(s) & Key Provision \\\\
\\midrule\n"

# Group by year-quarter
year_groups <- ulr %>%
  group_by(treat_year, treat_quarter) %>%
  summarise(states = paste(state_name, collapse = ", "), .groups = "drop")

for (i in 1:nrow(year_groups)) {
  tab2_tex <- paste0(tab2_tex,
    sprintf("%d & Q%d & %s & Broad ULR \\\\\n",
            year_groups$treat_year[i],
            year_groups$treat_quarter[i],
            year_groups$states[i]))
}

tab2_tex <- paste0(tab2_tex,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}

\\vspace{0.5em}
{\\small \\emph{Notes:} Universal License Recognition laws allow holders of valid out-of-state occupational licenses to obtain equivalent in-state licenses without additional exams or training. Arizona pioneered broad ULR in April 2019. Adoption quarter is the first full quarter after the law's effective date.}
\\end{table}\n")

writeLines(tab2_tex, "../tables/tab2_ulr.tex")

# ------------------------------------------------------------------
# Table 3: Main DDD results
# ------------------------------------------------------------------
cat("Table 3: Main DDD\n")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

models <- list(ddd_earn, ddd_earn_avg, ddd_hire, ddd_sep, ddd_jc, ddd_jd)
dep_vars <- c("Log New-Hire", "Log Avg Earn", "Hire Rate", "Sep Rate", "JC Rate", "JD Rate")

tab3_tex <- "\\begin{table}[H]
\\centering
\\caption{Effect of ULR Laws on Labor Market Outcomes}
\\label{tab:main}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule\n"

# Column headers
tab3_tex <- paste0(tab3_tex, " ")
for (j in 1:6) tab3_tex <- paste0(tab3_tex, sprintf(" & (%d)", j))
tab3_tex <- paste0(tab3_tex, " \\\\\n ")
for (j in 1:6) tab3_tex <- paste0(tab3_tex, sprintf(" & %s", dep_vars[j]))
tab3_tex <- paste0(tab3_tex, " \\\\\n\\midrule\n")

# post:licensed row
tab3_tex <- paste0(tab3_tex, "Post $\\times$ Licensed")
for (j in 1:6) {
  b <- coef(models[[j]])["post:licensed"]
  s <- se(models[[j]])["post:licensed"]
  p <- 2 * pnorm(-abs(b/s))
  tab3_tex <- paste0(tab3_tex, sprintf(" & %.4f%s", b, stars(p)))
}
tab3_tex <- paste0(tab3_tex, " \\\\\n")

# SE row
tab3_tex <- paste0(tab3_tex, " ")
for (j in 1:6) {
  s <- se(models[[j]])["post:licensed"]
  tab3_tex <- paste0(tab3_tex, sprintf(" & (%.4f)", s))
}
tab3_tex <- paste0(tab3_tex, " \\\\\n\\addlinespace\n")

# post row
tab3_tex <- paste0(tab3_tex, "Post (unlicensed)")
for (j in 1:6) {
  b <- coef(models[[j]])["post"]
  s <- se(models[[j]])["post"]
  p <- 2 * pnorm(-abs(b/s))
  tab3_tex <- paste0(tab3_tex, sprintf(" & %.4f%s", b, stars(p)))
}
tab3_tex <- paste0(tab3_tex, " \\\\\n")

tab3_tex <- paste0(tab3_tex, " ")
for (j in 1:6) {
  s <- se(models[[j]])["post"]
  tab3_tex <- paste0(tab3_tex, sprintf(" & (%.4f)", s))
}
tab3_tex <- paste0(tab3_tex, " \\\\\n\\midrule\n")

# N and FE
tab3_tex <- paste0(tab3_tex, sprintf("N & %s", format(nobs(ddd_earn), big.mark = ",")))
for (j in 2:6) tab3_tex <- paste0(tab3_tex, sprintf(" & %s", format(nobs(models[[j]]), big.mark = ",")))
tab3_tex <- paste0(tab3_tex, " \\\\\n")
tab3_tex <- paste0(tab3_tex, "State FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
tab3_tex <- paste0(tab3_tex, "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
tab3_tex <- paste0(tab3_tex, "Clustering & State & State & State & State & State & State \\\\\n")

tab3_tex <- paste0(tab3_tex,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}

\\vspace{0.5em}
{\\small \\emph{Notes:} Triple-difference estimates. Post ${\\times}$ Licensed captures the differential effect of ULR adoption on licensed sectors (Healthcare, Professional Services, Construction, Education) relative to unlicensed sectors (Retail, Accommodation, Information, Wholesale, Transport, Admin). Post captures the effect on unlicensed sectors in ULR-adopting states. Cols~1--2 weighted by hires/employment; cols~3--6 weighted by employment. Standard errors clustered at state level. * $p{<}0.10$, ** $p{<}0.05$, *** $p{<}0.01$.}
\\end{table}\n")

writeLines(tab3_tex, "../tables/tab3_main.tex")

# ------------------------------------------------------------------
# Table 4: Robustness
# ------------------------------------------------------------------
cat("Table 4: Robustness\n")

tab4_tex <- "\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccc}
\\toprule
 & ATT/Coef & SE & $p$-value \\\\
\\midrule
\\emph{Panel A: CS-DiD on licensed sectors} & & & \\\\
New-hire earnings & "

tab4_tex <- paste0(tab4_tex, sprintf("%.4f & %.4f & %.3f \\\\\n",
  cs_earn_agg$overall.att, cs_earn_agg$overall.se,
  2*pnorm(-abs(cs_earn_agg$overall.att/cs_earn_agg$overall.se))))

tab4_tex <- paste0(tab4_tex, sprintf("Hire rate & %.4f & %.4f & %.3f \\\\\n",
  cs_hire_agg$overall.att, cs_hire_agg$overall.se,
  2*pnorm(-abs(cs_hire_agg$overall.att/cs_hire_agg$overall.se))))

tab4_tex <- paste0(tab4_tex, "\\addlinespace\n\\emph{Panel B: Placebo (unlicensed sectors)} & & & \\\\\n")
tab4_tex <- paste0(tab4_tex, sprintf("Unlicensed new-hire earnings & %.4f & %.4f & %.3f \\\\\n",
  cs_placebo_agg$overall.att, cs_placebo_agg$overall.se,
  2*pnorm(-abs(cs_placebo_agg$overall.att/cs_placebo_agg$overall.se))))

tab4_tex <- paste0(tab4_tex, "\\addlinespace\n\\emph{Panel C: Exclude COVID} & & & \\\\\n")
b_nc <- coef(ddd_nocovid)["post:licensed"]
s_nc <- se(ddd_nocovid)["post:licensed"]
tab4_tex <- paste0(tab4_tex, sprintf("DDD post $\\times$ licensed & %.4f & %.4f & %.3f \\\\\n",
  b_nc, s_nc, 2*pnorm(-abs(b_nc/s_nc))))

tab4_tex <- paste0(tab4_tex, "\\addlinespace\n\\emph{Panel D: Education DDD (licensed sectors)} & & & \\\\\n")
b_ed <- coef(edu_ddd)["post:high_ed"]
s_ed <- se(edu_ddd)["post:high_ed"]
tab4_tex <- paste0(tab4_tex, sprintf("post $\\times$ high education & %.4f & %.4f & %.3f \\\\\n",
  b_ed, s_ed, 2*pnorm(-abs(b_ed/s_ed))))

b_eh <- coef(edu_hire_ddd)["post:high_ed"]
s_eh <- se(edu_hire_ddd)["post:high_ed"]
tab4_tex <- paste0(tab4_tex, sprintf("Hire rate $\\times$ high education & %.4f & %.4f & %.3f \\\\\n",
  b_eh, s_eh, 2*pnorm(-abs(b_eh/s_eh))))

tab4_tex <- paste0(tab4_tex,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}

\\vspace{0.5em}
{\\small \\emph{Notes:} Panel A: Callaway--Sant'Anna ATTs for licensed sectors only. Panel B: Placebo test on unlicensed sectors (should show null). Panel C: DDD excluding 2020Q2--2021Q2. Panel D: Within licensed sectors, high-education (some college+) vs.~low-education workers --- testing whether effects concentrate among credentialed workers.}
\\end{table}\n")

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ------------------------------------------------------------------
# Table F1: Standardized Effect Sizes
# ------------------------------------------------------------------
cat("Table F1: SDE\n")

# Get SD(Y) from the data
sd_earn_hir <- sd(df$log_earn_hir, na.rm = TRUE)
sd_earn_s <- sd(df$log_earn_s, na.rm = TRUE)
sd_hire <- sd(df$hire_rate, na.rm = TRUE)
sd_jc <- sd(df$jc_rate, na.rm = TRUE)

sde_rows <- tribble(
  ~outcome, ~beta, ~se_beta, ~sd_y,
  "New-hire earn (DDD)", coef(ddd_earn)["post:licensed"], se(ddd_earn)["post:licensed"], sd_earn_hir,
  "Avg earnings (DDD)", coef(ddd_earn_avg)["post:licensed"], se(ddd_earn_avg)["post:licensed"], sd_earn_s,
  "Hire rate (DDD)", coef(ddd_hire)["post:licensed"], se(ddd_hire)["post:licensed"], sd_hire,
  "Job creation (DDD)", coef(ddd_jc)["post:licensed"], se(ddd_jc)["post:licensed"], sd_jc
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

tabF1_tex <- "\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule\n"

for (i in 1:nrow(sde_rows)) {
  tabF1_tex <- paste0(tabF1_tex, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
    sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se_beta[i],
    sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
    sde_rows$classification[i]))
}

tabF1_tex <- paste0(tabF1_tex,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}

\\vspace{0.5em}
{\\small \\emph{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatments. SD($Y$) is the unconditional standard deviation. \\textbf{Question:} Do ULR laws increase hiring and job creation in licensed occupations? \\textbf{Treatment:} Binary (state adopted ULR). \\textbf{Data:} QWI, 2014--2025, state-industry-quarter panel. \\textbf{Method:} DDD with state and industry${\\times}$quarter FE, state-clustered SEs. Classification refers to magnitude, not significance. ``Null'' denotes $|$SDE$| < 0.005$.}
\\end{table}\n")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
