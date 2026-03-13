# 05_tables.R — Generate LaTeX tables
# APEP-0622: Taxing the Transition — EV Registration Fees and Adoption

source("code/00_packages.R")

cat("=== 05_tables.R ===\n")

# ============================================================
# 1. LOAD ALL RESULTS
# ============================================================
panel      <- readRDS("data/analysis_panel.rds")
cs_results <- readRDS("data/cs_results.rds")
twfe_results <- readRDS("data/twfe_results.rds")
robustness <- readRDS("data/robustness_results.rds")

# Convenience
cs_simple  <- cs_results$simple
cs_es      <- cs_results$es
twfe_main  <- twfe_results$main
twfe_total <- twfe_results$total

# Helper: significance stars
stars_fn <- function(pval) {
  ifelse(pval < 0.01, "^{***}",
  ifelse(pval < 0.05, "^{**}",
  ifelse(pval < 0.10, "^{*}", "")))
}

# Helper: format number
fmt <- function(x, digits = 3) {
  formatC(round(x, digits), format = "f", digits = digits, big.mark = ",")
}

fmt0 <- function(x) {
  formatC(round(x, 0), format = "f", digits = 0, big.mark = ",")
}

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Compute summary stats
summ_vars <- panel %>%
  summarise(
    bev_mean    = mean(bev),           bev_sd    = sd(bev),
    bev_min     = min(bev),            bev_max   = max(bev),
    phev_mean   = mean(phev),          phev_sd   = sd(phev),
    phev_min    = min(phev),           phev_max  = max(phev),
    ev_total_mean = mean(ev_total),    ev_total_sd = sd(ev_total),
    ev_total_min  = min(ev_total),     ev_total_max = max(ev_total),
    log_bev_mean  = mean(log_bev),     log_bev_sd  = sd(log_bev),
    fee_mean  = mean(fee_amount),      fee_sd  = sd(fee_amount),
    fee_cond_mean = mean(fee_amount[fee_amount > 0]),
    fee_cond_sd   = sd(fee_amount[fee_amount > 0])
  )

# Per-capita stats (only where population available)
pc_vars <- panel %>%
  filter(!is.na(bev_per_capita)) %>%
  summarise(
    bpc_mean = mean(bev_per_capita),   bpc_sd = sd(bev_per_capita),
    bpc_min  = min(bev_per_capita),    bpc_max = max(bev_per_capita),
    pop_mean = mean(population),       pop_sd = sd(population)
  )

gas_vars <- panel %>%
  filter(!is.na(gas_consumption_kbbl)) %>%
  summarise(
    gas_mean = mean(gas_consumption_kbbl), gas_sd = sd(gas_consumption_kbbl)
  )

# Treated vs control comparison
summ_by_treat <- panel %>%
  mutate(ever_treated = as.integer(first_treat > 0)) %>%
  group_by(ever_treated) %>%
  summarise(
    n_states    = n_distinct(state),
    bev_mean    = mean(bev),
    log_bev_mean = mean(log_bev),
    phev_mean   = mean(phev),
    ev_total_mean = mean(ev_total),
    .groups = "drop"
  )

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{Ever Treated} & \\multicolumn{2}{c}{Never Treated} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  "Variable & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

# Per-group stats
full_stats <- panel %>%
  summarise(
    bev_m = mean(bev), bev_s = sd(bev),
    log_bev_m = mean(log_bev), log_bev_s = sd(log_bev),
    phev_m = mean(phev), phev_s = sd(phev),
    ev_total_m = mean(ev_total), ev_total_s = sd(ev_total),
    ev_share_m = mean(ev_share, na.rm = TRUE), ev_share_s = sd(ev_share, na.rm = TRUE),
    fee_m = mean(fee_amount), fee_s = sd(fee_amount)
  )

treat_stats <- panel %>% filter(first_treat > 0) %>%
  summarise(
    bev_m = mean(bev), bev_s = sd(bev),
    log_bev_m = mean(log_bev), log_bev_s = sd(log_bev),
    phev_m = mean(phev), phev_s = sd(phev),
    ev_total_m = mean(ev_total), ev_total_s = sd(ev_total),
    ev_share_m = mean(ev_share, na.rm = TRUE), ev_share_s = sd(ev_share, na.rm = TRUE),
    fee_m = mean(fee_amount), fee_s = sd(fee_amount)
  )

ctrl_stats <- panel %>% filter(first_treat == 0) %>%
  summarise(
    bev_m = mean(bev), bev_s = sd(bev),
    log_bev_m = mean(log_bev), log_bev_s = sd(log_bev),
    phev_m = mean(phev), phev_s = sd(phev),
    ev_total_m = mean(ev_total), ev_total_s = sd(ev_total),
    ev_share_m = mean(ev_share, na.rm = TRUE), ev_share_s = sd(ev_share, na.rm = TRUE),
    fee_m = mean(fee_amount), fee_s = sd(fee_amount)
  )

# Build rows
add_row <- function(label, var_m, var_s) {
  paste0(label, " & ", fmt(full_stats[[paste0(var_m)]]), " & ", fmt(full_stats[[paste0(var_s)]]),
         " & ", fmt(treat_stats[[paste0(var_m)]]), " & ", fmt(treat_stats[[paste0(var_s)]]),
         " & ", fmt(ctrl_stats[[paste0(var_m)]]), " & ", fmt(ctrl_stats[[paste0(var_s)]]),
         " \\\\\n")
}

tab1 <- paste0(tab1,
  add_row("BEV Registrations", "bev_m", "bev_s"),
  add_row("$\\ln$(BEV)", "log_bev_m", "log_bev_s"),
  add_row("PHEV Registrations", "phev_m", "phev_s"),
  add_row("Total EV Registrations", "ev_total_m", "ev_total_s"),
  add_row("BEV Share of EVs", "ev_share_m", "ev_share_s"),
  add_row("EV Fee (\\$)", "fee_m", "fee_s"),
  "\\midrule\n",
  "States & \\multicolumn{2}{c}{", n_distinct(panel$state), "} & ",
  "\\multicolumn{2}{c}{", n_distinct(panel$state[panel$first_treat > 0]), "} & ",
  "\\multicolumn{2}{c}{", n_distinct(panel$state[panel$first_treat == 0]), "} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", fmt0(nrow(panel)), "} & ",
  "\\multicolumn{2}{c}{", fmt0(sum(panel$first_treat > 0)), "} & ",
  "\\multicolumn{2}{c}{", fmt0(sum(panel$first_treat == 0)), "} \\\\\n",
  "Years & \\multicolumn{6}{c}{", paste(range(panel$year), collapse = "--"), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} BEV = Battery Electric Vehicle; PHEV = Plug-in Hybrid Electric Vehicle. ",
  "Registration counts are cumulative stock from DOE/AFDC (Experian). ",
  "EV Fee is the annual BEV registration surcharge in nominal dollars (\\$0 for untreated state-years). ",
  "``Ever Treated'' includes ", n_distinct(panel$state[panel$first_treat > 0]),
  " states that enacted EV registration fees by 2023. ",
  "``Never Treated'' includes ", n_distinct(panel$state[panel$first_treat == 0]),
  " states (plus DC) that had not enacted fees by 2023.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "tables/tab1_summary.tex")
cat("Written: tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: MAIN RESULTS (CS-DiD + TWFE)
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

# Extract CS-DiD results
cs_att  <- cs_simple$overall.att
cs_se   <- cs_simple$overall.se
cs_t    <- cs_att / cs_se
cs_pval <- 2 * pnorm(-abs(cs_t))

# CS with never-treated control
cs_never_att <- robustness$never_cs_simple$overall.att
cs_never_se  <- robustness$never_cs_simple$overall.se
cs_never_t   <- cs_never_att / cs_never_se
cs_never_pval <- 2 * pnorm(-abs(cs_never_t))

# TWFE results
twfe_coef <- coef(twfe_main)["treated"]
twfe_se_val <- se(twfe_main)["treated"]
twfe_pval <- pvalue(twfe_main)["treated"]

twfe_total_coef <- coef(twfe_total)["treated"]
twfe_total_se   <- se(twfe_total)["treated"]
twfe_total_pval <- pvalue(twfe_total)["treated"]

n_treated <- n_distinct(panel$state[panel$first_treat > 0])
n_obs <- nrow(panel)
n_clust <- n_distinct(panel$state_id)

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of EV Registration Fees on Electric Vehicle Adoption}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & CS-DiD & CS-DiD & TWFE & TWFE \\\\\n",
  " & $\\ln$(BEV) & $\\ln$(BEV) & $\\ln$(BEV) & $\\ln$(EV Total) \\\\\n",
  "\\midrule\n",
  "ATT / Treated & $", fmt(cs_att, 4), "$", stars_fn(cs_pval),
  " & $", fmt(cs_never_att, 4), "$", stars_fn(cs_never_pval),
  " & $", fmt(twfe_coef, 4), "$", stars_fn(twfe_pval),
  " & $", fmt(twfe_total_coef, 4), "$", stars_fn(twfe_total_pval), " \\\\\n",
  " & (", fmt(cs_se, 4), ")",
  " & (", fmt(cs_never_se, 4), ")",
  " & (", fmt(twfe_se_val, 4), ")",
  " & (", fmt(twfe_total_se, 4), ") \\\\\n",
  "[4pt]\n",
  "Control group & Not-yet-treated & Never-treated & --- & --- \\\\\n",
  "Estimator & Callaway--Sant'Anna & Callaway--Sant'Anna & TWFE & TWFE \\\\\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\midrule\n",
  "Observations & ", fmt0(n_obs), " & ", fmt0(n_obs),
  " & ", fmt0(n_obs), " & ", fmt0(n_obs), " \\\\\n",
  "Clusters (states) & ", n_clust, " & ", n_clust,
  " & ", n_clust, " & ", n_clust, " \\\\\n",
  "Treated states & ", n_treated, " & ", n_treated,
  " & ", n_treated, " & ", n_treated, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2) report the overall ATT from \\citet{callaway2021difference} ",
  "with doubly robust estimation. Column (1) uses not-yet-treated states as controls; ",
  "column (2) uses only never-treated states. Columns (3)--(4) report standard TWFE estimates ",
  "for comparison. Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "tables/tab2_main.tex")
cat("Written: tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: ROBUSTNESS CHECKS
# ============================================================
cat("\n=== Table 3: Robustness ===\n")

# Placebo PHEV
phev_att  <- robustness$phev_cs_simple$overall.att
phev_se   <- robustness$phev_cs_simple$overall.se
phev_t    <- phev_att / phev_se
phev_pval <- 2 * pnorm(-abs(phev_t))

# Alt outcome: ev_total
total_att  <- robustness$total_cs_simple$overall.att
total_se   <- robustness$total_cs_simple$overall.se
total_t    <- total_att / total_se
total_pval <- 2 * pnorm(-abs(total_t))

# Dose-response
dose_coef <- coef(robustness$dose_twfe)["fee_100"]
dose_se   <- se(robustness$dose_twfe)["fee_100"]
dose_pval <- pvalue(robustness$dose_twfe)["fee_100"]

# TWFE PHEV
twfe_phev_coef <- coef(robustness$phev_twfe)["treated"]
twfe_phev_se   <- se(robustness$phev_twfe)["treated"]
twfe_phev_pval <- pvalue(robustness$phev_twfe)["treated"]

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Placebo & Alt.\\ Outcome & Dose--Response & Placebo \\\\\n",
  " & $\\ln$(BEV) & $\\ln$(PHEV) & $\\ln$(EV Total) & $\\ln$(BEV) & $\\ln$(PHEV) \\\\\n",
  "\\midrule\n",
  "ATT / Treated & $", fmt(cs_att, 4), "$", stars_fn(cs_pval),
  " & $", fmt(phev_att, 4), "$", stars_fn(phev_pval),
  " & $", fmt(total_att, 4), "$", stars_fn(total_pval),
  " & $", fmt(dose_coef, 4), "$", stars_fn(dose_pval),
  " & $", fmt(twfe_phev_coef, 4), "$", stars_fn(twfe_phev_pval), " \\\\\n",
  " & (", fmt(cs_se, 4), ")",
  " & (", fmt(phev_se, 4), ")",
  " & (", fmt(total_se, 4), ")",
  " & (", fmt(dose_se, 4), ")",
  " & (", fmt(twfe_phev_se, 4), ") \\\\\n",
  "[4pt]\n",
  "Estimator & CS-DiD & CS-DiD & CS-DiD & TWFE & TWFE \\\\\n",
  "Treatment & Binary & Binary & Binary & Fee/\\$100 & Binary \\\\\n",
  "Control group & Not-yet & Not-yet & Not-yet & --- & --- \\\\\n",
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\midrule\n",
  "Observations & ", fmt0(n_obs), " & ", fmt0(n_obs), " & ", fmt0(n_obs),
  " & ", fmt0(n_obs), " & ", fmt0(n_obs), " \\\\\n",
  "Clusters & ", n_clust, " & ", n_clust, " & ", n_clust,
  " & ", n_clust, " & ", n_clust, " \\\\\n",
  "Treated states & ", n_treated, " & ", n_treated, " & ", n_treated,
  " & ", n_treated, " & ", n_treated, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column (1) repeats the baseline CS-DiD estimate from Table~\\ref{tab:main}. ",
  "Column (2) uses $\\ln$(PHEV registrations) as a placebo outcome --- PHEVs face lower or zero fees in most states. ",
  "Column (3) uses $\\ln$(total EV registrations) as the outcome. ",
  "Column (4) reports a dose--response TWFE specification with the BEV fee amount (per \\$100) as a continuous treatment. ",
  "Column (5) reports TWFE with PHEV as placebo outcome. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "tables/tab3_robustness.tex")
cat("Written: tables/tab3_robustness.tex\n")

# ============================================================
# TABLE 4: EVENT-STUDY COEFFICIENTS
# ============================================================
cat("\n=== Table 4: Event Study ===\n")

es <- cs_results$es
es_df <- data.frame(
  event_time = es$egt,
  att        = es$att.egt,
  se         = es$se.egt
)
es_df$t_stat <- es_df$att / es_df$se
es_df$pval   <- 2 * pnorm(-abs(es_df$t_stat))

# Build event-study table
tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event-Study Estimates: Dynamic Treatment Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Event Time ($e = t - g$) & ATT & SE & 95\\% CI \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(es_df))) {
  e  <- es_df$event_time[i]
  a  <- es_df$att[i]
  s  <- es_df$se[i]
  ci_lo <- a - 1.96 * s
  ci_hi <- a + 1.96 * s
  star <- stars_fn(es_df$pval[i])
  label <- ifelse(e < 0, paste0("$e = ", e, "$ (pre)"),
           ifelse(e == 0, "$e = 0$ (impact)",
           paste0("$e = +", e, "$ (post)")))

  tab4 <- paste0(tab4, label, " & $", fmt(a, 4), "$", star,
                 " & ", fmt(s, 4),
                 " & $[", fmt(ci_lo, 3), ",\\;", fmt(ci_hi, 3), "]$ \\\\\n")
}

# Add joint pre-trend test
pre_atts <- es_df$att[es_df$event_time < 0]
pre_ses  <- es_df$se[es_df$event_time < 0]
# Wald-type test: sum of squared t-stats (chi-sq with K df)
pre_wald <- sum((pre_atts / pre_ses)^2)
pre_df   <- length(pre_atts)
pre_pval <- pchisq(pre_wald, df = pre_df, lower.tail = FALSE)

tab4 <- paste0(tab4,
  "\\midrule\n",
  "\\multicolumn{4}{l}{Joint pre-trend test: $\\chi^2(", pre_df, ") = ",
  fmt(pre_wald, 2), "$, $p = ", fmt(pre_pval, 3), "$} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Event-study estimates from the \\citet{callaway2021difference} ",
  "estimator with not-yet-treated controls. Event time $e = t - g$ measures years relative to ",
  "fee adoption (year $g$). Pre-treatment coefficients ($e < 0$) test the parallel trends ",
  "assumption. The joint test reports a Wald statistic for the null that all pre-treatment ",
  "coefficients are jointly zero. Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "tables/tab4_eventstudy.tex")
cat("Written: tables/tab4_eventstudy.tex\n")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE — MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute standardized effects (Cohen's d analog)
# For log outcomes: ATT is already in log-points (% change / 100)
# SDE = ATT / SD(outcome) for the treated group pre-treatment

# Pre-treatment SD of outcome among ever-treated
pre_treat_sd_bev <- panel %>%
  filter(first_treat > 0, year < first_treat) %>%
  pull(log_bev) %>%
  sd()

pre_treat_sd_phev <- panel %>%
  filter(first_treat > 0, year < first_treat) %>%
  pull(log_phev) %>%
  sd()

pre_treat_sd_total <- panel %>%
  filter(first_treat > 0, year < first_treat) %>%
  pull(log_ev_total) %>%
  sd()

# Compute SDEs
sde_bev   <- cs_att / pre_treat_sd_bev
sde_phev  <- phev_att / pre_treat_sd_phev
sde_total <- total_att / pre_treat_sd_total

# APEP 7-bucket classification
classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Use unconditional SD(Y) from full sample
sd_bev   <- sd(panel$log_bev)
sd_phev  <- sd(panel$log_phev)
sd_total <- sd(panel$log_ev_total)

sde_bev   <- cs_att / sd_bev
sde_phev  <- phev_att / sd_phev
sde_total <- total_att / sd_total

se_sde_bev   <- cs_se / sd_bev
se_sde_phev  <- phev_se / sd_phev
se_sde_total <- total_se / sd_total

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "$\\ln$(BEV Registrations) & $", fmt(cs_att, 3), "$ & $", fmt(cs_se, 3),
  "$ & $", fmt(sd_bev, 3), "$ & $", fmt(sde_bev, 3),
  "$ & $", fmt(se_sde_bev, 3), "$ & ", classify(sde_bev), " \\\\\n",
  "$\\ln$(PHEV Registrations) & $", fmt(phev_att, 3), "$ & $", fmt(phev_se, 3),
  "$ & $", fmt(sd_phev, 3), "$ & $", fmt(sde_phev, 3),
  "$ & $", fmt(se_sde_phev, 3), "$ & ", classify(sde_phev), " \\\\\n",
  "$\\ln$(Total EV Registrations) & $", fmt(total_att, 3), "$ & $", fmt(total_se, 3),
  "$ & $", fmt(sd_total, 3), "$ & $", fmt(sde_total, 3),
  "$ & $", fmt(se_sde_total, 3), "$ & ", classify(sde_total), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)\n",
  "to facilitate cross-study comparison of treatment effect magnitudes.\n",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment.\n",
  "SD($Y$) is the unconditional standard deviation of the outcome from the full sample\n",
  "(Table~\\ref{tab:summary}), before conditioning on fixed effects.\n\n",
  "\\textbf{Research question:} Does state adoption of EV-specific registration fees reduce electric vehicle adoption?\n",
  "\\textbf{Treatment:} Binary indicator for state having enacted an EV registration fee.\n",
  "\\textbf{Data:} DOE/AFDC Experian vehicle registrations, 50 states, 2016--2023.\n",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna estimator, state-clustered SEs.\n",
  "\\textbf{Sample:} ", fmt0(n_obs), " state-year observations; ",
  n_treated, " treated states, ",
  n_distinct(panel$state[panel$first_treat == 0]), " never-treated.\n\n",
  "Classification thresholds:\n",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),\n",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),\n",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),\n",
  "large positive ($> 0.15$).\n",
  "Classification labels refer to the magnitude of the standardized point estimate,\n",
  "not to statistical significance. ``Null'' denotes a near-zero effect size\n",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Written: tables/tabF1_sde.tex\n")

cat("\n=== 05_tables.R complete ===\n")
