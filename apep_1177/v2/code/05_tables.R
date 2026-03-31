## 05_tables.R — Generate all LaTeX tables
## apep_1177: The Conviction Lottery

source("./code/00_packages.R")

dt <- fread("./data/analysis_data.csv")
results <- readRDS("./data/regression_results.rds")

tables_dir <- "./tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Table 1: Summary Statistics ----
summ <- results$summary_stats
tab1 <- kbl(summ, format = "latex", booktabs = TRUE,
            caption = "Summary Statistics: Drug Trafficking Cases in São Paulo",
            label = "tab:summary") |>
  kable_styling(latex_options = "hold_position")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written\n")

## ---- Table 2: Vara Leniency Distribution ----
# Show distribution of conviction rates across varas
vara_stats <- dt[, .(
  n_cases = .N,
  conv_rate = mean(convicted, na.rm = TRUE),
  pretrial_rate = mean(pretrial_detained, na.rm = TRUE)
), by = vara_codigo][n_cases >= 20]  # Min 20 cases per vara

vara_dist <- data.table(
  Statistic = c("Number of varas", "Mean cases per vara",
                "Mean conviction rate", "SD conviction rate",
                "P10 conviction rate", "P25 conviction rate",
                "P50 conviction rate", "P75 conviction rate",
                "P90 conviction rate", "P90-P10 spread"),
  Value = c(
    nrow(vara_stats),
    round(mean(vara_stats$n_cases), 0),
    round(mean(vara_stats$conv_rate), 3),
    round(sd(vara_stats$conv_rate), 3),
    round(quantile(vara_stats$conv_rate, 0.10), 3),
    round(quantile(vara_stats$conv_rate, 0.25), 3),
    round(quantile(vara_stats$conv_rate, 0.50), 3),
    round(quantile(vara_stats$conv_rate, 0.75), 3),
    round(quantile(vara_stats$conv_rate, 0.90), 3),
    round(quantile(vara_stats$conv_rate, 0.90) -
            quantile(vara_stats$conv_rate, 0.10), 3)
  )
)

tab2 <- kbl(vara_dist, format = "latex", booktabs = TRUE,
            caption = "Distribution of Vara-Level Conviction Rates",
            label = "tab:vara_dist") |>
  kable_styling(latex_options = "hold_position")

# Add table notes
tab2_notes <- paste0(tab2, "\n\\begin{flushleft}\\small\n",
                     "\\textit{Notes:} Each observation is a criminal vara in S\\~ao Paulo ",
                     "handling $\\geq$20 drug trafficking cases. Conviction rate is the ",
                     "share of cases ending in \\textit{Proced\\^encia} (prosecution succeeded). ",
                     "The P90--P10 spread measures the range of conviction rates between the ",
                     "most and least severe varas.\n\\end{flushleft}")

writeLines(tab2_notes, file.path(tables_dir, "tab2_vara_dist.tex"))
cat("Table 2 written\n")

## ---- Table 3: First Stage and Reduced Form ----
models <- list(
  "Conviction" = results$first_stage_fe,
  "Pretrial Det." = results$rf_detention,
  "Log Duration" = results$rf_duration
)

tab3_tex <- capture.output(
  msummary(models,
           stars = c('*' = .1, '**' = .05, '***' = .01),
           coef_map = c("vara_leniency" = "Vara Leniency (LOO)"),
           gof_map = c("nobs", "r.squared"),
           output = "latex",
           title = "Reduced-Form Effects of Vara Assignment",
           notes = c("\\\\textit{Notes:} All specifications include assignment-pool $\\\\times$ year fixed effects. ",
                     "Standard errors clustered at the vara level in parentheses. ",
                     "Vara leniency is the leave-one-out conviction rate of the assigned vara, ",
                     "computed from all other cases in the same assignment pool. ",
                     "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_reduced_form.tex"))
cat("Table 3 written\n")

## ---- Table 4: Balance Tests ----
balance_models <- list(
  "Filing Month" = results$balance_month,
  "N Movements" = results$balance_movements
)

tab4_tex <- capture.output(
  msummary(balance_models,
           stars = c('*' = .1, '**' = .05, '***' = .01),
           coef_map = c("vara_leniency" = "Vara Leniency (LOO)"),
           gof_map = c("nobs", "r.squared"),
           output = "latex",
           title = "Balance Tests: Pre-Determined Covariates and Vara Leniency",
           notes = c("\\\\textit{Notes:} Tests whether vara leniency predicts case characteristics. ",
                     "Filing month is pre-determined at case initiation. ",
                     "All specifications include assignment-pool $\\\\times$ year fixed effects. ",
                     "Standard errors clustered at the vara level."))
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_balance.tex"))
cat("Table 4 written\n")

## ---- Table 5: Robustness ----
rob <- readRDS("./data/robustness_results.rds")

rob_models <- list(
  "Main (Pool×Year)" = rob$pool_year_fe,
  "Comarca FE" = rob$comarca_fe,
  "Split A" = rob$ujive_a,
  "Split B" = rob$ujive_b
)
# Remove NULLs
rob_models <- rob_models[!sapply(rob_models, is.null)]

tab5_tex <- capture.output(
  msummary(rob_models,
           stars = c('*' = .1, '**' = .05, '***' = .01),
           coef_map = c("vara_leniency" = "Vara Leniency (LOO)"),
           gof_map = c("nobs", "r.squared"),
           output = "latex",
           title = "Robustness: Alternative Specifications",
           notes = c("\\\\textit{Notes:} Column 1 is the main specification with assignment-pool $\\\\times$ year FE. ",
                     "Column 2 uses comarca FE only. Columns 3--4 split the sample of varas in half ",
                     "for a split-sample jackknife IV check. ",
                     "Standard errors clustered at the vara level."))
)
writeLines(tab5_tex, file.path(tables_dir, "tab5_robustness.tex"))
cat("Table 5 written\n")

## ---- Table F1: SDE Appendix ----
# Standard Deviation Effect for conviction and pretrial detention
sde_rows <- data.table(
  Outcome = character(),
  Beta = numeric(),
  SE = numeric(),
  SD_Y = numeric(),
  SDE = numeric(),
  SE_SDE = numeric(),
  Classification = character()
)

# Conviction (from first stage)
beta_conv <- coef(results$first_stage_fe)["vara_leniency"]
se_conv <- sqrt(vcov(results$first_stage_fe)["vara_leniency", "vara_leniency"])
sd_conv <- sd(dt$convicted, na.rm = TRUE)
sde_conv <- beta_conv / sd_conv
se_sde_conv <- se_conv / sd_conv
class_conv <- ifelse(abs(sde_conv) > 0.15, "Large",
                     ifelse(abs(sde_conv) > 0.05, "Moderate",
                            ifelse(abs(sde_conv) > 0.005, "Small", "Null")))

sde_rows <- rbind(sde_rows, data.table(
  Outcome = "Convicted",
  Beta = round(beta_conv, 4),
  SE = round(se_conv, 4),
  SD_Y = round(sd_conv, 4),
  SDE = round(sde_conv, 4),
  SE_SDE = round(se_sde_conv, 4),
  Classification = class_conv
))

# Pretrial detention
if (!is.null(results$rf_detention)) {
  beta_det <- coef(results$rf_detention)["vara_leniency"]
  se_det <- sqrt(vcov(results$rf_detention)["vara_leniency", "vara_leniency"])
  sd_det <- sd(dt$pretrial_detained, na.rm = TRUE)
  sde_det <- beta_det / sd_det
  se_sde_det <- se_det / sd_det
  class_det <- ifelse(abs(sde_det) > 0.15, "Large",
                      ifelse(abs(sde_det) > 0.05, "Moderate",
                             ifelse(abs(sde_det) > 0.005, "Small", "Null")))

  sde_rows <- rbind(sde_rows, data.table(
    Outcome = "Pretrial Detention",
    Beta = round(beta_det, 4),
    SE = round(se_det, 4),
    SD_Y = round(sd_det, 4),
    SDE = round(sde_det, 4),
    SE_SDE = round(se_sde_det, 4),
    Classification = class_det
  ))
}

# Generate SDE table with mandatory fields
sde_tab <- kbl(sde_rows, format = "latex", booktabs = TRUE,
               col.names = c("Outcome", "$\\hat{\\beta}$", "SE",
                             "SD($Y$)", "SDE", "SE(SDE)", "Classification"),
               escape = FALSE,
               caption = "Standardized Distributional Effects",
               label = "tab:sde") |>
  kable_styling(latex_options = "hold_position") |>
  pack_rows("Panel A: Pooled", 1, nrow(sde_rows)) |>
  pack_rows("Panel B: Heterogeneous", nrow(sde_rows) + 1, nrow(sde_rows))

# Add mandatory table notes
sde_notes <- paste0(
  "\\begin{flushleft}\\small\n",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does random vara assignment create a conviction lottery in drug trafficking cases? ",
  "\\textbf{Policy mechanism:} Lei 11.343/2006 grants judges unrestricted discretion over drug classification (use vs.\\ trafficking) with no objective quantity thresholds. ",
  "\\textbf{Outcome definition:} Binary conviction (\\textit{Proced\\^encia}) and pretrial detention from judicial movement records. ",
  "\\textbf{Treatment:} Assignment to a more vs.\\ less severe criminal vara via electronic lottery (\\textit{sorteio}). ",
  "\\textbf{Data:} CNJ DataJud public API, TJSP first-instance drug trafficking cases (2015--2023). ",
  "\\textbf{Method:} Judge (vara) leniency IV with leave-one-out conviction rate instrument, assignment-pool $\\times$ year FE. ",
  "\\textbf{Sample:} Multi-vara comarcas in S\\~ao Paulo with $\\geq$2 criminal varas. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "Classification refers to magnitude, not statistical significance. ",
  "Large: $|\\text{SDE}| > 0.15$; Moderate: 0.05--0.15; Small: 0.005--0.05; Null: $< 0.005$.\n",
  "\\end{flushleft}"
)

writeLines(c(sde_tab, sde_notes), file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written\n")

cat("\nAll tables generated.\n")
