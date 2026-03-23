# 05_tables.R — Generate all LaTeX tables
# APEP Paper apep_0804: The Caregiving Tax

source("00_packages.R")

cat("=== Generating tables ===\n")

dt <- fread("../data/analysis_data.csv")
dt <- dt[always_treated == 0]

load("../data/main_results.RData")
load("../data/robustness_results.RData")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

# Compute weighted means and SDs
wtd_stats <- function(x, w) {
  w <- w / sum(w, na.rm = TRUE)
  m <- sum(x * w, na.rm = TRUE)
  v <- sum(w * (x - m)^2, na.rm = TRUE)
  c(mean = m, sd = sqrt(v))
}

# All mothers
all_stats <- dt[, .(
  emp_mean = wtd_stats(employed, PWGTP)[1],
  emp_sd = wtd_stats(employed, PWGTP)[2],
  hours_mean = wtd_stats(hours, PWGTP)[1],
  hours_sd = wtd_stats(hours, PWGTP)[2],
  wages_mean = wtd_stats(wages, PWGTP)[1],
  wages_sd = wtd_stats(wages, PWGTP)[2],
  lfp_mean = wtd_stats(in_labor_force, PWGTP)[1],
  lfp_sd = wtd_stats(in_labor_force, PWGTP)[2],
  age_mean = wtd_stats(AGEP, PWGTP)[1],
  college_mean = wtd_stats(college, PWGTP)[1],
  married_mean = wtd_stats(married, PWGTP)[1],
  white_mean = wtd_stats(white, PWGTP)[1],
  n = .N
)]

# By DREM group
drem1_stats <- dt[has_drem_child == 1, .(
  emp_mean = wtd_stats(employed, PWGTP)[1],
  emp_sd = wtd_stats(employed, PWGTP)[2],
  hours_mean = wtd_stats(hours, PWGTP)[1],
  hours_sd = wtd_stats(hours, PWGTP)[2],
  wages_mean = wtd_stats(wages, PWGTP)[1],
  wages_sd = wtd_stats(wages, PWGTP)[2],
  lfp_mean = wtd_stats(in_labor_force, PWGTP)[1],
  lfp_sd = wtd_stats(in_labor_force, PWGTP)[2],
  age_mean = wtd_stats(AGEP, PWGTP)[1],
  college_mean = wtd_stats(college, PWGTP)[1],
  married_mean = wtd_stats(married, PWGTP)[1],
  white_mean = wtd_stats(white, PWGTP)[1],
  n = .N
)]

drem0_stats <- dt[has_drem_child == 0, .(
  emp_mean = wtd_stats(employed, PWGTP)[1],
  emp_sd = wtd_stats(employed, PWGTP)[2],
  hours_mean = wtd_stats(hours, PWGTP)[1],
  hours_sd = wtd_stats(hours, PWGTP)[2],
  wages_mean = wtd_stats(wages, PWGTP)[1],
  wages_sd = wtd_stats(wages, PWGTP)[2],
  lfp_mean = wtd_stats(in_labor_force, PWGTP)[1],
  lfp_sd = wtd_stats(in_labor_force, PWGTP)[2],
  age_mean = wtd_stats(AGEP, PWGTP)[1],
  college_mean = wtd_stats(college, PWGTP)[1],
  married_mean = wtd_stats(married, PWGTP)[1],
  white_mean = wtd_stats(white, PWGTP)[1],
  n = .N
)]

# Store summary stat SDs for SDE computation
emp_sd_all <- all_stats$emp_sd
hours_sd_all <- all_stats$hours_sd

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l ccc ccc ccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{All Mothers} & \\multicolumn{3}{c}{DREM=1 Child} & \\multicolumn{3}{c}{DREM=0 Child} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7} \\cmidrule(lr){8-10}\n",
  " & Mean & SD & N & Mean & SD & N & Mean & SD & N \\\\\n",
  "\\midrule\n",
  sprintf("Employed & %.3f & %.3f & & %.3f & %.3f & & %.3f & %.3f & \\\\\n",
          all_stats$emp_mean, all_stats$emp_sd,
          drem1_stats$emp_mean, drem1_stats$emp_sd,
          drem0_stats$emp_mean, drem0_stats$emp_sd),
  sprintf("Hours/week & %.1f & %.1f & & %.1f & %.1f & & %.1f & %.1f & \\\\\n",
          all_stats$hours_mean, all_stats$hours_sd,
          drem1_stats$hours_mean, drem1_stats$hours_sd,
          drem0_stats$hours_mean, drem0_stats$hours_sd),
  sprintf("Annual wages (\\$) & %s & %s & & %s & %s & & %s & %s & \\\\\n",
          format(round(all_stats$wages_mean), big.mark = ","),
          format(round(all_stats$wages_sd), big.mark = ","),
          format(round(drem1_stats$wages_mean), big.mark = ","),
          format(round(drem1_stats$wages_sd), big.mark = ","),
          format(round(drem0_stats$wages_mean), big.mark = ","),
          format(round(drem0_stats$wages_sd), big.mark = ",")),
  sprintf("In labor force & %.3f & %.3f & & %.3f & %.3f & & %.3f & %.3f & \\\\\n",
          all_stats$lfp_mean, all_stats$lfp_sd,
          drem1_stats$lfp_mean, drem1_stats$lfp_sd,
          drem0_stats$lfp_mean, drem0_stats$lfp_sd),
  sprintf("Age & %.1f & %.1f & & %.1f & %.1f & & %.1f & %.1f & \\\\\n",
          all_stats$age_mean, wtd_stats(dt$AGEP, dt$PWGTP)[2],
          drem1_stats$age_mean, wtd_stats(dt[has_drem_child==1]$AGEP, dt[has_drem_child==1]$PWGTP)[2],
          drem0_stats$age_mean, wtd_stats(dt[has_drem_child==0]$AGEP, dt[has_drem_child==0]$PWGTP)[2]),
  sprintf("College degree & %.3f & & & %.3f & & & %.3f & & \\\\\n",
          all_stats$college_mean, drem1_stats$college_mean, drem0_stats$college_mean),
  sprintf("Married & %.3f & & & %.3f & & & %.3f & & \\\\\n",
          all_stats$married_mean, drem1_stats$married_mean, drem0_stats$married_mean),
  sprintf("White & %.3f & & & %.3f & & & %.3f & & \\\\\n",
          all_stats$white_mean, drem1_stats$white_mean, drem0_stats$white_mean),
  "\\midrule\n",
  sprintf("Observations & & & %s & & & %s & & & %s \\\\\n",
          format(all_stats$n, big.mark = ","),
          format(drem1_stats$n, big.mark = ","),
          format(drem0_stats$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ACS 1-Year PUMS, 2008--2019. Sample: women aged 25--54 who are the reference person or spouse in households with children aged 5--17. DREM=1 indicates the household has at least one child with cognitive difficulty. All statistics weighted using ACS person weights (PWGTP). Wages are nominal annual wages/salary income. Employment defined as ESR $\\in \\{1,2,4,5\\}$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: Main DDD Results
# ============================================================
cat("\n--- Table 2: Main DDD Results ---\n")

get_coef <- function(mod, var = "post_drem") {
  cf <- coef(mod)
  se <- sqrt(diag(vcov(mod)))
  idx <- grep(var, names(cf), fixed = TRUE)
  if (length(idx) == 0) idx <- 1
  list(beta = cf[idx[1]], se = se[idx[1]],
       n = mod$nobs, stars = ifelse(abs(cf[idx[1]]/se[idx[1]]) > 2.576, "***",
                                     ifelse(abs(cf[idx[1]]/se[idx[1]]) > 1.96, "**",
                                            ifelse(abs(cf[idx[1]]/se[idx[1]]) > 1.645, "*", ""))))
}

r1 <- get_coef(ddd_emp)
r2 <- get_coef(ddd_hours)
r3 <- get_coef(ddd_lfp)
r4 <- get_coef(ddd_logwage)
r5 <- get_coef(ddd_emp_cov)

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Autism Insurance Mandates on Maternal Labor Supply}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Employed & Hours/wk & LFP & Log wages & Employed \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ DREM child & %.4f%s & %.3f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          r1$beta, r1$stars, r2$beta, r2$stars, r3$beta, r3$stars,
          r4$beta, r4$stars, r5$beta, r5$stars),
  sprintf(" & (%.4f) & (%.3f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          r1$se, r2$se, r3$se, r4$se, r5$se),
  "\\midrule\n",
  "Individual covariates & No & No & No & No & Yes \\\\\n",
  "State $\\times$ DREM FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year $\\times$ DREM FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","), format(r4$n, big.mark = ","),
          format(r5$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Triple-difference estimates. The coefficient on Post $\\times$ DREM Child captures the differential change in outcomes for mothers of children with cognitive difficulty (DREM=1) relative to mothers of children without cognitive difficulty, in states that adopted autism insurance mandates relative to states that did not. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column (4) conditions on employment. Column (5) adds controls for mother's age (dummies), college degree, marital status, race. ACS person weights used throughout.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("\n--- Table 3: Event Study ---\n")

es_cf <- coef(es_ddd)
es_se <- sqrt(diag(vcov(es_ddd)))

# Parse event study coefficients
es_names <- names(es_cf)
es_tab_rows <- ""
for (i in seq_along(es_cf)) {
  nm <- es_names[i]
  # Extract relative time from coefficient name
  stars <- ifelse(abs(es_cf[i] / es_se[i]) > 2.576, "***",
                  ifelse(abs(es_cf[i] / es_se[i]) > 1.96, "**",
                         ifelse(abs(es_cf[i] / es_se[i]) > 1.645, "*", "")))
  es_tab_rows <- paste0(es_tab_rows,
                         sprintf("%s & %.4f%s & (%.4f) \\\\\n", nm, es_cf[i], stars, es_se[i]))
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: DDD Coefficients by Relative Year}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Relative Year $\\times$ DREM & Coefficient & SE \\\\\n",
  "\\midrule\n",
  es_tab_rows,
  "\\midrule\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n", format(es_ddd$nobs, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study estimates from the triple-difference specification. Each coefficient is the interaction of a relative-year indicator (years since mandate adoption) with the DREM child indicator. Reference period: $t = -1$. Endpoints binned at $\\leq -5$ and $\\geq +5$. Outcome: employment (binary). Includes state $\\times$ DREM, year $\\times$ DREM, and state $\\times$ year fixed effects. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Heterogeneity and Placebo
# ============================================================
cat("\n--- Table 4: Heterogeneity and Placebo ---\n")

r_nc <- get_coef(ddd_noncollege)
r_c <- get_coef(ddd_college)
r_m <- get_coef(ddd_married)
r_um <- get_coef(ddd_unmarried)
r_pl <- get_coef(placebo_dphy, var = "post_dphy")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity and Placebo Tests}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & No college & College & Married & Unmarried & Placebo: DPHY \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Group & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          r_nc$beta, r_nc$stars, r_c$beta, r_c$stars,
          r_m$beta, r_m$stars, r_um$beta, r_um$stars,
          r_pl$beta, r_pl$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          r_nc$se, r_c$se, r_m$se, r_um$se, r_pl$se),
  "\\midrule\n",
  "Triple-diff FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(r_nc$n, big.mark = ","), format(r_c$n, big.mark = ","),
          format(r_m$n, big.mark = ","), format(r_um$n, big.mark = ","),
          format(r_pl$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(4) split the sample by mother's characteristics and report the triple-difference coefficient (Post $\\times$ DREM Child) on employment. Column (5) replaces the DREM indicator with physical disability (DPHY=1) as a placebo: autism mandates target cognitive/behavioral therapy, so mothers of children with only physical disabilities should show no effect. All specifications include state $\\times$ group, year $\\times$ group, and state $\\times$ year fixed effects. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:hetero}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_heterogeneity.tex")
cat("Table 4 written.\n")

# ============================================================
# TABLE 5 (Appendix): CS DiD Results
# ============================================================
cat("\n--- Table 5: Callaway-Sant'Anna Results ---\n")

if (!is.null(cs_result)) {
  cs_simple <- aggte(cs_result, type = "simple")
  cs_att <- cs_simple$overall.att
  cs_se_val <- cs_simple$overall.se

  tab5 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Callaway--Sant'Anna DiD: Mothers of Children with Cognitive Difficulty}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lcc}\n",
    "\\toprule\n",
    " & ATT & SE \\\\\n",
    "\\midrule\n",
    sprintf("Overall ATT (employment) & %.4f & (%.4f) \\\\\n", cs_att, cs_se_val),
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Callaway--Sant'Anna (2021) group-time ATT estimates, aggregated to a single overall ATT. Sample restricted to mothers of children with cognitive difficulty (DREM=1). Treatment groups defined by state mandate adoption year. Control group: never-treated states. Analytical standard errors.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\label{tab:cs}\n",
    "\\end{table}\n"
  )
} else {
  tab5 <- "% CS estimation did not converge — table omitted\n"
}

writeLines(tab5, "../tables/tab5_cs.tex")
cat("Table 5 written.\n")

# ============================================================
# SDE TABLE (Appendix F1) — Standardized Effect Sizes
# ============================================================
cat("\n--- SDE Table ---\n")

# Extract coefficients from main models
beta_emp <- coef(ddd_emp)["post_drem"]
se_emp <- sqrt(diag(vcov(ddd_emp)))["post_drem"]
sd_y_emp <- emp_sd_all  # from summary stats above

beta_hours <- coef(ddd_hours)["post_drem"]
se_hours <- sqrt(diag(vcov(ddd_hours)))["post_drem"]
sd_y_hours <- hours_sd_all

beta_lfp <- coef(ddd_lfp)["post_drem"]
se_lfp <- sqrt(diag(vcov(ddd_lfp)))["post_drem"]
sd_y_lfp <- all_stats$lfp_sd

# Compute SDE
sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp / sd_y_emp

sde_hours <- beta_hours / sd_y_hours
se_sde_hours <- se_hours / sd_y_hours

sde_lfp <- beta_lfp / sd_y_lfp
se_sde_lfp <- se_lfp / sd_y_lfp

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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state autism insurance mandates, which require private insurers to cover behavioral therapies for children with autism spectrum disorder, increase maternal labor force participation and employment? ",
  "\\textbf{Policy mechanism:} State-level mandates require private health insurers to cover diagnosis and treatment of autism spectrum disorder, including applied behavior analysis (ABA), speech therapy, and occupational therapy; by shifting the cost of intensive childhood therapy from families to insurers, mandates reduce the implicit caregiving tax on mothers who would otherwise provide or coordinate care themselves. ",
  "\\textbf{Outcome definition:} Employment is a binary indicator equal to one if the mother reports being employed (at work or with a job but not at work) in the ACS; hours per week is the usual weekly hours worked; labor force participation is a binary indicator for being employed or actively seeking work. ",
  "\\textbf{Treatment:} Binary --- state adopted an autism insurance mandate (staggered across 46 states, 2001--2015). ",
  "\\textbf{Data:} American Community Survey 1-Year PUMS, 2008--2019, individual-level with household linkage; mothers (women aged 25--54, reference person or spouse) in households with children aged 5--17. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ year $\\times$ child-disability-group) with state-group, year-group, and state-year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Mothers aged 25--54 in households with school-age children; excludes states that adopted mandates before the ACS disability module began (2008). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation from the full sample. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("Employment & DDD & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_emp, sd_y_emp, sde_emp, se_sde_emp, classify(sde_emp)),
  sprintf("Hours/week & DDD & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_hours, sd_y_hours, sde_hours, se_sde_hours, classify(sde_hours)),
  sprintf("LFP & DDD & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_lfp, sd_y_lfp, sde_lfp, se_sde_lfp, classify(sde_lfp)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("=== All tables generated ===\n")
