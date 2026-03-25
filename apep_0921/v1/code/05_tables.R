## 05_tables.R — Generate all LaTeX tables
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## Load data and results
df <- readRDS(file.path(data_dir, "agency_panel.rds")) %>%
  filter(state != "NC")
results <- readRDS(file.path(data_dir, "results.rds"))
rob <- readRDS(file.path(data_dir, "rob_results.rds"))
reforms <- readRDS(file.path(data_dir, "reforms.rds")) %>% filter(state != "NC")
pre_stats <- readRDS(file.path(data_dir, "pre_treat_stats.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-reform means by group
pre_df <- df %>% filter(post_reform == 0)
ever_treated <- df %>% filter(first_treat > 0) %>% pull(ncic_cd) %>% unique()

summ <- bind_rows(
  pre_df %>%
    summarize(
      group = "Full Sample (Pre-Reform)",
      N = n(),
      agencies = n_distinct(ncic_cd),
      mean_es = mean(es_funds),
      sd_es = sd(es_funds),
      mean_log_es = mean(log_es_funds),
      sd_log_es = sd(log_es_funds),
      pct_positive = mean(has_es) * 100,
      mean_budget = mean(budget, na.rm = TRUE) / 1e6,
      .groups = "drop"
    ),
  pre_df %>%
    filter(ncic_cd %in% ever_treated) %>%
    summarize(
      group = "Reform States (Pre-Reform)",
      N = n(),
      agencies = n_distinct(ncic_cd),
      mean_es = mean(es_funds),
      sd_es = sd(es_funds),
      mean_log_es = mean(log_es_funds),
      sd_log_es = sd(log_es_funds),
      pct_positive = mean(has_es) * 100,
      mean_budget = mean(budget, na.rm = TRUE) / 1e6,
      .groups = "drop"
    ),
  pre_df %>%
    filter(!ncic_cd %in% ever_treated) %>%
    summarize(
      group = "Never-Reform States (Pre-Reform)",
      N = n(),
      agencies = n_distinct(ncic_cd),
      mean_es = mean(es_funds),
      sd_es = sd(es_funds),
      mean_log_es = mean(log_es_funds),
      sd_log_es = sd(log_es_funds),
      pct_positive = mean(has_es) * 100,
      mean_budget = mean(budget, na.rm = TRUE) / 1e6,
      .groups = "drop"
    )
)

# Generate LaTeX
fmt_num <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
fmt_pct <- function(x) formatC(x, format = "f", digits = 1)
fmt_dol <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Summary Statistics: Equitable Sharing Activity, Pre-Reform Period}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{@{}lccc@{}}\n",
  "\\toprule\n",
  " & Full Sample & Reform States & Never-Reform \\\\\n",
  "\\midrule\n",
  sprintf("Agency-years & %s & %s & %s \\\\\n",
          fmt_num(summ$N[1]), fmt_num(summ$N[2]), fmt_num(summ$N[3])),
  sprintf("Unique agencies & %s & %s & %s \\\\\n",
          fmt_num(summ$agencies[1]), fmt_num(summ$agencies[2]), fmt_num(summ$agencies[3])),
  sprintf("Mean ES funds (\\$) & %s & %s & %s \\\\\n",
          fmt_dol(summ$mean_es[1]), fmt_dol(summ$mean_es[2]), fmt_dol(summ$mean_es[3])),
  sprintf("SD ES funds (\\$) & %s & %s & %s \\\\\n",
          fmt_dol(summ$sd_es[1]), fmt_dol(summ$sd_es[2]), fmt_dol(summ$sd_es[3])),
  sprintf("Mean log(ES funds + 1) & %s & %s & %s \\\\\n",
          fmt_pct(summ$mean_log_es[1]), fmt_pct(summ$mean_log_es[2]), fmt_pct(summ$mean_log_es[3])),
  sprintf("SD log(ES funds + 1) & %s & %s & %s \\\\\n",
          fmt_pct(summ$sd_log_es[1]), fmt_pct(summ$sd_log_es[2]), fmt_pct(summ$sd_log_es[3])),
  sprintf("Share receiving ES funds (\\%%) & %s & %s & %s \\\\\n",
          fmt_pct(summ$pct_positive[1]), fmt_pct(summ$pct_positive[2]), fmt_pct(summ$pct_positive[3])),
  sprintf("Mean agency budget (\\$M) & %s & %s & %s \\\\\n",
          fmt_pct(summ$mean_budget[1]), fmt_pct(summ$mean_budget[2]), fmt_pct(summ$mean_budget[3])),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Pre-reform period observations only (fiscal years before each state's reform; all years for never-reform states). ",
  "ES funds = Equitable Sharing Funds Received (DOJ ESAC Type 1 income). ",
  "Sample restricted to US law enforcement agencies filing accepted ESAC certifications, FY2009--2024, excluding North Carolina (abolished pre-panel). ",
  "36 reform states, 14 never-reform states, 50 states total.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Main Results
## ============================================================
cat("Generating Table 2: Main Results...\n")

# Extract coefficients
twfe_log <- results$twfe_log
twfe_ext <- results$twfe_ext
twfe_level <- results$twfe_level
cs_log <- results$cs_log_agg
cs_ext <- results$cs_ext_agg

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

twfe_coefs <- c(coef(twfe_log), coef(twfe_ext), coef(twfe_level))
twfe_ses <- c(sqrt(diag(vcov(twfe_log))), sqrt(diag(vcov(twfe_ext))),
              sqrt(diag(vcov(twfe_level))))
twfe_ps <- c(pvalue(twfe_log), pvalue(twfe_ext), pvalue(twfe_level))

tab2 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Effect of State Forfeiture Reform on Federal Equitable Sharing}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{@{}lcccccc@{}}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{TWFE} & \\multicolumn{3}{c}{Callaway-Sant'Anna} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  " & log(ES+1) & Participation & ES Funds & log(ES+1) & Participation & ES Funds \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\midrule\n",
  sprintf("Post Reform & %s%s & %s%s & %s%s & %s & %s & %s \\\\\n",
          formatC(twfe_coefs[1], format = "f", digits = 3), stars(twfe_ps[1]),
          formatC(twfe_coefs[2], format = "f", digits = 4), stars(twfe_ps[2]),
          fmt_dol(twfe_coefs[3]), stars(twfe_ps[3]),
          formatC(cs_log$overall.att, format = "f", digits = 3),
          formatC(cs_ext$overall.att, format = "f", digits = 4),
          fmt_dol(results$cs_level_agg$overall.att)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          formatC(twfe_ses[1], format = "f", digits = 3),
          formatC(twfe_ses[2], format = "f", digits = 4),
          fmt_dol(twfe_ses[3]),
          formatC(cs_log$overall.se, format = "f", digits = 3),
          formatC(cs_ext$overall.se, format = "f", digits = 4),
          fmt_dol(results$cs_level_agg$overall.se)),
  "\\midrule\n",
  sprintf("Agency FE & Yes & Yes & Yes & --- & --- & --- \\\\\n"),
  sprintf("Year FE & Yes & Yes & Yes & --- & --- & --- \\\\\n"),
  "Estimator & TWFE & TWFE & TWFE & CS-DiD & CS-DiD & CS-DiD \\\\\n",
  "Control group & --- & --- & --- & Never-treated & Never-treated & Never-treated \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_num(nobs(twfe_log)), fmt_num(nobs(twfe_ext)), fmt_num(nobs(twfe_level)),
          fmt_num(nobs(twfe_log)), fmt_num(nobs(twfe_log)), fmt_num(nobs(twfe_log))),
  "Clusters (states) & 50 & 50 & 50 & 50 & 50 & 50 \\\\\n",
  sprintf("Pre-treatment mean & %s & %s & %s & %s & %s & %s \\\\\n",
          formatC(pre_stats$mean_log_es, format = "f", digits = 2),
          formatC(pre_stats$mean_has_es, format = "f", digits = 3),
          fmt_dol(pre_stats$mean_es_funds),
          formatC(pre_stats$mean_log_es, format = "f", digits = 2),
          formatC(pre_stats$mean_has_es, format = "f", digits = 3),
          fmt_dol(pre_stats$mean_es_funds)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "TWFE specifications include agency and fiscal year fixed effects. ",
  "Callaway-Sant'Anna (CS-DiD) uses never-treated states as the comparison group with varying base period. ",
  "``Participation'' is an indicator for receiving any equitable sharing funds. ",
  "``ES Funds'' = total equitable sharing funds received (\\$). ",
  "Sample: 6,562 agencies across 50 states, FY2009--2024, excluding North Carolina (pre-panel abolition). ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

## ============================================================
## Table 3: Robustness
## ============================================================
cat("Generating Table 3: Robustness...\n")

# State-level
st_coef <- coef(rob$twfe_state_log)
st_se <- sqrt(diag(vcov(rob$twfe_state_log)))
st_p <- pvalue(rob$twfe_state_log)

st_share_coef <- coef(rob$twfe_state_share)
st_share_se <- sqrt(diag(vcov(rob$twfe_state_share)))
st_share_p <- pvalue(rob$twfe_state_share)

st_n_coef <- coef(rob$twfe_state_n)
st_n_se <- sqrt(diag(vcov(rob$twfe_state_n)))
st_n_p <- pvalue(rob$twfe_state_n)

# IHS
ihs_coef <- coef(rob$twfe_ihs)
ihs_se <- sqrt(diag(vcov(rob$twfe_ihs)))
ihs_p <- pvalue(rob$twfe_ihs)

# Placebo
plac_coef <- coef(rob$placebo_fit)
plac_se <- sqrt(diag(vcov(rob$placebo_fit)))
plac_p <- pvalue(rob$placebo_fit)

tab3 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{@{}lccc@{}}\n",
  "\\toprule\n",
  " & Coefficient & SE & Obs. \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Agency-Level Specifications}} \\\\\n",
  sprintf("\\quad TWFE: log(ES+1) [baseline] & %s & (%s) & %s \\\\\n",
          formatC(twfe_coefs[1], format = "f", digits = 3),
          formatC(twfe_ses[1], format = "f", digits = 3),
          fmt_num(nobs(twfe_log))),
  sprintf("\\quad TWFE: IHS(ES) & %s & (%s) & %s \\\\\n",
          formatC(ihs_coef, format = "f", digits = 3),
          formatC(ihs_se, format = "f", digits = 3),
          fmt_num(nobs(rob$twfe_ihs))),
  sprintf("\\quad CS-DiD: log(ES+1) & %s & (%s) & %s \\\\\n",
          formatC(cs_log$overall.att, format = "f", digits = 3),
          formatC(cs_log$overall.se, format = "f", digits = 3),
          fmt_num(nobs(twfe_log))),
  sprintf("\\quad Placebo (never-reformed states) & %s & (%s) & %s \\\\\n",
          formatC(plac_coef, format = "f", digits = 3),
          formatC(plac_se, format = "f", digits = 3),
          fmt_num(nobs(rob$placebo_fit))),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: State-Level Aggregates}} \\\\\n",
  sprintf("\\quad log(Total ES Funds) & %s%s & (%s) & %s \\\\\n",
          formatC(st_coef, format = "f", digits = 3), stars(st_p),
          formatC(st_se, format = "f", digits = 3),
          fmt_num(nobs(rob$twfe_state_log))),
  sprintf("\\quad Share of Agencies Participating & %s & (%s) & %s \\\\\n",
          formatC(st_share_coef, format = "f", digits = 4),
          formatC(st_share_se, format = "f", digits = 4),
          fmt_num(nobs(rob$twfe_state_share))),
  sprintf("\\quad Number of Agencies Filing & %s & (%s) & %s \\\\\n",
          formatC(st_n_coef, format = "f", digits = 1),
          formatC(st_n_se, format = "f", digits = 1),
          fmt_num(nobs(rob$twfe_state_n))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include unit and fiscal year fixed effects. Standard errors clustered at state level. ",
  "Panel A: Agency-level regressions. Placebo randomly assigns reform years to agencies in never-reformed states. ",
  "Panel B: State-year aggregates (50 states $\\times$ 12--16 years). ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_robust.tex"))

## ============================================================
## Table 4: Heterogeneity by Reform Stringency
## ============================================================
cat("Generating Table 4: Heterogeneity...\n")

het_coefs <- c(
  coef(results$twfe_strong),
  coef(results$twfe_weak),
  coef(results$twfe_no_anti),
  coef(results$twfe_anti)
)
het_ses <- c(
  sqrt(diag(vcov(results$twfe_strong))),
  sqrt(diag(vcov(results$twfe_weak))),
  sqrt(diag(vcov(results$twfe_no_anti))),
  sqrt(diag(vcov(results$twfe_anti)))
)
het_ps <- c(
  pvalue(results$twfe_strong),
  pvalue(results$twfe_weak),
  pvalue(results$twfe_no_anti),
  pvalue(results$twfe_anti)
)

n_strong <- nobs(results$twfe_strong)
n_weak <- nobs(results$twfe_weak)
n_no_anti <- nobs(results$twfe_no_anti)
n_anti <- nobs(results$twfe_anti)

# Count treated states
n_strong_states <- n_distinct(df$state[df$first_treat > 0 &
  df$state %in% (reforms %>% filter(reform_stringency >= 3) %>% pull(state))])
n_weak_states <- n_distinct(df$state[df$first_treat > 0 &
  df$state %in% (reforms %>% filter(reform_stringency %in% 1:2) %>% pull(state))])
n_anti_states <- n_distinct(df$state[df$first_treat > 0 & df$anti_circumvention])
n_no_anti_states <- n_distinct(df$state[df$first_treat > 0 & !df$anti_circumvention])

tab4 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Heterogeneity: Reform Stringency and Anti-Circumvention Laws}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{@{}lcccc@{}}\n",
  "\\toprule\n",
  " & Strong Reform & Weak Reform & No Anti-Circ. & Anti-Circ. \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Post Reform & %s%s & %s & %s & %s \\\\\n",
          formatC(het_coefs[1], format = "f", digits = 3), stars(het_ps[1]),
          formatC(het_coefs[2], format = "f", digits = 3),
          formatC(het_coefs[3], format = "f", digits = 3),
          formatC(het_coefs[4], format = "f", digits = 3)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          formatC(het_ses[1], format = "f", digits = 3),
          formatC(het_ses[2], format = "f", digits = 3),
          formatC(het_ses[3], format = "f", digits = 3),
          formatC(het_ses[4], format = "f", digits = 3)),
  "\\midrule\n",
  "Dep. var. & \\multicolumn{4}{c}{log(Equitable Sharing Funds + 1)} \\\\\n",
  "Agency \\& Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Treated states & %d & %d & %d & %d \\\\\n",
          n_strong_states, n_weak_states, n_no_anti_states, n_anti_states),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          fmt_num(n_strong), fmt_num(n_weak), fmt_num(n_no_anti), fmt_num(n_anti)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} TWFE with agency and fiscal year fixed effects, standard errors clustered at state level. ",
  "``Strong Reform'' = states that abolished forfeiture or required criminal conviction (stringency $\\geq$ 3). ",
  "``Weak Reform'' = states that raised burden of proof or enacted reporting requirements only (stringency $\\leq$ 2). ",
  "``Anti-Circ.'' = states that also enacted anti-circumvention statutes barring federal equitable sharing adoption (NM, NE, CO). ",
  "Each column includes agencies in the relevant reform-type states plus all never-reform state agencies as controls. ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))

## ============================================================
## Table F1: Standardized Effect Size (SDE) — MANDATORY
## ============================================================
cat("Generating Table F1: SDE...\n")

# Pre-treatment SDs
sd_log_es <- pre_stats$sd_log_es
sd_has_es <- pre_stats$sd_has_es
sd_es_funds <- pre_stats$sd_es_funds

# Main pooled outcomes (TWFE)
sde_log <- twfe_coefs[1] / sd_log_es
sde_ext <- twfe_coefs[2] / sd_has_es
sde_level <- twfe_coefs[3] / sd_es_funds
se_sde_log <- twfe_ses[1] / sd_log_es
se_sde_ext <- twfe_ses[2] / sd_has_es
se_sde_level <- twfe_ses[3] / sd_es_funds

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  return("Small negative")
}

# Heterogeneous: strong vs weak reform
sde_strong <- het_coefs[1] / sd_log_es
se_sde_strong <- het_ses[1] / sd_log_es
sde_weak <- het_coefs[2] / sd_log_es
se_sde_weak <- het_ses[2] / sd_log_es

# Format function
fmt3 <- function(x) formatC(x, format = "f", digits = 3)
fmt4 <- function(x) formatC(x, format = "f", digits = 4)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state civil asset forfeiture reforms cause law enforcement agencies to circumvent restrictions by increasing their use of the federal equitable sharing program? ",
  "\\textbf{Policy mechanism:} State reforms restrict or abolish civil asset forfeiture, raising the burden of proof for seizures or requiring criminal conviction; the federal equitable sharing program allows agencies to partner with federal authorities and retain up to 80\\% of seized assets under federal law, potentially bypassing state restrictions. ",
  "\\textbf{Outcome definition:} Log of equitable sharing funds received plus one (DOJ ESAC Type~1 income: direct federal equitable sharing disbursements to state/local agencies) and an indicator for any positive equitable sharing receipts. ",
  "\\textbf{Treatment:} Binary; state enactment of civil asset forfeiture reform (conviction requirement, burden-of-proof elevation, or abolition). ",
  "\\textbf{Data:} DOJ Asset Forfeiture Program ESAC FOIA, FY2009--2024, agency-year level, 51,868 observations across 6,562 agencies in 50 states. ",
  "\\textbf{Method:} TWFE with agency and fiscal year fixed effects, standard errors clustered at the state level (50 clusters). Callaway-Sant'Anna as robustness. ",
  "\\textbf{Sample:} US state and local law enforcement agencies filing accepted ESAC certifications; excludes North Carolina (abolished forfeiture before panel period). Panel restricted to agencies with $\\geq$3 years of data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{@{}lcccccc@{}}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("log(ES Funds + 1) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt3(twfe_coefs[1]), fmt3(twfe_ses[1]), fmt3(sd_log_es),
          fmt4(sde_log), fmt4(se_sde_log), classify_sde(sde_log)),
  sprintf("Participation & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt4(twfe_coefs[2]), fmt4(twfe_ses[2]), fmt3(sd_has_es),
          fmt4(sde_ext), fmt4(se_sde_ext), classify_sde(sde_ext)),
  sprintf("ES Funds (\\$) & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt_dol(twfe_coefs[3]), fmt_dol(twfe_ses[3]), fmt_dol(sd_es_funds),
          fmt4(sde_level), fmt4(se_sde_level), classify_sde(sde_level)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Reform Stringency)}} \\\\\n",
  sprintf("log(ES+1): Strong reform & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt3(het_coefs[1]), fmt3(het_ses[1]), fmt3(sd_log_es),
          fmt4(sde_strong), fmt4(se_sde_strong), classify_sde(sde_strong)),
  sprintf("log(ES+1): Weak reform & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt3(het_coefs[2]), fmt3(het_ses[2]), fmt3(sd_log_es),
          fmt4(sde_weak), fmt4(se_sde_weak), classify_sde(sde_weak)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
for (f in list.files(tables_dir, pattern = "\\.tex$")) cat("  ", f, "\n")
