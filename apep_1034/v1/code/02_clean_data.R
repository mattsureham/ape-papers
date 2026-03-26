## 02_clean_data.R — Construct analysis panels
## apep_1034: Norway Wind Resource Rent Tax

source("00_packages.R")

# ============================================================
# Load raw data
# ============================================================
annual <- readRDS("../data/annual_production.rds")
county <- readRDS("../data/county_production.rds")
monthly <- readRDS("../data/monthly_production.rds")
eurostat_df <- readRDS("../data/eurostat_production.rds")

# ============================================================
# Panel A: National monthly wind vs hydro (main DiD panel)
# ============================================================
monthly_panel <- monthly %>%
  mutate(
    post = as.integer(date >= as.Date("2023-01-01")),
    wind = as.integer(sector == "wind"),
    treat = wind * post,
    # Time index for event study (months since Dec 2022)
    month_idx = as.integer(difftime(date, as.Date("2022-12-01"), units = "days")) %/% 30,
    # Log production (adding small constant for zeros)
    log_gwh = log(gwh + 0.001),
    # Year-month numeric
    ym = year + (month - 1) / 12
  )

cat("Monthly panel:\n")
cat(sprintf("  Total obs: %d\n", nrow(monthly_panel)))
cat(sprintf("  Wind obs: %d\n", sum(monthly_panel$wind)))
cat(sprintf("  Post obs: %d\n", sum(monthly_panel$post)))
cat(sprintf("  Treated (wind x post): %d\n", sum(monthly_panel$treat)))
cat(sprintf("  Date range: %s to %s\n",
            min(monthly_panel$date), max(monthly_panel$date)))

# ============================================================
# Panel B: County annual wind vs hydro (geographic variation)
# ============================================================
# Keep counties that have BOTH wind and hydro production
county_both <- county %>%
  group_by(region_code) %>%
  summarise(
    has_wind = any(sector == "wind" & gwh > 0),
    has_hydro = any(sector == "hydro" & gwh > 0),
    .groups = "drop"
  ) %>%
  filter(has_wind & has_hydro)

county_panel <- county %>%
  filter(region_code %in% county_both$region_code) %>%
  mutate(
    post = as.integer(year >= 2023),
    wind = as.integer(sector == "wind"),
    treat = wind * post,
    log_gwh = log(gwh + 0.001),
    county_sector = paste(region_code, sector, sep = "_")
  )

cat("\nCounty panel:\n")
cat(sprintf("  Counties with both wind & hydro: %d\n", nrow(county_both)))
cat(sprintf("  Total obs: %d\n", nrow(county_panel)))
cat(sprintf("  Years: %d-%d\n", min(county_panel$year), max(county_panel$year)))

# ============================================================
# Panel C: Eurostat cross-country (placebo)
# ============================================================
if (nrow(eurostat_df) > 0) {
  eurostat_panel <- eurostat_df %>%
    filter(sector == "wind") %>%
    mutate(
      norway = as.integer(country == "NO"),
      post = as.integer(date >= as.Date("2023-01-01")),
      treat = norway * post,
      log_gwh = log(gwh + 0.001),
      month_idx = as.integer(difftime(date, as.Date("2022-12-01"), units = "days")) %/% 30
    )

  cat("\nEurostat panel (wind only, NO vs SE/DK):\n")
  cat(sprintf("  Total obs: %d\n", nrow(eurostat_panel)))
  cat(sprintf("  Countries: %s\n", paste(unique(eurostat_panel$country), collapse = ", ")))
} else {
  eurostat_panel <- NULL
  cat("\nNo Eurostat data available for placebo analysis.\n")
}

# ============================================================
# Compute growth rates for descriptive analysis
# ============================================================
annual_growth <- annual %>%
  filter(region_code == "0") %>%  # National level
  group_by(sector) %>%
  arrange(year) %>%
  mutate(
    growth = (gwh - lag(gwh)) / lag(gwh) * 100,
    gwh_diff = gwh - lag(gwh)
  ) %>%
  ungroup()

cat("\nAnnual growth rates (national):\n")
annual_growth %>%
  filter(year >= 2018) %>%
  select(sector, year, gwh, growth) %>%
  pivot_wider(names_from = sector, values_from = c(gwh, growth)) %>%
  print(n = 10)

# ============================================================
# Summary statistics for the paper
# ============================================================
sumstats_monthly <- monthly_panel %>%
  group_by(sector) %>%
  summarise(
    n = n(),
    mean_gwh = mean(gwh, na.rm = TRUE),
    sd_gwh = sd(gwh, na.rm = TRUE),
    min_gwh = min(gwh, na.rm = TRUE),
    max_gwh = max(gwh, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nSummary statistics (monthly production, GWh):\n")
print(sumstats_monthly)

# Pre-treatment statistics (for SDE computation)
pre_stats <- monthly_panel %>%
  filter(post == 0) %>%
  group_by(sector) %>%
  summarise(
    pre_mean = mean(gwh, na.rm = TRUE),
    pre_sd = sd(gwh, na.rm = TRUE),
    pre_mean_log = mean(log_gwh, na.rm = TRUE),
    pre_sd_log = sd(log_gwh, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment summary statistics:\n")
print(pre_stats)

# ============================================================
# Save analysis panels
# ============================================================
saveRDS(monthly_panel, "../data/monthly_panel.rds")
saveRDS(county_panel, "../data/county_panel.rds")
if (!is.null(eurostat_panel)) {
  saveRDS(eurostat_panel, "../data/eurostat_panel.rds")
}
saveRDS(annual_growth, "../data/annual_growth.rds")
saveRDS(sumstats_monthly, "../data/sumstats_monthly.rds")
saveRDS(pre_stats, "../data/pre_stats.rds")

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
