## 05_tables.R — Generate all tables for apep_0933
## APEP paper apep_0933: BNG and Housing Development in England

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ====================================================================
# Table 1: Summary Statistics
# ====================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[post_bng == 0]
post <- panel[post_bng == 1]

# By exposure group (pre-BNG)
tab1_data <- rbind(
  pre[high_exposure == 1, .(
    Group = "High BNG Exposure",
    Period = "Pre-BNG",
    `Total Granted` = sprintf("%.1f", mean(total_granted, na.rm = TRUE)),
    `Major Dwelling Granted` = sprintf("%.2f", mean(major_dwell_grant, na.rm = TRUE)),
    `Apps Received` = sprintf("%.1f", mean(apps_received, na.rm = TRUE)),
    `Approval Rate` = sprintf("%.3f", mean(approval_rate, na.rm = TRUE)),
    `Brownfield Sites` = sprintf("%.1f", mean(bf_sites, na.rm = TRUE)),
    `N (LA-quarters)` = sprintf("%d", .N)
  )],
  pre[high_exposure == 0, .(
    Group = "Low BNG Exposure",
    Period = "Pre-BNG",
    `Total Granted` = sprintf("%.1f", mean(total_granted, na.rm = TRUE)),
    `Major Dwelling Granted` = sprintf("%.2f", mean(major_dwell_grant, na.rm = TRUE)),
    `Apps Received` = sprintf("%.1f", mean(apps_received, na.rm = TRUE)),
    `Approval Rate` = sprintf("%.3f", mean(approval_rate, na.rm = TRUE)),
    `Brownfield Sites` = sprintf("%.1f", mean(bf_sites, na.rm = TRUE)),
    `N (LA-quarters)` = sprintf("%d", .N)
  )],
  post[high_exposure == 1, .(
    Group = "High BNG Exposure",
    Period = "Post-BNG",
    `Total Granted` = sprintf("%.1f", mean(total_granted, na.rm = TRUE)),
    `Major Dwelling Granted` = sprintf("%.2f", mean(major_dwell_grant, na.rm = TRUE)),
    `Apps Received` = sprintf("%.1f", mean(apps_received, na.rm = TRUE)),
    `Approval Rate` = sprintf("%.3f", mean(approval_rate, na.rm = TRUE)),
    `Brownfield Sites` = sprintf("%.1f", mean(bf_sites, na.rm = TRUE)),
    `N (LA-quarters)` = sprintf("%d", .N)
  )],
  post[high_exposure == 0, .(
    Group = "Low BNG Exposure",
    Period = "Post-BNG",
    `Total Granted` = sprintf("%.1f", mean(total_granted, na.rm = TRUE)),
    `Major Dwelling Granted` = sprintf("%.2f", mean(major_dwell_grant, na.rm = TRUE)),
    `Apps Received` = sprintf("%.1f", mean(apps_received, na.rm = TRUE)),
    `Approval Rate` = sprintf("%.3f", mean(approval_rate, na.rm = TRUE)),
    `Brownfield Sites` = sprintf("%.1f", mean(bf_sites, na.rm = TRUE)),
    `N (LA-quarters)` = sprintf("%d", .N)
  )]
)

# Write LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by BNG Exposure Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\hline\\hline\n",
  " & & Total & Major Dwell. & Apps & Approval & Brownfield \\\\\n",
  "Group & Period & Granted & Granted & Received & Rate & Sites \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i, ]
  tab1_tex <- paste0(tab1_tex,
    row$Group, " & ", row$Period, " & ",
    row$`Total Granted`, " & ",
    row$`Major Dwelling Granted`, " & ",
    row$`Apps Received`, " & ",
    row$`Approval Rate`, " & ",
    row$`Brownfield Sites`, " \\\\\n"
  )
  if (i == 2) tab1_tex <- paste0(tab1_tex, "\\hline\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} High BNG Exposure defined as LAs with below-median registered brownfield sites (169 LAs). ",
  "Low BNG Exposure defined as LAs with above-median brownfield sites (169 LAs). ",
  "Pre-BNG: 2015 Q1--2023 Q4. Post-BNG: 2024 Q1--2025 Q4. ",
  "Total Granted and Apps Received are quarterly counts per LA. ",
  "Approval Rate = applications granted / applications decided. ",
  "Data: DLUHC Planning Application Statistics PS1/PS2, Brownfield Land Register.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

# ====================================================================
# Table 2: Main DiD Results
# ====================================================================
cat("=== Table 2: Main DiD Results ===\n")

m <- results$continuous_did

setFixest_dict(c(
  did_term = "Post BNG $\\times$ Intensity"
))

etable(m$m1, m$m2, m$m3, m$m4, m$m5,
       file = file.path(table_dir, "tab2_main_did.tex"),
       replace = TRUE,
       headers = c("Log(Granted)", "Log(Received)", "Log(Major)", "Approval Rate", "Major Appr."),
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "r2"),
       extralines = list(
         "_LA Fixed Effects" = rep("Yes", 5),
         "_Quarter Fixed Effects" = rep("Yes", 5),
         "_Clustering" = rep("LA", 5)
       ),
       title = "Effect of Mandatory BNG on Planning Outcomes",
       label = "tab:main_did",
       notes = paste0(
         "Standard errors clustered at the LA level in parentheses. ",
         "BNG Intensity = 1 minus the percentile rank of registered brownfield sites per LA. ",
         "Post BNG = 1 for quarters after 2024 Q1. Sample: 338 English LAs, 2015 Q1--2025 Q4. ",
         "* p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01."
       ),
       style.tex = style.tex("aer"),
       drop.section = "fixef"
)
cat("Table 2 saved.\n")

# ====================================================================
# Table 3: Event Study Coefficients
# ====================================================================
cat("=== Table 3: Event Study ===\n")

es <- results$event_study$total
es_coefs <- coeftable(es)

# Extract event-time coefficients
et_rows <- grep("event_time::", rownames(es_coefs))
es_df <- data.frame(
  event_time = as.integer(gsub("event_time::|:bng_intensity", "", rownames(es_coefs)[et_rows])),
  estimate = es_coefs[et_rows, "Estimate"],
  se = es_coefs[et_rows, "Std. Error"],
  p = es_coefs[et_rows, "Pr(>|t|)"],
  stringsAsFactors = FALSE
)
es_df <- es_df[order(es_df$event_time), ]

# Create LaTeX event study table
tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: BNG Intensity $\\times$ Quarter Dummies}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Event Time & Coefficient & Std. Error & Calendar Quarter \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(es_df)) {
  et <- es_df$event_time[i]
  cal_year <- 2024 + floor(et / 4)
  cal_qtr <- ((et %% 4) + 4) %% 4 + 1
  if (et >= 0) {
    cal_year <- 2024 + floor(et / 4)
    cal_qtr <- (et %% 4) + 1
  } else {
    cal_year <- 2024 + floor(et / 4)
    cal_qtr <- ((et %% 4) + 4) %% 4 + 1
    if (cal_qtr > 4) { cal_qtr <- cal_qtr - 4; cal_year <- cal_year + 1 }
  }
  cal_label <- paste0(cal_year, " Q", cal_qtr)

  stars <- ""
  if (es_df$p[i] < 0.01) stars <- "***"
  else if (es_df$p[i] < 0.05) stars <- "**"
  else if (es_df$p[i] < 0.1) stars <- "*"

  if (et == -1) {
    tab3_tex <- paste0(tab3_tex, "$t = ", et, "$ & \\multicolumn{2}{c}{Reference} & ",
                        cal_label, " \\\\\n")
  } else {
    tab3_tex <- paste0(tab3_tex,
      "$t = ", et, "$ & ", sprintf("%.4f%s", es_df$estimate[i], stars),
      " & (", sprintf("%.4f", es_df$se[i]), ") & ", cal_label, " \\\\\n"
    )
  }
  if (et == -1) tab3_tex <- paste0(tab3_tex, "\\hline\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable: log(total applications granted + 1). ",
  "Each row shows the coefficient on BNG Intensity $\\times$ quarter dummy, ",
  "with $t = -1$ (2023 Q4) as reference. LA and quarter fixed effects included. ",
  "Standard errors clustered at the LA level. ",
  "Sample: 338 English LAs, 2019 Q1--2025 Q4. ",
  "* p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_event_study.tex"))
cat("Table 3 saved.\n")

# ====================================================================
# Table 4: Robustness Checks
# ====================================================================
cat("=== Table 4: Robustness ===\n")

setFixest_dict(c(
  did_term = "Post $\\times$ Intensity",
  did_hect = "Post $\\times$ Intensity (Ha)",
  fake_did = "Placebo $\\times$ Intensity"
))

etable(results$continuous_did$m1, robust$hectares, robust$short_window,
       robust$no_london, robust$placebo,
       file = file.path(table_dir, "tab4_robustness.tex"),
       replace = TRUE,
       headers = c("Baseline", "Hectares", "Short Pre", "Ex-London", "Placebo"),
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "r2"),
       extralines = list(
         "_LA FE" = rep("Yes", 5),
         "_Quarter FE" = rep("Yes", 5),
         "_Sample" = c("Full", "Full", "2019+", "Ex-London", "Pre-BNG")
       ),
       title = "Robustness of Main Results",
       label = "tab:robustness",
       notes = paste0(
         "Dependent variable: log(total applications granted + 1). ",
         "Col.\\ (2) uses brownfield hectares for intensity. ",
         "Col.\\ (3) restricts pre-period to 2019+. Col.\\ (4) drops London LAs. ",
         "Col.\\ (5): placebo test using 2022 Q1 as fake treatment (pre-BNG sample only). ",
         "Standard errors clustered at the LA level. * p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01."
       ),
       style.tex = style.tex("aer"),
       drop.section = "fixef"
)
cat("Table 4 saved.\n")

# ====================================================================
# Table F1: SDE Appendix (MANDATORY)
# ====================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

pre_data <- panel[post_bng == 0]

# Compute SDEs for main outcomes
# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sd_intensity <- sd(pre_data$bng_intensity, na.rm = TRUE)

sde_results <- data.frame(
  Outcome = character(),
  Beta = numeric(),
  SE = numeric(),
  SD_Y = numeric(),
  SDE = numeric(),
  SE_SDE = numeric(),
  Classification = character(),
  stringsAsFactors = FALSE
)

outcomes <- list(
  list(name = "Total Apps Granted (log)", model = results$continuous_did$m1,
       yvar = "log_total_granted"),
  list(name = "Apps Received (log)", model = results$continuous_did$m2,
       yvar = "log_apps_received"),
  list(name = "Major Dwelling Granted (log)", model = results$continuous_did$m3,
       yvar = "log_major_grant"),
  list(name = "Approval Rate", model = results$continuous_did$m4,
       yvar = "approval_rate")
)

for (o in outcomes) {
  beta <- coef(o$model)[1]
  se_beta <- se(o$model)[1]
  sd_y <- sd(pre_data[[o$yvar]], na.rm = TRUE)

  sde <- beta * sd_intensity / sd_y
  se_sde <- se_beta * sd_intensity / sd_y

  # Classify
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) {
    class_label <- "Null"
  } else if (abs_sde < 0.05) {
    class_label <- ifelse(sde > 0, "Small positive", "Small negative")
  } else if (abs_sde < 0.15) {
    class_label <- ifelse(sde > 0, "Moderate positive", "Moderate negative")
  } else {
    class_label <- ifelse(sde > 0, "Large positive", "Large negative")
  }

  sde_results <- rbind(sde_results, data.frame(
    Outcome = o$name,
    Beta = round(beta, 4),
    SE = round(se_beta, 4),
    SD_Y = round(sd_y, 4),
    SDE = round(sde, 4),
    SE_SDE = round(se_sde, 4),
    Classification = class_label,
    stringsAsFactors = FALSE
  ))
}

print(sde_results)

# Heterogeneity panel: split by London vs non-London
cat("\n--- Heterogeneity: London vs Rest ---\n")

het_results <- data.frame(
  Outcome = character(),
  Beta = numeric(),
  SE = numeric(),
  SD_Y = numeric(),
  SDE = numeric(),
  SE_SDE = numeric(),
  Classification = character(),
  stringsAsFactors = FALSE
)

# London
panel_london <- panel[region == "London"]
panel_rest <- panel[region != "London"]

for (subsample in list(
  list(name = "Total Granted (log) — London", data = panel_london, yvar = "log_total_granted"),
  list(name = "Total Granted (log) — Rest of England", data = panel_rest, yvar = "log_total_granted")
)) {
  m_sub <- feols(log_total_granted ~ did_term | la_code + quarter,
                 data = subsample$data, cluster = ~la_code)
  beta <- coef(m_sub)[1]
  se_beta <- se(m_sub)[1]
  sd_y <- sd(subsample$data[post_bng == 0][[subsample$yvar]], na.rm = TRUE)
  sd_x <- sd(subsample$data$bng_intensity, na.rm = TRUE)

  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  abs_sde <- abs(sde)
  if (abs_sde < 0.005) class_label <- "Null"
  else if (abs_sde < 0.05) class_label <- ifelse(sde > 0, "Small positive", "Small negative")
  else if (abs_sde < 0.15) class_label <- ifelse(sde > 0, "Moderate positive", "Moderate negative")
  else class_label <- ifelse(sde > 0, "Large positive", "Large negative")

  het_results <- rbind(het_results, data.frame(
    Outcome = subsample$name,
    Beta = round(beta, 4),
    SE = round(se_beta, 4),
    SD_Y = round(sd_y, 4),
    SDE = round(sde, 4),
    SE_SDE = round(se_sde, 4),
    Classification = class_label,
    stringsAsFactors = FALSE
  ))
}

print(het_results)

# Write LaTeX SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does mandatory 10\\% Biodiversity Net Gain (BNG) under the Environment Act 2021 reduce housing development in English Local Authorities with less brownfield land? ",
  "\\textbf{Policy mechanism:} BNG requires developers to demonstrate a 10\\% net gain in biodiversity value ",
  "via on-site enhancement, off-site credits, or statutory payments, raising compliance costs ",
  "disproportionately for greenfield sites with higher baseline ecological value. ",
  "\\textbf{Outcome definition:} Quarterly count of planning applications granted per Local Authority, measured from DLUHC PS2 statistics (log-transformed). ",
  "\\textbf{Treatment:} Continuous; BNG Intensity = 1 minus the percentile rank of registered brownfield sites per LA, so higher values indicate greater greenfield reliance and higher BNG compliance costs. ",
  "\\textbf{Data:} DLUHC Planning Application Statistics PS1/PS2, Brownfield Land Register; 338 English LAs, 2015 Q1--2025 Q4; 13,794 LA-quarter observations. ",
  "\\textbf{Method:} Heterogeneous-intensity difference-in-differences with LA and quarter fixed effects; standard errors clustered at the LA level. ",
  "\\textbf{Sample:} All English Local Planning Authorities with valid PS2 records; excludes national parks and non-standard planning authorities. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of BNG Intensity and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_results)) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_results$Outcome[i], " & ",
    sprintf("%.4f", sde_results$Beta[i]), " & ",
    sprintf("%.4f", sde_results$SE[i]), " & ",
    sprintf("%.4f", sde_results$SD_Y[i]), " & ",
    sprintf("%.4f", sde_results$SDE[i]), " & ",
    sprintf("%.4f", sde_results$SE_SDE[i]), " & ",
    sde_results$Classification[i], " \\\\\n"
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (London vs. Rest of England)}} \\\\\n"
)

for (i in 1:nrow(het_results)) {
  tabF1_tex <- paste0(tabF1_tex,
    het_results$Outcome[i], " & ",
    sprintf("%.4f", het_results$Beta[i]), " & ",
    sprintf("%.4f", het_results$SE[i]), " & ",
    sprintf("%.4f", het_results$SD_Y[i]), " & ",
    sprintf("%.4f", het_results$SDE[i]), " & ",
    sprintf("%.4f", het_results$SE_SDE[i]), " & ",
    het_results$Classification[i], " \\\\\n"
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
