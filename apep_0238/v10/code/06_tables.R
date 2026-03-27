# ── apep_0238 v10: Tables ─────────────────────────────────────────────────
# 6 main tables + SDE appendix table

# Source packages - detect script dir robustly
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg) > 0) {
  .script_dir <- dirname(normalizePath(sub("^--file=", "", .file_arg)))
} else {
  .script_dir <- getwd()
}
source(file.path(.script_dir, "00_packages.R"))
suppressPackageStartupMessages(library(lubridate))

dat <- readRDS(file.path(DATA_DIR, "analysis_data.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
mech <- readRDS(file.path(DATA_DIR, "mechanism_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

# ══════════════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════════

cat("Table 1: Summary statistics...\n")

exposure <- dat$exposure
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & Mean & Std. Dev. & Min & Max & N \\\\",
  "\\midrule",
  sprintf("Housing price boom (log, 2003--2006) & %s & %s & %s & %s & 50 \\\\",
          fmt(mean(exposure$hpi_boom), 3), fmt(sd(exposure$hpi_boom), 3),
          fmt(min(exposure$hpi_boom), 3), fmt(max(exposure$hpi_boom), 3)),
  sprintf("COVID Bartik shock (raw) & %s & %s & %s & %s & 50 \\\\",
          fmt(mean(exposure$bartik_covid), 4), fmt(sd(exposure$bartik_covid), 4),
          fmt(min(exposure$bartik_covid), 4), fmt(max(exposure$bartik_covid), 4)),
  sprintf("Saiz supply elasticity & %s & %s & %s & %s & 50 \\\\",
          fmt(mean(-exposure$saiz), 2), fmt(sd(-exposure$saiz), 2),
          fmt(min(-exposure$saiz), 2), fmt(max(-exposure$saiz), 2)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Housing price boom is the log change in the FHFA state-level house price index from 2003Q1 to 2006Q4. COVID Bartik shock is constructed using pre-pandemic (2019) industry employment shares weighted by leave-one-out national industry employment changes (Feb--Apr 2020). Saiz supply elasticity is from \\citet{saiz2010geographic}, measuring geographic constraints on housing supply.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(TAB_DIR, "tab1_summary.tex"))

# ══════════════════════════════════════════════════════════════════════════
# Table 2: Episode-Specific Long-Run Regressions
# ══════════════════════════════════════════════════════════════════════════

cat("Table 2: Episode-specific regressions...\n")

gr <- results$analysis_gr
covid <- results$analysis_covid

if ("avg_d_log_emp" %in% names(gr)) {
  fit_gr <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region), data = gr)
  ct_gr <- coeftest(fit_gr, vcov = vcovHC(fit_gr, type = "HC1"))

  fit_covid <- lm(avg_d_log_emp ~ bartik_covid_sd + log_emp_peak_covid + pre_growth_covid + factor(region), data = covid)
  ct_covid <- coeftest(fit_covid, vcov = vcovHC(fit_covid, type = "HC1"))

  tab2_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Long-Run Employment Response to Recession Exposure}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "& Great Recession & COVID-19 \\\\",
    "& (avg months 48--120) & (avg months 24--48) \\\\",
    "\\midrule",
    sprintf("Exposure & $%s%s$ & $%s%s$ \\\\",
            fmt(ct_gr["hpi_boom", 1]), stars(ct_gr["hpi_boom", 4]),
            fmt(ct_covid["bartik_covid_sd", 1]), stars(ct_covid["bartik_covid_sd", 4])),
    sprintf("& (%s) & (%s) \\\\",
            fmt(ct_gr["hpi_boom", 2]), fmt(ct_covid["bartik_covid_sd", 2])),
    sprintf("$R^2$ & %s & %s \\\\",
            fmt(summary(fit_gr)$r.squared, 3), fmt(summary(fit_covid)$r.squared, 3)),
    "\\midrule",
    "$N$ & 50 & 50 \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each column reports the coefficient from a cross-state regression of average log employment change over the specified horizon window on recession exposure. Great Recession exposure is the 2003--2006 housing price boom (log change). COVID exposure is the standardized Bartik shock (mean zero, unit variance). Controls: log pre-recession employment, pre-recession employment growth, census region indicators. Robust (HC1) standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:main}",
    "\\end{table}"
  )
  writeLines(tab2_lines, file.path(TAB_DIR, "tab2_main_regressions.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Table 3: Pooled Interaction
# ══════════════════════════════════════════════════════════════════════════

cat("Table 3: Pooled interaction...\n")

if (!is.null(results$fit_pooled)) {
  tab3_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Pooled Interaction: Is Great Recession Scarring Larger Than COVID?}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lc}",
    "\\toprule",
    "& Avg. Log Employment Change \\\\",
    "\\midrule",
    sprintf("Exposure (SD) & $%s%s$ \\\\", fmt(results$fit_pooled$coefficients["exposure_sd", 1]),
            stars(results$fit_pooled$coefficients["exposure_sd", 4])),
    sprintf("& (%s) \\\\", fmt(results$fit_pooled$coefficients["exposure_sd", 2])),
    sprintf("Exposure $\\times$ GR & $%s%s$ \\\\", fmt(results$fit_pooled$coefficients["exposure_x_gr", 1]),
            stars(results$fit_pooled$coefficients["exposure_x_gr", 4])),
    sprintf("& (%s) \\\\", fmt(results$fit_pooled$coefficients["exposure_x_gr", 2])),
    "\\midrule",
    "$N$ & 100 \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Pooled regression stacking GR and COVID observations. Exposure is standardized to unit variance within each episode. The interaction term (Exposure $\\times$ GR) tests whether GR scarring exceeds COVID scarring. A significant negative coefficient indicates the Great Recession produced larger long-run employment deficits per unit of exposure. HC1 standard errors. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:pooled}",
    "\\end{table}"
  )
  writeLines(tab3_lines, file.path(TAB_DIR, "tab3_pooled_interaction.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Table 4: CPS Mechanism Regressions (UR persistence)
# ══════════════════════════════════════════════════════════════════════════

cat("Table 4: Mechanism regressions...\n")

if (!is.null(mech$ur_lp_gr) && !is.null(mech$ur_lp_covid)) {
  ur_gr <- mech$ur_lp_gr
  ur_covid <- mech$ur_lp_covid

  # Build table rows for selected horizons
  tab4_header <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Unemployment Rate Response: Duration Trap Evidence}",
    "\\begin{threeparttable}",
    "\\small",
    "\\begin{tabular}{lcccccc}",
    "\\toprule",
    "& $h=6$ & $h=12$ & $h=24$ & $h=36$ & $h=48$ \\\\",
    "\\midrule"
  )

  gr_row <- "\\textit{Great Recession (HPI)}"
  for (h in c(6, 12, 24, 36, 48)) {
    r <- ur_gr[horizon == h]
    if (nrow(r) > 0) {
      gr_row <- paste0(gr_row, sprintf(" & $%s%s$", fmt(r$coef, 3), stars(r$pval)))
    } else {
      gr_row <- paste0(gr_row, " & ---")
    }
  }
  gr_row <- paste0(gr_row, " \\\\")

  gr_se_row <- ""
  for (h in c(6, 12, 24, 36, 48)) {
    r <- ur_gr[horizon == h]
    if (nrow(r) > 0) {
      gr_se_row <- paste0(gr_se_row, sprintf(" & (%s)", fmt(r$se, 3)))
    } else {
      gr_se_row <- paste0(gr_se_row, " &")
    }
  }
  gr_se_row <- paste0(gr_se_row, " \\\\[6pt]")

  covid_row <- "\\textit{COVID (Bartik SD)}"
  for (h in c(6, 12, 24, 36, 48)) {
    r <- ur_covid[horizon == h]
    if (nrow(r) > 0) {
      covid_row <- paste0(covid_row, sprintf(" & $%s%s$", fmt(r$coef, 3), stars(r$pval)))
    } else {
      covid_row <- paste0(covid_row, " & ---")
    }
  }
  covid_row <- paste0(covid_row, " \\\\")

  covid_se_row <- ""
  for (h in c(6, 12, 24, 36, 48)) {
    r <- ur_covid[horizon == h]
    if (nrow(r) > 0) {
      covid_se_row <- paste0(covid_se_row, sprintf(" & (%s)", fmt(r$se, 3)))
    } else {
      covid_se_row <- paste0(covid_se_row, " &")
    }
  }
  covid_se_row <- paste0(covid_se_row, " \\\\")

  tab4_lines <- c(tab4_header, gr_row, gr_se_row, covid_row, covid_se_row,
    "\\midrule",
    "$N$ & \\multicolumn{5}{c}{50} \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each cell reports the coefficient from a cross-state regression of the unemployment rate change (percentage points) on recession exposure at horizon $h$ months. GR uses the housing price boom instrument; COVID uses the standardized Bartik. Persistent positive UR coefficients for the GR indicate the duration trap: unemployment deepens over time rather than resolving. HC1 standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:mechanism}",
    "\\end{table}"
  )
  writeLines(tab4_lines, file.path(TAB_DIR, "tab4_mechanism.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Table 5: Duration-Trap Attenuation
# ══════════════════════════════════════════════════════════════════════════

cat("Table 5: Duration-trap attenuation...\n")

# Re-run the attenuation regressions to obtain HC1 standard errors
# (mechanism_results.rds only stores scalar coefficients)
panel <- dat$panel
gr <- dat$analysis_gr

# Compute UR change at h=24 from peak for GR
ur_peak_gr <- panel[date == GR_PEAK, .(state, ur_peak = ur)]
ur_h24_gr <- panel[date == GR_PEAK %m+% months(24), .(state, ur_h24 = ur)]
ur_change_gr <- merge(ur_peak_gr, ur_h24_gr, by = "state")
ur_change_gr[, d_ur_24 := ur_h24 - ur_peak]

gr_mech <- merge(gr, ur_change_gr[, .(state, d_ur_24)], by = "state")

if ("avg_d_log_emp" %in% names(gr_mech) && "d_ur_24" %in% names(gr_mech)) {
  fit_base <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                 data = gr_mech)
  ct_base <- coeftest(fit_base, vcov = vcovHC(fit_base, type = "HC1"))

  fit_med <- lm(avg_d_log_emp ~ hpi_boom + d_ur_24 + log_emp_peak_gr + pre_growth_gr + factor(region),
                data = gr_mech)
  ct_med <- coeftest(fit_med, vcov = vcovHC(fit_med, type = "HC1"))

  coef_b <- ct_base["hpi_boom", 1]
  se_b   <- ct_base["hpi_boom", 2]
  coef_m <- ct_med["hpi_boom", 1]
  se_m   <- ct_med["hpi_boom", 2]
  att    <- 1 - coef_m / coef_b

  tab5_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Duration-Trap Attenuation: How Much Does Unemployment Persistence Explain?}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    "& Baseline & + UR($h$=24) & Attenuation \\\\",
    "\\midrule",
    sprintf("HPI coefficient & $%s%s$ & $%s%s$ & %s\\%% \\\\",
            fmt(coef_b), stars(ct_base["hpi_boom", 4]),
            fmt(coef_m), stars(ct_med["hpi_boom", 4]),
            formatC(att * 100, format = "f", digits = 1)),
    sprintf("& (%s) & (%s) & \\\\", fmt(se_b), fmt(se_m)),
    "\\midrule",
    "$N$ & 50 & 50 & \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Baseline regresses average long-run log employment (months 48--120) on HPI boom with standard controls. The second column adds the state-level unemployment rate change at $h=24$ months as a mediator. Attenuation measures the fraction of the HPI coefficient absorbed by the duration-trap proxy. If unemployment duration fully explains scarring, the HPI coefficient should approach zero when duration measures are included. HC1 standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:attenuation}",
    "\\end{table}"
  )
  writeLines(tab5_lines, file.path(TAB_DIR, "tab5_attenuation.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Table 6: Robustness
# ══════════════════════════════════════════════════════════════════════════

cat("Table 6: Robustness...\n")

if (!is.null(rob$window_dt)) {
  tab6_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Robustness: Window Choice, Controls, and Samples}",
    "\\begin{threeparttable}",
    "\\small",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Specification & Coef. & SE & $p$-value & Perm. $p$ \\\\",
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{Panel A: Window robustness}} \\\\[3pt]"
  )
  for (i in 1:nrow(rob$window_dt)) {
    r <- rob$window_dt[i]
    tab6_lines <- c(tab6_lines,
      sprintf("Months %s & $%s%s$ & (%s) & %s & [%s] \\\\",
              r$window, fmt(r$coef), stars(r$pval), fmt(r$se), fmt(r$pval, 3), fmt(r$perm_p, 3)))
  }

  if (!is.null(rob$control_results)) {
    tab6_lines <- c(tab6_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Panel B: Control robustness}} \\\\[3pt]")
    for (i in 1:nrow(rob$control_results)) {
      r <- rob$control_results[i]
      perm_cell <- if ("perm_p" %in% names(r) && !is.na(r$perm_p)) {
        sprintf("[%s]", fmt(r$perm_p, 3))
      } else {
        "---"
      }
      tab6_lines <- c(tab6_lines,
        sprintf("%s & $%s%s$ & (%s) & %s & %s \\\\",
                r$spec, fmt(r$coef), stars(r$pval), fmt(r$se), fmt(r$pval, 3), perm_cell))
    }
  }

  if (!is.null(rob$nosand_coef)) {
    tab6_lines <- c(tab6_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Panel C: Sample robustness}} \\\\[3pt]",
      sprintf("Drop Sand States ($N$=46) & $%s%s$ & (%s) & %s & --- \\\\",
              fmt(rob$nosand_coef[1]), stars(rob$nosand_coef[4]),
              fmt(rob$nosand_coef[2]), fmt(rob$nosand_coef[4], 3)))
  }

  tab6_lines <- c(tab6_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} All specifications regress average long-run log employment change on the HPI boom instrument with census region indicators. Panel A varies the averaging window for the dependent variable. Panel B adds pre-2007 construction and manufacturing employment shares. Panel C drops Nevada, Arizona, Florida, and California. HC1 standard errors in parentheses. Permutation $p$-values in brackets (1,000 reassignments); --- indicates permutation inference was not computed for that specification. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:robustness}",
    "\\end{table}"
  )
  writeLines(tab6_lines, file.path(TAB_DIR, "tab6_robustness.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Appendix Table A: Full LP Dynamic Estimates
# ══════════════════════════════════════════════════════════════════════════

cat("Appendix Table A: Full LP dynamic estimates...\n")

lp_gr <- results$lp_gr
lp_covid <- results$lp_covid

if (!is.null(lp_gr) && !is.null(lp_covid)) {
  # Filter out h=0 (trivially zero)
  lp_gr_tab <- lp_gr[horizon > 0]
  lp_covid_tab <- lp_covid[horizon > 0]

  tabA_dyn_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Local Projection Dynamic Estimates: Horizon-by-Horizon Results}",
    "\\begin{threeparttable}",
    "\\small",
    "\\begin{tabular}{lcccccc}",
    "\\toprule",
    "& \\multicolumn{3}{c}{Great Recession (HPI)} & \\multicolumn{3}{c}{COVID-19 (Bartik SD)} \\\\",
    "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
    "Horizon & Coef. & SE & Perm.~$p$ & Coef. & SE & Perm.~$p$ \\\\",
    "\\midrule"
  )

  # All unique horizons across both episodes
  all_h <- sort(unique(c(lp_gr_tab$horizon, lp_covid_tab$horizon)))
  for (h in all_h) {
    rg <- lp_gr_tab[horizon == h]
    rc <- lp_covid_tab[horizon == h]
    gr_coef <- if (nrow(rg) > 0) sprintf("$%s%s$", fmt(rg$coef), stars(rg$pval)) else "---"
    gr_se   <- if (nrow(rg) > 0) sprintf("(%s)", fmt(rg$se)) else ""
    gr_perm <- if (nrow(rg) > 0) sprintf("[%s]", fmt(rg$perm_p, 3)) else ""
    cv_coef <- if (nrow(rc) > 0) sprintf("$%s%s$", fmt(rc$coef), stars(rc$pval)) else "---"
    cv_se   <- if (nrow(rc) > 0) sprintf("(%s)", fmt(rc$se)) else ""
    cv_perm <- if (nrow(rc) > 0) sprintf("[%s]", fmt(rc$perm_p, 3)) else ""
    tabA_dyn_lines <- c(tabA_dyn_lines,
      sprintf("$h$=%d & %s & %s & %s & %s & %s & %s \\\\",
              h, gr_coef, gr_se, gr_perm, cv_coef, cv_se, cv_perm))
  }

  tabA_dyn_lines <- c(tabA_dyn_lines,
    "\\midrule",
    "$N$ & \\multicolumn{3}{c}{50} & \\multicolumn{3}{c}{50} \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each row reports the local projection coefficient at horizon $h$ months from a cross-state regression of log employment change on recession exposure. GR exposure is the 2003--2006 housing price boom (log change). COVID exposure is the standardized Bartik shock. All specifications include log pre-recession employment, pre-recession employment growth, and census region indicators. HC1 standard errors in parentheses. Permutation $p$-values in brackets (1,000 reassignments). $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:dynamic}",
    "\\end{table}"
  )
  writeLines(tabA_dyn_lines, file.path(TAB_DIR, "tabA_dynamic.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Appendix Table B: Saiz IV Results
# ══════════════════════════════════════════════════════════════════════════

cat("Appendix Table B: Saiz IV results...\n")

iv_dt <- results$iv_dt

if (!is.null(iv_dt)) {
  tabA_iv_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Instrumental Variable Estimates: Saiz Housing Supply Elasticity}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    "& $h=12$ & $h=24$ & $h=48$ \\\\",
    "\\midrule",
    "\\textit{OLS}"
  )

  # OLS row
  ols_row <- ""
  for (i in 1:nrow(iv_dt)) {
    ols_row <- paste0(ols_row, sprintf(" & $%s$", fmt(iv_dt$ols[i])))
  }
  ols_row <- paste0(ols_row, " \\\\")
  tabA_iv_lines <- c(tabA_iv_lines, ols_row)

  # IV coefficient row
  iv_row <- "\\textit{IV (Saiz)}"
  for (i in 1:nrow(iv_dt)) {
    iv_row <- paste0(iv_row, sprintf(" & $%s$", fmt(iv_dt$iv[i])))
  }
  iv_row <- paste0(iv_row, " \\\\")
  tabA_iv_lines <- c(tabA_iv_lines, iv_row)

  # IV SE row
  iv_se_row <- ""
  for (i in 1:nrow(iv_dt)) {
    iv_se_row <- paste0(iv_se_row, sprintf(" & (%s)", fmt(iv_dt$iv_se[i])))
  }
  iv_se_row <- paste0(iv_se_row, " \\\\")
  tabA_iv_lines <- c(tabA_iv_lines, iv_se_row)

  # First-stage F if available
  if (!is.null(results$fs_f)) {
    tabA_iv_lines <- c(tabA_iv_lines,
      "\\midrule",
      sprintf("First-stage $F$ & \\multicolumn{3}{c}{%s} \\\\",
              formatC(results$fs_f, format = "f", digits = 1)))
  }

  tabA_iv_lines <- c(tabA_iv_lines,
    "\\midrule",
    "$N$ & \\multicolumn{3}{c}{50} \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} OLS and 2SLS estimates of the effect of the 2003--2006 housing price boom on log employment change at horizons $h$=12, 24, and 48 months. The instrument is the negative of the Saiz (2010) state-level housing supply elasticity, which predicts housing price booms through geographic constraints on construction. Controls: log pre-recession employment, pre-recession employment growth, census region indicators. HC1 standard errors for IV in parentheses.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:iv}",
    "\\end{table}"
  )
  writeLines(tabA_iv_lines, file.path(TAB_DIR, "tabA_iv.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# Appendix Table C: Horse Race (HPI vs GR Bartik)
# ══════════════════════════════════════════════════════════════════════════

cat("Appendix Table C: Horse race results...\n")

horse_dt <- results$horse_dt

if (!is.null(horse_dt)) {
  tabA_horse_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Horse Race: Housing Price Boom vs.\\ Great Recession Bartik Shock}",
    "\\begin{threeparttable}",
    "\\small",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    sprintf("& $h$=%d & $h$=%d & $h$=%d & $h$=%d \\\\",
            horse_dt$horizon[1], horse_dt$horizon[2], horse_dt$horizon[3], horse_dt$horizon[4]),
    "\\midrule",
    "\\textit{HPI boom}"
  )

  # HPI coefficient row
  hpi_coef_row <- ""
  for (i in 1:nrow(horse_dt)) {
    hpi_coef_row <- paste0(hpi_coef_row,
      sprintf(" & $%s%s$", fmt(horse_dt$hpi_coef[i]), stars(horse_dt$hpi_p[i])))
  }
  hpi_coef_row <- paste0(hpi_coef_row, " \\\\")
  tabA_horse_lines <- c(tabA_horse_lines, hpi_coef_row)

  # HPI SE row
  hpi_se_row <- ""
  for (i in 1:nrow(horse_dt)) {
    hpi_se_row <- paste0(hpi_se_row, sprintf(" & (%s)", fmt(horse_dt$hpi_se[i])))
  }
  hpi_se_row <- paste0(hpi_se_row, " \\\\[6pt]")
  tabA_horse_lines <- c(tabA_horse_lines, hpi_se_row)

  # Bartik coefficient row
  bartik_coef_row <- "\\textit{GR Bartik}"
  for (i in 1:nrow(horse_dt)) {
    bartik_coef_row <- paste0(bartik_coef_row,
      sprintf(" & $%s%s$", fmt(horse_dt$bartik_coef[i]), stars(horse_dt$bartik_p[i])))
  }
  bartik_coef_row <- paste0(bartik_coef_row, " \\\\")
  tabA_horse_lines <- c(tabA_horse_lines, bartik_coef_row)

  # Bartik SE row
  bartik_se_row <- ""
  for (i in 1:nrow(horse_dt)) {
    bartik_se_row <- paste0(bartik_se_row, sprintf(" & (%s)", fmt(horse_dt$bartik_se[i])))
  }
  bartik_se_row <- paste0(bartik_se_row, " \\\\")
  tabA_horse_lines <- c(tabA_horse_lines, bartik_se_row)

  tabA_horse_lines <- c(tabA_horse_lines,
    "\\midrule",
    "$N$ & \\multicolumn{4}{c}{50} \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Both HPI boom and GR Bartik shock are included simultaneously in each regression. The dependent variable is the log employment change at horizon $h$ months from the Great Recession peak. The GR Bartik shock is constructed from pre-2007 industry employment shares weighted by leave-one-out national industry employment changes during 2007--2009. Controls: log pre-recession employment, pre-recession employment growth, census region indicators. HC1 standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:horse}",
    "\\end{table}"
  )
  writeLines(tabA_horse_lines, file.path(TAB_DIR, "tabA_horse.tex"))
}

# ══════════════════════════════════════════════════════════════════════════
# SDE Appendix Table
# ══════════════════════════════════════════════════════════════════════════

cat("SDE table...\n")

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Structured Data Extract (SDE)}",
  "\\begin{threeparttable}",
  "\\small",
  "\\begin{tabular}{ll}",
  "\\toprule",
  "Field & Value \\\\",
  "\\midrule",
  "Paper ID & apep\\_0238\\_v10 \\\\",
  "Title & Demand Recessions Scar, Supply Recessions Don't \\\\",
  "Method & Local Projections (cross-sectional) \\\\",
  "Country & United States \\\\",
  "Unit & State (N=50) \\\\",
  "Period & 2000--2024 \\\\",
  "Outcome & Long-run employment (avg months 48--120) \\\\",
  "Treatment & Housing price boom (GR) / Bartik shock (COVID) \\\\",
  "Main finding & GR exposure $\\rightarrow$ persistent employment deficit; COVID $\\rightarrow$ full recovery \\\\",
  "Mechanism & Duration trap: prolonged unemployment erodes human capital \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{threeparttable}",
  "\\label{tab:sde}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(TAB_DIR, "tabF1_sde.tex"))

cat("Tables complete.\n")
