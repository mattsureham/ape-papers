## 05_tables.R — Generate all LaTeX tables for apep_0700
## UK LHA Freeze and Homelessness

source("00_packages.R")
setwd("../data")

main <- readRDS("regression_results.rds")
robust <- readRDS("robustness_results.rds")
panel <- fread("analysis_panel.csv")
mapped <- panel[brma_name != "UNMAPPED"]
lha <- fread("lha_rates_all_years.csv")

cat("=== Generating Tables ===\n")

## -----------------------------------------------------------------------
## Table 1: Summary Statistics
## -----------------------------------------------------------------------
cat("Table 1: Summary statistics\n")
mapped[, gap_10pp := gap_pct / 10]
mapped[, high_gap := as.integer(gap_pct > median(gap_pct))]
mapped[, claimant_rate := claimant_count / (households_000 * 1000) * 100]

# Panel A: Full sample
ss_all <- mapped[, .(
  Mean = c(mean(accept_rate_per1000, na.rm = TRUE),
           mean(ta_rate_per1000, na.rm = TRUE),
           mean(total_decisions, na.rm = TRUE),
           mean(gap_pct, na.rm = TRUE),
           mean(claimant_rate, na.rm = TRUE),
           mean(households_000, na.rm = TRUE)),
  SD = c(sd(accept_rate_per1000, na.rm = TRUE),
         sd(ta_rate_per1000, na.rm = TRUE),
         sd(total_decisions, na.rm = TRUE),
         sd(gap_pct, na.rm = TRUE),
         sd(claimant_rate, na.rm = TRUE),
         sd(households_000, na.rm = TRUE)),
  Variable = c("Acceptance rate (per 1,000 HH)",
               "TA rate (per 1,000 HH)",
               "Total decisions",
               "LHA gap (\\%)",
               "Claimant rate (\\%)",
               "Households (000s)")
)]

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Mean & SD \\\\",
  "\\hline",
  sprintf("%s & %.2f & %.2f \\\\", ss_all$Variable, ss_all$Mean, ss_all$SD),
  "\\hline",
  sprintf("Local authorities & \\multicolumn{2}{c}{%d} \\\\", uniqueN(mapped$la_code)),
  sprintf("Quarters & \\multicolumn{2}{c}{%d} \\\\", uniqueN(mapped$yq)),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nrow(mapped), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample covers 122 English local authorities, 2014Q2--2018Q1. The LHA gap is the percentage increase between the frozen 2015--16 two-bedroom LHA rate and the re-linked 2020--21 rate for each Broad Rental Market Area.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

## -----------------------------------------------------------------------
## Table 2: Main DiD Results
## -----------------------------------------------------------------------
cat("Table 2: Main results\n")

# Extract coefficients and SEs
extract_row <- function(model, var_pattern) {
  cf <- coeftable(model)
  idx <- grep(var_pattern, rownames(cf))
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(cf[idx, "Estimate"], cf[idx, "Std. Error"], cf[idx, "Pr(>|t|)"])
}

m1_res <- extract_row(main$m1, "gap_10pp:post")
m2_res <- extract_row(main$m2, "gap_10pp:post")
m4_res <- extract_row(main$m4, "gap_10pp:post")
m5_res <- extract_row(main$m5, "gap_10pp:post")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Effect of the LHA Freeze on Homelessness}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{1}{c}{Accept. rate} & \\multicolumn{1}{c}{Log accept.} & \\multicolumn{1}{c}{TA rate} & \\multicolumn{1}{c}{TA rate} \\\\",
  " & \\multicolumn{1}{c}{(1)} & \\multicolumn{1}{c}{(2)} & \\multicolumn{1}{c}{(3)} & \\multicolumn{1}{c}{(4)} \\\\",
  "\\hline",
  sprintf("Gap $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          m1_res[1], stars(m1_res[3]),
          m2_res[1], stars(m2_res[3]),
          m4_res[1], stars(m4_res[3]),
          m5_res[1], stars(m5_res[3])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          m1_res[2], m2_res[2], m4_res[2], m5_res[2]),
  "\\\\",
  "Controls & No & No & No & Yes \\\\",
  "LA fixed effects & Yes & Yes & Yes & Yes \\\\",
  "Quarter fixed effects & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(main$m1), big.mark = ","),
          format(nobs(main$m2), big.mark = ","),
          format(nobs(main$m4), big.mark = ","),
          format(nobs(main$m5), big.mark = ",")),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(main$m1, "wr2")[[1]],
          fitstat(main$m2, "wr2")[[1]],
          fitstat(main$m4, "wr2")[[1]],
          fitstat(main$m5, "wr2")[[1]]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on Gap $\\times$ Post from the continuous difference-in-differences specification $Y_{it} = \\alpha_i + \\gamma_t + \\beta(\\text{Gap}_i \\times \\text{Post}_t) + \\varepsilon_{it}$. Gap is the percentage increase in the two-bedroom LHA rate from 2015--16 (frozen) to 2020--21 (re-linked), scaled by 10 (so coefficients represent the effect of a 10 percentage-point gap increase). Post = 1 for 2016Q2 onward. Column (4) controls for the quarterly claimant count rate. Standard errors clustered at the local authority level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "../tables/tab2_main.tex")

## -----------------------------------------------------------------------
## Table 3: Robustness Checks (TA rate)
## -----------------------------------------------------------------------
cat("Table 3: Robustness\n")

r1_res <- extract_row(robust$r1_ta, "high_gap:post")
r2_res <- extract_row(robust$r2, "gap_1bed")
r4_res <- extract_row(robust$r4, "gap_10pp:post")
r6_res <- extract_row(robust$r6, "gap_10pp:post")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Temporary Accommodation Rate}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{1}{c}{Binary} & \\multicolumn{1}{c}{1-bed gap} & \\multicolumn{1}{c}{Excl.\\ London} & \\multicolumn{1}{c}{Full sample} \\\\",
  " & \\multicolumn{1}{c}{(1)} & \\multicolumn{1}{c}{(2)} & \\multicolumn{1}{c}{(3)} & \\multicolumn{1}{c}{(4)} \\\\",
  "\\hline",
  sprintf("Treatment $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r1_res[1], stars(r1_res[3]),
          r2_res[1], stars(r2_res[3]),
          r4_res[1], stars(r4_res[3]),
          r6_res[1], stars(r6_res[3])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r1_res[2], r2_res[2], r4_res[2], r6_res[2]),
  "\\\\",
  "LA fixed effects & Yes & Yes & Yes & Yes \\\\",
  "Quarter fixed effects & Yes & Yes & Yes & Yes \\\\",
  sprintf("Local authorities & %d & %d & %d & %d \\\\",
          121, 121, 107, 313),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(robust$r1_ta), big.mark = ","),
          format(nobs(robust$r2), big.mark = ","),
          format(nobs(robust$r4), big.mark = ","),
          format(nobs(robust$r6), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is the temporary accommodation rate per 1,000 households. Column (1) uses a binary treatment indicator (above-median gap). Column (2) uses the one-bedroom LHA gap instead of two-bedroom. Column (3) excludes London boroughs. Column (4) includes all 313 English local authorities (unmapped LAs assigned median gap). All specifications include LA and quarter fixed effects. Standard errors clustered at the local authority level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "../tables/tab3_robust.tex")

## -----------------------------------------------------------------------
## Table 4: Event Study Coefficients
## -----------------------------------------------------------------------
cat("Table 4: Event study\n")
es <- main$es
es_cf <- coeftable(es)
es_dt <- data.table(
  q = as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_cf))),
  est = es_cf[, "Estimate"],
  se = es_cf[, "Std. Error"],
  p = es_cf[, "Pr(>|t|)"]
)
es_dt <- es_dt[order(q)]

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Acceptance Rate per 1,000 Households}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Quarter relative to freeze & Estimate & SE & \\\\",
  "\\hline"
)
for (i in 1:nrow(es_dt)) {
  lab <- ifelse(es_dt$q[i] == -1, "$-1$ (ref.)", sprintf("$%d$", es_dt$q[i]))
  if (es_dt$q[i] == -1) {
    tab4_lines <- c(tab4_lines, sprintf("%s & --- & --- & \\\\", lab))
  } else {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.3f%s & (%.3f) & \\\\", lab,
              es_dt$est[i], stars(es_dt$p[i]), es_dt$se[i]))
  }
}
tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from the event study specification $Y_{it} = \\alpha_i + \\gamma_t + \\sum_{q \\neq -1} \\beta_q (\\text{Gap}_i \\times \\mathbf{1}[t = q]) + \\varepsilon_{it}$. Quarter $-1$ (2016Q1) is the omitted reference period. Gap is scaled by 10. Standard errors clustered at the local authority level.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")

## -----------------------------------------------------------------------
## Table 5 (Appendix): Standardized Effect Sizes
## -----------------------------------------------------------------------
cat("Table 5: SDE appendix\n")

# Compute SDE for main outcomes
sd_accept <- sd(mapped$accept_rate_per1000, na.rm = TRUE)
sd_ta <- sd(mapped$ta_rate_per1000, na.rm = TRUE)
sd_gap <- sd(mapped$gap_10pp, na.rm = TRUE)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
beta_accept <- coef(main$m1)["gap_10pp:post"]
se_accept <- se(main$m1)["gap_10pp:post"]
sde_accept <- beta_accept * sd_gap / sd_accept
sde_se_accept <- se_accept * sd_gap / sd_accept

beta_ta <- coef(main$m4)["gap_10pp:post"]
se_ta <- se(main$m4)["gap_10pp:post"]
sde_ta <- beta_ta * sd_gap / sd_ta
sde_se_ta <- se_ta * sd_gap / sd_ta

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("Acceptance rate & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_accept, se_accept, sd_accept, sde_accept, sde_se_accept,
          classify_sde(sde_accept)),
  sprintf("TA rate & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_ta, se_ta, sd_ta, sde_ta, sde_se_ta,
          classify_sde(sde_ta)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. $X$ is the LHA gap (\\% increase from 2015--16 to 2020--21, scaled by 10). $Y$ is the outcome variable.",
  "\\item \\textbf{Country:} United Kingdom (England).",
  "\\item \\textbf{Research question:} Does the 2016--2020 freeze on Local Housing Allowance rates increase statutory homelessness? The freeze held LHA constant while market rents grew, creating differential gaps of 0--39\\% across 152 Broad Rental Market Areas.",
  "\\item \\textbf{Policy mechanism:} The LHA freeze held weekly housing benefit rates constant at 2015--16 levels for four years regardless of local rent growth, eroding affordability for private renters receiving Housing Benefit. When rates were re-linked to 30th percentile rents in April 2020, the revealed gaps ranged from 0\\% (Wirral) to 39\\% (Cambridge).",
  "\\item \\textbf{Outcome definition:} (1) Homelessness acceptances per 1,000 households: quarterly count of households accepted as unintentionally homeless and in priority need, from MHCLG Table 784a. (2) Temporary accommodation rate per 1,000 households: stock of households in temporary accommodation at quarter-end.",
  "\\item \\textbf{Treatment:} Continuous. The percentage gap between frozen 2015--16 and re-linked 2020--21 two-bedroom LHA rates by BRMA, scaled by 10.",
  "\\item \\textbf{Data:} MHCLG Table 784a (homelessness), VOA/Cambridgeshire Insight (LHA rates), NOMIS (controls). 2014Q2--2018Q1, 122 English local authorities.",
  "\\item \\textbf{Method:} Continuous difference-in-differences with LA and quarter fixed effects. Standard errors clustered at LA level.",
  "\\item \\textbf{Sample:} 122 English LAs with valid BRMA mapping, 16 quarters (8 pre-freeze, 8 post-freeze). Excluded: 204 LAs without clean BRMA assignment.",
  "\\item Classification thresholds: Large ($>$0.15), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<$0.005). Classification refers to magnitude of the standardized point estimate, not statistical significance.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
print(list.files("../tables"))

setwd("../code")
