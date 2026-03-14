## 05_tables.R — Generate all LaTeX tables for apep_0689

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_individual.rds"))
models_main <- readRDS(file.path(data_dir, "models_main.rds"))
models_mechanism <- readRDS(file.path(data_dir, "models_mechanism.rds"))
models_income <- readRDS(file.path(data_dir, "models_income.rds"))
models_race <- readRDS(file.path(data_dir, "models_race.rds"))
models_robust <- readRDS(file.path(data_dir, "models_robustness.rds"))

# Helper
fmt_coef <- function(model, var, digits = 4) {
  ct <- coeftable(model)
  idx <- grep(paste0("^", var), rownames(ct))
  if (length(idx) == 0) return(list(est = "---", se = "", stars = ""))
  est <- ct[idx[1], "Estimate"]
  se <- ct[idx[1], "Std. Error"]
  pval <- ct[idx[1], "Pr(>|t|)"]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  list(est = sprintf(paste0("%.", digits, "f%s"), est, stars),
       se = sprintf(paste0("(%.", digits, "f)"), se),
       raw_est = est, raw_se = se, raw_p = pval)
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1 ===\n")

make_summ <- function(d, label) {
  data.frame(
    Group = label,
    N = format(nrow(d), big.mark = ","),
    DenialRate = sprintf("%.3f", mean(d$denied)),
    IntRate = sprintf("%.2f", mean(d$interest_rate[d$denied == 0], na.rm = TRUE)),
    Income = sprintf("%.0f", mean(d$income, na.rm = TRUE)),
    LoanAmt = sprintf("%.0f", mean(d$loan_amount, na.rm = TRUE)),
    Minority = sprintf("%.2f", mean(d$race_minority, na.rm = TRUE)),
    TractInc = sprintf("%.0f", mean(d$median_incomeE, na.rm = TRUE)),
    TractPov = sprintf("%.3f", mean(d$pct_poverty, na.rm = TRUE)),
    CoastDist = sprintf("%.1f", mean(d$coast_dist_km, na.rm = TRUE))
  )
}

s1 <- make_summ(df[coastal_10km == 1], "Coastal ($\\leq$10km)")
s2 <- make_summ(df[coastal_10km == 0], "Inland ($>$10km)")
s3 <- make_summ(df, "Full Sample")

tab1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics: Coastal vs.\\ Inland Census Tracts}\n",
  "\\label{tab:summary}\n\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & Coastal ($\\leq$10km) & Inland ($>$10km) & Full Sample \\\\\n\\hline\n",
  "Denial Rate & ", s1$DenialRate, " & ", s2$DenialRate, " & ", s3$DenialRate, " \\\\\n",
  "Interest Rate (\\%) & ", s1$IntRate, " & ", s2$IntRate, " & ", s3$IntRate, " \\\\\n",
  "Applicant Income (\\$K) & ", s1$Income, " & ", s2$Income, " & ", s3$Income, " \\\\\n",
  "Loan Amount (\\$K) & ", sprintf("%.0f", as.numeric(s1$LoanAmt)/1000), " & ", sprintf("%.0f", as.numeric(s2$LoanAmt)/1000), " & ", sprintf("%.0f", as.numeric(s3$LoanAmt)/1000), " \\\\\n",
  "Minority Applicant Share & ", s1$Minority, " & ", s2$Minority, " & ", s3$Minority, " \\\\\n",
  "Tract Median Income (\\$K) & ", sprintf("%.0f", as.numeric(s1$TractInc)/1000), " & ", sprintf("%.0f", as.numeric(s2$TractInc)/1000), " & ", sprintf("%.0f", as.numeric(s3$TractInc)/1000), " \\\\\n",  # TractInc is in raw dollars, /1000 for display
  "Tract Poverty Rate & ", s1$TractPov, " & ", s2$TractPov, " & ", s3$TractPov, " \\\\\n",
  "Mean Distance to Coast (km) & ", s1$CoastDist, " & ", s2$CoastDist, " & ", s3$CoastDist, " \\\\\n",
  "\\hline\n",
  "N Applications & ", s1$N, " & ", s2$N, " & ", s3$N, " \\\\\n",
  "N Tracts & ", format(length(unique(df$tract_fips[df$coastal_10km == 1])), big.mark=","), " & ",
  format(length(unique(df$tract_fips[df$coastal_10km == 0])), big.mark=","), " & ",
  format(length(unique(df$tract_fips)), big.mark=","), " \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Data are HMDA mortgage applications in Florida (2022) for owner-occupied properties. Coastal tracts are defined as census tracts whose centroid is within 10 kilometers of the Florida coastline. Interest rates are for originated loans only. Income and loan amounts are in thousands of dollars.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("=== Table 2 ===\n")

tab2 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Flood Zone Proximity and Mortgage Market Outcomes}\n",
  "\\label{tab:main}\n\\small\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & \\multicolumn{4}{c}{Denied (=1)} & Interest Rate \\\\\n\\hline\n"
)

# Coastal coefficient row
est_row <- "Coastal ($\\leq$10km) "
se_row <- " "
for (m in models_main) {
  c <- fmt_coef(m, "coastal_10km")
  est_row <- paste0(est_row, "& ", c$est, " ")
  se_row <- paste0(se_row, "& ", c$se, " ")
}
tab2 <- paste0(tab2, est_row, "\\\\\n", se_row, "\\\\\n\\hline\n",
  "Applicant Controls & & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "County FE & & & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Tract Controls & & & & $\\checkmark$ & $\\checkmark$ \\\\\n\\hline\n"
)

# N and R2
n_row <- "N "; r2_row <- "$R^2$ "
for (m in models_main) {
  n_row <- paste0(n_row, "& ", format(nobs(m), big.mark=","), " ")
  r2_row <- paste0(r2_row, "& ", sprintf("%.3f", r2(m, "r2")), " ")
}
tab2 <- paste0(tab2, n_row, "\\\\\n", r2_row, "\\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Unit of observation is an individual mortgage application in Florida (2022). Columns (1)--(4) estimate a linear probability model for denial. Column (5) estimates the effect on interest rate (percentage points) for originated loans. Coastal ($\\leq$10km) is a binary indicator for tracts whose centroid is within 10 kilometers of the Florida coastline. Applicant controls: log income, log loan amount, purchase indicator, minority indicator. Tract controls: log tract median income, poverty rate, owner-occupancy rate, bachelor's degree share. Standard errors clustered at tract level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Denial Reason Mechanism
# ============================================================
cat("=== Table 3 ===\n")

tab3 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Denial Reason Decomposition: Cost Burden vs.\\ Creditworthiness}\n",
  "\\label{tab:mechanism}\n\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & DTI Ratio & Credit History & Collateral \\\\\n\\hline\n"
)

est3 <- "Coastal ($\\leq$10km) "; se3 <- " "; n3 <- "N "
for (m in models_mechanism) {
  c <- fmt_coef(m, "coastal_10km")
  est3 <- paste0(est3, "& ", c$est, " ")
  se3 <- paste0(se3, "& ", c$se, " ")
  n3 <- paste0(n3, "& ", format(nobs(m), big.mark=","), " ")
}

tab3 <- paste0(tab3, est3, "\\\\\n", se3, "\\\\\n\\hline\n",
  "Applicant Controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "County FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Tract Controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n\\hline\n",
  n3, "\\\\\n\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sample restricted to denied mortgage applications. Each column estimates whether coastal proximity shifts the \\textit{composition} of denial reasons. If mandatory flood insurance raises effective borrowing costs, column (1) should show a positive effect (insurance premiums increase debt-to-income ratios). Column (2) serves as a placebo: flood zone location should not affect applicant credit scores. All specifications include applicant controls, tract demographics, and county fixed effects. Standard errors clustered at tract level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab3, file.path(tables_dir, "tab3_mechanism.tex"))

# ============================================================
# Table 4: Income Heterogeneity
# ============================================================
cat("=== Table 4 ===\n")

tab4 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Heterogeneity by Applicant Income}\n",
  "\\label{tab:income}\n\\small\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Low Income & Middle Income & High Income \\\\\n\\hline\n"
)

est4 <- "Coastal ($\\leq$10km) "; se4 <- " "; n4 <- "N "; dr4 <- "Mean Denial Rate "
terciles <- c("Low", "Middle", "High")
for (i in seq_along(models_income)) {
  c <- fmt_coef(models_income[[i]], "coastal_10km")
  est4 <- paste0(est4, "& ", c$est, " ")
  se4 <- paste0(se4, "& ", c$se, " ")
  n4 <- paste0(n4, "& ", format(nobs(models_income[[i]]), big.mark=","), " ")
  dr4 <- paste0(dr4, "& ", sprintf("%.3f", mean(df$denied[df$income_tercile == terciles[i]])), " ")
}

tab4 <- paste0(tab4, est4, "\\\\\n", se4, "\\\\\n\\hline\n",
  "Applicant Controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "County FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Tract Controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n\\hline\n",
  n4, "\\\\\n", dr4, "\\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each column estimates the coastal proximity effect on denial for a different income tercile. If mandatory flood insurance creates a binding credit constraint, the effect should be concentrated among low-income borrowers. All specifications include county fixed effects and controls. Standard errors clustered at tract level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab4, file.path(tables_dir, "tab4_income.tex"))

# ============================================================
# Table 5: Robustness
# ============================================================
cat("=== Table 5 ===\n")

rob_specs <- list(
  list(m = models_robust[["5km"]], var = "coastal_5km", label = "5km threshold"),
  list(m = models_robust[["20km"]], var = "coastal_20km", label = "20km threshold"),
  list(m = models_robust[["Continuous"]], var = "log_coast_dist", label = "Log distance (cont.)"),
  list(m = models_robust[["Purchase"]], var = "coastal_10km", label = "Purchase loans"),
  list(m = models_robust[["Refinance"]], var = "coastal_10km", label = "Refinance loans"),
  list(m = models_robust[["Excl Miami"]], var = "coastal_10km", label = "Excl.\\ Miami-Dade")
)

tab5 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robust}\n\\small\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  "Specification & Estimate & SE & $p$-value & N \\\\\n\\hline\n"
)

for (r in rob_specs) {
  c <- fmt_coef(r$m, r$var)
  tab5 <- paste0(tab5, r$label, " & ",
    sprintf("%.4f", c$raw_est), " & ",
    sprintf("%.4f", c$raw_se), " & ",
    sprintf("%.3f", c$raw_p), " & ",
    format(nobs(r$m), big.mark=","), " \\\\\n")
}

tab5 <- paste0(tab5,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row re-estimates the main specification (column 4 of Table~\\ref{tab:main}) under alternative assumptions. All specifications include applicant controls, tract demographics, and county fixed effects. Standard errors clustered at tract level.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab5, file.path(tables_dir, "tab5_robust.tex"))

# ============================================================
# Table F1: SDE Appendix
# ============================================================
cat("=== Table F1 ===\n")

sd_denied <- sd(df$denied, na.rm = TRUE)
sd_interest <- sd(df$interest_rate[df$denied == 0], na.rm = TRUE)
df_denied <- df[denied == 1]
sd_dti <- sd(df_denied$denial_dti, na.rm = TRUE)
sd_credit <- sd(df_denied$denial_credit, na.rm = TRUE)

ct4 <- coeftable(models_main[["Full Controls"]])
ct5 <- coeftable(models_main[["Interest Rate"]])
ct_dti <- coeftable(models_mechanism[["DTI Ratio"]])
ct_cred <- coeftable(models_mechanism[["Credit History"]])

sde_data <- data.frame(
  Outcome = c("Mortgage Denial", "Interest Rate", "DTI Denial (denied only)", "Credit Denial (denied only)"),
  Beta = c(ct4["coastal_10km", 1], ct5["coastal_10km", 1], ct_dti["coastal_10km", 1], ct_cred["coastal_10km", 1]),
  SE = c(ct4["coastal_10km", 2], ct5["coastal_10km", 2], ct_dti["coastal_10km", 2], ct_cred["coastal_10km", 2]),
  SD_Y = c(sd_denied, sd_interest, sd_dti, sd_credit)
)
sde_data$SDE <- sde_data$Beta / sde_data$SD_Y
sde_data$SE_SDE <- sde_data$SE / sde_data$SD_Y

classify <- function(x) {
  if (x < -0.15) "Large negative"
  else if (x < -0.05) "Moderate negative"
  else if (x < -0.005) "Small negative"
  else if (x < 0.005) "Null"
  else if (x < 0.05) "Small positive"
  else if (x < 0.15) "Moderate positive"
  else "Large positive"
}
sde_data$Class <- sapply(sde_data$SDE, classify)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n\\small\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n"
)
for (i in 1:nrow(sde_data)) {
  tabF1 <- paste0(tabF1, sde_data$Outcome[i], " & ",
    sprintf("%.4f", sde_data$Beta[i]), " & ",
    sprintf("%.4f", sde_data$SE[i]), " & ",
    sprintf("%.3f", sde_data$SD_Y[i]), " & ",
    sprintf("%.4f", sde_data$SDE[i]), " & ",
    sprintf("%.4f", sde_data$SE_SDE[i]), " & ",
    sde_data$Class[i], " \\\\\n")
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} This table reports standardized effect sizes for the main outcomes. The research question is whether mandatory flood insurance in coastal Florida census tracts rations mortgage credit. Data are ", format(nrow(df), big.mark=","), " individual HMDA mortgage applications in Florida (2022), merged with ACS tract demographics and coastal proximity measures. Method: OLS with county fixed effects, applicant and tract controls. Treatment: binary indicator for tract within 10km of coast. SDE = $\\hat{\\beta} / \\text{SD}(Y)$. Classification refers to effect magnitude, not statistical significance.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
