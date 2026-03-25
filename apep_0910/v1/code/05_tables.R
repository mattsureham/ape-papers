## ============================================================================
## 05_tables.R — Generate all LaTeX tables for the paper
## ============================================================================

paper_dir <- here::here()
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
setwd(here::here())
source("code/00_packages.R")

load("data/main_results.RData")
load("data/robustness_results.RData")
panel <- readRDS("data/analysis_panel.rds")

dir.create("tables", showWarnings = FALSE)

## ---------------------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------------------

cat("\n=== TABLE 1: SUMMARY STATISTICS ===\n")

# Compute pre-treatment summary stats
pre_data <- panel %>%
  filter(treated == 0 | (first_treat > 0 & year < nibrs_year))

sum_stats <- pre_data %>%
  summarise(
    across(c(violent_rate, murder_rate, robbery_rate, assault_rate,
             property_rate, burglary_rate, larceny_rate, motor_rate, population),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

# Format table
vars <- c("violent_rate", "murder_rate", "robbery_rate", "assault_rate",
          "property_rate", "burglary_rate", "larceny_rate", "motor_rate", "population")
var_labels <- c("Violent crime rate", "Murder rate", "Robbery rate",
                "Aggravated assault rate", "Property crime rate",
                "Burglary rate", "Larceny-theft rate", "Motor vehicle theft rate",
                "Population")

tab1_rows <- sapply(seq_along(vars), function(i) {
  v <- vars[i]
  paste0("    ", var_labels[i], " & ",
         formatC(sum_stats[[paste0(v, "_mean")]], format = "f",
                 digits = ifelse(v == "population", 0, 1), big.mark = ","), " & ",
         formatC(sum_stats[[paste0(v, "_sd")]], format = "f",
                 digits = ifelse(v == "population", 0, 1), big.mark = ","), " & ",
         formatC(sum_stats[[paste0(v, "_min")]], format = "f",
                 digits = ifelse(v == "population", 0, 1), big.mark = ","), " & ",
         formatC(sum_stats[[paste0(v, "_max")]], format = "f",
                 digits = ifelse(v == "population", 0, 1), big.mark = ","),
         " \\\\")
})

tab1 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment State-Level Crime Rates}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\hline\\hline\n",
  "    & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Crime Rates per 100,000}} \\\\\n",
  "\\addlinespace\n",
  paste(tab1_rows[1:8], collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Demographics}} \\\\\n",
  "\\addlinespace\n",
  tab1_rows[9], "\n",
  "\\addlinespace\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize Observations: ",
  formatC(nrow(pre_data), big.mark = ","),
  " state-year observations. Sample: 40 U.S. states, 2000--2020.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Pre-treatment period: all years before NIBRS adoption for treated states;} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize all years for never-treated states. Source: FBI UCR via Disaster Center.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1, "tables/tab1_summary.tex")
cat("Table 1 written\n")

## ---------------------------------------------------------------------------
## Table 2: Main Results — Callaway-Sant'Anna DiD
## ---------------------------------------------------------------------------

cat("\n=== TABLE 2: MAIN CS-DiD RESULTS ===\n")

# Helper to format coefficient with stars
fmt_coef <- function(att, se) {
  t <- abs(att / se)
  stars <- ifelse(t > 2.576, "^{***}", ifelse(t > 1.96, "^{**}", ifelse(t > 1.645, "^{*}", "")))
  paste0(formatC(att, format = "f", digits = 4), stars)
}
fmt_se <- function(se) paste0("(", formatC(se, format = "f", digits = 4), ")")
fmt_pct <- function(att) paste0(formatC((exp(att) - 1) * 100, format = "f", digits = 1), "\\%")

# Collect all results
outcomes <- list(
  list(name = "Property crime", agg = agg_property, twfe = twfe_property),
  list(name = "Violent crime", agg = agg_violent, twfe = twfe_violent),
  list(name = "Robbery", agg = agg_robbery, twfe = twfe_robbery),
  list(name = "Agg. assault", agg = agg_assault, twfe = NULL),
  list(name = "Burglary", agg = agg_burglary, twfe = twfe_burglary),
  list(name = "Murder (placebo)", agg = agg_murder, twfe = twfe_murder)
)

# Build rows
rows <- sapply(outcomes, function(o) {
  cs_att <- o$agg$overall.att
  cs_se <- o$agg$overall.se
  twfe_att <- if (!is.null(o$twfe)) coef(o$twfe)["treated"] else NA
  twfe_se <- if (!is.null(o$twfe)) se(o$twfe)["treated"] else NA

  row1 <- paste0("    ", o$name, " & ",
                  fmt_coef(cs_att, cs_se), " & ",
                  ifelse(is.na(twfe_att), "", fmt_coef(twfe_att, twfe_se)), " & ",
                  fmt_pct(cs_att), " \\\\")
  row2 <- paste0("    & ", fmt_se(cs_se), " & ",
                  ifelse(is.na(twfe_se), "", fmt_se(twfe_se)), " & \\\\")
  paste(row1, row2, sep = "\n")
})

tab2 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Effect of NIBRS Adoption on Reported Crime Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "    & CS-DiD & TWFE & Implied \\% \\\\\n",
  "    & ATT & (biased) & Change \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  paste(rows, collapse = "\n\\addlinespace\n"), "\n",
  "\\addlinespace\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\footnotesize States: 40. Years: 2000--2020. Treated: 30 states, 16 cohorts.} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize CS-DiD: Callaway and Sant'Anna (2021), never-treated control, regression} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize estimation. TWFE shown for comparison (known biased with staggered adoption).} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize Clustered SEs at state level in parentheses. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2, "tables/tab2_main.tex")
cat("Table 2 written\n")

## ---------------------------------------------------------------------------
## Table 3: Robustness — LOO and alternative control
## ---------------------------------------------------------------------------

cat("\n=== TABLE 3: ROBUSTNESS ===\n")

tab3 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications for Violent Crime Rate}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "    Specification & ATT & SE \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "    \\textit{Panel A: Main result} & & \\\\\n",
  "    CS-DiD (never-treated control) & ", fmt_coef(agg_violent$overall.att, agg_violent$overall.se),
  " & ", fmt_se(agg_violent$overall.se), " \\\\\n",
  "\\addlinespace\n",
  "    \\textit{Panel B: Alternative control group} & & \\\\\n",
  "    CS-DiD (not-yet-treated control) & ",
  ifelse(is.na(agg_nyt$overall.att), "---",
         fmt_coef(agg_nyt$overall.att, agg_nyt$overall.se)),
  " & ", ifelse(is.na(agg_nyt$overall.se), "---", fmt_se(agg_nyt$overall.se)), " \\\\\n",
  "\\addlinespace\n",
  "    \\textit{Panel C: Leave-one-state-out} & & \\\\\n",
  "    Minimum ATT (drop ", loo_df$dropped_state[which.min(loo_df$att)], ") & ",
  formatC(min(loo_df$att), format = "f", digits = 4), " & \\\\\n",
  "    Maximum ATT (drop ", loo_df$dropped_state[which.max(loo_df$att)], ") & ",
  formatC(max(loo_df$att), format = "f", digits = 4), " & \\\\\n",
  "    Median ATT & ", formatC(median(loo_df$att), format = "f", digits = 4), " & \\\\\n",
  "\\addlinespace\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize Outcome: log violent crime rate per 100,000. Leave-one-state-out} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize drops each of the 30 treated states in turn.} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3, "tables/tab3_robust.tex")
cat("Table 3 written\n")

## ---------------------------------------------------------------------------
## Table 4: Event Study Coefficients (Property Crime)
## ---------------------------------------------------------------------------

cat("\n=== TABLE 4: EVENT STUDY ===\n")

es_coefs <- coef(es_twfe_property)
es_ses <- se(es_twfe_property)
es_names <- names(es_coefs)

# Extract event-time from coefficient names
es_times <- as.integer(gsub("rel_time_f::", "", es_names))
es_df <- tibble(
  event_time = es_times,
  coef = es_coefs,
  se = es_ses
) %>% arrange(event_time)

es_rows <- sapply(seq_len(nrow(es_df)), function(i) {
  et <- es_df$event_time[i]
  cf <- es_df$coef[i]
  s <- es_df$se[i]
  label <- ifelse(et == -1, "$t-1$ (ref.)", paste0("$t", ifelse(et >= 0, "+", ""), et, "$"))
  if (et == -1) {
    paste0("    ", label, " & 0.000 & --- \\\\")
  } else {
    paste0("    ", label, " & ", fmt_coef(cf, s), " & ", fmt_se(s), " \\\\")
  }
})

# Insert reference period
ref_row <- "    $t-1$ (ref.) & 0.000 & --- \\\\"
pre_rows <- es_rows[es_df$event_time < -1]
post_rows <- es_rows[es_df$event_time >= 0]

tab4 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Property Crime Rate Around NIBRS Adoption}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "    Event Time & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n",
  paste(pre_rows, collapse = "\n"), "\n",
  ref_row, "\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\\n",
  paste(post_rows, collapse = "\n"), "\n",
  "\\addlinespace\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize TWFE event study with state and year FE.} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize Dependent variable: log property crime rate per 100,000.} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize Clustered SEs at state level. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4, "tables/tab4_eventstudy.tex")
cat("Table 4 written\n")

## ---------------------------------------------------------------------------
## Table F1: Standardized Effect Size (SDE) Appendix — MANDATORY
## ---------------------------------------------------------------------------

cat("\n=== TABLE F1: STANDARDIZED EFFECT SIZE ===\n")

# Pre-treatment SDs for SDE computation
pre_stats <- panel %>%
  filter(treated == 0 | (first_treat > 0 & year < nibrs_year)) %>%
  summarise(
    sd_log_violent = sd(log_violent_rate, na.rm = TRUE),
    sd_log_murder = sd(log_murder_rate, na.rm = TRUE),
    sd_log_property = sd(log_property_rate, na.rm = TRUE),
    sd_log_robbery = sd(log_robbery_rate, na.rm = TRUE),
    sd_log_burglary = sd(log_burglary_rate, na.rm = TRUE),
    sd_log_assault = sd(log_assault_rate, na.rm = TRUE)
  )

# SDE = beta_hat / SD(Y)
sde_data <- tibble(
  outcome = c("Violent crime rate", "Aggravated assault rate",
              "Property crime rate", "Robbery rate"),
  beta = c(agg_violent$overall.att, agg_assault$overall.att,
           agg_property$overall.att, agg_robbery$overall.att),
  se_beta = c(agg_violent$overall.se, agg_assault$overall.se,
              agg_property$overall.se, agg_robbery$overall.se),
  sd_y = c(pre_stats$sd_log_violent, pre_stats$sd_log_assault,
           pre_stats$sd_log_property, pre_stats$sd_log_robbery)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Panel B: Heterogeneity by state population size
panel_het <- panel %>%
  mutate(large_state = population > median(population, na.rm = TRUE))

# Large states
cs_large <- tryCatch({
  cs_d <- cs_data %>%
    left_join(panel %>% distinct(state_id, state), by = c("id" = "state_id")) %>%
    left_join(panel %>% group_by(state) %>%
                summarise(med_pop = median(population, na.rm = TRUE)), by = "state") %>%
    filter(med_pop > median(panel$population, na.rm = TRUE))
  m <- att_gt(yname = "log_violent_rate", tname = "t", idname = "id", gname = "g",
              data = cs_d, control_group = "nevertreated", base_period = "universal",
              est_method = "reg", allow_unbalanced_panel = TRUE,
              bstrap = TRUE, biters = 500, pl = FALSE)
  aggte(m, type = "simple", na.rm = TRUE)
}, error = function(e) list(overall.att = NA, overall.se = NA))

# Small states
cs_small <- tryCatch({
  cs_d <- cs_data %>%
    left_join(panel %>% distinct(state_id, state), by = c("id" = "state_id")) %>%
    left_join(panel %>% group_by(state) %>%
                summarise(med_pop = median(population, na.rm = TRUE)), by = "state") %>%
    filter(med_pop <= median(panel$population, na.rm = TRUE))
  m <- att_gt(yname = "log_violent_rate", tname = "t", idname = "id", gname = "g",
              data = cs_d, control_group = "nevertreated", base_period = "universal",
              est_method = "reg", allow_unbalanced_panel = TRUE,
              bstrap = TRUE, biters = 500, pl = FALSE)
  aggte(m, type = "simple", na.rm = TRUE)
}, error = function(e) list(overall.att = NA, overall.se = NA))

# Build SDE rows for Panel B (heterogeneity)
het_rows <- tibble(
  outcome = c("Violent crime (large states)", "Violent crime (small states)"),
  beta = c(cs_large$overall.att, cs_small$overall.att),
  se_beta = c(cs_large$overall.se, cs_small$overall.se),
  sd_y = rep(pre_stats$sd_log_violent, 2)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      is.na(sde) ~ "---",
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Format SDE table rows
fmt_sde_row <- function(d) {
  fmt_val <- function(x, dig) {
    if (is.na(x)) return("---")
    formatC(x, format = "f", digits = dig)
  }
  paste0("    ", d$outcome, " & ",
         fmt_val(d$beta, 4), " & ",
         fmt_val(d$se_beta, 4), " & ",
         fmt_val(d$sd_y, 4), " & ",
         fmt_val(d$sde, 3), " & ",
         fmt_val(d$se_sde, 3), " & ",
         d$classification, " \\\\")
}

panel_a_rows <- paste(sapply(seq_len(nrow(sde_data)), function(i) fmt_sde_row(sde_data[i, ])),
                      collapse = "\n")
panel_b_rows <- paste(sapply(seq_len(nrow(het_rows)), function(i) fmt_sde_row(het_rows[i, ])),
                      collapse = "\n")

# SDE Notes (CRITICAL: must be rich for Oracle training, no numerical leakage)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the transition from the FBI's Summary Reporting System (SRS) ",
  "to the National Incident-Based Reporting System (NIBRS) mechanically inflate ",
  "measured state-level crime rates through the elimination of the hierarchy rule? ",
  "\\textbf{Policy mechanism:} NIBRS removes the hierarchy rule that required agencies to report ",
  "only the most serious offense per incident, and expands offense categories from 8 to 52, ",
  "thereby counting all offenses per incident rather than just one. ",
  "\\textbf{Outcome definition:} Log of the annual reported crime rate per 100,000 population, ",
  "computed from FBI Uniform Crime Report offense counts divided by Census population estimates. ",
  "\\textbf{Treatment:} Binary; equals one in the year a state achieves majority NIBRS population coverage and all subsequent years. ",
  "\\textbf{Data:} FBI UCR state-level crime counts compiled by the Disaster Center, 2000--2020, ",
  "40 U.S. states, 803 state-year observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated control group, ",
  "regression estimation, standard errors clustered at the state level, 1,000 bootstrap iterations. ",
  "\\textbf{Sample:} 30 treated states across 16 adoption cohorts (2001--2020) and 10 never-treated states ",
  "(states that adopted NIBRS before 2000 or after 2020). States with missing Disaster Center data excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[!htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes: NIBRS Adoption and Crime Measurement}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "    Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace\n",
  panel_a_rows, "\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by state population)}} \\\\\n",
  "\\addlinespace\n",
  panel_b_rows, "\n",
  "\\addlinespace\n",
  "\\hline\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{minipage}\n",
  "\\\\\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) written\n")

cat("\nAll tables generated successfully.\n")
