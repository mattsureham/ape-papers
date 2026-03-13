## 04_robustness.R — Robustness checks
## apep_0662: Clean Slate Laws and Statistical Discrimination

source("00_packages.R")
load("data/analysis_results.RData")

cat("=== Robustness Checks ===\n")

# =========================================================
# 1. Exclude COVID period (2020-2021)
# =========================================================
cat("\n--- Excluding COVID period ---\n")

bls_nocovid <- bls_annual %>%
  filter(!(year %in% c(2020, 2021)))

twfe_urate_nocovid <- feols(urate ~ post | state_id + year,
                            data = bls_nocovid, cluster = ~state_id)
twfe_epop_nocovid <- feols(log_emp ~ post | state_id + year,
                           data = bls_nocovid %>% filter(!is.na(log_emp)),
                           cluster = ~state_id)

cat("  Urate (no COVID): ", round(coef(twfe_urate_nocovid)["post"], 3),
    " (", round(se(twfe_urate_nocovid)["post"], 3), ")\n")
cat("  E-pop (no COVID): ", round(coef(twfe_epop_nocovid)["post"], 3),
    " (", round(se(twfe_epop_nocovid)["post"], 3), ")\n")

# =========================================================
# 2. Implementation date treatment timing
# =========================================================
cat("\n--- Implementation date as treatment ---\n")

# Use implementation year instead of enactment year
impl_dates <- tribble(
  ~state_abbr, ~impl_year,
  "PA",  2019,
  "UT",  2022,
  "NJ",  2020,
  "CA",  2023,
  "MI",  2023,
  "CT",  2023,
  "DE",  2024,
  "VA",  0,  # Not yet implemented (2026)
  "OK",  0,  # Not yet implemented (2025, but marginal)
  "CO",  0,  # Not yet implemented (2025)
  "MN",  0,  # Not yet implemented (2025)
  "NY",  0   # Not yet implemented (2027)
)

bls_impl <- bls_annual %>%
  left_join(impl_dates, by = "state_abbr") %>%
  mutate(
    first_treat_impl = ifelse(is.na(impl_year) | impl_year == 0, 0, impl_year),
    post_impl = ifelse(first_treat_impl > 0 & year >= first_treat_impl, 1, 0)
  )

twfe_urate_impl <- feols(urate ~ post_impl | state_id + year,
                         data = bls_impl, cluster = ~state_id)
twfe_epop_impl <- feols(log_emp ~ post_impl | state_id + year,
                        data = bls_impl %>% filter(!is.na(log_emp)),
                        cluster = ~state_id)

cat("  Urate (implementation): ", round(coef(twfe_urate_impl)["post_impl"], 3),
    " (", round(se(twfe_urate_impl)["post_impl"], 3), ")\n")
cat("  E-pop (implementation): ", round(coef(twfe_epop_impl)["post_impl"], 3),
    " (", round(se(twfe_epop_impl)["post_impl"], 3), ")\n")

# =========================================================
# 3. Permutation inference (few-cluster robust)
# =========================================================
cat("\n--- Permutation inference ---\n")

# Permutation test: randomly reassign treatment status 999 times
set.seed(42)
n_perm <- 999
perm_coefs_urate <- numeric(n_perm)
perm_coefs_gap <- numeric(n_perm)

treated_ids <- unique(bls_annual$state_id[bls_annual$treated == 1])
all_ids <- unique(bls_annual$state_id)
n_treated <- length(treated_ids)

for (i in 1:n_perm) {
  fake_treated <- sample(all_ids, n_treated)
  perm_data <- bls_annual %>%
    mutate(post_perm = ifelse(state_id %in% fake_treated & year >= 2019, 1, 0))
  fit_perm <- feols(urate ~ post_perm | state_id + year, data = perm_data, cluster = ~state_id)
  perm_coefs_urate[i] <- coef(fit_perm)["post_perm"]
}

actual_coef <- coef(twfe_urate)["post"]
perm_p_urate <- mean(abs(perm_coefs_urate) >= abs(actual_coef))
cat("  Permutation p-value (urate): ", perm_p_urate, "\n")

# =========================================================
# 4. Placebo: E-pop ratio for states with pre-existing BTB
# =========================================================
cat("\n--- Ban-the-box interaction ---\n")

# States that had BTB before clean slate
btb_states <- c("CA", "CO", "CT", "DE", "HI", "IL", "MA", "MD", "MN",
                "MO", "NE", "NJ", "NM", "NY", "OH", "OK", "OR", "PA",
                "RI", "UT", "VA", "VT", "WA")

bls_btb <- bls_annual %>%
  mutate(btb = ifelse(state_abbr %in% btb_states, 1, 0))

twfe_urate_btb <- feols(urate ~ post + post:btb | state_id + year,
                        data = bls_btb, cluster = ~state_id)

cat("  Clean slate effect (no BTB): ", round(coef(twfe_urate_btb)["post"], 3), "\n")
cat("  Incremental effect (BTB states): ", round(coef(twfe_urate_btb)["post:btb"], 3), "\n")

# =========================================================
# 5. Leave-one-out: drop each treated state
# =========================================================
cat("\n--- Leave-one-out sensitivity ---\n")

treated_states <- unique(bls_annual$state_abbr[bls_annual$treated == 1])
loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (st in treated_states) {
  loo_data <- bls_annual %>% filter(state_abbr != st)
  fit <- feols(urate ~ post | state_id + year, data = loo_data, cluster = ~state_id)
  loo_results <- rbind(loo_results, data.frame(
    dropped = st,
    coef = coef(fit)["post"],
    se = se(fit)["post"]
  ))
}

cat("  LOO range for urate: [",
    round(min(loo_results$coef), 3), ", ",
    round(max(loo_results$coef), 3), "]\n")
cat("  Full sample estimate: ", round(coef(twfe_urate)["post"], 3), "\n")

# =========================================================
# 6. HonestDiD sensitivity (if pre-trends exist)
# =========================================================
cat("\n--- HonestDiD sensitivity ---\n")

# Extract event study coefficients from Sun-Abraham for HonestDiD
tryCatch({
  # Get pre-trend coefficients
  sa_coefs <- coef(sa_urate)
  sa_se <- se(sa_urate)
  sa_vcov <- vcov(sa_urate)

  # Identify pre-treatment coefficients
  pre_names <- names(sa_coefs)[grepl("::-", names(sa_coefs))]
  post_names <- names(sa_coefs)[grepl("::[0-9]", names(sa_coefs)) & !grepl("::-", names(sa_coefs))]

  if (length(pre_names) >= 2 && length(post_names) >= 1) {
    cat("  Pre-trend coefficients: ", length(pre_names), "\n")
    cat("  Post-treatment coefficients: ", length(post_names), "\n")

    # HonestDiD requires specific matrix structure
    # Use the betahat and sigma from the event study
    all_names <- c(pre_names, post_names)
    betahat <- sa_coefs[all_names]
    sigma <- sa_vcov[all_names, all_names]

    honest_result <- tryCatch({
      HonestDiD::createSensitivityResults(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_names),
        numPostPeriods = length(post_names),
        Mvec = seq(0, 0.5, by = 0.1)
      )
    }, error = function(e) {
      cat("  HonestDiD computation failed: ", e$message, "\n")
      NULL
    })

    if (!is.null(honest_result)) {
      cat("  HonestDiD bounds computed.\n")
      print(honest_result)
    }
  }
}, error = function(e) {
  cat("  HonestDiD setup failed: ", e$message, "\n")
})

# =========================================================
# Save robustness results
# =========================================================
save(
  twfe_urate_nocovid, twfe_epop_nocovid,
  twfe_urate_impl, twfe_epop_impl,
  perm_p_urate,
  twfe_urate_btb,
  loo_results,
  file = "data/robustness_results.RData"
)

cat("\n=== Robustness checks complete ===\n")
