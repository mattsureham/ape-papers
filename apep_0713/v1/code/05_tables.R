## 05_tables.R — Generate all LaTeX tables for apep_0713

source("code/00_packages.R")

results     <- readRDS("data/main_results.rds")
rob_results <- readRDS("data/robustness_results.rds")
bds_panel   <- readRDS("data/bds_panel.rds")
acs_panel   <- readRDS("data/acs_panel.rds")

## Helper: format p-values as stars
pstars <- function(p) {
  case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.1 ~ "*", TRUE ~ "")
}

## Helper: format coefficient with stars
fmt_coef <- function(att, se) {
  p <- 2 * pnorm(-abs(att / se))
  paste0(sprintf("%.4f", att), pstars(p))
}

fmt_se <- function(se) paste0("(", sprintf("%.4f", se), ")")

## ============================================================
## TABLE 1: SUMMARY STATISTICS
## ============================================================

## Pre-treatment summary stats
## bds_panel already has year_enacted merged in from clean_data
## but just in case, we re-join to be safe
preemption_laws_tab <- readRDS("data/preemption_laws.rds")

bds_pre <- bds_panel %>%
  filter(year <= 2010) %>%
  left_join(preemption_laws_tab %>% select(state_fip, year_enacted),
            by = "state_fip", suffix = c("", ".plaw")) %>%
  mutate(
    ## Use merged year_enacted.plaw if year_enacted not in bds_panel
    year_enacted_use = coalesce(year_enacted, year_enacted.plaw),
    treated = as.integer(!is.na(year_enacted_use))
  )

sum_stats <- bds_pre %>%
  group_by(treated) %>%
  summarise(
    n_states = n_distinct(state_fip),
    mean_firms = round(mean(firms, na.rm=TRUE), 0),
    mean_emp = round(mean(employment/1000, na.rm=TRUE), 1),
    mean_birth_rate = round(mean(firm_birth_rate * 100, na.rm=TRUE), 2),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(treated == 1, "Preemption States", "Never-Preempted States"))

tab1 <- sum_stats %>%
  select(Group, n_states, mean_firms, mean_emp, mean_birth_rate)

# Broadband summary
acs_pre <- acs_panel %>%
  filter(year == 2015) %>%
  mutate(treated = as.integer(!is.na(year_enacted)))

bb_sum <- acs_pre %>%
  group_by(treated) %>%
  summarise(
    mean_bb_rate = round(mean(broadband_rate * 100, na.rm=TRUE), 1),
    n = n(),
    .groups = "drop"
  )

## LaTeX table 1
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Characteristics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & N States & Firms (mean) & Employment (000s) & Firm Birth Rate (\\%) \\\\\n",
  "\\hline\n",
  "Preemption States & ", sum_stats$n_states[sum_stats$treated==1], " & ",
                          sum_stats$mean_firms[sum_stats$treated==1], " & ",
                          sum_stats$mean_emp[sum_stats$treated==1], " & ",
                          sum_stats$mean_birth_rate[sum_stats$treated==1], " \\\\\n",
  "Never-Preempted States & ", sum_stats$n_states[sum_stats$treated==0], " & ",
                               sum_stats$mean_firms[sum_stats$treated==0], " & ",
                               sum_stats$mean_emp[sum_stats$treated==0], " & ",
                               sum_stats$mean_birth_rate[sum_stats$treated==0], " \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Notes:} Pre-treatment summary statistics (2004--2010). ",
  "Firm birth rate = job-creating firm births / total firms. Source: Census BDS.}\\\\\n",
  "\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ============================================================
## TABLE 2: MAIN DiD RESULTS
## ============================================================

## Extract results
att_bb  <- results$agg_broadband$overall.att
se_bb   <- results$agg_broadband$overall.se
att_fir <- results$agg_firms$overall.att
se_fir  <- results$agg_firms$overall.se

twfe_bb_coef  <- coef(results$twfe_broadband)[1]
twfe_bb_se    <- se(results$twfe_broadband)[1]
twfe_fir_coef <- coef(results$twfe_firms)[1]
twfe_fir_se   <- se(results$twfe_firms)[1]

## N obs
n_acs <- nrow(acs_panel %>% filter(!is.na(broadband_rate)))
n_bds <- nrow(bds_panel)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Broadband Preemption on Broadband Adoption and Firm Formation}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & (1) Broadband Rate (pct pt) & (2) Firm Birth Rate (log) \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: TWFE}} \\\\\n",
  "Preempted & ", fmt_coef(twfe_bb_coef, twfe_bb_se), " & ",
                  fmt_coef(twfe_fir_coef, twfe_fir_se), " \\\\\n",
  " & ", fmt_se(twfe_bb_se), " & ", fmt_se(twfe_fir_se), " \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Callaway--Sant'Anna (2021) ATT}} \\\\\n",
  "ATT & ", fmt_coef(att_bb, se_bb), " & ", fmt_coef(att_fir, se_fir), " \\\\\n",
  " & ", fmt_se(se_bb), " & ", fmt_se(se_fir), " \\\\\n",
  "\\hline\n",
  "State FE & \\checkmark & \\checkmark \\\\\n",
  "Year FE & \\checkmark & \\checkmark \\\\\n",
  "Observations & ", n_acs, " & ", n_bds, " \\\\\n",
  "States & ", n_distinct(acs_panel$state_fip), " & ", n_distinct(bds_panel$state_fip), " \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Notes:} Clustered SEs at state level in parentheses. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.} \\\\\n",
  "\\multicolumn{3}{l}{Panel A uses two-way fixed effects. ",
  "Panel B uses Callaway-Sant'Anna (2021) staggered DiD with} \\\\\n",
  "\\multicolumn{3}{l}{never-treated states as control group. ",
  "Broadband rate from Census ACS 2015--2023; firm births from Census BDS 2004--2023.}\\\\\n",
  "\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "tables/tab2_main.tex")
cat("Table 2 written.\n")

## ============================================================
## TABLE 3: EVENT STUDY COEFFICIENTS
## ============================================================

es_firms_df     <- results$es_firms_df
es_broadband_df <- results$es_broadband_df

## Keep rel_time = -5 to +5
es_show <- es_firms_df %>%
  filter(event_time >= -5, event_time <= 5) %>%
  left_join(
    es_broadband_df %>%
      filter(event_time >= -5, event_time <= 5) %>%
      select(event_time, att_bb = att, se_bb = se),
    by = "event_time"
  )

## Build LaTeX
rows <- apply(es_show, 1, function(r) {
  et  <- as.integer(r["event_time"])
  a   <- as.numeric(r["att"])
  s   <- as.numeric(r["se"])
  a_b <- as.numeric(r["att_bb"])
  s_b <- as.numeric(r["se_bb"])
  paste0(
    et, " & ",
    fmt_coef(a_b, s_b), " & ", fmt_se(s_b), " & ",
    fmt_coef(a, s), " & ", fmt_se(s), " \\\\\n"
  )
})

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of Broadband Preemption}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Years Relative & \\multicolumn{2}{c}{Broadband Rate (pct pt)} ",
  "& \\multicolumn{2}{c}{Firm Birth Rate (log)} \\\\\n",
  "to Enactment & ATT & SE & ATT & SE \\\\\n",
  "\\hline\n",
  paste(rows, collapse=""),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Notes:} ",
  "Callaway-Sant'Anna (2021) event-study coefficients. Relative time 0 = year of preemption law enactment.} \\\\\n",
  "\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

## ============================================================
## TABLE 4: ROBUSTNESS CHECKS
## ============================================================

## Collect robustness ATTs
nyt_att <- rob_results$nyt_firms$overall.att
nyt_se  <- rob_results$nyt_firms$overall.se
rep_att <- ifelse(!is.null(rob_results$repeal$overall.att),
                  rob_results$repeal$overall.att, NA_real_)
rep_se  <- ifelse(!is.null(rob_results$repeal$overall.se),
                  rob_results$repeal$overall.se, NA_real_)
plac_att <- rob_results$placebo$overall.att
plac_se  <- rob_results$placebo$overall.se
bband_nyt_att <- rob_results$broadband_nyt$overall.att
bband_nyt_se  <- rob_results$broadband_nyt$overall.se

fmt_row <- function(label, att, se, note="") {
  p <- 2 * pnorm(-abs(att / se))
  paste0(label, " & ",
         sprintf("%.4f", att), pstars(p), " & ",
         fmt_se(se), " & ", note, " \\\\\n")
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Specification & ATT & SE & Notes \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Firm Birth Rate (log)}} \\\\\n",
  fmt_row("Baseline (CS-DiD, never-treated control)",
          results$agg_firms$overall.att, results$agg_firms$overall.se, "Main spec"),
  fmt_row("Not-yet-treated control",
          nyt_att, nyt_se, "Alt control"),
  ifelse(!is.na(rep_att),
         fmt_row("Repeal states only (reversal effect)", rep_att, rep_se, "Subset"),
         "Repeal effect & \\multicolumn{3}{l}{Insufficient repeal states for CS-DiD} \\\\\n"),
  fmt_row("Placebo test (pre-period, shifted dates)",
          plac_att, plac_se, "Should be 0"),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Broadband Penetration (pct pt)}} \\\\\n",
  fmt_row("Baseline (CS-DiD, never-treated control)",
          results$agg_broadband$overall.att, results$agg_broadband$overall.se, "Main spec"),
  fmt_row("Not-yet-treated control", bband_nyt_att, bband_nyt_se, "Alt control"),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Notes:} ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$. SEs clustered at state level.}\\\\\n",
  "\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "tables/tab4_robustness.tex")
cat("Table 4 written.\n")

## ============================================================
## TABLE F1: STANDARDIZED EFFECT SIZE (SDE)
## ============================================================

## Helper for SDE classification
classify_sde <- function(sde) {
  case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <=  0.005 ~ "Null",
    sde <=  0.05  ~ "Small positive",
    sde <=  0.15  ~ "Moderate positive",
    TRUE          ~ "Large positive"
  )
}

## Compute SDE for main outcomes
sde_data <- tibble(
  outcome = c(
    "Broadband penetration (pct pt)",
    "Firm birth rate (log)"
  ),
  beta  = c(results$sde$broadband_att, results$sde$firms_att),
  se    = c(results$sde$broadband_se,  results$sde$firms_se),
  sd_y  = c(results$sde$broadband_sd,  results$sde$firms_sd)
) %>%
  mutate(
    sde    = beta / sd_y,
    se_sde = se  / sd_y,
    classif = classify_sde(sde)
  )

## SDE Notes (no numerical results in notes — they belong in the table)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state laws restricting municipal broadband networks ",
  "reduce broadband adoption and new firm formation? ",
  "\\textbf{Policy mechanism:} Municipal broadband preemption laws prohibit or severely ",
  "restrict local governments from building publicly-owned broadband networks, eliminating ",
  "a potential source of competition to incumbent internet service providers and reducing ",
  "pressure to expand coverage and lower prices. ",
  "\\textbf{Outcome definition:} Column (1): broadband internet subscription rate among ",
  "households, from Census ACS Table B28002 (percentage-point scale). ",
  "Column (2): log firm birth rate defined as job-creating firm births per existing firm, ",
  "from Census Business Dynamics Statistics. ",
  "\\textbf{Treatment:} Binary indicator equal to one when a state's municipal broadband ",
  "preemption law is in effect; zero before enactment or after repeal. ",
  "\\textbf{Data:} Column (1): Census ACS 1-year estimates, 2015--2023, 50 states ",
  "(2020 excluded due to non-release); Column (2): Census BDS, 2004--2023, 50 states. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated states ",
  "as comparison group; state-clustered standard errors. ",
  "\\textbf{Sample:} 50 US states; 22 states enacted preemption laws between 1997 and 2020; ",
  "5 states subsequently repealed. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation ",
  "of the outcome across all observations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

## Build LaTeX
sde_rows <- apply(sde_data, 1, function(r) {
  paste0(
    r["outcome"], " & ",
    sprintf("%.4f", as.numeric(r["beta"])), " & ",
    sprintf("%.4f", as.numeric(r["se"])), " & ",
    sprintf("%.4f", as.numeric(r["sd_y"])), " & ",
    sprintf("%.4f", as.numeric(r["sde"])), " & ",
    sprintf("%.4f", as.numeric(r["se_sde"])), " & ",
    r["classif"], " \\\\\n"
  )
})

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes (SDE)}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste(sde_rows, collapse=""),
  "\\hline\n",
  "\\begin{minipage}{\\linewidth}\\vspace{2pt}\\begin{itemize}[leftmargin=*,noitemsep]\n",
  sde_notes, "\n",
  "\\end{itemize}\\end{minipage}\\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== ALL TABLES WRITTEN ===\n")
cat("tables/tab1_summary.tex\n")
cat("tables/tab2_main.tex\n")
cat("tables/tab3_eventstudy.tex\n")
cat("tables/tab4_robustness.tex\n")
cat("tables/tabF1_sde.tex\n")
