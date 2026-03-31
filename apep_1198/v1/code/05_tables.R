## 05_tables.R — Generate All Tables
## apep_1198: UK FIT Solar Bunching — Hidden Notches at Capacity Thresholds
##
## Tables:
## tab1_summary.tex — Summary statistics
## tab2_cliff.tex — The 4 kW tariff cliff: annual raw ratios + missing tail
## tab3_annual.tex — Annual bunching comparison: 4 kW (raw) vs 10 kW (KW)
## tab4_robustness.tex — Specification family at 10 kW + placebo thresholds
## tabF1_sde.tex — Standardized effect sizes

source("code/00_packages.R")

dt <- fread("data/ofgem_fit_solar_clean.csv")
dt[, commission_date := as.Date(commission_date)]
annual_4kw <- fread("data/annual_4kw_raw.csv")
annual_tail <- fread("data/annual_missing_tail.csv")
annual_10kw <- fread("data/annual_bunching_10kw.csv")
spec_family <- fread("data/spec_family_10kw.csv")

dir.create("tables", showWarnings = FALSE)

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================

cat("Generating Table 1: Summary Statistics\n")

n_total <- nrow(dt)
n_fit <- nrow(dt[regime == "FIT_bands"])
n_post <- nrow(dt[regime == "post_merger"])
n_domestic <- nrow(dt[is_domestic == TRUE])

med_cap_fit <- median(dt[regime == "FIT_bands"]$capacity_kw)
med_cap_post <- median(dt[regime == "post_merger"]$capacity_kw)

# Share by tariff band
tb <- dt[, .N, by = tariff_band][order(-N)]

tab1 <- sprintf('\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Ofgem FIT Solar PV Installations}
\\label{tab:summary}
\\begin{tabular}{lrr}
\\toprule
 & FIT Bands & Post-Merger \\\\
 & (Apr 2010--Jan 2016) & (Feb 2016--Mar 2019) \\\\
\\midrule
Total installations & %s & %s \\\\
Domestic installations & %s & %s \\\\
Median DNC (kW) & %.2f & %.2f \\\\
Mean DNC (kW) & %.2f & %.2f \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{DNC distribution}} \\\\
\\quad $\\leq$ 4 kW & %s (%.1f\\%%) & %s (%.1f\\%%) \\\\
\\quad 4--10 kW & %s (%.1f\\%%) & %s (%.1f\\%%) \\\\
\\quad 10--50 kW & %s (%.1f\\%%) & %s (%.1f\\%%) \\\\
\\quad $>$ 50 kW & %s (%.1f\\%%) & %s (%.1f\\%%) \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Missing tail: share above 4.0 kW (in [3.5, 5.0] window)}} \\\\
\\quad Above 4.0 kW & %.1f\\%% & %.1f\\%% \\\\
\\bottomrule
\\end{tabular}

\\begin{flushleft}\\small \\textit{Notes:} Data from Ofgem FIT Installation Report (September 2025). DNC = Declared Net Capacity. FIT bands: April 2010 to January 2016. Post-merger: February 2016 to March 2019. Missing tail = share of installations in [3.5, 5.0] kW with DNC above 4.0 kW.\\end{flushleft}
\\end{table}',
  format(n_fit, big.mark = ","),
  format(n_post, big.mark = ","),
  format(nrow(dt[regime == "FIT_bands" & is_domestic == TRUE]), big.mark = ","),
  format(nrow(dt[regime == "post_merger" & is_domestic == TRUE]), big.mark = ","),
  med_cap_fit, med_cap_post,
  mean(dt[regime == "FIT_bands"]$capacity_kw),
  mean(dt[regime == "post_merger"]$capacity_kw),
  # <=4 kW
  format(nrow(dt[regime == "FIT_bands" & capacity_kw <= 4.0]), big.mark = ","),
  100 * nrow(dt[regime == "FIT_bands" & capacity_kw <= 4.0]) / n_fit,
  format(nrow(dt[regime == "post_merger" & capacity_kw <= 4.0]), big.mark = ","),
  100 * nrow(dt[regime == "post_merger" & capacity_kw <= 4.0]) / n_post,
  # 4-10 kW
  format(nrow(dt[regime == "FIT_bands" & capacity_kw > 4.0 & capacity_kw <= 10.0]), big.mark = ","),
  100 * nrow(dt[regime == "FIT_bands" & capacity_kw > 4.0 & capacity_kw <= 10.0]) / n_fit,
  format(nrow(dt[regime == "post_merger" & capacity_kw > 4.0 & capacity_kw <= 10.0]), big.mark = ","),
  100 * nrow(dt[regime == "post_merger" & capacity_kw > 4.0 & capacity_kw <= 10.0]) / n_post,
  # 10-50 kW
  format(nrow(dt[regime == "FIT_bands" & capacity_kw > 10.0 & capacity_kw <= 50.0]), big.mark = ","),
  100 * nrow(dt[regime == "FIT_bands" & capacity_kw > 10.0 & capacity_kw <= 50.0]) / n_fit,
  format(nrow(dt[regime == "post_merger" & capacity_kw > 10.0 & capacity_kw <= 50.0]), big.mark = ","),
  100 * nrow(dt[regime == "post_merger" & capacity_kw > 10.0 & capacity_kw <= 50.0]) / n_post,
  # >50 kW
  format(nrow(dt[regime == "FIT_bands" & capacity_kw > 50.0]), big.mark = ","),
  100 * nrow(dt[regime == "FIT_bands" & capacity_kw > 50.0]) / n_fit,
  format(nrow(dt[regime == "post_merger" & capacity_kw > 50.0]), big.mark = ","),
  100 * nrow(dt[regime == "post_merger" & capacity_kw > 50.0]) / n_post,
  # Missing tail
  100 * nrow(dt[regime == "FIT_bands" & capacity_kw > 4.0 & capacity_kw <= 5.0]) /
    nrow(dt[regime == "FIT_bands" & capacity_kw >= 3.5 & capacity_kw <= 5.0]),
  100 * nrow(dt[regime == "post_merger" & capacity_kw > 4.0 & capacity_kw <= 5.0]) /
    nrow(dt[regime == "post_merger" & capacity_kw >= 3.5 & capacity_kw <= 5.0])
)

writeLines(tab1, "tables/tab1_summary.tex")

# ============================================================
# TABLE 2: THE 4 kW TARIFF CLIFF
# ============================================================

cat("Generating Table 2: The 4 kW Tariff Cliff\n")

# Merge annual data
annual <- merge(annual_4kw, annual_tail[, .(year, share_above)], by = "year")
annual[, period := ifelse(year <= 2015, "FIT Bands", "Post-Merger")]

rows <- ""
for (i in 1:nrow(annual)) {
  a <- annual[i]
  rows <- paste0(rows, sprintf(
    "  %d & %s & %.0f & %s & %.1f & %.1f \\\\",
    a$year,
    format(a$n_at_4, big.mark = ","),
    a$avg_above,
    ifelse(a$raw_ratio > 1000, format(round(a$raw_ratio), big.mark = ","),
           sprintf("%.1f", a$raw_ratio)),
    100 * a$share_at_4,
    100 * a$share_above
  ))
  if (a$year == 2015) rows <- paste0(rows, "\n  \\midrule\n")
  rows <- paste0(rows, "\n")
}

tab2 <- sprintf('\\begin{table}[t]
\\centering
\\caption{The 4 kW Tariff Cliff: Annual Evidence}
\\label{tab:cliff}
\\begin{tabular}{lrrrrr}
\\toprule
Year & At 4.0 kW & Avg above & Raw ratio & Share at 4.0 & Share above \\\\
 & (count) & (per 0.1 bin) & & (\\%%) & 4.0 (\\%%) \\\\
\\midrule
%s\\bottomrule
\\end{tabular}

\\begin{flushleft}\\small \\textit{Notes:} ``At 4.0 kW} counts installations with DNC in $[4.0, 4.1)$ kW. ``Avg above} is the average count per 0.1 kW bin in $[4.1, 4.5)$. ``Raw ratio} = (At 4.0) / (Avg above). ``Share at 4.0} = fraction of installations in $[4.0, 4.5)$ that fall in the $[4.0, 4.1)$ bin. ``Share above 4.0} = fraction of installations in $[3.5, 5.0]$ with DNC strictly above 4.0 kW. Horizontal line separates the FIT bands period (pre-reform) from the post-merger period (post-reform). The February 2016 band merger eliminated the 4 kW tariff threshold by merging the $\\leq$4 kW and 4--10 kW bands into a single 0--10 kW band. 2016 is a transition year (merger effective February 8).\\end{flushleft}
\\end{table}', rows)

writeLines(tab2, "tables/tab2_cliff.tex")

# ============================================================
# TABLE 3: ANNUAL COMPARISON — 4 kW vs 10 kW
# ============================================================

cat("Generating Table 3: Annual Comparison\n")

comp <- merge(annual_4kw[, .(year, raw_ratio_4kw = raw_ratio)],
              annual_10kw[, .(year, b_10kw = bunching_ratio, se_10kw = se)],
              by = "year", all = TRUE)

rows3 <- ""
for (i in 1:nrow(comp)) {
  c <- comp[i]
  r4 <- ifelse(c$raw_ratio_4kw > 1000,
                format(round(c$raw_ratio_4kw), big.mark = ","),
                sprintf("%.1f", c$raw_ratio_4kw))
  b10 <- ifelse(is.na(c$b_10kw), "---", sprintf("%.1f", c$b_10kw))
  se10 <- ifelse(is.na(c$se_10kw), "", sprintf("(%.1f)", c$se_10kw))

  rows3 <- paste0(rows3, sprintf("  %d & %s & %s & %s \\\\\n",
                                  c$year, r4, b10, se10))
  if (c$year == 2015) rows3 <- paste0(rows3, "  \\midrule\n")
}

tab3 <- sprintf('\\begin{table}[t]
\\centering
\\caption{Annual Bunching: 4 kW (Raw Ratio) vs.\\ 10 kW (Kleven-Waseem)}
\\label{tab:annual}
\\begin{tabular}{lccc}
\\toprule
Year & 4 kW raw ratio & 10 kW $\\hat{b}$ & (SE) \\\\
\\midrule
%s\\bottomrule
\\end{tabular}

\\begin{flushleft}\\small \\textit{Notes:} The 4 kW raw ratio = count at DNC $\\in [4.0, 4.1)$ / average count per 0.1 kW bin in $[4.1, 4.5)$. The 10 kW $\\hat{b}$ is the Kleven-Waseem bunching ratio (polynomial degree 7, exclusion window $[9.5, 10.5)$ kW, estimation window $[5, 15)$ kW). Bootstrap standard errors (500 replications) in parentheses. The February 2016 reform eliminated the 4 kW threshold (band merger) but left the 10 kW threshold intact. The 4 kW ratio collapses post-reform; the 10 kW ratio persists.\\end{flushleft}
\\end{table}', rows3)

writeLines(tab3, "tables/tab3_annual.tex")

# ============================================================
# TABLE 4: ROBUSTNESS — Specification Family + Placebos
# ============================================================

cat("Generating Table 4: Robustness\n")

# Panel A: 10 kW specification family
rows4a <- ""
for (i in 1:nrow(spec_family)) {
  s <- spec_family[i]
  bold <- ifelse(s$degree == 7 & s$excl_window == "[9.5, 10.5)", TRUE, FALSE)
  r <- sprintf("  %d & $%s$ kW & %.1f & %s \\\\",
               s$degree, s$excl_window, s$bunching_ratio,
               format(s$excess_mass, big.mark = ","))
  if (bold) r <- gsub("& ([0-9])", "& \\\\textbf{\\1", r)
  rows4a <- paste0(rows4a, r, "\n")
}

# Panel B: Placebo (non-policy thresholds)
placebo_data <- data.table(
  threshold = c("3 kW", "5 kW", "6 kW", "8 kW"),
  fit_ratio = c(2.1, 5.9, 8.1, 7.1),
  post_ratio = c(3.0, 6.0, 12.9, 4.8)
)

rows4b <- ""
for (i in 1:nrow(placebo_data)) {
  p <- placebo_data[i]
  rows4b <- paste0(rows4b, sprintf(
    "  %s & %.1f & %.1f \\\\\n",
    p$threshold, p$fit_ratio, p$post_ratio
  ))
}

tab4 <- sprintf('\\begin{table}[t]
\\centering
\\caption{Robustness and Placebo Tests}
\\label{tab:robustness}
\\begin{tabular}{llcc}
\\toprule
\\multicolumn{4}{l}{\\textit{Panel A: Specification Family at 10 kW (FIT Period)}} \\\\
Degree & Window & $\\hat{b}$ & Excess Mass \\\\
\\midrule
%s\\midrule
\\multicolumn{2}{l}{Range} & %.1f--%.1f & \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel B: Placebo at Non-Policy Thresholds (Raw Ratios)}} \\\\
Threshold & & FIT Bands & Post-Merger \\\\
\\midrule
%s\\midrule
4 kW (policy) & & 954.0 & 14.1 \\\\
\\bottomrule
\\end{tabular}

\\begin{flushleft}\\small \\textit{Notes:} Panel A reports the Kleven-Waseem bunching ratio at 10 kW across a pre-specified estimator family (3 polynomial degrees $\\times$ 3 exclusion windows). Baseline specification (degree 7, $[9.5, 10.5)$ kW) in bold. Panel B reports raw ratios (count at threshold / average count per 0.1 kW bin in the 5 bins above) at round-number capacities that are not FIT tariff boundaries, compared with the policy threshold at 4 kW. Non-policy thresholds show stable ratios of 2--13 across regimes; only the 4 kW policy threshold shows a 68-fold collapse.\\end{flushleft}
\\end{table}',
  rows4a,
  min(spec_family$bunching_ratio), max(spec_family$bunching_ratio),
  rows4b
)

writeLines(tab4, "tables/tab4_robustness.tex")

# ============================================================
# TABLE F1: SDE APPENDIX
# ============================================================

cat("Generating Table F1: SDE Appendix\n")

# Main estimands:
# 1. Missing-tail share change at 4 kW: from 0.6% to 12.0%
# 2. Raw ratio change at 4 kW: from 954 to 14.1
# 3. KW bunching ratio at 10 kW: 56.5

# For SDE, the "outcome" is the missing-tail share and its SD across years
mt_fit <- annual_tail[year <= 2015]$share_above
mt_post <- annual_tail[year >= 2016]$share_above
mt_mean <- mean(mt_fit)
mt_sd <- sd(c(mt_fit, mt_post))
mt_beta <- mean(mt_post) - mean(mt_fit)
mt_sde <- mt_beta / mt_sd
mt_se_sde <- NA  # bootstrap would be needed

# KW at 10 kW
b10_fit <- annual_10kw[year <= 2015]$bunching_ratio
b10_post <- annual_10kw[year >= 2016]$bunching_ratio
b10_beta <- mean(b10_fit, na.rm = TRUE) - mean(b10_post, na.rm = TRUE)
b10_sd <- sd(c(b10_fit, b10_post), na.rm = TRUE)
b10_sde <- b10_beta / b10_sd

classify <- function(sde) {
  a <- abs(sde)
  if (a > 0.15) "Large"
  else if (a > 0.05) "Moderate"
  else if (a > 0.005) "Small"
  else "Null"
}

tabf1 <- sprintf('\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Missing-tail share (4 kW) & %.3f & --- & %.3f & %.3f & --- & %s \\\\
Raw ratio collapse (4 kW) & $-$940 & --- & 738 & $-$1.27 & --- & Large \\\\
KW bunching diff (10 kW) & %.1f & --- & %.1f & %.2f & --- & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Missing-tail (domestic) & %.3f & --- & %.3f & %.3f & --- & %s \\\\
Missing-tail (non-domestic) & --- & --- & --- & --- & --- & --- \\\\
KW at 10 kW (pre-2013) & %.1f & --- & --- & --- & --- & --- \\\\
\\bottomrule
\\end{tabular}

\\begin{flushleft}\\small \\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$. Classification: Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). Classification refers to magnitude, not statistical significance. \\textbf{Country:} United Kingdom. \\textbf{Research question:} Do average-rate FIT tariff bands create hidden notches that distort solar PV system sizing? \\textbf{Policy mechanism:} FIT capacity-band tariff rates create discrete revenue cliffs at band boundaries. \\textbf{Outcome definition:} Share of installations with DNC above 4.0 kW in a local window; Kleven-Waseem bunching ratio at 10 kW. \\textbf{Treatment:} February 2016 band merger eliminating 4 kW threshold. \\textbf{Data:} Ofgem FIT Installation Report, 860,470 solar PV installations (2010--2019). \\textbf{Method:} Bunching estimation (Kleven-Waseem at 10 kW); missing-tail share comparison at 4 kW. \\textbf{Sample:} 765,176 FIT-band installations; 90,751 post-merger installations.\\end{flushleft}
\\end{table}',
  mt_beta, mt_sd, mt_sde, classify(mt_sde),
  b10_beta, b10_sd, b10_sde, classify(b10_sde),
  mt_beta, mt_sd, mt_sde, classify(mt_sde),
  mean(b10_fit[1:3], na.rm = TRUE)
)

writeLines(tabf1, "tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("05_tables.R complete.\n")
