## ── 01b_extend_panel.R ─────────────────────────────────────────
## Extend panel with DMSP nightlights (2008-2013) for more pre-periods
## DMSP and VIIRS overlap in 2012-2013, allowing calibration
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

shrug_dir <- "../../../../data/india_shrug"
out_dir <- "../data"

## ── Load DMSP data ─────────────────────────────────────────────
dmsp <- fread(file.path(shrug_dir, "dmsp_pc11dist.tab"))
cat("DMSP rows:", nrow(dmsp), "| Years:", paste(sort(unique(dmsp$year)), collapse = ","), "\n")

## ── Clean IDs ──────────────────────────────────────────────────
dmsp[, pc11_state_id := as.integer(pc11_state_id)]
dmsp[, pc11_district_id := as.integer(pc11_district_id)]
dmsp[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]

## ── Calibrate DMSP to VIIRS scale ─────────────────────────────
# Use 2012-2013 overlap to estimate linear mapping: VIIRS_mean ~ a + b * DMSP_mean
viirs <- readRDS(file.path(out_dir, "viirs_raw.rds"))
viirs[, pc11_state_id := as.integer(gsub('"', '', pc11_state_id))]
viirs[, pc11_district_id := as.integer(gsub('"', '', pc11_district_id))]
viirs[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]

# Overlap years
overlap <- merge(
  viirs[year %in% 2012:2013, .(dist_id, year, viirs_mean = viirs_annual_mean)],
  dmsp[year %in% 2012:2013, .(dist_id, year, dmsp_mean = dmsp_mean_light_cal)],
  by = c("dist_id", "year")
)
cat("Overlap obs:", nrow(overlap), "\n")

cal <- lm(viirs_mean ~ dmsp_mean, data = overlap)
cat("Calibration: VIIRS = ", round(coef(cal)[1], 4), " + ", round(coef(cal)[2], 4), " * DMSP\n")
cat("R-squared:", round(summary(cal)$r.squared, 3), "\n")

## ── Create extended panel (2008-2021) ──────────────────────────
# DMSP years: 2008-2013 (6 pre-treatment years + overlap)
dmsp_ext <- dmsp[year >= 2008 & year <= 2011]  # Only pre-VIIRS years
dmsp_ext[, viirs_annual_mean := predict(cal, newdata = data.frame(dmsp_mean = dmsp_mean_light_cal))]
dmsp_ext[, viirs_annual_sum := viirs_annual_mean * dmsp_num_cells]  # Approximate
dmsp_ext[, viirs_annual_num_cells := dmsp_num_cells]
dmsp_ext <- dmsp_ext[, .(dist_id, year, viirs_annual_mean, viirs_annual_sum, viirs_annual_num_cells)]

# VIIRS years: 2012-2021
viirs_panel <- viirs[category == "median-masked", .(dist_id, year, viirs_annual_mean, viirs_annual_sum, viirs_annual_num_cells)]

# Combine
extended <- rbind(dmsp_ext, viirs_panel)
extended <- extended[order(dist_id, year)]

cat("\nExtended panel:\n")
cat("Years:", paste(sort(unique(extended$year)), collapse = ", "), "\n")
cat("Districts:", uniqueN(extended$dist_id), "\n")
cat("Pre-treatment years (< 2015):", sum(sort(unique(extended$year)) < 2015), "\n")
cat("Total obs:", nrow(extended), "\n")

## ── Save extended VIIRS ────────────────────────────────────────
saveRDS(extended, file.path(out_dir, "viirs_extended.rds"))
cat("Extended panel saved.\n")
