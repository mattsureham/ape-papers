# 04_robustness.R — Robustness checks
# apep_1131: The Hollow Safety Net

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
shares <- read_csv("../data/bartik_shares.csv", show_col_types = FALSE)
growth <- read_csv("../data/industry_growth.csv", show_col_types = FALSE)

# ============================================================================
# 1. Rotemberg Weights — Which industries drive the Bartik instrument?
# ============================================================================
cat("=== Rotemberg Weights ===\n")

# Approximate Rotemberg weights: contribution of each industry to the variation
# Weight_k ≈ sum_s (share_sk × var(g_kt))
ind_var <- growth %>%
  group_by(industry) %>%
  summarise(
    var_g = var(g_loo, na.rm = TRUE),
    mean_g = mean(g_loo, na.rm = TRUE),
    .groups = "drop"
  )

# Average share by industry
avg_share <- shares %>%
  group_by(industry) %>%
  summarise(avg_share = mean(share), .groups = "drop")

rotemberg <- ind_var %>%
  inner_join(avg_share, by = "industry") %>%
  mutate(
    approx_weight = avg_share * var_g,
    approx_weight_norm = approx_weight / sum(approx_weight)
  ) %>%
  arrange(desc(approx_weight_norm))

cat("Top 5 Rotemberg-weight industries:\n")
print(head(rotemberg, 5))
write_csv(rotemberg, "../data/rotemberg_weights.csv")

# ============================================================================
# 2. Leave-One-Industry-Out — Drop top Rotemberg weight industries
# ============================================================================
cat("\n=== Leave-One-Industry-Out ===\n")

top_industries <- rotemberg %>% slice_head(n = 5) %>% pull(industry)

loo_results <- list()
for (drop_ind in top_industries) {
  # Recompute Bartik WITHOUT this industry
  shares_loo <- shares %>% filter(industry != drop_ind) %>%
    group_by(state_fips) %>%
    mutate(share_loo = share / sum(share)) %>%  # Renormalize
    ungroup()

  growth_loo <- growth %>% filter(industry != drop_ind)

  bartik_loo <- growth_loo %>%
    inner_join(shares_loo %>% select(state_fips, industry, share_loo),
               by = c("state_fips", "industry")) %>%
    group_by(state_fips, year) %>%
    summarise(bartik_shock_loo = sum(share_loo * g_loo, na.rm = TRUE), .groups = "drop")

  panel_loo <- panel %>%
    select(-bartik_shock) %>%
    left_join(bartik_loo, by = c("state_fips", "year")) %>%
    filter(!is.na(bartik_shock_loo))

  loo_mod <- feols(timeliness_14d ~ 1 | state_fips + year | log_claims ~ bartik_shock_loo,
                   data = panel_loo, cluster = ~state_fips)

  loo_results[[drop_ind]] <- tibble(
    dropped = drop_ind,
    coef = coef(loo_mod)["fit_log_claims"],
    se = se(loo_mod)["fit_log_claims"],
    f_stat = fitstat(loo_mod, "ivf")$ivf1$stat,
    n_obs = nrow(panel_loo)
  )
  cat(sprintf("  Drop %s: coef=%.3f (%.3f), F=%.1f\n",
              drop_ind, coef(loo_mod)["fit_log_claims"],
              se(loo_mod)["fit_log_claims"],
              fitstat(loo_mod, "ivf")$ivf1$stat))
}

loo_df <- bind_rows(loo_results)
write_csv(loo_df, "../data/loo_results.csv")

# ============================================================================
# 3. Placebo Test — Pre-recession period only (2006-2007)
# ============================================================================
cat("\n=== Placebo: Pre-recession (2006-2007) ===\n")

panel_pre <- panel %>% filter(year <= 2007)
if (nrow(panel_pre) >= 50) {
  placebo <- feols(timeliness_14d ~ bartik_shock | state_fips + year,
                   data = panel_pre, cluster = ~state_fips)
  cat("Placebo (pre-recession reduced form):\n")
  print(summary(placebo))
} else {
  cat("  Insufficient pre-recession observations for placebo.\n")
  placebo <- NULL
}

# ============================================================================
# 4. Alternative Timeliness Thresholds (7-day, 21-day)
# ============================================================================
cat("\n=== Alternative Timeliness Outcomes ===\n")

alt_7d <- feols(timeliness_7d ~ 1 | state_fips + year | log_claims ~ bartik_shock,
                data = panel, cluster = ~state_fips)
alt_21d <- feols(timeliness_21d ~ 1 | state_fips + year | log_claims ~ bartik_shock,
                 data = panel, cluster = ~state_fips)

cat("7-day timeliness:\n")
print(summary(alt_7d))
cat("21-day timeliness:\n")
print(summary(alt_21d))

# ============================================================================
# 5. Wild Cluster Bootstrap (51 clusters)
# ============================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

load("../data/models.RData")

wcb <- tryCatch({
  boot_iv1 <- boottest(iv1, param = "fit_log_claims", B = 999,
                       clustid = "state_fips", type = "webb")
  list(
    ci_lower = boot_iv1$conf_int[1],
    ci_upper = boot_iv1$conf_int[2],
    p_value = boot_iv1$p_val
  )
}, error = function(e) {
  cat("  WCB error:", e$message, "\n")
  NULL
})

if (!is.null(wcb)) {
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f], p=%.4f\n",
              wcb$ci_lower, wcb$ci_upper, wcb$p_value))
}

# ============================================================================
# Save robustness objects
# ============================================================================
save(loo_df, placebo, alt_7d, alt_21d, wcb, rotemberg,
     file = "../data/robustness.RData")
cat("\n=== Robustness checks complete ===\n")
