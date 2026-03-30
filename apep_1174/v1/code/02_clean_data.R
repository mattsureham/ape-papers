## 02_clean_data.R — Build facility-year analysis panel
## APEP-1174: The Enforcement Lottery

source("00_packages.R")
data_dir <- "../data"

cat("=== Loading cached data ===\n")
air_insp  <- readRDS(file.path(data_dir, "air_inspections.rds"))
echo      <- readRDS(file.path(data_dir, "echo_facilities.rds"))
emissions <- readRDS(file.path(data_dir, "emissions.rds"))
setDT(air_insp); setDT(echo); setDT(emissions)

cat("CAA inspections:", nrow(air_insp), "\n")
cat("ECHO facilities:", nrow(echo), "\n")
cat("Emissions records:", nrow(emissions), "\n")

## ============================================================
## 1. Clean CAA inspections
## ============================================================
cat("\n=== Cleaning CAA inspection data ===\n")

## Federal indicator from STATE_EPA_FLAG (E = EPA, S = State, L = Local)
air_insp[, federal := as.integer(STATE_EPA_FLAG == "E")]
cat("Federal inspections:", sum(air_insp$federal), "of", nrow(air_insp),
    "(", round(100 * mean(air_insp$federal), 1), "%)\n")

## Parse date: format is MM-DD-YYYY
air_insp[, eval_date := as.Date(ACTUAL_END_DATE, format = "%m-%d-%Y")]
cat("Dates parsed:", sum(!is.na(air_insp$eval_date)), "/", nrow(air_insp), "\n")

air_insp[, year := as.integer(format(eval_date, "%Y"))]

## Extract state from PGM_SYS_ID (first 2 characters = state abbreviation)
air_insp[, state := substr(PGM_SYS_ID, 1, 2)]

## Drop missing years and keep 2005-2023
air_insp <- air_insp[!is.na(year) & year >= 2005 & year <= 2023]
cat("After year filter (2005-2023):", nrow(air_insp), "inspections\n")

## Drop territories, keep 50 states + DC
valid_states <- c(state.abb, "DC")
air_insp <- air_insp[state %in% valid_states]
cat("After state filter:", nrow(air_insp), "inspections in",
    uniqueN(air_insp$state), "states\n")

## Year distribution
cat("\nYear distribution:\n")
print(table(air_insp$year))

## Federal share by year
fed_by_year <- air_insp[, .(
  n = .N, n_fed = sum(federal),
  fed_pct = round(100 * mean(federal), 1)
), by = year]
setorder(fed_by_year, year)
cat("\nFederal inspection share by year:\n")
print(fed_by_year)

## ============================================================
## 2. Inspection type detail
## ============================================================
cat("\n=== Inspection type detail ===\n")

## FCE (Full Compliance Evaluation) vs PCE (Partial) — FCEs are more rigorous
air_insp[, is_fce := as.integer(grepl("^F", COMP_MONITOR_TYPE_CODE))]
cat("FCE inspections:", sum(air_insp$is_fce), "of", nrow(air_insp),
    "(", round(100 * mean(air_insp$is_fce), 1), "%)\n")

## Federal inspections are more likely to be FCEs?
cat("FCE rate by inspector type:\n")
print(air_insp[, .(fce_rate = round(mean(is_fce), 3)), by = STATE_EPA_FLAG])

## ============================================================
## 3. Build facility-year panel
## ============================================================
cat("\n=== Building facility-year panel ===\n")

fac_year <- air_insp[, .(
  n_inspections = .N,
  n_federal     = sum(federal),
  n_state       = sum(STATE_EPA_FLAG == "S"),
  n_local       = sum(STATE_EPA_FLAG == "L"),
  any_federal   = as.integer(any(federal == 1)),
  n_fce         = sum(is_fce),
  n_fce_federal = sum(is_fce & federal == 1),
  fce_rate      = mean(is_fce)
), by = .(PGM_SYS_ID, state, year)]

fac_year[, fed_share := n_federal / n_inspections]
cat("Facility-year panel:", nrow(fac_year), "\n")
cat("Unique facilities:", uniqueN(fac_year$PGM_SYS_ID), "\n")

## ============================================================
## 4. State-year federal inspection intensity
## ============================================================
cat("\n=== State-year federal share ===\n")

state_year <- air_insp[, .(
  state_n_insp     = .N,
  state_n_federal  = sum(federal),
  state_fed_share  = mean(federal),
  state_fce_rate   = mean(is_fce)
), by = .(state, year)]

cat("State-year observations:", nrow(state_year), "\n")
cat("Mean state federal share:", round(mean(state_year$state_fed_share), 4), "\n")
cat("SD state federal share:", round(sd(state_year$state_fed_share), 4), "\n")

## Identify state-years with unusually HIGH federal share (SRF-triggered?)
state_year[, state_mean_fed := mean(state_fed_share), by = state]
state_year[, fed_share_deviation := state_fed_share - state_mean_fed]
state_year[, high_federal := as.integer(state_fed_share > state_mean_fed + 2 * sd(state_fed_share)),
           by = state]

cat("State-years with high federal share:", sum(state_year$high_federal, na.rm = TRUE),
    "of", nrow(state_year), "\n")

## ============================================================
## 5. Link to emissions via ECHO FRS
## ============================================================
cat("\n=== Linking to emissions ===\n")

## The FRS download maps REGISTRY_ID to program-specific IDs
## First, try the FRS program links file
frs_dir <- file.path(data_dir, "echo_exporter")  # ECHO exporter dir
frs_zip <- file.path(data_dir, "frs_downloads.zip")

## Download FRS if needed
if (!file.exists(frs_zip)) {
  cat("Downloading FRS crosswalk...\n")
  resp <- GET("https://echo.epa.gov/files/echodownloads/frs_downloads.zip",
              write_disk(frs_zip, overwrite = TRUE), progress(), timeout(300))
}

frs_dir2 <- file.path(data_dir, "frs")
dir.create(frs_dir2, showWarnings = FALSE)
unzip(frs_zip, exdir = frs_dir2, overwrite = TRUE)
frs_files <- list.files(frs_dir2, pattern = "\\.csv$", full.names = TRUE)
cat("FRS files:", paste(basename(frs_files), collapse = ", "), "\n")

## Find the program links file
pgm_file <- frs_files[grepl("PROGRAM|PGM", frs_files, ignore.case = TRUE)]
if (length(pgm_file) > 0) {
  cat("Reading FRS program links:", basename(pgm_file[1]), "\n")
  frs_pgm <- fread(pgm_file[1], fill = TRUE, showProgress = TRUE)
  cat("FRS program links:", nrow(frs_pgm), "records\n")
  cat("Columns:", paste(names(frs_pgm), collapse = ", "), "\n")

  ## Filter to CAA programs
  air_pgm <- frs_pgm[grepl("AIR|CAA|ICIS", PGM_SYS_ACRNM, ignore.case = TRUE)]
  cat("CAA program links:", nrow(air_pgm), "\n")

  ## Create crosswalk: PGM_SYS_ID -> REGISTRY_ID
  crosswalk <- unique(air_pgm[, .(REGISTRY_ID, PGM_SYS_ID)])
  cat("Unique PGM_SYS_ID -> REGISTRY_ID mappings:", nrow(crosswalk), "\n")

  ## Merge with facility-year panel
  fac_year <- merge(fac_year, crosswalk, by = "PGM_SYS_ID", all.x = TRUE)
  cat("Matched to REGISTRY_ID:", sum(!is.na(fac_year$REGISTRY_ID)),
      "of", nrow(fac_year), "\n")
} else {
  cat("No program links file found. Using direct PGM_SYS_ID.\n")
  fac_year[, REGISTRY_ID := PGM_SYS_ID]
}

## ============================================================
## 6. Merge with emissions
## ============================================================
cat("\n=== Merging with emissions ===\n")

## TRI emissions (program = TRIS in combined emissions)
tri_em <- emissions[PGM_SYS_ACRNM == "TRIS"]
cat("TRI emission records:", nrow(tri_em), "\n")

tri_fac_year <- tri_em[, .(
  total_releases_lbs = sum(ANNUAL_EMISSION, na.rm = TRUE),
  n_pollutants       = uniqueN(POLLUTANT_NAME)
), by = .(REGISTRY_ID, REPORTING_YEAR)]
cat("TRI facility-years:", nrow(tri_fac_year), "\n")

## Merge
panel <- merge(
  fac_year,
  tri_fac_year,
  by.x = c("REGISTRY_ID", "year"),
  by.y = c("REGISTRY_ID", "REPORTING_YEAR"),
  all.x = TRUE
)
cat("Panel after TRI merge:", nrow(panel), "\n")
cat("  with TRI data:", sum(!is.na(panel$total_releases_lbs)), "\n")

## NEI emissions for robustness
nei_em <- emissions[PGM_SYS_ACRNM == "EIS"]
if (nrow(nei_em) > 0) {
  nei_fac_year <- nei_em[, .(
    nei_releases_tons = sum(ANNUAL_EMISSION, na.rm = TRUE)
  ), by = .(REGISTRY_ID, REPORTING_YEAR)]

  panel <- merge(panel, nei_fac_year,
                  by.x = c("REGISTRY_ID", "year"),
                  by.y = c("REGISTRY_ID", "REPORTING_YEAR"),
                  all.x = TRUE)
  cat("  with NEI data:", sum(!is.na(panel$nei_releases_tons)), "\n")
}

## ============================================================
## 7. Merge facility characteristics
## ============================================================
cat("\n=== Adding facility characteristics ===\n")

echo_slim <- echo[, .(
  REGISTRY_ID,
  fac_name = FAC_NAME,
  fac_state = FAC_STATE,
  fac_county = FAC_COUNTY,
  fac_fips = FAC_FIPS_CODE,
  fac_naics = FAC_NAICS_CODES,
  fac_lat = FAC_LAT,
  fac_long = FAC_LONG,
  tri_flag = TRI_FLAG,
  epa_region = FAC_EPA_REGION,
  federal_flag = FAC_FEDERAL_FLG
)]
echo_slim <- unique(echo_slim, by = "REGISTRY_ID")

panel <- merge(panel, echo_slim, by = "REGISTRY_ID", all.x = TRUE)

## ============================================================
## 8. Create analysis variables
## ============================================================
cat("\n=== Creating analysis variables ===\n")

## Log emissions
panel[, log_releases := log(total_releases_lbs + 1)]
panel[, has_tri := as.integer(!is.na(total_releases_lbs) & total_releases_lbs > 0)]

## NEI log
if ("nei_releases_tons" %in% names(panel)) {
  panel[, log_nei := log(nei_releases_tons + 1)]
}

## Add state-year federal share
panel <- merge(panel, state_year[, .(state, year, state_fed_share, state_n_insp,
                                      state_n_federal, high_federal, fed_share_deviation)],
               by = c("state", "year"), all.x = TRUE)

## 2-digit NAICS
panel[, naics2 := substr(fac_naics, 1, 2)]

## Numeric facility ID for FE
panel[, fac_id := as.integer(factor(PGM_SYS_ID))]

## ============================================================
## 9. Final samples
## ============================================================
cat("\n=== Final sample sizes ===\n")

## TRI sample (facilities with emissions data)
panel_tri <- panel[has_tri == 1]

cat("\nFull panel:", nrow(panel), "obs,", uniqueN(panel$PGM_SYS_ID), "facilities\n")
cat("TRI panel:", nrow(panel_tri), "obs,", uniqueN(panel_tri$PGM_SYS_ID), "facilities\n")
cat("States:", uniqueN(panel$state), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")

cat("\n--- TRI panel summary ---\n")
cat("Mean log(releases):", round(mean(panel_tri$log_releases, na.rm = TRUE), 2), "\n")
cat("SD log(releases):", round(sd(panel_tri$log_releases, na.rm = TRUE), 2), "\n")
cat("Mean fed_share:", round(mean(panel_tri$fed_share, na.rm = TRUE), 4), "\n")
cat("Mean any_federal:", round(mean(panel_tri$any_federal, na.rm = TRUE), 4), "\n")
cat("Mean n_inspections:", round(mean(panel_tri$n_inspections, na.rm = TRUE), 2), "\n")

## ============================================================
## 10. Save
## ============================================================
saveRDS(panel, file.path(data_dir, "panel_full.rds"))
saveRDS(panel_tri, file.path(data_dir, "panel_tri.rds"))
saveRDS(state_year, file.path(data_dir, "state_year_fed.rds"))

cat("\n=== Data cleaning complete ===\n")
