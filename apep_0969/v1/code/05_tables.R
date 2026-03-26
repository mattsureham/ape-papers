# 05_tables.R — Generate all LaTeX tables
# Paper: The Compliance Cliff (apep_0969)

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness.RData")
panel[, ym := as.Date(ym)]
panel[, industry_code := sprintf("%02d", as.integer(industry_code))]

dir.create("../tables", showWarnings = FALSE)

# Helper: extract coefficient info
get_coef <- function(model, coef_name = "exempt:post") {
  b <- coef(model)[coef_name]
  se <- sqrt(diag(vcov(model)))[coef_name]
  n <- nobs(model)
  tstat <- b / se
  stars <- ifelse(abs(tstat) > 2.576, "***",
           ifelse(abs(tstat) > 1.96, "**",
           ifelse(abs(tstat) > 1.645, "*", "")))
  list(b = b, se = se, n = n, stars = stars, tstat = tstat)
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

pre <- panel[post == 0]
post_data <- panel[post == 1]

# By exempt status, pre-treatment
s_ex_pre <- pre[exempt == 1, .(hrs_m = mean(hours, na.rm=TRUE), hrs_sd = sd(hours, na.rm=TRUE),
                                days_m = mean(days, na.rm=TRUE), days_sd = sd(days, na.rm=TRUE),
                                N = .N)]
s_ctrl_pre <- pre[exempt == 0, .(hrs_m = mean(hours, na.rm=TRUE), hrs_sd = sd(hours, na.rm=TRUE),
                                  days_m = mean(days, na.rm=TRUE), days_sd = sd(days, na.rm=TRUE),
                                  N = .N)]
# Post
s_ex_post <- post_data[exempt == 1, .(hrs_m = mean(hours, na.rm=TRUE), hrs_sd = sd(hours, na.rm=TRUE),
                                       days_m = mean(days, na.rm=TRUE), days_sd = sd(days, na.rm=TRUE),
                                       N = .N)]
s_ctrl_post <- post_data[exempt == 0, .(hrs_m = mean(hours, na.rm=TRUE), hrs_sd = sd(hours, na.rm=TRUE),
                                         days_m = mean(days, na.rm=TRUE), days_sd = sd(days, na.rm=TRUE),
                                         N = .N)]

tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{3}{c}{Pre-Treatment (Apr 2017--Mar 2024)} & \\multicolumn{3}{c}{Post-Treatment (Apr 2024--Jan 2026)} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}
& Exempt & Control & Diff & Exempt & Control & Diff \\\\
\\midrule
Monthly hours & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\
& (%.1f) & (%.1f) & & (%.1f) & (%.1f) & \\\\
Monthly days & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\
& (%.1f) & (%.1f) & & (%.1f) & (%.1f) & \\\\
\\midrule
Industry-months & \\multicolumn{2}{c}{%d / %d} & & \\multicolumn{2}{c}{%d / %d} \\\\
Industries & \\multicolumn{2}{c}{3 / 16} & & \\multicolumn{2}{c}{3 / 16} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from the Labour Force Survey (Statistics Bureau of Japan). Standard deviations in parentheses. The unit of observation is an industry-month cell. Exempt industries (Construction, Transport/Postal, Medical/Welfare) were exempted from overtime caps under the 2018 Work Style Reform Act until April 2024. Control industries had overtime caps applied from April 2019 (large firms) and April 2020 (SMEs). Hours and days are averages per employed worker.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  s_ex_pre$hrs_m, s_ctrl_pre$hrs_m, s_ex_pre$hrs_m - s_ctrl_pre$hrs_m,
  s_ex_post$hrs_m, s_ctrl_post$hrs_m, s_ex_post$hrs_m - s_ctrl_post$hrs_m,
  s_ex_pre$hrs_sd, s_ctrl_pre$hrs_sd,
  s_ex_post$hrs_sd, s_ctrl_post$hrs_sd,
  s_ex_pre$days_m, s_ctrl_pre$days_m, s_ex_pre$days_m - s_ctrl_pre$days_m,
  s_ex_post$days_m, s_ctrl_post$days_m, s_ex_post$days_m - s_ctrl_post$days_m,
  s_ex_pre$days_sd, s_ctrl_pre$days_sd,
  s_ex_post$days_sd, s_ctrl_post$days_sd,
  s_ex_pre$N, s_ctrl_pre$N, s_ex_post$N, s_ctrl_post$N
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("Generating Table 2: Main Results...\n")

r1 <- get_coef(m1)
r2 <- get_coef(m2)
r3 <- get_coef(m3)
r_male <- get_coef(m_male)
r_female <- get_coef(m_female)

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of Overtime Cap Application on Exempt Industries}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Hours & Days & Hours/Day & Hours & Hours \\\\
& (All) & (All) & (All) & (Male) & (Female) \\\\
\\midrule
Exempt $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\
\\\\
RI $p$-value & [%.3f] & & & & \\\\
\\\\
Industry FE & Yes & Yes & Yes & Yes & Yes \\\\
Year-Month FE & Yes & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s & %s \\\\
Pre-treatment mean & %.1f & %.1f & %.2f & %.1f & %.1f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the industry level in parentheses. Randomization inference $p$-value from 2,000 permutations in brackets. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Each column reports the coefficient on the interaction of an exempt-industry indicator with a post-April-2024 indicator. Exempt industries: Construction, Transport/Postal, and Medical/Welfare. Pre-treatment means calculated for exempt industries over April 2017--March 2024.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  r1$b, r1$stars, r2$b, r2$stars, r3$b, r3$stars, r_male$b, r_male$stars, r_female$b, r_female$stars,
  r1$se, r2$se, r3$se, r_male$se, r_female$se,
  ri_pvalue,
  format(r1$n, big.mark=","), format(r2$n, big.mark=","),
  format(r3$n, big.mark=","), format(r_male$n, big.mark=","),
  format(r_female$n, big.mark=","),
  mean(panel[exempt==1 & post==0, hours], na.rm=TRUE),
  mean(panel[exempt==1 & post==0, days], na.rm=TRUE),
  mean(panel[exempt==1 & post==0, hours/days], na.rm=TRUE),
  mean(male_panel[exempt==1 & post==0, hours], na.rm=TRUE),
  mean(female_panel[exempt==1 & post==0, hours], na.rm=TRUE)
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# TABLE 3: Robustness
# ============================================================================
cat("Generating Table 3: Robustness...\n")

r_nocovid <- get_coef(m_nocovid)
r_placebo <- get_coef(m_placebo, "exempt:fake_post")
r_placebo2 <- get_coef(m_placebo2, "exempt:fake_post2")
r_antic <- get_coef(m_antic, "exempt:antic_post")

# By-industry DiD
did_09 <- (mean(panel[industry_code=="09" & post==1, hours]) - mean(panel[industry_code=="09" & post==0, hours])) -
          (mean(panel[exempt==0 & post==1, hours]) - mean(panel[exempt==0 & post==0, hours]))
did_42 <- (mean(panel[industry_code=="42" & post==1, hours]) - mean(panel[industry_code=="42" & post==0, hours])) -
          (mean(panel[exempt==0 & post==1, hours]) - mean(panel[exempt==0 & post==0, hours]))
did_78 <- (mean(panel[industry_code=="78" & post==1, hours]) - mean(panel[industry_code=="78" & post==0, hours])) -
          (mean(panel[exempt==0 & post==1, hours]) - mean(panel[exempt==0 & post==0, hours]))

# MDE
se_main <- r1$se
mde_05 <- 2.8 * se_main

tab3 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks and Heterogeneity}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Specification & Coefficient & (SE) \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Specification Robustness}} \\\\
Baseline (Table~\\ref{tab:main}, Col.~1) & %.3f & (%.3f) \\\\
Post-COVID only (2022--2026) & %.3f & (%.3f) \\\\
Placebo: fake treatment April 2022 & %.3f & (%.3f) \\\\
Placebo: fake treatment April 2021 & %.3f & (%.3f) \\\\
Anticipation test (Jan--Mar 2024 vs.~Oct--Dec 2023) & %.3f & (%.3f) \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel B: By Exempt Industry (simple DiD)}} \\\\
Construction & %.2f & \\\\
Transport/Postal & %.2f & \\\\
Medical/Welfare & %.2f & \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel C: Power}} \\\\
MDE ($\\alpha$=0.05, 80\\%% power) & \\multicolumn{2}{c}{%.2f hours (%.1f\\%% of exempt mean)} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the coefficient on Exempt $\\times$ Post from alternative specifications. All include industry and year-month fixed effects with standard errors clustered at the industry level. Panel B reports simple difference-in-differences estimates for each exempt industry individually against the mean of all non-exempt industries; standard errors are not computed because each sub-DiD involves only one treated industry. Panel C reports the minimum detectable effect at conventional thresholds.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  r1$b, r1$se,
  r_nocovid$b, r_nocovid$se,
  r_placebo$b, r_placebo$se,
  r_placebo2$b, r_placebo2$se,
  r_antic$b, r_antic$se,
  did_09, did_42, did_78,
  mde_05, 100 * mde_05 / mean(panel[exempt==1 & post==0, hours])
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ============================================================================
# TABLE F1: SDE (Standardized Effect Sizes)
# ============================================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Pooled
b_hrs <- r1$b
se_hrs <- r1$se
sd_y_hrs <- sd(panel[post == 0, hours], na.rm = TRUE)
sde_hrs <- b_hrs / sd_y_hrs
se_sde_hrs <- se_hrs / sd_y_hrs

b_days <- r2$b
se_days <- r2$se
sd_y_days <- sd(panel[post == 0, days], na.rm = TRUE)
sde_days <- b_days / sd_y_days
se_sde_days <- se_days / sd_y_days

classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Heterogeneous: by sex
b_male <- r_male$b
se_male <- r_male$se
sd_y_male <- sd(male_panel[post == 0, hours], na.rm = TRUE)
sde_male <- b_male / sd_y_male
se_sde_male <- se_male / sd_y_male

b_female <- r_female$b
se_female <- r_female$se
sd_y_female <- sd(female_panel[post == 0, hours], na.rm = TRUE)
sde_female <- b_female / sd_y_female
se_sde_female <- se_female / sd_y_female

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does the application of statutory overtime caps to previously exempted industries reduce worker hours and days worked? ",
  "\\textbf{Policy mechanism:} The 2018 Work Style Reform Act imposed binding monthly and annual overtime caps on most Japanese industries from April 2019, but granted five-year exemptions to transport, construction, and healthcare due to their ``distinctive'' labor demands. When exemptions expired in April 2024, these industries faced the same caps as all other sectors, creating a compliance cliff where firms had to immediately limit previously unconstrained overtime scheduling. ",
  "\\textbf{Outcome definition:} Average monthly hours worked per employed person, measured by the Labour Force Survey (household-based) at the industry-month level. ",
  "\\textbf{Treatment:} Binary---industry exempt from overtime caps until April 2024 vs.~already subject to caps since April 2019. ",
  "\\textbf{Data:} Labour Force Survey via e-Stat API, April 2017--January 2026, industry-month level, 19 major industries (excluding aggregates). ",
  "\\textbf{Method:} Two-way fixed effects DiD with industry and year-month fixed effects, standard errors clustered at the industry level, supplemented by randomization inference (2,000 permutations). ",
  "\\textbf{Sample:} All employed persons across 19 major industry divisions; 3 exempt industries (Construction, Transport/Postal, Medical/Welfare) and 16 non-exempt industries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Monthly hours & Baseline DiD & %.3f & %.2f & %.4f & %.4f & %s \\\\
Monthly days & Baseline DiD & %.3f & %.2f & %.4f & %.4f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sex)}} \\\\
Monthly hours & Male workers & %.3f & %.2f & %.4f & %.4f & %s \\\\
Monthly hours & Female workers & %.3f & %.2f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  b_hrs, sd_y_hrs, sde_hrs, se_sde_hrs, classify(sde_hrs),
  b_days, sd_y_days, sde_days, se_sde_days, classify(sde_days),
  b_male, sd_y_male, sde_male, se_sde_male, classify(sde_male),
  b_female, sd_y_female, sde_female, se_sde_female, classify(sde_female),
  sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
