# =============================================================================
# 02_clean_data.R — Harmonize current boundaries and construct analysis panel
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

source("00_packages.R")

cat("=== Loading raw data ===\n")

merger_xwalk <- fread(file.path(DATA_DIR, "merger_crosswalk.csv"))
snapshot <- fread(file.path(DATA_DIR, "municipality_snapshot_2024.csv"))
pop_panel <- fread(file.path(DATA_DIR, "population_panel.csv"))

cat("  merger_xwalk:", nrow(merger_xwalk), "\n")
cat("  pop_panel:", nrow(pop_panel), "\n")

cat("\n=== Resolving current-boundary municipality IDs ===\n")

direct_map <- unique(merger_xwalk[, .(
  from = as.integer(dissolved_code),
  to = as.integer(successor_code),
  merger_year
)])
setorder(direct_map, from, merger_year)

resolve_code <- function(code, map_dt) {
  cur <- as.integer(code)
  seen <- integer()
  repeat {
    nxt <- map_dt[from == cur, to]
    if (length(nxt) == 0) break
    nxt <- nxt[1]
    if (nxt %in% seen) break
    seen <- c(seen, cur)
    cur <- nxt
  }
  cur
}

all_codes <- sort(unique(c(pop_panel$bfs_nr, direct_map$from, direct_map$to)))
code_map <- data.table(
  bfs_nr = all_codes,
  current_bfs = vapply(all_codes, resolve_code, integer(1), map_dt = direct_map)
)

event_map <- rbindlist(list(
  direct_map[, .(bfs_nr = from, merger_year)],
  direct_map[, .(bfs_nr = to, merger_year)]
), fill = TRUE)
event_map <- merge(event_map, code_map, by = "bfs_nr", all.x = TRUE)
current_merger_years <- event_map[, .(
  first_merger_year = min(merger_year, na.rm = TRUE)
), by = current_bfs]

never_codes <- setdiff(unique(code_map$current_bfs), current_merger_years$current_bfs)
current_merger_years <- rbind(
  current_merger_years,
  data.table(current_bfs = never_codes, first_merger_year = NA_integer_),
  fill = TRUE
)

fwrite(code_map, file.path(DATA_DIR, "code_map.csv"))
fwrite(current_merger_years, file.path(DATA_DIR, "current_merger_years.csv"))

cat("  Historical codes:", nrow(code_map), "\n")
cat("  Ever-merged current units:", sum(!is.na(current_merger_years$first_merger_year)), "\n")

cat("\n=== Building canton mapping ===\n")

cantons_snap <- snapshot[Level == 1, .(canton_hc = HistoricalCode, canton = ShortName)]
districts_snap <- snapshot[Level == 2, .(district_hc = HistoricalCode, canton_parent = Parent)]
districts_snap <- merge(
  districts_snap,
  cantons_snap,
  by.x = "canton_parent",
  by.y = "canton_hc",
  all.x = TRUE
)
communes_snap <- snapshot[Level == 3, .(
  current_bfs = as.integer(BfsCode),
  district_parent = Parent,
  current_name = Name
)]
communes_snap <- merge(
  communes_snap,
  districts_snap[, .(district_hc, canton)],
  by.x = "district_parent",
  by.y = "district_hc",
  all.x = TRUE
)
communes_snap <- unique(communes_snap[, .(current_bfs, canton, current_name)])

cat("\n=== Aggregating demographic outcomes to current boundaries ===\n")

pop_panel <- merge(pop_panel, code_map, by = "bfs_nr", all.x = TRUE)
stopifnot("Missing current_bfs mappings" = all(!is.na(pop_panel$current_bfs)))

panel <- pop_panel[, .(
  total = sum(total, na.rm = TRUE),
  swiss = sum(swiss, na.rm = TRUE),
  foreign = sum(foreign, na.rm = TRUE)
), by = .(current_bfs, year)]
panel[, foreign_share := fifelse(total > 0, foreign / total, NA_real_)]
panel[, log_foreign := log(pmax(foreign, 1))]

panel <- merge(panel, current_merger_years, by = "current_bfs", all.x = TRUE)
panel <- merge(panel, communes_snap, by = "current_bfs", all.x = TRUE)

panel[, ever_merged := !is.na(first_merger_year)]
panel <- panel[is.na(first_merger_year) | (first_merger_year >= 2015 & first_merger_year <= 2020)]
panel[, post_merger := ever_merged & year >= first_merger_year]
panel[, rel_year := year - first_merger_year]

# Restrict to years with >=5 pre-periods before earliest treatment
panel <- panel[year >= 2010 & year <= 2024]

setorder(panel, current_bfs, year)
panel[, `:=`(
  foreign_growth = 100 * (foreign / shift(foreign) - 1),
  total_growth = 100 * (total / shift(total) - 1),
  foreign_share_change = foreign_share - shift(foreign_share),
  swiss_growth = 100 * (swiss / shift(swiss) - 1)
), by = current_bfs]
panel[!is.finite(foreign_growth), foreign_growth := NA_real_]
panel[!is.finite(total_growth), total_growth := NA_real_]
panel[!is.finite(swiss_growth), swiss_growth := NA_real_]

baseline <- panel[year == 1999, .(
  baseline_foreign_share = foreign_share,
  baseline_total_pop = total
), by = current_bfs]
panel <- merge(panel, baseline, by = "current_bfs", all.x = TRUE)
if (all(is.na(panel$baseline_foreign_share))) {
  baseline <- panel[year == 2014, .(
    baseline_foreign_share = foreign_share,
    baseline_total_pop = total
  ), by = current_bfs]
  panel <- merge(
    panel[, !c("baseline_foreign_share", "baseline_total_pop")],
    baseline,
    by = "current_bfs",
    all.x = TRUE
  )
}

panel <- panel[!is.na(foreign_share) & !is.na(canton)]

cat("  Analysis rows:", nrow(panel), "\n")
cat("  Municipalities:", uniqueN(panel$current_bfs), "\n")
cat("  Treated municipalities:", uniqueN(panel[ever_merged == TRUE, current_bfs]), "\n")
cat("  Control municipalities:", uniqueN(panel[ever_merged == FALSE, current_bfs]), "\n")

diag <- list(
  n_treated = uniqueN(panel[ever_merged == TRUE, current_bfs]),
  n_pre = length(unique(panel$year[panel$year < min(panel[ever_merged == TRUE, first_merger_year])])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat("\nSaved analysis_panel.csv and diagnostics.json\n")
