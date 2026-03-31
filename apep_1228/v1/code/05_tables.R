## 05_tables.R — Generate all LaTeX tables for apep_1228
## GIPP waterbed effect in UK insurance

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

## Force kableExtra backend for modelsummary (avoids tabularray dependency)
options(modelsummary_factory_default = "kableExtra")
options(modelsummary_format_numeric_latex = "plain")

boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))
firms_panel <- readRDS(file.path(data_dir, "firms_panel.rds"))
models <- readRDS(file.path(data_dir, "all_models.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_models.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================

## BoE panel stats
boe_stats <- boe_panel %>%
  mutate(nwp_bn = nwp / 1e9) %>%
  summarise(
    mean_nwp = mean(nwp_bn, na.rm = TRUE),
    sd_nwp = sd(nwp_bn, na.rm = TRUE),
    min_nwp = min(nwp_bn, na.rm = TRUE),
    max_nwp = max(nwp_bn, na.rm = TRUE),
    mean_lr = mean(loss_ratio, na.rm = TRUE),
    sd_lr = sd(loss_ratio, na.rm = TRUE),
    min_lr = min(loss_ratio, na.rm = TRUE),
    max_lr = max(loss_ratio, na.rm = TRUE),
    n = n()
  )

## By GIPP target
boe_by_target <- boe_panel %>%
  mutate(nwp_bn = nwp / 1e9) %>%
  group_by(Period = ifelse(gipp_target == 1, "GIPP-targeted", "Control")) %>%
  summarise(
    `Mean NWP (GBP bn)` = mean(nwp_bn, na.rm = TRUE),
    `SD NWP` = sd(nwp_bn, na.rm = TRUE),
    `Mean Loss Ratio` = mean(loss_ratio, na.rm = TRUE),
    `SD Loss Ratio` = sd(loss_ratio, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

## Pre/Post breakdown for GIPP targets
boe_by_period <- boe_panel %>%
  filter(gipp_target == 1) %>%
  mutate(nwp_bn = nwp / 1e9) %>%
  group_by(Period = ifelse(post == 1, "GIPP-targeted (post)", "GIPP-targeted (pre)")) %>%
  summarise(
    `Mean NWP (GBP bn)` = mean(nwp_bn, na.rm = TRUE),
    `SD NWP` = sd(nwp_bn, na.rm = TRUE),
    `Mean Loss Ratio` = mean(loss_ratio, na.rm = TRUE),
    `SD Loss Ratio` = sd(loss_ratio, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

## Control pre/post
boe_control_period <- boe_panel %>%
  filter(gipp_target == 0) %>%
  mutate(nwp_bn = nwp / 1e9) %>%
  group_by(Period = ifelse(post == 1, "Control (post)", "Control (pre)")) %>%
  summarise(
    `Mean NWP (GBP bn)` = mean(nwp_bn, na.rm = TRUE),
    `SD NWP` = sd(nwp_bn, na.rm = TRUE),
    `Mean Loss Ratio` = mean(loss_ratio, na.rm = TRUE),
    `SD Loss Ratio` = sd(loss_ratio, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

summary_df <- bind_rows(boe_by_target, boe_by_period, boe_control_period)

## Write LaTeX
cat("\\begin{table}[H]\n\\centering\n\\caption{Summary Statistics: BoE Insurance Lines}\n",
    "\\label{tab:summary}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lrrrrr}\n\\toprule\n",
    " & Mean NWP & SD NWP & Mean Loss & SD Loss & \\\\\n",
    " & (GBP bn) & (GBP bn) & Ratio (\\%) & Ratio & N \\\\\n\\midrule\n",
    file = file.path(table_dir, "tab1_summary.tex"))

for (i in 1:nrow(summary_df)) {
  cat(sprintf("%s & %.2f & %.2f & %.1f & %.1f & %d \\\\\n",
              summary_df$Period[i],
              summary_df$`Mean NWP (GBP bn)`[i],
              summary_df$`SD NWP`[i],
              summary_df$`Mean Loss Ratio`[i],
              summary_df$`SD Loss Ratio`[i],
              summary_df$N[i]),
      file = file.path(table_dir, "tab1_summary.tex"), append = TRUE)
}

cat("\\bottomrule\n\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n\\small\n",
    "\\item \\textit{Notes:} N = 396 line-quarter observations from Bank of England ",
    "Insurance Aggregate Data, 2017Q1--2025Q4. GIPP-targeted lines are Motor liability, ",
    "Motor other, and Property (home insurance). Control lines are Assistance, Credit, ",
    "Financial loss, General liability, Income protection, Legal expenses, Marine/Aviation/Transport, ",
    "and Medical expense. Net Written Premium (NWP) is in GBP billions. Loss ratio is claims ",
    "incurred as a percentage of premiums earned.\n",
    "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n",
    file = file.path(table_dir, "tab1_summary.tex"), append = TRUE)

## ============================================================
## Table 2: Main DiD Results
## ============================================================

## Extract models
m1 <- models$m1  # Basic DiD NWP
m2 <- models$m2  # Trends NWP
m5 <- models$m5  # Separate motor/property NWP
m3 <- models$m3  # Basic DiD LR
m6 <- models$m6  # Separate motor/property LR

## Use modelsummary
tab2_models <- list(
  "(1)" = m1,
  "(2)" = m2,
  "(3)" = m5,
  "(4)" = m3,
  "(5)" = m6
)

tab2_cm <- c(
  "treat_post" = "GIPP Target $\\times$ Post",
  "motor_post" = "Motor $\\times$ Post",
  "property_post" = "Property $\\times$ Post"
)

tab2_gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: line_id", "clean" = "Line FE", "fmt" = 0),
  list("raw" = "FE: quarter_id", "clean" = "Quarter FE", "fmt" = 0)
)

modelsummary(tab2_models,
             output = file.path(table_dir, "tab2_main.tex"),
             coef_map = tab2_cm,
             gof_map = tab2_gm,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             title = "GIPP Effects on Net Written Premium and Loss Ratio",
             notes = list("Standard errors clustered at line-of-business level in parentheses.",
                         "Columns (1)--(3): dependent variable is log(Net Written Premium).",
                         "Columns (4)--(5): dependent variable is Loss Ratio (\\%).",
                         "Column (2) includes line-specific linear time trends.",
                         "Treatment date: January 1, 2022."),
             add_rows = data.frame(
               term = c("Dep. Variable", "Line trends"),
               `(1)` = c("log(NWP)", "No"),
               `(2)` = c("log(NWP)", "Yes"),
               `(3)` = c("log(NWP)", "No"),
               `(4)` = c("Loss Ratio", "No"),
               `(5)` = c("Loss Ratio", "No"),
               check.names = FALSE
             ),
             escape = FALSE)

cat("Table 2 written.\n")

## ============================================================
## Table 3: Firm-Level DiD Results
## ============================================================
m_firm1 <- models$m_firm1
m_firm2 <- models$m_firm2
m_firm3 <- models$m_firm3

tab3_models <- list(
  "(1)" = m_firm1,
  "(2)" = m_firm2,
  "(3)" = m_firm3
)

tab3_cm <- c(
  "treat_post" = "High GIPP $\\times$ Post"
)

modelsummary(tab3_models,
             output = file.path(table_dir, "tab3_firms.tex"),
             coef_map = tab3_cm,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             title = "Firm-Level GIPP Effects: FCA GI Value Measures",
             notes = list("Standard errors clustered at firm level in parentheses.",
                         "Column (1): Claims Frequency (\\%, band midpoint).",
                         "Column (2): Claims Acceptance Rate (\\%, band midpoint).",
                         "Column (3): Claims Complaints as \\% of Claims (band midpoint).",
                         "High-GIPP products: Motor and Home insurance. Firm and year FE included."),
             escape = FALSE)

cat("Table 3 written.\n")

## ============================================================
## Table 4: Robustness
## ============================================================
rob_models <- list(
  "(1)" = robustness$placebo_motor_prop,
  "(2)" = robustness$no_covid_nwp,
  "(3)" = robustness$restricted_nwp,
  "(4)" = robustness$no_covid_lr,
  "(5)" = robustness$restricted_lr
)

tab4_cm <- c(
  "motor_post" = "Motor $\\times$ Post",
  "property_post" = "Property $\\times$ Post",
  "motor_placebo" = "Motor $\\times$ Placebo",
  "property_placebo" = "Property $\\times$ Placebo"
)

modelsummary(rob_models,
             output = file.path(table_dir, "tab4_robustness.tex"),
             coef_map = tab4_cm,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             title = "Robustness Checks",
             notes = list("Standard errors clustered at line level.",
                         "Col.~(1): Placebo treatment at 2020Q1, pre-GIPP sample only.",
                         "Cols.~(2)--(3): log(NWP); Cols.~(4)--(5): Loss Ratio.",
                         "Col.~(2) and (4): Drop COVID quarters (2020Q1--2021Q2).",
                         "Col.~(3) and (5): Drop Medical expense and Income protection from controls."),
             escape = FALSE)

cat("Table 4 written.\n")

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================

## Main coefficients from separate motor/property specification
beta_motor_nwp <- coef(models$m5)["motor_post"]
se_motor_nwp <- sqrt(diag(vcov(models$m5, type = "cluster")))["motor_post"]
sd_y_nwp <- sd(boe_panel$log_nwp)

beta_prop_nwp <- coef(models$m5)["property_post"]
se_prop_nwp <- sqrt(diag(vcov(models$m5, type = "cluster")))["property_post"]

beta_motor_lr <- coef(models$m6)["motor_post"]
se_motor_lr <- sqrt(diag(vcov(models$m6, type = "cluster")))["motor_post"]
sd_y_lr <- sd(boe_panel$loss_ratio, na.rm = TRUE)

beta_prop_lr <- coef(models$m6)["property_post"]
se_prop_lr <- sqrt(diag(vcov(models$m6, type = "cluster")))["property_post"]

## Firm-level
beta_firm_freq <- coef(models$m_firm1)["treat_post"]
se_firm_freq <- sqrt(diag(vcov(models$m_firm1, type = "cluster")))["treat_post"]
sd_y_freq <- sd(firms_panel$claims_freq_mid, na.rm = TRUE)

beta_firm_comp <- coef(models$m_firm3)["treat_post"]
se_firm_comp <- sqrt(diag(vcov(models$m_firm3, type = "cluster")))["treat_post"]
sd_y_comp <- sd(firms_panel$claims_complaints_mid, na.rm = TRUE)

## Compute SDEs (binary treatment)
compute_sde <- function(beta, se, sd_y) {
  sde <- beta / sd_y
  se_sde <- se / sd_y
  class <- dplyr::case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )
  list(beta = beta, se = se, sd_y = sd_y, sde = sde, se_sde = se_sde, class = class)
}

pooled_nwp <- compute_sde(coef(models$m1)["treat_post"],
                          sqrt(diag(vcov(models$m1, type = "cluster")))["treat_post"],
                          sd_y_nwp)
pooled_lr <- compute_sde(coef(models$m3)["treat_post"],
                         sqrt(diag(vcov(models$m3, type = "cluster")))["treat_post"],
                         sd_y_lr)
motor_nwp_sde <- compute_sde(beta_motor_nwp, se_motor_nwp, sd_y_nwp)
prop_nwp_sde <- compute_sde(beta_prop_nwp, se_prop_nwp, sd_y_nwp)
motor_lr_sde <- compute_sde(beta_motor_lr, se_motor_lr, sd_y_lr)
prop_lr_sde <- compute_sde(beta_prop_lr, se_prop_lr, sd_y_lr)
firm_freq_sde <- compute_sde(beta_firm_freq, se_firm_freq, sd_y_freq)
firm_comp_sde <- compute_sde(beta_firm_comp, se_firm_comp, sd_y_comp)

## Format a row
fmt_row <- function(label, s) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
          label, s$beta, s$se, s$sd_y, s$sde, s$se_sde, s$class)
}

## Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Did the FCA's ban on insurance price-walking ",
  "(GIPP, January 2022) create a waterbed effect in motor and home insurance, ",
  "where new customer premiums rose to compensate for the loss of renewal overcharges? ",
  "\\textbf{Policy mechanism:} GIPP (ICOBS 6B) requires that renewal prices must not ",
  "exceed the Equivalent New Business Price, eliminating the practice of charging loyal ",
  "customers higher premiums than new customers in home and motor insurance markets. ",
  "\\textbf{Outcome definition:} Log Net Written Premium (quarterly, by line of business) ",
  "and Loss Ratio (claims incurred as percentage of premiums earned) from BoE data; ",
  "Claims Frequency and Complaints Rate (band midpoints) from FCA GI Value Measures. ",
  "\\textbf{Treatment:} Binary; GIPP-targeted lines (Motor liability, Motor other, Property) ",
  "vs.~non-targeted lines (8 other non-life classes). ",
  "\\textbf{Data:} Bank of England Insurance Aggregate Data (2017Q1--2025Q4, 396 line-quarter obs) ",
  "and FCA GI Value Measures (2021--2024, 1,636 firm-product-year obs). ",
  "\\textbf{Method:} Two-way fixed effects DiD (line + quarter FE), clustered at line level for BoE ",
  "and firm level for FCA data. ",
  "\\textbf{Sample:} 11 non-life insurance lines over 36 quarters (BoE); 184 firms across 55 product ",
  "categories over 3 years (FCA). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_file <- file.path(table_dir, "tabF1_sde.tex")
cat("\\begin{table}[H]\n\\centering\n",
    "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
    "\\label{tab:sde}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lcccccc}\n\\toprule\n",
    "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
    "\\midrule\n",
    "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
    fmt_row("log(NWP)", pooled_nwp), "\n",
    fmt_row("Loss Ratio (\\%)", pooled_lr), "\n",
    "\\midrule\n",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Motor vs.~Property)}} \\\\\n",
    fmt_row("log(NWP) --- Motor", motor_nwp_sde), "\n",
    fmt_row("log(NWP) --- Property", prop_nwp_sde), "\n",
    fmt_row("Loss Ratio --- Motor", motor_lr_sde), "\n",
    fmt_row("Loss Ratio --- Property", prop_lr_sde), "\n",
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n\\small\n",
    sde_notes, "\n",
    "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n",
    file = sde_file, sep = "")

cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
