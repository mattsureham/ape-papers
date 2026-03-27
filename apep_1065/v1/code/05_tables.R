# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
ddd_models <- readRDS("../data/ddd_models.rds")
dd_models <- readRDS("../data/dd_models.rds")
dd_decomp <- readRDS("../data/dd_decomp.rds")
es_models <- readRDS("../data/es_models.rds")
everify_states <- readRDS("../data/everify_states.rds")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary Statistics...\n")

pre_data <- panel |>
  filter(year <= 2007 & Emp > 0)

summ_stats <- pre_data |>
  group_by(is_hispanic, is_construction) |>
  summarise(
    `Mean Employment` = mean(Emp, na.rm = TRUE),
    `Mean Hire Rate` = mean(hire_rate_w, na.rm = TRUE),
    `Mean Separation Rate` = mean(sep_rate_w, na.rm = TRUE),
    `Mean Stability Rate` = mean(stability_rate_w, na.rm = TRUE),
    `Mean New Hire Earnings` = mean(earn_new_hire, na.rm = TRUE),
    `Counties` = n_distinct(county_fips),
    `Observations` = n(),
    .groups = "drop"
  ) |>
  mutate(Group = case_when(
    is_hispanic & is_construction ~ "Hispanic, Construction",
    is_hispanic & !is_construction ~ "Hispanic, Services",
    !is_hispanic & is_construction ~ "Non-Hispanic, Construction",
    !is_hispanic & !is_construction ~ "Non-Hispanic, Services"
  )) |>
  select(Group, everything(), -is_hispanic, -is_construction)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Pre-Treatment Period (2004--2007)}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l S[table-format=5.0] S[table-format=1.3] S[table-format=1.3] S[table-format=1.3] S[table-format=5.0] S[table-format=3.0]}",
  "\\toprule",
  " & {Employment} & {Hire Rate} & {Sep. Rate} & {Stability} & {Earnings (\\$)} & {Counties} \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_stats)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    summ_stats$Group[i],
    format(round(summ_stats$`Mean Employment`[i]), big.mark = ","),
    format(round(summ_stats$`Mean Hire Rate`[i], 3), nsmall = 3),
    format(round(summ_stats$`Mean Separation Rate`[i], 3), nsmall = 3),
    format(round(summ_stats$`Mean Stability Rate`[i], 3), nsmall = 3),
    format(round(summ_stats$`Mean New Hire Earnings`[i]), big.mark = ","),
    summ_stats$Counties[i]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Pre-treatment county-quarter means from QWI race/ethnicity data (2004Q1--2007Q4). Construction includes NAICS 236--238; Services includes NAICS 541 (Professional Services) and 621 (Ambulatory Health). Hire Rate = New Hires/Employment; Separation Rate = Separations/Employment; Stability = Stable Employment/Employment. Rates winsorized at 1st/99th percentiles. Counties restricted to those with average Hispanic construction employment $\\geq$ 50 in the pre-period.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main DDD Results — Flow Decomposition
# =============================================================================

cat("Generating Table 2: DDD Results...\n")

# Pre-treatment means for the treated Hispanic construction group
pre_means <- panel |>
  filter(is_hispanic & is_construction & treated_state & year <= 2007 & Emp > 0) |>
  summarise(
    hire = mean(hire_rate_w, na.rm = TRUE),
    sep = mean(sep_rate_w, na.rm = TRUE),
    recall = mean(recall_rate_w, na.rm = TRUE),
    stability = mean(stability_rate_w, na.rm = TRUE),
    earnings = mean(earn_new_hire, na.rm = TRUE)
  )

outcomes_short <- c("hire_rate_w", "sep_rate_w", "recall_rate_w", "stability_rate_w", "earn_new_hire")
outcome_labs <- c("Hire Rate", "Sep. Rate", "Recall Rate", "Stability", "Earnings (\\$)")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{E-Verify Mandates and Hispanic Labor Market Flows: DDD Estimates}",
  "\\label{tab:ddd}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l ccccc}",
  "\\toprule",
  paste0(" & \\multicolumn{5}{c}{Dependent Variable} \\\\"),
  "\\cmidrule(lr){2-6}",
  paste0(" & ", paste(outcome_labs, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) & (5) \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Triple-Difference (Hispanic $\\times$ Construction $\\times$ Post)}} \\\\"
)

# Panel A: DDD coefficients
ddd_coefs <- sapply(ddd_models, function(m) coef(m)["hisp_x_constr_x_post"])
ddd_ses <- sapply(ddd_models, function(m) se(m)["hisp_x_constr_x_post"])
ddd_pvals <- sapply(ddd_models, function(m) pvalue(m)["hisp_x_constr_x_post"])

stars_fn <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

coef_line <- "Hispanic $\\times$ Constr. $\\times$ Post"
se_line <- ""
for (i in 1:5) {
  s <- stars_fn(ddd_pvals[i])
  if (i == 5) {
    coef_line <- paste0(coef_line, " & ", format(round(ddd_coefs[i], 1), nsmall = 1), s)
    se_line <- paste0(se_line, " & (", format(round(ddd_ses[i], 1), nsmall = 1), ")")
  } else {
    coef_line <- paste0(coef_line, " & ", format(round(ddd_coefs[i], 4), nsmall = 4), s)
    se_line <- paste0(se_line, " & (", format(round(ddd_ses[i], 4), nsmall = 4), ")")
  }
}
tab2_lines <- c(tab2_lines, paste0(coef_line, " \\\\"), paste0(se_line, " \\\\"))

# Panel B: Simple DD (Hispanic construction)
tab2_lines <- c(tab2_lines,
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Difference-in-Differences (Hispanic Construction Only)}} \\\\"
)

dd_coefs <- sapply(dd_models, function(m) coef(m)["post_mandateTRUE"])
dd_ses <- sapply(dd_models, function(m) se(m)["post_mandateTRUE"])
dd_pvals <- sapply(dd_models, function(m) pvalue(m)["post_mandateTRUE"])

coef_line2 <- "Post-Mandate"
se_line2 <- ""
for (i in 1:4) {
  s <- stars_fn(dd_pvals[i])
  coef_line2 <- paste0(coef_line2, " & ", format(round(dd_coefs[i], 4), nsmall = 4), s)
  se_line2 <- paste0(se_line2, " & (", format(round(dd_ses[i], 4), nsmall = 4), ")")
}
coef_line2 <- paste0(coef_line2, " & \\\\")
se_line2 <- paste0(se_line2, " & \\\\")

tab2_lines <- c(tab2_lines, coef_line2, se_line2)

# Add statistics
n_ddd <- nobs(ddd_models[[1]])
n_dd <- nobs(dd_models[[1]])

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Pre-treatment mean & %s & %s & %s & %s & %s \\\\",
    format(round(pre_means$hire, 3), nsmall = 3),
    format(round(pre_means$sep, 3), nsmall = 3),
    format(round(pre_means$recall, 3), nsmall = 3),
    format(round(pre_means$stability, 3), nsmall = 3),
    format(round(pre_means$earnings), big.mark = ",")),
  sprintf("Observations (Panel A) & \\multicolumn{5}{c}{%s} \\\\", format(n_ddd, big.mark = ",")),
  sprintf("Observations (Panel B) & \\multicolumn{4}{c}{%s} & \\\\", format(n_dd, big.mark = ",")),
  "County $\\times$ Quarter FE & \\multicolumn{5}{c}{Yes} \\\\",
  "Ethnicity $\\times$ Industry $\\times$ Quarter FE & \\multicolumn{5}{c}{Yes (Panel A)} \\\\",
  "Clustered SE (State) & \\multicolumn{5}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A reports triple-difference estimates of E-Verify mandates on labor market flows. The coefficient is on the interaction Hispanic $\\times$ Construction $\\times$ Post-Mandate. Panel B reports simple difference-in-differences for Hispanic construction workers in treated vs.\\ control states. Treatment states: AZ, MS (2008); SC (2009); AL, GA, LA, TN (2012); NC (2013). Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_ddd.tex")

# =============================================================================
# TABLE 3: DD by Ethnicity × Industry (The Decomposition Table)
# =============================================================================

cat("Generating Table 3: DD Decomposition by Group...\n")

# Re-run the four group DDs to get full objects
groups <- list(
  list(h = TRUE, c = TRUE, label = "Hispanic, Construction"),
  list(h = TRUE, c = FALSE, label = "Hispanic, Services"),
  list(h = FALSE, c = TRUE, label = "Non-Hispanic, Construction"),
  list(h = FALSE, c = FALSE, label = "Non-Hispanic, Services")
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{The Verification Chill Across Sectors: DD Estimates by Ethnicity and Industry}",
  "\\label{tab:decomp}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l cccc}",
  "\\toprule",
  " & Hispanic & Hispanic & Non-Hispanic & Non-Hispanic \\\\",
  " & Construction & Services & Construction & Services \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

outcomes_for_tab3 <- c("hire_rate_w", "sep_rate_w", "stability_rate_w")
outcome_labels_3 <- c("\\textit{Panel A: Hire Rate}", "\\textit{Panel B: Separation Rate}",
                       "\\textit{Panel C: Stability Rate}")

for (oi in seq_along(outcomes_for_tab3)) {
  y <- outcomes_for_tab3[oi]
  tab3_lines <- c(tab3_lines,
    if (oi > 1) "\\addlinespace",
    paste0("\\multicolumn{5}{l}{", outcome_labels_3[oi], "} \\\\")
  )

  coef_line <- "Post-Mandate"
  se_line <- ""

  for (g in groups) {
    df_g <- panel |> filter(is_hispanic == g$h & is_construction == g$c & Emp > 0)
    m_g <- feols(
      as.formula(paste0(y, " ~ post_mandate | county_fips + yq")),
      data = df_g, cluster = ~state_id
    )
    b <- coef(m_g)["post_mandateTRUE"]
    s_e <- se(m_g)["post_mandateTRUE"]
    p <- pvalue(m_g)["post_mandateTRUE"]
    star <- stars_fn(p)
    coef_line <- paste0(coef_line, " & ", format(round(b, 4), nsmall = 4), star)
    se_line <- paste0(se_line, " & (", format(round(s_e, 4), nsmall = 4), ")")
  }

  tab3_lines <- c(tab3_lines,
    paste0(coef_line, " \\\\"),
    paste0(se_line, " \\\\")
  )
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "County FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Clustered SE (State) & \\multicolumn{4}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate DD regression for the indicated ethnicity-industry group. All regressions include county and year-quarter fixed effects with standard errors clustered at the state level. The comparison reveals that hiring and separation declines extend to Hispanic workers in non-construction sectors (column 2), while non-Hispanic workers show minimal effects (columns 3--4). This pattern explains why the DDD in Table~\\ref{tab:ddd} Panel A returns null: the comparison group (Hispanic services) experiences the same freeze. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_decomp.tex")

# =============================================================================
# TABLE 4: Robustness — Leave-One-Out & Wild Bootstrap
# =============================================================================

cat("Generating Table 4: Robustness...\n")

loo <- readRDS("../data/loo_results.rds")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness: Leave-One-Out and Wild Cluster Bootstrap}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & DDD Hire Rate & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-State-Out (DDD)}} \\\\"
)

for (i in 1:nrow(loo)) {
  tab4_lines <- c(tab4_lines, sprintf(
    "Drop %s & %s & (%s) \\\\",
    loo$dropped_state[i],
    format(round(loo$coef[i], 4), nsmall = 4),
    format(round(loo$se[i], 4), nsmall = 4)
  ))
}

# WCB results
wcb_hire <- tryCatch(readRDS("../data/wcb_hire.rds"), error = function(e) NULL)
wcb_sep <- tryCatch(readRDS("../data/wcb_sep.rds"), error = function(e) NULL)

tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel B: Wild Cluster Bootstrap (Hispanic Construction DD)}} \\\\",
  " & Coefficient & WCB $p$-value \\\\"
)

if (!is.null(wcb_hire)) {
  tab4_lines <- c(tab4_lines, sprintf(
    "Hire Rate & %s & %s \\\\",
    format(round(coef(dd_models[[1]])["post_mandateTRUE"], 4), nsmall = 4),
    format(round(wcb_hire$p_val, 3), nsmall = 3)
  ))
}
if (!is.null(wcb_sep)) {
  tab4_lines <- c(tab4_lines, sprintf(
    "Separation Rate & %s & %s \\\\",
    format(round(coef(dd_models[[2]])["post_mandateTRUE"], 4), nsmall = 4),
    format(round(wcb_sep$p_val, 3), nsmall = 3)
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A drops each treated state in turn and re-estimates the DDD specification from Table~\\ref{tab:ddd}. Panel B reports wild cluster bootstrap $p$-values (Webb weights, 999 replications) for the simple DD estimates from Table~\\ref{tab:ddd} Panel B.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# =============================================================================

cat("Generating SDE table...\n")

# Compute pre-treatment SD(Y) for key outcomes
pre_hisp_constr <- panel |>
  filter(is_hispanic & is_construction & year <= 2007 & Emp > 0)

sd_hire <- sd(pre_hisp_constr$hire_rate_w, na.rm = TRUE)
sd_sep <- sd(pre_hisp_constr$sep_rate_w, na.rm = TRUE)
sd_stab <- sd(pre_hisp_constr$stability_rate_w, na.rm = TRUE)

# DD coefficients (the directly estimated effects)
b_hire <- coef(dd_models[[1]])["post_mandateTRUE"]
b_sep <- coef(dd_models[[2]])["post_mandateTRUE"]
b_stab <- coef(dd_models[[4]])["post_mandateTRUE"]

se_hire <- se(dd_models[[1]])["post_mandateTRUE"]
se_sep <- se(dd_models[[2]])["post_mandateTRUE"]
se_stab <- se(dd_models[[4]])["post_mandateTRUE"]

# SDE = beta / SD(Y)
sde_hire <- b_hire / sd_hire
sde_sep <- b_sep / sd_sep
sde_stab <- b_stab / sd_stab

se_sde_hire <- se_hire / sd_hire
se_sde_sep <- se_sep / sd_sep
se_sde_stab <- se_stab / sd_stab

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  sign <- if (sde >= 0) "positive" else "negative"
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste("Small", sign))
  if (abs_sde < 0.15) return(paste("Moderate", sign))
  return(paste("Large", sign))
}

# Heterogeneity: split by state wave
early_panel <- panel |>
  filter(is_hispanic & is_construction & Emp > 0 & cohort_year %in% c(2008, 2009))
late_panel <- panel |>
  filter(is_hispanic & is_construction & Emp > 0 & cohort_year %in% c(2012, 2013))

dd_early <- feols(hire_rate_w ~ post_mandate | county_fips + yq,
                  data = early_panel, cluster = ~state_id)
dd_late <- feols(hire_rate_w ~ post_mandate | county_fips + yq,
                 data = late_panel, cluster = ~state_id)

b_early <- coef(dd_early)["post_mandateTRUE"]
se_early <- se(dd_early)["post_mandateTRUE"]
sde_early <- b_early / sd_hire
se_sde_early <- se_early / sd_hire

b_late <- coef(dd_late)["post_mandateTRUE"]
se_late <- se(dd_late)["post_mandateTRUE"]
sde_late <- b_late / sd_hire
se_sde_late <- se_late / sd_hire

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state mandatory E-Verify laws reduce Hispanic labor market fluidity in construction, compressing both hiring and separation flows? ",
  "\\textbf{Policy mechanism:} E-Verify mandates require employers to verify employment eligibility of new hires through a federal database, raising the cost and risk of job transitions for Hispanic workers regardless of documentation status. ",
  "\\textbf{Outcome definition:} Quarterly new hire rate (new hires divided by beginning-of-quarter employment), separation rate (separations divided by employment), and employment stability rate (stable employment divided by employment) from the Census Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary; state adoption of mandatory E-Verify for private employers, staggered across 8 states (2008--2013). ",
  "\\textbf{Data:} Census QWI race/ethnicity by 3-digit NAICS, 2004Q1--2016Q4, county-quarter-ethnicity-industry cells for 930 counties. ",
  "\\textbf{Method:} Two-way fixed effects DD (county + quarter FE) for Hispanic construction workers in treated vs.\\ control states; standard errors clustered at the state level. Wild cluster bootstrap confirms inference. ",
  "\\textbf{Sample:} Counties with average pre-treatment Hispanic construction employment $\\geq$ 50; 206 treated and 724 control counties across 51 jurisdictions. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l S[table-format=-1.4] S[table-format=1.4] S[table-format=1.4] S[table-format=-1.3] S[table-format=1.3] l}",
  "\\toprule",
  "Outcome & {$\\hat{\\beta}$} & {SE} & {SD($Y$)} & {SDE} & {SE(SDE)} & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("New Hire Rate & %s & %s & %s & %s & %s & %s \\\\",
    format(round(b_hire, 4), nsmall = 4),
    format(round(se_hire, 4), nsmall = 4),
    format(round(sd_hire, 4), nsmall = 4),
    format(round(sde_hire, 3), nsmall = 3),
    format(round(se_sde_hire, 3), nsmall = 3),
    classify_sde(sde_hire)),
  sprintf("Separation Rate & %s & %s & %s & %s & %s & %s \\\\",
    format(round(b_sep, 4), nsmall = 4),
    format(round(se_sep, 4), nsmall = 4),
    format(round(sd_sep, 4), nsmall = 4),
    format(round(sde_sep, 3), nsmall = 3),
    format(round(se_sde_sep, 3), nsmall = 3),
    classify_sde(sde_sep)),
  sprintf("Stability Rate & %s & %s & %s & %s & %s & %s \\\\",
    format(round(b_stab, 4), nsmall = 4),
    format(round(se_stab, 4), nsmall = 4),
    format(round(sd_stab, 4), nsmall = 4),
    format(round(sde_stab, 3), nsmall = 3),
    format(round(se_sde_stab, 3), nsmall = 3),
    classify_sde(sde_stab)),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by treatment wave)}} \\\\",
  sprintf("Hire Rate (Early: 2008--09) & %s & %s & %s & %s & %s & %s \\\\",
    format(round(b_early, 4), nsmall = 4),
    format(round(se_early, 4), nsmall = 4),
    format(round(sd_hire, 4), nsmall = 4),
    format(round(sde_early, 3), nsmall = 3),
    format(round(se_sde_early, 3), nsmall = 3),
    classify_sde(sde_early)),
  sprintf("Hire Rate (Late: 2012--13) & %s & %s & %s & %s & %s & %s \\\\",
    format(round(b_late, 4), nsmall = 4),
    format(round(se_late, 4), nsmall = 4),
    format(round(sd_hire, 4), nsmall = 4),
    format(round(sde_late, 3), nsmall = 3),
    format(round(se_sde_late, 3), nsmall = 3),
    classify_sde(sde_late)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat("Done.\n")
