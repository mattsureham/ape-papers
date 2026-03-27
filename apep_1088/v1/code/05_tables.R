## 05_tables.R — Generate all LaTeX tables
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Load models
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))
df <- fread(file.path(data_dir, "analysis_panel.csv"))
density_full <- fread(file.path(data_dir, "density_full.csv"))

# ============================================================
# TABLE 1: Bunching Estimates at Multiple Thresholds
# ============================================================
cat("=== Generating Table 1: Bunching Estimates ===\n")

estimate_bunching_for_table <- function(density_dt, threshold, window = 10000, bin_width = 2000, poly_order = 7) {
  dt <- copy(density_dt)
  dt[, bin_center := rev_bin + bin_width / 2]
  excl_lo <- threshold - window
  excl_hi <- threshold + window
  dt[, in_window := bin_center >= excl_lo & bin_center <= excl_hi]
  dt[, z := (bin_center - threshold) / bin_width]
  fit_data <- dt[(in_window == FALSE)]
  if (nrow(fit_data) < poly_order + 1) return(list(b_hat = NA, se = NA, excess = NA))
  formula_str <- paste0("count ~ ", paste0("I(z^", 1:poly_order, ")", collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)
  dt[, predicted := predict(fit, newdata = dt)]
  bunching_bins <- dt[bin_center >= excl_lo & bin_center < threshold]
  excess <- sum(bunching_bins$count) - sum(bunching_bins$predicted)
  avg_cf <- mean(bunching_bins$predicted)
  b_hat <- excess / avg_cf
  # Bootstrap SE
  set.seed(42)
  b_boots <- replicate(200, {
    dt_b <- copy(dt); dt_b[, count := rpois(.N, pmax(count, 1))]
    fit_b <- tryCatch(lm(as.formula(formula_str), data = dt_b[(in_window == FALSE)]), error = function(e) NULL)
    if (is.null(fit_b)) return(NA)
    dt_b[, pred_b := predict(fit_b, newdata = dt_b)]
    bb <- dt_b[bin_center >= excl_lo & bin_center < threshold]
    (sum(bb$count) - sum(bb$pred_b)) / mean(bb$pred_b)
  })
  list(b_hat = b_hat, se = sd(b_boots, na.rm = TRUE), excess = excess)
}

thresholds <- c(100000, 150000, 200000, 250000)
labels <- c("\\$100K (old, freed)", "\\$150K (placebo)", "\\$200K (new, active)", "\\$250K (placebo)")

bunch_results <- lapply(thresholds, function(t) estimate_bunching_for_table(density_full, t))

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Bunching Estimates at Multiple Revenue Thresholds}",
  "\\label{tab:bunching}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Threshold & Norm.\\ Excess Mass ($\\hat{b}$) & SE & Excess Orgs \\\\",
  "\\hline"
)

for (i in seq_along(thresholds)) {
  r <- bunch_results[[i]]
  stars <- ""
  if (!is.na(r$se) && r$se > 0) {
    tstat <- abs(r$b_hat / r$se)
    stars <- ifelse(tstat > 2.576, "$^{***}$", ifelse(tstat > 1.96, "$^{**}$", ifelse(tstat > 1.645, "$^{*}$", "")))
  }
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.3f%s & (%.3f) & %.0f \\\\",
    labels[i], r$b_hat, stars, r$se, r$excess))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Normalized excess mass estimated using a seventh-degree polynomial ",
  "counterfactual with a \\$10K exclusion window on each side of the threshold ",
  "\\citep{kleven2016bunching}. Standard errors from 200 Poisson bootstrap replications. ",
  "The \\$100K threshold was the Form 990-EZ eligibility cutoff until 2010; the \\$200K ",
  "threshold replaced it. \\$150K and \\$250K are placebo thresholds with no policy relevance. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_bunching.tex"))
cat("  Table 1 saved.\n")

# ============================================================
# TABLE 2: DiD Revenue Growth Results
# ============================================================
cat("=== Generating Table 2: DiD Results ===\n")

tab2 <- etable(m1, m2, m3, m4,
  headers = c("Log Revenue", "Rev.\\ Growth", "Log Expenses", "Log Revenue"),
  se.below = TRUE,
  keep = "%constrained",
  dict = c("constrained:post" = "Constrained $\\times$ Post"),
  fitstat = c("n", "wr2"),
  tex = TRUE,
  style.tex = style.tex("aer"),
  notes = paste0(
    "\\\\textit{Notes:} Columns (1)--(3) compare organizations near the \\$200K threshold ",
    "(\\$170K--\\$220K baseline) to mid-range controls (\\$120K--\\$160K). ",
    "Column (4) uses low controls (\\$50K--\\$80K). ",
    "All specifications include organization and year FE. Clustered SEs."
  ),
  title = "Effect of Proximity to the \\$200K Threshold on Revenue Growth"
)

writeLines(tab2, file.path(table_dir, "tab2_did.tex"))
cat("  Table 2 saved.\n")

# ============================================================
# TABLE 3: Event Study
# ============================================================
cat("=== Generating Table 3: Event Study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

es_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event Time & Coefficient & SE & 95\\% CI \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_coefs))) {
  row <- es_coefs[i]
  stars <- ifelse(abs(row$coef / row$se) > 2.576, "$^{***}$",
           ifelse(abs(row$coef / row$se) > 1.96, "$^{**}$",
           ifelse(abs(row$coef / row$se) > 1.645, "$^{*}$", "")))
  es_lines <- c(es_lines, sprintf(
    "$t%s%d$ & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
    ifelse(row$event_time >= 0, "+", ""), row$event_time,
    row$coef, stars, row$se, row$ci_lo, row$ci_hi
  ))
}

es_lines <- c(es_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from interaction of constrained-group indicator with event-time dummies. ",
  "Event time 0 = 2014. Constrained group: organizations near the \\$200K threshold. ",
  "Controls: mid-range organizations (\\$120K--\\$160K). Organization and year FE included. Clustered SEs. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(es_lines, file.path(table_dir, "tab3_event_study.tex"))
cat("  Table 3 saved.\n")

# ============================================================
# TABLE 4: Mechanism / Alternative Controls
# ============================================================
cat("=== Generating Table 4: Mechanism ===\n")

tab4 <- etable(m_rev, m_exp, m_assets, m_gap,
  headers = c("Log Revenue", "Log Expenses", "Log Assets", "Rev-Exp Gap"),
  se.below = TRUE,
  keep = "%constrained",
  dict = c("constrained:post" = "Constrained $\\times$ Post"),
  fitstat = c("n", "wr2"),
  tex = TRUE,
  style.tex = style.tex("aer"),
  notes = paste0(
    "\\\\textit{Notes:} All specifications compare near-\\$200K organizations to mid-range controls. ",
    "Organization and year FE. Clustered SEs."
  ),
  title = "Mechanism: Revenue, Expenses, Assets, and the Revenue-Expense Gap"
)

writeLines(tab4, file.path(table_dir, "tab4_mechanism.tex"))
cat("  Table 4 saved.\n")

# ============================================================
# TABLE 5: Summary Statistics
# ============================================================
cat("=== Generating Table 5: Summary Statistics ===\n")

summ <- df[, .(
  `Mean Revenue` = mean(gross_receipts, na.rm = TRUE),
  `SD Revenue` = sd(gross_receipts, na.rm = TRUE),
  `Mean Expenses` = mean(total_expenses, na.rm = TRUE),
  `Mean Assets` = mean(total_assets, na.rm = TRUE),
  `N Org-Years` = .N,
  `N Orgs` = uniqueN(ein)
), by = group]

summ_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Group}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrrr}",
  "\\hline\\hline",
  "Group & Mean Rev.\\ & SD Rev.\\ & Mean Exp.\\ & Mean Assets & Org-Years & Orgs \\\\",
  "\\hline"
)

group_labels <- c(
  "control_low" = "Control Low (\\$50K--\\$80K)",
  "near_100k" = "Near \\$100K (\\$80K--\\$110K)",
  "control_mid" = "Control Mid (\\$120K--\\$160K)",
  "near_200k" = "Near \\$200K (\\$170K--\\$220K)"
)

for (g in c("control_low", "near_100k", "control_mid", "near_200k")) {
  row <- summ[group == g]
  if (nrow(row) > 0) {
    summ_lines <- c(summ_lines, sprintf(
      "%s & %s & %s & %s & %s & %s & %s \\\\",
      group_labels[g],
      format(round(row$`Mean Revenue`), big.mark = ","),
      format(round(row$`SD Revenue`), big.mark = ","),
      format(round(row$`Mean Expenses`), big.mark = ","),
      format(round(row$`Mean Assets`), big.mark = ","),
      format(row$`N Org-Years`, big.mark = ","),
      format(row$`N Orgs`, big.mark = ",")
    ))
  }
}

summ_lines <- c(summ_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Groups defined by mean gross receipts in 2011--2013 baseline period. ",
  "Revenue, expenses, and assets in nominal dollars. Organizations require at least two ",
  "baseline-period observations for group assignment.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(summ_lines, file.path(table_dir, "tab5_summary.tex"))
cat("  Table 5 saved.\n")

# ============================================================
# TABLE F1: SDE (Standardized Effect Sizes)
# ============================================================
cat("=== Generating Table F1: SDE ===\n")

df_did <- df[group %in% c("near_200k", "control_mid")]
df_did[, constrained := as.integer(group == "near_200k")]

sd_log_rev <- sd(df_did[tax_year < 2016, log(gross_receipts + 1)], na.rm = TRUE)
sd_rev_growth <- sd(df_did[tax_year < 2016, gross_receipts / mean_rev], na.rm = TRUE)
sd_log_exp <- sd(df_did[tax_year < 2016, log(pmax(total_expenses, 1))], na.rm = TRUE)

beta_rev <- coef(m1)[1]; se_rev <- sqrt(vcov(m1)[1,1])
beta_growth <- coef(m2)[1]; se_growth <- sqrt(vcov(m2)[1,1])
beta_exp <- coef(m3)[1]; se_exp <- sqrt(vcov(m3)[1,1])

sde_rev <- beta_rev / sd_log_rev; sde_se_rev <- se_rev / sd_log_rev
sde_growth <- beta_growth / sd_rev_growth; sde_se_growth <- se_growth / sd_rev_growth
sde_exp <- beta_exp / sd_log_exp; sde_se_exp <- se_exp / sd_log_exp

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity by NTEE sector
df_did[, ntee_broad := substr(ntee_code, 1, 1)]
df_did[, sector := fcase(
  ntee_broad %in% c("A", "B", "C", "D"), "Arts/Culture/Education",
  ntee_broad %in% c("E", "F", "G", "H"), "Health/Human Services",
  default = "Other"
)]

het_rows <- ""
for (s in c("Arts/Culture/Education", "Health/Human Services")) {
  df_s <- df_did[sector == s]
  if (uniqueN(df_s[constrained == 1]$ein) >= 5 && uniqueN(df_s$ein) >= 20 && nrow(df_s) >= 50) {
    m_s <- feols(log(gross_receipts + 1) ~ constrained:post | factor(ein) + factor(tax_year),
                 data = df_s[, .(gross_receipts, ein, tax_year, constrained, post = as.integer(tax_year >= 2016))],
                 cluster = ~ein)
    b_s <- coef(m_s)[1]; se_s <- sqrt(vcov(m_s)[1,1])
    sd_s <- sd(df_s[tax_year < 2016, log(gross_receipts + 1)], na.rm = TRUE)
    sde_s <- b_s / sd_s; sde_se_s <- se_s / sd_s
    label <- gsub("/", "/\\\\allowbreak ", s)
    het_rows <- paste0(het_rows, sprintf(
      "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
      label, b_s, se_s, sd_s, sde_s, sde_se_s, classify_sde(sde_s)))
  }
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the IRS Form 990-EZ gross receipts threshold at \\$200K constrain revenue growth for nonprofits near the compliance boundary, compared to similar-sized organizations between the old and new thresholds? ",
  "\\textbf{Policy mechanism:} The 2010 reform raised the Form 990-EZ eligibility ceiling from \\$100K to \\$200K, creating a new compliance discontinuity where organizations exceeding \\$200K in gross receipts must file the full twelve-page Form 990 rather than the four-page 990-EZ, imposing incremental reporting costs on governance, compensation, and program activities. ",
  "\\textbf{Outcome definition:} Log annual gross receipts from IRS Form 990/990-EZ electronic filings, measuring total organizational revenue. ",
  "\\textbf{Treatment:} Binary; organization classified as near the \\$200K threshold (mean gross receipts \\$170K--\\$220K in 2011--2013) versus mid-range control (\\$120K--\\$160K). ",
  "\\textbf{Data:} IRS Exempt Organizations Business Master File and ProPublica Nonprofit Explorer API, 2011--2022, organization-year panel, ",
  sprintf("%s organizations. ", format(uniqueN(df_did$ein), big.mark = ",")),
  "\\textbf{Method:} Two-way fixed effects DiD with organization and year fixed effects; standard errors clustered at the organization level. ",
  "\\textbf{Sample:} 501(c)(3) organizations with at least two baseline-period filing years (2011--2013) and mean gross receipts between \\$120K and \\$220K; excludes organizations with gross receipts above \\$2M. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log Revenue & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_rev, se_rev, sd_log_rev, sde_rev, sde_se_rev, classify_sde(sde_rev)),
  sprintf("Rev.\\ Growth & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_growth, se_growth, sd_rev_growth, sde_growth, sde_se_growth, classify_sde(sde_growth)),
  sprintf("Log Expenses & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_exp, se_exp, sd_log_exp, sde_exp, sde_se_exp, classify_sde(sde_exp)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sector)}} \\\\",
  het_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Table F1 (SDE) saved.\n")

cat("\n05_tables.R complete.\n")
