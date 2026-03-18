## 05_tables.R — Generate all tables for apep_0717
## Benefit cap reduction → temporary accommodation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

## =========================================================================
## Table 1: Summary Statistics
## =========================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

pre <- panel[post == 0 & !is.na(ta_rate)]

## Build summary table
vars_list <- list(
  "TA households per 1,000 pop" = pre$ta_rate,
  "Capped HH per 1,000 pop" = pre$cap_intensity,
  "Claimant rate per 1,000" = pre$claimant_rate,
  "Population (thousands)" = pre$population / 1000
)

sum_rows <- lapply(names(vars_list), function(v) {
  x <- vars_list[[v]]
  data.table(Variable = v,
             Mean = mean(x, na.rm = TRUE),
             SD = sd(x, na.rm = TRUE),
             p10 = quantile(x, 0.1, na.rm = TRUE),
             Median = median(x, na.rm = TRUE),
             p90 = quantile(x, 0.9, na.rm = TRUE))
})
sum_tab <- rbindlist(sum_rows)

## LaTeX output
tex_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics, Pre-Treatment (2012--2016)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& Mean & SD & p10 & Median & p90 \\\\",
  "\\midrule"
)
for (i in 1:nrow(sum_tab)) {
  tex_lines <- c(tex_lines, sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
                                    sum_tab$Variable[i], sum_tab$Mean[i], sum_tab$SD[i],
                                    sum_tab$p10[i], sum_tab$Median[i], sum_tab$p90[i]))
}
tex_lines <- c(tex_lines,
  "\\midrule",
  sprintf("Local authorities & \\multicolumn{5}{c}{%d} \\\\", uniqueN(pre$la_code)),
  sprintf("LA $\\times$ year observations & \\multicolumn{5}{c}{%d} \\\\", nrow(pre)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Pre-treatment period is financial years ending March 2012--2016. TA households per 1,000 population is from MHCLG Table 784. Capped households per 1,000 population measured at May 2017 (first post-reduction snapshot). Claimant rate is the annual average JSA/UC claimant count per 1,000 population from NOMIS. Sample restricted to 278 English local authorities with non-missing data in all periods.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tex_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

## =========================================================================
## Table 2: Main Results
## =========================================================================

cat("=== Generating Table 2: Main Results ===\n")

m1 <- models$m1
m2 <- models$m2
m3 <- models$m3
m4 <- models$m4

## Extract coefficients
extract_row <- function(m, coef_name) {
  idx <- grep(coef_name, names(coef(m)), fixed = TRUE)
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(coef(m)[idx], se(m)[idx], pvalue(m)[idx])
}

r1 <- extract_row(m1, "cap_intensity:post")
r2 <- extract_row(m2, "cap_intensity:post")
r3 <- extract_row(m3, "cap_intensity:post")
r4 <- extract_row(m4, "cap_intensity:post")

star <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

tex_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Benefit Cap Reduction on Temporary Accommodation}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Cap intensity $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r1[1], star(r1[3]), r2[1], star(r2[3]), r3[1], star(r3[3]), r4[1], star(r4[3])),
  sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r1[2], r2[2], r3[2], r4[2]),
  "\\addlinespace",
  sprintf("Claimant rate & & %.3f & & \\\\", coef(m2)["claimant_rate"]),
  sprintf("& & (%.3f) & & \\\\", se(m2)["claimant_rate"]),
  "\\midrule",
  "LA FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & \\\\",
  "Region $\\times$ year FE & & & & Yes \\\\",
  "Sample & Full & Full & Ex. London & Full \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  sprintf("LAs & %d & %d & %d & %d \\\\",
          fixef(m1, sorted = TRUE) |> lengths() |> (function(x) x["la_code"])(),
          fixef(m2, sorted = TRUE) |> lengths() |> (function(x) x["la_code"])(),
          fixef(m3, sorted = TRUE) |> lengths() |> (function(x) x["la_code"])(),
          fixef(m4, sorted = TRUE) |> lengths() |> (function(x) x["la_code"])()),
  sprintf("Within $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]], fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is households in temporary accommodation per 1,000 population, measured annually at 31 March (Table 784). Cap intensity is capped households per 1,000 population at May 2017. Post equals one for years 2017--2018. Standard errors clustered at the local authority level in parentheses. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tex_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

## =========================================================================
## Table 3: Event Study Coefficients
## =========================================================================

cat("=== Generating Table 3: Event Study ===\n")

m_event <- models$m_event
ev_coefs <- coef(m_event)
ev_se <- se(m_event)
ev_pval <- pvalue(m_event)

years_show <- c(2012, 2013, 2014, 2015, 2017, 2018)
coef_names <- paste0("year_f::", years_show, ":cap_intensity")

tex_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Cap Intensity $\\times$ Year Interactions}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year & Coefficient & SE \\\\",
  "\\midrule"
)
for (i in seq_along(years_show)) {
  yr <- years_show[i]
  nm <- coef_names[i]
  b <- ev_coefs[nm]
  s <- ev_se[nm]
  p <- ev_pval[nm]
  tex_lines <- c(tex_lines, sprintf("%d & %.3f%s & (%.3f) \\\\", yr, b, star(p), s))
  if (yr == 2015) {
    tex_lines <- c(tex_lines,
      "2016 (ref.) & --- & --- \\\\",
      "\\midrule")
  }
}
tex_lines <- c(tex_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\", nobs(m_event)),
  sprintf("LAs & \\multicolumn{2}{c}{%d} \\\\", fixef(m_event, sorted = TRUE) |> lengths() |> (function(x) x["la_code"])()),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each coefficient is the interaction of cap intensity (capped households per 1,000 population) with a year indicator, relative to 2016 (last pre-treatment year). LA and year fixed effects included. Standard errors clustered at the LA level. Significant pre-trend coefficients indicate that high-cap-intensity LAs were already experiencing faster TA growth before the November 2016 cap reduction. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tex_lines, file.path(tables_dir, "tab3_event.tex"))
cat("  Written tab3_event.tex\n")

## =========================================================================
## Table 4: Robustness
## =========================================================================

cat("=== Generating Table 4: Robustness ===\n")

## Build robustness rows
rob_row <- function(label, m, cn) {
  b <- coef(m)[cn]
  s <- se(m)[cn]
  p <- pvalue(m)[cn]
  n <- nobs(m)
  sprintf("%s & %.3f%s & (%.3f) & %d \\\\", label, b, star(p), s, n)
}

tex_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $N$ \\\\",
  "\\midrule",
  rob_row("Baseline", models$m1, "cap_intensity:post"),
  rob_row("First difference", rob_models$m_fd, "cap_intensity:post"),
  rob_row("Log outcome", rob_models$m_log, "cap_intensity:post"),
  rob_row("Excl.\\ top 5\\%", rob_models$m_no_outlier, "cap_intensity:post"),
  rob_row("Excl.\\ London", rob_models$m_no_london, "cap_intensity:post"),
  rob_row("Placebo (2015)", rob_models$m_placebo2015, "cap_intensity:placebo_post"),
  rob_row("Placebo (2014)", rob_models$m_placebo2014, "cap_intensity:placebo_post14")
)
tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Row 1 replicates the baseline from Table \\ref{tab:main}. Rows 2--5 vary the specification or sample. Rows 6--7 assign placebo treatment dates within the pre-period. Significance of placebo tests (rows 6--7) confirms pre-existing differential trends between high- and low-cap-intensity LAs. Standard errors clustered at the LA level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tex_lines, file.path(tables_dir, "tab4_robust.tex"))
cat("  Written tab4_robust.tex\n")

## =========================================================================
## Table F1: Standardized Effect Sizes (SDE)
## =========================================================================

cat("=== Generating SDE Table ===\n")

pre_data <- panel[post == 0]
sd_y <- sd(pre_data$ta_rate, na.rm = TRUE)

## Main outcome: TA rate
m1 <- models$m1
beta1 <- coef(m1)["cap_intensity:post"]
se1 <- se(m1)["cap_intensity:post"]
sde1 <- beta1 / sd_y
se_sde1 <- se1 / sd_y

## Log outcome
m_log <- rob_models$m_log
sd_logy <- sd(log(pre_data$ta_rate + 0.01), na.rm = TRUE)
beta_log <- coef(m_log)["cap_intensity:post"]
se_log <- se(m_log)["cap_intensity:post"]
sde_log <- beta_log / sd_logy
se_sde_log <- se_log / sd_logy

## Classify
classify <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  return("Small negative")
}

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does reducing the household benefit cap increase local authority temporary accommodation burdens? ",
  "\\textbf{Policy mechanism:} The November 2016 benefit cap reduction from \\pounds26,000 to \\pounds20,000/\\pounds23,000 limited total welfare payments for out-of-work households, potentially forcing rent shortfalls and housing displacement. ",
  "\\textbf{Outcome definition:} Households in temporary accommodation per 1,000 population at end of financial year, from MHCLG statutory homelessness Table 784. ",
  "\\textbf{Treatment:} Continuous; capped households per 1,000 population at May 2017. ",
  "\\textbf{Data:} MHCLG Table 784 (2013--2018), DWP benefit cap statistics, NOMIS population estimates; 278 English local authorities observed annually. ",
  "\\textbf{Method:} TWFE with LA and year fixed effects; standard errors clustered at LA level. ",
  "\\textbf{Sample:} English local authorities with non-missing TA data across all six years; 1,592 LA-year observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tex_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("TA per 1,000 & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
          beta1, se1, sd_y, sde1, se_sde1, classify(sde1)),
  sprintf("Log(TA + 0.01) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_log, se_log, sd_logy, sde_log, se_sde_log, classify(sde_log)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tex_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
