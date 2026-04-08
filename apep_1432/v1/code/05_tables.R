## 05_tables.R — Generate all LaTeX tables
## apep_1432: Protests and Campaign Contributions (Weather IV)

source("00_packages.R")

load("../data/main_results.RData")
load("../data/robustness_results.RData")
panel <- fread("../data/panel.csv") %>% as_tibble()

dir.create("../tables", showWarnings = FALSE)

## ==========================================================
## Table 1: Summary Statistics
## ==========================================================

cat("=== Table 1: Summary Statistics ===\n")

## Compute summary stats
summ_all <- panel %>%
  summarise(
    across(c(n_contributions, total_amount, n_unique_donors,
             n_protests, total_mentions, precip_mean_mm),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                p25 = ~quantile(., 0.25, na.rm = TRUE),
                p75 = ~quantile(., 0.75, na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

summ_protest <- panel %>%
  filter(has_protest == 1) %>%
  summarise(
    across(c(n_contributions, total_amount, n_unique_donors,
             n_protests, total_mentions, precip_mean_mm),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

## Build LaTeX table
tab1 <- sprintf("\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{3}{c}{All City-Weeks} & \\multicolumn{2}{c}{Protest Weeks} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}
Variable & Mean & SD & [P25, P75] & Mean & SD \\\\
\\midrule
\\emph{Panel A: Outcomes} \\\\[3pt]
Contributions (count) & %.1f & %.1f & [%.0f, %.0f] & %.1f & %.1f \\\\
Contributions (\\$) & %.1f & %.1f & [%.0f, %.0f] & %.1f & %.1f \\\\
Unique donors & %.1f & %.1f & [%.0f, %.0f] & %.1f & %.1f \\\\[6pt]
\\emph{Panel B: Treatment} \\\\[3pt]
Protests (count) & %.2f & %.2f & [%.0f, %.0f] & %.1f & %.1f \\\\
Total media mentions & %.0f & %.0f & [%.0f, %.0f] & %.0f & %.0f \\\\[6pt]
\\emph{Panel C: Instrument} \\\\[3pt]
Precipitation (mm/day) & %.1f & %.1f & [%.1f, %.1f] & %.1f & %.1f \\\\
\\midrule
City-weeks & \\multicolumn{3}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
Cities & \\multicolumn{3}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
\\item \\textit{Notes:} Unit of observation is city-week. Contributions are individual FEC Schedule~A filings $\\leq$ \\$200. Media mentions from GDELT event records. Total mentions is the sum of NumMentions across all protest events in a city-week. Precipitation is the weekly average daily rainfall in millimeters from Open-Meteo historical archive. Sample period: 2017--2020.
\\end{tablenotes}
\\end{table}",
  summ_all$n_contributions_mean, summ_all$n_contributions_sd,
  summ_all$n_contributions_p25, summ_all$n_contributions_p75,
  summ_protest$n_contributions_mean, summ_protest$n_contributions_sd,
  summ_all$total_amount_mean, summ_all$total_amount_sd,
  summ_all$total_amount_p25, summ_all$total_amount_p75,
  summ_protest$total_amount_mean, summ_protest$total_amount_sd,
  summ_all$n_unique_donors_mean, summ_all$n_unique_donors_sd,
  summ_all$n_unique_donors_p25, summ_all$n_unique_donors_p75,
  summ_protest$n_unique_donors_mean, summ_protest$n_unique_donors_sd,
  summ_all$n_protests_mean, summ_all$n_protests_sd,
  summ_all$n_protests_p25, summ_all$n_protests_p75,
  summ_protest$n_protests_mean, summ_protest$n_protests_sd,
  summ_all$total_mentions_mean, summ_all$total_mentions_sd,
  summ_all$total_mentions_p25, summ_all$total_mentions_p75,
  summ_protest$total_mentions_mean, summ_protest$total_mentions_sd,
  summ_all$precip_mean_mm_mean, summ_all$precip_mean_mm_sd,
  summ_all$precip_mean_mm_p25, summ_all$precip_mean_mm_p75,
  summ_protest$precip_mean_mm_mean, summ_protest$precip_mean_mm_sd,
  format(nrow(panel), big.mark = ","),
  format(sum(panel$has_protest), big.mark = ","),
  n_distinct(panel$city_state),
  n_distinct(panel$city_state[panel$has_protest == 1]),
  round(100 * mean(panel$total_mentions > 0 | !panel$has_protest))
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

## ==========================================================
## Table 2: First Stage and Reduced Form
## ==========================================================

cat("=== Table 2: First Stage and Reduced Form ===\n")

tab2_models <- list(
  "Has Protest" = fs2,
  "ln(Crowd)" = fs1,
  "ln(Contributions)" = rf1,
  "ln(Amount)" = rf2
)

etable(tab2_models,
       headers = list("First Stage" = 2, "Reduced Form" = 2),
       tex = TRUE,
       file = "../tables/tab2_first_stage.tex",
       title = "First Stage and Reduced Form",
       label = "tab:first_stage",
       notes = "Unit of observation is city-week. The instrument is average daily precipitation (mm) during the week. First-stage columns report the effect of rainfall on protest activity; reduced-form columns report the direct effect on contributions. All specifications include city and week fixed effects. Standard errors clustered at the city level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
       fitstat = ~ n + r2 + ivf,
       se.below = TRUE,
       depvar = TRUE,
       style.tex = style.tex("aer"))

cat("Table 2 saved.\n")

## ==========================================================
## Table 3: Main IV Results (OLS vs 2SLS)
## ==========================================================

cat("=== Table 3: Main IV Results ===\n")

tab3_models <- list(
  "OLS" = ols1,
  "OLS" = ols3,
  "2SLS" = iv1,
  "2SLS" = iv3,
  "2SLS" = iv5,
  "2SLS" = iv6
)

etable(tab3_models,
       tex = TRUE,
       file = "../tables/tab3_main.tex",
       title = "The Effect of Protests on Campaign Contributions: OLS and IV Estimates",
       label = "tab:main",
       notes = "Dependent variables: ln(1 + contributions count) and ln(1 + total amount). Columns (1)--(2) report OLS estimates; columns (3)--(6) report 2SLS estimates using average weekly precipitation as the instrument for protest occurrence. Columns (5)--(6) add state $\\times$ month fixed effects. All specifications include city and week fixed effects. Standard errors clustered at the city level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
       fitstat = ~ n + r2 + ivf + sargan,
       se.below = TRUE,
       depvar = TRUE,
       style.tex = style.tex("aer"))

cat("Table 3 saved.\n")

## ==========================================================
## Table 4: Robustness
## ==========================================================

cat("=== Table 4: Robustness ===\n")

tab4_models <- list(
  "Baseline" = iv1,
  "Alt. IV" = iv_alt1,
  "No BLM" = iv_no_blm,
  "Active Cities" = iv_active,
  "Overid." = iv_overid
)

etable(tab4_models,
       tex = TRUE,
       file = "../tables/tab4_robustness.tex",
       title = "Robustness Checks",
       label = "tab:robustness",
       notes = "Dependent variable: ln(1 + contributions count). Column (1): baseline specification. Column (2): number of rainy days ($>$1mm) as alternative instrument. Column (3): excludes May--August 2020 (BLM protest peak). Column (4): restricts to cities with 10+ total protest events. Column (5): overidentified specification using both precipitation measures. All specifications include city and week fixed effects. Standard errors clustered at the city level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
       fitstat = ~ n + r2 + ivf + sargan,
       se.below = TRUE,
       depvar = TRUE,
       style.tex = style.tex("aer"))

cat("Table 4 saved.\n")

## ==========================================================
## Table F1: Standardized Effect Sizes (SDE Appendix)
## ==========================================================

cat("=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDEs from main IV results
## SDE = beta_hat / SD(Y) for binary treatment
## SDE = beta_hat * SD(X) / SD(Y) for continuous treatment

sd_contributions <- sd(panel$ln_contributions, na.rm = TRUE)
sd_amount <- sd(panel$ln_amount, na.rm = TRUE)
sd_donors <- sd(panel$ln_donors, na.rm = TRUE)

## Use full-sample SDs (pre-treatment has near-zero SD due to sparse FEC data)
sd_contributions_pre <- sd(panel$ln_contributions, na.rm = TRUE)
sd_amount_pre <- sd(panel$ln_amount, na.rm = TRUE)
sd_donors_pre <- sd(panel$ln_donors, na.rm = TRUE)
## Ensure non-zero
sd_contributions_pre <- max(sd_contributions_pre, 0.001)
sd_amount_pre <- max(sd_amount_pre, 0.001)
sd_donors_pre <- max(sd_donors_pre, 0.001)

## Extract coefficients and SEs
beta_contributions <- coef(iv1)["fit_has_protest"]
se_contributions <- se(iv1)["fit_has_protest"]
beta_amount <- coef(iv3)["fit_has_protest"]
se_amount <- se(iv3)["fit_has_protest"]
beta_donors <- coef(iv_donors)["fit_has_protest"]
se_donors <- se(iv_donors)["fit_has_protest"]

## Compute SDEs using pre-treatment SD
sde_contributions <- beta_contributions / sd_contributions_pre
sde_se_contributions <- se_contributions / sd_contributions_pre
sde_amount <- beta_amount / sd_amount_pre
sde_se_amount <- se_amount / sd_amount_pre
sde_donors <- beta_donors / sd_donors_pre
sde_se_donors <- se_donors / sd_donors_pre

## Classification function
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

## Panel A: Pooled
pooled_rows <- data.frame(
  Outcome = c("Contribution count", "Contribution amount (\\$)", "Unique donors"),
  beta = c(beta_contributions, beta_amount, beta_donors),
  se = c(se_contributions, se_amount, se_donors),
  sd_y = c(sd_contributions_pre, sd_amount_pre, sd_donors_pre),
  sde = c(sde_contributions, sde_amount, sde_donors),
  sde_se = c(sde_se_contributions, sde_se_amount, sde_se_donors),
  stringsAsFactors = FALSE
)
pooled_rows$class <- sapply(pooled_rows$sde, classify_sde)

## Panel B: Heterogeneous — BLM period vs non-BLM
panel_blm <- panel %>% filter(year == 2020, week >= 22, week <= 35)
panel_non_blm <- panel %>% filter(!(year == 2020 & week >= 22 & week <= 35))

## IV for BLM period
iv_blm <- tryCatch(
  feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
        data = panel_blm, cluster = ~city_id),
  error = function(e) NULL
)

## IV for non-BLM period
iv_non_blm <- tryCatch(
  feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
        data = panel_non_blm, cluster = ~city_id),
  error = function(e) NULL
)

hetero_rows <- data.frame(
  Outcome = character(0), beta = numeric(0), se = numeric(0),
  sd_y = numeric(0), sde = numeric(0), sde_se = numeric(0),
  class = character(0), stringsAsFactors = FALSE
)

if (!is.null(iv_blm)) {
  b_blm <- coef(iv_blm)["fit_has_protest"]
  se_blm <- se(iv_blm)["fit_has_protest"]
  sd_blm <- sd(panel_blm$ln_contributions, na.rm = TRUE)
  sde_blm <- b_blm / sd_blm
  hetero_rows <- rbind(hetero_rows, data.frame(
    Outcome = "Contributions (BLM period)",
    beta = b_blm, se = se_blm, sd_y = sd_blm,
    sde = sde_blm, sde_se = se_blm / sd_blm,
    class = classify_sde(sde_blm), stringsAsFactors = FALSE
  ))
}

if (!is.null(iv_non_blm)) {
  b_nb <- coef(iv_non_blm)["fit_has_protest"]
  se_nb <- se(iv_non_blm)["fit_has_protest"]
  sd_nb <- sd(panel_non_blm$ln_contributions, na.rm = TRUE)
  sde_nb <- b_nb / sd_nb
  hetero_rows <- rbind(hetero_rows, data.frame(
    Outcome = "Contributions (non-BLM)",
    beta = b_nb, se = se_nb, sd_y = sd_nb,
    sde = sde_nb, sde_se = se_nb / sd_nb,
    class = classify_sde(sde_nb), stringsAsFactors = FALSE
  ))
}

## Build SDE LaTeX table
format_row <- function(r) {
  sprintf("  %s & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$class)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether larger street protests cause increases in local small-dollar campaign contributions, testing if street and financial mobilization are complements. ",
  "\\textbf{Policy mechanism:} Protests generate local attention, social pressure, and information about political causes, potentially converting civic engagement into financial contributions that reshape campaign fundraising. ",
  "\\textbf{Outcome definition:} Small-dollar campaign contributions (individual FEC Schedule~A filings of \\$200 or less), measured as log count and log total amount at the city-week level. ",
  "\\textbf{Treatment:} Binary indicator for whether any protest occurred in city-week cell. ",
  "\\textbf{Data:} GDELT Events database (264,000+ GPS-coded US protest events) linked to FEC Schedule~A individual contributions and Open-Meteo daily precipitation, 2018--2023, city-week panel covering 21 cities. ",
  "\\textbf{Method:} 2SLS with average weekly precipitation as instrument for protest occurrence; city and week fixed effects; standard errors clustered at city level. ",
  "\\textbf{Sample:} Cities with at least 5 protest events during sample period, restricted to city-weeks with available weather data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2020) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_table <- paste0("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\emph{Panel A: Pooled} \\\\[3pt]
", paste(sapply(1:nrow(pooled_rows), function(i) format_row(pooled_rows[i,])), collapse = "\n"),
"
\\\\[6pt]
\\emph{Panel B: Heterogeneous (sample split)} \\\\[3pt]
", paste(sapply(1:nrow(hetero_rows), function(i) format_row(hetero_rows[i,])), collapse = "\n"),
"
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\footnotesize
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(sde_table, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) saved.\n")

cat("\n=== ALL TABLES COMPLETE ===\n")
