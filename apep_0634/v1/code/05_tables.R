# =============================================================================
# 05_tables.R — Generate all tables
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
main_models <- readRDS("../data/main_models.rds")
rob_models <- readRDS("../data/robustness_models.rds")

# ─── Table 1: Summary Statistics ─────────────────────────────────────────────
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-MINER Act period (2000-2006Q2)
pre <- panel |> filter(post_miner == 0)

# Classify counties
pre <- pre |>
  mutate(group = case_when(
    mining_share > 0.05 ~ "High Mining ($>$5\\%)",
    mining_share > 0 & mining_share <= 0.05 ~ "Low Mining (0--5\\%)",
    TRUE ~ "No Mining (0\\%)"
  ))

# Summary by group
sum_stats <- pre |>
  group_by(group) |>
  summarize(
    Counties = n_distinct(county_id),
    `Emp (mean)` = sprintf("%.0f", mean(emp_total, na.rm = TRUE)),
    `Emp (sd)` = sprintf("%.0f", sd(emp_total, na.rm = TRUE)),
    `Earnings (mean)` = sprintf("%.0f", mean(earn_total, na.rm = TRUE)),
    `Mining Share (mean)` = sprintf("%.3f", mean(mining_share, na.rm = TRUE)),
    `Mining Share (sd)` = sprintf("%.3f", sd(mining_share, na.rm = TRUE)),
    `Mining Emp (mean)` = sprintf("%.0f", mean(emp_mining, na.rm = TRUE)),
    .groups = "drop"
  )

# LaTeX output
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-MINER Act Period (2000Q1--2006Q2)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & High Mining ($>$5\\%) & Low Mining (0--5\\%) & No Mining (0\\%) \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "Counties & %s & %s & %s \\\\",
    row$Counties[row$group == "High Mining ($>$5\\%)"],
    row$Counties[row$group == "Low Mining (0--5\\%)"],
    row$Counties[row$group == "No Mining (0\\%)"]
  ))
}

# Build table more carefully
high <- sum_stats |> filter(grepl("High", group))
low <- sum_stats |> filter(grepl("Low", group))
none <- sum_stats |> filter(grepl("No", group))

tab1_body <- c(
  sprintf("Counties & %s & %s & %s \\\\", high$Counties, low$Counties, none$Counties),
  sprintf("Total employment (mean) & %s & %s & %s \\\\",
          high$`Emp (mean)`, low$`Emp (mean)`, none$`Emp (mean)`),
  sprintf("Total employment (sd) & (%s) & (%s) & (%s) \\\\",
          high$`Emp (sd)`, low$`Emp (sd)`, none$`Emp (sd)`),
  sprintf("Quarterly earnings (\\$) & %s & %s & %s \\\\",
          high$`Earnings (mean)`, low$`Earnings (mean)`, none$`Earnings (mean)`),
  sprintf("Mining share (mean) & %s & %s & %s \\\\",
          high$`Mining Share (mean)`, low$`Mining Share (mean)`, none$`Mining Share (mean)`),
  sprintf("Mining employment (mean) & %s & %s & %s \\\\",
          high$`Mining Emp (mean)`, low$`Mining Emp (mean)`, none$`Mining Emp (mean)`)
)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-MINER Act Period (2000Q1--2006Q2)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & High Mining & Low Mining & No Mining \\\\",
  " & ($>$5\\%) & (0--5\\%) & (0\\%) \\\\",
  "\\midrule",
  tab1_body,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} County-quarter observations from the pre-MINER Act period (2000Q1--2006Q2) across 24 coal-producing states. Mining share is the 2005 annual average ratio of NAICS 212 (mining, except oil and gas) employment to total employment. Standard deviations in parentheses. Source: Census Quarterly Workforce Indicators.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ─── Table 2: Main DiD Results (Two-Event) ──────────────────────────────────
cat("=== Generating Table 2: Main Results ===\n")

tab2_models <- list(
  main_models$m2_emp, main_models$m2_earn, main_models$m2_mining,
  main_models$m1_nonmining
)

# Build table using fixest
setFixest_dict(c(
  treat_post = "Mining Share $\\times$ Post MINER",
  treat_post_ubb = "Mining Share $\\times$ Post UBB",
  log_emp = "Log Employment",
  log_earn = "Log Earnings",
  log_emp_mining = "Log Mining Emp",
  log_emp_nonmining = "Log Non-Mining Emp"
))

tab2_tex <- etable(
  main_models$m2_emp, main_models$m2_earn, main_models$m2_mining,
  main_models$m1_nonmining,
  headers = c("(1)", "(2)", "(3)", "(4)"),
  tex = TRUE,
  style.tex = style.tex(
    main = "aer",
    tablefoot = FALSE
  ),
  fitstat = c("n", "r2", "wr2"),
  notes = paste(
    "\\\\textit{Notes:} Each column reports a separate regression of the indicated",
    "outcome on mining share interacted with post-MINER Act (2006Q3+) and",
    "post-Upper Big Branch (2010Q2+) indicators. All specifications include",
    "county and quarter fixed effects. Standard errors clustered at the state",
    "level in parentheses. Mining share is the 2005 county-level ratio of",
    "NAICS 212 to total employment. Column (3) restricts to counties with",
    "positive mining employment. * $p<0.05$, ** $p<0.01$, *** $p<0.001$."
  ),
  label = "tab:main",
  title = "Effect of Mine Safety Regulation on County Labor Markets"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ─── Table 3: Event Study Coefficients ───────────────────────────────────────
cat("=== Generating Table 3: Event Study ===\n")

es <- main_models$es_emp
es_coefs <- as.data.frame(summary(es)$coeftable)
es_coefs$event_time <- as.numeric(gsub("event_year::(-?\\d+):mining_share", "\\1",
                                        rownames(es_coefs)))

# Format for LaTeX
tab3_rows <- c()
for (i in 1:nrow(es_coefs)) {
  et <- es_coefs$event_time[i]
  est <- es_coefs$Estimate[i]
  se <- es_coefs$`Std. Error`[i]
  pval <- es_coefs$`Pr(>|t|)`[i]
  stars <- ifelse(pval < 0.001, "***",
           ifelse(pval < 0.01, "**",
           ifelse(pval < 0.05, "*",
           ifelse(pval < 0.1, "$^{\\dagger}$", ""))))
  tab3_rows <- c(tab3_rows, sprintf(
    "$t%+d$ & %s%.3f%s & (%.3f) \\\\",
    et, ifelse(est >= 0, "\\phantom{-}", ""), est, stars, se
  ))
}

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Log Employment $\\times$ Mining Share}",
  "\\label{tab:event_study}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Year & Coefficient & Std. Error \\\\",
  "\\midrule",
  tab3_rows[1:4],  # Pre-treatment
  "\\midrule",
  "$t-1$ (reference) & 0.000 & --- \\\\",
  "\\midrule",
  tab3_rows[5:14],  # Post-treatment
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from regressing log total employment on interactions of 2005 mining share with annual event-time indicators, relative to the year before the MINER Act ($t-1$ = 2005). County and quarter fixed effects included. Standard errors clustered at the state level. $^{\\dagger} p<0.10$, * $p<0.05$, ** $p<0.01$. $N = 110{,}712$ county-quarter observations across 1,853 counties.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_event_study.tex")

# ─── Table 4: Regional Heterogeneity ────────────────────────────────────────
cat("=== Generating Table 4: Regional Heterogeneity ===\n")

tab4_tex <- etable(
  rob_models$app_emp, rob_models$west_emp, rob_models$no_wv_emp,
  headers = c("Appalachian", "Western", "Excl. WV"),
  tex = TRUE,
  style.tex = style.tex(main = "aer", tablefoot = FALSE),
  fitstat = c("n", "r2"),
  notes = paste(
    "\\\\textit{Notes:} Appalachian states: AL, KY, MD, OH, PA, TN, VA, WV.",
    "Western states: CO, MT, ND, NM, TX, UT, WY.",
    "All specifications include county and quarter fixed effects with",
    "standard errors clustered at the state level.",
    "* $p<0.05$, ** $p<0.01$, *** $p<0.001$."
  ),
  label = "tab:regional",
  title = "Regional Heterogeneity: Appalachian vs.\\ Western Coal States"
)

writeLines(tab4_tex, "../tables/tab4_regional.tex")

# ─── Table 5: Robustness ────────────────────────────────────────────────────
cat("=== Generating Table 5: Robustness ===\n")

tab5_tex <- etable(
  main_models$m2_emp, rob_models$b_emp, rob_models$alt_emp,
  rob_models$placebo_emp,
  headers = c("Baseline", "Binary Treat.", "2003 Share", "Non-Mining Placebo"),
  tex = TRUE,
  style.tex = style.tex(main = "aer", tablefoot = FALSE),
  fitstat = c("n", "r2"),
  notes = paste(
    "\\\\textit{Notes:} Column (1) reproduces the baseline specification.",
    "Column (2) uses a binary treatment indicator (above-median mining share).",
    "Column (3) measures mining share in 2003 instead of 2005.",
    "Column (4) uses log non-mining employment as a placebo outcome.",
    "All specifications include county and quarter fixed effects.",
    "Standard errors clustered at the state level.",
    "* $p<0.05$, ** $p<0.01$, *** $p<0.001$."
  ),
  label = "tab:robustness",
  title = "Robustness Checks"
)

writeLines(tab5_tex, "../tables/tab5_robustness.tex")

# ─── SDE Table (Appendix) ───────────────────────────────────────────────────
cat("=== Generating SDE Table ===\n")

# Compute standardized effect sizes
panel_pre <- panel |> filter(post_miner == 0)
sd_emp <- sd(panel_pre$log_emp, na.rm = TRUE)
sd_earn <- sd(panel_pre$log_earn, na.rm = TRUE)
sd_mining <- sd(panel_pre$log_emp_mining[panel_pre$mining_share > 0], na.rm = TRUE)
sd_nonmining <- sd(panel_pre$log_emp_nonmining, na.rm = TRUE)
sd_treat <- sd(panel$mining_share, na.rm = TRUE)

# Main results are from the two-event specification (post-UBB)
# For continuous treatment: SDE = beta * SD(X) / SD(Y)
beta_emp <- coef(main_models$m2_emp)["treat_post_ubb"]
se_emp <- summary(main_models$m2_emp)$coeftable["treat_post_ubb", "Std. Error"]
sde_emp <- beta_emp * sd_treat / sd_emp
sde_se_emp <- se_emp * sd_treat / sd_emp

beta_earn <- coef(main_models$m2_earn)["treat_post_ubb"]
se_earn <- summary(main_models$m2_earn)$coeftable["treat_post_ubb", "Std. Error"]
sde_earn <- beta_earn * sd_treat / sd_earn
sde_se_earn <- se_earn * sd_treat / sd_earn

beta_mining <- coef(main_models$m2_mining)["treat_post_ubb"]
se_mining <- summary(main_models$m2_mining)$coeftable["treat_post_ubb", "Std. Error"]
sd_mining_treat <- sd(panel$mining_share[panel$mining_share > 0], na.rm = TRUE)
sde_mining <- beta_mining * sd_mining_treat / sd_mining
sde_se_mining <- se_mining * sd_mining_treat / sd_mining

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- data.frame(
  Outcome = c("Log total employment", "Log quarterly earnings",
              "Log mining employment"),
  Beta = c(beta_emp, beta_earn, beta_mining),
  SE = c(se_emp, se_earn, se_mining),
  SD_Y = c(sd_emp, sd_earn, sd_mining),
  SDE = c(sde_emp, sde_earn, sde_mining),
  SDE_SE = c(sde_se_emp, sde_se_earn, sde_se_mining),
  Classification = c(classify_sde(sde_emp), classify_sde(sde_earn),
                     classify_sde(sde_mining))
)

cat("SDE values:\n")
print(sde_rows)

# LaTeX
sde_tex_rows <- c()
for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  sde_tex_rows <- c(sde_tex_rows, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SDE_SE, r$Classification
  ))
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Post-UBB Enforcement Period}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sde_tex_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} This table reports standardized effect sizes for the post-Upper Big Branch (2010Q2+) mining share interaction from the two-event difference-in-differences specification. The research question asks whether disaster-driven mine safety regulation causally reduced employment and earnings in mining-intensive counties. Data are quarterly county-level observations from the Census Quarterly Workforce Indicators (QWI), 2000Q1--2016Q4, across 24 coal-producing U.S.\\ states ($N = 124{,}380$). Treatment is the 2005 county-level ratio of NAICS 212 employment to total employment, interacted with a post-2010Q2 indicator. SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
ls("../tables/")
