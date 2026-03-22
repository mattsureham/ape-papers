# ============================================================
# 05_tables.R — Generate all LaTeX tables
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
ddd_emp <- readRDS(file.path(data_dir, "ddd_emp.rds"))
ddd_sep <- readRDS(file.path(data_dir, "ddd_sep.rds"))
ddd_earn <- readRDS(file.path(data_dir, "ddd_earn.rds"))
ddd_emp_level <- readRDS(file.path(data_dir, "ddd_emp_level.rds"))
ddd_hir <- readRDS(file.path(data_dir, "ddd_hir.rds"))
twfe_white <- readRDS(file.path(data_dir, "twfe_white_emp.rds"))
twfe_black <- readRDS(file.path(data_dir, "twfe_black_emp.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

fmt_coef <- function(est, se, digits = 3) {
  pval <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(pval < 0.01, "***",
           ifelse(pval < 0.05, "**",
           ifelse(pval < 0.10, "*", "")))
  paste0(formatC(est, digits = digits, format = "f"), stars)
}
fmt_se <- function(se, digits = 3) {
  paste0("(", formatC(se, digits = digits, format = "f"), ")")
}

# ===========================================================
# TABLE 1: Summary Statistics
# ===========================================================
cat("=== Table 1 ===\n")

pre <- panel[panel$first_treat == 0 | panel$time_id < panel$first_treat]
pre_w <- pre[race_label == "white"]
pre_b <- pre[race_label == "black"]

tab1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Summary Statistics: Food Retail Employment by Race, Pre-Treatment}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & \\multicolumn{2}{c}{White} & \\multicolumn{2}{c}{Black} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\", "\\midrule",
  paste0("Employment & ", round(mean(pre_w$Emp, na.rm=T), 1), " & ",
         round(sd(pre_w$Emp, na.rm=T), 1), " & ",
         round(mean(pre_b$Emp, na.rm=T), 1), " & ",
         round(sd(pre_b$Emp, na.rm=T), 1), " \\\\"),
  paste0("Separation rate & ", round(mean(pre_w$sep_rate, na.rm=T), 3), " & ",
         round(sd(pre_w$sep_rate, na.rm=T), 3), " & ",
         round(mean(pre_b$sep_rate, na.rm=T), 3), " & ",
         round(sd(pre_b$sep_rate, na.rm=T), 3), " \\\\"),
  paste0("All-worker hires & ", round(mean(pre_w$HirA, na.rm=T), 1), " & ",
         round(sd(pre_w$HirA, na.rm=T), 1), " & ",
         round(mean(pre_b$HirA, na.rm=T), 1), " & ",
         round(sd(pre_b$HirA, na.rm=T), 1), " \\\\"),
  paste0("Log earnings & ", round(mean(pre_w$ln_earn, na.rm=T), 2), " & ",
         round(sd(pre_w$ln_earn, na.rm=T), 2), " & ",
         round(mean(pre_b$ln_earn, na.rm=T), 2), " & ",
         round(sd(pre_b$ln_earn, na.rm=T), 2), " \\\\"),
  "\\addlinespace",
  paste0("County-quarter obs & \\multicolumn{2}{c}{",
         format(nrow(pre_w), big.mark = ","), "} & \\multicolumn{2}{c}{",
         format(nrow(pre_b), big.mark = ","), "} \\\\"),
  paste0("Counties & \\multicolumn{2}{c}{", length(unique(pre_w$county_fips)),
         "} & \\multicolumn{2}{c}{", length(unique(pre_b$county_fips)), "} \\\\"),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment statistics for NAICS 445 (Food \\& Beverage Stores).",
  "QWI data from Census LEHD, 2010--2024. Employment is beginning-of-quarter count.",
  "Separation rate is quarterly separations divided by employment.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab1, file.path(table_dir, "tab1_sumstats.tex"))

# ===========================================================
# TABLE 2: Main Race DDD Results
# ===========================================================
cat("=== Table 2 ===\n")

get_est <- function(model, var) {
  est <- coef(model)[var]
  se <- sqrt(vcov(model)[var, var])
  list(est = est, se = se)
}

r1 <- get_est(ddd_emp, "treated:black")
r2 <- get_est(ddd_sep, "treated:black")
r3 <- get_est(ddd_earn, "treated:black")
r4 <- get_est(ddd_hir, "treated:black")

# Also get the "treated" coefficient (White effect)
w1 <- get_est(ddd_emp, "treated")
w2 <- get_est(ddd_sep, "treated")
w3 <- get_est(ddd_earn, "treated")
w4 <- get_est(ddd_hir, "treated")

tab2 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Effect of Supermarket Exit on Food Retail Employment by Race}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Emp & Sep.~Rate & Log Earn & Hires \\\\",
  "\\midrule",
  "\\textbf{Panel A: White (baseline)} & & & & \\\\",
  paste0("SM Exit & ", fmt_coef(w1$est, w1$se), " & ",
         fmt_coef(w2$est, w2$se), " & ",
         fmt_coef(w3$est, w3$se), " & ",
         fmt_coef(w4$est, w4$se), " \\\\"),
  paste0(" & ", fmt_se(w1$se), " & ", fmt_se(w2$se), " & ",
         fmt_se(w3$se), " & ", fmt_se(w4$se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Panel B: Black differential} & & & & \\\\",
  paste0("SM Exit $\\times$ Black & ", fmt_coef(r1$est, r1$se), " & ",
         fmt_coef(r2$est, r2$se), " & ",
         fmt_coef(r3$est, r3$se), " & ",
         fmt_coef(r4$est, r4$se), " \\\\"),
  paste0(" & ", fmt_se(r1$se), " & ", fmt_se(r2$se), " & ",
         fmt_se(r3$se), " & ", fmt_se(r4$se), " \\\\"),
  "\\addlinespace",
  "\\midrule",
  paste0("Observations & ", format(nobs(ddd_emp), big.mark = ","), " & ",
         format(nobs(ddd_sep), big.mark = ","), " & ",
         format(nobs(ddd_earn), big.mark = ","), " & ",
         format(nobs(ddd_hir), big.mark = ","), " \\\\"),
  "Counties & 3,011 & 3,008 & 3,132 & 3,135 \\\\",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Race FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & County & County & County & County \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Race triple-difference estimates. Panel A shows the effect on White",
  "workers (baseline). Panel B shows the additional differential effect on Black workers.",
  "Treatment: county experiences $\\geq$1 SNAP supermarket exit. Outcomes from QWI NAICS 445.",
  "Standard errors clustered at county level in parentheses.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

# ===========================================================
# TABLE 3: Race-specific TWFE
# ===========================================================
cat("=== Table 3 ===\n")

tw <- get_est(twfe_white, "treated")
tb <- get_est(twfe_black, "treated")

tab3 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Race-Specific Effects of Supermarket Exit on Log Employment}",
  "\\label{tab:race_specific}",
  "\\begin{tabular}{lcc}", "\\toprule",
  " & (1) White & (2) Black \\\\", "\\midrule",
  paste0("SM Exit & ", fmt_coef(tw$est, tw$se), " & ",
         fmt_coef(tb$est, tb$se), " \\\\"),
  paste0(" & ", fmt_se(tw$se), " & ", fmt_se(tb$se), " \\\\"),
  "\\addlinespace",
  paste0("Observations & ", format(nobs(twfe_white), big.mark = ","), " & ",
         format(nobs(twfe_black), big.mark = ","), " \\\\"),
  "County FE & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes \\\\",
  "Clustering & County & County \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Separate TWFE regressions for White and Black food retail employment.",
  "Both races experience employment declines, but the Black sample yields a smaller coefficient",
  "because it is estimated on a different set of counties (those with Black NAICS 445 employment).",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab3, file.path(table_dir, "tab3_race_specific.tex"))

# ===========================================================
# TABLE 4: Robustness
# ===========================================================
cat("=== Table 4 ===\n")

rh <- get_est(robustness$ddd_high, "treated:black")
rl <- get_est(robustness$ddd_low, "treated:black")
rs <- get_est(robustness$ddd_state_cluster, "treated:black")

# Main result for comparison
rm <- get_est(ddd_sep, "treated:black")

tab4 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Robustness: Separation Rate Race Differential}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}", "\\toprule",
  " & Estimate & SE \\\\", "\\midrule",
  paste0("Main specification (county-clustered) & ", fmt_coef(rm$est, rm$se), " & ", fmt_se(rm$se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Heterogeneity} & & \\\\",
  paste0("\\quad High Black employment share & ", fmt_coef(rh$est, rh$se), " & ", fmt_se(rh$se), " \\\\"),
  paste0("\\quad Low Black employment share & ", fmt_coef(rl$est, rl$se), " & ", fmt_se(rl$se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Alternative inference} & & \\\\",
  paste0("\\quad State-clustered SE & ", fmt_coef(rs$est, rs$se), " & ", fmt_se(rs$se), " \\\\"),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications are race triple-differences with county, quarter,",
  "and race fixed effects. Dependent variable is quarterly separation rate.",
  "High/low Black share splits counties at median pre-treatment Black food retail employment share.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab4, file.path(table_dir, "tab4_robust.tex"))

# ===========================================================
# TABLE F1: SDE
# ===========================================================
cat("=== Table F1: SDE ===\n")

sd_sep_pre <- sd(panel[panel$first_treat == 0 | panel$time_id < panel$first_treat][black == 1]$sep_rate, na.rm = TRUE)
sd_emp_pre <- sd(panel[panel$first_treat == 0 | panel$time_id < panel$first_treat][black == 1]$ln_emp, na.rm = TRUE)

outcomes_names <- c("Black sep.~rate (diff.)", "Black log emp (diff.)")
est_vec <- c(r2$est, r1$est)
se_vec <- c(r2$se, r1$se)
sd_vec <- c(sd_sep_pre, sd_emp_pre)

sde_vec <- est_vec / sd_vec
sde_se_vec <- se_vec / sd_vec

classify_sde <- function(sde) {
  ifelse(sde < -0.15, "Large negative",
  ifelse(sde < -0.05, "Moderate negative",
  ifelse(sde < -0.005, "Small negative",
  ifelse(sde <= 0.005, "Null",
  ifelse(sde <= 0.05, "Small positive",
  ifelse(sde <= 0.15, "Moderate positive", "Large positive"))))))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does supermarket exit from the SNAP retail network ",
  "disproportionately increase Black food retail worker separations relative to White workers? ",
  "\\textbf{Policy mechanism:} SNAP retailer composition shifted from supermarkets (27\\% to 16\\% share) ",
  "to convenience stores (38\\% to 45\\% share) between 2005 and 2024, driven by corporate chain ",
  "bankruptcies, stocking rule enforcement, and market consolidation. Supermarkets employ more workers ",
  "at higher wages than convenience stores, so the composition shift destroys jobs --- particularly ",
  "among Black workers who occupy a disproportionate share of lower-seniority supermarket positions. ",
  "\\textbf{Outcome definition:} Quarterly separation rate (separations / beginning-of-quarter employment) ",
  "and log employment in NAICS 445 (Food and Beverage Stores), disaggregated by race. ",
  "\\textbf{Treatment:} Binary; equals one in the quarter a county first experiences a SNAP supermarket-class ",
  "retailer exit and all subsequent quarters. ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators (QWI) for NAICS 445, county $\\times$ quarter ",
  "$\\times$ race, 2010--2024, merged to USDA FNS SNAP Retailer Historical Database (703,441 retailers). ",
  "1.1 million county-quarter-race observations across 3,135 counties. ",
  "\\textbf{Method:} Race triple-difference (county FE $+$ quarter FE $+$ race FE $+$ treated $\\times$ Black), ",
  "standard errors clustered at the county level. ",
  "\\textbf{Sample:} All U.S.~counties with QWI NAICS 445 employment data for both White and Black workers; ",
  "2,628 treated counties (with $\\geq$1 supermarket exit) and 507 never-treated counties. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)
for (i in seq_along(est_vec)) {
  tabF1 <- c(tabF1, paste0(outcomes_names[i], " & ",
    formatC(est_vec[i], digits = 3, format = "f"), " & ",
    formatC(se_vec[i], digits = 3, format = "f"), " & ",
    formatC(sd_vec[i], digits = 3, format = "f"), " & ",
    formatC(sde_vec[i], digits = 3, format = "f"), " & ",
    formatC(sde_se_vec[i], digits = 3, format = "f"), " & ",
    classify_sde(sde_vec[i]), " \\\\"))
}
tabF1 <- c(tabF1, "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}", sde_notes, "\\end{tablenotes}", "\\end{table}")
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
