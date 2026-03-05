## 06_tables.R — Generate LaTeX tables from saved data
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

df <- fread(file.path(data_dir, "analysis_aggregate.csv"))
df_ind <- fread(file.path(data_dir, "analysis_industry.csv"))
results <- fread(file.path(data_dir, "main_results.csv"))

# Re-estimate regressions so data environments are available for etable
twfe_hir <- feols(log_ratio_hir ~ post | state + period, data = df, cluster = ~state)
twfe_s <- feols(log_ratio_s ~ post | state + period, data = df, cluster = ~state)
twfe_beg <- feols(log_ratio_beg ~ post | state + period, data = df, cluster = ~state)

# DDD
ddd_data <- rbindlist(list(
  df[, .(state, period, treated, post, cohort, ban_period,
         log_ratio = log_ratio_hir, worker_type = "new_hire",
         year, qtr, total_emp)],
  df[, .(state, period, treated, post, cohort, ban_period,
         log_ratio = log_ratio_s, worker_type = "continuing",
         year, qtr, total_emp)]
))
ddd_data[, new_hire := as.integer(worker_type == "new_hire")]
ddd_reg <- feols(log_ratio ~ post * new_hire | state + period + new_hire:period + new_hire:state,
                 data = ddd_data, cluster = ~state)

# Decomposition
twfe_female_hir <- feols(log_earn_f_hir ~ post | state + period, data = df, cluster = ~state)
twfe_male_hir <- feols(log_earn_m_hir ~ post | state + period, data = df, cluster = ~state)
twfe_hire_share <- feols(female_hire_share ~ post | state + period, data = df, cluster = ~state)

# Industry heterogeneity
ind_male_dom <- feols(log_ratio_hir ~ post | state + period, data = df_ind[male_dominated == TRUE], cluster = ~state)
ind_female_dom <- feols(log_ratio_hir ~ post | state + period, data = df_ind[female_dominated == TRUE], cluster = ~state)
ind_high_wage <- feols(log_ratio_hir ~ post | state + period, data = df_ind[high_wage == TRUE], cluster = ~state)

# Exclude bundled
bundled_states <- c("08", "06", "53")
twfe_nobundle <- feols(log_ratio_hir ~ post | state + period, data = df[!state %in% bundled_states], cluster = ~state)

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("Table 1: Summary Statistics\n")

# Pre-treatment means by group
pre <- df[post == 0 | treated == FALSE]
treat_pre <- pre[treated == TRUE]
ctrl_pre <- pre[treated == FALSE]

sum_stats <- data.table(
  Variable = c("Female/Male Earnings (New Hires)",
               "Female/Male Earnings (Continuing)",
               "Female/Male Earnings (All Workers)",
               "Female Share of New Hires",
               "Female Share of Employment",
               "Total Employment (millions)",
               "New Hires per Quarter",
               "State-Quarter Observations"),
  `Ban States` = c(
    sprintf("%.3f", mean(treat_pre$earn_ratio_hir, na.rm = TRUE)),
    sprintf("%.3f", mean(treat_pre$earn_ratio_s, na.rm = TRUE)),
    sprintf("%.3f", mean(treat_pre$earn_ratio_beg, na.rm = TRUE)),
    sprintf("%.3f", mean(treat_pre$female_hire_share, na.rm = TRUE)),
    sprintf("%.3f", mean(treat_pre$female_emp_share, na.rm = TRUE)),
    sprintf("%.2f", mean(treat_pre$total_emp, na.rm = TRUE) / 1e6),
    sprintf("%.0f", mean(treat_pre$HirN_sex1 + treat_pre$HirN_sex2, na.rm = TRUE)),
    format(nrow(treat_pre), big.mark = ",")
  ),
  `Non-Ban States` = c(
    sprintf("%.3f", mean(ctrl_pre$earn_ratio_hir, na.rm = TRUE)),
    sprintf("%.3f", mean(ctrl_pre$earn_ratio_s, na.rm = TRUE)),
    sprintf("%.3f", mean(ctrl_pre$earn_ratio_beg, na.rm = TRUE)),
    sprintf("%.3f", mean(ctrl_pre$female_hire_share, na.rm = TRUE)),
    sprintf("%.3f", mean(ctrl_pre$female_emp_share, na.rm = TRUE)),
    sprintf("%.2f", mean(ctrl_pre$total_emp, na.rm = TRUE) / 1e6),
    sprintf("%.0f", mean(ctrl_pre$HirN_sex1 + ctrl_pre$HirN_sex2, na.rm = TRUE)),
    format(nrow(ctrl_pre), big.mark = ",")
  )
)

# Write LaTeX
tex1 <- kable(sum_stats, format = "latex", booktabs = TRUE,
              caption = "Summary Statistics: Pre-Treatment Means",
              label = "sumstats",
              align = c("l", "c", "c")) |>
  kable_styling(latex_options = c("hold_position")) |>
  add_header_above(c(" " = 1, "Mean" = 2)) |>
  footnote(general = "Pre-treatment period defined as all quarters before the first salary history ban took effect in that state. Non-ban states use the full sample period. Employment and earnings from QWI (universe of UI-covered employment).",
           general_title = "Notes:", footnote_as_chunk = TRUE, threeparttable = TRUE)

writeLines(tex1, file.path(tab_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results
# ============================================================

cat("Table 2: Main Results\n")

# Use etable from fixest for nice LaTeX output
etable(twfe_hir, twfe_s, twfe_beg, ddd_reg,
       headers = c("New Hires", "Continuing", "All Workers", "DDD"),
       se.below = TRUE,
       se = "cluster",
       keep = c("%post"),
       dict = c(post = "Ban Effective", "post:new_hire" = "Ban $\\times$ New Hire",
                log_ratio_hir = "Log Ratio (New Hires)",
                log_ratio_s = "Log Ratio (Continuing)",
                log_ratio_beg = "Log Ratio (All Workers)",
                log_ratio = "Log Gender Ratio"),
       fitstat = c("n", "r2", "ar2"),
       title = "Effect of Salary History Bans on Gender Earnings Ratio",
       label = "tab:main",
       notes = "Dependent variable: log(Female earnings / Male earnings). Columns (1)--(3) report TWFE DiD. Column (4) reports DDD stacking new hire and continuing worker outcomes. All regressions include state and quarter fixed effects. Standard errors clustered by state in parentheses.",
       tex = TRUE,
       file = file.path(tab_dir, "tab2_main_results.tex"),
       replace = TRUE)

cat("  Saved tab2_main_results.tex\n")

# ============================================================
# Table 3: CS-DiD Results
# ============================================================

cat("Table 3: CS-DiD Results\n")

cs_results <- results[model %like% "CS-DiD"]
cs_results[, star_str := ifelse(is.na(stars) | stars == "", "", as.character(stars))]
cs_results[, N := nrow(df)]  # Same panel used for CS-DiD
cs_tex <- kable(cs_results[, .(Model = model,
                                Coefficient = paste0(sprintf("%.4f", coef), star_str),
                                SE = sprintf("(%.4f)", se),
                                Observations = format(N, big.mark = ","))],
                format = "latex", booktabs = TRUE,
                caption = "Callaway-Sant'Anna Group-Time ATT Estimates",
                label = "csatt",
                escape = FALSE) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Simple ATT aggregated across all group-time cells. Conservative standard errors computed as root-mean-square of group-time cell-level bootstrap SEs (1,000 iterations). N is the number of state-quarter observations in the estimation sample.",
           general_title = "Notes:", footnote_as_chunk = TRUE, threeparttable = TRUE)

writeLines(cs_tex, file.path(tab_dir, "tab3_csatt.tex"))
cat("  Saved tab3_csatt.tex\n")

# ============================================================
# Table 4: Robustness Checks
# ============================================================

cat("Table 4: Robustness\n")

rob <- fread(file.path(data_dir, "robustness_results.csv"))
rob[, Coefficient := sprintf("%.4f", coef)]
rob[!is.na(se), SE := sprintf("(%.4f)", se)]
rob[is.na(se), SE := ""]
rob[!is.na(n), N := format(as.integer(n), big.mark = ",")]
rob[is.na(n), N := ""]

rob_tex <- kable(rob[, .(Test = test, Coefficient, SE, N)],
                 format = "latex", booktabs = TRUE,
                 caption = "Robustness Checks",
                 label = "robustness",
                 escape = FALSE) |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "All regressions include state and quarter FE. Standard errors clustered by state. RI p-value from 500 permutations of treatment assignment. N is the number of state-quarter (or state-quarter-industry) observations.",
           general_title = "Notes:", footnote_as_chunk = TRUE, threeparttable = TRUE)

writeLines(rob_tex, file.path(tab_dir, "tab4_robustness.tex"))
cat("  Saved tab4_robustness.tex\n")

# ============================================================
# Table 5: Male vs Female Earnings Decomposition
# ============================================================

cat("Table 5: Gender Decomposition\n")

etable(twfe_female_hir, twfe_male_hir, twfe_hire_share,
       headers = c("Female Earn (New Hire)", "Male Earn (New Hire)", "Female Hire Share"),
       se.below = TRUE,
       se = "cluster",
       keep = "%post",
       dict = c(post = "Ban Effective",
                log_earn_f_hir = "Log Female Earnings",
                log_earn_m_hir = "Log Male Earnings",
                female_hire_share = "Female Hire Share"),
       fitstat = c("n", "r2"),
       title = "Decomposition: Female vs.~Male New Hire Earnings and Hiring Composition",
       label = "tab:decomp",
       notes = "Column (1): log female new hire earnings. Column (2): log male new hire earnings (placebo). Column (3): female share of all new hires. All regressions include state and quarter FE. Standard errors clustered by state.",
       tex = TRUE,
       file = file.path(tab_dir, "tab5_decomposition.tex"),
       replace = TRUE)

cat("  Saved tab5_decomposition.tex\n")

# ============================================================
# Table 6: Industry Heterogeneity
# ============================================================

cat("Table 6: Industry Heterogeneity\n")

etable(ind_male_dom, ind_female_dom, ind_high_wage, twfe_nobundle,
       headers = c("Male-Dom.", "Female-Dom.", "High-Wage", "Excl. CO/CA/WA"),
       se.below = TRUE,
       se = "cluster",
       keep = "%post",
       dict = c(post = "Ban Effective"),
       fitstat = c("n", "r2"),
       title = "Heterogeneity by Industry Gender Composition",
       label = "tab:heterogeneity",
       notes = "Male-dominated: Construction, Mining, Utilities, Manufacturing, Transportation. Female-dominated: Healthcare, Education, Accommodation. High-wage: Finance, Professional Services, Information. Column (4) excludes CO, CA, WA (bundled pay transparency laws). Standard errors clustered by state.",
       tex = TRUE,
       file = file.path(tab_dir, "tab6_heterogeneity.tex"),
       replace = TRUE)

cat("  Saved tab6_heterogeneity.tex\n")

cat("\nAll tables generated.\n")
