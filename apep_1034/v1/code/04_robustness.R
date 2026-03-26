## 04_robustness.R — Robustness checks and placebo tests
## apep_1034: Norway Wind Resource Rent Tax
## NOTE: Model 3 (with sector-specific linear trends) is the main specification.
## Without trends, the DiD captures secular wind growth, not the tax effect.

source("00_packages.R")

# ============================================================
# Load data
# ============================================================
monthly_panel <- readRDS("../data/monthly_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")
results <- readRDS("../data/model_results.rds")

eurostat_file <- "../data/eurostat_panel.rds"
has_eurostat <- file.exists(eurostat_file)
if (has_eurostat) {
  eurostat_panel <- readRDS(eurostat_file)
}

# Add trend variable to monthly panel
monthly_panel <- monthly_panel %>%
  mutate(ym_trend = as.numeric(date - min(date)) / 365.25)

# ============================================================
# 1. Placebo test: False treatment dates (WITH TRENDS)
# ============================================================
cat("=== PLACEBO: FALSE TREATMENT DATES (TREND-ADJUSTED) ===\n")

placebo_dates <- as.Date(c("2020-01-01", "2020-07-01", "2021-07-01"))
placebo_results <- list()

for (pd in placebo_dates) {
  pd_date <- as.Date(pd, origin = "1970-01-01")
  panel_pre <- monthly_panel %>%
    filter(date < as.Date("2022-12-01")) %>%
    mutate(
      post_placebo = as.integer(date >= pd_date),
      treat_placebo = wind * post_placebo
    )

  m_placebo <- feols(log_gwh ~ treat_placebo + wind:ym_trend | sector + date,
                     data = panel_pre)
  placebo_results[[as.character(pd_date)]] <- list(
    date = pd_date,
    beta = coef(m_placebo)["treat_placebo"],
    se = se(m_placebo)["treat_placebo"],
    pval = pvalue(m_placebo)["treat_placebo"]
  )
  cat(sprintf("  Placebo %s: beta = %.4f (%.4f), p = %.3f\n",
              pd_date,
              coef(m_placebo)["treat_placebo"],
              se(m_placebo)["treat_placebo"],
              pvalue(m_placebo)["treat_placebo"]))
}

# ============================================================
# 2. Cross-country: Norway vs Sweden/Denmark wind growth
# ============================================================
cat("\n=== CROSS-COUNTRY WIND GROWTH COMPARISON ===\n")

if (has_eurostat && nrow(eurostat_panel) > 0) {
  # Add trend variable
  eurostat_panel <- eurostat_panel %>%
    mutate(ym_trend = as.numeric(date - min(date)) / 365.25)

  # Simple DiD: Norway wind vs SE/DK wind
  m_cross_simple <- feols(
    log_gwh ~ treat | country + date,
    data = eurostat_panel
  )

  # With country-specific trends
  m_cross_trend <- feols(
    log_gwh ~ treat + norway:ym_trend | country + date,
    data = eurostat_panel
  )

  cat("Cross-country DiD (simple):\n")
  cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
              coef(m_cross_simple)["treat"],
              se(m_cross_simple)["treat"],
              pvalue(m_cross_simple)["treat"]))

  cat("Cross-country DiD (with country trends):\n")
  cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
              coef(m_cross_trend)["treat"],
              se(m_cross_trend)["treat"],
              pvalue(m_cross_trend)["treat"]))

  beta_cross <- coef(m_cross_trend)["treat"]
  se_cross <- se(m_cross_trend)["treat"]
} else {
  cat("  No Eurostat data — skipping cross-country analysis.\n")
  beta_cross <- NA
  se_cross <- NA
}

# ============================================================
# 3. Alternative post-period definitions (WITH TRENDS)
# ============================================================
cat("\n=== ROBUSTNESS: ALTERNATIVE POST-PERIOD (TREND-ADJUSTED) ===\n")

# 3a: Uncertainty window only (Jan 2023 - Dec 2023)
panel_uncertainty <- monthly_panel %>%
  filter(date < as.Date("2024-01-01")) %>%
  mutate(
    post_unc = as.integer(date >= as.Date("2023-01-01")),
    treat_unc = wind * post_unc
  )
m_uncertainty <- feols(log_gwh ~ treat_unc + wind:ym_trend | sector + date,
                       data = panel_uncertainty)
cat("Uncertainty window only (Jan-Dec 2023):\n")
cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
            coef(m_uncertainty)["treat_unc"],
            se(m_uncertainty)["treat_unc"],
            pvalue(m_uncertainty)["treat_unc"]))

# 3b: Post = enactment only (Jan 2024 onwards, dropping 2023)
panel_enact <- monthly_panel %>%
  filter(date < as.Date("2023-01-01") | date >= as.Date("2024-01-01")) %>%
  mutate(
    post_enact = as.integer(date >= as.Date("2024-01-01")),
    treat_enact = wind * post_enact
  )
m_enact <- feols(log_gwh ~ treat_enact + wind:ym_trend | sector + date,
                 data = panel_enact)
cat("\nPost-enactment only (Jan 2024+, 2023 dropped):\n")
cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
            coef(m_enact)["treat_enact"],
            se(m_enact)["treat_enact"],
            pvalue(m_enact)["treat_enact"]))

# ============================================================
# 4. Alternative trend specifications
# ============================================================
cat("\n=== ROBUSTNESS: ALTERNATIVE TREND SPECIFICATIONS ===\n")

# Quadratic trend
m_quad <- feols(log_gwh ~ treat + wind:ym_trend + wind:I(ym_trend^2) | sector + date,
                data = monthly_panel)
cat("Quadratic sector trend:\n")
cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
            coef(m_quad)["treat"], se(m_quad)["treat"], pvalue(m_quad)["treat"]))

# Log-linear trend (year-month interaction)
monthly_panel <- monthly_panel %>%
  mutate(year_frac = year + (month - 1) / 12)

m_ym <- feols(log_gwh ~ treat + wind:year_frac | sector + date,
              data = monthly_panel)
cat("\nYear-fraction trend:\n")
cat(sprintf("  beta = %.4f (%.4f), p = %.3f\n",
            coef(m_ym)["treat"], se(m_ym)["treat"], pvalue(m_ym)["treat"]))

# ============================================================
# 5. Growth rate specification (year-over-year change)
# ============================================================
cat("\n=== GROWTH RATE SPECIFICATION ===\n")

monthly_growth <- monthly_panel %>%
  group_by(sector) %>%
  arrange(date) %>%
  mutate(
    log_gwh_lag12 = dplyr::lag(log_gwh, 12),
    yoy_growth = log_gwh - log_gwh_lag12
  ) %>%
  ungroup() %>%
  filter(!is.na(yoy_growth))

m_growth <- feols(yoy_growth ~ treat | sector + date, data = monthly_growth)
cat("Year-over-year growth rate DiD:\n")
summary(m_growth)

# ============================================================
# 6. Heterogeneity: By season (wind is seasonal)
# ============================================================
cat("\n=== HETEROGENEITY: BY SEASON (TREND-ADJUSTED) ===\n")

monthly_panel <- monthly_panel %>%
  mutate(
    winter = as.integer(month %in% c(10, 11, 12, 1, 2, 3)),
    season_label = ifelse(winter == 1, "Winter (Oct-Mar)", "Summer (Apr-Sep)")
  )

m_winter <- feols(log_gwh ~ treat + wind:ym_trend | sector + date,
                  data = filter(monthly_panel, winter == 1))
m_summer <- feols(log_gwh ~ treat + wind:ym_trend | sector + date,
                  data = filter(monthly_panel, winter == 0))

cat(sprintf("Winter: beta = %.4f (%.4f), p = %.3f\n",
            coef(m_winter)["treat"], se(m_winter)["treat"], pvalue(m_winter)["treat"]))
cat(sprintf("Summer: beta = %.4f (%.4f), p = %.3f\n",
            coef(m_summer)["treat"], se(m_summer)["treat"], pvalue(m_summer)["treat"]))

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  placebo = placebo_results,
  cross_country = list(beta = beta_cross, se = se_cross),
  uncertainty_window = list(
    beta = coef(m_uncertainty)["treat_unc"],
    se = se(m_uncertainty)["treat_unc"]
  ),
  enactment_only = list(
    beta = coef(m_enact)["treat_enact"],
    se = se(m_enact)["treat_enact"]
  ),
  quadratic = list(
    beta = coef(m_quad)["treat"],
    se = se(m_quad)["treat"]
  ),
  growth_rate = list(
    beta = coef(m_growth)["treat"],
    se = se(m_growth)["treat"]
  ),
  winter = list(
    beta = coef(m_winter)["treat"],
    se = se(m_winter)["treat"]
  ),
  summer = list(
    beta = coef(m_summer)["treat"],
    se = se(m_summer)["treat"]
  ),
  m_uncertainty = m_uncertainty,
  m_enact = m_enact,
  m_quad = m_quad,
  m_growth = m_growth,
  m_winter = m_winter,
  m_summer = m_summer
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
