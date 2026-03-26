# =============================================================================
# 05_tables.R — Generate all tables for apep_0979
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
summary_stats <- readRDS("../data/summary_stats.rds")
pre_sds <- readRDS("../data/pre_sds.rds")
ulr_states <- read_csv("../data/ulr_states.csv", show_col_types = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
tab1_data <- df %>%
  group_by(race_label, industry_label) %>%
  summarize(
    mean_earn = weighted.mean(avg_monthly_earn, Emp, na.rm = TRUE),
    sd_earn = sqrt(weighted.mean((avg_monthly_earn - weighted.mean(avg_monthly_earn, Emp, na.rm = TRUE))^2, Emp, na.rm = TRUE)),
    mean_emp = mean(Emp, na.rm = TRUE),
    n_states = n_distinct(state_fips),
    n_qtrs = n_distinct(quarter_id),
    .groups = "drop"
  )

# ULR vs non-ULR comparison
tab1_ulr <- df %>%
  group_by(ulr_state, race_label, industry_label) %>%
  summarize(
    mean_earn = weighted.mean(avg_monthly_earn, Emp, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(ulr_state, "ULR States", "Non-ULR States"))

# Format Table 1 as LaTeX
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Average Monthly Earnings by Race and Industry}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Healthcare (NAICS 62)} & \\multicolumn{2}{c}{Manufacturing (NAICS 31--33)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Black & White & Black & White \\\\\n",
  "\\midrule\n"
)

# All states
all_row <- tab1_data %>% arrange(industry_label, race_label)
tab1_tex <- paste0(tab1_tex,
  "\\multicolumn{5}{l}{\\textit{Panel A: All States}} \\\\\n",
  sprintf("Mean Monthly Earnings (\\$) & %s & %s & %s & %s \\\\\n",
    format(round(all_row$mean_earn[1]), big.mark = ","),
    format(round(all_row$mean_earn[2]), big.mark = ","),
    format(round(all_row$mean_earn[3]), big.mark = ","),
    format(round(all_row$mean_earn[4]), big.mark = ",")),
  sprintf("SD of Earnings (\\$) & %s & %s & %s & %s \\\\\n",
    format(round(all_row$sd_earn[1]), big.mark = ","),
    format(round(all_row$sd_earn[2]), big.mark = ","),
    format(round(all_row$sd_earn[3]), big.mark = ","),
    format(round(all_row$sd_earn[4]), big.mark = ",")),
  sprintf("Mean Employment & %s & %s & %s & %s \\\\\n",
    format(round(all_row$mean_emp[1]), big.mark = ","),
    format(round(all_row$mean_emp[2]), big.mark = ","),
    format(round(all_row$mean_emp[3]), big.mark = ","),
    format(round(all_row$mean_emp[4]), big.mark = ",")),
  "\\midrule\n"
)

# ULR states
ulr_row <- tab1_ulr %>% filter(ulr_state) %>% arrange(industry_label, race_label)
non_ulr_row <- tab1_ulr %>% filter(!ulr_state) %>% arrange(industry_label, race_label)

tab1_tex <- paste0(tab1_tex,
  "\\multicolumn{5}{l}{\\textit{Panel B: ULR States (11)}} \\\\\n",
  sprintf("Mean Monthly Earnings (\\$) & %s & %s & %s & %s \\\\\n",
    format(round(ulr_row$mean_earn[1]), big.mark = ","),
    format(round(ulr_row$mean_earn[2]), big.mark = ","),
    format(round(ulr_row$mean_earn[3]), big.mark = ","),
    format(round(ulr_row$mean_earn[4]), big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Non-ULR States}} \\\\\n",
  sprintf("Mean Monthly Earnings (\\$) & %s & %s & %s & %s \\\\\n",
    format(round(non_ulr_row$mean_earn[1]), big.mark = ","),
    format(round(non_ulr_row$mean_earn[2]), big.mark = ","),
    format(round(non_ulr_row$mean_earn[3]), big.mark = ","),
    format(round(non_ulr_row$mean_earn[4]), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} QWI Race-Hispanic panel, 2015Q1--2022Q4. Private-sector workers. ",
  "Earnings are average monthly earnings computed as total quarterly earnings divided by employment. ",
  "ULR states adopted Universal Licensing Recognition between 2019--2021. ",
  sprintf("N = %s state-industry-race-quarter cells.\n", format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written\n")

# =============================================================================
# Table 2: Main DDD Results
# =============================================================================
m1 <- results$m1
m2 <- results$m2

# Extract key coefficients
get_coef_row <- function(model, varname, label) {
  coefs <- coef(model)
  ses <- se(model)
  pvals <- pvalue(model)
  idx <- grep(varname, names(coefs), fixed = TRUE)
  if (length(idx) == 0) return(NULL)
  tibble(
    label = label,
    coef = coefs[idx[1]],
    se = ses[idx[1]],
    pval = pvals[idx[1]]
  )
}

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Main results table
tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{The Reciprocity Dividend: DDD Estimates of ULR on Black-White Healthcare Wage Gap}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Baseline & Full FE \\\\\n",
  "\\midrule\n"
)

# DDD coefficient
c1 <- coef(m1)["post_ulr:black:healthcare"]
s1 <- se(m1)["post_ulr:black:healthcare"]
p1 <- pvalue(m1)["post_ulr:black:healthcare"]
c2 <- coef(m2)["post_ulr:black:healthcare"]
s2 <- se(m2)["post_ulr:black:healthcare"]
p2 <- pvalue(m2)["post_ulr:black:healthcare"]

tab2_tex <- paste0(tab2_tex,
  sprintf("Post ULR $\\times$ Black $\\times$ Healthcare & %.4f%s & %.4f%s \\\\\n",
    c1, stars(p1), c2, stars(p2)),
  sprintf(" & (%.4f) & (%.4f) \\\\\n", s1, s2),
  "\\midrule\n",
  "State $\\times$ Quarter FE & Yes & Yes \\\\\n",
  "State $\\times$ Race $\\times$ Industry FE & No & Yes \\\\\n",
  "Quarter $\\times$ Race $\\times$ Industry FE & No & Yes \\\\\n",
  sprintf("Observations & %s & %s \\\\\n",
    format(nobs(m1), big.mark = ","),
    format(nobs(m2), big.mark = ",")),
  sprintf("R$^2$ & %.3f & %.3f \\\\\n",
    r2(m1, "r2"), r2(m2, "r2")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} DDD estimates of ULR adoption on log average monthly earnings. ",
  "Treatment: 11 states adopting ULR (2019--2021, staggered). ",
  "Industries: Healthcare (NAICS 62) vs Manufacturing (NAICS 31--33). ",
  "Races: Black vs White workers. ",
  "Weighted by employment. Standard errors clustered at state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 written\n")

# =============================================================================
# Table 3: Event Study Coefficients
# =============================================================================
m3 <- results$m3
es_coefs <- coef(m3)
es_ses <- se(m3)
es_pvals <- pvalue(m3)

# Extract event-time coefficients
es_names <- names(es_coefs)
# Parse event time from names like "event_time_binned::-8:black_healthcare"
es_times <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", es_names))
es_df <- tibble(
  event_time = es_times,
  coef = as.numeric(es_coefs),
  se = as.numeric(es_ses),
  pval = as.numeric(es_pvals)
) %>%
  filter(!is.na(event_time)) %>%
  arrange(event_time)

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic DDD Effects of ULR on Black-White Healthcare Wage Gap}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Event Quarter & Coefficient & SE & $p$-value \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(es_df))) {
  row <- es_df[i, ]
  if (row$event_time == -1) next  # reference period
  tab3_tex <- paste0(tab3_tex,
    sprintf("$t %s %d$ & %.4f%s & (%.4f) & %.3f \\\\\n",
      ifelse(row$event_time >= 0, "+", ""),
      row$event_time,
      row$coef, stars(row$pval),
      row$se, row$pval))
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "Reference: $t - 1$ & \\multicolumn{3}{c}{(normalized to zero)} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Event study DDD coefficients from regression of log monthly earnings on ",
  "event-time dummies interacted with Black $\\times$ Healthcare. Full FE specification (state$\\times$quarter, ",
  "state$\\times$race$\\times$industry, quarter$\\times$race$\\times$industry). ",
  "Weighted by employment, SEs clustered at state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")
cat("Table 3 written\n")

# =============================================================================
# Table 4: Robustness
# =============================================================================
r1 <- robustness$r1_arizona
r4 <- robustness$r4_retail
r5 <- robustness$r5_unweighted
wcb <- robustness$wcb

# LOO range
loo <- robustness$loo
loo_min <- min(loo$coef)
loo_max <- max(loo$coef)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE & $N$ \\\\\n",
  "\\midrule\n",
  sprintf("Main specification (Table \\ref{tab:main}, col.~2) & %.4f%s & (%.4f) & %s \\\\\n",
    c2, stars(p2), s2, format(nobs(m2), big.mark = ",")),
  sprintf("Arizona only (pre-COVID) & %.4f%s & (%.4f) & %s \\\\\n",
    coef(r1)["post_ulr_az:black:healthcare"],
    stars(pvalue(r1)["post_ulr_az:black:healthcare"]),
    se(r1)["post_ulr_az:black:healthcare"],
    format(nobs(r1), big.mark = ",")),
  sprintf("Retail placebo (NAICS 44--45) & %.4f%s & (%.4f) & %s \\\\\n",
    coef(r4)["post_ulr:black:healthcare"],
    stars(pvalue(r4)["post_ulr:black:healthcare"]),
    se(r4)["post_ulr:black:healthcare"],
    format(nobs(r4), big.mark = ",")),
  sprintf("Unweighted & %.4f%s & (%.4f) & %s \\\\\n",
    coef(r5)["post_ulr:black:healthcare"],
    stars(pvalue(r5)["post_ulr:black:healthcare"]),
    se(r5)["post_ulr:black:healthcare"],
    format(nobs(r5), big.mark = ",")),
  sprintf("Leave-one-out range & [%.4f, %.4f] & & \\\\\n",
    loo_min, loo_max)
)

if (!is.null(wcb)) {
  tab4_tex <- paste0(tab4_tex,
    sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{3}{c}{$p = %.3f$, CI: [%.4f, %.4f]} \\\\\n",
      wcb$p_val, wcb$conf_int[1], wcb$conf_int[2]))
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include state$\\times$quarter, ",
  "state$\\times$race$\\times$industry, and quarter$\\times$race$\\times$industry FE (except Arizona-only which uses all available states pre-2020). ",
  "Arizona-only restricts to 2015Q1--2019Q4 (pre-COVID). ",
  "Leave-one-out drops each ULR state in turn. ",
  "WCB uses Rademacher weights with 999 iterations. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 written\n")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE) — Appendix
# =============================================================================
# Get main DDD coefficient and SE (from Model 2 = full FE)
ddd_name <- grep("post_ulr.*black.*healthcare", names(coef(results$m2)), value = TRUE)[1]
beta_main <- coef(results$m2)[ddd_name]
se_main <- se(results$m2)[ddd_name]
p_main <- pvalue(results$m2)[ddd_name]

# Pre-treatment SD of log earnings for Black healthcare workers
sd_y <- pre_sds %>%
  filter(race_label == "Black", industry_label == "Healthcare") %>%
  pull(sd_log_earn)

# SDE = beta / SD(Y)
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
panel_a <- tibble(
  outcome = "Log monthly earnings (Black HC)",
  beta = beta_main,
  se_beta = se_main,
  sd_y = sd_y,
  sde = sde_main,
  se_sde = se_sde_main,
  classification = classify_sde(sde_main)
)

# Panel B: Heterogeneous — split by adoption wave
# Wave 1 (2019): AZ, PA — pre-COVID
df_wave1 <- df %>%
  filter(state_fips %in% c("04", "42") | !ulr_state) %>%
  mutate(post_ulr = as.integer(ifelse(ulr_state, time_q >= first_treat_q, FALSE)))

m_wave1 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df_wave1,
  weights = ~Emp,
  cluster = ~state_fips
)

w1_name <- grep("post_ulr.*black.*healthcare", names(coef(m_wave1)), value = TRUE)[1]
beta_w1 <- coef(m_wave1)[w1_name]
se_w1 <- se(m_wave1)[w1_name]
sde_w1 <- beta_w1 / sd_y
se_sde_w1 <- se_w1 / sd_y

# Wave 3 (2021): NJ, OH, UT, CO, VA, WI, IN — COVID era
wave3_states <- c("34", "39", "49", "08", "51", "55", "18")
df_wave3 <- df %>%
  filter(state_fips %in% wave3_states | !ulr_state) %>%
  mutate(post_ulr = as.integer(ifelse(ulr_state, time_q >= first_treat_q, FALSE)))

m_wave3 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df_wave3,
  weights = ~Emp,
  cluster = ~state_fips
)

w3_name <- grep("post_ulr.*black.*healthcare", names(coef(m_wave3)), value = TRUE)[1]
beta_w3 <- coef(m_wave3)[w3_name]
se_w3 <- se(m_wave3)[w3_name]
sde_w3 <- beta_w3 / sd_y
se_sde_w3 <- se_w3 / sd_y

panel_b <- tibble(
  outcome = c("Wave 1 (2019, pre-COVID)", "Wave 3 (2021, COVID era)"),
  beta = c(beta_w1, beta_w3),
  se_beta = c(se_w1, se_w3),
  sd_y = c(sd_y, sd_y),
  sde = c(sde_w1, sde_w3),
  se_sde = c(se_sde_w1, se_sde_w3),
  classification = c(classify_sde(sde_w1), classify_sde(sde_w3))
)

# Format SDE table
fmt4 <- function(x) sprintf("%.4f", x)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do Universal Licensing Recognition laws narrow the Black-White earnings gap among healthcare workers? ",
  "\\textbf{Policy mechanism:} ULR allows out-of-state licensed professionals to practice immediately without re-examination, ",
  "reducing interstate mobility costs that disproportionately bind Black healthcare workers concentrated in states with restrictive reciprocity agreements. ",
  "\\textbf{Outcome definition:} Log average monthly earnings from QWI, computed as total quarterly earnings divided by beginning-of-quarter employment. ",
  "\\textbf{Treatment:} Binary; state-level adoption of comprehensive ULR law (11 states, staggered 2019--2021). ",
  "\\textbf{Data:} Census QWI Race-Hispanic panel via LEHD, 2015Q1--2022Q4, state-level, private sector. ",
  "\\textbf{Method:} Triple-difference (ULR adoption $\\times$ Black $\\times$ Healthcare), weighted by employment, SEs clustered at state level. ",
  "\\textbf{Sample:} State$\\times$industry$\\times$race$\\times$quarter cells; Healthcare (NAICS 62) vs Manufacturing (NAICS 31--33); Black vs White workers. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log monthly earnings for Black healthcare workers. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
    panel_a$outcome, fmt4(panel_a$beta), fmt4(panel_a$se_beta),
    fmt4(panel_a$sd_y), fmt4(panel_a$sde), fmt4(panel_a$se_sde),
    panel_a$classification),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by adoption wave)}} \\\\\n"
)

for (i in seq_len(nrow(panel_b))) {
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
      panel_b$outcome[i], fmt4(panel_b$beta[i]), fmt4(panel_b$se_beta[i]),
      fmt4(panel_b$sd_y[i]), fmt4(panel_b$sde[i]), fmt4(panel_b$se_sde[i]),
      panel_b$classification[i]))
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written\n")

cat("\n=== ALL TABLES GENERATED ===\n")
