## 05_tables.R — Generate all LaTeX tables
## apep_0655: The Employer Side of Deportation

source("00_packages.R")

cat("=== Loading results ===\n")
res <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
panel <- readRDS("../data/panel_main.rds")

# ------------------------------------------------------------------
# Table 1: Summary Statistics
# ------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

# Summary by ethnicity, pre-SC period
pre_data <- panel %>%
  filter(event_q < 0) %>%
  group_by(ethnicity) %>%
  summarise(
    `Employment` = sprintf("%.0f", mean(emp, na.rm = TRUE)),
    `All Hires` = sprintf("%.0f", mean(hir_all, na.rm = TRUE)),
    `Separations` = sprintf("%.0f", mean(sep, na.rm = TRUE)),
    `New Hires` = sprintf("%.0f", mean(hir_new, na.rm = TRUE)),
    `Job Creation` = sprintf("%.0f", mean(frm_job_gn, na.rm = TRUE)),
    `Job Destruction` = sprintf("%.0f", mean(frm_job_ls, na.rm = TRUE)),
    `Avg Earnings (\\$)` = sprintf("%.0f", mean(earn_s, na.rm = TRUE)),
    `N (county-quarters)` = sprintf("%s", format(n(), big.mark = ",")),
    .groups = "drop"
  )

# Pivot for LaTeX
tab1_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Activation Means by Ethnicity}
\\label{tab:sumstats}
\\begin{tabular}{lcc}
\\toprule
& Hispanic & Non-Hispanic \\\\
\\midrule\n"

hisp <- pre_data %>% filter(ethnicity == "Hispanic")
non_hisp <- pre_data %>% filter(ethnicity == "Non-Hispanic")

vars <- c("Employment", "All Hires", "Separations", "New Hires",
          "Job Creation", "Job Destruction", "Avg Earnings (\\$)",
          "N (county-quarters)")

for (v in vars) {
  h_val <- hisp[[v]]
  nh_val <- non_hisp[[v]]
  tab1_tex <- paste0(tab1_tex, sprintf("%s & %s & %s \\\\\n", v, h_val, nh_val))
}

tab1_tex <- paste0(tab1_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-activation means of QWI variables at the county-quarter level. Employment is beginning-of-quarter count. Earnings are average monthly. All Hires includes both new hires and recalls. Job Creation (Destruction) is firm-level gross job gains (losses). Data: Census LEHD Quarterly Workforce Indicators, race/ethnicity tabulation, 2005--2015.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")
cat("  Saved tab1_sumstats.tex\n")

# ------------------------------------------------------------------
# Table 2: Main DDD Results
# ------------------------------------------------------------------
cat("=== Table 2: Main DDD Results ===\n")

etable(
  res$m2_emp, res$m2_hir, res$m2_sep, res$m2_earn,
  res$m2_jgn, res$m2_jls,
  headers = c("Emp", "Hiring", "Sep", "Earnings", "Job Creat.", "Job Destr."),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  fitstat = c("n", "r2"),
  dict = c(treat_ddd = "SC $\\times$ Hispanic"),
  tex = TRUE,
  file = "../tables/tab2_main_ddd.tex",
  replace = TRUE,
  title = "The Employer Side of Deportation: Triple-Difference Estimates",
  label = "tab:main_ddd",
  notes = paste0(
    "\\textit{Notes:} Each column reports the triple-difference coefficient ",
    "(Post-SC $\\times$ Hispanic) from a regression of log outcomes on the DDD ",
    "interaction with county-ethnicity and county-quarter fixed effects. ",
    "Standard errors clustered at the state level in parentheses. ",
    "Data: QWI county $\\times$ quarter $\\times$ ethnicity, 2005--2015. ",
    "*** $p<0.01$, ** $p<0.05$, * $p<0.1$."
  ),
  fontsize = "small"
)
cat("  Saved tab2_main_ddd.tex\n")

# ------------------------------------------------------------------
# Table 3: Industry Heterogeneity
# ------------------------------------------------------------------
cat("=== Table 3: Industry Heterogeneity ===\n")

etable(
  rob$hi_emp, rob$lo_emp, rob$hi_hir, rob$lo_hir,
  headers = c("High-Imm Emp", "Low-Imm Emp", "High-Imm Hir", "Low-Imm Hir"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  fitstat = c("n", "r2"),
  dict = c(treat_ddd = "SC $\\times$ Hispanic"),
  tex = TRUE,
  file = "../tables/tab3_industry_het.tex",
  replace = TRUE,
  title = "Industry Heterogeneity: High- vs. Low-Immigrant Sectors",
  label = "tab:ind_het",
  notes = paste0(
    "\\textit{Notes:} High-immigrant industries: Construction (23), Accommodation (72), ",
    "Administrative (56), Agriculture (11). Low-immigrant industries: Finance (52), ",
    "Professional Services (54), Education (61). All specifications include ",
    "county-industry-ethnicity and county-quarter fixed effects. ",
    "Standard errors clustered at the state level. ",
    "*** $p<0.01$, ** $p<0.05$, * $p<0.1$."
  )
)
cat("  Saved tab3_industry_het.tex\n")

# ------------------------------------------------------------------
# Table 4: Robustness — Pre-trend test & LOSO
# ------------------------------------------------------------------
cat("=== Table 4: Robustness ===\n")

# Pre-trend test results
pre_coef <- coef(rob$pre_test)["fake_treat_ddd"]
pre_se <- se(rob$pre_test)["fake_treat_ddd"]
pre_p <- pvalue(rob$pre_test)["fake_treat_ddd"]

# LOSO range
loso_range <- range(rob$loso$coef_emp, na.rm = TRUE)

# Main result for comparison
main_coef <- coef(res$m2_emp)["treat_ddd"]
main_se <- se(res$m2_emp)["treat_ddd"]

# Detrended specification
detrend_coef <- coef(rob$detrend_emp)["treat_ddd"]
detrend_se <- se(rob$detrend_emp)["treat_ddd"]
detrend_p <- pvalue(rob$detrend_emp)["treat_ddd"]

tab4_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\toprule
Check & Coefficient & SE \\\\
\\midrule
\\textit{Panel A: Main result} & & \\\\
SC $\\times$ Hispanic (employment) & %.4f & (%.4f) \\\\
\\midrule
\\textit{Panel B: Pre-trend falsification} & & \\\\
Placebo treatment ($t-4$ to $t-1$) & %.4f & (%.4f) \\\\
 & & [$p = %.3f$] \\\\
\\midrule
\\textit{Panel C: Detrended specification} & & \\\\
SC $\\times$ Hispanic (with Hispanic $\\times$ linear trend) & %.4f & (%.4f) \\\\
 & & [$p = %.3f$] \\\\
\\midrule
\\textit{Panel D: Leave-one-state-out} & & \\\\
Minimum coefficient & %.4f & \\\\
Maximum coefficient & %.4f & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A repeats the main DDD estimate from Table \\ref{tab:main_ddd}. Panel B reports a placebo test using only pre-activation data, with a fake treatment applied 4 quarters before actual SC activation. Panel C adds a Hispanic $\\times$ linear time trend to the baseline specification, absorbing differential pre-existing formalization trends for Hispanic workers. Panel D shows the range of coefficients when dropping each state in turn (LOSO sensitivity). All specifications use county-ethnicity FE and state-clustered SEs.
\\end{tablenotes}
\\end{table}\n",
  main_coef, main_se,
  pre_coef, pre_se, pre_p,
  detrend_coef, detrend_se, detrend_p,
  loso_range[1], loso_range[2]
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("  Saved tab4_robustness.tex\n")

# ------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE appendix)
# ------------------------------------------------------------------
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SD(Y) for each outcome in pre-period Hispanic observations
pre_hisp <- panel %>%
  filter(event_q < 0 & hispanic == 1)

sdy <- data.frame(
  outcome = c("Employment", "Hiring", "Separations", "Earnings",
              "Job Creation", "Job Destruction"),
  beta = c(
    coef(res$m2_emp)["treat_ddd"],
    coef(res$m2_hir)["treat_ddd"],
    coef(res$m2_sep)["treat_ddd"],
    coef(res$m2_earn)["treat_ddd"],
    coef(res$m2_jgn)["treat_ddd"],
    coef(res$m2_jls)["treat_ddd"]
  ),
  se = c(
    se(res$m2_emp)["treat_ddd"],
    se(res$m2_hir)["treat_ddd"],
    se(res$m2_sep)["treat_ddd"],
    se(res$m2_earn)["treat_ddd"],
    se(res$m2_jgn)["treat_ddd"],
    se(res$m2_jls)["treat_ddd"]
  ),
  sd_y = c(
    sd(pre_hisp$ln_emp, na.rm = TRUE),
    sd(pre_hisp$ln_hir, na.rm = TRUE),
    sd(pre_hisp$ln_sep, na.rm = TRUE),
    sd(pre_hisp$ln_earn, na.rm = TRUE),
    sd(pre_hisp$ln_frm_job_gn, na.rm = TRUE),
    sd(pre_hisp$ln_frm_job_ls, na.rm = TRUE)
  )
)

sdy <- sdy %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
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

# Generate LaTeX table
sde_rows <- paste(apply(sdy, 1, function(r) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s",
          r["outcome"], as.numeric(r["beta"]), as.numeric(r["se"]),
          as.numeric(r["sd_y"]), as.numeric(r["sde"]), as.numeric(r["se_sde"]),
          r["classification"])
}), collapse = " \\\\\n")

n_obs <- nrow(panel)
n_counties <- n_distinct(panel$county_fips)

tabF1_tex <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
%s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standardized Diagnostic Effect sizes computed as SDE $= \\hat{\\beta}/\\text{SD}(Y)$ where $\\hat{\\beta}$ is the triple-difference coefficient (Post-SC $\\times$ Hispanic) and SD($Y$) is the pre-activation standard deviation of the log outcome among Hispanic county-quarter observations. Binary treatment (activated vs not yet). Classification refers to magnitude, not statistical significance. Research question: Does immigration enforcement through Secure Communities reduce Hispanic employment through employer-side adjustments? Data: QWI county $\\times$ quarter $\\times$ ethnicity, 2005--2015. Method: Triple-difference with county-ethnicity and county-quarter FE. $N = %s$ county-quarter-ethnicity observations across %s counties.
\\end{tablenotes}
\\end{table}\n",
  sde_rows,
  format(n_obs, big.mark = ","),
  format(n_counties, big.mark = ",")
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("=== All tables generated ===\n")
