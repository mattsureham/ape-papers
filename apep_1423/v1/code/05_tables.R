# 05_tables.R — Generate all tables including SDE appendix
source("00_packages.R")

boundary <- readRDS("../data/boundary_panel.rds")
analysis <- readRDS("../data/analysis_panel.rds")
main_models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

desc_vars <- c("pct_violation", "any_violation", "n_violation_qtrs", "is_major")
treated <- boundary[listed_303d == TRUE]
control <- boundary[listed_303d == FALSE]

tab1_rows <- list()
for (v in desc_vars) {
  t_mean <- mean(treated[[v]], na.rm = TRUE)
  t_sd <- sd(treated[[v]], na.rm = TRUE)
  c_mean <- mean(control[[v]], na.rm = TRUE)
  c_sd <- sd(control[[v]], na.rm = TRUE)
  diff <- t_mean - c_mean
  tab1_rows[[v]] <- c(t_mean, t_sd, c_mean, c_sd, diff)
}

tab1_mat <- do.call(rbind, tab1_rows)
colnames(tab1_mat) <- c("Treated Mean", "Treated SD", "Control Mean", "Control SD", "Difference")
rownames(tab1_mat) <- c("Violation rate (13Q)", "Any violation", "Violation quarters", "Major facility")

# LaTeX output
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Boundary Sample}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{303(d) Listed} & \\multicolumn{2}{c}{Non-Listed} & \\\\\n")
cat("\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n")
cat(" & Mean & SD & Mean & SD & Difference \\\\\n")
cat("\\hline\n")

labels <- c("Violation rate (13Q)", "Any violation (13Q)", "Violation quarters", "Share major")
for (i in seq_len(nrow(tab1_mat))) {
  cat(sprintf("%s & %.3f & (%.3f) & %.3f & (%.3f) & %.3f \\\\\n",
              labels[i],
              tab1_mat[i,1], tab1_mat[i,2],
              tab1_mat[i,3], tab1_mat[i,4],
              tab1_mat[i,5]))
}

cat("\\hline\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & %s \\\\\n",
            format(nrow(treated), big.mark = ","),
            format(nrow(control), big.mark = ","),
            format(nrow(boundary), big.mark = ",")))
cat(sprintf("HUC-8 watersheds & \\multicolumn{5}{c}{%s} \\\\\n",
            format(uniqueN(boundary$huc8), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} The boundary sample includes NPDES-permitted facilities in HUC-8 watersheds\n")
cat("that contain both 303(d)-listed and non-listed HUC-12 subwatersheds.\n")
cat("Violation rate is the share of 13 most recent quarters with compliance violations.\n")
cat("Data from EPA ECHO and ATTAINS, 2024 reporting cycle.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

m1 <- main_models$m1
m2 <- main_models$m2
m3 <- if (!is.null(main_models$m3)) main_models$m3 else NULL

# Extract coefficients
get_coef <- function(model, var = "listed_303dTRUE") {
  ct <- coeftable(model)
  idx <- which(rownames(ct) == var)
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(ct[idx, 1], ct[idx, 2], ct[idx, 4])  # estimate, SE, p-value
}

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of 303(d) Listing on Facility Compliance}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & Violation Rate & Any Violation & Violation Rate \\\\\n")
cat("\\hline\n")

c1 <- get_coef(m1)
c2 <- get_coef(m2)
c3 <- if (!is.null(m3)) get_coef(m3) else c(NA, NA, NA)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

cat(sprintf("303(d) Listed & %.4f%s & %.4f%s & %.4f%s \\\\\n",
            c1[1], stars(c1[3]), c2[1], stars(c2[3]),
            ifelse(is.na(c3[1]), NA, c3[1]), stars(c3[3])))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n", c1[2], c2[2],
            ifelse(is.na(c3[2]), NA, c3[2])))
cat("\\hline\n")
cat("HUC-8 FE & Yes & Yes & Yes \\\\\n")
cat(sprintf("State FE & No & No & %s \\\\\n", ifelse(is.null(m3), "---", "Yes")))
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(m1$nobs, big.mark = ","),
            format(m2$nobs, big.mark = ","),
            ifelse(is.null(m3), "---", format(m3$nobs, big.mark = ","))))
cat(sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\\n",
            fixest::r2(m1, "wr2"), fixest::r2(m2, "wr2"),
            ifelse(is.null(m3), NA, fixest::r2(m3, "wr2"))))
cat(sprintf("Mean dep. var. & %.3f & %.3f & %.3f \\\\\n",
            mean(boundary$pct_violation, na.rm = TRUE),
            mean(boundary$any_violation, na.rm = TRUE),
            mean(boundary$pct_violation, na.rm = TRUE)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the HUC-8 level in parentheses.\n")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("The sample includes facilities in HUC-8 watersheds containing both 303(d)-listed\n")
cat("and non-listed HUC-12 subwatersheds. Violation rate is the share of 13 most recent\n")
cat("quarters with compliance violations.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tab2_main.tex\n")

# ============================================================
# Table 3: Robustness
# ============================================================
cat("=== Table 3: Robustness ===\n")

sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Major Only & Violation Qtrs & Full Sample & Balanced States \\\\\n")
cat("\\hline\n")

models_rob <- list(rob_models$r1, rob_models$r2, rob_models$r3)
if (!is.null(rob_models$r5)) models_rob[[4]] <- rob_models$r5

for (i in seq_along(models_rob)) {
  ci <- get_coef(models_rob[[i]])
  if (i == 1) {
    cat(sprintf("303(d) Listed & %.4f%s", ci[1], stars(ci[3])))
  } else {
    cat(sprintf(" & %.4f%s", ci[1], stars(ci[3])))
  }
}
cat(" \\\\\n")

for (i in seq_along(models_rob)) {
  ci <- get_coef(models_rob[[i]])
  if (i == 1) {
    cat(sprintf(" & (%.4f)", ci[2]))
  } else {
    cat(sprintf(" & (%.4f)", ci[2]))
  }
}
cat(" \\\\\n")

cat("\\hline\n")
cat("Sample & Major only & Boundary & All facilities & Balanced \\\\\n")
obs_str <- sapply(models_rob, function(m) format(m$nobs, big.mark = ","))
cat(sprintf("Observations & %s \\\\\n", paste(obs_str, collapse = " & ")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the HUC-8 level (columns 1--2, 4)\n")
cat("or state level (column 3). Column 1 restricts to major NPDES permits.\n")
cat("Column 2 uses the count of violation quarters (0--13) as the outcome.\n")
cat("Column 3 includes all facilities with state fixed effects.\n")
cat("Column 4 restricts to states with at least 5 treated and 5 control facilities.\n")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tab3_robustness.tex\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Compute SDE for main outcomes
sd_y_violation <- sd(boundary$pct_violation[!boundary$listed_303d], na.rm = TRUE)
sd_y_any <- sd(boundary$any_violation[!boundary$listed_303d], na.rm = TRUE)

beta_violation <- coef(m1)["listed_303dTRUE"]
se_violation <- coeftable(m1)["listed_303dTRUE", 2]

beta_any <- coef(m2)["listed_303dTRUE"]
se_any <- coeftable(m2)["listed_303dTRUE", 2]

sde_violation <- beta_violation / sd_y_violation
se_sde_violation <- se_violation / sd_y_violation

sde_any <- beta_any / sd_y_any
se_sde_any <- se_any / sd_y_any

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Heterogeneity: high-violation vs low-violation HUC-8s (median split)
huc8_medviol <- boundary[, .(mean_viol = mean(pct_violation, na.rm = TRUE)), by = huc8]
med_viol <- median(huc8_medviol$mean_viol, na.rm = TRUE)
high_viol_huc8s <- huc8_medviol[mean_viol >= med_viol]$huc8

boundary_high <- boundary[huc8 %in% high_viol_huc8s]
boundary_low <- boundary[!(huc8 %in% high_viol_huc8s)]

m_high <- fixest::feols(pct_violation ~ listed_303d | huc8,
                         data = boundary_high, cluster = ~huc8)
beta_major <- coef(m_high)["listed_303dTRUE"]
se_major <- coeftable(m_high)["listed_303dTRUE", 2]
sd_y_major <- sd(boundary_high$pct_violation[!boundary_high$listed_303d], na.rm = TRUE)
sde_major <- beta_major / sd_y_major
se_sde_major <- se_major / sd_y_major

m_low <- fixest::feols(pct_violation ~ listed_303d | huc8,
                        data = boundary_low, cluster = ~huc8)
beta_minor <- coef(m_low)["listed_303dTRUE"]
se_minor <- coeftable(m_low)["listed_303dTRUE", 2]
sd_y_minor <- sd(boundary_low$pct_violation[!boundary_low$listed_303d], na.rm = TRUE)
sde_minor <- beta_minor / sd_y_minor
se_sde_minor <- se_minor / sd_y_minor

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Clean Water Act Section 303(d) impaired-waters listing cause permitted facilities to reduce compliance violations? ",
  "\\textbf{Policy mechanism:} 303(d) listing designates a water body as impaired under the CWA, triggering Total Maximum Daily Load (TMDL) development and wasteload allocations that impose stricter effluent limits on point-source dischargers; facilities in listed watersheds face tighter permits and increased EPA/state enforcement scrutiny. ",
  "\\textbf{Outcome definition:} Share of 13 most recent quarters with any compliance violation (effluent exceedance, significant noncompliance, or permit violation) from EPA ECHO quarterly compliance tracking. ",
  "\\textbf{Treatment:} Binary --- facility's HUC-12 subwatershed is on the state's 303(d) list of impaired waters. ",
  "\\textbf{Data:} EPA ECHO facility compliance data and ATTAINS 303(d) impairment assessments, 2024 reporting cycle, facility-level cross-section, ",
  format(nrow(boundary), big.mark = ","), " NPDES-permitted facilities. ",
  "\\textbf{Method:} OLS with HUC-8 watershed fixed effects; standard errors clustered at HUC-8 level. ",
  "\\textbf{Sample:} Boundary sample restricted to HUC-8 watersheds containing both 303(d)-listed and non-listed HUC-12 subwatersheds, ensuring within-watershed comparisons. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the control-group standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

cat(sprintf("Violation rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            beta_violation, se_violation, sd_y_violation,
            sde_violation, se_sde_violation, classify_sde(sde_violation)))
cat(sprintf("Any violation & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            beta_any, se_any, sd_y_any,
            sde_any, se_sde_any, classify_sde(sde_any)))

cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by watershed violation intensity)}} \\\\\n")

cat(sprintf("High-violation watersheds & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            beta_major, se_major, sd_y_major,
            sde_major, se_sde_major, classify_sde(sde_major)))
cat(sprintf("Low-violation watersheds & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            beta_minor, se_minor, sd_y_minor,
            sde_minor, se_sde_minor, classify_sde(sde_minor)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
