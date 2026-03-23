# 05_tables.R — Generate all tables
# apep_0835: Greece POS Terminal Mandates

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
panel <- fread("../data/analysis_panel.csv")

# Compute wages per employee and log transform
panel[, wage_per_emp := wages / (employment / 1000)]
panel[, log_wpe := log(wage_per_emp + 1)]

# TWFE model for wages per employee (intensive margin)
twfe_wpe <- feols(log_wpe ~ treat_post | sector_id + year,
                  data = panel, cluster = ~nace1)

# Helper: format coefficient with stars
fmt_coef <- function(model, coef_name = "treat_post") {
  beta <- coef(model)[coef_name]
  se <- sqrt(vcov(model)[coef_name, coef_name])
  pv <- 2 * pt(-abs(beta / se), df = model$nobs - model$nparams)
  stars <- ""
  if (!is.na(pv)) {
    if (pv < 0.01) stars <- "***"
    else if (pv < 0.05) stars <- "**"
    else if (pv < 0.10) stars <- "*"
  }
  list(beta = sprintf("%.4f%s", beta, stars),
       se = sprintf("(%.4f)", se),
       pv = pv)
}

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================

cat("=== Table 1 ===\n")

pre <- panel[year < 2017]
post <- panel[year >= 2017]

s1 <- pre[treated == 1, .(m_est = mean(establishments), s_est = sd(establishments),
                           m_emp = mean(employment), s_emp = sd(employment),
                           m_wg = mean(wages), s_wg = sd(wages), n = .N)]
s2 <- pre[treated == 0, .(m_est = mean(establishments), s_est = sd(establishments),
                           m_emp = mean(employment), s_emp = sd(employment),
                           m_wg = mean(wages), s_wg = sd(wages), n = .N)]
s3 <- post[treated == 1, .(m_est = mean(establishments), s_est = sd(establishments),
                            m_emp = mean(employment), s_emp = sd(employment),
                            m_wg = mean(wages), s_wg = sd(wages), n = .N)]
s4 <- post[treated == 0, .(m_est = mean(establishments), s_est = sd(establishments),
                            m_emp = mean(employment), s_emp = sd(employment),
                            m_wg = mean(wages), s_wg = sd(wages), n = .N)]

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Group and Period}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Establishments} & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Wages (EUR M)} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD & $N$ \\\\",
  "\\midrule",
  sprintf("Treated, Pre & %s & %s & %s & %s & %.1f & %.1f & %d \\\\",
          format(round(s1$m_est), big.mark = ","),
          format(round(s1$s_est), big.mark = ","),
          format(round(s1$m_emp), big.mark = ","),
          format(round(s1$s_emp), big.mark = ","),
          s1$m_wg, s1$s_wg, s1$n),
  sprintf("Control, Pre & %s & %s & %s & %s & %.1f & %.1f & %d \\\\",
          format(round(s2$m_est), big.mark = ","),
          format(round(s2$s_est), big.mark = ","),
          format(round(s2$m_emp), big.mark = ","),
          format(round(s2$s_emp), big.mark = ","),
          s2$m_wg, s2$s_wg, s2$n),
  sprintf("Treated, Post & %s & %s & %s & %s & %.1f & %.1f & %d \\\\",
          format(round(s3$m_est), big.mark = ","),
          format(round(s3$s_est), big.mark = ","),
          format(round(s3$m_emp), big.mark = ","),
          format(round(s3$s_emp), big.mark = ","),
          s3$m_wg, s3$s_wg, s3$n),
  sprintf("Control, Post & %s & %s & %s & %s & %.1f & %.1f & %d \\\\",
          format(round(s4$m_est), big.mark = ","),
          format(round(s4$s_est), big.mark = ","),
          format(round(s4$m_emp), big.mark = ","),
          format(round(s4$s_emp), big.mark = ","),
          s4$m_wg, s4$s_wg, s4$n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize",
  "\\textit{Notes:} Treated sectors: Retail/Wholesale (G), Accommodation/Food (I), Professional services (M), Administrative (N), Other services (S). Control sectors: Mining (B), Manufacturing (C), Electricity (D), Water/Waste (E), ICT (J). Establishments and employment are counts per sector-year. Wages in EUR millions. Source: Eurostat SBS, 2012--2019.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ===================================================================
# Table 2: Main Results
# ===================================================================

cat("=== Table 2 ===\n")

m1 <- fmt_coef(results$twfe$est)
m2 <- fmt_coef(results$twfe$emp)
m3 <- fmt_coef(results$twfe$wages)
m4 <- fmt_coef(results$twfe_reg)
m5 <- fmt_coef(twfe_wpe)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of POS Mandate on Formal Business Activity}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log Est. & Log Emp. & Log Wages & Log Emp. & Log Wages/Emp \\\\",
  " & & & & (Regional) & \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ Post & %s & %s & %s & %s & %s \\\\", m1$beta, m2$beta, m3$beta, m4$beta, m5$beta),
  sprintf(" & %s & %s & %s & %s & %s \\\\", m1$se, m2$se, m3$se, m4$se, m5$se),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          results$twfe$est$nobs, results$twfe$emp$nobs,
          results$twfe$wages$nobs, results$twfe_reg$nobs, twfe_wpe$nobs),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f \\\\",
          fitstat(results$twfe$est, "wr2")[[1]],
          fitstat(results$twfe$emp, "wr2")[[1]],
          fitstat(results$twfe$wages, "wr2")[[1]],
          fitstat(results$twfe_reg, "wr2")[[1]],
          fitstat(twfe_wpe, "wr2")[[1]]),
  "Sector FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & --- & Yes \\\\",
  "Region $\\times$ Year FE & --- & --- & --- & Yes & --- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize",
  "\\textit{Notes:} Columns 1--3: national sector-year panel (10 sectors, 2012--2019). Column 4: region-sector-year panel (13 NUTS2 regions, 9 sectors). Column 5: wages per employee (EUR thousands), intensive margin. Standard errors clustered at sector level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ===================================================================
# Table 3: Event Study (Sun-Abraham)
# ===================================================================

cat("=== Table 3 ===\n")

extract_es <- function(model) {
  ct <- as.data.table(coeftable(model), keep.rownames = "term")
  ct[, rel_time := as.numeric(gsub(".*::(-?[0-9]+).*", "\\1", term))]
  ct[!is.na(rel_time), .(rel_time, beta = Estimate, se = `Std. Error`,
                          pv = `Pr(>|t|)`)]
}

es_e <- extract_es(results$es$est)
es_m <- extract_es(results$es$emp)
es_w <- extract_es(results$es$wages)

all_k <- sort(unique(c(es_e$rel_time, es_m$rel_time, es_w$rel_time, -1)))

star <- function(pv) {
  if (is.na(pv)) return("")
  if (pv < 0.01) return("***")
  if (pv < 0.05) return("**")
  if (pv < 0.10) return("*")
  return("")
}

tab3_rows <- character()
for (k in all_k) {
  if (k == -1) {
    tab3_rows <- c(tab3_rows,
      sprintf("$%d$ & 0.000 & & 0.000 & & 0.000 & \\\\", k))
  } else {
    e <- es_e[rel_time == k]
    m <- es_m[rel_time == k]
    w <- es_w[rel_time == k]
    tab3_rows <- c(tab3_rows, sprintf(
      "$%d$ & %.3f%s & (%.3f) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
      k,
      if (nrow(e) > 0) e$beta else 0, if (nrow(e) > 0) star(e$pv) else "",
      if (nrow(e) > 0) e$se else 0,
      if (nrow(m) > 0) m$beta else 0, if (nrow(m) > 0) star(m$pv) else "",
      if (nrow(m) > 0) m$se else 0,
      if (nrow(w) > 0) w$beta else 0, if (nrow(w) > 0) star(w$pv) else "",
      if (nrow(w) > 0) w$se else 0
    ))
  }
}

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Sun-Abraham Interaction-Weighted Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{rcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Est.} & \\multicolumn{2}{c}{Log Emp.} & \\multicolumn{2}{c}{Log Wages} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "$k$ & Coef. & SE & Coef. & SE & Coef. & SE \\\\",
  "\\midrule",
  tab3_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize",
  "\\textit{Notes:} Sun-Abraham (2021) interaction-weighted estimator. Never-treated sectors as control. $k$ = years relative to 2017 mandate. Reference period: $k = -1$ (2016). Sector and year FEs. SEs clustered at sector level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_eventstudy.tex")

# ===================================================================
# Table 4: Robustness
# ===================================================================

cat("=== Table 4 ===\n")

r1 <- fmt_coef(rob_results$r1_restricted$emp)
r2 <- fmt_coef(rob_results$r2_incl2020$emp)
r3 <- fmt_coef(rob_results$r3_placebo$emp, "placebo_treat_post")
r4 <- fmt_coef(rob_results$r4_regional$emp)
base <- fmt_coef(results$twfe$emp)

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Employment Effects Across Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & 2014--19 & Incl. 2020 & Placebo 2015 & Regional \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ Post & %s & %s & %s & %s & %s \\\\",
          base$beta, r1$beta, r2$beta, r3$beta, r4$beta),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          base$se, r1$se, r2$se, r3$se, r4$se),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          results$twfe$emp$nobs,
          rob_results$r1_restricted$emp$nobs,
          rob_results$r2_incl2020$emp$nobs,
          rob_results$r3_placebo$emp$nobs,
          rob_results$r4_regional$emp$nobs),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize",
  sprintf("\\textit{Notes:} Dep.~var.: log employment. Col.~1: baseline (2012--2019, sector + year FEs). Col.~2: restricted to 2014--2019 for cleaner pre-trends. Col.~3: extends through 2020. Col.~4: placebo treatment at 2015 using pre-period only (2012--2016). Col.~5: region-sector panel with sector + region $\\times$ year FEs. Permutation inference $p$-value (500 draws): %.3f. SEs clustered at sector level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
          rob_results$r5_ri$p_emp),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ===================================================================
# Table 5: Heterogeneity by Sector
# ===================================================================

cat("=== Table 5 ===\n")

sector_labels <- c(G = "Retail", I = "Accomm.", M = "Prof. Svcs",
                   N = "Admin.", S = "Other Svcs")
het_results <- list()
for (s in names(sector_labels)) {
  het_data <- panel[nace1 == s | treated == 0]
  het_data[, het_tp := as.integer(nace1 == s) * post]
  het_results[[s]] <- feols(log_emp ~ het_tp | sector_id + year,
                            data = het_data, vcov = "HC1")
}

het_betas <- lapply(names(sector_labels), function(s) {
  fmt_coef(het_results[[s]], "het_tp")
})

tab5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneous Employment Effects by Treated Sector}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  sprintf(" & %s \\\\", paste(sector_labels, collapse = " & ")),
  "\\midrule",
  sprintf("Sector $\\times$ Post & %s \\\\",
          paste(sapply(het_betas, function(x) x$beta), collapse = " & ")),
  sprintf(" & %s \\\\",
          paste(sapply(het_betas, function(x) x$se), collapse = " & ")),
  "\\midrule",
  sprintf("Observations & %s \\\\",
          paste(sapply(het_results, function(m) m$nobs), collapse = " & ")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.5em}",
  "\\footnotesize",
  "\\textit{Notes:} Each column compares one treated sector vs.\\ the never-treated control group. Dep.~var.: log employment. Sector and year FEs. HC1 heteroskedasticity-robust standard errors in parentheses (cluster-robust SEs unreliable with only 6 sectors). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab5, "../tables/tab5_heterogeneity.tex")

# ===================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ===================================================================

cat("=== Table F1: SDE ===\n")

pre_sd <- results$pre_sd
pre_sd_wpe <- sd(panel[year < 2017]$log_wpe, na.rm = TRUE)

get_sde_row <- function(model, outcome_name, sd_y, coef_name = "treat_post") {
  beta <- coef(model)[coef_name]
  se_beta <- sqrt(vcov(model)[coef_name, coef_name])
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(x) {
    if (abs(x) > 0.15) return(ifelse(x < 0, "Large negative", "Large positive"))
    if (abs(x) > 0.05) return(ifelse(x < 0, "Moderate negative", "Moderate positive"))
    if (abs(x) > 0.005) return(ifelse(x < 0, "Small negative", "Small positive"))
    return("Null")
  }

  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          outcome_name, beta, se_beta, sd_y, sde, se_sde, classify(sde))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Greece. ",
  "\\textbf{Research question:} Did mandatory POS terminal installation for service-sector ",
  "businesses increase formal business activity in treated sectors relative to never-mandated ",
  "industrial and ICT sectors? ",
  "\\textbf{Policy mechanism:} Law 4446/2016 required businesses in approximately 196 professions ",
  "to install electronic payment terminals by 2017, creating a paper trail for transactions that ",
  "were previously conducted in cash; a complementary demand-side mandate required taxpayers to ",
  "conduct 30 percent of declared income via electronic payments or face a 22 percent surcharge. ",
  "\\textbf{Outcome definition:} Log local business units (establishments), log persons employed, ",
  "and log wages and salaries (in EUR millions) per NACE 1-digit sector-year cell from Eurostat ",
  "Structural Business Statistics. ",
  "\\textbf{Treatment:} Binary; sector-level assignment based on whether the NACE sector was ",
  "included in the 2017 POS mandate waves versus never-treated industrial and ICT sectors. ",
  "\\textbf{Data:} Eurostat SBS (sbs\\_na\\_ind\\_r2, sbs\\_na\\_dt\\_r2, sbs\\_na\\_1a\\_se\\_r2), ",
  "10 NACE 1-digit sectors, 2012--2019, 80 sector-year observations; supplementary regional panel ",
  "from sbs\\_r\\_nuts06\\_r2 (13 NUTS2 regions, 9 sectors, 814 observations). ",
  "\\textbf{Method:} Two-way fixed effects with sector and year fixed effects; Sun-Abraham event ",
  "study decomposition; standard errors clustered at sector level; permutation inference (500 draws). ",
  "\\textbf{Sample:} Restricted to 2012--2019 to exclude COVID-19 disruption; treated sectors are ",
  "those mandated in 2017 waves (retail/wholesale, accommodation/food, professional services, ",
  "administrative services, other services); control sectors are never-mandated (mining, manufacturing, ",
  "electricity, water/waste, ICT). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of ",
  "the log outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  get_sde_row(results$twfe$est, "Log establishments", pre_sd$sd_log_est),
  get_sde_row(results$twfe$emp, "Log employment", pre_sd$sd_log_emp),
  get_sde_row(results$twfe$wages, "Log wages", pre_sd$sd_log_wages),
  get_sde_row(twfe_wpe, "Log wages/emp", pre_sd_wpe),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{itemize}[leftmargin=*,nosep]",
  sde_notes,
  "\\end{itemize}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
