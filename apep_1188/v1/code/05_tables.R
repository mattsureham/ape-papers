# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================

source("00_packages.R")

models <- readRDS("../data/main_models.rds")
robustness <- readRDS("../data/robustness_models.rds")
panel <- readRDS("../data/panel_balanced.rds")
diag <- jsonlite::read_json("../data/diagnostics.json")

# --- Helper: format significance stars ---
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)
fmt3 <- function(x) formatC(x, format = "f", digits = 3)

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics\n")

panel <- panel %>%
  mutate(yq = year + (quarter - 1) / 4)

sum_stats <- panel %>%
  group_by(naics2) %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hira = mean(HirA, na.rm = TRUE),
    sd_hira = sd(HirA, na.rm = TRUE),
    mean_sep = mean(Sep, na.rm = TRUE),
    sd_sep = sd(Sep, na.rm = TRUE),
    mean_earns = mean(EarnS, na.rm = TRUE),
    sd_earns = sd(EarnS, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  )

ind_labels <- c("51" = "Information", "52" = "Finance", "54" = "Professional Svc.", "72" = "Accommodation")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: County-Quarter Panel, 2016--2020}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lcccccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Hires} & \\multicolumn{2}{c}{Separations} & \\multicolumn{2}{c}{Earnings (\\$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}",
  "Industry & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sum_stats))) {
  r <- sum_stats[i, ]
  lab <- ind_labels[r$naics2]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
    lab,
    formatC(r$mean_emp, format = "f", digits = 0, big.mark = ","),
    formatC(r$sd_emp, format = "f", digits = 0, big.mark = ","),
    formatC(r$mean_hira, format = "f", digits = 0, big.mark = ","),
    formatC(r$sd_hira, format = "f", digits = 0, big.mark = ","),
    formatC(r$mean_sep, format = "f", digits = 0, big.mark = ","),
    formatC(r$sd_sep, format = "f", digits = 0, big.mark = ","),
    formatC(r$mean_earns, format = "f", digits = 0, big.mark = ","),
    formatC(r$sd_earns, format = "f", digits = 0, big.mark = ",")
  ))
}

# EU trade exposure summary
eu_stats <- readRDS("../data/trade_exposure.rds")
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\multicolumn{9}{l}{\\textit{EU Trade Exposure (state-level):} Mean = %s, SD = %s, Median = %s} \\\\",
          fmt3(mean(eu_stats$eu_share, na.rm = TRUE)),
          fmt3(sd(eu_stats$eu_share, na.rm = TRUE)),
          fmt3(median(eu_stats$eu_share, na.rm = TRUE))),
  sprintf("\\multicolumn{9}{l}{\\textit{Panel:} %s counties, %d states, %d quarters, %s observations} \\\\",
          formatC(diag$n_counties, big.mark = ","),
          diag$n_states,
          diag$n_quarters,
          formatC(diag$n_obs, big.mark = ",", format = "d")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} QWI county-by-quarter data for NAICS 2-digit sectors, 2016Q1--2020Q1, excluding 2018Q2 (GDPR transition quarter). Employment, hires, and separations are quarterly counts. Earnings are average monthly earnings (\\$). EU trade exposure is the 2016 share of state merchandise exports destined for EU-28 partner countries (Census Foreign Trade Division). Panel restricted to counties with non-missing employment across all four industries and all quarters.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# ============================================================================
# TABLE 2: Main DDD Results
# ============================================================================

cat("Generating Table 2: Main DDD Results\n")

m1 <- models$m1; m2 <- models$m2; m3 <- models$m3; m4 <- models$m4; m5 <- models$m5

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Brussels Effect on US Labor Markets: Triple-Difference Estimates}",
  "\\label{tab:main_ddd}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & \\multicolumn{1}{c}{DD} & \\multicolumn{4}{c}{Triple-Difference} \\\\",
  "\\cmidrule(lr){2-2} \\cmidrule(lr){3-6}",
  " & log(Emp) & log(Emp) & log(Hires) & log(Sep) & log(Earn) \\\\",
  "\\midrule"
)

# Row: Info × Post (DD coefficient, column 1 only)
p1 <- pvalue(m1)["info_post"]
tab2_lines <- c(tab2_lines,
  sprintf("Info $\\times$ Post & %s%s & & & & \\\\",
          fmt(coef(m1)["info_post"]), stars(p1)),
  sprintf(" & (%s) & & & & \\\\",
          fmt(se(m1)["info_post"]))
)

# Row: Info × Post × EU Share (DDD coefficient, columns 2-5)
# In columns 2-5, the lower-order info × post is absorbed by FE
tab2_lines <- c(tab2_lines,
  sprintf("Info $\\times$ Post $\\times$ EU Share & & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(coef(m2)["info_post_eu"]), stars(pvalue(m2)["info_post_eu"]),
          fmt(coef(m3)["info_post_eu"]), stars(pvalue(m3)["info_post_eu"]),
          fmt(coef(m4)["info_post_eu"]), stars(pvalue(m4)["info_post_eu"]),
          fmt(coef(m5)["info_post_eu"]), stars(pvalue(m5)["info_post_eu"])),
  sprintf(" & & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(se(m2)["info_post_eu"]),
          fmt(se(m3)["info_post_eu"]),
          fmt(se(m4)["info_post_eu"]),
          fmt(se(m5)["info_post_eu"]))
)

tab2_lines <- c(tab2_lines,
  "\\midrule",
  "County FE & Yes & & & & \\\\",
  "Industry FE & Yes & & & & \\\\",
  "Year-Quarter FE & Yes & & & & \\\\",
  "County $\\times$ Year-Quarter FE & & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Year-Quarter FE & & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(nobs(m1), big.mark = ",", format = "d"),
          formatC(nobs(m2), big.mark = ",", format = "d"),
          formatC(nobs(m3), big.mark = ",", format = "d"),
          formatC(nobs(m4), big.mark = ",", format = "d"),
          formatC(nobs(m5), big.mark = ",", format = "d")),
  sprintf("R$^2$ (within) & %s & %s & %s & %s & %s \\\\",
          fmt3(r2(m1, "wr2")), fmt3(r2(m2, "wr2")),
          fmt3(r2(m3, "wr2")), fmt3(r2(m4, "wr2")),
          fmt3(r2(m5, "wr2"))),
  "Clusters (state) & 51 & 51 & 51 & 51 & 51 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Triple-difference estimates of GDPR enforcement (May 2018) on US labor market outcomes. Unit of observation is county $\\times$ quarter $\\times$ industry. Information (NAICS 51) is the treated industry; Finance (52), Professional Services (54), and Accommodation (72) are controls. EU Share is the 2016 state share of merchandise exports to EU-28. Column (1) shows the difference-in-differences without geographic variation. Standard errors clustered at the state level in parentheses. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main_ddd.tex")

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================

cat("Generating Table 3: Event Study\n")

es <- models$es_model
es_c <- coef(es)
es_s <- se(es)
es_p <- pvalue(es)

# Extract the relevant coefficients
es_names <- names(es_c)
es_df <- tibble(
  name = es_names,
  coef = es_c,
  se = es_s,
  pval = es_p
) %>%
  mutate(
    rel_qtr = as.integer(gsub(".*rel_qtr::(-?\\d+):.*", "\\1", name))
  ) %>%
  arrange(rel_qtr)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Quarter-by-Quarter Triple-Difference on Employment}",
  "\\label{tab:event_study}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter Relative to GDPR & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_df))) {
  r <- es_df[i, ]
  qtr_label <- if (r$rel_qtr < 0) {
    sprintf("$t%d$", r$rel_qtr)
  } else if (r$rel_qtr == 0) {
    "$t = 0$ (ref.)"
  } else {
    sprintf("$t+%d$", r$rel_qtr)
  }
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %s%s & (%s) \\\\",
    qtr_label, fmt(r$coef), stars(r$pval), fmt(r$se)
  ))
}

# Add reference period
tab3_lines <- c(tab3_lines,
  "\\midrule",
  "Reference period & \\multicolumn{2}{c}{2018Q1 ($t = 0$)} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nobs(es), big.mark = ",", format = "d")),
  "FE & \\multicolumn{2}{c}{County $\\times$ Qtr, Industry $\\times$ Qtr} \\\\",
  "Clustering & \\multicolumn{2}{c}{State (51)} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row shows the coefficient on Info $\\times$ EU\\_Share $\\times \\mathbf{1}[t = k]$, where $k$ is the relative quarter. Reference period is 2018Q1 (the last full quarter before GDPR enforcement in May 2018). Pre-period coefficients near zero support parallel trends. Standard errors clustered by state.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event_study.tex")

# ============================================================================
# TABLE 4: Robustness
# ============================================================================

cat("Generating Table 4: Robustness\n")

rob <- readRDS("../data/robustness_results.rds")
m_plac <- robustness$m_placebo
m_q2 <- robustness$m_with_q2
m_fin <- robustness$m_fin
m_pro <- robustness$m_pro

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccl}",
  "\\toprule",
  "Specification & $\\hat{\\beta}$ & SE & Notes \\\\",
  "\\midrule",
  sprintf("\\textit{A. Baseline} & %s%s & (%s) & Main DDD \\\\",
          fmt(diag$ddd_coef_emp), stars(pvalue(models$m2)["info_post_eu"]),
          fmt(diag$ddd_se_emp)),
  sprintf("\\textit{B. Pre-period placebo} & %s & (%s) & Fake treatment 2017Q2 \\\\",
          fmt(coef(m_plac)["placebo_ddd"]),
          fmt(se(m_plac)["placebo_ddd"])),
  sprintf("\\textit{C. Include 2018Q2} & %s%s & (%s) & Transition quarter included \\\\",
          fmt(coef(m_q2)["info_post_eu"]), stars(pvalue(m_q2)["info_post_eu"]),
          fmt(se(m_q2)["info_post_eu"])),
  sprintf("\\textit{D. Finance control only} & %s%s & (%s) & NAICS 51 vs 52 \\\\",
          fmt(coef(m_fin)["info_post_eu"]), stars(pvalue(m_fin)["info_post_eu"]),
          fmt(se(m_fin)["info_post_eu"])),
  sprintf("\\textit{E. Professional control only} & %s%s & (%s) & NAICS 51 vs 54 \\\\",
          fmt(coef(m_pro)["info_post_eu"]), stars(pvalue(m_pro)["info_post_eu"]),
          fmt(se(m_pro)["info_post_eu"])),
  sprintf("\\textit{F. LOO range} & [%s, %s] & & Drop one state at a time \\\\",
          fmt(min(robustness$loo_coefs)), fmt(max(robustness$loo_coefs)))
)

if (!is.null(robustness$boot_result)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\textit{G. Wild bootstrap} & %s & [%s, %s] & Webb weights, 999 reps \\\\",
            fmt(coef(models$m2)["info_post_eu"]),
            fmt(robustness$boot_result$conf_int[1]),
            fmt(robustness$boot_result$conf_int[2]))
  )
} else {
  tab4_lines <- c(tab4_lines,
    sprintf("\\textit{G. Wild bootstrap} & %s & --- & Bootstrap failed \\\\",
            fmt(coef(models$m2)["info_post_eu"]))
  )
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include county $\\times$ quarter and industry $\\times$ quarter fixed effects. The dependent variable is log employment. Standard errors clustered at the state level except Row G (wild cluster bootstrap, Webb weights, 999 replications). Row B uses a placebo treatment date of 2017Q2 with only pre-enforcement data. Row F reports the range of the DDD coefficient when each state is dropped in turn.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SD(Y) for each outcome in the pre-period
pre_panel <- panel %>% filter(yq < 2018.5)

sd_emp <- sd(pre_panel$log_emp, na.rm = TRUE)
sd_hira <- sd(pre_panel$log_hira, na.rm = TRUE)
sd_sep <- sd(pre_panel$log_sep, na.rm = TRUE)
sd_earn <- sd(pre_panel$log_earns, na.rm = TRUE)

# For continuous treatment: SDE = β × SD(X) / SD(Y)
sd_eu <- sd(readRDS("../data/trade_exposure.rds")$eu_share, na.rm = TRUE)

# Panel A: Pooled (main DDD estimates)
sde_emp <- diag$ddd_coef_emp * sd_eu / sd_emp
sde_hira <- diag$ddd_coef_hires * sd_eu / sd_hira
sde_sep <- diag$ddd_coef_sep * sd_eu / sd_sep
sde_earn <- diag$ddd_coef_earn * sd_eu / sd_earn

se_sde_emp <- diag$ddd_se_emp * sd_eu / sd_emp
se_sde_hira <- diag$ddd_se_hires * sd_eu / sd_hira
se_sde_sep <- diag$ddd_se_sep * sd_eu / sd_sep
se_sde_earn <- diag$ddd_se_earn * sd_eu / sd_earn

classify_sde <- function(x) {
  if (is.na(x)) return("---")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneity — High vs Low EU exposure states
panel_high <- panel %>% filter(eu_high == 1, yq < 2018.5)
panel_low <- panel %>% filter(eu_high == 0, yq < 2018.5)
sd_emp_high <- sd(panel_high$log_emp, na.rm = TRUE)
sd_emp_low <- sd(panel_low$log_emp, na.rm = TRUE)

# Run separate regressions for high/low EU exposure
m_high <- feols(log_emp ~ info_post | county_fips + naics2 + yearqtr,
                data = panel %>% filter(eu_high == 1), cluster = ~state_fips)
m_low <- feols(log_emp ~ info_post | county_fips + naics2 + yearqtr,
               data = panel %>% filter(eu_high == 0), cluster = ~state_fips)

sde_high <- coef(m_high)["info_post"] / sd_emp_high
sde_low <- coef(m_low)["info_post"] / sd_emp_low
se_sde_high <- se(m_high)["info_post"] / sd_emp_high
se_sde_low <- se(m_low)["info_post"] / sd_emp_low

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does EU GDPR enforcement reshape US labor markets by forcing American firms with EU exposure to hire compliance staff and restructure data operations? ",
  "\\textbf{Policy mechanism:} The EU General Data Protection Regulation, enforced May 2018, imposes strict data protection requirements on any firm processing EU residents' data, including US firms with EU customers, creating extraterritorial compliance demands that require new hires in data governance, privacy engineering, and legal counsel. ",
  "\\textbf{Outcome definition:} Quarterly Workforce Indicators (QWI) from the Longitudinal Employer-Household Dynamics program: log employment, log all hires, log separations, and log average monthly earnings at the county-quarter-industry level. ",
  "\\textbf{Treatment:} Continuous; state-level share of 2016 merchandise exports destined for EU-28 partner countries (Census Foreign Trade Division), interacted with Information sector (NAICS 51) and post-enforcement indicator. ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators, 2016Q1--2020Q1, county $\\times$ quarter $\\times$ NAICS 2-digit, ", formatC(diag$n_obs, big.mark = ",", format = "d"), " observations across ", diag$n_counties, " counties and ", diag$n_states, " states. ",
  "\\textbf{Method:} Triple-difference (county $\\times$ quarter $\\times$ industry) with county-by-quarter and industry-by-quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Balanced panel of counties with non-missing employment in all four industries (Information, Finance, Professional Services, Accommodation) across all quarters; excludes 2018Q2 as transition quarter. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-state standard deviation of EU export share and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Employment & %s & %s & %s & %s & %s & %s \\\\",
          fmt(diag$ddd_coef_emp), fmt(diag$ddd_se_emp), fmt3(sd_emp),
          fmt(sde_emp), fmt(se_sde_emp), classify_sde(sde_emp)),
  sprintf("Hires & %s & %s & %s & %s & %s & %s \\\\",
          fmt(diag$ddd_coef_hires), fmt(diag$ddd_se_hires), fmt3(sd_hira),
          fmt(sde_hira), fmt(se_sde_hira), classify_sde(sde_hira)),
  sprintf("Separations & %s & %s & %s & %s & %s & %s \\\\",
          fmt(diag$ddd_coef_sep), fmt(diag$ddd_se_sep), fmt3(sd_sep),
          fmt(sde_sep), fmt(se_sde_sep), classify_sde(sde_sep)),
  sprintf("Earnings & %s & %s & %s & %s & %s & %s \\\\",
          fmt(diag$ddd_coef_earn), fmt(diag$ddd_se_earn), fmt3(sd_earn),
          fmt(sde_earn), fmt(se_sde_earn), classify_sde(sde_earn)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample split by EU exposure)}} \\\\",
  sprintf("Employment (high EU) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(unname(coef(m_high)["info_post"])), fmt(unname(se(m_high)["info_post"])),
          fmt3(sd_emp_high), fmt(sde_high), fmt(se_sde_high), classify_sde(sde_high)),
  sprintf("Employment (low EU) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(unname(coef(m_low)["info_post"])), fmt(unname(se(m_low)["info_post"])),
          fmt3(sd_emp_low), fmt(sde_low), fmt(se_sde_low), classify_sde(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
