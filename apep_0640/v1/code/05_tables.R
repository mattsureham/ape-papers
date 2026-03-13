## 05_tables.R — Generate all LaTeX tables
## apep_0640: E-Verify Mandates and Hispanic Employment

source("00_packages.R")

cat("Loading results...\n")
df <- readRDS("../data/state_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")
sa_emp <- readRDS("../data/sa_emp.rds")
sa_placebo <- readRDS("../data/sa_placebo.rds")
sa_earn <- readRDS("../data/sa_earn.rds")
stacked_did <- readRDS("../data/stacked_did.rds")
sa_noaz <- readRDS("../data/sa_noaz.rds")
sa_early <- readRDS("../data/sa_early.rds")
sa_industry <- readRDS("../data/sa_industry.rds")
ri <- readRDS("../data/ri_results.rds")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment (2003-2007) summary by group
emp_avg <- df %>%
  filter(!is.na(Emp), Emp > 0, year <= 2019, state_fips != 11) %>%
  mutate(
    ethnicity_label = ifelse(ethnicity == "A2", "Hispanic", "Non-Hispanic"),
    group = ifelse(treated, "E-Verify", "Control")
  )

summ <- emp_avg %>%
  filter(year >= 2003, year <= 2007) %>%
  group_by(group, ethnicity_label) %>%
  summarise(
    `Mean Employment` = sprintf("%.0f", mean(Emp)),
    `SD Employment` = sprintf("%.0f", sd(Emp)),
    `Mean Earnings (\\$)` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    `Hiring Rate` = sprintf("%.3f", mean(HirA / Emp, na.rm = TRUE)),
    `Separation Rate` = sprintf("%.3f", mean(Sep / Emp, na.rm = TRUE)),
    States = as.character(n_distinct(state_fips)),
    `State-Quarters` = as.character(n()),
    .groups = "drop"
  )

tab1 <- summ %>%
  pivot_longer(cols = -c(group, ethnicity_label),
               names_to = "Variable", values_to = "value") %>%
  pivot_wider(names_from = c(group, ethnicity_label), values_from = value) %>%
  select(Variable,
         `E-Verify_Hispanic`, `E-Verify_Non-Hispanic`,
         `Control_Hispanic`, `Control_Non-Hispanic`)

tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Pre-Treatment Means (2003--2007)}
\\label{tab:summary}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{E-Verify States} & \\multicolumn{2}{c}{Control States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Hispanic & Non-Hisp. & Hispanic & Non-Hisp. \\\\
\\hline\n"

for (i in seq_len(nrow(tab1))) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Variable[i], " & ",
    tab1$`E-Verify_Hispanic`[i], " & ",
    tab1$`E-Verify_Non-Hispanic`[i], " & ",
    tab1$`Control_Hispanic`[i], " & ",
    tab1$`Control_Non-Hispanic`[i], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
"\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Pre-treatment quarterly means (2003--2007). Employment is average quarterly employment from the Quarterly Workforce Indicators (QWI). Earnings are average quarterly earnings per worker. Hiring and separation rates are quarterly flows divided by employment. E-Verify states: AZ, UT, MS, LA, AL, GA, NC, TN, SC, FL. Control states: all remaining states except DC. Source: Census LEHD/QWI race-by-ethnicity tabulations.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main Results (SA event study summary + stacked DiD)
# ============================================================================
cat("Generating Table 2: Main Results...\n")

# Extract SA ATTs at key horizons
sa_c <- coef(sa_emp)
sa_s <- se(sa_emp)

get_sa <- function(model, periods) {
  cc <- coef(model)
  ss <- se(model)
  names_match <- paste0("year::", periods)
  idx <- match(names_match, names(cc))
  data.frame(
    period = periods,
    coef = ifelse(is.na(idx), NA, cc[idx]),
    se = ifelse(is.na(idx), NA, ss[idx])
  )
}

# Get post-treatment average
post_names <- grep("^year::[0-9]", names(sa_c), value = TRUE)
avg_post_emp <- mean(sa_c[post_names])
avg_post_se_emp <- sqrt(mean(sa_s[post_names]^2))  # conservative

sa_earn_c <- coef(sa_earn)
sa_earn_s <- se(sa_earn)
post_earn <- grep("^year::[0-9]", names(sa_earn_c), value = TRUE)
avg_post_earn <- mean(sa_earn_c[post_earn])
avg_post_se_earn <- sqrt(mean(sa_earn_s[post_earn]^2))

# Stacked DiD
stack_b <- coef(stacked_did)
stack_se <- se(stacked_did)

# Exclude AZ
noaz_c <- coef(sa_noaz)
noaz_post <- grep("^year::[0-9]", names(noaz_c), value = TRUE)
noaz_avg <- mean(noaz_c[noaz_post])
noaz_se <- sqrt(mean(se(sa_noaz)[noaz_post]^2))

stars <- function(b, s) {
  p <- 2 * pnorm(-abs(b / s))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_tex <- sprintf("\\begin{table}[t]
\\centering
\\caption{Effect of E-Verify Mandates on Hispanic Employment and Earnings}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\hline\\hline
 & \\multicolumn{2}{c}{Sun--Abraham} & Stacked & Excl. \\\\
 & Employment & Earnings & DiD & Arizona \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
Average post-treatment & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]
RI $p$-value & %.3f & & & \\\\[6pt]
Observations & %d & %d & %d & %d \\\\
States & 51 & 51 & 51 & 50 \\\\
Treated states & 8 & 8 & 8 & 7 \\\\
Years & 2003--2019 & 2003--2019 & varying & 2003--2019 \\\\
Fixed effects & State, Year & State, Year & Stack$\\times$Year & State, Year \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Each column reports the average post-treatment effect from a Sun and Abraham (2021) interaction-weighted estimator (columns 1--2, 4) or a stacked difference-in-differences with clean 4-year windows (column 3). The dependent variable is log quarterly employment (columns 1, 3, 4) or log average quarterly earnings (column 2) of Hispanic workers at the state level, from Census QWI. Standard errors clustered at the state level in parentheses. The RI $p$-value is from 500 random permutations of treatment assignment. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.
\\end{tablenotes}
\\end{table}\n",
  avg_post_emp, stars(avg_post_emp, avg_post_se_emp),
  avg_post_earn, stars(avg_post_earn, avg_post_se_earn),
  stack_b, stars(stack_b, stack_se),
  noaz_avg, stars(noaz_avg, noaz_se),
  avg_post_se_emp, avg_post_se_earn, stack_se, noaz_se,
  ri$ri_p,
  nobs(sa_emp), nobs(sa_earn), nobs(stacked_did), nobs(sa_noaz))

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Industry Heterogeneity
# ============================================================================
cat("Generating Table 3: Industry Heterogeneity...\n")

hi_c <- coef(sa_industry$sa_hi)
hi_s <- se(sa_industry$sa_hi)
hi_post <- grep("^year::[0-9]", names(hi_c), value = TRUE)
hi_avg <- mean(hi_c[hi_post])
hi_se <- sqrt(mean(hi_s[hi_post]^2))

lo_c <- coef(sa_industry$sa_lo)
lo_s <- se(sa_industry$sa_lo)
lo_post <- grep("^year::[0-9]", names(lo_c), value = TRUE)
lo_avg <- mean(lo_c[lo_post])
lo_se <- sqrt(mean(lo_s[lo_post]^2))

# Placebo: non-Hispanic
plac_c <- coef(sa_placebo)
plac_post <- grep("^year::[0-9]", names(plac_c), value = TRUE)
plac_avg <- mean(plac_c[plac_post])
plac_se <- sqrt(mean(se(sa_placebo)[plac_post]^2))

# Early adopters
early_c <- coef(sa_early)
early_post <- grep("^year::[0-9]", names(early_c), value = TRUE)
early_avg <- mean(early_c[early_post])
early_se <- sqrt(mean(se(sa_early)[early_post]^2))

tab3_tex <- sprintf("\\begin{table}[t]
\\centering
\\caption{Heterogeneity and Placebo Tests}
\\label{tab:robust}
\\begin{tabular}{lcccc}
\\hline\\hline
 & High-Immig. & Low-Immig. & Non-Hispanic & Early \\\\
 & Industries & Industries & Placebo & Adopters \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
Avg. post-treatment & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
 & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]
Observations & %d & %d & %d & %d \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Sun--Abraham (2021) average post-treatment effects. High-immigrant industries: Construction (23), Accommodation/Food (72), Agriculture (11), Admin/Waste (56). Low-immigrant industries: Information (51), Finance (52), Professional Services (54), Healthcare (62). Column 3: placebo using non-Hispanic employment (should be null). Column 4: restricts to states adopting 2008--2013 and years 2003--2016. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.
\\end{tablenotes}
\\end{table}\n",
  hi_avg, stars(hi_avg, hi_se),
  lo_avg, stars(lo_avg, lo_se),
  plac_avg, stars(plac_avg, plac_se),
  early_avg, stars(early_avg, early_se),
  hi_se, lo_se, plac_se, early_se,
  nobs(sa_industry$sa_hi), nobs(sa_industry$sa_lo),
  nobs(sa_placebo), nobs(sa_early))

writeLines(tab3_tex, "../tables/tab3_robust.tex")

# ============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================================
cat("Generating SDE table...\n")

# Compute SD of log_emp and log_earn from pre-treatment data
hisp_pre <- df %>%
  filter(year <= 2007, !is.na(Emp), Emp > 0, state_fips != 11) %>%
  mutate(ethnicity_label = ifelse(ethnicity == "A2", "Hispanic", "Non-Hispanic")) %>%
  filter(ethnicity_label == "Hispanic") %>%
  mutate(log_emp = log(Emp), log_earn = log(EarnS))

sd_log_emp <- sd(hisp_pre$log_emp, na.rm = TRUE)
sd_log_earn <- sd(hisp_pre$log_earn, na.rm = TRUE)

# Main results
b_emp <- avg_post_emp
se_emp <- avg_post_se_emp
b_earn <- avg_post_earn
se_earn <- avg_post_se_earn

sde_emp <- b_emp / sd_log_emp
sde_earn <- b_earn / sd_log_earn
sde_se_emp <- se_emp / sd_log_emp
sde_se_earn <- se_earn / sd_log_earn

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Industry heterogeneity
b_hi <- hi_avg
se_hi <- hi_se
sd_log_emp_ind <- sd(log(df$Emp[df$year <= 2007 & !is.na(df$Emp) & df$Emp > 0]),
                     na.rm = TRUE)
sde_hi <- b_hi / sd_log_emp_ind
sde_se_hi <- se_hi / sd_log_emp_ind

tabF1_tex <- sprintf("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
Hispanic log employment & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Hispanic log earnings & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
High-immig. industries & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} This paper estimates the causal effect of mandatory E-Verify laws on Hispanic formal employment, using Census QWI administrative data in a Sun--Abraham (2021) staggered DiD design with 10 treated states (2008--2023) and 41 control states ($N = 856$ state-years). Treatment is binary (state-level mandate). SDE $= \\hat{\\beta} / \\text{SD}(Y)$. Classifications refer to effect magnitude, not statistical significance. SD($Y$) computed from pre-treatment (2003--2007) cross-section of state-quarter-ethnicity observations.
\\end{tablenotes}
\\end{table}\n",
  b_emp, se_emp, sd_log_emp, sde_emp, sde_se_emp, classify(sde_emp),
  b_earn, se_earn, sd_log_earn, sde_earn, sde_se_earn, classify(sde_earn),
  b_hi, se_hi, sd_log_emp_ind, sde_hi, sde_se_hi, classify(sde_hi))

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
