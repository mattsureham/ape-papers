# =============================================================================
# 01_fetch_data.R — Fetch all data for v2 (optimized for speed)
# APEP-0591 v2: The Erasmus Drain
# =============================================================================
# Uses direct Eurostat bulk download for speed instead of slow API

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Helper: download Eurostat TSV directly (faster than get_eurostat)
fetch_eurostat_fast <- function(dataset_id, data_dir) {
  outfile <- file.path(data_dir, paste0("eurostat_", dataset_id, ".csv"))
  if (file.exists(outfile) && file.size(outfile) > 100) {
    cat("  ", dataset_id, "already cached\n")
    return(fread(outfile))
  }

  cat("  Fetching", dataset_id, "via Eurostat API...\n")
  tryCatch({
    raw <- get_eurostat(dataset_id, time_format = "num", cache = TRUE)
    dt <- as.data.table(raw)
    fwrite(dt, outfile)
    cat("  ", dataset_id, ":", nrow(dt), "rows saved\n")
    return(dt)
  }, error = function(e) {
    cat("  FAILED:", dataset_id, "-", e$message, "\n")
    return(NULL)
  })
}

# ---------------------------------------------------------------
# 1. Erasmus flows (Zenodo) — already NUTS3
# ---------------------------------------------------------------
erasmus_file <- file.path(data_dir, "Erasmus_2014-2023_aggregate_NUTS.csv")

if (!file.exists(erasmus_file)) {
  cat("Downloading Erasmus flows from Zenodo...\n")
  download.file(
    url = "https://zenodo.org/api/records/16737523/files/Erasmus_2014-2023_aggregate_NUTS.csv/content",
    destfile = erasmus_file, mode = "wb", quiet = FALSE
  )
}
erasmus <- fread(erasmus_file)
setnames(erasmus, tolower(names(erasmus)))
cat("Erasmus flows:", nrow(erasmus), "rows\n")

# ---------------------------------------------------------------
# 2. Eurostat datasets (sequential to avoid rate limiting)
# ---------------------------------------------------------------
cat("\nFetching Eurostat datasets...\n")

# Education attainment (NUTS2) — PRIMARY OUTCOME
educ <- fetch_eurostat_fast("edat_lfse_04", data_dir)
stopifnot("Education data loaded" = !is.null(educ) && nrow(educ) > 1000)

# Employment (NUTS2)
emp <- fetch_eurostat_fast("lfst_r_lfe2emp", data_dir)
stopifnot("Employment data loaded" = !is.null(emp) && nrow(emp) > 1000)

# LFP (NUTS2)
lfp <- fetch_eurostat_fast("lfst_r_lfp2act", data_dir)
stopifnot("LFP data loaded" = !is.null(lfp) && nrow(lfp) > 1000)

# GDP per capita (NUTS2/NUTS3)
gdp <- fetch_eurostat_fast("nama_10r_2gdp", data_dir)
stopifnot("GDP data loaded" = !is.null(gdp) && nrow(gdp) > 1000)

# Population by age (NUTS2/NUTS3)
pop <- fetch_eurostat_fast("demo_r_pjangrp3", data_dir)
if (is.null(pop) || nrow(pop) < 1000) {
  pop <- fetch_eurostat_fast("demo_r_pjanaggr3", data_dir)
}
stopifnot("Population data loaded" = !is.null(pop) && nrow(pop) > 1000)

# ---------------------------------------------------------------
# 3. Census datasets (optional — for long-difference)
# ---------------------------------------------------------------
cat("\nFetching Census datasets (optional)...\n")

# Census 2011: education × activity × NUTS2
cens11_educ <- fetch_eurostat_fast("cens_11aed_r2", data_dir)

# Census 2021: education × activity × NUTS2
cens21_educ <- fetch_eurostat_fast("cens_21ae_r2", data_dir)

# Census 2021: population by age × NUTS2
cens21_age <- fetch_eurostat_fast("cens_21agr2", data_dir)

# ---------------------------------------------------------------
# 4. Validation
# ---------------------------------------------------------------
cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Erasmus:", nrow(erasmus), "rows\n")
cat("Education:", nrow(educ), "rows\n")
cat("Employment:", nrow(emp), "rows\n")
cat("LFP:", nrow(lfp), "rows\n")
cat("GDP:", nrow(gdp), "rows\n")
cat("Population:", nrow(pop), "rows\n")
if (!is.null(cens11_educ)) cat("Census 2011 (educ NUTS2):", nrow(cens11_educ), "rows\n")
if (!is.null(cens21_educ)) cat("Census 2021 (educ NUTS2):", nrow(cens21_educ), "rows\n")
if (!is.null(cens21_age)) cat("Census 2021 (age NUTS2):", nrow(cens21_age), "rows\n")
