## 05_tables.R — Generate all tables including SDE appendix
## apep_0841: Poland 500+ and Female Labor Supply

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

cat("=== Generating Tables ===\n")

panel <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/main_models.rds")
rob <- readRDS("../data/robustness_results.rds")

# ─── Table 1: Summary Statistics ───────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

pl <- panel[panel$poland == 1, ]
ctrl <- panel[panel$poland == 0, ]
pl_pre <- pl[pl$post2019 == 0, ]
pl_post <- pl[pl$post2019 == 1, ]
ctrl_pre <- ctrl[ctrl$post2019 == 0, ]
ctrl_post <- ctrl[ctrl$post2019 == 1, ]

make_cell <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return("---")
  sprintf("%.1f (%.1f)", mean(x), sd(x))
}

tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Polish and CEE NUTS2 Regions}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Poland} & \\multicolumn{2}{c}{CEE Controls} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre-2019 & Post-2019 & Pre-2019 & Post-2019 \\\\",
  "\\midrule",
  sprintf("Female employment rate (\\%%) & %s & %s & %s & %s \\\\",
          make_cell(pl_pre$emp_rate_f), make_cell(pl_post$emp_rate_f),
          make_cell(ctrl_pre$emp_rate_f), make_cell(ctrl_post$emp_rate_f)),
  sprintf("Male employment rate (\\%%) & %s & %s & %s & %s \\\\",
          make_cell(pl_pre$emp_rate_m), make_cell(pl_post$emp_rate_m),
          make_cell(ctrl_pre$emp_rate_m), make_cell(ctrl_post$emp_rate_m)),
  sprintf("GDP per capita (EUR) & %s & %s & %s & %s \\\\",
          make_cell(pl_pre$gdp_pc), make_cell(pl_post$gdp_pc),
          make_cell(ctrl_pre$gdp_pc), make_cell(ctrl_post$gdp_pc)),
  sprintf("Gender employment gap (pp) & %s & %s & %s & %s \\\\",
          make_cell(pl_pre$emp_rate_f - pl_pre$emp_rate_m),
          make_cell(pl_post$emp_rate_f - pl_post$emp_rate_m),
          make_cell(ctrl_pre$emp_rate_f - ctrl_pre$emp_rate_m),
          make_cell(ctrl_post$emp_rate_f - ctrl_post$emp_rate_m)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nrow(pl_pre), nrow(pl_post), nrow(ctrl_pre), nrow(ctrl_post)),
  sprintf("NUTS2 regions & %d & %d & %d & %d \\\\",
          length(unique(pl_pre$nuts2)), length(unique(pl_post$nuts2)),
          length(unique(ctrl_pre$nuts2)), length(unique(ctrl_post$nuts2))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Means with standard deviations in parentheses. Poland has 17 NUTS2 regions; CEE controls include Czech Republic (8), Slovakia (4), Hungary (9), Romania (8), and Bulgaria (6). Pre-2019 covers 2010--2018; Post-2019 covers 2019--2023. Gender employment gap is the female minus male employment-to-population ratio for ages 25--64. Source: Eurostat (lfst\\_r\\_lfe2emprt).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ─── Table 2: Main Results ─────────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

# Extract coefficients for clean manual table
get_coef <- function(model, param) {
  cf <- coef(model)[param]
  se <- sqrt(diag(vcov(model)))[param]
  pv <- summary(model)$coeftable[param, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}",
           ifelse(pv < 0.1, "^{*}", "")))
  list(coef = cf, se = se, pval = pv, stars = stars)
}

r1 <- get_coef(models$m1, "poland_post")
r5 <- get_coef(models$m5, "poland_post")
r6 <- get_coef(models$m6, "poland_post")
r3 <- get_coef(models$m3, "poland_intensity_post")

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of 500+ Universalization on Female Employment}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & All CEE & Gender Gap & Visegrad & Triple Diff \\\\",
  "\\midrule",
  sprintf("Poland $\\times$ Post-2019 & %.3f%s & %.3f%s & %.3f%s & \\\\",
          r1$coef, r1$stars, r5$coef, r5$stars, r6$coef, r6$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\",
          r1$se, r5$se, r6$se),
  sprintf("Poland $\\times$ Intensity $\\times$ Post & & & & %.3f%s \\\\",
          r3$coef, r3$stars),
  sprintf(" & & & & (%.3f) \\\\", r3$se),
  "\\midrule",
  sprintf("Outcome & Fem.\\ Emp. & Gap & Fem.\\ Emp. & Fem.\\ Emp. \\\\"),
  sprintf("Controls & All CEE & All CEE & CZ, SK, HU & All CEE \\\\"),
  sprintf("Region FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(models$m1), nobs(models$m5), nobs(models$m6), nobs(models$m3)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(models$m1, "wr2")[[1]],
          fitstat(models$m5, "wr2")[[1]],
          fitstat(models$m6, "wr2")[[1]],
          fitstat(models$m3, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at NUTS2 level in parentheses. Column 1: simple DiD comparing 17 Polish regions to 35 CEE controls. Column 2: outcome is the female minus male employment rate (gender gap), controlling for common labor demand shocks. Column 3: restricts controls to Visegrad countries (Czech Republic, Slovakia, Hungary), the closest structural comparators. Column 4: triple-difference exploiting within-Poland variation in treatment intensity (standardized inverse of pre-2019 total fertility rate). $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ─── Table 3: Event Study ─────────────────────────────────────────────────
cat("Generating Table 3: Event Study...\n")

es_coefs <- read.csv("../data/event_study_coefs.csv")
es_coefs <- es_coefs[order(es_coefs$event_time), ]
es_coefs$stars <- ifelse(abs(es_coefs$estimate / pmax(es_coefs$se, 0.001)) > 2.576, "^{***}",
                  ifelse(abs(es_coefs$estimate / pmax(es_coefs$se, 0.001)) > 1.96, "^{**}",
                  ifelse(abs(es_coefs$estimate / pmax(es_coefs$se, 0.001)) > 1.645, "^{*}", "")))

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Treatment Intensity $\\times$ Year Interactions}",
  "\\label{tab:event_study}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & Coefficient & Std.\\ Error & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_coefs)) {
  if (es_coefs$event_time[i] == -1) {
    tab3_tex <- c(tab3_tex,
      sprintf("$t = %+d$ (ref.) & --- & --- & --- \\\\",
              es_coefs$event_time[i]))
  } else {
    tab3_tex <- c(tab3_tex,
      sprintf("$t = %+d$ & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
              es_coefs$event_time[i],
              es_coefs$estimate[i], es_coefs$stars[i],
              es_coefs$se[i], es_coefs$ci_lo[i], es_coefs$ci_hi[i]))
  }
}

tab3_tex <- c(tab3_tex,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\",
          nrow(panel[panel$poland == 1, ])),
  "Region FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from regressing female employment rate on interactions between standardized treatment intensity (inverse pre-2019 TFR) and event-time indicators, within the 17 Polish NUTS2 regions. Reference period: $t = -1$ (2018). Standard errors clustered at NUTS2 level. The absence of individually significant pre-treatment coefficients is consistent with parallel trends. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_tex, "../tables/tab3_event_study.tex")

# ─── Table 4: Robustness ──────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

r_male <- get_coef(rob$male_placebo_simple, "poland_post")
r_nocov <- get_coef(rob$no_covid, "poland_post")

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Male Emp. & Excl.\\ COVID & Placebo 2016 & Placebo 2017 \\\\",
  "\\midrule",
  sprintf("Poland $\\times$ Post & %.3f%s & %.3f%s & & \\\\",
          r_male$coef, r_male$stars, r_nocov$coef, r_nocov$stars),
  sprintf(" & (%.3f) & (%.3f) & & \\\\", r_male$se, r_nocov$se),
  sprintf("Poland $\\times$ Placebo Post & & & %.3f & %.3f \\\\",
          rob$placebo_years[["2016"]]$coef,
          rob$placebo_years[["2017"]]$coef),
  sprintf(" & & & (%.3f) & (%.3f) \\\\",
          rob$placebo_years[["2016"]]$se,
          rob$placebo_years[["2017"]]$se),
  "\\midrule",
  "Outcome & Male emp. & Fem.\\ emp. & Fem.\\ emp. & Fem.\\ emp. \\\\",
  "Sample & All CEE & Excl.\\ 2020--21 & Pre-2019 & Pre-2019 \\\\",
  "Region FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Permutation $p$-value & & & \\multicolumn{2}{c}{%.3f (intensity)} \\\\",
          rob$permutation_p),
  sprintf("LOO range & & & \\multicolumn{2}{c}{[%.3f, %.3f]} \\\\",
          rob$loo_range[1], rob$loo_range[2]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at NUTS2 level in parentheses. Column 1: male employment as placebo outcome (the 500+ program should not directly affect male labor supply). Column 2: excludes 2020--2021 to remove COVID-19 contamination. Columns 3--4: placebo treatment dates in the pre-period. Permutation $p$-value from 999 random reassignments of treatment intensity across Polish regions. LOO range reports the within-Poland intensity DiD coefficient when each region is dropped in turn. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ─── Table F1: SDE Appendix ───────────────────────────────────────────────
cat("Generating Table F1: Standardized Effect Sizes...\n")

diag <- jsonlite::fromJSON("../data/diagnostics.json")
sd_y_pre <- diag$sd_y_pre

# Use gender gap DiD as primary; Visegrad as secondary; triple-diff as third
coef_gg <- coef(models$m5)["poland_post"]
se_gg <- sqrt(diag(vcov(models$m5)))["poland_post"]
coef_v4 <- coef(models$m6)["poland_post"]
se_v4 <- sqrt(diag(vcov(models$m6)))["poland_post"]
coef_td <- diag$main_coef_triple
se_td <- diag$main_se_triple

sde_gg <- coef_gg / sd_y_pre
sde_gg_se <- se_gg / sd_y_pre
sde_v4 <- coef_v4 / sd_y_pre
sde_v4_se <- se_v4 / sd_y_pre
sde_td <- coef_td / sd_y_pre
sde_td_se <- se_td / sd_y_pre

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Poland. ",
  "\\textbf{Research question:} Does universalizing the Family 500+ child benefit to first children reduce maternal labor force participation? ",
  "\\textbf{Policy mechanism:} In July 2019, Poland removed the income test for first-child eligibility in the 500+ program, creating an unconditional 500 PLN/month transfer to approximately 1.4 million previously-excluded one-child families, equivalent to roughly 22 percent of median net wages in low-income regions. ",
  "\\textbf{Outcome definition:} Female employment-to-population ratio for women aged 25--64, measured annually from Eurostat regional labor force statistics (lfst\\_r\\_lfe2emprt). ",
  "\\textbf{Treatment:} Binary (Poland vs.\\ CEE controls, rows 1--2) and continuous (standardized inverse of pre-2019 total fertility rate at NUTS2 level, proxying for share of one-child families newly eligible, row 3). ",
  "\\textbf{Data:} Eurostat NUTS2 regional statistics, 2010--2023, covering 17 Polish regions and 35 CEE control regions in Czech Republic, Slovakia, Hungary, Romania, and Bulgaria. ",
  "\\textbf{Method:} Two-way fixed effects (region and year), standard errors clustered at NUTS2 level; row 1 uses gender gap (female minus male employment) as outcome. ",
  "\\textbf{Sample:} All NUTS2 regions in Poland plus five CEE comparator countries (row 2 restricts to Visegrad); restricted to years 2010--2023 for balanced panel coverage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Gender gap (all CEE) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          coef_gg, se_gg, sd_y_pre, sde_gg, sde_gg_se, classify_sde(sde_gg)),
  sprintf("Fem.\\ emp.\\ (Visegrad) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          coef_v4, se_v4, sd_y_pre, sde_v4, sde_v4_se, classify_sde(sde_v4)),
  sprintf("Fem.\\ emp.\\ (triple diff) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          coef_td, se_td, sd_y_pre, sde_td, sde_td_se, classify_sde(sde_td)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated successfully.\n")
