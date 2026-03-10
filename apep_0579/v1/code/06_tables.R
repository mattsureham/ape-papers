## ==============================================================
## 06_tables.R — All tables for the paper
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

results <- readRDS(file.path(data_dir, "all_models.rds"))
rr_table <- fread(file.path(data_dir, "reversal_ratios.csv"))

## ---------------------------------------------------------------
## TABLE 1: Summary Statistics
## ---------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

sumstats <- list()

# Denmark
dk <- fread(file.path(data_dir, "dk_clean.csv"))
sumstats$dk <- data.table(
  Reform = "Denmark fat tax",
  Outcome = "HICP Index",
  Unit = "COICOP × month",
  N = nrow(dk),
  `Treated units` = uniqueN(dk[treated == 1]$coicop),
  `Control units` = uniqueN(dk[treated == 0]$coicop),
  `Mean (treated)` = round(mean(dk[treated == 1]$values, na.rm = TRUE), 1),
  `SD (treated)` = round(sd(dk[treated == 1]$values, na.rm = TRUE), 1),
  `Mean (control)` = round(mean(dk[treated == 0]$values, na.rm = TRUE), 1),
  `SD (control)` = round(sd(dk[treated == 0]$values, na.rm = TRUE), 1),
  Frequency = "Monthly",
  `Period` = "2008-2016"
)

# Czech Republic
cz <- fread(file.path(data_dir, "cz_clean.csv"))
cz <- cz[icha11_hf %in% c("HF1", "HF3")]
sumstats$cz <- data.table(
  Reform = "Czech co-payments",
  Outcome = "Health expenditure (EUR m)",
  Unit = "Financing × year",
  N = nrow(cz),
  `Treated units` = 1L,
  `Control units` = 1L,
  `Mean (treated)` = round(mean(cz[treated == 1]$values, na.rm = TRUE), 1),
  `SD (treated)` = round(sd(cz[treated == 1]$values, na.rm = TRUE), 1),
  `Mean (control)` = round(mean(cz[treated == 0]$values, na.rm = TRUE), 1),
  `SD (control)` = round(sd(cz[treated == 0]$values, na.rm = TRUE), 1),
  Frequency = "Annual",
  `Period` = "2003-2020"
)

# Italy
it <- fread(file.path(data_dir, "it_clean.csv"))
sumstats$it <- data.table(
  Reform = "Italy RdC",
  Outcome = "Poverty rate (%)",
  Unit = "NUTS2 × year",
  N = nrow(it),
  `Treated units` = uniqueN(it[treated == 1]$geo),
  `Control units` = uniqueN(it[treated == 0]$geo),
  `Mean (treated)` = round(mean(it[treated == 1]$values, na.rm = TRUE), 1),
  `SD (treated)` = round(sd(it[treated == 1]$values, na.rm = TRUE), 1),
  `Mean (control)` = round(mean(it[treated == 0]$values, na.rm = TRUE), 1),
  `SD (control)` = round(sd(it[treated == 0]$values, na.rm = TRUE), 1),
  Frequency = "Annual",
  `Period` = "2015-2024"
)

# Poland
pl <- fread(file.path(data_dir, "pl_clean.csv"))
sumstats$pl <- data.table(
  Reform = "Poland retirement",
  Outcome = "Employment rate (%)",
  Unit = "Sex-age × quarter",
  N = nrow(pl),
  `Treated units` = 1L,
  `Control units` = uniqueN(pl[treated == 0]$group),
  `Mean (treated)` = round(mean(pl[treated == 1]$values, na.rm = TRUE), 1),
  `SD (treated)` = round(sd(pl[treated == 1]$values, na.rm = TRUE), 1),
  `Mean (control)` = round(mean(pl[treated == 0]$values, na.rm = TRUE), 1),
  `SD (control)` = round(sd(pl[treated == 0]$values, na.rm = TRUE), 1),
  Frequency = "Quarterly",
  `Period` = "2008-2022"
)

# France — use total economy aggregate (same filter as main regression)
fr <- fread(file.path(data_dir, "fr_clean.csv"))
fr[, geo := as.character(geo)]
fr_total <- fr[nace_r2 == "B-S" & lcstruct == "D1_D4_MD5" & s_adj == "SCA" & unit == "I20"]
if (nrow(fr_total) < 20) {
  fr_total <- fr[nace_r2 %in% c("B-S", "B-S_X_O") & lcstruct %in% c("D1_D4_MD5", "D1")]
  if (nrow(fr_total) > 0) fr_total <- fr_total[, .SD[1], by = .(geo, date)]
}
if (nrow(fr_total) < 20) fr_total <- fr[, .SD[1], by = .(geo, date)]
sumstats$fr <- data.table(
  Reform = "France supertax",
  Outcome = "Labor cost index",
  Unit = "Country × quarter",
  N = nrow(fr_total),
  `Treated units` = 1L,
  `Control units` = uniqueN(fr_total[treated == 0]$geo),
  `Mean (treated)` = round(mean(fr_total[treated == 1]$values, na.rm = TRUE), 1),
  `SD (treated)` = round(sd(fr_total[treated == 1]$values, na.rm = TRUE), 1),
  `Mean (control)` = round(mean(fr_total[treated == 0]$values, na.rm = TRUE), 1),
  `SD (control)` = round(sd(fr_total[treated == 0]$values, na.rm = TRUE), 1),
  Frequency = "Quarterly",
  `Period` = "2008-2019"
)

tab1 <- rbindlist(sumstats, fill = TRUE)
fwrite(tab1, file.path(data_dir, "tab1_summary_stats.csv"))

# LaTeX output
tab1_tex <- kable(tab1, format = "latex", booktabs = TRUE, linesep = "",
                   caption = "Summary Statistics by Reform") |>
  kable_styling(latex_options = c("scale_down", "hold_position"))

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary_stats.tex"))
cat("  Saved tab1_summary_stats.tex\n")

## ---------------------------------------------------------------
## TABLE 2: Main Results — Switch-ON and Switch-OFF Estimates
## ---------------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

tab2 <- rr_table[, .(
  Reform = reform,
  Domain = domain,
  `Duration (months)` = duration_months,
  `β_ON` = sprintf("%.3f", beta_on),
  `SE(ON)` = sprintf("(%.3f)", se_on),
  `β_OFF` = ifelse(is.na(beta_off), "—", sprintf("%.3f", beta_off)),
  `SE(OFF)` = ifelse(is.na(se_off), "", sprintf("(%.3f)", se_off)),
  `RR` = ifelse(is.na(reversal_ratio), "—", sprintf("%.3f", reversal_ratio)),
  `SE(RR)` = ifelse(is.na(rr_se), "", sprintf("(%.3f)", rr_se)),
  `N (ON)` = N_on,
  `N (OFF)` = N_off
)]

fwrite(tab2, file.path(data_dir, "tab2_main_results.csv"))

tab2_tex <- kable(tab2, format = "latex", booktabs = TRUE, linesep = "",
                   caption = "Switch-ON and Switch-OFF Estimates with Reversal Ratios",
                   escape = FALSE) |>
  kable_styling(latex_options = c("scale_down", "hold_position")) |>
  footnote(general = c(
    "Each column reports the DiD estimate of the policy effect during introduction (β\\\\textsubscript{ON}) and during reversal (β\\\\textsubscript{OFF}).",
    "The reversal ratio (RR) = β\\\\textsubscript{OFF} / β\\\\textsubscript{ON}. RR = 0 indicates full reversal; RR = 1 indicates complete hysteresis.",
    "Standard errors clustered at the unit level in parentheses."
  ), escape = FALSE)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main_results.tex"))
cat("  Saved tab2_main_results.tex\n")

## ---------------------------------------------------------------
## TABLE 3: Meta-Regression Results
## ---------------------------------------------------------------
cat("=== Table 3: Meta-Regression ===\n")

meta_file <- file.path(data_dir, "meta_regression.csv")
if (file.exists(meta_file)) {
  meta <- fread(meta_file)

  tab3 <- meta[, .(
    Variable = c("Intercept", "Log(Duration)", "Price instrument"),
    Estimate = sprintf("%.3f", estimate),
    `Std. Error` = sprintf("(%.3f)", se),
    `p-value` = sprintf("%.3f", p_value)
  )]

  tab3_tex <- kable(tab3, format = "latex", booktabs = TRUE, linesep = "",
                     caption = "Meta-Regression: Reversal Ratio as a Function of Reform Characteristics") |>
    kable_styling(latex_options = "hold_position") |>
    footnote(general = c(
      "Dependent variable: Reversal Ratio (β\\\\textsubscript{OFF} / β\\\\textsubscript{ON}).",
      "Log(Duration) is the natural log of policy duration in months.",
      "Price instrument = 1 for price-based policies (Denmark fat tax, France supertax).",
      "N = number of reforms with estimable reversal ratios."
    ), escape = FALSE)

  writeLines(tab3_tex, file.path(tab_dir, "tab3_meta_regression.tex"))
  cat("  Saved tab3_meta_regression.tex\n")
}

## ---------------------------------------------------------------
## TABLE 4: Robustness Summary
## ---------------------------------------------------------------
cat("=== Table 4: Robustness Summary ===\n")

rob_file <- file.path(data_dir, "robustness_summary.csv")
if (file.exists(rob_file)) {
  rob <- fread(rob_file)
  rob_tex <- kable(rob, format = "latex", booktabs = TRUE, linesep = "",
                    caption = "Robustness Checks Summary") |>
    kable_styling(latex_options = c("scale_down", "hold_position"))

  writeLines(rob_tex, file.path(tab_dir, "tab4_robustness.tex"))
  cat("  Saved tab4_robustness.tex\n")
}

cat("\nAll tables generated.\n")
