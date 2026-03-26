# 05_tables.R — Generate all tables for Poland Sunday Trading Ban paper
# Tables: summary stats, main results, robustness, event study, SDE appendix

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
panel_ext <- readRDS("../data/panel_extended.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Pre-period and post-period stats
pre <- panel %>% filter(year < 2018)
post <- panel %>% filter(year >= 2018)

sum_stats <- tribble(
  ~Variable, ~Mean_Pre, ~SD_Pre, ~Mean_Post, ~SD_Post, ~N,
  "Trade employment (thousands)", mean(pre$emp_trade, na.rm=T), sd(pre$emp_trade, na.rm=T),
    mean(post$emp_trade, na.rm=T), sd(post$emp_trade, na.rm=T), nrow(panel),
  "Total employment (thousands)", mean(pre$emp_total, na.rm=T), sd(pre$emp_total, na.rm=T),
    mean(post$emp_total, na.rm=T), sd(post$emp_total, na.rm=T), nrow(panel),
  "Log trade employment", mean(pre$log_emp_trade, na.rm=T), sd(pre$log_emp_trade, na.rm=T),
    mean(post$log_emp_trade, na.rm=T), sd(post$log_emp_trade, na.rm=T), nrow(panel),
  "Trade share (2017 baseline)", mean(panel$trade_share_2017[!duplicated(panel$geo)], na.rm=T),
    sd(panel$trade_share_2017[!duplicated(panel$geo)], na.rm=T), NA, NA,
    n_distinct(panel$geo),
  "Ban intensity", 0, 0, mean(post$ban_intensity, na.rm=T), sd(post$ban_intensity, na.rm=T),
    nrow(panel),
  "Treatment (share $\\times$ intensity)", 0, 0,
    mean(post$treatment, na.rm=T), sd(post$treatment, na.rm=T), nrow(panel)
)

# Format LaTeX table
tab1_body <- sum_stats %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.), "---", sprintf("%.3f", .))))

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Pre-Ban (2014--2017)} & \\multicolumn{2}{c}{Post-Ban (2018--2019)} & \\\\\n",
  "\\cline{2-3} \\cline{4-5}\n",
  "Variable & Mean & SD & Mean & SD & $N$ \\\\\n",
  "\\hline\n",
  paste(apply(tab1_body, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 73 Polish NUTS-3 regions, 2014--2019 (438 region-years). ",
  "Employment data from Eurostat (\\texttt{nama\\_10r\\_3empers}). ",
  "Trade employment covers NACE Section G--I (wholesale/retail trade, transport, accommodation, food services). ",
  "Trade share is 2017 baseline (pre-reform). Ban intensity reflects the proportion of Sundays closed under each phase ",
  "(Phase~1: 0.42; Phase~2: 0.75). Treatment is the interaction of baseline trade share and ban intensity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main Results — Employment Effects
# ============================================================================

cat("=== Table 2: Main Results ===\n")

# Build table using modelsummary
m1 <- results$m1_continuous
m2 <- results$m2_phase
m4 <- results$m4_total_emp
m5 <- results$m5_total_phase
m6 <- results$m6_cross_country

# Manual LaTeX table for full control
extract_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  list(b = b, s = s, p = p, stars = stars,
       b_str = sprintf("%.4f%s", b, stars),
       se_str = sprintf("(%.4f)", s))
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Sunday Trading Ban on Employment}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Trade Emp. (G--I)} & \\multicolumn{2}{c}{Total Emp.} & Cross-Country \\\\\n",
  "\\cline{2-3} \\cline{4-5} \\cline{6-6}\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  sprintf("Treatment & %s & & %s & & \\\\\n",
          extract_coef(m1, "treatment")$b_str,
          extract_coef(m4, "treatment")$b_str),
  sprintf(" & %s & & %s & & \\\\\n",
          extract_coef(m1, "treatment")$se_str,
          extract_coef(m4, "treatment")$se_str),
  sprintf("Phase 1 $\\times$ Trade Share & & %s & & %s & \\\\\n",
          extract_coef(m2, "treat_phase1")$b_str,
          extract_coef(m5, "treat_phase1")$b_str),
  sprintf(" & & %s & & %s & \\\\\n",
          extract_coef(m2, "treat_phase1")$se_str,
          extract_coef(m5, "treat_phase1")$se_str),
  sprintf("Phase 2 $\\times$ Trade Share & & %s & & %s & \\\\\n",
          extract_coef(m2, "treat_phase2")$b_str,
          extract_coef(m5, "treat_phase2")$b_str),
  sprintf(" & & %s & & %s & \\\\\n",
          extract_coef(m2, "treat_phase2")$se_str,
          extract_coef(m5, "treat_phase2")$se_str),
  sprintf("Poland $\\times$ Post & & & & & %s \\\\\n",
          extract_coef(m6, "treat_x_post")$b_str),
  sprintf(" & & & & & %s \\\\\n",
          extract_coef(m6, "treat_x_post")$se_str),
  "\\hline\n",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
          nobs(m1), nobs(m2), nobs(m4), nobs(m5), nobs(m6)),
  sprintf("Regions & 73 & 73 & 73 & 73 & %d \\\\\n", n_distinct(readRDS("../data/cross_country.rds")$geo)),
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1, "ar2")[[1]], fitstat(m2, "ar2")[[1]],
          fitstat(m4, "ar2")[[1]], fitstat(m5, "ar2")[[1]],
          fitstat(m6, "ar2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log employment. ",
  "Columns (1)--(2) use trade-sector (NACE G--I) employment; (3)--(4) use total employment; ",
  "(5) pools Polish and Czech/Slovak NUTS-3 regions in a standard DiD. ",
  "Treatment in columns (1) and (3) is baseline trade share $\\times$ ban intensity. ",
  "Columns (2) and (4) estimate separate phase effects (Phase~1: March 2018, Phase~2: January 2019). ",
  "Standard errors clustered at NUTS-2 (voivodeship) level in parentheses. ",
  "$^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================================
# Table 3: Event Study (Pre-trend Check)
# ============================================================================

cat("=== Table 3: Event Study ===\n")

m_es <- robust$event_study
es_names <- names(coef(m_es))

tab3_rows <- list()
for (yr in c(2014, 2015, 2016, 2018, 2019)) {
  idx <- grep(as.character(yr), es_names)
  if (length(idx) > 0) {
    r <- extract_coef(m_es, es_names[idx])
    tab3_rows[[as.character(yr)]] <- sprintf(
      "%d & %s \\\\\n & %s \\\\",
      yr, r$b_str, r$se_str)
  }
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Trade Employment}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  "Year $\\times$ Trade Share & Log Trade Emp. \\\\\n",
  "\\hline\n",
  paste(tab3_rows, collapse = "\n"), "\n",
  "\\hline\n",
  "Reference year & 2017 \\\\\n",
  sprintf("Observations & %d \\\\\n", nobs(m_es)),
  "Region FE & Yes \\\\\n",
  "Year FE & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients on Year $\\times$ baseline trade share (2017). ",
  "2017 is the omitted reference year. The Sunday trading ban began in March 2018 (Phase~1) ",
  "and intensified in January 2019 (Phase~2). Pre-period coefficients (2014--2016) test ",
  "for differential pre-trends in high-trade-share regions. ",
  "Standard errors clustered at NUTS-2 level. ",
  "$^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event.tex")
cat("Table 3 written.\n")

# ============================================================================
# Table 4: Placebo Sectors
# ============================================================================

cat("=== Table 4: Placebo Sectors ===\n")

m_trade <- results$m1_continuous
m_ind <- robust$placebo_industry
m_con <- robust$placebo_construction
m_pub <- robust$placebo_public

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Tests: Non-Trade Sectors}\n",
  "\\label{tab:placebo}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Trade (G--I) & Industry (B--E) & Construction (F) & Public (O--Q) \\\\\n",
  "\\cline{2-5}\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Treatment & %s & %s & %s & %s \\\\\n",
          extract_coef(m_trade, "treatment")$b_str,
          ifelse(is.null(m_ind), "---", extract_coef(m_ind, "treatment")$b_str),
          ifelse(is.null(m_con), "---", extract_coef(m_con, "treatment")$b_str),
          ifelse(is.null(m_pub), "---", extract_coef(m_pub, "treatment")$b_str)),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          extract_coef(m_trade, "treatment")$se_str,
          ifelse(is.null(m_ind), "", extract_coef(m_ind, "treatment")$se_str),
          ifelse(is.null(m_con), "", extract_coef(m_con, "treatment")$se_str),
          ifelse(is.null(m_pub), "", extract_coef(m_pub, "treatment")$se_str)),
  "\\hline\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          nobs(m_trade),
          ifelse(is.null(m_ind), 0, nobs(m_ind)),
          ifelse(is.null(m_con), 0, nobs(m_con)),
          ifelse(is.null(m_pub), 0, nobs(m_pub))),
  "Region FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Same specification as Table~\\ref{tab:main}, column (1), ",
  "applied to employment in non-trade sectors. Treatment is baseline trade share ",
  "$\\times$ ban intensity. Industry (B--E), construction (F), and public administration/education/health (O--Q) ",
  "should not respond to the Sunday trading ban. Significant placebo effects indicate ",
  "differential growth trends correlated with baseline trade share. ",
  "$^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_placebo.tex")
cat("Table 4 written.\n")

# ============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("=== Table F1: SDE Appendix ===\n")

# Compute SDEs
diag <- jsonlite::read_json("../data/diagnostics.json")
sd_y_pre <- diag$sd_y_pre
sd_treatment <- diag$sd_treatment

# Main results for SDE
sde_rows <- list()

# 1. Trade employment (continuous treatment)
b1 <- coef(m1)["treatment"]
se1 <- se(m1)["treatment"]
# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde1 <- b1 * sd_treatment / sd_y_pre
se_sde1 <- se1 * sd_treatment / sd_y_pre

# 2. Total employment
b4 <- coef(results$m4_total_emp)["treatment"]
se4 <- se(results$m4_total_emp)["treatment"]
sd_y_total_pre <- sd(panel$log_emp_total[panel$year < 2018], na.rm = TRUE)
sde4 <- b4 * sd_treatment / sd_y_total_pre
se_sde4 <- se4 * sd_treatment / sd_y_total_pre

# 3. Cross-country trade employment
b6 <- coef(results$m6_cross_country)["treat_x_post"]
se6 <- se(results$m6_cross_country)["treat_x_post"]
cc <- readRDS("../data/cross_country.rds") %>% filter(year >= 2014 & year <= 2019)
sd_y_cc <- sd(cc$log_emp_trade[cc$year < 2018], na.rm = TRUE)
sde6 <- b6 / sd_y_cc  # Binary treatment
se_sde6 <- se6 / sd_y_cc

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

# Panel A: Pooled
panel_a_rows <- data.frame(
  Outcome = c("Trade employment (NACE G--I)",
              "Total employment",
              "Trade employment (cross-country)"),
  beta = c(b1, b4, b6),
  SE = c(se1, se4, se6),
  SD_Y = c(sd_y_pre, sd_y_total_pre, sd_y_cc),
  SDE = c(sde1, sde4, sde6),
  SE_SDE = c(se_sde1, se_sde4, se_sde6),
  Classification = c(classify_sde(sde1), classify_sde(sde4), classify_sde(sde6))
)

# Panel B: Heterogeneous (high vs low trade share)
panel_high <- panel %>% filter(high_trade == 1)
panel_low <- panel %>% filter(high_trade == 0)

m_high <- feols(log_emp_trade ~ treatment | geo + year,
                data = panel_high, cluster = ~nuts2)
m_low <- feols(log_emp_trade ~ treatment | geo + year,
               data = panel_low, cluster = ~nuts2)

sd_y_high <- sd(panel_high$log_emp_trade[panel_high$year < 2018], na.rm = TRUE)
sd_y_low <- sd(panel_low$log_emp_trade[panel_low$year < 2018], na.rm = TRUE)
sd_treat_high <- sd(panel_high$treatment[panel_high$treatment > 0], na.rm = TRUE)
sd_treat_low <- sd(panel_low$treatment[panel_low$treatment > 0], na.rm = TRUE)

b_high <- coef(m_high)["treatment"]
se_high <- se(m_high)["treatment"]
sde_high <- b_high * sd_treat_high / sd_y_high
se_sde_high <- se_high * sd_treat_high / sd_y_high

b_low <- coef(m_low)["treatment"]
se_low <- se(m_low)["treatment"]
sde_low <- b_low * sd_treat_low / sd_y_low
se_sde_low <- se_low * sd_treat_low / sd_y_low

panel_b_rows <- data.frame(
  Outcome = c("Trade emp., high-share regions",
              "Trade emp., low-share regions"),
  beta = c(b_high, b_low),
  SE = c(se_high, se_low),
  SD_Y = c(sd_y_high, sd_y_low),
  SDE = c(sde_high, sde_low),
  SE_SDE = c(se_sde_high, se_sde_low),
  Classification = c(classify_sde(sde_high), classify_sde(sde_low))
)

# Format SDE table
fmt_row <- function(r) {
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
          r$Outcome, r$beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Poland. ",
  "\\textbf{Research question:} Does restricting Sunday retail trading hours reduce trade-sector employment in exposed regions? ",
  "\\textbf{Policy mechanism:} The 2018 Act on Restriction of Trade on Sundays progressively banned Sunday commerce in three phases (2018: two open Sundays per month; 2019: one open Sunday per month; 2020: near-total ban with seven exemptions per year), while e-commerce remained unrestricted throughout. ",
  "\\textbf{Outcome definition:} Log of thousands of employed persons in NACE Section G--I (wholesale and retail trade, transport, accommodation, and food services) from Eurostat regional accounts. ",
  "\\textbf{Treatment:} Continuous; baseline (2017) trade-sector employment share interacted with time-varying ban intensity (proportion of Sundays closed). ",
  "\\textbf{Data:} Eurostat \\texttt{nama\\_10r\\_3empers}, 2014--2019, NUTS-3 regions, 438 region-years; cross-country sample adds Czech and Slovak NUTS-3 regions (570 region-years). ",
  "\\textbf{Method:} Two-way fixed effects (region + year) with continuous treatment; standard errors clustered at NUTS-2 (voivodeship) level (17 clusters). ",
  "\\textbf{Sample:} 73 Polish NUTS-3 regions, restricted to 2014--2019 to avoid COVID-19 confounding of Phase~3 (January 2020). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "$\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, ",
  "where SD($Y$) is the pre-treatment standard deviation. ",
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
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(1:nrow(panel_a_rows), function(i) fmt_row(panel_a_rows[i,])), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline trade share)}} \\\\\n",
  paste(sapply(1:nrow(panel_b_rows), function(i) fmt_row(panel_b_rows[i,])), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
