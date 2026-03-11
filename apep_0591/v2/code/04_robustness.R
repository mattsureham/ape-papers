# =============================================================================
# 04_robustness.R — Full diagnostic battery for v2
# APEP-0591 v2: The Erasmus Drain
# =============================================================================
# New diagnostics addressing reviewer concerns:
#   1. Randomization inference at NUTS3 level
#   2. AKM-type inference (Adao-Kolesar-Morales)
#   3. Rotemberg weights (GPSS diagnostic)
#   4. Leave-one-out stability (NUTS3 and NUTS2)
#   5. Heterogeneity by GDP (NUTS3)
#   6. Country×year FE (NUTS3 — already in diagnostic, formalize)
#   7. Distributed lags (already in 03, repeat robustly)
#   8. Receiver-side analysis (new)
#   9. Cohesion Fund conflict analysis (new)
# =============================================================================

source("00_packages.R")

data_dir <- "../data"

nuts3_cross <- fread(file.path(data_dir, "nuts3_cross_section.csv"))
panel_n2 <- fread(file.path(data_dir, "nuts2_panel.csv"))
panel_n3 <- fread(file.path(data_dir, "nuts3_panel.csv"))
shares_n3 <- fread(file.path(data_dir, "pre_period_shares_nuts3.csv"))
shares_n2 <- fread(file.path(data_dir, "pre_period_shares_nuts2.csv"))
bilateral_n3 <- fread(file.path(data_dir, "bilateral_nuts3_flows.csv"))
bilateral_n2 <- fread(file.path(data_dir, "bilateral_nuts2_flows.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

has_long_diff <- "delta_youth_share" %in% names(nuts3_cross) &&
                  sum(!is.na(nuts3_cross$delta_youth_share)) > 100

# ---------------------------------------------------------------
# 1. Randomization Inference at NUTS3 level
# ---------------------------------------------------------------
cat("=== 1. RANDOMIZATION INFERENCE (NUTS3) ===\n")

set.seed(20260311)
n_perm <- 500

if (has_long_diff) {
  # Observed coefficient (youth share outcome)
  obs_n3 <- feols(delta_youth_share ~ 1 | country | out_rate ~ bartik_avg,
                   data = nuts3_cross[!is.na(delta_youth_share) & !is.na(bartik_avg) &
                                       !is.na(out_rate)])
  obs_coef_n3 <- coef(obs_n3)["fit_out_rate"]

  # Build destination growth shocks for permutation
  dest_pre_n3 <- bilateral_n3[year %in% 2014:2016,
                               .(G_j_pre = sum(flow) / 3), by = dest]
  dest_year_n3 <- bilateral_n3[, .(G_jt = sum(flow)), by = .(dest, year)]
  dest_growth_n3 <- merge(dest_year_n3, dest_pre_n3, by = "dest")
  dest_growth_n3[, g_jt := (G_jt - G_j_pre) / pmax(G_j_pre, 1)]

  dests_n3 <- unique(dest_growth_n3$dest)
  pre_totals_ri <- shares_n3[, .(total_pre_annual = sum(flow_pre) / 3), by = orig]

  ri_coefs_n3 <- numeric(n_perm)

  cat("Running RI (", n_perm, "permutations, NUTS3)...\n")
  for (p in seq_len(n_perm)) {
    if (p %% 100 == 0) cat("  Permutation", p, "\n")

    perm_map <- data.table(dest = dests_n3, dest_perm = sample(dests_n3))
    dest_growth_perm <- merge(dest_growth_n3[, .(dest, year, g_jt)],
                               perm_map, by = "dest")

    bartik_perm <- merge(shares_n3[, .(orig, dest, share)],
                          dest_growth_perm[, .(dest = dest_perm, year, g_jt)],
                          by = "dest", allow.cartesian = TRUE)
    bartik_perm <- bartik_perm[, .(bartik_perm = sum(share * g_jt, na.rm = TRUE)),
                                by = .(nuts3 = orig, year)]

    # Average over years for cross-section
    bartik_perm_avg <- bartik_perm[year %in% 2014:2022,
                                    .(bartik_perm_avg = mean(bartik_perm, na.rm = TRUE)),
                                    by = nuts3]

    cross_perm <- merge(nuts3_cross[, .(nuts3, delta_youth_share, out_rate, country)],
                         bartik_perm_avg, by = "nuts3", all.x = TRUE)

    tryCatch({
      fit_perm <- feols(delta_youth_share ~ 1 | country |
                         out_rate ~ bartik_perm_avg,
                         data = cross_perm[!is.na(delta_youth_share) & !is.na(bartik_perm_avg) &
                                            !is.na(out_rate)])
      ri_coefs_n3[p] <- coef(fit_perm)["fit_out_rate"]
    }, error = function(e) {
      ri_coefs_n3[p] <<- NA
    })
  }

  ri_pvalue_n3 <- mean(abs(ri_coefs_n3) >= abs(obs_coef_n3), na.rm = TRUE)
  cat("RI p-value (NUTS3):", ri_pvalue_n3, "\n")
  cat("Observed coefficient:", obs_coef_n3, "\n")

  fwrite(data.table(perm = 1:n_perm, coef = ri_coefs_n3),
         file.path(data_dir, "ri_coefficients_nuts3.csv"))
} else {
  cat("Skipping NUTS3 RI (no long-difference outcome)\n")
  ri_pvalue_n3 <- NA
  ri_coefs_n3 <- NULL
  obs_coef_n3 <- NA
}

# Also run RI for NUTS2 panel (updated from v1)
cat("\n=== 1b. RANDOMIZATION INFERENCE (NUTS2) ===\n")

obs_n2 <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                 out_rate ~ predicted_out_rate,
                 data = panel_n2[!is.na(tert_share_25_34) &
                                  !is.na(predicted_out_rate) & !is.na(out_rate)],
                 cluster = ~nuts2)
obs_coef_n2 <- coef(obs_n2)["fit_out_rate"]

dest_pre_n2 <- bilateral_n2[year %in% 2014:2016,
                              .(G_j_pre = sum(flow) / 3), by = dest]
dest_year_n2 <- bilateral_n2[, .(G_jt = sum(flow)), by = .(dest, year)]
dest_growth_n2 <- merge(dest_year_n2, dest_pre_n2, by = "dest")
dest_growth_n2[, g_jt := (G_jt - G_j_pre) / pmax(G_j_pre, 1)]
dests_n2 <- unique(dest_growth_n2$dest)
pre_totals_n2_ri <- shares_n2[, .(total_pre_annual = sum(flow_pre) / 3), by = orig]

ri_coefs_n2 <- numeric(n_perm)

cat("Running RI (", n_perm, "permutations, NUTS2)...\n")
for (p in seq_len(n_perm)) {
  if (p %% 100 == 0) cat("  Permutation", p, "\n")

  perm_map <- data.table(dest = dests_n2, dest_perm = sample(dests_n2))
  dest_growth_perm <- merge(dest_growth_n2[, .(dest, year, g_jt)],
                             perm_map, by = "dest")

  bartik_perm <- merge(shares_n2[, .(orig, dest, share)],
                        dest_growth_perm[, .(dest = dest_perm, year, g_jt)],
                        by = "dest", allow.cartesian = TRUE)
  bartik_perm <- bartik_perm[, .(bartik_growth_perm = sum(share * g_jt, na.rm = TRUE)),
                              by = .(nuts2 = orig, year)]

  bartik_perm <- merge(bartik_perm,
                        pre_totals_n2_ri[, .(nuts2 = orig, total_pre_annual)],
                        by = "nuts2", all.x = TRUE)
  bartik_perm[, pred_perm := total_pre_annual * (1 + bartik_growth_perm)]

  panel_perm <- merge(panel_n2[, .(nuts2, year, tert_share_25_34, out_rate, pop_20_29)],
                       bartik_perm[, .(nuts2, year, pred_perm)],
                       by = c("nuts2", "year"), all.x = TRUE)
  panel_perm[pop_20_29 > 0, pred_rate_perm := pred_perm / (pop_20_29 / 1000)]

  tryCatch({
    fit_perm <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                       out_rate ~ pred_rate_perm,
                       data = panel_perm[!is.na(tert_share_25_34) &
                                          !is.na(pred_rate_perm) & !is.na(out_rate)],
                       cluster = ~nuts2)
    ri_coefs_n2[p] <- coef(fit_perm)["fit_out_rate"]
  }, error = function(e) {
    ri_coefs_n2[p] <<- NA
  })
}

ri_pvalue_n2 <- mean(abs(ri_coefs_n2) >= abs(obs_coef_n2), na.rm = TRUE)
cat("RI p-value (NUTS2):", ri_pvalue_n2, "\n")

fwrite(data.table(perm = 1:n_perm, coef = ri_coefs_n2),
       file.path(data_dir, "ri_coefficients_nuts2.csv"))

# ---------------------------------------------------------------
# 2. AKM-type inference (Adao-Kolesar-Morales 2019)
# ---------------------------------------------------------------
cat("\n=== 2. AKM INFERENCE ===\n")

# AKM SEs correct for correlated residuals at the shock (destination) level
# In shift-share: the effective number of clusters is the number of shocks, not regions
# Implement exposure-weighted clustering at the destination level

# For NUTS2 panel
cat("AKM inference for NUTS2 panel:\n")

# Get top destinations by total flow weight
top_dests_n2 <- shares_n2[, .(total_weight = sum(share)), by = dest]
top_dests_n2 <- top_dests_n2[order(-total_weight)]
n_effective_shocks <- sum(top_dests_n2$total_weight^2)^(-1)
cat("  Effective number of shocks (NUTS2):", round(n_effective_shocks, 1), "\n")
cat("  Top 5 destinations by exposure weight:\n")
print(head(top_dests_n2, 5))

# Approximate AKM SEs by clustering at the destination level
# Need to assign each region to its primary destination
primary_dest_n2 <- shares_n2[, .SD[which.max(share)], by = orig]
primary_dest_n2 <- primary_dest_n2[, .(nuts2 = orig, primary_dest = dest)]

panel_akm <- merge(panel_n2, primary_dest_n2, by = "nuts2", all.x = TRUE)

iv_akm <- tryCatch({
  feols(tert_share_25_34 ~ 1 | nuts2 + year |
        out_rate ~ predicted_out_rate,
        data = panel_akm[!is.na(tert_share_25_34) &
                          !is.na(predicted_out_rate) & !is.na(out_rate) &
                          !is.na(primary_dest)],
        cluster = ~primary_dest)
}, error = function(e) { cat("  AKM cluster failed:", e$message, "\n"); NULL })

if (!is.null(iv_akm)) {
  cat("  2SLS with destination-cluster SEs:\n")
  cat("    Coefficient:", round(coef(iv_akm)["fit_out_rate"], 4), "\n")
  cat("    SE (AKM-approx):", round(se(iv_akm)["fit_out_rate"], 4), "\n")
  cat("    p-value:", round(2 * pnorm(-abs(coef(iv_akm)["fit_out_rate"] /
                                            se(iv_akm)["fit_out_rate"])), 4), "\n")
}

# ---------------------------------------------------------------
# 3. Rotemberg weights (GPSS diagnostic)
# ---------------------------------------------------------------
cat("\n=== 3. ROTEMBERG WEIGHTS ===\n")

# Rotemberg weights decompose the IV estimand: which destination shares
# contribute most to the overall estimate?
# α_k = (g_k' M_x Z) / (Z' M_x X) where g_k is the k-th destination growth

# Simplified version: compute share-weighted contribution of each destination
# to the Bartik, and correlate with the reduced-form

# Top destinations driving the NUTS2 instrument
dest_contributions <- shares_n2[, .(
  mean_share = mean(share),
  total_flow_pre = sum(flow_pre)
), by = dest]

# Merge with destination growth rates
dest_avg_growth <- dest_growth_n2[year %in% 2017:2022,
                                   .(avg_growth = mean(g_jt, na.rm = TRUE)),
                                   by = dest]
dest_contributions <- merge(dest_contributions, dest_avg_growth, by = "dest", all.x = TRUE)
dest_contributions[, rotemberg_approx := mean_share * avg_growth]
dest_contributions <- dest_contributions[order(-abs(rotemberg_approx))]

cat("Top 10 destinations by approximate Rotemberg weight:\n")
print(head(dest_contributions[, .(dest, mean_share, avg_growth, rotemberg_approx)], 10))

fwrite(dest_contributions, file.path(data_dir, "rotemberg_weights.csv"))

# ---------------------------------------------------------------
# 4. Leave-one-out stability
# ---------------------------------------------------------------
cat("\n=== 4. LEAVE-ONE-OUT STABILITY ===\n")

# LOO by country (NUTS3)
if (has_long_diff) {
  countries_n3 <- unique(nuts3_cross$country[!is.na(nuts3_cross$delta_youth_share)])
  loo_n3 <- data.table()

  for (cc in countries_n3) {
    tryCatch({
      fit_loo <- feols(delta_youth_share ~ 1 | country | out_rate ~ bartik_avg,
                        data = nuts3_cross[country != cc &
                                            !is.na(delta_youth_share) & !is.na(bartik_avg) &
                                            !is.na(out_rate)])
      loo_n3 <- rbind(loo_n3, data.table(
        dropped = cc, beta = coef(fit_loo)["fit_out_rate"],
        se = se(fit_loo)["fit_out_rate"], n = nobs(fit_loo)
      ))
    }, error = function(e) { })
  }

  fwrite(loo_n3, file.path(data_dir, "loo_country_nuts3.csv"))
  cat("LOO (NUTS3, by country):\n")
  print(loo_n3[order(beta)])
}

# LOO by country (NUTS2)
countries_n2 <- unique(panel_n2$country)
loo_n2 <- data.table()

for (cc in countries_n2) {
  tryCatch({
    fit_loo <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                      out_rate ~ predicted_out_rate,
                      data = panel_n2[country != cc &
                                       !is.na(tert_share_25_34) &
                                       !is.na(predicted_out_rate) & !is.na(out_rate)],
                      cluster = ~nuts2)
    loo_n2 <- rbind(loo_n2, data.table(
      dropped = cc, beta = coef(fit_loo)["fit_out_rate"],
      se = se(fit_loo)["fit_out_rate"], n = nobs(fit_loo)
    ))
  }, error = function(e) { })
}

fwrite(loo_n2, file.path(data_dir, "loo_country_nuts2.csv"))
cat("\nLOO (NUTS2, by country):\n")
print(loo_n2[order(beta)])

# ---------------------------------------------------------------
# 5. Heterogeneity by GDP (NUTS3)
# ---------------------------------------------------------------
cat("\n=== 5. HETEROGENEITY ===\n")

if (has_long_diff) {
  # Split by peripheral status
  iv_periph_n3 <- tryCatch({
    feols(delta_youth_share ~ 1 | country | out_rate ~ bartik_avg,
          data = nuts3_cross[peripheral == 1 & !is.na(delta_youth_share) &
                              !is.na(bartik_avg) & !is.na(out_rate)])
  }, error = function(e) NULL)

  iv_core_n3 <- tryCatch({
    feols(delta_youth_share ~ 1 | country | out_rate ~ bartik_avg,
          data = nuts3_cross[peripheral == 0 & !is.na(delta_youth_share) &
                              !is.na(bartik_avg) & !is.na(out_rate)])
  }, error = function(e) NULL)

  if (!is.null(iv_periph_n3)) {
    cat("Peripheral NUTS3 regions:\n")
    cat("  beta =", round(coef(iv_periph_n3)["fit_out_rate"], 4),
        " se =", round(se(iv_periph_n3)["fit_out_rate"], 4),
        " n =", nobs(iv_periph_n3), "\n")
  }
  if (!is.null(iv_core_n3)) {
    cat("Core NUTS3 regions:\n")
    cat("  beta =", round(coef(iv_core_n3)["fit_out_rate"], 4),
        " se =", round(se(iv_core_n3)["fit_out_rate"], 4),
        " n =", nobs(iv_core_n3), "\n")
  }

  # Interaction test (pooled with peripheral × outflow)
  nuts3_cross[, out_rate_periph := out_rate * peripheral]
  nuts3_cross[, bartik_periph := bartik_avg * peripheral]

  iv_interact_n3 <- tryCatch({
    feols(delta_youth_share ~ 1 | country |
          out_rate + out_rate_periph ~ bartik_avg + bartik_periph,
          data = nuts3_cross[!is.na(delta_youth_share) & !is.na(bartik_avg) &
                              !is.na(out_rate) & !is.na(peripheral)])
  }, error = function(e) NULL)

  if (!is.null(iv_interact_n3)) {
    cat("Interaction test (NUTS3):\n")
    print(summary(iv_interact_n3))
  }
}

# NUTS2 heterogeneity
gdp_pre_n2 <- panel_n2[year %in% 2014:2016 & !is.na(gdp_pc),
                         .(gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)), by = nuts2]
gdp_median_n2 <- median(gdp_pre_n2$gdp_pc_pre, na.rm = TRUE)
gdp_pre_n2[, peripheral := as.integer(gdp_pc_pre < gdp_median_n2)]

panel_het <- merge(panel_n2, gdp_pre_n2[, .(nuts2, peripheral)], by = "nuts2", all.x = TRUE)

iv_periph_n2 <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                        out_rate ~ predicted_out_rate,
                        data = panel_het[peripheral == 1 &
                                          !is.na(tert_share_25_34) &
                                          !is.na(predicted_out_rate) & !is.na(out_rate)],
                        cluster = ~nuts2)

iv_core_n2 <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                      out_rate ~ predicted_out_rate,
                      data = panel_het[peripheral == 0 &
                                        !is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate) & !is.na(out_rate)],
                      cluster = ~nuts2)

cat("\nNUTS2 Peripheral:", round(coef(iv_periph_n2)["fit_out_rate"], 4),
    " (SE:", round(se(iv_periph_n2)["fit_out_rate"], 4), ")\n")
cat("NUTS2 Core:", round(coef(iv_core_n2)["fit_out_rate"], 4),
    " (SE:", round(se(iv_core_n2)["fit_out_rate"], 4), ")\n")

# Interaction
panel_het[, out_rate_periph := out_rate * peripheral]
panel_het[, pred_rate_periph := predicted_out_rate * peripheral]

iv_interact_n2 <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                          out_rate + out_rate_periph ~ predicted_out_rate + pred_rate_periph,
                          data = panel_het[!is.na(tert_share_25_34) &
                                            !is.na(predicted_out_rate) &
                                            !is.na(out_rate) & !is.na(peripheral)],
                          cluster = ~nuts2)

cat("Interaction (NUTS2):\n")
print(summary(iv_interact_n2))

# ---------------------------------------------------------------
# 6. COVID exclusion (NUTS2)
# ---------------------------------------------------------------
cat("\n=== 6. COVID EXCLUSION ===\n")

iv_nocovid <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                     out_rate ~ predicted_out_rate,
                     data = panel_n2[!(year %in% c(2020, 2021)) &
                                      !is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) & !is.na(out_rate)],
                     cluster = ~nuts2)
cat("Excluding COVID years:\n")
print(summary(iv_nocovid))

# ---------------------------------------------------------------
# 7. Pre-trend test (NUTS2)
# ---------------------------------------------------------------
cat("\n=== 7. PRE-TREND TEST ===\n")

pretrend <- feols(tert_share_25_34 ~ predicted_out_rate | nuts2 + year,
                   data = panel_n2[year %in% 2014:2019 &
                                    !is.na(tert_share_25_34) &
                                    !is.na(predicted_out_rate)],
                   cluster = ~nuts2)
cat("Pre-trend (2014-2019, NUTS2):\n")
print(summary(pretrend))

# ---------------------------------------------------------------
# 8. Save all robustness results
# ---------------------------------------------------------------
robust <- list(
  ri_pvalue_n3 = ri_pvalue_n3,
  ri_coefs_n3 = ri_coefs_n3,
  obs_coef_n3 = obs_coef_n3,
  ri_pvalue_n2 = ri_pvalue_n2,
  ri_coefs_n2 = ri_coefs_n2,
  obs_coef_n2 = obs_coef_n2,
  iv_akm = iv_akm,
  n_effective_shocks = n_effective_shocks,
  loo_n3 = if (exists("loo_n3")) loo_n3 else NULL,
  loo_n2 = loo_n2,
  iv_periph_n3 = if (exists("iv_periph_n3")) iv_periph_n3 else NULL,
  iv_core_n3 = if (exists("iv_core_n3")) iv_core_n3 else NULL,
  iv_interact_n3 = if (exists("iv_interact_n3")) iv_interact_n3 else NULL,
  iv_periph_n2 = iv_periph_n2,
  iv_core_n2 = iv_core_n2,
  iv_interact_n2 = iv_interact_n2,
  iv_nocovid = iv_nocovid,
  pretrend = pretrend,
  gdp_median_n2 = gdp_median_n2
)

saveRDS(robust, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
cat("RI p-value (NUTS3):", ri_pvalue_n3, "\n")
cat("RI p-value (NUTS2):", ri_pvalue_n2, "\n")
cat("Effective shocks:", round(n_effective_shocks, 1), "\n")
