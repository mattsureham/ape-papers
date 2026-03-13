# 02_clean_data.R — Construct semi-annual WAC changes and analysis dataset
source("00_packages.R")

cat("=== Constructing semi-annual price change dataset ===\n")

nadac <- readRDS("../data/nadac_brand.rds")

# ------------------------------------------------------------------
# 1. For each NDC, get the LAST observed price in each half-year
# ------------------------------------------------------------------
# NADAC publishes weekly. Semi-annual frequency gives more pre-periods.
# H1 = Jan-Jun, H2 = Jul-Dec

nadac <- nadac %>%
  mutate(
    half = ifelse(as.integer(format(effective_date, "%m")) <= 6, 1L, 2L),
    period = year + (half - 1) * 0.5  # 2014.0 = 2014H1, 2014.5 = 2014H2
  )

semiannual_prices <- nadac %>%
  group_by(ndc, ndc_description, year, half, period) %>%
  filter(effective_date == max(effective_date)) %>%
  slice(1) %>%
  ungroup() %>%
  select(ndc, ndc_description, year, half, period, nadac_per_unit, effective_date)

cat(sprintf("Semi-annual price observations: %s (NDC x half-year pairs)\n",
            format(nrow(semiannual_prices), big.mark = ",")))

# ------------------------------------------------------------------
# 2. Compute semi-annual price changes (annualized)
# ------------------------------------------------------------------
price_changes <- semiannual_prices %>%
  arrange(ndc, period) %>%
  group_by(ndc, ndc_description) %>%
  mutate(
    price_lag    = lag(nadac_per_unit),
    period_lag   = lag(period),
    pct_change   = (nadac_per_unit - price_lag) / price_lag * 100,
    abs_change   = nadac_per_unit - price_lag,
    log_change   = log(nadac_per_unit / price_lag) * 100
  ) %>%
  ungroup() %>%
  # Only keep consecutive half-years (period_lag == period - 0.5)
  filter(!is.na(pct_change), abs(period_lag - (period - 0.5)) < 0.01)

cat(sprintf("Semi-annual price changes: %s NDC-period pairs\n",
            format(nrow(price_changes), big.mark = ",")))

# ------------------------------------------------------------------
# 3. Define transparency law periods
# ------------------------------------------------------------------
# Key state adoption dates and thresholds:
# 2016: Vermont (launch price, no specific % threshold for increases)
# 2017: California (16% over 2 years)
# 2018: Oregon (10% annual for brand drugs)
# 2019: Connecticut (20%), Maine (various thresholds)
# 2020: New York (10% annual), New Mexico (10%)
# 2021: Colorado, Texas, others

# Era definitions for analysis
price_changes <- price_changes %>%
  mutate(
    era = case_when(
      year <= 2016 ~ "Pre-transparency",
      year == 2017 ~ "Early adoption (2017)",
      year >= 2018 & year <= 2020 ~ "10% threshold active (2018-2020)",
      year >= 2021 ~ "Mature regime (2021+)"
    ),
    era_simple = case_when(
      year <= 2016 ~ "Pre",
      year >= 2018 ~ "Post"
    ),
    # Binding threshold: the lowest active threshold
    binding_threshold = case_when(
      year <= 2016 ~ NA_real_,
      year == 2017 ~ 16,
      year >= 2018 ~ 10
    ),
    # Binary: was this increase above the binding threshold?
    above_threshold = case_when(
      is.na(binding_threshold) ~ NA,
      pct_change > binding_threshold ~ TRUE,
      TRUE ~ FALSE
    ),
    # Drug price level (base period price)
    high_price = price_lag >= median(price_lag, na.rm = TRUE)
  )

# ------------------------------------------------------------------
# 4. Filter to analysis sample
# ------------------------------------------------------------------
# Trim extremes (data errors, discontinuations, reformulations)
# For semi-annual changes, threshold is halved vs annual
analysis <- price_changes %>%
  filter(
    pct_change >= -30 & pct_change <= 60,  # trim extreme tails (semi-annual)
    price_lag >= 1                          # exclude very cheap drugs
  )

cat(sprintf("Analysis sample (after trimming): %s NDC-period pairs\n",
            format(nrow(analysis), big.mark = ",")))

# ------------------------------------------------------------------
# 5. Summary statistics
# ------------------------------------------------------------------
cat("\n=== Price Change Distribution ===\n")
cat("Full sample:\n")
summary(analysis$pct_change)

cat("\nBy era:\n")
analysis %>%
  group_by(era_simple) %>%
  filter(!is.na(era_simple)) %>%
  summarise(
    n = n(),
    mean_pct = mean(pct_change),
    median_pct = median(pct_change),
    sd_pct = sd(pct_change),
    p10 = quantile(pct_change, 0.10),
    p25 = quantile(pct_change, 0.25),
    p75 = quantile(pct_change, 0.75),
    p90 = quantile(pct_change, 0.90),
    share_above_5 = mean(pct_change > 5),
    share_above_10 = mean(pct_change > 10)
  ) %>%
  print()

# ------------------------------------------------------------------
# 6. Save analysis dataset
# ------------------------------------------------------------------
saveRDS(analysis, "../data/analysis.rds")
cat("\nSaved: ../data/analysis.rds\n")

# Also save summary stats for the paper
sumstats <- analysis %>%
  filter(!is.na(era_simple)) %>%
  group_by(era_simple) %>%
  summarise(
    n_obs = n(),
    n_ndcs = n_distinct(ndc),
    mean_price = mean(price_lag),
    mean_change_pct = mean(pct_change),
    median_change_pct = median(pct_change),
    sd_change_pct = sd(pct_change),
    share_positive = mean(pct_change > 0),
    share_above_5 = mean(pct_change > 5),
    share_above_10 = mean(pct_change > 10)
  )

saveRDS(sumstats, "../data/sumstats.rds")
cat("Saved: ../data/sumstats.rds\n")
