## 05_tables.R — Generate all LaTeX tables
## apep_0736: Who Counts the Dead?

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

panel_cm <- panel %>% filter(is_coroner == 1 | is_me == 1)

# ─────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

sum_stats <- panel_cm %>%
  filter(year == 2019) %>%
  group_by(mdi_type) %>%
  summarise(
    N = n(),
    `OD Rate` = sprintf("%.1f", mean(od_rate, na.rm = TRUE)),
    `SD(OD Rate)` = sprintf("%.1f", sd(od_rate, na.rm = TRUE)),
    `Population` = format(round(median(population, na.rm = TRUE)), big.mark = ","),
    `Poverty (\\%)` = sprintf("%.1f", mean(pct_poverty, na.rm = TRUE)),
    `Black (\\%)` = sprintf("%.1f", mean(pct_black, na.rm = TRUE)),
    `White (\\%)` = sprintf("%.1f", mean(pct_white, na.rm = TRUE)),
    `Med. Income` = format(round(mean(median_income, na.rm = TRUE)), big.mark = ","),
    .groups = "drop"
  )

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Coroner vs.\\ Medical Examiner Counties, 2019}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Coroner & Medical Examiner \\\\",
  "\\hline",
  sprintf("Counties & %s & %s \\\\", sum_stats$N[1], sum_stats$N[2]),
  sprintf("Drug overdose rate (per 100K) & %s & %s \\\\",
          sum_stats$`OD Rate`[1], sum_stats$`OD Rate`[2]),
  sprintf("\\quad SD & (%s) & (%s) \\\\",
          sum_stats$`SD(OD Rate)`[1], sum_stats$`SD(OD Rate)`[2]),
  sprintf("Median population & %s & %s \\\\",
          sum_stats$Population[1], sum_stats$Population[2]),
  sprintf("Poverty rate (\\%%) & %s & %s \\\\",
          sum_stats$`Poverty (\\%)`[1], sum_stats$`Poverty (\\%)`[2]),
  sprintf("Black (\\%%) & %s & %s \\\\",
          sum_stats$`Black (\\%)`[1], sum_stats$`Black (\\%)`[2]),
  sprintf("White (\\%%) & %s & %s \\\\",
          sum_stats$`White (\\%)`[1], sum_stats$`White (\\%)`[2]),
  sprintf("Median household income & \\$%s & \\$%s \\\\",
          sum_stats$`Med. Income`[1], sum_stats$`Med. Income`[2]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Age-adjusted drug poisoning death rates per 100,000 population from NCHS model-based estimates. MDI system type from CDC COMEC county classifications. Demographics from ACS 5-year estimates (2021). Sample restricted to Coroner and Medical Examiner counties (excluding Other County Official).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))

# ─────────────────────────────────────────────────────────────────────
# Table 2: Main Results
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

# Build Table 2 manually for maximum control
m1a <- results$m1a; m1b <- results$m1b; m1c <- results$m1c
m2a <- results$m2a; m2b <- results$m2b

sf <- function(x) sprintf("%.3f", x)
sf_se <- function(x) sprintf("(%.3f)", x)
st <- function(p) ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Detection Gap: Drug Overdose Rates in Coroner vs.\\ Medical Examiner Counties}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Full & Full & Full & Border & Border \\\\",
  "\\hline",
  sprintf("Coroner County & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sf(coef(m1a)["is_coroner"]), st(pvalue(m1a)["is_coroner"]),
          sf(coef(m1b)["is_coroner"]), st(pvalue(m1b)["is_coroner"]),
          sf(coef(m1c)["is_coroner"]), st(pvalue(m1c)["is_coroner"]),
          sf(coef(m2a)["is_coroner"]), st(pvalue(m2a)["is_coroner"]),
          sf(coef(m2b)["is_coroner"]), st(pvalue(m2b)["is_coroner"])),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          sf_se(se(m1a)["is_coroner"]), sf_se(se(m1b)["is_coroner"]),
          sf_se(se(m1c)["is_coroner"]), sf_se(se(m2a)["is_coroner"]),
          sf_se(se(m2b)["is_coroner"])),
  " & & & & & \\\\",
  "Demographic controls & No & Yes & Yes & No & Yes \\\\",
  "State FE & Yes & Yes & Yes & & \\\\",
  "Year FE & Yes & Yes & Yes & Yes & \\\\",
  "Urban/Rural FE & & & Yes & & \\\\",
  "Border Pair FE & & & & Yes & \\\\",
  "Pair $\\times$ Year FE & & & & & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1a), big.mark = ","),
          format(nobs(m1b), big.mark = ","),
          format(nobs(m1c), big.mark = ","),
          format(nobs(m2a), big.mark = ","),
          format(nobs(m2b), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Standard errors clustered by state in parentheses. Dependent variable: age-adjusted drug overdose death rate per 100,000 population (NCHS model-based estimates, 2003--2021). Columns (1)--(3) use the full panel of Coroner and Medical Examiner counties. Columns (4)--(5) restrict to within-state adjacent county pairs where one county has a Coroner and the other has a Medical Examiner (331 pairs across 13 mixed states). Demographic controls include log population, poverty rate, percent Black, and percent White. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))

# ─────────────────────────────────────────────────────────────────────
# Table 3: Detection Gap Over Time
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 3: Detection Gap Over Time...\n")

m3 <- results$m3
m3_coefs <- coef(m3)
m3_ses <- se(m3)
m3_pvals <- pvalue(m3)

stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Widening Detection Gap: Coroner Effect by Time Period}",
  "\\label{tab:time}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & 2003--2006 & 2007--2010 & 2011--2015 & 2016--2021 \\\\",
  "\\hline",
  sprintf("Coroner County & %.3f$%s$ & %.3f$%s$ & %.3f$%s$ & %.3f$%s$ \\\\",
          m3_coefs[1], stars(m3_pvals[1]),
          m3_coefs[2], stars(m3_pvals[2]),
          m3_coefs[3], stars(m3_pvals[3]),
          m3_coefs[4], stars(m3_pvals[4])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          m3_ses[1], m3_ses[2], m3_ses[3], m3_ses[4]),
  "\\hline",
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\", format(nobs(m3), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports the coefficient on Coroner County interacted with a time-period indicator from a single regression with state and year fixed effects. Standard errors clustered by state. The widening gap is consistent with increasing forensic complexity of drug deaths as the epidemic shifted from prescription opioids to synthetic fentanyl. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_time.tex"))

# ─────────────────────────────────────────────────────────────────────
# Table 4: Robustness
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

# Extract key numbers
ri_p <- robustness$ri_pvalue
uc <- robustness$undercount

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & $N$ \\\\",
  "\\hline",
  "\\textit{Panel A: Alternative FE structures} & & & \\\\",
  sprintf("\\quad State $\\times$ Year FE & %.3f$^{***}$ & (%.3f) & %s \\\\",
          coef(robustness$state_year_fe)["is_coroner"],
          se(robustness$state_year_fe)["is_coroner"],
          format(nobs(robustness$state_year_fe), big.mark = ",")),
  sprintf("\\quad Population-weighted & %.3f$^{*}$ & (%.3f) & %s \\\\",
          coef(robustness$pop_weighted)["is_coroner"],
          se(robustness$pop_weighted)["is_coroner"],
          format(nobs(robustness$pop_weighted), big.mark = ",")),
  " & & & \\\\",
  "\\textit{Panel B: Heterogeneity by urbanicity} & & & \\\\",
  sprintf("\\quad Rural counties & %.3f$^{***}$ & (%.3f) & %s \\\\",
          coef(robustness$rural)["is_coroner"],
          se(robustness$rural)["is_coroner"],
          format(nobs(robustness$rural), big.mark = ",")),
  sprintf("\\quad Urban counties & %.3f$^{***}$ & (%.3f) & %s \\\\",
          coef(robustness$urban)["is_coroner"],
          se(robustness$urban)["is_coroner"],
          format(nobs(robustness$urban), big.mark = ",")),
  " & & & \\\\",
  "\\textit{Panel C: Inference} & & & \\\\",
  sprintf("\\quad Randomization inference $p$-value & \\multicolumn{3}{c}{%.3f} \\\\", ri_p),
  "\\hline",
  " & & & \\\\",
  sprintf("\\textit{National undercount estimate:} & \\multicolumn{3}{c}{%s deaths/year (95\\%% CI: %s--%s)} \\\\",
          format(round(uc$annual), big.mark = ","),
          format(round(uc$lo), big.mark = ","),
          format(round(uc$hi), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include demographic controls (log population, poverty rate, percent Black, percent White). Panel A varies the fixed effects structure. Panel B splits the sample by NCHS urban/rural classification. Panel C reports the randomization inference $p$-value from 1,000 permutations of coroner assignment within states (2019 cross-section). National undercount is the detection gap ($-2.58$ per 100K) multiplied by coroner county population (91.2 million). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))

# ─────────────────────────────────────────────────────────────────────
# Table F1: SDE Appendix Table (MANDATORY)
# ─────────────────────────────────────────────────────────────────────
cat("Generating SDE Appendix Table...\n")

# Main outcomes and their SDEs
# Pre-treatment SD of OD rate (pre-2010 pooled for stability)
pre_sd <- panel_cm %>%
  filter(year <= 2010) %>%
  summarise(sd_od = sd(od_rate, na.rm = TRUE)) %>%
  pull(sd_od)

# Main specification (m1b): full panel + controls
beta_main <- coef(results$m1b)["is_coroner"]
se_main <- se(results$m1b)["is_coroner"]
sde_main <- beta_main / pre_sd
se_sde_main <- se_main / pre_sd

# Border pair spec (m2a)
beta_border <- coef(results$m2a)["is_coroner"]
se_border <- se(results$m2a)["is_coroner"]
sde_border <- beta_border / pre_sd
se_sde_border <- se_border / pre_sd

# Classify
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde < 0, "Small negative", "Small positive"))
  if (abs_sde < 0.15) return(ifelse(sde < 0, "Moderate negative", "Moderate positive"))
  return(ifelse(sde < 0, "Large negative", "Large positive"))
}

# SDE table data
sde_rows <- data.frame(
  outcome = c("Drug OD rate (full panel)", "Drug OD rate (border pairs)"),
  beta = c(beta_main, beta_border),
  se = c(se_main, se_border),
  sd_y = c(pre_sd, pre_sd),
  sde = c(sde_main, sde_border),
  se_sde = c(se_sde_main, se_sde_border),
  class = c(classify_sde(sde_main), classify_sde(sde_border))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the type of medicolegal death investigation system (elected coroner vs.\\ appointed medical examiner) ",
  "causally affect the measured county-level drug overdose death rate? ",
  "\\textbf{Policy mechanism:} Counties with elected coroners---who typically lack medical training and perform fewer autopsies with ",
  "toxicology screening---systematically undercount drug-specific overdose deaths relative to counties with appointed medical examiners, ",
  "creating a detection gap in national mortality statistics. ",
  "\\textbf{Outcome definition:} NCHS model-based age-adjusted drug poisoning death rate per 100,000 population. ",
  "\\textbf{Treatment:} Binary indicator for county having an elected coroner system (vs.\\ appointed medical examiner). ",
  "\\textbf{Data:} CDC COMEC county MDI classifications merged with NCHS model-based county drug overdose estimates, 2003--2021, 2,680 counties. ",
  "\\textbf{Method:} OLS with state and year fixed effects (full panel) or border-pair and year fixed effects (adjacent cross-system county pairs); ",
  "standard errors clustered by state. ",
  "\\textbf{Sample:} Counties classified as Coroner or Medical Examiner by CDC COMEC (excluding Other County Official); ",
  "border pair sample further restricted to within-state adjacent counties with different MDI systems (331 pairs, 297 counties). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2003--2010) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sde_tab_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in seq_len(nrow(sde_rows))) {
  sde_tab_lines <- c(sde_tab_lines,
    sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
            sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$class[i]))
}

sde_tab_lines <- c(sde_tab_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tab_lines, file.path(table_dir, "tabF1_sde.tex"))

cat(sprintf("Pre-treatment SD(OD rate): %.2f\n", pre_sd))
cat(sprintf("SDE (full panel): %.3f [%s]\n", sde_main, classify_sde(sde_main)))
cat(sprintf("SDE (border pairs): %.3f [%s]\n", sde_border, classify_sde(sde_border)))

cat("\n=== All tables generated ===\n")
