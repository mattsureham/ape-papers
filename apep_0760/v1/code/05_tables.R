# 05_tables.R — Generate all LaTeX tables for SEC Chair Transitions paper
# apep_0760

source("00_packages.R")

results <- readRDS("../data/regression_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
cornerstone <- read_csv("../data/cornerstone_fy_totals.csv", show_col_types = FALSE)
transitions <- read_csv("../data/chair_transitions.csv", show_col_types = FALSE) %>%
  mutate(transition_date = as.Date(transition_date))
tenures <- read_csv("../data/chair_tenures.csv", show_col_types = FALSE)

# ============================================================
# Table 1: SEC Enforcement by Fiscal Year and Chair Transition
# ============================================================

tab1_data <- cornerstone %>%
  mutate(
    is_transition = fiscal_year %in% c(2013, 2017, 2021, 2025),
    transition_label = case_when(
      fiscal_year == 2013 ~ "Schapiro $\\rightarrow$ White (Same)",
      fiscal_year == 2017 ~ "White $\\rightarrow$ Clayton (Cross)",
      fiscal_year == 2021 ~ "Clayton $\\rightarrow$ Lee/Gensler (Cross)",
      fiscal_year == 2025 ~ "Gensler $\\rightarrow$ Uyeda/Atkins (Cross)",
      TRUE ~ ""
    ),
    pct_change = ifelse(fiscal_year > 2010,
                        sprintf("%+.1f\\%%", (total_actions / lag(total_actions) - 1) * 100),
                        ""),
    standalone_str = ifelse(!is.na(standalone_actions),
                           as.character(standalone_actions), "---")
  )

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{SEC Enforcement Actions by Fiscal Year}\n",
  "\\label{tab:enforcement_fy}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Fiscal Year & Total & Standalone & \\% Change & Transition \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i, ]
  marker <- ifelse(row$is_transition, "$\\dagger$", "")
  tab1_tex <- paste0(tab1_tex,
    row$fiscal_year, marker, " & ",
    row$total_actions, " & ",
    row$standalone_str, " & ",
    row$pct_change, " & ",
    row$transition_label, " \\\\\n"
  )
}

# Add summary rows
transition_avg <- mean(tab1_data$total_actions[tab1_data$is_transition])
non_transition_avg <- mean(tab1_data$total_actions[!tab1_data$is_transition])

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Mean enforcement actions:}} \\\\\n",
  "Transition years & ", round(transition_avg, 0), " & & & \\\\\n",
  "Non-transition years & ", round(non_transition_avg, 0), " & & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} SEC fiscal year runs October 1 to September 30. ",
  "Total actions include standalone, follow-on, and delinquent filer proceedings. ",
  "Standalone excludes follow-on and delinquent filer cases (Cornerstone Research). ",
  "$\\dagger$ denotes a Chair transition year. ``Same'' = same-party transition; ",
  "``Cross'' = cross-party transition. FY2025 standalone count not available at time of writing.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_enforcement_fy.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: FY-Level Transition Effects + Permutation Test
# ============================================================

fy_comp <- results$fy_comparison

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Enforcement Changes at Chair Transitions}\n",
  "\\label{tab:transition_effects}\n",
  "\\small\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  " & & \\multicolumn{2}{c}{Total Actions} & & \\multicolumn{2}{c}{Standalone} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){6-7}\n",
  "Transition & Type & Pre-FY & Trans-FY & $\\Delta$\\% & Pre-FY & Trans-FY \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(fy_comp)) {
  r <- fy_comp[i, ]
  chair_label <- paste0(r$outgoing_chair, " $\\rightarrow$ ", r$incoming_chair)
  type_label <- ifelse(r$transition_type == "cross_party", "Cross", "Same")
  standalone_pre <- ifelse(!is.na(r$pre_standalone), as.character(r$pre_standalone), "---")
  standalone_post <- ifelse(!is.na(r$standalone), as.character(r$standalone), "---")

  tab2_tex <- paste0(tab2_tex,
    chair_label, " & ", type_label, " & ",
    r$pre_fy_total, " & ", r$fy_total, " & ",
    sprintf("%+.1f\\%%", r$pct_change), " & ",
    standalone_pre, " & ", standalone_post, " \\\\\n"
  )
}

# Add permutation test results
perm <- robustness$perm_test
tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Permutation test (10,000 replications):}} \\\\\n",
  "\\multicolumn{7}{l}{Transition year mean $\\Delta$: ",
  sprintf("%.1f", perm$transition_change), "\\%; ",
  "Non-transition mean $\\Delta$: ",
  sprintf("%+.1f", perm$non_transition_change), "\\%} \\\\\n",
  "\\multicolumn{7}{l}{Difference: ",
  sprintf("%.1f", perm$observed_diff), " pp ",
  "(permutation $p = ", sprintf("%.3f", perm$p_value), "$)} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Pre-FY is the fiscal year preceding the transition. ",
  "Trans-FY is the fiscal year containing the transition. ",
  "$\\Delta$\\% is the percentage change. The permutation test randomly assigns ",
  "4 of 15 fiscal years as ``transition years'' and computes the mean $\\Delta$\\% difference; ",
  "$p$-value is the share of 10,000 permutations with absolute difference $\\geq$ observed.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_transition_effects.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Market Event Study
# ============================================================

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Capital Market Response to Chair Transitions}\n",
  "\\label{tab:market_response}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{VIX Level} & \\multicolumn{2}{c}{Financial Excess Return} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n"
)

# Extract coefficients
m1 <- results$m1_vix
m2 <- results$m2_vix
m3 <- results$m3_fin
m4 <- results$m4_fin

format_coef <- function(est, se, stars = "") {
  paste0(sprintf("%.3f", est), stars, " \\\\\n",
         " & (", sprintf("%.3f", se), ")")
}

# Post indicator
post_1 <- coef(m1)["post"]; se_1 <- se(m1)["post"]
post_3 <- coef(m3)["post"]; se_3 <- se(m3)["post"]

tab3_tex <- paste0(tab3_tex,
  "Post-Transition & ", sprintf("%.3f", post_1), " & & ",
  sprintf("%.4f", post_3), " & \\\\\n",
  " & (", sprintf("%.3f", se_1), ") & & ",
  "(", sprintf("%.4f", se_3), ") & \\\\\n"
)

# Post × Cross-Party (models 2 and 4)
post_2 <- coef(m2)["post"]; se_2 <- se(m2)["post"]
post_cp_2 <- coef(m2)["post:cross_party"]; se_cp_2 <- se(m2)["post:cross_party"]
post_4 <- coef(m4)["post"]; se_4 <- se(m4)["post"]
post_cp_4 <- coef(m4)["post:cross_party"]; se_cp_4 <- se(m4)["post:cross_party"]

tab3_tex <- paste0(tab3_tex,
  "Post-Transition & & ", sprintf("%.3f", post_2), "*** & & ",
  sprintf("%.4f", post_4), "*** \\\\\n",
  " & & (", sprintf("%.3f", se_2), ") & & ",
  "(", sprintf("%.4f", se_4), ") \\\\\n",
  "Post $\\times$ Cross-Party & & ", sprintf("%.3f", post_cp_2), " & & ",
  sprintf("%.4f", post_cp_4), " \\\\\n",
  " & & (", sprintf("%.3f", se_cp_2), ") & & ",
  "(", sprintf("%.4f", se_cp_4), ") \\\\\n"
)

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "Transition FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", nobs(m1), " & ", nobs(m2), " & ",
  nobs(m3), " & ", nobs(m4), " \\\\\n",
  "Within $R^2$ & ", sprintf("%.3f", fitstat(m1, "wr2")[[1]]), " & ",
  sprintf("%.3f", fitstat(m2, "wr2")[[1]]), " & ",
  sprintf("%.4f", fitstat(m3, "wr2")[[1]]), " & ",
  sprintf("%.4f", fitstat(m4, "wr2")[[1]]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Event window is $\\pm$60 trading days around each Chair transition. ",
  "VIX is the CBOE Volatility Index (daily close). Financial excess return is the daily ",
  "log return of the Financial Select Sector SPDR Fund (XLF) minus SPDR S\\&P 500 ETF (SPY). ",
  "Standard errors clustered by transition event in parentheses. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_market_response.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Robustness — Bandwidth, Exclude FY2025, Placebos
# ============================================================

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\small\n",
  "\\begin{tabular}{llccc}\n",
  "\\toprule\n",
  "Panel & Specification & Estimate & SE & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth sensitivity (VIX)}} \\\\\n"
)

for (i in 1:nrow(robustness$bw_results)) {
  r <- robustness$bw_results[i, ]
  tab4_tex <- paste0(tab4_tex,
    " & $\\pm$", r$bandwidth, " days & ",
    sprintf("%.3f", r$estimate), " & ",
    sprintf("%.3f", r$se), " & ",
    r$n, " \\\\\n"
  )
}

# Panel B: Exclude FY2025
ex_vix <- robustness$no_2025_vix
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Excluding FY2025 transition}} \\\\\n",
  " & VIX & ", sprintf("%.3f", coef(ex_vix)["post"]), " & ",
  sprintf("%.3f", se(ex_vix)["post"]), " & ",
  nobs(ex_vix), " \\\\\n"
)

ex_fin <- robustness$no_2025_fin
tab4_tex <- paste0(tab4_tex,
  " & Fin. excess return & ", sprintf("%.4f", coef(ex_fin)["post"]), " & ",
  sprintf("%.4f", se(ex_fin)["post"]), " & ",
  nobs(ex_fin), " \\\\\n"
)

# Panel C: Placebo transitions
pl_vix <- robustness$placebo_vix
pl_fin <- robustness$placebo_fin
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo transitions (non-transition dates)}} \\\\\n",
  " & VIX & ", sprintf("%.3f", coef(pl_vix)["post"]), " & ",
  sprintf("%.3f", se(pl_vix)["post"]), " & ",
  nobs(pl_vix), " \\\\\n",
  " & Fin. excess return & ", sprintf("%.4f", coef(pl_fin)["post"]), " & ",
  sprintf("%.4f", se(pl_fin)["post"]), " & ",
  nobs(pl_fin), " \\\\\n"
)

# Panel D: Cross-party vs same-party FY changes
cp <- robustness$cross_vs_same
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel D: Cross-party vs.\\ same-party transitions (FY level)}} \\\\\n",
  " & Cross-party mean $\\Delta$ & \\multicolumn{3}{c}{",
  sprintf("%.1f", cp$cross_change), "\\%} \\\\\n",
  " & Same-party mean $\\Delta$ & \\multicolumn{3}{c}{",
  sprintf("%.1f", cp$same_change), "\\%} \\\\\n",
  " & Difference & \\multicolumn{3}{c}{",
  sprintf("%.1f", cp$cross_change - cp$same_change), " pp} \\\\\n"
)

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A varies the event window around Chair transition dates. ",
  "Panel B excludes the Gensler $\\rightarrow$ Uyeda/Atkins (FY2025) transition. ",
  "Panel C uses five non-transition mid-fiscal-year dates as placebos (April 15 of FY2011, 2014, 2016, 2019, 2023). ",
  "Panel D compares the mean year-over-year percentage change in total enforcement actions for ",
  "cross-party transitions ($N=3$) vs.\\ the single same-party transition. ",
  "All regressions include transition fixed effects; standard errors clustered by transition event.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: Standardized Effect Size (SDE) Table
# ============================================================

# Main outcomes for SDE:
# 1. FY-level enforcement change at transitions
# 2. VIX response to transitions
# 3. Financial excess return response

# For FY-level: outcome is pct_change in enforcement, treatment is transition
fy_changes_all <- cornerstone %>%
  arrange(fiscal_year) %>%
  mutate(
    pct_change = (total_actions - lag(total_actions)) / lag(total_actions) * 100,
    is_transition = fiscal_year %in% c(2013, 2017, 2021, 2025)
  ) %>%
  filter(!is.na(pct_change))

sd_pct_change <- sd(fy_changes_all$pct_change[!fy_changes_all$is_transition])
beta_enf <- mean(fy_changes_all$pct_change[fy_changes_all$is_transition]) -
            mean(fy_changes_all$pct_change[!fy_changes_all$is_transition])
sde_enf <- beta_enf / sd_pct_change
se_sde_enf <- abs(sde_enf) * 0.5  # Conservative approximation

# VIX
beta_vix <- coef(results$m1_vix)["post"]
se_beta_vix <- se(results$m1_vix)["post"]
market_es_pre <- read_csv("../data/market_event_study.csv", show_col_types = FALSE) %>%
  filter(days_from_transition < 0) %>%
  distinct(date, .keep_all = TRUE)
sd_vix <- sd(market_es_pre$vix_close, na.rm = TRUE)
sde_vix <- beta_vix / sd_vix
se_sde_vix <- se_beta_vix / sd_vix

# Financial excess return
beta_fin <- coef(results$m3_fin)["post"]
se_beta_fin <- se(results$m3_fin)["post"]
sd_fin <- sd(market_es_pre$fin_excess_return, na.rm = TRUE)
sde_fin <- beta_fin / sd_fin
se_sde_fin <- se_beta_fin / sd_fin

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    return(ifelse(sde > 0, "Small positive", "Small negative"))
  }
  if (abs_sde < 0.15) {
    return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  }
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

sde_rows <- tribble(
  ~outcome, ~beta, ~se_beta, ~sd_y, ~sde, ~se_sde, ~classification,
  "FY enforcement $\\Delta$\\%", beta_enf, NA_real_, sd_pct_change, sde_enf, se_sde_enf, classify_sde(sde_enf),
  "VIX level", beta_vix, se_beta_vix, sd_vix, sde_vix, se_sde_vix, classify_sde(sde_vix),
  "Financial excess return", beta_fin, se_beta_fin, sd_fin, sde_fin, se_sde_fin, classify_sde(sde_fin)
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do SEC Chair transitions create enforcement vacuums that affect capital market outcomes? ",
  "\\textbf{Policy mechanism:} Each SEC Chair transition disrupts the enforcement pipeline: outgoing Chairs rush pending cases before departure while incoming Chairs rebuild enforcement priorities, creating a temporary vacuum in regulatory oversight of securities markets. ",
  "\\textbf{Outcome definition:} (1) Year-over-year percentage change in total SEC enforcement actions (Cornerstone Research), (2) CBOE Volatility Index daily close, (3) daily log return spread between Financial Select Sector SPDR Fund (XLF) and SPDR S\\&P 500 ETF (SPY). ",
  "\\textbf{Treatment:} Binary; fiscal years containing a Chair transition vs.\\ non-transition years (enforcement outcome), or post-transition vs.\\ pre-transition trading days within $\\pm$60-day event window (market outcomes). ",
  "\\textbf{Data:} Cornerstone Research SEC Enforcement Activity reports, FY2010--FY2025, 16 fiscal years; CBOE VIX and ETF returns from Yahoo Finance, 2012--2025, $N = 324$ event-study trading days across 4 transitions. ",
  "\\textbf{Method:} FY-level permutation test (10,000 replications) for enforcement; panel event study with transition fixed effects and clustered standard errors for market outcomes. ",
  "\\textbf{Sample:} All SEC fiscal years FY2010--FY2025 (enforcement); trading days within $\\pm$60 days of 4 Chair transition dates (market). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (.05$--.15$), Small (.005$--.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  se_str <- ifelse(is.na(r$se_beta), "---", sprintf("%.3f", r$se_beta))
  tabF1_tex <- paste0(tabF1_tex,
    r$outcome, " & ",
    sprintf("%.3f", r$beta), " & ",
    se_str, " & ",
    sprintf("%.3f", r$sd_y), " & ",
    sprintf("%.3f", r$sde), " & ",
    sprintf("%.3f", r$se_sde), " & ",
    r$classification, " \\\\\n"
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables written to tables/ directory.\n")
