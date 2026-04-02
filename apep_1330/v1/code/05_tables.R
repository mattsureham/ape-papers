# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# =============================================================================

source("00_packages.R")

results    <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
panel      <- results$panel

dir.create("../tables", showWarnings = FALSE)

# Helper: format coefficient with stars
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}
fmt <- function(x, d = 2) formatC(round(x, d), format = "f", digits = d)
fmtc <- function(x) formatC(round(x), format = "d", big.mark = ",")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

sumvars <- c("in_state_tuition", "enrollment", "completions",
             "grant_per_student", "pell_per_recipient", "inst_grant_per",
             "net_price_q1", "net_price_q5",
             "predicted_heerf_per_student", "pell_share_2018")
sumlabs <- c("In-state tuition (\\$)", "Enrollment (12-month)", "Completions",
             "Grant aid/student (\\$)", "Pell grant/recipient (\\$)",
             "Institutional grant/student (\\$)",
             "Net price, Q1 income (\\$)", "Net price, Q5 income (\\$)",
             "Predicted HEERF/student (\\$)", "Pell share (2018)")

tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics: Public Institutions, 2015--2022}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrr}", "\\toprule",
  "Variable & Mean & Std.\\ Dev. & N \\\\", "\\midrule")

for (i in seq_along(sumvars)) {
  v <- sumvars[i]
  vals <- panel[[v]]
  m <- mean(vals, na.rm = TRUE)
  s <- sd(vals, na.rm = TRUE)
  n <- sum(!is.na(vals))
  if (v == "pell_share_2018") {
    tab1 <- c(tab1, sprintf("%s & %s & %s & %s \\\\",
      sumlabs[i], fmt(m, 3), fmt(s, 3), fmtc(n)))
  } else {
    tab1 <- c(tab1, sprintf("%s & %s & %s & %s \\\\",
      sumlabs[i], fmtc(m), fmtc(s), fmtc(n)))
  }
}

tab1 <- c(tab1, "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  sprintf("\\item \\textit{Notes:} Sample includes %s public institutions observed annually 2015--2022 (%s institution-years). Predicted HEERF per student is constructed from 2018 Pell Grant share $\\times$ FTE enrollment using the statutory HEERF allocation formula. All dollar amounts are nominal.",
    fmtc(length(unique(panel$unitid))), fmtc(nrow(panel))),
  "\\end{tablenotes}", "\\end{threeparttable}",
  "\\label{tab:summary}", "\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main Results (all outcomes)
# =============================================================================

main_outs <- c("in_state_tuition", "grant_per_student", "net_price_q1",
               "enrollment", "completions")
main_labs <- c("In-State Tuition", "Grant Aid/Student", "Net Price (Q1)",
               "Enrollment", "Completions")

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of HEERF Formula Exposure on Institutional Outcomes}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 5), collapse = "")),
  "\\toprule",
  paste0("& ", paste(sprintf("(%d)", 1:5), collapse = " & "), " \\\\"),
  paste0("& ", paste(main_labs, collapse = " & "), " \\\\"),
  "\\midrule")

coef_line <- "HEERF exposure ($\\$1{,}000$s)"
se_line <- ""
mean_line <- "Pre-treatment mean"
n_line <- "Observations"

for (y in main_outs) {
  m <- results$main[[y]]
  if (!is.null(m)) {
    est <- coef(m)["predicted_heerf_post"]
    sev <- se(m)["predicted_heerf_post"]
    pv <- 2 * pnorm(-abs(est / sev))
    pre_m <- mean(panel[[y]][panel$year < 2020], na.rm = TRUE)
    coef_line <- paste0(coef_line, sprintf(" & %s%s", fmt(est, 2), stars(pv)))
    se_line <- paste0(se_line, sprintf(" & (%s)", fmt(sev, 2)))
    mean_line <- paste0(mean_line, sprintf(" & %s", fmtc(pre_m)))
    n_line <- paste0(n_line, sprintf(" & %s", fmtc(nobs(m))))
  } else {
    coef_line <- paste0(coef_line, " & ---")
    se_line <- paste0(se_line, " & ---")
    mean_line <- paste0(mean_line, " & ---")
    n_line <- paste0(n_line, " & ---")
  }
}

tab2 <- c(tab2,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"), "\\\\",
  "Institution FE & \\multicolumn{5}{c}{Yes} \\\\",
  "State $\\times$ Year FE & \\multicolumn{5}{c}{Yes} \\\\",
  paste0(mean_line, " \\\\"),
  paste0(n_line, " \\\\"),
  "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\end{threeparttable}",
  "\\par\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "{\\footnotesize \\textit{Notes:} Each column reports a separate OLS regression of the outcome on predicted HEERF exposure per student (in \\$1,000s), defined as the institution's formula-predicted HEERF per student (from 2018 Pell share $\\times$ FTE) interacted with a post-2020 indicator. All regressions include institution and state $\\times$ year fixed effects. Standard errors clustered at the institution level in parentheses. Net Price (Q1) is the average net price for students with family income \\$0--\\$30,000. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
  "\\end{minipage}",
  "\\label{tab:main}", "\\end{table}")

writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Heterogeneity (enrollment by institution type and Pell intensity)
# =============================================================================

het_models <- list(
  robustness$het_enroll_4yr, robustness$het_enroll_2yr,
  robustness$het_enroll_highpell, robustness$het_enroll_lowpell)
het_labs <- c("4-Year", "2-Year", "High Pell", "Low Pell")

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Heterogeneity in Enrollment Response to HEERF Exposure}",
  "\\begin{threeparttable}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 4), collapse = "")),
  "\\toprule", "& (1) & (2) & (3) & (4) \\\\",
  paste0("& ", paste(het_labs, collapse = " & "), " \\\\"),
  "\\midrule")

cl <- "HEERF exposure ($\\$1{,}000$s)"
sl <- ""
nl <- "Observations"
for (m in het_models) {
  est <- coef(m)["predicted_heerf_post"]
  sev <- se(m)["predicted_heerf_post"]
  pv <- 2 * pnorm(-abs(est / sev))
  cl <- paste0(cl, sprintf(" & %s%s", fmt(est, 2), stars(pv)))
  sl <- paste0(sl, sprintf(" & (%s)", fmt(sev, 2)))
  nl <- paste0(nl, sprintf(" & %s", fmtc(nobs(m))))
}

tab3 <- c(tab3, paste0(cl, " \\\\"), paste0(sl, " \\\\"), "\\\\",
  "Institution FE & \\multicolumn{4}{c}{Yes} \\\\",
  "State $\\times$ Year FE & \\multicolumn{4}{c}{Yes} \\\\",
  paste0(nl, " \\\\"), "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  sprintf("\\item \\textit{Notes:} Dependent variable is 12-month unduplicated enrollment. Each column reports a separate regression on the indicated subsample. High/Low Pell split at the median 2018 Pell share (%.3f). Standard errors clustered at the institution level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    robustness$med_pell),
  "\\end{tablenotes}", "\\end{threeparttable}",
  "\\label{tab:heterogeneity}", "\\end{table}")

writeLines(tab3, "../tables/tab3_heterogeneity.tex")

# =============================================================================
# TABLE 4: Robustness
# =============================================================================

rob_models <- list(
  results$main$enrollment,
  robustness$rob_enroll_simple,
  robustness$rob_enroll_state,
  robustness$rob_log_enroll)
rob_labs <- c("Baseline", "No State$\\times$Year", "State Cluster", "Log Enroll.")

tab4 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness of Enrollment Response to Alternative Specifications}",
  "\\begin{threeparttable}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 4), collapse = "")),
  "\\toprule", "& (1) & (2) & (3) & (4) \\\\",
  paste0("& ", paste(rob_labs, collapse = " & "), " \\\\"),
  "\\midrule")

cl <- "HEERF exposure ($\\$1{,}000$s)"
sl <- ""
nl <- "Observations"
for (m in rob_models) {
  est <- coef(m)["predicted_heerf_post"]
  sev <- se(m)["predicted_heerf_post"]
  pv <- 2 * pnorm(-abs(est / sev))
  cl <- paste0(cl, sprintf(" & %s%s", fmt(est, 3), stars(pv)))
  sl <- paste0(sl, sprintf(" & (%s)", fmt(sev, 3)))
  nl <- paste0(nl, sprintf(" & %s", fmtc(nobs(m))))
}

tab4 <- c(tab4, paste0(cl, " \\\\"), paste0(sl, " \\\\"), "\\\\",
  paste0(nl, " \\\\"), "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  "\\item \\textit{Notes:} Column (1) is the baseline from Table~\\ref{tab:main}. Column (2) uses year FE only. Column (3) clusters at the state level. Column (4) uses log enrollment. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}", "\\end{threeparttable}",
  "\\label{tab:robustness}", "\\end{table}")

writeLines(tab4, "../tables/tab4_robustness.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =============================================================================

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# SD(X) uses the cross-sectional variation in predicted HEERF per student
# across ALL institutions (not the interaction term, which is zero pre-2020)
pre <- panel %>% filter(year < 2020)
sd_x <- sd(panel$predicted_heerf_per_student / 1000, na.rm = TRUE)  # In $1000s

# Pooled rows
sde_pooled <- list()
for (y in c("in_state_tuition", "enrollment", "completions")) {
  m <- results$main[[y]]
  if (is.null(m)) next
  beta <- coef(m)["predicted_heerf_post"]
  se_b <- se(m)["predicted_heerf_post"]
  sd_y <- sd(pre[[y]], na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  sde_pooled[[y]] <- list(
    label = c(in_state_tuition = "In-state tuition",
              enrollment = "Enrollment", completions = "Completions")[y],
    beta = beta, sd_x = sd_x, sd_y = sd_y, sde = sde, se_sde = se_sde,
    class = classify(sde))
}

# Heterogeneous rows (4yr vs 2yr enrollment)
sde_het <- list()
for (type in c("4yr", "2yr")) {
  m <- robustness[[paste0("het_enroll_", type)]]
  sub_pre <- pre %>% filter(if (type == "4yr") is_4year else is_2year)
  beta <- coef(m)["predicted_heerf_post"]
  se_b <- se(m)["predicted_heerf_post"]
  sd_y <- sd(sub_pre$enrollment, na.rm = TRUE)
  sub_all <- panel %>% filter(if (type == "4yr") is_4year else is_2year)
  sd_x_sub <- sd(sub_all$predicted_heerf_per_student / 1000, na.rm = TRUE)
  sde <- beta * sd_x_sub / sd_y
  se_sde <- se_b * sd_x_sub / sd_y
  sde_het[[type]] <- list(
    label = paste0("Enrollment (", ifelse(type == "4yr", "4-year", "2-year"), ")"),
    beta = beta, sd_x = sd_x_sub, sd_y = sd_y, sde = sde, se_sde = se_sde,
    class = classify(sde))
}

sde_tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}", "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\")

for (r in sde_pooled) {
  sde_tex <- c(sde_tex, sprintf("%s & RF & %s & %s & %s & %s & %s & %s \\\\",
    r$label, fmt(r$beta, 2), fmt(r$sd_x, 2), fmtc(r$sd_y),
    fmt(r$sde, 3), fmt(r$se_sde, 3), r$class))
}

sde_tex <- c(sde_tex, "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by institution type)}} \\\\")

for (r in sde_het) {
  sde_tex <- c(sde_tex, sprintf("%s & RF & %s & %s & %s & %s & %s & %s \\\\",
    r$label, fmt(r$beta, 2), fmt(r$sd_x, 2), fmtc(r$sd_y),
    fmt(r$sde, 3), fmt(r$se_sde, 3), r$class))
}

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the \\$76 billion Higher Education Emergency Relief Fund (HEERF, 2020--2021), allocated via a Pell-share formula, affect enrollment, tuition, and degree completion at public colleges? ",
  "\\textbf{Policy mechanism:} HEERF allocated emergency funds to U.S. colleges using a formula weighting Pell Grant recipient share and FTE enrollment, with at least 50\\% mandated for direct student emergency grants and the remainder available for institutional costs including lost revenue replacement; the formula created quasi-random cross-sectional variation in per-student windfall intensity. ",
  "\\textbf{Outcome definition:} Enrollment is the 12-month unduplicated headcount from IPEDS EFFY; in-state tuition is the annual sticker price for in-state undergraduates from IPEDS IC\\_AY; completions are total degrees/certificates awarded from IPEDS C\\_A. ",
  "\\textbf{Treatment:} Continuous: predicted HEERF per student in \\$1,000s (from the 2018 pre-pandemic Pell share $\\times$ FTE allocation formula), interacted with a post-2020 indicator. ",
  "\\textbf{Data:} IPEDS institutional panel, 2015--2022, public 4-year and 2-year institutions, institution-year unit of observation, ",
  fmtc(nrow(panel)), " observations. ",
  "\\textbf{Method:} Reduced-form OLS: outcome regressed on predicted HEERF exposure (from pre-pandemic formula) $\\times$ post-2020; institution and state $\\times$ year fixed effects; standard errors clustered at the institution level. ",
  "\\textbf{Sample:} Public 4-year and 2-year institutions with non-missing tuition and positive enrollment in all years 2015--2022. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) and SD($Y$) are pre-treatment (2015--2019) ",
  "unconditional standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).")

sde_tex <- c(sde_tex,
  "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "{\\footnotesize",
  sde_notes,
  "}", "\\end{minipage}", "\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
