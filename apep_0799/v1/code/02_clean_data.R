## ==========================================================================
## 02_clean_data.R — Merge shutdown events with nightlights panel
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

source("code/00_packages.R")

cat("=== Step 1: Load and Clean Shutdown Data ===\n")

## --- Load shutdown events ---
shutdowns <- readRDS("data/shutdowns_india_2016_22.rds")
shutdowns <- as.data.table(shutdowns)
cat("Raw shutdown events:", nrow(shutdowns), "\n")

## --- Clean dates ---
shutdowns[, start_date := as.Date(start_date)]
shutdowns[, end_date := as.Date(end_date)]
shutdowns[, year := year(start_date)]

## --- Compute duration (fill NAs with 1 day) ---
shutdowns[is.na(duration_days) | duration_days <= 0, duration_days := 1]

## --- Clean cause categories ---
shutdowns[, cause := tolower(actual_cause)]
shutdowns[cause %in% c("protest", "protests"), cause := "protest"]
shutdowns[cause %in% c("political instability"), cause := "political"]
shutdowns[cause %in% c("election", "elections"), cause := "elections"]
shutdowns[cause %in% c("communal violence"), cause := "communal_violence"]
shutdowns[cause == "exam cheating", cause := "exam"]
shutdowns[cause %in% c("religious holiday / anniversary",
                         "religious holiday/anniversary"), cause := "religious"]
shutdowns[cause %in% c("visits by government officials",
                         "visits by government officials"), cause := "vip_visit"]
shutdowns[cause %in% c("information control"), cause := "info_control"]
shutdowns[cause %in% c("other", "unknown"), cause := "other"]

cat("Cause distribution:\n")
print(shutdowns[, .N, by = cause][order(-N)])

## --- Clean state and district names for matching ---
# Standardize to match GADM names
shutdowns[, state_clean := trimws(state)]
shutdowns[, district_clean := trimws(districts)]

# Key state name fixes
shutdowns[state_clean == "Jammu and Kashmir", state_clean := "Jammu and Kashmīr"]

cat("\n=== Step 2: Load Nightlights Panel ===\n")

ntl <- fread("data/ntl_annual.csv")
cat("Nightlights observations:", nrow(ntl), "\n")
cat("Years:", paste(sort(unique(ntl$year)), collapse = ", "), "\n")
cat("Districts:", uniqueN(ntl$GID_2), "\n")

## --- Load district boundaries for name matching ---
districts_sf <- st_read("data/india_districts.gpkg", quiet = TRUE)
districts_dt <- as.data.table(districts_sf)[, .(GID_2, NAME_1, NAME_2)]

cat("\n=== Step 3: Match Shutdown Districts to GADM ===\n")

## Create lookup: GADM state-district unique combinations
gadm_lookup <- unique(districts_dt[, .(NAME_1, NAME_2, GID_2)])
gadm_lookup[, name2_lower := tolower(NAME_2)]

## Match shutdowns to GADM districts
## Strategy: fuzzy match on district name within state
library(stringdist)

shutdown_districts <- unique(shutdowns[, .(state_clean, district_clean)])
shutdown_districts[, district_lower := tolower(district_clean)]

# For each shutdown district, find best GADM match
matched <- list()
unmatched <- list()

for (i in seq_len(nrow(shutdown_districts))) {
  sd_state <- shutdown_districts[i, state_clean]
  sd_dist <- shutdown_districts[i, district_lower]

  # Find candidate GADM districts in the same state (fuzzy state match too)
  state_candidates <- gadm_lookup[
    stringdist::stringdist(tolower(NAME_1), tolower(sd_state), method = "jw") < 0.3
  ]

  if (nrow(state_candidates) == 0) {
    unmatched[[length(unmatched) + 1]] <- shutdown_districts[i]
    next
  }

  # Find best district match
  dists <- stringdist::stringdist(sd_dist, state_candidates$name2_lower, method = "jw")
  best_idx <- which.min(dists)

  if (length(best_idx) == 0 || length(dists) == 0) {
    unmatched[[length(unmatched) + 1]] <- shutdown_districts[i]
    next
  }

  if (dists[best_idx] < 0.3) {
    matched[[length(matched) + 1]] <- data.table(
      state_clean = sd_state,
      district_clean = shutdown_districts[i, district_clean],
      GID_2 = state_candidates[best_idx, GID_2],
      NAME_1 = state_candidates[best_idx, NAME_1],
      NAME_2 = state_candidates[best_idx, NAME_2],
      match_dist = dists[best_idx]
    )
  } else {
    unmatched[[length(unmatched) + 1]] <- shutdown_districts[i]
  }
}

match_table <- rbindlist(matched)
cat("Matched:", nrow(match_table), "district names\n")
cat("Unmatched:", length(unmatched), "district names\n")

if (length(unmatched) > 0) {
  cat("Unmatched districts:\n")
  print(rbindlist(unmatched))
}

## --- Merge GID_2 into shutdowns ---
shutdowns <- merge(shutdowns, match_table[, .(state_clean, district_clean, GID_2)],
                   by = c("state_clean", "district_clean"), all.x = TRUE)

matched_events <- sum(!is.na(shutdowns$GID_2))
cat("Events with GID_2 match:", matched_events, "/", nrow(shutdowns), "\n")

## --- Drop unmatched events ---
shutdowns <- shutdowns[!is.na(GID_2)]

cat("\n=== Step 4: Aggregate Shutdowns to District-Year ===\n")

## Create district-year treatment variables
shutdown_dy <- shutdowns[, .(
  n_shutdowns = .N,
  total_shutdown_days = sum(duration_days, na.rm = TRUE),
  n_exam_shutdowns = sum(cause == "exam"),
  exam_shutdown_days = sum(ifelse(cause == "exam", duration_days, 0), na.rm = TRUE),
  n_protest_shutdowns = sum(cause == "protest"),
  n_political_shutdowns = sum(cause == "political"),
  has_full_blackout = any(grepl("internet|all|full", tolower(affected_network),
                                perl = TRUE), na.rm = TRUE)
), by = .(GID_2, year)]

cat("District-year treatment observations:", nrow(shutdown_dy), "\n")

## --- Merge with NTL panel ---
panel <- merge(ntl, shutdown_dy, by = c("GID_2", "year"), all.x = TRUE)

## Fill missing shutdown data with zeros (no shutdown)
shutdown_vars <- c("n_shutdowns", "total_shutdown_days", "n_exam_shutdowns",
                   "exam_shutdown_days", "n_protest_shutdowns", "n_political_shutdowns")
for (v in shutdown_vars) {
  panel[is.na(get(v)), (v) := 0]
}
panel[is.na(has_full_blackout), has_full_blackout := FALSE]

## --- Create analysis variables ---
panel[, any_shutdown := as.integer(n_shutdowns > 0)]
panel[, any_exam_shutdown := as.integer(n_exam_shutdowns > 0)]
panel[, log_ntl := log(ntl_mean + 0.01)]  # Add small constant to handle zeros
panel[, shutdown_intensity := total_shutdown_days / 365]  # Fraction of year

# Identify J&K districts
panel[, is_jk := as.integer(NAME_1 %in% c("Jammu and Kashmīr", "Jammu and Kashmir",
                                            "Jammu & Kashmir"))]

cat("\n=== Step 5: Panel Summary ===\n")
cat("Panel dimensions:", nrow(panel), "district-year obs\n")
cat("Districts:", uniqueN(panel$GID_2), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Ever-shutdown districts:", uniqueN(panel[any_shutdown == 1, GID_2]), "\n")
cat("Exam-shutdown districts:", uniqueN(panel[any_exam_shutdown == 1, GID_2]), "\n")

cat("\nShutdown stats by year:\n")
print(panel[, .(
  n_shutdown_districts = sum(any_shutdown),
  total_shutdown_days = sum(total_shutdown_days),
  mean_ntl = mean(ntl_mean, na.rm = TRUE)
), by = year][order(year)])

cat("\nJ&K vs rest:\n")
print(panel[, .(
  mean_shutdowns = mean(n_shutdowns),
  mean_shutdown_days = mean(total_shutdown_days),
  mean_ntl = mean(ntl_mean, na.rm = TRUE)
), by = is_jk])

## --- Save panel ---
fwrite(panel, "data/analysis_panel.csv")
cat("\nSaved analysis panel to data/analysis_panel.csv\n")
