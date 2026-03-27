## 05_tables.R — Generate all LaTeX tables for CROWN Act paper
## apep_1066 v1

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/results.RData")
load("../data/robustness.RData")

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================

pre <- panel %>% filter(year < 2019)
post <- panel %>% filter(year >= 2019)

make_sumstat_row <- function(data, race_val, sex_val, label) {
  sub <- data %>% filter(race == race_val, sex == sex_val)
  tibble(
    Group = label,
    `Mean Earnings` = sprintf("\\$%s", formatC(mean(sub$median_earnings, na.rm = TRUE),
                                                format = "f", digits = 0, big.mark = ",")),
    `SD Earnings` = sprintf("(%s)", formatC(sd(sub$median_earnings, na.rm = TRUE),
                                             format = "f", digits = 0, big.mark = ",")),
    `Mean Emp. Rate` = sprintf("%.3f", mean(sub$emp_rate, na.rm = TRUE)),
    `SD Emp. Rate` = sprintf("(%.3f)", sd(sub$emp_rate, na.rm = TRUE)),
    `N States` = as.character(n_distinct(sub$state_fips))
  )
}

tab1_rows <- bind_rows(
  tibble(Group = "\\textit{Panel A: Pre-CROWN Act (2017--2018)}",
         `Mean Earnings` = "", `SD Earnings` = "", `Mean Emp. Rate` = "",
         `SD Emp. Rate` = "", `N States` = ""),
  make_sumstat_row(pre, "Black", "female", "\\quad Black Women"),
  make_sumstat_row(pre, "Black", "male", "\\quad Black Men"),
  make_sumstat_row(pre, "White", "female", "\\quad White Women"),
  make_sumstat_row(pre, "White", "male", "\\quad White Men"),
  tibble(Group = "\\textit{Panel B: Post-CROWN Act (2019--2023)}",
         `Mean Earnings` = "", `SD Earnings` = "", `Mean Emp. Rate` = "",
         `SD Emp. Rate` = "", `N States` = ""),
  make_sumstat_row(post, "Black", "female", "\\quad Black Women"),
  make_sumstat_row(post, "Black", "male", "\\quad Black Men"),
  make_sumstat_row(post, "White", "female", "\\quad White Women"),
  make_sumstat_row(post, "White", "male", "\\quad White Men")
)

## Write Table 1
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Median Earnings and Employment by Race and Sex}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Group & Mean Earnings & SD & Emp.\\ Rate & SD & States \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(tab1_rows))) {
  r <- tab1_rows[i, ]
  tab1_tex <- c(tab1_tex,
    sprintf("%s & %s & %s & %s & %s & %s \\\\",
            r$Group, r$`Mean Earnings`, r$`SD Earnings`,
            r$`Mean Emp. Rate`, r$`SD Emp. Rate`, r$`N States`))
  if (i == 5) tab1_tex <- c(tab1_tex, "\\midrule")
}

tab1_tex <- c(tab1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Median earnings (dollars) and employment-to-population ratios from the American Community Survey 1-year estimates. Black and White non-Hispanic populations. Pre-period: 2017--2018 (before any CROWN Act adoption). Post-period: 2019--2023 (excluding 2020 due to ACS COVID non-response). States with non-null estimates for the relevant race-sex group.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

## ============================================================
## TABLE 2: Main DDD Results
## ============================================================

## Extract coefficients
get_results <- function(model, coef_name) {
  idx <- which(names(coef(model)) == coef_name)
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA, stars = ""))
  b <- coef(model)[idx]
  s <- se(model)[idx]
  p <- pvalue(model)[idx]
  st <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, stars = st)
}

r1 <- get_results(m1_earn, "crown_black")
r2 <- get_results(m2_earn, "crown_black")
r2f <- get_results(m2_earn, "crown_active:female")
r2bf <- get_results(m2_earn, "crown_black:female")
r3 <- get_results(m3_emp, "crown_black")
r4 <- get_results(m4_emp, "crown_black")
r4f <- get_results(m4_emp, "crown_active:female")
r4bf <- get_results(m4_emp, "crown_black:female")

fmt_b <- function(x, d = 3) ifelse(is.na(x$b), "", sprintf("%.${d}f%s", x$b, x$stars))
fmt_se <- function(x, d = 3) ifelse(is.na(x$se), "", sprintf("(%.${d}f)", x$se))

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Texture Penalty: CROWN Act Effects on Black Worker Outcomes}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Median Earnings} & \\multicolumn{2}{c}{Employment Rate} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("CROWN $\\times$ Black & %.3f%s & %.3f%s & %.4f%s & %.4f%s \\\\",
          r1$b, r1$stars, r2$b, r2$stars, r3$b, r3$stars, r4$b, r4$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.4f) & (%.4f) \\\\",
          r1$se, r2$se, r3$se, r4$se),
  sprintf("CROWN $\\times$ Female & & %.3f%s & & %.4f%s \\\\",
          r2f$b, r2f$stars, r4f$b, r4f$stars),
  sprintf(" & & (%.3f) & & (%.4f) \\\\",
          r2f$se, r4f$se),
  sprintf("CROWN $\\times$ Black $\\times$ Female & & %.3f%s & & %.4f%s \\\\",
          r2bf$b, r2bf$stars, r4bf$b, r4bf$stars),
  sprintf(" & & (%.3f) & & (%.4f) \\\\",
          r2bf$se, r4bf$se),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(m1_earn), big.mark = ","),
          formatC(nobs(m2_earn), big.mark = ","),
          formatC(nobs(m3_emp), big.mark = ","),
          formatC(nobs(m4_emp), big.mark = ",")),
  "State $\\times$ Race FE & Yes & Yes & Yes & Yes \\\\",
  "Year $\\times$ Race FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Clusters & %d & %d & %d & %d \\\\",
          length(unique(panel$state_fips)), length(unique(panel$state_fips)),
          length(unique(panel$state_fips)), length(unique(panel$state_fips))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Triple-difference estimates of CROWN Act effects on Black worker outcomes. The sample is a state $\\times$ year $\\times$ race $\\times$ sex panel from ACS 1-year estimates, 2017--2023 (excluding 2020). Columns (1) and (3) estimate the differential effect for Black workers (both sexes) in CROWN Act states. Columns (2) and (4) add interactions to test whether Black women experience additional effects. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## ============================================================
## TABLE 3: Event Study (Callaway-Sant'Anna)
## ============================================================

es_df <- data.frame(
  event_time = es_earn$egt,
  att_earn = es_earn$att.egt,
  se_earn = es_earn$se.egt
)

## Merge employment event study
es_emp_df <- data.frame(
  event_time = es_emp$egt,
  att_emp = es_emp$att.egt,
  se_emp = es_emp$se.egt
)

es_merged <- merge(es_df, es_emp_df, by = "event_time", all = TRUE) %>%
  arrange(event_time)

## Stars
add_stars <- function(b, se) {
  p <- 2 * pnorm(-abs(b / se))
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of CROWN Act on Black Workers}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time & Log Earnings & Employment Rate \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_merged))) {
  r <- es_merged[i, ]
  st_e <- add_stars(r$att_earn, r$se_earn)
  st_p <- add_stars(r$att_emp, r$se_emp)
  tab3_tex <- c(tab3_tex,
    sprintf("$t %s %d$ & %.3f%s & %.4f%s \\\\",
            ifelse(r$event_time >= 0, "+", ""), r$event_time,
            r$att_earn, st_e, r$att_emp, st_p),
    sprintf(" & (%.3f) & (%.4f) \\\\",
            r$se_earn, r$se_emp)
  )
}

tab3_tex <- c(tab3_tex,
  "\\midrule",
  sprintf("Overall ATT & %.3f & %.4f \\\\",
          att_earn$overall.att, att_emp$overall.att),
  sprintf(" & (%.3f) & (%.4f) \\\\",
          att_earn$overall.se, att_emp$overall.se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) event-study estimates. Treatment groups defined by year of CROWN Act adoption (2019, 2020, 2021, 2022, 2023). Control group: never-treated states. Universal base period. Event time 0 is the year of adoption. Standard errors based on analytical formula from \\citet{callaway2021difference}. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

## ============================================================
## TABLE 4: Robustness
## ============================================================

## Get main result for reference
main_b <- coef(m1_earn)["crown_black"]
main_se <- se(m1_earn)["crown_black"]
main_p <- pvalue(m1_earn)["crown_black"]

## Female-only result
fonly_b <- coef(m_female_only)["crown_black"]
fonly_se <- se(m_female_only)["crown_black"]
fonly_p <- pvalue(m_female_only)["crown_black"]

## Placebo
plac_b <- coef(m_placebo)["crown_placebo"]
plac_se <- se(m_placebo)["crown_placebo"]
plac_p <- pvalue(m_placebo)["crown_placebo"]

## Heterogeneity
het_high_b <- coef(m_het)["crown_black_high"]
het_high_se <- se(m_het)["crown_black_high"]
het_low_b <- coef(m_het)["crown_black_low"]
het_low_se <- se(m_het)["crown_black_low"]

stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Heterogeneity}",
  "\\label{tab:robust}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE \\\\",
  "\\midrule",
  "\\textit{Panel A: Alternative Specifications} & & \\\\",
  sprintf("\\quad Baseline (CROWN $\\times$ Black) & %.3f%s & (%.3f) \\\\",
          main_b, stars_fn(main_p), main_se),
  sprintf("\\quad Black Women vs.\\ White Women Only & %.3f%s & (%.3f) \\\\",
          fonly_b, stars_fn(fonly_p), fonly_se)
)

## LOO results
for (i in seq_len(nrow(loo_df))) {
  st_name <- c("06" = "CA", "36" = "NY", "34" = "NJ")[loo_df$dropped_state[i]]
  tab4_tex <- c(tab4_tex,
    sprintf("\\quad Drop %s & %.3f%s & (%.3f) \\\\",
            st_name, loo_df$coef[i], stars_fn(loo_df$pval[i]), loo_df$se[i]))
}

tab4_tex <- c(tab4_tex,
  "\\midrule",
  "\\textit{Panel B: Placebo} & & \\\\",
  sprintf("\\quad CROWN $\\times$ White Male & %.3f%s & (%.3f) \\\\",
          plac_b, stars_fn(plac_p), plac_se),
  "\\midrule",
  "\\textit{Panel C: Heterogeneity by Black Emp.\\ Rate} & & \\\\",
  sprintf("\\quad Above-Median States & %.3f%s & (%.3f) \\\\",
          het_high_b, stars_fn(pvalue(m_het)["crown_black_high"]), het_high_se),
  sprintf("\\quad Below-Median States & %.3f%s & (%.3f) \\\\",
          het_low_b, stars_fn(pvalue(m_het)["crown_black_low"]), het_low_se),
  "\\midrule",
  "\\textit{Panel D: Inference} & & \\\\",
  sprintf("\\quad Randomization Inference $p$-value & \\multicolumn{2}{c}{%.3f} \\\\", ri_pvalue),
  sprintf("\\quad Permutations & \\multicolumn{2}{c}{%d} \\\\", length(perm_coefs)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports the baseline CROWN $\\times$ Black coefficient from Table \\ref{tab:main} alongside alternative specifications. Leave-one-out drops each early-adopting state (2019 cohort). Panel B reports a placebo test using white male outcomes. Panel C splits treated states by pre-treatment Black employment rate. Panel D reports a randomization inference $p$-value from 500 permutations of treatment assignment. All specifications include state $\\times$ race, year $\\times$ race, and state $\\times$ year fixed effects with state-clustered standard errors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")
cat("Table 4 written.\n")

## ============================================================
## TABLE F1: SDE APPENDIX (MANDATORY)
## ============================================================

## Compute SDEs for main outcomes
## Panel A: Pooled
sde_earn <- main_b / sd_log_earn
sde_earn_se <- main_se / sd_log_earn

emp_b <- coef(m3_emp)["crown_black"]
emp_se <- se(m3_emp)["crown_black"]
sde_emp <- emp_b / sd_emp_rate
sde_emp_se <- emp_se / sd_emp_rate

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

## Panel B: Heterogeneous (sample splits)
## Split 1: Black women only
female_black <- panel %>% filter(race == "Black", sex == "female", year < 2019)
sd_earn_bw <- sd(female_black$log_earn, na.rm = TRUE)
sd_emp_bw <- sd(female_black$emp_rate, na.rm = TRUE)

## Get female-only results for Black women
bw_earn_b <- coef(m_female_only)["crown_black"]
bw_earn_se <- se(m_female_only)["crown_black"]
sde_bw_earn <- bw_earn_b / sd_earn_bw
sde_bw_earn_se <- bw_earn_se / sd_earn_bw

## Split 2: High Black employment states
het_high_sde <- het_high_b / sd_log_earn
het_high_sde_se <- het_high_se / sd_log_earn
het_low_sde <- het_low_b / sd_log_earn
het_low_sde_se <- het_low_se / sd_log_earn

## Build SDE table
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
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Log Median Earnings & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          main_b, main_se, sd_log_earn, sde_earn, sde_earn_se, classify_sde(sde_earn)),
  sprintf("Employment Rate & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          emp_b, emp_se, sd_emp_rate, sde_emp, sde_emp_se, classify_sde(sde_emp)),
  "\\midrule",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\",
  sprintf("Black Women: Log Earnings & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          bw_earn_b, bw_earn_se, sd_earn_bw, sde_bw_earn, sde_bw_earn_se, classify_sde(sde_bw_earn)),
  sprintf("High Black Emp.\\ States: Log Earn.\\ & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          het_high_b, het_high_se, sd_log_earn, het_high_sde, het_high_sde_se, classify_sde(het_high_sde)),
  "\\bottomrule",
  "\\end{tabular}"
)

## --- SDE notes string (MANDATORY 8 textbf fields) ---
sde_notes <- paste0(
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level CROWN Acts that prohibit workplace discrimination based on hair texture and protective hairstyles improve labor market outcomes for Black workers? ",
  "\\textbf{Policy mechanism:} The CROWN Act (Creating a Respectful and Open World for Natural Hair) explicitly prohibits employers from discriminating against employees or applicants based on hair texture or protective hairstyles associated with race, closing a gap in existing anti-discrimination law that courts had not consistently covered under Title VII. ",
  "\\textbf{Outcome definition:} Log median earnings from ACS table B20017B (Black) and B20017H (White non-Hispanic), measuring full-time year-round median earnings by race and sex; employment-to-population ratio from ACS table B23002B/H for ages 16--64. ",
  "\\textbf{Treatment:} Binary; state adopted a CROWN Act (staggered 2019--2023, 22 states in sample window). ",
  "\\textbf{Data:} American Community Survey 1-year estimates, 2017--2023 (excluding 2020), state-level, approximately 1,200 state $\\times$ year $\\times$ race $\\times$ sex observations. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ year $\\times$ race variation) with state $\\times$ race, year $\\times$ race, and state $\\times$ year fixed effects; standard errors clustered at the state level; Callaway--Sant'Anna (2021) event study for dynamic effects. ",
  "\\textbf{Sample:} All 50 states plus DC with non-null ACS estimates for the relevant race-sex group; 22 CROWN Act states and 29 never-treated states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).\n",
  "\\end{tablenotes}"
)

tabF1_tex <- c(tabF1_tex, sde_notes, "\\end{table}")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
