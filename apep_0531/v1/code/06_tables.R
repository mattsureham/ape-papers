## ============================================================
## 06_tables.R — All tables for the paper
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

panel <- fread(file.path(dat_dir, "analysis_panel.csv"))
panel <- panel[!is.na(total_crime) & !is.na(pcso_fte) & year <= 2024]
load(file.path(dat_dir, "twfe_models.RData"))

## ---- Table 1: Summary Statistics ------------------------------

sum_stats <- panel[, .(
  Variable = c("PCSOs per 100k", "Officers per 100k", "Total crime rate per 100k",
               "Log crime rate", "Population (millions)"),
  Mean = c(mean(pcso_per100k, na.rm = TRUE),
           mean(officer_per100k, na.rm = TRUE),
           mean(crime_rate, na.rm = TRUE),
           mean(log_crime_rate, na.rm = TRUE),
           mean(population / 1e6, na.rm = TRUE)),
  SD = c(sd(pcso_per100k, na.rm = TRUE),
         sd(officer_per100k, na.rm = TRUE),
         sd(crime_rate, na.rm = TRUE),
         sd(log_crime_rate, na.rm = TRUE),
         sd(population / 1e6, na.rm = TRUE)),
  Min = c(min(pcso_per100k, na.rm = TRUE),
          min(officer_per100k, na.rm = TRUE),
          min(crime_rate, na.rm = TRUE),
          min(log_crime_rate, na.rm = TRUE),
          min(population / 1e6, na.rm = TRUE)),
  Max = c(max(pcso_per100k, na.rm = TRUE),
          max(officer_per100k, na.rm = TRUE),
          max(crime_rate, na.rm = TRUE),
          max(log_crime_rate, na.rm = TRUE),
          max(population / 1e6, na.rm = TRUE))
)]

# Round
sum_stats[, Mean := round(Mean, 2)]
sum_stats[, SD := round(SD, 2)]
sum_stats[, Min := round(Min, 2)]
sum_stats[, Max := round(Max, 2)]

fwrite(sum_stats, file.path(dat_dir, "table1_summary.csv"))

# LaTeX table
tab1_tex <- kbl(sum_stats, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics",
                label = "summary",
                col.names = c("Variable", "Mean", "SD", "Min", "Max")) |>
  kable_styling(latex_options = "hold_position")
writeLines(tab1_tex, file.path(tab_dir, "table1_summary.tex"))
cat("Table 1 saved.\n")


## ---- Table 2: Main TWFE Results --------------------------------

# Build Table 2 manually with kableExtra for reliable LaTeX output
fmt_coef <- function(x) ifelse(is.na(x), "", sprintf("%.4f", x))
fmt_se <- function(x) ifelse(is.na(x), "", paste0("(", sprintf("%.3f", x), ")"))

get_star <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

get_coef_se <- function(m, var) {
  ct <- coeftable(m)
  if (var %in% rownames(ct)) {
    c_val <- ct[var, "Estimate"]
    s_val <- ct[var, "Std. Error"]
    p_val <- ct[var, "Pr(>|t|)"]
    return(list(coef = paste0(sprintf("%.4f", c_val), get_star(p_val)),
                se = paste0("(", sprintf("%.4f", s_val), ")")))
  }
  list(coef = "", se = "")
}

r_pcso_m1 <- get_coef_se(m1, "pcso_per100k")
r_pcso_m2 <- get_coef_se(m2, "pcso_per100k")
r_pcso_m4 <- get_coef_se(m4, "pcso_per100k")
r_off_m2 <- get_coef_se(m2, "officer_per100k")
r_off_m4 <- get_coef_se(m4, "officer_per100k")
r_lpcso_m3 <- get_coef_se(m3, "log_pcso")
r_loff_m3 <- get_coef_se(m3, "log_officer")

tab2_data <- data.frame(
  Variable = c("PCSOs per 100k", "", "Officers per 100k", "",
               "Log PCSOs per 100k", "", "Log officers per 100k", "",
               "Observations", "Force FE", "Year FE"),
  M1 = c(r_pcso_m1$coef, r_pcso_m1$se, "", "", "", "", "", "",
         as.character(nobs(m1)), "X", "X"),
  M2 = c(r_pcso_m2$coef, r_pcso_m2$se, r_off_m2$coef, r_off_m2$se,
         "", "", "", "",
         as.character(nobs(m2)), "X", "X"),
  M3 = c("", "", "", "",
         r_lpcso_m3$coef, r_lpcso_m3$se, r_loff_m3$coef, r_loff_m3$se,
         as.character(nobs(m3)), "X", "X"),
  M4 = c(r_pcso_m4$coef, r_pcso_m4$se, r_off_m4$coef, r_off_m4$se,
         "", "", "", "",
         as.character(nobs(m4)), "X", "X"),
  stringsAsFactors = FALSE
)

tab2_tex <- kbl(tab2_data, format = "latex", booktabs = TRUE,
                col.names = c("", "(1)", "(2)", "(3)", "(4)"),
                align = c("l", "c", "c", "c", "c"),
                caption = "Effect of PCSOs on Crime",
                label = "main") |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = "TWFE with force and year FE. Clustered SEs. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (3) drops 6 force-years with zero PCSOs (required for log transformation).",
           general_title = "Note: ",
           footnote_as_chunk = TRUE, escape = FALSE)
writeLines(tab2_tex, file.path(tab_dir, "table2_main.tex"))
cat("Table 2 saved.\n")


## ---- Table 3: Crime Type Decomposition -------------------------

type_dt <- fread(file.path(dat_dir, "crime_type_results.csv"))
type_dt[, stars := as.character(stars)]
type_dt[is.na(stars) | stars == "", stars := ""]
type_dt[, coef_str := paste0(sprintf("%.4f", coef), stars)]
type_dt[, se_str := paste0("(", sprintf("%.4f", se), ")")]

tab3_data <- type_dt[order(coef), .(
  `Offence Group` = offence_group,
  `Coefficient` = coef_str,
  `SE` = se_str,
  `N` = n
)]

fwrite(tab3_data, file.path(dat_dir, "table3_types.csv"))

tab3_tex <- kbl(tab3_data, format = "latex", booktabs = TRUE,
                caption = "PCSO Effect by Crime Type",
                label = "types",
                align = c("l", "r", "r", "r")) |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = "TWFE with force and year FE. Clustered SEs in parentheses. Fraud ($N=246$): 2008--2013 only (reporting centralized after 2013).",
           footnote_as_chunk = TRUE, escape = FALSE)
writeLines(tab3_tex, file.path(tab_dir, "table3_types.tex"))
cat("Table 3 saved.\n")


## ---- Table 4: Robustness Summary --------------------------------

rob <- fread(file.path(dat_dir, "robustness_summary.csv"))
rob[, coef_str := sprintf("%.4f", coef)]
rob[, se_str := paste0("(", sprintf("%.4f", se), ")")]
rob[, ci_str := paste0("[", sprintf("%.4f", ci_low), ", ", sprintf("%.4f", ci_high), "]")]

tab4_data <- rob[, .(`Specification` = specification,
                      `Coefficient` = coef_str,
                      `SE` = se_str,
                      `95% CI` = ci_str,
                      `N` = n)]

fwrite(tab4_data, file.path(dat_dir, "table4_robustness.csv"))

tab4_tex <- kbl(tab4_data, format = "latex", booktabs = TRUE,
                caption = "Robustness of PCSO Coefficient Across Specifications",
                label = "robust",
                align = c("l", "r", "r", "c", "r")) |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = "Rows 1--3: force and year FE. Row 4 (first-differenced): year FE only (force FE difference out). All SEs clustered at force level.",
           footnote_as_chunk = TRUE)
writeLines(tab4_tex, file.path(tab_dir, "table4_robustness.tex"))
cat("Table 4 saved.\n")


## ---- Table 5: MDE and Power ------------------------------------

mde <- fread(file.path(dat_dir, "mde_results.csv"))

# Wild bootstrap
boot <- tryCatch(fread(file.path(dat_dir, "wild_bootstrap.csv")), error = function(e) NULL)
ri <- fread(file.path(dat_dir, "randomization_inference.csv"))

power_data <- data.table(
  Metric = c("Standard error (PCSO coef.)",
             "Average PCSO decline (per 100k)",
             "MDE at 80% power (crime %)",
             "Wild cluster bootstrap p-value",
             "Randomization inference p-value"),
  Value = c(sprintf("%.5f", mde$se),
            sprintf("%.1f", mde$avg_decline),
            sprintf("%.1f%%", mde$mde_pct),
            if (!is.null(boot)) sprintf("%.3f", boot$pval) else "N/A",
            sprintf("%.3f", ri$ri_pval))
)

fwrite(power_data, file.path(dat_dir, "table5_power.csv"))

tab5_tex <- kbl(power_data, format = "latex", booktabs = TRUE,
                caption = "Statistical Power and Inference Summary",
                label = "power",
                align = c("l", "r")) |>
  kable_styling(latex_options = "hold_position")
writeLines(tab5_tex, file.path(tab_dir, "table5_power.tex"))
cat("Table 5 saved.\n")

cat("\n=== ALL TABLES SAVED ===\n")
