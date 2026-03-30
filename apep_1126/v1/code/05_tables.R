## ============================================================================
## 05_tables.R — Generate all tables for apep_1126
## Prohibition-state sample only (drop MI, WA, VT, ME)
## ============================================================================

source("00_packages.R")

DATA   <- "../data"
TABLES <- "../tables"
dir.create(TABLES, showWarnings = FALSE)

## ---- Load data ----
panel <- as.data.table(read_parquet(file.path(DATA, "county_quarter_panel.parquet")))
drop_states <- c("MI", "WA", "VT", "ME")
panel <- panel[!(state_abb %in% drop_states)]
panel_hc <- panel[high_coverage == TRUE & !is.na(drug_rate)]
panel_hc[, state_yq := paste0(state_abb, "_", year_quarter)]
panel_hc[, border := as.numeric(is_border)]
panel_hc[, border_post   := border * post_legal]
panel_hc[, border_covid  := border * covid_closed]
panel_hc[, border_reopen := border * post_reopen]
panel_hc[, exp_post   := exposure_std * post_legal]
panel_hc[, exp_covid  := exposure_std * covid_closed]
panel_hc[, exp_reopen := exposure_std * post_reopen]

results    <- jsonlite::read_json(file.path(DATA, "main_results.json"))
robustness <- jsonlite::read_json(file.path(DATA, "robustness_results.json"))

cat(sprintf("Prohibition-state panel: %s obs, %d counties (%d border)\n",
            format(nrow(panel_hc), big.mark = ","),
            uniqueN(panel_hc$fips),
            uniqueN(panel_hc[is_border == TRUE, fips])))

## ============================================================================
## Table 1: Summary Statistics (border vs interior, by regime)
## ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- panel_hc[, .(
  mean_rate   = mean(drug_rate, na.rm = TRUE),
  sd_rate     = sd(drug_rate, na.rm = TRUE),
  median_rate = median(drug_rate, na.rm = TRUE),
  mean_pop    = mean(reporting_pop, na.rm = TRUE),
  n_obs       = .N,
  n_counties  = uniqueN(fips)
), by = .(is_border, regime)]

setorder(summ, -is_border, regime)
fwrite(summ, file.path(TABLES, "summary_stats.csv"))

sink(file.path(TABLES, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Drug Arrest Rates by County Type and Regime}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llccccc}\n")
cat("\\hline\\hline\n")
cat(" & & Mean & SD & Median & Counties & Obs \\\\\n")
cat("\\hline\n")

regime_order <- c("pre", "post_legal", "covid_closed", "post_reopen")
regime_labels <- c("pre" = "Pre-legalization",
                   "post_legal" = "Post-legalization",
                   "covid_closed" = "COVID closure",
                   "post_reopen" = "Post-reopening")

for (b in c(TRUE, FALSE)) {
  label <- ifelse(b, "\\textbf{Border counties}", "\\textbf{Interior counties}")
  cat(sprintf("%s & & & & & & \\\\\n", label))
  for (r in regime_order) {
    row <- summ[is_border == b & regime == r]
    if (nrow(row) > 0) {
      cat(sprintf("\\quad %s & & %.1f & %.1f & %.1f & %d & %s \\\\\n",
                  regime_labels[r],
                  row$mean_rate, row$sd_rate, row$median_rate,
                  row$n_counties,
                  format(row$n_obs, big.mark = ",")))
    }
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Drug arrest rate per 100,000 reporting population. ")
cat("Sample restricted to eight prohibition states bordering Canada ")
cat("(ID, MT, ND, MN, OH, PA, NY, NH). ")
cat("Pre-legalization: 2014Q1--2018Q3. Post-legalization: 2018Q4--2019Q4. ")
cat("COVID closure: 2020Q1--2021Q4. Post-reopening: 2022Q1--2023Q4.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved: tab1_summary.tex\n")

## ============================================================================
## Table 2: Main Results
## Columns: (1) Unweighted, (2) Weighted, (3) Continuous exposure, (4) Constant coverage
## ============================================================================
cat("\n=== Table 2: Main Results ===\n")

## Re-run all specs for etable
spec1_uw <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_hc, cluster = ~state_abb
)

spec2_wt <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_hc, cluster = ~state_abb, weights = ~reporting_pop
)

spec3_cont <- feols(
  drug_rate ~ exp_post + exp_covid + exp_reopen |
    fips + state_yq,
  data = panel_hc, cluster = ~state_abb
)

## Constant-coverage
full_cov  <- panel_hc[, .(n_q = .N), by = fips]
max_q     <- max(full_cov$n_q)
always_fips <- full_cov[n_q == max_q, fips]
panel_const <- panel_hc[fips %in% always_fips]

spec4_cc <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_const, cluster = ~state_abb
)

etable(spec1_uw, spec2_wt, spec3_cont, spec4_cc,
       tex = TRUE,
       file = file.path(TABLES, "tab2_main.tex"),
       title = "Effect of Canadian Cannabis Legalization on US Border County Drug Arrests",
       label = "tab:main",
       dict = c(
         "border_post"   = "Border $\\times$ Post-Legal",
         "border_covid"  = "Border $\\times$ COVID Closed",
         "border_reopen" = "Border $\\times$ Post-Reopen",
         "exp_post"      = "Exposure $\\times$ Post-Legal",
         "exp_covid"     = "Exposure $\\times$ COVID Closed",
         "exp_reopen"    = "Exposure $\\times$ Post-Reopen"
       ),
       headers = c("Unweighted", "Weighted", "Continuous", "Const. Coverage"),
       notes = paste0(
         "Drug arrest rate per 100,000 reporting population. ",
         "Sample restricted to eight prohibition states (ID, MT, ND, MN, OH, PA, NY, NH). ",
         "All specifications include county and state-by-quarter fixed effects. ",
         "Standard errors clustered at the state level in parentheses. ",
         "Column (2) uses population weights. Column (3) uses standardized crossing exposure. ",
         "Column (4) restricts to counties reporting in every quarter."
       ),
       fitstat = c("n", "wr2"))

cat("  Saved: tab2_main.tex\n")

## ============================================================================
## Table 3: Robustness — LOSO + fake-date placebos
## ============================================================================
cat("\n=== Table 3: Robustness ===\n")

sink(file.path(TABLES, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Leave-One-State-Out and Placebo Tests}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & $\\hat{\\beta}_{\\text{post}}$ & SE & $p$ & Counties & Border & Obs \\\\\n")
cat("\\hline\n")

## Panel A: LOSO
cat("\\multicolumn{7}{l}{\\textbf{Panel A: Leave-one-state-out}} \\\\\n")
loso <- robustness$loso
for (st_name in names(loso)) {
  r <- loso[[st_name]]
  cat(sprintf("Drop %s & %.3f & %.3f & %.3f & %d & %d & %s \\\\\n",
              r$dropped, r$beta_post, r$se_post, r$pval_post,
              r$n_counties, r$n_border,
              format(r$n_obs, big.mark = ",")))
}

## Panel B: Fake-date placebos
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textbf{Panel B: Fake-date placebos (pre-period only)}} \\\\\n")
for (fd_name in names(robustness$fake_date_placebos)) {
  fd <- robustness$fake_date_placebos[[fd_name]]
  date_label <- if (fd$fake_date == 2015.75) "Oct 2015" else "Oct 2016"
  cat(sprintf("Fake: %s & %.3f & %.3f & %.3f & --- & --- & --- \\\\\n",
              date_label, fd$estimate, fd$se, fd$pval))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item Panel A reports the coefficient on Border $\\times$ Post-Legal from the ")
cat("unweighted three-regime DiD, dropping each prohibition state in turn. ")
cat("Panel B re-estimates the model using only pre-period data with placebo treatment dates. ")
cat("All specifications include county and state-by-quarter fixed effects ")
cat("with state-clustered standard errors.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved: tab3_robustness.tex\n")

## ============================================================================
## Table F1: SDE Appendix (8 mandatory fields)
## ============================================================================
cat("\n=== Table F1: SDE Appendix ===\n")

## Main estimate: unweighted prohibition-state border_post coefficient
beta_post <- results$spec1_unweighted$beta_post_legal
se_beta   <- results$spec1_unweighted$se_post_legal
sd_y      <- sd(panel_hc$drug_rate, na.rm = TRUE)
sde       <- beta_post / sd_y
se_sde    <- se_beta / sd_y

classify_sde <- function(x) {
  ax <- abs(x)
  if (ax > 0.15) return("Large")
  if (ax > 0.05) return("Moderate")
  if (ax > 0.005) return("Small")
  return("Null")
}

sink(file.path(TABLES, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Distributional Effect (SDE)}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification & $N$ \\\\\n")
cat("\\hline\n")
cat(sprintf("Drug arrest rate & %.3f & %.3f & %.2f & %.4f & %.4f & %s & %s \\\\\n",
            beta_post, se_beta, sd_y, sde, se_sde, classify_sde(sde),
            format(results$spec1_unweighted$n_obs, big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textbf{Country:} United States. ")
cat("\\textbf{Research question:} Does Canada's cannabis legalization generate drug enforcement spillovers in US border counties? ")
cat("\\textbf{Policy mechanism:} Cross-border drug policy asymmetry creates arbitrage incentives that may increase drug-market enforcement activity near border crossings. ")
cat("\\textbf{Outcome definition:} Drug/narcotic-related arrests per 100,000 reporting population (UCR). ")
cat("\\textbf{Treatment:} Canadian Cannabis Act effective October 17, 2018. ")
cat("\\textbf{Data:} UCR Arrests by Age, Sex, and Race (Kaplan, Harvard Dataverse), 2014--2023, restricted to eight prohibition states. ")
cat("\\textbf{Method:} Difference-in-differences comparing border and interior counties with three-regime interactions (post-legalization, COVID border closure, post-reopening), county and state-by-quarter FE, state-clustered SEs. ")
cat("\\textbf{Sample:} ", format(results$spec1_unweighted$n_obs, big.mark = ","),
    " county-quarter observations from ",
    results$spec1_unweighted$n_counties,
    " counties (",
    results$spec1_unweighted$n_border,
    " border) in ID, MT, ND, MN, OH, PA, NY, NH. ",
    sep = "")
cat("Classification refers to magnitude, not statistical significance.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("  Saved: tabF1_sde.tex\n")

## ============================================================================
## diagnostics.json — Final output
## ============================================================================
cat("\n=== Writing diagnostics.json ===\n")

n_treated <- uniqueN(panel_hc[is_border == TRUE, fips])
n_pre     <- uniqueN(panel_hc[regime == "pre", year_quarter])
n_obs     <- nrow(panel_hc)

diagnostics <- list(
  n_treated                   = n_treated,
  n_pre                       = n_pre,
  n_obs                       = n_obs,
  n_states                    = uniqueN(panel_hc$state_abb),
  states                      = paste(sort(unique(panel_hc$state_abb)), collapse = ", "),
  n_total_counties            = uniqueN(panel_hc$fips),
  n_border_counties           = n_treated,
  n_interior_counties         = uniqueN(panel_hc[is_border == FALSE, fips]),
  sd_drug_rate                = sd_y,
  mean_drug_rate_border_pre   = mean(panel_hc[is_border == TRUE & regime == "pre", drug_rate], na.rm = TRUE),
  mean_drug_rate_interior_pre = mean(panel_hc[is_border == FALSE & regime == "pre", drug_rate], na.rm = TRUE),
  beta_post_unweighted        = beta_post,
  se_post_unweighted          = se_beta,
  sde                         = sde
)

jsonlite::write_json(diagnostics, file.path(DATA, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nFinal diagnostics:\n"))
cat(sprintf("  n_treated (border counties): %d\n", n_treated))
cat(sprintf("  n_pre (pre-period quarters): %d\n", n_pre))
cat(sprintf("  n_obs: %s\n", format(n_obs, big.mark = ",")))
cat(sprintf("  SD(Y): %.2f\n", sd_y))
cat(sprintf("  beta_post: %.3f (SE: %.3f)\n", beta_post, se_beta))
cat(sprintf("  SDE: %.4f [%s]\n", sde, classify_sde(sde)))

cat("\n=== All tables generated ===\n")
