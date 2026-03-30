# 03_main_analysis.R — Bunching estimation + difference-in-bunching
# apep_1173: PTZ zone reclassification bunching

source("00_packages.R")

dvf <- fread("../data/dvf_clean.csv")
ptz_caps <- fread("../data/raw/ptz_caps.csv")

cat(sprintf("Loaded %s transactions\n", formatC(nrow(dvf), format = "d", big.mark = ",")))

# ============================================================
# Bunching estimation function
# Following Kleven (2016): polynomial counterfactual + bootstrap
# ============================================================

estimate_bunching <- function(dt, cap_value, bin_width = 2500,
                              window = 40000, exclude_width = 7500,
                              poly_order = 7, n_boot = 200) {
  # Filter to transactions within window of the cap
  dt_w <- dt[valeur_fonciere >= (cap_value - window) &
               valeur_fonciere <= (cap_value + window)]

  if (nrow(dt_w) < 100) {
    return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w), cap = cap_value))
  }

  # Create bins relative to cap
  dt_w[, bin := floor((valeur_fonciere - cap_value) / bin_width) * bin_width + bin_width / 2]

  # Count transactions per bin
  bin_counts <- dt_w[, .(count = .N), by = bin]
  setkey(bin_counts, bin)

  # Fill in empty bins
  all_bins <- data.table(bin = seq(-window + bin_width/2, window - bin_width/2, by = bin_width))
  bin_counts <- merge(all_bins, bin_counts, by = "bin", all.x = TRUE)
  bin_counts[is.na(count), count := 0]

  # Define bunching region (bins just below and at the cap)
  # Bunching expected just below the cap (developers price AT cap)
  bunching_region <- bin_counts$bin >= -exclude_width & bin_counts$bin <= exclude_width

  # Fit polynomial counterfactual excluding bunching region
  fit_counterfactual <- function(bc) {
    df_fit <- bc[!bunching_region]
    if (nrow(df_fit) < poly_order + 1) return(rep(NA, nrow(bc)))
    mod <- lm(count ~ poly(bin, poly_order, raw = TRUE), data = df_fit)
    predict(mod, newdata = bc)
  }

  cf <- fit_counterfactual(bin_counts)
  if (all(is.na(cf))) {
    return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w), cap = cap_value))
  }

  # Excess mass = (actual - counterfactual) / counterfactual in bunching region
  actual_bunch <- sum(bin_counts$count[bunching_region])
  cf_bunch <- sum(cf[bunching_region])

  if (cf_bunch <= 0) {
    return(list(excess_mass = NA, se = NA, n_obs = nrow(dt_w), cap = cap_value))
  }

  excess_mass <- (actual_bunch - cf_bunch) / cf_bunch

  # Bootstrap SE
  boot_em <- numeric(n_boot)
  for (b in 1:n_boot) {
    idx <- sample(nrow(dt_w), replace = TRUE)
    dt_b <- dt_w[idx]
    dt_b[, bin := floor((valeur_fonciere - cap_value) / bin_width) * bin_width + bin_width / 2]
    bc_b <- dt_b[, .(count = .N), by = bin]
    bc_b <- merge(all_bins, bc_b, by = "bin", all.x = TRUE)
    bc_b[is.na(count), count := 0]
    cf_b <- fit_counterfactual(bc_b)
    if (all(is.na(cf_b))) { boot_em[b] <- NA; next }
    actual_b <- sum(bc_b$count[bunching_region])
    cf_b_sum <- sum(cf_b[bunching_region])
    boot_em[b] <- if (cf_b_sum > 0) (actual_b - cf_b_sum) / cf_b_sum else NA
  }

  se <- sd(boot_em, na.rm = TRUE)

  list(excess_mass = excess_mass, se = se, n_obs = nrow(dt_w), cap = cap_value,
       actual_bunch = actual_bunch, cf_bunch = round(cf_bunch))
}

# ============================================================
# Analysis 1: Cross-sectional bunching at PTZ caps
# ============================================================

cat("\n=== ANALYSIS 1: Cross-sectional bunching at PTZ caps ===\n")

# Focus on the most common caps (2-3 person households)
# and the zones with most transactions
key_caps <- ptz_caps[hh_size %in% c(1, 2, 3)]

# For each zone, estimate bunching at each cap
# Compare VEFA (new-build, PTZ eligible) vs non-VEFA (second-hand, placebo)

results_xsec <- list()
i <- 1

for (z in c("C", "B2", "B1", "A")) {
  caps_z <- key_caps[zone == z, cap]
  for (cp in caps_z) {
    for (vefa in c(TRUE, FALSE)) {
      dt_sub <- dvf[zone == z & is_vefa == vefa]
      cat(sprintf("  Zone %s, cap=%.1fK, %s: N=%s... ",
                  z, cp/1000, ifelse(vefa, "VEFA", "Resale"), formatC(nrow(dt_sub), big.mark = ",")))
      res <- estimate_bunching(dt_sub, cap_value = cp, n_boot = 200)
      res$zone <- z
      res$is_vefa <- vefa
      res$hh_size <- key_caps[zone == z & cap == cp, hh_size]
      results_xsec[[i]] <- res
      i <- i + 1
      if (!is.na(res$excess_mass)) {
        cat(sprintf("b=%.3f (SE=%.3f)\n", res$excess_mass, res$se))
      } else {
        cat("insufficient data\n")
      }
    }
  }
}

xsec <- rbindlist(results_xsec, fill = TRUE)
xsec[, sig := fifelse(!is.na(excess_mass) & !is.na(se) & se > 0,
                       fifelse(abs(excess_mass/se) > 2.576, "***",
                       fifelse(abs(excess_mass/se) > 1.96, "**",
                       fifelse(abs(excess_mass/se) > 1.645, "*", ""))), "")]

cat("\nCross-sectional bunching summary:\n")
print(xsec[!is.na(excess_mass), .(zone, cap = cap/1000, hh_size,
                                   type = fifelse(is_vefa, "VEFA", "Resale"),
                                   excess_mass = round(excess_mass, 3),
                                   se = round(se, 3), sig, n_obs)])

# ============================================================
# Analysis 2: Difference-in-bunching (pre/post reclassification)
# ============================================================

cat("\n=== ANALYSIS 2: Difference-in-bunching ===\n")

# Focus on the largest transition: B2 -> B1 (485 communes)
# Old cap (B2, 2-person): 165,000
# New cap (B1, 2-person): 202,500

# For reclassified B2->B1 communes:
# Pre-period: bunching at 165K (old cap)
# Post-period: bunching should migrate to 202.5K (new cap)

# Control: non-reclassified B2 communes (stable at 165K cap)

b2_to_b1 <- dvf[transition == "B2_to_B1" | (transition == "stable" & zone_pre_jul24 == "B2")]

# Tag treated vs control
b2_to_b1[, treated := transition == "B2_to_B1"]

cat(sprintf("B2->B1 sample: %s transactions (%s treated, %s control)\n",
            formatC(nrow(b2_to_b1), big.mark = ","),
            formatC(b2_to_b1[treated == TRUE, .N], big.mark = ","),
            formatC(b2_to_b1[treated == FALSE, .N], big.mark = ",")))

# Estimate bunching at OLD cap (165K) for treated vs control, pre vs post
old_cap <- 165000
new_cap <- 202500

dib_results <- list()
j <- 1

for (tr in c(TRUE, FALSE)) {
  for (post in c(FALSE, TRUE)) {
    for (vefa_flag in c(TRUE, FALSE)) {
      dt_sub <- b2_to_b1[treated == tr & post_jul24 == post & is_vefa == vefa_flag]
      label <- sprintf("%s, %s, %s",
                       ifelse(tr, "Treated", "Control"),
                       ifelse(post, "Post", "Pre"),
                       ifelse(vefa_flag, "VEFA", "Resale"))
      cat(sprintf("  %s at old cap (165K): N=%s... ", label, formatC(nrow(dt_sub), big.mark = ",")))

      res_old <- estimate_bunching(dt_sub, cap_value = old_cap, n_boot = 200)
      res_old$group <- label
      res_old$at_cap <- "old_165K"
      res_old$treated <- tr
      res_old$post <- post
      res_old$is_vefa <- vefa_flag
      dib_results[[j]] <- res_old
      j <- j + 1

      if (!is.na(res_old$excess_mass)) {
        cat(sprintf("b=%.3f ", res_old$excess_mass))
      } else {
        cat("NA ")
      }

      # Also estimate at NEW cap (202.5K) for treated
      if (tr) {
        res_new <- estimate_bunching(dt_sub, cap_value = new_cap, n_boot = 200)
        res_new$group <- label
        res_new$at_cap <- "new_202.5K"
        res_new$treated <- tr
        res_new$post <- post
        res_new$is_vefa <- vefa_flag
        dib_results[[j]] <- res_new
        j <- j + 1
        if (!is.na(res_new$excess_mass)) {
          cat(sprintf("| new cap: b=%.3f", res_new$excess_mass))
        }
      }
      cat("\n")
    }
  }
}

dib <- rbindlist(dib_results, fill = TRUE)
dib[, sig := fifelse(!is.na(excess_mass) & !is.na(se) & se > 0,
                      fifelse(abs(excess_mass/se) > 2.576, "***",
                      fifelse(abs(excess_mass/se) > 1.96, "**",
                      fifelse(abs(excess_mass/se) > 1.645, "*", ""))), "")]

cat("\nDifference-in-bunching results:\n")
print(dib[!is.na(excess_mass), .(group, at_cap,
                                  excess_mass = round(excess_mass, 3),
                                  se = round(se, 3), sig, n_obs)])

# ============================================================
# Analysis 3: Regression-based difference-in-bunching
# ============================================================

cat("\n=== ANALYSIS 3: Regression-based DiB ===\n")

# Create bin-level panel for B2/B1 zone communes
# Unit: commune-month-bin
# Focus on VEFA transactions near old/new caps

# Bin counts at the old cap (165K) for B2 communes
cap_focus <- 165000
window_reg <- 30000

# Get VEFA transactions near old cap
dt_reg <- b2_to_b1[is_vefa == TRUE &
                      valeur_fonciere >= (cap_focus - window_reg) &
                      valeur_fonciere <= (cap_focus + window_reg)]

if (nrow(dt_reg) > 50) {
  dt_reg[, bin := floor((valeur_fonciere - cap_focus) / 2500) * 2500 + 1250]
  dt_reg[, near_cap := abs(bin) <= 5000]  # within 5K of cap
  dt_reg[, quarter := paste0(year, "Q", ceiling(as.numeric(format(date, "%m")) / 3))]

  # Aggregate to commune-quarter-bin
  panel <- dt_reg[, .(n_txn = .N), by = .(code_commune, quarter, bin, treated, post_jul24, near_cap)]

  # DiD regression: transactions near cap ~ treated * post
  reg1 <- feols(n_txn ~ treated * post_jul24 | code_commune + quarter,
                data = panel[near_cap == TRUE],
                cluster = ~code_commune)
  cat("\nRegression 1: Bunching at old cap (165K) — VEFA only\n")
  cat("n_txn ~ treated * post | commune + quarter FE\n")
  print(summary(reg1))
} else {
  cat("Insufficient VEFA transactions for regression at 165K cap\n")
  reg1 <- NULL
}

# Also run on ALL transactions (not just VEFA) for more power
dt_reg_all <- b2_to_b1[valeur_fonciere >= (cap_focus - window_reg) &
                          valeur_fonciere <= (cap_focus + window_reg)]

if (nrow(dt_reg_all) > 100) {
  dt_reg_all[, bin := floor((valeur_fonciere - cap_focus) / 2500) * 2500 + 1250]
  dt_reg_all[, near_cap := abs(bin) <= 5000]
  dt_reg_all[, quarter := paste0(year, "Q", ceiling(as.numeric(format(date, "%m")) / 3))]

  panel_all <- dt_reg_all[, .(n_txn = .N), by = .(code_commune, quarter, bin, treated, post_jul24, near_cap, is_vefa)]

  # Triple-diff: near_cap * treated * post, with VEFA interaction
  reg2 <- feols(n_txn ~ near_cap * treated * post_jul24 | code_commune + quarter + bin,
                data = panel_all,
                cluster = ~code_commune)
  cat("\nRegression 2: Triple-diff (near_cap * treated * post) — all transactions\n")
  print(summary(reg2))
} else {
  cat("Insufficient transactions for triple-diff regression\n")
  reg2 <- NULL
}

# ============================================================
# Analysis 4: Dose-response across reclassification magnitudes
# ============================================================

cat("\n=== ANALYSIS 4: Dose-response ===\n")

# Compare excess mass migration across transition types
# B1->A: cap shift = 22.5K (smallest)
# B2->B1: cap shift = 37.5K (medium)
# C->B1: cap shift = 52.5K (largest among common transitions)

dose_transitions <- data.table(
  transition = c("B1_to_A", "B2_to_B1", "C_to_B1"),
  old_zone = c("B1", "B2", "C"),
  new_zone = c("A", "B1", "B1"),
  delta_cap_2p = c(22500, 37500, 52500)  # for 2-person household
)

dose_results <- list()
k <- 1

for (i_tr in 1:nrow(dose_transitions)) {
  tr <- dose_transitions[i_tr]
  old_caps <- ptz_caps[zone == tr$old_zone & hh_size == 2, cap]
  new_caps <- ptz_caps[zone == tr$new_zone & hh_size == 2, cap]

  dt_tr <- dvf[transition == tr$transition & is_vefa == TRUE]

  # Pre-period bunching at old cap
  if (nrow(dt_tr[post_jul24 == FALSE]) > 20) {
    res_pre <- estimate_bunching(dt_tr[post_jul24 == FALSE], cap_value = old_caps, n_boot = 200)
  } else {
    res_pre <- list(excess_mass = NA, se = NA)
  }

  # Post-period bunching at new cap
  if (nrow(dt_tr[post_jul24 == TRUE]) > 20) {
    res_post <- estimate_bunching(dt_tr[post_jul24 == TRUE], cap_value = new_caps, n_boot = 200)
  } else {
    res_post <- list(excess_mass = NA, se = NA)
  }

  dose_results[[k]] <- data.table(
    transition = tr$transition,
    delta_cap = tr$delta_cap_2p,
    n_communes = dvf[transition == tr$transition, uniqueN(code_commune)],
    n_vefa_pre = dt_tr[post_jul24 == FALSE, .N],
    n_vefa_post = dt_tr[post_jul24 == TRUE, .N],
    bunch_pre_old = ifelse(is.null(res_pre$excess_mass), NA, res_pre$excess_mass),
    se_pre = ifelse(is.null(res_pre$se), NA, res_pre$se),
    bunch_post_new = ifelse(is.null(res_post$excess_mass), NA, res_post$excess_mass),
    se_post = ifelse(is.null(res_post$se), NA, res_post$se)
  )
  k <- k + 1
}

dose <- rbindlist(dose_results)
cat("\nDose-response across transitions (VEFA, 2-person cap):\n")
print(dose)

# ============================================================
# Save results and write diagnostics.json
# ============================================================

# Save all results
save(xsec, dib, dose, reg1, reg2,
     file = "../data/analysis_results.RData")

# diagnostics.json for validator
n_treated <- dvf[reclassified_jul24 == TRUE, uniqueN(code_commune)]
n_pre <- dvf[post_jul24 == FALSE, uniqueN(month)]
n_obs <- nrow(dvf)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_vefa = dvf[is_vefa == TRUE, .N],
  n_reclassified_txn = dvf[reclassified_jul24 == TRUE, .N],
  zones = c("Abis", "A", "B1", "B2", "C"),
  transitions = as.list(dvf[reclassified_jul24 == TRUE, .N, transition][, setNames(as.list(N), transition)])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")
cat(sprintf("  n_treated=%d, n_pre=%d, n_obs=%s\n", n_treated, n_pre, formatC(n_obs, big.mark = ",")))
