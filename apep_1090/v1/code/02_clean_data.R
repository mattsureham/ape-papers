## 02_clean_data.R — Construct analysis panel
## apep_1090: The Compliance Trap

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load all data
# ============================================================
cbp <- readRDS(file.path(data_dir, "cbp_stores.rds"))
acs_snap <- readRDS(file.path(data_dir, "acs_snap_county.rds"))
acs_pop <- readRDS(file.path(data_dir, "acs_population.rds"))
acs_pov <- readRDS(file.path(data_dir, "acs_poverty.rds"))

cat("CBP rows:", nrow(cbp), "\n")
cat("ACS SNAP rows:", nrow(acs_snap), "\n")
cat("ACS Pop rows:", nrow(acs_pop), "\n")

# ============================================================
# 2. Construct treatment intensity from 2016 CBP
# ============================================================
# Use 2016 (last year with NAICS2012, full coverage) as pre-treatment baseline.
# Treatment intensity = convenience stores / (convenience + supermarket) per county.

cat("\n=== Constructing treatment intensity ===\n")

# Use 2015-2016 average for stability (both have good coverage)
cbp_pre <- cbp %>%
  filter(year %in% c(2015, 2016)) %>%
  group_by(fips, store_type) %>%
  summarise(estab = mean(estab, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = store_type, values_from = estab, values_fill = 0)

# Compute convenience store share
cbp_pre <- cbp_pre %>%
  mutate(
    total_food_retail = convenience + supermarket,
    cs_share = ifelse(total_food_retail > 0,
                      convenience / total_food_retail, NA),
    cs_dominant = cs_share > 0.5
  )

cat("Counties with both types:", sum(cbp_pre$total_food_retail > 0), "\n")
cat("Mean CS share:", round(mean(cbp_pre$cs_share, na.rm = TRUE), 3), "\n")
cat("Median CS share:", round(median(cbp_pre$cs_share, na.rm = TRUE), 3), "\n")

# Distribution of CS share
cat("\nCS share distribution:\n")
print(summary(cbp_pre$cs_share))

# ============================================================
# 3. Build ACS panel
# ============================================================
cat("\n=== Building ACS panel ===\n")

# Clean SNAP data
snap_panel <- acs_snap %>%
  select(fips, year, snap_hhE, snap_hhM, total_hhE, total_hhM) %>%
  rename(
    snap_hh = snap_hhE,
    snap_hh_moe = snap_hhM,
    total_hh = total_hhE,
    total_hh_moe = total_hhM
  ) %>%
  mutate(
    snap_rate = ifelse(total_hh > 0, snap_hh / total_hh, NA)
  )

# Clean population data
pop_panel <- acs_pop %>%
  select(fips, year, total_popE) %>%
  rename(population = total_popE)

# Clean poverty data
pov_panel <- acs_pov %>%
  select(fips, year, total_pov_universeE, below_povertyE) %>%
  rename(
    pov_universe = total_pov_universeE,
    below_poverty = below_povertyE
  ) %>%
  mutate(
    poverty_rate = ifelse(pov_universe > 0, below_poverty / pov_universe, NA)
  )

# ============================================================
# 4. Merge into analysis panel
# ============================================================
cat("\n=== Merging analysis panel ===\n")

panel <- snap_panel %>%
  left_join(pop_panel, by = c("fips", "year")) %>%
  left_join(pov_panel, by = c("fips", "year")) %>%
  left_join(
    cbp_pre %>% select(fips, cs_share, convenience, supermarket,
                        total_food_retail, cs_dominant),
    by = "fips"
  )

# Add treatment timing
# Depth-of-stock took effect Jan 17, 2018
# ACS 5-year estimates: 2018 vintage covers 2014-2018 (partial exposure)
# Clean post period starts with 2019 vintage (2015-2019)
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2019),  # Conservative: 2019+ as post
    post_2018 = as.integer(year >= 2018),  # Alternative: 2018+ (includes transition)
    state_fips = substr(fips, 1, 2),
    # Treatment intensity interaction
    treat_intensity = cs_share * post,
    treat_intensity_2018 = cs_share * post_2018,
    # SNAP per capita
    snap_per_1000 = ifelse(population > 0, snap_hh / population * 1000, NA),
    # Log outcomes
    log_snap_rate = log(snap_rate + 0.001),
    log_snap_hh = log(snap_hh + 1)
  )

# Filter to counties with valid treatment intensity
panel <- panel %>%
  filter(!is.na(cs_share), !is.na(snap_rate), population > 100)

cat("Panel dimensions:", nrow(panel), "county-years\n")
cat("Unique counties:", n_distinct(panel$fips), "\n")
cat("Year range:", min(panel$year), "-", max(panel$year), "\n")

# Balance check
panel_balanced <- panel %>%
  group_by(fips) %>%
  filter(n() == 10) %>%  # All 10 years 2013-2022
  ungroup()

cat("Balanced panel:", nrow(panel_balanced), "obs,",
    n_distinct(panel_balanced$fips), "counties\n")

# ============================================================
# 5. Descriptive statistics
# ============================================================
cat("\n=== Descriptive Statistics ===\n")

# Pre-period means by treatment intensity tercile
panel_balanced <- panel_balanced %>%
  mutate(
    cs_tercile = ntile(cs_share, 3),
    cs_tercile_label = case_when(
      cs_tercile == 1 ~ "Low CS share",
      cs_tercile == 2 ~ "Medium CS share",
      cs_tercile == 3 ~ "High CS share"
    )
  )

cat("\nPre-period (2013-2017) means by treatment tercile:\n")
pre_means <- panel_balanced %>%
  filter(year <= 2017) %>%
  group_by(cs_tercile_label) %>%
  summarise(
    n_counties = n_distinct(fips),
    mean_snap_rate = round(mean(snap_rate, na.rm = TRUE), 4),
    mean_poverty = round(mean(poverty_rate, na.rm = TRUE), 4),
    mean_pop = round(mean(population, na.rm = TRUE)),
    mean_cs_share = round(mean(cs_share, na.rm = TRUE), 3),
    .groups = "drop"
  )
print(pre_means)

# ============================================================
# 6. Save analysis datasets
# ============================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(panel_balanced, file.path(data_dir, "analysis_panel_balanced.rds"))
saveRDS(cbp_pre, file.path(data_dir, "cbp_pre_treatment.rds"))

cat("\n=== Panel construction complete ===\n")
cat("Key files: analysis_panel.rds, analysis_panel_balanced.rds\n")
