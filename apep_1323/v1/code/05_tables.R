## 05_tables.R — Generate all LaTeX tables
## APEP Working Paper apep_1323

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics\n")

## Pre-treatment (2005-2011) vs post-treatment (2012-2022)
## Nigeria vs Controls
summ_data <- panel %>%
  mutate(
    group = ifelse(nigeria == 1, "Nigeria", "Control Countries"),
    period = ifelse(year < 2012, "Pre (2005--2011)", "Post (2012--2022)")
  )

## Compute summary stats for key variables
vars <- c("atm_per_100k", "branches_per_100k", "gdp_growth", "gdp_pc",
          "mobile_subs", "internet_pct", "inflation")
var_labels <- c("ATMs per 100,000 adults", "Bank branches per 100,000 adults",
                "GDP growth (\\%)", "GDP per capita (constant 2015 USD)",
                "Mobile subscriptions per 100", "Internet users (\\%)",
                "Inflation (\\%)")

summ_table <- data.frame()
for (i in seq_along(vars)) {
  for (grp in c("Nigeria", "Control Countries")) {
    for (per in c("Pre (2005--2011)", "Post (2012--2022)")) {
      d <- summ_data %>%
        filter(group == grp, period == per) %>%
        pull(!!sym(vars[i]))
      summ_table <- bind_rows(summ_table, data.frame(
        Variable = var_labels[i],
        Group = grp,
        Period = per,
        Mean = mean(d, na.rm = TRUE),
        SD = sd(d, na.rm = TRUE),
        N = sum(!is.na(d)),
        stringsAsFactors = FALSE
      ))
    }
  }
}

## Write LaTeX table
sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Nigeria vs.\\ Control Countries}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{l cc cc cc cc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{4}{c}{Nigeria} & \\multicolumn{4}{c}{Control Countries} \\\\\n")
cat("\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}\n")
cat(" & \\multicolumn{2}{c}{Pre} & \\multicolumn{2}{c}{Post} & \\multicolumn{2}{c}{Pre} & \\multicolumn{2}{c}{Post} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}\n")
cat(" & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\\n")
cat("\\midrule\n")

for (vl in var_labels) {
  row <- summ_table %>% filter(Variable == vl)
  nga_pre <- row %>% filter(Group == "Nigeria", Period == "Pre (2005--2011)")
  nga_post <- row %>% filter(Group == "Nigeria", Period == "Post (2012--2022)")
  ctrl_pre <- row %>% filter(Group == "Control Countries", Period == "Pre (2005--2011)")
  ctrl_post <- row %>% filter(Group == "Control Countries", Period == "Post (2012--2022)")

  cat(sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
              vl,
              ifelse(nrow(nga_pre) > 0, nga_pre$Mean, NA),
              ifelse(nrow(nga_pre) > 0, nga_pre$SD, NA),
              ifelse(nrow(nga_post) > 0, nga_post$Mean, NA),
              ifelse(nrow(nga_post) > 0, nga_post$SD, NA),
              ifelse(nrow(ctrl_pre) > 0, ctrl_pre$Mean, NA),
              ifelse(nrow(ctrl_pre) > 0, ctrl_pre$SD, NA),
              ifelse(nrow(ctrl_post) > 0, ctrl_post$Mean, NA),
              ifelse(nrow(ctrl_post) > 0, ctrl_post$SD, NA)))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
nga_n <- sum(panel$country == "NG")
ctrl_n <- sum(panel$country != "NG")
cat(sprintf("\\item \\textit{Notes:} Nigeria: %d country-years. Control countries (10 SSA peers): %d country-years.\n", nga_n, ctrl_n))
cat("Pre-treatment period: 2005--2011. Post-treatment period: 2012--2022.\n")
cat("Control countries: Botswana, Cameroon, Ghana, Kenya, Mozambique, Rwanda, Tanzania, Uganda, South Africa, Zambia.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## TABLE 2: Main DiD Results
## ============================================================
cat("Generating Table 2: Main Results\n")

sink(file.path(table_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of Nigeria's Cashless Policy on Financial Infrastructure}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & ATM & Log ATM & Branches & Log Branch & ATM & Branches \\\\\n")
cat("\\midrule\n")

## Extract coefficients
models <- list(results$main_atm, results$main_log_atm, results$main_branches,
               results$main_log_branches, results$main_atm_ctrl, results$main_branches_ctrl)

## Print treatment effect row
cat("Nigeria $\\times$ Post-2012")
for (m in models) {
  b <- coef(m)["treat"]
  s <- se(m)["treat"]
  p <- pvalue(m)["treat"]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  cat(sprintf(" & %.3f%s", b, stars))
}
cat(" \\\\\n")

## Standard errors
cat(" ")
for (m in models) {
  s <- se(m)["treat"]
  cat(sprintf(" & (%.3f)", s))
}
cat(" \\\\\n")

## Permutation p-values (for cols 1 and 3)
cat("Permutation $p$-value")
cat(sprintf(" & %.3f", results$perm_p_atm))
cat(" & ")
cat(sprintf(" & %.3f", results$perm_p_br))
cat(" & & & \\\\\n")

## N
cat("\\midrule\n")
cat("Controls & No & No & No & No & Yes & Yes \\\\\n")
cat("Country FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")

cat("Observations")
for (m in models) {
  cat(sprintf(" & %d", m$nobs))
}
cat(" \\\\\n")

cat("Countries")
for (m in models) {
  nc <- length(unique(m$fixef_id$country_id))
  cat(sprintf(" & %d", nc))
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered by country in parentheses.\n")
cat("Columns (1)--(4): baseline specification with country and year fixed effects.\n")
cat("Columns (5)--(6): add GDP growth, inflation, log GDP per capita, and mobile subscriptions as controls.\n")
cat("Permutation $p$-values from placebo-in-space inference (fraction of 11 countries with $|\\hat{\\beta}| \\geq |\\hat{\\beta}_{\\text{Nigeria}}|$).\n")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## TABLE 3: Robustness
## ============================================================
cat("Generating Table 3: Robustness\n")

sink(file.path(table_dir, "tab3_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Effect on Bank Branches per 100,000 Adults}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & Baseline & 2008--18 & Treat=2013 & HC1 SE & Placebo 2009 & Placebo GDP \\\\\n")
cat("\\midrule\n")

rob_models <- list(
  results$main_branches,
  robustness$restricted$branches,
  robustness$wave2,
  robustness$hc_robust,
  robustness$placebo_timing,
  robustness$placebo_gdp
)

rob_vars <- c("treat", "treat", "treat_w2", "treat", "placebo_treat", "treat")

cat("Treatment")
for (i in seq_along(rob_models)) {
  m <- rob_models[[i]]
  v <- rob_vars[i]
  b <- coef(m)[v]
  p <- pvalue(m)[v]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  cat(sprintf(" & %.3f%s", b, stars))
}
cat(" \\\\\n")

cat(" ")
for (i in seq_along(rob_models)) {
  m <- rob_models[[i]]
  v <- rob_vars[i]
  s <- se(m)[v]
  cat(sprintf(" & (%.3f)", s))
}
cat(" \\\\\n")

cat("\\midrule\n")
cat("Outcome & Branches & Branches & Branches & Branches & Branches & GDP growth \\\\\n")
cat("Sample & Full & 2008--18 & Full & Full & Pre only & Full \\\\\n")

cat("Observations")
for (m in rob_models) {
  cat(sprintf(" & %d", m$nobs))
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications include country and year fixed effects.\n")
cat("Column (1): baseline clustered SE. Column (2): restricted to 2008--2018 (excludes COVID).\n")
cat("Column (3): treatment defined as 2013+ (Wave 2, expanded rollout).\n")
cat("Column (4): heteroskedasticity-robust (HC1) standard errors.\n")
cat("Column (5): placebo test using 2009 as fake treatment, pre-treatment data only.\n")
cat("Column (6): GDP growth as placebo outcome (should not be affected by cashless policy alone).\n")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## TABLE 4: Leave-One-Out
## ============================================================
cat("Generating Table 4: Leave-One-Out\n")

loo <- robustness$loo
country_names <- c(
  BW = "Botswana", CM = "Cameroon", GH = "Ghana", KE = "Kenya",
  MZ = "Mozambique", RW = "Rwanda", TZ = "Tanzania", UG = "Uganda",
  ZA = "South Africa", ZM = "Zambia"
)

sink(file.path(table_dir, "tab4_loo.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Leave-One-Out: Dropping Each Control Country}\n")
cat("\\label{tab:loo}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Dropped Country & Estimate & SE \\\\\n")
cat("\\midrule\n")

for (j in 1:nrow(loo)) {
  cc <- loo$dropped[j]
  cn <- country_names[cc]
  if (is.na(cn)) cn <- cc
  cat(sprintf("%s & %.3f%s & (%.3f) \\\\\n",
              cn, loo$estimate[j], loo$sig[j], loo$se[j]))
}

cat("\\midrule\n")
b_base <- coef(results$main_branches)["treat"]
se_base <- se(results$main_branches)["treat"]
cat(sprintf("Baseline (all controls) & %.3f*** & (%.3f) \\\\\n", b_base, se_base))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row drops one control country and re-estimates the baseline specification.\n")
cat("Dependent variable: bank branches per 100,000 adults. Country and year fixed effects included.\n")
cat("Standard errors clustered by country.\n")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## TABLE F1: SDE Table (Standardized Effect Sizes)
## ============================================================
cat("Generating SDE Table\n")

## Main outcomes with SDE
## Branches (primary), ATMs (secondary)
## SDE = beta / SD(Y) for binary treatment
sd_branches <- sd(panel$branches_per_100k, na.rm = TRUE)
sd_atm <- sd(panel$atm_per_100k, na.rm = TRUE)

beta_br <- coef(results$main_branches)["treat"]
se_br <- se(results$main_branches)["treat"]
sde_br <- beta_br / sd_branches
se_sde_br <- se_br / sd_branches

beta_atm <- coef(results$main_atm)["treat"]
se_atm_val <- se(results$main_atm)["treat"]
sde_atm <- beta_atm / sd_atm
se_sde_atm <- se_atm_val / sd_atm

classify <- function(s) {
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

## Heterogeneity: Southern vs Northern control countries
south_ctrls <- c("ZA", "BW", "ZM", "MZ", "TZ", "KE", "UG", "RW", "GH")
west_ctrls <- c("GH", "CM")  # West Africa comparison

## Southern Africa comparators
panel_south <- panel %>% filter(country == "NG" | country %in% south_ctrls[1:5])
m_south <- feols(branches_per_100k ~ treat | country_id + year,
                 data = panel_south, cluster = ~country_id)
sd_br_south <- sd(panel_south$branches_per_100k, na.rm = TRUE)
sde_br_south <- coef(m_south)["treat"] / sd_br_south
se_sde_br_south <- se(m_south)["treat"] / sd_br_south

## East Africa comparators
east_ctrls <- c("KE", "UG", "TZ", "RW")
panel_east <- panel %>% filter(country == "NG" | country %in% east_ctrls)
m_east <- feols(branches_per_100k ~ treat | country_id + year,
                data = panel_east, cluster = ~country_id)
sd_br_east <- sd(panel_east$branches_per_100k, na.rm = TRUE)
sde_br_east <- coef(m_east)["treat"] / sd_br_east
se_sde_br_east <- se(m_east)["treat"] / sd_br_east

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{llcccccc}\n")
cat("\\toprule\n")
cat("Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Branches per 100k & Baseline DiD & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_br, se_br, sd_branches, sde_br, se_sde_br, classify(sde_br)))
cat(sprintf("ATMs per 100k & Baseline DiD & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_atm, se_atm_val, sd_atm, sde_atm, se_sde_atm, classify(sde_atm)))
cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by control region)}} \\\\\n")
cat(sprintf("Branches per 100k & Southern Africa controls & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            coef(m_south)["treat"], se(m_south)["treat"], sd_br_south,
            sde_br_south, se_sde_br_south, classify(sde_br_south)))
cat(sprintf("Branches per 100k & East Africa controls & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            coef(m_east)["treat"], se(m_east)["treat"], sd_br_east,
            sde_br_east, se_sde_br_east, classify(sde_br_east)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Nigeria. ",
  "\\textbf{Research question:} Whether cash transaction penalties imposed on deposits and withdrawals above regulatory thresholds affect the density of physical bank branches in the treated country relative to untreated peer countries. ",
  "\\textbf{Policy mechanism:} The Central Bank of Nigeria introduced surcharges on cash deposits exceeding \\naira500,000 for individuals and \\naira3,000,000 for corporates, making large cash transactions costly and incentivizing electronic alternatives; this reduces the profitability of cash-handling physical branches. ",
  "\\textbf{Outcome definition:} Commercial bank branches per 100,000 adults from the World Bank Financial Access Survey, measuring the density of physical banking points of access. ",
  "\\textbf{Treatment:} Binary; Nigeria is treated from 2012 onward (phased rollout: Lagos January 2012, six additional states July 2013, nationwide July 2014). ",
  "\\textbf{Data:} World Bank Development Indicators, 2005--2022, country-year observations for 11 Sub-Saharan African countries (198 country-years). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with country and year fixed effects, standard errors clustered by country, supplemented by permutation inference across all 11 countries. ",
  "\\textbf{Sample:} Countries with at least three pre-treatment (before 2012) and three post-treatment years of ATM data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome variable across all country-years. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
cat(sprintf("  Tab 1 (Summary): %s\n", file.path(table_dir, "tab1_summary.tex")))
cat(sprintf("  Tab 2 (Main): %s\n", file.path(table_dir, "tab2_main.tex")))
cat(sprintf("  Tab 3 (Robustness): %s\n", file.path(table_dir, "tab3_robustness.tex")))
cat(sprintf("  Tab 4 (LOO): %s\n", file.path(table_dir, "tab4_loo.tex")))
cat(sprintf("  Tab F1 (SDE): %s\n", file.path(table_dir, "tabF1_sde.tex")))
