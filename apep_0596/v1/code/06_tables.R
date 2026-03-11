## 06_tables.R — Generate all LaTeX tables
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Table 1: Summary statistics...\n")

# Summary stats for the analysis panel
sumstats <- panel[, .(
  Variable = c(
    "Total imports (\\$M)",
    "Canal-origin imports (\\$M)",
    "European imports (\\$M)",
    "Log total imports",
    "Canal share (pre-drought)",
    "Drought intensity",
    "Treatment (share $\\times$ intensity)",
    "Gas price (\\$/MMBtu)"
  ),
  Mean = c(
    mean(total_imports / 1e6, na.rm = TRUE),
    mean(Canal_dependent / 1e6, na.rm = TRUE),
    mean(European / 1e6, na.rm = TRUE),
    mean(log_imports, na.rm = TRUE),
    mean(canal_share, na.rm = TRUE),
    mean(drought_intensity, na.rm = TRUE),
    mean(treatment, na.rm = TRUE),
    mean(gas_price, na.rm = TRUE)
  ),
  SD = c(
    sd(total_imports / 1e6, na.rm = TRUE),
    sd(Canal_dependent / 1e6, na.rm = TRUE),
    sd(European / 1e6, na.rm = TRUE),
    sd(log_imports, na.rm = TRUE),
    sd(canal_share, na.rm = TRUE),
    sd(drought_intensity, na.rm = TRUE),
    sd(treatment, na.rm = TRUE),
    sd(gas_price, na.rm = TRUE)
  ),
  Min = c(
    min(total_imports / 1e6, na.rm = TRUE),
    min(Canal_dependent / 1e6, na.rm = TRUE),
    min(European / 1e6, na.rm = TRUE),
    min(log_imports, na.rm = TRUE),
    min(canal_share, na.rm = TRUE),
    min(drought_intensity, na.rm = TRUE),
    min(treatment, na.rm = TRUE),
    min(gas_price, na.rm = TRUE)
  ),
  Max = c(
    max(total_imports / 1e6, na.rm = TRUE),
    max(Canal_dependent / 1e6, na.rm = TRUE),
    max(European / 1e6, na.rm = TRUE),
    max(log_imports, na.rm = TRUE),
    max(canal_share, na.rm = TRUE),
    max(drought_intensity, na.rm = TRUE),
    max(treatment, na.rm = TRUE),
    max(gas_price, na.rm = TRUE)
  )
)]

tab1_tex <- kable(sumstats, format = "latex", booktabs = TRUE, digits = 2,
                  escape = FALSE,
                  caption = "Summary Statistics",
                  label = "summary") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = sprintf("N = %s port-months across %d ports, January 2019--December 2024. Canal share is the pre-drought (2019, 2021--2022) share of a port's total imports originating from Canal-dependent Asian countries. Drought intensity is 1 minus the ratio of actual to normal daily Canal transits. Imports in millions of US dollars.",
                              format(nrow(panel), big.mark = ","),
                              uniqueN(panel$PORT)),
           escape = FALSE, threeparttable = TRUE)

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================

cat("Table 2: Main results...\n")

# Use fixest's etable for clean LaTeX output
tab2_tex <- etable(m1, m2, m3, m4, m5,
       headers = c("Binary", "Continuous", "Port Trends", "Asinh", "Canal Imports"),
       tex = TRUE,
       style.tex = style.tex("aer"),
       title = "Main Results: Effect of Canal Dependence on Port Imports",
       label = "tab:main",
       notes = c("Standard errors clustered at the port level in parentheses.",
                 "All specifications include port and year-month fixed effects.",
                 "Canal exposure is the pre-drought Asian import share for East/Gulf Coast ports (zero for West Coast).",
                 "Drought intensity ranges from 0 (normal capacity) to 0.51 (peak disruption in Feb 2024).",
                 "Column 3 adds port-specific linear time trends.",
                 sprintf("N ports = %d.", uniqueN(panel$PORT)),
                 "* p<0.10, ** p<0.05, *** p<0.01."),
       fitstat = c("n", "r2", "f"),
       se.below = TRUE,
       depvar = TRUE)

# Wrap tabular in adjustbox to prevent overfull hbox
tab2_tex <- gsub("\\\\begin\\{tabular\\}", "\\\\begin{adjustbox}{max width=\\\\textwidth}\n\\\\begin{tabular}", tab2_tex)
tab2_tex <- gsub("\\\\end\\{tabular\\}", "\\\\end{tabular}\n\\\\end{adjustbox}", tab2_tex)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Triple Difference
# ============================================================

cat("Table 3: Triple difference...\n")

triple_results <- fread(file.path(data_dir, "triple_diff_results.csv"))

# Only use coefficients actually estimated (double_origin_drought absorbed by year_month^origin FE)
n_triple_coefs <- nrow(triple_results)
cat(sprintf("  Triple diff CSV has %d coefficients\n", n_triple_coefs))

# Build table rows dynamically based on what was estimated
triple_labels <- c(
  "triple_treat" = "Canal share $\\times$ Canal origin $\\times$ Drought",
  "double_canal_drought" = "Canal share $\\times$ Drought",
  "double_origin_drought" = "Canal origin $\\times$ Drought"
)

tab3_body <- character()
for (i in seq_len(n_triple_coefs)) {
  term_name <- triple_results$term[i]
  label <- triple_labels[term_name]
  if (is.na(label)) label <- term_name
  star <- ifelse(triple_results$pval[i] < 0.01, "***",
          ifelse(triple_results$pval[i] < 0.05, "**",
          ifelse(triple_results$pval[i] < 0.1, "*", "")))
  tab3_body <- c(tab3_body,
    sprintf("%s & %.4f%s \\\\", label, triple_results$coef[i], star),
    sprintf("& (%.4f) \\\\", triple_results$se[i]),
    "\\\\")
}

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Triple Difference: Canal vs European Origins}",
  "\\label{tab:triple}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "& Log imports \\\\",
  "\\midrule",
  tab3_body,
  sprintf("Port $\\times$ origin FE & Yes \\\\"),
  sprintf("Year-month $\\times$ origin FE & Yes \\\\"),
  sprintf("Observations & %s \\\\", format(m_triple$nobs, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the port level in parentheses. The triple interaction tests whether Canal-dependent Asian imports decline differentially at high-Canal-share ports during the drought, relative to European imports at the same ports. Canal origin $\\times$ Drought is absorbed by year-month $\\times$ origin fixed effects. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tab_dir, "tab3_triple.tex"))

# ============================================================
# TABLE 4: Diversion Results
# ============================================================

cat("Table 4: Diversion results...\n")

diversion <- fread(file.path(data_dir, "diversion_results.csv"))

# Match using grep since coast names include parenthetical descriptions
wc_row <- diversion[grepl("West Coast", coast)]
ec_row <- diversion[grepl("East/Gulf", coast)]

star_fn <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# West Coast uses asian_treatment, East/Gulf uses canal treatment
tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Trade Diversion: Imports by Coast}",
  "\\label{tab:diversion}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "& West Coast & East/Gulf Coast \\\\",
  "& (Diversion) & (Direct effect) \\\\",
  "\\midrule",
  sprintf("Treatment & %.4f%s & %.4f%s \\\\",
          wc_row$coef, star_fn(wc_row$pval),
          ec_row$coef, star_fn(ec_row$pval)),
  sprintf("& (%.4f) & (%.4f) \\\\",
          wc_row$se, ec_row$se),
  "\\\\",
  sprintf("Observations & %s & %s \\\\",
          format(wc_row$n, big.mark = ","),
          format(ec_row$n, big.mark = ",")),
  "Port FE & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log total imports. West Coast treatment is Asian import share $\\times$ drought intensity; East/Gulf treatment is Canal share $\\times$ drought intensity. Standard errors clustered at the port level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_diversion.tex"))

# ============================================================
# TABLE 5: Heterogeneity by Port Size
# ============================================================

cat("Table 5: Heterogeneity...\n")

tab5_tex <- etable(m_small, m_medium, m_large,
       headers = c("Small", "Medium", "Large"),
       tex = TRUE,
       style.tex = style.tex("aer"),
       title = "Heterogeneity by Port Size",
       label = "tab:het_size",
       notes = c("Ports divided into terciles by average monthly imports (2019--2022).",
                 "Standard errors clustered at the port level.",
                 "* p<0.10, ** p<0.05, *** p<0.01."),
       fitstat = c("n", "r2"),
       se.below = TRUE)

writeLines(tab5_tex, file.path(tab_dir, "tab5_heterogeneity.tex"))

# ============================================================
# TABLE C1: Robustness — Alternative Specifications
# ============================================================

cat("Table C1: Alternative specifications...\n")

# Build alt specs table manually for clean formatting
# Extract coefficients/SEs from model objects
get_coef_se <- function(m, varname = "treatment") {
  idx <- grep(varname, names(coef(m)), value = TRUE)[1]
  if (is.na(idx)) return(list(coef = NA, se = NA, pval = NA))
  b <- coef(m)[idx]
  s <- se(m)[idx]
  p <- 2 * pnorm(-abs(b / s))
  list(coef = b, se = s, pval = p)
}

star_fn <- function(p) {
  if (is.na(p)) return("")
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# Extract from each model
c1 <- get_coef_se(m_main)         # Baseline (log imports)
c2 <- get_coef_se(m_levels)       # Levels ($M)
c3 <- get_coef_se(m_season)       # Port x Month FE
c4 <- get_coef_se(m_nocovid)      # Excl. COVID
c5 <- get_coef_se(m_binary, "high_canal")  # Binary treatment

# Scale levels to millions for readability
c2$coef <- c2$coef / 1e6
c2$se <- c2$se / 1e6

tabC1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications}",
  "\\label{tab:alt_specs}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Baseline & Levels (\\$M) & Port$\\times$Month FE & Excl.\\ COVID & Binary \\\\",
  "\\midrule",
  sprintf("Treatment & %.4f%s & %.2f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          c1$coef, star_fn(c1$pval),
          c2$coef, star_fn(c2$pval),
          c3$coef, star_fn(c3$pval),
          c4$coef, star_fn(c4$pval),
          c5$coef, star_fn(c5$pval)),
  sprintf("& (%.4f) & (%.2f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          c1$se, c2$se, c3$se, c4$se, c5$se),
  "\\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(m_main$nobs, big.mark = ","),
          format(m_levels$nobs, big.mark = ","),
          format(m_season$nobs, big.mark = ","),
          format(m_nocovid$nobs, big.mark = ","),
          format(m_binary$nobs, big.mark = ",")),
  sprintf("R$^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m_main, "r2")[[1]],
          fitstat(m_levels, "r2")[[1]],
          fitstat(m_season, "r2")[[1]],
          fitstat(m_nocovid, "r2")[[1]],
          fitstat(m_binary, "r2")[[1]]),
  "Port FE & Yes & Yes & & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Port $\\times$ calendar-month FE & & & Yes & & \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\textit{Notes:} Col.~1 is the baseline from Table~2. Col.~2 uses levels (\\$M). Col.~3 adds port$\\times$calendar-month FE. Col.~4 excludes 2020. Col.~5 uses binary treatment (above-median Canal share $\\times$ drought indicator). SEs clustered at port level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.}",
  "\\end{table}"
)

writeLines(tabC1_lines, file.path(tab_dir, "tabC1_alt_specs.tex"))

# ============================================================
# TABLE C2: Robustness Summary
# ============================================================

cat("Table C2: Robustness summary...\n")

robust_all <- fread(file.path(data_dir, "all_robustness_summary.csv"))
boot_data <- fread(file.path(data_dir, "bootstrap_results.csv"))
placebo_data <- fread(file.path(data_dir, "placebo_results.csv"))
euro_data <- fread(file.path(data_dir, "euro_placebo_results.csv"))
ri_data_summary <- fread(file.path(data_dir, "ri_summary.csv"))

tabC2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Summary}",
  "\\label{tab:robust_summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Test & Coefficient & $p$-value & Result \\\\",
  "\\midrule",
  sprintf("\\textit{Inference} & & & \\\\"),
  sprintf("~~Wild cluster bootstrap & %.4f & %.4f & %s \\\\",
          boot_data$coef, boot_data$p_boot,
          ifelse(boot_data$p_boot < 0.05, "Significant", "Not significant")),
  sprintf("~~Randomization inference & %.4f & %.4f & %s \\\\",
          ri_data_summary$true_coef, ri_data_summary$ri_pval,
          ifelse(ri_data_summary$ri_pval < 0.05, "Significant", "Not significant")),
  "\\\\",
  sprintf("\\textit{Placebos} & & & \\\\"),
  sprintf("~~Timing placebo (2021--2022) & %.4f & %.4f & %s \\\\",
          placebo_data$coef, placebo_data$pval,
          ifelse(placebo_data$pval > 0.1, "Null (passes)", "Fails")),
  sprintf("~~European imports placebo & %.4f & %.4f & %s \\\\",
          euro_data$coef, euro_data$pval,
          ifelse(euro_data$pval > 0.1, "Null (passes)", "Fails")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Wild cluster bootstrap uses Webb weights with 999 replications. Randomization inference permutes Canal share across ports 999 times. Timing placebo applies the same specification to a fake drought period (July 2021--August 2022) using only pre-actual-drought data. European imports placebo tests whether non-Canal-dependent imports respond to the Canal share treatment.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabC2_lines, file.path(tab_dir, "tabC2_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Sizes (MANDATORY)
# ============================================================

cat("Table F1: Standardized effect sizes...\n")

# Extract from main specification (m2: continuous treatment DiD)
beta_main <- coef(m2)["treatment"]
se_main <- se(m2)["treatment"]
sd_y <- sd(panel$log_imports, na.rm = TRUE)
sd_x <- sd(panel$treatment, na.rm = TRUE)  # Continuous treatment

# SDE for continuous treatment: beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

# Also for Canal-origin imports (m5) — uses same treatment variable
beta_canal <- coef(m5)["treatment"]
se_canal <- se(m5)["treatment"]
sd_y_canal <- sd(panel$log_canal_imports, na.rm = TRUE)

# Same treatment variable SD as main spec
sde_canal <- beta_canal * sd_x / sd_y_canal
se_sde_canal <- se_canal * sd_x / sd_y_canal

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

sde_table <- data.table(
  Outcome = c("Log total imports", "Log Canal-origin imports"),
  Specification = c("Table 2, Col. 2", "Table 2, Col. 5"),
  Beta = c(beta_main, beta_canal),
  SD_X = c(sd_x, sd_x),
  SD_Y = c(sd_y, sd_y_canal),
  SDE = c(sde_main, sde_canal),
  SE_SDE = c(se_sde_main, se_sde_canal),
  Classification = c(classify_sde(sde_main), classify_sde(sde_canal))
)

# Write LaTeX
tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log total imports & Table 2, Col.~2 & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_table$Beta[1], sde_table$SD_X[1], sde_table$SD_Y[1],
          sde_table$SDE[1], sde_table$SE_SDE[1], sde_table$Classification[1]),
  sprintf("Log Canal-origin imports & Table 2, Col.~5 & $%.4f$ & %.4f & %.4f & $%.4f$ & %.4f & %s \\\\",
          sde_table$Beta[2], sde_table$SD_X[2], sde_table$SD_Y[2],
          sde_table$SDE[2], sde_table$SE_SDE[2], sde_table$Classification[2]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)",
  "to facilitate cross-study comparison of treatment effect magnitudes.",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$,",
  "which gives the effect of a one-standard-deviation change in the treatment variable,",
  "measured in standard deviations of the outcome.",
  "SD($Y$) and SD($X$) are unconditional standard deviations from Table~\\ref{tab:summary}.",
  "",
  "\\textbf{Research question:} How does Panama Canal drought-induced transit capacity reduction",
  "affect US port-level merchandise imports, exploiting differential Canal dependence across ports?",
  "\\textbf{Treatment:} Continuous interaction of pre-drought Canal share and monthly drought intensity.",
  sprintf("\\textbf{Data:} US Census International Trade API, January 2019--December 2024, %d ports, %s port-months.",
          uniqueN(panel$PORT), format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Continuous treatment DiD with port and year-month fixed effects, port-clustered SEs.",
  "\\textbf{Sample:} US customs districts with positive imports in at least one month during the sample period.",
  "",
  "Classification thresholds (7 categories): large negative ($< -0.15$), moderate negative",
  "($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),",
  "large positive ($> 0.15$).",
  "Classification labels refer to the magnitude of the standardized point estimate,",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$),",
  "not a failure to reject a null hypothesis.}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tab_dir, "tabF1_sde.tex"))
fwrite(sde_table, file.path(data_dir, "sde_table.csv"))

cat("\n=== All tables generated ===\n")
