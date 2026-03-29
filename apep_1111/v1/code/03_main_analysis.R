# 03_main_analysis.R — Main DiD Analysis
# FEMA Risk Rating 2.0 and Residential Construction

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Analysis Panel Summary ===\n")
cat(sprintf("Observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Counties: %d\n", n_distinct(panel$fips)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Post-RR2.0: %d obs\n", sum(panel$post == 1)))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Split by treatment intensity
panel <- panel %>%
  mutate(
    exposure_group = case_when(
      treatment_q <= 2 ~ "Low Exposure",
      treatment_q == 3 ~ "Medium Exposure",
      treatment_q >= 4 ~ "High Exposure"
    ),
    exposure_group = factor(exposure_group,
                            levels = c("Low Exposure", "Medium Exposure", "High Exposure"))
  )

# Summary stats by exposure group
summary_vars <- c("total_units", "single_family_units", "multifamily_units",
                   "claims_per_1000", "paid_per_capita")

make_summary <- function(df, group_name) {
  data.frame(
    Group = group_name,
    N_Counties = n_distinct(df$fips),
    Mean_Permits = mean(df$total_units, na.rm = TRUE),
    SD_Permits = sd(df$total_units, na.rm = TRUE),
    Mean_SF = mean(df$single_family_units, na.rm = TRUE),
    Mean_MF = mean(df$multifamily_units, na.rm = TRUE),
    Mean_Claims_1000 = mean(df$claims_per_1000, na.rm = TRUE),
    Mean_Paid_PC = mean(df$paid_per_capita, na.rm = TRUE)
  )
}

pre_panel <- panel %>% filter(post == 0)
tab1 <- bind_rows(
  make_summary(pre_panel, "Full Sample"),
  make_summary(pre_panel %>% filter(exposure_group == "Low Exposure"), "Low Exposure"),
  make_summary(pre_panel %>% filter(exposure_group == "Medium Exposure"), "Medium Exposure"),
  make_summary(pre_panel %>% filter(exposure_group == "High Exposure"), "High Exposure")
)

print(tab1)

# Generate LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Flood Exposure}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & Counties & \\multicolumn{2}{c}{Permits/Year} & SF & MF & Claims \\\\\n",
  " & & Mean & SD & Permits & Permits & per 1,000 \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1)) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %d & %.0f & %.0f & %.0f & %.0f & %.1f \\\\\n",
            tab1$Group[i], tab1$N_Counties[i], tab1$Mean_Permits[i],
            tab1$SD_Permits[i], tab1$Mean_SF[i], tab1$Mean_MF[i],
            tab1$Mean_Claims_1000[i]))
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Pre-treatment (2010--2021) summary statistics. ",
  "Exposure groups based on quintiles of pre-RR2.0 NFIP flood claims per 1,000 population. ",
  "Low = quintiles 1--2, Medium = quintile 3, High = quintiles 4--5. ",
  "Permits from Census Building Permits Survey (annual, county-level). ",
  "Claims from FEMA OpenFEMA NFIP Claims database.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — Continuous Treatment DiD
# ============================================================================
cat("\n=== Table 2: Main DiD Results ===\n")

# Standardize treatment intensity for interpretability
panel <- panel %>%
  mutate(
    claims_std = (claims_per_1000 - mean(claims_per_1000, na.rm = TRUE)) /
                  sd(claims_per_1000, na.rm = TRUE),
    paid_std = (paid_per_capita - mean(paid_per_capita, na.rm = TRUE)) /
                sd(paid_per_capita, na.rm = TRUE)
  )

# Model 1: Basic DiD — county + year FE
m1 <- feols(log_total_units ~ post:claims_std |
              fips + year,
            data = panel,
            cluster = ~state_fips)

# Model 2: Add state × year FE
m2 <- feols(log_total_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

# Model 3: With unemployment control
if ("unemp_rate" %in% names(panel)) {
  m3 <- feols(log_total_units ~ post:claims_std + unemp_rate |
                fips + state_fips^year,
              data = panel,
              cluster = ~state_fips)
} else {
  m3 <- m2  # Fallback if no LAUS data
}

# Model 4: Single-family permits only
m4 <- feols(log_sf_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

# Model 5: Multifamily permits
m5 <- feols(log_mf_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

cat("\n--- Model 1: County + Year FE ---\n")
print(summary(m1))
cat("\n--- Model 2: County + State×Year FE ---\n")
print(summary(m2))
cat("\n--- Model 4: Single-Family ---\n")
print(summary(m4))
cat("\n--- Model 5: Multifamily ---\n")
print(summary(m5))

# Export Table 2
etable(m1, m2, m3, m4, m5,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main_results.tex"),
       title = "Effect of Flood Risk Repricing on Residential Building Permits",
       dict = c(
         "log_total_units" = "Log Total Permits",
         "log_sf_units" = "Log SF Permits",
         "log_mf_units" = "Log MF Permits",
         "post:claims_std" = "Post $\\times$ Flood Exposure",
         "claims_std:post" = "Post $\\times$ Flood Exposure",
         "unemp_rate" = "Unemployment Rate"
       ),
       label = "tab:main",
       style.tex = style.tex("aer"),
       notes = paste0(
         "County and year (or state$\\times$year) fixed effects included. ",
         "Flood Exposure is the standardized pre-RR2.0 NFIP claims per 1,000 population. ",
         "Post = 1 for years $\\geq$ 2022. ",
         "Standard errors clustered by state in parentheses. ",
         "Significance: $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$."
       ),
       replace = TRUE
)

# ============================================================================
# Table 3: Event Study — Pre-Trends Test
# ============================================================================
cat("\n=== Table 3: Event Study ===\n")

# Create event-time indicators
# Treatment: RR2.0 announced Oct 2021, full April 2022
# We use 2021 as the omitted year (last pre-treatment)
panel <- panel %>%
  mutate(
    event_time = year - 2021,
    event_time_fac = factor(event_time)
  )

# Event study with continuous treatment
es_model <- feols(
  log_total_units ~ i(event_time, claims_std, ref = 0) |
    fips + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

cat("\n--- Event Study Coefficients ---\n")
print(summary(es_model))

# Save event study coefficients for the table
es_coefs <- coeftable(es_model)
es_df <- data.frame(
  event_time = as.integer(gsub("event_time::", "",
                               gsub(":claims_std", "", rownames(es_coefs)))),
  estimate = es_coefs[, "Estimate"],
  se = es_coefs[, "Std. Error"],
  pval = es_coefs[, "Pr(>|t|)"]
) %>%
  mutate(
    stars = case_when(
      pval < 0.01 ~ "***",
      pval < 0.05 ~ "**",
      pval < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

# Generate LaTeX table for event study
es_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Flood Exposure and Building Permits}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Event Time & Estimate & Std. Error \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(es_df)) {
  if (es_df$event_time[i] == 0) {
    es_tex <- paste0(es_tex,
      sprintf("$k = %d$ (omitted) & --- & --- \\\\\n", es_df$event_time[i]))
  } else {
    es_tex <- paste0(es_tex,
      sprintf("$k = %+d$ & %.4f%s & (%.4f) \\\\\n",
              es_df$event_time[i], es_df$estimate[i],
              es_df$stars[i], es_df$se[i]))
  }
}

es_tex <- paste0(es_tex,
  "\\hline\n",
  "County FE & Yes \\\\\n",
  "State $\\times$ Year FE & Yes \\\\\n",
  "Observations & ", format(nobs(es_model), big.mark = ","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Event study estimates from ",
  "$Y_{it} = \\alpha_i + \\gamma_{st} + \\sum_{k \\neq 0} \\beta_k \\cdot \\mathbf{1}[t - 2021 = k] \\times \\text{FloodExposure}_i + \\varepsilon_{it}$. ",
  "FloodExposure is standardized pre-RR2.0 NFIP claims per 1,000 population. ",
  "$k = 0$ (year 2021) is the omitted reference period. ",
  "Negative $k$ values test parallel trends pre-treatment. ",
  "Standard errors clustered by state. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(es_tex, file.path(tables_dir, "tab3_event_study.tex"))

# ============================================================================
# Save key results for paper
# ============================================================================
results <- list(
  main_coef = coef(m2)["post:claims_std"],
  main_se = se(m2)["post:claims_std"],
  main_pval = pvalue(m2)["post:claims_std"],
  n_obs = nobs(m2),
  n_counties = n_distinct(panel$fips),
  n_years = n_distinct(panel$year),
  sf_coef = coef(m4)["post:claims_std"],
  sf_se = se(m4)["post:claims_std"],
  mf_coef = coef(m5)["post:claims_std"],
  mf_se = se(m5)["post:claims_std"],
  es_coefs = es_df,
  sd_y = sd(panel$log_total_units, na.rm = TRUE),
  sd_x = sd(panel$claims_std, na.rm = TRUE),
  mean_permits = mean(panel$total_units, na.rm = TRUE),
  median_permits = median(panel$total_units, na.rm = TRUE)
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Update diagnostics
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))
diagnostics$main_coefficient <- results$main_coef
diagnostics$main_se <- results$main_se
diagnostics$main_pvalue <- results$main_pval
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Main coefficient (Post × FloodExposure): %.4f (SE: %.4f, p: %.4f)\n",
            results$main_coef, results$main_se, results$main_pval))
