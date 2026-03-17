# 05_tables.R — Generate LaTeX tables for sports betting cannibalization
# apep_0720

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
stc <- readRDS(file.path(data_dir, "stc_analysis.rds"))
results <- readRDS(file.path(data_dir, "regression_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

df <- stc %>% filter(!is.na(g))

# Helper: format numbers
fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")
fmt1 <- function(x, digits = 1) formatC(x, digits = digits, format = "f")

# ===================================================================
# TABLE 1: Summary Statistics (pre-2019, treated vs never-treated)
# ===================================================================

cat("Generating Table 1: Summary Statistics\n")

pre <- df %>% filter(year < 2019)

summary_stats <- pre %>%
  mutate(group = ifelse(g > 0, "Treated", "Never-Treated")) %>%
  group_by(group) %>%
  summarise(
    mean_T11 = mean(T11, na.rm = TRUE),
    sd_T11   = sd(T11, na.rm = TRUE),
    mean_T20 = mean(T20, na.rm = TRUE),
    sd_T20   = sd(T20, na.rm = TRUE),
    mean_T09 = mean(T09, na.rm = TRUE),
    sd_T09   = sd(T09, na.rm = TRUE),
    mean_T10 = mean(T10, na.rm = TRUE),
    sd_T10   = sd(T10, na.rm = TRUE),
    mean_T16 = mean(T16, na.rm = TRUE),
    sd_T16   = sd(T16, na.rm = TRUE),
    N        = n(),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  )

treated <- summary_stats %>% filter(group == "Treated")
never   <- summary_stats %>% filter(group == "Never-Treated")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Period Mean Tax Revenue (Millions \\$)}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Never-Treated States} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Revenue Category & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  sprintf("T11: Amusement/Gambling & %s & %s & %s & %s \\\\\n",
          fmt1(treated$mean_T11), fmt1(treated$sd_T11),
          fmt1(never$mean_T11), fmt1(never$sd_T11)),
  sprintf("T20: Pari-mutuel & %s & %s & %s & %s \\\\\n",
          fmt1(treated$mean_T20), fmt1(treated$sd_T20),
          fmt1(never$mean_T20), fmt1(never$sd_T20)),
  sprintf("T09: General Sales & %s & %s & %s & %s \\\\\n",
          fmt1(treated$mean_T09), fmt1(treated$sd_T09),
          fmt1(never$mean_T09), fmt1(never$sd_T09)),
  sprintf("T10: Alcohol & %s & %s & %s & %s \\\\\n",
          fmt1(treated$mean_T10), fmt1(treated$sd_T10),
          fmt1(never$mean_T10), fmt1(never$sd_T10)),
  sprintf("T16: Tobacco & %s & %s & %s & %s \\\\\n",
          fmt1(treated$mean_T16), fmt1(treated$sd_T16),
          fmt1(never$mean_T16), fmt1(never$sd_T16)),
  "\\hline\n",
  sprintf("State-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          fmt0(treated$N), fmt0(never$N)),
  sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          treated$n_states, never$n_states),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Pre-period defined as 2012--2018 (before first sports betting legalizations). ",
  "Revenue in millions of dollars from Census Annual Survey of State Government Tax Collections. ",
  "Treated states are those that legalized online sports betting by FY2022. ",
  "Never-treated states had not legalized by end of sample.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("  -> tab1_summary.tex\n")

# ===================================================================
# TABLE 2: Main TWFE Results
# ===================================================================

cat("Generating Table 2: Main TWFE Results\n")

extract_coef <- function(model, varname = "post") {
  ct <- coeftable(model)
  idx <- which(rownames(ct) == varname)
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA, n = model$nobs))
  list(
    b  = ct[idx, "Estimate"],
    se = ct[idx, "Std. Error"],
    p  = ct[idx, "Pr(>|t|)"],
    n  = model$nobs
  )
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Extract from main results
c1 <- extract_coef(results$m1_t11)
c2 <- extract_coef(results$m2_t20)
c3 <- extract_coef(results$m3_t10)
c4 <- extract_coef(results$m4_t09)
c5 <- extract_coef(results$m5_t16)

# Outcome means
df_valid <- df %>% filter(!is.na(log_T11))
ymean1 <- mean(df_valid$log_T11, na.rm = TRUE)
df_valid2 <- df %>% filter(!is.na(log_T20))
ymean2 <- mean(df_valid2$log_T20, na.rm = TRUE)
df_valid3 <- df %>% filter(!is.na(log_T10))
ymean3 <- mean(df_valid3$log_T10, na.rm = TRUE)
df_valid4 <- df %>% filter(!is.na(log_T09))
ymean4 <- mean(df_valid4$log_T09, na.rm = TRUE)
df_valid5 <- df %>% filter(T16 > 0)
ymean5 <- mean(log(df_valid5$T16), na.rm = TRUE)

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Sports Betting Legalization on State Tax Revenue (TWFE)}\n",
  "\\label{tab:main}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Log T11 & Log T20 & Log T10 & Log T09 & Log T16 \\\\\n",
  " & Gambling & Pari-mutuel & Alcohol & Sales & Tobacco \\\\\n",
  "\\hline\n",
  sprintf("Post $\\times$ Treated & %s%s & %s%s & %s%s & %s%s & %s%s \\\\\n",
          fmt(c1$b), stars(c1$p),
          fmt(c2$b), stars(c2$p),
          fmt(c3$b), stars(c3$p),
          fmt(c4$b), stars(c4$p),
          fmt(c5$b), stars(c5$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(c1$se), fmt(c2$se), fmt(c3$se), fmt(c4$se), fmt(c5$se)),
  "\\hline\n",
  sprintf("Outcome mean & %s & %s & %s & %s & %s \\\\\n",
          fmt(ymean1), fmt(ymean2), fmt(ymean3), fmt(ymean4), fmt(ymean5)),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          fmt0(c1$n), fmt0(c2$n), fmt0(c3$n), fmt0(c4$n), fmt0(c5$n)),
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$. ",
  "Columns (1)--(2) are the main outcomes of interest: amusement/gambling tax and pari-mutuel tax revenue. ",
  "Column (3) tests cross-market spillovers to alcohol tax. ",
  "Columns (4)--(5) are placebo outcomes (general sales tax and tobacco tax), which should be unaffected by sports betting legalization. ",
  "All outcomes in logs. Sample: 2012--2022.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("  -> tab2_main.tex\n")

# ===================================================================
# TABLE 3: Callaway-Sant'Anna DiD Aggregate ATT
# ===================================================================

cat("Generating Table 3: CS-DiD Results\n")

# Extract CS-DiD aggregate results
cs_t11_att <- if (!is.null(results$agg_t11)) {
  list(
    att = results$agg_t11$overall.att,
    se  = results$agg_t11$overall.se,
    ci_lower = results$agg_t11$overall.att - 1.96 * results$agg_t11$overall.se,
    ci_upper = results$agg_t11$overall.att + 1.96 * results$agg_t11$overall.se
  )
} else {
  list(att = NA, se = NA, ci_lower = NA, ci_upper = NA)
}

cs_t20_att <- if (!is.null(results$agg_t20)) {
  list(
    att = results$agg_t20$overall.att,
    se  = results$agg_t20$overall.se,
    ci_lower = results$agg_t20$overall.att - 1.96 * results$agg_t20$overall.se,
    ci_upper = results$agg_t20$overall.att + 1.96 * results$agg_t20$overall.se
  )
} else {
  list(att = NA, se = NA, ci_lower = NA, ci_upper = NA)
}

# Number of groups/periods
n_groups_t11 <- if (!is.null(results$cs_t11)) length(unique(results$cs_t11$group)) else NA
n_groups_t20 <- if (!is.null(results$cs_t20)) length(unique(results$cs_t20$group)) else NA

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Callaway--Sant'Anna (2021) Aggregate ATT Estimates}\n",
  "\\label{tab:csdid}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) \\\\\n",
  " & Log T11 & Log T20 \\\\\n",
  " & Gambling & Pari-mutuel \\\\\n",
  "\\hline\n",
  sprintf("Aggregate ATT & %s & %s \\\\\n",
          ifelse(is.na(cs_t11_att$att), "---", fmt(cs_t11_att$att)),
          ifelse(is.na(cs_t20_att$att), "---", fmt(cs_t20_att$att))),
  sprintf(" & (%s) & (%s) \\\\\n",
          ifelse(is.na(cs_t11_att$se), "---", fmt(cs_t11_att$se)),
          ifelse(is.na(cs_t20_att$se), "---", fmt(cs_t20_att$se))),
  sprintf("95\\%% CI & [%s, %s] & [%s, %s] \\\\\n",
          ifelse(is.na(cs_t11_att$ci_lower), "---", fmt(cs_t11_att$ci_lower)),
          ifelse(is.na(cs_t11_att$ci_upper), "---", fmt(cs_t11_att$ci_upper)),
          ifelse(is.na(cs_t20_att$ci_lower), "---", fmt(cs_t20_att$ci_lower)),
          ifelse(is.na(cs_t20_att$ci_upper), "---", fmt(cs_t20_att$ci_upper))),
  "\\hline\n",
  sprintf("Treatment groups & %s & %s \\\\\n",
          ifelse(is.na(n_groups_t11), "---", as.character(n_groups_t11)),
          ifelse(is.na(n_groups_t20), "---", as.character(n_groups_t20))),
  "Control group & Never-treated & Never-treated \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.85\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} Estimates from the Callaway and Sant'Anna (2021) ",
  "doubly-robust DiD estimator with never-treated states as the control group. ",
  "Standard errors computed using the multiplier bootstrap (default). ",
  "Aggregate ATT is the simple (equally-weighted) average across all group--time ATTs. ",
  "Sample: 2012--2022.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_csdid.tex"))
cat("  -> tab3_csdid.tex\n")

# ===================================================================
# TABLE 4: Robustness Panel
# ===================================================================

cat("Generating Table 4: Robustness Checks\n")

# Extract robustness coefficients
r1_t11 <- extract_coef(robustness$r1_t11_levels)
r1_t20 <- extract_coef(robustness$r1_t20_levels)
r2_log <- extract_coef(robustness$r2_combined_log)
r2_lev <- extract_coef(robustness$r2_combined_levels)
r3_t11 <- extract_coef(robustness$r3_t11_no_nj)
r3_t20 <- extract_coef(robustness$r3_t20_no_nj)

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llccc}\n",
  "\\hline\\hline\n",
  " & & Coefficient & SE & $N$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Levels instead of logs (millions \\$)}} \\\\\n",
  sprintf("& T11: Gambling & %s%s & (%s) & %s \\\\\n",
          fmt(r1_t11$b), stars(r1_t11$p), fmt(r1_t11$se), fmt0(r1_t11$n)),
  sprintf("& T20: Pari-mutuel & %s%s & (%s) & %s \\\\\n",
          fmt(r1_t20$b), stars(r1_t20$p), fmt(r1_t20$se), fmt0(r1_t20$n)),
  "[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Combined T11 + T20 (total gambling revenue)}} \\\\\n",
  sprintf("& Log(T11 + T20) & %s%s & (%s) & %s \\\\\n",
          fmt(r2_log$b), stars(r2_log$p), fmt(r2_log$se), fmt0(r2_log$n)),
  sprintf("& Levels (millions \\$) & %s%s & (%s) & %s \\\\\n",
          fmt(r2_lev$b), stars(r2_lev$p), fmt(r2_lev$se), fmt0(r2_lev$n)),
  "[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Leave-one-out (drop New Jersey)}} \\\\\n",
  sprintf("& Log T11: Gambling & %s%s & (%s) & %s \\\\\n",
          fmt(r3_t11$b), stars(r3_t11$p), fmt(r3_t11$se), fmt0(r3_t11$n)),
  sprintf("& Log T20: Pari-mutuel & %s%s & (%s) & %s \\\\\n",
          fmt(r3_t20$b), stars(r3_t20$p), fmt(r3_t20$se), fmt0(r3_t20$n)),
  "\\hline\n",
  "State FE & & Yes & & \\\\\n",
  "Year FE & & Yes & & \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} All specifications include state and year fixed effects with standard errors ",
  "clustered at the state level. Panel A reports results in levels (millions of dollars) rather than logs. ",
  "Panel B combines amusement/gambling tax (T11) and pari-mutuel tax (T20) into a single total gambling ",
  "revenue measure. Panel C drops New Jersey, the largest and first state to legalize online sports betting. ",
  "$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("  -> tab4_robustness.tex\n")

# ===================================================================
# TABLE F1: Standardized DiD Estimates (SDE)
# ===================================================================

cat("Generating Table F1: SDE Table\n")

# Extract TWFE coefficients for SDE
sde_t11_beta <- coeftable(results$m1_t11)["post", "Estimate"]
sde_t11_se   <- coeftable(results$m1_t11)["post", "Std. Error"]
sde_t20_beta <- coeftable(results$m2_t20)["post", "Estimate"]
sde_t20_se   <- coeftable(results$m2_t20)["post", "Std. Error"]

# SD of outcome variables (full sample)
sd_log_t11 <- sd(df$log_T11, na.rm = TRUE)
sd_log_t20 <- sd(df$log_T20, na.rm = TRUE)

# SDE = beta / SD(Y)
sde_t11 <- sde_t11_beta / sd_log_t11
sde_t20 <- sde_t20_beta / sd_log_t20

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized DiD Estimates (SDE)}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SD($Y$) & SDE & $N$ \\\\\n",
  "\\hline\n",
  sprintf("Log gambling tax (T11) & %s & %s & %s & %s \\\\\n",
          fmt(sde_t11_beta), fmt(sd_log_t11), fmt(sde_t11),
          fmt0(results$m1_t11$nobs)),
  sprintf("Log pari-mutuel (T20) & %s & %s & %s & %s \\\\\n",
          fmt(sde_t20_beta), fmt(sd_log_t20), fmt(sde_t20),
          fmt0(results$m2_t20$nobs)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\footnotesize \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does legalizing online sports betting generate net new gambling tax revenue or cannibalize existing gambling revenue streams? ",
  "\\textbf{Policy mechanism:} States legalized online sports betting following the 2018 \\textit{Murphy v.\\ NCAA} Supreme Court decision, creating new licensed gambling markets with state-specific tax rates on gross gaming revenue. ",
  "\\textbf{Outcome definition:} Log of state annual amusement/gambling tax revenue (Census STC category T11) and pari-mutuel tax revenue (T20). ",
  "\\textbf{Treatment:} Binary --- state has legalized online sports betting. ",
  "\\textbf{Data:} Census Annual Survey of State Government Tax Collections (STC), 2012--2022, state-year panel, 51 jurisdictions. ",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) and TWFE; state-clustered SEs. ",
  "\\textbf{Sample:} All 51 U.S.\\ state/territory jurisdictions, 2012--2022. ",
  "The SDE divides $\\hat{\\beta}$ by the cross-sectional standard deviation of the outcome, ",
  "providing a unit-free measure of effect magnitude. ",
  "The SDE is a measure of magnitude, not statistical significance; ",
  "see the main tables for standard errors and $p$-values.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("  -> tabF1_sde.tex\n")

cat("\nAll tables generated successfully.\n")
