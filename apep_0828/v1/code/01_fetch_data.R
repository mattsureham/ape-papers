## 01_fetch_data.R — Fetch STATS19 collision data and construct smart motorway panel
## Source: DfT STATS19 via stats19 R package + government publications for section info

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) {
  script_dir <- dirname(normalizePath(script_path))
} else {
  script_dir <- getwd()
}
source(file.path(script_dir, "00_packages.R"))
paper_root <- dirname(script_dir)
setwd(paper_root)
cat(sprintf("Working directory: %s\n", getwd()))

cat("=== STEP 1: Construct smart motorway section database ===\n")

# Smart motorway sections from National Highways / DfT publications
# Sources:
#   - House of Commons Transport Committee (2021)
#   - National Highways Safety Evidence Stocktake (2023)
#   - DfT Written Ministerial Statement (April 2023)
# Types: ALR = All Lane Running; DHSR = Dynamic Hard Shoulder Running
# Coordinates: approximate OSGR (easting, northing) for start/end junctions

smart_sections <- data.table(
  section_id = 1:28,
  motorway = c(
    "M42", "M6",  "M1",  "M1",  "M62",
    "M4",  "M60", "M6",  "M1",
    "M25", "M1",  "M3",  "M6",
    "M1",  "M6",  "M20", "M23", "M27", "M6",
    "M1",  "M56", "M6",  "M5",  "M25",
    "M4",  "M3",  "M27", "M62"
  ),
  junctions = c(
    "J3a-J7",   "J4-J11a",  "J10-J13",  "J6a-J10",  "J25-J30",
    "J19-J20",  "J8-J18",   "J10a-J13", "J39-J42",
    "J23-J27",  "J32-J35a", "J2-J4a",   "J5-J8",
    "J13-J16",  "J2-J4",    "J3-J5",    "J8-J10",   "J4-J11",  "J13-J15",
    "J28-J31",  "J6-J8",    "J21a-J26", "J4a-J6",   "J5-J7",
    "J3-J12",   "J4a-J2",   "J11-J12",  "J20-J25"
  ),
  type = c(
    rep("DHSR", 9), rep("ALR", 19)
  ),
  open_year = c(
    2006, 2011, 2010, 2009, 2013,
    2011, 2012, 2012, 2013,
    2014, 2015, 2017, 2017,
    2017, 2017, 2017, 2017, 2017, 2017,
    2020, 2020, 2019, 2018, 2014,
    2022, 2017, 2022, 2022
  ),
  open_quarter = c(
    3, 2, 2, 4, 4,
    2, 2, 2, 4,
    2, 1, 1, 2,
    4, 1, 4, 4, 2, 1,
    1, 1, 2, 2, 4,
    1, 2, 3, 2
  ),
  length_miles = c(
    11.0, 17.5, 11.5, 12.0, 20.0,
    4.6, 12.0, 12.0, 14.0,
    10.0, 11.5, 13.0, 13.0,
    12.0, 7.0, 8.0, 5.5, 13.0, 8.0,
    12.0, 7.0, 16.0, 7.0, 6.0,
    20.0, 13.0, 5.0, 15.0
  ),
  # Approximate OSGR bounding boxes for each section
  # (northing_min, northing_max, easting_min, easting_max)
  # These define corridors along the motorway
  north_min = c(
    # DHSR
    217000, 286000, 226000, 204000, 414000,   # M42 J3a-7, M6 J4-11a, M1 J10-13, M1 J6a-10, M62 J25-30
    174000, 392000, 320000, 440000,            # M4 J19-20, M60 J8-18, M6 J10a-13, M1 J39-42
    # ALR
    180000, 375000, 118000, 290000,            # M25 J23-27, M1 J32-35a, M3 J2-4a, M6 J5-8
    246000, 275000, 120000, 115000, 101000, 340000,  # M1 J13-16, M6 J2-4, M20 J3-5, M23 J8-10, M27 J4-11, M6 J13-15
    368000, 360000, 370000, 157000, 175000,    # M1 J28-31, M56 J6-8, M6 J21a-26, M5 J4a-6, M25 J5-7
    141000, 128000, 108000, 425000             # M4 J3-12, M3 J4a-2, M27 J11-12, M62 J20-25
  ),
  north_max = c(
    227000, 340000, 246000, 226000, 430000,
    178000, 405000, 340000, 460000,
    195000, 400000, 140000, 310000,
    264000, 290000, 135000, 125000, 120000, 360000,
    395000, 370000, 400000, 175000, 185000,
    178000, 140000, 115000, 440000
  ),
  east_min = c(
    413000, 391000, 500000, 510000, 390000,
    366000, 385000, 392000, 432000,
    500000, 435000, 465000, 390000,
    486000, 385000, 570000, 530000, 435000, 387000,
    442000, 365000, 370000, 358000, 510000,
    475000, 445000, 435000, 400000
  ),
  east_max = c(
    425000, 415000, 520000, 525000, 420000,
    380000, 405000, 410000, 448000,
    530000, 450000, 490000, 410000,
    500000, 400000, 590000, 545000, 465000, 400000,
    458000, 380000, 395000, 370000, 530000,
    520000, 470000, 455000, 425000
  )
)

# Compute treatment date as fractional year
smart_sections[, treat_date := open_year + (open_quarter - 1) / 4]

cat(sprintf("  %d smart motorway sections constructed\n", nrow(smart_sections)))
cat(sprintf("  Types: ALR=%d, DHSR=%d\n",
            sum(smart_sections$type == "ALR"), sum(smart_sections$type == "DHSR")))

fwrite(smart_sections, "data/smart_sections.csv")

cat("\n=== STEP 2: Fetch STATS19 collision data ===\n")

# Download full historical collision file (1979-latest)
# year = 2019 triggers the full 1979-latest file; years >= 2022 get only that year
collisions_all <- get_stats19(year = 2019, type = "collision", ask = FALSE)
dt <- as.data.table(collisions_all)

# Identify year column (changed from accident_year to collision_year)
year_col <- intersect(c("collision_year", "accident_year"), names(dt))[1]
index_col <- intersect(c("collision_index", "accident_index"), names(dt))[1]
cat(sprintf("  Year column: %s, Index column: %s\n", year_col, index_col))

# Filter to 2000-2023 and motorway collisions
dt <- dt[get(year_col) >= 2000 & get(year_col) <= 2023]
mway <- dt[first_road_class == "Motorway"]
cat(sprintf("  All collisions 2000-2023: %d\n", nrow(dt)))
cat(sprintf("  Motorway collisions 2000-2023: %d\n", nrow(mway)))

if (nrow(mway) < 5000) {
  stop("FATAL: Too few motorway collisions retrieved.")
}

# Standardize columns
mway[, `:=`(
  year = get(year_col),
  idx = get(index_col),
  mway_num = as.integer(first_road_number),
  mway_name = paste0("M", first_road_number),
  easting = location_easting_osgr,
  northing = location_northing_osgr,
  severity = collision_severity
)]

# Add quarter
mway[, `:=`(
  dt_date = as.Date(date),
  qtr = quarter(as.Date(date)),
  year_qtr = year + (quarter(as.Date(date)) - 1) / 4
)]

cat(sprintf("  Year range: %d to %d\n", min(mway$year), max(mway$year)))
cat(sprintf("  Motorway numbers: %s\n",
            paste(head(sort(unique(mway$mway_name[!is.na(mway$mway_num)])), 15), collapse = ", ")))

# Check collision severity distribution
cat("\n  Severity distribution:\n")
print(table(mway$severity, useNA = "always"))

fwrite(mway, "data/stats19_motorway_collisions.csv")

cat("\n=== STEP 3: Fetch casualty data ===\n")
casualties_all <- get_stats19(year = 2019, type = "casualty", ask = FALSE)
cas_dt <- as.data.table(casualties_all)

# Match to motorway collisions
cas_idx_col <- intersect(c("collision_index", "accident_index"), names(cas_dt))[1]
cas_motorway <- cas_dt[get(cas_idx_col) %in% mway$idx]
cat(sprintf("  Motorway casualties: %d\n", nrow(cas_motorway)))

# Check severity
sev_col <- grep("casualty_severity", names(cas_motorway), value = TRUE)[1]
if (!is.na(sev_col)) {
  cat("  Casualty severity:\n")
  print(table(cas_motorway[[sev_col]]))
}

fwrite(cas_motorway, "data/stats19_motorway_casualties.csv")

cat("\n=== STEP 4: Assign collisions to smart sections ===\n")

# For each collision, check if it falls within any smart section's bounding box
# AND matches the motorway name
mway[, section_id := NA_integer_]

for (i in seq_len(nrow(smart_sections))) {
  sec <- smart_sections[i]
  mway_num <- as.integer(gsub("M", "", sec$motorway))

  mask <- mway$mway_num == mway_num &
    !is.na(mway$easting) & !is.na(mway$northing) &
    mway$northing >= sec$north_min & mway$northing <= sec$north_max &
    mway$easting >= sec$east_min & mway$easting <= sec$east_max

  n_matched <- sum(mask, na.rm = TRUE)
  if (n_matched > 0) {
    # If collision already assigned, keep the first (sections shouldn't overlap much)
    mway[mask & is.na(section_id), section_id := sec$section_id]
  }
  cat(sprintf("  Section %d (%s %s): %d collisions assigned\n",
              sec$section_id, sec$motorway, sec$junctions, n_matched))
}

# Summary
n_smart <- sum(!is.na(mway$section_id))
n_conv <- sum(is.na(mway$section_id))
cat(sprintf("\n  Collisions in smart sections: %d (%.1f%%)\n", n_smart, 100 * n_smart / nrow(mway)))
cat(sprintf("  Collisions in conventional sections: %d (%.1f%%)\n", n_conv, 100 * n_conv / nrow(mway)))

# Add treatment status
mway <- merge(mway, smart_sections[, .(section_id, type, open_year, open_quarter, treat_date)],
              by = "section_id", all.x = TRUE)
mway[, smart := fifelse(!is.na(section_id) & year_qtr >= treat_date, 1L, 0L)]

cat(sprintf("  Treated observations: %d\n", sum(mway$smart == 1)))
cat(sprintf("  Control observations: %d\n", sum(mway$smart == 0)))

fwrite(mway, "data/stats19_motorway_collisions_assigned.csv")

cat("\n=== Data fetch complete ===\n")
