# ── 01_fetch_data.R ────────────────────────────────────────────────
# Load SHRUG nightlights and construct district-level panel
# ───────────────────────────────────────────────────────────────────
source("code/00_packages.R")

shrug_dir <- normalizePath(file.path(getwd(), "..", "..", "..", "data", "india_shrug"))

# ── 1. Load district crosswalk (small) ────────────────────────────
cat("Loading district crosswalk...\n")
dist_key <- fread(file.path(shrug_dir, "shrid_pc11dist_key.csv"))
stopifnot(nrow(dist_key) > 500000)
cat(sprintf("  %d village-to-district mappings\n", nrow(dist_key)))

# ── 2. Load VIIRS nightlights and aggregate to district level ─────
# VIIRS is 1.6GB at village level; aggregate immediately to save RAM
cat("Loading VIIRS nightlights (aggregating to district level)...\n")
viirs <- fread(
  file.path(shrug_dir, "viirs_annual_shrid.csv"),
  select = c("shrid2", "viirs_annual_mean", "viirs_annual_sum",
             "viirs_annual_num_cells", "year")
)
stopifnot(nrow(viirs) > 1000000)
cat(sprintf("  %d village-year observations loaded\n", nrow(viirs)))

# Merge with district IDs
viirs <- merge(viirs, dist_key, by = "shrid2", all.x = FALSE)

# Aggregate to district-year level
cat("Aggregating to district-year level...\n")
district_nl <- viirs[, .(
  total_light    = sum(viirs_annual_sum, na.rm = TRUE),
  mean_light     = weighted.mean(viirs_annual_mean, viirs_annual_num_cells, na.rm = TRUE),
  n_villages     = .N,
  total_cells    = sum(viirs_annual_num_cells, na.rm = TRUE)
), by = .(pc11_state_id, pc11_district_id, year)]

rm(viirs); gc()
cat(sprintf("  %d VIIRS district-year observations\n", nrow(district_nl)))

# ── 2b. Load DMSP nightlights (2008-2011) to extend pre-period ───
# DMSP covers 1994-2013; we use 2008-2011 to add 4 more pre-treatment years
# (VIIRS starts 2012, so 2012+ uses VIIRS; 2008-2011 uses DMSP)
cat("Loading DMSP nightlights (2008-2011)...\n")
dmsp <- fread(
  file.path(shrug_dir, "dmsp_shrid.csv"),
  select = c("shrid2", "dmsp_total_light_cal", "dmsp_mean_light_cal",
             "dmsp_num_cells", "year")
)
dmsp <- dmsp[year %in% 2008:2011]
stopifnot(nrow(dmsp) > 500000)
cat(sprintf("  %d DMSP village-year observations for 2008-2011\n", nrow(dmsp)))

dmsp <- merge(dmsp, dist_key, by = "shrid2", all.x = FALSE)

dmsp_dist <- dmsp[, .(
  total_light    = sum(dmsp_total_light_cal, na.rm = TRUE),
  mean_light     = weighted.mean(dmsp_mean_light_cal, dmsp_num_cells, na.rm = TRUE),
  n_villages     = .N,
  total_cells    = sum(dmsp_num_cells, na.rm = TRUE)
), by = .(pc11_state_id, pc11_district_id, year)]

rm(dmsp); gc()
cat(sprintf("  %d DMSP district-year observations\n", nrow(dmsp_dist)))

# Combine DMSP (2008-2011) + VIIRS (2012-2023)
# District FE absorb level differences between sensors
district_nl <- rbind(dmsp_dist, district_nl)
rm(dmsp_dist)
cat(sprintf("  %d combined district-year observations (2008-2023)\n", nrow(district_nl)))

# ── 3. Load Census 2011 PCA for baseline controls ────────────────
cat("Loading Census 2011 PCA...\n")
pca <- fread(file.path(shrug_dir, "pc11_pca_clean_shrid.csv"),
             select = c("shrid2", "pc11_pca_tot_p", "pc11_pca_p_lit",
                        "pc11_pca_p_sc", "pc11_pca_p_st",
                        "pc11_pca_tot_work_p"))
pca <- merge(pca, dist_key, by = "shrid2", all.x = FALSE)

# District-level baselines
district_base <- pca[, .(
  pop_2011       = sum(pc11_pca_tot_p, na.rm = TRUE),
  lit_rate       = sum(pc11_pca_p_lit, na.rm = TRUE) / sum(pc11_pca_tot_p, na.rm = TRUE),
  sc_share       = sum(pc11_pca_p_sc, na.rm = TRUE) / sum(pc11_pca_tot_p, na.rm = TRUE),
  st_share       = sum(pc11_pca_p_st, na.rm = TRUE) / sum(pc11_pca_tot_p, na.rm = TRUE),
  work_rate      = sum(pc11_pca_tot_work_p, na.rm = TRUE) / sum(pc11_pca_tot_p, na.rm = TRUE)
), by = .(pc11_state_id, pc11_district_id)]

rm(pca); gc()

# ── 4. 14th Finance Commission formula weights ───────────────────
# Official devolution shares from 14th FC Report (2015-2020)
# Source: Report of the Fourteenth Finance Commission, Table 8.5
# These shares determine each state's percentage of the total divisible pool
cat("Loading 14th FC formula weights...\n")

fc14_shares <- data.table(
  pc11_state_id = as.integer(c(
    28, 12, 18, 10,  22, 30,  24, 06, 02,  1, 20, 29, 32,
    23,  27, 14, 17, 15,  13, 21, 03, 08, 11, 04, 36, 16,  9, 05, 19
  )),
  state_name = c(
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jammu & Kashmir",
    "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra",
    "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha",
    "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
    "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
  ),
  fc14_share = c(
    4.305, 1.370, 3.311, 9.665, 3.080,
    0.378, 3.084, 1.084, 0.713, 1.854,
    3.139, 4.713, 2.500, 7.548, 5.521,
    0.617, 0.642, 0.460, 0.498, 4.642,
    1.577, 5.495, 0.367, 4.023, 2.437,
    0.642, 17.959, 1.052, 7.324
  ),
  # 13th FC shares for comparison (2010-2015)
  # Source: Report of the Thirteenth Finance Commission, Table 8.3
  fc13_share = c(
    6.937, 0.328, 3.235, 10.917, 2.476,
    0.266, 3.569, 1.048, 0.521, 1.551,
    2.802, 4.328, 2.341, 6.711, 5.199,
    0.451, 0.408, 0.226, 0.314, 4.779,
    1.389, 5.853, 0.194, 5.047, 0.000,
    0.428, 19.677, 0.938, 7.264
  )
)

# Compute per-capita windfall intensity
# Total central tax devolution ~Rs 39.5 lakh crore over 14th FC period (2015-2020)
# 14th FC: 42% of divisible pool; 13th FC: 32% of divisible pool
# We use the SHARE CHANGE as treatment intensity (per-capita, normalized)
# Note: Telangana fc13_share = 0 because it was part of AP;
#   for clean identification, we combine AP+Telangana or drop Telangana

# State population from Census 2011 for per-capita normalization
state_pop <- district_base[, .(state_pop_2011 = sum(pop_2011)), by = pc11_state_id]
fc14_shares <- merge(fc14_shares, state_pop, by = "pc11_state_id", all.x = TRUE)

# Per-capita windfall: net gain from 14th FC reform
# Net share = (42% × 14th FC share) - (32% × 13th FC share)
# This captures the ACTUAL change in central transfers each state receives
fc14_shares[, share_change := fc14_share - fc13_share]
fc14_shares[, net_share := 0.42 * fc14_share - 0.32 * fc13_share]
fc14_shares[, windfall_pc := (net_share / 100) / (state_pop_2011 / 1e7)]
# Normalize to standard deviation units for interpretability
fc14_shares[, windfall_pc_z := (windfall_pc - mean(windfall_pc, na.rm = TRUE)) /
              sd(windfall_pc, na.rm = TRUE)]

cat("State-level windfall variation:\n")
print(fc14_shares[order(-windfall_pc), .(state_name, fc14_share, fc13_share,
                                          share_change, windfall_pc_z)][1:10])

# ── 5. Merge everything ──────────────────────────────────────────
panel <- merge(district_nl, district_base,
               by = c("pc11_state_id", "pc11_district_id"), all.x = TRUE)
panel <- merge(panel, fc14_shares[, .(pc11_state_id, fc14_share, fc13_share,
                                       share_change, windfall_pc, windfall_pc_z,
                                       state_name)],
               by = "pc11_state_id", all.x = TRUE)

# Drop UTs and states not in FC formula (Telangana handled via AP combination)
panel <- panel[!is.na(windfall_pc)]

# Create treatment variables
panel[, post := as.integer(year >= 2015)]
panel[, district_id := paste0(pc11_state_id, "_", pc11_district_id)]
panel[, log_light := log(total_light + 1)]
panel[, log_mean_light := log(mean_light + 0.01)]

# Create event-time indicators
panel[, event_time := year - 2015]

cat(sprintf("\nFinal panel: %d district-year obs, %d districts, %d states\n",
            nrow(panel), uniqueN(panel$district_id), uniqueN(panel$pc11_state_id)))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))

# ── 6. Save ───────────────────────────────────────────────────────
fwrite(panel, "data/district_panel.csv")
fwrite(fc14_shares, "data/fc14_state_shares.csv")
cat("Panel saved to data/district_panel.csv\n")
