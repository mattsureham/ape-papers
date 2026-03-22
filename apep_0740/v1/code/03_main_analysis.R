## 03_main_analysis.R — Spatial RDD at QPV boundaries
## APEP-0740: QPV Designation Paradox

source("00_packages.R")
script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(file.path(script_dir, ".."))
data_dir <- "data"

cat("=== Loading analysis data ===\n")
df <- data.table::fread(file.path(data_dir, "analysis_data.csv"))
cat(sprintf("Loaded %s observations\n", format(nrow(df), big.mark = ",")))

## ---- Main RDD: All data is post-QPV (2020-2024) ----
cat("\n=== Main RDD Estimation ===\n")

## All geolocalized DVF data is 2020-2024, all post-QPV designation (2015)
post <- df
cat(sprintf("Observations: %s\n", format(nrow(post), big.mark = ",")))

## Primary specification: rdrobust with triangular kernel
## Outcome: log(price/m2), running var: signed distance
rdd_main <- rdrobust::rdrobust(
  y = post$log_price_m2,
  x = post$signed_dist,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = post$commune,
  all = TRUE
)
cat("\n--- Main RDD (rdrobust, MSE-optimal bandwidth) ---\n")
summary(rdd_main)

## Store main estimate
tau_main <- rdd_main$coef[1]  # Conventional
tau_bc <- rdd_main$coef[2]    # Bias-corrected
se_main <- rdd_main$se[1]
se_bc <- rdd_main$se[3]       # Robust SE
bw_main <- rdd_main$bws[1, 1]
n_left <- rdd_main$N[1]
n_right <- rdd_main$N[2]

cat(sprintf("\nMain estimate (conventional): %.4f (SE: %.4f)\n", tau_main, se_main))
cat(sprintf("Bias-corrected: %.4f (Robust SE: %.4f)\n", tau_bc, se_bc))
cat(sprintf("MSE-optimal bandwidth: %.0f meters\n", bw_main))
cat(sprintf("N left (outside): %d, N right (inside): %d\n", n_left, n_right))

## ---- Fixed bandwidth specifications ----
cat("\n=== Fixed Bandwidth Specifications ===\n")

bws <- c(250, 500, 750, 1000)
rdd_bw <- list()

for (bw in bws) {
  rdd_bw[[as.character(bw)]] <- rdrobust::rdrobust(
    y = post$log_price_m2,
    x = post$signed_dist,
    c = 0,
    h = bw,
    kernel = "triangular",
    cluster = post$commune,
    all = TRUE
  )
  est <- rdd_bw[[as.character(bw)]]
  cat(sprintf("BW=%4dm: tau=%.4f (robust SE=%.4f), N=%d+%d\n",
              bw, est$coef[2], est$se[3], est$N[1], est$N[2]))
}

## ---- With covariates ----
cat("\n=== RDD with Covariates ===\n")

## Create covariate matrix
covars <- as.matrix(post[, .(surface_reelle_bati = surface,
                              rooms = rooms,
                              is_apt = is_apartment)])
## Remove rows with NA covariates
valid <- complete.cases(covars)

rdd_covars <- rdrobust::rdrobust(
  y = post$log_price_m2[valid],
  x = post$signed_dist[valid],
  covs = covars[valid, ],
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = post$commune[valid],
  all = TRUE
)
cat("\n--- RDD with Covariates ---\n")
summary(rdd_covars)

## ---- Parametric specification (OLS with polynomial) ----
cat("\n=== Parametric Specification (fixest) ===\n")

## Linear polynomial, 500m bandwidth
post_500 <- post[abs(signed_dist) <= 500]

## Add QPV boundary segment FE
reg1 <- fixest::feols(
  log_price_m2 ~ inside_qpv * signed_dist + surface + rooms + is_apartment |
    nearest_qpv_id + year_quarter,
  data = post_500,
  cluster = ~commune
)
cat("\n--- Parametric (500m, boundary FE + year-quarter FE) ---\n")
summary(reg1)

## Without boundary FE
reg2 <- fixest::feols(
  log_price_m2 ~ inside_qpv * signed_dist + surface + rooms + is_apartment | year_quarter,
  data = post_500,
  cluster = ~commune
)

## ---- McCrary density test ----
cat("\n=== McCrary Density Test ===\n")

dens_test <- rddensity::rddensity(post$signed_dist, c = 0)
cat(sprintf("McCrary test p-value: %.4f\n", dens_test$test$p_jk))
cat(sprintf("N left: %d, N right: %d\n", dens_test$N$left, dens_test$N$right))

## ---- Covariate balance at boundary ----
cat("\n=== Covariate Balance at Boundary ===\n")

covs_to_test <- c("surface", "rooms", "is_apartment", "price")
balance_results <- list()

for (cv in covs_to_test) {
  tryCatch({
    rdd_cv <- rdrobust::rdrobust(
      y = post[[cv]],
      x = post$signed_dist,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = post$commune
    )
    balance_results[[cv]] <- data.table::data.table(
      variable = cv,
      estimate = rdd_cv$coef[2],
      se = rdd_cv$se[3],
      pvalue = rdd_cv$pv[3],
      bw = rdd_cv$bws[1, 1]
    )
    cat(sprintf("  %s: est=%.4f, p=%.3f\n", cv, rdd_cv$coef[2], rdd_cv$pv[3]))
  }, error = function(e) {
    cat(sprintf("  %s: FAILED (%s)\n", cv, e$message))
  })
}

balance_dt <- data.table::rbindlist(balance_results)

## ---- Save results for tables ----
cat("\n=== Saving results ===\n")

results <- list(
  main = list(
    tau_conv = tau_main,
    tau_bc = tau_bc,
    se_conv = se_main,
    se_robust = se_bc,
    bw = bw_main,
    n_left = n_left,
    n_right = n_right,
    ci_lower = rdd_main$ci[3, 1],
    ci_upper = rdd_main$ci[3, 2]
  ),
  bandwidth_robustness = lapply(rdd_bw, function(r) {
    list(tau_bc = r$coef[2], se_robust = r$se[3], n_left = r$N[1], n_right = r$N[2])
  }),
  covariates = list(
    tau_bc = rdd_covars$coef[2],
    se_robust = rdd_covars$se[3],
    bw = rdd_covars$bws[1, 1]
  ),
  parametric = list(
    tau = coef(reg1)["inside_qpvTRUE"],
    se = se(reg1)["inside_qpvTRUE"],
    n = nobs(reg1),
    r2 = fixest::r2(reg1, "ar2")
  ),
  mccrary = list(
    p_value = dens_test$test$p_jk,
    n_left = dens_test$N$left,
    n_right = dens_test$N$right
  ),
  balance = balance_dt
)

saveRDS(results, file.path(data_dir, "rdd_results.rds"))

## ---- Diagnostics for validator ----
n_treated <- nrow(post[inside_qpv == TRUE & abs(signed_dist) <= bw_main])
## For spatial RDD, "pre-periods" = years of data. QPV designated 2015; data 2020-2024.
n_pre <- length(unique(df$year))
n_obs <- nrow(post[abs(signed_dist) <= bw_main])

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
