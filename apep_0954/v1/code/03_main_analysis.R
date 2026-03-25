## 03_main_analysis.R — Main regressions for apep_0954
## Beirut Port Explosion and Food Prices

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

dt <- fread(file.path(data_dir, "panel_main.csv"))
dt[, ym := as.Date(ym)]

cat(sprintf("Analysis panel: %d obs, %d markets, %d commodities\n",
            nrow(dt), uniqueN(dt$market), uniqueN(dt$commodity)))

# ---- 1. DiD: Beirut Proximity × Post ----
# Main specification: log(price) = α_mc + γ_ct + β(BeirutProximity × Post) + ε
# where mc = market×commodity FE, ct = commodity×time FE

cat("\n=== MAIN DiD: Beirut Proximity × Post ===\n")

# Create fixed effect identifiers
dt[, mc_fe := paste0(market, "_", commodity)]
dt[, ct_fe := paste0(commodity, "_", as.character(ym))]
dt[, mt_fe := paste0(market, "_", as.character(ym))]

# Interaction term
dt[, bp_post := beirut_proximity * post]

# Main specification (Table 2, Column 1)
m1 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt, cluster = ~market)
cat("\nModel 1: DiD with market×commodity + commodity×time FE\n")
summary(m1)

# Column 2: Add market×time FE (absorbs all market-level time trends)
# This requires triple-diff for identification
# For the DiD specification, use commodity×time FE only

# Column 3: Restrict to imported commodities
m2 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt[imported == 1], cluster = ~market)
cat("\nModel 2: Imported commodities only\n")
summary(m2)

# Column 4: Restrict to local commodities (PLACEBO)
m3 <- feols(log_price ~ bp_post | mc_fe + ct_fe,
            data = dt[local == 1], cluster = ~market)
cat("\nModel 3: Local commodities only (PLACEBO)\n")
summary(m3)

# ---- 2. Triple-Difference ----
# log(price) = α_mc + γ_mt + δ_ct + β(BeirutProx × Imported × Post) + controls + ε
# Market×time FE absorb all common market-level shocks (hyperinflation, COVID)
# Commodity×time FE absorb all common commodity-level shocks
# The triple interaction isolates: port-dependent price effect for imported goods

cat("\n=== TRIPLE-DIFFERENCE ===\n")

# Triple-diff sample: imported + local (exclude ambiguous)
dt_td <- dt[commodity_type != "ambiguous"]

dt_td[, bp_imp_post := beirut_proximity * imported * post]
dt_td[, bp_imp := beirut_proximity * imported]
dt_td[, imp_post := imported * post]
dt_td[, bp_post_td := beirut_proximity * post]

# Triple-diff with market×time and commodity×time FE
m4 <- feols(log_price ~ bp_imp_post + bp_post_td + imp_post + bp_imp |
              mc_fe + ct_fe,
            data = dt_td, cluster = ~market)
cat("\nModel 4: Triple-diff (mc + ct FE)\n")
summary(m4)

# Triple-diff with full saturation: market×time FE absorbs all market-level macro shocks
m5 <- feols(log_price ~ bp_imp_post |
              mc_fe + mt_fe + ct_fe,
            data = dt_td, cluster = ~market)
cat("\nModel 5: Triple-diff with market×time FE (fully saturated)\n")
summary(m5)

# ---- 3. Event Study ----
cat("\n=== EVENT STUDY ===\n")

# Create monthly event-time indicators
dt[, event_time := months_rel]

# Bin endpoints at -12 and +12
dt[event_time < -12, event_time := -12]
dt[event_time > 12, event_time := 12]

# Event study: interact BeirutProximity with event-time dummies
# Reference period: month -1 (July 2020)
dt[, event_factor := factor(event_time)]
dt[, event_factor := relevel(event_factor, ref = "-1")]

# Event study for all commodities
m_es <- feols(log_price ~ i(event_time, beirut_proximity, ref = -1) | mc_fe + ct_fe,
              data = dt, cluster = ~market)
cat("\nEvent study coefficients:\n")
print(coeftable(m_es)[1:min(24, nrow(coeftable(m_es))), ])

# Event study for imported commodities only
m_es_imp <- feols(log_price ~ i(event_time, beirut_proximity, ref = -1) | mc_fe + ct_fe,
                  data = dt[imported == 1], cluster = ~market)

# Event study for local commodities (placebo)
m_es_loc <- feols(log_price ~ i(event_time, beirut_proximity, ref = -1) | mc_fe + ct_fe,
                  data = dt[local == 1], cluster = ~market)

# ---- 4. Distance Bins ----
cat("\n=== DISTANCE BINS ===\n")

dt[, dist_bin := cut(dist_beirut_km, breaks = c(0, 20, 40, 60, 80, 160),
                     labels = c("0-20km", "20-40km", "40-60km", "60-80km", "80+km"),
                     include.lowest = TRUE)]

m_bins <- feols(log_price ~ i(dist_bin, post, ref = "80+km") | mc_fe + ct_fe,
                data = dt[imported == 1], cluster = ~market)
cat("\nDistance bin results (imported commodities):\n")
summary(m_bins)

# ---- 5. Save regression results ----

# Diagnostics for validation
n_treated <- uniqueN(dt[beirut_proximity > 0.5, market])
n_pre <- uniqueN(dt[post == 0, ym])
n_obs <- nrow(dt)

diag_list <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_markets = uniqueN(dt$market),
  n_commodities = uniqueN(dt$commodity),
  n_mc_pairs = uniqueN(dt$mc_fe),
  main_beta = coef(m1)["bp_post"],
  main_se = se(m1)["bp_post"],
  main_pval = pvalue(m1)["bp_post"],
  imported_beta = coef(m2)["bp_post"],
  imported_se = se(m2)["bp_post"],
  local_beta = coef(m3)["bp_post"],
  local_se = se(m3)["bp_post"],
  triple_beta = coef(m5)["bp_imp_post"],
  triple_se = se(m5)["bp_imp_post"]
)

write_json(diag_list, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m_es, m_es_imp, m_es_loc, m_bins,
     file = file.path(data_dir, "models.RData"))
cat("Model objects saved to data/models.RData\n")
