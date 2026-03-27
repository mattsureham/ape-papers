# =============================================================================
# 04_robustness.R — Robustness checks and mechanism analysis
# apep_1068: Last Hired, Not First Fired
# =============================================================================

source("00_packages.R")

dt <- fread("../data/analysis_sample.csv")
black <- dt[black == 1]

cat(sprintf("Black sample: %s observations\n", format(nrow(black), big.mark = ",")))

# ============================================================================
# A. Alternative occupational measure: SEI
# ============================================================================
cat("\n=== Robustness: SEI measure ===\n")

sei_iv <- feols(sei_change_bust ~ age_1920 + age_sq + in_school +
                  farm_orig + married_1920 + sei_1920 |
                  migrant ~ log_instrument,
                data = black, cluster = ~origin_county)
etable(sei_iv, se.below = TRUE)

# ============================================================================
# B. Exclude return migrants
# ============================================================================
cat("\n=== Robustness: Exclude return migrants ===\n")

black_noreturn <- black[return_migrant == 0]
cat(sprintf("  Excluding %d return migrants\n", sum(black$return_migrant == 1)))

noreturn_iv <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
                       farm_orig + married_1920 + occscore_1920 |
                       migrant ~ log_instrument,
                     data = black_noreturn, cluster = ~origin_county)
etable(noreturn_iv, se.below = TRUE)

# ============================================================================
# C. With origin state FE (instrument weakens — documented)
# ============================================================================
cat("\n=== Robustness: Origin state FE (weak instrument check) ===\n")

iv_state_fe <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
                       farm_orig + married_1920 + occscore_1920 | statefip_1920 |
                       migrant ~ log_instrument,
                     data = black, cluster = ~origin_county)

fs_state_fe <- feols(migrant ~ log_instrument + age_1920 + age_sq + in_school +
                       farm_orig + married_1920 + occscore_1920 | statefip_1920,
                     data = black, cluster = ~origin_county)

fs_fe_t <- coef(fs_state_fe)["log_instrument"] / se(fs_state_fe)["log_instrument"]
cat(sprintf("  State FE first-stage F: %.1f (weak — instrument varies primarily across states)\n", fs_fe_t^2))
etable(iv_state_fe, se.below = TRUE)

# ============================================================================
# D. Instrument balance checks
# ============================================================================
cat("\n=== Balance: Instrument vs pre-determined covariates ===\n")

bal_age <- feols(age_1920 ~ log_instrument,
                 data = black, cluster = ~origin_county)
bal_school <- feols(in_school ~ log_instrument,
                    data = black, cluster = ~origin_county)
bal_farm <- feols(farm_orig ~ log_instrument,
                  data = black, cluster = ~origin_county)
bal_occ <- feols(occscore_1920 ~ log_instrument,
                 data = black, cluster = ~origin_county)
bal_married <- feols(married_1920 ~ log_instrument,
                     data = black, cluster = ~origin_county)

cat("Balance results (coefficient on instrument):\n")
etable(bal_age, bal_school, bal_farm, bal_occ, bal_married, se.below = TRUE)

# ============================================================================
# E. Leave-one-out IV (drop each destination city)
# ============================================================================
cat("\n=== Leave-one-out IV sensitivity ===\n")

destinations <- data.table(
  dest_name = c("Chicago", "Philadelphia", "New York", "Detroit",
                "Cleveland", "Pittsburgh", "St.Louis", "Indianapolis",
                "Cincinnati", "Columbus", "Baltimore", "Washington"),
  black_pop_1910 = c(44103, 84459, 91709, 5741, 8448, 25623,
                     43960, 21816, 19639, 12739, 84749, 94446),
  lat = c(41.88, 39.95, 40.71, 42.33, 41.50, 40.44,
          38.63, 39.77, 39.10, 39.96, 39.29, 38.91),
  lon = c(-87.63, -75.16, -74.01, -83.05, -81.69, -79.99,
          -90.20, -86.16, -84.51, -82.99, -76.61, -77.04)
)

haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 6371
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

loo_results <- data.table(
  dropped = character(),
  coef = numeric(),
  se = numeric()
)

for (d in seq_len(nrow(destinations))) {
  black[, loo_instrument := 0]
  for (j in seq_len(nrow(destinations))) {
    if (j == d) next
    dist_km <- haversine(black$origin_lat, black$origin_lon,
                         destinations$lat[j], destinations$lon[j])
    dist_km <- pmax(dist_km, 50)
    black[, loo_instrument := loo_instrument + destinations$black_pop_1910[j] / dist_km]
  }
  black[, log_loo := log(loo_instrument)]

  loo_mod <- tryCatch(
    feols(occ_change_bust ~ age_1920 + age_sq + in_school +
            farm_orig + married_1920 + occscore_1920 |
            migrant ~ log_loo,
          data = black, cluster = ~origin_county),
    error = function(e) NULL
  )

  if (!is.null(loo_mod)) {
    loo_results <- rbind(loo_results, data.table(
      dropped = destinations$dest_name[d],
      coef = coef(loo_mod)["fit_migrant"],
      se = se(loo_mod)["fit_migrant"]
    ))
  }
}

cat("Leave-one-out IV results:\n")
print(loo_results)

black[, c("loo_instrument", "log_loo") := NULL]

# ============================================================================
# F. Heterogeneity by school attendance
# ============================================================================
cat("\n=== Heterogeneity: School attendance ===\n")

iv_school <- feols(occ_change_bust ~ age_1920 + age_sq +
                     farm_orig + married_1920 + occscore_1920 |
                     migrant ~ log_instrument,
                   data = black[in_school == 1], cluster = ~origin_county)

iv_noschool <- feols(occ_change_bust ~ age_1920 + age_sq +
                       farm_orig + married_1920 + occscore_1920 |
                       migrant ~ log_instrument,
                     data = black[in_school == 0], cluster = ~origin_county)

cat("In school:\n")
etable(iv_school, se.below = TRUE)
cat("Not in school:\n")
etable(iv_noschool, se.below = TRUE)

# ============================================================================
# G. Heterogeneity by farm origin
# ============================================================================
cat("\n=== Heterogeneity: Farm vs Non-farm Origin ===\n")

iv_farm <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
                   married_1920 + occscore_1920 |
                   migrant ~ log_instrument,
                 data = black[farm_orig == 1], cluster = ~origin_county)

iv_nonfarm <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
                      married_1920 + occscore_1920 |
                      migrant ~ log_instrument,
                    data = black[farm_orig == 0], cluster = ~origin_county)

cat("Farm origin:\n")
etable(iv_farm, se.below = TRUE)
cat("Non-farm origin:\n")
etable(iv_nonfarm, se.below = TRUE)

# ============================================================================
# Save robustness models
# ============================================================================
save(sei_iv, noreturn_iv, iv_state_fe,
     bal_age, bal_school, bal_farm, bal_occ, bal_married,
     loo_results, iv_school, iv_noschool, iv_farm, iv_nonfarm,
     file = "../data/robustness_models.RData")

cat("\nRobustness checks complete.\n")
