# =============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_0663
# =============================================================================

source("00_packages.R")

# Load data and models
panel <- readRDS("../data/panel_clean.rds")
full_stats <- readRDS("../data/full_stats.rds")
ddd_models <- readRDS("../data/ddd_models.rds")
ddd_edu <- readRDS("../data/ddd_edu_models.rds")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Summary stats by expansion status and ESI classification
make_sumstats <- function(data, label) {
  data %>%
    summarise(
      across(c(hire_rate, sep_rate, hira_rate, net_job_creation, Emp),
             list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))),
      N = n(),
      .groups = "drop"
    ) %>%
    mutate(group = label)
}

ss <- bind_rows(
  make_sumstats(panel, "Full Sample"),
  make_sumstats(panel %>% filter(expansion_state == 1, high_esi == 1), "Expansion, High-ESI"),
  make_sumstats(panel %>% filter(expansion_state == 1, high_esi == 0), "Expansion, Low-ESI"),
  make_sumstats(panel %>% filter(expansion_state == 0, high_esi == 1), "Non-Expansion, High-ESI"),
  make_sumstats(panel %>% filter(expansion_state == 0, high_esi == 0), "Non-Expansion, Low-ESI")
)

tab1_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Worker Mobility by Expansion Status and Industry Type}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{l*{4}{S[table-format=2.2]}c}
\\toprule
 & {Hire Rate} & {Sep. Rate} & {All Hires} & {Net Job} & \\\\
Group & {(New)} & {} & {Rate} & {Creation} & {N} \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: Full Sample}} \\\\
Mean & %.2f & %.2f & %.2f & %.2f & %s \\\\
SD   & (%.2f) & (%.2f) & (%.2f) & (%.2f) & \\\\[0.5em]
\\multicolumn{6}{l}{\\textit{Panel B: Expansion States, High-ESI Industries}} \\\\
Mean & %.2f & %.2f & %.2f & %.2f & %s \\\\
SD   & (%.2f) & (%.2f) & (%.2f) & (%.2f) & \\\\[0.5em]
\\multicolumn{6}{l}{\\textit{Panel C: Expansion States, Low-ESI Industries}} \\\\
Mean & %.2f & %.2f & %.2f & %.2f & %s \\\\
SD   & (%.2f) & (%.2f) & (%.2f) & (%.2f) & \\\\[0.5em]
\\multicolumn{6}{l}{\\textit{Panel D: Non-Expansion States, High-ESI Industries}} \\\\
Mean & %.2f & %.2f & %.2f & %.2f & %s \\\\
SD   & (%.2f) & (%.2f) & (%.2f) & (%.2f) & \\\\[0.5em]
\\multicolumn{6}{l}{\\textit{Panel E: Non-Expansion States, Low-ESI Industries}} \\\\
Mean & %.2f & %.2f & %.2f & %.2f & %s \\\\
SD   & (%.2f) & (%.2f) & (%.2f) & (%.2f) & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} QWI data, 2010Q1--2019Q4. Hire Rate (New) = new hires from other employers per 100 workers. Sep.\\ Rate = separations per 100 workers. All Hires Rate includes recalls. Net Job Creation = (firm job gains $-$ firm job losses) per 100 workers. High-ESI industries: Manufacturing, Information, Finance, Professional/Technical, Utilities, Management. Low-ESI industries: Accommodation/Food, Retail, Agriculture, Admin/Waste, Other Services, Arts/Entertainment. Standard deviations in parentheses.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  ss$hire_rate_mean[1], ss$sep_rate_mean[1], ss$hira_rate_mean[1], ss$net_job_creation_mean[1], format(ss$N[1], big.mark = ","),
  ss$hire_rate_sd[1], ss$sep_rate_sd[1], ss$hira_rate_sd[1], ss$net_job_creation_sd[1],
  ss$hire_rate_mean[2], ss$sep_rate_mean[2], ss$hira_rate_mean[2], ss$net_job_creation_mean[2], format(ss$N[2], big.mark = ","),
  ss$hire_rate_sd[2], ss$sep_rate_sd[2], ss$hira_rate_sd[2], ss$net_job_creation_sd[2],
  ss$hire_rate_mean[3], ss$sep_rate_mean[3], ss$hira_rate_mean[3], ss$net_job_creation_mean[3], format(ss$N[3], big.mark = ","),
  ss$hire_rate_sd[3], ss$sep_rate_sd[3], ss$hira_rate_sd[3], ss$net_job_creation_sd[3],
  ss$hire_rate_mean[4], ss$sep_rate_mean[4], ss$hira_rate_mean[4], ss$net_job_creation_mean[4], format(ss$N[4], big.mark = ","),
  ss$hire_rate_sd[4], ss$sep_rate_sd[4], ss$hira_rate_sd[4], ss$net_job_creation_sd[4],
  ss$hire_rate_mean[5], ss$sep_rate_mean[5], ss$hira_rate_mean[5], ss$net_job_creation_mean[5], format(ss$N[5], big.mark = ","),
  ss$hire_rate_sd[5], ss$sep_rate_sd[5], ss$hira_rate_sd[5], ss$net_job_creation_sd[5]
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main DDD Results
# =============================================================================

cat("Generating Table 2: Main DDD Results\n")

setFixest_dict(c(
  hire_rate = "New Hire Rate",
  sep_rate = "Separation Rate",
  hira_rate = "All Hires Rate",
  net_job_creation = "Net Job Creation",
  log_earnings = "Log Earnings"
))

etable(
  ddd_models$hire, ddd_models$sep, ddd_models$hira,
  ddd_models$netjob, ddd_models$earn,
  se.below = TRUE,
  fitstat = c("n", "r2"),
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  style.tex = style.tex("aer"),
  file = "../tables/tab2_ddd_main.tex",
  replace = TRUE,
  title = "Triple-Difference Estimates: Effect of Medicaid Expansion on Worker Mobility",
  label = "tab:ddd_main",
  notes = c(
    "Each column reports the triple-interaction coefficient (Expansion $\\times$ Post $\\times$ High-ESI).",
    "All specifications include state$\\times$industry, industry$\\times$time, and state$\\times$time fixed effects.",
    "Standard errors clustered at the state level in parentheses.",
    "Outcomes are per 100 workers (columns 1--4) or log dollars (column 5).",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)

# =============================================================================
# TABLE 3: Education Heterogeneity (Quadruple-Difference)
# =============================================================================

cat("Generating Table 3: Education Heterogeneity\n")

etable(
  ddd_edu$hire_low, ddd_edu$hire_high,
  ddd_edu$sep_low, ddd_edu$sep_high,
  se.below = TRUE,
  fitstat = c("n", "r2"),
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  style.tex = style.tex("aer"),
  file = "../tables/tab3_education.tex",
  replace = TRUE,
  title = "Education Heterogeneity: DDD Estimates by Education Level",
  label = "tab:education",
  notes = c(
    "Columns (1)--(2) report DDD estimates for new hire rate; columns (3)--(4) for separation rate.",
    "Low education: less than bachelor's degree. High education: bachelor's or above.",
    "Medicaid expansion primarily affected low-education workers; high-education serves as within-industry placebo.",
    "All specifications include state$\\times$industry, industry$\\times$time, and state$\\times$time FE.",
    "Standard errors clustered at state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)

# =============================================================================
# TABLE 4: Robustness
# =============================================================================

cat("Generating Table 4: Robustness\n")

ddd_twoway <- readRDS("../data/ddd_hire_twoway.rds")
ddd_noearlyexp <- readRDS("../data/ddd_hire_noearlyexp.rds")
ddd_dose <- readRDS("../data/ddd_dose_models.rds")

etable(
  ddd_edu$hire_low,        # Baseline (low-edu)
  ddd_twoway,              # Two-way clustering
  ddd_noearlyexp,          # Excluding early expanders
  ddd_dose$high,           # High pre-ACA uninsured
  ddd_dose$low,            # Low pre-ACA uninsured
  se.below = TRUE,
  fitstat = c("n", "r2"),
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  style.tex = style.tex("aer"),
  file = "../tables/tab4_robustness.tex",
  replace = TRUE,
  title = "Robustness: DDD Estimates for New Hire Rate Under Alternative Specifications",
  label = "tab:robustness",
  notes = c(
    "Dependent variable: new hire rate (per 100 workers). Low-education workers only (columns 1--5).",
    "Column 1: baseline DDD. Column 2: two-way clustering (state + time).",
    "Column 3: excludes MA, VT, NY (pre-ACA Medicaid expansions).",
    "Columns 4--5: split by state pre-ACA uninsured rate (above/below median).",
    "All specifications include state$\\times$industry, industry$\\times$time, state$\\times$time FE.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  )
)

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =============================================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Extract coefficients from main DDD models
extract_sde <- function(model, outcome_name, sd_y, treatment_type = "binary") {
  coef_name <- names(coef(model))[1]
  beta <- coef(model)[coef_name]
  se_beta <- sqrt(diag(vcov(model)))[coef_name]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

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

  tibble(
    outcome = outcome_name,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_table <- bind_rows(
  extract_sde(ddd_models$hire, "New Hire Rate", full_stats$hire_rate_sd),
  extract_sde(ddd_models$sep, "Separation Rate", full_stats$sep_rate_sd),
  extract_sde(ddd_models$hira, "All Hires Rate", full_stats$hira_rate_sd),
  extract_sde(ddd_models$netjob, "Net Job Creation", full_stats$net_job_creation_sd),
  extract_sde(ddd_models$earn, "Log Earnings", full_stats$log_earnings_sd)
)

# Generate LaTeX
sde_rows <- sde_table %>%
  mutate(row = sprintf("%s & %.3f & %.3f & --- & %.3f & %.3f & %.3f & %s \\\\",
                       outcome, beta, se, sd_y, sde, se_sde, classification)) %>%
  pull(row)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lccccccl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(sde_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "SD($Y$) is the unconditional standard deviation from the full sample.\n\n",
  "\\textbf{Research question:} Does ACA Medicaid expansion increase worker mobility in high-ESI industries?\n\n",
  "\\textbf{Treatment:} Binary (DDD interaction: Expansion $\\times$ Post $\\times$ High-ESI).\n\n",
  "\\textbf{Data:} Census QWI, 2010Q1--2019Q4, state $\\times$ quarter $\\times$ industry type $\\times$ education level.\n\n",
  "\\textbf{Method:} Triple-difference with state$\\times$industry, industry$\\times$time, state$\\times$time FE; state-clustered SEs.\n\n",
  "\\textbf{Sample:} 51 states (35 expansion, 16 never-treated within window), 12 industries classified as high or low ESI.\n\n",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
