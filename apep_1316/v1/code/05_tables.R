# 05_tables.R — Generate all LaTeX tables
# apep_1316: BVA Judge Leniency IV
# V1 format: max 5 tables + 1 SDE table (appendix)

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

df <- read_csv(file.path(DATA_DIR, "analysis_data.csv"), show_col_types = FALSE)
vlj_stats <- read_csv(file.path(DATA_DIR, "vlj_stats.csv"), show_col_types = FALSE)
load(file.path(DATA_DIR, "model_objects.RData"))
load(file.path(DATA_DIR, "robustness_objects.RData"))

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

# Case-level stats
case_stats <- df |>
  summarize(
    across(c(grant, leniency_loo, n_issues),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

# VLJ-level stats
vlj_summ <- vlj_stats |>
  summarize(
    n_vlj = n(),
    mean_cases = mean(n_cases),
    sd_cases = sd(n_cases),
    min_cases = min(n_cases),
    max_cases = max(n_cases),
    mean_grant_rate = mean(grant_rate),
    sd_grant_rate = sd(grant_rate),
    min_grant_rate = min(grant_rate),
    max_grant_rate = max(grant_rate)
  )

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& Mean & Std. Dev. & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Case-Level Variables (N = %s)}} \\\\[0.3em]
Appeal Granted          & %.3f & %.3f & %.0f & %.0f \\\\
Leave-One-Out Leniency  & %.3f & %.3f & %.3f & %.3f \\\\
Number of Issues        & %.2f & %.2f & %.0f & %.0f \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: VLJ-Level Variables (N = %d)}} \\\\[0.3em]
Cases per VLJ           & %.1f & %.1f & %.0f & %.0f \\\\
VLJ Grant Rate          & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample includes BVA decisions from FY2017--2018 with identified VLJ and substantive outcome (grant or deny). Panel A reports case-level variables. Panel B reports VLJ-level means. Leave-one-out leniency is the VLJ's grant rate excluding the focal case.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  format(nrow(df), big.mark = ","),
  case_stats$grant_mean, case_stats$grant_sd, case_stats$grant_min, case_stats$grant_max,
  case_stats$leniency_loo_mean, case_stats$leniency_loo_sd,
  case_stats$leniency_loo_min, case_stats$leniency_loo_max,
  case_stats$n_issues_mean, case_stats$n_issues_sd,
  case_stats$n_issues_min, case_stats$n_issues_max,
  vlj_summ$n_vlj,
  vlj_summ$mean_cases, vlj_summ$sd_cases, vlj_summ$min_cases, vlj_summ$max_cases,
  vlj_summ$mean_grant_rate, vlj_summ$sd_grant_rate,
  vlj_summ$min_grant_rate, vlj_summ$max_grant_rate
)
writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))

# =============================================================================
# TABLE 2: First Stage Results
# =============================================================================
cat("Generating Table 2: First Stage\n")

fs_models <- list("(1)" = fs_1, "(2)" = fs_2, "(3)" = fs_3, "(4)" = fs_4)

# Build table manually for clean formatting
rows <- lapply(fs_models, function(m) {
  b <- coef(m)["leniency_loo"]
  s <- se(m)["leniency_loo"]
  p <- pvalue(m)["leniency_loo"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  f_stat <- (b / s)^2
  n <- nobs(m)
  r2 <- fitstat(m, "r2")$r2
  list(beta = sprintf("%.3f%s", b, stars),
       se = sprintf("(%.3f)", s),
       f = sprintf("%.1f", f_stat),
       n = format(n, big.mark = ","),
       r2 = sprintf("%.3f", r2))
})

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{First Stage: VLJ Leniency Predicts Appeal Grants}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
\\midrule
VLJ Leniency (LOO) & %s & %s & %s & %s \\\\
                    & %s & %s & %s & %s \\\\[0.5em]
First-stage $F$     & %s & %s & %s & %s \\\\
\\midrule
Year FE             & No & Yes & Yes & Yes \\\\
RO FE               & No & No & Yes & Yes \\\\
Issue Category FE   & No & No & No & Yes \\\\
\\midrule
$N$                 & %s & %s & %s & %s \\\\
$R^2$               & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is an indicator for appeal granted. VLJ Leniency is the leave-one-out grant rate of the assigned Veterans Law Judge. Standard errors clustered at the VLJ level in parentheses. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:first_stage}
\\end{table}",
  rows[["(1)"]]$beta, rows[["(2)"]]$beta, rows[["(3)"]]$beta, rows[["(4)"]]$beta,
  rows[["(1)"]]$se, rows[["(2)"]]$se, rows[["(3)"]]$se, rows[["(4)"]]$se,
  rows[["(1)"]]$f, rows[["(2)"]]$f, rows[["(3)"]]$f, rows[["(4)"]]$f,
  rows[["(1)"]]$n, rows[["(2)"]]$n, rows[["(3)"]]$n, rows[["(4)"]]$n,
  rows[["(1)"]]$r2, rows[["(2)"]]$r2, rows[["(3)"]]$r2, rows[["(4)"]]$r2
)
writeLines(tab2, file.path(TABLE_DIR, "tab2_first_stage.tex"))

# =============================================================================
# TABLE 3: Balance Tests
# =============================================================================
cat("Generating Table 3: Balance Tests\n")

bal_models <- list(
  "Mental Health Issue" = bal_mh,
  "TDIU Issue" = bal_tdiu,
  "Service Connection" = bal_sc,
  "Number of Issues" = bal_issues
)

bal_rows <- ""
for (nm in names(bal_models)) {
  m <- bal_models[[nm]]
  b <- coef(m)["leniency_loo"]
  s <- se(m)["leniency_loo"]
  p <- pvalue(m)["leniency_loo"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  dep_mean <- if (nm == "Number of Issues") {
    sprintf("%.2f", mean(df$n_issues, na.rm = TRUE))
  } else {
    var_name <- case_when(
      nm == "Mental Health Issue" ~ "mental_health",
      nm == "TDIU Issue" ~ "tdiu",
      nm == "Service Connection" ~ "service_connection"
    )
    sprintf("%.3f", mean(df$issue_category == var_name))
  }
  bal_rows <- paste0(bal_rows, sprintf(
    "%s & %s%.3f%s & (%.3f) & %.3f \\\\\n",
    nm, ifelse(b < 0, "$-$", ""), abs(b), stars, s, as.numeric(dep_mean)
  ))
}

# Joint F
jf <- fitstat(bal_joint, "f")$f
joint_p <- jf$p

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Balance Tests: VLJ Leniency and Case Characteristics}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Dependent Variable & Coefficient & (SE) & Mean \\\\
\\midrule
%s\\midrule
Joint $F$-test $p$-value & \\multicolumn{3}{c}{%.3f} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the coefficient from a regression of the case characteristic on VLJ leave-one-out leniency with year fixed effects. Standard errors clustered at the VLJ level. Under random assignment, leniency should not predict case characteristics. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:balance}
\\end{table}",
  bal_rows, joint_p
)
writeLines(tab3, file.path(TABLE_DIR, "tab3_balance.tex"))

# =============================================================================
# TABLE 4: Heterogeneity by Issue Type
# =============================================================================
cat("Generating Table 4: Heterogeneity\n")

het_rows <- ""
for (itype in names(het_results)) {
  h <- het_results[[itype]]
  stars <- ifelse(abs(h$beta / h$se) > 2.58, "***",
           ifelse(abs(h$beta / h$se) > 1.96, "**",
           ifelse(abs(h$beta / h$se) > 1.645, "*", "")))
  label <- str_to_title(str_replace_all(itype, "_", " "))
  het_rows <- paste0(het_rows, sprintf(
    "%s & %.3f%s & (%.3f) & %s & %.3f \\\\\n",
    label, h$beta, stars, h$se,
    format(h$n, big.mark = ","), h$mean_grant
  ))
}

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{First Stage Heterogeneity by Appeal Issue Type}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Issue Type & VLJ Leniency & (SE) & $N$ & Mean Grant Rate \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the first-stage coefficient from a separate regression of appeal granted on VLJ leave-one-out leniency within the specified issue category subsample. All regressions include year and regional office fixed effects. Standard errors clustered at the VLJ level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:heterogeneity}
\\end{table}",
  het_rows
)
writeLines(tab4, file.path(TABLE_DIR, "tab4_heterogeneity.tex"))

# =============================================================================
# TABLE 5: Robustness
# =============================================================================
cat("Generating Table 5: Robustness\n")

# Preferred spec
pref_b <- coef(fs_4)["leniency_loo"]
pref_se <- se(fs_4)["leniency_loo"]
pref_f <- (pref_b / pref_se)^2

# Placebo
plac_b <- coef(placebo_remand)["leniency_loo"]
plac_se <- se(placebo_remand)["leniency_loo"]

# Excl issue
alt1_b <- coef(alt_1)["leniency_excl_issue"]
alt1_se <- se(alt_1)["leniency_excl_issue"]
alt1_f <- (alt1_b / alt1_se)^2

# Other year
alt2_b <- coef(alt_2)["leniency_other_year"]
alt2_se <- se(alt_2)["leniency_other_year"]
alt2_f <- (alt2_b / alt2_se)^2

# Cluster by RO
ro_se <- se(alt_cluster_ro)["leniency_loo"]

# Two-way cluster
tw_se <- se(alt_cluster_2way)["leniency_loo"]

make_stars <- function(b, s) {
  t <- abs(b / s)
  ifelse(t > 2.58, "***", ifelse(t > 1.96, "**", ifelse(t > 1.645, "*", "")))
}

tab5 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness of the First Stage}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Specification & Coefficient & (SE) & First-Stage $F$ \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Baseline}} \\\\[0.3em]
Preferred (Year + RO + Issue FE) & %.3f%s & (%.3f) & %.1f \\\\[0.5em]
\\multicolumn{4}{l}{\\textit{Panel B: Alternative Leniency Measures}} \\\\[0.3em]
Excluding same issue category    & %.3f%s & (%.3f) & %.1f \\\\
Other-year leniency only         & %.3f%s & (%.3f) & %.1f \\\\[0.5em]
\\multicolumn{4}{l}{\\textit{Panel C: Placebo}} \\\\[0.3em]
Leniency $\\rightarrow$ Remand   & %.3f%s & (%.3f) & --- \\\\[0.5em]
\\multicolumn{4}{l}{\\textit{Panel D: Alternative Clustering}} \\\\[0.3em]
Cluster by Regional Office       & %.3f%s & (%.3f) & %.1f \\\\
Two-way (VLJ + Year-Month)       & %.3f%s & (%.3f) & %.1f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the preferred specification. Panel B uses alternative constructions of VLJ leniency. Panel C runs a placebo test predicting remand (a procedural, not substantive, outcome). Panel D varies the level of standard-error clustering. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}",
  pref_b, make_stars(pref_b, pref_se), pref_se, pref_f,
  alt1_b, make_stars(alt1_b, alt1_se), alt1_se, alt1_f,
  alt2_b, make_stars(alt2_b, alt2_se), alt2_se, alt2_f,
  plac_b, make_stars(plac_b, plac_se), plac_se,
  pref_b, make_stars(pref_b, ro_se), ro_se, (pref_b / ro_se)^2,
  pref_b, make_stars(pref_b, tw_se), tw_se, (pref_b / tw_se)^2
)
writeLines(tab5, file.path(TABLE_DIR, "tab5_robustness.tex"))

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — Appendix
# =============================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Main outcome: grant decision
beta_main <- coef(fs_4)["leniency_loo"]
se_main <- se(fs_4)["leniency_loo"]
sd_y <- sd(df$grant)
sd_x <- sd(df$leniency_loo)

# SDE for continuous treatment: β × SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

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

# Heterogeneous panel: by issue type
het_sde_rows <- ""
for (itype in c("service_connection", "mental_health")) {
  if (!(itype %in% names(het_results))) next
  h <- het_results[[itype]]
  sub <- df |> filter(issue_category == itype)
  sd_y_sub <- sd(sub$grant)
  sd_x_sub <- sd(sub$leniency_loo)
  sde_h <- h$beta * sd_x_sub / sd_y_sub
  se_sde_h <- h$se * sd_x_sub / sd_y_sub
  label <- str_to_title(str_replace_all(itype, "_", " "))
  het_sde_rows <- paste0(het_sde_rows, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    label, h$beta, h$se, sd_y_sub, sde_h, se_sde_h, sd_x_sub, classify(sde_h)
  ))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the identity of the randomly assigned Veterans Law Judge at the Board of Veterans Appeals affect whether a veteran's disability benefits appeal is granted? ",
  "\\textbf{Policy mechanism:} The BVA's Caseflow Automatic Case Distribution system assigns appeals to one of approximately 60 Veterans Law Judges based on docket order and availability, not case characteristics; VLJs exercise substantial discretion over whether to grant, deny, or remand each appeal, creating consequential variation in a veteran's access to monthly disability compensation (\\$150--\\$3,700+) and VA healthcare. ",
  "\\textbf{Outcome definition:} Binary indicator equal to one if the VLJ grants the veteran's appeal (in whole or in part) on the merits, zero if denied. ",
  "\\textbf{Treatment:} Continuous leave-one-out VLJ leniency (the assigned judge's grant rate excluding the focal case). ",
  "\\textbf{Data:} BVA decision text files downloaded from va.gov for FY2017--2018, parsed to extract judge identity, decision outcome, regional office, and issue type; case-level unit of observation. ",
  "\\textbf{Method:} OLS first-stage regression of appeal granted on leave-one-out VLJ leniency with year, regional office, and issue category fixed effects; standard errors clustered at the VLJ level. ",
  "\\textbf{Sample:} BVA decisions with identified VLJ, substantive outcome (grant or deny, excluding remands), and VLJ with at least 30 total decisions. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome and SD($X$) is the unconditional standard deviation of VLJ leniency. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lccccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & SD($X$) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\[0.3em]
Appeal Granted & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\[0.3em]
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  beta_main, se_main, sd_y, sde_main, se_sde_main, sd_x, classify(sde_main),
  het_sde_rows,
  sde_notes
)
writeLines(tabF1, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("All tables generated successfully.\n")
