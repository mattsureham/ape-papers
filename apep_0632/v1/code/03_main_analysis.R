## 03_main_analysis.R — Main diff-in-disc estimation
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ============================================================
## 1. Restrict sample to metros with active ZFEs
## ============================================================
cat("=== 1. Sample Construction ===\n")

## For the main analysis, restrict to communes near metros that had ZFE
## active before the 2022 presidential election
## This ensures the "control" communes are near the same urban areas
active_metros_2022 <- unique(panel[metro_active_2022 == TRUE, nearest_metro_siren])
cat(sprintf("  Active metro SIRENs (2022): %s\n", paste(active_metros_2022, collapse = ", ")))

## Main sample: communes near active ZFE metros only
main_sample <- panel[nearest_metro_siren %in% active_metros_2022]
cat(sprintf("  Main sample (near active metros): %d communes\n", nrow(main_sample)))
cat(sprintf("  Inside ZFE: %d | Outside: %d\n",
            sum(main_sample$inside_zfe), sum(!main_sample$inside_zfe)))

## ============================================================
## 2. Bandwidth selection and sample cuts
## ============================================================
cat("\n=== 2. Bandwidth Samples ===\n")

bandwidths <- c(3, 5, 7, 10, 15, 20)
for (bw in bandwidths) {
  n <- sum(main_sample$dist_to_boundary_m <= bw * 1000)
  n_in <- sum(main_sample$inside_zfe & main_sample$dist_to_boundary_m <= bw * 1000)
  cat(sprintf("  %2d km: N=%5d (inside=%3d, outside=%4d)\n", bw, n, n_in, n - n_in))
}

## ============================================================
## 3. Main diff-in-disc estimation
## ============================================================
cat("\n=== 3. Main Diff-in-Disc Results ===\n")

## The diff-in-disc specification:
## ΔRN_{c,2017→2022} = α + τ·Inside_c + f(Dist_c) + Inside_c × f(Dist_c) + δ_metro + ε_c
##
## Key outcome: change in RN vote share 2017→2022
## Also test: change in far-right share (Le Pen + Zemmour) 2017→2022
## Also test: change in turnout

## Main specification: local linear, triangular kernel, various bandwidths
results_list <- list()

for (bw in bandwidths) {
  sub <- main_sample[dist_to_boundary_m <= bw * 1000]
  if (nrow(sub) < 20 || sum(sub$inside_zfe) < 5) next

  ## Triangular kernel weights
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]
  sub[w < 0, w := 0]

  ## Local linear with metro FE
  fit_rn <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )

  ## Far-right share (Le Pen + Zemmour)
  fit_fr <- tryCatch(
    feols(delta_farright_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )

  ## Turnout
  fit_to <- tryCatch(
    feols(delta_turnout_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )

  if (!is.null(fit_rn)) {
    coef_rn <- coef(fit_rn)["inside_zfeTRUE"]
    se_rn <- sqrt(vcov(fit_rn)["inside_zfeTRUE", "inside_zfeTRUE"])
    results_list[[paste0("rn_bw", bw)]] <- data.table(
      outcome = "RN share", bw_km = bw, estimate = coef_rn, se = se_rn,
      n = nrow(sub), n_inside = sum(sub$inside_zfe),
      pval = 2 * pnorm(-abs(coef_rn / se_rn))
    )
    cat(sprintf("  RN share, BW=%2dkm: τ̂=%.4f (SE=%.4f), p=%.3f, N=%d (in=%d)\n",
                bw, coef_rn, se_rn, 2 * pnorm(-abs(coef_rn / se_rn)),
                nrow(sub), sum(sub$inside_zfe)))
  }

  if (!is.null(fit_fr)) {
    coef_fr <- coef(fit_fr)["inside_zfeTRUE"]
    se_fr <- sqrt(vcov(fit_fr)["inside_zfeTRUE", "inside_zfeTRUE"])
    results_list[[paste0("fr_bw", bw)]] <- data.table(
      outcome = "Far-right share", bw_km = bw, estimate = coef_fr, se = se_fr,
      n = nrow(sub), n_inside = sum(sub$inside_zfe),
      pval = 2 * pnorm(-abs(coef_fr / se_fr))
    )
    cat(sprintf("  Far-right, BW=%2dkm: τ̂=%.4f (SE=%.4f), p=%.3f\n",
                bw, coef_fr, se_fr, 2 * pnorm(-abs(coef_fr / se_fr))))
  }

  if (!is.null(fit_to)) {
    coef_to <- coef(fit_to)["inside_zfeTRUE"]
    se_to <- sqrt(vcov(fit_to)["inside_zfeTRUE", "inside_zfeTRUE"])
    results_list[[paste0("to_bw", bw)]] <- data.table(
      outcome = "Turnout", bw_km = bw, estimate = coef_to, se = se_to,
      n = nrow(sub), n_inside = sum(sub$inside_zfe),
      pval = 2 * pnorm(-abs(coef_to / se_to))
    )
    cat(sprintf("  Turnout,   BW=%2dkm: τ̂=%.4f (SE=%.4f), p=%.3f\n",
                bw, coef_to, se_to, 2 * pnorm(-abs(coef_to / se_to))))
  }
  cat("\n")
}

results <- rbindlist(results_list)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## ============================================================
## 4. rdrobust estimation (data-driven bandwidth)
## ============================================================
cat("=== 4. rdrobust Estimation ===\n")

## Use rdrobust on the full active-metro sample
## Running variable: signed distance (positive = inside)
## Cutoff: 0

main_sample_complete <- main_sample[!is.na(delta_rn_1722) & !is.na(delta_farright_1722)]

## RN share change
rd_rn <- tryCatch(
  rdrobust(y = main_sample_complete$delta_rn_1722,
           x = main_sample_complete$signed_dist_km,
           c = 0, kernel = "triangular", p = 1, q = 2),
  error = function(e) { cat(sprintf("  rdrobust RN failed: %s\n", e$message)); NULL }
)
if (!is.null(rd_rn)) {
  cat("\n  RN share (rdrobust):\n")
  print(summary(rd_rn))
}

## Far-right share change
rd_fr <- tryCatch(
  rdrobust(y = main_sample_complete$delta_farright_1722,
           x = main_sample_complete$signed_dist_km,
           c = 0, kernel = "triangular", p = 1, q = 2),
  error = function(e) { cat(sprintf("  rdrobust FR failed: %s\n", e$message)); NULL }
)
if (!is.null(rd_fr)) {
  cat("\n  Far-right share (rdrobust):\n")
  print(summary(rd_fr))
}

## Turnout change
rd_to <- tryCatch(
  rdrobust(y = main_sample_complete$delta_turnout_1722,
           x = main_sample_complete$signed_dist_km,
           c = 0, kernel = "triangular", p = 1, q = 2),
  error = function(e) { cat(sprintf("  rdrobust TO failed: %s\n", e$message)); NULL }
)
if (!is.null(rd_to)) {
  cat("\n  Turnout (rdrobust):\n")
  print(summary(rd_to))
}

## Save rdrobust objects
saveRDS(list(rn = rd_rn, fr = rd_fr, to = rd_to),
        file.path(data_dir, "rdrobust_results.rds"))

## ============================================================
## 5. Placebo test: 2012→2017 change (before any ZFE)
## ============================================================
cat("\n=== 5. Placebo Test: Pre-ZFE Period (2012→2017) ===\n")

main_sample_placebo <- main_sample[!is.na(delta_rn_1217)]

rd_placebo <- tryCatch(
  rdrobust(y = main_sample_placebo$delta_rn_1217,
           x = main_sample_placebo$signed_dist_km,
           c = 0, kernel = "triangular", p = 1, q = 2),
  error = function(e) { cat(sprintf("  Placebo rdrobust failed: %s\n", e$message)); NULL }
)
if (!is.null(rd_placebo)) {
  cat("  Placebo (2012→2017 ΔRN):\n")
  print(summary(rd_placebo))
}

saveRDS(rd_placebo, file.path(data_dir, "placebo_results.rds"))

## ============================================================
## 6. Broader sample: ALL metros (including later ZFEs)
## ============================================================
cat("\n=== 6. Extended Sample (All Metros, Legislative 2024) ===\n")

## For the 2024 legislative, more metros have active ZFEs
active_metros_2024 <- unique(panel[metro_active_2024 == TRUE, nearest_metro_siren])
extended_sample <- panel[nearest_metro_siren %in% active_metros_2024 & !is.na(rn_share_2024l)]

## Compute 2017→2024 far-right change (using legislative RN share)
extended_sample[, delta_rn_2024l := rn_share_2024l - rn_share_2017]

rd_2024 <- tryCatch(
  rdrobust(y = extended_sample$delta_rn_2024l,
           x = extended_sample$signed_dist_km,
           c = 0, kernel = "triangular", p = 1, q = 2),
  error = function(e) { cat(sprintf("  2024 rdrobust failed: %s\n", e$message)); NULL }
)
if (!is.null(rd_2024)) {
  cat("  Legislative 2024 ΔRN:\n")
  print(summary(rd_2024))
}

## ============================================================
## 7. Covariate balance at the boundary
## ============================================================
cat("\n=== 7. Covariate Balance ===\n")

for (var in c("rn_share_2017", "turnout_2017", "population", "rn_share_2012")) {
  sub <- main_sample_complete[!is.na(get(var))]
  rd_cov <- tryCatch(
    rdrobust(y = sub[[var]], x = sub$signed_dist_km, c = 0, kernel = "triangular"),
    error = function(e) NULL
  )
  if (!is.null(rd_cov)) {
    cat(sprintf("  %s: coef=%.4f, p=%.3f, bw=%.1fkm\n",
                var, rd_cov$coef[1], rd_cov$pv[1], rd_cov$bws[1]))
  }
}

## ============================================================
## 8. Density test (McCrary)
## ============================================================
cat("\n=== 8. Density Test ===\n")
dens_test <- tryCatch(
  rddensity(X = main_sample_complete$signed_dist_km, c = 0),
  error = function(e) { cat(sprintf("  Density test failed: %s\n", e$message)); NULL }
)
if (!is.null(dens_test)) {
  cat(sprintf("  McCrary density test p-value: %.3f\n", dens_test$test$p_jk))
}

## ============================================================
## 9. Write diagnostics.json
## ============================================================
cat("\n=== 9. Diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(main_sample$inside_zfe),
  n_pre = 2L,  # 2012, 2017 are pre-ZFE elections
  n_obs = nrow(main_sample),
  n_total_panel = nrow(panel),
  n_metros_active = length(active_metros_2022),
  bandwidths_tested = bandwidths,
  density_test_p = if (!is.null(dens_test)) dens_test$test$p_jk else NA
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("  diagnostics.json written\n")

cat("\nMain analysis complete.\n")
