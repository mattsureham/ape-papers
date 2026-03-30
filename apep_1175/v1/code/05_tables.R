# =============================================================================
# 05_tables.R — Generate all tables for AER: Insights paper
# =============================================================================

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

panel <- fread("../data/analysis_panel.csv")
load("../data/main_results.RData")
load("../data/robustness_results.RData")
pre_sd <- fread("../data/pre_treatment_sd.csv")

prime <- panel[age_group == "prime_age" & year %in% 2005:2019]

# Helper: format coefficient with stars
fmt_coef <- function(model, coef_name, digits = 4) {
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- 2 * pt(-abs(b/s), df = model$nobs - length(coef(model)))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  sprintf("$%s%s$", formatC(b, format = "f", digits = digits), stars)
}

fmt_se <- function(model, coef_name, digits = 4) {
  sprintf("(%s)", formatC(se(model)[coef_name], format = "f", digits = digits))
}

# ─────────────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────────────
message("Generating Table 1: Summary Statistics...")

pre_data <- prime[year < 2010]

county_stats <- pre_data[, .(
  emp = mean(Emp, na.rm = TRUE),
  earn = mean(EarnS, na.rm = TRUE),
  hire_rate = mean(hire_rate, na.rm = TRUE),
  sep_rate = mean(sep_rate, na.rm = TRUE),
  oxy_share = first(oxy_share),
  total_pills_pc = first(total_pills_pc),
  pop = first(pop_2009)
), by = fips]

# Full sample and by quartile
q_breaks <- quantile(county_stats$oxy_share, c(0, 0.25, 0.5, 0.75, 1))
county_stats[, oxy_q := cut(oxy_share, breaks = q_breaks, include.lowest = TRUE,
                              labels = c("Q1 (Low)", "Q2", "Q3", "Q4 (High)"))]

make_row <- function(dt, label) {
  sprintf("%s & %d & %s & \\$%s & %s & %s & %s \\\\",
    label, nrow(dt),
    formatC(mean(dt$emp, na.rm=TRUE), format="f", digits=0, big.mark=","),
    formatC(mean(dt$earn, na.rm=TRUE), format="f", digits=0, big.mark=","),
    formatC(mean(dt$hire_rate, na.rm=TRUE), format="f", digits=3),
    formatC(mean(dt$sep_rate, na.rm=TRUE), format="f", digits=3),
    formatC(mean(dt$oxy_share), format="f", digits=3))
}

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Reform County Characteristics (2005--2009)}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & $N$ & Emp & Earnings & Hire & Sep & OxyContin \\\\\n",
  " & & (mean) & (mean) & Rate & Rate & Share \\\\\n",
  "\\midrule\n",
  make_row(county_stats, "Full Sample"), "\n",
  "\\midrule\n",
  make_row(county_stats[oxy_q == "Q1 (Low)"], "Q1 (Low share)"), "\n",
  make_row(county_stats[oxy_q == "Q2"], "Q2"), "\n",
  make_row(county_stats[oxy_q == "Q3"], "Q3"), "\n",
  make_row(county_stats[oxy_q == "Q4 (High)"], "Q4 (High share)"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Employment, earnings, hire rates, and separation rates are from QWI for prime-age workers (25--44), averaged over 2005--2009. ",
  "OxyContin Share is the county-level share of oxycodone pills that were OxyContin brand, from DEA ARCOS (2006--2009 average). ",
  "Quartiles based on OxyContin Share. Counties with population $<$ 1,000 or zero oxycodone excluded.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 2: Main Results — Static DiD
# ─────────────────────────────────────────────────────────────────────────────
message("Generating Table 2: Main Results...")

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{OxyContin Reformulation Exposure and Prime-Age Labor Market Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Log Emp & Log Earn & Sep Rate & Hire Rate \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("OxyContin Share $\\times$ Post & %s & %s & %s & %s \\\\\n",
    fmt_coef(static_emp, "oxy_share_post"),
    fmt_coef(static_earn, "oxy_share_post"),
    fmt_coef(static_sep, "oxy_share_post"),
    fmt_coef(static_hire, "oxy_share_post")),
  sprintf(" & %s & %s & %s & %s \\\\\n",
    fmt_se(static_emp, "oxy_share_post"),
    fmt_se(static_earn, "oxy_share_post"),
    fmt_se(static_sep, "oxy_share_post"),
    fmt_se(static_hire, "oxy_share_post")),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
    format(nobs(static_emp), big.mark=","),
    format(nobs(static_earn), big.mark=","),
    format(nobs(static_sep), big.mark=","),
    format(nobs(static_hire), big.mark=",")),
  sprintf("Counties & %s & %s & %s & %s \\\\\n",
    format(length(fixef(static_emp)$fips), big.mark=","),
    format(length(fixef(static_earn)$fips), big.mark=","),
    format(length(fixef(static_sep)$fips), big.mark=","),
    format(length(fixef(static_hire)$fips), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ",
  "OxyContin Share is the pre-reform (2006--2009) county-level share of oxycodone that was OxyContin brand from DEA ARCOS. ",
  "Post $= 1$ for years $\\geq$ 2010. All regressions control for total opioid pills per capita $\\times$ year. ",
  "Prime-age workers (25--44). Population-weighted. Sample: 2005--2019.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 3: Heterogeneity by Age Group
# ─────────────────────────────────────────────────────────────────────────────
message("Generating Table 3: Heterogeneity by age group...")

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by Age Group: Employment Effects of Reformulation Exposure}\n",
  "\\label{tab:hetero}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & All Ages & Prime-Age & Young & Older & Elderly \\\\\n",
  " & & (25--44) & (14--24) & (45--64) & (65+) \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("OxyContin Share $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
    fmt_coef(static_emp_all, "oxy_share_post"),
    fmt_coef(static_emp, "oxy_share_post"),
    fmt_coef(static_emp_young, "oxy_share_post"),
    fmt_coef(static_emp_older, "oxy_share_post"),
    fmt_coef(rob_elderly, "oxy_share_post")),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
    fmt_se(static_emp_all, "oxy_share_post"),
    fmt_se(static_emp, "oxy_share_post"),
    fmt_se(static_emp_young, "oxy_share_post"),
    fmt_se(static_emp_older, "oxy_share_post"),
    fmt_se(rob_elderly, "oxy_share_post")),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
    format(nobs(static_emp_all), big.mark=","),
    format(nobs(static_emp), big.mark=","),
    format(nobs(static_emp_young), big.mark=","),
    format(nobs(static_emp_older), big.mark=","),
    format(nobs(rob_elderly), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: log employment. Standard errors clustered at the state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ",
  "All specifications include county and year FE and control for total opioid pills per capita $\\times$ year. Population-weighted. ",
  "Elderly (65+) serves as a placebo group less affected by opioid misuse.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_hetero.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table 4: Robustness
# ─────────────────────────────────────────────────────────────────────────────
message("Generating Table 4: Robustness...")

rob_coef_name_short <- "oxy_share_short_post"

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness of Employment Effects}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Baseline & 2008--09 IV & Trimmed & Unweighted & Alt.\\ Cluster \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("OxyContin Share $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
    fmt_coef(static_emp, "oxy_share_post"),
    fmt_coef(rob_short, rob_coef_name_short),
    fmt_coef(rob_trimmed, "oxy_share_post"),
    fmt_coef(rob_unweight, "oxy_share_post"),
    fmt_coef(rob_cz_cluster, "oxy_share_post")),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
    fmt_se(static_emp, "oxy_share_post"),
    fmt_se(rob_short, rob_coef_name_short),
    fmt_se(rob_trimmed, "oxy_share_post"),
    fmt_se(rob_unweight, "oxy_share_post"),
    fmt_se(rob_cz_cluster, "oxy_share_post")),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
    format(nobs(static_emp), big.mark=","),
    format(nobs(rob_short), big.mark=","),
    format(nobs(rob_trimmed), big.mark=","),
    format(nobs(rob_unweight), big.mark=","),
    format(nobs(rob_cz_cluster), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: log employment, prime-age (25--44). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ",
  "Column 1: baseline (state-clustered, population-weighted). ",
  "Column 2: instrument from 2008--2009 only. Column 3: drops top/bottom 5\\% of OxyContin share. ",
  "Column 4: unweighted. Column 5: two-way clustered (state $\\times$ year). ",
  "County and year FE throughout.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ─────────────────────────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ─────────────────────────────────────────────────────────────────────────────
message("Generating SDE table...")

sd_x <- sd(prime[year == 2009]$oxy_share)

get_sde <- function(model, coef_name, sd_y, outcome_label) {
  beta <- coef(model)[coef_name]
  se_beta <- se(model)[coef_name]
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  classify <- ifelse(sde < -0.15, "Large negative",
    ifelse(sde < -0.05, "Moderate negative",
    ifelse(sde < -0.005, "Small negative",
    ifelse(sde <= 0.005, "Null",
    ifelse(sde <= 0.05, "Small positive",
    ifelse(sde <= 0.15, "Moderate positive", "Large positive"))))))
  data.table(Outcome = outcome_label, beta = beta, se = se_beta,
             sd_y = sd_y, sde = sde, se_sde = se_sde, classification = classify)
}

sde_rows <- rbind(
  get_sde(static_emp, "oxy_share_post", pre_sd$sd_log_emp, "Log Employment"),
  get_sde(static_earn, "oxy_share_post", pre_sd$sd_log_earn, "Log Earnings"),
  get_sde(static_sep, "oxy_share_post", pre_sd$sd_sep_rate, "Separation Rate"),
  get_sde(static_hire, "oxy_share_post", pre_sd$sd_hire_rate, "Hire Rate")
)

# Panel B: heterogeneous by age
sde_hetero <- rbind(
  get_sde(static_emp, "oxy_share_post", pre_sd$sd_log_emp, "Log Emp (Prime-Age 25--44)"),
  get_sde(static_emp_older, "oxy_share_post",
          panel[age_group == "older" & year < 2010, sd(log_emp, na.rm = TRUE)],
          "Log Emp (Older 45--64)")
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2010 OxyContin abuse-deterrent reformulation, which shifted opioid misuse from prescription to illicit sources, cause labor market scarring in exposed communities? ",
  "\\textbf{Policy mechanism:} Purdue Pharma replaced crushable OxyContin with an abuse-deterrent formulation in August 2010, eliminating the ability to crush, snort, or inject the pill; counties with higher pre-reform OxyContin brand dependence experienced larger disruptions to their divertible opioid supply, forcing users toward heroin and illicit fentanyl. ",
  "\\textbf{Outcome definition:} QWI log employment (beginning-of-quarter count of workers with UI-covered earnings), log average monthly earnings, quarterly separation rate, and quarterly hire rate for prime-age workers (25--44). ",
  "\\textbf{Treatment:} Continuous; pre-reform (2006--2009) county-level OxyContin brand share of total oxycodone pill shipments from DEA ARCOS, interacted with a post-2010 indicator. ",
  "\\textbf{Data:} DEA ARCOS (178.6M transactions, 2006--2012) for the instrument; Census QWI/LEHD (county-quarter-age, 2005--2019) for outcomes; ACS 5-year population estimates for weights. ",
  sprintf("\\textbf{Method:} Continuous-treatment difference-in-differences with county and year fixed effects, controlling for total opioid pills per capita $\\times$ year; standard errors clustered at state level (%d clusters); population-weighted. ",
          uniqueN(prime$state_fips)),
  sprintf("\\textbf{Sample:} %s counties with population $\\geq$ 1,000 and positive oxycodone shipments, observed 2005--2019 (%s county-year observations). ",
          format(uniqueN(prime$fips), big.mark = ","),
          format(nrow(prime), big.mark = ",")),
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of OxyContin share and SD($Y$) is the pre-treatment standard deviation of each outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Prime-Age 25--44)}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_tex <- paste0(sde_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits by Age)}} \\\\\n"
)

for (i in 1:nrow(sde_hetero)) {
  r <- sde_hetero[i]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

message("=== All tables generated ===")
