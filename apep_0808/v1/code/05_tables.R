## ── 05_tables.R ───────────────────────────────────────────────────────────────
## Generate all LaTeX tables for apep_0808
## ──────────────────────────────────────────────────────────────────────────────

source("code/00_packages.R")

cat("=== GENERATING TABLES FOR APEP_0808 ===\n\n")

df <- readRDS("data/analysis_dataset.rds")
models <- readRDS("data/models.rds")
sub_results <- readRDS("data/sub_results.rds")
state_results <- readRDS("data/state_results.rds")
wave_comparison <- readRDS("data/wave_comparison.rds")

## ── Table 1: Summary Statistics ──────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

tab1_data <- data.table(
  Panel = c(rep("Panel A: Full Sample", 4),
            rep("Panel B: By Subsection", 6),
            rep("Panel C: By Outcome", 2)),
  Variable = c(
    "Total organizations revoked",
    "States represented",
    "Subsection types",
    "Mean reinstatement rate",
    "501(c)(3) Charitable",
    "501(c)(4) Social Welfare",
    "501(c)(7) Social Club",
    "501(c)(8) Fraternal",
    "501(c)(13) Cemetery",
    "501(c)(19) Veterans",
    "Reinstated (N)",
    "Permanently revoked (N)"
  ),
  Value = c(
    format(nrow(df), big.mark = ","),
    as.character(uniqueN(df$state)),
    as.character(uniqueN(df$subsection_code)),
    sprintf("%.1f\\%%", mean(df$reinstated) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$is_c3), big.mark = ","),
            mean(df$is_c3) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$is_c4), big.mark = ","),
            mean(df$is_c4) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$is_c7), big.mark = ","),
            mean(df$is_c7) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$is_c8), big.mark = ","),
            mean(df$is_c8) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$subsection_code == 13), big.mark = ","),
            mean(df$subsection_code == 13) * 100),
    sprintf("%s (%.1f\\%%)",
            format(sum(df$subsection_code == 19), big.mark = ","),
            mean(df$subsection_code == 19) * 100),
    format(sum(df$reinstated), big.mark = ","),
    format(sum(!df$reinstated), big.mark = ",")
  )
)

## Write LaTeX
tex1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: 2010 IRS Mass Revocation}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & Value \\\\",
  "\\midrule"
)

current_panel <- ""
for (i in seq_len(nrow(tab1_data))) {
  if (tab1_data$Panel[i] != current_panel) {
    if (current_panel != "") tex1 <- c(tex1, "\\addlinespace[6pt]")
    tex1 <- c(tex1, sprintf("\\multicolumn{2}{l}{\\textit{%s}} \\\\",
                            tab1_data$Panel[i]))
    current_panel <- tab1_data$Panel[i]
  }
  tex1 <- c(tex1, sprintf("\\quad %s & %s \\\\",
                          tab1_data$Variable[i], tab1_data$Value[i]))
}

tex1 <- c(tex1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} The 2010 wave represents organizations that had their tax-exempt status automatically revoked under the Pension Protection Act of 2006 for failing to file required information returns for three consecutive tax years (2007--2009). Reinstatement is identified by matching revoked EINs against the current IRS Exempt Organizations Business Master File. Source: IRS Auto-Revocation List and Exempt Organizations Business Master File.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex1, "tables/tab1_summary.tex")

## ── Table 2: Reinstatement Rates by Subsection ──────────────────────────────
cat("Generating Table 2: Reinstatement by Subsection...\n")

tab2_data <- df[subsection_code %in% c(3, 4, 5, 6, 7, 8, 13, 19), .(
  n_revoked = .N,
  n_reinstated = sum(reinstated),
  rate = mean(reinstated) * 100
), by = .(subsection_code, subsection_label)][order(-n_revoked)]

tex2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Reinstatement Rates by Organizational Subsection}",
  "\\label{tab:subsection}",
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  "Subsection Type & Revoked & Reinstated & Rate (\\%) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(tab2_data))) {
  tex2 <- c(tex2, sprintf("%s & %s & %s & %.1f \\\\",
                          tab2_data$subsection_label[i],
                          format(tab2_data$n_revoked[i], big.mark = ","),
                          format(tab2_data$n_reinstated[i], big.mark = ","),
                          tab2_data$rate[i]))
}

tex2 <- c(tex2,
  "\\midrule",
  sprintf("Total & %s & %s & %.1f \\\\",
          format(nrow(df), big.mark = ","),
          format(sum(df$reinstated), big.mark = ","),
          mean(df$reinstated) * 100),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample restricted to U.S. organizations in the 2010 PPA revocation wave. Reinstatement is identified by matching revoked EINs to the current IRS Exempt Organizations BMF. Subsection types ordered by number of revocations. Organizations holding physical assets (cemeteries, veterans posts, social clubs, fraternal lodges) exhibit systematically higher reinstatement rates than purely charitable organizations. Source: IRS Auto-Revocation List and BMF extract.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex2, "tables/tab2_subsection.tex")

## ── Table 3: Main Regression Results ─────────────────────────────────────────
cat("Generating Table 3: Regression Results...\n")

## Use fixest's etable for clean LaTeX output
etable(models$m1, models$m2, models$m4,
       tex = TRUE,
       file = "tables/tab3_regression.tex",
       title = "Determinants of Reinstatement After Mass Revocation",
       label = "tab:regression",
       headers = c("(1) OLS", "(2) State FE", "(3) Asset FE"),
       dict = c(
         is_c3 = "501(c)(3)",
         is_c4 = "501(c)(4)",
         is_c5 = "501(c)(5)",
         is_c6 = "501(c)(6)",
         is_c8 = "501(c)(8)",
         has_physical_assets = "Physical Asset Org.",
         state = "State"
       ),
       notes = c(
         "Dependent variable: Reinstated (= 1 if organization regained tax-exempt status).",
         "Reference category in (1)--(2): 501(c)(7) Social Club.",
         "Physical Asset Org.~in (3): 501(c)(5), (c)(7), (c)(8), (c)(13), (c)(19).",
         "Standard errors: (1) heteroskedasticity-robust; (2)--(3) clustered by state.",
         "Source: IRS Auto-Revocation List matched to BMF."
       ),
       fitstat = c("n", "r2"),
       se.below = TRUE,
       drop = "Intercept")

## ── Table 4: Revocation Waves Over Time ──────────────────────────────────────
cat("Generating Table 4: Revocation Waves...\n")

tex4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Annual Revocations and Reinstatement Rates, 2010--2023}",
  "\\label{tab:waves}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Revoked & Reinstated & Rate (\\%) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(wave_comparison))) {
  yr <- wave_comparison$rev_year[i]
  bold <- ifelse(yr == 2010, "\\textbf{", "")
  end_bold <- ifelse(yr == 2010, "}", "")
  tex4 <- c(tex4, sprintf("%s%d%s & %s%s%s & %s%s%s & %s%.1f%s \\\\",
                          bold, yr, end_bold,
                          bold, format(wave_comparison$n_revoked[i], big.mark = ","), end_bold,
                          bold, format(wave_comparison$n_reinstated[i], big.mark = ","), end_bold,
                          bold, wave_comparison$rate[i], end_bold))
}

tex4 <- c(tex4,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} The 2010 row (bolded) represents the first-ever mass automatic revocation under the Pension Protection Act of 2006. Subsequent years show ongoing annual revocations for continued non-filing. Reinstatement declines over time as organizations revoked more recently have had less time to reinstate. Source: IRS Auto-Revocation List matched to BMF.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex4, "tables/tab4_waves.tex")

## ── Table F1: Standardized Effect Sizes (SDE) ───────────────────────────────
cat("Generating SDE Table (Appendix)...\n")

## Compute SDEs from LPM coefficients
## Binary treatment (subsection indicators), outcome = reinstated {0,1}
sd_y <- sd(df$reinstated)

## Main effects from Model 2 (with state FE)
m2 <- models$m2
coefs <- coef(m2)
ses <- se(m2)

## SDE table: effect of each subsection relative to c(7)
sde_vars <- c("is_c3", "is_c4", "is_c5", "is_c6", "is_c8")
sde_labels <- c(
  "501(c)(3) Charitable",
  "501(c)(4) Social Welfare",
  "501(c)(5) Labor/Agricultural",
  "501(c)(6) Business League",
  "501(c)(8) Fraternal"
)

sde_data <- data.table(
  Outcome = sde_labels,
  Beta = coefs[sde_vars],
  SE = ses[sde_vars],
  SD_Y = sd_y,
  SDE = coefs[sde_vars] / sd_y,
  SE_SDE = ses[sde_vars] / sd_y
)

sde_data[, Classification := fcase(
  SDE < -0.15, "Large negative",
  SDE >= -0.15 & SDE < -0.05, "Moderate negative",
  SDE >= -0.05 & SDE < -0.005, "Small negative",
  SDE >= -0.005 & SDE <= 0.005, "Null",
  SDE > 0.005 & SDE <= 0.05, "Small positive",
  SDE > 0.05 & SDE <= 0.15, "Moderate positive",
  SDE > 0.15, "Large positive"
)]

## Build LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does organizational type predict reinstatement after the 2010 IRS mass revocation of tax-exempt status under the Pension Protection Act? ",
  "\\textbf{Policy mechanism:} The PPA of 2006 created a new filing requirement (Form 990-N) for small tax-exempt organizations; three consecutive years of non-filing triggered automatic revocation of tax-exempt status, executed en masse in June 2011 for 377,409 organizations. ",
  "\\textbf{Outcome definition:} Binary reinstatement indicator equal to one if the organization's EIN appears in the current IRS Exempt Organizations Business Master File. ",
  "\\textbf{Treatment:} Binary indicators for organizational subsection type (501(c)(3), (c)(4), (c)(5), (c)(6), (c)(8)) relative to 501(c)(7) Social Club. ",
  "\\textbf{Data:} IRS Auto-Revocation List matched to Exempt Organizations BMF, 2010 revocation wave, 376,472 U.S. organizations. ",
  "\\textbf{Method:} Linear probability model with state fixed effects, standard errors clustered by state. ",
  "\\textbf{Sample:} All U.S. organizations in the 2010 PPA mass revocation wave with valid state codes. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the sample ",
  "standard deviation of the reinstatement indicator. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

texF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Subsection Type and Reinstatement}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_data))) {
  texF1 <- c(texF1, sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
                            sde_data$Outcome[i],
                            sde_data$Beta[i],
                            sde_data$SE[i],
                            sde_data$SD_Y[i],
                            sde_data$SDE[i],
                            sde_data$SE_SDE[i],
                            sde_data$Classification[i]))
}

texF1 <- c(texF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(texF1, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files: tab1_summary.tex, tab2_subsection.tex, tab3_regression.tex,\n")
cat("       tab4_waves.tex, tabF1_sde.tex\n")
