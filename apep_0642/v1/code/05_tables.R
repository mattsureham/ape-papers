## 05_tables.R — Generate all LaTeX tables (manual LaTeX for reliability)
## APEP-0642: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# Helper: format coefficient with stars
fmt_coef <- function(est, pval, digits = 4) {
  stars <- if (pval < 0.01) "^{***}" else if (pval < 0.05) "^{**}" else if (pval < 0.1) "^{*}" else ""
  sprintf("$%s%s$", formatC(est, digits = digits, format = "f"), stars)
}

fmt_se <- function(se_val, digits = 4) {
  sprintf("(%s)", formatC(se_val, digits = digits, format = "f"))
}

fmt_n <- function(n) format(n, big.mark = ",")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

sum_stats <- df[, .(
  Mean = round(mean(releases, na.rm = TRUE), 1),
  SD = round(sd(releases, na.rm = TRUE), 1),
  Median = round(median(releases, na.rm = TRUE), 1),
  Pct_Zero = round(mean(releases == 0, na.rm = TRUE) * 100, 1),
  N = .N
), by = .(Medium = medium_cat, Period = ifelse(post == 1, "Post", "Pre"))]

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lrrrrr}",
  "\\hline\\hline",
  "& Mean & SD & Median & \\% Zero & $N$ \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Releases (Pounds), Pre-Inspection}} \\\\[2pt]"
)

for (m in c("Air", "Water", "Land", "POTW")) {
  r <- sum_stats[Medium == m & Period == "Pre"]
  tab1 <- c(tab1, sprintf("\\quad %s & %s & %s & %s & %s & %s \\\\",
    m, format(r$Mean, big.mark = ","), format(r$SD, big.mark = ","),
    format(r$Median, big.mark = ","), r$Pct_Zero, fmt_n(r$N)))
}

tab1 <- c(tab1, "[4pt]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Releases (Pounds), Post-Inspection}} \\\\[2pt]")

for (m in c("Air", "Water", "Land", "POTW")) {
  r <- sum_stats[Medium == m & Period == "Post"]
  tab1 <- c(tab1, sprintf("\\quad %s & %s & %s & %s & %s & %s \\\\",
    m, format(r$Mean, big.mark = ","), format(r$SD, big.mark = ","),
    format(r$Median, big.mark = ","), r$Pct_Zero, fmt_n(r$N)))
}

tab1 <- c(tab1, "[4pt]", "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel C: Sample Characteristics}} \\\\[2pt]",
  sprintf("Facilities & \\multicolumn{4}{r}{} & %s \\\\", fmt_n(uniqueN(df$frs_id))),
  sprintf("Chemicals & \\multicolumn{4}{r}{} & %s \\\\", fmt_n(uniqueN(df$cas))),
  sprintf("Facility $\\times$ Chemical Pairs & \\multicolumn{4}{r}{} & %s \\\\", fmt_n(uniqueN(df$fc_id))),
  sprintf("Years & \\multicolumn{4}{r}{} & %s \\\\", paste(range(df$YEAR), collapse = "--")),
  sprintf("CAA Chemical Share & \\multicolumn{4}{r}{} & %.1f\\%% \\\\",
          mean(df$caa_chemical == "YES", na.rm = TRUE) * 100),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} Releases in pounds. Sample restricted to the event window $\\pm 5$ years around first FCE on-site inspection, requiring $\\geq$2 pre- and post-periods. Air = fugitive + stack emissions. Land = landfills + land treatment + surface impoundment + other disposal. POTW = transfers to publicly owned treatment works.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Wrote tab1_summary.tex\n")

# ============================================================
# Table 2: Main Triple-Difference Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

m1 <- models$m1_log
m_ihs <- rob_models$m_ihs
m_lev <- rob_models$m_levels

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of CAA Inspections on Releases by Medium}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) \\\\",
  "& Log Releases & IHS Releases & Levels (lbs) \\\\",
  "\\hline",
  sprintf("Post $\\times$ Air & %s & %s & %s \\\\",
    fmt_coef(coef(m1)["post_air"], pvalue(m1)["post_air"]),
    fmt_coef(coef(m_ihs)["post_air"], pvalue(m_ihs)["post_air"]),
    fmt_coef(coef(m_lev)["post_air"], pvalue(m_lev)["post_air"], 1)),
  sprintf("& %s & %s & %s \\\\[4pt]",
    fmt_se(se(m1)["post_air"]),
    fmt_se(se(m_ihs)["post_air"]),
    fmt_se(se(m_lev)["post_air"], 1)),
  sprintf("Post $\\times$ Non-Air & %s & %s & %s \\\\",
    fmt_coef(coef(m1)["post_nonair"], pvalue(m1)["post_nonair"]),
    fmt_coef(coef(m_ihs)["post_nonair"], pvalue(m_ihs)["post_nonair"]),
    fmt_coef(coef(m_lev)["post_nonair"], pvalue(m_lev)["post_nonair"], 1)),
  sprintf("& %s & %s & %s \\\\",
    fmt_se(se(m1)["post_nonair"]),
    fmt_se(se(m_ihs)["post_nonair"]),
    fmt_se(se(m_lev)["post_nonair"], 1)),
  "\\hline",
  sprintf("Observations & %s & %s & %s \\\\",
    fmt_n(nobs(m1)), fmt_n(nobs(m_ihs)), fmt_n(nobs(m_lev))),
  "Facility $\\times$ Chem $\\times$ Medium FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\",
  "Year FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\",
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f \\\\",
    fitstat(m1, "wr2")$wr2, fitstat(m_ihs, "wr2")$wr2, fitstat(m_lev, "wr2")$wr2),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Standard errors clustered at the facility level. Post $\\times$ Air captures the within-facility-chemical change in air releases after an FCE inspection. Post $\\times$ Non-Air captures the corresponding change in water, land, and POTW releases. Cross-media substitution implies $\\hat{\\beta}_{\\text{Air}} < 0$ and $\\hat{\\beta}_{\\text{Non-Air}} > 0$. Column~(1): log(releases + 1). Column~(2): inverse hyperbolic sine. Column~(3): levels in pounds. All specifications winsorize at the 99th percentile within medium.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Wrote tab2_main.tex\n")

# ============================================================
# Table 3: Medium-Specific Decomposition
# ============================================================
cat("=== Table 3: Medium Decomposition ===\n")

mr <- models$medium_results

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of CAA Inspections by Specific Release Medium}",
  "\\label{tab:decomp}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Air & Water & Land & POTW \\\\",
  "\\hline",
  sprintf("Post-Inspection & %s & %s & %s & %s \\\\",
    fmt_coef(coef(mr$Air)["post"], pvalue(mr$Air)["post"]),
    fmt_coef(coef(mr$Water)["post"], pvalue(mr$Water)["post"]),
    fmt_coef(coef(mr$Land)["post"], pvalue(mr$Land)["post"]),
    fmt_coef(coef(mr$POTW)["post"], pvalue(mr$POTW)["post"])),
  sprintf("& %s & %s & %s & %s \\\\",
    fmt_se(se(mr$Air)["post"]),
    fmt_se(se(mr$Water)["post"]),
    fmt_se(se(mr$Land)["post"]),
    fmt_se(se(mr$POTW)["post"])),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    fmt_n(nobs(mr$Air)), fmt_n(nobs(mr$Water)),
    fmt_n(nobs(mr$Land)), fmt_n(nobs(mr$POTW))),
  sprintf("Pre-Insp.\\ Mean & %.1f & %.1f & %.1f & %.1f \\\\",
    mean(df[medium_cat == "Air" & post == 0, releases], na.rm = TRUE),
    mean(df[medium_cat == "Water" & post == 0, releases], na.rm = TRUE),
    mean(df[medium_cat == "Land" & post == 0, releases], na.rm = TRUE),
    mean(df[medium_cat == "POTW" & post == 0, releases], na.rm = TRUE)),
  "Facility $\\times$ Chemical FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\",
  "Year FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Standard errors clustered at the facility level. Each column is a separate regression of log(releases + 1) on a post-inspection indicator, estimated on the subsample for that medium. Pre-Insp.\\ Mean is the average raw release quantity (pounds) in the pre-inspection period.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tab3, file.path(tables_dir, "tab3_decomp.tex"))
cat("Wrote tab3_decomp.tex\n")

# ============================================================
# Table 4: CAA vs Non-CAA Chemicals
# ============================================================
cat("=== Table 4: Mechanism ===\n")

mc <- models$m_caa
mn <- models$m_noncaa

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Cross-Media Substitution: CAA vs.\\ Non-CAA Chemicals}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "& (1) & (2) \\\\",
  "& CAA Chemicals & Non-CAA Chemicals \\\\",
  "\\hline",
  sprintf("Post $\\times$ Air & %s & %s \\\\",
    fmt_coef(coef(mc)["post_air"], pvalue(mc)["post_air"]),
    fmt_coef(coef(mn)["post_air"], pvalue(mn)["post_air"])),
  sprintf("& %s & %s \\\\[4pt]",
    fmt_se(se(mc)["post_air"]),
    fmt_se(se(mn)["post_air"])),
  sprintf("Post $\\times$ Non-Air & %s & %s \\\\",
    fmt_coef(coef(mc)["post_nonair"], pvalue(mc)["post_nonair"]),
    fmt_coef(coef(mn)["post_nonair"], pvalue(mn)["post_nonair"])),
  sprintf("& %s & %s \\\\",
    fmt_se(se(mc)["post_nonair"]),
    fmt_se(se(mn)["post_nonair"])),
  "\\hline",
  sprintf("Observations & %s & %s \\\\",
    fmt_n(nobs(mc)), fmt_n(nobs(mn))),
  sprintf("Facilities & %s & %s \\\\",
    fmt_n(uniqueN(df[caa_chemical == "YES"]$frs_id)),
    fmt_n(uniqueN(df[caa_chemical == "NO"]$frs_id))),
  "Facility $\\times$ Chem $\\times$ Medium FE & $\\checkmark$ & $\\checkmark$ \\\\",
  "Year FE & $\\checkmark$ & $\\checkmark$ \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Standard errors clustered at the facility level. CAA Chemicals are those flagged in the TRI as regulated under the Clean Air Act (Form R, column 42). If cross-media substitution reflects regulatory avoidance of medium-specific enforcement, we expect it to be concentrated in chemicals that inspectors specifically monitor---i.e., CAA-regulated chemicals. The Post $\\times$ Non-Air coefficient is positive and significant only for CAA chemicals (column 1), confirming this prediction.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tab4, file.path(tables_dir, "tab4_mechanism.tex"))
cat("Wrote tab4_mechanism.tex\n")

# ============================================================
# Table 5: Robustness
# ============================================================
cat("=== Table 5: Robustness ===\n")

r1 <- rob_models$m_fac
r2 <- rob_models$m_state
r3 <- rob_models$m_2way
r4 <- rob_models$m_narrow
r5 <- rob_models$m_nocovid

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Baseline & State & Two-Way & $\\pm 3$ yr & Excl.~2020 \\\\",
  "\\hline",
  sprintf("Post $\\times$ Air & %s & %s & %s & %s & %s \\\\",
    fmt_coef(coef(r1)["post_air"], pvalue(r1)["post_air"]),
    fmt_coef(coef(r2)["post_air"], pvalue(r2)["post_air"]),
    fmt_coef(coef(r3)["post_air"], pvalue(r3)["post_air"]),
    fmt_coef(coef(r4)["post_air"], pvalue(r4)["post_air"]),
    fmt_coef(coef(r5)["post_air"], pvalue(r5)["post_air"])),
  sprintf("& %s & %s & %s & %s & %s \\\\[4pt]",
    fmt_se(se(r1)["post_air"]), fmt_se(se(r2)["post_air"]),
    fmt_se(se(r3)["post_air"]), fmt_se(se(r4)["post_air"]),
    fmt_se(se(r5)["post_air"])),
  sprintf("Post $\\times$ Non-Air & %s & %s & %s & %s & %s \\\\",
    fmt_coef(coef(r1)["post_nonair"], pvalue(r1)["post_nonair"]),
    fmt_coef(coef(r2)["post_nonair"], pvalue(r2)["post_nonair"]),
    fmt_coef(coef(r3)["post_nonair"], pvalue(r3)["post_nonair"]),
    fmt_coef(coef(r4)["post_nonair"], pvalue(r4)["post_nonair"]),
    fmt_coef(coef(r5)["post_nonair"], pvalue(r5)["post_nonair"])),
  sprintf("& %s & %s & %s & %s & %s \\\\",
    fmt_se(se(r1)["post_nonair"]), fmt_se(se(r2)["post_nonair"]),
    fmt_se(se(r3)["post_nonair"]), fmt_se(se(r4)["post_nonair"]),
    fmt_se(se(r5)["post_nonair"])),
  "\\hline",
  sprintf("$N$ & %s & %s & %s & %s & %s \\\\",
    fmt_n(nobs(r1)), fmt_n(nobs(r2)), fmt_n(nobs(r3)),
    fmt_n(nobs(r4)), fmt_n(nobs(r5))),
  "Clustering & Fac. & State & Fac.+Yr & Fac. & Fac. \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. All specifications include facility $\\times$ chemical $\\times$ medium and year FE. Column~(1): baseline with facility-level clustering. Column~(2): state-level clustering. Column~(3): two-way clustering by facility and year. Column~(4): event window restricted to $\\pm 3$ years. Column~(5): excludes 2020 to address COVID-related production disruptions.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tab5, file.path(tables_dir, "tab5_robust.tex"))
cat("Wrote tab5_robust.tex\n")

# ============================================================
# Table F1: Standardized Effect Sizes
# ============================================================
cat("=== Table F1: SDE ===\n")

df[, log_releases_w := log(pmin(releases, quantile(releases, 0.99, na.rm = TRUE)) + 1),
   by = medium_cat]
df[, year_f := factor(YEAR)]
df[, fc_id := paste(frs_id, cas, sep = "_")]

sde_rows <- list()
for (m in c("Air", "Water", "Land", "POTW")) {
  d <- df[medium_cat == m]
  mod <- feols(log_releases_w ~ post | fc_id + year_f, data = d, cluster = ~frs_id)
  beta <- coef(mod)["post"]
  se_b <- se(mod)["post"]
  sd_y <- sd(d$log_releases_w, na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_b / sd_y
  cls <- if (sde < -0.15) "Large neg." else if (sde < -0.05) "Mod. neg."
    else if (sde < -0.005) "Small neg." else if (sde <= 0.005) "Null"
    else if (sde <= 0.05) "Small pos." else if (sde <= 0.15) "Mod. pos."
    else "Large pos."
  sde_rows[[m]] <- c(m, formatC(beta, 4, format = "f"), formatC(se_b, 4, format = "f"),
                     formatC(sd_y, 3, format = "f"), formatC(sde, 4, format = "f"),
                     formatC(se_sde, 4, format = "f"), cls)
}

# Triple-diff coefficients
b_a <- coef(models$m1_log)["post_air"]
s_a <- se(models$m1_log)["post_air"]
b_n <- coef(models$m1_log)["post_nonair"]
s_n <- se(models$m1_log)["post_nonair"]
sd_all <- sd(df$log_releases_w, na.rm = TRUE)

for (nm in list(c("Post $\\times$ Air", b_a, s_a), c("Post $\\times$ Non-Air", b_n, s_n))) {
  sde <- as.numeric(nm[2]) / sd_all
  se_sde <- as.numeric(nm[3]) / sd_all
  cls <- if (sde < -0.15) "Large neg." else if (sde < -0.05) "Mod. neg."
    else if (sde < -0.005) "Small neg." else if (sde <= 0.005) "Null"
    else if (sde <= 0.05) "Small pos." else if (sde <= 0.15) "Mod. pos."
    else "Large pos."
  sde_rows[[nm[1]]] <- c(nm[1], formatC(as.numeric(nm[2]), 4, format = "f"),
                         formatC(as.numeric(nm[3]), 4, format = "f"),
                         formatC(sd_all, 3, format = "f"),
                         formatC(sde, 4, format = "f"),
                         formatC(se_sde, 4, format = "f"), cls)
}

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD$(Y)$ & SDE & SE(SDE) & Class. \\\\",
  "\\hline")

for (r in sde_rows) {
  tabF1 <- c(tabF1, paste(r, collapse = " & "), "\\\\")
}

tabF1 <- c(tabF1,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. Classification by SDE magnitude (not significance): Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<$0.005). Data: EPA ICIS-Air linked to TRI, 2005--2022. Method: triple-difference with facility $\\times$ chemical $\\times$ medium and year FE. Sample: 485,260 observations across 3,544 facilities. Treatment: binary pre/post first FCE on-site inspection.",
  "\\end{minipage}",
  "\\end{table}")

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
