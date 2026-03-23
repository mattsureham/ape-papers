# 02_clean_data.R — Clean and merge RIETI merger data with MIC fiscal data
# Japan Heisei Municipal Merger Fiscal Cliff (apep_0836)

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Clean RIETI Converter: Extract merger status and dates
# ============================================================
cat("=== Processing RIETI Merger Data ===\n")

rieti <- readRDS(file.path(data_dir, "rieti_raw.rds"))

# Extract merger dates from Japanese text in note_merge_consol and note_merge_incorp
# Pattern: YYYY年MM月DD日
extract_date <- function(text) {
  if (is.na(text) || text == "") return(as.Date(NA))
  m <- regmatches(text, regexpr("(19[0-9]{2}|20[0-9]{2})年([0-9]{1,2})月([0-9]{1,2})日", text))
  if (length(m) == 0) return(as.Date(NA))
  parts <- as.integer(unlist(regmatches(m, gregexpr("[0-9]+", m))))
  as.Date(sprintf("%04d-%02d-%02d", parts[1], parts[2], parts[3]))
}

# Apply to both merger types
rieti[, merge_date_consol := as.Date(sapply(note_merge_consol, extract_date), origin = "1970-01-01")]
rieti[, merge_date_incorp := as.Date(sapply(note_merge_incorp, extract_date), origin = "1970-01-01")]

# Take earliest merger date
rieti[, merge_date := pmin(merge_date_consol, merge_date_incorp, na.rm = TRUE)]
rieti[, merge_fy := as.integer(format(merge_date, "%Y"))]

# Adjust: Japanese fiscal years run April-March
# A merger in Jan-March of year Y belongs to FY(Y-1)
rieti[month(merge_date) <= 3, merge_fy := merge_fy - 1L]

# Merger type
rieti[, merge_type := fcase(
  !is.na(merge_date_consol) & merge_date_consol == merge_date, "consolidation",
  !is.na(merge_date_incorp) & merge_date_incorp == merge_date, "incorporation",
  default = NA_character_
)]

# Focus on Heisei-era mergers (FY1999-FY2010)
rieti[, heisei_merger := merge_fy >= 1999 & merge_fy <= 2010 & !is.na(merge_fy)]

cat("Heisei merger year distribution:\n")
print(table(rieti$merge_fy[rieti$heisei_merger]))

# Map pre-merger codes to post-merger codes (2020 vintage)
# The key: multiple pre-merger rows map to the same post-merger municipality
# Post-merger code = id_muni2020 (or id_muni2010 for earlier vintages)
# RIETI codes are 4-5 digit integers without check digit — pad to 5 digits
rieti[, muni_code := as.character(id_muni2020)]
rieti[is.na(muni_code) | muni_code == "", muni_code := as.character(id_muni2010)]
rieti[, muni_code := sprintf("%05d", as.integer(muni_code))]

# Build municipality-level merger info (one row per post-merger municipality)
merger_info <- rieti[heisei_merger == TRUE, .(
  n_pre_merger_units = .N,
  merge_fy = min(merge_fy),
  merge_type = first(merge_type),
  merge_date = min(merge_date)
), by = muni_code]

# Grace period: 10 years full, then 5-year phase-out
# Phase-out starts at merge_fy + 10
# Phase-out schedule: Year 11: 10% cut, Year 12: 30%, Year 13: 50%, Year 14: 70%, Year 15: 90%
merger_info[, phaseout_start_fy := merge_fy + 10L]
merger_info[, phaseout_end_fy := merge_fy + 15L]

cat("\nPhase-out start year distribution:\n")
print(table(merger_info$phaseout_start_fy))

cat(sprintf("\nMerged municipalities: %d\n", nrow(merger_info)))
cat(sprintf("Phase-out range: FY%d to FY%d\n",
            min(merger_info$phaseout_start_fy), max(merger_info$phaseout_end_fy)))

# ============================================================
# 2. Clean MIC Fiscal Data
# ============================================================
cat("\n=== Processing MIC Fiscal Data ===\n")

mic_raw <- readRDS(file.path(data_dir, "mic_parsed_raw.rds"))

parse_mic_year <- function(dt, fy) {
  # Find the row where municipality codes start (6-digit numeric in col 1)
  col1 <- as.character(dt[[1]])
  data_start <- which(grepl("^[0-9]{5,6}$", trimws(col1)))[1]

  if (is.na(data_start)) {
    cat(sprintf("  FY%d: no data rows found\n", fy))
    return(NULL)
  }

  # Extract data rows
  data_rows <- dt[data_start:nrow(dt)]

  # The overview table columns (typical structure FY2011+):
  # Col 1: municipality code (団体コード)
  # Col 2: municipality name (団体名)
  # Col 3: registered population (住民基本台帳)
  # Col 4: [subcolumn - Japanese nationals only]
  # Col 5: census population
  # Col 6: census pop growth rate
  # Col 7-9: industrial structure (primary, secondary, tertiary %)
  # Col 10: area (km²)
  # Col 11: standard fiscal demand (基準財政需要額)
  # Col 12: standard fiscal revenue (基準財政収入額)
  # Col 13: standard fiscal scale (標準財政規模)
  # Col 14: [subcolumn]
  # Col 15: real balance ratio (実質収支比率)

  clean <- data.table(
    muni_code = trimws(as.character(data_rows[[1]])),
    muni_name = as.character(data_rows[[2]]),
    population = as.numeric(gsub("[^0-9.-]", "", as.character(data_rows[[3]]))),
    sfd = as.numeric(gsub("[^0-9.-]", "", as.character(data_rows[[11]]))),
    sfr = as.numeric(gsub("[^0-9.-]", "", as.character(data_rows[[12]]))),
    std_fiscal_scale = as.numeric(gsub("[^0-9.-]", "", as.character(data_rows[[13]]))),
    balance_ratio = as.numeric(gsub("[^0-9.-]", "", as.character(data_rows[[15]]))),
    fiscal_year = fy
  )

  # Remove rows with NA municipality codes
  clean <- clean[!is.na(muni_code) & muni_code != "" & nchar(muni_code) >= 5]

  # MIC codes are 5-6 digits (5-digit base + optional check digit)
  # Pad to 6 digits first, then strip check digit to get 5-digit base
  clean[nchar(muni_code) == 5, muni_code := paste0("0", muni_code)]
  # Now all 6 digits: PPMM0C or PPMMMC. Strip last digit (check digit)
  clean[, muni_code := substr(muni_code, 1, 5)]

  cat(sprintf("  FY%d: %d municipalities\n", fy, nrow(clean)))
  return(clean)
}

fiscal_list <- list()
for (fy_name in names(mic_raw)) {
  fy <- as.integer(fy_name)
  fiscal_list[[fy_name]] <- parse_mic_year(mic_raw[[fy_name]], fy)
}

fiscal <- rbindlist(fiscal_list[!sapply(fiscal_list, is.null)])
cat(sprintf("\nTotal fiscal observations: %d\n", nrow(fiscal)))
cat(sprintf("Unique municipalities: %d\n", uniqueN(fiscal$muni_code)))
cat(sprintf("Fiscal years: %d to %d\n", min(fiscal$fiscal_year), max(fiscal$fiscal_year)))

# ============================================================
# 3. Merge merger status with fiscal panel
# ============================================================
cat("\n=== Merging Datasets ===\n")

# Ensure muni_code types match
fiscal[, muni_code := as.character(muni_code)]
merger_info[, muni_code := as.character(muni_code)]

# Join merger info
panel <- merge(fiscal, merger_info, by = "muni_code", all.x = TRUE)

# Classify municipalities
panel[, merged := !is.na(merge_fy)]
panel[, never_merged := is.na(merge_fy)]

# Compute LAT-related variables
# LAT ≈ max(0, SFD - SFR) — standard formula
# Units are in 千円 (thousands of yen)
panel[, lat_implied := pmax(0, sfd - sfr)]
panel[, lat_share := fifelse(std_fiscal_scale > 0, lat_implied / std_fiscal_scale, NA_real_)]

# Event time relative to phase-out start
panel[merged == TRUE, event_time := fiscal_year - phaseout_start_fy]

# Phase-out intensity (how much of the merger bonus is being clawed back)
panel[merged == TRUE, phaseout_pct := fcase(
  event_time < 0, 0,       # Before phase-out: full bonus
  event_time == 0, 10,     # Year 11: 10% reduction
  event_time == 1, 30,     # Year 12: 30% reduction
  event_time == 2, 50,     # Year 13: 50% reduction
  event_time == 3, 70,     # Year 14: 70% reduction
  event_time == 4, 90,     # Year 15: 90% reduction
  event_time >= 5, 100,    # After phase-out: full reduction
  default = NA_real_
)]

# Per-capita variables (SFD in thousands of yen)
panel[, sfd_pc := sfd / population * 1000]  # Yen per capita
panel[, sfr_pc := sfr / population * 1000]
panel[, lat_pc := lat_implied / population * 1000]
panel[, std_scale_pc := std_fiscal_scale / population * 1000]

cat("Panel summary:\n")
cat(sprintf("  Merged municipalities: %d\n", uniqueN(panel$muni_code[panel$merged == TRUE])))
cat(sprintf("  Never-merged municipalities: %d\n", uniqueN(panel$muni_code[panel$never_merged == TRUE])))
cat(sprintf("  Panel years: %d to %d\n", min(panel$fiscal_year), max(panel$fiscal_year)))
cat(sprintf("  Total observations: %d\n", nrow(panel)))

# Event time coverage
if (any(!is.na(panel$event_time))) {
  cat("\nEvent time distribution (merged municipalities):\n")
  print(table(panel$event_time[panel$merged == TRUE]))
}

# ============================================================
# 4. Drop problematic observations and validate
# ============================================================

# Drop prefectural codes (first 2 digits = prefecture, last 4 = municipality)
# Prefecture-level entries have code ending in 000
panel <- panel[!grepl("000$", muni_code)]

# Drop observations with missing key variables
panel <- panel[!is.na(population) & population > 0]
panel <- panel[!is.na(sfd) & !is.na(sfr)]

cat("\nAfter cleaning:\n")
cat(sprintf("  Municipalities: %d\n", uniqueN(panel$muni_code)))
cat(sprintf("  Observations: %d\n", nrow(panel)))
cat(sprintf("  Merged: %d | Never-merged: %d\n",
            uniqueN(panel$muni_code[panel$merged == TRUE]),
            uniqueN(panel$muni_code[panel$never_merged == TRUE])))

# ============================================================
# 5. Save clean panel
# ============================================================
saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
fwrite(panel, file.path(data_dir, "panel_clean.csv"))

cat("\n=== Clean panel saved ===\n")
