# 04_robustness.R — Robustness checks for PTZ bunching analysis
# apep_1173

source("00_packages.R")

dvf <- fread("../data/dvf_clean.csv")
load("../data/analysis_results.RData")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# Reuse bunching estimator from 03
estimate_bunching <- function(dt, cap_value, bin_width = 2500,
                              window = 40000, exclude_width = 7500,
                              poly_order = 7, n_boot = 200) {
  dt_w <- dt[valeur_fonciere >= (cap_value - window) &
               valeur_fonciere <= (cap_value + window)]
  if (nrow(dt_w) < 100) return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w)))
  dt_w[, bin := floor((valeur_fonciere - cap_value) / bin_width) * bin_width + bin_width / 2]
  bin_counts <- dt_w[, .(count = .N), by = bin]
  all_bins <- data.table(bin = seq(-window + bin_width/2, window - bin_width/2, by = bin_width))
  bin_counts <- merge(all_bins, bin_counts, by = "bin", all.x = TRUE)
  bin_counts[is.na(count), count := 0]
  bunching_region <- bin_counts$bin >= -exclude_width & bin_counts$bin <= exclude_width
  fit_cf <- function(bc) {
    df_fit <- bc[!bunching_region]
    if (nrow(df_fit) < poly_order + 1) return(rep(NA, nrow(bc)))
    mod <- lm(count ~ poly(bin, poly_order, raw = TRUE), data = df_fit)
    predict(mod, newdata = bc)
  }
  cf <- fit_cf(bin_counts)
  if (all(is.na(cf))) return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w)))
  actual <- sum(bin_counts$count[bunching_region])
  cf_sum <- sum(cf[bunching_region])
  if (cf_sum <= 0) return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w)))
  em <- (actual - cf_sum) / cf_sum
  boot_em <- numeric(n_boot)
  for (b in 1:n_boot) {
    dt_b <- dt_w[sample(.N, replace = TRUE)]
    dt_b[, bin := floor((valeur_fonciere - cap_value) / bin_width) * bin_width + bin_width / 2]
    bc_b <- dt_b[, .(count = .N), by = bin]
    bc_b <- merge(all_bins, bc_b, by = "bin", all.x = TRUE)
    bc_b[is.na(count), count := 0]
    cf_b <- fit_cf(bc_b)
    if (all(is.na(cf_b))) { boot_em[b] <- NA; next }
    a_b <- sum(bc_b$count[bunching_region])
    c_b <- sum(cf_b[bunching_region])
    boot_em[b] <- if (c_b > 0) (a_b - c_b) / c_b else NA
  }
  list(excess_mass = em, se = sd(boot_em, na.rm = TRUE), n_obs = nrow(dt_w))
}

# ============================================================
# Robustness 1: Alternative bin widths
# ============================================================

cat("--- Robustness 1: Alternative bin widths (B2, cap=165K, VEFA) ---\n")
dt_b2_vefa <- dvf[zone_pre_jul24 == "B2" & is_vefa == TRUE]
rob_bw <- list()
for (bw in c(1000, 2500, 5000)) {
  res <- estimate_bunching(dt_b2_vefa, cap_value = 165000, bin_width = bw, n_boot = 200)
  rob_bw[[as.character(bw)]] <- data.table(bin_width = bw,
                                            excess_mass = res$excess_mass,
                                            se = res$se, n_obs = res$n_obs)
  cat(sprintf("  Bin=%.1fK: b=%.3f (SE=%.3f)\n", bw/1000, res$excess_mass, res$se))
}
rob_bw <- rbindlist(rob_bw)

# ============================================================
# Robustness 2: Alternative polynomial orders
# ============================================================

cat("\n--- Robustness 2: Alternative polynomial orders (B2, cap=165K, VEFA) ---\n")
rob_poly <- list()
for (po in c(5, 7, 9)) {
  res <- estimate_bunching(dt_b2_vefa, cap_value = 165000, poly_order = po, n_boot = 200)
  rob_poly[[as.character(po)]] <- data.table(poly_order = po,
                                              excess_mass = res$excess_mass,
                                              se = res$se)
  cat(sprintf("  Poly=%d: b=%.3f (SE=%.3f)\n", po, res$excess_mass, res$se))
}
rob_poly <- rbindlist(rob_poly)

# ============================================================
# Robustness 3: Placebo caps (shifted by 10K, 20K)
# ============================================================

cat("\n--- Robustness 3: Placebo caps (B2, VEFA) ---\n")
rob_placebo <- list()
for (pc in c(145000, 155000, 165000, 175000, 185000)) {
  res <- estimate_bunching(dt_b2_vefa, cap_value = pc, n_boot = 200)
  rob_placebo[[as.character(pc)]] <- data.table(placebo_cap = pc,
                                                 is_true_cap = (pc == 165000),
                                                 excess_mass = res$excess_mass,
                                                 se = res$se)
  cat(sprintf("  Cap=%dK: b=%.3f (SE=%.3f) %s\n", pc/1000,
              ifelse(is.na(res$excess_mass), 0, res$excess_mass),
              ifelse(is.na(res$se), 0, res$se),
              ifelse(pc == 165000, "<-- true cap", "")))
}
rob_placebo <- rbindlist(rob_placebo)

# ============================================================
# Robustness 4: Resale as full placebo
# ============================================================

cat("\n--- Robustness 4: Resale transactions as placebo ---\n")
dt_b2_resale <- dvf[zone_pre_jul24 == "B2" & is_vefa == FALSE]
for (cp in c(110000, 165000, 198000)) {
  res <- estimate_bunching(dt_b2_resale, cap_value = cp, n_boot = 200)
  cat(sprintf("  B2 Resale at %dK: b=%.3f (SE=%.3f)\n", cp/1000, res$excess_mass, res$se))
}

# ============================================================
# Robustness 5: Alternative exclude widths
# ============================================================

cat("\n--- Robustness 5: Alternative exclude widths (B2, cap=165K, VEFA) ---\n")
rob_excl <- list()
for (ew in c(5000, 7500, 10000, 12500)) {
  res <- estimate_bunching(dt_b2_vefa, cap_value = 165000, exclude_width = ew, n_boot = 200)
  rob_excl[[as.character(ew)]] <- data.table(exclude_width = ew,
                                              excess_mass = res$excess_mass,
                                              se = res$se)
  cat(sprintf("  Exclude=%.1fK: b=%.3f (SE=%.3f)\n", ew/1000, res$excess_mass, res$se))
}
rob_excl <- rbindlist(rob_excl)

# ============================================================
# Robustness 6: Alternative triple-diff specifications
# ============================================================

cat("\n--- Robustness 6: Triple-diff with alternative windows ---\n")

b2_all <- dvf[transition == "B2_to_B1" | (transition == "stable" & zone_pre_jul24 == "B2")]
b2_all[, treated := transition == "B2_to_B1"]
b2_all[, quarter := paste0(year, "Q", ceiling(as.numeric(format(as.Date(date_mutation), "%m")) / 3))]

for (win in c(20000, 30000, 40000)) {
  dt_r <- b2_all[valeur_fonciere >= (165000 - win) & valeur_fonciere <= (165000 + win)]
  dt_r[, bin := floor((valeur_fonciere - 165000) / 2500) * 2500 + 1250]
  dt_r[, near_cap := abs(bin) <= 5000]
  panel_r <- dt_r[, .(n_txn = .N), by = .(code_commune, quarter, bin, treated, post_jul24, near_cap)]
  reg_r <- feols(n_txn ~ near_cap * treated * post_jul24 | code_commune + quarter + bin,
                 data = panel_r, cluster = ~code_commune)
  coef_name <- "near_capTRUE:treatedTRUE:post_jul24TRUE"
  cf <- coef(reg_r)[coef_name]
  se_cf <- sqrt(vcov(reg_r)[coef_name, coef_name])
  cat(sprintf("  Window=+-%dK: coef=%.4f (SE=%.4f), p=%.3f\n", win/1000, cf, se_cf, 2*pnorm(-abs(cf/se_cf))))
}

# Save robustness results
save(rob_bw, rob_poly, rob_placebo, rob_excl,
     file = "../data/robustness_results.RData")

cat("\n=== Robustness checks complete ===\n")
