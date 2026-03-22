# 02_clean_data.R — Clean FARS data and compute distance to TZ boundaries
# apep_0730: Time Zone Boundaries and Teen Morning Traffic Deaths

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Loading raw data ===\n")
accidents <- fread("fars_accidents_2010_2023.csv")
persons <- fread("fars_persons_2010_2023.csv")

# --- Define time zone boundaries ---
# Three continental US boundaries (approximate longitudes):
# Eastern/Central: ~86.5°W (varies by state, but this is the modal boundary)
# Central/Mountain: ~104.05°W
# Mountain/Pacific: ~115.0°W

# More precise: use state FIPS to assign actual TZ, then compute distance
# to nearest boundary using longitude

# State-level TZ assignments (dominant TZ for border states)
# States touching Eastern/Central boundary:
ec_boundary <- data.table(
  boundary = "EC",
  # Eastern side states (FIPS)
  east_states = list(c(13, 17, 18, 21, 26, 39, 47)),  # GA, IL, IN, KY, MI, OH, TN
  # Central side states
  west_states = list(c(1, 19, 22, 27, 28, 29, 38, 46, 55))  # AL, IA, LA, MN, MS, MO, ND, SD, WI
)

# Actually, let's use a more precise approach:
# Assign each crash to a TZ based on its longitude and state,
# then compute distance to the nearest TZ boundary

# Time zone boundaries as longitude lines (simplified but accurate for RDD)
# These are the approximate longitudes where boundaries run
tz_boundaries <- data.table(
  boundary_id = c("EC", "CM", "MP"),
  boundary_name = c("Eastern/Central", "Central/Mountain", "Mountain/Pacific"),
  approx_lon = c(-86.5, -104.05, -115.0)
)

cat("=== Cleaning accident data ===\n")

# FARS encodes longitude as positive in some years, negative in others
# Also uses 99.9999 or 999 as missing values
# LONGITUD should be negative for US (western hemisphere)

# Fix longitude sign issues
accidents[, lon := ifelse(LONGITUD > 0 & LONGITUD < 180, -LONGITUD, LONGITUD)]
# Some FARS years store as positive values > 60
accidents[LONGITUD > 60 & LONGITUD < 180, lon := -LONGITUD]
# Keep original if already negative
accidents[LONGITUD < 0 & LONGITUD > -180, lon := LONGITUD]

accidents[, lat := LATITUDE]

# Filter to valid continental US coordinates
accidents <- accidents[lat > 24 & lat < 50 & lon > -125 & lon < -66]
cat(sprintf("Crashes with valid continental US coords: %d\n", nrow(accidents)))

# --- Compute distance to nearest TZ boundary ---
# For each crash, find the nearest TZ boundary and compute signed distance
# Positive = west (late-sunset side), Negative = east (early-sunset side)

accidents[, `:=`(
  dist_EC = lon - (-86.5),    # negative = east of EC boundary
  dist_CM = lon - (-104.05),
  dist_MP = lon - (-115.0)
)]

# Find nearest boundary
accidents[, `:=`(
  abs_dist_EC = abs(dist_EC),
  abs_dist_CM = abs(dist_CM),
  abs_dist_MP = abs(dist_MP)
)]

accidents[, nearest_boundary := ifelse(
  abs_dist_EC <= abs_dist_CM & abs_dist_EC <= abs_dist_MP, "EC",
  ifelse(abs_dist_CM <= abs_dist_MP, "CM", "MP")
)]

accidents[, dist_to_boundary := ifelse(
  nearest_boundary == "EC", dist_EC,
  ifelse(nearest_boundary == "CM", dist_CM, dist_MP)
)]

# Late-sunset indicator (west of boundary = negative longitude = more negative)
# West side has MORE NEGATIVE longitude (further west)
# dist_to_boundary < 0 means west of boundary (late-sunset side)
accidents[, late_sunset := as.integer(dist_to_boundary < 0)]

# Convert distance from degrees to approximate km (1° longitude ≈ 85km at 40°N)
accidents[, dist_km := dist_to_boundary * 85]

cat(sprintf("Crashes near EC boundary (±2°): %d\n",
            nrow(accidents[nearest_boundary == "EC" & abs(dist_to_boundary) < 2])))
cat(sprintf("Crashes near CM boundary (±2°): %d\n",
            nrow(accidents[nearest_boundary == "CM" & abs(dist_to_boundary) < 2])))
cat(sprintf("Crashes near MP boundary (±2°): %d\n",
            nrow(accidents[nearest_boundary == "MP" & abs(dist_to_boundary) < 2])))

# --- Merge person data to get age information ---
cat("\n=== Merging person data ===\n")

# Count fatalities by age group per crash
# PER_TYP: 1 = driver, 2 = passenger, others = non-occupants
# INJ_SEV: 4 = fatal

fatal_persons <- persons[INJ_SEV == 4]
fatal_persons[, age_group := fcase(
  AGE >= 15 & AGE <= 19, "teen",
  AGE >= 20 & AGE <= 64, "adult",
  AGE >= 65,             "elderly",
  default = "other"
)]

# Count teen and adult fatalities per crash
teen_fatal <- fatal_persons[age_group == "teen", .(n_teen_fatal = .N), by = .(STATE, ST_CASE, YEAR)]
adult_fatal <- fatal_persons[age_group == "adult", .(n_adult_fatal = .N), by = .(STATE, ST_CASE, YEAR)]

accidents <- merge(accidents, teen_fatal, by = c("STATE", "ST_CASE", "YEAR"), all.x = TRUE)
accidents <- merge(accidents, adult_fatal, by = c("STATE", "ST_CASE", "YEAR"), all.x = TRUE)
accidents[is.na(n_teen_fatal), n_teen_fatal := 0]
accidents[is.na(n_adult_fatal), n_adult_fatal := 0]

# --- Time of day classification ---
# HOUR: 0-23 (99 = unknown)
# Morning commute: 6-9 AM
# Evening commute: 3-7 PM
# Night: 10 PM - 5 AM

accidents[, time_period := fcase(
  HOUR >= 6 & HOUR <= 9,   "morning",
  HOUR >= 15 & HOUR <= 19, "evening",
  HOUR >= 22 | HOUR <= 5,  "night",
  HOUR == 99,              "unknown",
  default = "midday"
)]

accidents[, morning := as.integer(time_period == "morning")]
accidents[, evening := as.integer(time_period == "evening")]

# Create key outcome variables
accidents[, teen_morning_fatal := as.integer(n_teen_fatal > 0 & morning == 1)]
accidents[, any_morning_fatal := as.integer(morning == 1)]
accidents[, teen_fatal := as.integer(n_teen_fatal > 0)]

# Weekend indicator
accidents[, weekend := as.integer(DAY_WEEK %in% c(1, 7))]  # 1=Sunday, 7=Saturday

# Lighting condition (proxy for darkness)
# LGT_COND: 1=daylight, 2=dark, 3=dark-lighted, 4=dawn, 5=dusk
accidents[, dark := as.integer(LGT_COND %in% c(2, 3))]

cat(sprintf("\n=== Summary statistics ===\n"))
cat(sprintf("Total crashes (continental US, 2010-2023): %d\n", nrow(accidents)))
cat(sprintf("Morning crashes: %d\n", sum(accidents$morning)))
cat(sprintf("Morning crashes with teen fatality: %d\n", sum(accidents$teen_morning_fatal)))
cat(sprintf("Morning crashes with adult fatality: %d\n",
            sum(accidents$morning == 1 & accidents$n_adult_fatal > 0)))

# --- RDD analysis sample: restrict to near-boundary crashes ---
# Primary bandwidth: 1.5 degrees (~127 km)
bandwidth <- 1.5
rdd_sample <- accidents[abs(dist_to_boundary) <= bandwidth]

cat(sprintf("\nRDD sample (±%.1f° = ±%.0fkm): %d crashes\n",
            bandwidth, bandwidth * 85, nrow(rdd_sample)))
cat(sprintf("  Morning: %d\n", sum(rdd_sample$morning)))
cat(sprintf("  Morning + teen fatal: %d\n", sum(rdd_sample$teen_morning_fatal)))
cat(sprintf("  Late-sunset side: %d (%.1f%%)\n",
            sum(rdd_sample$late_sunset),
            100 * mean(rdd_sample$late_sunset)))

# --- Create FIPS code for county-level aggregation ---
accidents[, fips := sprintf("%02d%03d", STATE, COUNTY)]

# Save cleaned data
fwrite(accidents, "fars_cleaned.csv")
fwrite(rdd_sample, "rdd_sample.csv")

cat("\n=== Cleaned data saved ===\n")
