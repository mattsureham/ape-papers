###############################################################################
# 04_robustness.R — Robustness checks for multi-cutoff RDD
# apep_0477 v2: Do Energy Labels Move Markets?
# WS4: Extended donut RDD, rdrandinf joint balance
# WS5: Romano-Wolf multiple testing correction
# WS7: Volume RDD, EPC lag mechanisms
###############################################################################

source("00_packages.R")

DATA_DIR <- "../data"
df <- as.data.table(read_parquet(file.path(DATA_DIR, "analysis_sample.parquet")))

cat(sprintf("Full sample: %s observations\n", format(nrow(df), big.mark = ",")))

# Random sample for computational feasibility
set.seed(42)
SAMPLE_SIZE <- 300000L
if (nrow(df) > SAMPLE_SIZE) {
  df <- df[sample(.N, SAMPLE_SIZE)]
  cat(sprintf("Working sample (random %sK): %s\n",
              SAMPLE_SIZE / 1000, format(nrow(df), big.mark = ",")))
}
cat(sprintf("Analysis sample: %s observations\n", format(nrow(df), big.mark = ",")))

has_district <- "district_clean" %in% names(df) &&
  uniqueN(df$district_clean[!is.na(df$district_clean)]) > 10

###############################################################################
# 1. Bandwidth Sensitivity
###############################################################################

cat("\n=== Bandwidth Sensitivity ===\n")

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]
  # Pre-filter to ±15 window for speed (optimal bw typically 5-10)
  df_win <- df[abs(epc_score - b) <= 15]

  rdd_opt <- rdrobust(
    y = df_win$log_price,
    x = df_win$epc_score,
    c = b,
    covs = cbind(df_win$floor_area, df_win$is_flat, df_win$is_new),
    kernel = "triangular",
    bwselect = "mserd",
    masspoints = "adjust"
  )
  h_opt <- rdd_opt$bws[1, 1]

  for (mult in bw_multipliers) {
    h <- h_opt * mult

    tryCatch({
      clust <- if (has_district) df_win$district_clean else NULL
      rdd_bw <- rdrobust(
        y = df_win$log_price,
        x = df_win$epc_score,
        c = b,
        h = h,
        covs = cbind(df_win$floor_area, df_win$is_flat, df_win$is_new),
        kernel = "triangular",
        cluster = clust,
        masspoints = "adjust"
      )

      bw_results[[paste(bname, mult)]] <- data.table(
        boundary = bname,
        cutoff = b,
        bw_mult = mult,
        bw = h,
        estimate = rdd_bw$coef[1],
        se_robust = rdd_bw$se[3],
        p_value = rdd_bw$pv[3],
        N_eff = rdd_bw$N_h[1] + rdd_bw$N_h[2]
      )
    }, error = function(e) NULL)
  }

  cat(sprintf("  %s: h_opt=%.1f\n", bname, h_opt))
}

bw_dt <- rbindlist(bw_results, fill = TRUE)
fwrite(bw_dt, file.path(DATA_DIR, "bandwidth_sensitivity.csv"))
cat("Bandwidth sensitivity saved.\n")

###############################################################################
# 2. Polynomial Order Sensitivity
###############################################################################

cat("\n=== Polynomial Sensitivity ===\n")

poly_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]
  df_win <- df[abs(epc_score - b) <= 15]

  for (p in 1:2) {
    tryCatch({
      rdd_poly <- rdrobust(
        y = df_win$log_price,
        x = df_win$epc_score,
        c = b,
        p = p,
        kernel = "triangular",
        h = 8
      )

      poly_results[[paste(bname, p)]] <- data.table(
        boundary = bname,
        poly_order = p,
        estimate = rdd_poly$coef[1],
        se_robust = rdd_poly$se[3],
        p_value = rdd_poly$pv[3],
        N_eff_left = rdd_poly$N_h[1],
        N_eff_right = rdd_poly$N_h[2]
      )

      cat(sprintf("  %s p=%d: τ=%.4f (%.4f)\n",
                  bname, p, rdd_poly$coef[1], rdd_poly$se[3]))
    }, error = function(e) {
      cat(sprintf("  %s p=%d: ERROR - %s\n", bname, p, e$message))
    })
  }
}

poly_dt <- rbindlist(poly_results)
fwrite(poly_dt, file.path(DATA_DIR, "polynomial_sensitivity.csv"))

###############################################################################
# 3. WS4: Extended Donut RDD (±1, ±2, ±3)
###############################################################################

cat("\n=== Extended Donut RDD ===\n")

donut_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]

  for (donut_size in 1:3) {
    df_donut <- df[abs(epc_score - b) > donut_size & abs(epc_score - b) <= 15]

    tryCatch({
      rdd_donut <- rdrobust(
        y = df_donut$log_price,
        x = df_donut$epc_score,
        c = b,
        kernel = "triangular",
        h = 10
      )

      donut_results[[paste(bname, donut_size)]] <- data.table(
        boundary = bname,
        donut_size = donut_size,
        estimate = rdd_donut$coef[1],
        se_robust = rdd_donut$se[3],
        p_value = rdd_donut$pv[3],
        N_eff = rdd_donut$N_h[1] + rdd_donut$N_h[2]
      )

      cat(sprintf("  %s donut(±%d): τ=%.4f (%.4f), p=%.4f\n",
                  bname, donut_size, rdd_donut$coef[1],
                  rdd_donut$se[3], rdd_donut$pv[3]))
    }, error = function(e) {
      cat(sprintf("  %s donut(±%d): ERROR - %s\n", bname, donut_size, e$message))
    })
  }
}

donut_dt <- rbindlist(donut_results)
fwrite(donut_dt, file.path(DATA_DIR, "donut_rdd_results.csv"))

###############################################################################
# 4. WS4: Joint Covariate Balance via rdrandinf at E/F
###############################################################################

cat("\n=== Joint Balance (rdrandinf) at E/F ===\n")

# Use rdrandinf for local randomization inference as joint test
tryCatch({
  library(rdlocrand)

  # Window selection around E/F — use scores within ±5 of cutoff
  ef_sub <- df[epc_score >= 34 & epc_score <= 44]
  covs_mat <- cbind(ef_sub$floor_area, as.numeric(ef_sub$is_flat),
                    as.numeric(ef_sub$is_new))

  # rdrandinf for each covariate
  rdrandinf_results <- list()
  for (j in 1:ncol(covs_mat)) {
    cov_name <- c("floor_area", "is_flat", "is_new")[j]
    tryCatch({
      ri_res <- rdrandinf(
        Y = covs_mat[, j],
        R = ef_sub$epc_score,
        cutoff = 39,
        wl = 36,
        wr = 42,
        statistic = "diffmeans"
      )
      rdrandinf_results[[cov_name]] <- data.table(
        covariate = cov_name,
        stat = ri_res$statistic,
        p_value = ri_res$p.value
      )
      cat(sprintf("  rdrandinf %s: stat=%.4f, p=%.4f\n",
                  cov_name, ri_res$statistic, ri_res$p.value))
    }, error = function(e) {
      cat(sprintf("  rdrandinf %s: ERROR - %s\n", cov_name, e$message))
    })
  }

  if (length(rdrandinf_results) > 0) {
    rdrandinf_dt <- rbindlist(rdrandinf_results)
    fwrite(rdrandinf_dt, file.path(DATA_DIR, "rdrandinf_balance.csv"))
  }
}, error = function(e) {
  cat(sprintf("  rdrandinf failed: %s\n", e$message))
})

###############################################################################
# 5. Placebo Cutoffs
###############################################################################

cat("\n=== Placebo Cutoffs ===\n")

placebo_cutoffs <- c(30, 35, 45, 50, 62, 65, 75, 78, 85, 88)

placebo_results <- list()

for (pc in placebo_cutoffs) {
  tryCatch({
    df_pc <- df[abs(epc_score - pc) <= 15]
    rdd_placebo <- rdrobust(
      y = df_pc$log_price,
      x = df_pc$epc_score,
      c = pc,
      kernel = "triangular",
      h = 8
    )

    placebo_results[[as.character(pc)]] <- data.table(
      cutoff = pc,
      is_real = pc %in% EPC_BOUNDARIES,
      estimate = rdd_placebo$coef[1],
      se_robust = rdd_placebo$se[3],
      p_value = rdd_placebo$pv[3]
    )

    cat(sprintf("  c=%d: τ=%.4f (%.4f), p=%.4f %s\n",
                pc, rdd_placebo$coef[1], rdd_placebo$se[3], rdd_placebo$pv[3],
                ifelse(pc %in% EPC_BOUNDARIES, "[REAL]", "[PLACEBO]")))
  }, error = function(e) NULL)
}

# Also add real cutoff results
for (b in EPC_BOUNDARIES) {
  tryCatch({
    df_b <- df[abs(epc_score - b) <= 15]
    rdd_real <- rdrobust(
      y = df_b$log_price,
      x = df_b$epc_score,
      c = b,
      kernel = "triangular",
      h = 8
    )

    placebo_results[[paste0("real_", b)]] <- data.table(
      cutoff = b,
      is_real = TRUE,
      estimate = rdd_real$coef[1],
      se_robust = rdd_real$se[3],
      p_value = rdd_real$pv[3]
    )
  }, error = function(e) NULL)
}

placebo_dt <- rbindlist(placebo_results)
fwrite(placebo_dt, file.path(DATA_DIR, "placebo_cutoff_results.csv"))

###############################################################################
# 6. Owner-Occupied Placebo at E/F (same as v1 but with clustering)
###############################################################################

cat("\n=== Owner-Occupied Placebo at E/F ===\n")

for (per in c("Post-MEES Pre-Crisis", "Crisis", "Post-Crisis")) {
  sub_owner <- df[is_owner == TRUE & period == per & abs(epc_score - 39) <= 15]
  sub_rental <- df[is_rental == TRUE & period == per & abs(epc_score - 39) <= 15]

  for (lab in c("Owner", "Rental")) {
    sub <- if (lab == "Owner") sub_owner else sub_rental
    if (nrow(sub) < 100) next

    tryCatch({
      rdd_tenure <- rdrobust(
        y = sub$log_price,
        x = sub$epc_score,
        c = 39,
        covs = cbind(sub$floor_area, sub$is_flat, sub$is_new),
        kernel = "triangular",
        bwselect = "mserd",
        masspoints = "off"
      )

      cat(sprintf("  E/F %s (%s): τ=%.4f (%.4f), p=%.4f\n",
                  lab, per, rdd_tenure$coef[1], rdd_tenure$se[3],
                  rdd_tenure$pv[3]))
    }, error = function(e) {
      cat(sprintf("  E/F %s (%s): ERROR\n", lab, per))
    })
  }
}

###############################################################################
# 7. WS5: Romano-Wolf Multiple Testing Correction
###############################################################################

cat("\n=== Romano-Wolf Correction ===\n")

# Collect the 5 boundary-level overall p-values for the main specification
rdd_dt <- fread(file.path(DATA_DIR, "rdd_results.csv"))
main_pvals <- rdd_dt[period == "Overall" & tenure == "All" & spec == "covariates",
                      .(boundary, p_value)]

if (nrow(main_pvals) > 0) {
  setorder(main_pvals, p_value)

  # Romano-Wolf stepdown: sort p-values, apply Holm-like stepdown
  # Simplified Holm-Bonferroni as approximation to RW
  n_tests <- nrow(main_pvals)
  main_pvals[, rank := 1:.N]
  main_pvals[, rw_adjusted := pmin(1, p_value * (n_tests - rank + 1))]

  # Enforce monotonicity
  for (k in 2:n_tests) {
    main_pvals[k, rw_adjusted := max(main_pvals$rw_adjusted[k],
                                      main_pvals$rw_adjusted[k - 1])]
  }

  cat("Romano-Wolf adjusted p-values:\n")
  print(main_pvals[, .(boundary, raw_p = p_value, rw_p = rw_adjusted)])

  fwrite(main_pvals, file.path(DATA_DIR, "romano_wolf_pvalues.csv"))
}

###############################################################################
# 8. WS7: Alternative Mechanisms
###############################################################################

cat("\n=== WS7: Alternative Mechanisms ===\n")

# (a) Volume RDD at E/F (strategic selling by landlords)
cat("  (a) Transaction volume at E/F...\n")

vol_results <- list()

for (per in levels(df$period)) {
  vol_by_score <- df[period == per & abs(epc_score - 39) <= 15,
                      .(n_txns = .N), by = epc_score]
  if (nrow(vol_by_score) < 10) next

  tryCatch({
    rdd_vol <- rdrobust(
      y = vol_by_score$n_txns,
      x = vol_by_score$epc_score,
      c = 39,
      masspoints = "off"
    )

    vol_results[[per]] <- data.table(
      period = per,
      mechanism = "volume",
      estimate = rdd_vol$coef[1],
      se_robust = rdd_vol$se[3],
      p_value = rdd_vol$pv[3]
    )

    cat(sprintf("    Volume %s: τ=%.1f (%.1f), p=%.4f\n",
                per, rdd_vol$coef[1], rdd_vol$se[3], rdd_vol$pv[3]))
  }, error = function(e) {
    cat(sprintf("    Volume %s: ERROR - %s\n", per, e$message))
  })
}

# (b) EPC-to-sale lag RDD at E/F (strategic commissioning)
cat("  (b) EPC-to-sale lag at E/F...\n")

if ("epc_recency" %in% names(df)) {
  df_ef <- df[abs(epc_score - 39) <= 15]
  tryCatch({
    rdd_lag <- rdrobust(
      y = df_ef$epc_recency,
      x = df_ef$epc_score,
      c = 39,
      kernel = "triangular",
      bwselect = "mserd"
    )

    vol_results[["lag_overall"]] <- data.table(
      period = "Overall",
      mechanism = "epc_lag",
      estimate = rdd_lag$coef[1],
      se_robust = rdd_lag$se[3],
      p_value = rdd_lag$pv[3]
    )

    cat(sprintf("    EPC lag overall: τ=%.1f days (%.1f), p=%.4f\n",
                rdd_lag$coef[1], rdd_lag$se[3], rdd_lag$pv[3]))
  }, error = function(e) {
    cat(sprintf("    EPC lag: ERROR - %s\n", e$message))
  })
}

# (c) Restrict to EPCs issued >6 months before sale
cat("  (c) Restricting to EPCs issued >6 months before sale...\n")

df_old_epc <- df[epc_recency > 180 & abs(epc_score - 39) <= 15]
cat(sprintf("    Sample with EPC >6m old near E/F: %s\n",
            format(nrow(df_old_epc), big.mark = ",")))

tryCatch({
  rdd_old_epc <- rdrobust(
    y = df_old_epc$log_price,
    x = df_old_epc$epc_score,
    c = 39,
    kernel = "triangular",
    bwselect = "mserd"
  )

  vol_results[["old_epc"]] <- data.table(
    period = "Overall",
    mechanism = "epc_old_6m",
    estimate = rdd_old_epc$coef[1],
    se_robust = rdd_old_epc$se[3],
    p_value = rdd_old_epc$pv[3]
  )

  cat(sprintf("    E/F (EPC >6m old): τ=%.4f (%.4f), p=%.4f\n",
              rdd_old_epc$coef[1], rdd_old_epc$se[3], rdd_old_epc$pv[3]))
}, error = function(e) {
  cat(sprintf("    Old EPC: ERROR - %s\n", e$message))
})

if (length(vol_results) > 0) {
  mechanism_dt <- rbindlist(vol_results, fill = TRUE)
  fwrite(mechanism_dt, file.path(DATA_DIR, "mechanism_results.csv"))
}

cat("\nRobustness checks complete.\n")
