# 05_tables.R — Generate all LaTeX tables for apep_1086
# CAA Attainment Redesignation and the Environmental Ratchet
# ============================================================

# ---------- Resolve script directory ----------
this_file <- tryCatch(
  normalizePath(sys.frame(1)$ofile),
  error = function(e) NULL
)
if (is.null(this_file)) {
  # Fallback: assume working directory is the code/ folder or its parent
  if (file.exists("00_packages.R")) {
    this_file <- normalizePath("05_tables.R")
  } else if (file.exists("code/00_packages.R")) {
    this_file <- normalizePath("code/05_tables.R")
  } else {
    stop("Cannot determine script location. Run from code/ or its parent directory.")
  }
}
code_dir <- dirname(this_file)

source(file.path(code_dir, "00_packages.R"))

# ---------- Paths ----------
base_dir   <- dirname(code_dir)
data_dir   <- file.path(base_dir, "data")
tables_dir <- file.path(base_dir, "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ---------- Load results ----------
main_res <- readRDS(file.path(data_dir, "main_results.rds"))
rob_res  <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel    <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Results loaded.\n")

# ==============================================================================
# Helper: write character vector to file
# ==============================================================================
write_tex <- function(lines, filename) {
  writeLines(lines, file.path(tables_dir, filename))
  cat("Wrote", filename, "\n")
}

# Helper: format numbers
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
fmt_pct <- function(x, digits = 3) formatC(x, format = "f", digits = digits)

# Helper: stars from p-value
stars <- function(p) {
  ifelse(p < 0.001, "^{***}",
  ifelse(p < 0.01,  "^{**}",
  ifelse(p < 0.05,  "^{*}",
  ifelse(p < 0.10,  "^{\\dagger}", ""))))
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
make_tab1 <- function() {
  treated_panel  <- panel[panel$ever_treated == TRUE, ]
  control_panel  <- panel[panel$ever_treated == FALSE, ]

  n_treated <- length(unique(treated_panel$fips))
  n_control <- length(unique(control_panel$fips))
  nobs_treated <- nrow(treated_panel)
  nobs_control <- nrow(control_panel)

  # Compute means and SDs for each group
  vars_info <- list(
    list(var = "mfg_emp",       label = "Manufacturing Employment"),
    list(var = "log_mfg_emp",   label = "Log Manufacturing Employment"),
    list(var = "mean_conc_PM25", label = "PM$_{2.5}$ ($\\mu$g/m$^3$)"),
    list(var = "mfg_hires",     label = "Manufacturing Hires"),
    list(var = "mfg_seps",      label = "Manufacturing Separations"),
    list(var = "mfg_earnings",  label = "Manufacturing Earnings (\\$/qtr)")
  )

  rows <- character(0)
  for (v in vars_info) {
    t_vals <- treated_panel[[v$var]]
    c_vals <- control_panel[[v$var]]
    t_vals <- t_vals[!is.na(t_vals)]
    c_vals <- c_vals[!is.na(c_vals)]

    # Use integer formatting for levels, decimal for logs/concentrations
    if (v$var %in% c("log_mfg_emp", "mean_conc_PM25")) {
      t_mean <- fmt(mean(t_vals), 2)
      t_sd   <- fmt(sd(t_vals), 2)
      c_mean <- fmt(mean(c_vals), 2)
      c_sd   <- fmt(sd(c_vals), 2)
    } else {
      t_mean <- fmt_int(round(mean(t_vals)))
      t_sd   <- fmt_int(round(sd(t_vals)))
      c_mean <- fmt_int(round(mean(c_vals)))
      c_sd   <- fmt_int(round(sd(c_vals)))
    }

    rows <- c(rows, paste0(
      "  ", v$label, " & ", t_mean, " & ", t_sd,
      " & ", c_mean, " & ", c_sd, " \\\\"
    ))
  }

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\begin{threeparttable}",
    "\\caption{Summary Statistics: Treated vs.\\ Control Counties}",
    "\\label{tab:summary}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    " & \\multicolumn{2}{c}{Redesignated} & \\multicolumn{2}{c}{Never-Designated} \\\\",
    "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
    " & Mean & SD & Mean & SD \\\\",
    "\\midrule",
    rows,
    "\\midrule",
    paste0("  Counties & \\multicolumn{2}{c}{", fmt_int(n_treated),
           "} & \\multicolumn{2}{c}{", fmt_int(n_control), "} \\\\"),
    paste0("  County-Year Observations & \\multicolumn{2}{c}{", fmt_int(nobs_treated),
           "} & \\multicolumn{2}{c}{", fmt_int(nobs_control), "} \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Sample spans 2001--2019. Redesignated counties are those that transitioned from CAA nonattainment to attainment/maintenance status during the sample period. Never-designated counties had no nonattainment history. PM$_{2.5}$ statistics are conditional on having an EPA AQS monitor in the county. Manufacturing employment, hires, separations, and earnings are from the Census Quarterly Workforce Indicators (QWI).",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  write_tex(tex, "tab1_summary.tex")
}

# ==============================================================================
# TABLE 2: Main Results
# ==============================================================================
make_tab2 <- function() {
  # Extract coefficients and SEs from fixest models
  extract_fixest <- function(mod) {
    ct <- coeftable(mod)
    list(
      coef = ct[1, "Estimate"],
      se   = ct[1, "Std. Error"],
      pval = ct[1, "Pr(>|t|)"],
      nobs = nobs(mod),
      ar2  = fitstat(mod, "ar2")[[1]]
    )
  }

  m_emp      <- extract_fixest(main_res$twfe_emp)
  m_hires    <- extract_fixest(main_res$twfe_hires)
  m_seps     <- extract_fixest(main_res$twfe_seps)
  m_earnings <- extract_fixest(main_res$twfe_earnings)

  # CS simple ATT
  cs_att <- main_res$cs_simple$overall.att
  cs_se  <- main_res$cs_simple$overall.se
  cs_p   <- 2 * pnorm(-abs(cs_att / cs_se))  # two-sided z-test
  # N for CS: same as twfe_emp panel
  cs_nobs <- nobs(main_res$twfe_emp)

  # Format a coefficient cell
  coef_cell <- function(b, se, p) {
    paste0("$", fmt(b), stars(p), "$ \\\\ & $(", fmt(se), ")$")
  }
  # For level outcomes (hires/seps) use fewer decimal places
  coef_cell_int <- function(b, se, p) {
    paste0("$", fmt(b, 1), stars(p), "$ \\\\ & $(", fmt(se, 1), ")$")
  }

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Effect of CAA Redesignation on Manufacturing Activity}",
    "\\label{tab:main}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    " & (1) & (2) & (3) & (4) & (5) \\\\",
    " & Log Emp. & Log Emp. & Hires & Separations & Log Earn. \\\\",
    " & TWFE & CS & TWFE & TWFE & TWFE \\\\",
    "\\midrule",
    # Post coefficient row
    paste0("Post $\\times$ Treated & ",
      "$", fmt(m_emp$coef), stars(m_emp$pval), "$ & ",
      "$", fmt(cs_att), stars(cs_p), "$ & ",
      "$", fmt(m_hires$coef, 1), stars(m_hires$pval), "$ & ",
      "$", fmt(m_seps$coef, 1), stars(m_seps$pval), "$ & ",
      "$", fmt(m_earnings$coef), stars(m_earnings$pval), "$ \\\\"),
    # SE row
    paste0(" & ",
      "$(", fmt(m_emp$se), ")$ & ",
      "$(", fmt(cs_se), ")$ & ",
      "$(", fmt(m_hires$se, 1), ")$ & ",
      "$(", fmt(m_seps$se, 1), ")$ & ",
      "$(", fmt(m_earnings$se), ")$ \\\\"),
    "\\midrule",
    paste0("County FE & Yes & --- & Yes & Yes & Yes \\\\"),
    paste0("Year FE & Yes & --- & Yes & Yes & Yes \\\\"),
    paste0("Estimator & TWFE & CS-DR & TWFE & TWFE & TWFE \\\\"),
    paste0("Observations & ", fmt_int(m_emp$nobs), " & ", fmt_int(cs_nobs),
           " & ", fmt_int(m_hires$nobs), " & ", fmt_int(m_seps$nobs),
           " & ", fmt_int(m_earnings$nobs), " \\\\"),
    paste0("Adj.\\ $R^2$ & ", fmt(m_emp$ar2, 3), " & --- & ",
           fmt(m_hires$ar2, 3), " & ", fmt(m_seps$ar2, 3), " & ",
           fmt(m_earnings$ar2, 3), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "",
    "\\vspace{0.3em}",
    "{\\small \\textit{Notes:} $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$. TWFE columns report two-way fixed effects estimates with standard errors clustered at the county level. Column (2) reports Callaway and Sant'Anna (2021) doubly robust ATT with analytical standard errors, using never-treated counties as controls. Hires and separations are in levels; employment and earnings are in logs.}",
    "\\end{table}"
  )

  write_tex(tex, "tab2_main.tex")
}

# ==============================================================================
# TABLE 3: CS Dynamic Event Study
# ==============================================================================
make_tab3 <- function() {
  dyn <- main_res$cs_dynamic
  egt    <- dyn$egt
  att    <- dyn$att.egt
  se_egt <- dyn$se.egt
  crit   <- dyn$crit.val.egt

  # Determine significance using simultaneous confidence bands
  sig <- abs(att / se_egt) > crit

  rows <- character(0)
  for (i in seq_along(egt)) {
    e <- egt[i]
    a <- att[i]
    s <- se_egt[i]
    star_str <- if (sig[i]) "$^{*}$" else ""

    rows <- c(rows, paste0(
      "  $", ifelse(e >= 0, paste0("+"), ""), e, "$ & ",
      fmt(a), star_str, " & (",
      fmt(s), ") & [",
      fmt(a - crit * s), ", ",
      fmt(a + crit * s), "] \\\\"
    ))

    # Add midrule between pre and post
    if (e == -1) {
      rows <- c(rows, "  \\midrule")
    }
  }

  # Overall dynamic ATT
  overall_att <- dyn$overall.att
  overall_se  <- dyn$overall.se

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Dynamic Treatment Effects: Callaway--Sant'Anna Event Study}",
    "\\label{tab:event}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    "Event Time & ATT$(e)$ & (SE) & 95\\% Simult.\\ CB \\\\",
    "\\midrule",
    "\\multicolumn{4}{l}{\\textit{Pre-treatment}} \\\\",
    rows[1:5],  # e = -5 to -1
    "\\midrule",  # already inserted by the loop but we replace
    "\\multicolumn{4}{l}{\\textit{Post-treatment}} \\\\",
    rows[7:length(rows)],  # e = 0 to +5 (rows[6] is the midrule)
    "\\midrule",
    paste0("Overall ATT & ", fmt(overall_att), " & (",
           fmt(overall_se), ") & \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "",
    "\\vspace{0.3em}",
    "{\\small \\textit{Notes:} $^{*}$ denotes that the simultaneous confidence band excludes zero. Callaway and Sant'Anna (2021) doubly robust estimator with never-treated counties as controls. Standard errors are analytical; simultaneous confidence bands account for multiple testing across event times.}",
    "\\end{table}"
  )

  write_tex(tex, "tab3_event.tex")
}

# ==============================================================================
# TABLE 4: Robustness
# ==============================================================================
make_tab4 <- function() {
  extract_fixest <- function(mod) {
    ct <- coeftable(mod)
    # Handle different coefficient names
    idx <- 1
    list(
      coef = ct[idx, "Estimate"],
      se   = ct[idx, "Std. Error"],
      pval = ct[idx, "Pr(>|t|)"],
      nobs = nobs(mod),
      ar2  = fitstat(mod, "ar2")[[1]],
      n_counties = length(fixef(mod)$fips)
    )
  }

  baseline  <- extract_fixest(main_res$twfe_emp)
  placebo   <- extract_fixest(rob_res$placebo_twfe)
  ever_na   <- extract_fixest(rob_res$twfe_ever_na)
  no2005    <- extract_fixest(rob_res$twfe_no2005)
  no2007    <- extract_fixest(rob_res$twfe_no2007)

  models <- list(baseline, placebo, ever_na, no2005, no2007)
  col_labels <- c("Baseline", "Placebo", "Ever-NA", "Excl.\\ 2005", "Excl.\\ 2007")

  # Build coefficient row
  coef_row <- paste0("Post $\\times$ Treated")
  se_row   <- ""
  nobs_row <- "Observations"
  nc_row   <- "Counties"
  ar2_row  <- "Adj.\\ $R^2$"

  for (m in models) {
    coef_row <- paste0(coef_row, " & $", fmt(m$coef), stars(m$pval), "$")
    se_row   <- paste0(se_row, " & $(", fmt(m$se), ")$")
    nobs_row <- paste0(nobs_row, " & ", fmt_int(m$nobs))
    nc_row   <- paste0(nc_row, " & ", fmt_int(m$n_counties))
    ar2_row  <- paste0(ar2_row, " & ", fmt(m$ar2, 3))
  }

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Robustness Checks: Log Manufacturing Employment}",
    "\\label{tab:robustness}",
    "\\begin{tabular}{lccccc}",
    "\\toprule",
    paste0(" & (1) & (2) & (3) & (4) & (5) \\\\"),
    paste0(" & ", paste(col_labels, collapse = " & "), " \\\\"),
    "\\midrule",
    paste0(coef_row, " \\\\"),
    paste0(se_row, " \\\\"),
    "\\midrule",
    "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
    "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
    paste0(nc_row, " \\\\"),
    paste0(nobs_row, " \\\\"),
    paste0(ar2_row, " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "",
    "\\vspace{0.3em}",
    "{\\small \\textit{Notes:} $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$. All specifications use TWFE with county and year fixed effects. Standard errors clustered at the county level. Column (1): full sample baseline. Column (2): placebo test assigning fake treatment to never-treated counties. Column (3): restricts control group to counties with any nonattainment history (ever-nonattainment). Column (4): excludes the 2005 redesignation cohort. Column (5): excludes the 2007 redesignation cohort.}",
    "\\end{table}"
  )

  write_tex(tex, "tab4_robustness.tex")
}

# ==============================================================================
# TABLE 5: Air Quality Results
# ==============================================================================
make_tab5 <- function() {
  extract_fixest <- function(mod) {
    ct <- coeftable(mod)
    list(
      coef = ct[1, "Estimate"],
      se   = ct[1, "Std. Error"],
      pval = ct[1, "Pr(>|t|)"],
      nobs = nobs(mod),
      ar2  = fitstat(mod, "ar2")[[1]],
      n_counties = length(fixef(mod)$fips)
    )
  }

  pm25 <- extract_fixest(main_res$twfe_pm25)
  o3   <- extract_fixest(main_res$twfe_o3)

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Effect of CAA Redesignation on Ambient Air Quality}",
    "\\label{tab:pollution}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    " & (1) & (2) \\\\",
    " & PM$_{2.5}$ ($\\mu$g/m$^3$) & Ozone (ppm) \\\\",
    "\\midrule",
    "\\multicolumn{3}{l}{\\textit{Panel A: Fine Particulate Matter (PM$_{2.5}$)}} \\\\[0.3em]",
    paste0("Post $\\times$ Treated & $", fmt(pm25$coef), stars(pm25$pval), "$ & \\\\"),
    paste0(" & $(", fmt(pm25$se), ")$ & \\\\"),
    paste0("Counties & ", fmt_int(pm25$n_counties), " & \\\\"),
    paste0("Observations & ", fmt_int(pm25$nobs), " & \\\\"),
    paste0("Adj.\\ $R^2$ & ", fmt(pm25$ar2, 3), " & \\\\"),
    "\\midrule",
    "\\multicolumn{3}{l}{\\textit{Panel B: Ground-Level Ozone}} \\\\[0.3em]",
    paste0("Post $\\times$ Treated & & $", fmt(o3$coef, 4), stars(o3$pval), "$ \\\\"),
    paste0(" & & $(", fmt(o3$se, 4), ")$ \\\\"),
    paste0("Counties & & ", fmt_int(o3$n_counties), " \\\\"),
    paste0("Observations & & ", fmt_int(o3$nobs), " \\\\"),
    paste0("Adj.\\ $R^2$ & & ", fmt(o3$ar2, 3), " \\\\"),
    "\\midrule",
    "County FE & Yes & Yes \\\\",
    "Year FE & Yes & Yes \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "",
    "\\vspace{0.3em}",
    "{\\small \\textit{Notes:} $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{\\dagger}p<0.10$. TWFE estimates with county and year fixed effects. Standard errors clustered at the county level. PM$_{2.5}$ is mean annual concentration in $\\mu$g/m$^3$; ozone is mean annual fourth-highest daily maximum 8-hour concentration in ppm. Sample restricted to counties with EPA AQS monitors.}",
    "\\end{table}"
  )

  write_tex(tex, "tab5_pollution.tex")
}

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (Appendix)
# ==============================================================================
make_tabF1 <- function() {
  # ---------- Compute SD(Y) from the panel ----------
  sd_log_emp     <- sd(panel$log_mfg_emp, na.rm = TRUE)
  sd_pm25        <- sd(panel$mean_conc_PM25, na.rm = TRUE)
  sd_o3          <- sd(panel$mean_conc_O3, na.rm = TRUE)

  # For heterogeneous: compute SD within each subsample
  sd_log_emp_hi  <- sd(panel$log_mfg_emp[panel$high_mfg == TRUE], na.rm = TRUE)
  sd_log_emp_lo  <- sd(panel$log_mfg_emp[panel$high_mfg == FALSE], na.rm = TRUE)

  # ---------- Extract coefficients ----------
  extract_fixest <- function(mod) {
    ct <- coeftable(mod)
    list(coef = ct[1, "Estimate"], se = ct[1, "Std. Error"])
  }

  emp_main <- extract_fixest(main_res$twfe_emp)
  pm25_main <- extract_fixest(main_res$twfe_pm25)
  o3_main  <- extract_fixest(main_res$twfe_o3)
  hi_mfg   <- extract_fixest(rob_res$twfe_high_mfg)
  lo_mfg   <- extract_fixest(rob_res$twfe_low_mfg)

  # ---------- Compute SDE and SE(SDE) ----------
  # SDE = beta / SD(Y); SE(SDE) = SE(beta) / SD(Y)
  compute_sde <- function(beta, se, sd_y) {
    list(
      sde    = beta / sd_y,
      se_sde = se / sd_y,
      sd_y   = sd_y
    )
  }

  sde_emp  <- compute_sde(emp_main$coef, emp_main$se, sd_log_emp)
  sde_pm25 <- compute_sde(pm25_main$coef, pm25_main$se, sd_pm25)
  sde_o3   <- compute_sde(o3_main$coef, o3_main$se, sd_o3)
  sde_hi   <- compute_sde(hi_mfg$coef, hi_mfg$se, sd_log_emp_hi)
  sde_lo   <- compute_sde(lo_mfg$coef, lo_mfg$se, sd_log_emp_lo)

  # ---------- Classification ----------
  classify <- function(sde_val) {
    if (sde_val < -0.15) return("Large negative")
    if (sde_val < -0.05) return("Moderate negative")
    if (sde_val < -0.005) return("Small negative")
    if (sde_val <= 0.005) return("Null")
    if (sde_val <= 0.05) return("Small positive")
    if (sde_val <= 0.15) return("Moderate positive")
    return("Large positive")
  }

  # ---------- Build rows ----------
  sde_row <- function(label, beta, se, sd_y, sde, se_sde) {
    cls <- classify(sde)
    paste0("  ", label, " & ",
      fmt(beta, 4), " & ", fmt(se, 4), " & ", fmt(sd_y, 3),
      " & ", fmt(sde, 4), " & ", fmt(se_sde, 4),
      " & ", cls, " \\\\")
  }

  tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Standardized Effect Sizes}",
    "\\label{tab:sde}",
    "\\small",
    "\\begin{tabular}{lcccccc}",
    "\\toprule",
    "Outcome & $\\hat{\\beta}$ & SE & SD$(Y)$ & SDE & SE(SDE) & Classification \\\\",
    "\\midrule",
    "\\multicolumn{7}{l}{\\textit{Panel A: Pooled Effects}} \\\\[0.3em]",
    sde_row("Log Mfg.\\ Employment",
            emp_main$coef, emp_main$se, sde_emp$sd_y,
            sde_emp$sde, sde_emp$se_sde),
    sde_row("PM$_{2.5}$ ($\\mu$g/m$^3$)",
            pm25_main$coef, pm25_main$se, sde_pm25$sd_y,
            sde_pm25$sde, sde_pm25$se_sde),
    sde_row("Ozone (ppm)",
            o3_main$coef, o3_main$se, sde_o3$sd_y,
            sde_o3$sde, sde_o3$se_sde),
    "\\midrule",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous Effects (Log Mfg.\\ Employment)}} \\\\[0.3em]",
    sde_row("High-Manufacturing Counties",
            hi_mfg$coef, hi_mfg$se, sde_hi$sd_y,
            sde_hi$sde, sde_hi$se_sde),
    sde_row("Low-Manufacturing Counties",
            lo_mfg$coef, lo_mfg$se, sde_lo$sd_y,
            sde_lo$sde, sde_lo$se_sde),
    "\\bottomrule",
    "\\end{tabular}",
    "",
    "\\vspace{0.5em}",
    "\\begin{minipage}{\\textwidth}",
    "\\small",
    "\\textbf{Country:} United States. \\\\",
    "\\textbf{Research question:} Does EPA redesignation from nonattainment to attainment status cause a rebound in manufacturing activity or ambient air pollution? \\\\",
    "\\textbf{Policy mechanism:} Redesignation removes New Source Review requirements, Reasonably Available Control Technology mandates, and emission offset obligations for new and modified stationary sources. \\\\",
    "\\textbf{Outcome definition:} Log quarterly manufacturing employment (NAICS 31--33) from QWI and mean annual PM$_{2.5}$ concentration ($\\mu$g/m$^3$) from EPA AQS monitors. \\\\",
    "\\textbf{Treatment:} Binary; county transitions from CAA nonattainment to attainment/maintenance status. \\\\",
    paste0("\\textbf{Data:} EPA Green Book designation history, Census QWI, and EPA AQS, 2001--2019, county-year panel, ",
           fmt_int(nrow(panel)), " observations. \\\\"),
    paste0("\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with never-treated controls, doubly robust estimation, standard errors clustered at county level. \\\\"),
    paste0("\\textbf{Sample:} ", fmt_int(length(unique(panel$fips[panel$ever_treated == TRUE]))),
           " redesignated counties and ",
           fmt_int(length(unique(panel$fips[panel$ever_treated == FALSE]))),
           " never-designated controls; restricted to redesignation years 2002--2019 with at least one pre-treatment year. \\\\[0.5em]"),
    "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).",
    "\\end{minipage}",
    "\\end{table}"
  )

  write_tex(tex, "tabF1_sde.tex")
}

# ==============================================================================
# Generate all tables
# ==============================================================================
cat("\n=== Generating tables ===\n")
make_tab1()
make_tab2()
make_tab3()
make_tab4()
make_tab5()
make_tabF1()
cat("\nAll tables generated successfully.\n")
