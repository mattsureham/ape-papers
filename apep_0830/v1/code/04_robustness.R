## 04_robustness.R — Robustness checks and mechanism tests
## apep_0830: VAT Receipt Lotteries and Compliance Gaps

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
results <- readRDS("../data/main_results.rds")
lottery_events <- readRDS("../data/lottery_events.rds")

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# 1. Placebo outcome: Income tax / GDP (should NOT respond to receipt lotteries)
# ---------------------------------------------------------------
cat("\n--- Placebo: Income Tax / GDP ---\n")
placebo_twfe <- feols(inc_tax_gdp_pct ~ lottery | geo_id + year,
                      data = panel, cluster = ~geo_id)
print(summary(placebo_twfe))

# ---------------------------------------------------------------
# 2. Alternative outcome: VAT share of production taxes
# ---------------------------------------------------------------
cat("\n--- Alternative outcome: VAT / Total Production Taxes ---\n")
alt_twfe <- feols(vat_share ~ lottery | geo_id + year,
                  data = panel, cluster = ~geo_id)
print(summary(alt_twfe))

# ---------------------------------------------------------------
# 3. Cancellation analysis
# Countries that cancelled: SK (end 2020), CZ (end 2019), PL (end 2016), LV (end 2022)
# Test: does VAT/GDP fall after cancellation?
# ---------------------------------------------------------------
cat("\n--- Cancellation Event Study ---\n")

# Create a cancellation indicator for countries that ended their lottery
# Restrict sample to: (a) countries that cancelled + (b) never-treated controls
# Within cancelling countries, keep only the active + post-cancel years
cancel_geos <- lottery_events |> filter(!is.na(end_year)) |> pull(geo)
never_treated_geos <- unique(panel$geo[panel$first_treat == 0])

panel_cancel <- panel |>
  filter(geo %in% c(cancel_geos, never_treated_geos)) |>
  left_join(lottery_events |> filter(!is.na(end_year)) |>
              select(geo, c_end = end_year, c_start = start_year), by = "geo") |>
  filter(
    # Never-treated: keep all years
    geo %in% never_treated_geos |
    # Cancelled: keep from start_year onward (during + after lottery)
    (geo %in% cancel_geos & year >= c_start)
  ) |>
  mutate(
    post_cancel = case_when(
      is.na(c_end) ~ 0L,
      year > c_end ~ 1L,
      TRUE ~ 0L
    )
  )

cancel_twfe <- feols(vat_gdp_pct ~ post_cancel | geo_id + year,
                     data = panel_cancel, cluster = ~geo_id)
cat("Cancellation TWFE:\n")
print(summary(cancel_twfe))

# ---------------------------------------------------------------
# 4. Permutation test (randomization inference)
# Randomly reassign treatment across countries and compute t-stat
# ---------------------------------------------------------------
cat("\n--- Permutation Inference ---\n")

observed_t <- coef(results$twfe)["lottery"] /
  sqrt(vcov(results$twfe)["lottery", "lottery"])

set.seed(42)
n_perms <- 1000
perm_t <- numeric(n_perms)

country_list <- unique(panel$geo)
n_treated <- n_distinct(panel$geo[panel$first_treat > 0])

for (i in seq_len(n_perms)) {
  # Randomly assign which countries are "treated"
  fake_treated <- sample(country_list, n_treated)
  # Randomly assign treatment years from actual distribution
  actual_starts <- unique(panel$first_treat[panel$first_treat > 0])
  fake_starts <- sample(actual_starts, n_treated, replace = TRUE)

  panel_perm <- panel |>
    mutate(
      fake_first = case_when(
        geo %in% fake_treated ~ fake_starts[match(geo, fake_treated)],
        TRUE ~ 0L
      ),
      fake_lottery = as.integer(fake_first > 0 & year >= fake_first)
    )

  perm_fit <- tryCatch(
    feols(vat_gdp_pct ~ fake_lottery | geo_id + year, data = panel_perm,
          cluster = ~geo_id),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    perm_t[i] <- coef(perm_fit)["fake_lottery"] /
      sqrt(vcov(perm_fit)["fake_lottery", "fake_lottery"])
  } else {
    perm_t[i] <- 0
  }
}

ri_p <- mean(abs(perm_t) >= abs(observed_t))
cat(sprintf("RI p-value: %.3f (observed t=%.3f)\n", ri_p, observed_t))

# ---------------------------------------------------------------
# 5. Heterogeneity: by baseline VAT/GDP level
# ---------------------------------------------------------------
cat("\n--- Heterogeneity: High vs Low Baseline VAT/GDP ---\n")

baseline_vat <- panel |>
  filter(year == 2005) |>
  select(geo, baseline_vat_gdp = vat_gdp_pct)

panel_het <- panel |>
  left_join(baseline_vat, by = "geo") |>
  mutate(high_baseline = as.integer(baseline_vat_gdp > median(baseline_vat_gdp, na.rm = TRUE)))

het_twfe <- feols(vat_gdp_pct ~ lottery:i(high_baseline) | geo_id + year,
                  data = panel_het, cluster = ~geo_id)
cat("Heterogeneity by baseline VAT/GDP:\n")
print(summary(het_twfe))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
rob_results <- list(
  placebo_twfe = placebo_twfe,
  alt_twfe = alt_twfe,
  cancel_twfe = cancel_twfe,
  het_twfe = het_twfe,
  ri_p = ri_p,
  observed_t = observed_t,
  perm_t = perm_t
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
