## 04_robustness.R — Event study, placebos, wild bootstrap, HonestDiD
## apep_0867: Upload Filters and the Creative Economy

source("00_packages.R")

panel <- readRDS("../data/panel_balanced.rds")
results <- readRDS("../data/main_results.rds")

cat("=== Robustness Checks ===\n")

# -------------------------------------------------------------------
# 1. Event Study (TWFE with fixest::sunab)
# -------------------------------------------------------------------
cat("\n--- Sun-Abraham Event Study ---\n")

panel_j <- panel %>%
  filter(nace == "J") %>%
  mutate(
    cohort = if_else(first_treat == 0, Inf, as.numeric(first_treat))
  )

es_sa <- feols(
  log_empl ~ sunab(cohort, year) | country + year,
  data = panel_j,
  cluster = ~country
)
cat("Sun-Abraham event study:\n")
summary(es_sa)

# Save event study coefficients for table
es_coefs <- as.data.frame(coeftable(es_sa))
es_coefs$event_time <- as.numeric(gsub(".*::", "", rownames(es_coefs)))
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# -------------------------------------------------------------------
# 2. Pre-trend test (joint F-test on pre-treatment coefficients)
# -------------------------------------------------------------------
cat("\n--- Pre-trend joint F-test ---\n")
pre_coefs <- rownames(coeftable(es_sa))[es_coefs$event_time < 0]
if (length(pre_coefs) > 0) {
  pre_test <- wald(es_sa, pre_coefs)
  cat(sprintf("Joint F-test on pre-trends: F = %.2f, p = %.4f\n",
              pre_test$stat, pre_test$p))
  saveRDS(pre_test, "../data/pretrend_test.rds")
}

# -------------------------------------------------------------------
# 3. Leave-one-country-out
# -------------------------------------------------------------------
cat("\n--- Leave-one-country-out ---\n")

countries <- unique(panel_j$country)
loo_results <- map_dfr(countries, function(c) {
  d <- panel_j %>% filter(country != c)
  d$id <- as.integer(factor(d$country))

  cs_loo <- tryCatch({
    att_gt(
      yname = "log_empl", tname = "year",
      idname = "id", gname = "first_treat",
      data = d, control_group = "notyettreated",
      anticipation = 0, base_period = "universal"
    )
  }, error = function(e) NULL)

  if (is.null(cs_loo)) return(tibble(dropped = c, att = NA, se = NA))

  agg <- aggte(cs_loo, type = "simple")
  tibble(
    dropped = c,
    att = agg$overall.att,
    se = agg$overall.se
  )
})

cat("Leave-one-out ATTs:\n")
print(loo_results, n = 30)
saveRDS(loo_results, "../data/loo_results.rds")

# -------------------------------------------------------------------
# 4. Randomization Inference (main DDD spec)
# -------------------------------------------------------------------
cat("\n--- Randomization Inference (permute treatment across countries) ---\n")

ddd_data <- panel %>%
  mutate(
    country_nace = paste0(country, "_", nace),
    country_year = paste0(country, "_", year)
  )

# Actual DDD estimate
ddd_for_ri <- feols(
  log_empl ~ did_treat |
    country^nace + nace^year + country^year,
  data = ddd_data,
  cluster = ~country
)
actual_coef <- coef(ddd_for_ri)["did_treat"]

# Permute treatment timing across countries
set.seed(42)
n_perm <- 999
perm_coefs <- numeric(n_perm)

countries_w_treat <- panel %>%
  filter(nace == "J") %>%
  distinct(country, first_treat) %>%
  pull(first_treat)

for (i in seq_len(n_perm)) {
  shuffled_treat <- sample(countries_w_treat)
  country_map <- panel %>%
    filter(nace == "J") %>%
    distinct(country) %>%
    mutate(fake_treat = shuffled_treat)

  perm_data <- panel %>%
    left_join(country_map, by = "country") %>%
    mutate(
      fake_treated = as.integer(fake_treat > 0 & year >= fake_treat),
      fake_did_treat = fake_treated * is_info
    )

  perm_fit <- tryCatch({
    feols(log_empl ~ fake_did_treat |
            country^nace + nace^year + country^year,
          data = perm_data, cluster = ~country)
  }, error = function(e) NULL)

  if (!is.null(perm_fit)) {
    perm_coefs[i] <- coef(perm_fit)["fake_did_treat"]
  } else {
    perm_coefs[i] <- NA
  }
}

ri_p <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat(sprintf("RI p-value (two-sided): %.4f\n", ri_p))
cat(sprintf("Actual coef: %.4f, Permutation mean: %.4f, SD: %.4f\n",
            actual_coef, mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

ri_result <- list(
  actual_coef = actual_coef,
  perm_coefs = perm_coefs,
  p_value = ri_p
)
saveRDS(ri_result, "../data/ri_result.rds")

# -------------------------------------------------------------------
# 5. Placebo: NACE K should show no effect
# -------------------------------------------------------------------
cat("\n--- Placebo: NACE K (Finance) ---\n")

panel_k <- panel %>%
  filter(nace == "K") %>%
  mutate(id = as.integer(factor(country)))

cs_placebo <- att_gt(
  yname = "log_empl",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = panel_k,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

agg_placebo <- aggte(cs_placebo, type = "simple")
cat("\nPlacebo ATT (NACE K, log):\n")
print(summary(agg_placebo))
saveRDS(agg_placebo, "../data/placebo_k_result.rds")

# -------------------------------------------------------------------
# 6. HonestDiD sensitivity (if pre-trends exist)
# -------------------------------------------------------------------
cat("\n--- HonestDiD Sensitivity ---\n")

honest_result <- tryCatch({
  # Use CS-DiD dynamic estimates
  cs_dyn <- results$agg_log_dynamic

  # Extract pre and post estimates
  pre_idx <- which(cs_dyn$egt < 0)
  post_idx <- which(cs_dyn$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    beta_hat <- cs_dyn$att.egt
    sigma_hat <- diag(cs_dyn$se.egt^2)

    honest_res <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0.5, 2, by = 0.5)
    )
    cat("HonestDiD results:\n")
    print(honest_res)
    honest_res
  } else {
    cat("Not enough pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat(sprintf("HonestDiD failed: %s\n", e$message))
  NULL
})

if (!is.null(honest_result)) {
  saveRDS(honest_result, "../data/honest_did.rds")
}

# -------------------------------------------------------------------
# 7. Placebo treatment dates (shift treatment 2 years earlier)
# -------------------------------------------------------------------
cat("\n--- Placebo: Fake treatment 2 years early ---\n")

panel_j_placebo <- panel_j %>%
  mutate(
    first_treat_fake = if_else(first_treat > 0, first_treat - 2L, 0L)
  ) %>%
  filter(year < min(first_treat[first_treat > 0]))  # Pre-treatment only

if (nrow(panel_j_placebo) > 10) {
  panel_j_placebo$id <- as.integer(factor(panel_j_placebo$country))

  cs_fake <- tryCatch({
    att_gt(
      yname = "log_empl", tname = "year",
      idname = "id", gname = "first_treat_fake",
      data = panel_j_placebo,
      control_group = "notyettreated",
      anticipation = 0, base_period = "universal"
    )
  }, error = function(e) {
    cat(sprintf("Fake treatment CS-DiD failed: %s\n", e$message))
    NULL
  })

  if (!is.null(cs_fake)) {
    agg_fake <- aggte(cs_fake, type = "simple")
    cat("Placebo (fake dates) ATT:\n")
    print(summary(agg_fake))
    saveRDS(agg_fake, "../data/placebo_dates_result.rds")
  }
} else {
  cat("Not enough pre-treatment data for fake-date placebo.\n")
}

cat("\n=== Robustness checks complete ===\n")
