# 05_tables.R — Generate all LaTeX tables for paper
# apep_0920: MAID Laws and End-of-Life Medicare Spending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
county <- readRDS(file.path(data_dir, "county_panel_clean.rds"))
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
twfe_results <- readRDS(file.path(data_dir, "twfe_county_results.rds"))
cs_results <- readRDS(file.path(data_dir, "cs_state_results.rds"))
wcb_results <- readRDS(file.path(data_dir, "wcb_results.rds"))
placebo_results <- readRDS(file.path(data_dir, "placebo_results.rds"))

# Helper: format with stars
stars_fn <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

fmt <- function(x, digits = 2) {
  formatC(x, format = "f", digits = digits, big.mark = ",")
}

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Estimation sample (exclude always-treated and territories)
always_treated_fips <- c("41", "53", "30", "50")
est_county <- county %>%
  filter(!state_fips %in% c("72", "78"),
         !state_fips %in% always_treated_fips) %>%
  filter(!is.na(county_fips)) %>%
  mutate(
    treated_state = if_else(!is.na(maid_year) & maid_year >= 2014, 1L, 0L),
    treated_post = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L)
  )

# Compute stats for pre-treatment period (2014-2015)
summ_vars <- c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "tot_stdzd_pymt_pc",
               "hospc_users_pct", "er_visits_per_1000", "snf_stdzd_pymt_pc",
               "hh_stdzd_pymt_pc", "bene_avg_age", "bene_dual_pct", "bene_risk_score")

summ_labels <- c("Hospice spending per capita (\\$)",
                 "Inpatient spending per capita (\\$)",
                 "Total Medicare spending per capita (\\$)",
                 "Hospice utilization rate",
                 "ER visits per 1,000",
                 "SNF spending per capita (\\$)",
                 "Home health spending per capita (\\$)",
                 "Average beneficiary age",
                 "Dual-eligible share",
                 "Average HCC risk score")

pre_data <- est_county %>% filter(year <= 2015)

compute_stats <- function(df, var) {
  x <- as.numeric(df[[var]])
  c(mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE),
    max = max(x, na.rm = TRUE),
    n = sum(!is.na(x)))
}

# All counties
all_stats <- sapply(summ_vars, function(v) compute_stats(pre_data, v))

# Treated vs control
treat_stats <- sapply(summ_vars, function(v)
  compute_stats(pre_data %>% filter(treated_state == 1), v))
ctrl_stats <- sapply(summ_vars, function(v)
  compute_stats(pre_data %>% filter(treated_state == 0), v))

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment (2014--2015)}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{All Counties} & \\multicolumn{2}{c}{MAID States} & \\multicolumn{2}{c}{Non-MAID States} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "& Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_along(summ_vars)) {
  row <- paste0(
    summ_labels[i], " & ",
    fmt(all_stats["mean", i]), " & ",
    fmt(all_stats["sd", i]), " & ",
    fmt(treat_stats["mean", i]), " & ",
    fmt(treat_stats["sd", i]), " & ",
    fmt(ctrl_stats["mean", i]), " & ",
    fmt(ctrl_stats["sd", i]), " \\\\"
  )
  tab1_lines <- c(tab1_lines, row)
  if (i == 5) tab1_lines <- c(tab1_lines, "\\midrule")  # Separate outcomes from controls
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  paste0("Counties & \\multicolumn{2}{c}{", n_distinct(pre_data$county_fips),
         "} & \\multicolumn{2}{c}{", n_distinct(pre_data$county_fips[pre_data$treated_state == 1]),
         "} & \\multicolumn{2}{c}{", n_distinct(pre_data$county_fips[pre_data$treated_state == 0]), "} \\\\"),
  paste0("County-years & \\multicolumn{2}{c}{", fmt(nrow(pre_data), 0),
         "} & \\multicolumn{2}{c}{", fmt(sum(pre_data$treated_state == 1), 0),
         "} & \\multicolumn{2}{c}{", fmt(sum(pre_data$treated_state == 0), 0), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\scriptsize",
  paste0("\\item \\textit{Notes:} Pre-treatment county-year observations (2014--2015).",
         " ",
         "MAID states are those that enacted Medical Aid in Dying laws during 2016--2021 ",
         "(CA, CO, DC, HI, NJ, ME, NM). Non-MAID states serve as the control group. ",
         "Spending variables are CMS Medicare FFS standardized payments per capita. ",
         "Always-treated states (OR, WA, MT, VT) are excluded from the estimation sample."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written:", file.path(tables_dir, "tab1_summary.tex"), "\n")

# ============================================================================
# TABLE 2: Main Results — TWFE + CS-DiD + WCB
# ============================================================================

cat("=== Generating Table 2: Main Results ===\n")

outcome_labels <- c(
  "hospc_stdzd_pymt_pc" = "Hospice",
  "ip_stdzd_pymt_pc" = "Inpatient",
  "tot_stdzd_pymt_pc" = "Total",
  "hospc_users_pct" = "Hospice util.",
  "er_visits_per_1000" = "ER visits"
)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of MAID Legalization on Medicare Spending Composition}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0("& ", paste(outcome_labels, collapse = " & "), " \\\\"),
  paste0("& (1) & (2) & (3) & (4) & (5) \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: County-Level TWFE}} \\\\"
)

# Panel A: TWFE county-level
beta_row <- "MAID enacted"
se_row <- ""

for (outcome_var in names(outcome_labels)) {
  twfe <- twfe_results[[outcome_var]]$model
  b <- as.numeric(coef(twfe)["treated_post"])
  s <- as.numeric(fixest::se(twfe)["treated_post"])
  p <- 2 * pnorm(-abs(b/s))
  star <- stars_fn(p)

  beta_row <- paste0(beta_row, " & ", fmt(b), star)
  se_row <- paste0(se_row, " & (", fmt(s), ")")
}

tab2_lines <- c(tab2_lines, paste0(beta_row, " \\\\"), paste0(se_row, " \\\\"))

# WCB p-values
wcb_row <- "WCB $p$-value"
for (outcome_var in names(outcome_labels)) {
  p <- wcb_results[[outcome_var]]$p_value
  if (is.null(p) || is.na(p)) {
    wcb_row <- paste0(wcb_row, " & ---")
  } else {
    wcb_row <- paste0(wcb_row, " & [", fmt(p, 3), "]")
  }
}
tab2_lines <- c(tab2_lines, paste0(wcb_row, " \\\\"))

# N and clusters
n_row <- "$N$"
for (outcome_var in names(outcome_labels)) {
  n <- nobs(twfe_results[[outcome_var]]$model)
  n_row <- paste0(n_row, " & ", formatC(n, format = "d", big.mark = ","))
}
tab2_lines <- c(tab2_lines, paste0(n_row, " \\\\"))

# Pre-treatment mean
mean_row <- "Pre-treatment mean"
for (outcome_var in names(outcome_labels)) {
  m <- twfe_results[[outcome_var]]$pre_mean
  mean_row <- paste0(mean_row, " & ", fmt(m))
}
tab2_lines <- c(tab2_lines, paste0(mean_row, " \\\\"))

# Panel B: CS state-level
tab2_lines <- c(tab2_lines,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Callaway--Sant'Anna (State-Level)}} \\\\"
)

cs_beta_row <- "ATT"
cs_se_row <- ""
for (outcome_var in names(outcome_labels)) {
  if (!is.null(cs_results[[outcome_var]])) {
    b <- cs_results[[outcome_var]]$att
    s <- cs_results[[outcome_var]]$se
    p <- 2 * pnorm(-abs(b/s))
    star <- stars_fn(p)
    cs_beta_row <- paste0(cs_beta_row, " & ", fmt(b), star)
    cs_se_row <- paste0(cs_se_row, " & (", fmt(s), ")")
  } else {
    cs_beta_row <- paste0(cs_beta_row, " & ---")
    cs_se_row <- paste0(cs_se_row, " & ---")
  }
}
tab2_lines <- c(tab2_lines, paste0(cs_beta_row, " \\\\"), paste0(cs_se_row, " \\\\"))

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\scriptsize",
  paste0("\\item \\textit{Notes:} Panel A reports TWFE estimates from county-level regressions ",
         "with county and year fixed effects. Standard errors clustered at the state level ",
         "in parentheses. Wild cluster bootstrap $p$-values (Rademacher weights, 9,999 iterations) ",
         "in brackets. Panel B reports Callaway--Sant'Anna (2021) ATT estimates from state-level ",
         "regressions using never-treated states as controls. ",
         "Spending variables are CMS Medicare FFS standardized payments per capita (2014--2023). ",
         "MAID states: CA (2016), CO (2016), DC (2017), HI (2019), NJ (2019), ME (2019), NM (2021). ",
         "Always-treated states (OR, WA, MT, VT) excluded. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Written:", file.path(tables_dir, "tab2_main.tex"), "\n")

# ============================================================================
# TABLE 3: Robustness — Placebo, Always-Treated, DDD
# ============================================================================

cat("=== Generating Table 3: Robustness ===\n")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& Hospice & Inpatient & Total & ER visits \\\\",
  "& (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Placebo Outcomes}} \\\\"
)

# Placebo: SNF
snf_m <- placebo_results[["snf_stdzd_pymt_pc"]]
hh_m <- placebo_results[["hh_stdzd_pymt_pc"]]
tab3_lines <- c(tab3_lines,
  paste0("SNF spending & \\multicolumn{4}{c}{",
         fmt(coef(snf_m)["treated_post"]), stars_fn(2*pnorm(-abs(tstat(snf_m)["treated_post"]))),
         " (", fmt(fixest::se(snf_m)["treated_post"]), ")} \\\\"),
  paste0("Home health spending & \\multicolumn{4}{c}{",
         fmt(coef(hh_m)["treated_post"]), stars_fn(2*pnorm(-abs(tstat(hh_m)["treated_post"]))),
         " (", fmt(fixest::se(hh_m)["treated_post"]), ")} \\\\")
)

# Panel B: Include always-treated
always_treat_results <- readRDS(file.path(data_dir, "always_treat_results.rds"))
tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Include Always-Treated States (OR, WA, MT, VT)}} \\\\"
)

at_row <- "MAID enacted"
at_se <- ""
for (ov in c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "tot_stdzd_pymt_pc", "er_visits_per_1000")) {
  m <- always_treat_results[[ov]]
  b <- coef(m)["treated_post"]
  s <- as.numeric(fixest::se(m)["treated_post"])
  p <- 2*pnorm(-abs(b/s))
  at_row <- paste0(at_row, " & ", fmt(b), stars_fn(p))
  at_se <- paste0(at_se, " & (", fmt(s), ")")
}
tab3_lines <- c(tab3_lines, paste0(at_row, " \\\\"), paste0(at_se, " \\\\"))

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\scriptsize",
  paste0("\\item \\textit{Notes:} Panel A reports TWFE estimates on placebo outcomes ",
         "(SNF and home health spending) that should not be affected by MAID legalization. ",
         "Panel B includes always-treated states (OR, WA, MT, VT) in the estimation sample. ",
         "All specifications include county and year fixed effects with state-clustered standard errors. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_robust.tex"))
cat("  Written:", file.path(tables_dir, "tab3_robust.tex"), "\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================================

cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# --- Panel A: Pooled ---
sde_rows_a <- list()

main_outcomes <- c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc",
                   "tot_stdzd_pymt_pc", "er_visits_per_1000")
main_labels <- c("Hospice spending per capita",
                 "Inpatient spending per capita",
                 "Total Medicare spending per capita",
                 "ER visits per 1,000 beneficiaries")

for (i in seq_along(main_outcomes)) {
  ov <- main_outcomes[i]
  twfe <- twfe_results[[ov]]$model
  b <- as.numeric(coef(twfe)["treated_post"])
  s <- as.numeric(fixest::se(twfe)["treated_post"])
  sd_y <- twfe_results[[ov]]$overall_sd

  sde <- b / sd_y
  se_sde <- s / sd_y

  classify <- function(sde_val) {
    dplyr::case_when(
      sde_val < -0.15 ~ "Large negative",
      sde_val < -0.05 ~ "Moderate negative",
      sde_val < -0.005 ~ "Small negative",
      sde_val < 0.005 ~ "Null",
      sde_val < 0.05 ~ "Small positive",
      sde_val < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  }

  sde_rows_a[[ov]] <- c(
    label = main_labels[i],
    beta = fmt(b),
    se_beta = fmt(s),
    sd_y = fmt(sd_y),
    sde = fmt(sde, 4),
    se_sde = fmt(se_sde, 4),
    classification = classify(sde)
  )
}

# --- Panel B: Heterogeneous (sample splits) ---
# Split 1: High vs Low baseline hospice utilization states
est_county_full <- county %>%
  filter(!state_fips %in% c("72", "78"),
         !state_fips %in% always_treated_fips) %>%
  filter(!is.na(county_fips)) %>%
  mutate(
    treated_post = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    state_id = as.integer(factor(state_fips)),
    county_id_num = as.integer(factor(county_fips))
  )

# Compute baseline hospice utilization (2014)
baseline_hospice <- est_county_full %>%
  filter(year == 2014, !is.na(hospc_stdzd_pymt_pc)) %>%
  group_by(state_fips) %>%
  summarise(baseline_hospc = median(hospc_stdzd_pymt_pc, na.rm = TRUE)) %>%
  ungroup()

median_baseline <- median(baseline_hospice$baseline_hospc, na.rm = TRUE)

est_county_het <- est_county_full %>%
  left_join(baseline_hospice, by = "state_fips") %>%
  mutate(high_hospice = if_else(baseline_hospc >= median_baseline, 1L, 0L))

sde_rows_b <- list()

# High baseline hospice
high_df <- est_county_het %>% filter(high_hospice == 1, !is.na(hospc_stdzd_pymt_pc))
high_twfe <- feols(hospc_stdzd_pymt_pc ~ treated_post | county_id_num + year,
                   data = high_df, cluster = ~state_id)
sd_y_high <- sd(high_df$hospc_stdzd_pymt_pc, na.rm = TRUE)
b_h <- as.numeric(coef(high_twfe)["treated_post"])
s_h <- as.numeric(fixest::se(high_twfe)["treated_post"])
sde_h <- b_h / sd_y_high

sde_rows_b[["high"]] <- c(
  label = "Hospice spending --- high baseline",
  beta = fmt(b_h), se_beta = fmt(s_h),
  sd_y = fmt(sd_y_high),
  sde = fmt(sde_h, 4), se_sde = fmt(s_h/sd_y_high, 4),
  classification = classify(sde_h)
)

# Low baseline hospice
low_df <- est_county_het %>% filter(high_hospice == 0, !is.na(hospc_stdzd_pymt_pc))
low_twfe <- feols(hospc_stdzd_pymt_pc ~ treated_post | county_id_num + year,
                  data = low_df, cluster = ~state_id)
sd_y_low <- sd(low_df$hospc_stdzd_pymt_pc, na.rm = TRUE)
b_l <- as.numeric(coef(low_twfe)["treated_post"])
s_l <- as.numeric(fixest::se(low_twfe)["treated_post"])
sde_l <- b_l / sd_y_low

sde_rows_b[["low"]] <- c(
  label = "Hospice spending --- low baseline",
  beta = fmt(b_l), se_beta = fmt(s_l),
  sd_y = fmt(sd_y_low),
  sde = fmt(sde_l, 4), se_sde = fmt(s_l/sd_y_low, 4),
  classification = classify(sde_l)
)

# --- Build LaTeX table ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level legalization of Medical Aid in Dying shift Medicare ",
  "fee-for-service spending away from acute inpatient care toward hospice and palliative care? ",
  "\\textbf{Policy mechanism:} MAID laws allow terminally ill adults with fewer than six months to live ",
  "to request a lethal prescription from a physician, potentially normalizing end-of-life planning, increasing ",
  "advance directive completion, and shifting provider norms toward palliative care for all terminal patients, ",
  "not just MAID users. ",
  "\\textbf{Outcome definition:} CMS Medicare Fee-for-Service standardized payments per capita and utilization ",
  "rates by service category (hospice, inpatient, total, emergency room), aggregated at the county-year level. ",
  "\\textbf{Treatment:} Binary indicator for state MAID law in effect (staggered adoption: CA and CO in 2016, ",
  "DC in 2017, HI, NJ, and ME in 2019, NM in 2021). ",
  "\\textbf{Data:} CMS Medicare Geographic Variation Public Use File, 2014--2023, county-year panel with ",
  "30,429 observations across 3,056 counties in 47 states and DC. ",
  "\\textbf{Method:} Two-way fixed effects (county + year) with state-clustered standard errors; ",
  "Callaway--Sant'Anna (2021) as robustness; wild cluster bootstrap for few-cluster inference. ",
  "\\textbf{Sample:} Counties in 47 states plus DC; four always-treated states (OR, WA, MT, VT) and ",
  "territories excluded from the estimation sample. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (row in sde_rows_a) {
  sde_lines <- c(sde_lines,
    paste0(row["label"], " & ", row["beta"], " & ", row["se_beta"], " & ",
           row["sd_y"], " & ", row["sde"], " & ", row["se_sde"], " & ",
           row["classification"], " \\\\")
  )
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline hospice spending)}} \\\\"
)

for (row in sde_rows_b) {
  sde_lines <- c(sde_lines,
    paste0(row["label"], " & ", row["beta"], " & ", row["se_beta"], " & ",
           row["sd_y"], " & ", row["sde"], " & ", row["se_sde"], " & ",
           row["classification"], " \\\\")
  )
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\scriptsize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written:", file.path(tables_dir, "tabF1_sde.tex"), "\n")

cat("\n=== All tables generated ===\n")
