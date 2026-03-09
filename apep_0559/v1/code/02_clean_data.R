## ============================================================
## 02_clean_data.R — Variable construction and panel assembly
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- 1. Load Raw Data ---
cat("=== Loading raw data ===\n")

tier_data <- fread(file.path(DATA_DIR, "cbk_tier_panel.csv"))
wb_all    <- fread(file.path(DATA_DIR, "wb_financial_indicators.csv"))
monthly   <- fread(file.path(DATA_DIR, "monthly_rates.csv"))
cc_credit <- fread(file.path(DATA_DIR, "cross_country_credit.csv"))
cc_rates  <- fread(file.path(DATA_DIR, "cross_country_rates.csv"))
cc_npl    <- fread(file.path(DATA_DIR, "cross_country_npl.csv"))

## --- 2. Clean Tier Panel ---
cat("\n=== Cleaning tier panel ===\n")

tier_panel <- tier_data |>
  mutate(
    # Derived ratios
    loan_asset_ratio = loans_advances_bn / total_assets_bn,
    govt_sec_ratio   = govt_securities_bn / total_assets_bn,
    loan_deposit_ratio = loans_advances_bn / deposits_bn,

    # Per-bank averages
    assets_per_bank = total_assets_bn / n_banks,
    loans_per_bank  = loans_advances_bn / n_banks,

    # Log transformations
    log_assets = log(total_assets_bn),
    log_loans  = log(loans_advances_bn),
    log_govt_sec = log(govt_securities_bn),

    # Growth rates (year-over-year within tier)
    # Will compute after arranging
    dummy = 1
  ) |>
  group_by(tier) |>
  arrange(tier, year) |>
  mutate(
    loan_growth  = (loans_advances_bn / lag(loans_advances_bn) - 1) * 100,
    asset_growth = (total_assets_bn / lag(total_assets_bn) - 1) * 100,
    govt_sec_growth = (govt_securities_bn / lag(govt_securities_bn) - 1) * 100
  ) |>
  ungroup() |>
  select(-dummy) |>
  mutate(
    # Treatment indicators
    cap_on = as.integer(year >= 2017 & year <= 2019),  # Full cap years
    cap_partial = as.integer(year == 2016),              # Partial year (Sep onwards)
    repeal = as.integer(year >= 2020),
    covid  = as.integer(year >= 2020),

    # Period factor
    period = case_when(
      year < 2016 ~ "Pre-cap",
      year == 2016 ~ "Partial cap",
      year <= 2019 ~ "Cap-on",
      TRUE ~ "Post-repeal"
    ),
    period = factor(period, levels = c("Pre-cap", "Partial cap", "Cap-on", "Post-repeal")),

    # Exposure measure: Tier 3 is most exposed (highest loan/asset, lowest govt sec)
    # Use 2015 baseline values for exposure
    tier_num = case_when(
      tier == "Tier1" ~ 1L,
      tier == "Tier2" ~ 2L,
      tier == "Tier3" ~ 3L
    )
  )

# Compute baseline (2015) exposure measures
baseline_2015 <- tier_panel |>
  filter(year == 2015) |>
  select(tier,
         baseline_loan_ratio = loan_asset_ratio,
         baseline_govt_ratio = govt_sec_ratio,
         baseline_npl = npl_ratio) |>
  mutate(
    # Continuous exposure: higher loan ratio + lower govt ratio = more exposed
    exposure = baseline_loan_ratio - baseline_govt_ratio
  )

tier_panel <- tier_panel |>
  left_join(baseline_2015, by = "tier")

cat("  Tier panel:", nrow(tier_panel), "rows\n")
cat("  Baseline exposure (2015):\n")
baseline_2015 |> select(tier, baseline_loan_ratio, baseline_govt_ratio, exposure) |> print()

## --- 3. Clean Cross-Country Panel ---
cat("\n=== Cleaning cross-country panel ===\n")

# Combine all cross-country indicators
cc_all <- bind_rows(
  cc_credit |> rename(credit_gdp = value) |> select(country, country_name, year, credit_gdp),
  cc_rates  |> rename(lending_rate = value) |> select(country, country_name, year, lending_rate),
  cc_npl    |> rename(npl_ratio = value) |> select(country, country_name, year, npl_ratio)
) |>
  group_by(country, country_name, year) |>
  summarise(
    credit_gdp = first(na.omit(credit_gdp)),
    lending_rate = first(na.omit(lending_rate)),
    npl_ratio = first(na.omit(npl_ratio)),
    .groups = "drop"
  ) |>
  filter(year >= 2010 & year <= 2023) |>
  mutate(
    treated = as.integer(country == "KE"),
    cap_on = as.integer(year >= 2017 & year <= 2019),
    repeal = as.integer(year >= 2020),
    post = as.integer(year >= 2017),
    period = case_when(
      year < 2017 ~ "Pre-cap",
      year <= 2019 ~ "Cap-on",
      TRUE ~ "Post-repeal"
    ),
    period = factor(period, levels = c("Pre-cap", "Cap-on", "Post-repeal"))
  )

cat("  Cross-country panel:", nrow(cc_all), "rows\n")
cat("  Countries:", paste(unique(cc_all$country_name), collapse = ", "), "\n")
cat("  Years:", min(cc_all$year), "-", max(cc_all$year), "\n")

## --- 4. Clean Monthly Data ---
cat("\n=== Cleaning monthly data ===\n")

monthly_clean <- monthly |>
  mutate(
    date = as.Date(date),
    # Event time relative to cap introduction (Sep 2016 = 0)
    event_time_cap = interval(as.Date("2016-09-01"), date) %/% months(1),
    # Event time relative to repeal (Nov 2019 = 0)
    event_time_repeal = interval(as.Date("2019-11-01"), date) %/% months(1),
    # Implied spread over CBR
    implied_max_rate = cbr + 4,
    # Year-month numeric
    ym = year + (month - 1) / 12
  )

cat("  Monthly data:", nrow(monthly_clean), "rows\n")

## --- 5. Summary Statistics ---
cat("\n=== Computing summary statistics ===\n")

# Tier-level summary by period
tier_summary <- tier_panel |>
  group_by(tier, period) |>
  summarise(
    n_years = n(),
    mean_loan_ratio = mean(loan_asset_ratio, na.rm = TRUE),
    mean_govt_ratio = mean(govt_sec_ratio, na.rm = TRUE),
    mean_npl = mean(npl_ratio, na.rm = TRUE),
    mean_loan_growth = mean(loan_growth, na.rm = TRUE),
    mean_assets_bn = mean(total_assets_bn),
    .groups = "drop"
  )

cat("\nTier Summary by Period:\n")
print(tier_summary)

# Cross-country summary
cc_summary <- cc_all |>
  group_by(country_name, period) |>
  summarise(
    mean_credit_gdp = mean(credit_gdp, na.rm = TRUE),
    mean_lending_rate = mean(lending_rate, na.rm = TRUE),
    mean_npl = mean(npl_ratio, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nCross-Country Summary by Period:\n")
print(cc_summary)

## --- 6. Save Cleaned Data ---
cat("\n=== Saving cleaned data ===\n")

fwrite(tier_panel, file.path(DATA_DIR, "tier_panel_clean.csv"))
fwrite(cc_all, file.path(DATA_DIR, "cross_country_clean.csv"))
fwrite(monthly_clean, file.path(DATA_DIR, "monthly_clean.csv"))
fwrite(tier_summary, file.path(DATA_DIR, "tier_summary.csv"))
fwrite(cc_summary, file.path(DATA_DIR, "cc_summary.csv"))

cat("\n=== Data cleaning complete ===\n")
cat("Files saved to:", DATA_DIR, "\n")
