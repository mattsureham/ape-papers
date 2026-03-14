## 03_main_analysis.R — Main regressions
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")

data_dir <- "../data"

plant_chars <- readRDS(file.path(data_dir, "plant_chars.rds"))
state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))

# -----------------------------------------------------------------------
# 1. Plant-level first stage: What predicts MATS retirement?
# -----------------------------------------------------------------------
cat("=== Plant-Level Retirement Models ===\n")

# Prepare plant-level data
plant_reg <- plant_chars %>%
  filter(!is.na(heat_rate), heat_rate > 0, !is.na(capacity_mw)) %>%
  mutate(
    # Heat rate in MMBtu/MWh (standard coal units)
    heat_rate_mmbtu = heat_rate,
    # Standardized heat rate for interpretation
    high_heat_rate = as.integer(heat_rate > median(heat_rate, na.rm = TRUE)),
    # Capacity terciles
    small_plant = as.integer(capacity_mw < quantile(capacity_mw, 0.33, na.rm = TRUE)),
    large_plant = as.integer(capacity_mw > quantile(capacity_mw, 0.67, na.rm = TRUE)),
    # Log transformations
    log_heat_rate = log(heat_rate),
    log_capacity = log(capacity_mw + 1),
    # 2010 generation (proxy for utilization)
    log_gen_2010 = log(gen_2010 + 1)
  )

cat(sprintf("  Plant regression sample: %d plants\n", nrow(plant_reg)))

# Model 1: Bivariate — heat rate only
m1_plant <- feols(retired ~ log_heat_rate, data = plant_reg, vcov = "hetero")

# Model 2: Add capacity
m2_plant <- feols(retired ~ log_heat_rate + log_capacity, data = plant_reg, vcov = "hetero")

# Model 3: Add 2010 generation (utilization proxy)
m3_plant <- feols(retired ~ log_heat_rate + log_capacity + log_gen_2010,
                  data = plant_reg, vcov = "hetero")

# Model 4: Full specification with state FE
m4_plant <- feols(retired ~ log_heat_rate + log_capacity + log_gen_2010 | state,
                  data = plant_reg)

cat("\nPlant-level retirement regressions:\n")
etable(m1_plant, m2_plant, m3_plant, m4_plant,
       headers = c("(1)", "(2)", "(3)", "(4)"))

# -----------------------------------------------------------------------
# 2. State-level DiD: MATS exposure and electricity prices
# -----------------------------------------------------------------------
cat("\n=== State-Level DiD: Electricity Prices ===\n")

# Continuous treatment DiD
# Treatment: capacity_retired_share (share of pre-MATS coal capacity retired)
# Post: year >= 2015

# Model 1: Basic DiD (state + year FE)
m1_did <- feols(log_price ~ mats_post | state + year,
                data = state_panel, cluster = ~state)

# Model 2: Add coal share control
m2_did <- feols(log_price ~ mats_post + coal_share | state + year,
                data = state_panel, cluster = ~state)

# Model 3: Using retirement rate instead of capacity share
state_panel <- state_panel %>%
  mutate(retire_rate_post = coalesce(retirement_rate, 0) * post_mats)

m3_did <- feols(log_price ~ retire_rate_post | state + year,
                data = state_panel, cluster = ~state)

cat("\nState-level DiD results:\n")
etable(m1_did, m2_did, m3_did,
       headers = c("Cap Share", "Cap Share + Coal", "Retire Rate"))

# -----------------------------------------------------------------------
# 3. Event study specification
# -----------------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Create event-time indicators
# Base year: 2014 (last full year before compliance deadline)
state_panel <- state_panel %>%
  mutate(
    event_time = year - 2015,
    # Interact each year with MATS exposure
    mats_year = mats_exposure * factor(year)
  )

# Event study with year-by-exposure interactions
# Drop 2014 (event_time = -1) as reference
m_event <- feols(log_price ~ i(year, mats_exposure, ref = 2014) | state + year,
                 data = state_panel, cluster = ~state)

cat("\nEvent study coefficients:\n")
print(coeftable(m_event))

# -----------------------------------------------------------------------
# 4. Mechanism: Regulated vs. Deregulated states
# -----------------------------------------------------------------------
cat("\n=== Mechanism: Market Structure ===\n")

# States with restructured/deregulated electricity markets
# Major deregulated states (as of 2012):
deregulated <- c("TX", "PA", "OH", "IL", "NY", "NJ", "MD", "DE", "CT", "MA",
                  "RI", "NH", "ME", "MI", "MT")

state_panel <- state_panel %>%
  mutate(
    deregulated = as.integer(state %in% deregulated),
    mats_post_dereg = mats_post * deregulated,
    mats_post_reg = mats_post * (1 - deregulated)
  )

# Split by market structure
m_mechanism <- feols(log_price ~ mats_post_reg + mats_post_dereg | state + year,
                     data = state_panel, cluster = ~state)

cat("\nMechanism: Regulated vs Deregulated:\n")
etable(m_mechanism)

# Also run separately
m_reg_only <- feols(log_price ~ mats_post | state + year,
                    data = state_panel %>% filter(deregulated == 0),
                    cluster = ~state)
m_dereg_only <- feols(log_price ~ mats_post | state + year,
                      data = state_panel %>% filter(deregulated == 1),
                      cluster = ~state)

cat("\nRegulated states only:\n")
etable(m_reg_only)
cat("\nDeregulated states only:\n")
etable(m_dereg_only)

# -----------------------------------------------------------------------
# 5. Sector-specific prices (residential, commercial, industrial)
# -----------------------------------------------------------------------
cat("\n=== Sector-Specific Price Effects ===\n")

eia_prices <- readRDS(file.path(data_dir, "eia_retail_prices.rds"))
state_retirements <- readRDS(file.path(data_dir, "state_retirements.rds"))

sector_panel <- eia_prices %>%
  filter(!is.na(state_id), nchar(state_id) == 2, sector %in% c("RES", "COM", "IND"),
         year >= 2005, year <= 2022) %>%
  rename(state = state_id) %>%
  left_join(state_retirements %>% select(state, mats_exposure = capacity_retired_share),
            by = "state") %>%
  filter(!is.na(mats_exposure)) %>%
  mutate(
    post_mats = as.integer(year >= 2015),
    mats_post = mats_exposure * post_mats,
    log_price = log(price_cents_kwh)
  )

m_res <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "RES"), cluster = ~state)
m_com <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "COM"), cluster = ~state)
m_ind <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "IND"), cluster = ~state)

cat("\nSector-specific price effects:\n")
etable(m_res, m_com, m_ind,
       headers = c("Residential", "Commercial", "Industrial"))

# -----------------------------------------------------------------------
# 6. Coal generation decline
# -----------------------------------------------------------------------
cat("\n=== Coal Generation Decline ===\n")

# State coal generation by year (from facility-fuel data)
plant_year <- readRDS(file.path(data_dir, "coal_plant_year.rds"))
state_coal_gen <- plant_year %>%
  group_by(year, state) %>%
  summarise(coal_gen_mwh = sum(generation_mwh, na.rm = TRUE), .groups = "drop")

coal_panel <- state_coal_gen %>%
  filter(year >= 2005, year <= 2022) %>%
  left_join(state_retirements %>% select(state, mats_exposure = capacity_retired_share),
            by = "state") %>%
  filter(!is.na(mats_exposure)) %>%
  mutate(
    post_mats = as.integer(year >= 2015),
    mats_post = mats_exposure * post_mats,
    log_coal_gen = log(coal_gen_mwh + 1)
  )

m_coal <- feols(log_coal_gen ~ mats_post | state + year,
                data = coal_panel, cluster = ~state)

cat("\nCoal generation decline:\n")
etable(m_coal)

# -----------------------------------------------------------------------
# 7. Write diagnostics.json for validator
# -----------------------------------------------------------------------
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(state_panel$mats_exposure > median(state_panel$mats_exposure, na.rm = TRUE) &
                  state_panel$post_mats == 1 & !duplicated(state_panel$state)),
  n_pre = length(unique(state_panel$year[state_panel$year < 2015])),
  n_obs = nrow(state_panel)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("  n_treated = %d, n_pre = %d, n_obs = %d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# -----------------------------------------------------------------------
# 8. Save all model objects for tables script
# -----------------------------------------------------------------------
save(m1_plant, m2_plant, m3_plant, m4_plant,
     m1_did, m2_did, m3_did,
     m_event,
     m_mechanism, m_reg_only, m_dereg_only,
     m_res, m_com, m_ind,
     m_coal,
     file = file.path(data_dir, "models.RData"))

cat("\nMain analysis complete. Model objects saved.\n")
