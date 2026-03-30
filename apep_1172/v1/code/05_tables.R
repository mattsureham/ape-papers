## 05_tables.R — Generate all LaTeX tables
## apep_1172: Cage-Free Egg Mandates

source("00_packages.R")

analysis <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

pre_data <- analysis %>%
  filter(date < as.Date("2022-01-01"), !is.na(avg_layers_k))

sumstats <- pre_data %>%
  group_by(Group = ifelse(treated_state, "Mandate States", "Non-Mandate States")) %>%
  summarise(
    `Mean Layers (000s)` = sprintf("%.0f", mean(avg_layers_k, na.rm = TRUE)),
    `SD Layers` = sprintf("%.0f", sd(avg_layers_k, na.rm = TRUE)),
    `Mean Production (M eggs)` = sprintf("%.0f", mean(production_eggs, na.rm = TRUE)),
    `SD Production` = sprintf("%.0f", sd(production_eggs, na.rm = TRUE)),
    `Mean Eggs/100 Layers` = sprintf("%.1f", mean(eggs_per_100, na.rm = TRUE)),
    `SD Eggs/100` = sprintf("%.1f", sd(eggs_per_100, na.rm = TRUE)),
    `States` = as.character(n_distinct(state)),
    `State-Months` = as.character(n()),
    .groups = "drop"
  )

# Build LaTeX table manually for precise control
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Mandate Period (2010--2021)}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Mandate States & Non-Mandate States \\\\\n",
  "\\hline\n"
)

# Add rows
for (i in 2:ncol(sumstats)) {
  col_name <- names(sumstats)[i]
  tab1 <- paste0(tab1, col_name, " & ", sumstats[[i]][1], " & ", sumstats[[i]][2], " \\\\\n")
}

tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-mandate period summary statistics for egg-producing states ",
  "reporting to USDA NASS monthly Chickens and Eggs surveys, 2010--2021. Mandate states ",
  "are those that enacted cage-free egg requirements with effective dates between 2022 and 2026. ",
  "Layers measured in thousands; production in million eggs.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ============================================================
# Table 2: Main Results — Callaway-Sant'Anna
# ============================================================

cat("=== Generating Table 2: Main Results ===\n")

att_layers <- results$agg_overall_layers
att_prod <- results$agg_overall_prod
att_epl <- results$agg_overall_epl

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# P-values from CS
p_layers <- 2 * pnorm(-abs(att_layers$overall.att / att_layers$overall.se))
p_prod <- 2 * pnorm(-abs(att_prod$overall.att / att_prod$overall.se))
p_epl <- 2 * pnorm(-abs(att_epl$overall.att / att_epl$overall.se))

# TWFE comparison
twfe_l <- results$twfe_layers
twfe_p <- results$twfe_prod
twfe_e <- results$twfe_epl

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Cage-Free Mandates on Egg Production}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Log Layers & Log Production & Log Eggs/100 \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\\n",
  "{}[3pt]\n",
  "ATT & ", sprintf("%.4f", att_layers$overall.att), stars(p_layers),
  " & ", sprintf("%.4f", att_prod$overall.att), stars(p_prod),
  " & ", sprintf("%.4f", att_epl$overall.att), stars(p_epl), " \\\\\n",
  " & (", sprintf("%.4f", att_layers$overall.se), ")",
  " & (", sprintf("%.4f", att_prod$overall.se), ")",
  " & (", sprintf("%.4f", att_epl$overall.se), ") \\\\\n",
  "{}[6pt]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\\n",
  "{}[3pt]\n",
  "Post $\\times$ Mandate & ", sprintf("%.4f", coef(twfe_l)["post"]),
  stars(pvalue(twfe_l)["post"]),
  " & ", sprintf("%.4f", coef(twfe_p)["post"]),
  stars(pvalue(twfe_p)["post"]),
  " & ", sprintf("%.4f", coef(twfe_e)["post"]),
  stars(pvalue(twfe_e)["post"]), " \\\\\n",
  " & (", sprintf("%.4f", se(twfe_l)["post"]), ")",
  " & (", sprintf("%.4f", se(twfe_p)["post"]), ")",
  " & (", sprintf("%.4f", se(twfe_e)["post"]), ") \\\\\n",
  "{}[6pt]\n",
  "\\hline\n",
  "State FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nrow(results$yearly %>% filter(!is.na(ln_layers))), big.mark = ","), " & ",
  format(nrow(results$yearly %>% filter(!is.na(ln_production))), big.mark = ","), " & ",
  format(nrow(results$yearly %>% filter(!is.na(ln_eggs_per_100))), big.mark = ","), " \\\\\n",
  "States & ", n_distinct(results$yearly$state[!is.na(results$yearly$ln_layers)]), " & ",
  n_distinct(results$yearly$state[!is.na(results$yearly$ln_production)]), " & ",
  n_distinct(results$yearly$state[!is.na(results$yearly$ln_eggs_per_100)]), " \\\\\n",
  "Treated States & ", n_distinct(results$yearly$state[results$yearly$treated_state & !is.na(results$yearly$ln_layers)]), " & ",
  n_distinct(results$yearly$state[results$yearly$treated_state & !is.na(results$yearly$ln_production)]), " & ",
  n_distinct(results$yearly$state[results$yearly$treated_state & !is.na(results$yearly$ln_eggs_per_100)]), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports Callaway--Sant'Anna (2021) ATT estimates using ",
  "doubly-robust estimation with never-treated states as the control group and a universal ",
  "base period. Panel B reports standard TWFE estimates with state-clustered standard errors. ",
  "Outcomes are in logs; coefficients approximate percentage changes. Mandate states: ",
  "CA (2022), MA (2023), WA/OR/NV (2024), CO/AZ/MI/UT (2025). ",
  "Year fixed effects absorb national shocks including avian influenza outbreaks. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# Table 3: Robustness
# ============================================================

cat("=== Generating Table 3: Robustness ===\n")

# Collect robustness results for layers
rob_no_ca <- rob_results$no_ca
rob_nyt <- rob_results$nyt
rob_wcb <- rob_results$wcb_layers

# Sun-Abraham
sa_coefs <- coef(results$sa_layers)
sa_post <- sa_coefs[grepl("time_index::", names(sa_coefs))]
sa_att <- mean(sa_post[as.numeric(gsub("time_index::", "", names(sa_post))) >= 0], na.rm = TRUE)

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Log Layers}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & ATT & SE \\\\\n",
  "\\hline\n",
  "Baseline (CS, never-treated) & ", sprintf("%.4f", att_layers$overall.att),
  stars(p_layers), " & (", sprintf("%.4f", att_layers$overall.se), ") \\\\\n",
  "Not-yet-treated control & ", sprintf("%.4f", rob_nyt$att),
  " & (", sprintf("%.4f", rob_nyt$se), ") \\\\\n",
  "Drop California & ", sprintf("%.4f", rob_no_ca$att),
  " & (", sprintf("%.4f", rob_no_ca$se), ") \\\\\n",
  "TWFE & ", sprintf("%.4f", coef(twfe_l)["post"]),
  stars(pvalue(twfe_l)["post"]),
  " & (", sprintf("%.4f", se(twfe_l)["post"]), ") \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Wild cluster bootstrap (TWFE)}} \\\\\n",
  "\\quad $p$-value & \\multicolumn{2}{c}{", sprintf("%.3f", rob_wcb$p), "} \\\\\n",
  "\\quad 95\\% CI & \\multicolumn{2}{c}{[", sprintf("%.4f", rob_wcb$ci[1]),
  ", ", sprintf("%.4f", rob_wcb$ci[2]), "]} \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Placebo outcome}} \\\\\n",
  "Eggs per 100 layers & ", sprintf("%.4f", rob_results$placebo_epl$att),
  " & (", sprintf("%.4f", rob_results$placebo_epl$se), ") \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications use log layers as the outcome. ",
  "Baseline uses Callaway--Sant'Anna (2021) with never-treated controls and doubly-robust estimation. ",
  "``Not-yet-treated'' uses states that adopt mandates later as controls. ",
  "``Drop California'' removes the largest and earliest-adopting state. ",
  "Wild cluster bootstrap uses Webb weights with 9,999 iterations. ",
  "Eggs per 100 layers is a placebo outcome: mandates regulate housing conditions, ",
  "not per-hen productivity; a null here supports the displacement mechanism.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robust.tex")

# ============================================================
# Table 4: Cohort-Specific Effects
# ============================================================

cat("=== Generating Table 4: Cohort Effects ===\n")

group_atts <- results$agg_group_layers
group_df <- data.frame(
  group = group_atts$egt,
  att = group_atts$att.egt,
  se = group_atts$se.egt
)

# Map month index back to year
group_df <- group_df %>%
  mutate(
    cohort_year = group,  # egt values are already years
    p = 2 * pnorm(-abs(att / se))
  )

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Cohort-Specific Effects: Log Layers}\n",
  "\\label{tab:cohort}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Cohort & ATT & SE \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(group_df)) {
  cohort_label <- switch(as.character(group_df$cohort_year[i]),
    "2022" = "2022 (CA)",
    "2023" = "2023 (MA)",
    "2024" = "2024 (WA, OR, NV)",
    "2025" = "2025 (CO, AZ, MI, UT)",
    paste0(group_df$cohort_year[i])
  )
  tab4 <- paste0(tab4, cohort_label, " & ",
    sprintf("%.4f", group_df$att[i]), stars(group_df$p[i]),
    " & (", sprintf("%.4f", group_df$se[i]), ") \\\\\n")
}

tab4 <- paste0(tab4,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Callaway--Sant'Anna group-specific ATT estimates. ",
  "Each row reports the average treatment effect for states in that adoption cohort. ",
  "Standard errors in parentheses, clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_cohort.tex")

# ============================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================

cat("=== Generating Table F1: SDE ===\n")

# Pre-treatment SDs for SDE calculation
pre_sds <- analysis %>%
  filter(date < as.Date("2022-01-01"), treated_state) %>%
  summarise(
    sd_ln_layers = sd(ln_layers, na.rm = TRUE),
    sd_ln_production = sd(ln_production, na.rm = TRUE),
    sd_ln_epl = sd(ln_eggs_per_100, na.rm = TRUE)
  )

# SDE = beta / SD(Y) for binary treatment
sde_layers <- att_layers$overall.att / pre_sds$sd_ln_layers
sde_se_layers <- att_layers$overall.se / pre_sds$sd_ln_layers

sde_prod <- att_prod$overall.att / pre_sds$sd_ln_production
sde_se_prod <- att_prod$overall.se / pre_sds$sd_ln_production

sde_epl <- att_epl$overall.att / pre_sds$sd_ln_epl
sde_se_epl <- att_epl$overall.se / pre_sds$sd_ln_epl

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# --- Heterogeneous effects: Large vs Small producing states (yearly) ---
yearly <- results$yearly

median_layers <- yearly %>%
  filter(year < 2022, treated_state) %>%
  group_by(state) %>%
  summarise(mean_layers = mean(avg_layers_k, na.rm = TRUE), .groups = "drop") %>%
  pull(mean_layers) %>%
  median()

# Large producers
large_data <- yearly %>%
  filter(!is.na(ln_layers)) %>%
  group_by(state) %>%
  mutate(mean_pre_layers = mean(avg_layers_k[year < 2022], na.rm = TRUE)) %>%
  ungroup() %>%
  filter(mean_pre_layers >= median_layers)

cs_large <- att_gt(
  yname = "ln_layers", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = large_data,
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
agg_large <- aggte(cs_large, type = "simple")
sd_large <- sd(large_data$ln_layers[large_data$year < 2022 & large_data$treated_state], na.rm = TRUE)
sde_large <- agg_large$overall.att / sd_large
sde_se_large <- agg_large$overall.se / sd_large

# Small producers
small_data <- yearly %>%
  filter(!is.na(ln_layers)) %>%
  group_by(state) %>%
  mutate(mean_pre_layers = mean(avg_layers_k[year < 2022], na.rm = TRUE)) %>%
  ungroup() %>%
  filter(mean_pre_layers < median_layers)

cs_small <- att_gt(
  yname = "ln_layers", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = small_data,
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
agg_small <- aggte(cs_small, type = "simple")
sd_small <- sd(small_data$ln_layers[small_data$year < 2022 & small_data$treated_state], na.rm = TRUE)
sde_small <- agg_small$overall.att / sd_small
sde_se_small <- agg_small$overall.se / sd_small

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level cage-free egg mandates reduce ",
  "in-state egg production by displacing conventional laying operations? ",
  "\\textbf{Policy mechanism:} State laws require all shell eggs sold within ",
  "state borders to come from cage-free housing systems, raising per-hen capital ",
  "costs and eliminating conventional battery-cage production as a legal option ",
  "for in-state sales. ",
  "\\textbf{Outcome definition:} Log average number of egg-laying hens (thousands) ",
  "from USDA NASS monthly Chickens and Eggs surveys; log total egg production ",
  "(million eggs); log eggs per 100 layers (hen productivity). ",
  "\\textbf{Treatment:} Binary; equals one in state-months after the cage-free ",
  "mandate effective date. ",
  "\\textbf{Data:} USDA NASS monthly Chickens and Eggs reports aggregated to ",
  "state-year level, 2010--2026, approximately ", format(nrow(results$yearly %>% filter(!is.na(ln_layers))), big.mark = ","),
  " observations across ", n_distinct(results$yearly$state[!is.na(results$yearly$ln_layers)]), " states. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with doubly-robust ",
  "estimation, never-treated control group, universal base period; standard errors ",
  "clustered at the state level. ",
  "\\textbf{Sample:} States reporting monthly egg production to USDA NASS; excludes ",
  "states with incomplete reporting histories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated states. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "{}[3pt]\n",
  "Log Layers & ", sprintf("%.4f", att_layers$overall.att),
  " & ", sprintf("%.4f", att_layers$overall.se),
  " & ", sprintf("%.4f", pre_sds$sd_ln_layers),
  " & ", sprintf("%.4f", sde_layers),
  " & ", sprintf("%.4f", sde_se_layers),
  " & ", classify_sde(sde_layers), " \\\\\n",
  "Log Production & ", sprintf("%.4f", att_prod$overall.att),
  " & ", sprintf("%.4f", att_prod$overall.se),
  " & ", sprintf("%.4f", pre_sds$sd_ln_production),
  " & ", sprintf("%.4f", sde_prod),
  " & ", sprintf("%.4f", sde_se_prod),
  " & ", classify_sde(sde_prod), " \\\\\n",
  "Log Eggs/100 Layers & ", sprintf("%.4f", att_epl$overall.att),
  " & ", sprintf("%.4f", att_epl$overall.se),
  " & ", sprintf("%.4f", pre_sds$sd_ln_epl),
  " & ", sprintf("%.4f", sde_epl),
  " & ", sprintf("%.4f", sde_se_epl),
  " & ", classify_sde(sde_epl), " \\\\\n",
  "{}[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment flock size)}} \\\\\n",
  "{}[3pt]\n",
  "Large producers & ", sprintf("%.4f", agg_large$overall.att),
  " & ", sprintf("%.4f", agg_large$overall.se),
  " & ", sprintf("%.4f", sd_large),
  " & ", sprintf("%.4f", sde_large),
  " & ", sprintf("%.4f", sde_se_large),
  " & ", classify_sde(sde_large), " \\\\\n",
  "Small producers & ", sprintf("%.4f", agg_small$overall.att),
  " & ", sprintf("%.4f", agg_small$overall.se),
  " & ", sprintf("%.4f", sd_small),
  " & ", sprintf("%.4f", sde_small),
  " & ", sprintf("%.4f", sde_se_small),
  " & ", classify_sde(sde_small), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.5em}\n",
  "{\\scriptsize \\textit{Notes:} ", gsub("\\\\item \\\\textit\\{Notes:\\} ", "", sde_notes), "}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_robust.tex\n")
cat("  tab4_cohort.tex\n")
cat("  tabF1_sde.tex\n")
