# 05_tables.R — Generate all tables for apep_1180
# Korea Mandatory English Disclosure paper

source("00_packages.R")

data_dir   <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

weekly  <- fread(file.path(data_dir, "weekly_panel.csv"))
firms   <- fread(file.path(data_dir, "firm_characteristics.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust  <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Summary stats by treatment group
sumstats <- function(dt, varlist, group_label) {
  out <- data.table()
  for (v in varlist) {
    x <- dt[[v]]
    x <- x[!is.na(x) & is.finite(x)]
    out <- rbind(out, data.table(
      Variable = v,
      Group = group_label,
      N = length(x),
      Mean = mean(x),
      SD = sd(x),
      Median = median(x),
      P25 = quantile(x, 0.25),
      P75 = quantile(x, 0.75)
    ))
  }
  return(out)
}

vars <- c("amihud_w", "turnover_w", "abs_ret_w", "close_w", "volume_w")
var_labels <- c("Amihud illiquidity ($\\times 10^3$)",
                "Turnover (daily avg)",
                "Absolute return",
                "Closing price (KRW)",
                "Volume (shares)")

ss_treated <- sumstats(weekly[phase1 == 1], vars, "Phase 1")
ss_control <- sumstats(weekly[phase1 == 0], vars, "Control")
ss_all     <- sumstats(weekly, vars, "All")

# Build LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Weekly Stock Market Outcomes}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Phase 1 (Treated)} & \\multicolumn{3}{c}{Control} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  "Variable & Mean & SD & Median & Mean & SD & Median \\\\"
)
tab1_lines <- c(tab1_lines, "\\midrule")

for (i in seq_along(vars)) {
  t_row <- ss_treated[Variable == vars[i]]
  c_row <- ss_control[Variable == vars[i]]

  # Format numbers
  fmt <- function(x, digits = 4) formatC(x, format = "f", digits = digits, big.mark = ",")

  if (vars[i] %in% c("close_w", "volume_w")) {
    digits <- 0
  } else {
    digits <- 4
  }

  line <- paste0(var_labels[i], " & ",
                 fmt(t_row$Mean, digits), " & ",
                 fmt(t_row$SD, digits), " & ",
                 fmt(t_row$Median, digits), " & ",
                 fmt(c_row$Mean, digits), " & ",
                 fmt(c_row$SD, digits), " & ",
                 fmt(c_row$Median, digits), " \\\\")
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  paste0("Firms & \\multicolumn{3}{c}{", uniqueN(weekly[phase1 == 1]$ticker),
         "} & \\multicolumn{3}{c}{", uniqueN(weekly[phase1 == 0]$ticker), "} \\\\"),
  paste0("Firm-weeks & \\multicolumn{3}{c}{",
         formatC(nrow(weekly[phase1 == 1]), big.mark = ","),
         "} & \\multicolumn{3}{c}{",
         formatC(nrow(weekly[phase1 == 0]), big.mark = ","), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Weekly averages of daily stock market outcomes ",
         "for KOSPI firms, January 2022--December 2025. Phase 1 firms have total ",
         "assets $\\geq$ KRW 10 trillion and were mandated to file in English ",
         "from January 2024. Amihud illiquidity is $|r_t|/(\\text{Volume}_t \\times 10^{-9})$. ",
         "Turnover is daily trading volume divided by shares outstanding. ",
         "Absolute return is $|\\Delta \\ln P_t|$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("Generating Table 2: Main DiD Results\n")

did_amihud   <- results$did_amihud
did_turnover <- results$did_turnover
did_absret   <- results$did_absret

# Extract coefficients
get_coef <- function(mod, var = "post:phase1") {
  ct <- coeftable(mod)
  idx <- grep(var, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) idx <- 1
  list(
    beta = ct[idx, 1],
    se   = ct[idx, 2],
    pval = ct[idx, 4],
    stars = ifelse(ct[idx, 4] < 0.01, "***",
                   ifelse(ct[idx, 4] < 0.05, "**",
                          ifelse(ct[idx, 4] < 0.10, "*", "")))
  )
}

c_amihud   <- get_coef(did_amihud)
c_turnover <- get_coef(did_turnover)
c_absret   <- get_coef(did_absret)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Mandatory English Disclosure on Stock Market Liquidity}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Log Amihud & Log Turnover & Abs. Return \\\\",
  "\\midrule",
  paste0("Phase 1 $\\times$ Post & ",
         sprintf("%.4f%s", c_amihud$beta, c_amihud$stars), " & ",
         sprintf("%.4f%s", c_turnover$beta, c_turnover$stars), " & ",
         sprintf("%.4f%s", c_absret$beta, c_absret$stars), " \\\\"),
  paste0(" & (", sprintf("%.4f", c_amihud$se), ") & (",
         sprintf("%.4f", c_turnover$se), ") & (",
         sprintf("%.4f", c_absret$se), ") \\\\"),
  " \\\\",
  "\\midrule",
  paste0("Firm FE & Yes & Yes & Yes \\\\"),
  paste0("Week FE & Yes & Yes & Yes \\\\"),
  paste0("Observations & ",
         formatC(nobs(did_amihud), big.mark = ","), " & ",
         formatC(nobs(did_turnover), big.mark = ","), " & ",
         formatC(nobs(did_absret), big.mark = ","), " \\\\"),
  paste0("Firms & ", uniqueN(weekly$ticker), " & ",
         uniqueN(weekly$ticker), " & ",
         uniqueN(weekly$ticker), " \\\\"),
  paste0("Mean dep. var. (pre) & ",
         sprintf("%.3f", mean(weekly[post == 0]$log_amihud_w, na.rm = TRUE)), " & ",
         sprintf("%.3f", mean(weekly[post == 0]$log_turnover_w, na.rm = TRUE)), " & ",
         sprintf("%.4f", mean(weekly[post == 0]$abs_ret_w, na.rm = TRUE)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Difference-in-differences estimates. ",
         "The dependent variable in column (1) is the natural log of weekly ",
         "Amihud illiquidity; in column (2), the natural log of daily trading ",
         "turnover averaged within weeks; in column (3), the average absolute ",
         "daily return within each week. Phase 1 firms are KOSPI-listed companies ",
         "with total assets $\\geq$ KRW 10 trillion, mandated to file in English ",
         "from January 2024. All specifications include firm and week fixed effects. ",
         "Standard errors clustered at the firm level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Heterogeneity — Size and Sector Splits
# ============================================================
cat("Generating Table 3: Heterogeneity\n")

c_large  <- get_coef(results$did_large)
c_small  <- get_coef(results$did_small)
c_fin    <- get_coef(results$did_financial)
c_nonfin <- get_coef(results$did_nonfinancial)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity: Size and Sector Splits}",
  "\\label{tab:hetero}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Large Treated & Small Treated & Financial & Non-Financial \\\\",
  "\\midrule",
  paste0("Phase 1 $\\times$ Post & ",
         sprintf("%.4f%s", c_large$beta, c_large$stars), " & ",
         sprintf("%.4f%s", c_small$beta, c_small$stars), " & ",
         sprintf("%.4f%s", c_fin$beta, c_fin$stars), " & ",
         sprintf("%.4f%s", c_nonfin$beta, c_nonfin$stars), " \\\\"),
  paste0(" & (", sprintf("%.4f", c_large$se), ") & (",
         sprintf("%.4f", c_small$se), ") & (",
         sprintf("%.4f", c_fin$se), ") & (",
         sprintf("%.4f", c_nonfin$se), ") \\\\"),
  " \\\\",
  "\\midrule",
  "Firm FE & Yes & Yes & Yes & Yes \\\\",
  "Week FE & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ",
         formatC(nobs(results$did_large), big.mark = ","), " & ",
         formatC(nobs(results$did_small), big.mark = ","), " & ",
         formatC(nobs(results$did_financial), big.mark = ","), " & ",
         formatC(nobs(results$did_nonfinancial), big.mark = ","), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is log Amihud illiquidity ",
         "in all columns. Columns (1)--(2) split Phase 1 firms at the median market ",
         "capitalization within the treated group. Columns (3)--(4) split by sector: ",
         "financial (banking, insurance, financial services) vs.\\ non-financial. ",
         "Each column compares the relevant treated subsample against the full ",
         "control group. Standard errors clustered at the firm level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_heterogeneity.tex"))

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness\n")

c_placebo  <- get_coef(robust$placebo_amihud, "post_placebo:phase1")
c_donut    <- get_coef(robust$did_donut)
c_wins     <- get_coef(robust$did_wins_amihud)
c_ex_top10 <- get_coef(robust$did_ex_top10)
c_balanced <- get_coef(robust$did_balanced)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks: Log Amihud Illiquidity}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & Placebo & Donut & Excl. Top 10 & Balanced \\\\",
  "\\midrule",
  paste0("Treatment $\\times$ Post & ",
         sprintf("%.4f%s", c_amihud$beta, c_amihud$stars), " & ",
         sprintf("%.4f%s", c_placebo$beta, c_placebo$stars), " & ",
         sprintf("%.4f%s", c_donut$beta, c_donut$stars), " & ",
         sprintf("%.4f%s", c_ex_top10$beta, c_ex_top10$stars), " & ",
         sprintf("%.4f%s", c_balanced$beta, c_balanced$stars), " \\\\"),
  paste0(" & (", sprintf("%.4f", c_amihud$se), ") & (",
         sprintf("%.4f", c_placebo$se), ") & (",
         sprintf("%.4f", c_donut$se), ") & (",
         sprintf("%.4f", c_ex_top10$se), ") & (",
         sprintf("%.4f", c_balanced$se), ") \\\\"),
  " \\\\",
  "\\midrule",
  "Firm FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Week FE & Yes & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ",
         formatC(nobs(did_amihud), big.mark = ","), " & ",
         formatC(nobs(robust$placebo_amihud), big.mark = ","), " & ",
         formatC(nobs(robust$did_donut), big.mark = ","), " & ",
         formatC(nobs(robust$did_ex_top10), big.mark = ","), " & ",
         formatC(nobs(robust$did_balanced), big.mark = ","), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is log Amihud illiquidity ",
         "in all columns. Column (1) repeats the baseline. Column (2) uses a ",
         "placebo treatment date of January 2023, estimated on pre-2024 data only. ",
         "Column (3) excludes 4 weeks on either side of the treatment date. ",
         "Column (4) excludes the 10 largest firms by market capitalization. ",
         "Column (5) restricts to firms present in $\\geq$90\\% of weeks. ",
         "Standard errors clustered at the firm level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDEs
sd_amihud  <- sd(weekly[post == 0]$log_amihud_w, na.rm = TRUE)
sd_turnover <- sd(weekly[post == 0]$log_turnover_w, na.rm = TRUE)

sde_amihud   <- c_amihud$beta / sd_amihud
se_sde_amihud <- c_amihud$se / sd_amihud

sde_turnover   <- c_turnover$beta / sd_turnover
se_sde_turnover <- c_turnover$se / sd_turnover

# Heterogeneous SDEs (large vs small treated)
sde_large <- c_large$beta / sd_amihud
se_sde_large <- c_large$se / sd_amihud
sde_small <- c_small$beta / sd_amihud
se_sde_small <- c_small$se / sd_amihud

classify <- function(s) {
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

# Build SDE table
sde_rows <- list(
  # Panel A: Pooled
  list("Amihud illiquidity", "Pooled DiD",
       c_amihud$beta, c_amihud$se, "---", sd_amihud,
       sde_amihud, se_sde_amihud, classify(sde_amihud)),
  list("Turnover", "Pooled DiD",
       c_turnover$beta, c_turnover$se, "---", sd_turnover,
       sde_turnover, se_sde_turnover, classify(sde_turnover)),
  # Panel B: Heterogeneous
  list("Amihud (large treated)", "Sample split",
       c_large$beta, c_large$se, "---", sd_amihud,
       sde_large, se_sde_large, classify(sde_large)),
  list("Amihud (small treated)", "Sample split",
       c_small$beta, c_small$se, "---", sd_amihud,
       sde_small, se_sde_small, classify(sde_small))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} South Korea. ",
  "\\textbf{Research question:} Does mandatory English-language financial disclosure ",
  "for large KOSPI firms reduce stock market illiquidity for treated firms relative to ",
  "untreated KOSPI peers? ",
  "\\textbf{Policy mechanism:} Korea's FSC required firms with total assets at or above KRW ",
  "10 trillion to file financial statements in English starting January 2024, reducing ",
  "language-based information barriers for foreign investors who previously could not read ",
  "Korean-only filings. ",
  "\\textbf{Outcome definition:} Log of weekly Amihud illiquidity ratio (average absolute daily ",
  "return divided by KRW trading volume in billions), where higher values indicate less liquid markets. ",
  "\\textbf{Treatment:} Binary: firms with total assets $\\geq$ KRW 10 trillion mandated to ",
  "file in English (Phase 1) vs.\\ firms below the threshold. ",
  "\\textbf{Data:} Yahoo Finance daily OHLCV and FinanceDataReader firm characteristics for ",
  "KOSPI-listed firms, January 2022--December 2025, at the firm-week level; ",
  formatC(nrow(weekly), big.mark = ","), " firm-week observations across ",
  uniqueN(weekly$ticker), " firms. ",
  "\\textbf{Method:} Two-way fixed effects DiD (firm and week FE), standard errors clustered at ",
  "the firm level. ",
  "\\textbf{Sample:} Top 300 KOSPI firms by market capitalization; weeks with $\\geq$3 trading days. ",
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
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:2) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    paste0(r[[1]], " & ", r[[2]], " & ",
           sprintf("%.4f", r[[3]]), " & ",
           sprintf("%.4f", r[[4]]), " & ",
           sprintf("%.3f", r[[6]]), " & ",
           sprintf("%.4f", r[[7]]), " & ",
           sprintf("%.4f", r[[8]]), " & ",
           r[[9]], " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\"
)

for (i in 3:4) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines,
    paste0(r[[1]], " & ", r[[2]], " & ",
           sprintf("%.4f", r[[3]]), " & ",
           sprintf("%.4f", r[[4]]), " & ",
           sprintf("%.3f", r[[6]]), " & ",
           sprintf("%.4f", r[[7]]), " & ",
           sprintf("%.4f", r[[8]]), " & ",
           r[[9]], " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
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

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated successfully.\n")
cat("Tables saved to:", tables_dir, "\n")
