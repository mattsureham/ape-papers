# 04_robustness.R — Robustness checks for apep_1215
# 1. Randomization inference (permutation test)
# 2. Leave-one-NUTS1-out jackknife
# 3. Pre-trend test
# 4. Excluding COVID years (2020-2021)
# 5. East vs West heterogeneity

source("00_packages.R")

cat("=== Running robustness checks ===\n")

unemp_panel <- readRDS("../data/unemp_panel.rds")
emp_panel <- readRDS("../data/emp_panel.rds")
vv_prices <- readRDS("../data/vv_prices.rds")

# --- Main model for reference ---
m_main <- feols(unemp_rate ~ treat_dt_10 | geo + year, data = unemp_panel,
                cluster = ~nuts1)

# --- 1. Randomization Inference ---
cat("--- Randomization inference (1000 permutations) ---\n")
set.seed(42)
n_perms <- 1000
observed_coef <- as.numeric(coef(m_main)["treat_dt_10"])
perm_coefs <- numeric(n_perms)

# Get unique subsidy values per region
region_subsidies <- vv_prices %>% select(geo, subsidy) %>% deframe()

for (b in 1:n_perms) {
  # Shuffle subsidy assignments across regions
  shuffled <- sample(region_subsidies)
  names(shuffled) <- names(region_subsidies)

  df_perm <- unemp_panel %>%
    mutate(
      subsidy_perm = shuffled[geo],
      treat_perm = (subsidy_perm / 10) * post_dt
    )
  m_perm <- tryCatch(
    feols(unemp_rate ~ treat_perm | geo + year, data = df_perm, cluster = ~nuts1),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_coefs[b] <- as.numeric(coef(m_perm)["treat_perm"])
  } else {
    perm_coefs[b] <- NA
  }
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(observed_coef), na.rm = TRUE)
ri_ci <- quantile(perm_coefs, c(0.025, 0.975), na.rm = TRUE)

cat(sprintf("  Observed: %.4f\n", observed_coef))
cat(sprintf("  RI p-value (two-sided): %.3f\n", ri_pvalue))
cat(sprintf("  RI 95%% range: [%.4f, %.4f]\n", ri_ci[1], ri_ci[2]))

# --- 2. Leave-one-NUTS1-out jackknife ---
cat("\n--- Leave-one-NUTS1-out ---\n")
nuts1_list <- unique(unemp_panel$nuts1)
jack_coefs <- numeric(length(nuts1_list))
jack_labels <- character(length(nuts1_list))

for (i in seq_along(nuts1_list)) {
  df_jack <- unemp_panel %>% filter(nuts1 != nuts1_list[i])
  m_jack <- feols(unemp_rate ~ treat_dt_10 | geo + year, data = df_jack,
                  cluster = ~nuts1)
  jack_coefs[i] <- as.numeric(coef(m_jack)["treat_dt_10"])
  jack_labels[i] <- nuts1_list[i]
}

cat(sprintf("  Full sample: %.4f\n", observed_coef))
cat(sprintf("  Jackknife range: [%.4f, %.4f]\n", min(jack_coefs), max(jack_coefs)))
cat(sprintf("  Most influential: dropping %s changes coef to %.4f\n",
            jack_labels[which.max(abs(jack_coefs - observed_coef))],
            jack_coefs[which.max(abs(jack_coefs - observed_coef))]))

# --- 3. Pre-trend test ---
cat("\n--- Pre-trend test ---\n")
pre_data <- unemp_panel %>% filter(post_dt == 0)
pre_data <- pre_data %>%
  mutate(
    trend = year - min(year),
    subsidy_trend = (subsidy / 10) * trend
  )

m_pretrend <- feols(unemp_rate ~ subsidy_trend | geo + year, data = pre_data,
                    cluster = ~nuts1)
cat(sprintf("  Subsidy/10 × trend: %.4f (SE: %.4f, p: %.3f)\n",
            coef(m_pretrend)["subsidy_trend"],
            se(m_pretrend)["subsidy_trend"],
            pvalue(m_pretrend)["subsidy_trend"]))

# --- 4. Excluding COVID years ---
cat("\n--- Excluding COVID years (2020-2021) ---\n")
unemp_nocovid <- unemp_panel %>% filter(!(year %in% c(2020, 2021)))
m_nocovid <- feols(unemp_rate ~ treat_dt_10 | geo + year, data = unemp_nocovid,
                   cluster = ~nuts1)
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.3f)\n",
            coef(m_nocovid)["treat_dt_10"],
            se(m_nocovid)["treat_dt_10"],
            pvalue(m_nocovid)["treat_dt_10"]))

# --- 5. East vs West heterogeneity ---
cat("\n--- East vs West ---\n")
m_west <- feols(unemp_rate ~ treat_dt_10 | geo + year,
                data = filter(unemp_panel, !east), cluster = ~nuts1)
m_east <- feols(unemp_rate ~ treat_dt_10 | geo + year,
                data = filter(unemp_panel, east), cluster = ~nuts1)

cat(sprintf("  West: %.4f (SE: %.4f, p: %.3f, N=%d)\n",
            coef(m_west)["treat_dt_10"], se(m_west)["treat_dt_10"],
            pvalue(m_west)["treat_dt_10"], nobs(m_west)))
cat(sprintf("  East: %.4f (SE: %.4f, p: %.3f, N=%d)\n",
            coef(m_east)["treat_dt_10"], se(m_east)["treat_dt_10"],
            pvalue(m_east)["treat_dt_10"], nobs(m_east)))

# --- Save results ---
robustness <- list(
  ri = list(
    observed = observed_coef,
    perm_coefs = perm_coefs,
    p_value = ri_pvalue,
    ci_lower = as.numeric(ri_ci[1]),
    ci_upper = as.numeric(ri_ci[2])
  ),
  jackknife = list(
    coefs = jack_coefs,
    labels = jack_labels,
    range = c(min(jack_coefs), max(jack_coefs))
  ),
  pretrend = list(
    coef = as.numeric(coef(m_pretrend)["subsidy_trend"]),
    se = as.numeric(se(m_pretrend)["subsidy_trend"]),
    pval = as.numeric(pvalue(m_pretrend)["subsidy_trend"])
  ),
  no_covid = list(
    coef = as.numeric(coef(m_nocovid)["treat_dt_10"]),
    se = as.numeric(se(m_nocovid)["treat_dt_10"]),
    pval = as.numeric(pvalue(m_nocovid)["treat_dt_10"])
  ),
  west = list(
    coef = as.numeric(coef(m_west)["treat_dt_10"]),
    se = as.numeric(se(m_west)["treat_dt_10"])
  ),
  east = list(
    coef = as.numeric(coef(m_east)["treat_dt_10"]),
    se = as.numeric(se(m_east)["treat_dt_10"])
  )
)

saveRDS(robustness, "../data/robustness.rds")
saveRDS(m_west, "../data/m_west.rds")
saveRDS(m_east, "../data/m_east.rds")
saveRDS(m_nocovid, "../data/m_nocovid.rds")

cat("\n=== Robustness checks complete ===\n")
