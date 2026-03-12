## 06_tables.R — Generate all tables for the paper
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: Merged main effects table, WCB p-values, metro/EB columns

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
panel[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
rob_results <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

cat("=== TABLE 1: Summary Statistics (with metro comparison) ===\n")

make_summ <- function(dt, label) {
  data.frame(
    Group = label,
    `Jail Rate` = sprintf("%.1f (%.1f)", mean(dt$jail_rate, na.rm=T), sd(dt$jail_rate, na.rm=T)),
    `Jail Population` = sprintf("%.0f (%.0f)", mean(dt$total_jail_pop, na.rm=T), sd(dt$total_jail_pop, na.rm=T)),
    `Pretrial Share` = sprintf("%.2f (%.2f)",
      mean(dt$total_jail_pretrial/dt$total_jail_pop, na.rm=T),
      sd(dt$total_jail_pretrial/dt$total_jail_pop, na.rm=T)),
    `Population (K)` = sprintf("%.0f (%.0f)", mean(dt$total_pop, na.rm=T)/1000, sd(dt$total_pop, na.rm=T)/1000),
    `Black Share` = sprintf("%.1f (%.1f)", mean(dt$black_share, na.rm=T), sd(dt$black_share, na.rm=T)),
    `Poverty Rate` = sprintf("%.1f (%.1f)", mean(dt$poverty_rate, na.rm=T), sd(dt$poverty_rate, na.rm=T)),
    `Unemp. Rate` = sprintf("%.1f (%.1f)", mean(dt$unemp_rate, na.rm=T), sd(dt$unemp_rate, na.rm=T)),
    `N` = nrow(dt),
    check.names = FALSE
  )
}

pre_treat <- panel[year >= 2010 & year <= 2014]
summ_treated <- make_summ(pre_treat[ever_treated == 1], "Progressive DA")
summ_all_ctrl <- make_summ(pre_treat[ever_treated == 0], "All Controls")
summ_metro_ctrl <- make_summ(pre_treat[ever_treated == 0 & is_metro == 1], "Metro Controls")

table1 <- rbind(summ_treated, summ_all_ctrl, summ_metro_ctrl)
table1_t <- t(table1[, -1])
colnames(table1_t) <- table1$Group

tex_table1 <- xtable(table1_t,
  caption = "Summary Statistics: Pre-Treatment Means (2010--2014)",
  label = "tab:summary",
  align = c("l", "c", "c", "c"))
print(tex_table1,
  file = file.path(TABLE_DIR, "table1_summary.tex"),
  floating = TRUE,
  sanitize.text.function = identity,
  include.rownames = TRUE,
  booktabs = TRUE)
cat("Table 1 saved\n")

cat("\n=== TABLE 2: Main Results — Consolidated (Jail + Homicide) ===\n")

# Panel A: Jail outcomes
tab2a_models <- list()
tab2a_models[["(1)"]] <- results$twfe_jail
tab2a_models[["(2)"]] <- results$twfe_jail_ctrl
tab2a_models[["(3)"]] <- results$twfe_jail_sxyr
tab2a_models[["(4)"]] <- results$twfe_jail_metro
if (!is.null(results$twfe_jail_ebal)) {
  tab2a_models[["(5)"]] <- results$twfe_jail_ebal
}

tab2a_names <- c(
  "treated" = "Progressive DA",
  "poverty_rate" = "Poverty Rate",
  "unemp_rate" = "Unemployment Rate",
  "log_pop" = "Log Population"
)

# Generate Panel A
modelsummary(
  tab2a_models,
  coef_map = tab2a_names,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_omit = "AIC|BIC|Log|Adj|Within",
  title = "Panel A: Effect on County Jail Population Rate (per 100,000)",
  notes = c("Standard errors clustered at state level in parentheses.",
            "All specifications include county and year fixed effects.",
            "Col (3): state $\\times$ year FE. Col (4): metro controls only. Col (5): entropy-balanced weights."),
  output = file.path(TABLE_DIR, "table2a_jail.tex")
)

# Panel B: Homicide outcomes
tab2b_models <- list(
  "(1)" = results$twfe_homicide,
  "(2)" = results$twfe_hom_sxyr
)

modelsummary(
  tab2b_models,
  coef_map = c("treated" = "Progressive DA"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_omit = "AIC|BIC|Log|Adj|Within",
  title = "Panel B: Effect on Homicide Mortality Rate (per 100,000)",
  notes = c("Standard errors clustered at state level.",
            "Col (1): county + year FE. Col (2): county + state $\\times$ year FE.",
            "Sample: 2019--2024 (CHR data availability)."),
  output = file.path(TABLE_DIR, "table2b_homicide.tex")
)
cat("Table 2 (A+B) saved\n")

cat("\n=== TABLE 3: DDD — Racial Decomposition ===\n")

tab3_models <- list(
  "(1)" = results$ddd_jail,
  "(2)" = results$twfe_bw_ratio
)

# Add metro DDD if available
if (!is.null(results$ddd_jail_metro)) {
  tab3_models[["(3)"]] <- results$ddd_jail_metro
}

tab3_names <- c(
  "is_black:treated" = "Black $\\times$ Progressive DA",
  "treated" = "Progressive DA"
)

modelsummary(
  tab3_models,
  coef_map = tab3_names,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_omit = "AIC|BIC|Log|Adj|Within",
  title = "Racial Decomposition: Differential Effects on Black vs.\\ White Jail Rates",
  notes = c("Col (1): DDD with county$\\times$race, year$\\times$race, county$\\times$year FE.",
            "Col (2): Black/White ratio as dependent variable.",
            "Col (3): DDD restricted to metro control counties.",
            "Standard errors clustered at state level."),
  output = file.path(TABLE_DIR, "table3_racial_ddd.tex")
)
cat("Table 3 saved\n")

cat("\n=== TABLE 4: CS-DiD Summary ===\n")

# Create CS-DiD summary table manually
cs_rows <- list()

add_cs_row <- function(label, agg_obj) {
  if (!is.null(agg_obj)) {
    data.frame(
      Specification = label,
      ATT = sprintf("%.1f", agg_obj$overall.att),
      SE = sprintf("(%.1f)", agg_obj$overall.se),
      stringsAsFactors = FALSE
    )
  }
}

cs_rows[[1]] <- add_cs_row("Jail Rate (Full Sample)", results$cs_jail_agg)
cs_rows[[2]] <- add_cs_row("Jail Rate (Metro Only)", results$cs_jail_metro_agg)
cs_rows[[3]] <- add_cs_row("Pretrial Rate", results$cs_pretrial_agg)
cs_rows[[4]] <- add_cs_row("Homicide Rate", results$cs_hom_agg)
cs_rows[[5]] <- add_cs_row("Black Jail Rate", results$cs_black_agg)
cs_rows[[6]] <- add_cs_row("White Jail Rate", results$cs_white_agg)

cs_table <- bind_rows(cs_rows[!sapply(cs_rows, is.null)])

if (nrow(cs_table) > 0) {
  tex_cs <- xtable(cs_table,
    caption = "Callaway-Sant'Anna (2021) Simple ATT Estimates",
    label = "tab:csatt",
    align = c("l", "l", "r", "r"))
  print(tex_cs,
    file = file.path(TABLE_DIR, "table4_csatt.tex"),
    floating = TRUE,
    include.rownames = FALSE,
    booktabs = TRUE,
    sanitize.text.function = identity)
  cat("Table 4 saved\n")
}

cat("\n=== TABLE 5: Robustness Checks (with WCB p-values) ===\n")

tab5_models <- list(
  "(1) Full" = results$twfe_jail,
  "(2) Pre-COVID" = rob_results$precovid,
  "(3) Pre-2020" = rob_results$precohort,
  "(4) No 2020" = rob_results$no2020,
  "(5) Pop-Wt" = rob_results$weighted,
  "(6) AAPI" = rob_results$aapi_placebo
)

# Add donut if available
if (!is.null(rob_results$donut)) {
  tab5_models[["(7) Donut"]] <- rob_results$donut
}

modelsummary(
  tab5_models,
  coef_map = c("treated" = "Progressive DA"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  gof_omit = "AIC|BIC|Log|Adj|Within",
  title = "Robustness: Effect on Jail Population Rate",
  notes = c("All: county + year FE, state-clustered SEs.",
            "Col (6): AAPI jail rate (placebo). Col (7): excludes counties adjacent to treated.",
            sprintf("WCB p-value (baseline): %.4f. RI p-value: %.4f.",
                    ifelse(!is.null(rob_results$wcb$baseline),
                           summary(rob_results$wcb$baseline)$p_val, NA),
                    rob_results$ri_pvalue)),
  output = file.path(TABLE_DIR, "table5_robustness.tex")
)
cat("Table 5 saved\n")

cat("\n=== TABLE 6: Inference Summary (NEW v2) ===\n")

# Create a comprehensive inference table
inference_rows <- data.frame(
  Specification = character(),
  Coefficient = character(),
  State_SE = character(),
  County_SE = character(),
  WCB_p = character(),
  stringsAsFactors = FALSE
)

# Baseline
base_coef <- coef(results$twfe_jail)["treated"]
base_se_state <- se(results$twfe_jail)["treated"]
base_se_county <- se(rob_results$county_clustered)["treated"]
base_wcb_p <- ifelse(!is.null(rob_results$wcb$baseline),
                      sprintf("%.4f", summary(rob_results$wcb$baseline)$p_val), "---")

inference_rows <- rbind(inference_rows, data.frame(
  Specification = "Baseline (Full)",
  Coefficient = sprintf("%.1f", base_coef),
  State_SE = sprintf("(%.1f)", base_se_state),
  County_SE = sprintf("(%.1f)", base_se_county),
  WCB_p = base_wcb_p,
  stringsAsFactors = FALSE
))

# Metro
metro_coef <- coef(results$twfe_jail_metro)["treated"]
metro_se <- se(results$twfe_jail_metro)["treated"]
metro_wcb_p <- ifelse(!is.null(rob_results$wcb$metro),
                       sprintf("%.4f", summary(rob_results$wcb$metro)$p_val), "---")

inference_rows <- rbind(inference_rows, data.frame(
  Specification = "Metro Only",
  Coefficient = sprintf("%.1f", metro_coef),
  State_SE = sprintf("(%.1f)", metro_se),
  County_SE = "---",
  WCB_p = metro_wcb_p,
  stringsAsFactors = FALSE
))

# State × Year
sxyr_coef <- coef(results$twfe_jail_sxyr)["treated"]
sxyr_se <- se(results$twfe_jail_sxyr)["treated"]
sxyr_wcb_p <- ifelse(!is.null(rob_results$wcb$sxyr),
                      sprintf("%.4f", summary(rob_results$wcb$sxyr)$p_val), "---")

inference_rows <- rbind(inference_rows, data.frame(
  Specification = "State $\\times$ Year FE",
  Coefficient = sprintf("%.1f", sxyr_coef),
  State_SE = sprintf("(%.1f)", sxyr_se),
  County_SE = "---",
  WCB_p = sxyr_wcb_p,
  stringsAsFactors = FALSE
))

# RI row
inference_rows <- rbind(inference_rows, data.frame(
  Specification = "Randomization Inference",
  Coefficient = sprintf("%.1f", base_coef),
  State_SE = "---",
  County_SE = "---",
  WCB_p = sprintf("%.4f (RI)", rob_results$ri_pvalue),
  stringsAsFactors = FALSE
))

tex_inf <- xtable(inference_rows,
  caption = "Inference Robustness: Alternative Standard Errors and Permutation Tests",
  label = "tab:inference",
  align = c("l", "l", "r", "r", "r", "r"))
print(tex_inf,
  file = file.path(TABLE_DIR, "table6_inference.tex"),
  floating = TRUE,
  include.rownames = FALSE,
  booktabs = TRUE,
  sanitize.text.function = identity)
cat("Table 6 (Inference) saved\n")

cat("\n=== TABLE 7: Treatment County Details ===\n")

treatment <- fread(file.path(DATA_DIR, "progressive_da_treatment.csv"))
treatment[, fips := str_pad(as.character(fips), width = 5, pad = "0")]

pre_chars <- panel[year == 2014, .(fips, total_pop, jail_rate, black_share, homicide_rate)]
treatment_detail <- merge(treatment, pre_chars, by = "fips", all.x = TRUE)
treatment_detail <- treatment_detail[order(treatment_year)]

tex_treat <- xtable(
  treatment_detail[, .(county_name, state, da_name, treatment_year,
                       total_pop = round(total_pop/1000),
                       jail_rate = round(jail_rate, 1),
                       black_share = round(black_share, 1))],
  caption = "Progressive District Attorney Counties: Treatment Details",
  label = "tab:treatment",
  align = c("l", "l", "c", "l", "c", "r", "r", "r")
)

print(tex_treat,
  file = file.path(TABLE_DIR, "table7_treatment_details.tex"),
  floating = TRUE,
  include.rownames = FALSE,
  booktabs = TRUE,
  sanitize.text.function = identity)
cat("Table 7 saved\n")

cat("\n=== TABLES COMPLETE ===\n")
cat("Files in tables directory:\n")
cat(paste(list.files(TABLE_DIR), collapse = "\n"), "\n")
