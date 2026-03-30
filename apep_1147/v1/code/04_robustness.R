## ── 04_robustness.R ───────────────────────────────────────────────────────
## Robustness checks: placebos, wild cluster bootstrap, HonestDiD
## ───────────────────────────────────────────────────────────────────────────

source("00_packages.R")

panel <- readRDS("../data/panel_all.rds")
results <- readRDS("../data/main_results.rds")

## ══════════════════════════════════════════════════════════════════════════
## 1. Wild cluster bootstrap (address few treated clusters)
## ══════════════════════════════════════════════════════════════════════════

cat("=== Wild Cluster Bootstrap ===\n")

# Re-run main DDD for WCB
panel$ddd <- as.integer(panel$treated_state & panel$post == 1 & panel$black == 1)

m_ddd <- feols(
  log_earn ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel,
  cluster = ~state_fips
)

# Wild cluster bootstrap p-value for DDD coefficient
wcb_result <- tryCatch({
  boot_ddd <- boottest(
    m_ddd,
    param = "ddd",
    clustid = ~state_fips,
    B = 9999,
    type = "webb"
  )
  cat(sprintf("WCB p-value (DDD): %.4f\n", boot_ddd$p_val))
  cat(sprintf("WCB CI: [%.4f, %.4f]\n", boot_ddd$conf_int[1], boot_ddd$conf_int[2]))
  boot_ddd
}, error = function(e) {
  cat(sprintf("WCB error: %s\n", e$message))
  NULL
})

## ══════════════════════════════════════════════════════════════════════════
## 2. Placebo: False RTW at t-12 quarters (3 years before actual)
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Placebo: False RTW at t-12 ===\n")

panel_placebo <- panel %>%
  mutate(
    placebo_first_treat = ifelse(first_treat > 0, first_treat - 12, 0),
    placebo_post = case_when(
      first_treat == 0 ~ 0L,
      time >= placebo_first_treat & time < first_treat ~ 1L,
      TRUE ~ 0L
    )
  ) %>%
  # Restrict to pre-treatment period only
  filter(first_treat == 0 | time < first_treat)

panel_placebo$placebo_ddd <- as.integer(
  panel_placebo$treated_state & panel_placebo$placebo_post == 1 & panel_placebo$black == 1
)

m_placebo <- feols(
  log_earn ~ placebo_ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel_placebo,
  cluster = ~state_fips
)

cat("Placebo DDD coefficient (should be ~0):\n")
print(coeftable(m_placebo))

## ══════════════════════════════════════════════════════════════════════════
## 3. Exclude one treated state at a time (leave-one-out)
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Leave-one-out robustness ===\n")

treated_fips <- c("18", "26", "55", "54")
state_names <- c("Indiana", "Michigan", "Wisconsin", "West Virginia")

loo_results <- data.frame(
  excluded = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (i in seq_along(treated_fips)) {
  panel_loo <- panel %>%
    filter(state_fips != treated_fips[i])

  panel_loo$ddd <- as.integer(panel_loo$treated_state & panel_loo$post == 1 & panel_loo$black == 1)

  m_loo <- feols(
    log_earn ~ ddd |
      county_fips^race + time^race + state_fips^time,
    data = panel_loo,
    cluster = ~state_fips
  )

  ct <- coeftable(m_loo)
  ddd_row <- grep("ddd", rownames(ct))
  if (length(ddd_row) > 0) {
    loo_results <- rbind(loo_results, data.frame(
      excluded = state_names[i],
      coef = ct[ddd_row, 1],
      se = ct[ddd_row, 2],
      stringsAsFactors = FALSE
    ))
    cat(sprintf("  Excluding %s: DDD = %.4f (%.4f)\n",
                state_names[i], ct[ddd_row, 1], ct[ddd_row, 2]))
  }
}

## ══════════════════════════════════════════════════════════════════════════
## 4. HonestDiD bounds (for CS DiD event study)
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== HonestDiD Sensitivity ===\n")

honest_results <- tryCatch({
  if (!is.null(results$es_black)) {
    # Extract event study coefficients for HonestDiD
    es <- results$es_black
    # Need pre-period coefficients and post-period coefficients
    pre_idx <- which(es$egt < 0)
    post_idx <- which(es$egt >= 0)

    if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
      betahat <- es$att.egt
      sigma <- es$se.egt^2 * diag(length(es$egt))  # Simplified: diagonal variance

      # HonestDiD relative magnitudes approach
      delta_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mbarvec = seq(0, 2, by = 0.5)
      )
      cat("HonestDiD relative magnitudes bounds:\n")
      print(delta_rm)
      delta_rm
    } else {
      cat("Insufficient pre/post periods for HonestDiD.\n")
      NULL
    }
  } else {
    cat("No CS event study available for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat(sprintf("HonestDiD error: %s\n", e$message))
  NULL
})

## ── Save robustness results ──────────────────────────────────────────────
rob_results <- list(
  wcb = if (exists("wcb_result")) wcb_result else NULL,
  placebo = m_placebo,
  loo = loo_results,
  honest = if (exists("honest_results")) honest_results else NULL
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
