# ==============================================================================
# 04_robustness.R — Robustness checks for Lex Weber vacancy-rate DiD
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# ==============================================================================
#
# Nine robustness checks:
#   1. Placebo timing tests (fake treatment in 2000, 2003, 2005, 2007)
#   2. Donut DiD (drop municipalities near the 20% cutoff)
#   3. Leave-one-canton-out
#   4. Randomization inference (1000 permutations)
#   5. Wild cluster bootstrap (Webb weights, 999 replications)
#   6. Alternative treatment timing (ZWG 2016)
#   7. Continuous treatment intensity
#   8. Placebo outcome (non-residential employment)
#   9. Rambachan & Roth (HonestDiD) sensitivity
#
# Input:  ../data/panel.csv
# Output: ../data/placebo_timing.csv, donut_did.csv, leave_one_canton_out.csv,
#         ri_distribution.csv, ri_summary.csv, wild_bootstrap.csv,
#         alt_timing.csv, continuous_treatment.csv, placebo_outcome.csv,
#         honest_did.csv
# ==============================================================================

source("00_packages.R")

cat("\n========== 04_robustness.R ==========\n")

# --- Load data ----------------------------------------------------------------

panel <- fread("../data/panel.csv")
stopifnot(nrow(panel) > 0)
stopifnot(all(c("gem_id", "year", "treated", "post", "second_home_share",
                "vacancy_rate", "canton_id") %in% names(panel)))

cat(sprintf("Panel loaded: %d obs, %d municipalities, years %d-%d\n",
            nrow(panel), uniqueN(panel$gem_id),
            min(panel$year), max(panel$year)))

out_dir <- "../data"

# ==============================================================================
# Helper: extract DiD coefficient from fixest model
# ==============================================================================

extract_did <- function(mod, param_pattern = "treated.*post|treat_post") {
  cf  <- coef(mod)
  se  <- se(mod)
  pv  <- pvalue(mod)
  idx <- grep(param_pattern, names(cf))
  if (length(idx) == 0) {
    return(data.table(coef = NA_real_, se = NA_real_, pvalue = NA_real_))
  }
  data.table(
    coef   = cf[idx[1]],
    se     = se[idx[1]],
    pvalue = pv[idx[1]]
  )
}

# ==============================================================================
# 1. Placebo Timing Tests
# ==============================================================================

cat("\n--- 1. Placebo timing tests ---\n")

fake_years <- c(2000, 2003, 2005, 2007)
pre_data   <- panel[year <= 2011]

placebo_timing <- rbindlist(lapply(fake_years, function(fy) {
  tryCatch({
    dt <- copy(pre_data)
    dt[, fake_post := as.integer(year >= fy)]
    mod <- feols(vacancy_rate ~ treated:fake_post | gem_id + year,
                 data = dt, cluster = ~canton_id)
    res <- extract_did(mod, "treated.*fake_post")
    res[, fake_year := fy]
    cat(sprintf("  Fake %d: coef = %.4f, se = %.4f, p = %.3f\n",
                fy, res$coef, res$se, res$pvalue))
    res
  }, error = function(e) {
    cat(sprintf("  Fake %d: ERROR — %s\n", fy, conditionMessage(e)))
    data.table(coef = NA_real_, se = NA_real_, pvalue = NA_real_, fake_year = fy)
  })
}))

setcolorder(placebo_timing, c("fake_year", "coef", "se", "pvalue"))
fwrite(placebo_timing, file.path(out_dir, "placebo_timing.csv"))
cat("  Saved placebo_timing.csv\n")

# ==============================================================================
# 2. Donut DiD
# ==============================================================================

cat("\n--- 2. Donut DiD (drop 18% < share < 22%) ---\n")

tryCatch({
  donut <- panel[second_home_share <= 18 | second_home_share >= 22]
  cat(sprintf("  Donut sample: %d obs (%d municipalities dropped)\n",
              nrow(donut),
              uniqueN(panel$gem_id) - uniqueN(donut$gem_id)))

  mod_donut <- feols(vacancy_rate ~ treated:post | gem_id + year,
                     data = donut, cluster = ~canton_id)
  res_donut <- extract_did(mod_donut)
  res_donut[, sample := "donut_2pp"]

  cat(sprintf("  coef = %.4f, se = %.4f, p = %.3f\n",
              res_donut$coef, res_donut$se, res_donut$pvalue))

  fwrite(res_donut, file.path(out_dir, "donut_did.csv"))
  cat("  Saved donut_did.csv\n")
}, error = function(e) {
  cat(sprintf("  ERROR — %s\n", conditionMessage(e)))
  fwrite(data.table(coef = NA, se = NA, pvalue = NA, sample = "donut_2pp"),
         file.path(out_dir, "donut_did.csv"))
})

# ==============================================================================
# 3. Leave-One-Canton-Out
# ==============================================================================

cat("\n--- 3. Leave-one-canton-out ---\n")

cantons_with_treated <- sort(unique(panel[treated == 1]$canton_id))
cat(sprintf("  Cantons with treated municipalities: %s\n",
            paste(cantons_with_treated, collapse = ", ")))

loco_results <- rbindlist(lapply(cantons_with_treated, function(ct) {
  tryCatch({
    subset_data <- panel[canton_id != ct]
    # Ensure there are still treated and control units
    if (uniqueN(subset_data[treated == 1]$gem_id) < 5 ||
        uniqueN(subset_data[treated == 0]$gem_id) < 5) {
      cat(sprintf("  Drop %s: too few treated/control units remaining, skipped\n", ct))
      return(data.table(canton_dropped = ct, coef = NA_real_,
                        se = NA_real_, pvalue = NA_real_,
                        n_treated = uniqueN(subset_data[treated == 1]$gem_id),
                        n_control = uniqueN(subset_data[treated == 0]$gem_id)))
    }
    mod <- feols(vacancy_rate ~ treated:post | gem_id + year,
                 data = subset_data, cluster = ~canton_id)
    res <- extract_did(mod)
    res[, `:=`(canton_dropped = ct,
               n_treated = uniqueN(subset_data[treated == 1]$gem_id),
               n_control = uniqueN(subset_data[treated == 0]$gem_id))]
    cat(sprintf("  Drop %s: coef = %.4f, se = %.4f, p = %.3f (T=%d, C=%d)\n",
                ct, res$coef, res$se, res$pvalue, res$n_treated, res$n_control))
    res
  }, error = function(e) {
    cat(sprintf("  Drop %s: ERROR — %s\n", ct, conditionMessage(e)))
    data.table(canton_dropped = ct, coef = NA_real_, se = NA_real_,
               pvalue = NA_real_, n_treated = NA_integer_, n_control = NA_integer_)
  })
}))

setcolorder(loco_results, c("canton_dropped", "coef", "se", "pvalue",
                            "n_treated", "n_control"))
fwrite(loco_results, file.path(out_dir, "leave_one_canton_out.csv"))
cat("  Saved leave_one_canton_out.csv\n")

# ==============================================================================
# 4. Randomization Inference
# ==============================================================================

cat("\n--- 4. Randomization inference (1000 permutations) ---\n")

tryCatch({
  # Real estimate
  mod_real <- feols(vacancy_rate ~ treated:post | gem_id + year,
                    data = panel, cluster = ~canton_id)
  real_coef <- extract_did(mod_real)$coef
  cat(sprintf("  Real coefficient: %.4f\n", real_coef))

  set.seed(42)
  n_perms <- 1000L

  # Municipality-level treatment map
 muni_map <- unique(panel[, .(gem_id, treated, canton_id)])

  perm_coefs <- numeric(n_perms)

  cat("  Running permutations")
  for (i in seq_len(n_perms)) {
    # Shuffle treatment labels within each canton (preserves canton-level proportions)
    muni_perm <- copy(muni_map)
    muni_perm[, treated_perm := sample(treated), by = canton_id]

    shuffled <- merge(panel[, !c("treated"), with = FALSE],
                      muni_perm[, .(gem_id, treated_perm)],
                      by = "gem_id", all.x = TRUE)
    shuffled[, treat_post_perm := treated_perm * post]

    mod_perm <- feols(vacancy_rate ~ treat_post_perm | gem_id + year,
                      data = shuffled)
    cf <- coef(mod_perm)
    perm_coefs[i] <- ifelse("treat_post_perm" %in% names(cf),
                            cf["treat_post_perm"], NA_real_)

    if (i %% 100 == 0) cat(sprintf(" %d", i))
  }
  cat("\n")

  # RI p-value (two-sided)
  ri_pvalue <- mean(abs(perm_coefs) >= abs(real_coef), na.rm = TRUE)
  cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))

  # Save distribution
  fwrite(data.table(permutation = seq_len(n_perms), coef = perm_coefs),
         file.path(out_dir, "ri_distribution.csv"))

  # Save summary
  fwrite(data.table(
    real_coef  = real_coef,
    ri_pvalue  = ri_pvalue,
    n_perms    = n_perms,
    perm_mean  = mean(perm_coefs, na.rm = TRUE),
    perm_sd    = sd(perm_coefs, na.rm = TRUE),
    perm_q025  = quantile(perm_coefs, 0.025, na.rm = TRUE),
    perm_q975  = quantile(perm_coefs, 0.975, na.rm = TRUE)
  ), file.path(out_dir, "ri_summary.csv"))

  cat("  Saved ri_distribution.csv and ri_summary.csv\n")
}, error = function(e) {
  cat(sprintf("  ERROR — %s\n", conditionMessage(e)))
  fwrite(data.table(permutation = NA, coef = NA),
         file.path(out_dir, "ri_distribution.csv"))
  fwrite(data.table(real_coef = NA, ri_pvalue = NA, n_perms = NA,
                    perm_mean = NA, perm_sd = NA, perm_q025 = NA, perm_q975 = NA),
         file.path(out_dir, "ri_summary.csv"))
})

# ==============================================================================
# 5. Wild Cluster Bootstrap
# ==============================================================================

cat("\n--- 5. Wild cluster bootstrap ---\n")

tryCatch({
  # Re-estimate main specification
  mod_main <- feols(vacancy_rate ~ treated:post | gem_id + year,
                    data = panel, cluster = ~canton_id)

  boot_result <- boottest(mod_main,
                          param    = "treated:post",
                          clustid  = "canton_id",
                          B        = 999,
                          type     = "webb")

  # Extract results
  boot_ci   <- boot_result$conf_int
  boot_pval <- boot_result$p_val
  boot_t    <- boot_result$teststat

  boot_out <- data.table(
    param        = "treated:post",
    coef         = coef(mod_main)["treated:post"],
    boot_pvalue  = boot_pval,
    boot_t_stat  = boot_t,
    boot_ci_low  = boot_ci[1],
    boot_ci_high = boot_ci[2],
    B            = 999,
    type         = "webb"
  )

  cat(sprintf("  Boot p-value: %.4f, CI: [%.4f, %.4f]\n",
              boot_pval, boot_ci[1], boot_ci[2]))

  fwrite(boot_out, file.path(out_dir, "wild_bootstrap.csv"))
  cat("  Saved wild_bootstrap.csv\n")
}, error = function(e) {
  cat(sprintf("  ERROR — %s\n", conditionMessage(e)))
  fwrite(data.table(param = "treated:post", coef = NA, boot_pvalue = NA,
                    boot_t_stat = NA, boot_ci_low = NA, boot_ci_high = NA,
                    B = 999, type = "webb"),
         file.path(out_dir, "wild_bootstrap.csv"))
})

# ==============================================================================
# 6. Alternative Treatment Timing (ZWG 2016)
# ==============================================================================

cat("\n--- 6. Alternative treatment timing (ZWG 2016) ---\n")

tryCatch({
  panel[, post_2016 := as.integer(year >= 2016)]

  mod_2016 <- feols(vacancy_rate ~ treated:post_2016 | gem_id + year,
                    data = panel, cluster = ~canton_id)
  res_2016 <- extract_did(mod_2016, "treated.*post_2016")
  res_2016[, treatment_year := 2016L]

  # Also re-run with baseline 2013 for direct comparison
  mod_2013 <- feols(vacancy_rate ~ treated:post | gem_id + year,
                    data = panel, cluster = ~canton_id)
  res_2013 <- extract_did(mod_2013)
  res_2013[, treatment_year := 2013L]

  alt_timing <- rbind(res_2013, res_2016)
  setcolorder(alt_timing, c("treatment_year", "coef", "se", "pvalue"))

  cat(sprintf("  2013: coef = %.4f, p = %.3f\n", res_2013$coef, res_2013$pvalue))
  cat(sprintf("  2016: coef = %.4f, p = %.3f\n", res_2016$coef, res_2016$pvalue))

  fwrite(alt_timing, file.path(out_dir, "alt_timing.csv"))
  cat("  Saved alt_timing.csv\n")

  # Clean up
  panel[, post_2016 := NULL]
}, error = function(e) {
  cat(sprintf("  ERROR — %s\n", conditionMessage(e)))
  fwrite(data.table(treatment_year = NA, coef = NA, se = NA, pvalue = NA),
         file.path(out_dir, "alt_timing.csv"))
})

# ==============================================================================
# 7. Continuous Treatment Intensity
# ==============================================================================

cat("\n--- 7. Continuous treatment intensity ---\n")

tryCatch({
  mod_cont <- feols(vacancy_rate ~ second_home_share:post | gem_id + year,
                    data = panel, cluster = ~canton_id)
  res_cont <- extract_did(mod_cont, "second_home_share.*post")
  res_cont[, specification := "continuous_share"]

  cat(sprintf("  coef = %.6f, se = %.6f, p = %.3f\n",
              res_cont$coef, res_cont$se, res_cont$pvalue))

  fwrite(res_cont, file.path(out_dir, "continuous_treatment.csv"))
  cat("  Saved continuous_treatment.csv\n")
}, error = function(e) {
  cat(sprintf("  ERROR — %s\n", conditionMessage(e)))
  fwrite(data.table(coef = NA, se = NA, pvalue = NA, specification = "continuous_share"),
         file.path(out_dir, "continuous_treatment.csv"))
})

# ==============================================================================
# 8. Placebo Outcome: Non-Residential Employment
# ==============================================================================

cat("\n--- 8. Placebo outcome tests ---\n")

# Test outcomes that should NOT be affected by the second-home construction ban
# (or should be affected differently as a falsification check)
placebo_outcomes <- c("log_emp_total", "log_emp_secondary", "log_emp_tertiary")

# log_emp_secondary and log_emp_tertiary serve as sector-specific placebo outcomes

placebo_results <- rbindlist(lapply(placebo_outcomes, function(yvar) {
  tryCatch({
    # Check variable exists and has non-missing values
    if (!(yvar %in% names(panel))) {
      cat(sprintf("  %s: not available, skipped\n", yvar))
      return(data.table(outcome = yvar, coef = NA_real_, se = NA_real_,
                        pvalue = NA_real_, n_obs = NA_integer_))
    }
    dt <- panel[!is.na(get(yvar))]
    if (nrow(dt) < 100) {
      cat(sprintf("  %s: too few non-missing obs (%d), skipped\n", yvar, nrow(dt)))
      return(data.table(outcome = yvar, coef = NA_real_, se = NA_real_,
                        pvalue = NA_real_, n_obs = nrow(dt)))
    }

    fml <- as.formula(paste0(yvar, " ~ treated:post | gem_id + year"))
    mod <- feols(fml, data = dt, cluster = ~canton_id)
    res <- extract_did(mod)
    res[, `:=`(outcome = yvar, n_obs = nrow(dt))]
    cat(sprintf("  %s: coef = %.4f, se = %.4f, p = %.3f (n = %d)\n",
                yvar, res$coef, res$se, res$pvalue, nrow(dt)))
    res
  }, error = function(e) {
    cat(sprintf("  %s: ERROR — %s\n", yvar, conditionMessage(e)))
    data.table(outcome = yvar, coef = NA_real_, se = NA_real_,
               pvalue = NA_real_, n_obs = NA_integer_)
  })
}))

setcolorder(placebo_results, c("outcome", "coef", "se", "pvalue", "n_obs"))
fwrite(placebo_results, file.path(out_dir, "placebo_outcome.csv"))
cat("  Saved placebo_outcome.csv\n")

# ==============================================================================
# 9. Rambachan & Roth (HonestDiD) Sensitivity
# ==============================================================================

cat("\n--- 9. HonestDiD sensitivity analysis ---\n")

tryCatch({
  # Event-study specification for HonestDiD
  # Need relative-time indicators; sunab() in fixest provides this
  # Determine treatment year per municipality
  treatment_year <- 2013L

  # Create relative time variable
  panel[, rel_time := year - treatment_year]

  # Event-study with sunab for staggered adoption (all treated at 2013 here)
  mod_es <- feols(vacancy_rate ~ sunab(treated * treatment_year, year) |
                    gem_id + year,
                  data = panel[, treatment_year_var := fifelse(treated == 1, treatment_year, 10000L)],
                  cluster = ~canton_id)

  # If sunab doesn't work with this structure, fall back to i() syntax
  if (inherits(mod_es, "try-error") || length(coef(mod_es)) == 0) {
    stop("sunab specification failed, falling back to i() syntax")
  }

  # HonestDiD: extract pre-period coefficients and variance-covariance matrix
  # Use the relative magnitude approach (Delta^{RM})
  honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat        = coef(mod_es),
    sigma          = vcov(mod_es),
    numPrePeriods  = sum(grepl("year::-", names(coef(mod_es)))),
    numPostPeriods = sum(grepl("year::(?!-)", names(coef(mod_es)), perl = TRUE)),
    Mbarvec        = seq(0, 2, by = 0.5)
  )

  honest_dt <- as.data.table(honest_result)
  cat(sprintf("  HonestDiD: %d sensitivity rows computed\n", nrow(honest_dt)))
  print(honest_dt)

  fwrite(honest_dt, file.path(out_dir, "honest_did.csv"))
  cat("  Saved honest_did.csv\n")

  # Clean up
  panel[, c("rel_time", "treatment_year_var") := NULL]

}, error = function(e) {
  cat(sprintf("  HonestDiD (sunab) failed: %s\n", conditionMessage(e)))
  cat("  Attempting fallback with i() event-study syntax...\n")

  tryCatch({
    # Fallback: manual event-study with i() and explicit relative time
    panel[, rel_time := year - 2013L]

    # Bin endpoints to avoid singletons
    min_rt <- min(panel$rel_time)
    max_rt <- max(panel$rel_time)
    panel[, rel_time_binned := pmax(pmin(rel_time, max_rt), min_rt)]

    # Event study: drop rel_time == -1 as reference
    mod_es2 <- feols(vacancy_rate ~ i(rel_time_binned, treated, ref = -1) |
                       gem_id + year,
                     data = panel, cluster = ~canton_id)

    cf_names <- names(coef(mod_es2))
    pre_idx  <- grep("rel_time_binned::-", cf_names)
    post_idx <- grep("rel_time_binned::[0-9]", cf_names)

    if (length(pre_idx) == 0 || length(post_idx) == 0) {
      stop("Could not identify pre/post coefficients")
    }

    n_pre  <- length(pre_idx)
    n_post <- length(post_idx)

    # Reorder: pre periods (ascending) then post periods (ascending)
    all_idx     <- c(pre_idx, post_idx)
    betahat_all <- coef(mod_es2)[all_idx]
    sigma_all   <- vcov(mod_es2)[all_idx, all_idx]

    honest_result2 <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat        = betahat_all,
      sigma          = sigma_all,
      numPrePeriods  = n_pre,
      numPostPeriods = n_post,
      Mbarvec        = seq(0, 2, by = 0.5)
    )

    honest_dt2 <- as.data.table(honest_result2)
    cat(sprintf("  HonestDiD (fallback): %d sensitivity rows computed\n",
                nrow(honest_dt2)))
    print(honest_dt2)

    fwrite(honest_dt2, file.path(out_dir, "honest_did.csv"))
    cat("  Saved honest_did.csv\n")

    panel[, c("rel_time", "rel_time_binned") := NULL]

  }, error = function(e2) {
    cat(sprintf("  HonestDiD fallback also failed: %s\n", conditionMessage(e2)))
    cat("  Saving empty honest_did.csv\n")
    fwrite(data.table(Mbar = NA, lb = NA, ub = NA, method = NA),
           file.path(out_dir, "honest_did.csv"))
    # Clean up if columns were created
    if ("rel_time" %in% names(panel)) panel[, rel_time := NULL]
    if ("rel_time_binned" %in% names(panel)) panel[, rel_time_binned := NULL]
  })
})

# ==============================================================================
# Summary
# ==============================================================================

cat("\n========== Robustness checks complete ==========\n")

output_files <- c("placebo_timing.csv", "donut_did.csv",
                  "leave_one_canton_out.csv", "ri_distribution.csv",
                  "ri_summary.csv", "wild_bootstrap.csv",
                  "alt_timing.csv", "continuous_treatment.csv",
                  "placebo_outcome.csv", "honest_did.csv")

for (f in output_files) {
  fp <- file.path(out_dir, f)
  if (file.exists(fp)) {
    sz <- file.info(fp)$size
    cat(sprintf("  [OK] %s (%s bytes)\n", f, format(sz, big.mark = ",")))
  } else {
    cat(sprintf("  [MISSING] %s\n", f))
  }
}

cat("\nDone.\n")
