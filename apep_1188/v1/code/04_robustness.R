# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_balanced.rds")
models <- readRDS("../data/main_models.rds")

panel <- panel %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    rel_qtr = round((yq - 2018.0) * 4)
  )

# ============================================================================
# 1. Wild cluster bootstrap inference
# ============================================================================

cat("=== Wild Cluster Bootstrap ===\n")

# Main DDD with wild cluster bootstrap
m_ddd <- feols(log_emp ~ info_post_eu |
                 county_fips^yearqtr + naics2^yearqtr,
               data = panel, cluster = ~state_fips)

boot_result <- tryCatch({
  boottest(
    m_ddd,
    param = "info_post_eu",
    clustid = ~state_fips,
    B = 999,
    type = "webb"
  )
}, error = function(e) {
  cat("Bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("Wild bootstrap CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
}

# ============================================================================
# 2. Placebo: Pre-period DDD (should be zero)
# ============================================================================

cat("\n=== Pre-Period Placebo ===\n")

panel_pre <- panel %>%
  filter(yq < 2018.5) %>%  # Only pre-period
  mutate(
    placebo_post = (yq >= 2017.25),  # Fake treatment at 2017Q2
    placebo_ddd = info * placebo_post * eu_share
  )

m_placebo <- feols(log_emp ~ placebo_ddd |
                     county_fips^yearqtr + naics2^yearqtr,
                   data = panel_pre, cluster = ~state_fips)

cat(sprintf("Placebo DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m_placebo)["placebo_ddd"],
            se(m_placebo)["placebo_ddd"],
            pvalue(m_placebo)["placebo_ddd"]))

# ============================================================================
# 3. Including 2018Q2 transition quarter
# ============================================================================

cat("\n=== Including Transition Quarter ===\n")

panel_full <- readRDS("../data/qwi_2digit.rds") %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    post = (yq >= 2018.5),
    info = as.integer(naics2 == "51"),
    yearqtr = paste0(year, "Q", quarter)
  ) %>%
  left_join(readRDS("../data/trade_exposure.rds") %>% select(state_fips, eu_share),
            by = "state_fips") %>%
  filter(!is.na(eu_share), year >= 2016, yq <= 2020.0) %>%
  filter(county_fips %in% unique(panel$county_fips)) %>%
  mutate(
    log_emp = log(Emp + 1),
    info_post_eu = info * post * eu_share
  )

m_with_q2 <- feols(log_emp ~ info_post_eu |
                      county_fips^yearqtr + naics2^yearqtr,
                    data = panel_full, cluster = ~state_fips)

cat(sprintf("With 2018Q2 (β): %.4f (SE: %.4f)\n",
            coef(m_with_q2)["info_post_eu"], se(m_with_q2)["info_post_eu"]))

# ============================================================================
# 4. Leave-one-state-out
# ============================================================================

cat("\n=== Leave-One-State-Out ===\n")

states <- unique(panel$state_fips)
loo_coefs <- numeric(length(states))
loo_ses <- numeric(length(states))

for (j in seq_along(states)) {
  m_loo <- feols(log_emp ~ info_post_eu |
                   county_fips^yearqtr + naics2^yearqtr,
                 data = panel %>% filter(state_fips != states[j]),
                 cluster = ~state_fips)
  loo_coefs[j] <- coef(m_loo)["info_post_eu"]
  loo_ses[j] <- se(m_loo)["info_post_eu"]
}

cat(sprintf("LOO coefficient range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("LOO SE range: [%.4f, %.4f]\n", min(loo_ses), max(loo_ses)))
cat(sprintf("Main estimate: %.4f. LOO sign consistent: %s\n",
            coef(m_ddd)["info_post_eu"],
            ifelse(all(sign(loo_coefs) == sign(coef(m_ddd)["info_post_eu"])), "YES", "NO")))

# ============================================================================
# 5. Alternative control industries
# ============================================================================

cat("\n=== Alternative Control Industries ===\n")

# Fetch manufacturing + retail if available, otherwise use subsets
# Test with just Finance (52) as single control
panel_fin <- panel %>% filter(naics2 %in% c("51", "52"))
m_fin <- feols(log_emp ~ info_post_eu |
                 county_fips^yearqtr + naics2^yearqtr,
               data = panel_fin, cluster = ~state_fips)

# Test with just Professional Services (54) as single control
panel_pro <- panel %>% filter(naics2 %in% c("51", "54"))
m_pro <- feols(log_emp ~ info_post_eu |
                 county_fips^yearqtr + naics2^yearqtr,
               data = panel_pro, cluster = ~state_fips)

cat(sprintf("Finance-only control (β): %.4f (SE: %.4f)\n",
            coef(m_fin)["info_post_eu"], se(m_fin)["info_post_eu"]))
cat(sprintf("Professional-only control (β): %.4f (SE: %.4f)\n",
            coef(m_pro)["info_post_eu"], se(m_pro)["info_post_eu"]))

# ============================================================================
# 6. 3-digit NAICS placebo: 512 (Motion Picture) vs 518 (Data Processing)
# ============================================================================

cat("\n=== 3-Digit NAICS Placebo ===\n")

qwi_3d <- readRDS("../data/qwi_3digit.rds") %>%
  left_join(readRDS("../data/trade_exposure.rds") %>% select(state_fips, eu_share),
            by = "state_fips") %>%
  filter(!is.na(eu_share)) %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    post = (yq >= 2018.5),
    transition = (year == 2018 & quarter == 2),
    log_emp = log(Emp + 1),
    yearqtr = paste0(year, "Q", quarter)
  ) %>%
  filter(!transition, year >= 2016, yq <= 2020.0)

# 518 (Data Processing) should respond; 512 (Motion Picture) should NOT
for (naics in c("518", "512")) {
  d <- qwi_3d %>%
    filter(naics3 %in% c(naics, "515")) %>%  # Use 515 (Broadcasting) as control
    mutate(
      treated = as.integer(naics3 == naics),
      ddd = treated * post * eu_share
    )

  m_n3 <- tryCatch(
    feols(log_emp ~ ddd | county_fips + naics3 + yearqtr,
          data = d, cluster = ~state_fips),
    error = function(e) {
      cat(sprintf("  NAICS %s: singleton issue, skipping\n", naics))
      NULL
    }
  )
  if (is.null(m_n3)) next
  cat(sprintf("NAICS %s DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
              naics, coef(m_n3)["ddd"], se(m_n3)["ddd"], pvalue(m_n3)["ddd"]))
}

# ============================================================================
# Save robustness results
# ============================================================================

robustness <- list(
  bootstrap_p = if (!is.null(boot_result)) boot_result$p_val else NA,
  bootstrap_ci = if (!is.null(boot_result)) boot_result$conf_int else c(NA, NA),
  placebo_coef = unname(coef(m_placebo)["placebo_ddd"]),
  placebo_p = unname(pvalue(m_placebo)["placebo_ddd"]),
  with_q2_coef = unname(coef(m_with_q2)["info_post_eu"]),
  loo_range = c(min(loo_coefs), max(loo_coefs)),
  loo_sign_consistent = all(sign(loo_coefs) == sign(coef(m_ddd)["info_post_eu"])),
  finance_control_coef = unname(coef(m_fin)["info_post_eu"]),
  prof_control_coef = unname(coef(m_pro)["info_post_eu"])
)

saveRDS(robustness, "../data/robustness_results.rds")
saveRDS(list(m_placebo = m_placebo, m_with_q2 = m_with_q2,
             m_fin = m_fin, m_pro = m_pro,
             loo_coefs = loo_coefs, loo_ses = loo_ses,
             boot_result = boot_result),
        "../data/robustness_models.rds")

cat("\nRobustness checks complete.\n")
