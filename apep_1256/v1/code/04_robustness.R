## ============================================================================
## 04_robustness.R — apep_1256
## Robustness checks: bandwidth sensitivity, placebos, alternative specs
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
muni  <- fread(paste0(data_dir, "muni_characteristics.csv"))

# Reconstruct key variables
panel[, margin_hd := ifelse(high_donor == 1, margin, -margin)]
panel[, treat := as.integer(margin_hd > 0)]

# Cross-section for rdrobust
pre_data <- panel[post == 0, .(
  disc_share_n_pre = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_pre = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_pre      = sum(n_total)
), by = .(codmpio, margin_hd, treat, high_donor, winner_donor_share)]

post_data <- panel[post == 1, .(
  disc_share_n_post = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_post = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_post      = sum(n_total)
), by = codmpio]

cs_data <- merge(pre_data, post_data, by = "codmpio")
cs_data[, delta_disc_n := disc_share_n_post - disc_share_n_pre]
cs_data[, delta_disc_v := disc_share_v_post - disc_share_v_pre]

## --------------------------------------------------------------------------
## 1. BANDWIDTH SENSITIVITY (Panel DiD)
## --------------------------------------------------------------------------
cat("=== Bandwidth Sensitivity ===\n")

bw_grid <- c(0.05, 0.075, 0.10, 0.125, 0.15, 0.20, 0.30)
bw_results <- data.table()

for (h in bw_grid) {
  sub <- panel[abs(margin_hd) <= h]
  n_muni <- uniqueN(sub$codmpio)

  if (n_muni < 20) {
    cat(sprintf("BW ±%.0f pp: skipping (only %d municipalities)\n", h*100, n_muni))
    next
  }

  mod <- feols(disc_share_n ~ treat:post | codmpio + yq,
               data = sub, cluster = ~codmpio)
  ct <- summary(mod)$coeftable

  bw_results <- rbind(bw_results, data.table(
    bandwidth = h,
    coef      = ct[1, 1],
    se        = ct[1, 2],
    pvalue    = ct[1, 4],
    n_muni    = n_muni,
    n_obs     = nobs(mod)
  ))

  cat(sprintf("BW ±%.0f pp: β=%.4f (SE=%.4f), p=%.4f, N_muni=%d\n",
              h*100, ct[1,1], ct[1,2], ct[1,4], n_muni))
}

## --------------------------------------------------------------------------
## 2. BANDWIDTH SENSITIVITY (rdrobust, cross-section)
## --------------------------------------------------------------------------
cat("\n=== rdrobust Bandwidth Sensitivity ===\n")

rdd_bw_results <- data.table()
for (h in c(0.05, 0.075, 0.10, 0.125, 0.15, 0.20)) {
  tryCatch({
    mod <- rdrobust(cs_data$delta_disc_n, cs_data$margin_hd, c = 0, h = h)
    rdd_bw_results <- rbind(rdd_bw_results, data.table(
      bandwidth = h,
      coef      = mod$coef[1],
      se        = mod$se[3],
      pvalue    = mod$pv[3],
      n_eff     = sum(mod$N_h)
    ))
    cat(sprintf("BW ±%.0f pp: β=%.4f, p=%.4f, N_eff=%d\n",
                h*100, mod$coef[1], mod$pv[3], sum(mod$N_h)))
  }, error = function(e) {
    cat(sprintf("BW ±%.0f pp: failed (%s)\n", h*100, e$message))
  })
}

## --------------------------------------------------------------------------
## 3. PLACEBO: PRE-PERIOD OUTCOME (should be null)
## --------------------------------------------------------------------------
cat("\n=== Placebo: Pre-Period Outcome ===\n")

# Define pseudo-treatment at Q3 2019 (period 3) instead of Q1 2020
panel[, pseudo_post := as.integer(period >= 3)]  # Q3 2019+
pre_only <- panel[post == 0]  # Only pre-inauguration quarters

if (nrow(pre_only) > 50 && uniqueN(pre_only$codmpio) > 20) {
  placebo_mod <- tryCatch({
    feols(disc_share_n ~ treat:pseudo_post | codmpio + yq,
          data = pre_only[abs(margin_hd) <= 0.15],
          cluster = ~codmpio)
  }, error = function(e) NULL)

  if (!is.null(placebo_mod)) {
    ct <- summary(placebo_mod)$coeftable
    cat(sprintf("Placebo (pre-period pseudo-treatment): β=%.4f, p=%.4f\n",
                ct[1,1], ct[1,4]))
  } else {
    cat("Placebo model failed (insufficient variation in pre-period)\n")
  }
} else {
  cat("Insufficient pre-period observations for placebo test\n")
}

# Cross-section placebo: pre-period level should show no discontinuity
placebo_rdd <- rdrobust(
  y = cs_data$disc_share_n_pre,
  x = cs_data$margin_hd,
  c = 0
)
cat(sprintf("Placebo RDD (pre-period level): β=%.4f, p=%.4f\n",
            placebo_rdd$coef[1], placebo_rdd$pv[3]))

## --------------------------------------------------------------------------
## 4. DONUT-HOLE RDD (exclude ±1pp)
## --------------------------------------------------------------------------
cat("\n=== Donut-Hole RDD ===\n")

cs_donut <- cs_data[abs(margin_hd) > 0.01]
donut_rdd <- tryCatch({
  rdrobust(cs_donut$delta_disc_n, cs_donut$margin_hd, c = 0)
}, error = function(e) { cat("Donut RDD failed:", e$message, "\n"); NULL })

if (!is.null(donut_rdd)) {
  cat(sprintf("Donut (exclude ±1pp): β=%.4f, p=%.4f, N_eff=%d\n",
              donut_rdd$coef[1], donut_rdd$pv[3], sum(donut_rdd$N_h)))
}

## --------------------------------------------------------------------------
## 5. ALTERNATIVE TREATMENT: CONTINUOUS DONOR SHARE
## --------------------------------------------------------------------------
cat("\n=== Continuous Treatment ===\n")

for (h in c(0.10, 0.15, 0.20)) {
  sub <- panel[abs(margin_hd) <= h]
  if (uniqueN(sub$codmpio) < 20) next

  mod <- feols(disc_share_n ~ winner_donor_share:post | codmpio + yq,
               data = sub, cluster = ~codmpio)
  ct <- summary(mod)$coeftable
  cat(sprintf("BW ±%.0f pp: β(donor_share×post)=%.4f, p=%.4f\n",
              h*100, ct[1,1], ct[1,4]))
}

## --------------------------------------------------------------------------
## 6. POLYNOMIAL ORDER SENSITIVITY (rdrobust)
## --------------------------------------------------------------------------
cat("\n=== Polynomial Order Sensitivity ===\n")

for (p in 1:2) {
  mod <- tryCatch({
    rdrobust(cs_data$delta_disc_n, cs_data$margin_hd, c = 0, p = p)
  }, error = function(e) NULL)
  if (!is.null(mod)) {
    cat(sprintf("Order %d: β=%.4f, p=%.4f, BW=%.4f\n",
                p, mod$coef[1], mod$pv[3], mod$bws[1,1]))
  }
}

## --------------------------------------------------------------------------
## 7. SAVE ROBUSTNESS RESULTS
## --------------------------------------------------------------------------
rob_results <- list(
  bw_sensitivity_panel = bw_results,
  bw_sensitivity_rdd   = rdd_bw_results,
  placebo_pre_rdd      = list(coef = placebo_rdd$coef[1], pv = placebo_rdd$pv[3]),
  donut = if (!is.null(donut_rdd))
    list(coef = donut_rdd$coef[1], pv = donut_rdd$pv[3]) else NULL
)
saveRDS(rob_results, paste0(data_dir, "robustness.rds"))

cat("\n=== Robustness checks complete ===\n")
