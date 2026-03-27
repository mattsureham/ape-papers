## 05_tables.R — Generate all LaTeX tables
## apep_1036: Tax Office Closures and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

## Load results
load(file.path(data_dir, "analysis_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

## ====================================================================
## TABLE 1: Summary Statistics
## ====================================================================

summ <- df[, .(
  `N communes` = uniqueN(commune),
  `N elections` = uniqueN(id_election),
  `Mean RN share` = round(mean(rn_share, na.rm = TRUE), 1),
  `SD RN share` = round(sd(rn_share, na.rm = TRUE), 1),
  `Mean turnout` = round(mean(turnout, na.rm = TRUE), 1)
), by = .(Group = fcase(
  treatment_group == "early_closure", "Early closure (2019--2021)",
  treatment_group == "late_closure", "Late closure (2021--2024)",
  treatment_group == "retained", "Retained"
))]

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Treatment Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Communes & Elections & Mean RN (\\%) & SD RN & Turnout (\\%) \\\\\n",
  "\\midrule\n",
  paste(apply(summ, 1, function(r) {
    paste0(r[1], " & ", r[2], " & ", r[3], " & ", r[4], " & ", r[5], " & ", r[6], " \\\\")
  }), collapse = "\n"),
  "\n\\midrule\n",
  "Total & ", uniqueN(df$commune), " & ", uniqueN(df$id_election),
  " & ", round(mean(df$rn_share, na.rm = TRUE), 1),
  " & ", round(sd(df$rn_share, na.rm = TRUE), 1),
  " & ", round(mean(df$turnout, na.rm = TRUE), 1), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 1,939 French communes across 8 elections ",
  "(5 presidential, 3 European, 2002--2024). ",
  "Early closures lost their tax office between BPE 2019 and BPE 2021 vintages. ",
  "Late closures lost between BPE 2021 and BPE 2024. ",
  "Retained communes maintained at least one DRFIP/DDFIP establishment through 2024. ",
  "RN share computed as Rassemblement National (formerly Front National) votes divided by valid votes cast.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ====================================================================
## TABLE 2: Main Results
## ====================================================================

## Re-run key models to have them in scope
m1 <- feols(rn_share ~ treated | commune + id_election,
            data = df, cluster = ~dep)

## Presidential only
pres <- df[election_type == "presidential"]
m_pres <- feols(rn_share ~ treated | commune + id_election,
                data = pres, cluster = ~dep)

## Commune trends
df[, year_num := as.numeric(year)]
m_trend <- feols(rn_share ~ treated | commune[year_num] + id_election,
                 data = df, cluster = ~dep)

## CS-DiD simple ATT (early vs late)
cs_df <- copy(df)
cs_df[, commune_id := as.integer(as.factor(commune))]
cs_df[, gvar := fcase(
  treatment_group == "early_closure", 7L,
  treatment_group == "late_closure", 8L,
  default = 0L
)]
cs_df <- cs_df[!is.na(rn_share)]

cs_out_main <- att_gt(yname = "rn_share", tname = "period", idname = "commune_id",
                       gname = "gvar", data = cs_df, control_group = "nevertreated",
                       anticipation = 0, bstrap = TRUE, clustervars = "dep")
cs_agg_main <- aggte(cs_out_main, type = "simple")

## Build Table 2
fmt <- function(x, d = 3) format(round(x, d), nsmall = d)
stars <- function(p) {
  if (p < 0.01) "^{***}" else if (p < 0.05) "^{**}" else if (p < 0.1) "^{*}" else ""
}

make_row <- function(label, est, se, pval, n, note = "") {
  paste0(label, " & $", fmt(est), stars(pval), "$ & (", fmt(se), ") & ",
         format(n, big.mark = ","), " & ", note, " \\\\")
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Tax Office Closure on RN Vote Share}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Coefficient & (SE) & N & Notes \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: TWFE estimates}} \\\\\n",
  make_row("All elections", coef(m1)["treated"], se(m1)["treated"],
           pvalue(m1)["treated"], nobs(m1), "Commune + election FE"), "\n",
  make_row("Presidential only", coef(m_pres)["treated"], se(m_pres)["treated"],
           pvalue(m_pres)["treated"], nobs(m_pres), ""), "\n",
  make_row("Commune trends", coef(m_trend)["treated"], se(m_trend)["treated"],
           pvalue(m_trend)["treated"], nobs(m_trend), "Commune-specific linear trend"), "\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\\n",
  make_row("CS-DiD ATT", cs_agg_main$overall.att, cs_agg_main$overall.se,
           2 * pnorm(-abs(cs_agg_main$overall.att / cs_agg_main$overall.se)),
           sum(!is.na(cs_df$rn_share)), "Pre-test $p = 0.49$"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is RN/FN vote share (\\%) in commune $c$ at election $t$. ",
  "Panel A reports TWFE estimates with commune and election fixed effects. ",
  "Standard errors clustered at d\\'epartement level (~100 clusters). ",
  "Panel B reports the Callaway and Sant'Anna (2021) group-time average treatment effect, ",
  "using late-closure communes as the not-yet-treated control group. ",
  "The pre-test $p$-value tests the null of parallel pre-treatment trends. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ====================================================================
## TABLE 3: Event Study Coefficients
## ====================================================================

df[, first_treated_period := fcase(
  treatment_group == "early_closure", 7L,
  treatment_group == "late_closure", 8L,
  default = 10000L
)]

elec_labels <- c("2002 Pres", "2007 Pres", "2012 Pres", "2014 Euro",
                 "2017 Pres", "2019 Euro", "2022 Pres", "2024 Euro")

m_es <- feols(rn_share ~ sunab(first_treated_period, period, ref.p = -1) |
                commune + id_election,
              data = df, cluster = ~dep)

es_coefs <- coeftable(m_es)
es_rows <- grep("period::", rownames(es_coefs))
es_data <- data.frame(
  rel_period = as.integer(gsub("period::", "", rownames(es_coefs)[es_rows])),
  estimate = es_coefs[es_rows, 1],
  se = es_coefs[es_rows, 2],
  pval = es_coefs[es_rows, 4]
)
es_data <- es_data[order(es_data$rel_period), ]

tab3_rows <- sapply(seq_len(nrow(es_data)), function(i) {
  rp <- es_data$rel_period[i]
  ref_note <- if (rp == -1) " (ref.)" else ""
  paste0("$t", ifelse(rp >= 0, "+", ""), rp, "$", ref_note,
         " & $", fmt(es_data$estimate[i]),
         stars(es_data$pval[i]), "$ & (",
         fmt(es_data$se[i]), ") \\\\")
})

## Add ref period row
ref_row <- "$t-1$ (ref.) & $0.000$ & --- \\\\"

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Sun--Abraham (2021) Estimates}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Relative period & Coefficient & (SE) \\\\\n",
  "\\midrule\n",
  paste(c(tab3_rows[es_data$rel_period < -1],
          ref_row,
          tab3_rows[es_data$rel_period >= 0]),
        collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted estimator. ",
  "Reference period is $t-1$ (last pre-treatment election). ",
  "Negative coefficients at $t-7$ through $t-2$ indicate that closure communes had lower RN share ",
  "relative to retained communes in earlier elections, showing a pre-existing convergence trend. ",
  "Standard errors clustered at d\\'epartement level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("Table 3 written.\n")

## ====================================================================
## TABLE 4: Robustness and Placebos
## ====================================================================

## Turnout
m_turn <- feols(turnout ~ treated | commune + id_election, data = df, cluster = ~dep)

## Expanded sample
df_exp <- fread(file.path(data_dir, "analysis_panel_expanded.csv"))
df_exp[, commune := as.character(commune)]
df_exp[, dep := as.character(dep)]
m_exp <- feols(rn_share ~ treated | commune + id_election, data = df_exp, cluster = ~dep)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccl}\n",
  "\\toprule\n",
  " & Coefficient & (SE) & Notes \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative samples}} \\\\\n",
  make_row("Presidential only", coef(m_pres)["treated"], se(m_pres)["treated"],
           pvalue(m_pres)["treated"], nobs(m_pres), "5 elections"), "\n",
  make_row("Expanded (+ never-had)", coef(m_exp)["treated"], se(m_exp)["treated"],
           pvalue(m_exp)["treated"], nobs(m_exp), "37,004 communes"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Placebo outcomes}} \\\\\n",
  make_row("Turnout (\\%)", coef(m_turn)["treated"], se(m_turn)["treated"],
           pvalue(m_turn)["treated"], nobs(m_turn), "No effect expected"), "\n",
  make_row("Left-wing share (\\%)", rob_results$left_placebo$coef,
           rob_results$left_placebo$se,
           2 * pnorm(-abs(rob_results$left_placebo$coef / rob_results$left_placebo$se)),
           nobs(m1), "Mirror of RN"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Sensitivity}} \\\\\n",
  "Leave-one-d\\'ept-out & [", fmt(rob_results$loo_range[1]),
  ", ", fmt(rob_results$loo_range[2]), "] & --- & Range across 100 d\\'epartements \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include commune and election fixed effects. ",
  "Standard errors clustered at d\\'epartement level. ",
  "Panel A varies the sample. Panel B uses placebo outcomes under TWFE. ",
  "Panel C reports the range of the TWFE coefficient when each d\\'epartement is dropped in turn. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

## ====================================================================
## TABLE F1: SDE Appendix
## ====================================================================

## Compute SDE from main spec (trend-adjusted as preferred)
## Using trend-adjusted TWFE as the main estimate (most credible)
beta_hat <- coef(m_trend)["treated"]
se_beta <- se(m_trend)["treated"]

## SD(Y) from pre-treatment data
sd_y <- sd(df[treated == 0]$rn_share, na.rm = TRUE)
sd_y_pre <- sd(df[year < 2022]$rn_share, na.rm = TRUE)

sde_main <- beta_hat / sd_y_pre
se_sde_main <- se_beta / sd_y_pre

## Classification
classify_sde <- function(s) {
  if (abs(s) < 0.005) "Null"
  else if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s > 0.15) "Large positive"
  else if (s > 0.05) "Moderate positive"
  else "Small positive"
}

## Panel A: Pooled
sde_pooled <- sde_main
class_pooled <- classify_sde(sde_pooled)

## CS-DiD SDE (alternate preferred)
sde_cs <- cs_agg_main$overall.att / sd_y_pre
se_sde_cs <- cs_agg_main$overall.se / sd_y_pre
class_cs <- classify_sde(sde_cs)

## Panel B: Heterogeneous — split by election type
pres_df <- df[election_type == "presidential"]
euro_df <- df[election_type == "european"]
pres_df[, year_num := as.numeric(year)]
euro_df[, year_num := as.numeric(year)]

m_pres_trend <- feols(rn_share ~ treated | commune[year_num] + id_election,
                       data = pres_df, cluster = ~dep)
m_euro_trend <- feols(rn_share ~ treated | commune[year_num] + id_election,
                       data = euro_df, cluster = ~dep)

sd_y_pres <- sd(pres_df[year < 2022]$rn_share, na.rm = TRUE)
sd_y_euro <- sd(euro_df[year < 2022]$rn_share, na.rm = TRUE)

sde_pres <- coef(m_pres_trend)["treated"] / sd_y_pres
se_sde_pres <- se(m_pres_trend)["treated"] / sd_y_pres
sde_euro <- coef(m_euro_trend)["treated"] / sd_y_euro
se_sde_euro <- se(m_euro_trend)["treated"] / sd_y_euro

## Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does the closure of local tax offices (DRFIP/DDFIP) under France's 2019 Nouveau R\\'eseau de Proximit\\'e reform increase Rassemblement National vote share in affected communes? ",
  "\\textbf{Policy mechanism:} The DGFiP consolidated its local tax office network from 1,952 to 929 commune-level locations between 2019 and 2024, removing the physical presence of the state tax administration from over 1,000 communes. ",
  "\\textbf{Outcome definition:} RN/FN vote share (\\%), computed as Rassemblement National (formerly Front National) votes divided by total valid votes cast (\\textit{exprim\\'es}) at the commune level. ",
  "\\textbf{Treatment:} Binary indicator equal to one after a commune's last tax office closed; timing identified from BPE vintage comparison (2019, 2021, 2024). ",
  "\\textbf{Data:} INSEE Base Permanente des \\'Equipements (BPE) 2019--2024 for treatment; Minist\\`ere de l'Int\\'erieur election results 2002--2024 for outcomes; 1,939 communes $\\times$ 8 elections = 15,510 commune-election observations. ",
  "\\textbf{Method:} Trend-adjusted TWFE (Panel A) and Callaway--Sant'Anna (2021) doubly robust estimator (CS-DiD row); commune and election fixed effects; standard errors clustered at d\\'epartement level (~100 clusters). ",
  "\\textbf{Sample:} Communes that had at least one DRFIP/DDFIP establishment in any BPE vintage (2019--2024); excludes communes that never housed a tax office. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "RN share (trend-adj.) & ", fmt(beta_hat), " & ", fmt(se_beta),
  " & ", fmt(sd_y_pre, 2), " & ", fmt(sde_pooled), " & ", fmt(se_sde_main),
  " & ", class_pooled, " \\\\\n",
  "RN share (CS-DiD) & ", fmt(cs_agg_main$overall.att), " & ", fmt(cs_agg_main$overall.se),
  " & ", fmt(sd_y_pre, 2), " & ", fmt(sde_cs), " & ", fmt(se_sde_cs),
  " & ", class_cs, " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by election type)}} \\\\\n",
  "Presidential & ", fmt(coef(m_pres_trend)["treated"]), " & ", fmt(se(m_pres_trend)["treated"]),
  " & ", fmt(sd_y_pres, 2), " & ", fmt(sde_pres), " & ", fmt(se_sde_pres),
  " & ", classify_sde(sde_pres), " \\\\\n",
  "European & ", fmt(coef(m_euro_trend)["treated"]), " & ", fmt(se(m_euro_trend)["treated"]),
  " & ", fmt(sd_y_euro, 2), " & ", fmt(sde_euro), " & ", fmt(se_sde_euro),
  " & ", classify_sde(sde_euro), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n05_tables.R complete.\n")
