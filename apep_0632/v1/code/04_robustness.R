## 04_robustness.R — Robustness checks
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## Active metros for 2022 election
active_metros_2022 <- unique(panel[metro_active_2022 == TRUE, nearest_metro_siren])
main <- panel[nearest_metro_siren %in% active_metros_2022]

## ============================================================
## 1. Donut RDD — drop communes very close to boundary (< 500m)
## ============================================================
cat("=== 1. Donut RDD ===\n")

for (bw in c(5, 10, 15)) {
  sub <- main[dist_to_boundary_m >= 500 & dist_to_boundary_m <= bw * 1000]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]
  sub[w < 0, w := 0]

  fit <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Donut(500m) BW=%dkm: τ̂=%.4f (SE=%.4f), N=%d (in=%d)\n",
                bw, tau, se, nrow(sub), sum(sub$inside_zfe)))
  }
}

## ============================================================
## 2. Quadratic polynomial
## ============================================================
cat("\n=== 2. Quadratic Polynomial ===\n")

for (bw in c(5, 10, 15)) {
  sub <- main[dist_to_boundary_m <= bw * 1000]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]
  sub[w < 0, w := 0]
  sub[, signed_dist_km2 := signed_dist_km^2]

  fit <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * (signed_dist_km + signed_dist_km2) | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Quadratic BW=%dkm: τ̂=%.4f (SE=%.4f), N=%d\n", bw, tau, se, nrow(sub)))
  }
}

## ============================================================
## 3. Uniform kernel
## ============================================================
cat("\n=== 3. Uniform Kernel ===\n")

for (bw in c(3, 5, 7, 10)) {
  sub <- main[dist_to_boundary_m <= bw * 1000]

  fit <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Uniform BW=%dkm: τ̂=%.4f (SE=%.4f), N=%d\n", bw, tau, se, nrow(sub)))
  }
}

## ============================================================
## 4. Without metro FE (shows cross-metro confounding)
## ============================================================
cat("\n=== 4. Without Metro FE (Demonstrates Confounding) ===\n")

for (bw in c(3, 5, 10)) {
  sub <- main[dist_to_boundary_m <= bw * 1000]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]

  fit <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * signed_dist_km,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  No FE, BW=%dkm: τ̂=%.4f (SE=%.4f), N=%d\n", bw, tau, se, nrow(sub)))
  }
}

## ============================================================
## 5. Leave-one-metro-out
## ============================================================
cat("\n=== 5. Leave-One-Metro-Out ===\n")

bw <- 10  # Use 10km bandwidth
sub_full <- main[dist_to_boundary_m <= bw * 1000]
sub_full[, w := (1 - dist_to_boundary_m / (bw * 1000))]

for (m in active_metros_2022) {
  sub <- sub_full[nearest_metro_siren != m]
  if (nrow(sub) < 20 || sum(sub$inside_zfe) < 3) next

  fit <- tryCatch(
    feols(delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Drop %s: τ̂=%.4f (SE=%.4f), N=%d (in=%d)\n",
                m, tau, se, nrow(sub), sum(sub$inside_zfe)))
  }
}

## ============================================================
## 6. Far-right total (Le Pen + Zemmour) as alternative outcome
## ============================================================
cat("\n=== 6. Far-Right Total (Le Pen + Zemmour) ===\n")

for (bw in c(5, 10, 15)) {
  sub <- main[dist_to_boundary_m <= bw * 1000]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]

  fit <- tryCatch(
    feols(delta_farright_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Far-right BW=%dkm: τ̂=%.4f (SE=%.4f), N=%d\n", bw, tau, se, nrow(sub)))
  }
}

## ============================================================
## 7. Placebo bandwidths (2012→2017 with metro FE)
## ============================================================
cat("\n=== 7. Placebo with Metro FE ===\n")

for (bw in c(3, 5, 7, 10)) {
  sub <- main[dist_to_boundary_m <= bw * 1000 & !is.na(delta_rn_1217)]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]

  fit <- tryCatch(
    feols(delta_rn_1217 ~ inside_zfe * signed_dist_km | nearest_metro_siren,
          data = sub, weights = ~w, se = "hetero"),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    tau <- coef(fit)["inside_zfeTRUE"]
    se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
    cat(sprintf("  Placebo (1217) BW=%dkm: τ̂=%.4f (SE=%.4f), p=%.3f\n",
                bw, tau, se, 2 * pnorm(-abs(tau / se))))
  }
}

## ============================================================
## 8. Store robustness results for tables
## ============================================================
cat("\n=== 8. Compiling Robustness Summary ===\n")

## Run the full set for the main table
rob_results <- list()
for (bw in c(3, 5, 7, 10, 15, 20)) {
  sub <- main[dist_to_boundary_m <= bw * 1000]
  sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]

  for (outcome in c("delta_rn_1722", "delta_farright_1722", "delta_turnout_1722", "delta_rn_1217")) {
    fit <- tryCatch(
      feols(as.formula(paste(outcome, "~ inside_zfe * signed_dist_km | nearest_metro_siren")),
            data = sub, weights = ~w, se = "hetero"),
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      tau <- coef(fit)["inside_zfeTRUE"]
      se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
      rob_results[[length(rob_results) + 1]] <- data.table(
        outcome = outcome, bw_km = bw,
        estimate = tau, se = se,
        pval = 2 * pnorm(-abs(tau / se)),
        n = nrow(sub), n_inside = sum(sub$inside_zfe)
      )
    }
  }
}
rob_results <- rbindlist(rob_results)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("  Robustness results saved.\n")
cat("\nRobustness checks complete.\n")
