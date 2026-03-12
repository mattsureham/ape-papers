# 02_clean_data.R — Clean and construct analysis dataset
# APEP Working Paper apep_0607

source("00_packages.R")

# ============================================================
# 1. Clean IBGE SIDRA agricultural data
# ============================================================
cat("\n=== Cleaning IBGE SIDRA Data ===\n")

clean_sidra <- function(raw, value_name) {
  col_names <- names(raw)

  # SIDRA API column identification
  code_col <- col_names[grepl("C.d.*Munic|Codigo.*Munic", col_names, ignore.case = TRUE)]
  if (length(code_col) == 0) {
    # Sometimes it's just "Cód."
    potential <- col_names[grepl("C.d|Codigo", col_names, ignore.case = TRUE)]
    # Find the one with 7-digit values
    for (p in potential) {
      sample_vals <- head(raw[[p]], 10)
      if (all(nchar(as.character(sample_vals)) >= 6, na.rm = TRUE)) {
        code_col <- p
        break
      }
    }
  }
  year_col <- col_names[grepl("^Ano$", col_names, ignore.case = TRUE)]
  value_col <- col_names[grepl("^Valor$", col_names, ignore.case = TRUE)]

  cat("  Code col:", code_col[1], "| Year col:", year_col[1], "| Value col:", value_col[1], "\n")

  out <- tibble(
    muni_code = as.character(raw[[code_col[1]]]),
    year = as.integer(raw[[year_col[1]]]),
    value = as.numeric(gsub("[^0-9.-]", "", raw[[value_col[1]]]))
  ) %>%
    filter(!is.na(muni_code), !is.na(year), nchar(muni_code) >= 6) %>%
    rename(!!value_name := value)

  cat("  Cleaned rows:", nrow(out), "| Municipalities:", n_distinct(out$muni_code), "\n")
  return(out)
}

# Load and clean
cat("Cleaning soybean area...\n")
soy_area <- clean_sidra(readRDS("../data/raw_soy_area.rds"), "soy_area_ha")
cat("Cleaning soybean value...\n")
soy_value <- clean_sidra(readRDS("../data/raw_soy_value.rds"), "soy_value_1000brl")
cat("Cleaning soybean production...\n")
soy_prod <- clean_sidra(readRDS("../data/raw_soy_production.rds"), "soy_prod_tons")
cat("Cleaning cattle herd...\n")
cattle <- clean_sidra(readRDS("../data/raw_cattle.rds"), "cattle_head")
cat("Cleaning temp crop area...\n")
temp_crop <- clean_sidra(readRDS("../data/raw_temp_crop_area.rds"), "temp_crop_area_ha")

# Merge agricultural outcomes
cat("\n=== Merging Agricultural Outcomes ===\n")

agri <- soy_area %>%
  full_join(soy_value, by = c("muni_code", "year")) %>%
  full_join(soy_prod, by = c("muni_code", "year")) %>%
  full_join(cattle, by = c("muni_code", "year")) %>%
  full_join(temp_crop, by = c("muni_code", "year"))

agri <- agri %>%
  mutate(soy_yield = ifelse(soy_area_ha > 0, soy_prod_tons / soy_area_ha, NA_real_))

cat("Merged:", nrow(agri), "rows,", n_distinct(agri$muni_code), "municipalities\n")

# ============================================================
# 2. Process MapBiomas land cover data
# ============================================================
cat("\n=== Processing MapBiomas Data ===\n")

mb <- readxl::read_excel("../data/mapbiomas_municipalities.xlsx", sheet = "COVERAGE_9")
cat("MapBiomas loaded:", nrow(mb), "rows x", ncol(mb), "cols\n")

# Column structure:
# biome, state, municipality, municipality-state, geocode, class,
# class_level_0 (Natural/Antropic), class_level_1 (1.Forest / 3.Farming etc),
# class_level_2-4, then year columns 1985-2023

# ============================================================
# 3. Construct treatment variable
# ============================================================
cat("\n=== Constructing Treatment Variable ===\n")

# Treatment: farming share in 2008 = area classified as "3. Farming" / total area
# This captures pre-amnesty agricultural intensity

# Farming = class_level_1 == "3. Farming"
# Forest = class_level_1 %in% c("1. Forest", "2. Non Forest Natural Formation")

treatment <- mb %>%
  mutate(
    geocode = as.character(geocode),
    area_2008 = as.numeric(`2008`),
    area_1985 = as.numeric(`1985`),
    area_2000 = as.numeric(`2000`),
    is_farming = class_level_1 == "3. Farming",
    is_forest = class_level_1 %in% c("1. Forest", "2. Non Forest Natural Formation")
  ) %>%
  filter(!is.na(area_2008)) %>%
  group_by(geocode) %>%
  summarise(
    total_area = sum(area_2008, na.rm = TRUE),
    farming_area_2008 = sum(area_2008[is_farming], na.rm = TRUE),
    forest_area_2008 = sum(area_2008[is_forest], na.rm = TRUE),
    farming_area_1985 = sum(area_1985[is_farming], na.rm = TRUE),
    forest_area_1985 = sum(area_1985[is_forest], na.rm = TRUE),
    farming_area_2000 = sum(area_2000[is_farming], na.rm = TRUE),
    forest_area_2000 = sum(area_2000[is_forest], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    farming_share_2008 = farming_area_2008 / total_area,
    forest_share_2008 = forest_area_2008 / total_area,
    # Forest loss 1985-2008 (potential amnesty windfall)
    forest_loss_1985_2008 = forest_area_1985 - forest_area_2008,
    forest_loss_share = forest_loss_1985_2008 / total_area,
    # Forest conversion to farming 2000-2008 (more recent proxy)
    farming_expansion_2000_2008 = farming_area_2008 - farming_area_2000,
    farming_expansion_share = farming_expansion_2000_2008 / total_area
  ) %>%
  filter(total_area > 0)

cat("Treatment variable for", nrow(treatment), "municipalities\n")
cat("Farming share 2008 — Mean:", round(mean(treatment$farming_share_2008), 3),
    "SD:", round(sd(treatment$farming_share_2008), 3),
    "Range:", round(min(treatment$farming_share_2008), 3),
    "-", round(max(treatment$farming_share_2008), 3), "\n")
cat("Forest loss share 1985-2008 — Mean:", round(mean(treatment$forest_loss_share), 3),
    "SD:", round(sd(treatment$forest_loss_share), 3), "\n")

# Get biome info (primary biome per municipality)
biome_info <- mb %>%
  mutate(geocode = as.character(geocode), area_2008 = as.numeric(`2008`)) %>%
  group_by(geocode, biome) %>%
  summarise(biome_area = sum(area_2008, na.rm = TRUE), .groups = "drop") %>%
  group_by(geocode) %>%
  slice_max(biome_area, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(geocode, biome)

# Get state info
state_info <- mb %>%
  mutate(geocode = as.character(geocode)) %>%
  distinct(geocode, state)

treatment <- treatment %>%
  left_join(biome_info, by = "geocode") %>%
  left_join(state_info, by = "geocode") %>%
  mutate(state_code = substr(geocode, 1, 2))

cat("\nBiome distribution:\n")
print(count(treatment, biome, sort = TRUE))

saveRDS(treatment, "../data/treatment_data.rds")

# ============================================================
# 4. Post-2012 deforestation outcome (for moral hazard)
# ============================================================
cat("\n=== Constructing Post-2012 Deforestation ===\n")

defor_outcome <- mb %>%
  mutate(
    geocode = as.character(geocode),
    area_2012 = as.numeric(`2012`),
    area_2020 = as.numeric(`2020`),
    is_forest = class_level_1 %in% c("1. Forest", "2. Non Forest Natural Formation")
  ) %>%
  filter(!is.na(area_2012), !is.na(area_2020)) %>%
  group_by(geocode) %>%
  summarise(
    forest_2012 = sum(area_2012[is_forest], na.rm = TRUE),
    forest_2020 = sum(area_2020[is_forest], na.rm = TRUE),
    total_area = sum(area_2012, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    post_2012_forest_loss = forest_2012 - forest_2020,
    post_2012_defor_share = post_2012_forest_loss / total_area
  ) %>%
  filter(total_area > 0)

cat("Post-2012 deforestation — Mean:", round(mean(defor_outcome$post_2012_defor_share, na.rm = TRUE), 4),
    "SD:", round(sd(defor_outcome$post_2012_defor_share, na.rm = TRUE), 4), "\n")

saveRDS(defor_outcome, "../data/defor_outcome.rds")

# ============================================================
# 5. Construct analysis panel
# ============================================================
cat("\n=== Constructing Analysis Panel ===\n")

# Match municipality codes: SIDRA uses 7-digit, MapBiomas also 7-digit (geocode)
# But SIDRA may have trailing check digit differences
# Standard: IBGE 6-digit = first 6 of 7-digit code

agri <- agri %>%
  mutate(muni_code_6 = substr(muni_code, 1, 6))

treatment <- treatment %>%
  mutate(muni_code_6 = substr(geocode, 1, 6)) %>%
  # Deduplicate: keep one row per 6-digit code (take area-weighted average if multiple)
  group_by(muni_code_6) %>%
  summarise(
    farming_share_2008 = weighted.mean(farming_share_2008, total_area, na.rm = TRUE),
    forest_share_2008 = weighted.mean(forest_share_2008, total_area, na.rm = TRUE),
    forest_loss_share = weighted.mean(forest_loss_share, total_area, na.rm = TRUE),
    farming_expansion_share = weighted.mean(farming_expansion_share, total_area, na.rm = TRUE),
    biome = first(biome),
    state = first(state),
    state_code = first(state_code),
    total_area = sum(total_area),
    .groups = "drop"
  )

panel <- agri %>%
  inner_join(treatment, by = "muni_code_6") %>%
  filter(!is.na(farming_share_2008))

# Add DiD variables
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2012),
    treatment_x_post = farming_share_2008 * post,
    state_year = paste0(state_code, "_", year),
    event_time = year - 2012
  )

# Log outcomes (adding 1 to handle zeros)
panel <- panel %>%
  mutate(
    log_soy_area = log(soy_area_ha + 1),
    log_soy_value = log(soy_value_1000brl + 1),
    log_soy_prod = log(soy_prod_tons + 1),
    log_cattle = log(cattle_head + 1),
    log_temp_crop = log(temp_crop_area_ha + 1),
    log_soy_yield = log(soy_yield + 0.001)
  )

cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Municipalities:", n_distinct(panel$muni_code_6), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Post-2012:", sum(panel$post), "| Pre-2012:", sum(1 - panel$post), "\n")

cat("\nOutcome means:\n")
panel %>%
  summarise(
    soy_area = mean(soy_area_ha, na.rm = TRUE),
    cattle = mean(cattle_head, na.rm = TRUE),
    temp_crop = mean(temp_crop_area_ha, na.rm = TRUE),
    farming_share = mean(farming_share_2008)
  ) %>%
  print()

saveRDS(panel, "../data/analysis_panel.rds")
cat("\n=== Panel saved ===\n")
