# 02_clean_data.R — Construct commune × election panel
# Merge maternity closure events with election results and commune controls

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Clean DREES maternity data: identify closure events
# =============================================================================
cat("=== 1. Processing DREES maternity data ===\n")

mat <- fread(file.path(data_dir, "drees_maternites_raw.csv"), encoding = "UTF-8")
cat("Raw maternity records:", nrow(mat), "\n")
cat("Years covered:", paste(sort(unique(mat$annee)), collapse = ", "), "\n")

# Key columns: annee, com (commune code), acctot (total deliveries), nom_mat
# Standardize commune code to 5 digits
mat[, commune_code := str_pad(as.character(com), 5, pad = "0")]
mat[, year := as.integer(annee)]
mat[, deliveries := as.numeric(acctot)]

# Keep active maternities (non-zero deliveries)
mat_active <- mat[!is.na(deliveries) & deliveries > 0]
cat("Active maternity-year records:", nrow(mat_active), "\n")

# For each facility, find first and last active year
mat_active[, facility_id := paste0(commune_code, "_", str_sub(nom_mat, 1, 30))]
facility_life <- mat_active[, .(
  first_year = min(year),
  last_year = max(year),
  mean_deliveries = mean(deliveries, na.rm = TRUE),
  commune_code = commune_code[1],
  name = nom_mat[1]
), by = facility_id]

cat("Unique maternity facilities:", nrow(facility_life), "\n")
cat("Year range:", min(facility_life$first_year), "-", max(facility_life$last_year), "\n")

# Identify closures: facilities whose last_year < max observed year
# (i.e., they disappeared from the data before the latest observation)
max_year <- max(mat_active$year)
closures <- facility_life[last_year < max_year]
closures[, closure_year := last_year + 1L]  # Closed in year after last active

cat("Maternity closures identified:", nrow(closures), "\n")
cat("Closure years:\n")
print(closures[, .N, by = closure_year][order(closure_year)])

# Save closure events
fwrite(closures, file.path(data_dir, "maternity_closures.csv"))


# =============================================================================
# 2. Commune coordinates — load and prepare
# =============================================================================
cat("\n=== 2. Processing commune coordinates ===\n")

communes <- fread(file.path(data_dir, "communes_france.csv"), encoding = "UTF-8")
# Key columns: code_insee, latitude_centre, longitude_centre, population
communes[, commune_code := as.character(code_insee)]
communes[, lat := as.numeric(latitude_centre)]
communes[, lon := as.numeric(longitude_centre)]
communes[, pop := as.numeric(population)]

# Drop communes without coordinates
communes_geo <- communes[!is.na(lat) & !is.na(lon),
                         .(commune_code, nom_standard, lat, lon, pop,
                           dep_code, reg_code)]
cat("Communes with coordinates:", nrow(communes_geo), "\n")


# =============================================================================
# 3. Calculate distance from each commune to nearest maternity
# =============================================================================
cat("\n=== 3. Calculating commune-maternity distances ===\n")

# Get maternity locations (need coordinates for each maternity commune)
mat_communes <- unique(mat_active[, .(commune_code)])
mat_locations <- merge(mat_communes, communes_geo[, .(commune_code, lat, lon)],
                       by = "commune_code", all.x = TRUE)
mat_locations <- mat_locations[!is.na(lat)]

# For each year, identify which maternities are active
# Then for each commune, find distance to nearest active maternity
years_of_interest <- sort(unique(mat_active$year))

cat("Computing nearest-maternity distance for each commune-year...\n")
cat("(This uses commune centroids — an approximation)\n")

# Build active facility set by year
active_by_year <- mat_active[, .(commune_code = unique(commune_code)), by = year]

# Function to compute nearest maternity distance for a given year
compute_nearest <- function(yr, communes_geo, active_by_year, mat_locations) {
  active_comms <- active_by_year[year == yr, commune_code]
  active_locs <- mat_locations[commune_code %chin% active_comms]

  if (nrow(active_locs) == 0) return(NULL)

  # For each commune, find minimum distance to any active maternity commune
  # Use Haversine distance (geosphere) — batch processing
  comm_coords <- as.matrix(communes_geo[, .(lon, lat)])
  mat_coords <- as.matrix(active_locs[, .(lon, lat)])

  n_comm <- nrow(comm_coords)
  nearest_dist <- numeric(n_comm)

  # Process in chunks to balance speed and memory
  chunk_size <- 1000L
  n_chunks <- ceiling(n_comm / chunk_size)

  for (ch in seq_len(n_chunks)) {
    idx_start <- (ch - 1L) * chunk_size + 1L
    idx_end <- min(ch * chunk_size, n_comm)
    idx <- idx_start:idx_end

    # distm computes full distance matrix for a chunk
    dmat <- geosphere::distm(comm_coords[idx, , drop = FALSE], mat_coords,
                              fun = geosphere::distHaversine)
    nearest_dist[idx] <- apply(dmat, 1, min) / 1000  # km
  }

  data.table(
    commune_code = communes_geo$commune_code,
    year = yr,
    dist_nearest_mat_km = nearest_dist
  )
}

# DREES data starts 2013, so we compute distance for each DREES year
# Map elections: pre-2013 -> 2013 (baseline), 2014/2017 -> 2014/2017, 2019/2022 -> 2019/2022
# Elections: presidential (2002,2007,2012,2017,2022) + European (2004,2009,2014,2019)
election_to_mat <- data.table(
  election_year = c(2002L, 2004L, 2007L, 2009L, 2012L, 2014L, 2017L, 2019L, 2022L),
  mat_year = c(2013L, 2013L, 2013L, 2013L, 2013L, 2014L, 2017L, 2019L, 2022L)
)

# Only compute for unique mat_years needed
unique_mat_years <- unique(election_to_mat$mat_year)

dist_list <- list()
for (my in unique_mat_years) {
  cat(sprintf("  Computing distances for maternity year %d...\n", my))
  dist_list[[as.character(my)]] <- compute_nearest(my, communes_geo,
                                                    active_by_year, mat_locations)
}

# Expand to election years
dist_panel_list <- list()
for (i in seq_len(nrow(election_to_mat))) {
  ey <- election_to_mat$election_year[i]
  my <- election_to_mat$mat_year[i]
  d <- copy(dist_list[[as.character(my)]])
  if (!is.null(d)) {
    d[, election_year := ey]
    dist_panel_list[[as.character(ey)]] <- d
  }
}

dist_panel <- rbindlist(dist_panel_list, use.names = TRUE)
cat("Distance panel rows:", nrow(dist_panel), "\n")


# =============================================================================
# 4. Process election data
# =============================================================================
cat("\n=== 4. Processing election results ===\n")

elec <- arrow::read_parquet(file.path(data_dir, "candidats_results.parquet"))
setDT(elec)

cat("Total election records:", nrow(elec), "\n")
cat("Columns:", paste(names(elec), collapse = ", "), "\n")

# Identify presidential elections
# id_election format likely includes election type info
cat("Sample id_election values:\n")
print(head(unique(elec$id_election), 20))

# Filter to presidential 1st round AND European Parliament elections
# id_election format: YYYY_pres_t1 or YYYY_euro_t1
pres <- elec[grepl("_(pres|euro)_t1$", id_election)]

cat("Presidential + European 1st round records:", nrow(pres), "\n")

# Extract year from id_election
pres[, election_year := as.integer(str_extract(id_election, "\\d{4}"))]
cat("Presidential election years:", paste(sort(unique(pres$election_year)), collapse = ", "), "\n")

# Identify FN/RN candidates (Le Pen family + Marine Le Pen's party)
# Jean-Marie Le Pen: 2002, 2007
# Marine Le Pen: 2012, 2017, 2022
pres[, is_fn_rn := grepl("LE PEN|LEPEN", nom, ignore.case = TRUE) |
                   grepl("^FN$|^RN$|^EXD$", nuance, ignore.case = TRUE)]

cat("FN/RN candidate records:", sum(pres$is_fn_rn), "\n")

# Standardize commune code
pres[, commune_code := str_pad(as.character(code_commune), 5, pad = "0")]

# Aggregate to commune level: sum votes across bureaux de vote
commune_elec <- pres[, .(
  fn_rn_votes = sum(voix[is_fn_rn], na.rm = TRUE),
  total_votes = sum(voix, na.rm = TRUE)
), by = .(commune_code, election_year)]

commune_elec[, fn_rn_share := fn_rn_votes / total_votes * 100]

cat("Commune-election observations:", nrow(commune_elec), "\n")
cat("Mean FN/RN share by year:\n")
print(commune_elec[, .(mean_share = mean(fn_rn_share, na.rm = TRUE),
                        median_share = median(fn_rn_share, na.rm = TRUE),
                        n_communes = .N),
                    by = election_year][order(election_year)])


# =============================================================================
# 5. Also get general results for total expressed votes / turnout
# =============================================================================
cat("\n=== 5. Processing general election results ===\n")

gen <- arrow::read_parquet(file.path(data_dir, "general_results.parquet"))
setDT(gen)
cat("General result columns:", paste(names(gen), collapse = ", "), "\n")

# Filter to same presidential + European elections
gen_pres <- gen[grepl("_(pres|euro)_t1$", id_election)]

gen_pres[, election_year := as.integer(str_extract(id_election, "\\d{4}"))]
gen_pres[, commune_code := str_pad(as.character(code_commune), 5, pad = "0")]

# Check available columns for turnout
cat("General result sample columns:\n")
print(head(gen_pres, 3))


# =============================================================================
# 6. Merge everything into analysis panel
# =============================================================================
cat("\n=== 6. Building analysis panel ===\n")

# Merge elections with distances
panel <- merge(commune_elec, dist_panel[, .(commune_code, election_year, dist_nearest_mat_km)],
               by = c("commune_code", "election_year"), all.x = TRUE)

# Merge with commune characteristics
panel <- merge(panel, communes_geo[, .(commune_code, lat, lon, pop, dep_code, reg_code,
                                        nom_standard)],
               by = "commune_code", all.x = TRUE)

# Drop if missing key variables
panel <- panel[!is.na(fn_rn_share) & !is.na(dist_nearest_mat_km)]

cat("Final panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Communes:", uniqueN(panel$commune_code), "\n")
cat("Election years:", paste(sort(unique(panel$election_year)), collapse = ", "), "\n")

# Create treatment variables
# A commune is "treated" when its nearest maternity distance increases significantly
# First, identify the closure event for each commune
panel <- panel[order(commune_code, election_year)]

# For each commune, compute change in distance from first observation
panel[, first_dist := dist_nearest_mat_km[election_year == min(election_year)],
      by = commune_code]
panel[, dist_change := dist_nearest_mat_km - first_dist]

# Binary treatment: distance increased by >5km between any two periods
panel[, ever_affected := any(dist_change > 5), by = commune_code]

# Identify first election where distance jumped
panel[, dist_increased := dist_nearest_mat_km > shift(dist_nearest_mat_km, 1, type = "lag") + 2,
      by = commune_code]
panel[is.na(dist_increased), dist_increased := FALSE]

# Cohort assignment: first election year where distance meaningfully increased
panel[, first_treatment_year := fifelse(any(dist_increased),
                                         min(election_year[dist_increased]),
                                         0L),
      by = commune_code]
panel[first_treatment_year == 0L, first_treatment_year := NA_integer_]

cat("\nTreatment summary:\n")
cat("Ever-affected communes (>5km increase):",
    uniqueN(panel[ever_affected == TRUE, commune_code]), "\n")
cat("Never-affected communes:",
    uniqueN(panel[ever_affected == FALSE, commune_code]), "\n")
cat("\nFirst treatment year distribution:\n")
print(panel[!is.na(first_treatment_year),
            .(n_communes = uniqueN(commune_code)),
            by = first_treatment_year][order(first_treatment_year)])

cat("\nSummary statistics:\n")
print(panel[, .(
  mean_fn_rn = mean(fn_rn_share, na.rm = TRUE),
  sd_fn_rn = sd(fn_rn_share, na.rm = TRUE),
  mean_dist = mean(dist_nearest_mat_km, na.rm = TRUE),
  sd_dist = sd(dist_nearest_mat_km, na.rm = TRUE),
  mean_pop = mean(pop, na.rm = TRUE)
)])

# Save analysis panel
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")

# Save key objects for later scripts
saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(closures, file.path(data_dir, "closures.rds"))
cat("Done.\n")
