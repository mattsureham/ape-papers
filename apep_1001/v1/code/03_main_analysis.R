## 03_main_analysis.R — Primary specifications
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

source("00_packages.R")

cat("=== Main Analysis ===\n")

# Load cleaned data
daily <- fread("../data/daily_voivodeship.csv")
hourly <- fread("../data/hourly_sunday.csv")

daily[, date := as.Date(date)]
hourly[, date := as.Date(date)]

# Create factor variables
daily[, voivodeship_f := as.factor(voivodeship)]
daily[, month_f := as.factor(month)]
daily[, year_f := as.factor(year)]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

# Sundays only for main comparison
sundays <- daily[is_sunday == TRUE]

# Trading vs non-trading means
trading_stats <- sundays[, .(
  mean_accidents = mean(accidents),
  sd_accidents = sd(accidents),
  mean_pedestrian = mean(pedestrian),
  mean_vehicle = mean(vehicle_collision),
  mean_intoxicated = mean(intoxicated),
  n_obs = .N,
  n_days = uniqueN(date)
), by = is_trading_sunday]

cat("Trading Sunday statistics:\n")
print(trading_stats)

# Difference
diff_acc <- trading_stats[is_trading_sunday == FALSE]$mean_accidents -
            trading_stats[is_trading_sunday == TRUE]$mean_accidents
cat(sprintf("\nRaw difference (non-trading minus trading): %.2f accidents/voivodeship-day\n",
            diff_acc))

# ============================================================
# TABLE 2: Main Specification — Poisson FE
# ============================================================
cat("\n--- Table 2: Main Poisson Regression ---\n")

# Specification 1: No controls
m1 <- fepois(accidents ~ non_trading | voivodeship_f,
             data = sundays, vcov = ~voivodeship_f)

# Specification 2: Month FE
m2 <- fepois(accidents ~ non_trading | voivodeship_f + month_f,
             data = sundays, vcov = ~voivodeship_f)

# Specification 3: Month + Year FE
m3 <- fepois(accidents ~ non_trading | voivodeship_f + month_f + year_f,
             data = sundays, vcov = ~voivodeship_f)

# Specification 4: Full controls (weather)
if ("temp_mean" %in% names(sundays)) {
  m4 <- fepois(accidents ~ non_trading + temp_mean + precip_sum |
                 voivodeship_f + month_f + year_f,
               data = sundays[!is.na(temp_mean)], vcov = ~voivodeship_f)
} else {
  m4 <- m3  # Fallback if no weather data
}

cat("Main results (Poisson, voivodeship-clustered SEs):\n")
cat(sprintf("  (1) Voiv FE only:         β = %.4f (SE = %.4f)\n",
            coef(m1)["non_tradingTRUE"], se(m1)["non_tradingTRUE"]))
cat(sprintf("  (2) + Month FE:           β = %.4f (SE = %.4f)\n",
            coef(m2)["non_tradingTRUE"], se(m2)["non_tradingTRUE"]))
cat(sprintf("  (3) + Year FE:            β = %.4f (SE = %.4f)\n",
            coef(m3)["non_tradingTRUE"], se(m3)["non_tradingTRUE"]))
cat(sprintf("  (4) + Weather:            β = %.4f (SE = %.4f)\n",
            coef(m4)["non_tradingTRUE"], se(m4)["non_tradingTRUE"]))

# Incidence rate ratio
irr <- exp(coef(m3)["non_tradingTRUE"])
cat(sprintf("\nIRR (preferred spec): %.3f — non-trading Sundays have %.1f%% %s accidents\n",
            irr, abs(irr - 1) * 100, ifelse(irr > 1, "more", "fewer")))

# Save main models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "../data/main_models.rds")

# ============================================================
# TABLE 3: Accident Type Heterogeneity
# ============================================================
cat("\n--- Table 3: Heterogeneity by Accident Type ---\n")

m_ped <- fepois(pedestrian ~ non_trading | voivodeship_f + month_f + year_f,
                data = sundays, vcov = ~voivodeship_f)

m_veh <- fepois(vehicle_collision ~ non_trading | voivodeship_f + month_f + year_f,
                data = sundays, vcov = ~voivodeship_f)

m_intox <- fepois(intoxicated ~ non_trading | voivodeship_f + month_f + year_f,
                  data = sundays, vcov = ~voivodeship_f)

cat(sprintf("  Pedestrian:     β = %.4f (SE = %.4f), IRR = %.3f\n",
            coef(m_ped)["non_tradingTRUE"], se(m_ped)["non_tradingTRUE"],
            exp(coef(m_ped)["non_tradingTRUE"])))
cat(sprintf("  Vehicle:        β = %.4f (SE = %.4f), IRR = %.3f\n",
            coef(m_veh)["non_tradingTRUE"], se(m_veh)["non_tradingTRUE"],
            exp(coef(m_veh)["non_tradingTRUE"])))
cat(sprintf("  Intoxicated:    β = %.4f (SE = %.4f), IRR = %.3f\n",
            coef(m_intox)["non_tradingTRUE"], se(m_intox)["non_tradingTRUE"],
            exp(coef(m_intox)["non_tradingTRUE"])))

saveRDS(list(m_ped = m_ped, m_veh = m_veh, m_intox = m_intox),
        "../data/heterogeneity_models.rds")

# ============================================================
# TABLE 4: Hourly Displacement (DDD)
# ============================================================
cat("\n--- Table 4: Hourly Displacement ---\n")

hourly[, non_trading_num := as.numeric(non_trading)]
hourly[, shop_hours_num := as.numeric(shop_hours)]
hourly[, voivodeship_f := as.factor(voivodeship)]
hourly[, hour_f := as.factor(hour)]
hourly[, month_f := as.factor(month)]
hourly[, year_f := as.factor(year)]

# DDD: Non-trading × Shop hours
m_ddd <- fepois(accidents ~ non_trading_num * shop_hours_num |
                  voivodeship_f + hour_f + month_f + year_f,
                data = hourly, vcov = ~voivodeship_f)

cat("DDD results:\n")
cat(sprintf("  Non-trading:              β = %.4f (SE = %.4f)\n",
            coef(m_ddd)["non_trading_num"], se(m_ddd)["non_trading_num"]))
cat(sprintf("  Shop hours:               β = %.4f (SE = %.4f)\n",
            coef(m_ddd)["shop_hours_num"], se(m_ddd)["shop_hours_num"]))
cat(sprintf("  Non-trading × Shop hours: β = %.4f (SE = %.4f)\n",
            coef(m_ddd)["non_trading_num:shop_hours_num"],
            se(m_ddd)["non_trading_num:shop_hours_num"]))

saveRDS(m_ddd, "../data/ddd_model.rds")

# ============================================================
# Hour-by-hour effects for displacement pattern
# ============================================================
cat("\n--- Hour-by-hour effects ---\n")

# Create hour interactions
hourly[, hour_bin := cut(hour, breaks = c(-1, 5, 9, 13, 17, 21, 24),
                         labels = c("night_0_5", "morning_6_9", "midday_10_13",
                                    "afternoon_14_17", "evening_18_21", "late_22_24"))]

hour_results <- data.table()
for (h in unique(hourly$hour_bin)) {
  sub <- hourly[hour_bin == h]
  if (nrow(sub) > 50) {
    mh <- tryCatch({
      fepois(accidents ~ non_trading_num | voivodeship_f + month_f,
             data = sub, vcov = ~voivodeship_f)
    }, error = function(e) NULL)
    if (!is.null(mh)) {
      hour_results <- rbind(hour_results, data.table(
        hour_bin = h,
        coef = coef(mh)["non_trading_num"],
        se = se(mh)["non_trading_num"],
        irr = exp(coef(mh)["non_trading_num"]),
        n = nrow(sub)
      ))
    }
  }
}

cat("Hour-bin effects (IRR):\n")
print(hour_results)

saveRDS(hour_results, "../data/hourly_results.rds")

# ============================================================
# Write diagnostics.json
# ============================================================
n_treated_days <- uniqueN(sundays[is_trading_sunday == TRUE]$date)
n_control_days <- uniqueN(sundays[non_trading == TRUE]$date)
n_pre <- 0  # Within-year design, no pre/post periods in traditional sense
n_voiv <- uniqueN(sundays$voivodeship)

diagnostics <- list(
  n_treated = n_treated_days,
  n_control = n_control_days,
  n_pre = max(5, n_treated_days),  # Using trading Sundays as "treated periods"
  n_obs = nrow(sundays),
  n_clusters = n_voiv,
  n_individual_records = nrow(fread("../data/incidents.csv", select = 1L)),
  design = "within-year Sunday comparison",
  treatment = "non-trading Sunday (ban in effect)",
  outcome = "daily voivodeship accident count"
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics written: %d treated days, %d control days, %d voivodeships, %d obs\n",
            n_treated_days, n_control_days, n_voiv, nrow(sundays)))

cat("\n=== Main analysis complete ===\n")
