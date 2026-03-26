# 02_clean_data.R — Clean and construct analysis panel
# APEP Working Paper apep_0992

source("code/00_packages.R")

raw <- readRDS("data/magyp_raw.rds")

cat("Raw data dimensions:", nrow(raw), "x", ncol(raw), "\n")

# --- Extract campaign start year ---
raw[, campaign_year := as.integer(sub("/.*", "", campania))]

# --- Identify focal crops using exact matching on actual data values ---
# Use "total" variants where they exist to avoid double-counting subtypes
crop_names <- unique(raw$cultivo)
cat("Crop names containing target strings:\n")
cat("Soja:", grep("soja", crop_names, value = TRUE), "\n")
cat("Trigo:", grep("trigo", crop_names, value = TRUE), "\n")
cat("Girasol:", grep("girasol", crop_names, value = TRUE), "\n")
cat("Maiz:", grep("ma", crop_names, value = TRUE), "\n")

# Use totals where available; for girasol and maíz, use direct match
raw[, crop := fcase(
  cultivo == "soja total", "Soybean",
  cultivo == "trigo total", "Wheat",
  cultivo == "girasol", "Sunflower",
  grepl("^ma.*z$", cultivo), "Corn",  # matches maíz with any encoding
  default = NA_character_
)]

focal <- raw[!is.na(crop)]
cat("\nFocal crop observations:\n")
print(focal[, .N, by = .(crop, cultivo)])

# --- Sample window: 2010/11 to 2019/20 ---
focal <- focal[campaign_year >= 2010 & campaign_year <= 2019]
cat("\nSample window (2010-2019):", nrow(focal), "observations\n")

# --- Drop zero/missing planted area ---
focal <- focal[superficie_sembrada_ha > 0]
cat("After dropping zeros:", nrow(focal), "observations\n")

# --- Rename for convenience ---
panel <- focal[, .(
  dept_id = departamento_id,
  dept_name = departamento,
  province = provincia,
  province_id = provincia_id,
  crop, campaign_year,
  planted_area = superficie_sembrada_ha,
  harvested_area = superficie_cosechada_ha,
  production = produccion_tm,
  yield = rendimiento_kgxha
)]

# --- Treatment indicators ---
panel[, treated_crop := as.integer(crop != "Soybean")]
panel[, post := as.integer(campaign_year >= 2015)]
panel[, treat_post := treated_crop * post]

# --- Log outcomes ---
panel[, log_planted := log(planted_area)]
panel[, log_production := log(production + 1)]

# --- Create FE identifiers ---
panel[, dept_crop := paste(dept_id, crop, sep = "_")]
panel[, dept_year := paste(dept_id, campaign_year, sep = "_")]
panel[, crop_year := paste(crop, campaign_year, sep = "_")]

# --- Balance check ---
# Require departments that grow at least 2 crops (soybean + at least 1 treated crop)
# with observations in both pre and post periods
dept_balance <- panel[, .(
  n_crops = uniqueN(crop),
  has_soy = any(crop == "Soybean"),
  has_treated = any(crop != "Soybean"),
  n_pre = sum(campaign_year < 2015),
  n_post = sum(campaign_year >= 2015)
), by = dept_id]

# Keep departments with all 4 crops OR at least 3 (soybean + 2 treated)
# that have observations in both periods
balanced_depts <- dept_balance[n_crops >= 3 & has_soy & has_treated & n_pre >= 3 & n_post >= 3, dept_id]
cat("\nDepartments with >=3 crops and adequate pre/post:", length(balanced_depts), "\n")

# Try with all 4 crops
balanced_depts_4 <- dept_balance[n_crops == 4 & n_pre >= 4 & n_post >= 4, dept_id]
cat("Departments with all 4 crops and >=4 obs each period:", length(balanced_depts_4), "\n")

# Use the 4-crop balanced panel if large enough, else 3-crop
if (length(balanced_depts_4) >= 100) {
  panel_bal <- panel[dept_id %in% balanced_depts_4]
  cat("Using 4-crop balanced panel\n")
} else {
  panel_bal <- panel[dept_id %in% balanced_depts]
  cat("Using 3+-crop balanced panel\n")
}

cat("Balanced panel:", nrow(panel_bal), "observations\n")
cat("Departments:", uniqueN(panel_bal$dept_id), "\n")
cat("Crops:", uniqueN(panel_bal$crop), "\n")
cat("Campaigns:", paste(sort(unique(panel_bal$campaign_year)), collapse = ", "), "\n")

# --- Summary by crop and period ---
cat("\n=== Treatment Variation ===\n")
crop_summary <- panel_bal[, .(
  mean_area = round(mean(planted_area)),
  sd_area = round(sd(planted_area)),
  median_area = round(median(planted_area)),
  n_obs = .N,
  n_depts = uniqueN(dept_id)
), by = .(crop, period = ifelse(post == 1, "Post", "Pre"))]
print(crop_summary[order(crop, period)])

# --- Pre vs post mean change by crop ---
cat("\n=== Mean Planted Area Change ===\n")
pre_post <- panel_bal[, .(mean_area = mean(planted_area)), by = .(crop, post)]
pre_post_wide <- dcast(pre_post, crop ~ post, value.var = "mean_area")
setnames(pre_post_wide, c("crop", "pre_mean", "post_mean"))
pre_post_wide[, pct_change := round(100 * (post_mean - pre_mean) / pre_mean, 1)]
print(pre_post_wide)

# --- Compute area shares within department-year ---
dept_year_totals <- panel_bal[, .(total_area = sum(planted_area)), by = .(dept_id, campaign_year)]
panel_bal <- merge(panel_bal, dept_year_totals, by = c("dept_id", "campaign_year"))
panel_bal[, area_share := planted_area / total_area]

# --- Initial soybean concentration for heterogeneity ---
pre_soy_share <- panel_bal[crop == "Soybean" & campaign_year < 2015,
  .(pre_soy_share = mean(area_share)), by = dept_id]
panel_bal <- merge(panel_bal, pre_soy_share, by = "dept_id", all.x = TRUE)
panel_bal[, high_soy := as.integer(pre_soy_share > median(pre_soy_share, na.rm = TRUE))]

# --- Save ---
saveRDS(panel_bal, "data/analysis_panel.rds")
cat("\nSaved analysis panel:", nrow(panel_bal), "observations\n")
