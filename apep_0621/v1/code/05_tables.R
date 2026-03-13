# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# APEP Working Paper apep_0621
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robust_results.rds")
summ_short <- readRDS("../data/summary_short.rds")
summ_long <- readRDS("../data/summary_long.rds")
state_long <- readRDS("../data/state_long_clean.rds")
state_changes <- readRDS("../data/state_changes.rds")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Combine short-run and long-run summaries
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Variable & Mean & Std.~Dev. & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Short-Run Panel (Children 8--14 in 1910)}} \\\\[3pt]"
)

for (i in 1:nrow(summ_short)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f \\\\",
    summ_short$Variable[i],
    summ_short$Mean[i], summ_short$SD[i],
    summ_short$Min[i], summ_short$Max[i]
  ))
}

tab1_lines <- c(tab1_lines,
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Long-Run Panel (Children 0--10 in 1920, Outcomes in 1940)}} \\\\[3pt]"
)

for (i in 1:nrow(summ_long)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.3f & %.3f & & \\\\",
    summ_long$Variable[i],
    summ_long$Mean[i], summ_long$SD[i]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Panel A: State-level aggregates from the IPUMS MLP ",
         "1910--1920 linked panel. N = ", length(unique(state_changes$statefip)),
         " states. Child labor rate = share of children aged 8--14 in the labor force. ",
         "School attendance = share attending school. Panel B: State-level aggregates ",
         "from the IPUMS MLP 1920--1930--1940 linked panel. N = ", nrow(state_long),
         " states. SEI = Duncan Socioeconomic Index. Occscore = occupational income ",
         "score. MP exposure = years between mothers' pension adoption and 1920."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Written tab1_summary.tex\n")

# =============================================================================
# Table 2: Main DiD Results — Short-Run Child Labor
# =============================================================================
cat("=== Table 2: Short-Run DiD ===\n")

# Extract coefficients
get_coef <- function(fit, param = NULL) {
  cf <- coef(fit)
  se <- se(fit)
  pv <- pvalue(fit)
  n <- fit$nobs
  if (!is.null(param)) {
    idx <- grep(param, names(cf), fixed = TRUE)
    if (length(idx) == 0) idx <- 1
    cf <- cf[idx]
    se <- se[idx]
    pv <- pv[idx]
  }
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  list(coef = cf, se = se, pval = pv, stars = stars, n = n)
}

r1 <- get_coef(results$did_child_labor, "treated_by_1920:post")
r2 <- get_coef(results$did_child_labor_ns, "treated_by_1920:post")
r3 <- get_coef(results$did_school, "treated_by_1920:post")
r4 <- get_coef(results$did_school_ns, "treated_by_1920:post")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Short-Run Effects of Mothers' Pensions on Child Labor and Schooling (1910--1920)}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Child Labor Rate} & \\multicolumn{2}{c}{School Attendance} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Full & Non-South & Full & Non-South \\\\",
  "\\midrule",
  sprintf("MP Adopted $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          r1$coef, r1$stars, r2$coef, r2$stars, r3$coef, r3$stars, r4$coef, r4$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          r1$se, r2$se, r3$se, r4$se),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] & [%.3f] \\\\[6pt]",
          r1$pval, r2$pval, r3$pval, r4$pval),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          r1$n, r2$n, r3$n, r4$n),
  sprintf("States & %d & %d & %d & %d \\\\",
          r1$n / 2, r2$n / 2, r3$n / 2, r4$n / 2),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Weights & Population & Population & Population & Population \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Difference-in-differences estimates of the effect of ",
         "mothers' pension adoption on child labor and school attendance. Unit of ",
         "observation is the state $\\times$ year. Treatment = state adopted a mothers' ",
         "pension law by 1919. Pre-period: 1910; post-period: 1920. Children aged 8--14 ",
         "in 1910 from the IPUMS MLP linked panel. Standard errors clustered at the ",
         "state level in parentheses; $p$-values in brackets. ",
         "Columns (2) and (4) exclude Southern states. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:short_run}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_short_run.tex")
cat("Written tab2_short_run.tex\n")

# =============================================================================
# Table 3: Long-Run Effects on Adult Occupational Attainment
# =============================================================================
cat("=== Table 3: Long-Run Results ===\n")

l1 <- get_coef(results$ols_sei, "treated")
l2 <- get_coef(results$ols_sei_cont, "mp_exposure")
l3 <- get_coef(results$ols_sei_ctrl, "mp_exposure")
l4 <- get_coef(results$ols_sei_ns, "mp_exposure")
l5 <- get_coef(results$ols_occscore_cont, "mp_exposure")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Long-Run Effects of Mothers' Pensions on Adult Occupational Attainment (1940)}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{4}{c}{SEI (1940)} & Occscore \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-6}",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("MP Adopted & %.3f%s & & & & \\\\", l1$coef, l1$stars),
  sprintf(" & (%.3f) & & & & \\\\[3pt]", l1$se),
  sprintf("MP Exposure (years) & & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          l2$coef, l2$stars, l3$coef, l3$stars, l4$coef, l4$stars, l5$coef, l5$stars),
  sprintf(" & & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\[6pt]",
          l2$se, l3$se, l4$se, l5$se),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          l1$n, l2$n, l3$n, l4$n, l5$n),
  "Controls & No & No & Yes & Yes & No \\\\",
  "Sample & Full & Full & Full & Non-South & Full \\\\",
  "Weights & Population & Population & Population & Population & Population \\\\",
  "Clustering & State & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Cross-sectional estimates of the effect of childhood ",
         "exposure to mothers' pensions on adult occupational attainment in 1940. ",
         "Unit of observation is the state. Children aged 0--10 in 1920, observed as ",
         "adults (20--30) in 1940, from the IPUMS MLP linked panel. Column (1): binary ",
         "treatment (adopted by 1919). Columns (2)--(5): continuous treatment (years ",
         "of MP exposure = 1920 $-$ adoption year). Controls in (3)--(4): share male, ",
         "share white, mean age in 1920, school attendance in 1920. Column (4) excludes ",
         "Southern states. SEI = Duncan Socioeconomic Index; Occscore = occupational ",
         "income score. Standard errors clustered at the state level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:long_run}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_long_run.tex")
cat("Written tab3_long_run.tex\n")

# =============================================================================
# Table 4: Mechanism — Intermediate Schooling and Additional Outcomes
# =============================================================================
cat("=== Table 4: Mechanisms ===\n")

m1 <- get_coef(results$ols_school30, "mp_exposure")
m2 <- get_coef(results$ols_lfp, "mp_exposure")
m3 <- get_coef(results$ols_farm, "mp_exposure")
m4 <- get_coef(results$ols_homeown, "mp_exposure")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanism Tests: Intermediate Schooling and Additional Adult Outcomes}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & School 1930 & LFP 1940 & Farm 1940 & Homeowner 1940 \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("MP Exposure (years) & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          m1$coef, m1$stars, m2$coef, m2$stars, m3$coef, m3$stars, m4$coef, m4$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          m1$se, m2$se, m3$se, m4$se),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          m1$n, m2$n, m3$n, m4$n),
  "Controls & Yes & Yes & Yes & Yes \\\\",
  "Weights & Population & Population & Population & Population \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each column reports the coefficient on MP exposure (years) ",
         "from a separate cross-sectional regression. Sample: children aged 0--10 in 1920. ",
         "School 1930: school attendance rate (intermediate outcome). LFP 1940: labor force ",
         "participation rate. Farm 1940: share residing on farms. Homeowner 1940: home ownership ",
         "rate. Controls: share male, share white. Standard errors clustered at the state level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:mechanisms}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_mechanisms.tex")
cat("Written tab4_mechanisms.tex\n")

# =============================================================================
# Table 5: Robustness — Placebo, Heterogeneity
# =============================================================================
cat("=== Table 5: Robustness ===\n")

p1 <- get_coef(robust$placebo_did, "treated_by_1920:post")
h1 <- get_coef(robust$did_cl_boys, "treated_by_1920:post")
h2 <- get_coef(robust$did_cl_girls, "treated_by_1920:post")
h3 <- get_coef(robust$sei_male, "mp_exposure")
h4 <- get_coef(robust$sei_female, "mp_exposure")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Placebo Test and Heterogeneity by Sex}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Child Labor (1910--1920)} & \\multicolumn{2}{c}{SEI (1940)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & Placebo & Boys & Girls & Males & Females \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("MP $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & & \\\\",
          p1$coef, p1$stars, h1$coef, h1$stars, h2$coef, h2$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & & \\\\[3pt]",
          p1$se, h1$se, h2$se),
  sprintf("MP Exposure & & & & %.3f%s & %.3f%s \\\\",
          h3$coef, h3$stars, h4$coef, h4$stars),
  sprintf(" & & & & (%.3f) & (%.3f) \\\\[6pt]",
          h3$se, h4$se),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          p1$n, h1$n, h2$n, h3$n, h4$n),
  "Age group & 15--18 & 8--14 & 8--14 & 0--10 & 0--10 \\\\",
  "State FE & Yes & Yes & Yes & No & No \\\\",
  "Year FE & Yes & Yes & Yes & No & No \\\\",
  "Weights & Pop. & Pop. & Pop. & Pop. & Pop. \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Column (1): placebo test on children aged 15--18 in ",
         "1910 (already working age, should not be affected by MPs). Columns (2)--(3): ",
         "short-run DiD for child labor by sex. Columns (4)--(5): long-run OLS for adult ",
         "SEI by sex. Standard errors clustered at the state level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robustness}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")
cat("Written tab5_robustness.tex\n")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes using the continuous treatment specification
# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_exposure <- sd(state_long$mp_exposure)

# Main outcomes from the controlled specification (ols_sei_ctrl)
sde_entries <- data.frame(
  Outcome = character(),
  Specification = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_x = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

# Helper function
classify_sde <- function(s) {
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

add_sde <- function(df, outcome_name, spec_name, fit, param, sd_y, sd_x = NA) {
  beta <- coef(fit)[param]
  se_b <- se(fit)[param]
  if (is.na(sd_x)) {
    sde <- beta / sd_y
    se_sde <- se_b / sd_y
  } else {
    sde <- beta * sd_x / sd_y
    se_sde <- se_b * sd_x / sd_y
  }
  rbind(df, data.frame(
    Outcome = outcome_name,
    Specification = spec_name,
    beta = beta,
    se_beta = se_b,
    sd_x = ifelse(is.na(sd_x), NA, sd_x),
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify_sde(sde),
    stringsAsFactors = FALSE
  ))
}

# Child labor DiD (binary treatment)
sd_cl <- sd(state_changes$child_labor_1910)
sde_entries <- add_sde(sde_entries, "Child labor rate", "DiD (1910--1920)",
                        results$did_child_labor, "treated_by_1920:post", sd_cl)

# School attendance DiD (binary treatment)
sd_school <- sd(state_changes$school_attend_1910)
sde_entries <- add_sde(sde_entries, "School attendance", "DiD (1910--1920)",
                        results$did_school, "treated_by_1920:post", sd_school)

# SEI 1940 (continuous treatment)
sd_sei <- sd(state_long$mean_sei_1940, na.rm = TRUE)
sde_entries <- add_sde(sde_entries, "SEI (1940)", "OLS, continuous",
                        results$ols_sei_ctrl, "mp_exposure", sd_sei, sd_exposure)

# Occscore 1940 (continuous treatment)
sd_occ <- sd(state_long$mean_occscore_1940, na.rm = TRUE)
sde_entries <- add_sde(sde_entries, "Occscore (1940)", "OLS, continuous",
                        results$ols_occscore_cont, "mp_exposure", sd_occ, sd_exposure)

# School 1930 (continuous treatment)
sd_sch30 <- sd(state_long$school_attend_1930, na.rm = TRUE)
sde_entries <- add_sde(sde_entries, "School attend. (1930)", "OLS, continuous",
                        results$ols_school30, "mp_exposure", sd_sch30, sd_exposure)

# Farm 1940 (continuous treatment)
sd_farm <- sd(state_long$farm_1940, na.rm = TRUE)
sde_entries <- add_sde(sde_entries, "Farm residence (1940)", "OLS, continuous",
                        results$ols_farm, "mp_exposure", sd_farm, sd_exposure)

cat("SDE entries:\n")
print(sde_entries[, c("Outcome", "sde", "se_sde", "classification")])

# Generate LaTeX
sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_entries)) {
  e <- sde_entries[i, ]
  sd_x_str <- ifelse(is.na(e$sd_x), "---", sprintf("%.3f", e$sd_x))
  sde_lines <- c(sde_lines, sprintf(
    "%s & %s & %.4f & %s & %.3f & %.3f & %.3f & %s \\\\",
    e$Outcome, e$Specification, e$beta, sd_x_str, e$sd_y,
    e$sde, e$se_sde, e$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes ",
         "(SDE) to facilitate cross-study comparison of treatment effect magnitudes. ",
         "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the ",
         "SD($X$) column is marked ``---''. ",
         "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
         "which gives the effect of a one-standard-deviation change in the treatment ",
         "variable, measured in standard deviations of the outcome. ",
         "SD($Y$) and SD($X$) are unconditional standard deviations from the summary ",
         "statistics (Table~\\ref{tab:summary}), before conditioning on fixed effects. "),
  "",
  paste0("\\textbf{Research question:} Does childhood exposure to mothers' pensions ",
         "(America's first welfare program, adopted 1911--1919) improve children's ",
         "long-run occupational attainment? "),
  paste0("\\textbf{Treatment:} Binary (state adopted MP by 1919) for child labor/schooling; ",
         "continuous (years of MP exposure = 1920 $-$ adoption year) for adult outcomes. "),
  paste0("\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel, 1910--1940 linked ",
         "censuses, state-level aggregates. "),
  paste0("\\textbf{Method:} DiD (child labor, schooling); OLS with controls (adult outcomes). ",
         "State-clustered SEs. "),
  paste0("\\textbf{Sample:} Children aged 8--14 in 1910 (short-run) or 0--10 in 1920 ",
         "(long-run), tracked across census waves."),
  "",
  paste0("Classification thresholds (7 categories): ",
         "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
         "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), ",
         "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), ",
         "large positive ($> 0.15$). ",
         "Classification labels refer to the magnitude of the standardized point estimate, ",
         "not to statistical significance. ``Null'' denotes a near-zero effect size ",
         "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}"),
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
