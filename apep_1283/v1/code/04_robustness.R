# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

source("00_packages.R")

df_state  <- readRDS("../data/analysis_state.rds")
df_mfg    <- readRDS("../data/analysis_mfg.rds")
df_sector <- readRDS("../data/analysis_sector.rds")

df_state <- df_state %>%
  mutate(
    state_id = as.integer(factor(state_abbr)),
    post_repeal = as.integer(treated_state & period >= first_treat_period)
  )

# ---------------------------------------------------------------------------
# 1. Manufacturing placebo (no PW coverage → null expected)
# ---------------------------------------------------------------------------
cat("=== Placebo: Manufacturing B/W Ratio ===\n")

df_mfg <- df_mfg %>%
  mutate(
    state_id = as.integer(factor(state_abbr)),
    post_repeal = as.integer(treated_state & period >= first_treat_period)
  )

placebo_mfg <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_mfg,
  cluster = ~state_id
)
cat("Manufacturing placebo:\n")
summary(placebo_mfg)

# ---------------------------------------------------------------------------
# 2. Drop concurrent RTW states (WV, KY)
# ---------------------------------------------------------------------------
cat("\n=== Sensitivity: Drop WV and KY (concurrent RTW) ===\n")

df_no_rtw <- df_state %>%
  filter(!(state_abbr %in% c("wv", "ky")))

twfe_no_rtw <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_no_rtw,
  cluster = ~state_id
)
cat("Without WV/KY:\n")
summary(twfe_no_rtw)

# ---------------------------------------------------------------------------
# 3. Leave-one-out: Drop each treated state
# ---------------------------------------------------------------------------
cat("\n=== Leave-One-Out ===\n")

treated_states <- c("in", "wv", "ky", "ar", "wi", "mi")
loo_results <- list()

for (drop_st in treated_states) {
  df_loo <- df_state %>% filter(state_abbr != drop_st)
  df_loo <- df_loo %>% mutate(state_id = as.integer(factor(state_abbr)))

  fit_loo <- feols(
    bw_ratio ~ post_repeal | state_id + period,
    data = df_loo,
    cluster = ~state_id
  )

  loo_results[[drop_st]] <- tibble(
    dropped = drop_st,
    coef = coef(fit_loo)["post_repeal"],
    se = se(fit_loo)["post_repeal"],
    pval = pvalue(fit_loo)["post_repeal"]
  )
  cat("  Drop", toupper(drop_st), ": coef =", round(coef(fit_loo)["post_repeal"], 4),
      "se =", round(se(fit_loo)["post_repeal"], 4), "\n")
}

loo_df <- bind_rows(loo_results)

# ---------------------------------------------------------------------------
# 4. Wild cluster bootstrap (few-cluster inference)
# ---------------------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")

twfe_main <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_state,
  cluster = ~state_id
)

tryCatch({
  boot_result <- boottest(
    twfe_main,
    param = "post_repeal",
    clustid = "state_id",
    B = 9999,
    type = "webb"
  )
  cat("Wild cluster bootstrap:\n")
  # Extract p-value and CI safely
  boot_summ <- summary(boot_result)
  print(boot_summ)
  tryCatch({
    boot_pval <- boot_summ$p.value
    if (is.null(boot_pval) || is.na(boot_pval)) {
      boot_pval <- boot_result$p_val
    }
    boot_ci <- c(boot_summ$conf.low, boot_summ$conf.high)
    if (any(is.null(boot_ci))) boot_ci <- c(NA, NA)
  }, error = function(e2) {
    boot_pval <<- NA
    boot_ci <<- c(NA, NA)
  })
}, error = function(e) {
  cat("Wild bootstrap warning:", e$message, "\n")
  boot_pval <<- NA
  boot_ci <<- c(NA, NA)
})

# ---------------------------------------------------------------------------
# 5. Alternative outcome: log earnings gap
# ---------------------------------------------------------------------------
cat("\n=== Alternative Outcome: Log B/W Gap ===\n")

twfe_ln <- feols(
  ln_bw_gap ~ post_repeal | state_id + period,
  data = df_state,
  cluster = ~state_id
)
cat("Log B/W gap:\n")
summary(twfe_ln)

# ---------------------------------------------------------------------------
# 6. Pre-trend test (event study coefficients)
# ---------------------------------------------------------------------------
cat("\n=== Pre-trend F-test ===\n")

df_state <- df_state %>%
  mutate(
    first_treat_sa = ifelse(first_treat_period == 0, 10000L, first_treat_period)
  )

sa_es <- feols(
  bw_ratio ~ sunab(first_treat_sa, period) | state_id + period,
  data = df_state,
  cluster = ~state_id
)

# Extract pre-treatment coefficients
es_coefs <- coeftable(sa_es)
pre_coefs <- es_coefs[grep("^period::-", rownames(es_coefs)), ]
if (nrow(pre_coefs) > 0) {
  f_stat <- sum((pre_coefs[, 1] / pre_coefs[, 2])^2) / nrow(pre_coefs)
  f_pval <- pf(f_stat, nrow(pre_coefs), Inf, lower.tail = FALSE)
  cat("Joint F-test on pre-treatment coefficients:\n")
  cat("  F =", round(f_stat, 3), ", p =", round(f_pval, 3), "\n")
  cat("  (Null: all pre-treatment effects are zero)\n")
}

# ---------------------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------------------
rob_results <- list(
  placebo_mfg = placebo_mfg,
  twfe_no_rtw = twfe_no_rtw,
  loo_df = loo_df,
  twfe_ln = twfe_ln,
  sa_es = sa_es,
  boot_pval = if(exists("boot_pval")) boot_pval else NA,
  boot_ci = if(exists("boot_ci")) boot_ci else c(NA, NA)
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nAll robustness results saved.\n")
