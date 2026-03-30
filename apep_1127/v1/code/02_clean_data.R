# 02_clean_data.R — Construct county-month panel with treatment assignment
# apep_1127: Injection well volume regulations and induced seismicity

source("00_packages.R")

cat("=== Loading earthquake data ===\n")
ok_quakes <- read_csv("../data/ok_quakes_county.csv", show_col_types = FALSE)
ks_quakes <- read_csv("../data/ks_quakes_county.csv", show_col_types = FALSE)
wti <- read_csv("../data/wti_prices.csv", show_col_types = FALSE)
ok_counties <- readRDS("../data/ok_counties.rds")

# =============================================================================
# OKLAHOMA TREATMENT ASSIGNMENT
# =============================================================================
# OCC directives targeted wells in the Arbuckle formation disposal zone.
# We identify treated counties based on the "Area of Interest" (AOI) defined by
# OCC, which covers north-central Oklahoma where most injection wells sit.
#
# Treatment timing is based on the FIRST major directive affecting each county:
# - March 2015: First "Plan to Address" — 347 wells in AOI required 50% reduction
# - February 2016: Second wave — 40% aggregate reduction for 600+ wells (expanded AOI)
# - September 2016: Post-Pawnee (M5.8) emergency — 32 wells shut in, 35 reduced
# - March 2017: Daily caps of 10,000-15,000 BPD across remaining wells
#
# Counties in the AOI (determined by OCC regulatory maps and seismicity clusters):
# These are counties with significant Arbuckle formation injection activity.
# =============================================================================

# Counties in OCC "Area of Interest" and their first treatment month
# Based on OCC regulatory actions documented in:
# - OCC "Earthquake Response" page
# - Murray (2015) "Seismicity in Oklahoma"
# - Langenbruch & Zoback (2016) "How will induced seismicity in Oklahoma respond to
#   decreased saltwater injection rates?"

# Wave 1 (March 2015): Original AOI — highest-seismicity counties
wave1_counties <- c(
  "40047",  # Garfield
  "40073",  # Kingfisher
  "40083",  # Logan
  "40103",  # Noble
  "40107",  # Oklahoma
  "40119",  # Payne
  "40017",  # Canadian
  "40081"   # Lincoln
)

# Wave 2 (February 2016): Expanded AOI — broader injection zone
wave2_counties <- c(
  "40003",  # Alfalfa
  "40053",  # Grant
  "40093",  # Major
  "40043",  # Dewey
  "40149",  # Washita
  "40039",  # Custer
  "40011",  # Blaine
  "40025",  # Cimarron (expanded north)
  "40129",  # Roger Mills
  "40153"   # Woodward
)

# Wave 3 (September 2016): Post-Pawnee emergency — additional shutdowns
wave3_counties <- c(
  "40117",  # Pawnee (epicenter of M5.8)
  "40037",  # Creek
  "40113",  # Osage
  "40143"   # Tulsa (eastern extension)
)

# Compile treatment assignment
treatment_df <- bind_rows(
  tibble(county_fips = wave1_counties, first_treat_date = as.Date("2015-03-01"), wave = 1),
  tibble(county_fips = wave2_counties, first_treat_date = as.Date("2016-02-01"), wave = 2),
  tibble(county_fips = wave3_counties, first_treat_date = as.Date("2016-09-01"), wave = 3)
)

# Convert to numeric month indicator for did package
treatment_df <- treatment_df |>
  mutate(
    first_treat_ym = as.numeric(format(first_treat_date, "%Y")) * 12 +
                     as.numeric(format(first_treat_date, "%m"))
  )

cat(sprintf("Treated counties: %d (Wave 1: %d, Wave 2: %d, Wave 3: %d)\n",
            nrow(treatment_df),
            sum(treatment_df$wave == 1),
            sum(treatment_df$wave == 2),
            sum(treatment_df$wave == 3)))

# =============================================================================
# CONSTRUCT COUNTY-MONTH PANEL (OKLAHOMA)
# =============================================================================

cat("\n=== Constructing county-month panel ===\n")

# All Oklahoma county FIPS
all_ok_fips <- ok_counties$GEOID

# Create balanced panel: all counties × all months
months_seq <- seq(as.Date("2010-01-01"), as.Date("2023-12-01"), by = "month")

panel <- expand_grid(
  county_fips = all_ok_fips,
  year_month = months_seq
) |>
  mutate(
    year = year(year_month),
    month = month(year_month),
    ym_numeric = year * 12 + month
  )

# Count earthquakes per county-month
quake_counts <- ok_quakes |>
  mutate(year_month = floor_date(as.Date(year_month), "month"),
         county_fips = as.character(county_fips)) |>
  group_by(county_fips, year_month) |>
  summarise(
    n_quakes = n(),
    max_mag = max(mag, na.rm = TRUE),
    mean_mag = mean(mag, na.rm = TRUE),
    n_quakes_m3 = sum(mag >= 3.0, na.rm = TRUE),
    n_quakes_m4 = sum(mag >= 4.0, na.rm = TRUE),
    .groups = "drop"
  )

# Merge counts into panel (fill zeros for county-months with no earthquakes)
panel <- panel |>
  left_join(quake_counts, by = c("county_fips", "year_month")) |>
  mutate(across(c(n_quakes, n_quakes_m3, n_quakes_m4), ~replace_na(.x, 0)),
         across(c(max_mag, mean_mag), ~replace_na(.x, 0)))

# Merge treatment assignment
panel <- panel |>
  left_join(treatment_df |> select(county_fips, first_treat_date, first_treat_ym, wave),
            by = "county_fips") |>
  mutate(
    treated_county = !is.na(first_treat_ym),
    post = ifelse(treated_county, ym_numeric >= first_treat_ym, FALSE),
    treat_post = treated_county & post,
    # For never-treated counties, set first_treat_ym = 0 (did package convention)
    first_treat_ym = replace_na(first_treat_ym, 0)
  )

# Merge WTI oil prices
wti_merge <- wti |>
  mutate(year_month = floor_date(as.Date(date), "month")) |>
  select(year_month, wti_price)

panel <- panel |>
  left_join(wti_merge, by = "year_month")

# County names
county_names <- ok_counties |>
  st_drop_geometry() |>
  select(county_fips = GEOID, county_name = NAME)

panel <- panel |>
  left_join(county_names, by = "county_fips")

# Add IHS transformation for count data (inverse hyperbolic sine)
panel <- panel |>
  mutate(
    ihs_quakes = log(n_quakes + sqrt(n_quakes^2 + 1)),
    log_quakes_p1 = log(n_quakes + 1)
  )

cat(sprintf("Panel dimensions: %d rows × %d columns\n", nrow(panel), ncol(panel)))
cat(sprintf("Counties: %d (treated: %d, never-treated: %d)\n",
            n_distinct(panel$county_fips),
            sum(panel$treated_county[!duplicated(panel$county_fips)]),
            sum(!panel$treated_county[!duplicated(panel$county_fips)])))
cat(sprintf("Months: %d (%s to %s)\n",
            n_distinct(panel$year_month),
            min(panel$year_month), max(panel$year_month)))

# Pre-treatment summary for treated vs control
pre_summary <- panel |>
  filter(year < 2015) |>
  group_by(treated_county) |>
  summarise(
    mean_quakes = mean(n_quakes),
    sd_quakes = sd(n_quakes),
    total_quakes = sum(n_quakes),
    n_county_months = n(),
    .groups = "drop"
  )
cat("\nPre-treatment summary (2010-2014):\n")
print(pre_summary)

# Save panel
write_csv(panel, "../data/panel_ok.csv")
cat("\nSaved panel_ok.csv\n")

# =============================================================================
# KANSAS PANEL (for replication)
# =============================================================================

cat("\n=== Constructing Kansas county-month panel ===\n")

ks_counties_sf <- readRDS("../data/ks_counties.rds")
all_ks_fips <- ks_counties_sf$GEOID

ks_panel <- expand_grid(
  county_fips = all_ks_fips,
  year_month = months_seq
) |>
  mutate(
    year = year(year_month),
    month = month(year_month),
    ym_numeric = year * 12 + month
  )

ks_quake_counts <- ks_quakes |>
  mutate(year_month = floor_date(as.Date(year_month), "month"),
         county_fips = as.character(county_fips)) |>
  group_by(county_fips, year_month) |>
  summarise(
    n_quakes = n(),
    n_quakes_m3 = sum(mag >= 3.0, na.rm = TRUE),
    .groups = "drop"
  )

ks_panel <- ks_panel |>
  left_join(ks_quake_counts, by = c("county_fips", "year_month")) |>
  mutate(n_quakes = replace_na(n_quakes, 0),
         n_quakes_m3 = replace_na(n_quakes_m3, 0))

# Kansas treatment: KCC orders
# March 2015: Harper (20077), Sumner (20191) counties
# August 2016: expanded to Sedgwick (20173), Kingman (20095), Barber (20007)
ks_treatment <- bind_rows(
  tibble(county_fips = c("20077", "20191"),
         first_treat_date = as.Date("2015-03-01"), wave = 1),
  tibble(county_fips = c("20173", "20095", "20007"),
         first_treat_date = as.Date("2016-08-01"), wave = 2)
)

ks_treatment <- ks_treatment |>
  mutate(first_treat_ym = as.numeric(format(first_treat_date, "%Y")) * 12 +
                          as.numeric(format(first_treat_date, "%m")))

ks_panel <- ks_panel |>
  left_join(ks_treatment |> select(county_fips, first_treat_ym, wave),
            by = "county_fips") |>
  mutate(
    treated_county = !is.na(first_treat_ym),
    first_treat_ym = replace_na(first_treat_ym, 0),
    ihs_quakes = log(n_quakes + sqrt(n_quakes^2 + 1)),
    log_quakes_p1 = log(n_quakes + 1)
  )

# Merge WTI
ks_panel <- ks_panel |>
  left_join(wti_merge, by = "year_month")

# County names
ks_county_names <- ks_counties_sf |>
  st_drop_geometry() |>
  select(county_fips = GEOID, county_name = NAME)

ks_panel <- ks_panel |>
  left_join(ks_county_names, by = "county_fips")

write_csv(ks_panel, "../data/panel_ks.csv")
cat(sprintf("Kansas panel: %d rows, %d treated counties\n",
            nrow(ks_panel),
            sum(ks_panel$treated_county[!duplicated(ks_panel$county_fips)])))

cat("\n=== Data cleaning complete ===\n")
