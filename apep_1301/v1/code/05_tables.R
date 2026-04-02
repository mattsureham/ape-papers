## ============================================================
## 05_tables.R — Generate All LaTeX Tables (State Level)
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
## ============================================================

source("code/00_packages.R")

data_dir <- "data"
tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

results <- readRDS(file.path(data_dir, "regression_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
df <- fread(file.path(data_dir, "analysis_panel.csv"))

## Helper functions
make_cell <- function(est, se_val) {
  if (is.na(est) || is.na(se_val)) return("")
  pval <- 2 * pnorm(-abs(est / se_val))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}",
            ifelse(pval < 0.1, "^{*}", "")))
  sprintf("%.4f%s", est, stars)
}

extract_row <- function(model, var_name = NULL) {
  cf <- coef(model)
  se_vec <- se(model)
  nm <- names(cf)
  if (!is.null(var_name)) {
    idx <- grep(var_name, nm)
  } else {
    idx <- grep("exit_rate|post_exit|cum_exits|log_supers|placebo|fit_", nm)
  }
  if (length(idx) == 0) idx <- 1
  est <- cf[idx[1]]
  se_val <- se_vec[idx[1]]
  pval <- 2 * pnorm(-abs(est / se_val))
  c(est = est, se = se_val, pval = pval)
}

n_states <- length(unique(df$state_fips))
n_obs <- nrow(df)


## ---- Table 1: Summary Statistics ----
cat("=== Table 1: Summary Statistics ===\n")

ss <- results$summary_stats

tab1_rows <- paste(sprintf("  %s & %s & %s \\\\",
  ss$Variable,
  ifelse(ss$Mean > 100, format(round(ss$Mean, 0), big.mark = ","),
         sprintf("%.2f", ss$Mean)),
  ifelse(ss$SD > 100, format(round(ss$SD, 0), big.mark = ","),
         sprintf("%.2f", ss$SD))
), collapse = "\n")

tab1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lcc}
\\hline\\hline
 & Mean & SD \\\\
\\hline
%s
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} State-year panel of %d states plus DC over %d--%d.
Birth outcomes from CDC NCHS natality microdata aggregated to state-year.
Supermarket counts from USDA SNAP Retailer Historical Database.
Exit rate is annual supermarket exits per 1,000 active SNAP-authorized supermarkets.
$N = %d$ state-year observations.
\\end{tablenotes}
\\end{table}",
tab1_rows,
n_states, min(df$year), max(df$year), n_obs)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))


## ---- Table 2: Main Results (OLS + IV) ----
cat("=== Table 2: Main Results ===\n")

ols_lbw <- extract_row(results$ols_lbw)
ols_pre <- extract_row(results$ols_preterm)
ols_cs <- extract_row(results$ols_csection)

iv_lbw <- extract_row(results$iv_lbw)
iv_pre <- extract_row(results$iv_preterm)
iv_cs <- extract_row(results$iv_csection)

fs_f <- tryCatch({
  fst <- fitstat(results$first_stage, "ivf")
  if (is.list(fst)) round(fst$ivf$stat, 1) else round(fst, 1)
}, error = function(e) {
  t_val <- coef(results$first_stage)[1] / se(results$first_stage)[1]
  round(t_val^2, 1)
})

tab2 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Supermarket Exits and Birth Outcomes}
\\label{tab:main}
\\begin{tabular}{lccc}
\\hline\\hline
 & Low Birth & Preterm & C-Section \\\\
 & Weight (\\%%%%) & Birth (\\%%%%) & Rate (\\%%%%, placebo) \\\\
\\hline
\\multicolumn{4}{l}{\\textit{Panel A: OLS (State + Year FE)}} \\\\[3pt]
Exit Rate & $%s$ & $%s$ & $%s$ \\\\
 & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: IV (Chain Bankruptcy Instrument)}} \\\\[3pt]
Exit Rate & $%s$ & $%s$ & $%s$ \\\\
 & (%.4f) & (%.4f) & (%.4f) \\\\[3pt]
First-stage $F$ & \\multicolumn{3}{c}{%s} \\\\
\\hline
States & %d & %d & %d \\\\
Observations & %d & %d & %d \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Each column reports a separate regression of the birth outcome rate
(in percentage points) on the supermarket exit rate (annual exits per 1,000 active
SNAP-authorized supermarkets). All specifications include state and year fixed effects
and control for state unemployment rate.
Panel~B instruments the exit rate with the number of pre-existing chain stores belonging
to bankrupt chains (A\\&P 2015, Tops 2018, Southeastern Grocers 2018, Lucky's 2020,
Earth Fare 2020) interacted with post-bankruptcy timing.
Standard errors clustered at the state level in parentheses.
C-section rate serves as a placebo---delivery method should not respond to
food access changes.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
make_cell(ols_lbw[1], ols_lbw[2]),
make_cell(ols_pre[1], ols_pre[2]),
make_cell(ols_cs[1], ols_cs[2]),
ols_lbw[2], ols_pre[2], ols_cs[2],
make_cell(iv_lbw[1], iv_lbw[2]),
make_cell(iv_pre[1], iv_pre[2]),
make_cell(iv_cs[1], iv_cs[2]),
iv_lbw[2], iv_pre[2], iv_cs[2],
fs_f,
n_states, n_states, n_states,
n_obs, n_obs, n_obs)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))


## ---- Table 3: Event Study ----
cat("=== Table 3: Event Study ===\n")

es_lbw_cf <- coeftable(results$es_lbw)
es_pre_cf <- coeftable(results$es_preterm)

es_rows_lbw <- es_lbw_cf[grepl("rel_time|chain_rel|post_chain", rownames(es_lbw_cf)), , drop = FALSE]
es_rows_pre <- es_pre_cf[grepl("rel_time|chain_rel|post_chain", rownames(es_pre_cf)), , drop = FALSE]

get_time <- function(rn) {
  as.integer(gsub(".*::", "", gsub(":ever_treated", "", rn)))
}

es_data <- data.table(
  time = get_time(rownames(es_rows_lbw)),
  lbw_est = es_rows_lbw[, 1], lbw_se = es_rows_lbw[, 2],
  pre_est = es_rows_pre[, 1], pre_se = es_rows_pre[, 2]
)
es_data <- es_data[order(time)]

# Add reference
es_data <- rbind(
  es_data[time < 0],
  data.table(time = -1, lbw_est = 0, lbw_se = NA, pre_est = 0, pre_se = NA),
  es_data[time >= 0]
)

es_tex_rows <- sapply(1:nrow(es_data), function(i) {
  row <- es_data[i]
  if (row$time == -1) {
    sprintf("  $t%+d$ & [ref] & & [ref] & \\\\", row$time)
  } else {
    sprintf("  $t%+d$ & $%s$ & (%.4f) & $%s$ & (%.4f) \\\\",
            row$time,
            make_cell(row$lbw_est, row$lbw_se), row$lbw_se,
            make_cell(row$pre_est, row$pre_se), row$pre_se)
  }
})

tab3 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Event Study: Supermarket Exit and Birth Outcomes}
\\label{tab:event_study}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Low Birth Weight (\\%%%%)} & \\multicolumn{2}{c}{Preterm Birth (\\%%%%)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Event Time & Estimate & SE & Estimate & SE \\\\
\\hline
%s
\\hline
States & %d & & %d & \\\\
Observations & %d & & %d & \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Event-study estimates around the first year a state experiences
supermarket exits. Reference period is $t-1$ (one year before first exit).
Endpoints binned at $t-3$ and $t+3$.
State and year fixed effects included. Standard errors clustered at the state level.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
paste(es_tex_rows, collapse = "\n"),
n_states, n_states, n_obs, n_obs)

writeLines(tab3, file.path(tables_dir, "tab3_event_study.tex"))


## ---- Table 4: Heterogeneity ----
cat("=== Table 4: Heterogeneity ===\n")

het_hi_lbw <- extract_row(results$het_hi_lbw)
het_lo_lbw <- extract_row(results$het_lo_lbw)
het_hi_pre <- extract_row(results$het_hi_preterm)
het_lo_pre <- extract_row(results$het_lo_preterm)

median_med <- median(df$medicaid_share, na.rm = TRUE) * 100
n_hi <- nrow(df[df$medicaid_share >= median(df$medicaid_share, na.rm = TRUE)])
n_lo <- nrow(df) - n_hi

tab4 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity by State Medicaid Share}
\\label{tab:heterogeneity}
\\begin{tabular}{lcc}
\\hline\\hline
 & Low Birth Weight (\\%%%%) & Preterm Birth (\\%%%%) \\\\
\\hline
\\multicolumn{3}{l}{\\textit{Panel A: High Medicaid Share ($\\geq$ %.1f\\%%%%)}} \\\\[3pt]
Exit Rate & $%s$ & $%s$ \\\\
 & (%.4f) & (%.4f) \\\\
$N$ & %d & %d \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Low Medicaid Share ($<$ %.1f\\%%%%)}} \\\\[3pt]
Exit Rate & $%s$ & $%s$ \\\\
 & (%.4f) & (%.4f) \\\\
$N$ & %d & %d \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Sample split at the median state Medicaid birth share (%.1f\\%%%%).
Each cell reports the coefficient on the exit rate from a separate regression
with state and year fixed effects. Standard errors clustered at the state level.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
median_med,
make_cell(het_hi_lbw[1], het_hi_lbw[2]),
make_cell(het_hi_pre[1], het_hi_pre[2]),
het_hi_lbw[2], het_hi_pre[2], n_hi, n_hi,
median_med,
make_cell(het_lo_lbw[1], het_lo_lbw[2]),
make_cell(het_lo_pre[1], het_lo_pre[2]),
het_lo_lbw[2], het_lo_pre[2], n_lo, n_lo,
median_med)

writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))


## ---- Table 5: Robustness ----
cat("=== Table 5: Robustness ===\n")

rob_cum <- extract_row(rob_results$cum_lbw, "cum_exits")
rob_log <- extract_row(rob_results$log_lbw, "log_supers")
rob_nc <- extract_row(rob_results$nocovid_lbw)
rob_wt <- extract_row(rob_results$weighted_lbw)
rob_placebo <- extract_row(rob_results$placebo)

tab5 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks: Low Birth Weight Rate}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\hline\\hline
Specification & Estimate & SE \\\\
\\hline
(1) Baseline (Table~\\ref{tab:main}, Panel A) & $%s$ & (%.4f) \\\\
(2) Cumulative exits (intensive) & $%s$ & (%.4f) \\\\
(3) Log active supermarkets & $%s$ & (%.4f) \\\\
(4) Exclude COVID years (2020--2021) & $%s$ & (%.4f) \\\\
(5) Birth-weighted regression & $%s$ & (%.4f) \\\\
(6) Placebo: $t-2$ pseudo-treatment & $%s$ & (%.4f) \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} All specifications include state and year fixed effects.
Row~(1) reproduces the baseline OLS estimate from Table~\\ref{tab:main}.
Row~(2) uses cumulative supermarket exits as a continuous treatment.
Row~(3) uses log active supermarkets (negative coefficient = exits worsen outcomes).
Row~(4) drops 2020--2021 to address COVID-era confounds.
Row~(5) weights by state births. Row~(6) assigns a pseudo-treatment two years
before actual first exit, restricting to pre-exit observations.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}",
make_cell(ols_lbw[1], ols_lbw[2]), ols_lbw[2],
make_cell(rob_cum[1], rob_cum[2]), rob_cum[2],
make_cell(rob_log[1], rob_log[2]), rob_log[2],
make_cell(rob_nc[1], rob_nc[2]), rob_nc[2],
make_cell(rob_wt[1], rob_wt[2]), rob_wt[2],
make_cell(rob_placebo[1], rob_placebo[2]), rob_placebo[2])

writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))


## ---- SDE Appendix Table ----
cat("=== SDE Appendix Table ===\n")

sds <- results$sds

compute_sde <- function(est, se_val, sd_y) {
  sde <- est / sd_y
  se_sde <- se_val / sd_y
  bucket <- ifelse(sde < -0.15, "Large negative",
            ifelse(sde < -0.05, "Moderate negative",
            ifelse(sde < -0.005, "Small negative",
            ifelse(sde < 0.005, "Null",
            ifelse(sde < 0.05, "Small positive",
            ifelse(sde < 0.15, "Moderate positive",
                                "Large positive"))))))
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

# Panel A: Pooled (IV estimates)
sde_lbw <- compute_sde(iv_lbw[1], iv_lbw[2], sds$lbw)
sde_pre <- compute_sde(iv_pre[1], iv_pre[2], sds$preterm)
sde_cs <- compute_sde(iv_cs[1], iv_cs[2], sds$csection)

# Panel B: Heterogeneous
sd_hi <- sd(df[high_medicaid == 1, lbw_rate_100], na.rm = TRUE)
sd_lo <- sd(df[high_medicaid == 0, lbw_rate_100], na.rm = TRUE)
sde_hi <- compute_sde(het_hi_lbw[1], het_hi_lbw[2], sd_hi)
sde_lo <- compute_sde(het_lo_lbw[1], het_lo_lbw[2], sd_lo)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the closure of SNAP-authorized supermarkets ",
  "cause worse birth outcomes through reduced access to affordable fresh produce? ",
  "\\textbf{Policy mechanism:} Corporate chain bankruptcies force supermarket closures in affected states, ",
  "reducing proximate access to affordable fresh food; pregnant women in areas losing grocery stores face ",
  "longer travel distances or substitution toward convenience stores with limited fresh produce, degrading ",
  "maternal nutrition during a biologically critical nine-month window. ",
  "\\textbf{Outcome definition:} Panel~A reports state-year low birth weight rate (percentage of births ",
  "under 2,500g), preterm birth rate (percentage under 37 weeks gestation), ",
  "and C-section rate (placebo). Panel~B splits the low birth weight outcome by state Medicaid birth share. ",
  "\\textbf{Treatment:} Continuous---annual supermarket exits per 1,000 active SNAP-authorized supermarkets, ",
  "instrumented by pre-existing chain store count interacted with post-bankruptcy timing. ",
  sprintf("\\textbf{Data:} CDC NCHS natality microdata and USDA SNAP Retailer Historical Database, "),
  sprintf("%d--%d, %d states, %d state-year observations. ",
          min(df$year), max(df$year), n_states, n_obs),
  "\\textbf{Method:} Two-stage least squares with state and year fixed effects; ",
  "standard errors clustered at the state level; wild cluster bootstrap reported in robustness. ",
  "\\textbf{Sample:} All 50 states plus the District of Columbia; natality outcomes computed from ",
  "individual birth records with valid delivery method and payment source. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where ",
  "SD($X$) is the cross-state standard deviation of the exit rate and SD($Y$) is the standard deviation ",
  "of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# For continuous treatment SDE: SDE = beta * SD(X) / SD(Y)
sd_exit_rate <- sd(df$exit_rate, na.rm = TRUE)

sde_cont <- function(est, se_val, sd_x, sd_y) {
  sde <- est * sd_x / sd_y
  se_sde <- se_val * sd_x / sd_y
  bucket <- ifelse(sde < -0.15, "Large negative",
            ifelse(sde < -0.05, "Moderate negative",
            ifelse(sde < -0.005, "Small negative",
            ifelse(sde < 0.005, "Null",
            ifelse(sde < 0.05, "Small positive",
            ifelse(sde < 0.15, "Moderate positive",
                                "Large positive"))))))
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

sde_lbw <- sde_cont(iv_lbw[1], iv_lbw[2], sd_exit_rate, sds$lbw)
sde_pre <- sde_cont(iv_pre[1], iv_pre[2], sd_exit_rate, sds$preterm)
sde_cs <- sde_cont(iv_cs[1], iv_cs[2], sd_exit_rate, sds$csection)

sd_exit_hi <- sd(df[high_medicaid == 1, exit_rate], na.rm = TRUE)
sd_exit_lo <- sd(df[high_medicaid == 0, exit_rate], na.rm = TRUE)
sde_hi <- sde_cont(het_hi_lbw[1], het_hi_lbw[2], sd_exit_hi, sd_hi)
sde_lo <- sde_cont(het_lo_lbw[1], het_lo_lbw[2], sd_exit_lo, sd_lo)

tabF1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled (IV Estimates)}} \\\\[3pt]
Low birth weight (\\%%%%) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
Preterm birth (\\%%%%) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
C-section rate (\\%%%%, placebo) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Medicaid Share Split, OLS)}} \\\\[3pt]
LBW -- High Medicaid & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
LBW -- Low Medicaid & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{table}",
iv_lbw[1], iv_lbw[2], sds$lbw, sde_lbw$sde, sde_lbw$se_sde, sde_lbw$bucket,
iv_pre[1], iv_pre[2], sds$preterm, sde_pre$sde, sde_pre$se_sde, sde_pre$bucket,
iv_cs[1], iv_cs[2], sds$csection, sde_cs$sde, sde_cs$se_sde, sde_cs$bucket,
het_hi_lbw[1], het_hi_lbw[2], sd_hi, sde_hi$sde, sde_hi$se_sde, sde_hi$bucket,
het_lo_lbw[1], het_lo_lbw[2], sd_lo, sde_lo$sde, sde_lo$se_sde, sde_lo$bucket,
sde_notes)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:", paste(list.files(tables_dir, pattern = "\\.tex$"), collapse = ", "), "\n")
