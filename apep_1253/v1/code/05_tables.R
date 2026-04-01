# ==============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_1253
# ==============================================================================

source("00_packages.R")

panel       <- fread("../data/analysis_panel.csv",
                     colClasses = list(character = c("fips", "industry", "state_fips")))
ind_results <- readRDS("../data/industry_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
summ_pre    <- readRDS("../data/summary_stats.rds")

cat("=== Generating LaTeX tables ===\n\n")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("--- Table 1: Summary Statistics ---\n")

# Compute by poverty tercile
panel[, poverty_tercile := cut(poverty_rate,
                                breaks = quantile(poverty_rate, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                                labels = c("Low", "Medium", "High"),
                                include.lowest = TRUE)]

summ_vars <- panel[post == 0, .(
  `Employment`              = mean(emp, na.rm = TRUE),
  `Log employment`          = mean(log(emp), na.rm = TRUE),
  `Average earnings (\\$)`  = mean(avg_earnings, na.rm = TRUE),
  `Hires (quarterly)`       = mean(hires_all, na.rm = TRUE),
  `Separations (quarterly)` = mean(separations, na.rm = TRUE),
  `Poverty rate (\\%)`      = mean(poverty_rate, na.rm = TRUE),
  `Population`              = mean(population, na.rm = TRUE)
)]

summ_sd <- panel[post == 0, .(
  `Employment`              = sd(emp, na.rm = TRUE),
  `Log employment`          = sd(log(emp), na.rm = TRUE),
  `Average earnings (\\$)`  = sd(avg_earnings, na.rm = TRUE),
  `Hires (quarterly)`       = sd(hires_all, na.rm = TRUE),
  `Separations (quarterly)` = sd(separations, na.rm = TRUE),
  `Poverty rate (\\%)`      = sd(poverty_rate, na.rm = TRUE),
  `Population`              = sd(population, na.rm = TRUE)
)]

# Build table
var_names <- names(summ_vars)
n_pre_obs <- nrow(panel[post == 0])
n_counties <- uniqueN(panel$fips)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics (Pre-Treatment Period, 2018Q1--2021Q3)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Variable & Mean & Std. Dev. \\\\",
  "\\midrule"
)

for (v in var_names) {
  m <- as.numeric(summ_vars[[v]])
  s <- as.numeric(summ_sd[[v]])
  if (grepl("earnings|Population", v)) {
    tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s \\\\",
                                         v, format(round(m), big.mark = ","),
                                         format(round(s), big.mark = ",")))
  } else {
    tab1_lines <- c(tab1_lines, sprintf("%s & %.2f & %.2f \\\\", v, m, s))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s county-industry-quarter observations across %s counties, 7 NAICS sectors, and 15 pre-treatment quarters (2018Q1--2021Q3). Employment is the average beginning-of-quarter count per county-industry-quarter cell. Earnings are average monthly earnings. Poverty rate is the 2019 SAIPE all-ages poverty rate used as treatment intensity. Source: Census QWI (LEHD) and Census SAIPE.",
          format(n_pre_obs, big.mark = ","), format(n_counties, big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Written tables/tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main Results — Industry-Specific DiD
# ==============================================================================

cat("--- Table 2: Industry-Specific DiD ---\n")

# Re-run pooled for the table
fit_pooled <- feols(
  log(emp) ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
  data = panel,
  cluster = ~state_fips
)

pooled_beta <- coef(fit_pooled)[[1]]
pooled_se <- sqrt(diag(vcov(fit_pooled)))[[1]]
pooled_pval <- pvalue(fit_pooled)[[1]]
pooled_n <- nobs(fit_pooled)
pooled_stars <- ifelse(pooled_pval < 0.01, "***",
                ifelse(pooled_pval < 0.05, "**",
                ifelse(pooled_pval < 0.10, "*", "")))

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of SNAP Benefit Increase on Log Employment by Industry}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{1}{c}{$\\hat{\\beta}$} & \\multicolumn{1}{c}{SE} & \\multicolumn{1}{c}{$N$} & \\multicolumn{1}{c}{Counties} \\\\",
  "\\midrule",
  sprintf("\\textit{All industries (pooled)} & %.4f%s & (%.4f) & %s & %s \\\\",
          pooled_beta, pooled_stars, pooled_se,
          format(pooled_n, big.mark = ","),
          format(uniqueN(panel$fips), big.mark = ",")),
  "\\midrule"
)

# Industry rows sorted by expected effect
ind_order <- c("72", "44-45", "56", "62", "54", "52", "31-33")
for (ind in ind_order) {
  row <- ind_results[industry == ind]
  tab2_lines <- c(tab2_lines, sprintf("%s (NAICS %s) & %.4f%s & (%.4f) & %s & %s \\\\",
                                       row$ind_label, row$industry,
                                       row$beta, row$stars, row$se,
                                       format(row$n_obs, big.mark = ","),
                                       format(row$n_counties, big.mark = ",")))
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  "County $\\times$ industry FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Industry $\\times$ quarter FE & \\multicolumn{4}{c}{Yes} \\\\",
  sprintf("Clusters (states) & \\multicolumn{4}{c}{%d} \\\\", ind_results$n_clusters[1]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports $\\hat{\\beta}$ from a separate regression of log quarterly employment on the interaction of the county's 2019 poverty rate (continuous, in percentage points) with a post-October 2021 indicator. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The coefficient represents the additional log-point change in employment per percentage point of county poverty rate after the TFP revision. Source: Census QWI (LEHD) 2018Q1--2023Q4 merged with 2019 SAIPE poverty rates.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Written tables/tab2_main.tex\n")

# ==============================================================================
# Table 3: Robustness
# ==============================================================================

cat("--- Table 3: Robustness ---\n")

# Add main estimate row
main_row <- data.table(
  test = "Baseline (pooled)",
  beta = pooled_beta,
  se = pooled_se,
  pval = pooled_pval,
  n_obs = pooled_n
)

rob_full <- rbind(main_row, rob_results[test != "Manufacturing placebo" &
                                          test != "Hires outcome" &
                                          test != "Separations outcome"])

rob_full[, stars := ifelse(pval < 0.01, "***",
                    ifelse(pval < 0.05, "**",
                    ifelse(pval < 0.10, "*", "")))]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & $\\hat{\\beta}$ & SE & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(rob_full))) {
  row <- rob_full[i]
  tab3_lines <- c(tab3_lines, sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
                                       row$test, row$beta, row$stars, row$se,
                                       format(row$n_obs, big.mark = ",")))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include county $\\times$ industry and industry $\\times$ quarter fixed effects with state-clustered standard errors unless noted otherwise. The placebo test uses 2019Q4 as a false treatment date on the pre-period sample only. The state $\\times$ quarter FE specification adds state-level time trends to absorb state-specific shocks (e.g., enhanced UI expiration timing). The balanced panel restricts to counties observed in all 24 quarters. Child poverty uses the 2019 child (0--17) poverty rate as the treatment intensity variable. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Written tables/tab3_robustness.tex\n")

# ==============================================================================
# Table 4: Mechanism — Hires vs. Separations by Industry
# ==============================================================================

cat("--- Table 4: Mechanism (Hires and Separations) ---\n")

panel[, log_hires := log(pmax(hires_all, 1))]
panel[, log_seps := log(pmax(separations, 1))]

mech_results <- list()
for (ind in c("72", "44-45", "62", "31-33")) {
  fit_h <- feols(
    log_hires ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
    data = panel[industry == ind],
    cluster = ~state_fips
  )
  fit_s <- feols(
    log_seps ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
    data = panel[industry == ind],
    cluster = ~state_fips
  )
  fit_e <- feols(
    avg_earnings ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
    data = panel[industry == ind],
    cluster = ~state_fips
  )

  lab <- panel[industry == ind, ind_label[1]]
  mech_results[[ind]] <- data.table(
    industry = ind,
    ind_label = lab,
    hires_beta = coef(fit_h)[[1]], hires_se = sqrt(diag(vcov(fit_h)))[[1]],
    hires_pval = pvalue(fit_h)[[1]],
    seps_beta = coef(fit_s)[[1]], seps_se = sqrt(diag(vcov(fit_s)))[[1]],
    seps_pval = pvalue(fit_s)[[1]],
    earn_beta = coef(fit_e)[[1]], earn_se = sqrt(diag(vcov(fit_e)))[[1]],
    earn_pval = pvalue(fit_e)[[1]],
    n_obs = nobs(fit_h)
  )
}

mech_dt <- rbindlist(mech_results)

stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanism: Hires, Separations, and Earnings by Industry}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Log hires & Log separations & Avg. earnings (\\$) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(mech_dt))) {
  row <- mech_dt[i]
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.4f%s & %.4f%s & %.1f%s \\\\",
            row$ind_label,
            row$hires_beta, stars_fn(row$hires_pval),
            row$seps_beta, stars_fn(row$seps_pval),
            row$earn_beta, stars_fn(row$earn_pval)),
    sprintf(" & (%.4f) & (%.4f) & (%.1f) \\\\",
            row$hires_se, row$seps_se, row$earn_se)
  )
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("$N$ & \\multicolumn{3}{c}{%s per industry} \\\\",
          format(mech_dt$n_obs[1], big.mark = ",")),
  "County $\\times$ industry FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Industry $\\times$ quarter FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the coefficient on the interaction of county poverty rate with the post-October 2021 indicator. Log hires and log separations use log(max(1, count)) to handle zeros. Average earnings are monthly. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Declining hires combined with stable or rising separations in food services would indicate labor supply withdrawal; rising hires in healthcare would indicate sectoral reallocation.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_mechanism.tex")
cat("Written tables/tab4_mechanism.tex\n")

saveRDS(mech_dt, "../data/mechanism_results.rds")

# ==============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ==============================================================================

cat("--- Table F1: Standardized Effect Sizes ---\n")

# Compute SDE for main outcomes
sd_log_emp <- sd(panel[post == 0, log(emp)], na.rm = TRUE)
sd_log_hires <- sd(panel[post == 0, log(pmax(hires_all, 1))], na.rm = TRUE)
sd_log_seps <- sd(panel[post == 0, log(pmax(separations, 1))], na.rm = TRUE)
sd_poverty <- sd(panel$poverty_rate, na.rm = TRUE)

# Main pooled result (continuous treatment → SDE = β × SD(X) / SD(Y))
sde_emp <- pooled_beta * sd_poverty / sd_log_emp
se_sde_emp <- pooled_se * sd_poverty / sd_log_emp

# Food services
fs_row <- ind_results[industry == "72"]
sde_fs <- fs_row$beta * sd_poverty / sd(panel[industry == "72" & post == 0, log(emp)], na.rm = TRUE)
se_sde_fs <- fs_row$se * sd_poverty / sd(panel[industry == "72" & post == 0, log(emp)], na.rm = TRUE)

# Retail
rt_row <- ind_results[industry == "44-45"]
sde_rt <- rt_row$beta * sd_poverty / sd(panel[industry == "44-45" & post == 0, log(emp)], na.rm = TRUE)
se_sde_rt <- rt_row$se * sd_poverty / sd(panel[industry == "44-45" & post == 0, log(emp)], na.rm = TRUE)

# Healthcare
hc_row <- ind_results[industry == "62"]
sde_hc <- hc_row$beta * sd_poverty / sd(panel[industry == "62" & post == 0, log(emp)], na.rm = TRUE)
se_sde_hc <- hc_row$se * sd_poverty / sd(panel[industry == "62" & post == 0, log(emp)], na.rm = TRUE)

# Heterogeneity: high vs low poverty counties
med_pov <- median(panel$poverty_rate, na.rm = TRUE)

fit_high <- feols(
  log(emp) ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
  data = panel[poverty_rate >= med_pov],
  cluster = ~state_fips
)
fit_low <- feols(
  log(emp) ~ I(poverty_rate * post) | paste0(fips, "_", industry) + paste0(industry, "_", time_id),
  data = panel[poverty_rate < med_pov],
  cluster = ~state_fips
)

sd_high <- sd(panel[poverty_rate >= med_pov & post == 0, log(emp)], na.rm = TRUE)
sd_low <- sd(panel[poverty_rate < med_pov & post == 0, log(emp)], na.rm = TRUE)
sd_pov_high <- sd(panel[poverty_rate >= med_pov, poverty_rate], na.rm = TRUE)
sd_pov_low <- sd(panel[poverty_rate < med_pov, poverty_rate], na.rm = TRUE)

sde_high <- coef(fit_high)[[1]] * sd_pov_high / sd_high
se_sde_high <- sqrt(diag(vcov(fit_high)))[[1]] * sd_pov_high / sd_high
sde_low <- coef(fit_low)[[1]] * sd_pov_low / sd_low
se_sde_low <- sqrt(diag(vcov(fit_low)))[[1]] * sd_pov_low / sd_low

# Classification function
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

# Build SDE table
sde_rows <- data.table(
  panel_label = c(rep("Panel A: Pooled", 4), rep("Panel B: Heterogeneous", 2)),
  outcome = c("Employment (all industries)", "Employment (food services)",
              "Employment (retail trade)", "Employment (healthcare)",
              "Employment (high-poverty counties)", "Employment (low-poverty counties)"),
  beta = c(pooled_beta, fs_row$beta, rt_row$beta, hc_row$beta,
           coef(fit_high)[[1]], coef(fit_low)[[1]]),
  se = c(pooled_se, fs_row$se, rt_row$se, hc_row$se,
         sqrt(diag(vcov(fit_high)))[[1]], sqrt(diag(vcov(fit_low)))[[1]]),
  sd_y = c(sd_log_emp,
           sd(panel[industry == "72" & post == 0, log(emp)], na.rm = TRUE),
           sd(panel[industry == "44-45" & post == 0, log(emp)], na.rm = TRUE),
           sd(panel[industry == "62" & post == 0, log(emp)], na.rm = TRUE),
           sd_high, sd_low),
  sde = c(sde_emp, sde_fs, sde_rt, sde_hc, sde_high, sde_low),
  se_sde = c(se_sde_emp, se_sde_fs, se_sde_rt, se_sde_hc, se_sde_high, se_sde_low)
)
sde_rows[, classification := classify(sde)]

# Write LaTeX
sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:4) {
  row <- sde_rows[i]
  sde_lines <- c(sde_lines, sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
                                     row$outcome, row$beta, row$se, row$sd_y,
                                     row$sde, row$se_sde, row$classification))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\"
)

for (i in 5:6) {
  row <- sde_rows[i]
  sde_lines <- c(sde_lines, sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
                                     row$outcome, row$beta, row$se, row$sd_y,
                                     row$sde, row$se_sde, row$classification))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does a permanent increase in SNAP benefits reduce employment in low-wage industries and reallocate workers toward higher-paying sectors in high-poverty counties? ",
  "\\textbf{Policy mechanism:} The October 2021 Thrifty Food Plan revision permanently raised the maximum SNAP benefit by 21\\% (\\$36 per person per month), increasing non-labor income for SNAP-eligible households and potentially reducing the opportunity cost of not working in low-wage jobs while enabling job search in better-paying sectors. ",
  "\\textbf{Outcome definition:} Log quarterly beginning-of-quarter employment from the Quarterly Workforce Indicators (QWI/LEHD), measured at the county-industry-quarter level. ",
  "\\textbf{Treatment:} Continuous --- county-level 2019 poverty rate (in percentage points) interacted with a post-October 2021 indicator; higher poverty rates proxy for greater SNAP exposure to the benefit increase. ",
  "\\textbf{Data:} Census QWI (LEHD) county $\\times$ NAICS sector $\\times$ quarter panel, 2018Q1--2023Q4, merged with 2019 SAIPE county poverty rates. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with county $\\times$ industry and industry $\\times$ quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} US counties with non-suppressed QWI employment in 7 NAICS sectors (food services, retail, healthcare, admin/waste, manufacturing, professional services, finance); ages 25--54; balanced panel subset used for robustness. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of county poverty rate and SD($Y$) is the pre-treatment ",
  "standard deviation of log employment. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
