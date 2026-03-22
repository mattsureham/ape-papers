## 02_clean_data.R — Build county-year panel and define treatment
source("00_packages.R")

cbp_raw <- readRDS("../data/cbp_raw.rds")
acs_all <- readRDS("../data/acs_raw.rds")
rucc    <- readRDS("../data/rucc.rds")

# ---- Build county-year panel ----
panel <- cbp_raw %>%
  select(fips, year, naics, ESTAB) %>%
  mutate(
    store_type = case_when(
      naics == "445110" ~ "supermarket",
      naics == "445120" ~ "convenience",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(store_type)) %>%
  select(fips, year, store_type, estab = ESTAB)

# Pivot wider: one row per county-year
panel_wide <- panel %>%
  pivot_wider(
    names_from  = store_type,
    values_from = estab,
    values_fill = 0L
  ) %>%
  mutate(total_food = supermarket + convenience)

cat(sprintf("Panel: %d county-year obs, %d unique counties, years %d-%d\n",
            nrow(panel_wide), n_distinct(panel_wide$fips),
            min(panel_wide$year), max(panel_wide$year)))

# ---- Compute pre-reform treatment intensity ----
# Use 2015 as the base year (pre-announcement)
pre_reform <- panel_wide %>%
  filter(year == 2015) %>%
  mutate(
    conv_share_pre = convenience / pmax(total_food, 1)
  ) %>%
  select(fips, conv_share_pre, convenience_pre = convenience,
         supermarket_pre = supermarket, total_food_pre = total_food)

cat(sprintf("Pre-reform treatment intensity: mean=%.3f, sd=%.3f, p25=%.3f, p75=%.3f\n",
            mean(pre_reform$conv_share_pre, na.rm = TRUE),
            sd(pre_reform$conv_share_pre, na.rm = TRUE),
            quantile(pre_reform$conv_share_pre, 0.25, na.rm = TRUE),
            quantile(pre_reform$conv_share_pre, 0.75, na.rm = TRUE)))

# ---- Merge treatment intensity + demographics ----
analysis <- panel_wide %>%
  inner_join(pre_reform, by = "fips") %>%
  mutate(post = as.integer(year >= 2018)) %>%
  left_join(rucc, by = "fips")

# Merge ACS (use 2015 for pre-period demographics)
acs_base <- acs_all %>%
  filter(year == 2015) %>%
  select(fips, total_pop, poverty_rate, no_veh_share)

analysis <- analysis %>%
  left_join(acs_base, by = "fips")

# Drop counties with no food retailers in any year (noise)
county_max <- analysis %>%
  group_by(fips) %>%
  summarise(max_food = max(total_food, na.rm = TRUE)) %>%
  filter(max_food > 0)

analysis <- analysis %>%
  filter(fips %in% county_max$fips)

# Create log outcomes
analysis <- analysis %>%
  mutate(
    log_conv  = log(1 + convenience),
    log_super = log(1 + supermarket),
    log_total = log(1 + total_food)
  )

cat(sprintf("Analysis dataset: %d obs, %d counties, %d years\n",
            nrow(analysis), n_distinct(analysis$fips),
            n_distinct(analysis$year)))

# ---- High-poverty indicator ----
analysis <- analysis %>%
  mutate(
    high_poverty = as.integer(poverty_rate >= median(poverty_rate, na.rm = TRUE))
  )

# ---- Summary statistics ----
sumstats <- analysis %>%
  filter(!is.na(poverty_rate)) %>%
  summarise(
    across(
      c(convenience, supermarket, total_food, conv_share_pre,
        poverty_rate, no_veh_share, total_pop),
      list(
        mean = ~mean(.x, na.rm = TRUE),
        sd   = ~sd(.x, na.rm = TRUE),
        min  = ~min(.x, na.rm = TRUE),
        max  = ~max(.x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    ),
    N = n(),
    N_counties = n_distinct(fips)
  )

saveRDS(sumstats, "../data/sumstats.rds")
saveRDS(analysis, "../data/analysis.rds")

cat("Analysis dataset saved.\n")

# Print key stats
cat("\n=== Key Sample Statistics ===\n")
cat(sprintf("Observations: %d\n", nrow(analysis)))
cat(sprintf("Counties: %d\n", n_distinct(analysis$fips)))
cat(sprintf("Years: %d-%d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("Mean convenience stores per county: %.1f\n", mean(analysis$convenience, na.rm = TRUE)))
cat(sprintf("Mean supermarkets per county: %.1f\n", mean(analysis$supermarket, na.rm = TRUE)))
cat(sprintf("Mean pre-reform convenience share: %.3f\n", mean(analysis$conv_share_pre, na.rm = TRUE)))
