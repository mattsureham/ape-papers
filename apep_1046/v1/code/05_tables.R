## 05_tables.R — Generate all tables including SDE appendix
## apep_1046: Cross-hazard injury substitution

source("00_packages.R")

load("../data/main_results.RData")
load("../data/robustness_results.RData")
panel <- fread("../data/panel_establishment.csv")
mfg <- panel[sector_group == "manufacturing"]
mfg[, high_silica := as.integer(naics3 %in% c(327, 331, 332))]
mfg[, post := as.integer(year >= 2019)]

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ═══════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary statistics\n")

## Pre-period stats
pre_stats <- mfg[post == 0, .(
  N = .N,
  Establishments = uniqueN(establishment_id),
  Employees = round(mean(emp, na.rm = TRUE), 0),
  `Injury Rate` = round(mean(total_injuries_rate, na.rm = TRUE), 2),
  `Respiratory Rate` = round(mean(total_respiratory_conditions_rate, na.rm = TRUE), 3),
  `Hearing Loss Rate` = round(mean(total_hearing_loss_rate, na.rm = TRUE), 3),
  `Skin Disorders Rate` = round(mean(total_skin_disorders_rate, na.rm = TRUE), 3),
  `Other Illness Rate` = round(mean(total_other_illnesses_rate, na.rm = TRUE), 3)
), by = .(Group = fifelse(high_silica == 1, "High-silica", "Low-silica"))]

## Write Table 1
tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Manufacturing Establishments, Pre-Treatment (2016--2021)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & High-Silica & Low-Silica \\\\",
  " & NAICS 327/331/332 & Other Manufacturing \\\\",
  "\\midrule"
)

hs <- pre_stats[Group == "High-silica"]
ls <- pre_stats[Group == "Low-silica"]

tab1_tex <- c(tab1_tex,
  sprintf("Establishments & %s & %s \\\\",
          format(hs$Establishments, big.mark = ","),
          format(ls$Establishments, big.mark = ",")),
  sprintf("Establishment-years & %s & %s \\\\",
          format(hs$N, big.mark = ","),
          format(ls$N, big.mark = ",")),
  sprintf("Mean employees & %s & %s \\\\",
          format(hs$Employees, big.mark = ","),
          format(ls$Employees, big.mark = ",")),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Rates per 100 FTE-years}} \\\\[3pt]",
  sprintf("Total injuries & %.2f & %.2f \\\\",
          hs$`Injury Rate`, ls$`Injury Rate`),
  sprintf("Respiratory conditions & %.3f & %.3f \\\\",
          hs$`Respiratory Rate`, ls$`Respiratory Rate`),
  sprintf("Hearing loss & %.3f & %.3f \\\\",
          hs$`Hearing Loss Rate`, ls$`Hearing Loss Rate`),
  sprintf("Skin disorders & %.3f & %.3f \\\\",
          hs$`Skin Disorders Rate`, ls$`Skin Disorders Rate`),
  sprintf("Other illnesses & %.3f & %.3f \\\\",
          hs$`Other Illness Rate`, ls$`Other Illness Rate`),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Rates computed as (count / total hours worked) $\\times$ 200,000.",
  "High-silica subsectors: NAICS 327 (stone, clay, glass, cement), 331 (primary metals),",
  "332 (fabricated metal products). Pre-treatment period: 2016--2018, before OSHA's",
  "crystalline silica standard's engineering controls deadline took effect for general industry (June 2021, first full year 2022).",
  "Source: OSHA Injury Tracking Application Form 300A.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Wrote tab1_summary.tex\n")

## ═══════════════════════════════════════════════════════════════════════
## TABLE 2: Main Results — Triple-Diff and DiD
## ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main results\n")

## Extract coefficients and SEs
get_coef <- function(model, var_name = NULL) {
  ct <- summary(model)$coeftable
  if (is.null(var_name)) var_name <- rownames(ct)[1]
  row <- ct[var_name, , drop = FALSE]
  list(est = row[1, 1], se = row[1, 2], pval = row[1, 4],
       n = model$nobs, r2 = fitstat(model, "ar2")[[1]])
}

m2_c <- get_coef(m2, "hs_nt_post")
m5_c <- get_coef(m5, "high_silica:post")
m6_c <- get_coef(m6, "high_silica:post")

stars <- function(p) {
  if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else ""
}

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Safety Balloon: Does Targeted Regulation Create Cross-Hazard Substitution?}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Triple-Diff & Respiratory & Total Injuries \\\\",
  " & All Hazards & (Targeted) & (Non-Targeted) \\\\",
  "\\midrule",
  sprintf("High-silica $\\times$ Non-targeted $\\times$ Post & %.4f%s & & \\\\",
          m2_c$est, stars(m2_c$pval)),
  sprintf(" & (%.4f) & & \\\\", m2_c$se),
  sprintf("High-silica $\\times$ Post & & %.4f%s & %.4f%s \\\\",
          m5_c$est, stars(m5_c$pval), m6_c$est, stars(m6_c$pval)),
  sprintf(" & & (%.4f) & (%.4f) \\\\", m5_c$se, m6_c$se),
  "\\midrule",
  "Establishment FE & \\checkmark & \\checkmark & \\checkmark \\\\",
  "Estab.~$\\times$ Hazard FE & \\checkmark & & \\\\",
  "Hazard $\\times$ Year FE & \\checkmark & & \\\\",
  "Estab.~$\\times$ Year FE & \\checkmark & & \\\\",
  "Year FE & & \\checkmark & \\checkmark \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          format(m2_c$n, big.mark = ","),
          format(m5_c$n, big.mark = ","),
          format(m6_c$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column 1 reports the triple-difference estimate: the",
  "differential change in non-targeted hazard categories (injuries, hearing loss,",
  "skin disorders, other illnesses) relative to the targeted category (respiratory",
  "conditions) at high-silica establishments vs.\\ low-silica establishments,",
  "before vs.\\ after the 2018 silica standard. Columns 2--3 report",
  "difference-in-differences for individual hazard categories.",
  "Rates per 100 FTE-years. Standard errors clustered at establishment level in parentheses.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("  Wrote tab2_main.tex\n")

## ═══════════════════════════════════════════════════════════════════════
## TABLE 3: Event Study
## ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Event study\n")

es_ct <- summary(m3)$coeftable
es_names <- c("eym5", "eym4", "eym3", "eym2", "eym1", "eyp1", "eyp2", "eyp3")
es_labels <- c("$t - 5$ (2016)", "$t - 4$ (2017)", "$t - 3$ (2018)", "$t - 2$ (2019)",
               "$t - 1$ (2020)", "$t + 1$ (2022)", "$t + 2$ (2023)", "$t + 3$ (2024)")

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Triple-Difference Coefficients by Year}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time (Year) & Estimate & SE \\\\",
  "\\midrule"
)

for (i in seq_along(es_names)) {
  nm <- es_names[i]
  est <- es_ct[nm, 1]
  se <- es_ct[nm, 2]
  pv <- es_ct[nm, 4]
  tab3_tex <- c(tab3_tex,
    sprintf("%s & %.4f%s & (%.4f) \\\\", es_labels[i], est, stars(pv), se))
}

tab3_tex <- c(tab3_tex,
  "\\midrule",
  "$t = 0$ (2021) & \\multicolumn{2}{c}{[Base year]} \\\\",
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(m3$nobs, big.mark = ",")),
  "Estab.$\\times$Hazard + Hazard$\\times$Year + Estab.$\\times$Year FE & \\multicolumn{2}{c}{\\checkmark} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient is the triple-difference interaction",
  "(High-silica $\\times$ Non-targeted hazard) at event time $k$ relative to $t = 0$ (2018).",
  "Pre-treatment years $t - 2$ and $t - 1$ test for differential pre-trends.",
  "COVID pandemic in 2020--2021 may affect coefficients at $t + 2$ and $t + 3$.",
  "Standard errors clustered at establishment level.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("  Wrote tab3_eventstudy.tex\n")

## ═══════════════════════════════════════════════════════════════════════
## TABLE 4: Robustness
## ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Robustness\n")

r1_c <- get_coef(r1, "hs_nt_post")
r2_c <- get_coef(r2, "hs_nt_post")
r3_c <- get_coef(r3, "hs_nt_post")

## R4 (DAFW)
r4_ct <- summary(r4)$coeftable
r4_c <- list(est = r4_ct[1, 1], se = r4_ct[1, 2], pval = r4_ct[1, 4],
             n = r4$nobs)

## R5a (log injuries)
r5a_ct <- summary(r5a)$coeftable
r5a_c <- list(est = r5a_ct[1, 1], se = r5a_ct[1, 2], pval = r5a_ct[1, 4],
              n = r5a$nobs)

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness of the Cross-Hazard Substitution Test}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Triple-Difference Variants}} \\\\[3pt]",
  sprintf("Baseline (Table~\\ref{tab:main}, Col.~1) & %.4f & (%.4f) & %s \\\\",
          m2_c$est, m2_c$se, format(m2_c$n, big.mark = ",")),
  sprintf("Excl.\\ COVID years (2020--2021) & %.4f & (%.4f) & %s \\\\",
          r1_c$est, r1_c$se, format(r1_c$n, big.mark = ",")),
  sprintf("Broader silica def.\\ (add NAICS 321/324) & %.4f & (%.4f) & %s \\\\",
          r2_c$est, r2_c$se, format(r2_c$n, big.mark = ",")),
  sprintf("Narrower silica def.\\ (NAICS 327 only) & %.3f & (%.3f) & %s \\\\",
          r3_c$est, r3_c$se, format(r3_c$n, big.mark = ",")),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative Outcome Measures}} \\\\[3pt]",
  sprintf("Days away from work (DAFW) rate & %.3f%s & (%.3f) & %s \\\\",
          r4_c$est, stars(r4_c$pval), r4_c$se, format(r4_c$n, big.mark = ",")),
  sprintf("Log(injuries + 1) & %.4f%s & (%.4f) & %s \\\\",
          r5a_c$est, stars(r5a_c$pval), r5a_c$se, format(r5a_c$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A varies the triple-difference specification. All include",
  "establishment$\\times$hazard, hazard$\\times$year, and establishment$\\times$year fixed effects.",
  "Panel B reports DiD for high-silica$\\times$post with establishment and year FE only.",
  "Standard errors clustered at establishment level.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_robust.tex"))
cat("  Wrote tab4_robust.tex\n")

## ═══════════════════════════════════════════════════════════════════════
## TABLE F1: Standardized Effect Size (SDE) Appendix
## ═══════════════════════════════════════════════════════════════════════
cat("Generating Table F1: SDE appendix\n")

## Compute SDE for each outcome
## SDE = β̂ / SD(Y)  where SD(Y) is pre-treatment SD
pre_data <- mfg[post == 0]

## Outcome 1: Triple-diff (all hazards)
## The triple-diff is on rate_w which pools all hazard categories
## For SDE, use the pre-treatment SD of hazard rates
hazard_vars <- c("total_injuries_rate", "total_respiratory_conditions_rate",
                  "total_hearing_loss_rate", "total_skin_disorders_rate",
                  "total_other_illnesses_rate")
pre_rates <- unlist(pre_data[, ..hazard_vars])
pre_rates_w <- pmin(pmax(pre_rates, 0), quantile(pre_rates, 0.99, na.rm = TRUE))
sd_all <- sd(pre_rates_w, na.rm = TRUE)

## Outcome 2: Respiratory rate
sd_resp <- sd(pmin(pmax(pre_data$total_respiratory_conditions_rate, 0),
              quantile(pre_data$total_respiratory_conditions_rate, 0.99, na.rm = TRUE)),
              na.rm = TRUE)

## Outcome 3: Total injury rate
sd_inj <- sd(pmin(pmax(pre_data$total_injuries_rate, 0),
             quantile(pre_data$total_injuries_rate, 0.99, na.rm = TRUE)),
             na.rm = TRUE)

## Outcome 4: DAFW rate
sd_dafw <- sd(pmin(pmax(pre_data$dafw_rate <- as.numeric(pre_data$total_dafw_days) / pre_data$hours * 200000,
              0), quantile(pre_data$dafw_rate, 0.99, na.rm = TRUE)), na.rm = TRUE)

## Compute SDEs
sde_triple <- m2_c$est / sd_all
se_sde_triple <- m2_c$se / sd_all

sde_resp <- m5_c$est / sd_resp
se_sde_resp <- m5_c$se / sd_resp

sde_inj <- m6_c$est / sd_inj
se_sde_inj <- m6_c$se / sd_inj

sde_dafw <- r4_c$est / sd_dafw
se_sde_dafw <- r4_c$se / sd_dafw

## Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

## Size heterogeneity
m4_ct <- summary(m4)$coeftable
sde_small <- m4_ct["hs_nt_post_small", 1] / sd_all
se_sde_small <- m4_ct["hs_nt_post_small", 2] / sd_all
sde_large <- m4_ct["hs_nt_post_large", 1] / sd_all
se_sde_large <- m4_ct["hs_nt_post_large", 2] / sd_all

## Build SDE table
sde_rows <- list(
  list("Cross-hazard substitution (DDD)", m2_c$est, m2_c$se, sd_all,
       sde_triple, se_sde_triple, classify_sde(sde_triple)),
  list("Respiratory conditions (DiD)", m5_c$est, m5_c$se, sd_resp,
       sde_resp, se_sde_resp, classify_sde(sde_resp)),
  list("Total injuries (DiD)", m6_c$est, m6_c$se, sd_inj,
       sde_inj, se_sde_inj, classify_sde(sde_inj)),
  list("Days away from work (DiD)", r4_c$est, r4_c$se, sd_dafw,
       sde_dafw, se_sde_dafw, classify_sde(sde_dafw))
)

hetero_rows <- list(
  list("Small firms ($<$500 emp.)", m4_ct["hs_nt_post_small", 1],
       m4_ct["hs_nt_post_small", 2], sd_all,
       sde_small, se_sde_small, classify_sde(sde_small)),
  list("Large firms ($\\geq$500 emp.)", m4_ct["hs_nt_post_large", 1],
       m4_ct["hs_nt_post_large", 2], sd_all,
       sde_large, se_sde_large, classify_sde(sde_large))
)

## --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does OSHA's 2018 crystalline silica standard, ",
  "which targeted respiratory hazards in manufacturing, cause cross-hazard injury ",
  "substitution to non-targeted hazard categories within the same establishments? ",
  "\\textbf{Policy mechanism:} The standard reduced the permissible exposure limit for ",
  "respirable crystalline silica from 250 to 50 $\\mu$g/m$^3$ in general industry, ",
  "requiring engineering controls, respiratory protection programs, medical surveillance, ",
  "and exposure assessments---imposing substantial compliance costs on silica-intensive manufacturers. ",
  "\\textbf{Outcome definition:} Injury/illness rates per 100 full-time equivalent workers ",
  "(count $\\div$ total hours worked $\\times$ 200,000), separately by hazard category ",
  "(total injuries, respiratory conditions, hearing loss, skin disorders, other illnesses). ",
  "\\textbf{Treatment:} Binary: high-silica manufacturing (NAICS 327, 331, 332) versus ",
  "low-silica manufacturing (all other NAICS 31--33 subsectors). ",
  "\\textbf{Data:} OSHA Injury Tracking Application Form 300A, 2016--2024, ",
  "establishment-year level, 254,933 observations from 43,954 manufacturing establishments. ",
  "\\textbf{Method:} Triple-difference (high-silica $\\times$ non-targeted hazard $\\times$ post-2021) ",
  "with establishment$\\times$hazard, hazard$\\times$year, and establishment$\\times$year fixed effects; ",
  "standard errors clustered at establishment level. ",
  "\\textbf{Sample:} Manufacturing establishments (NAICS 31--33) present in the ITA for ",
  "$\\geq$4 years with positive employment and hours; excludes construction and services. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (r in sde_rows) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r[[1]], r[[2]], r[[3]], r[[4]], r[[5]], r[[6]], r[[7]]))
}

tabF1_tex <- c(tabF1_tex,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (firm size, cross-hazard substitution)}} \\\\[3pt]"
)

for (r in hetero_rows) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r[[1]], r[[2]], r[[3]], r[[4]], r[[5]], r[[6]], r[[7]]))
}

tabF1_tex <- c(tabF1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Wrote tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
