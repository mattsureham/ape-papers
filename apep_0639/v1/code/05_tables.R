# 05_tables.R — Generate all tables for paper
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

source("00_packages.R")

panel <- readRDS("../data/analysis_wide.rds")
results_table <- readRDS("../data/results_table.rds")
agg_results <- readRDS("../data/agg_results.rds")
twfe_results <- readRDS("../data/twfe_results.rds")
summ_stats <- readRDS("../data/summary_stats.rds")
es_results <- readRDS("../data/es_results.rds")

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Generating Table 1: Summary Statistics\n")

# Compute summary stats from the panel
vars_to_summarize <- c(
  "death_rate_rx_opioid", "death_rate_heroin", "death_rate_synthetic",
  "death_rate_cocaine", "death_rate_psychostimulant", "death_rate_total"
)

var_labels <- c(
  "Rx opioid deaths per 100K",
  "Heroin deaths per 100K",
  "Synthetic opioid deaths per 100K",
  "Cocaine deaths per 100K",
  "Psychostimulant deaths per 100K",
  "Total overdose deaths per 100K"
)

tab1_rows <- list()
for (i in seq_along(vars_to_summarize)) {
  v <- vars_to_summarize[i]
  if (!v %in% names(panel)) next
  vals <- panel[[v]][!is.na(panel[[v]])]
  tab1_rows[[i]] <- sprintf(
    "%s & %.2f & %.2f & %.2f & %.2f \\\\",
    var_labels[i],
    mean(vals), sd(vals), min(vals), max(vals)
  )
}

# Treatment stats
n_states <- n_distinct(panel$state_fips)
n_treated <- sum(panel$first_treat > 0 & !duplicated(panel$state_fips))
n_control <- n_states - n_treated
n_obs <- nrow(panel)
year_range <- paste(min(panel$year), "--", max(panel$year))

tab1_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: State-Level Drug Overdose Death Rates}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & Std.\\ Dev. & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Overdose death rates (per 100,000 population)}} \\\\[3pt]
", paste(unlist(tab1_rows), collapse = "\n"), "
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Treatment characteristics}} \\\\[3pt]
Treated states & \\multicolumn{4}{c}{", n_treated, "} \\\\
Never-treated states & \\multicolumn{4}{c}{", n_control, "} \\\\
State-year observations & \\multicolumn{4}{c}{", format(n_obs, big.mark=","), "} \\\\
Year range & \\multicolumn{4}{c}{", year_range, "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Death rates are annual deaths per 100,000 state population from CDC NCHS Provisional Drug Overdose Death Counts (resource xkb8-kh2a). Drug categories follow ICD-10 underlying cause codes: T40.2 (natural/semi-synthetic opioids, capturing prescription opioids), T40.1 (heroin), T40.4 (synthetic opioids excluding methadone, primarily fentanyl), T40.5 (cocaine), T43.6 (psychostimulants with abuse potential). Treatment is defined as state adoption of a day-supply limit on initial opioid prescriptions. ", n_treated, " states adopted limits between 2016 and 2019; ", n_control, " states had no limit by end of sample.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  -> tables/tab1_summary.tex\n")

# ==============================================================================
# Table 2: Main Results — Drug-Type Decomposition (CS ATT)
# ==============================================================================
cat("Generating Table 2: Main Results\n")

# Build rows from results_table
tab2_rows <- ""
for (i in 1:nrow(results_table)) {
  r <- results_table[i, ]
  stars <- ifelse(r$pvalue < 0.01, "***",
           ifelse(r$pvalue < 0.05, "**",
           ifelse(r$pvalue < 0.10, "*", "")))

  tab2_rows <- paste0(tab2_rows, sprintf(
    "%s & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
    r$outcome, r$att, stars, r$se, r$ci_lower, r$ci_upper
  ))
}

tab2_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Day-Supply Limits on Drug-Type-Specific Overdose Death Rates}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Drug Category & CS ATT & SE & 95\\% CI \\\\
\\midrule
", tab2_rows, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row reports the Callaway and Sant'Anna (2021) overall ATT for the effect of state day-supply limit laws on drug-type-specific overdose death rates (per 100,000 population). Treatment groups defined by year of law adoption (2016--2019). Control group: never-treated states. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. N = ", format(n_obs, big.mark=","), " state-year observations across ", n_states, " states.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  -> tables/tab2_main.tex\n")

# ==============================================================================
# Table 3: TWFE comparison and robustness summary
# ==============================================================================
cat("Generating Table 3: TWFE vs CS Comparison\n")

tab3_rows <- ""
for (label in names(twfe_results)) {
  fit <- twfe_results[[label]]
  beta_twfe <- coef(fit)["post_treat"]
  se_twfe <- se(fit)["post_treat"]
  pval_twfe <- pvalue(fit)["post_treat"]

  # Get CS result
  cs_row <- results_table %>% filter(outcome == label)

  stars_twfe <- ifelse(pval_twfe < 0.01, "***",
                ifelse(pval_twfe < 0.05, "**",
                ifelse(pval_twfe < 0.10, "*", "")))

  if (nrow(cs_row) > 0) {
    stars_cs <- ifelse(cs_row$pvalue < 0.01, "***",
               ifelse(cs_row$pvalue < 0.05, "**",
               ifelse(cs_row$pvalue < 0.10, "*", "")))

    tab3_rows <- paste0(tab3_rows, sprintf(
      "%s & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\\n",
      label,
      beta_twfe, stars_twfe, se_twfe,
      cs_row$att, stars_cs, cs_row$se
    ))
  }
}

tab3_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{TWFE vs.\\ Callaway--Sant'Anna Estimates}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{TWFE} & \\multicolumn{2}{c}{Callaway--Sant'Anna} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Drug Category & Estimate & SE & ATT & SE \\\\
\\midrule
", tab3_rows, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} TWFE estimates from two-way fixed effects regression with state and year fixed effects. CS estimates from Callaway and Sant'Anna (2021) using never-treated states as controls. Both cluster standard errors at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:twfe_vs_cs}
\\end{table}")

writeLines(tab3_tex, "../tables/tab3_comparison.tex")
cat("  -> tables/tab3_comparison.tex\n")

# ==============================================================================
# Table 4: Event Study Coefficients (pre-trend test)
# ==============================================================================
cat("Generating Table 4: Event Study Coefficients\n")

# Extract event study coefficients for key outcomes
key_outcomes <- c("Rx Opioid (T40.2)", "Synthetic/Fentanyl (T40.4)", "Total Overdose")

tab4_parts <- list()

for (label in key_outcomes) {
  if (!label %in% names(es_results)) next

  es <- es_results[[label]]

  es_df <- tibble(
    event_time = as.numeric(es$egt),
    att = as.numeric(es$att.egt),
    se = as.numeric(es$se.egt)
  ) %>%
    filter(!is.na(att), !is.na(se), se > 0) %>%
    mutate(
      pval = 2 * pnorm(-abs(att / se)),
      stars = ifelse(pval < 0.01, "***",
              ifelse(pval < 0.05, "**",
              ifelse(pval < 0.10, "*", "")))
    )

  tab4_parts[[label]] <- es_df
}

# Build combined event study table
if (length(tab4_parts) > 0) {
  # Get all event times
  all_times <- sort(unique(unlist(lapply(tab4_parts, function(x) x$event_time))))

  tab4_header <- "\\begin{table}[H]
\\centering
\\caption{Event Study Coefficients by Drug Type}
\\begin{threeparttable}
\\begin{tabular}{l"
  for (l in key_outcomes) tab4_header <- paste0(tab4_header, "cc")
  tab4_header <- paste0(tab4_header, "}
\\toprule
")

  # Column headers
  col_headers <- "Event Time"
  for (l in key_outcomes) {
    short_label <- gsub(" \\(.*\\)", "", l)
    col_headers <- paste0(col_headers, " & \\multicolumn{2}{c}{", short_label, "}")
  }
  col_headers <- paste0(col_headers, " \\\\\n")

  # Cmidrule
  cmi <- ""
  col_idx <- 2
  for (l in key_outcomes) {
    cmi <- paste0(cmi, "\\cmidrule(lr){", col_idx, "-", col_idx+1, "}")
    col_idx <- col_idx + 2
  }
  cmi <- paste0(cmi, "\n")

  sub_headers <- ""
  for (l in key_outcomes) {
    sub_headers <- paste0(sub_headers, " & ATT & SE")
  }
  sub_headers <- paste0(sub_headers, " \\\\\n\\midrule\n")

  # Rows
  tab4_body <- ""
  for (t in all_times) {
    row <- paste0("$k = ", t, "$")
    for (l in key_outcomes) {
      if (l %in% names(tab4_parts)) {
        es_row <- tab4_parts[[l]] %>% filter(event_time == t)
        if (nrow(es_row) == 1) {
          row <- paste0(row, sprintf(" & %.3f%s & (%.3f)", es_row$att, es_row$stars, es_row$se))
        } else {
          row <- paste0(row, " & & ")
        }
      } else {
        row <- paste0(row, " & & ")
      }
    }
    tab4_body <- paste0(tab4_body, row, " \\\\\n")
  }

  tab4_tex <- paste0(tab4_header, col_headers, cmi, sub_headers, tab4_body,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Event study coefficients from Callaway and Sant'Anna (2021) dynamic aggregation. Event time $k$ measures years relative to law adoption. Pre-treatment coefficients ($k < 0$) test the parallel trends assumption. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:event_study}
\\end{table}")

  writeLines(tab4_tex, "../tables/tab4_event_study.tex")
  cat("  -> tables/tab4_event_study.tex\n")
}

# ==============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ==============================================================================
cat("Generating SDE Table\n")

# Compute SDE for each main outcome
sde_rows <- list()

for (i in 1:nrow(results_table)) {
  r <- results_table[i, ]
  outcome_var <- c(
    "Rx Opioid (T40.2)" = "death_rate_rx_opioid",
    "Heroin (T40.1)" = "death_rate_heroin",
    "Synthetic/Fentanyl (T40.4)" = "death_rate_synthetic",
    "Cocaine (T40.5)" = "death_rate_cocaine",
    "Psychostimulant (T43.6)" = "death_rate_psychostimulant",
    "Total Overdose" = "death_rate_total"
  )[r$outcome]

  if (is.na(outcome_var) || !outcome_var %in% names(panel)) next

  sd_y <- sd(panel[[outcome_var]], na.rm = TRUE)
  if (is.na(sd_y) || sd_y == 0) next

  sde <- r$att / sd_y
  se_sde <- r$se / sd_y

  classification <- dplyr::case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )

  sde_rows[[length(sde_rows) + 1]] <- sprintf(
    "%s & %.3f & (%.3f) & %.2f & %.4f & (%.4f) & %s \\\\",
    r$outcome, r$att, r$se, sd_y, sde, se_sde, classification
  )
}

sde_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
", paste(unlist(sde_rows), collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE $= \\hat{\\beta} / \\text{SD}(Y)$) for each main drug-type outcome.
Treatment is binary (state adopted day-supply limit law).
SD($Y$) is the unconditional standard deviation of the outcome variable across the full state-year panel.

\\textbf{Research question:} Do state opioid prescribing day-supply limits reduce prescription opioid overdose deaths but increase illicit opioid (heroin, fentanyl) overdose deaths through substitution?
\\textbf{Treatment:} Binary indicator for state adoption of a day-supply limit law (3--7 day caps on initial opioid prescriptions).
\\textbf{Data:} CDC NCHS Provisional Drug Overdose Death Counts, 50 states + DC, ", min(panel$year), "--", max(panel$year), ", N = ", format(nrow(panel), big.mark=","), " state-year observations.
\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, state-clustered standard errors.
\\textbf{Sample:} All US states with non-missing overdose death data, annual frequency.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),
small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),
small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),
large positive ($> 0.15$).
Classification labels refer to the magnitude of the standardized point estimate,
not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$),
not a failure to reject a null hypothesis.}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("  -> tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
