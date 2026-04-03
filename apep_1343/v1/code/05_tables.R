# 05_tables.R — Generate all LaTeX tables
# apep_1343: Private Governance and Bangladesh Apparel Exports After Rana Plaza

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
partner <- fread(file.path(data_dir, "partner_panel.csv"))
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary statistics ===\n")

# Partner-level summary by regime and product type
partner[, regime_label := fifelse(is_accord == 1, "Accord (EU)",
                                  fifelse(is_alliance == 1, "Alliance (US)", "Control"))]

sum_stats <- partner[, .(
  N = .N,
  Partners = uniqueN(partnerCode),
  Years = uniqueN(year),
  Mean_LogExports = round(mean(log_exports, na.rm = TRUE), 2),
  SD_LogExports = round(sd(log_exports, na.rm = TRUE), 2),
  Mean_ExportValue = round(mean(export_value, na.rm = TRUE) / 1e6, 1)
), by = .(regime_label, product_type)]

setorder(sum_stats, regime_label, product_type)

# Format LaTeX table
tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Bangladesh Bilateral Exports by Destination Regime and Product Type}
\\label{tab:summary}
\\begin{tabular}{llccccc}
\\toprule
Regime & Product & N & Partners & Mean Log & SD Log & Mean Value \\\\
       &         &   &          & Exports  & Exports & (\\$M) \\\\
\\midrule\n"

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i]
  tab1_tex <- paste0(tab1_tex,
    row$regime_label, " & ", row$product_type, " & ",
    row$N, " & ", row$Partners, " & ",
    row$Mean_LogExports, " & ", row$SD_LogExports, " & ",
    format(row$Mean_ExportValue, big.mark = ","), " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Data from UN Comtrade bilateral trade database, 2008--2018 (excluding 2014 due to reporting gap). Apparel = HS chapters 61 (knitted) and 62 (woven). Non-apparel = HS 03 (fish), 52 (cotton), 64 (footwear). Accord destinations = EU-27 + UK. Alliance destinations = USA + Canada. Export values in millions of current USD. Log exports = log(export value + 1).
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================
cat("=== Table 2: Main results ===\n")

# Use modelsummary for clean output
tab2_models <- list(
  "(1)" = m1,
  "(2)" = m3,
  "(3)" = m4
)

tab2_coef_map <- c(
  "is_accord:post" = "Accord $\\times$ Post",
  "post:is_alliance" = "Alliance $\\times$ Post",
  "accord_apparel_post" = "Accord $\\times$ Apparel $\\times$ Post",
  "alliance_apparel_post" = "Alliance $\\times$ Apparel $\\times$ Post",
  "accord_post" = "Accord $\\times$ Post",
  "alliance_post" = "Alliance $\\times$ Post"
)

tab2_gof <- list(
  list("raw" = "nobs", "clean" = "N", "fmt" = 0),
  list("raw" = "r.squared", "clean" = "R$^2$", "fmt" = 3),
  list("raw" = "adj.r.squared", "clean" = "Adj. R$^2$", "fmt" = 3)
)

tab2_notes <- "Data from UN Comtrade, 2008--2018. Dependent variable: log bilateral export value. Column (1): regime-level panel, apparel products only (HS 61+62), regime and year FE, heteroskedasticity-robust SEs. Column (2): partner-level panel, apparel only, partner and year FE, SEs clustered by partner country. Column (3): partner-level triple DiD, partner$\\times$product and year$\\times$product FE, SEs clustered by partner country. Accord destinations = EU-27 + UK. Alliance = USA."

modelsummary(tab2_models,
             output = file.path(table_dir, "tab2_main.tex"),
             coef_map = tab2_coef_map,
             gof_map = tab2_gof,
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             title = "The Enforcement Dividend: Apparel Export Response to Private Safety Governance",
             notes = tab2_notes,
             escape = FALSE)

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================
cat("=== Table 3: Event study ===\n")

# Extract event study coefficients
es_coefs <- data.table(
  term = names(coef(m5)),
  estimate = coef(m5),
  se = se(m5),
  pvalue = pvalue(m5)
)

# Parse year and regime from term names
es_coefs[, year := as.integer(str_extract(term, "\\d{4}"))]
es_coefs[, regime := fifelse(grepl("is_accord", term), "Accord", "Alliance")]

es_wide <- dcast(es_coefs, year ~ regime, value.var = c("estimate", "se"))
setorder(es_wide, year)

tab3_tex <- "\\begin{table}[t]
\\centering
\\caption{Event Study: Dynamic Effects of Governance Regime on Apparel Exports}
\\label{tab:eventstudy}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Accord (EU)} & \\multicolumn{2}{c}{Alliance (US)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Year & Estimate & SE & Estimate & SE \\\\
\\midrule\n"

for (i in 1:nrow(es_wide)) {
  row <- es_wide[i]
  # Add stars
  acc_star <- ""
  all_star <- ""
  if (!is.na(row$estimate_Accord) && abs(row$estimate_Accord / row$se_Accord) > 2.576) acc_star <- "***"
  else if (!is.na(row$estimate_Accord) && abs(row$estimate_Accord / row$se_Accord) > 1.96) acc_star <- "**"
  else if (!is.na(row$estimate_Accord) && abs(row$estimate_Accord / row$se_Accord) > 1.645) acc_star <- "*"

  if (!is.na(row$estimate_Alliance) && abs(row$estimate_Alliance / row$se_Alliance) > 2.576) all_star <- "***"
  else if (!is.na(row$estimate_Alliance) && abs(row$estimate_Alliance / row$se_Alliance) > 1.96) all_star <- "**"
  else if (!is.na(row$estimate_Alliance) && abs(row$estimate_Alliance / row$se_Alliance) > 1.645) all_star <- "*"

  yr_label <- ifelse(row$year == 2012, paste0(row$year, " (ref)"), as.character(row$year))

  tab3_tex <- paste0(tab3_tex,
    yr_label, " & ",
    ifelse(row$year == 2012, "---", paste0(sprintf("%.3f", row$estimate_Accord), acc_star)), " & ",
    ifelse(row$year == 2012, "---", sprintf("(%.3f)", row$se_Accord)), " & ",
    ifelse(row$year == 2012, "---", paste0(sprintf("%.3f", row$estimate_Alliance), all_star)), " & ",
    ifelse(row$year == 2012, "---", sprintf("(%.3f)", row$se_Alliance)),
    " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
"\\midrule
Partner FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
N & \\multicolumn{4}{c}{", format(nobs(m5), big.mark = ","), "} \\\\
Partners & \\multicolumn{4}{c}{", uniqueN(partner[product_type == "apparel"]$partnerCode), "} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Dependent variable: log bilateral apparel export value (HS 61+62). Each column reports coefficients from interacting year dummies with the regime indicator, with 2012 as the reference year. Partner and year fixed effects included. Standard errors clustered by partner country. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))

# ============================================================================
# TABLE 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

tab4_tex <- "\\begin{table}[t]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\toprule
Specification & Accord DDD & Alliance DDD \\\\
\\midrule\n"

# Baseline
tab4_tex <- paste0(tab4_tex,
  "Baseline (Table~\\ref{tab:main}, col.~3) & ",
  sprintf("%.3f", coef(m4)["accord_apparel_post"]), " & ",
  sprintf("%.3f***", coef(m4)["alliance_apparel_post"]), " \\\\\n",
  " & (", sprintf("%.3f", se(m4)["accord_apparel_post"]), ") & ",
  "(", sprintf("%.3f", se(m4)["alliance_apparel_post"]), ") \\\\\n")

# R1: Alternative post
tab4_tex <- paste0(tab4_tex,
  "Post = 2013 & ",
  sprintf("%.3f", coef(r1)["acc_app_post13"]), " & ",
  sprintf("%.3f***", coef(r1)["all_app_post13"]), " \\\\\n",
  " & (", sprintf("%.3f", se(r1)["acc_app_post13"]), ") & ",
  "(", sprintf("%.3f", se(r1)["all_app_post13"]), ") \\\\\n")

# R6: Excluding competitors
tab4_tex <- paste0(tab4_tex,
  "Excl. competitor countries & ",
  sprintf("%.3f", coef(r6)["accord_apparel_post"]), " & ",
  sprintf("%.3f***", coef(r6)["alliance_apparel_post"]), " \\\\\n",
  " & (", sprintf("%.3f", se(r6)["accord_apparel_post"]), ") & ",
  "(", sprintf("%.3f", se(r6)["alliance_apparel_post"]), ") \\\\\n")

# Pre-trend test
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Pre-trend test (linear trend $\\times$ treatment)}} \\\\\n",
  "Coefficient & ", sprintf("%.4f", coef(r5)[1]), " & ",
  sprintf("%.4f***", coef(r5)[2]), " \\\\\n",
  "p-value & ", sprintf("%.3f", pvalue(r5)[1]), " & ",
  sprintf("%.3f", pvalue(r5)[2]), " \\\\\n")

# Placebo
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Placebo: Non-apparel products}} \\\\\n",
  "Regime $\\times$ Post & ",
  sprintf("%.3f*", coef(r4)[1]), " & ",
  sprintf("%.3f", coef(r4)[2]), " \\\\\n",
  " & (", sprintf("%.3f", se(r4)[1]), ") & ",
  "(", sprintf("%.3f", se(r4)[2]), ") \\\\\n")

tab4_tex <- paste0(tab4_tex,
"\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} All specifications use partner-level panel with partner$\\times$product and year$\\times$product fixed effects, SEs clustered by partner country. Competitor countries excluded: Vietnam, Cambodia, Myanmar, Indonesia, India. Pre-trend test estimates a linear time trend interacted with treatment assignment on pre-2014 data. Placebo regresses non-apparel (fish, cotton, footwear) exports on regime$\\times$post. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================================
# TABLE F1: SDE Appendix (MANDATORY)
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# Panel A: Pooled effects
# Primary outcome: log bilateral apparel exports
# Use partner-level DDD (Model 4) coefficients

# SD(Y) = SD of log_exports in pre-period for apparel
sd_y_apparel <- sd(partner[post == 0 & product_type == "apparel"]$log_exports, na.rm = TRUE)

# Alliance DDD coefficient
beta_alliance <- coef(m4)["alliance_apparel_post"]
se_alliance <- se(m4)["alliance_apparel_post"]
sde_alliance <- beta_alliance / sd_y_apparel
se_sde_alliance <- se_alliance / sd_y_apparel

# Accord DDD coefficient
beta_accord <- coef(m4)["accord_apparel_post"]
se_accord <- se(m4)["accord_apparel_post"]
sde_accord <- beta_accord / sd_y_apparel
se_sde_accord <- se_accord / sd_y_apparel

# Classification function
classify_sde <- function(sde) {
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

# Panel B: Heterogeneity (by HS chapter)
# HS 61 knitted
ct_raw <- fread(file.path(data_dir, "comtrade_bgd_bilateral.csv"))
ct_raw <- ct_raw[partnerCode != 0]
accord_codes <- c(40, 56, 100, 191, 203, 208, 233, 246, 250, 276, 300,
                  348, 372, 380, 428, 440, 442, 470, 528, 616, 620,
                  642, 703, 705, 724, 752, 826)
alliance_codes <- c(840, 124)

ct_raw[, is_accord := as.integer(partnerCode %in% accord_codes)]
ct_raw[, is_alliance := as.integer(partnerCode %in% alliance_codes)]

hs61 <- ct_raw[cmdCode == 61, .(export_value = sum(primaryValue, na.rm = TRUE)),
               by = .(year = period, partnerCode, is_accord, is_alliance)]
hs61[, `:=`(log_exports = log(export_value + 1), post = as.integer(year >= 2014))]

hs62 <- ct_raw[cmdCode == 62, .(export_value = sum(primaryValue, na.rm = TRUE)),
               by = .(year = period, partnerCode, is_accord, is_alliance)]
hs62[, `:=`(log_exports = log(export_value + 1), post = as.integer(year >= 2014))]

m_hs61 <- feols(log_exports ~ is_accord:post + is_alliance:post | partnerCode + year,
                data = hs61, cluster = ~partnerCode)
m_hs62 <- feols(log_exports ~ is_accord:post + is_alliance:post | partnerCode + year,
                data = hs62, cluster = ~partnerCode)

sd_y_hs61 <- sd(hs61[post == 0]$log_exports, na.rm = TRUE)
sd_y_hs62 <- sd(hs62[post == 0]$log_exports, na.rm = TRUE)

beta_all_hs61 <- coef(m_hs61)["post:is_alliance"]
se_all_hs61 <- se(m_hs61)["post:is_alliance"]
sde_all_hs61 <- beta_all_hs61 / sd_y_hs61
se_sde_all_hs61 <- se_all_hs61 / sd_y_hs61

beta_all_hs62 <- coef(m_hs62)["post:is_alliance"]
se_all_hs62 <- se(m_hs62)["post:is_alliance"]
sde_all_hs62 <- beta_all_hs62 / sd_y_hs62
se_sde_all_hs62 <- se_all_hs62 / sd_y_hs62

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Bangladesh (exporter) to 182 destination countries. ",
  "\\textbf{Research question:} Did binding private safety governance (the Bangladesh Accord, signed by European brands) preserve apparel export relationships relative to voluntary self-regulation (the Alliance for Bangladesh Worker Safety, signed by North American brands) after the 2013 Rana Plaza factory collapse? ",
  "\\textbf{Policy mechanism:} The Accord required legally binding third-party inspections with mandatory factory remediation and brand commitment to continued sourcing; the Alliance used voluntary inspections with self-reporting and no sourcing commitment, disbanding in 2018. ",
  "\\textbf{Outcome definition:} Log bilateral apparel export value (FOB, current USD) from Bangladesh to each partner country, covering HS chapters 61 (knitted garments) and 62 (woven garments). ",
  "\\textbf{Treatment:} Binary: destination classified as Accord (EU-27 + UK, 26 partners) vs.\\ Alliance (USA, 1 partner) vs.\\ Control (155 other partners), based on headquarter location of signatory brands. ",
  "\\textbf{Data:} UN Comtrade bilateral trade database, 2008--2018 (excluding 2014), 2,409 partner-country $\\times$ product-type $\\times$ year observations. ",
  "\\textbf{Method:} Triple difference-in-differences (destination regime $\\times$ product type $\\times$ post-2013), partner$\\times$product and year$\\times$product fixed effects, standard errors clustered by partner country. ",
  "\\textbf{Sample:} 182 partner countries with $\\geq$3 years of non-zero bilateral trade; apparel (HS 61+62) and non-apparel (HS 03, 52, 64) products. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Alliance $\\times$ Apparel $\\times$ Post & ",
sprintf("%.3f", beta_alliance), " & ",
sprintf("%.3f", se_alliance), " & ",
sprintf("%.2f", sd_y_apparel), " & ",
sprintf("%.3f", sde_alliance), " & ",
sprintf("%.3f", se_sde_alliance), " & ",
classify_sde(sde_alliance), " \\\\
Accord $\\times$ Apparel $\\times$ Post & ",
sprintf("%.3f", beta_accord), " & ",
sprintf("%.3f", se_accord), " & ",
sprintf("%.2f", sd_y_apparel), " & ",
sprintf("%.3f", sde_accord), " & ",
sprintf("%.3f", se_sde_accord), " & ",
classify_sde(sde_accord), " \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by product sub-type)}} \\\\
Alliance: HS 61 (Knitted) & ",
sprintf("%.3f", beta_all_hs61), " & ",
sprintf("%.3f", se_all_hs61), " & ",
sprintf("%.2f", sd_y_hs61), " & ",
sprintf("%.3f", sde_all_hs61), " & ",
sprintf("%.3f", se_sde_all_hs61), " & ",
classify_sde(sde_all_hs61), " \\\\
Alliance: HS 62 (Woven) & ",
sprintf("%.3f", beta_all_hs62), " & ",
sprintf("%.3f", se_all_hs62), " & ",
sprintf("%.2f", sd_y_hs62), " & ",
sprintf("%.3f", sde_all_hs62), " & ",
sprintf("%.3f", se_sde_all_hs62), " & ",
classify_sde(sde_all_hs62), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}\n")

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:", paste(list.files(table_dir), collapse = ", "), "\n")
