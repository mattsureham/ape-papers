# 05_tables.R — Generate all LaTeX tables for Furusato Nozei paper

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Load data and results
df <- readRDS(file.path(data_dir, "analysis_panel.rds"))
main_res <- readRDS(file.path(data_dir, "main_results.rds"))
rob_res <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Reconstruct variables
df <- df %>%
  mutate(
    rel_time = fy - 2019,
    time_num = as.numeric(fy - 2015),
    gift_tercile = case_when(
      fy2018_gift_rate <= 0.20 ~ "Low (<20\\%)",
      fy2018_gift_rate <= 0.30 ~ "Medium (20--30\\%)",
      TRUE ~ "High (>30\\%)"
    ),
    gift_quintile = ntile(fy2018_gift_rate, 5),
    gift_quintile_f = factor(gift_quintile)
  )

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-reform means
pre_df <- df %>% filter(fy <= 2018)
post_df <- df %>% filter(fy >= 2020)

# By treatment group
make_summ <- function(data, label) {
  data %>%
    group_by(muni_id) %>%
    summarise(
      mean_don_amount = mean(donation_amount / 1000, na.rm = TRUE),
      mean_don_count = mean(donation_count, na.rm = TRUE),
      mean_gift_rate = first(fy2018_gift_rate),
      .groups = "drop"
    ) %>%
    summarise(
      Label = label,
      N_muni = n(),
      `Mean donations (\\textyen M)` = round(mean(mean_don_amount, na.rm = TRUE), 1),
      `SD donations (\\textyen M)` = round(sd(mean_don_amount, na.rm = TRUE), 1),
      `Mean count` = formatC(round(mean(mean_don_count, na.rm = TRUE)), format = "d", big.mark = ","),
      `Mean gift rate` = round(mean(mean_gift_rate, na.rm = TRUE) * 100, 1)
    )
}

tab1_pre_all <- make_summ(pre_df, "Full sample (pre)")
tab1_pre_t <- make_summ(pre_df %>% filter(treat_binary == 1), "Treated (pre)")
tab1_pre_c <- make_summ(pre_df %>% filter(treat_binary == 0), "Control (pre)")
tab1_post_all <- make_summ(post_df, "Full sample (post)")
tab1_post_t <- make_summ(post_df %>% filter(treat_binary == 1), "Treated (post)")
tab1_post_c <- make_summ(post_df %>% filter(treat_binary == 0), "Control (post)")

tab1 <- bind_rows(tab1_pre_all, tab1_pre_t, tab1_pre_c,
                   tab1_post_all, tab1_post_t, tab1_post_c)

# LaTeX output
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Furusato Nozei Donations by Treatment Status}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Municipalities & Mean donations & SD donations & Mean count & Mean gift \\\\\n",
  " & & (\\textyen M) & (\\textyen M) & & rate (\\%) \\\\\n",
  "\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-reform (FY2014--2018)}} \\\\\n"
)

for (i in 1:3) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Label[i], " & ", tab1$N_muni[i], " & ",
    tab1$`Mean donations (\\textyen M)`[i], " & ",
    tab1$`SD donations (\\textyen M)`[i], " & ",
    tab1$`Mean count`[i], " & ",
    tab1$`Mean gift rate`[i], " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-reform (FY2020--2024)}} \\\\\n"
)

for (i in 4:6) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Label[i], " & ", tab1$N_muni[i], " & ",
    tab1$`Mean donations (\\textyen M)`[i], " & ",
    tab1$`SD donations (\\textyen M)`[i], " & ",
    tab1$`Mean count`[i], " & ",
    tab1$`Mean gift rate`[i], " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Data from the Ministry of Internal Affairs and Communications (MIC). ",
  "Donations measured in millions of yen (\\textyen M = \\textyen 1,000 $\\times$ 1,000). ",
  "Gift rate is the ratio of return-gift procurement cost to total donations received in FY2018. ",
  "Treated municipalities are those with FY2018 gift rates exceeding the 30\\% cap imposed in June 2019. ",
  "FY2019 is excluded as a partial treatment year. ",
  "N = 15,642 municipality-year observations across 1,738 municipalities.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================

cat("=== Generating Table 2: Main Results ===\n")

# Re-estimate models for modelsummary
m1 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df, cluster = ~prefecture)
m2 <- feols(log_donations ~ I(fy2018_gift_rate * post) | muni_id + fy,
            data = df, cluster = ~prefecture)
m3 <- feols(log(donation_count + 1) ~ treat_binary:post | muni_id + fy,
            data = df, cluster = ~prefecture)

# With municipality trends
m4 <- feols(log_donations ~ treat_binary:post | muni_id[time_num] + fy,
            data = df, cluster = ~prefecture)

# Shorter pre-period
df_short <- df %>% filter(fy >= 2017)
m5 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df_short, cluster = ~prefecture)

tab2_models <- list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5
)

# Custom coefficient names
coef_map <- c(
  "treat_binary:post" = "High Gift Rate $\\times$ Post",
  "I(fy2018_gift_rate * post)" = "Gift Rate $\\times$ Post"
)

gm <- list(
  list(raw = "nobs", clean = "Observations", fmt = function(x) formatC(x, format = "d", big.mark = ",")),
  list(raw = "r.squared.within", clean = "Within $R^2$", fmt = 3),
  list(raw = "FE: muni_id", clean = "Municipality FE", fmt = function(x) ifelse(x == "X", "Yes", "No")),
  list(raw = "FE: fy", clean = "Year FE", fmt = function(x) ifelse(x == "X", "Yes", "No"))
)

tab2_note <- paste0(
  "\\textit{Notes:} Each column reports a separate regression. ",
  "The dependent variable is log donations received (columns 1, 2, 4, 5) or log donation count (column 3). ",
  "``High Gift Rate'' is a binary indicator for municipalities with FY2018 gift procurement cost ratios exceeding 30\\%. ",
  "``Gift Rate'' in column (2) is the continuous FY2018 ratio. ",
  "Column (4) includes municipality-specific linear time trends. ",
  "Column (5) restricts the pre-period to FY2017--2018. ",
  "Standard errors clustered by prefecture in parentheses. ",
  "\\sym{*} $p < 0.10$, \\sym{**} $p < 0.05$, \\sym{***} $p < 0.01$."
)

modelsummary(
  tab2_models,
  output = file.path(table_dir, "tab2_main.tex"),
  coef_map = coef_map,
  gof_map = gm,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Effect of the 30\\% Gift Rate Cap on Municipal Donations",
  notes = tab2_note,
  escape = FALSE
)

# Add column headers manually
tab2_raw <- readLines(file.path(table_dir, "tab2_main.tex"))
# Find the header row and add dep var labels
header_idx <- which(grepl("^\\s*&\\s*\\(1\\)", tab2_raw))[1]
if (!is.na(header_idx)) {
  depvar_line <- " & \\multicolumn{2}{c}{Log Donations} & Log Count & \\multicolumn{2}{c}{Log Donations} \\\\"
  cmidrule_line <- " \\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-6}"
  tab2_raw <- c(tab2_raw[1:(header_idx-1)], depvar_line, cmidrule_line, tab2_raw[header_idx:length(tab2_raw)])
}

# Add extra info rows
munitrend_row <- "Municipality trends & No & No & No & Yes & No \\\\"
preperiod_row <- "Pre-period & 2014--18 & 2014--18 & 2014--18 & 2014--18 & 2017--18 \\\\"

# Insert before the bottomrule
bottom_idx <- which(grepl("bottomrule", tab2_raw))[1]
if (!is.na(bottom_idx)) {
  tab2_raw <- c(tab2_raw[1:(bottom_idx-1)], munitrend_row, preperiod_row, tab2_raw[bottom_idx:length(tab2_raw)])
}

writeLines(tab2_raw, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================

cat("=== Generating Table 3: Event Study ===\n")

es <- feols(
  log_donations ~ i(rel_time, treat_binary, ref = -1) | muni_id + fy,
  data = df, cluster = ~prefecture
)

es_coefs <- data.frame(
  period = c(-5, -4, -3, -2, 1, 2, 3, 4, 5),
  fy = c(2014, 2015, 2016, 2017, 2020, 2021, 2022, 2023, 2024),
  coef = coef(es),
  se = se(es)
) %>%
  mutate(
    stars = case_when(
      abs(coef / se) > 2.576 ~ "***",
      abs(coef / se) > 1.960 ~ "**",
      abs(coef / se) > 1.645 ~ "*",
      TRUE ~ ""
    ),
    ci_low = coef - 1.96 * se,
    ci_high = coef + 1.96 * se
  )

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Effect of the Gift Rate Cap on Log Donations}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Fiscal Year & Relative Period & Coefficient & Std. Error & 95\\% CI \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Pre-reform}} \\\\\n"
)

for (i in 1:4) {
  tab3_tex <- paste0(tab3_tex,
    "FY", es_coefs$fy[i], " & $t", sprintf("%+d", es_coefs$period[i]), "$ & ",
    sprintf("%.3f%s", es_coefs$coef[i], es_coefs$stars[i]), " & ",
    sprintf("(%.3f)", es_coefs$se[i]), " & ",
    sprintf("[%.3f, %.3f]", es_coefs$ci_low[i], es_coefs$ci_high[i]), " \\\\\n"
  )
}

tab3_tex <- paste0(tab3_tex,
  "FY2018 & $t-1$ & \\multicolumn{3}{c}{(reference period)} \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Post-reform}} \\\\\n"
)

for (i in 5:9) {
  tab3_tex <- paste0(tab3_tex,
    "FY", es_coefs$fy[i], " & $t+", es_coefs$period[i], "$ & ",
    sprintf("%.3f%s", es_coefs$coef[i], es_coefs$stars[i]), " & ",
    sprintf("(%.3f)", es_coefs$se[i]), " & ",
    sprintf("[%.3f, %.3f]", es_coefs$ci_low[i], es_coefs$ci_high[i]), " \\\\\n"
  )
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from an event study regression of log donations on interactions ",
  "between a high-gift-rate indicator (FY2018 rate $> 30\\%$) and fiscal year dummies. ",
  "FY2018 ($t{-}1$) is the reference period; FY2019 is excluded as a partial treatment year. ",
  "All regressions include municipality and year fixed effects. ",
  "Standard errors clustered by prefecture. ",
  "The pre-reform upward trend reflects the ``gift race'': municipalities with aggressive return-gift ",
  "strategies were gaining market share before the cap. ",
  "\\sym{*} $p < 0.10$, \\sym{**} $p < 0.05$, \\sym{***} $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))

# ============================================================
# TABLE 4: Redistribution and Dose-Response
# ============================================================

cat("=== Generating Table 4: Redistribution ===\n")

# Tercile model
m_terc <- feols(
  log_donations ~ i(gift_tercile, post, ref = "Medium (20--30\\%)") | muni_id + fy,
  data = df %>% mutate(gift_tercile = case_when(
    fy2018_gift_rate <= 0.20 ~ "Low (<20\\%)",
    fy2018_gift_rate <= 0.30 ~ "Medium (20--30\\%)",
    TRUE ~ "High (>30\\%)"
  ), gift_tercile = factor(gift_tercile, levels = c("Medium (20--30\\%)", "Low (<20\\%)", "High (>30\\%)"))),
  cluster = ~prefecture
)

# Quintile model
m_quint <- feols(
  log_donations ~ i(gift_quintile_f, post, ref = "3") | muni_id + fy,
  data = df, cluster = ~prefecture
)

# LaTeX table
q_coefs <- data.frame(
  quintile = c(1, 2, 3, 4, 5),
  coef = c(coef(m_quint), 0)[c(1,2,5,3,4)],  # reorder
  se = c(se(m_quint), 0)[c(1,2,5,3,4)]
)
# Actually let me just extract properly
q_res <- summary(m_quint)
q_coefs <- data.frame(
  quintile = c(1, 2, 4, 5),
  coef = coef(m_quint),
  se = se(m_quint)
)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Dose-Response: Effect by Pre-Reform Gift Rate Quintile}\n",
  "\\label{tab:quintile}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Q1 (Lowest) & Q2 & Q3 (Base) & Q4 & Q5 (Highest) \\\\\n",
  "\\hline\n",
  "Mean gift rate (\\%) & ",
  paste(round(tapply(df$fy2018_gift_rate[df$fy == 2018], df$gift_quintile[df$fy == 2018], mean, na.rm = TRUE) * 100, 1), collapse = " & "),
  " \\\\\n",
  "[0.5em]\n"
)

# Get coefficients
stars_fn <- function(coef, se) {
  t <- abs(coef / se)
  if (t > 2.576) return("***")
  if (t > 1.960) return("**")
  if (t > 1.645) return("*")
  return("")
}

coefs_q <- c(coef(m_quint)[1], coef(m_quint)[2], 0, coef(m_quint)[3], coef(m_quint)[4])
ses_q <- c(se(m_quint)[1], se(m_quint)[2], NA, se(m_quint)[3], se(m_quint)[4])

coef_str <- sapply(1:5, function(i) {
  if (i == 3) return("---")
  sprintf("%.3f%s", coefs_q[i], stars_fn(coefs_q[i], ses_q[i]))
})

se_str <- sapply(1:5, function(i) {
  if (i == 3) return("")
  sprintf("(%.3f)", ses_q[i])
})

tab4_tex <- paste0(tab4_tex,
  "Quintile $\\times$ Post & ", paste(coef_str, collapse = " & "), " \\\\\n",
  " & ", paste(se_str, collapse = " & "), " \\\\\n",
  "\\hline\n",
  "Municipalities & ",
  paste(table(df$gift_quintile[df$fy == 2018]), collapse = " & "),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from a regression of log donations on interactions between ",
  "gift-rate quintile indicators and a post-reform dummy (FY2020--2024), with municipality and year ",
  "fixed effects. Quintile 3 is the omitted category. The monotonic gradient---positive for Q1 (lowest gift rates) ",
  "and sharply negative for Q5 (highest)---confirms a dose-response relationship: municipalities ",
  "further above the 30\\% cap experienced larger donation declines. ",
  "Standard errors clustered by prefecture. ",
  "\\sym{*} $p < 0.10$, \\sym{**} $p < 0.05$, \\sym{***} $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_quintile.tex"))

# ============================================================
# TABLE 5: Robustness
# ============================================================

cat("=== Generating Table 5: Robustness ===\n")

# Excluding banned
m_nb <- feols(log_donations ~ treat_binary:post | muni_id + fy,
              data = df %>% filter(excluded == 0), cluster = ~prefecture)
# Excluding COVID
m_nc <- feols(log_donations ~ treat_binary:post | muni_id + fy,
              data = df %>% filter(!fy %in% c(2020, 2021)), cluster = ~prefecture)

rob_list <- list(
  "(1)" = m1,       # Main
  "(2)" = m4,       # Muni trends
  "(3)" = m5,       # Short pre
  "(4)" = m_nb,     # No banned
  "(5)" = m_nc      # No COVID
)

modelsummary(
  rob_list,
  output = file.path(table_dir, "tab5_robustness.tex"),
  coef_map = c("treat_binary:post" = "High Gift Rate $\\times$ Post"),
  gof_map = gm,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = "Robustness Checks",
  notes = paste0(
    "\\textit{Notes:} Dependent variable is log donations in all columns. ",
    "Column (1) is the baseline specification. ",
    "Column (2) adds municipality-specific linear time trends. ",
    "Column (3) restricts the pre-period to FY2017--2018. ",
    "Column (4) excludes the four municipalities banned from the system in June 2019. ",
    "Column (5) excludes FY2020--2021 (COVID years). ",
    "Standard errors clustered by prefecture. ",
    "\\sym{*} $p < 0.10$, \\sym{**} $p < 0.05$, \\sym{***} $p < 0.01$."
  ),
  escape = FALSE
)

# Add descriptive rows
tab5_raw <- readLines(file.path(table_dir, "tab5_robustness.tex"))
bottom_idx <- which(grepl("bottomrule", tab5_raw))[1]
if (!is.na(bottom_idx)) {
  extra_rows <- c(
    "Municipality trends & No & Yes & No & No & No \\\\",
    "Pre-period & 2015--18 & 2015--18 & 2017--18 & 2015--18 & 2015--18 \\\\",
    "Excl.\\ banned & No & No & No & Yes & No \\\\",
    "Excl.\\ COVID & No & No & No & No & Yes \\\\"
  )
  tab5_raw <- c(tab5_raw[1:(bottom_idx-1)], extra_rows, tab5_raw[bottom_idx:length(tab5_raw)])
}
writeLines(tab5_raw, file.path(table_dir, "tab5_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================

cat("=== Generating Table F1: SDE ===\n")

# Compute SDEs
# Pre-treatment SD of log_donations
pre_treated <- df %>% filter(fy <= 2018, treat_binary == 1)
pre_control <- df %>% filter(fy <= 2018, treat_binary == 0)
pre_all <- df %>% filter(fy <= 2018)

sd_y_log_don <- sd(pre_all$log_donations, na.rm = TRUE)
sd_y_log_count <- sd(log(pre_all$donation_count + 1), na.rm = TRUE)

# Main estimates
beta_donations <- coef(m1)["treat_binary:post"]
se_donations <- se(m1)["treat_binary:post"]

m_count <- feols(log(donation_count + 1) ~ treat_binary:post | muni_id + fy,
                 data = df, cluster = ~prefecture)
beta_count <- coef(m_count)["treat_binary:post"]
se_count <- se(m_count)["treat_binary:post"]

sde_donations <- beta_donations / sd_y_log_don
sde_count <- beta_count / sd_y_log_count
se_sde_donations <- se_donations / sd_y_log_don
se_sde_count <- se_count / sd_y_log_count

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: urban vs rural
# Use donation count as proxy for municipality size
df <- df %>%
  mutate(
    large_muni = as.integer(fy2018_donations_yen > median(fy2018_donations_yen, na.rm = TRUE))
  )

m_large <- feols(log_donations ~ treat_binary:post | muni_id + fy,
                 data = df %>% filter(large_muni == 1), cluster = ~prefecture)
m_small <- feols(log_donations ~ treat_binary:post | muni_id + fy,
                 data = df %>% filter(large_muni == 0), cluster = ~prefecture)

sd_y_large <- sd(df$log_donations[df$fy <= 2018 & df$large_muni == 1], na.rm = TRUE)
sd_y_small <- sd(df$log_donations[df$fy <= 2018 & df$large_muni == 0], na.rm = TRUE)

beta_large <- coef(m_large)["treat_binary:post"]
se_large <- se(m_large)["treat_binary:post"]
beta_small <- coef(m_small)["treat_binary:post"]
se_small <- se(m_small)["treat_binary:post"]

sde_large <- beta_large / sd_y_large
se_sde_large <- se_large / sd_y_large
sde_small <- beta_small / sd_y_small
se_sde_small <- se_small / sd_y_small

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does a binding cap on return-gift rates in a competitive fiscal donation system redistribute donations away from municipalities that offered the most generous gifts? ",
  "\\textbf{Policy mechanism:} The June 2019 regulation imposed a binding 30\\% ceiling on the ratio of return-gift procurement costs to donation amounts under Japan's Furusato Nozei (hometown tax) system, ending a ``gift race'' in which municipalities competed for tax-deductible donations by offering return gifts worth up to 50\\% of the donation value. ",
  "\\textbf{Outcome definition:} Log of total Furusato Nozei donation receipts (in thousands of yen) received by each municipality per fiscal year, as reported in MIC annual surveys. ",
  "\\textbf{Treatment:} Binary indicator for municipalities with FY2018 gift procurement cost ratios exceeding 30\\%. ",
  "\\textbf{Data:} Ministry of Internal Affairs and Communications (MIC) annual Furusato Nozei survey, FY2014--2024 (excluding FY2019), 1,738 municipalities, 15,642 observations. ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year), standard errors clustered by prefecture (47 clusters). ",
  "\\textbf{Sample:} All Japanese municipalities with non-missing FY2018 cost data; FY2019 excluded as a partial treatment year. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Log donations & ", sprintf("%.3f", beta_donations), " & ", sprintf("%.3f", se_donations),
  " & ", sprintf("%.3f", sd_y_log_don), " & ", sprintf("%.3f", sde_donations),
  " & ", sprintf("%.3f", se_sde_donations), " & ", classify_sde(sde_donations), " \\\\\n",
  "Log count & ", sprintf("%.3f", beta_count), " & ", sprintf("%.3f", se_count),
  " & ", sprintf("%.3f", sd_y_log_count), " & ", sprintf("%.3f", sde_count),
  " & ", sprintf("%.3f", se_sde_count), " & ", classify_sde(sde_count), " \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  "Log donations (large munis) & ", sprintf("%.3f", beta_large), " & ", sprintf("%.3f", se_large),
  " & ", sprintf("%.3f", sd_y_large), " & ", sprintf("%.3f", sde_large),
  " & ", sprintf("%.3f", se_sde_large), " & ", classify_sde(sde_large), " \\\\\n",
  "Log donations (small munis) & ", sprintf("%.3f", beta_small), " & ", sprintf("%.3f", se_small),
  " & ", sprintf("%.3f", sd_y_small), " & ", sprintf("%.3f", sde_small),
  " & ", sprintf("%.3f", se_sde_small), " & ", classify_sde(sde_small), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("Files:\n")
for (f in list.files(table_dir, pattern = "\\.tex$")) cat("  ", f, "\n")
