## 05_tables.R — Generate all tables for apep_0963
## Produces LaTeX tables for paper

source("00_packages.R")
library(fixest)
library(modelsummary)

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
df_full <- readRDS(file.path(data_dir, "analysis_data.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

## =========================================================================
## Table 1: Summary Statistics
## =========================================================================
cat("=== Table 1: Summary Statistics ===\n")

## Pre vs post comparison
sumstat_vars <- c("food_insecure", "very_low_fs", "snap_receipt",
                  "age", "college", "black", "hispanic",
                  "hh_size", "has_children", "low_income", "snap_rate")

var_labels <- c("Food insecure", "Very low food security", "SNAP receipt",
                "Age", "College degree", "Black", "Hispanic",
                "Household size", "Has children", "Low income (< \\$25K)",
                "State SNAP rate (2019)")

pre_stats <- df %>% filter(post == 0) %>%
  summarise(across(all_of(sumstat_vars),
                   list(mean = ~weighted.mean(., hh_weight, na.rm = TRUE),
                        sd = ~sqrt(weighted.mean((. - weighted.mean(., hh_weight, na.rm = TRUE))^2,
                                                 hh_weight, na.rm = TRUE)))))

post_stats <- df %>% filter(post == 1) %>%
  summarise(across(all_of(sumstat_vars),
                   list(mean = ~weighted.mean(., hh_weight, na.rm = TRUE),
                        sd = ~sqrt(weighted.mean((. - weighted.mean(., hh_weight, na.rm = TRUE))^2,
                                                 hh_weight, na.rm = TRUE)))))

## Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{Pre-Period (2018--2019)} & \\multicolumn{2}{c}{Post-Period (2022--2023)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_along(sumstat_vars)) {
  v <- sumstat_vars[i]
  pre_m <- pre_stats[[paste0(v, "_mean")]]
  pre_s <- pre_stats[[paste0(v, "_sd")]]
  post_m <- post_stats[[paste0(v, "_mean")]]
  post_s <- post_stats[[paste0(v, "_sd")]]

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\",
            var_labels[i], pre_m, pre_s, post_m, post_s))
}

n_pre <- sum(df$post == 0)
n_post <- sum(df$post == 1)
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(n_pre, big.mark = ","), format(n_post, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} CPS Food Security Supplement, December waves. N = %s households. Weighted using CPS household weights. Pre-period: December 2018--2019 (before TFP revision and COVID). Post-period: December 2022--2023 (after TFP revision, Emergency Allotments ended). Food insecure = low or very low food security (HRFS12M1 $\\geq$ 2). State SNAP rate is the 2019 ACS household SNAP participation rate, used as treatment intensity.",
          format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

## =========================================================================
## Table 2: Main Results
## =========================================================================
cat("=== Table 2: Main Results ===\n")

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3
m4 <- results$m4; m5 <- results$m5

## Get statistics
get_coef_row <- function(model, var = "post_treat") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, stars = stars)
}

r1 <- get_coef_row(m1); r2 <- get_coef_row(m2); r3 <- get_coef_row(m3)
r4 <- get_coef_row(m4); r5 <- get_coef_row(m5)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of TFP Revision on Food Security: Main Results}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Food & Food & Food & Very Low & SNAP \\\\",
  "& Insecure & Insecure & Insecure & Food Sec. & Receipt \\\\",
  "\\midrule",
  sprintf("Post $\\times$ SNAP Rate & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r1$b, r1$stars, r2$b, r2$stars, r3$b, r3$stars, r4$b, r4$stars, r5$b, r5$stars),
  sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r1$se, r2$se, r3$se, r4$se, r5$se),
  "\\\\",
  sprintf("Mean dep. var. & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          weighted.mean(df$food_insecure, df$hh_weight, na.rm = TRUE),
          weighted.mean(df$food_insecure, df$hh_weight, na.rm = TRUE),
          weighted.mean(df$food_insecure, df$hh_weight, na.rm = TRUE),
          weighted.mean(df$very_low_fs, df$hh_weight, na.rm = TRUE),
          weighted.mean(df$snap_receipt, df$hh_weight, na.rm = TRUE)),
  "HH controls & No & Yes & Yes & Yes & Yes \\\\",
  "Unemployment & No & No & Yes & Yes & Yes \\\\",
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","), format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","), format(nobs(m4), big.mark = ","),
          format(nobs(m5), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at state level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Post = 1 for December 2022--2023, 0 for December 2018--2019. SNAP Rate = state-level SNAP household participation rate from 2019 ACS. HH controls: age, college, Black, Hispanic, household size, children present, low income. Weighted by CPS household weights.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

## =========================================================================
## Table 3: Heterogeneity and Mechanisms
## =========================================================================
cat("=== Table 3: Heterogeneity ===\n")

het_lowinc <- get_coef_row(results$m_het_lowinc)
het_highinc <- get_coef_row(results$m_het_highinc)
het_kids <- get_coef_row(results$m_het_kids)
het_nokids <- get_coef_row(results$m_het_nokids)

## Also run by race
m_het_black <- feols(food_insecure ~ post_treat + age + college +
                       hh_size + has_children + low_income + unemp_rate |
                       statefip + year,
                     data = df %>% filter(black == 1),
                     cluster = ~statefip, weights = ~hh_weight)
m_het_nonblack <- feols(food_insecure ~ post_treat + age + college +
                          hispanic + hh_size + has_children + low_income + unemp_rate |
                          statefip + year,
                        data = df %>% filter(black == 0),
                        cluster = ~statefip, weights = ~hh_weight)

het_black <- get_coef_row(m_het_black)
het_nonblack <- get_coef_row(m_het_nonblack)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneous Effects of TFP Revision on Food Insecurity}",
  "\\label{tab:heterogeneity}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{By Income} & \\multicolumn{2}{c}{By Children} & \\multicolumn{2}{c}{By Race} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "& Low & Higher & With & Without & Black & Non-Black \\\\",
  "& Income & Income & Children & Children & & \\\\",
  "\\midrule",
  sprintf("Post $\\times$ SNAP Rate & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          het_lowinc$b, het_lowinc$stars, het_highinc$b, het_highinc$stars,
          het_kids$b, het_kids$stars, het_nokids$b, het_nokids$stars,
          het_black$b, het_black$stars, het_nonblack$b, het_nonblack$stars),
  sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          het_lowinc$se, het_highinc$se, het_kids$se, het_nokids$se,
          het_black$se, het_nonblack$se),
  "\\\\",
  sprintf("Mean dep. var. & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          weighted.mean(df$food_insecure[df$low_income==1], df$hh_weight[df$low_income==1], na.rm=TRUE),
          weighted.mean(df$food_insecure[df$low_income==0], df$hh_weight[df$low_income==0], na.rm=TRUE),
          weighted.mean(df$food_insecure[df$has_children==1], df$hh_weight[df$has_children==1], na.rm=TRUE),
          weighted.mean(df$food_insecure[df$has_children==0], df$hh_weight[df$has_children==0], na.rm=TRUE),
          weighted.mean(df$food_insecure[df$black==1], df$hh_weight[df$black==1], na.rm=TRUE),
          weighted.mean(df$food_insecure[df$black==0], df$hh_weight[df$black==0], na.rm=TRUE)),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(results$m_het_lowinc), big.mark=","),
          format(nobs(results$m_het_highinc), big.mark=","),
          format(nobs(results$m_het_kids), big.mark=","),
          format(nobs(results$m_het_nokids), big.mark=","),
          format(nobs(m_het_black), big.mark=","),
          format(nobs(m_het_nonblack), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at state level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Each column is a separate regression on the indicated subsample. All specifications include household controls (age, college, household size, race/ethnicity where not the split variable), state unemployment rate, and state and year fixed effects. Low income = family income below \\$25,000. Weighted by CPS household weights.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_heterogeneity.tex"))
cat("  Written tab3_heterogeneity.tex\n")

## =========================================================================
## Table 4: Robustness
## =========================================================================
cat("=== Table 4: Robustness ===\n")

r_placebo <- get_coef_row(rob$m_placebo, "placebo_treat")
r_full <- get_coef_row(rob$m_full)
r_unwt <- get_coef_row(rob$m_unwt)
r_state <- get_coef_row(rob$m_state)
r_binary <- get_coef_row(rob$m_binary, "post_high")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule",
  sprintf("\\textit{Main specification} & %.3f & (%.3f) & %s \\\\",
          coef(m3)["post_treat"], se(m3)["post_treat"],
          format(nobs(m3), big.mark = ",")),
  "\\\\",
  "\\textit{Robustness checks:} & & & \\\\",
  sprintf("\\quad Placebo (2018 vs 2019) & %.3f & (%.3f) & %s \\\\",
          r_placebo$b, r_placebo$se, format(nobs(rob$m_placebo), big.mark = ",")),
  sprintf("\\quad Full sample (2018--2023) + EA control & %.3f & (%.3f) & %s \\\\",
          r_full$b, r_full$se, format(nobs(rob$m_full), big.mark = ",")),
  sprintf("\\quad Unweighted & %.3f & (%.3f) & %s \\\\",
          r_unwt$b, r_unwt$se, format(nobs(rob$m_unwt), big.mark = ",")),
  sprintf("\\quad State-level aggregation & %.3f & (%.3f) & %s \\\\",
          r_state$b, r_state$se, format(nobs(rob$m_state), big.mark = ",")),
  sprintf("\\quad Binary treatment (above median) & %.3f%s & (%.3f) & %s \\\\",
          r_binary$b, r_binary$stars, r_binary$se, format(nobs(rob$m_binary), big.mark = ",")),
  sprintf("\\quad Wild cluster bootstrap p-value & \\multicolumn{2}{c}{%.3f} & \\\\",
          ifelse(is.null(rob$boot_result), NA, rob$boot_result$p_val)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Main specification: household-level regression with state and year FE, HH controls, state unemployment, clustered SEs. Placebo uses only pre-period (2018 vs 2019). Full sample includes 2020--2021 with an Emergency Allotment indicator. Binary treatment splits states at the median SNAP participation rate. Wild cluster bootstrap uses Webb weights with 9,999 iterations.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("  Written tab4_robustness.tex\n")

## =========================================================================
## Table F1: Standardized Effect Sizes (SDE)
## =========================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDE for main outcomes
sd_y_fi <- sd(df$food_insecure)
sd_y_vlfs <- sd(df$very_low_fs)
sd_x <- sd(df$treat_intensity)

## Panel A: Pooled
beta_fi <- coef(m3)["post_treat"]
se_fi <- se(m3)["post_treat"]
sde_fi <- beta_fi * sd_x / sd_y_fi
se_sde_fi <- se_fi * sd_x / sd_y_fi

beta_vlfs <- coef(m4)["post_treat"]
se_vlfs <- se(m4)["post_treat"]
sde_vlfs <- beta_vlfs * sd_x / sd_y_vlfs
se_sde_vlfs <- se_vlfs * sd_x / sd_y_vlfs

## Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

## Panel B: Heterogeneous (low income vs higher income)
sd_y_fi_low <- sd(df$food_insecure[df$low_income == 1])
sd_y_fi_high <- sd(df$food_insecure[df$low_income == 0])

beta_low <- coef(results$m_het_lowinc)["post_treat"]
se_low <- se(results$m_het_lowinc)["post_treat"]
sde_low <- beta_low * sd_x / sd_y_fi_low
se_sde_low <- se_low * sd_x / sd_y_fi_low

beta_high <- coef(results$m_het_highinc)["post_treat"]
se_high <- se(results$m_het_highinc)["post_treat"]
sde_high <- beta_high * sd_x / sd_y_fi_high
se_sde_high <- se_high * sd_x / sd_y_fi_high

## Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the October 2021 Thrifty Food Plan revision, ",
  "which permanently increased SNAP maximum benefits by 21\\%, reduced household food insecurity ",
  "across states with varying SNAP exposure. ",
  "\\textbf{Policy mechanism:} USDA recalculated the market basket underpinning SNAP benefits ",
  "to reflect contemporary dietary guidelines and realistic food prices, raising the maximum ",
  "monthly allotment by \\$36.24 per person---the first substantive update since the program's inception. ",
  "\\textbf{Outcome definition:} Household food insecurity from the CPS Food Security Supplement, ",
  "defined as low or very low food security on the USDA 12-month scale. ",
  "\\textbf{Treatment:} Continuous---state-level SNAP household participation rate (2019 ACS), ",
  "measuring per-capita exposure to the benefit increase. ",
  "\\textbf{Data:} CPS Food Security Supplement (December 2018--2019, 2022--2023), household-level, ",
  "N = ", format(nrow(df), big.mark = ","), " households across 51 states. ",
  "\\textbf{Method:} Continuous difference-in-differences with state and year fixed effects, ",
  "household controls, state-clustered standard errors. ",
  "\\textbf{Sample:} Reference-person households with valid food security status, excluding ",
  "transition years 2020--2021 (contaminated by COVID and Emergency Allotment dynamics). ",
  "SDE = $\\hat{\\beta} \\times$ SD($X$) / SD($Y$) ",
  "where SD($X$) is the standard deviation of the continuous treatment and ",
  "SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$|$ $>$ 0.15), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<$ 0.005)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Food insecure & Main & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_fi, sd_x, sd_y_fi, sde_fi, se_sde_fi, classify(sde_fi)),
  sprintf("Very low food sec. & Main & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_vlfs, sd_x, sd_y_vlfs, sde_vlfs, se_sde_vlfs, classify(sde_vlfs)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Food insecure & Low income & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_low, sd_x, sd_y_fi_low, sde_low, se_sde_low, classify(sde_low)),
  sprintf("Food insecure & Higher income & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta_high, sd_x, sd_y_fi_high, sde_high, se_sde_high, classify(sde_high)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{threeparttable}",
  "\\par\\vspace{0.3em}",
  "{\\scriptsize",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

## =========================================================================
## Table 5: Event Study Coefficients
## =========================================================================
cat("=== Table 5: Event Study ===\n")

es_model <- results$m_es
es_coefs <- coef(es_model)
es_ses <- se(es_model)
es_pvals <- pvalue(es_model)

## Extract year × treatment intensity coefficients
es_years <- c(2015, 2016, 2017, 2018, 2020, 2021, 2022, 2023)
es_names <- paste0("year_factor::", es_years, ":treat_intensity")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year $\\times$ SNAP Rate & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in seq_along(es_years)) {
  yr <- es_years[i]
  nm <- es_names[i]
  b <- es_coefs[nm]
  s <- es_ses[nm]
  p <- es_pvals[nm]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  ref_note <- ifelse(yr >= 2022, " (post-TFP)", ifelse(yr == 2021, " (TFP start)", ""))
  tab5_lines <- c(tab5_lines,
    sprintf("%d%s & %.3f%s & (%.3f) \\\\", yr, ref_note, b, stars, s))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  "2019 (reference) & --- & --- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Event study specification with year dummies interacted with state SNAP participation rate. Reference year: 2019. All nine years (2015--2023) included. Controls: age, college, Black, Hispanic, household size, children, low income, unemployment rate. State and year FE. State-clustered SEs. N = %s.", format(nobs(es_model), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_eventstudy.tex"))
cat("  Written tab5_eventstudy.tex\n")

cat("\nAll tables generated.\n")
