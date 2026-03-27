# 04_robustness.R — Robustness checks and placebo tests
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
ban_dates <- readRDS("../data/ban_dates.rds")

# ──────────────────────────────────────────────────────────
# 1. PLACEBO: Non-sealant contaminants (lead, atrazine)
# ──────────────────────────────────────────────────────────
run_placebo <- function(data_path, contaminant_name) {
  if (!file.exists(data_path)) {
    cat(sprintf("  No %s data available — skipping placebo\n", contaminant_name))
    return(NULL)
  }

  raw <- readRDS(data_path)

  clean <- raw %>%
    transmute(
      station_id    = Location_Identifier,
      activity_date = as.Date(Activity_StartDate),
      year          = year(activity_date),
      result_value  = as.numeric(Result_Measure),
      detect_cond   = Result_ResultDetectionCondition,
      detect_limit  = as.numeric(DetectionLimit_MeasureA),
      state         = state_abbr
    ) %>%
    filter(year >= 2000 & year <= 2025) %>%
    mutate(
      is_nondetect = grepl("Not Detected|Below|Non-detect", detect_cond, ignore.case = TRUE),
      value_clean = case_when(
        !is.na(result_value) & result_value >= 0 ~ result_value,
        is_nondetect & !is.na(detect_limit)       ~ detect_limit / 2,
        TRUE                                       ~ NA_real_
      )
    ) %>%
    filter(!is.na(value_clean))

  # Station-year averages
  sy <- clean %>%
    group_by(station_id, state, year) %>%
    summarise(mean_val = mean(value_clean, na.rm = TRUE),
              n_samples = n(), .groups = "drop") %>%
    mutate(log_val = log(mean_val + 0.001))

  # Merge treatment
  sy <- sy %>%
    left_join(ban_dates %>% select(state_abbr, ban_year),
              by = c("state" = "state_abbr")) %>%
    mutate(
      ban_year = replace_na(ban_year, 0L),
      treated  = as.integer(ban_year > 0),
      post     = as.integer(year >= ban_year & ban_year > 0),
      station_num = as.integer(factor(station_id))
    )

  # Keep stations with ≥3 years
  keep <- sy %>% group_by(station_id) %>%
    summarise(n = n(), .groups = "drop") %>%
    filter(n >= 3) %>% pull(station_id)
  sy <- sy %>% filter(station_id %in% keep)

  if (nrow(sy) < 50 || n_distinct(sy$state) < 3) {
    cat(sprintf("  %s: insufficient data (%d obs)\n", contaminant_name, nrow(sy)))
    return(NULL)
  }

  # TWFE placebo
  m <- feols(log_val ~ post | station_num + year, data = sy, cluster = ~state)
  cat(sprintf("\n=== Placebo: %s (TWFE) ===\n", contaminant_name))
  cat(sprintf("  Coef: %.4f (SE: %.4f, p=%.3f)\n",
              coef(m)["post"], se(m)["post"], pvalue(m)["post"]))
  cat(sprintf("  N=%d, stations=%d\n", nrow(sy), n_distinct(sy$station_id)))
  m
}

placebo_lead <- run_placebo("../data/lead_raw.rds", "Lead")
placebo_atrazine <- run_placebo("../data/atrazine_raw.rds", "Atrazine")

# ──────────────────────────────────────────────────────────
# 2. NOT-YET-TREATED as control group (alternative to never-treated)
# ──────────────────────────────────────────────────────────
cat("\n=== CS with not-yet-treated controls ===\n")
cs_data <- panel %>%
  mutate(first_treat = ifelse(ban_year == 0, 0, ban_year))

cs_nyt <- tryCatch({
  att_gt(
    yname      = "log_fluor",
    tname      = "year",
    idname     = "station_num",
    gname      = "first_treat",
    data       = cs_data,
    control_group = "notyettreated",
    base_period = "universal",
    clustervars = "state",
    print_details = FALSE
  )
}, error = function(e) {
  cat(sprintf("  CS not-yet-treated failed: %s\n", e$message))
  NULL
})

if (!is.null(cs_nyt)) {
  cs_nyt_agg <- aggte(cs_nyt, type = "simple")
  cat(sprintf("  ATT (not-yet-treated): %.4f (SE: %.4f)\n",
              cs_nyt_agg$overall.att, cs_nyt_agg$overall.se))
}

# ──────────────────────────────────────────────────────────
# 3. PYRENE as secondary PAH outcome
# ──────────────────────────────────────────────────────────
pyrene_result <- run_placebo("../data/pyrene_raw.rds", "Pyrene (secondary PAH)")

# ──────────────────────────────────────────────────────────
# 4. EXCLUDE early adopter (DC 2009) — sensitivity
# ──────────────────────────────────────────────────────────
cat("\n=== Sensitivity: Exclude DC ===\n")
panel_noDC <- panel %>% filter(state != "DC")
if (nrow(panel_noDC) > 100) {
  twfe_noDC <- feols(
    log_fluor ~ post | station_num + year,
    data = panel_noDC,
    cluster = ~state
  )
  cat(sprintf("  TWFE (no DC): %.4f (SE: %.4f)\n",
              coef(twfe_noDC)["post"], se(twfe_noDC)["post"]))
}

# ──────────────────────────────────────────────────────────
# 5. DROP NON-DETECTS entirely (sensitivity to substitution rule)
# ──────────────────────────────────────────────────────────
cat("\n=== Sensitivity: Drop all non-detects ===\n")
fluor_clean <- readRDS("../data/fluor_clean.rds")
fluor_detect_only <- fluor_clean %>%
  filter(!is_nondetect) %>%
  group_by(station_id, state, year, ban_year, lat, lon) %>%
  summarise(
    mean_fluor = mean(value_ugl, na.rm = TRUE),
    n_samples = n(), .groups = "drop"
  ) %>%
  mutate(
    log_fluor = log(mean_fluor + 0.001),
    treated = as.integer(ban_year > 0),
    post = as.integer(year >= ban_year & ban_year > 0),
    station_num = as.integer(factor(station_id))
  )

keep_detect <- fluor_detect_only %>%
  group_by(station_id) %>% summarise(n = n(), .groups = "drop") %>%
  filter(n >= 3) %>% pull(station_id)
fluor_detect_only <- fluor_detect_only %>% filter(station_id %in% keep_detect)

if (nrow(fluor_detect_only) > 100) {
  twfe_detect <- tryCatch({
    feols(
      log_fluor ~ post | station_num + year,
      data = fluor_detect_only,
      cluster = ~state
    )
  }, error = function(e) {
    cat(sprintf("  Detects-only failed: %s\n", e$message))
    NULL
  })
  if (!is.null(twfe_detect)) {
    cat(sprintf("  TWFE (detects only): %.4f (SE: %.4f)\n",
                coef(twfe_detect)["post"], se(twfe_detect)["post"]))
  }
}

# ── Save robustness results ──
rob_results <- list(
  placebo_lead = placebo_lead,
  placebo_atrazine = placebo_atrazine,
  cs_nyt = if (exists("cs_nyt_agg")) cs_nyt_agg else NULL,
  pyrene = pyrene_result,
  twfe_noDC = if (exists("twfe_noDC")) twfe_noDC else NULL,
  twfe_detect_only = if (exists("twfe_detect")) twfe_detect else NULL
)
saveRDS(rob_results, "../data/results_robustness.rds")

cat("\nRobustness checks complete.\n")
