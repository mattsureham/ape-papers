# 02_clean_data.R — Clean and construct analysis panel
# EU Late Payment Directive & Small Firm Survival (apep_0938)

source("00_packages.R")

bd_raw <- readRDS("../data/bd_raw.rds")
payment_delay <- readRDS("../data/payment_delay.rds")

# ----------------------------------------------------------------
# 1. Filter to relevant indicators, size classes, and sectors
# ----------------------------------------------------------------

# Key indicators from Eurostat business demography:
# V97120 = Enterprise death rate (deaths / active enterprises * 100)
# V97020 = Number of enterprise births (count)
# V97010 = Number of active enterprises (count)
# V97143 = 3-year survival rate (% of enterprises born in t-3 surviving to t)
# V11910 = Number of enterprise births (alternative)

# Size classes: "0" (0 emp), "1-4", "5-9", "GE10" (10+), "TOTAL"
# NACE: use "B-S_X_K642" (business economy except financial holding)
#   or aggregate across main sectors

eu28 <- payment_delay$geo

cat("Filtering to EU-28, key indicators, total economy...\n")

bd <- bd_raw |>
  filter(
    geo %in% eu28,
    indic_sb %in% c("V97120", "V97130", "V97143"),
    sizeclas %in% c("0", "1-4", "5-9", "GE10"),
    # Use total business economy
    nace_r2 == "B-S_X_K642"
  ) |>
  mutate(year = as.integer(TIME_PERIOD))

cat(sprintf("Filtered: %d rows\n", nrow(bd)))
cat(sprintf("Countries: %d (%s)\n", n_distinct(bd$geo),
            paste(sort(unique(bd$geo)), collapse = ", ")))
cat(sprintf("Years: %d to %d\n", min(bd$year), max(bd$year)))
cat(sprintf("Size classes: %s\n", paste(sort(unique(bd$sizeclas)), collapse = ", ")))

# ----------------------------------------------------------------
# 2. Pivot to wide format
# ----------------------------------------------------------------

bd_wide <- bd |>
  select(geo, sizeclas, year, indic_sb, values) |>
  distinct(geo, sizeclas, year, indic_sb, .keep_all = TRUE) |>
  pivot_wider(
    names_from = indic_sb,
    values_from = values,
    values_fn = mean
  ) |>
  rename(
    death_rate = V97120,
    birth_rate = V97130,
    surv_rate_3yr = V97143
  )

cat(sprintf("\nWide panel: %d rows\n", nrow(bd_wide)))
cat(sprintf("Non-missing death rates: %d (%.0f%%)\n",
            sum(!is.na(bd_wide$death_rate)),
            100 * mean(!is.na(bd_wide$death_rate))))
cat(sprintf("Non-missing 3yr survival: %d (%.0f%%)\n",
            sum(!is.na(bd_wide$surv_rate_3yr)),
            100 * mean(!is.na(bd_wide$surv_rate_3yr))))

# ----------------------------------------------------------------
# 3. Construct treatment variables
# ----------------------------------------------------------------

panel <- bd_wide |>
  left_join(payment_delay |> select(geo, avg_payment_days, country_name),
            by = "geo") |>
  filter(!is.na(avg_payment_days)) |>
  mutate(
    # Post-directive indicator (transposition deadline March 2013)
    # 2014 = first full post year
    post = as.integer(year >= 2014),

    # Standardize payment delay
    pay_delay_z = (avg_payment_days - mean(unique(avg_payment_days))) /
                   sd(unique(avg_payment_days)),

    # Binary: high-delay country (above median)
    high_delay = as.integer(
      avg_payment_days > median(unique(avg_payment_days))
    ),

    # Small firm indicator
    small = as.integer(sizeclas %in% c("0", "1-4", "5-9")),

    # Size class labels for display
    size_label = case_when(
      sizeclas == "0" ~ "0 employees",
      sizeclas == "1-4" ~ "1-4 employees",
      sizeclas == "5-9" ~ "5-9 employees",
      sizeclas == "GE10" ~ "10+ employees"
    ),

    # Numeric size for FE
    size_num = case_when(
      sizeclas == "0" ~ 1L,
      sizeclas == "1-4" ~ 2L,
      sizeclas == "5-9" ~ 3L,
      sizeclas == "GE10" ~ 4L
    ),

    # Year relative to directive (2013 = 0)
    rel_year = year - 2013
  )

cat(sprintf("\nFinal panel: %d rows\n", nrow(panel)))
cat(sprintf("Countries: %d\n", n_distinct(panel$geo)))
cat(sprintf("Size groups: %s\n", paste(sort(unique(panel$sizeclas)), collapse = ", ")))
cat(sprintf("Year range: %d to %d\n", min(panel$year), max(panel$year)))

# Payment delay distribution
cat("\nPayment delay distribution (across 28 countries):\n")
pd_stats <- panel |>
  distinct(geo, avg_payment_days) |>
  summarise(
    mean = mean(avg_payment_days),
    sd = sd(avg_payment_days),
    min = min(avg_payment_days),
    p25 = quantile(avg_payment_days, 0.25),
    median = median(avg_payment_days),
    p75 = quantile(avg_payment_days, 0.75),
    max = max(avg_payment_days)
  )
print(pd_stats)

# Coverage by size class
coverage <- panel |>
  group_by(sizeclas) |>
  summarise(
    n_obs = n(),
    n_countries = n_distinct(geo),
    n_years = n_distinct(year),
    pct_death_nonmiss = round(100 * mean(!is.na(death_rate)), 1),
    pct_surv_nonmiss = round(100 * mean(!is.na(surv_rate_3yr)), 1),
    .groups = "drop"
  )

cat("\nCoverage by size class:\n")
print(coverage)

# Save
saveRDS(panel, "../data/panel.rds")

cat("\n=== Panel construction complete ===\n")
