# 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
main_res <- readRDS("../data/main_results.rds")
rob_res  <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

get_coef <- function(model, var) {
  cf <- coef(model)[var]; se <- se(model)[var]; pv <- pvalue(model)[var]
  n  <- model$nobs
  stars <- ifelse(pv < 0.01, "$^{***}$", ifelse(pv < 0.05, "$^{**}$", ifelse(pv < 0.10, "$^{*}$", "")))
  list(cf = cf, se = se, pv = pv, n = n, stars = stars)
}

# ---- Table 1: Summary Statistics ----
cat("Table 1: Summary Stats\n")
ss <- analysis %>%
  group_by(group = ifelse(first_treat > 0, "BBCE States", "Non-BBCE States")) %>%
  summarise(n = n(), n_states = n_distinct(state_fips),
            snap_mean = mean(snap_rate, na.rm=T), snap_sd = sd(snap_rate, na.rm=T),
            ur_mean = mean(unemp_rate, na.rm=T), ur_sd = sd(unemp_rate, na.rm=T),
            .groups = "drop")

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics by BBCE Adoption Status}
\\label{tab:summary}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{BBCE States} & \\multicolumn{2}{c}{Non-BBCE States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& Mean & SD & Mean & SD \\\\
\\midrule
SNAP participation rate & %.3f & %.3f & %.3f & %.3f \\\\
Unemployment rate & %.3f & %.3f & %.3f & %.3f \\\\[4pt]
State-year observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} SNAP participation rate is the share of households receiving SNAP benefits (ACS 1-year, table B22003). Unemployment rate from BLS LAUS via FRED. BBCE states are those that adopted Broad-Based Categorical Eligibility at any point. Panel years: %d--%d.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  ss$snap_mean[ss$group == "BBCE States"], ss$snap_sd[ss$group == "BBCE States"],
  ss$snap_mean[ss$group == "Non-BBCE States"], ss$snap_sd[ss$group == "Non-BBCE States"],
  ss$ur_mean[ss$group == "BBCE States"], ss$ur_sd[ss$group == "BBCE States"],
  ss$ur_mean[ss$group == "Non-BBCE States"], ss$ur_sd[ss$group == "Non-BBCE States"],
  format(ss$n[ss$group == "BBCE States"], big.mark=","),
  format(ss$n[ss$group == "Non-BBCE States"], big.mark=","),
  ss$n_states[ss$group == "BBCE States"], ss$n_states[ss$group == "Non-BBCE States"],
  min(analysis$year), max(analysis$year))
writeLines(tab1, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results ----
cat("Table 2: Main Results\n")
r1 <- get_coef(main_res$twfe_snap, "bbce_on")
r2 <- get_coef(main_res$twfe_snap_ctrl, "bbce_on")

# CS-DiD results (if available)
cs_att <- if (!is.null(main_res$cs_snap_agg)) {
  list(cf = main_res$cs_snap_agg$overall.att,
       se = main_res$cs_snap_agg$overall.se,
       pv = 2 * pnorm(-abs(main_res$cs_snap_agg$overall.att / main_res$cs_snap_agg$overall.se)),
       stars = ifelse(2*pnorm(-abs(main_res$cs_snap_agg$overall.att/main_res$cs_snap_agg$overall.se)) < 0.01,
                      "$^{***}$", ifelse(2*pnorm(-abs(main_res$cs_snap_agg$overall.att/main_res$cs_snap_agg$overall.se)) < 0.05,
                                         "$^{**}$", ifelse(2*pnorm(-abs(main_res$cs_snap_agg$overall.att/main_res$cs_snap_agg$overall.se)) < 0.10,
                                                           "$^{*}$", ""))))
} else { list(cf = NA, se = NA, stars = "") }

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of BBCE Adoption on SNAP Participation Rate}
\\label{tab:main}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& TWFE & TWFE + Controls & CS-DiD \\\\
\\midrule
BBCE adopted & %.4f%s & %.4f%s & %s \\\\
& (%.4f) & (%.4f) & %s \\\\[4pt]
Unemployment control & No & Yes & No \\\\
State FE & Yes & Yes & -- \\\\
Year FE & Yes & Yes & -- \\\\
Observations & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable: share of households receiving SNAP (ACS B22003). Columns~(1)--(2): TWFE with state and year fixed effects, SEs clustered at state level. Column~(3): Callaway--Sant'Anna staggered DiD with never-treated control group. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  r1$cf, r1$stars, r2$cf, r2$stars,
  ifelse(is.na(cs_att$cf), "--", sprintf("%.4f%s", cs_att$cf, cs_att$stars)),
  r1$se, r2$se,
  ifelse(is.na(cs_att$se), "", sprintf("(%.4f)", cs_att$se)),
  format(r1$n, big.mark=","), format(r2$n, big.mark=","),
  ifelse(is.na(cs_att$cf), "--", format(r1$n, big.mark=",")))
writeLines(tab2, "../tables/tab2_main.tex")

# ---- Table 3: Event Study ----
cat("Table 3: Event Study\n")
if (!is.null(main_res$es_twfe)) {
  es <- main_res$es_twfe
  es_cf <- coef(es); es_se <- se(es); es_pv <- pvalue(es)
  es_names <- names(es_cf)
  es_k <- as.integer(gsub("event_fac::(-?[0-9]+)", "\\1", es_names))
  es_stars <- ifelse(es_pv < 0.01, "$^{***}$", ifelse(es_pv < 0.05, "$^{**}$", ifelse(es_pv < 0.10, "$^{*}$", "")))
  ord <- order(es_k)
  # Truncate to k=-5 through k=10 for readability
  keep <- which(es_k >= -5 & es_k <= 10)
  ord <- intersect(ord, keep)
  es_rows <- paste(sapply(ord, function(i) {
    sprintf("$k = %d$ & %.4f%s & (%.4f) \\\\", es_k[i], es_cf[i], es_stars[i], es_se[i])
  }), collapse = "\n")
} else {
  es_rows <- "-- & -- & -- \\\\"
}

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Effects of BBCE on SNAP Participation}
\\label{tab:event}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time ($k$) & Coefficient & SE \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} TWFE event study. Dependent variable: SNAP participation rate. Reference: $k=-1$. State and year FE. SEs clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
", es_rows)
writeLines(tab3, "../tables/tab3_event.tex")

# ---- Table 4: Heterogeneity ----
cat("Table 4: Heterogeneity\n")
rh_base <- get_coef(rob_res$het_snap, "bbce_on")
rh_int  <- tryCatch(get_coef(rob_res$het_snap, "I(bbce_on * high_snap_base)"),
                     error = function(e) list(cf=NA, se=NA, stars=""))

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Heterogeneity by Baseline SNAP Rate}
\\label{tab:hetero}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lc}
\\toprule
& SNAP Rate \\\\
\\midrule
BBCE adopted & %.4f%s \\\\
& (%.4f) \\\\[4pt]
BBCE $\\times$ High Baseline SNAP & %s \\\\
& %s \\\\[4pt]
Observations & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} High Baseline SNAP is an indicator for states with above-median SNAP participation rate in the first panel year. TWFE with state and year FE. SEs clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  rh_base$cf, rh_base$stars, rh_base$se,
  ifelse(is.na(rh_int$cf), "--", sprintf("%.4f%s", rh_int$cf, rh_int$stars)),
  ifelse(is.na(rh_int$se), "", sprintf("(%.4f)", rh_int$se)),
  format(rob_res$het_snap$nobs, big.mark=","))
writeLines(tab4, "../tables/tab4_hetero.tex")

# ---- Table 5: Robustness ----
cat("Table 5: Robustness\n")
r_ctrl <- get_coef(rob_res$twfe_ctrl, "bbce_on")

# CS-DiD not-yet-treated
cs_nyt_att <- if (!is.null(rob_res$cs_nyt)) {
  a <- rob_res$cs_nyt$agg
  list(cf = a$overall.att, se = a$overall.se,
       pv = 2*pnorm(-abs(a$overall.att/a$overall.se)),
       stars = ifelse(2*pnorm(-abs(a$overall.att/a$overall.se)) < 0.01, "$^{***}$",
               ifelse(2*pnorm(-abs(a$overall.att/a$overall.se)) < 0.05, "$^{**}$",
               ifelse(2*pnorm(-abs(a$overall.att/a$overall.se)) < 0.10, "$^{*}$", ""))))
} else { list(cf = NA, se = NA, stars = "") }

# Placebo
plac <- if (!is.null(rob_res$placebo)) get_coef(rob_res$placebo, "fake_treat") else list(cf=NA, se=NA, stars="")

tab5 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& TWFE + UR & CS-DiD (NYT) & Placebo \\\\
\\midrule
BBCE / Placebo & %.4f%s & %s & %s \\\\
& (%.4f) & %s & %s \\\\[4pt]
Sample & Full & Full & Pre-period \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Col~(1): TWFE controlling for state unemployment rate. Col~(2): Callaway--Sant'Anna with not-yet-treated control group. Col~(3): placebo treatment at 2007, pre-period only. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  r_ctrl$cf, r_ctrl$stars,
  ifelse(is.na(cs_nyt_att$cf), "--", sprintf("%.4f%s", cs_nyt_att$cf, cs_nyt_att$stars)),
  ifelse(is.na(plac$cf), "--", sprintf("%.4f%s", plac$cf, plac$stars)),
  r_ctrl$se,
  ifelse(is.na(cs_nyt_att$se), "", sprintf("(%.4f)", cs_nyt_att$se)),
  ifelse(is.na(plac$se), "", sprintf("(%.4f)", plac$se)))
writeLines(tab5, "../tables/tab5_robust.tex")

# ---- SDE Table ----
cat("SDE Table\n")
beta <- coef(main_res$twfe_snap)["bbce_on"]
se_b <- se(main_res$twfe_snap)["bbce_on"]
sd_y <- sd(analysis$snap_rate, na.rm = TRUE)
sde  <- beta / sd_y
se_sde <- se_b / sd_y

classify <- function(s) case_when(
  s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive", s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive")

sde_notes <- paste0(
  "\\item \\textit{Notes:} \\footnotesize ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does SNAP Broad-Based Categorical Eligibility expansion affect ",
  "program enrollment in U.S.\\ states? ",
  "\\textbf{Policy mechanism:} BBCE allows states to raise the SNAP gross income eligibility ",
  "threshold from 130\\%% to up to 200\\%% of the Federal Poverty Level and eliminate asset tests ",
  "by linking SNAP eligibility to receipt of any TANF-funded benefit, including informational brochures. ",
  "\\textbf{Outcome definition:} Share of households receiving SNAP benefits from ACS 1-year table B22003. ",
  "\\textbf{Treatment:} Binary; state adopted BBCE in a given year. ",
  "\\textbf{Data:} Census ACS 1-year estimates, %d--%d, state-year observations, ",
  format(nrow(analysis), big.mark=","), " total. ",
  "\\textbf{Method:} TWFE with state and year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 states plus DC; excludes territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).")
sde_notes <- sprintf(sde_notes, min(analysis$year), max(analysis$year))

sde_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
SNAP participation rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
", beta, se_b, sd_y, sde, se_sde, classify(sde), sde_notes)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
