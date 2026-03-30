## 05_tables.R — Generate all LaTeX tables
## apep_1169: Click to Incorporate

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment summary by treatment status
pre_panel <- panel %>%
  filter(ym < ifelse(treated_state, launch_ym, max(panel$ym)))

stats <- panel %>%
  group_by(treated_state) %>%
  summarise(
    `Mean BA` = mean(BA, na.rm = TRUE),
    `SD BA` = sd(BA, na.rm = TRUE),
    `Mean HBA` = mean(HBA, na.rm = TRUE),
    `SD HBA` = sd(HBA, na.rm = TRUE),
    `Mean WBA` = mean(WBA, na.rm = TRUE),
    `SD WBA` = sd(WBA, na.rm = TRUE),
    `N States` = n_distinct(state),
    `N Obs` = n(),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(treated_state, "Portal States", "Non-Portal States")) %>%
  select(Group, everything(), -treated_state)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Monthly Business Applications by State}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{All Applications} & \\multicolumn{2}{c}{High-Propensity} & \\multicolumn{2}{c}{Wage-Planned} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  " & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(stats)) {
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\\n",
            stats$Group[i],
            stats$`Mean BA`[i], stats$`SD BA`[i],
            stats$`Mean HBA`[i], stats$`SD HBA`[i],
            stats$`Mean WBA`[i], stats$`SD WBA`[i]))
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  sprintf("\\multicolumn{7}{l}{\\footnotesize Portal states: %d; Non-portal states: %d; ",
          stats$`N States`[stats$Group == "Portal States"],
          stats$`N States`[stats$Group == "Non-Portal States"]),
  sprintf("State-months: %s} \\\\\n",
          format(sum(stats$`N Obs`), big.mark = ",")),
  "\\multicolumn{7}{l}{\\footnotesize Source: Census Bureau Business Formation Statistics (FRED). July 2004--December 2024.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

# ============================================================
# Table 2: Main Results — CS ATT
# ============================================================

cat("=== Generating Table 2: Main Results ===\n")

att_wba <- results$att_wba
att_cba <- results$att_cba
att_ba <- results$att_ba
att_hba <- results$att_hba
twfe_wba <- results$twfe_wba
twfe_cba <- results$twfe_cba
twfe_ba <- results$twfe_ba
twfe_hba <- results$twfe_hba

add_stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  s <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.4f%s", est, s)
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of One-Stop Business Registration Portals on New Firm Applications}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & log(WBA) & log(CBA) & log(BA) & log(HBA) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna (2021)}} \\\\\n",
  sprintf("ATT & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          add_stars(att_wba$overall.att, att_wba$overall.se),
          add_stars(att_cba$overall.att, att_cba$overall.se),
          add_stars(att_ba$overall.att, att_ba$overall.se),
          add_stars(att_hba$overall.att, att_hba$overall.se)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          att_wba$overall.se, att_cba$overall.se, att_ba$overall.se, att_hba$overall.se),
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE (for comparison)}} \\\\\n",
  sprintf("Treated & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          add_stars(coef(twfe_wba)["treated"], se(twfe_wba)["treated"]),
          add_stars(coef(twfe_cba)["treated"], se(twfe_cba)["treated"]),
          add_stars(coef(twfe_ba)["treated"], se(twfe_ba)["treated"]),
          add_stars(coef(twfe_hba)["treated"], se(twfe_hba)["treated"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(twfe_wba)["treated"], se(twfe_cba)["treated"],
          se(twfe_ba)["treated"], se(twfe_hba)["treated"]),
  "\\hline\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("States & %d & %d & %d & %d \\\\\n",
          length(unique(panel$state)), length(unique(panel$state)),
          length(unique(panel$state)), length(unique(panel$state))),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nrow(panel), big.mark=","), format(nrow(panel), big.mark=","),
          format(nrow(panel), big.mark=","), format(nrow(panel), big.mark=",")),
  "\\hline\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$. Standard errors clustered by state.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Panel A: Callaway--Sant'Anna ATT with never-treated comparison group.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize WBA = wage-planned; CBA = corporate; BA = all; HBA = high-propensity.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 saved.\n")

# ============================================================
# Table 3: Robustness — LOO + Sun-Abraham
# ============================================================

cat("=== Generating Table 3: Robustness ===\n")

loo <- rob_results$loo
main_att <- att_wba$overall.att
main_se <- att_wba$overall.se

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Leave-One-Out and Alternative Estimators}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & ATT & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Out (log BA)}} \\\\\n"
)

for (i in 1:nrow(loo)) {
  tab3_tex <- paste0(tab3_tex,
    sprintf("Drop %s & %.4f & (%.4f) \\\\\n",
            loo$dropped[i], loo$att[i], loo$se[i]))
}

# Sun-Abraham
sa_att <- rob_results$sa_att

tab3_tex <- paste0(tab3_tex,
  "[6pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Alternative Estimators (log WBA)}} \\\\\n",
  sprintf("Callaway--Sant'Anna & %.4f & (%.4f) \\\\\n", main_att, main_se),
  sprintf("Sun--Abraham & %.4f & --- \\\\\n", sa_att),
  sprintf("TWFE & %.4f & (%.4f) \\\\\n",
          coef(results$twfe_wba)["treated"], se(results$twfe_wba)["treated"]),
  "\\hline\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize Standard errors clustered by state.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robust.tex")
cat("Table 3 saved.\n")

# ============================================================
# Table 4: Bacon Decomposition
# ============================================================

cat("=== Generating Table 4: Bacon Decomposition ===\n")

bacon <- rob_results$bacon

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Goodman-Bacon Decomposition of TWFE Estimate}\n",
  "\\label{tab:bacon}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Comparison Type & Weight & Weighted Estimate \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(bacon)) {
  tab4_tex <- paste0(tab4_tex,
    sprintf("%s & %.3f & %.4f \\\\\n",
            bacon$type[i], bacon$weight[i], bacon$weighted_est[i]))
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize Decomposition of the TWFE coefficient on log(BA).} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_bacon.tex")
cat("Table 4 saved.\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ============================================================

cat("=== Generating Table F1: SDE ===\n")

# Compute SDE for each outcome
# Use pre-treatment SD
pre_panel <- panel %>%
  filter(!treated_state | ym < launch_ym)

sd_ba_pre <- sd(pre_panel$log_BA, na.rm = TRUE)
sd_hba_pre <- sd(pre_panel$log_HBA, na.rm = TRUE)
sd_wba_pre <- sd(pre_panel$log_WBA, na.rm = TRUE)

sde_ba <- att_ba$overall.att / sd_ba_pre
sde_hba <- att_hba$overall.att / sd_hba_pre
sde_wba <- att_wba$overall.att / sd_wba_pre

se_sde_ba <- att_ba$overall.se / sd_ba_pre
se_sde_hba <- att_hba$overall.se / sd_hba_pre
se_sde_wba <- att_wba$overall.se / sd_wba_pre

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state adoption of integrated one-stop-shop online business registration portals increase new firm formation? ",
  "\\textbf{Policy mechanism:} Portals consolidate entity formation (Secretary of State), tax registration (Revenue), employer registration (Labor), and licensing into a single online interface, reducing the number of separate filings and agency visits required to start a business. ",
  "\\textbf{Outcome definition:} Monthly count of business applications (BA), high-propensity applications likely to become employer firms (HBA), and applications with planned wages (WBA), from Census Bureau Business Formation Statistics. ",
  "\\textbf{Treatment:} Binary; state-month indicator for whether the state has launched an integrated one-stop registration portal. ",
  "\\textbf{Data:} Census BFS via FRED, July 2004--December 2024, 51 state-level jurisdictions, ",
  format(nrow(panel), big.mark = ","), " state-months. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with never-treated comparison group; standard errors clustered at the state level. ",
  "\\textbf{Sample:} 11 treated states adopting portals between 2008 and 2022; 40 never-treated states as comparison. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of the log outcome. ",
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
  sprintf("log(BA) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          att_ba$overall.att, att_ba$overall.se, sd_ba_pre,
          sde_ba, se_sde_ba, classify_sde(sde_ba)),
  sprintf("log(HBA) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          att_hba$overall.att, att_hba$overall.se, sd_hba_pre,
          sde_hba, se_sde_hba, classify_sde(sde_hba)),
  sprintf("log(WBA) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          att_wba$overall.att, att_wba$overall.se, sd_wba_pre,
          sde_wba, se_sde_wba, classify_sde(sde_wba)),
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n"
)

# Heterogeneity: Early adopters vs late adopters
early_states <- c("VA","KY","NV","KS","MS")
late_states <- c("WI","PA","DE","CT","TX","AZ")

panel_early <- panel %>% filter(state %in% early_states | !treated_state)
panel_late <- panel %>% filter(state %in% late_states | !treated_state)

cs_early <- tryCatch({
  att_gt(yname = "log_BA", tname = "ym", idname = "state_id",
         gname = "first_treat", data = panel_early,
         control_group = "nevertreated", base_period = "universal",
         clustervars = "state_id", print_details = FALSE)
}, error = function(e) NULL)

cs_late <- tryCatch({
  att_gt(yname = "log_BA", tname = "ym", idname = "state_id",
         gname = "first_treat", data = panel_late,
         control_group = "nevertreated", base_period = "universal",
         clustervars = "state_id", print_details = FALSE)
}, error = function(e) NULL)

if (!is.null(cs_early)) {
  att_early <- aggte(cs_early, type = "simple")
  sde_early <- att_early$overall.att / sd_ba_pre
  se_sde_early <- att_early$overall.se / sd_ba_pre
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("Early adopters & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            att_early$overall.att, att_early$overall.se, sd_ba_pre,
            sde_early, se_sde_early, classify_sde(sde_early)))
}

if (!is.null(cs_late)) {
  att_late <- aggte(cs_late, type = "simple")
  sde_late <- att_late$overall.att / sd_ba_pre
  se_sde_late <- att_late$overall.se / sd_ba_pre
  tabF1_tex <- paste0(tabF1_tex,
    sprintf("Late adopters & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            att_late$overall.att, att_late$overall.se, sd_ba_pre,
            sde_late, se_sde_late, classify_sde(sde_late)))
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\begin{itemize}[leftmargin=*]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{minipage}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) saved.\n")

cat("ALL TABLES GENERATED.\n")
