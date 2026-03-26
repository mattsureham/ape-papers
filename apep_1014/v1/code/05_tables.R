# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")
load("../data/models.RData")
load("../data/robustness.RData")

analysis <- arrow::read_parquet("../data/analysis_sample.parquet")
dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

pre_data <- analysis %>%
  filter(year <= 2016, industry == "72") %>%
  group_by(tipped_group) %>%
  summarise(
    States = n_distinct(state_fips),
    bw_mean = mean(bw_ratio, na.rm = TRUE),
    bw_sd = sd(bw_ratio, na.rm = TRUE),
    earn_b = mean(EarnS_Black, na.rm = TRUE),
    earn_w = mean(EarnS_White, na.rm = TRUE),
    hisp_mean = mean(hisp_ratio, na.rm = TRUE),
    emp_b = mean(Emp_Black, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  filter(tipped_group %in% c("OFW", "Reform", "LowTipped")) %>%
  arrange(factor(tipped_group, levels = c("OFW", "Reform", "LowTipped")))

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Food Services (NAICS 72), Pre-Reform 2005--2016}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & States & B-W Ratio & SD & Earn (B) & Earn (W) & Hisp Ratio & Obs \\\\",
  "\\midrule"
)

labels <- c("OFW" = "One Fair Wage", "Reform" = "Reform States", "LowTipped" = "Low-Tipped (\\$2.13)")
for (i in 1:nrow(pre_data)) {
  tab1 <- c(tab1, sprintf(
    "%s & %d & %.3f & %.3f & \\$%s & \\$%s & %.3f & %s \\\\",
    labels[pre_data$tipped_group[i]], pre_data$States[i],
    pre_data$bw_mean[i], pre_data$bw_sd[i],
    format(round(pre_data$earn_b[i]), big.mark = ","),
    format(round(pre_data$earn_w[i]), big.mark = ","),
    pre_data$hisp_mean[i], format(pre_data$n[i], big.mark = ",")))
}

tab1 <- c(tab1, "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} QWI LEHD administrative data, race$\\times$ethnicity by NAICS sector, state-quarter level. One Fair Wage (OFW) states (AK, CA, MN, MT, NV, OR, WA) never allowed a tip credit. Reform states (AZ, DC, MI) enacted tipped minimum wage increases during the sample. Low-Tipped states retain the \\$2.13 federal tipped minimum wage. B-W Ratio = average monthly earnings of Black workers divided by White workers. Hisp Ratio = Hispanic / non-Hispanic earnings. All earnings in current dollars.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# TABLE 2: DD Main Results (Food Services Only)
# ============================================================================

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  ""
}

extract <- function(mod, var) {
  co <- coef(mod)[[var]]
  se <- sqrt(vcov(mod)[[var, var]])
  pv <- pvalue(mod)[[var]]
  list(coef = co, se = se, pval = pv)
}

dd_bw_r <- extract(dd_bw, "treated:post")
dd_ln_bw_r <- extract(dd_ln_bw, "treated:post")
dd_hisp_r <- extract(dd_hisp, "treated:post")
dd_ln_hisp_r <- extract(dd_ln_hisp, "treated:post")

tab2 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{The Tipping Penalty: Difference-in-Differences in Food Services}",
  "\\label{tab:dd}", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & \\multicolumn{2}{c}{Black-White Gap} & \\multicolumn{2}{c}{Hispanic Gap} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & B-W Ratio & Log Gap & Hisp Ratio & Log Gap \\\\",
  " & (1) & (2) & (3) & (4) \\\\", "\\midrule",
  sprintf("Reform $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          dd_bw_r$coef, stars(dd_bw_r$pval), dd_ln_bw_r$coef, stars(dd_ln_bw_r$pval),
          dd_hisp_r$coef, stars(dd_hisp_r$pval), dd_ln_hisp_r$coef, stars(dd_ln_hisp_r$pval)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          dd_bw_r$se, dd_ln_bw_r$se, dd_hisp_r$se, dd_ln_hisp_r$se),
  "\\midrule",
  sprintf("State FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year-Quarter FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\", format(nobs(dd_bw), big.mark = ",")),
  sprintf("Clusters (states) & \\multicolumn{4}{c}{%d} \\\\", n_distinct(dd_food$state_fips)),
  sprintf("Pre-reform mean (control) & %.3f & --- & %.3f & --- \\\\",
          mean(dd_food$bw_ratio[dd_food$treated == 0 & dd_food$year < 2017], na.rm = TRUE),
          mean(dd_food$hisp_ratio[dd_food$treated == 0 & dd_food$year < 2017], na.rm = TRUE)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Difference-in-differences estimates for food services (NAICS 72) only. Reform states (AZ from 2017, DC from 2023, MI from 2024) vs.\\ 27 low-tipped states retaining the \\$2.13 federal floor. B-W Ratio = Black/White average monthly earnings. Log Gap = ln(Black earnings) $-$ ln(White earnings). Standard errors clustered by state in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab2, "../tables/tab2_dd.tex")

# ============================================================================
# TABLE 3: DDD with Retail Control
# ============================================================================

ddd_bw_r <- extract(ddd_bw, "treat_ddd")
ddd_state_r <- extract(ddd_bw, "treated_state:post")
ddd_hisp_r <- extract(ddd_hisp, "treat_ddd")
ddd_hisp_state_r <- extract(ddd_hisp, "treated_state:post")

tab3 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Triple-Difference: Within-State Industry Control}",
  "\\label{tab:ddd}", "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}", "\\toprule",
  " & B-W Ratio & Hisp Ratio \\\\",
  " & (1) & (2) \\\\", "\\midrule",
  sprintf("Reform $\\times$ Food Svc $\\times$ Post & %.4f%s & %.4f%s \\\\",
          ddd_bw_r$coef, stars(ddd_bw_r$pval), ddd_hisp_r$coef, stars(ddd_hisp_r$pval)),
  sprintf(" & (%.4f) & (%.4f) \\\\", ddd_bw_r$se, ddd_hisp_r$se),
  "[0.5em]",
  sprintf("Reform $\\times$ Post & %.4f%s & %.4f%s \\\\",
          ddd_state_r$coef, stars(ddd_state_r$pval), ddd_hisp_state_r$coef, stars(ddd_hisp_state_r$pval)),
  sprintf(" & (%.4f) & (%.4f) \\\\", ddd_state_r$se, ddd_hisp_state_r$se),
  "\\midrule",
  "State, Industry, Year-Quarter FE & Yes & Yes \\\\",
  sprintf("Observations & %s & %s \\\\", format(nobs(ddd_bw), big.mark = ","), format(nobs(ddd_hisp), big.mark = ",")),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Triple-difference comparing food services (NAICS 72) vs.\\ retail (NAICS 44--45) in reform vs.\\ control states, before and after reform. The triple interaction captures the food-services-specific effect beyond any general reform impact. Reform $\\times$ Post captures the common effect across both industries. Standard errors clustered by state. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab3, "../tables/tab3_ddd.tex")

# ============================================================================
# TABLE 4: Robustness & Placebos
# ============================================================================

ph_r <- extract(placebo_health_reg, "reform_state:post")
pp_r <- extract(placebo_prof_reg, "reform_state:post")

# Employment
emp_b_r <- extract(emp_did_black, "treated:post")
emp_h_r <- extract(emp_did_hisp, "treated:post")

tab4 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Robustness Checks, Placebos, and Employment Effects}",
  "\\label{tab:robustness}", "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}", "\\toprule",
  " & Coefficient & SE & $p$-value \\\\", "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Placebo Industries (B-W ratio, AZ DiD)}} \\\\",
  sprintf("\\quad Healthcare (NAICS 62) & %.4f & (%.4f) & %.3f \\\\", ph_r$coef, ph_r$se, ph_r$pval),
  sprintf("\\quad Professional Services (NAICS 54) & %.4f & (%.4f) & %.3f \\\\", pp_r$coef, pp_r$se, pp_r$pval),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Leave-One-Out (DDD, B-W ratio)}} \\\\"
)

state_names <- c("04" = "Arizona", "11" = "DC", "26" = "Michigan")
for (st in names(robustness$loo)) {
  r <- robustness$loo[[st]]
  tab4 <- c(tab4, sprintf("\\quad Drop %s & %.4f & (%.4f) & %.3f \\\\",
                           state_names[st], r$coef, r$se, r$pval))
}

tab4 <- c(tab4, "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Employment Effects (log, AZ food services)}} \\\\",
  sprintf("\\quad Black employment & %.4f%s & (%.4f) & %.4f \\\\",
          emp_b_r$coef, stars(emp_b_r$pval), emp_b_r$se, emp_b_r$pval),
  sprintf("\\quad Hispanic employment & %.4f%s & (%.4f) & %.4f \\\\",
          emp_h_r$coef, stars(emp_h_r$pval), emp_h_r$se, emp_h_r$pval),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel D: OFW Cross-Section}} \\\\",
  sprintf("\\quad OFW vs.\\ Low-Tipped (B-W ratio) & %.4f%s & (%.4f) & %.3f \\\\",
          coef(ofw_cross)[[1]], stars(pvalue(ofw_cross)[[1]]),
          sqrt(vcov(ofw_cross)[[1,1]]), pvalue(ofw_cross)[[1]]),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A: DiD on placebo industries with no tipping; a null confirms food-services specificity. Panel B: DDD dropping each reform state in turn. Panel C: DiD on log minority employment in food services (AZ vs.\\ low-tipped). Panel D: cross-sectional comparison of One Fair Wage states (never allowed tip credit) vs.\\ low-tipped states, with year and quarter FEs. All standard errors clustered by state.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================================
# TABLE 5: Event Study Coefficients
# ============================================================================

es_coefs <- coef(es_az_level)
es_ses <- sqrt(diag(vcov(es_az_level)))

tab5 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Arizona Proposition 206: Event-Study Estimates for B-W Earnings Ratio}",
  "\\label{tab:event_study}", "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}", "\\toprule",
  "Years Relative to Reform & Coefficient & Std.\\ Error \\\\", "\\midrule")

for (i in seq_along(es_coefs)) {
  nm <- names(es_coefs)[i]
  # Extract the relative year number
  yr_num <- as.integer(gsub("year::", "", nm))
  pv <- 2 * pnorm(-abs(es_coefs[i] / es_ses[i]))
  label <- ifelse(yr_num < 0, sprintf("$t%d$", yr_num), sprintf("$t+%d$", yr_num))
  tab5 <- c(tab5, sprintf("%s & %.4f%s & (%.4f) \\\\", label, es_coefs[i], stars(pv), es_ses[i]))
}

tab5 <- c(tab5, "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nobs(es_az_level), big.mark = ",")),
  "State \\& Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted estimator. Dependent variable: Black-White average monthly earnings ratio in food services (NAICS 72). Annual data (Q1 only). Arizona treated in 2017; control group is 27 never-treated low-tipped states. Standard errors clustered by state. Base period is $t-1$ (2016). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab5, "../tables/tab5_event_study.tex")

# ============================================================================
# SDE TABLE (Appendix)
# ============================================================================

# Pre-treatment SDs
pre_sd_bw <- sd(dd_food$bw_ratio[dd_food$year < 2017 & dd_food$treated == 0], na.rm = TRUE)
pre_sd_hisp <- sd(dd_food$hisp_ratio[dd_food$year < 2017 & dd_food$treated == 0], na.rm = TRUE)
pre_sd_emp_b <- sd(log(analysis$Emp_Black[analysis$year < 2017 & analysis$industry == "72" &
                                              analysis$tipped_group == "LowTipped"]), na.rm = TRUE)

# Panel A: Pooled
dd_bw_ext <- extract(dd_bw, "treated:post")
dd_hisp_ext <- extract(dd_hisp, "treated:post")

sde_bw <- dd_bw_ext$coef / pre_sd_bw
sde_bw_se <- dd_bw_ext$se / pre_sd_bw
sde_hisp <- dd_hisp_ext$coef / pre_sd_hisp
sde_hisp_se <- dd_hisp_ext$se / pre_sd_hisp

classify <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  "Large positive"
}

# Panel B: AZ only
az_food <- dd_food %>%
  filter(state_fips == "04" | treated == 0) %>%
  mutate(az_treat = as.integer(state_fips == "04"),
         az_post = as.integer(year >= 2017))
az_dd <- feols(bw_ratio ~ az_treat:az_post | state_fips + yearq,
               data = az_food, cluster = ~state_fips)
az_coef <- coef(az_dd)[["az_treat:az_post"]]
az_se <- sqrt(vcov(az_dd)[["az_treat:az_post", "az_treat:az_post"]])
sde_az <- az_coef / pre_sd_bw
sde_az_se <- az_se / pre_sd_bw

# Employment SDE
emp_b_ext <- extract(emp_did_black, "treated:post")
sde_emp <- emp_b_ext$coef / pre_sd_emp_b
sde_emp_se <- emp_b_ext$se / pre_sd_emp_b

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does eliminating the tipped subminimum wage reduce the Black-White earnings gap in accommodation and food services? ",
  "\\textbf{Policy mechanism:} The Fair Labor Standards Act permits employers to pay tipped workers as little as \\$2.13/hr, crediting customer tips toward the minimum wage obligation; One Fair Wage reforms eliminate this tip credit and require employers to pay the full state minimum wage as a base floor regardless of tip income, raising the guaranteed compensation floor for tipped workers. ",
  "\\textbf{Outcome definition:} Ratio of average monthly earnings of Black workers to White workers in NAICS 72 (Accommodation and Food Services), constructed from Quarterly Workforce Indicators (QWI) administrative earnings records. ",
  "\\textbf{Treatment:} Binary; state-level tipped minimum wage reform (Arizona Proposition 206 effective January 2017, DC Initiative 82 effective May 2023, Michigan court ruling effective February 2024). ",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI) from the Longitudinal Employer-Household Dynamics (LEHD) program, race/ethnicity by NAICS sector, state-quarter panels, 2005--2024, ",
  format(nobs(dd_bw), big.mark = ","), " state-quarter observations in the food services sample. ",
  "\\textbf{Method:} Difference-in-differences comparing reform states to 27 low-tipped states retaining the \\$2.13 federal floor, with state and year-quarter fixed effects; standard errors clustered by state. ",
  "\\textbf{Sample:} Reform states (AZ, DC, MI) vs.\\ 27 states with tipped minimum wage at or near the \\$2.13 federal floor; restricted to NAICS 72 (Accommodation and Food Services) for the primary specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome in the control group. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("B-W earnings ratio & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          dd_bw_ext$coef, dd_bw_ext$se, pre_sd_bw, sde_bw, sde_bw_se, classify(sde_bw)),
  sprintf("Hisp-NonHisp ratio & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          dd_hisp_ext$coef, dd_hisp_ext$se, pre_sd_hisp, sde_hisp, sde_hisp_se, classify(sde_hisp)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("B-W ratio: AZ only & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          az_coef, az_se, pre_sd_bw, sde_az, sde_az_se, classify(sde_az)),
  sprintf("Black employment (log) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          emp_b_ext$coef, emp_b_ext$se, pre_sd_emp_b, sde_emp, sde_emp_se, classify(sde_emp)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("All tables generated:\n")
for (f in list.files("../tables", pattern = "\\.tex$")) cat("  ", f, "\n")

# Save key numbers for paper macros
table_data <- list(
  dd_bw_coef = dd_bw_ext$coef,
  dd_bw_se = dd_bw_ext$se,
  dd_bw_pval = dd_bw_ext$pval,
  dd_hisp_coef = dd_hisp_ext$coef,
  dd_hisp_se = dd_hisp_ext$se,
  ddd_bw_coef = ddd_bw_r$coef,
  ddd_state_coef = ddd_state_r$coef,
  ofw_gap = coef(ofw_cross)[[1]],
  emp_black_coef = emp_b_ext$coef,
  emp_hisp_coef = emp_h_r$coef,
  sde_bw = sde_bw,
  sde_class = classify(sde_bw),
  pre_sd_bw = pre_sd_bw,
  n_obs = nobs(dd_bw),
  n_states = n_distinct(dd_food$state_fips)
)
jsonlite::write_json(table_data, "../data/table_data.json", auto_unbox = TRUE)
