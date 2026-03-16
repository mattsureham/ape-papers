# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
women <- readRDS("../data/analysis_sample.rds")
setDT(women)

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics\n")

# Build summary by group
all_stats <- women[, .(
  N = format(.N, big.mark = ","),
  LFP_1920 = sprintf("%.3f", mean(lfp_1920)),
  LFP_1930 = sprintf("%.3f", mean(lfp_1930)),
  D_LFP = sprintf("%.3f", mean(d_lfp)),
  Domestic_1920 = sprintf("%.3f", mean(domestic_1920)),
  Age = sprintf("%.1f", mean(age_1920)),
  Literate = sprintf("%.3f", mean(lit_1920 == 4, na.rm = TRUE)),
  Farm = sprintf("%.3f", mean(farm_1920 == 2)),
  NChild = sprintf("%.2f", mean(nchild_1920)),
  Exposure = sprintf("%.4f", mean(exposure))
)]

married_stats <- women[married_1920 == 1, .(
  N = format(.N, big.mark = ","),
  LFP_1920 = sprintf("%.3f", mean(lfp_1920)),
  LFP_1930 = sprintf("%.3f", mean(lfp_1930)),
  D_LFP = sprintf("%.3f", mean(d_lfp)),
  Domestic_1920 = sprintf("%.3f", mean(domestic_1920)),
  Age = sprintf("%.1f", mean(age_1920)),
  Literate = sprintf("%.3f", mean(lit_1920 == 4, na.rm = TRUE)),
  Farm = sprintf("%.3f", mean(farm_1920 == 2)),
  NChild = sprintf("%.2f", mean(nchild_1920)),
  Exposure = sprintf("%.4f", mean(exposure))
)]

unmarried_stats <- women[married_1920 == 0, .(
  N = format(.N, big.mark = ","),
  LFP_1920 = sprintf("%.3f", mean(lfp_1920)),
  LFP_1930 = sprintf("%.3f", mean(lfp_1930)),
  D_LFP = sprintf("%.3f", mean(d_lfp)),
  Domestic_1920 = sprintf("%.3f", mean(domestic_1920)),
  Age = sprintf("%.1f", mean(age_1920)),
  Literate = sprintf("%.3f", mean(lit_1920 == 4, na.rm = TRUE)),
  Farm = sprintf("%.3f", mean(farm_1920 == 2)),
  NChild = sprintf("%.2f", mean(nchild_1920)),
  Exposure = sprintf("%.4f", mean(exposure))
)]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Native-Born White Women, 1920--1930 Linked Panel}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & All & Married & Unmarried \\\\",
  "\\hline",
  paste0("Observations & ", all_stats$N, " & ", married_stats$N, " & ", unmarried_stats$N, " \\\\"),
  paste0("LFP rate, 1920 & ", all_stats$LFP_1920, " & ", married_stats$LFP_1920, " & ", unmarried_stats$LFP_1920, " \\\\"),
  paste0("LFP rate, 1930 & ", all_stats$LFP_1930, " & ", married_stats$LFP_1930, " & ", unmarried_stats$LFP_1930, " \\\\"),
  paste0("$\\Delta$ LFP & ", all_stats$D_LFP, " & ", married_stats$D_LFP, " & ", unmarried_stats$D_LFP, " \\\\"),
  paste0("In domestic service, 1920 & ", all_stats$Domestic_1920, " & ", married_stats$Domestic_1920, " & ", unmarried_stats$Domestic_1920, " \\\\"),
  paste0("Age in 1920 & ", all_stats$Age, " & ", married_stats$Age, " & ", unmarried_stats$Age, " \\\\"),
  paste0("Literate & ", all_stats$Literate, " & ", married_stats$Literate, " & ", unmarried_stats$Literate, " \\\\"),
  paste0("Farm resident & ", all_stats$Farm, " & ", married_stats$Farm, " & ", unmarried_stats$Farm, " \\\\"),
  paste0("Number of children & ", all_stats$NChild, " & ", married_stats$NChild, " & ", unmarried_stats$NChild, " \\\\"),
  paste0("County S/E European share & ", all_stats$Exposure, " & ", married_stats$Exposure, " & ", unmarried_stats$Exposure, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample consists of native-born white women aged 18--55 in 1920, linked to 1930 census via IPUMS MLP. LFP defined as reporting an occupation (OCCSCORE $> 0$). County S/E European share is the fraction of linked individuals in the county who are foreign-born from Southern/Eastern European countries in 1920.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# --------------------------------------------------------------------------
# Table 2: Main Results
# --------------------------------------------------------------------------
cat("Generating Table 2: Main Results\n")

# Helper to format coefficients
fmt_coef <- function(model, var = "exposure_std") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- fixest::pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(
    coef = sprintf("%.4f%s", b, stars),
    se = sprintf("(%.4f)", s),
    b = b, s = s, p = p
  )
}

r1 <- fmt_coef(results$m1); r2 <- fmt_coef(results$m2)
r3 <- fmt_coef(results$m3); r4 <- fmt_coef(results$m4)
r5 <- fmt_coef(results$m5); r6 <- fmt_coef(results$m6)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Immigration Restriction and Women's Labor Force Participation, 1920--1930}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{All Women} & \\multicolumn{2}{c}{Married} & \\multicolumn{2}{c}{Unmarried} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline",
  paste0("Exposure (std.) & ", r1$coef, " & ", r2$coef, " & ", r3$coef, " & ", r4$coef, " & ", r5$coef, " & ", r6$coef, " \\\\"),
  paste0(" & ", r1$se, " & ", r2$se, " & ", r3$se, " & ", r4$se, " & ", r5$se, " & ", r6$se, " \\\\"),
  "\\hline",
  paste0("Controls & No & Yes & No & Yes & No & Yes \\\\"),
  paste0("State FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\"),
  paste0("Observations & ", format(results$n_women, big.mark=","), " & ", format(results$n_women, big.mark=","),
         " & ", format(results$n_married, big.mark=","), " & ", format(results$n_married, big.mark=","),
         " & ", format(results$n_unmarried, big.mark=","), " & ", format(results$n_unmarried, big.mark=","), " \\\\"),
  paste0("Clusters & ", results$n_counties, " & ", results$n_counties,
         " & ", results$n_counties, " & ", results$n_counties,
         " & ", results$n_counties, " & ", results$n_counties, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is the change in LFP ($\\Delta$LFP $= \\mathbf{1}$[OCCSCORE$_{1930} > 0$] $-$ $\\mathbf{1}$[OCCSCORE$_{1920} > 0$]). Exposure is the standardized county share of S/E European immigrants in 1920. Controls include age, age$^2$, literacy, farm status, and number of children. Standard errors clustered at the county level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# --------------------------------------------------------------------------
# Table 3: Mechanism — Domestic Service
# --------------------------------------------------------------------------
cat("Generating Table 3: Mechanism\n")

m1 <- fmt_coef(results$d1); m2 <- fmt_coef(results$d2)
m3 <- fmt_coef(results$d3); m4 <- fmt_coef(results$d4)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Mechanism: Domestic Service Employment and Occupational Upgrading}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{$\\Delta$ Domestic Service} & $\\Delta$ Occ. Score \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5}",
  " & All & Married & Unmarried & Ever Employed \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  paste0("Exposure (std.) & ", m1$coef, " & ", m2$coef, " & ", m3$coef, " & ", m4$coef, " \\\\"),
  paste0(" & ", m1$se, " & ", m2$se, " & ", m3$se, " & ", m4$se, " \\\\"),
  "\\hline",
  "Controls & Yes & Yes & Yes & Yes \\\\",
  "State FE & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ", format(results$n_women, big.mark=","),
         " & ", format(results$n_married, big.mark=","),
         " & ", format(results$n_unmarried, big.mark=","),
         " & ", format(sum(women$lfp_1920 == 1 | women$lfp_1930 == 1), big.mark=","), " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns 1--3: dependent variable is $\\Delta$ domestic service ($= \\mathbf{1}$[domestic$_{1930}$] $-$ $\\mathbf{1}$[domestic$_{1920}$]). Column 4: dependent variable is $\\Delta$ OCCSCORE among women employed in either 1920 or 1930. Domestic service includes OCC1950 codes 820--822, 825 (housekeepers, laundresses, servants in private households). All specifications include controls and state fixed effects. Standard errors clustered at county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_mechanism.tex")

# --------------------------------------------------------------------------
# Table 4: Robustness — Placebo, Non-Movers, Urban/Rural
# --------------------------------------------------------------------------
cat("Generating Table 4: Robustness\n")

rp1 <- fmt_coef(rob$placebo_all); rp2 <- fmt_coef(rob$placebo_married); rp3 <- fmt_coef(rob$placebo_unmarried)
rn1 <- fmt_coef(rob$nonmover_all); rn2 <- fmt_coef(rob$nonmover_married)
ru1 <- fmt_coef(rob$urban_married); ru2 <- fmt_coef(rob$rural_married)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Placebo, Non-Movers, and Urban/Rural Heterogeneity}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Placebo: 1910--1920} & \\multicolumn{2}{c}{Non-Movers} & \\multicolumn{2}{c}{Urban/Rural} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  " & All & Married & Unmarr. & All & Married & Urban M. & Rural M. \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\\\",
  "\\hline",
  paste0("Exposure (std.) & ", rp1$coef, " & ", rp2$coef, " & ", rp3$coef,
         " & ", rn1$coef, " & ", rn2$coef, " & ", ru1$coef, " & ", ru2$coef, " \\\\"),
  paste0(" & ", rp1$se, " & ", rp2$se, " & ", rp3$se,
         " & ", rn1$se, " & ", rn2$se, " & ", ru1$se, " & ", ru2$se, " \\\\"),
  "\\hline",
  "Controls & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "State FE & Yes & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Columns 1--3: placebo test using the 1910--1920 linked panel (pre-Johnson-Reed Act). If exposure predicts LFP changes before the Act, the identification strategy fails. ",
         "Columns 4--5: restrict to women who remained in the same county between 1920 and 1930 (mover $= 0$). ",
         "Columns 6--7: married women split by urban (non-farm) vs.~rural (farm) residence in 1920. ",
         "All specifications include individual controls and state fixed effects. Standard errors clustered at county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# --------------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE) — Appendix
# --------------------------------------------------------------------------
cat("Generating Table F1: SDE\n")

# Compute SDE for main outcomes
compute_sde <- function(model, var = "exposure_std", sd_y) {
  b <- coef(model)[var]
  se_b <- se(model)[var]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  classify <- function(x) {
    if (x < -0.15) "Large negative"
    else if (x < -0.05) "Moderate negative"
    else if (x < -0.005) "Small negative"
    else if (x <= 0.005) "Null"
    else if (x <= 0.05) "Small positive"
    else if (x <= 0.15) "Moderate positive"
    else "Large positive"
  }
  list(b = b, se = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde,
       class = classify(sde))
}

sde_all <- compute_sde(results$m2, sd_y = results$sd_y)
sde_married <- compute_sde(results$m4, sd_y = results$sd_y_married)
sde_unmarried <- compute_sde(results$m6, sd_y = results$sd_y_unmarried)
sde_domestic <- compute_sde(results$d1, sd_y = sd(women$d_domestic))
sde_dom_unmarried <- compute_sde(results$d3, sd_y = sd(women[married_1920 == 0]$d_domestic))

sde_list <- list(sde_all, sde_married, sde_unmarried, sde_domestic, sde_dom_unmarried)
outcomes <- c("$\\Delta$ LFP (all women)", "$\\Delta$ LFP (married)", "$\\Delta$ LFP (unmarried)",
              "$\\Delta$ domestic service (all)", "$\\Delta$ domestic service (unmarried)")

# Build notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 1924 Johnson-Reed Act --- which cut Southern/Eastern European immigration by 87\\% --- affect native-born white women's labor force participation through the domestic servant supply channel? ",
  "\\textbf{Policy mechanism:} The Act imposed national-origin quotas at 2\\% of 1890 foreign-born stock, disproportionately restricting immigration from Italy, Poland, Russia, and Austria-Hungary. These countries supplied a large share of domestic servants in US cities, so the quotas created a sudden scarcity of hired household labor in high-immigration counties. ",
  "\\textbf{Outcome definition:} Change in labor force participation (LFP $= \\mathbf{1}$[OCCSCORE $> 0$]) between 1920 and 1930 census for the same individual. ",
  "\\textbf{Treatment:} Continuous --- county-level share of S/E European foreign-born in 1920, standardized (mean zero, unit SD). ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP) linked 1920--1930 census, ", format(results$n_women, big.mark = ","), " native-born white women aged 18--55. ",
  "\\textbf{Method:} Individual-level Bartik DiD with state fixed effects and individual controls; standard errors clustered at county level (", results$n_counties, " clusters). ",
  "\\textbf{Sample:} Restricted to native-born white women aged 18--55 in 1920, successfully linked to 1930 census. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of $\\Delta$LFP. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- sapply(seq_along(sde_list), function(i) {
  s <- sde_list[[i]]
  paste0(outcomes[i], " & ", sprintf("%.4f", s$b), " & ", sprintf("%.4f", s$se),
         " & ", sprintf("%.3f", s$sd_y), " & ", sprintf("%.4f", s$sde),
         " & ", sprintf("%.4f", s$se_sde), " & ", s$class, " \\\\")
})

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sde_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
