# 05_tables.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Generate all LaTeX tables: summary stats, main results, event study,
# heterogeneity, robustness, and SDE disclosure

source("00_packages.R")

data_dir   <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------
# 1. Load data and results
# ------------------------------------------------------------------
all_workers        <- readRDS(file.path(data_dir, "all_workers.rds"))
black_workers      <- readRDS(file.path(data_dir, "black_workers.rds"))
main_results       <- readRDS(file.path(data_dir, "main_results.rds"))
robustness_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

cs_all_hirn   <- main_results$cs_all_hirn
cs_black_hirn <- main_results$cs_black_hirn
cs_all_emp    <- main_results$cs_all_emp
twfe_all_hirn   <- main_results$twfe_all_hirn
twfe_black_hirn <- main_results$twfe_black_hirn
twfe_all_emp    <- main_results$twfe_all_emp

# ------------------------------------------------------------------
# Helper: write LaTeX with adjustbox wrapper
# ------------------------------------------------------------------
write_tex <- function(tex_body, caption, label, filename,
                      notes = NULL, tpnote_header = "\\textit{Notes:}") {
  # tex_body: the tabular environment content (inside threeparttable)
  notes_block <- ""
  if (!is.null(notes)) {
    note_items <- paste0("\\item ", notes, collapse = "\n")
    notes_block <- sprintf(
      "\\begin{tablenotes}[flushleft]\n\\footnotesize\n%s %s\n\\end{tablenotes}",
      tpnote_header, paste(notes, collapse = " ")
    )
  }

  full_tex <- sprintf(
    "\\begin{table}[htbp]\n\\centering\n\\caption{%s}\n\\label{%s}\n\\begin{adjustbox}{max width=\\textwidth}\n\\begin{threeparttable}\n%s\n%s\n\\end{threeparttable}\n\\end{adjustbox}\n\\end{table}",
    caption, label, tex_body, notes_block
  )
  writeLines(full_tex, file.path(tables_dir, filename))
  cat("Saved:", filename, "\n")
}

# Helper: format coefficient + SE in two-row style
fmt_coef <- function(est, se_val, stars = TRUE) {
  if (is.na(est)) return(list(coef = "--", se = ""))
  pval <- 2 * pnorm(-abs(est / se_val))
  star <- if (stars) {
    if (pval < 0.01) "$^{***}$" else if (pval < 0.05) "$^{**}$" else if (pval < 0.1) "$^{*}$" else ""
  } else ""
  list(
    coef = sprintf("%.4f%s", est, star),
    se   = sprintf("(%.4f)", se_val)
  )
}

# ------------------------------------------------------------------
# Table 1: Summary Statistics by treatment group AND by race
# ------------------------------------------------------------------
cat("\n--- Generating tab1_summary.tex ---\n")

sum_stats <- function(df, group_label) {
  df %>%
    summarise(
      group    = group_label,
      n_states = n_distinct(state_id),
      n_obs    = n(),
      emp_mean = mean(Emp,      na.rm = TRUE),
      emp_sd   = sd(Emp,        na.rm = TRUE),
      hirn_mean = mean(HirN,    na.rm = TRUE),
      hirn_sd  = sd(HirN,       na.rm = TRUE),
      hirn_rate_mean = mean(hirn_rate, na.rm = TRUE),
      hirn_rate_sd   = sd(hirn_rate,   na.rm = TRUE),
      earns_mean = mean(EarnS,  na.rm = TRUE),
      earns_sd   = sd(EarnS,    na.rm = TRUE),
      ur_mean  = mean(unemp_rate, na.rm = TRUE),
      ur_sd    = sd(unemp_rate,   na.rm = TRUE)
    )
}

ss_treated_all   <- sum_stats(all_workers   %>% filter(treated == 1), "Treated -- All")
ss_control_all   <- sum_stats(all_workers   %>% filter(treated == 0), "Control -- All")
ss_treated_black <- sum_stats(black_workers %>% filter(treated == 1), "Treated -- Black")
ss_control_black <- sum_stats(black_workers %>% filter(treated == 0), "Control -- Black")

ss_combined <- bind_rows(ss_treated_all, ss_control_all,
                         ss_treated_black, ss_control_black)

tab1_body <- paste0(
  "\\begin{tabular}{lcccccccc}\n",
  "\\hline\\hline\n",
  " & N States & N Obs & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{New Hires} & \\multicolumn{2}{c}{Unemp. Rate} \\\\\n",
  "\\cmidrule(lr){4-5}\\cmidrule(lr){6-7}\\cmidrule(lr){8-9}\n",
  " & & & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  paste(apply(ss_combined, 1, function(r) {
    sprintf("%s & %s & %s & %.0f & %.0f & %.0f & %.0f & %.2f & %.2f \\\\",
            r["group"],
            r["n_states"],
            format(as.numeric(r["n_obs"]), big.mark = ","),
            as.numeric(r["emp_mean"]),
            as.numeric(r["emp_sd"]),
            as.numeric(r["hirn_mean"]),
            as.numeric(r["hirn_sd"]),
            as.numeric(r["ur_mean"]),
            as.numeric(r["ur_sd"]))
  }), collapse = "\n"),
  "\n\\hline\\hline\n",
  "\\end{tabular}"
)

write_tex(
  tex_body = tab1_body,
  caption  = "Summary Statistics by Treatment Group and Race",
  label    = "tab:summary",
  filename = "tab1_summary.tex",
  notes    = "Unit of observation is state-quarter pair, 2019Q1--2023Q4. Employment (Emp) and New Hires (HirN) are quarterly counts from the Quarterly Workforce Indicators (QWI). Treated states terminated SNAP Emergency Allotments before February 2023. Race categories: All = all workers (A0); Black = Black workers (A2). Unemployment rate from FRED."
)

# ------------------------------------------------------------------
# Table 2: Main CS-DiD ATT (all workers and Black workers)
# ------------------------------------------------------------------
cat("\n--- Generating tab2_main.tex ---\n")

get_att_row <- function(cs_result, twfe_result, outcome_label) {
  cs_att <- if (!is.null(cs_result)) cs_result$overall_att else NA_real_
  cs_se  <- if (!is.null(cs_result)) cs_result$overall_se  else NA_real_
  tw_att <- coef(twfe_result)[names(coef(twfe_result))[1]]
  tw_se  <- se(twfe_result)[names(se(twfe_result))[1]]
  n_obs  <- if (!is.null(cs_result)) cs_result$n_obs else nobs(twfe_result)

  cs_fmt <- fmt_coef(cs_att, cs_se)
  tw_fmt <- fmt_coef(tw_att, tw_se)

  list(
    outcome = outcome_label,
    cs_coef = cs_fmt$coef,
    cs_se   = cs_fmt$se,
    tw_coef = tw_fmt$coef,
    tw_se   = tw_fmt$se,
    n_obs   = format(n_obs, big.mark = ",")
  )
}

rows <- list(
  get_att_row(cs_all_hirn,   twfe_all_hirn,   "Log New Hires -- All Workers"),
  get_att_row(cs_all_emp,    twfe_all_emp,     "Log Employment -- All Workers"),
  get_att_row(cs_black_hirn, twfe_black_hirn,  "Log New Hires -- Black Workers")
)

tab2_body <- paste0(
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{CS-DiD} & \\multicolumn{2}{c}{TWFE} \\\\\n",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n",
  "Outcome & ATT & SE & Coef. & SE \\\\\n",
  "\\hline\n",
  paste(sapply(rows, function(r) {
    sprintf(
      "%s & %s & %s & %s & %s \\\\\n & %s & & %s & [N = %s] \\\\[4pt]",
      r$outcome, r$cs_coef, r$cs_se, r$tw_coef, r$tw_se,
      r$cs_se, r$tw_se, r$n_obs
    )
  }), collapse = "\n"),
  "\n\\hline\n",
  paste0("State FE & \\multicolumn{4}{c}{Yes} \\\\\n"),
  paste0("Time FE  & \\multicolumn{4}{c}{Yes} \\\\\n"),
  paste0("Control group & \\multicolumn{2}{c}{Never-treated} & \\multicolumn{2}{c}{Stacked TWFE} \\\\\n"),
  "\\hline\\hline\n",
  "\\end{tabular}"
)

write_tex(
  tex_body = tab2_body,
  caption  = "Effect of SNAP Emergency Allotment Termination on Labor Market Outcomes",
  label    = "tab:main",
  filename = "tab2_main.tex",
  notes    = "Each row presents estimates from a separate regression. CS-DiD: Callaway-Sant'Anna (2021) difference-in-differences with never-treated states as comparison group. TWFE: two-way fixed effects with state and time fixed effects. Outcome variable is log(1 + count). Sample: 51 state-level units (50 states + DC), 2019Q1--2023Q4 (20 quarters). Standard errors clustered by state. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
)

# ------------------------------------------------------------------
# Table 3: Event Study Coefficients (k = -4 to k = 5)
# ------------------------------------------------------------------
cat("\n--- Generating tab3_event.tex ---\n")

extract_es <- function(cs_result, group_label) {
  if (is.null(cs_result) || is.null(cs_result$aggte_es)) return(NULL)
  es <- cs_result$aggte_es
  data.frame(
    event_time = es$egt,
    att        = es$att.egt,
    se         = es$se.egt,
    group      = group_label
  ) %>%
    filter(!is.na(att), event_time >= -4, event_time <= 5)
}

es_all   <- extract_es(cs_all_hirn,   "All Workers")
es_black <- extract_es(cs_black_hirn, "Black Workers")

if (!is.null(es_all) && !is.null(es_black)) {
  es_wide <- full_join(
    es_all   %>% select(event_time, att_all = att, se_all = se),
    es_black %>% select(event_time, att_blk = att, se_blk = se),
    by = "event_time"
  ) %>%
    arrange(event_time) %>%
    mutate(
      pre_post = if_else(event_time < 0, "Pre", "Post")
    )

  tab3_body <- paste0(
    "\\begin{tabular}{rcccc}\n",
    "\\hline\\hline\n",
    "Event Time & \\multicolumn{2}{c}{All Workers} & \\multicolumn{2}{c}{Black Workers} \\\\\n",
    "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n",
    "$(k)$ & ATT$_k$ & SE & ATT$_k$ & SE \\\\\n",
    "\\hline\n",
    paste(apply(es_wide, 1, function(r) {
      k     <- as.integer(r["event_time"])
      mark  <- if (k == -1) " [ref]" else ""
      a_est <- as.numeric(r["att_all"]); a_se <- as.numeric(r["se_all"])
      b_est <- as.numeric(r["att_blk"]); b_se <- as.numeric(r["se_blk"])

      a_fmt <- fmt_coef(a_est, a_se)
      b_fmt <- fmt_coef(b_est, b_se)

      sprintf("$k=%d$%s & %s & %s & %s & %s \\\\",
              k, mark,
              if (is.na(a_est)) "--" else a_fmt$coef,
              if (is.na(a_se))  "" else a_fmt$se,
              if (is.na(b_est)) "--" else b_fmt$coef,
              if (is.na(b_se))  "" else b_fmt$se)
    }), collapse = "\n"),
    "\n\\hline\\hline\n",
    "\\end{tabular}"
  )

  write_tex(
    tex_body = tab3_body,
    caption  = "Event Study Coefficients: Effect of SNAP Emergency Allotment Termination",
    label    = "tab:eventstudy",
    filename = "tab3_event.tex",
    notes    = "Dynamic ATT estimates from Callaway-Sant'Anna (2021), type = 'dynamic'. Event time $k$ denotes quarters relative to EA termination in the treated state. $k < 0$ are pre-treatment periods; flat pre-trends support parallel trends assumption. Outcome: log(1 + New Hires). Never-treated states as comparison group. Standard errors from multiplier bootstrap (1,000 iterations). $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
  )
} else {
  cat("  WARNING: Event study data unavailable; writing placeholder.\n")
  writeLines(
    "% Event study results unavailable -- check 03_main_analysis.R output",
    file.path(tables_dir, "tab3_event.tex")
  )
}

# ------------------------------------------------------------------
# Table 4: Racial Heterogeneity (all vs Black)
# ------------------------------------------------------------------
cat("\n--- Generating tab4_hetero.tex ---\n")

all_att  <- if (!is.null(cs_all_hirn))   cs_all_hirn$overall_att   else NA_real_
all_se   <- if (!is.null(cs_all_hirn))   cs_all_hirn$overall_se    else NA_real_
blk_att  <- if (!is.null(cs_black_hirn)) cs_black_hirn$overall_att else NA_real_
blk_se   <- if (!is.null(cs_black_hirn)) cs_black_hirn$overall_se  else NA_real_

# Difference and approximate SE (assuming independence)
diff_att <- blk_att - all_att
diff_se  <- sqrt(blk_se^2 + all_se^2)

all_fmt  <- fmt_coef(all_att, all_se)
blk_fmt  <- fmt_coef(blk_att, blk_se)
diff_fmt <- fmt_coef(diff_att, diff_se)

tab4_body <- paste0(
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & All Workers & Black Workers & Difference \\\\\n",
  " & (1) & (2) & (2)-(1) \\\\\n",
  "\\hline\n",
  sprintf("CS-DiD ATT & %s & %s & %s \\\\\n",
          all_fmt$coef, blk_fmt$coef, diff_fmt$coef),
  sprintf(" & %s & %s & %s \\\\[4pt]\n",
          all_fmt$se, blk_fmt$se, diff_fmt$se),
  sprintf("N (states) & %d & %d & -- \\\\\n",
          if (!is.null(cs_all_hirn))   cs_all_hirn$n_treated   else NA,
          if (!is.null(cs_black_hirn)) cs_black_hirn$n_treated else NA),
  "\\hline\n",
  "Outcome & \\multicolumn{3}{c}{Log New Hires} \\\\\n",
  "Control group & \\multicolumn{3}{c}{Never-treated (CS-DiD)} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}"
)

write_tex(
  tex_body = tab4_body,
  caption  = "Racial Heterogeneity: CS-DiD Effect of EA Termination on New Hires",
  label    = "tab:hetero",
  filename = "tab4_hetero.tex",
  notes    = "Columns (1) and (2) present CS-DiD overall ATT from separate regressions for all workers (race = A0) and Black workers (race = A2) from the Quarterly Workforce Indicators. Column (3) is the difference, with standard error computed under independence. Outcome: log(1 + New Hires). Never-treated states as comparison group. Standard errors from multiplier bootstrap (1,000 iterations). $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
)

# ------------------------------------------------------------------
# Table 5: Robustness
# ------------------------------------------------------------------
cat("\n--- Generating tab5_robust.tex ---\n")

rob <- robustness_results

r1a <- fmt_coef(coef(rob$twfe_ur_all_hirn)["ea_ended"],   se(rob$twfe_ur_all_hirn)["ea_ended"])
r1b <- fmt_coef(coef(rob$twfe_ur_black_hirn)["ea_ended"], se(rob$twfe_ur_black_hirn)["ea_ended"])

r2a <- fmt_coef(
  if (!is.null(rob$cs_nyt_all))   rob$cs_nyt_all$overall_att   else NA_real_,
  if (!is.null(rob$cs_nyt_all))   rob$cs_nyt_all$overall_se    else NA_real_
)
r2b <- fmt_coef(
  if (!is.null(rob$cs_nyt_black)) rob$cs_nyt_black$overall_att else NA_real_,
  if (!is.null(rob$cs_nyt_black)) rob$cs_nyt_black$overall_se  else NA_real_
)

r3 <- fmt_coef(
  if (!is.na(rob$placebo_coef)) rob$placebo_coef else NA_real_,
  if (!is.na(rob$placebo_se))   rob$placebo_se   else NA_real_
)

r4 <- fmt_coef(
  if (!is.null(rob$cs_earns)) rob$cs_earns$overall.att else NA_real_,
  if (!is.null(rob$cs_earns)) rob$cs_earns$overall.se  else NA_real_
)

tab5_body <- paste0(
  "\\begin{tabular}{lllcc}\n",
  "\\hline\\hline\n",
  "Specification & Outcome & Sample & Coef./ATT & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: TWFE with unemployment control}} \\\\\n",
  sprintf("\\quad All Workers & Log HirN & All states & %s & %s \\\\\n",
          r1a$coef, r1a$se),
  sprintf("\\quad Black Workers & Log HirN & All states & %s & %s \\\\[4pt]\n",
          r1b$coef, r1b$se),
  "\\multicolumn{5}{l}{\\textit{Panel B: CS-DiD with not-yet-treated control}} \\\\\n",
  sprintf("\\quad All Workers & Log HirN & All states & %s & %s \\\\\n",
          r2a$coef, r2a$se),
  sprintf("\\quad Black Workers & Log HirN & All states & %s & %s \\\\[4pt]\n",
          r2b$coef, r2b$se),
  "\\multicolumn{5}{l}{\\textit{Panel C: Pre-COVID placebo (fake treatment 2019Q3)}} \\\\\n",
  sprintf("\\quad All Workers & Log HirN & 2019Q1--2020Q1 & %s & %s \\\\[4pt]\n",
          r3$coef, r3$se),
  "\\multicolumn{5}{l}{\\textit{Panel D: Earnings outcome}} \\\\\n",
  sprintf("\\quad All Workers & Log EarnS & All states & %s & %s \\\\\n",
          r4$coef, r4$se),
  "\\hline\\hline\n",
  "\\end{tabular}"
)

write_tex(
  tex_body = tab5_body,
  caption  = "Robustness Checks",
  label    = "tab:robust",
  filename = "tab5_robust.tex",
  notes    = "Panel A adds the state quarterly unemployment rate (FRED) as a control to the TWFE specification. Panel B uses CS-DiD with not-yet-treated states as the comparison group instead of never-treated. Panel C assigns a fake treatment date of 2019Q3 to eventually-treated states and restricts to the 2019Q1--2020Q1 pre-COVID window; a null result supports pre-trends validity. Panel D uses log total earnings of stable employment (EarnS) as the outcome under the baseline CS-DiD specification. Standard errors clustered by state. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
)

# ------------------------------------------------------------------
# Table F1: SDE Disclosure (all 8 mandatory fields)
# ------------------------------------------------------------------
cat("\n--- Generating tabF1_sde.tex ---\n")

# Construct treatment intensity summary
n_treated <- n_distinct(all_workers$state_id[all_workers$treated == 1])
n_control <- n_distinct(all_workers$state_id[all_workers$treated == 0])
first_ea_end <- "2021Q2 (Idaho, South Dakota)"
last_ea_end  <- "2022Q2 (Alaska)"

sde_body <- paste0(
  "\\begin{tabular}{lp{10cm}}\n",
  "\\hline\\hline\n",
  "\\multicolumn{2}{l}{\\textbf{Study Design Element (SDE) Disclosure}} \\\\\n",
  "\\hline\n",
  "\\textbf{Country} & United States \\\\\n",
  "\\hline\n",
  "\\textbf{Policy} & SNAP Emergency Allotment (EA) termination. During the COVID-19 public health emergency, all SNAP households received a minimum monthly supplement of \\$95 (later \\$250 for small households), added on top of regular benefits. Eighteen states terminated these Emergency Allotments early, between 2021Q2 and 2022Q2, while the remaining states continued until February 2023. This created staggered, state-level variation in the timing of benefit reduction, averaging \\$95--\\$250 per household per month. \\\\\n",
  "\\hline\n",
  sprintf("\\textbf{Treatment Groups} & %d early-terminating states (treated); %d states + DC that continued EA through February 2023 (never-treated in sample). Early terminators span 2021Q2--2022Q2. \\\\\n",
          n_treated, n_control),
  "\\hline\n",
  "\\textbf{Outcome Data} & Quarterly Workforce Indicators (QWI), U.S. Census Bureau, extracted from Azure Blob Storage (az://derived/qwi/rh/n3/). State-level quarterly employment counts (Emp), new hires (HirN), and total earnings of stable employment (EarnS) for all workers (race code A0) and Black workers (race code A2), 2019Q1--2023Q4. \\\\\n",
  "\\hline\n",
  "\\textbf{Identification} & Callaway-Sant'Anna (2021) staggered difference-in-differences. Treatment is the quarter of EA termination in each early-ending state. Comparison group: states that never terminated EA during the sample window. Parallel trends assumption tested via pre-treatment event study coefficients ($k = -4$ to $k = -1$). \\\\\n",
  "\\hline\n",
  "\\textbf{Estimation Method} & CS-DiD with multiplier bootstrap standard errors (1,000 iterations). Supplementary TWFE estimates with two-way (state $\\times$ time) fixed effects and cluster-robust standard errors by state. \\\\\n",
  "\\hline\n",
  "\\textbf{Sample Period} & 2019Q1--2023Q4 (20 quarters). Pre-treatment window: 2019Q1--2021Q1 (8 quarters before the earliest EA termination in the sample). \\\\\n",
  "\\hline\n",
  "\\textbf{Magnitude \\& Significance} & Effect magnitudes are reported as log-point changes in new hires or employment stock. For interpretability, $\\exp(\\hat{\\beta}) - 1$ approximates the percentage change. Results should be interpreted as local average treatment effects on the treated (ATT) states. Statistical significance at conventional levels (10\\%, 5\\%, 1\\%) is indicated by $^{*}$, $^{**}$, $^{***}$ respectively; a null result is a finding, not a failure. \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}"
)

write_tex(
  tex_body = sde_body,
  caption  = "Study Design Element (SDE) Disclosure",
  label    = "tab:sde",
  filename = "tabF1_sde.tex",
  notes    = NULL
)

cat("\nAll tables generated in:", tables_dir, "\n")
cat(list.files(tables_dir, pattern = "\\.tex$"), sep = "\n")

cat("\n05_tables.R complete.\n")
