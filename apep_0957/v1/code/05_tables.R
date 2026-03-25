## 05_tables.R — Generate all tables including SDE appendix
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- df %>%
  group_by(naics56, hispanic) %>%
  summarise(
    N = n(),
    `Mean Emp` = round(mean(EmpS, na.rm = TRUE), 0),
    `SD Emp` = round(sd(EmpS, na.rm = TRUE), 0),
    `Mean Hire` = round(mean(HirA, na.rm = TRUE), 0),
    `Mean Earn/W` = round(mean(earn_pw, na.rm = TRUE), 0),
    `Pct EITC` = round(mean(has_eitc, na.rm = TRUE) * 100, 1),
    .groups = "drop"
  ) %>%
  mutate(
    Sector = ifelse(naics56 == 1, "Admin Support (56)", "Control Sectors"),
    Ethnicity = ifelse(hispanic == 1, "Hispanic", "Non-Hispanic")
  ) %>%
  select(Sector, Ethnicity, N, `Mean Emp`, `SD Emp`, `Mean Hire`, `Mean Earn/W`, `Pct EITC`)

# LaTeX summary statistics table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Sector and Ethnicity}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{llrrrrrr}\n")
cat("\\hline\\hline\n")
cat("Sector & Ethnicity & N & Mean Emp & SD Emp & Mean Hire & Earn/Worker & \\% EITC \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & \\$%s & %.1f \\\\\n",
              summ$Sector[i], summ$Ethnicity[i],
              formatC(summ$N[i], format = "d", big.mark = ","),
              formatC(summ$`Mean Emp`[i], format = "d", big.mark = ","),
              formatC(summ$`SD Emp`[i], format = "d", big.mark = ","),
              formatC(summ$`Mean Hire`[i], format = "d", big.mark = ","),
              formatC(summ$`Mean Earn/W`[i], format = "d", big.mark = ","),
              summ$`Pct EITC`[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Unit of observation is state $\\times$ industry $\\times$ ethnicity $\\times$ year. ")
cat("Admin Support is NAICS 56; control sectors are NAICS 44 (Retail), 52 (Finance), 54 (Professional), ")
cat("61 (Education), 62 (Health Care), 72 (Accommodation). ")
cat("Emp = stable employment (beginning-of-quarter); Hire = all hires; Earn/Worker = quarterly payroll ")
cat("divided by stable employment. \\% EITC = share of state-year observations with an active state EITC supplement.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Written tab1_summary.tex\n")

# ============================================================================
# Table 2: Main Triple-Difference Results
# ============================================================================
cat("\n=== Table 2: Main Results ===\n")

# Extract triple-diff coefficients
extract_coef <- function(model, label) {
  if (is.null(model)) return(tibble(Outcome = label, Estimate = NA, SE = NA, pval = NA, N = NA))
  ct <- as.data.frame(coeftable(model))
  target <- grep("has_eitc.*naics56.*hispanic", rownames(ct))
  if (length(target) == 0) {
    # Try alternative pattern
    target <- grep("naics56.*hispanic", rownames(ct))
  }
  if (length(target) == 0) return(tibble(Outcome = label, Estimate = NA, SE = NA, pval = NA, N = model$nobs))
  tibble(
    Outcome = label,
    Estimate = ct[target[1], 1],
    SE = ct[target[1], 2],
    pval = ct[target[1], 4],
    N = model$nobs
  )
}

main_tab <- bind_rows(
  extract_coef(results$twfe_emp, "ln(Employment)"),
  extract_coef(results$twfe_hire, "ln(Hiring)"),
  extract_coef(results$twfe_sep, "ln(Separations)")
)
# Add earnings only if available
if (!is.null(results$twfe_earn)) {
  main_tab <- bind_rows(main_tab, extract_coef(results$twfe_earn, "ln(Earnings/Worker)"))
}

# Stars function
stars <- function(p) {
  case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.1 ~ "*", TRUE ~ "")
}

ncols <- nrow(main_tab)
sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Triple-Difference Estimates: State EITC $\\times$ Admin Support $\\times$ Hispanic}\n")
cat("\\label{tab:main}\n")
cat(sprintf("\\begin{tabular}{l%s}\n", paste(rep("c", ncols), collapse = "")))
cat("\\hline\\hline\n")
cat(paste(" &", paste(sprintf("(%d)", 1:ncols), collapse = " & "), "\\\\\n"))
cat(paste(" &", paste(main_tab$Outcome, collapse = " & "), "\\\\\n"))
cat("\\hline\n")
cat(paste("EITC $\\times$ NAICS 56 $\\times$ Hispanic &",
          paste(sprintf("%.4f%s", main_tab$Estimate, stars(main_tab$pval)), collapse = " & "),
          "\\\\\n"))
cat(paste(" &",
          paste(sprintf("(%.4f)", main_tab$SE), collapse = " & "),
          "\\\\\n"))
cat("\\hline\n")
n_clusters <- n_distinct(df$state_fips)
cat(paste("State $\\times$ Year FE &", paste(rep("Yes", ncols), collapse = " & "), "\\\\\n"))
cat(paste("Industry $\\times$ Year FE &", paste(rep("Yes", ncols), collapse = " & "), "\\\\\n"))
cat(paste("State $\\times$ Industry $\\times$ Ethnicity FE &", paste(rep("Yes", ncols), collapse = " & "), "\\\\\n"))
cat(paste("Observations &",
          paste(formatC(main_tab$N, format = "d", big.mark = ","), collapse = " & "),
          "\\\\\n"))
cat(paste("Clusters (states) &",
          paste(rep(n_clusters, ncols), collapse = " & "),
          "\\\\\n"))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each column reports the triple-difference coefficient ")
cat("$\\hat{\\beta}_1$ from the specification in equation (1). Standard errors ")
cat("clustered at the state level in parentheses. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Written tab2_main.tex\n")

# ============================================================================
# Table 3: Callaway-Sant'Anna ATT
# ============================================================================
cat("\n=== Table 3: CS ATT ===\n")

cs_att <- results$cs_agg
cs_placebo <- results$placebo

sink("../tables/tab3_cs.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Callaway-Sant'Anna ATT: Hispanic Employment in Admin Support}\n")
cat("\\label{tab:cs}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & Hispanic & Non-Hispanic \\\\\n")
cat(" & (Treatment) & (Placebo) \\\\\n")
cat("\\hline\n")
cat(sprintf("Simple ATT & %.4f%s & %.4f%s \\\\\n",
            cs_att$overall.att, stars(cs_att$overall.se > 0 & abs(cs_att$overall.att / cs_att$overall.se) > 2.576),
            cs_placebo$overall.att, stars(cs_placebo$overall.se > 0 & abs(cs_placebo$overall.att / cs_placebo$overall.se) > 2.576)))
cat(sprintf(" & (%.4f) & (%.4f) \\\\\n",
            cs_att$overall.se, cs_placebo$overall.se))
cat("\\hline\n")
cat("Estimator & CS (2021) & CS (2021) \\\\\n")
cat("Control group & Never-treated & Never-treated \\\\\n")
cat("Method & DR & DR \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1) shows the Callaway \\& Sant'Anna (2021) simple ATT for Hispanic workers in ")
cat("NAICS 56 (Admin Support). Column (2) shows the placebo test using non-Hispanic workers in the same sector. ")
cat("DR = doubly robust estimation. Standard errors based on multiplier bootstrap.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Written tab3_cs.tex\n")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("\n=== Table 4: Robustness ===\n")

rob_cont <- coeftable(robust$continuous)
rob_alt <- coeftable(robust$alt_controls)
rob_fin <- coeftable(robust$finance_placebo)

get_triple <- function(ct) {
  target <- grep("(eitc|has_eitc).*(naics56|naics52).*hispanic", rownames(ct))
  if (length(target) == 0) return(list(est = NA, se = NA, p = NA))
  list(est = ct[target[1], 1], se = ct[target[1], 2], p = ct[target[1], 4])
}

r_cont <- get_triple(rob_cont)
r_alt <- get_triple(rob_alt)
r_fin <- get_triple(rob_fin)

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Baseline & Continuous & Alt Controls & Finance \\\\\n")
cat(" & TWFE & Treatment & (61, 62) & Placebo \\\\\n")
cat("\\hline\n")

baseline <- extract_coef(results$twfe_emp, "")

cat(sprintf("Triple-diff coef & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
            baseline$Estimate, stars(baseline$pval),
            r_cont$est, stars(r_cont$p),
            r_alt$est, stars(r_alt$p),
            r_fin$est, stars(r_fin$p)))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            baseline$SE, r_cont$se, r_alt$se, r_fin$se))

# LOO summary
loo <- robust$loo
cat(sprintf("\\hline\nLOO coef range & \\multicolumn{4}{c}{[%.4f, %.4f]} \\\\\n",
            min(loo$coef), max(loo$coef)))
cat(sprintf("LOO sign changes & \\multicolumn{4}{c}{%d / %d states} \\\\\n",
            sum(sign(loo$coef) != sign(median(loo$coef))), nrow(loo)))
if (!is.na(robust$boot_pval)) {
  cat(sprintf("Wild bootstrap $p$ & \\multicolumn{4}{c}{%.3f} \\\\\n", robust$boot_pval))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1) reproduces the baseline TWFE triple-difference from Table \\ref{tab:main}. ")
cat("Column (2) uses continuous EITC generosity (\\% of federal credit) instead of binary adoption. ")
cat("Column (3) uses NAICS 61 (Education) and 62 (Health Care) as control sectors instead of 52/54. ")
cat("Column (4) is a sector placebo using NAICS 52 (Finance) as the ``treated'' sector --- ")
cat("no effect expected since finance wages are above EITC eligibility. ")
cat("LOO = leave-one-out sensitivity dropping each treated state. ")
cat("All specifications include state $\\times$ year, industry $\\times$ year, and state $\\times$ industry $\\times$ ethnicity FEs. ")
cat("Standard errors clustered at state level. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Written tab4_robustness.tex\n")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
# ============================================================================
cat("\n=== Table F1: SDE ===\n")

# Compute SDE for each outcome
compute_sde <- function(model, df_sub, outcome_var, label) {
  if (is.null(model)) return(NULL)
  ct <- as.data.frame(coeftable(model))
  target <- grep("has_eitc.*naics56.*hispanic", rownames(ct))
  if (length(target) == 0) target <- grep("naics56.*hispanic", rownames(ct))
  if (length(target) == 0) return(NULL)
  beta <- ct[target[1], 1]
  se_beta <- ct[target[1], 2]

  # SD of outcome (pre-treatment, for treated group)
  pre_vals <- df_sub %>%
    filter(hispanic == 1 & naics56 == 1 & !has_eitc) %>%
    pull(!!sym(outcome_var))
  sd_y <- sd(pre_vals, na.rm = TRUE)

  if (is.na(sd_y) || sd_y == 0) return(NULL)

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  tibble(
    Outcome = label,
    beta = beta, se = se_beta, sd_y = sd_y,
    sde = sde, se_sde = se_sde,
    classification = classify
  )
}

sde_tab <- bind_rows(
  compute_sde(results$twfe_emp, df, "ln_emp", "ln(Employment)"),
  compute_sde(results$twfe_hire, df, "ln_hire", "ln(Hiring)"),
  compute_sde(results$twfe_sep, df, "ln_sep", "ln(Separations)")
)

# Heterogeneity: split by high-generosity vs low-generosity states
df_high <- df %>% filter(is.na(eitc_pct) | eitc_pct >= 0.20)
df_low <- df %>% filter(is.na(eitc_pct) | eitc_pct < 0.20)

m_high <- feols(
  ln_emp ~ has_eitc:naics56:hispanic +
    has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
    state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
  data = df_high, cluster = ~state_fips
)
m_low <- feols(
  ln_emp ~ has_eitc:naics56:hispanic +
    has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
    state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
  data = df_low, cluster = ~state_fips
)

sde_het <- bind_rows(
  compute_sde(m_high, df_high, "ln_emp", "ln(Emp) --- High generosity ($\\geq$20\\%)"),
  compute_sde(m_low, df_low, "ln_emp", "ln(Emp) --- Low generosity ($<$20\\%)")
)

# --- SDE notes string ---
n_treated_states <- n_distinct(df$state_fips[df$first_treat > 0 & df$first_treat >= 2000])
n_total_obs <- nrow(df)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state Earned Income Tax Credit supplements increase Hispanic employment in low-wage administrative support occupations relative to non-Hispanic workers and higher-wage sectors? ",
  "\\textbf{Policy mechanism:} State EITC supplements provide a refundable or nonrefundable tax credit equal to 3--45\\% of the federal EITC, directly increasing the after-tax return to work for low-income earners in the phase-in range and reducing the net cost of formal employment for workers near the eligibility threshold. ",
  "\\textbf{Outcome definition:} Log stable employment (beginning-of-quarter count from QWI) measuring workers employed at both the beginning and end of the quarter. ",
  "\\textbf{Treatment:} Binary indicator for whether a state has an active EITC supplement in a given year; 31 states adopted staggered over 1987--2022. ",
  "\\textbf{Data:} Census Bureau Quarterly Workforce Indicators (QWI) Race/Ethnicity panel, state $\\times$ industry $\\times$ ethnicity $\\times$ year, 2000--2022, ",
  formatC(n_total_obs, format = "d", big.mark = ","), " observations. ",
  "\\textbf{Method:} TWFE triple-difference (state EITC $\\times$ NAICS 56 $\\times$ Hispanic) with state$\\times$year, industry$\\times$year, and state$\\times$industry$\\times$ethnicity fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} States with $\\geq$15 years of non-missing QWI data; industries restricted to NAICS 44, 52, 54, 56, 61, 62, 72. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for Hispanic workers in NAICS 56. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in 1:nrow(sde_tab)) {
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              sde_tab$Outcome[i], sde_tab$beta[i], sde_tab$se[i],
              sde_tab$sd_y[i], sde_tab$sde[i], sde_tab$se_sde[i],
              sde_tab$classification[i]))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by EITC generosity)}} \\\\\n")
for (i in 1:nrow(sde_het)) {
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              sde_het$Outcome[i], sde_het$beta[i], sde_het$se[i],
              sde_het$sd_y[i], sde_het$sde[i], sde_het$se_sde[i],
              sde_het$classification[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables complete ===\n")
