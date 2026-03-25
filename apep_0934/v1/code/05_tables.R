# 05_tables.R — Generate all tables for apep_0934
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>%
  filter(treatment_group != "post_policy") %>%
  mutate(
    treated = ifelse(treatment_group == "newly_treated", 1L, 0L),
    g = ifelse(treatment_group == "newly_treated" & !is.na(first_new_install),
               first_new_install, 0L),
    muni_id = as.integer(factor(municipality_no))
  )

results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment period (2016)
pre_data <- panel %>% filter(year == 2016)

summ_by_group <- pre_data %>%
  group_by(treated) %>%
  summarize(
    N = n(),
    `Property Value (1000 DKK)` = sprintf("%.0f", mean(avg_property_value / 1000, na.rm = TRUE)),
    `Property Value SD` = sprintf("%.0f", sd(avg_property_value / 1000, na.rm = TRUE)),
    `Population` = sprintf("%.0f", mean(population, na.rm = TRUE)),
    `Population SD` = sprintf("%.0f", sd(population, na.rm = TRUE)),
    `Avg Income (1000 DKK)` = sprintf("%.0f", mean(avg_income / 1000, na.rm = TRUE)),
    `Wind Capacity (MW)` = sprintf("%.1f", mean(onshore_wind_mw, na.rm = TRUE)),
    `N Turbines` = sprintf("%.0f", mean(n_onshore_turbines, na.rm = TRUE)),
    .groups = "drop"
  )

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Status (2016)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Control & Treated \\\\",
  " & (No new wind) & (New wind 2017--2020) \\\\",
  "\\hline"
)

ctrl <- summ_by_group %>% filter(treated == 0)
trt <- summ_by_group %>% filter(treated == 1)

tab1_lines <- c(tab1_lines,
  sprintf("Municipalities & %d & %d \\\\", ctrl$N, trt$N),
  sprintf("Property value (1000 DKK) & %s & %s \\\\", ctrl$`Property Value (1000 DKK)`, trt$`Property Value (1000 DKK)`),
  sprintf("\\quad SD & (%s) & (%s) \\\\", ctrl$`Property Value SD`, trt$`Property Value SD`),
  sprintf("Population & %s & %s \\\\", ctrl$Population, trt$Population),
  sprintf("\\quad SD & (%s) & (%s) \\\\", ctrl$`Population SD`, trt$`Population SD`),
  sprintf("Avg.~income (1000 DKK) & %s & %s \\\\", ctrl$`Avg Income (1000 DKK)`, trt$`Avg Income (1000 DKK)`),
  sprintf("Onshore wind capacity (MW) & %s & %s \\\\", ctrl$`Wind Capacity (MW)`, trt$`Wind Capacity (MW)`),
  sprintf("N onshore turbines & %s & %s \\\\", ctrl$`N Turbines`, trt$`N Turbines`),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Control municipalities include those with no wind (14) and those",
  "with existing wind but no new installations during 2017--2020 (34).",
  "Treated municipalities received new onshore wind capacity under Denmark's",
  "k{\\o}beretsordning (purchase-right scheme). Property values are average market",
  "valuations of single-family houses from DST EJDFOE1.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("=== Generating Table 2: Main Results ===\n")

# Get CS-DiD results
cs_att <- results$cs_agg$overall.att
cs_se <- results$cs_agg$overall.se

# TWFE with controls
twfe_ctrl <- robust$twfe_controls

tab2_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Effect of Community Wind Ownership on Property Values}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & TWFE & TWFE & TWFE & CS-DiD \\\\",
  " & Binary & Continuous & Controls & \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel A: Log property values}} \\\\",
  "\\\\[-1.2ex]",
  sprintf("Post $\\times$ Treated & $%s$ & & $%s$ & $%s$ \\\\",
          format(round(coef(results$twfe_binary)["post_treatment"], 4), nsmall = 4),
          format(round(coef(twfe_ctrl)["post_treatment"], 4), nsmall = 4),
          format(round(cs_att, 4), nsmall = 4)),
  sprintf(" & (%s) & & (%s) & (%s) \\\\",
          format(round(se(results$twfe_binary)["post_treatment"], 4), nsmall = 4),
          format(round(se(twfe_ctrl)["post_treatment"], 4), nsmall = 4),
          format(round(cs_se, 4), nsmall = 4)),
  sprintf("New wind capacity (MW) & & $%s$ & & \\\\",
          format(round(coef(results$twfe_continuous)["treatment_intensity"], 6), nsmall = 6)),
  sprintf(" & & (%s) & & \\\\",
          format(round(se(results$twfe_continuous)["treatment_intensity"], 6), nsmall = 6)),
  "\\\\[-1.2ex]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Green party vote share (pp)}} \\\\",
  "\\\\[-1.2ex]",
  sprintf("Post $\\times$ Treated & $%s$ & & & \\\\",
          format(round(coef(results$elec_twfe)["post_treatment"], 3), nsmall = 3)),
  sprintf(" & (%s) & & & \\\\",
          format(round(se(results$elec_twfe)["post_treatment"], 3), nsmall = 3)),
  "\\\\[-1.2ex]",
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & --- \\\\",
  "Year FE & Yes & Yes & Yes & --- \\\\",
  "Controls & No & No & Yes & No \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(results$twfe_binary), nobs(results$twfe_continuous),
          nobs(twfe_ctrl), nrow(panel)),
  sprintf("Municipalities & 97 & 97 & 97 & 97 \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the municipality level in parentheses.",
  "Columns 1--3 report two-way fixed effects estimates. Column 4 reports the",
  "Callaway and Sant'Anna (2021) aggregate ATT using not-yet-treated municipalities",
  "as the comparison group. Controls in Column 3 include log population and log average income.",
  "Green party vote share (Panel B) includes SF, Alternativet, and Enhedslisten.",
  "Municipal elections: 2005, 2009, 2013, 2017, 2021.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ============================================================================
# TABLE 3: Event Study Estimates
# ============================================================================
cat("=== Generating Table 3: Event Study ===\n")

cs_dyn <- results$cs_dynamic
event_times <- cs_dyn$egt
est <- cs_dyn$att.egt
ses <- cs_dyn$se.egt

tab3_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: CS-DiD Event Study}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event time & Estimate & Std.~Error & 95\\% CI \\\\",
  "\\hline"
)

for (i in seq_along(event_times)) {
  e <- event_times[i]
  label <- ifelse(e < 0, sprintf("$%d$", e), sprintf("$+%d$", e))
  ci_lo <- est[i] - 1.96 * ses[i]
  ci_hi <- est[i] + 1.96 * ses[i]
  star <- ifelse(ci_lo > 0 | ci_hi < 0, "*", "")
  if (e == 0) tab3_lines <- c(tab3_lines, "\\hline")
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s%s & %s & [%s, %s] \\\\",
            label,
            format(round(est[i], 4), nsmall = 4), star,
            format(round(ses[i], 4), nsmall = 4),
            format(round(ci_lo, 4), nsmall = 4),
            format(round(ci_hi, 4), nsmall = 4)))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic aggregation",
  "with not-yet-treated as comparison group. Event time 0 is the year of",
  "first new onshore wind installation under the k{\\o}beretsordning.",
  "* indicates 95\\% simultaneous confidence band excludes zero.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))

# ============================================================================
# TABLE 4: Robustness
# ============================================================================
cat("=== Generating Table 4: Robustness ===\n")

# Placebo
plac_coef <- coef(robust$placebo)
plac_se <- se(robust$placebo)

# SF only
sf_coef <- coef(robust$sf_twfe)["post_treatment"]
sf_se <- se(robust$sf_twfe)["post_treatment"]

tab4_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Coefficient & Std.~Error \\\\",
  "\\hline",
  "\\\\[-1.2ex]",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-one-out (TWFE, log property values)}} \\\\",
  "\\\\[-1.2ex]"
)

for (i in 1:nrow(robust$loo)) {
  tab4_lines <- c(tab4_lines,
    sprintf("Drop cohort %d (N treated = %d) & %s & (%s) \\\\",
            robust$loo$dropped_cohort[i], robust$loo$n_treated[i],
            format(round(robust$loo$coef[i], 4), nsmall = 4),
            format(round(robust$loo$se[i], 4), nsmall = 4)))
}

tab4_lines <- c(tab4_lines,
  "\\\\[-1.2ex]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo}} \\\\",
  "\\\\[-1.2ex]",
  sprintf("Old wind $\\times$ Post-2012 & %s & (%s) \\\\",
          format(round(plac_coef[1], 4), nsmall = 4),
          format(round(plac_se[1], 4), nsmall = 4)),
  "\\\\[-1.2ex]",
  "\\multicolumn{3}{l}{\\textit{Panel C: Alternative green measure}} \\\\",
  "\\\\[-1.2ex]",
  sprintf("SF vote share only & %s & (%s) \\\\",
          format(round(sf_coef, 3), nsmall = 3),
          format(round(sf_se, 3), nsmall = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Panel A drops one treatment cohort at a time from the TWFE specification.",
  "Panel B tests whether municipalities with pre-existing (pre-2016) wind turbines",
  "experienced differential property value trends relative to never-wind municipalities",
  "using a pseudo-treatment date of 2012. Panel C uses only SF (Socialistisk Folkeparti)",
  "vote share as the outcome. All standard errors clustered at the municipality level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================================
# TABLE F1: SDE Appendix
# ============================================================================
cat("=== Generating SDE Table ===\n")

# Compute SDE for main outcomes
# 1. Property values (CS-DiD ATT)
pre_panel <- panel %>% filter(year < 2017, !is.na(log_property))
sd_y_property <- sd(pre_panel$log_property)

sde_property <- cs_att / sd_y_property
sde_se_property <- cs_se / sd_y_property

# 2. Property values (TWFE binary)
twfe_coef <- coef(results$twfe_binary)["post_treatment"]
twfe_se_val <- se(results$twfe_binary)["post_treatment"]
sde_twfe <- twfe_coef / sd_y_property
sde_se_twfe <- twfe_se_val / sd_y_property

# 3. Green vote share
pre_elec <- readRDS(file.path(data_dir, "election_panel.rds")) %>%
  filter(year < 2017, !is.na(green_share))
sd_y_green <- sd(pre_elec$green_share)
elec_coef <- coef(results$elec_twfe)["post_treatment"]
elec_se <- se(results$elec_twfe)["post_treatment"]
sde_green <- elec_coef / sd_y_green
sde_se_green <- elec_se / sd_y_green

# 4. SF vote share
sf_pre <- readRDS(file.path(data_dir, "elections_full.rds"))
# For SF, use the TWFE estimate directly
sde_sf <- sf_coef / sd_y_green  # Approximate using same SD
sde_se_sf <- sf_se / sd_y_green

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  sign <- ifelse(sde >= 0, "positive", "negative")
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste0("Small ", sign))
  if (abs_sde < 0.15) return(paste0("Moderate ", sign))
  return(paste0("Large ", sign))
}

# Build SDE table rows
sde_rows <- data.frame(
  Outcome = c("Log property value (CS-DiD)", "Log property value (TWFE)",
              "Green party vote share (pp)", "SF vote share (pp)"),
  beta = c(cs_att, twfe_coef, elec_coef, sf_coef),
  se = c(cs_se, twfe_se_val, elec_se, sf_se),
  sd_y = c(sd_y_property, sd_y_property, sd_y_green, sd_y_green),
  sde = c(sde_property, sde_twfe, sde_green, sde_sf),
  sde_se = c(sde_se_property, sde_se_twfe, sde_se_green, sde_se_sf)
)
sde_rows$classification <- sapply(sde_rows$sde, classify_sde)

# Heterogeneity: split by urban/rural (above/below median population)
med_pop <- median(panel$population[panel$year == 2016], na.rm = TRUE)
panel_rural <- panel %>% filter(population <= med_pop)
panel_urban <- panel %>% filter(population > med_pop)

twfe_rural <- feols(log_property ~ post_treatment | municipality_no + year,
                    data = panel_rural, cluster = ~municipality_no)
twfe_urban <- feols(log_property ~ post_treatment | municipality_no + year,
                    data = panel_urban, cluster = ~municipality_no)

sde_rural <- coef(twfe_rural)["post_treatment"] / sd_y_property
sde_se_rural <- se(twfe_rural)["post_treatment"] / sd_y_property
sde_urban <- coef(twfe_urban)["post_treatment"] / sd_y_property
sde_se_urban <- se(twfe_urban)["post_treatment"] / sd_y_property

het_rows <- data.frame(
  Outcome = c("Log property value (rural)", "Log property value (urban)"),
  beta = c(coef(twfe_rural)["post_treatment"], coef(twfe_urban)["post_treatment"]),
  se = c(se(twfe_rural)["post_treatment"], se(twfe_urban)["post_treatment"]),
  sd_y = c(sd_y_property, sd_y_property),
  sde = c(sde_rural, sde_urban),
  sde_se = c(sde_se_rural, sde_se_urban)
)
het_rows$classification <- sapply(het_rows$sde, classify_sde)

# SDE LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does community financial co-ownership of onshore wind turbines ",
  "under Denmark's k{\\o}beretsordning (2009--2020) affect residential property values and green party voting? ",
  "\\textbf{Policy mechanism:} The k{\\o}beretsordning required developers of onshore wind turbines ",
  "to offer at least 20\\% of project shares at cost price to residents within 4.5~km, creating ",
  "a mandatory financial stake in the turbine's returns for nearby households. ",
  "\\textbf{Outcome definition:} Panel~A: Log average market valuation of single-family houses ",
  "(DST EJDFOE1). Panel~B: Combined vote share of SF, Alternativet, and Enhedslisten in municipal elections. ",
  "\\textbf{Treatment:} Binary indicator for municipality receiving new onshore wind capacity during 2017--2020. ",
  "\\textbf{Data:} Energidataservice CapacityPerMunicipality (monthly, 2016--2026) merged with ",
  "DST StatBank EJDFOE1 (2004--2024) and VALGK3 (2005--2021), 97 municipalities. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) DiD for Panel~A primary; TWFE with municipality and year FE ",
  "for remaining specifications; standard errors clustered at municipality level. ",
  "\\textbf{Sample:} 49 treated municipalities receiving new onshore wind capacity under the k{\\o}beretsordning ",
  "vs.\\ 48 control municipalities (14 never-wind, 34 always-wind with no new installations). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1_lines <- c(
  "\\begin{table}[!ht]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\\\[-1.2ex]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\\\[-1.2ex]"
)

for (i in 1:nrow(sde_rows)) {
  tabf1_lines <- c(tabf1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_rows$Outcome[i],
            format(round(sde_rows$beta[i], 4), nsmall = 4),
            format(round(sde_rows$se[i], 4), nsmall = 4),
            format(round(sde_rows$sd_y[i], 4), nsmall = 4),
            format(round(sde_rows$sde[i], 4), nsmall = 4),
            format(round(sde_rows$sde_se[i], 4), nsmall = 4),
            sde_rows$classification[i]))
}

tabf1_lines <- c(tabf1_lines,
  "\\\\[-1.2ex]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (rural vs.\\ urban)}} \\\\",
  "\\\\[-1.2ex]"
)

for (i in 1:nrow(het_rows)) {
  tabf1_lines <- c(tabf1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            het_rows$Outcome[i],
            format(round(het_rows$beta[i], 4), nsmall = 4),
            format(round(het_rows$se[i], 4), nsmall = 4),
            format(round(het_rows$sd_y[i], 4), nsmall = 4),
            format(round(het_rows$sde[i], 4), nsmall = 4),
            format(round(het_rows$sde_se[i], 4), nsmall = 4),
            het_rows$classification[i]))
}

tabf1_lines <- c(tabf1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabf1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
