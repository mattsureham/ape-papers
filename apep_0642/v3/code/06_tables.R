## 06_tables.R — Generate all LaTeX tables
## APEP-0642 v3: Regulatory Whack-a-Mole (Reparameterized specification)

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# Load models
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
df <- fread(file.path(data_dir, "analysis_panel.csv"))

# Prepare derived columns (match 03_main_analysis.R)
df[, log_releases := log(releases + 1)]
df[, fcm_id := paste(fc_id, medium, sep = "_")]
df[, year_f := factor(YEAR)]
for (m in unique(df$medium_cat)) {
  p99 <- quantile(df[medium_cat == m, releases], 0.99, na.rm = TRUE)
  df[medium_cat == m, releases_w := pmin(releases, p99)]
}
df[, log_releases_w := log(releases_w + 1)]
if (!"cwa_inspected" %in% names(df)) df[, cwa_inspected := 0L]

# Helper: format numbers with significance stars
fmt_coef <- function(est, se, pval) {
  stars <- ""
  if (!is.na(pval)) {
    if (pval < 0.01) stars <- "***"
    else if (pval < 0.05) stars <- "**"
    else if (pval < 0.1) stars <- "*"
  }
  paste0(sprintf("%.4f", est), stars)
}

fmt_se <- function(se_val) {
  sprintf("(%.4f)", se_val)
}

# Helper: safely extract coefficient (returns 0 if missing)
safe_coef <- function(model, name) {
  cf <- coef(model)
  if (name %in% names(cf)) cf[[name]] else NA_real_
}
safe_se <- function(model, name) {
  s <- se(model)
  if (name %in% names(s)) s[[name]] else NA_real_
}
safe_pval <- function(model, name) {
  p <- pvalue(model)
  if (name %in% names(p)) p[[name]] else NA_real_
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- df[, .(mean = mean(releases, na.rm = TRUE),
               sd = sd(releases, na.rm = TRUE),
               median = median(releases, na.rm = TRUE),
               pct_zero = mean(releases == 0, na.rm = TRUE) * 100,
               n = .N),
           by = medium_cat][order(match(medium_cat, c("Air", "Water", "Land", "POTW")))]

n_fac <- uniqueN(df$frs_id)
n_chem <- uniqueN(df$cas)
n_fc <- uniqueN(df$fc_id)
n_cwa <- if ("cwa_inspected" %in% names(df)) uniqueN(df$frs_id[df$cwa_inspected == 1]) else 0
caa_share <- round(mean(df[medium_cat == "Air", caa_chemical == "YES"]) * 100, 1)

tab1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lrrrrr}
\\toprule
& Mean & SD & Median & \\% Zero & N \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: Releases by Medium (pounds)}} \\\\[3pt]
Air releases & ", sprintf("%.1f", summ[medium_cat == "Air", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Air", pct_zero]), " & ",
  format(summ[medium_cat == "Air", n], big.mark = ","), " \\\\
Water releases & ", sprintf("%.1f", summ[medium_cat == "Water", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Water", pct_zero]), " & ",
  format(summ[medium_cat == "Water", n], big.mark = ","), " \\\\
Land releases & ", sprintf("%.1f", summ[medium_cat == "Land", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "Land", pct_zero]), " & ",
  format(summ[medium_cat == "Land", n], big.mark = ","), " \\\\
POTW transfers & ", sprintf("%.1f", summ[medium_cat == "POTW", mean]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", sd]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", median]), " & ",
  sprintf("%.1f", summ[medium_cat == "POTW", pct_zero]), " & ",
  format(summ[medium_cat == "POTW", n], big.mark = ","), " \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel B: Sample Characteristics}} \\\\[3pt]
Facilities & \\multicolumn{5}{l}{", format(n_fac, big.mark = ","), "} \\\\
Chemicals & \\multicolumn{5}{l}{", format(n_chem, big.mark = ","), "} \\\\
Facility-chemicals & \\multicolumn{5}{l}{", format(n_fc, big.mark = ","), "} \\\\
CAA-regulated (\\%) & \\multicolumn{5}{l}{", caa_share, "} \\\\
CWA-inspected facilities & \\multicolumn{5}{l}{", format(n_cwa, big.mark = ","), "} \\\\
Years & \\multicolumn{5}{l}{", paste(range(df$YEAR), collapse = "--"), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Pre-inspection releases in the analysis sample (event window $\\pm 5$ years). The panel is at the facility $\\times$ chemical $\\times$ medium $\\times$ year level. CWA (Clean Water Act) inspections from EPA ICIS-NPDES database. CAA-regulated share based on TRI chemical designation (Column 42).
\\end{minipage}
\\end{table}")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Reparameterized Main Results
# Y = alpha_fcm + gamma_t + theta(Post) + tau(Post x Air) + eps
# theta = common post effect (non-air baseline)
# tau = air-vs-nonair differential (key parameter)
# ============================================================
cat("=== Table 2: Main Reparameterized Results ===\n")

m1 <- models$m_reparam
m2 <- models$m_reparam_cwa

tab2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Cross-Media Pollution Substitution: Main Results}
\\label{tab:main}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& Baseline & CWA Controls \\\\
\\midrule
$\\hat{\\theta}$ (Post) & ",
  fmt_coef(coef(m1)["post"], se(m1)["post"], pvalue(m1)["post"]), " & ",
  fmt_coef(coef(m2)["post"], se(m2)["post"], pvalue(m2)["post"]), " \\\\
& ", fmt_se(se(m1)["post"]), " & ", fmt_se(se(m2)["post"]), " \\\\[6pt]
$\\hat{\\tau}$ (Post $\\times$ Air) & ",
  fmt_coef(coef(m1)["post_air"], se(m1)["post_air"], pvalue(m1)["post_air"]), " & ",
  fmt_coef(coef(m2)["post_air"], se(m2)["post_air"], pvalue(m2)["post_air"]), " \\\\
& ", fmt_se(se(m1)["post_air"]), " & ", fmt_se(se(m2)["post_air"]), " \\\\[6pt]",
if ("cwa_inspected" %in% names(coef(m2))) paste0("
CWA Inspected & & ",
  fmt_coef(coef(m2)["cwa_inspected"], se(m2)["cwa_inspected"], pvalue(m2)["cwa_inspected"]), " \\\\
& & ", fmt_se(se(m2)["cwa_inspected"]), " \\\\[6pt]") else "", "
\\midrule
Observations & ", format(nobs(m1), big.mark = ","), " & ",
  format(nobs(m2), big.mark = ","), " \\\\
Facility $\\times$ Chem $\\times$ Medium FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Clustering & Facility & Facility \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Dependent variable is $\\log(\\text{releases} + 1)$, winsorized at the 99th percentile by medium. The reparameterized specification is $Y_{fcmt} = \\alpha_{fcm} + \\gamma_t + \\theta \\cdot \\mathit{Post}_{ft} + \\tau \\cdot \\mathit{Post}_{ft} \\times \\mathit{Air}_m + \\varepsilon_{fcmt}$, where $\\theta$ captures the common post-inspection effect across all media and $\\tau$ captures the air-vs-non-air differential. Column~(2) adds an indicator for contemporaneous CWA inspection. Standard errors clustered at the facility level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Medium-Specific Decomposition
# ============================================================
cat("=== Table 3: Medium-Specific Decomposition ===\n")

mn <- models$medium_results

tab3_rows <- ""
tab3_n <- ""
for (m in c("Air", "Water", "Land", "POTW")) {
  mod <- mn[[m]]
  tab3_rows <- paste0(tab3_rows, "
", m, " & ",
    fmt_coef(coef(mod)["post"], se(mod)["post"], pvalue(mod)["post"]), " & ",
    fmt_se(se(mod)["post"]), " & ",
    format(nobs(mod), big.mark = ","), " \\\\[3pt]")
}

tab3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Medium-Specific Decomposition: Effect of CAA Inspections by Release Pathway}
\\label{tab:decomp}
\\begin{tabular}{lccc}
\\toprule
& Post & SE & N \\\\
\\midrule", tab3_rows, "
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Each row reports the post-inspection coefficient from a separate regression of $\\log(\\text{releases} + 1)$ on a post-inspection indicator, estimated within each release medium. All specifications include facility $\\times$ chemical and year fixed effects, with CWA inspection controls. Standard errors clustered at the facility level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab3, file.path(tables_dir, "tab3_decomp.tex"))

# ============================================================
# Table 4: CAA vs Non-CAA Mechanism (reparameterized)
# ============================================================
cat("=== Table 4: Mechanism (CAA vs Non-CAA) ===\n")

m_caa <- models$m_caa
m_nc  <- models$m_noncaa

# m_caa and m_noncaa use reparameterized spec: post + post_air
tab4 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Mechanism Test: CAA-Regulated vs.\\ Non-CAA Chemicals}
\\label{tab:mechanism}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& CAA Chemicals & Non-CAA Chemicals \\\\
\\midrule
$\\hat{\\theta}$ (Post) & ",
  fmt_coef(coef(m_caa)["post"], se(m_caa)["post"], pvalue(m_caa)["post"]), " & ",
  fmt_coef(coef(m_nc)["post"], se(m_nc)["post"], pvalue(m_nc)["post"]), " \\\\
& ", fmt_se(se(m_caa)["post"]), " & ", fmt_se(se(m_nc)["post"]), " \\\\[6pt]
$\\hat{\\tau}$ (Post $\\times$ Air) & ",
  fmt_coef(coef(m_caa)["post_air"], se(m_caa)["post_air"], pvalue(m_caa)["post_air"]), " & ",
  fmt_coef(coef(m_nc)["post_air"], se(m_nc)["post_air"], pvalue(m_nc)["post_air"]), " \\\\
& ", fmt_se(se(m_caa)["post_air"]), " & ", fmt_se(se(m_nc)["post_air"]), " \\\\[6pt]
\\midrule
Observations & ", format(nobs(m_caa), big.mark = ","), " & ", format(nobs(m_nc), big.mark = ","), " \\\\
Facility $\\times$ Chem $\\times$ Medium FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
CWA Controls & Yes & Yes \\\\
Clustering & Facility & Facility \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} The sample is split by whether the chemical is classified as regulated under the Clean Air Act (TRI Column 42). Both specifications use the reparameterized model with CWA inspection controls. If the mechanism is regulatory substitution, $\\hat{\\tau}$ should be larger (more negative) for CAA-regulated chemicals. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab4, file.path(tables_dir, "tab4_mechanism.tex"))

# ============================================================
# Table 5: Stacked DiD vs TWFE
# ============================================================
cat("=== Table 5: Stacked DiD vs TWFE ===\n")

m_twfe <- models$m_reparam_cwa
m_stack <- models$m_stacked

tab5 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity-Robust Estimation: TWFE vs.\\ Stacked DiD}
\\label{tab:stacked}
\\begin{tabular}{lccc}
\\toprule
& $\\hat{\\theta}$ (Post) & $\\hat{\\tau}$ (Post $\\times$ Air) & N \\\\
\\midrule
TWFE (baseline) & ",
  fmt_coef(coef(m_twfe)["post"], se(m_twfe)["post"], pvalue(m_twfe)["post"]), " & ",
  fmt_coef(coef(m_twfe)["post_air"], se(m_twfe)["post_air"], pvalue(m_twfe)["post_air"]), " & ",
  format(nobs(m_twfe), big.mark = ","), " \\\\
& ", fmt_se(se(m_twfe)["post"]), " & ", fmt_se(se(m_twfe)["post_air"]), " & \\\\[6pt]
Stacked DiD & ",
  fmt_coef(coef(m_stack)["post"], se(m_stack)["post"], pvalue(m_stack)["post"]), " & ",
  fmt_coef(coef(m_stack)["post_air"], se(m_stack)["post_air"], pvalue(m_stack)["post_air"]), " & ",
  format(nobs(m_stack), big.mark = ","), " \\\\
& ", fmt_se(se(m_stack)["post"]), " & ", fmt_se(se(m_stack)["post_air"]), " & \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} TWFE estimates are from the reparameterized specification with CWA controls (Table~\\ref{tab:main}, Column 2). Stacked DiD constructs cohort-specific datasets using each treatment cohort and its not-yet-treated controls within a $\\pm 4$ year window, then estimates the reparameterized specification on the pooled stacked sample with cohort-specific fixed effects. Standard errors clustered at the facility level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab5, file.path(tables_dir, "tab5_stacked.tex"))

# ============================================================
# Table 6: Robustness
# Note: Robustness models (04_robustness.R) use V2 parameterization
# (post_air + post_nonair). We derive theta and tau:
#   theta = post_nonair  (common post = non-air effect)
#   tau = post_air - post_nonair  (air differential)
# For SEs on tau we use the delta method via the vcov matrix.
# ============================================================
cat("=== Table 6: Robustness ===\n")

rm <- rob_models

# Helper: extract reparameterized theta and tau from V2 models
# V2 model: Y ~ post_air + post_nonair | FE
# theta = post_nonair, tau = post_air - post_nonair
# Use vcov matrix for proper delta-method SEs on tau
reparam_from_v2 <- function(model) {
  # theta = post_nonair (direct coefficient)
  theta_est <- coef(model)["post_nonair"]
  theta_se <- se(model)["post_nonair"]
  theta_p <- pvalue(model)["post_nonair"]

  # tau = post_air - post_nonair (delta method via vcov)
  tau_est <- coef(model)["post_air"] - coef(model)["post_nonair"]

  # SE(tau) = sqrt(Var(a) + Var(b) - 2*Cov(a,b))
  V <- vcov(model)
  tau_var <- V["post_air", "post_air"] + V["post_nonair", "post_nonair"] -
             2 * V["post_air", "post_nonair"]
  tau_se <- sqrt(max(tau_var, 0))
  tau_p <- 2 * pt(-abs(tau_est / tau_se), df = nobs(model) - length(coef(model)))

  list(theta = theta_est, theta_se = theta_se, theta_p = theta_p,
       tau = tau_est, tau_se = tau_se, tau_p = tau_p,
       n = nobs(model))
}

# Extract reparameterized coefficients for each robustness spec
r_fac     <- reparam_from_v2(rm$m_fac)
r_state   <- reparam_from_v2(rm$m_state)
r_2way    <- reparam_from_v2(rm$m_2way)
r_w3      <- reparam_from_v2(rm$m_w3)
r_nocovid <- reparam_from_v2(rm$m_nocovid)

tab6 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Baseline & State & Two-Way & $\\pm 3$ Yr & Excl.\\ 2020 \\\\
\\midrule
$\\hat{\\theta}$ (Post) & ",
fmt_coef(r_fac$theta, r_fac$theta_se, r_fac$theta_p), " & ",
fmt_coef(r_state$theta, r_state$theta_se, r_state$theta_p), " & ",
fmt_coef(r_2way$theta, r_2way$theta_se, r_2way$theta_p), " & ",
fmt_coef(r_w3$theta, r_w3$theta_se, r_w3$theta_p), " & ",
fmt_coef(r_nocovid$theta, r_nocovid$theta_se, r_nocovid$theta_p), " \\\\
& ", fmt_se(r_fac$theta_se), " & ",
fmt_se(r_state$theta_se), " & ",
fmt_se(r_2way$theta_se), " & ",
fmt_se(r_w3$theta_se), " & ",
fmt_se(r_nocovid$theta_se), " \\\\[6pt]
$\\hat{\\tau}$ (Post $\\times$ Air) & ",
fmt_coef(r_fac$tau, r_fac$tau_se, r_fac$tau_p), " & ",
fmt_coef(r_state$tau, r_state$tau_se, r_state$tau_p), " & ",
fmt_coef(r_2way$tau, r_2way$tau_se, r_2way$tau_p), " & ",
fmt_coef(r_w3$tau, r_w3$tau_se, r_w3$tau_p), " & ",
fmt_coef(r_nocovid$tau, r_nocovid$tau_se, r_nocovid$tau_p), " \\\\
& ", fmt_se(r_fac$tau_se), " & ",
fmt_se(r_state$tau_se), " & ",
fmt_se(r_2way$tau_se), " & ",
fmt_se(r_w3$tau_se), " & ",
fmt_se(r_nocovid$tau_se), " \\\\[6pt]
\\midrule
Observations & ", format(r_fac$n, big.mark = ","), " & ",
format(r_state$n, big.mark = ","), " & ",
format(r_2way$n, big.mark = ","), " & ",
format(r_w3$n, big.mark = ","), " & ",
format(r_nocovid$n, big.mark = ","), " \\\\
Clustering & Facility & State & Fac + Year & Facility & Facility \\\\
\\midrule
RI $p$-value (Air) & \\multicolumn{5}{c}{", sprintf("%.3f", rm$ri_p_air), "} \\\\
RI $p$-value (Non-Air) & \\multicolumn{5}{c}{", sprintf("%.3f", rm$ri_p_nonair), "} \\\\
Pre-trend Wald $p$ & \\multicolumn{5}{c}{", sprintf("%.3f", rm$wald_pre_p), "} \\\\
Balance test $p$ & \\multicolumn{5}{c}{$<$0.001} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} All specifications include facility $\\times$ chemical $\\times$ medium and year fixed effects. $\\hat{\\theta}$ and $\\hat{\\tau}$ derived from the reparameterized specification (Table~\\ref{tab:main}). Column~(1): facility-level clustering. Column~(2): state-level clustering. Column~(3): two-way (facility + year) clustering. Column~(4): $\\pm 3$ year event window. Column~(5): excludes 2020 (COVID year). RI $p$-values from 500 permutations of inspection timing. Pre-trend Wald test: joint significance of $t = -5$ through $t = -2$ event-study coefficients. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab6, file.path(tables_dir, "tab6_robust.tex"))

# ============================================================
# Table 7: Heterogeneity
# Note: Heterogeneity models also use V2 parameterization.
# Derive theta/tau from post_air and post_nonair.
# ============================================================
cat("=== Table 7: Heterogeneity ===\n")

r_high <- reparam_from_v2(rm$m_high)
r_low  <- reparam_from_v2(rm$m_low)

het_rows <- paste0(
"High enforcement & ",
fmt_coef(r_high$theta, r_high$theta_se, r_high$theta_p), " & ",
fmt_coef(r_high$tau, r_high$tau_se, r_high$tau_p), " & ",
format(r_high$n, big.mark = ","), " \\\\
& ", fmt_se(r_high$theta_se), " & ", fmt_se(r_high$tau_se), " & \\\\[3pt]
Low enforcement & ",
fmt_coef(r_low$theta, r_low$theta_se, r_low$theta_p), " & ",
fmt_coef(r_low$tau, r_low$tau_se, r_low$tau_p), " & ",
format(r_low$n, big.mark = ","), " \\\\
& ", fmt_se(r_low$theta_se), " & ", fmt_se(r_low$tau_se), " & \\\\")

tab7 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity Analysis}
\\label{tab:heterogeneity}
\\begin{tabular}{lccc}
\\toprule
& $\\hat{\\theta}$ (Post) & $\\hat{\\tau}$ (Post $\\times$ Air) & N \\\\
\\midrule
", het_rows, "
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Each row reports coefficients from a separate specification on the indicated subsample. High enforcement: top 15 states by CAA inspection count. All specifications include facility $\\times$ chemical $\\times$ medium and year fixed effects, clustered at facility level. $\\hat{\\theta}$ and $\\hat{\\tau}$ derived from the reparameterized specification. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tab7, file.path(tables_dir, "tab7_heterogeneity.tex"))

# ============================================================
# Table 8: Magnitudes and Environmental Relevance
# Levels model uses V2 parameterization (post_air + post_nonair on releases_w)
# post_air = levels change for air; post_nonair = levels change for non-air
# Offset = |post_nonair| / |post_air|
# ============================================================
cat("=== Table 8: Magnitudes ===\n")

m_lev <- rob_models$m_levels

# Get pre-inspection means for each medium
pre_means <- df[post == 0, .(pre_mean = mean(releases, na.rm = TRUE)),
                by = medium_cat]

# Levels coefficients
lev_air <- coef(m_lev)["post_air"]
lev_nonair <- coef(m_lev)["post_nonair"]
offset_pct <- abs(lev_nonair) / abs(lev_air) * 100

tab8 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Magnitudes and Environmental Relevance}
\\label{tab:magnitudes}
\\begin{tabular}{lcccc}
\\toprule
& Air & Water & Land & POTW \\\\
\\midrule
Pre-inspection mean (lbs) & ",
sprintf("%.0f", pre_means[medium_cat == "Air", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "Water", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "Land", pre_mean]), " & ",
sprintf("%.0f", pre_means[medium_cat == "POTW", pre_mean]), " \\\\[3pt]
Log-point change & ",
sprintf("%.4f", coef(models$medium_results$Air)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results$Water)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results$Land)["post"]), " & ",
sprintf("%.4f", coef(models$medium_results$POTW)["post"]), " \\\\
\\% change & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results$Air)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results$Water)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results$Land)["post"]) - 1) * 100), " & ",
sprintf("%.1f\\%%", (exp(coef(models$medium_results$POTW)["post"]) - 1) * 100), " \\\\[6pt]
\\midrule
\\multicolumn{5}{l}{\\textit{Levels specification (pounds)}} \\\\[3pt]
Air effect & \\multicolumn{4}{c}{", sprintf("%.1f", lev_air), " lbs ",
  fmt_se(se(m_lev)["post_air"]), "} \\\\
Non-air effect & \\multicolumn{4}{c}{", sprintf("%.1f", lev_nonair), " lbs ",
  fmt_se(se(m_lev)["post_nonair"]), "} \\\\[3pt]
\\midrule
\\multicolumn{5}{l}{\\textit{Offset calculation}} \\\\[3pt]
Non-air increase / Air decrease & \\multicolumn{4}{c}{",
sprintf("%.0f\\%%", offset_pct), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Pre-inspection means computed from the analysis sample prior to first CAA inspection. Log-point changes from the medium-specific regressions with CWA controls (Table~\\ref{tab:decomp}). Levels changes from the pooled specification with dependent variable in pounds (winsorized). The offset ratio measures what fraction of the air release reduction is offset by increased non-air releases. Standard errors in parentheses, clustered at the facility level.
\\end{minipage}
\\end{table}")

writeLines(tab8, file.path(tables_dir, "tab8_magnitudes.tex"))

# ============================================================
# Appendix Table: Composition Outcomes
# ============================================================
cat("=== Appendix: Composition Outcomes ===\n")

m_as <- models$m_airshare
m_tot <- models$m_total
m_ao <- models$m_air_only

tabA1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Composition Outcomes: Air Share, Total Releases, and Air-Only Releases}
\\label{tab:composition}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Air Share & Log Total & Log Air \\\\
\\midrule
Post & ",
  fmt_coef(coef(m_as)["post"], se(m_as)["post"], pvalue(m_as)["post"]), " & ",
  fmt_coef(coef(m_tot)["post"], se(m_tot)["post"], pvalue(m_tot)["post"]), " & ",
  fmt_coef(coef(m_ao)["post"], se(m_ao)["post"], pvalue(m_ao)["post"]), " \\\\
& ", fmt_se(se(m_as)["post"]), " & ", fmt_se(se(m_tot)["post"]), " & ",
  fmt_se(se(m_ao)["post"]), " \\\\[6pt]
CWA Inspected & ",
  fmt_coef(coef(m_as)["cwa_inspected"], se(m_as)["cwa_inspected"], pvalue(m_as)["cwa_inspected"]), " & ",
  fmt_coef(coef(m_tot)["cwa_inspected"], se(m_tot)["cwa_inspected"], pvalue(m_tot)["cwa_inspected"]), " & ",
  fmt_coef(coef(m_ao)["cwa_inspected"], se(m_ao)["cwa_inspected"], pvalue(m_ao)["cwa_inspected"]), " \\\\
& ", fmt_se(se(m_as)["cwa_inspected"]), " & ", fmt_se(se(m_tot)["cwa_inspected"]), " & ",
  fmt_se(se(m_ao)["cwa_inspected"]), " \\\\[6pt]
\\midrule
Observations & ", format(nobs(m_as), big.mark = ","), " & ",
  format(nobs(m_tot), big.mark = ","), " & ", format(nobs(m_ao), big.mark = ","), " \\\\
Facility $\\times$ Chemical FE & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes \\\\
Measurement bias & \\multicolumn{3}{c}{",
  sprintf("%.4f", coef(m_ao)["post"] - coef(m_tot)["post"]), " log points} \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Column~(1): dependent variable is Air/(Air + Water + Land + POTW), the air share of total releases. Column~(2): $\\log(\\text{total releases} + 1)$. Column~(3): $\\log(\\text{air releases} + 1)$. The measurement bias is the difference between the air-only and total log-point changes: if air falls faster than total, the gap reflects compositional reallocation rather than true abatement. All specifications at the facility $\\times$ chemical level with CWA controls. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tabA1, file.path(tables_dir, "tabA1_composition.tex"))

# ============================================================
# Appendix Table: Functional Form Robustness
# ============================================================
cat("=== Appendix: Functional Form ===\n")

r_ihs <- reparam_from_v2(rm$m_ihs)
r_levels <- reparam_from_v2(rm$m_levels)

tabA2_rows <- paste0(
"Log(Y+1) [baseline] & ",
  fmt_coef(r_fac$theta, r_fac$theta_se, r_fac$theta_p), " & ",
  fmt_coef(r_fac$tau, r_fac$tau_se, r_fac$tau_p), " & ",
  format(r_fac$n, big.mark = ","), " \\\\
& ", fmt_se(r_fac$theta_se), " & ", fmt_se(r_fac$tau_se), " & \\\\[3pt]
IHS(Y) & ",
  fmt_coef(r_ihs$theta, r_ihs$theta_se, r_ihs$theta_p), " & ",
  fmt_coef(r_ihs$tau, r_ihs$tau_se, r_ihs$tau_p), " & ",
  format(r_ihs$n, big.mark = ","), " \\\\
& ", fmt_se(r_ihs$theta_se), " & ", fmt_se(r_ihs$tau_se), " & \\\\[3pt]
Levels (lbs) & ",
  fmt_coef(r_levels$theta, r_levels$theta_se, r_levels$theta_p), " & ",
  fmt_coef(r_levels$tau, r_levels$tau_se, r_levels$tau_p), " & ",
  format(r_levels$n, big.mark = ","), " \\\\
& ", fmt_se(r_levels$theta_se), " & ", fmt_se(r_levels$tau_se), " & \\\\")

tabA2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Functional Form Robustness}
\\label{tab:funcform}
\\begin{tabular}{lccc}
\\toprule
& $\\hat{\\theta}$ (Post) & $\\hat{\\tau}$ (Post $\\times$ Air) & N \\\\
\\midrule
", tabA2_rows, "
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} All specifications include facility $\\times$ chemical $\\times$ medium and year fixed effects, clustered at the facility level. IHS = inverse hyperbolic sine transformation. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tabA2, file.path(tables_dir, "tabA2_funcform.tex"))

# ============================================================
# Appendix Table: Extensive Margin
# ============================================================
cat("=== Appendix: Extensive Margin ===\n")

m_el <- models$m_ext_land
m_ew <- models$m_ext_water

tabA3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Extensive Margin: Probability of Any Release by Medium}
\\label{tab:extensive}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& Pr(Land $> 0$) & Pr(Water $> 0$) \\\\
\\midrule
Post & ",
  fmt_coef(coef(m_el)["post"], se(m_el)["post"], pvalue(m_el)["post"]), " & ",
  fmt_coef(coef(m_ew)["post"], se(m_ew)["post"], pvalue(m_ew)["post"]), " \\\\
& ", fmt_se(se(m_el)["post"]), " & ", fmt_se(se(m_ew)["post"]), " \\\\[6pt]
CWA Inspected & ",
  fmt_coef(coef(m_el)["cwa_inspected"], se(m_el)["cwa_inspected"], pvalue(m_el)["cwa_inspected"]), " & ",
  fmt_coef(coef(m_ew)["cwa_inspected"], se(m_ew)["cwa_inspected"], pvalue(m_ew)["cwa_inspected"]), " \\\\
& ", fmt_se(se(m_el)["cwa_inspected"]), " & ", fmt_se(se(m_ew)["cwa_inspected"]), " \\\\[6pt]
\\midrule
Observations & ", format(nobs(m_el), big.mark = ","), " & ", format(nobs(m_ew), big.mark = ","), " \\\\
Facility $\\times$ Chemical FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Clustering & Facility & Facility \\\\
\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{0.3em}
\\footnotesize \\textit{Notes:} Linear probability models for whether a facility-chemical has any positive release in a given medium-year. Unit of analysis is facility $\\times$ chemical $\\times$ year. A positive coefficient on Post indicates that CAA inspections increase the probability of initiating releases through that medium. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{minipage}
\\end{table}")

writeLines(tabA3, file.path(tables_dir, "tabA3_extensive.tex"))

cat("\n=== All tables complete ===\n")
cat("Tables written to:", tables_dir, "\n")
list.files(tables_dir)
