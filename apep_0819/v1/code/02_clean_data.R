# 02_clean_data.R — Construct district-year panel
# apep_0819: Media salience and disaster recovery in India

source("00_packages.R")

cat("=== CONSTRUCTING PANEL ===\n")

# ── Load raw data ─────────────────────────────────────────────────────

viirs <- fread("data/shrug_viirs_district.csv")
td <- fread("data/shrug_crosswalk.csv")
pca <- fread("data/shrug_census2011.csv")
rain <- fread("data/nasa_power_rainfall.csv")
competing <- fread("data/competing_events.csv")
state_map <- fread("data/state_map.csv")

# ── 1. Construct monsoon rainfall anomalies ───────────────────────────
# Monsoon season: June-September (months 6-9)

cat("Computing monsoon rainfall anomalies...\n")

monsoon <- rain[month %in% 6:9, .(
  monsoon_precip = mean(precip_mm_day, na.rm = TRUE)
), by = .(pc11_state_id, state_name, year)]

# Compute state-specific long-run mean and SD
monsoon[, `:=`(
  state_mean_precip = mean(monsoon_precip, na.rm = TRUE),
  state_sd_precip = sd(monsoon_precip, na.rm = TRUE)
), by = pc11_state_id]

# Rainfall anomaly: z-score of monsoon rainfall
monsoon[, rain_anomaly := (monsoon_precip - state_mean_precip) / state_sd_precip]

# Flood exposure: above-median monsoon (positive anomaly = wetter than normal)
monsoon[, flood_exposed := as.integer(rain_anomaly > 0)]

# Extreme flood: top quartile of rainfall anomaly
monsoon[, extreme_rain := as.integer(rain_anomaly > quantile(rain_anomaly, 0.75, na.rm = TRUE)),
        by = pc11_state_id]

cat(sprintf("  Monsoon data: %d state-years\n", nrow(monsoon)))
cat(sprintf("  Flood-exposed state-years: %d (%.0f%%)\n",
            sum(monsoon$flood_exposed), mean(monsoon$flood_exposed) * 100))

# ── 2. Build district-year nightlights panel ──────────────────────────

cat("Building district-year nightlights panel...\n")

# Restrict to 2013-2021 (need t-1 for growth, VIIRS starts 2012)
nl <- viirs[year >= 2012 & year <= 2021,
            .(pc11_district_id, pc11_state_id, year,
              nl_mean = viirs_annual_mean, nl_sum = viirs_annual_sum)]

# Merge with crosswalk for population and area
nl <- merge(nl, td[, .(pc11_state_id, pc11_district_id,
                        pc11_td_tot_p, pc11_td_area, pc11_td_avg_rain)],
            by = c("pc11_state_id", "pc11_district_id"), all.x = TRUE)

# Merge with Census population
nl <- merge(nl, pca[, .(pc11_state_id, pc11_district_id,
                         pc11_pca_tot_p, pc11_pca_p_lit, pc11_pca_p_sc,
                         pc11_pca_p_st, pc11_pca_tot_work_p)],
            by = c("pc11_state_id", "pc11_district_id"), all.x = TRUE)

# Compute nightlights growth
setorder(nl, pc11_district_id, year)
nl[, nl_growth := log(nl_mean + 0.01) - shift(log(nl_mean + 0.01), 1),
   by = pc11_district_id]

# Forward nightlights (recovery measure: next year's NL given this year's shock)
nl[, nl_forward := shift(nl_mean, -1, type = "lead"), by = pc11_district_id]
nl[, nl_forward_growth := log(nl_forward + 0.01) - log(nl_mean + 0.01)]

# ── 3. Merge monsoon rainfall and competing events ────────────────────

cat("Merging monsoon and competing event data...\n")

# Merge state-level monsoon data
panel <- merge(nl, monsoon[, .(pc11_state_id, year, monsoon_precip,
                                rain_anomaly, flood_exposed, extreme_rain)],
               by = c("pc11_state_id", "year"), all.x = TRUE)

# Merge year-level competing events
panel <- merge(panel, competing[, .(year, competing_index, sports_event)],
               by = "year", all.x = TRUE)

# ── 4. Construct treatment variables ──────────────────────────────────

cat("Constructing treatment variables...\n")

# District-level flood proneness (cross-sectional from SHRUG avg rainfall)
panel[, flood_prone := as.integer(pc11_td_avg_rain > median(pc11_td_avg_rain, na.rm = TRUE))]

# Triple-diff interactions
panel[, `:=`(
  # Core: flood exposure × competing news
  flood_x_competing = flood_exposed * competing_index,
  # Extreme rain × competing
  extreme_x_competing = extreme_rain * competing_index,
  # Continuous: rain anomaly × competing
  rain_x_competing = rain_anomaly * competing_index,
  # Sports-only instrument
  flood_x_sports = flood_exposed * sports_event,
  rain_x_sports = rain_anomaly * sports_event
)]

# ── 5. Census-based controls ─────────────────────────────────────────

panel[, `:=`(
  log_pop = log(pc11_pca_tot_p + 1),
  lit_rate = pc11_pca_p_lit / pc11_pca_tot_p,
  sc_share = pc11_pca_p_sc / pc11_pca_tot_p,
  st_share = pc11_pca_p_st / pc11_pca_tot_p,
  work_rate = pc11_pca_tot_work_p / pc11_pca_tot_p
)]

# ── 6. District and state identifiers ─────────────────────────────────

panel[, dist_id := paste0(pc11_state_id, "_", pc11_district_id)]

# Restrict to analysis sample: 2013-2020 (need t+1 for forward NL)
analysis <- panel[year >= 2013 & year <= 2020 & !is.na(nl_forward_growth)
                  & !is.na(rain_anomaly) & !is.na(competing_index)]

cat(sprintf("\n  Full panel: %d district-years\n", nrow(panel)))
cat(sprintf("  Analysis sample: %d district-years\n", nrow(analysis)))
cat(sprintf("  Districts: %d\n", uniqueN(analysis$dist_id)))
cat(sprintf("  Years: %d-%d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("  States: %d\n", uniqueN(analysis$pc11_state_id)))

# ── 7. Summary statistics ─────────────────────────────────────────────

cat("\n=== KEY SUMMARY STATISTICS ===\n")
cat(sprintf("  NL forward growth: mean=%.3f, sd=%.3f\n",
            mean(analysis$nl_forward_growth, na.rm = TRUE),
            sd(analysis$nl_forward_growth, na.rm = TRUE)))
cat(sprintf("  Rain anomaly: mean=%.3f, sd=%.3f\n",
            mean(analysis$rain_anomaly, na.rm = TRUE),
            sd(analysis$rain_anomaly, na.rm = TRUE)))
cat(sprintf("  Competing index: mean=%.3f, sd=%.3f\n",
            mean(analysis$competing_index, na.rm = TRUE),
            sd(analysis$competing_index, na.rm = TRUE)))
cat(sprintf("  Flood exposed: %.0f%%\n",
            mean(analysis$flood_exposed, na.rm = TRUE) * 100))

# ── Save ──────────────────────────────────────────────────────────────

fwrite(analysis, "data/analysis_panel.csv")
fwrite(monsoon, "data/monsoon_anomalies.csv")

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
