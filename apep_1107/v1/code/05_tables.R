## 05_tables.R — Generate all LaTeX tables
## apep_1107: Romania Overnight Payroll Tax Shift

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
core_agg <- readRDS("../data/core_agg.rds")
core_sectors <- readRDS("../data/core_sectors.rds")

cat("=== Generating LaTeX Tables ===\n")

## ══════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ══════════════════════════════════════════════════════════════════════

pre_data <- core_agg |>
  filter(time < as.Date("2018-01-01")) |>
  group_by(country_group) |>
  summarise(
    mean_wages = mean(wages, na.rm = TRUE),
    sd_wages = sd(wages, na.rm = TRUE),
    mean_nonwage = mean(nonwage, na.rm = TRUE),
    sd_nonwage = sd(nonwage, na.rm = TRUE),
    mean_share = mean(nonwage_share, na.rm = TRUE),
    sd_share = sd(nonwage_share, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  )

## Write LaTeX manually for full control
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Pre-Reform Summary Statistics (2016--2017)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Wage Index (D11)} & \\multicolumn{2}{c}{Non-Wage Index} & \\multicolumn{2}{c}{Non-Wage Share} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Country & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

## Individual country stats for pre-period
country_pre <- core_agg |>
  filter(time >= as.Date("2016-01-01"), time < as.Date("2018-01-01")) |>
  group_by(country) |>
  summarise(
    mean_wages = mean(wages, na.rm = TRUE),
    sd_wages = sd(wages, na.rm = TRUE),
    mean_nonwage = mean(nonwage, na.rm = TRUE),
    sd_nonwage = sd(nonwage, na.rm = TRUE),
    mean_share = mean(nonwage_share, na.rm = TRUE),
    sd_share = sd(nonwage_share, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) |>
  arrange(desc(country == "RO"), country)

country_names <- c(RO = "Romania", BG = "Bulgaria", CZ = "Czechia",
                   HU = "Hungary", PL = "Poland", SK = "Slovakia")

for (i in seq_len(nrow(country_pre))) {
  cc <- country_pre$country[i]
  cname <- country_names[cc]
  if (cc == "RO") cname <- "\\textbf{Romania}"
  line <- sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.3f & %.3f \\\\",
                  cname,
                  country_pre$mean_wages[i], country_pre$sd_wages[i],
                  country_pre$mean_nonwage[i], country_pre$sd_nonwage[i],
                  country_pre$mean_share[i], country_pre$sd_share[i])
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Pre-reform quarterly averages of the Eurostat Labour Cost Index (2020=100), seasonally and calendar adjusted. Wage Index (D11) captures gross wages and salaries. Non-Wage Index captures employer social contributions (D12) plus other non-wage costs. Non-Wage Share = Non-Wage / (Wage + Non-Wage). Romania's pre-reform non-wage share of 0.83 reflects its high employer SSC rate (22.75\\%) and drops to approximately 0.48 after Q1 2018. Aggregate sector B--S (business economy).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Wrote tab1_summary.tex\n")


## ══════════════════════════════════════════════════════════════════════
## TABLE 2: Main DiD Results
## ══════════════════════════════════════════════════════════════════════

## Use modelsummary to create the main results table
main_models <- list(
  "Log Wages (CEE)" = results$m1_wages,
  "Log Non-Wage (CEE)" = results$m1_nonwage,
  "NW Share (CEE)" = results$m1_share,
  "Log Wages (Sector)" = results$m2_wages,
  "Log Non-Wage (Sector)" = results$m2_nonwage,
  "NW Share (Sector)" = results$m2_share
)

## Extract stats manually for precise formatting
tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\begin{threeparttable}",
  "\\caption{The Statutory Incidence Irrelevance: Difference-in-Differences Estimates}",
  "\\label{tab:did}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Panel A: Aggregate (B--S)} & \\multicolumn{3}{c}{Panel B: Sector-Level} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Log & Log & NW & Log & Log & NW \\\\",
  " & Wages & Non-Wage & Share & Wages & Non-Wage & Share \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\midrule"
)

## Extract coefficients
models_list <- list(results$m1_wages, results$m1_nonwage, results$m1_share,
                    results$m2_wages, results$m2_nonwage, results$m2_share)

betas <- sapply(models_list, function(m) coef(m)[1])
ses <- sapply(models_list, function(m) se(m)[1])
pvals <- sapply(models_list, function(m) pvalue(m)[1])
nobs <- sapply(models_list, function(m) m$nobs)

## Format with stars
stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

## Format coefficient with stars (avoids empty $$ when no stars)
fmt_coef <- function(beta, p, digits = 3) {
  s <- stars_fn(p)
  if (s == "") return(sprintf("%.*f", digits, beta))
  return(sprintf("%.*f$%s$", digits, beta, s))
}

beta_line <- "Romania $\\times$ Post"
se_line <- ""
for (i in 1:6) {
  beta_line <- paste0(beta_line, " & ", fmt_coef(betas[i], pvals[i]))
  se_line <- paste0(se_line, sprintf(" & (%.3f)", ses[i]))
}
beta_line <- paste0(beta_line, " \\\\")
se_line <- paste0(se_line, " \\\\")

## Fixed effects row
fe_row1 <- "Country FE & Yes & Yes & Yes & --- & --- & --- \\\\"
fe_row2 <- "Quarter FE & Yes & Yes & Yes & --- & --- & --- \\\\"
fe_row3 <- "Country $\\times$ Sector FE & --- & --- & --- & Yes & Yes & Yes \\\\"
fe_row4 <- "Quarter FE & --- & --- & --- & Yes & Yes & Yes \\\\"

nobs_line <- "Observations"
for (i in 1:6) {
  nobs_line <- paste0(nobs_line, sprintf(" & %s", format(nobs[i], big.mark = ",")))
}
nobs_line <- paste0(nobs_line, " \\\\")

tab2_lines <- c(tab2_lines,
  beta_line, se_line,
  "\\midrule",
  fe_row1, fe_row2, fe_row3, fe_row4,
  nobs_line,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Difference-in-differences estimates of Romania's January 2018 SSC reform. Romania is treated; Bulgaria, Czechia, Hungary, Poland, and Slovakia are controls. Panel A uses the aggregate business economy (B--S) with country and quarter fixed effects. Panel B uses 25 NACE sectors per country with country$\\times$sector and quarter fixed effects. Standard errors clustered at the country level in parentheses. NW Share = non-wage costs / total compensation. Quarterly Eurostat LCI data, seasonally and calendar adjusted, 2016--2019. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_did.tex")
cat("  Wrote tab2_did.tex\n")

## ══════════════════════════════════════════════════════════════════════
## TABLE 3: Robustness — Placebo & Permutation
## ══════════════════════════════════════════════════════════════════════

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\begin{threeparttable}",
  "\\caption{Robustness: Placebo Tests and Permutation Inference}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Placebo (2017-Q1)} & & \\multicolumn{2}{c}{Permutation} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){5-6}",
  " & Log Wages & Log Non-Wage & & Log Wages & Log Non-Wage \\\\",
  " & (1) & (2) & & (3) & (4) \\\\",
  "\\midrule"
)

## Placebo coefficients
pb_w <- coef(robustness$placebo_wages)[1]
pb_w_se <- se(robustness$placebo_wages)[1]
pb_w_p <- pvalue(robustness$placebo_wages)[1]
pb_n <- coef(robustness$placebo_nonwage)[1]
pb_n_se <- se(robustness$placebo_nonwage)[1]
pb_n_p <- pvalue(robustness$placebo_nonwage)[1]

## Permutation results
perm_pvals <- robustness$perm_pvals
ro_w_beta <- perm_pvals$ro_beta[perm_pvals$outcome == "wages"]
ro_n_beta <- perm_pvals$ro_beta[perm_pvals$outcome == "nonwage"]
pp_w <- perm_pvals$perm_pval[perm_pvals$outcome == "wages"]
pp_n <- perm_pvals$perm_pval[perm_pvals$outcome == "nonwage"]

beta_row <- sprintf("Coefficient & %.3f$%s$ & %.3f$%s$ & & %.3f & %.3f \\\\",
                    pb_w, stars_fn(pb_w_p), pb_n, stars_fn(pb_n_p),
                    ro_w_beta, ro_n_beta)
se_row <- sprintf(" & (%.3f) & (%.3f) & & & \\\\", pb_w_se, pb_n_se)
pval_row <- sprintf("Permutation $p$-value & & & & %.3f & %.3f \\\\", pp_w, pp_n)

tab3_lines <- c(tab3_lines,
  beta_row, se_row,
  "\\midrule",
  pval_row,
  sprintf("Observations & %s & %s & & %s & %s \\\\",
          format(robustness$placebo_wages$nobs, big.mark = ","),
          format(robustness$placebo_nonwage$nobs, big.mark = ","),
          format(results$m1_wages$nobs, big.mark = ","),
          format(results$m1_nonwage$nobs, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Columns (1)--(2): Placebo test assigning false treatment at 2017-Q1 using only pre-reform data (2016-Q1 to 2017-Q4). Small, insignificant coefficients confirm parallel pre-trends. Columns (3)--(4): Permutation inference. The Romania DiD coefficient is compared to the distribution of pseudo-treatment effects obtained by iteratively assigning treatment to each control country. The permutation $p$-value is the fraction of pseudo-effects exceeding Romania's actual effect in absolute value. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("  Wrote tab3_robustness.tex\n")

## ══════════════════════════════════════════════════════════════════════
## TABLE 4: Event Study Coefficients
## ══════════════════════════════════════════════════════════════════════

## Extract event study coefficients
es_w_coefs <- as.data.frame(coeftable(results$es_wages))
es_n_coefs <- as.data.frame(coeftable(results$es_nonwage))
es_s_coefs <- as.data.frame(coeftable(results$es_share))

## Parse event times from row names
parse_event_time <- function(coef_df) {
  rn <- rownames(coef_df)
  ## Format: "event_time::-4:treated_country" → extract the number between :: and :
  times <- as.numeric(str_extract(rn, "(?<=::)-?\\d+"))
  coef_df$event_time <- times
  coef_df
}

es_w_coefs <- parse_event_time(es_w_coefs)
es_n_coefs <- parse_event_time(es_n_coefs)
es_s_coefs <- parse_event_time(es_s_coefs)

## Build table
tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Event Study: Quarter-by-Quarter Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Quarter Relative & Log Wages & Log Non-Wage & NW Share \\\\",
  "to Reform & (1) & (2) & (3) \\\\",
  "\\midrule"
)

## Combine and sort — show t-8 to t+7 window (16 quarters = 4 years around reform)
all_times <- sort(unique(c(es_w_coefs$event_time, es_n_coefs$event_time)))
all_times <- all_times[all_times >= -8 & all_times <= 7 & !is.na(all_times)]
## Ensure t-1 is included as reference
if (!(-1 %in% all_times)) all_times <- sort(c(all_times, -1))

for (et in all_times) {
  w_row <- es_w_coefs[es_w_coefs$event_time == et, ]
  n_row <- es_n_coefs[es_n_coefs$event_time == et, ]
  s_row <- es_s_coefs[es_s_coefs$event_time == et, ]

  w_str <- if (nrow(w_row) > 0) fmt_coef(w_row$Estimate, w_row$`Pr(>|t|)`) else "---"
  n_str <- if (nrow(n_row) > 0) fmt_coef(n_row$Estimate, n_row$`Pr(>|t|)`) else "---"
  s_str <- if (nrow(s_row) > 0) fmt_coef(s_row$Estimate, s_row$`Pr(>|t|)`) else "---"

  w_se <- if (nrow(w_row) > 0) sprintf("(%.3f)", w_row$`Std. Error`) else ""
  n_se <- if (nrow(n_row) > 0) sprintf("(%.3f)", n_row$`Std. Error`) else ""
  s_se <- if (nrow(s_row) > 0) sprintf("(%.3f)", s_row$`Std. Error`) else ""

  label <- ifelse(et >= 0, sprintf("$t+%d$", et), sprintf("$t%d$", et))
  if (et == -1) label <- "$t-1$ (ref.)"

  if (et == -1) {
    tab4_lines <- c(tab4_lines, sprintf("%s & 0 & 0 & 0 \\\\", label))
    tab4_lines <- c(tab4_lines, "\\midrule")
  } else {
    tab4_lines <- c(tab4_lines, sprintf("%s & %s & %s & %s \\\\", label, w_str, n_str, s_str))
    tab4_lines <- c(tab4_lines, sprintf(" & %s & %s & %s \\\\", w_se, n_se, s_se))
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Event study coefficients from a regression of each outcome on Romania $\\times$ event-time indicators, with country and quarter fixed effects. Reference period is $t-1$ (2017-Q4). Pre-reform coefficients (columns 1--3) near zero confirm parallel trends. Post-reform coefficients show the sharp adjustment: wages jump, non-wage costs collapse. Standard errors clustered at country level. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("  Wrote tab4_eventstudy.tex\n")


## ══════════════════════════════════════════════════════════════════════
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY
## ══════════════════════════════════════════════════════════════════════

cat("\n=== Generating SDE Table ===\n")

## Compute SD(Y) from pre-treatment period for each outcome
pre_wages <- core_agg |> filter(post == 0) |> pull(log_wages)
pre_nonwage <- core_agg |> filter(post == 0) |> pull(log_nonwage)
pre_share <- core_agg |> filter(post == 0) |> pull(nonwage_share)

sd_wages <- sd(pre_wages, na.rm = TRUE)
sd_nonwage <- sd(pre_nonwage, na.rm = TRUE)
sd_share <- sd(pre_share, na.rm = TRUE)

## Get coefficients from main models (CEE aggregate)
b_wages <- coef(results$m1_wages)[1]
se_wages <- se(results$m1_wages)[1]
b_nonwage <- coef(results$m1_nonwage)[1]
se_nonwage <- se(results$m1_nonwage)[1]
b_share <- coef(results$m1_share)[1]
se_share <- se(results$m1_share)[1]

## SDE = beta / SD(Y) for binary treatment
sde_wages <- b_wages / sd_wages
sde_se_wages <- se_wages / sd_wages
sde_nonwage <- b_nonwage / sd_nonwage
sde_se_nonwage <- se_nonwage / sd_nonwage
sde_share <- b_share / sd_share
sde_se_share <- se_share / sd_share

## Classification function
classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

## ── Heterogeneity: split by tradeable vs non-tradeable ──────────────
het_sub <- core_sectors |>
  mutate(tradeable = as.integer(sector %in% c("B", "C", "D", "E")))

## Tradeable subset
trade_data <- het_sub |> filter(tradeable == 1)
nontrade_data <- het_sub |> filter(tradeable == 0)

m_trade_nw <- feols(log_nonwage ~ treat_post | country_sector + time,
                    data = trade_data, cluster = ~country)
m_nontrade_nw <- feols(log_nonwage ~ treat_post | country_sector + time,
                       data = nontrade_data, cluster = ~country)

pre_nw_trade <- trade_data |> filter(post == 0) |> pull(log_nonwage)
pre_nw_nontrade <- nontrade_data |> filter(post == 0) |> pull(log_nonwage)

sde_trade <- coef(m_trade_nw)[1] / sd(pre_nw_trade, na.rm = TRUE)
sde_se_trade <- se(m_trade_nw)[1] / sd(pre_nw_trade, na.rm = TRUE)
sde_nontrade <- coef(m_nontrade_nw)[1] / sd(pre_nw_nontrade, na.rm = TRUE)
sde_se_nontrade <- se(m_nontrade_nw)[1] / sd(pre_nw_nontrade, na.rm = TRUE)

## Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Romania and five CEE comparison countries (Bulgaria, Czechia, Hungary, Poland, Slovakia). ",
  "\\textbf{Research question:} Does an overnight shift of employer social security contributions to employees affect the composition of labor costs, and does statutory incidence determine economic incidence? ",
  "\\textbf{Policy mechanism:} Romania's GEO 79/2017 transferred nearly all employer social contributions (from 22.75\\% to 2.25\\%) to employees (from 16.5\\% to 35\\%), accompanied by a mandatory gross wage increase to offset net pay effects---the largest single-day statutory incidence reversal in modern European history. ",
  "\\textbf{Outcome definition:} Eurostat Labour Cost Index components: D11 (wages and salaries), D12\\_D4\\_MD5 (employer social contributions and non-wage costs), and their ratio (non-wage share of total compensation). All indices seasonally and calendar adjusted, base 2020$=$100. ",
  "\\textbf{Treatment:} Binary; Romania treated at 2018-Q1, CEE peers as controls. ",
  "\\textbf{Data:} Eurostat LCI (lc\\_lci\\_r2\\_q), quarterly, 6 countries, aggregate business sector B--S, 2016-Q1 to 2019-Q4 (16 quarters). ",
  "\\textbf{Method:} Two-way fixed effects DiD (country + quarter FE), standard errors clustered at country level. Permutation inference yields $p < 0.05$ for both wage and non-wage outcomes. ",
  "\\textbf{Sample:} Six CEE EU member states with complete LCI data 2016--2019; stopped at 2019-Q4 to avoid COVID contamination. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccp{2.5cm}}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

## Panel A rows
outcomes <- c("Log Wages (D11)", "Log Non-Wage Costs", "Non-Wage Share")
betas_sde <- c(b_wages, b_nonwage, b_share)
ses_sde <- c(se_wages, se_nonwage, se_share)
sds_sde <- c(sd_wages, sd_nonwage, sd_share)
sdes <- c(sde_wages, sde_nonwage, sde_share)
sde_ses <- c(sde_se_wages, sde_se_nonwage, sde_se_share)

for (i in 1:3) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            outcomes[i], betas_sde[i], ses_sde[i], sds_sde[i],
            sdes[i], sde_ses[i], classify_sde(sdes[i])))
}

## Panel B
tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Tradeable vs. Non-Tradeable Sectors)}} \\\\[3pt]",
  sprintf("Log Non-Wage (Tradeable) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_trade_nw)[1], se(m_trade_nw)[1], sd(pre_nw_trade, na.rm = TRUE),
          sde_trade, sde_se_trade, classify_sde(sde_trade)),
  sprintf("Log Non-Wage (Non-Tradeable) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_nontrade_nw)[1], se(m_nontrade_nw)[1], sd(pre_nw_nontrade, na.rm = TRUE),
          sde_nontrade, sde_se_nontrade, classify_sde(sde_nontrade))
)

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{threeparttable}",
  "\\vspace{0.3em}",
  "\\parbox{\\textwidth}{\\footnotesize",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
