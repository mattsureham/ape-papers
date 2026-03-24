## 05_tables.R — Generate all tables for the paper
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/main_results.RData")
load("../data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

# Pre-treatment means for treated vs comparison states
pre_data <- panel %>%
  mutate(treated_ever = ifelse(g > 0, "Treated", "Comparison")) %>%
  filter(treated == 0)  # pre-treatment only

summ <- pre_data %>%
  group_by(treated_ever) %>%
  summarise(
    `N (state-years)` = as.character(n()),
    `States` = as.character(n_distinct(state_fips)),
    `Nonemployer Estab. (311)` = sprintf("%.0f (%.0f)", mean(estab_311, na.rm = TRUE), sd(estab_311, na.rm = TRUE)),
    `Nonemployer Estab. per 100K` = sprintf("%.1f (%.1f)", mean(estab_311_pc, na.rm = TRUE), sd(estab_311_pc, na.rm = TRUE)),
    `Bakery Estab. (3118)` = sprintf("%.0f (%.0f)", mean(estab_3118, na.rm = TRUE), sd(estab_3118, na.rm = TRUE)),
    `Employer Estab. (311)` = sprintf("%.0f (%.0f)", mean(employer_estab_311, na.rm = TRUE), sd(employer_estab_311, na.rm = TRUE)),
    `Receipts ($1000)` = sprintf("%.0f (%.0f)", mean(receipts_311, na.rm = TRUE)/1000, sd(receipts_311, na.rm = TRUE)/1000),
    `Population (millions)` = sprintf("%.2f (%.2f)", mean(population, na.rm = TRUE)/1e6, sd(population, na.rm = TRUE)/1e6),
    .groups = "drop"
  )

# Transpose for LaTeX
summ_t <- summ %>%
  pivot_longer(-treated_ever, names_to = "Variable", values_to = "value") %>%
  pivot_wider(names_from = treated_ever, values_from = value)

cat("\nTable 1: Summary Statistics\n")
print(summ_t)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Pre-Treatment Means}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Treated States & Comparison States \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ_t)) {
  cat(sprintf("%s & %s & %s \\\\\n",
      summ_t$Variable[i],
      summ_t$Treated[i],
      summ_t$Comparison[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Standard deviations in parentheses. ")
cat("Treated states are those that adopted or significantly expanded cottage food laws during 2012--2022. ")
cat("Comparison states had pre-existing cottage food laws before the panel window. ")
cat("Nonemployer establishments from Census Nonemployer Statistics; employer establishments from County Business Patterns. ")
cat("NAICS 311 = Food Manufacturing; NAICS 3118 = Bakeries and Tortilla Manufacturing.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# =============================================================================
# TABLE 2: Main DiD Results
# =============================================================================

# Extract CS results
cs_att <- cs_agg_simple$overall.att
cs_se <- cs_agg_simple$overall.se
cs_pval <- 2 * pnorm(-abs(cs_att / cs_se))

cs_att_pc <- cs_agg_pc$overall.att
cs_se_pc <- cs_agg_pc$overall.se

cs_att_rec <- cs_agg_receipts$overall.att
cs_se_rec <- cs_agg_receipts$overall.se

# Stars function
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

format_coef <- function(est, se) {
  pval <- 2 * pnorm(-abs(est / se))
  sprintf("%.4f%s", est, stars(pval))
}

format_se <- function(se) {
  sprintf("(%.4f)", se)
}

sink("../tables/tab2_main_results.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Cottage Food Laws on Food Micro-Entrepreneurship}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Log Establishments} & Estab. per 100K & Log Receipts \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}\n")
cat(" & TWFE & CS DiD & CS DiD & CS DiD \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

# TWFE
twfe_est <- coef(twfe_estab)["treated"]
twfe_se_val <- se(twfe_estab)["treated"]
twfe_pval <- pvalue(twfe_estab)["treated"]

cat(sprintf("Cottage Food Law & %s & %s & %s & %s \\\\\n",
    format_coef(twfe_est, twfe_se_val),
    format_coef(cs_att, cs_se),
    format_coef(cs_att_pc, cs_se_pc),
    format_coef(cs_att_rec, cs_se_rec)))
cat(sprintf(" & %s & %s & %s & %s \\\\\n",
    format_se(twfe_se_val),
    format_se(cs_se),
    format_se(cs_se_pc),
    format_se(cs_se_rec)))

cat("\\hline\n")
cat(sprintf("Observations & %d & %d & %d & %d \\\\\n",
    nrow(panel), nrow(panel), nrow(panel), nrow(panel)))
cat(sprintf("States & %d & %d & %d & %d \\\\\n",
    n_distinct(panel$state_fips), n_distinct(panel$state_fips),
    n_distinct(panel$state_fips), n_distinct(panel$state_fips)))
cat("State FE & Yes & -- & -- & -- \\\\\n")
cat("Year FE & Yes & -- & -- & -- \\\\\n")
cat("Estimator & TWFE & CS (2021) & CS (2021) & CS (2021) \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$. ")
cat("Column 1 reports two-way fixed effects estimates with standard errors clustered at the state level. ")
cat("Columns 2--4 report Callaway and Sant'Anna (2021) doubly-robust estimates using not-yet-treated ")
cat("states as the comparison group, with 1,000 bootstrap iterations for inference. ")
cat("The treatment indicator equals one after a state adopts or significantly expands its cottage food law. ")
cat("NAICS 311 (Food Manufacturing) nonemployer establishments from Census Nonemployer Statistics, 2012--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# =============================================================================
# TABLE 3: Mechanism and Placebo Tests
# =============================================================================

# Bakery results
if (!is.null(cs_agg_bakery)) {
  bakery_att <- cs_agg_bakery$overall.att
  bakery_se <- cs_agg_bakery$overall.se
} else {
  bakery_att <- NA
  bakery_se <- NA
}

# Placebo results
if (!is.null(cs_agg_placebo)) {
  placebo_att <- cs_agg_placebo$overall.att
  placebo_se <- cs_agg_placebo$overall.se
} else {
  placebo_att <- NA
  placebo_se <- NA
}

sink("../tables/tab3_mechanism.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Mechanism and Placebo Tests}\n")
cat("\\label{tab:mechanism}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & Bakeries (3118) & Food Mfg (311) & Employer Estab. (311) \\\\\n")
cat(" & Mechanism & Main & Placebo \\\\\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat("\\hline\n")

cat(sprintf("Cottage Food Law & %s & %s & %s \\\\\n",
    ifelse(!is.na(bakery_att), format_coef(bakery_att, bakery_se), "--"),
    format_coef(cs_att, cs_se),
    ifelse(!is.na(placebo_att), format_coef(placebo_att, placebo_se), "--")))
cat(sprintf(" & %s & %s & %s \\\\\n",
    ifelse(!is.na(bakery_se), format_se(bakery_se), ""),
    format_se(cs_se),
    ifelse(!is.na(placebo_se), format_se(placebo_se), "")))

cat("\\hline\n")
cat("Estimator & CS (2021) & CS (2021) & CS (2021) \\\\\n")
cat("Outcome & Log Estab. & Log Estab. & Log Estab. \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$. ")
cat("All columns report Callaway and Sant'Anna (2021) doubly-robust ATT estimates. ")
cat("Column 1 tests the mechanism: bakeries (NAICS 3118) are the food subcategory most directly ")
cat("affected by cottage food laws. Column 2 reproduces the main result. Column 3 is a placebo: ")
cat("employer food manufacturing establishments (County Business Patterns) should not respond to ")
cat("laws targeting unlicensed home producers.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# =============================================================================
# TABLE 4: Robustness
# =============================================================================

# Sun-Abraham ATT
sa_coefs <- coef(sa_estab)
sa_ses <- se(sa_estab)
# Get the aggregated ATT
sa_att_val <- sa_agg$coeftable[nrow(sa_agg$coeftable), 1]
sa_se_val <- sa_agg$coeftable[nrow(sa_agg$coeftable), 2]

# First adoption only
first_est <- coef(twfe_first)["treated_first"]
first_se_val <- se(twfe_first)["treated_first"]

# Major expansion only
expand_est <- coef(twfe_expand)["treated_expand"]
expand_se_val <- se(twfe_expand)["treated_expand"]

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Alternative Estimators and Treatment Definitions}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & TWFE & CS (2021) & Sun-Abraham & First Adoption & Major Expansion \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("\\hline\n")

cat(sprintf("Cottage Food Law & %s & %s & %s & %s & %s \\\\\n",
    format_coef(twfe_est, twfe_se_val),
    format_coef(cs_att, cs_se),
    format_coef(sa_att_val, sa_se_val),
    format_coef(first_est, first_se_val),
    format_coef(expand_est, expand_se_val)))
cat(sprintf(" & %s & %s & %s & %s & %s \\\\\n",
    format_se(twfe_se_val),
    format_se(cs_se),
    format_se(sa_se_val),
    format_se(first_se_val),
    format_se(expand_se_val)))

cat("\\hline\n")
cat("Estimator & TWFE & CS DR & SA IW & TWFE & TWFE \\\\\n")
cat("Treatment def. & All events & All events & All events & First adoption & Expansion \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$. ")
cat("Dependent variable: log nonemployer food manufacturing establishments (NAICS 311). ")
cat("Column 1: two-way FE. Column 2: Callaway-Sant'Anna doubly-robust. Column 3: Sun-Abraham ")
cat("interaction-weighted. Column 4: restricts treatment to states adopting their first cottage food law. ")
cat("Column 5: restricts to states that significantly expanded existing laws. ")
cat("All standard errors clustered at the state level.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# =============================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# =============================================================================

# Compute SDEs
# SDE = beta_hat / SD(Y) where SD(Y) is pre-treatment SD
pre_panel <- panel %>% filter(treated == 0)
sd_ln_estab <- sd(pre_panel$ln_estab_311, na.rm = TRUE)
sd_estab_pc <- sd(pre_panel$estab_311_pc, na.rm = TRUE)
sd_ln_receipts <- sd(pre_panel$ln_receipts_311, na.rm = TRUE)
sd_ln_bakery <- sd(pre_panel$ln_estab_3118, na.rm = TRUE)
sd_ln_employer <- sd(pre_panel$ln_employer_estab_311, na.rm = TRUE)

# Main outcomes
sde_estab <- cs_att / sd_ln_estab
se_sde_estab <- cs_se / sd_ln_estab

sde_estab_pc <- cs_att_pc / sd_estab_pc
se_sde_estab_pc <- cs_se_pc / sd_estab_pc

sde_receipts <- cs_att_rec / sd_ln_receipts
se_sde_receipts <- cs_se_rec / sd_ln_receipts

# Bakery mechanism
if (!is.na(bakery_att)) {
  sde_bakery <- bakery_att / sd_ln_bakery
  se_sde_bakery <- bakery_se / sd_ln_bakery
} else {
  sde_bakery <- NA
  se_sde_bakery <- NA
}

# Placebo
if (!is.na(placebo_att)) {
  sde_placebo <- placebo_att / sd_ln_employer
  se_sde_placebo <- placebo_se / sd_ln_employer
} else {
  sde_placebo <- NA
  se_sde_placebo <- NA
}

classify_sde <- function(sde) {
  if (is.na(sde)) return("--")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table data
sde_rows <- data.frame(
  panel = c(rep("A", 3), rep("B", 2)),
  outcome = c(
    "Nonemployer establishments (log)",
    "Nonemployer establishments per 100K",
    "Nonemployer receipts (log)",
    "Bakery establishments (NAICS 3118, log)",
    "Employer establishments (NAICS 311, log, placebo)"
  ),
  beta = c(cs_att, cs_att_pc, cs_att_rec, bakery_att, placebo_att),
  se = c(cs_se, cs_se_pc, cs_se_rec, bakery_se, placebo_se),
  sd_y = c(sd_ln_estab, sd_estab_pc, sd_ln_receipts, sd_ln_bakery, sd_ln_employer),
  sde = c(sde_estab, sde_estab_pc, sde_receipts, sde_bakery, sde_placebo),
  se_sde = c(se_sde_estab, se_sde_estab_pc, se_sde_receipts, se_sde_bakery, se_sde_placebo),
  stringsAsFactors = FALSE
)
sde_rows$classification <- sapply(sde_rows$sde, classify_sde)

# SDE Notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the adoption or expansion of state-level cottage food laws---which ",
  "exempt home food producers from commercial licensing, inspection, and facility requirements---increase ",
  "food micro-entrepreneurship? ",
  "\\textbf{Policy mechanism:} Cottage food laws reduce the fixed regulatory cost of entering food production ",
  "by allowing individuals to produce and sell shelf-stable foods (baked goods, jams, preserves) from ",
  "residential kitchens without commercial licenses, health department inspections, or dedicated food-processing ",
  "facilities. Liberalization varies from first adoption of any exemption to comprehensive Food Freedom Acts ",
  "removing virtually all restrictions on home food sales. ",
  "\\textbf{Outcome definition:} Primary outcome is log count of nonemployer establishments in NAICS 311 ",
  "(Food Manufacturing) from the Census Nonemployer Statistics, measuring sole-proprietor food businesses ",
  "with no paid employees. ",
  "\\textbf{Treatment:} Binary indicator equal to one after a state adopts or significantly expands its ",
  "cottage food law (first adoption or major legislative expansion during 2012--2022). ",
  "\\textbf{Data:} Census Nonemployer Statistics and County Business Patterns, 51 states ",
  "(including DC) $\\times$ 11 years (2012--2022), for a balanced panel of approximately 560 state-year observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly-robust estimator with not-yet-treated comparison group; ",
  "standard errors from 1,000 bootstrap iterations. ",
  "\\textbf{Sample:} All 50 states plus DC; 27 treated states with legislative events during the panel window; ",
  "24 comparison states with pre-existing cottage food laws. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in which(sde_rows$panel == "A")) {
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
      sde_rows$outcome[i],
      sde_rows$beta[i], sde_rows$se[i], sde_rows$sd_y[i],
      sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$classification[i]))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by subcategory and placebo)}} \\\\\n")
for (i in which(sde_rows$panel == "B")) {
  if (!is.na(sde_rows$beta[i])) {
    cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
        sde_rows$outcome[i],
        sde_rows$beta[i], sde_rows$se[i], sde_rows$sd_y[i],
        sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$classification[i]))
  } else {
    cat(sprintf("%s & -- & -- & -- & -- & -- & -- \\\\\n", sde_rows$outcome[i]))
  }
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main_results.tex\n")
cat("  tables/tab3_mechanism.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
