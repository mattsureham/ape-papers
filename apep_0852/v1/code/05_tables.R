## 05_tables.R — Generate all LaTeX tables for apep_0852
## Tables: (1) Summary stats, (2) Main DDD, (3) Robustness, (4) Heterogeneity
## Plus mandatory SDE appendix table (tabF1_sde.tex)

library(data.table)
library(fixest)
library(jsonlite)

# Set working directory to paper root (parent of code/)
paper_dir <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
)
if (dir.exists(paper_dir)) setwd(paper_dir)
datadir  <- "data"
tabledir <- "tables"
if (!dir.exists(tabledir)) dir.create(tabledir, recursive = TRUE)

# Load data and models
df <- fread(file.path(datadir, "analysis_data.csv"))
models <- readRDS(file.path(datadir, "main_models.rds"))
rob <- readRDS(file.path(datadir, "robustness_results.rds"))
rob_models <- readRDS(file.path(datadir, "robustness_models.rds"))

# ── TABLE 1: Summary Statistics ──────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment (2019 + 2021) stats by treatment group × school-age
summ_func <- function(d, label) {
  data.table(
    Group = label,
    N = nrow(d),
    Food_Insecure = round(100 * weighted.mean(d$food_insecure, d$wt), 1),
    Very_Low_FS = round(100 * weighted.mean(d$very_low_fs, d$wt), 1),
    SNAP = round(100 * weighted.mean(d$snap_receipt, d$wt, na.rm = TRUE), 1),
    Low_Income = round(100 * mean(d$low_income), 1),
    HH_Size = round(weighted.mean(d$hhsize, d$wt), 1),
    Single_Parent = round(100 * mean(d$single_parent), 1)
  )
}

pre <- df[year %in% c(2019, 2021)]
tab1_data <- rbind(
  summ_func(pre[treat_state == 1 & has_school_age == 1], "Treated, School-Age"),
  summ_func(pre[treat_state == 1 & has_school_age == 0], "Treated, No Children"),
  summ_func(pre[treat_state == 0 & has_school_age == 1], "Control, School-Age"),
  summ_func(pre[treat_state == 0 & has_school_age == 0], "Control, No Children")
)

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics by Treatment Group}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Food Security (\\%)} & SNAP & Low & HH & Single \\\\",
  "Group & Insecure & Very Low & (\\%) & Income (\\%) & Size & Parent (\\%) \\\\",
  "\\hline"
)

for (i in 1:nrow(tab1_data)) {
  r <- tab1_data[i]
  tab1_tex <- c(tab1_tex, sprintf(
    "%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
    r$Group, r$Food_Insecure, r$Very_Low_FS, r$SNAP,
    r$Low_Income, r$HH_Size, r$Single_Parent
  ))
  if (i == 2) tab1_tex <- c(tab1_tex, "\\addlinespace")
}

tab1_tex <- c(tab1_tex,
  "\\hline",
  sprintf("\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Pre-treatment period (2019, 2021). $N$ = %s households.} \\\\",
          format(nrow(pre), big.mark = ",")),
  "\\multicolumn{7}{l}{\\footnotesize Treated states: CA, ME, CO, MI, MN, VT. Weighted using CPS FSS supplement weights.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab1_tex, file.path(tabledir, "tab1_summary.tex"))

# ── TABLE 2: Main DDD Results ────────────────────────────────────
cat("Generating Table 2: Main DDD Results\n")

# Extract key results
get_result <- function(m, var = "treat_x_school_x_post") {
  b <- coef(m)[var]
  s <- se(m)[var]
  p <- pvalue(m)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  list(b = b, s = s, stars = stars, n = m$nobs)
}

r1 <- get_result(models$m1_fi)
r2 <- get_result(models$m2_fi)
r3 <- get_result(models$m3_fi)
r4 <- get_result(models$m1_vlfs)
r5 <- get_result(models$m2_vlfs)
r6 <- get_result(models$m1_snap)

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Universal Free School Meals on Household Food Security}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Food Insecure} & Very Low & Very Low & SNAP \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline",
  sprintf("Treat $\\times$ SchoolAge $\\times$ Post & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
          r1$b, r1$stars, r2$b, r2$stars, r3$b, r3$stars,
          r4$b, r4$stars, r5$b, r5$stars, r6$b, r6$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          r1$s, r2$s, r3$s, r4$s, r5$s, r6$s),
  "\\addlinespace",
  "State FE & Yes & --- & Yes & Yes & --- & Yes \\\\",
  "Year FE & Yes & --- & Yes & Yes & --- & Yes \\\\",
  "State $\\times$ Year FE & No & Yes & No & No & Yes & No \\\\",
  "State $\\times$ SchoolAge FE & No & Yes & No & No & Yes & No \\\\",
  "Controls & No & No & Yes & No & No & No \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","), format(r4$n, big.mark = ","),
          format(r5$n, big.mark = ","), format(r6$n, big.mark = ",")),
  sprintf("Pre-treatment mean & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(df[year <= 2021]$food_insecure), mean(df[year <= 2021]$food_insecure),
          mean(df[year <= 2021]$food_insecure),
          mean(df[year <= 2021]$very_low_fs), mean(df[year <= 2021]$very_low_fs),
          mean(df[year <= 2021]$snap_receipt, na.rm = TRUE)),
  "\\hline",
  "\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} LPM estimates. Dependent variables are binary indicators.} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize Standard errors clustered at the state level in parentheses.} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab2_tex, file.path(tabledir, "tab2_main.tex"))

# ── TABLE 3: Robustness ─────────────────────────────────────────
cat("Generating Table 3: Robustness\n")

r_placebo <- get_result(rob_models$m_placebo, "treat_x_young_x_post")
r_c1 <- get_result(rob_models$m_c1, "ddd_c1")
r_c2 <- get_result(rob_models$m_c2, "ddd_c2")
r_logit_b <- coef(rob_models$m_logit)["treat_x_school_x_post"]
r_logit_s <- se(rob_models$m_logit)["treat_x_school_x_post"]
r_logit_p <- pvalue(rob_models$m_logit)["treat_x_school_x_post"]
logit_stars <- ifelse(r_logit_p < 0.01, "^{***}", ifelse(r_logit_p < 0.05, "^{**}", ifelse(r_logit_p < 0.1, "^{*}", "")))

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE \\\\",
  "\\hline",
  "\\textit{Panel A: Main estimate} & & \\\\",
  sprintf("\\quad Saturated DDD (baseline) & $%.4f%s$ & (%.4f) \\\\",
          coef(models$m2_fi)["treat_x_school_x_post"],
          get_result(models$m2_fi)$stars,
          se(models$m2_fi)["treat_x_school_x_post"]),
  "\\addlinespace",
  "\\textit{Panel B: Placebo and falsification} & & \\\\",
  sprintf("\\quad Young children (0--4) placebo & $%.4f%s$ & (%.4f) \\\\",
          r_placebo$b, r_placebo$stars, r_placebo$s),
  "\\addlinespace",
  "\\textit{Panel C: By cohort} & & \\\\",
  sprintf("\\quad Cohort 1 (CA, ME --- 2022) & $%.4f%s$ & (%.4f) \\\\",
          r_c1$b, r_c1$stars, r_c1$s),
  sprintf("\\quad Cohort 2 (CO, MI, MN, VT --- 2023) & $%.4f%s$ & (%.4f) \\\\",
          r_c2$b, r_c2$stars, r_c2$s),
  "\\addlinespace",
  "\\textit{Panel D: Alternative specification} & & \\\\",
  sprintf("\\quad Logit (log-odds) & $%.4f%s$ & (%.4f) \\\\",
          r_logit_b, logit_stars, r_logit_s),
  sprintf("\\quad Logit marginal effect & $%.4f$ & \\\\", rob$logit_me),
  "\\addlinespace",
  "\\textit{Panel E: Leave-one-out (treated states)} & & \\\\",
  sprintf("\\quad Range & [%.4f, %.4f] & \\\\",
          min(rob$jackknife), max(rob$jackknife)),
  "\\hline",
  "\\multicolumn{3}{l}{\\footnotesize \\textit{Notes:} Panel A reproduces the saturated DDD from Table~\\ref{tab:main}, col.~(2).} \\\\",
  "\\multicolumn{3}{l}{\\footnotesize Panels B--E test sensitivity. All SEs clustered at state level.} \\\\",
  "\\multicolumn{3}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab3_tex, file.path(tabledir, "tab3_robust.tex"))

# ── TABLE 4: Heterogeneity ──────────────────────────────────────
cat("Generating Table 4: Heterogeneity\n")

r_low <- get_result(rob_models$m_lowinc)
r_high <- get_result(rob_models$m_highinc)
r_sing <- get_result(rob_models$m_single)
r_two <- get_result(rob_models$m_twopar)

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneous Effects by Household Characteristics}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{By Income} & \\multicolumn{2}{c}{By Family Structure} \\\\",
  " & $<$185\\% FPL & $\\geq$185\\% FPL & Single Parent & Two Parent \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("DDD & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
          r_low$b, r_low$stars, r_high$b, r_high$stars,
          r_sing$b, r_sing$stars, r_two$b, r_two$stars),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          r_low$s, r_high$s, r_sing$s, r_two$s),
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r_low$n, big.mark = ","), format(r_high$n, big.mark = ","),
          format(r_sing$n, big.mark = ","), format(r_two$n, big.mark = ",")),
  sprintf("Pre-treatment mean & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(df[year <= 2021 & low_income == 1]$food_insecure),
          mean(df[year <= 2021 & low_income == 0]$food_insecure),
          mean(df[year <= 2021 & single_parent == 1]$food_insecure),
          mean(df[year <= 2021 & single_parent == 0]$food_insecure)),
  "\\hline",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} Each column estimates the DDD on a subsample.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize SEs clustered at the state level. $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab4_tex, file.path(tabledir, "tab4_hetero.tex"))

# ── TABLE F1: Standardized Effect Sizes (SDE) ───────────────────
cat("Generating Table F1: SDE Appendix\n")

sd_fi <- models$sd_fi_pre
sd_vlfs <- models$sd_vlfs_pre

# Main estimates from saturated DDD
b_fi <- coef(models$m2_fi)["treat_x_school_x_post"]
se_fi <- se(models$m2_fi)["treat_x_school_x_post"]
b_vlfs <- coef(models$m2_vlfs)["treat_x_school_x_post"]
se_vlfs <- se(models$m2_vlfs)["treat_x_school_x_post"]

# SNAP
b_snap <- coef(models$m2_snap)["treat_x_school_x_post"]
se_snap <- se(models$m2_snap)["treat_x_school_x_post"]
sd_snap <- sd(df[year <= 2021]$snap_receipt, na.rm = TRUE)

# Heterogeneity: low-income
b_lowinc <- rob$hetero_income$low$coef
se_lowinc <- rob$hetero_income$low$se
sd_fi_low <- sd(df[year <= 2021 & low_income == 1]$food_insecure)

# Heterogeneity: single-parent
b_single <- rob$hetero_single$single$coef
se_single <- rob$hetero_single$single$se
sd_fi_single <- sd(df[year <= 2021 & single_parent == 1]$food_insecure)

# Compute SDEs
compute_sde <- function(beta, se_beta, sd_y) {
  sde <- beta / sd_y
  se_sde <- abs(se_beta / sd_y)
  classify <- ifelse(sde < -0.15, "Large negative",
              ifelse(sde < -0.05, "Moderate negative",
              ifelse(sde < -0.005, "Small negative",
              ifelse(sde < 0.005, "Null",
              ifelse(sde < 0.05, "Small positive",
              ifelse(sde < 0.15, "Moderate positive", "Large positive"))))))
  list(sde = sde, se_sde = se_sde, class = classify)
}

sde_fi <- compute_sde(b_fi, se_fi, sd_fi)
sde_vlfs <- compute_sde(b_vlfs, se_vlfs, sd_vlfs)
sde_snap <- compute_sde(b_snap, se_snap, sd_snap)
sde_lowinc <- compute_sde(b_lowinc, se_lowinc, sd_fi_low)
sde_single <- compute_sde(b_single, se_single, sd_fi_single)

# SDE notes string
n_total <- nrow(df)
n_treated_hh <- nrow(df[treat_state == 1 & has_school_age == 1])
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state universal free school meal mandates---enacted after the expiration of pandemic-era federal waivers---improve household food security for families with school-age children? ",
  "\\textbf{Policy mechanism:} Eight states legislated permanent universal free breakfast and lunch in all public schools, eliminating both meal prices for non-qualifying families and the administrative burden of means-tested free/reduced-price applications; this shifts eligible-but-unenrolled families from partial cost to zero cost and removes stigma associated with program participation. ",
  "\\textbf{Outcome definition:} HRFS12M1 from the CPS Food Security Supplement---a 12-month household food security status measure based on an 18-item questionnaire, dichotomized into food insecure (low or very low food security) versus food secure. ",
  "\\textbf{Treatment:} Binary: household resides in a state that enacted permanent universal free school meals (CA/ME from 2022; CO/MI/MN/VT from 2023). ",
  "\\textbf{Data:} CPS Food Security Supplement (Census Bureau microdata API), December 2019 and 2021--2023, household-level observations, $N$ = ",
  format(n_total, big.mark = ","), " household-years. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ school-age children $\\times$ post) with state-by-year and state-by-household-type fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Reference-person records with valid 12-month food security status; school-age defined as having at least one child aged 5--18 in the household. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("\\quad Food insecure & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          b_fi, se_fi, sd_fi, sde_fi$sde, sde_fi$se_sde, sde_fi$class),
  sprintf("\\quad Very low food security & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          b_vlfs, se_vlfs, sd_vlfs, sde_vlfs$sde, sde_vlfs$se_sde, sde_vlfs$class),
  sprintf("\\quad SNAP receipt & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          b_snap, se_snap, sd_snap, sde_snap$sde, sde_snap$se_sde, sde_snap$class),
  "\\addlinespace",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\",
  sprintf("\\quad Food insecure (low-income) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          b_lowinc, se_lowinc, sd_fi_low, sde_lowinc$sde, sde_lowinc$se_sde, sde_lowinc$class),
  sprintf("\\quad Food insecure (single-parent) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          b_single, se_single, sd_fi_single, sde_single$sde, sde_single$se_sde, sde_single$class),
  "\\hline",
  "\\begin{minipage}{\\textwidth}",
  "\\begin{itemize}[leftmargin=*,nosep]",
  sde_notes,
  "\\end{itemize}",
  "\\end{minipage}",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tabF1_tex, file.path(tabledir, "tabF1_sde.tex"))

cat(sprintf("\nAll tables saved to %s/\n", tabledir))
cat("Files: tab1_summary.tex, tab2_main.tex, tab3_robust.tex, tab4_hetero.tex, tabF1_sde.tex\n")
cat("\n=== Table generation complete ===\n")
