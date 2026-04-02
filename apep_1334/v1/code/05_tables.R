##############################################################################
# 05_tables.R — Generate all LaTeX tables
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

source("code/00_packages.R")

dir.create("tables", showWarnings = FALSE)

cat("=== Loading data and models ===\n")
df <- as.data.table(read_parquet("data/analysis_data.parquet"))
load("data/models.RData")
load("data/robustness_models.RData")

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

sumstats <- function(x, nm) {
  x <- x[!is.na(x)]
  data.table(Variable = nm,
             N = format(length(x), big.mark = ","),
             Mean = sprintf("%.3f", mean(x)),
             SD = sprintf("%.3f", sd(x)),
             Min = sprintf("%.3f", min(x)),
             Max = sprintf("%.3f", max(x)))
}

tab1 <- rbindlist(list(
  sumstats(df$granted, "Patent Granted"),
  sumstats(df$market_transfer, "Market Transfer (Any Assignment)"),
  sumstats(df$collateralized, "Security Interest"),
  sumstats(df$loo_grant_rate, "Examiner Leniency (LOO Grant Rate)"),
  sumstats(df$small_entity, "Small Entity"),
  sumstats(as.numeric(df$n_conveyances), "Number of Conveyances")
))

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  apply(tab1, 1, function(r) paste0(paste(r, collapse = " & "), " \\\\")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Sample includes %s resolved USPTO patent applications filed 2000--2016 with identifiable examiner assignment. Patent Granted equals one if the application was issued (disposal\\_type = ISS). Market Transfer equals one if the patent was assigned to a different entity. Security Interest equals one if the patent was used as collateral. Examiner Leniency is the leave-one-out grant rate of the assigned examiner within the same art-unit $\\times$ filing-year cell. Small Entity equals one if the applicant filed under the USPTO's reduced-fee small-entity status.",
          format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab1_tex, collapse = "\n"), "tables/tab1_summary.tex")
cat("  Wrote tables/tab1_summary.tex\n")

# ===================================================================
# Table 2: First Stage and Reduced Form
# ===================================================================
cat("\n=== Table 2: First Stage and Reduced Form ===\n")

# First stage
fs_coef <- sprintf("%.4f", coef(fs)["loo_grant_rate"])
fs_se <- sprintf("(%.4f)", se(fs)["loo_grant_rate"])
fs_stars <- ifelse(pvalue(fs)["loo_grant_rate"] < 0.01, "***",
             ifelse(pvalue(fs)["loo_grant_rate"] < 0.05, "**",
              ifelse(pvalue(fs)["loo_grant_rate"] < 0.10, "*", "")))
fs_f <- sprintf("%.1f", wald(fs, "loo_grant_rate")$stat)

# Reduced form: transfer
rf_t_coef <- sprintf("%.4f", coef(rf_transfer)["loo_grant_rate"])
rf_t_se <- sprintf("(%.4f)", se(rf_transfer)["loo_grant_rate"])
rf_t_stars <- ifelse(pvalue(rf_transfer)["loo_grant_rate"] < 0.01, "***",
               ifelse(pvalue(rf_transfer)["loo_grant_rate"] < 0.05, "**",
                ifelse(pvalue(rf_transfer)["loo_grant_rate"] < 0.10, "*", "")))

# Reduced form: security
rf_s_coef <- sprintf("%.4f", coef(rf_security)["loo_grant_rate"])
rf_s_se <- sprintf("(%.4f)", se(rf_security)["loo_grant_rate"])
rf_s_stars <- ifelse(pvalue(rf_security)["loo_grant_rate"] < 0.01, "***",
               ifelse(pvalue(rf_security)["loo_grant_rate"] < 0.05, "**",
                ifelse(pvalue(rf_security)["loo_grant_rate"] < 0.10, "*", "")))

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{First Stage and Reduced-Form Estimates}",
  "\\label{tab:firststage}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Patent Granted & Market Transfer & Security Interest \\\\",
  "\\midrule",
  sprintf("Examiner Leniency & %s%s & %s%s & %s%s \\\\",
          fs_coef, fs_stars, rf_t_coef, rf_t_stars, rf_s_coef, rf_s_stars),
  sprintf(" & %s & %s & %s \\\\", fs_se, rf_t_se, rf_s_se),
  "\\\\",
  sprintf("Art Unit $\\times$ Year FE & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(fs), big.mark = ","),
          format(nobs(rf_transfer), big.mark = ","),
          format(nobs(rf_security), big.mark = ",")),
  sprintf("F-statistic & %s & & \\\\", fs_f),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) reports the first-stage relationship between examiner leniency (leave-one-out grant rate within art-unit $\\times$ filing-year) and patent grant probability. Columns (2)--(3) report reduced-form effects of examiner leniency on market outcomes. Standard errors clustered at the art-unit level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab2_tex, collapse = "\n"), "tables/tab2_firststage.tex")
cat("  Wrote tables/tab2_firststage.tex\n")

# ===================================================================
# Table 3: IV Results (Main)
# ===================================================================
cat("\n=== Table 3: IV Results ===\n")

iv_t_coef <- sprintf("%.4f", coef(iv_transfer)["fit_granted"])
iv_t_se <- sprintf("(%.4f)", se(iv_transfer)["fit_granted"])
iv_t_stars <- ifelse(pvalue(iv_transfer)["fit_granted"] < 0.01, "***",
               ifelse(pvalue(iv_transfer)["fit_granted"] < 0.05, "**",
                ifelse(pvalue(iv_transfer)["fit_granted"] < 0.10, "*", "")))

iv_s_coef <- sprintf("%.4f", coef(iv_security)["fit_granted"])
iv_s_se <- sprintf("(%.4f)", se(iv_security)["fit_granted"])
iv_s_stars <- ifelse(pvalue(iv_security)["fit_granted"] < 0.01, "***",
               ifelse(pvalue(iv_security)["fit_granted"] < 0.05, "**",
                ifelse(pvalue(iv_security)["fit_granted"] < 0.10, "*", "")))

# OLS for comparison
ols_t_coef <- sprintf("%.4f", coef(ols_transfer)["granted"])
ols_t_se <- sprintf("(%.4f)", se(ols_transfer)["granted"])
ols_t_stars <- ifelse(pvalue(ols_transfer)["granted"] < 0.01, "***",
                ifelse(pvalue(ols_transfer)["granted"] < 0.05, "**",
                 ifelse(pvalue(ols_transfer)["granted"] < 0.10, "*", "")))

ols_s_coef <- sprintf("%.4f", coef(ols_security)["granted"])
ols_s_se <- sprintf("(%.4f)", se(ols_security)["granted"])
ols_s_stars <- ifelse(pvalue(ols_security)["granted"] < 0.01, "***",
                ifelse(pvalue(ols_security)["granted"] < 0.05, "**",
                 ifelse(pvalue(ols_security)["granted"] < 0.10, "*", "")))

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{The Causal Effect of Patent Grants on Market Outcomes}",
  "\\label{tab:iv}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Market Transfer} & \\multicolumn{2}{c}{Security Interest} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) OLS & (2) IV & (3) OLS & (4) IV \\\\",
  "\\midrule",
  sprintf("Patent Granted & %s%s & %s%s & %s%s & %s%s \\\\",
          ols_t_coef, ols_t_stars, iv_t_coef, iv_t_stars,
          ols_s_coef, ols_s_stars, iv_s_coef, iv_s_stars),
  sprintf(" & %s & %s & %s & %s \\\\",
          ols_t_se, iv_t_se, ols_s_se, iv_s_se),
  "\\\\",
  "Art Unit $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(ols_transfer), big.mark = ","),
          format(nobs(iv_transfer), big.mark = ","),
          format(nobs(ols_security), big.mark = ","),
          format(nobs(iv_security), big.mark = ",")),
  sprintf("First-Stage F & & %s & & %s \\\\", fs_f, fs_f),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} This table compares OLS and IV estimates of the effect of patent grant on market outcomes. The instrument is the leave-one-out examiner grant rate within art-unit $\\times$ filing-year cells. Market Transfer equals one if the patent was assigned to a different entity via the USPTO assignment system. Security Interest equals one if the patent was pledged as collateral. Standard errors clustered at the art-unit level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab3_tex, collapse = "\n"), "tables/tab3_iv.tex")
cat("  Wrote tables/tab3_iv.tex\n")

# ===================================================================
# Table 4: Entity Size Heterogeneity
# ===================================================================
cat("\n=== Table 4: Entity Size Heterogeneity ===\n")

make_cell <- function(mod, var) {
  coef_val <- coef(mod)[var]
  se_val <- se(mod)[var]
  p_val <- pvalue(mod)[var]
  stars <- ifelse(p_val < 0.01, "***", ifelse(p_val < 0.05, "**", ifelse(p_val < 0.10, "*", "")))
  list(coef = sprintf("%.4f%s", coef_val, stars),
       se = sprintf("(%.4f)", se_val))
}

sm_t <- make_cell(iv_small, "fit_granted")
lg_t <- make_cell(iv_large, "fit_granted")
sm_s <- make_cell(iv_sec_small, "fit_granted")
lg_s <- make_cell(iv_sec_large, "fit_granted")

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity by Entity Size: Patent Grants and Market Outcomes}",
  "\\label{tab:heterogeneity}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Market Transfer} & \\multicolumn{2}{c}{Security Interest} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) Small & (2) Large & (3) Small & (4) Large \\\\",
  "\\midrule",
  sprintf("Patent Granted (IV) & %s & %s & %s & %s \\\\",
          sm_t$coef, lg_t$coef, sm_s$coef, lg_s$coef),
  sprintf(" & %s & %s & %s & %s \\\\",
          sm_t$se, lg_t$se, sm_s$se, lg_s$se),
  "\\\\",
  "Art Unit $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(iv_small), big.mark = ","),
          format(nobs(iv_large), big.mark = ","),
          format(nobs(iv_sec_small), big.mark = ","),
          format(nobs(iv_sec_large), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} This table reports IV estimates separately for small-entity and large-entity patent applicants. Small entities (individuals, small firms, nonprofits) file under the USPTO's reduced-fee program. The instrument is the leave-one-out examiner grant rate within art-unit $\\times$ filing-year cells. Standard errors clustered at the art-unit level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab4_tex, collapse = "\n"), "tables/tab4_heterogeneity.tex")
cat("  Wrote tables/tab4_heterogeneity.tex\n")

# ===================================================================
# Table 5: Robustness
# ===================================================================
cat("\n=== Table 5: Robustness ===\n")

# Main result (repeated for reference)
main_coef <- sprintf("%.4f", coef(iv_transfer)["fit_granted"])
main_se <- sprintf("(%.4f)", se(iv_transfer)["fit_granted"])
main_n <- format(nobs(iv_transfer), big.mark = ",")

# Alt instrument
alt_coef <- sprintf("%.4f", coef(iv_alt)["fit_granted"])
alt_se <- sprintf("(%.4f)", se(iv_alt)["fit_granted"])
alt_n <- format(nobs(iv_alt), big.mark = ",")

# Trimmed
trim_coef <- sprintf("%.4f", coef(iv_trim)["fit_granted"])
trim_se <- sprintf("(%.4f)", se(iv_trim)["fit_granted"])
trim_n <- format(nobs(iv_trim), big.mark = ",")

tab5_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness of IV Estimates for Market Transfer}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule",
  sprintf("\\textit{Baseline} & %s & %s & %s \\\\", main_coef, main_se, main_n),
  sprintf("3-Year Instrument Window & %s & %s & %s \\\\", alt_coef, alt_se, alt_n),
  sprintf("Trimmed (5--95\\%% leniency) & %s & %s & %s \\\\", trim_coef, trim_se, trim_n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications instrument Patent Granted with examiner leniency and include art-unit $\\times$ filing-year fixed effects. Row 1 reproduces the baseline from \\Cref{tab:iv}. Row 2 constructs the leave-one-out instrument within 3-year filing windows (coarser cells). Row 3 drops applications assigned to examiners in the top or bottom 5\\% of the leniency distribution. Standard errors clustered at the art-unit level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(paste(tab5_tex, collapse = "\n"), "tables/tab5_robustness.tex")
cat("  Wrote tables/tab5_robustness.tex\n")

# ===================================================================
# Table F1: Standardized Effect Sizes (SDE — Appendix)
# ===================================================================
cat("\n=== Table F1: SDE ===\n")

# Compute SDEs
sd_transfer <- sd(df$market_transfer)
sd_security <- sd(df$collateralized)

# Pooled
beta_t <- coef(iv_transfer)["fit_granted"]
se_t <- se(iv_transfer)["fit_granted"]
sde_t <- beta_t / sd_transfer
se_sde_t <- se_t / sd_transfer

beta_s <- coef(iv_security)["fit_granted"]
se_s <- se(iv_security)["fit_granted"]
sde_s <- beta_s / sd_security
se_sde_s <- se_s / sd_security

# Heterogeneous: small vs large entity (market transfer)
beta_sm <- coef(iv_small)["fit_granted"]
se_sm <- se(iv_small)["fit_granted"]
sd_transfer_sm <- sd(df[small_entity == 1, market_transfer])
sde_sm <- beta_sm / sd_transfer_sm
se_sde_sm <- se_sm / sd_transfer_sm

beta_lg <- coef(iv_large)["fit_granted"]
se_lg <- se(iv_large)["fit_granted"]
sd_transfer_lg <- sd(df[small_entity == 0, market_transfer])
sde_lg <- beta_lg / sd_transfer_lg
se_sde_lg <- se_lg / sd_transfer_lg

classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does a quasi-randomly assigned patent grant cause the underlying invention to be traded or pledged as collateral in the secondary patent market? ",
  "\\textbf{Policy mechanism:} The USPTO examines patent applications and decides whether to grant a patent right conferring 20 years of legal exclusivity over the claimed invention; the grant decision determines whether the invention has a formal property right that can be transferred, licensed, or collateralized. ",
  "\\textbf{Outcome definition:} Market Transfer is a binary indicator equal to one if the patent's USPTO assignment records contain at least one non-employer assignment event (ownership change to a different entity); Security Interest is a binary indicator for collateralization. ",
  "\\textbf{Treatment:} Binary (patent granted = 1 vs.\\ abandoned = 0), instrumented by examiner leniency. ",
  "\\textbf{Data:} USPTO PatEx and Assignment datasets via Google BigQuery, covering patent applications filed 2000--2015, matched to assignment records through application number; unit of observation is the patent application. ",
  "\\textbf{Method:} Two-stage least squares with leave-one-out examiner grant rate as instrument, art-unit $\\times$ filing-year fixed effects, standard errors clustered at the art-unit level. ",
  "\\textbf{Sample:} Resolved applications (issued or abandoned) with examiner caseload $\\geq$ 50 applications. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Market Transfer & IV (Pooled) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_t, se_t, sd_transfer, sde_t, se_sde_t, classify_sde(sde_t)),
  sprintf("Security Interest & IV (Pooled) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_s, se_s, sd_security, sde_s, se_sde_s, classify_sde(sde_s)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by Entity Size)}} \\\\",
  sprintf("Market Transfer & IV (Small Entity) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_sm, se_sm, sd_transfer_sm, sde_sm, se_sde_sm, classify_sde(sde_sm)),
  sprintf("Market Transfer & IV (Large Entity) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_lg, se_lg, sd_transfer_lg, sde_lg, se_sde_lg, classify_sde(sde_lg)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{threeparttable}",
  "\\par\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  paste0("\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does a quasi-randomly assigned patent grant cause the underlying invention to be traded or pledged as collateral in the secondary patent market? ",
  "\\textbf{Policy mechanism:} The USPTO examines patent applications and decides whether to grant a patent right conferring 20 years of exclusivity; the grant decision determines whether the invention has a formal property right that can be transferred, licensed, or collateralized. ",
  "\\textbf{Outcome definition:} Market Transfer equals one if the patent's USPTO assignment records contain at least one non-employer ownership change; Security Interest equals one if collateralized. ",
  "\\textbf{Treatment:} Binary (granted = 1 vs.\\\\ abandoned = 0), instrumented by examiner leniency. ",
  "\\textbf{Data:} USPTO PatEx and Assignment datasets via Google BigQuery, patent applications filed 2000--2015, matched via application number. ",
  "\\textbf{Method:} 2SLS with leave-one-out examiner grant rate, art-unit $\\times$ filing-year FE, art-unit-clustered SEs. ",
  "\\textbf{Sample:} Resolved applications with examiner caseload $\\geq$ 50. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(paste(sde_tex, collapse = "\n"), "tables/tabF1_sde.tex")
cat("  Wrote tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
