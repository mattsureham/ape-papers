# 04_robustness.R — Robustness checks for apep_0770
# Testing the null: maternity closures and populist voting

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))
closures <- readRDS(file.path(data_dir, "closures.rds"))

# Drop DOM-TOM
panel <- panel[!grepl("^97", dep_code)]
panel[, dep := dep_code]
panel[, log_pop := log(pmax(pop, 1))]

# =============================================================================
# 1. Alternative treatment: proximity to closure (within 20km)
# =============================================================================
cat("=== 1. Proximity-based treatment ===\n")

# Instead of distance change, use binary: any maternity closed within 20km
# between 2013 and the election year

# Need commune-level coordinates for closures
communes_geo <- fread(file.path(data_dir, "communes_france.csv"), encoding = "UTF-8")
communes_geo[, commune_code := as.character(code_insee)]
communes_geo[, lat := as.numeric(latitude_centre)]
communes_geo[, lon := as.numeric(longitude_centre)]
communes_geo <- communes_geo[!is.na(lat) & !is.na(lon)]

# Merge closure locations with coordinates
closures[, commune_code := as.character(commune_code)]
closure_locs <- merge(closures, communes_geo[, .(commune_code, lat, lon)],
                       by = "commune_code", all.x = TRUE)
closure_locs <- closure_locs[!is.na(lat)]

cat("Closures with coordinates:", nrow(closure_locs), "\n")

# For each commune in panel, check if any closure happened within 20km before each election
# Panel already has lat/lon from merge in 02_clean_data
# Just ensure they exist
panel_geo <- copy(panel)
if (!"lat" %in% names(panel_geo) || all(is.na(panel_geo$lat))) {
  panel_geo <- merge(panel_geo[, !c("lat", "lon"), with = FALSE],
                      communes_geo[, .(commune_code, lat, lon)],
                      by = "commune_code", all.x = TRUE)
}

# For each election year, find closures that happened before it
for (ey in c(2017L, 2022L)) {
  closures_before <- closure_locs[closure_year <= ey & closure_year > 2013L]
  if (nrow(closures_before) == 0) next

  col_name <- paste0("closure_within_20km_", ey)
  mat_coords <- as.matrix(closures_before[, .(lon, lat)])

  panel_geo[election_year == ey, (col_name) := {
    comm_coords <- cbind(lon, lat)
    sapply(seq_len(.N), function(i) {
      dists <- geosphere::distHaversine(comm_coords[i, , drop = FALSE], mat_coords)
      min(dists) / 1000
    })
  }]
}

# Binary treatment: any closure within 20km
panel_geo[, nearby_closure_20km := fifelse(
  (election_year == 2017L & !is.na(closure_within_20km_2017) & closure_within_20km_2017 < 20) |
  (election_year == 2022L & !is.na(closure_within_20km_2022) & closure_within_20km_2022 < 20),
  1L, 0L
)]

# Pre-treatment periods get 0
panel_geo[election_year < 2017L, nearby_closure_20km := 0L]

r1 <- feols(fn_rn_share ~ nearby_closure_20km |
              commune_code + election_year,
            data = panel_geo, cluster = ~dep)
cat("Proximity treatment (within 20km):\n")
summary(r1)


# =============================================================================
# 2. Heterogeneity by commune size
# =============================================================================
cat("\n=== 2. Heterogeneity by commune size ===\n")

panel[, small_commune := fifelse(pop < 2000, 1L, 0L)]

# Small communes (<2000 pop)
r2a <- feols(fn_rn_share ~ dist_nearest_mat_km |
               commune_code + election_year,
             data = panel[small_commune == 1L],
             cluster = ~dep)
cat("Small communes (<2000 pop):\n")
summary(r2a)

# Large communes (>=2000 pop)
r2b <- feols(fn_rn_share ~ dist_nearest_mat_km |
               commune_code + election_year,
             data = panel[small_commune == 0L],
             cluster = ~dep)
cat("Large communes (>=2000 pop):\n")
summary(r2b)


# =============================================================================
# 3. Placebo: Left-populist (LFI/Mélenchon) vote share
# =============================================================================
cat("\n=== 3. Placebo — Left-populist vote share ===\n")

elec <- arrow::read_parquet(file.path(data_dir, "candidats_results.parquet"))
setDT(elec)

pres <- elec[grepl("_pres_t1$", id_election)]
pres[, election_year := as.integer(str_extract(id_election, "\\d{4}"))]
pres[, commune_code := str_pad(as.character(code_commune), 5, pad = "0")]

# Left populist candidates:
# 2002: none (Jospin was mainstream); 2007: none clear
# 2012: Mélenchon (Front de Gauche, ~11%)
# 2017: Mélenchon (La France Insoumise, ~20%)
# 2022: Mélenchon (LFI/NUPES, ~22%)
pres[, is_lfi := grepl("MELENCHON|M.LENCHON", nom, ignore.case = TRUE) |
                 grepl("^FG$|^FI$|^LFI$", nuance, ignore.case = TRUE)]

commune_lfi <- pres[, .(
  lfi_votes = sum(voix[is_lfi], na.rm = TRUE),
  total_votes = sum(voix, na.rm = TRUE)
), by = .(commune_code, election_year)]
commune_lfi[, lfi_share := lfi_votes / total_votes * 100]

# Merge with panel
panel_lfi <- merge(panel, commune_lfi[, .(commune_code, election_year, lfi_share)],
                    by = c("commune_code", "election_year"), all.x = TRUE)

# Restrict to 2012-2022 (Mélenchon only ran these years)
r3 <- feols(lfi_share ~ dist_nearest_mat_km |
              commune_code + election_year,
            data = panel_lfi[election_year >= 2012L],
            cluster = ~dep)
cat("Placebo — LFI/Mélenchon share:\n")
summary(r3)


# =============================================================================
# 4. Placebo: Turnout
# =============================================================================
cat("\n=== 4. Placebo — Turnout ===\n")

gen <- arrow::read_parquet(file.path(data_dir, "general_results.parquet"))
setDT(gen)
gen_pres <- gen[grepl("_pres_t1$", id_election)]
gen_pres[, election_year := as.integer(str_extract(id_election, "\\d{4}"))]
gen_pres[, commune_code := str_pad(as.character(code_commune), 5, pad = "0")]

# Aggregate to commune level
commune_turnout <- gen_pres[, .(
  inscrits = sum(inscrits, na.rm = TRUE),
  votants = sum(votants, na.rm = TRUE),
  abstentions = sum(abstentions, na.rm = TRUE)
), by = .(commune_code, election_year)]
commune_turnout[, turnout := votants / inscrits * 100]

panel_turnout <- merge(panel, commune_turnout[, .(commune_code, election_year, turnout)],
                        by = c("commune_code", "election_year"), all.x = TRUE)

r4 <- feols(turnout ~ dist_nearest_mat_km |
              commune_code + election_year,
            data = panel_turnout,
            cluster = ~dep)
cat("Placebo — Turnout:\n")
summary(r4)


# =============================================================================
# 5. Robustness: Drop Île-de-France
# =============================================================================
cat("\n=== 5. Dropping Île-de-France ===\n")

r5 <- feols(fn_rn_share ~ dist_nearest_mat_km |
              commune_code + election_year,
            data = panel[!grepl("^(75|77|78|91|92|93|94|95)", dep_code)],
            cluster = ~dep)
cat("Excluding Île-de-France:\n")
summary(r5)


# =============================================================================
# 6. Continuous treatment intensity: distance CHANGE
# =============================================================================
cat("\n=== 6. Continuous distance change ===\n")

# Distance change from baseline (2013 maternity landscape)
panel[, dist_change_from_baseline := dist_nearest_mat_km - dist_nearest_mat_km[election_year == min(election_year)],
      by = commune_code]

r6 <- feols(fn_rn_share ~ dist_change_from_baseline |
              commune_code + election_year,
            data = panel,
            cluster = ~dep)
cat("Distance change from baseline:\n")
summary(r6)


# =============================================================================
# Save all robustness results
# =============================================================================
rob_results <- list(
  proximity_20km = r1,
  small_communes = r2a,
  large_communes = r2b,
  placebo_lfi = r3,
  placebo_turnout = r4,
  excl_idf = r5,
  dist_change = r6
)
saveRDS(rob_results, file.path(data_dir, "robustness_models.rds"))
cat("\nAll robustness models saved.\n")
