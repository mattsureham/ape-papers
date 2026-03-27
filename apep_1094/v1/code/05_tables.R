# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

source("00_packages.R")

results    <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
panel_all  <- readRDS("../data/panel_all.rds")
panel_white <- readRDS("../data/panel_white.rds")
panel_black <- readRDS("../data/panel_black.rds")
panel_hisp  <- readRDS("../data/panel_hisp.rds")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_data <- panel_all %>%
  filter(race == "A0", year >= 2003) %>%
  group_by(treated) %>%
  summarize(
    n_states = n_distinct(state_abbr),
    n_obs = n(),
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hir = mean(HirA, na.rm = TRUE),
    sd_hir = sd(HirA, na.rm = TRUE),
    mean_earn = mean(EarnHirAS, na.rm = TRUE),
    sd_earn = sd(EarnHirAS, na.rm = TRUE),
    .groups = "drop"
  )

# Also get race-specific stats for treated states
race_stats <- bind_rows(
  panel_white %>% filter(treated, year >= 2003) %>%
    summarize(race = "White", mean_emp = mean(Emp, na.rm = TRUE),
              sd_emp = sd(Emp, na.rm = TRUE)),
  panel_black %>% filter(treated, year >= 2003) %>%
    summarize(race = "Black", mean_emp = mean(Emp, na.rm = TRUE),
              sd_emp = sd(Emp, na.rm = TRUE)),
  panel_hisp %>% filter(treated, year >= 2003) %>%
    summarize(race = "Hispanic", mean_emp = mean(Emp, na.rm = TRUE),
              sd_emp = sd(Emp, na.rm = TRUE))
)

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: NAICS 512 Employment by Treatment Status}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Never-Treated} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  sprintf("Employment (all races) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          summ_data$mean_emp[summ_data$treated], summ_data$sd_emp[summ_data$treated],
          summ_data$mean_emp[!summ_data$treated], summ_data$sd_emp[!summ_data$treated]),
  sprintf("Hires (all races) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          summ_data$mean_hir[summ_data$treated], summ_data$sd_hir[summ_data$treated],
          summ_data$mean_hir[!summ_data$treated], summ_data$sd_hir[!summ_data$treated]),
  sprintf("Earnings (\\$) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          summ_data$mean_earn[summ_data$treated], summ_data$sd_earn[summ_data$treated],
          summ_data$mean_earn[!summ_data$treated], summ_data$sd_earn[!summ_data$treated]),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Treated states, by race:}} \\\\\n",
  sprintf("\\quad White employment & %.0f & %.0f & & \\\\\n",
          race_stats$mean_emp[race_stats$race == "White"],
          race_stats$sd_emp[race_stats$race == "White"]),
  sprintf("\\quad Black employment & %.0f & %.0f & & \\\\\n",
          race_stats$mean_emp[race_stats$race == "Black"],
          race_stats$sd_emp[race_stats$race == "Black"]),
  sprintf("\\quad Hispanic employment & %.0f & %.0f & & \\\\\n",
          race_stats$mean_emp[race_stats$race == "Hispanic"],
          race_stats$sd_emp[race_stats$race == "Hispanic"]),
  "\\addlinespace\n",
  sprintf("States & %d & & %d & \\\\\n",
          summ_data$n_states[summ_data$treated], summ_data$n_states[!summ_data$treated]),
  sprintf("State-quarter obs & %d & & %d & \\\\\n",
          summ_data$n_obs[summ_data$treated], summ_data$n_obs[!summ_data$treated]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Data from Census QWI (race/ethnicity table, NAICS 512 Motion Picture), quarterly 2003--2024. Treated states adopted film production tax credits ($\\geq$15\\% rate) between 2002 and 2019. Never-treated states include AK, CA, DE, ID, IA, KS, ND, NE, NH, SD, VT, WY, DC. Employment, hires, and earnings are state-quarter means.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main Results — CS-DiD ATT by Race
# =============================================================================
cat("Generating Table 2: Main CS-DiD Results...\n")

make_stars <- function(att, se) {
  z <- abs(att / se)
  if (z > 2.576) return("***")
  if (z > 1.960) return("**")
  if (z > 1.645) return("*")
  return("")
}

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Film Tax Credits and NAICS 512 Employment by Race}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & All Races & White & Black & Hispanic \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Log Employment (CS-DiD ATT)}} \\\\\n",
  sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          results$agg_all$overall.att, make_stars(results$agg_all$overall.att, results$agg_all$overall.se),
          results$res_white$agg$overall.att, make_stars(results$res_white$agg$overall.att, results$res_white$agg$overall.se),
          results$res_black$agg$overall.att, make_stars(results$res_black$agg$overall.att, results$res_black$agg$overall.se),
          results$res_hisp$agg$overall.att, make_stars(results$res_hisp$agg$overall.att, results$res_hisp$agg$overall.se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          results$agg_all$overall.se, results$res_white$agg$overall.se,
          results$res_black$agg$overall.se, results$res_hisp$agg$overall.se),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Log Hires (CS-DiD ATT)}} \\\\\n",
  sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          results$hir_all$agg$overall.att, make_stars(results$hir_all$agg$overall.att, results$hir_all$agg$overall.se),
          results$hir_white$agg$overall.att, make_stars(results$hir_white$agg$overall.att, results$hir_white$agg$overall.se),
          results$hir_black$agg$overall.att, make_stars(results$hir_black$agg$overall.att, results$hir_black$agg$overall.se),
          results$hir_hisp$agg$overall.att, make_stars(results$hir_hisp$agg$overall.att, results$hir_hisp$agg$overall.se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          results$hir_all$agg$overall.se, results$hir_white$agg$overall.se,
          results$hir_black$agg$overall.se, results$hir_hisp$agg$overall.se),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Log Earnings (CS-DiD ATT)}} \\\\\n",
  sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          results$earn_all$agg$overall.att, make_stars(results$earn_all$agg$overall.att, results$earn_all$agg$overall.se),
          results$earn_white$agg$overall.att, make_stars(results$earn_white$agg$overall.att, results$earn_white$agg$overall.se),
          results$earn_black$agg$overall.att, make_stars(results$earn_black$agg$overall.att, results$earn_black$agg$overall.se),
          results$earn_hisp$agg$overall.att, make_stars(results$earn_hisp$agg$overall.att, results$earn_hisp$agg$overall.se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          results$earn_all$agg$overall.se, results$earn_white$agg$overall.se,
          results$earn_black$agg$overall.se, results$earn_hisp$agg$overall.se),
  "\\midrule\n",
  "Estimator & \\multicolumn{4}{c}{Callaway \\& Sant'Anna (2021)} \\\\\n",
  "Control group & \\multicolumn{4}{c}{Never-treated states} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each cell reports the aggregated group-time ATT from Callaway and Sant'Anna (2021). Outcomes are log(variable + 1) for NAICS 512 (Motion Picture). Treatment is state adoption of film production tax credits ($\\geq$15\\% rate). Control group is never-treated states. Standard errors in parentheses use analytical formula from Callaway and Sant'Anna (2021). \\sym{*}~$p<0.10$, \\sym{**}~$p<0.05$, \\sym{***}~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: TWFE Comparison (what Button 2019 estimated)
# =============================================================================
cat("Generating Table 3: TWFE Comparison...\n")

get_twfe_vals <- function(fit) {
  b <- coef(fit)["postTRUE"]
  s <- se(fit)["postTRUE"]
  n <- fit$nobs
  r2 <- fitstat(fit, "r2")$r2
  list(b = b, s = s, n = n, r2 = r2)
}

tw_all  <- get_twfe_vals(results$twfe_all)
tw_wht  <- get_twfe_vals(results$twfe_white)
tw_blk  <- get_twfe_vals(results$twfe_black)
tw_hsp  <- get_twfe_vals(results$twfe_hisp)

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{TWFE Estimates: Film Tax Credits on Log Employment (NAICS 512)}\n",
  "\\label{tab:twfe}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & All Races & White & Black & Hispanic \\\\\n",
  "\\midrule\n",
  sprintf("Post-Credit & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          tw_all$b, make_stars(tw_all$b, tw_all$s),
          tw_wht$b, make_stars(tw_wht$b, tw_wht$s),
          tw_blk$b, make_stars(tw_blk$b, tw_blk$s),
          tw_hsp$b, make_stars(tw_hsp$b, tw_hsp$s)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          tw_all$s, tw_wht$s, tw_blk$s, tw_hsp$s),
  "\\addlinespace\n",
  sprintf("$N$ & %d & %d & %d & %d \\\\\n",
          tw_all$n, tw_wht$n, tw_blk$n, tw_hsp$n),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          tw_all$r2, tw_wht$r2, tw_blk$r2, tw_hsp$r2),
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at state level in parentheses. Dependent variable: $\\log(\\text{employment} + 1)$ in NAICS 512. The TWFE estimator may produce biased estimates under treatment effect heterogeneity \\citep{deChaisemartin2020, GoodmanBacon2021}. \\sym{*}~$p<0.10$, \\sym{**}~$p<0.05$, \\sym{***}~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_twfe.tex")

# =============================================================================
# Table 4: Robustness — Placebo, NC Repeal, Heterogeneity
# =============================================================================
cat("Generating Table 4: Robustness...\n")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & ATT & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Placebo sector (NAICS 722, Food Services)}} \\\\\n",
  sprintf("Log employment & %.4f%s & (%.4f) \\\\\n",
          robustness$placebo_722$att, make_stars(robustness$placebo_722$att, robustness$placebo_722$se),
          robustness$placebo_722$se),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: NC credit repeal (2014, NC vs GA)}} \\\\\n",
  {
    nc_coef <- coef(robustness$nc_repeal)["is_ncTRUE:repeal_postTRUE"]
    nc_se <- sqrt(diag(vcov(robustness$nc_repeal)))["is_ncTRUE:repeal_postTRUE"]
    if (is.na(nc_coef)) { nc_coef <- 0; nc_se <- 0 }
    sprintf("DiD (NC $\\times$ Post-2014) & %.4f%s & (%.4f) \\\\\n",
            nc_coef, make_stars(nc_coef, nc_se), nc_se)
  },
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Heterogeneity by pre-treatment Black share (Black emp)}} \\\\\n",
  sprintf("High Black share states & %.4f%s & (%.4f) \\\\\n",
          robustness$het_high_black$att, make_stars(robustness$het_high_black$att, robustness$het_high_black$se),
          robustness$het_high_black$se),
  sprintf("Low Black share states & %.4f%s & (%.4f) \\\\\n",
          robustness$het_low_black$att, make_stars(robustness$het_low_black$att, robustness$het_low_black$se),
          robustness$het_low_black$se),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Randomization inference (TWFE, all races)}} \\\\\n",
  sprintf("RI $p$-value (two-sided) & \\multicolumn{2}{c}{%.4f} \\\\\n", robustness$ri_pval),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A uses Callaway and Sant'Anna (2021) on NAICS 722 (Food Services), which should be unaffected by film tax credits. Panel B uses two-way fixed effects DiD comparing NC (credit repealed 2014) to GA (credit maintained) before and after 2014. Panel C splits treated states by pre-treatment median Black employment share in NAICS 512 and runs CS-DiD separately on each sample. Panel D reports a randomization inference $p$-value from 999 permutations of state treatment assignments. \\sym{*}~$p<0.10$, \\sym{**}~$p<0.05$, \\sym{***}~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robust.tex")

# =============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# =============================================================================
cat("Generating Table F1: SDE Appendix...\n")

# Pre-treatment SD of outcomes
pre_all <- panel_all %>% filter(!post, year >= 2003, Emp > 0)
sd_emp_pre <- sd(pre_all$log_emp, na.rm = TRUE)

pre_black <- panel_black %>% filter(!post, year >= 2003, Emp > 0)
sd_emp_black_pre <- sd(pre_black$log_emp, na.rm = TRUE)

# Main outcomes and SDE calculations
sde_rows <- tribble(
  ~outcome, ~beta, ~se, ~sd_y, ~panel,
  "Log employment (all races)", results$agg_all$overall.att, results$agg_all$overall.se, sd_emp_pre, "A",
  "Log hires (all races)", results$hir_all$agg$overall.att, results$hir_all$agg$overall.se, sd(pre_all$log_hir, na.rm = TRUE), "A",
  "Log earnings (all races)", results$earn_all$agg$overall.att, results$earn_all$agg$overall.se, sd(pre_all$log_earn, na.rm = TRUE), "A",
  "Log employment (Black)", results$res_black$agg$overall.att, results$res_black$agg$overall.se, sd_emp_black_pre, "B",
  "Log employment (high Black share)", robustness$het_high_black$att, robustness$het_high_black$se, sd_emp_black_pre, "B"
)

sde_rows <- sde_rows %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Generate SDE table
sde_body <- paste(apply(sde_rows, 1, function(row) {
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
          row["outcome"], as.numeric(row["beta"]), as.numeric(row["se"]),
          as.numeric(row["sd_y"]), as.numeric(row["sde"]), as.numeric(row["se_sde"]),
          row["classification"])
}), collapse = " \\\\\n")

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state film production tax credits increase motion picture industry employment, and do employment gains differ by race? ",
  "\\textbf{Policy mechanism:} State tax credits of 15--40\\% of qualified production expenditures reduce the after-tax cost of filming in-state, incentivizing production companies to locate shoots and hire local crews in the adopting state. ",
  "\\textbf{Outcome definition:} Log quarterly employment (Emp + 1) in NAICS 512 (Motion Picture and Sound Recording) from Census QWI race/ethnicity tables. ",
  "\\textbf{Treatment:} Binary; state-quarter adoption of film production tax credits at $\\geq$15\\% rate. ",
  "\\textbf{Data:} Census QWI (race/ethnicity), 2003--2024, state-quarter, 37 treated + 13 never-treated states, approximately 4,000 state-quarter observations per race group. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated control group and analytical standard errors. ",
  "\\textbf{Sample:} All 50 states plus DC; treatment defined as credit adoption at $\\geq$15\\% rate; never-treated states had no substantial film production tax credit program through 2024. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(apply(sde_rows %>% filter(panel == "A"), 1, function(row) {
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
            row["outcome"], as.numeric(row["beta"]), as.numeric(row["se"]),
            as.numeric(row["sd_y"]), as.numeric(row["sde"]), as.numeric(row["se_sde"]),
            row["classification"])
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  paste(apply(sde_rows %>% filter(panel == "B"), 1, function(row) {
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
            row["outcome"], as.numeric(row["beta"]), as.numeric(row["se"]),
            as.numeric(row["sd_y"]), as.numeric(row["sde"]), as.numeric(row["se_sde"]),
            row["classification"])
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("  tab1_summary.tex\n  tab2_main.tex\n  tab3_twfe.tex\n  tab4_robust.tex\n  tabF1_sde.tex\n")
