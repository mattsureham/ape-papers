## 05_tables.R — Generate all LaTeX tables for Panic of 1907 study
## Memory-efficient: load panel for summary stats, then unload before model objects
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Helpers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))))
}

get_coef <- function(mod, varname) {
  if (varname %in% names(coef(mod))) {
    list(b = coef(mod)[varname], se = se(mod)[varname], p = pvalue(mod)[varname])
  } else {
    list(b = NA_real_, se = NA_real_, p = NA_real_)
  }
}

# ============================================================================
# PHASE 1: Compute summary stats from panel (then release memory)
# ============================================================================
cat("=== Computing summary statistics ===\n")
panel <- readRDS(file.path(data_dir, "analysis_data.rds"))

summ_by_panic <- panel[, .(
  N = .N,
  mean_age = mean(age_1900),
  pct_white = mean(white) * 100,
  pct_foreign = mean(foreign_born) * 100,
  pct_literate = mean(literate_1900) * 100,
  pct_married = mean(married_1900) * 100,
  pct_farm = mean(on_farm_1900) * 100,
  pct_owner = mean(owner_1900) * 100,
  mean_occ_1900 = mean(occscore_1900),
  sd_occ_1900 = sd(occscore_1900),
  mean_occ_1910 = mean(occscore_1910),
  sd_occ_1910 = sd(occscore_1910),
  mean_delta = mean(delta_occscore),
  sd_delta = sd(delta_occscore),
  pct_banking = mean(banking_dependent) * 100
), by = panic_severity]
setorder(summ_by_panic, panic_severity)

full <- panel[, .(
  N = .N,
  mean_age = mean(age_1900),
  pct_white = mean(white) * 100,
  pct_foreign = mean(foreign_born) * 100,
  pct_literate = mean(literate_1900) * 100,
  pct_married = mean(married_1900) * 100,
  pct_farm = mean(on_farm_1900) * 100,
  pct_owner = mean(owner_1900) * 100,
  mean_occ_1900 = mean(occscore_1900),
  sd_occ_1900 = sd(occscore_1900),
  mean_occ_1910 = mean(occscore_1910),
  sd_occ_1910 = sd(occscore_1910),
  mean_delta = mean(delta_occscore),
  sd_delta = sd(delta_occscore),
  pct_banking = mean(banking_dependent) * 100
)]

# Compute SDs for SDE table
sd_delta <- sd(panel$delta_occscore)
sd_own <- sd(panel$delta_ownership, na.rm = TRUE)
sd_ag <- sd(panel[sector == "Agriculture", delta_occscore])
sd_na <- sd(panel[sector != "Agriculture", delta_occscore])
n_total <- nrow(panel)

# Release the big panel
rm(panel); gc()

# ============================================================================
# TABLE 1: Summary Statistics by Panic Severity
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

low <- summ_by_panic[panic_severity == 1]
mod <- summ_by_panic[panic_severity == 2]
core <- summ_by_panic[panic_severity == 3]

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Panic of 1907 Severity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l cccc}\n",
  "\\toprule\n",
  " & Low (1) & Moderate (2) & Core (3) & Full Sample \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Demographics (1900)}} \\\\\n",
  sprintf("Age & %s & %s & %s & %s \\\\\n",
          fmt(low$mean_age, 1), fmt(mod$mean_age, 1), fmt(core$mean_age, 1), fmt(full$mean_age, 1)),
  sprintf("White (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_white, 1), fmt(mod$pct_white, 1), fmt(core$pct_white, 1), fmt(full$pct_white, 1)),
  sprintf("Foreign born (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_foreign, 1), fmt(mod$pct_foreign, 1), fmt(core$pct_foreign, 1), fmt(full$pct_foreign, 1)),
  sprintf("Literate (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_literate, 1), fmt(mod$pct_literate, 1), fmt(core$pct_literate, 1), fmt(full$pct_literate, 1)),
  sprintf("Married (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_married, 1), fmt(mod$pct_married, 1), fmt(core$pct_married, 1), fmt(full$pct_married, 1)),
  sprintf("On farm (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_farm, 1), fmt(mod$pct_farm, 1), fmt(core$pct_farm, 1), fmt(full$pct_farm, 1)),
  sprintf("Homeowner (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_owner, 1), fmt(mod$pct_owner, 1), fmt(core$pct_owner, 1), fmt(full$pct_owner, 1)),
  sprintf("Banking-dep.\\ sector (\\%%) & %s & %s & %s & %s \\\\\n",
          fmt(low$pct_banking, 1), fmt(mod$pct_banking, 1), fmt(core$pct_banking, 1), fmt(full$pct_banking, 1)),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Occupational Income Score}} \\\\\n",
  sprintf("Occscore 1900 & %s & %s & %s & %s \\\\\n",
          fmt(low$mean_occ_1900, 2), fmt(mod$mean_occ_1900, 2), fmt(core$mean_occ_1900, 2), fmt(full$mean_occ_1900, 2)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(low$sd_occ_1900, 2), fmt(mod$sd_occ_1900, 2), fmt(core$sd_occ_1900, 2), fmt(full$sd_occ_1900, 2)),
  sprintf("Occscore 1910 & %s & %s & %s & %s \\\\\n",
          fmt(low$mean_occ_1910, 2), fmt(mod$mean_occ_1910, 2), fmt(core$mean_occ_1910, 2), fmt(full$mean_occ_1910, 2)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(low$sd_occ_1910, 2), fmt(mod$sd_occ_1910, 2), fmt(core$sd_occ_1910, 2), fmt(full$sd_occ_1910, 2)),
  sprintf("$\\Delta$ Occscore & %s & %s & %s & %s \\\\\n",
          fmt(low$mean_delta, 3), fmt(mod$mean_delta, 3), fmt(core$mean_delta, 3), fmt(full$mean_delta, 3)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(low$sd_delta, 2), fmt(mod$sd_delta, 2), fmt(core$sd_delta, 2), fmt(full$sd_delta, 2)),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          fmt0(low$N), fmt0(mod$N), fmt0(core$N), fmt0(full$N)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample consists of prime-age men (18--50 in 1900) successfully linked across the 1900 and 1910 censuses via the IPUMS Machine Learning Linked Panel (MLP). Panic severity classifications follow Wicker (2000) and Moen and Tallman (1992): Core (3) includes states with trust company failures and widespread bank runs (NY, NJ, CT, PA, MA, RI); Moderate (2) includes states with secondary bank suspensions and clearing house certificate issuance; Low (1) includes all remaining states with minimal direct banking disruption. Banking-dependent sectors include manufacturing (OCC1950 500--699), trade (200--299), services (300--399), and clerical (800--899). Standard deviations in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("  tab1_summary.tex written\n")

# ============================================================================
# PHASE 2: Load model results (without panel)
# ============================================================================
gc()
results <- readRDS(file.path(data_dir, "main_results.rds"))

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

m1 <- results$m1_bivariate
m2 <- results$m2_controls
m3 <- results$m3_factor
m5 <- results$m5_ddd

c1 <- get_coef(m1, "panic_severity")
c2 <- get_coef(m2, "panic_severity")
c3_mod <- get_coef(m3, "panic_severity::2")
c3_core <- get_coef(m3, "panic_severity::3")
c5_bd <- get_coef(m5, "banking_dependentTRUE")
c5_int <- get_coef(m5, "panic_severity:banking_dependentTRUE")

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Panic of 1907 Severity on Occupational Income Change}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Bivariate & Controls & Factor & DDD \\\\\n",
  "\\midrule\n",
  sprintf("Panic severity & %s%s & %s%s & & \\\\\n",
          fmt(c1$b, 4), stars(c1$p), fmt(c2$b, 4), stars(c2$p)),
  sprintf(" & (%s) & (%s) & & \\\\\n", fmt(c1$se, 4), fmt(c2$se, 4)),
  sprintf("Moderate (vs.\\ Low) & & & %s%s & \\\\\n",
          fmt(c3_mod$b, 4), stars(c3_mod$p)),
  sprintf(" & & & (%s) & \\\\\n", fmt(c3_mod$se, 4)),
  sprintf("Core (vs.\\ Low) & & & %s%s & \\\\\n",
          fmt(c3_core$b, 4), stars(c3_core$p)),
  sprintf(" & & & (%s) & \\\\\n", fmt(c3_core$se, 4)),
  sprintf("Banking-dependent & & & & %s%s \\\\\n",
          fmt(c5_bd$b, 4), stars(c5_bd$p)),
  sprintf(" & & & & (%s) \\\\\n", fmt(c5_bd$se, 4)),
  sprintf("Panic $\\times$ Banking-dep. & & & & %s%s \\\\\n",
          fmt(c5_int$b, 4), stars(c5_int$p)),
  sprintf(" & & & & (%s) \\\\\n", fmt(c5_int$se, 4)),
  "\\midrule\n",
  "Controls & No & Yes & Yes & Yes \\\\\n",
  "State FE & No & No & No & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          fmt0(nobs(m1)), fmt0(nobs(m2)), fmt0(nobs(m3)), fmt0(nobs(m5))),
  sprintf("$R^2$ & %s & %s & %s & %s \\\\\n",
          fmt(fitstat(m1, "r2")[[1]], 4),
          fmt(fitstat(m2, "r2")[[1]], 4),
          fmt(fitstat(m3, "r2")[[1]], 4),
          fmt(fitstat(m5, "r2")[[1]], 4)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is $\\Delta$Occscore $=$ Occscore$_{1910}$ $-$ Occscore$_{1900}$. Columns (1)--(3) exploit cross-state variation in Panic severity; column (4) includes state fixed effects and identifies from the within-state, across-sector interaction between panic exposure and banking dependence (the DDD specification). Panic severity is a 3-level ordinal variable (1 = Low, 2 = Moderate, 3 = Core) based on Wicker (2000) and Moen and Tallman (1992). Banking-dependent sectors (manufacturing, trade, services, clerical) relied on trust company and commercial bank credit for working capital. Controls include age, age$^2$, race, foreign-born status, literacy, marital status, and initial occupational score. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))
cat("  tab2_main.tex written\n")

# ============================================================================
# TABLE 3: Sector Heterogeneity + Home Ownership Mechanism
# ============================================================================
cat("=== Table 3: Mechanism ===\n")

m8_ag <- results$m8_agriculture
m8_nonag <- results$m8_nonag
m8_bank <- results$m8_banking
m7_xs <- results$m7_ownership_xs
m7_ddd <- results$m7_ownership_ddd

c_ag <- get_coef(m8_ag, "panic_severity")
c_nonag <- get_coef(m8_nonag, "panic_severity")
c_bank <- get_coef(m8_bank, "panic_severity")
c_own_xs <- get_coef(m7_xs, "panic_severity")
c_own_ddd <- get_coef(m7_ddd, "panic_severity:banking_dependentTRUE")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Sector Heterogeneity, Falsification, and Home Ownership Mechanism}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Agriculture & Non-Agric. & Banking-Dep. & $\\Delta$Ownership & $\\Delta$Ownership \\\\\n",
  " & $\\Delta$Occscore & $\\Delta$Occscore & $\\Delta$Occscore & (Cross-state) & (DDD) \\\\\n",
  "\\midrule\n",
  sprintf("Panic severity & %s%s & %s%s & %s%s & %s%s & \\\\\n",
          fmt(c_ag$b, 4), stars(c_ag$p),
          fmt(c_nonag$b, 4), stars(c_nonag$p),
          fmt(c_bank$b, 4), stars(c_bank$p),
          fmt(c_own_xs$b, 5), stars(c_own_xs$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & \\\\\n",
          fmt(c_ag$se, 4), fmt(c_nonag$se, 4), fmt(c_bank$se, 4), fmt(c_own_xs$se, 5)),
  sprintf("Panic $\\times$ Banking-dep. & & & & & %s%s \\\\\n",
          fmt(c_own_ddd$b, 5), stars(c_own_ddd$p)),
  sprintf(" & & & & & (%s) \\\\\n", fmt(c_own_ddd$se, 5)),
  "\\midrule\n",
  "Controls & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State FE & No & No & No & No & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          fmt0(nobs(m8_ag)), fmt0(nobs(m8_nonag)), fmt0(nobs(m8_bank)),
          fmt0(nobs(m7_xs)), fmt0(nobs(m7_ddd))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(3) estimate the cross-state effect of Panic severity on $\\Delta$Occscore by sector: agriculture (column 1, falsification), non-agriculture (column 2), and banking-dependent sectors only (column 3). Agriculture, which relied less on formal banking credit, should show smaller effects --- this serves as a falsification test. Columns (4)--(5) use the change in home ownership (OWNERSHP in 1910 vs.\\ 1900) as the dependent variable. Column (5) uses the DDD specification with state FE. All specifications include demographic controls. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:mechanism}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(table_dir, "tab3_mechanism.tex"))
cat("  tab3_mechanism.tex written\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — compute while results are loaded
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Cross-state main
xs_b <- coef(results$m2_controls)["panic_severity"]
xs_se <- se(results$m2_controls)["panic_severity"]
sde_xs <- xs_b / sd_delta
se_sde_xs <- xs_se / sd_delta

# DDD interaction
ddd_b <- coef(results$m5_ddd)["panic_severity:banking_dependentTRUE"]
ddd_se <- se(results$m5_ddd)["panic_severity:banking_dependentTRUE"]
sde_ddd <- ddd_b / sd_delta
se_sde_ddd <- ddd_se / sd_delta

# Agriculture
ag_b <- coef(results$m8_agriculture)["panic_severity"]
ag_se <- se(results$m8_agriculture)["panic_severity"]
sde_ag <- ag_b / sd_ag
se_sde_ag <- ag_se / sd_ag

# Non-agriculture
na_b <- coef(results$m8_nonag)["panic_severity"]
na_se <- se(results$m8_nonag)["panic_severity"]
sde_na <- na_b / sd_na
se_sde_na <- na_se / sd_na

# Ownership
own_b <- coef(results$m7_ownership_xs)["panic_severity"]
own_se <- se(results$m7_ownership_xs)["panic_severity"]
sde_own <- own_b / sd_own
se_sde_own <- own_se / sd_own

# Release main results
rm(results); gc()

# ============================================================================
# TABLE 4: Robustness Checks
# ============================================================================
cat("=== Table 4: Robustness ===\n")
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

r1x <- robustness$r1_no_ny_xs
r1d <- robustness$r1_no_ny_ddd
r2x <- robustness$r2_binary_xs
r3x <- robustness$r3_urban_xs
r4x <- robustness$r4_placebo_xs
r5bx <- robustness$r5b_stayers_xs

cr1x <- get_coef(r1x, "panic_severity")
cr1d <- get_coef(r1d, "panic_severity:banking_dependentTRUE")
cr2x <- get_coef(r2x, "core_panic")
cr3x <- get_coef(r3x, "panic_severity")
cr4x <- get_coef(r4x, "panic_severity")
cr5bx <- get_coef(r5bx, "panic_severity")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  " & Excl.\\ NY & Excl.\\ NY & Binary & +Farm & Placebo: & Stayers \\\\\n",
  " & (XS) & (DDD) & Treatment & Share & $\\Delta$Lit. & Only \\\\\n",
  "\\midrule\n",
  sprintf("Panic severity & %s%s & & & %s%s & %s%s & %s%s \\\\\n",
          fmt(cr1x$b, 4), stars(cr1x$p),
          fmt(cr3x$b, 4), stars(cr3x$p),
          fmt(cr4x$b, 5), stars(cr4x$p),
          fmt(cr5bx$b, 4), stars(cr5bx$p)),
  sprintf(" & (%s) & & & (%s) & (%s) & (%s) \\\\\n",
          fmt(cr1x$se, 4), fmt(cr3x$se, 4), fmt(cr4x$se, 5), fmt(cr5bx$se, 4)),
  sprintf("Panic $\\times$ Banking-dep. & & %s%s & & & & \\\\\n",
          fmt(cr1d$b, 4), stars(cr1d$p)),
  sprintf(" & & (%s) & & & & \\\\\n", fmt(cr1d$se, 4)),
  sprintf("Core panic (binary) & & & %s%s & & & \\\\\n",
          fmt(cr2x$b, 4), stars(cr2x$p)),
  sprintf(" & & & (%s) & & & \\\\\n", fmt(cr2x$se, 4)),
  "\\midrule\n",
  "Controls & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "State FE & No & Yes & No & No & No & No \\\\\n",
  sprintf("Dep.\\ var. & $\\Delta$Occ & $\\Delta$Occ & $\\Delta$Occ & $\\Delta$Occ & $\\Delta$Lit & $\\Delta$Occ \\\\\n"),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt0(nobs(r1x)), fmt0(nobs(r1d)), fmt0(nobs(r2x)),
          fmt0(nobs(r3x)), fmt0(nobs(r4x)), fmt0(nobs(r5bx))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) drops New York, the dominant core-panic state. Column (2) reports the DDD interaction excluding New York (with state FE). Column (3) uses a binary treatment (core panic = 1, all others = 0). Column (4) adds county-level farm share as a proxy for urbanization. Column (5) is a placebo: the dependent variable is the change in literacy status (1910 vs.\\ 1900), which should not be directly affected by a financial panic. Column (6) restricts to individuals who remained in the same state between 1900 and 1910. All specifications include demographic controls. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))
cat("  tab4_robustness.tex written\n")

rm(robustness); gc()

# ============================================================================
# Write TABLE F1 (SDE values computed earlier while main results were loaded)
# ============================================================================

classify <- function(s) {
  if (is.na(s)) return("---")
  as <- abs(s)
  if (as < 0.005) return("Null")
  if (as < 0.05) return("Small")
  if (as < 0.15) return("Moderate")
  return("Large")
}

make_row <- function(label, b, se_b, sd_y, sde, se_sde) {
  sprintf("%s & %s & %s & --- & %s & %s & %s & %s",
          label, fmt(b, 4), fmt(se_b, 4), fmt(sd_y, 3),
          fmt(sde, 4), fmt(se_sde, 4), classify(sde))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the Panic of 1907 cause lasting occupational scarring for workers in banking-dependent sectors of affected states? ",
  "\\textbf{Policy mechanism:} The Panic originated with trust company failures in New York in October 1907, cascading through the correspondent banking network to suspend payments, freeze credit, and disrupt commercial activity in states with significant banking exposure; workers in banking-dependent sectors (manufacturing, trade, services) experienced layoffs and occupational dislocation that persisted through the 1910 census. ",
  "\\textbf{Outcome:} Change in occupational income score (OCCSCORE) between the 1900 and 1910 decennial censuses. ",
  "\\textbf{Treatment:} State-level Panic of 1907 severity, a 3-level ordinal variable (Low/Moderate/Core) based on Wicker (2000) and Moen and Tallman (1992). ",
  "\\textbf{Data:} IPUMS Machine Learning Linked Panel (MLP) linking individuals across the 1900 and 1910 full-count censuses, with ", fmt0(n_total), " prime-age men. ",
  "\\textbf{Method:} First-difference with state fixed effects (DDD specification), standard errors clustered at the state level. ",
  "\\textbf{Sample:} Prime-age men (18--50 in 1900) successfully linked across censuses via the MLP algorithm. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the dependent variable. ",
  "Classification follows magnitude: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Cross-State}} \\\\\n",
  make_row("$\\Delta$Occscore (ordinal)", xs_b, xs_se, sd_delta, sde_xs, se_sde_xs), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: DDD (State FE)}} \\\\\n",
  make_row("Panic $\\times$ Banking-dep.", ddd_b, ddd_se, sd_delta, sde_ddd, se_sde_ddd), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel C: Mechanisms and Falsification}} \\\\\n",
  make_row("$\\Delta$Ownership (XS)", own_b, own_se, sd_own, sde_own, se_sde_own), " \\\\\n",
  make_row("$\\Delta$Occ.\\ (Agric., falsif.)", ag_b, ag_se, sd_ag, sde_ag, se_sde_ag), " \\\\\n",
  make_row("$\\Delta$Occ.\\ (Non-agric.)", na_b, na_se, sd_na, sde_na, se_sde_na), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:sde}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("  tabF1_sde.tex written\n")

cat("\nAll tables generated:\n")
for (f in list.files(table_dir, pattern = "\\.tex$")) {
  cat("  ", f, "\n")
}
