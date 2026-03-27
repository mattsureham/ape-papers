# 05_tables.R — Generate all LaTeX tables
# apep_1057: The Consolidation Trap

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Load results
# ============================================================================
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
sumstats <- fromJSON(file.path(data_dir, "summary_stats.json"))

stars <- function(coef, se) {
  pval <- 2 * pnorm(-abs(coef / se))
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1\n")

stats_t <- panel[treated == TRUE, .(
  mv = mean(has_violation), sv = sd(has_violation),
  mc = mean(n_health_viols), sc = sd(n_health_viols),
  mp = mean(pop_served, na.rm = TRUE), sp = sd(pop_served, na.rm = TRUE),
  ns = uniqueN(pwsid), no = .N
)]
stats_c <- panel[treated == FALSE, .(
  mv = mean(has_violation), sv = sd(has_violation),
  mc = mean(n_health_viols), sc = sd(n_health_viols),
  mp = mean(pop_served, na.rm = TRUE), sp = sd(pop_served, na.rm = TRUE),
  ns = uniqueN(pwsid), no = .N
)]

tab1 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics: Community Water Systems, 2006--2024}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Never Treated} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n\\hline\n",
  sprintf("Health violation (0/1) & %.4f & %.4f & %.4f & %.4f \\\\\n",
          stats_t$mv, stats_t$sv, stats_c$mv, stats_c$sv),
  sprintf("Violation count & %.4f & %.4f & %.4f & %.4f \\\\\n",
          stats_t$mc, stats_t$sc, stats_c$mc, stats_c$sc),
  sprintf("Population served & %s & %s & %s & %s \\\\\n",
          format(round(stats_t$mp), big.mark = ","),
          format(round(stats_t$sp), big.mark = ","),
          format(round(stats_c$mp), big.mark = ","),
          format(round(stats_c$sp), big.mark = ",")),
  "\\hline\n",
  sprintf("Systems & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(stats_t$ns, big.mark = ","), format(stats_c$ns, big.mark = ",")),
  sprintf("System-quarters & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(stats_t$no, big.mark = ","), format(stats_c$no, big.mark = ",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Data from EPA Safe Drinking Water Information System (SDWIS), 2006Q1--2024Q4. ",
  "Treated systems are active community water systems (CWS) in the same ZIP code as a CWS deactivated during 2006--2024. ",
  "Health violations include Maximum Contaminant Level exceedances for regulated contaminants. ",
  "Population served is the system's reported service population.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("Generating Table 2\n")

tb <- coef(twfe_binary)["post"]; tbs <- sqrt(vcov(twfe_binary)["post","post"])
tc <- coef(twfe_count)["post"]; tcs <- sqrt(vcov(twfe_count)["post","post"])
cb <- cs_agg_simple$overall.att; cbs <- cs_agg_simple$overall.se
cc <- cs_count_simple$overall.att; ccs <- cs_count_simple$overall.se

tab2 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Effect of Neighbor System Deactivation on Drinking Water Violations}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{TWFE} & \\multicolumn{2}{c}{Callaway-Sant'Anna} \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Binary & Count & Binary & Count \\\\\n\\hline\n",
  sprintf("Post $\\times$ Treated & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          tb, stars(tb,tbs), tc, stars(tc,tcs), cb, stars(cb,cbs), cc, stars(cc,ccs)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n", tbs, tcs, cbs, ccs),
  "[0.5em]\n",
  sprintf("Dep.\\ var.\\ mean & %.4f & %.4f & %.4f & %.4f \\\\\n",
          sumstats$mean_has_viol, sumstats$mean_viols, sumstats$mean_has_viol, sumstats$mean_viols),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nrow(panel), big.mark=","), format(nrow(panel), big.mark=","),
          format(nrow(panel), big.mark=","), format(nrow(panel), big.mark=",")),
  sprintf("Systems & %s & %s & %s & %s \\\\\n",
          format(sumstats$n_systems, big.mark=","), format(sumstats$n_systems, big.mark=","),
          format(sumstats$n_systems, big.mark=","), format(sumstats$n_systems, big.mark=",")),
  "System FE & Yes & Yes & -- & -- \\\\\n",
  "Quarter FE & Yes & Yes & -- & -- \\\\\n",
  "Clustering & State & State & State & State \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2) report two-way fixed effects estimates. ",
  "Columns (3)--(4) report Callaway and Sant'Anna (2021) staggered DiD estimates. ",
  "Binary = indicator for any health-based violation. Count = number of violations. ",
  "Standard errors clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Robustness
# ============================================================================
cat("Generating Table 3\n")

pb <- coef(placebo_twfe)["post_placebo"]
pbs <- sqrt(vcov(placebo_twfe)["post_placebo","post_placebo"])
poi <- coef(poisson_fit)["post"]
pois <- sqrt(vcov(poisson_fit)["post","post"])
cab <- coef(ca_twfe)["post"]
cas <- sqrt(vcov(ca_twfe)["post","post"])

tab3 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Placebo & Poisson & California \\\\\n\\hline\n",
  sprintf("Post $\\times$ Treated & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          pb, stars(pb,pbs), poi, stars(poi,pois), cab, stars(cab,cas)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n", pbs, pois, cas),
  "[0.5em]\n",
  "Outcome & Binary & Count & Binary \\\\\n",
  "Estimator & TWFE & Poisson FE & TWFE \\\\\n",
  "Sample & Never-treated & Full & California \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nrow(panel[treated == FALSE]), big.mark=","),
          format(nrow(panel), big.mark=","),
          format(nrow(panel[state == "CA"]), big.mark=",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1): random placebo timing on never-treated. ",
  "Column (2): Poisson FE for violation counts. ",
  "Column (3): California only (SB 88 mandatory consolidation). ",
  "Standard errors clustered at state (1--2) or system (3) level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab3, file.path(tables_dir, "tab3_robust.tex"))

# ============================================================================
# Table 4: Dose-Response
# ============================================================================
cat("Generating Table 4\n")

dc <- coef(dose_fit); dv <- vcov(dose_fit)

tab4 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Dose-Response: Effect by Population Absorbed}\n\\label{tab:dose}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n\\hline\\hline\n",
  " & Health Violation (0/1) \\\\\n\\hline\n",
  sprintf("Post (Low dose) & %.4f%s \\\\\n", dc["post"], stars(dc["post"], sqrt(dv["post","post"]))),
  sprintf(" & (%.4f) \\\\\n", sqrt(dv["post","post"])),
  sprintf("Post $\\times$ Medium dose & %.4f%s \\\\\n",
          dc["post:medium"], stars(dc["post:medium"], sqrt(dv["post:medium","post:medium"]))),
  sprintf(" & (%.4f) \\\\\n", sqrt(dv["post:medium","post:medium"])),
  sprintf("Post $\\times$ High dose & %.4f%s \\\\\n",
          dc["post:high"], stars(dc["post:high"], sqrt(dv["post:high","post:high"]))),
  sprintf(" & (%.4f) \\\\\n", sqrt(dv["post:high","post:high"])),
  "[0.5em]\n",
  "System FE & Yes \\\\\nQuarter FE & Yes \\\\\n",
  "Sample & Treated only \\\\\n",
  sprintf("Observations & %s \\\\\n", format(nrow(panel[treated == TRUE]), big.mark=",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dose terciles based on total population of deactivated neighbor systems. ",
  "Standard errors clustered at state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab4, file.path(tables_dir, "tab4_dose.tex"))

# ============================================================================
# Table 5: Event Study
# ============================================================================
cat("Generating Table 5\n")

es <- fread(file.path(data_dir, "event_study_data.csv"))
es_disp <- es[e >= -8 & e <= 12]

rows <- sapply(1:nrow(es_disp), function(i) {
  r <- es_disp[i]
  sprintf("$e = %+d$ & %.4f%s & (%.4f) \\\\\n", r$e, r$att, stars(r$att, r$se), r$se)
})

tab5 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Dynamic Treatment Effects: Event Study Coefficients}\n\\label{tab:event_study}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  "Quarters relative to & ATT & SE \\\\\n",
  "neighbor deactivation & & \\\\\n\\hline\n",
  paste0(rows, collapse = ""),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATTs aggregated to event time. ",
  "Doubly robust estimation with never-treated as control. State-clustered SEs. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab5, file.path(tables_dir, "tab5_event_study.tex"))

# ============================================================================
# SDE Table (Appendix F1)
# ============================================================================
cat("Generating SDE Table\n")

sd_y_bin <- panel[post == 0, sd(has_violation)]
sd_y_cnt <- panel[post == 0, sd(n_health_viols)]

# Panel A: Pooled
sde_bin <- cb / sd_y_bin; sde_se_bin <- cbs / sd_y_bin
sde_cnt <- cc / sd_y_cnt; sde_se_cnt <- ccs / sd_y_cnt

classify <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneous — by system size
med_pop <- panel[, median(pop_served, na.rm = TRUE)]

# Small systems TWFE (simpler, more robust for V1)
small_fit <- feols(has_violation ~ post | pwsid + qtr_idx,
                    data = panel[pop_served <= med_pop], cluster = ~state)
small_b <- coef(small_fit)["post"]
small_se <- sqrt(vcov(small_fit)["post","post"])
sde_small <- small_b / sd_y_bin
sde_se_small <- small_se / sd_y_bin

# Large systems
large_fit <- feols(has_violation ~ post | pwsid + qtr_idx,
                    data = panel[pop_served > med_pop], cluster = ~state)
large_b <- coef(large_fit)["post"]
large_se <- sqrt(vcov(large_fit)["post","post"])
sde_large <- large_b / sd_y_bin
sde_se_large <- large_se / sd_y_bin

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does absorbing customers from deactivated neighboring community water systems increase health-based drinking water violations in the receiving system? ",
  "\\textbf{Policy mechanism:} When small community water systems fail financially or violate safety standards, state regulators deactivate them and their customers must be served by a neighboring system, creating a sudden capacity and infrastructure shock to the absorbing system. ",
  "\\textbf{Outcome definition:} Quarterly indicator for any health-based Safe Drinking Water Act violation (Maximum Contaminant Level exceedances for arsenic, nitrate, coliform, disinfection byproducts, and other regulated contaminants) in the receiving community water system. ",
  "\\textbf{Treatment:} Binary indicator for whether an active CWS is located in the same ZIP code as a CWS that was deactivated during the sample period. ",
  "\\textbf{Data:} EPA Safe Drinking Water Information System (SDWIS) via Envirofacts API, 2006--2024, quarterly system-level panel, ",
  sprintf("%s system-quarter observations across %s community water systems. ",
          format(nrow(panel), big.mark=","), format(uniqueN(panel$pwsid), big.mark=",")),
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with doubly robust estimation; never-treated systems as control group; standard errors clustered at state level. ",
  "\\textbf{Sample:} Active community water systems with population served $> 0$ and at least 8 pre-treatment quarters; restricted to 2006Q1--2024Q4. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Health violation (0/1) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          cb, cbs, sd_y_bin, sde_bin, sde_se_bin, classify(sde_bin)),
  sprintf("Violation count & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          cc, ccs, sd_y_cnt, sde_cnt, sde_se_cnt, classify(sde_cnt)),
  "[0.5em]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by system size)}} \\\\\n",
  sprintf("Small systems ($\\leq$ median pop.) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          small_b, small_se, sd_y_bin, sde_small, sde_se_small, classify(sde_small)),
  sprintf("Large systems ($>$ median pop.) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          large_b, large_se, sd_y_bin, sde_large, sde_se_large, classify(sde_large)),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:", paste(list.files(tables_dir), collapse=", "), "\n")
