## 02_clean_data.R — Construct analysis dataset with signed distance to ZFE
## apep_0680: ZFE Spatial RDD on Property Values

source("code/00_packages.R")

cat("=== Building analysis dataset ===\n\n")

# ---- 1. Load and combine DVF data ----
dvf_years <- 2020:2024  # geo-dvf bulk CSVs available from 2020
dvf_list <- list()

for (yr in dvf_years) {
  f <- sprintf("data/dvf_%d.csv.gz", yr)
  cat(sprintf("Reading DVF %d...\n", yr))
  dt <- fread(f, select = c(
    "date_mutation", "nature_mutation", "valeur_fonciere",
    "type_local", "surface_reelle_bati", "nombre_pieces_principales",
    "longitude", "latitude", "code_commune", "id_parcelle"
  ))
  dt[, year := yr]
  dvf_list[[as.character(yr)]] <- dt
}

dvf <- rbindlist(dvf_list, fill = TRUE)
cat(sprintf("Raw DVF: %s transactions across %d years\n",
            format(nrow(dvf), big.mark = ","), length(dvf_years)))

# ---- 2. Filter to residential sales ----
dvf <- dvf[
  nature_mutation == "Vente" &
  type_local %in% c("Appartement", "Maison") &
  !is.na(valeur_fonciere) &
  valeur_fonciere > 10000 &
  !is.na(surface_reelle_bati) &
  surface_reelle_bati >= 9 &
  surface_reelle_bati <= 500 &
  !is.na(longitude) &
  !is.na(latitude)
]

# Remove extreme prices (likely commercial or data errors)
dvf[, price_m2 := valeur_fonciere / surface_reelle_bati]
dvf <- dvf[price_m2 >= 500 & price_m2 <= 15000]

cat(sprintf("After filtering: %s residential sales\n",
            format(nrow(dvf), big.mark = ",")))

# ---- 3. Parse dates ----
dvf[, date := as.Date(date_mutation)]
dvf[, year_quarter := paste0(year(date), "-Q", quarter(date))]
dvf[, month := floor_date(date, "month")]

# ---- 4. Load ZFE boundary and compute signed distance ----
cat("Loading ZFE boundary...\n")
zfe <- st_read("data/zfe_lyon.geojson", quiet = TRUE)

# Ensure CRS is WGS84, then project to metric CRS for distance computation
zfe <- st_transform(zfe, 2154)  # RGF93 / Lambert-93 (France metric)
zfe_boundary <- st_boundary(st_union(zfe))

# Convert DVF to spatial
dvf_sf <- st_as_sf(dvf, coords = c("longitude", "latitude"), crs = 4326)
dvf_sf <- st_transform(dvf_sf, 2154)

# Compute distance to ZFE boundary (meters)
cat("Computing distance to ZFE boundary (this may take a moment)...\n")
dist_to_boundary <- as.numeric(st_distance(dvf_sf, zfe_boundary))

# Determine inside/outside
zfe_polygon <- st_union(zfe)
inside <- as.logical(st_intersects(dvf_sf, zfe_polygon, sparse = FALSE))

# Signed distance: positive = inside ZFE, negative = outside
dvf[, dist_m := dist_to_boundary]
dvf[, inside_zfe := inside]
dvf[, signed_dist := ifelse(inside_zfe, dist_m, -dist_m)]
dvf[, signed_dist_km := signed_dist / 1000]

cat(sprintf("Inside ZFE: %s | Outside: %s\n",
            format(sum(dvf$inside_zfe), big.mark = ","),
            format(sum(!dvf$inside_zfe), big.mark = ",")))

# ---- 5. Define treatment periods ----
# Pre-ZFE: before September 2022 (private vehicle ban)
# Post-ZFE Phase 1: September 2022 - December 2023 (Crit'Air 5 banned)
# Post-ZFE Phase 2: January 2024+ (Crit'Air 3 banned)
dvf[, period := fcase(
  date < as.Date("2022-09-01"), "pre",
  date >= as.Date("2022-09-01") & date < as.Date("2024-01-01"), "post_phase1",
  date >= as.Date("2024-01-01"), "post_phase2"
)]

# Binary post indicator
dvf[, post := as.integer(date >= as.Date("2022-09-01"))]

# ---- 6. Create analysis variables ----
dvf[, log_price_m2 := log(price_m2)]
dvf[, is_apartment := as.integer(type_local == "Appartement")]
dvf[, rooms := pmin(nombre_pieces_principales, 10)]  # cap at 10

# ---- 7. Restrict to analysis bandwidth ----
# Keep all data but flag analysis sample (within 2km for maximum bandwidth)
dvf[, in_sample_2km := abs(signed_dist) <= 2000]
dvf[, in_sample_1km := abs(signed_dist) <= 1000]

cat(sprintf("\nWithin 2km bandwidth: %s transactions\n",
            format(sum(dvf$in_sample_2km), big.mark = ",")))
cat(sprintf("Within 1km bandwidth: %s transactions\n",
            format(sum(dvf$in_sample_1km), big.mark = ",")))

# ---- 8. Save analysis dataset ----
saveRDS(dvf, "data/analysis_data.rds")
cat(sprintf("\nSaved analysis_data.rds: %s observations, %d variables\n",
            format(nrow(dvf), big.mark = ","), ncol(dvf)))

# ---- 9. Summary statistics ----
cat("\n=== Summary Statistics (1km bandwidth, all years) ===\n")
sample_1km <- dvf[in_sample_1km == TRUE]
cat(sprintf("N transactions: %s\n", format(nrow(sample_1km), big.mark = ",")))
cat(sprintf("Inside ZFE: %s | Outside: %s\n",
            format(sum(sample_1km$inside_zfe), big.mark = ","),
            format(sum(!sample_1km$inside_zfe), big.mark = ",")))
cat(sprintf("Median price/m²: €%s\n", format(median(sample_1km$price_m2), big.mark = ",")))
cat(sprintf("SD price/m²: €%s\n", format(round(sd(sample_1km$price_m2)), big.mark = ",")))
cat(sprintf("Pre-ZFE: %s | Post Phase 1: %s | Post Phase 2: %s\n",
            format(sum(sample_1km$period == "pre"), big.mark = ","),
            format(sum(sample_1km$period == "post_phase1"), big.mark = ","),
            format(sum(sample_1km$period == "post_phase2"), big.mark = ",")))
