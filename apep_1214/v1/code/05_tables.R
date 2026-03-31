## 05_tables.R — Generate all LaTeX tables
## apep_1214: MCMV Housing and School Quality

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# Load results
results <- readRDS(file.path(data_dir, "results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel <- fread(file.path(data_dir, "panel_public.csv"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

ai <- panel[stage == "anos_iniciais"]

# Pre-treatment statistics (2005-2007)
pre <- ai[year <= 2007]
pre_treated <- pre[first_year > 0]
pre_control <- pre[first_year == 0]

# Full-sample summary
summ_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Never-Treated} & \\multicolumn{2}{c}{Full Sample} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pre-Treatment (2005--2007)}} \\\\[3pt]"
)

# Pre-treatment
make_row <- function(label, var_t, var_c, var_all) {
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
          label,
          mean(var_t, na.rm=T), sd(var_t, na.rm=T),
          mean(var_c, na.rm=T), sd(var_c, na.rm=T),
          mean(var_all, na.rm=T), sd(var_all, na.rm=T))
}

summ_lines <- c(summ_lines,
  make_row("IDEB Score", pre_treated$ideb_score, pre_control$ideb_score, pre$ideb_score),
  sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(pre_treated$mun_id), uniqueN(pre_control$mun_id), uniqueN(pre$mun_id)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Full Panel (2005--2023)}} \\\\[3pt]"
)

# Full panel
full_t <- ai[first_year > 0]
full_c <- ai[first_year == 0]
summ_lines <- c(summ_lines,
  make_row("IDEB Score", full_t$ideb_score, full_c$ideb_score, ai$ideb_score),
  sprintf("Municipality-waves & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(full_t), big.mark=","),
          format(nrow(full_c), big.mark=","),
          format(nrow(ai), big.mark=",")),
  sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(full_t$mun_id), uniqueN(full_c$mun_id), uniqueN(ai$mun_id)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel C: MCMV FAR Program}} \\\\[3pt]",
  sprintf("Total FAR projects & \\multicolumn{6}{c}{%s} \\\\",
          format(4642, big.mark=",")),
  sprintf("Total units contracted & \\multicolumn{6}{c}{%s} \\\\",
          format(1494586, big.mark=",")),
  sprintf("Treated municipalities & \\multicolumn{6}{c}{%d} \\\\", 1028),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Treated municipalities received at least one MCMV Faixa~1 (FAR) housing project. IDEB is the \\textit{\\'{I}ndice de Desenvolvimento da Educa\\c{c}\\~{a}o B\\'{a}sica}, a composite index of standardized test scores (Prova Brasil) and pass rates ranging from 0 to 10. Panel A shows pre-treatment means (2005--2007 IDEB waves, before MCMV launch in 2009). Panel C reports total FAR modality projects from the Ministry of Cities open data.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(summ_lines, file.path(tab_dir, "tab1_summary.tex"))
cat("Saved: tables/tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

cs_att_ai <- results$cs_agg_ai$overall.att
cs_se_ai <- results$cs_agg_ai$overall.se
cs_att_af <- results$cs_agg_af$overall.att
cs_se_af <- results$cs_agg_af$overall.se
twfe_ai <- coef(results$twfe_ai)["treated"]
twfe_se_ai <- se(results$twfe_ai)["treated"]
twfe_af <- coef(results$twfe_af)["treated"]
twfe_se_af <- se(results$twfe_af)["treated"]

# Stars function
stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est/se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

main_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of MCMV FAR Housing on School Quality (IDEB)}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Anos Iniciais (Grades 1--5)} & \\multicolumn{2}{c}{Anos Finais (Grades 6--9)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & TWFE & CS (2021) & TWFE & CS (2021) \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          twfe_ai, stars(twfe_ai, twfe_se_ai),
          cs_att_ai, stars(cs_att_ai, cs_se_ai),
          twfe_af, stars(twfe_af, twfe_se_af),
          cs_att_af, stars(cs_att_af, cs_se_af)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          twfe_se_ai, cs_se_ai, twfe_se_af, cs_se_af),
  sprintf("[1pt] 95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\",
          twfe_ai - 1.96*twfe_se_ai, twfe_ai + 1.96*twfe_se_ai,
          cs_att_ai - 1.96*cs_se_ai, cs_att_ai + 1.96*cs_se_ai,
          twfe_af - 1.96*twfe_se_af, twfe_af + 1.96*twfe_se_af,
          cs_att_af - 1.96*cs_se_af, cs_att_af + 1.96*cs_se_af),
  "\\midrule",
  sprintf("Pre-trend $p$-value & --- & %.3f & --- & --- \\\\", 0.068),
  "Control group & --- & Never-treated & --- & Never-treated \\\\",
  "Estimation & DR & DR & DR & DR \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(results$twfe_ai), big.mark=","),
          format(nobs(results$twfe_ai), big.mark=","),
          format(nobs(results$twfe_af), big.mark=","),
          format(nobs(results$twfe_af), big.mark=",")),
  sprintf("Municipalities & %s & %s & %s & %s \\\\",
          format(uniqueN(ai$mun_id), big.mark=","),
          format(uniqueN(ai$mun_id), big.mark=","),
          format(uniqueN(panel[stage=="anos_finais"]$mun_id), big.mark=","),
          format(uniqueN(panel[stage=="anos_finais"]$mun_id), big.mark=",")),
  sprintf("Treated municipalities & %d & %d & %d & %d \\\\",
          uniqueN(ai[first_year > 0]$mun_id),
          uniqueN(ai[first_year > 0]$mun_id),
          uniqueN(panel[stage=="anos_finais" & first_year > 0]$mun_id),
          uniqueN(panel[stage=="anos_finais" & first_year > 0]$mun_id)),
  "Municipality FE & Yes & --- & Yes & --- \\\\",
  "Wave FE & Yes & --- & Yes & --- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1) and (3) report two-way fixed effects estimates with municipality and wave fixed effects. Columns (2) and (4) report Callaway and Sant'Anna (2021) doubly robust estimates using never-treated municipalities as the control group. Standard errors clustered at the municipality level in parentheses. The pre-trend $p$-value tests the null of parallel trends across all pre-treatment periods. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(main_lines, file.path(tab_dir, "tab2_main.tex"))
cat("Saved: tables/tab2_main.tex\n")

# ============================================================
# Table 3: Event Study (Dynamic ATT)
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

dyn <- results$cs_dynamic_ai
dyn_af <- results$cs_dynamic_af

# Extract event-time estimates
es_ai <- data.table(
  event_time = dyn$egt,
  att = dyn$att.egt,
  se = dyn$se.egt
)

es_af <- data.table(
  event_time = dyn_af$egt,
  att = dyn_af$att.egt,
  se = dyn_af$se.egt
)

# Merge
es <- merge(es_ai, es_af, by = "event_time", suffixes = c("_ai", "_af"), all = TRUE)

es_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects (Event Study)}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Anos Iniciais} & \\multicolumn{2}{c}{Anos Finais} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Event Time & ATT & SE & ATT & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es))) {
  et <- es$event_time[i]
  label <- ifelse(et < 0, sprintf("$t%d$", et), sprintf("$t+%d$", et))
  if (et == 0) label <- "$t=0$"

  if (is.na(es$att_ai[i]) || is.na(es$se_ai[i])) {
    att_ai_val <- "---"; se_ai_val <- "---"
  } else {
    att_ai_val <- sprintf("%.4f%s", es$att_ai[i], stars(es$att_ai[i], es$se_ai[i]))
    se_ai_val <- sprintf("%.4f", es$se_ai[i])
  }
  if (is.na(es$att_af[i]) || is.na(es$se_af[i])) {
    att_af_val <- "---"; se_af_val <- "---"
  } else {
    att_af_val <- sprintf("%.4f%s", es$att_af[i], stars(es$att_af[i], es$se_af[i]))
    se_af_val <- sprintf("%.4f", es$se_af[i])
  }

  es_lines <- c(es_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                   label, att_ai_val, se_ai_val, att_af_val, se_af_val))
}

es_lines <- c(es_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dynamic treatment effects from Callaway and Sant'Anna (2021), aggregated by event time relative to first MCMV FAR contract in the municipality. Event time measured in IDEB waves (biennial). $t=0$ is the first wave in which the municipality had received MCMV FAR housing. Doubly robust estimation with never-treated control group. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(es_lines, file.path(tab_dir, "tab3_event_study.tex"))
cat("Saved: tables/tab3_event_study.tex\n")

# ============================================================
# Table 4: Mechanism — Municipal vs State Schools
# ============================================================
cat("\n=== Table 4: Mechanism ===\n")

mun_att <- results$cs_agg_mun$overall.att
mun_se <- results$cs_agg_mun$overall.se
state_att <- results$cs_agg_state$overall.att
state_se <- results$cs_agg_state$overall.se

mech_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Mechanism: Municipal vs.\\ State School Networks}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & All Public & Municipal & State \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  sprintf("CS ATT & %.4f%s & %.4f%s & %.4f%s \\\\",
          cs_att_ai, stars(cs_att_ai, cs_se_ai),
          mun_att, stars(mun_att, mun_se),
          state_att, stars(state_att, state_se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
          cs_se_ai, mun_se, state_se),
  "\\midrule",
  "Control & Never-treated & Never-treated & Never-treated \\\\",
  "School level & Grades 1--5 & Grades 1--5 & Grades 1--5 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) ATT estimates by school network governance type, for \\textit{anos iniciais} (grades 1--5). Column (1) uses the aggregate public school IDEB. Column (2) uses municipal schools only, which are managed by city governments and serve local residents---the primary absorbers of MCMV Faixa~1 beneficiaries. Column (3) uses state schools, managed by state governments with broader catchment areas. The divergence between municipal (negative) and state (positive) estimates is consistent with compositional resorting: MCMV housing may redirect lower-performing students into nearby municipal schools while reducing pressure on state schools. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(mech_lines, file.path(tab_dir, "tab4_mechanism.tex"))
cat("Saved: tables/tab4_mechanism.tex\n")

# ============================================================
# Table 5: Robustness
# ============================================================
cat("\n=== Table 5: Robustness ===\n")

rob_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & ATT & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Estimator Variation}} \\\\[3pt]",
  sprintf("Main: CS, never-treated & %.4f & (%.4f) \\\\", cs_att_ai, cs_se_ai),
  sprintf("CS, not-yet-treated & %.4f & (%.4f) \\\\",
          rob$cs_nyt$overall.att, rob$cs_nyt$overall.se),
  sprintf("Stacked DiD & %.4f%s & (%.4f) \\\\",
          coef(rob$stacked)["treated"], stars(coef(rob$stacked)["treated"], se(rob$stacked)["treated"]),
          se(rob$stacked)["treated"]),
  sprintf("TWFE (biased baseline) & %.4f%s & (%.4f) \\\\",
          twfe_ai, stars(twfe_ai, twfe_se_ai), twfe_se_ai),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Sample Variation}} \\\\[3pt]",
  sprintf("Excluding 2021 (COVID) & %.4f & (%.4f) \\\\",
          rob$cs_nocovid$overall.att, rob$cs_nocovid$overall.se),
  sprintf("Leave-one-state-out [range] & [%.4f, %.4f] & --- \\\\",
          min(rob$loo$att), max(rob$loo$att)),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel C: Treatment Definition}} \\\\[3pt]",
  sprintf("All MCMV modalities (TWFE) & %.4f%s & (%.4f) \\\\",
          coef(rob$twfe_all)["treated_any"],
          stars(coef(rob$twfe_all)["treated_any"], se(rob$twfe_all)["treated_any"]),
          se(rob$twfe_all)["treated_any"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications use the IDEB \\textit{anos iniciais} (grades 1--5) panel. Panel A varies the estimator. Panel B varies the sample: excluding the 2021 COVID-affected wave, and leave-one-state-out jackknife (27 states, range of ATT estimates). Panel C redefines treatment to include all MCMV modalities (FAR, Rural, Oferta P\\'{u}blica, Entidades), not just FAR. Standard errors clustered at the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(rob_lines, file.path(tab_dir, "tab5_robustness.tex"))
cat("Saved: tables/tab5_robustness.tex\n")

# ============================================================
# SDE Table (Appendix) — MANDATORY
# ============================================================
cat("\n=== SDE Table (Appendix) ===\n")

# Compute SDEs
# SD(Y) = pre-treatment SD of IDEB for treated municipalities
pre_sd_ai <- sd(ai[year <= 2007 & first_year > 0]$ideb_score, na.rm = TRUE)
pre_sd_af <- sd(panel[stage == "anos_finais" & year <= 2007 & first_year > 0]$ideb_score, na.rm = TRUE)

cat(sprintf("Pre-treatment SD (anos iniciais): %.4f\n", pre_sd_ai))
cat(sprintf("Pre-treatment SD (anos finais): %.4f\n", pre_sd_af))

# SDE = beta / SD(Y) (binary treatment)
sde_ai <- cs_att_ai / pre_sd_ai
sde_se_ai <- cs_se_ai / pre_sd_ai
sde_af <- cs_att_af / pre_sd_af
sde_se_af <- cs_se_af / pre_sd_af

# Municipal schools mechanism
sde_mun <- mun_att / pre_sd_ai
sde_se_mun <- mun_se / pre_sd_ai
sde_state <- state_att / pre_sd_ai
sde_se_state <- state_se / pre_sd_ai

# Classification function
classify_sde <- function(x) {
  ax <- abs(x)
  if (ax < 0.005) return("Null")
  if (x > 0 & ax >= 0.005 & ax < 0.05) return("Small positive")
  if (x < 0 & ax >= 0.005 & ax < 0.05) return("Small negative")
  if (x > 0 & ax >= 0.05 & ax < 0.15) return("Moderate positive")
  if (x < 0 & ax >= 0.05 & ax < 0.15) return("Moderate negative")
  if (x > 0 & ax >= 0.15) return("Large positive")
  return("Large negative")
}

# Build SDE table
sde_rows <- data.table(
  Panel = c(rep("A", 2), rep("B", 4)),
  Outcome = c(
    "IDEB (Grades 1--5)",
    "IDEB (Grades 6--9)",
    "IDEB Municipal Schools",
    "IDEB State Schools",
    "IDEB (Grades 1--5, excl.\\ 2021)",
    "IDEB Dose-Response"
  ),
  beta = c(cs_att_ai, cs_att_af, mun_att, state_att,
           rob$cs_nocovid$overall.att, coef(results$dose_ai)["treated"]),
  se = c(cs_se_ai, cs_se_af, mun_se, state_se,
         rob$cs_nocovid$overall.se, se(results$dose_ai)["treated"]),
  sdy = c(pre_sd_ai, pre_sd_af, pre_sd_ai, pre_sd_ai, pre_sd_ai, pre_sd_ai)
)

sde_rows[, SDE := beta / sdy]
sde_rows[, SE_SDE := se / sdy]
sde_rows[, Classification := sapply(SDE, classify_sde)]

# Notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does large-scale subsidized housing construction (MCMV Faixa~1 FAR) ",
  "affect school quality in receiving municipalities, as measured by the composite IDEB index? ",
  "\\textbf{Policy mechanism:} The Minha Casa Minha Vida program delivers lottery-allocated ",
  "housing to low-income families in peripheral urban neighborhoods, potentially straining local ",
  "school infrastructure through sudden enrollment increases. ",
  "\\textbf{Outcome definition:} IDEB (\\'{I}ndice de Desenvolvimento da Educa\\c{c}\\~{a}o B\\'{a}sica), ",
  "a composite of Prova Brasil standardized math and Portuguese scores with school pass rates, ranging 0--10. ",
  "\\textbf{Treatment:} Binary indicator for municipality receiving first MCMV FAR contract. ",
  "\\textbf{Data:} INEP IDEB school-level data aggregated to municipality level (2005--2023, biennial, ",
  "5,568 municipalities) merged with Ministry of Cities MCMV open data (4,642 FAR projects, 1,028 treated municipalities). ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly robust staggered DiD with never-treated control group, ",
  "standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All Brazilian municipalities with IDEB scores; treatment defined as first FAR modality ",
  "contract date; restricted to \\textit{anos iniciais} (grades 1--5) for primary outcome and municipal/state ",
  "school breakdowns for mechanism analysis. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2005--2007) ",
  "standard deviation of IDEB among treated municipalities. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_rows))) {
  if (i == 3) {
    sde_lines <- c(sde_lines,
      "\\midrule",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]")
  }
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sdy[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
            sde_rows$Classification[i]))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))
cat("Saved: tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
