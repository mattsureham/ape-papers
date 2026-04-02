# 05_tables.R — Generate all tables for paper
# APEP Paper apep_1292: Sunshine Through the Alps

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
panel <- fread(file.path(data_dir, "panel_main.csv"))
panel[, L_REP_CTY := as.character(L_REP_CTY)]
panel[, unit_id := as.character(unit_id)]
panel[, time_period := as.integer((year - 2000) * 4 + qtr_num)]

main_results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

sd_y_pre <- main_results$sd_y_pre

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

summ_by_pos <- panel[, .(
  N_countries = uniqueN(L_REP_CTY),
  N_obs = .N,
  Mean = mean(value_usd, na.rm = TRUE),
  SD = sd(value_usd, na.rm = TRUE),
  Median = median(value_usd, na.rm = TRUE),
  Mean_log = mean(log_position, na.rm = TRUE),
  SD_log = sd(log_position, na.rm = TRUE)
), by = L_POSITION]

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Bilateral Banking Positions with Liechtenstein}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Countries & Obs. & Mean (\\$M) & Mean (log) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: By Position Type}} \\\\\n"
)

for (pos in c("C", "L")) {
  row <- summ_by_pos[L_POSITION == pos]
  label <- ifelse(pos == "C", "Claims on LI", "Liabilities to LI")
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %d & %d & %.1f & %.2f \\\\\n",
            label, row$N_countries, row$N_obs, row$Mean, row$Mean_log))
  tab1_tex <- paste0(tab1_tex,
    sprintf(" & & & (%.1f) & (%.2f) \\\\\n", row$SD, row$SD_log))
}

# Pre/post for pooled panel
pre_all <- panel[treated == 0, .(Mean = mean(value_usd), SD = sd(value_usd),
                                  Mean_log = mean(log_position), SD_log = sd(log_position),
                                  N = .N)]
post_all <- panel[treated == 1, .(Mean = mean(value_usd), SD = sd(value_usd),
                                   Mean_log = mean(log_position), SD_log = sd(log_position),
                                   N = .N)]

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Pre vs. Post AEOI (Pooled)}} \\\\\n",
  sprintf("Pre-AEOI & --- & %d & %.1f & %.2f \\\\\n",
          pre_all$N, pre_all$Mean, pre_all$Mean_log),
  sprintf(" & & & (%.1f) & (%.2f) \\\\\n", pre_all$SD, pre_all$SD_log),
  sprintf("Post-AEOI & --- & %d & %.1f & %.2f \\\\\n",
          post_all$N, post_all$Mean, post_all$Mean_log),
  sprintf(" & & & (%.1f) & (%.2f) \\\\\n", post_all$SD, post_all$SD_log),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} BIS Locational Banking Statistics, 2010--2023. ",
  "Claims are cross-border positions of reporter countries on Liechtenstein; ",
  "liabilities are Liechtenstein bank positions with reporter countries. ",
  "Values in millions of USD. Standard deviations in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results\n")

r <- main_results
implied_pct <- function(b) round((exp(b) - 1) * 100, 1)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of AEOI Activation on Bilateral Banking Positions}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Pooled & Claims & Liabilities & Sun-Abraham & EU/EEA + \\\\\n",
  " & TWFE & Only & Only & ATT & Later Waves \\\\\n",
  "\\hline\n",
  sprintf("AEOI Active & %.3f%s & %.3f%s & %.3f%s & %.3f & %.3f%s \\\\\n",
    r$pooled_twfe$coef, stars(r$pooled_twfe$pval),
    r$claims_twfe$coef, stars(r$claims_twfe$pval),
    r$liab_twfe$coef, stars(r$liab_twfe$pval),
    r$sunab$att_coef,
    r$eu_twfe$coef, stars(r$eu_twfe$pval)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    r$pooled_twfe$se, r$claims_twfe$se, r$liab_twfe$se,
    r$sunab$att_se, r$eu_twfe$se),
  sprintf("Implied \\%% Change & %.1f\\%% & %.1f\\%% & %.1f\\%% & %.1f\\%% & %.1f\\%% \\\\\n",
    implied_pct(r$pooled_twfe$coef),
    implied_pct(r$claims_twfe$coef),
    implied_pct(r$liab_twfe$coef),
    implied_pct(r$sunab$att_coef),
    implied_pct(r$eu_twfe$coef)),
  "\\hline\n",
  sprintf("Position Type & Both & Claims & Liabilities & Both & Both \\\\\n"),
  "Unit FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Countries & %d & %d & %d & %d & %d \\\\\n",
    r$pooled_twfe$n_countries, r$claims_twfe$n_countries,
    r$liab_twfe$n_countries, r$pooled_twfe$n_countries,
    r$eu_twfe$n_countries),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
    r$pooled_twfe$n, r$claims_twfe$n, r$liab_twfe$n,
    r$pooled_twfe$n, r$eu_twfe$n),
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f & --- & %.3f \\\\\n",
    r$pooled_twfe$r2, r$claims_twfe$r2, r$liab_twfe$r2, r$eu_twfe$r2),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is log(position $+$ 1) where positions are in millions of USD. ",
  "Column (1) pools claims and liabilities with country$\\times$position fixed effects. ",
  "Columns (2)--(3) decompose by position type. ",
  "Column (4) reports the aggregate ATT from \\citet{sun2021estimating}. ",
  "Column (5) restricts to EU/EEA countries plus later AEOI waves. ",
  "Standard errors clustered by reporter country in parentheses. ",
  "Implied \\% change = $\\exp(\\hat{\\beta}) - 1$. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Robustness
# ============================================================
cat("Generating Table 3: Robustness\n")

rb <- rob_results

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Estimate & Std. Error \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Anticipation Test}} \\\\\n",
  sprintf("Pre-AEOI (4 quarters) & %.3f & (%.3f) \\\\\n",
    rb$anticipation_coef, rb$anticipation_se),
  sprintf("Post-AEOI & %.3f & (%.3f) \\\\\n",
    rb$post_only_coef, rb$post_only_se),
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Inference}} \\\\\n",
  sprintf("Randomization inference $p$-value & \\multicolumn{2}{c}{%.3f} \\\\\n",
    rb$ri_pval),
  sprintf("Leave-one-out range & \\multicolumn{2}{c}{[%.2f, %.2f]} \\\\\n",
    rb$loo_min, rb$loo_max),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A tests for anticipation effects by including a 4-quarter pre-activation window. ",
  "Panel B reports alternative inference: randomization inference (999 permutations, two-sided) and ",
  "the range of TWFE coefficients when dropping each country. ",
  "All specifications use the pooled claims$+$liabilities panel with country$\\times$position and quarter FE, ",
  "clustered by reporter country.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))

# ============================================================
# Table 4: Event Study
# ============================================================
cat("Generating Table 4: Event Study\n")

es <- fread(file.path(data_dir, "event_study_coefs.csv"))

# Select key event times
key_times <- c(-8, -5, -4, -3, -2, 0, 1, 2, 4, 8, 12)
es_tab <- es[event_time %in% key_times]

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Selected Sun-Abraham Coefficients}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event Time & Estimate & Std. Error & 95\\% CI \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es_tab))) {
  row <- es_tab[i]
  tab4_tex <- paste0(tab4_tex,
    sprintf("$t = %+d$ & %.3f & (%.3f) & [%.2f, %.2f] \\\\\n",
      row$event_time, row$estimate, row$se, row$ci_low, row$ci_high))
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sun-Abraham interaction-weighted event-study coefficients ",
  "from the pooled panel. Dependent variable is log(position $+$ 1). ",
  "Reference period is $t = -1$. Standard errors clustered by reporter country.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_eventstudy.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes
# ============================================================
cat("Generating Table F1: SDE\n")

# SDE = coefficient / pre-treatment SD
r <- main_results
sde_pooled <- r$pooled_twfe$coef / sd_y_pre
sde_claims <- r$claims_twfe$coef / sd_y_pre
sde_liab <- r$liab_twfe$coef / sd_y_pre
sde_eu <- r$eu_twfe$coef / sd_y_pre

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Pooled & Claims & Liabilities & EU/EEA \\\\\n",
  "\\hline\n",
  sprintf("Coefficient ($\\hat{\\beta}$) & %.3f & %.3f & %.3f & %.3f \\\\\n",
    r$pooled_twfe$coef, r$claims_twfe$coef, r$liab_twfe$coef, r$eu_twfe$coef),
  sprintf("Pre-treatment SD & \\multicolumn{4}{c}{%.3f} \\\\\n", sd_y_pre),
  sprintf("SDE ($\\hat{\\beta}/\\sigma$) & %.3f & %.3f & %.3f & %.3f \\\\\n",
    sde_pooled, sde_claims, sde_liab, sde_eu),
  "\\hline\n",
  "Interpretation & ",
  ifelse(abs(sde_pooled) < 0.2, "Small", ifelse(abs(sde_pooled) < 0.5, "Medium", "Large")),
  " & ",
  ifelse(abs(sde_claims) < 0.2, "Small", ifelse(abs(sde_claims) < 0.5, "Medium", "Large")),
  " & ",
  ifelse(abs(sde_liab) < 0.2, "Small", ifelse(abs(sde_liab) < 0.5, "Medium", "Large")),
  " & ",
  ifelse(abs(sde_eu) < 0.2, "Small", ifelse(abs(sde_eu) < 0.5, "Medium", "Large")),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Standardized effect size (SDE) = $\\hat{\\beta} / \\sigma_{Y,\\text{pre}}$. ",
  "Pre-treatment SD computed from the pooled panel. ",
  "Cohen's $d$ thresholds: $|SDE| < 0.2$ (small), $0.2$--$0.5$ (medium), $> 0.5$ (large).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
