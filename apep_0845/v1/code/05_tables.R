## 05_tables.R — Generate all LaTeX tables
## apep_0845: EU Professional Qualifications Directive

source("code/00_packages.R")
library(fixest)
library(data.table)

cat("\n=== GENERATING TABLES ===\n")

results <- readRDS("data/model_results.rds")
robustness <- readRDS("data/robustness_results.rds")
panel <- results$panel

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt2 <- function(x) formatC(x, format = "f", digits = 2)
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
stars <- function(p) {
  if (is.na(p)) return("")
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# Model mapping:
# m1: oq_gap_all ~ treat_post (primary, 24 countries)
# m2: oq_gap_all ~ high_reg_post (binary, 24 countries)
# m3: oq_gap ~ treat_post (EU-foreign subset, 17 countries)
# m4: nat ~ treat_post (national OQ)
# m5: oq_gap_noneu ~ treat_post (non-EU gap, placebo)

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3
m4 <- results$m4; m5 <- results$m5

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════════════════
cat("--- Table 1: Summary Statistics ---\n")

pre <- panel[year < 2016]; post <- panel[year >= 2016]

vars_list <- list(
  list(name = "Overqualification rate, foreign (\\%)", var = "all_for"),
  list(name = "Overqualification rate, national (\\%)", var = "nat"),
  list(name = "Overqualification gap, foreign $-$ nat. (pp)", var = "oq_gap_all"),
  list(name = "Overqualification gap, EU-for. $-$ nat. (pp)", var = "oq_gap"),
  list(name = "Overqualification gap, non-EU $-$ nat. (pp)", var = "oq_gap_noneu"),
  list(name = "Regulated professions (count)", var = "n_regulated")
)

tab1_lines <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Summary Statistics: Overqualification and Professional Regulation}",
  "\\label{tab:summary}", "\\begin{tabular}{lcccc}", "\\toprule",
  " & \\multicolumn{2}{c}{Pre-Reform (2006--2015)} & \\multicolumn{2}{c}{Post-Reform (2016--2023)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\", "\\midrule"
)
for (v in vars_list) {
  pre_m <- mean(pre[[v$var]], na.rm = TRUE); pre_s <- sd(pre[[v$var]], na.rm = TRUE)
  post_m <- mean(post[[v$var]], na.rm = TRUE); post_s <- sd(post[[v$var]], na.rm = TRUE)
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                       v$name, fmt2(pre_m), fmt2(pre_s), fmt2(post_m), fmt2(post_s)))
}
tab1_lines <- c(tab1_lines, "\\midrule",
  sprintf("Countries & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(pre$country), uniqueN(post$country)),
  sprintf("Country-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          fmt0(nrow(pre)), fmt0(nrow(post))),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Overqualification rates from Eurostat LFS (lfsa\\_eoqgan), defined as the share of employed persons with tertiary education (ISCED 5--8) working in occupations not requiring tertiary education. ``Foreign'' are all non-citizens; ``EU-foreign'' are EU citizens residing in another member state; ``non-EU'' are third-country nationals; ``national'' are citizens of the reporting country. ``Gap'' is the difference in rates. Regulated professions count from EC Regulated Professions Database (circa 2013). Pre-reform: 2006--2015; post-reform: 2016--2023 (transposition deadline January 18, 2016).",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 2: Main DiD Results
## ═══════════════════════════════════════════════════════════════════════════
cat("--- Table 2: Main Results ---\n")

get_row <- function(model, varname) {
  b <- coef(model)[varname]; s <- se(model)[varname]; p <- pvalue(model)[varname]
  list(coef = b, se = s, p = p, star = stars(p))
}

r1 <- get_row(m1, "treat_post")
r2 <- get_row(m2, "high_reg_post")
r3 <- get_row(m3, "treat_post")
r4 <- get_row(m4, "treat_post")
r5 <- get_row(m5, "treat_post")

tab2_lines <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Effect of Professional Qualifications Reform on Overqualification}",
  "\\label{tab:main}", "\\begin{tabular}{lccccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & For. Gap & For. Gap & EU-For. & National & Non-EU \\\\",
  " & (Cont.) & (Binary) & Gap & OQ Rate & Gap \\\\",
  "\\midrule",
  sprintf("Reg. Intensity $\\times$ Post & %s%s & & %s%s & %s%s & %s%s \\\\",
          fmt(r1$coef), r1$star, fmt(r3$coef), r3$star,
          fmt(r4$coef), r4$star, fmt(r5$coef), r5$star),
  sprintf(" & (%s) & & (%s) & (%s) & (%s) \\\\",
          fmt(r1$se), fmt(r3$se), fmt(r4$se), fmt(r5$se)),
  sprintf("High Reg. $\\times$ Post & & %s%s & & & \\\\",
          fmt(r2$coef), r2$star),
  sprintf(" & & (%s) & & & \\\\", fmt(r2$se)),
  "\\midrule",
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          fmt0(nobs(m1)), fmt0(nobs(m2)), fmt0(nobs(m3)), fmt0(nobs(m4)), fmt0(nobs(m5))),
  sprintf("$R^2$ (within) & %s & %s & %s & %s & %s \\\\",
          fmt(r2(m1, "wr2")), fmt(r2(m2, "wr2")), fmt(r2(m3, "wr2")),
          fmt(r2(m4, "wr2")), fmt(r2(m5, "wr2"))),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Columns (1)--(2): dependent variable is the foreign-national overqualification gap (all foreign citizens minus nationals, pp). Column (3): EU-foreign gap only (17 countries with EU citizenship data). Column (4): national overqualification rate. Column (5): non-EU foreign gap (placebo---unaffected by intra-EU recognition). ``Reg.~Intensity'' is standardized regulated professions count. ``High Reg.'' is an indicator for above-median regulated professions. ``Post'' = years $\\geq$ 2016. All specifications include country and year FE. SEs clustered at country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab2_lines, "tables/tab2_main.tex")
cat("  Written tables/tab2_main.tex\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 3: Event Study
## ═══════════════════════════════════════════════════════════════════════════
cat("--- Table 3: Event Study ---\n")

es <- results$es_coefs
es[, event_time := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
es <- es[order(event_time)]

tab3_lines <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Event Study: Foreign Overqualification Gap $\\times$ Regulatory Intensity}",
  "\\label{tab:eventstudy}", "\\begin{tabular}{lcc}", "\\toprule",
  "Event Time & Coefficient & SE \\\\", "\\midrule"
)
for (i in seq_len(nrow(es))) {
  et <- es$event_time[i]; b <- es$estimate[i]; s <- es$se[i]; p <- es$p[i]
  st <- stars(p)
  label <- ifelse(et == -1, "$t = -1$ (ref.)",
                  paste0("$t = ", ifelse(et > 0, paste0("+", et), et), "$"))
  if (et == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- \\\\", label))
  } else {
    tab3_lines <- c(tab3_lines, sprintf("%s & %s%s & (%s) \\\\", label, fmt(b), st, fmt(s)))
  }
  if (et == -1 && i < nrow(es)) tab3_lines <- c(tab3_lines, "\\midrule")
}
tab3_lines <- c(tab3_lines, "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", fmt0(nrow(panel))),
  "Country \\& Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each coefficient = interaction of event time (relative to 2016 deadline) with standardized regulatory intensity. Reference: $t = -1$ (2015). SE clustered by country. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_eventstudy.tex")
cat("  Written tables/tab3_eventstudy.tex\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 4: Robustness
## ═══════════════════════════════════════════════════════════════════════════
cat("--- Table 4: Robustness ---\n")

main_b <- coef(m1)["treat_post"]; main_se <- se(m1)["treat_post"]; main_p <- pvalue(m1)["treat_post"]
if (!is.null(robustness$m_early)) {
  early_b <- coef(robustness$m_early)["treat_post"]
  early_se <- se(robustness$m_early)["treat_post"]
  early_p <- pvalue(robustness$m_early)["treat_post"]
} else { early_b <- early_se <- early_p <- NA }
loo_min <- min(robustness$loo_results$coef); loo_max <- max(robustness$loo_results$coef)

tab4_lines <- c(
  "\\begin{table}[t]", "\\centering", "\\caption{Robustness Checks}",
  "\\label{tab:robustness}", "\\begin{tabular}{lccc}", "\\toprule",
  "Specification & Coefficient & SE & $p$-value \\\\", "\\midrule",
  sprintf("Baseline & %s%s & (%s) & %s \\\\", fmt(main_b), stars(main_p), fmt(main_se), fmt(main_p,3)),
  sprintf("Wild cluster bootstrap & %s & --- & %s \\\\", fmt(main_b),
          ifelse(!is.null(robustness$wcb_pvalue), fmt(robustness$wcb_pvalue,3), "---")),
  sprintf("Randomization inference & %s & --- & %s \\\\", fmt(main_b), fmt(robustness$ri_pvalue,3))
)
if (!is.na(early_b)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Drop late transposers & %s%s & (%s) & %s \\\\",
            fmt(early_b), stars(early_p), fmt(early_se), fmt(early_p,3)))
}
tab4_lines <- c(tab4_lines,
  sprintf("Leave-one-out range & [%s, %s] & & \\\\", fmt(loo_min), fmt(loo_max)),
  "\\midrule",
  "EU-foreign gap (17 countries) & \\multicolumn{3}{c}{See Table~\\ref{tab:main}, col.~(3)} \\\\",
  "Non-EU placebo & \\multicolumn{3}{c}{See Table~\\ref{tab:main}, col.~(5)} \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All specifications: standardized regulatory intensity $\\times$ post-2016 on all-foreign overqualification gap, country + year FE. Baseline: cluster-robust SE ($N = 24$). Wild cluster bootstrap: 999 Rademacher reps. RI: 1,000 permutations of treatment intensity. ``Drop late transposers'': excludes countries transposing after 2018. LOO: range from dropping each country.",
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tab4_lines, "tables/tab4_robustness.tex")
cat("  Written tables/tab4_robustness.tex\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE F1: SDE
## ═══════════════════════════════════════════════════════════════════════════
cat("--- Table F1: SDE ---\n")

sd_pre_all <- sd(panel[year < 2016]$oq_gap_all, na.rm = TRUE)
sd_pre_eu <- sd(panel[year < 2016]$oq_gap, na.rm = TRUE)
sd_pre_noneu <- sd(panel[year < 2016]$oq_gap_noneu, na.rm = TRUE)

# SDE = β × SD(X) / SD(Y) = β / SD(Y) since SD(X)=1
sde_all <- coef(m1)["treat_post"] / sd_pre_all
sde_all_se <- se(m1)["treat_post"] / sd_pre_all
sde_eu <- coef(m3)["treat_post"] / sd_pre_eu
sde_eu_se <- se(m3)["treat_post"] / sd_pre_eu
sde_noneu <- coef(m5)["treat_post"] / sd_pre_noneu
sde_noneu_se <- se(m5)["treat_post"] / sd_pre_noneu

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large neg.")
  if (s < -0.05) return("Mod. neg.")
  if (s < -0.005) return("Small neg.")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small pos.")
  if (s <= 0.15) return("Mod. pos.")
  return("Large pos.")
}

# Panel B: sample splits
panel_high <- panel[high_reg == 1]; panel_low <- panel[high_reg == 0]
m_high <- feols(oq_gap_all ~ post | country, data = panel_high, cluster = ~country)
m_low <- feols(oq_gap_all ~ post | country, data = panel_low, cluster = ~country)
sd_high <- sd(panel_high[year < 2016]$oq_gap_all, na.rm = TRUE)
sd_low <- sd(panel_low[year < 2016]$oq_gap_all, na.rm = TRUE)
sde_high <- coef(m_high)["post"] / sd_high; sde_high_se <- se(m_high)["post"] / sd_high
sde_low <- coef(m_low)["post"] / sd_low; sde_low_se <- se(m_low)["post"] / sd_low

tabF1_lines <- c(
  "\\begin{table}[t]", "\\centering", "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccp{2.2cm}}", "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule", "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("OQ gap, all foreign $-$ nat. & %s & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m1)["treat_post"]), fmt(se(m1)["treat_post"]),
          fmt(sd_pre_all), fmt(sde_all), fmt(sde_all_se), classify_sde(sde_all)),
  sprintf("OQ gap, EU-foreign $-$ nat. & %s & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m3)["treat_post"]), fmt(se(m3)["treat_post"]),
          fmt(sd_pre_eu), fmt(sde_eu), fmt(sde_eu_se), classify_sde(sde_eu)),
  sprintf("OQ gap, non-EU $-$ nat. & %s & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m5)["treat_post"]), fmt(se(m5)["treat_post"]),
          fmt(sd_pre_noneu), fmt(sde_noneu), fmt(sde_noneu_se), classify_sde(sde_noneu)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample split by regulatory intensity)}} \\\\",
  sprintf("All-for. gap, high reg. ($\\geq$ med.) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_high)["post"]), fmt(se(m_high)["post"]),
          fmt(sd_high), fmt(sde_high), fmt(sde_high_se), classify_sde(sde_high)),
  sprintf("All-for. gap, low reg. ($<$ med.) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_low)["post"]), fmt(se(m_low)["post"]),
          fmt(sd_low), fmt(sde_low), fmt(sde_low_se), classify_sde(sde_low)),
  "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} ",
    "\\textbf{Country:} European Union (24 member states with data). ",
    "\\textbf{Research question:} Does the 2013 modernization of the EU Professional Qualifications Directive (2013/55/EU), which introduced electronic recognition procedures and the European Professional Card, reduce overqualification among mobile professionals? ",
    "\\textbf{Policy mechanism:} The reform streamlined cross-border recognition of professional qualifications by mandating electronic procedures via the Internal Market Information system and creating the European Professional Card for nurses, pharmacists, and physiotherapists, reducing administrative barriers for professionals seeking to work in other member states. ",
    "\\textbf{Outcome definition:} Overqualification gap, defined as the difference in overqualification rates between foreign citizens and nationals within each country (Eurostat LFS lfsa\\_eoqgan), where overqualification means holding tertiary education (ISCED 5--8) while employed in an occupation not requiring it. ",
    "\\textbf{Treatment:} Continuous --- standardized number of regulated professions per country (mean zero, unit variance; raw range 88--415). ",
    "\\textbf{Data:} Eurostat Labour Force Survey, 24 EU countries, 2006--2023, country-year level, ", fmt0(nrow(panel)), " observations. ",
    "\\textbf{Method:} Two-way fixed effects (country + year), standard errors clustered at country level. ",
    "\\textbf{Sample:} EU member states with non-missing overqualification data; employed persons aged 20--64 with tertiary education. ",
    "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) = 1 (standardized treatment) and SD($Y$) is the pre-reform standard deviation. ",
    "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."),
  "\\end{tablenotes}", "\\end{table}"
)
writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
