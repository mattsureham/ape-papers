## 05_tables.R — Generate all tables including SDE appendix
source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

df <- fread(file.path(data_dir, "panel_clean.csv"))
results <- readRDS(file.path(data_dir, "results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ── Table 1: Summary Statistics ──
message("Table 1: Summary statistics")
narrow <- df[in_bandwidth_narrow == TRUE & !is.na(tcr)]

# By Appendix B status
sum_stats <- narrow[, .(
  N = .N,
  Mean_Emp = round(mean(emp, na.rm = TRUE), 1),
  Mean_TCR = round(mean(tcr, na.rm = TRUE), 2),
  SD_TCR = round(sd(tcr, na.rm = TRUE), 2),
  Mean_DART = round(mean(dart_rate, na.rm = TRUE), 2),
  SD_DART = round(sd(dart_rate, na.rm = TRUE), 2),
  Mean_Hours = round(mean(hours, na.rm = TRUE) / 1000, 0),
  Pct_Zero_Injury = round(100 * mean(total_cases == 0, na.rm = TRUE), 1)
), by = .(appendix_b, above100)]

# Format
sum_stats[, Group := paste0(
  ifelse(appendix_b == 1, "Appendix B", "Non-App. B"),
  ", ",
  ifelse(above100 == 1, "\\geq 100", "< 100")
)]

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Establishments in 80--120 Employee Bandwidth}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccccc}\n",
  "\\toprule\n",
  " & N & Mean Emp & TCR & SD(TCR) & DART & SD(DART) & Hours (000s) & \\% Zero \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sum_stats)) {
  r <- sum_stats[i]
  tab1_tex <- paste0(tab1_tex,
    r$Group, " & ", format(r$N, big.mark = ","), " & ",
    r$Mean_Emp, " & ", r$Mean_TCR, " & ", r$SD_TCR, " & ",
    r$Mean_DART, " & ", r$SD_DART, " & ",
    r$Mean_Hours, " & ", r$Pct_Zero_Injury, " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\footnotesize\n",
  "\\item \\textit{Notes:} Sample restricted to establishments with 80--120 annual average employees, ",
  "2016--2024. TCR = Total Case Rate per 100 FTE (200,000 hours). ",
  "DART = Days Away/Restricted/Transferred rate. Hours in thousands.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n")

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

# ── Table 2: Main RDD Results ──
message("Table 2: Main RDD results")
# Re-run key specifications for table
narrow[, emp_c_pos := pmax(emp_centered, 0)]

m1 <- feols(tcr ~ above100 + emp_centered + emp_c_pos | year,
            data = narrow[appendix_b == 1], cluster = ~naics4)
m2 <- feols(tcr ~ above100 + emp_centered + emp_c_pos | naics2 + year,
            data = narrow[appendix_b == 1], cluster = ~naics4)
m3 <- feols(tcr ~ above100 + emp_centered + emp_c_pos | naics2 + year + state_code,
            data = narrow[appendix_b == 1], cluster = ~naics4)
m4 <- feols(tcr ~ above100 * appendix_b * post + emp_centered + emp_c_pos |
              naics2 + year + state_code,
            data = narrow, cluster = ~naics4)
m5 <- feols(dart_rate ~ above100 * appendix_b * post + emp_centered + emp_c_pos |
              naics2 + year + state_code,
            data = narrow[!is.na(dart_rate)], cluster = ~naics4)

etable(m1, m2, m3, m4, m5,
       tex = TRUE,
       file = file.path(tab_dir, "tab2_main.tex"),
       title = "Main Results: Injury Rates at the 100-Employee Reporting Threshold",
       label = "tab:main",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       notes = paste0("Sample: establishments with 80--120 employees, 2016--2024. ",
                      "Columns (1)--(3): Appendix B industries only, pooled 2024. ",
                      "Column (4): Difference-in-discontinuities (TCR). ",
                      "Column (5): DinD with DART rate. ",
                      "Standard errors clustered by 4-digit NAICS."),
       depvar = FALSE,
       fitstat = c("n", "r2"))

# ── Table 3: Event Study Estimates ──
message("Table 3: Event study")
es <- results$rd_by_year[outcome == "tcr"]
es[, stars := fifelse(pval < 0.01, "***",
               fifelse(pval < 0.05, "**",
               fifelse(pval < 0.1, "*", "")))]

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Year-by-Year RDD Estimates at 100 Employees}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  "Year & Estimate & Robust SE & $p$-value & $N$ & Bandwidth \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(es)) {
  r <- es[i]
  tab3_tex <- paste0(tab3_tex,
    r$year, " & ", sprintf("%.3f", r$coef), r$stars,
    " & ", sprintf("%.3f", r$se),
    " & ", sprintf("%.3f", r$pval),
    " & ", format(r$n, big.mark = ","),
    " & ", sprintf("%.1f", r$bw), " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\footnotesize\n",
  "\\item \\textit{Notes:} Local polynomial RDD estimates (rdrobust) at the 100-employee ",
  "threshold, Appendix B industries. Outcome: Total Case Rate per 100 FTE. ",
  "The 2024 estimate captures the post-treatment effect; 2016--2023 are pre-period placebos. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n")

writeLines(tab3_tex, file.path(tab_dir, "tab3_event_study.tex"))

# ── Table 4: Robustness ──
message("Table 4: Robustness")
# Bandwidth + donut + polynomial sensitivity
bw <- rob_results$bandwidth_sensitivity
if (!is.null(bw) && nrow(bw) > 0) {
  bw[, stars := fifelse(pval < 0.01, "***",
                 fifelse(pval < 0.05, "**",
                 fifelse(pval < 0.1, "*", "")))]

  tab4_tex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Robustness: Bandwidth Sensitivity}\n",
    "\\label{tab:robustness}\n",
    "\\begin{tabular}{lcccc}\n",
    "\\toprule\n",
    "Bandwidth & Estimate & Robust SE & $p$-value & $N$ \\\\\n",
    "\\midrule\n"
  )

  for (i in 1:nrow(bw)) {
    r <- bw[i]
    tab4_tex <- paste0(tab4_tex,
      "$\\pm$", r$bandwidth,
      " & ", sprintf("%.3f", r$coef), r$stars,
      " & ", sprintf("%.3f", r$se),
      " & ", sprintf("%.3f", r$pval),
      " & ", format(r$n, big.mark = ","), " \\\\\n")
  }

  tab4_tex <- paste0(tab4_tex,
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}\\footnotesize\n",
    "\\item \\textit{Notes:} RDD estimates at the 100-employee threshold for varying bandwidths. ",
    "Appendix B industries, 2024. Outcome: TCR per 100 FTE. ",
    "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n")

  writeLines(tab4_tex, file.path(tab_dir, "tab4_robustness.tex"))
}

# ── Table F1: Standardized Effect Size (SDE) ──
message("Table F1: SDE appendix")

# Compute SDE from main results
# Get pre-treatment SD of outcomes
pre_app_b <- df[year < 2024 & appendix_b == 1 & in_bandwidth_narrow == TRUE]
sd_tcr <- sd(pre_app_b$tcr, na.rm = TRUE)
sd_dart <- sd(pre_app_b$dart_rate, na.rm = TRUE)

# Get coefficients from DinD (the triple interaction)
dind_tcr <- feols(tcr ~ above100 * appendix_b * post +
                    emp_centered + pmax(emp_centered, 0) |
                    naics2 + year + state_code,
                  data = narrow, cluster = ~naics4)
dind_dart <- feols(dart_rate ~ above100 * appendix_b * post +
                     emp_centered + pmax(emp_centered, 0) |
                     naics2 + year + state_code,
                   data = narrow[!is.na(dart_rate)], cluster = ~naics4)

beta_tcr <- coef(dind_tcr)["above100:appendix_b:post"]
se_tcr <- coeftable(dind_tcr)["above100:appendix_b:post", "Std. Error"]
beta_dart <- coef(dind_dart)["above100:appendix_b:post"]
se_dart <- coeftable(dind_dart)["above100:appendix_b:post", "Std. Error"]

sde_tcr <- beta_tcr / sd_tcr
sde_se_tcr <- se_tcr / sd_tcr
sde_dart <- beta_dart / sd_dart
sde_se_dart <- se_dart / sd_dart

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste0("Small ", ifelse(sde > 0, "positive", "negative")))
  if (abs_sde < 0.15) return(paste0("Moderate ", ifelse(sde > 0, "positive", "negative")))
  return(paste0("Large ", ifelse(sde > 0, "positive", "negative")))
}

# Heterogeneity: Manufacturing vs Services
mfg_naics2 <- 31:33
svc_naics2 <- c(44:45, 62, 72)

het_mfg <- narrow[naics2 %in% mfg_naics2]
het_svc <- narrow[naics2 %in% svc_naics2]

# For heterogeneity, use sample splits with simpler spec (above100 only, post+AppB sample)
# to avoid collinearity in thin cells
het_run <- function(sub_dt, label) {
  sub_post <- sub_dt[appendix_b == 1 & year == 2024 & !is.na(tcr)]
  if (nrow(sub_post) < 50) return(list(beta = NA, se = NA, sd_y = NA, sde = NA, sde_se = NA))
  sub_post[, emp_c_pos := pmax(emp_centered, 0)]
  m <- feols(tcr ~ above100 + emp_centered + emp_c_pos | naics4,
             data = sub_post, cluster = ~naics4)
  b <- coef(m)["above100"]
  s <- coeftable(m)["above100", "Std. Error"]
  sd_y <- sd(sub_dt[year < 2024 & appendix_b == 1]$tcr, na.rm = TRUE)
  list(beta = b, se = s, sd_y = sd_y, sde = b / sd_y, sde_se = s / sd_y)
}

het_mfg_res <- het_run(het_mfg, "Manufacturing")
het_svc_res <- het_run(het_svc, "Services")

beta_mfg <- het_mfg_res$beta; se_mfg <- het_mfg_res$se; sd_mfg <- het_mfg_res$sd_y
sde_mfg <- het_mfg_res$sde; sde_se_mfg <- het_mfg_res$sde_se
beta_svc <- het_svc_res$beta; se_svc <- het_svc_res$se; sd_svc <- het_svc_res$sd_y
sde_svc <- het_svc_res$sde; sde_se_svc <- het_svc_res$sde_se

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does mandatory electronic submission of detailed workplace injury logs ",
  "reduce injury rates at establishments crossing the 100-employee regulatory threshold in high-hazard industries? ",
  "\\textbf{Policy mechanism:} OSHA's 2023 final rule (88 FR 47046) requires Appendix B high-hazard ",
  "establishments with 100 or more employees to electronically submit detailed Forms 300 and 301 injury logs, ",
  "making case-level injury data publicly accessible and creating reputational incentives to reduce workplace injuries. ",
  "\\textbf{Outcome definition:} Total Case Rate (TCR) per 100 full-time equivalent workers, computed as ",
  "total recordable cases divided by hours worked times 200,000, following OSHA standard methodology. ",
  "\\textbf{Treatment:} Binary; equals one for Appendix B establishments with 100 or more annual average employees in 2024. ",
  "\\textbf{Data:} OSHA Injury Tracking Application (ITA) 300A Summary Data, 2016--2024, establishment-year level, ",
  "approximately 394,000 establishments per year, restricted to 80--120 employee bandwidth. ",
  "\\textbf{Method:} Difference-in-discontinuities combining sharp RDD at 100 employees with ",
  "Appendix B vs.\\ non-Appendix B industry comparison and pre/post 2024 variation; standard errors clustered by 4-digit NAICS. ",
  "\\textbf{Sample:} Establishments with 80--120 annual average employees reporting to OSHA ITA; ",
  "bandwidth chosen to balance bias-variance tradeoff around the 100-employee threshold. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Total Case Rate & ", sprintf("%.3f", beta_tcr), " & ", sprintf("%.3f", se_tcr),
  " & ", sprintf("%.2f", sd_tcr),
  " & ", sprintf("%.3f", sde_tcr), " & ", sprintf("%.3f", sde_se_tcr),
  " & ", classify_sde(sde_tcr), " \\\\\n",
  "DART Rate & ", sprintf("%.3f", beta_dart), " & ", sprintf("%.3f", se_dart),
  " & ", sprintf("%.2f", sd_dart),
  " & ", sprintf("%.3f", sde_dart), " & ", sprintf("%.3f", sde_se_dart),
  " & ", classify_sde(sde_dart), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (TCR)}} \\\\\n"
)

if (!is.na(sde_mfg)) {
  sde_tex <- paste0(sde_tex,
    "Manufacturing & ", sprintf("%.3f", beta_mfg), " & ", sprintf("%.3f", se_mfg),
    " & ", sprintf("%.2f", sd_mfg),
    " & ", sprintf("%.3f", sde_mfg), " & ", sprintf("%.3f", sde_se_mfg),
    " & ", classify_sde(sde_mfg), " \\\\\n")
}

if (!is.na(sde_svc)) {
  sde_tex <- paste0(sde_tex,
    "Services & ", sprintf("%.3f", beta_svc), " & ", sprintf("%.3f", se_svc),
    " & ", sprintf("%.2f", sd_svc),
    " & ", sprintf("%.3f", sde_svc), " & ", sprintf("%.3f", sde_se_svc),
    " & ", classify_sde(sde_svc), " \\\\\n")
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n")

writeLines(sde_tex, file.path(tab_dir, "tabF1_sde.tex"))

message("\nAll tables saved to ", tab_dir)
message("Tables: ", paste(list.files(tab_dir, pattern = "\\.tex$"), collapse = ", "))
