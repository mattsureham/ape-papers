# 06_dose_table.R — Generate dedicated dose-response table
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

source("00_packages.R")

panel <- readRDS("../data/analysis_wide.rds")

# ==============================================================================
# Dose-response TWFE: Effects by limit stringency
# ==============================================================================

panel_dose <- panel %>%
  mutate(
    dose_group = case_when(
      first_treat == 0 ~ "Never treated",
      max_days <= 3 ~ "3-day",
      max_days <= 5 ~ "5-day",
      max_days <= 7 ~ "7-day",
      TRUE ~ "Other"
    ),
    post_treat = as.integer(year >= first_treat & first_treat > 0)
  )

# Count states per dose group
dose_counts <- panel_dose %>%
  distinct(state_fips, dose_group) %>%
  count(dose_group)
cat("States per dose group:\n")
print(dose_counts)

outcomes <- c("death_rate_rx_opioid", "death_rate_synthetic",
              "death_rate_heroin", "death_rate_cocaine",
              "death_rate_psychostimulant")
labels <- c("Rx Opioid", "Synthetic/Fentanyl", "Heroin", "Cocaine", "Psychostimulant")

# Run dose-response for each outcome
dose_results <- list()
for (i in seq_along(outcomes)) {
  outcome <- outcomes[i]
  label <- labels[i]
  if (!outcome %in% names(panel_dose)) next

  df <- panel_dose %>% filter(!is.na(.data[[outcome]]))

  fit <- feols(
    as.formula(paste0(outcome, " ~ i(dose_group, post_treat, ref = 'Never treated') | state_id + year")),
    data = df,
    cluster = ~state_id
  )

  dose_results[[label]] <- fit
}

# ==============================================================================
# Build LaTeX table
# ==============================================================================
dose_groups_ordered <- c("3-day", "5-day", "7-day")

# Header
tab_rows <- ""
for (dg in dose_groups_ordered) {
  row <- paste0(dg, " limit")

  for (label in labels) {
    fit <- dose_results[[label]]
    if (is.null(fit)) {
      row <- paste0(row, " & & ")
      next
    }

    coef_name <- paste0("dose_group::", dg, ":post_treat")
    if (coef_name %in% names(coef(fit))) {
      beta <- coef(fit)[coef_name]
      se_val <- se(fit)[coef_name]
      pval <- pvalue(fit)[coef_name]
      stars <- ifelse(pval < 0.01, "***",
               ifelse(pval < 0.05, "**",
               ifelse(pval < 0.10, "*", "")))
      row <- paste0(row, sprintf(" & %.2f%s", beta, stars))
    } else {
      row <- paste0(row, " & ")
    }
  }
  tab_rows <- paste0(tab_rows, row, " \\\\\n")

  # SE row
  se_row <- ""
  for (label in labels) {
    fit <- dose_results[[label]]
    coef_name <- paste0("dose_group::", dg, ":post_treat")
    if (!is.null(fit) && coef_name %in% names(coef(fit))) {
      se_val <- se(fit)[coef_name]
      se_row <- paste0(se_row, sprintf(" & (%.2f)", se_val))
    } else {
      se_row <- paste0(se_row, " & ")
    }
  }
  tab_rows <- paste0(tab_rows, se_row, " \\\\[3pt]\n")
}

# Get N from the total outcome
n_states <- n_distinct(panel_dose$state_fips)

tab5_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Dose-Response: Effect of Limit Stringency on Drug-Specific Overdose Death Rates}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l", paste(rep("c", length(labels)), collapse=""), "}
\\toprule
& \\multicolumn{1}{c}{Rx Opioid} & \\multicolumn{1}{c}{Synthetic} & \\multicolumn{1}{c}{Heroin} & \\multicolumn{1}{c}{Cocaine} & \\multicolumn{1}{c}{Psychostim.} \\\\
& \\multicolumn{1}{c}{(T40.2)} & \\multicolumn{1}{c}{(T40.4)} & \\multicolumn{1}{c}{(T40.1)} & \\multicolumn{1}{c}{(T40.5)} & \\multicolumn{1}{c}{(T43.6)} \\\\
\\midrule
", tab_rows,
"\\midrule
State FE & \\multicolumn{5}{c}{Yes} \\\\
Year FE & \\multicolumn{5}{c}{Yes} \\\\
States & \\multicolumn{5}{c}{", n_states, "} \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each column reports TWFE estimates with state and year fixed effects, where treatment is interacted with dose-group indicators (3-day, 5-day, 7-day limit). Omitted category: never-treated states. 3-day states: FL, TN, KY. 5-day states: NJ, NC, AZ, WI, GA. 7-day states: 30 states. Standard errors clustered at the state level in parentheses. Death rates are per 100,000 population. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:dose_response}
\\end{table}")

writeLines(tab5_tex, "../tables/tab5_dose_response.tex")
cat("\n-> tables/tab5_dose_response.tex\n")
