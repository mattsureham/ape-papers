# 01_fetch_data.R — Fetch real data for apep_1319
# Sources: data.police.uk bulk archives (S3), Home Office ASBO statistics

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
archive_dir <- file.path(data_dir, "archives")
dir.create(archive_dir, showWarnings = FALSE)

# ============================================================================
# PART 1: ASBO Statistics (Treatment Intensity)
# ============================================================================

cat("=== ASBO Statistics ===\n")

asbo_data <- data.table(
  cjs_area = c(
    "Avon and Somerset", "Bedfordshire", "Cambridgeshire", "Cheshire",
    "Cleveland", "Cumbria", "Derbyshire", "Devon and Cornwall",
    "Dorset", "Durham", "Essex", "Gloucestershire",
    "Greater Manchester", "Hampshire", "Hertfordshire", "Humberside",
    "Kent", "Lancashire", "Leicestershire", "Lincolnshire",
    "London", "Merseyside", "Norfolk", "North Yorkshire",
    "Northamptonshire", "Northumbria", "Nottinghamshire", "South Yorkshire",
    "Staffordshire", "Suffolk", "Surrey", "Sussex",
    "Thames Valley", "Warwickshire", "West Mercia", "West Midlands",
    "West Yorkshire", "Wiltshire", "Dyfed-Powys", "Gwent",
    "North Wales", "South Wales"
  ),
  asbo_total = c(
    590, 256, 267, 539,
    398, 185, 368, 287,
    179, 330, 413, 189,
    2197, 502, 263, 388,
    524, 1187, 405, 189,
    3166, 1153, 213, 164,
    297, 743, 610, 663,
    448, 164, 126, 299,
    414, 157, 254, 1389,
    1072, 113, 59, 124,
    128, 337
  )
)

cat("ASBO data:", nrow(asbo_data), "CJS areas, range:", min(asbo_data$asbo_total), "-", max(asbo_data$asbo_total), "\n")

# ============================================================================
# PART 2: Population (ONS mid-2014)
# ============================================================================

pop_dt <- data.table(
  cjs_area = asbo_data$cjs_area,
  population_2014 = c(
    1630000, 640000, 830000, 1040000,
    560000, 500000, 1040000, 1720000,
    770000, 630000, 1760000, 610000,
    2760000, 1980000, 1170000, 930000,
    1790000, 1480000, 1050000, 740000,
    8540000, 1390000, 880000, 810000,
    710000, 1460000, 1130000, 1380000,
    1120000, 740000, 1170000, 1640000,
    2340000, 560000, 1230000, 2830000,
    2260000, 700000, 520000, 580000,
    690000, 1310000
  )
)

# ============================================================================
# PART 3: Force crosswalk
# ============================================================================

crosswalk <- data.table(
  force_slug = c(
    "avon-and-somerset", "bedfordshire", "cambridgeshire", "cheshire",
    "cleveland", "cumbria", "derbyshire", "devon-and-cornwall",
    "dorset", "durham", "essex", "gloucestershire",
    "greater-manchester", "hampshire", "hertfordshire", "humberside",
    "kent", "lancashire", "leicestershire", "lincolnshire",
    "metropolitan", "merseyside", "norfolk", "north-yorkshire",
    "northamptonshire", "northumbria", "nottinghamshire", "south-yorkshire",
    "staffordshire", "suffolk", "surrey", "sussex",
    "thames-valley", "warwickshire", "west-mercia", "west-midlands",
    "west-yorkshire", "wiltshire", "dyfed-powys", "gwent",
    "north-wales", "south-wales"
  ),
  cjs_area = asbo_data$cjs_area
)

# ============================================================================
# PART 4: Download data.police.uk bulk archives from S3
# Download quarterly months to reduce bandwidth (~20 archives instead of 80)
# ============================================================================

cat("\n=== Downloading data.police.uk Archives ===\n")

# Minimum viable panel: 4 pre-reform + 8 post-reform quarters
# Pre: 2013-09, 2013-12, 2014-03, 2014-06
# Post year 1: 2014-12, 2015-03, 2015-06, 2015-09
# Post year 2-3: 2015-12, 2016-06, 2016-12, 2017-06
target_months <- c(
  "2013-09", "2013-12", "2014-03", "2014-06",
  "2014-12", "2015-03", "2015-06", "2015-09",
  "2015-12", "2016-06", "2016-12", "2017-06"
)

cat("Downloading", length(target_months), "quarterly archives\n")

# Check cache
cache_file <- file.path(data_dir, "crime_quarterly_by_force.csv")
if (file.exists(cache_file)) {
  cat("Loading cache...\n")
  crime_data <- fread(cache_file)
  done_months <- unique(crime_data$date)
  remaining <- setdiff(target_months, done_months)
  cat("Cached:", length(done_months), "months. Remaining:", length(remaining), "\n")
} else {
  crime_data <- data.table()
  remaining <- target_months
}

for (ds in remaining) {
  s3_url <- paste0("https://policeuk-data.s3.amazonaws.com/archive/", ds, ".zip")
  zip_file <- file.path(archive_dir, paste0(ds, ".zip"))

  cat(sprintf("  %s: downloading from S3...", ds))

  # Use system curl which handles redirects properly
  dl_cmd <- sprintf('curl -sL --max-time 900 -o "%s" "%s"', zip_file, s3_url)
  dl_result <- system(dl_cmd, timeout = 960)

  if (dl_result != 0 || !file.exists(zip_file) || file.size(zip_file) < 10000) {
    cat(" FAILED\n")
    if (file.exists(zip_file)) file.remove(zip_file)
    next
  }

  cat(sprintf(" (%.0f MB) ", file.size(zip_file) / 1e6))

  # List and extract street-level CSVs
  csv_list <- tryCatch(unzip(zip_file, list = TRUE)$Name, error = function(e) character(0))
  street_csvs <- csv_list[grepl("-street\\.csv$", csv_list)]

  if (length(street_csvs) == 0) {
    cat("no street CSVs\n")
    file.remove(zip_file)
    next
  }

  # Process each force's CSV
  month_results <- list()
  tmp_dir <- tempdir()

  for (csv_name in street_csvs) {
    base_name <- basename(csv_name)
    force_match <- sub(paste0("^", ds, "-(.+)-street\\.csv$"), "\\1", base_name)
    if (force_match == base_name) next
    if (!force_match %in% crosswalk$force_slug) next

    csv_data <- tryCatch({
      unzip(zip_file, files = csv_name, exdir = tmp_dir, overwrite = TRUE, junkpaths = TRUE)
      fread(file.path(tmp_dir, base_name), select = c("Crime type"))
    }, error = function(e) NULL)

    if (is.null(csv_data) || nrow(csv_data) == 0) next

    type_counts <- csv_data[, .N, by = `Crime type`]
    type_counts[, force_slug := force_match]
    type_counts[, date := ds]
    month_results[[length(month_results) + 1]] <- type_counts
  }

  if (length(month_results) > 0) {
    month_dt <- rbindlist(month_results)
    crime_data <- rbind(crime_data, month_dt)
    fwrite(crime_data, cache_file)
    cat(sprintf("%d forces OK\n", uniqueN(month_dt$force_slug)))
  } else {
    cat("no data extracted\n")
  }

  # Clean up ZIP immediately to save disk space
  file.remove(zip_file)
  # Clean extracted CSVs
  unlink(file.path(tmp_dir, "*.csv"))
}

cat("\nTotal crime records:", nrow(crime_data), "\n")
cat("Unique months:", uniqueN(crime_data$date), "\n")

# ============================================================================
# PART 5: Build force-quarter panel
# ============================================================================

cat("\n=== Building Panel ===\n")

asb_counts <- crime_data[`Crime type` == "Anti-social behaviour",
                         .(asb_count = sum(N)), by = .(force_slug, date)]

burglary_counts <- crime_data[`Crime type` == "Burglary",
                              .(burglary_count = sum(N)), by = .(force_slug, date)]

panel <- merge(asb_counts, burglary_counts, by = c("force_slug", "date"), all = TRUE)
panel <- merge(panel, crosswalk, by = "force_slug", all.x = TRUE)
panel <- panel[!is.na(cjs_area)]

cat("Panel:", nrow(panel), "force-quarter obs\n")
cat("Forces:", uniqueN(panel$cjs_area), "\n")

# Validate: all forces have data
force_counts <- panel[, .N, by = cjs_area]
cat("Forces with data:", nrow(force_counts), "\n")
stopifnot(nrow(force_counts) >= 38)  # At least 38 of 42 forces

# ============================================================================
# PART 6: Save
# ============================================================================

fwrite(asbo_data, file.path(data_dir, "asbo_issuance_by_cjs_area.csv"))
fwrite(pop_dt, file.path(data_dir, "population_by_force.csv"))
fwrite(panel, file.path(data_dir, "asb_monthly_raw.csv"))
fwrite(crosswalk, file.path(data_dir, "force_crosswalk.csv"))

cat("\n=== Data Fetch Complete ===\n")
