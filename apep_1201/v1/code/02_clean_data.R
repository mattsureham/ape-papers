# ============================================================================
# apep_1201: When the Anchor Drops
# 02_clean_data.R - Build matched branch-event analysis sample
# ============================================================================

source("code/00_packages.R")

fdic <- safe_read_parquet("data/raw/fdic_sod_2010_2024.parquet")
snap <- safe_read_parquet("data/raw/snap_grocery_history.parquet")

fdic <- unique(fdic, by = c("year", "branch_id"))
setorder(fdic, branch_id, year)
fdic[, exit_next_year := as.integer(shift(year, type = "lead") != year + 1L), by = branch_id]
fdic[year == max(year), exit_next_year := NA_integer_]
fdic[, exit_within_3y := as.integer(shift(year, n = 3L, type = "lead") != year + 3L), by = branch_id]
fdic[year > max(year) - 3L, exit_within_3y := NA_integer_]
fdic[, ln_deposits := log1p(pmax(deposits, 0))]

latest_branch <- fdic[order(branch_id, year)][, .SD[.N], by = branch_id]
latest_branch <- latest_branch[!is.na(latitude) & !is.na(longitude)]

snap[, store_name_upper := toupper(store_name)]
snap[, chain := fifelse(
  str_detect(store_name_upper, "^A&P($|\\s)"),
  "A_AND_P",
  fifelse(
    str_detect(store_name_upper, "^TOPS($|\\s|#)") | str_detect(store_name_upper, "^TOPS MARKET"),
    "TOPS",
    fifelse(
      str_detect(store_name_upper, "^WINN DIXIE"),
      "WINN_DIXIE",
      fifelse(
        str_detect(store_name_upper, "^BI-LO"),
        "BI_LO",
        fifelse(
          str_detect(store_name_upper, "^HARVEYS SUPERMARKET"),
          "HARVEYS",
          NA_character_
        )
      )
    )
  )
)]

chain_snap <- snap[!is.na(chain)]
chain_snap <- merge(chain_snap, chain_windows, by = "chain", all.x = TRUE)
chain_snap[, end_year := year(end_date)]
chain_snap[, bankruptcy_exit := !is.na(end_year) & end_year >= shock_year & end_year <= shock_year + 1L]
chain_snap <- chain_snap[bankruptcy_exit == TRUE]

chain_snap[, event_year := shock_year]
chain_snap[, event_id := .I]
chain_snap[, event_label := sprintf("%s_%05d", chain, event_id)]

branch_sf <- st_as_sf(
  latest_branch[, .(branch_id, county_id, state_abbr, latitude, longitude)],
  coords = c("longitude", "latitude"),
  crs = 4326
)
exit_sf <- st_as_sf(
  chain_snap[, .(event_id, event_label, chain, event_year, latitude, longitude)],
  coords = c("longitude", "latitude"),
  crs = 4326
)

branch_sf <- st_transform(branch_sf, 3857)
exit_sf <- st_transform(exit_sf, 3857)

candidate_idx <- st_is_within_distance(branch_sf, exit_sf, dist = 8046.72)

pair_list <- vector("list", length(candidate_idx))
for (i in seq_along(candidate_idx)) {
  idx <- candidate_idx[[i]]
  if (length(idx) == 0L) {
    next
  }

  branch_row <- branch_sf[i, ]
  exit_rows <- exit_sf[idx, ]
  dist_m <- as.numeric(st_distance(branch_row, exit_rows))

  pair_list[[i]] <- data.table(
    branch_id = branch_row$branch_id,
    county_id = branch_row$county_id,
    state_abbr = branch_row$state_abbr,
    event_id = exit_rows$event_id,
    event_label = exit_rows$event_label,
    chain = exit_rows$chain,
    event_year = exit_rows$event_year,
    distance_m = dist_m
  )
}

pairs_dt <- rbindlist(pair_list, fill = TRUE)
stopifnot(nrow(pairs_dt) > 0L)

pairs_dt[, distance_miles := distance_m / 1609.34]
pairs_dt[, distance_band := fifelse(
  distance_miles <= 1, "treated_0_1",
  fifelse(distance_miles > 1 & distance_miles <= 2, "buffer_1_2",
          fifelse(distance_miles > 2 & distance_miles <= 5, "control_2_5", NA_character_))
)]
pairs_dt <- pairs_dt[!is.na(distance_band)]

pair_choice <- pairs_dt[
  order(branch_id, event_year, distance_miles)
][, .SD[1], by = branch_id]

pair_choice <- pair_choice[distance_band %chin% c("treated_0_1", "control_2_5")]
pair_choice[, treated := as.integer(distance_band == "treated_0_1")]

analysis_panel <- merge(
  fdic,
  pair_choice[, .(branch_id, county_id_match = county_id, event_id, event_label, chain, event_year, distance_miles, distance_band, treated)],
  by = "branch_id",
  all = FALSE
)

analysis_panel[, rel_year := year - event_year]
analysis_panel <- analysis_panel[rel_year >= -5 & rel_year <= 3]
analysis_panel <- analysis_panel[!(distance_band == "buffer_1_2")]

analysis_panel[, county_year_fe := sprintf("%s_%d", county_id, year)]
analysis_panel[, post := as.integer(rel_year >= 0)]
analysis_panel[, small_branch := as.integer(deposits <= quantile(deposits, 0.5, na.rm = TRUE)), by = year]
analysis_panel[, distance_close := as.integer(distance_miles <= 0.5)]

treated_count <- uniqueN(analysis_panel[treated == 1, branch_id])
control_count <- uniqueN(analysis_panel[treated == 0, branch_id])

cat(sprintf("Matched treated branches: %d\n", treated_count))
cat(sprintf("Matched control branches: %d\n", control_count))

sample_summary <- analysis_panel[, .(
  obs = .N,
  branches = uniqueN(branch_id),
  counties = uniqueN(county_id),
  years = paste(range(year), collapse = "-"),
  mean_exit = mean(exit_next_year, na.rm = TRUE),
  mean_deposits = mean(deposits, na.rm = TRUE)
), by = treated]

fwrite(sample_summary, "data/derived/sample_summary.csv")
safe_write_parquet(analysis_panel, "data/derived/analysis_panel.parquet")
safe_write_parquet(pair_choice, "data/derived/branch_event_assignment.parquet")
safe_write_parquet(chain_snap, "data/derived/bankruptcy_exit_stores.parquet")

cat("Clean data construction complete.\n")
