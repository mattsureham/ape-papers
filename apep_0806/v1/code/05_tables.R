## 05_tables.R — Generate all tables for paper
## apep_0806: Ireland Rent Pressure Zones

source("00_packages.R")

panel   <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob     <- readRDS("../data/robustness_results.rds")

# ── Table 1: Summary Statistics ──────────────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

pre_panel <- panel %>% filter(time_id < (2016 * 4 + 4))  # before 2016Q4

tab1_data <- panel %>%
  mutate(
    treat_wave = case_when(
      rpz_yq %in% c("2016Q4", "2017Q1") ~ "Early (Dec 2016--Jan 2017)",
      rpz_yq %in% c("2017Q3", "2018Q1", "2019Q1") ~ "Mid (Sep 2017--Jan 2019)",
      TRUE ~ "Late/National (Aug 2021)"
    )
  )

# Pre-treatment means by treatment wave
tab1 <- tab1_data %>%
  filter(time_id < (2016 * 4 + 4), !is.na(rent_growth_yy)) %>%
  group_by(treat_wave) %>%
  summarise(
    counties     = n_distinct(county),
    mean_rent    = mean(rent_eur),
    sd_rent      = sd(rent_eur),
    mean_growth  = mean(rent_growth_yy),
    sd_growth    = sd(rent_growth_yy),
    .groups = "drop"
  ) %>%
  bind_rows(
    tab1_data %>%
      filter(time_id < (2016 * 4 + 4), !is.na(rent_growth_yy)) %>%
      summarise(
        treat_wave = "All counties",
        counties = n_distinct(county),
        mean_rent = mean(rent_eur),
        sd_rent = sd(rent_eur),
        mean_growth = mean(rent_growth_yy),
        sd_growth = sd(rent_growth_yy)
      )
  )

# Generate LaTeX
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics by Treatment Wave}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & Counties & \\multicolumn{2}{c}{Monthly Rent (\\euro)} & \\multicolumn{2}{c}{YoY Growth (\\%)} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  " & & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(tab1)) {
  if (tab1$treat_wave[i] == "All counties") tab1_tex <- paste0(tab1_tex, "\\midrule\n")
  tab1_tex <- paste0(tab1_tex,
    tab1$treat_wave[i], " & ",
    tab1$counties[i], " & ",
    sprintf("%.0f", tab1$mean_rent[i]), " & ",
    sprintf("%.0f", tab1$sd_rent[i]), " & ",
    sprintf("%.1f", tab1$mean_growth[i]), " & ",
    sprintf("%.1f", tab1$sd_growth[i]), " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Pre-treatment period: 2012Q1--2016Q3. Monthly rent is the RTB/ESRI ",
  "standardised average monthly rent in euros. YoY growth is the year-on-year percentage change ",
  "in standardised average rent. Early counties include Dublin, Cork, Galway, and Kildare. ",
  "Mid counties include Louth, Meath, Wicklow, Limerick, Waterford, Kilkenny, Carlow, and Westmeath. ",
  "Late/National counties are the remaining 14 counties designated in August 2021. ",
  "Source: CSO PxStat table RIQ02.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Saved tab1_summary.tex\n")

# ── Table 2: Main Results ────────────────────────────────────────────────
cat("\n=== Table 2: Main Results ===\n")

# Extract C-S results
cs_level_att <- results$agg_overall$overall.att
cs_level_se  <- results$agg_overall$overall.se
cs_growth_att <- results$agg_growth_overall$overall.att
cs_growth_se  <- results$agg_growth_overall$overall.se

# TWFE results
twfe_level_coef <- coef(results$twfe)["post_rpz"]
twfe_level_se   <- sqrt(vcov(results$twfe)["post_rpz", "post_rpz"])

twfe_growth <- rob$twfe_growth
twfe_growth_coef <- coef(twfe_growth)["post_rpz"]
twfe_growth_se   <- sqrt(vcov(twfe_growth)["post_rpz", "post_rpz"])

# Sun-Abraham (saved as scalars in robustness results)
sa_att <- rob$sa_att
sa_se  <- rob$sa_se

sig_stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of RPZ Designation on Rents}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Log Rent Level} & \\multicolumn{2}{c}{YoY Rent Growth (\\%)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna (2021)}} \\\\\n",
  "[3pt]\n",
  "ATT & ",
  sprintf("%.4f", cs_level_att), sig_stars(cs_level_att, cs_level_se), " & & ",
  sprintf("%.2f", cs_growth_att), sig_stars(cs_growth_att, cs_growth_se), " & \\\\\n",
  " & (", sprintf("%.4f", cs_level_se), ") & & (",
  sprintf("%.2f", cs_growth_se), ") & \\\\\n",
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Sun-Abraham (2021)}} \\\\\n",
  "[3pt]\n",
  "ATT & & ",
  sprintf("%.4f", sa_att), sig_stars(sa_att, sa_se), " & & \\\\\n",
  " & & (", sprintf("%.4f", sa_se), ") & & \\\\\n",
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: TWFE (biased baseline)}} \\\\\n",
  "[3pt]\n",
  "Post RPZ & & & & ",
  sprintf("%.2f", twfe_growth_coef), sig_stars(twfe_growth_coef, twfe_growth_se), " \\\\\n",
  " & & & & (", sprintf("%.2f", twfe_growth_se), ") \\\\\n",
  "[3pt]\n",
  "\\midrule\n",
  "County FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Quarter FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Observations & ",
  format(nrow(panel), big.mark = ","), " & ",
  format(nrow(panel), big.mark = ","), " & ",
  format(sum(!is.na(panel$rent_growth_yy)), big.mark = ","), " & ",
  format(sum(!is.na(panel$rent_growth_yy)), big.mark = ","), " \\\\\n",
  "Counties & 26 & 26 & 26 & 26 \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panels A and B report heterogeneity-robust DiD estimates. ",
  "Panel A uses Callaway and Sant'Anna (2021) with not-yet-treated as the control group. ",
  "Panel B uses Sun and Abraham (2021). Panel C reports standard TWFE for comparison; ",
  "this estimator is biased under treatment effect heterogeneity with staggered adoption. ",
  "Standard errors clustered at the county level in parentheses. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Saved tab2_main.tex\n")

# ── Table 3: Cohort-Specific ATTs ────────────────────────────────────────
cat("\n=== Table 3: Cohort-Specific Effects ===\n")

cohort_growth <- rob$cs_group_growth

# Extract group-level results
g_data <- data.frame(
  group = cohort_growth$egt,
  att   = cohort_growth$att.egt,
  se    = cohort_growth$se.egt
)

# Map numeric group IDs to labels
cohort_map <- c(
  "8068" = "Dublin, Cork (2016Q4)",
  "8069" = "Galway, Kildare (2017Q1)",
  "8071" = "Louth, Meath, Wicklow (2017Q3)",
  "8073" = "Limerick (2018Q1)",
  "8077" = "Waterford, Kilkenny, Carlow, Westmeath (2019Q1)"
)

g_data$label <- cohort_map[as.character(g_data$group)]
g_data <- g_data %>% filter(!is.na(label))

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Cohort-Specific Effects on Year-on-Year Rent Growth}\n",
  "\\label{tab:cohort}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Treatment Cohort & Counties & ATT (pp) & SE & 95\\% CI \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(g_data)) {
  ci_lo <- g_data$att[i] - 1.96 * g_data$se[i]
  ci_hi <- g_data$att[i] + 1.96 * g_data$se[i]
  n_counties <- switch(as.character(g_data$group[i]),
    "8068" = 2, "8069" = 2, "8071" = 3, "8073" = 1, "8077" = 4
  )
  tab3_tex <- paste0(tab3_tex,
    g_data$label[i], " & ",
    n_counties, " & ",
    sprintf("%.2f", g_data$att[i]), sig_stars(g_data$att[i], g_data$se[i]), " & ",
    sprintf("%.2f", g_data$se[i]), " & [",
    sprintf("%.2f", ci_lo), ", ", sprintf("%.2f", ci_hi), "] \\\\\n"
  )
}

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "Overall & 12 & ",
  sprintf("%.2f", cohort_growth$overall.att), sig_stars(cohort_growth$overall.att, cohort_growth$overall.se), " & ",
  sprintf("%.2f", cohort_growth$overall.se), " & [",
  sprintf("%.2f", cohort_growth$overall.att - 1.96 * cohort_growth$overall.se), ", ",
  sprintf("%.2f", cohort_growth$overall.att + 1.96 * cohort_growth$overall.se), "] \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-level ATTs on year-on-year ",
  "rent growth (percentage points). Control group: not-yet-treated counties. ",
  "The Late/National cohort (14 counties, August 2021) has no clean not-yet-treated ",
  "control and is excluded. Standard errors use the multiplier bootstrap. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_cohort.tex")
cat("Saved tab3_cohort.tex\n")

# ── Table 4: Bacon Decomposition ─────────────────────────────────────────
cat("\n=== Table 4: Bacon Decomposition ===\n")

bacon_df <- as.data.frame(rob$bacon)
bacon_summary <- bacon_df %>%
  group_by(type) %>%
  summarise(
    n_pairs = n(),
    weight  = sum(weight),
    avg_est = sum(estimate * weight) / sum(weight),
    min_est = min(estimate),
    max_est = max(estimate),
    .groups = "drop"
  )

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Bacon Decomposition of TWFE Estimate}\n",
  "\\label{tab:bacon}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  "Comparison Type & Pairs & Weight & Avg.~Est. & Min & Max \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(bacon_summary)) {
  tab4_tex <- paste0(tab4_tex,
    bacon_summary$type[i], " & ",
    bacon_summary$n_pairs[i], " & ",
    sprintf("%.3f", bacon_summary$weight[i]), " & ",
    sprintf("%.4f", bacon_summary$avg_est[i]), " & ",
    sprintf("%.4f", bacon_summary$min_est[i]), " & ",
    sprintf("%.4f", bacon_summary$max_est[i]), " \\\\\n"
  )
}

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "TWFE overall & & 1.000 & ",
  sprintf("%.4f", twfe_level_coef), " & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Goodman-Bacon (2021) decomposition of the TWFE estimate ",
  "of RPZ designation on log rent levels. Since all counties are eventually treated by 2021Q3, ",
  "there are no never-treated units; all comparisons involve timing variation. ",
  "The positive TWFE estimate (+0.068) contrasts sharply with the near-zero ",
  "Callaway-Sant'Anna ATT ($-0.005$), illustrating how TWFE with staggered ",
  "adoption can produce misleading estimates.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_bacon.tex")
cat("Saved tab4_bacon.tex\n")

# ── Table F1: SDE Appendix ──────────────────────────────────────────────
cat("\n=== Table F1: Standardised Effect Sizes ===\n")

# Pre-treatment SD of outcomes
pre <- panel %>% filter(time_id < min(panel$first_treat))
sd_log_rent <- sd(pre$log_rent, na.rm = TRUE)
sd_yy_growth <- sd(pre$rent_growth_yy, na.rm = TRUE)

# SDE = beta / SD(Y)
sde_level  <- cs_level_att / sd_log_rent
sde_level_se <- cs_level_se / sd_log_rent
sde_growth <- cs_growth_att / sd_yy_growth
sde_growth_se <- cs_growth_se / sd_yy_growth

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
  "\\textbf{Country:} Ireland. ",
  "\\textbf{Research question:} Do Rent Pressure Zone designations, which cap annual ",
  "rent increases at 4\\%, reduce rent levels or rent growth in designated areas ",
  "relative to not-yet-designated areas? ",
  "\\textbf{Policy mechanism:} RPZ designation prohibits landlords from raising rents ",
  "on existing tenancies by more than 4\\% per annum in designated Local Electoral Areas; ",
  "new tenancies are subject to the same cap relative to the previous rent. ",
  "\\textbf{Outcome definition:} (1)~Log standardised average monthly rent (RTB/ESRI), ",
  "(2)~Year-on-year percentage change in standardised average monthly rent. ",
  "\\textbf{Treatment:} Binary --- county designated as RPZ at staggered dates from 2016Q4 to 2021Q3. ",
  "\\textbf{Data:} CSO PxStat table RIQ02, quarterly, county-level, 26 counties, ",
  "2012Q1--2025Q3, $N = 1{,}430$ county-quarters. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD; not-yet-treated ",
  "control group; standard errors via multiplier bootstrap clustered at county level. ",
  "\\textbf{Sample:} All 26 Irish counties; restricted to 2012Q1 onwards to avoid ",
  "post-crisis recovery distortion. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardised Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "Log rent level & ",
  sprintf("%.4f", cs_level_att), " & ",
  sprintf("%.4f", cs_level_se), " & ",
  sprintf("%.4f", sd_log_rent), " & ",
  sprintf("%.4f", sde_level), " & ",
  sprintf("%.4f", sde_level_se), " & ",
  classify_sde(sde_level), " \\\\\n",
  "YoY rent growth (\\%) & ",
  sprintf("%.2f", cs_growth_att), " & ",
  sprintf("%.2f", cs_growth_se), " & ",
  sprintf("%.2f", sd_yy_growth), " & ",
  sprintf("%.4f", sde_growth), " & ",
  sprintf("%.4f", sde_growth_se), " & ",
  classify_sde(sde_growth), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Saved tabF1_sde.tex\n")

# Print SDE values for reference
cat("\nSDE Summary:\n")
cat("  Log rent level: SDE =", sprintf("%.4f", sde_level),
    "->", classify_sde(sde_level), "\n")
cat("  YoY rent growth: SDE =", sprintf("%.4f", sde_growth),
    "->", classify_sde(sde_growth), "\n")

cat("\n✓ All tables generated\n")
