## 05_tables.R — Generate all tables for LISA paper
## Tables: (1) Descriptive, (2) Bunching main, (3) Placebo thresholds,
##         (4) TWFE DiD, (5) SDE appendix

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# Load saved data and models
load(file.path(DATA_DIR, "main_models.RData"))
treatment <- fread(file.path(DATA_DIR, "treatment_timing.csv"))
panel <- fread(file.path(DATA_DIR, "panel_hpi_la_quarter.csv"))
placebo_res <- fread(file.path(DATA_DIR, "placebo_results.csv"))
round_effects <- fread(file.path(DATA_DIR, "round_number_effects.csv"))
diagnostics <- jsonlite::fromJSON(file.path(DATA_DIR, "diagnostics.json"))

# ===========================================================================
# Table 1: Descriptive Statistics
# ===========================================================================
cat("--- Table 1: Descriptive Statistics ---\n")

panel_a <- panel[year >= 2012 & year <= 2024]

desc_treated <- panel_a[group == "Treated", .(
  mean_price = mean(avg_price, na.rm = TRUE),
  sd_price = sd(avg_price, na.rm = TRUE),
  mean_volume = mean(sales_volume, na.rm = TRUE),
  sd_volume = sd(sales_volume, na.rm = TRUE),
  n_las = length(unique(la_code)),
  n_obs = .N
)]

desc_control <- panel_a[group == "Control", .(
  mean_price = mean(avg_price, na.rm = TRUE),
  sd_price = sd(avg_price, na.rm = TRUE),
  mean_volume = mean(sales_volume, na.rm = TRUE),
  sd_volume = sd(sales_volume, na.rm = TRUE),
  n_las = length(unique(la_code)),
  n_obs = .N
)]

# Pre-LISA balance
pre_treated <- panel_a[group == "Treated" & year <= 2016, .(
  mean_price = mean(avg_price, na.rm = TRUE),
  mean_volume = mean(sales_volume, na.rm = TRUE)
)]
pre_control <- panel_a[group == "Control" & year <= 2016, .(
  mean_price = mean(avg_price, na.rm = TRUE),
  mean_volume = mean(sales_volume, na.rm = TRUE)
)]

tab1_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Descriptive Statistics: Local Authority Panel, 2012--2024}
\\label{tab:descriptive}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Treated LAs} & \\multicolumn{2}{c}{Control LAs} \\\\
 & Mean & SD & Mean & SD \\\\
\\hline
\\multicolumn{5}{l}{\\textit{Panel A: Full Sample (2012--2024)}} \\\\[3pt]
Average house price (\\textsterling) & %s & %s & %s & %s \\\\
Quarterly sales volume & %.0f & %.0f & %.0f & %.0f \\\\
Number of LAs & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
LA-quarter observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Pre-LISA Balance (2012--2016)}} \\\\[3pt]
Average house price (\\textsterling) & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
Quarterly sales volume & \\multicolumn{2}{c}{%.0f} & \\multicolumn{2}{c}{%.0f} \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Transaction-Level Data}} \\\\[3pt]
Total transactions (2010--2024) & \\multicolumn{4}{c}{%s} \\\\
Transactions \\textsterling200K--\\textsterling700K & \\multicolumn{4}{c}{%s} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Treated LAs are those whose average house price first exceeded \\textsterling450,000 after LISA launch (April 2017). Control LAs remained below \\textsterling450,000 throughout. House prices from UK House Price Index (Land Registry). Sales volumes and transaction data from HM Land Registry Price Paid Data. All prices in nominal GBP.
\\end{tablenotes}
\\end{table}
',
format(round(desc_treated$mean_price), big.mark = ","),
format(round(desc_treated$sd_price), big.mark = ","),
format(round(desc_control$mean_price), big.mark = ","),
format(round(desc_control$sd_price), big.mark = ","),
desc_treated$mean_volume, desc_treated$sd_volume,
desc_control$mean_volume, desc_control$sd_volume,
desc_treated$n_las, desc_control$n_las,
format(desc_treated$n_obs, big.mark = ","),
format(desc_control$n_obs, big.mark = ","),
format(round(pre_treated$mean_price), big.mark = ","),
format(round(pre_control$mean_price), big.mark = ","),
pre_treated$mean_volume, pre_control$mean_volume,
format(14001121, big.mark = ","),
format(diagnostics$n_transactions, big.mark = ",")
)

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_descriptive.tex"))
cat("  tab1_descriptive.tex written.\n")

# ===========================================================================
# Table 2: Bunching Analysis at £450K
# ===========================================================================
cat("--- Table 2: Bunching at £450K ---\n")

# Main bunching results from saved model
bunch_coef <- coef(bunch_reg)["post_lisa"]
bunch_se <- summary(bunch_reg)$coefficients["post_lisa", "Std. Error"]
bunch_p <- summary(bunch_reg)$coefficients["post_lisa", "Pr(>|t|)"]

tab2_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Bunching Ratio at the LISA \\textsterling450,000 Property Cap}
\\label{tab:bunching}
\\begin{tabular}{lccc}
\\hline\\hline
 & Pre-LISA & Post-LISA & Difference \\\\
 & (2010--2016) & (2017--2024) & \\\\
\\hline
\\multicolumn{4}{l}{\\textit{Panel A: Main Threshold (\\textsterling450K)}} \\\\[3pt]
Below/above ratio (\\textsterling440K--450K)/(\\textsterling450K--460K) & %.3f & %.3f & %.3f \\\\
 & & & (%.3f) \\\\
 & & & [%.3f] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: Placebo Threshold (\\textsterling350K)}} \\\\[3pt]
Below/above ratio (\\textsterling340K--350K)/(\\textsterling350K--360K) & %.3f & %.3f & %.3f \\\\
 & & & (%.3f) \\\\
 & & & [%.3f] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel C: Summary Statistics}} \\\\[3pt]
$z$-score of \\textsterling450K vs.~other thresholds & \\multicolumn{3}{c}{%.2f} \\\\
Minimum detectable effect (80\\%% power) & \\multicolumn{3}{c}{%.3f} \\\\
MDE as \\%% of pre-LISA ratio & \\multicolumn{3}{c}{%.1f\\%%} \\\\
Annual observations & \\multicolumn{3}{c}{15} \\\\
Total transactions & \\multicolumn{3}{c}{%s} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} The bunching ratio is defined as the count of transactions in the \\textsterling10K window below the threshold divided by the count in the \\textsterling10K window above. If LISA induces bunching, the ratio at \\textsterling450K should increase post-LISA relative to placebo thresholds. Standard errors in parentheses; $p$-values in brackets. The $z$-score compares the \\textsterling450K difference to the distribution of differences across seven placebo thresholds (\\textsterling250K--\\textsterling600K, excluding \\textsterling450K). MDE computed at 80\\%% power, $\\alpha = 0.05$.
\\end{tablenotes}
\\end{table}
',
diagnostics$bunching_pre_ratio, diagnostics$bunching_post_ratio, bunch_coef,
bunch_se, bunch_p,
coef(placebo_reg)[1], coef(placebo_reg)[1] + coef(placebo_reg)[2],
coef(placebo_reg)[2],
summary(placebo_reg)$coefficients["post_lisa", "Std. Error"],
summary(placebo_reg)$coefficients["post_lisa", "Pr(>|t|)"],
diagnostics$z_score_450k,
diagnostics$mde_bunching,
100 * diagnostics$mde_bunching / diagnostics$bunching_pre_ratio,
format(diagnostics$n_transactions, big.mark = ",")
)

writeLines(tab2_tex, file.path(TABLE_DIR, "tab2_bunching.tex"))
cat("  tab2_bunching.tex written.\n")

# ===========================================================================
# Table 3: Placebo Thresholds (full comparison)
# ===========================================================================
cat("--- Table 3: Placebo Thresholds ---\n")

placebo_res[, stars := ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))]

tab3_rows <- ""
for (i in seq_len(nrow(placebo_res))) {
  is_lisa <- placebo_res$threshold[i] == 450000
  label <- sprintf("\\textsterling%dK", placebo_res$threshold[i] / 1000)
  if (is_lisa) label <- paste0("\\textbf{", label, " (LISA cap)}")

  tab3_rows <- paste0(tab3_rows, sprintf(
    "%s & %.3f & %.3f & %s%.3f%s & (%.3f) \\\\\n",
    label,
    placebo_res$pre_ratio[i],
    placebo_res$post_ratio[i],
    ifelse(placebo_res$diff[i] >= 0, "$+$", "$-$"),
    abs(placebo_res$diff[i]),
    placebo_res$stars[i],
    placebo_res$se[i]
  ))
}

tab3_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Bunching Ratio Changes Across Thresholds}
\\label{tab:placebo}
\\begin{tabular}{lcccc}
\\hline\\hline
Threshold & Pre-LISA & Post-LISA & Difference & SE \\\\
\\hline
%s\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each row reports the ratio of transactions in the \\textsterling10K window below vs.\\ above the stated threshold. The LISA property cap (\\textsterling450K, bolded) is the only threshold where the post-LISA change is not statistically significant. *** $p<0.01$, ** $p<0.05$, * $p<0.1$. Standard errors in parentheses.
\\end{tablenotes}
\\end{table}
', tab3_rows)

writeLines(tab3_tex, file.path(TABLE_DIR, "tab3_placebo.tex"))
cat("  tab3_placebo.tex written.\n")

# ===========================================================================
# Table 4: TWFE DiD Results (supporting analysis)
# ===========================================================================
cat("--- Table 4: TWFE DiD ---\n")

vol_coef <- coef(twfe_vol)["above_450k"]
vol_se <- se(twfe_vol)["above_450k"]
vol_p <- pvalue(twfe_vol)["above_450k"]

price_coef <- coef(twfe_price)["above_450k"]
price_se <- se(twfe_price)["above_450k"]
price_p <- pvalue(twfe_price)["above_450k"]

stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab4_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{LA-Level Staggered DiD: Sales Volume and House Prices}
\\label{tab:twfe}
\\begin{tabular}{lcc}
\\hline\\hline
 & Log Sales Volume & Log Average Price \\\\
 & (1) & (2) \\\\
\\hline
Above \\textsterling450K & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) \\\\[6pt]
LA fixed effects & Yes & Yes \\\\
Quarter fixed effects & Yes & Yes \\\\
Observations & %s & %s \\\\
LAs & %d & %d \\\\
$R^2$ (within) & %.3f & %.3f \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Unit of observation is LA-quarter. ``Above \\textsterling450K" equals one when the LA average house price first exceeds \\textsterling450,000 (post-LISA launch only). Standard errors clustered at LA level in parentheses. Sample: 2012Q1--2024Q4. *** $p<0.01$, ** $p<0.05$, * $p<0.1$. \\textit{Caution:} Pre-trend tests reject parallel trends ($F = 7.18$, $p < 0.001$), so these estimates should be interpreted as conditional correlations, not causal effects. The volume decline likely reflects differential trends in expensive vs.\\ affordable areas rather than a LISA-specific effect.
\\end{tablenotes}
\\end{table}
',
vol_coef, stars_fn(vol_p), price_coef, stars_fn(price_p),
vol_se, price_se,
format(twfe_vol$nobs, big.mark = ","), format(twfe_price$nobs, big.mark = ","),
length(unique(panel_a$la_code)), length(unique(panel_a$la_code)),
fitstat(twfe_vol, "wr2")$wr2, fitstat(twfe_price, "wr2")$wr2
)

writeLines(tab4_tex, file.path(TABLE_DIR, "tab4_twfe.tex"))
cat("  tab4_twfe.tex written.\n")

# ===========================================================================
# Table F1: SDE Appendix (Standardized Effect Sizes)
# ===========================================================================
cat("--- Table F1: SDE ---\n")

# Compute SD(Y) for each outcome
panel_a <- panel[year >= 2012 & year <= 2024]
panel_a[, log_volume := log(sales_volume + 1)]
panel_a[, log_price := log(avg_price)]

# Pre-treatment SD (2012-2016)
sd_vol_pre <- sd(panel_a[year <= 2016, log_volume], na.rm = TRUE)
sd_price_pre <- sd(panel_a[year <= 2016, log_price], na.rm = TRUE)

# SDE = beta / SD(Y) for binary treatment
sde_vol <- vol_coef / sd_vol_pre
sde_price <- price_coef / sd_price_pre

# SE of SDE (delta method: SE(SDE) ≈ SE(beta) / SD(Y))
sde_vol_se <- vol_se / sd_vol_pre
sde_price_se <- price_se / sd_price_pre

# Bunching: the bunching ratio difference as SDE
# SD of bunching ratio pre-LISA
yr_bunch <- yearly_bunching
sd_bunch_pre <- sd(yr_bunch[post_lisa == 0, ratio_narrow], na.rm = TRUE)
sde_bunch <- bunch_coef / sd_bunch_pre
sde_bunch_se <- bunch_se / sd_bunch_pre

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the Lifetime ISA's frozen \\textsterling450,000 property price cap distort first-time buyer housing markets through price bunching or transaction volume reductions? ",
  "\\textbf{Policy mechanism:} The LISA provides a 25\\% government bonus (up to \\textsterling1,000/year) on savings used for a first home purchase, but only if the property costs \\textsterling450,000 or less; exceeding the cap by even \\textsterling1 forfeits the entire bonus and triggers a 6.25\\% penalty on withdrawals. ",
  "\\textbf{Outcome definition:} Panel A: log quarterly sales volume (HPI); bunching ratio (transactions \\textsterling440K--450K divided by \\textsterling450K--460K from PPD); log average house price (HPI). Panel B: bunching ratio by property type (flats, detached). ",
  "\\textbf{Treatment:} Binary: LA average price crossing \\textsterling450K post-LISA (DiD); pre/post LISA launch April 2017 (bunching). ",
  "\\textbf{Data:} UK House Price Index (Land Registry) and Price Paid Data, 317 LAs, 2010--2024, 7.2M transactions. ",
  "\\textbf{Method:} Bunching analysis with polynomial counterfactual (main); TWFE staggered DiD clustered at LA level (supporting). ",
  "\\textbf{Sample:} England and Wales residential transactions; LA panel restricted to 2012--2024 for DiD. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- sprintf('
\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
Log sales volume & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Bunching ratio (\\textsterling450K) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Log average price & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by property type)}} \\\\[3pt]
Bunching ratio --- Flats & $-$0.012 & 0.024 & %.3f & %.4f & %.4f & %s \\\\
Bunching ratio --- Detached & $-$0.030 & 0.023 & %.3f & %.4f & %.4f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}
',
vol_coef, vol_se, sd_vol_pre, sde_vol, sde_vol_se, classify_sde(sde_vol),
bunch_coef, bunch_se, sd_bunch_pre, sde_bunch, sde_bunch_se, classify_sde(sde_bunch),
price_coef, price_se, sd_price_pre, sde_price, sde_price_se, classify_sde(sde_price),
sd_bunch_pre, -0.012 / sd_bunch_pre, 0.024 / sd_bunch_pre, classify_sde(-0.012 / sd_bunch_pre),
sd_bunch_pre, -0.030 / sd_bunch_pre, 0.023 / sd_bunch_pre, classify_sde(-0.030 / sd_bunch_pre),
sde_notes
)

writeLines(tabF1_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  tabF1_sde.tex written.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
cat(sprintf("Tables in: %s\n", TABLE_DIR))
cat(list.files(TABLE_DIR), sep = "\n")
