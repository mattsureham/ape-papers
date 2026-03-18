## 04_robustness.R — Robustness checks for YEI RDD
## apep_0723: EU Youth Employment Initiative RDD

source("00_packages.R")

df      <- readRDS("../data/analysis_clean.rds")
models  <- readRDS("../data/models.rds")
rdd_neet <- models$rdd_neet
bw_main  <- models$bw_main

cat(sprintf("Analysis sample: %d NUTS2 regions\n", nrow(df)))
cat(sprintf("Main bandwidth: %.2f pp\n", bw_main))

# ============================================================
# HELPER
# ============================================================

safe_rdd <- function(y, x, cluster = NULL, bw = NULL, ...) {
  args <- list(y = y, x = x, c = 0, kernel = "triangular", cluster = cluster)
  if (!is.null(bw)) {
    args$h <- bw
    args$b <- bw * 2
    args$bwselect <- "manual"
  } else {
    args$bwselect <- "mserd"
  }
  args <- c(args, list(...))
  tryCatch(do.call(rdrobust::rdrobust, args), error = function(e) {
    cat(sprintf("  rdrobust failed: %s\n", e$message))
    NULL
  })
}

extract_row <- function(rdd_obj, label) {
  if (is.null(rdd_obj)) return(data.frame(spec=label, coef=NA, se=NA, pval=NA, bw=NA, n=NA))
  data.frame(
    spec = label,
    coef = as.numeric(rdd_obj$coef["Conventional"]),
    se   = as.numeric(rdd_obj$se["Conventional"]),
    pval = as.numeric(rdd_obj$pv["Conventional"]),
    bw   = as.numeric(rdd_obj$bws["h", "left"]),
    n    = as.numeric(rdd_obj$N_h["left"]) + as.numeric(rdd_obj$N_h["right"]),
    stringsAsFactors = FALSE
  )
}

# ============================================================
# 1. BANDWIDTH SENSITIVITY
# ============================================================

cat("\n=== BANDWIDTH SENSITIVITY ===\n")

bw_grid <- c(5, 7, 10, bw_main, bw_main * 1.5, 20, 25)
bw_grid <- sort(unique(round(bw_grid, 2)))

bw_results <- list()
for (bw_val in bw_grid) {
  df_bw <- df %>% filter(abs(rv) <= bw_val)
  cat(sprintf("  BW = %.1f pp: %d regions\n", bw_val, nrow(df_bw)))
  if (nrow(df_bw) < 10) next

  rdd_bw <- safe_rdd(
    y = df_bw$d_neet,
    x = df_bw$rv,
    cluster = df_bw$country,
    bw = bw_val
  )
  row <- extract_row(rdd_bw, sprintf("BW = %.1f", bw_val))
  row$n_obs <- nrow(df_bw)
  bw_results[[as.character(bw_val)]] <- row
}

bw_df <- bind_rows(bw_results)
cat("\nBandwidth sensitivity results:\n")
print(bw_df)

# ============================================================
# 2. McCRARY DENSITY TEST (rddensity)
# ============================================================

cat("\n=== McCRARY DENSITY TEST ===\n")

mccrary <- tryCatch({
  rddensity::rddensity(X = df$rv, c = 0)
}, error = function(e) {
  cat(sprintf("WARNING: rddensity failed: %s\n", e$message))
  NULL
})

if (!is.null(mccrary)) {
  cat("McCrary density test:\n")
  print(summary(mccrary))
  mccrary_tstat <- mccrary$test$t_jk
  mccrary_pval  <- mccrary$test$p_jk
  cat(sprintf("T-statistic: %.4f | p-value: %.4f\n",
              as.numeric(mccrary_tstat), as.numeric(mccrary_pval)))
} else {
  mccrary_tstat <- NA
  mccrary_pval  <- NA
}

# ============================================================
# 3. PRE-PERIOD BALANCE AT THRESHOLD
#    Test: 2012 NEET level, employment rate level at threshold
# ============================================================

cat("\n=== PRE-PERIOD BALANCE ===\n")

# Balance test: is there a discontinuity in pre-YEI outcome levels?
# If no, this supports the RDD exclusion restriction

# Balance in pre-period NEET level (2012)
df_bal <- df %>% filter(!is.na(neet_pre))

rdd_balance_neet <- safe_rdd(
  y = df_bal$neet_pre,
  x = df_bal$rv,
  cluster = df_bal$country
)

bal_neet <- extract_row(rdd_balance_neet, "Pre-period NEET level (2012)")
cat("Balance test — pre-period NEET level:\n"); print(bal_neet)

# Balance in pre-period employment rate
df_bal_emp <- df %>% filter(!is.na(emp_pre))

rdd_balance_emp <- safe_rdd(
  y = df_bal_emp$emp_pre,
  x = df_bal_emp$rv,
  cluster = df_bal_emp$country
)

bal_emp <- extract_row(rdd_balance_emp, "Pre-period employment rate (2010-2012)")
cat("Balance test — pre-period employment rate:\n"); print(bal_emp)

balance_results <- bind_rows(bal_neet, bal_emp)

# ============================================================
# 4. PLACEBO CUTOFFS: 20% and 30%
# ============================================================

cat("\n=== PLACEBO CUTOFFS ===\n")

# Placebo at 20%: running variable centered at 20% (rv_20 = unemp_2012 - 20)
df_pl20 <- df %>%
  mutate(rv_20 = unemp_2012 - 20) %>%
  filter(unemp_2012 < 25)  # exclude regions above true threshold

rdd_placebo_20 <- safe_rdd(
  y = df_pl20$d_neet,
  x = df_pl20$rv_20,
  cluster = df_pl20$country
)

placebo_20 <- extract_row(rdd_placebo_20, "Placebo cutoff: 20%")
cat("Placebo at 20%:\n"); print(placebo_20)

# Placebo at 30%: running variable centered at 30% (rv_30 = unemp_2012 - 30)
df_pl30 <- df %>%
  mutate(rv_30 = unemp_2012 - 30) %>%
  filter(unemp_2012 >= 25)  # restrict to treated side only

rdd_placebo_30 <- safe_rdd(
  y = df_pl30$d_neet,
  x = df_pl30$rv_30,
  cluster = df_pl30$country
)

placebo_30 <- extract_row(rdd_placebo_30, "Placebo cutoff: 30%")
cat("Placebo at 30%:\n"); print(placebo_30)

placebo_results <- bind_rows(placebo_20, placebo_30)

# ============================================================
# 5. DONUT RDD — EXCLUDING REGIONS WITHIN 1pp OF THRESHOLD
# ============================================================

cat("\n=== DONUT RDD ===\n")

df_donut <- df %>% filter(abs(rv) > 1)
cat(sprintf("Donut sample (|rv| > 1): %d regions\n", nrow(df_donut)))

rdd_donut <- safe_rdd(
  y = df_donut$d_neet,
  x = df_donut$rv,
  cluster = df_donut$country
)

donut_result <- extract_row(rdd_donut, "Donut RDD (exclude |rv| <= 1pp)")
cat("Donut RDD:\n"); print(donut_result)

# ============================================================
# 6. ALTERNATIVE KERNEL: Uniform
# ============================================================

cat("\n=== UNIFORM KERNEL ===\n")

rdd_uniform <- safe_rdd(
  y = df$d_neet,
  x = df$rv,
  cluster = df$country
)
# Override kernel via separate call
rdd_uniform <- tryCatch({
  rdrobust::rdrobust(
    y = df$d_neet,
    x = df$rv,
    c = 0,
    kernel = "uniform",
    bwselect = "mserd",
    cluster = df$country
  )
}, error = function(e) NULL)

uniform_result <- extract_row(rdd_uniform, "Uniform kernel")
cat("Uniform kernel:\n"); print(uniform_result)

# ============================================================
# 7. COMPILE ALL ROBUSTNESS RESULTS
# ============================================================

# Main estimate row for comparison
main_row <- data.frame(
  spec = "Main (triangular, MSE-optimal BW)",
  coef = as.numeric(rdd_neet$coef["Conventional"]),
  se   = as.numeric(rdd_neet$se["Conventional"]),
  pval = as.numeric(rdd_neet$pv["Conventional"]),
  bw   = as.numeric(rdd_neet$bws["h", "left"]),
  n    = as.numeric(rdd_neet$N_h["left"]) + as.numeric(rdd_neet$N_h["right"]),
  n_obs = nrow(df),
  stringsAsFactors = FALSE
)

all_robustness <- bind_rows(
  main_row,
  bw_df %>% mutate(n_obs = coalesce(n_obs, n)),
  donut_result %>% mutate(n_obs = nrow(df_donut)),
  uniform_result %>% mutate(n_obs = nrow(df))
)

saveRDS(list(
  bw_results    = bw_df,
  balance       = balance_results,
  placebo       = placebo_results,
  donut         = donut_result,
  uniform       = uniform_result,
  all_robustness = all_robustness,
  mccrary_tstat = as.numeric(mccrary_tstat),
  mccrary_pval  = as.numeric(mccrary_pval),
  mccrary       = mccrary
), "../data/robustness.rds")

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat("All robustness results:\n")
print(all_robustness)
cat("\nBalance tests:\n")
print(balance_results)
cat("\nPlacebo cutoffs:\n")
print(placebo_results)
cat(sprintf("\nMcCrary density test: T=%.4f, p=%.4f\n",
            as.numeric(mccrary_tstat), as.numeric(mccrary_pval)))

cat("\nRobustness checks complete.\n")
