## 06_tables.R — Generate all tables as LaTeX
## apep_0575: BRRD Bail-In Risk and Household Deposit Structure

source("00_packages.R")

data_dir <- "../data/"
tab_dir <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================

hh <- fread(paste0(data_dir, "hh_panel.csv"))
nfc <- fread(paste0(data_dir, "nfc_panel.csv"))
eba <- fread(paste0(data_dir, "eba_dgs_ratios.csv"))

# Panel A: Household deposits (19-country analysis sample for all variables)
analysis_countries_hh <- unique(hh[!is.na(share_overnight)]$country)
hh_analysis_stats <- hh[country %in% analysis_countries_hh]

vars_hh <- c("share_overnight", "share_agreed", "share_redeemable",
             "dep_total", "log_total_dep")
labels_hh <- c("Overnight share", "Agreed-maturity share",
               "Redeemable-at-notice share",
               "Total deposits (EUR M)", "Log total deposits")

sumstats_hh <- rbindlist(lapply(seq_along(vars_hh), function(i) {
  x <- hh_analysis_stats[[vars_hh[i]]]
  x <- x[!is.na(x)]
  data.table(
    Variable = labels_hh[i],
    Mean = mean(x),
    SD = sd(x),
    Min = min(x),
    Max = max(x),
    N = length(x)
  )
}))

# Panel B: Treatment variables
# Filter EBA to the 19 analysis-sample countries (those with non-NA share data)
analysis_countries <- unique(hh[!is.na(share_overnight)]$country)
eba_analysis <- eba[country %in% analysis_countries]

# Post-BRRD also restricted to analysis sample
hh_analysis <- hh[country %in% analysis_countries]

sumstats_treat <- data.table(
  Variable = c("Uninsured deposit share", "Post-BRRD transposition"),
  Mean = c(mean(eba_analysis$uninsured_share), mean(hh_analysis$post_brrd)),
  SD = c(sd(eba_analysis$uninsured_share), sd(hh_analysis$post_brrd)),
  Min = c(min(eba_analysis$uninsured_share), 0),
  Max = c(max(eba_analysis$uninsured_share), 1),
  N = c(nrow(eba_analysis), nrow(hh_analysis))
)

sumstats_all <- rbind(sumstats_hh, sumstats_treat)

# Format
sumstats_tex <- sumstats_all[, .(
  Variable,
  Mean = sprintf("%.3f", Mean),
  SD = sprintf("%.3f", SD),
  Min = sprintf("%.3f", Min),
  Max = sprintf("%.3f", Max),
  N = format(N, big.mark = ",")
)]

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Variable & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Household Deposit Composition}} \\\\",
  paste0(apply(sumstats_tex[1:5], 1, function(r) paste(r, collapse = " & ")), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Treatment Variables}} \\\\",
  paste0(apply(sumstats_tex[6:7], 1, function(r) paste(r, collapse = " & ")), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Restricted to the 19-country regression sample (countries with complete BSI maturity disaggregation). Monthly country-level panel from ECB Balance Sheet Items (BSI) database, January 2012 to December 2018. Deposit shares are the ratio of each maturity type to total household deposits. Uninsured deposit share is one minus the covered-to-eligible deposit ratio from EBA Deposit Guarantee Scheme data (2015). Post-BRRD is an indicator for months after national transposition of Directive 2014/59/EU.",
  "\\end{tablenotes}",
  "\\end{table}"
), paste0(tab_dir, "tab1_sumstats.tex"))

cat("Table 1 saved: summary statistics\n")

# ===========================================================================
# TABLE 2: Main Results
# ===========================================================================

results <- fread(paste0(data_dir, "main_results.csv"))

# Format main result rows
format_coef <- function(est, se_val, stars_val) {
  sprintf("%.4f%s", est, stars_val)
}
format_se <- function(se_val) {
  sprintf("(%.4f)", se_val)
}

# Build table manually for maximum control
twfe_ov <- results[specification == "TWFE Overnight"]
twfe_ag <- results[specification == "TWFE Agreed"]
twfe_re <- results[specification == "TWFE Redeemable"]
td_ov <- results[specification == "Triple-diff Overnight (post_x_uninsured)"]
td_ag <- results[specification == "Triple-diff Agreed (post_x_uninsured)"]

# Triple-diff post_brrd main effect for columns 4-5 (from main_results.csv)
td_ov_post <- results[specification == "Triple-diff Overnight (post_brrd)"]
td_ag_post <- results[specification == "Triple-diff Agreed (post_brrd)"]

# Sector DDD post_brrd for Table 3 (from main_results.csv)
sec_post <- results[specification == "Sector DDD (post_brrd)"]

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{BRRD Transposition and Household Deposit Composition}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{TWFE DiD} & & \\multicolumn{2}{c}{Intensity Interaction} \\\\",
  "\\cmidrule{2-4} \\cmidrule{6-7}",
  " & Overnight & Agreed & Redeemable & & Overnight & Agreed \\\\",
  " & (1) & (2) & (3) & & (4) & (5) \\\\",
  "\\midrule",
  sprintf("Post-BRRD & %s & %s & %s & & %s & %s \\\\",
          format_coef(twfe_ov$estimate, twfe_ov$se, twfe_ov$stars),
          format_coef(twfe_ag$estimate, twfe_ag$se, twfe_ag$stars),
          format_coef(twfe_re$estimate, twfe_re$se, twfe_re$stars),
          format_coef(td_ov_post$estimate, td_ov_post$se, td_ov_post$stars),
          format_coef(td_ag_post$estimate, td_ag_post$se, td_ag_post$stars)),
  sprintf(" & %s & %s & %s & & %s & %s \\\\",
          format_se(twfe_ov$se), format_se(twfe_ag$se), format_se(twfe_re$se),
          format_se(td_ov_post$se), format_se(td_ag_post$se)),
  sprintf("Post $\\times$ Uninsured & & & & & %s & %s \\\\",
          format_coef(td_ov$estimate, td_ov$se, td_ov$stars),
          format_coef(td_ag$estimate, td_ag$se, td_ag$stars)),
  sprintf(" & & & & & %s & %s \\\\",
          format_se(td_ov$se), format_se(td_ag$se)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & & %s & %s \\\\",
          format(sum(!is.na(hh$share_overnight)), big.mark=","),
          format(sum(!is.na(hh$share_agreed)), big.mark=","),
          format(sum(!is.na(hh$share_redeemable)), big.mark=","),
          format(sum(!is.na(hh$share_overnight)), big.mark=","),
          format(sum(!is.na(hh$share_agreed)), big.mark=",")),
  sprintf("Countries & %d & %d & %d & & %d & %d \\\\",
          uniqueN(hh[!is.na(share_overnight)]$country),
          uniqueN(hh[!is.na(share_agreed)]$country),
          uniqueN(hh[!is.na(share_redeemable)]$country),
          uniqueN(hh[!is.na(share_overnight)]$country),
          uniqueN(hh[!is.na(share_agreed)]$country)),
  "Country FE & Yes & Yes & Yes & & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & & Yes & Yes \\\\",
  "Clustering & Country & Country & Country & & Country & Country \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns 1--3 report two-way fixed effects estimates of BRRD transposition on household deposit composition shares. The dependent variable is the ratio of each deposit maturity type to total household deposits (0--1 scale; multiply coefficients by 100 for percentage points). Columns 4--5 interact the post-transposition indicator with the cross-sectional uninsured deposit share (one minus the EBA covered-to-eligible ratio) to test for treatment-intensity heterogeneity. Redeemable-at-notice data are missing for Spain and Croatia, reducing Column~3 to 17 countries. Standard errors clustered at the country level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
), paste0(tab_dir, "tab2_main_results.tex"))

cat("Table 2 saved: main results\n")

# ===========================================================================
# TABLE 3: Corporate Deposit Placebo
# ===========================================================================

plac_ov <- results[specification == "Placebo: Corporate Overnight"]
plac_ag <- results[specification == "Placebo: Corporate Agreed"]
sec_did <- results[specification == "Sector DDD (post_x_hh)"]

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo Test: Corporate Deposits and Sector Difference-in-Differences}",
  "\\label{tab:placebo}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Corp. Overnight & Corp. Agreed & Sector DDD \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  sprintf("Post-BRRD & %s & %s & %s \\\\",
          format_coef(plac_ov$estimate, plac_ov$se, plac_ov$stars),
          format_coef(plac_ag$estimate, plac_ag$se, plac_ag$stars),
          format_coef(sec_post$estimate, sec_post$se, sec_post$stars)),
  sprintf(" & %s & %s & %s \\\\",
          format_se(plac_ov$se), format_se(plac_ag$se), format_se(sec_post$se)),
  sprintf("Post $\\times$ Household & & & %s \\\\",
          format_coef(sec_did$estimate, sec_did$se, sec_did$stars)),
  sprintf(" & & & %s \\\\", format_se(sec_did$se)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
          format(sum(!is.na(nfc$share_overnight)), big.mark=","),
          format(sum(!is.na(nfc$share_agreed)), big.mark=","),
          format(sum(!is.na(hh$share_overnight)) + sum(!is.na(nfc$share_overnight)), big.mark=",")),
  sprintf("Countries & %d & %d & %d \\\\",
          uniqueN(nfc[!is.na(share_overnight)]$country),
          uniqueN(nfc[!is.na(share_agreed)]$country),
          uniqueN(nfc[!is.na(share_overnight)]$country)),
  "Country FE & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes \\\\",
  "Clustering & Country & Country & Country \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns 1--2 replicate the main specification on non-financial corporate deposits (placebo sector). Column 3 reports a sector-level difference-in-differences combining household and corporate deposits, where Post $\\times$ Household tests whether BRRD effects are differentially larger for households. Standard errors clustered at the country level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
), paste0(tab_dir, "tab3_placebo.tex"))

cat("Table 3 saved: placebo\n")

# ===========================================================================
# TABLE 4: BRRD Transposition Dates
# ===========================================================================

brrd <- fread(paste0(data_dir, "brrd_transposition_dates.csv"))
brrd[, transposition_date := as.Date(transposition_date)]
# Exclude countries not in BSI sample (BG, DK, EL)
excluded_bsi <- c("BG", "DK", "EL")
brrd_sorted <- brrd[!(country %in% excluded_bsi)][order(transposition_date)]

eba_full <- fread(paste0(data_dir, "eba_dgs_ratios.csv"))
brrd_sorted <- merge(brrd_sorted, eba_full[, .(country, uninsured_share)],
                     by = "country", all.x = TRUE)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{BRRD National Transposition Dates and Deposit Insurance Coverage}",
  "\\label{tab:brrd_dates}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcc}",
  "\\toprule",
  "Country & Transposition Date & Days Relative to Deadline & Uninsured Share \\\\",
  "\\midrule"
)

for (i in 1:nrow(brrd_sorted)) {
  days_late <- as.numeric(brrd_sorted$transposition_date[i] - as.Date("2014-12-31"))
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s & %d & %.1f\\%% \\\\",
            brrd_sorted$country_name[i],
            format(brrd_sorted$transposition_date[i], "%B %d, %Y"),
            days_late,
            brrd_sorted$uninsured_share[i] * 100))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Transposition dates from the IWH Banking Union Directives Database, cross-validated with CELLAR SPARQL national implementation measures. Uninsured share computed as one minus the covered-to-eligible deposit ratio from EBA Deposit Guarantee Scheme aggregate data (2015). The BRRD transposition deadline was December 31, 2014. Three countries (Bulgaria, Denmark, Greece) are excluded due to incomplete BSI coverage. Five countries (Czech Republic, Hungary, Poland, Romania, Sweden) are included in this table for completeness but lack maturity-disaggregated BSI data and are excluded from all regression analyses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, paste0(tab_dir, "tab4_brrd_dates.tex"))
cat("Table 4 saved: BRRD dates\n")

# ===========================================================================
# TABLE 5: Heterogeneity-Robust Estimators (CS-DiD & Sun-Abraham)
# ===========================================================================

cs_results <- fread(paste0(data_dir, "cs_results.csv"))
sa_att <- fread(paste0(data_dir, "sa_att_results.csv"))
loo <- fread(paste0(data_dir, "loo_results.csv"))
robust <- fread(paste0(data_dir, "robustness_summary.csv"))

# CS-DiD results
cs_ov <- cs_results[specification == "CS-DiD Overnight (ATT)"]
cs_ag <- cs_results[specification == "CS-DiD Agreed (ATT)"]
cs_ov[, stars := fifelse(p_value < 0.01, "***",
                   fifelse(p_value < 0.05, "**",
                   fifelse(p_value < 0.10, "*", "")))]
cs_ag[, stars := fifelse(p_value < 0.01, "***",
                   fifelse(p_value < 0.05, "**",
                   fifelse(p_value < 0.10, "*", "")))]

# SA results
sa_ov <- sa_att[specification == "Sun-Abraham overnight"]
sa_ag <- sa_att[specification == "Sun-Abraham agreed"]

# TWFE from main results for comparison
twfe_ov_main <- results[specification == "TWFE Overnight"]
twfe_ag_main <- results[specification == "TWFE Agreed"]

n_eff_ov <- sum(!is.na(hh$share_overnight))
n_eff_ag <- sum(!is.na(hh$share_agreed))
n_ctry_ov <- uniqueN(hh[!is.na(share_overnight)]$country)

writeLines(c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity-Robust Estimators: Callaway-Sant'Anna and Sun-Abraham}",
  "\\label{tab:robust_estimators}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & TWFE & Callaway-Sant'Anna & Sun-Abraham \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Overnight Deposit Share}} \\\\[3pt]",
  sprintf("ATT & %s & %s & %s \\\\",
          format_coef(twfe_ov_main$estimate, twfe_ov_main$se, twfe_ov_main$stars),
          format_coef(cs_ov$estimate, cs_ov$se, cs_ov$stars),
          format_coef(sa_ov$estimate, sa_ov$se, sa_ov$stars)),
  sprintf(" & %s & %s & %s \\\\",
          format_se(twfe_ov_main$se), format_se(cs_ov$se), format_se(sa_ov$se)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Agreed-Maturity Deposit Share}} \\\\[3pt]",
  sprintf("ATT & %s & %s & %s \\\\",
          format_coef(twfe_ag_main$estimate, twfe_ag_main$se, twfe_ag_main$stars),
          format_coef(cs_ag$estimate, cs_ag$se, cs_ag$stars),
          format_coef(sa_ag$estimate, sa_ag$se, sa_ag$stars)),
  sprintf(" & %s & %s & %s \\\\",
          format_se(twfe_ag_main$se), format_se(cs_ag$se), format_se(sa_ag$se)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
          format(n_eff_ov, big.mark=","), format(n_eff_ov, big.mark=","),
          format(n_eff_ov, big.mark=",")),
  sprintf("Countries & %d & %d & %d \\\\",
          n_ctry_ov, n_ctry_ov, n_ctry_ov),
  "Estimator & TWFE & CS (2021) & SA (2021) \\\\",
  "Control group & --- & Not-yet-treated & --- \\\\",
  "Country FE & Yes & (implicit) & Yes \\\\",
  "Month FE & Yes & (implicit) & Yes \\\\",
  "Clustering & Country & Analytic & Country \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column 1 reports the two-way fixed effects estimate for comparison. Column 2 reports the simple (unconditional) ATT from \\citet{callaway2021difference} using not-yet-treated countries as the control group; standard errors are analytical (pointwise). Column 3 reports the \\citet{sunab2021estimating} interaction-weighted ATT aggregated across cohort-time cells; 83 interactions were dropped due to collinearity, so the SA estimate may overweight specific cohort comparisons. Standard errors for TWFE and SA are clustered at the country level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
), paste0(tab_dir, "tab5_robust_estimators.tex"))

cat("Table 5 saved: robust estimators\n")

# ===========================================================================
# TABLE 6: Robustness Summary
# ===========================================================================

writeLines(c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary of Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llccc}",
  "\\toprule",
  "Check & Estimate & SE & $N$ & Note \\\\",
  "\\midrule",
  paste0(apply(robust, 1, function(r) {
    paste(r["check"], "&", r["estimate"], "&", r["se"], "&", r["n_obs"], "&", r["note"], "\\\\")
  }), collapse = "\n"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Summary of robustness checks from the main TWFE and intensity-interaction specifications. Leave-one-out reports the range of TWFE overnight coefficients when each country is dropped. RI $p$-value tests the TWFE specification (which is biased under staggered adoption). All specifications include country and time fixed effects with standard errors clustered at the country level.",
  "\\end{tablenotes}",
  "\\end{table}"
), paste0(tab_dir, "tab6_robustness.tex"))

cat("Table 6 saved: robustness summary\n")

cat("\nAll tables generated.\n")
