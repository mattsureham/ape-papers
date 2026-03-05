## 04_robustness.R — Robustness checks
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# 1. Load data
# ===========================================================================
cat("=== Loading data ===\n")

panel <- fread(file.path(data_dir, "panel.csv"))
reform_dates <- fread(file.path(data_dir, "reform_dates.csv"))

# Identify mixed border pairs
reform_cantons <- reform_dates$canton
bp_status <- panel[!is.na(border_pair), .(
  has_reformed = any(canton %in% reform_cantons),
  has_unreformed = any(!canton %in% reform_cantons)
), by = border_pair]
mixed_bps <- bp_status[has_reformed & has_unreformed]$border_pair

# Create reform year reference for all municipalities in mixed border pairs
border_pair_to_reform <- panel[canton %in% reform_cantons & border_pair %in% mixed_bps,
  .(bp_reform_canton = first(canton), bp_reform_year = min(reform_year, na.rm = TRUE)),
  by = border_pair
]
border_pair_to_reform <- unique(border_pair_to_reform, by = "border_pair")

sample_full <- merge(panel[border_pair %in% mixed_bps], border_pair_to_reform, by = "border_pair", all.x = TRUE)
sample_full[, ref_event_time := year - bp_reform_year]
sample_full[, post_reform_ref := as.integer(year >= bp_reform_year)]

cat("  Full analysis data:", nrow(sample_full), "rows\n")

# ===========================================================================
# 2. Bandwidth sensitivity
# ===========================================================================
cat("\n=== Bandwidth sensitivity ===\n")

bw_results <- list()
for (bw in c(5, 10, 15, 20, 30)) {
  bw_data <- sample_full[dist_to_border_km <= bw]
  if (nrow(bw_data) < 50) next

  for (comp in c("total", "charge", "aidfee")) {
    form <- as.formula(paste0(comp,
      " ~ reformed + dist_to_border_km | border_pair + year"))
    est <- tryCatch(
      feols(form, data = bw_data, cluster = ~canton),
      error = function(e) NULL
    )
    if (!is.null(est)) {
      bw_results[[paste(bw, comp)]] <- data.table(
        bandwidth_km = bw,
        component = comp,
        coef = coef(est)["reformedTRUE"],
        se = se(est)["reformedTRUE"],
        n = nobs(est),
        n_mun = uniqueN(bw_data$mun_id)
      )
    }
  }
}

bw_table <- rbindlist(bw_results)
cat("  Bandwidth sensitivity:\n")
print(bw_table)
fwrite(bw_table, file.path(data_dir, "robustness_bandwidth.csv"))

# ===========================================================================
# 3. Donut RDD — Exclude municipalities within 2km of border
# ===========================================================================
cat("\n=== Donut RDD (excluding <2km from border) ===\n")

donut_results <- list()
for (comp in c("total", "charge", "aidfee")) {
  donut_data <- sample_full[dist_to_border_km >= 2 & dist_to_border_km <= 15]
  form <- as.formula(paste0(comp,
    " ~ reformed + dist_to_border_km | border_pair + year"))
  est <- tryCatch(
    feols(form, data = donut_data, cluster = ~canton),
    error = function(e) NULL
  )
  if (!is.null(est)) {
    donut_results[[comp]] <- data.table(
      component = comp,
      coef = coef(est)["reformedTRUE"],
      se = se(est)["reformedTRUE"],
      n = nobs(est)
    )
  }
}

donut_table <- rbindlist(donut_results)
cat("  Donut RDD results:\n")
print(donut_table)
fwrite(donut_table, file.path(data_dir, "robustness_donut.csv"))

# ===========================================================================
# 4. Placebo borders (within-canton fake borders)
# ===========================================================================
cat("\n=== Placebo borders ===\n")

# Create fake borders by randomly splitting municipalities within each canton
set.seed(528)
placebo_results <- list()

for (ct in unique(panel$canton[!is.na(panel$canton)])) {
  ct_muns <- unique(panel[canton == ct & !is.na(dist_to_border_km)]$mun_id)
  if (length(ct_muns) < 20) next

  # Random split into two halves
  fake_treated <- sample(ct_muns, length(ct_muns) / 2)
  ct_data <- panel[canton == ct & mun_id %in% ct_muns]
  ct_data[, fake_reform := mun_id %in% fake_treated]

  est <- tryCatch(
    feols(charge ~ fake_reform | year, data = ct_data, cluster = ~mun_id),
    error = function(e) NULL
  )

  if (!is.null(est)) {
    placebo_results[[ct]] <- data.table(
      canton = ct,
      coef = coef(est)["fake_reformTRUE"],
      se = se(est)["fake_reformTRUE"],
      n = nobs(est)
    )
  }
}

if (length(placebo_results) > 0) {
  placebo_table <- rbindlist(placebo_results)
  cat("  Placebo border results (should be near zero):\n")
  cat("  Mean placebo coef:", round(mean(placebo_table$coef), 3), "\n")
  cat("  Share significant:", round(mean(abs(placebo_table$coef / placebo_table$se) > 1.96) * 100, 1), "%\n")
  fwrite(placebo_table, file.path(data_dir, "robustness_placebo_borders.csv"))
}

# ===========================================================================
# 5. Temporal placebo — Pre-reform periods only
# ===========================================================================
cat("\n=== Temporal placebo (pre-reform only) ===\n")

pre_data <- sample_full[ref_event_time < 0 & dist_to_border_km <= 15]
if (nrow(pre_data) > 100) {
  # Test for any pre-existing trend difference
  for (comp in c("charge", "total")) {
    form <- as.formula(paste0(comp,
      " ~ reformed * ref_event_time + dist_to_border_km | border_pair"))
    est <- tryCatch(
      feols(form, data = pre_data, cluster = ~canton),
      error = function(e) NULL
    )
    if (!is.null(est)) {
      cat("  Pre-trend test for", comp, ":\n")
      cat("    Reformed × time coef:", round(coef(est)["reformedTRUE:ref_event_time"], 4),
          " (SE:", round(se(est)["reformedTRUE:ref_event_time"], 4), ")\n")
    }
  }
}

# ===========================================================================
# 6. Polynomial order sensitivity
# ===========================================================================
cat("\n=== Polynomial order sensitivity ===\n")

poly_results <- list()
sample_15 <- sample_full[dist_to_border_km <= 15]

for (poly_order in 1:3) {
  dist_terms <- paste0("I(dist_to_border_km^", 1:poly_order, ")", collapse = " + ")
  form <- as.formula(paste0("charge ~ reformed + ", dist_terms, " | border_pair + year"))
  est <- tryCatch(
    feols(form, data = sample_15, cluster = ~canton),
    error = function(e) NULL
  )
  if (!is.null(est)) {
    poly_results[[as.character(poly_order)]] <- data.table(
      poly_order = poly_order,
      coef = coef(est)["reformedTRUE"],
      se = se(est)["reformedTRUE"],
      n = nobs(est)
    )
  }
}

poly_table <- rbindlist(poly_results)
cat("  Polynomial sensitivity:\n")
print(poly_table)
fwrite(poly_table, file.path(data_dir, "robustness_polynomial.csv"))

# ===========================================================================
# 7. Operator (DSO) fixed effects
# ===========================================================================
cat("\n=== DSO fixed effects ===\n")

if ("operator_id" %in% names(sample_15) && uniqueN(sample_15$operator_id) > 10) {
  for (comp in c("total", "charge")) {
    form <- as.formula(paste0(comp,
      " ~ reformed + dist_to_border_km | border_pair + year + operator_id"))
    est <- tryCatch(
      feols(form, data = sample_15, cluster = ~canton),
      error = function(e) NULL
    )
    if (!is.null(est)) {
      cat("  ", comp, "with DSO FE: coef =", round(coef(est)["reformedTRUE"], 3),
          " (SE:", round(se(est)["reformedTRUE"], 3), ")\n")
    }
  }
}

# ===========================================================================
# 8. Covariate balance at borders
# ===========================================================================
cat("\n=== Covariate balance (tariff components pre-reform) ===\n")

# Use pre-reform tariff components as covariates
pre_balance <- sample_full[ref_event_time == -1 & dist_to_border_km <= 15]
if (nrow(pre_balance) > 50) {
  for (v in c("energy", "gridusage", "aidfee")) {
    form <- as.formula(paste0(v, " ~ reformed + dist_to_border_km | border_pair"))
    est <- tryCatch(
      feols(form, data = pre_balance, cluster = ~canton),
      error = function(e) NULL
    )
    if (!is.null(est)) {
      cat("  Pre-reform balance for", v, ":",
          round(coef(est)["reformedTRUE"], 3),
          " (SE:", round(se(est)["reformedTRUE"], 3), ")\n")
    }
  }
}

# ===========================================================================
# 9. Nonparametric RDD using rdrobust (supplementary)
# ===========================================================================
cat("\n=== Nonparametric RDD (rdrobust) ===\n")

# rdrobust requires a single running variable. We use signed distance:
# positive = reform canton side, negative = non-reform side
rdd_np_data <- sample_full[dist_to_border_km <= 15 & !is.na(reformed)]
rdd_np_data[, signed_dist := fifelse(reformed, dist_to_border_km, -dist_to_border_km)]

for (comp in c("charge", "total", "aidfee")) {
  y_vec <- rdd_np_data[[comp]]
  x_vec <- rdd_np_data$signed_dist
  valid <- !is.na(y_vec) & !is.na(x_vec)

  if (sum(valid) > 100) {
    rd_est <- tryCatch(
      rdrobust(y = y_vec[valid], x = x_vec[valid], c = 0),
      error = function(e) { cat("  rdrobust error for", comp, ":", e$message, "\n"); NULL }
    )
    if (!is.null(rd_est)) {
      cat("  rdrobust for", comp, ": coef =", round(rd_est$coef[1], 4),
          " (SE:", round(rd_est$se[1], 4), "), BW =", round(rd_est$bws[1, 1], 2), "km\n")
    }
  }
}

cat("\n=== Robustness checks complete ===\n")
