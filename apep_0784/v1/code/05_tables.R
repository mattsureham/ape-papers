# 05_tables.R — Generate all LaTeX tables
# APEP paper apep_0784: OSHA Heat NEP

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# Recreate event_time
df[, event_time := year - 2022]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-period summary by industry group
summ_pre <- df[post == 0, .(
  N = format(.N, big.mark = ","),
  Employees = sprintf("%.0f", mean(employees, na.rm = TRUE)),
  `TRC Rate` = sprintf("%.2f", mean(trc_rate, na.rm = TRUE)),
  `SD(TRC)` = sprintf("%.2f", sd(trc_rate, na.rm = TRUE)),
  `DART Rate` = sprintf("%.2f", mean(dart_rate, na.rm = TRUE)),
  `SD(DART)` = sprintf("%.2f", sd(dart_rate, na.rm = TRUE)),
  `Illness Rate` = sprintf("%.2f", mean(illness_rate, na.rm = TRUE)),
  `SD(Illness)` = sprintf("%.2f", sd(illness_rate, na.rm = TRUE))
), by = industry_group]

# Post-period summary by industry group
summ_post <- df[post == 1, .(
  N = format(.N, big.mark = ","),
  Employees = sprintf("%.0f", mean(employees, na.rm = TRUE)),
  `TRC Rate` = sprintf("%.2f", mean(trc_rate, na.rm = TRUE)),
  `SD(TRC)` = sprintf("%.2f", sd(trc_rate, na.rm = TRUE)),
  `DART Rate` = sprintf("%.2f", mean(dart_rate, na.rm = TRUE)),
  `SD(DART)` = sprintf("%.2f", sd(dart_rate, na.rm = TRUE)),
  `Illness Rate` = sprintf("%.2f", mean(illness_rate, na.rm = TRUE)),
  `SD(Illness)` = sprintf("%.2f", sd(illness_rate, na.rm = TRUE))
), by = industry_group]

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Industry Group and Period}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrrr}\n",
  "\\toprule\n",
  " & N & Avg. & TRC & SD & DART & SD & Illness & SD \\\\\n",
  " & & Empl. & Rate & (TRC) & Rate & (DART) & Rate & (Illness) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Panel A: Pre-NEP (2016--2021)}} \\\\\n",
  sprintf("High-Heat (Targeted) & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
          summ_pre[1, N], summ_pre[1, Employees], summ_pre[1, `TRC Rate`], summ_pre[1, `SD(TRC)`],
          summ_pre[1, `DART Rate`], summ_pre[1, `SD(DART)`], summ_pre[1, `Illness Rate`], summ_pre[1, `SD(Illness)`]),
  sprintf("Low-Heat (Non-Targeted) & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
          summ_pre[2, N], summ_pre[2, Employees], summ_pre[2, `TRC Rate`], summ_pre[2, `SD(TRC)`],
          summ_pre[2, `DART Rate`], summ_pre[2, `SD(DART)`], summ_pre[2, `Illness Rate`], summ_pre[2, `SD(Illness)`]),
  "\\addlinespace\n",
  "\\multicolumn{9}{l}{\\textit{Panel B: Post-NEP (2022--2023)}} \\\\\n",
  sprintf("High-Heat (Targeted) & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
          summ_post[1, N], summ_post[1, Employees], summ_post[1, `TRC Rate`], summ_post[1, `SD(TRC)`],
          summ_post[1, `DART Rate`], summ_post[1, `SD(DART)`], summ_post[1, `Illness Rate`], summ_post[1, `SD(Illness)`]),
  sprintf("Low-Heat (Non-Targeted) & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
          summ_post[2, N], summ_post[2, Employees], summ_post[2, `TRC Rate`], summ_post[2, `SD(TRC)`],
          summ_post[2, `DART Rate`], summ_post[2, `SD(DART)`], summ_post[2, `Illness Rate`], summ_post[2, `SD(Illness)`]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} OSHA Injury Tracking Application (ITA) data, 2016--2023. ",
  "Rates per 200,000 hours worked. High-heat (NEP-targeted) industries: agriculture, mining, utilities, construction, ",
  "manufacturing, transportation, administrative/waste services, accommodation/food. ",
  "Low-heat (non-targeted) industries: wholesale/retail trade, information, finance, real estate, ",
  "professional services, management, education, healthcare, arts/entertainment, other services. ",
  "TRC = Total Recordable Cases. DART = Days Away, Restricted, or Transferred. ",
  "Illness includes skin disorders, respiratory conditions, poisonings, and other illnesses.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

# Extract coefficients and SEs from models
extract_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", s))
}

# Build table manually for precise control
tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of OSHA Heat NEP on Workplace Injury Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & TRC & DART & Illness & TRC & TRC \\\\\n",
  " & Rate & Rate & Rate & Rate & Rate \\\\\n",
  "\\midrule\n",

  # Row 1: DiD coefficient
  sprintf("High-Heat $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
          extract_coef(m1_trc, "did")$coef, extract_coef(m1_dart, "did")$coef,
          extract_coef(m1_ill, "did")$coef, extract_coef(m2_trc, "did")$coef,
          extract_coef(m3_trc, "did")$coef),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          extract_coef(m1_trc, "did")$se, extract_coef(m1_dart, "did")$se,
          extract_coef(m1_ill, "did")$se, extract_coef(m2_trc, "did")$se,
          extract_coef(m3_trc, "did")$se),

  "\\addlinespace\n",

  # Row 2: Triple interaction (cols 4-5)
  sprintf("High-Heat $\\times$ Post $\\times$ Hot State & & & & %s & \\\\\n",
          extract_coef(m2_trc, "triple_did")$coef),
  sprintf(" & & & & %s & \\\\\n",
          extract_coef(m2_trc, "triple_did")$se),

  "\\addlinespace\n",

  # Row 3: Continuous heat interaction (col 5)
  sprintf("High-Heat $\\times$ Post $\\times$ Temp (std.) & & & & & %s \\\\\n",
          extract_coef(m3_trc, "did_temp")$coef),
  sprintf(" & & & & & %s \\\\\n",
          extract_coef(m3_trc, "did_temp")$se),

  "\\addlinespace\n",
  "\\midrule\n",
  sprintf("Industry FE & Yes & Yes & Yes & & \\\\\n"),
  sprintf("Industry $\\times$ State FE & & & & Yes & Yes \\\\\n"),
  sprintf("State $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(m1_trc), big.mark = ","), format(nobs(m1_dart), big.mark = ","),
          format(nobs(m1_ill), big.mark = ","), format(nobs(m2_trc), big.mark = ","),
          format(nobs(m3_trc), big.mark = ",")),
  sprintf("Clusters (States) & 51 & 51 & 51 & 51 & 51 \\\\\n"),
  sprintf("Pre-treatment Mean (Targeted) & 4.65 & 3.02 & 0.23 & 4.65 & 4.65 \\\\\n"),

  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient from a difference-in-differences regression ",
  "of workplace injury rates (per 200,000 hours worked) on the interaction of NEP-targeted industry status and the post-2022 indicator. ",
  "Columns (1)--(3) include NAICS 2-digit industry and state$\\times$year fixed effects. ",
  "Columns (4)--(5) add industry$\\times$state fixed effects. ",
  "Column (4) adds a triple interaction with a binary hot-state indicator (above-median summer temperature). ",
  "Column (5) interacts with standardized average summer temperature (continuous). ",
  "Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ============================================================
# TABLE 3: Event Study
# ============================================================
cat("=== Table 3: Event Study ===\n")

es_coefs <- coef(m4_trc)
es_se <- se(m4_trc)
es_pval <- pvalue(m4_trc)

event_times <- c(-6, -5, -4, -3, -2, 0, 1)
es_names <- paste0("event_time::", event_times, ":high_heat")

tab3_rows <- ""
for (i in seq_along(event_times)) {
  et <- event_times[i]
  nm <- es_names[i]
  b <- es_coefs[nm]
  s <- es_se[nm]
  p <- es_pval[nm]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  yr_label <- 2022 + et

  tab3_rows <- paste0(tab3_rows,
    sprintf("%d ($t%s%d$) & %.3f%s \\\\\n", yr_label,
            ifelse(et >= 0, "+", ""), abs(et), b, stars),
    sprintf(" & (%.3f) \\\\\n", s))
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: TRC Rate by Year Relative to NEP}\n",
  "\\label{tab:event}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n",
  "\\toprule\n",
  "Year (Event Time) & High-Heat $\\times$ Year \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\addlinespace\n",
  "Reference: 2021 ($t-1$) & 0 \\\\\n",
  "\\addlinespace\n",
  "\\midrule\n",
  sprintf("Observations & %s \\\\\n", format(nobs(m4_trc), big.mark = ",")),
  "Industry FE & Yes \\\\\n",
  "State $\\times$ Year FE & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from an event-study regression of TRC rate on interactions of ",
  "high-heat industry indicator with year dummies, omitting 2021 (the year before NEP implementation). ",
  "The NEP took effect in April 2022 (event time 0). Non-parallel pre-trends in 2016--2019 indicate ",
  "secular convergence in injury rates across industry groups, complicating simple DiD interpretation. ",
  "Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_event.tex"))
cat("  Saved tab3_event.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

rob_rows <- function(model, var, label) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  sprintf("%s & %.3f%s & (%.3f) & %s \\\\\n", label, b, stars, s,
          format(nobs(model), big.mark = ","))
}

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Simple DiD (High-Heat $\\times$ Post)}} \\\\\n",
  rob_rows(m1_trc, "did", "Baseline (2016--2023)"),
  rob_rows(r1_did, "did", "Restricted: 2019--2023"),
  rob_rows(r2_did, "did_nocovid", "Excluding 2020--2021"),
  rob_rows(r3_did, "did", "Federal OSHA states only"),
  rob_rows(r4_did, "did", "State-plan states (placebo)"),
  rob_rows(r7_did, "did", "Large establishments ($\\geq$250 empl.)"),
  "\\addlinespace\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Triple DiD (High-Heat $\\times$ Post $\\times$ Hot State)}} \\\\\n",
  rob_rows(m2_trc, "triple_did", "Baseline (2016--2023)"),
  rob_rows(r1_triple, "triple_did", "Restricted: 2019--2023"),
  rob_rows(r3_triple, "triple_did", "Federal OSHA states only"),
  rob_rows(r7_triple, "triple_did", "Large establishments ($\\geq$250 empl.)"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports the simple DiD coefficient (High-Heat $\\times$ Post) under alternative samples. ",
  "Panel B reports the triple-DiD coefficient. All specifications include state$\\times$year fixed effects. ",
  "Panel B specifications add industry$\\times$state fixed effects. ",
  "The ``Restricted: 2019--2023'' specification uses a shorter pre-treatment window that produces near-zero estimates, ",
  "confirming that the full-sample DiD result reflects secular trends rather than the NEP. ",
  "The state-plan placebo shows a significant ``effect'' in jurisdictions where the federal NEP does not apply. ",
  "Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_robust.tex"))
cat("  Saved tab4_robust.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: SDE ===\n")

sde_info <- jsonlite::fromJSON(file.path(data_dir, "sde_info.json"))

# Main outcomes from the simple DiD (baseline specification)
outcomes <- data.frame(
  outcome = c("TRC Rate", "DART Rate", "Illness Rate"),
  beta = c(coef(m1_trc)["did"], coef(m1_dart)["did"], coef(m1_ill)["did"]),
  se_beta = c(se(m1_trc)["did"], se(m1_dart)["did"], se(m1_ill)["did"]),
  sd_y = c(sde_info$sd_trc_pre, sde_info$sd_dart_pre, sde_info$sd_ill_pre),
  stringsAsFactors = FALSE
)

outcomes$sde <- outcomes$beta / outcomes$sd_y
outcomes$se_sde <- outcomes$se_beta / outcomes$sd_y

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

outcomes$classification <- classify_sde(outcomes$sde)

# Build SDE table
sde_rows <- ""
for (i in 1:nrow(outcomes)) {
  sde_rows <- paste0(sde_rows, sprintf(
    "%s & %.3f & %.3f & --- & %.3f & %.4f & %.4f & %s \\\\\n",
    outcomes$outcome[i], outcomes$beta[i], outcomes$se_beta[i],
    outcomes$sd_y[i], outcomes$sde[i], outcomes$se_sde[i],
    outcomes$classification[i]
  ))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does OSHA's 2022 Heat National Emphasis Program, which ",
  "intensified workplace inspections in heat-exposed industries, reduce establishment-level ",
  "injury and illness rates? ",
  "\\textbf{Policy mechanism:} The NEP directs OSHA compliance officers to prioritize heat-related ",
  "inspections in high-risk industries (agriculture, construction, manufacturing, transportation, ",
  "landscaping) on days when the heat index exceeds 80\\textdegree F, with enhanced civil penalties ",
  "for heat-related violations. It is the strongest administrative action on occupational heat short ",
  "of a formal rulemaking. ",
  "\\textbf{Outcome definition:} Total Recordable Case (TRC) rate per 200,000 hours worked, ",
  "computed from OSHA Form 300A annual establishment-level reports; DART rate (days away, restricted, ",
  "or transferred cases per 200,000 hours); and total illness rate (skin disorders, respiratory ",
  "conditions, poisonings, and other illnesses per 200,000 hours). ",
  "\\textbf{Treatment:} Binary --- establishment in a NEP-targeted NAICS industry (agriculture, ",
  "mining, utilities, construction, manufacturing, transportation, admin/waste, accommodation) vs. ",
  "non-targeted industry, interacted with post-April 2022 indicator. ",
  "\\textbf{Data:} OSHA Injury Tracking Application, 2016--2023, establishment-year level, ",
  "2,337,654 observations from approximately 1,069,842 unique establishments in 51 states. ",
  "\\textbf{Method:} Difference-in-differences with NAICS 2-digit industry and state$\\times$year ",
  "fixed effects; standard errors clustered at the state level (51 clusters). ",
  "\\textbf{Sample:} Establishments with 250+ employees or in OSHA-designated high-hazard industries, ",
  "as required by ITA electronic reporting; establishments with positive hours worked only. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2016--2021) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
