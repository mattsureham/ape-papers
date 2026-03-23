# =============================================================================
# 04_robustness.R — Robustness checks
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------------------
# 1. NAICS 23 (Construction) placebo — should show NULL DDD
# ---------------------------------------------------------------------------

cat("=== PLACEBO: NAICS 23 (Construction) ===\n")
df23 <- df %>% filter(industry == "23" & in_pre_covid_sample)

m_placebo_emp <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                         fips^race + t^race + state_fips^t,
                       data = df23, cluster = ~state_fips)

m_placebo_earn <- feols(ln_earn ~ treat_post_black + treat_post + black:i(t) |
                          fips^race + t^race + state_fips^t,
                        data = df23, cluster = ~state_fips)

m_placebo_sep <- feols(ln_sep ~ treat_post_black + treat_post + black:i(t) |
                         fips^race + t^race + state_fips^t,
                       data = df23, cluster = ~state_fips)

cat(sprintf("Placebo ln(Emp):  DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_placebo_emp)["treat_post_black"],
            se(m_placebo_emp)["treat_post_black"],
            fixest::pvalue(m_placebo_emp)["treat_post_black"]))
cat(sprintf("Placebo ln(Earn): DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_placebo_earn)["treat_post_black"],
            se(m_placebo_earn)["treat_post_black"],
            fixest::pvalue(m_placebo_earn)["treat_post_black"]))
cat(sprintf("Placebo ln(Sep):  DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_placebo_sep)["treat_post_black"],
            se(m_placebo_sep)["treat_post_black"],
            fixest::pvalue(m_placebo_sep)["treat_post_black"]))

# ---------------------------------------------------------------------------
# 2. Leave-one-out by treatment cohort (drop Oregon)
# ---------------------------------------------------------------------------

cat("\n=== LEAVE-ONE-OUT: Drop Oregon ===\n")
df72_no_or <- df %>%
  filter(industry == "72" & in_pre_covid_sample & state_fips != 41L)

m_loo_emp <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                     fips^race + t^race + state_fips^t,
                   data = df72_no_or, cluster = ~state_fips)

cat(sprintf("Without Oregon: DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_loo_emp)["treat_post_black"],
            se(m_loo_emp)["treat_post_black"],
            fixest::pvalue(m_loo_emp)["treat_post_black"]))

# Drop SF
cat("\n=== LEAVE-ONE-OUT: Drop San Francisco ===\n")
df72_no_sf <- df %>%
  filter(industry == "72" & in_pre_covid_sample & fips != 6075L)

m_loo_sf <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                    fips^race + t^race + state_fips^t,
                  data = df72_no_sf, cluster = ~state_fips)

cat(sprintf("Without SF: DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_loo_sf)["treat_post_black"],
            se(m_loo_sf)["treat_post_black"],
            fixest::pvalue(m_loo_sf)["treat_post_black"]))

# Drop NYC
cat("\n=== LEAVE-ONE-OUT: Drop NYC ===\n")
nyc_fips <- c(36005L, 36047L, 36061L, 36081L, 36085L)
df72_no_nyc <- df %>%
  filter(industry == "72" & in_pre_covid_sample & !(fips %in% nyc_fips))

m_loo_nyc <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                     fips^race + t^race + state_fips^t,
                   data = df72_no_nyc, cluster = ~state_fips)

cat(sprintf("Without NYC: DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_loo_nyc)["treat_post_black"],
            se(m_loo_nyc)["treat_post_black"],
            fixest::pvalue(m_loo_nyc)["treat_post_black"]))

# ---------------------------------------------------------------------------
# 3. Full sample (including COVID-era adopters)
# ---------------------------------------------------------------------------

cat("\n=== FULL SAMPLE (includes COVID-era adopters) ===\n")
df72_full <- df %>% filter(industry == "72")

m_full_emp <- feols(ln_emp ~ treat_post_black + treat_post + black:i(t) |
                      fips^race + t^race + state_fips^t,
                    data = df72_full, cluster = ~state_fips)

m_full_earn <- feols(ln_earn ~ treat_post_black + treat_post + black:i(t) |
                       fips^race + t^race + state_fips^t,
                     data = df72_full, cluster = ~state_fips)

cat(sprintf("Full sample ln(Emp):  DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_full_emp)["treat_post_black"],
            se(m_full_emp)["treat_post_black"],
            fixest::pvalue(m_full_emp)["treat_post_black"]))
cat(sprintf("Full sample ln(Earn): DDD = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_full_earn)["treat_post_black"],
            se(m_full_earn)["treat_post_black"],
            fixest::pvalue(m_full_earn)["treat_post_black"]))

# ---------------------------------------------------------------------------
# 4. Randomization Inference (permute treatment across states)
# ---------------------------------------------------------------------------

cat("\n=== RANDOMIZATION INFERENCE ===\n")

df72_pre <- df %>% filter(industry == "72" & in_pre_covid_sample)

# Get the observed DDD coefficient
obs_coef <- coef(results$twfe_precovid$emp)["treat_post_black"]

# Permute state treatment status 500 times
set.seed(42)
n_perm <- 500
treated_states <- unique(df72_pre$state_fips[df72_pre$treated_ever])
all_states <- unique(df72_pre$state_fips)
n_treated_states <- length(treated_states)

perm_coefs <- numeric(n_perm)
cat(sprintf("Running %d permutations (permuting %d treated states among %d)...\n",
            n_perm, n_treated_states, length(all_states)))

for (i in seq_len(n_perm)) {
  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perm))

  # Randomly assign treatment to states
  fake_treated <- sample(all_states, n_treated_states)

  df_perm <- df72_pre %>%
    mutate(
      fake_treat = state_fips %in% fake_treated,
      fake_treat_post = as.integer(fake_treat & post),
      fake_ddd = fake_treat_post * black
    )

  m_perm <- tryCatch({
    feols(ln_emp ~ fake_ddd + fake_treat_post + black:i(t) |
            fips^race + t^race + state_fips^t,
          data = df_perm, cluster = ~state_fips)
  }, error = function(e) NULL)

  if (!is.null(m_perm) && "fake_ddd" %in% names(coef(m_perm))) {
    perm_coefs[i] <- coef(m_perm)["fake_ddd"]
  } else {
    perm_coefs[i] <- NA_real_
  }
}

valid_perms <- perm_coefs[!is.na(perm_coefs)]
ri_p <- mean(abs(valid_perms) >= abs(obs_coef))
cat(sprintf("RI p-value (two-sided): %.3f (%d valid permutations)\n",
            ri_p, length(valid_perms)))
cat(sprintf("Observed DDD: %.4f | Permutation distribution: mean=%.4f, sd=%.4f\n",
            obs_coef, mean(valid_perms), sd(valid_perms)))

# ---------------------------------------------------------------------------
# 5. Save robustness results
# ---------------------------------------------------------------------------

rob_results <- list(
  placebo = list(emp = m_placebo_emp, earn = m_placebo_earn, sep = m_placebo_sep),
  loo_no_oregon = m_loo_emp,
  loo_no_sf = m_loo_sf,
  loo_no_nyc = m_loo_nyc,
  full_sample = list(emp = m_full_emp, earn = m_full_earn),
  ri = list(obs_coef = obs_coef, perm_coefs = valid_perms, ri_p = ri_p)
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
