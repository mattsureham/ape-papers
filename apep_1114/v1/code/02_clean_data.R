## 02_clean_data.R — Construct analysis panel for apep_1114
## Municipality-year panel with Natura 2000 exposure treatment

source("00_packages.R")

cat("=== Constructing analysis panel ===\n\n")

# ---------------------------------------------------------------
# 1. Clean agriculture data
# ---------------------------------------------------------------
cat("1. Cleaning agriculture data...\n")

agri <- readRDS("../data/cbs_80781ned_raw.rds")

# Extract year from period code (e.g., "2000JJ00" -> 2000)
agri$year <- as.integer(substr(agri$Perioden, 1, 4))

# Clean municipality code (trim whitespace)
agri$muni_code <- trimws(agri$RegioS)

# Select key variables and rename
agri_panel <- agri |>
  select(
    muni_code,
    year,
    n_farms      = AantalLandbouwbedrijvenTotaal_1,
    cattle       = RundveeTotaal_84,
    pigs         = VarkensTotaal_121,
    chickens     = KippenTotaal_125,
    agri_land_ha = Cultuurgrond_3,
    grazing_total = GraasdierenTotaal_102,
    housed_total  = HokdierenTotaal_135
  ) |>
  # Filter to municipality-level observations (exclude provinces, national)
  # CBS municipality codes: GM followed by 4 digits
  filter(grepl("^GM", muni_code)) |>
  mutate(across(c(n_farms, cattle, pigs, chickens, agri_land_ha,
                  grazing_total, housed_total), as.numeric))

cat("  Agriculture panel rows:", nrow(agri_panel), "\n")
cat("  Municipalities:", n_distinct(agri_panel$muni_code), "\n")
cat("  Years:", min(agri_panel$year), "-", max(agri_panel$year), "\n")

# Compute livestock units (LU) using standard EU coefficients
# Cattle = 1.0 LU, Pig = 0.3 LU, Chicken = 0.014 LU
agri_panel <- agri_panel |>
  mutate(
    livestock_units = cattle * 1.0 + pigs * 0.3 + chickens * 0.014,
    livestock_per_farm = ifelse(n_farms > 0, livestock_units / n_farms, NA_real_),
    cattle_per_farm = ifelse(n_farms > 0, cattle / n_farms, NA_real_),
    pigs_per_farm = ifelse(n_farms > 0, pigs / n_farms, NA_real_),
    log_farms = ifelse(n_farms > 0, log(n_farms), NA_real_),
    log_livestock = ifelse(livestock_units > 0, log(livestock_units), NA_real_)
  )

# ---------------------------------------------------------------
# 2. Compute Natura 2000 exposure by municipality
# ---------------------------------------------------------------
cat("\n2. Computing Natura 2000 spatial exposure...\n")

n2k <- readRDS("../data/natura2000_sf.rds")
muni <- readRDS("../data/municipality_boundaries_sf.rds")

# Ensure same CRS (Amersfoort / RD New — EPSG:28992)
if (st_crs(n2k)$epsg != st_crs(muni)$epsg) {
  muni <- st_transform(muni, st_crs(n2k))
}

# Buffer Natura 2000 sites by 5km (nitrogen deposition radius)
cat("  Buffering Natura 2000 sites by 5km...\n")
n2k_buffer <- st_buffer(n2k, dist = 5000)
n2k_union <- st_union(n2k_buffer)

# Compute municipality area
muni$muni_area_m2 <- as.numeric(st_area(muni))

# Compute intersection area between each municipality and N2K buffer
cat("  Computing intersection areas...\n")
muni_intersect <- st_intersection(muni, n2k_union)
muni_intersect$intersect_area_m2 <- as.numeric(st_area(muni_intersect))

# Get the municipality code column (varies across CBS WFS versions)
muni_code_col <- grep("^(statcode|gemeentecode|code)", names(muni),
                       value = TRUE, ignore.case = TRUE)[1]
if (is.na(muni_code_col)) {
  # Try to find any column with "GM" codes
  for (col in names(muni)) {
    if (is.character(muni[[col]]) && any(grepl("^GM", muni[[col]]))) {
      muni_code_col <- col
      break
    }
  }
}
stopifnot("Cannot identify municipality code column" = !is.na(muni_code_col))
cat("  Municipality code column:", muni_code_col, "\n")

# Build exposure data frame
exposure_df <- tibble(
  muni_code = muni[[muni_code_col]],
  muni_area_m2 = muni$muni_area_m2
) |>
  left_join(
    tibble(
      muni_code = muni_intersect[[muni_code_col]],
      n2k_area_m2 = muni_intersect$intersect_area_m2
    ),
    by = "muni_code"
  ) |>
  mutate(
    n2k_area_m2 = replace_na(n2k_area_m2, 0),
    n2k_share = n2k_area_m2 / muni_area_m2
  )

cat("  Municipalities with N2K exposure > 0:", sum(exposure_df$n2k_share > 0), "\n")
cat("  Mean N2K share:", round(mean(exposure_df$n2k_share), 3), "\n")
cat("  Max N2K share:", round(max(exposure_df$n2k_share), 3), "\n")

# ---------------------------------------------------------------
# 3. Construct treatment intensity
# ---------------------------------------------------------------
cat("\n3. Constructing treatment intensity...\n")

# Pre-treatment livestock density (average 2015-2018, before nitrogen ruling)
pre_livestock <- agri_panel |>
  filter(year >= 2015 & year <= 2018) |>
  group_by(muni_code) |>
  summarise(
    pre_livestock_units = mean(livestock_units, na.rm = TRUE),
    pre_farms = mean(n_farms, na.rm = TRUE),
    pre_livestock_per_farm = mean(livestock_per_farm, na.rm = TRUE),
    .groups = "drop"
  )

# Merge exposure and pre-treatment intensity
treatment <- exposure_df |>
  left_join(pre_livestock, by = "muni_code") |>
  mutate(
    # Treatment intensity = N2K proximity × livestock density
    exposure = n2k_share * pre_livestock_units / 1000,
    # Binary treatment (above median among agricultural municipalities)
    high_exposure = exposure > median(exposure[pre_farms > 10], na.rm = TRUE)
  )

cat("  High-exposure municipalities:", sum(treatment$high_exposure, na.rm = TRUE), "\n")
cat("  Exposure range:", round(min(treatment$exposure, na.rm = TRUE), 2),
    "to", round(max(treatment$exposure, na.rm = TRUE), 2), "\n")

# ---------------------------------------------------------------
# 4. Build final panel
# ---------------------------------------------------------------
cat("\n4. Building analysis panel...\n")

panel <- agri_panel |>
  inner_join(
    treatment |> select(muni_code, n2k_share, exposure, high_exposure,
                         pre_livestock_units, pre_farms, pre_livestock_per_farm),
    by = "muni_code"
  ) |>
  mutate(
    post_2019 = as.integer(year >= 2020),  # Post nitrogen ruling
    post_2023 = as.integer(year >= 2024),  # Post buyout launch (effects from 2024)
    # Event time relative to nitrogen ruling (2019)
    event_time_nitrogen = year - 2019,
    # Event time relative to buyout (2023)
    event_time_buyout = year - 2023
  )

# Drop municipalities with no farms in any year
panel <- panel |>
  group_by(muni_code) |>
  filter(any(n_farms > 0, na.rm = TRUE)) |>
  ungroup()

cat("  Final panel:", nrow(panel), "observations\n")
cat("  Municipalities:", n_distinct(panel$muni_code), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")
cat("  Post-2019 obs:", sum(panel$post_2019), "\n")
cat("  Post-2023 obs:", sum(panel$post_2023), "\n")

# ---------------------------------------------------------------
# 5. Summary statistics
# ---------------------------------------------------------------
cat("\n5. Summary statistics:\n")
panel |>
  filter(year == 2018) |>
  group_by(high_exposure) |>
  summarise(
    n_munis = n(),
    mean_farms = mean(n_farms, na.rm = TRUE),
    mean_cattle = mean(cattle, na.rm = TRUE),
    mean_pigs = mean(pigs, na.rm = TRUE),
    mean_chickens = mean(chickens, na.rm = TRUE),
    mean_lu = mean(livestock_units, na.rm = TRUE),
    mean_n2k_share = mean(n2k_share, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# Save
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(treatment, "../data/treatment_exposure.rds")

cat("\n=== Panel construction complete ===\n")
cat("Saved: data/analysis_panel.rds, data/treatment_exposure.rds\n")
