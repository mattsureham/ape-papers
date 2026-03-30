# ==============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_1129
# ==============================================================================

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness_models.RData")

# Helper: get stars
stars_fn <- function(p) {
  ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
}

# Helper: safe F-stat from IV model
get_fs_f <- function(model) {
  tryCatch({
    fs <- fitstat(model, "ivf1")
    fs[[1]]$stat
  }, error = function(e) {
    tryCatch({
      w <- wald(model, keep = "bartik_hhi")
      w$stat
    }, error = function(e2) NA)
  })
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- c("pills_per_cap", "hhi", "bartik_hhi", "n_distributors",
               "overdose_rate", "population", "median_income", "pct_white")
summ_labels <- c("Pills per capita", "Distributor HHI",
                 "Predicted HHI (instrument)", "Number of distributors",
                 "Overdose death rate (per 100k)", "Population",
                 "Median household income", "Percent white")

tab1_rows <- sapply(seq_along(summ_vars), function(i) {
  x <- panel[[summ_vars[i]]]
  x <- x[!is.na(x)]
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\",
    summ_labels[i], mean(x), sd(x),
    quantile(x, 0.25), quantile(x, 0.75),
    format(length(x), big.mark = ","))
})

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & P25 & P75 & $N$ \\\\\n",
  "\\hline\n",
  paste(tab1_rows, collapse = "\n"), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of U.S.\\ counties, 2006--2012. ",
  "Pills per capita is the total dosage units of opioids (hydrocodone and oxycodone) ",
  "shipped to pharmacies in the county per resident, from the DEA ARCOS database. ",
  "HHI is the Herfindahl-Hirschman Index of distributor market concentration. ",
  "Predicted HHI is the instrument constructed from 2006 county distributor shares ",
  "interacted with national merger-driven share changes. ",
  "Overdose death rate is the NCHS model-based drug poisoning death rate per 100,000.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# TABLE 2: Main Results (First Stage + 2SLS)
# ============================================================================
cat("Generating Table 2: Main Results...\n")

fs_f1 <- wald(fs1, "bartik_hhi")$stat
fs_f2 <- wald(fs2, "bartik_hhi")$stat

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Competitive Flood: Distributor Concentration and Opioid Supply}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{First Stage} & \\multicolumn{2}{c}{2SLS} & \\multicolumn{2}{c}{Reduced Form} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  " & HHI & HHI & Pills/cap & Pills/cap & Pills/cap & Pills/cap \\\\\n",
  "\\hline\n",
  sprintf("Predicted HHI & %.4f$%s$ & %.4f$%s$ & & & %.3f$%s$ & %.3f$%s$ \\\\\n",
    coef(fs1)["bartik_hhi"], stars_fn(pvalue(fs1)["bartik_hhi"]),
    coef(fs2)["bartik_hhi"], stars_fn(pvalue(fs2)["bartik_hhi"]),
    coef(rf1)["bartik_hhi"], stars_fn(pvalue(rf1)["bartik_hhi"]),
    coef(rf2)["bartik_hhi"], stars_fn(pvalue(rf2)["bartik_hhi"])),
  sprintf(" & (%.4f) & (%.4f) & & & (%.3f) & (%.3f) \\\\\n",
    se(fs1)["bartik_hhi"], se(fs2)["bartik_hhi"],
    se(rf1)["bartik_hhi"], se(rf2)["bartik_hhi"]),
  sprintf("HHI (instrumented) & & & %.3f$%s$ & %.3f$%s$ & & \\\\\n",
    coef(iv1)["fit_hhi"], stars_fn(pvalue(iv1)["fit_hhi"]),
    coef(iv2)["fit_hhi"], stars_fn(pvalue(iv2)["fit_hhi"])),
  sprintf(" & & & (%.3f) & (%.3f) & & \\\\\n",
    se(iv1)["fit_hhi"], se(iv2)["fit_hhi"]),
  "\\hline\n",
  "Controls & No & Yes & No & Yes & No & Yes \\\\\n",
  "County \\& Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("First-stage $F$ & %.1f & %.1f & %.1f & %.1f & & \\\\\n",
    fs_f1, fs_f2, fs_f1, fs_f2),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
    format(nobs(fs1), big.mark = ","), format(nobs(fs2), big.mark = ","),
    format(nobs(iv1), big.mark = ","), format(nobs(iv2), big.mark = ","),
    format(nobs(rf1), big.mark = ","), format(nobs(rf2), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Columns 1--2 report the first stage: predicted HHI ",
  "(constructed from 2006 county distributor shares $\\times$ national merger-driven ",
  "share shifts) on actual HHI. Columns 3--4 report 2SLS: the effect of instrumented ",
  "HHI on pills per capita. Columns 5--6 report the reduced form. ",
  "Controls: log median income, percent white, percent with high school diploma. ",
  "Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# TABLE 3: Robustness
# ============================================================================
cat("Generating Table 3: Robustness...\n")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Baseline & Pop-weighted & Log outcome \\\\\n",
  "\\hline\n",
  sprintf("HHI (instrumented) & %.3f$%s$ & %.3f$%s$ & %.4f$%s$ \\\\\n",
    coef(iv2)["fit_hhi"], stars_fn(pvalue(iv2)["fit_hhi"]),
    coef(iv_wt)["fit_hhi"], stars_fn(pvalue(iv_wt)["fit_hhi"]),
    coef(iv3)["fit_hhi"], stars_fn(pvalue(iv3)["fit_hhi"])),
  sprintf(" & (%.3f) & (%.3f) & (%.4f) \\\\\n",
    se(iv2)["fit_hhi"], se(iv_wt)["fit_hhi"], se(iv3)["fit_hhi"]),
  "\\hline\n",
  "Controls & Yes & Yes & Yes \\\\\n",
  "County \\& Year FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
    format(nobs(iv2), big.mark = ","), format(nobs(iv_wt), big.mark = ","),
    format(nobs(iv3), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All columns use the predicted HHI instrument. ",
  "Column 1 is the baseline 2SLS. Column 2 weights by county population. ",
  "Column 3 uses log pills per capita as the outcome. ",
  "Controls: log median income, percent white, percent high school. ",
  "Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_robustness.tex")

# ============================================================================
# TABLE 4: Drug Decomposition + Mortality
# ============================================================================
cat("Generating Table 4: Mechanisms...\n")

has_mort <- !is.null(mort_iv) && !inherits(mort_iv, "try-error")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Drug-Type Decomposition and Overdose Mortality}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Hydrocodone/cap & Oxycodone/cap & Overdose rate \\\\\n",
  "\\hline\n",
  sprintf("HHI (instrumented) & %.3f$%s$ & %.3f$%s$ & %.3f$%s$ \\\\\n",
    coef(iv_hydro)["fit_hhi"], stars_fn(pvalue(iv_hydro)["fit_hhi"]),
    coef(iv_oxy)["fit_hhi"], stars_fn(pvalue(iv_oxy)["fit_hhi"]),
    if (has_mort) coef(mort_iv)["fit_hhi"] else NA,
    if (has_mort) stars_fn(pvalue(mort_iv)["fit_hhi"]) else ""),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    se(iv_hydro)["fit_hhi"], se(iv_oxy)["fit_hhi"],
    if (has_mort) se(mort_iv)["fit_hhi"] else NA),
  "\\hline\n",
  "Controls & Yes & Yes & No \\\\\n",
  "County \\& Year FE & Yes & Yes & Yes \\\\\n",
  sprintf("Mean dep.\\ var.\\ & %.2f & %.2f & %.2f \\\\\n",
    mean(panel_drug$hydro_per_cap, na.rm = TRUE),
    mean(panel_drug$oxy_per_cap, na.rm = TRUE),
    mean(panel$overdose_rate, na.rm = TRUE)),
  sprintf("Observations & %s & %s & %s \\\\\n",
    format(nobs(iv_hydro), big.mark = ","),
    format(nobs(iv_oxy), big.mark = ","),
    if (has_mort) format(nobs(mort_iv), big.mark = ",") else "---"),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All columns use the predicted HHI instrument. ",
  "Columns 1--2 decompose total opioid supply into hydrocodone and oxycodone ",
  "pills per capita. Column 3 uses the NCHS model-based drug overdose death rate ",
  "per 100,000 as the outcome. Controls in columns 1--2 include log median income, ",
  "percent white, and percent high school. Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_mechanism.tex")

# ============================================================================
# TABLE 5: Balance Tests
# ============================================================================
cat("Generating Table 5: Balance...\n")

balance_results <- fread("../data/balance_results.csv")
balance_labels <- c(
  "log_med_income" = "Log median income",
  "pct_white" = "Percent white",
  "pct_hs" = "Percent high school",
  "population" = "Population"
)

bal_rows <- sapply(1:nrow(balance_results), function(i) {
  r <- balance_results[i]
  s <- stars_fn(r$pval)
  label <- balance_labels[r$variable]
  if (is.na(label)) label <- r$variable
  sprintf("%s & %.4f$%s$ & (%.4f) & %.3f \\\\", label, r$coef, s, r$se, r$pval)
})

# Add LOO summary row
loo_results <- fread("../data/loo_results.csv")

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Instrument Validity: Balance Tests and Leave-One-Out Sensitivity}\n",
  "\\label{tab:balance}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Balance Tests}} \\\\\n",
  "Covariate & Coefficient & SE & $p$-value \\\\\n",
  "\\hline\n",
  paste(bal_rows, collapse = "\n"), "\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Leave-One-Out Sensitivity (Drop Each State)}} \\\\\n",
  " & Min & Max & Fraction negative \\\\\n",
  "\\hline\n",
  sprintf("2SLS coefficient & %.3f & %.3f & %d/%d \\\\\n",
    min(loo_results$iv_coef), max(loo_results$iv_coef),
    sum(loo_results$iv_coef < 0), nrow(loo_results)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A: each row reports the coefficient from a regression ",
  "of the predetermined covariate on the predicted HHI instrument with county and year ",
  "fixed effects. Panel B: the 2SLS specification is re-estimated dropping one state at ",
  "a time. Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5, "../tables/tab5_balance.tex")

# ============================================================================
# SDE TABLE (Appendix — MANDATORY)
# ============================================================================
cat("Generating SDE Table...\n")

diag <- jsonlite::fromJSON("../data/diagnostics.json")

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_main <- diag$iv_coef * diag$sd_hhi / diag$sd_y_pre
sde_se <- diag$iv_se * diag$sd_hhi / diag$sd_y_pre

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Heterogeneity: small vs large counties
panel_lo <- panel[population <= median(population, na.rm = TRUE)]
panel_hi <- panel[population > median(population, na.rm = TRUE)]

het_results <- list()
for (lbl in c("Small counties", "Large counties")) {
  sub <- if (lbl == "Small counties") panel_lo else panel_hi
  tryCatch({
    m <- feols(pills_per_cap ~ log_med_income + pct_white + pct_hs |
                 fips + year | hhi ~ bartik_hhi,
               data = sub, vcov = ~state_fips)
    sd_y_sub <- sd(sub[year <= 2007]$pills_per_cap, na.rm = TRUE)
    sd_x_sub <- sd(sub$hhi, na.rm = TRUE)
    het_results[[lbl]] <- list(
      coef = coef(m)["fit_hhi"],
      se = se(m)["fit_hhi"],
      sd_y = sd_y_sub,
      sd_x = sd_x_sub,
      sde = coef(m)["fit_hhi"] * sd_x_sub / sd_y_sub,
      sde_se = se(m)["fit_hhi"] * sd_x_sub / sd_y_sub
    )
  }, error = function(e) {
    cat(sprintf("  Heterogeneity failed for %s: %s\n", lbl, e$message))
  })
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does pharmaceutical distributor market concentration affect county-level opioid pill supply during the prescription opioid era (2006--2012)? ",
  "\\textbf{Policy mechanism:} National merger waves among wholesale pharmaceutical distributors reshuffled county-level distributor market shares, altering the competitive structure of local pill supply chains and potentially changing the volume discipline exercised by wholesalers. ",
  "\\textbf{Outcome definition:} Total opioid dosage units (hydrocodone and oxycodone) per county resident per year, from DEA Automation of Reports and Consolidated Orders System (ARCOS) transaction records. ",
  "\\textbf{Treatment:} Continuous; Herfindahl-Hirschman Index of distributor market shares within each county-year (higher values indicate greater concentration). ",
  "\\textbf{Data:} DEA ARCOS (178 million transactions, 2006--2012), county-year panel of 2,937 counties across 49 states over 7 years ($N = 20{,}387$ county-years). ",
  "\\textbf{Method:} Shift-share (Bartik) instrumental variables using predicted HHI from 2006 county distributor shares interacted with national merger-driven share changes; county and year fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} U.S.\\ counties with population $\\geq$ 1,000 and matched to FIPS codes; years 2006--2012 (pre-synthetic-fentanyl prescription opioid era). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of the treatment variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Pills per capita & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
    diag$iv_coef, diag$iv_se, diag$sd_y_pre, sde_main, abs(sde_se), classify_sde(sde_main)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n"
)

for (lbl in names(het_results)) {
  r <- het_results[[lbl]]
  sde_tab <- paste0(sde_tab,
    sprintf("\\quad %s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
      lbl, r$coef, r$se, r$sd_y, r$sde, abs(r$sde_se), classify_sde(r$sde)))
}

sde_tab <- paste0(sde_tab,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
