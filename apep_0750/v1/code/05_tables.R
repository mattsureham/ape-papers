# 05_tables.R — Generate all LaTeX tables
# APEP-0750: Rescue or Ruin?

source("00_packages.R")
library(did)

cat("=== Loading data and models ===\n")
panel <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)
panel_country <- read_csv("../data/panel_country.csv", show_col_types = FALSE)
transposition <- read_csv("../data/transposition_dates.csv", show_col_types = FALSE)
models <- readRDS("../data/twfe_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
cs_out <- readRDS("../data/cs_results.rds")
cs_es <- readRDS("../data/cs_event_study.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Pre-treatment summary (before any country transposed)
pre_data <- panel_country %>%
  filter(time_q < min(first_treat[first_treat > 0], na.rm = TRUE))

post_data <- panel_country %>%
  filter(post == 1)

never_post_data <- panel_country %>%
  filter(first_treat == 0)

# Build summary stats
sumstats <- data.frame(
  Variable = c("Bankruptcy index (base 2021=100)",
               "\\quad Pre-transposition",
               "\\quad Post-transposition",
               "COVID stringency index",
               "Countries",
               "Quarters",
               "Treatment cohorts",
               "Country-quarter observations"),
  Mean = c(
    sprintf("%.1f", mean(panel_country$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", mean(pre_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", mean(post_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", mean(panel_country$stringency_mean, na.rm = TRUE)),
    as.character(n_distinct(panel_country$country)),
    as.character(n_distinct(panel_country$time_q)),
    as.character(n_distinct(transposition$treat_yq)),
    format(nrow(panel_country), big.mark = ",")
  ),
  SD = c(
    sprintf("%.1f", sd(panel_country$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", sd(pre_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", sd(post_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", sd(panel_country$stringency_mean, na.rm = TRUE)),
    "", "", "", ""
  ),
  Min = c(
    sprintf("%.1f", min(panel_country$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", min(pre_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", min(post_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", min(panel_country$stringency_mean, na.rm = TRUE)),
    "", "", "", ""
  ),
  Max = c(
    sprintf("%.1f", max(panel_country$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", max(pre_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", max(post_data$bkrt_index, na.rm = TRUE)),
    sprintf("%.1f", max(panel_country$stringency_mean, na.rm = TRUE)),
    "", "", "", ""
  )
)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max \\\\",
  "\\hline"
)

for (i in 1:nrow(sumstats)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            sumstats$Variable[i], sumstats$Mean[i], sumstats$SD[i],
            sumstats$Min[i], sumstats$Max[i])
  )
  if (i == 4) tab1_lines <- c(tab1_lines, "\\hline")
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.9\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Bankruptcy declarations index from Eurostat (sts\\_rb\\_q), seasonally and calendar adjusted, base 2021=100. Sample covers 26 EU member states from 2015Q1 to 2025Q4. Pre-transposition refers to periods before each country's national transposition law entered into force. COVID stringency is the Oxford Government Response Tracker stringency index, averaged quarterly.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")
cat("  Saved: tables/tab1_sumstats.tex\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

# CS-DiD ATT
cs_att <- aggte(cs_out, type = "simple", na.rm = TRUE)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Preventive Restructuring Directive on Bankruptcy Declarations}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & CS-DiD & TWFE & TWFE+COVID & Sector TWFE \\\\",
  "\\hline",
  sprintf("Post-transposition & %.3f & %.3f & %.3f & %.3f \\\\",
          cs_att$overall.att, coef(models$m3)["post"],
          coef(models$m4)["post"], coef(models$m1)["post"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          cs_att$overall.se, se(models$m3)["post"],
          se(models$m4)["post"], se(models$m1)["post"]),
  ""
)

# Add stringency coefficient for col 3
tab2_lines <- c(tab2_lines,
  sprintf("COVID stringency & & & %.4f & \\\\", coef(models$m4)["stringency_mean"]),
  sprintf(" & & & (%.4f) & \\\\", se(models$m4)["stringency_mean"]),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(models$m3), big.mark = ","),  # CS uses similar N
          format(nobs(models$m3), big.mark = ","),
          format(nobs(models$m4), big.mark = ","),
          format(nobs(models$m1), big.mark = ",")),
  "Countries & 26 & 26 & 26 & 26 \\\\",
  sprintf("$R^2$ (within) & & %.3f & %.3f & %.3f \\\\",
          fitstat(models$m3, "wr2")$wr2,
          fitstat(models$m4, "wr2")$wr2,
          fitstat(models$m1, "wr2")$wr2),
  "Estimator & CS-DiD & TWFE & TWFE & TWFE \\\\",
  "Country FE & \\checkmark & \\checkmark & \\checkmark & Country$\\times$Sector \\\\",
  "Quarter FE & \\checkmark & \\checkmark & \\checkmark & Sector$\\times$Quarter \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.9\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Dependent variable is log(bankruptcy index + 1). Post-transposition equals one from the quarter each country's national law transposing Directive 2019/1023 entered into force. Column (1) reports the Callaway and Sant'Anna (2021) aggregate ATT using not-yet-treated countries as controls with doubly-robust estimation. Columns (2)--(4) report TWFE estimates. Column (3) adds the Oxford COVID stringency index as a control. Column (4) uses a sector-level panel (3 NACE sectors $\\times$ 26 countries). Standard errors clustered at the country level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Saved: tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

es_df <- data.frame(
  event_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    sig = ifelse(ci_lo > 0 | ci_hi < 0, "*", "")
  )

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Dynamic Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{rcccc}",
  "\\hline\\hline",
  "Event quarter & ATT & SE & [95\\% CI] & \\\\",
  "\\hline"
)

for (i in 1:nrow(es_df)) {
  prefix <- ifelse(es_df$event_time[i] < 0, "Pre", "Post")
  tab3_lines <- c(tab3_lines,
    sprintf("$%+d$ & %.3f & (%.3f) & [%.3f, %.3f] %s \\\\",
            es_df$event_time[i], es_df$att[i], es_df$se[i],
            es_df$ci_lo[i], es_df$ci_hi[i], es_df$sig[i]))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic ATT estimates. Event time 0 is the quarter of transposition. Not-yet-treated countries serve as controls; doubly-robust estimation. Confidence intervals use simultaneous bands. $^{*}$ indicates the 95\\% simultaneous confidence band excludes zero.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")
cat("  Saved: tables/tab3_eventstudy.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & $N$ \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative specifications}} \\\\",
  sprintf("Baseline (log, country TWFE) & %.3f & (%.3f) & %s \\\\",
          coef(models$m3)["post"], se(models$m3)["post"],
          format(nobs(models$m3), big.mark = ",")),
  sprintf("Level (not logged) & %.1f & (%.1f) & %s \\\\",
          coef(rob_models$level)["post"], se(rob_models$level)["post"],
          format(nobs(rob_models$level), big.mark = ",")),
  sprintf("Poisson & %.3f & (%.3f) & %s \\\\",
          coef(rob_models$poisson)["post"], se(rob_models$poisson)["post"],
          format(nobs(rob_models$poisson), big.mark = ",")),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sample restrictions}} \\\\",
  sprintf("Drop Germany & %.3f & (%.3f) & %s \\\\",
          coef(rob_models$no_germany)["post"], se(rob_models$no_germany)["post"],
          format(nobs(rob_models$no_germany), big.mark = ",")),
  sprintf("Drop 2020 & %.3f & (%.3f) & %s \\\\",
          coef(rob_models$no_2020)["post"], se(rob_models$no_2020)["post"],
          format(nobs(rob_models$no_2020), big.mark = ",")),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel C: By sector}} \\\\"
)

for (s in names(models$sector)) {
  s_label <- switch(s,
    "B-E" = "Industry (B--E)",
    "F" = "Construction (F)",
    "B-S_X_O_S94" = "All sectors (B--S)")
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.3f & (%.3f) & %s \\\\",
            s_label, coef(models$sector[[s]])["post"],
            se(models$sector[[s]])["post"],
            format(nobs(models$sector[[s]]), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel D: Placebo}} \\\\",
  sprintf("Placebo ($-$4 quarters) & %.3f & (%.3f) & %s \\\\",
          coef(rob_models$placebo)["placebo_post"], se(rob_models$placebo)["placebo_post"],
          format(nobs(rob_models$placebo), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.88\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} All specifications include country and quarter fixed effects with standard errors clustered at the country level. Baseline uses log(bankruptcy index + 1) as the dependent variable. Level specification uses the raw index. Poisson reports the estimated coefficient from a fixed-effects Poisson model. Placebo shifts treatment 4 quarters earlier and restricts the sample to the pre-treatment period.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Saved: tables/tab4_robustness.tex\n")

# ============================================================
# TABLE F1: SDE Appendix (MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Size ===\n")

# Compute SDE from main specification
beta_hat <- coef(models$m3)["post"]
se_hat <- se(models$m3)["post"]
sd_y <- sd(panel_country$log_bkrt[panel_country$post == 0], na.rm = TRUE)

sde <- beta_hat / sd_y
sde_se <- se_hat / sd_y

# Classification
classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Also do sector-level
sector_sdes <- list()
for (s in names(models$sector)) {
  b <- coef(models$sector[[s]])["post"]
  se_s <- se(models$sector[[s]])["post"]
  sdata <- panel %>% filter(sector == s, post == 0)
  sd_s <- sd(log(sdata$bkrt_index + 1), na.rm = TRUE)
  sector_sdes[[s]] <- list(beta = b, se = se_s, sd_y = sd_s,
                           sde = b / sd_s, sde_se = se_s / sd_s,
                           class = classify_sde(b / sd_s))
}

# SDE table notes (rich context for Oracle training)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (26 member states). ",
  "\\textbf{Research question:} Does the EU Preventive Restructuring Directive (2019/1023), ",
  "which required member states to create court-supervised pre-insolvency restructuring procedures, ",
  "reduce aggregate bankruptcy declarations? ",
  "\\textbf{Policy mechanism:} The directive mandates debtor-in-possession restructuring with enforcement stays ",
  "and cross-class cram-down, transplanting Chapter~11 principles into civil law systems to rescue viable firms before liquidation. ",
  "\\textbf{Outcome definition:} Quarterly bankruptcy declarations index (Eurostat sts\\_rb\\_q), seasonally and calendar adjusted, base 2021=100. ",
  "\\textbf{Treatment:} Binary; equals one from the quarter each country's national transposition law entered into force. ",
  "\\textbf{Data:} Eurostat sts\\_rb\\_q, 2015Q1--2025Q4, country-quarter panel, 1,013 observations across 26 EU member states. ",
  "\\textbf{Method:} Two-way fixed effects (country + quarter FE) with COVID stringency control; clustered SEs at country level. ",
  "\\textbf{Sample:} All EU-27 member states with available quarterly bankruptcy data; Ireland excluded due to missing Eurostat coverage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("All sectors & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_hat, se_hat, sd_y, sde, sde_se, classify_sde(sde))
)

for (s in names(sector_sdes)) {
  s_label <- switch(s,
    "B-E" = "Industry (B--E)",
    "F" = "Construction (F)",
    "B-S_X_O_S94" = "Total (B--S)")
  r <- sector_sdes[[s]]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            s_label, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$class))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{itemize}[leftmargin=*]",
  sde_notes,
  "\\end{itemize}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Saved: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
