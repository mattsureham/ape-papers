## 02_clean_data.R — Construct analysis variables
## apep_1278: The Compliance Lottery

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== Cleaning and constructing analysis variables ===\n")

# -----------------------------------------------------------------------
# 1. Create numeric country ID for fixest/did
# -----------------------------------------------------------------------
panel <- panel %>%
  mutate(country_id = as.integer(factor(country)))

# -----------------------------------------------------------------------
# 2. Construct additional outcome variables
# -----------------------------------------------------------------------
panel <- panel %>%
  group_by(country) %>%
  arrange(year) %>%
  mutate(
    # Log VAT revenue
    ln_vat = log(vat_revenue_mio),
    # VAT revenue growth rate
    vat_growth = (vat_revenue_mio - lag(vat_revenue_mio)) / lag(vat_revenue_mio) * 100,
    # Log GDP
    ln_gdp = log(gdp_mio),
    # Change in VAT gap (first difference)
    d_vat_gap = vat_gap_pct - lag(vat_gap_pct)
  ) %>%
  ungroup()

# -----------------------------------------------------------------------
# 3. Pre-treatment baseline characteristics
# -----------------------------------------------------------------------
baseline <- panel %>%
  filter(year == 2012) %>%
  select(country, vat_gap_pct, vat_gdp_ratio, gdp_mio) %>%
  rename(
    baseline_gap = vat_gap_pct,
    baseline_vat_gdp = vat_gdp_ratio,
    baseline_gdp = gdp_mio
  )

panel <- panel %>%
  left_join(baseline, by = "country") %>%
  mutate(
    high_baseline_gap = as.integer(baseline_gap > median(baseline_gap, na.rm = TRUE))
  )

# -----------------------------------------------------------------------
# 4. Summary statistics
# -----------------------------------------------------------------------
cat("\n--- Summary: Treated vs Never-Treated ---\n")
summary_stats <- panel %>%
  filter(!is.na(vat_gap_pct)) %>%
  group_by(ever_treated) %>%
  summarise(
    n_countries = n_distinct(country),
    n_obs = n(),
    mean_gap = mean(vat_gap_pct, na.rm = TRUE),
    sd_gap = sd(vat_gap_pct, na.rm = TRUE),
    mean_vat_gdp = mean(vat_gdp_ratio, na.rm = TRUE),
    .groups = "drop"
  )
print(summary_stats)

cat("\n--- Treatment Timing ---\n")
panel %>%
  filter(ever_treated, cs_group > 0) %>%
  distinct(country, cs_group) %>%
  arrange(cs_group) %>%
  print(n = 20)

# -----------------------------------------------------------------------
# 5. Validate balanced panel
# -----------------------------------------------------------------------
panel_count <- panel %>%
  filter(!is.na(vat_gap_pct)) %>%
  count(country) %>%
  pull(n)

cat(sprintf("\nPanel balance: min %d, max %d obs per country\n",
            min(panel_count), max(panel_count)))

# Save cleaned data
saveRDS(panel, "../data/panel_clean.rds")
cat("Cleaned data saved to data/panel_clean.rds\n")
cat("=== Cleaning complete ===\n")
