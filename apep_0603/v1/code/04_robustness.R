## 04_robustness.R — Robustness checks and placebo tests
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

source("00_packages.R")
load("../data/main_models.RData")

## ------------------------------------------------------------------
## 1. PLACEBO TEST: Fake treatment in 2013
## ------------------------------------------------------------------
cat("=== PLACEBO TEST: Fake treatment 2013 ===\n")

df_pre <- df %>% filter(year <= 2015)
df_pre <- df_pre %>%
  mutate(
    fake_post = as.integer(year >= 2013),
    fake_treat = intensity * fake_post
  )

placebo_models <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ fake_treat | powiat_id + year"))
  placebo_models[[y]] <- feols(fml, data = df_pre, cluster = ~powiat_id)
  cat(sprintf("\n%s (placebo 2013):\n", outcome_labels[i]))
  print(coeftable(placebo_models[[y]]))
}

## ------------------------------------------------------------------
## 2. DROP CITY POWIATS (grodzkie)
## ------------------------------------------------------------------
cat("\n=== DROP CITY POWIATS ===\n")

df_rural <- df %>% filter(!is_city_powiat)
cat(sprintf("Non-city powiats: %d (dropped %d city powiats)\n",
            n_distinct(df_rural$powiat_id),
            n_distinct(df$powiat_id) - n_distinct(df_rural$powiat_id)))

models_rural <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_post | powiat_id + year"))
  models_rural[[y]] <- feols(fml, data = df_rural, cluster = ~powiat_id)
}

## ------------------------------------------------------------------
## 3. PERMUTATION INFERENCE
## ------------------------------------------------------------------
cat("\n=== PERMUTATION INFERENCE (500 permutations) ===\n")

set.seed(42)
n_perms <- 500
perm_results <- matrix(NA, nrow = n_perms, ncol = length(outcomes))
colnames(perm_results) <- outcomes

# Get the actual coefficients
actual_coefs <- sapply(outcomes, function(y) {
  coeftable(models_baseline[[y]])["treat_post", "Estimate"]
})

# Permute treatment intensity across powiats
powiat_ids <- unique(df$powiat_id)
n_powiats <- length(powiat_ids)

for (p in seq_len(n_perms)) {
  if (p %% 100 == 0) cat(sprintf("  Permutation %d / %d\n", p, n_perms))

  # Shuffle intensity assignment
  shuffled <- sample(powiat_ids)
  intensity_map <- setNames(
    df %>% filter(year == 2015) %>% distinct(powiat_id, intensity) %>% pull(intensity),
    df %>% filter(year == 2015) %>% distinct(powiat_id) %>% pull(powiat_id)
  )
  new_intensity <- intensity_map[shuffled]
  names(new_intensity) <- powiat_ids

  df_perm <- df %>%
    mutate(
      perm_intensity = new_intensity[powiat_id],
      perm_treat = perm_intensity * post2016
    )

  for (i in seq_along(outcomes)) {
    y <- outcomes[i]
    fml <- as.formula(paste0(y, " ~ perm_treat | powiat_id + year"))
    m <- tryCatch(
      feols(fml, data = df_perm, cluster = ~powiat_id),
      error = function(e) NULL
    )
    if (!is.null(m)) {
      perm_results[p, i] <- coeftable(m)["perm_treat", "Estimate"]
    }
  }
}

# Compute RI p-values (two-sided)
ri_pvalues <- sapply(seq_along(outcomes), function(i) {
  perm_coefs <- perm_results[, i]
  perm_coefs <- perm_coefs[!is.na(perm_coefs)]
  mean(abs(perm_coefs) >= abs(actual_coefs[i]))
})
names(ri_pvalues) <- outcomes

cat("\nRandomization inference p-values:\n")
print(ri_pvalues)

## ------------------------------------------------------------------
## 4. HETEROGENEITY: High vs low baseline income
## ------------------------------------------------------------------
cat("\n=== HETEROGENEITY: By baseline income proxy ===\n")

# Use 2015 business registration rate as income proxy
# (powiats with more businesses are richer)
df <- df %>%
  left_join(
    df %>% filter(year == 2015) %>%
      select(powiat_id, biz_2015 = biz_rate),
    by = "powiat_id"
  ) %>%
  mutate(
    high_income = as.integer(biz_2015 > median(biz_2015, na.rm = TRUE)),
    treat_post_hi = treat_post * high_income,
    treat_post_lo = treat_post * (1 - high_income)
  )

het_models <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_post_hi + treat_post_lo | powiat_id + year"))
  het_models[[y]] <- feols(fml, data = df, cluster = ~powiat_id)
  cat(sprintf("\n%s (heterogeneity by income):\n", outcome_labels[i]))
  print(coeftable(het_models[[y]]))
}

## ------------------------------------------------------------------
## 5. HonestDiD SENSITIVITY (for main outcome)
## ------------------------------------------------------------------
cat("\n=== HonestDiD SENSITIVITY ANALYSIS ===\n")

# Apply to business registrations event study
tryCatch({
  es_biz <- es_models[["biz_rate"]]
  ct <- coeftable(es_biz)

  # Extract pre-period and post-period coefficients
  coef_names <- rownames(ct)
  pre_idx <- grep("et::-[2-9]|et::-1[0-9]", coef_names)  # pre-period (not ref)
  post_idx <- grep("et::[0-9]", coef_names)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    beta_hat <- ct[c(pre_idx, post_idx), "Estimate"]
    sigma <- vcov(es_biz)[c(pre_idx, post_idx), c(pre_idx, post_idx)]

    n_pre <- length(pre_idx)
    n_post <- length(post_idx)

    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      Mvec = seq(0, 0.5, by = 0.1)
    )

    cat("HonestDiD sensitivity results (business registrations):\n")
    print(honest_result)

    write_csv(as.data.frame(honest_result), "../data/honestdid_results.csv")
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat("HonestDiD failed:", conditionMessage(e), "\n")
  cat("Proceeding without sensitivity analysis.\n")
})

## ------------------------------------------------------------------
## 6. SAVE ROBUSTNESS RESULTS
## ------------------------------------------------------------------
robustness <- list(
  placebo_pvalues = sapply(outcomes, function(y) {
    coeftable(placebo_models[[y]])["fake_treat", "Pr(>|t|)"]
  }),
  ri_pvalues = ri_pvalues,
  n_rural_powiats = n_distinct(df_rural$powiat_id),
  rural_coefs = sapply(outcomes, function(y) {
    coeftable(models_rural[[y]])["treat_post", "Estimate"]
  }),
  rural_ses = sapply(outcomes, function(y) {
    coeftable(models_rural[[y]])["treat_post", "Std. Error"]
  }),
  het_hi_coefs = sapply(outcomes, function(y) {
    coeftable(het_models[[y]])["treat_post_hi", "Estimate"]
  }),
  het_lo_coefs = sapply(outcomes, function(y) {
    coeftable(het_models[[y]])["treat_post_lo", "Estimate"]
  })
)

jsonlite::write_json(robustness, "../data/robustness_results.json", auto_unbox = TRUE)
cat("\nRobustness results saved.\n")

save(placebo_models, models_rural, het_models, ri_pvalues,
     perm_results, actual_coefs,
     file = "../data/robustness_models.RData")
cat("Robustness models saved.\n")
