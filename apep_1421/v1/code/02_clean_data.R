## ── 02_clean_data.R ────────────────────────────────────────────
## Construct district-year panel with treatment intensity
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

out_dir <- "../data"

# Use VIIRS-only panel (2012-2021) — clean sensor, no calibration artifacts
viirs <- readRDS(file.path(out_dir, "viirs_raw.rds"))
ec13  <- readRDS(file.path(out_dir, "ec13_raw.rds"))
pca   <- readRDS(file.path(out_dir, "pca_raw.rds"))
td    <- readRDS(file.path(out_dir, "td_raw.rds"))

## ── Clean IDs (remove quotes if present) ───────────────────────
clean_id <- function(x) as.integer(gsub('"', '', x))

viirs[, pc11_state_id := clean_id(pc11_state_id)]
viirs[, pc11_district_id := clean_id(pc11_district_id)]
ec13[, pc11_state_id := clean_id(pc11_state_id)]
ec13[, pc11_district_id := clean_id(pc11_district_id)]
pca[, pc11_state_id := clean_id(pc11_state_id)]
pca[, pc11_district_id := clean_id(pc11_district_id)]
td[, pc11_state_id := clean_id(pc11_state_id)]
td[, pc11_district_id := clean_id(pc11_district_id)]

## ── Create unique district ID ──────────────────────────────────
viirs[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]
ec13[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]
pca[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]
td[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]

## ── Treatment intensity: mining employment share ───────────────
# ec13_emp_pub_mines = employment in public mining sector
# ec13_emp_all = total employment
ec13[, mining_emp := as.numeric(ec13_emp_pub_mines)]
ec13[, total_emp := as.numeric(ec13_emp_all)]
ec13[is.na(mining_emp), mining_emp := 0]
ec13[, mining_share := mining_emp / total_emp]
ec13[is.na(mining_share) | is.infinite(mining_share), mining_share := 0]
ec13[, is_mining := as.integer(mining_emp > 0)]

cat("Mining districts (any mining emp):", sum(ec13$is_mining), "of", nrow(ec13), "\n")
cat("Mining employment distribution:\n")
print(summary(ec13[is_mining == 1]$mining_emp))

## ── Merge VIIRS panel with treatment ───────────────────────────
# Create the panel: district × year
panel <- merge(viirs[, .(dist_id, year, viirs_annual_mean, viirs_annual_sum, viirs_annual_num_cells)],
               ec13[, .(dist_id, mining_emp, mining_share, is_mining, total_emp)],
               by = "dist_id", all.x = TRUE)

# Fill non-matched districts as non-mining
panel[is.na(is_mining), `:=`(mining_emp = 0, mining_share = 0, is_mining = 0, total_emp = 0)]

## ── Add Census controls ────────────────────────────────────────
pca_vars <- pca[, .(dist_id,
                     pop = as.numeric(pc11_pca_tot_p),
                     lit_rate = as.numeric(pc11_pca_p_lit) / as.numeric(pc11_pca_tot_p),
                     sc_share = as.numeric(pc11_pca_p_sc) / as.numeric(pc11_pca_tot_p),
                     st_share = as.numeric(pc11_pca_p_st) / as.numeric(pc11_pca_tot_p),
                     work_rate = as.numeric(pc11_pca_tot_work_p) / as.numeric(pc11_pca_tot_p))]

panel <- merge(panel, pca_vars, by = "dist_id", all.x = TRUE)

## ── Treatment variables ────────────────────────────────────────
panel[, post := as.integer(year >= 2015)]
panel[, log_light := log(viirs_annual_mean + 0.01)]

# Continuous treatment: mining_emp × post
panel[, treat_cont := mining_emp * post]

# Mining share × post
panel[, treat_share := mining_share * post]

# Binary treatment: is_mining × post
panel[, treat_binary := is_mining * post]

# Log mining employment (for dose-response)
panel[, log_mining := log(mining_emp + 1)]
panel[, treat_log := log_mining * post]

## ── State ID for clustering ────────────────────────────────────
panel[, state_id := as.integer(sub("_.*", "", dist_id))]

## ── Summary statistics ─────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat("Total obs:", nrow(panel), "\n")
cat("Districts:", uniqueN(panel$dist_id), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Mining districts:", uniqueN(panel[is_mining == 1]$dist_id), "\n")
cat("Non-mining districts:", uniqueN(panel[is_mining == 0]$dist_id), "\n")
cat("Pre-treatment years:", sum(sort(unique(panel$year)) < 2015), "\n")
cat("Post-treatment years:", sum(sort(unique(panel$year)) >= 2015), "\n")

cat("\nNightlights by mining status:\n")
print(panel[, .(mean_light = mean(viirs_annual_mean, na.rm = TRUE),
                sd_light = sd(viirs_annual_mean, na.rm = TRUE),
                n = .N), by = .(is_mining, post)])

## ── Save panel ─────────────────────────────────────────────────
saveRDS(panel, file.path(out_dir, "panel.rds"))
cat("\nPanel saved to data/panel.rds\n")
