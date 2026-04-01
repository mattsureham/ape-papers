## ============================================================================
## 05_tables.R — apep_1256
## Generate all LaTeX tables for the paper
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
muni  <- fread(paste0(data_dir, "muni_characteristics.csv"))
est   <- readRDS(paste0(data_dir, "estimates.rds"))
rob   <- readRDS(paste0(data_dir, "robustness.rds"))

# Reconstruct
panel[, margin_hd := ifelse(high_donor == 1, margin, -margin)]
panel[, treat := as.integer(margin_hd > 0)]

# Cross-section
pre_data <- panel[post == 0, .(
  disc_share_n_pre = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_pre = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_pre      = sum(n_total)
), by = .(codmpio, margin_hd, treat, winner_donor_share)]

post_data <- panel[post == 1, .(
  disc_share_n_post = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_post = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_post      = sum(n_total)
), by = codmpio]

cs_data <- merge(pre_data, post_data, by = "codmpio")
cs_data[, delta_disc_n := disc_share_n_post - disc_share_n_pre]
cs_data[, delta_disc_v := disc_share_v_post - disc_share_v_pre]

## ==========================================================================
## TABLE 1: Summary Statistics
## ==========================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Full sample
full_stats <- panel[, .(
  Variable = c("Discretionary share (count)", "Discretionary share (value)",
               "Total contracts/quarter", "Total value/quarter (M COP)",
               "Vote margin", "Winner donor share", "Winner N donors"),
  Mean = c(mean(disc_share_n, na.rm=T), mean(disc_share_v, na.rm=T),
           mean(n_total), mean(value_total/1e6, na.rm=T),
           mean(abs(margin_hd)), mean(winner_donor_share),
           mean(winner_n_donors)),
  SD = c(sd(disc_share_n, na.rm=T), sd(disc_share_v, na.rm=T),
         sd(n_total), sd(value_total/1e6, na.rm=T),
         sd(abs(margin_hd)), sd(winner_donor_share),
         sd(winner_n_donors)),
  N = c(sum(!is.na(disc_share_n)), sum(!is.na(disc_share_v)),
        .N, .N,
        .N, .N, .N)
)]

# Within ±10pp bandwidth
bw_panel <- panel[abs(margin_hd) <= 0.10]
bw_stats <- bw_panel[, .(
  Mean_BW = c(mean(disc_share_n, na.rm=T), mean(disc_share_v, na.rm=T),
              mean(n_total), mean(value_total/1e6, na.rm=T),
              mean(abs(margin_hd)), mean(winner_donor_share),
              mean(winner_n_donors)),
  N_BW = c(sum(!is.na(disc_share_n)), sum(!is.na(disc_share_v)),
           .N, .N, .N, .N, .N)
)]

tab1 <- cbind(full_stats, bw_stats)

# LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Full Sample} & \\multicolumn{2}{c}{$\\pm$10 pp Bandwidth} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n",
  "Variable & Mean & SD & N & Mean & N \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1)) {
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %.3f & %.3f & %s & %.3f & %s \\\\\n",
    tab1$Variable[i],
    tab1$Mean[i], tab1$SD[i], format(tab1$N[i], big.mark=","),
    tab1$Mean_BW[i], format(tab1$N_BW[i], big.mark=",")
  ))
  if (i == 4) tab1_tex <- paste0(tab1_tex, "\\hline\n")  # separator
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Municipality-quarter panel from SECOP II procurement data, ",
  "matched to 2019 Alcald\\'{i}a election results and Cuentas Claras campaign finance ",
  "disclosures. Discretionary share is the fraction of contracts (or contract value) ",
  "awarded via contrataci\\'{o}n directa or m\\'{i}nima cuant\\'{i}a. ",
  "Vote margin is from the high-donor-funded candidate's perspective. ",
  "Sample covers Q1 2019--Q4 2022 (16 quarters).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, paste0(table_dir, "tab1_summary.tex"))

## ==========================================================================
## TABLE 2: Main Results
## ==========================================================================
cat("=== Generating Table 2: Main Results ===\n")

# Re-run regressions for clean output
bw_opt <- est$rdd_main$bw

# Panel specifications within optimal bandwidth
p_bw <- panel[abs(margin_hd) <= bw_opt]
m1 <- feols(disc_share_n ~ treat:post | codmpio + yq,
            data = p_bw, cluster = ~codmpio)
m2 <- feols(disc_share_v ~ treat:post | codmpio + yq,
            data = p_bw, cluster = ~codmpio)
m3 <- feols(disc_share_n ~ treat:post + I(margin_hd * post) | codmpio + yq,
            data = p_bw, cluster = ~codmpio)

# Wider bandwidth for comparison
p_15 <- panel[abs(margin_hd) <= 0.15]
m4 <- feols(disc_share_n ~ treat:post | codmpio + yq,
            data = p_15, cluster = ~codmpio)

# Continuous treatment
m5 <- feols(disc_share_n ~ winner_donor_share:post | codmpio + yq,
            data = p_bw, cluster = ~codmpio)

# rdrobust cross-section
rdd_cs <- rdrobust(cs_data$delta_disc_n, cs_data$margin_hd, c = 0)

# Build table manually for maximum control
tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Main Results: Donor-Funded Mayors and Discretionary Procurement}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & \\multicolumn{3}{c}{Panel DiD-in-Disc.} & Panel DiD & rdrobust \\\\\n",
  " & $\\Delta$ Count & $\\Delta$ Value & + Margin & BW: $\\pm$15pp & Cross-sec. \\\\\n",
  "\\hline\n"
)

ct1 <- summary(m1)$coeftable; ct2 <- summary(m2)$coeftable
ct3 <- summary(m3)$coeftable; ct4 <- summary(m4)$coeftable

tab2_tex <- paste0(tab2_tex,
  sprintf("Treat $\\times$ Post & %.3f & %.3f & %.3f & %.3f & \\\\\n",
          ct1[1,1], ct2[1,1], ct3[1,1], ct4[1,1]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & \\\\\n",
          ct1[1,2], ct2[1,2], ct3[1,2], ct4[1,2]),
  sprintf("RD Estimate & & & & & %.3f \\\\\n", rdd_cs$coef[1]),
  sprintf(" & & & & & [%.3f] \\\\\n", rdd_cs$se[3]),
  "\\hline\n",
  sprintf("Bandwidth & $\\pm$%.0f pp & $\\pm$%.0f pp & $\\pm$%.0f pp & $\\pm$15 pp & $\\pm$%.0f pp \\\\\n",
          bw_opt*100, bw_opt*100, bw_opt*100, rdd_cs$bws[1,1]*100),
  sprintf("Municipalities & %d & %d & %d & %d & %d \\\\\n",
          uniqueN(p_bw$codmpio), uniqueN(p_bw$codmpio), uniqueN(p_bw$codmpio),
          uniqueN(p_15$codmpio), sum(rdd_cs$N_h)),
  sprintf("Observations & %s & %s & %s & %s & %d \\\\\n",
          format(nobs(m1), big.mark=","), format(nobs(m2), big.mark=","),
          format(nobs(m3), big.mark=","), format(nobs(m4), big.mark=","),
          sum(rdd_cs$N_h)),
  "Municipality FE & Yes & Yes & Yes & Yes & --- \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & --- \\\\\n",
  "Margin control & No & No & Yes & No & Local poly. \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Columns 1--4 report panel difference-in-discontinuity estimates ",
  "with municipality and quarter fixed effects, clustered standard errors in parentheses. ",
  "Column 5 reports local polynomial RDD estimates (\\texttt{rdrobust}, triangular kernel, ",
  "MSE-optimal bandwidth) with robust standard errors in brackets. ",
  "The dependent variable is the municipality-quarter share of contracts awarded via ",
  "discretionary modalities (contrataci\\'{o}n directa and m\\'{i}nima cuant\\'{i}a). ",
  "Treatment is an indicator for the high-donor-funded candidate winning the 2019 mayoral election. ",
  "Bandwidth refers to the vote margin from the high-donor candidate's perspective. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, paste0(table_dir, "tab2_main.tex"))

## ==========================================================================
## TABLE 3: Robustness — Bandwidth Sensitivity
## ==========================================================================
cat("=== Generating Table 3: Bandwidth Sensitivity ===\n")

bw_dt <- rob$bw_sensitivity_panel

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Bandwidth Sensitivity}\n",
  "\\label{tab:bandwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Bandwidth & Treat $\\times$ Post & SE & Municipalities & Obs. \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(bw_dt)) {
  stars <- ifelse(bw_dt$pvalue[i] < 0.01, "$^{***}$",
           ifelse(bw_dt$pvalue[i] < 0.05, "$^{**}$",
           ifelse(bw_dt$pvalue[i] < 0.10, "$^{*}$", "")))
  tab3_tex <- paste0(tab3_tex, sprintf(
    "$\\pm$%.0f pp & %.3f%s & (%.3f) & %d & %s \\\\\n",
    bw_dt$bandwidth[i]*100, bw_dt$coef[i], stars, bw_dt$se[i],
    bw_dt$n_muni[i], format(bw_dt$n_obs[i], big.mark=",")
  ))
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on Treat $\\times$ Post from a ",
  "separate panel DiD-in-discontinuity regression within the specified bandwidth. ",
  "All regressions include municipality and quarter fixed effects. Standard errors ",
  "clustered at the municipality level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, paste0(table_dir, "tab3_bandwidth.tex"))

## ==========================================================================
## TABLE 4: Validity — McCrary, Balance, Placebo
## ==========================================================================
cat("=== Generating Table 4: Validity Tests ===\n")

# Run all tests fresh
mccrary <- rddensity(cs_data$margin_hd, c = 0)
bal_pre_disc <- rdrobust(cs_data$disc_share_n_pre, cs_data$margin_hd, c = 0)
bal_pre_n <- rdrobust(log(cs_data$n_total_pre + 1), cs_data$margin_hd, c = 0)
bal_pre_donor <- rdrobust(cs_data$winner_donor_share, cs_data$margin_hd, c = 0)
placebo_rdd <- rdrobust(cs_data$disc_share_n_pre, cs_data$margin_hd, c = 0)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Validity Tests}\n",
  "\\label{tab:validity}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Estimate & SE & $p$-value \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: McCrary Density Test}} \\\\\n",
  sprintf("Density discontinuity & & & %.3f \\\\\n", mccrary$test$p_jk),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Covariate Balance at Threshold}} \\\\\n",
  sprintf("Pre-period discret. share & %.3f & %.3f & %.3f \\\\\n",
          bal_pre_disc$coef[1], bal_pre_disc$se[3], bal_pre_disc$pv[3]),
  sprintf("Pre-period log(contracts) & %.3f & %.3f & %.3f \\\\\n",
          bal_pre_n$coef[1], bal_pre_n$se[3], bal_pre_n$pv[3]),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo Outcome}} \\\\\n",
  sprintf("Pre-period level (rdrobust) & %.3f & %.3f & %.3f \\\\\n",
          placebo_rdd$coef[1], placebo_rdd$se[3], placebo_rdd$pv[3]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\item \\textit{Notes:} Panel A reports the Cattaneo, Jansson, and Ma (2020) density ",
  "manipulation test at the zero margin threshold ($H_0$: no sorting). Panel B tests for ",
  "discontinuities in predetermined covariates using local polynomial regression ",
  "(\\texttt{rdrobust}, MSE-optimal bandwidth). Panel C uses pre-inauguration procurement ",
  "composition as a placebo outcome.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, paste0(table_dir, "tab4_validity.tex"))

## ==========================================================================
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
## ==========================================================================
cat("=== Generating Table F1: SDE ===\n")

# Main estimate for SDE calculation
main_coef <- summary(m1)$coeftable[1, 1]
main_se   <- summary(m1)$coeftable[1, 2]

# SD(Y) from pre-treatment period within bandwidth
sd_y_pre <- sd(p_bw[post == 0]$disc_share_n, na.rm = TRUE)

# Value-based outcome
value_coef <- summary(m2)$coeftable[1, 1]
value_se   <- summary(m2)$coeftable[1, 2]
sd_y_v_pre <- sd(p_bw[post == 0]$disc_share_v, na.rm = TRUE)

# SDE = beta / SD(Y)
sde_main  <- main_coef / sd_y_pre
sde_se_main <- main_se / sd_y_pre
sde_value <- value_coef / sd_y_v_pre
sde_se_value <- value_se / sd_y_v_pre

classify_sde <- function(s) {
  if (s > 0.15) return("Large positive")
  if (s > 0.05) return("Moderate positive")
  if (s > 0.005) return("Small positive")
  if (s > -0.005) return("Null")
  if (s > -0.05) return("Small negative")
  if (s > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: large vs small municipalities (by pre-period total contracts)
med_n_pre <- median(p_bw[post == 0, .(total = sum(n_total)), by = codmpio]$total, na.rm = TRUE)

het_data <- merge(
  p_bw,
  p_bw[post == 0, .(large_muni = sum(n_total) > med_n_pre), by = codmpio],
  by = "codmpio"
)

# Large municipalities
m_hi <- feols(disc_share_n ~ treat:post | codmpio + yq,
              data = het_data[large_muni == TRUE], cluster = ~codmpio)
ct_hi <- summary(m_hi)$coeftable
sd_hi <- sd(het_data[large_muni == TRUE & post == 0]$disc_share_n, na.rm = TRUE)
sd_hi <- max(sd_hi, 0.001)  # floor to avoid Inf
sde_hi <- ct_hi[1,1] / sd_hi
sde_se_hi <- ct_hi[1,2] / sd_hi

# Small municipalities
m_lo <- feols(disc_share_n ~ treat:post | codmpio + yq,
              data = het_data[large_muni == FALSE], cluster = ~codmpio)
ct_lo <- summary(m_lo)$coeftable
sd_lo <- sd(het_data[large_muni == FALSE & post == 0]$disc_share_n, na.rm = TRUE)
sd_lo <- max(sd_lo, 0.001)  # floor to avoid Inf
sde_lo <- ct_lo[1,1] / sd_lo
sde_se_lo <- ct_lo[1,2] / sd_lo

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Does electing a donor-funded mayor shift municipal procurement from competitive to discretionary modalities? ",
  "\\textbf{Policy mechanism:} Colombian campaign finance allows external donors to fund mayoral candidates; upon taking office, donor-funded mayors may restructure the entire procurement system toward contrataci\\'on directa (direct award without competition) to facilitate patronage and repay supporters. ",
  "\\textbf{Outcome definition:} Municipality-quarter share of procurement contracts awarded via discretionary modalities (contrataci\\'on directa and m\\'inima cuant\\'ia) from SECOP~II. ",
  "\\textbf{Treatment:} Binary; the candidate with higher external donor income share wins the close election. ",
  "\\textbf{Data:} SECOP~II procurement (1.1M territorial contracts), Cuentas Claras campaign finance (26K records), CEDAE election results (8K candidate-municipality records), 2018--2022, municipality-quarter panel; 244 municipalities within CCT-optimal bandwidth. ",
  "\\textbf{Method:} Close-election RDD with difference-in-discontinuity panel; municipality and quarter fixed effects; standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Colombian municipalities with matched election, finance, and procurement data; restricted to close races ($|$margin$| \\leq 10$~pp). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Discret. share (count) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          main_coef, main_se, sd_y_pre, sde_main, sde_se_main, classify_sde(sde_main)),
  sprintf("Discret. share (value) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          value_coef, value_se, sd_y_v_pre, sde_value, sde_se_value, classify_sde(sde_value)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  sprintf("Large municipalities & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          ct_hi[1,1], ct_hi[1,2], sd_hi, sde_hi, sde_se_hi, classify_sde(sde_hi)),
  sprintf("Small municipalities & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          ct_lo[1,1], ct_lo[1,2], sd_lo, sde_lo, sde_se_lo, classify_sde(sde_lo)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, paste0(table_dir, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
cat(sprintf("SDE main: %.3f (%s)\n", sde_main, classify_sde(sde_main)))
cat(sprintf("SDE value: %.3f (%s)\n", sde_value, classify_sde(sde_value)))
cat(sprintf("SD(Y) pre-treatment: %.3f\n", sd_y_pre))
