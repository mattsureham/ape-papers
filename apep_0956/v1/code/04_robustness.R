# 04_robustness.R — Robustness checks
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

source("00_packages.R")

dk_panel <- readRDS("../data/dk_panel_agg.rds")
cross_country <- readRDS("../data/cross_country_panel.rds")
results <- readRDS("../data/main_results.rds")

# =============================================================================
# 1. Pre-trend test: pre-tax period only
# =============================================================================
cat("=== Pre-Trend Tests ===\n")

# Linear pre-trend test: is there differential trending before October 2011?
pre_data <- dk_panel %>% filter(date < as.Date("2011-10-01"))

m_pretrend <- feols(log_cpi ~ treated:time_trend | product_fct + date,
                    data = pre_data,
                    cluster = ~product_fct)
cat("Pre-trend test (treated × trend):\n")
summary(m_pretrend)

# =============================================================================
# 2. Placebo test: sugar/chocolate (011800) as placebo treated
# =============================================================================
cat("\n=== Placebo Tests ===\n")

# Sugar/chocolate: same retail shelf, but <2.3% saturated fat (control)
# If our results are driven by food-sector trends, sugar should show similar patterns
# Reload full CPI data to include sugar category
dk_cpi_full <- readRDS("../data/dk_cpi_pris6.rds") %>%
  filter(date >= as.Date("2008-01-01") & date <= as.Date("2015-12-01"))
if ("011800" %in% dk_cpi_full$product_code) {
  # Build extended panel including sugar
  sugar_data <- dk_cpi_full %>%
    filter(product_code == "011800") %>%
    mutate(
      log_cpi = log(cpi),
      treated = 0L,
      post_intro = as.integer(date >= as.Date("2011-10-01")),
      post_abolish_ind = as.integer(date >= as.Date("2013-01-01")),
      product_fct = factor(product_code),
      time_trend = as.numeric(date - as.Date("2000-01-01")) / 365.25
    )
  dk_panel_ext <- bind_rows(
    dk_panel %>% select(product_code, date, log_cpi, treated, post_intro, post_abolish_ind, product_fct, time_trend),
    sugar_data %>% select(product_code, date, log_cpi, treated, post_intro, post_abolish_ind, product_fct, time_trend)
  )
  dk_placebo <- dk_panel_ext %>%
    filter(treated == 0) %>%
    mutate(placebo_treated = as.integer(product_code == "011800"))

  m_placebo <- feols(log_cpi ~ placebo_treated:post_intro + placebo_treated:post_abolish_ind |
                       product_fct + date,
                     data = dk_placebo,
                     cluster = ~product_fct)
  cat("Placebo test (sugar/chocolate vs other controls):\n")
  summary(m_placebo)
} else {
  cat("Sugar/chocolate category not available, skipping placebo.\n")
  m_placebo <- NULL
}

# =============================================================================
# 3. Alternative windows
# =============================================================================
cat("\n=== Alternative Windows ===\n")

# Narrow window: 6 months before/after each event
dk_narrow <- dk_panel %>%
  filter(date >= as.Date("2011-04-01") & date <= as.Date("2013-06-01"))

m_narrow <- feols(log_cpi ~ treated:post_intro + treated:post_abolish_ind |
                    product_fct + date,
                  data = dk_narrow,
                  cluster = ~product_fct)
cat("Narrow window (2011M04-2013M06):\n")
summary(m_narrow)

# Wide window: full sample 2000-2015
dk_wide <- dk_panel  # Already 2008-2015; use what we have

m_wide <- feols(log_cpi ~ treated:post_intro + treated:post_abolish_ind |
                  product_fct + date,
                data = dk_wide,
                cluster = ~product_fct)
cat("Wide window (full sample):\n")
summary(m_wide)

# =============================================================================
# 4. Product-specific trends
# =============================================================================
cat("\n=== With Product-Specific Trends ===\n")

# Add product-specific linear trends to absorb differential trending
m_trends <- feols(log_cpi ~ treated:post_intro + treated:post_abolish_ind |
                    product_fct + date + product_fct[time_trend],
                  data = dk_panel,
                  cluster = ~product_fct)
cat("With product-specific linear trends:\n")
summary(m_trends)

# =============================================================================
# 5. Newey-West (HAC) standard errors
# =============================================================================
cat("\n=== HAC Standard Errors ===\n")

# Re-estimate with Newey-West SEs (12-month bandwidth for autocorrelation)
# Need to set panel structure for NW
m_hac <- feols(log_cpi ~ treated:post_intro + treated:post_abolish_ind |
                 product_fct + date,
               data = dk_panel,
               panel.id = ~product_fct + date,
               vcov = NW(12))
cat("With Newey-West(12) standard errors:\n")
summary(m_hac)

# =============================================================================
# 6. Sweden counterfactual: triple-difference
# =============================================================================
cat("\n=== Sweden Triple-Difference ===\n")

# DDD: Denmark × Treated_product × Post
# This absorbs Denmark-wide shocks and product-wide global shocks
m_ddd <- feols(log_hicp ~ denmark:treated_product:post_intro +
                 denmark:treated_product:post_abolish +
                 denmark:post_intro + denmark:post_abolish +
                 treated_product:post_intro + treated_product:post_abolish |
                 country_product + date,
               data = cross_country,
               cluster = ~country_product)
cat("Triple-difference (DK × Treated × Post):\n")
summary(m_ddd)

# Sweden-only placebo: same event dates, should show no effect
se_only <- cross_country %>% filter(country == "SE")
m_sweden_placebo <- feols(log_hicp ~ treated_product:post_intro + treated_product:post_abolish |
                            coicop + date,
                          data = se_only,
                          cluster = ~coicop)
cat("\nSweden placebo (same dates, no tax):\n")
summary(m_sweden_placebo)

# =============================================================================
# 7. Save robustness results
# =============================================================================
robustness <- list(
  m_pretrend = m_pretrend,
  m_placebo = m_placebo,
  m_narrow = m_narrow,
  m_wide = m_wide,
  m_trends = m_trends,
  m_hac = m_hac,
  m_ddd = m_ddd,
  m_sweden_placebo = m_sweden_placebo
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
