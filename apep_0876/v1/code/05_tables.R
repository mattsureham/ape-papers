## 05_tables.R — Generate all tables for the paper
source("00_packages.R")

main <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
df <- readRDS("../data/analysis_panel.rds")

cat("=== Generating Tables ===\n")

## ------------------------------------------------------------------
## Helper: format coefficient
## ------------------------------------------------------------------
fmt_coef <- function(x, digits = 4) {
  formatC(x, digits = digits, format = "f")
}
fmt_se <- function(x, digits = 4) {
  paste0("(", formatC(x, digits = digits, format = "f"), ")")
}
stars <- function(coef, se) {
  t <- abs(coef / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

# LaTeX-safe bracket labels
bracket_tex <- c("Under \\$10K", "\\$10--25K", "\\$25--50K", "\\$50--75K",
                  "\\$75--100K", "\\$100--200K", "\\$200K+")

## ------------------------------------------------------------------
## Table 1: Summary Statistics
## ------------------------------------------------------------------
cat("  Table 1: Summary Statistics\n")

sumstats <- main$sumstats
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by AGI Bracket}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "AGI Bracket & Mean Net & SD Net & Mean Out- & Mean In- & Mean Total & Obs. \\\\",
  " & Mig.\\ Rate & Mig.\\ Rate & flow Rate & flow Rate & Returns & \\\\",
  "\\midrule"
)

for (i in 1:nrow(sumstats)) {
  r <- sumstats[i]
  tab1_lines <- c(tab1_lines, paste0(
    bracket_tex[i], " & ",
    fmt_coef(r$mean_net_mig, 4), " & ",
    fmt_coef(r$sd_net_mig, 4), " & ",
    fmt_coef(r$mean_outflow, 4), " & ",
    fmt_coef(r$mean_inflow, 4), " & ",
    formatC(round(r$mean_total_returns), format = "d", big.mark = ","), " & ",
    formatC(r$n_obs, format = "d", big.mark = ","), " \\\\"
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} IRS SOI state-to-state migration files, 2011--2021. Net migration rate = (inflows $-$ outflows) / total returns. Unit of observation: state $\\times$ year $\\times$ AGI bracket. $N = 3{,}927$ state-bracket-year cells (51 jurisdictions $\\times$ 7 brackets $\\times$ 11 years).} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

## ------------------------------------------------------------------
## Table 2: Income Gradient of SALT Migration Response
## ------------------------------------------------------------------
cat("  Table 2: Income Gradient\n")

bd <- main$bracket_dt
tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Income Gradient of Tax-Induced Migration: SALT Cap Effects by AGI Bracket}",
  "\\label{tab:gradient}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "AGI Bracket & SALT$_z \\times$ Post & SE & 95\\% CI & $N$ \\\\",
  "\\midrule"
)

for (i in 1:nrow(bd)) {
  r <- bd[i]
  s <- stars(r$coef, r$se)
  tab2_lines <- c(tab2_lines, paste0(
    bracket_tex[i], " & ",
    fmt_coef(r$coef, 5), s, " & ",
    fmt_se(r$se, 5), " & ",
    "[", fmt_coef(r$ci_lo, 5), ", ", fmt_coef(r$ci_hi, 5), "] & ",
    formatC(r$nobs, format = "d", big.mark = ","), " \\\\"
  ))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\multicolumn{5}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Each row is a separate regression of net migration rate on SALT$_z \\times$ Post, where SALT$_z$ is the standardized state-level average SALT deduction in 2017. Post $= 1$ for years $\\geq$ 2018 (TCJA). All specifications include state and year fixed effects. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_gradient.tex")

## ------------------------------------------------------------------
## Table 3: Triple-Difference (Main Result)
## ------------------------------------------------------------------
cat("  Table 3: Triple-Difference\n")

m1 <- main$m1_triple
m2 <- main$m2_dose
m_out <- main$m4_out
m_in <- main$m4_in

get_row <- function(mod, var) {
  cf <- coef(mod)
  vc <- vcov(mod)
  idx <- grep(var, names(cf), fixed = TRUE)
  if (length(idx) == 0) return(c(NA, NA))
  c(cf[idx[1]], sqrt(vc[idx[1], idx[1]]))
}

r1 <- get_row(m1, "high_salt_post")
r2 <- get_row(m2, "salt_post_high")
r3 <- get_row(m_out, "high_salt_post")
r4 <- get_row(m_in, "high_salt_post")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{SALT Cap and High-Income Migration: Triple-Difference Estimates}",
  "\\label{tab:triple}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Net Migration Rate} & Outflow & Inflow \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  paste0("High SALT $\\times$ Post $\\times$ High Inc.\\ & ",
    fmt_coef(r1[1], 5), stars(r1[1], r1[2]), " & & ",
    fmt_coef(r3[1], 5), stars(r3[1], r3[2]), " & ",
    fmt_coef(r4[1], 5), stars(r4[1], r4[2]), " \\\\"),
  paste0(" & ", fmt_se(r1[2], 5), " & & ",
    fmt_se(r3[2], 5), " & ", fmt_se(r4[2], 5), " \\\\"),
  "[0.5em]",
  paste0("SALT$_z \\times$ Post $\\times$ High Inc.\\ & & ",
    fmt_coef(r2[1], 5), stars(r2[1], r2[2]), " & & \\\\"),
  paste0(" & & ", fmt_se(r2[2], 5), " & & \\\\"),
  "\\midrule",
  paste0("Observations & ", formatC(nobs(m1), format = "d", big.mark = ","),
    " & ", formatC(nobs(m2), format = "d", big.mark = ","),
    " & ", formatC(nobs(m_out), format = "d", big.mark = ","),
    " & ", formatC(nobs(m_in), format = "d", big.mark = ","), " \\\\"),
  "State $\\times$ Bracket FE & Yes & Yes & Yes & Yes \\\\",
  "Year $\\times$ Bracket FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Columns (1) and (2) estimate the differential migration response of high-income filers (AGI $\\geq$ \\$100K) in high-SALT states after the 2018 TCJA cap. Column (1) uses a binary high-SALT indicator ($\\geq$ \\$13K average deduction); column (2) uses standardized continuous SALT exposure. Columns (3)--(4) decompose into outflow and inflow channels. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_triple.tex")

## ------------------------------------------------------------------
## Table 4: Robustness
## ------------------------------------------------------------------
cat("  Table 4: Robustness\n")

rob_rows <- list(
  list("Baseline", r1[1], r1[2], nobs(m1)),
  list("State$\\times$bracket clustering",
       get_row(rob$m_alt_cluster, "high_salt_post")[1],
       get_row(rob$m_alt_cluster, "high_salt_post")[2],
       nobs(rob$m_alt_cluster)),
  list("Excl.\\ NY, NJ, CT",
       get_row(rob$m_no_top3, "high_salt_post")[1],
       get_row(rob$m_no_top3, "high_salt_post")[2],
       nobs(rob$m_no_top3)),
  list("Excl.\\ 2020--2021 (COVID)",
       get_row(rob$m_no_covid, "high_salt_post")[1],
       get_row(rob$m_no_covid, "high_salt_post")[2],
       nobs(rob$m_no_covid))
)

# Add placebo
plac_cf <- coef(rob$m_placebo)
plac_vc <- vcov(rob$m_placebo)
plac_idx <- grep("high_salt.*post_salt", names(plac_cf))
if (length(plac_idx) > 0) {
  rob_rows[[5]] <- list("Placebo: AGI $<$ \\$50K",
                          plac_cf[plac_idx[1]], sqrt(plac_vc[plac_idx[1], plac_idx[1]]),
                          nobs(rob$m_placebo))
}

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Triple-Difference Estimate}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $N$ \\\\",
  "\\midrule"
)

for (rr in rob_rows) {
  if (is.null(rr)) next
  s <- if (!is.na(rr[[2]]) & !is.na(rr[[3]])) stars(rr[[2]], rr[[3]]) else ""
  tab4_lines <- c(tab4_lines, paste0(
    rr[[1]], " & ",
    if (!is.na(rr[[2]])) fmt_coef(rr[[2]], 5) else "---", s, " & ",
    if (!is.na(rr[[3]])) fmt_se(rr[[3]], 5) else "---", " & ",
    formatC(rr[[4]], format = "d", big.mark = ","), " \\\\"
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Each row reports the High SALT $\\times$ Post $\\times$ High Income coefficient from a variant of the triple-difference specification in \\Cref{tab:triple}. The placebo restricts to AGI brackets 1--3 (under \\$50K), who should not respond to the SALT cap. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

## ------------------------------------------------------------------
## Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
## ------------------------------------------------------------------
cat("  Table F1: SDE\n")

main_coef <- r1[1]
main_se <- r1[2]

sd_y_main <- df[year < 2018 & high_income == 1 & high_salt == 1,
                sd(net_mig_rate, na.rm = TRUE)]
sde_main <- main_coef / sd_y_main
sde_se_main <- main_se / sd_y_main

out_coef <- r3[1]
out_se <- r3[2]
in_coef <- r4[1]
in_se <- r4[2]

sd_y_out <- df[year < 2018 & high_income == 1 & high_salt == 1,
               sd(outflow_rate, na.rm = TRUE)]
sd_y_in <- df[year < 2018 & high_income == 1 & high_salt == 1,
              sd(inflow_rate, na.rm = TRUE)]

sde_out <- out_coef / sd_y_out
sde_se_out <- out_se / sd_y_out
sde_in <- in_coef / sd_y_in
sde_se_in <- in_se / sd_y_in

# Heterogeneity
bd <- main$bracket_dt
b7 <- bd[bracket == 7]
b6 <- bd[bracket == 6]

sd_y_b7 <- df[year < 2018 & agi_bracket == 7, sd(net_mig_rate, na.rm = TRUE)]
sd_y_b6 <- df[year < 2018 & agi_bracket == 6, sd(net_mig_rate, na.rm = TRUE)]

sde_b7 <- b7$coef / sd_y_b7
sde_se_b7 <- b7$se / sd_y_b7
sde_b6 <- b6$coef / sd_y_b6
sde_se_b6 <- b6$se / sd_y_b6

classify_sde <- function(x) {
  if (is.na(x)) return("---")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- list(
  list("panel", "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\", NA, NA, NA, NA, NA, NA),
  list("data", "Net migration rate", main_coef, main_se, sd_y_main, sde_main, sde_se_main, classify_sde(sde_main)),
  list("data", "Outflow rate", out_coef, out_se, sd_y_out, sde_out, sde_se_out, classify_sde(sde_out)),
  list("data", "Inflow rate", in_coef, in_se, sd_y_in, sde_in, sde_se_in, classify_sde(sde_in)),
  list("panel", "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by income bracket)}} \\\\", NA, NA, NA, NA, NA, NA),
  list("data", "Net mig.\\ rate (\\$200K+)", b7$coef, b7$se, sd_y_b7, sde_b7, sde_se_b7, classify_sde(sde_b7)),
  list("data", "Net mig.\\ rate (\\$100--200K)", b6$coef, b6$se, sd_y_b6, sde_b6, sde_se_b6, classify_sde(sde_b6))
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the SALT deduction cap differentially induce net outmigration ",
  "of high-income tax filers from states with historically large state and local tax deductions? ",
  "\\textbf{Policy mechanism:} The 2017 Tax Cuts and Jobs Act capped the federal deduction for state ",
  "and local taxes at \\$10,000, sharply raising the effective after-tax cost of residing in high-tax ",
  "states for itemizers whose SALT deductions previously exceeded the cap. ",
  "\\textbf{Outcome definition:} Net migration rate, defined as (inflow returns $-$ outflow returns) / ",
  "total returns from IRS SOI state-to-state migration files, measured at the state-year-AGI bracket level. ",
  "\\textbf{Treatment:} Binary; high-SALT state (average 2017 SALT deduction $\\geq$ \\$13,000) $\\times$ ",
  "post-TCJA (year $\\geq$ 2018) $\\times$ high-income bracket (AGI $\\geq$ \\$100,000). ",
  "\\textbf{Data:} IRS SOI state-to-state migration files, 51 jurisdictions $\\times$ 7 AGI brackets ",
  "$\\times$ 11 years (2011--2021); unit of observation is state-year-bracket. ",
  "\\textbf{Method:} Triple-difference with state$\\times$bracket, year$\\times$bracket, and state$\\times$year ",
  "fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 states plus DC; AGI brackets from under \\$10K to \\$200K+; ",
  "excludes U.S. territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for the relevant subsample. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (rr in sde_rows) {
  if (rr[[1]] == "panel") {
    tabF1_lines <- c(tabF1_lines, rr[[2]])
  } else {
    s <- stars(rr[[3]], rr[[4]])
    tabF1_lines <- c(tabF1_lines, paste0(
      rr[[2]], " & ",
      fmt_coef(rr[[3]], 5), s, " & ",
      fmt_se(rr[[4]], 5), " & ",
      fmt_coef(rr[[5]], 4), " & ",
      fmt_coef(rr[[6]], 3), " & ",
      fmt_se(rr[[7]], 3), " & ",
      rr[[8]], " \\\\"
    ))
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\begin{itemize}[leftmargin=*]",
  sde_notes,
  "\\end{itemize}",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
