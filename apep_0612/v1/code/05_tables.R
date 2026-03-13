## 05_tables.R — Generate all LaTeX tables
## apep_0612: Immigration Judge Leniency and Local Crime

source("code/00_packages.R")

df       <- readRDS("data/analysis.rds")
results  <- readRDS("data/results.rds")
robust   <- readRDS("data/robustness.rds")
courts   <- readRDS("data/courts_clean.rds")

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("=== Table 1: Summary Statistics ===\n")

sum_vars <- df %>%
  transmute(
    `Homicide Rate (per 100K)`     = All_Homicide_avg_rate,
    `Firearm Homicide Rate`        = FA_Homicide_avg_rate,
    `Suicide Rate (per 100K)`      = All_Suicide_avg_rate,
    `Asylum Grant Rate (\\%)`       = state_grant_rate,
    `Judge Leniency Index (\\%)`    = state_judge_leniency,
    `Within-Court Leniency SD`     = state_leniency_sd,
    `Number of Courts`             = n_courts,
    `Number of Judges`             = total_judges,
    `Population (millions)`        = total_pop / 1e6,
    `Foreign-Born Share (\\%)`      = pct_foreign,
    `Poverty Rate (\\%)`            = poverty_rate,
    `Unemployment Rate (\\%)`       = unemp_rate
  )

sum_stats <- sum_vars %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "value") %>%
  group_by(Variable) %>%
  summarise(
    Mean   = mean(value, na.rm = TRUE),
    SD     = sd(value, na.rm = TRUE),
    Min    = min(value, na.rm = TRUE),
    Max    = max(value, na.rm = TRUE),
    .groups = "drop"
  )

# Maintain order
var_order <- names(sum_vars)
sum_stats <- sum_stats %>%
  mutate(Variable = factor(Variable, levels = var_order)) %>%
  arrange(Variable)

tab1_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & SD & Min & Max \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %d states with active immigration courts and CDC homicide data (2019--2024 average).
Judge Leniency Index is the caseload-weighted average career grant rate of immigration judges
at courts within each state. Within-Court Leniency SD measures the dispersion of grant rates
among judges in the same courthouse. Homicide rates from CDC Mapping Injury data.
Demographics from American Community Survey 5-year estimates (2022).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  paste(sapply(seq_len(nrow(sum_stats)), function(i) {
    sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
            sum_stats$Variable[i], sum_stats$Mean[i], sum_stats$SD[i],
            sum_stats$Min[i], sum_stats$Max[i])
  }), collapse = "\n"),
  nrow(df)
)

writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# ===================================================================
# Table 2: First Stage and Balance Tests
# ===================================================================
cat("=== Table 2: First Stage ===\n")

fs_models <- results$fs
bal_models <- robust$balance

# First stage table
tab2_tex <- capture.output({
  etable(
    fs_models[[1]], fs_models[[2]], fs_models[[3]],
    se = "HC1",
    tex = TRUE,
    style.tex = style.tex("aer"),
    title = "First Stage: Judge Leniency Predicts Asylum Grant Rate",
    label = "tab:first_stage",
    notes = paste(
      "Dependent variable: state-level asylum grant rate (\\%).",
      "Judge Leniency Index is the caseload-weighted average career grant rate",
      "of all immigration judges at courts within the state.",
      "Robust (HC1) standard errors in parentheses.",
      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
    ),
    depvar = FALSE,
    fitstat = c("r2", "n")
  )
})

writeLines(tab2_tex, "tables/tab2_first_stage.tex")
cat("  Written tables/tab2_first_stage.tex\n")

# ===================================================================
# Table 3: Main Results (OLS, Reduced Form, 2SLS)
# ===================================================================
cat("=== Table 3: Main Results ===\n")

iv_models <- results$iv

tab3_tex <- capture.output({
  etable(
    results$ols[[3]], results$rf[[2]],
    iv_models[[1]], iv_models[[2]], iv_models[[3]],
    se = "HC1",
    tex = TRUE,
    style.tex = style.tex("aer"),
    title = "Effect of Asylum Grant Rate on Homicide Rate",
    label = "tab:main",
    headers = c("OLS", "Reduced Form", "2SLS", "2SLS", "2SLS"),
    notes = paste(
      "Dependent variable: state-level average homicide rate per 100,000 (CDC, 2019--2024).",
      "In columns 3--5, asylum grant rate is instrumented by the Judge Leniency Index.",
      "Robust (HC1) standard errors in parentheses.",
      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
    ),
    fitstat = c("r2", "n", "ivf")
  )
})

writeLines(tab3_tex, "tables/tab3_main.tex")
cat("  Written tables/tab3_main.tex\n")

# ===================================================================
# Table 4: Robustness and Placebos
# ===================================================================
cat("=== Table 4: Robustness ===\n")

# Build robustness table with sensitivity analysis
sens_models <- robust$sensitivity

tab4_tex <- capture.output({
  etable(
    sens_models[[1]], sens_models[[2]], sens_models[[3]],
    sens_models[[4]], sens_models[[5]],
    se = "HC1",
    tex = TRUE,
    style.tex = style.tex("aer"),
    title = "Robustness: Sensitivity to Controls",
    label = "tab:robustness",
    headers = c("No Controls", "+ Pop", "+ Demo", "+ Region FE", "+ Unemp"),
    notes = paste(
      "Dependent variable: state-level homicide rate per 100,000.",
      "All specifications use 2SLS with Judge Leniency Index as instrument for asylum grant rate.",
      "Robust (HC1) standard errors in parentheses.",
      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
    ),
    fitstat = c("r2", "n", "ivf")
  )
})

writeLines(tab4_tex, "tables/tab4_robustness.tex")
cat("  Written tables/tab4_robustness.tex\n")

# ===================================================================
# Table 5: Balance and Placebos
# ===================================================================
cat("=== Table 5: Balance and Placebos ===\n")

bal_tex <- capture.output({
  etable(
    bal_models[[1]], bal_models[[2]], bal_models[[3]],
    bal_models[[4]], bal_models[[5]],
    se = "HC1",
    tex = TRUE,
    style.tex = style.tex("aer"),
    title = "Balance Tests: Judge Leniency Does Not Predict State Demographics",
    label = "tab:balance",
    headers = c("Log Pop", "Poverty", "Foreign", "Unemp", "Log Income"),
    notes = paste(
      "Each column regresses a state demographic variable on the Judge Leniency Index.",
      "If judge composition is quasi-random conditional on geography, these coefficients should be zero.",
      "Robust (HC1) standard errors in parentheses.",
      "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
    ),
    fitstat = c("r2", "n")
  )
})

writeLines(bal_tex, "tables/tab5_balance.tex")
cat("  Written tables/tab5_balance.tex\n")

# ===================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ===================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Get preferred IV specification (with controls + region FE)
iv_pref <- results$iv[[3]]  # iv_3: controls + region FE
iv_fa   <- results$iv[[4]]  # iv_4: firearm homicide

# Function to compute SDE
compute_sde <- function(model, outcome_var, outcome_label, treatment_var = "fit_state_grant_rate") {
  beta <- coef(model)[treatment_var]
  se_beta <- se(model)[treatment_var]
  sd_y <- sd(df[[outcome_var]], na.rm = TRUE)
  # Grant rate is continuous, so use SD(X) normalization
  sd_x <- sd(df$state_grant_rate, na.rm = TRUE)

  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
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

  tibble(
    Outcome = outcome_label,
    beta = beta,
    se = se_beta,
    sd_x = sd_x,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_rows <- bind_rows(
  compute_sde(iv_pref, "All_Homicide_avg_rate", "All Homicide Rate"),
  tryCatch(
    compute_sde(iv_fa, "FA_Homicide_avg_rate", "Firearm Homicide Rate"),
    error = function(e) tibble()
  )
)

# Add suicide placebo if available
if (!is.null(robust$placebo$suicide_iv)) {
  sde_rows <- bind_rows(sde_rows,
    tryCatch(
      compute_sde(robust$placebo$suicide_iv, "All_Suicide_avg_rate", "Suicide Rate (Placebo)"),
      error = function(e) tibble()
    )
  )
}

# Generate LaTeX table
sde_body <- paste(sapply(seq_len(nrow(sde_rows)), function(i) {
  r <- sde_rows[i, ]
  sprintf("%s & %.3f & %.3f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_x, r$sd_y,
          r$sde, r$se_sde, r$classification)
}), collapse = "\n")

n_obs <- nrow(df)

sde_tex <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lccccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)
to facilitate cross-study comparison of treatment effect magnitudes.
For this continuous treatment, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$,
which gives the effect of a one-standard-deviation change in the asylum grant rate,
measured in standard deviations of the outcome.
SD($Y$) and SD($X$) are unconditional standard deviations from the summary
statistics (Table~\\ref{tab:summary}), before conditioning on fixed effects.

\\textbf{Research question:} Does exogenous variation in asylum grant rates, driven by
immigration judge leniency, affect local homicide rates?
\\textbf{Treatment:} Continuous; state-level asylum grant rate (\\%%), instrumented by
Judge Leniency Index.
\\textbf{Data:} OpenImmigration.us (88 courts, 1,269 judges) merged with CDC Mapping Injury
(county-level homicide, 2019--2024), unit of observation is state, N = %d.
\\textbf{Method:} Cross-sectional 2SLS with Judge Leniency Index as instrument, HC1 standard errors.
\\textbf{Sample:} U.S. states with active immigration courts and CDC homicide data.

Classification thresholds (7 categories):
large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),
small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),
small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),
large positive ($> 0.15$).
Classification labels refer to the magnitude of the standardized point estimate,
not to statistical significance. ``Null'' denotes a near-zero effect size
($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}", sde_body, n_obs)

writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
