## ============================================================================
## 03_main_analysis.R — apep_1256
## Close-election RDD: donor-funded mayors and procurement composition
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
muni  <- fread(paste0(data_dir, "muni_characteristics.csv"))

## --------------------------------------------------------------------------
## 1. CONSTRUCT RDD RUNNING VARIABLE
## --------------------------------------------------------------------------
## For each municipality, redefine the margin from the high-donor candidate's
## perspective: positive if the higher-donor-share candidate won, negative if
## they lost. This creates a proper sharp RDD at zero.

# margin is always positive (winner - runner-up). high_donor = 1 if winner
# has higher donor share. So:
# margin_hd =  margin if high_donor == 1 (donor candidate won)
# margin_hd = -margin if high_donor == 0 (donor candidate lost)
panel[, margin_hd := ifelse(high_donor == 1, margin, -margin)]

# Treatment: did the high-donor candidate win?
panel[, treat := as.integer(margin_hd > 0)]

cat("=== RDD Design Summary ===\n")
cat(sprintf("Total municipalities: %d\n", uniqueN(panel$codmpio)))
cat(sprintf("Treated (high-donor won): %d\n",
            uniqueN(panel[treat == 1, codmpio])))
cat(sprintf("Control (high-donor lost): %d\n",
            uniqueN(panel[treat == 0, codmpio])))

## --------------------------------------------------------------------------
## 2. CROSS-SECTIONAL OUTCOMES — post-inauguration procurement
## --------------------------------------------------------------------------
## Collapse to municipality-level: pre-period and post-period averages

pre_data <- panel[post == 0, .(
  disc_share_n_pre = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_pre = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_pre      = sum(n_total),
  n_quarters_pre   = .N
), by = .(codmpio, margin_hd, treat, high_donor, winner_donor_share,
          winner_n_donors)]

post_data <- panel[post == 1, .(
  disc_share_n_post = weighted.mean(disc_share_n, n_total, na.rm = TRUE),
  disc_share_v_post = weighted.mean(disc_share_v, value_total, na.rm = TRUE),
  n_total_post      = sum(n_total),
  n_quarters_post   = .N
), by = codmpio]

cs_data <- merge(pre_data, post_data, by = "codmpio")

# Change in discretionary share (difference-in-discontinuity outcome)
cs_data[, delta_disc_n := disc_share_n_post - disc_share_n_pre]
cs_data[, delta_disc_v := disc_share_v_post - disc_share_v_pre]

cat(sprintf("\nCross-section sample: %d municipalities with pre+post data\n",
            nrow(cs_data)))

## --------------------------------------------------------------------------
## 3. RDD ESTIMATION — rdrobust
## --------------------------------------------------------------------------
cat("\n=== Main RDD Results ===\n")

# Primary outcome: change in discretionary share (by # contracts)
rdd_main <- rdrobust(
  y = cs_data$delta_disc_n,
  x = cs_data$margin_hd,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("\n--- Table 1: Discretionary Share (# contracts), DiD ---\n")
summary(rdd_main)

# Store optimal bandwidth
bw_opt <- rdd_main$bws[1, 1]
cat(sprintf("\nOptimal bandwidth: %.4f (±%.1f pp)\n", bw_opt, bw_opt * 100))
cat(sprintf("Effective N: %d left, %d right\n",
            rdd_main$N_h[1], rdd_main$N_h[2]))

# Secondary outcome: change in discretionary share (by value)
rdd_value <- rdrobust(
  y = cs_data$delta_disc_v,
  x = cs_data$margin_hd,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("\n--- Table 1: Discretionary Share (value), DiD ---\n")
summary(rdd_value)

# Post-level outcome (not DiD)
rdd_post_level <- rdrobust(
  y = cs_data$disc_share_n_post,
  x = cs_data$margin_hd,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("\n--- Post-period level (# contracts) ---\n")
summary(rdd_post_level)

## --------------------------------------------------------------------------
## 4. McCRARY DENSITY TEST
## --------------------------------------------------------------------------
cat("\n=== McCrary Density Test ===\n")
density_test <- rddensity(cs_data$margin_hd, c = 0)
cat(sprintf("McCrary test p-value: %.4f\n", density_test$test$p_jk))
cat(sprintf("  (H0: no manipulation. p > 0.05 = no evidence of sorting)\n"))

## --------------------------------------------------------------------------
## 5. COVARIATE BALANCE AT THE THRESHOLD
## --------------------------------------------------------------------------
cat("\n=== Covariate Balance ===\n")

# Pre-period discretionary share should be smooth at threshold
rdd_pre_balance <- rdrobust(
  y = cs_data$disc_share_n_pre,
  x = cs_data$margin_hd,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Pre-period disc share at threshold: coef=%.4f, p=%.4f\n",
            rdd_pre_balance$coef[1], rdd_pre_balance$pv[3]))

# Total contracts (pre-period)
rdd_ncontracts <- rdrobust(
  y = log(cs_data$n_total_pre + 1),
  x = cs_data$margin_hd,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Pre-period log(contracts) at threshold: coef=%.4f, p=%.4f\n",
            rdd_ncontracts$coef[1], rdd_ncontracts$pv[3]))

## --------------------------------------------------------------------------
## 6. PANEL DIFFERENCE-IN-DISCONTINUITY (fixest)
## --------------------------------------------------------------------------
cat("\n=== Panel DiD-in-Discontinuity ===\n")

# Within optimal bandwidth
panel_bw <- panel[abs(margin_hd) <= bw_opt]

cat(sprintf("Panel within bandwidth: %d obs, %d municipalities\n",
            nrow(panel_bw), uniqueN(panel_bw$codmpio)))

# Main specification: municipality and quarter FE
did_main <- feols(
  disc_share_n ~ treat:post | codmpio + yq,
  data = panel_bw,
  cluster = ~codmpio
)
cat("\n--- Panel DiD (main): treat × post ---\n")
print(summary(did_main))

# With margin control
did_margin <- feols(
  disc_share_n ~ treat:post + I(margin_hd * post) | codmpio + yq,
  data = panel_bw,
  cluster = ~codmpio
)

# Continuous treatment: donor share
did_continuous <- feols(
  disc_share_n ~ winner_donor_share:post | codmpio + yq,
  data = panel_bw,
  cluster = ~codmpio
)
cat("\n--- Panel DiD (continuous treatment): donor_share × post ---\n")
print(summary(did_continuous))

## --------------------------------------------------------------------------
## 7. SAVE ESTIMATES FOR TABLES
## --------------------------------------------------------------------------
estimates <- list(
  rdd_main = list(
    coef = rdd_main$coef[1],
    se = rdd_main$se[3],
    pv = rdd_main$pv[3],
    ci_l = rdd_main$ci[3, 1],
    ci_u = rdd_main$ci[3, 2],
    bw = bw_opt,
    n_eff = sum(rdd_main$N_h),
    n_left = rdd_main$N_h[1],
    n_right = rdd_main$N_h[2]
  ),
  rdd_value = list(
    coef = rdd_value$coef[1],
    se = rdd_value$se[3],
    pv = rdd_value$pv[3],
    bw = rdd_value$bws[1, 1],
    n_eff = sum(rdd_value$N_h)
  ),
  rdd_post_level = list(
    coef = rdd_post_level$coef[1],
    se = rdd_post_level$se[3],
    pv = rdd_post_level$pv[3]
  ),
  mccrary_pv = density_test$test$p_jk,
  pre_balance_pv = rdd_pre_balance$pv[3],
  did_main = list(
    coef = coef(did_main)[[1]],
    se = summary(did_main)$se[[1]],
    pv = summary(did_main)$coeftable[1, 4]
  ),
  did_continuous = list(
    coef = coef(did_continuous)[[1]],
    se = summary(did_continuous)$se[[1]],
    pv = summary(did_continuous)$coeftable[1, 4]
  )
)

saveRDS(estimates, paste0(data_dir, "estimates.rds"))

## --------------------------------------------------------------------------
## 8. DIAGNOSTICS for validator
## --------------------------------------------------------------------------
diag <- list(
  n_treated = uniqueN(panel_bw[treat == 1, codmpio]),
  n_pre     = uniqueN(panel[post == 0, yq]),
  n_obs     = nrow(panel_bw)
)
write_json(diag, paste0(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
cat("=== Main analysis complete ===\n")
