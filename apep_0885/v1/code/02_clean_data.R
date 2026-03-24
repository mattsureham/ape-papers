## 02_clean_data.R — Clean and construct analysis panels
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

source("00_packages.R")

DATA_DIR <- "../data"

## Create cantonal reference data if not already saved
cantonal_pop <- data.frame(
  canton_abbr = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR",
                  "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG",
                  "TI", "VD", "VS", "NE", "GE", "JU"),
  canton_id = as.character(1:26),
  canton_name = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                  "Nidwalden", "Glarus", "Zug", "Fribourg",
                  "Solothurn", "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
                  "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen", "Graubünden",
                  "Aargau", "Thurgau",
                  "Ticino", "Vaud", "Valais", "Neuchâtel", "Genève", "Jura"),
  pop_2015 = c(1487969, 1026513, 403397, 36145, 155863, 37378,
               42556, 40147, 124007, 311914,
               269441, 198206, 285624, 80769, 54954, 15984, 499065, 197550,
               663462, 270709,
               354375, 784822, 339060, 178107, 490578, 73122),
  is_ticino = c(0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 1,0,0,0,0,0),
  is_alpine_control = c(0,0,0,1,0,0,0,0,0,0, 0,0,0,0,0,0,0,1,0,0, 0,0,1,0,0,0),
  stringsAsFactors = FALSE
)
saveRDS(cantonal_pop, file.path(DATA_DIR, "cantonal_pop.rds"))

## ============================================================================
## 1. Clean Construction Data (Canton Level)
## ============================================================================

cat("=== Cleaning Canton Construction Data ===\n")

constr_raw <- readRDS(file.path(DATA_DIR, "construction_canton_raw.rds"))

# Rename columns
names(constr_raw) <- c("geo", "contractor", "building_type", "work_type",
                        "unit", "year", "value")

constr <- constr_raw %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value)
  ) %>%
  # Keep only canton-level rows (2-letter codes)
  filter(nchar(geo) == 2, geo != "CH") %>%
  # Create readable labels
  mutate(
    building_label = case_when(
      building_type == "0" ~ "total",
      building_type == "6011" ~ "hochbau",
      TRUE ~ building_type
    ),
    work_label = case_when(
      work_type == "0" ~ "total_expenditure",
      work_type == "4" ~ "investment",
      work_type == "1" ~ "new_construction",
      TRUE ~ work_type
    )
  )

# Merge cantonal reference data
constr <- constr %>%
  left_join(cantonal_pop, by = c("geo" = "canton_abbr"))

# Verify all cantons matched
stopifnot(sum(is.na(constr$canton_name)) == 0)

# Create per-capita measure
constr <- constr %>%
  mutate(value_pc = value / pop_2015 * 1000)  # per 1000 residents

# Primary panel: total construction expenditure by canton-year
panel_canton <- constr %>%
  filter(building_label == "total", work_label == "total_expenditure") %>%
  select(canton = geo, canton_name, year, construction = value,
         construction_pc = value_pc, is_ticino, is_alpine_control, pop_2015)

cat("Canton panel: ", nrow(panel_canton), "rows,",
    n_distinct(panel_canton$canton), "cantons,",
    range(panel_canton$year), "\n")

# Investment-only panel
panel_canton_inv <- constr %>%
  filter(building_label == "total", work_label == "investment") %>%
  select(canton = geo, year, investment = value) %>%
  mutate(investment = as.numeric(investment))

# New construction panel
panel_canton_new <- constr %>%
  filter(building_label == "total", work_label == "new_construction") %>%
  select(canton = geo, year, new_construction = value) %>%
  mutate(new_construction = as.numeric(new_construction))

# Building (Hochbau) panel
panel_canton_hb <- constr %>%
  filter(building_label == "hochbau", work_label == "total_expenditure") %>%
  select(canton = geo, year, hochbau = value) %>%
  mutate(hochbau = as.numeric(hochbau))

# Merge all outcome variables
panel_canton <- panel_canton %>%
  left_join(panel_canton_inv, by = c("canton", "year")) %>%
  left_join(panel_canton_new, by = c("canton", "year")) %>%
  left_join(panel_canton_hb, by = c("canton", "year")) %>%
  mutate(
    investment_pc = investment / pop_2015 * 1000,
    new_construction_pc = new_construction / pop_2015 * 1000,
    hochbau_pc = hochbau / pop_2015 * 1000
  )

## ============================================================================
## 2. Clean Construction Data (Municipal Level)
## ============================================================================

cat("\n=== Cleaning Municipal Construction Data ===\n")

constr_muni_raw <- readRDS(file.path(DATA_DIR, "construction_muni_raw.rds"))
names(constr_muni_raw) <- c("geo", "contractor", "building_type", "work_type",
                             "unit", "year", "value")

# Identify canton from municipality code
# BFS municipality numbering: first 2 digits = district
# Ticino districts: 50xx (Bellinzona), 51xx (Locarno), 52xx (Lugano), 53xx (Mendrisio)
# GR districts: 37xx-39xx (and some 35xx, 36xx)
# VS districts: 60xx-62xx
# UR districts: 12xx

constr_muni <- constr_muni_raw %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value),
    muni_id = geo
  ) %>%
  # Only keep municipality rows (4-digit codes)
  filter(grepl("^[0-9]{4}$", geo)) %>%
  mutate(
    district = as.integer(substr(geo, 1, 2)),
    canton = case_when(
      district %in% 50:53 ~ "TI",
      district %in% 35:39 ~ "GR",
      district %in% 60:62 ~ "VS",
      district %in% 12:12 ~ "UR",
      TRUE ~ "other"
    ),
    is_ticino = as.integer(canton == "TI"),
    is_control = as.integer(canton %in% c("GR", "VS", "UR"))
  ) %>%
  filter(canton != "other")

# Create municipal panel
panel_muni <- constr_muni %>%
  select(muni_id, canton, year, construction = value, is_ticino, is_control)

cat("Municipal panel:", nrow(panel_muni), "rows,",
    n_distinct(panel_muni$muni_id), "municipalities\n")
cat("  Ticino:", n_distinct(panel_muni$muni_id[panel_muni$is_ticino == 1]), "\n")
cat("  Controls:", n_distinct(panel_muni$muni_id[panel_muni$is_control == 1]), "\n")

## ============================================================================
## 3. Clean HESTA Tourism Data (Canton Level)
## ============================================================================

cat("\n=== Cleaning Canton Tourism Data ===\n")

hesta_raw <- readRDS(file.path(DATA_DIR, "hesta_canton_raw.rds"))
names(hesta_raw) <- c("year", "month", "canton_id", "origin", "indicator", "value")

hesta <- hesta_raw %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value),
    canton_id = canton_id
  ) %>%
  # Remove Switzerland total
  filter(canton_id != "8100") %>%
  # Create origin labels
  mutate(
    origin_label = case_when(
      origin == "00" ~ "total",
      origin == "1" ~ "swiss",
      origin == "11" ~ "german",
      origin == "14" ~ "italian",
      TRUE ~ origin
    )
  ) %>%
  # Merge canton reference
  left_join(cantonal_pop, by = c("canton_id" = "canton_id"))

# Pivot to wide format for analysis
hesta_wide <- hesta %>%
  select(canton_abbr, year, origin_label, overnights = value,
         is_ticino, is_alpine_control, pop_2015) %>%
  pivot_wider(names_from = origin_label, values_from = overnights,
              names_prefix = "nights_")

# Per-capita tourism
hesta_wide <- hesta_wide %>%
  mutate(
    nights_total_pc = nights_total / pop_2015 * 1000,
    nights_swiss_pc = nights_swiss / pop_2015 * 1000
  )

cat("Canton tourism panel:", nrow(hesta_wide), "rows,",
    n_distinct(hesta_wide$canton_abbr), "cantons,",
    range(hesta_wide$year), "\n")

## ============================================================================
## 4. Clean HESTA Tourism Data (Municipal Level)
## ============================================================================

cat("\n=== Cleaning Municipal Tourism Data ===\n")

hesta_muni_raw <- readRDS(file.path(DATA_DIR, "hesta_muni_raw.rds"))
names(hesta_muni_raw) <- c("year", "month", "muni_id", "origin", "indicator", "value")

hesta_muni <- hesta_muni_raw %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value),
    muni_id = muni_id
  )

# Map municipalities to cantons using BFS coding
# HESTA uses different municipality IDs — map via first digits
hesta_muni <- hesta_muni %>%
  mutate(
    muni_num = as.integer(muni_id),
    district = as.integer(substr(muni_id, 1, 2)),
    canton = case_when(
      district %in% 50:53 ~ "TI",
      district %in% 35:39 ~ "GR",
      district %in% 60:62 ~ "VS",
      district %in% 12:12 ~ "UR",
      # Add other cantons for broader comparison
      district %in% c(1:2) ~ "ZH",
      district %in% c(3:4, 24:25) ~ "BE",
      district %in% c(10:11) ~ "LU",
      district %in% c(6:7) ~ "SZ",
      TRUE ~ "other"
    ),
    is_ticino = as.integer(canton == "TI"),
    is_alpine_control = as.integer(canton %in% c("GR", "VS", "UR"))
  )

hesta_muni_panel <- hesta_muni %>%
  filter(origin == "0") %>%  # Total tourists
  select(muni_id, canton, year, overnights = value, is_ticino, is_alpine_control)

cat("Municipal tourism panel:", nrow(hesta_muni_panel), "rows,",
    n_distinct(hesta_muni_panel$muni_id), "municipalities\n")
cat("  Ticino municipalities in HESTA:",
    n_distinct(hesta_muni_panel$muni_id[hesta_muni_panel$is_ticino == 1]), "\n")

## ============================================================================
## 5. Define Treatment Variables
## ============================================================================

# Treatment: post-December 2016 Gotthard Base Tunnel opening
# For annual data, 2017 is the first full post-treatment year
TREATMENT_YEAR <- 2017

panel_canton <- panel_canton %>%
  mutate(
    post = as.integer(year >= TREATMENT_YEAR),
    treat_post = is_ticino * post,
    # For event study
    rel_year = year - TREATMENT_YEAR,
    # Analysis sample: Ticino + alpine controls
    in_sample = as.integer(is_ticino == 1 | is_alpine_control == 1)
  )

panel_muni <- panel_muni %>%
  mutate(
    post = as.integer(year >= TREATMENT_YEAR),
    treat_post = is_ticino * post,
    rel_year = year - TREATMENT_YEAR
  )

hesta_wide <- hesta_wide %>%
  mutate(
    post = as.integer(year >= TREATMENT_YEAR),
    treat_post = is_ticino * post,
    rel_year = year - TREATMENT_YEAR,
    in_sample = as.integer(is_ticino == 1 | is_alpine_control == 1)
  )

## ============================================================================
## 6. Log Transformations
## ============================================================================

panel_canton <- panel_canton %>%
  mutate(
    log_construction = log(pmax(construction, 1)),
    log_investment = log(pmax(investment, 1)),
    log_new_construction = log(pmax(new_construction, 1)),
    log_hochbau = log(pmax(hochbau, 1))
  )

panel_muni <- panel_muni %>%
  mutate(log_construction = log(pmax(construction, 1)))

hesta_wide <- hesta_wide %>%
  mutate(
    log_nights_total = log(pmax(nights_total, 1)),
    log_nights_swiss = log(pmax(nights_swiss, 1)),
    log_nights_german = log(pmax(nights_german, 1)),
    log_nights_italian = log(pmax(nights_italian, 1))
  )

## ============================================================================
## 7. Save Cleaned Panels
## ============================================================================

saveRDS(panel_canton, file.path(DATA_DIR, "panel_canton.rds"))
saveRDS(panel_muni, file.path(DATA_DIR, "panel_muni.rds"))
saveRDS(hesta_wide, file.path(DATA_DIR, "panel_tourism_canton.rds"))
saveRDS(hesta_muni_panel, file.path(DATA_DIR, "panel_tourism_muni.rds"))

cat("\n=== Cleaned Panel Summary ===\n")
cat("Canton construction:", nrow(panel_canton), "obs (", n_distinct(panel_canton$canton),
    "cantons ×", length(unique(panel_canton$year)), "years)\n")
cat("Municipal construction:", nrow(panel_muni), "obs (",
    n_distinct(panel_muni$muni_id), "municipalities)\n")
cat("Canton tourism:", nrow(hesta_wide), "obs\n")
cat("Municipal tourism:", nrow(hesta_muni_panel), "obs\n")
cat("\nTreatment year:", TREATMENT_YEAR, "\n")
cat("Treated cantons: TI (Ticino)\n")
cat("Control cantons: GR (Graubünden), VS (Valais), UR (Uri)\n")
