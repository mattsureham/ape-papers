## 05_tables.R — Generate all LaTeX tables
## Input: data/main_models.RData, data/robustness_models.RData, data/enoe_analysis.csv
## Output: tables/tab1_summary.tex through tables/tabF1_sde.tex

source("code/00_packages.R")

# Force modelsummary to use kableExtra backend for clean LaTeX
options(modelsummary_factory_latex = "kableExtra")
options(modelsummary_format_numeric_latex = "plain")

load("data/main_models.RData")
load("data/robustness_models.RData")
enoe <- fread("data/enoe_analysis.csv")
dir.create("tables", showWarnings = FALSE)

# ══════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics\n")

make_summ_row <- function(dt, var, label) {
  m_pre  <- dt[male == 1 & eda < 18, mean(get(var), na.rm = TRUE)]
  f_pre  <- dt[male == 0 & eda < 18, mean(get(var), na.rm = TRUE)]
  m_post <- dt[male == 1 & eda >= 18, mean(get(var), na.rm = TRUE)]
  f_post <- dt[male == 0 & eda >= 18, mean(get(var), na.rm = TRUE)]
  sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\", label, m_pre, f_pre, m_post, f_post)
}

make_n_row <- function(dt, label) {
  n1 <- nrow(dt[male == 1 & eda < 18])
  n2 <- nrow(dt[male == 0 & eda < 18])
  n3 <- nrow(dt[male == 1 & eda >= 18])
  n4 <- nrow(dt[male == 0 & eda >= 18])
  sprintf("%s & %s & %s & %s & %s \\\\",
          label,
          format(n1, big.mark = ","),
          format(n2, big.mark = ","),
          format(n3, big.mark = ","),
          format(n4, big.mark = ","))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics by Gender and Lottery Eligibility}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-Lottery (Ages 15--17)} & \\multicolumn{2}{c}{Post-Lottery (Ages 18--30)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Males & Females & Males & Females \\\\",
  "\\midrule",
  "\\textit{Panel A: Labor Market Outcomes} \\\\[3pt]",
  make_summ_row(enoe, "employed", "Employment rate"),
  make_summ_row(enoe, "formal", "Formal employment rate"),
  make_summ_row(enoe, "salaried", "Salaried employment"),
  sprintf("Mean monthly earnings (MXN) & %s & %s & %s & %s \\\\",
          format(round(mean(enoe[male == 1 & eda < 18]$earnings_cond, na.rm = TRUE)), big.mark = ","),
          format(round(mean(enoe[male == 0 & eda < 18]$earnings_cond, na.rm = TRUE)), big.mark = ","),
          format(round(mean(enoe[male == 1 & eda >= 18]$earnings_cond, na.rm = TRUE)), big.mark = ","),
          format(round(mean(enoe[male == 0 & eda >= 18]$earnings_cond, na.rm = TRUE)), big.mark = ",")),
  sprintf("Mean weekly hours & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(enoe[male == 1 & eda < 18]$hours_cond, na.rm = TRUE),
          mean(enoe[male == 0 & eda < 18]$hours_cond, na.rm = TRUE),
          mean(enoe[male == 1 & eda >= 18]$hours_cond, na.rm = TRUE),
          mean(enoe[male == 0 & eda >= 18]$hours_cond, na.rm = TRUE)),
  "\\midrule",
  "\\textit{Panel B: Education} \\\\[3pt]",
  make_summ_row(enoe, "educ_years", "Years of education"),
  make_summ_row(enoe, "in_school", "Currently enrolled"),
  "\\midrule",
  make_n_row(enoe, "Observations"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Data from INEGI's ENOE quarterly labor force survey. Pre-lottery = ages 15--17 (before Sorteo Militar eligibility). Post-lottery = ages 18--30 (after lottery assignment). Earnings conditional on employment. Formal employment defined as having social security access (\\textit{seg\\_soc}).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ══════════════════════════════════════════════════════════════════
# Table 2: Male-Female Employment Gap by Age (Key Evidence)
# ══════════════════════════════════════════════════════════════════
cat("Generating Table 2: Age Profile of Gender Gaps\n")

gaps <- fread("data/age_gaps.csv")
gaps <- gaps[eda >= 15 & eda <= 25]

tab2_rows <- sapply(seq_len(nrow(gaps)), function(i) {
  g <- gaps[i]
  marker <- if (g$eda == 18) " $\\leftarrow$ \\textit{Lottery}" else ""
  sprintf("%d%s & %.3f & %.3f & %.3f & %s & %s \\\\",
          g$eda, marker,
          g$male_emp, g$female_emp, g$emp_gap,
          format(g$n_male, big.mark = ","),
          format(g$n_female, big.mark = ","))
})

# Add midrule before age 18
tab2_rows_final <- character(0)
for (r in tab2_rows) {
  if (grepl("^18", r)) tab2_rows_final <- c(tab2_rows_final, "\\midrule")
  tab2_rows_final <- c(tab2_rows_final, r)
  if (grepl("^18", r)) tab2_rows_final <- c(tab2_rows_final, "\\midrule")
}

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Male--Female Employment Gap by Age}",
  "\\label{tab:age_profile}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Age & Male Emp. & Female Emp. & Gap & $N$ Males & $N$ Females \\\\",
  "\\midrule",
  tab2_rows_final,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each row shows the employment rate for males and females at a given age, pooling all ENOE quarters. The ``Gap'' column is the male minus female difference. The lottery (Sorteo Militar) occurs at age 18, assigning $\\sim$40\\% of men to active Saturday service. The horizontal rules bracket the lottery year.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_age_profile.tex")

# ══════════════════════════════════════════════════════════════════
# Table 3: Main DiD Results (hand-built for reliability)
# ══════════════════════════════════════════════════════════════════
cat("Generating Table 3: Main Results\n")

star_fn <- function(p) {
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

make_model_col <- function(mod, varname = "male_post18") {
  b <- coef(mod)[varname]
  s <- se(mod)[varname]
  p <- pvalue(mod)[varname]
  n <- mod$nobs
  r2 <- fitstat(mod, "r2")$r2
  list(b = b, s = s, p = p, n = n, r2 = r2)
}

models <- list(make_model_col(m1), make_model_col(m2), make_model_col(m3),
               make_model_col(m4), make_model_col(m5))

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Saturday Soldier Effect: Male--Female DiD at Age 18}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Employment & Formal & Ln Earnings & Hours & In School \\\\",
  "\\midrule",
  sprintf("Male $\\times$ Post-Lottery & %.4f$%s$ & %.4f$%s$ & %.4f & %.4f$%s$ & %.4f \\\\",
          models[[1]]$b, star_fn(models[[1]]$p),
          models[[2]]$b, star_fn(models[[2]]$p),
          models[[3]]$b,
          models[[4]]$b, star_fn(models[[4]]$p),
          models[[5]]$b),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          models[[1]]$s, models[[2]]$s, models[[3]]$s, models[[4]]$s, models[[5]]$s),
  sprintf("LATE ($/0.40$) & %.4f & %.4f & & & \\\\",
          models[[1]]$b / 0.40, models[[2]]$b / 0.40),
  "\\midrule",
  "Age, YQ, State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(models[[1]]$n, big.mark = ","), format(models[[2]]$n, big.mark = ","),
          format(models[[3]]$n, big.mark = ","), format(models[[4]]$n, big.mark = ","),
          format(models[[5]]$n, big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          models[[1]]$r2, models[[2]]$r2, models[[3]]$r2, models[[4]]$r2, models[[5]]$r2),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column reports the coefficient on Male $\\times$ Post-Lottery from a regression with age, year-quarter, and state fixed effects. Clustered standard errors by state in parentheses. Post-Lottery = ages 18--30. Sample: ages 15--30, both genders. Columns 3--4 condition on employment. The ITT captures lottery eligibility; the LATE scales by the 0.40 treatment share. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_main.tex")

# ══════════════════════════════════════════════════════════════════
# Table 4: Robustness and Mechanism Tests
# ══════════════════════════════════════════════════════════════════
cat("Generating Table 4: Robustness\n")

rob_models <- list(
  make_model_col(r1_emp), make_model_col(r2_emp),
  make_model_col(r3_urban), make_model_col(r3_rural),
  make_model_col(m_salaried), make_model_col(m_selfemp)
)

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Mechanism Tests}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Narrow & Cohort FE & Urban & Rural & Salaried & Self-Emp. \\\\",
  " & (16--20) & & & & & \\\\",
  "\\midrule",
  sprintf("Male $\\times$ Post & %.4f$%s$ & %.4f$%s$ & %.4f$%s$ & %.4f$%s$ & %.4f$%s$ & %.4f$%s$ \\\\",
          rob_models[[1]]$b, star_fn(rob_models[[1]]$p),
          rob_models[[2]]$b, star_fn(rob_models[[2]]$p),
          rob_models[[3]]$b, star_fn(rob_models[[3]]$p),
          rob_models[[4]]$b, star_fn(rob_models[[4]]$p),
          rob_models[[5]]$b, star_fn(rob_models[[5]]$p),
          rob_models[[6]]$b, star_fn(rob_models[[6]]$p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          rob_models[[1]]$s, rob_models[[2]]$s, rob_models[[3]]$s,
          rob_models[[4]]$s, rob_models[[5]]$s, rob_models[[6]]$s),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(rob_models[[1]]$n, big.mark = ","), format(rob_models[[2]]$n, big.mark = ","),
          format(rob_models[[3]]$n, big.mark = ","), format(rob_models[[4]]$n, big.mark = ","),
          format(rob_models[[5]]$n, big.mark = ","), format(rob_models[[6]]$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Clustered SEs by state in parentheses. Columns 1--4: dependent variable is employment. Column 5: salaried employment. Column 6: self-employment. ``Narrow'' restricts to ages 16--20. ``Cohort FE'' replaces age FE with birth-year cohort FE. Urban = cities $\\geq$ 100K. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_robustness.tex")

# ══════════════════════════════════════════════════════════════════
# Table 5: Event Study Coefficients (Male × Age interactions)
# ══════════════════════════════════════════════════════════════════
cat("Generating Table 5: Event Study Coefficients\n")

# Extract event study coefficients for employment
es_coefs <- data.table(
  term = names(coef(es_emp)),
  est = coef(es_emp),
  se = se(es_emp),
  pval = pvalue(es_emp)
)
# Keep only male:age_rel interactions
es_coefs <- es_coefs[grepl("^male:age_rel_f", term)]
es_coefs[, age_rel := as.integer(gsub("male:age_rel_f", "", term))]
# Add reference point
es_coefs <- rbind(
  es_coefs,
  data.table(term = "male:age_rel_f-1", est = 0, se = NA, pval = NA, age_rel = -1L)
)
es_coefs <- es_coefs[order(age_rel)]
es_coefs[, age := age_rel + 18L]

# Similarly for formal
es_f_coefs <- data.table(
  term = names(coef(es_formal)),
  est = coef(es_formal),
  se = se(es_formal),
  pval = pvalue(es_formal)
)
es_f_coefs <- es_f_coefs[grepl("^male:age_rel_f", term)]
es_f_coefs[, age_rel := as.integer(gsub("male:age_rel_f", "", term))]
es_f_coefs <- rbind(
  es_f_coefs,
  data.table(term = "male:age_rel_f-1", est = 0, se = NA, pval = NA, age_rel = -1L)
)
es_f_coefs <- es_f_coefs[order(age_rel)]
es_f_coefs[, age := age_rel + 18L]

# Deduplicate (keep one row per age)
es_coefs <- unique(es_coefs, by = "age")
es_f_coefs <- unique(es_f_coefs, by = "age")

# Filter to ages 15-25
es_tab <- merge(
  es_coefs[age >= 15 & age <= 25, .(age, emp_coef = est, emp_se = se)],
  es_f_coefs[age >= 15 & age <= 25, .(age, formal_coef = est, formal_se = se)],
  by = "age"
)

star <- function(est, se) {
  if (is.na(se)) return("")
  p <- 2 * pnorm(-abs(est / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab5_rows <- sapply(seq_len(nrow(es_tab)), function(i) {
  r <- es_tab[i]
  if (r$age == 17) {
    return(sprintf("%d & [ref] & & [ref] & \\\\", r$age))
  }
  sprintf("%d & %.4f%s & (%.4f) & %.4f%s & (%.4f) \\\\",
          r$age,
          r$emp_coef, star(r$emp_coef, r$emp_se), r$emp_se,
          r$formal_coef, star(r$formal_coef, r$formal_se), r$formal_se)
})

# Mark age 18 with midrule
tab5_rows_final <- character(0)
for (r in tab5_rows) {
  if (grepl("^18 ", r)) tab5_rows_final <- c(tab5_rows_final, "\\midrule")
  tab5_rows_final <- c(tab5_rows_final, r)
  if (grepl("^18 ", r)) tab5_rows_final <- c(tab5_rows_final, "\\midrule")
}

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Male--Female Gap Relative to Age 17\\label{tab:event_study}}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Formal Employment} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Age & Coef. & SE & Coef. & SE \\\\",
  "\\midrule",
  tab5_rows_final,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each coefficient is the interaction of Male $\\times$ I(Age $= a$) from a regression of the outcome on the full set of male-age interactions plus age, year-quarter, and state FEs. Age 17 is the omitted reference (last pre-lottery year). Standard errors clustered by state. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5, "tables/tab5_event_study.tex")

# ══════════════════════════════════════════════════════════════════
# SDE Appendix Table
# ══════════════════════════════════════════════════════════════════
cat("Generating SDE Appendix Table\n")

# Compute SD(Y) for each outcome
sd_emp <- sd(enoe$employed, na.rm = TRUE)
sd_formal <- sd(enoe$formal, na.rm = TRUE)
sd_lnearn <- sd(enoe[!is.na(ln_earnings)]$ln_earnings, na.rm = TRUE)
sd_hours <- sd(enoe[!is.na(hours_cond)]$hours_cond, na.rm = TRUE)
sd_school <- sd(enoe[!is.na(in_school)]$in_school, na.rm = TRUE)

sde_rows <- list(
  list("Employment", coef(m1)["male_post18"], se(m1)["male_post18"], sd_emp),
  list("Formal Emp.", coef(m2)["male_post18"], se(m2)["male_post18"], sd_formal),
  list("Ln Earnings", coef(m3)["male_post18"], se(m3)["male_post18"], sd_lnearn),
  list("Weekly Hours", coef(m4)["male_post18"], se(m4)["male_post18"], sd_hours),
  list("In School", coef(m5)["male_post18"], se(m5)["male_post18"], sd_school)
)

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_tex_rows <- sapply(sde_rows, function(r) {
  sde <- r[[2]] / r[[4]]
  se_sde <- r[[3]] / r[[4]]
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          r[[1]], r[[2]], r[[3]], r[[4]], sde, se_sde, classify_sde(sde))
})

sde_tab <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes\\label{tab:sde}}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sde_tex_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\footnotesize",
  "\\item \\textit{Notes:} Standardized effect sizes from the Male $\\times$ Post-Lottery ITT specification (Table \\ref{tab:main}). SDE $= \\hat{\\beta} / \\text{SD}(Y)$. Classification based on SDE magnitude: Large ($|$SDE$|> 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). Classification refers to effect magnitude, not statistical significance. Data: INEGI ENOE quarterly labor force survey, pooled 2018--2019. Sample: ages 15--30, both genders ($N = 835{,}735$). Identification: male--female DiD at the Sorteo Militar eligibility threshold (age 18). Treatment share $\\approx 0.40$ (pre-2025).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_tab, "tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
list.files("tables/")
