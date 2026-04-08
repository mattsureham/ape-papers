# 05_tables.R — Generate all tables for paper
# APEP-1420: The Coding Dividend

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

sumstats <- analysis[, .(
  Variable = c(
    "Discharges per hospital-DRG-year (MCC)",
    "Discharges per hospital-DRG-year (CC)",
    "Discharges per hospital-DRG-year (base)",
    "Average submitted charges, MCC (\\$)",
    "Average submitted charges, CC (\\$)",
    "Average Medicare payment, MCC (\\$)",
    "Average Medicare payment, CC (\\$)",
    "MCC--CC payment gap (\\$)",
    "MCC share of triplet discharges",
    "Charge ratio (MCC/CC)"
  ),
  Mean = c(
    mean(discharges_MCC, na.rm = TRUE),
    mean(discharges_CC, na.rm = TRUE),
    mean(discharges_BASE, na.rm = TRUE),
    mean(avg_charges_MCC, na.rm = TRUE),
    mean(avg_charges_CC, na.rm = TRUE),
    mean(avg_medicare_payment_MCC, na.rm = TRUE),
    mean(avg_medicare_payment_CC, na.rm = TRUE),
    mean(mcc_cc_payment_gap, na.rm = TRUE),
    mean(mcc_share, na.rm = TRUE),
    mean(charge_ratio_mcc_cc, na.rm = TRUE)
  ),
  SD = c(
    sd(discharges_MCC, na.rm = TRUE),
    sd(discharges_CC, na.rm = TRUE),
    sd(discharges_BASE, na.rm = TRUE),
    sd(avg_charges_MCC, na.rm = TRUE),
    sd(avg_charges_CC, na.rm = TRUE),
    sd(avg_medicare_payment_MCC, na.rm = TRUE),
    sd(avg_medicare_payment_CC, na.rm = TRUE),
    sd(mcc_cc_payment_gap, na.rm = TRUE),
    sd(mcc_share, na.rm = TRUE),
    sd(charge_ratio_mcc_cc, na.rm = TRUE)
  ),
  P25 = c(
    quantile(discharges_MCC, 0.25, na.rm = TRUE),
    quantile(discharges_CC, 0.25, na.rm = TRUE),
    quantile(discharges_BASE, 0.25, na.rm = TRUE),
    quantile(avg_charges_MCC, 0.25, na.rm = TRUE),
    quantile(avg_charges_CC, 0.25, na.rm = TRUE),
    quantile(avg_medicare_payment_MCC, 0.25, na.rm = TRUE),
    quantile(avg_medicare_payment_CC, 0.25, na.rm = TRUE),
    quantile(mcc_cc_payment_gap, 0.25, na.rm = TRUE),
    quantile(mcc_share, 0.25, na.rm = TRUE),
    quantile(charge_ratio_mcc_cc, 0.25, na.rm = TRUE)
  ),
  P75 = c(
    quantile(discharges_MCC, 0.75, na.rm = TRUE),
    quantile(discharges_CC, 0.75, na.rm = TRUE),
    quantile(discharges_BASE, 0.75, na.rm = TRUE),
    quantile(avg_charges_MCC, 0.75, na.rm = TRUE),
    quantile(avg_charges_CC, 0.75, na.rm = TRUE),
    quantile(avg_medicare_payment_MCC, 0.75, na.rm = TRUE),
    quantile(avg_medicare_payment_CC, 0.75, na.rm = TRUE),
    quantile(mcc_cc_payment_gap, 0.75, na.rm = TRUE),
    quantile(mcc_share, 0.75, na.rm = TRUE),
    quantile(charge_ratio_mcc_cc, 0.75, na.rm = TRUE)
  )
)]

# Format numbers
format_num <- function(x, digits = 0) {
  ifelse(abs(x) < 1, sprintf(paste0("%.", max(digits, 3), "f"), x),
         format(round(x, digits), big.mark = ",", nsmall = digits))
}

n_obs <- nrow(analysis)
n_hosp <- uniqueN(analysis$provider_id)
n_triplets <- uniqueN(analysis$triplet_id)
n_years <- uniqueN(analysis$year)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Medicare Inpatient DRG Triplets}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & P25 & P75 \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(sumstats)) {
  row <- sumstats[i]
  if (abs(row$Mean) >= 100) {
    tab1_tex <- paste0(tab1_tex, sprintf("%s & %s & %s & %s & %s \\\\\n",
      row$Variable,
      format(round(row$Mean), big.mark = ","),
      format(round(row$SD), big.mark = ","),
      format(round(row$P25), big.mark = ","),
      format(round(row$P75), big.mark = ",")))
  } else {
    tab1_tex <- paste0(tab1_tex, sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\\n",
      row$Variable, row$Mean, row$SD, row$P25, row$P75))
  }
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\\n", format(n_obs, big.mark = ",")),
  sprintf("Hospitals & \\multicolumn{4}{c}{%s} \\\\\n", format(n_hosp, big.mark = ",")),
  sprintf("DRG triplets & \\multicolumn{4}{c}{%d} \\\\\n", n_triplets),
  sprintf("Years & \\multicolumn{4}{c}{%d} \\\\\n", n_years),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Data from CMS Medicare Inpatient Hospitals by Provider ",
  "and Service Public Use File. Each observation is a hospital $\\times$ DRG triplet ",
  "$\\times$ fiscal year. A DRG triplet consists of three MS-DRGs sharing the same ",
  "base condition but differing in severity classification: with MCC, with CC, and ",
  "without CC/MCC. MCC share is the fraction of triplet discharges coded to the MCC tier. ",
  "Charge ratio is average submitted charges for MCC discharges divided by CC discharges. ",
  "Sample restricted to complete triplets with $>$10 discharges per tier.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

# ============================================================
# TABLE 2: Main Results — The Coding Dividend
# ============================================================
cat("\n=== Generating Table 2: Main Results ===\n")

m1 <- results$coding_dividend$m1
m2 <- results$coding_dividend$m2
m3 <- results$coding_dividend$m3
m4 <- results$coding_margin$m4
m5 <- results$coding_margin$m5
m6 <- results$coding_margin$m6

# Extract coefficients and standard errors
extract_coef <- function(model, var_pattern) {
  ct <- coeftable(model)
  idx <- grep(var_pattern, rownames(ct))
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(ct[idx[1], 1], ct[idx[1], 2], ct[idx[1], 4])  # coef, se, pval
}

# Build table
tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Coding Dividend: Payment Pass-Through to Treatment Intensity}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Panel A: Charge Gap} & \\multicolumn{3}{c}{Panel B: MCC Share} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n"
)

models_a <- list(m1, m2, m3)
models_b <- list(m4, m5, m6)

# Panel A: log payment gap → log charge gap
coefs_a <- sapply(models_a, function(m) extract_coef(m, "log_payment"))
# Panel B: payment gap → MCC share
coefs_b <- sapply(models_b, function(m) extract_coef(m, "mcc_cc_payment"))

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

# Coefficient row
tab2_tex <- paste0(tab2_tex,
  sprintf("Log payment gap & %.3f%s & %.3f%s & %.3f%s",
          coefs_a[1,1], stars(coefs_a[3,1]),
          coefs_a[1,2], stars(coefs_a[3,2]),
          coefs_a[1,3], stars(coefs_a[3,3])),
  " & & & \\\\\n"
)
# SE row
tab2_tex <- paste0(tab2_tex,
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & & & \\\\\n",
          coefs_a[2,1], coefs_a[2,2], coefs_a[2,3])
)

# Payment gap for Panel B
tab2_tex <- paste0(tab2_tex,
  sprintf("Payment gap (\\$1,000) & & & & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          coefs_b[1,1]*1000, stars(coefs_b[3,1]),
          coefs_b[1,2]*1000, stars(coefs_b[3,2]),
          coefs_b[1,3]*1000, stars(coefs_b[3,3]))
)
tab2_tex <- paste0(tab2_tex,
  sprintf(" & & & & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          coefs_b[2,1]*1000, coefs_b[2,2]*1000, coefs_b[2,3]*1000)
)

tab2_tex <- paste0(tab2_tex,
  "\\hline\n",
  "Triplet FE & Yes & Yes & -- & Yes & Yes & -- \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Hospital FE & No & Yes & -- & No & Yes & -- \\\\\n",
  "Hospital $\\times$ Triplet FE & No & No & Yes & No & No & Yes \\\\\n",
  sprintf("Observations & \\multicolumn{3}{c}{%s} & \\multicolumn{3}{c}{%s} \\\\\n",
          format(n_obs, big.mark = ","), format(n_obs, big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"),
          r2(m4, "r2"), r2(m5, "r2"), r2(m6, "r2")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A estimates the elasticity of the MCC--CC charge gap ",
  "with respect to the MCC--CC payment gap (the ``coding dividend''). A coefficient of 1 ",
  "implies full pass-through of payment into treatment intensity; 0 implies charges are ",
  "unresponsive. Panel B estimates the effect of the payment gap on MCC coding share ",
  "(fraction of triplet discharges in the MCC tier). Coefficients in Panel B are scaled ",
  "per \\$1,000 of payment gap. Standard errors clustered at the DRG triplet level in ",
  "parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("\n=== Generating Table 3: Event Study ===\n")

if (!is.null(results$event_study)) {
  es_charges <- results$event_study$charges
  es_coding <- results$event_study$coding

  ct_charges <- coeftable(es_charges)
  ct_coding <- coeftable(es_coding)

  # Extract event-time coefficients
  event_times <- c(-3, -2, 0, 1, 2, 3)  # -1 is omitted reference
  event_labels <- c("$t-3$", "$t-2$", "$t$ (shock)", "$t+1$", "$t+2$", "$t+3$")

  tab3_tex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Event Study: Response to Large Payment Gap Changes}\n",
    "\\label{tab:eventstudy}\n",
    "\\begin{tabular}{lcccc}\n",
    "\\hline\\hline\n",
    " & \\multicolumn{2}{c}{Charge Gap} & \\multicolumn{2}{c}{MCC Share} \\\\\n",
    "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
    "Event Time & Coeff. & SE & Coeff. & SE \\\\\n",
    "\\hline\n"
  )

  for (i in seq_along(event_times)) {
    et <- event_times[i]
    lab <- event_labels[i]

    # Find coefficient in model
    et_name <- sprintf("event_time_f%d", et)

    if (et_name %in% rownames(ct_charges)) {
      c_coef <- sprintf("%.4f%s", ct_charges[et_name, 1], stars(ct_charges[et_name, 4]))
      c_se <- sprintf("(%.4f)", ct_charges[et_name, 2])
    } else {
      c_coef <- "--"
      c_se <- ""
    }

    if (et_name %in% rownames(ct_coding)) {
      m_coef <- sprintf("%.4f%s", ct_coding[et_name, 1], stars(ct_coding[et_name, 4]))
      m_se <- sprintf("(%.4f)", ct_coding[et_name, 2])
    } else {
      m_coef <- "--"
      m_se <- ""
    }

    tab3_tex <- paste0(tab3_tex, sprintf("%s & %s & %s & %s & %s \\\\\n",
                                          lab, c_coef, c_se, m_coef, m_se))
  }

  # Add reference period
  tab3_tex <- paste0(tab3_tex,
    "\\hline\n",
    "Reference period & \\multicolumn{4}{c}{$t-1$ (year before shock)} \\\\\n",
    sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\\n",
            format(nobs(es_charges), big.mark = ",")),
    "Hospital FE & \\multicolumn{4}{c}{Yes} \\\\\n",
    "Triplet FE & \\multicolumn{4}{c}{Yes} \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\\small\n",
    "\\item \\textit{Notes:} Event study around large year-over-year changes in the ",
    "MCC--CC payment gap (top quartile of $|\\Delta$gap$|$). Reference period is $t-1$. ",
    "Pre-period coefficients ($t-3$, $t-2$) test parallel trends. Post-period coefficients ",
    "capture the treatment response. Standard errors clustered at the DRG triplet level.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))
  cat("Table 3 saved.\n")
} else {
  cat("No event study results available.\n")
}

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("\n=== Generating Table 4: Robustness ===\n")

# Collect key coefficient from each robustness spec
rob_specs <- list()

# Main result (for comparison)
main_ct <- coeftable(results$coding_dividend$m3)
main_var <- grep("log_payment", rownames(main_ct))
if (length(main_var) > 0) {
  rob_specs[["Main specification"]] <- c(main_ct[main_var[1], 1], main_ct[main_var[1], 2], main_ct[main_var[1], 4], nobs(results$coding_dividend$m3))
}

# Surgical
if (!is.null(robust$surgical)) {
  ct <- coeftable(robust$surgical)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["Surgical DRGs only"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$surgical))
}

# Medical
if (!is.null(robust$medical)) {
  ct <- coeftable(robust$medical)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["Medical DRGs only"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$medical))
}

# Large gap
if (!is.null(robust$large_gap)) {
  ct <- coeftable(robust$large_gap)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["Above-median payment gap"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$large_gap))
}

# Small gap
if (!is.null(robust$small_gap)) {
  ct <- coeftable(robust$small_gap)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["Below-median payment gap"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$small_gap))
}

# State clustering
if (!is.null(robust$state_cluster)) {
  ct <- coeftable(robust$state_cluster)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["State-clustered SEs"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$state_cluster))
}

# Two-way clustering
if (!is.null(robust$twoway_cluster)) {
  ct <- coeftable(robust$twoway_cluster)
  idx <- grep("log_payment", rownames(ct))
  if (length(idx) > 0) rob_specs[["Two-way clustered SEs"]] <- c(ct[idx[1],1], ct[idx[1],2], ct[idx[1],4], nobs(robust$twoway_cluster))
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Coding Dividend Under Alternative Specifications}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE & $N$ \\\\\n",
  "\\hline\n"
)

for (name in names(rob_specs)) {
  vals <- rob_specs[[name]]
  tab4_tex <- paste0(tab4_tex, sprintf("%s & %.3f%s & (%.3f) & %s \\\\\n",
                                        name, vals[1], stars(vals[3]), vals[2],
                                        format(round(vals[4]), big.mark = ",")))
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on log(payment gap MCC/CC) ",
  "from a separate regression of log(charge gap MCC/CC) with hospital $\\times$ triplet ",
  "and year fixed effects, unless otherwise noted. Standard errors clustered at the DRG ",
  "triplet level unless otherwise noted. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robust.tex"))
cat("Table 4 saved.\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================
cat("\n=== Generating Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SDE = β̂ / SD(Y) for binary treatment
# SDE = β̂ × SD(X) / SD(Y) for continuous treatment

# Our treatment is continuous: log(payment gap MCC/CC)
sd_x <- sd(analysis$log_payment_gap_mcc_cc, na.rm = TRUE)
sd_y_charges <- sd(analysis$log_charge_gap_mcc_cc, na.rm = TRUE)
sd_y_mccshare <- sd(analysis$mcc_share, na.rm = TRUE)

# Main spec coefficients (model 3: hosp×triplet FE)
m3 <- results$coding_dividend$m3
ct3 <- coeftable(m3)
idx3 <- grep("log_payment", rownames(ct3))
beta_charges <- ct3[idx3[1], 1]
se_charges <- ct3[idx3[1], 2]

m6 <- results$coding_margin$m6
ct6 <- coeftable(m6)
idx6 <- grep("mcc_cc_payment", rownames(ct6))
beta_coding <- ct6[idx6[1], 1]
se_coding <- ct6[idx6[1], 2]

# SDE calculations
sde_charges <- beta_charges * sd_x / sd_y_charges
se_sde_charges <- se_charges * sd_x / sd_y_charges

# For coding margin, treatment is in dollars
sd_x_coding <- sd(analysis$mcc_cc_payment_gap, na.rm = TRUE)
sde_coding <- beta_coding * sd_x_coding / sd_y_mccshare
se_sde_coding <- se_coding * sd_x_coding / sd_y_mccshare

# Volume regression
if (!is.null(robust$volume)) {
  ct_vol <- coeftable(robust$volume)
  idx_vol <- grep("mcc_cc_payment", rownames(ct_vol))
  beta_vol <- ct_vol[idx_vol[1], 1]
  se_vol <- ct_vol[idx_vol[1], 2]
  sd_y_vol <- sd(analysis$log_total_discharges, na.rm = TRUE)
  sde_vol <- beta_vol * sd_x_coding / sd_y_vol
  se_sde_vol <- se_vol * sd_x_coding / sd_y_vol
}

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde) || !is.finite(sde)) return("--")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build SDE table
sde_rows <- data.frame(
  Outcome = character(),
  Beta = numeric(),
  SE = numeric(),
  SD_Y = numeric(),
  SDE = numeric(),
  SE_SDE = numeric(),
  Class = character(),
  stringsAsFactors = FALSE
)

# Panel A: Pooled
sde_rows <- rbind(sde_rows, data.frame(
  Outcome = "Log charge gap (MCC/CC)",
  Beta = beta_charges, SE = se_charges,
  SD_Y = sd_y_charges, SDE = sde_charges,
  SE_SDE = se_sde_charges, Class = classify_sde(sde_charges)
))

sde_rows <- rbind(sde_rows, data.frame(
  Outcome = "MCC discharge share",
  Beta = beta_coding, SE = se_coding,
  SD_Y = sd_y_mccshare, SDE = sde_coding,
  SE_SDE = se_sde_coding, Class = classify_sde(sde_coding)
))

if (!is.null(robust$volume)) {
  sde_rows <- rbind(sde_rows, data.frame(
    Outcome = "Log total discharges",
    Beta = beta_vol, SE = se_vol,
    SD_Y = sd_y_vol, SDE = sde_vol,
    SE_SDE = se_sde_vol, Class = classify_sde(sde_vol)
  ))
}

# Panel B: Heterogeneous (surgical vs medical)
surg_ct <- coeftable(robust$surgical)
surg_idx <- grep("log_payment", rownames(surg_ct))
med_ct <- coeftable(robust$medical)
med_idx <- grep("log_payment", rownames(med_ct))

if (length(surg_idx) > 0 && length(med_idx) > 0) {
  # Surgical subsample SD
  surg_data <- analysis[grepl("\\bOR\\b|SURG|PROC|IMPLANT|TRANSPLANT", base_condition, ignore.case = TRUE)]
  med_data <- analysis[!grepl("\\bOR\\b|SURG|PROC|IMPLANT|TRANSPLANT", base_condition, ignore.case = TRUE)]

  sd_y_surg <- sd(surg_data$log_charge_gap_mcc_cc, na.rm = TRUE)
  sd_y_med <- sd(med_data$log_charge_gap_mcc_cc, na.rm = TRUE)
  sd_x_surg <- sd(surg_data$log_payment_gap_mcc_cc, na.rm = TRUE)
  sd_x_med <- sd(med_data$log_payment_gap_mcc_cc, na.rm = TRUE)

  sde_surg <- surg_ct[surg_idx[1], 1] * sd_x_surg / sd_y_surg
  se_sde_surg <- surg_ct[surg_idx[1], 2] * sd_x_surg / sd_y_surg
  sde_med <- med_ct[med_idx[1], 1] * sd_x_med / sd_y_med
  se_sde_med <- med_ct[med_idx[1], 2] * sd_x_med / sd_y_med

  sde_rows <- rbind(sde_rows, data.frame(
    Outcome = "Charge gap --- Surgical DRGs",
    Beta = surg_ct[surg_idx[1], 1], SE = surg_ct[surg_idx[1], 2],
    SD_Y = sd_y_surg, SDE = sde_surg,
    SE_SDE = se_sde_surg, Class = classify_sde(sde_surg)
  ))

  sde_rows <- rbind(sde_rows, data.frame(
    Outcome = "Charge gap --- Medical DRGs",
    Beta = med_ct[med_idx[1], 1], SE = med_ct[med_idx[1], 2],
    SD_Y = sd_y_med, SDE = sde_med,
    SE_SDE = se_sde_med, Class = classify_sde(sde_med)
  ))
}

# Format SDE table
sde_tex <- paste0(
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

# Panel A rows (first 2-3 rows)
n_pooled <- min(3, nrow(sde_rows))
for (i in 1:n_pooled) {
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
    sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
    sde_rows$Class[i]
  ))
}

# Panel B
if (nrow(sde_rows) > n_pooled) {
  sde_tex <- paste0(sde_tex,
    "\\hline\n",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n"
  )
  for (i in (n_pooled + 1):nrow(sde_rows)) {
    sde_tex <- paste0(sde_tex, sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
      sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
      sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
      sde_rows$Class[i]
    ))
  }
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Medicare's severity-based payment system (MS-DRG) affect hospital treatment intensity, or only clinical documentation and coding behavior? ",
  "\\textbf{Policy mechanism:} CMS classifies inpatient diagnoses into severity tiers (MCC, CC, non-CC) that determine DRG assignment and payment; reclassification of codes between tiers mechanically shifts payment by \\$3,000--\\$15,000 per discharge without changing the underlying clinical condition. ",
  "\\textbf{Outcome definition:} Log ratio of average submitted charges between MCC and CC tiers within a DRG triplet (treatment intensity proxy); MCC discharge share (coding margin); log total triplet discharges (volume margin). ",
  "\\textbf{Treatment:} Continuous---log ratio of average Medicare payment between MCC and CC tiers within a DRG triplet, varying across triplets and over time as CMS recalibrates DRG relative weights. ",
  "\\textbf{Data:} CMS Medicare Inpatient Hospitals by Provider and Service PUF, fiscal years as available, hospital $\\times$ DRG level, sample of complete triplets with $>$10 discharges per tier. ",
  "\\textbf{Method:} OLS with hospital $\\times$ triplet and year fixed effects; standard errors clustered at the DRG triplet level. ",
  "\\textbf{Sample:} Acute-care hospitals reporting to CMS; restricted to DRG triplets (base, CC, MCC variants of same condition) with non-suppressed discharge counts in all three tiers. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the within-sample standard deviation of the treatment variable and SD($Y$) is the standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(sde_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\nAll tables generated.\n")
