## 05_tables.R — Generate all tables including SDE appendix
## APEP-1174: The Enforcement Lottery

source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel_tri <- readRDS(file.path(data_dir, "panel_tri.rds"))
panel_full <- readRDS(file.path(data_dir, "panel_full.rds"))
state_year <- readRDS(file.path(data_dir, "state_year_fed.rds"))
models <- readRDS(file.path(data_dir, "models_main.rds"))
rob <- readRDS(file.path(data_dir, "models_robustness.rds"))
setDT(panel_tri); setDT(panel_full); setDT(state_year)

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

## Panel A: Full inspection sample
stats_full <- panel_full[, .(
  Variable = c("Inspections per facility-year", "Federal inspections",
               "Any federal inspection", "Federal share",
               "FCE rate"),
  Mean = round(c(mean(n_inspections), mean(n_federal), mean(any_federal),
                 mean(fed_share), mean(fce_rate)), 3),
  SD = round(c(sd(n_inspections), sd(n_federal), sd(any_federal),
               sd(fed_share), sd(fce_rate)), 3),
  N = nrow(panel_full)
)]

## Panel B: TRI-linked sample
stats_tri <- panel_tri[, .(
  Variable = c("Log(TRI releases + 1)", "TRI releases (1000 lbs)",
               "Inspections per facility-year", "Any federal inspection",
               "Federal share", "Number of pollutants"),
  Mean = round(c(mean(log_releases, na.rm = TRUE),
                 mean(total_releases_lbs/1000, na.rm = TRUE),
                 mean(n_inspections), mean(any_federal),
                 mean(fed_share), mean(n_pollutants, na.rm = TRUE)), 3),
  SD = round(c(sd(log_releases, na.rm = TRUE),
               sd(total_releases_lbs/1000, na.rm = TRUE),
               sd(n_inspections), sd(any_federal),
               sd(fed_share), sd(n_pollutants, na.rm = TRUE)), 3),
  N = nrow(panel_tri)
)]

## Panel C: State-year level
stats_state <- state_year[, .(
  Variable = c("State federal share", "State inspections",
               "State federal inspections"),
  Mean = round(c(mean(state_fed_share), mean(state_n_insp),
                 mean(state_n_federal)), 3),
  SD = round(c(sd(state_fed_share), sd(state_n_insp),
               sd(state_n_federal)), 3),
  N = nrow(state_year)
)]

## Generate LaTeX
tab1_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lrrr}
\\toprule
 & Mean & SD & N \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: All CAA-inspected facilities (2005--2023)}} \\\\[3pt]
",
paste(sapply(1:nrow(stats_full), function(i)
  sprintf("%s & %s & %s & %s \\\\", stats_full$Variable[i],
          format(stats_full$Mean[i], nsmall = 3),
          format(stats_full$SD[i], nsmall = 3),
          formatC(stats_full$N[i], format = "d", big.mark = ","))
), collapse = "\n"),
"
\\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: TRI-linked facilities}} \\\\[3pt]
",
paste(sapply(1:nrow(stats_tri), function(i)
  sprintf("%s & %s & %s & %s \\\\", stats_tri$Variable[i],
          format(stats_tri$Mean[i], nsmall = 3),
          format(stats_tri$SD[i], nsmall = 3),
          formatC(stats_tri$N[i], format = "d", big.mark = ","))
), collapse = "\n"),
"
\\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel C: State-year level}} \\\\[3pt]
",
paste(sapply(1:nrow(stats_state), function(i)
  sprintf("%s & %s & %s & %s \\\\", stats_state$Variable[i],
          format(stats_state$Mean[i], nsmall = 3),
          format(stats_state$SD[i], nsmall = 3),
          formatC(stats_state$N[i], format = "d", big.mark = ","))
), collapse = "\n"),
"
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Data from EPA ECHO (ICIS-Air compliance monitoring records) linked to TRI facility-level releases and ECHO Exporter facility characteristics. Sample covers Clean Air Act inspections from 2005 to 2023 across 51 states (including DC). Panel A includes all facilities receiving at least one CAA inspection. Panel B restricts to facilities also reporting to the Toxics Release Inventory. Panel C aggregates to state-year level. Federal inspections identified via the STATE\\_EPA\\_FLAG field (``E'' = EPA/federal inspector). TRI releases measured in pounds per facility-year across all reported chemicals.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ============================================================
## TABLE 2: Main Results (OLS and IV)
## ============================================================
cat("=== Table 2: Main Results ===\n")

## Use modelsummary for clean output
tab2_models <- list(
  "(1)" = models$m1_ols,
  "(2)" = models$m4_ctrl,
  "(3)" = models$m3_n,
  "(4)" = models$fs1,
  "(5)" = models$m5_iv
)

## Custom stats
gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) formatC(x, format = "d", big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 4),
  list("raw" = "FE: PGM_SYS_ID", "clean" = "Facility FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

cm <- c(
  "any_federal" = "Any federal inspection",
  "n_inspections" = "Total inspections",
  "n_federal" = "Number federal inspections",
  "state_fed_share" = "State federal share",
  "fit_any_federal" = "Any federal (IV)"
)

tab2_tex <- modelsummary(
  tab2_models,
  stars = c("*" = .1, "**" = .05, "***" = .01),
  coef_map = cm,
  gof_map = gm,
  output = "latex",
  title = "Federal Enforcement and TRI Releases",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "Dependent variable: log(TRI releases + 1). Columns (1)--(3) report OLS estimates with facility and year fixed effects.",
    "Column (4) shows the first stage: state-year federal inspection share predicts facility-level federal inspection.",
    "Column (5) reports the IV estimate instrumenting facility federal inspection with state-year aggregate share.",
    "First-stage F-statistic = 396.8."
  )
)

## Add label
tab2_tex <- sub("\\\\caption\\{", "\\\\caption{", tab2_tex)
tab2_tex <- sub("\\\\caption\\{Federal Enforcement",
                "\\\\label{tab:main}\\\\caption{Federal Enforcement", tab2_tex)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ============================================================
## TABLE 3: Event Study Coefficients
## ============================================================
cat("=== Table 3: Event Study ===\n")

if (!is.null(rob$event_study)) {
  es <- rob$event_study
  es_coefs <- data.table(
    Event_Time = c(-5, -4, -3, -2, 0, 1, 2, 3, 4, 5),
    Coefficient = round(coef(es), 3),
    SE = round(se(es), 3)
  )
  es_coefs[, Stars := fifelse(abs(Coefficient/SE) > 2.576, "***",
                     fifelse(abs(Coefficient/SE) > 1.96, "**",
                     fifelse(abs(Coefficient/SE) > 1.645, "*", "")))]

  tab3_body <- paste(sapply(1:nrow(es_coefs), function(i) {
    sprintf("$%s$ & %s%s & (%s) \\\\",
            ifelse(es_coefs$Event_Time[i] == -1, "-1", as.character(es_coefs$Event_Time[i])),
            format(es_coefs$Coefficient[i], nsmall = 3),
            es_coefs$Stars[i],
            format(es_coefs$SE[i], nsmall = 3))
  }), collapse = "\n")

  tab3_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Event Study: Log(TRI Releases) Around First Federal Inspection}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time & Coefficient & SE \\\\
\\midrule
$-1$ & \\multicolumn{2}{c}{[Reference]} \\\\
", tab3_body, "
\\midrule
Facility FE & \\multicolumn{2}{c}{Yes} \\\\
Year FE & \\multicolumn{2}{c}{Yes} \\\\
Observations & \\multicolumn{2}{c}{", formatC(nobs(es), format = "d", big.mark = ","), "} \\\\
Facilities & \\multicolumn{2}{c}{", formatC(es$fixef_sizes[1], format = "d", big.mark = ","), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Event study regression of log(TRI releases + 1) on event-time dummies relative to a facility's first federal (EPA) inspection, with period $t = -1$ as the reference category. Extreme event times are binned at $\\pm 5$. Standard errors clustered at state level. Sample restricted to facilities that receive at least one federal inspection during the 2005--2023 period. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

  writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))
  cat("Table 3 written.\n")
}

## ============================================================
## TABLE 4: Robustness Checks
## ============================================================
cat("=== Table 4: Robustness ===\n")

rob_models <- list()
rob_models[["(1) Baseline"]] <- models$m1_ols
rob_models[["(2) FCE only"]] <- rob$fce_only
rob_models[["(3) Pre-2017"]] <- rob$pre_2017
rob_models[["(4) Post-2016"]] <- rob$post_2016

if (!is.null(rob$non_manufacturing)) {
  rob_models[["(5) Non-mfg"]] <- rob$non_manufacturing
}

tab4_tex <- modelsummary(
  rob_models,
  stars = c("*" = .1, "**" = .05, "***" = .01),
  coef_map = c("any_federal" = "Any federal inspection",
               "any_federal_fce" = "Any federal FCE"),
  gof_map = gm,
  output = "latex",
  title = "Robustness: Federal Enforcement and TRI Releases",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "Dependent variable: log(TRI releases + 1). All models include facility and year FE.",
    "Column (2) restricts to Full Compliance Evaluations (the most rigorous inspection type).",
    "Columns (3)--(4) split the sample at 2017. Column (5) restricts to non-manufacturing facilities.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

tab4_tex <- sub("\\\\caption\\{Robustness",
                "\\\\label{tab:robustness}\\\\caption{Robustness", tab4_tex)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

## ============================================================
## TABLE 5: State-Year Reduced Form
## ============================================================
cat("=== Table 5: State-Year Analysis ===\n")

state_models <- list(
  "(1)" = models$m7_rf,
  "(2)" = models$m8_rf_total,
  "(3)" = models$m9_rf_binary,
  "(4)" = models$m10_insp,
  "(5)" = models$m11_fce
)

cm_state <- c(
  "fed_share" = "Federal inspection share",
  "high_federal" = "High federal (2 SD above mean)",
  "state_fed_share" = "State federal share"
)

gm_state <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) formatC(x, format = "d", big.mark = ",")),
  list("raw" = "FE: state_id", "clean" = "State FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: PGM_SYS_ID", "clean" = "Facility FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

tab5_tex <- modelsummary(
  state_models,
  stars = c("*" = .1, "**" = .05, "***" = .01),
  coef_map = cm_state,
  gof_map = gm_state,
  output = "latex",
  title = "State-Year Federal Enforcement and Outcomes",
  notes = list(
    "Standard errors clustered at state level in parentheses.",
    "Columns (1)--(3): state-year level. Dep. var. in (1): mean log(TRI releases); (2): log(total TRI releases); (3): mean log(TRI releases) with binary instrument.",
    "Columns (4)--(5): facility-year level (all inspected facilities). Dep. var. in (4): number of inspections; (5): FCE rate.",
    "All models include state (or facility) and year fixed effects.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

tab5_tex <- sub("\\\\caption\\{State-Year",
                "\\\\label{tab:stateyear}\\\\caption{State-Year", tab5_tex)

writeLines(tab5_tex, file.path(table_dir, "tab5_stateyear.tex"))
cat("Table 5 written.\n")

## ============================================================
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
## ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDE for main outcomes
## Binary treatment: SDE = beta_hat / SD(Y)
sd_y_tri <- sd(panel_tri$log_releases, na.rm = TRUE)

## Main models for SDE
sde_rows <- data.table(
  Outcome = character(),
  Beta = numeric(),
  SE_beta = numeric(),
  SD_Y = numeric(),
  SDE = numeric(),
  SE_SDE = numeric(),
  Classification = character()
)

## Model 1: any_federal → log(releases) [OLS]
b1 <- coef(models$m1_ols)["any_federal"]
se1 <- se(models$m1_ols)["any_federal"]
sde1 <- b1 / sd_y_tri
se_sde1 <- se1 / sd_y_tri

## Model 5: IV estimate
b5 <- coef(models$m5_iv)["fit_any_federal"]
se5 <- se(models$m5_iv)["fit_any_federal"]
sde5 <- b5 / sd_y_tri
se_sde5 <- se5 / sd_y_tri

## FCE-only
b_fce <- coef(rob$fce_only)["any_federal_fce"]
se_fce <- se(rob$fce_only)["any_federal_fce"]
sde_fce <- b_fce / sd_y_tri
se_sde_fce <- se_fce / sd_y_tri

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

sde_rows <- rbind(sde_rows, data.table(
  Outcome = c("Log(TRI releases) --- OLS",
              "Log(TRI releases) --- IV",
              "Log(TRI releases) --- FCE only"),
  Beta = round(c(b1, b5, b_fce), 4),
  SE_beta = round(c(se1, se5, se_fce), 4),
  SD_Y = round(rep(sd_y_tri, 3), 4),
  SDE = round(c(sde1, sde5, sde_fce), 4),
  SE_SDE = round(c(se_sde1, se_sde5, se_sde_fce), 4),
  Classification = c(classify_sde(sde1), classify_sde(sde5), classify_sde(sde_fce))
))

## Panel B: Heterogeneity (sample splits)
## Non-manufacturing
panel_tri[, manufacturing := as.integer(naics2 %in% c("31", "32", "33"))]
if (!is.null(rob$non_manufacturing)) {
  b_nm <- coef(rob$non_manufacturing)["any_federal"]
  se_nm <- se(rob$non_manufacturing)["any_federal"]
  sd_y_nm <- sd(panel_tri[manufacturing == 0]$log_releases, na.rm = TRUE)
  sde_nm <- b_nm / sd_y_nm
  se_sde_nm <- se_nm / sd_y_nm

  sde_rows <- rbind(sde_rows, data.table(
    Outcome = "Log(TRI releases) --- Non-manufacturing",
    Beta = round(b_nm, 4),
    SE_beta = round(se_nm, 4),
    SD_Y = round(sd_y_nm, 4),
    SDE = round(sde_nm, 4),
    SE_SDE = round(se_sde_nm, 4),
    Classification = classify_sde(sde_nm)
  ))
}

## NEI outcome
if (!is.null(rob$nei)) {
  b_nei <- coef(rob$nei)["any_federal"]
  se_nei <- se(rob$nei)["any_federal"]
  sd_y_nei <- sd(panel_tri[!is.na(log_nei)]$log_nei, na.rm = TRUE)
  sde_nei <- b_nei / sd_y_nei
  se_sde_nei <- se_nei / sd_y_nei

  sde_rows <- rbind(sde_rows, data.table(
    Outcome = "Log(NEI emissions) --- OLS",
    Beta = round(b_nei, 4),
    SE_beta = round(se_nei, 4),
    SD_Y = round(sd_y_nei, 4),
    SDE = round(sde_nei, 4),
    SE_SDE = round(se_sde_nei, 4),
    Classification = classify_sde(sde_nei)
  ))
}

cat("SDE table:\n")
print(sde_rows)

## SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does federal (EPA) enforcement of the Clean Air Act affect facility-level toxic releases, compared to state-delegated enforcement? ",
  "\\textbf{Policy mechanism:} Under cooperative federalism, EPA delegates Clean Air Act enforcement to state agencies but retains concurrent authority to conduct inspections. Federal inspectors operate under different institutional incentives (no revolving door with local industry, national rather than state-level performance metrics) and may enforce more stringently. ",
  "\\textbf{Outcome definition:} Log of annual Toxics Release Inventory (TRI) total releases in pounds plus one, summing all reported chemicals per facility-year; alternative outcome uses National Emissions Inventory (NEI) annual emissions. ",
  "\\textbf{Treatment:} Binary indicator for whether a facility received at least one federal (EPA) inspection in a given year. ",
  "\\textbf{Data:} EPA ECHO ICIS-Air compliance monitoring records linked to TRI facility-year releases via FRS crosswalk, 2005--2023, ",
  formatC(nrow(panel_tri), format = "d", big.mark = ","), " facility-year observations from ",
  formatC(uniqueN(panel_tri$PGM_SYS_ID), format = "d", big.mark = ","), " facilities across 51 states. ",
  "\\textbf{Method:} Two-way fixed effects (facility + year) OLS and IV (instrumenting facility-level federal inspection with state-year aggregate federal inspection share); standard errors clustered at state level. ",
  "\\textbf{Sample:} Restricted to facilities in both ICIS-Air and TRI databases; excludes territories; ",
  "all years with at least one inspection. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the within-sample ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

## Build LaTeX table
n_panel_a <- min(3, nrow(sde_rows))
n_panel_b <- nrow(sde_rows) - n_panel_a

sde_body_a <- paste(sapply(1:n_panel_a, function(i) {
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
          sde_rows$Outcome[i],
          format(sde_rows$Beta[i], nsmall = 4),
          format(sde_rows$SE_beta[i], nsmall = 4),
          format(sde_rows$SD_Y[i], nsmall = 2),
          format(sde_rows$SDE[i], nsmall = 4),
          format(sde_rows$SE_SDE[i], nsmall = 4),
          sde_rows$Classification[i])
}), collapse = "\n")

sde_body_b <- ""
if (n_panel_b > 0) {
  sde_body_b <- paste(sapply((n_panel_a + 1):nrow(sde_rows), function(i) {
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_rows$Outcome[i],
            format(sde_rows$Beta[i], nsmall = 4),
            format(sde_rows$SE_beta[i], nsmall = 4),
            format(sde_rows$SD_Y[i], nsmall = 2),
            format(sde_rows$SDE[i], nsmall = 4),
            format(sde_rows$SE_SDE[i], nsmall = 4),
            sde_rows$Classification[i])
  }), collapse = "\n")
}

tabF1_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes: Federal Enforcement and Toxic Releases}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
", sde_body_a, "
\\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]
", sde_body_b, "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
cat("Files in", table_dir, ":\n")
for (f in list.files(table_dir)) cat("  ", f, "\n")
