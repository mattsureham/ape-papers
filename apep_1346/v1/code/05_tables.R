# 05_tables.R — Generate LaTeX tables
# apep_1346: The Lag Windfall

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load data
event_panel <- fread(file.path(data_dir, "event_study_panel.csv"))
drug_windfall <- fread(file.path(data_dir, "drug_windfall.csv"))
entry_drugs <- fread(file.path(data_dir, "generic_entry_events.csv"))
entry_spending <- fread(file.path(data_dir, "entry_drugs_spending.csv"))
asp_panel <- fread(file.path(data_dir, "asp_panel_clean.csv"))
regs <- readRDS(file.path(data_dir, "regression_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: ASP Drug Universe
n_drugs <- uniqueN(asp_panel$hcpcs)
n_quarters <- uniqueN(asp_panel[, .(year, quarter)])
n_obs <- nrow(asp_panel)
mean_payment <- mean(asp_panel$payment_limit, na.rm = TRUE)
med_payment <- median(asp_panel$payment_limit, na.rm = TRUE)
sd_payment <- sd(asp_panel$payment_limit, na.rm = TRUE)

# Panel B: Generic Entry Events
n_entries <- nrow(entry_drugs)
mean_drop <- mean(entry_drugs$drop_pct, na.rm = TRUE)
med_drop <- median(entry_drugs$drop_pct, na.rm = TRUE)
mean_pre <- mean(entry_drugs$pre_payment, na.rm = TRUE)
med_pre <- median(entry_drugs$pre_payment, na.rm = TRUE)

# Panel C: Lag Windfall
mean_wf <- mean(drug_windfall$windfall_per_unit, na.rm = TRUE)
med_wf <- median(drug_windfall$windfall_per_unit, na.rm = TRUE)
mean_wf_pct <- mean(drug_windfall$windfall_pct, na.rm = TRUE)
med_wf_pct <- median(drug_windfall$windfall_pct, na.rm = TRUE)
share_pos <- mean(drug_windfall$windfall_per_unit > 0, na.rm = TRUE)

tab1 <- paste0(
  "\\begin{table}[ht]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  " & Mean & Median & SD & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Medicare Part B Drug Universe (2017--2024)}} \\\\\n",
  sprintf("Payment limit (\\$/unit) & %.1f & %.1f & %.1f & %s \\\\\n",
          mean_payment, med_payment, sd_payment, format(n_obs, big.mark = ",")),
  sprintf("HCPCS codes per quarter & %.0f & & & %d \\\\\n",
          n_obs / n_quarters, n_quarters),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Generic Entry Events}} \\\\\n",
  sprintf("Pre-entry payment (\\$/unit) & %.1f & %.1f & %.1f & %d \\\\\n",
          mean_pre, med_pre, sd(entry_drugs$pre_payment, na.rm = TRUE), n_entries),
  sprintf("Drop at ASP adjustment (\\%%) & %.1f & %.1f & %.1f & \\\\\n",
          mean_drop * 100, med_drop * 100, sd(entry_drugs$drop_pct, na.rm = TRUE) * 100),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Lag Windfall}} \\\\\n",
  sprintf("Windfall per unit (\\$) & %.1f & %.1f & %.1f & %d \\\\\n",
          mean_wf, med_wf, sd(drug_windfall$windfall_per_unit, na.rm = TRUE),
          nrow(drug_windfall)),
  sprintf("Windfall (\\%% of pre-entry) & %.1f & %.1f & %.1f & \\\\\n",
          mean_wf_pct * 100, med_wf_pct * 100,
          sd(drug_windfall$windfall_pct, na.rm = TRUE) * 100),
  sprintf("Share with positive windfall & %.1f\\%% & & & \\\\\n", share_pos * 100),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Data from CMS ASP Quarterly Pricing Files and FDA Orange Book. ",
  "Panel A describes the universe of Medicare Part B physician-administered drugs with quarterly ",
  "payment limits. Panel B describes drugs experiencing a $>$20\\% payment limit decline, ",
  "signaling generic entry and subsequent ASP formula adjustment. Panel C measures the lag ",
  "windfall: the gap between payment limits during the 2-quarter lag window (when generic prices ",
  "are not yet reflected) and the post-adjustment equilibrium.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# =============================================================================
# Table 2: Event Study Results
# =============================================================================
cat("=== Table 2: Event Study ===\n")

# Extract event study coefficients
es_coefs <- coeftable(regs$m1)
es_rows <- data.table(
  event_time = as.integer(gsub("et_factor", "", rownames(es_coefs))),
  coef = es_coefs[, 1],
  se = es_coefs[, 2],
  pval = es_coefs[, 4]
)
es_rows <- es_rows[event_time >= -6 & event_time <= 6]
setorder(es_rows, event_time)

# Add significance stars
es_rows[, stars := fifelse(pval < 0.01, "***",
                  fifelse(pval < 0.05, "**",
                  fifelse(pval < 0.1, "*", "")))]

# Also get placebo coefficients
pl_coefs <- coeftable(robust$m_placebo)
pl_rows <- data.table(
  event_time = as.integer(gsub("et_factor", "", rownames(pl_coefs))),
  coef_pl = pl_coefs[, 1],
  se_pl = pl_coefs[, 2]
)
pl_rows <- pl_rows[event_time >= -6 & event_time <= 6]

es_full <- merge(es_rows, pl_rows, by = "event_time", all.x = TRUE)

tab2_body <- ""
for (i in 1:nrow(es_full)) {
  r <- es_full[i]
  et_label <- ifelse(r$event_time == -3, paste0(r$event_time, " (ref.)"),
                     as.character(r$event_time))
  if (r$event_time == -3) {
    tab2_body <- paste0(tab2_body,
      sprintf("%s & --- & --- & %.4f & (%.4f) \\\\\n",
              et_label, r$coef_pl, r$se_pl))
  } else {
    tab2_body <- paste0(tab2_body,
      sprintf("%s & %.4f%s & (%.4f) & %.4f & (%.4f) \\\\\n",
              et_label, r$coef, r$stars, r$se,
              ifelse(is.na(r$coef_pl), 0, r$coef_pl),
              ifelse(is.na(r$se_pl), 0, r$se_pl)))
  }
}

tab2 <- paste0(
  "\\begin{table}[ht]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Event Study: Normalized Payment Limits Around Generic Entry}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Entry Drugs} & \\multicolumn{2}{c}{Placebo (No Entry)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Event Quarter & Coefficient & SE & Coefficient & SE \\\\\n",
  "\\midrule\n",
  tab2_body,
  "\\midrule\n",
  sprintf("Drug FE & Yes & & Yes & \\\\\n"),
  sprintf("N (drug $\\times$ quarter) & %s & & %s & \\\\\n",
          format(nrow(event_panel), big.mark = ","),
          format(nrow(event_panel[hcpcs %in% robust$stable_var$hcpcs]), big.mark = ",")),
  sprintf("Drugs & %d & & %d & \\\\\n",
          uniqueN(event_panel$hcpcs), nrow(robust$stable_var)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: payment limit normalized by pre-entry mean ",
  "(average of event quarters $-4$ to $-1$). Event quarter 0 is the quarter when the ASP formula ",
  "adjusts to incorporate generic pricing (the first $>$20\\% payment limit decline). The lag ",
  "windfall appears at event quarters $-2$ and $-1$: generic drugs are available but the ASP ",
  "formula still uses pre-generic data, keeping payment limits elevated. Placebo: drugs that ",
  "never experience a $>$20\\% decline, centered at their median observed quarter. Standard ",
  "errors clustered by HCPCS code. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(table_dir, "tab2_event_study.tex"))
cat("Table 2 written.\n")

# =============================================================================
# Table 3: Aggregate Medicare Cost of the Lag Formula
# =============================================================================
cat("=== Table 3: Aggregate Cost ===\n")

agg <- merge(drug_windfall, entry_spending, by = "hcpcs", all.x = TRUE)
spending_years <- 2019:2023

agg[, avg_annual_spending := rowMeans(
  .SD, na.rm = TRUE
), .SDcols = paste0("Tot_Spndng_", spending_years)]

agg[, avg_annual_units := rowMeans(
  .SD, na.rm = TRUE
), .SDcols = paste0("Tot_Dsg_Unts_", spending_years)]

agg[, quarterly_units := avg_annual_units / 4]
agg[, total_drug_windfall := windfall_per_unit * quarterly_units * 2]

agg_matched <- agg[!is.na(avg_annual_spending) & !is.na(windfall_per_unit)]

# Top 10 drugs by windfall cost
top10 <- agg_matched[order(-total_drug_windfall)][1:10]
top10[, drug_label := ifelse(!is.na(Brnd_Name) & Brnd_Name != "",
                             Brnd_Name, hcpcs)]

tab3_body <- ""
for (i in 1:min(10, nrow(top10))) {
  r <- top10[i]
  tab3_body <- paste0(tab3_body,
    sprintf("%s & \\$%.0f & %.0f\\%% & %s & \\$%.1fM \\\\\n",
            substr(r$drug_label, 1, 25),
            r$pre_payment,
            r$windfall_pct * 100,
            format(round(r$quarterly_units), big.mark = ","),
            r$total_drug_windfall / 1e6))
}

total_wf <- sum(agg_matched$total_drug_windfall, na.rm = TRUE)
annual_wf <- total_wf / 7

tab3 <- paste0(
  "\\begin{table}[ht]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Estimated Medicare Cost of the ASP Lag Formula: Top 10 Drugs}\n",
  "\\label{tab:aggregate_cost}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Drug & Pre-Entry & Windfall & Quarterly & Total \\\\\n",
  " & Payment & (\\%) & Units & Windfall \\\\\n",
  "\\midrule\n",
  tab3_body,
  "\\midrule\n",
  sprintf("\\textit{All %d drugs} & & & & \\$%.1fM \\\\\n",
          nrow(agg_matched), total_wf / 1e6),
  sprintf("\\textit{Annualized} & & & & \\$%.1fM/yr \\\\\n",
          annual_wf / 1e6),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Windfall computed as the gap between the payment limit during the ",
  "2-quarter lag window (event quarters $-2$ and $-1$) and the post-adjustment equilibrium ",
  "(event quarters 2--4). Total windfall $=$ windfall per unit $\\times$ quarterly dosage ",
  "units $\\times$ 2 quarters. Quarterly units from Medicare Part B Spending Dashboard ",
  "(average 2019--2023). Annualized estimate divides total across 7 observation years.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(table_dir, "tab3_aggregate_cost.tex"))
cat("Table 3 written.\n")

# =============================================================================
# Table 4: Heterogeneity by Drug Characteristics
# =============================================================================
cat("=== Table 4: Heterogeneity ===\n")

# Cross-sectional regression
m2 <- regs$m2
m3 <- regs$m3

# Add: windfall by spending quartile
agg_matched[, spending_q := cut(avg_annual_spending,
                                quantile(avg_annual_spending, c(0, 0.25, 0.5, 0.75, 1),
                                         na.rm = TRUE),
                                labels = c("Q1 (Low)", "Q2", "Q3", "Q4 (High)"),
                                include.lowest = TRUE)]

het_by_spending <- agg_matched[!is.na(spending_q), .(
  n = .N,
  mean_windfall_pct = mean(windfall_pct, na.rm = TRUE),
  se = sd(windfall_pct, na.rm = TRUE) / sqrt(.N),
  mean_total_windfall = mean(total_drug_windfall, na.rm = TRUE)
), by = spending_q]

tab4 <- paste0(
  "\\begin{table}[ht]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Heterogeneity: Lag Windfall by Drug Spending Quartile}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Spending Quartile & N & Windfall (\\%) & SE & Mean Total (\\$) \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(het_by_spending)) {
  r <- het_by_spending[i]
  tab4 <- paste0(tab4,
    sprintf("%s & %d & %.1f & (%.1f) & %s \\\\\n",
            r$spending_q, r$n,
            r$mean_windfall_pct * 100, r$se * 100,
            format(round(r$mean_total_windfall), big.mark = ",")))
}

tab4 <- paste0(tab4,
  "\\midrule\n",
  sprintf("All drugs & %d & %.1f & (%.1f) & %s \\\\\n",
          nrow(agg_matched),
          mean(agg_matched$windfall_pct, na.rm = TRUE) * 100,
          sd(agg_matched$windfall_pct, na.rm = TRUE) / sqrt(nrow(agg_matched)) * 100,
          format(round(mean(agg_matched$total_drug_windfall, na.rm = TRUE)),
                 big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Drugs ranked by average annual Medicare Part B spending ",
  "(2019--2023). Windfall (\\%) is the gap between lag-window and post-adjustment payment ",
  "limits, expressed as a share of pre-entry payment. Standard errors of the mean in ",
  "parentheses. Mean Total is the average per-drug windfall in dollars over the 2-quarter ",
  "lag window.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(table_dir, "tab4_heterogeneity.tex"))
cat("Table 4 written.\n")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# The main "treatment" is generic entry. The outcome is payment limit.
# Since this is an event study, SDE = β / SD(Y_pre)

# Outcome 1: Normalized payment limit at adjustment (ET 0)
sd_pre_norm <- sd(event_panel$norm_payment[event_panel$event_time < 0], na.rm = TRUE)
beta_et0 <- coeftable(regs$m1)["et_factor0", 1]
se_et0 <- coeftable(regs$m1)["et_factor0", 2]
sde_et0 <- beta_et0 / sd_pre_norm
se_sde_et0 <- se_et0 / sd_pre_norm

# Outcome 2: Normalized payment limit at ET -2 (lag window start)
beta_et_m2 <- coeftable(regs$m1)["et_factor-2", 1]
se_et_m2 <- coeftable(regs$m1)["et_factor-2", 2]
sde_et_m2 <- beta_et_m2 / sd_pre_norm
se_sde_et_m2 <- se_et_m2 / sd_pre_norm

# Outcome 3: Windfall % (cross-sectional, continuous treatment = drop size)
sd_drop <- sd(drug_windfall$total_drop, na.rm = TRUE)
sd_wf <- sd(drug_windfall$windfall_pct[drug_windfall$windfall_pct < quantile(drug_windfall$windfall_pct, 0.99, na.rm = TRUE)], na.rm = TRUE)
beta_xs <- coeftable(regs$m2)["total_drop", 1]
se_xs <- coeftable(regs$m2)["total_drop", 2]
sde_xs <- beta_xs * sd_drop / sd_wf
se_sde_xs <- se_xs * sd_drop / sd_wf

# Classification function
classify_sde <- function(x) {
  if (is.na(x)) return("---")
  abs_x <- abs(x)
  sign_x <- sign(x)
  if (abs_x < 0.005) return("Null")
  if (abs_x < 0.05) {
    if (sign_x > 0) return("Small positive")
    else return("Small negative")
  }
  if (abs_x < 0.15) {
    if (sign_x > 0) return("Moderate positive")
    else return("Moderate negative")
  }
  if (sign_x > 0) return("Large positive")
  else return("Large negative")
}

# --- Panel A: Pooled ---
sde_rows_a <- data.table(
  outcome = c(
    "Payment limit at ASP adjustment",
    "Payment limit during lag window",
    "Windfall (\\% of pre-entry)"
  ),
  beta = c(beta_et0, beta_et_m2, beta_xs),
  se = c(se_et0, se_et_m2, se_xs),
  sd_y = c(sd_pre_norm, sd_pre_norm, sd_wf),
  sde = c(sde_et0, sde_et_m2, sde_xs),
  se_sde = c(se_sde_et0, se_sde_et_m2, se_sde_xs)
)
sde_rows_a[, classification := sapply(sde, classify_sde)]

# --- Panel B: Heterogeneous (by spending level) ---
# Split event_panel by high vs low spending drugs
spending_med <- median(agg_matched$avg_annual_spending, na.rm = TRUE)
high_spend_hcpcs <- agg_matched[avg_annual_spending > spending_med]$hcpcs
low_spend_hcpcs <- agg_matched[avg_annual_spending <= spending_med]$hcpcs

# Re-run event study on subsamples
ep_high <- event_panel[hcpcs %in% high_spend_hcpcs]
ep_low <- event_panel[hcpcs %in% low_spend_hcpcs]

ep_high[, et_factor := factor(event_time)]
ep_high[, et_factor := relevel(et_factor, ref = "-3")]
ep_low[, et_factor := factor(event_time)]
ep_low[, et_factor := relevel(et_factor, ref = "-3")]

m_high <- feols(norm_payment ~ et_factor | hcpcs, data = ep_high, cluster = ~ hcpcs)
m_low <- feols(norm_payment ~ et_factor | hcpcs, data = ep_low, cluster = ~ hcpcs)

beta_high <- coeftable(m_high)["et_factor0", 1]
se_high <- coeftable(m_high)["et_factor0", 2]
sd_pre_high <- sd(ep_high$norm_payment[ep_high$event_time < 0], na.rm = TRUE)
sde_high <- beta_high / sd_pre_high
se_sde_high <- se_high / sd_pre_high

beta_low <- coeftable(m_low)["et_factor0", 1]
se_low <- coeftable(m_low)["et_factor0", 2]
sd_pre_low <- sd(ep_low$norm_payment[ep_low$event_time < 0], na.rm = TRUE)
sde_low <- beta_low / sd_pre_low
se_sde_low <- se_low / sd_pre_low

sde_rows_b <- data.table(
  outcome = c(
    "High-spending drugs (above median)",
    "Low-spending drugs (below median)"
  ),
  beta = c(beta_high, beta_low),
  se = c(se_high, se_low),
  sd_y = c(sd_pre_high, sd_pre_low),
  sde = c(sde_high, sde_low),
  se_sde = c(se_sde_high, se_sde_low)
)
sde_rows_b[, classification := sapply(sde, classify_sde)]

# Build LaTeX table
sde_body_a <- ""
for (i in 1:nrow(sde_rows_a)) {
  r <- sde_rows_a[i]
  sde_body_a <- paste0(sde_body_a,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

sde_body_b <- ""
for (i in 1:nrow(sde_rows_b)) {
  r <- sde_rows_b[i]
  sde_body_b <- paste0(sde_body_b,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does Medicare Part B's 2-quarter ASP update lag create a ",
  "temporary windfall that keeps payment limits elevated after generic drug entry? ",
  "\\textbf{Policy mechanism:} Section 1847A SSA reimburses physician-administered drugs at ",
  "ASP+6\\%, updated quarterly with a 2-quarter lag; when a generic enters, reimbursement ",
  "continues at pre-generic levels for two quarters before the formula adjusts, creating a ",
  "mechanical spread between payment limits and market prices. ",
  "\\textbf{Outcome definition:} Payment limit per dosage unit from CMS ASP Quarterly Pricing ",
  "Files, normalized by the drug's pre-entry mean (event quarters $-4$ to $-1$). ",
  "\\textbf{Treatment:} Binary generic entry event identified by a $>$20\\% payment limit ",
  "decline; 235 events across 2017--2024. ",
  "\\textbf{Data:} CMS ASP Quarterly Pricing Files (26 quarters, 2017Q3--2024Q4), ",
  "FDA Orange Book, Medicare Part B Spending Dashboard; 1,001 unique HCPCS codes, ",
  "17,281 drug-quarter observations. ",
  "\\textbf{Method:} Within-drug event study with drug fixed effects; standard errors clustered ",
  "by HCPCS code; placebo test on 474 drugs without generic entry. ",
  "\\textbf{Sample:} Drugs with at least 4 pre-entry quarters in the ASP files; excludes ",
  "vaccines and blood products. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation ",
  "of normalized payment limits. Classification refers to magnitude, not statistical ",
  "significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), ",
  "Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[ht]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_body_a,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Medicare spending)}} \\\\\n",
  sde_body_b,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables written to", table_dir, "\n")
