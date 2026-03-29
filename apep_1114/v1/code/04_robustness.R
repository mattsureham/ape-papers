## 04_robustness.R — Robustness checks for apep_1114
## Pre-trend tests, placebos, alternative exposure, leave-one-out

source("00_packages.R")

cat("=== Robustness Checks ===\n\n")

panel <- readRDS("../data/analysis_panel.rds") |>
  filter(!is.na(high_exposure))

results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------
# 1. Placebo test: pseudo-treatment in 2012 (pre-nitrogen ruling)
# ---------------------------------------------------------------
cat("--- 1. Placebo Test (pseudo-treatment 2012) ---\n")

pre_panel <- panel |> filter(year <= 2018)
pre_panel <- pre_panel |>
  mutate(
    placebo_post = as.integer(year >= 2013)
  )

placebo_farms <- feols(
  log_farms ~ exposure:placebo_post | muni_code + year,
  data = pre_panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("Placebo (log farms, pseudo-2012):\n")
cat("  β =", round(coef(placebo_farms)[1], 5),
    " SE =", round(se(placebo_farms)[1], 5),
    " p =", round(pvalue(placebo_farms)[1], 4), "\n")

placebo_lu <- feols(
  log_livestock ~ exposure:placebo_post | muni_code + year,
  data = pre_panel |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)
cat("Placebo (log LU, pseudo-2012):\n")
cat("  β =", round(coef(placebo_lu)[1], 5),
    " SE =", round(se(placebo_lu)[1], 5),
    " p =", round(pvalue(placebo_lu)[1], 4), "\n")

# ---------------------------------------------------------------
# 2. Detrended specification (municipality-specific trends)
# ---------------------------------------------------------------
cat("\n--- 2. Municipality-specific Linear Trends ---\n")

panel <- panel |>
  mutate(trend = year - 2000)

m_detrend_farms <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("Detrended (log farms):\n")
print(summary(m_detrend_farms))

m_detrend_lu <- feols(
  log_livestock ~ exposure:post_2019 + exposure:post_2023 |
    muni_code[trend] + year,
  data = panel |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)
cat("Detrended (log LU):\n")
print(summary(m_detrend_lu))

# ---------------------------------------------------------------
# 3. Alternative exposure: distance-based only (no interaction)
# ---------------------------------------------------------------
cat("\n--- 3. Alternative Exposure (N2K share only) ---\n")

m_alt_farms <- feols(
  log_farms ~ n2k_share:post_2019 + n2k_share:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("N2K share only (log farms):\n")
cat("  post_2019: β =", round(coef(m_alt_farms)[1], 4),
    " p =", round(pvalue(m_alt_farms)[1], 4), "\n")
cat("  post_2023: β =", round(coef(m_alt_farms)[2], 4),
    " p =", round(pvalue(m_alt_farms)[2], 4), "\n")

# ---------------------------------------------------------------
# 4. Leave-one-out: drop top 3 concentration municipalities
# ---------------------------------------------------------------
cat("\n--- 4. Leave-One-Out (drop Ede, Venray, Barneveld) ---\n")

# Identify top 3 by exposure
top3 <- panel |>
  filter(!is.na(exposure)) |>
  group_by(muni_code) |>
  summarise(mean_exposure = mean(exposure), .groups = "drop") |>
  arrange(desc(mean_exposure)) |>
  slice_head(n = 3) |>
  pull(muni_code)

cat("Dropping municipalities:", paste(top3, collapse = ", "), "\n")

m_loo_farms <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_farms) & !muni_code %in% top3),
  cluster = ~muni_code
)
cat("LOO (log farms):\n")
cat("  post_2019: β =", round(coef(m_loo_farms)[1], 5),
    " SE =", round(se(m_loo_farms)[1], 5),
    " p =", round(pvalue(m_loo_farms)[1], 4), "\n")
cat("  post_2023: β =", round(coef(m_loo_farms)[2], 5),
    " SE =", round(se(m_loo_farms)[2], 5),
    " p =", round(pvalue(m_loo_farms)[2], 4), "\n")

# ---------------------------------------------------------------
# 5. Permutation inference (randomize exposure across municipalities)
# ---------------------------------------------------------------
cat("\n--- 5. Permutation Inference (500 iterations) ---\n")

set.seed(42)
n_perm <- 500

# Get true coefficients
true_coefs <- coef(results$m1_farms)

# Permutation: shuffle exposure across municipalities
muni_exposure <- panel |>
  distinct(muni_code, exposure)

perm_coefs_post2019 <- numeric(n_perm)
perm_coefs_post2023 <- numeric(n_perm)

for (i in seq_len(n_perm)) {
  shuffled <- muni_exposure |>
    mutate(exposure_perm = sample(exposure))

  perm_data <- panel |>
    select(-exposure) |>
    left_join(shuffled |> select(muni_code, exposure_perm), by = "muni_code") |>
    filter(!is.na(log_farms))

  perm_mod <- feols(
    log_farms ~ exposure_perm:post_2019 + exposure_perm:post_2023 |
      muni_code + year,
    data = perm_data,
    cluster = ~muni_code
  )

  perm_coefs_post2019[i] <- coef(perm_mod)["exposure_perm:post_2019"]
  perm_coefs_post2023[i] <- coef(perm_mod)["exposure_perm:post_2023"]
}

ri_p_2019 <- mean(abs(perm_coefs_post2019) >= abs(true_coefs["exposure:post_2019"]))
ri_p_2023 <- mean(abs(perm_coefs_post2023) >= abs(true_coefs["exposure:post_2023"]))

cat("Randomization inference p-values:\n")
cat("  post_2019 (farms):", ri_p_2019, "\n")
cat("  post_2023 (farms):", ri_p_2023, "\n")

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
cat("\n--- Saving robustness results ---\n")

robust_results <- list(
  placebo_farms = placebo_farms,
  placebo_lu = placebo_lu,
  detrend_farms = m_detrend_farms,
  detrend_lu = m_detrend_lu,
  alt_exposure_farms = m_alt_farms,
  loo_farms = m_loo_farms,
  ri_p_2019 = ri_p_2019,
  ri_p_2023 = ri_p_2023,
  perm_coefs_post2023 = perm_coefs_post2023
)
saveRDS(robust_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
