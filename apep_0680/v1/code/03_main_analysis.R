## 03_main_analysis.R — Spatial RDD estimation
## apep_0680: ZFE Spatial RDD on Property Values

source("code/00_packages.R")

cat("=== Main Analysis: Spatial RDD ===\n\n")

dvf <- readRDS("data/analysis_data.rds")

# ---- 1. Post-ZFE spatial RDD (primary specification) ----
# Focus on post-September 2022 transactions within analysis bandwidth
post <- dvf[post == 1 & in_sample_2km == TRUE]
cat(sprintf("Post-ZFE sample (2km): %s transactions\n", format(nrow(post), big.mark = ",")))

# Primary RDD: rdrobust with MSE-optimal bandwidth
cat("\n--- Primary RDD: log(price/m²) on signed distance ---\n")
rdd_main <- rdrobust(
  y = post$log_price_m2,
  x = post$signed_dist_km,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)
summary(rdd_main)

# Store key results
tau_main <- rdd_main$coef[1]  # Conventional estimate
se_main  <- rdd_main$se[3]    # Robust SE
ci_main  <- rdd_main$ci[3, ]  # Robust CI
bw_main  <- rdd_main$bws[1, 1]  # Bandwidth (left = right for mserd)
n_eff    <- rdd_main$N_h[1] + rdd_main$N_h[2]  # Effective sample

cat(sprintf("\nPrimary RDD estimate: %.4f (robust SE: %.4f)\n", tau_main, se_main))
cat(sprintf("Robust 95%% CI: [%.4f, %.4f]\n", ci_main[1], ci_main[2]))
cat(sprintf("MSE-optimal bandwidth: %.3f km\n", bw_main))
cat(sprintf("Effective N: %d (left: %d, right: %d)\n",
            n_eff, rdd_main$N_h[1], rdd_main$N_h[2]))

# ---- 2. RDD with covariates (preferred specification) ----
cat("\n--- RDD with covariates ---\n")
# Use fixest for covariate-adjusted specification
post_1km <- dvf[post == 1 & in_sample_1km == TRUE]

# Polynomial in distance + covariates
rdd_cov <- feols(
  log_price_m2 ~ inside_zfe * poly(signed_dist_km, 1) +
    surface_reelle_bati + rooms + is_apartment | year_quarter,
  data = post_1km,
  vcov = "HC1"
)
cat("Covariate-adjusted RDD (1km bandwidth, linear, HC1):\n")
summary(rdd_cov)

# ---- 3. Pre-ZFE placebo test ----
cat("\n--- Pre-ZFE Placebo Test ---\n")
pre <- dvf[post == 0 & in_sample_2km == TRUE]
cat(sprintf("Pre-ZFE sample (2km): %s transactions\n", format(nrow(pre), big.mark = ",")))

rdd_placebo <- rdrobust(
  y = pre$log_price_m2,
  x = pre$signed_dist_km,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)
summary(rdd_placebo)

tau_placebo <- rdd_placebo$coef[1]
se_placebo  <- rdd_placebo$se[3]
cat(sprintf("\nPlacebo estimate: %.4f (robust SE: %.4f)\n", tau_placebo, se_placebo))

# ---- 4. Phase decomposition ----
cat("\n--- Phase Decomposition ---\n")

# Phase 1: Sep 2022 - Dec 2023 (Crit'Air 5 only)
p1 <- dvf[period == "post_phase1" & in_sample_2km == TRUE]
rdd_p1 <- rdrobust(y = p1$log_price_m2, x = p1$signed_dist_km, c = 0,
                   kernel = "triangular", p = 1, bwselect = "mserd")
cat(sprintf("Phase 1 (Crit'Air 5): τ = %.4f (robust SE = %.4f), N_eff = %d\n",
            rdd_p1$coef[1], rdd_p1$se[3], sum(rdd_p1$N_h)))

# Phase 2: Jan 2024+ (Crit'Air 3)
p2 <- dvf[period == "post_phase2" & in_sample_2km == TRUE]
if (nrow(p2) >= 100) {
  rdd_p2 <- rdrobust(y = p2$log_price_m2, x = p2$signed_dist_km, c = 0,
                     kernel = "triangular", p = 1, bwselect = "mserd")
  cat(sprintf("Phase 2 (Crit'Air 3): τ = %.4f (robust SE = %.4f), N_eff = %d\n",
              rdd_p2$coef[1], rdd_p2$se[3], sum(rdd_p2$N_h)))
} else {
  cat(sprintf("Phase 2: insufficient observations (%d)\n", nrow(p2)))
  rdd_p2 <- NULL
}

# ---- 5. Heterogeneity: apartments vs. houses ----
cat("\n--- Heterogeneity by Property Type ---\n")
post_apt <- dvf[post == 1 & in_sample_2km == TRUE & is_apartment == 1]
post_house <- dvf[post == 1 & in_sample_2km == TRUE & is_apartment == 0]

rdd_apt <- rdrobust(y = post_apt$log_price_m2, x = post_apt$signed_dist_km,
                    c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
cat(sprintf("Apartments: τ = %.4f (robust SE = %.4f), N_eff = %d\n",
            rdd_apt$coef[1], rdd_apt$se[3], sum(rdd_apt$N_h)))

if (nrow(post_house) >= 50) {
  rdd_house <- rdrobust(y = post_house$log_price_m2, x = post_house$signed_dist_km,
                        c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
  cat(sprintf("Houses: τ = %.4f (robust SE = %.4f), N_eff = %d\n",
              rdd_house$coef[1], rdd_house$se[3], sum(rdd_house$N_h)))
} else {
  cat(sprintf("Houses: insufficient observations (%d)\n", nrow(post_house)))
  rdd_house <- NULL
}

# ---- 6. Difference-in-discontinuities (DiD at boundary) ----
cat("\n--- Difference-in-Discontinuities ---\n")
# Compare post vs pre discontinuity
# This controls for any pre-existing boundary effect
all_1km <- dvf[in_sample_1km == TRUE]

did_boundary <- feols(
  log_price_m2 ~ inside_zfe * post * poly(signed_dist_km, 1) +
    surface_reelle_bati + rooms + is_apartment | year_quarter,
  data = all_1km,
  vcov = "HC1"
)
cat("Difference-in-Discontinuities (inside_zfe × post):\n")
summary(did_boundary)

# ---- 7. Save results for tables ----
results <- list(
  rdd_main = list(
    tau = rdd_main$coef[1],
    se_robust = rdd_main$se[3],
    ci_lower = rdd_main$ci[3, 1],
    ci_upper = rdd_main$ci[3, 2],
    bw = bw_main,
    n_eff = n_eff,
    n_left = rdd_main$N_h[1],
    n_right = rdd_main$N_h[2]
  ),
  rdd_cov = list(
    tau = coef(rdd_cov)["inside_zfeTRUE"],
    se = se(rdd_cov)["inside_zfeTRUE"]
  ),
  placebo = list(
    tau = rdd_placebo$coef[1],
    se_robust = rdd_placebo$se[3]
  ),
  phase1 = list(tau = rdd_p1$coef[1], se = rdd_p1$se[3]),
  phase2 = if (!is.null(rdd_p2)) list(tau = rdd_p2$coef[1], se = rdd_p2$se[3]) else NULL,
  apartments = list(tau = rdd_apt$coef[1], se = rdd_apt$se[3]),
  houses = if (!is.null(rdd_house)) list(tau = rdd_house$coef[1], se = rdd_house$se[3]) else NULL,
  did_boundary = list(
    tau = coef(did_boundary)["inside_zfeTRUE:post"],
    se = se(did_boundary)["inside_zfeTRUE:post"]
  )
)

saveRDS(results, "data/main_results.rds")
saveRDS(rdd_cov, "data/rdd_cov_model.rds")
saveRDS(did_boundary, "data/did_boundary_model.rds")

# ---- 8. Write diagnostics.json for validator ----
sample <- dvf[in_sample_1km == TRUE & post == 1]
diagnostics <- list(
  n_treated = sum(sample$inside_zfe),
  n_pre = length(unique(dvf[period == "pre"]$year_quarter)),
  n_obs = nrow(sample)
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
