## 04_robustness.R — Robustness checks
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

df <- read_csv("../data/clean_panel.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

## -------------------------------------------------------------------------
## 1. Leave-one-out: Exclude extreme prefectures
## -------------------------------------------------------------------------

cat("--- 1. Leave-one-out sensitivity ---\n")

extreme_prefs <- c("13000", "47000", "01000")  # Tokyo, Okinawa, Hokkaido
pref_names <- c("Tokyo" = "13000", "Okinawa" = "47000", "Hokkaido" = "01000")

loo_results <- list()
for (pname in names(pref_names)) {
  df_loo <- df %>% filter(area_code != pref_names[pname])
  m_loo <- feols(log_cultivated ~ treatment_intensity | area_code + year,
                 data = df_loo, cluster = ~area_code)
  loo_results[[pname]] <- m_loo
  cat(sprintf("  Excl. %s: β=%.6f (SE=%.6f)\n", pname,
              coef(m_loo)["treatment_intensity"], se(m_loo)["treatment_intensity"]))
}

## -------------------------------------------------------------------------
## 2. Alternative treatment windows
## -------------------------------------------------------------------------

cat("\n--- 2. Alternative time windows ---\n")

## 2a: Narrower window (2008-2018)
df_narrow <- df %>% filter(year >= 2008, year <= 2018)
m_narrow <- feols(log_cultivated ~ treatment_intensity | area_code + year,
                  data = df_narrow, cluster = ~area_code)
cat(sprintf("  2008-2018: β=%.6f (SE=%.6f)\n",
            coef(m_narrow)["treatment_intensity"],
            se(m_narrow)["treatment_intensity"]))

## 2b: Pre-2017 only (before FIT amendment)
df_pre17 <- df %>% filter(year <= 2016)
m_pre17 <- feols(log_cultivated ~ treatment_intensity | area_code + year,
                 data = df_pre17, cluster = ~area_code)
cat(sprintf("  2005-2016 (pre-amendment): β=%.6f (SE=%.6f)\n",
            coef(m_pre17)["treatment_intensity"],
            se(m_pre17)["treatment_intensity"]))

## 2c: Post-2017 only (after FIT amendment)
df_post17 <- df %>% filter(year >= 2017 | year < 2012)
m_post17 <- feols(log_cultivated ~ treatment_intensity | area_code + year,
                  data = df_post17, cluster = ~area_code)
cat(sprintf("  Pre-FIT + post-amendment: β=%.6f (SE=%.6f)\n",
            coef(m_post17)["treatment_intensity"],
            se(m_post17)["treatment_intensity"]))

## -------------------------------------------------------------------------
## 3. Placebo: Paddy fields should respond less
## -------------------------------------------------------------------------

cat("\n--- 3. Placebo: Paddy vs Field outcomes ---\n")

m_paddy <- feols(log_paddy ~ treatment_intensity | area_code + year,
                 data = df, cluster = ~area_code)
m_field <- feols(log_field ~ treatment_intensity | area_code + year,
                 data = df, cluster = ~area_code)

cat(sprintf("  Paddy (placebo):  β=%.6f (SE=%.6f, p=%.4f)\n",
            coef(m_paddy)["treatment_intensity"],
            se(m_paddy)["treatment_intensity"],
            pvalue(m_paddy)["treatment_intensity"]))
cat(sprintf("  Field (expected): β=%.6f (SE=%.6f, p=%.4f)\n",
            coef(m_field)["treatment_intensity"],
            se(m_field)["treatment_intensity"],
            pvalue(m_field)["treatment_intensity"]))

## -------------------------------------------------------------------------
## 4. Randomization inference (47 clusters)
## -------------------------------------------------------------------------

cat("\n--- 4. Randomization Inference ---\n")

set.seed(42)
n_perms <- 1000
actual_beta <- coef(results$m1)["treatment_intensity"]

## Permute upland shares across prefectures
pref_shares <- df %>%
  filter(!duplicated(area_code)) %>%
  select(area_code, pre_upland_share)

ri_betas <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  ## Shuffle upland shares
  shuffled <- pref_shares
  shuffled$pre_upland_share <- sample(shuffled$pre_upland_share)

  df_perm <- df %>%
    select(-pre_upland_share, -treatment_intensity) %>%
    left_join(shuffled, by = "area_code") %>%
    mutate(treatment_intensity = fit_rate * pre_upland_share)

  m_perm <- tryCatch(
    feols(log_cultivated ~ treatment_intensity | area_code + year,
          data = df_perm, cluster = ~area_code),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    ri_betas[i] <- coef(m_perm)["treatment_intensity"]
  } else {
    ri_betas[i] <- NA
  }
}

ri_p <- mean(abs(ri_betas) >= abs(actual_beta), na.rm = TRUE)
cat(sprintf("  Actual β: %.6f\n", actual_beta))
cat(sprintf("  RI p-value (two-sided, %d permutations): %.4f\n", n_perms, ri_p))
cat(sprintf("  RI 95%% CI: [%.6f, %.6f]\n",
            quantile(ri_betas, 0.025, na.rm = TRUE),
            quantile(ri_betas, 0.975, na.rm = TRUE)))

## -------------------------------------------------------------------------
## 5. Pre-trend test: Formal F-test on pre-2012 event study coefficients
## -------------------------------------------------------------------------

cat("\n--- 5. Pre-trend F-test ---\n")

m_es <- results$m_es
es_coefs <- coeftable(m_es)
pre_coefs <- es_coefs[grep("rel_year::-[2-9]|::-1[0-9]", rownames(es_coefs)), ]

if (nrow(pre_coefs) > 0) {
  ## Joint F-test on pre-treatment coefficients
  pre_names <- rownames(pre_coefs)
  cat(sprintf("  Pre-treatment coefficients: %d\n", length(pre_names)))
  for (pn in pre_names) {
    cat(sprintf("    %s: %.6f (%.6f)\n", pn, pre_coefs[pn, 1], pre_coefs[pn, 2]))
  }

  ## Wald test
  tryCatch({
    w_test <- wald(m_es, pre_names)
    cat(sprintf("  Joint F-test: F=%.2f, p=%.4f\n", w_test$stat, w_test$p))
  }, error = function(e) {
    cat(sprintf("  Wald test failed: %s\n", e$message))
    ## Manual check: are any individually significant at 5%?
    sig_5 <- sum(abs(pre_coefs[, 1] / pre_coefs[, 2]) > 1.96)
    cat(sprintf("  Pre-trend coefs individually significant at 5%%: %d of %d\n",
                sig_5, nrow(pre_coefs)))
  })
} else {
  cat("  No pre-treatment event study coefficients found.\n")
}

## -------------------------------------------------------------------------
## 6. Population-weighted regression
## -------------------------------------------------------------------------

cat("\n--- 6. Cultivated-land-weighted ---\n")

## Use 2011 cultivated land as weights
land_2011 <- df %>%
  filter(year == 2011) %>%
  select(area_code, land_weight = cultivated_land_total)

df_weighted <- df %>%
  left_join(land_2011, by = "area_code")

m_weighted <- feols(log_cultivated ~ treatment_intensity | area_code + year,
                    data = df_weighted, weights = ~land_weight, cluster = ~area_code)
cat(sprintf("  Land-weighted: β=%.6f (SE=%.6f)\n",
            coef(m_weighted)["treatment_intensity"],
            se(m_weighted)["treatment_intensity"]))

## -------------------------------------------------------------------------
## 7. Trend-adjusted (prefecture-specific linear trends)
## -------------------------------------------------------------------------

cat("\n--- 7. Prefecture-specific linear trends ---\n")

## Create prefecture × year trend
df <- df %>%
  mutate(pref_trend = as.numeric(factor(area_code)) * year)

m_trend <- feols(log_cultivated ~ treatment_intensity | area_code + year + area_code[year],
                 data = df, cluster = ~area_code)
cat(sprintf("  With pref-specific trends: β=%.6f (SE=%.6f)\n",
            coef(m_trend)["treatment_intensity"],
            se(m_trend)["treatment_intensity"]))

## -------------------------------------------------------------------------
## Save all robustness results
## -------------------------------------------------------------------------

rob_results <- list(
  loo = loo_results,
  narrow = m_narrow,
  pre17 = m_pre17,
  post17 = m_post17,
  placebo_paddy = m_paddy,
  placebo_field = m_field,
  ri_p = ri_p,
  ri_betas = ri_betas,
  weighted = m_weighted,
  trend = m_trend
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\n=== Robustness results saved ===\n")
