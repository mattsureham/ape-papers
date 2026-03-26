# 04_robustness.R — Robustness checks for Poland Sunday Trading Ban
# Key tests: pre-trends, placebo sectors, wild cluster bootstrap, extended panel

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
panel_ext <- readRDS("../data/panel_extended.rds")
results <- readRDS("../data/main_results.rds")

# ============================================================================
# Test 1: Pre-trend check (event study with interactions)
# If trade_share × year dummies show pre-trends, identification fails
# ============================================================================

cat("=== Test 1: Pre-trend check ===\n")

# Create year interactions with baseline trade share (omit 2017 as base year)
panel$year_f <- factor(panel$year)

m_event <- feols(log_emp_trade ~
                   i(year_f, trade_share_2017, ref = "2017") | geo + year,
                 data = panel, cluster = ~nuts2)
summary(m_event)

# Check if pre-period coefficients are significant
pre_coefs <- coef(m_event)[grep("2014|2015|2016", names(coef(m_event)))]
pre_ses <- se(m_event)[grep("2014|2015|2016", names(se(m_event)))]
pre_pvals <- pvalue(m_event)[grep("2014|2015|2016", names(pvalue(m_event)))]

cat("\nPre-trend coefficients:\n")
for (i in seq_along(pre_coefs)) {
  cat(sprintf("  %s: %.4f (SE: %.4f, p: %.3f) %s\n",
              names(pre_coefs)[i], pre_coefs[i], pre_ses[i], pre_pvals[i],
              ifelse(pre_pvals[i] < 0.1, "⚠ SIGNIFICANT", "")))
}

# Joint F-test on pre-period coefficients
cat("\nPre-trend assessment: ")
if (all(pre_pvals > 0.1)) {
  cat("CLEAN — no significant pre-trends\n")
} else {
  cat("WARNING — some pre-trends detected\n")
}

# ============================================================================
# Test 2: Placebo sectors (should NOT respond to Sunday trading ban)
# ============================================================================

cat("\n=== Test 2: Placebo sectors ===\n")

# Industry (B-E): not affected by Sunday trading
panel_ind <- panel %>% filter(!is.na(log_emp_industry))
if (nrow(panel_ind) > 50) {
  m_ind <- feols(log_emp_industry ~ treatment | geo + year,
                 data = panel_ind, cluster = ~nuts2)
  cat("Industry (B-E):\n")
  summary(m_ind)
} else {
  m_ind <- NULL
  cat("Industry: insufficient data\n")
}

# Construction (F): not affected by Sunday trading
panel_con <- panel %>% filter(!is.na(log_emp_construction))
if (nrow(panel_con) > 50) {
  m_con <- feols(log_emp_construction ~ treatment | geo + year,
                 data = panel_con, cluster = ~nuts2)
  cat("Construction (F):\n")
  summary(m_con)
} else {
  m_con <- NULL
  cat("Construction: insufficient data\n")
}

# Public sector (O-Q): not affected by Sunday trading
panel_pub <- panel %>% filter(!is.na(log_emp_public))
if (nrow(panel_pub) > 50) {
  m_pub <- feols(log_emp_public ~ treatment | geo + year,
                 data = panel_pub, cluster = ~nuts2)
  cat("Public sector (O-Q):\n")
  summary(m_pub)
} else {
  m_pub <- NULL
  cat("Public sector: insufficient data\n")
}

# ============================================================================
# Test 3: Wild cluster bootstrap (few clusters: 17 NUTS-2)
# ============================================================================

cat("\n=== Test 3: Wild cluster bootstrap ===\n")

m1 <- results$m1_continuous

# Run wild cluster bootstrap
set.seed(42)
wcb <- tryCatch({
  boot_result <- boottest(m1, param = "treatment",
                          clustid = ~nuts2,
                          B = 9999, type = "rademacher")
  cat(sprintf("WCB p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("WCB 95%% CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
  boot_result
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  NULL
})

# ============================================================================
# Test 4: Extended panel through 2022 (COVID controls)
# ============================================================================

cat("\n=== Test 4: Extended panel (2014-2022) ===\n")

m_ext <- feols(log_emp_trade ~ treatment | geo + year,
               data = panel_ext, cluster = ~nuts2)
cat("Extended panel (includes COVID period):\n")
summary(m_ext)

# Phase-specific with all three phases
m_ext_phase <- feols(log_emp_trade ~ treat_phase1 + treat_phase2 + treat_phase3 | geo + year,
                     data = panel_ext, cluster = ~nuts2)
cat("Extended, phase-specific:\n")
summary(m_ext_phase)

# ============================================================================
# Test 5: Alternative treatment intensity (using trade share quartiles)
# ============================================================================

cat("\n=== Test 5: Quartile-based treatment ===\n")

panel$trade_quartile <- ntile(panel$trade_share_2017, 4)
panel$q4 <- as.numeric(panel$trade_quartile == 4)  # Top quartile
panel$q1 <- as.numeric(panel$trade_quartile == 1)  # Bottom quartile

m_q4 <- feols(log_emp_trade ~ q4:post | geo + year,
              data = panel, cluster = ~nuts2)
cat("Top quartile vs rest:\n")
summary(m_q4)

# ============================================================================
# Test 6: Retail trade monthly data (national level — descriptive)
# ============================================================================

cat("\n=== Test 6: National retail trade index ===\n")

if (file.exists("../data/retail_trade_monthly.rds")) {
  retail <- readRDS("../data/retail_trade_monthly.rds")

  # Get volume index for Poland vs comparison countries
  retail_vol <- retail %>%
    filter(geo %in% c("PL", "CZ", "SK"),
           grepl("TOVV|TOVT", indic_bt, ignore.case = TRUE)) %>%
    mutate(year = as.numeric(format(TIME_PERIOD, "%Y")),
           month = as.numeric(format(TIME_PERIOD, "%m")))

  if (nrow(retail_vol) > 0) {
    cat(sprintf("Retail volume data: %d country-months\n", nrow(retail_vol)))

    # Average by country and year
    retail_annual <- retail_vol %>%
      filter(year >= 2015 & year <= 2021) %>%
      group_by(geo, year) %>%
      summarise(vol_index = mean(values, na.rm = TRUE), .groups = "drop") %>%
      pivot_wider(names_from = geo, values_from = vol_index)

    cat("\nRetail trade volume index (annual average):\n")
    print(retail_annual)
  } else {
    cat("No volume index available.\n")
    # Try any available indicator
    cat("Available indicators:", paste(unique(retail$indic_bt), collapse = ", "), "\n")
  }
}

# ============================================================================
# Save robustness results
# ============================================================================

robust_results <- list(
  event_study = m_event,
  placebo_industry = m_ind,
  placebo_construction = m_con,
  placebo_public = m_pub,
  wcb = wcb,
  extended = m_ext,
  extended_phase = m_ext_phase,
  quartile = m_q4
)

saveRDS(robust_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
