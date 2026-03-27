## 05_tables.R — Generate all tables for paper
## apep_1054: Mexico DST Abolition and Crime

source("00_packages.R")

cat("=== Loading Results ===\n")
df <- fread("../data/analysis_panel.csv")
df[, date := as.Date(date)]
main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

## ---------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------
cat("\n=== Table 1: Summary Statistics ===\n")

pre <- df[post == 0]

## Summary by border status
make_summ <- function(dt, label) {
  data.table(
    Group = label,
    N_munis = uniqueN(dt$muni_id),
    N_obs = nrow(dt),
    Mean_total = round(mean(dt$total_crime), 2),
    SD_total = round(sd(dt$total_crime), 2),
    Mean_street = round(mean(dt$street_crime), 2),
    SD_street = round(sd(dt$street_crime), 2),
    Mean_property = round(mean(dt$property_crime), 2),
    SD_property = round(sd(dt$property_crime), 2),
    Mean_violent = round(mean(dt$violent_crime), 2),
    SD_violent = round(sd(dt$violent_crime), 2),
    Mean_whitecollar = round(mean(dt$whitecollar_crime), 2),
    SD_whitecollar = round(sd(dt$whitecollar_crime), 2)
  )
}

summ_border <- make_summ(pre[border == 1], "Border (Control)")
summ_nonborder <- make_summ(pre[border == 0], "Non-Border (Treated)")
summ_all <- make_summ(pre, "All Municipalities")

summ <- rbind(summ_border, summ_nonborder, summ_all)

## Generate LaTeX table
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics (2015--2022)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Border & Non-Border & Difference \\\\",
  " & (Control) & (Treated) & \\\\",
  "\\midrule",
  sprintf("Municipalities & %d & %d & \\\\",
          summ$N_munis[1], summ$N_munis[2]),
  sprintf("Municipality-months & %s & %s & \\\\",
          format(summ$N_obs[1], big.mark = ","), format(summ$N_obs[2], big.mark = ",")),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Monthly crime counts (means)}} \\\\[3pt]",
  sprintf("Total crime & %.1f & %.1f & %.1f \\\\",
          summ$Mean_total[1], summ$Mean_total[2],
          summ$Mean_total[2] - summ$Mean_total[1]),
  sprintf(" & (%.1f) & (%.1f) & \\\\",
          summ$SD_total[1], summ$SD_total[2]),
  sprintf("Street crime & %.1f & %.1f & %.1f \\\\",
          summ$Mean_street[1], summ$Mean_street[2],
          summ$Mean_street[2] - summ$Mean_street[1]),
  sprintf(" & (%.1f) & (%.1f) & \\\\",
          summ$SD_street[1], summ$SD_street[2]),
  sprintf("Property crime & %.1f & %.1f & %.1f \\\\",
          summ$Mean_property[1], summ$Mean_property[2],
          summ$Mean_property[2] - summ$Mean_property[1]),
  sprintf(" & (%.1f) & (%.1f) & \\\\",
          summ$SD_property[1], summ$SD_property[2]),
  sprintf("Violent crime & %.1f & %.1f & %.1f \\\\",
          summ$Mean_violent[1], summ$Mean_violent[2],
          summ$Mean_violent[2] - summ$Mean_violent[1]),
  sprintf(" & (%.1f) & (%.1f) & \\\\",
          summ$SD_violent[1], summ$SD_violent[2]),
  sprintf("White-collar crime & %.1f & %.1f & %.1f \\\\",
          summ$Mean_whitecollar[1], summ$Mean_whitecollar[2],
          summ$Mean_whitecollar[2] - summ$Mean_whitecollar[1]),
  sprintf(" & (%.1f) & (%.1f) & \\\\",
          summ$SD_whitecollar[1], summ$SD_whitecollar[2]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Pre-treatment period: January 2015--October 2022. Border municipalities are the 33 northern border municipalities exempted from Mexico's October 2022 DST abolition. Non-border municipalities are all other municipalities in the same five states (Chihuahua, Coahuila, Nuevo Le\\'on, Sonora, Tamaulipas). Standard deviations in parentheses. Street crime includes robbery (\\textit{robo}) and assault (\\textit{lesiones}). White-collar crime includes fraud (\\textit{fraude}) and extortion (\\textit{extorsi\\'on}).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

## ---------------------------------------------------------------
## Table 2: Main DiD Results (Crime Type Decomposition)
## ---------------------------------------------------------------
cat("\n=== Table 2: Main Results ===\n")

## Extract coefficients and SEs
get_row <- function(model, label, coef_name = "treat_post_dst") {
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- pvalue(model)[coef_name]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(label = label, b = b, s = s, p = p, n = n, stars = stars)
}

r_total <- get_row(main$m1_total, "Total crime")
r_street <- get_row(main$m1_street, "Street crime")
r_property <- get_row(main$m1_property, "Property crime")
r_violent <- get_row(main$m1_violent, "Violent crime")
r_wc <- get_row(main$m1_wc, "White-collar crime")

## Means for context
pre_means <- df[post == 0 & treated == 0, .(
  total = mean(total_crime),
  street = mean(street_crime),
  property = mean(property_crime),
  violent = mean(violent_crime),
  whitecollar = mean(whitecollar_crime)
)]

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of DST Abolition on Crime by Type}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Total & Street & Property & Violent & White-Collar \\\\",
  " & Crime & Crime & Crime & Crime & Crime \\\\",
  "\\midrule",
  sprintf("Non-Border $\\times$ Post $\\times$ DST & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          format(round(r_total$b, 4), nsmall = 4), r_total$stars,
          format(round(r_street$b, 4), nsmall = 4), r_street$stars,
          format(round(r_property$b, 4), nsmall = 4), r_property$stars,
          format(round(r_violent$b, 4), nsmall = 4), r_violent$stars,
          format(round(r_wc$b, 4), nsmall = 4), r_wc$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          format(round(r_total$s, 4), nsmall = 4),
          format(round(r_street$s, 4), nsmall = 4),
          format(round(r_property$s, 4), nsmall = 4),
          format(round(r_violent$s, 4), nsmall = 4),
          format(round(r_wc$s, 4), nsmall = 4)),
  "\\midrule",
  sprintf("Control mean & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          pre_means$total, pre_means$street, pre_means$property,
          pre_means$violent, pre_means$whitecollar),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(r_total$n, big.mark = ","),
          format(r_street$n, big.mark = ","),
          format(r_property$n, big.mark = ","),
          format(r_violent$n, big.mark = ","),
          format(r_wc$n, big.mark = ",")),
  sprintf("Municipalities & %d & %d & %d & %d & %d \\\\",
          uniqueN(df$muni_id), uniqueN(df$muni_id), uniqueN(df$muni_id),
          uniqueN(df$muni_id), uniqueN(df$muni_id)),
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Year-Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is IHS(crime count). The reported coefficient is the triple-interaction: Non-Border $\\times$ Post-Reform $\\times$ DST-Active Month, which isolates the effect during months when the one-hour sunset difference exists (March--October). Sample restricted to four states with within-state treatment variation: Chihuahua, Coahuila, Nuevo Le\\'on, Tamaulipas. Standard errors clustered at municipality level in parentheses. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

## ---------------------------------------------------------------
## Table 3: DST-Active vs Non-Active Months (Temporal Placebo)
## ---------------------------------------------------------------
cat("\n=== Table 3: Temporal Placebo ===\n")

r_dst <- get_row(main$m2_dst, "DST months", coef_name = "treat_post")
r_nodst <- get_row(main$m2_nodst, "Non-DST months", coef_name = "treat_post")

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Temporal Placebo: DST-Active vs.\\ Non-Active Months}",
  "\\label{tab:temporal}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & DST Months & Non-DST Months \\\\",
  " & (Mar--Oct) & (Nov--Feb) \\\\",
  "\\midrule",
  sprintf("Non-Border $\\times$ Post & %s%s & %s%s \\\\",
          format(round(r_dst$b, 4), nsmall = 4), r_dst$stars,
          format(round(r_nodst$b, 4), nsmall = 4), r_nodst$stars),
  sprintf(" & (%s) & (%s) \\\\",
          format(round(r_dst$s, 4), nsmall = 4),
          format(round(r_nodst$s, 4), nsmall = 4)),
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
          format(r_dst$n, big.mark = ","),
          format(r_nodst$n, big.mark = ",")),
  "Municipality FE & Yes & Yes \\\\",
  "State $\\times$ Year-Month FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is IHS(street crime). DST-active months (March--October) are when DST would normally shift clocks forward, creating a one-hour sunset difference between border and non-border municipalities post-reform. Non-DST months (November--February) serve as a temporal placebo: all municipalities are on standard time regardless, so no treatment contrast exists. Standard errors clustered at municipality level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(tab_dir, "tab3_temporal.tex"))
cat("Table 3 written.\n")

## ---------------------------------------------------------------
## Table 4: Robustness Checks
## ---------------------------------------------------------------
cat("\n=== Table 4: Robustness ===\n")

r_base <- get_row(main$m1_street_simple, "Baseline", coef_name = "treat_post")
r_log <- get_row(robust$m_log, "Log(Y+1)", coef_name = "treat_post")
r_levels <- get_row(robust$m_levels, "Levels", coef_name = "treat_post")
r_urban <- get_row(robust$m_urban, "Urban only", coef_name = "treat_post")
r_rural <- get_row(robust$m_rural, "Rural only", coef_name = "treat_post")
r_nolarge <- get_row(robust$m_nolarge, "Excl. large border", coef_name = "treat_post")

## Pre-trend
b_pt <- coef(robust$m_pretrend)
s_pt <- se(robust$m_pretrend)
p_pt <- pvalue(robust$m_pretrend)
stars_pt <- ifelse(p_pt < 0.01, "***", ifelse(p_pt < 0.05, "**", ifelse(p_pt < 0.1, "*", "")))

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Street Crime}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Estimate & SE & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative outcome transformations}} \\\\[3pt]",
  sprintf("IHS (baseline) & %s%s & (%s) & %s \\\\",
          format(round(r_base$b, 4), nsmall = 4), r_base$stars,
          format(round(r_base$s, 4), nsmall = 4),
          format(r_base$n, big.mark = ",")),
  sprintf("Log(crime + 1) & %s%s & (%s) & %s \\\\",
          format(round(r_log$b, 4), nsmall = 4), r_log$stars,
          format(round(r_log$s, 4), nsmall = 4),
          format(r_log$n, big.mark = ",")),
  sprintf("Crime count (levels) & %s%s & (%s) & %s \\\\",
          format(round(r_levels$b, 4), nsmall = 4), r_levels$stars,
          format(round(r_levels$s, 4), nsmall = 4),
          format(r_levels$n, big.mark = ",")),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sample restrictions}} \\\\[3pt]",
  sprintf("Urban municipalities & %s%s & (%s) & %s \\\\",
          format(round(r_urban$b, 4), nsmall = 4), r_urban$stars,
          format(round(r_urban$s, 4), nsmall = 4),
          format(r_urban$n, big.mark = ",")),
  sprintf("Rural municipalities & %s%s & (%s) & %s \\\\",
          format(round(r_rural$b, 4), nsmall = 4), r_rural$stars,
          format(round(r_rural$s, 4), nsmall = 4),
          format(r_rural$n, big.mark = ",")),
  sprintf("Excl.\\ large border cities & %s%s & (%s) & %s \\\\",
          format(round(r_nolarge$b, 4), nsmall = 4), r_nolarge$stars,
          format(round(r_nolarge$s, 4), nsmall = 4),
          format(r_nolarge$n, big.mark = ",")),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Pre-treatment parallel trends}} \\\\[3pt]",
  sprintf("Differential linear trend & %s%s & (%s) & %s \\\\",
          format(round(b_pt, 4), nsmall = 4), stars_pt,
          format(round(s_pt, 4), nsmall = 4),
          format(nrow(df[post == 0]), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} All specifications include municipality and state $\\times$ year-month fixed effects with simple DiD (Non-Border $\\times$ Post). Panel A varies the dependent variable transformation for street crime. Panel B restricts the sample. Urban/rural split at median pre-treatment crime. ``Large border cities'' are Ciudad Ju\\'arez, Reynosa, Matamoros, and Nuevo Laredo. Panel C tests for differential pre-treatment trends between border and non-border municipalities. Standard errors clustered at municipality level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(tab_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

## ---------------------------------------------------------------
## Table F1: Standardized Effect Size (SDE) — MANDATORY
## ---------------------------------------------------------------
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDE for main outcomes
## SDE = β̂ / SD(Y) where SD(Y) is pre-treatment SD

pre_sd <- df[post == 0 & treated == 1, .(
  sd_total = sd(ihs_total),
  sd_street = sd(ihs_street),
  sd_property = sd(ihs_property),
  sd_violent = sd(ihs_violent),
  sd_whitecollar = sd(ihs_whitecollar)
)]

## Main outcomes — use triple-diff coefficient (treat_post_dst)
sde_rows <- data.table(
  outcome = c("Street crime", "Property crime",
              "Violent crime", "White-collar crime"),
  beta = c(coef(main$m1_street)["treat_post_dst"], coef(main$m1_property)["treat_post_dst"],
           coef(main$m1_violent)["treat_post_dst"], coef(main$m1_wc)["treat_post_dst"]),
  se_beta = c(se(main$m1_street)["treat_post_dst"], se(main$m1_property)["treat_post_dst"],
              se(main$m1_violent)["treat_post_dst"], se(main$m1_wc)["treat_post_dst"]),
  sd_y = c(pre_sd$sd_street, pre_sd$sd_property,
           pre_sd$sd_violent, pre_sd$sd_whitecollar)
)

sde_rows[, sde := beta / sd_y]
sde_rows[, se_sde := se_beta / sd_y]

## Classification
classify_sde <- function(x) {
  ifelse(x < -0.15, "Large negative",
  ifelse(x < -0.05, "Moderate negative",
  ifelse(x < -0.005, "Small negative",
  ifelse(x < 0.005, "Null",
  ifelse(x < 0.05, "Small positive",
  ifelse(x < 0.15, "Moderate positive",
         "Large positive"))))))
}

sde_rows[, classification := classify_sde(sde)]

cat("SDE Results:\n")
print(sde_rows)

## Heterogeneous panel: Urban vs Rural for street crime
sde_urban <- coef(robust$m_urban) / pre_sd$sd_street
sde_rural <- coef(robust$m_rural) / pre_sd$sd_street
se_sde_urban <- se(robust$m_urban) / pre_sd$sd_street
se_sde_rural <- se(robust$m_rural) / pre_sd$sd_street

## Generate SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Mexico. ",
  "\\textbf{Research question:} Does abolishing daylight saving time increase crime through earlier evening darkness in affected municipalities? ",
  "\\textbf{Policy mechanism:} Mexico's October 2022 reform abolished DST nationwide except for 33 northern border municipalities that retained it for US economic integration, shifting sunsets one hour earlier during March--October in non-exempt municipalities. ",
  "\\textbf{Outcome definition:} Monthly municipality-level crime counts from SESNSP, transformed by inverse hyperbolic sine; street crime aggregates robbery (\\textit{robo}) and assault (\\textit{lesiones}). ",
  "\\textbf{Treatment:} Binary indicator for non-border municipalities that lost DST after October 2022. ",
  "\\textbf{Data:} SESNSP municipality-month crime panel, 2015--2025, four northern border states with within-state treatment variation. ",
  "\\textbf{Method:} Difference-in-differences with municipality and state $\\times$ year-month fixed effects; standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Municipalities in Chihuahua, Coahuila, Nuevo Le\\'on, and Tamaulipas with at least 80\\% of months observed. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the IHS-transformed outcome among treated municipalities. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_tex <- c(tabF1_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_rows$outcome[i],
    format(round(sde_rows$beta[i], 4), nsmall = 4),
    format(round(sde_rows$se_beta[i], 4), nsmall = 4),
    format(round(sde_rows$sd_y[i], 3), nsmall = 3),
    format(round(sde_rows$sde[i], 4), nsmall = 4),
    format(round(sde_rows$se_sde[i], 4), nsmall = 4),
    sde_rows$classification[i]
  ))
}

tabF1_tex <- c(tabF1_tex,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Street Crime)}} \\\\[3pt]",
  sprintf("Urban municipalities & %s & %s & %s & %s & %s & %s \\\\",
          format(round(coef(robust$m_urban), 4), nsmall = 4),
          format(round(se(robust$m_urban), 4), nsmall = 4),
          format(round(pre_sd$sd_street, 3), nsmall = 3),
          format(round(sde_urban, 4), nsmall = 4),
          format(round(se_sde_urban, 4), nsmall = 4),
          classify_sde(sde_urban)),
  sprintf("Rural municipalities & %s & %s & %s & %s & %s & %s \\\\",
          format(round(coef(robust$m_rural), 4), nsmall = 4),
          format(round(se(robust$m_rural), 4), nsmall = 4),
          format(round(pre_sd$sd_street, 3), nsmall = 3),
          format(round(sde_rural, 4), nsmall = 4),
          format(round(se_sde_rural, 4), nsmall = 4),
          classify_sde(sde_rural)),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}[flushleft]\\small"),
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, file.path(tab_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All Tables Complete ===\n")
