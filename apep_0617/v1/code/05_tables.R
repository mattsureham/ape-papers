## 05_tables.R — Generate all LaTeX tables
## Tables: (1) Summary stats, (2) Main CS-DiD, (3) TWFE + triple-diff,
##         (4) Mechanisms, (5) Robustness, (F1) SDE appendix

source("00_packages.R")

panel <- fread("../data/panel_main.csv")
load("../data/analysis_results.RData")
load("../data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE)

# Helper: format number with stars
fmt_coef <- function(b, se, digits = 4) {
  pval <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pval < 0.01, "***",
           ifelse(pval < 0.05, "**",
           ifelse(pval < 0.10, "*", "")))
  sprintf("%.*f%s", digits, b, stars)
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

# Compute summary stats for low-edu women
vars <- c("share_62", "share_72", "share_4445", "share_56", "share_3133",
          "earn_62", "earn_72", "earn_4445", "total_emp")
labels <- c("Healthcare share", "Food services share", "Retail share",
            "Admin services share", "Manufacturing share",
            "Healthcare earnings (\\$)", "Food services earnings (\\$)",
            "Retail earnings (\\$)", "Total employment")

stats_rows <- lapply(seq_along(vars), function(i) {
  x <- panel[[vars[i]]]
  x <- x[is.finite(x) & !is.na(x)]
  data.frame(
    Variable = labels[i],
    Mean = mean(x),
    SD = sd(x),
    Min = min(x),
    Max = max(x),
    N = length(x)
  )
})
stats_df <- do.call(rbind, stats_rows)

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Low-Education Women's Employment}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & Mean & Std.\\ Dev. & Min & Max & N \\\\",
  "\\midrule"
)

for (i in 1:nrow(stats_df)) {
  row <- stats_df[i, ]
  if (i <= 5) {
    # Shares: show as proportions
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f & %s \\\\",
      row$Variable, row$Mean, row$SD, row$Min, row$Max,
      format(row$N, big.mark = ",")))
  } else if (i <= 8) {
    # Earnings: show as dollars
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %s & %s & %s & %s & %s \\\\",
      row$Variable,
      format(round(row$Mean), big.mark = ","),
      format(round(row$SD), big.mark = ","),
      format(round(row$Min), big.mark = ","),
      format(round(row$Max), big.mark = ","),
      format(row$N, big.mark = ",")))
  } else {
    # Employment: show as thousands
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %s & %s & %s & %s & %s \\\\",
      row$Variable,
      format(round(row$Mean), big.mark = ","),
      format(round(row$SD), big.mark = ","),
      format(round(row$Min), big.mark = ","),
      format(round(row$Max), big.mark = ","),
      format(row$N, big.mark = ",")))
  }
}

n_treated <- length(unique(panel$statefip[panel$eitc_adopt_year > 0]))
n_never <- length(unique(panel$statefip[panel$eitc_adopt_year == 0]))

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: State$\\times$year panel of low-education (less than high school and high school/GED) women's employment, 2001--2023. Industry shares computed as sector employment divided by total state employment for the demographic group. Earnings are average monthly earnings of stable workers. Data from Census QWI (Quarterly Workforce Indicators) on Azure. N = %s state-year observations. %d states adopted state EITCs; %d states never adopted.",
          format(nrow(panel), big.mark = ","), n_treated, n_never),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Results — CS-DiD and TWFE
# ============================================================
cat("Generating Table 2: Main DiD Results...\n")

# Get CS-DiD results
cs_b_health <- cs_results$health$att
cs_se_health <- cs_results$health$se
cs_b_food <- cs_results$food$att
cs_se_food <- cs_results$food$se
cs_b_retail <- cs_results$retail$att
cs_se_retail <- cs_results$retail$se
cs_b_emp <- cs_results$emp$att
cs_se_emp <- cs_results$emp$se

# Get TWFE results
tw_b_health <- coef(twfe_health)["treated"]
tw_se_health <- se(twfe_health)["treated"]
tw_b_food <- coef(twfe_food)["treated"]
tw_se_food <- se(twfe_food)["treated"]
tw_b_retail <- coef(twfe_retail)["treated"]
tw_se_retail <- se(twfe_retail)["treated"]
tw_b_emp <- coef(twfe_emp)["treated"]
tw_se_emp <- se(twfe_emp)["treated"]

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of State EITC on Low-Education Women's Industry Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Healthcare & Food Services & Retail & Log Total \\\\",
  "& Share & Share & Share & Employment \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna (2021)}} \\\\[3pt]",
  sprintf("State EITC & %s & %s & %s & %s \\\\",
          fmt_coef(cs_b_health, cs_se_health),
          fmt_coef(cs_b_food, cs_se_food),
          fmt_coef(cs_b_retail, cs_se_retail),
          fmt_coef(cs_b_emp, cs_se_emp)),
  sprintf("& (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          cs_se_health, cs_se_food, cs_se_retail, cs_se_emp),
  "\\multicolumn{5}{l}{\\textit{Panel B: Two-Way Fixed Effects}} \\\\[3pt]",
  sprintf("State EITC & %s & %s & %s & %s \\\\",
          fmt_coef(tw_b_health, tw_se_health),
          fmt_coef(tw_b_food, tw_se_food),
          fmt_coef(tw_b_retail, tw_se_retail),
          fmt_coef(tw_b_emp, tw_se_emp)),
  sprintf("& (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          tw_se_health, tw_se_food, tw_se_retail, tw_se_emp),
  "\\midrule",
  sprintf("State, Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("States & %d & %d & %d & %d \\\\",
          length(unique(panel$statefip[!is.na(panel$share_62)])),
          length(unique(panel$statefip[!is.na(panel$share_72)])),
          length(unique(panel$statefip[!is.na(panel$share_4445)])),
          length(unique(panel$statefip))),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(sum(!is.na(panel$share_62)), big.mark = ","),
          format(sum(!is.na(panel$share_72)), big.mark = ","),
          format(sum(!is.na(panel$share_4445)), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  sprintf("Dep.\\ var.\\ mean & %.3f & %.3f & %.3f & %.2f \\\\",
          mean(panel$share_62, na.rm = TRUE),
          mean(panel$share_72, na.rm = TRUE),
          mean(panel$share_4445, na.rm = TRUE),
          mean(panel$log_total_emp, na.rm = TRUE)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Panel A reports the simple aggregate ATT from the Callaway--Sant'Anna (2021) estimator with bootstrap inference (1,000 iterations) and ``never treated'' control group. Panel B reports two-way fixed effects estimates. The sample is a balanced panel of U.S.\\ states, 2001--2023. The dependent variable is the share of low-education (less than HS plus HS/GED) women's employment in the indicated sector. Column (4) uses log total employment of low-education women. Treatment is an indicator for state having adopted a state-level EITC supplement.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("Generating Table 3: Event Study...\n")

es_h <- es_results$health
es_f <- es_results$food

# Merge
es_merge <- merge(es_h, es_f, by = "event_time", suffixes = c("_h", "_f"), all = TRUE)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of State EITC on Industry Shares}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{rcccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{Healthcare Share} & \\multicolumn{2}{c}{Food Services Share} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Event Time & ATT & SE & ATT & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_merge)) {
  et <- es_merge$event_time[i]
  # Reference period (t=-1): show as "(reference)" instead of NA
  if (et == -1) {
    tab3_lines <- c(tab3_lines,
      "-1 & \\multicolumn{2}{c}{\\textit{(reference)}} & \\multicolumn{2}{c}{\\textit{(reference)}} \\\\")
  } else {
    tab3_lines <- c(tab3_lines, sprintf(
      "%d & %s & (%.4f) & %s & (%.4f) \\\\",
      et,
      ifelse(is.na(es_merge$att_h[i]), "---",
             fmt_coef(es_merge$att_h[i], es_merge$se_h[i])),
      ifelse(is.na(es_merge$se_h[i]), 0, es_merge$se_h[i]),
      ifelse(is.na(es_merge$att_f[i]), "---",
             fmt_coef(es_merge$att_f[i], es_merge$se_f[i])),
      ifelse(is.na(es_merge$se_f[i]), 0, es_merge$se_f[i])
    ))
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Callaway--Sant'Anna (2021) group-time ATTs aggregated to event time, with bootstrap standard errors (1,000 iterations). Event time 0 is the year of state EITC adoption. Pre-treatment coefficients (negative event times) test the parallel trends assumption. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ============================================================
# TABLE 4: Mechanisms — Triple-diff + Dose-response + Placebo
# ============================================================
cat("Generating Table 4: Mechanisms...\n")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanisms: Triple-Difference, Dose-Response, and Placebo Tests}",
  "\\label{tab:mechanisms}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& \\multicolumn{2}{c}{Healthcare} & \\multicolumn{2}{c}{Food Services} \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Triple-difference (low vs.\\ high education women)}} \\\\[3pt]",
  sprintf("EITC $\\times$ Low education & %s & & %s & \\\\",
          fmt_coef(coef(triple_health)["treated_low"], se(triple_health)["treated_low"]),
          fmt_coef(coef(triple_food)["treated_low"], se(triple_food)["treated_low"])),
  sprintf("& (%.4f) & & (%.4f) & \\\\[6pt]",
          se(triple_health)["treated_low"],
          se(triple_food)["treated_low"]),
  "\\multicolumn{5}{l}{\\textit{Panel B: Dose-response (EITC credit \\%)}} \\\\[3pt]",
  sprintf("EITC credit \\%% & & %s & & %s \\\\",
          fmt_coef(coef(dose_health)["eitc_intensity"], se(dose_health)["eitc_intensity"]),
          fmt_coef(coef(dose_food)["eitc_intensity"], se(dose_food)["eitc_intensity"])),
  sprintf("& & (%.5f) & & (%.5f) \\\\[6pt]",
          se(dose_health)["eitc_intensity"],
          se(dose_food)["eitc_intensity"]),
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo --- low-education men}} \\\\[3pt]",
  sprintf("State EITC & %s & & %s & \\\\",
          fmt_coef(coef(placebo_health)["treated"], se(placebo_health)["treated"]),
          fmt_coef(coef(placebo_food)["treated"], se(placebo_food)["treated"])),
  sprintf("& (%.4f) & & (%.4f) & \\\\",
          se(placebo_health)["treated"],
          se(placebo_food)["treated"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Panel A reports the triple-difference coefficient (EITC $\\times$ low education) from a model with state$\\times$education and year$\\times$education fixed effects, comparing low-education (E1+E2) to high-education (E4+E5) women. Panel B uses continuous EITC generosity (credit as \\% of federal EITC) instead of the binary adoption indicator. Panel C replaces the sample with low-education men as a placebo group.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab4_lines, "../tables/tab4_mechanisms.tex")

# ============================================================
# TABLE 5: Robustness
# ============================================================
cat("Generating Table 5: Robustness...\n")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Samples and Specifications}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "& Healthcare Share & Food Services Share \\\\",
  "\\midrule",
  sprintf("Baseline TWFE & %s & %s \\\\",
          fmt_coef(coef(twfe_health)["treated"], se(twfe_health)["treated"]),
          fmt_coef(coef(twfe_food)["treated"], se(twfe_food)["treated"])),
  sprintf("& (%.4f) & (%.4f) \\\\[3pt]",
          se(twfe_health)["treated"], se(twfe_food)["treated"]),
  sprintf("Post-2001 adopters only & %s & %s \\\\",
          fmt_coef(coef(twfe_post_health)["treated"], se(twfe_post_health)["treated"]),
          fmt_coef(coef(twfe_post_food)["treated"], se(twfe_post_food)["treated"])),
  sprintf("& (%.4f) & (%.4f) \\\\[3pt]",
          se(twfe_post_health)["treated"], se(twfe_post_food)["treated"]),
  sprintf("Excl.\\ recession (2008--2010) & %s & %s \\\\",
          fmt_coef(coef(twfe_norec_health)["treated"], se(twfe_norec_health)["treated"]),
          fmt_coef(coef(twfe_norec_food)["treated"], se(twfe_norec_food)["treated"])),
  sprintf("& (%.4f) & (%.4f) \\\\[3pt]",
          se(twfe_norec_health)["treated"], se(twfe_norec_food)["treated"]),
  sprintf("Refundable EITCs & %s & %s \\\\",
          fmt_coef(coef(refund_health)["treated_refundable"], se(refund_health)["treated_refundable"]),
          fmt_coef(coef(refund_food)["treated_refundable"], se(refund_food)["treated_refundable"])),
  sprintf("& (%.4f) & (%.4f) \\\\[3pt]",
          se(refund_health)["treated_refundable"], se(refund_food)["treated_refundable"]),
  sprintf("Non-refundable EITCs & %s & %s \\\\",
          fmt_coef(coef(refund_health)["treated_nonrefund"], se(refund_health)["treated_nonrefund"]),
          fmt_coef(coef(refund_food)["treated_nonrefund"], se(refund_food)["treated_nonrefund"])),
  sprintf("& (%.4f) & (%.4f) \\\\[3pt]",
          se(refund_health)["treated_nonrefund"], se(refund_food)["treated_nonrefund"]),
  sprintf("Manufacturing (placebo) & %s & \\\\",
          fmt_coef(coef(twfe_mfg)["treated"], se(twfe_mfg)["treated"])),
  sprintf("& (%.4f) & \\\\",
          se(twfe_mfg)["treated"]),
  "\\midrule",
  "State, Year FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each row reports the coefficient on the EITC treatment indicator from a separate TWFE regression. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ``Post-2001 only'' restricts to states adopting EITCs after 2001 plus never-treated states. ``Excl.\\ recession'' drops 2008--2010. ``Refundable/Non-refundable'' estimates separate coefficients by EITC type. ``Manufacturing'' tests whether the EITC affects a non-service sector (placebo).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab5_lines, "../tables/tab5_robustness.tex")

# ============================================================
# TABLE F1: Standardized Effect Sizes
# ============================================================
cat("Generating SDE Table...\n")

# Compute SDE for main outcomes
sde_rows <- list()

# Healthcare share
b_h <- cs_results$health$att
se_h <- cs_results$health$se
sd_y_h <- sd(panel$share_62, na.rm = TRUE)
sde_h <- b_h / sd_y_h
se_sde_h <- se_h / sd_y_h

# Food services share
b_f <- cs_results$food$att
se_f <- cs_results$food$se
sd_y_f <- sd(panel$share_72, na.rm = TRUE)
sde_f <- b_f / sd_y_f
se_sde_f <- se_f / sd_y_f

# Retail share
b_r <- cs_results$retail$att
se_r <- cs_results$retail$se
sd_y_r <- sd(panel$share_4445, na.rm = TRUE)
sde_r <- b_r / sd_y_r
se_sde_r <- se_r / sd_y_r

# Log employment
b_e <- cs_results$emp$att
se_e <- cs_results$emp$se
sd_y_e <- sd(panel$log_total_emp, na.rm = TRUE)
sde_e <- b_e / sd_y_e
se_sde_e <- se_e / sd_y_e

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

sde_tab <- data.frame(
  Outcome = c("Healthcare share", "Food services share", "Retail share", "Log total employment"),
  beta = c(b_h, b_f, b_r, b_e),
  SE = c(se_h, se_f, se_r, se_e),
  SD_Y = c(sd_y_h, sd_y_f, sd_y_r, sd_y_e),
  SDE = c(sde_h, sde_f, sde_r, sde_e),
  SE_SDE = c(se_sde_h, se_sde_f, se_sde_r, se_sde_e),
  Classification = classify(c(sde_h, sde_f, sde_r, sde_e))
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_tab)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    sde_tab$Outcome[i], sde_tab$beta[i], sde_tab$SE[i],
    sde_tab$SD_Y[i], sde_tab$SDE[i], sde_tab$SE_SDE[i],
    sde_tab$Classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatment, SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) is the unconditional standard deviation of the outcome variable from Table~\\ref{tab:summary}.",
  "",
  sprintf("\\textbf{Research question:} Does state EITC adoption change the industry composition of low-education women's employment? \\textbf{Treatment:} Binary --- state adopted a state-level EITC supplement. \\textbf{Data:} Census QWI, 2001--2023, state$\\times$year panel. \\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with ``never treated'' control group, state-clustered SEs. \\textbf{Sample:} %d state-year observations across %d states.",
          nrow(panel), length(unique(panel$statefip))),
  "",
  "Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}")

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files in tables/:\n")
cat(paste("  ", list.files("../tables/"), collapse = "\n"), "\n")
