## 02_clean_data.R — Clean, link, and construct analysis panel
## APEP-0642: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Clean ICIS-Air inspections
# ============================================================
cat("=== Cleaning ICIS-Air inspections ===\n")

inspections <- fread(file.path(data_dir, "icis_air/ICIS-AIR_FCES_PCES.csv"),
                     showProgress = FALSE)

# FCE On-Site = "FOO" in COMP_MONITOR_TYPE_CODE
cat("Compliance monitor types:\n")
print(table(inspections$COMP_MONITOR_TYPE_CODE))

inspections <- inspections[COMP_MONITOR_TYPE_CODE == "FOO"]
cat("FCE On-Site inspections:", nrow(inspections), "\n")

# Parse inspection date (format: MM-DD-YYYY)
inspections[, insp_date := as.Date(ACTUAL_END_DATE, format = "%m-%d-%Y")]
inspections[, insp_year := year(insp_date)]
cat("Date parse success:", sum(!is.na(inspections$insp_year)), "/", nrow(inspections), "\n")
cat("Inspection year range:", range(inspections$insp_year, na.rm = TRUE), "\n")

# Keep 2005-2022 (matching TRI window)
inspections <- inspections[insp_year >= 2005 & insp_year <= 2022]
cat("FCE inspections 2005-2022:", nrow(inspections), "\n")

# ============================================================
# 2. Read facilities (for REGISTRY_ID linkage)
# ============================================================
cat("\n=== Reading ICIS-Air facilities ===\n")
facilities <- fread(file.path(data_dir, "icis_air/ICIS-AIR_FACILITIES.csv"),
                    showProgress = FALSE,
                    select = c("PGM_SYS_ID", "REGISTRY_ID", "STATE", "NAICS_CODES"))
cat("Facilities:", nrow(facilities), "\n")
cat("With REGISTRY_ID:", sum(!is.na(facilities$REGISTRY_ID) & facilities$REGISTRY_ID != ""), "\n")

# Merge inspection with facility to get REGISTRY_ID
inspections <- merge(inspections, facilities, by = "PGM_SYS_ID", all.x = TRUE)
cat("Inspections with REGISTRY_ID:", sum(!is.na(inspections$REGISTRY_ID) & inspections$REGISTRY_ID != ""), "\n")

# ============================================================
# 3. Read and stack TRI data (column names have number prefixes)
# ============================================================
cat("\n=== Reading TRI data ===\n")

tri_files <- list.files(file.path(data_dir, "tri"), pattern = "tri_\\d{4}_us\\.csv$",
                        full.names = TRUE)
cat("TRI files to read:", length(tri_files), "\n")

tri_list <- lapply(tri_files, function(f) {
  cat("  Reading:", basename(f), "...\n")
  dt <- fread(f, showProgress = FALSE)
  # Strip numeric prefixes from column names: "1. YEAR" -> "YEAR"
  old_names <- names(dt)
  new_names <- gsub("^\\d+\\.\\s*", "", old_names)
  setnames(dt, old_names, new_names)
  # Select relevant columns
  keep_cols <- c("YEAR", "TRIFD", "FRS ID", "FACILITY NAME", "ST", "COUNTY",
                 "PRIMARY NAICS", "CHEMICAL", "CAS#", "CLEAN AIR ACT CHEMICAL",
                 "CLASSIFICATION", "CARCINOGEN", "UNIT OF MEASURE",
                 "5.1 - FUGITIVE AIR", "5.2 - STACK AIR", "5.3 - WATER",
                 "5.5.1 - LANDFILLS", "5.5.2 - LAND TREATMENT",
                 "5.5.3 - SURFACE IMPNDMNT", "5.5.4 - OTHER DISPOSAL",
                 "ON-SITE RELEASE TOTAL",
                 "6.1 - POTW - TRNS RLSE",
                 "OFF-SITE RELEASE TOTAL", "TOTAL RELEASES")
  # Keep only columns that exist
  keep_cols <- intersect(keep_cols, names(dt))
  dt[, ..keep_cols]
})

tri <- rbindlist(tri_list, fill = TRUE)
cat("Total TRI records:", nrow(tri), "\n")
cat("Unique facilities (TRIFD):", uniqueN(tri$TRIFD), "\n")
cat("Unique chemicals:", uniqueN(tri$CHEMICAL), "\n")
cat("Year range:", range(tri$YEAR), "\n")

# Clean column names for R
setnames(tri,
         old = c("FRS ID", "CAS#", "CLEAN AIR ACT CHEMICAL",
                 "PRIMARY NAICS", "FACILITY NAME",
                 "5.1 - FUGITIVE AIR", "5.2 - STACK AIR", "5.3 - WATER",
                 "5.5.1 - LANDFILLS", "5.5.2 - LAND TREATMENT",
                 "5.5.3 - SURFACE IMPNDMNT", "5.5.4 - OTHER DISPOSAL",
                 "ON-SITE RELEASE TOTAL",
                 "6.1 - POTW - TRNS RLSE",
                 "OFF-SITE RELEASE TOTAL", "TOTAL RELEASES",
                 "UNIT OF MEASURE"),
         new = c("frs_id", "cas", "caa_chemical",
                 "naics", "facility_name",
                 "fugitive_air", "stack_air", "water",
                 "landfills", "land_treatment",
                 "surface_impound", "other_disposal",
                 "onsite_release_total",
                 "potw_transfers",
                 "offsite_release_total", "total_releases",
                 "unit_of_measure"),
         skip_absent = TRUE)

# Convert release quantities to numeric
release_cols <- c("fugitive_air", "stack_air", "water", "landfills",
                  "land_treatment", "surface_impound", "other_disposal",
                  "onsite_release_total", "potw_transfers",
                  "offsite_release_total", "total_releases")

for (col in release_cols) {
  if (col %in% names(tri)) tri[, (col) := as.numeric(get(col))]
}

# Create aggregate medium categories
tri[, air_releases := fifelse(is.na(fugitive_air), 0, fugitive_air) +
                      fifelse(is.na(stack_air), 0, stack_air)]
tri[, water_releases := fifelse(is.na(water), 0, water)]
tri[, land_releases := fifelse(is.na(landfills), 0, landfills) +
                       fifelse(is.na(land_treatment), 0, land_treatment) +
                       fifelse(is.na(surface_impound), 0, surface_impound) +
                       fifelse(is.na(other_disposal), 0, other_disposal)]
tri[, potw := fifelse(is.na(potw_transfers), 0, potw_transfers)]

cat("\nCAA chemical flag distribution:\n")
print(table(tri$caa_chemical, useNA = "ifany"))

# Keep only pounds (most common unit, for comparability)
cat("\nUnit of measure:\n")
print(table(tri$unit_of_measure))
tri <- tri[unit_of_measure == "Pounds"]
cat("After keeping only pounds:", nrow(tri), "\n")

# ============================================================
# 4. Link TRI to ICIS-Air via FRS ID / REGISTRY_ID
# ============================================================
cat("\n=== Linking TRI to ICIS-Air ===\n")

tri[, frs_id := trimws(as.character(frs_id))]
facilities[, REGISTRY_ID := trimws(as.character(REGISTRY_ID))]

tri_frs <- unique(tri$frs_id[tri$frs_id != "" & !is.na(tri$frs_id)])
icis_frs <- unique(facilities$REGISTRY_ID[facilities$REGISTRY_ID != "" & !is.na(facilities$REGISTRY_ID)])

matched_frs <- intersect(tri_frs, icis_frs)
cat("TRI facilities with FRS ID:", length(tri_frs), "\n")
cat("ICIS-Air facilities with REGISTRY_ID:", length(icis_frs), "\n")
cat("Matched facilities:", length(matched_frs), "\n")
cat("Match rate (TRI):", round(length(matched_frs) / length(tri_frs) * 100, 1), "%\n")

tri_matched <- tri[frs_id %in% matched_frs]
cat("TRI records in matched facilities:", nrow(tri_matched), "\n")

# ============================================================
# 5. Identify treatment events: FCE inspections per facility-year
# ============================================================
cat("\n=== Identifying treatment events ===\n")

inspections[, registry_id := trimws(as.character(REGISTRY_ID))]
insp_events <- inspections[registry_id %in% matched_frs,
                           .(n_inspections = .N),
                           by = .(registry_id, insp_year)]

cat("Inspection events (facility-years):", nrow(insp_events), "\n")
cat("Unique facilities inspected:", uniqueN(insp_events$registry_id), "\n")
cat("Inspections per year:\n")
print(insp_events[, .(n_facilities = .N, total_insp = sum(n_inspections)), by = insp_year][order(insp_year)])

# ============================================================
# 6. Construct analysis panel: facility x chemical x year
# ============================================================
cat("\n=== Constructing analysis panel ===\n")

panel <- tri_matched[, .(frs_id, YEAR, CHEMICAL, cas, caa_chemical,
                         air_releases, water_releases, land_releases, potw,
                         total_releases = fifelse(is.na(total_releases), 0, total_releases),
                         naics, ST)]

# Merge inspection events
panel <- merge(panel,
               insp_events[, .(frs_id = registry_id, YEAR = insp_year, inspected = 1L)],
               by = c("frs_id", "YEAR"),
               all.x = TRUE)
panel[is.na(inspected), inspected := 0L]

cat("Panel rows:", nrow(panel), "\n")
cat("With inspection:", sum(panel$inspected == 1), "\n")
cat("Without inspection:", sum(panel$inspected == 0), "\n")

# ============================================================
# 7. Event-time relative to first inspection
# ============================================================
first_insp <- insp_events[, .(first_insp_year = min(insp_year)), by = registry_id]
setnames(first_insp, "registry_id", "frs_id")

panel <- merge(panel, first_insp, by = "frs_id", all.x = TRUE)
panel[, event_time := YEAR - first_insp_year]

cat("Facilities with inspection:", uniqueN(panel$frs_id[!is.na(panel$first_insp_year)]), "\n")
cat("Facilities without inspection:", uniqueN(panel$frs_id[is.na(panel$first_insp_year)]), "\n")

# ============================================================
# 8. Reshape to long by medium (for triple-diff)
# ============================================================
cat("\n=== Reshaping to long by medium ===\n")

panel[, fc_id := paste(frs_id, cas, sep = "_")]

panel_long <- melt(panel,
                   id.vars = c("frs_id", "fc_id", "YEAR", "CHEMICAL", "cas",
                               "caa_chemical", "naics", "ST",
                               "inspected", "first_insp_year", "event_time",
                               "total_releases"),
                   measure.vars = c("air_releases", "water_releases",
                                    "land_releases", "potw"),
                   variable.name = "medium",
                   value.name = "releases")

panel_long[, is_air := as.integer(medium == "air_releases")]
panel_long[, medium_cat := fcase(
  medium == "air_releases", "Air",
  medium == "water_releases", "Water",
  medium == "land_releases", "Land",
  medium == "potw", "POTW"
)]

panel_long[, post := as.integer(!is.na(first_insp_year) & YEAR >= first_insp_year)]
panel_long[, post_air := post * is_air]
panel_long[, post_nonair := post * (1L - is_air)]

cat("Panel long rows:", nrow(panel_long), "\n")

# ============================================================
# 9. Analysis sample: balanced window around first inspection
# ============================================================
cat("\n=== Creating analysis sample ===\n")

# Keep event window ±5, require ≥2 pre and ≥2 post years
panel_long[, pre_years := uniqueN(YEAR[YEAR < first_insp_year]), by = .(frs_id, cas)]
panel_long[, post_years := uniqueN(YEAR[YEAR >= first_insp_year]), by = .(frs_id, cas)]

analysis_sample <- panel_long[!is.na(first_insp_year) &
                                pre_years >= 2 &
                                post_years >= 2 &
                                event_time >= -5 & event_time <= 5]

cat("Analysis sample rows:", nrow(analysis_sample), "\n")
cat("Unique facilities:", uniqueN(analysis_sample$frs_id), "\n")
cat("Unique chemicals:", uniqueN(analysis_sample$cas), "\n")
cat("Unique facility-chemicals:", uniqueN(analysis_sample$fc_id), "\n")
cat("Years:", paste(range(analysis_sample$YEAR), collapse = "-"), "\n")

# Log-transform releases (add 1 to handle zeros)
analysis_sample[, log_releases := log(releases + 1)]

# ============================================================
# 10. Save cleaned data
# ============================================================
cat("\n=== Saving ===\n")

fwrite(analysis_sample, file.path(data_dir, "analysis_panel.csv"))
cat("Saved analysis_panel.csv:", nrow(analysis_sample), "rows\n")

fwrite(panel_long, file.path(data_dir, "panel_long_full.csv"))
cat("Saved panel_long_full.csv:", nrow(panel_long), "rows\n")

fwrite(insp_events, file.path(data_dir, "inspection_events.csv"))

cat("\n=== Summary statistics ===\n")
cat("Mean releases by medium (analysis sample):\n")
print(analysis_sample[, .(mean = round(mean(releases, na.rm = TRUE), 1),
                          median = round(median(releases, na.rm = TRUE), 1),
                          sd = round(sd(releases, na.rm = TRUE), 1),
                          pct_zero = round(mean(releases == 0) * 100, 1),
                          n = .N),
                      by = medium_cat][order(medium_cat)])

cat("\nMean releases by medium × pre/post:\n")
print(analysis_sample[, .(mean = round(mean(releases, na.rm = TRUE), 1), n = .N),
                      by = .(medium_cat, post)][order(medium_cat, post)])
