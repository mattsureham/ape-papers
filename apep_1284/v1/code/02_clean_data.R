# 02_clean_data.R — Spatial join to counties + construct analysis dataset
# APEP-1284: BLM Lottery Leases and Western County Economies

source("00_packages.R")

if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf", repos = "https://cloud.r-project.org")
if (!requireNamespace("tigris", quietly = TRUE)) install.packages("tigris", repos = "https://cloud.r-project.org")
library(sf)
library(tigris)
options(tigris_use_cache = TRUE)

DATA_DIR <- "../data"

# ============================================================
# 1. LOAD TOWNSHIP LEASE DATA WITH COORDINATES
# ============================================================
cat("=== Loading township lease data ===\n")
twp <- fread(file.path(DATA_DIR, "township_leases_geo.csv"))
cat(sprintf("Township records: %d\n", nrow(twp)))

# Focus on core Western states (continental US only, excluding AK)
western_states <- c("WY", "MT", "NM", "CO", "UT", "NV", "CA", "ID", "OR",
                    "SD", "ND", "NE", "AZ")
twp_west <- twp[state %in% western_states]
cat(sprintf("Western township records: %d\n", nrow(twp_west)))

# ============================================================
# 2. SPATIAL JOIN: TOWNSHIPS → COUNTIES
# ============================================================
cat("=== Spatial join to counties ===\n")

# Convert to sf points
twp_sf <- st_as_sf(twp_west, coords = c("lon", "lat"), crs = 4326)

# Get US county boundaries
counties_sf <- counties(cb = TRUE, year = 2020, class = "sf")
counties_sf <- st_transform(counties_sf, 4326)

# Spatial join
joined <- st_join(twp_sf, counties_sf[, c("GEOID", "NAME", "STATEFP", "COUNTYFP")])

# Back to data.table
joined_dt <- as.data.table(st_drop_geometry(joined))

# Check coverage
cat(sprintf("Townships with county match: %d / %d\n",
            sum(!is.na(joined_dt$GEOID)), nrow(joined_dt)))

# ============================================================
# 3. AGGREGATE TO COUNTY LEVEL
# ============================================================
cat("=== Aggregating to county level ===\n")

county_leases <- joined_dt[!is.na(GEOID), .(
  lottery_acres = sum(lottery_acres, na.rm = TRUE),
  noncomp_acres = sum(noncomp_acres, na.rm = TRUE),
  competitive_acres = sum(competitive_acres, na.rm = TRUE),
  lottery_n = sum(lottery_n, na.rm = TRUE),
  noncomp_n = sum(noncomp_n, na.rm = TRUE),
  competitive_n = sum(competitive_n, na.rm = TRUE),
  n_townships = .N
), by = .(fips = GEOID, county_name = NAME, state_fips = STATEFP)]

# Compute lottery share
county_leases[, total_prefooglra_acres := lottery_acres + noncomp_acres]
county_leases[, total_all_acres := lottery_acres + noncomp_acres + competitive_acres]
county_leases[, lottery_share := ifelse(total_prefooglra_acres > 0,
                                         lottery_acres / total_prefooglra_acres, 0)]
county_leases[, lottery_share_all := ifelse(total_all_acres > 0,
                                             lottery_acres / total_all_acres, 0)]

cat(sprintf("Counties with any federal O&G leases: %d\n", nrow(county_leases)))
cat(sprintf("Counties with lottery leases: %d\n",
            sum(county_leases$lottery_acres > 0)))
cat(sprintf("\nLottery share summary:\n"))
print(summary(county_leases$lottery_share))

# ============================================================
# 4. LOAD AND CLEAN BEA REIS DATA
# ============================================================
cat("\n=== Loading BEA REIS data ===\n")

clean_bea <- function(file, varname) {
  fp <- file.path(DATA_DIR, file)
  if (!file.exists(fp) || file.info(fp)$size == 0) {
    cat(sprintf("  Skipping %s (empty or missing)\n", file))
    return(NULL)
  }
  dt <- fread(fp)
  if (nrow(dt) == 0 || !"GeoFips" %in% names(dt)) return(NULL)
  dt <- dt[, .(fips = GeoFips, year = as.integer(TimePeriod),
               value = as.numeric(gsub(",", "", DataValue)))]
  dt <- dt[!grepl("000$", fips)]
  dt <- dt[!is.na(value)]
  setnames(dt, "value", varname)
  return(dt)
}

bea_pcincome <- clean_bea("bea_pcincome.csv", "pc_income")
bea_pop <- clean_bea("bea_population.csv", "population")
stopifnot(!is.null(bea_pcincome), !is.null(bea_pop))

cat(sprintf("BEA per capita income: %d obs\n", nrow(bea_pcincome)))
cat(sprintf("BEA population: %d obs\n", nrow(bea_pop)))

# Merge BEA data
bea_panel <- merge(bea_pcincome, bea_pop, by = c("fips", "year"), all = TRUE)

# Log transformations
bea_panel[, log_pc_income := log(pc_income)]
bea_panel[, log_pop := log(population)]

# ============================================================
# 5. MERGE COUNTY LEASES WITH BEA PANEL
# ============================================================
cat("\n=== Merging datasets ===\n")

# Ensure fips is character in both
bea_panel[, fips := as.character(fips)]
county_leases[, fips := as.character(fips)]

# Merge: county_leases (cross-section) x bea_panel (panel)
analysis <- merge(bea_panel, county_leases[, .(fips, lottery_share, lottery_acres,
                                                total_prefooglra_acres, total_all_acres,
                                                lottery_share_all, n_townships, state_fips)],
                  by = "fips", all.x = FALSE)

# Define eras
analysis[, era := fcase(
  year <= 1975, "pre_lottery",
  year <= 1990, "lottery_era",
  year <= 2005, "post_lottery",
  default = "modern"
)]

analysis[, post_era := as.integer(year > 1990)]

# State fixed effects
analysis[, state := substr(fips, 1, 2)]

# Treatment intensity: interaction of lottery share with post-era
analysis[, lottery_x_post := lottery_share * post_era]

# High lottery share indicator (above median)
med_lottery <- median(county_leases[lottery_acres > 0]$lottery_share, na.rm = TRUE)
analysis[, high_lottery := as.integer(lottery_share > med_lottery)]

cat(sprintf("Analysis panel: %d county-years\n", nrow(analysis)))
cat(sprintf("Unique counties: %d\n", uniqueN(analysis$fips)))
cat(sprintf("Years: %s\n", paste(sort(unique(analysis$year)), collapse = ", ")))

# ============================================================
# 6. SAVE
# ============================================================
fwrite(county_leases, file.path(DATA_DIR, "county_leases.csv"))
fwrite(analysis, file.path(DATA_DIR, "analysis_panel.csv"))
cat("\n=== Data saved ===\n")

# Summary statistics
cat("\n=== Key summary statistics ===\n")
cat(sprintf("N counties: %d\n", uniqueN(analysis$fips)))
cat(sprintf("N county-years: %d\n", nrow(analysis)))
cat(sprintf("Lottery share: mean=%.3f, sd=%.3f, p25=%.3f, p75=%.3f\n",
            mean(county_leases$lottery_share), sd(county_leases$lottery_share),
            quantile(county_leases$lottery_share, 0.25),
            quantile(county_leases$lottery_share, 0.75)))
cat(sprintf("Median lottery acres: %s\n", format(median(county_leases$lottery_acres), big.mark = ",")))
