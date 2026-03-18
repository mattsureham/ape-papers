## 05_tables.R — Generate all LaTeX tables
## apep_0721: UK NLW Wage Distribution Compression

source("00_packages.R")

# ============================================================================
# Load saved results
# ============================================================================
cat("=== Loading data and results ===\n")
df            <- readRDS("../data/analysis_dataset.rds")
main_results  <- readRDS("../data/main_results.rds")
ratio_results <- readRDS("../data/ratio_results.rds")
rob_results   <- readRDS("../data/robustness_results.rds")
bite_2015     <- readRDS("../data/bite_2015.rds")

# Ensure tables directory exists
dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# Helper: stars from p-value
# ============================================================================
fmt_star <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

# Helper: format coefficient with star
fmt_coef <- function(b, pval, digits = 4) {
  if (is.na(b)) return("---")
  sprintf("%.%df%s" |> gsub("%df", paste0(digits, "f"), x = _), b, fmt_star(pval))
}

# Helper: format SE in parentheses
fmt_se <- function(se, digits = 4) {
  if (is.na(se)) return("---")
  sprintf("(%.%df)" |> gsub("%df", paste0(digits, "f"), x = _), se)
}

# Simpler formatting helpers (avoid pipe operator complications)
coef_star <- function(b, pval, digits = 4) {
  if (is.na(b)) return("---")
  paste0(formatC(b, format = "f", digits = digits), fmt_star(pval))
}

se_paren <- function(se_val, digits = 4) {
  if (is.na(se_val)) return("---")
  paste0("(", formatC(se_val, format = "f", digits = digits), ")")
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

pcts <- c("p10", "p25", "p50", "p60", "p90")
pct_labels <- c("p10", "p25", "p50", "p60", "p90")

# Pre-NLW (2015) and post-NLW (2023) stats
pre  <- df %>% filter(year == 2015)
post <- df %>% filter(year == 2023)

# High-bite vs low-bite split
med_bite <- median(bite_2015$bite, na.rm = TRUE)
pre_hi   <- pre  %>% filter(high_bite == 1)
pre_lo   <- pre  %>% filter(high_bite == 0)
post_hi  <- post %>% filter(high_bite == 1)
post_lo  <- post %>% filter(high_bite == 0)

# Build summary rows
make_row <- function(dat, pvar) {
  vals <- dat[[pvar]]
  sprintf("%.2f & %.2f", mean(vals, na.rm = TRUE), sd(vals, na.rm = TRUE))
}

lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Wage Percentiles by Period and LA Bite Group}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{High-Bite LAs} & \\multicolumn{2}{c}{Low-Bite LAs} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pre-NLW (2015, £/hour)}} \\\\"
)

for (p in pcts) {
  row <- sprintf("\\quad %s & %s & %s & %s \\\\",
                 toupper(p),
                 make_row(pre, p),
                 make_row(pre_hi, p),
                 make_row(pre_lo, p))
  lines <- c(lines, row)
}

# Bite ratio row — pre-period
bite_full <- bite_2015$bite
bite_hi   <- bite_2015 %>% filter(bite >= med_bite) %>% pull(bite)
bite_lo   <- bite_2015 %>% filter(bite <  med_bite) %>% pull(bite)
bite_row  <- sprintf("\\quad Bite ratio & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
                     mean(bite_full, na.rm = TRUE), sd(bite_full, na.rm = TRUE),
                     mean(bite_hi, na.rm = TRUE),   sd(bite_hi, na.rm = TRUE),
                     mean(bite_lo, na.rm = TRUE),   sd(bite_lo, na.rm = TRUE))
lines <- c(lines, bite_row)

lines <- c(lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Post-NLW (2023, £/hour)}} \\\\"
)

for (p in pcts) {
  row <- sprintf("\\quad %s & %s & %s & %s \\\\",
                 toupper(p),
                 make_row(post, p),
                 make_row(post_hi, p),
                 make_row(post_lo, p))
  lines <- c(lines, row)
}

n_full <- n_distinct(df$la_code)
n_hi   <- n_distinct(df$la_code[df$high_bite == 1])
n_lo   <- n_distinct(df$la_code[df$high_bite == 0])
obs_full <- nrow(df)
obs_hi   <- nrow(df %>% filter(high_bite == 1))
obs_lo   <- nrow(df %>% filter(high_bite == 0))

n_row  <- sprintf("\\quad $N$ (LAs) & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
                  n_full, n_hi, n_lo)
ob_row <- sprintf("\\quad Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
                  obs_full, obs_hi, obs_lo)

lines <- c(lines, n_row, ob_row,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\raggedright\\footnotesize\\textit{Notes:} Unit of observation is Local Authority (LA) $\\times$ year. ",
         "Wage percentiles are gross hourly wages in £ from ASHE (Annual Survey of Hours and Earnings), ",
         "Office for National Statistics. Bite ratio is the 2015 National Minimum Wage (£6.50) divided by the ",
         "LA median wage in 2015. High-bite LAs are those with bite ratio at or above the median across all LAs ",
         "(threshold: ", sprintf("%.3f", med_bite), "). Stars: *** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{table}"
)

writeLines(lines, "../tables/tab1_summary.tex")
cat("  Saved tab1_summary.tex\n")

# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================
cat("\n=== Table 2: Main DiD Results ===\n")

outcomes    <- c("log_p10", "log_p25", "log_p50", "log_p60", "log_p90")
col_labels  <- c("Log p10", "Log p25", "Log p50", "Log p60", "Log p90")

coefs  <- sapply(outcomes, function(y) coef(main_results[[y]])["bite_post"])
ses    <- sapply(outcomes, function(y) se(main_results[[y]])["bite_post"])
pvals  <- sapply(outcomes, function(y) pvalue(main_results[[y]])["bite_post"])
nobs   <- sapply(outcomes, function(y) fitstat(main_results[[y]], "n")[[1]])
r2s    <- sapply(outcomes, function(y) fitstat(main_results[[y]], "r2")[[1]])

lines2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of NLW Bite on Log Wage Percentiles: Main DiD Results}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log p10 & Log p25 & Log p50 & Log p60 & Log p90 \\\\",
  "\\hline",
  "\\textit{Dependent variable:} & & & & & \\\\"
)

# Bite × Post row
bp_row <- paste0("Bite $\\times$ Post  & ",
                 paste(sapply(seq_along(outcomes), function(i)
                   coef_star(coefs[i], pvals[i])), collapse = " & "),
                 " \\\\")
se_row <- paste0(" & ",
                 paste(sapply(seq_along(outcomes), function(i)
                   se_paren(ses[i])), collapse = " & "),
                 " \\\\")

lines2 <- c(lines2, bp_row, se_row,
  "\\hline",
  "LA FE           & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE         & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustered SE    & LA  & LA  & LA  & LA  & LA  \\\\"
)

# Observations
obs_row <- paste0("Observations    & ",
                  paste(formatC(nobs, format = "d", big.mark = ","), collapse = " & "),
                  " \\\\")
r2_row  <- paste0("$R^2$           & ",
                  paste(sprintf("%.3f", r2s), collapse = " & "),
                  " \\\\")

lines2 <- c(lines2, obs_row, r2_row,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\raggedright\\footnotesize\\textit{Notes:} All regressions include LA and year fixed effects. ",
         "Standard errors clustered at the LA level in parentheses. ",
         "Bite $\\times$ Post is the interaction of the 2015 NMW bite ratio (£6.50/LA median wage) ",
         "with an indicator for years 2016 and later (post-NLW introduction). ",
         "Data: ASHE 2013--2023, all Local Authorities in England and Wales. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{table}"
)

writeLines(lines2, "../tables/tab2_main.tex")
cat("  Saved tab2_main.tex\n")

# ============================================================================
# TABLE 3: Percentile Ratio Results
# ============================================================================
cat("\n=== Table 3: Percentile Ratio Results ===\n")

ratio_outcomes <- c("p10_p50", "p25_p50", "p10_p90")
ratio_labels3  <- c("p10/p50", "p25/p50", "p10/p90")

r_coefs <- sapply(ratio_outcomes, function(y) coef(ratio_results[[y]])["bite_post"])
r_ses   <- sapply(ratio_outcomes, function(y) se(ratio_results[[y]])["bite_post"])
r_pvals <- sapply(ratio_outcomes, function(y) pvalue(ratio_results[[y]])["bite_post"])
r_nobs  <- sapply(ratio_outcomes, function(y) fitstat(ratio_results[[y]], "n")[[1]])
r_r2s   <- sapply(ratio_outcomes, function(y) fitstat(ratio_results[[y]], "r2")[[1]])

lines3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of NLW Bite on Wage Percentile Ratios}",
  "\\label{tab:ratios}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  " & p10/p50 & p25/p50 & p10/p90 \\\\",
  "\\hline",
  "\\textit{Dependent variable:} & & & \\\\"
)

rr_bp  <- paste0("Bite $\\times$ Post  & ",
                 paste(sapply(seq_along(ratio_outcomes), function(i)
                   coef_star(r_coefs[i], r_pvals[i])), collapse = " & "),
                 " \\\\")
rr_se  <- paste0(" & ",
                 paste(sapply(seq_along(ratio_outcomes), function(i)
                   se_paren(r_ses[i])), collapse = " & "),
                 " \\\\")

r_obs_row <- paste0("Observations    & ",
                    paste(formatC(r_nobs, format = "d", big.mark = ","), collapse = " & "),
                    " \\\\")
r_r2_row  <- paste0("$R^2$           & ",
                    paste(sprintf("%.3f", r_r2s), collapse = " & "),
                    " \\\\")

lines3 <- c(lines3, rr_bp, rr_se,
  "\\hline",
  "LA FE        & Yes & Yes & Yes \\\\",
  "Year FE      & Yes & Yes & Yes \\\\",
  "Clustered SE & LA  & LA  & LA  \\\\",
  r_obs_row, r_r2_row,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\raggedright\\footnotesize\\textit{Notes:} Dependent variables are wage percentile ratios, ",
         "which increase when the wage distribution compresses from below. ",
         "A positive coefficient on Bite $\\times$ Post indicates that higher-bite LAs experienced ",
         "greater compression at the bottom of the distribution following NLW introduction. ",
         "All regressions include LA and year fixed effects with standard errors clustered at the LA level. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{table}"
)

writeLines(lines3, "../tables/tab3_ratios.tex")
cat("  Saved tab3_ratios.tex\n")

# ============================================================================
# TABLE 4: Robustness Panel (p10 outcome)
# ============================================================================
cat("\n=== Table 4: Robustness Panel ===\n")

# Extract each robustness spec
specs <- list(
  list(label = "Baseline",
       fit = main_results[["log_p10"]],
       coef_name = "bite_post",
       note = "Main specification (bite = NMW/p50)"),
  list(label = "Alt.\\ bite (NMW/p25)",
       fit = rob_results[["alt_bite_p10"]],
       coef_name = "bite_p25_post",
       note = "Bite ratio computed using LA p25 wage as denominator"),
  list(label = "Excl.\\ London",
       fit = rob_results[["no_london_p10"]],
       coef_name = "bite_post",
       note = "Excludes all London boroughs and City of London"),
  list(label = "Region $\\times$ Year FE",
       fit = rob_results[["reg_fe_p10"]],
       coef_name = "bite_post",
       note = "Adds region $\\times$ year fixed effects to absorb regional trends"),
  list(label = "Placebo (pre-period)",
       fit = rob_results[["placebo_p10"]],
       coef_name = "bite_placebo",
       note = "Placebo test using 2013--2015 subsample; treatment assigned to 2015")
)

rb_coefs <- sapply(specs, function(s) coef(s$fit)[s$coef_name])
rb_ses   <- sapply(specs, function(s) se(s$fit)[s$coef_name])
rb_pvals <- sapply(specs, function(s) pvalue(s$fit)[s$coef_name])
rb_nobs  <- sapply(specs, function(s) fitstat(s$fit, "n")[[1]])
rb_r2s   <- sapply(specs, function(s) fitstat(s$fit, "r2")[[1]])

lines4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Effect of NLW Bite on Log p10}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & Alt.\\ Bite & No London & Region$\\times$Yr & Placebo \\\\",
  "\\hline"
)

rb_bp_row <- paste0("Bite $\\times$ Post & ",
                    paste(sapply(seq_along(specs), function(i)
                      coef_star(rb_coefs[i], rb_pvals[i])), collapse = " & "),
                    " \\\\")
rb_se_row <- paste0(" & ",
                    paste(sapply(seq_along(specs), function(i)
                      se_paren(rb_ses[i])), collapse = " & "),
                    " \\\\")

rb_obs_row <- paste0("Observations & ",
                     paste(formatC(rb_nobs, format = "d", big.mark = ","), collapse = " & "),
                     " \\\\")
rb_r2_row  <- paste0("$R^2$        & ",
                     paste(sprintf("%.3f", rb_r2s), collapse = " & "),
                     " \\\\")

lines4 <- c(lines4, rb_bp_row, rb_se_row,
  "\\hline",
  "LA FE          & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE        & Yes & Yes & Yes & Yes & Yes \\\\",
  "Region$\\times$Year & No & No & No & Yes & No \\\\",
  rb_obs_row, rb_r2_row,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\raggedright\\footnotesize\\textit{Notes:} Dependent variable is log hourly wage at the 10th percentile. ",
         "Column (1) replicates the main specification. ",
         "Column (2) uses the NMW/p25 bite ratio instead of NMW/p50. ",
         "Column (3) excludes London boroughs, which have structurally higher wages and lower bite. ",
         "Column (4) adds region $\\times$ year fixed effects to absorb differential regional wage trends. ",
         "Column (5) is a placebo test using only pre-NLW years (2013--2015): ",
         "a statistically insignificant coefficient supports the parallel-trends assumption. ",
         "All standard errors clustered at the LA level. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{table}"
)

writeLines(lines4, "../tables/tab4_robustness.tex")
cat("  Saved tab4_robustness.tex\n")

# ============================================================================
# TABLE 5: Heterogeneity — High-bite vs Low-bite split samples
# ============================================================================
cat("\n=== Table 5: Heterogeneity by Bite Group ===\n")

df_hi <- df %>% filter(high_bite == 1)
df_lo <- df %>% filter(high_bite == 0)

het_specs <- list(
  list(yvar = "log_p10", label = "Log p10"),
  list(yvar = "log_p25", label = "Log p25")
)

het_fits <- list()
for (s in het_specs) {
  fml <- as.formula(paste0(s$yvar, " ~ bite_post | la_code + year"))
  het_fits[[paste0(s$yvar, "_hi")]] <- feols(fml, data = df_hi, cluster = ~la_code)
  het_fits[[paste0(s$yvar, "_lo")]] <- feols(fml, data = df_lo, cluster = ~la_code)
}

# Extract
h_coefs <- c(
  coef(het_fits[["log_p10_hi"]])["bite_post"],
  coef(het_fits[["log_p10_lo"]])["bite_post"],
  coef(het_fits[["log_p25_hi"]])["bite_post"],
  coef(het_fits[["log_p25_lo"]])["bite_post"]
)
h_ses <- c(
  se(het_fits[["log_p10_hi"]])["bite_post"],
  se(het_fits[["log_p10_lo"]])["bite_post"],
  se(het_fits[["log_p25_hi"]])["bite_post"],
  se(het_fits[["log_p25_lo"]])["bite_post"]
)
h_pvals <- c(
  pvalue(het_fits[["log_p10_hi"]])["bite_post"],
  pvalue(het_fits[["log_p10_lo"]])["bite_post"],
  pvalue(het_fits[["log_p25_hi"]])["bite_post"],
  pvalue(het_fits[["log_p25_lo"]])["bite_post"]
)
h_nobs <- c(
  fitstat(het_fits[["log_p10_hi"]], "n")[[1]],
  fitstat(het_fits[["log_p10_lo"]], "n")[[1]],
  fitstat(het_fits[["log_p25_hi"]], "n")[[1]],
  fitstat(het_fits[["log_p25_lo"]], "n")[[1]]
)
h_r2s <- c(
  fitstat(het_fits[["log_p10_hi"]], "r2")[[1]],
  fitstat(het_fits[["log_p10_lo"]], "r2")[[1]],
  fitstat(het_fits[["log_p25_hi"]], "r2")[[1]],
  fitstat(het_fits[["log_p25_lo"]], "r2")[[1]]
)

lines5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by NLW Bite Intensity: Split-Sample Results}",
  "\\label{tab:heterogeneity}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Log p10} & \\multicolumn{2}{c}{Log p25} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  " & High-Bite & Low-Bite & High-Bite & Low-Bite \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline"
)

h_bp_row <- paste0("Bite $\\times$ Post & ",
                   paste(sapply(1:4, function(i) coef_star(h_coefs[i], h_pvals[i])),
                         collapse = " & "),
                   " \\\\")
h_se_row <- paste0(" & ",
                   paste(sapply(1:4, function(i) se_paren(h_ses[i])),
                         collapse = " & "),
                   " \\\\")
h_obs_row <- paste0("Observations & ",
                    paste(formatC(h_nobs, format = "d", big.mark = ","), collapse = " & "),
                    " \\\\")
h_r2_row  <- paste0("$R^2$        & ",
                    paste(sprintf("%.3f", h_r2s), collapse = " & "),
                    " \\\\")

lines5 <- c(lines5, h_bp_row, h_se_row,
  "\\hline",
  "LA FE        & Yes & Yes & Yes & Yes \\\\",
  "Year FE      & Yes & Yes & Yes & Yes \\\\",
  "Clustered SE & LA  & LA  & LA  & LA  \\\\",
  h_obs_row, h_r2_row,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\raggedright\\footnotesize\\textit{Notes:} Sample split at the median bite ratio (",
         sprintf("%.3f", med_bite), "). ",
         "High-bite LAs (columns 1, 3) have bite ratio $\\geq$ median; ",
         "low-bite LAs (columns 2, 4) have bite ratio $<$ median. ",
         "Bite $\\times$ Post is the interaction of the LA-level 2015 bite ratio with an indicator ",
         "for post-NLW years ($\\geq$2016). Standard errors clustered at the LA level. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{table}"
)

writeLines(lines5, "../tables/tab5_heterogeneity.tex")
cat("  Saved tab5_heterogeneity.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

sde_outcomes <- c("log_p10", "log_p25", "log_p50")
sde_labels   <- c("Log p10", "Log p25", "Log p50")

sd_bite <- sd(bite_2015$bite, na.rm = TRUE)

sde_rows <- lapply(seq_along(sde_outcomes), function(i) {
  yvar <- sde_outcomes[i]
  fit  <- main_results[[yvar]]
  b    <- coef(fit)["bite_post"]
  p    <- pvalue(fit)["bite_post"]
  se_v <- se(fit)["bite_post"]
  sd_y <- sd(df[[yvar]], na.rm = TRUE)
  sde  <- b * sd_bite / sd_y
  list(
    label   = sde_labels[i],
    beta    = b,
    se_v    = se_v,
    pval    = p,
    sd_bite = sd_bite,
    sd_y    = sd_y,
    sde     = sde
  )
})

lines_f1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: NLW Bite on Log Wage Percentiles}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & $\\hat{\\beta}$ & SE & $\\sigma(\\text{Bite})$ & $\\sigma(Y)$ & SDE \\\\",
  "\\hline"
)

for (r in sde_rows) {
  row_line <- sprintf("%s & %s & %s & %.4f & %.4f & %.4f \\\\",
                      r$label,
                      coef_star(r$beta, r$pval),
                      se_paren(r$se_v),
                      r$sd_bite,
                      r$sd_y,
                      r$sde)
  lines_f1 <- c(lines_f1, row_line)
}

# SDE interpretation note (mandatory 8-field block)
sde_note <- paste0(
  "\\raggedright\\footnotesize\\textit{Notes:} ",
  "SDE (standardized effect size) $= \\hat{\\beta} \\times \\sigma(\\text{Bite}) / \\sigma(Y)$, ",
  "where $\\sigma(\\text{Bite})$ is the cross-LA standard deviation of the 2015 bite ratio ",
  "and $\\sigma(Y)$ is the standard deviation of the log wage outcome across all LA-year observations. ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the National Living Wage compress the lower tail of the local wage distribution? ",
  "\\textbf{Policy mechanism:} A higher bite ratio (NMW relative to local median wage) means the NLW floor ",
  "binds more tightly in that locality, raising low-end wages relative to the median. ",
  "\\textbf{Outcome definition:} Log gross hourly wage at the indicated percentile from ASHE micro-data, ",
  "aggregated to the Local Authority level. ",
  "\\textbf{Treatment:} Continuous bite ratio (NMW £6.50 / LA median wage in 2015) interacted with ",
  "post-NLW indicator ($\\geq$2016). ",
  "\\textbf{Data:} Annual Survey of Hours and Earnings (ASHE), ONS, 2013--2023; ",
  "369 Local Authorities in England and Wales. ",
  "\\textbf{Method:} Two-way fixed effects DiD (LA FE + year FE) with standard errors clustered at the LA level. ",
  "\\textbf{Sample:} All working-age employees in scope of ASHE; 25+ age group (NLW applicable from April 2016; ",
  "extended to 23+ in 2021). *** $p<0.01$, ** $p<0.05$, * $p<0.10$."
)

lines_f1 <- c(lines_f1,
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\parbox{\\textwidth}{", sde_note, "}"),
  "\\end{table}"
)

writeLines(lines_f1, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

# ============================================================================
# Summary
# ============================================================================
cat("\n=== All tables generated ===\n")
cat("  ../tables/tab1_summary.tex\n")
cat("  ../tables/tab2_main.tex\n")
cat("  ../tables/tab3_ratios.tex\n")
cat("  ../tables/tab4_robustness.tex\n")
cat("  ../tables/tab5_heterogeneity.tex\n")
cat("  ../tables/tabF1_sde.tex\n")
