# 03b_distance_analysis.R — Distance-based treatment intensity (inverse distance to Chemours)

library(tidyverse)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

# ============================================================
# 0. Load data
# ============================================================
panel <- readRDS("data/panel.rds")
meta  <- readRDS("data/gm_metadata_final.rds")

# Normalize Fryslân → Friesland (consistent with 03_main_analysis.R)
panel$province[panel$province == "Fryslân"] <- "Friesland"
meta$province[meta$province == "Fryslân"]   <- "Friesland"

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$region), "municipalities\n")
cat("Metadata:", nrow(meta), "municipalities\n")

# ============================================================
# 1. Assign municipality centroids
# ============================================================

# Chemours factory location (Dordrecht)
chemours_lat <- 51.79
chemours_lon <- 4.685

# Known municipality centroids (largest cities)
known_centroids <- tribble(
  ~gem_code,   ~lat,    ~lon,
  "GM0505",    51.81,   4.67,   # Dordrecht
  "GM0599",    51.92,   4.48,   # Rotterdam
  "GM0518",    52.07,   4.30,   # Den Haag
  "GM0363",    52.37,   4.89,   # Amsterdam
  "GM0344",    52.09,   5.12,   # Utrecht
  "GM0772",    51.44,   5.47,   # Eindhoven
  "GM0855",    51.56,   5.09    # Tilburg
)

# Province-level average coordinates for remaining municipalities
province_centroids <- tribble(
  ~province,         ~prov_lat,  ~prov_lon,
  "Groningen",       53.22,      6.57,
  "Friesland",       53.16,      5.78,
  "Drenthe",         52.85,      6.63,
  "Overijssel",      52.44,      6.35,
  "Flevoland",       52.53,      5.48,
  "Gelderland",      52.05,      5.87,
  "Utrecht",         52.09,      5.18,
  "Noord-Holland",   52.55,      4.85,
  "Zuid-Holland",     52.02,      4.40,
  "Zeeland",         51.49,      3.85,
  "Noord-Brabant",   51.55,      5.10,
  "Limburg",         51.20,      5.93
)

# Build centroid table: known cities first, province averages for the rest
meta_coords <- meta %>%
  select(gem_code, gem_name, province) %>%
  left_join(known_centroids, by = "gem_code") %>%
  left_join(province_centroids, by = "province") %>%
  mutate(
    lat = ifelse(!is.na(lat), lat, prov_lat),
    lon = ifelse(!is.na(lon), lon, prov_lon)
  ) %>%
  select(gem_code, gem_name, province, lat, lon)

# Report coverage
n_known   <- sum(meta_coords$gem_code %in% known_centroids$gem_code)
n_prov    <- sum(!is.na(meta_coords$lat) & !meta_coords$gem_code %in% known_centroids$gem_code)
n_missing <- sum(is.na(meta_coords$lat))
cat("\nCoordinate assignment:\n")
cat("  Known centroids:", n_known, "\n")
cat("  Province-average:", n_prov, "\n")
cat("  Missing (no province):", n_missing, "\n")

# ============================================================
# 2. Compute Haversine distance to Chemours
# ============================================================
haversine_km <- function(lat1, lon1, lat2, lon2) {
  # Haversine formula for great-circle distance
  R <- 6371  # Earth's radius in km
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat / 2)^2 +
    cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dlon / 2)^2
  2 * R * asin(sqrt(a))
}

meta_coords <- meta_coords %>%
  filter(!is.na(lat)) %>%
  mutate(
    distance_km = haversine_km(lat, lon, chemours_lat, chemours_lon),
    inv_dist    = 1 / distance_km,
    # Distance bins
    dist_bin = case_when(
      distance_km <= 30  ~ "0-30km",
      distance_km <= 60  ~ "30-60km",
      distance_km <= 100 ~ "60-100km",
      TRUE               ~ "100+km"
    ),
    dist_bin = factor(dist_bin, levels = c("100+km", "0-30km", "30-60km", "60-100km"))
  )

cat("\n--- Distance summary ---\n")
cat("Distance range:", round(range(meta_coords$distance_km), 1), "km\n")
cat("Distance distribution:\n")
print(table(meta_coords$dist_bin))
cat("\nClosest 10 municipalities:\n")
print(
  meta_coords %>%
    arrange(distance_km) %>%
    head(10) %>%
    select(gem_code, gem_name, province, distance_km, inv_dist) %>%
    mutate(distance_km = round(distance_km, 1), inv_dist = round(inv_dist, 4))
)

# ============================================================
# 3. Merge distance measures into panel
# ============================================================
panel_dist <- panel %>%
  left_join(
    meta_coords %>% select(gem_code, distance_km, inv_dist, dist_bin),
    by = c("region" = "gem_code")
  ) %>%
  filter(!is.na(distance_km)) %>%  # drop any unmatched
  mutate(
    # Ensure post indicators are numeric for proper continuous interaction
    post_freeze_num = as.numeric(post_freeze),
    post_relax_num  = as.numeric(post_relax)
  )

cat("\nPanel after distance merge:", nrow(panel_dist), "obs,",
    n_distinct(panel_dist$region), "municipalities\n")

# ============================================================
# 4. Specification A: Continuous DiD (inverse distance)
# ============================================================
cat("\n=== SPEC A: CONTINUOUS DiD (inv_dist x post_freeze) ===\n")

m_cont <- feols(
  new_construction ~ inv_dist:post_freeze_num | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)
cat("\n--- Continuous treatment (inv_dist x post_freeze) ---\n")
summary(m_cont)

# Also with post_relax
m_cont2 <- feols(
  new_construction ~ inv_dist:post_freeze_num + inv_dist:post_relax_num | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)
cat("\n--- Continuous treatment (freeze + relax periods) ---\n")
summary(m_cont2)

# Log outcome version
m_cont_log <- feols(
  log_new ~ inv_dist:post_freeze_num | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)
cat("\n--- Continuous treatment, log outcome ---\n")
summary(m_cont_log)

# ============================================================
# 5. Specification B: Distance bins x post_freeze
# ============================================================
cat("\n=== SPEC B: DISTANCE BIN DiD ===\n")

m_bin <- feols(
  new_construction ~ i(dist_bin, post_freeze, ref = "100+km") | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)
cat("\n--- Distance bin treatment effects (ref = 100+km) ---\n")
summary(m_bin)

# Distance bins with freeze + relax
m_bin2 <- feols(
  new_construction ~ i(dist_bin, post_freeze, ref = "100+km") +
    i(dist_bin, post_relax, ref = "100+km") | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)
cat("\n--- Distance bins (freeze + relax) ---\n")
summary(m_bin2)

# ============================================================
# 6. Distance bin summary statistics
# ============================================================
cat("\n=== DISTANCE BIN SUMMARY ===\n")
bin_summary <- panel_dist %>%
  filter(date < as.Date("2019-07-01")) %>%
  group_by(dist_bin) %>%
  summarise(
    n_muni         = n_distinct(region),
    mean_new       = round(mean(new_construction, na.rm = TRUE), 1),
    sd_new         = round(sd(new_construction, na.rm = TRUE), 1),
    pct_high_pfas  = round(100 * mean(high_pfas), 1),
    mean_dist_km   = round(mean(distance_km), 1),
    .groups = "drop"
  )
print(bin_summary)

# ============================================================
# 7. Joint F-test for pre-trend coefficients (event study)
# ============================================================
cat("\n=== JOINT F-TEST FOR PRE-TRENDS ===\n")

# Re-estimate event study (same as 03_main_analysis.R)
panel_dist <- panel_dist %>%
  mutate(
    et_bin = case_when(
      event_time <= -24 ~ -24L,
      event_time >= 48  ~ 48L,
      TRUE              ~ event_time
    ),
    et_factor = factor(et_bin)
  )

es <- feols(
  new_construction ~ i(et_factor, high_pfas, ref = -1) | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)

# Extract pre-trend coefficients (event_time < -1)
es_coefs <- coeftable(es) %>%
  as.data.frame() %>%
  tibble::rownames_to_column("term") %>%
  filter(grepl("et_factor", term)) %>%
  mutate(
    event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))
  )

pre_terms <- es_coefs %>%
  filter(event_time < -1) %>%
  pull(term)

cat("Number of pre-trend coefficients:", length(pre_terms), "\n")

# Wald test: joint significance of pre-trend coefficients
if (length(pre_terms) > 1) {
  # Use fixest::wald to test joint significance
  pre_test <- wald(es, keep = pre_terms)
  cat("\n--- Wald test (joint significance of pre-trend coefficients) ---\n")
  print(pre_test)

  f_stat <- pre_test$stat
  f_pval <- pre_test$p
  f_df1  <- pre_test$df1
  f_df2  <- pre_test$df2
  cat("\nF-statistic:", round(f_stat, 3), "\n")
  cat("p-value:", round(f_pval, 4), "\n")
  cat("df:", f_df1, ",", f_df2, "\n")
} else {
  cat("Too few pre-trend coefficients for joint test.\n")
  f_stat <- NA
  f_pval <- NA
  f_df1  <- NA
  f_df2  <- NA
}

# ============================================================
# 8. Distance-based event study (continuous)
# ============================================================
cat("\n=== DISTANCE-BASED EVENT STUDY ===\n")

es_dist <- feols(
  new_construction ~ i(et_factor, inv_dist, ref = -1) | region + ym_factor,
  data = panel_dist,
  cluster = "region"
)

es_dist_coefs <- coeftable(es_dist) %>%
  as.data.frame() %>%
  tibble::rownames_to_column("term") %>%
  filter(grepl("et_factor", term)) %>%
  mutate(
    event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))
  ) %>%
  arrange(event_time)

cat("\n--- Distance-based event study (inv_dist) ---\n")
cat("Pre-period coefficients (should be ~0):\n")
print(
  es_dist_coefs %>%
    filter(event_time < -1) %>%
    select(event_time, Estimate, `Std. Error`, `Pr(>|t|)`) %>%
    mutate(across(where(is.numeric), ~round(., 4)))
)

# ============================================================
# 9. Save all results
# ============================================================
distance_results <- list(
  # Continuous DiD
  m_cont       = m_cont,
  m_cont2      = m_cont2,
  m_cont_log   = m_cont_log,
  # Distance bin DiD
  m_bin        = m_bin,
  m_bin2       = m_bin2,
  # Distance event study
  es_dist      = es_dist,
  es_dist_coefs = es_dist_coefs,
  # Pre-trend F-test
  f_test = list(
    f_stat = f_stat,
    f_pval = f_pval,
    f_df1  = f_df1,
    f_df2  = f_df2,
    n_pre_coefs = length(pre_terms)
  ),
  # Metadata
  meta_coords   = meta_coords,
  bin_summary   = bin_summary
)

saveRDS(distance_results, "data/distance_results.rds")
cat("\n=== Results saved to data/distance_results.rds ===\n")

# ============================================================
# 10. Print summary
# ============================================================
cat("\n")
cat("====================================================\n")
cat("           DISTANCE ANALYSIS SUMMARY\n")
cat("====================================================\n\n")

cat("Continuous DiD (inv_dist x post_freeze):\n")
cat("  Coefficient:", round(coef(m_cont)[[1]], 3), "\n")
cat("  Std. Error: ", round(se(m_cont)[[1]], 3), "\n")
cat("  p-value:    ", round(pvalue(m_cont)[[1]], 4), "\n\n")

cat("Distance bin effects (ref = 100+km):\n")
bin_coefs <- coeftable(m_bin) %>% as.data.frame()
for (i in seq_len(nrow(bin_coefs))) {
  cat("  ", rownames(bin_coefs)[i], ":",
      round(bin_coefs$Estimate[i], 3), "  (SE:", round(bin_coefs$`Std. Error`[i], 3),
      ", p:", round(bin_coefs$`Pr(>|t|)`[i], 4), ")\n")
}

cat("\nPre-trend F-test:\n")
cat("  F-stat:", round(f_stat, 3), ", p-value:", round(f_pval, 4), "\n")
cat("  Interpretation:",
    ifelse(!is.na(f_pval) && f_pval > 0.10,
           "Cannot reject null of parallel pre-trends (good)",
           "Pre-trends may be non-parallel (caution)"), "\n")
