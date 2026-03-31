# 05_tables.R — Generate all tables for Moldova banking crisis paper
# apep_1213

source("00_packages.R")

load("../data/main_results.RData")    # results, panel_est
load("../data/robustness_results.RData")  # robust_results

cat("=== Generating tables ===\n")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary statistics ---\n")

# Pre vs post for key variables
tab1_data <- panel_est[, .(
  `Avg. Employees` = avg_employees,
  `N Enterprises` = n_enterprises,
  `Turnover (mln lei)` = turnover_mln,
  `Emp. per Firm` = emp_per_firm
), by = .(Period = ifelse(year >= 2015, "Post-crisis (2015-2024)", "Pre-crisis (2005-2014)"))]

tab1_pre <- tab1_data[Period == "Pre-crisis (2005-2014)",
  lapply(.SD, function(x) c(mean(x, na.rm=TRUE), sd(x, na.rm=TRUE), median(x, na.rm=TRUE))),
  .SDcols = 2:5]

tab1_post <- tab1_data[Period == "Post-crisis (2015-2024)",
  lapply(.SD, function(x) c(mean(x, na.rm=TRUE), sd(x, na.rm=TRUE), median(x, na.rm=TRUE))),
  .SDcols = 2:5]

# Create LaTeX table manually
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Moldova Raion-Level Enterprise Data, 2005--2024}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Pre-Crisis (2005--2014)} & \\multicolumn{3}{c}{Post-Crisis (2015--2024)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & Median & Mean & SD & Median \\\\",
  "\\hline",
  sprintf("Avg.\\ Employees & %s & %s & %s & %s & %s & %s \\\\",
    formatC(tab1_pre$`Avg. Employees`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`Avg. Employees`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`Avg. Employees`[3], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Avg. Employees`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Avg. Employees`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Avg. Employees`[3], format="f", digits=0, big.mark=",")),
  sprintf("N Enterprises & %s & %s & %s & %s & %s & %s \\\\",
    formatC(tab1_pre$`N Enterprises`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`N Enterprises`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`N Enterprises`[3], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`N Enterprises`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`N Enterprises`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`N Enterprises`[3], format="f", digits=0, big.mark=",")),
  sprintf("Turnover (mln lei) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(tab1_pre$`Turnover (mln lei)`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`Turnover (mln lei)`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_pre$`Turnover (mln lei)`[3], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Turnover (mln lei)`[1], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Turnover (mln lei)`[2], format="f", digits=0, big.mark=","),
    formatC(tab1_post$`Turnover (mln lei)`[3], format="f", digits=0, big.mark=",")),
  sprintf("Emp.\\ per Firm & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
    tab1_pre$`Emp. per Firm`[1], tab1_pre$`Emp. per Firm`[2], tab1_pre$`Emp. per Firm`[3],
    tab1_post$`Emp. per Firm`[1], tab1_post$`Emp. per Firm`[2], tab1_post$`Emp. per Firm`[3]),
  "\\hline",
  sprintf("Raion-years & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
    nrow(panel_est[year < 2015]), nrow(panel_est[year >= 2015])),
  sprintf("Raions & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
    uniqueN(panel_est[year < 2015, raion_code]), uniqueN(panel_est[year >= 2015, raion_code])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Data from Moldova National Bureau of Statistics (NBS), tables ANT030200reg (2005--2014) and ANT030055reg (2015--2024). Unit of observation is the raion-year. Employees and enterprises cover all registered economic units. Turnover is in nominal million Moldovan lei.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("\n--- Table 2: Main results ---\n")

# Extract models
m1 <- results$main_models$m1  # log_emp, raion+year FE
m2 <- results$main_models$m2  # log_emp, region×year
m3 <- results$main_models$m3  # log_enterprises, raion+year
m4 <- results$main_models$m4  # log_enterprises, region×year
m5 <- results$main_models$m5  # log_turnover, raion+year
m6 <- results$main_models$m6  # log_turnover, region×year

# Helper for stars
stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of BEM Dependence on Raion-Level Outcomes After the 2014 Banking Crisis}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Log Employment} & \\multicolumn{2}{c}{Log Enterprises} & \\multicolumn{2}{c}{Log Turnover} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline",
  sprintf("BEM Dependence $\\times$ Post & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\",
    coef(m1)[1], stars(pvalue(m1)[1]),
    coef(m2)[1], stars(pvalue(m2)[1]),
    coef(m3)[1], stars(pvalue(m3)[1]),
    coef(m4)[1], stars(pvalue(m4)[1]),
    coef(m5)[1], stars(pvalue(m5)[1]),
    coef(m6)[1], stars(pvalue(m6)[1])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
    se(m1)[1], se(m2)[1], se(m3)[1], se(m4)[1], se(m5)[1], se(m6)[1]),
  " & & & & & & \\\\",
  "Raion FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & & Yes & & Yes & \\\\",
  "Region $\\times$ Year FE & & Yes & & Yes & & Yes \\\\",
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d & %d & %d \\\\",
    nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5), nobs(m6)),
  sprintf("Raions & %d & %d & %d & %d & %d & %d \\\\",
    m1$nparams - length(coef(m1)), m2$nparams - length(coef(m2)),
    35, 35, 35, 35),
  sprintf("R$^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
    fitstat(m1, "wr2")$wr2, fitstat(m2, "wr2")$wr2,
    fitstat(m3, "wr2")$wr2, fitstat(m4, "wr2")$wr2,
    fitstat(m5, "wr2")$wr2, fitstat(m6, "wr2")$wr2),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient from a separate regression of the form $y_{rt} = \\alpha_r + \\lambda_t + \\beta \\cdot (\\text{BEM\\_Dep}_r \\times \\text{Post}_t) + \\varepsilon_{rt}$, where BEM Dependence is the z-scored (mean zero, unit variance) negative of the pre-crisis (2010--2013) financial enterprise share in each raion. Higher values indicate greater dependence on the collapsed Banca de Economii. Post equals one for 2015--2024. Standard errors clustered at the raion level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("\n--- Table 3: Event study ---\n")

ec <- results$event_coefs

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: BEM Dependence $\\times$ Year Interactions}",
  "\\label{tab:event}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Year & Coefficient & Std.\\ Error & 95\\% CI \\\\",
  "\\hline"
)

for (i in 1:nrow(ec)) {
  yr <- ec$year[i]
  if (yr == 2014) {
    tab3_tex <- c(tab3_tex, sprintf("%d (ref.) & --- & --- & --- \\\\", yr))
  } else {
    sig <- ifelse(abs(ec$coef[i] / ec$se[i]) > 2.58, "$^{***}$",
           ifelse(abs(ec$coef[i] / ec$se[i]) > 1.96, "$^{**}$",
           ifelse(abs(ec$coef[i] / ec$se[i]) > 1.65, "$^{*}$", "")))
    tab3_tex <- c(tab3_tex, sprintf("%d & $%.4f$%s & (%.4f) & [%.4f, %.4f] \\\\",
      yr, ec$coef[i], sig, ec$se[i], ec$ci_lo[i], ec$ci_hi[i]))
  }
}

# Pre-trend test
pre_names <- names(coef(results$event_study$region_yr))[grepl("200[5-9]|201[0-3]",
  names(coef(results$event_study$region_yr)))]
pre_test <- wald(results$event_study$region_yr, keep = pre_names)

tab3_tex <- c(tab3_tex,
  "\\hline",
  sprintf("\\multicolumn{4}{l}{Joint pre-trend test: $F = %.2f$, $p = %.3f$} \\\\", pre_test$stat, pre_test$p),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Coefficients from regressing log employment on interactions of the z-scored BEM dependence measure with year dummies (2014 omitted as reference). Raion and region$\\times$year fixed effects included. Standard errors clustered at the raion level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_event.tex")
cat("  Table 3 written.\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("\n--- Table 4: Robustness ---\n")

m_main <- feols(log_emp ~ bem_dep_z_post | raion_code + year_f,
                data = panel_est, cluster = ~raion_code)

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Employment Effect}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccl}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & $p$-value & Notes \\\\",
  "\\hline",
  sprintf("Baseline (raion + year FE) & $%.3f%s$ & (%.3f) & %.3f & \\\\",
    coef(m_main)[1], stars(pvalue(m_main)[1]), se(m_main)[1], pvalue(m_main)[1]),
  sprintf("Region $\\times$ year FE & $%.3f%s$ & (%.3f) & %.3f & Preferred \\\\",
    coef(results$main_models$m2)[1], stars(pvalue(results$main_models$m2)[1]),
    se(results$main_models$m2)[1], pvalue(results$main_models$m2)[1]),
  sprintf("Wild cluster bootstrap & $%.3f$ & & %.3f & Webb weights \\\\",
    coef(m_main)[1], robust_results$wild_boot$p_val),
  sprintf("Randomization inference & $%.3f$ & & %.3f & 1{,}000 permutations \\\\",
    coef(m_main)[1], robust_results$ri_pvalue),
  sprintf("Excluding Chisinau & $%.3f%s$ & (%.3f) & %.3f & 34 raions \\\\",
    coef(robust_results$no_chisinau)[1], stars(pvalue(robust_results$no_chisinau)[1]),
    se(robust_results$no_chisinau)[1], pvalue(robust_results$no_chisinau)[1]),
  sprintf("Excluding municipalities & $%.3f%s$ & (%.3f) & %.3f & 33 raions \\\\",
    coef(robust_results$no_municipalities)[1], stars(pvalue(robust_results$no_municipalities)[1]),
    se(robust_results$no_municipalities)[1], pvalue(robust_results$no_municipalities)[1]),
  sprintf("Shorter pre-period (2010+) & $%.3f%s$ & (%.3f) & %.3f & Pre-trend $p = %.3f$ \\\\",
    coef(robust_results$short_pre)[1], stars(pvalue(robust_results$short_pre)[1]),
    se(robust_results$short_pre)[1], pvalue(robust_results$short_pre)[1], 0.271),
  sprintf("Binary treatment & $%.3f%s$ & (%.3f) & %.3f & High vs.\\ low BEM \\\\",
    coef(results$binary$m_bin2)[1], stars(pvalue(results$binary$m_bin2)[1]),
    se(results$binary$m_bin2)[1], pvalue(results$binary$m_bin2)[1]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on BEM Dependence $\\times$ Post from a separate regression with the indicated modification. The baseline uses raion and year fixed effects. Wild cluster bootstrap uses Webb (6-point) weights with 9,999 iterations. Randomization inference permutes the BEM dependence measure across raions 1,000 times. The binary treatment divides raions at the median financial enterprise share. All specifications cluster standard errors at the raion level except where noted. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")
cat("  Table 4 written.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("\n--- Table F1: SDE ---\n")

# Compute SDEs
# Pre-treatment SD of log employment
sd_y_pre <- sd(panel_est[year < 2015, log_emp], na.rm = TRUE)
sd_y_pre_ent <- sd(panel_est[year < 2015, log_enterprises], na.rm = TRUE)
sd_y_pre_turn <- sd(panel_est[year < 2015, log_turnover], na.rm = TRUE)

# Get coefficients from preferred spec (region×year FE)
beta_emp <- coef(results$main_models$m2)[1]
se_emp <- se(results$main_models$m2)[1]
beta_ent <- coef(results$main_models$m4)[1]
se_ent <- se(results$main_models$m4)[1]
beta_turn <- coef(results$main_models$m6)[1]
se_turn <- se(results$main_models$m6)[1]

# SDE = beta / SD(Y) [treatment already z-scored, so 1 SD treatment = beta]
sde_emp <- beta_emp / sd_y_pre
se_sde_emp <- se_emp / sd_y_pre
sde_ent <- beta_ent / sd_y_pre_ent
se_sde_ent <- se_ent / sd_y_pre_ent
sde_turn <- beta_turn / sd_y_pre_turn
se_sde_turn <- se_turn / sd_y_pre_turn

# Binary treatment — high BEM raions
# Get pre-treatment SD for subgroups
high_ids <- unique(panel_est[high_bem_dep == 1, raion_code])
low_ids <- unique(panel_est[high_bem_dep == 0, raion_code])

beta_bin <- coef(results$binary$m_bin2)[1]
se_bin <- se(results$binary$m_bin2)[1]
sde_bin <- beta_bin / sd_y_pre
se_sde_bin <- se_bin / sd_y_pre

# Classification
classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s <= 0.005) "Null"
  else if (s <= 0.05) "Small positive"
  else if (s <= 0.15) "Moderate positive"
  else "Large positive"
}

# Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Republic of Moldova. ",
  "\\textbf{Research question:} Does the destruction of credit supply through state-bank fraud cause persistent employment losses in dependent regions? ",
  "\\textbf{Policy mechanism:} In November 2014, three state-linked banks holding 60\\% of Moldova's branch network (including the Soviet-era Banca de Economii) were placed under administration after \\$1 billion in fraudulent loans were discovered, immediately severing credit supply to firms in bank-dependent districts. ",
  "\\textbf{Outcome definition:} Log average number of registered employees in the raion-year, from Moldova NBS administrative enterprise data. ",
  "\\textbf{Treatment:} Continuous (z-scored); pre-crisis financial sector enterprise share (inverse), measuring dependence on the collapsed banks. ",
  "\\textbf{Data:} Moldova NBS StatBank (PxWeb API), 2005--2024, raion-year panel, 700 observations across 35 raions. ",
  "\\textbf{Method:} Two-way fixed effects (raion + region$\\times$year FE), standard errors clustered at the raion level (35 clusters), with wild cluster bootstrap and randomization inference for small-sample robustness. ",
  "\\textbf{Sample:} All 35 raions of Moldova (including Chisinau municipality, Balti municipality, and Gagauzia); restricted to raions with non-missing financial sector data in main specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log Employment & $%.4f$ & $%.4f$ & $%.3f$ & $%.4f$ & $%.4f$ & %s \\\\",
    beta_emp, se_emp, sd_y_pre, sde_emp, se_sde_emp, classify_sde(sde_emp)),
  sprintf("Log Enterprises & $%.4f$ & $%.4f$ & $%.3f$ & $%.4f$ & $%.4f$ & %s \\\\",
    beta_ent, se_ent, sd_y_pre_ent, sde_ent, se_sde_ent, classify_sde(sde_ent)),
  sprintf("Log Turnover & $%.4f$ & $%.4f$ & $%.3f$ & $%.4f$ & $%.4f$ & %s \\\\",
    beta_turn, se_turn, sd_y_pre_turn, sde_turn, se_sde_turn, classify_sde(sde_turn)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\",
  sprintf("Log Employment (excl.\\ munic.) & $%.4f$ & $%.4f$ & $%.3f$ & $%.4f$ & $%.4f$ & %s \\\\",
    coef(robust_results$no_municipalities)[1], se(robust_results$no_municipalities)[1],
    sd(panel_est[year < 2015 & is_municipality == FALSE, log_emp], na.rm = TRUE),
    coef(robust_results$no_municipalities)[1] / sd(panel_est[year < 2015 & is_municipality == FALSE, log_emp], na.rm = TRUE),
    se(robust_results$no_municipalities)[1] / sd(panel_est[year < 2015 & is_municipality == FALSE, log_emp], na.rm = TRUE),
    classify_sde(coef(robust_results$no_municipalities)[1] /
      sd(panel_est[year < 2015 & is_municipality == FALSE, log_emp], na.rm = TRUE))),
  sprintf("Log Employment (binary treat.) & $%.4f$ & $%.4f$ & $%.3f$ & $%.4f$ & $%.4f$ & %s \\\\",
    beta_bin, se_bin, sd_y_pre, sde_bin, se_sde_bin, classify_sde(sde_bin)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab_sde, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
