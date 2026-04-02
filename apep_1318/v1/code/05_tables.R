# 05_tables.R — Generate all LaTeX tables
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

source("00_packages.R")
load("../data/models.RData")
load("../data/robustness_models.RData")
amld5 <- fread("../data/amld5_transposition_panel.csv")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

panel[, period := fifelse(year <= 2018, "Pre-Reform (2015--2018)",
                   fifelse(year >= 2020 & year <= 2021, "Transparency (2020--2021)",
                    fifelse(year >= 2022, "Post-CJEU (2022--2023)", "Transition (2019)")))]

panel[, group := fifelse(!is.na(register_closed_year), "Rolled Back", "Maintained")]

# Summary stats by group × period
ss <- panel[period != "Transition (2019)", .(
  N = .N,
  Countries = length(unique(geo)),
  `Mean Reg. Index` = round(mean(reg_index, na.rm = TRUE), 1),
  `SD Reg. Index` = round(sd(reg_index, na.rm = TRUE), 1)
), by = .(group, period)]

ss <- ss[order(group, period)]

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Quarterly Business Registration Index by Treatment Group}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{llcccc}",
  "\\toprule",
  " & Period & N & Countries & Mean & SD \\\\",
  "\\midrule"
)

for (g in c("Maintained", "Rolled Back")) {
  tab1_lines <- c(tab1_lines, paste0("\\textit{", g, "} & & & & & \\\\"))
  for (i in which(ss$group == g)) {
    tab1_lines <- c(tab1_lines, sprintf(" & %s & %d & %d & %.1f & %.1f \\\\",
                                         ss$period[i], ss$N[i], ss$Countries[i],
                                         ss$`Mean Reg. Index`[i], ss$`SD Reg. Index`[i]))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Quarterly business registration index (Eurostat \\texttt{sts\\_rb\\_q}), ",
         "seasonally and calendar adjusted, base year 2015 = 100. Total business economy (NACE B--S excl. O, S94). ",
         "``Rolled Back'' countries suspended public access to beneficial ownership registers following the CJEU ruling ",
         "of November 22, 2022: Austria, Belgium, Denmark, Germany, Ireland, Luxembourg, Malta, Netherlands. ",
         "``Maintained'' countries continued public access. 21 EU member states with available registration data."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")
cat("Table 1 saved.\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("=== Generating Table 2: Main DiD Results ===\n")

# Extract coefficients
get_coef_str <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  paste0(sprintf("%.4f%s", b, stars), " & (",  sprintf("%.4f", s), ")")
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Beneficial Ownership Transparency on Business Registrations}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{4}{c}{Log Registration Index} \\\\",
  "\\cmidrule(lr){2-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Public Register & %s & %s & & %s \\\\",
          get_coef_str(m1, "register_public"),
          get_coef_str(m2, "register_public"),
          get_coef_str(m4, "register_public")),
  " & & & & \\\\",
  sprintf("Rolled Back & & & %s & %s \\\\",
          get_coef_str(m3, "rolled_back"),
          get_coef_str(m4, "rolled_back")),
  "\\midrule",
  sprintf("Country FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Quarter FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Country Trends & No & Yes & No & No \\\\"),
  sprintf("Sample & Full & Full & Post-2021 & Full \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ",")),
  sprintf("Countries & 21 & 21 & 21 & 21 \\\\"),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "ar2")[[1]], fitstat(m2, "ar2")[[1]],
          fitstat(m3, "ar2")[[1]], fitstat(m4, "ar2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is log quarterly business registration index ",
         "(Eurostat \\texttt{sts\\_rb\\_q}, seasonally adjusted, 2015=100). ",
         "``Public Register'' equals one when a country's beneficial ownership register is publicly accessible ",
         "under AMLD5 transposition. ``Rolled Back'' equals one when a country suspended public access following ",
         "the CJEU ruling of November 22, 2022. Standard errors clustered by country in parentheses. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 saved.\n")

# ============================================================
# TABLE 3: Sector Placebo and Mechanism
# ============================================================
cat("=== Generating Table 3: Sector Tests ===\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Sector-Level Tests: Financial Services vs.\\ Manufacturing Placebo}",
  "\\label{tab:sectors}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Adoption Effect} & \\multicolumn{2}{c}{Reversal Effect} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Total & Manufacturing & Total & Manufacturing \\\\",
  " & Economy & (Placebo) & Economy & (Placebo) \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Public Register & %s & %s & & \\\\",
          get_coef_str(m1, "register_public"),
          get_coef_str(placebo_mfg, "register_public")),
  " & & & & \\\\",
  sprintf("Rolled Back & & & %s & %s \\\\",
          get_coef_str(m3, "rolled_back"),
          get_coef_str(placebo_mfg_rev, "rolled_back")),
  "\\midrule",
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Sample & Full & Full & Post-2021 & Post-2021 \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(placebo_mfg), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(placebo_mfg_rev), big.mark = ",")),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "ar2")[[1]], fitstat(placebo_mfg, "ar2")[[1]],
          fitstat(m3, "ar2")[[1]], fitstat(placebo_mfg_rev, "ar2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Columns (1) and (3) reproduce the main estimates from Table~\\ref{tab:main}. ",
         "Columns (2) and (4) replace the dependent variable with the manufacturing sector (NACE B--E) ",
         "registration index. Manufacturing serves as a placebo: ownership transparency should not affect ",
         "sectors without opacity-sensitive corporate structures. The similar reversal coefficients across ",
         "sectors suggest that post-CJEU registration declines in rolled-back countries reflect macroeconomic ",
         "conditions (e.g., the 2022--2023 European energy crisis) rather than transparency-specific effects. ",
         "Standard errors clustered by country. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_sectors.tex")
cat("Table 3 saved.\n")

# ============================================================
# TABLE 4: Robustness — Leave-One-Out and Permutation
# ============================================================
cat("=== Generating Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out and Permutation Inference}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Adoption & Reversal \\\\",
  " & Coefficient & Coefficient \\\\",
  "\\midrule",
  "\\textit{Panel A: Leave-One-Out} & & \\\\",
  sprintf("Baseline & %.4f & %.4f \\\\",
          coef(m4)["register_public"], coef(m4)["rolled_back"]),
  " & (%.4f) & (%.4f) \\\\",
  sprintf("Drop Austria & %.4f & %.4f \\\\",
          loo_results[dropped == "AT"]$adopt_coef, loo_results[dropped == "AT"]$reverse_coef),
  sprintf("Drop Germany & %.4f & %.4f \\\\",
          loo_results[dropped == "DE"]$adopt_coef, loo_results[dropped == "DE"]$reverse_coef),
  sprintf("Drop Ireland & %.4f & %.4f \\\\",
          loo_results[dropped == "IE"]$adopt_coef, loo_results[dropped == "IE"]$reverse_coef),
  sprintf("Drop Luxembourg & %.4f & %.4f \\\\",
          loo_results[dropped == "LU"]$adopt_coef, loo_results[dropped == "LU"]$reverse_coef),
  sprintf("Drop Netherlands & %.4f & %.4f \\\\",
          loo_results[dropped == "NL"]$adopt_coef, loo_results[dropped == "NL"]$reverse_coef),
  sprintf("Range & [%.3f, %.3f] & [%.3f, %.3f] \\\\",
          min(loo_results$adopt_coef), max(loo_results$adopt_coef),
          min(loo_results$reverse_coef), max(loo_results$reverse_coef)),
  "\\midrule",
  "\\textit{Panel B: Permutation Inference} & & \\\\",
  sprintf("Actual coefficient & & %.4f \\\\", actual_coef),
  sprintf("Permutation mean & & %.4f \\\\", mean(perm_coefs)),
  sprintf("Permutation SD & & %.4f \\\\", sd(perm_coefs)),
  sprintf("Two-sided $p$-value & & %.3f \\\\", perm_p),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Panel A reports coefficients from the full specification ",
         "(column 4 of Table~\\ref{tab:main}) dropping each rolled-back country in turn. ",
         "Panel B reports results from 1,000 random permutations of the rollback assignment ",
         "across countries (post-2021 sample). The two-sided $p$-value is the fraction of ",
         "permuted coefficients with absolute value exceeding the actual coefficient."),
  "\\end{tablenotes}",
  "\\end{table}"
)

# Fix the SE line
tab4_lines[12] <- sprintf(" & (%.4f) & (%.4f) \\\\",
                          se(m4)["register_public"], se(m4)["rolled_back"])

writeLines(tab4_lines, "../tables/tab4_robust.tex")
cat("Table 4 saved.\n")

# ============================================================
# TABLE F1: SDE Table (Appendix — Mandatory)
# ============================================================
cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs
# Pre-treatment SD of log_reg (2015-2018)
sd_y_pre <- sd(panel[year <= 2018]$log_reg, na.rm = TRUE)
# Pre-treatment SD of log_fdi
sd_fdi_pre <- sd(fdi_clean[year <= 2018]$log_fdi, na.rm = TRUE)

# Main outcomes
beta_adopt <- coef(m1)["register_public"]
se_adopt <- se(m1)["register_public"]
sde_adopt <- beta_adopt / sd_y_pre
se_sde_adopt <- se_adopt / sd_y_pre

beta_reverse <- coef(m3)["rolled_back"]
se_reverse <- se(m3)["rolled_back"]
sde_reverse <- beta_reverse / sd_y_pre
se_sde_reverse <- se_reverse / sd_y_pre

beta_fdi <- coef(m6)["register_public"]
se_fdi <- se(m6)["register_public"]
sde_fdi <- beta_fdi / sd_fdi_pre
se_sde_fdi <- se_fdi / sd_fdi_pre

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Heterogeneity: Maintained vs Rolled-Back countries
# Split sample for heterogeneity
panel_maint <- panel[is.na(register_closed_year)]
panel_rb <- panel[!is.na(register_closed_year)]

m_het_maint <- feols(log_reg ~ register_public | geo + time_id,
                     data = panel_maint, cluster = ~geo)
m_het_rb <- feols(log_reg ~ register_public | geo + time_id,
                  data = panel_rb, cluster = ~geo)

beta_maint <- coef(m_het_maint)["register_public"]
se_maint <- se(m_het_maint)["register_public"]
sde_maint <- beta_maint / sd_y_pre
se_sde_maint <- se_maint / sd_y_pre

beta_rb <- coef(m_het_rb)["register_public"]
se_rb <- se(m_het_rb)["register_public"]
sde_rb <- beta_rb / sd_y_pre
se_sde_rb <- se_rb / sd_y_pre

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (21 member states with quarterly registration data). ",
  "\\textbf{Research question:} Whether mandating public access to beneficial ownership registers ",
  "under the EU's Fifth Anti-Money Laundering Directive (AMLD5) deters new business formation. ",
  "\\textbf{Policy mechanism:} AMLD5 requires EU member states to make registers of companies' ",
  "ultimate beneficial owners publicly accessible, exposing ownership structures previously hidden ",
  "behind nominee directors and shell companies; the CJEU struck down public access in November 2022, ",
  "creating a natural reversal. ",
  "\\textbf{Outcome definition:} Eurostat quarterly business registration index (\\texttt{sts\\_rb\\_q}), ",
  "seasonally and calendar adjusted, base year 2015 = 100, measuring new enterprise registrations. ",
  "\\textbf{Treatment:} Binary indicator for whether the country's beneficial ownership register is ",
  "publicly accessible in a given quarter. ",
  "\\textbf{Data:} Eurostat quarterly business registrations, 21 EU countries, 2015--2023, ",
  "country-quarter observations (N = 2,928). ",
  "\\textbf{Method:} Two-way fixed effects (country + quarter), standard errors clustered by country. ",
  "\\textbf{Sample:} EU member states with available Eurostat registration index data; excludes UK ",
  "(always-treated pre-AMLD5). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2015--2018) ",
  "standard deviation of the log registration index (SD = ", sprintf("%.3f", sd_y_pre), "). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Registrations (adoption) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_adopt, se_adopt, sd_y_pre, sde_adopt, se_sde_adopt, classify_sde(sde_adopt)),
  sprintf("Registrations (reversal) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_reverse, se_reverse, sd_y_pre, sde_reverse, se_sde_reverse, classify_sde(sde_reverse)),
  sprintf("FDI inflows (adoption) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_fdi, se_fdi, sd_fdi_pre, sde_fdi, se_sde_fdi, classify_sde(sde_fdi)),
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (sample splits)} & & & & & & \\\\",
  sprintf("Maintained countries & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_maint, se_maint, sd_y_pre, sde_maint, se_sde_maint, classify_sde(sde_maint)),
  sprintf("Rolled-back countries & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          beta_rb, se_rb, sd_y_pre, sde_rb, se_sde_rb, classify_sde(sde_rb)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
