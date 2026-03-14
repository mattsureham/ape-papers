## 02_clean_data.R — Clean and construct analysis panels
## apep_0675

source("00_packages.R")

## ── Load raw data ──
gas_prices <- readRDS("../data/gas_prices_raw.rds")
hh_energy  <- readRDS("../data/hh_energy_raw.rds")
epov       <- readRDS("../data/energy_poverty_raw.rds")
hdd_raw    <- readRDS("../data/hdd_raw.rds")

## ── Carbon tax treatment assignment ──
treated_countries <- tribble(
  ~geo,  ~country_name,   ~treat_year, ~treat_half, ~treat_period,
  "IE",  "Ireland",        2010,        1,           "2010-S1",
  "FR",  "France",         2014,        2,           "2014-S2",
  "PT",  "Portugal",       2015,        1,           "2015-S1",
  "DE",  "Germany",        2021,        1,           "2021-S1",
  "AT",  "Austria",        2022,        1,           "2022-S1"
)

## ═══════════════════════════════════════════════
## PANEL A: Gas Price Pass-Through (semi-annual)
## ═══════════════════════════════════════════════

cat("=== Building gas price panel ===\n")

## Band D2 = GJ20-199 (medium household 20-200 GJ)
## I_TAX = price including all taxes; X_TAX = price excluding all taxes
price_panel <- gas_prices %>%
  filter(
    nrg_cons == "GJ20-199",
    unit     == "KWH",
    currency == "EUR",
    tax %in% c("I_TAX", "X_TAX")
  ) %>%
  select(geo, TIME_PERIOD, tax, values) %>%
  pivot_wider(names_from = tax, values_from = values) %>%
  rename(price_incl_tax = I_TAX, price_excl_tax = X_TAX) %>%
  mutate(
    tax_wedge = price_incl_tax - price_excl_tax,
    year      = as.integer(substr(TIME_PERIOD, 1, 4)),
    half      = as.integer(substr(TIME_PERIOD, 7, 7)),
    period_num = (year - 2007) * 2 + half
  ) %>%
  filter(!is.na(price_incl_tax), !is.na(price_excl_tax)) %>%
  ## Keep 2-letter country codes only (exclude aggregates like EU27, EA19)
  filter(nchar(geo) == 2) %>%
  left_join(treated_countries %>% select(geo, treat_year, treat_half, treat_period),
            by = "geo") %>%
  mutate(
    treated = if_else(!is.na(treat_year), 1L, 0L),
    treat_period_num = if_else(treated == 1L,
                               (treat_year - 2007) * 2 + treat_half,
                               0L),
    rel_period = if_else(treated == 1L, period_num - treat_period_num, NA_integer_),
    post = if_else(treated == 1L & period_num >= treat_period_num, 1L, 0L)
  )

cat(sprintf("  Price panel: %d obs, %d countries, years %d-%d\n",
            nrow(price_panel),
            n_distinct(price_panel$geo),
            min(price_panel$year),
            max(price_panel$year)))

## Show treated countries tax wedge change
for (g in c("IE", "FR", "PT", "DE", "AT")) {
  d <- price_panel %>% filter(geo == g) %>% arrange(TIME_PERIOD)
  tw_range <- range(d$tax_wedge, na.rm = TRUE)
  cat(sprintf("  %s: tax wedge %.4f - %.4f\n", g, tw_range[1], tw_range[2]))
}

## ═══════════════════════════════════════════════
## PANEL B: Gas Consumption (annual country-level)
## ═══════════════════════════════════════════════

cat("=== Building consumption panel ===\n")

cons_panel <- hh_energy %>%
  filter(
    siec == "G3000",             # Natural gas
    unit == "TJ",                # Terajoules
    nrg_bal == "FC_OTH_HH_E"    # Final consumption - households - energy use
  ) %>%
  select(geo, TIME_PERIOD, values) %>%
  rename(gas_consumption_tj = values) %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  filter(!is.na(gas_consumption_tj), gas_consumption_tj > 0,
         nchar(geo) == 2)

## Annual prices (average of S1 and S2)
annual_prices <- price_panel %>%
  group_by(geo, year) %>%
  summarise(
    price_incl = mean(price_incl_tax, na.rm = TRUE),
    price_excl = mean(price_excl_tax, na.rm = TRUE),
    tax_wedge  = mean(tax_wedge, na.rm = TRUE),
    .groups = "drop"
  )

## HDD
hdd_clean <- hdd_raw %>%
  filter(indic_nrg == "HDD") %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  select(geo, year, hdd = values) %>%
  filter(!is.na(hdd), nchar(geo) == 2)

iv_panel <- cons_panel %>%
  inner_join(annual_prices, by = c("geo", "year")) %>%
  inner_join(hdd_clean, by = c("geo", "year")) %>%
  left_join(treated_countries %>% select(geo, treat_year), by = "geo") %>%
  mutate(
    log_q = log(gas_consumption_tj),
    log_p = log(price_incl),
    log_tax = log(pmax(tax_wedge, 0.001)),
    log_hdd = log(hdd),
    treated = if_else(!is.na(treat_year), 1L, 0L)
  ) %>%
  filter(is.finite(log_q), is.finite(log_p), is.finite(log_tax))

cat(sprintf("  IV panel: %d obs, %d countries, years %d-%d\n",
            nrow(iv_panel),
            n_distinct(iv_panel$geo),
            min(iv_panel$year),
            max(iv_panel$year)))

## ═══════════════════════════════════════════════
## PANEL C: Energy Poverty (annual, for CS-DiD)
## ═══════════════════════════════════════════════

cat("=== Building energy poverty panel ===\n")

epov_panel <- epov %>%
  filter(
    incgrp == "TOTAL",
    hhtyp  == "TOTAL",
    unit   == "PC"
  ) %>%
  select(geo, TIME_PERIOD, values) %>%
  rename(pct_unable_warm = values) %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  filter(!is.na(pct_unable_warm),
         nchar(geo) == 2,
         !geo %in% c("EU", "EA")) %>%
  left_join(treated_countries %>% select(geo, treat_year), by = "geo") %>%
  mutate(
    first_treat = if_else(!is.na(treat_year), treat_year, 0L)
  )

cat(sprintf("  Energy poverty panel: %d obs, %d countries, years %d-%d\n",
            nrow(epov_panel),
            n_distinct(epov_panel$geo),
            min(epov_panel$year),
            max(epov_panel$year)))

## By income group for heterogeneity (below/above 60% median income)
epov_income <- epov %>%
  filter(
    incgrp %in% c("A_MD60", "B_MD60"),  # below/above 60% median
    hhtyp  == "TOTAL",
    unit   == "PC"
  ) %>%
  select(geo, TIME_PERIOD, incgrp, values) %>%
  rename(pct_unable_warm = values) %>%
  mutate(year = as.integer(TIME_PERIOD),
         low_income = if_else(incgrp == "A_MD60", 1L, 0L)) %>%
  filter(!is.na(pct_unable_warm),
         nchar(geo) == 2,
         !geo %in% c("EU", "EA")) %>%
  left_join(treated_countries %>% select(geo, treat_year), by = "geo") %>%
  mutate(first_treat = if_else(!is.na(treat_year), treat_year, 0L))

cat(sprintf("  Energy poverty by income: %d obs\n", nrow(epov_income)))

## ── Save cleaned panels ──
saveRDS(price_panel, "../data/price_panel.rds")
saveRDS(iv_panel, "../data/iv_panel.rds")
saveRDS(epov_panel, "../data/epov_panel.rds")
saveRDS(epov_income, "../data/epov_income.rds")

cat("=== All panels saved ===\n")
