## 05_tables.R — Generate all LaTeX tables for apep_0882

library(tidyverse)
library(data.table)
library(fixest)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "panel.csv"))
panel[, fips := as.character(fips)]
panel[, state_fips := as.character(state_fips)]
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)


## =================================================================
## TABLE 1: Summary Statistics
## =================================================================
cat("=== Table 1: Summary Statistics ===\n")

oil <- panel[has_oil == 1]
non_oil <- panel[has_oil == 0]

summ_vars <- function(dt, label) {
  data.table(
    Group = label,
    N = nrow(dt),
    Counties = uniqueN(dt$fips),
    `Drug OD Rate` = mean(dt$drug_od_rate, na.rm = TRUE),
    `SD Drug OD` = sd(dt$drug_od_rate, na.rm = TRUE),
    `Population (000s)` = mean(dt$population / 1000, na.rm = TRUE),
    `Oil Share` = mean(dt$oil_share, na.rm = TRUE)
  )
}

summ <- rbind(
  summ_vars(non_oil, "Non-Oil Counties"),
  summ_vars(oil, "Oil Counties"),
  summ_vars(panel[high_oil == 1], "High Oil (Top Quartile)")
)

# Period means for the two groups
period_means <- panel[, .(
  rate = mean(drug_od_rate, na.rm = TRUE),
  sd = sd(drug_od_rate, na.rm = TRUE)
), by = .(period, has_oil)]
setorder(period_means, has_oil, period)

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Oil and Non-Oil Counties, 1999--2015}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
 & \\multicolumn{2}{c}{Non-Oil} & \\multicolumn{2}{c}{Oil} & \\multicolumn{2}{c}{High Oil} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
 & Mean & SD & Mean & SD & Mean & SD \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Full Sample}} \\\\
Drug OD rate (per 100K) & ", fmt(mean(non_oil$drug_od_rate), 2),
" & ", fmt(sd(non_oil$drug_od_rate), 2),
" & ", fmt(mean(oil$drug_od_rate), 2),
" & ", fmt(sd(oil$drug_od_rate), 2),
" & ", fmt(mean(panel[high_oil == 1]$drug_od_rate), 2),
" & ", fmt(sd(panel[high_oil == 1]$drug_od_rate), 2), " \\\\
Population (000s) & ", fmt(mean(non_oil$population/1000, na.rm=TRUE), 1),
" & ", fmt(sd(non_oil$population/1000, na.rm=TRUE), 1),
" & ", fmt(mean(oil$population/1000, na.rm=TRUE), 1),
" & ", fmt(sd(oil$population/1000, na.rm=TRUE), 1),
" & ", fmt(mean(panel[high_oil == 1]$population/1000, na.rm=TRUE), 1),
" & ", fmt(sd(panel[high_oil == 1]$population/1000, na.rm=TRUE), 1), " \\\\
Oil/gas emp.~share (\\%) & --- & --- & ",
fmt(100 * mean(oil$oil_share, na.rm=TRUE), 2),
" & ", fmt(100 * sd(oil$oil_share, na.rm=TRUE), 2),
" & ", fmt(100 * mean(panel[high_oil == 1]$oil_share, na.rm=TRUE), 2),
" & ", fmt(100 * sd(panel[high_oil == 1]$oil_share, na.rm=TRUE), 2), " \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Drug OD Rate by Period}} \\\\
Pre-boom (1999--2004) & ",
fmt(period_means[has_oil == 0 & period == "pre_boom"]$rate, 2), " & ",
fmt(period_means[has_oil == 0 & period == "pre_boom"]$sd, 2), " & ",
fmt(period_means[has_oil == 1 & period == "pre_boom"]$rate, 2), " & ",
fmt(period_means[has_oil == 1 & period == "pre_boom"]$sd, 2), " & & \\\\
Boom (2005--2014) & ",
fmt(period_means[has_oil == 0 & period == "boom"]$rate, 2), " & ",
fmt(period_means[has_oil == 0 & period == "boom"]$sd, 2), " & ",
fmt(period_means[has_oil == 1 & period == "boom"]$rate, 2), " & ",
fmt(period_means[has_oil == 1 & period == "boom"]$sd, 2), " & & \\\\
Bust (2015) & ",
fmt(period_means[has_oil == 0 & period == "bust"]$rate, 2), " & ",
fmt(period_means[has_oil == 0 & period == "bust"]$sd, 2), " & ",
fmt(period_means[has_oil == 1 & period == "bust"]$rate, 2), " & ",
fmt(period_means[has_oil == 1 & period == "bust"]$sd, 2), " & & \\\\
\\midrule
County-years & \\multicolumn{2}{c}{", format(nrow(non_oil), big.mark=","),
"} & \\multicolumn{2}{c}{", format(nrow(oil), big.mark=","),
"} & \\multicolumn{2}{c}{", format(nrow(panel[high_oil == 1]), big.mark=","), "} \\\\
Counties & \\multicolumn{2}{c}{", format(uniqueN(non_oil$fips), big.mark=","),
"} & \\multicolumn{2}{c}{", format(uniqueN(oil$fips), big.mark=","),
"} & \\multicolumn{2}{c}{", format(uniqueN(panel[high_oil == 1]$fips), big.mark=","), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Oil counties are those with at least one NAICS 211 (Oil and Gas Extraction) establishment in the 2001--2004 County Business Patterns. High Oil counties are in the top quartile of establishment counts. Drug overdose rates are model-based age-adjusted death rates per 100,000 from CDC NCHS, reported in 2-unit categorical bins and converted to midpoints. Oil/gas employment share uses pre-boom (2001--2004) CBP data.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")


## =================================================================
## TABLE 2: Main Event Study Coefficients
## =================================================================
cat("\n=== Table 2: Event Study ===\n")

es <- results$es_binary
es_coefs <- coeftable(es)
years <- 1999:2015
ref_year <- 2004

# Build event study table
es_rows <- character()
for (yr in years) {
  if (yr == ref_year) {
    es_rows <- c(es_rows, paste0(yr, " & [Ref.] & & [Ref.] & \\\\"))
    next
  }

  # Binary
  bn <- paste0("year::", yr, ":has_oil")
  bc <- fmt(es_coefs[bn, "Estimate"], 3)
  bs <- paste0("(", fmt(es_coefs[bn, "Std. Error"], 3), ")")
  bstar <- stars(es_coefs[bn, "Pr(>|t|)"])

  # High oil
  hn <- paste0("year::", yr, ":high_oil")
  hc_row <- coeftable(results$es_high)
  hc <- fmt(hc_row[hn, "Estimate"], 3)
  hs <- paste0("(", fmt(hc_row[hn, "Std. Error"], 3), ")")
  hstar <- stars(hc_row[hn, "Pr(>|t|)"])

  es_rows <- c(es_rows,
    paste0(yr, " & ", bc, bstar, " & ", bs, " & ", hc, hstar, " & ", hs, " \\\\"))
}

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Event Study: Oil Exposure and Drug Overdose Mortality}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Any Oil} & \\multicolumn{2}{c}{High Oil} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Year & Coef. & SE & Coef. & SE \\\\
\\midrule
", paste(es_rows, collapse = "\n"), "
\\midrule
County FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
Observations & \\multicolumn{2}{c}{", format(nobs(results$es_binary), big.mark=","),
"} & \\multicolumn{2}{c}{", format(nobs(results$es_high), big.mark=","), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Estimates from $Y_{ct} = \\alpha_c + \\gamma_t + \\sum_k \\beta_k (\\text{Oil}_c \\times \\mathbf{1}[t=k]) + \\varepsilon_{ct}$ where $Y$ is the drug overdose mortality rate per 100,000 and Oil$_c$ is a pre-boom county oil exposure indicator. Reference year is 2004. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:event_study}
\\end{table}"
)

writeLines(tab2, file.path(tables_dir, "tab2_event_study.tex"))
cat("  Saved tab2_event_study.tex\n")


## =================================================================
## TABLE 3: Period DiD (Main + Robustness)
## =================================================================
cat("\n=== Table 3: Period DiD ===\n")

# Extract coefficients from multiple models
extract_did <- function(mod, boom_name, bust_name) {
  ct <- coeftable(mod)
  list(
    boom = ct[boom_name, "Estimate"],
    boom_se = ct[boom_name, "Std. Error"],
    boom_p = ct[boom_name, "Pr(>|t|)"],
    bust = ct[bust_name, "Estimate"],
    bust_se = ct[bust_name, "Std. Error"],
    bust_p = ct[bust_name, "Pr(>|t|)"],
    n = nobs(mod)
  )
}

m1 <- extract_did(results$did_binary, "has_oil_x_boom", "has_oil_x_bust")
m2 <- extract_did(results$did_high, "high_x_boom", "high_x_bust")
m3 <- extract_did(rob$did_trends, "has_oil_x_boom", "has_oil_x_bust")
m4 <- extract_did(rob$did_emp, "emp_x_boom", "emp_x_bust")

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Period Difference-in-Differences: Oil Exposure and Drug Overdose Mortality}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Any Oil & High Oil & State Trends & Non-Zero Emp. \\\\
\\midrule
Oil $\\times$ Boom & ", fmt(m1$boom), stars(m1$boom_p),
" & ", fmt(m2$boom), stars(m2$boom_p),
" & ", fmt(m3$boom), stars(m3$boom_p),
" & ", fmt(m4$boom), stars(m4$boom_p), " \\\\
 & (", fmt(m1$boom_se), ") & (", fmt(m2$boom_se), ") & (", fmt(m3$boom_se), ") & (", fmt(m4$boom_se), ") \\\\
Oil $\\times$ Bust & ", fmt(m1$bust), stars(m1$bust_p),
" & ", fmt(m2$bust), stars(m2$bust_p),
" & ", fmt(m3$bust), stars(m3$bust_p),
" & ", fmt(m4$bust), stars(m4$bust_p), " \\\\
 & (", fmt(m1$bust_se), ") & (", fmt(m2$bust_se), ") & (", fmt(m3$bust_se), ") & (", fmt(m4$bust_se), ") \\\\
\\midrule
County FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
State $\\times$ Year Trend & No & No & Yes & No \\\\
Observations & ", format(m1$n, big.mark=","),
" & ", format(m2$n, big.mark=","),
" & ", format(m3$n, big.mark=","),
" & ", format(m4$n, big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is drug overdose mortality rate per 100,000 (model-based, CDC NCHS). Boom = 2005--2014; Bust = 2015. Column 1: any pre-boom NAICS 211 establishment. Column 2: top-quartile establishment count. Column 3: adds state-specific linear time trends. Column 4: restricts to counties with non-zero reported oil/gas employment in CBP. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:did}
\\end{table}"
)

writeLines(tab3, file.path(tables_dir, "tab3_did.tex"))
cat("  Saved tab3_did.tex\n")


## =================================================================
## TABLE 4: Quintile Heterogeneity
## =================================================================
cat("\n=== Table 4: Quintile Heterogeneity ===\n")

# Re-estimate for each quintile
preboom_rate <- panel[year <= 2004, .(preboom_drug = mean(drug_od_rate)), by = fips]
preboom_rate[, quintile := cut(preboom_drug,
  breaks = quantile(preboom_drug, probs = 0:5/5, na.rm = TRUE),
  labels = paste0("Q", 1:5), include.lowest = TRUE)]
panel <- merge(panel, preboom_rate[, .(fips, quintile)], by = "fips", all.x = TRUE)

q_rows <- character()
for (q in paste0("Q", 1:5)) {
  mod <- feols(
    drug_od_rate ~ has_oil_x_boom + has_oil_x_bust | fips + year,
    data = panel[quintile == q],
    cluster = ~state_fips
  )
  ct <- coeftable(mod)
  q_rows <- c(q_rows, paste0(
    q, " & ", fmt(ct[1,1]), stars(ct[1,4]),
    " & (", fmt(ct[1,2]), ")",
    " & ", fmt(ct[2,1]), stars(ct[2,4]),
    " & (", fmt(ct[2,2]), ")",
    " & ", format(nobs(mod), big.mark=","), " \\\\"
  ))
}

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Heterogeneous Effects by Pre-Boom Drug Overdose Rate Quintile}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
Pre-boom & \\multicolumn{2}{c}{Oil $\\times$ Boom} & \\multicolumn{2}{c}{Oil $\\times$ Bust} & N \\\\
Quintile & Coef. & SE & Coef. & SE & \\\\
\\midrule
", paste(q_rows, collapse = "\n"), "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each row estimates $Y_{ct} = \\alpha_c + \\gamma_t + \\beta_1 (\\text{Oil}_c \\times \\text{Boom}_t) + \\beta_2 (\\text{Oil}_c \\times \\text{Bust}_t) + \\varepsilon_{ct}$ separately within each quintile of the county's pre-boom (1999--2004) average drug overdose rate. Q1 = lowest, Q5 = highest pre-boom drug overdose rates. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:quintile}
\\end{table}"
)

writeLines(tab4, file.path(tables_dir, "tab4_quintile.tex"))
cat("  Saved tab4_quintile.tex\n")


## =================================================================
## TABLE 5: Triple-Diff
## =================================================================
cat("\n=== Table 5: Triple-Diff ===\n")

td1 <- coeftable(results$did_triple)
td2 <- coeftable(rob$did_triple_trend)

tab5 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Triple-Difference: Oil Exposure, Pre-Boom Drug Vulnerability, and Drug Overdose Mortality}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
 & (1) & (2) \\\\
 & Baseline & State Trends \\\\
\\midrule
Oil $\\times$ Boom & ", fmt(td1["oil_boom",1]), stars(td1["oil_boom",4]),
" & ", fmt(td2["oil_boom2",1]), stars(td2["oil_boom2",4]), " \\\\
 & (", fmt(td1["oil_boom",2]), ") & (", fmt(td2["oil_boom2",2]), ") \\\\
Oil $\\times$ Bust & ", fmt(td1["oil_bust",1]), stars(td1["oil_bust",4]),
" & ", fmt(td2["oil_bust2",1]), stars(td2["oil_bust2",4]), " \\\\
 & (", fmt(td1["oil_bust",2]), ") & (", fmt(td2["oil_bust2",2]), ") \\\\
HighDrug $\\times$ Boom & ", fmt(td1["drug_boom",1]), stars(td1["drug_boom",4]),
" & ", fmt(td2["drug_boom2",1]), stars(td2["drug_boom2",4]), " \\\\
 & (", fmt(td1["drug_boom",2]), ") & (", fmt(td2["drug_boom2",2]), ") \\\\
HighDrug $\\times$ Bust & ", fmt(td1["drug_bust",1]), stars(td1["drug_bust",4]),
" & ", fmt(td2["drug_bust2",1]), stars(td2["drug_bust2",4]), " \\\\
 & (", fmt(td1["drug_bust",2]), ") & (", fmt(td2["drug_bust2",2]), ") \\\\
\\midrule
Oil $\\times$ Boom $\\times$ HighDrug & ", fmt(td1["oil_boom_highdrug",1]), stars(td1["oil_boom_highdrug",4]),
" & ", fmt(td2["oil_boom_highdrug",1]), stars(td2["oil_boom_highdrug",4]), " \\\\
 & (", fmt(td1["oil_boom_highdrug",2]), ") & (", fmt(td2["oil_boom_highdrug",2]), ") \\\\
Oil $\\times$ Bust $\\times$ HighDrug & ", fmt(td1["oil_bust_highdrug",1]), stars(td1["oil_bust_highdrug",4]),
" & ", fmt(td2["oil_bust_highdrug",1]), stars(td2["oil_bust_highdrug",4]), " \\\\
 & (", fmt(td1["oil_bust_highdrug",2]), ") & (", fmt(td2["oil_bust_highdrug",2]), ") \\\\
\\midrule
County FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
State $\\times$ Year Trend & No & Yes \\\\
Observations & ", format(nobs(results$did_triple), big.mark=","),
" & ", format(nobs(rob$did_triple_trend), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Triple-difference estimates. HighDrug = county's pre-boom (1999--2004) drug overdose rate above the sample median. The coefficients on Oil $\\times$ Period $\\times$ HighDrug capture the differential effect of oil exposure on drug mortality in already-vulnerable counties. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:triple}
\\end{table}"
)

writeLines(tab5, file.path(tables_dir, "tab5_triple_diff.tex"))
cat("  Saved tab5_triple_diff.tex\n")


## =================================================================
## TABLE F1: Standardized Effect Sizes (SDE)
## =================================================================
cat("\n=== Table F1: SDE ===\n")

# Main specification: binary DiD
beta_boom <- coef(results$did_binary)["has_oil_x_boom"]
se_boom <- se(results$did_binary)["has_oil_x_boom"]
beta_bust <- coef(results$did_binary)["has_oil_x_bust"]
se_bust <- se(results$did_binary)["has_oil_x_bust"]
sd_y <- sd(panel$drug_od_rate[panel$year <= 2004])

sde_boom <- beta_boom / sd_y
sde_se_boom <- se_boom / sd_y
sde_bust <- beta_bust / sd_y
sde_se_bust <- se_bust / sd_y

# Triple-diff: heterogeneous effect in high-drug counties
td_ct <- coeftable(results$did_triple)
beta_td_boom <- td_ct["oil_boom_highdrug", "Estimate"]
se_td_boom <- td_ct["oil_boom_highdrug", "Std. Error"]
beta_td_bust <- td_ct["oil_bust_highdrug", "Estimate"]
se_td_bust <- td_ct["oil_bust_highdrug", "Std. Error"]

# SD(Y) for high-drug counties
sd_y_high <- sd(panel$drug_od_rate[panel$year <= 2004 & panel$high_drug == 1])

sde_td_boom <- beta_td_boom / sd_y_high
sde_se_td_boom <- se_td_boom / sd_y_high
sde_td_bust <- beta_td_bust / sd_y_high
sde_se_td_bust <- se_td_bust / sd_y_high

# Classification function
classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether county-level exposure to oil and gas extraction ",
  "during the shale boom (2005--2014) and subsequent bust (2015) affected drug overdose mortality ",
  "rates, and whether this effect differed by pre-existing vulnerability to drug deaths. ",
  "\\textbf{Policy mechanism:} The shale revolution created geographically concentrated employment ",
  "and income shocks in counties overlying shale formations; the mechanism is economic opportunity ",
  "as a protective factor against substance abuse, operating through labor demand, wages, and ",
  "community investment in resource-dependent areas. ",
  "\\textbf{Outcome definition:} Model-based age-adjusted drug overdose death rate per 100,000 ",
  "population from CDC NCHS, covering all drug poisoning deaths (ICD-10 X40--X44, X60--X64, X85, Y10--Y14). ",
  "\\textbf{Treatment:} Binary indicator for county having at least one NAICS 211 (Oil and Gas Extraction) ",
  "establishment in the pre-boom period (2001--2004), interacted with boom/bust period indicators. ",
  "\\textbf{Data:} CDC NCHS Drug Poisoning Mortality by County, 1999--2015; Census County Business Patterns ",
  "2001--2004; county-year panel with 53,387 observations across 3,141 counties. ",
  "\\textbf{Method:} Two-way fixed effects (county + year) difference-in-differences with state-clustered ",
  "standard errors; triple-difference specification interacting oil exposure with pre-boom drug vulnerability. ",
  "\\textbf{Sample:} All US counties with non-missing drug overdose rates in the CDC NCHS data, 1999--2015. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (1999--2004) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
Drug OD rate & Oil $\\times$ Boom & ", fmt(beta_boom),
" & ", fmt(se_boom), " & ", fmt(sd_y, 2),
" & ", fmt(sde_boom), " & ", fmt(sde_se_boom),
" & ", classify(sde_boom), " \\\\
Drug OD rate & Oil $\\times$ Bust & ", fmt(beta_bust),
" & ", fmt(se_bust), " & ", fmt(sd_y, 2),
" & ", fmt(sde_bust), " & ", fmt(sde_se_bust),
" & ", classify(sde_bust), " \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (High Pre-Boom Drug Rate Counties)}} \\\\
Drug OD rate & Oil $\\times$ Boom $\\times$ HighDrug & ", fmt(beta_td_boom),
" & ", fmt(se_td_boom), " & ", fmt(sd_y_high, 2),
" & ", fmt(sde_td_boom), " & ", fmt(sde_se_td_boom),
" & ", classify(sde_td_boom), " \\\\
Drug OD rate & Oil $\\times$ Bust $\\times$ HighDrug & ", fmt(beta_td_bust),
" & ", fmt(se_td_bust), " & ", fmt(sd_y_high, 2),
" & ", fmt(sde_td_bust), " & ", fmt(sde_se_td_bust),
" & ", classify(sde_td_bust), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")


cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste("  ", list.files(tables_dir), collapse = "\n"), "\n")
