# ─────────────────────────────────────────────
# 05_tables.R — Generate all tables for paper
# ─────────────────────────────────────────────

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
if (!dir.exists(TABLE_DIR)) dir.create(TABLE_DIR, recursive = TRUE)

load(file.path(DATA_DIR, "main_results.RData"))
load(file.path(DATA_DIR, "robustness_results.RData"))
treatment <- fread(file.path(DATA_DIR, "treatment_panel.csv"), colClasses = c(muni_code = "character"))

# ─────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment period (2014-2020)
pre_panel <- panel[year <= 2020]
treated_pre <- pre_panel[treatment_year > 0]
control_pre <- pre_panel[treatment_year == 0]

make_sumstat_row <- function(data, varname, label) {
  x <- data[[varname]]
  sprintf("  %s & %.1f & %.1f & %.1f & %.1f \\\\",
          label,
          mean(x, na.rm = TRUE),
          sd(x, na.rm = TRUE),
          min(x, na.rm = TRUE),
          max(x, na.rm = TRUE))
}

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (2014--2020)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Privatized Municipalities (N = ",
  sprintf("%s)}} \\\\", format(uniqueN(treated_pre$muni_code), big.mark = ",")),
  make_sumstat_row(treated_pre, "hosp_rate", "Waterborne hosp.\\ rate (per 100K)"),
  make_sumstat_row(treated_pre, "under5_rate", "Under-5 hosp.\\ rate (per 100K)"),
  make_sumstat_row(treated_pre, "cost_per_cap", "Hosp.\\ cost per capita (BRL)"),
  sprintf("  Population & %s & %s & %s & %s \\\\",
          format(round(mean(treated_pre$population)), big.mark = ","),
          format(round(sd(treated_pre$population)), big.mark = ","),
          format(round(min(treated_pre$population)), big.mark = ","),
          format(round(max(treated_pre$population)), big.mark = ",")),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Never-Privatized Municipalities (N = ",
  sprintf("%s)}} \\\\", format(uniqueN(control_pre$muni_code), big.mark = ",")),
  make_sumstat_row(control_pre, "hosp_rate", "Waterborne hosp.\\ rate (per 100K)"),
  make_sumstat_row(control_pre, "under5_rate", "Under-5 hosp.\\ rate (per 100K)"),
  make_sumstat_row(control_pre, "cost_per_cap", "Hosp.\\ cost per capita (BRL)"),
  sprintf("  Population & %s & %s & %s & %s \\\\",
          format(round(mean(control_pre$population)), big.mark = ","),
          format(round(sd(control_pre$population)), big.mark = ","),
          format(round(min(control_pre$population)), big.mark = ","),
          format(round(max(control_pre$population)), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Summary statistics for the pre-treatment period (2014--2020). Privatized municipalities are those that transitioned to private water/sanitation providers following the 2020 Marco Legal do Saneamento: Alagoas Block A (2021, N = %d), CEDAE/Rio de Janeiro (2022, N = %d), Corsan/Rio Grande do Sul (2023, N = %d). Waterborne diseases defined as ICD-10 A00--A09 (intestinal infectious diseases). Data: DATASUS SIH (hospitalization records) and IBGE population estimates.",
          sum(treatment$wave == "Alagoas_BRK"),
          sum(treatment$wave == "CEDAE_RJ"),
          sum(treatment$wave == "Corsan_RS")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_summary.tex"))

# ─────────────────────────────────────────────
# Table 2: Main Results
# ─────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

# CS estimates
att_cs <- agg_simple$overall.att
se_cs <- agg_simple$overall.se
p_cs <- 2 * pnorm(-abs(att_cs / se_cs))

# Under-5 CS
att_u5 <- agg_under5$overall.att
se_u5 <- agg_under5$overall.se
p_u5 <- 2 * pnorm(-abs(att_u5 / se_u5))

# TWFE estimates
att_twfe <- coef(twfe)["treated"]
se_twfe <- se(twfe)["treated"]
p_twfe <- pvalue(twfe)["treated"]

att_twfe_r <- coef(twfe_region)["treated"]
se_twfe_r <- se(twfe_region)["treated"]
p_twfe_r <- pvalue(twfe_region)["treated"]

# CS never-treated
att_nt <- agg_never$overall.att
se_nt <- agg_never$overall.se
p_nt <- 2 * pnorm(-abs(att_nt / se_nt))

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Sanitation Privatization on Waterborne Disease Hospitalizations}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & CS-DR & CS-DR & TWFE & TWFE & CS-DR \\\\",
  " & All ages & Under-5 & Baseline & Region$\\times$Year & Never-treated \\\\",
  "\\midrule",
  sprintf("  Privatized & %.2f%s & %.2f%s & %.2f%s & %.2f%s & %.2f%s \\\\",
          att_cs, stars(p_cs), att_u5, stars(p_u5),
          att_twfe, stars(p_twfe), att_twfe_r, stars(p_twfe_r),
          att_nt, stars(p_nt)),
  sprintf("  & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
          se_cs, se_u5, se_twfe, se_twfe_r, se_nt),
  "\\\\",
  sprintf("  Mean dep.\\ var. & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(panel$hosp_rate_w), mean(panel$under5_rate_w),
          mean(panel$hosp_rate_w), mean(panel$hosp_rate_w), mean(panel$hosp_rate_w)),
  sprintf("  Municipalities & %s & %s & %s & %s & %s \\\\",
          format(uniqueN(panel$muni_id), big.mark = ","),
          format(uniqueN(panel$muni_id), big.mark = ","),
          format(uniqueN(panel$muni_id), big.mark = ","),
          format(uniqueN(panel$muni_id), big.mark = ","),
          format(uniqueN(panel$muni_id), big.mark = ",")),
  sprintf("  Observations & %s & %s & %s & %s & %s \\\\",
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  "  Estimator & CS & CS & TWFE & TWFE & CS \\\\",
  "  Control group & Not-yet & Not-yet & All & All & Never \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(2) and (5) report Callaway--Sant'Anna (2021) doubly robust estimates with 1 year of anticipation allowed. Column (1): overall ATT on waterborne hospitalization rate per 100K. Column (2): ATT on under-5 waterborne hospitalization rate. Columns (3)--(4): two-way fixed effects estimates. Column (5): CS estimates using only never-treated municipalities as controls. Standard errors clustered at the municipality level in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(TABLE_DIR, "tab2_main.tex"))

# ─────────────────────────────────────────────
# Table 3: Event Study Coefficients
# ─────────────────────────────────────────────
cat("Generating Table 3: Event Study...\n")

agg_es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 3)

es_rows <- character(0)
for (i in seq_along(agg_es$egt)) {
  e <- agg_es$egt[i]
  att_e <- agg_es$att.egt[i]
  se_e <- agg_es$se.egt[i]
  p_e <- 2 * pnorm(-abs(att_e / se_e))
  label <- ifelse(e < 0, sprintf("$t%d$", e), ifelse(e == 0, "$t$", sprintf("$t+%d$", e)))
  es_rows <- c(es_rows,
               sprintf("  %s & %.2f%s \\\\", label, att_e, stars(p_e)),
               sprintf("  & (%.2f) \\\\", se_e))
}

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Dynamic Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & Waterborne hosp.\\ rate \\\\",
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Pre-treatment}} \\\\",
  es_rows[1:(2 * length(agg_es$egt[agg_es$egt < 0]))],
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Post-treatment}} \\\\",
  es_rows[(2 * length(agg_es$egt[agg_es$egt < 0]) + 1):length(es_rows)],
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Callaway--Sant'Anna (2021) group-time ATT estimates aggregated to event time. Not-yet-treated control group, doubly robust estimation, 1 year of anticipation. Standard errors clustered at municipality level. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(TABLE_DIR, "tab3_eventstudy.tex"))

# ─────────────────────────────────────────────
# Table 4: Heterogeneity by Wave
# ─────────────────────────────────────────────
cat("Generating Table 4: Heterogeneity by Wave...\n")

# Group-specific ATTs
group_atts <- data.table(
  group = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt
)
group_atts[, pval := 2 * pnorm(-abs(att / se))]

# Corsan subsample
att_cors <- agg_corsan$overall.att
se_cors <- agg_corsan$overall.se
p_cors <- 2 * pnorm(-abs(att_cors / se_cors))

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity by Privatization Wave}",
  "\\label{tab:heterogeneity}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Alagoas & CEDAE/RJ & Corsan/RS & Corsan Only \\\\",
  " & (2021) & (2022) & (2023) & (South sample) \\\\",
  "\\midrule"
)

# Add group ATTs
for (i in seq_len(nrow(group_atts))) {
  g <- group_atts[i]
  wave_label <- ifelse(g$group == 2021, "Alagoas (2021)",
                ifelse(g$group == 2022, "CEDAE/RJ (2022)", "Corsan/RS (2023)"))
}

# Build rows dynamically based on available groups
wave_atts <- character(0)
wave_ses <- character(0)
for (yr in c(2021, 2022, 2023)) {
  row <- group_atts[group == yr]
  if (nrow(row) > 0) {
    wave_atts <- c(wave_atts, sprintf("%.2f%s", row$att, stars(row$pval)))
    wave_ses <- c(wave_ses, sprintf("(%.2f)", row$se))
  } else {
    wave_atts <- c(wave_atts, "--")
    wave_ses <- c(wave_ses, "")
  }
}

tab4_lines <- c(tab4_lines,
  sprintf("  ATT & %s & %s & %s & %.2f%s \\\\",
          wave_atts[1], wave_atts[2], wave_atts[3], att_cors, stars(p_cors)),
  sprintf("  & %s & %s & %s & (%.2f) \\\\",
          wave_ses[1], wave_ses[2], wave_ses[3], se_cors),
  "\\\\",
  sprintf("  Treated municipalities & %d & %d & %d & %d \\\\",
          sum(panel$treatment_year == 2021 & panel$year == 2021),
          sum(panel$treatment_year == 2022 & panel$year == 2022),
          sum(panel$treatment_year == 2023 & panel$year == 2023),
          uniqueN(panel[state_code %in% c("43") & treatment_year > 0]$muni_code)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(3) report group-specific ATT estimates from the Callaway--Sant'Anna estimator. Column (4) restricts the sample to Southern states (RS, SC, PR) to isolate the Corsan privatization wave (Dec 2022) from potential COVID confounding. Standard errors clustered at municipality level. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_heterogeneity.tex"))

# ─────────────────────────────────────────────
# Table 5: Robustness
# ─────────────────────────────────────────────
cat("Generating Table 5: Robustness...\n")

# Cost outcome
att_cost <- coef(twfe_cost)["treated"]
se_cost_val <- se(twfe_cost)["treated"]
p_cost <- pvalue(twfe_cost)["treated"]

# Raw (unwinsorized)
att_raw <- coef(twfe_raw)["treated"]
se_raw <- se(twfe_raw)["treated"]
p_raw <- pvalue(twfe_raw)["treated"]

# Log
att_log <- coef(twfe_log)["treated"]
se_log_val <- se(twfe_log)["treated"]
p_log <- pvalue(twfe_log)["treated"]

# Large municipalities
att_large <- coef(twfe_large)["treated"]
se_large <- se(twfe_large)["treated"]
p_large <- pvalue(twfe_large)["treated"]

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & No winsor. & Log rate & Pop $\\geq$ 5K & Cost/cap \\\\",
  "\\midrule",
  sprintf("  Privatized & %.2f%s & %.2f%s & %.3f%s & %.2f%s & %.2f%s \\\\",
          coef(twfe)["treated"], stars(pvalue(twfe)["treated"]),
          att_raw, stars(p_raw),
          att_log, stars(p_log),
          att_large, stars(p_large),
          att_cost, stars(p_cost)),
  sprintf("  & (%.2f) & (%.2f) & (%.3f) & (%.2f) & (%.2f) \\\\",
          se(twfe)["treated"], se_raw, se_log_val, se_large, se_cost_val),
  "\\\\",
  sprintf("  Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(twfe), big.mark = ","),
          format(nobs(twfe_raw), big.mark = ","),
          format(nobs(twfe_log), big.mark = ","),
          format(nobs(twfe_large), big.mark = ","),
          format(nobs(twfe_cost), big.mark = ",")),
  "  Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "  Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All columns report TWFE estimates with municipality and year fixed effects, standard errors clustered at the municipality level. Column (1): baseline specification with winsorized hospitalization rate. Column (2): unwinsorized rate. Column (3): log(rate + 1). Column (4): excluding municipalities with population below 5,000. Column (5): hospitalization cost per capita (BRL per 1,000 population). $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab5_lines, file.path(TABLE_DIR, "tab5_robustness.tex"))

# ─────────────────────────────────────────────
# SDE Table (Appendix F1)
# ─────────────────────────────────────────────
cat("Generating SDE Table...\n")

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

# Main outcome: waterborne hospitalization rate
sd_y_hosp <- sd(panel$hosp_rate_w, na.rm = TRUE)
sde_hosp <- att_cs / sd_y_hosp
se_sde_hosp <- se_cs / sd_y_hosp

# Under-5 outcome
sd_y_u5 <- sd(panel$under5_rate_w, na.rm = TRUE)
sde_u5 <- agg_under5$overall.att / sd_y_u5
se_sde_u5 <- agg_under5$overall.se / sd_y_u5

# Cost outcome
sd_y_cost <- sd(panel$cost_per_cap, na.rm = TRUE)
sde_cost <- att_cost / sd_y_cost
se_sde_cost <- se_cost_val / sd_y_cost

# Heterogeneity: Corsan subsample
rs_sd <- sd(panel[state_code %in% c("43", "42", "41")]$hosp_rate_w, na.rm = TRUE)
sde_corsan <- att_cors / rs_sd
se_sde_corsan <- se_cors / rs_sd

# Large municipalities
large_sd <- sd(panel[population >= 5000]$hosp_rate_w, na.rm = TRUE)
sde_large <- att_large / large_sd
se_sde_large <- se_large / large_sd

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does privatizing municipal water and sanitation services under Brazil's 2020 Marco Legal do Saneamento reduce waterborne disease hospitalizations? ",
  "\\textbf{Policy mechanism:} Law 14,026 of July 2020 mandated competitive bidding for all sanitation concessions, triggering the transfer of water and sewage services from public utilities to private operators across three major BNDES-organized auction waves, with private operators contractually committed to expanding coverage and improving treatment infrastructure. ",
  "\\textbf{Outcome definition:} Annual municipality-level hospitalization rate per 100,000 population for intestinal infectious diseases (ICD-10 A00--A09) from DATASUS Hospital Information System (SIH). ",
  "\\textbf{Treatment:} Binary: municipality's first full year under a private sanitation provider, identified from BNDES auction records. ",
  "\\textbf{Data:} DATASUS SIH hospitalization microdata linked to IBGE population estimates, 2014--2023, municipality-year panel for 11 Brazilian states. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered difference-in-differences with doubly robust estimation, not-yet-treated control group, and 1 year of anticipation; standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} Municipalities in treated states (Alagoas, Rio de Janeiro, Rio Grande do Sul) and neighboring control states (Sergipe, Pernambuco, Bahia, S\\~{a}o Paulo, Minas Gerais, Esp\\'{i}rito Santo, Santa Catarina, Paran\\'{a}). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Waterborne hosp.\\ rate & CS-DR & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          att_cs, se_cs, sd_y_hosp, sde_hosp, se_sde_hosp, classify_sde(sde_hosp)),
  sprintf("Under-5 hosp.\\ rate & CS-DR & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          agg_under5$overall.att, agg_under5$overall.se, sd_y_u5, sde_u5, se_sde_u5, classify_sde(sde_u5)),
  sprintf("Hosp.\\ cost per capita & TWFE & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          att_cost, se_cost_val, sd_y_cost, sde_cost, se_sde_cost, classify_sde(sde_cost)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Hosp.\\ rate (Corsan/South) & CS-DR & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          att_cors, se_cors, rs_sd, sde_corsan, se_sde_corsan, classify_sde(sde_corsan)),
  sprintf("Hosp.\\ rate (Pop $\\geq$ 5K) & TWFE & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          att_large, se_large, large_sd, sde_large, se_sde_large, classify_sde(sde_large)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("\nAll tables generated successfully.\n")
cat(sprintf("  tab1_summary.tex\n  tab2_main.tex\n  tab3_eventstudy.tex\n"))
cat(sprintf("  tab4_heterogeneity.tex\n  tab5_robustness.tex\n  tabF1_sde.tex\n"))
