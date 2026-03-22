## 04_robustness.R — Robustness checks for bunching analysis
## apep_0731: Nonprofit bunching at state audit thresholds

source("00_packages.R")

data_dir <- "../data"

bmf_clean <- fread(file.path(data_dir, "bmf_clean.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ══════════════════════════════════════════════════════════════════════════
## ROBUSTNESS 1: Placebo thresholds at round numbers
## ══════════════════════════════════════════════════════════════════════════

## Test for bunching at round numbers where there is NO audit threshold
## If bunching is due to round-number preference (not audit avoidance),
## we'd see similar patterns at $400K, $600K, etc.

no_audit_states_list <- c("AK", "AZ", "DE", "FL", "IA", "ID", "IN", "LA",
                          "MT", "ND", "NE", "NV", "SD", "TX", "VT", "WA", "WY")
bin_width <- 5000

placebo_thresholds <- c(300000, 400000, 600000, 700000, 800000, 900000, 1000000)
placebo_results <- list()

for (pt in placebo_thresholds) {
  w_low <- pt * 0.5
  w_high <- pt * 1.5

  ## In no-audit states only (pure placebo)
  df_p <- bmf_clean[STATE %in% no_audit_states_list &
                    revenue >= w_low & revenue <= w_high]
  if (nrow(df_p) < 100) next

  bw_p <- max(round(pt / 100), 1000)
  df_p[, bin := floor(revenue / bw_p) * bw_p]
  bins_p <- df_p[, .(count = .N), by = bin][order(bin)]
  bins_p[, bin_centered := bin - pt]

  ex_low_p <- pt * 0.95
  ex_high_p <- pt * 1.03
  bins_p[, excluded := (bin >= ex_low_p & bin <= ex_high_p)]

  fit_p <- bins_p[excluded == FALSE]
  if (nrow(fit_p) < 8) next

  tryCatch({
    poly_p <- lm(count ~ poly(bin_centered, 5, raw = TRUE), data = fit_p)
    bins_p[, cf := predict(poly_p, newdata = .SD)]

    excess_p <- bins_p[bin >= (pt - pt * 0.05) & bin < pt]
    em_p <- sum(excess_p$count) - sum(excess_p$cf)
    avg_cf_p <- mean(bins_p[excluded == FALSE]$cf)
    b_p <- em_p / max(avg_cf_p, 1)

    placebo_results[[as.character(pt)]] <- data.table(
      threshold = pt,
      excess_mass = round(em_p, 1),
      bunching_ratio = round(b_p, 3),
      type = "placebo"
    )
  }, error = function(e) NULL)
}

placebo_dt <- rbindlist(placebo_results)
cat("Placebo bunching at round numbers (no-audit states):\n")
print(placebo_dt)

## ══════════════════════════════════════════════════════════════════════════
## ROBUSTNESS 2: Polynomial order sensitivity
## ══════════════════════════════════════════════════════════════════════════

## Re-estimate $500K bunching with polynomial orders 5, 6, 7, 8, 9
states_500k <- bmf_clean[threshold == 500000 & has_audit_mandate == TRUE,
                         unique(STATE)]
threshold_val <- 500000
window_low <- 250000
window_high <- 750000

df_500k <- bmf_clean[STATE %in% states_500k &
                     revenue >= window_low &
                     revenue <= window_high]
df_500k[, bin := floor(revenue / bin_width) * bin_width]
bin_counts <- df_500k[, .(count = .N), by = bin][order(bin)]
bin_counts[, bin_centered := bin - threshold_val]

exclude_low <- threshold_val - 25000
exclude_high <- threshold_val + 15000
bin_counts[, excluded := (bin >= exclude_low & bin <= exclude_high)]

poly_results <- list()
for (p_order in 5:9) {
  fit_data <- bin_counts[excluded == FALSE]
  tryCatch({
    poly_fit <- lm(count ~ poly(bin_centered, p_order, raw = TRUE), data = fit_data)
    bin_counts[, cf_temp := predict(poly_fit, newdata = .SD)]

    excess <- bin_counts[bin >= (threshold_val - 25000) & bin < threshold_val]
    em <- sum(excess$count) - sum(excess$cf_temp)
    avg_cf <- mean(bin_counts[excluded == FALSE]$cf_temp)
    b <- em / avg_cf

    poly_results[[as.character(p_order)]] <- data.table(
      poly_order = p_order,
      excess_mass = round(em, 1),
      bunching_ratio = round(b, 3)
    )
  }, error = function(e) NULL)
}

poly_dt <- rbindlist(poly_results)
cat("\nPolynomial order sensitivity ($500K threshold):\n")
print(poly_dt)

## ══════════════════════════════════════════════════════════════════════════
## ROBUSTNESS 3: Donut specification (exclude thin band around threshold)
## ══════════════════════════════════════════════════════════════════════════

## Vary the excluded region width
donut_results <- list()
donut_widths <- c(10000, 15000, 20000, 25000, 30000, 40000)

for (dw in donut_widths) {
  ex_l <- threshold_val - dw
  ex_h <- threshold_val + round(dw * 0.6)
  bin_counts[, exc_temp := (bin >= ex_l & bin <= ex_h)]

  fit_d <- bin_counts[exc_temp == FALSE]
  if (nrow(fit_d) < 8) next

  tryCatch({
    poly_d <- lm(count ~ poly(bin_centered, 7, raw = TRUE), data = fit_d)
    bin_counts[, cf_d := predict(poly_d, newdata = .SD)]

    excess_d <- bin_counts[bin >= (threshold_val - dw) & bin < threshold_val]
    em_d <- sum(excess_d$count) - sum(excess_d$cf_d)
    avg_cf_d <- mean(bin_counts[exc_temp == FALSE]$cf_d)
    b_d <- em_d / max(avg_cf_d, 1)

    donut_results[[as.character(dw)]] <- data.table(
      donut_width = dw,
      excess_mass = round(em_d, 1),
      bunching_ratio = round(b_d, 3)
    )
  }, error = function(e) NULL)
}

donut_dt <- rbindlist(donut_results)
cat("\nDonut specification sensitivity:\n")
print(donut_dt)

## ══════════════════════════════════════════════════════════════════════════
## ROBUSTNESS 4: By NTEE category
## ══════════════════════════════════════════════════════════════════════════

## Do certain nonprofit types bunch more?
if ("NTEE_CD" %in% names(bmf_clean)) {
  bmf_clean[, ntee_major := substr(NTEE_CD, 1, 1)]

  ntee_results <- list()
  for (nt in unique(bmf_clean[STATE %in% states_500k & !is.na(ntee_major), ntee_major])) {
    df_nt <- bmf_clean[STATE %in% states_500k & ntee_major == nt &
                       revenue >= window_low & revenue <= window_high]
    if (nrow(df_nt) < 100) next

    df_nt[, bin := floor(revenue / bin_width) * bin_width]
    bins_nt <- df_nt[, .(count = .N), by = bin][order(bin)]
    bins_nt[, bin_centered := bin - threshold_val]
    bins_nt[, excluded := (bin >= exclude_low & bin <= exclude_high)]

    fit_nt <- bins_nt[excluded == FALSE]
    if (nrow(fit_nt) < 8) next

    tryCatch({
      poly_nt <- lm(count ~ poly(bin_centered, 5, raw = TRUE), data = fit_nt)
      bins_nt[, cf := predict(poly_nt, newdata = .SD)]

      excess_nt <- bins_nt[bin >= (threshold_val - 25000) & bin < threshold_val]
      em_nt <- sum(excess_nt$count) - sum(excess_nt$cf)
      avg_cf_nt <- mean(bins_nt[excluded == FALSE]$cf)
      b_nt <- em_nt / max(avg_cf_nt, 1)

      ntee_results[[nt]] <- data.table(
        ntee_major = nt,
        n_orgs = nrow(df_nt),
        excess_mass = round(em_nt, 1),
        bunching_ratio = round(b_nt, 3)
      )
    }, error = function(e) NULL)
  }

  ntee_dt <- rbindlist(ntee_results)
  ntee_dt <- ntee_dt[order(-bunching_ratio)]
  cat("\nBunching by NTEE major category:\n")
  print(ntee_dt)
}

## ── Save robustness results ────────────────────────────────────────────────
robustness <- list(
  placebo = placebo_dt,
  polynomial = poly_dt,
  donut = donut_dt,
  ntee = if (exists("ntee_dt")) ntee_dt else NULL
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
cat("Done.\n")
