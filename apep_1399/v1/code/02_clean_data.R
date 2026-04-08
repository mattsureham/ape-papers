# 02_clean_data.R — Construct state-year panel: mortality × geology × RRNC
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ============================================================================
# 1. Load USGS Geological Radon Potential Shapefile
# ============================================================================
cat("=== Loading USGS GRP shapefile ===\n")

sf_use_s2(FALSE)
grp_shp <- st_read(file.path(data_dir, "usradon", "conusgrp_NAD83.shp"), quiet = TRUE)
cat("GRP shapefile:", nrow(grp_shp), "features\n")

# ============================================================================
# 2. Compute State-Level GRP Composition
# ============================================================================
cat("\n=== Computing state-level GRP composition ===\n")

# Load county boundaries
county_shp_file <- file.path(data_dir, "counties_2020.shp")
if (!file.exists(county_shp_file)) {
  tiger_url <- "https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_county_500k.zip"
  tiger_zip <- file.path(data_dir, "counties_2020.zip")
  resp <- httr::GET(tiger_url, httr::timeout(120),
                    httr::write_disk(tiger_zip, overwrite = TRUE))
  stopifnot("County shapefile download failed" = httr::status_code(resp) == 200)
  unzip(tiger_zip, exdir = data_dir)
  file.rename(file.path(data_dir, "cb_2020_us_county_500k.shp"), county_shp_file)
  file.rename(file.path(data_dir, "cb_2020_us_county_500k.dbf"),
              file.path(data_dir, "counties_2020.dbf"))
  file.rename(file.path(data_dir, "cb_2020_us_county_500k.shx"),
              file.path(data_dir, "counties_2020.shx"))
  file.rename(file.path(data_dir, "cb_2020_us_county_500k.prj"),
              file.path(data_dir, "counties_2020.prj"))
}

counties <- st_read(county_shp_file, quiet = TRUE)
counties$fips5 <- paste0(counties$STATEFP, counties$COUNTYFP)
cat("Counties:", nrow(counties), "\n")

# Centroid-based assignment of GRP to each county
grp_proj <- st_transform(grp_shp, st_crs(counties))
county_centroids <- st_centroid(counties)
joined <- st_join(county_centroids, grp_proj, join = st_within)
joined$grp_num <- as.numeric(as.character(joined$GRP))

# Nearest fallback for unmatched
missing <- is.na(joined$grp_num)
if (sum(missing) > 0) {
  cat("Counties without centroid match:", sum(missing), "- using nearest\n")
  nearest_idx <- st_nearest_feature(county_centroids[missing, ], grp_proj)
  joined$grp_num[missing] <- as.numeric(as.character(grp_proj$GRP[nearest_idx]))
}

county_grp <- joined %>%
  st_drop_geometry() %>%
  transmute(
    fips5 = fips5,
    STATEFP = STATEFP,
    grp_num = grp_num,
    high_grp = as.integer(grp_num >= 2)
  ) %>%
  as.data.table()

# Aggregate to state level: share of counties with high GRP, mean GRP
state_grp <- county_grp[, .(
  n_counties = .N,
  high_grp_share = mean(high_grp, na.rm = TRUE),
  mean_grp = mean(grp_num, na.rm = TRUE),
  n_high_grp = sum(high_grp, na.rm = TRUE)
), by = .(state_fips = STATEFP)]

# Classify states as high-GRP if majority of counties are moderate/high
state_grp[, high_grp_state := as.integer(high_grp_share > 0.5)]

cat("State GRP composition:\n")
cat("High-GRP states (>50% counties moderate/high):", sum(state_grp$high_grp_state), "\n")
cat("Low-GRP states:", sum(1 - state_grp$high_grp_state), "\n")

fwrite(county_grp, file.path(data_dir, "county_grp.csv"))
fwrite(state_grp, file.path(data_dir, "state_grp.csv"))

# ============================================================================
# 3. Load State-Level Mortality Data (CDC Leading Causes, 1999-2017)
# ============================================================================
cat("\n=== Loading state-level mortality data ===\n")

mort_file <- file.path(data_dir, "state_mortality_all_causes.csv")
stopifnot("Mortality data not found — run 01_fetch_data.R" = file.exists(mort_file))

mort <- fread(mort_file)
cat("Mortality records:", nrow(mort), "\n")
cat("Causes:", paste(unique(mort$cause_name), collapse = ", "), "\n")

# Clean
mort[, year := as.integer(year)]
mort[, deaths := as.integer(gsub(",", "", deaths))]
mort[, aadr := as.numeric(aadr)]

# State name to FIPS mapping
state_fips_map <- data.table(
  state = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
            "Connecticut","Delaware","District of Columbia","Florida","Georgia",
            "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
            "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
            "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
            "New Jersey","New Mexico","New York","North Carolina","North Dakota",
            "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina",
            "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
            "Washington","West Virginia","Wisconsin","Wyoming"),
  state_fips = c("01","02","04","05","06","08","09","10","11","12","13","15","16",
                 "17","18","19","20","21","22","23","24","25","26","27","28","29",
                 "30","31","32","33","34","35","36","37","38","39","40","41","42",
                 "44","45","46","47","48","49","50","51","53","54","55","56")
)

mort <- merge(mort, state_fips_map, by = "state", all.x = TRUE)
# Drop "United States" total
mort <- mort[!is.na(state_fips)]

# Pivot to wide: one row per state-year with columns for each cause
mort_wide <- dcast(mort, state_fips + state + year ~ cause_name,
                   value.var = c("deaths", "aadr"))

# Clean column names
setnames(mort_wide, gsub(" ", "_", names(mort_wide)))
setnames(mort_wide, gsub("\\.", "", names(mort_wide)))

cat("State-year panel:", nrow(mort_wide), "rows\n")
cat("States:", length(unique(mort_wide$state_fips)), "\n")
cat("Years:", range(mort_wide$year), "\n")

# ============================================================================
# 4. Load RRNC Adoption Dates
# ============================================================================
cat("\n=== Loading RRNC adoption dates ===\n")
rrnc <- fread(file.path(data_dir, "rrnc_adoption.csv"))
rrnc[, state_fips := sprintf("%02d", as.integer(state_fips))]
cat("RRNC states:", nrow(rrnc), "\n")
print(rrnc)

# ============================================================================
# 5. Load State Population (for computing rates from death counts)
# ============================================================================
cat("\n=== Loading state population ===\n")

# Aggregate county populations to state level
pop_file <- file.path(data_dir, "county_population.csv")
pop_raw <- fread(pop_file, fill = TRUE)
pop_raw[, state_fips := sprintf("%02d", as.integer(STATE))]

# 2010-2023 from county_population.csv
pop_cols <- names(pop_raw)[grepl("^POPESTIMATE20", names(pop_raw))]
state_pop_2010 <- pop_raw[COUNTY == "000" | COUNTY == 0, ]
state_pop_long <- melt(state_pop_2010, id.vars = c("state_fips", "STNAME"),
                       measure.vars = pop_cols,
                       variable.name = "year_col", value.name = "population")
state_pop_long[, year := as.integer(gsub("POPESTIMATE", "", year_col))]

# 2000-2010 intercensal
pop00_file <- file.path(data_dir, "pop_2000_2010.csv")
if (!file.exists(pop00_file)) {
  download.file(
    "https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/county/co-est00int-tot.csv",
    pop00_file, quiet = TRUE)
}
pop00 <- fread(pop00_file, fill = TRUE)
pop00[, state_fips := sprintf("%02d", as.integer(STATE))]
pop_cols00 <- names(pop00)[grepl("^POPESTIMATE200", names(pop00))]
state_pop00 <- pop00[COUNTY == 0, ]
state_pop00_long <- melt(state_pop00, id.vars = c("state_fips", "STNAME"),
                         measure.vars = pop_cols00,
                         variable.name = "year_col", value.name = "population")
state_pop00_long[, year := as.integer(gsub("POPESTIMATE", "", year_col))]

# Add 1999 using 2000 as proxy
pop_1999 <- copy(state_pop00_long[year == 2000])
pop_1999[, year := 1999L]

state_pop <- rbindlist(list(pop_1999, state_pop00_long, state_pop_long), fill = TRUE)
state_pop <- unique(state_pop[, .(state_fips, year, population)], by = c("state_fips", "year"))

cat("State population panel:", nrow(state_pop), "rows\n")
cat("States:", length(unique(state_pop$state_fips)), "\n")

# ============================================================================
# 6. Build Analysis Dataset
# ============================================================================
cat("\n=== Building analysis dataset ===\n")

# Merge mortality + GRP + RRNC + population
analysis <- merge(mort_wide, state_grp[, .(state_fips, high_grp_share, mean_grp,
                                            n_counties, high_grp_state)],
                  by = "state_fips", all.x = TRUE)

analysis <- merge(analysis, rrnc[, .(state_fips, rrnc_year, rrnc_scope)],
                  by = "state_fips", all.x = TRUE)
analysis[is.na(rrnc_year), rrnc_year := 9999]

analysis <- merge(analysis, state_pop, by = c("state_fips", "year"), all.x = TRUE)

# Treatment variables
analysis[, post_rrnc := as.integer(year >= rrnc_year)]
analysis[, treated_state := as.integer(rrnc_year < 9999)]
analysis[, treat_x_grp := post_rrnc * high_grp_state]
analysis[, years_since := year - rrnc_year]
analysis[rrnc_year == 9999, years_since := NA]

# Compute crude cancer rate per 100,000 (supplement the AADR)
analysis[, cancer_deaths := deaths_Cancer]
analysis[, cancer_rate := cancer_deaths / population * 100000]

# Age-adjusted rate from CDC
analysis[, cancer_aadr := aadr_Cancer]
analysis[, heart_aadr := aadr_Heart_disease]
analysis[, clrd_aadr := aadr_CLRD]
analysis[, stroke_aadr := aadr_Stroke]
analysis[, diabetes_aadr := aadr_Diabetes]

# Continuous GRP treatment intensity
analysis[, treat_x_grp_cont := post_rrnc * high_grp_share]

# Save
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))

cat("Analysis panel:", nrow(analysis), "rows\n")
cat("States:", length(unique(analysis$state_fips)), "\n")
cat("Years:", range(analysis$year), "\n")
cat("Treated states:", sum(analysis$treated_state & analysis$year == 2010), "\n")
cat("Post-RRNC observations:", sum(analysis$post_rrnc), "\n")
cat("Cancer AADR range:", range(analysis$cancer_aadr, na.rm = TRUE), "\n")
cat("Population coverage:", sum(!is.na(analysis$population)), "/", nrow(analysis), "\n")

cat("\n=== Data cleaning complete ===\n")
