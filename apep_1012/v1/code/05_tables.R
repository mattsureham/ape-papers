# 05_tables.R — Generate all tables
# Ban the Box and the Black Employment Gap (apep_1012)

source("00_packages.R")

df <- fread("../data/analysis_long.csv")
df_wide <- fread("../data/analysis_wide.csv")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
message("Generating Table 1: Summary Statistics")

# Summary by race and treatment status
sum_stats <- df[, .(
  mean_emp = mean(Emp, na.rm = TRUE),
  sd_emp = sd(Emp, na.rm = TRUE),
  mean_hira = mean(HirA, na.rm = TRUE),
  sd_hira = sd(HirA, na.rm = TRUE),
  mean_hirn = mean(HirN, na.rm = TRUE),
  sd_hirn = sd(HirN, na.rm = TRUE),
  mean_emps = mean(EmpS, na.rm = TRUE),
  sd_emps = sd(EmpS, na.rm = TRUE),
  n_counties = uniqueN(county_fips),
  n_obs = .N
), by = .(race_label = fifelse(race == "A1", "White", "Black"),
          group = fifelse(treated_state, "BTB States", "Control States"))]

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: QWI County-Race Panel, 2005--2023}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{BTB States} & \\multicolumn{2}{c}{Control States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & White & Black & White & Black \\\\",
  "\\hline"
)

# Build rows
for (var in c("emp", "hira", "hirn", "emps")) {
  var_label <- switch(var,
    emp = "Employment",
    hira = "All Hires",
    hirn = "New Hires",
    emps = "FQ Employment"
  )
  means <- sum_stats[, get(paste0("mean_", var))]
  sds <- sum_stats[, get(paste0("sd_", var))]

  # Order: BTB-White, BTB-Black, Control-White, Control-Black
  idx_bw <- which(sum_stats$group == "BTB States" & sum_stats$race_label == "White")
  idx_bb <- which(sum_stats$group == "BTB States" & sum_stats$race_label == "Black")
  idx_cw <- which(sum_stats$group == "Control States" & sum_stats$race_label == "White")
  idx_cb <- which(sum_stats$group == "Control States" & sum_stats$race_label == "Black")

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.0f & %.0f & %.0f & %.0f \\\\", var_label,
            means[idx_bw], means[idx_bb], means[idx_cw], means[idx_cb]),
    sprintf(" & (%.0f) & (%.0f) & (%.0f) & (%.0f) \\\\",
            sds[idx_bw], sds[idx_bb], sds[idx_cw], sds[idx_cb])
  )
}

# Add county counts and observations
idx_bw <- which(sum_stats$group == "BTB States" & sum_stats$race_label == "White")
idx_cw <- which(sum_stats$group == "Control States" & sum_stats$race_label == "White")

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Counties & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(sum_stats$n_counties[idx_bw], big.mark = ","),
          format(sum_stats$n_counties[idx_cw], big.mark = ",")),
  sprintf("County-quarter-race obs. & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(sum(sum_stats[group == "BTB States"]$n_obs), big.mark = ","),
          format(sum(sum_stats[group == "Control States"]$n_obs), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Mean employment levels (standard deviations in parentheses) from the QWI county$\\times$race panel, 2005--2023. BTB states adopted private-employer Ban-the-Box laws between 2010 and 2020. Employment is measured as beginning-of-quarter employment. FQ Employment is full-quarter (stable) employment.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Triple-Difference Results
# ============================================================
message("Generating Table 2: Main Results")

# Re-estimate models to have them in environment
m1_emp <- feols(ln_emp ~ post_btb:black + post_btb + black | county_fips + time_id,
                data = df, cluster = ~state_fips)
m1_hira <- feols(ln_hira ~ post_btb:black + post_btb + black | county_fips + time_id,
                 data = df, cluster = ~state_fips)
m1_hirn <- feols(ln_hirn ~ post_btb:black + post_btb + black | county_fips + time_id,
                 data = df, cluster = ~state_fips)
m1_emps <- feols(ln_emps ~ post_btb:black + post_btb + black | county_fips + time_id,
                 data = df, cluster = ~state_fips)

# Store key coefficients
coef_emp <- coef(m1_emp)["post_btb:black"]
se_emp <- se(m1_emp)["post_btb:black"]
coef_hira <- coef(m1_hira)["post_btb:black"]
se_hira <- se(m1_hira)["post_btb:black"]
coef_hirn <- coef(m1_hirn)["post_btb:black"]
se_hirn <- se(m1_hirn)["post_btb:black"]
coef_emps <- coef(m1_emps)["post_btb:black"]
se_emps <- se(m1_emps)["post_btb:black"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

p_emp <- pvalue(m1_emp)["post_btb:black"]
p_hira <- pvalue(m1_hira)["post_btb:black"]
p_hirn <- pvalue(m1_hirn)["post_btb:black"]
p_emps <- pvalue(m1_emps)["post_btb:black"]

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Ban-the-Box on Black Employment: Triple-Difference Estimates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & ln(Emp) & ln(All Hires) & ln(New Hires) & ln(FQ Emp) \\\\",
  "\\hline",
  sprintf("BTB $\\times$ Post $\\times$ Black & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
          coef_emp, stars(p_emp), coef_hira, stars(p_hira),
          coef_hirn, stars(p_hirn), coef_emps, stars(p_emps)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
          se_emp, se_hira, se_hirn, se_emps),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1_emp), big.mark = ","),
          format(nobs(m1_hira), big.mark = ","),
          format(nobs(m1_hirn), big.mark = ","),
          format(nobs(m1_emps), big.mark = ",")),
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Clusters (states) & %d & %d & %d & %d \\\\",
          length(unique(df$state_fips)), length(unique(df$state_fips)),
          length(unique(df$state_fips)), length(unique(df$state_fips))),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient ($\\hat{\\delta}$) from the specification: $\\ln Y_{crt} = \\alpha_c + \\gamma_t + \\delta(\\text{BTB}_s \\times \\text{Post}_{st} \\times \\text{Black}_r) + \\beta(\\text{BTB}_s \\times \\text{Post}_{st}) + \\mu(\\text{Post}_{st} \\times \\text{Black}_r) + \\varepsilon_{crt}$. Unit of observation is county$\\times$race$\\times$quarter. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================
# Table 3: CS-DiD Results (staggered-robust)
# ============================================================
message("Generating Table 3: CS-DiD Results")

cs_rows <- list()
if (!is.null(results$cs_black_emp)) {
  cs_rows$black_emp <- results$cs_black_emp
}
if (!is.null(results$cs_white_emp)) {
  cs_rows$white_emp <- results$cs_white_emp
}
if (!is.null(results$cs_black_hirn)) {
  cs_rows$black_hirn <- results$cs_black_hirn
}
if (!is.null(results$cs_black_emps)) {
  cs_rows$black_emps <- results$cs_black_emps
}

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Callaway-Sant'Anna Staggered DiD Estimates}",
  "\\label{tab:csdid}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & ATT & SE \\\\",
  "\\hline",
  "\\textit{Panel A: Black Workers} & & \\\\"
)

if (!is.null(cs_rows$black_emp)) {
  p_val <- 2 * pnorm(-abs(cs_rows$black_emp$att / cs_rows$black_emp$se))
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad Employment & %.4f%s & (%.4f) \\\\",
            cs_rows$black_emp$att, stars(p_val), cs_rows$black_emp$se))
}
if (!is.null(cs_rows$black_hirn)) {
  p_val <- 2 * pnorm(-abs(cs_rows$black_hirn$att / cs_rows$black_hirn$se))
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad New Hires & %.4f%s & (%.4f) \\\\",
            cs_rows$black_hirn$att, stars(p_val), cs_rows$black_hirn$se))
}
if (!is.null(cs_rows$black_emps)) {
  p_val <- 2 * pnorm(-abs(cs_rows$black_emps$att / cs_rows$black_emps$se))
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad Full-Quarter Employment & %.4f%s & (%.4f) \\\\",
            cs_rows$black_emps$att, stars(p_val), cs_rows$black_emps$se))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  "\\textit{Panel B: White Workers (Placebo)} & & \\\\"
)

if (!is.null(cs_rows$white_emp)) {
  p_val <- 2 * pnorm(-abs(cs_rows$white_emp$att / cs_rows$white_emp$se))
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad Employment & %.4f%s & (%.4f) \\\\",
            cs_rows$white_emp$att, stars(p_val), cs_rows$white_emp$se))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATT estimates aggregated to a simple weighted average. Panel A shows effects on Black workers in BTB states relative to never-treated states. Panel B shows the corresponding estimates for White workers as a placebo test. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_csdid.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
message("Generating Table 4: Robustness")

loo <- rob_results$loo

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Coefficient & SE \\\\",
  "\\hline",
  sprintf("Baseline & %.4f & (%.4f) \\\\", coef_emp, se_emp),
  sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{2}{c}{%.3f} \\\\",
          ifelse(is.na(rob_results$wcb_pval), 99, rob_results$wcb_pval)),
  sprintf("Public-sector BTB placebo & %.4f & (%.4f) \\\\",
          rob_results$placebo_coef, rob_results$placebo_se),
  "\\hline",
  "\\textit{Leave-one-out (drop state):} & & \\\\"
)

for (i in 1:nrow(loo)) {
  p_val_loo <- 2 * pnorm(-abs(loo$coef[i] / loo$se[i]))
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Drop %s & %.4f%s & (%.4f) \\\\",
            loo$dropped_state[i], loo$coef[i], stars(p_val_loo), loo$se[i]))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All specifications include county and quarter fixed effects with standard errors clustered at the state level. The baseline is the triple-difference estimate from Table \\ref{tab:main}, column (1). Wild cluster bootstrap uses the Webb (2023) six-point distribution with 999 iterations. The public-sector BTB placebo applies a pseudo-treatment at 2016 Q1 to states with only public-employer BTB laws, excluding all private-employer BTB states.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — Appendix
# ============================================================
message("Generating Table F1: SDE Appendix")

# Compute SDEs
pre_sd <- df[treated_state == TRUE & post_btb == 0, .(
  sd_emp = sd(ln_emp, na.rm = TRUE),
  sd_hira = sd(ln_hira, na.rm = TRUE),
  sd_hirn = sd(ln_hirn, na.rm = TRUE),
  sd_emps = sd(ln_emps, na.rm = TRUE)
)]

# SDE = beta / SD(Y)
sde_emp <- coef_emp / pre_sd$sd_emp
sde_hira <- coef_hira / pre_sd$sd_hira
sde_hirn <- coef_hirn / pre_sd$sd_hirn
sde_emps <- coef_emps / pre_sd$sd_emps

se_sde_emp <- se_emp / pre_sd$sd_emp
se_sde_hira <- se_hira / pre_sd$sd_hira
se_sde_hirn <- se_hirn / pre_sd$sd_hirn
se_sde_emps <- se_emps / pre_sd$sd_emps

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do private-employer Ban-the-Box laws, which prohibit criminal history inquiries on job applications, affect the Black-White employment gap through statistical discrimination? ",
  "\\textbf{Policy mechanism:} BTB laws remove the criminal history checkbox from initial job applications, forcing employers to defer background checks to later stages; when individual screening is delayed, employers may substitute group-level statistical discrimination using race as a proxy for unobserved criminal history. ",
  "\\textbf{Outcome definition:} Log county-level quarterly employment, all hires, new hires, and full-quarter (stable) employment from the QWI, separately by race (Black vs.\\ White). ",
  "\\textbf{Treatment:} Binary; state adoption of a private-employer Ban-the-Box law (16 states, 2010--2020). ",
  "\\textbf{Data:} Quarterly Workforce Indicators (QWI) county$\\times$race panel, 2005--2023, covering all 50 states plus DC; approximately ",
  format(nrow(df), big.mark = ","), " county-race-quarter observations. ",
  "\\textbf{Method:} TWFE triple-difference (BTB state $\\times$ post $\\times$ Black) with county and quarter fixed effects; standard errors clustered at the state level; Callaway-Sant'Anna staggered DiD as robustness. ",
  "\\textbf{Sample:} Counties with non-suppressed Black and White employment cells in at least 80\\% of quarters; excludes counties with sparse minority populations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome in treated states. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build heterogeneity panel: split by county Black population share
# High Black share vs Low Black share counties
df_pre <- df[treated_state == TRUE & post_btb == 0 & race == "A2"]
county_black_emp <- df_pre[, .(mean_black_emp = mean(Emp, na.rm = TRUE)), by = county_fips]
median_be <- median(county_black_emp$mean_black_emp, na.rm = TRUE)

high_black <- county_black_emp[mean_black_emp >= median_be]$county_fips
low_black <- county_black_emp[mean_black_emp < median_be]$county_fips

m_high <- feols(ln_emp ~ post_btb:black + post_btb + black | county_fips + time_id,
                data = df[county_fips %in% high_black], cluster = ~state_fips)
m_low <- feols(ln_emp ~ post_btb:black + post_btb + black | county_fips + time_id,
               data = df[county_fips %in% low_black], cluster = ~state_fips)

coef_high <- coef(m_high)["post_btb:black"]
se_high <- se(m_high)["post_btb:black"]
coef_low <- coef(m_low)["post_btb:black"]
se_low <- se(m_low)["post_btb:black"]

sde_high <- coef_high / pre_sd$sd_emp
sde_low <- coef_low / pre_sd$sd_emp
se_sde_high <- se_high / pre_sd$sd_emp
se_sde_low <- se_low / pre_sd$sd_emp

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Employment & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_emp, se_emp, pre_sd$sd_emp, sde_emp, se_sde_emp, classify_sde(sde_emp)),
  sprintf("All Hires & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_hira, se_hira, pre_sd$sd_hira, sde_hira, se_sde_hira, classify_sde(sde_hira)),
  sprintf("New Hires & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_hirn, se_hirn, pre_sd$sd_hirn, sde_hirn, se_sde_hirn, classify_sde(sde_hirn)),
  sprintf("FQ Employment & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_emps, se_emps, pre_sd$sd_emps, sde_emps, se_sde_emps, classify_sde(sde_emps)),
  "\\hline",
  "\\textit{Panel B: Heterogeneous (Employment)} & & & & & & \\\\",
  sprintf("High Black pop.\\ counties & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_high, se_high, pre_sd$sd_emp, sde_high, se_sde_high, classify_sde(sde_high)),
  sprintf("Low Black pop.\\ counties & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          coef_low, se_low, pre_sd$sd_emp, sde_low, se_sde_low, classify_sde(sde_low)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

message("All tables generated successfully.")
