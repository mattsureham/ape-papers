# =============================================================================
# 05_tables.R — Generate all tables including SDE appendix
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robust_results.rds")
df <- readRDS("../data/analysis_lowwage.rds")
sumstats <- readRDS("../data/sumstats.rds")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Compute treated vs never-treated splits
ss_treated <- df %>%
  filter(treated == 1) %>%
  summarise(
    mean_bhs = mean(black_hire_share, na.rm = TRUE),
    sd_bhs = sd(black_hire_share, na.rm = TRUE),
    mean_bwer = mean(bw_earn_ratio, na.rm = TRUE),
    sd_bwer = sd(bw_earn_ratio, na.rm = TRUE),
    mean_hires = mean(total_hires, na.rm = TRUE),
    sd_hires = sd(total_hires, na.rm = TRUE),
    n = n()
  )

ss_control <- df %>%
  filter(treated == 0) %>%
  summarise(
    mean_bhs = mean(black_hire_share, na.rm = TRUE),
    sd_bhs = sd(black_hire_share, na.rm = TRUE),
    mean_bwer = mean(bw_earn_ratio, na.rm = TRUE),
    sd_bwer = sd(bw_earn_ratio, na.rm = TRUE),
    mean_hires = mean(total_hires, na.rm = TRUE),
    sd_hires = sd(total_hires, na.rm = TRUE),
    n = n()
  )

ss_all <- df %>%
  summarise(
    mean_bhs = mean(black_hire_share, na.rm = TRUE),
    sd_bhs = sd(black_hire_share, na.rm = TRUE),
    mean_bwer = mean(bw_earn_ratio, na.rm = TRUE),
    sd_bwer = sd(bw_earn_ratio, na.rm = TRUE),
    mean_bsr = mean(black_sep_rate, na.rm = TRUE),
    sd_bsr = sd(black_sep_rate, na.rm = TRUE),
    mean_hires = mean(total_hires, na.rm = TRUE),
    sd_hires = sd(total_hires, na.rm = TRUE),
    n = n()
  )

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Low-Wage Industries (NAICS 72, 44--45)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
 & \\multicolumn{2}{c}{All} & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Never-Treated} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
Variable & Mean & SD & Mean & SD & Mean & SD \\\\
\\midrule
Black share of new hires & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\
Black--White earnings ratio & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\
Black separation rate & %.3f & %.3f & --- & --- & --- & --- \\\\
Total new hires (county-year) & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\
\\midrule
County-year observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from Census QWI race/ethnicity files (LEHD), 2005--2024. Low-wage industries are Accommodation and Food Services (NAICS 72) and Retail Trade (NAICS 44--45). Black share of new hires is the ratio of Black new hires to total (Black + White) new hires. Earnings ratio is mean monthly earnings of Black workers divided by White workers. Counties with fewer than 10 total hires per year are excluded.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
ss_all$mean_bhs, ss_all$sd_bhs, ss_treated$mean_bhs, ss_treated$sd_bhs, ss_control$mean_bhs, ss_control$sd_bhs,
ss_all$mean_bwer, ss_all$sd_bwer, ss_treated$mean_bwer, ss_treated$sd_bwer, ss_control$mean_bwer, ss_control$sd_bwer,
ss_all$mean_bsr, ss_all$sd_bsr,
ss_all$mean_hires, ss_all$sd_hires, ss_treated$mean_hires, ss_treated$sd_hires, ss_control$mean_hires, ss_control$sd_hires,
format(ss_all$n, big.mark = ","), format(ss_treated$n, big.mark = ","), format(ss_control$n, big.mark = ",")
)

writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main Results — CS DiD and TWFE
# =============================================================================
cat("Generating Table 2: Main Results...\n")

# Extract CS results
cs_bhs_att <- results$cs_bhs_agg$overall.att
cs_bhs_se <- results$cs_bhs_agg$overall.se
cs_bwer_att <- results$cs_bwer_agg$overall.att
cs_bwer_se <- results$cs_bwer_agg$overall.se
cs_bsr_att <- results$cs_bsr_agg$overall.att
cs_bsr_se <- results$cs_bsr_agg$overall.se

# Extract TWFE results
twfe_bhs_coef <- coef(results$twfe_bhs)["post"]
twfe_bhs_se <- se(results$twfe_bhs)["post"]
twfe_bwer_coef <- coef(results$twfe_bwer)["post"]
twfe_bwer_se <- se(results$twfe_bwer)["post"]

# Triple-diff
triple_coef <- coef(results$twfe_triple)[1]
triple_se <- se(results$twfe_triple)[1]

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

cs_bhs_p <- 2 * pnorm(-abs(cs_bhs_att / cs_bhs_se))
cs_bwer_p <- 2 * pnorm(-abs(cs_bwer_att / cs_bwer_se))
cs_bsr_p <- 2 * pnorm(-abs(cs_bsr_att / cs_bsr_se))
twfe_bhs_p <- pvalue(results$twfe_bhs)["post"]
twfe_bwer_p <- pvalue(results$twfe_bwer)["post"]
triple_p <- pvalue(results$twfe_triple)[1]

n_main <- nrow(df)
n_earn <- nrow(df %>% filter(!is.na(bw_earn_ratio)))
n_sep <- nrow(df %>% filter(!is.na(black_sep_rate)))
n_states_treated <- n_distinct(df$state_fips[df$treated == 1])
n_states_control <- n_distinct(df$state_fips[df$treated == 0])

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Main Results: Effect of Minimum Wage Increases on Racial Composition of Hiring}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & CS DiD & CS DiD & TWFE & Triple-Diff \\\\
 & Black Hire & B--W Earnings & Black Hire & Black Hire \\\\
 & Share & Ratio & Share & Share \\\\
\\midrule
ATT / Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\
\\\\
Observations & %s & %s & %s & %s \\\\
Counties & %s & %s & %s & --- \\\\
Treated states & %d & %d & %d & %d \\\\
Control states & %d & %d & %d & %d \\\\
County FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Industry FE & --- & --- & --- & Yes \\\\
Clustering & State & State & State & State \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Columns (1)--(2) report Callaway--Sant'Anna (2021) doubly robust ATT estimates with never-treated states as the control group. Column (3) reports two-way fixed effects estimates. Column (4) reports a triple-difference comparing MW-exposed industries (NAICS 72, 44--45) to non-exposed industries (NAICS 52, 54) within the same county-year, with county$\\times$industry, year$\\times$industry, and county$\\times$year fixed effects. Standard errors clustered at the state level in parentheses.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
cs_bhs_att, stars(cs_bhs_p), cs_bwer_att, stars(cs_bwer_p),
twfe_bhs_coef, stars(twfe_bhs_p), triple_coef, stars(triple_p),
cs_bhs_se, cs_bwer_se, twfe_bhs_se, triple_se,
format(n_main, big.mark = ","), format(n_earn, big.mark = ","),
format(n_main, big.mark = ","), format(nrow(readRDS("../data/analysis_triple.rds") %>% filter(!is.na(black_hire_share), total_hires >= 10)), big.mark = ","),
format(n_distinct(df$county_fips), big.mark = ","),
format(n_distinct(df %>% filter(!is.na(bw_earn_ratio)) %>% pull(county_fips) %>% unique()), big.mark = ","),
format(n_distinct(df$county_fips), big.mark = ","),
n_states_treated, n_states_treated, n_states_treated, n_states_treated,
n_states_control, n_states_control, n_states_control, n_states_control
)

writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Robustness — Placebo and Alternative Threshold
# =============================================================================
cat("Generating Table 3: Robustness...\n")

placebo_coef <- coef(robust$twfe_placebo)["post"]
placebo_se <- se(robust$twfe_placebo)["post"]
placebo_p <- pvalue(robust$twfe_placebo)["post"]
alt_coef <- coef(robust$twfe_alt)["post_120"]
alt_se <- se(robust$twfe_alt)["post_120"]
alt_p <- pvalue(robust$twfe_alt)["post_120"]

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness: Placebo Sector and Alternative Treatment Threshold}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Placebo: Healthcare & Alt. Threshold (120\\%%) \\\\
 & (NAICS 62) & \\\\
\\midrule
Post $\\times$ Treated & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) \\\\
\\\\
County FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Clustering & State & State \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1) runs the main specification on Healthcare (NAICS 62), where the minimum wage is less binding due to higher baseline wages. A null result supports the interpretation that effects in the main analysis are driven by minimum wage exposure. Column (2) uses a stricter treatment definition requiring the state MW to exceed 120\\%% of the federal minimum (\\$8.70). Standard errors clustered at the state level.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
placebo_coef, stars(placebo_p), alt_coef, stars(alt_p),
placebo_se, alt_se
)

writeLines(tab3, "../tables/tab3_robust.tex")

# =============================================================================
# Table 4: Heterogeneity
# =============================================================================
cat("Generating Table 4: Heterogeneity...\n")

hb_coef <- coef(robust$twfe_high_black)["post"]
hb_se <- se(robust$twfe_high_black)["post"]
hb_p <- pvalue(robust$twfe_high_black)["post"]
lb_coef <- coef(robust$twfe_low_black)["post"]
lb_se <- se(robust$twfe_low_black)["post"]
lb_p <- pvalue(robust$twfe_low_black)["post"]
lgb_coef <- coef(robust$twfe_large_bite)["post"]
lgb_se <- se(robust$twfe_large_bite)["post"]
lgb_p <- pvalue(robust$twfe_large_bite)["post"]
smb_coef <- coef(robust$twfe_small_bite)["post"]
smb_se <- se(robust$twfe_small_bite)["post"]
smb_p <- pvalue(robust$twfe_small_bite)["post"]

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Heterogeneity by Baseline Black Share and MW Bite}
\\label{tab:het}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & High Black & Low Black & Large MW & Small MW \\\\
 & Share & Share & Bite & Bite \\\\
\\midrule
Post $\\times$ Treated & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\
\\\\
County FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Clustering & State & State & State & State \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Sample split by pre-treatment (2005--2008) median county-level Black share of new hires (columns 1--2) and by whether the state achieved a minimum wage exceeding \\$10 by 2016 (columns 3--4). Standard errors clustered at the state level.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
hb_coef, stars(hb_p), lb_coef, stars(lb_p), lgb_coef, stars(lgb_p), smb_coef, stars(smb_p),
hb_se, lb_se, lgb_se, smb_se
)

writeLines(tab4, "../tables/tab4_het.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# =============================================================================
cat("Generating SDE table...\n")

# Compute SDEs
sd_bhs <- sd(df$black_hire_share, na.rm = TRUE)
sd_bwer <- sd(df$bw_earn_ratio[!is.na(df$bw_earn_ratio)])
sd_bsr <- sd(df$black_sep_rate[!is.na(df$black_sep_rate)])

# Panel A: Pooled
sde_bhs <- cs_bhs_att / sd_bhs
se_sde_bhs <- cs_bhs_se / sd_bhs
sde_bwer <- cs_bwer_att / sd_bwer
se_sde_bwer <- cs_bwer_se / sd_bwer
sde_bsr <- cs_bsr_att / sd_bsr
se_sde_bsr <- cs_bsr_se / sd_bsr

# Panel B: Heterogeneous (high vs low baseline Black share)
sde_hb <- hb_coef / sd_bhs
se_sde_hb <- hb_se / sd_bhs
sde_lb <- lb_coef / sd_bhs
se_sde_lb <- lb_se / sd_bhs

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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state minimum wage increases alter the racial composition of new hires ",
  "in low-wage industries, as predicted by Becker's (1957) model of taste-based discrimination? ",
  "\\textbf{Policy mechanism:} State minimum wage laws set a binding wage floor that compresses the lower tail of the ",
  "wage distribution; when employers cannot hire minority workers at a discount, the wage wedge that sustains ",
  "taste-based discrimination shrinks, potentially equalizing hiring across racial groups. ",
  "\\textbf{Outcome definition:} Black share of new hires (ratio of Black new hires to Black-plus-White new hires) from ",
  "Census LEHD Quarterly Workforce Indicators, measured at the county-year level; Black--White earnings ratio ",
  "(mean monthly earnings of Black workers divided by White workers); Black separation rate ",
  "(annual Black separations divided by average Black employment). ",
  "\\textbf{Treatment:} Binary indicator for state effective minimum wage exceeding 110\\% of the federal minimum (\\$7.98). ",
  "\\textbf{Data:} Census QWI race/ethnicity files (LEHD), county-year level, 2005--2024, ",
  "low-wage industries (Accommodation/Food Services NAICS 72, Retail Trade NAICS 44--45). ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with doubly robust estimation, ",
  "never-treated states as control group, standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with at least 10 total (Black + White) new hires per year in low-wage industries; ",
  "excludes state-level aggregates and counties with suppressed race-specific data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
Black hire share & CS DiD & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
B--W earnings ratio & CS DiD & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Black separation rate & CS DiD & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by baseline Black share)}} \\\\
High Black share counties & TWFE & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Low Black share counties & TWFE & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
cs_bhs_att, cs_bhs_se, sd_bhs, sde_bhs, se_sde_bhs, classify(sde_bhs),
cs_bwer_att, cs_bwer_se, sd_bwer, sde_bwer, se_sde_bwer, classify(sde_bwer),
cs_bsr_att, cs_bsr_se, sd_bsr, sde_bsr, se_sde_bsr, classify(sde_bsr),
hb_coef, hb_se, sd_bhs, sde_hb, se_sde_hb, classify(sde_hb),
lb_coef, lb_se, sd_bhs, sde_lb, se_sde_lb, classify(sde_lb),
sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

# =============================================================================
# Table A1: Event Study Coefficients
# =============================================================================
cat("Generating event study table...\n")

es_data <- data.frame(
  event_time = results$cs_bhs_es$egt,
  att = results$cs_bhs_es$att.egt,
  se = results$cs_bhs_es$se.egt
)

es_rows <- paste(apply(es_data, 1, function(row) {
  p <- 2 * pnorm(-abs(as.numeric(row["att"]) / as.numeric(row["se"])))
  sprintf("$e = %+d$ & %.4f%s & (%.4f)",
          as.integer(row["event_time"]),
          as.numeric(row["att"]),
          stars(p),
          as.numeric(row["se"]))
}), collapse = " \\\\\n")

tabA1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Event Study Coefficients: Black Share of New Hires}
\\label{tab:event_study}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time & ATT & SE \\\\
\\midrule
%s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Callaway--Sant'Anna (2021) dynamic aggregation. Event time 0 is the year the state minimum wage first exceeds 110\\%% of the federal floor. Standard errors based on analytical formula from the \\texttt{did} package.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", es_rows)

writeLines(tabA1, "../tables/tabA1_event_study.tex")

cat("\nAll tables generated.\n")
