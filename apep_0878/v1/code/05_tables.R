# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
df <- df %>% filter(year >= 2001, year <= 2022)
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

df$post <- as.integer(df$year >= df$eitc_year & df$eitc_year > 0)

# Pre-treatment means by race
pre_stats <- df %>%
  filter(post == 0 | eitc_year == 0) %>%
  group_by(race) %>%
  summarize(
    `Mean Employment` = mean(emp, na.rm = TRUE),
    `SD Employment` = sd(emp, na.rm = TRUE),
    `Mean Earnings (\\$/month)` = mean(earn_avg, na.rm = TRUE),
    `SD Earnings` = sd(earn_avg, na.rm = TRUE),
    `Mean Hires` = mean(hires, na.rm = TRUE),
    Observations = n(),
    .groups = "drop"
  ) %>%
  mutate(race = ifelse(race == "A1", "White", "Black"))

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Means by Race}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lrrrrrr}\n",
  "\\toprule\n",
  "Race & Mean Emp & SD Emp & Mean Earn & SD Earn & Mean Hires & Obs \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(pre_stats)) {
  tab1_tex <- paste0(tab1_tex,
    pre_stats$race[i], " & ",
    format(round(pre_stats$`Mean Employment`[i], 0), big.mark = ","), " & ",
    format(round(pre_stats$`SD Employment`[i], 0), big.mark = ","), " & ",
    format(round(pre_stats$`Mean Earnings (\\$/month)`[i], 0), big.mark = ","), " & ",
    format(round(pre_stats$`SD Earnings`[i], 0), big.mark = ","), " & ",
    format(round(pre_stats$`Mean Hires`[i], 0), big.mark = ","), " & ",
    format(pre_stats$Observations[i], big.mark = ","),
    " \\\\\n"
  )
}

# Treatment adoption summary
n_treated_states <- n_distinct(df$state_fips[df$eitc_year > 0])
n_control_states <- n_distinct(df$state_fips[df$eitc_year == 0])
n_counties <- n_distinct(df$fips_county)

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Treatment Design}} \\\\\n",
  "Treated states & \\multicolumn{6}{l}{", n_treated_states, "} \\\\\n",
  "Never-treated states & \\multicolumn{6}{l}{", n_control_states, "} \\\\\n",
  "Counties & \\multicolumn{6}{l}{", format(n_counties, big.mark = ","), "} \\\\\n",
  "Industries & \\multicolumn{6}{l}{Accommodation/Food (72), Retail (44-45), Healthcare (62)} \\\\\n",
  "Treatment cohorts & \\multicolumn{6}{l}{2006, 2007, 2008, 2011, 2013, 2015, 2018} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} QWI county $\\times$ industry $\\times$ race annual panel, 2001--2022. ",
  "Employment and earnings are annual averages of quarterly observations. ",
  "Pre-treatment means computed for years before each state's EITC adoption (treated states) ",
  "or all years (never-treated states). Sample restricted to low-wage sectors.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# =============================================================================
# TABLE 2: Main Results — CS DiD ATT
# =============================================================================
cat("Generating Table 2: Main Results\n")

att_be <- results$att_black_emp
att_we <- results$att_white_emp
att_bear <- results$att_black_earn
att_wear <- results$att_white_earn

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{State EITC Effects on Employment and Earnings by Race}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Log Employment} & \\multicolumn{2}{c}{Log Earnings} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Black & White & Black & White \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "ATT & ", sprintf("%.4f", att_be$overall.att),
  " & ", sprintf("%.4f", att_we$overall.att),
  " & ", sprintf("%.4f", att_bear$overall.att),
  " & ", sprintf("%.4f", att_wear$overall.att), " \\\\\n",
  " & (", sprintf("%.4f", att_be$overall.se),
  ") & (", sprintf("%.4f", att_we$overall.se),
  ") & (", sprintf("%.4f", att_bear$overall.se),
  ") & (", sprintf("%.4f", att_wear$overall.se), ") \\\\\n",
  "\\midrule\n",
  "Estimator & \\multicolumn{4}{c}{Callaway \\& Sant'Anna (2021)} \\\\\n",
  "Control group & \\multicolumn{4}{c}{Never-treated states} \\\\\n",
  "Unit & \\multicolumn{4}{c}{State $\\times$ industry $\\times$ race} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports the aggregated group-time ATT from ",
  "Callaway and Sant'Anna (2021), using never-treated states as controls and a universal base period. ",
  "Outcomes are log employment (columns 1--2) and log average monthly earnings (columns 3--4). ",
  "Standard errors in parentheses use the multiplier bootstrap.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Triple-Difference (DDD) Results
# =============================================================================
cat("Generating Table 3: DDD Results\n")

ddd_e <- results$ddd_emp
ddd_a <- results$ddd_earn
ddd_h <- results$ddd_hires

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Triple-Difference: Black--White Gap in EITC-Adopting States}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Log Employment & Log Earnings & Log Hires \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\midrule\n",
  "Post $\\times$ Black & ",
  sprintf("%.4f", coef(ddd_e)["post:black"]), " & ",
  sprintf("%.4f", coef(ddd_a)["post:black"]), " & ",
  sprintf("%.4f", coef(ddd_h)["post:black"]), " \\\\\n",
  " & (", sprintf("%.4f", sqrt(vcov(ddd_e)["post:black", "post:black"])),
  ") & (", sprintf("%.4f", sqrt(vcov(ddd_a)["post:black", "post:black"])),
  ") & (", sprintf("%.4f", sqrt(vcov(ddd_h)["post:black", "post:black"])),
  ") \\\\\n",
  "[4pt]\n",
  "Post & ",
  sprintf("%.4f", coef(ddd_e)["post"]), " & ",
  sprintf("%.4f", coef(ddd_a)["post"]), " & ",
  sprintf("%.4f", coef(ddd_h)["post"]), " \\\\\n",
  " & (", sprintf("%.4f", sqrt(vcov(ddd_e)["post", "post"])),
  ") & (", sprintf("%.4f", sqrt(vcov(ddd_a)["post", "post"])),
  ") & (", sprintf("%.4f", sqrt(vcov(ddd_h)["post", "post"])),
  ") \\\\\n",
  "\\midrule\n",
  "County $\\times$ Industry $\\times$ Race FE & Yes & Yes & Yes \\\\\n",
  "Industry $\\times$ Race $\\times$ Year FE & Yes & Yes & Yes \\\\\n",
  "Clusters (states) & ", robustness$n_clusters,
  " & ", robustness$n_clusters,
  " & ", robustness$n_clusters, " \\\\\n",
  "Observations & ", format(nrow(df %>% filter(year >= 2001, year <= 2022)), big.mark = ","),
  " & ", format(nrow(df %>% filter(year >= 2001, year <= 2022)), big.mark = ","),
  " & ", format(nrow(df %>% filter(year >= 2001, year <= 2022)), big.mark = ","),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Triple-difference estimates comparing Black vs.\\ White workers, ",
  "in EITC-adopting vs.\\ never-treated states, before vs.\\ after adoption. ",
  "Post $\\times$ Black captures the differential effect of state EITC adoption ",
  "on Black relative to White workers. Standard errors clustered at the state level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_ddd.tex")

# =============================================================================
# TABLE 4: Robustness
# =============================================================================
cat("Generating Table 4: Robustness\n")

placebo <- robustness$placebo_earn
att_nyt <- robustness$att_nyt
dose <- robustness$dose_earn
loso <- robustness$loso

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: DDD Earnings (Post $\\times$ Black)}} \\\\\n",
  "Baseline & ", sprintf("%.4f", coef(ddd_a)["post:black"]),
  " & ", sprintf("%.4f", sqrt(vcov(ddd_a)["post:black", "post:black"])), " \\\\\n",
  "Placebo ($t-3$ fake treatment) & ", sprintf("%.4f", coef(placebo)["fake_post:black"]),
  " & ", sprintf("%.4f", sqrt(vcov(placebo)["fake_post:black", "fake_post:black"])), " \\\\\n",
  "Continuous treatment (dose $\\times$ Black) & ", sprintf("%.4f", coef(dose)["dose:black"]),
  " & ", sprintf("%.4f", sqrt(vcov(dose)["dose:black", "dose:black"])), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: CS DiD Black Earnings ATT}} \\\\\n",
  "Never-treated controls & ", sprintf("%.4f", results$att_black_earn$overall.att),
  " & ", sprintf("%.4f", results$att_black_earn$overall.se), " \\\\\n",
  "Not-yet-treated controls & ", sprintf("%.4f", att_nyt$overall.att),
  " & ", sprintf("%.4f", att_nyt$overall.se), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Leave-One-State-Out (DDD Earnings)}} \\\\\n",
  "Minimum & ", sprintf("%.4f", min(loso$coef)),
  " & ", sprintf("%.4f", loso$se[which.min(loso$coef)]), " \\\\\n",
  "Maximum & ", sprintf("%.4f", max(loso$coef)),
  " & ", sprintf("%.4f", loso$se[which.max(loso$coef)]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A compares the baseline DDD earnings estimate with a placebo ",
  "(fake treatment 3 years before actual adoption) and a continuous treatment specification ",
  "using state EITC supplement rates. Panel B compares CS DiD estimates for Black earnings ",
  "using never-treated vs.\\ not-yet-treated control groups. Panel C shows the range of ",
  "DDD coefficients when each treated state is dropped individually.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# =============================================================================
cat("Generating Table F1: SDE\n")

# Compute pre-treatment SDs
pre_sd <- df %>%
  filter(eitc_year == 0 | year < eitc_year) %>%
  summarize(
    sd_log_emp_black = sd(log_emp[race == "A2"], na.rm = TRUE),
    sd_log_earn_black = sd(log_earn[race == "A2"], na.rm = TRUE),
    sd_log_emp_white = sd(log_emp[race == "A1"], na.rm = TRUE),
    sd_log_earn_white = sd(log_earn[race == "A1"], na.rm = TRUE),
    sd_log_emp_all = sd(log_emp, na.rm = TRUE),
    sd_log_earn_all = sd(log_earn, na.rm = TRUE)
  )

# SDE calculations
# Max 6 rows total (4 pooled + 2 heterogeneous)
sde_rows <- tribble(
  ~outcome, ~beta, ~se, ~sd_y,
  "Black Employment (CS ATT)", att_be$overall.att, att_be$overall.se, pre_sd$sd_log_emp_black,
  "Black Earnings (CS ATT)", att_bear$overall.att, att_bear$overall.se, pre_sd$sd_log_earn_black,
  "Racial Emp Gap (DDD)", coef(ddd_e)["post:black"],
    sqrt(vcov(ddd_e)["post:black", "post:black"]), pre_sd$sd_log_emp_all,
  "Racial Earn Gap (DDD)", coef(ddd_a)["post:black"],
    sqrt(vcov(ddd_a)["post:black", "post:black"]), pre_sd$sd_log_earn_all
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Panel B: Heterogeneous (by industry)
het_rows <- list()
for (ind in c("72", "62")) {
  ind_label <- ifelse(ind == "72", "Accom/Food", "Healthcare")
  df_ind <- df %>% filter(industry == ind, year >= 2001, year <= 2022)
  df_ind$post <- as.integer(df_ind$year >= df_ind$eitc_year & df_ind$eitc_year > 0)
  m_ind <- feols(
    log_earn ~ post:black + post + black |
      fips_county^race + race^year,
    data = df_ind, cluster = ~state_fips
  )
  b <- coef(m_ind)["post:black"]
  s <- sqrt(vcov(m_ind)["post:black", "post:black"])
  sd_y_ind <- sd(df_ind$log_earn[df_ind$eitc_year == 0 | df_ind$year < df_ind$eitc_year], na.rm = TRUE)
  het_rows[[ind]] <- tibble(
    outcome = paste0("Racial Earn Gap — ", ind_label),
    beta = b, se = s, sd_y = sd_y_ind,
    sde = b / sd_y_ind, se_sde = s / sd_y_ind,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )
}
het_df <- bind_rows(het_rows)

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state Earned Income Tax Credit supplements narrow racial employment and earnings gaps in low-wage industries, and does employer wage incidence offset employment gains for Black workers? ",
  "\\textbf{Policy mechanism:} State EITC supplements provide refundable tax credits to low-income workers as a percentage (5--30\\%) of the federal EITC, increasing the after-tax return to work; economic theory (Rothstein 2010) predicts employers capture part of the subsidy through lower pre-tax wages. ",
  "\\textbf{Outcome definition:} Log county-level average monthly earnings (EarnS) and log employment (Emp) from QWI administrative records. ",
  "\\textbf{Treatment:} Binary indicator for state EITC adoption (12 states, 2006--2018). ",
  "\\textbf{Data:} Quarterly Workforce Indicators (LEHD), county $\\times$ NAICS sector $\\times$ race, 2001--2022, ",
  format(nrow(df), big.mark = ","), " observations. ",
  "\\textbf{Method:} Callaway--Sant'Anna staggered DiD (Panels A, B) and triple-difference with county $\\times$ industry $\\times$ race and industry $\\times$ race $\\times$ year FE, clustered at state level (remaining rows). ",
  "\\textbf{Sample:} Low-wage sectors (Accommodation/Food NAICS 72, Retail 44-45, Healthcare 62), White and Black workers, excluding states with pre-2001 EITCs. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  tabf1 <- paste0(tabf1,
    sde_rows$outcome[i], " & ",
    sprintf("%.4f", sde_rows$beta[i]), " & ",
    sprintf("%.4f", sde_rows$se[i]), " & ",
    sprintf("%.3f", sde_rows$sd_y[i]), " & ",
    sprintf("%.4f", sde_rows$sde[i]), " & ",
    sprintf("%.4f", sde_rows$se_sde[i]), " & ",
    sde_rows$classification[i], " \\\\\n"
  )
}

tabf1 <- paste0(tabf1,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by industry)}} \\\\\n"
)

for (i in 1:nrow(het_df)) {
  tabf1 <- paste0(tabf1,
    het_df$outcome[i], " & ",
    sprintf("%.4f", het_df$beta[i]), " & ",
    sprintf("%.4f", het_df$se[i]), " & ",
    sprintf("%.3f", het_df$sd_y[i]), " & ",
    sprintf("%.4f", het_df$sde[i]), " & ",
    sprintf("%.4f", het_df$se_sde[i]), " & ",
    het_df$classification[i], " \\\\\n"
  )
}

tabf1 <- paste0(tabf1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabf1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
