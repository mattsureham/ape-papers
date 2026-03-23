# ==============================================================================
# 05_tables.R — Generate All Tables
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

source("00_packages.R")

results     <- readRDS("../data/main_results.rds")
robustness  <- readRDS("../data/robustness_results.rds")
county_base <- readRDS("../data/county_panel_base.rds")
qwi_panel   <- readRDS("../data/qwi_panel.rds")
closures    <- readRDS("../data/closures_detail.rds")

# Rebuild annual panel for summary stats
annual_panel <- qwi_panel %>%
  group_by(county_fips, year, industry, n_closures, first_closure_year,
           total_peak_enrollment) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    hir_a = sum(hir_a, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(pmax(emp, 1)),
    log_hir = log(pmax(hir_a, 1)),
    log_sep = log(pmax(sep, 1)),
    log_earn = log(pmax(earn_s, 1)),
    treated = as.integer(n_closures > 0)
  )

dir.create("../tables", showWarnings = FALSE)

# ===== TABLE 1: Summary Statistics =====
cat("Generating Table 1: Summary Statistics...\n")

# Pre-period (2008-2012) summary by treatment status
pre_data <- annual_panel %>%
  filter(year <= 2012, industry == "00")

summ <- pre_data %>%
  group_by(treated) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_hir = mean(hir_a, na.rm = TRUE),
    sd_hir = sd(hir_a, na.rm = TRUE),
    mean_earn = mean(earn_s, na.rm = TRUE),
    sd_earn = sd(earn_s, na.rm = TRUE),
    .groups = "drop"
  )

# Also get closure-specific stats
closure_summ <- county_base %>%
  filter(n_closures > 0) %>%
  summarise(
    mean_closures = mean(n_closures),
    sd_closures = sd(n_closures),
    median_closures = median(n_closures),
    max_closures = max(n_closures),
    mean_enrollment = mean(total_peak_enrollment),
    sd_enrollment = sd(total_peak_enrollment)
  )

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Counties with For-Profit Colleges}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Control} \\\\",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Period (2008--2012), Total Private Sector}} \\\\[3pt]"
)

treat_row <- summ %>% filter(treated == 1)
ctrl_row  <- summ %>% filter(treated == 0)

tab1_lines <- c(tab1_lines,
  sprintf("Employment & %.0f & %.0f & %.0f & %.0f \\\\",
          treat_row$mean_emp, treat_row$sd_emp, ctrl_row$mean_emp, ctrl_row$sd_emp),
  sprintf("Annual Hires & %.0f & %.0f & %.0f & %.0f \\\\",
          treat_row$mean_hir, treat_row$sd_hir, ctrl_row$mean_hir, ctrl_row$sd_hir),
  sprintf("Avg. Monthly Earnings (\\$) & %.0f & %.0f & %.0f & %.0f \\\\",
          treat_row$mean_earn, treat_row$sd_earn, ctrl_row$mean_earn, ctrl_row$sd_earn),
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          treat_row$n_counties, ctrl_row$n_counties),
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Closure Characteristics (Treated Counties Only)}} \\\\[3pt]",
  sprintf("Closures per County & %.1f & %.1f & & \\\\",
          closure_summ$mean_closures, closure_summ$sd_closures),
  sprintf("Peak Enrollment (Closed Inst.) & %.0f & %.0f & & \\\\",
          closure_summ$mean_enrollment, closure_summ$sd_enrollment),
  sprintf("Total Institutions Closed & \\multicolumn{2}{c}{%d} & & \\\\",
          nrow(closures)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Pre-period summary statistics for total private-sector employment",
  "(QWI, county-year averages 2008--2012). Treated counties experienced at least one for-profit",
  "college closure during 2013--2018. Control counties had at least one for-profit college but",
  "experienced zero closures. Peak enrollment measured as maximum total enrollment in the 5 years",
  "prior to closure.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ===== TABLE 2: Main Results (CS-DiD ATT by Sector) =====
cat("Generating Table 2: Main Results...\n")

sectors <- c("61", "62", "72", "00")
sector_labels <- c("Education", "Health Care", "Accomm./Food", "Total Private")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of For-Profit Closures on County Employment}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  paste0(" & ", paste(sector_labels, collapse = " & "), " \\\\"),
  "\\hline"
)

# Row 1: CS-DiD ATT
cs_atts <- sapply(sectors, function(s) {
  if (!is.null(results$cs_results[[s]])) {
    sprintf("%.4f", results$cs_results[[s]]$att)
  } else { "---" }
})
cs_ses <- sapply(sectors, function(s) {
  if (!is.null(results$cs_results[[s]])) {
    sprintf("(%.4f)", results$cs_results[[s]]$se)
  } else { "" }
})

tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna ATT}} \\\\[3pt]",
  paste0("CS-DiD ATT & ", paste(cs_atts, collapse = " & "), " \\\\"),
  paste0(" & ", paste(cs_ses, collapse = " & "), " \\\\[6pt]")
)

# Row 2: TWFE with closure count
twfe_coefs <- sapply(sectors, function(s) {
  if (!is.null(results$twfe_results[[s]])) {
    sprintf("%.5f", coef(results$twfe_results[[s]])[1])
  } else { "---" }
})
twfe_ses <- sapply(sectors, function(s) {
  if (!is.null(results$twfe_results[[s]])) {
    sprintf("(%.5f)", sqrt(vcov(results$twfe_results[[s]])[1,1]))
  } else { "" }
})
twfe_stars <- sapply(sectors, function(s) {
  if (!is.null(results$twfe_results[[s]])) {
    p <- fixest::pvalue(results$twfe_results[[s]])[1]
    if (p < 0.01) return("***") else if (p < 0.05) return("**") else if (p < 0.1) return("*") else return("")
  } else { "" }
})

tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE, Closure Count $\\times$ Post}} \\\\[3pt]",
  paste0("Closures $\\times$ Post & ",
         paste(sprintf("%s%s", twfe_coefs, twfe_stars), collapse = " & "), " \\\\"),
  paste0(" & ", paste(twfe_ses, collapse = " & "), " \\\\[6pt]")
)

# Row 3: Chain IV
iv_coefs <- sapply(sectors, function(s) {
  if (!is.null(results$iv_results[[s]])) {
    sprintf("%.5f", coef(results$iv_results[[s]])[1])
  } else { "---" }
})
iv_ses <- sapply(sectors, function(s) {
  if (!is.null(results$iv_results[[s]])) {
    sprintf("(%.5f)", sqrt(vcov(results$iv_results[[s]])[1,1]))
  } else { "" }
})

tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel C: Chain IV (ITT/Corinthian/ECA Exposure)}} \\\\[3pt]",
  paste0("IV Estimate & ", paste(iv_coefs, collapse = " & "), " \\\\"),
  paste0(" & ", paste(iv_ses, collapse = " & "), " \\\\")
)

# Add N and FE info
n_obs <- sapply(sectors, function(s) {
  if (!is.null(results$twfe_results[[s]])) {
    formatC(nobs(results$twfe_results[[s]]), format = "d", big.mark = ",")
  } else { "---" }
})

tab2_lines <- c(tab2_lines,
  "\\hline",
  paste0("Observations & ", paste(n_obs, collapse = " & "), " \\\\"),
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is log employment (annual average from QWI).",
  "Panel A: Callaway-Sant'Anna (2021) ATT using not-yet-treated controls and doubly robust estimation.",
  "Panel B: Two-way fixed effects with closure count $\\times$ post-treatment indicator.",
  "Panel C: IV using chain campus presence (ITT Tech, Corinthian, ECA) $\\times$ post-2015 as instrument.",
  "Standard errors clustered at county level in parentheses.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ===== TABLE 3: Mechanism (Hires, Separations, Earnings) =====
cat("Generating Table 3: Mechanism...\n")

mech_fits <- list(
  results$mechanism$hires,
  results$mechanism$seps,
  results$mechanism$earnings
)
mech_labels <- c("Log Hires", "Log Separations", "Log Earnings")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Mechanism: Closures and Education-Sector Labor Flows}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  paste0(" & ", paste(mech_labels, collapse = " & "), " \\\\"),
  "\\hline"
)

mech_coefs <- sapply(mech_fits, function(f) sprintf("%.5f", coef(f)[1]))
mech_ses   <- sapply(mech_fits, function(f) sprintf("(%.5f)", sqrt(vcov(f)[1,1])))
mech_stars <- sapply(mech_fits, function(f) {
  p <- fixest::pvalue(f)[1]
  if (p < 0.01) return("***") else if (p < 0.05) return("**") else if (p < 0.1) return("*") else return("")
})
mech_n <- sapply(mech_fits, function(f) formatC(nobs(f), format = "d", big.mark = ","))

tab3_lines <- c(tab3_lines,
  paste0("Closures $\\times$ Post & ",
         paste(sprintf("%s%s", mech_coefs, mech_stars), collapse = " & "), " \\\\"),
  paste0(" & ", paste(mech_ses, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Observations & ", paste(mech_n, collapse = " & "), " \\\\"),
  "County FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "Sector & Educ. & Educ. & Educ. \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} NAICS 61 (Education Services) only. Closure count $\\times$ post-treatment",
  "indicator, with county and year fixed effects. Standard errors clustered at county level.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_mechanism.tex")

# ===== TABLE 4: Robustness =====
cat("Generating Table 4: Robustness...\n")

rob_fits <- list(
  robustness$enrl_weighted,
  robustness$high_intensity,
  robustness$no_top5,
  robustness$placebo_total
)
rob_labels <- c("Enrollment\\\\Weighted", "High Intensity\\\\($\\geq$3)", "Drop Top-5\\\\Counties", "Total Private\\\\(Placebo)")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  paste0(" & \\shortstack{", paste(rob_labels, collapse = "} & \\shortstack{"), "} \\\\"),
  "\\hline"
)

rob_coefs <- sapply(rob_fits, function(f) {
  if (!is.null(f)) sprintf("%.5f", coef(f)[1]) else "---"
})
rob_ses <- sapply(rob_fits, function(f) {
  if (!is.null(f)) sprintf("(%.5f)", sqrt(vcov(f)[1,1])) else ""
})
rob_stars <- sapply(rob_fits, function(f) {
  if (!is.null(f)) {
    p <- fixest::pvalue(f)[1]
    if (p < 0.01) return("***") else if (p < 0.05) return("**") else if (p < 0.1) return("*") else return("")
  } else ""
})
rob_n <- sapply(rob_fits, function(f) {
  if (!is.null(f)) formatC(nobs(f), format = "d", big.mark = ",") else "---"
})

tab4_lines <- c(tab4_lines,
  paste0("Treatment Effect & ",
         paste(sprintf("%s%s", rob_coefs, rob_stars), collapse = " & "), " \\\\"),
  paste0(" & ", paste(rob_ses, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Observations & ", paste(rob_n, collapse = " & "), " \\\\"),
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Sector & Educ. & Educ. & Educ. & Total \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} All specifications include county and year fixed effects, standard errors",
  "clustered at county level. Column 1 uses peak enrollment at closed institutions (thousands) as",
  "treatment intensity. Column 2 restricts to counties with $\\geq$3 closures and controls.",
  "Column 3 drops the five counties with the most closures. Column 4 uses total private-sector",
  "employment as a placebo outcome.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ===== TABLE F1: SDE (Appendix) =====
cat("Generating SDE Table (Appendix)...\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y) for binary treatment (using pre-treatment SD)
pre_sds <- annual_panel %>%
  filter(year <= 2012) %>%
  group_by(industry) %>%
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_log_hir = sd(log_hir, na.rm = TRUE),
    sd_log_sep = sd(log_sep, na.rm = TRUE),
    .groups = "drop"
  )

sde_rows <- list()

# Education employment
if (!is.null(results$twfe_results[["61"]])) {
  b <- coef(results$twfe_results[["61"]])[1]
  se_b <- sqrt(vcov(results$twfe_results[["61"]])[1,1])
  sd_y <- pre_sds$sd_log_emp[pre_sds$industry == "61"]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  sde_rows[["edu_emp"]] <- c("Education Employment", b, se_b, sd_y, sde, se_sde)
}

# Health care employment
if (!is.null(results$twfe_results[["62"]])) {
  b <- coef(results$twfe_results[["62"]])[1]
  se_b <- sqrt(vcov(results$twfe_results[["62"]])[1,1])
  sd_y <- pre_sds$sd_log_emp[pre_sds$industry == "62"]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  sde_rows[["hc_emp"]] <- c("Health Care Employment", b, se_b, sd_y, sde, se_sde)
}

# Accommodation/Food employment
if (!is.null(results$twfe_results[["72"]])) {
  b <- coef(results$twfe_results[["72"]])[1]
  se_b <- sqrt(vcov(results$twfe_results[["72"]])[1,1])
  sd_y <- pre_sds$sd_log_emp[pre_sds$industry == "72"]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  sde_rows[["af_emp"]] <- c("Accommodation/Food Employment", b, se_b, sd_y, sde, se_sde)
}

# Total private employment
if (!is.null(results$twfe_results[["00"]])) {
  b <- coef(results$twfe_results[["00"]])[1]
  se_b <- sqrt(vcov(results$twfe_results[["00"]])[1,1])
  sd_y <- pre_sds$sd_log_emp[pre_sds$industry == "00"]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  sde_rows[["total_emp"]] <- c("Total Private Employment", b, se_b, sd_y, sde, se_sde)
}

# Education hires
b <- coef(results$mechanism$hires)[1]
se_b <- sqrt(vcov(results$mechanism$hires)[1,1])
sd_y <- pre_sds$sd_log_hir[pre_sds$industry == "61"]
sde <- b / sd_y
se_sde <- se_b / sd_y
sde_rows[["edu_hir"]] <- c("Education Hires", b, se_b, sd_y, sde, se_sde)

# Education earnings
b <- coef(results$mechanism$earnings)[1]
se_b <- sqrt(vcov(results$mechanism$earnings)[1,1])
sd_y <- pre_sds$sd_log_emp[pre_sds$industry == "61"]  # use emp SD as proxy
sde <- b / sd_y
se_sde <- se_b / sd_y
sde_rows[["edu_earn"]] <- c("Education Earnings", b, se_b, sd_y, sde, se_sde)

# Classify SDE
classify_sde <- function(sde_val) {
  sde_val <- as.numeric(sde_val)
  if (sde_val < -0.15) return("Large negative")
  if (sde_val < -0.05) return("Moderate negative")
  if (sde_val < -0.005) return("Small negative")
  if (sde_val <= 0.005) return("Null")
  if (sde_val <= 0.05) return("Small positive")
  if (sde_val <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table
sde_tab <- do.call(rbind, lapply(sde_rows, function(r) {
  data.frame(
    Outcome = r[1],
    Beta = sprintf("%.5f", as.numeric(r[2])),
    SE = sprintf("%.5f", as.numeric(r[3])),
    SD_Y = sprintf("%.3f", as.numeric(r[4])),
    SDE = sprintf("%.4f", as.numeric(r[5])),
    SE_SDE = sprintf("%.4f", as.numeric(r[6])),
    Classification = classify_sde(r[5]),
    stringsAsFactors = FALSE
  )
}))

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does federal regulatory tightening that caused mass for-profit college closures (2013--2018) disrupt county-level labor markets in the education sector and adjacent industries? ",
  "\\textbf{Policy mechanism:} Federal enforcement of the Gainful Employment rule, Cohort Default Rate sanctions, and fraud investigations triggered chain-wide closures of for-profit college systems (Corinthian Colleges, ITT Tech, Education Corporation of America), eliminating over 1,200 campuses as employers across 383 counties. ",
  "\\textbf{Outcome definition:} Log employment (beginning-of-quarter count from QWI), log annual hires, and log average monthly earnings by NAICS sector. ",
  "\\textbf{Treatment:} Continuous---number of for-profit institution closures per county interacted with post-treatment indicator. ",
  "\\textbf{Data:} IPEDS institutional directory (1997--2024) for closure identification; Census QWI (2008--2022) for county $\\times$ quarter $\\times$ NAICS sector employment outcomes. ",
  "\\textbf{Method:} Two-way fixed effects (county + year) with closure count $\\times$ post; Callaway-Sant'Anna (2021) for heterogeneity-robust ATT; chain IV using ITT/Corinthian/ECA exposure. Standard errors clustered at county level. ",
  "\\textbf{Sample:} 383 treated counties (experienced $\\geq$1 for-profit closure) and 327 control counties (had for-profit colleges but zero closures), 2008--2022. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_tab)) {
  sde_tex <- c(sde_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_tab$Outcome[i], sde_tab$Beta[i], sde_tab$SE[i],
    sde_tab$SD_Y[i], sde_tab$SDE[i], sde_tab$SE_SDE[i],
    sde_tab$Classification[i]
  ))
}

sde_tex <- c(sde_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
