## 05_tables.R — Generate all tables for the paper
## V1: ≤5 tables + 1 SDE appendix table

source("00_packages.R")

panel_did <- readRDS("../data/panel_did.rds")
full_panel <- readRDS("../data/full_panel.rds")
results <- readRDS("../data/results.rds")
fs_models <- readRDS("../data/first_stage_models.rds")
did_models <- readRDS("../data/did_models.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ================================================================
# TABLE 1: Summary Statistics
# ================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Facility-level summary by mandate status
fac_data <- full_panel[, .(
  state = state[1],
  hprd_total = hprd_total[1],
  hprd_rn = hprd_rn[1],
  hprd_cna = hprd_cna[1],
  beds = beds[1],
  urban = urban[1],
  mandate_year = mandate_year[1],
  staffing_rating = staffing_rating[1],
  overall_rating = overall_rating[1],
  rn_turnover = rn_turnover[1],
  total_turnover = total_turnover[1],
  n_def_mean = mean(n_deficiencies),
  has_severe_mean = mean(has_severe)
), by = ccn]

fac_data[, has_mandate := as.integer(!is.na(mandate_year))]
fac_data[, mandate_group := fcase(
  is.na(mandate_year), "No Mandate",
  mandate_year < 2017, "Pre-2017 Mandate",
  mandate_year >= 2017, "2017+ Mandate"
)]

# Generate summary stats table
vars_to_summarize <- c("hprd_total", "hprd_rn", "hprd_cna", "beds",
                        "urban", "staffing_rating", "n_def_mean",
                        "has_severe_mean", "rn_turnover", "total_turnover")
var_labels <- c("Total HPRD", "RN HPRD", "CNA HPRD", "Certified Beds",
                "Urban", "Staffing Rating (1--5)", "Mean Deficiencies/Survey",
                "Pr(Severe Deficiency)", "RN Turnover (\\%)", "Total Turnover (\\%)")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Staffing Mandate Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & No Mandate & Pre-2017 Mandate & 2017+ Mandate \\\\",
  "\\hline"
)

for (i in seq_along(vars_to_summarize)) {
  v <- vars_to_summarize[i]
  lbl <- var_labels[i]
  vals <- sapply(c("No Mandate", "Pre-2017 Mandate", "2017+ Mandate"), function(g) {
    x <- fac_data[mandate_group == g, get(v)]
    x <- x[!is.na(x)]
    if (length(x) == 0) return("---")
    sprintf("%.2f", mean(x))
  })
  sds <- sapply(c("No Mandate", "Pre-2017 Mandate", "2017+ Mandate"), function(g) {
    x <- fac_data[mandate_group == g, get(v)]
    x <- x[!is.na(x)]
    if (length(x) == 0) return("")
    sprintf("(%.2f)", sd(x))
  })
  tab1_lines <- c(tab1_lines,
                   sprintf("%s & %s & %s & %s \\\\", lbl, vals[1], vals[2], vals[3]),
                   sprintf(" & %s & %s & %s \\\\", sds[1], sds[2], sds[3]))
}

# Add N
ns <- sapply(c("No Mandate", "Pre-2017 Mandate", "2017+ Mandate"), function(g) {
  format(nrow(fac_data[mandate_group == g]), big.mark = ",")
})
tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Facilities & %s & %s & %s \\\\", ns[1], ns[2], ns[3]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard deviations in parentheses. HPRD = hours per resident per day from CMS Payroll-Based Journal data (March 2026 release). Staffing rating is the CMS Five-Star staffing domain rating. Deficiency data from CMS Health Deficiency surveys (2017--2026). Mandate classification based on state-level quantitative staffing floor statutes; see Section~\\ref{sec:data} for details.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 written\n")

# ================================================================
# TABLE 2: First Stage — Mandates and Current Staffing
# ================================================================
cat("=== Generating Table 2: First Stage ===\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{First Stage: Staffing Mandates and Hours per Resident per Day}",
  "\\label{tab:first_stage}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Total HPRD & RN HPRD & CNA HPRD & Weekend HPRD \\\\",
  "\\hline"
)

models <- list(fs_models$fs2, fs_models$fs3, fs_models$fs4, fs_models$fs5)
coefs <- sapply(models, function(m) sprintf("%.3f", coef(m)["has_mandate"]))
ses <- sapply(models, function(m) sprintf("(%.3f)", sqrt(vcov(m)["has_mandate","has_mandate"])))
pvals <- sapply(models, function(m) {
  p <- 2 * pnorm(-abs(coef(m)["has_mandate"] / sqrt(vcov(m)["has_mandate","has_mandate"])))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
})
ns_tab2 <- sapply(models, function(m) format(nobs(m), big.mark = ","))
r2s <- sapply(models, function(m) sprintf("%.3f", fixest::r2(m, "wr2")))
dep_means <- c(
  sprintf("%.2f", mean(fac_data$hprd_total, na.rm = TRUE)),
  sprintf("%.2f", mean(fac_data$hprd_rn, na.rm = TRUE)),
  sprintf("%.2f", mean(fac_data$hprd_cna, na.rm = TRUE)),
  sprintf("%.2f", mean(fac_data$hprd_weekend, na.rm = TRUE))
)

tab2_lines <- c(tab2_lines,
  sprintf("Has Mandate & %s%s & %s%s & %s%s & %s%s \\\\",
          coefs[1], pvals[1], coefs[2], pvals[2], coefs[3], pvals[3], coefs[4], pvals[4]),
  sprintf(" & %s & %s & %s & %s \\\\", ses[1], ses[2], ses[3], ses[4]),
  "\\hline",
  sprintf("Dep.\\ Var.\\ Mean & %s & %s & %s & %s \\\\", dep_means[1], dep_means[2], dep_means[3], dep_means[4]),
  sprintf("Observations & %s & %s & %s & %s \\\\", ns_tab2[1], ns_tab2[2], ns_tab2[3], ns_tab2[4]),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Controls & Yes & Yes & Yes & Yes \\\\",
  sprintf("$R^2$ (within) & %s & %s & %s & %s \\\\", r2s[1], r2s[2], r2s[3], r2s[4]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Cross-sectional OLS regressions of current staffing levels on mandate status. Unit of observation is the nursing home facility. ``Has Mandate'' equals one for facilities in states with quantitative HPRD staffing floors. Controls include number of certified beds, urban indicator, ownership type (for-profit, nonprofit, government), and chain membership. Standard errors clustered by state in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, "../tables/tab2_first_stage.tex")
cat("  Table 2 written\n")

# ================================================================
# TABLE 3: Main DiD Results
# ================================================================
cat("=== Generating Table 3: Main DiD Results ===\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Staffing Mandates on Health Deficiencies}",
  "\\label{tab:main_did}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Deficiencies & Log(Def.+1) & Standard Def. & Severe Def. \\\\",
  "\\hline"
)

mods_did <- list(did_models$twfe1, did_models$twfe2, did_models$twfe4, did_models$twfe3)
coefs3 <- sapply(mods_did, function(m) sprintf("%.3f", coef(m)["treated"]))
ses3 <- sapply(mods_did, function(m) sprintf("(%.3f)", sqrt(vcov(m)["treated","treated"])))
pvals3 <- sapply(mods_did, function(m) {
  p <- 2 * pnorm(-abs(coef(m)["treated"] / sqrt(vcov(m)["treated","treated"])))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
})
ns_tab3 <- sapply(mods_did, function(m) format(nobs(m), big.mark = ","))
dep_means3 <- c(
  sprintf("%.2f", mean(panel_did$n_deficiencies[panel_did$treated == 0])),
  sprintf("%.2f", mean(panel_did$log_def[panel_did$treated == 0])),
  sprintf("%.2f", mean(panel_did$n_standard[panel_did$treated == 0])),
  sprintf("%.2f", mean(panel_did$has_severe[panel_did$treated == 0]))
)

tab3_lines <- c(tab3_lines,
  sprintf("Treated & %s%s & %s%s & %s%s & %s%s \\\\",
          coefs3[1], pvals3[1], coefs3[2], pvals3[2], coefs3[3], pvals3[3], coefs3[4], pvals3[4]),
  sprintf(" & %s & %s & %s & %s \\\\", ses3[1], ses3[2], ses3[3], ses3[4]),
  "\\hline",
  sprintf("Dep.\\ Var.\\ Mean & %s & %s & %s & %s \\\\", dep_means3[1], dep_means3[2], dep_means3[3], dep_means3[4]),
  sprintf("Observations & %s & %s & %s & %s \\\\", ns_tab3[1], ns_tab3[2], ns_tab3[3], ns_tab3[4]),
  "Facility FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} TWFE difference-in-differences estimates. Unit of observation is the facility-survey. ``Treated'' equals one for facilities in states with active quantitative staffing mandates at the time of the health inspection survey. Deficiency counts are from CMS health deficiency surveys (2017--2026). ``Severe Def.'' is an indicator for any deficiency with scope-severity code G through L (isolated or pattern actual harm or jeopardy). Standard errors clustered by state in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_main_did.tex")
cat("  Table 3 written\n")

# ================================================================
# TABLE 4: Robustness
# ================================================================
cat("=== Generating Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE \\\\",
  "\\hline",
  sprintf("Baseline TWFE & %.3f & (%.3f) \\\\", results$twfe$n_def$coef, results$twfe$n_def$se)
)

# CS-DiD
tab4_lines <- c(tab4_lines,
  sprintf("Callaway-Sant'Anna & %.3f & (%.3f) \\\\", results$cs_did$att, results$cs_did$se))

# Exclude COVID
tab4_lines <- c(tab4_lines,
  sprintf("Excl.\\ COVID (2020Q2--2021Q1) & %.3f & (%.3f) \\\\",
          rob_results$nocovid$coef, rob_results$nocovid$se))

# Severe deficiency
tab4_lines <- c(tab4_lines,
  sprintf("Outcome: Severe Deficiency & %.3f & (%.3f) \\\\",
          rob_results$severe$coef, rob_results$severe$se))

# Complaint placebo
tab4_lines <- c(tab4_lines,
  sprintf("Placebo: Complaint Deficiencies & %.3f & (%.3f) \\\\",
          rob_results$complaint_placebo$coef, rob_results$complaint_placebo$se))

# Facility clustering
tab4_lines <- c(tab4_lines,
  sprintf("Clustering: Facility & %.3f & (%.3f) \\\\",
          rob_results$fac_cluster$coef, rob_results$fac_cluster$se))

# LOO range
tab4_lines <- c(tab4_lines,
  sprintf("Leave-one-state-out range & [%.3f, %.3f] & --- \\\\",
          min(rob_results$loo$coef), max(rob_results$loo$coef)))

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include facility and year fixed effects. Dependent variable is the number of health deficiencies per survey unless otherwise noted. Standard errors clustered by state (except where indicated). The Callaway-Sant'Anna estimator uses not-yet-treated facilities as controls. Leave-one-state-out iteratively drops each treated state.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Table 4 written\n")

# ================================================================
# TABLE 5: Heterogeneity by Ownership and Size
# ================================================================
cat("=== Generating Table 5: Heterogeneity ===\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Ownership Type and Facility Size}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & For-Profit & Nonprofit & Small ($\\leq$60 beds) & Large ($>$120 beds) \\\\",
  "\\hline"
)

het_mods <- list(did_models$twfe_fp, did_models$twfe_np, did_models$twfe_small, did_models$twfe_large)
het_coefs <- sapply(het_mods, function(m) sprintf("%.3f", coef(m)["treated"]))
het_ses <- sapply(het_mods, function(m) sprintf("(%.3f)", sqrt(vcov(m)["treated","treated"])))
het_pvals <- sapply(het_mods, function(m) {
  p <- 2 * pnorm(-abs(coef(m)["treated"] / sqrt(vcov(m)["treated","treated"])))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
})
het_ns <- sapply(het_mods, function(m) format(nobs(m), big.mark = ","))

tab5_lines <- c(tab5_lines,
  sprintf("Treated & %s%s & %s%s & %s%s & %s%s \\\\",
          het_coefs[1], het_pvals[1], het_coefs[2], het_pvals[2],
          het_coefs[3], het_pvals[3], het_coefs[4], het_pvals[4]),
  sprintf(" & %s & %s & %s & %s \\\\", het_ses[1], het_ses[2], het_ses[3], het_ses[4]),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s \\\\", het_ns[1], het_ns[2], het_ns[3], het_ns[4]),
  "Facility FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} TWFE difference-in-differences estimates on split samples. Dependent variable is the number of health deficiencies per survey. Standard errors clustered by state in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab5_lines, "../tables/tab5_heterogeneity.tex")
cat("  Table 5 written\n")

# ================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ================================================================
cat("=== Generating Table F1: SDE ===\n")

# Compute SDEs for main outcomes
# Binary treatment: SDE = beta / SD(Y_control)
sde_rows <- list()

# 1. Total deficiencies
sd_y_def <- sd(panel_did$n_deficiencies[panel_did$treated == 0], na.rm = TRUE)
beta_def <- as.numeric(results$twfe$n_def$coef)
se_def <- as.numeric(results$twfe$n_def$se)
sde_def <- beta_def / sd_y_def
sde_se_def <- se_def / sd_y_def
sde_rows[[1]] <- c("Total deficiencies", sprintf("%.3f", beta_def), sprintf("%.3f", se_def),
                    sprintf("%.3f", sd_y_def), sprintf("%.3f", sde_def),
                    sprintf("%.3f", sde_se_def),
                    ifelse(abs(sde_def) > 0.15, ifelse(sde_def > 0, "Large positive", "Large negative"),
                    ifelse(abs(sde_def) > 0.05, ifelse(sde_def > 0, "Moderate positive", "Moderate negative"),
                    ifelse(abs(sde_def) > 0.005, ifelse(sde_def > 0, "Small positive", "Small negative"), "Null"))))

# 2. Severe deficiency indicator
sd_y_sev <- sd(panel_did$has_severe[panel_did$treated == 0], na.rm = TRUE)
beta_sev <- as.numeric(results$twfe$has_severe$coef)
se_sev <- as.numeric(results$twfe$has_severe$se)
sde_sev <- beta_sev / sd_y_sev
sde_se_sev <- se_sev / sd_y_sev
classify <- function(sde) {
  if (abs(sde) > 0.15) return(ifelse(sde > 0, "Large positive", "Large negative"))
  if (abs(sde) > 0.05) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  if (abs(sde) > 0.005) return(ifelse(sde > 0, "Small positive", "Small negative"))
  return("Null")
}
sde_rows[[2]] <- c("Severe deficiency", sprintf("%.3f", beta_sev), sprintf("%.3f", se_sev),
                    sprintf("%.3f", sd_y_sev), sprintf("%.3f", sde_sev),
                    sprintf("%.3f", sde_se_sev), classify(sde_sev))

# 3. Standard deficiencies
sd_y_std <- sd(panel_did$n_standard[panel_did$treated == 0], na.rm = TRUE)
beta_std <- as.numeric(coef(did_models$twfe4)["treated"])
se_std <- as.numeric(sqrt(vcov(did_models$twfe4)["treated","treated"]))
sde_std <- beta_std / sd_y_std
sde_se_std <- se_std / sd_y_std
sde_rows[[3]] <- c("Standard deficiencies", sprintf("%.3f", beta_std), sprintf("%.3f", se_std),
                    sprintf("%.3f", sd_y_std), sprintf("%.3f", sde_std),
                    sprintf("%.3f", sde_se_std), classify(sde_std))

# Panel B: Heterogeneous (split samples)
# 4. For-profit
sd_y_fp <- sd(panel_did$n_deficiencies[panel_did$treated == 0 & panel_did$own_cat == "for_profit"], na.rm = TRUE)
beta_fp <- as.numeric(results$heterogeneity$fp$coef)
se_fp <- as.numeric(results$heterogeneity$fp$se)
sde_fp <- beta_fp / sd_y_fp
sde_se_fp <- se_fp / sd_y_fp
sde_rows[[4]] <- c("For-profit facilities", sprintf("%.3f", beta_fp), sprintf("%.3f", se_fp),
                    sprintf("%.3f", sd_y_fp), sprintf("%.3f", sde_fp),
                    sprintf("%.3f", sde_se_fp), classify(sde_fp))

# 5. Nonprofit
sd_y_np <- sd(panel_did$n_deficiencies[panel_did$treated == 0 & panel_did$own_cat == "nonprofit"], na.rm = TRUE)
beta_np <- as.numeric(results$heterogeneity$np$coef)
se_np <- as.numeric(results$heterogeneity$np$se)
sde_np <- beta_np / sd_y_np
sde_se_np <- se_np / sd_y_np
sde_rows[[5]] <- c("Nonprofit facilities", sprintf("%.3f", beta_np), sprintf("%.3f", se_np),
                    sprintf("%.3f", sd_y_np), sprintf("%.3f", sde_np),
                    sprintf("%.3f", sde_se_np), classify(sde_np))

# Build LaTeX table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:3) {
  row <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            row[1], row[2], row[3], row[4], row[5], row[6], row[7]))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (i in 4:5) {
  row <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            row[1], row[2], row[3], row[4], row[5], row[6], row[7]))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level nursing home minimum staffing mandates (quantitative HPRD floors) ",
  "reduce health deficiencies identified during CMS inspection surveys? ",
  "\\textbf{Policy mechanism:} State staffing mandates set minimum hours per resident per day (HPRD) that nursing ",
  "homes must provide, requiring facilities below the floor to hire additional nursing staff (RNs, LPNs, CNAs) ",
  "or face regulatory penalties and potential decertification. ",
  "\\textbf{Outcome definition:} Number of health deficiencies cited during CMS standard health inspection surveys, ",
  "where each deficiency represents a specific regulatory violation identified by state surveyors. ",
  "\\textbf{Treatment:} Binary indicator equal to one when a facility's state has an active quantitative HPRD staffing floor. ",
  "\\textbf{Data:} CMS Health Deficiency surveys and Provider Information, 2017--2026, facility-survey level, approximately 14,000 facilities. ",
  "\\textbf{Method:} TWFE difference-in-differences with facility and year fixed effects; standard errors clustered by state. ",
  "\\textbf{Sample:} Excludes always-treated states (mandates enacted before 2017) to ensure a pre-treatment period; ",
  "restricted to facilities with at least three years of survey data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written\n")

cat("\n=== All tables generated ===\n")
