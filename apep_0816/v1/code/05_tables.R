# ==============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_0816
# ==============================================================================

source("00_packages.R")

load("../data/main_models.RData")
load("../data/robustness_models.RData")
panel <- fread("../data/analysis_panel.csv")
tech_share <- fread("../data/tech_share.csv")
ind_het <- fread("../data/industry_heterogeneity.csv")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

naics54 <- panel[industry == "54"]
pre_data <- naics54[yearqtr < 2003.75]

# Panel A: County characteristics
county_summ <- tech_share[, .(
  Variable = c("Tech employment share (\\%)", "Total employment (000s)"),
  Mean = c(sprintf("%.2f", mean(tech_share * 100)),
           sprintf("%.1f", mean(total_emp / 1000))),
  SD = c(sprintf("%.2f", sd(tech_share * 100)),
         sprintf("%.1f", sd(total_emp / 1000))),
  P25 = c(sprintf("%.2f", quantile(tech_share * 100, 0.25)),
          sprintf("%.1f", quantile(total_emp / 1000, 0.25))),
  P75 = c(sprintf("%.2f", quantile(tech_share * 100, 0.75)),
          sprintf("%.1f", quantile(total_emp / 1000, 0.75))),
  N = c(format(.N, big.mark = ","), format(.N, big.mark = ","))
)]

# Panel B: QWI outcomes (pre-period)
young_pre <- pre_data[agegrp == "A04", .(
  emp_mean = mean(Emp, na.rm = TRUE), emp_sd = sd(Emp, na.rm = TRUE),
  hire_mean = mean(HirA, na.rm = TRUE), hire_sd = sd(HirA, na.rm = TRUE),
  earn_mean = mean(EarnS, na.rm = TRUE), earn_sd = sd(EarnS, na.rm = TRUE)
)]

old_pre <- pre_data[agegrp == "A06", .(
  emp_mean = mean(Emp, na.rm = TRUE), emp_sd = sd(Emp, na.rm = TRUE),
  hire_mean = mean(HirA, na.rm = TRUE), hire_sd = sd(HirA, na.rm = TRUE),
  earn_mean = mean(EarnS, na.rm = TRUE), earn_sd = sd(EarnS, na.rm = TRUE)
)]

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Mean & SD & P25 & P75 \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: County Characteristics (2002Q1), N = ",
  format(nrow(tech_share), big.mark = ","), "}} \\\\\n",
  "Tech employment share (\\%) & ", sprintf("%.2f", mean(tech_share$tech_share * 100)),
  " & ", sprintf("%.2f", sd(tech_share$tech_share * 100)),
  " & ", sprintf("%.2f", quantile(tech_share$tech_share * 100, 0.25)),
  " & ", sprintf("%.2f", quantile(tech_share$tech_share * 100, 0.75)), " \\\\\n",
  "Total employment (000s) & ", sprintf("%.1f", mean(tech_share$total_emp / 1000)),
  " & ", sprintf("%.1f", sd(tech_share$total_emp / 1000)),
  " & ", sprintf("%.1f", quantile(tech_share$total_emp / 1000, 0.25)),
  " & ", sprintf("%.1f", quantile(tech_share$total_emp / 1000, 0.75)), " \\\\\n",
  "[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: QWI Outcomes, NAICS 54 (Pre-period 2001--2003)}} \\\\\n",
  "\\multicolumn{5}{l}{\\textit{Workers aged 25--34:}} \\\\\n",
  "Employment & ", sprintf("%.0f", young_pre$emp_mean),
  " & ", sprintf("%.0f", young_pre$emp_sd), " & & \\\\\n",
  "All hires & ", sprintf("%.0f", young_pre$hire_mean),
  " & ", sprintf("%.0f", young_pre$hire_sd), " & & \\\\\n",
  "Avg quarterly earnings (\\$) & ", sprintf("%s", format(round(young_pre$earn_mean), big.mark = ",")),
  " & ", sprintf("%s", format(round(young_pre$earn_sd), big.mark = ",")), " & & \\\\\n",
  "[0.3em]\n",
  "\\multicolumn{5}{l}{\\textit{Workers aged 45--54:}} \\\\\n",
  "Employment & ", sprintf("%.0f", old_pre$emp_mean),
  " & ", sprintf("%.0f", old_pre$emp_sd), " & & \\\\\n",
  "All hires & ", sprintf("%.0f", old_pre$hire_mean),
  " & ", sprintf("%.0f", old_pre$hire_sd), " & & \\\\\n",
  "Avg quarterly earnings (\\$) & ", sprintf("%s", format(round(old_pre$earn_mean), big.mark = ",")),
  " & ", sprintf("%s", format(round(old_pre$earn_sd), big.mark = ",")), " & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A shows county-level characteristics measured in 2002Q1 for ",
  "counties with total employment $\\geq$ 1,000. Tech employment share is the ratio of ",
  "NAICS 51 (Information) plus NAICS 54 (Professional/Technical) employment to total employment. ",
  "Panel B shows pre-treatment means and standard deviations of QWI outcomes in professional and ",
  "technical services (NAICS 54) by age group. Source: Census Quarterly Workforce Indicators (QWI), ",
  "2001--2003.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Written tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main DDD Results
# ==============================================================================

cat("=== Generating Table 2: Main DDD ===\n")

# Extract coefficients for the triple interaction
get_triple <- function(model) {
  ct <- coeftable(model)
  row <- grep("tech_share:young:post", rownames(ct))
  if (length(row) == 0) row <- grep("tech_share.*young.*post", rownames(ct))
  if (length(row) > 0) return(ct[row[1], ]) else return(rep(NA, 4))
}

t2_emp <- get_triple(m1_emp)
t2_hires <- get_triple(m1_hires)
t2_sep <- get_triple(m1_sep)
t2_earn <- get_triple(m1_earn)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Effect of H-1B Restrictions on Native Workers: Triple-Difference Estimates}\n",
  "\\label{tab:main_ddd}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Log Emp & Log Hires & Log Sep & Log Earnings \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "TechShare $\\times$ Young $\\times$ Post & ",
  sprintf("%.4f", t2_emp[1]), stars(t2_emp[4]),
  " & ", sprintf("%.4f", t2_hires[1]), stars(t2_hires[4]),
  " & ", sprintf("%.4f", t2_sep[1]), stars(t2_sep[4]),
  " & ", sprintf("%.4f", t2_earn[1]), stars(t2_earn[4]), " \\\\\n",
  " & (", sprintf("%.4f", t2_emp[2]),
  ") & (", sprintf("%.4f", t2_hires[2]),
  ") & (", sprintf("%.4f", t2_sep[2]),
  ") & (", sprintf("%.4f", t2_earn[2]), ") \\\\\n",
  "[0.5em]\n",
  "County-Industry-Age FE & Yes & Yes & Yes & Yes \\\\\n",
  "State-Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Age-Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(m1_emp), big.mark = ","),
  " & ", format(nobs(m1_hires), big.mark = ","),
  " & ", format(nobs(m1_sep), big.mark = ","),
  " & ", format(nobs(m1_earn), big.mark = ","), " \\\\\n",
  "Clusters (states) & ", uniqueN(panel[industry == "54", fips_state]),
  " & ", uniqueN(panel[industry == "54", fips_state]),
  " & ", uniqueN(panel[industry == "54", fips_state]),
  " & ", uniqueN(panel[industry == "54", fips_state]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the triple-difference estimate ",
  "from $Y_{c,a,t} = \\alpha_{ca} + \\gamma_{st} + \\delta_{at} + \\beta \\cdot ",
  "\\text{TechShare}_c \\times \\text{Young}_a \\times \\text{Post}_t + \\varepsilon_{c,a,t}$, ",
  "where TechShare is the county's 2002Q1 ratio of NAICS 51+54 to total employment, ",
  "Young indicates workers aged 25--34 (vs.\\ 45--54), and Post indicates quarters after 2003Q3 ",
  "(the FY2004 H-1B cap reduction). Sample: NAICS 54 (Professional/Technical Services). ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main_ddd.tex")
cat("  Written tab2_main_ddd.tex\n")

# ==============================================================================
# Table 3: Quarterly Dynamics (Event-Study Coefficients)
# ==============================================================================

cat("=== Generating Table 3: Quarterly Dynamics ===\n")

es_coefs <- fread("../data/event_study_coefs.csv")

# Select key quarters for the table
key_quarters <- c(-8, -4, -1, 0, 1, 2, 4, 8, 12, 15)

# Separate by outcome
es_emp_disp <- es_coefs[outcome == "employment"]
es_earn_disp <- es_coefs[outcome == "earnings"]

# Extract event time
es_emp_disp[, event_q := as.integer(gsub("^et_bin::([-0-9]+):.*$", "\\1", term))]
es_earn_disp[, event_q := as.integer(gsub("^et_bin::([-0-9]+):.*$", "\\1", term))]

# Filter to key quarters
es_emp_disp <- es_emp_disp[event_q %in% key_quarters][order(event_q)]
es_earn_disp <- es_earn_disp[event_q %in% key_quarters][order(event_q)]

# Merge on event_q
es_merged <- merge(es_emp_disp[, .(event_q, emp_est = estimate, emp_se = se)],
                   es_earn_disp[, .(event_q, earn_est = estimate, earn_se = se)],
                   by = "event_q", all = TRUE)
es_merged <- es_merged[order(event_q)]

tab3_rows <- ""
for (r in seq_len(nrow(es_merged))) {
  q <- es_merged[r, event_q]
  label <- ifelse(q < 0, sprintf("$t%d$", q), sprintf("$t+%d$", q))
  if (q == -1) label <- "$t-1$ (ref.)"

  if (q == -1) {
    tab3_rows <- paste0(tab3_rows, label, " & --- & --- \\\\\n")
  } else {
    emp_star <- stars(2 * pt(-abs(es_merged[r, emp_est] / es_merged[r, emp_se]), df = 45))
    earn_star <- stars(2 * pt(-abs(es_merged[r, earn_est] / es_merged[r, earn_se]), df = 45))
    tab3_rows <- paste0(tab3_rows, label,
                        " & ", sprintf("%.4f%s", es_merged[r, emp_est], emp_star),
                        " & ", sprintf("%.4f%s", es_merged[r, earn_est], earn_star),
                        " \\\\\n")
    tab3_rows <- paste0(tab3_rows,
                        " & (", sprintf("%.4f", es_merged[r, emp_se]), ")",
                        " & (", sprintf("%.4f", es_merged[r, earn_se]), ")",
                        " \\\\\n")
  }
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Quarterly Adjustment Dynamics: Event-Study Triple-Difference}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Quarter Relative to Cap Cut & Log Employment & Log Earnings \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\midrule\n",
  "County-Industry-Age FE & Yes & Yes \\\\\n",
  "State-Quarter FE & Yes & Yes \\\\\n",
  "Age-Quarter FE & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(es_emp), big.mark = ","),
  " & ", format(nobs(es_earn), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on ",
  "$\\text{TechShare}_c \\times \\text{Young}_a \\times \\mathbf{1}(t = \\tau)$ ",
  "from the event-study specification. Quarter $t-1$ (2003Q3) is the reference period. ",
  "The cap reduction took effect in 2003Q4 ($t=0$). Estimates trace the quarterly path ",
  "of native professional-services employment in high-tech counties for young (25--34) ",
  "relative to older (45--54) workers. Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event_study.tex")
cat("  Written tab3_event_study.tex\n")

# ==============================================================================
# Table 4: Industry Heterogeneity
# ==============================================================================

cat("=== Generating Table 4: Industry Heterogeneity ===\n")

tab4_rows <- ""
for (r in seq_len(nrow(ind_het))) {
  tab4_rows <- paste0(tab4_rows,
                      ind_het[r, name], " (NAICS ", ind_het[r, industry], ")",
                      " & ", sprintf("%.4f%s", ind_het[r, beta], stars(ind_het[r, pval])),
                      " & (", sprintf("%.4f", ind_het[r, se]), ")",
                      " & ", format(ind_het[r, n_obs], big.mark = ","),
                      " \\\\\n")
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Industry Heterogeneity: Triple-Difference by Sector}\n",
  "\\label{tab:industry}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Industry & TechShare $\\times$ Young $\\times$ Post & (SE) & N \\\\\n",
  "\\midrule\n",
  tab4_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the triple-difference coefficient from the ",
  "baseline specification estimated separately by industry. Professional/Technical ",
  "services (NAICS 54) is the main H-1B-receiving sector; other sectors serve as ",
  "placebo tests. Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_industry.tex")
cat("  Written tab4_industry.tex\n")

# ==============================================================================
# Table 5: Robustness Checks
# ==============================================================================

cat("=== Generating Table 5: Robustness ===\n")

get_triple_rob <- function(model, pattern = "treated:young:post|tech_share:young:post|tech_share.*young.*post") {
  ct <- coeftable(model)
  row <- grep(pattern, rownames(ct))
  if (length(row) > 0) return(ct[row[1], ]) else return(rep(NA, 4))
}

r_main <- get_triple(m1_emp)
r_bin <- get_triple_rob(m_bin)
r_alt <- get_triple_rob(m_alt)
r_nohub <- get_triple_rob(m_nohub)

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Log Employment}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Main & Binary & Alt Age & No Hubs \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "DDD coefficient & ",
  sprintf("%.4f%s", r_main[1], stars(r_main[4])),
  " & ", sprintf("%.4f%s", r_bin[1], stars(r_bin[4])),
  " & ", sprintf("%.4f%s", r_alt[1], stars(r_alt[4])),
  " & ", sprintf("%.4f%s", r_nohub[1], stars(r_nohub[4])), " \\\\\n",
  " & (", sprintf("%.4f", r_main[2]),
  ") & (", sprintf("%.4f", r_bin[2]),
  ") & (", sprintf("%.4f", r_alt[2]),
  ") & (", sprintf("%.4f", r_nohub[2]), ") \\\\\n",
  "[0.5em]\n",
  "Treatment & Continuous & Binary Q4 & Continuous & Continuous \\\\\n",
  "Age comparison & 25--34 vs 45--54 & 25--34 vs 45--54 & 35--44 vs 45--54 & 25--34 vs 45--54 \\\\\n",
  "Sample & Full & Q1 \\& Q4 & Full & No tech hubs \\\\\n",
  "Observations & ", format(nobs(m1_emp), big.mark = ","),
  " & ", format(nobs(m_bin), big.mark = ","),
  " & ", format(nobs(m_alt), big.mark = ","),
  " & ", format(nobs(m_nohub), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) reproduces the main continuous-treatment DDD. ",
  "Column (2) uses a binary indicator comparing top- to bottom-quartile tech-share counties. ",
  "Column (3) replaces the ``young'' group with workers aged 35--44 (partial H-1B substitutes). ",
  "Column (4) drops the five largest tech hubs (Santa Clara CA, King WA, Travis TX, Suffolk MA, ",
  "Fairfax VA). All specifications include county-industry-age, state-quarter, and age-quarter ",
  "fixed effects. Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, "../tables/tab5_robustness.tex")
cat("  Written tab5_robustness.tex\n")

# ==============================================================================
# Appendix Table F1: Standardized Effect Sizes
# ==============================================================================

cat("=== Generating SDE Table ===\n")

sde_rows <- data.table(
  outcome = c("Employment", "All Hires", "Separations", "Quarterly Earnings"),
  beta = c(t2_emp[1], t2_hires[1], t2_sep[1], t2_earn[1]),
  se = c(t2_emp[2], t2_hires[2], t2_sep[2], t2_earn[2]),
  sd_y = c(pre_sd_emp, pre_sd_hires, pre_sd_sep, pre_sd_earn)
)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
# tech_share SD
sd_x <- sd(tech_share$tech_share)
cat(sprintf("SD(TechShare) = %.4f\n", sd_x))

sde_rows[, sde := beta * sd_x / sd_y]
sde_rows[, se_sde := se * sd_x / sd_y]
sde_rows[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# Build LaTeX
sde_body <- ""
for (r in seq_len(nrow(sde_rows))) {
  sde_body <- paste0(sde_body,
                     sde_rows[r, outcome],
                     " & ", sprintf("%.4f", sde_rows[r, beta]),
                     " & ", sprintf("%.4f", sde_rows[r, se]),
                     " & ", sprintf("%.3f", sde_rows[r, sd_y]),
                     " & ", sprintf("%.4f", sde_rows[r, sde]),
                     " & ", sprintf("%.4f", sde_rows[r, se_sde]),
                     " & ", sde_rows[r, classification],
                     " \\\\\n")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does restricting H-1B skilled immigration visas increase native ",
  "professional-services employment, hiring, separations, and earnings for young workers in ",
  "tech-dependent county labor markets? ",
  "\\textbf{Policy mechanism:} The FY2004 H-1B cap reduction (195,000 to 65,000 annual visas) ",
  "mechanically reduced the supply of skilled foreign workers eligible for employer-sponsored ",
  "temporary work authorization in specialty occupations, tightening competition for native ",
  "workers in professional and technical services. ",
  "\\textbf{Outcome definition:} Log county-quarter employment, all hires, separations, and ",
  "average quarterly earnings in NAICS 54 (Professional, Scientific, and Technical Services) ",
  "from the Census Quarterly Workforce Indicators (QWI). ",
  "\\textbf{Treatment:} Continuous; county-level pre-period (2002Q1) share of total employment ",
  "in NAICS 51 (Information) plus NAICS 54 (Professional/Technical), interacted with a ",
  "young-worker indicator (aged 25--34 vs.\\ 45--54). ",
  "\\textbf{Data:} Census QWI, 2001Q1--2012Q4, county-quarter-age cells in NAICS 54; ",
  format(nobs(m1_emp), big.mark = ","), " county-age-quarter observations across ",
  uniqueN(panel[industry == "54", fips_county]), " counties. ",
  "\\textbf{Method:} Triple-difference (county tech intensity $\\times$ young worker $\\times$ post-cap-cut) ",
  "with county-industry-age, state-quarter, and age-quarter fixed effects; standard errors ",
  "clustered at the state level (", uniqueN(panel[industry == "54", fips_state]), " clusters). ",
  "\\textbf{Sample:} Counties with total employment $\\geq$ 1,000 in 2002Q1; restricted to ",
  "NAICS 54 professional services and workers aged 25--34 or 45--54. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county ",
  "standard deviation of tech employment share and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_body,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Written tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
