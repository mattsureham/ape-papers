## 05_tables.R — Generate all tables for paper
## apep_0787: PSL mandates and workplace injuries

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))
industry_panel <- readRDS(file.path(data_dir, "industry_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

state_panel[, treated := as.integer(first_treat > 0 & data_year >= first_treat)]
state_panel[, post := as.integer(first_treat > 0 & data_year >= first_treat)]

# ── Table 1: Summary Statistics ────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment summary by treatment group
pre_treated <- state_panel[first_treat > 0 & data_year < first_treat]
pre_control <- state_panel[first_treat == 0]

make_sumstat_row <- function(var, label, dt1, dt2) {
  m1 <- round(mean(dt1[[var]], na.rm = TRUE), 3)
  s1 <- round(sd(dt1[[var]], na.rm = TRUE), 3)
  m2 <- round(mean(dt2[[var]], na.rm = TRUE), 3)
  s2 <- round(sd(dt2[[var]], na.rm = TRUE), 3)
  paste0(label, " & ", m1, " & (", s1, ") & ", m2, " & (", s2, ") \\\\")
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Injury Rates by Treatment Group}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Never-Treated States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  make_sumstat_row("tcr", "Total case rate", pre_treated, pre_control),
  make_sumstat_row("dafw_rate", "DAFW rate", pre_treated, pre_control),
  make_sumstat_row("djtr_rate", "DJTR rate", pre_treated, pre_control),
  make_sumstat_row("n_estab", "Establishments", pre_treated, pre_control),
  make_sumstat_row("total_employees", "Total employees", pre_treated, pre_control),
  "\\midrule",
  paste0("Observations & \\multicolumn{2}{c}{", nrow(pre_treated),
         "} & \\multicolumn{2}{c}{", nrow(pre_control), "} \\\\"),
  paste0("States & \\multicolumn{2}{c}{",
         length(unique(pre_treated$state_abbr)),
         "} & \\multicolumn{2}{c}{",
         length(unique(pre_control$state_abbr)), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Injury rates are per 100 full-time equivalent workers (FTE = hours/2,000). DAFW = days away from work cases. DJTR = days of job transfer or restriction cases. Pre-treatment period defined as all years before each state's PSL mandate effective date. Treated states: AZ, CO, MD, MI, NJ, NY, RI, WA (8 states). Never-treated states: 37 states without statewide PSL mandates through 2023.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ── Table 2: Main Results ──────────────────────────────────────────────────
cat("Generating Table 2: Main Results\n")

# Extract CS results
cs_att <- function(obj) {
  att <- aggte(obj, type = "simple")
  list(est = att$overall.att, se = att$overall.se)
}

tcr_cs <- cs_att(results$cs_tcr)
dafw_cs <- cs_att(results$cs_dafw)
djtr_cs <- cs_att(results$cs_djtr)

# Stars function
stars <- function(est, se) {
  pval <- 2 * pnorm(-abs(est / se))
  s <- ""
  if (pval < 0.01) s <- "***"
  else if (pval < 0.05) s <- "**"
  else if (pval < 0.1) s <- "*"
  s
}

fmt <- function(x) formatC(round(x, 4), format = "f", digits = 4)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Paid Sick Leave Mandates on Workplace Injury Rates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Total Case & DAFW & DJTR \\\\",
  " & Rate & Rate & Rate \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway-Sant'Anna (2021)}} \\\\[4pt]",
  paste0("PSL mandate & ", fmt(tcr_cs$est), stars(tcr_cs$est, tcr_cs$se),
         " & ", fmt(dafw_cs$est), stars(dafw_cs$est, dafw_cs$se),
         " & ", fmt(djtr_cs$est), stars(djtr_cs$est, djtr_cs$se), " \\\\"),
  paste0(" & (", fmt(tcr_cs$se), ") & (", fmt(dafw_cs$se), ") & (", fmt(djtr_cs$se), ") \\\\"),
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\[4pt]",
  paste0("PSL mandate & ", fmt(coef(results$twfe_tcr)["treated"]),
         stars(coef(results$twfe_tcr)["treated"], se(results$twfe_tcr)["treated"]),
         " & ", fmt(coef(results$twfe_dafw)["treated"]),
         stars(coef(results$twfe_dafw)["treated"], se(results$twfe_dafw)["treated"]),
         " & ", fmt(coef(results$twfe_djtr)["treated"]),
         stars(coef(results$twfe_djtr)["treated"], se(results$twfe_djtr)["treated"]),
         " \\\\"),
  paste0(" & (", fmt(se(results$twfe_tcr)["treated"]),
         ") & (", fmt(se(results$twfe_dafw)["treated"]),
         ") & (", fmt(se(results$twfe_djtr)["treated"]), ") \\\\"),
  "\\addlinespace",
  "\\multicolumn{4}{l}{\\textit{Panel C: Sun-Abraham (2021)}} \\\\[4pt]",
  {
    # Extract SA post-treatment ATT manually (average of e >= 0 coefficients)
    sa_att <- function(mod) {
      ct <- mod$coeftable
      rn <- rownames(ct)
      # Post-treatment: event times >= 0
      post_idx <- grep("::([0-9])", rn)
      if (length(post_idx) == 0) return(list(est = NA, se = NA))
      est <- mean(ct[post_idx, "Estimate"])
      # SE via delta method: SE(mean) = sqrt(sum(var))/n
      se <- sqrt(sum(ct[post_idx, "Std. Error"]^2)) / length(post_idx)
      list(est = est, se = se)
    }
    sa_tcr_att <- sa_att(rob_results$sa_tcr)
    sa_dafw_att <- sa_att(rob_results$sa_dafw)
    sa_djtr_att <- sa_att(rob_results$sa_djtr)
    NULL
  },
  paste0("ATT & ", fmt(sa_tcr_att$est),
         " & ", fmt(sa_dafw_att$est),
         " & ", fmt(sa_djtr_att$est), " \\\\"),
  paste0(" & (", fmt(sa_tcr_att$se),
         ") & (", fmt(sa_dafw_att$se),
         ") & (", fmt(sa_djtr_att$se), ") \\\\"),
  "\\midrule",
  paste0("Pre-treatment mean & ",
         fmt(mean(pre_treated$tcr, na.rm = TRUE)), " & ",
         fmt(mean(pre_treated$dafw_rate, na.rm = TRUE)), " & ",
         fmt(mean(pre_treated$djtr_rate, na.rm = TRUE)), " \\\\"),
  paste0("Observations & \\multicolumn{3}{c}{", nrow(state_panel), "} \\\\"),
  paste0("States & \\multicolumn{3}{c}{", length(unique(state_panel$state_abbr)), "} \\\\"),
  paste0("Treated states & \\multicolumn{3}{c}{",
         length(unique(state_panel[first_treat > 0]$state_abbr)), "} \\\\"),
  "Clustering & \\multicolumn{3}{c}{State} \\\\",
  "State \\& year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the estimated effect of state paid sick leave mandates on workplace injury rates per 100 FTE. Panel~A uses the Callaway and Sant'Anna (2021) estimator with never-treated states as controls. Panel~B reports two-way fixed-effects estimates. Panel~C reports Sun and Abraham (2021) interaction-weighted estimates. All panels include state and year fixed effects with standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ── Table 3: Robustness ───────────────────────────────────────────────────
cat("Generating Table 3: Robustness\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & TCR & DJTR \\\\",
  " & (1) & (2) \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Wild cluster bootstrap p-values}} \\\\[4pt]",
  paste0("TWFE estimate & ", fmt(coef(results$twfe_tcr)["treated"]),
         " & ", fmt(coef(results$twfe_djtr)["treated"]), " \\\\"),
  paste0("Bootstrap p-value & ", round(rob_results$boot_tcr$p_val, 3),
         " & ", round(rob_results$boot_djtr$p_val, 3), " \\\\"),
  paste0("Bootstrap 95\\% CI & [", round(rob_results$boot_tcr$conf_int[1], 3),
         ", ", round(rob_results$boot_tcr$conf_int[2], 3),
         "] & [", round(rob_results$boot_djtr$conf_int[1], 3),
         ", ", round(rob_results$boot_djtr$conf_int[2], 3), "] \\\\"),
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel B: Excluding COVID years (2020--2021)}} \\\\[4pt]",
  paste0("PSL mandate & ", fmt(coef(rob_results$twfe_tcr_nc)["treated"]),
         " & ", fmt(coef(rob_results$twfe_djtr_nc)["treated"]), " \\\\"),
  paste0(" & (", fmt(se(rob_results$twfe_tcr_nc)["treated"]),
         ") & (", fmt(se(rob_results$twfe_djtr_nc)["treated"]), ") \\\\"),
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel C: Industry-level panel}} \\\\[4pt]",
  paste0("PSL mandate & ", fmt(coef(rob_results$twfe_ind_tcr)["treated"]),
         " & ", fmt(coef(rob_results$twfe_ind_djtr)["treated"]), " \\\\"),
  paste0(" & (", fmt(se(rob_results$twfe_ind_tcr)["treated"]),
         ") & (", fmt(se(rob_results$twfe_ind_djtr)["treated"]), ") \\\\"),
  paste0("Observations & ", nrow(industry_panel[!is.na(tcr)]),
         " & ", nrow(industry_panel[!is.na(djtr_rate)]), " \\\\"),
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel D: Placebo outcome (death rate)}} \\\\[4pt]",
  paste0("PSL mandate & \\multicolumn{2}{c}{",
         fmt(coef(rob_results$twfe_death)["treated"]),
         " (", fmt(se(rob_results$twfe_death)["treated"]), ")} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel~A reports Webb six-point distribution wild cluster bootstrap inference (9,999 iterations) to address few-cluster concerns with 8 treated states. Panel~B excludes 2020--2021 to address potential COVID-19 confounding. Panel~C uses state $\\times$ NAICS 2-digit $\\times$ year cells instead of state-year aggregates. Panel~D reports a placebo test using workplace fatality rates, which should be unaffected by presenteeism. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_robustness.tex"))

# ── Table 4: Heterogeneity ─────────────────────────────────────────────────
cat("Generating Table 4: Heterogeneity\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Industry Hazard Level}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Total Case Rate} & \\multicolumn{2}{c}{DJTR Rate} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & High Hazard & Low Hazard & High Hazard & Low Hazard \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  paste0("PSL mandate & ",
         fmt(coef(rob_results$het_high_tcr)["treated"]),
         " & ", fmt(coef(rob_results$het_low_tcr)["treated"]),
         " & ", fmt(coef(rob_results$het_high_djtr)["treated"]),
         " & ", fmt(coef(rob_results$het_low_djtr)["treated"]), " \\\\"),
  paste0(" & (", fmt(se(rob_results$het_high_tcr)["treated"]),
         ") & (", fmt(se(rob_results$het_low_tcr)["treated"]),
         ") & (", fmt(se(rob_results$het_high_djtr)["treated"]),
         ") & (", fmt(se(rob_results$het_low_djtr)["treated"]), ") \\\\"),
  "\\midrule",
  paste0("Observations & ", nobs(rob_results$het_high_tcr),
         " & ", nobs(rob_results$het_low_tcr),
         " & ", nobs(rob_results$het_high_djtr),
         " & ", nobs(rob_results$het_low_djtr), " \\\\"),
  "Cell \\& year FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Clustering & \\multicolumn{4}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} High-hazard industries include construction (NAICS 23), manufacturing (31--33), transportation (48--49), agriculture (11), and mining (21). Low-hazard industries include information (51), finance (52), real estate (53), professional services (54), and management (55). Each regression includes state$\\times$industry cell and year fixed effects with standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_heterogeneity.tex"))

# ── Table F1: SDE Appendix (mandatory) ─────────────────────────────────────
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for main outcomes
# SDE = beta_hat / SD(Y), using pre-treatment SD
sd_tcr <- sd(pre_treated$tcr, na.rm = TRUE)
sd_dafw <- sd(pre_treated$dafw_rate, na.rm = TRUE)
sd_djtr <- sd(pre_treated$djtr_rate, na.rm = TRUE)

sde_tcr <- tcr_cs$est / sd_tcr
sde_dafw <- dafw_cs$est / sd_dafw
sde_djtr <- djtr_cs$est / sd_djtr

se_sde_tcr <- tcr_cs$se / sd_tcr
se_sde_dafw <- dafw_cs$se / sd_dafw
se_sde_djtr <- djtr_cs$se / sd_djtr

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state paid sick leave mandates reduce establishment-level workplace injury rates by allowing sick or fatigued workers to stay home? ",
  "\\textbf{Policy mechanism:} Mandates require employers to provide paid sick leave, ",
  "enabling workers to take time off when ill without income loss, potentially reducing ",
  "presenteeism-related injuries in physically demanding occupations. ",
  "\\textbf{Outcome definition:} Injury rates per 100 full-time equivalent workers (FTE = annual hours worked / 2,000), ",
  "reported on OSHA Form 300A: total recordable cases (TCR), days-away-from-work cases (DAFW), ",
  "and days of job transfer or restriction cases (DJTR). ",
  "\\textbf{Treatment:} Binary; indicator for state having enacted a mandatory paid sick leave law in a given year. ",
  "\\textbf{Data:} OSHA Injury Tracking Application (ITA) establishment-level 300A summaries, 2017--2023, ",
  "aggregated to state-year panel with 315 observations across 45 states. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated states ",
  "as controls, standard errors clustered at the state level. ",
  "\\textbf{Sample:} Establishments required to submit Form 300A to OSHA (generally 250+ employees ",
  "or high-hazard industries with 20+ employees); excludes always-treated states (CT, CA, MA, DC, OR, VT). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  paste0("Total case rate & ", fmt(tcr_cs$est), " & ", fmt(tcr_cs$se),
         " & ", fmt(sd_tcr), " & ", fmt(sde_tcr), " & ", fmt(se_sde_tcr),
         " & ", classify_sde(sde_tcr), " \\\\"),
  paste0("DAFW rate & ", fmt(dafw_cs$est), " & ", fmt(dafw_cs$se),
         " & ", fmt(sd_dafw), " & ", fmt(sde_dafw), " & ", fmt(se_sde_dafw),
         " & ", classify_sde(sde_dafw), " \\\\"),
  paste0("DJTR rate & ", fmt(djtr_cs$est), " & ", fmt(djtr_cs$se),
         " & ", fmt(sd_djtr), " & ", fmt(sde_djtr), " & ", fmt(se_sde_djtr),
         " & ", classify_sde(sde_djtr), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("Files:\n")
cat("  ", file.path(tables_dir, "tab1_summary.tex"), "\n")
cat("  ", file.path(tables_dir, "tab2_main.tex"), "\n")
cat("  ", file.path(tables_dir, "tab3_robustness.tex"), "\n")
cat("  ", file.path(tables_dir, "tab4_heterogeneity.tex"), "\n")
cat("  ", file.path(tables_dir, "tabF1_sde.tex"), "\n")
