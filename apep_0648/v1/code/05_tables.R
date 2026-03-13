## 05_tables.R — Generate all LaTeX tables
## APEP-0636: Constitutional Carry and Firearm Violence

source("00_packages.R")

panel <- read_csv("data/analysis_panel_clean.csv", show_col_types = FALSE)
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")

did_panel <- panel |> filter(cc_wave != "Pre-2019")

dir.create("tables", showWarnings = FALSE)

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================

cat("Generating Table 1: Summary Statistics\n")

# Compute summary statistics by treatment status
summ_all <- did_panel |>
  summarise(
    across(c(fa_homicide_rate, fa_suicide_rate, nfa_homicide_rate,
             nfa_suicide_rate, total_fa_rate, population),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

# By treatment group (pre-period only for treated states)
summ_treated <- did_panel |>
  filter(gname > 0, year < gname) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))))

summ_control <- did_panel |>
  filter(gname == 0) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))))

n_tot <- nrow(did_panel)
n_states_t <- n_distinct(did_panel$state_fips[did_panel$gname > 0])
n_states_c <- n_distinct(did_panel$state_fips[did_panel$gname == 0])

tab1_tex <- sprintf(
  "\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{CC States (Pre-Treatment)} & \\multicolumn{2}{c}{Never-CC States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
Firearm homicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Firearm suicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Total firearm death rate & %.2f & %.2f & %.2f & %.2f \\\\
Population (millions) & %.2f & %.2f & %.2f & %.2f \\\\
\\midrule
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
State-year observations & \\multicolumn{4}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Rates per 100,000 population. CC states: states adopting constitutional carry 2019--2024; pre-treatment means use only years before each state's adoption. Never-CC states: states without constitutional carry as of 2024. Data: CDC Mapping Injury (2019--2024), Census population estimates.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  summ_treated$fa_homicide_rate_mean, summ_treated$fa_homicide_rate_sd,
  summ_control$fa_homicide_rate_mean, summ_control$fa_homicide_rate_sd,
  summ_treated$fa_suicide_rate_mean, summ_treated$fa_suicide_rate_sd,
  summ_control$fa_suicide_rate_mean, summ_control$fa_suicide_rate_sd,
  summ_treated$total_fa_rate_mean, summ_treated$total_fa_rate_sd,
  summ_control$total_fa_rate_mean, summ_control$total_fa_rate_sd,
  summ_treated$population_mean / 1e6, summ_treated$population_sd / 1e6,
  summ_control$population_mean / 1e6, summ_control$population_sd / 1e6,
  n_states_t, n_states_c,
  format(n_tot, big.mark = ",")
)

writeLines(tab1_tex, "tables/tab1_summary.tex")

# ============================================================
# TABLE 2: MAIN RESULTS
# ============================================================

cat("Generating Table 2: Main Results\n")

# Extract results
cs_hom <- results$agg_hom_simple
cs_sui <- results$agg_sui_simple
cs_total <- results$agg_total_simple
twfe_hom <- results$twfe_hom
twfe_sui <- results$twfe_sui
twfe_total <- results$twfe_total

# P-values and stars
pval <- function(est, se) 2 * pnorm(-abs(est / se))
stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# CS-DiD estimates
cs_hom_p <- pval(cs_hom$overall.att, cs_hom$overall.se)
cs_sui_p <- pval(cs_sui$overall.att, cs_sui$overall.se)
cs_total_p <- pval(cs_total$overall.att, cs_total$overall.se)

# TWFE estimates
twfe_hom_p <- pvalue(twfe_hom)["treated"]
twfe_sui_p <- pvalue(twfe_sui)["treated"]
twfe_total_p <- pvalue(twfe_total)["treated"]

# Control means
ctrl_mean_hom <- mean(did_panel$fa_homicide_rate[did_panel$gname == 0], na.rm = TRUE)
ctrl_mean_sui <- mean(did_panel$fa_suicide_rate[did_panel$gname == 0], na.rm = TRUE)
ctrl_mean_tot <- mean(did_panel$total_fa_rate[did_panel$gname == 0], na.rm = TRUE)

tab2_tex <- sprintf(
  "\\begin{table}[H]
\\centering
\\caption{Effect of Constitutional Carry Laws on Firearm Mortality}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& \\multicolumn{3}{c}{Outcome (rate per 100,000)} \\\\
\\cmidrule(lr){2-4}
& FA Homicide & FA Suicide & Total FA Deaths \\\\
& (1) & (2) & (3) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\[3pt]
ATT & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\[3pt]
Treated & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
\\midrule
Control group mean & %.2f & %.2f & %.2f \\\\
\\%% of control mean & %.1f\\%% & %.1f\\%% & %.1f\\%% \\\\
Treated states & %d & %d & %d \\\\
Control states & %d & %d & %d \\\\
State-year obs. & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the overall average treatment effect on the treated (ATT) from the \\citet{callaway2021} estimator with never-treated states as controls. Panel B reports two-way fixed effects estimates with state and year fixed effects. Standard errors clustered at the state level in parentheses. Rates are deaths per 100,000 population. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
  # Panel A: CS-DiD
  cs_hom$overall.att, stars(cs_hom_p),
  cs_sui$overall.att, stars(cs_sui_p),
  cs_total$overall.att, stars(cs_total_p),
  cs_hom$overall.se, cs_sui$overall.se, cs_total$overall.se,
  cs_hom$overall.att - 1.96 * cs_hom$overall.se,
  cs_hom$overall.att + 1.96 * cs_hom$overall.se,
  cs_sui$overall.att - 1.96 * cs_sui$overall.se,
  cs_sui$overall.att + 1.96 * cs_sui$overall.se,
  cs_total$overall.att - 1.96 * cs_total$overall.se,
  cs_total$overall.att + 1.96 * cs_total$overall.se,
  # Panel B: TWFE
  coef(twfe_hom)["treated"], stars(twfe_hom_p),
  coef(twfe_sui)["treated"], stars(twfe_sui_p),
  coef(twfe_total)["treated"], stars(twfe_total_p),
  se(twfe_hom)["treated"], se(twfe_sui)["treated"], se(twfe_total)["treated"],
  # Bottom
  ctrl_mean_hom, ctrl_mean_sui, ctrl_mean_tot,
  cs_hom$overall.att / ctrl_mean_hom * 100,
  cs_sui$overall.att / ctrl_mean_sui * 100,
  cs_total$overall.att / ctrl_mean_tot * 100,
  n_states_t, n_states_t, n_states_t,
  n_states_c, n_states_c, n_states_c,
  format(n_tot, big.mark = ","), format(n_tot, big.mark = ","), format(n_tot, big.mark = ",")
)

writeLines(tab2_tex, "tables/tab2_main.tex")

# ============================================================
# TABLE 3: EVENT STUDY COEFFICIENTS
# ============================================================

cat("Generating Table 3: Event Study\n")

es_hom <- results$es_hom
es_sui <- results$es_sui

es_df <- tibble(
  event_time = es_hom$egt,
  att_hom = es_hom$att.egt,
  se_hom = es_hom$se.egt,
  att_sui = es_sui$att.egt,
  se_sui = es_sui$se.egt
) |>
  mutate(
    p_hom = pval(att_hom, se_hom),
    p_sui = pval(att_sui, se_sui),
    star_hom = sapply(p_hom, stars),
    star_sui = sapply(p_sui, stars)
  )

# Build table rows
es_rows <- es_df |>
  mutate(row = sprintf("$k = %+d$ & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
                       event_time,
                       att_hom, star_hom, se_hom,
                       att_sui, star_sui, se_sui)) |>
  pull(row)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "& \\multicolumn{2}{c}{FA Homicide Rate} & \\multicolumn{2}{c}{FA Suicide Rate} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Event Time & ATT & SE & ATT & SE \\\\\n",
  "\\midrule\n",
  paste(es_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study coefficients from the \\citet{callaway2021} estimator aggregated dynamically. $k=0$ is the year of adoption. Negative $k$ values are pre-treatment periods (testing parallel trends). Standard errors clustered at the state level. Never-treated states serve as the control group. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}"
)

writeLines(tab3_tex, "tables/tab3_eventstudy.tex")

# ============================================================
# TABLE 4: ROBUSTNESS
# ============================================================

cat("Generating Table 4: Robustness\n")

# Placebo estimates
nfa_hom <- rob$agg_nfa_hom
nfa_sui <- rob$agg_nfa_sui
nyt_hom <- rob$agg_hom_nyt
nyt_sui <- rob$agg_sui_nyt
loo <- rob$loo_results

nfa_hom_p <- pval(nfa_hom$overall.att, nfa_hom$overall.se)
nfa_sui_p <- pval(nfa_sui$overall.att, nfa_sui$overall.se)
nyt_hom_p <- pval(nyt_hom$overall.att, nyt_hom$overall.se)
nyt_sui_p <- pval(nyt_sui$overall.att, nyt_sui$overall.se)

tab4_tex <- sprintf(
  "\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Specification & ATT & SE & ATT & SE \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Baseline}} \\\\[3pt]
CS-DiD (never-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Alternative Control Group}} \\\\[3pt]
CS-DiD (not-yet-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Placebo Outcomes}} \\\\[3pt]
Non-firearm homicide & %.3f%s & (%.3f) & & \\\\
Non-firearm suicide & & & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel D: Leave-One-State-Out}} \\\\[3pt]
Min ATT & %.3f & & & \\\\
Max ATT & %.3f & & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reproduces the baseline Callaway--Sant'Anna estimate from \\Cref{tab:main}. Panel B uses not-yet-treated states as controls. Panel C tests placebo outcomes that should be unaffected by gun carry laws: non-firearm homicide and non-firearm suicide. Panel D shows the range of the firearm homicide ATT when each treated state is dropped in turn. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}",
  # Panel A
  results$agg_hom_simple$overall.att, stars(pval(results$agg_hom_simple$overall.att, results$agg_hom_simple$overall.se)),
  results$agg_hom_simple$overall.se,
  results$agg_sui_simple$overall.att, stars(pval(results$agg_sui_simple$overall.att, results$agg_sui_simple$overall.se)),
  results$agg_sui_simple$overall.se,
  # Panel B
  nyt_hom$overall.att, stars(nyt_hom_p), nyt_hom$overall.se,
  nyt_sui$overall.att, stars(nyt_sui_p), nyt_sui$overall.se,
  # Panel C
  nfa_hom$overall.att, stars(nfa_hom_p), nfa_hom$overall.se,
  nfa_sui$overall.att, stars(nfa_sui_p), nfa_sui$overall.se,
  # Panel D
  min(loo$att, na.rm = TRUE),
  max(loo$att, na.rm = TRUE)
)

writeLines(tab4_tex, "tables/tab4_robustness.tex")

# ============================================================
# TABLE 5: HETEROGENEITY BY COHORT
# ============================================================

cat("Generating Table 5: Heterogeneity by Cohort\n")

grp_hom <- results$agg_hom_group
grp_sui <- results$agg_sui_group

grp_df <- tibble(
  cohort = grp_hom$egt,
  att_hom = grp_hom$att.egt,
  se_hom = grp_hom$se.egt,
  att_sui = grp_sui$att.egt,
  se_sui = grp_sui$se.egt,
  n_states = sapply(grp_hom$egt, function(g) {
    n_distinct(did_panel$state_fips[did_panel$gname == g])
  })
) |>
  mutate(
    p_hom = pval(att_hom, se_hom),
    p_sui = pval(att_sui, se_sui)
  )

grp_rows <- grp_df |>
  mutate(row = sprintf("%d & %d & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
                       cohort, n_states,
                       att_hom, sapply(p_hom, stars), se_hom,
                       att_sui, sapply(p_sui, stars), se_sui)) |>
  pull(row)

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Treatment Effects by Adoption Cohort}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{cccccc}\n",
  "\\toprule\n",
  "& & \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "Cohort & States & ATT & SE & ATT & SE \\\\\n",
  "\\midrule\n",
  paste(grp_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Group-specific average treatment effects from the \\citet{callaway2021} estimator. Each row shows the ATT for states adopting constitutional carry in the indicated year. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:heterogeneity}\n",
  "\\end{table}"
)

writeLines(tab5_tex, "tables/tab5_heterogeneity.tex")

# ============================================================
# SDE TABLE (MANDATORY APPENDIX)
# ============================================================

cat("Generating SDE Table\n")

# Extract standardized effect sizes
sd_fa_hom <- sd(did_panel$fa_homicide_rate, na.rm = TRUE)
sd_fa_sui <- sd(did_panel$fa_suicide_rate, na.rm = TRUE)
sd_total <- sd(did_panel$total_fa_rate, na.rm = TRUE)

sde_data <- tibble(
  Outcome = c("Firearm homicide rate", "Firearm suicide rate", "Total firearm death rate"),
  beta = c(results$agg_hom_simple$overall.att,
           results$agg_sui_simple$overall.att,
           results$agg_total_simple$overall.att),
  se_beta = c(results$agg_hom_simple$overall.se,
              results$agg_sui_simple$overall.se,
              results$agg_total_simple$overall.se),
  sd_y = c(sd_fa_hom, sd_fa_sui, sd_total)
) |>
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
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

sde_rows <- sde_data |>
  mutate(row = sprintf("%s & %.3f & (%.3f) & %.2f & %.3f & (%.3f) & %s \\\\",
                       Outcome, beta, se_beta, sd_y, sde, se_sde, classification)) |>
  pull(row)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(sde_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison. For binary (0/1) treatments, ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is marked ``---''. ",
  "SD($Y$) is the unconditional standard deviation of the outcome.\n\n",
  "\\textbf{Research question:} Effect of constitutional carry (permitless concealed carry) laws on firearm mortality.\n",
  "\\textbf{Treatment:} Binary --- state adopted constitutional carry law (2019--2024 wave).\n",
  "\\textbf{Data:} CDC Mapping Injury (2019--2024), state-year panel, ", format(nrow(did_panel), big.mark = ","), " observations.\n",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna estimator, state-clustered SEs.\n",
  "\\textbf{Sample:} 50 US states, excluding pre-2019 constitutional carry adopters (13 states).\n\n",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}"
)

writeLines(sde_tex, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(" ", list.files("tables"), collapse = "\n"), "\n")
