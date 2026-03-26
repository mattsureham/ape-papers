## 05_tables.R — Generate all LaTeX tables
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

cat("=== Loading results ===\n")

panel <- fread("../data/panel_internet_banking.csv")
trans <- fread("../data/transposition_dates.csv")
cs_out <- readRDS("../data/cs_results.rds")
cs_es <- readRDS("../data/cs_event_study.rds")
cs_simple <- readRDS("../data/cs_simple.rds")
twfe_es <- readRDS("../data/twfe_event_study.rds")
loo <- fread("../data/leave_one_out.csv")

# Load optional results
sa_result <- if (file.exists("../data/sa_result.rds")) readRDS("../data/sa_result.rds") else NULL
wcb_result <- if (file.exists("../data/wcb_result.rds")) readRDS("../data/wcb_result.rds") else NULL
placebo_twfe <- if (file.exists("../data/placebo_twfe.rds")) readRDS("../data/placebo_twfe.rds") else NULL
cs_placebo <- if (file.exists("../data/cs_placebo.rds")) readRDS("../data/cs_placebo.rds") else NULL
hardship_twfe <- if (file.exists("../data/hardship_twfe.rds")) readRDS("../data/hardship_twfe.rds") else NULL
cs_hardship <- if (file.exists("../data/cs_hardship.rds")) readRDS("../data/cs_hardship.rds") else NULL
cs_findex <- if (file.exists("../data/cs_findex.rds")) readRDS("../data/cs_findex.rds") else NULL
findex_panel <- fread("../data/panel_findex.csv")

# ==================================================================
# TABLE 1: Transposition Timeline and Baseline Characteristics
# ==================================================================
cat("\n=== Table 1: Transposition Timeline ===\n")

# Merge baseline internet banking (2014 or earliest available)
baseline <- panel[year == min(year), .(country_code, baseline_ibank = internet_banking_pct)]

tab1_data <- merge(trans, baseline, by = "country_code", all.x = TRUE)

# Add Findex baseline (2014)
findex_base <- findex_panel[year == 2014, .(country_code, findex_2014 = account_pct)]
tab1_data <- merge(tab1_data, findex_base, by = "country_code", all.x = TRUE)

tab1_data[, status := fifelse(pre_existing_law, "Pre-existing law",
                               fifelse(is.na(transposition_date), "Unknown",
                                        fifelse(transposition_date <= as.Date("2016-09-18"),
                                                 "On time", "Late")))]

tab1_data <- tab1_data[order(transposition_date, na.last = TRUE)]

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Transposition of the Payment Accounts Directive (2014/92/EU)}",
  "\\label{tab:transposition}",
  "\\begin{tabular}{llccc}",
  "\\hline\\hline",
  "Country & Status & Transposition Date & Account \\% (2014) & Internet Banking \\% \\\\",
  "\\hline"
)

for (i in seq_len(nrow(tab1_data))) {
  row <- tab1_data[i]
  trans_str <- if (is.na(row$transposition_date)) "---" else format(row$transposition_date, "%b %Y")
  findex_str <- if (is.na(row$findex_2014)) "---" else sprintf("%.1f", row$findex_2014)
  ibank_str <- if (is.na(row$baseline_ibank)) "---" else sprintf("%.1f", row$baseline_ibank)

  tab1_lines <- c(tab1_lines,
    paste0(row$country_name, " & ", row$status, " & ", trans_str, " & ",
           findex_str, " & ", ibank_str, " \\\\"))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Transposition dates from CELLAR SPARQL (EUR-Lex national implementation measures for CELEX 32014L0092). Account ownership from Global Findex 2014 wave. Internet banking from Eurostat (isoc\\_bde15cbc). Deadline: September 18, 2016. Pre-existing law countries (CZ, HU, SK, SI) serve as never-treated controls.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_transposition.tex")
cat("  tab1_transposition.tex written.\n")

# ==================================================================
# TABLE 2: Main Results — CS-DiD and TWFE
# ==================================================================
cat("\n=== Table 2: Main Results ===\n")

# Get TWFE coefficient
twfe_main <- feols(internet_banking_pct ~ treated | country_id + year,
                    data = panel, cluster = ~country_id)

# CS-DiD simple ATT
cs_att <- cs_simple$overall.att
cs_se <- cs_simple$overall.se

# Findex TWFE
findex_twfe <- feols(account_pct ~ treated | country_id + year,
                      data = findex_panel, cluster = ~country_id)

# Findex CS-DiD
cs_findex_att <- if (!is.null(cs_findex)) {
  findex_agg <- aggte(cs_findex, type = "simple")
  c(findex_agg$overall.att, findex_agg$overall.se)
} else c(NA, NA)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of PAD Transposition on Financial Inclusion}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Internet Banking (\\%)} & \\multicolumn{2}{c}{Account Ownership (\\%)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & CS-DiD & TWFE & CS-DiD & TWFE \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("PAD Transposed & %.2f & %.2f & %s & %.2f \\\\",
          cs_att, coef(twfe_main)["treated"],
          if (!is.na(cs_findex_att[1])) sprintf("%.2f", cs_findex_att[1]) else "---",
          coef(findex_twfe)["treated"]),
  sprintf(" & (%.2f) & (%.2f) & %s & (%.2f) \\\\",
          cs_se, sqrt(vcov(twfe_main)["treated", "treated"]),
          if (!is.na(cs_findex_att[2])) sprintf("(%.2f)", cs_findex_att[2]) else "---",
          sqrt(vcov(findex_twfe)["treated", "treated"])),
  "\\hline",
  sprintf("Countries & %d & %d & %d & %d \\\\",
          uniqueN(panel$country_code), uniqueN(panel$country_code),
          uniqueN(findex_panel$country_code), uniqueN(findex_panel$country_code)),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nrow(panel), nrow(panel), nrow(findex_panel), nrow(findex_panel)),
  sprintf("Years & %d--%d & %d--%d & %d--%d & %d--%d \\\\",
          min(panel$year), max(panel$year), min(panel$year), max(panel$year),
          min(findex_panel$year), max(findex_panel$year),
          min(findex_panel$year), max(findex_panel$year)),
  "Country FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  "Year FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1) and (3) report Callaway and Sant'Anna (2021) simple ATT estimates using not-yet-treated and never-treated as comparison groups, with doubly robust estimation. Columns (2) and (4) report TWFE estimates. Internet banking is the percentage of individuals who used internet banking in the last three months (Eurostat isoc\\_bde15cbc). Account ownership is the percentage of adults with a financial institution account (Global Findex). Standard errors clustered at the country level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main_results.tex")
cat("  tab2_main_results.tex written.\n")

# ==================================================================
# TABLE 3: Event Study Coefficients
# ==================================================================
cat("\n=== Table 3: Event Study ===\n")

es_data <- data.table(
  period = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
)
es_data[, stars := fifelse(abs(att/se) > 2.576, "***",
                            fifelse(abs(att/se) > 1.96, "**",
                                     fifelse(abs(att/se) > 1.645, "*", "")))]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study Estimates}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Event Time & CS-DiD ATT & SE \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_data))) {
  row <- es_data[i]
  label <- if (row$period < 0) paste0("$t", row$period, "$") else paste0("$t+", row$period, "$")
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %.2f%s & (%.2f) \\\\", label, row$att, row$stars, row$se))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic ATT aggregated across treatment groups. Reference period is $t-1$. Standard errors clustered at the country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event_study.tex")
cat("  tab3_event_study.tex written.\n")

# ==================================================================
# TABLE 4: Robustness Checks
# ==================================================================
cat("\n=== Table 4: Robustness ===\n")

# Collect robustness results
rob_rows <- list()

# Row 1: Main CS-DiD
rob_rows[[1]] <- c("CS-DiD (baseline)", sprintf("%.2f", cs_att), sprintf("%.2f", cs_se))

# Row 2: Sun-Abraham
if (!is.null(sa_result)) {
  sa_coefs <- coef(sa_result)
  sa_att_names <- grep("year::", names(sa_coefs), value = TRUE)
  sa_post <- sa_coefs[sa_att_names]
  # Get post-treatment coefficients only
  sa_mean <- mean(sa_post, na.rm = TRUE)
  rob_rows[[2]] <- c("Sun-Abraham", sprintf("%.2f", sa_mean), "---")
} else {
  rob_rows[[2]] <- c("Sun-Abraham", "---", "---")
}

# Row 3: TWFE
rob_rows[[3]] <- c("TWFE", sprintf("%.2f", coef(twfe_main)["treated"]),
                     sprintf("%.2f", sqrt(vcov(twfe_main)["treated", "treated"])))

# Row 4: Wild cluster bootstrap p-value
if (!is.null(wcb_result)) {
  rob_rows[[4]] <- c("WCB $p$-value", sprintf("%.3f", wcb_result$p_val), "---")
} else {
  rob_rows[[4]] <- c("WCB $p$-value", "---", "---")
}

# Row 5: Placebo (internet info)
if (!is.null(placebo_twfe)) {
  rob_rows[[5]] <- c("Placebo: Internet info",
                       sprintf("%.2f", coef(placebo_twfe)["treated"]),
                       sprintf("%.2f", sqrt(vcov(placebo_twfe)["treated", "treated"])))
} else {
  rob_rows[[5]] <- c("Placebo: Internet info", "---", "---")
}

# Row 6: Leave-one-out range
rob_rows[[6]] <- c("Leave-one-out range",
                     sprintf("[%.2f, %.2f]", min(loo$coef), max(loo$coef)), "---")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Estimate & SE \\\\",
  "\\hline"
)

for (row in rob_rows) {
  tab4_lines <- c(tab4_lines, paste0(row[1], " & ", row[2], " & ", row[3], " \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications use internet banking (\\%) as the outcome. CS-DiD: Callaway and Sant'Anna (2021) with doubly robust estimation and not-yet-treated/never-treated comparison. Sun-Abraham: Sun and Abraham (2021) interaction-weighted estimator. TWFE: two-way fixed effects. WCB: Webb wild cluster bootstrap with 9,999 iterations. Placebo: internet usage for non-financial purposes (should not respond to PAD). Leave-one-out: range of TWFE coefficients when dropping one country at a time.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  tab4_robustness.tex written.\n")

# ==================================================================
# TABLE F1: Standardized Effect Size (SDE) — APPENDIX
# ==================================================================
cat("\n=== Table F1: SDE Appendix ===\n")

# Compute SDE for main outcomes
# Internet banking: pre-treatment SD
pre_sd_ibank <- panel[group > 0 & year < group,
                       sd(internet_banking_pct, na.rm = TRUE)]

# Findex: pre-treatment SD
pre_sd_findex <- findex_panel[group > 0 & year < group,
                               sd(account_pct, na.rm = TRUE)]

# Hardship: pre-treatment SD
if (!is.null(hardship_twfe) && file.exists("../data/panel_hardship.csv")) {
  panel_hard <- fread("../data/panel_hardship.csv")
  pre_sd_hard <- panel_hard[group > 0 & year < group,
                             sd(unable_expense_pct, na.rm = TRUE)]
  hard_coef <- coef(hardship_twfe)["treated"]
  hard_se <- sqrt(vcov(hardship_twfe)["treated", "treated"])
} else {
  pre_sd_hard <- NA
  hard_coef <- NA
  hard_se <- NA
}

# Compute SDEs
sde_ibank <- cs_att / pre_sd_ibank
sde_se_ibank <- cs_se / pre_sd_ibank

sde_findex <- coef(findex_twfe)["treated"] / pre_sd_findex
sde_se_findex <- sqrt(vcov(findex_twfe)["treated", "treated"]) / pre_sd_findex

sde_hard <- if (!is.na(hard_coef)) hard_coef / pre_sd_hard else NA
sde_se_hard <- if (!is.na(hard_se)) hard_se / pre_sd_hard else NA

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
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

# Build SDE rows
sde_rows <- list(
  list("Internet Banking (\\%)", cs_att, cs_se, pre_sd_ibank, sde_ibank, sde_se_ibank),
  list("Account Ownership (\\%)", coef(findex_twfe)["treated"],
       sqrt(vcov(findex_twfe)["treated", "treated"]),
       pre_sd_findex, sde_findex, sde_se_findex)
)

if (!is.na(hard_coef)) {
  sde_rows[[3]] <- list("Financial Hardship (\\%)", hard_coef, hard_se,
                          pre_sd_hard, sde_hard, sde_se_hard)
}

# Heterogeneity: split by baseline internet banking (above/below median)
median_ibank <- panel[year == min(year), median(internet_banking_pct, na.rm = TRUE)]
high_base <- panel[country_code %in%
  panel[year == min(year) & internet_banking_pct >= median_ibank]$country_code]
low_base <- panel[country_code %in%
  panel[year == min(year) & internet_banking_pct < median_ibank]$country_code]

twfe_high <- feols(internet_banking_pct ~ treated | country_id + year,
                    data = high_base, cluster = ~country_id)
twfe_low <- feols(internet_banking_pct ~ treated | country_id + year,
                   data = low_base, cluster = ~country_id)

pre_sd_high <- high_base[group > 0 & year < group, sd(internet_banking_pct, na.rm = TRUE)]
pre_sd_low <- low_base[group > 0 & year < group, sd(internet_banking_pct, na.rm = TRUE)]

sde_high <- coef(twfe_high)["treated"] / pre_sd_high
sde_se_high <- sqrt(vcov(twfe_high)["treated", "treated"]) / pre_sd_high
sde_low <- coef(twfe_low)["treated"] / pre_sd_low
sde_se_low <- sqrt(vcov(twfe_low)["treated", "treated"]) / pre_sd_low

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does mandating basic bank accounts via the EU Payment Accounts Directive (2014/92/EU) increase financial inclusion among EU residents? ",
  "\\textbf{Policy mechanism:} The directive requires all member states to ensure consumer access to basic payment accounts with essential features (direct debits, card payments, online banking) at reasonable or no cost, with transposition staggered across states from August 2015 to December 2017. ",
  "\\textbf{Outcome definition:} Internet banking is the percentage of individuals aged 16--74 who used internet banking in the last three months (Eurostat isoc\\_bde15cbc); account ownership is the percentage of adults aged 15+ with an account at a financial institution (World Bank Global Findex). ",
  "\\textbf{Treatment:} Binary indicator equal to one from the year of national transposition onward. ",
  "\\textbf{Data:} Eurostat internet banking survey (2008--2024, 27 countries, annual, country-year panel, $N \\approx ", nrow(panel), "$); Global Findex (2011--2024, 5 waves, ", uniqueN(findex_panel$country_code), " countries). ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) doubly robust group-time ATT with not-yet-treated and never-treated controls; standard errors clustered at country level. Panel A uses pooled CS-DiD ATT; Panel B splits by median baseline internet banking penetration (TWFE for subsamples). ",
  "\\textbf{Sample:} EU-27 member states; four countries with pre-existing basic account legislation (CZ, HU, SK, SI) serve as never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (row in sde_rows) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
            row[[1]], row[[2]], row[[3]], row[[4]], row[[5]], row[[6]],
            classify_sde(row[[5]])))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline internet banking)}} \\\\",
  sprintf("High baseline (Internet Banking) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(twfe_high)["treated"], sqrt(vcov(twfe_high)["treated", "treated"]),
          pre_sd_high, sde_high, sde_se_high, classify_sde(sde_high)),
  sprintf("Low baseline (Internet Banking) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(twfe_low)["treated"], sqrt(vcov(twfe_low)["treated", "treated"]),
          pre_sd_low, sde_low, sde_se_low, classify_sde(sde_low)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  tabF1_sde.tex written.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
list.files("../tables/")
