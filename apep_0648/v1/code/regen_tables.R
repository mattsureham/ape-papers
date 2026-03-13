## regen_tables.R — Regenerate corrupted table files from saved RDS results
library(tidyverse)
library(fixest)

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results_main.rds")
rob <- readRDS("../data/results_robustness.rds")

summ_stats <- results$summ_stats
sr <- summ_stats %>% filter(group == "Reform")
snr <- summ_stats %>% filter(group == "Non-reform")

# ─── Table 1: Summary Statistics ────────
tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Reform Period (2012--2017)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Reform States & Non-Reform States \\\\",
  "\\midrule",
  sprintf("Pharmacy establishments & %.0f & %.0f \\\\", sr$mean_estab, snr$mean_estab),
  sprintf(" & (%.0f) & (%.0f) \\\\", sr$sd_estab, snr$sd_estab),
  sprintf("Pharmacies per 100,000 & %.1f & %.1f \\\\", sr$mean_pc, snr$mean_pc),
  sprintf(" & (%.1f) & (%.1f) \\\\", sr$sd_pc, snr$sd_pc),
  sprintf("Pharmacy employment & %.0f & %.0f \\\\", sr$mean_emp, snr$mean_emp),
  sprintf(" & (%.0f) & (%.0f) \\\\", sr$sd_emp, snr$sd_emp),
  sprintf("Population (millions) & %.2f & %.2f \\\\", sr$mean_pop_m, snr$mean_pop_m),
  sprintf("Number of states & %d & %d \\\\", sr$n_states, snr$n_states),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Means with standard deviations in parentheses. Reform states banned PBM spread pricing in Medicaid by 2023. Pre-reform period: 2012--2017. Source: Census County Business Patterns, NAICS 446110; ACS 1-year population estimates.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")
cat("tab1 written\n")

# ─── Table 2: Main Results ────────
n_treated <- 12L
n_obs <- nrow(panel)
n_st <- n_distinct(panel$state_fips)

tw_e <- coef(results$twfe_estab)["treated"]
tw_se <- sqrt(vcov(results$twfe_estab)["treated","treated"])
tw_p <- 2*pnorm(abs(tw_e/tw_se), lower.tail=FALSE)
tw_s <- if(tw_p<0.01)"***" else if(tw_p<0.05)"**" else if(tw_p<0.10)"*" else ""

cs_e <- results$cs_agg$overall.att
cs_se <- results$cs_agg$overall.se
cs_p <- 2*pnorm(abs(cs_e/cs_se), lower.tail=FALSE)
cs_s <- if(cs_p<0.01)"***" else if(cs_p<0.05)"**" else if(cs_p<0.10)"*" else ""

nyt_e <- rob$cs_nyt_agg$overall.att
nyt_se <- rob$cs_nyt_agg$overall.se
nyt_p <- 2*pnorm(abs(nyt_e/nyt_se), lower.tail=FALSE)
nyt_s <- if(nyt_p<0.01)"***" else if(nyt_p<0.05)"**" else if(nyt_p<0.10)"*" else ""

tw_emp_e <- coef(results$twfe_emp)["treated"]
tw_emp_se <- sqrt(vcov(results$twfe_emp)["treated","treated"])
tw_emp_p <- 2*pnorm(abs(tw_emp_e/tw_emp_se), lower.tail=FALSE)
tw_emp_s <- if(tw_emp_p<0.01)"***" else if(tw_emp_p<0.05)"**" else if(tw_emp_p<0.10)"*" else ""

cs_emp_e <- results$cs_emp_agg$overall.att
cs_emp_se <- results$cs_emp_agg$overall.se
cs_emp_p <- 2*pnorm(abs(cs_emp_e/cs_emp_se), lower.tail=FALSE)
cs_emp_s <- if(cs_emp_p<0.01)"***" else if(cs_emp_p<0.05)"**" else if(cs_emp_p<0.10)"*" else ""

m_e <- mean(panel$estab_per_100k, na.rm=TRUE)
m_emp <- mean(panel$emp_per_100k, na.rm=TRUE)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of PBM Spread Pricing Bans on Pharmacy Market Structure}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Pharmacies per 100K} & \\multicolumn{2}{c}{Employment per 100K} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & TWFE & CS (NT) & CS (NYT) & TWFE & CS (NT) \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("Spread ban & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          tw_e, tw_s, cs_e, cs_s, nyt_e, nyt_s, tw_emp_e, tw_emp_s, cs_emp_e, cs_emp_s),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          tw_se, cs_se, nyt_se, tw_emp_se, cs_emp_se),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] & [%.3f] & [%.3f] \\\\",
          tw_p, cs_p, nyt_p, tw_emp_p, cs_emp_p),
  "\\midrule",
  sprintf("Dep.\\ var.\\ mean & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          m_e, m_e, m_e, m_emp, m_emp),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\", n_obs, n_obs, n_obs, n_obs, n_obs),
  sprintf("States & %d & %d & %d & %d & %d \\\\", n_st, n_st, n_st, n_st, n_st),
  sprintf("Treated states & %d & %d & %d & %d & %d \\\\",
          n_treated, n_treated, n_treated, n_treated, n_treated),
  "Estimator & TWFE & CS & CS & TWFE & CS \\\\",
  "Control group & --- & Never-treated & Not-yet-treated & --- & Never-treated \\\\",
  "State \\& year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. $p$-values in brackets. TWFE = two-way fixed effects. CS = Callaway-Sant'Anna (2021). NT = never-treated control. NYT = not-yet-treated control. Treatment: effective year of state PBM spread pricing ban. Sample: 50 states (excl.\\ DC), 2012--2022. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")
cat("tab2 written\n")

# ─── Table F1: SDE ────────
sd_e <- sd(panel$estab_per_100k, na.rm=TRUE)
sd_emp_v <- sd(panel$emp_per_100k, na.rm=TRUE)

sde_df <- tibble(
  Outcome = c("Pharmacies per 100K", "Employment per 100K"),
  beta = c(cs_e, cs_emp_e),
  se_b = c(cs_se, cs_emp_se),
  sd_y = c(sd_e, sd_emp_v),
  sde = beta / sd_y,
  se_sde = se_b / sd_y,
  class = case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
)

sde_body <- sde_df %>%
  mutate(row = sprintf("%s & %.3f & (%.3f) & %.2f & %.4f & (%.4f) & %s \\\\",
                       Outcome, beta, se_b, sd_y, sde, se_sde, class)) %>%
  pull(row)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sde_body,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sprintf("\\item \\textit{Notes:} SDE = $\\hat{\\beta}$ / SD($Y$). Callaway-Sant'Anna (2021) with never-treated controls. Research question: Does banning PBM spread pricing preserve community pharmacies? Data: Census CBP (NAICS 446110), 50 states, 2012--2022. %d treated states. %d state-year observations. Binary treatment (state enacted spread pricing ban). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.", 12L, n_obs),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("tabF1 written\n")

cat("\nAll 3 tables regenerated.\n")
