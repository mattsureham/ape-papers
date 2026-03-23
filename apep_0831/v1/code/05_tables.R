## 05_tables.R — Generate all LaTeX tables
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

source("00_packages.R")

df <- readRDS("../data/analysis.rds")
models <- readRDS("../data/models.rds")
robustness <- readRDS("../data/robustness_models.rds")
es_coefs <- readRDS("../data/event_study_coefs.rds")

## Helper: extract coefficient + SE + stars
extract_coef <- function(model, var_name) {
  ct <- coeftable(model)
  if (!(var_name %in% rownames(ct))) return(list(est = "", se = "", stars = ""))
  row <- ct[var_name, ]
  stars <- ifelse(row["Pr(>|t|)"] < 0.01, "^{***}",
           ifelse(row["Pr(>|t|)"] < 0.05, "^{**}",
           ifelse(row["Pr(>|t|)"] < 0.10, "^{*}", "")))
  list(
    est = sprintf("%.4f%s", row["Estimate"], stars),
    se = sprintf("(%.4f)", row["Std. Error"]),
    stars = stars,
    raw_est = row["Estimate"],
    raw_se = row["Std. Error"]
  )
}

n_fmt <- function(x) format(nobs(x), big.mark = ",")

## ========================================================
## Table 1: Summary Statistics
## ========================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- df %>% filter(post == 0, !is.na(earn), earn > 0, !is.na(emp), emp > 0)

## Panel A: By race
race_white <- pre %>% filter(race == "A1")
race_black <- pre %>% filter(race == "A2")

w_earn <- weighted.mean(race_white$earn, race_white$emp, na.rm = TRUE)
b_earn <- weighted.mean(race_black$earn, race_black$emp, na.rm = TRUE)
w_sd <- sqrt(Hmisc::wtd.var(race_white$earn, race_white$emp, na.rm = TRUE))
b_sd <- sqrt(Hmisc::wtd.var(race_black$earn, race_black$emp, na.rm = TRUE))
w_emp <- mean(race_white$emp, na.rm = TRUE)
b_emp <- mean(race_black$emp, na.rm = TRUE)

## Panel B: By exposure
hi <- pre %>% filter(high_exposure == 1)
lo <- pre %>% filter(high_exposure == 0)
hi_earn <- weighted.mean(hi$earn, hi$emp, na.rm = TRUE)
lo_earn <- weighted.mean(lo$earn, lo$emp, na.rm = TRUE)
hi_sd <- sqrt(Hmisc::wtd.var(hi$earn, hi$emp, na.rm = TRUE))
lo_sd <- sqrt(Hmisc::wtd.var(lo$earn, lo$emp, na.rm = TRUE))

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Period Manufacturing Earnings (2015Q1--2018Q1)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Mean & SD & Mean & & \\\\",
  " & Earnings & Earnings & Employment & Counties & Obs. \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: By Race}} \\\\[3pt]",
  sprintf("White & %s & %s & %s & %s & %s \\\\",
          format(round(w_earn), big.mark = ","),
          format(round(w_sd), big.mark = ","),
          format(round(w_emp, 1), big.mark = ","),
          format(n_distinct(race_white$fips), big.mark = ","),
          format(nrow(race_white), big.mark = ",")),
  sprintf("Black & %s & %s & %s & %s & %s \\\\",
          format(round(b_earn), big.mark = ","),
          format(round(b_sd), big.mark = ","),
          format(round(b_emp, 1), big.mark = ","),
          format(n_distinct(race_black$fips), big.mark = ","),
          format(nrow(race_black), big.mark = ",")),
  sprintf("Gap & %s & & & & \\\\",
          format(round(w_earn - b_earn), big.mark = ",")),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: By Tariff Exposure}} \\\\[3pt]",
  sprintf("High exposure & %s & %s & & %s & %s \\\\",
          format(round(hi_earn), big.mark = ","),
          format(round(hi_sd), big.mark = ","),
          format(n_distinct(hi$fips), big.mark = ","),
          format(nrow(hi), big.mark = ",")),
  sprintf("Low exposure & %s & %s & & %s & %s \\\\",
          format(round(lo_earn), big.mark = ","),
          format(round(lo_sd), big.mark = ","),
          format(n_distinct(lo$fips), big.mark = ","),
          format(nrow(lo), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-period (2015Q1--2018Q1) summary statistics for manufacturing workers (NAICS 31--33). Earnings are average monthly earnings in dollars, weighted by employment. High-exposure counties have above-median share of 2016 employment in primary metals (NAICS 331) and fabricated metals (NAICS 332) among counties with positive metals employment. Source: Quarterly Workforce Indicators Race-Hispanic panel and County Business Patterns 2016.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ========================================================
## Table 2: Main Results
## ========================================================
cat("\n=== Table 2: Main Results ===\n")

m1 <- extract_coef(models$m1, "post_exposure")
m2_pe <- extract_coef(models$m2, "post_exposure")
m2_pb <- extract_coef(models$m2, "post_black")
m2_peb <- extract_coef(models$m2, "post_exposure_black")
m3_pe <- extract_coef(models$m3, "post_exposure")
m3_pb <- extract_coef(models$m3, "post_black")
m3_peb <- extract_coef(models$m3, "post_exposure_black")
m4_pe <- extract_coef(models$m4, "post_exposure")
m4_peb <- extract_coef(models$m4, "post_exposure_black")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Section 232 Tariffs and the Black-White Earnings Gap in Manufacturing}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\multicolumn{4}{c}{Log Average Monthly Earnings} \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Exposure & $%s$ & $%s$ & $%s$ & $%s$ \\\\",
          m1$est, m2_pe$est, m3_pe$est, m4_pe$est),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]",
          m1$se, m2_pe$se, m3_pe$se, m4_pe$se),
  sprintf("Post $\\times$ Black & & $%s$ & $%s$ & \\\\",
          m2_pb$est, m3_pb$est),
  sprintf(" & & %s & %s & \\\\[6pt]",
          m2_pb$se, m3_pb$se),
  sprintf("Post $\\times$ Exposure $\\times$ Black & & $%s$ & $%s$ & $%s$ \\\\",
          m2_peb$est, m3_peb$est, m4_peb$est),
  sprintf(" & & %s & %s & %s \\\\",
          m2_peb$se, m3_peb$se, m4_peb$se),
  "\\midrule",
  "County FE & Yes & Yes & & \\\\",
  "Quarter FE & Yes & Yes & & \\\\",
  "County $\\times$ Race FE & & & Yes & Yes \\\\",
  "Race $\\times$ Quarter FE & & & & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          n_fmt(models$m1), n_fmt(models$m2), n_fmt(models$m3), n_fmt(models$m4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log average monthly earnings from the QWI. Exposure is the county-level share of 2016 employment in primary metals (NAICS 331) and fabricated metals (NAICS 332). Post is an indicator for 2018Q2 onward (first full quarter after Section 232 took effect March 23, 2018). Black is an indicator for Black workers (vs.\\ White). Sample: manufacturing sector (NAICS 31--33), 2015Q1--2020Q1. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## ========================================================
## Table 3: Earnings vs. Employment vs. Hires
## ========================================================
cat("\n=== Table 3: Margins ===\n")

m_earn_pe <- extract_coef(models$m4, "post_exposure")
m_earn_peb <- extract_coef(models$m4, "post_exposure_black")
m_emp_pe <- extract_coef(models$m_emp, "post_exposure")
m_emp_peb <- extract_coef(models$m_emp, "post_exposure_black")
m_hir_pe <- extract_coef(models$m_hires, "post_exposure")
m_hir_peb <- extract_coef(models$m_hires, "post_exposure_black")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Protection and Race: Earnings, Employment, and Hiring}",
  "\\label{tab:margins}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) Log Earnings & (2) Log Employment & (3) Log Hires \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Exposure & $%s$ & $%s$ & $%s$ \\\\",
          m_earn_pe$est, m_emp_pe$est, m_hir_pe$est),
  sprintf(" & %s & %s & %s \\\\[6pt]",
          m_earn_pe$se, m_emp_pe$se, m_hir_pe$se),
  sprintf("Post $\\times$ Exposure $\\times$ Black & $%s$ & $%s$ & $%s$ \\\\",
          m_earn_peb$est, m_emp_peb$est, m_hir_peb$est),
  sprintf(" & %s & %s & %s \\\\",
          m_earn_peb$se, m_emp_peb$se, m_hir_peb$se),
  "\\midrule",
  "County $\\times$ Race FE & Yes & Yes & Yes \\\\",
  "Race $\\times$ Quarter FE & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          n_fmt(models$m4), n_fmt(models$m_emp), n_fmt(models$m_hires)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications include county$\\times$race and race$\\times$quarter fixed effects with state-clustered standard errors. Dependent variables: (1) log average monthly earnings; (2) log beginning-of-quarter employment; (3) log all hires during the quarter. Sample: manufacturing sector (NAICS 31--33), 2015Q1--2020Q1. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "../tables/tab3_margins.tex")
cat("Table 3 written.\n")

## ========================================================
## Table 4: Event Study
## ========================================================
cat("\n=== Table 4: Event Study ===\n")

es_data <- es_coefs %>%
  arrange(rel_q) %>%
  mutate(
    Quarter = case_when(
      rel_q < 0 ~ sprintf("$t%d$", rel_q),
      rel_q == 0 ~ "$t=0$",
      TRUE ~ sprintf("$t+%d$", rel_q)
    ),
    stars = ifelse(`Pr(>|t|)` < 0.01, "^{***}",
            ifelse(`Pr(>|t|)` < 0.05, "^{**}",
            ifelse(`Pr(>|t|)` < 0.10, "^{*}", "")))
  )

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Quarterly Triple-Interaction Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter & $\\hat{\\beta}_{3,t}$ & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\[3pt]"
)

for (i in 1:nrow(es_data)) {
  if (es_data$rel_q[i] == 0) {
    tab4_lines <- c(tab4_lines,
      "\\midrule",
      "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\[3pt]"
    )
  }
  tab4_lines <- c(tab4_lines, sprintf(
    "%s & $%.4f%s$ & (%.4f) \\\\",
    es_data$Quarter[i], es_data$Estimate[i], es_data$stars[i], es_data$`Std. Error`[i]
  ))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "Reference & \\multicolumn{2}{c}{$t-1$ (2018Q1)} \\\\",
  "FEs & \\multicolumn{2}{c}{County$\\times$Race, Race$\\times$Qtr} \\\\",
  "Clustering & \\multicolumn{2}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients on the triple interaction (Exposure $\\times$ Black $\\times$ Quarter) from the event study specification. $t=0$ is 2018Q2, the first full quarter after Section 232 tariffs. Reference period is $t-1$ (2018Q1). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

## ========================================================
## Table 5: Robustness
## ========================================================
cat("\n=== Table 5: Robustness ===\n")

r_large <- extract_coef(robustness$m_large, "post_exposure_black")
r_tight <- extract_coef(robustness$m_tight, "post_exposure_black")
r_placebo <- extract_coef(robustness$m_placebo, "post_exposure_black")
r_binary <- extract_coef(robustness$m_binary, "post_high_black")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) Large & (2) Through & (3) Binary & (4) Non-Mfg. \\\\",
  " & Counties & 2019Q4 & Treatment & Placebo \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Exp. $\\times$ Black & $%s$ & $%s$ & $%s$ & $%s$ \\\\",
          r_large$est, r_tight$est, r_binary$est, r_placebo$est),
  sprintf(" & %s & %s & %s & %s \\\\",
          r_large$se, r_tight$se, r_binary$se, r_placebo$se),
  "\\midrule",
  "County $\\times$ Race FE & Yes & Yes & Yes & Yes \\\\",
  "Race $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          n_fmt(robustness$m_large), n_fmt(robustness$m_tight),
          n_fmt(robustness$m_binary), n_fmt(robustness$m_placebo)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications include county$\\times$race and race$\\times$quarter fixed effects with state-clustered standard errors. (1) Restricts to counties with $\\geq$100 manufacturing workers. (2) Drops 2020 observations. (3) Uses binary above/below-median exposure instead of continuous. (4) Placebo using non-manufacturing sectors (wholesale, retail, professional services, accommodation) in the same counties. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5_lines, "../tables/tab5_robust.tex")
cat("Table 5 written.\n")

## ========================================================
## SDE Table (Appendix)
## ========================================================
cat("\n=== SDE Table ===\n")

pre_data <- df %>% filter(post == 0, !is.na(earn), earn > 0)
sd_y_earn <- sd(log(pre_data$earn), na.rm = TRUE)
cat(sprintf("Pre-period SD of log earnings: %.4f\n", sd_y_earn))

emp_pre <- df %>% filter(post == 0, !is.na(emp), emp > 0)
sd_y_emp <- sd(log(emp_pre$emp), na.rm = TRUE)

hire_pre <- df %>% filter(post == 0, !is.na(hires), hires > 0)
sd_y_hires <- sd(log(hire_pre$hires), na.rm = TRUE)

calc_sde <- function(model, var_name, outcome_label, sd_y) {
  ct <- coeftable(model)
  if (!(var_name %in% rownames(ct))) return(NULL)
  beta <- ct[var_name, "Estimate"]
  se <- ct[var_name, "Std. Error"]
  sde <- beta / sd_y
  se_sde <- se / sd_y
  classify <- function(x) {
    if (x > 0.15) return("Large positive")
    if (x > 0.05) return("Moderate positive")
    if (x > 0.005) return("Small positive")
    if (x > -0.005) return("Null")
    if (x > -0.05) return("Small negative")
    if (x > -0.15) return("Moderate negative")
    return("Large negative")
  }
  data.frame(
    Outcome = outcome_label,
    beta = sprintf("%.4f", beta),
    se = sprintf("%.4f", se),
    sd_y = sprintf("%.4f", sd_y),
    sde = sprintf("%.4f", sde),
    se_sde = sprintf("%.4f", se_sde),
    classification = classify(sde)
  )
}

sde_rows <- bind_rows(
  calc_sde(models$m4, "post_exposure_black", "Racial Earnings Gap", sd_y_earn),
  calc_sde(models$m4, "post_exposure", "Overall Earnings (White)", sd_y_earn),
  calc_sde(models$m_emp, "post_exposure_black", "Racial Employment Gap", sd_y_emp),
  calc_sde(models$m_hires, "post_exposure_black", "Racial Hiring Gap", sd_y_hires)
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did Section 232 steel and aluminum tariffs (25\\% and 10\\% ad valorem, effective March 2018) narrow or widen the Black-White earnings, employment, and hiring gaps in manufacturing communities with varying tariff exposure? ",
  "\\textbf{Policy mechanism:} Presidential proclamation imposed tariffs on steel (25\\%) and aluminum (10\\%) imports under national security authority, raising domestic prices of these metals and increasing demand for domestic producers while raising input costs for downstream manufacturing users. ",
  "\\textbf{Outcome definition:} Log average monthly earnings, log beginning-of-quarter employment, and log all hires from the QWI, measuring county-level manufacturing labor market outcomes separately for Black and White workers. ",
  "\\textbf{Treatment:} Continuous --- county-level share of 2016 employment in primary metals (NAICS 331) and fabricated metals (NAICS 332), interacted with post-2018Q2 indicator and Black race indicator. ",
  "\\textbf{Data:} Census QWI Race-Hispanic panel and County Business Patterns 2016, 2015Q1--2020Q1, county-race-quarter level, manufacturing sector (NAICS 31--33). ",
  "\\textbf{Method:} Triple-difference (county $\\times$ tariff exposure $\\times$ race) with county$\\times$race and race$\\times$quarter fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} Manufacturing sector in 2,737 counties with positive manufacturing employment in 2016 CBP; 857 high-exposure and 1,880 low-exposure counties; 313,362 county-race-quarter observations for earnings. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)
for (i in 1:nrow(sde_rows)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se[i],
    sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$classification[i]
  ))
}
sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
