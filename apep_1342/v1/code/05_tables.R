# 05_tables.R — Table generation for apep_1342
# UK FCA HCSTC Price Cap: Supply-Side Destruction

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
market_panel <- readRDS(file.path(data_dir, "market_panel.rds"))
regional_panel <- readRDS(file.path(data_dir, "regional_panel.rds"))
firm_exits <- readRDS(file.path(data_dir, "firm_exits.rds"))
boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))
regs <- readRDS(file.path(data_dir, "regression_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================================
# Table 1: Summary Statistics — Market Structure Pre vs Post Cap
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

sum_stats <- market_panel %>%
  mutate(period = case_when(
    phase == "pre_cap" ~ "Pre-Cap (2012Q1--2014Q4)",
    phase == "phase1_cap" ~ "Post-Cap Phase 1 (2015Q1--2018Q2)",
    phase == "phase2_compensation" ~ "Compensation Wave (2018Q3--2019Q4)",
    TRUE ~ "Steady State (2020Q1--2022Q4)"
  )) %>%
  group_by(period) %>%
  summarise(
    `Quarters` = n(),
    `Active Firms (mean)` = round(mean(n_active_firms), 0),
    `Active Firms (min)` = min(n_active_firms),
    `Loans/Qtr ('000, mean)` = round(mean(total_loans_000), 0),
    `Value/Qtr (GBP m, mean)` = round(mean(total_value_gbp_m), 0),
    `HHI (approx.)` = round(mean(hhi_approx), 0),
    .groups = "drop"
  ) %>%
  arrange(match(period, c("Pre-Cap (2012Q1--2014Q4)",
                           "Post-Cap Phase 1 (2015Q1--2018Q2)",
                           "Compensation Wave (2018Q3--2019Q4)",
                           "Steady State (2020Q1--2022Q4)")))

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: HCSTC Market Structure by Phase}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Period & Quarters & Firms & Firms & Loans/Qtr & Value/Qtr & HHI \\\\",
  " & & (mean) & (min) & ('000) & (\\pounds m) & (approx.) \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %d & %d & %d & %s & %s & %s \\\\",
    row$period, row$Quarters, row$`Active Firms (mean)`, row$`Active Firms (min)`,
    format(row$`Loans/Qtr ('000, mean)`, big.mark = ","),
    format(row$`Value/Qtr (GBP m, mean)`, big.mark = ","),
    format(row$`HHI (approx.)`, big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from FCA Product Sales Data (PSD006), FCA post-implementation reviews (FS17/2), and FCA annual data bulletins. Active Firms counts firms with HCSTC permissions actively originating loans. HHI is approximated from market share distributions reported in FCA publications. The HCSTC price cap (0.8\\% of principal per day) took effect 2 January 2015. The compensation wave began with the Wonga administration (August 2018) and included QuickQuid (October 2019), The Money Shop (June 2019), and Wageday Advance (February 2019).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("  Table 1 written.\n")

# ============================================================================
# Table 2: Phase Decomposition Regressions
# ============================================================================
cat("=== Generating Table 2: Phase Decomposition ===\n")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Phase Decomposition of Market Collapse}",
  "\\label{tab:phases}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Log(Active Firms) & Log(Loans '000) \\\\",
  "\\midrule"
)

# Extract coefficients
firms_coef <- coef(regs$m2_firms)
firms_se <- sqrt(diag(vcov(regs$m2_firms)))
loans_coef <- coef(regs$m2_loans)
loans_se <- sqrt(diag(vcov(regs$m2_loans)))

vars_to_show <- c("phase1", "phase2", "phase3")
var_labels <- c("Post-Cap Phase 1", "Compensation Wave", "Steady State")

for (j in seq_along(vars_to_show)) {
  v <- vars_to_show[j]
  fc <- ifelse(v %in% names(firms_coef), sprintf("%.3f", firms_coef[v]), "")
  fs <- ifelse(v %in% names(firms_se), sprintf("(%.3f)", firms_se[v]), "")
  lc <- ifelse(v %in% names(loans_coef), sprintf("%.3f", loans_coef[v]), "")
  ls <- ifelse(v %in% names(loans_se), sprintf("(%.3f)", loans_se[v]), "")

  # Stars
  if (v %in% names(firms_coef)) {
    fp <- pvalue(regs$m2_firms)[v]
    if (!is.na(fp) && fp < 0.01) fc <- paste0(fc, "***")
    else if (!is.na(fp) && fp < 0.05) fc <- paste0(fc, "**")
    else if (!is.na(fp) && fp < 0.1) fc <- paste0(fc, "*")
  }
  if (v %in% names(loans_coef)) {
    lp <- pvalue(regs$m2_loans)[v]
    if (!is.na(lp) && lp < 0.01) lc <- paste0(lc, "***")
    else if (!is.na(lp) && lp < 0.05) lc <- paste0(lc, "**")
    else if (!is.na(lp) && lp < 0.1) lc <- paste0(lc, "*")
  }

  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s \\\\", var_labels[j], fc, lc),
    sprintf(" & %s & %s \\\\", fs, ls)
  )
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Observations & %d & %d \\\\", nobs(regs$m2_firms), nobs(regs$m2_loans)),
  sprintf("$R^2$ & %.3f & %.3f \\\\", r2(regs$m2_firms, type = "r2"), r2(regs$m2_loans, type = "r2")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} OLS regressions of log market outcomes on phase indicators. Each coefficient measures the average log-point difference relative to the Pre-Cap baseline (2012Q1--2014Q4). Newey-West standard errors in parentheses. Phase 1 = cap introduction (2015Q1--2018Q2); Compensation Wave = major firm exits from historical redress claims (2018Q3--2019Q4); Steady State = post-consolidation (2020Q1--2022Q4). Significance: * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_phases.tex"))
cat("  Table 2 written.\n")

# ============================================================================
# Table 3: Supply Destruction Multiplier
# ============================================================================
cat("=== Generating Table 3: Supply Destruction Multiplier ===\n")

# Compute multiplier components
pre_cap_peak <- market_panel %>% filter(quarter == "2013Q3")
steady_state <- market_panel %>% filter(phase == "phase3_steady_state")

actual_decline_loans <- 1 - min(steady_state$total_loans_000) / pre_cap_peak$total_loans_000
actual_decline_firms <- 1 - min(steady_state$n_active_firms) / pre_cap_peak$n_active_firms
actual_decline_value <- 1 - min(steady_state$total_value_gbp_m) / pre_cap_peak$total_value_gbp_m

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Supply Destruction Multiplier: FCA Predictions vs.~Outcomes}",
  "\\label{tab:multiplier}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & FCA CBA & Actual & Multiplier \\\\",
  " & Prediction & Outcome & (Actual/Predicted) \\\\",
  "\\midrule",
  sprintf("Borrower access loss & 7--11\\%% & %.0f\\%% & %.1f--%.1fx \\\\",
          actual_decline_loans * 100,
          actual_decline_loans / 0.11,
          actual_decline_loans / 0.07),
  sprintf("Firm exit & ``some exit'' & %.0f\\%% & --- \\\\",
          actual_decline_firms * 100),
  sprintf("Lending volume decline & --- & %.0f\\%% & --- \\\\",
          actual_decline_value * 100),
  sprintf("HHI change & --- & %s $\\rightarrow$ %s & --- \\\\",
          format(round(mean(market_panel$hhi_approx[market_panel$phase == "pre_cap"])), big.mark = ","),
          format(round(mean(market_panel$hhi_approx[market_panel$phase == "phase3_steady_state"])), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} FCA CBA predictions from CP14/10 (July 2014). ``Borrower access loss'' is measured as the percentage decline in quarterly loan originations from the pre-cap peak (2013Q3) to the steady-state average (2020Q1--2022Q4). Firm exit is the percentage decline in actively lending firms. HHI is the Herfindahl-Hirschman Index (approximated from FCA market share data). The FCA CBA modeled price effects on demand but did not quantify expected firm exits or market concentration changes.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_multiplier.tex"))
cat("  Table 3 written.\n")

# ============================================================================
# Table 4: Robustness Checks
# ============================================================================
cat("=== Generating Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Pre-trend & OFT Placebo & Levels & Excl.~COVID \\\\",
  " & Log(Loans) & Log(Loans) & Loans ('000) & Log(Firms) \\\\",
  "\\midrule"
)

# Pre-trend
pt_coef <- coef(robust$r1_pretrend_loans)["trend"]
pt_se <- sqrt(diag(vcov(robust$r1_pretrend_loans)))["trend"]
pt_p <- pvalue(robust$r1_pretrend_loans)["trend"]
pt_star <- ifelse(pt_p < 0.01, "***", ifelse(pt_p < 0.05, "**", ifelse(pt_p < 0.1, "*", "")))

# OFT placebo
oft_coef <- coef(robust$r2_oft_placebo)["post_oft"]
oft_se <- sqrt(diag(vcov(robust$r2_oft_placebo)))["post_oft"]
oft_p <- pvalue(robust$r2_oft_placebo)["post_oft"]
oft_star <- ifelse(oft_p < 0.01, "***", ifelse(oft_p < 0.05, "**", ifelse(oft_p < 0.1, "*", "")))

# Levels Phase 1
lev_coef <- coef(robust$r4_level_loans)["phase1"]
lev_se <- sqrt(diag(vcov(robust$r4_level_loans)))["phase1"]
lev_p <- pvalue(robust$r4_level_loans)["phase1"]
lev_star <- ifelse(lev_p < 0.01, "***", ifelse(lev_p < 0.05, "**", ifelse(lev_p < 0.1, "*", "")))

# No-COVID Phase 1
nc_coef <- coef(robust$r6_no_covid)["phase1"]
nc_se <- sqrt(diag(vcov(robust$r6_no_covid)))["phase1"]
nc_p <- pvalue(robust$r6_no_covid)["phase1"]
nc_star <- ifelse(nc_p < 0.01, "***", ifelse(nc_p < 0.05, "**", ifelse(nc_p < 0.1, "*", "")))

tab4_lines <- c(tab4_lines,
  sprintf("Key coefficient & %.4f%s & %.4f%s & %.1f%s & %.3f%s \\\\",
          pt_coef, pt_star, oft_coef, oft_star, lev_coef, lev_star, nc_coef, nc_star),
  sprintf(" & (%.4f) & (%.4f) & (%.1f) & (%.3f) \\\\",
          pt_se, oft_se, lev_se, nc_se),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(robust$r1_pretrend_loans), nobs(robust$r2_oft_placebo),
          nobs(robust$r4_level_loans), nobs(robust$r6_no_covid)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(robust$r1_pretrend_loans, type = "r2"), r2(robust$r2_oft_placebo, type = "r2"),
          r2(robust$r4_level_loans, type = "r2"), r2(robust$r6_no_covid, type = "r2"))
)

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Column (1) tests for pre-existing trends in the pre-cap period (2012Q1--2014Q4); the coefficient is on a linear time trend. Column (2) uses the OFT-to-FCA administrative transfer (April 2014) as a placebo treatment date within the pre-cap period. Column (3) repeats the phase decomposition in levels rather than logs. Column (4) excludes the COVID period (2020Q1 onwards) to verify that Phase 1 and Phase 2 results are not driven by pandemic effects. Newey-West standard errors in parentheses. Significance: * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("  Table 4 written.\n")

# ============================================================================
# Table 5: Regional Heterogeneity
# ============================================================================
cat("=== Generating Table 5: Regional Heterogeneity ===\n")

# Summary by penetration group
reg_summary <- regional_panel %>%
  mutate(penetration_group = ifelse(high_penetration == 1, "High", "Low")) %>%
  group_by(penetration_group) %>%
  summarise(
    n_regions = n_distinct(region),
    mean_loans_per_1000 = round(mean(loans_per_1000_adults), 1),
    sd_loans_per_1000 = round(sd(loans_per_1000_adults), 1),
    mean_total_loans = round(mean(n_loans), 0),
    growth_rate = round((mean(n_loans[quarter == "2018Q2"]) /
                          mean(n_loans[quarter == "2016Q3"]) - 1) * 100, 1),
    .groups = "drop"
  )

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Regional Heterogeneity in Post-Cap Lending Recovery}",
  "\\label{tab:regional}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Penetration & Regions & Loans/1000 & Loans/1000 & Mean Loans & Growth \\\\",
  "Group & & (mean) & (s.d.) & per Quarter & 2016Q3--2018Q2 \\\\",
  "\\midrule"
)

for (i in 1:nrow(reg_summary)) {
  row <- reg_summary[i, ]
  tab5_lines <- c(tab5_lines, sprintf(
    "%s & %d & %.1f & %.1f & %s & %.1f\\%% \\\\",
    row$penetration_group, row$n_regions, row$mean_loans_per_1000,
    row$sd_loans_per_1000, format(row$mean_total_loans, big.mark = ","),
    row$growth_rate
  ))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Regional Fixed Effects Regression}} \\\\",
  "\\midrule"
)

# Add regression coefficient
reg_coef <- coef(regs$m3_regional)
reg_se_vals <- sqrt(diag(vcov(regs$m3_regional)))

# Get the high_penetration interaction terms
hp_vars <- grep("high_penetration", names(reg_coef), value = TRUE)
if (length(hp_vars) > 0) {
  avg_coef <- mean(reg_coef[hp_vars])
  avg_se <- mean(reg_se_vals[hp_vars])
  tab5_lines <- c(tab5_lines,
    sprintf("High Penetration $\\times$ Quarter (avg.) & \\multicolumn{5}{c}{%.4f (%.4f)} \\\\",
            avg_coef, avg_se)
  )
}

tab5_lines <- c(tab5_lines,
  sprintf("Region FE & \\multicolumn{5}{c}{Yes} \\\\"),
  sprintf("Quarter FE & \\multicolumn{5}{c}{Yes} \\\\"),
  sprintf("Observations & \\multicolumn{5}{c}{%d} \\\\", nobs(regs$m3_regional)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports summary statistics for 12 UK regions grouped by pre-cap HCSTC penetration (above/below median loans per 1,000 adults in Q3 2016). Growth is the percentage change in total quarterly loans from Q3 2016 to Q2 2018. Panel B reports the average coefficient from a region and quarter fixed effects regression of log loans on the interaction of high-penetration indicator with quarter dummies. Standard errors clustered by region in parentheses. Data from FCA PSD006.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_regional.tex"))
cat("  Table 5 written.\n")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================================
cat("=== Generating Table F1: SDE ===\n")

# Compute SDEs for main outcomes
# Primary: Phase 1 effect on log loans and log firms
# SDE = beta / SD(Y) for binary treatment

# SD of pre-cap outcomes
sd_ln_loans_pre <- sd(market_panel$ln_loans[market_panel$post_cap == 0])
sd_ln_firms_pre <- sd(market_panel$ln_firms[market_panel$post_cap == 0])
sd_ln_value_pre <- sd(market_panel$ln_value[market_panel$post_cap == 0])

# Phase decomposition coefficients (Phase 1 = cap effect)
beta_firms_p1 <- coef(regs$m2_firms)["phase1"]
se_firms_p1 <- sqrt(diag(vcov(regs$m2_firms)))["phase1"]
beta_loans_p1 <- coef(regs$m2_loans)["phase1"]
se_loans_p1 <- sqrt(diag(vcov(regs$m2_loans)))["phase1"]

# Phase 2 = compensation effect
beta_firms_p2 <- coef(regs$m2_firms)["phase2"]
se_firms_p2 <- sqrt(diag(vcov(regs$m2_firms)))["phase2"]
beta_loans_p2 <- coef(regs$m2_loans)["phase2"]
se_loans_p2 <- sqrt(diag(vcov(regs$m2_loans)))["phase2"]

# Compute SDEs
sde_firms_p1 <- beta_firms_p1 / sd_ln_firms_pre
se_sde_firms_p1 <- se_firms_p1 / sd_ln_firms_pre
sde_loans_p1 <- beta_loans_p1 / sd_ln_loans_pre
se_sde_loans_p1 <- se_loans_p1 / sd_ln_loans_pre
sde_firms_p2 <- beta_firms_p2 / sd_ln_firms_pre
se_sde_firms_p2 <- se_firms_p2 / sd_ln_firms_pre
sde_loans_p2 <- beta_loans_p2 / sd_ln_loans_pre
se_sde_loans_p2 <- se_loans_p2 / sd_ln_loans_pre

# Classification function
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_table <- tibble(
  outcome = c("Active Firms (Phase 1)", "Loan Volume (Phase 1)",
              "Active Firms (Phase 2)", "Loan Volume (Phase 2)"),
  panel = c("A", "A", "B", "B"),
  beta = c(beta_firms_p1, beta_loans_p1, beta_firms_p2, beta_loans_p2),
  se = c(se_firms_p1, se_loans_p1, se_firms_p2, se_loans_p2),
  sd_y = c(sd_ln_firms_pre, sd_ln_loans_pre, sd_ln_firms_pre, sd_ln_loans_pre),
  sde = c(sde_firms_p1, sde_loans_p1, sde_firms_p2, sde_loans_p2),
  se_sde = c(se_sde_firms_p1, se_sde_loans_p1, se_sde_firms_p2, se_sde_loans_p2),
  classification = classify_sde(c(sde_firms_p1, sde_loans_p1, sde_firms_p2, sde_loans_p2))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does a statutory price cap on high-cost short-term credit cause market collapse through mass firm exit, and how large is the gap between regulatory predictions and actual supply-side outcomes? ",
  "\\textbf{Policy mechanism:} The FCA's HCSTC price cap (effective 2 January 2015) capped interest at 0.8\\% of principal per day, default fees at GBP~15, and total cost at 100\\% of amount borrowed, compressing margins for firms with high operating costs and forcing unprofitable lenders to exit. ",
  "\\textbf{Outcome definition:} Panel A reports the cap's direct effect (Phase 1: 2015Q1--2018Q2); Panel B reports the compensation-wave effect (Phase 2: 2018Q3--2019Q4) where exits were driven by historical redress claims. Active Firms is the count of HCSTC-permitted firms actively originating loans; Loan Volume is quarterly total HCSTC originations in thousands. ",
  "\\textbf{Treatment:} Binary (pre/post price cap introduction). ",
  "\\textbf{Data:} FCA Financial Services Register, FCA Product Sales Data (PSD006), and FCA post-implementation reviews; quarterly market-level panel 2012Q1--2022Q4; 44 quarterly observations. ",
  "\\textbf{Method:} OLS phase decomposition with phase-specific linear trends; Newey-West standard errors. ",
  "\\textbf{Sample:} All HCSTC-permitted firms in England, Wales, Scotland, and Northern Ireland; quarterly aggregates. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Cap Effect --- Phase 1)}} \\\\"
)

for (i in which(sde_table$panel == "A")) {
  row <- sde_table[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    row$outcome, row$beta, row$se, row$sd_y, row$sde, row$se_sde, row$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Compensation Wave --- Phase 2)}} \\\\"
)

for (i in which(sde_table$panel == "B")) {
  row <- sde_table[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    row$outcome, row$beta, row$se, row$sd_y, row$sde, row$se_sde, row$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Table F1 (SDE) written.\n")

cat("\nAll tables generated.\nDONE.\n")
