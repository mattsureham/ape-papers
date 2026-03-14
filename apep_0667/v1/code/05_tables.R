## 05_tables.R — Generate all tables
## apep_0667: EBT rollout and drug-market disruption

source("00_packages.R")

cat("=== Loading results ===\n")
panel      <- readRDS("../data/panel.rds")
results    <- readRDS("../data/results_main.rds")
robustness <- readRDS("../data/results_robustness.rds")

# Ensure tables directory exists
dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# --- Helper functions ---
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
make_stars <- function(b, s) {
  t <- abs(b / s)
  if (t > 2.576) "***" else if (t > 1.96) "**" else if (t > 1.645) "*" else ""
}

panel_main <- results$panel_main

# ===================================================================
cat("\n=== Table 1: Summary Statistics ===\n")
# ===================================================================
# Compare pre-treatment vs post-treatment periods
# Since all states are eventually treated, partition by treated status at each year

pre_obs  <- panel_main %>% filter(treated == 0)
post_obs <- panel_main %>% filter(treated == 1)

summ_var <- function(df, var, label) {
  x <- df[[var]]
  x <- x[!is.na(x)]
  c(label, fmt_int(length(x)), fmt(mean(x), 2), fmt(sd(x), 2),
    fmt(min(x), 2), fmt(max(x), 2))
}

# Build summary rows for each variable and partition
vars_info <- list(
  list(var = "drug_death_rate", label = "Drug death rate"),
  list(var = "drug_deaths",     label = "Drug deaths (count)"),
  list(var = "suicide_rate",    label = "Suicide rate"),
  list(var = "injury_rate",     label = "Unintentional injury rate"),
  list(var = "heart_rate",      label = "Heart disease rate")
)

tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics: Drug Poisoning Mortality and Placebo Outcomes}",
  "\\label{tab:summary}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "& N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Not-Yet-Treated State-Years}} \\\\"
)

for (vi in vars_info) {
  row <- summ_var(pre_obs, vi$var, vi$label)
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                          row[1], row[2], row[3], row[4], row[5], row[6]))
}

tab1 <- c(tab1, "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-EBT State-Years}} \\\\"
)

for (vi in vars_info) {
  row <- summ_var(post_obs, vi$var, vi$label)
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                          row[1], row[2], row[3], row[4], row[5], row[6]))
}

tab1 <- c(tab1, "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel C: Full Sample}} \\\\"
)

for (vi in vars_info) {
  row <- summ_var(panel_main, vi$var, vi$label)
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                          row[1], row[2], row[3], row[4], row[5], row[6]))
}

n_cohorts <- n_distinct(panel_main$ebt_year)
tab1 <- c(tab1,
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  sprintf("\\item \\textit{Notes:} All rates are age-adjusted per 100,000. Panel spans 1999--2010 across %d states/DC with %d EBT adoption cohorts (1998--2004). Not-yet-treated state-years are those where EBT had not yet been implemented; post-EBT state-years follow implementation. All states eventually adopted EBT.",
          n_distinct(panel_main$state_abbr), n_cohorts),
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Written tab1_summary.tex\n")

# ===================================================================
cat("\n=== Table 2: Main Results ===\n")
# ===================================================================
# Col 1: CS-DiD overall ATT
# Col 2: TWFE
# Col 3: TWFE with state trends
# Col 4: Log-deaths specification

cs_att <- results$cs_overall$overall.att
cs_se  <- results$cs_overall$overall.se
cs_n   <- nrow(panel_main)

twfe <- results$twfe_main
b_twfe <- coef(twfe)["treated"]
s_twfe <- se(twfe)["treated"]

b_trends <- coef(robustness$twfe_trends)["treated"]
s_trends <- se(robustness$twfe_trends)["treated"]

b_counts <- coef(robustness$twfe_counts)["treated"]
s_counts <- se(robustness$twfe_counts)["treated"]

n_clusters <- n_distinct(panel_main$state_id)

# Confidence intervals
ci <- function(b, s) sprintf("[%s, %s]", fmt(b - 1.96*s), fmt(b + 1.96*s))

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of EBT Implementation on Drug Poisoning Mortality}",
  "\\label{tab:main}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& (1) CS-DiD & (2) TWFE & (3) TWFE+Trends & (4) Log Deaths \\\\",
  "\\midrule",
  sprintf("EBT Implemented & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(cs_att), make_stars(cs_att, cs_se),
    fmt(b_twfe), make_stars(b_twfe, s_twfe),
    fmt(b_trends), make_stars(b_trends, s_trends),
    fmt(b_counts), make_stars(b_counts, s_counts)),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(cs_se), fmt(s_twfe), fmt(s_trends), fmt(s_counts)),
  sprintf("95\\%% CI & %s & %s & %s & %s \\\\",
    ci(cs_att, cs_se), ci(b_twfe, s_twfe),
    ci(b_trends, s_trends), ci(b_counts, s_counts)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    fmt_int(cs_n), fmt_int(nobs(twfe)),
    fmt_int(nobs(robustness$twfe_trends)),
    fmt_int(nobs(robustness$twfe_counts))),
  sprintf("Clusters (states) & %d & %d & %d & %d \\\\",
    n_clusters, n_clusters, n_clusters,
    n_distinct(panel_main$state_id[!is.na(panel_main$drug_deaths) &
                                    panel_main$drug_deaths > 0 &
                                    !is.na(panel_main$pop_fred) &
                                    panel_main$pop_fred > 0])),
  "Estimator & CS-DiD & TWFE & TWFE & TWFE \\\\",
  "Control group & Not-yet-treated & --- & --- & --- \\\\",
  "State + Year FE & Yes & Yes & Yes & Yes \\\\",
  "State trends & No & No & Yes & No \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  sprintf("\\item \\textit{Notes:} Dependent variable: age-adjusted drug poisoning death rate per 100,000 (cols 1--3); log drug deaths with log population offset (col 4). Col (1): Callaway and Sant'Anna (2021) with not-yet-treated control group, doubly robust estimator, and bootstrapped SEs. Cols (2)--(4): two-way fixed effects with SEs clustered at state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. N = %d states, 1999--2010. All states adopted EBT between 1998 and 2004.",
    n_distinct(panel_main$state_abbr)),
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")
cat("  Written tab2_main.tex\n")

# ===================================================================
cat("\n=== Table 3: Placebo Tests ===\n")
# ===================================================================
# Show CS-DiD and TWFE on suicide, injury, heart disease rates

placebo <- robustness$placebo

# Collect estimates
placebo_rows <- list()
for (yvar in c("suicide_rate", "injury_rate", "heart_rate")) {
  if (!is.null(placebo[[yvar]])) {
    p <- placebo[[yvar]]
    placebo_rows[[yvar]] <- list(
      label    = p$label,
      cs_att   = ifelse(is.na(p$cs_att), NA, p$cs_att),
      cs_se    = ifelse(is.na(p$cs_se), NA, p$cs_se),
      twfe_b   = coef(p$twfe)["treated"],
      twfe_se  = se(p$twfe)["treated"],
      n_obs    = p$n_obs
    )
  }
}

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Placebo Tests: Effect of EBT on Non-Drug Mortality}",
  "\\label{tab:placebo}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "& \\multicolumn{2}{c}{CS-DiD} & \\multicolumn{2}{c}{TWFE} & N & Clusters \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Outcome & ATT & SE & $\\hat{\\beta}$ & SE & & \\\\"
)

if (length(placebo_rows) > 0) {
  tab3 <- c(tab3, "\\midrule")
  for (pr in placebo_rows) {
    cs_cell <- if (is.na(pr$cs_att)) "---" else paste0(fmt(pr$cs_att), make_stars(pr$cs_att, pr$cs_se))
    cs_se_cell <- if (is.na(pr$cs_se)) "---" else paste0("(", fmt(pr$cs_se), ")")
    tab3 <- c(tab3, sprintf(
      "%s & %s & %s & %s%s & (%s) & %s & %d \\\\",
      pr$label,
      cs_cell, cs_se_cell,
      fmt(pr$twfe_b), make_stars(pr$twfe_b, pr$twfe_se), fmt(pr$twfe_se),
      fmt_int(pr$n_obs), n_clusters
    ))
  }

  # Add main result for comparison
  tab3 <- c(tab3, "\\midrule",
    sprintf(
      "Drug death rate & %s%s & (%s) & %s%s & (%s) & %s & %d \\\\",
      fmt(cs_att), make_stars(cs_att, cs_se), fmt(cs_se),
      fmt(b_twfe), make_stars(b_twfe, s_twfe), fmt(s_twfe),
      fmt_int(cs_n), n_clusters
    ))
} else {
  tab3 <- c(tab3, "\\midrule",
    "\\multicolumn{7}{c}{\\textit{No placebo outcomes available}} \\\\"
  )
}

tab3 <- c(tab3,
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  sprintf("\\item \\textit{Notes:} All rates are age-adjusted per 100,000. CS-DiD: Callaway and Sant'Anna (2021) with not-yet-treated controls. TWFE: state + year FE, SEs clustered at state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. The drug death rate row reproduces the main estimate from Table~\\ref{tab:main} for comparison. EBT should not affect suicide, unintentional injury, or heart disease mortality if the identification strategy is valid."),
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab3, "../tables/tab3_placebo.tex")
cat("  Written tab3_placebo.tex\n")

# ===================================================================
cat("\n=== Table 4: Robustness — Leave-One-Cohort-Out ===\n")
# ===================================================================
loco <- robustness$loco

tab4 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness: Leave-One-Cohort-Out Estimates}",
  "\\label{tab:robust}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}", "\\toprule",
  "Dropped Cohort & ATT & SE & 95\\% CI & States & Obs \\\\",
  "\\midrule"
)

# Full sample TWFE baseline
tab4 <- c(tab4, sprintf(
  "None (baseline) & %s%s & (%s) & %s & %d & %s \\\\",
  fmt(b_twfe), make_stars(b_twfe, s_twfe), fmt(s_twfe),
  ci(b_twfe, s_twfe), n_distinct(panel_main$state_abbr), fmt_int(nrow(panel_main))
))

if (length(loco) > 0) {
  tab4 <- c(tab4, "\\midrule")
  for (g in sort(names(loco))) {
    lr <- loco[[g]]
    tab4 <- c(tab4, sprintf(
      "%s & %s%s & (%s) & %s & %d & %s \\\\",
      g, fmt(lr$att), make_stars(lr$att, lr$se), fmt(lr$se),
      ci(lr$att, lr$se), lr$n_states, fmt_int(lr$n_obs)
    ))
  }
}

tab4 <- c(tab4,
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} Each row drops all states in the indicated EBT adoption cohort and re-estimates the TWFE specification with state and year fixed effects. SEs clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robustness.tex")
cat("  Written tab4_robustness.tex\n")

# ===================================================================
cat("\n=== Table F1: Standardized Effect Sizes (SDE) ===\n")
# ===================================================================
sd_y <- sd(panel_main$drug_death_rate, na.rm = TRUE)

sde_cs   <- cs_att / sd_y
se_sde_cs <- cs_se / sd_y
sde_twfe <- b_twfe / sd_y
se_sde_twfe <- s_twfe / sd_y

classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_lines <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{llcccccl}", "\\toprule",
  "Outcome & Estimator & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Drug death rate & CS-DiD & %s & %s & %s & %s & %s & %s \\\\",
    fmt(cs_att, 4), fmt(cs_se, 4), fmt(sd_y, 3),
    fmt(sde_cs, 4), fmt(se_sde_cs, 4), classify(sde_cs)),
  sprintf("Drug death rate & TWFE & %s & %s & %s & %s & %s & %s \\\\",
    fmt(b_twfe, 4), fmt(s_twfe, 4), fmt(sd_y, 3),
    fmt(sde_twfe, 4), fmt(se_sde_twfe, 4), classify(sde_twfe)),
  "\\bottomrule", "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} SDE = $\\hat{\\beta}$ / SD($Y$). Treatment is binary (EBT implemented in state). \\textbf{Research question:} Did EBT implementation reduce drug poisoning mortality by disrupting cash-based drug markets? \\textbf{Data:} CDC NCHS drug poisoning mortality, %d states, 1999--2010 (N = %s). \\textbf{Method:} Callaway--Sant'Anna staggered DiD and TWFE. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
    n_distinct(panel_main$state_abbr), fmt_int(nrow(panel_main))),
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables written ===\n")
