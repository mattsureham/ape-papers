## ===========================================================
## 02_clean_data.R — Build analysis panel
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

# -----------------------------------------------------------
# 1. Load raw data
# -----------------------------------------------------------
ged_nga <- fread(file.path(data_dir, "ucdp_nigeria.csv"))
treatment <- read_csv(file.path(data_dir, "treatment_assignment.csv"),
                      show_col_types = FALSE)
nga_lgas <- st_read(file.path(data_dir, "nga_lgas.gpkg"),
                    layer = "lgas", quiet = TRUE)
nga_states <- st_read(file.path(data_dir, "nga_states.gpkg"),
                      layer = "states", quiet = TRUE)

# -----------------------------------------------------------
# 2. Spatial join: assign UCDP events to LGAs
# -----------------------------------------------------------
cat("Spatially joining UCDP events to LGAs...\n")

# Convert UCDP events to sf points
events_sf <- ged_nga %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Spatial join to LGA polygons
events_lga <- st_join(events_sf, nga_lgas[, c("NAME_1", "NAME_2", "GID_2")],
                       join = st_within)

# Extract back to data.table
events_dt <- events_lga %>%
  st_drop_geometry() %>%
  as.data.table() %>%
  rename(state_gadm = NAME_1, lga_gadm = NAME_2, lga_id = GID_2)

cat(sprintf("Events matched to LGAs: %d / %d (%.1f%%)\n",
            sum(!is.na(events_dt$lga_id)),
            nrow(events_dt),
            100 * sum(!is.na(events_dt$lga_id)) / nrow(events_dt)))

# -----------------------------------------------------------
# 3. Classify pastoral zones
# -----------------------------------------------------------
cat("Classifying pastoral zones...\n")

# Method: Use pre-treatment (2010-2015) non-state violence events
# as a proxy for pastoral conflict zones. LGAs with >=2 type-2
# events in the pre-treatment period are classified as "pastoral."
# This is a revealed-preference measure: areas where farmer-herder
# conflict actually occurred are pastoral zones.

pre_treatment_events <- events_dt %>%
  filter(year >= 2010 & year <= 2015,
         type_of_violence == 2,        # Non-state violence
         !is.na(lga_id))

pastoral_lgas <- pre_treatment_events %>%
  group_by(lga_id) %>%
  summarise(pre_events = n(), .groups = "drop") %>%
  filter(pre_events >= 2) %>%
  pull(lga_id)

# Also include LGAs on known transhumance corridors
# (Middle Belt states: Benue, Plateau, Nasarawa, Taraba, Kaduna, Niger, Kogi, Kwara)
middle_belt_states <- c("Benue", "Plateau", "Nasarawa", "Taraba",
                         "Kaduna", "Niger", "Kogi", "Kwara")

# Alternative: use livestock density if GLW data available
glw_file <- file.path(data_dir, "glw4_cattle.tif")
if (file.exists(glw_file)) {
  cat("Using FAO GLW cattle density for pastoral classification...\n")
  library(terra)
  cattle_rast <- rast(glw_file)

  # Extract mean cattle density per LGA
  lga_vect <- vect(nga_lgas)
  cattle_by_lga <- extract(cattle_rast, lga_vect, fun = mean, na.rm = TRUE)

  nga_lgas$cattle_density <- cattle_by_lga[, 2]

  # Pastoral = above median cattle density
  pastoral_threshold <- median(nga_lgas$cattle_density, na.rm = TRUE)
  pastoral_lgas_glw <- nga_lgas$GID_2[nga_lgas$cattle_density > pastoral_threshold &
                                       !is.na(nga_lgas$cattle_density)]

  # Union of conflict-based and livestock-based classification
  pastoral_lgas <- unique(c(pastoral_lgas, pastoral_lgas_glw))
  cat(sprintf("Pastoral LGAs (union of conflict + GLW): %d\n", length(pastoral_lgas)))
} else {
  # Fallback: use Middle Belt LGAs as proxy
  mb_lgas <- nga_lgas$GID_2[nga_lgas$NAME_1 %in% middle_belt_states]
  pastoral_lgas <- unique(c(pastoral_lgas, mb_lgas))
  cat(sprintf("Pastoral LGAs (conflict + Middle Belt proxy): %d\n", length(pastoral_lgas)))
}

# -----------------------------------------------------------
# 4. Build state-year panel
# -----------------------------------------------------------
cat("Building state-year panel...\n")

# State name harmonization between UCDP and GADM
state_crosswalk <- tibble(
  ucdp_name = sort(unique(ged_nga$adm_1)),
) %>%
  mutate(
    clean_name = str_replace(ucdp_name, " state$", "") %>%
      str_replace("^FCT$", "Federal Capital Territory") %>%
      str_to_title()
  )

# Count events by state-year-type
state_year <- events_dt %>%
  filter(!is.na(state_gadm)) %>%
  group_by(state = state_gadm, year, type_of_violence) %>%
  summarise(
    events = n(),
    deaths = sum(best, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = type_of_violence,
    values_from = c(events, deaths),
    values_fill = 0,
    names_sep = "_type"
  )

# Rename for clarity
state_year <- state_year %>%
  rename_with(~ case_when(
    . == "events_type1" ~ "events_statebased",
    . == "events_type2" ~ "events_nonstate",
    . == "events_type3" ~ "events_onesided",
    . == "deaths_type1" ~ "deaths_statebased",
    . == "deaths_type2" ~ "deaths_nonstate",
    . == "deaths_type3" ~ "deaths_onesided",
    TRUE ~ .
  ))

# Complete panel (all states × all years)
all_states <- unique(nga_states$NAME_1)
all_years <- 2005:2024
full_panel <- expand_grid(state = all_states, year = all_years)

state_panel <- full_panel %>%
  left_join(state_year, by = c("state", "year")) %>%
  mutate(across(starts_with("events_") | starts_with("deaths_"),
                ~ replace_na(., 0))) %>%
  # Add total events/deaths
  mutate(
    events_total = events_statebased + events_nonstate + events_onesided,
    deaths_total = deaths_statebased + deaths_nonstate + deaths_onesided
  )

# Merge treatment assignment
state_panel <- state_panel %>%
  left_join(treatment %>% select(state, first_treat),
            by = "state")

# Handle unmatched states
unmatched <- state_panel %>% filter(is.na(first_treat)) %>% distinct(state)
if (nrow(unmatched) > 0) {
  cat("WARNING: Unmatched states (setting first_treat=0):\n")
  print(unmatched$state)
  state_panel <- state_panel %>%
    mutate(first_treat = replace_na(first_treat, 0L))
}

# Create state numeric ID
state_panel <- state_panel %>%
  mutate(state_id = as.integer(factor(state)))

cat(sprintf("State-year panel: %d obs (%d states × %d years)\n",
            nrow(state_panel),
            n_distinct(state_panel$state),
            n_distinct(state_panel$year)))

# -----------------------------------------------------------
# 5. Build LGA-year panel
# -----------------------------------------------------------
cat("Building LGA-year panel...\n")

# Count events by LGA-year-type
lga_year <- events_dt %>%
  filter(!is.na(lga_id)) %>%
  group_by(lga_id, state = state_gadm, year, type_of_violence) %>%
  summarise(
    events = n(),
    deaths = sum(best, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = type_of_violence,
    values_from = c(events, deaths),
    values_fill = 0,
    names_sep = "_type"
  )

lga_year <- lga_year %>%
  rename_with(~ case_when(
    . == "events_type1" ~ "events_statebased",
    . == "events_type2" ~ "events_nonstate",
    . == "events_type3" ~ "events_onesided",
    . == "deaths_type1" ~ "deaths_statebased",
    . == "deaths_type2" ~ "deaths_nonstate",
    . == "deaths_type3" ~ "deaths_onesided",
    TRUE ~ .
  ))

# Complete panel
all_lgas <- nga_lgas %>%
  st_drop_geometry() %>%
  select(lga_id = GID_2, state = NAME_1, lga_name = NAME_2)

full_lga_panel <- expand_grid(
  lga_id = all_lgas$lga_id,
  year = all_years
) %>%
  left_join(all_lgas, by = "lga_id")

lga_panel <- full_lga_panel %>%
  left_join(lga_year %>% select(-state), by = c("lga_id", "year")) %>%
  mutate(across(starts_with("events_") | starts_with("deaths_"),
                ~ replace_na(., 0))) %>%
  mutate(
    events_total = events_statebased + events_nonstate + events_onesided,
    deaths_total = deaths_statebased + deaths_nonstate + deaths_onesided
  )

# Add treatment and pastoral classification
lga_panel <- lga_panel %>%
  left_join(treatment %>% select(state, first_treat), by = "state") %>%
  mutate(
    first_treat = replace_na(first_treat, 0L),
    pastoral = as.integer(lga_id %in% pastoral_lgas),
    # DDD treatment indicator
    treated_pastoral = as.integer(first_treat > 0 & first_treat <= year & pastoral == 1)
  )

# Create numeric IDs
lga_panel <- lga_panel %>%
  mutate(
    lga_num = as.integer(factor(lga_id)),
    state_id = as.integer(factor(state))
  )

cat(sprintf("LGA-year panel: %d obs (%d LGAs × %d years)\n",
            nrow(lga_panel),
            n_distinct(lga_panel$lga_id),
            n_distinct(lga_panel$year)))
cat(sprintf("Pastoral LGAs: %d (%.1f%%)\n",
            sum(lga_panel$pastoral[lga_panel$year == 2020]),
            100 * mean(lga_panel$pastoral[lga_panel$year == 2020])))

# -----------------------------------------------------------
# 6. Save analysis datasets
# -----------------------------------------------------------
write_csv(state_panel, file.path(data_dir, "state_panel.csv"))
write_csv(lga_panel, file.path(data_dir, "lga_panel.csv"))

# Also save pastoral classification
pastoral_df <- tibble(
  lga_id = all_lgas$lga_id,
  pastoral = as.integer(all_lgas$lga_id %in% pastoral_lgas)
)
write_csv(pastoral_df, file.path(data_dir, "pastoral_classification.csv"))

cat("\nData cleaning complete. Panels saved.\n")
