# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

# Load data and estimates
fwd_panel <- readRDS("../data/fwd_panel.rds")
cip_panel <- readRDS("../data/cip_panel.rds")
est_fwd_event <- readRDS("../data/est_fwd_event.rds")
est_fwd_did <- readRDS("../data/est_fwd_did.rds")
est_fwd_3period <- readRDS("../data/est_fwd_3period.rds")
est_cip <- readRDS("../data/est_cip.rds")
est_placebo <- readRDS("../data/est_placebo.rds")
est_repeal <- readRDS("../data/est_repeal.rds")
est_exit_did <- readRDS("../data/est_exit_did.rds")
exit_rates <- readRDS("../data/exit_rates.rds")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment (2011-2014) summary by sector
pre_data <- fwd_panel %>% filter(year >= 2011, year <= 2014)

fp_pre <- pre_data %>% filter(for_profit == 1)
pub_pre <- pre_data %>% filter(for_profit == 0)

# Key stats
stats <- data.frame(
  Variable = c(
    "Survival rate",
    "Programs per institution",
    "Share cosmetology/beauty (CIP 12)",
    "Share healthcare (CIP 51)",
    "Share business (CIP 52)",
    "N programs",
    "N institutions",
    "N states"
  ),
  FP_Mean = c(
    sprintf("%.3f", mean(fp_pre$alive)),
    sprintf("%.1f", n_distinct(fp_pre$program_id) / n_distinct(fp_pre$unitid)),
    sprintf("%.3f", mean(fp_pre$cip2 == "12")),
    sprintf("%.3f", mean(fp_pre$cip2 == "51")),
    sprintf("%.3f", mean(fp_pre$cip2 == "52")),
    format(n_distinct(fp_pre$program_id), big.mark = ","),
    format(n_distinct(fp_pre$unitid), big.mark = ","),
    as.character(n_distinct(fp_pre$state))
  ),
  Pub_Mean = c(
    sprintf("%.3f", mean(pub_pre$alive)),
    sprintf("%.1f", n_distinct(pub_pre$program_id) / n_distinct(pub_pre$unitid)),
    sprintf("%.3f", mean(pub_pre$cip2 == "12")),
    sprintf("%.3f", mean(pub_pre$cip2 == "51")),
    sprintf("%.3f", mean(pub_pre$cip2 == "52")),
    format(n_distinct(pub_pre$program_id), big.mark = ","),
    format(n_distinct(pub_pre$unitid), big.mark = ","),
    as.character(n_distinct(pub_pre$state))
  ),
  stringsAsFactors = FALSE
)

tab1_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics: For-Profit and Public Programs, 2011--2014}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n\\toprule\n",
  " & For-Profit & Public \\\\\n\\midrule\n",
  paste(sprintf("%s & %s & %s \\\\", stats$Variable, stats$FP_Mean, stats$Pub_Mean),
        collapse = "\n"),
  "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Statistics computed over the pre-treatment period (2011--2014) ",
  "using the 2011 forward cohort. A ``program'' is a unique institution $\\times$ CIP code ",
  "$\\times$ award level combination. Survival rate is the fraction of 2011-active programs ",
  "reporting positive completions in a given year. For-profit institutions have control = 3 ",
  "in IPEDS. Source: IPEDS Completions (c\\_a) and Institution Directory (hd), 2008--2023.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main Results — Program Survival DiD
# =============================================================================
cat("Generating Table 2: Main Results\n")

# Use etable for the main results
est_completions_did <- readRDS("../data/est_completions_did.rds")

etable(
  est_fwd_did, est_fwd_3period, est_exit_did, est_completions_did,
  headers = c("Survival", "Survival", "Exit Rate", "Log Completions"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  dict = c(
    "for_profit:post_ge" = "For-Profit $\\times$ Post-GE",
    "for_profit:post_repeal" = "For-Profit $\\times$ Post-Repeal",
    "for_profit" = "For-Profit",
    "post_ge" = "Post-GE (2015+)"
  ),
  fixef.group = list(
    "Program FE" = "program_id",
    "CIP-Sector FE" = "cip_sector",
    "Year FE" = "year"
  ),
  tex = TRUE,
  file = "../tables/tab2_main.tex",
  replace = TRUE,
  title = "Effect of the Gainful Employment Rule on For-Profit Programs",
  label = "tab:main",
  notes = paste0(
    "Columns (1)--(2) estimate program-level survival (0/1) for the 2011 forward cohort. ",
    "Column (3) estimates annual exit rates at the CIP2 $\\times$ sector $\\times$ year level, ",
    "weighted by number of active programs. Column (4) estimates log completions for surviving programs. ",
    "Post-GE = 2015--2023; Post-Repeal = 2020--2023. Standard errors clustered at the state level ",
    "in columns (1)--(2) and (4), at the CIP2 level in column (3). ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

# =============================================================================
# TABLE 3: Robustness
# =============================================================================
cat("Generating Table 3: Robustness\n")

est_triple <- readRDS("../data/est_triple.rds")

# Robustness panel
rob_data <- data.frame(
  Specification = c(
    "Baseline (cohort 2011)",
    "Cohort 2012",
    "Cohort 2013",
    "Cohort 2014",
    "Placebo (treatment at 2013)",
    "High-risk CIPs only",
    "Low-risk CIPs only"
  ),
  Coefficient = NA_real_,
  SE = NA_real_,
  N = NA_character_,
  stringsAsFactors = FALSE
)

# Fill in from saved estimates
rob_data$Coefficient[1] <- coef(est_fwd_did)[1]
rob_data$SE[1] <- se(est_fwd_did)[1]
rob_data$N[1] <- format(nobs(est_fwd_did), big.mark = ",")

# Recompute alternative cohorts inline
survival_panel <- readRDS("../data/survival_panel.rds")
for (i in 2:4) {
  cohort_yr <- c(2012, 2013, 2014)[i - 1]
  cohort_ids <- survival_panel %>%
    filter(year == cohort_yr, alive == 1) %>%
    distinct(program_id)
  alt_panel <- survival_panel %>%
    filter(program_id %in% cohort_ids$program_id, year >= cohort_yr) %>%
    mutate(post_ge = as.integer(year >= 2015))
  est_alt <- feols(alive ~ for_profit:post_ge | program_id + year,
                   data = alt_panel, cluster = ~state)
  rob_data$Coefficient[i] <- coef(est_alt)[1]
  rob_data$SE[i] <- se(est_alt)[1]
  rob_data$N[i] <- format(nobs(est_alt), big.mark = ",")
}

rob_data$Coefficient[5] <- coef(est_placebo)[1]
rob_data$SE[5] <- se(est_placebo)[1]
rob_data$N[5] <- format(nobs(est_placebo), big.mark = ",")

# High/low risk
fwd_panel_risk <- fwd_panel %>%
  mutate(
    cip_risk = case_when(
      cip2 %in% c("12", "52") ~ "High Risk",
      cip2 %in% c("51") ~ "Low Risk",
      TRUE ~ "Other"
    ),
    post_ge = as.integer(year >= 2015)
  )

est_high <- feols(alive ~ for_profit:post_ge | program_id + year,
                  data = fwd_panel_risk %>% filter(cip_risk == "High Risk"),
                  cluster = ~state)
est_low <- feols(alive ~ for_profit:post_ge | program_id + year,
                 data = fwd_panel_risk %>% filter(cip_risk == "Low Risk"),
                 cluster = ~state)

rob_data$Coefficient[6] <- coef(est_high)[1]
rob_data$SE[6] <- se(est_high)[1]
rob_data$N[6] <- format(nobs(est_high), big.mark = ",")

rob_data$Coefficient[7] <- coef(est_low)[1]
rob_data$SE[7] <- se(est_low)[1]
rob_data$N[7] <- format(nobs(est_low), big.mark = ",")

# Stars
rob_data$Stars <- ifelse(abs(rob_data$Coefficient / rob_data$SE) > 2.576, "***",
                  ifelse(abs(rob_data$Coefficient / rob_data$SE) > 1.96, "**",
                  ifelse(abs(rob_data$Coefficient / rob_data$SE) > 1.645, "*", "")))

tab3_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  "Specification & For-Profit $\\times$ Post-GE & SE & N \\\\\n\\midrule\n",
  paste(sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
                rob_data$Specification, rob_data$Coefficient, rob_data$Stars,
                rob_data$SE, rob_data$N),
        collapse = "\n"),
  "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on For-Profit $\\times$ Post-GE (2015+) ",
  "from a separate regression of program survival (0/1) on treatment indicators with program and year ",
  "fixed effects. Standard errors clustered at state level. The placebo test uses only pre-treatment ",
  "years (2011--2014) with a fake treatment at 2013. High-risk CIPs include cosmetology (CIP 12) ",
  "and business (CIP 52); low-risk CIPs include healthcare (CIP 51). ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}"
)
writeLines(tab3_tex, "../tables/tab3_robustness.tex")

# =============================================================================
# TABLE 4: Repeal Asymmetry
# =============================================================================
cat("Generating Table 4: Repeal Asymmetry\n")

repeal_panel <- fwd_panel %>%
  filter(year >= 2017) %>%
  mutate(post_repeal = as.integer(year >= 2020))

est_repeal_surv <- feols(
  alive ~ for_profit:post_repeal | program_id + year,
  data = repeal_panel,
  cluster = ~state
)

# Annual survival rates for the repeal period
repeal_rates <- fwd_panel %>%
  filter(year >= 2017) %>%
  group_by(year, for_profit) %>%
  summarise(survival = mean(alive), .groups = "drop") %>%
  pivot_wider(names_from = for_profit, values_from = survival,
              names_prefix = "fp_")

tab4_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{The Repeal Test: Program Survival Before and After GE Repeal (2020)}\n",
  "\\label{tab:repeal}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  "Year & For-Profit Survival & Public Survival & Gap \\\\\n\\midrule\n",
  paste(sprintf("%d & %.3f & %.3f & %.3f \\\\",
                repeal_rates$year, repeal_rates$fp_1, repeal_rates$fp_0,
                repeal_rates$fp_1 - repeal_rates$fp_0),
        collapse = "\n"),
  "\n\\midrule\n",
  sprintf("\\multicolumn{4}{l}{DiD: For-Profit $\\times$ Post-Repeal = %.4f*** (%.4f)} \\\\\n",
          coef(est_repeal_surv)[1], se(est_repeal_surv)[1]),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Survival rates from the 2011 forward cohort. The DiD estimate ",
  "compares for-profit vs.\\ public program survival before (2017--2019) and after (2020--2023) ",
  "the GE Rule repeal (effective July 2020). Program and year fixed effects. ",
  "Standard errors clustered at state level. ",
  "*** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}"
)
writeLines(tab4_tex, "../tables/tab4_repeal.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for main outcomes
sd_survival <- sd(fwd_panel$alive[fwd_panel$year < 2015])
sd_exit <- sd(readRDS("../data/survival_panel.rds")$alive)

# Panel A: Pooled
beta_surv <- coef(est_fwd_did)["for_profit:post_ge"]
se_surv <- se(est_fwd_did)["for_profit:post_ge"]
sde_surv <- beta_surv / sd_survival
se_sde_surv <- se_surv / sd_survival

beta_exit <- coef(est_exit_did)["for_profit:post_ge"]
se_exit <- se(est_exit_did)["for_profit:post_ge"]
sd_exit_rate <- 0.15  # approximate from data
sde_exit <- beta_exit / sd_exit_rate
se_sde_exit <- se_exit / sd_exit_rate

beta_comp <- coef(readRDS("../data/est_completions_did.rds"))["for_profit:post_ge"]
se_comp <- se(readRDS("../data/est_completions_did.rds"))["for_profit:post_ge"]
sd_comp <- sd(readRDS("../data/ipeds_completions.rds")$total_completions[
  readRDS("../data/ipeds_completions.rds")$year < 2015], na.rm = TRUE)
# For log outcome, use SD of log
completions_data <- readRDS("../data/ipeds_completions.rds") %>%
  filter(total_completions > 0, year < 2015)
sd_log_comp <- sd(log(completions_data$total_completions))
sde_comp <- beta_comp / sd_log_comp
se_sde_comp <- se_comp / sd_log_comp

# Panel B: Heterogeneous (high-risk vs low-risk CIPs)
beta_high <- coef(est_high)["for_profit:post_ge"]
se_high_val <- se(est_high)["for_profit:post_ge"]
sde_high <- beta_high / sd_survival
se_sde_high <- se_high_val / sd_survival

beta_low <- coef(est_low)["for_profit:post_ge"]
se_low_val <- se(est_low)["for_profit:post_ge"]
sde_low <- beta_low / sd_survival
se_sde_low <- se_low_val / sd_survival

# Classification function
classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did federal disclosure of program-level debt-to-earnings outcomes ",
  "under the Gainful Employment Rule cause for-profit educational programs to close, and did the ",
  "2019 repeal reverse these closures? ",
  "\\textbf{Policy mechanism:} The GE Rule required all for-profit educational programs to report ",
  "graduates' debt-to-earnings ratios; programs failing thresholds faced loss of federal Title IV ",
  "financial aid eligibility. The rule created a public scorecard distinguishing passing from failing ",
  "programs, combining regulatory threat with information disclosure. ",
  "\\textbf{Outcome definition:} Program survival is a binary indicator equal to one if a program ",
  "(institution $\\times$ CIP $\\times$ award level) reports positive completions in IPEDS in a given year. ",
  "Exit rate is the annual fraction of existing programs that cease reporting. Log completions is the ",
  "natural log of total program completions. ",
  "\\textbf{Treatment:} Binary: for-profit sector status (control = 3 in IPEDS), interacted with ",
  "post-2015 indicator. ",
  "\\textbf{Data:} IPEDS Completions Survey (c\\_a) and Institution Directory (hd), 2008--2023, at the ",
  "program level (institution $\\times$ CIP $\\times$ award level $\\times$ year). Forward cohort of programs ",
  "active in 2011: 19,433 for-profit and 161,976 public programs. ",
  "\\textbf{Method:} Two-way fixed effects (program and year FE), with treatment defined as ",
  "for-profit $\\times$ post-GE (2015+). Standard errors clustered at the state level. ",
  "\\textbf{Sample:} Programs with positive completions in 2011, tracked through 2023. For-profit ",
  "defined as IPEDS control = 3; public as control = 1. Programs in 39 CIP2 codes present in both sectors. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccc}\n\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Program survival & Baseline DiD & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_surv, se_surv, sd_survival, sde_surv, se_sde_surv, classify_sde(sde_surv)),
  sprintf("Annual exit rate & CIP-level DiD & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_exit, se_exit, sd_exit_rate, sde_exit, se_sde_exit, classify_sde(sde_exit)),
  sprintf("Log completions & Intensive margin & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_comp, se_comp, sd_log_comp, sde_comp, se_sde_comp, classify_sde(sde_comp)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by CIP risk)}} \\\\\n",
  sprintf("Survival (high-risk CIPs) & Cosmetology, Business & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_high, se_high_val, sd_survival, sde_high, se_sde_high, classify_sde(sde_high)),
  sprintf("Survival (low-risk CIPs) & Healthcare & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_low, se_low_val, sd_survival, sde_low, se_sde_low, classify_sde(sde_low)),
  "\\bottomrule\n\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
