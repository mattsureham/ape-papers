# =============================================================================
# 05_tables.R — Generate LaTeX tables for paper
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
state_year_all <- readRDS("../data/state_year_all.rds")
state_year_race <- readRDS("../data/state_year_race.rds")
film_credits <- readRDS("../data/film_credits.rds")

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------

cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment stats
pre_data <- state_year_all %>%
  filter(year < first_treat | first_treat == 0) %>%
  filter(year >= 2001 & year <= 2004)

treated_pre <- pre_data %>% filter(first_treat > 0)
control_pre <- pre_data %>% filter(first_treat == 0)

make_row <- function(var, label, data) {
  x <- data[[var]]
  x <- x[!is.na(x)]
  c(label, sprintf("%.1f", mean(x)), sprintf("%.1f", sd(x)),
    sprintf("%.0f", min(x)), sprintf("%.0f", max(x)))
}

# Full sample stats (all years)
full_stats <- state_year_all %>% filter(!(state_abbr %in% c("NC","MI")))

tab1_rows <- rbind(
  c("\\textit{Panel A: Full sample}", "", "", "", ""),
  make_row("emp_512", "NAICS 512 employment", full_stats),
  make_row("log_emp_512", "Log NAICS 512 employment", full_stats),
  make_row("emp_share_512", "NAICS 512 share (per 1,000)", full_stats),
  make_row("hir_512", "Annual hires", full_stats),
  make_row("sep_512", "Annual separations", full_stats),
  c("", "", "", "", ""),
  c("\\textit{Panel B: Pre-treatment (2001--2004)}", "", "", "", ""),
  c("Treated states", sprintf("%.0f", n_distinct(treated_pre$state_fips)), "", "", ""),
  c("Control states", sprintf("%.0f", n_distinct(control_pre$state_fips)), "", "", ""),
  make_row("emp_512", "NAICS 512 employment (treated)", treated_pre),
  make_row("emp_512", "NAICS 512 employment (control)", control_pre)
)

n_obs <- nrow(full_stats)
n_states <- n_distinct(full_stats$state_fips)
n_years <- n_distinct(full_stats$year)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: NAICS 512 Employment}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  paste(apply(tab1_rows, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\n",
  sprintf("\\multicolumn{5}{l}{\\footnotesize Observations: %s state-years (%s states $\\times$ %s years).} \\\\\n",
          format(n_obs, big.mark=","), n_states, n_years),
  "\\multicolumn{5}{l}{\\footnotesize Source: QWI (LEHD), 2001--2024.} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------------------
# Table 2: Main Results — CS-DiD
# ---------------------------------------------------------------------------

cat("Generating Table 2: Main Results\n")

att_overall <- results$att_simple
att_black <- results$att_black
att_white <- results$att_white
att_hisp <- results$att_hisp
att_share <- results$att_share

format_coef <- function(att) {
  est <- att$overall.att
  se <- att$overall.se
  stars <- ifelse(abs(est/se) > 2.576, "^{***}",
           ifelse(abs(est/se) > 1.96, "^{**}",
           ifelse(abs(est/se) > 1.645, "^{*}", "")))
  c(sprintf("%.3f%s", est, stars), sprintf("(%.3f)", se))
}

overall_coef <- format_coef(att_overall)
black_coef <- format_coef(att_black)
white_coef <- format_coef(att_white)
hisp_coef <- format_coef(att_hisp)
share_coef <- format_coef(att_share)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Film Tax Credits on NAICS 512 Employment}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & All & Black & White & Hispanic & Share \\\\\n",
  " & \\multicolumn{4}{c}{Log Employment} & per 1,000 \\\\\n",
  "\\hline\n",
  sprintf("ATT & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          overall_coef[1], black_coef[1], white_coef[1], hisp_coef[1], share_coef[1]),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          overall_coef[2], black_coef[2], white_coef[2], hisp_coef[2], share_coef[2]),
  "\\hline\n",
  "Estimator & \\multicolumn{5}{c}{Callaway-Sant'Anna (2021)} \\\\\n",
  "Comparison & \\multicolumn{5}{c}{Never-treated} \\\\\n",
  "Clustering & \\multicolumn{5}{c}{State} \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{6}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Clustered SE at state level.} \\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize NC and MI excluded (credit repealed). Control: 13 never-treated states.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ---------------------------------------------------------------------------
# Table 3: Robustness — Placebo Sectors + TWFE/Sun-Abraham
# ---------------------------------------------------------------------------

cat("Generating Table 3: Robustness\n")

format_feols <- function(est) {
  ct <- coeftable(est)
  beta <- ct[1, "Estimate"]
  se <- ct[1, "Std. Error"]
  stars <- ifelse(abs(beta/se) > 2.576, "^{***}",
           ifelse(abs(beta/se) > 1.96, "^{**}",
           ifelse(abs(beta/se) > 1.645, "^{*}", "")))
  c(sprintf("%.3f%s", beta, stars), sprintf("(%.3f)", se))
}

twfe_coef <- format_feols(results$twfe_basic)
mfg_coef <- format_feols(rob_results$twfe_mfg)
fin_coef <- format_feols(rob_results$twfe_fin)
arts_coef <- format_feols(rob_results$twfe_arts)
gen_coef <- format_feols(rob_results$twfe_generous)
mod_coef <- format_feols(rob_results$twfe_modest)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Placebo Sectors and Credit Generosity}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  " & NAICS 512 & Manuf. & Finance & Arts & Generous & Modest \\\\\n",
  " & TWFE & Placebo & Placebo & Placebo & $\\geq$25\\% & 15--24\\% \\\\\n",
  "\\hline\n",
  sprintf("Treated $\\times$ Post & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          twfe_coef[1], mfg_coef[1], fin_coef[1], arts_coef[1], gen_coef[1], mod_coef[1]),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          twfe_coef[2], mfg_coef[2], fin_coef[2], arts_coef[2], gen_coef[2], mod_coef[2]),
  "\\hline\n",
  "State FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Year FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{7}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Clustered SE at state level. All outcomes in logs.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robustness.tex")

# ---------------------------------------------------------------------------
# Table 4: NC Repeal Analysis
# ---------------------------------------------------------------------------

cat("Generating Table 4: NC Repeal\n")

nc_credit_coef <- format_feols(rob_results$nc_did_credit)
nc_repeal_coef <- format_feols(rob_results$nc_did_repeal)
hir_coef <- format_feols(results$twfe_hir)
sep_coef <- format_feols(results$twfe_sep)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{North Carolina Repeal and Worker Flow Decomposition}\n",
  "\\label{tab:nc_flows}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & NC Credit & NC Repeal & Log Hires & Log Sep. \\\\\n",
  " & Adoption & Effect & (All states) & (All states) \\\\\n",
  "\\hline\n",
  sprintf("Treatment & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          nc_credit_coef[1], nc_repeal_coef[1], hir_coef[1], sep_coef[1]),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          nc_credit_coef[2], nc_repeal_coef[2], hir_coef[2], sep_coef[2]),
  "\\hline\n",
  "State FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Year FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Sample & NC + neighbors & NC + neighbors & All states & All states \\\\\n",
  "Period & 2001--2013 & 2009--2024 & 2001--2024 & 2001--2024 \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Clustered SE at state level.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize NC neighbors: SC, VA, TN, GA. Col.~(1): NC $\\times$ Post-2009.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Col.~(2): NC $\\times$ Post-2014 (repeal).} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_nc_flows.tex")

# ---------------------------------------------------------------------------
# Table F1: SDE Table (Appendix — Mandatory)
# ---------------------------------------------------------------------------

cat("Generating SDE Table\n")

# Get main results for SDE
att_main <- results$att_simple
att_blk <- results$att_black
att_wht <- results$att_white

# Pre-treatment SDs
pre_all <- state_year_all %>%
  filter(year < first_treat | first_treat == 0) %>%
  filter(year <= 2004, !(state_abbr %in% c("NC","MI")))

sd_log_emp <- sd(pre_all$log_emp_512, na.rm = TRUE)
sd_share <- sd(pre_all$emp_share_512, na.rm = TRUE)

# Black pre-treatment SD
pre_black <- state_year_race %>%
  filter(race_cat == "Black") %>%
  filter(year < first_treat | first_treat == 0) %>%
  filter(year <= 2004, !(state_abbr %in% c("NC","MI")))
sd_black <- sd(pre_black$log_emp_512, na.rm = TRUE)

# Calculate SDEs
calc_sde <- function(beta, se, sd_y) {
  sde <- beta / sd_y
  se_sde <- se / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

sde_all <- calc_sde(att_main$overall.att, att_main$overall.se, sd_log_emp)
sde_black <- calc_sde(att_blk$overall.att, att_blk$overall.se, sd_black)
sde_white <- calc_sde(att_wht$overall.att, att_wht$overall.se, sd_log_emp)
sde_share <- calc_sde(results$att_share$overall.att, results$att_share$overall.se, sd_share)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state film production tax credits increase motion picture industry employment, and do Black workers capture a proportional share of gains? ",
  "\\textbf{Policy mechanism:} State-level transferable or refundable tax credits (15--42\\% of qualified production expenditures) subsidize film, television, and commercial production, reducing location costs and attracting productions that would otherwise film in competing jurisdictions or countries. ",
  "\\textbf{Outcome definition:} Beginning-of-quarter employment count in NAICS 512 (Motion Picture and Sound Recording Industries) from the Quarterly Workforce Indicators, measured at the state-year level. ",
  "\\textbf{Treatment:} Binary; state-year adoption of a film production tax credit with rate $\\geq$ 15\\%. ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators (QWI), 2001--2024, 51 jurisdictions, state-year panel with race/ethnicity demographic breakdowns. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated comparison group; standard errors clustered at the state level. ",
  "\\textbf{Sample:} 37 treated states (excluding NC and MI, which repealed credits) and 13 never-treated states; NC repeal analyzed separately. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  sprintf("Log emp. (all) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          att_main$overall.att, att_main$overall.se, sd_log_emp,
          sde_all$sde, sde_all$se_sde, sde_all$bucket),
  sprintf("Log emp. (Black) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          att_blk$overall.att, att_blk$overall.se, sd_black,
          sde_black$sde, sde_black$se_sde, sde_black$bucket),
  sprintf("Log emp. (White) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          att_wht$overall.att, att_wht$overall.se, sd_log_emp,
          sde_white$sde, sde_white$se_sde, sde_white$bucket),
  sprintf("Emp. share & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          results$att_share$overall.att, results$att_share$overall.se, sd_share,
          sde_share$sde, sde_share$se_sde, sde_share$bucket),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated in ../tables/\n")
cat("05_tables.R complete.\n")
