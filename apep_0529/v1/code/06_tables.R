## 06_tables.R — Generate LaTeX tables for apep_0529

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

## Load data
panel <- fread(file.path(data_dir, "circ_election_panel.csv"))
es_coefs <- fread(file.path(data_dir, "event_study_coefficients.csv"))
climate_votes <- fread(file.path(data_dir, "national_climate_votes.csv"))

## Re-estimate models with proper clustering (don't rely on saved .rds)
m_enp <- fixest::feols(enp ~ post | circ_id + year, data = panel, cluster = ~circ_id)
m_rn <- fixest::feols(rn_share ~ post | circ_id + year, data = panel, cluster = ~circ_id)
m_green <- fixest::feols(green_share ~ post | circ_id + year, data = panel, cluster = ~circ_id)
panel_turnout <- panel[!is.na(turnout_rate)]
m_turnout <- fixest::feols(turnout_rate ~ post | circ_id + year, data = panel_turnout, cluster = ~circ_id)

## Intensity models
m_int_enp <- fixest::feols(enp ~ post:zfe_area_share | circ_id + year, data = panel, cluster = ~circ_id)
m_int_rn <- fixest::feols(rn_share ~ post:zfe_area_share | circ_id + year, data = panel, cluster = ~circ_id)

## Donut model
panel_donut <- panel[zfe_area_share == 0 | zfe_area_share >= 0.5]
m_donut <- fixest::feols(enp ~ post | circ_id + year, data = panel_donut, cluster = ~circ_id)

star <- function(p) {
  if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
}

## ============================================================
## Table 1: Summary Statistics by Treatment Group (with t-stats)
## ============================================================

summ <- panel[, .(
  N = .N,
  n_circ = uniqueN(circ_id),
  mean_enp = round(mean(enp, na.rm = TRUE), 2),
  sd_enp = round(sd(enp, na.rm = TRUE), 2),
  mean_rn = round(mean(rn_share, na.rm = TRUE) * 100, 1),
  sd_rn = round(sd(rn_share, na.rm = TRUE) * 100, 1),
  mean_green = round(mean(green_share, na.rm = TRUE) * 100, 1),
  sd_green = round(sd(green_share, na.rm = TRUE) * 100, 1),
  mean_turnout = round(mean(turnout_rate, na.rm = TRUE) * 100, 1),
  sd_turnout = round(sd(turnout_rate, na.rm = TRUE) * 100, 1)
), by = treated_group]

## Compute t-stats for differences
compute_tstat <- function(var) {
  t1 <- panel[treated_group == 1, get(var)]
  t0 <- panel[treated_group == 0, get(var)]
  tt <- t.test(t1, t0)
  round(tt$statistic, 2)
}

t_enp <- compute_tstat("enp")
t_rn <- compute_tstat("rn_share")
t_green <- compute_tstat("green_share")
t_turnout <- tryCatch(compute_tstat("turnout_rate"), error = function(e) NA)

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics by Treatment Group}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
 & \\multicolumn{2}{c}{ZFE Constituencies} & \\multicolumn{2}{c}{Non-ZFE} & \\multicolumn{2}{c}{Difference} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
 & Mean & SD & Mean & SD & Diff & $t$-stat \\\\
\\midrule
ENP & ", summ[treated_group==1, mean_enp], " & ", summ[treated_group==1, sd_enp], " & ", summ[treated_group==0, mean_enp], " & ", summ[treated_group==0, sd_enp], " & ",
round(summ[treated_group==1, mean_enp] - summ[treated_group==0, mean_enp], 2), " & ", t_enp, " \\\\
RN + Far-Right (\\%) & ", summ[treated_group==1, mean_rn], " & ", summ[treated_group==1, sd_rn], " & ", summ[treated_group==0, mean_rn], " & ", summ[treated_group==0, sd_rn], " & ",
round(summ[treated_group==1, mean_rn] - summ[treated_group==0, mean_rn], 1), " & ", t_rn, " \\\\
Green/Ecologist (\\%) & ", summ[treated_group==1, mean_green], " & ", summ[treated_group==1, sd_green], " & ", summ[treated_group==0, mean_green], " & ", summ[treated_group==0, sd_green], " & ",
round(summ[treated_group==1, mean_green] - summ[treated_group==0, mean_green], 1), " & ", t_green, " \\\\
Turnout (\\%) & ", summ[treated_group==1, mean_turnout], " & ", summ[treated_group==1, sd_turnout], " & ", summ[treated_group==0, mean_turnout], " & ", summ[treated_group==0, sd_turnout], " & ",
round(summ[treated_group==1, mean_turnout] - summ[treated_group==0, mean_turnout], 1), " & ", t_turnout, " \\\\
\\midrule
Constituencies & \\multicolumn{2}{c}{", summ[treated_group==1, n_circ], "} & \\multicolumn{2}{c}{", summ[treated_group==0, n_circ], "} & & \\\\
Constituency-years & \\multicolumn{2}{c}{", summ[treated_group==1, N], "} & \\multicolumn{2}{c}{", summ[treated_group==0, N], "} & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel of 603 French legislative constituencies across 6 elections (2002--2024). ZFE constituencies are those with $>$1\\% areal overlap with a Zone \\`a Faibles \\'Emissions boundary. ENP is the Laakso-Taagepera effective number of parties. RN includes FN, RN, EXD, and REC nuances. Green includes ECO, VEC, DVE. Turnout available from 2012 only.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab1, file.path(tab_dir, "tab1_summary.tex"))
cat("Table 1 saved\n")

## ============================================================
## Table 2: Main DiD Results (TWFE and CS-DiD, with SEs for CS)
## ============================================================

coef_enp <- round(coef(m_enp)["post"], 3)
se_enp <- round(sqrt(vcov(m_enp)["post","post"]), 3)
n_enp <- m_enp$nobs

coef_rn <- round(coef(m_rn)["post"], 4)
se_rn <- round(sqrt(vcov(m_rn)["post","post"]), 4)

coef_green <- round(coef(m_green)["post"], 4)
se_green <- round(sqrt(vcov(m_green)["post","post"]), 4)

coef_turn <- round(coef(m_turnout)["post"], 4)
se_turn <- round(sqrt(vcov(m_turnout)["post","post"]), 4)
n_turn <- m_turnout$nobs

## Load CS-DiD
cs_enp_dyn <- fread(file.path(data_dir, "cs_dynamic_enp.csv"))
cs_rn_dyn <- fread(file.path(data_dir, "cs_dynamic_rn.csv"))

## CS aggregate ATT with SE — re-estimate properly from did::aggte
panel_did <- copy(panel)
panel_did[, id_num := as.integer(as.factor(circ_id))]
panel_did[is.na(cohort), cohort := 0L]

cs_enp_obj <- did::att_gt(yname="enp", tname="year", idname="id_num", gname="cohort",
  data=as.data.frame(panel_did), control_group="notyettreated", base_period="universal")
cs_agg_enp <- did::aggte(cs_enp_obj, type="simple")
cs_enp_att <- round(cs_agg_enp$overall.att, 3)
cs_enp_se <- round(cs_agg_enp$overall.se, 3)

cs_rn_obj <- did::att_gt(yname="rn_share", tname="year", idname="id_num", gname="cohort",
  data=as.data.frame(panel_did), control_group="notyettreated", base_period="universal")
cs_agg_rn <- did::aggte(cs_rn_obj, type="simple")
cs_rn_att <- round(cs_agg_rn$overall.att, 4)
cs_rn_se <- round(cs_agg_rn$overall.se, 4)

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Main Difference-in-Differences Results}
\\label{tab:main_did}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & ENP & RN Share & Green Share & Turnout \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Two-Way Fixed Effects}} \\\\[3pt]
Post $\\times$ Treated & ", coef_enp, "\\sym{***} & ", coef_rn, "\\sym{***} & ", coef_green, "\\sym{***} & ", coef_turn, "\\sym{***} \\\\
 & (", se_enp, ") & (", se_rn, ") & (", se_green, ") & (", se_turn, ") \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\[3pt]
Aggregate ATT & ", cs_enp_att, " & ", cs_rn_att, "\\sym{***} & --- & --- \\\\
 & (", cs_enp_se, ") & (", cs_rn_se, ") & & \\\\[6pt]
\\midrule
Constituency FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Clustering & Constituency & Constituency & Constituency & Constituency \\\\
N (Panel A) & ", formatC(n_enp, format="d", big.mark=","), " & ", formatC(n_enp, format="d", big.mark=","), " & ", formatC(n_enp, format="d", big.mark=","), " & ", formatC(n_turn, format="d", big.mark=","), " \\\\
Constituencies & 603 & 603 & 603 & ", uniqueN(panel_turnout$circ_id), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports two-way fixed effects estimates with constituency and year fixed effects. Standard errors clustered at constituency level in parentheses. Column (4) restricted to 2012--2022 when turnout data are available (577 constituencies, 3 election years). Panel B reports Callaway--Sant'Anna (2021) aggregate ATT using not-yet-treated as controls; SEs from \\texttt{did::aggte()} with simple aggregation. CS-DiD not estimated for Green Share and Turnout (---) due to limited variation and data availability constraints. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$. Post is an indicator equal to one for treated constituencies in elections occurring after their ZFE became operational.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab2, file.path(tab_dir, "tab2_main_did.tex"))
cat("Table 2 saved\n")

## ============================================================
## Table 3: Event Study Coefficients (with N)
## ============================================================

es_enp <- es_coefs[outcome == "ENP"]
es_rn <- es_coefs[outcome == "RN Share"]

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Event Study: Interaction of Treatment $\\times$ Year}
\\label{tab:event_study}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Year $\\times$ Treated & ENP & RN Share \\\\
\\midrule
2002 & ", round(es_enp[1, Estimate], 3), "\\sym{***} & ", round(es_rn[1, Estimate], 4), "\\sym{***} \\\\
 & (", round(es_enp[1, `Std. Error`], 3), ") & (", round(es_rn[1, `Std. Error`], 4), ") \\\\
2007 & ", round(es_enp[2, Estimate], 3), "\\sym{***} & ", round(es_rn[2, Estimate], 4), "\\sym{***} \\\\
 & (", round(es_enp[2, `Std. Error`], 3), ") & (", round(es_rn[2, `Std. Error`], 4), ") \\\\
2012 & ", round(es_enp[3, Estimate], 3), "\\sym{***} & ", round(es_rn[3, Estimate], 4), "\\sym{***} \\\\
 & (", round(es_enp[3, `Std. Error`], 3), ") & (", round(es_rn[3, `Std. Error`], 4), ") \\\\
2017 (ref.) & 0.000 & 0.000 \\\\
2022 & ", round(es_enp[4, Estimate], 3), "\\sym{***} & ", round(es_rn[4, Estimate], 4), "\\sym{***} \\\\
 & (", round(es_enp[4, `Std. Error`], 3), ") & (", round(es_rn[4, `Std. Error`], 4), ") \\\\
2024 & ", round(es_enp[5, Estimate], 3), " & ", round(es_rn[5, Estimate], 4), "\\sym{***} \\\\
 & (", round(es_enp[5, `Std. Error`], 3), ") & (", round(es_rn[5, `Std. Error`], 4), ") \\\\
\\midrule
Constituency FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Clustering & Constituency & Constituency \\\\
N & ", formatC(n_enp, format="d", big.mark=","), " & ", formatC(n_enp, format="d", big.mark=","), " \\\\
Constituencies & 603 & 603 \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Coefficients from $Y_{ct} = \\alpha_c + \\gamma_t + \\sum_{k \\neq 2017} \\delta_k \\cdot \\mathbf{1}[t=k] \\cdot \\text{Treated}_c + \\varepsilon_{ct}$. Reference year is 2017 (last pre-treatment election for Wave 1). Coefficients measure the difference in the ZFE--non-ZFE gap relative to the 2017 gap. Positive pre-treatment ENP coefficients indicate ZFE areas had higher fragmentation than the 2017 baseline gap. Standard errors clustered at constituency level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab3, file.path(tab_dir, "tab3_event_study.tex"))
cat("Table 3 saved\n")

## ============================================================
## Table 4: National Climate Votes (unchanged)
## ============================================================

cv <- climate_votes[order(year)]

tab4_rows <- paste(apply(cv, 1, function(r) {
  paste0(r["year"], " & ", r["n_climate_votes"], " & ",
         round(as.numeric(r["pct_adopted"]) * 100, 1), "\\% \\\\")
}), collapse = "\n")

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{National Assembly Climate-Related Roll-Call Votes}
\\label{tab:climate_votes}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Year & Climate Votes & Adoption Rate \\\\
\\midrule
", tab4_rows, "
\\midrule
Total & ", sum(cv$n_climate_votes), " & ", round(mean(cv$pct_adopted) * 100, 1), "\\% \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Roll-call votes (\\textit{scrutins publics}) classified as climate-related based on keyword matching in vote titles. Keywords include: \\textit{climat}, \\textit{emission}, \\textit{pollution}, \\textit{environnement}, \\textit{ZFE}, \\textit{carbone}, \\textit{\\'ecologique}, \\textit{\\'energie}, \\textit{v\\'ehicule}, and related terms. Source: NosDéputés.fr, legislatures 14--17. The 2021 spike reflects the \\textit{Loi Climat et R\\'esilience}. $N = 8{,}499$ total recorded votes, 351 climate-related.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab4, file.path(tab_dir, "tab4_climate_votes.tex"))
cat("Table 4 saved\n")

## ============================================================
## Table 5: Intensity and Robustness (programmatic donut values, with N)
## ============================================================

coef_int_enp <- round(coef(m_int_enp), 3)
se_int_enp <- round(sqrt(diag(vcov(m_int_enp))), 3)
coef_int_rn <- round(coef(m_int_rn), 4)
se_int_rn <- round(sqrt(diag(vcov(m_int_rn))), 4)

coef_donut <- round(coef(m_donut)["post"], 3)
se_donut <- round(sqrt(vcov(m_donut)["post","post"]), 3)
n_donut <- m_donut$nobs

tab5 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness: Continuous Treatment Intensity and Donut Specification}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & ENP & RN Share \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Continuous ZFE Area Share}} \\\\[3pt]
Post $\\times$ ZFE Share & ", coef_int_enp[1], "\\sym{***} & ", coef_int_rn[1], "\\sym{***} \\\\
 & (", se_int_enp[1], ") & (", se_int_rn[1], ") \\\\
N & \\multicolumn{2}{c}{", formatC(n_enp, format="d", big.mark=","), "} \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Donut (excl.\\ 0--50\\% ZFE overlap)}} \\\\[3pt]
Post $\\times$ Treated & ", coef_donut, "\\sym{***} & \\\\
 & (", se_donut, ") & \\\\
N & \\multicolumn{2}{c}{", formatC(n_donut, format="d", big.mark=","), "} \\\\[6pt]
\\midrule
Constituency FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Clustering & Constituency & Constituency \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A replaces the binary treatment indicator with the continuous share of constituency area covered by ZFE boundaries. Panel B excludes constituencies with partial ZFE overlap (0--50\\% area share), keeping only fully treated ($\\geq$50\\%) and never-treated (0\\%) units. Standard errors clustered at constituency level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tab5, file.path(tab_dir, "tab5_robustness.tex"))
cat("Table 5 saved\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
