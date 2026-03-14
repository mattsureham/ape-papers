## 04_robustness.R — Robustness checks
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")

data_dir <- "../data"
plant_chars <- readRDS(file.path(data_dir, "plant_chars.rds"))
state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))
state_retirements <- readRDS(file.path(data_dir, "state_retirements.rds"))
eia_prices <- readRDS(file.path(data_dir, "eia_retail_prices.rds"))

# Ensure deregulated variable exists
deregulated <- c("TX", "PA", "OH", "IL", "NY", "NJ", "MD", "DE", "CT", "MA",
                  "RI", "NH", "ME", "MI", "MT")
state_panel <- state_panel %>%
  mutate(
    deregulated = as.integer(state %in% deregulated),
    post_mats = as.integer(year >= 2015),
    mats_post = mats_exposure * post_mats
  )

# -----------------------------------------------------------------------
# 1. Alternative treatment timing
# -----------------------------------------------------------------------
cat("=== Robustness: Alternative Treatment Timing ===\n")

# MATS finalized 2012 — try post=2013, post=2016
state_panel <- state_panel %>%
  mutate(
    post_2013 = as.integer(year >= 2013),
    post_2016 = as.integer(year >= 2016),
    mats_post_2013 = mats_exposure * post_2013,
    mats_post_2016 = mats_exposure * post_2016
  )

m_rob_2013 <- feols(log_price ~ mats_post_2013 | state + year,
                     data = state_panel, cluster = ~state)
m_rob_2015 <- feols(log_price ~ mats_post | state + year,
                     data = state_panel, cluster = ~state)
m_rob_2016 <- feols(log_price ~ mats_post_2016 | state + year,
                     data = state_panel, cluster = ~state)

cat("Alternative timing:\n")
etable(m_rob_2013, m_rob_2015, m_rob_2016,
       headers = c("Post=2013", "Post=2015", "Post=2016"))

# -----------------------------------------------------------------------
# 2. Alternative treatment measures
# -----------------------------------------------------------------------
cat("\n=== Robustness: Alternative Treatment Measures ===\n")

# Binary treatment: above-median MATS exposure
state_panel <- state_panel %>%
  mutate(
    high_exposure = as.integer(mats_exposure > median(mats_exposure, na.rm = TRUE)),
    high_exp_post = high_exposure * post_mats
  )

m_binary <- feols(log_price ~ high_exp_post | state + year,
                  data = state_panel, cluster = ~state)

# Number of plants retired (count-based)
state_panel <- state_panel %>%
  left_join(state_retirements %>% select(state, n_retired), by = "state",
            suffix = c("", "_join")) %>%
  mutate(
    n_retired = coalesce(n_retired, n_retired_join),
    n_retired_post = n_retired * post_mats
  ) %>%
  select(-n_retired_join)

m_count <- feols(log_price ~ n_retired_post | state + year,
                 data = state_panel, cluster = ~state)

cat("Alternative treatment:\n")
etable(m_binary, m_count, headers = c("Binary", "Count"))

# -----------------------------------------------------------------------
# 3. Dropping outlier states
# -----------------------------------------------------------------------
cat("\n=== Robustness: Excluding Outlier States ===\n")

# Drop WV (highest coal dependence)
m_no_wv <- feols(log_price ~ mats_post | state + year,
                 data = state_panel %>% filter(state != "WV"),
                 cluster = ~state)

# Drop TX (largest deregulated market)
m_no_tx <- feols(log_price ~ mats_post | state + year,
                 data = state_panel %>% filter(state != "TX"),
                 cluster = ~state)

# Drop states with < 3 coal plants
small_states <- state_retirements %>% filter(n_plants_pre < 3) %>% pull(state)
m_no_small <- feols(log_price ~ mats_post | state + year,
                    data = state_panel %>% filter(!state %in% small_states),
                    cluster = ~state)

cat("Dropping outliers:\n")
etable(m_no_wv, m_no_tx, m_no_small,
       headers = c("No WV", "No TX", "No Small"))

# -----------------------------------------------------------------------
# 4. Placebo test: Pre-MATS trend
# -----------------------------------------------------------------------
cat("\n=== Placebo: Pre-MATS Period ===\n")

# Restrict to 2005-2012 and test fake treatment at 2009
pre_mats_panel <- state_panel %>%
  filter(year >= 2005, year <= 2012) %>%
  mutate(
    placebo_post = as.integer(year >= 2009),
    placebo_treat = mats_exposure * placebo_post
  )

m_placebo <- feols(log_price ~ placebo_treat | state + year,
                   data = pre_mats_panel, cluster = ~state)

cat("Placebo (fake treatment 2009):\n")
etable(m_placebo)

# -----------------------------------------------------------------------
# 5. Controlling for natural gas prices
# -----------------------------------------------------------------------
cat("\n=== Robustness: State-Year Trends ===\n")

# Census region trends
state_panel <- state_panel %>%
  mutate(
    region = case_when(
      state %in% c("CT","ME","MA","NH","RI","VT","NJ","NY","PA") ~ "Northeast",
      state %in% c("IN","IL","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD") ~ "Midwest",
      state %in% c("DE","FL","GA","MD","NC","SC","VA","WV","DC","AL","KY","MS","TN","AR","LA","OK","TX") ~ "South",
      state %in% c("AZ","CO","ID","NM","MT","UT","NV","WY","AK","CA","HI","OR","WA") ~ "West",
      TRUE ~ "Other"
    )
  )

m_region_trend <- feols(log_price ~ mats_post | state + year + region[year],
                        data = state_panel, cluster = ~state)

cat("Region-year trends:\n")
etable(m_region_trend)

# -----------------------------------------------------------------------
# 6. Save robustness results
# -----------------------------------------------------------------------
save(m_rob_2013, m_rob_2015, m_rob_2016,
     m_binary, m_count,
     m_no_wv, m_no_tx, m_no_small,
     m_placebo, m_region_trend,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
