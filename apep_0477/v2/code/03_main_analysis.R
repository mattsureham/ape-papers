###############################################################################
# 03_main_analysis.R — Multi-cutoff RDD at EPC band boundaries
# apep_0477 v2: Do Energy Labels Move Markets?
# WS1: Match quality balance tests + address-matched subsample validation
# WS2: C/D-only as primary decomposition benchmark
# WS3: Diff-in-disc around MEES + annual event study
# WS4: No-covariate estimates, joint balance test
# WS5: Clustered SEs + mass-point adjustment
###############################################################################

source("00_packages.R")

DATA_DIR <- "../data"
df <- as.data.table(read_parquet(file.path(DATA_DIR, "analysis_sample.parquet")))

cat(sprintf("Full sample: %s observations\n", format(nrow(df), big.mark = ",")))

# Random sample for computational feasibility (16GB RAM, rdrobust is O(N))
# 500K obs gives 50K+ near each boundary — far more than RDD needs
set.seed(42)
SAMPLE_SIZE <- 500000L
if (nrow(df) > SAMPLE_SIZE) {
  df <- df[sample(.N, SAMPLE_SIZE)]
  cat(sprintf("Working sample (random %sK): %s observations\n",
              SAMPLE_SIZE / 1000, format(nrow(df), big.mark = ",")))
}
cat(sprintf("Analysis sample: %s observations\n", format(nrow(df), big.mark = ",")))

###############################################################################
# 1. McCrary Density Tests at All Boundaries
###############################################################################

cat("\n=== McCrary Density Tests ===\n")

mccrary_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]
  # Pre-filter to ±15 for speed (optimal bw typically 5-10)
  df_dens <- df[abs(epc_score - b) <= 15]

  # Overall
  dens <- rddensity(df_dens$epc_score, c = b)
  mccrary_results[[bname]] <- list(
    boundary = bname,
    cutoff = b,
    test_stat = dens$test$t_jk,
    p_value = dens$test$p_jk,
    N_left = dens$N$eff_left,
    N_right = dens$N$eff_right
  )

  cat(sprintf("  %s (c=%d): T=%.3f, p=%.4f [%s]\n",
              bname, b, dens$test$t_jk, dens$test$p_jk,
              ifelse(dens$test$p_jk < 0.05, "BUNCHING DETECTED", "OK")))

  # By MEES period (E/F only)
  if (b == 39) {
    for (per in c("Pre-MEES", "Post-MEES Pre-Crisis", "Crisis", "Post-Crisis")) {
      sub <- df_dens[period == per]
      if (nrow(sub) > 100) {
        dens_p <- rddensity(sub$epc_score, c = b)
        cat(sprintf("    %s: T=%.3f, p=%.4f [%s]\n",
                    per, dens_p$test$t_jk, dens_p$test$p_jk,
                    ifelse(dens_p$test$p_jk < 0.05, "BUNCHING", "OK")))
      }
    }
  }
}

mccrary_dt <- rbindlist(lapply(mccrary_results, as.data.table))
fwrite(mccrary_dt, file.path(DATA_DIR, "mccrary_results.csv"))
cat("McCrary results saved.\n")

###############################################################################
# 2. Covariate Balance Tests (WS4: expanded)
###############################################################################

cat("\n=== Covariate Balance Tests ===\n")

covariates <- c("floor_area", "is_flat", "is_new")
# WS1: Add match diagnostics to balance tests
match_diag_covs <- c("n_epc_candidates", "epc_recency")

balance_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]
  # Pre-filter to ±15 window (much faster; optimal bw is typically 5-10)
  df_win <- df[abs(epc_score - b) <= 15]

  all_covs <- c(covariates, if (b == 39) match_diag_covs else character(0))

  for (cov in all_covs) {
    if (all(is.na(df_win[[cov]]))) next

    tryCatch({
      rdd_cov <- rdrobust(
        y = df_win[[cov]],
        x = df_win$epc_score,
        c = b,
        kernel = "triangular",
        bwselect = "mserd",
        masspoints = "adjust"  # WS5
      )

      balance_results[[paste(bname, cov)]] <- data.table(
        boundary = bname,
        covariate = cov,
        estimate = rdd_cov$coef[1],
        se = rdd_cov$se[3],
        p_value = rdd_cov$pv[3],
        bw = rdd_cov$bws[1, 1],
        N_eff = rdd_cov$N_h[1] + rdd_cov$N_h[2]
      )

      cat(sprintf("  %s × %s: coef=%.4f, p=%.4f\n",
                  bname, cov, rdd_cov$coef[1], rdd_cov$pv[3]))
    }, error = function(e) {
      cat(sprintf("  %s × %s: ERROR - %s\n", bname, cov, e$message))
    })
  }
}

if (length(balance_results) > 0) {
  balance_dt <- rbindlist(balance_results)
  fwrite(balance_dt, file.path(DATA_DIR, "balance_results.csv"))
  cat("Balance results saved.\n")
}

###############################################################################
# 3. Main RDD Estimates at Each Boundary
#    WS4: Both with and without covariates
#    WS5: Clustered SEs + mass-point adjustment
###############################################################################

cat("\n=== Main RDD Estimates ===\n")

rdd_results <- list()

# Check if district column exists for clustering
has_district <- "district_clean" %in% names(df) &&
  uniqueN(df$district_clean[!is.na(df$district_clean)]) > 10

run_rdd <- function(sub_df, b, bname, period_label, tenure_label,
                    use_covs = TRUE, use_cluster = TRUE, tag = "",
                    window = 15) {
  # Pre-filter to ±window around cutoff (much faster than full sample)
  sub_df <- sub_df[abs(epc_score - b) <= window]
  key <- paste(bname, period_label, tenure_label, tag)
  n <- nrow(sub_df)
  if (n < 100) return(NULL)

  covs_mat <- if (use_covs) {
    cbind(sub_df$floor_area, sub_df$is_flat, sub_df$is_new)
  } else {
    NULL
  }

  # WS5: Cluster at district level
  clust <- if (use_cluster && has_district && !is.null(sub_df$district_clean)) {
    sub_df$district_clean
  } else {
    NULL
  }

  tryCatch({
    rdd <- rdrobust(
      y = sub_df$log_price,
      x = sub_df$epc_score,
      c = b,
      covs = covs_mat,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = clust,
      masspoints = "adjust"  # WS5
    )

    data.table(
      boundary = bname,
      cutoff = b,
      period = period_label,
      tenure = tenure_label,
      spec = ifelse(use_covs, "covariates", "no_covariates"),
      clustered = !is.null(clust),
      estimate = rdd$coef[1],
      se_robust = rdd$se[3],
      ci_lower = rdd$ci[3, 1],
      ci_upper = rdd$ci[3, 2],
      p_value = rdd$pv[3],
      bw_left = rdd$bws[1, 1],
      bw_right = rdd$bws[1, 2],
      N_eff_left = rdd$N_h[1],
      N_eff_right = rdd$N_h[2]
    )
  }, error = function(e) {
    cat(sprintf("    %s: ERROR - %s\n", key, e$message))
    NULL
  })
}

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]

  # Overall — with covariates (primary)
  res <- run_rdd(df, b, bname, "Overall", "All", use_covs = TRUE)
  if (!is.null(res)) {
    rdd_results[[paste(bname, "Overall", "cov")]] <- res
    cat(sprintf("\n  %s Overall (cov, clust): τ=%.4f (%.4f), p=%.4f, bw=%.1f\n",
                bname, res$estimate, res$se_robust, res$p_value, res$bw_left))
  }

  # WS4: Overall — without covariates
  res_nocov <- run_rdd(df, b, bname, "Overall", "All", use_covs = FALSE)
  if (!is.null(res_nocov)) {
    rdd_results[[paste(bname, "Overall", "nocov")]] <- res_nocov
    cat(sprintf("  %s Overall (no-cov): τ=%.4f (%.4f), p=%.4f\n",
                bname, res_nocov$estimate, res_nocov$se_robust, res_nocov$p_value))
  }

  # By period
  for (per in levels(df$period)) {
    sub <- df[period == per]
    if (nrow(sub) < 200) next

    res_per <- run_rdd(sub, b, bname, per, "All", use_covs = TRUE)
    if (!is.null(res_per)) {
      rdd_results[[paste(bname, per, "cov")]] <- res_per
      cat(sprintf("    %s (cov): τ=%.4f (%.4f), p=%.4f\n",
                  per, res_per$estimate, res_per$se_robust, res_per$p_value))
    }
  }

  # E/F boundary: by tenure (MEES regulatory decomposition)
  if (b == 39) {
    for (ten in c("rental", "owner")) {
      sub <- if (ten == "rental") df[is_rental == TRUE] else df[is_owner == TRUE]
      if (nrow(sub) < 200) next

      for (per in c("Pre-MEES", "Post-MEES Pre-Crisis", "Crisis", "Post-Crisis")) {
        sub_per <- sub[period == per]
        if (nrow(sub_per) < 100) next

        res_ten <- run_rdd(sub_per, b, bname, per, ten, use_covs = TRUE)
        if (!is.null(res_ten)) {
          rdd_results[[paste(bname, per, ten)]] <- res_ten
          cat(sprintf("    %s (%s): τ=%.4f (%.4f), p=%.4f\n",
                      per, ten, res_ten$estimate, res_ten$se_robust, res_ten$p_value))
        }
      }
    }
  }
}

rdd_dt <- rbindlist(rdd_results, fill = TRUE)
fwrite(rdd_dt, file.path(DATA_DIR, "rdd_results.csv"))
cat("\nAll RDD results saved.\n")

###############################################################################
# 4. WS1: Match Quality Validation
#    (a) Balance tests on match diagnostics at E/F
#    (b) Main E/F RDD on address-matched subsample
###############################################################################

cat("\n=== WS1: Match Quality Validation ===\n")

# (a) Already done above (match diagnostics in balance tests)

# (b) Address-matched subsample RDD at E/F
addr_sub <- df[match_quality == "address"]
cat(sprintf("Address-matched subsample: %s observations\n",
            format(nrow(addr_sub), big.mark = ",")))
cat(sprintf("  Near E/F (±10): %s\n",
            format(sum(abs(addr_sub$epc_score - 39) <= 10), big.mark = ",")))

addr_match_results <- list()

# Overall
res_addr <- run_rdd(addr_sub, 39, "E/F", "Overall", "All",
                    use_covs = TRUE, use_cluster = TRUE)
if (!is.null(res_addr)) {
  addr_match_results[["Overall"]] <- res_addr
  cat(sprintf("  E/F address-matched: τ=%.4f (%.4f), p=%.4f, N_eff=%d\n",
              res_addr$estimate, res_addr$se_robust, res_addr$p_value,
              res_addr$N_eff_left + res_addr$N_eff_right))
}

# By period
for (per in levels(df$period)) {
  sub_a <- addr_sub[period == per]
  res_a <- run_rdd(sub_a, 39, "E/F", per, "All", use_covs = TRUE)
  if (!is.null(res_a)) {
    addr_match_results[[per]] <- res_a
    cat(sprintf("    %s: τ=%.4f (%.4f), p=%.4f\n",
                per, res_a$estimate, res_a$se_robust, res_a$p_value))
  }
}

addr_match_dt <- rbindlist(addr_match_results, fill = TRUE)
fwrite(addr_match_dt, file.path(DATA_DIR, "address_match_validation.csv"))

###############################################################################
# 5. WS2: Decomposition — C/D-only as primary benchmark
###############################################################################

cat("\n=== Effect Decomposition (C/D-only primary) ===\n")

# Primary: C/D-only as informational benchmark (D/E fails McCrary, p=0.017)
cd_results <- rdd_dt[boundary == "C/D" & tenure == "All" & spec == "covariates"]
ef_results <- rdd_dt[boundary == "E/F" & tenure == "All" & spec == "covariates"]

if (nrow(cd_results) > 0 && nrow(ef_results) > 0) {
  decomp_cd <- merge(
    ef_results[, .(period, ef_effect = estimate, ef_se = se_robust)],
    cd_results[, .(period, info_effect = estimate, info_se = se_robust)],
    by = "period", all.x = TRUE
  )

  decomp_cd[, reg_effect := ef_effect - info_effect]
  decomp_cd[, reg_se := sqrt(ef_se^2 + info_se^2)]
  decomp_cd[, reg_pval := 2 * pnorm(-abs(reg_effect / reg_se))]
  decomp_cd[, benchmark := "C/D only"]

  cat("Primary decomposition (C/D-only benchmark):\n")
  print(decomp_cd[, .(period, ef_effect, info_effect, reg_effect, reg_se, reg_pval)])

  fwrite(decomp_cd, file.path(DATA_DIR, "decomposition_results.csv"))
}

# Robustness: D/E + C/D average (relegated to appendix per WS2)
de_cd_results <- rdd_dt[boundary %in% c("D/E", "C/D") & tenure == "All" &
                           spec == "covariates"]
if (nrow(de_cd_results) > 0) {
  info_avg <- de_cd_results[, .(
    info_effect = mean(estimate),
    info_se = sqrt(mean(se_robust^2))
  ), by = period]

  decomp_avg <- merge(
    ef_results[, .(period, ef_effect = estimate, ef_se = se_robust)],
    info_avg, by = "period", all.x = TRUE
  )
  decomp_avg[, reg_effect := ef_effect - info_effect]
  decomp_avg[, reg_se := sqrt(ef_se^2 + info_se^2)]
  decomp_avg[, reg_pval := 2 * pnorm(-abs(reg_effect / reg_se))]
  decomp_avg[, benchmark := "D/E + C/D average"]

  cat("\nRobustness decomposition (D/E + C/D average):\n")
  print(decomp_avg[, .(period, ef_effect, info_effect, reg_effect, reg_se, reg_pval)])

  fwrite(decomp_avg, file.path(DATA_DIR, "decomposition_results_avg.csv"))
}

###############################################################################
# 6. WS3: Difference-in-Discontinuities Around MEES (April 2018)
###############################################################################

cat("\n=== WS3: Difference-in-Discontinuities ===\n")

# (a) 2-year windows: pre (2016-2017) vs post (2018-2019)
pre_mees_2yr <- df[date_transfer >= as.Date("2016-01-01") &
                     date_transfer < as.Date("2018-04-01")]
post_mees_2yr <- df[date_transfer >= as.Date("2018-04-01") &
                      date_transfer < as.Date("2020-04-01")]

did_disc_results <- list()

for (bname_lab in c("E/F", "C/D")) {
  b <- EPC_BOUNDARIES[match(bname_lab, EPC_BAND_NAMES)]

  pre_res <- run_rdd(pre_mees_2yr, b, bname_lab, "Pre-MEES 2yr", "All",
                     use_covs = TRUE, use_cluster = TRUE, tag = "did")
  post_res <- run_rdd(post_mees_2yr, b, bname_lab, "Post-MEES 2yr", "All",
                      use_covs = TRUE, use_cluster = TRUE, tag = "did")

  if (!is.null(pre_res) && !is.null(post_res)) {
    diff <- post_res$estimate - pre_res$estimate
    diff_se <- sqrt(post_res$se_robust^2 + pre_res$se_robust^2)
    diff_pval <- 2 * pnorm(-abs(diff / diff_se))

    did_disc_results[[paste(bname_lab, "simple")]] <- data.table(
      boundary = bname_lab,
      type = "diff_in_disc",
      pre_estimate = pre_res$estimate,
      post_estimate = post_res$estimate,
      diff = diff,
      diff_se = diff_se,
      diff_pval = diff_pval
    )

    cat(sprintf("  %s diff-in-disc: pre=%.4f, post=%.4f, diff=%.4f (%.4f), p=%.4f\n",
                bname_lab, pre_res$estimate, post_res$estimate,
                diff, diff_se, diff_pval))
  }
}

# (b) Triple-difference: (E/F post - E/F pre) - (C/D post - C/D pre)
if (length(did_disc_results) >= 2) {
  ef_did <- did_disc_results[["E/F simple"]]
  cd_did <- did_disc_results[["C/D simple"]]

  if (!is.null(ef_did) && !is.null(cd_did)) {
    triple_diff <- ef_did$diff - cd_did$diff
    triple_se <- sqrt(ef_did$diff_se^2 + cd_did$diff_se^2)
    triple_pval <- 2 * pnorm(-abs(triple_diff / triple_se))

    did_disc_results[["triple"]] <- data.table(
      boundary = "Triple (E/F vs C/D)",
      type = "triple_diff",
      pre_estimate = NA_real_,
      post_estimate = NA_real_,
      diff = triple_diff,
      diff_se = triple_se,
      diff_pval = triple_pval
    )

    cat(sprintf("  Triple-diff (E/F - C/D): %.4f (%.4f), p=%.4f\n",
                triple_diff, triple_se, triple_pval))
  }
}

did_disc_dt <- rbindlist(did_disc_results, fill = TRUE)
fwrite(did_disc_dt, file.path(DATA_DIR, "diff_in_disc_results.csv"))

###############################################################################
# 6b. Cluster Bootstrap Inference for Decomposition & Diff-in-Disc
#     Resamples districts with replacement to account for spatial correlation.
#     Uses fixed bandwidth h=8 and no covariates for computational feasibility.
###############################################################################

cat("\n=== Cluster Bootstrap Inference ===\n")

B_BOOT <- 200L
BOOT_H <- 8
BOOT_WINDOW <- 15
set.seed(20260309)

# Identify unique districts for cluster resampling
district_ids <- unique(df$district_clean[!is.na(df$district_clean)])
n_districts <- length(district_ids)
cat(sprintf("Bootstrap: %d replications, %d districts, h=%d\n",
            B_BOOT, n_districts, BOOT_H))

# Subsets for diff-in-disc (same date windows as section 6a)
pre_mees_boot <- df[date_transfer >= as.Date("2016-01-01") &
                      date_transfer < as.Date("2018-04-01")]
post_mees_boot <- df[date_transfer >= as.Date("2018-04-01") &
                       date_transfer < as.Date("2020-04-01")]

# Helper: run rdrobust with fixed bandwidth, no covariates, no clustering
boot_rdd <- function(boot_df, b, window = BOOT_WINDOW) {
  sub <- boot_df[abs(epc_score - b) <= window]
  if (nrow(sub) < 60) return(NA_real_)
  tryCatch({
    rdd <- rdrobust(
      y = sub$log_price,
      x = sub$epc_score,
      c = b,
      h = BOOT_H,
      kernel = "triangular",
      masspoints = "adjust"
    )
    rdd$coef[1]  # conventional estimate
  }, error = function(e) NA_real_)
}

# Cutoffs
b_ef <- 39
b_cd <- 69

# Point estimates from original sample (for reporting)
orig_ef_pre  <- boot_rdd(pre_mees_boot, b_ef)
orig_ef_post <- boot_rdd(post_mees_boot, b_ef)
orig_cd_pre  <- boot_rdd(pre_mees_boot, b_cd)
orig_cd_post <- boot_rdd(post_mees_boot, b_cd)

orig_decomp_pre  <- orig_ef_pre - orig_cd_pre
orig_decomp_post <- orig_ef_post - orig_cd_post
orig_did_ef <- orig_ef_post - orig_ef_pre
orig_did_cd <- orig_cd_post - orig_cd_pre
orig_triple <- orig_did_ef - orig_did_cd

cat(sprintf("  Point estimates (h=%d, no covs):\n", BOOT_H))
cat(sprintf("    Decomp Pre-MEES:  %.4f\n", orig_decomp_pre))
cat(sprintf("    Decomp Post-MEES: %.4f\n", orig_decomp_post))
cat(sprintf("    Diff-in-disc E/F: %.4f\n", orig_did_ef))
cat(sprintf("    Diff-in-disc C/D: %.4f\n", orig_did_cd))
cat(sprintf("    Triple-diff:      %.4f\n", orig_triple))

# Storage matrices
boot_mat <- matrix(NA_real_, nrow = B_BOOT, ncol = 5,
                   dimnames = list(NULL,
                     c("decomp_pre", "decomp_post", "did_ef", "did_cd", "triple")))

t_start <- proc.time()
n_success <- 0L

for (bb in seq_len(B_BOOT)) {
  # Resample districts with replacement
  sampled_districts <- sample(district_ids, n_districts, replace = TRUE)

  # Build bootstrap sample: all observations from sampled districts
  # Handle duplicates by creating a mapping table
  boot_map <- data.table(district_clean = sampled_districts,
                         boot_id = seq_along(sampled_districts))
  boot_df <- merge(df, boot_map, by = "district_clean", allow.cartesian = TRUE)

  # Pre/post subsets for this bootstrap draw
  boot_pre  <- boot_df[date_transfer >= as.Date("2016-01-01") &
                          date_transfer < as.Date("2018-04-01")]
  boot_post <- boot_df[date_transfer >= as.Date("2018-04-01") &
                          date_transfer < as.Date("2020-04-01")]

  # Run rdrobust at each boundary x period
  ef_pre  <- boot_rdd(boot_pre, b_ef)
  ef_post <- boot_rdd(boot_post, b_ef)
  cd_pre  <- boot_rdd(boot_pre, b_cd)
  cd_post <- boot_rdd(boot_post, b_cd)

  # Skip if any RDD failed
  if (anyNA(c(ef_pre, ef_post, cd_pre, cd_post))) next

  boot_mat[bb, "decomp_pre"]  <- ef_pre - cd_pre
  boot_mat[bb, "decomp_post"] <- ef_post - cd_post
  boot_mat[bb, "did_ef"]      <- ef_post - ef_pre
  boot_mat[bb, "did_cd"]      <- cd_post - cd_pre
  boot_mat[bb, "triple"]      <- (ef_post - ef_pre) - (cd_post - cd_pre)
  n_success <- n_success + 1L

  if (bb %% 20 == 0) {
    elapsed <- (proc.time() - t_start)[3]
    cat(sprintf("  Bootstrap %d/%d complete (%d successful, %.1f min elapsed)\n",
                bb, B_BOOT, n_success, elapsed / 60))
  }
}

elapsed_total <- (proc.time() - t_start)[3]
cat(sprintf("  Bootstrap finished: %d/%d successful draws in %.1f minutes\n",
            n_success, B_BOOT, elapsed_total / 60))

# Compute bootstrap SEs and CIs from successful draws
boot_inference <- data.table(
  estimand = c("decomp_pre", "decomp_post", "did_ef", "did_cd", "triple"),
  estimate = c(orig_decomp_pre, orig_decomp_post, orig_did_ef, orig_did_cd, orig_triple)
)

for (j in seq_len(nrow(boot_inference))) {
  col <- boot_inference$estimand[j]
  vals <- boot_mat[, col]
  vals <- vals[!is.na(vals)]

  if (length(vals) >= 20) {
    boot_inference[j, boot_se := sd(vals)]
    boot_inference[j, boot_ci_lower := quantile(vals, 0.025)]
    boot_inference[j, boot_ci_upper := quantile(vals, 0.975)]
    # Two-sided p-value: proportion of bootstrap draws on opposite side of zero
    est <- boot_inference$estimate[j]
    boot_inference[j, boot_pval := 2 * min(mean(vals >= 0), mean(vals <= 0))]
  } else {
    cat(sprintf("  WARNING: Too few successful draws for %s (%d)\n", col, length(vals)))
    boot_inference[j, `:=`(boot_se = NA_real_, boot_ci_lower = NA_real_,
                           boot_ci_upper = NA_real_, boot_pval = NA_real_)]
  }
}

cat("\nCluster bootstrap inference results:\n")
print(boot_inference)

fwrite(boot_inference, file.path(DATA_DIR, "bootstrap_inference.csv"))
cat("Bootstrap inference saved to data/bootstrap_inference.csv\n")

# (c) Annual Event Study: E/F RDD for each year 2015-2024
cat("\n=== WS3: Annual Event Study ===\n")

annual_results <- list()

for (yr in 2015:2024) {
  sub_yr <- df[year_txn == yr]
  if (nrow(sub_yr) < 200) next

  for (bname_lab in c("E/F", "C/D")) {
    b <- EPC_BOUNDARIES[match(bname_lab, EPC_BAND_NAMES)]
    res_yr <- run_rdd(sub_yr, b, bname_lab, as.character(yr), "All",
                      use_covs = TRUE, use_cluster = TRUE, tag = "annual")

    if (!is.null(res_yr)) {
      res_yr[, year_num := yr]
      annual_results[[paste(bname_lab, yr)]] <- res_yr
      cat(sprintf("  %s %d: τ=%.4f (%.4f), p=%.4f\n",
                  bname_lab, yr, res_yr$estimate, res_yr$se_robust, res_yr$p_value))
    }
  }
}

annual_dt <- rbindlist(annual_results, fill = TRUE)
fwrite(annual_dt, file.path(DATA_DIR, "annual_event_study.csv"))

###############################################################################
# 7. Crisis Amplification Test
###############################################################################

cat("\n=== Crisis Amplification ===\n")

for (bname in EPC_BAND_NAMES[1:3]) {
  pre <- rdd_dt[boundary == bname & period == "Post-MEES Pre-Crisis" &
                  tenure == "All" & spec == "covariates"]
  crisis <- rdd_dt[boundary == bname & period == "Crisis" &
                     tenure == "All" & spec == "covariates"]

  if (nrow(pre) == 1 && nrow(crisis) == 1) {
    diff <- crisis$estimate - pre$estimate
    diff_se <- sqrt(crisis$se_robust^2 + pre$se_robust^2)
    diff_pval <- 2 * pnorm(-abs(diff / diff_se))
    cat(sprintf("  %s: Crisis - Pre = %.4f (%.4f), p=%.4f\n",
                bname, diff, diff_se, diff_pval))
  }
}

cat("\nMain analysis complete.\n")

###############################################################################
# 8. Full-Sample RDD at Each Boundary (±15 SAP window)
#    Reloads the full analysis_sample.parquet (not the 500K subsample)
#    Runs Overall/All/covariates specification only
###############################################################################

cat("\n=== Full-Sample RDD Estimates (±15 window) ===\n")

df_full <- as.data.table(read_parquet(file.path(DATA_DIR, "analysis_sample.parquet")))
cat(sprintf("Full sample reloaded: %s observations\n",
            format(nrow(df_full), big.mark = ",")))

has_district_full <- "district_clean" %in% names(df_full) &&
  uniqueN(df_full$district_clean[!is.na(df_full$district_clean)]) > 10

fullsample_results <- list()

for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  bname <- EPC_BAND_NAMES[i]

  # Trim to ±15 SAP points around the cutoff
  df_win <- df_full[abs(epc_score - b) <= 15]
  n_win <- nrow(df_win)
  cat(sprintf("\n  %s (c=%d): %s obs in ±15 window\n",
              bname, b, format(n_win, big.mark = ",")))

  if (n_win < 100) {
    cat(sprintf("    Skipping %s — too few observations\n", bname))
    next
  }

  # Covariates matrix
  covs_mat <- cbind(df_win$floor_area, df_win$is_flat, df_win$is_new)

  # Cluster variable
  clust <- if (has_district_full && !is.null(df_win$district_clean)) {
    df_win$district_clean
  } else {
    NULL
  }

  tryCatch({
    rdd <- rdrobust(
      y = df_win$log_price,
      x = df_win$epc_score,
      c = b,
      covs = covs_mat,
      kernel = "triangular",
      h = 8,
      cluster = clust
    )

    fullsample_results[[bname]] <- data.table(
      boundary = bname,
      cutoff = b,
      period = "Overall",
      tenure = "All",
      spec = "covariates",
      clustered = !is.null(clust),
      estimate = rdd$coef[1],
      se_robust = rdd$se[3],
      ci_lower = rdd$ci[3, 1],
      ci_upper = rdd$ci[3, 2],
      p_value = rdd$pv[3],
      bw_left = rdd$bws[1, 1],
      bw_right = rdd$bws[1, 2],
      N_eff_left = rdd$N_h[1],
      N_eff_right = rdd$N_h[2]
    )

    cat(sprintf("    τ=%.4f (%.4f), p=%.4f, bw=[%.1f, %.1f], N_eff=[%d, %d]\n",
                rdd$coef[1], rdd$se[3], rdd$pv[3],
                rdd$bws[1, 1], rdd$bws[1, 2],
                rdd$N_h[1], rdd$N_h[2]))

  }, error = function(e) {
    cat(sprintf("    %s: ERROR - %s\n", bname, e$message))
  })
}

if (length(fullsample_results) > 0) {
  fullsample_dt <- rbindlist(fullsample_results, fill = TRUE)
  fwrite(fullsample_dt, file.path(DATA_DIR, "rdd_results_fullsample.csv"))
  cat(sprintf("\nFull-sample RDD results saved: %d boundaries\n", nrow(fullsample_dt)))
  print(fullsample_dt[, .(boundary, estimate, se_robust, p_value, N_eff_left, N_eff_right)])
} else {
  cat("\nWARNING: No full-sample RDD results produced.\n")
}

rm(df_full)  # free memory
