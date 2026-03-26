## 05_tables.R — Generate all LaTeX tables (tract FE preferred)
## apep_1023: Redemption Deserts

source("00_packages.R")

load("../data/all_models.RData")
load("../data/robustness_models.RData")

dir.create("../tables", showWarnings = FALSE)

# Helper: format coefficient and SE
fmt_coef <- function(model, var = "net_exits") {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  c(sprintf("%.4f%s", b, stars), sprintf("(%.4f)", s))
}

fmt_iv <- function(model, var = "fit_net_exits") {
  fmt_coef(model, var)
}

# === Table 1: Summary Statistics ===
cat("=== Table 1 ===\n")

summ_df <- readRDS("../data/summary_stats.rds")
var_labels <- c(
  snap_rate = "SNAP participation rate",
  n_retailers = "SNAP-authorized retailers",
  net_exits = "Net retailer exits",
  n_exits = "Retailer exits",
  n_new = "New retailer authorizations",
  poverty_rate = "Poverty rate",
  no_vehicle_rate = "No-vehicle rate",
  log_pop = "Log population",
  log_med_inc = "Log median household income",
  pct_black = "Share Black",
  pct_hispanic = "Share Hispanic",
  pre_small_share = "Pre-2018 small-format share"
)

summ_df$Label <- var_labels[summ_df$name]
summ_df <- summ_df[match(names(var_labels), summ_df$name), ]

tab1_body <- paste(
  sprintf("  %s & %s & %.3f & %.3f & %.3f & %.3f \\\\",
          summ_df$Label,
          formatC(summ_df$N, format = "d", big.mark = ","),
          summ_df$Mean, summ_df$SD, summ_df$Min, summ_df$Max),
  collapse = "\n"
)

tab1 <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
Variable & N & Mean & SD & Min & Max \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Unit of observation is census tract $\\times$ year (2015--2022). SNAP participation rate is the share of households receiving SNAP benefits (ACS table B22003). Net retailer exits equals the number of SNAP retailer deauthorizations minus new authorizations in the tract-year. Small-format share is the pre-2018 share of convenience stores, dollar stores, and specialty retailers among all SNAP-authorized retailers in the tract.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}", tab1_body)

writeLines(tab1, "../tables/tab1_summary.tex")

# === Table 2: OLS ===
cat("=== Table 2 ===\n")

ols_c <- cbind(fmt_coef(ols1), fmt_coef(ols2), fmt_coef(ols3), fmt_coef(ols4))

tab2 <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{OLS Estimates: SNAP Retailer Exits and Participation}
\\label{tab:ols}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
\\midrule
Net retailer exits & %s & %s & %s & %s \\\\
& %s & %s & %s & %s \\\\
\\midrule
Controls & No & Yes & No & Yes \\\\
County FE & Yes & Yes & -- & -- \\\\
Tract FE & -- & -- & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
\\midrule
Observations & %s & %s & %s & %s \\\\
$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Dependent variable is the tract-level SNAP participation rate. Controls include poverty rate, log population, log median household income, share Black, and share Hispanic. Standard errors clustered at the county level. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  ols_c[1,1], ols_c[1,2], ols_c[1,3], ols_c[1,4],
  ols_c[2,1], ols_c[2,2], ols_c[2,3], ols_c[2,4],
  formatC(nobs(ols1), big.mark = ","), formatC(nobs(ols2), big.mark = ","),
  formatC(nobs(ols3), big.mark = ","), formatC(nobs(ols4), big.mark = ","),
  r2(ols1, "r2"), r2(ols2, "r2"), r2(ols3, "r2"), r2(ols4, "r2"))

writeLines(tab2, "../tables/tab2_ols.tex")

# === Table 3: First Stage ===
cat("=== Table 3 ===\n")

fmt_fs <- function(model, var) {
  if (var %in% names(coef(model))) {
    b <- coef(model)[var]; s <- se(model)[var]; p <- pvalue(model)[var]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
    c(sprintf("%.4f%s", b, stars), sprintf("(%.4f)", s))
  } else { c("", "") }
}

ivs <- c("iv_fd", "iv_wm", "iv_ap", "iv_stock_rule")
iv_labels <- c("Family Dollar $\\times$ Post-2019",
               "Walmart $\\times$ Post-2016",
               "A\\&P $\\times$ Post-2015",
               "Small-format share $\\times$ Post-2018")

fs_body <- ""
for (i in seq_along(ivs)) {
  r1 <- sapply(list(fs1, fs2, fs3, fs4), function(m) fmt_fs(m, ivs[i])[1])
  r2_row <- sapply(list(fs1, fs2, fs3, fs4), function(m) fmt_fs(m, ivs[i])[2])
  fs_body <- paste0(fs_body, sprintf("%s & %s & %s & %s & %s \\\\\n", iv_labels[i], r1[1], r1[2], r1[3], r1[4]))
  fs_body <- paste0(fs_body, sprintf("& %s & %s & %s & %s \\\\\n", r2_row[1], r2_row[2], r2_row[3], r2_row[4]))
}

tab3 <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{First Stage: Instruments and SNAP Retailer Net Exits}
\\label{tab:first_stage}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& Corp.\\ Shocks & Stock Rule & All IVs & All IVs \\\\
\\midrule
%s\\midrule
County FE & Yes & Yes & Yes & -- \\\\
Tract FE & -- & -- & -- & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
\\midrule
Observations & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Dependent variable is net SNAP retailer exits per tract-year. Family Dollar exposure is the pre-2015 count of Family Dollar stores, interacted with a post-2019 indicator. Walmart and A\\&P exposures constructed analogously. Small-format share is the pre-2018 fraction of small-format retailers, interacted with a post-2018 indicator. Standard errors clustered at the county level. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  fs_body,
  formatC(nobs(fs1), big.mark = ","), formatC(nobs(fs2), big.mark = ","),
  formatC(nobs(fs3), big.mark = ","), formatC(nobs(fs4), big.mark = ","))

writeLines(tab3, "../tables/tab3_first_stage.tex")

# === Table 4: IV Results (county FE and tract FE) ===
cat("=== Table 4 ===\n")

iv_c <- cbind(fmt_iv(iv1), fmt_iv(iv2), fmt_iv(iv3), fmt_iv(iv4), fmt_iv(iv5))

tab4 <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{IV Estimates: Effect of SNAP Retailer Loss on Participation}
\\label{tab:iv}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Corp.\\ IVs & Stock IV & All IVs & All IVs & All IVs \\\\
\\midrule
Net retailer exits & %s & %s & %s & %s & %s \\\\
& %s & %s & %s & %s & %s \\\\
\\midrule
Controls & No & No & No & Yes & No \\\\
County FE & Yes & Yes & Yes & Yes & -- \\\\
Tract FE & -- & -- & -- & -- & Yes \\\\
Year FE & Yes & Yes & Yes & Yes & Yes \\\\
\\midrule
Observations & %s & %s & %s & %s & %s \\\\
First-stage F & %.0f & %.0f & %.0f & %.0f & %.0f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Dependent variable is the tract-level SNAP participation rate. Net retailer exits instrumented using corporate chain closures and the 2018 depth-of-stock rule. Columns~(1)--(4) use county fixed effects; column~(5) uses tract fixed effects. The sign reversal between county FE (positive) and tract FE (negative) reflects cross-tract selection: chain stores locate in high-SNAP neighborhoods, and county FE do not fully absorb this correlation. The tract FE specification (column~5) identifies the within-tract causal effect. Standard errors clustered at the county level. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  iv_c[1,1], iv_c[1,2], iv_c[1,3], iv_c[1,4], iv_c[1,5],
  iv_c[2,1], iv_c[2,2], iv_c[2,3], iv_c[2,4], iv_c[2,5],
  formatC(nobs(iv1), big.mark = ","), formatC(nobs(iv2), big.mark = ","),
  formatC(nobs(iv3), big.mark = ","), formatC(nobs(iv4), big.mark = ","),
  formatC(nobs(iv5), big.mark = ","),
  fitstat(iv1, "ivf")[[1]], fitstat(iv2, "ivf")[[1]],
  fitstat(iv3, "ivf")[[1]], fitstat(iv4, "ivf")[[1]],
  fitstat(iv5, "ivf")[[1]])

writeLines(tab4, "../tables/tab4_iv.tex")

# === Table 5: Robustness and Heterogeneity (Tract FE) ===
cat("=== Table 5 ===\n")

rob_c <- cbind(
  fmt_iv(iv_tfe_no_fd), fmt_iv(iv_tfe_no_wm), fmt_iv(iv_tfe_no_ap),
  fmt_iv(iv_tfe_no_sr), fmt_iv(placebo_pov_tfe)
)
het_c <- cbind(
  fmt_iv(iv_tfe_low_veh), fmt_iv(iv_tfe_high_veh),
  fmt_iv(iv_tfe_urban), fmt_iv(iv_tfe_rural),
  fmt_iv(iv_tfe_hipov)
)

tab5 <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{Robustness and Heterogeneity (Tract Fixed Effects)}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
\\multicolumn{6}{l}{\\textit{Panel A: Leave-One-Instrument-Out}} \\\\
\\midrule
& Drop Fam. & Drop & Drop & Drop Stock & Placebo: \\\\
& Dollar & Walmart & A\\&P & Rule & Poverty \\\\
\\midrule
Net retailer exits & %s & %s & %s & %s & %s \\\\
& %s & %s & %s & %s & %s \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel B: Heterogeneity by Baseline Tract Characteristics}} \\\\
\\midrule
& Low & High & & & High \\\\
& No-Veh & No-Veh & Urban & Rural & Poverty \\\\
\\midrule
Net retailer exits & %s & %s & %s & %s & %s \\\\
& %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} All specifications use tract and year fixed effects with standard errors clustered at the county level. Panel~A drops one instrument at a time; column~(5) uses poverty rate as the outcome (placebo). Panel~B splits the sample at the baseline median of each characteristic (computed from the first observed year per tract to avoid bad controls). $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  rob_c[1,1], rob_c[1,2], rob_c[1,3], rob_c[1,4], rob_c[1,5],
  rob_c[2,1], rob_c[2,2], rob_c[2,3], rob_c[2,4], rob_c[2,5],
  het_c[1,1], het_c[1,2], het_c[1,3], het_c[1,4], het_c[1,5],
  het_c[2,1], het_c[2,2], het_c[2,3], het_c[2,4], het_c[2,5])

writeLines(tab5, "../tables/tab5_robustness.tex")

# === SDE Table ===
cat("=== SDE Table ===\n")

# Preferred spec: iv5 (tract FE, all IVs)
coef_main <- coef(iv5)["fit_net_exits"]
se_main <- se(iv5)["fit_net_exits"]

# SD(Y) from pre-treatment period (2015)
pre_df <- df[df$year == 2015, ]
sd_y <- sd(pre_df$snap_rate, na.rm = TRUE)

sde_main <- coef_main / sd_y
sde_se_main <- se_main / sd_y

classify_sde <- function(x) {
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small positive")
  if (x < 0.15) return("Moderate positive")
  return("Large positive")
}

panel_a <- sprintf(
"    SNAP participation rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
  coef_main, se_main, sd_y, sde_main, sde_se_main, classify_sde(sde_main))

# Panel B: heterogeneity
het_specs <- list(
  list(model = iv_tfe_high_veh, label = "High no-vehicle tracts",
       sub = df[df$high_noveh == 1, ]),
  list(model = iv_tfe_rural, label = "Rural tracts",
       sub = df[df$urban == 0, ])
)

panel_b <- ""
for (h in het_specs) {
  b <- coef(h$model)["fit_net_exits"]
  s <- se(h$model)["fit_net_exits"]
  pre_sub <- h$sub[h$sub$year == 2015, ]
  sd_sub <- sd(pre_sub$snap_rate, na.rm = TRUE)
  sde_h <- b / sd_sub
  sde_se_h <- s / sd_sub
  panel_b <- paste0(panel_b, sprintf(
"    %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    h$label, b, s, sd_sub, sde_h, sde_se_h, classify_sde(sde_h)))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does loss of SNAP-authorized retailers reduce household SNAP participation through destruction of physical redemption infrastructure? ",
  "\\textbf{Policy mechanism:} SNAP benefits can only be redeemed at authorized retailers; when retailers lose authorization (due to corporate closures or the 2018 depth-of-stock rule tripling minimum inventory requirements from 12 to 36 staple items), eligible households face increased travel costs to redeem benefits, potentially reducing takeup among the eligible population. ",
  "\\textbf{Outcome definition:} SNAP participation rate, defined as the share of households in a census tract receiving SNAP/Food Stamp benefits in the past 12 months (ACS table B22003). ",
  "\\textbf{Treatment:} Continuous; net retailer exits per tract-year (deauthorizations minus new authorizations). ",
  "\\textbf{Data:} ACS 5-year estimates (2015--2022) merged with USDA SNAP Historical Retailer Database (703,000 retailers with authorization and end dates), census tract level, approximately ",
  formatC(nrow(df), big.mark = ","),
  " tract-year observations across ",
  formatC(n_distinct(df$GEOID), big.mark = ","),
  " tracts. ",
  "\\textbf{Method:} Two-stage least squares using four instruments---pre-shock exposure to Family Dollar (post-2019), Walmart (post-2016), and A\\&P (post-2015) corporate closures, plus pre-2018 small-format retailer share interacted with post-2018 depth-of-stock rule---with tract and year fixed effects; standard errors clustered at the county level. ",
  "\\textbf{Sample:} Continental U.S.~census tracts with at least 50 households (excludes tracts with zero population or suppressed ACS data). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- sprintf(
"\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\midrule
%s
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  panel_a, panel_b, sde_notes)

writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
