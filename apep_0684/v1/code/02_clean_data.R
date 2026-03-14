## 02_clean_data.R — Construct analysis datasets
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")

data_dir <- "../data"

# -----------------------------------------------------------------------
# 1. Load raw data
# -----------------------------------------------------------------------
cat("=== Loading raw data ===\n")

plant_year <- readRDS(file.path(data_dir, "coal_plant_year.rds"))
operating_gens <- readRDS(file.path(data_dir, "operating_coal_generators.rds"))
eia_prices <- readRDS(file.path(data_dir, "eia_retail_prices.rds"))
facility_fuel <- readRDS(file.path(data_dir, "facility_fuel_raw.rds"))

cat(sprintf("  Plant-year panel: %d rows, %d plants\n",
            nrow(plant_year), n_distinct(plant_year$plant_id)))
cat(sprintf("  Operating generators: %d\n", nrow(operating_gens)))
cat(sprintf("  Electricity prices: %d rows\n", nrow(eia_prices)))

# -----------------------------------------------------------------------
# 2. Identify MATS-era retirements
# -----------------------------------------------------------------------
cat("\n=== Identifying MATS Retirements ===\n")

# A plant is "active pre-MATS" if it had positive coal generation in 2010-2012
pre_mats_active <- plant_year %>%
  filter(year %in% 2010:2012) %>%
  group_by(plant_id, plant_name, state) %>%
  summarise(
    avg_gen_pre = mean(generation_mwh, na.rm = TRUE),
    avg_heat_rate_pre = mean(heat_rate, na.rm = TRUE),
    max_gen_pre = max(generation_mwh, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(avg_gen_pre > 0)  # Must have had positive generation

cat(sprintf("  Plants active in 2010-2012: %d\n", nrow(pre_mats_active)))

# Check generation in post-MATS period (2016-2020)
post_mats_gen <- plant_year %>%
  filter(year %in% 2016:2020) %>%
  group_by(plant_id) %>%
  summarise(
    avg_gen_post = mean(generation_mwh, na.rm = TRUE),
    max_gen_post = max(generation_mwh, na.rm = TRUE),
    years_with_gen = sum(generation_mwh > 0),
    .groups = "drop"
  )

# Merge pre and post
plant_panel <- pre_mats_active %>%
  left_join(post_mats_gen, by = "plant_id") %>%
  mutate(
    # Retirement: had generation pre-MATS, zero/negligible post-MATS
    retired = ifelse(is.na(avg_gen_post) | max_gen_post < 1000, 1L, 0L),
    # Generation decline ratio
    gen_decline = 1 - coalesce(avg_gen_post, 0) / avg_gen_pre
  )

cat(sprintf("  Plants retired (no generation 2016-2020): %d / %d (%.1f%%)\n",
            sum(plant_panel$retired), nrow(plant_panel),
            100 * mean(plant_panel$retired)))

# -----------------------------------------------------------------------
# 3. Construct pre-MATS plant characteristics
# -----------------------------------------------------------------------
cat("\n=== Constructing Plant Characteristics ===\n")

# Heat rate from 2010 facility-fuel data
heat_rate_2010 <- plant_year %>%
  filter(year == 2010, generation_mwh > 0) %>%
  select(plant_id, heat_rate_2010 = heat_rate, gen_2010 = generation_mwh)

# Capacity from operating generators (for plants still operating)
plant_capacity <- operating_gens %>%
  group_by(plant_id) %>%
  summarise(
    total_capacity_mw = sum(nameplate_mw, na.rm = TRUE),
    total_summer_mw = sum(summer_mw, na.rm = TRUE),
    n_generators = n(),
    county = first(county),
    latitude = first(latitude),
    longitude = first(longitude),
    operating_year = min(operating_year, na.rm = TRUE),
    sector = first(sector),
    entity_name = first(entity_name),
    balancing_auth = first(balancing_auth),
    .groups = "drop"
  ) %>%
  mutate(
    vintage_year = as.integer(substr(operating_year, 1, 4))
  )

# For plants not in operating_gens (i.e., retired), estimate capacity from peak generation
# Typical coal capacity factor ~0.5-0.7, so peak_gen / (8760 * 0.6) ≈ capacity
peak_gen <- plant_year %>%
  filter(year %in% 2003:2012) %>%
  group_by(plant_id) %>%
  summarise(peak_gen_mwh = max(generation_mwh, na.rm = TRUE), .groups = "drop") %>%
  mutate(est_capacity_mw = peak_gen_mwh / (8760 * 0.60))

# Merge all characteristics
plant_chars <- plant_panel %>%
  left_join(heat_rate_2010, by = "plant_id") %>%
  left_join(plant_capacity, by = "plant_id") %>%
  left_join(peak_gen, by = "plant_id") %>%
  mutate(
    # Use observed capacity if available, otherwise estimated
    capacity_mw = coalesce(total_capacity_mw, est_capacity_mw),
    # Heat rate from 2010 data
    heat_rate = coalesce(heat_rate_2010, avg_heat_rate_pre),
    # Compute log heat rate for regression
    log_heat_rate = log(heat_rate),
    # Log capacity
    log_capacity = log(capacity_mw + 1),
    # Age as of MATS finalization (2012)
    plant_age_2012 = ifelse(!is.na(vintage_year), 2012 - vintage_year, NA)
  )

cat(sprintf("  Plants with heat rate: %d / %d\n",
            sum(!is.na(plant_chars$heat_rate)), nrow(plant_chars)))
cat(sprintf("  Plants with capacity: %d / %d\n",
            sum(!is.na(plant_chars$capacity_mw)), nrow(plant_chars)))
cat(sprintf("  Plants with vintage: %d / %d\n",
            sum(!is.na(plant_chars$vintage_year)), nrow(plant_chars)))

# -----------------------------------------------------------------------
# 4. State-level analysis panel
# -----------------------------------------------------------------------
cat("\n=== Constructing State-Level Panel ===\n")

# Aggregate plant retirements to state level
state_retirements <- plant_chars %>%
  group_by(state) %>%
  summarise(
    n_plants_pre = n(),
    n_retired = sum(retired),
    retirement_rate = mean(retired),
    total_capacity_mw = sum(capacity_mw, na.rm = TRUE),
    retired_capacity_mw = sum(capacity_mw * retired, na.rm = TRUE),
    capacity_retired_share = retired_capacity_mw / total_capacity_mw,
    avg_heat_rate = mean(heat_rate, na.rm = TRUE),
    .groups = "drop"
  )

# State coal generation by year
state_coal_gen <- plant_year %>%
  group_by(year, state) %>%
  summarise(coal_gen_mwh = sum(generation_mwh, na.rm = TRUE), .groups = "drop")

# Baseline coal share (2010)
baseline_coal <- state_coal_gen %>%
  filter(year == 2010) %>%
  select(state, baseline_coal_gen = coal_gen_mwh)

# Electricity prices — ALL sector
state_prices <- eia_prices %>%
  filter(sector == "ALL", !is.na(state_id), nchar(state_id) == 2) %>%
  select(year, state = state_id, price_cents_kwh, sales_mwh, revenue_thou) %>%
  filter(year >= 2005, year <= 2022)

# Merge into state-year panel
state_panel <- state_prices %>%
  left_join(state_retirements, by = "state") %>%
  left_join(baseline_coal, by = "state") %>%
  left_join(state_coal_gen, by = c("year", "state")) %>%
  mutate(
    # Coal share over time
    coal_share = coal_gen_mwh / sales_mwh,
    # Baseline coal share
    baseline_coal_share = baseline_coal_gen / sales_mwh,
    # Post-MATS dummy (compliance deadline April 2015)
    post_mats = as.integer(year >= 2015),
    # Treatment intensity: MATS exposure
    mats_exposure = coalesce(capacity_retired_share, 0),
    # Interaction
    mats_post = mats_exposure * post_mats,
    # Log price
    log_price = log(price_cents_kwh)
  ) %>%
  filter(!is.na(price_cents_kwh))

# Only keep states that had coal plants
state_panel <- state_panel %>%
  filter(!is.na(n_plants_pre) & n_plants_pre > 0)

cat(sprintf("State panel: %d state-years, %d states, years %d-%d\n",
            nrow(state_panel), n_distinct(state_panel$state),
            min(state_panel$year), max(state_panel$year)))

# -----------------------------------------------------------------------
# 5. Summary statistics
# -----------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

cat("Plant-level:\n")
cat(sprintf("  N plants: %d\n", nrow(plant_chars)))
cat(sprintf("  Retired: %d (%.1f%%)\n",
            sum(plant_chars$retired), 100 * mean(plant_chars$retired)))
cat(sprintf("  Mean heat rate: %.0f BTU/MWh\n", mean(plant_chars$heat_rate, na.rm = TRUE)))
cat(sprintf("  Mean capacity: %.0f MW\n", mean(plant_chars$capacity_mw, na.rm = TRUE)))
cat(sprintf("  Median plant age (2012): %.0f years\n",
            median(plant_chars$plant_age_2012, na.rm = TRUE)))

cat("\nState-level:\n")
cat(sprintf("  N states with coal: %d\n", n_distinct(state_panel$state)))
cat(sprintf("  Mean retirement rate: %.1f%%\n", 100 * mean(state_retirements$retirement_rate)))
cat(sprintf("  Mean capacity retired share: %.1f%%\n",
            100 * mean(state_retirements$capacity_retired_share, na.rm = TRUE)))

# -----------------------------------------------------------------------
# 6. Save analysis datasets
# -----------------------------------------------------------------------
saveRDS(plant_chars, file.path(data_dir, "plant_chars.rds"))
saveRDS(state_panel, file.path(data_dir, "state_panel.rds"))
saveRDS(state_retirements, file.path(data_dir, "state_retirements.rds"))

cat("\nAnalysis datasets saved.\n")
