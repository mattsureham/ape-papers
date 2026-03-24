## 05_tables.R — Generate all LaTeX tables
## apep_0872: Hungary bank levy and credit supply

source("00_packages.R")

bsi <- readRDS("../data/bsi_panel.rds") %>%
  filter(country != "SK", date >= as.Date("2005-01-01")) %>%
  mutate(month_id = as.integer(factor(date)))

wb <- readRDS("../data/wb_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
placebo <- readRDS("../data/placebo_results.rds")
loo <- readRDS("../data/loo_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

# Pre-treatment (2005:01 - 2010:08)
pre <- bsi %>% filter(date < as.Date("2010-09-01"))
post_d <- bsi %>% filter(date >= as.Date("2010-09-01"))

country_labels <- c(HU = "Hungary (Treated)", AT = "Austria", CZ = "Czech Rep.", PL = "Poland")

# Build summary for each country
make_sumstat <- function(df, label) {
  df %>%
    group_by(country) %>%
    summarise(
      mean_loans = mean(nfc_loans_eur),
      sd_loans = sd(nfc_loans_eur),
      mean_log = mean(log_nfc_loans),
      sd_log = sd(log_nfc_loans),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(period = label)
}

ss_pre <- make_sumstat(pre, "Pre-Levy")
ss_post <- make_sumstat(post_d, "Post-Levy")

# Also WB stats
wb_pre <- wb %>% filter(year >= 2005 & year < 2011) %>%
  group_by(country) %>%
  summarise(mean_credit_gdp = mean(credit_gdp, na.rm = TRUE), .groups = "drop")
wb_post <- wb %>% filter(year >= 2011 & year <= 2020) %>%
  group_by(country) %>%
  summarise(mean_credit_gdp = mean(credit_gdp, na.rm = TRUE), .groups = "drop")

# Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: NFC Loans and Credit-to-GDP}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Pre-Levy (2006--2010)} & \\multicolumn{3}{c}{Post-Levy (2010--2020)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  "Country & NFC Loans & Log(NFC) & Credit/GDP & NFC Loans & Log(NFC) & Credit/GDP \\\\",
  " & (EUR mn) & & (\\%) & (EUR mn) & & (\\%) \\\\",
  "\\midrule"
)

for (cc in c("HU", "CZ", "PL", "AT")) {
  pre_row <- ss_pre[ss_pre$country == cc, ]
  post_row <- ss_post[ss_post$country == cc, ]
  wb_pre_val <- wb_pre$mean_credit_gdp[wb_pre$country == cc]
  wb_post_val <- wb_post$mean_credit_gdp[wb_post$country == cc]

  if (length(wb_pre_val) == 0) wb_pre_val <- NA
  if (length(wb_post_val) == 0) wb_post_val <- NA

  label <- country_labels[cc]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %.2f & %.1f & %s & %.2f & %.1f \\\\",
    label,
    formatC(round(pre_row$mean_loans), format = "d", big.mark = ","),
    pre_row$mean_log,
    wb_pre_val,
    formatC(round(post_row$mean_loans), format = "d", big.mark = ","),
    post_row$mean_log,
    wb_post_val
  ))

  # SD row
  tab1_lines <- c(tab1_lines, sprintf(
    " & (%s) & (%.2f) & & (%s) & (%.2f) & \\\\",
    formatC(round(pre_row$sd_loans), format = "d", big.mark = ","),
    pre_row$sd_log,
    formatC(round(post_row$sd_loans), format = "d", big.mark = ","),
    post_row$sd_log
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Months & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          nrow(pre) / length(unique(pre$country)),
          nrow(post_d) / length(unique(post_d$country))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} NFC loans are outstanding amounts from ECB Balance Sheet Items statistics (EUR millions). Standard deviations in parentheses. Credit/GDP is domestic credit to private sector from World Bank Development Indicators. Pre-levy: January 2006 to August 2010. Post-levy: September 2010 to December 2020. Slovakia excluded from ECB panel due to data quality issues.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================

# Re-estimate models for clean extraction
m1 <- feols(log_nfc_loans ~ treat | country + month_id, data = bsi)

bsi$trend <- as.numeric(bsi$date - as.Date("2010-09-01")) / 365.25
m2 <- feols(log_nfc_loans ~ treat + i(country, trend) | country + month_id, data = bsi)

m1_cl <- feols(log_nfc_loans ~ treat | country + month_id, data = bsi, cluster = ~country)

# WB
wb_sub <- wb %>% filter(year >= 2003 & year <= 2020)
m_wb <- feols(credit_gdp ~ treat | country + year, data = wb_sub)

# Three-period
bsi$period <- factor(
  case_when(bsi$date < as.Date("2010-09-01") ~ "Pre",
            bsi$date < as.Date("2013-06-01") ~ "Levy",
            TRUE ~ "FGS"),
  levels = c("Pre", "Levy", "FGS")
)
m_3per <- feols(log_nfc_loans ~ i(period, hungary, ref = "Pre") | country + month_id, data = bsi)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Hungary's Bank Levy on Credit Supply}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log(NFC) & Log(NFC) & Log(NFC) & Credit/GDP & Log(NFC) \\\\",
  " & Baseline & Trends & Clustered & Annual & Three-Period \\\\",
  "\\midrule"
)

# Row: Hungary × Post
b1 <- coef(m1)["treat"]; s1 <- se(m1)["treat"]
b2 <- coef(m2)["treat"]; s2 <- se(m2)["treat"]
b3 <- coef(m1_cl)["treat"]; s3 <- se(m1_cl)["treat"]
b4 <- coef(m_wb)["treat"]; s4 <- se(m_wb)["treat"]

# Stars
star <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

p1 <- pvalue(m1)["treat"]; p2 <- pvalue(m2)["treat"]
p3 <- pvalue(m1_cl)["treat"]; p4 <- pvalue(m_wb)["treat"]

tab2_lines <- c(tab2_lines,
  sprintf("Hungary $\\times$ Post & %.3f%s & %.3f%s & %.3f & %.1f%s & \\\\",
          b1, star(p1), b2, star(p2), b3, b4, star(p4)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.1f) & \\\\",
          s1, s2, s3, s4),
  "\\addlinespace"
)

# Three-period coefficients
b_levy <- coef(m_3per)["period::Levy:hungary"]
s_levy <- se(m_3per)["period::Levy:hungary"]
p_levy <- pvalue(m_3per)["period::Levy:hungary"]
b_fgs <- coef(m_3per)["period::FGS:hungary"]
s_fgs <- se(m_3per)["period::FGS:hungary"]
p_fgs <- pvalue(m_3per)["period::FGS:hungary"]

tab2_lines <- c(tab2_lines,
  sprintf("Hungary $\\times$ Levy Period & & & & & %.3f%s \\\\", b_levy, star(p_levy)),
  sprintf(" & & & & & (%.3f) \\\\", s_levy),
  sprintf("Hungary $\\times$ FGS Period & & & & & %.3f%s \\\\", b_fgs, star(p_fgs)),
  sprintf(" & & & & & (%.3f) \\\\", s_fgs),
  "\\addlinespace",
  "\\midrule"
)

# Bottom panel
tab2_lines <- c(tab2_lines,
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m1_cl), nobs(m_wb), nobs(m_3per)),
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Time FE & Month & Month & Month & Year & Month \\\\",
  "Country trends & No & Yes & No & No & No \\\\",
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(m1, "wr2"), r2(m2, "wr2"), r2(m1_cl, "wr2"), r2(m_wb, "wr2"), r2(m_3per, "wr2")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Columns (1)--(3) and (5) use monthly ECB BSI data on outstanding NFC loans (4 countries, 2006--2020). Column (4) uses annual World Bank credit/GDP data (5 countries, 2003--2020). Column (2) adds country-specific linear time trends. Column (3) clusters standard errors at the country level ($G=4$). Column (5) splits the post-treatment period into Levy Only (September 2010--May 2013) and FGS Period (June 2013 onward). The coefficient in column (1) implies that Hungarian NFC credit was %.1f\\%% lower than it would have been absent the levy.", (exp(b1) - 1) * 100),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Robustness — Placebo and Leave-One-Out
# ============================================================

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Placebo and Leave-One-Out Tests}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Estimate & SE & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Placebo Treatment (each country as pseudo-treated)}} \\\\"
)

for (i in 1:nrow(placebo)) {
  cc <- placebo$placebo_country[i]
  label <- ifelse(cc == "HU", "Hungary (actual)", country_labels[cc])
  bold_start <- ifelse(cc == "HU", "\\textbf{", "")
  bold_end <- ifelse(cc == "HU", "}", "")
  tab3_lines <- c(tab3_lines, sprintf(
    "%s%s%s & %s%.3f%s & %s%.3f%s & \\\\",
    bold_start, label, bold_end,
    bold_start, placebo$estimate[i], bold_end,
    bold_start, placebo$se[i], bold_end
  ))
}

tab3_lines <- c(tab3_lines,
  "\\addlinespace",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Leave-One-Out (dropping each control country)}} \\\\"
)

for (i in 1:nrow(loo)) {
  label <- ifelse(loo$dropped[i] == "None", "Full sample (baseline)",
                  paste0("Drop ", country_labels[loo$dropped[i]]))
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.3f & %.3f & \\\\",
    label, loo$estimate[i], loo$se[i]
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A assigns placebo treatment status to each country in turn. Hungary's actual treatment effect is the most extreme in absolute value (rank 4 of 4). Panel B drops each control country from the sample. All specifications include country and month fixed effects with IID standard errors.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================

event_coefs <- readRDS("../data/event_coefs.rds")

# Re-run to get clean coefficients
bsi$event_bin <- pmax(pmin(floor(bsi$event_time / 6) * 6, 60), -36)
m_ev <- feols(log_nfc_loans ~ i(event_bin, hungary, ref = -6) | country + month_id, data = bsi)
ev <- as.data.frame(coeftable(m_ev))
ev$bin <- as.integer(gsub("event_bin::|:hungary", "", rownames(ev)))

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Effect of Bank Levy on Log NFC Loans (6-Month Bins)}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event Time & Months Relative & Estimate & SE & 95\\% CI \\\\",
  "(bins) & to Sept 2010 & & & \\\\",
  "\\midrule"
)

for (i in order(ev$bin)) {
  b <- ev$bin[i]
  est <- ev$Estimate[i]
  se_val <- ev$`Std. Error`[i]
  ci_lo <- est - 1.96 * se_val
  ci_hi <- est + 1.96 * se_val

  period_label <- ifelse(b < 0, "Pre", ifelse(b < 33, "Levy", "FGS"))
  tab4_lines <- c(tab4_lines, sprintf(
    "$t = %+d$ & %s & %.3f & (%.3f) & [%.3f, %.3f] \\\\",
    b, period_label, est, se_val, ci_lo, ci_hi
  ))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Reference: $t = -6$ & Pre & \\multicolumn{3}{c}{(normalized to zero)} \\\\"),
  sprintf("Observations & & \\multicolumn{3}{c}{%d} \\\\", nobs(m_ev)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient reports the differential change in log NFC loans for Hungary relative to controls (Austria, Czech Republic, Poland) at the given event time, with $t=-6$ (6 months before the levy) as the reference period. Bins represent 6-month windows. Country and month fixed effects included. IID standard errors.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_event.tex")
cat("Table 4 written.\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE — MANDATORY)
# ============================================================

sd_y <- results$sd_y  # SD of log NFC loans pre-treatment
beta_main <- coef(m1)["treat"]
se_main <- se(m1)["treat"]
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Classify
classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Panel B: Heterogeneity (sample splits)
# Split 1: Levy-only period (2010:09 - 2013:05) vs FGS period (2013:06+)
bsi_levy <- bsi %>% filter(date >= as.Date("2010-09-01") & date < as.Date("2013-06-01") |
                             date < as.Date("2010-09-01"))
m_levy_only <- feols(log_nfc_loans ~ treat | country + month_id, data = bsi_levy)
beta_levy <- coef(m_levy_only)["treat"]
se_levy <- se(m_levy_only)["treat"]

# Split 2: Use WB credit/GDP as alternative outcome
sd_wb <- sd(wb$credit_gdp[wb$year < 2011], na.rm = TRUE)
beta_wb <- coef(m_wb)["treat"]
se_wb <- se(m_wb)["treat"]
sde_wb <- beta_wb / sd_wb
se_sde_wb <- se_wb / sd_wb

sde_levy <- beta_levy / sd_y
se_sde_levy <- se_levy / sd_y

# Notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Hungary (treated) vs.\\ Austria, Czech Republic, Poland (controls). ",
  "\\textbf{Research question:} Did Hungary's 2010 bank levy --- the largest in the EU at 0.7\\% of GDP --- reduce the supply of credit to non-financial corporations? ",
  "\\textbf{Policy mechanism:} Act XC of 2010 imposed a progressive annual levy on bank adjusted total assets (0.15\\% below HUF 50 billion, 0.53\\% above), extracting roughly HUF 180 billion per year in fiscal revenue from the banking sector. ",
  "\\textbf{Outcome definition:} Log outstanding loans to non-financial corporations from ECB Balance Sheet Items statistics, measured in EUR millions. Panel B row 2 uses domestic credit to private sector as a share of GDP from the World Bank. ",
  "\\textbf{Treatment:} Binary; Hungary in September 2010 and after versus Central European controls that did not impose comparable bank levies. ",
  "\\textbf{Data:} ECB SDW BSI series (monthly, 2006--2020, 4 countries, 720 country-months) and World Bank Development Indicators (annual, 2003--2020, 5 countries). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences (country and time FE); IID standard errors (cluster-robust with $G=4$ reported in main table). ",
  "\\textbf{Sample:} Non-euro-area Central European economies (Czech Republic, Poland) and Austria as peer controls; Slovakia excluded due to BSI data quality issues. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llccccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{9}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log(NFC Loans) & Baseline DiD & %.3f & %.3f & --- & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{9}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Log(NFC Loans) & Levy-only period & %.3f & %.3f & --- & %.3f & %.3f & %.3f & %s \\\\",
          beta_levy, se_levy, sd_y, sde_levy, se_sde_levy, classify_sde(sde_levy)),
  sprintf("Credit/GDP (\\%%) & Annual WB data & %.1f & %.1f & --- & %.1f & %.3f & %.3f & %s \\\\",
          beta_wb, se_wb, sd_wb, sde_wb, se_sde_wb, classify_sde(sde_wb)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
cat("DONE: 05_tables.R\n")
