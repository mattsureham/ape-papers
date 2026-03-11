## =============================================================================
## 04_robustness.R — Robustness checks and sensitivity analysis
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

rtep <- fread(file.path(data_dir, "rtep_clean.csv"))
rtep[, date := as.Date(date)]
wfp <- fread(file.path(data_dir, "wfp_clean.csv"))
wfp[, date := as.Date(date)]

## ---------------------------------------------------------------------------
## 1. Leave-one-out (state): Drop each state and re-estimate
## ---------------------------------------------------------------------------

cat("=== Leave-One-Out (State) ===\n")

states <- unique(rtep$adm1_name)
loo_results <- list()

for (s in states) {
  m <- tryCatch({
    feols(log_petrol ~ dist_post_100 | mkt_name + date,
          data = rtep[adm1_name != s], cluster = ~adm1_name)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    loo_results[[s]] <- data.table(
      dropped_state = s,
      estimate = coef(m)["dist_post_100"],
      se = se(m)["dist_post_100"]
    )
  }
}

loo_dt <- rbindlist(loo_results)
cat("LOO range:", round(min(loo_dt$estimate), 4), "to",
    round(max(loo_dt$estimate), 4), "\n")
cat("Full sample estimate:", round(coef(feols(log_petrol ~ dist_post_100 |
    mkt_name + date, data = rtep, cluster = ~adm1_name))["dist_post_100"], 4), "\n")

fwrite(loo_dt, file.path(data_dir, "robustness_loo.csv"))

## ---------------------------------------------------------------------------
## 2. Alternative distance measures
## ---------------------------------------------------------------------------

cat("\n=== Alternative Distance Measures ===\n")

# Distance to Lagos only (largest terminal)
market_dists <- fread(file.path(data_dir, "market_distances.csv"))
rtep <- merge(rtep, market_dists[, .(mkt_name, dist_lagos, dist_ph, dist_warri)],
              by = "mkt_name", all.x = TRUE)

rtep[, dist_lagos_100 := dist_lagos / 100]
rtep[, dist_lagos_post := dist_lagos_100 * post]

m_lagos <- feols(log_petrol ~ dist_lagos_post | mkt_name + date,
                 data = rtep, cluster = ~adm1_name)

# Distance to PH only
rtep[, dist_ph_100 := dist_ph / 100]
rtep[, dist_ph_post := dist_ph_100 * post]
m_ph <- feols(log_petrol ~ dist_ph_post | mkt_name + date,
              data = rtep, cluster = ~adm1_name)

# Log distance
rtep[, log_dist := log(dist_nearest)]
rtep[, log_dist_post := log_dist * post]
m_logdist <- feols(log_petrol ~ log_dist_post | mkt_name + date,
                   data = rtep, cluster = ~adm1_name)

etable(m_lagos, m_ph, m_logdist,
       dict = c(dist_lagos_post = "Post × Dist Lagos (100km)",
                dist_ph_post = "Post × Dist PH (100km)",
                log_dist_post = "Post × Log(Dist)"),
       title = "Alternative Distance Measures")

## ---------------------------------------------------------------------------
## 3. Bandwidth sensitivity (varying pre/post window)
## ---------------------------------------------------------------------------

cat("\n=== Bandwidth Sensitivity ===\n")

bandwidths <- c(6, 9, 12, 18)
bw_results <- list()

for (bw in bandwidths) {
  rtep_bw <- rtep[date >= (as.Date("2023-06-01") - bw * 30.44) &
                    date <= (as.Date("2023-06-01") + bw * 30.44)]
  m <- tryCatch({
    feols(log_petrol ~ dist_post_100 | mkt_name + date,
          data = rtep_bw, cluster = ~adm1_name)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    bw_results[[as.character(bw)]] <- data.table(
      bandwidth_months = bw,
      estimate = coef(m)["dist_post_100"],
      se = se(m)["dist_post_100"],
      n = nobs(m)
    )
  }
}

# Add full sample as the last row
m_full <- feols(log_petrol ~ dist_post_100 | mkt_name + date,
                data = rtep, cluster = ~adm1_name)
bw_results[["full"]] <- data.table(
  bandwidth_months = 99,  # sentinel for full sample
  estimate = coef(m_full)["dist_post_100"],
  se = se(m_full)["dist_post_100"],
  n = nobs(m_full)
)

bw_dt <- rbindlist(bw_results)
cat("Bandwidth sensitivity:\n")
print(bw_dt)
fwrite(bw_dt, file.path(data_dir, "robustness_bandwidth.csv"))

## ---------------------------------------------------------------------------
## 4. Diesel prices (parallel outcome — also deregulated)
## ---------------------------------------------------------------------------

cat("\n=== Diesel Prices (Parallel Outcome) ===\n")

rtep_diesel <- rtep[!is.na(log_diesel)]
if (nrow(rtep_diesel) > 100) {
  m_diesel <- feols(log_diesel ~ dist_post_100 | mkt_name + date,
                    data = rtep_diesel, cluster = ~adm1_name)
  cat("Diesel estimate:", coef(m_diesel)["dist_post_100"], "\n")
  cat("Diesel SE:", se(m_diesel)["dist_post_100"], "\n")
}

## ---------------------------------------------------------------------------
## 5. Kerosene prices (parallel outcome)
## ---------------------------------------------------------------------------

cat("\n=== Kerosene Prices (Parallel Outcome) ===\n")

rtep_kero <- rtep[!is.na(log_kerosene)]
if (nrow(rtep_kero) > 100) {
  m_kerosene <- feols(log_kerosene ~ dist_post_100 | mkt_name + date,
                      data = rtep_kero, cluster = ~adm1_name)
  cat("Kerosene estimate:", coef(m_kerosene)["dist_post_100"], "\n")
  cat("Kerosene SE:", se(m_kerosene)["dist_post_100"], "\n")
}

## ---------------------------------------------------------------------------
## 6. Short-window preferred specification (±12 months)
## ---------------------------------------------------------------------------

cat("\n=== Short-Window Preferred Spec (±12 months) ===\n")

rtep_short <- rtep[date >= as.Date("2022-06-01") & date <= as.Date("2024-06-01")]
m_short <- feols(log_petrol ~ dist_post_100 | mkt_name + date,
                 data = rtep_short, cluster = ~adm1_name)
cat("Short-window estimate:", coef(m_short)["dist_post_100"], "\n")
cat("Short-window SE:", se(m_short)["dist_post_100"], "\n")
cat("Short-window N:", nobs(m_short), "\n")

## ---------------------------------------------------------------------------
## 7. Randomization inference (permute distance assignments)
## ---------------------------------------------------------------------------

cat("\n=== Randomization Inference ===\n")

n_perms <- 1000
actual_coef <- coef(feols(log_petrol ~ dist_post_100 | mkt_name + date,
                          data = rtep))["dist_post_100"]

# Permute distance across markets (break market-distance mapping)
market_list <- unique(rtep[, .(mkt_name, dist_100km)])
ri_coefs <- numeric(n_perms)

set.seed(42)
for (i in 1:n_perms) {
  rtep_perm <- copy(rtep)
  perm_dists <- market_list[sample(.N)]
  rtep_perm <- merge(rtep_perm[, !c("dist_100km"), with = FALSE],
                     data.table(mkt_name = market_list$mkt_name,
                                dist_100km = perm_dists$dist_100km),
                     by = "mkt_name")
  rtep_perm[, dist_post_100 := dist_100km * post]

  m_perm <- tryCatch({
    feols(log_petrol ~ dist_post_100 | mkt_name + date, data = rtep_perm)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    ri_coefs[i] <- coef(m_perm)["dist_post_100"]
  }
}

ri_p <- mean(abs(ri_coefs) >= abs(actual_coef))
cat("RI p-value:", ri_p, "\n")
cat("Actual coefficient:", actual_coef, "\n")
cat("RI distribution: mean =", mean(ri_coefs), ", sd =", sd(ri_coefs), "\n")

ri_result <- data.table(
  actual_coef = actual_coef,
  ri_p_value = ri_p,
  ri_mean = mean(ri_coefs),
  ri_sd = sd(ri_coefs),
  n_perms = n_perms
)
fwrite(ri_result, file.path(data_dir, "robustness_ri.csv"))

ri_dist <- data.table(perm_coef = ri_coefs)
fwrite(ri_dist, file.path(data_dir, "ri_distribution.csv"))

## ---------------------------------------------------------------------------
## 8. Placebo timing test (fake reform 1 year earlier)
## ---------------------------------------------------------------------------

cat("\n=== Placebo Timing (May 2022) ===\n")

rtep_pre <- rtep[date < as.Date("2023-06-01")]
rtep_pre[, placebo_post := as.integer(date >= as.Date("2022-06-01"))]
rtep_pre[, placebo_dist_post := dist_100km * placebo_post]

m_placebo <- feols(log_petrol ~ placebo_dist_post | mkt_name + date,
                   data = rtep_pre, cluster = ~adm1_name)
cat("Placebo estimate:", coef(m_placebo)["placebo_dist_post"], "\n")
cat("Placebo SE:", se(m_placebo)["placebo_dist_post"], "\n")
cat("Placebo p-value:", fixest::pvalue(m_placebo)["placebo_dist_post"], "\n")

## ---------------------------------------------------------------------------
## 9. Excluding Dangote Refinery period
## ---------------------------------------------------------------------------

cat("\n=== Excluding Post-Dangote Period ===\n")

# Dangote refinery began limited operations late 2023
rtep_pre_dangote <- rtep[date <= as.Date("2023-10-01")]
m_pre_dangote <- feols(log_petrol ~ dist_post_100 | mkt_name + date,
                       data = rtep_pre_dangote, cluster = ~adm1_name)
cat("Pre-Dangote estimate:", coef(m_pre_dangote)["dist_post_100"], "\n")
cat("Pre-Dangote SE:", se(m_pre_dangote)["dist_post_100"], "\n")

## ---------------------------------------------------------------------------
## 10. Commodity-by-Month Fixed Effects for Food
## ---------------------------------------------------------------------------

cat("\n=== Commodity-by-Month FE (Food Robustness) ===\n")

# Load food data
load(file.path(data_dir, "main_models.RData"))
wfp <- fread(file.path(data_dir, "wfp_clean.csv"))
wfp[, date := as.Date(date)]
wfp_food <- wfp[is_fuel == FALSE & !is.na(dist_nearest)]

# Create commodity-by-month identifier
wfp_food[, commodity_month := paste0(commodity, "_", date)]

# All food with commodity-by-month FE
m_food_commo_month <- feols(log_price ~ dist_post_100 | market_commodity + commodity_month,
                             data = wfp_food, cluster = ~admin1)

# Cereals with commodity-by-month FE
m_cereal_commo_month <- feols(log_price ~ dist_post_100 | market_commodity + commodity_month,
                               data = wfp_food[commodity_group == "Cereals"],
                               cluster = ~admin1)

cat("All food with commodity-month FE: beta =", round(coef(m_food_commo_month)["dist_post_100"], 4),
    ", SE =", round(se(m_food_commo_month)["dist_post_100"], 4), "\n")
cat("Cereals with commodity-month FE: beta =", round(coef(m_cereal_commo_month)["dist_post_100"], 4),
    ", SE =", round(se(m_cereal_commo_month)["dist_post_100"], 4), "\n")

# Save
commo_month_results <- data.table(
  model = c("All Food + Commodity-Month FE", "Cereals + Commodity-Month FE"),
  coefficient = c(coef(m_food_commo_month)["dist_post_100"],
                  coef(m_cereal_commo_month)["dist_post_100"]),
  se = c(se(m_food_commo_month)["dist_post_100"],
         se(m_cereal_commo_month)["dist_post_100"])
)
fwrite(commo_month_results, file.path(data_dir, "robustness_commodity_month_fe.csv"))

## ---------------------------------------------------------------------------
## Save all robustness results
## ---------------------------------------------------------------------------

save(loo_dt, bw_dt, ri_result,
     m_lagos, m_ph, m_logdist, m_placebo, m_pre_dangote,
     m_food_commo_month, m_cereal_commo_month,
     file = file.path(data_dir, "robustness_models.RData"))

## ---------------------------------------------------------------------------
## 11. Wild Cluster Bootstrap
## ---------------------------------------------------------------------------

cat("\n=== Conley Spatial HAC Standard Errors ===\n")

load(file.path(data_dir, "main_models.RData"))

# Conley SEs with 200km distance cutoff (conservative given mean distance ~917km)
conley_petrol <- tryCatch({
  vcov_conley(m_a2, lat = "lat", lon = "lon", cutoff = 200)
}, error = function(e) { cat("Conley petrol failed:", e$message, "\n"); NULL })

wfp_food <- wfp[is_fuel == FALSE & !is.na(dist_nearest)]
wfp_cer <- wfp_food[commodity_group == "Cereals"]

m_cer_conley <- feols(log_price ~ dist_post_100 | market_commodity + date,
                      data = wfp_cer, cluster = ~admin1)
conley_cereal <- tryCatch({
  vcov_conley(m_cer_conley, lat = "latitude", lon = "longitude", cutoff = 200)
}, error = function(e) { cat("Conley cereal failed:", e$message, "\n"); NULL })

# Extract SEs
conley_results <- data.table(
  model = character(), coefficient = numeric(),
  se_state_cluster = numeric(), se_conley_200km = numeric()
)

if (!is.null(conley_petrol)) {
  se_conley_p <- sqrt(diag(conley_petrol))["dist_post_100"]
  conley_results <- rbind(conley_results, data.table(
    model = "Petrol (Full, m_a2)",
    coefficient = coef(m_a2)["dist_post_100"],
    se_state_cluster = se(m_a2)["dist_post_100"],
    se_conley_200km = se_conley_p
  ))
}

if (!is.null(conley_cereal)) {
  se_conley_c <- sqrt(diag(conley_cereal))["dist_post_100"]
  conley_results <- rbind(conley_results, data.table(
    model = "Cereals",
    coefficient = coef(m_cer_conley)["dist_post_100"],
    se_state_cluster = se(m_cer_conley)["dist_post_100"],
    se_conley_200km = se_conley_c
  ))
}

fwrite(conley_results, file.path(data_dir, "conley_se_results.csv"))
cat("Conley SE results:\n")
print(conley_results)

cat("\n=== All robustness checks complete ===\n")
