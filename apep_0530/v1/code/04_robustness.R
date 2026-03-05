## 04_robustness.R — Robustness checks and mechanism tests

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Analysis panel:", format(nrow(panel), big.mark = ","), "transactions\n")

# ── 1. Bandwidth sensitivity ────────────────────────────────────────────────
cat("\n=== Bandwidth sensitivity ===\n")

bandwidths <- c(200, 500, 1000, 1500, 2000)
bw_results <- list()

for (bw in bandwidths) {
  dt_bw <- panel[dist_to_boundary <= bw]
  if (nrow(dt_bw) < 500) { cat("  BW", bw, "m: too few obs\n"); next }

  m <- tryCatch(
    feols(log_price_sqm ~ inside_x_gained + inside_x_retained +
            log(surface) + rooms + is_apartment +
            signed_dist + I(signed_dist^2) |
            nearest_boundary_id + transaction_year,
          data = dt_bw, vcov = ~nearest_boundary_id),
    error = function(e) NULL
  )

  if (!is.null(m)) {
    for (cf in c("inside_x_gained", "inside_x_retained")) {
      if (cf %in% names(coef(m))) {
        bw_results[[length(bw_results) + 1]] <- data.table(
          bandwidth = bw,
          coefficient = gsub("inside_x_", "", cf),
          estimate = coef(m)[cf], se = se(m)[cf], n = nrow(dt_bw)
        )
      }
    }
    cat("  BW", bw, "m: N =", format(nrow(dt_bw), big.mark = ","), "\n")
  }
}

bw_sensitivity <- rbindlist(bw_results)
bw_sensitivity[, ci_lower := estimate - 1.96 * se]
bw_sensitivity[, ci_upper := estimate + 1.96 * se]
fwrite(bw_sensitivity, file.path(data_dir, "bw_sensitivity.csv"))

# ── 2. Donut RDD ───────────────────────────────────────────────────────────
cat("\n=== Donut RDD ===\n")

donut_results <- list()
for (donut in c(0, 50, 100, 200)) {
  dt_d <- panel[dist_to_boundary > donut & dist_to_boundary <= 1000]
  if (nrow(dt_d) < 500) next

  m <- tryCatch(
    feols(log_price_sqm ~ inside_x_gained + inside_x_retained +
            log(surface) + rooms + is_apartment +
            signed_dist + I(signed_dist^2) |
            nearest_boundary_id + transaction_year,
          data = dt_d, vcov = ~nearest_boundary_id),
    error = function(e) NULL
  )

  if (!is.null(m)) {
    for (cf in c("inside_x_gained", "inside_x_retained")) {
      if (cf %in% names(coef(m))) {
        donut_results[[length(donut_results) + 1]] <- data.table(
          donut_size = donut, coefficient = gsub("inside_x_", "", cf),
          estimate = coef(m)[cf], se = se(m)[cf], n = nrow(dt_d)
        )
      }
    }
  }
}
fwrite(rbindlist(donut_results), file.path(data_dir, "donut_rdd.csv"))

# ── 3. McCrary density test ─────────────────────────────────────────────────
cat("\n=== Density test ===\n")

density_list <- list()
for (grp in c("gained", "retained")) {
  dt_g <- panel[nearest_group == grp & abs(signed_dist) <= 1000]
  if (nrow(dt_g) < 200) next
  dt_g[, dist_bin := round(signed_dist / 50) * 50]
  dens <- dt_g[, .N, by = dist_bin]
  dens$group <- grp
  density_list[[length(density_list) + 1]] <- dens
}
fwrite(rbindlist(density_list), file.path(data_dir, "density_test.csv"))

# ── 4. Covariate balance ────────────────────────────────────────────────────
cat("\n=== Covariate balance ===\n")
dt_bw <- panel[dist_to_boundary <= 500]
balance_results <- list()

for (grp in c("gained", "retained")) {
  dt_g <- dt_bw[nearest_group == grp]
  for (cv in c("surface", "rooms", "is_apartment")) {
    if (!(cv %in% names(dt_g)) || sum(!is.na(dt_g[[cv]])) < 100) next
    m_bal <- tryCatch(
      feols(as.formula(paste(cv, "~ inside_int | nearest_boundary_id")),
            data = dt_g, vcov = ~nearest_boundary_id),
      error = function(e) NULL
    )
    if (!is.null(m_bal) && "inside_int" %in% names(coef(m_bal))) {
      balance_results[[length(balance_results) + 1]] <- data.table(
        group = grp, covariate = cv,
        diff = coef(m_bal)["inside_int"], se = se(m_bal)["inside_int"],
        mean_outside = mean(dt_g[inside == FALSE][[cv]], na.rm = TRUE),
        n = nrow(dt_g)
      )
    }
  }
}

balance <- rbindlist(balance_results)
balance[, pct_diff := diff / mean_outside * 100]
fwrite(balance, file.path(data_dir, "covariate_balance.csv"))
print(balance)

# ── 5. Property type heterogeneity (mechanism) ──────────────────────────────
cat("\n=== Property type heterogeneity ===\n")

type_results <- list()
for (prop_type in c("Appartement", "Maison")) {
  dt_t <- dt_bw[type_local == prop_type]
  if (nrow(dt_t) < 200) next

  m_t <- tryCatch(
    feols(log_price_sqm ~ inside_x_gained + inside_x_retained +
            log(surface) + rooms +
            signed_dist + I(signed_dist^2) |
            nearest_boundary_id + transaction_year,
          data = dt_t, vcov = ~nearest_boundary_id),
    error = function(e) NULL
  )

  if (!is.null(m_t)) {
    label <- ifelse(prop_type == "Appartement", "Apartment", "House")
    for (cf in c("inside_x_gained", "inside_x_retained")) {
      if (cf %in% names(coef(m_t))) {
        type_results[[length(type_results) + 1]] <- data.table(
          property_type = label, coefficient = cf,
          estimate = coef(m_t)[cf], se = se(m_t)[cf],
          n = nrow(dt_t)
        )
      }
    }
  }
}
fwrite(rbindlist(type_results), file.path(data_dir, "type_heterogeneity.csv"))

# ── 6. Transaction volume ──────────────────────────────────────────────────
cat("\n=== Transaction volume ===\n")
vol <- panel[dist_to_boundary <= 500, .(
  n_transactions = .N,
  total_value = sum(valeur_fonciere, na.rm = TRUE)
), by = .(nearest_boundary_id, nearest_group, transaction_year, inside)]
vol[, log_n := log(n_transactions + 1)]
fwrite(vol, file.path(data_dir, "transaction_volume.csv"))

# Transaction volume regression
vol_reg_results <- list()
for (grp in c("gained", "retained")) {
  vol_g <- vol[nearest_group == grp]
  m_vol <- tryCatch(
    feols(log_n ~ inside | nearest_boundary_id + transaction_year,
          data = vol_g, vcov = ~nearest_boundary_id),
    error = function(e) NULL
  )
  if (!is.null(m_vol) && "insideTRUE" %in% names(coef(m_vol))) {
    vol_reg_results[[length(vol_reg_results) + 1]] <- data.table(
      group = grp, estimate = coef(m_vol)["insideTRUE"],
      se = se(m_vol)["insideTRUE"], n = nrow(vol_g)
    )
  }
}
if (length(vol_reg_results) > 0) {
  fwrite(rbindlist(vol_reg_results), file.path(data_dir, "volume_regression.csv"))
}

saveRDS(list(), file.path(data_dir, "robustness_models.rds"))
cat("\n=== Robustness complete ===\n")
