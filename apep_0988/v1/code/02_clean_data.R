# 02_clean_data.R — Construct analysis panel for Poland Sunday Trading Ban
# Unit: NUTS-3 region × year
# Treatment: baseline trade-sector employment share × phase intensity

source("00_packages.R")

# ============================================================================
# Step 1: Load employment data and construct trade share
# ============================================================================

emp <- readRDS("../data/employment_eurostat.rds")

cat("Employment data columns:", paste(names(emp), collapse = ", "), "\n")
cat("NACE sections:\n")
print(sort(unique(emp$nace_r2)))

# Identify trade-relevant NACE sections
# G-I = Wholesale/retail trade, transport, accommodation, food
# TOTAL = Total employment
# We want the trade share = G-I / TOTAL

# Filter to Poland NUTS-3 level (5-char codes like PL213)
pl_emp <- emp %>%
  filter(substr(geo, 1, 2) == "PL",
         nchar(geo) == 5,
         nace_r2 %in% c("G-I", "TOTAL"),
         unit == "THS",
         wstatus == "EMP") %>%
  select(geo, year, nace_r2, values)

cat(sprintf("Polish NUTS-3 employment: %d rows\n", nrow(pl_emp)))

# Pivot to wide: one column per NACE section
pl_wide <- pl_emp %>%
  pivot_wider(names_from = nace_r2, values_from = values,
              names_prefix = "emp_") %>%
  rename(emp_trade = `emp_G-I`, emp_total = emp_TOTAL)

cat(sprintf("Wide panel: %d region-years\n", nrow(pl_wide)))
cat(sprintf("Regions: %d | Years: %s\n",
            n_distinct(pl_wide$geo),
            paste(range(pl_wide$year, na.rm=TRUE), collapse="-")))

# ============================================================================
# Step 2: Construct baseline (2017) trade employment share
# ============================================================================

baseline <- pl_wide %>%
  filter(year == 2017) %>%
  mutate(trade_share_2017 = emp_trade / emp_total) %>%
  select(geo, trade_share_2017, emp_trade_2017 = emp_trade, emp_total_2017 = emp_total)

cat(sprintf("Baseline 2017: %d regions with data\n", nrow(baseline)))
cat(sprintf("Trade share: mean=%.3f, sd=%.3f, range=[%.3f, %.3f]\n",
            mean(baseline$trade_share_2017, na.rm=TRUE),
            sd(baseline$trade_share_2017, na.rm=TRUE),
            min(baseline$trade_share_2017, na.rm=TRUE),
            max(baseline$trade_share_2017, na.rm=TRUE)))

# Drop regions without valid baseline
baseline <- baseline %>% filter(!is.na(trade_share_2017) & trade_share_2017 > 0)
cat(sprintf("Regions with valid baseline: %d\n", nrow(baseline)))

# ============================================================================
# Step 3: Construct treatment variables
# ============================================================================

# Phase definitions:
# Pre-reform: before March 2018 → Phase = 0
# Phase 1: 2018 (partial year, ~2 open Sundays/month) → intensity = 0.5
# Phase 2: 2019 (1 open Sunday/month) → intensity = 0.75
# Phase 3: 2020+ (7 exempted Sundays/year) → intensity = 0.93

# Since data is annual, we use:
# 2018 = partial phase (March start → ~10/12 months at Phase 1) ≈ 0.42
# 2019 = full Phase 2 = 0.75
# 2020 = Phase 3 = 0.93
# 2021-2022 = Phase 3 = 0.93

panel <- pl_wide %>%
  inner_join(baseline, by = "geo") %>%
  mutate(
    # Phase indicators
    phase1 = as.numeric(year == 2018),
    phase2 = as.numeric(year == 2019),
    phase3 = as.numeric(year >= 2020),
    post = as.numeric(year >= 2018),

    # Continuous treatment intensity (national)
    ban_intensity = case_when(
      year < 2018 ~ 0,
      year == 2018 ~ 0.42,  # ~10 months at ~50% restriction
      year == 2019 ~ 0.75,  # Full year at ~75% restriction
      year >= 2020 ~ 0.93,  # Full year at ~93% restriction
      TRUE ~ 0
    ),

    # Main treatment: trade share × ban intensity
    treatment = trade_share_2017 * ban_intensity,

    # Phase-specific treatments
    treat_phase1 = trade_share_2017 * phase1,
    treat_phase2 = trade_share_2017 * phase2,
    treat_phase3 = trade_share_2017 * phase3,

    # Outcome: log employment
    log_emp_trade = log(emp_trade),
    log_emp_total = log(emp_total),

    # Trade share (time-varying, for descriptive)
    trade_share = emp_trade / emp_total,

    # High-exposure indicator (above-median trade share in 2017)
    high_trade = as.numeric(trade_share_2017 > median(baseline$trade_share_2017, na.rm=TRUE)),

    # NUTS-2 (voivodeship) for clustering
    nuts2 = substr(geo, 1, 4)
  )

# ============================================================================
# Step 4: Add other outcomes (unemployment, GDP)
# ============================================================================

# Unemployment
if (file.exists("../data/unemployment_eurostat.rds")) {
  unemp <- readRDS("../data/unemployment_eurostat.rds")
  if ("TIME_PERIOD" %in% names(unemp)) {
    unemp$year <- as.numeric(format(unemp$TIME_PERIOD, "%Y"))
  } else if ("time" %in% names(unemp)) {
    unemp$year <- as.numeric(unemp$time)
  }

  # Get total unemployment rate for Poland NUTS-3
  unemp_pl <- unemp %>%
    filter(substr(geo, 1, 2) == "PL",
           nchar(geo) == 5) %>%
    # Filter to total sex/age where possible
    group_by(geo, year) %>%
    summarise(unemp_rate = mean(values, na.rm = TRUE), .groups = "drop")

  panel <- panel %>%
    left_join(unemp_pl, by = c("geo", "year"))

  cat(sprintf("Unemployment merged: %d non-missing\n",
              sum(!is.na(panel$unemp_rate))))
}

# GDP per capita
if (file.exists("../data/gdp_eurostat.rds")) {
  gdp <- readRDS("../data/gdp_eurostat.rds")
  if ("TIME_PERIOD" %in% names(gdp)) gdp$year <- as.numeric(format(gdp$TIME_PERIOD, "%Y"))
  else if ("time" %in% names(gdp)) gdp$year <- as.numeric(gdp$time)

  # Check available units
  cat("GDP units:", paste(unique(gdp$unit), collapse=", "), "\n")
  gdp_unit <- if ("MIO_EUR" %in% gdp$unit) "MIO_EUR" else unique(gdp$unit)[1]
  gdp_pl <- gdp %>%
    filter(substr(geo, 1, 2) == "PL",
           nchar(geo) == 5,
           unit == gdp_unit) %>%
    select(geo, year, gdp_mio = values)

  panel <- panel %>%
    left_join(gdp_pl, by = c("geo", "year"))

  cat(sprintf("GDP merged: %d non-missing\n", sum(!is.na(panel$gdp_mio))))
}

# ============================================================================
# Step 5: Also add non-trade employment as placebo outcomes
# ============================================================================

# B-E = Industry (except construction)
# F = Construction
# O-Q = Public admin, education, health

pl_placebo <- emp %>%
  filter(substr(geo, 1, 2) == "PL",
         nchar(geo) == 5,
         nace_r2 %in% c("B-E", "F", "O-Q"),
         unit == "THS",
         wstatus == "EMP") %>%
  select(geo, year, nace_r2, values) %>%
  pivot_wider(names_from = nace_r2, values_from = values,
              names_prefix = "emp_") %>%
  rename(emp_industry = `emp_B-E`, emp_construction = emp_F,
         emp_public = `emp_O-Q`) %>%
  mutate(
    log_emp_industry = log(emp_industry),
    log_emp_construction = log(emp_construction),
    log_emp_public = log(emp_public)
  )

panel <- panel %>%
  left_join(pl_placebo, by = c("geo", "year"))

# ============================================================================
# Step 6: Build comparison country panels (for cross-country analysis)
# ============================================================================

# Czech Republic and Slovakia NUTS-3
comp_emp <- emp %>%
  filter(substr(geo, 1, 2) %in% c("CZ", "SK"),
         nchar(geo) == 5,
         nace_r2 %in% c("G-I", "TOTAL"),
         unit == "THS",
         wstatus == "EMP") %>%
  select(geo, year, nace_r2, values) %>%
  pivot_wider(names_from = nace_r2, values_from = values,
              names_prefix = "emp_") %>%
  rename(emp_trade = `emp_G-I`, emp_total = emp_TOTAL) %>%
  mutate(
    log_emp_trade = log(emp_trade),
    country = substr(geo, 1, 2),
    treated_country = 0  # Not treated
  )

# Add Poland with treated_country = 1
pl_for_comp <- panel %>%
  select(geo, year, emp_trade, emp_total, log_emp_trade) %>%
  mutate(country = "PL", treated_country = 1)

cross_country <- bind_rows(pl_for_comp, comp_emp) %>%
  mutate(
    post = as.numeric(year >= 2018),
    treat_x_post = treated_country * post,
    nuts2 = substr(geo, 1, 4)
  )

cat(sprintf("Cross-country panel: %d region-years (%d PL, %d CZ, %d SK)\n",
            nrow(cross_country),
            sum(cross_country$country == "PL"),
            sum(cross_country$country == "CZ"),
            sum(cross_country$country == "SK")))

# ============================================================================
# Step 7: Save final panels
# ============================================================================

# Restrict main sample: 2013-2019 (5 pre-periods: 2013-2017)
panel_main <- panel %>%
  filter(year >= 2013 & year <= 2019)

panel_extended <- panel %>%
  filter(year >= 2013 & year <= 2022)

saveRDS(panel_main, "../data/panel_main.rds")
saveRDS(panel_extended, "../data/panel_extended.rds")
saveRDS(cross_country, "../data/cross_country.rds")

# ============================================================================
# Summary statistics
# ============================================================================

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Main panel (2014-2019): %d obs, %d regions, %d years\n",
            nrow(panel_main), n_distinct(panel_main$geo), n_distinct(panel_main$year)))
cat(sprintf("Extended panel (2014-2022): %d obs, %d regions, %d years\n",
            nrow(panel_extended), n_distinct(panel_extended$geo), n_distinct(panel_extended$year)))
cat(sprintf("Clustering units (NUTS-2): %d\n", n_distinct(panel_main$nuts2)))

cat("\nTrade share 2017 summary:\n")
print(summary(panel_main$trade_share_2017[!duplicated(panel_main$geo)]))

cat("\nOutcome: log trade employment\n")
print(summary(panel_main$log_emp_trade))

cat("\nTreatment intensity by year:\n")
panel_main %>%
  group_by(year) %>%
  summarise(
    mean_ban_intensity = mean(ban_intensity),
    mean_treatment = mean(treatment, na.rm=TRUE),
    n_regions = n(),
    .groups = "drop"
  ) %>%
  print()

cat("\nData cleaning complete.\n")
