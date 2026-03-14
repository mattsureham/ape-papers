## ============================================================
## 05_tables.R — Generate all LaTeX tables
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/main_results.RData")
load("../data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE)

## ============================
## Table 1: Summary Statistics
## ============================

cat("\n=== Table 1: Summary Statistics ===\n")

summ_data <- analysis_df |>
  filter(year >= 2003, year <= 2022, !is.na(bachelors_total)) |>
  mutate(group = ifelse(pbf_treated, "PBF States", "Non-PBF States"))

## Summary by group
summ_tab <- summ_data |>
  group_by(group) |>
  summarise(
    `Bachelor's Completions` = sprintf("%.0f (%.0f)", mean(bachelors_total, na.rm = TRUE),
                                        sd(bachelors_total, na.rm = TRUE)),
    `6-Year Graduation Rate (\\%)` = sprintf("%.1f (%.1f)", mean(grad_rate_150, na.rm = TRUE),
                                              sd(grad_rate_150, na.rm = TRUE)),
    `Fall Enrollment` = sprintf("%.0f (%.0f)", mean(enroll_total, na.rm = TRUE),
                                 sd(enroll_total, na.rm = TRUE)),
    `Minority Share (\\%)` = sprintf("%.1f (%.1f)", mean(pct_minority, na.rm = TRUE),
                                     sd(pct_minority, na.rm = TRUE)),
    `Black Share (\\%)` = sprintf("%.1f (%.1f)", mean(pct_black, na.rm = TRUE),
                                  sd(pct_black, na.rm = TRUE)),
    Institutions = as.character(n_distinct(unitid)),
    `Inst-Years` = format(n(), big.mark = ","),
    .groups = "drop"
  ) |>
  t()

## Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Public Four-Year Institutions}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & PBF States & Non-PBF States \\\\\n")
cat("\\midrule\n")
for (i in 2:nrow(summ_tab)) {
  cat(rownames(summ_tab)[i], " & ", summ_tab[i, 1], " & ", summ_tab[i, 2], " \\\\\n")
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Means with standard deviations in parentheses. ")
cat("Sample covers public four-year institutions from IPEDS, 2003--2022. ")
cat("PBF states adopted performance-based funding 2.0 formulas between 2009 and 2019. ")
cat("Graduation rate is the 150\\% time (6-year) rate for first-time, full-time bachelor's cohorts. ")
cat("Minority share is the percentage of fall enrollment that is Black or Hispanic.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written.\n")

## ============================
## Table 2: Main Results
## ============================

cat("\n=== Table 2: Main DiD Results ===\n")

## Extract CS-DiD ATTs
cs_results <- data.frame(
  outcome = c("Log Completions", "Graduation Rate", "Log Enrollment"),
  cs_att = c(agg_comp$overall.att,
             ifelse(is.null(agg_gr) || is.na(agg_gr$overall.att), NA, agg_gr$overall.att),
             agg_enroll$overall.att),
  cs_se = c(agg_comp$overall.se,
            ifelse(is.null(agg_gr) || is.na(agg_gr$overall.se), NA, agg_gr$overall.se),
            agg_enroll$overall.se)
)

## Stars function
stars <- function(beta, se) {
  if (is.na(beta) | is.na(se)) return("")
  p <- 2 * pnorm(-abs(beta / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

sink("../tables/tab2_main.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of Performance-Based Funding on Higher Education Outcomes}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & Log Bach. & Grad. & Log Fall & Minority & Black \\\\\n")
cat(" & Compl. & Rate & Enroll. & Share & Share \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: TWFE}} \\\\\n")
cat("PBF Adopted")
for (reg in list(reg_comp, reg_gr, reg_enroll, reg_minority, reg_black)) {
  b <- coef(reg)["treated"]
  s <- se(reg)["treated"]
  st <- stars(b, s)
  cat(sprintf(" & %.4f%s", b, st))
}
cat(" \\\\\n")
cat(" ")
for (reg in list(reg_comp, reg_gr, reg_enroll, reg_minority, reg_black)) {
  s <- se(reg)["treated"]
  cat(sprintf(" & (%.4f)", s))
}
cat(" \\\\\n")

## CS-DiD panel
cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Callaway-Sant'Anna}} \\\\\n")
cat(sprintf("ATT & %.4f%s", agg_comp$overall.att, stars(agg_comp$overall.att, agg_comp$overall.se)))
if (!is.null(agg_gr) && !is.na(agg_gr$overall.att)) {
  cat(sprintf(" & %.4f%s", agg_gr$overall.att, stars(agg_gr$overall.att, agg_gr$overall.se)))
} else {
  cat(" & ---")
}
cat(sprintf(" & %.4f%s", agg_enroll$overall.att, stars(agg_enroll$overall.att, agg_enroll$overall.se)))
cat(sprintf(" & %.4f%s", agg_minority$overall.att, stars(agg_minority$overall.att, agg_minority$overall.se)))
cat(" & --- \\\\\n")

cat(" ")
cat(sprintf(" & (%.4f)", agg_comp$overall.se))
if (!is.null(agg_gr) && !is.na(agg_gr$overall.se)) {
  cat(sprintf(" & (%.4f)", agg_gr$overall.se))
} else {
  cat(" & ")
}
cat(sprintf(" & (%.4f)", agg_enroll$overall.se))
cat(sprintf(" & (%.4f)", agg_minority$overall.se))
cat(" & \\\\\n")

cat("\\addlinespace\n")
cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
            format(nobs(reg_comp), big.mark = ","),
            format(nobs(reg_gr), big.mark = ","),
            format(nobs(reg_enroll), big.mark = ","),
            format(nobs(reg_minority), big.mark = ","),
            format(nobs(reg_black), big.mark = ",")))

n_cl <- length(unique(twfe_data$state[!is.na(twfe_data$ln_bachelors)]))
cat(sprintf("Clusters (states) & %d & %d & %d & %d & %d \\\\\n",
            n_cl, n_cl, n_cl, n_cl, n_cl))
cat("Institution FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ")
cat("Panel A reports two-way fixed effects estimates. ")
cat("Panel B reports Callaway and Sant'Anna (2021) doubly robust ATT estimates using never-treated states as the control group. ")
cat("Sample: public four-year institutions with at least 50 bachelor's completions, 2003--2022. ")
cat("Graduation rate is the 6-year (150\\% time) rate for first-time, full-time bachelor's cohorts. ")
cat("Minority share = (Black + Hispanic) / total fall enrollment $\\times$ 100.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written.\n")

## ============================
## Table 3: Cream-Skimming Decomposition
## ============================

cat("\n=== Table 3: Cream-Skimming ===\n")

## Run regressions for Black completions share and Hispanic completions share
twfe_data2 <- twfe_data |>
  mutate(
    pct_bach_black = ifelse(bachelors_total > 0,
                            bachelors_black / bachelors_total * 100, NA),
    pct_bach_hisp = ifelse(bachelors_total > 0,
                           bachelors_hispanic / bachelors_total * 100, NA),
    pct_bach_white = ifelse(bachelors_total > 0,
                            bachelors_white / bachelors_total * 100, NA)
  )

reg_pct_bach_black <- feols(pct_bach_black ~ treated | unitid + year,
                            data = twfe_data2, cluster = ~state)
reg_pct_bach_hisp <- feols(pct_bach_hisp ~ treated | unitid + year,
                           data = twfe_data2, cluster = ~state)
reg_enroll_black <- feols(pct_black ~ treated | unitid + year,
                          data = twfe_data2, cluster = ~state)
reg_enroll_hisp <- feols(pct_hispanic ~ treated | unitid + year,
                         data = twfe_data2, cluster = ~state)

sink("../tables/tab3_cream_skimming.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Cream-Skimming Test: Enrollment and Completion Composition}\n")
cat("\\label{tab:cream}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & \\% Black & \\% Hispanic & \\% Black & \\% Hispanic \\\\\n")
cat(" & Enrolled & Enrolled & Completing & Completing \\\\\n")
cat("\\midrule\n")
cat("PBF Adopted")
for (reg in list(reg_enroll_black, reg_enroll_hisp, reg_pct_bach_black, reg_pct_bach_hisp)) {
  b <- coef(reg)["treated"]
  s <- se(reg)["treated"]
  st <- stars(b, s)
  cat(sprintf(" & %.3f%s", b, st))
}
cat(" \\\\\n")
cat(" ")
for (reg in list(reg_enroll_black, reg_enroll_hisp, reg_pct_bach_black, reg_pct_bach_hisp)) {
  s <- se(reg)["treated"]
  cat(sprintf(" & (%.3f)", s))
}
cat(" \\\\\n")
cat("\\addlinespace\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(reg_enroll_black), big.mark = ","),
            format(nobs(reg_enroll_hisp), big.mark = ","),
            format(nobs(reg_pct_bach_black), big.mark = ","),
            format(nobs(reg_pct_bach_hisp), big.mark = ",")))
cat("Institution FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ")
cat("Columns (1)--(2) report effects on the share of fall enrollment that is Black or Hispanic. ")
cat("Columns (3)--(4) report effects on the share of bachelor's completions awarded to Black or Hispanic students. ")
cat("If PBF induces cream-skimming, both enrollment and completion shares for disadvantaged groups should decline. ")
cat("Sample: public four-year institutions, 2003--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written.\n")

## ============================
## Table 4: Robustness
## ============================

cat("\n=== Table 4: Robustness ===\n")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & Baseline & Private & DDD & Late & High & Low \\\\\n")
cat(" & Public & Placebo & Within-State & Adopters & Dose & Dose \\\\\n")
cat("\\midrule\n")

## Row: coefficient
cat("PBF Effect")
b1 <- coef(reg_comp)["treated"]; s1 <- se(reg_comp)["treated"]
b2 <- coef(placebo_comp)["treated"]; s2 <- se(placebo_comp)["treated"]
b3 <- coef(ddd_comp)["ddd_treat"]; s3 <- se(ddd_comp)["ddd_treat"]
b4 <- coef(reg_late_comp)["treated"]; s4 <- se(reg_late_comp)["treated"]
b5 <- coef(reg_hilo)["pbf_high"]; s5 <- se(reg_hilo)["pbf_high"]
b6 <- coef(reg_hilo)["pbf_low"]; s6 <- se(reg_hilo)["pbf_low"]

for (i in 1:6) {
  b <- c(b1, b2, b3, b4, b5, b6)[i]
  s <- c(s1, s2, s3, s4, s5, s6)[i]
  st <- stars(b, s)
  cat(sprintf(" & %.4f%s", b, st))
}
cat(" \\\\\n")

cat(" ")
for (s in c(s1, s2, s3, s4, s5, s6)) {
  cat(sprintf(" & (%.4f)", s))
}
cat(" \\\\\n")

cat("\\addlinespace\n")
cat(sprintf("N & %s & %s & %s & %s & %s & %s \\\\\n",
            format(nobs(reg_comp), big.mark = ","),
            format(nobs(placebo_comp), big.mark = ","),
            format(nobs(ddd_comp), big.mark = ","),
            format(nobs(reg_late_comp), big.mark = ","),
            format(nobs(reg_hilo), big.mark = ","),
            format(nobs(reg_hilo), big.mark = ",")))
cat("Sample & Public & Private & PBF States & Post-2011 & Public & Public \\\\\n")
cat("Outcome & Log Comp. & Log Comp. & Log Comp. & Log Comp. & Log Comp. & Log Comp. \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ")
cat("* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ")
cat("All specifications include institution and year fixed effects. ")
cat("Column (1): baseline TWFE on public 4-year institutions. ")
cat("Column (2): placebo test on private 4-year institutions (should not respond to PBF). ")
cat("Column (3): triple difference --- public vs.\\ private within PBF states. ")
cat("Column (4): restricts to states adopting PBF from 2012 onward. ")
cat("Columns (5)--(6): dose-response --- high dose ($\\geq 20$\\% of funding) vs.\\ low dose ($<20$\\%). ")
cat("Outcome is log bachelor's completions in all columns.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written.\n")

## ============================
## Table F1: Standardized Effect Sizes (SDE)
## ============================

cat("\n=== SDE Table ===\n")

## Compute SDEs from TWFE main results
sd_comp <- sd(twfe_data$ln_bachelors, na.rm = TRUE)
sd_gr <- sd(twfe_data$grad_rate_150, na.rm = TRUE)
sd_enroll <- sd(twfe_data$ln_enroll, na.rm = TRUE)
sd_minority <- sd(twfe_data$pct_minority, na.rm = TRUE)
sd_black <- sd(twfe_data$pct_black, na.rm = TRUE)

sde_rows <- list(
  list("Log Completions", "TWFE",
       coef(reg_comp)["treated"], se(reg_comp)["treated"], sd_comp),
  list("Graduation Rate", "TWFE",
       coef(reg_gr)["treated"], se(reg_gr)["treated"], sd_gr),
  list("Log Enrollment", "TWFE",
       coef(reg_enroll)["treated"], se(reg_enroll)["treated"], sd_enroll),
  list("Minority Share", "TWFE",
       coef(reg_minority)["treated"], se(reg_minority)["treated"], sd_minority),
  list("Black Share", "TWFE",
       coef(reg_black)["treated"], se(reg_black)["treated"], sd_black)
)

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

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{llcccccc}\n")
cat("\\toprule\n")
cat("Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
for (row in sde_rows) {
  b <- row[[3]]; s <- row[[4]]; sdy <- row[[5]]
  sde <- b / sdy
  se_sde <- s / sdy
  cl <- classify_sde(sde)
  cat(sprintf("%s & %s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              row[[1]], row[[2]], b, s, sdy, sde, se_sde, cl))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)\n")
cat("to facilitate cross-study comparison of treatment effect magnitudes.\n")
cat("Treatment is binary (0/1): PBF adopted in institution's state.\n")
cat("SDE $= \\hat{\\beta} / \\text{SD}(Y)$; SD($X$) column omitted for binary treatment.\n")
cat("SD($Y$) is the unconditional standard deviation from the full sample.\n\n")
cat("\\textbf{Research question:} Does performance-based funding for public universities\n")
cat("affect degree completions, graduation rates, and enrollment composition?\n")
cat("\\textbf{Treatment:} Binary --- state adoption of PBF 2.0 formula (25 states, 2009--2019).\n")
cat("\\textbf{Data:} IPEDS, 2003--2022, public four-year institutions.\n")
cat("\\textbf{Method:} Staggered DiD with TWFE (institution and year fixed effects), state-clustered SEs.\n")
cat("\\textbf{Sample:} Public four-year institutions with $\\geq 50$ bachelor's completions.\n\n")
cat("Classification thresholds:\n")
cat("large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),\n")
cat("small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),\n")
cat("small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),\n")
cat("large positive ($> 0.15$).\n")
cat("Classification labels refer to the magnitude of the standardized point estimate,\n")
cat("not to statistical significance. ``Null'' denotes a near-zero effect size\n")
cat("($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n")
cat("\\end{table}\n")
sink()
cat("SDE table written.\n")

## Save table-related objects
save(twfe_data2, reg_pct_bach_black, reg_pct_bach_hisp,
     reg_enroll_black, reg_enroll_hisp,
     file = "../data/table_objects.RData")
cat("\nAll tables generated.\n")
