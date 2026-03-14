## 05_tables.R — Generate all LaTeX tables for APEP-0683
## Council Tax Empty Homes Premium and Long-Term Vacancy

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Full sample stats
full_stats <- panel %>%
  filter(year >= 2004, year <= 2024) %>%
  summarise(
    `Long-term vacant dwellings` = paste0(round(mean(long_term_vacant, na.rm = TRUE)), " (",
                                           round(sd(long_term_vacant, na.rm = TRUE)), ")"),
    `All vacant dwellings` = paste0(round(mean(all_vacant, na.rm = TRUE)), " (",
                                     round(sd(all_vacant, na.rm = TRUE)), ")"),
    `LTV share (\\%)` = paste0(round(mean(ltv_share, na.rm = TRUE), 1), " (",
                                round(sd(ltv_share, na.rm = TRUE), 1), ")"),
    `Log(long-term vacants)` = paste0(round(mean(log_ltv, na.rm = TRUE), 2), " (",
                                       round(sd(log_ltv, na.rm = TRUE), 2), ")"),
    `LTV per 1,000 pop.` = paste0(round(mean(ltv_per_1000, na.rm = TRUE), 2), " (",
                                    round(sd(ltv_per_1000, na.rm = TRUE), 2), ")"),
    `Population` = paste0(format(round(mean(population, na.rm = TRUE)), big.mark = ","), " (",
                           format(round(sd(population, na.rm = TRUE)), big.mark = ","), ")")
  )

# By treatment group
grp_stats <- panel %>%
  filter(year >= 2004, year <= 2024) %>%
  group_by(ever_treated) %>%
  summarise(
    ltv_mean = round(mean(long_term_vacant, na.rm = TRUE)),
    ltv_sd = round(sd(long_term_vacant, na.rm = TRUE)),
    av_mean = round(mean(all_vacant, na.rm = TRUE)),
    av_sd = round(sd(all_vacant, na.rm = TRUE)),
    share_mean = round(mean(ltv_share, na.rm = TRUE), 1),
    share_sd = round(sd(ltv_share, na.rm = TRUE), 1),
    log_mean = round(mean(log_ltv, na.rm = TRUE), 2),
    log_sd = round(sd(log_ltv, na.rm = TRUE), 2),
    pc_mean = round(mean(ltv_per_1000, na.rm = TRUE), 2),
    pc_sd = round(sd(ltv_per_1000, na.rm = TRUE), 2),
    pop_mean = round(mean(population, na.rm = TRUE)),
    pop_sd = round(sd(population, na.rm = TRUE)),
    n_la = n_distinct(ons_code),
    n_obs = n(),
    .groups = "drop"
  )

# Write LaTeX table
tex1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Premium Adopters} & \\multicolumn{2}{c}{Never Adopted} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

t_row <- grp_stats %>% filter(ever_treated)
c_row <- grp_stats %>% filter(!ever_treated)

tex1 <- paste0(tex1,
  sprintf("Long-term vacant dwellings & %s & %s & %s & %s \\\\\n",
          format(t_row$ltv_mean, big.mark = ","), format(t_row$ltv_sd, big.mark = ","),
          format(c_row$ltv_mean, big.mark = ","), format(c_row$ltv_sd, big.mark = ",")),
  sprintf("All vacant dwellings & %s & %s & %s & %s \\\\\n",
          format(t_row$av_mean, big.mark = ","), format(t_row$av_sd, big.mark = ","),
          format(c_row$av_mean, big.mark = ","), format(c_row$av_sd, big.mark = ",")),
  sprintf("LTV share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          t_row$share_mean, t_row$share_sd, c_row$share_mean, c_row$share_sd),
  sprintf("Log(long-term vacants) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          t_row$log_mean, t_row$log_sd, c_row$log_mean, c_row$log_sd),
  sprintf("LTV per 1,000 population & %.2f & %.2f & %.2f & %.2f \\\\\n",
          t_row$pc_mean, t_row$pc_sd, c_row$pc_mean, c_row$pc_sd),
  sprintf("Population & %s & %s & %s & %s \\\\\n",
          format(t_row$pop_mean, big.mark = ","), format(t_row$pop_sd, big.mark = ","),
          format(c_row$pop_mean, big.mark = ","), format(c_row$pop_sd, big.mark = ",")),
  "\\midrule\n",
  sprintf("Local authorities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          t_row$n_la, c_row$n_la),
  sprintf("LA-year observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(t_row$n_obs, big.mark = ","), format(c_row$n_obs, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Sample covers 274 English local authorities observed annually from 2004 to 2024. ",
  "Premium Adopters are 269 LAs that adopted the empty homes council tax premium by 2025; ",
  "Never Adopted are 5 LAs (Amber Valley, Bolsover, Castle Point, Gravesham, Ribble Valley) that had not adopted as of October 2025. ",
  "Long-term vacant dwellings are those empty for six months or more, as reported in MHCLG Live Table 615. ",
  "LTV share is long-term vacants as a percentage of all vacants.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tex1, file.path(tables_dir, "tab1_summary.tex"))
cat("  Wrote tab1_summary.tex\n")

## ============================================================
## Table 2: Main DiD Results
## ============================================================
cat("\n=== Table 2: Main Results ===\n")

m1 <- readRDS(file.path(data_dir, "model_twfe_log.rds"))
m2 <- readRDS(file.path(data_dir, "model_twfe_level.rds"))
m3 <- readRDS(file.path(data_dir, "model_twfe_share.rds"))
m4 <- readRDS(file.path(data_dir, "model_twfe_percap.rds"))

# Load CS-DiD
cs_out <- tryCatch(readRDS(file.path(data_dir, "cs_results.rds")), error = function(e) NULL)
cs_att <- if (!is.null(cs_out)) aggte(cs_out, type = "simple") else NULL

tex2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Empty Homes Premium on Long-Term Vacancy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Log(LTV) & Levels & LTV Share & Per Capita \\\\\n",
  "\\midrule\n"
)

# Extract coefficients
get_coef <- function(m) {
  b <- coef(m)[1]
  se <- sqrt(diag(vcov(m)))[1]
  p <- summary(m)$coeftable[1, 4]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = se, p = p, stars = stars,
       ci_lo = b - 1.96 * se, ci_hi = b + 1.96 * se)
}

c1 <- get_coef(m1); c2 <- get_coef(m2); c3 <- get_coef(m3); c4 <- get_coef(m4)

tex2 <- paste0(tex2,
  sprintf("Premium $\\times$ Post & %.3f%s & %.1f%s & %.3f%s & %.3f%s \\\\\n",
          c1$b, c1$stars, c2$b, c2$stars, c3$b, c3$stars, c4$b, c4$stars),
  sprintf(" & (%.3f) & (%.1f) & (%.3f) & (%.3f) \\\\\n",
          c1$se, c2$se, c3$se, c4$se),
  sprintf(" & [%.3f, %.3f] & [%.1f, %.1f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\\n",
          c1$ci_lo, c1$ci_hi, c2$ci_lo, c2$ci_hi, c3$ci_lo, c3$ci_hi, c4$ci_lo, c4$ci_hi),
  "\\midrule\n",
  sprintf("LA FE & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Clustering & LA & LA & LA & LA \\\\\n"),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(m1$nobs, big.mark = ","), format(m2$nobs, big.mark = ","),
          format(m3$nobs, big.mark = ","), format(m4$nobs, big.mark = ",")),
  sprintf("Treated LAs & 269 & 269 & 269 & 269 \\\\\n"),
  sprintf("Control LAs & 5 & 5 & 5 & 5 \\\\\n"),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1, "ar2")$ar2, fitstat(m2, "ar2")$ar2,
          fitstat(m3, "ar2")$ar2, fitstat(m4, "ar2")$ar2),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Standard errors clustered at the local authority level in parentheses; ",
  "95\\% confidence intervals in brackets. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "All specifications include LA and year fixed effects. ",
  "Treatment is defined as LA adoption of the council tax empty homes premium (first permitted April 2013). ",
  "Column (1): log of long-term vacant dwellings. ",
  "Column (2): count of long-term vacants. ",
  "Column (3): long-term vacants as \\% of all vacants. ",
  "Column (4): long-term vacants per 1,000 population. ",
  "The Callaway--Sant'Anna (2021) overall ATT estimate on log(LTV) is ",
  sprintf("%.3f (SE = %.3f).\n", cs_att$overall.att, cs_att$overall.se),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tex2, file.path(tables_dir, "tab2_main.tex"))
cat("  Wrote tab2_main.tex\n")

## ============================================================
## Table 3: Event Study Coefficients
## ============================================================
cat("\n=== Table 3: Event Study ===\n")

es_coefs <- readRDS(file.path(data_dir, "event_study_coefs.rds"))

tex3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Effect of Premium Adoption on Log(Long-Term Vacants)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Event Time & Estimate & SE & 95\\% CI & $p$-value \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i, ]
  stars <- ifelse(row$pval < 0.01, "***", ifelse(row$pval < 0.05, "**", ifelse(row$pval < 0.1, "*", "")))
  marker <- ifelse(row$event_time == -1, " (ref.)", "")
  tex3 <- paste0(tex3,
    sprintf("$t %s %d$%s & %.3f%s & (%.3f) & [%.3f, %.3f] & %.3f \\\\\n",
            ifelse(row$event_time >= 0, "+", ""), abs(row$event_time), marker,
            row$estimate, stars, row$se, row$ci_lower, row$ci_upper, row$pval)
  )
}

tex3 <- paste0(tex3,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Sun--Abraham (2021) interaction-weighted event study estimates. ",
  "Dependent variable is log(long-term vacant dwellings). ",
  "Reference period is $t-1$ (October 2012). Treatment begins at $t+0$ (October 2013). ",
  "Standard errors clustered at the LA level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "N = ", format(6004, big.mark = ","), " LA-year observations; 269 treated, 5 never-treated LAs.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)

writeLines(tex3, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("  Wrote tab3_eventstudy.tex\n")

## ============================================================
## Table 4: Robustness
## ============================================================
cat("\n=== Table 4: Robustness ===\n")

rob <- readRDS(file.path(data_dir, "robustness_models.rds"))

tex4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\emph{Panel A: Outcome variations}} \\\\\n"
)

# Main result (baseline)
c_main <- get_coef(m1)
tex4 <- paste0(tex4,
  sprintf("Baseline: Log(LTV) & %.3f & (%.3f) & %s \\\\\n",
          c_main$b, c_main$se, format(m1$nobs, big.mark = ",")))

# Placebo
c_plac <- get_coef(rob$placebo)
tex4 <- paste0(tex4,
  sprintf("Placebo: Log(all vacants) & %.3f & (%.3f) & %s \\\\\n",
          c_plac$b, c_plac$se, format(rob$placebo$nobs, big.mark = ",")))

tex4 <- paste0(tex4,
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\emph{Panel B: Sample variations}} \\\\\n"
)

# No London
c_nol <- get_coef(rob$no_london)
tex4 <- paste0(tex4,
  sprintf("Excluding London & %.3f & (%.3f) & %s \\\\\n",
          c_nol$b, c_nol$se, format(rob$no_london$nobs, big.mark = ",")))

# Short window
c_short <- get_coef(rob$short_window)
tex4 <- paste0(tex4,
  sprintf("Short window (2010--2016) & %.3f & (%.3f) & %s \\\\\n",
          c_short$b, c_short$se, format(rob$short_window$nobs, big.mark = ",")))

tex4 <- paste0(tex4,
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\emph{Panel C: Inference variations}} \\\\\n"
)

# Region clustering
c_reg <- get_coef(rob$region_cluster)
tex4 <- paste0(tex4,
  sprintf("Region-clustered SEs & %.3f & (%.3f) & %s \\\\\n",
          c_reg$b, c_reg$se, format(rob$region_cluster$nobs, big.mark = ",")))

tex4 <- paste0(tex4,
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\emph{Panel D: Falsification}} \\\\\n"
)

# Fake treatment
c_fake <- get_coef(rob$fake_2009)
tex4 <- paste0(tex4,
  sprintf("Placebo treatment date (2009) & %.3f & (%.3f) & %s \\\\\n",
          c_fake$b, c_fake$se, format(rob$fake_2009$nobs, big.mark = ",")))

tex4 <- paste0(tex4,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} All specifications include LA and year fixed effects. ",
  "Standard errors clustered at the LA level unless otherwise noted. ",
  "Baseline uses log(long-term vacants) as outcome with 269 treated and 5 never-treated LAs, 2004--2025. ",
  "The placebo outcome (all vacants) should not respond directly to the premium. ",
  "The placebo treatment date (2009) tests for pre-existing differential trends.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)

writeLines(tex4, file.path(tables_dir, "tab4_robustness.tex"))
cat("  Wrote tab4_robustness.tex\n")

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================
cat("\n=== SDE Table ===\n")

# Extract main results for SDE computation
sd_ltv <- sd(panel$long_term_vacant, na.rm = TRUE)
sd_log_ltv <- sd(panel$log_ltv, na.rm = TRUE)
sd_share <- sd(panel$ltv_share, na.rm = TRUE)
sd_pc <- sd(panel$ltv_per_1000, na.rm = TRUE)

sde_rows <- tibble(
  outcome = c("Log(long-term vacants)", "Long-term vacants (levels)",
              "LTV share (\\%)", "LTV per 1,000 pop."),
  beta = c(c1$b, c2$b, c3$b, c4$b),
  se = c(c1$se, c2$se, c3$se, c4$se),
  sd_y = c(sd_log_ltv, sd_ltv, sd_share, sd_pc),
  sde = c(c1$b, c2$b, c3$b, c4$b) / c(sd_log_ltv, sd_ltv, sd_share, sd_pc),
  se_sde = c(c1$se, c2$se, c3$se, c4$se) / c(sd_log_ltv, sd_ltv, sd_share, sd_pc)
) %>%
  mutate(
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

texF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  texF1 <- paste0(texF1,
    sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
  )
}

texF1 <- paste0(texF1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For this binary (0/1) treatment, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and no SD($X$) column is needed. ",
  "SD($Y$) is the unconditional standard deviation from the full sample. ",
  "\\textbf{Research question:} Does the council tax empty homes premium reduce long-term housing vacancy in English local authorities? ",
  "\\textbf{Treatment:} Binary; LA adopted the premium (first permitted April 2013) vs.\\ never adopted. ",
  "\\textbf{Data:} MHCLG Live Table 615, 2004--2025, LA-year panel. ",
  "\\textbf{Method:} TWFE DiD with LA and year fixed effects, LA-clustered standard errors. ",
  "\\textbf{Sample:} 274 English LAs (269 treated, 5 never-treated), 6,004--6,026 LA-year observations. ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(texF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Wrote tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
