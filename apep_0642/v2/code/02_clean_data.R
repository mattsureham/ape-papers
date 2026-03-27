## 02_clean_data.R — Clean, link, and construct analysis panel
## APEP-0642 v2: Regulatory Whack-a-Mole

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
# 7b. Clean and merge CWA (NPDES) inspection data [V2 NEW]
# ============================================================
cat("\n=== Processing CWA (NPDES) inspections ===\n")

npdes_dir <- file.path(data_dir, "npdes")
npdes_insp_file <- list.files(npdes_dir, pattern = "NPDES_INSPECTIONS", full.names = TRUE, recursive = TRUE)

if (length(npdes_insp_file) >= 1) {
  npdes_insp_file <- npdes_insp_file[1]
  cat("Reading CWA inspections from:", basename(npdes_insp_file), "\n")
  npdes_insp <- fread(npdes_insp_file, showProgress = FALSE)
  cat("  Raw CWA inspections:", nrow(npdes_insp), "\n")
  cat("  Columns:", paste(head(names(npdes_insp), 10), collapse = ", "), "...\n")

  # Parse date column (try common formats)
  date_col <- grep("DATE|date|Date", names(npdes_insp), value = TRUE)
  if (length(date_col) > 0) {
    date_col <- date_col[1]
    npdes_insp[, cwa_date := as.Date(get(date_col), format = "%m-%d-%Y")]
    if (sum(is.na(npdes_insp$cwa_date)) > nrow(npdes_insp) * 0.5) {
      npdes_insp[, cwa_date := as.Date(get(date_col), format = "%m/%d/%Y")]
    }
    if (sum(is.na(npdes_insp$cwa_date)) > nrow(npdes_insp) * 0.5) {
      npdes_insp[, cwa_date := as.Date(get(date_col))]
    }
  }
  npdes_insp[, cwa_year := year(cwa_date)]
  npdes_insp <- npdes_insp[cwa_year >= 2005 & cwa_year <= 2022]
  cat("  CWA inspections 2005-2022:", nrow(npdes_insp), "\n")

  # Link to FRS via REGISTRY_ID
  reg_col <- grep("REGISTRY", names(npdes_insp), value = TRUE)
  if (length(reg_col) > 0) {
    npdes_insp[, cwa_frs_id := trimws(as.character(get(reg_col[1])))]
  } else {
    # Try via NPDES facility file
    npdes_fac_file <- list.files(npdes_dir, pattern = "ICIS_FACILITIES|NPDES_FACILITIES", full.names = TRUE, recursive = TRUE)
    if (length(npdes_fac_file) >= 1) {
      cat("  Linking CWA via facility file...\n")
      npdes_fac <- fread(npdes_fac_file[1], showProgress = FALSE,
                         select = intersect(names(fread(npdes_fac_file[1], nrows = 0)),
                                            c("NPDES_ID", "EXTERNAL_PERMIT_NMBR", "REGISTRY_ID")))
      # Find ID column that links inspections to facilities
      link_col <- intersect(names(npdes_insp), names(npdes_fac))
      if (length(link_col) > 0) {
        npdes_insp <- merge(npdes_insp, npdes_fac[, c(link_col[1], "REGISTRY_ID"), with = FALSE],
                            by = link_col[1], all.x = TRUE)
        npdes_insp[, cwa_frs_id := trimws(as.character(REGISTRY_ID))]
      }
    }
  }

  if ("cwa_frs_id" %in% names(npdes_insp)) {
    # Aggregate to facility-year
    cwa_events <- npdes_insp[cwa_frs_id %in% matched_frs & !is.na(cwa_frs_id) & cwa_frs_id != "",
                             .(n_cwa_insp = .N),
                             by = .(frs_id = cwa_frs_id, YEAR = cwa_year)]
    cat("  CWA events (facility-years) in matched sample:", nrow(cwa_events), "\n")
    cat("  Unique CWA-inspected facilities:", uniqueN(cwa_events$frs_id), "\n")

    # Merge CWA events into panel
    panel <- merge(panel, cwa_events, by = c("frs_id", "YEAR"), all.x = TRUE)
    panel[is.na(n_cwa_insp), n_cwa_insp := 0L]
    panel[, cwa_inspected := as.integer(n_cwa_insp > 0)]

    # First CWA inspection year
    first_cwa <- cwa_events[, .(first_cwa_year = min(YEAR)), by = frs_id]
    panel <- merge(panel, first_cwa, by = "frs_id", all.x = TRUE)
    panel[, cwa_post := as.integer(!is.na(first_cwa_year) & YEAR >= first_cwa_year)]

    cat("  Facilities with any CWA inspection:", uniqueN(panel$frs_id[panel$cwa_inspected == 1]), "\n")

    # CWA-CAA overlap statistics
    overlap <- panel[!is.na(first_insp_year),
                     .(has_caa = 1, has_cwa = as.integer(any(cwa_inspected == 1))),
                     by = frs_id]
    cat("\n  === CWA-CAA Overlap ===\n")
    cat("  CAA-inspected facilities:", nrow(overlap), "\n")
    cat("  Also CWA-inspected:", sum(overlap$has_cwa), "(", round(mean(overlap$has_cwa)*100, 1), "%)\n")
  } else {
    cat("  WARNING: Could not link CWA inspections to FRS. Setting cwa_inspected = 0.\n")
    panel[, c("n_cwa_insp", "cwa_inspected", "first_cwa_year", "cwa_post") :=
            list(0L, 0L, NA_integer_, 0L)]
  }
} else {
  cat("  WARNING: NPDES inspection file not found. Setting cwa_inspected = 0.\n")
  panel[, c("n_cwa_insp", "cwa_inspected", "first_cwa_year", "cwa_post") :=
          list(0L, 0L, NA_integer_, 0L)]
}

# ============================================================
# 7c. Clean and merge RCRA inspection data [V2 NEW]
# ============================================================
cat("\n=== Processing RCRA inspections ===\n")

rcra_dir <- file.path(data_dir, "rcra")
rcra_insp_file <- list.files(rcra_dir, pattern = "EVALUATION|INSPECTION|CEI", full.names = TRUE,
                             recursive = TRUE, ignore.case = TRUE)

if (length(rcra_insp_file) >= 1) {
  rcra_insp_file <- rcra_insp_file[1]
  cat("Reading RCRA inspections from:", basename(rcra_insp_file), "\n")
  rcra_insp <- fread(rcra_insp_file, showProgress = FALSE)
  cat("  Raw RCRA records:", nrow(rcra_insp), "\n")

  # Parse date
  date_col <- grep("DATE|date|Date", names(rcra_insp), value = TRUE)
  if (length(date_col) > 0) {
    rcra_insp[, rcra_date := as.Date(get(date_col[1]), format = "%m-%d-%Y")]
    if (sum(is.na(rcra_insp$rcra_date)) > nrow(rcra_insp) * 0.5) {
      rcra_insp[, rcra_date := as.Date(get(date_col[1]), format = "%m/%d/%Y")]
    }
    if (sum(is.na(rcra_insp$rcra_date)) > nrow(rcra_insp) * 0.5) {
      rcra_insp[, rcra_date := as.Date(get(date_col[1]))]
    }
  }
  rcra_insp[, rcra_year := year(rcra_date)]
  rcra_insp <- rcra_insp[rcra_year >= 2005 & rcra_year <= 2022]

  # Link to FRS
  reg_col <- grep("REGISTRY", names(rcra_insp), value = TRUE)
  if (length(reg_col) > 0) {
    rcra_insp[, rcra_frs_id := trimws(as.character(get(reg_col[1])))]
  } else {
    # Try facility file for linkage
    rcra_fac_file <- list.files(rcra_dir, pattern = "FACILITY|HANDLER", full.names = TRUE,
                                recursive = TRUE, ignore.case = TRUE)
    if (length(rcra_fac_file) >= 1) {
      rcra_fac <- fread(rcra_fac_file[1], showProgress = FALSE)
      rcra_reg <- grep("REGISTRY", names(rcra_fac), value = TRUE)
      rcra_link <- intersect(names(rcra_insp), names(rcra_fac))
      if (length(rcra_link) > 0 && length(rcra_reg) > 0) {
        rcra_insp <- merge(rcra_insp, rcra_fac[, c(rcra_link[1], rcra_reg[1]), with = FALSE],
                           by = rcra_link[1], all.x = TRUE)
        rcra_insp[, rcra_frs_id := trimws(as.character(get(rcra_reg[1])))]
      }
    }
  }

  if ("rcra_frs_id" %in% names(rcra_insp)) {
    rcra_events <- rcra_insp[rcra_frs_id %in% matched_frs & !is.na(rcra_frs_id) & rcra_frs_id != "",
                             .(n_rcra_insp = .N),
                             by = .(frs_id = rcra_frs_id, YEAR = rcra_year)]
    cat("  RCRA events (facility-years) in matched sample:", nrow(rcra_events), "\n")

    panel <- merge(panel, rcra_events, by = c("frs_id", "YEAR"), all.x = TRUE)
    panel[is.na(n_rcra_insp), n_rcra_insp := 0L]
    panel[, rcra_inspected := as.integer(n_rcra_insp > 0)]

    first_rcra <- rcra_events[, .(first_rcra_year = min(YEAR)), by = frs_id]
    panel <- merge(panel, first_rcra, by = "frs_id", all.x = TRUE)
    panel[, rcra_post := as.integer(!is.na(first_rcra_year) & YEAR >= first_rcra_year)]

    cat("  Facilities with any RCRA inspection:", uniqueN(panel$frs_id[panel$rcra_inspected == 1]), "\n")
  } else {
    cat("  WARNING: Could not link RCRA inspections. Setting rcra_inspected = 0.\n")
    panel[, c("n_rcra_insp", "rcra_inspected", "first_rcra_year", "rcra_post") :=
            list(0L, 0L, NA_integer_, 0L)]
  }
} else {
  cat("  WARNING: RCRA inspection file not found. Setting rcra_inspected = 0.\n")
  panel[, c("n_rcra_insp", "rcra_inspected", "first_rcra_year", "rcra_post") :=
          list(0L, 0L, NA_integer_, 0L)]
}

# Create fc_id early (needed by 7d extensive-margin diagnostics)
panel[, fc_id := paste(frs_id, cas, sep = "_")]

# ============================================================
# 7d. Extensive-margin indicators [V2 NEW]
# ============================================================
cat("\n=== Creating extensive-margin indicators ===\n")

panel[, any_land := as.integer(land_releases > 0)]
panel[, any_water := as.integer(water_releases > 0)]
panel[, any_potw := as.integer(potw > 0)]

# Pre-inspection switching capacity: did facility ever release to land before first CAA inspection?
panel[, pre_land_ever := as.integer(any(land_releases[YEAR < first_insp_year] > 0)),
      by = .(frs_id, cas)]
panel[is.na(pre_land_ever), pre_land_ever := 0L]

cat("Pre-inspection land release rates:\n")
cat("  Facility-chemicals with any pre-inspection land release:",
    uniqueN(panel$fc_id[panel$pre_land_ever == 1]), "\n")
cat("  Facility-chemicals without:",
    uniqueN(panel$fc_id[panel$pre_land_ever == 0]), "\n")

# ============================================================
# 7e. Cohort variable for Callaway-Sant'Anna [V2 NEW]
# ============================================================
panel[, cohort_year := fifelse(is.na(first_insp_year), 0L, as.integer(first_insp_year))]

# Repeat inspection frequency
repeat_insp <- insp_events[, .(n_insp_years = .N), by = registry_id]
cat("\nRepeat inspection statistics:\n")
cat("  Facilities with 1 inspection year:", sum(repeat_insp$n_insp_years == 1), "\n")
cat("  Facilities with 2+ inspection years:", sum(repeat_insp$n_insp_years >= 2), "\n")
cat("  Facilities with 5+ inspection years:", sum(repeat_insp$n_insp_years >= 5), "\n")

# ============================================================
# 8. Reshape to long by medium (for triple-diff)
# ============================================================
cat("\n=== Reshaping to long by medium ===\n")

panel[, fc_id := paste(frs_id, cas, sep = "_")]

panel_long <- melt(panel,
                   id.vars = c("frs_id", "fc_id", "YEAR", "CHEMICAL", "cas",
                               "caa_chemical", "naics", "ST",
                               "inspected", "first_insp_year", "event_time",
                               "total_releases",
                               "n_cwa_insp", "cwa_inspected", "first_cwa_year", "cwa_post",
                               "n_rcra_insp", "rcra_inspected", "first_rcra_year", "rcra_post",
                               "any_land", "any_water", "any_potw",
                               "pre_land_ever", "cohort_year"),
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
