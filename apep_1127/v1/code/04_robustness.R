# 04_robustness.R — Robustness checks and placebo tests
# apep_1127: Injection well volume regulations and induced seismicity

source("00_packages.R")

cat("=== Loading data ===\n")
panel <- read_csv("../data/panel_ok.csv", show_col_types = FALSE)
ks_panel <- read_csv("../data/panel_ks.csv", show_col_types = FALSE)
ca_quakes <- read_csv("../data/earthquakes_raw.csv", show_col_types = FALSE) |>
  filter(region_label == "California_placebo")

panel_active <- panel |>
  group_by(county_fips) |>
  filter(sum(n_quakes) > 0 | any(treated_county)) |>
  ungroup() |>
  mutate(post_treat = as.numeric(treat_post))

# =============================================================================
# 1. KANSAS REPLICATION
# =============================================================================

cat("\n=== Kansas Replication ===\n")

ks_active <- ks_panel |>
  group_by(county_fips) |>
  filter(sum(n_quakes) > 0 | any(treated_county)) |>
  ungroup() |>
  mutate(
    ym_numeric = year * 12 + month,
    post_treat = as.numeric(treated_county & ym_numeric >= first_treat_ym)
  )

if (n_distinct(ks_active$county_fips[ks_active$treated_county]) >= 2) {
  ks_m1 <- feols(ihs_quakes ~ post_treat | county_fips + year_month,
                 data = ks_active, cluster = "county_fips")
  cat("Kansas TWFE:\n")
  summary(ks_m1)
  saveRDS(ks_m1, "../data/ks_twfe.rds")
} else {
  cat("Too few treated Kansas counties for TWFE — reporting descriptive only\n")
}

# Kansas descriptive
ks_desc <- ks_active |>
  filter(treated_county) |>
  group_by(year) |>
  summarise(total_quakes = sum(n_quakes), .groups = "drop")
cat("\nKansas treated counties annual earthquake counts:\n")
print(ks_desc, n = 20)

# =============================================================================
# 2. CALIFORNIA TECTONIC PLACEBO
# =============================================================================

cat("\n=== California Tectonic Placebo ===\n")

ca_monthly <- ca_quakes |>
  mutate(
    date = as.Date(time),
    year = year(date),
    month = month(date),
    year_month = floor_date(date, "month")
  ) |>
  group_by(year_month, year, month) |>
  summarise(n_quakes = n(), .groups = "drop")

# Pseudo-treatment at March 2015 (same timing as Oklahoma)
ca_monthly <- ca_monthly |>
  mutate(
    post_2015 = as.numeric(year_month >= as.Date("2015-03-01")),
    ihs_quakes = log(n_quakes + sqrt(n_quakes^2 + 1))
  )

ca_placebo <- lm(ihs_quakes ~ post_2015, data = ca_monthly)
cat("California placebo (pseudo-treatment at March 2015):\n")
summary(ca_placebo)

saveRDS(ca_placebo, "../data/ca_placebo.rds")

# =============================================================================
# 3. MAGNITUDE THRESHOLD ROBUSTNESS
# =============================================================================

cat("\n=== Magnitude threshold robustness ===\n")

# M3.0+ threshold
panel_m3 <- panel_active |>
  mutate(n_quakes_m3 = replace_na(n_quakes_m3, 0),
         ihs_quakes_m3 = log(n_quakes_m3 + sqrt(n_quakes_m3^2 + 1)))

m_m3 <- feols(ihs_quakes_m3 ~ post_treat | county_fips + year_month,
              data = panel_m3, cluster = "county_fips")
cat("M3.0+ threshold:\n")
summary(m_m3)

# =============================================================================
# 4. OIL PRICE DECOMPOSITION
# =============================================================================

cat("\n=== Oil price decomposition ===\n")

# Key question: how much of the decline is regulation vs oil price collapse?
# Oil prices: 2014 avg $93 → 2016 avg $43 (54% decline)
# Injection volumes decline with oil prices (less wastewater from drilling)
# BUT: volumes stayed low even as prices recovered to $65+ in 2018-2019

# Interaction: WTI × treated county
panel_oil <- panel_active |>
  mutate(wti_x_treated = wti_price * as.numeric(treated_county))

m_oil <- feols(ihs_quakes ~ post_treat + wti_price + wti_x_treated |
                 county_fips + year_month,
               data = panel_oil, cluster = "county_fips")
cat("Oil price interaction:\n")
summary(m_oil)

# Post-recovery test: split post-treatment into early (2015-2017) and late (2018-2023)
# Oil prices: 2015-16 avg ~$45, 2018-19 avg ~$62 (recovered)
# If regulatory effect persists in late period, it's not just oil prices
panel_split <- panel_active |>
  filter(year >= 2010) |>
  mutate(
    early_post = as.numeric(treated_county & year %in% 2015:2017),
    late_post = as.numeric(treated_county & year >= 2018)
  )

m_recovery <- feols(ihs_quakes ~ early_post + late_post | county_fips + year_month,
                    data = panel_split, cluster = "county_fips")
cat("\nSplit post-treatment (early vs late) — ratchet persistence test:\n")
summary(m_recovery)

saveRDS(list(m_oil = m_oil, m_recovery = m_recovery, m_m3 = m_m3),
        "../data/robustness_results.rds")

# =============================================================================
# 5. LEAVE-ONE-COUNTY-OUT (jackknife sensitivity)
# =============================================================================

cat("\n=== Leave-one-county-out sensitivity ===\n")

treated_fips <- unique(panel_active$county_fips[panel_active$treated_county])
loo_list <- list()

for (i in seq_along(treated_fips)) {
  fips <- treated_fips[i]
  loo_data <- panel_active |> filter(county_fips != fips)
  loo_m <- feols(ihs_quakes ~ post_treat | county_fips + year_month,
                 data = loo_data, cluster = "county_fips")
  loo_list[[i]] <- tibble(
    dropped_county = as.character(fips),
    coefficient = coef(loo_m)["post_treat"],
    se = se(loo_m)["post_treat"]
  )
}

loo_results <- bind_rows(loo_list)

cat(sprintf("LOO coefficient range: [%.3f, %.3f]\n",
            min(loo_results$coefficient), max(loo_results$coefficient)))
cat(sprintf("Baseline coefficient: %.3f\n",
            coef(feols(ihs_quakes ~ post_treat | county_fips + year_month,
                       data = panel_active, cluster = "county_fips"))["post_treat"]))

saveRDS(loo_results, "../data/loo_results.rds")

cat("\n=== Robustness checks complete ===\n")
