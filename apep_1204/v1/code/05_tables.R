## 05_tables.R — Generate all LaTeX tables
## APEP-1204: Stretched Thin

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis.rds"))
results_main <- readRDS(file.path(data_dir, "results_main.rds"))
results_rob <- readRDS(file.path(data_dir, "results_robustness.rds"))

ihp_df <- filter(analysis, has_ihp, ihp_registrations > 0) %>%
  mutate(concurrent_load_sd = (concurrent_load - mean(concurrent_load)) / sd(concurrent_load))
pa_df <- filter(analysis, has_pa) %>%
  mutate(concurrent_load_sd = (concurrent_load - mean(concurrent_load)) / sd(concurrent_load))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Panel A: All disasters
panel_a <- data.frame(
  Variable = c(
    "Concurrent disasters (other-state)",
    "Concurrent disasters (total)",
    "Number of counties",
    "Disaster is hurricane",
    "Declaration year"
  ),
  N = nrow(analysis),
  Mean = c(
    mean(analysis$concurrent_load),
    mean(analysis$concurrent_total),
    mean(analysis$n_counties),
    mean(analysis$is_hurricane),
    mean(analysis$decl_year)
  ),
  SD = c(
    sd(analysis$concurrent_load),
    sd(analysis$concurrent_total),
    sd(analysis$n_counties),
    sd(analysis$is_hurricane),
    sd(analysis$decl_year)
  ),
  Min = c(
    min(analysis$concurrent_load),
    min(analysis$concurrent_total),
    min(analysis$n_counties),
    0,
    min(analysis$decl_year)
  ),
  Max = c(
    max(analysis$concurrent_load),
    max(analysis$concurrent_total),
    max(analysis$n_counties),
    1,
    max(analysis$decl_year)
  )
)

# Panel B: IHP outcomes
panel_b <- data.frame(
  Variable = c(
    "IHP approval rate",
    "Average IHP grant (\\$)",
    "Total registrations",
    "Inspection rate"
  ),
  N = c(
    nrow(ihp_df),
    sum(!is.na(ihp_df$avg_grant)),
    nrow(ihp_df),
    sum(!is.na(ihp_df$inspection_rate))
  ),
  Mean = c(
    mean(ihp_df$approval_rate, na.rm = TRUE),
    mean(ihp_df$avg_grant, na.rm = TRUE),
    mean(ihp_df$ihp_registrations, na.rm = TRUE),
    mean(ihp_df$ihp_inspected / ihp_df$ihp_registrations, na.rm = TRUE)
  ),
  SD = c(
    sd(ihp_df$approval_rate, na.rm = TRUE),
    sd(ihp_df$avg_grant, na.rm = TRUE),
    sd(ihp_df$ihp_registrations, na.rm = TRUE),
    sd(ihp_df$ihp_inspected / ihp_df$ihp_registrations, na.rm = TRUE)
  ),
  Min = c(
    min(ihp_df$approval_rate, na.rm = TRUE),
    min(ihp_df$avg_grant, na.rm = TRUE),
    min(ihp_df$ihp_registrations, na.rm = TRUE),
    min(ihp_df$ihp_inspected / ihp_df$ihp_registrations, na.rm = TRUE)
  ),
  Max = c(
    max(ihp_df$approval_rate, na.rm = TRUE),
    max(ihp_df$avg_grant, na.rm = TRUE),
    max(ihp_df$ihp_registrations, na.rm = TRUE),
    max(ihp_df$ihp_inspected / ihp_df$ihp_registrations, na.rm = TRUE)
  )
)

# Panel C: PA outcomes
panel_c <- data.frame(
  Variable = c(
    "PA median obligation lag (days)",
    "PA mean obligation lag (days)",
    "Number of PA projects",
    "Total federal share (\\$ millions)"
  ),
  N = c(
    sum(!is.na(pa_df$pa_median_lag)),
    sum(!is.na(pa_df$pa_mean_lag)),
    nrow(pa_df),
    nrow(pa_df)
  ),
  Mean = c(
    mean(pa_df$pa_median_lag, na.rm = TRUE),
    mean(pa_df$pa_mean_lag, na.rm = TRUE),
    mean(pa_df$pa_n_projects, na.rm = TRUE),
    mean(pa_df$pa_federal_share / 1e6, na.rm = TRUE)
  ),
  SD = c(
    sd(pa_df$pa_median_lag, na.rm = TRUE),
    sd(pa_df$pa_mean_lag, na.rm = TRUE),
    sd(pa_df$pa_n_projects, na.rm = TRUE),
    sd(pa_df$pa_federal_share / 1e6, na.rm = TRUE)
  ),
  Min = c(
    min(pa_df$pa_median_lag, na.rm = TRUE),
    min(pa_df$pa_mean_lag, na.rm = TRUE),
    min(pa_df$pa_n_projects, na.rm = TRUE),
    min(pa_df$pa_federal_share / 1e6, na.rm = TRUE)
  ),
  Max = c(
    max(pa_df$pa_median_lag, na.rm = TRUE),
    max(pa_df$pa_mean_lag, na.rm = TRUE),
    max(pa_df$pa_n_projects, na.rm = TRUE),
    max(pa_df$pa_federal_share / 1e6, na.rm = TRUE)
  )
)

# Write LaTeX
fmt_num <- function(x, digits = 2) formatC(x, digits = digits, format = "f", big.mark = ",")

write_panel <- function(df, label, digits = 2) {
  lines <- character()
  lines <- c(lines, sprintf("\\multicolumn{6}{l}{\\textit{%s}} \\\\", label))
  for (i in seq_len(nrow(df))) {
    lines <- c(lines, sprintf("\\quad %s & %s & %s & %s & %s & %s \\\\",
                              df$Variable[i],
                              fmt_num(df$N[i], 0),
                              fmt_num(df$Mean[i], digits),
                              fmt_num(df$SD[i], digits),
                              fmt_num(df$Min[i], digits),
                              fmt_num(df$Max[i], digits)))
  }
  lines
}

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "& N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  write_panel(panel_a, "Panel A: Major Disaster Declarations (2005--2024)"),
  "\\addlinespace",
  write_panel(panel_b, "Panel B: IHP Housing Assistance Outcomes"),
  "\\addlinespace",
  write_panel(panel_c, "Panel C: Public Assistance Outcomes"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from OpenFEMA. Sample restricted to Major Disaster Declarations (type DR) from 2005--2024. Concurrent disasters (other-state) counts the number of other Major Disasters with overlapping active periods in different states at the time of declaration. IHP approval rate is the ratio of approved-for-assistance registrations to total valid registrations. PA obligation lag is the number of days between declaration and first federal obligation.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — Concurrent Load and IHP Outcomes
# ============================================================================
cat("Generating Table 2: Main Results...\n")

# Run models for the table
# Col 1: OLS approval (raw)
# Col 2: RF approval (standardized)
# Col 3: RF log avg grant
# Col 4: RF approval — hurricanes only
# Col 5: RF approval — non-hurricanes

hurr_df <- filter(ihp_df, is_hurricane == 1)
nonhurr_df <- filter(ihp_df, is_hurricane == 0)

rf_hurr <- feols(
  approval_rate ~ concurrent_load_sd + log_n_counties |
    decl_year + quarter,
  data = hurr_df, cluster = ~state
)

rf_nonhurr <- feols(
  approval_rate ~ concurrent_load_sd + log_n_counties +
    is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = nonhurr_df, cluster = ~state
)

# Also log avg grant for hurricanes
rf_hurr_grant <- feols(
  log_avg_grant ~ concurrent_load_sd + log_n_counties |
    decl_year + quarter,
  data = filter(hurr_df, !is.na(log_avg_grant), is.finite(log_avg_grant)),
  cluster = ~state
)

models_tab2 <- list(
  results_main$rf_approval,
  results_main$rf_grant,
  rf_hurr,
  rf_hurr_grant,
  rf_nonhurr
)

# Generate table using etable
setFixest_dict(c(
  concurrent_load_sd = "Concurrent load (SD)",
  log_n_counties = "Log(counties)",
  approval_rate = "Approval rate",
  log_avg_grant = "Log(avg grant)",
  is_hurricane = "Hurricane",
  is_flood = "Flood",
  is_fire = "Fire",
  is_severe_storm = "Severe storm"
))

etable(
  models_tab2,
  file = file.path(tables_dir, "tab2_main.tex"),
  style.tex = style.tex("aer"),
  title = "Concurrent Disaster Load and FEMA Household Assistance",
  label = "tab:main",
  headers = c("All", "All", "Hurricane", "Hurricane", "Non-Hurricane"),
  depvar = TRUE,
  se.below = TRUE,
  fitstat = ~ n + r2 + ar2,
  notes = paste0(
    "Data from OpenFEMA, 2005--2024. Concurrent load (SD) is the standardized count of other-state ",
    "Major Disaster declarations with overlapping active periods. All specifications include year and ",
    "quarter fixed effects and disaster type controls. Standard errors clustered by state in parentheses. ",
    "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$."
  ),
  replace = TRUE
)

# ============================================================================
# Table 3: Robustness and Falsification
# ============================================================================
cat("Generating Table 3: Robustness...\n")

# Collect robustness results into a compact table
rob_rows <- data.frame(
  Specification = c(
    "Baseline (all disasters)",
    "Hurricanes only",
    "Non-hurricanes only",
    "Leave-one-out (FEMA region)",
    "Total concurrent (incl. same state)",
    "\\textit{Falsification:}",
    "\\quad Log(counties affected)",
    "\\quad Log(total damage)"
  ),
  N = c(
    nobs(results_main$rf_approval),
    nobs(rf_hurr),
    nobs(rf_nonhurr),
    nobs(results_rob$loo_approval),
    nobs(results_rob$alt_total),
    NA,
    nobs(results_rob$fals_counties),
    nobs(results_rob$fals_damage)
  ),
  Beta = c(
    coef(results_main$rf_approval)["concurrent_load_sd"],
    coef(rf_hurr)["concurrent_load_sd"],
    coef(rf_nonhurr)["concurrent_load_sd"],
    coef(results_rob$loo_approval)["concurrent_load_sd"],
    coef(results_rob$alt_total)["concurrent_total_sd"],
    NA,
    coef(results_rob$fals_counties)["concurrent_load_sd"],
    coef(results_rob$fals_damage)["concurrent_load_sd"]
  ),
  SE = c(
    se(results_main$rf_approval)["concurrent_load_sd"],
    se(rf_hurr)["concurrent_load_sd"],
    se(rf_nonhurr)["concurrent_load_sd"],
    se(results_rob$loo_approval)["concurrent_load_sd"],
    se(results_rob$alt_total)["concurrent_total_sd"],
    NA,
    se(results_rob$fals_counties)["concurrent_load_sd"],
    se(results_rob$fals_damage)["concurrent_load_sd"]
  ),
  stringsAsFactors = FALSE
)

# Stars
rob_rows$stars <- ""
for (i in seq_len(nrow(rob_rows))) {
  if (is.na(rob_rows$Beta[i])) next
  pval <- 2 * pnorm(-abs(rob_rows$Beta[i] / rob_rows$SE[i]))
  if (pval < 0.01) rob_rows$stars[i] <- "***"
  else if (pval < 0.05) rob_rows$stars[i] <- "**"
  else if (pval < 0.10) rob_rows$stars[i] <- "*"
}

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Falsification Tests}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  "Specification & N & $\\hat{\\beta}$ & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(rob_rows))) {
  if (is.na(rob_rows$Beta[i])) {
    tab3_lines <- c(tab3_lines, sprintf("%s & & & \\\\", rob_rows$Specification[i]))
  } else {
    tab3_lines <- c(tab3_lines, sprintf("%s & %d & %.4f%s & (%.4f) \\\\",
                                        rob_rows$Specification[i],
                                        rob_rows$N[i],
                                        rob_rows$Beta[i],
                                        rob_rows$stars[i],
                                        rob_rows$SE[i]))
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include year and quarter fixed effects, disaster type controls, and log(counties). Dependent variable is IHP approval rate except where noted. Concurrent load is standardized (mean zero, unit variance). Standard errors clustered by state. Falsification outcomes are pre-determined disaster characteristics that should not respond to concurrent load. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_robustness.tex"))

# ============================================================================
# Table 4: Binned Concurrent Load
# ============================================================================
cat("Generating Table 4: Binned Results...\n")

# Rerun bin model for hurricanes
hurr_df <- hurr_df %>%
  mutate(load_bin = cut(concurrent_load,
                        breaks = c(0, 15, 30, 45, 60, Inf),
                        labels = c("1-15", "16-30", "31-45", "46-60", "61+"),
                        include.lowest = TRUE))

bin_hurr <- feols(
  approval_rate ~ load_bin + log_n_counties | decl_year + quarter,
  data = hurr_df, cluster = ~state
)

bin_all <- results_main$bin_approval

models_tab4 <- list(bin_all, bin_hurr)

etable(
  models_tab4,
  file = file.path(tables_dir, "tab4_binned.tex"),
  style.tex = style.tex("aer"),
  title = "Nonlinear Effects: Binned Concurrent Disaster Load",
  label = "tab:binned",
  headers = c("All Disasters", "Hurricanes Only"),
  depvar = TRUE,
  se.below = TRUE,
  fitstat = ~ n + r2,
  notes = paste0(
    "Dependent variable is IHP approval rate. Reference category: 1--15 concurrent ",
    "other-state disasters. Year and quarter fixed effects, disaster type controls (all disasters), ",
    "and log(counties) included. Standard errors clustered by state. ",
    "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$."
  ),
  replace = TRUE
)

# ============================================================================
# Table 5 (Appendix): Standardized Effect Sizes
# ============================================================================
cat("Generating SDE Table (Appendix)...\n")

# Compute SDEs for main outcomes
# SDE = β * SD(X) / SD(Y)  for continuous treatment
# Here: β is already in standardized units (SD(X) = 1), so SDE = β / SD(Y)

sd_approval_all <- sd(ihp_df$approval_rate, na.rm = TRUE)
sd_approval_hurr <- sd(hurr_df$approval_rate, na.rm = TRUE)
sd_grant <- sd(ihp_df$avg_grant[is.finite(ihp_df$avg_grant)], na.rm = TRUE)
sd_log_grant <- sd(log(ihp_df$avg_grant[ihp_df$avg_grant > 0] + 1), na.rm = TRUE)
sd_pa_lag <- sd(log(pa_df$pa_median_lag[pa_df$pa_median_lag > 0] + 1), na.rm = TRUE)

# Pool results
sde_data <- data.frame(
  Outcome = c(
    "IHP Approval Rate (All)",
    "IHP Approval Rate (Hurricane)",
    "IHP Approval Rate (Non-Hurr.)",
    "Log Avg.~Grant (All)",
    "Log PA Median Lag (All)"
  ),
  beta = c(
    coef(results_main$rf_approval)["concurrent_load_sd"],
    coef(rf_hurr)["concurrent_load_sd"],
    coef(rf_nonhurr)["concurrent_load_sd"],
    coef(results_main$rf_grant)["concurrent_load_sd"],
    coef(results_main$rf_lag)["concurrent_load_sd"]
  ),
  se_beta = c(
    se(results_main$rf_approval)["concurrent_load_sd"],
    se(rf_hurr)["concurrent_load_sd"],
    se(rf_nonhurr)["concurrent_load_sd"],
    se(results_main$rf_grant)["concurrent_load_sd"],
    se(results_main$rf_lag)["concurrent_load_sd"]
  ),
  sd_y = c(
    sd_approval_all,
    sd_approval_hurr,
    sd(nonhurr_df$approval_rate, na.rm = TRUE),
    sd_log_grant,
    sd_pa_lag
  ),
  stringsAsFactors = FALSE
)

sde_data <- sde_data %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15  ~ "Large negative",
      sde < -0.05  ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <=  0.005 ~ "Null",
      sde <=  0.05  ~ "Small positive",
      sde <=  0.15  ~ "Moderate positive",
      TRUE          ~ "Large positive"
    )
  )

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does concurrent federal disaster load---the number of simultaneously active Major Disaster declarations stretching FEMA's fixed workforce---reduce the quality of household disaster assistance? ",
  "\\textbf{Policy mechanism:} FEMA's Individual Assistance cadre has approximately 2,585 deployable workers shared across all active disasters; each additional concurrent declaration dilutes per-disaster caseworker availability, potentially reducing inspection thoroughness and approval quality. ",
  "\\textbf{Outcome definition:} IHP approval rate (approved-for-assistance registrations divided by total valid registrations), average IHP grant amount (total approved amount divided by approved registrations), and PA median obligation lag (median days from declaration to first federal obligation). ",
  "\\textbf{Treatment:} Continuous; standardized count of other-state Major Disaster declarations with overlapping active periods at the time of each disaster's declaration. ",
  "\\textbf{Data:} OpenFEMA Disaster Declarations Summary, Housing Assistance Owners, and PA Funded Projects, 2005--2024; 479 disasters with IHP data, 433 with PA data. ",
  "\\textbf{Method:} Reduced-form OLS with year and quarter fixed effects, disaster type controls, and log(counties) as severity proxy; standard errors clustered by state. ",
  "\\textbf{Sample:} Major Disaster Declarations (type DR) in U.S. states and territories, restricted to disasters with non-zero IHP registrations or PA projects. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-disaster ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Panel A: Pooled
tab_sde <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lrrrrrrl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

pooled_idx <- c(1, 4, 5)  # All approval, log grant, PA lag
for (i in pooled_idx) {
  tab_sde <- c(tab_sde, sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
                                sde_data$Outcome[i],
                                sde_data$beta[i], sde_data$se_beta[i],
                                sde_data$sd_y[i],
                                sde_data$sde[i], sde_data$se_sde[i],
                                sde_data$classification[i]))
}

tab_sde <- c(tab_sde,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by disaster type)}} \\\\"
)

het_idx <- c(2, 3)  # Hurricane, non-hurricane
for (i in het_idx) {
  tab_sde <- c(tab_sde, sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
                                sde_data$Outcome[i],
                                sde_data$beta[i], sde_data$se_beta[i],
                                sde_data$sd_y[i],
                                sde_data$sde[i], sde_data$se_sde[i],
                                sde_data$classification[i]))
}

tab_sde <- c(tab_sde,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab_sde, file.path(tables_dir, "tabF1_sde.tex"))

# ============================================================================
# Save hurricane-specific models for paper
# ============================================================================
saveRDS(list(rf_hurr = rf_hurr, rf_nonhurr = rf_nonhurr,
             rf_hurr_grant = rf_hurr_grant,
             bin_hurr = bin_hurr),
        file.path(data_dir, "results_heterogeneity.rds"))

cat("\nAll tables generated.\n")
cat(sprintf("Files in %s:\n", tables_dir))
cat(paste(list.files(tables_dir), collapse = "\n"), "\n")
