## 03b_iv_analysis.R — IV analysis and additional controls
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")

data_dir <- "../data"
plant_chars <- readRDS(file.path(data_dir, "plant_chars.rds"))
state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))
state_retirements <- readRDS(file.path(data_dir, "state_retirements.rds"))

deregulated_states <- c("TX", "PA", "OH", "IL", "NY", "NJ", "MD", "DE", "CT", "MA",
                         "RI", "NH", "ME", "MI", "MT")

# -----------------------------------------------------------------------
# 1. Construct instruments from pre-MATS fleet characteristics
# -----------------------------------------------------------------------
cat("=== Constructing State-Level Instruments ===\n")

# State-level fleet characteristics (capacity-weighted averages)
state_fleet <- plant_chars %>%
  filter(!is.na(heat_rate), heat_rate > 0) %>%
  group_by(state) %>%
  summarise(
    fleet_avg_hr = weighted.mean(heat_rate, capacity_mw, na.rm = TRUE),
    share_old_plants = sum((capacity_mw * as.integer(plant_age_2012 > 40)), na.rm = TRUE) /
                        sum(capacity_mw, na.rm = TRUE),
    fleet_share_high_hr = sum((capacity_mw * as.integer(heat_rate > median(plant_chars$heat_rate, na.rm = TRUE))), na.rm = TRUE) /
                     sum(capacity_mw, na.rm = TRUE),
    avg_capacity = mean(capacity_mw, na.rm = TRUE),
    n_plants = n(),
    actual_retire_share = sum(retired * capacity_mw, na.rm = TRUE) /
                           sum(capacity_mw, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("  Corr(fleet_avg_hr, retire_share) = %.3f\n",
            cor(state_fleet$fleet_avg_hr, state_fleet$actual_retire_share, use = "complete")))
cat(sprintf("  Corr(fleet_share_high_hr, retire_share) = %.3f\n",
            cor(state_fleet$fleet_share_high_hr, state_fleet$actual_retire_share, use = "complete")))

# -----------------------------------------------------------------------
# 2. Build augmented state panel
# -----------------------------------------------------------------------
fleet_instrument <- state_fleet %>%
  select(state, fleet_avg_hr, fleet_share_high_hr)
state_panel_iv <- state_panel %>%
  left_join(fleet_instrument, by = "state")

cat(sprintf("  Join check: fleet_avg_hr available for %d / %d rows\n",
            sum(!is.na(state_panel_iv$fleet_avg_hr)), nrow(state_panel_iv)))

state_panel_iv <- state_panel_iv %>%
  mutate(
    post_mats = as.integer(year >= 2015),
    mats_post = mats_exposure * post_mats,
    log_price = log(price_cents_kwh),
    deregulated = as.integer(state %in% deregulated_states),
    # Instruments
    fleet_hr_post = fleet_avg_hr * post_mats,
    fleet_hhr_post = fleet_share_high_hr * post_mats
  )

# -----------------------------------------------------------------------
# 3. 2SLS using avg heat rate as instrument
# -----------------------------------------------------------------------
cat("\n=== 2SLS: Avg Heat Rate as Instrument ===\n")

m_iv <- feols(log_price ~ 1 | state + year | mats_post ~ fleet_hr_post,
              data = state_panel_iv, cluster = ~state)

cat("2SLS (all states):\n")
etable(m_iv)

# 2SLS for regulated states
m_iv_reg <- feols(log_price ~ 1 | state + year | mats_post ~ fleet_hr_post,
                  data = state_panel_iv %>% filter(deregulated == 0),
                  cluster = ~state)

cat("\n2SLS (regulated only):\n")
etable(m_iv_reg)

# -----------------------------------------------------------------------
# 4. Reduced form with heat rate instrument directly
# -----------------------------------------------------------------------
cat("\n=== Reduced Form ===\n")

m_rf <- feols(log_price ~ fleet_hr_post | state + year,
              data = state_panel_iv, cluster = ~state)
m_rf_reg <- feols(log_price ~ fleet_hr_post | state + year,
                  data = state_panel_iv %>% filter(deregulated == 0),
                  cluster = ~state)

cat("Reduced form (heat rate instrument):\n")
etable(m_rf, m_rf_reg, headers = c("All", "Regulated"))

# -----------------------------------------------------------------------
# 5. OLS with coal share control (gas exposure proxy)
# -----------------------------------------------------------------------
cat("\n=== OLS with Controls ===\n")

# Coal share × post controls for differential gas price exposure
state_panel_iv <- state_panel_iv %>%
  left_join(
    readRDS(file.path(data_dir, "coal_plant_year.rds")) %>%
      filter(year == 2010) %>%
      group_by(state) %>%
      summarise(coal_gen_2010 = sum(generation_mwh, na.rm = TRUE), .groups = "drop"),
    by = "state"
  ) %>%
  left_join(
    readRDS(file.path(data_dir, "eia_retail_prices.rds")) %>%
      filter(year == 2010, sector == "ALL", !is.na(state_id), nchar(state_id) == 2) %>%
      select(state = state_id, total_sales_2010 = sales_mwh),
    by = "state"
  ) %>%
  mutate(
    coal_share_2010 = coal_gen_2010 / total_sales_2010,
    coal_share_post = coal_share_2010 * post_mats
  )

m_ols_ctrl <- feols(log_price ~ mats_post + coal_share_post | state + year,
                    data = state_panel_iv, cluster = ~state)

m_ols_ctrl_reg <- feols(log_price ~ mats_post + coal_share_post | state + year,
                        data = state_panel_iv %>% filter(deregulated == 0),
                        cluster = ~state)

cat("OLS with coal share control:\n")
etable(m_ols_ctrl, m_ols_ctrl_reg, headers = c("All", "Regulated"))

# -----------------------------------------------------------------------
# 6. Summary table: OLS vs 2SLS comparison
# -----------------------------------------------------------------------
cat("\n=== OLS vs 2SLS Comparison ===\n")

# Baseline OLS
m_ols <- feols(log_price ~ mats_post | state + year,
               data = state_panel_iv, cluster = ~state)
m_ols_reg <- feols(log_price ~ mats_post | state + year,
                   data = state_panel_iv %>% filter(deregulated == 0),
                   cluster = ~state)

cat("Comparison:\n")
etable(m_ols, m_ols_ctrl, m_rf, m_ols_reg, m_ols_ctrl_reg, m_rf_reg,
       headers = c("OLS", "OLS+Ctrl", "RF", "OLS-R", "OLS+C-R", "RF-R"))

# -----------------------------------------------------------------------
# 7. Save
# -----------------------------------------------------------------------
save(m_iv, m_iv_reg, m_rf, m_rf_reg,
     m_ols_ctrl, m_ols_ctrl_reg,
     state_fleet,
     file = file.path(data_dir, "iv_models.RData"))

cat("\nIV analysis complete.\n")
