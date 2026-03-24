# 02_clean_data.R — Construct school-year panel for DiD analysis
# apep_0881: Academy Conversion and Pupil Sorting

source("00_packages.R")

data_dir <- "../data"
panel_raw <- readRDS(file.path(data_dir, "panel_raw.rds"))
academies <- readRDS(file.path(data_dir, "academies.rds"))

cat("Raw panel: ", nrow(panel_raw), "obs,", n_distinct(panel_raw$URN), "schools\n")

# ==============================================================================
# 1. Download and parse GIAS links (predecessor-successor mapping)
# ==============================================================================
cat("Downloading GIAS links data...\n")

links_file <- file.path(data_dir, "gias_links.csv")
if (!file.exists(links_file)) {
  resp <- httr2::request(
    "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/links_edubasealldata20260301.csv"
  ) |>
    httr2::req_timeout(60) |>
    httr2::req_headers("User-Agent" = "Mozilla/5.0") |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()
  stopifnot(httr2::resp_status(resp) == 200)
  writeBin(httr2::resp_body_raw(resp), links_file)
}

links <- read_csv(links_file, show_col_types = FALSE)
cat("Links rows:", nrow(links), "\n")

# Filter to predecessor/successor links (these track academy conversions)
pred_links <- links |>
  filter(grepl("Predecessor", LinkType, ignore.case = TRUE)) |>
  select(academy_urn = URN, predecessor_urn = LinkURN, link_type = LinkType)

cat("Predecessor links:", nrow(pred_links), "\n")

# ==============================================================================
# 2. Filter to English state-funded schools
# ==============================================================================
school_phases <- c("Primary", "Secondary", "Middle deemed primary",
                   "Middle deemed secondary", "All through")

state_types <- c(
  "Community school", "Voluntary aided school", "Voluntary controlled school",
  "Foundation school", "Academy converter", "Academy sponsor led",
  "Free schools", "University technical college", "Studio schools",
  "City technology college"
)

academy_types <- c("Academy converter", "Academy sponsor led",
                   "Free schools", "University technical college", "Studio schools")

panel <- panel_raw |>
  filter(Phase %in% school_phases, TypeName %in% state_types, StatusName == "Open") |>
  select(URN, EstablishmentName, TypeName, LA_code, LA_name, Phase,
         NumberOfPupils, PercentageFSM, snapshot_year) |>
  mutate(
    fsm_pct = as.numeric(PercentageFSM),
    n_pupils = as.numeric(NumberOfPupils),
    la_code = as.character(LA_code),
    is_academy = TypeName %in% academy_types
  ) |>
  filter(!is.na(fsm_pct), !is.na(n_pupils), n_pupils >= 10)

cat("\nFiltered panel:", nrow(panel), "rows,", n_distinct(panel$URN), "schools\n")

# ==============================================================================
# 3. Create "school entity" that tracks through conversion using predecessor links
# ==============================================================================

# For each academy, find its predecessor maintained school
# This lets us track FSM% before and after conversion using the SAME physical school

# Build entity mapping: assign a common entity_id to predecessor-successor pairs
entity_map <- pred_links |>
  # Use predecessor URN as the entity ID (the original school)
  mutate(entity_id = predecessor_urn) |>
  select(URN = academy_urn, entity_id)

# For schools without predecessor links, entity_id = URN
all_urns <- unique(panel$URN)
entity_map_full <- tibble(URN = all_urns) |>
  left_join(entity_map, by = "URN") |>
  mutate(entity_id = ifelse(is.na(entity_id), URN, entity_id))

# Also add predecessor URNs that map to themselves
pred_urns <- unique(pred_links$predecessor_urn)
pred_self <- tibble(URN = pred_urns[!pred_urns %in% entity_map_full$URN],
                    entity_id = pred_urns[!pred_urns %in% entity_map_full$URN])
entity_map_full <- bind_rows(entity_map_full, pred_self)

# Merge entity_id into panel
panel <- panel |>
  left_join(entity_map_full, by = "URN")

# Check: how many entities have both maintained and academy observations?
entity_types <- panel |>
  group_by(entity_id) |>
  summarise(
    has_maintained = any(!is_academy),
    has_academy = any(is_academy),
    n_obs = n(),
    n_years = n_distinct(snapshot_year),
    .groups = "drop"
  )

converters <- entity_types |> filter(has_maintained & has_academy)
cat("\nEntities with both maintained and academy observations:", nrow(converters), "\n")

always_acad <- entity_types |> filter(!has_maintained & has_academy)
cat("Always-academy entities:", nrow(always_acad), "\n")

never_acad <- entity_types |> filter(has_maintained & !has_academy)
cat("Never-academy entities:", nrow(never_acad), "\n")

# ==============================================================================
# 4. Identify treatment timing for converters
# ==============================================================================

# For converter entities, treatment year = first year observed as academy
converter_timing <- panel |>
  filter(entity_id %in% converters$entity_id, is_academy) |>
  group_by(entity_id) |>
  summarise(treat_year = min(snapshot_year), .groups = "drop")

cat("\nConverter cohorts:\n")
print(table(converter_timing$treat_year))

# Also use GIAS exact conversion dates for entities that don't appear in panel as maintained
# (e.g., predecessor closed before 2021)
gias_timing <- academies |>
  filter(!is.na(conversion_year)) |>
  inner_join(entity_map_full |> filter(URN %in% academies$URN), by = "URN") |>
  group_by(entity_id) |>
  summarise(gias_treat_year = min(conversion_year), .groups = "drop")

converter_timing <- converter_timing |>
  left_join(gias_timing, by = "entity_id") |>
  mutate(
    # Use panel-observed conversion if available; GIAS date as cross-check
    final_treat_year = treat_year
  )

# ==============================================================================
# 5. Build entity-level panel
# ==============================================================================

# For each entity-year, take the observation (could be from predecessor or successor URN)
# When both exist in same year (overlap), prefer the one with more pupils
entity_panel <- panel |>
  group_by(entity_id, snapshot_year) |>
  slice_max(n_pupils, n = 1, with_ties = FALSE) |>
  ungroup()

# Assign treatment status
entity_panel <- entity_panel |>
  left_join(converter_timing |> select(entity_id, treat_year = final_treat_year),
            by = "entity_id") |>
  mutate(
    treatment_group = case_when(
      entity_id %in% converters$entity_id ~ "converter",
      entity_id %in% always_acad$entity_id ~ "always_academy",
      entity_id %in% never_acad$entity_id ~ "never_academy",
      TRUE ~ "other"
    ),
    # CS-DiD group variable: treatment year for treated, 0 for never-treated
    g = case_when(
      treatment_group == "converter" & !is.na(treat_year) ~ treat_year,
      treatment_group == "never_academy" ~ 0L,
      TRUE ~ NA_integer_
    ),
    year = snapshot_year,
    school_id = entity_id
  )

# For CS-DiD: converters + never-academy only
# Need at least 1 pre-treatment observation
did_panel <- entity_panel |>
  filter(treatment_group %in% c("converter", "never_academy")) |>
  filter(!is.na(g))

# Drop treated schools with no pre-treatment data
treated_with_pre <- did_panel |>
  filter(g > 0) |>
  group_by(school_id) |>
  filter(any(year < g)) |>
  pull(school_id) |>
  unique()

cat("\nTreated entities with pre-treatment data:", length(treated_with_pre), "\n")

did_panel <- did_panel |>
  filter(g == 0 | school_id %in% treated_with_pre)

cat("\nFinal CS-DiD panel:\n")
cat("  Rows:", nrow(did_panel), "\n")
cat("  Entities:", n_distinct(did_panel$school_id), "\n")
n_treated <- n_distinct(did_panel$school_id[did_panel$g > 0])
n_control <- n_distinct(did_panel$school_id[did_panel$g == 0])
cat("  Treated:", n_treated, "\n")
cat("  Control:", n_control, "\n")
cat("  Cohorts:", paste(sort(unique(did_panel$g[did_panel$g > 0])), collapse = ", "), "\n")

cat("\nFSM% by group:\n")
did_panel |>
  group_by(treatment_group) |>
  summarise(
    n = n_distinct(school_id),
    mean_fsm = round(mean(fsm_pct, na.rm = TRUE), 1),
    sd_fsm = round(sd(fsm_pct, na.rm = TRUE), 1),
    mean_pupils = round(mean(n_pupils), 0),
    .groups = "drop"
  ) |>
  print()

# ==============================================================================
# 6. LA-level segregation panel
# ==============================================================================

la_panel <- panel |>
  group_by(la_code, LA_name, snapshot_year) |>
  summarise(
    n_schools = n(),
    total_pupils = sum(n_pupils),
    mean_fsm = weighted.mean(fsm_pct, n_pupils, na.rm = TRUE),
    sd_fsm = sd(fsm_pct, na.rm = TRUE),
    cv_fsm = sd_fsm / pmax(mean_fsm, 0.01),
    total_fsm = sum(n_pupils * fsm_pct / 100),
    la_fsm_share = total_fsm / total_pupils,
    dissimilarity = sum(abs(fsm_pct/100 - la_fsm_share) * n_pupils) /
                    (2 * total_pupils * pmax(la_fsm_share * (1 - la_fsm_share), 0.001)),
    n_academy = sum(is_academy),
    academy_share = n_academy / n_schools,
    .groups = "drop"
  ) |>
  filter(n_schools >= 10)

cat("\nLA-level panel:", nrow(la_panel), "rows,", n_distinct(la_panel$la_code), "LAs\n")
cat("Mean dissimilarity:", round(mean(la_panel$dissimilarity, na.rm = TRUE), 3), "\n")

# ==============================================================================
# 7. Save everything
# ==============================================================================
saveRDS(did_panel, file.path(data_dir, "did_panel.rds"))
saveRDS(la_panel, file.path(data_dir, "la_panel.rds"))
saveRDS(entity_panel, file.path(data_dir, "entity_panel.rds"))

# Summary stats for paper
summary_stats <- did_panel |>
  group_by(treatment_group) |>
  summarise(
    n_schools = n_distinct(school_id),
    mean_fsm = mean(fsm_pct, na.rm = TRUE),
    sd_fsm = sd(fsm_pct, na.rm = TRUE),
    mean_pupils = mean(n_pupils, na.rm = TRUE),
    sd_pupils = sd(n_pupils, na.rm = TRUE),
    pct_primary = mean(Phase == "Primary", na.rm = TRUE) * 100,
    .groups = "drop"
  )
saveRDS(summary_stats, file.path(data_dir, "summary_stats.rds"))

# Diagnostics for validator
diagnostics <- list(
  n_treated = n_treated,
  n_pre = length(unique(did_panel$year[did_panel$year < min(converter_timing$treat_year)])),
  n_obs = nrow(did_panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
