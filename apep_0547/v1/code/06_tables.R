# =============================================================================
# 06_tables.R — All Table Generation
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# Load results
results <- readRDS(file.path(data_dir, "main_results.rds"))
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]
panel[, log_price := log(mean_price)]
rob_summary <- tryCatch(fread(file.path(data_dir, "robustness_summary.csv")), error = function(e) NULL)
key_results <- fread(file.path(data_dir, "key_results.csv"))
sumstats <- fread(file.path(data_dir, "summary_stats.csv"))

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Creating Table 1: Summary statistics...\n")

# Compute detailed summary stats by country × period
ss_detail <- panel[, .(
  `Mean transactions/month` = mean(n_transactions),
  `SD transactions/month` = sd(n_transactions),
  `Mean price (£)` = mean(mean_price, na.rm = TRUE),
  `SD price (£)` = sd(mean_price, na.rm = TRUE),
  `Freehold share` = mean(freehold_share, na.rm = TRUE),
  `Flat share` = mean(flat_share, na.rm = TRUE),
  `Category B share` = mean(cat_b_share, na.rm = TRUE),
  `New-build share` = mean(new_share, na.rm = TRUE),
  `PRS share (Census 2021)` = mean(prs_share, na.rm = TRUE),
  `N (LA-months)` = .N,
  `N (LAs)` = uniqueN(la)
), by = .(Country = country, Period = fifelse(post == 1, "Post (Dec 2022+)", "Pre (Jan 2018 -- Nov 2022)"))]

fwrite(ss_detail, file.path(tab_dir, "table1_summary_stats.csv"))

# LaTeX version
ss_tex <- kbl(ss_detail, format = "latex", booktabs = TRUE, digits = 3,
              caption = "Summary Statistics: Wales vs. England, Pre- and Post-Treatment",
              label = "tab:sumstats") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(ss_tex, file.path(tab_dir, "table1_summary_stats.tex"))
cat("  Saved table1_summary_stats.tex\n")

# =============================================================================
# TABLE 2: Main DiD Results
# =============================================================================
cat("Creating Table 2: Main DiD results...\n")

# Re-run models to get clean modelsummary output
m1 <- feols(log_n ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m2 <- feols(log_n ~ treated | la_id + ym_id + la_id[year], data = panel, cluster = ~la_id)

panel[, log_cat_a := log(n_cat_a + 1)]
panel[, log_cat_b := log(n_cat_b + 1)]
panel[, log_detached := log(n_detached + 1)]
panel[, log_flat_v := log(n_flat + 1)]

m_catA <- feols(log_cat_a ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m_catB <- feols(log_cat_b ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)

tab2_models <- list(
  "All transactions" = m1,
  "LA trends" = m2,
  "Cat A (owner proxy)" = m_catA,
  "Cat B (BTL proxy)" = m_catB
)

tab2 <- modelsummary(
  tab2_models,
  output = "latex_tabular",
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c("treated" = "Wales $\\times$ Post"),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title = "Effect of Renting Homes Act on Transaction Volumes",
  notes = list("Standard errors clustered at LA level in parentheses.",
               "All specifications include LA and year-month fixed effects.",
               "Cat A = standard residential transactions (owner-occupier proxy).",
               "Cat B = additional property transactions (buy-to-let proxy)."),
  escape = FALSE
)

writeLines(as.character(tab2), file.path(tab_dir, "table2_main_did.tex"))
cat("  Saved table2_main_did.tex\n")

# =============================================================================
# TABLE 3: Triple-Difference (DDD) Results
# =============================================================================
cat("Creating Table 3: DDD results...\n")

m_ddd1 <- feols(log_n ~ treated * prs_share | la_id + ym_id, data = panel, cluster = ~la_id)
m_ddd2 <- feols(log_n ~ treated * high_prs | la_id + ym_id, data = panel, cluster = ~la_id)
m_ddd3 <- feols(log_cat_b ~ treated * prs_share | la_id + ym_id, data = panel, cluster = ~la_id)

tab3_models <- list(
  "Log transactions\n(continuous PRS)" = m_ddd1,
  "Log transactions\n(high PRS)" = m_ddd2,
  "Cat B share\n(continuous PRS)" = m_ddd3
)

tab3 <- modelsummary(
  tab3_models,
  output = "latex_tabular",
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c("treated" = "Wales $\\times$ Post",
               "treated:prs_share" = "Wales $\\times$ Post $\\times$ PRS Share",
               "treated:high_prs" = "Wales $\\times$ Post $\\times$ High PRS"),
  gof_map = c("nobs", "r.squared"),
  title = "Triple-Difference: Heterogeneity by Pre-Reform PRS Intensity",
  notes = list("Standard errors clustered at LA level in parentheses.",
               "PRS Share = proportion of households in private rented sector (Census 2021).",
               "High PRS = indicator for above-median PRS share."),
  escape = FALSE
)

writeLines(as.character(tab3), file.path(tab_dir, "table3_ddd.tex"))
cat("  Saved table3_ddd.tex\n")

# =============================================================================
# TABLE 4: Composition Analysis
# =============================================================================
cat("Creating Table 4: Composition analysis...\n")

m_fh <- feols(freehold_share ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m_fl <- feols(flat_share ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m_cb <- feols(cat_b_share ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m_nw <- feols(new_share ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)
m_pr <- feols(log_price ~ treated | la_id + ym_id, data = panel, cluster = ~la_id)

tab4_models <- list(
  "Freehold share" = m_fh,
  "Flat share" = m_fl,
  "Cat B share" = m_cb,
  "New-build share" = m_nw,
  "Log price" = m_pr
)

tab4 <- modelsummary(
  tab4_models,
  output = "latex_tabular",
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c("treated" = "Wales $\\times$ Post"),
  gof_map = c("nobs", "r.squared"),
  title = "Composition Effects: How the Renting Homes Act Changed the Mix of Transactions",
  notes = list("Standard errors clustered at LA level in parentheses.",
               "All specifications include LA and year-month fixed effects."),
  escape = FALSE
)

writeLines(as.character(tab4), file.path(tab_dir, "table4_composition.tex"))
cat("  Saved table4_composition.tex\n")

# =============================================================================
# TABLE 5: Robustness Summary
# =============================================================================
cat("Creating Table 5: Robustness summary...\n")

if (!is.null(rob_summary)) {
  rob_summary[, stars := fifelse(!is.na(p_value) & p_value < 0.01, "***",
                           fifelse(!is.na(p_value) & p_value < 0.05, "**",
                             fifelse(!is.na(p_value) & p_value < 0.10, "*", "")))]

  rob_tex <- kbl(rob_summary[, .(Test = test,
                                   Estimate = round(estimate, 4),
                                   SE = round(se, 4),
                                   `p-value` = round(p_value, 4),
                                   Sig. = stars)],
                  format = "latex", booktabs = TRUE,
                  caption = "Robustness Checks: Alternative Samples and Inference Methods",
                  label = "tab:robustness") |>
    kable_styling(latex_options = c("hold_position"))

  writeLines(rob_tex, file.path(tab_dir, "table5_robustness.tex"))
  cat("  Saved table5_robustness.tex\n")
}

# =============================================================================
# TABLE A1: Pre-Trend Tests
# =============================================================================
cat("Creating Table A1: Pre-trend tests...\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))
pre_coefs <- es_coefs[t >= -12 & t <= -2]

pre_test_tab <- data.table(
  Test = c("Joint F-test (t=-12 to t=-2)",
           "Mean pre-treatment coefficient",
           "Max absolute pre-treatment coefficient",
           "Number of individually significant (5%)"),
  Value = c(
    NA,  # Will be filled from model output
    round(mean(pre_coefs$estimate), 4),
    round(max(abs(pre_coefs$estimate)), 4),
    sum(abs(pre_coefs$estimate / pre_coefs$se) > 1.96, na.rm = TRUE)
  )
)

fwrite(pre_test_tab, file.path(tab_dir, "tableA1_pretrends.csv"))
cat("  Saved tableA1_pretrends.csv\n")

cat("\n=== All tables generated ===\n")
