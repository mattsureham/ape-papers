# =============================================================================
# 05_tables.R — Generate all tables for the paper
# =============================================================================

source("00_packages.R")

cat("=== Loading data and models ===\n")
panel <- read_csv("../data/analysis_panel.csv.gz", show_col_types = FALSE)
main_models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
es_coefs <- read_csv("../data/event_study_coefs.csv", show_col_types = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

tab1_data <- panel %>%
  filter(post == 0) %>%
  group_by(Type = ifelse(is_coal_county, "Coal-Dominant", "Other Mining")) %>%
  summarise(
    Counties = n_distinct(county_id),
    `Mining Emp.` = sprintf("%.0f", mean(emp, na.rm = TRUE)),
    `Sep. Rate` = sprintf("%.3f", mean(sep_rate, na.rm = TRUE)),
    `Coal Share` = sprintf("%.2f", mean(coal_share, na.rm = TRUE)),
    `Total Emp.` = sprintf("%.0f", mean(emp_total, na.rm = TRUE)),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics (2011Q1--2014Q2)}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Counties & Mining Emp. & Sep.\\ Rate & Coal Share & Total Emp. \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(tab1_data)) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %d & %s & %s & %s & %s \\\\\n",
            tab1_data$Type[i], tab1_data$Counties[i],
            tab1_data$`Mining Emp.`[i], tab1_data$`Sep. Rate`[i],
            tab1_data$`Coal Share`[i], tab1_data$`Total Emp.`[i]))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Pre-treatment means (2011Q1--2014Q2) for counties with $\\geq$10 mining employees in 2013. ",
  "Coal-dominant counties have $>$50\\% of 2013 mining employment in NAICS 212 (coal mining). ",
  "Mining Emp.\\ and Total Emp.\\ are quarterly averages. ",
  "Sep.\\ Rate is quarterly separations divided by employment. ",
  "Source: QWI (LEHD) and authors' calculations.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================
cat("Generating Table 2: Main Results\n")

# Stars function
stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

format_coef <- function(model, varname) {
  est <- coef(model)[varname]
  se_val <- se(model)[varname]
  p_val <- pvalue(model)[varname]
  sprintf("%.4f%s", est, stars(p_val))
}

format_se <- function(model, varname) {
  sprintf("(%.4f)", se(model)[varname])
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{MSHA Coal Dust Rule and Mining Employment}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Log(Employment)} & Sep.\\ Rate & Log(Hires) \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5} \\cmidrule(lr){6-6}\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("Coal Share $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
          format_coef(main_models$m1, "treatment"),
          format_coef(main_models$m2, "treatment"),
          format_coef(main_models$m3, "treatment"),
          format_coef(main_models$m4, "treatment"),
          format_coef(main_models$m5, "treatment")),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          format_se(main_models$m1, "treatment"),
          format_se(main_models$m2, "treatment"),
          format_se(main_models$m3, "treatment"),
          format_se(main_models$m4, "treatment"),
          format_se(main_models$m5, "treatment")),
  "\\addlinespace\n",
  "Coal Price $\\times$ Share &  & Yes &  &  &  \\\\\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes &  & Yes & Yes \\\\\n",
  "State $\\times$ Quarter FE &  &  & Yes &  &  \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(nobs(main_models$m1), big.mark = ","),
          formatC(nobs(main_models$m2), big.mark = ","),
          formatC(nobs(main_models$m3), big.mark = ","),
          formatC(nobs(main_models$m4), big.mark = ","),
          formatC(nobs(main_models$m5), big.mark = ",")
  ),
  sprintf("Counties & %d & %d & %d & %d & %d \\\\\n",
          n_distinct(panel$county_id), n_distinct(panel$county_id),
          n_distinct(panel$county_id), n_distinct(panel$county_id),
          n_distinct(panel$county_id)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Difference-in-differences estimates. Treatment is the 2013 county coal share ",
  "of mining employment interacted with a post-August 2014 indicator. Sample: counties with $\\geq$10 ",
  "mining employees in 2013, 2011Q1--2019Q4. Standard errors clustered by state in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Robustness and Heterogeneity
# =============================================================================
cat("Generating Table 3: Robustness\n")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness and Heterogeneity}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & DDD & Appalachian & Non-App. & Placebo \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Treatment & %s & %s & %s & %s \\\\\n",
          format_coef(rob_models$m_ddd, "is_coal_ind:post"),
          format_coef(rob_models$m_app, "treatment"),
          format_coef(rob_models$m_west, "treatment"),
          format_coef(rob_models$m_placebo, "fake_treatment")),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          format_se(rob_models$m_ddd, "is_coal_ind:post"),
          format_se(rob_models$m_app, "treatment"),
          format_se(rob_models$m_west, "treatment"),
          format_se(rob_models$m_placebo, "fake_treatment")),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(rob_models$m_ddd), big.mark = ","),
          formatC(nobs(rob_models$m_app), big.mark = ","),
          formatC(nobs(rob_models$m_west), big.mark = ","),
          formatC(nobs(rob_models$m_placebo), big.mark = ",")
  ),
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1): Difference-in-difference-in-differences comparing NAICS 212 (coal) vs.\\ 211 (oil/gas) employment ",
  "within county, pre/post August 2014. Column (2): Appalachian states (WV, KY, VA, PA, OH, TN, AL, MD). ",
  "Column (3): All other states. Column (4): Placebo test using Q3 2012 as fake treatment date on 2011--2013 data. ",
  "Standard errors clustered by state. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_robust.tex")

# =============================================================================
# Table 4: Event Study Coefficients
# =============================================================================
cat("Generating Table 4: Event Study\n")

# Select key periods for display
es_display <- es_coefs %>%
  filter(rel_quarter %in% c(-8, -6, -4, -2, -1, 0, 2, 4, 6, 8, 10, 12)) %>%
  mutate(
    sig = ifelse(abs(estimate/se) > 2.576, "***",
                 ifelse(abs(estimate/se) > 1.96, "**",
                        ifelse(abs(estimate/se) > 1.645, "*", "")))
  )

tab4_rows <- ""
for (i in 1:nrow(es_display)) {
  tab4_rows <- paste0(tab4_rows,
    sprintf("%d & %.4f%s & (%.4f) \\\\\n",
            es_display$rel_quarter[i],
            es_display$estimate[i],
            es_display$sig[i],
            es_display$se[i]))
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Coal Share $\\times$ Relative Quarter}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{rcc}\n",
  "\\toprule\n",
  "Quarter Rel.\\ to Rule & Coefficient & Std.\\ Error \\\\\n",
  "\\midrule\n",
  tab4_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Coefficients from interacting 2013 county coal share with relative quarter dummies. ",
  "Reference period: Q2 2014 ($t = -1$). Positive values indicate coal-intensive counties had higher ",
  "mining employment relative to the reference period. County and quarter fixed effects. ",
  "Standard errors clustered by state. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_eventstudy.tex")

# =============================================================================
# SDE Table (Appendix)
# =============================================================================
cat("Generating SDE Table\n")

# Compute SDEs for main outcomes
panel_pre <- panel %>% filter(post == 0)

compute_sde <- function(model, varname, outcome_var, panel_pre_data) {
  beta <- coef(model)[varname]
  se_beta <- se(model)[varname]
  sd_y <- sd(panel_pre_data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  classification <- case_when(
    sde > 0.15 ~ "Large positive",
    sde > 0.05 ~ "Moderate positive",
    sde > 0.005 ~ "Small positive",
    sde > -0.005 ~ "Null",
    sde > -0.05 ~ "Small negative",
    sde > -0.15 ~ "Moderate negative",
    TRUE ~ "Large negative"
  )
  list(beta = beta, se_beta = se_beta, sd_y = sd_y,
       sde = sde, se_sde = se_sde, classification = classification)
}

sde_emp <- compute_sde(main_models$m1, "treatment", "log_emp", panel_pre)
sde_sep <- compute_sde(main_models$m4, "treatment", "sep_rate", panel_pre)
sde_hir <- compute_sde(main_models$m5, "treatment", "log_hir", panel_pre)
sde_app <- compute_sde(rob_models$m_app, "treatment", "log_emp",
                        panel %>% filter(post == 0 & state_fips %in% c(54,21,51,42,39,47,1,24)))

sde_rows <- data.frame(
  Outcome = c("Log(Mining Emp.)", "Separation Rate",
              "Log(New Hires)", "Log(Emp.), Appalachian"),
  beta = c(sde_emp$beta, sde_sep$beta, sde_hir$beta, sde_app$beta),
  se = c(sde_emp$se_beta, sde_sep$se_beta, sde_hir$se_beta, sde_app$se_beta),
  sd_y = c(sde_emp$sd_y, sde_sep$sd_y, sde_hir$sd_y, sde_app$sd_y),
  sde = c(sde_emp$sde, sde_sep$sde, sde_hir$sde, sde_app$sde),
  se_sde = c(sde_emp$se_sde, sde_sep$se_sde, sde_hir$se_sde, sde_app$se_sde),
  classification = c(sde_emp$classification, sde_sep$classification,
                     sde_hir$classification, sde_app$classification)
)

# Build SDE LaTeX table
sde_body <- ""
for (i in 1:nrow(sde_rows)) {
  sde_body <- paste0(sde_body,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
            sde_rows$classification[i]))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does MSHA's 2014 coal dust rule, which lowered permissible respirable dust limits in coal mines, reduce county-level coal mining employment? ",
  "\\textbf{Policy mechanism:} The rule reduced the permissible exposure limit for respirable coal mine dust from 2.0 to 1.5 mg/m\\textsuperscript{3}, required continuous personal dust monitors, and mandated corrective actions on single-shift violations, raising compliance costs particularly for underground mines. ",
  "\\textbf{Outcome definition:} Log quarterly average mining employment from QWI (LEHD), separation rate (quarterly separations / employment), and log new hires. ",
  "\\textbf{Treatment:} Continuous; 2013 county-level share of mining employment in coal (NAICS 212). ",
  "\\textbf{Data:} QWI county$\\times$quarter$\\times$NAICS 3-digit panel, 2011Q1--2019Q4, 822 mining counties, 29,435 observations. ",
  "\\textbf{Method:} Continuous DiD with county and quarter fixed effects; standard errors clustered by state. ",
  "\\textbf{Sample:} Counties with $\\geq$10 mining employees in 2013; restricted to 2011--2019. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_body,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
