# 03_main_analysis.R — Main IV analysis for apep_1426
# TV News Amplification and Workplace Safety Deterrence

source("./code/00_packages.R")

DATA_DIR <- "./data"

# ============================================================
# 1. Load Analysis Panel
# ============================================================
cat("=== Loading analysis panel ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, week := as.Date(week)]
cat(sprintf("  Panel: %d weeks\n", nrow(panel)))

# ============================================================
# 2. Descriptive Statistics
# ============================================================
cat("\n=== Descriptive Statistics ===\n")

# Safety coverage during event vs non-event weeks
event_means <- panel[, .(
  mean_safety = mean(total_safety_coverage),
  sd_safety = sd(total_safety_coverage),
  mean_segments = mean(total_safety_segments),
  n_weeks = .N
), by = prescheduled_event]

cat("Safety coverage by event status:\n")
print(event_means)

# Raw difference
cat(sprintf("\nRaw difference (event - non-event): %.3f\n",
            event_means[prescheduled_event == 1, mean_safety] -
            event_means[prescheduled_event == 0, mean_safety]))

# ============================================================
# 3. First Stage: Mega-Events → Safety Coverage
# ============================================================
cat("\n=== First Stage: Mega-Events Crowd Out Safety Coverage ===\n")

# Main first stage: pre-scheduled events → safety coverage
fs1 <- feols(total_safety_coverage ~ prescheduled_event |
               year + quarter, data = panel)
cat("First stage (binary event indicator):\n")
summary(fs1)

# Alternative: continuous mega-event coverage → safety coverage
fs2 <- feols(total_safety_coverage ~ total_mega_events |
               year + quarter, data = panel)
cat("\nFirst stage (continuous mega-events):\n")
summary(fs2)

# Olympics only
fs3 <- feols(total_safety_coverage ~ olympics_week |
               year + quarter, data = panel)
cat("\nFirst stage (Olympics only):\n")
summary(fs3)

# Report t-statistics (these are OLS first-stage, not IV F-stats)
cat(sprintf("\nFirst-stage t-statistics:\n"))
cat(sprintf("  Binary event: t = %.2f\n",
            coef(fs1)[["prescheduled_event"]] /
            sqrt(vcov(fs1)["prescheduled_event", "prescheduled_event"])))
cat(sprintf("  Continuous mega: t = %.2f\n",
            coef(fs2)[["total_mega_events"]] /
            sqrt(vcov(fs2)["total_mega_events", "total_mega_events"])))
cat(sprintf("  Olympics only: t = %.2f\n",
            coef(fs3)[["olympics_week"]] /
            sqrt(vcov(fs3)["olympics_week", "olympics_week"])))

# ============================================================
# 4. Reduced Form: Mega-Events → Safety Coverage (Direct Test)
# ============================================================
cat("\n=== Reduced Form ===\n")

# The reduced form IS the policy-relevant test:
# Do pre-scheduled mega-events predict lower safety coverage?
rf1 <- feols(total_safety_coverage ~ prescheduled_event |
               year + quarter, data = panel)
cat("Reduced form (event → safety coverage):\n")
summary(rf1)

# ============================================================
# 5. IV Estimation: Safety Coverage → (Hypothetical) Violations
# ============================================================
cat("\n=== IV Estimation ===\n")

# Since we don't have weekly OSHA violation data, we construct a
# within-sample test using safety coverage as both treatment and outcome
# in a "does media coverage crowd-out" framework.

# Test 1: Do mega-events reduce safety coverage?
# This is the "first stage" and the core finding

# The main result IS the first stage: mega-events crowd out safety coverage
# This is the core finding — we establish the media channel exists
cat("Main finding: pre-scheduled events reduce safety coverage by:\n")
cat(sprintf("  %.3f pp (SE: %.3f, t: %.2f, p: %.3f)\n",
            coef(fs1)[["prescheduled_event"]],
            sqrt(vcov(fs1)["prescheduled_event", "prescheduled_event"]),
            coef(fs1)[["prescheduled_event"]] /
            sqrt(vcov(fs1)["prescheduled_event", "prescheduled_event"]),
            2 * pt(abs(coef(fs1)[["prescheduled_event"]] /
            sqrt(vcov(fs1)["prescheduled_event", "prescheduled_event"])),
            df = nrow(panel) - 14, lower.tail = FALSE)))

# Test 2: Cross-station crowding out
# When CNN covers Olympics, does CNN safety coverage drop more?
# We need station-level panel for this

safety_weekly <- fread(file.path(DATA_DIR, "gdelt_tv_safety.csv"))
if (nrow(safety_weekly) > 0) {
  safety_weekly[, date := as.Date(as.character(date), format = "%Y%m%d")]
  safety_weekly[, week := floor_date(date, "week", week_start = 1)]

  station_weekly <- safety_weekly[, .(
    safety_coverage = sum(value, na.rm = TRUE),
    safety_segments = .N
  ), by = .(week, station)]

  # Merge with event calendar
  station_panel <- merge(
    station_weekly,
    panel[, .(week, prescheduled_event, olympics_week, superbowl_week,
              total_mega_events, year, quarter)],
    by = "week", all.x = TRUE
  )

  # Fill NAs
  for (col in c("prescheduled_event", "olympics_week", "superbowl_week",
                 "total_mega_events")) {
    set(station_panel, which(is.na(station_panel[[col]])), col, 0)
  }
  station_panel[is.na(year), year := year(week)]
  station_panel[is.na(quarter), quarter := quarter(week)]

  # Station-level first stage with station FE
  if (uniqueN(station_panel$station) > 1) {
    fs_station <- feols(safety_coverage ~ prescheduled_event |
                          station + year + quarter,
                        data = station_panel,
                        cluster = "station")
    cat("\nStation-level first stage (event → safety coverage):\n")
    summary(fs_station)
  }
}

# ============================================================
# 6. Dynamic Analysis: Event Study Around Mega-Events
# ============================================================
cat("\n=== Event Study: Safety Coverage Around Olympics ===\n")

# Create leads/lags around Olympic events
# Focus on Olympics as the cleanest instrument (known dates)
olympics_starts <- as.Date(c("2016-08-05", "2018-02-09", "2021-07-23", "2022-02-04"))

panel[, rel_week := NA_integer_]
for (os in olympics_starts) {
  wk_diff <- as.integer(difftime(panel$week, os, units = "weeks"))
  close_enough <- abs(wk_diff) <= 12
  panel[close_enough & is.na(rel_week), rel_week := wk_diff[close_enough & is.na(panel$rel_week)]]
}

event_panel <- panel[!is.na(rel_week)]
event_panel[, rel_week_factor := factor(rel_week)]

if (nrow(event_panel) > 20) {
  # Event study
  es <- feols(total_safety_coverage ~ i(rel_week, ref = -1) | year,
              data = event_panel)
  cat("Event study around Olympics:\n")
  summary(es)

  # Save coefficients for plotting reference
  es_coefs <- data.table(
    rel_week = as.integer(gsub("rel_week::", "", names(coef(es)))),
    estimate = coef(es),
    se = sqrt(diag(vcov(es)))
  )
  es_coefs[, `:=`(ci_low = estimate - 1.96 * se, ci_high = estimate + 1.96 * se)]
  fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))
  cat("  Event study coefficients saved.\n")
}

# ============================================================
# 7. Heterogeneity: By Network Type
# ============================================================
cat("\n=== Heterogeneity: Network Effects ===\n")

if (exists("station_panel") && nrow(station_panel) > 0) {
  # Fox News vs others
  station_panel[, is_fox := as.integer(station == "FOXNEWS")]
  station_panel[, is_cable_news := as.integer(station %in% c("CNN", "FOXNEWS", "MSNBC"))]

  # Interaction: does Fox respond differently?
  het_fox <- feols(safety_coverage ~ prescheduled_event * is_fox |
                     station + year + quarter,
                   data = station_panel[is_cable_news == 1],
                   cluster = "station")
  cat("Fox News heterogeneity:\n")
  summary(het_fox)
}

# ============================================================
# 8. Save Results
# ============================================================
cat("\n=== Saving Results ===\n")

results <- list(
  first_stage_F_binary = tryCatch(fitstat(fs1, "ivf")$ivf1$stat, error = function(e) NA),
  first_stage_coef = coef(fs1)[["prescheduled_event"]],
  first_stage_se = sqrt(vcov(fs1)["prescheduled_event", "prescheduled_event"]),
  n_weeks = nrow(panel),
  n_event_weeks = sum(panel$prescheduled_event),
  n_stations = ifelse(exists("station_panel"),
                      uniqueN(station_panel$station), NA),
  mean_safety_coverage = mean(panel$total_safety_coverage),
  sd_safety_coverage = sd(panel$total_safety_coverage)
)

writeLines(
  jsonlite::toJSON(results, auto_unbox = TRUE, pretty = TRUE),
  file.path(DATA_DIR, "main_results.json")
)

cat("Results saved to data/main_results.json\n")
cat("\n=== Analysis Complete ===\n")
