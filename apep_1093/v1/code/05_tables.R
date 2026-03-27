# 05_tables.R — Generate all LaTeX tables
# Pay Transparency Laws and the Racial New-Hire Earnings Gap

source("00_packages.R")

# ---- Load results ----
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
df_gap <- readRDS("../data/qwi_gap.rds")
df <- readRDS("../data/qwi_clean.rds")

# ====================================================================
# Table 1: Summary Statistics
# ====================================================================

cat("--- Generating Table 1: Summary Statistics ---\n")

# Panel A: Treated vs Control states
summ <- df_gap %>%
  mutate(group = ifelse(treated_state == 1, "Treated", "Control")) %>%
  group_by(group) %>%
  summarise(
    `Mean B-W Gap (log)` = mean(bw_gap, na.rm = TRUE),
    `SD B-W Gap` = sd(bw_gap, na.rm = TRUE),
    `Mean B Earnings` = mean(EarnHirAS_Black, na.rm = TRUE),
    `Mean W Earnings` = mean(EarnHirAS_White, na.rm = TRUE),
    `Mean B-W Ratio` = mean(bw_ratio, na.rm = TRUE),
    `Counties` = n_distinct(county_fips),
    `Observations` = n(),
    .groups = "drop"
  )

# Panel B: High vs Low dispersion
summ_disp <- df_gap %>%
  mutate(group = ifelse(high_dispersion == 1, "High Dispersion", "Low Dispersion")) %>%
  group_by(group) %>%
  summarise(
    `Mean B-W Gap (log)` = mean(bw_gap, na.rm = TRUE),
    `SD B-W Gap` = sd(bw_gap, na.rm = TRUE),
    `Mean B Earnings` = mean(EarnHirAS_Black, na.rm = TRUE),
    `Mean W Earnings` = mean(EarnHirAS_White, na.rm = TRUE),
    `Mean B-W Ratio` = mean(bw_ratio, na.rm = TRUE),
    `Counties` = n_distinct(county_fips),
    `Observations` = n(),
    .groups = "drop"
  )

# Format for LaTeX
tab1 <- rbind(
  c("", "\\multicolumn{7}{c}{\\textit{Panel A: By Treatment Status}}"),
  c("", "\\midrule"),
  c("Treated States",
    sprintf("%.3f", summ$`Mean B-W Gap (log)`[summ$group == "Treated"]),
    sprintf("%.3f", summ$`SD B-W Gap`[summ$group == "Treated"]),
    sprintf("%.0f", summ$`Mean B Earnings`[summ$group == "Treated"]),
    sprintf("%.0f", summ$`Mean W Earnings`[summ$group == "Treated"]),
    sprintf("%.3f", summ$`Mean B-W Ratio`[summ$group == "Treated"]),
    format(summ$Counties[summ$group == "Treated"], big.mark = ","),
    format(summ$Observations[summ$group == "Treated"], big.mark = ",")),
  c("Control States",
    sprintf("%.3f", summ$`Mean B-W Gap (log)`[summ$group == "Control"]),
    sprintf("%.3f", summ$`SD B-W Gap`[summ$group == "Control"]),
    sprintf("%.0f", summ$`Mean B Earnings`[summ$group == "Control"]),
    sprintf("%.0f", summ$`Mean W Earnings`[summ$group == "Control"]),
    sprintf("%.3f", summ$`Mean B-W Ratio`[summ$group == "Control"]),
    format(summ$Counties[summ$group == "Control"], big.mark = ","),
    format(summ$Observations[summ$group == "Control"], big.mark = ",")),
  c("", ""),
  c("", "\\multicolumn{7}{c}{\\textit{Panel B: By Industry Pay Dispersion}}"),
  c("", "\\midrule"),
  c("High Dispersion",
    sprintf("%.3f", summ_disp$`Mean B-W Gap (log)`[summ_disp$group == "High Dispersion"]),
    sprintf("%.3f", summ_disp$`SD B-W Gap`[summ_disp$group == "High Dispersion"]),
    sprintf("%.0f", summ_disp$`Mean B Earnings`[summ_disp$group == "High Dispersion"]),
    sprintf("%.0f", summ_disp$`Mean W Earnings`[summ_disp$group == "High Dispersion"]),
    sprintf("%.3f", summ_disp$`Mean B-W Ratio`[summ_disp$group == "High Dispersion"]),
    format(summ_disp$Counties[summ_disp$group == "High Dispersion"], big.mark = ","),
    format(summ_disp$Observations[summ_disp$group == "High Dispersion"], big.mark = ",")),
  c("Low Dispersion",
    sprintf("%.3f", summ_disp$`Mean B-W Gap (log)`[summ_disp$group == "Low Dispersion"]),
    sprintf("%.3f", summ_disp$`SD B-W Gap`[summ_disp$group == "Low Dispersion"]),
    sprintf("%.0f", summ_disp$`Mean B Earnings`[summ_disp$group == "Low Dispersion"]),
    sprintf("%.0f", summ_disp$`Mean W Earnings`[summ_disp$group == "Low Dispersion"]),
    sprintf("%.3f", summ_disp$`Mean B-W Ratio`[summ_disp$group == "Low Dispersion"]),
    format(summ_disp$Counties[summ_disp$group == "Low Dispersion"], big.mark = ","),
    format(summ_disp$Observations[summ_disp$group == "Low Dispersion"], big.mark = ","))
)

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: New-Hire Earnings by Race}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & B-W Gap & SD Gap & Black & White & B-W & & \\\\",
  " & (log pts) & & Earnings & Earnings & Ratio & Counties & Obs. \\\\",
  "\\midrule",
  paste0(tab1[1,1], " & ", paste(tab1[1,-1], collapse = " "), " \\\\"),
  tab1[2,2],
  paste0(tab1[3,1], " & ", paste(tab1[3,2:8], collapse = " & "), " \\\\"),
  paste0(tab1[4,1], " & ", paste(tab1[4,2:8], collapse = " & "), " \\\\"),
  "\\addlinespace",
  paste0(tab1[6,1], " & ", paste(tab1[6,-1], collapse = " "), " \\\\"),
  tab1[7,2],
  paste0(tab1[8,1], " & ", paste(tab1[8,2:8], collapse = " & "), " \\\\"),
  paste0(tab1[9,1], " & ", paste(tab1[9,2:8], collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} QWI race/ethnicity data at 3-digit NAICS, county-quarter level, 2018Q1--2024Q4. Black and White earnings are average monthly earnings of new hires (EarnHirAS). B-W Gap is $\\ln(\\text{EarnHirAS}_{\\text{Black}}) - \\ln(\\text{EarnHirAS}_{\\text{White}})$. High-dispersion industries: Professional Services (541), Credit Intermediation (522), Publishing/Info (511). Low-dispersion industries: Food Services (722), Food/Beverage Stores (445), Accommodation (721).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ====================================================================
# Table 2: Main Results — DiD and DDD
# ====================================================================

cat("--- Generating Table 2: Main Results ---\n")

# Use modelsummary for clean output
tab2_models <- list(
  "Black DiD" = results$m1_black_did,
  "White DiD" = results$m1_white_did,
  "Black DDD" = results$m2_black_ddd,
  "White DDD" = results$m2_white_ddd,
  "Gap DiD" = results$m3_gap_did,
  "Gap DDD" = results$m4_gap_ddd
)

tab2_notes <- "County-industry and quarter fixed effects included in all specifications. Standard errors clustered at state level in parentheses. Dependent variable in columns (1)--(4): $\\ln$(EarnHirAS). Columns (5)--(6): $\\ln$(EarnHirAS\\textsubscript{Black})$-\\ln$(EarnHirAS\\textsubscript{White}). High-dispersion industries: Professional Services (541), Credit Intermediation (522), Publishing/Information (511). Sample: QWI race data, 2018Q1--2024Q4."

# Build table manually for full control
coef_names <- c(
  "treated_state:post" = "Treated $\\times$ Post",
  "treated_state:post:high_dispersion" = "Treated $\\times$ Post $\\times$ HighDisp",
  "treated_state:high_dispersion" = "Treated $\\times$ HighDisp",
  "post:high_dispersion" = "Post $\\times$ HighDisp"
)

modelsummary(
  tab2_models,
  output = "../tables/tab2_main.tex",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = coef_names,
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title = "Pay Transparency and New-Hire Earnings by Race",
  notes = tab2_notes,
  escape = FALSE
)

# ====================================================================
# Table 3: Robustness — Event Study + Wild Bootstrap + Drop CO
# ====================================================================

cat("--- Generating Table 3: Robustness ---\n")

tab3_models <- list(
  "Baseline" = results$m3_gap_did,
  "No Colorado" = robust$no_colorado,
  "CO vs Never" = robust$never_treated,
  "Sep. Placebo" = robust$sep_placebo
)

modelsummary(
  tab3_models,
  output = "../tables/tab3_robustness.tex",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c("treated_state:post" = "Treated $\\times$ Post"),
  gof_map = c("nobs", "r.squared"),
  title = "Robustness Checks: B-W New-Hire Earnings Gap",
  notes = "All specifications include county-industry and quarter fixed effects. Standard errors clustered at state level. Column (1): baseline DiD. Column (2): drops Colorado (earliest adopter). Column (3): Colorado vs never-treated states only. Column (4): placebo using separation gap instead of earnings gap.",
  escape = FALSE
)

# ====================================================================
# Table 4: Industry Heterogeneity
# ====================================================================

cat("--- Generating Table 4: Industry heterogeneity ---\n")

# Re-run industry-specific DiD inline (models don't serialize well to RDS)
industries <- unique(df_gap$industry)
ind_list <- list()
for (ind in industries) {
  df_ind <- df_gap %>% filter(industry == ind)
  if (nrow(df_ind) < 100) next
  m_ind <- tryCatch(
    feols(bw_gap ~ treated_state:post | panel_id + time_index,
          data = df_ind, cluster = ~state_fips),
    error = function(e) NULL
  )
  if (!is.null(m_ind)) {
    ct <- fixest::coeftable(m_ind)
    ind_list[[length(ind_list) + 1]] <- data.frame(
      Industry = ind,
      Coefficient = as.numeric(ct[1, 1]),
      SE = as.numeric(ct[1, 2]),
      pvalue = as.numeric(ct[1, 4]),
      N = as.integer(m_ind$nobs),
      stringsAsFactors = FALSE
    )
  }
}
ind_df <- do.call(rbind, ind_list)
if (!is.null(ind_df) && nrow(ind_df) > 0) {
  ind_df$stars <- ifelse(ind_df$pvalue < 0.01, "***",
                  ifelse(ind_df$pvalue < 0.05, "**",
                  ifelse(ind_df$pvalue < 0.10, "*", "")))

  # Industry labels
  ind_labels <- c(
    "541" = "Professional Services", "522" = "Credit Intermediation",
    "511" = "Publishing/Information", "722" = "Food Services",
    "445" = "Food/Beverage Stores", "721" = "Accommodation",
    "611" = "Education", "621" = "Healthcare",
    "238" = "Specialty Contractors", "423" = "Wholesale Durable",
    "561" = "Admin/Support", "812" = "Personal Services"
  )
  ind_df$Label <- ind_labels[ind_df$Industry]

  # Sort by coefficient
  ind_df <- ind_df[order(ind_df$Coefficient, decreasing = TRUE), ]

  # Write LaTeX
  tab4_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Pay Transparency Effects on B-W Gap by Industry}",
    "\\label{tab:industry}",
    "\\small",
    "\\begin{tabular}{llccc}",
    "\\toprule",
    "NAICS & Industry & Treated$\\times$Post & SE & Obs. \\\\",
    "\\midrule",
    "\\multicolumn{5}{l}{\\textit{High-Dispersion Industries}} \\\\",
    "\\addlinespace"
  )

  # High-dispersion industries first
  high_inds <- ind_df[ind_df$Industry %in% c("541", "522", "511"), ]
  for (i in seq_len(nrow(high_inds))) {
    tab4_lines <- c(tab4_lines, sprintf(
      "%s & %s & %.4f%s & (%.4f) & %s \\\\",
      high_inds$Industry[i], high_inds$Label[i],
      high_inds$Coefficient[i], high_inds$stars[i],
      high_inds$SE[i], format(high_inds$N[i], big.mark = ",")
    ))
  }

  tab4_lines <- c(tab4_lines,
    "\\addlinespace",
    "\\multicolumn{5}{l}{\\textit{Low-Dispersion Industries}} \\\\",
    "\\addlinespace"
  )

  low_inds <- ind_df[!ind_df$Industry %in% c("541", "522", "511"), ]
  for (i in seq_len(nrow(low_inds))) {
    tab4_lines <- c(tab4_lines, sprintf(
      "%s & %s & %.4f%s & (%.4f) & %s \\\\",
      low_inds$Industry[i], low_inds$Label[i],
      low_inds$Coefficient[i], low_inds$stars[i],
      low_inds$SE[i], format(low_inds$N[i], big.mark = ",")
    ))
  }

  tab4_lines <- c(tab4_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}",
    "\\item \\textit{Notes:} Each row is a separate DiD regression of the B-W new-hire earnings gap on Treated$\\times$Post within that industry. County-industry and quarter fixed effects. Standard errors clustered at state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
    "\\end{tablenotes}",
    "\\end{table}"
  )
  writeLines(tab4_lines, "../tables/tab4_industry.tex")
}

# ====================================================================
# Table F1: SDE Appendix (MANDATORY)
# ====================================================================

cat("--- Generating Table F1: SDE ---\n")

# Compute SDE for main outcomes
# SDE = β̂ / SD(Y) for binary treatment

# Pre-treatment SD of outcomes
pre_gap <- df_gap %>% filter(post == 0)
sd_gap <- sd(pre_gap$bw_gap, na.rm = TRUE)

pre_black <- df %>% filter(race == "Black" & post == 0)
pre_white <- df %>% filter(race == "White" & post == 0)
sd_ln_earn_black <- sd(pre_black$ln_earn_hire, na.rm = TRUE)
sd_ln_earn_white <- sd(pre_white$ln_earn_hire, na.rm = TRUE)
sd_ln_hires_black <- sd(pre_black$ln_hires, na.rm = TRUE)

# Extract coefficients and SEs
get_coef_se <- function(model, param = "treated_state:post") {
  ct <- fixest::coeftable(model)
  idx <- grep(param, rownames(ct), fixed = TRUE)[1]
  c(beta = ct[idx, 1], se = ct[idx, 2])
}

gap_cs <- get_coef_se(results$m3_gap_did)
black_cs <- get_coef_se(results$m1_black_did)
white_cs <- get_coef_se(results$m1_white_did)
hire_black_cs <- get_coef_se(results$m5_hire_black)

# SDE calculations
sde_data <- data.frame(
  Outcome = c(
    "B-W New-Hire Earnings Gap",
    "Black New-Hire Earnings",
    "White New-Hire Earnings",
    "Black Hiring Volume"
  ),
  Beta = c(gap_cs["beta"], black_cs["beta"], white_cs["beta"], hire_black_cs["beta"]),
  SE = c(gap_cs["se"], black_cs["se"], white_cs["se"], hire_black_cs["se"]),
  SD_Y = c(sd_gap, sd_ln_earn_black, sd_ln_earn_white, sd_ln_hires_black),
  stringsAsFactors = FALSE
)

sde_data$SDE <- sde_data$Beta / sde_data$SD_Y
sde_data$SE_SDE <- sde_data$SE / sde_data$SD_Y

# Classification
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
sde_data$Classification <- classify_sde(sde_data$SDE)

# --- Heterogeneous panel (sample splits) ---
# Split by industry type: high-dispersion vs low-dispersion
gap_high <- df_gap %>% filter(high_dispersion == 1)
gap_low <- df_gap %>% filter(high_dispersion == 0)

m_gap_high <- feols(bw_gap ~ treated_state:post | panel_id + time_index,
                    data = gap_high, cluster = ~state_fips)
m_gap_low <- feols(bw_gap ~ treated_state:post | panel_id + time_index,
                   data = gap_low, cluster = ~state_fips)

sd_gap_high <- sd(gap_high$bw_gap[gap_high$post == 0], na.rm = TRUE)
sd_gap_low <- sd(gap_low$bw_gap[gap_low$post == 0], na.rm = TRUE)

high_cs <- get_coef_se(m_gap_high)
low_cs <- get_coef_se(m_gap_low)

het_data <- data.frame(
  Outcome = c(
    "B-W Gap: High-Disp. Industries",
    "B-W Gap: Low-Disp. Industries"
  ),
  Beta = c(high_cs["beta"], low_cs["beta"]),
  SE = c(high_cs["se"], low_cs["se"]),
  SD_Y = c(sd_gap_high, sd_gap_low),
  stringsAsFactors = FALSE
)
het_data$SDE <- het_data$Beta / het_data$SD_Y
het_data$SE_SDE <- het_data$SE / het_data$SD_Y
het_data$Classification <- classify_sde(het_data$SDE)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level salary-range-in-job-posting mandates reduce the Black-White new-hire earnings gap? ",
  "\\textbf{Policy mechanism:} Requires employers to disclose salary ranges in job postings, reducing information asymmetry between employers and applicants and constraining discretionary wage-setting that may reflect racial disparities. ",
  "\\textbf{Outcome definition:} Log difference in average monthly earnings of new hires (EarnHirAS) between Black and White workers at the county-industry-quarter level, constructed from Census QWI race/ethnicity tabulations. ",
  "\\textbf{Treatment:} Binary; equals one for state-quarters after adoption of a salary-range posting mandate (staggered across six states, 2021--2024). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), race/ethnicity by 3-digit NAICS, county-quarter cells, 2018Q1--2024Q4; ",
  sprintf("%s county-industry-quarter observations across %d states. ",
    format(nrow(df_gap), big.mark = ","),
    n_distinct(df_gap$state_fips)),
  "\\textbf{Method:} Difference-in-differences with county-industry and quarter fixed effects; standard errors clustered at state level; wild cluster bootstrap for inference. ",
  "\\textbf{Sample:} County-industry-quarter cells with non-suppressed earnings for both Black and White new hires in 12 selected 3-digit NAICS industries spanning high-dispersion (professional services, finance, information) and low-dispersion (food services, retail, accommodation) sectors. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Pay Transparency and Racial Earnings Gap}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(sde_data))) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    sde_data$Outcome[i], sde_data$Beta[i], sde_data$SE[i],
    sde_data$SD_Y[i], sde_data$SDE[i], sde_data$SE_SDE[i],
    sde_data$Classification[i]
  ))
}

sde_lines <- c(sde_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits by Industry Dispersion)}} \\\\",
  "\\addlinespace"
)

for (i in seq_len(nrow(het_data))) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    het_data$Outcome[i], het_data$Beta[i], het_data$SE[i],
    het_data$SD_Y[i], het_data$SDE[i], het_data$SE_SDE[i],
    het_data$Classification[i]
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
