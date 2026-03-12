## 02_clean_data.R — Construct treatment intensity and analysis panel
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

source("00_packages.R")

## ------------------------------------------------------------------
## Load raw data
## ------------------------------------------------------------------
df_raw <- read_csv("../data/bdl_raw.csv", show_col_types = FALSE)

cat(sprintf("Loaded %d observations across %d variables\n",
            nrow(df_raw), n_distinct(df_raw$variable)))

## ------------------------------------------------------------------
## Pivot to wide format: one row per powiat-year
## ------------------------------------------------------------------
df_wide <- df_raw %>%
  select(powiat_id, powiat_name, year, variable, value) %>%
  pivot_wider(names_from = variable, values_from = value,
              values_fn = first) %>%
  arrange(powiat_id, year)

cat(sprintf("Panel: %d powiat-years (%d powiats × %d years)\n",
            nrow(df_wide), n_distinct(df_wide$powiat_id),
            n_distinct(df_wide$year)))

## ------------------------------------------------------------------
## Construct treatment intensity
## ------------------------------------------------------------------
## The Bartik treatment is:
##   Intensity_i = (births_per_capita_2015_i) × national_transfer
##
## Rationale: powiats with higher birth rates in 2015 had more
## children per capita, thus received more 500+ transfers per capita.
## This is a clean pre-program measure of child density.
##
## If household composition data is available, we use:
##   share_2plus = (hh_2children + hh_3plus) / total_households
## Otherwise: births / population as proxy for child density.

hh_file <- "../data/household_composition.csv"
young_file <- "../data/young_population.csv"

if (file.exists(hh_file)) {
  cat("Using household composition data for treatment intensity.\n")
  df_hh <- read_csv(hh_file, show_col_types = FALSE) %>%
    pivot_wider(names_from = variable, values_from = value) %>%
    mutate(
      hh_2plus = hh_2children + hh_3plus_children,
      hh_total_with_kids = hh_1child + hh_2children + hh_3plus_children,
      share_2plus = hh_2plus / hh_total_with_kids
    ) %>%
    select(powiat_id, share_2plus, hh_total_with_kids)

  # Merge treatment intensity
  df_wide <- df_wide %>%
    left_join(df_hh, by = "powiat_id")

  treatment_var <- "share_2plus"

} else if (file.exists(young_file)) {
  cat("Using young population data for treatment intensity.\n")
  df_young <- read_csv(young_file, show_col_types = FALSE) %>%
    filter(year == 2015) %>%
    select(powiat_id, young_pop = value)

  # Get 2015 population
  pop_2015 <- df_wide %>%
    filter(year == 2015) %>%
    select(powiat_id, pop_2015 = population)

  df_wide <- df_wide %>%
    left_join(
      df_young %>%
        left_join(pop_2015, by = "powiat_id") %>%
        mutate(child_share_2015 = young_pop / pop_2015) %>%
        select(powiat_id, child_share_2015),
      by = "powiat_id"
    )

  treatment_var <- "child_share_2015"

} else {
  cat("Using birth rate as proxy for treatment intensity.\n")

  ## Construct average birth rate 2013-2015 as treatment proxy
  birth_rate <- df_wide %>%
    filter(year %in% 2013:2015) %>%
    group_by(powiat_id) %>%
    summarise(
      avg_births = mean(births, na.rm = TRUE),
      avg_pop = mean(population, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(birth_rate_2015 = avg_births / avg_pop * 1000) %>%
    select(powiat_id, birth_rate_2015)

  df_wide <- df_wide %>%
    left_join(birth_rate, by = "powiat_id")

  treatment_var <- "birth_rate_2015"
}

cat(sprintf("Treatment variable: %s\n", treatment_var))

## ------------------------------------------------------------------
## Standardize treatment intensity (mean 0, sd 1) for interpretation
## ------------------------------------------------------------------
df_wide <- df_wide %>%
  mutate(
    intensity_raw = .data[[treatment_var]],
    intensity = (intensity_raw - mean(intensity_raw, na.rm = TRUE)) /
      sd(intensity_raw, na.rm = TRUE)
  )

## ------------------------------------------------------------------
## Construct outcome rates (per capita where relevant)
## ------------------------------------------------------------------
df_wide <- df_wide %>%
  mutate(
    biz_rate = new_biz_per10k,  # already per 10K
    # unemp_rate already fetched as percentage from BDL
    birth_rate = births / population * 1000,
    marriage_rate = marriages / population * 1000,
    log_pop = log(population)
  )

## ------------------------------------------------------------------
## Construct treatment interaction variables
## ------------------------------------------------------------------
df_wide <- df_wide %>%
  mutate(
    post2016 = as.integer(year >= 2016),
    post2019 = as.integer(year >= 2019),
    treat_post = intensity * post2016,
    treat_post2 = intensity * post2019,
    # Event time dummies for event study
    event_time = year - 2016
  )

## ------------------------------------------------------------------
## Extract voivodeship from powiat_id for regional FE
## ------------------------------------------------------------------
# Polish powiat IDs: first 2 digits = voivodeship code
df_wide <- df_wide %>%
  mutate(
    voivodeship = substr(powiat_id, 1, 4)
  )

## ------------------------------------------------------------------
## Identify city-powiats (grodzkie) for heterogeneity
## ------------------------------------------------------------------
# City powiats typically have IDs ending in 01 at the city level
# or their names contain "City" or "miasto"
df_wide <- df_wide %>%
  mutate(
    is_city_powiat = grepl("(?i)(city|miasto|capital|m\\.)", powiat_name)
  )

## ------------------------------------------------------------------
## Validate panel completeness
## ------------------------------------------------------------------
panel_balance <- df_wide %>%
  group_by(powiat_id) %>%
  summarise(n_years = n(), .groups = "drop")

cat(sprintf("Panel balance: %d powiats with %d years (%.1f%% balanced)\n",
            sum(panel_balance$n_years == max(panel_balance$n_years)),
            max(panel_balance$n_years),
            mean(panel_balance$n_years == max(panel_balance$n_years)) * 100))

## Drop powiats with incomplete data
complete_powiats <- panel_balance %>%
  filter(n_years >= 10) %>%
  pull(powiat_id)

df_panel <- df_wide %>%
  filter(powiat_id %in% complete_powiats)

n_final <- n_distinct(df_panel$powiat_id)
cat(sprintf("Final panel: %d powiats × %d years = %d observations\n",
            n_final, n_distinct(df_panel$year), nrow(df_panel)))

stopifnot("Need at least 300 powiats" = n_final >= 300)

## ------------------------------------------------------------------
## Summary statistics
## ------------------------------------------------------------------
cat("\n--- Pre-treatment summary (2010-2015) ---\n")
df_panel %>%
  filter(year <= 2015) %>%
  summarise(
    across(c(biz_rate, unemp_rate, birth_rate, marriage_rate,
             infant_mortality_per1k, population, intensity_raw),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(everything()) %>%
  print(n = 50)

## ------------------------------------------------------------------
## Treatment intensity distribution
## ------------------------------------------------------------------
cat("\n--- Treatment intensity distribution ---\n")
df_panel %>%
  filter(year == 2015) %>%
  summarise(
    mean = mean(intensity_raw, na.rm = TRUE),
    sd = sd(intensity_raw, na.rm = TRUE),
    p10 = quantile(intensity_raw, 0.1, na.rm = TRUE),
    p25 = quantile(intensity_raw, 0.25, na.rm = TRUE),
    p50 = quantile(intensity_raw, 0.5, na.rm = TRUE),
    p75 = quantile(intensity_raw, 0.75, na.rm = TRUE),
    p90 = quantile(intensity_raw, 0.9, na.rm = TRUE)
  ) %>%
  print()

## ------------------------------------------------------------------
## Save
## ------------------------------------------------------------------
write_csv(df_panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")
