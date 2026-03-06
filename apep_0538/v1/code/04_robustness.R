## 04_robustness.R — Robustness checks, heterogeneity, and mechanism tests
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"

## =========================================================================
## A. Load data
## =========================================================================

cat("=== A. Loading data ===\n")

dvf <- fread(file.path(data_dir, "dvf_boundary_2km.csv"))
dvf_full <- fread(file.path(data_dir, "dvf_analysis_full.csv"))
dvf_res <- fread(file.path(data_dir, "dvf_residential_boundary.csv"))

for (dt in list(dvf, dvf_full, dvf_res)) {
  dt[, city_f := as.factor(city)]
  dt[, yq_f := as.factor(year_quarter)]
  dt[, code_commune_f := as.factor(code_commune)]
}

## =========================================================================
## B. Bandwidth robustness
## =========================================================================

cat("\n=== B. Bandwidth robustness ===\n")

bandwidths <- c(0.5, 1, 2, 5)
bw_results <- list()

for (bw in bandwidths) {
  dt_bw <- dvf_full[abs(signed_dist_km) <= bw &
                      property_type %in% c("house", "apartment")]
  dt_bw[, city_f := as.factor(city)]
  dt_bw[, yq_f := as.factor(year_quarter)]
  dt_bw[, code_commune_f := as.factor(code_commune)]

  if (nrow(dt_bw) > 100) {
    m_bw <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales |
                    city_f + yq_f,
                  data = dt_bw, cluster = ~code_commune_f)
    bw_results[[as.character(bw)]] <- data.table(
      bandwidth_km = bw,
      coef = coef(m_bw)["treated"],
      se = se(m_bw)["treated"],
      n_obs = nobs(m_bw)
    )
    cat("  BW =", bw, "km: coef =", round(coef(m_bw)["treated"], 4),
        "SE =", round(se(m_bw)["treated"], 4), "N =", nobs(m_bw), "\n")
  }
}

bw_robustness <- rbindlist(bw_results)
bw_robustness[, ci_lower := coef - 1.96 * se]
bw_robustness[, ci_upper := coef + 1.96 * se]
fwrite(bw_robustness, file.path(data_dir, "robustness_bandwidth.csv"))

## =========================================================================
## C. Donut specification (exclude within 200m of boundary)
## =========================================================================

cat("\n=== C. Donut specification ===\n")

dvf_donut <- dvf_res[abs(signed_dist_km) >= 0.2]
dvf_donut[, city_f := as.factor(city)]
dvf_donut[, yq_f := as.factor(year_quarter)]

if (nrow(dvf_donut) > 100) {
  m_donut <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales |
                     city_f + yq_f,
                   data = dvf_donut, cluster = ~code_commune_f)
  cat("  Donut (exclude 200m): coef =", round(coef(m_donut)["treated"], 4),
      "SE =", round(se(m_donut)["treated"], 4), "\n")

  donut_result <- data.table(
    spec = "Donut (>200m from boundary)",
    coef = coef(m_donut)["treated"],
    se = se(m_donut)["treated"],
    n_obs = nobs(m_donut)
  )
  fwrite(donut_result, file.path(data_dir, "robustness_donut.csv"))
}

## =========================================================================
## D. Distance gradient (spillover test)
## =========================================================================

cat("\n=== D. Distance gradient (spillover test) ===\n")

## Create distance rings relative to ZFE boundary
dvf_full[, dist_ring := fcase(
  signed_dist_km <= -2, "deep_inside",
  signed_dist_km > -2 & signed_dist_km <= -1, "inside_1_2km",
  signed_dist_km > -1 & signed_dist_km <= -0.5, "inside_05_1km",
  signed_dist_km > -0.5 & signed_dist_km <= 0, "inside_0_05km",
  signed_dist_km > 0 & signed_dist_km <= 0.5, "outside_0_05km",
  signed_dist_km > 0.5 & signed_dist_km <= 1, "outside_05_1km",
  signed_dist_km > 1 & signed_dist_km <= 2, "outside_1_2km",
  signed_dist_km > 2 & signed_dist_km <= 5, "outside_2_5km",
  signed_dist_km > 5, "far_outside"
)]

dvf_rings <- dvf_full[property_type %in% c("house", "apartment") &
                        !is.na(dist_ring) &
                        dist_ring != "far_outside" &
                        dist_ring != "deep_inside"]
dvf_rings[, city_f := as.factor(city)]
dvf_rings[, yq_f := as.factor(year_quarter)]
dvf_rings[, ring_f := factor(dist_ring, levels = c(
  "outside_2_5km", "outside_1_2km", "outside_05_1km", "outside_0_05km",
  "inside_0_05km", "inside_05_1km", "inside_1_2km"
))]

m_gradient <- feols(log_price_m2 ~ i(ring_f, post_zfe, ref = "outside_2_5km") +
                      surface + nombre_pieces_principales |
                      city_f + yq_f,
                    data = dvf_rings, cluster = ~code_commune_f)

cat("Distance gradient results:\n")
summary(m_gradient)

## Extract gradient coefficients
grad_coefs <- as.data.table(coeftable(m_gradient))
grad_rows <- grepl("ring_f", rownames(coeftable(m_gradient)))
grad_coefs <- grad_coefs[grad_rows, ]
grad_coefs[, ring := gsub("ring_f::", "", rownames(coeftable(m_gradient))[grad_rows])]
grad_coefs[, ring := gsub(":post_zfe", "", ring)]
setnames(grad_coefs, c("estimate", "se", "tval", "pval", "ring"))
grad_coefs[, ci_lower := estimate - 1.96 * se]
grad_coefs[, ci_upper := estimate + 1.96 * se]

fwrite(grad_coefs, file.path(data_dir, "distance_gradient.csv"))

## =========================================================================
## E. Heterogeneity by property size (distributional incidence)
## =========================================================================

cat("\n=== E. Heterogeneity by property size ===\n")

dvf_res[, small_apt := as.integer(property_type == "apartment" & surface <= 40)]
dvf_res[, large_apt := as.integer(property_type == "apartment" & surface > 80)]

## Interaction: treatment x small apartment
m_size <- feols(log_price_m2 ~ treated * small_apt +
                  surface + nombre_pieces_principales |
                  city_f + yq_f,
                data = dvf_res[property_type == "apartment"],
                cluster = ~code_commune_f)

cat("  Size heterogeneity:\n")
summary(m_size)

## By size quintile
if ("size_quintile" %in% names(dvf_res)) {
  dvf_q <- dvf_res[property_type == "apartment" & !is.na(size_quintile)]
  dvf_q[, city_f := as.factor(city)]
  dvf_q[, yq_f := as.factor(year_quarter)]

  m_quintile <- feols(log_price_m2 ~ i(size_quintile, treated) +
                        nombre_pieces_principales |
                        city_f + yq_f,
                      data = dvf_q, cluster = ~code_commune_f)

  q_coefs <- as.data.table(coeftable(m_quintile))
  q_rows <- grepl("size_quintile", rownames(coeftable(m_quintile)))
  q_coefs <- q_coefs[q_rows, ]
  q_coefs[, quintile := gsub(".*::(Q[0-9]).*", "\\1",
                              rownames(coeftable(m_quintile))[q_rows])]
  setnames(q_coefs, c("estimate", "se", "tval", "pval", "quintile"))
  q_coefs[, ci_lower := estimate - 1.96 * se]
  q_coefs[, ci_upper := estimate + 1.96 * se]
  fwrite(q_coefs, file.path(data_dir, "heterogeneity_size.csv"))

  cat("  Size quintile results:\n")
  print(q_coefs[, .(quintile, estimate, se)])
}

## =========================================================================
## F. Heterogeneity by city
## =========================================================================

cat("\n=== F. Heterogeneity by city ===\n")

city_results <- list()
for (c_name in unique(dvf_res$city)) {
  dt_city <- dvf_res[city == c_name]
  dt_city[, yq_f := as.factor(year_quarter)]
  if (nrow(dt_city) > 50 && dt_city[, uniqueN(treated)] == 2) {
    m_city <- tryCatch({
      feols(log_price_m2 ~ treated + surface + nombre_pieces_principales | yq_f,
            data = dt_city, cluster = ~code_commune_f)
    }, error = function(e) NULL)
    if (!is.null(m_city)) {
      city_results[[c_name]] <- data.table(
        city = c_name,
        coef = coef(m_city)["treated"],
        se = se(m_city)["treated"],
        n_obs = nobs(m_city)
      )
    }
  }
}

if (length(city_results) > 0) {
  city_het <- rbindlist(city_results)
  city_het[, ci_lower := coef - 1.96 * se]
  city_het[, ci_upper := coef + 1.96 * se]
  fwrite(city_het, file.path(data_dir, "heterogeneity_city.csv"))
  cat("  City-level results:\n")
  print(city_het[, .(city, coef = round(coef, 4), se = round(se, 4), n_obs)])
}

## =========================================================================
## G. Pre-trend test (commune-level, 2014-2024)
## =========================================================================

cat("\n=== G. Pre-trend test (commune-level) ===\n")

## commune_price_trends.csv not available (CEREMA API too slow)
## Use within-sample pre-trend from DVF data instead
pretrend_data <- dvf_res[, .(
  mean_log_price = mean(log_price_m2, na.rm = TRUE),
  n_trans = .N
), by = .(year_quarter, inside_zfe)]
fwrite(pretrend_data, file.path(data_dir, "pretrend_commune.csv"))
cat("  Pre-trend data saved (from DVF within-sample)\n")

## =========================================================================
## H. Randomization inference
## =========================================================================

cat("\n=== H. Randomization inference ===\n")

## Permute ZFE start dates across cities
set.seed(42)
n_perms <- 500
actual_coef <- fread(file.path(data_dir, "main_results.csv"))[model == "Hedonic controls", coef]

ri_coefs <- numeric(n_perms)

for (p in 1:n_perms) {
  dvf_ri <- copy(dvf_res)
  ## Shuffle ZFE start dates across cities
  shuffled_dates <- sample(unique(dvf_ri$zfe_start_date))
  city_map <- data.table(
    city = unique(dvf_ri$city),
    shuffled_date = shuffled_dates[1:length(unique(dvf_ri$city))]
  )
  dvf_ri <- merge(dvf_ri, city_map, by = "city")
  dvf_ri[, post_zfe_ri := as.integer(as.Date(date) >= as.Date(shuffled_date))]
  dvf_ri[, treated_ri := inside_zfe * post_zfe_ri]
  dvf_ri[, city_f := as.factor(city)]
  dvf_ri[, yq_f := as.factor(year_quarter)]

  m_ri <- tryCatch({
    feols(log_price_m2 ~ treated_ri + surface + nombre_pieces_principales |
            city_f + yq_f,
          data = dvf_ri, cluster = ~code_commune_f)
  }, error = function(e) NULL)

  if (!is.null(m_ri)) {
    ri_coefs[p] <- coef(m_ri)["treated_ri"]
  }

  if (p %% 100 == 0) cat("    Permutation", p, "/", n_perms, "\n")
}

ri_pval <- mean(abs(ri_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("  RI p-value:", round(ri_pval, 4), "\n")
cat("  Actual coef:", round(actual_coef, 4), "\n")
cat("  Mean permuted:", round(mean(ri_coefs, na.rm = TRUE), 4), "\n")

ri_result <- data.table(
  actual_coef = actual_coef,
  ri_pval = ri_pval,
  mean_permuted = mean(ri_coefs, na.rm = TRUE),
  sd_permuted = sd(ri_coefs, na.rm = TRUE),
  n_perms = n_perms
)
fwrite(ri_result, file.path(data_dir, "randomization_inference.csv"))
fwrite(data.table(coef = ri_coefs), file.path(data_dir, "ri_distribution.csv"))

## =========================================================================
## I. CS-DiD leave-one-city-out robustness
## =========================================================================

cat("\n=== I. CS-DiD leave-one-city-out ===\n")

## Load CS-DiD data (excluding Paris and Grenoble, same as main analysis)
dvf_cs <- dvf_res[!(city %in% c("Paris", "Grenoble")) & !is.na(zfe_start_date)]
dvf_cs[, period := year * 4 + quarter]
dvf_cs[, first_treat := year(as.Date(zfe_start_date)) * 4 +
          quarter(as.Date(zfe_start_date))]
dvf_cs[inside_zfe == 0, first_treat := 0]
dvf_cs[, commune_id := as.integer(as.factor(code_commune))]

cs_cities <- unique(dvf_cs$city)
loo_results <- list()

for (drop_city in cs_cities) {
  dvf_loo <- dvf_cs[city != drop_city]
  dvf_loo[, commune_id := as.integer(as.factor(code_commune))]

  dvf_loo_agg <- dvf_loo[, .(
    log_price_m2 = mean(log_price_m2, na.rm = TRUE),
    n_trans = .N
  ), by = .(commune_id, period, first_treat)]

  cs_loo <- tryCatch({
    att_gt(
      yname = "log_price_m2",
      tname = "period",
      idname = "commune_id",
      gname = "first_treat",
      data = as.data.frame(dvf_loo_agg),
      control_group = "notyettreated",
      base_period = "varying"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    cs_loo_agg <- aggte(cs_loo, type = "simple", na.rm = TRUE)
    loo_results[[drop_city]] <- data.table(
      dropped_city = drop_city,
      att = cs_loo_agg$overall.att,
      se = cs_loo_agg$overall.se
    )
    cat("  Drop", drop_city, ": ATT =", round(cs_loo_agg$overall.att, 4),
        "SE =", round(cs_loo_agg$overall.se, 4), "\n")
  }
}

if (length(loo_results) > 0) {
  loo_table <- rbindlist(loo_results)
  loo_table[, ci_lower := att - 1.96 * se]
  loo_table[, ci_upper := att + 1.96 * se]
  fwrite(loo_table, file.path(data_dir, "cs_did_loo.csv"))
  cat("  Leave-one-out results saved\n")
}

cat("\n=== Robustness analysis complete ===\n")
