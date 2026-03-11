# =============================================================================
# 04_robustness.R — Placebo tests, BHJ diagnostics, RI, heterogeneity
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel    <- fread(file.path(data_dir, "analysis_panel.csv"))
cross    <- fread(file.path(data_dir, "analysis_cross_section.csv"))
bilateral <- fread(file.path(data_dir, "bilateral_nuts2_flows.csv"))
shares   <- fread(file.path(data_dir, "pre_period_shares.csv"))

# ---------------------------------------------------------------
# 1. Pre-trend test: instrument should not predict pre-period changes
# ---------------------------------------------------------------
# Regress pre-period outcome change on predicted outflow rate
pre_panel <- panel[year %in% 2014:2019]

pretrend_tert <- feols(tert_share_25_34 ~ predicted_out_rate | nuts2 + year,
                       data = pre_panel[!is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate)],
                       cluster = ~nuts2)

cat("=== PRE-TREND TEST ===\n")
print(summary(pretrend_tert))

# Placebo: broader education cohort (25-64) should not be affected
pretrend_placebo <- feols(tert_share_25_64 ~ predicted_out_rate | nuts2 + year,
                          data = pre_panel[!is.na(tert_share_25_64) &
                                           !is.na(predicted_out_rate)],
                          cluster = ~nuts2)

cat("\n=== PRE-TREND PLACEBO (tert 25-64) ===\n")
print(summary(pretrend_placebo))

# ---------------------------------------------------------------
# 2. Exclude COVID years (2020-2021)
# ---------------------------------------------------------------
panel_nocovid <- panel[!(year %in% c(2020, 2021))]

iv_nocovid <- feols(tert_share_25_34 ~ 1 | nuts2 + year | out_rate ~ predicted_out_rate,
                    data = panel_nocovid[!is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate) &
                                        !is.na(out_rate)],
                    cluster = ~nuts2)

cat("\n=== 2SLS: Excluding COVID years ===\n")
print(summary(iv_nocovid))

# ---------------------------------------------------------------
# 3. Alternative pre-period windows for shares (2014-2015 only)
# ---------------------------------------------------------------
# Narrower pre-period shares
pre_bilateral_alt <- bilateral[year %in% 2014:2015,
                               .(flow_pre = sum(flow)), by = .(orig, dest)]
pre_totals_alt <- pre_bilateral_alt[, .(total_pre = sum(flow_pre)), by = orig]
shares_alt <- merge(pre_bilateral_alt, pre_totals_alt, by = "orig")
shares_alt[, share := flow_pre / total_pre]

# Pre-period destination totals (using 2014-2015)
dest_pre_alt <- bilateral[year %in% 2014:2015,
                          .(G_j_pre = sum(flow) / 2), by = dest]

# Destination inflows by year
dest_year <- bilateral[, .(G_jt = sum(flow)), by = .(dest, year)]

# Rebuild Bartik growth with alt shares
bartik_alt_parts <- merge(shares_alt[, .(orig, dest, share, flow_pre)],
                          bilateral[, .(orig, dest, year, flow)],
                          by = c("orig", "dest"), all.x = TRUE, allow.cartesian = TRUE)
bartik_alt_parts[is.na(flow), flow := 0]
bartik_alt_parts <- merge(bartik_alt_parts, dest_year, by = c("dest", "year"), all.x = TRUE)
bartik_alt_parts <- merge(bartik_alt_parts, dest_pre_alt, by = "dest", all.x = TRUE)

# LOO destination inflow and growth rate
bartik_alt_parts[, G_jt_loo := G_jt - flow]
bartik_alt_parts[, g_jt_loo := (G_jt_loo - G_j_pre) / pmax(G_j_pre, 1)]

bartik_alt_growth <- bartik_alt_parts[, .(bartik_alt_growth = sum(share * g_jt_loo, na.rm = TRUE)),
                                      by = .(nuts2 = orig, year)]

# Compute predicted outflow rate with alt shares
alt_pre_totals_merged <- merge(bartik_alt_growth,
                               pre_totals_alt[, .(nuts2 = orig, total_pre_annual = total_pre / 2)],
                               by = "nuts2", all.x = TRUE)
alt_pre_totals_merged[, predicted_out_alt := total_pre_annual * (1 + bartik_alt_growth)]

panel_alt <- merge(panel, alt_pre_totals_merged[, .(nuts2, year, predicted_out_alt)],
                   by = c("nuts2", "year"), all.x = TRUE)

# Scale by population
panel_alt[, predicted_out_rate_alt := predicted_out_alt / (pop_20_29 / 1000)]

iv_alt_shares <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                       out_rate ~ predicted_out_rate_alt,
                       data = panel_alt[!is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate_alt) &
                                        !is.na(out_rate)],
                       cluster = ~nuts2)

cat("\n=== 2SLS: Alternative shares (2014-2015) ===\n")
print(summary(iv_alt_shares))

# ---------------------------------------------------------------
# 4. Randomization Inference: permute destination growth shocks
#    and rebuild the predicted outflow rate
# ---------------------------------------------------------------
set.seed(20260311)
n_perm <- 500

# Get the observed IV coefficient
obs_fit <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                 out_rate ~ predicted_out_rate,
                 data = panel[!is.na(tert_share_25_34) &
                              !is.na(predicted_out_rate) & !is.na(out_rate)],
                 cluster = ~nuts2)
obs_coef <- coef(obs_fit)["fit_out_rate"]

# Pre-period destination totals (same as in 02b)
dest_pre <- bilateral[year %in% 2014:2016,
                      .(G_j_pre = sum(flow) / 3), by = dest]

# Unique destinations and their growth shocks (LOO totals by dest-year)
dest_growth <- merge(dest_year, dest_pre, by = "dest")
dest_growth[, g_jt := (G_jt - G_j_pre) / pmax(G_j_pre, 1)]

# Unique destinations
dests <- unique(dest_growth$dest)
n_dests <- length(dests)

# Pre-period total annual outflows per origin
pre_totals_ri <- shares[, .(total_pre_annual = sum(flow_pre) / 3), by = orig]

# Run RI by permuting destination-level growth shocks and rebuilding predicted outflow rate
ri_coefs <- numeric(n_perm)

cat("\nRunning Randomization Inference (", n_perm, "permutations)...\n")
for (p in seq_len(n_perm)) {
  if (p %% 100 == 0) cat("  Permutation", p, "\n")

  # Permute destination labels in the growth data
  perm_map <- data.table(dest = dests, dest_perm = sample(dests))
  dest_growth_perm <- merge(dest_growth[, .(dest, year, g_jt)], perm_map, by = "dest")

  # Rebuild Bartik growth with permuted destinations
  bartik_perm_parts <- merge(shares[, .(orig, dest, share)],
                             dest_growth_perm[, .(dest = dest_perm, year, g_jt)],
                             by = "dest", allow.cartesian = TRUE)

  bartik_perm <- bartik_perm_parts[, .(bartik_growth_perm = sum(share * g_jt, na.rm = TRUE)),
                                   by = .(nuts2 = orig, year)]

  # Rebuild predicted outflow rate
  bartik_perm <- merge(bartik_perm, pre_totals_ri[, .(nuts2 = orig, total_pre_annual)],
                       by = "nuts2", all.x = TRUE)
  bartik_perm[, predicted_out_perm := total_pre_annual * (1 + bartik_growth_perm)]

  panel_perm <- merge(panel[, .(nuts2, year, tert_share_25_34, out_rate, pop_20_29)],
                      bartik_perm[, .(nuts2, year, predicted_out_perm)],
                      by = c("nuts2", "year"), all.x = TRUE)

  # Scale by population
  panel_perm[, predicted_out_rate_perm := predicted_out_perm / (pop_20_29 / 1000)]

  tryCatch({
    fit_perm <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                      out_rate ~ predicted_out_rate_perm,
                      data = panel_perm[!is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate_perm) &
                                        !is.na(out_rate)],
                      cluster = ~nuts2)
    ri_coefs[p] <- coef(fit_perm)["fit_out_rate"]
  }, error = function(e) {
    ri_coefs[p] <<- NA
  })
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(obs_coef), na.rm = TRUE)
cat("\nRI p-value:", ri_pvalue, "\n")
cat("Observed coefficient:", obs_coef, "\n")

fwrite(data.table(perm = 1:n_perm, coef = ri_coefs),
       file.path(data_dir, "ri_coefficients.csv"))

# ---------------------------------------------------------------
# 5. Leave-one-out stability (drop each country and re-run main 2SLS)
# ---------------------------------------------------------------
countries <- unique(panel$country)
loo_results <- data.table()

for (cc in countries) {
  tryCatch({
    fit_loo <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                     out_rate ~ predicted_out_rate,
                     data = panel[country != cc &
                                  !is.na(tert_share_25_34) &
                                  !is.na(predicted_out_rate) &
                                  !is.na(out_rate)],
                     cluster = ~nuts2)
    loo_results <- rbind(loo_results,
                         data.table(dropped = cc,
                                    beta = coef(fit_loo)["fit_out_rate"],
                                    se = se(fit_loo)["fit_out_rate"],
                                    n = nobs(fit_loo)))
  }, error = function(e) {
    cat("  LOO failed for:", cc, "\n")
  })
}

fwrite(loo_results, file.path(data_dir, "loo_country_results.csv"))
cat("\n=== LEAVE-ONE-OUT (by country) ===\n")
print(loo_results)

# ---------------------------------------------------------------
# 6. Heterogeneity by GDP per capita (peripheral vs. core)
# ---------------------------------------------------------------
# Classify regions by pre-period GDP per capita
gdp_pre <- panel[year %in% 2014:2016 & !is.na(gdp_pc),
                 .(gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)), by = nuts2]
gdp_median <- median(gdp_pre$gdp_pc_pre, na.rm = TRUE)
gdp_pre[, peripheral := as.integer(gdp_pc_pre < gdp_median)]

panel_het <- merge(panel, gdp_pre[, .(nuts2, peripheral)], by = "nuts2", all.x = TRUE)

# Low-GDP regions (peripheral)
iv_peripheral <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                       out_rate ~ predicted_out_rate,
                       data = panel_het[peripheral == 1 &
                                        !is.na(tert_share_25_34) &
                                        !is.na(predicted_out_rate) &
                                        !is.na(out_rate)],
                       cluster = ~nuts2)

# High-GDP regions (core)
iv_core <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                 out_rate ~ predicted_out_rate,
                 data = panel_het[peripheral == 0 &
                                  !is.na(tert_share_25_34) &
                                  !is.na(predicted_out_rate) &
                                  !is.na(out_rate)],
                 cluster = ~nuts2)

cat("\n=== HETEROGENEITY: Peripheral vs Core ===\n")
cat("Peripheral (below-median GDP):\n")
print(summary(iv_peripheral))
cat("Core (above-median GDP):\n")
print(summary(iv_core))

# ---------------------------------------------------------------
# 7. Heterogeneity by net-sending vs net-receiving status
# ---------------------------------------------------------------
net_status <- panel[year %in% 2014:2016,
                    .(net_out_pre = mean(net_out, na.rm = TRUE)), by = nuts2]
net_status[, net_sender := as.integer(net_out_pre > 0)]

panel_net <- merge(panel, net_status[, .(nuts2, net_sender)], by = "nuts2", all.x = TRUE)

iv_senders <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                    out_rate ~ predicted_out_rate,
                    data = panel_net[net_sender == 1 &
                                    !is.na(tert_share_25_34) &
                                    !is.na(predicted_out_rate) &
                                    !is.na(out_rate)],
                    cluster = ~nuts2)

iv_receivers <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                      out_rate ~ predicted_out_rate,
                      data = panel_net[net_sender == 0 &
                                      !is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) &
                                      !is.na(out_rate)],
                      cluster = ~nuts2)

cat("\n=== HETEROGENEITY: Net Senders vs Net Receivers ===\n")
cat("Net senders:\n")
print(summary(iv_senders))
cat("Net receivers:\n")
print(summary(iv_receivers))

# ---------------------------------------------------------------
# 8. Country-by-year fixed effects (reviewer-requested)
# ---------------------------------------------------------------
# This absorbs country-level shocks (e.g., national labor market conditions,
# accession dynamics) that may correlate with both Erasmus intensity and
# human capital trends.
iv_country_year <- feols(tert_share_25_34 ~ 1 | nuts2 + country^year |
                         out_rate ~ predicted_out_rate,
                         data = panel[!is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) &
                                      !is.na(out_rate)],
                         cluster = ~nuts2)

cat("\n=== 2SLS with country-by-year FE ===\n")
print(summary(iv_country_year))

# ---------------------------------------------------------------
# 9. Formal heterogeneity interaction test (reviewer-requested)
# ---------------------------------------------------------------
# Instead of separate subsamples, estimate a pooled model with
# peripheral × outflow rate interaction to get a formal test of
# differential effects.
panel_het <- merge(panel, gdp_pre[, .(nuts2, peripheral)], by = "nuts2", all.x = TRUE)

panel_het[, out_rate_peripheral := out_rate * peripheral]
panel_het[, pred_rate_peripheral := predicted_out_rate * peripheral]

iv_interact <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                     out_rate + out_rate_peripheral ~ predicted_out_rate + pred_rate_peripheral,
                     data = panel_het[!is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) &
                                      !is.na(out_rate) &
                                      !is.na(peripheral)],
                     cluster = ~nuts2)

cat("\n=== HETEROGENEITY INTERACTION TEST ===\n")
cat("Outflow rate (base):", round(coef(iv_interact)["fit_out_rate"], 4), "\n")
cat("Peripheral × Outflow rate:", round(coef(iv_interact)["fit_out_rate_peripheral"], 4), "\n")
print(summary(iv_interact))

# ---------------------------------------------------------------
# 10. Save robustness results
# ---------------------------------------------------------------
robust <- list(
  pretrend = pretrend_tert,
  pretrend_placebo = pretrend_placebo,
  nocovid = iv_nocovid,
  alt_shares = iv_alt_shares,
  ri_pvalue = ri_pvalue,
  ri_coefs = ri_coefs,
  obs_coef = obs_coef,
  loo = loo_results,
  iv_peripheral = iv_peripheral,
  iv_core = iv_core,
  iv_senders = iv_senders,
  iv_receivers = iv_receivers,
  gdp_median = gdp_median,
  iv_country_year = iv_country_year,
  iv_interact = iv_interact
)

saveRDS(robust, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
