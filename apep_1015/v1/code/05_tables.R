# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

main <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
dt <- as.data.table(arrow::read_parquet("../data/est_sample_women.parquet"))

# Reconstruct key variables
dt[, mw_x_covered := mw_state * covered_ind]
dt[, native := as.integer(nativity_1910 <= 1)]
dt[, literate := as.integer(lit_1910 == 4)]
dt[, married := as.integer(marst_1910 <= 2)]
dt[, white := as.integer(race_1910 == 1)]
dt[, in_lf_1920 := as.integer(occ1950_1920 > 0 & occ1950_1920 < 979)]
dt[, retention := in_lf_1920]
dt[, same_industry := as.integer(ind1950_1910 == ind1950_1920)]
dt[, occ_change := occscore_1920 - occscore_1910]

dir.create("../tables", showWarnings = FALSE)

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
cat("=== Table 1: Summary Statistics ===\n")

make_row <- function(varname, label, data) {
  x <- data[[varname]]
  sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\",
          label,
          mean(x[data$mw_state == 1 & data$covered_ind == 1], na.rm = TRUE),
          mean(x[data$mw_state == 1 & data$covered_ind == 0], na.rm = TRUE),
          mean(x[data$mw_state == 0 & data$covered_ind == 1], na.rm = TRUE),
          mean(x[data$mw_state == 0 & data$covered_ind == 0], na.rm = TRUE))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Group}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{MW States} & \\multicolumn{2}{c}{Non-MW States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Covered & Exempt & Covered & Exempt \\\\",
  "\\midrule",
  "\\textit{Panel A: 1910 Characteristics} \\\\[3pt]",
  make_row("age_1910", "Age", dt),
  make_row("native", "Native-born", dt),
  make_row("literate", "Literate", dt),
  make_row("married", "Married", dt),
  make_row("white", "White", dt),
  make_row("occscore_1910", "Occupational score", dt),
  "\\midrule",
  "\\textit{Panel B: 1920 Outcomes} \\\\[3pt]",
  make_row("retention", "In labor force", dt),
  make_row("same_industry", "Same industry", dt),
  sprintf("Occ.\\ score change & %.2f & %.2f & %.2f & %.2f \\\\",
          mean(dt[mw_state==1 & covered_ind==1]$occ_change, na.rm=TRUE),
          mean(dt[mw_state==1 & covered_ind==0]$occ_change, na.rm=TRUE),
          mean(dt[mw_state==0 & covered_ind==1]$occ_change, na.rm=TRUE),
          mean(dt[mw_state==0 & covered_ind==0]$occ_change, na.rm=TRUE)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nrow(dt[mw_state==1 & covered_ind==1]), big.mark=","),
          format(nrow(dt[mw_state==1 & covered_ind==0]), big.mark=","),
          format(nrow(dt[mw_state==0 & covered_ind==1]), big.mark=","),
          format(nrow(dt[mw_state==0 & covered_ind==0]), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample consists of women observed in the labor force in the 1910 Census",
  "who are linked to their 1920 Census record via the IPUMS MLP panel. Covered industries",
  "include manufacturing, retail trade, hotels/lodging, eating/drinking, and laundry services.",
  "Exempt industries include agriculture and domestic service. MW states are the 14 states",
  "that enacted women's minimum wage laws between 1912 and 1920.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ===========================================================================
# TABLE 2: Main DDD Results
# ===========================================================================
cat("=== Table 2: Main DDD Results ===\n")

fmt_coef <- function(model, var = "mw_x_covered") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  c(sprintf("%.4f%s", b, stars), sprintf("(%.4f)", s))
}

r1 <- fmt_coef(main$m1_base)
r2 <- fmt_coef(main$m1_ctrl)
r3 <- fmt_coef(main$m2_base)
r4 <- fmt_coef(main$m2_ctrl)
r5 <- fmt_coef(main$m3_base)
r6 <- fmt_coef(main$m3_ctrl)

# WCB p-values
wcb1 <- sprintf("%.3f", main$boot_m1$p_val)
wcb2 <- sprintf("%.3f", main$boot_m2$p_val)
wcb3 <- sprintf("%.3f", main$boot_m3$p_val)

# Dep var means
mean_ret <- sprintf("%.3f", mean(dt$retention, na.rm = TRUE))
mean_ind <- sprintf("%.3f", mean(dt$same_industry, na.rm = TRUE))
mean_occ <- sprintf("%.2f", mean(dt$occ_change, na.rm = TRUE))

N <- format(nrow(dt), big.mark = ",")

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Women's Minimum Wage Laws on Labor Market Trajectories}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Retention} & \\multicolumn{2}{c}{Same Industry} & \\multicolumn{2}{c}{Occ.\\ Score $\\Delta$} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\midrule",
  sprintf("MW $\\times$ Covered & %s & %s & %s & %s & %s & %s \\\\", r1[1], r2[1], r3[1], r4[1], r5[1], r6[1]),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\", r1[2], r2[2], r3[2], r4[2], r5[2], r6[2]),
  sprintf("WCB $p$-value & & %s & & %s & & %s \\\\", wcb1, wcb2, wcb3),
  "\\midrule",
  "Controls & No & Yes & No & Yes & No & Yes \\\\",
  sprintf("Dep.\\ var.\\ mean & %s & %s & %s & %s & %s & %s \\\\", mean_ret, mean_ret, mean_ind, mean_ind, mean_occ, mean_occ),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\", N, N, N, N, N, N),
  "State FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Industry FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the DDD coefficient: MW state $\\times$ covered industry.",
  "State and industry fixed effects absorb the main effects. Controls: age, age$^2$, native-born,",
  "literate, married, white. Standard errors clustered by state in parentheses.",
  "WCB $p$-values from wild cluster bootstrap (Webb weights, 9,999 iterations).",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ===========================================================================
# TABLE 3: Robustness and Placebo Tests
# ===========================================================================
cat("=== Table 3: Robustness ===\n")

rob_placebo_men <- fmt_coef(rob$placebo_men_ret)
rob_placebo_mind <- fmt_coef(rob$placebo_men_ind)
rob_county <- fmt_coef(rob$county_fe)

r_early <- coef(rob$early_late)["early_x_covered"]
se_early <- se(rob$early_late)["early_x_covered"]
r_late <- coef(rob$early_late)["late_x_covered"]
se_late <- se(rob$early_late)["late_x_covered"]

r_wh <- coef(rob$white)["mw_x_covered"]
se_wh <- se(rob$white)["mw_x_covered"]
r_nw <- coef(rob$nonwhite)["mw_x_covered"]
se_nw <- se(rob$nonwhite)["mw_x_covered"]
r_ma <- coef(rob$married)["mw_x_covered"]
se_ma <- se(rob$married)["mw_x_covered"]
r_um <- coef(rob$unmarried)["mw_x_covered"]
se_um <- se(rob$unmarried)["mw_x_covered"]

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccl}",
  "\\toprule",
  "Specification & Coefficient & SE & Notes \\\\",
  "\\midrule",
  "\\textit{Panel A: Placebo (Men)} \\\\[3pt]",
  sprintf("Retention & %s & %s & $N$ = %s \\\\", rob_placebo_men[1], rob_placebo_men[2],
          format(nobs(rob$placebo_men_ret), big.mark=",")),
  sprintf("Same industry & %s & %s & \\\\", rob_placebo_mind[1], rob_placebo_mind[2]),
  "\\midrule",
  "\\textit{Panel B: Alternative FEs} \\\\[3pt]",
  sprintf("County FE & %s & %s & %s counties \\\\", rob_county[1], rob_county[2],
          format(length(unique(as.data.table(arrow::read_parquet("../data/est_sample_women.parquet"))$countyicp_1910)), big.mark=",")),
  "\\midrule",
  "\\textit{Panel C: Adoption Timing} \\\\[3pt]",
  sprintf("Early adopters (1912--13) & %.4f & (%.4f) & 9 states \\\\", r_early, se_early),
  sprintf("Late adopters (1915--20) & %.4f & (%.4f) & 5 states \\\\", r_late, se_late),
  "\\midrule",
  "\\textit{Panel D: Heterogeneity} \\\\[3pt]",
  sprintf("White women & %.4f & (%.4f) & $N$ = %s \\\\", r_wh, se_wh,
          format(nobs(rob$white), big.mark=",")),
  sprintf("Non-white women & %.4f & (%.4f) & $N$ = %s \\\\", r_nw, se_nw,
          format(nobs(rob$nonwhite), big.mark=",")),
  sprintf("Married & %.4f & (%.4f) & $N$ = %s \\\\", r_ma, se_ma,
          format(nobs(rob$married), big.mark=",")),
  sprintf("Unmarried & %.4f & (%.4f) & $N$ = %s \\\\", r_um, se_um,
          format(nobs(rob$unmarried), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications include individual controls (age, age$^2$,",
  "native-born, literate, married, white) and state $\\times$ industry fixed effects",
  "(county $\\times$ industry for Panel B). Standard errors clustered by state.",
  "The men's placebo (Panel A) applies the identical DDD to men in the same covered",
  "vs.\\ exempt industries; laws targeted women only.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_robustness.tex")

# ===========================================================================
# TABLE 4: Leave-One-Out Sensitivity
# ===========================================================================
cat("=== Table 4: Leave-One-Out ===\n")

state_names <- c(
  `4`="Arizona", `5`="Arkansas", `6`="California", `8`="Colorado",
  `20`="Kansas", `25`="Massachusetts", `27`="Minnesota", `31`="Nebraska",
  `38`="North Dakota", `41`="Oregon", `48`="Texas", `49`="Utah",
  `53`="Washington", `55`="Wisconsin"
)

loo <- rob$loo
loo[, state_name := state_names[as.character(dropped)]]

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Leave-One-Out Sensitivity: Dropping Each MW State}",
  "\\label{tab:loo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Dropped State & Coefficient & SE \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(loo))) {
  tab4 <- c(tab4, sprintf("%s & %.4f & (%.4f) \\\\",
                          loo$state_name[i], loo$coef[i], loo$se[i]))
}
tab4 <- c(tab4,
  "\\midrule",
  sprintf("Full sample & %.4f & (%.4f) \\\\",
          coef(main$m1_ctrl)["mw_x_covered"], se(main$m1_ctrl)["mw_x_covered"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each row drops one MW state from the estimation sample.",
  "Dependent variable: labor force retention (in LF in 1920). All specifications",
  "include controls, state FE, and industry FE with standard errors clustered by state.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_loo.tex")

# ===========================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ===========================================================================
cat("=== Table F1: SDE ===\n")

# Compute SDEs
sd_ret <- sd(dt$retention)
sd_ind <- sd(dt$same_industry)
sd_occ <- sd(dt$occ_change)

b_ret <- coef(main$m1_ctrl)["mw_x_covered"]
se_ret <- se(main$m1_ctrl)["mw_x_covered"]
b_ind <- coef(main$m2_ctrl)["mw_x_covered"]
se_ind <- se(main$m2_ctrl)["mw_x_covered"]
b_occ <- coef(main$m3_ctrl)["mw_x_covered"]
se_occ <- se(main$m3_ctrl)["mw_x_covered"]

sde_ret <- b_ret / sd_ret
sde_se_ret <- se_ret / sd_ret
sde_ind <- b_ind / sd_ind
sde_se_ind <- se_ind / sd_ind
sde_occ <- b_occ / sd_occ
sde_se_occ <- se_occ / sd_occ

classify <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneous panel (sample splits)
# White women
b_wh <- coef(rob$white)["mw_x_covered"]
se_wh_val <- se(rob$white)["mw_x_covered"]
sd_ret_wh <- sd(dt[race_1910 == 1]$retention)
sde_wh <- b_wh / sd_ret_wh
sde_se_wh <- se_wh_val / sd_ret_wh

# Non-white women
b_nw <- coef(rob$nonwhite)["mw_x_covered"]
se_nw_val <- se(rob$nonwhite)["mw_x_covered"]
sd_ret_nw <- sd(dt[race_1910 != 1]$retention)
sde_nw <- b_nw / sd_ret_nw
sde_se_nw <- se_nw_val / sd_ret_nw

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the first state-level minimum wage laws for women (1912--1920) affect women's labor force retention, industry persistence, or occupational mobility in covered vs.\\ exempt industries? ",
  "\\textbf{Policy mechanism:} Fourteen states enacted minimum wage laws specifically targeting women workers in manufacturing, retail, laundry, and hospitality, while exempting domestic service and agriculture; these laws set wage floors that raised the cost of employing women in covered sectors relative to exempt sectors. ",
  "\\textbf{Outcome definition:} Primary outcome is labor force retention, a binary indicator equal to one if a woman observed in the labor force in the 1910 Census is also observed in the labor force in the 1920 Census. ",
  "\\textbf{Treatment:} Binary: residence in a state that enacted a women's minimum wage law by 1920, interacted with employment in a covered industry in 1910. ",
  "\\textbf{Data:} IPUMS MLP linked census panel, 1910--1920, 1,609,942 women in the labor force in 1910 in covered or exempt industries, linked across decennial censuses. ",
  "\\textbf{Method:} Triple-difference (state MW status $\\times$ covered industry $\\times$ time) with state and industry fixed effects; standard errors clustered by state; wild cluster bootstrap inference. ",
  "\\textbf{Sample:} Women aged 10+ observed in the labor force in 1910, in manufacturing, retail, hospitality/laundry (covered) or agriculture/domestic service (exempt); linked to 1920 Census via machine learning linkage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the overall ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} \\\\[3pt]",
  sprintf("Retention & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          b_ret, se_ret, sd_ret, sde_ret, sde_se_ret, classify(sde_ret)),
  sprintf("Same industry & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          b_ind, se_ind, sd_ind, sde_ind, sde_se_ind, classify(sde_ind)),
  sprintf("Occ.\\ score $\\Delta$ & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          b_occ, se_occ, sd_occ, sde_occ, sde_se_occ, classify(sde_occ)),
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (Retention)} \\\\[3pt]",
  sprintf("White women & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          b_wh, se_wh_val, sd_ret_wh, sde_wh, sde_se_wh, classify(sde_wh)),
  sprintf("Non-white women & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          b_nw, se_nw_val, sd_ret_nw, sde_nw, sde_se_nw, classify(sde_nw)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat("05_tables.R complete.\n")
