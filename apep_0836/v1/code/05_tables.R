# 05_tables.R — Generate all LaTeX tables
# Japan Heisei Municipal Merger Fiscal Cliff (apep_0836)

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# Recompute variables
panel[, log_sfd_pc := log(sfd_pc + 1)]
panel[, log_sfr_pc := log(sfr_pc + 1)]
panel[, log_lat_pc := log(lat_pc + 1)]
panel[, log_std_scale_pc := log(std_scale_pc + 1)]
panel[, post_phaseout := fifelse(merged == TRUE & event_time >= 0, 1L, 0L)]
panel[, phaseout_intensity := fifelse(merged == TRUE, phaseout_pct / 100, 0)]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

sum_stats <- function(dt, label) {
  data.table(
    Group = label,
    N_munis = uniqueN(dt$muni_code),
    N_obs = nrow(dt),
    Pop_mean = mean(dt$population, na.rm = TRUE),
    Pop_sd = sd(dt$population, na.rm = TRUE),
    SFD_pc_mean = mean(dt$sfd_pc, na.rm = TRUE),
    SFD_pc_sd = sd(dt$sfd_pc, na.rm = TRUE),
    SFR_pc_mean = mean(dt$sfr_pc, na.rm = TRUE),
    SFR_pc_sd = sd(dt$sfr_pc, na.rm = TRUE),
    LAT_pc_mean = mean(dt$lat_pc, na.rm = TRUE),
    LAT_pc_sd = sd(dt$lat_pc, na.rm = TRUE),
    Balance_mean = mean(dt$balance_ratio, na.rm = TRUE),
    Balance_sd = sd(dt$balance_ratio, na.rm = TRUE)
  )
}

ss_all <- sum_stats(panel, "All municipalities")
ss_merged <- sum_stats(panel[merged == TRUE], "Merged")
ss_never <- sum_stats(panel[never_merged == TRUE], "Never merged")

ss <- rbindlist(list(ss_all, ss_merged, ss_never))

# Format for LaTeX
format_num <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Japanese Municipalities, FY2011--2023}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & All & Merged & Never Merged \\\\\n",
  "\\hline\n",
  sprintf("Municipalities & %s & %s & %s \\\\\n",
          format_num(ss$N_munis[1]), format_num(ss$N_munis[2]), format_num(ss$N_munis[3])),
  sprintf("Municipality-year obs. & %s & %s & %s \\\\\n",
          format_num(ss$N_obs[1]), format_num(ss$N_obs[2]), format_num(ss$N_obs[3])),
  "\\addlinespace\n",
  sprintf("Population & %s & %s & %s \\\\\n",
          format_num(ss$Pop_mean[1]), format_num(ss$Pop_mean[2]), format_num(ss$Pop_mean[3])),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format_num(ss$Pop_sd[1]), format_num(ss$Pop_sd[2]), format_num(ss$Pop_sd[3])),
  "\\addlinespace\n",
  sprintf("SFD per capita (\\textyen{} 1,000) & %s & %s & %s \\\\\n",
          format_num(ss$SFD_pc_mean[1], 1), format_num(ss$SFD_pc_mean[2], 1), format_num(ss$SFD_pc_mean[3], 1)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format_num(ss$SFD_pc_sd[1], 1), format_num(ss$SFD_pc_sd[2], 1), format_num(ss$SFD_pc_sd[3], 1)),
  "\\addlinespace\n",
  sprintf("SFR per capita (\\textyen{} 1,000) & %s & %s & %s \\\\\n",
          format_num(ss$SFR_pc_mean[1], 1), format_num(ss$SFR_pc_mean[2], 1), format_num(ss$SFR_pc_mean[3], 1)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format_num(ss$SFR_pc_sd[1], 1), format_num(ss$SFR_pc_sd[2], 1), format_num(ss$SFR_pc_sd[3], 1)),
  "\\addlinespace\n",
  sprintf("LAT per capita (\\textyen{} 1,000) & %s & %s & %s \\\\\n",
          format_num(ss$LAT_pc_mean[1], 1), format_num(ss$LAT_pc_mean[2], 1), format_num(ss$LAT_pc_mean[3], 1)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format_num(ss$LAT_pc_sd[1], 1), format_num(ss$LAT_pc_sd[2], 1), format_num(ss$LAT_pc_sd[3], 1)),
  "\\addlinespace\n",
  sprintf("Real balance ratio (\\%%) & %s & %s & %s \\\\\n",
          format_num(ss$Balance_mean[1], 2), format_num(ss$Balance_mean[2], 2), format_num(ss$Balance_mean[3], 2)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format_num(ss$Balance_sd[1], 2), format_num(ss$Balance_sd[2], 2), format_num(ss$Balance_sd[3], 2)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. SFD = Standard Fiscal Demand; ",
  "SFR = Standard Fiscal Revenue; LAT = Local Allocation Tax (implied: max(0, SFD $-$ SFR)). ",
  "``Merged'' municipalities underwent Heisei-era consolidation (FY1999--2010). ",
  "Per capita figures in thousands of yen.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main DiD Results ===\n")

# Recreate models for etable
did_sfd <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
                 data = panel, cluster = ~muni_code)
did_lat <- feols(log_lat_pc ~ post_phaseout | muni_code + fiscal_year,
                 data = panel, cluster = ~muni_code)
did_sfr <- feols(log_sfr_pc ~ post_phaseout | muni_code + fiscal_year,
                 data = panel, cluster = ~muni_code)
did_balance <- feols(balance_ratio ~ post_phaseout | muni_code + fiscal_year,
                     data = panel, cluster = ~muni_code)

# Dose-response
dose_sfd <- feols(log_sfd_pc ~ phaseout_intensity | muni_code + fiscal_year,
                  data = panel, cluster = ~muni_code)
dose_lat <- feols(log_lat_pc ~ phaseout_intensity | muni_code + fiscal_year,
                  data = panel, cluster = ~muni_code)

setFixest_dict(c(
  post_phaseout = "Post phase-out",
  phaseout_intensity = "Phase-out intensity",
  log_sfd_pc = "Log SFD/cap",
  log_lat_pc = "Log LAT/cap",
  log_sfr_pc = "Log SFR/cap",
  balance_ratio = "Balance ratio"
))

etable(did_sfd, did_lat, did_sfr, did_balance, dose_sfd, dose_lat,
       tex = TRUE,
       file = file.path(table_dir, "tab2_main_did.tex"),
       title = "Effect of LAT Grace Period Phase-Out on Municipal Fiscal Indicators",
       label = "tab:main_did",
       replace = TRUE)

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

# Extract Sun & Abraham coefficients for SFD and LAT
panel[, cohort2 := fifelse(merged == TRUE, phaseout_start_fy, Inf)]

est_sfd_sa <- feols(
  log_sfd_pc ~ sunab(cohort2, fiscal_year) | muni_code + fiscal_year,
  data = panel[(!is.na(event_time) & event_time >= -3 & event_time <= 8) | never_merged == TRUE],
  cluster = ~muni_code
)

est_lat_sa <- feols(
  log_lat_pc ~ sunab(cohort2, fiscal_year) | muni_code + fiscal_year,
  data = panel[(!is.na(event_time) & event_time >= -3 & event_time <= 8) | never_merged == TRUE],
  cluster = ~muni_code
)

# Extract coefficients
sfd_coefs <- coeftable(est_sfd_sa)
lat_coefs <- coeftable(est_lat_sa)

event_times <- -3:8
event_times_no_ref <- event_times[event_times != -1]

tab3_rows <- ""
for (et in event_times) {
  if (et == -1) {
    tab3_rows <- paste0(tab3_rows,
      sprintf("$k = %d$ & \\multicolumn{2}{c}{[Reference]} & \\multicolumn{2}{c}{[Reference]} \\\\\n", et))
    next
  }

  sfd_row_name <- paste0("fiscal_year::", et)
  lat_row_name <- paste0("fiscal_year::", et)

  sfd_est <- ifelse(sfd_row_name %in% rownames(sfd_coefs),
                    sprintf("%.4f", sfd_coefs[sfd_row_name, "Estimate"]), "---")
  sfd_se <- ifelse(sfd_row_name %in% rownames(sfd_coefs),
                   sprintf("(%.4f)", sfd_coefs[sfd_row_name, "Std. Error"]), "")
  sfd_star <- ""
  if (sfd_row_name %in% rownames(sfd_coefs)) {
    p <- sfd_coefs[sfd_row_name, "Pr(>|t|)"]
    if (p < 0.001) sfd_star <- "$^{***}$"
    else if (p < 0.01) sfd_star <- "$^{**}$"
    else if (p < 0.05) sfd_star <- "$^{*}$"
  }

  lat_est <- ifelse(lat_row_name %in% rownames(lat_coefs),
                    sprintf("%.4f", lat_coefs[lat_row_name, "Estimate"]), "---")
  lat_se <- ifelse(lat_row_name %in% rownames(lat_coefs),
                   sprintf("(%.4f)", lat_coefs[lat_row_name, "Std. Error"]), "")
  lat_star <- ""
  if (lat_row_name %in% rownames(lat_coefs)) {
    p <- lat_coefs[lat_row_name, "Pr(>|t|)"]
    if (p < 0.001) lat_star <- "$^{***}$"
    else if (p < 0.01) lat_star <- "$^{**}$"
    else if (p < 0.05) lat_star <- "$^{*}$"
  }

  tab3_rows <- paste0(tab3_rows,
    sprintf("$k = %d$ & %s%s & %s & %s%s & %s \\\\\n",
            et, sfd_est, sfd_star, sfd_se, lat_est, lat_star, lat_se))
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Sun \\& Abraham (2021) Estimates}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Log SFD per capita} & \\multicolumn{2}{c}{Log LAT per capita} \\\\\n",
  "Event time & Estimate & SE & Estimate & SE \\\\\n",
  "\\hline\n",
  tab3_rows,
  "\\hline\n",
  "Observations & \\multicolumn{2}{c}{", format(nobs(est_sfd_sa), big.mark = ","),
  "} & \\multicolumn{2}{c}{", format(nobs(est_lat_sa), big.mark = ","), "} \\\\\n",
  "Municipality FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sun \\& Abraham (2021) interaction-weighted estimates ",
  "with $k = -1$ as reference period. Standard errors clustered at the municipality level. ",
  "Event time $k = 0$ denotes the first year of the 5-year phase-out. ",
  "Sample restricted to event times $-3$ to $+8$ for merged municipalities plus all never-merged. ",
  "$^{***}$p$<$0.001; $^{**}$p$<$0.01; $^{*}$p$<$0.05.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_event_study.tex"))

# ============================================================
# Table 4: Heterogeneity
# ============================================================
cat("=== Table 4: Heterogeneity ===\n")

# Panel already has pre_lat_share and high_lat_dep from robustness script
# Just ensure post_phaseout is defined
panel[, post_phaseout := fifelse(merged == TRUE & !is.na(event_time) & event_time >= 0, 1L, 0L)]
panel_het <- copy(panel)

het_high <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
                  data = panel_het[(merged == TRUE & high_lat_dep == TRUE) | never_merged == TRUE],
                  cluster = ~muni_code)
het_low <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
                 data = panel_het[(merged == TRUE & high_lat_dep == FALSE) | never_merged == TRUE],
                 cluster = ~muni_code)

# By merger cohort
panel_het[merged == TRUE, cohort_group := fcase(
  merge_fy <= 2004, "early",
  merge_fy == 2005, "peak",
  merge_fy >= 2006, "late"
)]

het_early <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
                   data = panel_het[(merged == TRUE & cohort_group == "early") | never_merged == TRUE],
                   cluster = ~muni_code)
het_peak <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
                  data = panel_het[(merged == TRUE & cohort_group == "peak") | never_merged == TRUE],
                  cluster = ~muni_code)

etable(het_high, het_low, het_early, het_peak,
       tex = TRUE,
       file = file.path(table_dir, "tab4_heterogeneity.tex"),
       title = "Heterogeneity in Phase-Out Effects on Log SFD per Capita",
       label = "tab:heterogeneity",
       headers = c("High LAT dep.", "Low LAT dep.", "Early cohort", "Peak cohort"),
       replace = TRUE)

# ============================================================
# Table 5: Robustness and Placebo
# ============================================================
cat("=== Table 5: Robustness ===\n")

# Callaway-Sant'Anna aggregate
cs_att_sfd <- rob_models$agg_cs_sfd$overall.att
cs_se_sfd <- rob_models$agg_cs_sfd$overall.se

# Placebo
placebo_coef <- coef(rob_models$placebo_est)
placebo_se <- se(rob_models$placebo_est)
placebo_p <- pvalue(rob_models$placebo_est)

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Alternative Estimators and Placebo}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Estimate & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Alternative estimators (Dep. var: Log SFD/cap)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("Sun \\& Abraham (2021), binary & %.4f$^{***}$ & (%.4f) \\\\\n",
          coef(models$did_sfd), se(models$did_sfd)),
  sprintf("Sun \\& Abraham (2021), dose-response & %.4f$^{***}$ & (%.4f) \\\\\n",
          coef(models$dose_sfd), se(models$dose_sfd)),
  sprintf("Callaway \\& Sant'Anna (2021), aggregate ATT & %.4f%s & (%.4f) \\\\\n",
          cs_att_sfd, ifelse(abs(cs_att_sfd/cs_se_sfd) > 1.96, "$^{*}$", ""), cs_se_sfd),
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo test}} \\\\\n",
  "\\addlinespace\n",
  sprintf("Pseudo-treatment on never-merged & %.4f & (%.4f) \\\\\n",
          placebo_coef, placebo_se),
  sprintf(" & \\multicolumn{2}{c}{[p = %.3f]} \\\\\n", placebo_p),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A reports point estimates for Log SFD per capita ",
  "from three alternative estimators. Panel B assigns pseudo-treatment dates to ",
  "never-merged municipalities drawn from the actual cohort distribution. ",
  "All specifications include municipality and fiscal year fixed effects. ",
  "SEs clustered at municipality level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, file.path(table_dir, "tab5_robustness.tex"))

# ============================================================
# Table F1: SDE Appendix
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs for main outcomes
compute_sde <- function(model, panel_data, outcome_var, outcome_label, treatment_type = "binary") {
  beta <- coef(model)[1]
  se_beta <- se(model)[1]

  # For log outcomes, SDE = beta / SD(log_Y) since Y is already in logs
  sd_y <- sd(panel_data[merged == TRUE & event_time < 0, get(outcome_var)], na.rm = TRUE)

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  classify <- function(s) {
    if (abs(s) < 0.005) return("Null")
    if (s > 0.15) return("Large positive")
    if (s > 0.05) return("Moderate positive")
    if (s > 0.005) return("Small positive")
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    return("Small negative")
  }

  list(
    outcome = outcome_label,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_sfd <- compute_sde(models$did_sfd, panel, "log_sfd_pc", "Log SFD per capita")
sde_lat <- compute_sde(models$did_lat, panel, "log_lat_pc", "Log LAT per capita")
sde_sfr <- compute_sde(models$did_sfr, panel, "log_sfr_pc", "Log SFR per capita")
sde_bal <- compute_sde(models$did_balance, panel, "balance_ratio", "Real balance ratio")

sde_list <- list(sde_sfd, sde_lat, sde_sfr, sde_bal)

# Build SDE table rows
sde_rows <- ""
for (s in sde_list) {
  sde_rows <- paste0(sde_rows, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    s$outcome, s$beta, s$se, s$sd_y, s$sde, s$se_sde, s$classification
  ))
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does the expiration of a temporary intergovernmental transfer grace period following municipal mergers cause fiscal distress or reveal merger efficiency gains? ",
  "\\textbf{Policy mechanism:} Japan's Heisei Great Mergers (1999--2010) reduced municipalities from 3,253 to 1,741; a 10+5 year Local Allocation Tax grace period inflated post-merger grants to the sum of pre-merger entitlements, with a scheduled 5-year phase-out creating a mechanical fiscal cliff at staggered dates. ",
  "\\textbf{Outcome definition:} Standard Fiscal Demand per capita (formula-based measure of expenditure need), implied LAT per capita (max(0, SFD $-$ SFR)), Standard Fiscal Revenue per capita (own-source tax capacity), and real balance ratio (surplus share of standard fiscal scale). ",
  "\\textbf{Treatment:} Binary indicator for fiscal years at or after the start of the grace period phase-out, determined mechanically by merger date. ",
  "\\textbf{Data:} MIC Survey on Local Public Finance and RIETI Municipality Converter, FY2011--2023, municipality-year panel of 793 cities (425 merged, 368 never-merged), 10,280 observations. ",
  "\\textbf{Method:} Two-way fixed effects with Sun \\& Abraham (2021) interaction-weighted estimator for staggered adoption; standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Japanese cities (\\textit{shi}) that existed as post-merger entities by FY2011; towns and villages excluded due to data coverage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among merged municipalities. ",
  "Classification refers to magnitude, not statistical significance: ",
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
  sde_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste("  ", list.files(table_dir, pattern = "\\.tex$"), collapse = "\n"), "\n")
