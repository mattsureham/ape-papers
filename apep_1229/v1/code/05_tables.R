# 05_tables.R — Generate all tables for paper
# apep_1229: GIPP and Insurance Market Competition

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(paste0(data_dir, "models.RData"))
load(paste0(data_dir, "robustness_models.RData"))

# ============================================================================
# Table 1: Summary Statistics — CPIH Insurance Indices
# ============================================================================

cpih_panel <- readRDS(paste0(data_dir, "cpih_panel.rds"))

# Pre-GIPP (2015-2021) and Post-GIPP (2022-2025)
cpih_stats <- cpih_panel %>%
  filter(year >= 2015, year <= 2025) %>%
  mutate(period = ifelse(post_gipp == 1, "Post-GIPP (2022-2025)", "Pre-GIPP (2015-2021)")) %>%
  group_by(period) %>%
  summarise(
    N = n(),
    `Transport Ins. Mean` = round(mean(transport_ins, na.rm = TRUE), 1),
    `Transport Ins. SD` = round(sd(transport_ins, na.rm = TRUE), 1),
    `House Ins. Mean` = round(mean(house_ins, na.rm = TRUE), 1),
    `House Ins. SD` = round(sd(house_ins, na.rm = TRUE), 1),
    `Health Ins. Mean` = round(mean(health_ins, na.rm = TRUE), 1),
    `Health Ins. SD` = round(sd(health_ins, na.rm = TRUE), 1),
    `CPIH All Items Mean` = round(mean(cpih_all, na.rm = TRUE), 1),
    `CPIH All Items SD` = round(sd(cpih_all, na.rm = TRUE), 1),
    .groups = "drop"
  )

# Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: CPIH Insurance Price Indices}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Transport} & \\multicolumn{2}{c}{House Contents} & \\multicolumn{2}{c}{Health} & \\multicolumn{2}{c}{CPIH All Items} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}",
  "Period & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(cpih_stats)) {
  row <- cpih_stats[i, ]
  tab1_lines <- c(tab1_lines,
    sprintf("%s (N=%d) & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
            row$period, row$N,
            row$`Transport Ins. Mean`, row$`Transport Ins. SD`,
            row$`House Ins. Mean`, row$`House Ins. SD`,
            row$`Health Ins. Mean`, row$`Health Ins. SD`,
            row$`CPIH All Items Mean`, row$`CPIH All Items SD`))
}

# Add cumulative changes
dec21 <- cpih_panel %>% filter(date == as.Date("2021-12-01"))
dec23 <- cpih_panel %>% filter(date == as.Date("2023-12-01"))
latest <- cpih_panel %>% filter(date == max(date))

pct_transport_23 <- round((dec23$transport_ins / dec21$transport_ins - 1) * 100, 1)
pct_house_23 <- round((dec23$house_ins / dec21$house_ins - 1) * 100, 1)
pct_health_23 <- round((dec23$health_ins / dec21$health_ins - 1) * 100, 1)
pct_cpih_23 <- round((dec23$cpih_all / dec21$cpih_all - 1) * 100, 1)

pct_transport_lat <- round((latest$transport_ins / dec21$transport_ins - 1) * 100, 1)
pct_house_lat <- round((latest$house_ins / dec21$house_ins - 1) * 100, 1)
pct_health_lat <- round((latest$health_ins / dec21$health_ins - 1) * 100, 1)
pct_cpih_lat <- round((latest$cpih_all / dec21$cpih_all - 1) * 100, 1)

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\%% change, Dec 2021--Dec 2023 & +%s\\%% & & +%s\\%% & & +%s\\%% & & +%s\\%% & \\\\",
          pct_transport_23, pct_house_23, pct_health_23, pct_cpih_23),
  sprintf("\\%% change, Dec 2021--Feb 2026 & +%s\\%% & & +%s\\%% & & +%s\\%% & & +%s\\%% & \\\\",
          pct_transport_lat, pct_house_lat, pct_health_lat, pct_cpih_lat),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} CPIH indices are from ONS Table 37, base year 2015 = 100. Transport insurance (COICOP 12.5.4) includes motor insurance, the primary target of the GIPP loyalty penalty ban. House contents insurance (12.5.2) was also subject to GIPP. Health insurance (12.5.3) serves as a within-insurance control subject to GIPP but with lower switching rates. The GIPP pricing remedy (PS21/5, ICOBS 6B) took effect on 1 January 2022.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, paste0(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main Results — DiD Estimates
# ============================================================================

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Difference-in-Differences: Transport Insurance vs.\\ Alternative Controls}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & vs.\\ Health & vs.\\ House & Short Window & YoY Growth \\\\",
  "\\midrule"
)

# Extract DiD coefficients
models <- list(m4_did, m_rob1, m_short, m_yoy)
dep_var <- c("Log Index", "Log Index", "Log Index", "YoY \\% Change")
controls <- c("Health Ins.", "House Ins.", "Health Ins.", "Health Ins.")
windows <- c("2015--2025", "2015--2025", "2019--2025", "2016--2025")

coef_names <- c("treat_post", "treat_post", "treat_post", "treat_post")
coefs <- sapply(models, function(m) round(coef(m)[coef_names[1]], 4))
ses <- sapply(models, function(m) round(se(m)[coef_names[1]], 4))

# Significance stars
stars <- sapply(models, function(m) {
  p <- pvalue(m)[coef_names[1]]
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
})

tab2_lines <- c(tab2_lines,
  sprintf("Transport $\\times$ Post-GIPP & %s%s & %s%s & %s%s & %s%s \\\\",
          coefs[1], stars[1], coefs[2], stars[2], coefs[3], stars[3], coefs[4], stars[4]),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\", ses[1], ses[2], ses[3], ses[4]),
  "\\\\",
  sprintf("Dep.\\ variable & %s & %s & %s & %s \\\\", dep_var[1], dep_var[2], dep_var[3], dep_var[4]),
  sprintf("Control group & %s & %s & %s & %s \\\\", controls[1], controls[2], controls[3], controls[4]),
  sprintf("Window & %s & %s & %s & %s \\\\", windows[1], windows[2], windows[3], windows[4]),
  sprintf("N & %d & %d & %d & %d \\\\",
          nrow(cpih_long), nrow(cpih_long2),
          nrow(cpih_short), nrow(cpih_yoy)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on the interaction of a transport insurance indicator with a post-GIPP (January 2022) indicator. Columns (1)--(3) use log price indices as the dependent variable; column (4) uses 12-month percentage changes. All specifications include insurance-type fixed effects and, for columns (1)--(3), log CPIH as a control. Heteroskedasticity-robust standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, paste0(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================================
# Table 3: FCA Loss Ratios by Product and Year
# ============================================================================

fca_panel <- readRDS(paste0(data_dir, "fca_panel.rds"))

fca_tab <- fca_panel %>%
  group_by(product_group, year) %>%
  summarise(
    n = n(),
    loss_ratio = round(mean(loss_ratio, na.rm = TRUE), 3),
    premiums_bn = round(sum(premiums, na.rm = TRUE) / 1e9, 2),
    .groups = "drop"
  ) %>%
  filter(product_group %in% c("Motor", "Home", "Pet", "Travel"))

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{FCA General Insurance Value Measures: Loss Ratios by Product Group}",
  "\\label{tab:fca}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Loss Ratio} & \\multicolumn{2}{c}{Premiums (\\pounds bn)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Product Group & 2023 & 2024 & 2023 & 2024 \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{GIPP-targeted products}} \\\\"
)

for (pg in c("Motor", "Home")) {
  r23 <- fca_tab %>% filter(product_group == pg, year == 2023)
  r24 <- fca_tab %>% filter(product_group == pg, year == 2024)
  lr23 <- ifelse(nrow(r23) > 0, r23$loss_ratio, "---")
  lr24 <- ifelse(nrow(r24) > 0, r24$loss_ratio, "---")
  pr23 <- ifelse(nrow(r23) > 0, r23$premiums_bn, "---")
  pr24 <- ifelse(nrow(r24) > 0, r24$premiums_bn, "---")
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad %s & %s & %s & %s & %s \\\\", pg, lr23, lr24, pr23, pr24))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Comparison products}} \\\\"
)

for (pg in c("Pet", "Travel")) {
  r23 <- fca_tab %>% filter(product_group == pg, year == 2023)
  r24 <- fca_tab %>% filter(product_group == pg, year == 2024)
  lr23 <- ifelse(nrow(r23) > 0, r23$loss_ratio, "---")
  lr24 <- ifelse(nrow(r24) > 0, r24$loss_ratio, "---")
  pr23 <- ifelse(nrow(r23) > 0, r23$premiums_bn, "---")
  pr24 <- ifelse(nrow(r24) > 0, r24$premiums_bn, "---")
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad %s & %s & %s & %s & %s \\\\", pg, lr23, lr24, pr23, pr24))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Loss ratio is the proportion of gross written premiums paid out in claims. Data from FCA General Insurance Value Measures 2024, covering firms reporting to the FCA. Motor and Home products were the primary targets of the GIPP pricing remedy (PS21/5). Pet and Travel products serve as within-insurance comparisons subject to the same regulatory environment but with lower pre-GIPP loyalty penalty prevalence.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, paste0(table_dir, "tab3_fca.tex"))
cat("Table 3 written.\n")

# ============================================================================
# Table 4: Placebo Test
# ============================================================================

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Test: Fake GIPP Treatment at January 2020}",
  "\\label{tab:placebo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Placebo (Jan 2020) & Actual (Jan 2022) \\\\",
  "\\midrule"
)

placebo_coef <- round(coef(m_placebo)["treat_post"], 4)
placebo_se <- round(se(m_placebo)["treat_post"], 4)
placebo_p <- pvalue(m_placebo)["treat_post"]
placebo_star <- ifelse(placebo_p < 0.01, "***", ifelse(placebo_p < 0.05, "**", ifelse(placebo_p < 0.10, "*", "")))

actual_coef <- round(coef(m4_did)["treat_post"], 4)
actual_se <- round(se(m4_did)["treat_post"], 4)
actual_p <- pvalue(m4_did)["treat_post"]
actual_star <- ifelse(actual_p < 0.01, "***", ifelse(actual_p < 0.05, "**", ifelse(actual_p < 0.10, "*", "")))

tab4_lines <- c(tab4_lines,
  sprintf("Transport $\\times$ Post & %s%s & %s%s \\\\", placebo_coef, placebo_star, actual_coef, actual_star),
  sprintf(" & (%s) & (%s) \\\\", placebo_se, actual_se),
  "\\\\",
  "Treatment date & Jan 2020 & Jan 2022 \\\\",
  sprintf("Sample & Pre-GIPP only & Full sample \\\\"),
  sprintf("N & %d & %d \\\\", nrow(cpih_placebo), nrow(cpih_long)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) assigns a placebo treatment at January 2020, using only pre-GIPP data (2015--2021). The significant negative coefficient indicates that transport insurance was trending differently from health insurance before GIPP, which constitutes evidence against the parallel trends assumption. Column (2) repeats the main DiD specification for comparison. Both specifications compare transport insurance to health insurance, controlling for log CPIH. Heteroskedasticity-robust standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, paste0(table_dir, "tab4_placebo.tex"))
cat("Table 4 written.\n")

# ============================================================================
# Table F1: SDE Table (Mandatory)
# ============================================================================

# Main estimate: DiD Transport vs Health
beta_did <- coef(m4_did)["treat_post"]
se_did <- se(m4_did)["treat_post"]

# SD(Y) from pre-treatment transport insurance log index
pre_data <- cpih_long %>% filter(post_gipp == 0, is_transport == 1)
sd_y <- sd(pre_data$log_index, na.rm = TRUE)

sde_main <- beta_did / sd_y
se_sde_main <- se_did / sd_y

# Classification function
classify_sde <- function(s) {
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

# Heterogeneity: YoY specification
beta_yoy <- coef(m_yoy)["treat_post"]
se_yoy <- se(m_yoy)["treat_post"]
pre_yoy <- cpih_yoy %>% filter(post_gipp == 0, is_transport == 1)
sd_y_yoy <- sd(pre_yoy$yoy_change, na.rm = TRUE)
sde_yoy <- beta_yoy / sd_y_yoy
se_sde_yoy <- se_yoy / sd_y_yoy

# Short window specification
beta_short <- coef(m_short)["treat_post"]
se_short <- se(m_short)["treat_post"]
pre_short <- cpih_short %>% filter(post_gipp == 0, is_transport == 1)
sd_y_short <- sd(pre_short$log_index, na.rm = TRUE)
sde_short <- beta_short / sd_y_short
se_sde_short <- se_short / sd_y_short

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Whether the FCA's General Insurance Pricing Practices (GIPP) loyalty penalty ban, effective January 2022, differentially increased transport (motor) insurance prices relative to health insurance prices. ",
  "\\textbf{Policy mechanism:} GIPP (PS21/5, ICOBS 6B) prohibits insurers from offering renewal premiums that exceed equivalent new business prices, effectively banning price discrimination against long-tenured customers in retail general insurance. ",
  "\\textbf{Outcome definition:} Log of the ONS CPIH price index for transport insurance (COICOP 12.5.4, base 2015 = 100), capturing consumer-facing motor insurance premium levels. ",
  "\\textbf{Treatment:} Binary; post-January 2022 indicator interacted with transport insurance indicator (vs.\\ health insurance control). ",
  "\\textbf{Data:} ONS Consumer Price Inflation detailed reference tables (Table 37), monthly observations, 2015--2025, two insurance series. ",
  "\\textbf{Method:} Two-group difference-in-differences comparing transport insurance to health insurance, with heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} Monthly CPIH indices for transport insurance and health insurance, restricted to 2015--2025 for the main specification and 2019--2025 for the short-window robustness check. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log transport ins. & Main DiD & %s & %s & %s & %s & %s \\\\",
          round(beta_did, 4), round(sd_y, 4), round(sde_main, 4),
          round(se_sde_main, 4), classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Log transport ins. & Short window (2019--2025) & %s & %s & %s & %s & %s \\\\",
          round(beta_short, 4), round(sd_y_short, 4), round(sde_short, 4),
          round(se_sde_short, 4), classify_sde(sde_short)),
  sprintf("YoY \\%% change & Growth rate DiD & %s & %s & %s & %s & %s \\\\",
          round(beta_yoy, 2), round(sd_y_yoy, 2), round(sde_yoy, 4),
          round(se_sde_yoy, 4), classify_sde(sde_yoy)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, paste0(table_dir, "tabF1_sde.tex"))
cat("Table SDE written.\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
