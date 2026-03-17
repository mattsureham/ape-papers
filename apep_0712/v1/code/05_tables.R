# 05_tables.R — Generate all tables for paper
# apep_0712: UK Ground Rent Abolition

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

sumstats <- rdd_sample[, .(
  N = .N,
  mean_price = mean(price),
  sd_price = sd(price),
  median_price = median(price),
  min_price = min(price),
  max_price = max(price),
  mean_log_price = mean(log_price),
  sd_log_price = sd(log_price),
  pct_london = mean(postcode_area %in% c("E", "EC", "N", "NW", "SE", "SW", "W", "WC")) * 100
), by = .(Period = ifelse(post == 0, "Pre-reform", "Post-reform"))]

# New-build freehold summary
freehold_stats <- did_sample[treated == 0, .(
  N = .N,
  mean_price = mean(price),
  sd_price = sd(price),
  median_price = median(price),
  mean_log_price = mean(log_price),
  sd_log_price = sd(log_price)
), by = .(Period = ifelse(post == 0, "Pre-reform", "Post-reform"))]

tab1_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{l rrrr}
\\toprule
 & \\multicolumn{2}{c}{New-Build Leasehold Flats} & \\multicolumn{2}{c}{New-Build Freehold} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Pre-reform & Post-reform & Pre-reform & Post-reform \\\\
\\midrule
Transactions & %s & %s & %s & %s \\\\
Mean price (\\pounds) & %s & %s & %s & %s \\\\
SD price (\\pounds) & %s & %s & %s & %s \\\\
Median price (\\pounds) & %s & %s & %s & %s \\\\
Mean log price & %.3f & %.3f & %.3f & %.3f \\\\
SD log price & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-reform = January 2021 -- June 30, 2022. Post-reform = July 1, 2022 -- December 2024. New-build leasehold flats are the treated group (subject to the ground rent ban). New-build freehold properties serve as controls. Source: HM Land Registry Price Paid Data.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  format(sumstats$N[1], big.mark = ","), format(sumstats$N[2], big.mark = ","),
  format(freehold_stats$N[1], big.mark = ","), format(freehold_stats$N[2], big.mark = ","),
  format(round(sumstats$mean_price[1]), big.mark = ","),
  format(round(sumstats$mean_price[2]), big.mark = ","),
  format(round(freehold_stats$mean_price[1]), big.mark = ","),
  format(round(freehold_stats$mean_price[2]), big.mark = ","),
  format(round(sumstats$sd_price[1]), big.mark = ","),
  format(round(sumstats$sd_price[2]), big.mark = ","),
  format(round(freehold_stats$sd_price[1]), big.mark = ","),
  format(round(freehold_stats$sd_price[2]), big.mark = ","),
  format(round(sumstats$median_price[1]), big.mark = ","),
  format(round(sumstats$median_price[2]), big.mark = ","),
  format(round(freehold_stats$median_price[1]), big.mark = ","),
  format(round(freehold_stats$median_price[2]), big.mark = ","),
  sumstats$mean_log_price[1], sumstats$mean_log_price[2],
  freehold_stats$mean_log_price[1], freehold_stats$mean_log_price[2],
  sumstats$sd_log_price[1], sumstats$sd_log_price[2],
  freehold_stats$sd_log_price[1], freehold_stats$sd_log_price[2]
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main RDD Results (bandwidth sensitivity)
# ============================================================
cat("Generating Table 2: Main RDD Results...\n")

# Re-estimate with specific bandwidths for clean table
bw_for_table <- c(60, 90, 120, 180, 365)
rdd_table_rows <- lapply(bw_for_table, function(h) {
  fit <- rdrobust(
    y = rdd_sample$log_price,
    x = rdd_sample$days_from_cutoff,
    c = 0, kernel = "triangular", p = 1, h = h
  )
  list(
    bw = h,
    coef = fit$coef[1],
    se = fit$se[3],
    pval = fit$pv[3],
    n_eff = fit$N_h[1] + fit$N_h[2],
    ci_lo = fit$ci[3, 1],
    ci_hi = fit$ci[3, 2]
  )
})

# Add CCT optimal bandwidth
rdd_opt <- rdrobust(
  y = rdd_sample$log_price,
  x = rdd_sample$days_from_cutoff,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd"
)
rdd_table_rows <- c(
  list(list(
    bw = round(rdd_opt$bws[1, 1]),
    coef = rdd_opt$coef[1],
    se = rdd_opt$se[3],
    pval = rdd_opt$pv[3],
    n_eff = rdd_opt$N_h[1] + rdd_opt$N_h[2],
    ci_lo = rdd_opt$ci[3, 1],
    ci_hi = rdd_opt$ci[3, 2]
  )),
  rdd_table_rows
)

star_fn <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_rows <- sapply(rdd_table_rows, function(r) {
  stars <- star_fn(r$pval)
  sprintf("%.0f days & %.4f%s & (%.4f) & %s & [%.4f, %.4f] \\\\",
          r$bw, r$coef, stars, r$se,
          format(r$n_eff, big.mark = ","),
          r$ci_lo, r$ci_hi)
})

# Mark the CCT row
tab2_rows[1] <- sub("^", "CCT: ", tab2_rows[1])

tab2_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{RDD Estimates: Effect of Ground Rent Abolition on New-Build Leasehold Flat Prices}
\\label{tab:rdd}
\\begin{threeparttable}
\\begin{tabular}{lcccl}
\\toprule
Bandwidth & Estimate & Robust SE & $N$ (effective) & 95\\%% CI \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Local linear regression with triangular kernel. Dependent variable is log(transaction price). Running variable is days from June 30, 2022. Robust standard errors and confidence intervals from \\citet{cattaneo2020}. CCT row uses MSE-optimal bandwidth. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(tab2_rows, collapse = "\n"))

writeLines(tab2_tex, file.path(tables_dir, "tab2_rdd.tex"))

# ============================================================
# Table 3: DiD and Triple-Diff Results
# ============================================================
cat("Generating Table 3: DiD and Triple-Diff...\n")

did_coef_val <- coef(did_fit)["treated:post"]
did_se_val <- se(did_fit)["treated:post"]
did_pval <- pvalue(did_fit)["treated:post"]
did_n <- nobs(did_fit)

ddd_coef_val <- coef(ddd_fit)["ddd_var"]
ddd_se_val <- se(ddd_fit)["ddd_var"]
ddd_pval <- pvalue(ddd_fit)["ddd_var"]
ddd_n <- nobs(ddd_fit)

tab3_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Difference-in-Differences and Triple-Difference Estimates}
\\label{tab:did}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) DiD & (2) Triple-Diff \\\\
\\midrule
Treated $\\times$ Post & %.4f%s & \\\\
 & (%.4f) & \\\\[0.5em]
Leasehold $\\times$ New-Build $\\times$ Post & & %.4f%s \\\\
 & & (%.4f) \\\\[0.5em]
Postcode area FE & Yes & Yes \\\\
Year-month FE & Yes & Yes \\\\
$N$ & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is log(transaction price). Column (1): Treated group is new-build leasehold flats; control is new-build freehold properties. Column (2): Triple-difference adds existing leasehold flats as a second control. Standard errors clustered by postcode area in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  did_coef_val, star_fn(did_pval), did_se_val,
  ddd_coef_val, star_fn(ddd_pval), ddd_se_val,
  format(did_n, big.mark = ","), format(ddd_n, big.mark = ",")
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_did.tex"))

# ============================================================
# Table 4: Robustness Checks
# ============================================================
cat("Generating Table 4: Robustness...\n")

# Collect all robustness results
rob_rows <- list(
  list(spec = "Main RDD (CCT optimal)", coef = rdd_opt$coef[1],
       se = rdd_opt$se[3], pval = rdd_opt$pv[3],
       n = rdd_opt$N_h[1] + rdd_opt$N_h[2]),
  list(spec = "Donut ($\\pm$30 days)", coef = rdd_donut30$coef[1],
       se = rdd_donut30$se[3], pval = rdd_donut30$pv[3],
       n = rdd_donut30$N_h[1] + rdd_donut30$N_h[2]),
  list(spec = "Quadratic polynomial", coef = rdd_quad$coef[1],
       se = rdd_quad$se[3], pval = rdd_quad$pv[3],
       n = rdd_quad$N_h[1] + rdd_quad$N_h[2])
)

# Add placebo cutoffs
for (pd in as.Date(c("2021-06-30", "2023-06-30"))) {
  pd <- as.Date(pd, origin = "1970-01-01")
  rdd_tmp <- copy(rdd_sample)
  rdd_tmp[, days_plac := as.numeric(date_transfer - pd)]
  fit_plac <- rdrobust(y = rdd_tmp$log_price, x = rdd_tmp$days_plac,
                       c = 0, kernel = "triangular", p = 1)
  rob_rows <- c(rob_rows, list(list(
    spec = sprintf("Placebo: %s", pd),
    coef = fit_plac$coef[1], se = fit_plac$se[3],
    pval = fit_plac$pv[3], n = fit_plac$N_h[1] + fit_plac$N_h[2]
  )))
}

# Add freehold placebo
freehold_new <- ppd_analysis <- readRDS(file.path(data_dir, "ppd_analysis.rds"))
freehold_new <- ppd_analysis[group == "new_freehold" & property_type %in% c("D", "S", "T")]
freehold_new[, days_from_cutoff := as.numeric(date_transfer - as.Date("2022-06-30"))]
if (nrow(freehold_new) > 500) {
  fit_fh <- rdrobust(y = freehold_new$log_price, x = freehold_new$days_from_cutoff,
                     c = 0, kernel = "triangular", p = 1)
  rob_rows <- c(rob_rows, list(list(
    spec = "Placebo: freehold houses",
    coef = fit_fh$coef[1], se = fit_fh$se[3],
    pval = fit_fh$pv[3], n = fit_fh$N_h[1] + fit_fh$N_h[2]
  )))
}

tab4_lines <- sapply(rob_rows, function(r) {
  sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
          r$spec, r$coef, star_fn(r$pval), r$se,
          format(r$n, big.mark = ","))
})

tab4_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Specification & Estimate & Robust SE & $N$ \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications use local linear regression with triangular kernel and CCT-optimal bandwidth unless noted. Dependent variable is log(transaction price). Running variable is days from June 30, 2022 (or placebo date). Robust standard errors from \\citet{cattaneo2020}. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(tab4_lines, collapse = "\n"))

writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: SDE...\n")

sd_y <- sd(rdd_sample$log_price)

# Main outcomes
sde_rows <- list(
  list(
    outcome = "Log(price) — RDD",
    beta = rdd_opt$coef[1],
    se_beta = rdd_opt$se[3],
    sd_y = sd_y
  ),
  list(
    outcome = "Log(price) — DiD",
    beta = coef(did_fit)["treated:post"],
    se_beta = se(did_fit)["treated:post"],
    sd_y = sd(did_sample$log_price)
  ),
  list(
    outcome = "Log(price) — Triple-Diff",
    beta = coef(ddd_fit)["ddd_var"],
    se_beta = se(ddd_fit)["ddd_var"],
    sd_y = sd(triplediff_sample$log_price)
  )
)

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_table_lines <- sapply(sde_rows, function(r) {
  sde <- r$beta / r$sd_y
  se_sde <- r$se_beta / r$sd_y
  cls <- classify_sde(sde)
  sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          r$outcome, r$beta, r$se_beta, r$sd_y, sde, se_sde, cls)
})

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England and Wales). ",
  "\\textbf{Research question:} Does abolishing ground rent on new residential leases ",
  "increase leasehold property prices through capitalization of reduced future obligations? ",
  "\\textbf{Policy mechanism:} The Leasehold Reform (Ground Rent) Act 2022 set ground rent ",
  "to a peppercorn (effectively zero) for all new long residential leases granted on or after ",
  "30 June 2022; previously, developers charged ground rents of GBP 250--1,000 per year, ",
  "often with doubling clauses that amplified the net present value of the obligation. ",
  "\\textbf{Outcome definition:} Log of transaction price from HM Land Registry Price Paid Data, ",
  "measuring the sale price of new-build leasehold flats. ",
  "\\textbf{Treatment:} Binary --- transactions on or after 1 July 2022 are subject to the ",
  "zero ground rent requirement. ",
  "\\textbf{Data:} HM Land Registry Price Paid Data, 2021--2024, transaction-level, ",
  "universe of all registered residential sales in England and Wales. ",
  "\\textbf{Method:} Local linear RDD with triangular kernel and CCT-optimal bandwidth; ",
  "difference-in-differences using new-build freehold as control; triple-difference adding ",
  "existing leaseholds. Robust standard errors from Cattaneo, Idrobo, and Titiunik (2020). ",
  "\\textbf{Sample:} New-build leasehold flats (Property Type = F, New Build = Y, Duration = L); ",
  "restricted to standard price-paid transactions (PPD Category A). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation ",
  "of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  paste(sde_table_lines, collapse = "\n"),
  sde_notes
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
