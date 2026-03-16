# 04_robustness.R — Robustness checks
# apep_0709: Markets Under Fire

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
market_treatment <- readRDS(file.path(data_dir, "market_treatment.rds"))
ged <- fread(file.path(data_dir, "ucdp_ged_bfa.csv"))

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Alternative treatment radii (30km, 75km, 100km)
# ============================================================
cat("\n--- Alternative Treatment Radii ---\n")

markets <- unique(panel[, .(market_id, market_name, latitude, longitude)])
alt_radii <- c(30, 75, 100)
radius_results <- list()

for (r in alt_radii) {
  cat(sprintf("  Radius: %dkm...\n", r))

  # Recompute treatment at this radius
  event_coords_r <- cbind(ged$longitude, ged$latitude)
  mt_list <- lapply(1:nrow(markets), function(i) {
    mkt <- markets[i]
    mkt_coords <- matrix(c(mkt$longitude, mkt$latitude), ncol = 2,
                          nrow = nrow(ged), byrow = TRUE)
    dists <- geosphere::distHaversine(mkt_coords, event_coords_r) / 1000
    within <- which(dists <= r)
    if (length(within) > 0) {
      first_idx <- within[which.min(ged$date_start[within])]
      first_date <- as.Date(ged$date_start[first_idx])
      data.table(market_id = mkt$market_id, treated_r = TRUE,
                 first_event_ym_r = as.Date(paste0(format(first_date, "%Y-%m"), "-01")))
    } else {
      data.table(market_id = mkt$market_id, treated_r = FALSE,
                 first_event_ym_r = as.Date(NA))
    }
  })
  mt_r <- rbindlist(mt_list)

  # Merge and run CS at quarterly frequency
  panel_r <- merge(panel[, .(market_id, ym, log_price, year, month)],
                   mt_r, by = "market_id")
  panel_r[, quarter := ceiling(month / 3)]
  panel_r[, t_q := (year - 2012) * 4 + quarter]

  cs_r_data <- panel_r[, .(log_price = mean(log_price, na.rm = TRUE)),
                        by = .(market_id, t_q, treated_r, first_event_ym_r)]
  cs_r_data[, g_q := ifelse(
    treated_r,
    (year(first_event_ym_r) - 2012) * 4 + ceiling(month(first_event_ym_r) / 3),
    0
  )]

  # Balance
  grid_r <- CJ(market_id = unique(cs_r_data$market_id), t_q = unique(cs_r_data$t_q))
  cs_r_data <- merge(grid_r, cs_r_data, by = c("market_id", "t_q"), all.x = TRUE)
  cs_r_data[, g_q := max(g_q, na.rm = TRUE), by = market_id]
  cs_r_data[is.infinite(g_q), g_q := 0]
  cs_r_data[, log_price := nafill(nafill(log_price, "locf"), "nocb"), by = market_id]
  cs_r_data <- cs_r_data[!is.na(log_price)]

  n_treated <- uniqueN(cs_r_data$market_id[cs_r_data$g_q > 0])
  n_control <- uniqueN(cs_r_data$market_id[cs_r_data$g_q == 0])

  if (n_treated >= 3 & n_control >= 2) {
    cs_r <- tryCatch({
      out <- att_gt(
        yname = "log_price", tname = "t_q", idname = "market_id", gname = "g_q",
        data = as.data.frame(cs_r_data), control_group = "notyettreated",
        anticipation = 0, base_period = "varying"
      )
      aggte(out, type = "simple")
    }, error = function(e) { cat(sprintf("    Failed: %s\n", e$message)); NULL })

    if (!is.null(cs_r)) {
      radius_results[[as.character(r)]] <- list(
        att = cs_r$overall.att, se = cs_r$overall.se,
        n_treated = n_treated, n_control = n_control
      )
      cat(sprintf("    ATT: %.4f (SE: %.4f), treated: %d, control: %d\n",
                  cs_r$overall.att, cs_r$overall.se, n_treated, n_control))
    }
  }
}

saveRDS(radius_results, file.path(data_dir, "radius_results.rds"))

# ============================================================
# 2. Placebo test: imported rice only
# ============================================================
cat("\n--- Placebo: Imported Rice ---\n")

rice_data <- panel[commodity_clean == "Rice"]
rice_data[, quarter := ceiling(month / 3)]
rice_data[, t_q := (year - 2012) * 4 + quarter]
rice_market <- rice_data[, .(
  log_price = mean(log_price, na.rm = TRUE)
), by = .(market_id, t_q, treated, first_event_ym)]

rice_market[, g_q := ifelse(
  treated,
  (year(first_event_ym) - 2012) * 4 + ceiling(month(first_event_ym) / 3),
  0
)]

# Balance
rice_grid <- CJ(market_id = unique(rice_market$market_id), t_q = unique(rice_market$t_q))
rice_market <- merge(rice_grid, rice_market, by = c("market_id", "t_q"), all.x = TRUE)
rice_market[, g_q := max(g_q, na.rm = TRUE), by = market_id]
rice_market[is.infinite(g_q), g_q := 0]
rice_market[, log_price := nafill(nafill(log_price, "locf"), "nocb"), by = market_id]
rice_market <- rice_market[!is.na(log_price)]

n_t_rice <- uniqueN(rice_market$market_id[rice_market$g_q > 0])
n_c_rice <- uniqueN(rice_market$market_id[rice_market$g_q == 0])
cat(sprintf("  Rice panel: %d treated, %d control markets\n", n_t_rice, n_c_rice))

if (n_t_rice >= 3) {
  cs_rice <- tryCatch({
    out <- att_gt(
      yname = "log_price", tname = "t_q", idname = "market_id", gname = "g_q",
      data = as.data.frame(rice_market), control_group = "notyettreated",
      anticipation = 0, base_period = "varying"
    )
    aggte(out, type = "simple")
  }, error = function(e) { cat(sprintf("  Failed: %s\n", e$message)); NULL })

  if (!is.null(cs_rice)) {
    cat(sprintf("  Rice ATT: %.4f (SE: %.4f)\n",
                cs_rice$overall.att, cs_rice$overall.se))
    saveRDS(cs_rice, file.path(data_dir, "cs_rice_placebo.rds"))
  }
}

# ============================================================
# 3. Intensity measure: cumulative events
# ============================================================
cat("\n--- Intensity: Cumulative Events ---\n")

# Create monthly event count within 50km of each market
panel_intensity <- copy(panel)

# For each market-month, count events within 50km up to that month
event_coords_int <- cbind(ged$longitude, ged$latitude)
int_list <- lapply(1:nrow(markets), function(i) {
  mkt <- markets[i]
  mkt_coords <- matrix(c(mkt$longitude, mkt$latitude), ncol = 2,
                        nrow = nrow(ged), byrow = TRUE)
  dists <- geosphere::distHaversine(mkt_coords, event_coords_int) / 1000

  nearby_events <- ged[dists <= 50]

  if (nrow(nearby_events) > 0) {
    nearby_events[, ym := as.Date(paste0(format(as.Date(date_start), "%Y-%m"), "-01"))]
    monthly <- nearby_events[, .(
      events_month = .N,
      fatalities_month = sum(best, na.rm = TRUE)
    ), by = ym]
    monthly[order(ym), cum_events := cumsum(events_month)]
    monthly[order(ym), cum_fatalities := cumsum(fatalities_month)]
    monthly[, market_id := mkt$market_id]
    monthly
  } else {
    data.table(ym = as.Date(character(0)), events_month = integer(0),
               fatalities_month = integer(0), cum_events = integer(0),
               cum_fatalities = integer(0), market_id = integer(0))
  }
})
intensity_data <- rbindlist(int_list)

# Merge into panel
panel_intensity <- merge(panel, intensity_data,
                         by = c("market_id", "ym"), all.x = TRUE)
panel_intensity[is.na(events_month), events_month := 0]
panel_intensity[is.na(cum_events), cum_events := 0]

# TWFE with intensity (continuous treatment)
intensity_fit <- feols(
  log_price ~ log(cum_events + 1) | market_id + ym,
  data = panel_intensity,
  cluster = ~market_id
)

cat(sprintf("  Intensity (log cum events): %.4f (SE: %.4f)\n",
            coef(intensity_fit)[1], se(intensity_fit)[1]))

saveRDS(intensity_fit, file.path(data_dir, "intensity_fit.rds"))

# ============================================================
# 4. Pre-trend formal test
# ============================================================
cat("\n--- Pre-Trend Assessment ---\n")

cs_dynamic <- readRDS(file.path(data_dir, "cs_dynamic.rds"))

# Extract pre-treatment coefficients
pre_idx <- cs_dynamic$egt < 0
pre_coefs <- cs_dynamic$att.egt[pre_idx]
pre_ses <- cs_dynamic$se.egt[pre_idx]
pre_times <- cs_dynamic$egt[pre_idx]

cat("  Pre-treatment event-study coefficients:\n")
for (i in seq_along(pre_coefs)) {
  sig <- ifelse(abs(pre_coefs[i] / pre_ses[i]) > 1.96, "*", "")
  cat(sprintf("    t=%d: %.4f (%.4f)%s\n",
              pre_times[i], pre_coefs[i], pre_ses[i], sig))
}

# Joint test: are all pre-treatment coefficients zero?
# Simple Wald-like test
if (length(pre_coefs) > 0 & all(!is.na(pre_ses)) & all(pre_ses > 0)) {
  wald_stat <- sum((pre_coefs / pre_ses)^2)
  wald_df <- length(pre_coefs)
  wald_p <- 1 - pchisq(wald_stat, df = wald_df)
  cat(sprintf("  Joint pre-trend test: chi2(%d) = %.2f, p = %.4f\n",
              wald_df, wald_stat, wald_p))
}

# Save all robustness results
robustness_summary <- list(
  radius_results = radius_results,
  intensity_coef = coef(intensity_fit)[1],
  intensity_se = se(intensity_fit)[1],
  pre_trend_p = if (exists("wald_p")) wald_p else NA
)
saveRDS(robustness_summary, file.path(data_dir, "robustness_summary.rds"))

cat("\n=== Robustness checks complete ===\n")
