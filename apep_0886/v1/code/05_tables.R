# =============================================================================
# 05_tables.R — Generate All LaTeX Tables
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/results_main.rds")
robust <- readRDS("../data/results_robust.rds")

# ---- Table 1: Descriptive Statistics ---- #
cat("=== Generating Table 1: Descriptive Statistics ===\n")

df_main <- panel %>% filter(industry_code %in% c("624", "311", "332"))

desc_stats <- df_main %>%
  group_by(
    Industry = case_when(
      industry_code == "624" ~ "Social Assistance (624)",
      TRUE ~ "Manufacturing (311, 332)"
    ),
    Sex = ifelse(sex == 2, "Female", "Male"),
    Period = ifelse(post == 0, "Pre-ARP (2019Q1--2021Q3)", "Post-ARP (2021Q4--2024Q3)")
  ) %>%
  summarise(
    `Mean Emp.` = round(mean(emp, na.rm = TRUE), 0),
    `SD Emp.` = round(sd(emp, na.rm = TRUE), 0),
    `Mean Earn.` = round(mean(earn, na.rm = TRUE), 0),
    `Mean Hires` = round(mean(hires, na.rm = TRUE), 0),
    N = n(),
    .groups = "drop"
  ) %>%
  arrange(Industry, Sex, Period)

# Generate LaTeX table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Descriptive Statistics: QWI Employment by Industry, Sex, and Period}",
  "\\label{tab:desc}",
  "\\begin{tabular}{llcrrrr}",
  "\\toprule",
  "Industry & Sex & Period & Mean Emp. & SD Emp. & Mean Earn. (\\$) & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(desc_stats))) {
  row <- desc_stats[i, ]
  line <- sprintf("%s & %s & %s & %s & %s & %s & %d \\\\",
    row$Industry, row$Sex, row$Period,
    format(row$`Mean Emp.`, big.mark = ","),
    format(row$`SD Emp.`, big.mark = ","),
    format(row$`Mean Earn.`, big.mark = ","),
    row$N)
  if (i %in% c(4, 8)) line <- paste0(line, "\n\\midrule")
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Employment (EmpS) is the count of stable quarterly employees. Earnings (EarnS) are average quarterly earnings. Data from the Quarterly Workforce Indicators (QWI) Sex $\\times$ Education panel, 2019Q1--2024Q3, aggregated to state $\\times$ industry $\\times$ sex $\\times$ quarter. Social Assistance (NAICS 624) includes childcare centers and social services. Manufacturing includes Food Manufacturing (311) and Fabricated Metal (332).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_descriptive.tex")
cat("Written: tables/tab1_descriptive.tex\n")

# ---- Table 2: Main DDD Results ---- #
cat("=== Generating Table 2: Main DDD Results ===\n")

m1 <- results$m1_ddd_emp
m2 <- results$m2_ddd_earn
m3 <- results$m3_ddd_hires
m5 <- results$m5_broad

# Extract stats
get_stat <- function(model, var = "ddd") {
  beta <- coef(model)[var]
  se_val <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(beta = beta, se = se_val, p = p, stars = stars)
}

s1 <- get_stat(m1, "ddd")
s2 <- get_stat(m2, "ddd")
s3 <- get_stat(m3, "ddd")
s5 <- get_stat(m5, "ddd_broad")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Main Results: Triple-Difference Estimates of ARP Childcare Stabilization Grants}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Emp. & Earnings (\\$) & Log Hires & Log Emp. \\\\",
  " & NAICS 624 & NAICS 624 & NAICS 624 & Broad Care \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Female $\\times$ Childcare & %s%s & %s%s & %s%s & %s%s \\\\",
    format(round(s1$beta, 4), nsmall = 4), s1$stars,
    format(round(s2$beta, 1), nsmall = 1), s2$stars,
    format(round(s3$beta, 4), nsmall = 4), s3$stars,
    format(round(s5$beta, 4), nsmall = 4), s5$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    format(round(s1$se, 4), nsmall = 4),
    format(round(s2$se, 1), nsmall = 1),
    format(round(s3$se, 4), nsmall = 4),
    format(round(s5$se, 4), nsmall = 4)),
  sprintf(" & [%s] & [%s] & [%s] & [%s] \\\\",
    format(round(s1$p, 4), nsmall = 4),
    format(round(s2$p, 4), nsmall = 4),
    format(round(s3$p, 4), nsmall = 4),
    format(round(s5$p, 4), nsmall = 4)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(m1), big.mark = ","),
    format(nobs(m2), big.mark = ","),
    format(nobs(m3), big.mark = ","),
    format(nobs(m5), big.mark = ",")),
  "State $\\times$ Industry $\\times$ Sex FE & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "Comparison industries & 311, 332 & 311, 332 & 311, 332 & 311, 332 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Triple-difference estimates. The coefficient of interest is Post $\\times$ Female $\\times$ Childcare, which measures the differential change in female employment (relative to male) in childcare industries (relative to manufacturing) after ARP stabilization grant disbursements began in 2021Q4. Columns (1)--(3) compare Social Assistance (NAICS 624) to Manufacturing (311, 332). Column (4) expands the childcare sector to include Education (611) and Nursing/Residential Care (623). Standard errors clustered at the state level in parentheses; $p$-values in brackets. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Written: tables/tab2_main.tex\n")

# ---- Table 3: Robustness Checks ---- #
cat("=== Generating Table 3: Robustness ===\n")

# Within-624 DD
s_w624 <- get_stat(robust$r1_within_624_emp, "post:female")
s_w624e <- get_stat(robust$r1_within_624_earn, "post:female")
# Placebo manufacturing
s_plac <- get_stat(robust$r2_placebo_mfg, "post:female")
# Pre-COVID
s_pcov <- get_stat(robust$r3_precovid, "ddd")
# High alloc
s_high <- get_stat(robust$r4_high_alloc, "ddd")
# Low alloc
s_low <- get_stat(robust$r4_low_alloc, "ddd")
# Active grant
s_act <- get_stat(robust$r5_expiry, "ddd_active")
# Expired grant
s_exp <- get_stat(robust$r5_expiry, "ddd_expired")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Mechanism Tests}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccl}",
  "\\toprule",
  "Specification & Coefficient & SE & Design \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Within-Sector Tests}} \\\\[3pt]",
  sprintf("Female $\\times$ Post (624 only, Log Emp.) & %s%s & (%s) & DD \\\\",
    format(round(s_w624$beta, 4), nsmall = 4), s_w624$stars,
    format(round(s_w624$se, 4), nsmall = 4)),
  sprintf("Female $\\times$ Post (624 only, Earnings) & %s%s & (%s) & DD \\\\",
    format(round(s_w624e$beta, 1), nsmall = 1), s_w624e$stars,
    format(round(s_w624e$se, 1), nsmall = 1)),
  sprintf("Female $\\times$ Post (Manufacturing, Log Emp.) & %s%s & (%s) & Placebo DD \\\\",
    format(round(s_plac$beta, 4), nsmall = 4), s_plac$stars,
    format(round(s_plac$se, 4), nsmall = 4)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sample Restrictions}} \\\\[3pt]",
  sprintf("DDD, excl.\\ COVID quarters & %s%s & (%s) & DDD \\\\",
    format(round(s_pcov$beta, 4), nsmall = 4), s_pcov$stars,
    format(round(s_pcov$se, 4), nsmall = 4)),
  sprintf("DDD, high-allocation states & %s%s & (%s) & DDD \\\\",
    format(round(s_high$beta, 4), nsmall = 4), s_high$stars,
    format(round(s_high$se, 4), nsmall = 4)),
  sprintf("DDD, low-allocation states & %s%s & (%s) & DDD \\\\",
    format(round(s_low$beta, 4), nsmall = 4), s_low$stars,
    format(round(s_low$se, 4), nsmall = 4)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Grant Expiration}} \\\\[3pt]",
  sprintf("DDD, active grant period & %s%s & (%s) & DDD \\\\",
    format(round(s_act$beta, 4), nsmall = 4), s_act$stars,
    format(round(s_act$se, 4), nsmall = 4)),
  sprintf("DDD, post-expiration & %s%s & (%s) & DDD \\\\",
    format(round(s_exp$beta, 4), nsmall = 4), s_exp$stars,
    format(round(s_exp$se, 4), nsmall = 4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A shows within-sector difference-in-differences (female vs.\\ male) for Social Assistance (624) and a placebo test using Manufacturing (311, 332). Panel B restricts the sample: excluding COVID-affected quarters (2020Q2--2021Q3), and splitting by above/below median state ARP allocation per capita. Panel C decomposes the post period into active grants (2021Q4--2023Q3) and post-expiration (2023Q4--2024Q3). All specifications include cell, industry$\\times$quarter, and state$\\times$quarter fixed effects. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Written: tables/tab3_robustness.tex\n")

# ---- Table 4: Event Study Coefficients ---- #
cat("=== Generating Table 4: Event Study ===\n")

m_es <- results$m_es
es_coefs <- coeftable(m_es)
es_rows <- rownames(es_coefs)
es_idx <- grep("female_childcare", es_rows)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Triple-Difference Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & Coefficient & SE & $p$-value \\\\",
  "\\midrule"
)

for (i in es_idx) {
  et_name <- sub("et::", "", sub(":female_childcare", "", es_rows[i]))
  beta_val <- es_coefs[i, 1]
  se_val <- es_coefs[i, 2]
  p_val <- es_coefs[i, 4]
  stars <- ifelse(p_val < 0.01, "***", ifelse(p_val < 0.05, "**", ifelse(p_val < 0.1, "*", "")))

  if (et_name == "-1") next  # Reference period

  line <- sprintf("$t = %s$ & %s%s & (%s) & %s \\\\",
    et_name,
    format(round(beta_val, 4), nsmall = 4), stars,
    format(round(se_val, 4), nsmall = 4),
    format(round(p_val, 4), nsmall = 4))

  # Add separator between pre and post
  if (et_name == "-2") {
    line <- paste0(line, "\n$t = -1$ & \\multicolumn{3}{c}{\\textit{(reference period)}} \\\\")
  }

  tab4_lines <- c(tab4_lines, line)
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dynamic triple-difference coefficients from interacting event-time dummies with Female $\\times$ Childcare (NAICS 624). Event time $t = 0$ corresponds to 2021Q4 (first quarter of ARP stabilization grant disbursements). Endpoints binned at $t \\leq -8$ and $t \\geq 10$. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("Written: tables/tab4_eventstudy.tex\n")

# ---- Table F1: Standardized Effect Sizes (SDE) ---- #
cat("=== Generating Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SDE = beta_hat / SD(Y) where SD(Y) is pre-treatment SD
pre_data <- df_main %>% filter(post == 0)

sd_log_emp <- sd(pre_data$log_emp, na.rm = TRUE)
sd_earn <- sd(pre_data$earn, na.rm = TRUE)
sd_log_hires <- sd(pre_data$log_hires, na.rm = TRUE)

sde_emp <- s1$beta / sd_log_emp
sde_earn <- s2$beta / sd_earn
sde_hires <- s3$beta / sd_log_hires

se_sde_emp <- s1$se / sd_log_emp
se_sde_earn <- s2$se / sd_earn
se_sde_hires <- s3$se / sd_log_hires

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
pooled_rows <- data.frame(
  Outcome = c("Log Employment", "Quarterly Earnings", "Log New Hires"),
  beta = c(s1$beta, s2$beta, s3$beta),
  se = c(s1$se, s2$se, s3$se),
  sd_y = c(sd_log_emp, sd_earn, sd_log_hires),
  sde = c(sde_emp, sde_earn, sde_hires),
  se_sde = c(se_sde_emp, se_sde_earn, se_sde_hires),
  stringsAsFactors = FALSE
)
pooled_rows$class <- sapply(pooled_rows$sde, classify_sde)

# Panel B: Heterogeneous (high vs low allocation)
s_high_emp <- get_stat(robust$r4_high_alloc, "ddd")
s_low_emp <- get_stat(robust$r4_low_alloc, "ddd")

sde_high <- s_high_emp$beta / sd_log_emp
sde_low <- s_low_emp$beta / sd_log_emp
se_sde_high <- s_high_emp$se / sd_log_emp
se_sde_low <- s_low_emp$se / sd_log_emp

het_rows <- data.frame(
  Outcome = c("Log Emp. (High Alloc.)", "Log Emp. (Low Alloc.)"),
  beta = c(s_high_emp$beta, s_low_emp$beta),
  se = c(s_high_emp$se, s_low_emp$se),
  sd_y = c(sd_log_emp, sd_log_emp),
  sde = c(sde_high, sde_low),
  se_sde = c(se_sde_high, se_sde_low),
  stringsAsFactors = FALSE
)
het_rows$class <- sapply(het_rows$sde, classify_sde)

all_sde <- bind_rows(pooled_rows, het_rows)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the American Rescue Plan's \\$24 billion childcare stabilization grants differentially affect female employment in care work industries relative to male employment? ",
  "\\textbf{Policy mechanism:} Federal grants disbursed through state CCDF agencies subsidized childcare provider operating costs and worker wages, intended to prevent provider closures and stabilize the care workforce during the pandemic recovery. ",
  "\\textbf{Outcome definition:} Log quarterly stable employment (EmpS), quarterly earnings (EarnS), and log quarterly new hires (HirN) from the Census Bureau Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary post indicator (2021Q4 onward) interacted with female and childcare-industry indicators in a triple-difference design. ",
  "\\textbf{Data:} QWI Sex $\\times$ Education panel, 50 states, 2019Q1--2024Q3, state $\\times$ industry $\\times$ sex $\\times$ quarter cells (N = 6,810). ",
  "\\textbf{Method:} Triple-difference (Post $\\times$ Female $\\times$ Childcare) with cell, industry$\\times$quarter, and state$\\times$quarter fixed effects; SEs clustered at state level. ",
  "\\textbf{Sample:} Social Assistance (NAICS 624) vs.\\ Manufacturing (311, 332); all private-sector employees; excludes Alaska (data unavailable). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in seq_len(nrow(pooled_rows))) {
  row <- pooled_rows[i, ]
  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    row$Outcome,
    format(round(row$beta, 4), nsmall = 4),
    format(round(row$se, 4), nsmall = 4),
    format(round(row$sd_y, 3), nsmall = 3),
    format(round(row$sde, 4), nsmall = 4),
    format(round(row$se_sde, 4), nsmall = 4),
    row$class)
  tabF1_lines <- c(tabF1_lines, line)
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by ARP allocation per capita)}} \\\\[3pt]"
)

for (i in seq_len(nrow(het_rows))) {
  row <- het_rows[i, ]
  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    row$Outcome,
    format(round(row$beta, 4), nsmall = 4),
    format(round(row$se, 4), nsmall = 4),
    format(round(row$sd_y, 3), nsmall = 3),
    format(round(row$sde, 4), nsmall = 4),
    format(round(row$se_sde, 4), nsmall = 4),
    row$class)
  tabF1_lines <- c(tabF1_lines, line)
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
