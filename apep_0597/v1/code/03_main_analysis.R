## =============================================================================
## 03_main_analysis.R — Primary DiD regressions
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

rtep <- fread(file.path(data_dir, "rtep_clean.csv"))
rtep[, date := as.Date(date)]
wfp <- fread(file.path(data_dir, "wfp_clean.csv"))
wfp[, date := as.Date(date)]

## ---------------------------------------------------------------------------
## Panel A: Petrol price pass-through (RTEP data)
## ---------------------------------------------------------------------------

cat("=== PANEL A: Petrol Price Pass-Through ===\n\n")

# Main specification: log(petrol_price) = market FE + month FE + β(post × distance)
# Clustering at state level (admin1)

# Column 1: OLS with main effects (no FE)
m_a1 <- feols(log_petrol ~ post + dist_100km + dist_post_100, data = rtep,
              cluster = ~adm1_name)

# Column 2: Market + Month FE
m_a2 <- feols(log_petrol ~ dist_post_100 | mkt_name + date,
              data = rtep, cluster = ~adm1_name)

# Column 3: Market + Month FE + state-specific trends
m_a3 <- feols(log_petrol ~ dist_post_100 | mkt_name + date + adm1_name[year],
              data = rtep, cluster = ~adm1_name)

# Column 4: Market + Month FE + trust score control
rtep[, trust_petrol := as.numeric(trust_fuel_petrol_gasoline)]
m_a4 <- feols(log_petrol ~ dist_post_100 + trust_petrol | mkt_name + date,
              data = rtep[!is.na(trust_petrol)], cluster = ~adm1_name)

etable(m_a1, m_a2, m_a3, m_a4,
       dict = c(dist_post_100 = "Post × Distance (100km)",
                trust_petrol = "Trust Score"),
       title = "Panel A: Petrol Price Pass-Through")

# Save coefficients for SDE table
panel_a_coef <- coef(m_a2)["dist_post_100"]
panel_a_se <- se(m_a2)["dist_post_100"]
panel_a_sd_y <- sd(rtep$log_petrol)
panel_a_sd_x <- sd(rtep$dist_100km)

cat("\nPanel A preferred estimate (Col 2):\n")
cat("  β =", panel_a_coef, "\n")
cat("  SE =", panel_a_se, "\n")
cat("  SD(Y) =", panel_a_sd_y, "\n")
cat("  SD(X) =", panel_a_sd_x, "\n")

## ---------------------------------------------------------------------------
## Event Study: Petrol prices (pre-trend validation)
## ---------------------------------------------------------------------------

cat("\n=== EVENT STUDY: Petrol Prices ===\n")

# Create event time dummies (omit t = -1 as reference)
# Bin endpoints at -12 and +18
rtep[, event_time_bin := pmax(-12, pmin(18, event_time))]
rtep[, event_time_bin := factor(event_time_bin)]
rtep[, event_time_bin := relevel(event_time_bin, ref = "-1")]

es_petrol <- feols(log_petrol ~ i(event_time_bin, dist_100km, ref = "-1") |
                     mkt_name + date,
                   data = rtep, cluster = ~adm1_name)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_petrol), keep.rownames = TRUE)
es_coefs <- es_coefs[grepl("event_time_bin", rn)]
es_coefs[, event_time := as.integer(gsub(".*::([-0-9]+):.*", "\\1", rn))]
setnames(es_coefs, c("rn", "estimate", "se", "t", "p", "event_time"))

# Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(rn = "ref", estimate = 0, se = 0, t = 0, p = 1, event_time = -1)
)
es_coefs <- es_coefs[order(event_time)]
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_coefs, file.path(data_dir, "event_study_petrol.csv"))

# Pre-trend test: joint F-test of pre-period coefficients
pre_coefs <- es_coefs[event_time < -1 & event_time != -1]
cat("Pre-trend F-test (joint significance of pre-period × distance):\n")
pre_test <- wald(es_petrol,
                 paste0("event_time_bin::", -12:-2, ":dist_100km"),
                 cluster = ~adm1_name)
print(pre_test)

## ---------------------------------------------------------------------------
## Panel B: Food price pass-through (WFP data)
## ---------------------------------------------------------------------------

cat("\n=== PANEL B: Food Price Pass-Through ===\n")

# Exclude fuel commodities — focus on food items
wfp_food <- wfp[is_fuel == FALSE & !is.na(dist_nearest)]

# Column 1: All food commodities
m_b1 <- feols(log_price ~ dist_post_100 | market_commodity + date,
              data = wfp_food, cluster = ~admin1)

# Column 2: Transport-intensive commodities (cereals, roots, legumes)
m_b2 <- feols(log_price ~ dist_post_100 | market_commodity + date,
              data = wfp_food[transport_intensive == 1], cluster = ~admin1)

# Column 3: Non-transport-intensive commodities (PLACEBO)
m_b3 <- feols(log_price ~ dist_post_100 | market_commodity + date,
              data = wfp_food[transport_intensive == 0], cluster = ~admin1)

# Column 4: By commodity group
m_b4_cereals <- feols(log_price ~ dist_post_100 | market_commodity + date,
                      data = wfp_food[commodity_group == "Cereals"],
                      cluster = ~admin1)
m_b4_protein <- feols(log_price ~ dist_post_100 | market_commodity + date,
                      data = wfp_food[commodity_group == "Protein"],
                      cluster = ~admin1)
m_b4_roots <- feols(log_price ~ dist_post_100 | market_commodity + date,
                    data = wfp_food[commodity_group == "Roots/Tubers"],
                    cluster = ~admin1)

etable(m_b1, m_b2, m_b3, m_b4_cereals, m_b4_protein, m_b4_roots,
       dict = c(dist_post_100 = "Post × Distance (100km)"),
       headers = c("All Food", "Transport-Intensive", "Non-Transport (Placebo)",
                    "Cereals", "Protein", "Roots/Tubers"),
       title = "Panel B: Food Price Pass-Through")

# Save Panel B coefficients
panel_b_coef <- coef(m_b1)["dist_post_100"]
panel_b_se <- se(m_b1)["dist_post_100"]
panel_b_sd_y <- sd(wfp_food$log_price)
panel_b_sd_x <- sd(wfp_food$dist_100km)

## ---------------------------------------------------------------------------
## Food Event Study — Cereals
## ---------------------------------------------------------------------------

cat("\n=== Food Event Study: Cereals ===\n")
wfp_cereals <- wfp_food[commodity_group == "Cereals"]
# Create event-time indicators (month relative to June 2023)
wfp_cereals[, event_time := as.numeric(difftime(date, as.Date("2023-06-01"), units = "days")) / 30.44]
wfp_cereals[, event_time := round(event_time)]
# Cap at ±18
wfp_cereals <- wfp_cereals[event_time >= -18 & event_time <= 18]
# Create interactions
for (k in setdiff(-18:18, -1)) {
  vname <- paste0("etime_", ifelse(k < 0, "m", "p"), abs(k))
  wfp_cereals[, (vname) := as.numeric(event_time == k) * dist_100km]
}
# Estimate
etime_vars <- grep("^etime_", names(wfp_cereals), value = TRUE)
fml_food_es <- as.formula(paste("log_price ~", paste(etime_vars, collapse = " + "),
                                 "| market_commodity + date"))
es_food <- feols(fml_food_es, data = wfp_cereals, cluster = ~admin1)
# Extract coefficients
es_food_coefs <- data.table(
  event_time = as.integer(gsub("etime_(m|p)", "\\1", names(coef(es_food)))),
  estimate = coef(es_food),
  se = se(es_food)
)
# Fix event_time parsing
es_food_coefs[, event_time := {
  raw <- names(coef(es_food))
  sign <- ifelse(grepl("_m", raw), -1L, 1L)
  num <- as.integer(gsub("etime_[mp]", "", raw))
  sign * num
}]
es_food_coefs[, ci_lo := estimate - 1.96 * se]
es_food_coefs[, ci_hi := estimate + 1.96 * se]
# Add omitted period
es_food_coefs <- rbind(es_food_coefs, data.table(event_time = -1, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0))
es_food_coefs <- es_food_coefs[order(event_time)]
fwrite(es_food_coefs, file.path(data_dir, "event_study_food_cereals.csv"))
cat("Food event study coefficients saved.\n")

## ---------------------------------------------------------------------------
## Panel C: Conflict events (ACLED, if available)
## ---------------------------------------------------------------------------

acled_file <- file.path(data_dir, "acled_state_month.csv")

if (file.exists(acled_file)) {
  cat("\n=== PANEL C: Social Unrest ===\n")

  acled_sm <- fread(acled_file)
  acled_sm[, date := as.Date(date)]

  # Merge with state-level distances
  market_dists <- fread(file.path(data_dir, "market_distances.csv"))
  state_dists <- market_dists[, .(dist_nearest = mean(dist_nearest)),
                               by = .(state = adm1_name)]

  acled_sm <- merge(acled_sm, state_dists, by.x = "admin1", by.y = "state",
                    all.x = TRUE)
  # For states not in market data, use avg_dist from events
  acled_sm[is.na(dist_nearest), dist_nearest := avg_dist]
  acled_sm <- acled_sm[!is.na(dist_nearest)]

  acled_sm[, dist_100km := dist_nearest / 100]
  acled_sm[, dist_post_100 := dist_100km * post]

  # Column 1: All protests
  m_c1 <- feols(protests ~ dist_post_100 | admin1 + date,
                data = acled_sm, cluster = ~admin1)

  # Column 2: Fuel-related events
  m_c2 <- feols(fuel_events ~ dist_post_100 | admin1 + date,
                data = acled_sm, cluster = ~admin1)

  # Column 3: Battles (PLACEBO — not driven by fuel costs)
  m_c3 <- feols(battles ~ dist_post_100 | admin1 + date,
                data = acled_sm, cluster = ~admin1)

  # Column 4: Riots
  m_c4 <- feols(riots ~ dist_post_100 | admin1 + date,
                data = acled_sm, cluster = ~admin1)

  etable(m_c1, m_c2, m_c3, m_c4,
         dict = c(dist_post_100 = "Post × Distance (100km)"),
         headers = c("Protests", "Fuel Events", "Battles (Placebo)", "Riots"),
         title = "Panel C: Social Unrest")

  panel_c_coef <- coef(m_c1)["dist_post_100"]
  panel_c_se <- se(m_c1)["dist_post_100"]
  panel_c_sd_y <- sd(acled_sm$protests)
  panel_c_sd_x <- sd(acled_sm$dist_100km)

  fwrite(acled_sm, file.path(data_dir, "acled_analysis.csv"))
}

## ---------------------------------------------------------------------------
## Save all model objects
## ---------------------------------------------------------------------------

save(m_a1, m_a2, m_a3, m_a4, es_petrol, es_coefs,
     m_b1, m_b2, m_b3, m_b4_cereals, m_b4_protein, m_b4_roots,
     es_food, es_food_coefs,
     panel_a_coef, panel_a_se, panel_a_sd_y, panel_a_sd_x,
     panel_b_coef, panel_b_se, panel_b_sd_y, panel_b_sd_x,
     file = file.path(data_dir, "main_models.RData"))

if (file.exists(acled_file)) {
  save(m_c1, m_c2, m_c3, m_c4,
       panel_c_coef, panel_c_se, panel_c_sd_y, panel_c_sd_x,
       file = file.path(data_dir, "acled_models.RData"))
}

cat("\n=== All main analyses complete ===\n")
