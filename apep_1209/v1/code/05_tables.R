## 05_tables.R — Generate all tables for paper
## apep_1209: Cannabis dispensary lotteries and property values

source("00_packages.R")

cat("=== Loading results ===\n")
sales <- readRDS("../data/sales_clean.rds")
disp <- readRDS("../data/dispensary_clean.rds")
models <- readRDS("../data/main_models.rds")
robust <- readRDS("../data/robustness_results.rds")
summ <- readRDS("../data/summary_stats.rds")

## ---------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------
cat("\n=== Table 1: Summary Statistics ===\n")

# Split by near/far
near_stats <- sales[near_050 == 1, .(
  N = .N,
  mean_price = mean(sale_price, na.rm=T),
  sd_price = sd(sale_price, na.rm=T),
  mean_log_price = mean(log_price, na.rm=T),
  sd_log_price = sd(log_price, na.rm=T),
  mean_dist = mean(dist_nearest, na.rm=T),
  pct_post = mean(post_open, na.rm=T) * 100
)]

far_stats <- sales[near_050 == 0, .(
  N = .N,
  mean_price = mean(sale_price, na.rm=T),
  sd_price = sd(sale_price, na.rm=T),
  mean_log_price = mean(log_price, na.rm=T),
  sd_log_price = sd(log_price, na.rm=T),
  mean_dist = mean(dist_nearest, na.rm=T),
  pct_post = mean(post_open, na.rm=T) * 100
)]

all_stats <- sales[, .(
  N = .N,
  mean_price = mean(sale_price, na.rm=T),
  sd_price = sd(sale_price, na.rm=T),
  mean_log_price = mean(log_price, na.rm=T),
  sd_log_price = sd(log_price, na.rm=T),
  mean_dist = mean(dist_nearest, na.rm=T),
  pct_post = mean(post_open, na.rm=T) * 100
)]

tab1_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lSSS}
\\toprule
 & {Within 0.5mi} & {Beyond 0.5mi} & {All Sales} \\\\
\\midrule
Sale price (\\$) & ", format(round(near_stats$mean_price), big.mark=","), " & ",
format(round(far_stats$mean_price), big.mark=","), " & ",
format(round(all_stats$mean_price), big.mark=","), " \\\\
& (", format(round(near_stats$sd_price), big.mark=","), ") & (",
format(round(far_stats$sd_price), big.mark=","), ") & (",
format(round(all_stats$sd_price), big.mark=","), ") \\\\[4pt]
Log(sale price) & ", round(near_stats$mean_log_price, 3), " & ",
round(far_stats$mean_log_price, 3), " & ",
round(all_stats$mean_log_price, 3), " \\\\
& (", round(near_stats$sd_log_price, 3), ") & (",
round(far_stats$sd_log_price, 3), ") & (",
round(all_stats$sd_log_price, 3), ") \\\\[4pt]
Distance to nearest dispensary (mi) & ", round(near_stats$mean_dist, 2), " & ",
round(far_stats$mean_dist, 2), " & ",
round(all_stats$mean_dist, 2), " \\\\[4pt]
Post-opening sales (\\%) & ", round(near_stats$pct_post, 1), " & ",
round(far_stats$pct_post, 1), " & ",
round(all_stats$pct_post, 1), " \\\\[4pt]
Observations & ", format(near_stats$N, big.mark=","), " & ",
format(far_stats$N, big.mark=","), " & ",
format(all_stats$N, big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard deviations in parentheses. Sales from Cook County, Illinois, 2019--2025. ``Within 0.5mi'' denotes properties whose nearest dispensary is within 0.5 miles. ``Post-opening'' indicates the sale occurred after the nearest dispensary's license issue date. Prices winsorized at \\$10,000 and \\$5,000,000.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Saved tab1_summary.tex\n")

## ---------------------------------------------------------------
## Table 2: Main DiD Results
## ---------------------------------------------------------------
cat("\n=== Table 2: Main Results ===\n")

m1 <- models$m1; m2 <- models$m2; m3 <- models$m3
m4 <- models$m4; m5 <- models$m5

# Helper: format coefficient with stars
fmt_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- 2 * pnorm(-abs(b/s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  paste0(sprintf("%.4f", b), stars)
}

fmt_se <- function(model, var) {
  sprintf("(%.4f)", se(model)[var])
}

tab2_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Dispensary Proximity on Log Property Prices}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
 & 0.25mi & 0.50mi & Inv.~Dist & Rings & Lottery \\\\
\\midrule
Near $\\times$ Post & ", fmt_coef(m1, "treat_025"), " & ",
fmt_coef(m2, "treat_050"), " & & & \\\\
 & ", fmt_se(m1, "treat_025"), " & ",
fmt_se(m2, "treat_050"), " & & & \\\\[4pt]
Inv.~Distance $\\times$ Post & & & ", fmt_coef(m3, "inv_dist_post"), " & & \\\\
 & & & ", fmt_se(m3, "inv_dist_post"), " & & \\\\[4pt]
0--0.25mi $\\times$ Post & & & & ", fmt_coef(m4, "treat_025"), " & \\\\
 & & & & ", fmt_se(m4, "treat_025"), " & \\\\[4pt]
0.25--0.50mi $\\times$ Post & & & & ", fmt_coef(m4, "treat_025_050"), " & \\\\
 & & & & ", fmt_se(m4, "treat_025_050"), " & \\\\[4pt]
0.50--1.00mi $\\times$ Post & & & & ", fmt_coef(m4, "treat_050_100"), " & \\\\
 & & & & ", fmt_se(m4, "treat_050_100"), " & \\\\[4pt]
Lottery dispensary $\\times$ Post & & & & & ", fmt_coef(m5, "treat_050"), " \\\\
 & & & & & ", fmt_se(m5, "treat_050"), " \\\\[4pt]
\\midrule
Dispensary cluster FE & Yes & Yes & Yes & Yes & Yes \\\\
Year-quarter FE & Yes & Yes & Yes & Yes & Yes \\\\
Observations & ", format(nobs(m1), big.mark=","), " & ",
format(nobs(m2), big.mark=","), " & ",
format(nobs(m3), big.mark=","), " & ",
format(nobs(m4), big.mark=","), " & ",
format(nobs(m5), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is log(sale price). Each column reports a separate OLS regression with dispensary-cluster and year-quarter fixed effects. Standard errors clustered at the dispensary level in parentheses. ``Near $\\times$ Post'' is an indicator for sales within the stated radius of a dispensary, after the dispensary's license issue date. Column (3) uses inverse distance (1/(dist+0.1)) interacted with a post-opening indicator. Column (5) restricts to sales near dispensaries that received licenses through the 2021--2023 lottery process. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Saved tab2_main.tex\n")

## ---------------------------------------------------------------
## Table 3: Heterogeneity by Income and Property Type
## ---------------------------------------------------------------
cat("\n=== Table 3: Heterogeneity ===\n")

m_hi <- robust$m_high_income
m_lo <- robust$m_low_income
m_res <- robust$m_residential

tab3_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Heterogeneity: Neighborhood Income and Property Type}
\\label{tab:hetero}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & High Income & Low Income & Residential \\\\
\\midrule
Within 0.50mi $\\times$ Post & ", fmt_coef(m_hi, "treat_050"), " & ",
fmt_coef(m_lo, "treat_050"), " & ",
fmt_coef(m_res, "treat_050"), " \\\\
 & ", fmt_se(m_hi, "treat_050"), " & ",
fmt_se(m_lo, "treat_050"), " & ",
fmt_se(m_res, "treat_050"), " \\\\[4pt]
\\midrule
Dispensary cluster FE & Yes & Yes & Yes \\\\
Year-quarter FE & Yes & Yes & Yes \\\\
Observations & ", format(nobs(m_hi), big.mark=","), " & ",
format(nobs(m_lo), big.mark=","), " & ",
format(nobs(m_res), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is log(sale price). ``High Income'' and ``Low Income'' split the sample at the median neighborhood-level median sale price. ``Residential'' restricts to single-family residential properties (Cook County class codes 2xx). Standard errors clustered at the dispensary level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab3_tex, "../tables/tab3_hetero.tex")
cat("  Saved tab3_hetero.tex\n")

## ---------------------------------------------------------------
## Table 4: Crime Effects
## ---------------------------------------------------------------
cat("\n=== Table 4: Crime Effects ===\n")

m_ct <- robust$m_crime_total
m_cd <- robust$m_crime_drug
m_cp <- robust$m_crime_property

if (!is.null(m_ct) && !is.null(m_cd) && !is.null(m_cp)) {
tab4_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Effect of Dispensary Entry on Crime}
\\label{tab:crime}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Log(Total) & Log(Drug) & Log(Property) \\\\
\\midrule
Dispensary present & ", fmt_coef(m_ct, "has_disp"), " & ",
fmt_coef(m_cd, "has_disp"), " & ",
fmt_coef(m_cp, "has_disp"), " \\\\
 & ", fmt_se(m_ct, "has_disp"), " & ",
fmt_se(m_cd, "has_disp"), " & ",
fmt_se(m_cp, "has_disp"), " \\\\[4pt]
\\midrule
Community area FE & Yes & Yes & Yes \\\\
Year-quarter FE & Yes & Yes & Yes \\\\
Observations & ", format(nobs(m_ct), big.mark=","), " & ",
format(nobs(m_cd), big.mark=","), " & ",
format(nobs(m_cp), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variables are log(crime count + 1) at the community-area--quarter level. ``Dispensary present'' is an indicator for at least one dispensary within one mile of the community area centroid being open in that quarter. Standard errors clustered at the community-area level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")
} else {
tab4_tex <- "% Crime table omitted: insufficient data"
}

writeLines(tab4_tex, "../tables/tab4_crime.tex")
cat("  Saved tab4_crime.tex\n")

## ---------------------------------------------------------------
## Table F1: Standardized Effect Sizes (SDE)
## ---------------------------------------------------------------
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- summ$sd_log_price  # SD of log price (unconditional)

# Main estimates
beta_025 <- coef(m1)["treat_025"]
se_025 <- se(m1)["treat_025"]
beta_050 <- coef(m2)["treat_050"]
se_050 <- se(m2)["treat_050"]

# Heterogeneity
beta_hi <- coef(m_hi)["treat_050"]
se_hi <- se(m_hi)["treat_050"]
beta_lo <- coef(m_lo)["treat_050"]
se_lo <- se(m_lo)["treat_050"]

# SDE computation (binary treatment)
sde_025 <- beta_025 / sd_y
sde_se_025 <- se_025 / sd_y
sde_050 <- beta_050 / sd_y
sde_se_050 <- se_050 / sd_y
sde_hi <- beta_hi / sd_y
sde_se_hi <- se_hi / sd_y
sde_lo <- beta_lo / sd_y
sde_se_lo <- se_lo / sd_y

# Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the entry of a lottery-assigned cannabis dispensary affect nearby residential property values in Cook County, Illinois? ",
  "\\textbf{Policy mechanism:} Illinois allocated 185 adult-use cannabis dispensary licenses through computerized lotteries (2021--2023), creating quasi-random variation in which neighborhoods received a dispensary; dispensary entry introduces visible retail cannabis activity, foot traffic, and signage to a neighborhood. ",
  "\\textbf{Outcome definition:} Log of residential property sale price from Cook County Assessor records, capturing the market valuation of housing within specified distance rings of dispensary locations. ",
  "\\textbf{Treatment:} Binary indicator equal to one for property sales within a specified distance of a dispensary that has opened. ",
  "\\textbf{Data:} Cook County Assessor property sales (Socrata API) and IDFPR dispensary license records, 2019--2025, property-transaction level, 26,740 geocoded sales. ",
  "\\textbf{Method:} Difference-in-differences with dispensary-cluster and year-quarter fixed effects, standard errors clustered at the dispensary level. ",
  "\\textbf{Sample:} Arm's-length residential property sales in Cook County with PIN-matched geocoordinates, \\$10,000--\\$5,000,000 sale price range. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log(sale price) = ",
  sprintf("%.3f", sd_y), ". ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
Log(price) & 0.25mi ring & ", sprintf("%.4f", beta_025), " & ", sprintf("%.4f", se_025), " & ",
sprintf("%.3f", sd_y), " & ", sprintf("%.4f", sde_025), " & ", sprintf("%.4f", sde_se_025), " & ",
classify(sde_025), " \\\\
Log(price) & 0.50mi ring & ", sprintf("%.4f", beta_050), " & ", sprintf("%.4f", se_050), " & ",
sprintf("%.3f", sd_y), " & ", sprintf("%.4f", sde_050), " & ", sprintf("%.4f", sde_se_050), " & ",
classify(sde_050), " \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Log(price) & High income & ", sprintf("%.4f", beta_hi), " & ", sprintf("%.4f", se_hi), " & ",
sprintf("%.3f", sd_y), " & ", sprintf("%.4f", sde_hi), " & ", sprintf("%.4f", sde_se_hi), " & ",
classify(sde_hi), " \\\\
Log(price) & Low income & ", sprintf("%.4f", beta_lo), " & ", sprintf("%.4f", se_lo), " & ",
sprintf("%.3f", sd_y), " & ", sprintf("%.4f", sde_lo), " & ", sprintf("%.4f", sde_se_lo), " & ",
classify(sde_lo), " \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize
\\begin{itemize}[leftmargin=*]
", sde_notes, "
\\end{itemize}}
\\end{table}\n")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat("Tables in tables/:\n")
cat(paste("  ", list.files("../tables"), collapse = "\n"), "\n")
