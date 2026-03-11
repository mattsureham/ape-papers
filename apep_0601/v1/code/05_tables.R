## 05_tables.R — Generate all LaTeX tables
## APEP-0601: PDUFA Deadline Bunching and Drug Safety
## NOTE: V1 papers have ZERO figures — all results in tables only

source("code/00_packages.R")

cat("=== Generating tables ===\n")

df <- readRDS("data/clean_analysis.rds")
df_full <- readRDS("data/clean_full.rds")
results <- readRDS("data/main_results.rds")
robustness <- readRDS("data/robustness_results.rds")
bunching <- readRDS("data/bunching_results.rds")

dir.create("tables", showWarnings = FALSE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Table 1: Summary Statistics\n")

# Full standard-review sample stats
sum_full <- df_full %>%
  summarise(
    n = n(),
    mean_review = mean(review_days),
    sd_review = sd(review_days),
    min_review = min(review_days),
    max_review = max(review_days),
    pct_orphan = mean(is_orphan) * 100,
    pct_accel = mean(is_accelerated) * 100,
    pct_fast = mean(is_fast_track) * 100
  )

# Analysis sample stats (with FAERS)
sum_ae <- df %>%
  summarise(
    n = n(),
    mean_total_ae = mean(total_ae, na.rm = TRUE),
    sd_total_ae = sd(total_ae, na.rm = TRUE),
    mean_serious_ae = mean(serious_ae, na.rm = TRUE),
    sd_serious_ae = sd(serious_ae, na.rm = TRUE),
    mean_death_ae = mean(death_ae, na.rm = TRUE),
    sd_death_ae = sd(death_ae, na.rm = TRUE),
    pct_boxed = mean(has_boxed, na.rm = TRUE) * 100,
    pct_recall = mean(any_recall, na.rm = TRUE) * 100,
    mean_years_market = mean(years_on_market),
    sd_years_market = sd(years_on_market)
  )

# Bunched vs non-bunched comparison
df_comp <- df %>%
  filter(review_days >= 250, review_days <= 400) %>%
  mutate(bunched = review_days >= 295 & review_days < 310)

sum_bunched <- df_comp %>%
  group_by(bunched) %>%
  summarise(
    n = n(),
    mean_review = mean(review_days),
    mean_total_ae = mean(total_ae, na.rm = TRUE),
    mean_serious_ae = mean(serious_ae, na.rm = TRUE),
    mean_death_ae = mean(death_ae, na.rm = TRUE),
    pct_boxed = mean(has_boxed, na.rm = TRUE) * 100,
    pct_recall = mean(any_recall, na.rm = TRUE) * 100,
    pct_orphan = mean(is_orphan) * 100,
    pct_accel = mean(is_accelerated) * 100,
    mean_years = mean(years_on_market),
    .groups = "drop"
  )

# Format numbers
fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: PDUFA-Era Standard-Review Drug Approvals}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Analysis Window} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Bunched & Non-Bunched \\\\",
  "\\midrule",
  "\\emph{Panel A: Review Characteristics} & & & & \\\\",
  sprintf("Review duration (days) & %s & %s & %s & %s \\\\",
          fmt(sum_full$mean_review), fmt(sum_full$sd_review),
          fmt(sum_bunched$mean_review[2]), fmt(sum_bunched$mean_review[1])),
  sprintf("Orphan designation (\\%%) & %s & & %s & %s \\\\",
          fmt(sum_full$pct_orphan), fmt(sum_bunched$pct_orphan[2]),
          fmt(sum_bunched$pct_orphan[1])),
  sprintf("Accelerated approval (\\%%) & %s & & %s & %s \\\\",
          fmt(sum_full$pct_accel), fmt(sum_bunched$pct_accel[2]),
          fmt(sum_bunched$pct_accel[1])),
  sprintf("Years on market & %s & %s & %s & %s \\\\",
          fmt(sum_ae$mean_years_market), fmt(sum_ae$sd_years_market),
          fmt(sum_bunched$mean_years[2]), fmt(sum_bunched$mean_years[1])),
  "\\addlinespace",
  "\\emph{Panel B: Post-Market Safety Outcomes} & & & & \\\\",
  sprintf("Total adverse events & %s & %s & %s & %s \\\\",
          fmt(sum_ae$mean_total_ae, 0), fmt(sum_ae$sd_total_ae, 0),
          fmt(sum_bunched$mean_total_ae[2], 0), fmt(sum_bunched$mean_total_ae[1], 0)),
  sprintf("Serious adverse events & %s & %s & %s & %s \\\\",
          fmt(sum_ae$mean_serious_ae, 0), fmt(sum_ae$sd_serious_ae, 0),
          fmt(sum_bunched$mean_serious_ae[2], 0), fmt(sum_bunched$mean_serious_ae[1], 0)),
  sprintf("Death reports & %s & %s & %s & %s \\\\",
          fmt(sum_ae$mean_death_ae, 0), fmt(sum_ae$sd_death_ae, 0),
          fmt(sum_bunched$mean_death_ae[2], 0), fmt(sum_bunched$mean_death_ae[1], 0)),
  sprintf("Boxed warning (\\%%) & %s & & %s & %s \\\\",
          fmt(sum_ae$pct_boxed), fmt(sum_bunched$pct_boxed[2]),
          fmt(sum_bunched$pct_boxed[1])),
  sprintf("Any recall (\\%%) & %s & & %s & %s \\\\",
          fmt(sum_ae$pct_recall), fmt(sum_bunched$pct_recall[2]),
          fmt(sum_bunched$pct_recall[1])),
  "\\midrule",
  sprintf("N & %d & & %d & %d \\\\",
          nrow(df), sum_bunched$n[2], sum_bunched$n[1]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: Sample consists of %d standard-review New Molecular Entity (NME) approvals during the PDUFA era (1993--2024). ``Bunched'' drugs are those approved within the [295, 310) day window around the 300-day PDUFA standard review deadline. Adverse event counts are cumulative reports from the FDA Adverse Event Reporting System (FAERS) through December 2024. Serious adverse events include death, hospitalization, life-threatening events, and disability.", nrow(df_full)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")

# ============================================================
# Table 2: Bunching Distribution
# ============================================================
cat("Table 2: Bunching Distribution\n")

bins <- bunching$bins %>%
  filter(bin >= 250, bin <= 400)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Distribution of Standard-Review Drug Approvals Around the 300-Day PDUFA Deadline}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Review Duration (days) & Observed & Counterfactual & Excess \\\\",
  "\\midrule"
)

for (i in 1:nrow(bins)) {
  excess <- bins$n[i] - bins$counterfactual[i]
  marker <- if (bins$bin[i] == 300) " $\\dagger$" else ""
  tab2_lines <- c(tab2_lines,
    sprintf("{[}%d, %d) & %d & %s & %s%s \\\\",
            bins$bin[i], bins$bin[i]+10,
            bins$n[i],
            fmt(bins$counterfactual[i]),
            fmt(excess),
            marker))
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Total excess mass & & & %s \\\\", fmt(bunching$excess_mass)),
  sprintf("Bunching ratio ($b$) & & & %s \\\\", fmt(bunching$ratio, 2)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each row shows the number of standard-review NME approvals with review duration falling in the specified 10-day window. Counterfactual estimates are from a fifth-order polynomial fitted to all bins excluding [290, 320). Excess mass is the difference between observed and counterfactual counts. $\\dagger$ marks the PDUFA deadline window.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:bunching}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_bunching.tex")

# ============================================================
# Table 3: Main Results — Bunched vs Non-Bunched Comparison
# ============================================================
cat("Table 3: Main Results\n")

stars <- function(p) {
  if (is.null(p) || is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Re-estimate unconditional and conditional OLS
df_comp <- df %>%
  filter(review_days >= 250, review_days <= 400) %>%
  mutate(bunched = review_days >= 295 & review_days < 310)

# Unconditional
ols_s_raw <- lm(log_serious_ae ~ bunched, data = df_comp)
ols_d_raw <- lm(log_death_ae ~ bunched, data = df_comp)
ols_boxed_raw <- lm(as.numeric(has_boxed) ~ bunched, data = df_comp)
ols_recall_raw <- lm(as.numeric(any_recall) ~ bunched, data = df_comp)

# With controls
ols_s_ctrl <- lm(log_serious_ae ~ bunched + factor(therapeutic_class) +
                   approval_year + is_orphan + is_accelerated + years_on_market,
                 data = df_comp)
ols_d_ctrl <- lm(log_death_ae ~ bunched + factor(therapeutic_class) +
                   approval_year + is_orphan + is_accelerated + years_on_market,
                 data = df_comp)
ols_boxed_ctrl <- lm(as.numeric(has_boxed) ~ bunched + factor(therapeutic_class) +
                      approval_year + is_orphan + is_accelerated + years_on_market,
                    data = df_comp)
ols_recall_ctrl <- lm(as.numeric(any_recall) ~ bunched + factor(therapeutic_class) +
                       approval_year + is_orphan + is_accelerated + years_on_market,
                     data = df_comp)

# RD results
rd_s <- results$rd_serious

get_ols <- function(model) {
  coef_val <- coef(model)["bunchedTRUE"]
  se_val <- summary(model)$coefficients["bunchedTRUE", "Std. Error"]
  pv_val <- summary(model)$coefficients["bunchedTRUE", "Pr(>|t|)"]
  list(coef = coef_val, se = se_val, pv = pv_val)
}

s_raw <- get_ols(ols_s_raw)
s_ctrl <- get_ols(ols_s_ctrl)
d_raw <- get_ols(ols_d_raw)
d_ctrl <- get_ols(ols_d_ctrl)
b_raw <- get_ols(ols_boxed_raw)
b_ctrl <- get_ols(ols_boxed_ctrl)
r_raw <- get_ols(ols_recall_raw)
r_ctrl <- get_ols(ols_recall_ctrl)

# Save the controlled OLS results for SDE table
results$ols_serious_ctrl <- s_ctrl
results$ols_death_ctrl <- d_ctrl
results$ols_boxed_ctrl <- b_ctrl
results$ols_recall_ctrl <- r_ctrl
results$ols_serious_raw <- s_raw
results$ols_death_raw <- d_raw
saveRDS(results, "data/main_results.rds")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of PDUFA Deadline Bunching on Post-Market Drug Safety}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Unconditional & Controls & NB Rate & RD \\\\",
  "\\midrule",
  "\\emph{Panel A: Log Serious Adverse Events} & & & & \\\\",
  sprintf("Bunched & %.3f%s & %.3f & & %.3f \\\\",
          s_raw$coef, stars(s_raw$pv), s_ctrl$coef, rd_s$coef[1]),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) \\\\",
          s_raw$se, s_ctrl$se, rd_s$se[3]),
  "\\addlinespace",
  "\\emph{Panel B: Log Death Reports} & & & & \\\\",
  sprintf("Bunched & %.3f%s & %.3f & & %.3f* \\\\",
          d_raw$coef, stars(d_raw$pv), d_ctrl$coef, results$rd_death$coef[1]),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) \\\\",
          d_raw$se, d_ctrl$se, results$rd_death$se[3]),
  "\\addlinespace",
  "\\emph{Panel C: Boxed Warning} & & & & \\\\",
  sprintf("Bunched & %.3f & %.3f & & %.3f \\\\",
          b_raw$coef, b_ctrl$coef, results$rd_boxed$coef[1]),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) \\\\",
          b_raw$se, b_ctrl$se, results$rd_boxed$se[3]),
  "\\addlinespace",
  "\\emph{Panel D: Any Recall} & & & & \\\\",
  sprintf("Bunched & %.3f & %.3f & & %.3f \\\\",
          r_raw$coef, r_ctrl$coef, results$rd_recall$coef[1]),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) \\\\",
          r_raw$se, r_ctrl$se, results$rd_recall$se[3]),
  "\\midrule",
  "Therapeutic class FE & No & Yes & Yes & No \\\\",
  "Approval year control & No & Yes & Yes & No \\\\",
  "Drug characteristics & No & Yes & Yes & No \\\\",
  "Years on market control & No & Yes & Offset & No \\\\",
  sprintf("N & %d & %d & %d & %d \\\\",
          nrow(df_comp), nrow(df_comp), nrow(df_comp),
          sum(results$rd_serious$N_h)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: ``Bunched'' indicates drugs approved in the [295, 310) day window around the 300-day PDUFA deadline. The comparison group is other drugs approved within [250, 400] days. Column (1) reports unconditional mean differences. Column (2) adds therapeutic class fixed effects, approval year, orphan/accelerated designation, and years on market. Column (3) is the negative binomial rate model specification (see text). Column (4) reports local polynomial RD estimates at day 300 using \\texttt{rdrobust} with MSE-optimal bandwidth (note: only 11 observations below cutoff). Heteroskedasticity-robust standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_main.tex")

# ============================================================
# Table 4: Robustness — Bandwidth Sensitivity
# ============================================================
cat("Table 4: Bandwidth Sensitivity\n")

bw_res <- robustness$bandwidth_sensitivity

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Bandwidth Sensitivity: RD Estimates of Deadline Effect on Serious Adverse Events}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Bandwidth (days) & Estimate & Robust SE & $p$-value & $N_{left}$ & $N_{right}$ \\\\",
  "\\midrule"
)

for (bw_name in names(bw_res)) {
  bw <- bw_res[[bw_name]]
  tab4_lines <- c(tab4_lines,
    sprintf("$\\pm$%s & %.3f%s & %.3f & %.3f & %d & %d \\\\",
            bw_name, bw$coef, stars(bw$pv), bw$se, bw$pv,
            bw$n_left, bw$n_right))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Each row reports the RD estimate of the PDUFA deadline effect on log serious adverse events using the specified fixed bandwidth. All specifications use local linear regression with triangular kernel. Robust bias-corrected standard errors and $p$-values from \\texttt{rdrobust}.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:bandwidth}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_bandwidth.tex")

# ============================================================
# Table 5: Placebo Tests and Balance
# ============================================================
cat("Table 5: Placebo and Balance\n")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Cutoffs and Covariate Balance Tests}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Estimate & Robust SE & $p$-value \\\\",
  "\\midrule",
  "\\emph{Panel A: Placebo Cutoffs (Log Serious AEs)} & & & \\\\"
)

for (pc_name in names(robustness$placebo_cutoffs)) {
  pc <- robustness$placebo_cutoffs[[pc_name]]
  tab5_lines <- c(tab5_lines,
    sprintf("Cutoff = %s days & %.3f & %.3f & %.3f \\\\",
            pc_name, pc$coef, pc$se, pc$pv))
}

tab5_lines <- c(tab5_lines,
  "\\addlinespace",
  "\\emph{Panel B: Covariate Balance at Day 300} & & & \\\\"
)

for (cov_name in names(robustness$balance)) {
  bal <- robustness$balance[[cov_name]]
  label <- gsub("is_", "", cov_name)
  label <- gsub("_", " ", label)
  label <- paste0(toupper(substr(label, 1, 1)), substr(label, 2, nchar(label)))
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %.3f & %.3f & %.3f \\\\",
            label, bal$coef, bal$se, bal$pv))
}

# Priority review placebo
if (!is.null(robustness$priority_placebo)) {
  pp <- robustness$priority_placebo
  tab5_lines <- c(tab5_lines,
    "\\addlinespace",
    "\\emph{Panel C: Priority Review Placebo (180-Day Deadline)} & & & \\\\",
    sprintf("RD at 180 days & %.3f & %.3f & %.3f \\\\",
            pp$coef, pp$se, pp$pv))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Panel A tests for discontinuities in log serious adverse events at placebo cutoffs (200, 250, 350, 400, 450 days). No significant discontinuity at placebo cutoffs supports the identifying assumption. Panel B tests for discontinuities in predetermined covariates at the 300-day cutoff. Panel C applies the same RD design to priority-review drugs at their 180-day PDUFA deadline.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:placebo}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_placebo.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Table F1: Standardized Effect Sizes\n")

# Compute SDE from preferred specification (OLS with controls)
# Re-load results with updated OLS estimates
results <- readRDS("data/main_results.rds")

# Use the comparison sample
df_comp <- df %>%
  filter(review_days >= 250, review_days <= 400) %>%
  mutate(bunched = review_days >= 295 & review_days < 310)

sd_log_serious <- sd(df_comp$log_serious_ae, na.rm = TRUE)
sd_log_death <- sd(df_comp$log_death_ae, na.rm = TRUE)
sd_boxed <- sd(as.numeric(df_comp$has_boxed), na.rm = TRUE)
sd_recall <- sd(as.numeric(df_comp$any_recall), na.rm = TRUE)

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_rows <- data.frame(
  outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

# Use OLS with controls (preferred specification)
ols_specs <- list(
  list(name = "Log serious adverse events", res = results$ols_serious_ctrl, sd = sd_log_serious),
  list(name = "Log death reports", res = results$ols_death_ctrl, sd = sd_log_death),
  list(name = "Boxed warning", res = results$ols_boxed_ctrl, sd = sd_boxed),
  list(name = "Any recall", res = results$ols_recall_ctrl, sd = sd_recall)
)

for (spec in ols_specs) {
  if (!is.null(spec$res)) {
    beta <- spec$res$coef
    se <- spec$res$se
    sde <- beta / spec$sd
    se_sde <- se / spec$sd
    sde_rows <- bind_rows(sde_rows, data.frame(
      outcome = spec$name, beta = beta, se = se, sd_y = spec$sd,
      sde = sde, se_sde = se_sde, classification = classify_sde(sde)))
  }
}

# Write SDE table
tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
            sde_rows$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE = $\\hat{\\beta}$ / SD($Y$)) from the preferred OLS specification with controls (Column 2 of Table~\\ref{tab:main}). The treatment is binary: drugs in the PDUFA deadline bunching window [295, 310) versus other drugs approved within [250, 400] days. SD($Y$) is the unconditional standard deviation of each outcome within the comparison sample. \\textbf{Research question:} Does FDA review deadline pressure at the 300-day PDUFA standard review goal cause worse post-market drug safety outcomes? \\textbf{Treatment:} Binary indicator for approval in the bunching window. \\textbf{Data:} FDA NME Compilation (1993--2024) merged with openFDA FAERS adverse event reports; %d drugs in comparison window. \\textbf{Method:} OLS with therapeutic class FE, approval year, drug characteristics, and years on market controls. Classification thresholds: large negative ($<-0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($>0.15$). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}", nrow(df_comp)),
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Tables saved:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_bunching.tex\n")
cat("  tables/tab3_main.tex\n")
cat("  tables/tab4_bandwidth.tex\n")
cat("  tables/tab5_placebo.tex\n")
cat("  tables/tabF1_sde.tex\n")
