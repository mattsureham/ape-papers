# 02_clean_data.R — Clean and construct analysis variables
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Loading raw data ===\n")
df_raw <- fread("../data/ghgrp_raw.csv", encoding = "Latin-1")
cat("Raw rows:", nrow(df_raw), "\n")

# Rename key columns to clean names
setnames(df_raw, old = c(
  names(df_raw)[1],   # GHGRP ID
  names(df_raw)[2],   # Reference Year
  names(df_raw)[3],   # Facility Name
  names(df_raw)[6],   # Province
  names(df_raw)[8],   # Latitude
  names(df_raw)[9],   # Longitude
  names(df_raw)[11],  # NAICS Code
  names(df_raw)[12],  # NAICS Description (English)
  names(df_raw)[27],  # CO2 (tonnes)
  names(df_raw)[28],  # CH4 (tonnes)
  names(df_raw)[29],  # CH4 (CO2e)
  names(df_raw)[30],  # N2O (tonnes)
  names(df_raw)[31],  # N2O (CO2e)
  names(df_raw)[76]   # Total Emissions
), new = c(
  "facility_id", "year", "facility_name", "province",
  "lat", "lon", "naics", "naics_desc",
  "co2_tonnes", "ch4_tonnes", "ch4_co2e",
  "n2o_tonnes", "n2o_co2e", "total_co2e"
))

# Select key columns
df <- df_raw[, .(facility_id, year, facility_name, province,
                 lat, lon, naics, naics_desc,
                 co2_tonnes, ch4_tonnes, ch4_co2e,
                 n2o_tonnes, n2o_co2e, total_co2e)]

# Clean types
df[, year := as.integer(year)]
df[, total_co2e := as.numeric(total_co2e)]
df[, co2_tonnes := as.numeric(co2_tonnes)]
df[, ch4_co2e := as.numeric(ch4_co2e)]
df[, n2o_co2e := as.numeric(n2o_co2e)]
df[, naics := as.character(naics)]

# Remove the one empty-province row
df <- df[province != ""]

cat("\n=== Province distribution after cleaning ===\n")
print(table(df$province))

# Define treatment groups
# Backstop provinces: received federal carbon pricing April 2019
backstop_provinces <- c("Ontario", "Saskatchewan", "Manitoba", "New Brunswick")

# Own-pricing provinces: had own carbon pricing before backstop
# BC: carbon tax since 2008
# QC: cap-and-trade since 2013
# AB: SGER since 2007 / CCIR 2018 / TIER 2020
own_pricing_provinces <- c("British Columbia", "Quebec", "Alberta")

df[, treatment_group := fcase(
  province %in% backstop_provinces, "backstop",
  province %in% own_pricing_provinces, "own_pricing",
  default = "other"
)]

# Binary treatment indicator
df[, backstop := as.integer(province %in% backstop_provinces)]
df[, post := as.integer(year >= 2019)]
df[, treat_post := backstop * post]

# Log emissions (handle zeros)
df[, log_co2e := log(pmax(total_co2e, 1))]
df[, log_co2 := log(pmax(co2_tonnes, 1))]

# 2-digit NAICS sector
df[, naics_2d := substr(naics, 1, 2)]

# Sector classification for heterogeneity
df[, sector := fcase(
  naics_2d %in% c("21"), "Mining & Oil/Gas",
  naics_2d %in% c("31", "32", "33"), "Manufacturing",
  naics_2d %in% c("22"), "Utilities",
  naics_2d %in% c("56", "92"), "Waste & Public Admin",
  default = "Other"
)]

cat("\n=== Treatment group distribution ===\n")
print(df[, .N, by = .(treatment_group, year)][order(treatment_group, year)] |>
        dcast(year ~ treatment_group, value.var = "N"))

cat("\n=== Sector distribution ===\n")
print(table(df$sector))

# Focus on main analysis sample: backstop + own-pricing provinces only
df_analysis <- df[treatment_group %in% c("backstop", "own_pricing")]
cat("\n=== Analysis sample ===\n")
cat("Observations:", nrow(df_analysis), "\n")
cat("Unique facilities:", uniqueN(df_analysis$facility_id), "\n")
cat("Year range:", range(df_analysis$year), "\n")

# For balanced panel robustness: identify facilities present pre and post
facility_years <- df_analysis[, .(
  n_years = uniqueN(year),
  first_year = min(year),
  last_year = max(year),
  has_pre = any(year < 2019),
  has_post = any(year >= 2019)
), by = facility_id]

balanced_ids <- facility_years[has_pre == TRUE & has_post == TRUE, facility_id]
cat("Facilities with pre+post data:", length(balanced_ids), "\n")

df_balanced <- df_analysis[facility_id %in% balanced_ids]
cat("Balanced panel observations:", nrow(df_balanced), "\n")

# Save cleaned data
fwrite(df_analysis, "../data/analysis_panel.csv")
fwrite(df_balanced, "../data/balanced_panel.csv")
fwrite(df, "../data/full_panel.csv")

cat("\n=== Saved analysis datasets ===\n")
cat("  analysis_panel.csv:", nrow(df_analysis), "obs\n")
cat("  balanced_panel.csv:", nrow(df_balanced), "obs\n")
cat("  full_panel.csv:", nrow(df), "obs\n")
