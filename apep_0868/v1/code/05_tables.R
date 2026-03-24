## 05_tables.R — Generate all tables for apep_0868
## Grid Isolation and the Economic Costs of Infrastructure Failure
source("00_packages.R")

cat("=== Loading results ===\n")
main_res <- readRDS("../data/main_results.rds")
robust_res <- readRDS("../data/robustness_results.rds")
panel <- fread("../data/analysis_panel_balanced.csv")

###########################################################################
## TABLE 1: Summary Statistics
###########################################################################
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[year <= 2020]

summ_ercot <- pre[ercot == 1, .(
  mean_emp = sprintf("%.0f", mean(emp, na.rm = TRUE)),
  sd_emp = sprintf("[%.0f]", sd(emp, na.rm = TRUE)),
  mean_wage = sprintf("%.0f", mean(avg_wage, na.rm = TRUE)),
  sd_wage = sprintf("[%.0f]", sd(avg_wage, na.rm = TRUE)),
  mean_estabs = sprintf("%.0f", mean(estabs, na.rm = TRUE)),
  sd_estabs = sprintf("[%.0f]", sd(estabs, na.rm = TRUE)),
  n_counties = uniqueN(fips),
  n_obs = .N
)]

summ_nonercot <- pre[ercot == 0, .(
  mean_emp = sprintf("%.0f", mean(emp, na.rm = TRUE)),
  sd_emp = sprintf("[%.0f]", sd(emp, na.rm = TRUE)),
  mean_wage = sprintf("%.0f", mean(avg_wage, na.rm = TRUE)),
  sd_wage = sprintf("[%.0f]", sd(avg_wage, na.rm = TRUE)),
  mean_estabs = sprintf("%.0f", mean(estabs, na.rm = TRUE)),
  sd_estabs = sprintf("[%.0f]", sd(estabs, na.rm = TRUE)),
  n_counties = uniqueN(fips),
  n_obs = .N
)]

tab1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (2018--2020)}
\\label{tab:summary}
\\begin{tabular}{lcc}
\\hline\\hline
 & ERCOT & Non-ERCOT \\\\
 & (1) & (2) \\\\
\\hline
\\\\[-6pt]
\\multicolumn{3}{l}{\\textit{Panel A: Employment}} \\\\[3pt]
Private sector employment & ", summ_ercot$mean_emp, " & ", summ_nonercot$mean_emp, " \\\\
 & ", summ_ercot$sd_emp, " & ", summ_nonercot$sd_emp, " \\\\[6pt]
Average weekly wage (\\$) & ", summ_ercot$mean_wage, " & ", summ_nonercot$mean_wage, " \\\\
 & ", summ_ercot$sd_wage, " & ", summ_nonercot$sd_wage, " \\\\[6pt]
Establishments & ", summ_ercot$mean_estabs, " & ", summ_nonercot$mean_estabs, " \\\\
 & ", summ_ercot$sd_estabs, " & ", summ_nonercot$sd_estabs, " \\\\[6pt]
\\\\[-6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Sample}} \\\\[3pt]
Counties & ", summ_ercot$n_counties, " & ", summ_nonercot$n_counties, " \\\\
County-quarter observations & ", summ_ercot$n_obs, " & ", summ_nonercot$n_obs, " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Standard deviations in brackets. Statistics computed over Q1 2018--Q4 2020 (pre-treatment period). ERCOT counties are served by the Electric Reliability Council of Texas, which is electrically isolated from the national grid. Non-ERCOT counties are served by SPP, MISO, or WECC interconnections. Employment data from BLS Quarterly Census of Employment and Wages, private sector (ownership code 5).
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1, "../tables/tab1_summary.tex")

###########################################################################
## TABLE 2: Main DiD Results
###########################################################################
cat("=== Table 2: Main DiD Results ===\n")

# Re-run models for clean extraction
panel[, county := as.factor(fips)]
panel[, quarter_fe := as.factor(paste0(year, "Q", quarter))]
panel[, trend := time_id]

# Baseline
m1 <- feols(log_emp ~ treat:post | county + quarter_fe,
            data = panel[!is.na(log_emp)], cluster = ~fips)
m2 <- feols(log_wage ~ treat:post | county + quarter_fe,
            data = panel[!is.na(log_wage)], cluster = ~fips)
m3 <- feols(log_estabs ~ treat:post | county + quarter_fe,
            data = panel[!is.na(log_estabs)], cluster = ~fips)

# County trends
m4 <- feols(log_emp ~ treat:post + county:trend | county + quarter_fe,
            data = panel[!is.na(log_emp)], cluster = ~fips)
m5 <- feols(log_wage ~ treat:post + county:trend | county + quarter_fe,
            data = panel[!is.na(log_wage)], cluster = ~fips)
m6 <- feols(log_estabs ~ treat:post + county:trend | county + quarter_fe,
            data = panel[!is.na(log_estabs)], cluster = ~fips)

# Q1 2021 only
panel[, uri_quarter := as.integer(year == 2021 & quarter == 1)]
m7 <- feols(log_emp ~ treat:uri_quarter | county + quarter_fe,
            data = panel[year <= 2021 & !is.na(log_emp)], cluster = ~fips)

get_row <- function(model, coef_name) {
  ct <- coeftable(model)
  idx <- grep(coef_name, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) return(c(NA, NA))
  c(ct[idx, "Estimate"], ct[idx, "Std. Error"])
}

stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

fmt <- function(x, d = 3) {
  if (is.na(x)) return("---")
  sprintf(paste0("%.", d, "f"), x)
}

r1 <- get_row(m1, "treat:post")
r2 <- get_row(m2, "treat:post")
r3 <- get_row(m3, "treat:post")
r4 <- get_row(m4, "treat:post")
r5 <- get_row(m5, "treat:post")
r6 <- get_row(m6, "treat:post")
r7 <- get_row(m7, "treat:uri_quarter")

p1 <- coeftable(m1)["treat:post", "Pr(>|t|)"]
p2 <- coeftable(m2)["treat:post", "Pr(>|t|)"]
p3 <- coeftable(m3)["treat:post", "Pr(>|t|)"]
p4 <- coeftable(m4)["treat:post", "Pr(>|t|)"]
p5 <- coeftable(m5)["treat:post", "Pr(>|t|)"]
p6 <- coeftable(m6)["treat:post", "Pr(>|t|)"]
p7 <- coeftable(m7)["treat:uri_quarter", "Pr(>|t|)"]

tab2 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Effect of Grid Isolation on County-Level Economic Outcomes}
\\label{tab:main_did}
\\begin{tabular}{lccc}
\\hline\\hline
 & Log Employment & Log Avg Weekly Wage & Log Establishments \\\\
 & (1) & (2) & (3) \\\\
\\hline
\\\\[-6pt]
\\multicolumn{4}{l}{\\textit{Panel A: Baseline (County + Quarter FE)}} \\\\[3pt]
ERCOT $\\times$ Post & ", fmt(r1[1]), stars(p1), " & ", fmt(r2[1]), stars(p2), " & ", fmt(r3[1]), stars(p3), " \\\\
 & (", fmt(r1[2]), ") & (", fmt(r2[2]), ") & (", fmt(r3[2]), ") \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: County-Specific Linear Trends}} \\\\[3pt]
ERCOT $\\times$ Post & ", fmt(r4[1]), stars(p4), " & ", fmt(r5[1]), stars(p5), " & ", fmt(r6[1]), stars(p6), " \\\\
 & (", fmt(r4[2]), ") & (", fmt(r5[2]), ") & (", fmt(r6[2]), ") \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel C: Immediate Impact (Q1 2021 Only)}} \\\\[3pt]
ERCOT $\\times$ Uri Quarter & ", fmt(r7[1]), stars(p7), " & --- & --- \\\\
 & (", fmt(r7[2]), ") & & \\\\[3pt]
\\hline
Observations & ", format(nobs(m1), big.mark = ","), " & ", format(nobs(m2), big.mark = ","), " & ", format(nobs(m3), big.mark = ","), " \\\\
Counties & 253 & 253 & 254 \\\\
ERCOT counties & 213 & 213 & 213 \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Each cell reports the coefficient on the interaction of ERCOT grid membership with a post-February 2021 indicator (Panels A--B) or with a Q1 2021 indicator (Panel C). All specifications include county and year-quarter fixed effects. Standard errors clustered at the county level in parentheses. Panel C restricts the sample to 2018Q1--2021Q4. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab2, "../tables/tab2_main_did.tex")

###########################################################################
## TABLE 3: Event Study Coefficients
###########################################################################
cat("=== Table 3: Event Study ===\n")

es_emp <- feols(log_emp ~ i(event_time, treat, ref = -1) | county + quarter_fe,
                data = panel[!is.na(log_emp)], cluster = ~fips)

es_ct <- as.data.table(coeftable(es_emp), keep.rownames = "term")
es_ct[, event_time := as.integer(gsub("event_time::(-?\\d+):treat", "\\1", term))]
setnames(es_ct, c("term", "beta", "se", "t", "pval", "event_time"))

# Select key quarters for the table
key_times <- c(-12, -8, -4, -2, -1, 0, 1, 2, 4, 8, 11)
es_tab <- es_ct[event_time %in% key_times]
# Add the reference period
es_tab <- rbind(es_tab,
  data.table(term = "ref", beta = 0, se = NA, t = NA, pval = NA, event_time = -1),
  fill = TRUE)
es_tab <- es_tab[!duplicated(event_time)]
setorder(es_tab, event_time)

# Map event times to calendar quarters
qtr_labels <- c(
  "-12" = "2018Q1", "-8" = "2019Q1", "-4" = "2020Q1",
  "-2" = "2020Q3", "-1" = "2020Q4", "0" = "2021Q1",
  "1" = "2021Q2", "2" = "2021Q3", "4" = "2022Q1",
  "8" = "2023Q1", "11" = "2023Q4"
)

tab3_rows <- ""
for (i in 1:nrow(es_tab)) {
  et <- as.character(es_tab$event_time[i])
  qlabel <- ifelse(et %in% names(qtr_labels), qtr_labels[et], paste0("t", et))
  if (es_tab$event_time[i] == -1) {
    tab3_rows <- paste0(tab3_rows,
      qlabel, " & $k = ", et, "$ & [Reference] & \\\\[3pt]\n")
  } else {
    tab3_rows <- paste0(tab3_rows,
      qlabel, " & $k = ", et, "$ & ", fmt(es_tab$beta[i]),
      stars(es_tab$pval[i]),
      " & (", fmt(es_tab$se[i]), ") \\\\[3pt]\n")
  }
}

tab3 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Event Study: Log Employment Response to Grid Isolation}
\\label{tab:event_study}
\\begin{tabular}{llcc}
\\hline\\hline
Calendar Quarter & Event Time & Coefficient & Std. Error \\\\
\\hline
\\\\[-6pt]
\\multicolumn{4}{l}{\\textit{Pre-treatment}} \\\\[3pt]
", paste(tab3_rows, collapse = ""),
"\\hline
County FE & & \\multicolumn{2}{c}{Yes} \\\\
Quarter FE & & \\multicolumn{2}{c}{Yes} \\\\
Observations & & \\multicolumn{2}{c}{", format(nobs(es_emp), big.mark = ","), "} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Coefficients from an event study regression of log private-sector employment on interactions of ERCOT grid membership with event-time indicators, relative to 2020Q4 ($k=-1$). The Uri storm occurred in February 2021 ($k=0$). Standard errors clustered at the county level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab3, "../tables/tab3_event_study.tex")

###########################################################################
## TABLE 4: Robustness
###########################################################################
cat("=== Table 4: Robustness ===\n")

# Size-matched sample
pre_emp <- panel[year == 2019, .(pre_emp = mean(emp, na.rm = TRUE)), by = fips]
panel2 <- merge(panel, pre_emp, by = "fips", all.x = TRUE)
non_ercot_range <- panel2[ercot == 0 & year == 2019,
                          .(lo = quantile(emp, 0.05, na.rm = TRUE),
                            hi = quantile(emp, 0.95, na.rm = TRUE))]
panel_matched <- panel2[pre_emp >= non_ercot_range$lo & pre_emp <= non_ercot_range$hi]

metro_fips <- c("48201", "48113", "48439", "48029", "48453",
                "48141", "48085", "48121", "48157", "48491",
                "48215", "48303")
panel_rural <- panel[!fips %in% metro_fips]

mr1 <- feols(log_emp ~ treat:post | county + quarter_fe,
             data = panel_matched[!is.na(log_emp)], cluster = ~fips)
mr2 <- feols(log_emp ~ treat:post | county + quarter_fe,
             data = panel_rural[!is.na(log_emp)], cluster = ~fips)
# Re-run baseline and trends for consistent extraction
mr3 <- m1  # baseline
mr4 <- m4  # county trends

rr1 <- get_row(mr1, "treat:post")
rr2 <- get_row(mr2, "treat:post")
rr3 <- get_row(mr3, "treat:post")
rr4 <- get_row(mr4, "treat:post")
pp1 <- coeftable(mr1)["treat:post", "Pr(>|t|)"]
pp2 <- coeftable(mr2)["treat:post", "Pr(>|t|)"]
pp3 <- coeftable(mr3)["treat:post", "Pr(>|t|)"]
pp4 <- coeftable(mr4)["treat:post", "Pr(>|t|)"]

tab4 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Robustness: Alternative Samples and Specifications}
\\label{tab:robustness}
\\begin{tabular}{lcccc}
\\hline\\hline
 & Baseline & County Trends & Rural Only & Size-Matched \\\\
 & (1) & (2) & (3) & (4) \\\\
\\hline
\\\\[-6pt]
ERCOT $\\times$ Post & ", fmt(rr3[1]), stars(pp3), " & ", fmt(rr4[1]), stars(pp4),
" & ", fmt(rr2[1]), stars(pp2), " & ", fmt(rr1[1]), stars(pp1), " \\\\
 & (", fmt(rr3[2]), ") & (", fmt(rr4[2]), ") & (", fmt(rr2[2]), ") & (", fmt(rr1[2]), ") \\\\[6pt]
\\hline
County FE & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes \\\\
County $\\times$ Trend & No & Yes & No & No \\\\
Exclude metros & No & No & Yes & No \\\\
Counties & 253 & 253 & 241 & 216 \\\\
Observations & ", format(nobs(mr3), big.mark=","), " & ", format(nobs(mr4), big.mark=","),
" & ", format(nobs(mr2), big.mark=","), " & ", format(nobs(mr1), big.mark=","), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Dependent variable is log private-sector employment in all columns. Column (1) is the baseline specification. Column (2) adds county-specific linear time trends. Column (3) excludes the 12 largest metro counties. Column (4) restricts ERCOT counties to those within the 5th--95th percentile of non-ERCOT county pre-treatment employment. Standard errors clustered at the county level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab4, "../tables/tab4_robustness.tex")

###########################################################################
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
###########################################################################
cat("=== Table F1: Standardized Effect Size ===\n")

sd_pre <- main_res$sd_pre

# Compute SDE for main outcomes (from county-trend specification — preferred)
sde_emp_beta <- coef(m4)["treat:post"]
sde_emp_se <- coeftable(m4)["treat:post", "Std. Error"]
sde_emp <- sde_emp_beta / sd_pre$emp
sde_emp_se_ratio <- sde_emp_se / sd_pre$emp

sde_wage_beta <- coef(m5)["treat:post"]
sde_wage_se <- coeftable(m5)["treat:post", "Std. Error"]
sde_wage <- sde_wage_beta / sd_pre$wage
sde_wage_se_ratio <- sde_wage_se / sd_pre$wage

sde_estabs_beta <- coef(m6)["treat:post"]
sde_estabs_se <- coeftable(m6)["treat:post", "Std. Error"]
sde_estabs <- sde_estabs_beta / sd_pre$estabs
sde_estabs_se_ratio <- sde_estabs_se / sd_pre$estabs

# Immediate impact SDE
sde_imm_beta <- coef(m7)["treat:uri_quarter"]
sde_imm_se <- coeftable(m7)["treat:uri_quarter", "Std. Error"]
sd_emp_pre_imm <- sd(panel[year <= 2020 & !is.na(log_emp), log_emp])
sde_imm <- sde_imm_beta / sd_emp_pre_imm
sde_imm_se_ratio <- sde_imm_se / sd_emp_pre_imm

# Rural subsample SDE (heterogeneity: rural vs all)
metro_fips <- c("48201", "48113", "48439", "48029", "48453",
                "48141", "48085", "48121", "48157", "48491",
                "48215", "48303")
panel_rural_sde <- panel[!fips %in% metro_fips]
panel_rural_sde[, county := as.factor(fips)]
panel_rural_sde[, quarter_fe := as.factor(paste0(year, "Q", quarter))]
panel_rural_sde[, trend := time_id]
m_rural_trend <- feols(log_emp ~ treat:post + county:trend | county + quarter_fe,
                       data = panel_rural_sde[!is.na(log_emp)], cluster = ~fips)
sde_rural_beta <- coef(m_rural_trend)["treat:post"]
sde_rural_se <- coeftable(m_rural_trend)["treat:post", "Std. Error"]
sd_rural_pre <- sd(panel_rural_sde[year <= 2020 & !is.na(log_emp), log_emp])
sde_rural <- sde_rural_beta / sd_rural_pre
sde_rural_se_ratio <- sde_rural_se / sd_rural_pre

classify_sde <- function(x) {
  if (is.na(x)) return("---")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small positive")
  if (x < 0.15) return("Moderate positive")
  return("Large positive")
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} United States. ",
  "\\\\textbf{Research question:} Does electrical grid isolation from the national interconnection impose economic costs when extreme weather causes infrastructure failure, as measured by county-level employment, wages, and business establishments? ",
  "\\\\textbf{Policy mechanism:} ERCOT operates Texas's isolated electrical grid, disconnected from national interconnections to avoid federal regulation; during Winter Storm Uri (February 2021), this isolation prevented power imports during cascading generator failures, causing 4.5 million customers to lose electricity for up to 5 days. ",
  "\\\\textbf{Outcome definition:} Log quarterly private-sector employment from BLS QCEW (ownership code 5), measuring average of three monthly employment levels per quarter. ",
  "\\\\textbf{Treatment:} Binary --- county served by ERCOT (isolated grid) vs.\\\\ SPP/MISO/WECC (nationally connected grids). ",
  "\\\\textbf{Data:} BLS Quarterly Census of Employment and Wages, 254 Texas counties, Q1 2018--Q4 2023, 6,096 county-quarter observations. ",
  "\\\\textbf{Method:} Two-way fixed effects DiD with county and year-quarter fixed effects, county-specific linear trends (preferred specification); standard errors clustered at the county level. ",
  "\\\\textbf{Sample:} All 254 Texas counties with non-suppressed QCEW data; 213 ERCOT, 41 non-ERCOT (26 SPP, 13 MISO, 2 WECC). ",
  "SDE $= \\\\hat{\\\\beta} / \\\\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the log outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes: Grid Isolation and Economic Outcomes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\\\[-6pt]
\\multicolumn{7}{l}{\\textit{Panel A: Pooled (County-Trend Specification)}} \\\\[3pt]
Log employment & ", fmt(sde_emp_beta, 4), " & ", fmt(sde_emp_se, 4),
" & ", fmt(sd_pre$emp, 4),
" & ", fmt(sde_emp, 4),
" & ", fmt(sde_emp_se_ratio, 4),
" & ", classify_sde(sde_emp), " \\\\
Log avg weekly wage & ", fmt(sde_wage_beta, 4), " & ", fmt(sde_wage_se, 4),
" & ", fmt(sd_pre$wage, 4),
" & ", fmt(sde_wage, 4),
" & ", fmt(sde_wage_se_ratio, 4),
" & ", classify_sde(sde_wage), " \\\\
Log establishments & ", fmt(sde_estabs_beta, 4), " & ", fmt(sde_estabs_se, 4),
" & ", fmt(sd_pre$estabs, 4),
" & ", fmt(sde_estabs, 4),
" & ", fmt(sde_estabs_se_ratio, 4),
" & ", classify_sde(sde_estabs), " \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\[3pt]
Log emp (Q1 2021 only) & ", fmt(sde_imm_beta, 4), " & ", fmt(sde_imm_se, 4),
" & ", fmt(sd_emp_pre_imm, 4),
" & ", fmt(sde_imm, 4),
" & ", fmt(sde_imm_se_ratio, 4),
" & ", classify_sde(sde_imm), " \\\\
Log emp (rural only) & ", fmt(sde_rural_beta, 4), " & ", fmt(sde_rural_se, 4),
" & ", fmt(sd_rural_pre, 4),
" & ", fmt(sde_rural, 4),
" & ", fmt(sde_rural_se_ratio, 4),
" & ", classify_sde(sde_rural), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\small
", sde_notes, "
\\end{tablenotes}
\\end{table}\n")

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
cat(sprintf("SDE employment (county trends): %.4f (%s)\n",
    sde_emp, classify_sde(sde_emp)))
cat(sprintf("SDE wage (county trends): %.4f (%s)\n",
    sde_wage, classify_sde(sde_wage)))
cat(sprintf("SDE establishments (county trends): %.4f (%s)\n",
    sde_estabs, classify_sde(sde_estabs)))
cat(sprintf("SDE immediate impact: %.4f (%s)\n",
    sde_imm, classify_sde(sde_imm)))
