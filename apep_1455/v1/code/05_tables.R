# 05_tables.R — Generate all tables for V1 paper
source("00_packages.R")

df <- readRDS("../data/analysis_dataset.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ================================================================
# Table 1: Summary Statistics
# ================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment stats by group
pre <- df %>% filter(year < 2023)
all_stats <- df %>%
  group_by(Group = ifelse(treated == 1, "Treated", "Control")) %>%
  summarise(
    `Multi-unit share` = sprintf("%.3f", mean(multi_unit_share, na.rm = TRUE)),
    `SD multi-unit share` = sprintf("%.3f", sd(multi_unit_share, na.rm = TRUE)),
    `Total consents` = sprintf("%.0f", mean(total, na.rm = TRUE)),
    `SD total consents` = sprintf("%.0f", sd(total, na.rm = TRUE)),
    `Houses` = sprintf("%.0f", mean(houses, na.rm = TRUE)),
    `Multi-unit homes` = sprintf("%.0f", mean(multi_unit, na.rm = TRUE)),
    `N (region-years)` = n(),
    .groups = "drop"
  )

# Full sample
full <- df %>%
  summarise(
    Group = "Full sample",
    `Multi-unit share` = sprintf("%.3f", mean(multi_unit_share, na.rm = TRUE)),
    `SD multi-unit share` = sprintf("%.3f", sd(multi_unit_share, na.rm = TRUE)),
    `Total consents` = sprintf("%.0f", mean(total, na.rm = TRUE)),
    `SD total consents` = sprintf("%.0f", sd(total, na.rm = TRUE)),
    `Houses` = sprintf("%.0f", mean(houses, na.rm = TRUE)),
    `Multi-unit homes` = sprintf("%.0f", mean(multi_unit, na.rm = TRUE)),
    `N (region-years)` = n()
  )

sumtab <- bind_rows(all_stats, full)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Treated & Control & Full Sample \\\\\n")
cat("\\midrule\n")

vars <- c("Multi-unit share", "Total consents", "Houses", "Multi-unit homes", "N (region-years)")
sd_vars <- c("SD multi-unit share", "SD total consents", NA, NA, NA)
for (v in seq_along(vars)) {
  vals <- c(sumtab[[vars[v]]][sumtab$Group == "Treated"],
            sumtab[[vars[v]]][sumtab$Group == "Control"],
            sumtab[[vars[v]]][sumtab$Group == "Full sample"])
  cat(sprintf("%s & %s & %s & %s \\\\\n", vars[v], vals[1], vals[2], vals[3]))
  if (!is.na(sd_vars[v])) {
    sd_vals <- c(sumtab[[sd_vars[v]]][sumtab$Group == "Treated"],
                 sumtab[[sd_vars[v]]][sumtab$Group == "Control"],
                 sumtab[[sd_vars[v]]][sumtab$Group == "Full sample"])
    cat(sprintf(" & (%s) & (%s) & (%s) \\\\\n", sd_vals[1], sd_vals[2], sd_vals[3]))
  }
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard deviations in parentheses. Treated regions contain MDRS Tier~1 cities (Waikato, Bay of Plenty, Wellington, Canterbury). Control regions are all other non-Auckland regions. Data: Stats NZ Building Consents, annual year ended February, 2016--2026. Multi-unit share is the fraction of new dwelling consents classified as multi-unit homes (townhouses, flats, apartments) rather than standalone houses. N~=~", nrow(df), " region-years (", n_distinct(df$region), " regions $\\times$ 11 years).\n", sep = "")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ================================================================
# Table 2: Main Results
# ================================================================
cat("Generating Table 2: Main Results...\n")

m1 <- results$twfe_base
m2 <- results$twfe_control
cs_agg <- results$cs_agg
m3 <- results$log_multi

sink("../tables/tab2_main.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of MDRS on Dwelling Type Composition}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & \\multicolumn{2}{c}{Multi-unit share} & CS ATT & log(Multi-unit) \\\\\n")
cat("\\midrule\n")

# Extract coefficients
b1 <- coef(m1)["treat_post"]
se1 <- se(m1)["treat_post"]
b2 <- coef(m2)["treat_post"]
se2 <- se(m2)["treat_post"]
b_cs <- cs_agg$overall.att
se_cs <- cs_agg$overall.se
b3 <- coef(m3)["treat_post"]
se3 <- se(m3)["treat_post"]

stars <- function(b, se) {
  p <- 2 * pnorm(-abs(b / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

cat(sprintf("MDRS $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            b1, stars(b1, se1), b2, stars(b2, se2), b_cs, stars(b_cs, se_cs), b3, stars(b3, se3)))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n", se1, se2, se_cs, se3))
cat("\\\\\n")
cat(sprintf("Region FE & Yes & Yes & --- & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & --- & Yes \\\\\n"))
cat(sprintf("log(Total consents) & No & Yes & No & No \\\\\n"))
cat(sprintf("Estimator & TWFE & TWFE & CS & TWFE \\\\\n"))
cat(sprintf("N & %d & %d & %d & %d \\\\\n", nobs(m1), nobs(m2), nrow(df), nobs(m3)))
cat(sprintf("Treated regions & 4 & 4 & 4 & 4 \\\\\n"))
cat(sprintf("Control regions & 11 & 11 & 11 & 11 \\\\\n"))
cat(sprintf("Pre-treatment mean & %.3f & %.3f & %.3f & --- \\\\\n",
            mean(df$multi_unit_share[df$treated == 1 & df$year < 2023], na.rm = TRUE),
            mean(df$multi_unit_share[df$treated == 1 & df$year < 2023], na.rm = TRUE),
            mean(df$multi_unit_share[df$treated == 1 & df$year < 2023], na.rm = TRUE)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the region level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Columns (1)--(2) report two-way fixed effects (TWFE) estimates. Column (3) reports the Callaway--Sant'Anna (2021) simple aggregated ATT using never-treated regions as the comparison group. Column (4) uses log multi-unit consents as outcome. Post period: year ended February 2023--2026 (MDRS operative August 2022).\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ================================================================
# Table 3: Pre-trends / Event Study
# ================================================================
cat("Generating Table 3: Event Study...\n")

es <- rob$pretrend
es_coefs <- coef(es)
es_se <- se(es)

# Extract year interactions
idx <- grep("year_fac.*:treated", names(es_coefs))
es_years <- as.integer(gsub("year_fac::(\\d+):treated", "\\1", names(es_coefs)[idx]))

sink("../tables/tab3_event_study.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Multi-Unit Share by Year Relative to MDRS}\n")
cat("\\label{tab:event}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Year & Coefficient & SE \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n")
for (k in seq_along(idx)) {
  yr <- es_years[k]
  if (yr >= 2023) next
  b <- es_coefs[idx[k]]
  s <- es_se[idx[k]]
  cat(sprintf("%d & %.3f%s & (%.3f) \\\\\n", yr, b, stars(b, s), s))
}
cat("2022 (ref.) & 0.000 & --- \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\\n")
for (k in seq_along(idx)) {
  yr <- es_years[k]
  if (yr < 2023) next
  b <- es_coefs[idx[k]]
  s <- es_se[idx[k]]
  cat(sprintf("%d & %.3f%s & (%.3f) \\\\\n", yr, b, stars(b, s), s))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Coefficients from regressing multi-unit share on year $\\times$ treated interactions with region and year fixed effects. Standard errors clustered at the region level. Reference year: 2022 (last pre-treatment year). MDRS operative August 2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ================================================================
# Table 4: Robustness
# ================================================================
cat("Generating Table 4: Robustness...\n")

rob_models <- list(
  `Baseline` = results$twfe_base,
  `Excl. Canterbury` = rob$no_canterbury,
  `Excl. small regions` = rob$no_small,
  `Delayed treatment (2024)` = rob$delayed_treat
)

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Effect of MDRS on Multi-Unit Share}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Baseline & Excl. Canterbury & Excl. small & Delayed (2024) \\\\\n")
cat("\\midrule\n")

for (j in seq_along(rob_models)) {
  mod <- rob_models[[j]]
  treat_var <- intersect(c("treat_post", "treat_post_delayed"), names(coef(mod)))
  b <- coef(mod)[treat_var]
  s <- se(mod)[treat_var]
  if (j == 1) {
    cat(sprintf("MDRS $\\times$ Post & %.3f%s", b, stars(b, s)))
  } else {
    cat(sprintf(" & %.3f%s", b, stars(b, s)))
  }
}
cat(" \\\\\n")
for (j in seq_along(rob_models)) {
  mod <- rob_models[[j]]
  treat_var <- intersect(c("treat_post", "treat_post_delayed"), names(coef(mod)))
  s <- se(mod)[treat_var]
  if (j == 1) {
    cat(sprintf(" & (%.3f)", s))
  } else {
    cat(sprintf(" & (%.3f)", s))
  }
}
cat(" \\\\\n\\\\\n")
for (j in seq_along(rob_models)) {
  if (j == 1) cat(sprintf("N & %d", nobs(rob_models[[j]])))
  else cat(sprintf(" & %d", nobs(rob_models[[j]])))
}
cat(" \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications include region and year fixed effects with standard errors clustered at the region level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column (2) excludes Canterbury (earthquake reconstruction). Column (3) excludes regions averaging fewer than 200 annual consents. Column (4) defines treatment onset as year ended February 2024 (first full post-MDRS year).\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ================================================================
# Table 5: Placebo — Total consents
# ================================================================
cat("Generating Table 5: Placebo...\n")

m_placebo <- rob$placebo_total
m_houses <- results$houses_share

sink("../tables/tab5_placebo.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Placebo Outcomes: Total Consents and Houses Share}\n")
cat("\\label{tab:placebo}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) \\\\\n")
cat(" & log(Total consents) & Houses share \\\\\n")
cat("\\midrule\n")
b_p <- coef(m_placebo)["treat_post"]
se_p <- se(m_placebo)["treat_post"]
b_h <- coef(m_houses)["treat_post"]
se_h <- se(m_houses)["treat_post"]
cat(sprintf("MDRS $\\times$ Post & %.3f%s & %.3f%s \\\\\n", b_p, stars(b_p, se_p), b_h, stars(b_h, se_h)))
cat(sprintf(" & (%.3f) & (%.3f) \\\\\n", se_p, se_h))
cat(sprintf("\\\\\nN & %d & %d \\\\\n", nobs(m_placebo), nobs(m_houses)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1) tests whether MDRS affected the overall volume of consents (it should not primarily shift composition, though supply effects are possible). Column (2) shows the houses share effect — the mechanical mirror of multi-unit share. Standard errors clustered at the region level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ================================================================
cat("Generating SDE table...\n")

# Main result: multi-unit share
beta_main <- coef(results$twfe_base)["treat_post"]
se_main <- se(results$twfe_base)["treat_post"]
sd_y <- sd(df$multi_unit_share[df$year < 2023], na.rm = TRUE)  # Pre-treatment SD

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Heterogeneity: split by large vs small treated regions
large_treated <- c("Canterbury", "Wellington")
small_treated <- c("Waikato", "Bay of Plenty")

df_large <- df %>% filter(region %in% large_treated | treated == 0)
df_small <- df %>% filter(region %in% small_treated | treated == 0)

m_large <- feols(multi_unit_share ~ treat_post | region_id + year, data = df_large, cluster = ~region_id)
m_small <- feols(multi_unit_share ~ treat_post | region_id + year, data = df_small, cluster = ~region_id)

beta_large <- coef(m_large)["treat_post"]
se_large <- se(m_large)["treat_post"]
sde_large <- beta_large / sd_y
se_sde_large <- se_large / sd_y

beta_small <- coef(m_small)["treat_post"]
se_small <- se(m_small)["treat_post"]
sde_small <- beta_small / sd_y
se_sde_small <- se_small / sd_y

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} New Zealand. ",
  "\\textbf{Research question:} Does mandatory upzoning (permitting as-of-right medium-density construction) shift the composition of new housing toward multi-unit dwelling types in treated cities? ",
  "\\textbf{Policy mechanism:} The Medium Density Residential Standards (MDRS), operative August 2022, require Tier~1 territorial authorities to allow up to three residential units of up to three stories on any urban residential lot without resource consent, eliminating a discretionary approval process that averaged 40--70 days and several thousand NZD in fees for medium-density proposals. ",
  "\\textbf{Outcome definition:} Multi-unit share --- the fraction of annual new dwelling consents classified as multi-unit homes (townhouses, flats, apartments) rather than standalone houses, from Stats NZ Building Consents. ",
  "\\textbf{Treatment:} Binary (0/1): region contains a Tier~1 city subject to MDRS from August 2022. ",
  "\\textbf{Data:} Stats NZ Building Consents, annual year ended February, 2016--2026; 15 regions $\\times$ 11 years = 165 region-years. ",
  "\\textbf{Method:} Two-way fixed effects DiD with region and year fixed effects; standard errors clustered at the region level. Callaway--Sant'Anna (2021) estimator as robustness. ",
  "\\textbf{Sample:} 15 NZ regions excluding Auckland (treated earlier via Auckland Unitary Plan 2016). Four treated regions (Waikato, Bay of Plenty, Wellington, Canterbury) vs.\\ 11 never-treated control regions. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of the multi-unit share. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{llcccccc}\n")
cat("\\toprule\n")
cat("Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Multi-unit share & TWFE baseline & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_main, sd_y, sde_main, se_sde_main, classify(sde_main)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by region size)}} \\\\\n")
cat(sprintf("Multi-unit share & Large cities (Canterbury, Wellington) & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_large, sd_y, sde_large, se_sde_large, classify(sde_large)))
cat(sprintf("Multi-unit share & Smaller cities (Waikato, Bay of Plenty) & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_small, sd_y, sde_small, se_sde_small, classify(sde_small)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated in ../tables/\n")
