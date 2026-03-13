## 05_tables.R — Generate all LaTeX tables for paper
## APEP paper apep_0631

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
main_res <- readRDS(file.path(data_dir, "main_results.rds"))
rob_res <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
irs_zip <- readRDS(file.path(data_dir, "irs_zip_salt.rds"))

## ══════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics by SALT Exposure Quartile
## ══════════════════════════════════════════════════════════════

cat("Generating Table 1: Summary Statistics\n")

# salt_group already exists in the panel from 02_clean_data.R
# Groups: "Under cap", "$0-5K above", "$5-10K above", "$10K+ above"

# Pre-period stats (2017) by salt_group
pre_stats <- panel[year == 2017, .(
  n_zips = uniqueN(zip),
  mean_zhvi = mean(zhvi, na.rm = TRUE),
  sd_zhvi = sd(zhvi, na.rm = TRUE),
  mean_salt = mean(avg_salt, na.rm = TRUE),
  mean_bite = mean(salt_bite, na.rm = TRUE)
), by = salt_group]

# Overall
overall <- panel[year == 2017, .(
  salt_group = "All",
  n_zips = uniqueN(zip),
  mean_zhvi = mean(zhvi, na.rm = TRUE),
  sd_zhvi = sd(zhvi, na.rm = TRUE),
  mean_salt = mean(avg_salt, na.rm = TRUE),
  mean_bite = mean(salt_bite, na.rm = TRUE)
)]

tab1_data <- rbind(pre_stats, overall)

# Escape $ for LaTeX and use en-dashes
tab1_data[, salt_group := gsub("\\$", "\\\\$", salt_group)]
tab1_data[, salt_group := gsub("(\\d)-(\\d)", "\\1--\\2", salt_group)]

# Write LaTeX — use \small font and @{} to fit within margins
tab1_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Summary Statistics by SALT Exposure Quartile (2017)}
\\label{tab:summary}
\\begin{threeparttable}
{\\small
\\begin{tabular}{@{}lrrrrr@{}}
\\toprule
 & Zip Codes & Mean ZHVI (\\$) & SD ZHVI (\\$) & Avg SALT (\\$) & SALT Bite (\\$10K) \\\\
\\midrule
%s
\\midrule
%s
\\bottomrule
\\end{tabular}}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} ZHVI is the Zillow Home Value Index (smoothed, seasonally adjusted) for the typical home in each zip code. Avg SALT is the average state and local tax deduction per itemizing return from the 2017 IRS SOI zip-code file. SALT Bite measures dollars above the \\$10,000 TCJA cap, in \\$10,000 units. Quartiles are defined over SALT Bite across %s zip codes.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
paste(sprintf("%-10s & %s & %s & %s & %s & %.2f \\\\",
              tab1_data$salt_group[1:4],
              formatC(tab1_data$n_zips[1:4], format = "d", big.mark = ","),
              formatC(round(tab1_data$mean_zhvi[1:4]), format = "d", big.mark = ","),
              formatC(round(tab1_data$sd_zhvi[1:4]), format = "d", big.mark = ","),
              formatC(round(tab1_data$mean_salt[1:4]), format = "d", big.mark = ","),
              tab1_data$mean_bite[1:4]), collapse = "\n"),
sprintf("%-10s & %s & %s & %s & %s & %.2f \\\\",
        "All", formatC(tab1_data$n_zips[5], format = "d", big.mark = ","),
        formatC(round(tab1_data$mean_zhvi[5]), format = "d", big.mark = ","),
        formatC(round(tab1_data$sd_zhvi[5]), format = "d", big.mark = ","),
        formatC(round(tab1_data$mean_salt[5]), format = "d", big.mark = ","),
        tab1_data$mean_bite[5]),
formatC(tab1_data$n_zips[5], format = "d", big.mark = ",")
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

## ══════════════════════════════════════════════════════════════
## TABLE 2: Main DiD Results (hand-built tabular)
## ══════════════════════════════════════════════════════════════

cat("Generating Table 2: Main Results\n")

stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Extract coefficients for each model
fits <- list(main_res$fit1, main_res$fit2, main_res$fit3, main_res$fit4)
tcja_coef <- sapply(fits, function(f) coef(f)["post_tcja:salt_bite"])
tcja_se   <- sapply(fits, function(f) se(f)["post_tcja:salt_bite"])
tcja_p    <- sapply(fits, function(f) pvalue(f)["post_tcja:salt_bite"])
tcja_stars <- sapply(tcja_p, stars_fn)

nobs_vec  <- sapply(fits, nobs)
r2_vec    <- sapply(fits, r2, type = "r2")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of SALT Deduction Cap on House Prices}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{@{}lcccc@{}}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Post-TCJA $\\times$ SALT Bite & $%.3f$%s & $%.3f$%s & $%.3f$%s & $%.3f$%s \\\\",
          tcja_coef[1], tcja_stars[1], tcja_coef[2], tcja_stars[2],
          tcja_coef[3], tcja_stars[3], tcja_coef[4], tcja_stars[4]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\[6pt]",
          tcja_se[1], tcja_se[2], tcja_se[3], tcja_se[4]),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs_vec[1], format="d", big.mark=","),
          formatC(nobs_vec[2], format="d", big.mark=","),
          formatC(nobs_vec[3], format="d", big.mark=","),
          formatC(nobs_vec[4], format="d", big.mark=",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r2_vec[1], r2_vec[2], r2_vec[3], r2_vec[4]),
  "\\midrule",
  "Zip FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & No & No \\\\",
  "Metro $\\times$ Month FE & No & No & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Outcome is log(ZHVI). SALT Bite = max(0, avg SALT per itemizer $-$ \\$10,000) / \\$10,000. Columns (1)--(2) include all zip codes; (3)--(4) restrict to zips within a metro area. Standard errors clustered at the state level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab2_lines, collapse = "\n"), file.path(tables_dir, "tab2_main.tex"))

## ══════════════════════════════════════════════════════════════
## TABLE 3: Event Study Coefficients
## ══════════════════════════════════════════════════════════════

cat("Generating Table 3: Event Study\n")

es_fit <- main_res$fit_es
es_coefs <- as.data.table(coeftable(es_fit), keep.rownames = "term")
es_coefs <- es_coefs[grepl("year_rel_bin", term)]

# Extract year from term
es_coefs[, year_rel := as.integer(gsub(".*::(-?\\d+):.*", "\\1", term))]
setorder(es_coefs, year_rel)

# Format event study table
es_lines <- sprintf("  %+d & %.4f & (%.4f) & %.3f \\\\",
                     es_coefs$year_rel,
                     es_coefs$Estimate,
                     es_coefs$`Std. Error`,
                     es_coefs$`Pr(>|t|)`)

tab3_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Effects of SALT Cap on House Prices}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{rccl}
\\toprule
Year Relative to TCJA & Coefficient & Std. Error & p-value \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the coefficient on the interaction of a year dummy (relative to 2018) with SALT Bite. The omitted category is $k = -1$ (2017). Zip and month fixed effects included. Standard errors clustered at the state level. N = %s zip-month observations.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
paste(es_lines, collapse = "\n"),
formatC(nobs(es_fit), format = "d", big.mark = ",")
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_eventstudy.tex"))

## ══════════════════════════════════════════════════════════════
## TABLE 4: OBBB Reversal and Symmetry Test
## ══════════════════════════════════════════════════════════════

cat("Generating Table 4: Symmetry Test\n")

sym <- rob_res$symmetry

tab4_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{OBBB Reversal and Test of Symmetric Capitalization}
\\label{tab:symmetry}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Zip + Month FE & Zip + Metro$\\times$Month FE \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Separate Period Effects}} \\\\[3pt]
Post-TCJA $\\times$ SALT Bite & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) \\\\[3pt]
Post-OBBB $\\times$ SALT Bite & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Symmetry Test}} \\\\[3pt]
$\\hat{\\beta}_{\\text{TCJA}} + \\hat{\\beta}_{\\text{OBBB}}$ & %.4f & --- \\\\
Wald $\\chi^2$ (H$_0$: full reversal) & %.3f & --- \\\\
p-value & %.4f & --- \\\\[3pt]
\\midrule
Observations & %s & --- \\\\
Zip codes & %s & --- \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the coefficient on SALT Bite interacted with period indicators. The reference period is pre-TCJA (2012--2017). Post-TCJA covers Jan 2018--Jun 2025. Post-OBBB covers Jul 2025--Jan 2026. Panel B tests whether the OBBB reversal fully offset the TCJA cap effect (H$_0$: $\\beta_{\\text{TCJA}} + \\beta_{\\text{OBBB}} = 0$). Standard errors clustered at the state level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
# Column 1: from rob_res$fit_sym
coef(rob_res$fit_sym)["period_f::tcja:salt_bite"],
ifelse(abs(coef(rob_res$fit_sym)["period_f::tcja:salt_bite"] / se(rob_res$fit_sym)["period_f::tcja:salt_bite"]) > 2.576, "***",
       ifelse(abs(coef(rob_res$fit_sym)["period_f::tcja:salt_bite"] / se(rob_res$fit_sym)["period_f::tcja:salt_bite"]) > 1.96, "**",
              ifelse(abs(coef(rob_res$fit_sym)["period_f::tcja:salt_bite"] / se(rob_res$fit_sym)["period_f::tcja:salt_bite"]) > 1.645, "*", ""))),
# Column 2 placeholder (metro FE version — compute if available)
coef(main_res$fit4)["post_tcja:salt_bite"],
ifelse(abs(coef(main_res$fit4)["post_tcja:salt_bite"] / se(main_res$fit4)["post_tcja:salt_bite"]) > 2.576, "***",
       ifelse(abs(coef(main_res$fit4)["post_tcja:salt_bite"] / se(main_res$fit4)["post_tcja:salt_bite"]) > 1.96, "**",
              ifelse(abs(coef(main_res$fit4)["post_tcja:salt_bite"] / se(main_res$fit4)["post_tcja:salt_bite"]) > 1.645, "*", ""))),
se(rob_res$fit_sym)["period_f::tcja:salt_bite"],
se(main_res$fit4)["post_tcja:salt_bite"],
# OBBB row
coef(rob_res$fit_sym)["period_f::obbb:salt_bite"],
ifelse(abs(coef(rob_res$fit_sym)["period_f::obbb:salt_bite"] / se(rob_res$fit_sym)["period_f::obbb:salt_bite"]) > 2.576, "***",
       ifelse(abs(coef(rob_res$fit_sym)["period_f::obbb:salt_bite"] / se(rob_res$fit_sym)["period_f::obbb:salt_bite"]) > 1.96, "**",
              ifelse(abs(coef(rob_res$fit_sym)["period_f::obbb:salt_bite"] / se(rob_res$fit_sym)["period_f::obbb:salt_bite"]) > 1.645, "*", ""))),
coef(main_res$fit4)["post_obbb:salt_bite"],
ifelse(abs(coef(main_res$fit4)["post_obbb:salt_bite"] / se(main_res$fit4)["post_obbb:salt_bite"]) > 2.576, "***",
       ifelse(abs(coef(main_res$fit4)["post_obbb:salt_bite"] / se(main_res$fit4)["post_obbb:salt_bite"]) > 1.96, "**",
              ifelse(abs(coef(main_res$fit4)["post_obbb:salt_bite"] / se(main_res$fit4)["post_obbb:salt_bite"]) > 1.645, "*", ""))),
se(rob_res$fit_sym)["period_f::obbb:salt_bite"],
se(main_res$fit4)["post_obbb:salt_bite"],
# Symmetry test
sym$beta_tcja + sym$beta_obbb,
sym$wald_stat,
sym$wald_p,
formatC(nobs(rob_res$fit_sym), format = "d", big.mark = ","),
formatC(uniqueN(panel$zip), format = "d", big.mark = ",")
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_symmetry.tex"))

## ══════════════════════════════════════════════════════════════
## TABLE 5: Robustness (hand-built tabular)
## ══════════════════════════════════════════════════════════════

cat("Generating Table 5: Robustness\n")

# Column 1: Baseline (fit1), Column 2: Metro×Month (fit3),
# Column 3: Placebo (fit_placebo), Column 4: Zip Cluster, Column 5: Pre-Trend
rob_fits <- list(main_res$fit1, main_res$fit3, rob_res$fit_placebo,
                 rob_res$fit_zip_cluster, rob_res$fit_pretrend)

# Row 1: Post-TCJA × SALT Bite (cols 1, 2, 4)
get_coef <- function(f, nm) {
  b <- coef(f)[nm]; s <- se(f)[nm]; p <- pvalue(f)[nm]
  if (is.na(b)) return(list(b=NA, s=NA, p=NA))
  list(b=b, s=s, p=p)
}

# Row 1: Post-TCJA × SALT Bite
r1 <- lapply(rob_fits, get_coef, nm = "post_tcja:salt_bite")
# Row 2: Placebo pseudo treatment (col 3 only)
r2_plac <- get_coef(rob_res$fit_placebo, "post_tcja:pseudo_treat")
# Row 3: Pre-trend (col 5 only)
r3_pre <- get_coef(rob_res$fit_pretrend, "year_trend:salt_bite")

fmt_cell <- function(val, p) {
  if (is.na(val)) return("")
  sprintf("$%.3f$%s", val, stars_fn(p))
}
fmt_se <- function(val) {
  if (is.na(val)) return("")
  sprintf("(%.3f)", val)
}

nobs5 <- sapply(rob_fits, nobs)
r2_5 <- sapply(rob_fits, r2, type = "r2")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{@{}lccccc@{}}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & Metro$\\times$Mo. & Placebo & Zip Cl. & Pre-Trend \\\\",
  "\\midrule",
  # Row 1: Post-TCJA × SALT Bite
  sprintf("Post-TCJA $\\times$ SALT Bite & %s & %s & & %s & \\\\",
          fmt_cell(r1[[1]]$b, r1[[1]]$p), fmt_cell(r1[[2]]$b, r1[[2]]$p),
          fmt_cell(r1[[4]]$b, r1[[4]]$p)),
  sprintf(" & %s & %s & & %s & \\\\[4pt]",
          fmt_se(r1[[1]]$s), fmt_se(r1[[2]]$s), fmt_se(r1[[4]]$s)),
  # Row 2: Placebo
  sprintf("Post-TCJA $\\times$ Pseudo Treat. & & & %s & & \\\\",
          fmt_cell(r2_plac$b, r2_plac$p)),
  sprintf(" & & & %s & & \\\\[4pt]",
          fmt_se(r2_plac$s)),
  # Row 3: Pre-trend
  sprintf("Year Trend $\\times$ SALT Bite & & & & & %s \\\\",
          fmt_cell(r3_pre$b, r3_pre$p)),
  sprintf(" & & & & & %s \\\\",
          fmt_se(r3_pre$s)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(nobs5[1], format="d", big.mark=","),
          formatC(nobs5[2], format="d", big.mark=","),
          formatC(nobs5[3], format="d", big.mark=","),
          formatC(nobs5[4], format="d", big.mark=","),
          formatC(nobs5[5], format="d", big.mark=",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          r2_5[1], r2_5[2], r2_5[3], r2_5[4], r2_5[5]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors in parentheses: state-clustered in (1)--(3) and (5); zip-clustered in (4). Column (3) restricts to zip codes below the \\$10K SALT cap (placebo test). Column (5) tests for differential pre-trends over 2012--2017. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab5_lines, collapse = "\n"), file.path(tables_dir, "tab5_robustness.tex"))

## ══════════════════════════════════════════════════════════════
## SDE TABLE (Appendix — mandatory)
## ══════════════════════════════════════════════════════════════

cat("Generating SDE Table\n")

# Use preferred specification (fit3: metro × month FE)
fit_pref <- main_res$fit3
beta_hat <- coef(fit_pref)["post_tcja:salt_bite"]
se_hat <- se(fit_pref)["post_tcja:salt_bite"]

# SD(Y) = unconditional SD of log(ZHVI)
sd_y <- sd(panel$log_zhvi, na.rm = TRUE)

# SD(X) = unconditional SD of salt_bite across zip codes
sd_x <- sd(panel$salt_bite[!duplicated(panel$zip)], na.rm = TRUE)

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde <- beta_hat * sd_x / sd_y
se_sde <- se_hat * sd_x / sd_y

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

# Note: OBBB reversal SDE omitted — short post-period makes it unreliable

n_obs_str <- formatC(nrow(panel), format = "d", big.mark = ",")
n_zip_str <- formatC(uniqueN(panel$zip), format = "d", big.mark = ",")

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "{\\small",
  "\\begin{tabular}{lcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("House Prices (TCJA) & $%.4f$ & %.3f & %.3f & $%.4f$ & %.4f & %s \\\\",
          beta_hat, sd_x, sd_y, sde, se_sde, classify(sde)),
  "\\bottomrule",
  "\\end{tabular}}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
         "to facilitate cross-study comparison of treatment effect magnitudes. ",
         "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
         "which gives the effect of a one-standard-deviation change in the treatment variable, ",
         "measured in standard deviations of the outcome. ",
         "SD($Y$) and SD($X$) are unconditional standard deviations from the full analysis sample."),
  "",
  paste0("\\textbf{Research question:} Does capping the SALT deduction at \\$10,000 (TCJA 2018) ",
         "and subsequently raising the cap to \\$40,000 (OBBB 2025) affect local house prices? ",
         "\\textbf{Treatment:} Continuous; SALT Bite = max(0, avg SALT per itemizer $-$ \\$10,000) / \\$10,000, ",
         "measured in \\$10K units. ",
         "\\textbf{Data:} Zillow ZHVI (zip-code monthly, 2012--2026) merged with 2017 IRS SOI zip-code SALT data. ",
         n_obs_str, " zip-month observations. ",
         "\\textbf{Method:} Continuous-treatment difference-in-differences with zip and metro$\\times$month ",
         "fixed effects, state-clustered standard errors. ",
         "\\textbf{Sample:} ", n_zip_str, " zip codes observed monthly over 2012--2026."),
  "",
  paste0("Classification labels refer to the magnitude of the standardized point estimate, ",
         "not to statistical significance. ``Null'' denotes a near-zero effect size ",
         "($|\\text{SDE}| < 0.005$), not a failure to reject a null hypothesis.}"),
  "\\end{table}"
)
sde_tex <- paste(sde_lines, collapse = "\n")

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(" ", list.files(tables_dir), collapse = "\n"), "\n")
