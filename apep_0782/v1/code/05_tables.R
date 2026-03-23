## 05_tables.R — Generate LaTeX tables for MSHA penalty reform paper
## APEP paper apep_0782

library(data.table)
library(fixest)

cat("=== 05_tables.R: Generating tables ===\n")

data_dir   <- here::here("output", "apep_0782", "v1", "data")
table_dir  <- here::here("output", "apep_0782", "v1", "tables")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "panel.rds"))
panel <- panel[!is.na(treat_intensity)]
models <- readRDS(file.path(data_dir, "main_models.rds"))
robust <- readRDS(file.path(data_dir, "robustness_models.rds"))
pen_compare <- readRDS(file.path(data_dir, "penalty_comparison.rds"))

## Helper: format number with commas
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")

## Helper: significance stars
stars <- function(p) {
  ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
}

## ========================================================================
## Table 1: Summary Statistics
## ========================================================================
cat("Table 1: Summary statistics...\n")

# Pre and post panels
pre  <- panel[post == 0]
post_d <- panel[post == 1]

make_row <- function(label, var, dt = panel) {
  sprintf("%-40s & %s & %s & %s & %s \\\\",
          label,
          fmt(mean(dt[[var]], na.rm = TRUE), 3),
          fmt(sd(dt[[var]], na.rm = TRUE), 3),
          fmt(min(dt[[var]], na.rm = TRUE), 3),
          fmt(max(dt[[var]], na.rm = TRUE), 1))
}

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Mine-Quarter Panel, 2004--2010}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome Variables}} \\\\[3pt]",
  make_row("Injury count (per mine-quarter)", "n_injuries"),
  make_row("Injury rate (per 100 employees)", "injury_rate"),
  make_row("Serious injury count", "n_serious"),
  make_row("Days lost", "total_days_lost"),
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Violation and Penalty Variables}} \\\\[3pt]",
  make_row("Violations (per mine-quarter)", "n_violations"),
  make_row("S\\&S violations (per mine-quarter)", "n_ss_violations"),
  make_row("Total penalties (\\$)", "total_penalty"),
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel C: Treatment and Mine Characteristics}} \\\\[3pt]",
  make_row("Treatment intensity (mean S\\&S penalty/100)", "treat_intensity"),
  make_row("Pre-reform S\\&S violations (count)", "n_ss_pre"),
  make_row("Number of employees", "n_employees"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s mine-quarter observations across %s mines and %d quarters (2004Q1--2010Q4). Treatment intensity is the mean proposed penalty per S\\&S violation at each mine during 2004--2006, divided by 100 for interpretability. A one-unit increase corresponds to \\$100 higher mean pre-reform S\\&S penalty. Injury rate is the count of MSHA-reported injuries per mine-quarter divided by the mine's employee count, multiplied by 100.",
          fmt0(nrow(panel)), fmt0(uniqueN(panel$MINE_ID)), uniqueN(panel$yq)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

## ========================================================================
## Table 2: Pre/Post Penalty Comparison
## ========================================================================
cat("Table 2: Penalty comparison...\n")

pc <- pen_compare[order(period, ss)]
# Reshape for cleaner output
tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{MSHA Proposed Penalties: Pre- vs.\\ Post-Reform Comparison}",
  "\\label{tab:penalties}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccc}",
  "\\toprule",
  "Period & Violation Type & N & Mean (\\$) & Median (\\$) & Total (\\$M) \\\\",
  "\\midrule"
)

for (i in 1:nrow(pc)) {
  row <- pc[i]
  tab2 <- c(tab2, sprintf("%-28s & %-8s & %s & %s & %s & %s \\\\",
                           row$period, row$ss,
                           fmt0(row$n_violations),
                           fmt(row$mean_penalty, 0),
                           fmt(row$median_penalty, 0),
                           fmt(row$total_penalty / 1e6, 1)))
}

tab2 <- c(tab2,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from MSHA Violations dataset. S\\&S = Significant and Substantial violations as designated by MSHA inspectors. The reform (30 CFR Part 100, effective March 2007) raised penalty points across the board, with disproportionate increases for S\\&S violations. Transition year (2007) shown separately because the reform took effect in March.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, file.path(table_dir, "tab2_violations.tex"))

## ========================================================================
## Table 3: Main DiD Results
## ========================================================================
cat("Table 3: Main results...\n")

# Extract coefficients for main interaction
get_main <- function(m, coef_name = "treat_intensity:post") {
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  p <- fixest::pvalue(m)[coef_name]
  list(b = b, s = s, p = p)
}

m2_r <- get_main(models$m2)
m3_r <- get_main(models$m3)
m4_r <- get_main(models$m4)
m5_r <- get_main(models$m5)
m6_r <- get_main(models$m6)

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Pre-Reform Penalty Exposure on Post-Reform Injury Rates}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Injury Rate & Injury Rate & Injury Rate & Serious Inj.\\ Rate & Days Lost Rate \\\\",
  "\\midrule",
  sprintf("Treatment $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(m2_r$b, 4), stars(m2_r$p),
          fmt(m3_r$b, 4), stars(m3_r$p),
          fmt(m4_r$b, 4), stars(m4_r$p),
          fmt(m5_r$b, 4), stars(m5_r$p),
          fmt(m6_r$b, 4), stars(m6_r$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(m2_r$s, 4), fmt(m3_r$s, 4), fmt(m4_r$s, 4), fmt(m5_r$s, 4), fmt(m6_r$s, 4)),
  "\\\\",
  "Mine FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & --- & --- & Yes & Yes \\\\",
  "State $\\times$ Quarter FE & --- & Yes & --- & --- & --- \\\\",
  "Mine Type $\\times$ Quarter FE & --- & --- & Yes & --- & --- \\\\",
  "\\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          fmt0(models$m2$nobs), fmt0(models$m3$nobs), fmt0(models$m4$nobs),
          fmt0(models$m5$nobs), fmt0(models$m6$nobs)),
  sprintf("Mines & %s & %s & %s & %s & %s \\\\",
          fmt0(uniqueN(panel$MINE_ID)), fmt0(uniqueN(panel$MINE_ID)),
          fmt0(uniqueN(panel$MINE_ID)), fmt0(uniqueN(panel$MINE_ID)),
          fmt0(uniqueN(panel$MINE_ID))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the mine level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Treatment intensity is the mean proposed penalty per S\\&S violation at mine $i$ during 2004--2006, divided by 100. Post equals one from 2007Q2 onward. Injury rate is injuries per 100 employees per quarter. Serious injuries include fatalities, permanent disabilities, and cases with days away from work. Days lost rate is total days lost per employee per quarter.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, file.path(table_dir, "tab3_main.tex"))

## ========================================================================
## Table 4: Event Study Coefficients
## ========================================================================
cat("Table 4: Event study...\n")

es <- models$es1
es_ct <- coeftable(es)
# Extract year labels from row names
es_years <- as.integer(gsub(".*::(\\d{4}).*", "\\1", rownames(es_ct)))

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Interaction of Treatment Intensity with Year Indicators}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year & Coefficient & Std.\\ Error \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_ct))) {
  yr <- es_years[i]
  b <- es_ct[i, "Estimate"]
  s <- es_ct[i, "Std. Error"]
  p <- es_ct[i, "Pr(>|t|)"]
  tab4 <- c(tab4, sprintf("%d & %s%s & (%s) \\\\",
                           yr, fmt(b, 4), stars(p), fmt(s, 4)))
}

tab4 <- c(tab4,
  "\\\\",
  "Reference year & \\multicolumn{2}{c}{2006} \\\\",
  "Mine FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", fmt0(es$nobs)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient is from the interaction of treatment intensity with a year indicator, estimated in a single regression with mine and quarter fixed effects. Standard errors clustered at the mine level. Reference year is 2006. Pre-reform coefficients (2004--2005) test the parallel trends assumption; post-reform coefficients (2007--2010) capture the dynamic treatment effect. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, file.path(table_dir, "tab4_eventstudy.tex"))

## ========================================================================
## Table 5: Robustness
## ========================================================================
cat("Table 5: Robustness...\n")

get_robust <- function(m, cn) {
  b <- coef(m)[cn]
  s <- se(m)[cn]
  p <- fixest::pvalue(m)[cn]
  n <- m$nobs
  list(b = b, s = s, p = p, n = n)
}

r_state  <- get_robust(robust$state_cluster, "treat_intensity:post")
r_plac   <- get_robust(robust$placebo, "treat_intensity_placebo:post_placebo")
r_notran <- get_robust(robust$no_transition, "treat_intensity:post_notrans")
r_count  <- get_robust(robust$ss_count, "treat_count:post")
r_wins   <- get_robust(robust$winsorized, "treat_intensity:post")

tab5 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & State SE & Placebo 2004 & Excl.\\ Trans. & S\\&S Count & Winsorized \\\\",
  "\\midrule",
  sprintf("Treatment $\\times$ Post & %s%s & %s & %s%s & %s%s & %s%s \\\\",
          fmt(r_state$b, 4), stars(r_state$p),
          fmt(r_plac$b, 4),
          fmt(r_notran$b, 4), stars(r_notran$p),
          fmt(r_count$b, 4), stars(r_count$p),
          fmt(r_wins$b, 4), stars(r_wins$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(r_state$s, 4), fmt(r_plac$s, 4), fmt(r_notran$s, 4),
          fmt(r_count$s, 4), fmt(r_wins$s, 4)),
  "\\\\",
  "Mine FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          fmt0(r_state$n), fmt0(r_plac$n), fmt0(r_notran$n),
          fmt0(r_count$n), fmt0(r_wins$n)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include mine and quarter fixed effects. Column 1 clusters standard errors at the state level instead of the mine level. Column 2 tests a placebo reform in 2004 using 2002--2006 data only (treatment based on 2002--2003 S\\&S penalties). Column 3 excludes the transition quarters 2007Q1--Q2 when the reform was being implemented. Column 4 uses the count of pre-reform S\\&S violations as an alternative treatment measure. Column 5 winsorizes the injury rate at the 99th percentile. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab5, file.path(table_dir, "tab5_robustness.tex"))

## ========================================================================
## Table F1: Standardized Effect Sizes (SDE)
## ========================================================================
cat("Table F1: SDE...\n")

# Main specification: m2 (injury rate ~ treat_intensity:post | mine + quarter)
beta_inj  <- as.numeric(coef(models$m2)["treat_intensity:post"])
se_inj    <- as.numeric(se(models$m2)["treat_intensity:post"])
sd_y_inj  <- sd(panel$injury_rate)
sd_x      <- sd(panel$treat_intensity)

# For continuous treatment: SDE = beta * sd_x / sd_y
sde_inj   <- beta_inj * sd_x / sd_y_inj
se_sde_inj <- se_inj * sd_x / sd_y_inj

# Serious injuries: m5
beta_ser  <- as.numeric(coef(models$m5)["treat_intensity:post"])
se_ser    <- as.numeric(se(models$m5)["treat_intensity:post"])
sd_y_ser  <- sd(panel$serious_rate)
sde_ser   <- beta_ser * sd_x / sd_y_ser
se_sde_ser <- se_ser * sd_x / sd_y_ser

# Classify
classify <- function(s) {
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

# Use base R to avoid dplyr dependency
classify_base <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llccccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Injury rate & Mine + Quarter FE & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_inj, 4), fmt(sd_x, 2), fmt(sd_y_inj, 2),
          fmt(sde_inj, 4), fmt(se_sde_inj, 4), classify_base(sde_inj)),
  sprintf("Serious inj.\\ rate & Mine + Quarter FE & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_ser, 4), fmt(sd_x, 2), fmt(sd_y_ser, 2),
          fmt(sde_ser, 4), fmt(se_sde_ser, 4), classify_base(sde_ser)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes.",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, which gives the effect of a one-standard-deviation change in the treatment variable, measured in standard deviations of the outcome.",
  "SD($Y$) and SD($X$) are unconditional standard deviations from the summary statistics (Table~\\ref{tab:summary}), before conditioning on fixed effects.",
  "",
  "\\textbf{Country:} United States.",
  "\\textbf{Research question:} Whether MSHA's 2007 civil penalty reform (30 CFR Part 100), which raised average proposed penalties 4.2-fold overnight, reduced mine-level injury rates.",
  "\\textbf{Policy mechanism:} The reform increased penalty assessment points across the board for all mine safety violations, with disproportionate increases for Significant and Substantial (S\\&S) violations; it raised the financial cost of non-compliance to deter unsafe practices.",
  "\\textbf{Outcome definition:} Quarterly injury count per mine divided by mine employment, multiplied by 100, using MSHA accident/injury reports.",
  "\\textbf{Treatment:} Continuous; mean proposed penalty per S\\&S violation at each mine during 2004--2006, divided by 100.",
  "\\textbf{Data:} MSHA Accidents, Violations, and Mines datasets, 2004--2010, mine-quarter panel.",
  sprintf("\\textbf{Method:} Continuous-treatment DiD with mine and quarter fixed effects, standard errors clustered at the mine level. N = %s mine-quarter observations across %s mines.", fmt0(nrow(panel)), fmt0(uniqueN(panel$MINE_ID))),
  "\\textbf{Sample:} Active mines with at least one S\\&S violation during 2004--2006 and non-missing employee counts.",
  "",
  "Classification thresholds (7 categories): large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$).",
  "Classification is based solely on the SDE point estimate --- never on statistical significance or p-values.",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat(sprintf("\nSDE results: injury rate SDE = %.4f (%s), serious SDE = %.4f (%s)\n",
            sde_inj, classify_base(sde_inj), sde_ser, classify_base(sde_ser)))

cat("\n=== 05_tables.R: DONE ===\n")
