## 05_tables.R — Generate all LaTeX tables
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply

source("00_packages.R")

df <- readRDS("data/analysis_sample.rds")
annual <- readRDS("data/panel_annual.rds") |>
  filter(year >= 2010, year <= 2024, !is.na(net_additions))

# Load model results
twfe_model <- readRDS("data/twfe_model.rds")
twfe_log <- readRDS("data/twfe_log.rds")
cs_att <- readRDS("data/cs_att.rds")
cs_es <- readRDS("data/cs_es.rds")
twfe_w1 <- readRDS("data/twfe_w1.rds")
twfe_w2 <- readRDS("data/twfe_w2.rds")
twfe_received <- readRDS("data/twfe_received.rds")
twfe_narrow <- readRDS("data/twfe_narrow.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

sum_stats <- df |>
  group_by(treated_ever) |>
  summarise(
    n_lpa = n_distinct(lpa_name),
    mean_decided = mean(apps_decided, na.rm = TRUE),
    sd_decided = sd(apps_decided, na.rm = TRUE),
    mean_received = mean(apps_received, na.rm = TRUE),
    sd_received = sd(apps_received, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )

# Annual net additions
annual_stats <- annual |>
  mutate(treated_ever = !is.na(wave)) |>
  group_by(treated_ever) |>
  summarise(
    mean_additions = mean(net_additions, na.rm = TRUE),
    sd_additions = sd(net_additions, na.rm = TRUE),
    .groups = "drop"
  )

# Combine
all_stats <- df |>
  summarise(
    mean_decided = mean(apps_decided, na.rm = TRUE),
    sd_decided = sd(apps_decided, na.rm = TRUE),
    mean_received = mean(apps_received, na.rm = TRUE),
    sd_received = sd(apps_received, na.rm = TRUE)
  )

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Planning Applications by Treatment Status}
\\begin{threeparttable}
\\begin{tabular}{l S[table-format=3.1] S[table-format=3.1] S[table-format=3.1] S[table-format=3.1]}
\\toprule
& \\multicolumn{2}{c}{Treated LPAs} & \\multicolumn{2}{c}{Control LPAs} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & {Mean} & {Std. Dev.} & {Mean} & {Std. Dev.} \\\\
\\midrule
Applications decided (quarterly) & ",
  sprintf("%.1f & %.1f & %.1f & %.1f",
    sum_stats$mean_decided[sum_stats$treated_ever], sum_stats$sd_decided[sum_stats$treated_ever],
    sum_stats$mean_decided[!sum_stats$treated_ever], sum_stats$sd_decided[!sum_stats$treated_ever]),
" \\\\
Applications received (quarterly) & ",
  sprintf("%.1f & %.1f & %.1f & %.1f",
    sum_stats$mean_received[sum_stats$treated_ever], sum_stats$sd_received[sum_stats$treated_ever],
    sum_stats$mean_received[!sum_stats$treated_ever], sum_stats$sd_received[!sum_stats$treated_ever]),
" \\\\
Net additional dwellings (annual) & ",
  sprintf("%.1f & %.1f & %.1f & %.1f",
    annual_stats$mean_additions[annual_stats$treated_ever], annual_stats$sd_additions[annual_stats$treated_ever],
    annual_stats$mean_additions[!annual_stats$treated_ever], annual_stats$sd_additions[!annual_stats$treated_ever]),
" \\\\
\\midrule
Number of LPAs & \\multicolumn{2}{c}{", sum_stats$n_lpa[sum_stats$treated_ever],
"} & \\multicolumn{2}{c}{", sum_stats$n_lpa[!sum_stats$treated_ever], "} \\\\
Quarterly observations & \\multicolumn{2}{c}{", format(sum_stats$n_obs[sum_stats$treated_ever], big.mark = ","),
"} & \\multicolumn{2}{c}{", format(sum_stats$n_obs[!sum_stats$treated_ever], big.mark = ","), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample covers 2010Q1--2025Q3. Treated LPAs received nutrient neutrality advice from Natural England in Wave~1 (2019, $N=29$) or Wave~2 (March 2022, $N=40$). Control LPAs never received nutrient neutrality advice. Applications decided and received are from MHCLG PS1 Planning Application Statistics. Net additional dwellings are from MHCLG Live Table 122 (annual, 2010--2024).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: MAIN RESULTS
# ============================================================
cat("Generating Table 2: Main Results\n")

# Compute key statistics
cs_beta <- cs_att$overall.att
cs_se <- cs_att$overall.se
twfe_beta <- coef(twfe_model)["treated"]
twfe_se <- se(twfe_model)["treated"]
log_beta <- coef(twfe_log)["treated"]
log_se <- se(twfe_log)["treated"]

# Net additions
twfe_dwell <- readRDS("data/twfe_dwellings.rds")
dwell_beta <- coef(twfe_dwell)["treated"]
dwell_se <- se(twfe_dwell)["treated"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Nutrient Neutrality Advice on Planning Outcomes}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& \\multicolumn{3}{c}{Applications Decided (Quarterly)} & \\multicolumn{2}{c}{Net Dwellings (Annual)} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}
& {CS-DiD} & {TWFE} & {Log TWFE} & {Levels} & {Log} \\\\
\\midrule
Nutrient neutrality & ", sprintf("%.2f%s", cs_beta, stars(2*pnorm(-abs(cs_beta/cs_se)))),
" & ", sprintf("%.2f%s", twfe_beta, stars(2*pnorm(-abs(twfe_beta/twfe_se)))),
" & ", sprintf("%.3f%s", log_beta, stars(2*pnorm(-abs(log_beta/log_se)))),
" & ", sprintf("%.2f%s", dwell_beta, stars(2*pnorm(-abs(dwell_beta/dwell_se)))),
" & ", sprintf("%.3f", coef(readRDS("data/twfe_dwellings_log.rds"))["treated"]),
" \\\\
& (", sprintf("%.2f", cs_se),
") & (", sprintf("%.2f", twfe_se),
") & (", sprintf("%.3f", log_se),
") & (", sprintf("%.2f", dwell_se),
") & (", sprintf("%.3f", se(readRDS("data/twfe_dwellings_log.rds"))["treated"]),
") \\\\
\\\\
Estimator & {CS} & {TWFE} & {TWFE} & {TWFE} & {TWFE} \\\\
LPA FE & {Yes} & {Yes} & {Yes} & {Yes} & {Yes} \\\\
Quarter/Year FE & {Yes} & {Yes} & {Yes} & {Yes} & {Yes} \\\\
Clustering & {LPA} & {LPA} & {LPA} & {LPA} & {LPA} \\\\
Control group & {Never} & {Never} & {Never} & {Never} & {Never} \\\\
Observations & ", format(nrow(df), big.mark = ","),
" & ", format(nrow(df), big.mark = ","),
" & ", format(nrow(df), big.mark = ","),
" & ", format(summary(twfe_dwell)$nobs, big.mark = ","),
" & ", format(summary(readRDS("data/twfe_dwellings_log.rds"))$nobs, big.mark = ","),
" \\\\
LPAs & 350 & 350 & 350 & ", length(unique(twfe_dwell$fixef_id$lpa_id)),
" & ", length(unique(readRDS("data/twfe_dwellings_log.rds")$fixef_id$lpa_id)), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the LPA level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column~(1) reports the Callaway--Sant'Anna (2021) overall ATT using never-treated LPAs as controls. Columns~(2)--(3) report TWFE estimates with LPA and quarter fixed effects. Columns~(4)--(5) use annual net additional dwellings from MHCLG Live Table 122. The treatment variable equals one for LPAs receiving nutrient neutrality advice from Natural England in the post-advice period.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}")

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: EVENT STUDY COEFFICIENTS
# ============================================================
cat("Generating Table 3: Event Study\n")

es_data <- data.frame(
  event_time = cs_es$egt,
  estimate = cs_es$att.egt,
  se = cs_es$se.egt
) |>
  filter(event_time >= -8, event_time <= 8)

es_rows <- paste(apply(es_data, 1, function(row) {
  et <- as.integer(row["event_time"])
  est <- as.numeric(row["estimate"])
  s <- as.numeric(row["se"])
  p <- 2 * pnorm(-abs(est / s))
  sprintf("%d & %.2f%s & (%.2f)", et, est, stars(p), s)
}), collapse = " \\\\\n")

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Event Study Estimates: Callaway--Sant'Anna Dynamic ATT}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Quarter & Estimate & Std. Error \\\\
\\midrule
", es_rows, " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Event time 0 is the quarter in which the LPA first received nutrient neutrality advice. Estimates from Callaway--Sant'Anna (2021) dynamic aggregation with never-treated controls. Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Pre-treatment coefficients (event time $<0$) test parallel trends.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:event_study}
\\end{table}")

writeLines(tab3, "../tables/tab3_event_study.tex")

# ============================================================
# TABLE 4: ROBUSTNESS
# ============================================================
cat("Generating Table 4: Robustness\n")

cs_nyt <- readRDS("data/cs_att_nyt.rds")

models <- list(
  "Baseline" = twfe_log,
  "Wave 1 only" = twfe_w1,
  "Wave 2 only" = twfe_w2,
  "2015--2025" = twfe_narrow,
  "Apps received" = twfe_received
)

rob_rows <- paste(sapply(names(models), function(nm) {
  m <- models[[nm]]
  b <- coef(m)["treated"]
  s <- se(m)["treated"]
  p <- 2 * pnorm(-abs(b / s))
  n <- summary(m)$nobs
  sprintf("%s & %.3f%s & (%.3f) & %s", nm, b, stars(p), s, format(n, big.mark = ","))
}), collapse = " \\\\\n")

# Add CS not-yet-treated
nyt_p <- 2 * pnorm(-abs(cs_nyt$overall.att / cs_nyt$overall.se))
rob_rows <- paste0(rob_rows, " \\\\\n",
  sprintf("CS not-yet-treated & %.2f%s & (%.2f) & %s",
    cs_nyt$overall.att, stars(nyt_p), cs_nyt$overall.se,
    format(nrow(df), big.mark = ",")))

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Specification & Estimate & Std. Error & $N$ \\\\
\\midrule
", rob_rows, " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All TWFE specifications include LPA and quarter fixed effects with LPA-clustered standard errors. The dependent variable is log(applications decided + 1) unless otherwise noted. ``Apps received'' uses log(applications received + 1) as the dependent variable. ``CS not-yet-treated'' reports the Callaway--Sant'Anna ATT using not-yet-treated LPAs as the control group (levels, not logs). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}")

writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZES
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Main outcomes
sd_decided <- sd(df$apps_decided, na.rm = TRUE)
sd_log_decided <- sd(df$log_decided, na.rm = TRUE)

# CS-DiD (levels)
sde_cs <- cs_beta / sd_decided
se_sde_cs <- cs_se / sd_decided

# Log TWFE
sde_log <- log_beta / sd_log_decided
se_sde_log <- log_se / sd_log_decided

# Net additions (annual)
sd_additions <- sd(annual$net_additions, na.rm = TRUE)
sde_dwell <- dwell_beta / sd_additions
se_sde_dwell <- dwell_se / sd_additions

classify <- function(s) {
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

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{llccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Applications decided & CS-DiD & ", sprintf("%.2f", cs_beta), " & ", sprintf("%.2f", sd_decided),
" & ", sprintf("%.3f", sde_cs), " & ", sprintf("%.3f", se_sde_cs), " & ", classify(sde_cs), " \\\\
Applications decided (log) & TWFE & ", sprintf("%.3f", log_beta), " & ", sprintf("%.3f", sd_log_decided),
" & ", sprintf("%.3f", sde_log), " & ", sprintf("%.3f", se_sde_log), " & ", classify(sde_log), " \\\\
Net additional dwellings & TWFE & ", sprintf("%.2f", dwell_beta), " & ", sprintf("%.2f", sd_additions),
" & ", sprintf("%.3f", sde_dwell), " & ", sprintf("%.3f", se_sde_dwell), " & ", classify(sde_dwell), " \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is omitted. SD($Y$) is the unconditional standard deviation from the analysis sample before conditioning on fixed effects.

\\textbf{Research question:} What is the effect of nutrient neutrality advice on local planning authority decisions and housing supply in England?
\\textbf{Treatment:} Binary --- whether an LPA has received nutrient neutrality advice from Natural England.
\\textbf{Data:} MHCLG PS1 Planning Application Statistics (quarterly, 2010--2025) and Live Table 122 (annual net additional dwellings, 2010--2024), 350 LPAs.
\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator and TWFE; LPA-clustered standard errors.
\\textbf{Sample:} 69 treated LPAs (29 Wave 1, 40 Wave 2) and 281 never-treated control LPAs.

Classification thresholds (7 categories): large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). Classification is based solely on the SDE point estimate --- never on statistical significance or $p$-values.

\\textbf{Disclaimer:} Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|\\text{SDE}| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}")

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/\n")
