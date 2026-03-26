# 04_robustness.R — Robustness checks for apep_0974

source("00_packages.R")

panel <- arrow::read_parquet("../data/panel.parquet")
results <- readRDS("../data/main_results.rds")

cat("Panel loaded: ", nrow(panel), " obs\n")

# =============================================================================
# 1. Pre-trend event study (key diagnostic)
# =============================================================================
cat("\n=== Pre-trend Analysis ===\n")

# Event study coefficients from CS-DiD (already computed in main_analysis)
es <- results$agg_dynamic
pre_coefs <- data.frame(
  event_time = es$egt[es$egt < 0],
  att = es$att.egt[es$egt < 0],
  se = es$se.egt[es$egt < 0]
)
pre_coefs$sig <- abs(pre_coefs$att / pre_coefs$se) > 1.96

n_sig_pre <- sum(pre_coefs$sig, na.rm = TRUE)
cat(sprintf("Pre-treatment event-study coefficients: %d of %d significant at 5%%\n",
            n_sig_pre, nrow(pre_coefs)))

if (n_sig_pre > nrow(pre_coefs) * 0.2) {
  warning("More than 20% of pre-treatment coefficients are significant — parallel trends concern")
}

# =============================================================================
# 2. Randomization inference (permute treatment assignment)
# =============================================================================
cat("\n=== Randomization Inference ===\n")

# Permute which states are "early terminators" 999 times
set.seed(42)
n_perms <- 999
n_early <- sum(panel$early_terminator[!duplicated(panel$state)])
all_states <- unique(panel$state)

ri_coefs_share <- numeric(n_perms)
ri_coefs_ed <- numeric(n_perms)

for (p in 1:n_perms) {
  fake_early <- sample(all_states, n_early)
  panel_perm <- panel |>
    mutate(
      fake_early = state %in% fake_early,
      fake_post = as.integer(fake_early & CLAIM_FROM_MONTH >= ea_end_month)
    )
  mod_share <- feols(ed_share ~ fake_post | state + year_month,
                      data = panel_perm, cluster = ~state)
  mod_ed <- feols(log_ed_claims ~ fake_post | state + year_month,
                   data = panel_perm, cluster = ~state)
  ri_coefs_share[p] <- coef(mod_share)["fake_post"]
  ri_coefs_ed[p] <- coef(mod_ed)["fake_post"]
}

actual_share <- coef(results$twfe_share)["post_ea"]
actual_ed <- coef(results$twfe_ed)["post_ea"]

ri_p_share <- mean(abs(ri_coefs_share) >= abs(actual_share))
ri_p_ed <- mean(abs(ri_coefs_ed) >= abs(actual_ed))

cat(sprintf("RI p-value (ED share): %.3f\n", ri_p_share))
cat(sprintf("RI p-value (log ED): %.3f\n", ri_p_ed))

boot_share <- list(p_val = ri_p_share,
                    conf_int = quantile(ri_coefs_share, c(0.025, 0.975)))
boot_ed <- list(p_val = ri_p_ed,
                 conf_int = quantile(ri_coefs_ed, c(0.025, 0.975)))

# =============================================================================
# 3. Excluding COVID peak (March-June 2020)
# =============================================================================
cat("\n=== Excluding COVID Peak ===\n")

panel_nocovid <- panel |>
  filter(!(CLAIM_FROM_MONTH >= "2020-03" & CLAIM_FROM_MONTH <= "2020-06"))

twfe_nocovid <- feols(ed_share ~ post_ea | state + year_month,
                       data = panel_nocovid, cluster = ~state)
cat("TWFE ED share (excl. COVID peak):\n")
print(summary(twfe_nocovid))

# =============================================================================
# 4. State-specific linear trends
# =============================================================================
cat("\n=== State-Specific Linear Trends ===\n")

twfe_trends <- feols(ed_share ~ post_ea + i(state, year_month) | state + year_month,
                      data = panel, cluster = ~state)
cat("TWFE ED share (state trends):\n")
cat(sprintf("  Coefficient: %.5f (SE: %.5f)\n",
            coef(twfe_trends)["post_ea"], se(twfe_trends)["post_ea"]))

# =============================================================================
# 5. Leave-one-out: drop each early-terminating state
# =============================================================================
cat("\n=== Leave-One-Out ===\n")

early_states <- unique(panel$state[panel$early_terminator])
loo_results <- data.frame(
  dropped_state = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (s in early_states) {
  panel_loo <- panel |> filter(state != s)
  mod <- feols(ed_share ~ post_ea | state + year_month,
               data = panel_loo, cluster = ~state)
  loo_results <- rbind(loo_results, data.frame(
    dropped_state = s,
    coef = coef(mod)["post_ea"],
    se = se(mod)["post_ea"]
  ))
}

cat("Leave-one-out coefficients:\n")
print(loo_results)
cat(sprintf("Range: [%.5f, %.5f]\n", min(loo_results$coef), max(loo_results$coef)))

# =============================================================================
# 6. Placebo: behavioral health codes (should NOT be affected by SNAP EA)
# =============================================================================
cat("\n=== Placebo: Behavioral Health ===\n")

# Load behavioral health claims from T-MSIS
ds <- arrow::open_dataset("../../../../data/medicaid_provider_spending/tmsis.parquet")
bh_codes <- c("H0015", "H0020", "H0004", "90834", "90837")

bh_claims <- ds |>
  filter(HCPCS_CODE %in% bh_codes) |>
  select(BILLING_PROVIDER_NPI_NUM, HCPCS_CODE, CLAIM_FROM_MONTH,
         TOTAL_CLAIMS) |>
  collect()

npi_state <- arrow::read_parquet("../data/npi_state.parquet") |>
  mutate(npi = as.character(npi))
ea_dates <- arrow::read_parquet("../data/snap_ea_dates.parquet")

bh_geo <- bh_claims |>
  left_join(npi_state, by = c("BILLING_PROVIDER_NPI_NUM" = "npi")) |>
  filter(!is.na(state), state %in% c(state.abb, "DC"))

bh_panel <- bh_geo |>
  group_by(state, CLAIM_FROM_MONTH) |>
  summarize(bh_claims = sum(TOTAL_CLAIMS, na.rm = TRUE), .groups = "drop") |>
  mutate(
    log_bh = log(bh_claims + 1),
    year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4)),
    month = as.integer(substr(CLAIM_FROM_MONTH, 6, 7)),
    year_month = year * 12 + month
  ) |>
  left_join(ea_dates, by = "state") |>
  mutate(post_ea = as.integer(CLAIM_FROM_MONTH >= ea_end_month))

placebo_bh <- feols(log_bh ~ post_ea | state + year_month,
                     data = bh_panel, cluster = ~state)
cat("Placebo (behavioral health):\n")
print(summary(placebo_bh))

# =============================================================================
# 7. Save robustness results
# =============================================================================
robust <- list(
  boot_share = boot_share,
  boot_ed = boot_ed,
  twfe_nocovid = twfe_nocovid,
  twfe_trends = twfe_trends,
  loo_results = loo_results,
  placebo_bh = placebo_bh,
  pre_coefs = pre_coefs
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
