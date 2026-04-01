## ==============================================================
## 05_tables.R — apep_1293
## Generate all LaTeX tables
## ==============================================================

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel[, mun_code := as.character(mun_code)]
sumstats <- fread("data/summary_stats.csv")
models <- readRDS("data/main_models.rds")
es_coefs <- fread("data/event_study_coefs.csv")
rob_models <- readRDS("data/robustness_models.rds")

dir.create("tables", showWarnings = FALSE)

## ------------------------------------------------------------------
## Table 1: Summary Statistics
## ------------------------------------------------------------------

cat("=== Table 1: Summary Statistics ===\n")

fire <- panel[cause_group == "firearm_homicide"]
nfire <- panel[cause_group == "nonfirearm_homicide"]

# Pre-period stats
pre <- fire[year < 2019]
post <- fire[year >= 2019]

# Compute means for treated and control
treated_pre <- pre[has_club == 1, .(
  fire_rate = weighted.mean(rate, population),
  pop = mean(population),
  deaths = mean(deaths)
)]
control_pre <- pre[has_club == 0, .(
  fire_rate = weighted.mean(rate, population),
  pop = mean(population),
  deaths = mean(deaths)
)]

# Overall stats
tab1 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Club Municipalities} & \\multicolumn{2}{c}{No-Club Municipalities} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Mean & SD & Mean & SD \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Pre-Treatment (2013--2018)}} \\\\[3pt]
Firearm homicide rate (per 100K) & %.2f & %.2f & %.2f & %.2f \\\\
Non-firearm homicide rate (per 100K) & %.2f & %.2f & %.2f & %.2f \\\\
Population (thousands) & %.1f & %.1f & %.1f & %.1f \\\\
Firearm deaths per municipality-year & %.2f & %.2f & %.2f & %.2f \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Treatment Intensity}} \\\\[3pt]
Shooting clubs in 2018 & %.2f & %.2f & 0 & 0 \\\\
Club density (per 100K, 2018) & %.2f & %.2f & 0 & 0 \\\\[6pt]
\\midrule
Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
Municipality-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{flushleft}\\small
\\textit{Notes:} Statistics computed over the pre-treatment period (2013--2018). Club municipalities are those with at least one registered shooting club (CNAE 9312-3/00) in 2018. Population-weighted means for rates. Source: DATASUS SIM, IBGE population estimates, Receita Federal CNPJ via Base dos Dados.
\\end{flushleft}
\\end{table}
",
  # Treated pre stats
  pre[has_club == 1, weighted.mean(rate, population)],
  pre[has_club == 1, sd(rate)],
  pre[has_club == 0, weighted.mean(rate, population)],
  pre[has_club == 0, sd(rate)],
  # Non-firearm
  panel[cause_group == "nonfirearm_homicide" & year < 2019 & has_club == 1,
        weighted.mean(rate, population)],
  panel[cause_group == "nonfirearm_homicide" & year < 2019 & has_club == 1, sd(rate)],
  panel[cause_group == "nonfirearm_homicide" & year < 2019 & has_club == 0,
        weighted.mean(rate, population)],
  panel[cause_group == "nonfirearm_homicide" & year < 2019 & has_club == 0, sd(rate)],
  # Population
  pre[has_club == 1, mean(population / 1000)],
  pre[has_club == 1, sd(population / 1000)],
  pre[has_club == 0, mean(population / 1000)],
  pre[has_club == 0, sd(population / 1000)],
  # Deaths
  pre[has_club == 1, mean(deaths)],
  pre[has_club == 1, sd(deaths)],
  pre[has_club == 0, mean(deaths)],
  pre[has_club == 0, sd(deaths)],
  # Clubs
  pre[has_club == 1 & year == 2018, mean(clubs_2018)],
  pre[has_club == 1 & year == 2018, sd(clubs_2018)],
  pre[has_club == 1 & year == 2018, mean(club_density)],
  pre[has_club == 1 & year == 2018, sd(club_density)],
  # Ns
  uniqueN(pre[has_club == 1]$mun_code),
  uniqueN(pre[has_club == 0]$mun_code),
  format(nrow(fire[has_club == 1]), big.mark = ","),
  format(nrow(fire[has_club == 0]), big.mark = ",")
)

writeLines(tab1, "tables/tab1_summary.tex")

## ------------------------------------------------------------------
## Table 2: Main Results
## ------------------------------------------------------------------

cat("=== Table 2: Main Results ===\n")

# Run all specs fresh for clean table
fire_all <- panel[cause_group == "firearm_homicide"]
spec1 <- feols(rate ~ post2019_clubs | mun_code + year,
               data = fire_all, cluster = ~mun_code)
spec2 <- feols(rate ~ i(post_2019, has_club) | mun_code + year,
               data = fire_all, cluster = ~mun_code)

# With Post2023 separation
fire_all[, post2023_clubs := post_2023 * club_density]
fire_all[, post2023_hasclub := post_2023 * has_club]

spec3 <- feols(rate ~ post2019_clubs + post2023_clubs | mun_code + year,
               data = fire_all, cluster = ~mun_code)
spec4 <- feols(rate ~ i(post_2019, has_club) + i(post_2023, has_club) | mun_code + year,
               data = fire_all, cluster = ~mun_code)

# DDD
panel[, post2019_clubs_firearm := post_2019 * club_density * firearm]
ddd5 <- feols(rate ~ post2019_clubs_firearm |
                mun_code^cause_group + year^cause_group + mun_code^year,
              data = panel, cluster = ~mun_code)

options("modelsummary_format_numeric_latex" = "plain")
modelsummary(
  list("(1)" = spec1, "(2)" = spec2, "(3)" = spec3, "(4)" = spec4, "(5)" = ddd5),
  output = "tables/tab2_main.tex",
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  gof_map = c("nobs", "adj.r.squared"),
  title = "Firearm Liberalization and Homicide: Main Results",
  escape = FALSE
)

## ------------------------------------------------------------------
## Table 3: Event Study Coefficients
## ------------------------------------------------------------------

cat("=== Table 3: Event Study ===\n")

es <- feols(rate ~ i(year, club_density, ref = 2018) | mun_code + year,
            data = fire_all, cluster = ~mun_code)

es_dt <- data.table(
  year = 2013:2023,
  coef = c(coef(es)[1:5], 0, coef(es)[6:10]),
  se = c(se(es)[1:5], 0, se(es)[6:10])
)
es_dt[, stars := fcase(
  abs(coef / se) > 2.576, "***",
  abs(coef / se) > 1.96, "**",
  abs(coef / se) > 1.645, "*",
  default = ""
)]
es_dt[year == 2018, stars := ""]
es_dt[, ci_lo := coef - 1.96 * se]
es_dt[, ci_hi := coef + 1.96 * se]

tab3 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Event Study: Firearm Homicide Rate $\\times$ Club Density}
\\label{tab:event_study}
\\begin{tabular}{lccc}
\\toprule
Year & Coefficient & SE & 95\\%% CI \\\\
\\midrule
%s
\\midrule
\\multicolumn{4}{l}{Reference year: 2018. Observations: %s. $R^2$: %.4f} \\\\
\\bottomrule
\\end{tabular}
\\begin{flushleft}\\small
\\textit{Notes:} Each coefficient represents the interaction between year indicator and pre-2019 shooting club density (per 100K population). Municipality and year fixed effects absorbed. Standard errors clustered at the municipality level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.
\\end{flushleft}
\\end{table}
",
  paste(apply(es_dt, 1, function(r) {
    if (r["year"] == "2018") {
      sprintf("%s & [Reference] & --- & --- \\\\", r["year"])
    } else {
      sprintf("%s & %.4f%s & (%.4f) & [%.3f, %.3f] \\\\",
              r["year"], as.numeric(r["coef"]), r["stars"],
              as.numeric(r["se"]),
              as.numeric(r["ci_lo"]), as.numeric(r["ci_hi"]))
    }
  }), collapse = "\n"),
  format(nobs(es), big.mark = ","),
  fitstat(es, "r2")$r2
)

writeLines(tab3, "tables/tab3_event_study.tex")

## ------------------------------------------------------------------
## Table 4: Robustness
## ------------------------------------------------------------------

cat("=== Table 4: Robustness ===\n")

# Placebo
nf_all <- panel[cause_group == "nonfirearm_homicide"]
rob1 <- feols(rate ~ post2019_clubs | mun_code + year,
              data = nf_all, cluster = ~mun_code)

# Pop-weighted
rob2 <- feols(rate ~ post2019_clubs | mun_code + year,
              data = fire_all, cluster = ~mun_code, weights = ~population)

# State-clustered
fire_all[, state_code := substr(mun_code, 1, 2)]
rob3 <- feols(rate ~ post2019_clubs | mun_code + year,
              data = fire_all, cluster = ~state_code)

# Log deaths
fire_all[, log_deaths := log(deaths + 1)]
rob4 <- feols(log_deaths ~ post2019_clubs | mun_code + year,
              data = fire_all, cluster = ~mun_code)

modelsummary(
  list("Firearm\n(Main)" = spec1,
       "Non-Firearm\n(Placebo)" = rob1,
       "Pop-Weighted" = rob2,
       "State SE" = rob3,
       "Log Deaths" = rob4),
  output = "tables/tab4_robustness.tex",
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  gof_map = c("nobs", "adj.r.squared"),
  title = "Robustness Checks: Continuous Treatment (Club Density)",
  escape = FALSE
)

## ------------------------------------------------------------------
## Table F1: SDE Appendix
## ------------------------------------------------------------------

cat("=== Table F1: SDE Appendix ===\n")

# Compute SDEs
fire_pre <- fire_all[year < 2019]
sd_fire_rate <- sd(fire_pre$rate)
sd_nf_rate <- sd(nf_all[year < 2019]$rate)

# Main specs
sde_main <- abs(coef(spec1)) / sd_fire_rate
sde_placebo <- abs(coef(rob1)) / sd_nf_rate

# DDD
sde_ddd <- abs(coef(ddd5)) / sd(panel[year < 2019]$rate)

# Pop-weighted
sde_pw <- abs(coef(rob2)) / sd_fire_rate

# Heterogeneity: large cities
large <- fire_all[pop_2018 > quantile(fire_all$pop_2018, 2/3, na.rm = TRUE)]
spec_large <- feols(rate ~ post2019_clubs | mun_code + year,
                    data = large, cluster = ~mun_code)
sde_large <- abs(coef(spec_large)) / sd(large[year < 2019]$rate)

# Classification function
classify_sde <- function(x) {
  if (abs(x) > 0.15) return("Large")
  if (abs(x) > 0.05) return("Moderate")
  if (abs(x) > 0.005) return("Small")
  return("Null")
}

tabF1 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Standardized Distributional Effects (SDE)}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
Firearm homicide rate & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
Non-firearm homicide (placebo) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
DDD (firearm $-$ non-firearm) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]
Large municipalities ($>$67th pctile) & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
Population-weighted & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{flushleft}\\small
\\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$. Classification: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). Classification refers to magnitude, not statistical significance.

\\textbf{Field:} Country: Brazil.
\\textbf{Research question:} Does firearm liberalization increase homicide, and does restriction reverse it?
\\textbf{Policy mechanism:} Legal firearms supply expansion via shooting club proliferation and registration relaxation.
\\textbf{Outcome definition:} Firearm homicide rate per 100,000 population (ICD-10 X93--X95).
\\textbf{Treatment:} Pre-2019 shooting club density (clubs per 100K), interacted with post-2019 national policy indicator.
\\textbf{Data:} DATASUS Mortality Information System (SIM), IBGE population estimates, Receita Federal CNPJ (2013--2023).
\\textbf{Method:} Shift-share difference-in-differences with triple-difference falsification.
\\textbf{Sample:} 5,570 municipalities $\\times$ 11 years = 61,270 municipality-year observations (firearm); 122,540 for DDD.
\\end{flushleft}
\\end{table}
",
  coef(spec1), se(spec1), sd_fire_rate, sde_main, se(spec1)/sd_fire_rate, classify_sde(sde_main),
  coef(rob1), se(rob1), sd_nf_rate, sde_placebo, se(rob1)/sd_nf_rate, classify_sde(sde_placebo),
  coef(ddd5), se(ddd5), sd(panel[year < 2019]$rate), sde_ddd, se(ddd5)/sd(panel[year < 2019]$rate), classify_sde(sde_ddd),
  coef(spec_large), se(spec_large), sd(large[year < 2019]$rate), sde_large, se(spec_large)/sd(large[year < 2019]$rate), classify_sde(sde_large),
  coef(rob2), se(rob2), sd_fire_rate, sde_pw, se(rob2)/sd_fire_rate, classify_sde(sde_pw)
)

writeLines(tabF1, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat(paste(list.files("tables/", pattern = "\\.tex$"), collapse = "\n"))
cat("\n")
