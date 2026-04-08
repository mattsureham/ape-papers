# 02_clean_data.R — Data cleaning and panel construction for apep_1426
# TV News Amplification and Workplace Safety Deterrence

source("./code/00_packages.R")

DATA_DIR <- "./data"

# ============================================================
# 1. Load GDELT TV Safety Coverage
# ============================================================
cat("=== Loading GDELT TV safety coverage ===\n")

safety_dt <- fread(file.path(DATA_DIR, "gdelt_tv_safety.csv"))
cat(sprintf("  Raw safety data: %d rows\n", nrow(safety_dt)))

# Parse dates
safety_dt[, date := as.Date(as.character(date), format = "%Y%m%d")]
safety_dt <- safety_dt[!is.na(date)]

# Aggregate to station-week level
safety_dt[, week := floor_date(date, "week", week_start = 1)]  # Monday start
safety_weekly <- safety_dt[, .(
  safety_coverage = sum(value, na.rm = TRUE),
  safety_segments = .N,
  n_queries_hit = uniqueN(query)
), by = .(week, station)]

cat(sprintf("  Safety weekly: %d station-weeks\n", nrow(safety_weekly)))

# Aggregate across stations to national weekly level
safety_national <- safety_weekly[, .(
  total_safety_coverage = sum(safety_coverage),
  total_safety_segments = sum(safety_segments),
  n_stations_covering = uniqueN(station)
), by = week]

cat(sprintf("  National safety weekly: %d weeks\n", nrow(safety_national)))
cat(sprintf("  Weeks with >0 safety coverage: %d\n",
            sum(safety_national$total_safety_segments > 0)))

# ============================================================
# 2. Load GDELT TV Mega-Event Coverage (Instrument)
# ============================================================
cat("\n=== Loading GDELT TV mega-event coverage ===\n")

mega_dt <- fread(file.path(DATA_DIR, "gdelt_tv_megaevents.csv"))
cat(sprintf("  Raw mega-event data: %d rows\n", nrow(mega_dt)))

mega_dt[, date := as.Date(as.character(date), format = "%Y%m%d")]
mega_dt <- mega_dt[!is.na(date)]

# Aggregate to week level
mega_dt[, week := floor_date(date, "week", week_start = 1)]
mega_weekly <- mega_dt[, .(
  mega_event_coverage = sum(value, na.rm = TRUE),
  mega_event_segments = .N
), by = .(week, query)]

# Wide format: one column per event type
mega_wide <- dcast(mega_weekly, week ~ query,
                   value.var = "mega_event_coverage",
                   fun.aggregate = sum, fill = 0)

# Clean column names
setnames(mega_wide, function(x) gsub('[" ]', '', tolower(x)))
# Create total mega-event index
mega_cols <- setdiff(names(mega_wide), "week")
mega_wide[, total_mega_events := rowSums(.SD), .SDcols = mega_cols]

cat(sprintf("  Mega-event weekly: %d weeks\n", nrow(mega_wide)))

# ============================================================
# 3. Load BLS Injury/Illness Data
# ============================================================
cat("\n=== Loading BLS workplace injury data ===\n")

bls_file <- file.path(DATA_DIR, "bls_soii_state.txt")
cfoi_file <- file.path(DATA_DIR, "bls_cfoi.txt")

if (file.exists(bls_file)) {
  bls_raw <- fread(bls_file, strip.white = TRUE)
  cat(sprintf("  BLS SOII raw: %d rows\n", nrow(bls_raw)))

  # Load series definitions to identify state-level injury rates
  series_file <- file.path(DATA_DIR, "is_series.txt")
  if (file.exists(series_file)) {
    series_def <- fread(series_file, strip.white = TRUE)
    cat(sprintf("  Series definitions: %d series\n", nrow(series_def)))

    # Filter for state-level total injury/illness rate series
    # Series ID format: ISU{state}{industry}{case}{datatype}
    # We want total nonfatal injury/illness rates by state
    state_series <- series_def[grepl("^ISU", series_id)]

    if (nrow(state_series) > 0) {
      cat(sprintf("  State-level series: %d\n", nrow(state_series)))

      # Merge with data
      bls_state <- merge(bls_raw, state_series[, .(series_id)],
                         by = "series_id")
      cat(sprintf("  State-level data: %d rows\n", nrow(bls_state)))
    }
  }
} else if (file.exists(cfoi_file)) {
  cfoi_raw <- fread(cfoi_file, strip.white = TRUE)
  cat(sprintf("  BLS CFOI raw: %d rows\n", nrow(cfoi_raw)))
} else {
  cat("  WARNING: No BLS injury data available. Will use GDELT only.\n")
}

# ============================================================
# 4. Construct Analysis Panel
# ============================================================
cat("\n=== Constructing analysis panel ===\n")

# Create balanced weekly panel 2015-2023
all_weeks <- data.table(
  week = seq(as.Date("2015-01-05"), as.Date("2023-12-25"), by = "week")
)
cat(sprintf("  Panel: %d weeks (2015-2023)\n", nrow(all_weeks)))

# Merge safety coverage
panel <- merge(all_weeks, safety_national, by = "week", all.x = TRUE)

# Fill NAs with 0 (weeks with no safety coverage)
setnafill(panel, fill = 0,
          cols = c("total_safety_coverage", "total_safety_segments", "n_stations_covering"))

# Merge mega-event coverage
panel <- merge(panel, mega_wide, by = "week", all.x = TRUE)

# Fill mega-event NAs with 0
mega_merge_cols <- intersect(names(mega_wide), names(panel))
mega_merge_cols <- setdiff(mega_merge_cols, "week")
for (col in mega_merge_cols) {
  set(panel, which(is.na(panel[[col]])), col, 0)
}

# Add time variables
panel[, `:=`(
  year = year(week),
  quarter = quarter(week),
  month = month(week),
  week_of_year = isoweek(week),
  year_quarter = paste0(year(week), "Q", quarter(week))
)]

# Create the instrument: mega-event share of total coverage
# (proxy for competing-news pressure)
panel[, mega_event_share := fifelse(
  total_safety_coverage + total_mega_events > 0,
  total_mega_events / (total_safety_coverage + total_mega_events),
  0
)]

# Create log transforms (adding 1 to avoid log(0))
panel[, `:=`(
  log_safety = log1p(total_safety_coverage),
  log_mega = log1p(total_mega_events)
)]

# ============================================================
# 5. Create Pre-Scheduled Event Indicators (Cleaner Instrument)
# ============================================================
cat("\n=== Creating pre-scheduled event calendar ===\n")

# Olympics (known dates — truly exogenous)
olympics <- data.table(
  start = as.Date(c(
    "2016-08-05",   # Rio Summer
    "2018-02-09",   # PyeongChang Winter
    "2020-07-23",   # Tokyo (delayed to 2021)
    "2021-07-23",   # Tokyo Summer (actual)
    "2022-02-04"    # Beijing Winter
  )),
  end = as.Date(c(
    "2016-08-21",
    "2018-02-25",
    "2020-08-08",   # Would have been
    "2021-08-08",
    "2022-02-20"
  )),
  event = c("rio2016", "pyeongchang2018", "tokyo2020_planned",
            "tokyo2021", "beijing2022")
)

# Super Bowl (first Sunday of February)
superbowl_dates <- as.Date(c(
  "2015-02-01", "2016-02-07", "2017-02-05", "2018-02-04",
  "2019-02-03", "2020-02-02", "2021-02-07", "2022-02-13",
  "2023-02-12"
))

# Create weekly indicators
panel[, olympics_week := 0L]
for (i in seq_len(nrow(olympics))) {
  s <- olympics[i, start]
  e <- olympics[i, end]
  panel[week >= s - 7 & week <= e + 7, olympics_week := 1L]
}

panel[, superbowl_week := 0L]
for (sb in superbowl_dates) {
  panel[week >= sb - 7 & week <= sb + 7, superbowl_week := 1L]
}

# Combined pre-scheduled event indicator
panel[, prescheduled_event := pmax(olympics_week, superbowl_week)]

cat(sprintf("  Olympics weeks: %d\n", sum(panel$olympics_week)))
cat(sprintf("  Super Bowl weeks: %d\n", sum(panel$superbowl_week)))
cat(sprintf("  Any pre-scheduled event: %d\n", sum(panel$prescheduled_event)))

# ============================================================
# 6. Summary Statistics
# ============================================================
cat("\n=== Panel Summary ===\n")
cat(sprintf("  Observations: %d weeks\n", nrow(panel)))
cat(sprintf("  Period: %s to %s\n", min(panel$week), max(panel$week)))
cat(sprintf("  Mean safety coverage: %.2f\n", mean(panel$total_safety_coverage)))
cat(sprintf("  SD safety coverage: %.2f\n", sd(panel$total_safety_coverage)))
cat(sprintf("  Mean mega-event coverage: %.2f\n", mean(panel$total_mega_events)))
cat(sprintf("  Weeks with safety coverage > 0: %d (%.1f%%)\n",
            sum(panel$total_safety_segments > 0),
            100 * mean(panel$total_safety_segments > 0)))

# Save panel
panel_file <- file.path(DATA_DIR, "analysis_panel.csv")
fwrite(panel, panel_file)
cat(sprintf("\n  Panel saved: %s (%d rows)\n", panel_file, nrow(panel)))

# Save diagnostics
diagnostics <- list(
  n_treated = sum(panel$prescheduled_event),  # Weeks with pre-scheduled events
  n_pre = sum(panel$prescheduled_event == 0),  # Non-event weeks (controls)
  n_obs = nrow(panel)
)
writeLines(jsonlite::toJSON(diagnostics, auto_unbox = TRUE, pretty = TRUE),
           file.path(DATA_DIR, "diagnostics.json"))
cat(sprintf("  Diagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
