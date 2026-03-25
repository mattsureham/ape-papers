## 02_clean_data.R — apep_0931: IAP and Economic Development
## Clean and prepare analysis datasets

source("code/00_packages.R")

# ── Load processed data ─────────────────────────────────────────────
dmsp <- fread("data/dmsp_district_panel.csv")
pca01 <- fread("data/pca01_district.csv")
pca11 <- fread("data/pca11_district.csv")
td <- fread("data/td_district.csv")

cat(sprintf("DMSP panel: %d obs, %d districts, years %d-%d\n",
            nrow(dmsp), uniqueN(dmsp$pc11_district_id), min(dmsp$year), max(dmsp$year)))

# ── Construct baseline covariates from Census 2001 ──────────────────
# Population and literacy from PCA 2001
baseline <- pca01[, .(
  pc11_district_id = pc01_district_id,
  pc11_state_id = pc01_state_id,
  pop_2001 = pc01_pca_tot_p,
  lit_rate_2001 = fifelse(pc01_pca_tot_p > 0,
                          pc01_pca_p_lit / pc01_pca_tot_p, NA_real_),
  sc_share_2001 = fifelse(pc01_pca_tot_p > 0,
                          pc01_pca_p_sc / pc01_pca_tot_p, NA_real_),
  st_share_2001 = fifelse(pc01_pca_tot_p > 0,
                          pc01_pca_p_st / pc01_pca_tot_p, NA_real_),
  female_share_2001 = fifelse(pc01_pca_tot_p > 0,
                              pc01_pca_tot_f / pc01_pca_tot_p, NA_real_),
  worker_share_2001 = fifelse(pc01_pca_tot_p > 0,
                              (pc01_pca_main_al_p + pc01_pca_main_cl_p +
                               pc01_pca_main_hh_p + pc01_pca_main_ot_p) /
                              pc01_pca_tot_p, NA_real_)
)]

cat(sprintf("Baseline covariates: %d districts\n", nrow(baseline)))

# ── Merge baseline covariates ───────────────────────────────────────
# Note: Census 2001 district IDs may differ from 2011 due to bifurcations
# For district-level DiD, we merge on pc11_district_id
# (SHRUG provides harmonized IDs)
dmsp <- merge(dmsp, baseline, by = c("pc11_district_id", "pc11_state_id"), all.x = TRUE)

# ── Also prepare Census outcomes (2001 vs 2011 comparison) ──────────
# Census 2011 outcomes
outcomes_11 <- pca11[, .(
  pc11_district_id,
  pc11_state_id,
  pop_2011 = pc11_pca_tot_p,
  lit_rate_2011 = fifelse(pc11_pca_tot_p > 0,
                          pc11_pca_p_lit / pc11_pca_tot_p, NA_real_),
  sc_share_2011 = fifelse(pc11_pca_tot_p > 0,
                          pc11_pca_p_sc / pc11_pca_tot_p, NA_real_),
  st_share_2011 = fifelse(pc11_pca_tot_p > 0,
                          pc11_pca_p_st / pc11_pca_tot_p, NA_real_),
  worker_share_2011 = fifelse(pc11_pca_tot_p > 0,
                              (pc11_pca_main_al_p + pc11_pca_main_cl_p +
                               pc11_pca_main_hh_p + pc11_pca_main_ot_p) /
                              pc11_pca_tot_p, NA_real_)
)]

# Census 2001 outcomes
outcomes_01 <- pca01[, .(
  pc11_district_id = pc01_district_id,
  pc11_state_id = pc01_state_id,
  pop_2001 = pc01_pca_tot_p,
  lit_rate_2001 = fifelse(pc01_pca_tot_p > 0,
                          pc01_pca_p_lit / pc01_pca_tot_p, NA_real_),
  worker_share_2001 = fifelse(pc01_pca_tot_p > 0,
                              (pc01_pca_main_al_p + pc01_pca_main_cl_p +
                               pc01_pca_main_hh_p + pc01_pca_main_ot_p) /
                              pc01_pca_tot_p, NA_real_)
)]

# Create census long panel (2001, 2011) for cross-census DiD
census_long <- rbind(
  outcomes_01[, .(pc11_district_id, pc11_state_id, year = 2001L,
                  pop = pop_2001, lit_rate = lit_rate_2001,
                  worker_share = worker_share_2001)],
  outcomes_11[, .(pc11_district_id, pc11_state_id, year = 2011L,
                  pop = pop_2011, lit_rate = lit_rate_2011,
                  worker_share = worker_share_2011)]
)

# Load IAP indicator
iap_ids <- fread("data/iap_districts.csv")$pc11_district_id
census_long[, iap := as.integer(pc11_district_id %in% iap_ids)]
census_long[, post := as.integer(year == 2011)]
census_long[, treat_post := iap * post]
census_long[, ln_pop := log(pop + 1)]

cat(sprintf("Census long panel: %d obs (%d districts)\n",
            nrow(census_long), uniqueN(census_long$pc11_district_id)))

# ── Create within-state sample for robustness ───────────────────────
# States containing both IAP and non-IAP districts
iap_states <- unique(dmsp[iap == 1]$pc11_state_id)
dmsp[, in_iap_state := as.integer(pc11_state_id %in% iap_states)]

cat(sprintf("Districts in IAP states: %d (treated: %d, control: %d)\n",
            uniqueN(dmsp[in_iap_state == 1]$pc11_district_id),
            uniqueN(dmsp[in_iap_state == 1 & iap == 1]$pc11_district_id),
            uniqueN(dmsp[in_iap_state == 1 & iap == 0]$pc11_district_id)))

# ── Create event-time variable ──────────────────────────────────────
dmsp[, event_time := year - 2010L]  # 0 = treatment year

# ── Summary statistics ──────────────────────────────────────────────
cat("\n=== Summary Statistics (DMSP nightlights) ===\n")
cat("IAP districts (pre-treatment, 1994-2010):\n")
print(summary(dmsp[iap == 1 & year <= 2010]$dmsp_total_light_cal))
cat("\nNon-IAP districts (pre-treatment, 1994-2010):\n")
print(summary(dmsp[iap == 0 & year <= 2010]$dmsp_total_light_cal))

# ── Save ────────────────────────────────────────────────────────────
fwrite(dmsp, "data/analysis_panel.csv")
fwrite(census_long, "data/census_long_panel.csv")

cat("\nAnalysis data saved.\n")
