# ============================================================
# 05_tables.R — Generate all LaTeX tables
# apep_0765: SNAP Retailer Exits and Mortgage Access
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
twfe_orig <- readRDS(file.path(data_dir, "twfe_orig.rds"))
twfe_deny <- readRDS(file.path(data_dir, "twfe_deny.rds"))
twfe_loan <- readRDS(file.path(data_dir, "twfe_loan.rds"))
twfe_fha <- readRDS(file.path(data_dir, "twfe_fha.rds"))
twfe_orig_sy <- readRDS(file.path(data_dir, "twfe_orig_sy.rds"))
twfe_deny_sy <- readRDS(file.path(data_dir, "twfe_deny_sy.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

fmt_coef <- function(est, se, digits = 3) {
  pval <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  paste0(formatC(est, digits = digits, format = "f"), stars)
}
fmt_se <- function(se, digits = 3) paste0("(", formatC(se, digits = digits, format = "f"), ")")
get_est <- function(m, v) {
  list(est = coef(m)[v], se = sqrt(vcov(m)[v, v]))
}

# ===========================================================
# TABLE 1: Summary Statistics
# ===========================================================
pre <- panel[treated == 0]

tab1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Summary Statistics: County-Year Mortgage Panel, 2018--2023}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lrrr}", "\\toprule",
  " & Mean & SD & N \\\\", "\\midrule",
  paste0("Originations & ", round(mean(pre$n_originations, na.rm=T), 1), " & ",
         round(sd(pre$n_originations, na.rm=T), 1), " & ",
         format(nrow(pre), big.mark=","), " \\\\"),
  paste0("Log originations & ", round(mean(pre$ln_orig, na.rm=T), 2), " & ",
         round(sd(pre$ln_orig, na.rm=T), 2), " & \\\\"),
  paste0("Denial rate & ", round(mean(pre$denial_rate, na.rm=T), 3), " & ",
         round(sd(pre$denial_rate, na.rm=T), 3), " & \\\\"),
  paste0("Median loan (\\$) & ", format(round(mean(pre$median_loan, na.rm=T), 0), big.mark=","), " & ",
         format(round(sd(pre$median_loan, na.rm=T), 0), big.mark=","), " & \\\\"),
  paste0("FHA share & ", round(mean(pre$fha_share, na.rm=T), 3), " & ",
         round(sd(pre$fha_share, na.rm=T), 3), " & \\\\"),
  "\\addlinespace",
  paste0("Counties & \\multicolumn{3}{c}{", length(unique(panel$county_fips)), "} \\\\"),
  paste0("Treated (ever) & \\multicolumn{3}{c}{",
         sum(panel$first_treat > 0 & !duplicated(panel$county_fips)), "} \\\\"),
  paste0("Never-treated & \\multicolumn{3}{c}{",
         sum(panel$first_treat == 0 & !duplicated(panel$county_fips)), "} \\\\"),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment statistics. HMDA home-purchase loans from CFPB, 2018--2023.",
  "Denial rate = denied applications / total applications. FHA share = FHA originations / total originations.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab1, file.path(table_dir, "tab1_sumstats.tex"))

# ===========================================================
# TABLE 2: Main Results
# ===========================================================
r1 <- get_est(twfe_orig, "treated")
r2 <- get_est(twfe_deny, "treated")
r3 <- get_est(twfe_loan, "treated")
r4 <- get_est(twfe_fha, "treated")

tab2 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Effect of Supermarket Exit on County Mortgage Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Orig & Denial Rate & Log Loan & FHA Share \\\\",
  "\\midrule",
  paste0("SM Exit & ", fmt_coef(r1$est, r1$se), " & ",
         fmt_coef(r2$est, r2$se), " & ",
         fmt_coef(r3$est, r3$se), " & ",
         fmt_coef(r4$est, r4$se), " \\\\"),
  paste0(" & ", fmt_se(r1$se), " & ", fmt_se(r2$se), " & ",
         fmt_se(r3$se), " & ", fmt_se(r4$se), " \\\\"),
  paste0(" & [", formatC(r1$est - 1.96*r1$se, digits=3, format="f"), ", ",
         formatC(r1$est + 1.96*r1$se, digits=3, format="f"), "]",
         " & [", formatC(r2$est - 1.96*r2$se, digits=3, format="f"), ", ",
         formatC(r2$est + 1.96*r2$se, digits=3, format="f"), "]",
         " & & \\\\"),
  "\\addlinespace",
  paste0("Pre-treatment mean & ", round(mean(pre$ln_orig, na.rm=T), 2),
         " & ", round(mean(pre$denial_rate, na.rm=T), 3),
         " & ", round(mean(pre$ln_loan[!is.na(pre$ln_loan)], na.rm=T), 2),
         " & ", round(mean(pre$fha_share, na.rm=T), 3), " \\\\"),
  paste0("Observations & ", format(nobs(twfe_orig), big.mark=","),
         " & ", format(nobs(twfe_deny), big.mark=","),
         " & ", format(nobs(twfe_loan), big.mark=","),
         " & ", format(nobs(twfe_fha), big.mark=","), " \\\\"),
  "Counties & 3,179 & 3,179 & 3,176 & 3,179 \\\\",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & County & County & County & County \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} TWFE estimates. Treatment: county's first SNAP supermarket deauthorization.",
  "95\\% CI in brackets for key outcomes. Standard errors clustered at county level.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

# ===========================================================
# TABLE 3: State × Year FE
# ===========================================================
s1 <- get_est(twfe_orig_sy, "treated")
s2 <- get_est(twfe_deny_sy, "treated")

tab3 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Robustness: State $\\times$ Year Fixed Effects}",
  "\\label{tab:stateyear}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Orig & Denial Rate & Log Orig & Denial Rate \\\\",
  " & County+Year & County+Year & County+St$\\times$Yr & County+St$\\times$Yr \\\\",
  "\\midrule",
  paste0("SM Exit & ", fmt_coef(r1$est, r1$se), " & ",
         fmt_coef(r2$est, r2$se), " & ",
         fmt_coef(s1$est, s1$se), " & ",
         fmt_coef(s2$est, s2$se), " \\\\"),
  paste0(" & ", fmt_se(r1$se), " & ", fmt_se(r2$se), " & ",
         fmt_se(s1$se), " & ", fmt_se(s2$se), " \\\\"),
  "\\addlinespace",
  paste0("Observations & ", format(nobs(twfe_orig), big.mark=","),
         " & ", format(nobs(twfe_deny), big.mark=","),
         " & ", format(nobs(twfe_orig_sy), big.mark=","),
         " & ", format(nobs(twfe_deny_sy), big.mark=","), " \\\\"),
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & --- & --- \\\\",
  "State $\\times$ Year FE & No & No & Yes & Yes \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (3)--(4) replace year FE with state $\\times$ year FE,",
  "absorbing all state-level time-varying confounds. Results remain null.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab3, file.path(table_dir, "tab3_stateyear.tex"))

# ===========================================================
# TABLE 4: Robustness
# ===========================================================
d1 <- get_est(robustness$dose_deny, "cum_sm_exits")
d2 <- get_est(robustness$dose_orig, "cum_sm_exits")
lv <- get_est(robustness$level, "treated")
sc <- get_est(robustness$state_cluster, "treated")

tab4 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Additional Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}", "\\toprule",
  " & Estimate & SE \\\\", "\\midrule",
  "\\textbf{Panel A: Dose-response (cumulative exits)} & & \\\\",
  paste0("\\quad Denial rate & ", fmt_coef(d1$est, d1$se, 5), " & ", fmt_se(d1$se, 5), " \\\\"),
  paste0("\\quad Log originations & ", fmt_coef(d2$est, d2$se), " & ", fmt_se(d2$se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Panel B: Alternative specifications} & & \\\\",
  paste0("\\quad Origination count (level) & ", fmt_coef(lv$est, lv$se, 1), " & ", fmt_se(lv$se, 1), " \\\\"),
  paste0("\\quad Denial rate (state-clustered) & ", fmt_coef(sc$est, sc$se), " & ", fmt_se(sc$se), " \\\\"),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A uses cumulative supermarket exits (continuous) instead of binary treatment.",
  "Panel B varies outcome definition and clustering.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab4, file.path(table_dir, "tab4_robust.tex"))

# ===========================================================
# TABLE F1: SDE
# ===========================================================
sd_deny_pre <- sd(pre$denial_rate, na.rm = TRUE)
sd_orig_pre <- sd(pre$ln_orig, na.rm = TRUE)

est_vec <- c(r2$est, r1$est)
se_vec <- c(r2$se, r1$se)
sd_vec <- c(sd_deny_pre, sd_orig_pre)
sde_vec <- est_vec / sd_vec
sde_se_vec <- se_vec / sd_vec

classify_sde <- function(s) ifelse(s < -0.15, "Large negative",
  ifelse(s < -0.05, "Moderate negative", ifelse(s < -0.005, "Small negative",
  ifelse(s <= 0.005, "Null", ifelse(s <= 0.05, "Small positive",
  ifelse(s <= 0.15, "Moderate positive", "Large positive"))))))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does SNAP supermarket exit from a county reduce mortgage ",
  "originations or increase denial rates for home purchase loans? ",
  "\\textbf{Policy mechanism:} Supermarket deauthorization from the SNAP retail network removes ",
  "a major foot-traffic anchor from the neighborhood commercial ecosystem. If lenders and appraisers ",
  "interpret grocery exit as a signal of neighborhood decline, mortgage access may tighten through ",
  "higher denial rates, lower loan amounts, or a shift toward government-backed (FHA) lending. ",
  "\\textbf{Outcome definition:} Denial rate (denied home-purchase applications divided by total ",
  "applications) and log originations (natural log of the count of originated home-purchase loans) ",
  "at the county-year level. ",
  "\\textbf{Treatment:} Binary; equals one in the year a county first experiences a SNAP ",
  "supermarket-class retailer deauthorization and all subsequent years. ",
  "\\textbf{Data:} CFPB HMDA loan-level data (30.9 million home-purchase applications, 2018--2023) ",
  "aggregated to county-year, merged to USDA FNS SNAP Retailer Historical Database (703,441 retailers). ",
  "19,005 county-year observations across 3,186 counties. ",
  "\\textbf{Method:} Two-way fixed effects (county FE $+$ year FE), standard errors clustered at ",
  "the county level. State $\\times$ year FE as robustness. ",
  "\\textbf{Sample:} All U.S.~counties with HMDA home-purchase loan data and matched SNAP retailer ",
  "records; 1,871 treated counties (with $\\geq$1 supermarket deauthorization) and 1,315 never-treated. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  paste0("Denial rate & ", formatC(est_vec[1], digits=4, format="f"), " & ",
         formatC(se_vec[1], digits=4, format="f"), " & ",
         formatC(sd_vec[1], digits=3, format="f"), " & ",
         formatC(sde_vec[1], digits=3, format="f"), " & ",
         formatC(sde_se_vec[1], digits=3, format="f"), " & ",
         classify_sde(sde_vec[1]), " \\\\"),
  paste0("Log originations & ", formatC(est_vec[2], digits=4, format="f"), " & ",
         formatC(se_vec[2], digits=4, format="f"), " & ",
         formatC(sd_vec[2], digits=3, format="f"), " & ",
         formatC(sde_vec[2], digits=3, format="f"), " & ",
         formatC(sde_se_vec[2], digits=3, format="f"), " & ",
         classify_sde(sde_vec[2]), " \\\\"),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}", sde_notes, "\\end{tablenotes}", "\\end{table}")
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
