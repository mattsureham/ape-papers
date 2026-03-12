## 05_tables.R — Generate all LaTeX tables
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
att_total <- readRDS("../data/att_total.rds")
att_bev <- readRDS("../data/att_by_beverage.rds")
es_total <- readRDS("../data/es_total.rds")
es_bev <- readRDS("../data/es_by_beverage.rds")
twfe_results <- readRDS("../data/twfe_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

pre_panel <- panel[first_treat_year == 0 | year < first_treat_year]
post_panel <- panel[first_treat_year > 0 & year >= first_treat_year]

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Alcohol Consumption (gallons ethanol per capita, age 21+)}} \\\\"
)

for (v in c("total", "beer", "wine", "spirits")) {
  vals <- panel[[v]]
  label <- switch(v, total="Total ethanol", beer="Beer", wine="Wine", spirits="Spirits")
  tab1 <- c(tab1, sprintf("%s & %.3f & %.3f & %.3f & %.3f & %s \\\\",
                          label, mean(vals, na.rm=TRUE), sd(vals, na.rm=TRUE),
                          min(vals, na.rm=TRUE), max(vals, na.rm=TRUE),
                          format(sum(!is.na(vals)), big.mark=",")))
}

tax_vals <- panel$tax_per_pack[!is.na(panel$tax_per_pack)]
tab1 <- c(tab1,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Cigarette Excise Tax}} \\\\",
  sprintf("Tax per pack (\\$) & %.2f & %.2f & %.2f & %.2f & %s \\\\",
          mean(tax_vals), sd(tax_vals), min(tax_vals), max(tax_vals),
          format(length(tax_vals), big.mark=",")),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel C: Treatment Groups}} \\\\",
  sprintf("Treated states & \\multicolumn{4}{c}{%d} & \\\\",
          length(unique(panel[first_treat_year > 0]$state_name))),
  sprintf("Never-treated states & \\multicolumn{4}{c}{%d} & \\\\",
          length(unique(panel[first_treat_year == 0]$state_name))),
  sprintf("Tax increase events ($\\geq$ \\$0.25) & \\multicolumn{4}{c}{%d} & \\\\",
          nrow(readRDS("../data/first_increase.rds"))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Panel of %d states, %s. Alcohol consumption data from NIAAA Surveillance Report \\#122 (per capita gallons of ethanol, population aged 21+). Cigarette excise tax data from CDC Tax Burden on Tobacco. A state is ``treated'' in the year of its first excise tax increase $\\geq$ \\$0.25/pack during 2001--2019. %d states experienced at least one large increase; %d states (Missouri, North Dakota) had no increase $\\geq$ \\$0.25.",
          length(unique(panel$state_name)),
          paste(min(panel$year), max(panel$year), sep="--"),
          length(unique(panel[first_treat_year > 0]$state_name)),
          length(unique(panel[first_treat_year == 0]$state_name))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main Results (CS-DiD)
# =============================================================================
cat("Generating Table 2: Main Results...\n")

get_p <- function(att_obj) 2 * pnorm(-abs(att_obj$overall.att / att_obj$overall.se))

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Cigarette Tax Increases on Alcohol Consumption}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Total & Beer & Wine & Spirits \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna ATT}} \\\\"
)

# CS ATT
for (i in seq_along(c("total", "beer", "wine", "spirits"))) {
  v <- c("total", "beer", "wine", "spirits")[i]
  if (v == "total") {
    att <- att_total
  } else {
    att <- att_bev[[v]]
  }
  p <- get_p(att)
  s <- stars(p)
  if (i == 1) {
    tab2 <- c(tab2, sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\",
      att_total$overall.att, stars(get_p(att_total)),
      att_bev$beer$overall.att, stars(get_p(att_bev$beer)),
      att_bev$wine$overall.att, stars(get_p(att_bev$wine)),
      att_bev$spirits$overall.att, stars(get_p(att_bev$spirits))))
    tab2 <- c(tab2, sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\",
      att_total$overall.se, att_bev$beer$overall.se,
      att_bev$wine$overall.se, att_bev$spirits$overall.se))
    break
  }
}

# TWFE
tab2 <- c(tab2,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Two-Way Fixed Effects}} \\\\"
)
twfe_line1 <- "TWFE"
twfe_line2 <- ""
for (v in c("total", "beer", "wine", "spirits")) {
  b <- coef(twfe_results[[v]])["treated"]
  s <- se(twfe_results[[v]])["treated"]
  p <- pvalue(twfe_results[[v]])["treated"]
  twfe_line1 <- paste0(twfe_line1, sprintf(" & %.4f%s", b, stars(p)))
  twfe_line2 <- paste0(twfe_line2, sprintf(" & (%.4f)", s))
}
tab2 <- c(tab2,
  paste0(twfe_line1, " \\\\"),
  paste0(twfe_line2, " \\\\"),
  "\\midrule",
  {n_st <- length(unique(panel$state_name)); sprintf("States & %d & %d & %d & %d \\\\", n_st, n_st, n_st, n_st)},
  {yr <- paste(min(panel$year), max(panel$year), sep="--"); sprintf("Years & %s & %s & %s & %s \\\\", yr, yr, yr, yr)},
  {nobs <- format(nrow(panel), big.mark=","); sprintf("Observations & %s & %s & %s & %s \\\\", nobs, nobs, nobs, nobs)},
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports Callaway and Sant'Anna (2021) staggered DiD estimates. Treatment is defined as the first state cigarette excise tax increase $\\geq$ \\$0.25/pack during 2001--2019. Control group: not-yet-treated states. Panel B reports standard TWFE with state and year fixed effects for comparison. Dependent variables are per capita gallons of ethanol (age 21+) by beverage type. Standard errors clustered at the state level.",
  " * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Event Study Coefficients
# =============================================================================
cat("Generating Table 3: Event Study...\n")

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event Time & Total & Beer & Wine & Spirits \\\\",
  "\\midrule"
)

# Get event study data for each beverage
for (k in -5:5) {
  total_idx <- which(es_total$egt == k)
  beer_idx <- which(es_bev$beer$egt == k)
  wine_idx <- which(es_bev$wine$egt == k)
  spirits_idx <- which(es_bev$spirits$egt == k)

  total_est <- if(length(total_idx)>0) es_total$att.egt[total_idx] else NA
  beer_est <- if(length(beer_idx)>0) es_bev$beer$att.egt[beer_idx] else NA
  wine_est <- if(length(wine_idx)>0) es_bev$wine$att.egt[wine_idx] else NA
  spirits_est <- if(length(spirits_idx)>0) es_bev$spirits$att.egt[spirits_idx] else NA

  total_se <- if(length(total_idx)>0) es_total$se.egt[total_idx] else NA
  beer_se <- if(length(beer_idx)>0) es_bev$beer$se.egt[beer_idx] else NA
  wine_se <- if(length(wine_idx)>0) es_bev$wine$se.egt[wine_idx] else NA
  spirits_se <- if(length(spirits_idx)>0) es_bev$spirits$se.egt[spirits_idx] else NA

  fmt_est <- function(e, s) {
    if(is.na(e)) return("---")
    p <- 2*pnorm(-abs(e/s))
    sprintf("%.4f%s", e, stars(p))
  }
  fmt_se <- function(s) if(is.na(s)) "---" else sprintf("(%.4f)", s)

  tab3 <- c(tab3,
    sprintf("$k = %d$ & %s & %s & %s & %s \\\\",
            k, fmt_est(total_est, total_se), fmt_est(beer_est, beer_se),
            fmt_est(wine_est, wine_se), fmt_est(spirits_est, spirits_se)),
    sprintf(" & %s & %s & %s & %s \\\\",
            fmt_se(total_se), fmt_se(beer_se), fmt_se(wine_se), fmt_se(spirits_se)))
}

tab3 <- c(tab3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic ATT estimates by event time $k$ (years relative to first large cigarette tax increase). $k < 0$ are pre-treatment periods (test parallel trends). Standard errors in parentheses.",
  " * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_eventstudy.tex")

# =============================================================================
# TABLE 4: Robustness
# =============================================================================
cat("Generating Table 4: Robustness...\n")

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & ATT & SE & States \\\\",
  "\\midrule",
  sprintf("Baseline ($\\geq$ \\$0.25) & %.4f & %.4f & 49 \\\\",
          att_total$overall.att, att_total$overall.se)
)

if (!is.null(robustness$thresh_0.1)) {
  tab4 <- c(tab4, sprintf("Threshold $\\geq$ \\$0.10 & %.4f & %.4f & 49 \\\\",
    robustness$thresh_0.1$overall.att, robustness$thresh_0.1$overall.se))
}
if (!is.null(robustness$thresh_0.5)) {
  tab4 <- c(tab4, sprintf("Threshold $\\geq$ \\$0.50 & %.4f & %.4f & 38 \\\\",
    robustness$thresh_0.5$overall.att, robustness$thresh_0.5$overall.se))
}
if (!is.null(robustness$thresh_1)) {
  tab4 <- c(tab4, sprintf("Threshold $\\geq$ \\$1.00 & %.4f & %.4f & 20 \\\\",
    robustness$thresh_1$overall.att, robustness$thresh_1$overall.se))
}
if (!is.null(robustness$excl_big)) {
  tab4 <- c(tab4, sprintf("Excl.\\ CA, NY, IL & %.4f & %.4f & 46 \\\\",
    robustness$excl_big$overall.att, robustness$excl_big$overall.se))
}
if (!is.null(robustness$short_window)) {
  tab4 <- c(tab4, sprintf("2001--2019 only & %.4f & %.4f & 51 \\\\",
    robustness$short_window$overall.att, robustness$short_window$overall.se))
}

tab4 <- c(tab4,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use Callaway and Sant'Anna (2021) with not-yet-treated controls. Dependent variable: total per capita ethanol consumption (gallons, age 21+). Baseline defines treatment as first increase $\\geq$ \\$0.25/pack. Alternative rows vary the threshold or sample.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robust.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes
# =============================================================================
cat("Generating Table F1: SDE...\n")

sd_y_total <- sd(panel$total, na.rm=TRUE)
sd_y_beer <- sd(panel$beer, na.rm=TRUE)
sd_y_wine <- sd(panel$wine, na.rm=TRUE)
sd_y_spirits <- sd(panel$spirits, na.rm=TRUE)

# Binary treatment → SDE = beta / SD(Y)
sde_data <- data.frame(
  Outcome = c("Total ethanol", "Beer", "Wine", "Spirits"),
  beta = c(att_total$overall.att, att_bev$beer$overall.att,
           att_bev$wine$overall.att, att_bev$spirits$overall.att),
  se = c(att_total$overall.se, att_bev$beer$overall.se,
         att_bev$wine$overall.se, att_bev$spirits$overall.se),
  sd_y = c(sd_y_total, sd_y_beer, sd_y_wine, sd_y_spirits)
)
sde_data$sde <- sde_data$beta / sde_data$sd_y
sde_data$se_sde <- sde_data$se / sde_data$sd_y

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
sde_data$class <- classify(sde_data$sde)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_data)) {
  r <- sde_data[i, ]
  tabF1 <- c(tabF1,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

tabF1 <- c(tabF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Standardized effect sizes (SDE $= \\hat{\\beta}/\\text{SD}(Y)$) for binary treatment. SD($Y$) is the unconditional standard deviation of per capita ethanol consumption (gallons, age 21+)."),
  "",
  sprintf("\\textbf{Research question:} Do state cigarette excise tax increases cause cross-substance spillovers to alcohol consumption? \\textbf{Treatment:} Binary --- first state cigarette tax increase $\\geq$ \\$0.25/pack, 2001--2019. \\textbf{Data:} NIAAA Surveillance Report \\#122 and CDC Tax Burden on Tobacco, %d states, %s. \\textbf{Method:} Callaway--Sant'Anna staggered DiD, not-yet-treated controls, state-clustered inference. \\textbf{Sample:} %s state-year observations.",
          length(unique(panel$state_name)),
          paste(min(panel$year), max(panel$year), sep="--"),
          format(nrow(panel), big.mark=",")),
  "",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
