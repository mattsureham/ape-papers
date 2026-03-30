# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================

source("00_packages.R")
library(fixest)
load("../data/model_results.RData")
load("../data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

panel[, total_pills_m := total_pills / 1e6]

stats_overall <- panel[, .(
  Variable = c("Total pills (millions)", "Cardinal pills (M)", "McKesson pills (M)",
               "AmerisourceBergen pills (M)", "Walgreens pills (M)",
               "Cardinal market share", "Pre-enforcement Cardinal share"),
  Mean = c(mean(total_pills_m, na.rm = TRUE),
           mean(Cardinal / 1e6, na.rm = TRUE),
           mean(McKesson / 1e6, na.rm = TRUE),
           mean(AmerisourceBergen / 1e6, na.rm = TRUE),
           mean(Walgreens / 1e6, na.rm = TRUE),
           mean(cardinal_share_t, na.rm = TRUE),
           mean(cardinal_share, na.rm = TRUE)),
  SD = c(sd(total_pills_m, na.rm = TRUE),
         sd(Cardinal / 1e6, na.rm = TRUE),
         sd(McKesson / 1e6, na.rm = TRUE),
         sd(AmerisourceBergen / 1e6, na.rm = TRUE),
         sd(Walgreens / 1e6, na.rm = TRUE),
         sd(cardinal_share_t, na.rm = TRUE),
         sd(cardinal_share, na.rm = TRUE))
)]

n_counties <- uniqueN(panel$county_id)
n_obs <- nrow(panel)

high_card <- panel[cardinal_share >= 0.20]
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: County-Quarter Opioid Pill Shipments, 2006--2012}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "& Mean & SD \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: All County-Quarters}} \\\\[3pt]"
)

for (i in 1:nrow(stats_overall)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.3f & %.3f \\\\", stats_overall$Variable[i],
            stats_overall$Mean[i], stats_overall$SD[i]))
}

tab1_lines <- c(tab1_lines,
  "{}[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: High-Cardinal Counties ($\\geq$ 20\\% pre-share)}} \\\\[3pt]",
  sprintf("Total pills (M), pre-2008 & %.3f & %.3f \\\\",
          mean(high_card[post == 0]$total_pills_m, na.rm = TRUE),
          sd(high_card[post == 0]$total_pills_m, na.rm = TRUE)),
  sprintf("Total pills (M), post-2008 & %.3f & %.3f \\\\",
          mean(high_card[post == 1]$total_pills_m, na.rm = TRUE),
          sd(high_card[post == 1]$total_pills_m, na.rm = TRUE)),
  sprintf("Cardinal share, pre-2008 & %.3f & %.3f \\\\",
          mean(high_card[post == 0]$cardinal_share_t, na.rm = TRUE),
          sd(high_card[post == 0]$cardinal_share_t, na.rm = TRUE)),
  sprintf("Cardinal share, post-2008 & %.3f & %.3f \\\\",
          mean(high_card[post == 1]$cardinal_share_t, na.rm = TRUE),
          sd(high_card[post == 1]$cardinal_share_t, na.rm = TRUE)),
  "\\hline",
  sprintf("County-quarter observations & \\multicolumn{2}{c}{%s} \\\\",
          format(n_obs, big.mark = ",")),
  sprintf("Counties & \\multicolumn{2}{c}{%s} \\\\",
          format(n_counties, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\par\\vspace{3pt}\\raggedright\\small",
  "\\textit{Notes:} Data from DEA ARCOS transaction records, 2006--2012. Each observation is a county-quarter. Pills measured in millions of dosage units (oxycodone + hydrocodone). Cardinal market share is the fraction of a county's total pill supply shipped by Cardinal Health distribution centers. Pre-enforcement share computed from 2006Q1--2007Q4. High-Cardinal counties are those with $\\geq$ 20\\% Cardinal share in the pre-period.",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================

cm <- c("cardinal_share:post" = "Cardinal Share $\\times$ Post")

etable(m1, m2, m3, m4, m5,
       headers = c("Log Total", "Log Total", "Log Cardinal",
                   "Log McKesson", "Log Amerisource"),
       se.below = TRUE, dict = cm, fitstat = c("n", "wr2"),
       tex = TRUE, style.tex = style.tex("aer"),
       title = "The Waterbed Effect: DEA Enforcement and Distributor-Level Pill Supply",
       label = "tab:waterbed",
       notes = c("All specifications include county and quarter fixed effects. Column (2) adds state $\\times$ quarter fixed effects. Standard errors clustered at the state level in parentheses. The dependent variable is log(pills + 1) at the county-quarter level. Cardinal Share is the pre-enforcement (2006--2007) county-level share of total opioid pills shipped by Cardinal Health. Post equals one for 2008Q1--2012Q4. * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       file = "../tables/tab2_waterbed.tex", replace = TRUE)
cat("Table 2 written.\n")

# =============================================================================
# Table 3: Event Study
# =============================================================================

etable(es_total, es_cardinal, es_mckesson,
       headers = c("Log Total", "Log Cardinal", "Log McKesson"),
       se.below = TRUE, fitstat = c("n", "wr2"),
       tex = TRUE, style.tex = style.tex("aer"),
       title = "Event Study: Year-by-Year Effects of Cardinal Exposure on Pill Supply",
       label = "tab:event_study",
       notes = c("Event study with county and quarter fixed effects. Each coefficient is the interaction of pre-enforcement Cardinal share with a year indicator (2007 omitted). Standard errors clustered at the state level. The pre-treatment coefficient (2006) tests the parallel trends assumption. * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       file = "../tables/tab3_event_study.tex", replace = TRUE)
cat("Table 3 written.\n")

# =============================================================================
# Table 4: Market Share Reallocation
# =============================================================================

cm4 <- c("cardinal_share:post" = "Cardinal Share $\\times$ Post")

etable(m_cs, m_ms, m_as,
       headers = c("Cardinal Share$_t$", "McKesson Share$_t$",
                   "Amerisource Share$_t$"),
       se.below = TRUE, dict = cm4, fitstat = c("n", "wr2"),
       tex = TRUE, style.tex = style.tex("aer"),
       title = "Market Share Reallocation After DEA Enforcement",
       label = "tab:reallocation",
       notes = c("Dependent variable is the within-quarter market share of each distributor in a county. County and quarter fixed effects. Standard errors clustered at the state level. A negative coefficient on Cardinal Share and positive coefficients on McKesson/AmerisourceBergen indicate supply chain reallocation---the waterbed effect. * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       file = "../tables/tab4_reallocation.tex", replace = TRUE)
cat("Table 4 written.\n")

# =============================================================================
# Table 5: Robustness
# =============================================================================

etable(placebo_m1, donut_m1, binary_m1, pretrend_test,
       headers = c("Placebo (McKesson)", "Donut (excl FL/WA/NJ)",
                   "Binary ($\\geq$20\\%)", "Pre-trend"),
       se.below = TRUE, fitstat = c("n", "wr2"),
       tex = TRUE, style.tex = style.tex("aer"),
       title = "Robustness Checks",
       label = "tab:robustness",
       notes = c("Column (1): Placebo test using McKesson pre-share as treatment (no enforcement action). Column (2): Drops Florida, Washington, and New Jersey (states with suspended Cardinal distribution centers). Column (3): Binary treatment at $\\geq$ 20\\% Cardinal share. Column (4): Pre-trend test using 2006 vs.~2007 (both pre-enforcement). All specifications include county and quarter fixed effects. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       file = "../tables/tab5_robustness.tex", replace = TRUE)
cat("Table 5 written.\n")

# =============================================================================
# SDE Table — max 6 rows (4 pooled + 2 heterogeneous)
# =============================================================================

sd_cardinal_share <- sd(panel$cardinal_share, na.rm = TRUE)
sd_log_total <- sd(panel[post == 0]$log_total_pills, na.rm = TRUE)
sd_log_cardinal <- sd(panel[post == 0]$log_cardinal, na.rm = TRUE)
sd_mckesson_share_t <- sd(panel[post == 0]$mckesson_share_t, na.rm = TRUE)
sd_cardinal_share_t <- sd(panel[post == 0]$cardinal_share_t, na.rm = TRUE)

# 4 pooled rows
sde_data <- data.table(
  outcome = c("Total pills (log)", "Cardinal pills (log)",
              "Cardinal market share", "McKesson market share"),
  beta = c(coef(m1)["cardinal_share:post"], coef(m3)["cardinal_share:post"],
           coef(m_cs)["cardinal_share:post"], coef(m_ms)["cardinal_share:post"]),
  se_beta = c(se(m1)["cardinal_share:post"], se(m3)["cardinal_share:post"],
              se(m_cs)["cardinal_share:post"], se(m_ms)["cardinal_share:post"]),
  sd_y = c(sd_log_total, sd_log_cardinal, sd_cardinal_share_t, sd_mckesson_share_t),
  sd_x = rep(sd_cardinal_share, 4)
)

sde_data[, sde := beta * sd_x / sd_y]
sde_data[, se_sde := se_beta * sd_x / sd_y]
sde_data[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# 2 heterogeneous rows
panel[, high_card_binary := cardinal_share >= median(cardinal_share, na.rm = TRUE)]

m_total_high <- feols(log_total_pills ~ cardinal_share:post | county_id + period,
                      data = panel[high_card_binary == TRUE], cluster = ~state)
m_total_low <- feols(log_total_pills ~ cardinal_share:post | county_id + period,
                     data = panel[high_card_binary == FALSE], cluster = ~state)

sde_het <- data.table(
  outcome = c("Total pills: Above-median Cardinal",
              "Total pills: Below-median Cardinal"),
  beta = c(coef(m_total_high)["cardinal_share:post"],
           coef(m_total_low)["cardinal_share:post"]),
  se_beta = c(se(m_total_high)["cardinal_share:post"],
              se(m_total_low)["cardinal_share:post"]),
  sd_y = c(sd(panel[high_card_binary == TRUE & post == 0]$log_total_pills, na.rm = TRUE),
           sd(panel[high_card_binary == FALSE & post == 0]$log_total_pills, na.rm = TRUE)),
  sd_x = c(sd(panel[high_card_binary == TRUE]$cardinal_share, na.rm = TRUE),
           sd(panel[high_card_binary == FALSE]$cardinal_share, na.rm = TRUE))
)
sde_het[, sde := beta * sd_x / sd_y]
sde_het[, se_sde := se_beta * sd_x / sd_y]
sde_het[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does DEA enforcement against a major pharmaceutical ",
  "distributor reduce total county-level opioid pill supply, or does supply reroute ",
  "through competing distributors (the waterbed effect)? ",
  "\\textbf{Policy mechanism:} The DEA suspended Cardinal Health distribution center ",
  "licenses in Florida, Washington, and New Jersey in late 2007 for failure to report ",
  "suspicious opioid orders, removing a major supply node from the pharmaceutical chain. ",
  "\\textbf{Outcome definition:} Log total opioid dosage units (oxycodone + hydrocodone) ",
  "shipped to county pharmacies per quarter, from DEA ARCOS transaction records. ",
  "\\textbf{Treatment:} Continuous; pre-enforcement (2006--2007) Cardinal Health share ",
  "of county-level total opioid pill shipments. ",
  "\\textbf{Data:} DEA ARCOS 178.6 million transactions, 2006--2012, county-quarter panel ",
  sprintf("with %s counties and %s observations. ",
          format(uniqueN(panel$county_id), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Two-way fixed effects (county + quarter); standard errors clustered at state level. ",
  "\\textbf{Sample:} All US counties with opioid shipment records in ARCOS, 2006--2012. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of ",
  "Cardinal pre-share and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(sde_data)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_data$outcome[i], sde_data$beta[i], sde_data$se_beta[i],
            sde_data$sd_y[i], sde_data$sde[i], sde_data$se_sde[i],
            sde_data$classification[i]))
}

sde_lines <- c(sde_lines,
  "{}[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]"
)

for (i in 1:nrow(sde_het)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_het$outcome[i], sde_het$beta[i], sde_het$se_beta[i],
            sde_het$sd_y[i], sde_het$sde[i], sde_het$se_sde[i],
            sde_het$classification[i]))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{3pt}\\raggedright\\small",
  sde_notes,
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")
cat(sprintf("SDE rows: %d pooled + %d heterogeneous = %d total\n",
            nrow(sde_data), nrow(sde_het), nrow(sde_data) + nrow(sde_het)))
cat("\nAll tables generated.\n")
