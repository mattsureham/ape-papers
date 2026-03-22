## 05_tables.R — Generate all LaTeX tables
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ---- Load results ----
load(file.path(data_dir, "analysis_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

## ===========================================================================
## TABLE 1: Summary Statistics
## ===========================================================================

# Reshape sumstats for LaTeX
tab1_rows <- data.table(
  Variable = c("Fatal crashes", "Total fatalities",
                "Phone-distracted (\\%)", "Any distraction (\\%)",
                "Drunk driver present (\\%)", "Mean distance to border (km)"),
  Treated = c(
    format(sumstats[Side == "Treated", N], big.mark = ","),
    format(sumstats[Side == "Treated", Fatalities], big.mark = ","),
    sprintf("%.2f", sumstats[Side == "Treated", Pct_Phone_Distracted]),
    sprintf("%.2f", sumstats[Side == "Treated", Pct_Any_Distracted]),
    sprintf("%.2f", sumstats[Side == "Treated", Pct_Drunk_Driver]),
    sprintf("%.1f", sumstats[Side == "Treated", Mean_Dist_km])
  ),
  Control = c(
    format(sumstats[Side == "Control", N], big.mark = ","),
    format(sumstats[Side == "Control", Fatalities], big.mark = ","),
    sprintf("%.2f", sumstats[Side == "Control", Pct_Phone_Distracted]),
    sprintf("%.2f", sumstats[Side == "Control", Pct_Any_Distracted]),
    sprintf("%.2f", sumstats[Side == "Control", Pct_Drunk_Driver]),
    sprintf("%.1f", sumstats[Side == "Control", Mean_Dist_km])
  ),
  Full = c(
    format(sumstats[Side == "Full Sample", N], big.mark = ","),
    format(sumstats[Side == "Full Sample", Fatalities], big.mark = ","),
    sprintf("%.2f", sumstats[Side == "Full Sample", Pct_Phone_Distracted]),
    sprintf("%.2f", sumstats[Side == "Full Sample", Pct_Any_Distracted]),
    sprintf("%.2f", sumstats[Side == "Full Sample", Pct_Drunk_Driver]),
    sprintf("%.1f", sumstats[Side == "Full Sample", Mean_Dist_km])
  )
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Fatal Crashes within 50km of State Borders}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Treated Side & Control Side & Full Sample \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1_rows)) {
  tab1_tex <- paste0(tab1_tex,
    tab1_rows$Variable[i], " & ",
    tab1_rows$Treated[i], " & ",
    tab1_rows$Control[i], " & ",
    tab1_rows$Full[i], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sample includes all fatal crashes within 50km of state borders ",
  "where one state adopted a handheld cellphone ban between 2017--2021 and the neighboring ",
  "state did not. Data from NHTSA FARS 2015--2022. Phone-distracted includes FARS distraction ",
  "codes 5 (talking/listening), 6 (manipulating), and 15 (other cellular phone related). Treated side refers to the ",
  "state that adopted the ban.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_sumstats.tex"))
cat("Table 1 written.\n")

## ===========================================================================
## TABLE 2: Main Results — Diff-in-Disc across bandwidths
## ===========================================================================

# Helper for stars
star <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Main Results: Difference-in-Discontinuities at State Borders}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{4}{c}{Bandwidth (km)} \\\\\n",
  " \\cmidrule(lr){2-5}\n",
  " & 10 & 20 & 30 & 50 \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: All fatal crashes}} \\\\\n"
)

# Panel A: All crashes
for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "all_crashes"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "Treated $\\times$ Post", ""),
      " & ", sprintf("%.4f", r$coef), star(r$pval))
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# SEs
for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "all_crashes"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "", ""),
      " & (", sprintf("%.4f", r$se), ")")
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n[6pt]\n")

# Panel B: Phone-distracted
tab2_tex <- paste0(tab2_tex,
  "\\multicolumn{5}{l}{\\textit{Panel B: Phone-distracted crashes}} \\\\\n")

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "phone"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "Treated $\\times$ Post", ""),
      " & ", sprintf("%.4f", r$coef), star(r$pval))
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "phone"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      " & (", sprintf("%.4f", r$se), ")")
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n[6pt]\n")

# Panel C: Any distraction
tab2_tex <- paste0(tab2_tex,
  "\\multicolumn{5}{l}{\\textit{Panel C: Any distraction crashes}} \\\\\n")

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "distracted"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "Treated $\\times$ Post", ""),
      " & ", sprintf("%.4f", r$coef), star(r$pval))
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "distracted"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      " & (", sprintf("%.4f", r$se), ")")
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# Footer rows
tab2_tex <- paste0(tab2_tex,
  "\\hline\n",
  "Border-pair FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year-month FE & Yes & Yes & Yes & Yes \\\\\n"
)

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "all_crashes"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "Observations", ""),
      " & ", format(r$n_obs, big.mark = ","))
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

for (bw in c("10", "20", "30", "50")) {
  r <- table2_data[bandwidth == as.integer(bw) & outcome == "all_crashes"]
  if (nrow(r) > 0) {
    tab2_tex <- paste0(tab2_tex,
      ifelse(bw == "10", "Counties", ""),
      " & ", format(r$n_counties, big.mark = ","))
  }
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

tab2_tex <- paste0(tab2_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on Treated $\\times$ Post ",
  "from a county-month panel regression of crash counts on a treated-side indicator, ",
  "post-treatment indicator, and their interaction, with border-pair and year-month ",
  "fixed effects. Standard errors clustered at the state-county level in parentheses. ",
  "Phone-distracted crashes use FARS distraction codes 5, 6, 15. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ===========================================================================
## TABLE 3: Robustness Checks
## ===========================================================================

# Collect robustness results
rob_rows <- data.table(
  Specification = c(
    "Baseline (30km)",
    "Donut (2--30km)",
    "Linear distance control",
    "Quadratic distance control",
    "Pair-clustered SEs",
    "Placebo: pre-treatment",
    "Placebo: drunk driving"
  ),
  Coef = c(
    table2_data[bandwidth == 30 & outcome == "all_crashes", coef],
    robustness$donut$coef,
    robustness$dist_linear$coef,
    robustness$dist_quad$coef,
    coef(m_pair_cluster)["treated_side:post"],
    robustness$placebo_pre$coef,
    robustness$drunk_placebo$coef
  ),
  SE = c(
    table2_data[bandwidth == 30 & outcome == "all_crashes", se],
    robustness$donut$se,
    robustness$dist_linear$se,
    robustness$dist_quad$se,
    se(m_pair_cluster)["treated_side:post"],
    robustness$placebo_pre$se,
    robustness$drunk_placebo$se
  ),
  Pval = c(
    table2_data[bandwidth == 30 & outcome == "all_crashes", pval],
    pvalue(m_donut)["treated_side:post"],
    pvalue(m_dist_linear)["treated_side:post"],
    pvalue(m_dist_quad)["treated_side:post"],
    pvalue(m_pair_cluster)["treated_side:post"],
    robustness$placebo_pre$pval,
    robustness$drunk_placebo$pval
  )
)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE & $p$-value \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Sensitivity}} \\\\\n"
)

for (i in 1:5) {
  tab3_tex <- paste0(tab3_tex,
    rob_rows$Specification[i], " & ",
    sprintf("%.4f", rob_rows$Coef[i]), star(rob_rows$Pval[i]), " & (",
    sprintf("%.4f", rob_rows$SE[i]), ") & ",
    sprintf("%.3f", rob_rows$Pval[i]), " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Placebos}} \\\\\n"
)

for (i in 6:7) {
  tab3_tex <- paste0(tab3_tex,
    rob_rows$Specification[i], " & ",
    sprintf("%.4f", rob_rows$Coef[i]), star(rob_rows$Pval[i]), " & (",
    sprintf("%.4f", rob_rows$SE[i]), ") & ",
    sprintf("%.3f", rob_rows$Pval[i]), " \\\\\n")
}

# Add WCB if available
if (!is.null(robustness$boot_result)) {
  tab3_tex <- paste0(tab3_tex,
    "Wild cluster bootstrap $p$-value & \\multicolumn{3}{c}{",
    sprintf("%.3f", robustness$boot_result$pval), "} \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A shows sensitivity of the main result (all fatal crashes, ",
  "30km bandwidth) to alternative specifications. Panel B shows placebo tests: the pre-treatment ",
  "placebo applies a false treatment date two years before actual adoption; the drunk-driving ",
  "placebo uses crashes involving an intoxicated driver, which should not respond to cellphone bans. ",
  "All specifications include border-pair and year-month fixed effects. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))
cat("Table 3 written.\n")

## ===========================================================================
## TABLE 4: Pair-by-Pair Estimates
## ===========================================================================

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Border-Pair-Specific Estimates}\n",
  "\\label{tab:pairs}\n",
  "\\begin{tabular}{llcccc}\n",
  "\\hline\\hline\n",
  "Treated & Control & Coefficient & SE & $p$-value & $N$ \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(pair_dt)) {
  tab4_tex <- paste0(tab4_tex,
    pair_dt$treated[i], " & ",
    pair_dt$control[i], " & ",
    sprintf("%.4f", pair_dt$coef[i]), star(pair_dt$pval[i]), " & (",
    sprintf("%.4f", pair_dt$se[i]), ") & ",
    sprintf("%.3f", pair_dt$pval[i]), " & ",
    format(pair_dt$n_obs[i], big.mark = ","), " \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the difference-in-discontinuities estimate ",
  "for a single border pair (30km bandwidth). The specification includes year-month fixed ",
  "effects with standard errors clustered at the state-county level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_pairs.tex"))
cat("Table 4 written.\n")

## ===========================================================================
## TABLE F1: Standardized Effect Sizes (SDE) — APPENDIX
## ===========================================================================

# Compute SDE for main outcomes
# SDE = beta_hat / SD(Y) where SD(Y) is pre-treatment SD

county_month <- fread(file.path(data_dir, "analysis_county_month.csv"))
cm30 <- county_month[mean_dist <= 30]
cm30_pre <- cm30[post == 0]

sd_crashes <- sd(cm30_pre$n_crashes, na.rm = TRUE)
sd_phone <- sd(cm30_pre$n_phone, na.rm = TRUE)
sd_distracted <- sd(cm30_pre$n_distracted, na.rm = TRUE)

# Get coefficients from preferred spec (30km)
pref_all <- table2_data[bandwidth == 30 & outcome == "all_crashes"]
pref_phone <- table2_data[bandwidth == 30 & outcome == "phone"]
pref_dist <- table2_data[bandwidth == 30 & outcome == "distracted"]

sde_data <- data.table(
  Outcome = c("All fatal crashes", "Phone-distracted crashes", "Any distraction crashes"),
  beta = c(pref_all$coef, pref_phone$coef, pref_dist$coef),
  se_beta = c(pref_all$se, pref_phone$se, pref_dist$se),
  sd_y = c(sd_crashes, sd_phone, sd_distracted)
)

sde_data[, SDE := beta / sd_y]
sde_data[, SE_SDE := se_beta / sd_y]

# Classification
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_data[, Classification := sapply(SDE, classify_sde)]

cat("\n=== SDE Table ===\n")
print(sde_data)

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level handheld cellphone bans reduce fatal traffic crashes near state borders where the policy discontinuously changes? ",
  "\\textbf{Policy mechanism:} Handheld cellphone bans prohibit drivers from holding a phone while operating a vehicle, aiming to reduce distracted driving by shifting phone use to hands-free modes or eliminating it; enforcement typically involves primary-offense traffic stops. ",
  "\\textbf{Outcome definition:} Monthly counts of fatal motor vehicle crashes (FARS), phone-distracted fatal crashes (FARS distraction codes 5, 6, 15), and any-distraction fatal crashes at the county level within 30km of treated state borders. ",
  "\\textbf{Treatment:} Binary; state-level adoption of handheld cellphone ban between 2017--2021. ",
  "\\textbf{Data:} NHTSA Fatality Analysis Reporting System, 2015--2022, county-month panel, ",
  format(pref_all$n_obs, big.mark = ","), " observations across ",
  format(pref_all$n_counties, big.mark = ","), " counties in 8 border pairs. ",
  "\\textbf{Method:} Difference-in-discontinuities with border-pair and year-month fixed effects; standard errors clustered at state-county level; robustness via wild cluster bootstrap, donut RDD, and distance polynomial controls. ",
  "\\textbf{Sample:} Fatal crashes within 30km of state borders where one state adopted a handheld cellphone ban and the neighboring state did not; restricted to continental U.S. with valid geocoded coordinates. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(sde_data)) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_data$Outcome[i], " & ",
    sprintf("%.4f", sde_data$beta[i]), " & ",
    sprintf("%.4f", sde_data$se_beta[i]), " & ",
    sprintf("%.4f", sde_data$sd_y[i]), " & ",
    sprintf("%.4f", sde_data$SDE[i]), " & ",
    sprintf("%.4f", sde_data$SE_SDE[i]), " & ",
    sde_data$Classification[i], " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
cat("Done.\n")
