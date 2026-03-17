## 05_tables.R — All tables for apep_0714
## Marijuana Expungement × Black Employment DDD

source("code/00_packages.R")

models <- readRDS("data/models.rds")
rob_list <- readRDS("data/robustness_models.rds")
ddd_results <- readRDS("data/ddd_results.rds")
df <- readRDS("data/qwi_analysis.rds")
diagnostics <- jsonlite::read_json("data/diagnostics.json")

spec_a <- models$spec_a
spec_b <- models$spec_b
spec_c <- models$spec_c
spec_d <- models$spec_d
es_coefs <- models$es_coefs

# ============================================================
# TABLE 1: DESCRIPTIVE STATISTICS
# ============================================================

df_expunge <- df %>% filter(group == "expunge")
df_legal <- df %>% filter(group == "legalize_only")

desc_stats <- bind_rows(
  tibble(
    Group = "Expunge States",
    `Mean Black Employment` = mean(df_expunge$emp_black, na.rm=TRUE),
    `Mean White Employment` = mean(df_expunge$emp_white, na.rm=TRUE),
    `Mean Black Earnings` = mean(df_expunge$earn_black, na.rm=TRUE),
    `Mean White Earnings` = mean(df_expunge$earn_white, na.rm=TRUE),
    Counties = n_distinct(df_expunge$county_fips)
  ),
  tibble(
    Group = "Legalize-Only States",
    `Mean Black Employment` = mean(df_legal$emp_black, na.rm=TRUE),
    `Mean White Employment` = mean(df_legal$emp_white, na.rm=TRUE),
    `Mean Black Earnings` = mean(df_legal$earn_black, na.rm=TRUE),
    `Mean White Earnings` = mean(df_legal$earn_white, na.rm=TRUE),
    Counties = n_distinct(df_legal$county_fips)
  )
)

# States summary
states_summary <- tribble(
  ~State, ~Group, ~`Retail Legal`, ~`Auto Expunge`, ~`Expunge Year`,
  "California", "Expunge", "Jan 2018", "Jan 2019", 2019,
  "Illinois", "Expunge", "Jan 2020", "Jan 2020", 2020,
  "New Jersey", "Expunge", "Feb 2022", "Feb 2021", 2021,
  "Virginia", "Expunge", "Jul 2021", "Jul 2021", 2021,
  "New York", "Expunge", "Dec 2022", "Mar 2021", 2021,
  "Colorado", "Legalize-only", "Jan 2014", "None", NA,
  "Washington", "Legalize-only", "Jul 2014", "None", NA,
  "Oregon", "Legalize-only", "Oct 2015", "None", NA,
  "Alaska", "Legalize-only", "Oct 2016", "None", NA
)

states_tex <- states_summary %>%
  knitr::kable("latex", booktabs = TRUE, escape = FALSE,
               caption = "Marijuana Legalization and Automatic Expungement Policy Dates",
               label = "states") %>%
  kableExtra::kable_styling(latex_options = c("hold_position")) %>%
  kableExtra::pack_rows("Expunge States (Treatment)", 1, 5) %>%
  kableExtra::pack_rows("Legalize-Only States (Comparison)", 6, 9) %>%
  kableExtra::add_footnote(
    c("Notes: ``Auto Expunge'' column indicates date when automatic record clearing for prior marijuana convictions began. States in the legalize-only group adopted petition-based expungement only during this period. Sample period: 2013Q1-2023Q4."),
    notation = "none"
  )

writeLines(as.character(states_tex), "tables/tab1_states.tex")
cat("Table 1 (states) saved.\n")

# ============================================================
# TABLE 2: MAIN RESULTS
# ============================================================

# Get coefficients
get_row <- function(mod, coef_name) {
  ct <- coeftable(mod)
  if (coef_name %in% rownames(ct)) {
    row <- ct[coef_name, ]
    c(
      est = as.numeric(row["Estimate"]),
      se = as.numeric(row["Std. Error"]),
      pval = as.numeric(row["Pr(>|t|)"])
    )
  } else {
    c(est=NA, se=NA, pval=NA)
  }
}

format_coef <- function(est, se, pval) {
  stars <- case_when(
    pval < 0.01 ~ "$^{***}$",
    pval < 0.05 ~ "$^{**}$",
    pval < 0.10 ~ "$^{*}$",
    TRUE ~ ""
  )
  sprintf("%.4f%s", est, stars)
}
format_se <- function(se) sprintf("(%.4f)", se)

# Main table: 4 columns
r_expunge_a <- get_row(spec_a, "expunge_state:post_expunge")
r_legal_a   <- get_row(spec_a, "legal_state:post_legal")
r_expunge_c <- get_row(spec_c, "expunge_state:post_expunge")
r_legal_c   <- get_row(spec_c, "legal_state:post_legal")
r_expunge_d <- get_row(spec_d, "expunge_state:post_expunge")
r_legal_d   <- get_row(spec_d, "legal_state:post_legal")

# White earnings
r_expunge_we <- get_row(rob_list$placebo_white_earn, "expunge_state:post_expunge")
r_legal_we   <- get_row(rob_list$placebo_white_earn, "legal_state:post_legal")

nobs_a <- fitstat(spec_a, "n")$n
nobs_c <- fitstat(spec_c, "n")$n
nobs_d <- fitstat(spec_d, "n")$n
nobs_we <- fitstat(rob_list$placebo_white_earn, "n")$n

# Format DDD row
ddd_stars <- case_when(
  ddd_results$ddd_pval < 0.01 ~ "$^{***}$",
  ddd_results$ddd_pval < 0.05 ~ "$^{**}$",
  ddd_results$ddd_pval < 0.10 ~ "$^{*}$",
  TRUE ~ ""
)
ddd_coef_str <- sprintf("%.4f%s", ddd_results$ddd_diff, ddd_stars)
ddd_se_str   <- sprintf("(%.4f)", ddd_results$ddd_se)

main_tab <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Effect of Automatic Marijuana Expungement on Black Employment and Earnings}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Log Emp. & Log Earn. & Log Emp. & Log Earn. \\\\\n",
  " & Black & Black & White & White \\\\\n",
  "\\midrule\n",
  "\\textbf{Expunge} $\\times$ Post & ",
  format_coef(r_expunge_a["est"], r_expunge_a["se"], r_expunge_a["pval"]), " & ",
  format_coef(r_expunge_c["est"], r_expunge_c["se"], r_expunge_c["pval"]), " & ",
  format_coef(r_expunge_d["est"], r_expunge_d["se"], r_expunge_d["pval"]), " & ",
  format_coef(r_expunge_we["est"], r_expunge_we["se"], r_expunge_we["pval"]), " \\\\\n",
  " & ",
  format_se(r_expunge_a["se"]), " & ",
  format_se(r_expunge_c["se"]), " & ",
  format_se(r_expunge_d["se"]), " & ",
  format_se(r_expunge_we["se"]), " \\\\\n",
  "\\textbf{Legal} $\\times$ Post & ",
  format_coef(r_legal_a["est"], r_legal_a["se"], r_legal_a["pval"]), " & ",
  format_coef(r_legal_c["est"], r_legal_c["se"], r_legal_c["pval"]), " & ",
  format_coef(r_legal_d["est"], r_legal_d["se"], r_legal_d["pval"]), " & ",
  format_coef(r_legal_we["est"], r_legal_we["se"], r_legal_we["pval"]), " \\\\\n",
  " & ",
  format_se(r_legal_a["se"]), " & ",
  format_se(r_legal_c["se"]), " & ",
  format_se(r_legal_d["se"]), " & ",
  format_se(r_legal_we["se"]), " \\\\\n",
  "\\midrule\n",
  "\\textit{DDD (cols 2$-$4):} & & & & \\\\\n",
  "\\quad Black$-$White earnings gap & -- & ", ddd_coef_str, " & -- & -- \\\\\n",
  " & -- & ", ddd_se_str, " & -- & -- \\\\\n",
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", nobs_a, " & ", nobs_c, " & ", nobs_d, " & ", nobs_we, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item Notes: Sample includes counties from five expunge states (CA, IL, NJ, VA, NY) and four legalize-only comparison states (CO, WA, OR, AK), 2013Q1--2023Q4. \\textbf{Expunge} $\\times$ Post equals one for expunge-state counties in quarters at or after the state's automatic expungement law took effect. \\textbf{Legal} $\\times$ Post equals one for all legalizing-state counties after retail marijuana sales began. The \\textit{DDD} row reports the difference between column (2) and column (4) coefficients ($\\hat{\\beta}_{\\text{Black}} - \\hat{\\beta}_{\\text{White}}$), with SE computed as $\\sqrt{\\text{SE}_B^2 + \\text{SE}_W^2}$ and $p$-value from $t$-distribution with 7 degrees of freedom (9 states$-$2 groups). Standard errors clustered at the state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(main_tab, "tables/tab2_main.tex")
cat("Table 2 (main results) saved.\n")

# ============================================================
# TABLE 3: ROBUSTNESS
# ============================================================

r1 <- get_row(rob_list$rob1_earn, "expunge_state:post_expunge")
r2 <- get_row(rob_list$rob2_earn, "expunge_state:post_expunge")
r3 <- get_row(rob_list$rob3_earn, "expunge_state:post_expunge")
r_state <- get_row(rob_list$state_earn, "expunge_state:post_expunge")
r_main <- get_row(spec_c, "expunge_state:post_expunge")

n1 <- fitstat(rob_list$rob1_earn, "n")$n
n2 <- fitstat(rob_list$rob2_earn, "n")$n
n3 <- fitstat(rob_list$rob3_earn, "n")$n
n_state <- fitstat(rob_list$state_earn, "n")$n
n_main <- fitstat(spec_c, "n")$n

rob_tab <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Effect of Expungement on Black Earnings (Log)}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Full Sample & No Border & Excl. CA & State-Level \\\\\n",
  "\\midrule\n",
  "\\textbf{Expunge} $\\times$ Post & ",
  format_coef(r_main["est"], r_main["se"], r_main["pval"]), " & ",
  format_coef(r1["est"], r1["se"], r1["pval"]), " & ",
  format_coef(r2["est"], r2["se"], r2["pval"]), " & ",
  format_coef(r3["est"], r3["se"], r3["pval"]), " & ",
  format_coef(r_state["est"], r_state["se"], r_state["pval"]), " \\\\\n",
  " & ",
  format_se(r_main["se"]), " & ",
  format_se(r1["se"]), " & ",
  format_se(r2["se"]), " & ",
  format_se(r3["se"]), " & ",
  format_se(r_state["se"]), " \\\\\n",
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & -- \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes & -- \\\\\n",
  "State + Year FE & -- & -- & -- & -- & Yes \\\\\n",
  "Never-legal controls & No & Yes & No & No & No \\\\\n",
  "Sample restriction & -- & -- & No border & No CA & -- \\\\\n",
  "Observations & ", n_main, " & ", n1, " & ", n2, " & ", n3, " & ", n_state, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item Notes: Dependent variable is log average monthly earnings for Black workers from the QWI. (1) Baseline: expunge vs.~legalize-only states, county $\\times$ state-year FEs, cluster state. (2) Full Sample: adds never-legalized states as controls. (3) No Border: drops counties within 100 miles of a state border. (4) Excl.~CA: IL, NJ, VA, NY expunge states vs.~legalize-only. (5) State-Level: state-quarter panel, state and year FEs. Standard errors clustered at the state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(rob_tab, "tables/tab3_robustness.tex")
cat("Table 3 (robustness) saved.\n")

# ============================================================
# TABLE 4: EVENT STUDY SUMMARY (pre vs. post averages)
# ============================================================

# Extract pre-period and post-period averages from event study
pre_avg <- es_coefs %>% filter(time %in% -8:-2) %>%
  summarise(avg_est = mean(estimate), se = mean(std.error))
post_avg <- es_coefs %>% filter(time %in% 1:11) %>%
  summarise(avg_est = mean(estimate), se = mean(std.error))

es_tab_data <- es_coefs %>%
  filter(time >= -7) %>%
  mutate(
    Period = case_when(time < 0 ~ "Pre-Expungement", time == 0 ~ "Expungement Quarter", TRUE ~ "Post-Expungement"),
    stars = case_when(
      is.na(std.error) | std.error == 0 ~ "(ref.)",
      abs(estimate / std.error) > 2.576 ~ "***",
      abs(estimate / std.error) > 1.960 ~ "**",
      abs(estimate / std.error) > 1.645 ~ "*",
      TRUE ~ ""
    )
  ) %>%
  arrange(time)

# Simple pre-trend test table
pretrend_tab <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Event Study: Black Employment Around Expungement}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{rcc}\n",
  "\\toprule\n",
  "Quarters Relative & \\multicolumn{2}{c}{Log Black Employment} \\\\\n",
  "to Expungement & Coefficient & 95\\% CI \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Pre-Treatment Period}} \\\\\n"
)

pre_rows <- es_coefs %>% filter(time >= -6, time < 0)
for (i in 1:nrow(pre_rows)) {
  r <- pre_rows[i, ]
  pretrend_tab <- paste0(pretrend_tab,
    sprintf("%d & %.4f & [%.4f, %.4f] \\\\\n",
            r$time, r$estimate, r$conf_lo, r$conf_hi))
}

pretrend_tab <- paste0(pretrend_tab,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Post-Treatment Period}} \\\\\n"
)

post_rows <- es_coefs %>% filter(time >= 0, time <= 8)
for (i in 1:nrow(post_rows)) {
  r <- post_rows[i, ]
  stars <- if (!is.na(r$std.error) && r$std.error > 0 && abs(r$estimate/r$std.error) > 1.96) "**" else ""
  pretrend_tab <- paste0(pretrend_tab,
    sprintf("%d & %.4f%s & [%.4f, %.4f] \\\\\n",
            r$time, r$estimate, stars, r$conf_lo, r$conf_hi))
}

pretrend_tab <- paste0(pretrend_tab,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item Notes: Event-study coefficients from TWFE regression of log Black employment on relative-time dummies, estimated on expunge-state counties with county and state $\\times$ year fixed effects. Relative time = 0 denotes the quarter expungement law took effect (staggered: CA 2019Q1, IL 2020Q1, NJ/VA/NY 2021Q1--Q3). Reference period: quarter $-1$. Standard errors clustered at the state level. $^{**}p<0.05$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(pretrend_tab, "tables/tab4_eventstudy.tex")
cat("Table 4 (event study) saved.\n")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) — APPENDIX
# ============================================================

# Compute SDE for main outcomes
df_earn <- readRDS("data/qwi_analysis.rds")

# Pre-treatment SD of Black earnings (expunge + legalize-only states, pre-2019)
pre_sd_earn <- df_earn %>%
  filter(year < 2019, !is.na(earn_black)) %>%
  summarise(sd = sd(earn_black, na.rm=TRUE)) %>%
  pull(sd)

pre_sd_emp <- df_earn %>%
  filter(year < 2019, !is.na(emp_black)) %>%
  summarise(sd = sd(emp_black, na.rm=TRUE)) %>%
  pull(sd)

# Mean of outcomes (for context)
mean_earn_pre <- df_earn %>%
  filter(year < 2019, !is.na(earn_black)) %>%
  summarise(m = mean(earn_black, na.rm=TRUE)) %>%
  pull(m)

# Coefficients are in log units, need to convert for SDE
# For log outcome: beta ≈ percent change → beta * mean = dollar change
# SDE = (beta * mean_earn) / sd(earn) OR we use log SD
pre_sd_log_earn <- df_earn %>%
  filter(year < 2019, !is.na(log_earn_black)) %>%
  summarise(sd = sd(log_earn_black, na.rm=TRUE)) %>%
  pull(sd)

pre_sd_log_emp <- df_earn %>%
  filter(year < 2019, !is.na(log_emp_black)) %>%
  summarise(sd = sd(log_emp_black, na.rm=TRUE)) %>%
  pull(sd)

# Extract coefficients
beta_earn <- coef(spec_c)["expunge_state:post_expunge"]
se_earn    <- fixest::se(spec_c)["expunge_state:post_expunge"]
beta_emp   <- coef(spec_a)["expunge_state:post_expunge"]
se_emp     <- fixest::se(spec_a)["expunge_state:post_expunge"]
beta_earn_white <- coef(rob_list$placebo_white_earn)["expunge_state:post_expunge"]
se_earn_white   <- fixest::se(rob_list$placebo_white_earn)["expunge_state:post_expunge"]

# SDE = beta / SD(Y) — using log outcomes
sde_earn <- as.numeric(beta_earn) / pre_sd_log_earn
se_sde_earn <- as.numeric(se_earn) / pre_sd_log_earn
sde_emp  <- as.numeric(beta_emp) / pre_sd_log_emp
se_sde_emp  <- as.numeric(se_emp) / pre_sd_log_emp
sde_earn_white <- as.numeric(beta_earn_white) / pre_sd_log_earn
se_sde_earn_white <- as.numeric(se_earn_white) / pre_sd_log_earn

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does automatic marijuana record expungement raise Black workers' earnings and employment relative to states that legalized without record clearing? ",
  "\\textbf{Policy mechanism:} Automatic expungement removes prior marijuana possession convictions from court databases in participating states (CA 2019, IL 2020, NJ/VA/NY 2021), eliminating a background-check barrier that previously screened Black applicants out of formal-sector jobs requiring criminal background clearance. Unlike petition-based expungement, automatic clearing requires no action by the individual. ",
  "\\textbf{Outcome definition:} Average monthly earnings (EarnS) and employment count (Emp) from the Census LEHD Quarterly Workforce Indicators, county $\\times$ quarter $\\times$ race panel, private-sector aggregate. ",
  "\\textbf{Treatment:} Binary; counties in states with automatic expungement laws after the effective date versus counties in states that legalized recreational marijuana without automatic expungement. ",
  "\\textbf{Data:} Census LEHD QWI Race-Ethnicity Panel, 2013Q1--2023Q4, county-quarter level, 1,523 counties across 9 states. ",
  "\\textbf{Method:} TWFE with county and state $\\times$ year fixed effects; standard errors clustered at the state level. Comparison group: four legalize-only states (CO, WA, OR, AK). ",
  "\\textbf{Sample:} Private-sector workers, all industries, all ages, male and female combined; counties with at least 50\\% data coverage in pre-treatment periods. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD$(Y)$ is the pre-treatment standard deviation of the log outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Size (SDE) Appendix}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD$(Y)$ & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("Log Black Earnings & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          as.numeric(beta_earn), as.numeric(se_earn), pre_sd_log_earn,
          sde_earn, se_sde_earn, classify_sde(sde_earn)),
  sprintf("Log Black Employment & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          as.numeric(beta_emp), as.numeric(se_emp), pre_sd_log_emp,
          sde_emp, se_sde_emp, classify_sde(sde_emp)),
  sprintf("Log White Earnings & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          as.numeric(beta_earn_white), as.numeric(se_earn_white), pre_sd_log_earn,
          sde_earn_white, se_sde_earn_white, classify_sde(sde_earn_white)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{itemize}[leftmargin=*,noitemsep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) saved.\n")

# Print SDE summary
cat(sprintf("\n=== SDE SUMMARY ===\n"))
cat(sprintf("Black Earnings SDE: %.4f (%s)\n", sde_earn, classify_sde(sde_earn)))
cat(sprintf("Black Employment SDE: %.4f (%s)\n", sde_emp, classify_sde(sde_emp)))
cat(sprintf("White Earnings SDE: %.4f (%s)\n", sde_earn_white, classify_sde(sde_earn_white)))

cat("\nAll tables saved.\n")
