## ============================================================
## 04_robustness.R — Robustness checks
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir <- "../data/"
analysis <- fread(paste0(data_dir, "analysis.csv"))
annual   <- fread(paste0(data_dir, "annual_panel.csv"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ---------------------------------------------------------
## 1. McCrary density test
## ---------------------------------------------------------
cat("1. McCrary density test (manipulation of running variable)\n")

rv_vals <- analysis[!is.na(rv_centered)]$rv_centered

dens_test <- rddensity(rv_vals, c = 0)
cat("  Density test p-value:", round(dens_test$test$p_jk, 4), "\n")

dens_results <- data.table(
  test = "McCrary_density",
  statistic = dens_test$test$t_jk,
  p_value = dens_test$test$p_jk,
  n_left = dens_test$N[1],
  n_right = dens_test$N[2]
)

fwrite(dens_results, paste0(data_dir, "density_test.csv"))

## ---------------------------------------------------------
## 2. Covariate balance at threshold
## ---------------------------------------------------------
cat("\n2. Covariate balance tests\n")

# Test whether pre-determined covariates are smooth at threshold
covariates <- c("running_var_0713", "mfg_share_pre", "emp_pre")
covariate_labels <- c("GDP/cap 2002-2004 avg", "Manufacturing share (pre)",
                       "Employment rate (pre)")

bal_results <- list()
for (i in seq_along(covariates)) {
  cov <- covariates[i]
  d <- analysis[!is.na(rv_centered) & !is.na(get(cov))]

  tryCatch({
    bal_rdd <- rdrobust(y = d[[cov]], x = d$rv_centered, c = 0)
    bal_results[[cov]] <- data.table(
      covariate = covariate_labels[i],
      coef = bal_rdd$coef[1],
      se = bal_rdd$se[3],
      p_value = bal_rdd$pv[3],
      bw = bal_rdd$bws[1, 1]
    )
    cat("  ", covariate_labels[i], ": coef=", round(bal_rdd$coef[1], 3),
        " (p=", round(bal_rdd$pv[3], 3), ")\n")
  }, error = function(e) {
    cat("  ", covariate_labels[i], ": failed\n")
  })
}

bal_dt <- rbindlist(bal_results, fill = TRUE)
fwrite(bal_dt, paste0(data_dir, "balance_tests.csv"))

## ---------------------------------------------------------
## 3. Donut hole specifications
## ---------------------------------------------------------
cat("\n3. Donut hole specifications\n")

rdd_data <- analysis[!is.na(rv_centered) & !is.na(delta_gdp)]

donut_results <- list()
for (d in c(1, 2, 3)) {
  sub <- rdd_data[abs(rv_centered) > d]

  tryCatch({
    rdd_donut <- rdrobust(y = sub$delta_gdp, x = sub$rv_centered, c = 0)
    donut_results[[as.character(d)]] <- data.table(
      donut = d,
      coef = rdd_donut$coef[1],
      se = rdd_donut$se[3],
      ci_lower = rdd_donut$ci[3, 1],
      ci_upper = rdd_donut$ci[3, 2],
      p_value = rdd_donut$pv[3],
      bw = rdd_donut$bws[1, 1],
      n = rdd_donut$N[1] + rdd_donut$N[2]
    )
    cat("  Donut ±", d, "pp: coef=", round(rdd_donut$coef[1], 3),
        " (p=", round(rdd_donut$pv[3], 3), ")\n")
  }, error = function(e) {
    cat("  Donut ±", d, "pp: failed\n")
  })
}

donut_dt <- rbindlist(donut_results, fill = TRUE)
fwrite(donut_dt, paste0(data_dir, "donut_results.csv"))

## ---------------------------------------------------------
## 4. Placebo cutoffs
## ---------------------------------------------------------
cat("\n4. Placebo cutoff tests\n")

placebo_cuts <- c(-20, -15, -10, -5, 5, 10, 15, 20)  # relative to 75%
placebo_results <- list()

for (pc in placebo_cuts) {
  sub <- rdd_data[!is.na(rv_centered)]

  tryCatch({
    rdd_placebo <- rdrobust(y = sub$delta_gdp, x = sub$rv_centered, c = pc)
    placebo_results[[as.character(pc)]] <- data.table(
      cutoff = 75 + pc,
      cutoff_centered = pc,
      coef = rdd_placebo$coef[1],
      se = rdd_placebo$se[3],
      p_value = rdd_placebo$pv[3]
    )
    cat("  Cutoff at ", 75 + pc, "%: coef=", round(rdd_placebo$coef[1], 3),
        " (p=", round(rdd_placebo$pv[3], 3), ")\n")
  }, error = function(e) {
    cat("  Cutoff at ", 75 + pc, "%: failed\n")
  })
}

placebo_dt <- rbindlist(placebo_results, fill = TRUE)
fwrite(placebo_dt, paste0(data_dir, "placebo_cutoffs.csv"))

## ---------------------------------------------------------
## 5. Leave-one-country-out
## ---------------------------------------------------------
cat("\n5. Leave-one-country-out\n")

countries <- unique(rdd_data$country)
loco_results <- list()

for (ctry in countries) {
  sub <- rdd_data[country != ctry]
  if (nrow(sub) < 20) next

  tryCatch({
    rdd_loco <- rdrobust(y = sub$delta_gdp, x = sub$rv_centered, c = 0)
    loco_results[[ctry]] <- data.table(
      excluded_country = ctry,
      coef = rdd_loco$coef[1],
      se = rdd_loco$se[3],
      p_value = rdd_loco$pv[3],
      n = rdd_loco$N[1] + rdd_loco$N[2]
    )
    cat("  Excl. ", ctry, ": coef=", round(rdd_loco$coef[1], 3),
        " (p=", round(rdd_loco$pv[3], 3), ")\n")
  }, error = function(e) {
    cat("  Excl. ", ctry, ": failed\n")
  })
}

loco_dt <- rbindlist(loco_results, fill = TRUE)
fwrite(loco_dt, paste0(data_dir, "leave_one_country_out.csv"))

## ---------------------------------------------------------
## 6. Multi-cutoff: 90% threshold (transition → more developed)
## ---------------------------------------------------------
cat("\n6. Multi-cutoff replication at 90% threshold\n")

rdd_data_90 <- analysis[!is.na(running_var) & !is.na(delta_gdp)]
rdd_data_90[, rv_90 := running_var - 90]

tryCatch({
  rdd_90 <- rdrobust(y = rdd_data_90$delta_gdp, x = rdd_data_90$rv_90, c = 0)
  cat("  90% threshold RDD:\n")
  summary(rdd_90)

  rdd_90_result <- data.table(
    cutoff = 90,
    coef = rdd_90$coef[1],
    se = rdd_90$se[3],
    p_value = rdd_90$pv[3],
    bw = rdd_90$bws[1, 1],
    n = rdd_90$N[1] + rdd_90$N[2]
  )
  fwrite(rdd_90_result, paste0(data_dir, "rdd_90_threshold.csv"))
}, error = function(e) {
  cat("  90% threshold failed:", e$message, "\n")
})

## ---------------------------------------------------------
## 7. Polynomial order sensitivity
## ---------------------------------------------------------
cat("\n7. Polynomial order sensitivity\n")

poly_results <- list()
for (p in 1:3) {
  tryCatch({
    rdd_p <- rdrobust(y = rdd_data$delta_gdp, x = rdd_data$rv_centered, c = 0, p = p)
    poly_results[[as.character(p)]] <- data.table(
      poly_order = p,
      coef = rdd_p$coef[1],
      se = rdd_p$se[3],
      p_value = rdd_p$pv[3],
      bw = rdd_p$bws[1, 1]
    )
    cat("  p=", p, ": coef=", round(rdd_p$coef[1], 3),
        " (SE=", round(rdd_p$se[3], 3), ")\n")
  }, error = function(e) {
    cat("  p=", p, ": failed\n")
  })
}

poly_dt <- rbindlist(poly_results, fill = TRUE)
fwrite(poly_dt, paste0(data_dir, "polynomial_sensitivity.csv"))

## ---------------------------------------------------------
## 8. Pre-treatment placebo: 2000-2006 → 2007-2013 transition
## ---------------------------------------------------------
cat("\n8. Pre-treatment placebo (2000-2006 → 2007-2013)\n")

# Use 2002-2004 running variable (which determined 2007-2013 eligibility)
# Test: did crossing 75% based on 2002-2004 data predict GDP growth 2000-2006?
gdp_pct_raw <- fread(paste0(data_dir, "gdp_pct_eu27.csv"))

gdp_preplacebo <- gdp_pct_raw[, .(
  gdp_pre = mean(values[time %in% 2000:2006], na.rm = TRUE),
  gdp_post = mean(values[time %in% 2007:2013], na.rm = TRUE)
), by = .(geo)]
gdp_preplacebo[, delta_pre := gdp_post - gdp_pre]

placebo_panel <- merge(analysis[, .(geo, running_var_0713, rv_0713_centered = running_var_0713 - 75)],
  gdp_preplacebo, by = "geo")

placebo_panel <- placebo_panel[!is.na(rv_0713_centered) & !is.na(delta_pre)]

tryCatch({
  rdd_preplacebo <- rdrobust(y = placebo_panel$delta_pre,
    x = placebo_panel$rv_0713_centered, c = 0)
  cat("  Pre-treatment placebo:\n")
  summary(rdd_preplacebo)

  preplacebo_result <- data.table(
    test = "pre_treatment_placebo",
    coef = rdd_preplacebo$coef[1],
    se = rdd_preplacebo$se[3],
    p_value = rdd_preplacebo$pv[3]
  )
  fwrite(preplacebo_result, paste0(data_dir, "pre_placebo.csv"))
}, error = function(e) {
  cat("  Pre-treatment placebo failed:", e$message, "\n")
})

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
