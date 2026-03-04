# =============================================================================
# 02_clean_data.R — Build analysis panel
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# =============================================================================
# STEP 1: Load raw data
# =============================================================================

cat("\n=== Loading raw data ===\n")
merger_xwalk <- fread(file.path(DATA_DIR, "merger_crosswalk.csv"))
mutations    <- fread(file.path(DATA_DIR, "mutations_full.csv"))
snapshot     <- fread(file.path(DATA_DIR, "municipality_snapshot_2024.csv"))
ref_raw      <- fread(file.path(DATA_DIR, "referendum_turnout.csv"))
pop_dt       <- fread(file.path(DATA_DIR, "population_municipal.csv"))

# Also load election data if available
elec_file <- file.path(DATA_DIR, "election_turnout.csv")
has_elections <- file.exists(elec_file)
if (has_elections) {
  elec_dt <- fread(elec_file)
}

cat("  Merger crosswalk: ", nrow(merger_xwalk), "\n")
cat("  Referendum raw: ", nrow(ref_raw), "\n")
cat("  Population: ", nrow(pop_dt), "\n")

# =============================================================================
# STEP 2: Build BFS number lookup from PXWeb metadata
# =============================================================================

cat("\n=== Building BFS number lookup ===\n")

# The referendum data has geo_labels like "......Aarau" (no BFS number in text)
# But PXWeb metadata has codes like "0001" for "......Aeugst am Albis"
# The codes ARE the BFS numbers — we map geo_label → BFS code

# Re-fetch PXWeb metadata to get code↔text mapping
meta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1703030000_101/px-x-1703030000_101.px"
resp <- GET(meta_url, timeout(60))
meta <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
vars <- meta$variables

geo_row <- which(grepl("Gemeinde", vars$code))
geo_texts <- vars$valueTexts[[geo_row]]
geo_values <- vars$values[[geo_row]]

# Filter to commune level (texts starting with "......")
commune_mask <- startsWith(geo_texts, "......")
commune_texts <- geo_texts[commune_mask]
commune_codes <- geo_values[commune_mask]

# Build lookup: geo_label (the full text like "......Aarau") → BFS code
geo_lookup <- data.table(
  geo_label = commune_texts,
  bfs_nr = as.integer(commune_codes)
)
geo_lookup <- geo_lookup[!is.na(bfs_nr)]
cat("  Commune lookup table: ", nrow(geo_lookup), " entries\n")

# Match referendum data to BFS numbers
if ("bfs_nr" %in% names(ref_raw)) ref_raw[, bfs_nr := NULL]  # Remove old column if exists
ref_raw <- merge(ref_raw, geo_lookup, by = "geo_label", all.x = TRUE)

matched <- sum(!is.na(ref_raw$bfs_nr))
unmatched <- sum(is.na(ref_raw$bfs_nr))
cat("  Matched to BFS: ", matched, " (", round(matched / nrow(ref_raw) * 100, 1), "%)\n")
cat("  Unmatched: ", unmatched, "\n")

if (unmatched > 0) {
  cat("  Sample unmatched labels:\n")
  unmatched_labels <- unique(ref_raw[is.na(bfs_nr), geo_label])
  for (nm in head(unmatched_labels, 10)) cat("    ", nm, "\n")
}

# Drop unmatched (Ausland-CH, Anderes, Korrespondenzweg etc.)
ref_clean <- ref_raw[!is.na(bfs_nr)]
cat("  Clean referendum rows: ", nrow(ref_clean), "\n")

# =============================================================================
# STEP 3: Build merger treatment indicator
# =============================================================================

cat("\n=== Building merger treatment indicator ===\n")

# Get unique merger events with timing
merger_events <- unique(merger_xwalk[, .(dissolved_code, successor_code, merger_year)])

# Extract canton from snapshot using HistoricalCode linkage
# Parent field references HistoricalCode (not BfsCode)
# Level 1 = canton, Level 2 = district, Level 3 = commune
cantons_snap <- snapshot[Level == 1, .(canton_hc = HistoricalCode, canton = ShortName)]
districts_snap <- snapshot[Level == 2, .(district_hc = HistoricalCode, canton_parent = Parent)]
communes_snap <- snapshot[Level == 3, .(bfs_nr = BfsCode, district_parent = Parent, name = Name)]

# Map district → canton (via HistoricalCode)
districts_snap <- merge(districts_snap, cantons_snap,
                        by.x = "canton_parent", by.y = "canton_hc", all.x = TRUE)
# Map commune → canton via district
communes_snap <- merge(communes_snap, districts_snap[, .(district_hc, canton)],
                       by.x = "district_parent", by.y = "district_hc", all.x = TRUE)

cat("  Communes with canton mapping: ", sum(!is.na(communes_snap$canton)),
    " of ", nrow(communes_snap), "\n")

# Create set of dissolved municipalities and their merger years
dissolved_set <- merger_events[, .(bfs_nr = dissolved_code, merger_year)]
dissolved_set <- unique(dissolved_set)

# Also track successor municipalities (they were part of a merger too)
successor_set <- unique(merger_events[, .(bfs_nr = successor_code, merger_year)])
# Successors are "treated" in a different way — they absorbed others

# Create never-merged set (control municipalities)
all_bfs <- unique(ref_clean$bfs_nr)
ever_merged <- unique(c(dissolved_set$bfs_nr, successor_set$bfs_nr))
never_merged <- setdiff(all_bfs, ever_merged)
cat("  Ever merged (dissolved): ", nrow(dissolved_set), "\n")
cat("  Ever merged (successor): ", nrow(successor_set), "\n")
cat("  Never merged (controls): ", length(never_merged), "\n")

# =============================================================================
# STEP 4: Harmonize municipality panel using SMMT crosswalk
# =============================================================================

cat("\n=== Harmonizing municipality panel ===\n")

# Strategy: Map all historical municipality IDs to their 2024 successor
# For dissolved municipalities → use successor code
# For never-merged → use their own code
# For successors → use their own code (they continue to exist)

# Build full mapping: historical BFS → current BFS
id_map <- rbind(
  # Dissolved → successor
  merger_events[, .(historical_bfs = dissolved_code, current_bfs = successor_code,
                    merger_year)],
  # Successors → themselves
  data.table(historical_bfs = unique(successor_set$bfs_nr),
             current_bfs = unique(successor_set$bfs_nr),
             merger_year = NA_integer_),
  # Never-merged → themselves
  data.table(historical_bfs = never_merged,
             current_bfs = never_merged,
             merger_year = NA_integer_),
  fill = TRUE
)

# Some municipalities may have merged multiple times (chain mergers)
# Handle by finding the final successor
# For now, use the direct mapping (first-order)
id_map <- unique(id_map, by = c("historical_bfs", "current_bfs"))

# Add merger treatment to referendum data
ref_panel <- merge(ref_clean, id_map[, .(historical_bfs, current_bfs)],
                   by.x = "bfs_nr", by.y = "historical_bfs",
                   all.x = TRUE)

# For communes not in the id_map, current_bfs = bfs_nr
ref_panel[is.na(current_bfs), current_bfs := bfs_nr]

# Add treatment indicator: post = 1 if after merger
# Need merger year for each current_bfs
merger_years <- unique(dissolved_set[, .(bfs_nr, merger_year)])
# For the successor, use the merger year of the first merger
successor_years <- merger_events[, .(merger_year = min(merger_year)),
                                  by = .(bfs_nr = successor_code)]
all_merger_years <- rbind(
  dissolved_set[, .(bfs_nr, first_merger_year = merger_year)],
  successor_years[, .(bfs_nr, first_merger_year = merger_year)]
)
all_merger_years <- all_merger_years[, .(first_merger_year = min(first_merger_year)),
                                      by = bfs_nr]

# Map merger year to current_bfs (for the harmonized panel)
current_merger_years <- all_merger_years[bfs_nr %in% unique(ref_panel$current_bfs)]

ref_panel <- merge(ref_panel, current_merger_years,
                   by.x = "current_bfs", by.y = "bfs_nr",
                   all.x = TRUE)

# Treatment: ever_merged indicator + post indicator
ref_panel[, ever_merged := !is.na(first_merger_year)]
ref_panel[, post_merger := ever_merged & vote_year >= first_merger_year]
ref_panel[, rel_year := vote_year - first_merger_year]

cat("  Panel rows: ", nrow(ref_panel), "\n")
cat("  Unique current_bfs: ", uniqueN(ref_panel$current_bfs), "\n")
cat("  Ever merged: ", sum(ref_panel$ever_merged), " obs\n")
cat("  Post merger: ", sum(ref_panel$post_merger), " obs\n")
cat("  Pre merger: ", sum(ref_panel$ever_merged & !ref_panel$post_merger), " obs\n")

# =============================================================================
# STEP 5: Aggregate to current_bfs × vote_date level
# =============================================================================

cat("\n=== Aggregating to harmonized panel ===\n")

# For pre-merger periods, multiple historical municipalities map to the same
# current_bfs. Aggregate turnout as weighted average (by eligible voters).
panel <- ref_panel[, .(
  turnout_pct = weighted.mean(turnout_pct, eligible_voters, na.rm = TRUE),
  eligible_voters = sum(eligible_voters, na.rm = TRUE),
  n_components = .N,
  post_merger = first(post_merger),
  ever_merged = first(ever_merged),
  first_merger_year = first(first_merger_year),
  rel_year = first(rel_year)
), by = .(current_bfs, vote_date, vote_year)]

cat("  Aggregated panel: ", nrow(panel), " obs\n")
cat("  Unique municipalities: ", uniqueN(panel$current_bfs), "\n")
cat("  Unique vote dates: ", uniqueN(panel$vote_date), "\n")

# Add canton code from commune→canton mapping built in Step 3
canton_map <- communes_snap[!is.na(canton), .(bfs_nr, canton)]
canton_map[, bfs_nr := as.integer(bfs_nr)]

panel <- merge(panel, canton_map, by.x = "current_bfs", by.y = "bfs_nr",
               all.x = TRUE)

# =============================================================================
# STEP 6: Add population
# =============================================================================

cat("\n=== Adding population data ===\n")

# Population is annual (2010-2024). Match to nearest year.
pop_dt[, bfs_nr := as.integer(bfs_nr)]
pop_dt[, year := as.integer(year)]

# For each vote_year, find the closest population year
panel[, pop_year := pmin(pmax(vote_year, min(pop_dt$year)), max(pop_dt$year))]
panel <- merge(panel, pop_dt[, .(bfs_nr, year, population)],
               by.x = c("current_bfs", "pop_year"),
               by.y = c("bfs_nr", "year"),
               all.x = TRUE)
panel[, pop_year := NULL]

cat("  Population matched: ", sum(!is.na(panel$population)), " of ", nrow(panel), "\n")

# =============================================================================
# STEP 7: Create Callaway-Sant'Anna variables
# =============================================================================

cat("\n=== Creating CS-DiD variables ===\n")

# CS-DiD needs:
# - g: first treatment year (or 0 for never-treated)
# - t: time period (year)
# - y: outcome
# - id: unit identifier

# Convert vote_date to a year-quarter numeric for time period
panel[, vote_yq := vote_year + (quarter(vote_date) - 1) / 4]

# For CS-DiD, use annual aggregation (average turnout per year per municipality)
annual_panel <- panel[, .(
  turnout_pct = mean(turnout_pct, na.rm = TRUE),
  eligible_voters = mean(eligible_voters, na.rm = TRUE),
  n_votes = .N,
  population = mean(population, na.rm = TRUE)
), by = .(current_bfs, vote_year, canton, ever_merged, first_merger_year)]

# CS-DiD group variable (g): first_merger_year for treated, 0 for never-treated
annual_panel[, g := fifelse(ever_merged, first_merger_year, 0L)]
annual_panel[is.na(g), g := 0L]

cat("  Annual panel: ", nrow(annual_panel), " obs\n")
cat("  Unique units: ", uniqueN(annual_panel$current_bfs), "\n")
cat("  Treatment groups:\n")
print(table(annual_panel[, .(ever_merged = ever_merged)]))
cat("\n  Cohort distribution (g):\n")
g_dist <- annual_panel[g > 0, .N, by = g][order(g)]
print(g_dist)

# =============================================================================
# STEP 8: Save analysis datasets
# =============================================================================

cat("\n=== Saving analysis datasets ===\n")
fwrite(panel, file.path(DATA_DIR, "panel_vote.csv"))
fwrite(annual_panel, file.path(DATA_DIR, "panel_annual.csv"))
fwrite(id_map, file.path(DATA_DIR, "id_map.csv"))

cat("  Saved panel_vote.csv (", nrow(panel), " obs)\n")
cat("  Saved panel_annual.csv (", nrow(annual_panel), " obs)\n")

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("  Mean turnout (all): ", round(mean(panel$turnout_pct, na.rm = TRUE), 1), "%\n")
cat("  Mean turnout (control): ",
    round(mean(panel[!ever_merged, turnout_pct], na.rm = TRUE), 1), "%\n")
cat("  Mean turnout (treated, pre): ",
    round(mean(panel[ever_merged & !post_merger, turnout_pct], na.rm = TRUE), 1), "%\n")
cat("  Mean turnout (treated, post): ",
    round(mean(panel[post_merger == TRUE, turnout_pct], na.rm = TRUE), 1), "%\n")
cat("  Time range: ", min(panel$vote_year), "-", max(panel$vote_year), "\n")
