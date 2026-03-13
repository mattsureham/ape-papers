## 02_clean_data.R — Clean STATS19 data and construct LA-month panel
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data/"

## ------------------------------------------------------------------
## 1. Load raw data
## ------------------------------------------------------------------
collisions <- fread(file.path(data_dir, "collisions_raw.csv"))
casualties <- fread(file.path(data_dir, "casualties_raw.csv"))

cat("Loaded", nrow(collisions), "collisions and", nrow(casualties), "casualties\n")

## ------------------------------------------------------------------
## 2. Parse dates and identify country
## ------------------------------------------------------------------

# Parse date — STATS19 uses DD/MM/YYYY format
collisions[, date := as.Date(date, format = "%d/%m/%Y")]
# Fallback: try other formats if many NAs
if (sum(is.na(collisions$date)) > nrow(collisions) * 0.5) {
  collisions[, date := as.Date(date, format = "%Y-%m-%d")]
}
stopifnot("Date parsing failed for >10% of records" =
            sum(is.na(collisions$date)) < nrow(collisions) * 0.1)

collisions[, `:=`(
  year  = year(date),
  month = month(date),
  ym    = format(date, "%Y-%m")
)]

# Identify country from local_authority_ons_district code
# W = Wales, E = England, S = Scotland
la_col <- intersect(
  c("local_authority_ons_district", "local_authority_ons_district_code",
    "lsoa_of_collision_location"),
  names(collisions)
)

if (length(la_col) > 0) {
  la_col <- la_col[1]
  cat("Using LA column:", la_col, "\n")
} else {
  # Try to identify from police_force codes
  cat("No LA column found. Will identify Wales from police_force codes.\n")
  la_col <- NULL
}

# Identify Welsh collisions
if (!is.null(la_col)) {
  collisions[, country := fcase(
    grepl("^W", get(la_col)), "Wales",
    grepl("^E", get(la_col)), "England",
    grepl("^S", get(la_col)), "Scotland",
    default = "Unknown"
  )]
  collisions[, la_code := get(la_col)]
} else {
  # Fallback: use police_force codes (60-63 = Welsh forces)
  collisions[, country := fcase(
    police_force %in% c(60, 61, 62, 63), "Wales",
    police_force %in% 1:55, "England",
    police_force %in% c(91, 92, 93, 94, 95, 96, 97, 98, 99), "Scotland",
    default = "Unknown"
  )]
  collisions[, la_code := paste0(police_force, "_", collision_year)]
}

cat("Country distribution:\n")
print(table(collisions$country, useNA = "always"))

## ------------------------------------------------------------------
## 3. Filter to England and Wales only (exclude Scotland)
## ------------------------------------------------------------------
collisions <- collisions[country %in% c("England", "Wales")]
cat("After filtering to E&W:", nrow(collisions), "collisions\n")

## ------------------------------------------------------------------
## 4. Exclude COVID period (March 2020 - June 2021)
## ------------------------------------------------------------------
collisions[, covid_period := (date >= as.Date("2020-03-01") &
                                date <= as.Date("2021-06-30"))]
cat("COVID period collisions:", sum(collisions$covid_period), "\n")
collisions <- collisions[covid_period == FALSE]
cat("After excluding COVID:", nrow(collisions), "collisions\n")

## ------------------------------------------------------------------
## 5. Define treatment variables
## ------------------------------------------------------------------
treatment_date <- as.Date("2023-09-17")

collisions[, `:=`(
  welsh    = as.integer(country == "Wales"),
  post     = as.integer(date >= treatment_date),
  treated  = as.integer(country == "Wales" & date >= treatment_date)
)]

# Relative month (0 = September 2023)
collisions[, rel_month := (year - 2023) * 12L + (month - 9L)]

## ------------------------------------------------------------------
## 6. Define severity variables
## ------------------------------------------------------------------
# collision_severity: 1 = Fatal, 2 = Serious, 3 = Slight
collisions[, `:=`(
  fatal   = as.integer(collision_severity == 1),
  serious = as.integer(collision_severity == 2),
  slight  = as.integer(collision_severity == 3),
  ksi     = as.integer(collision_severity %in% c(1, 2))
)]

## ------------------------------------------------------------------
## 7. Define road type variables
## ------------------------------------------------------------------
# speed_limit field: the posted speed limit at the collision location
collisions[, `:=`(
  restricted_road = as.integer(speed_limit %in% c(20, 30)),
  high_speed_road = as.integer(speed_limit >= 40)
)]

## ------------------------------------------------------------------
## 8. Merge pedestrian casualty indicator from casualty table
## ------------------------------------------------------------------
# casualty_type: 0 = Pedestrian, 1 = Cyclist, etc.
if ("casualty_type" %in% names(casualties)) {
  ped_collisions <- casualties[casualty_type == 0,
                                .(n_ped_casualties = .N,
                                  n_ped_ksi = sum(casualty_severity %in% c(1, 2))),
                                by = collision_index]
  collisions <- merge(collisions, ped_collisions, by = "collision_index", all.x = TRUE)
  collisions[is.na(n_ped_casualties), n_ped_casualties := 0L]
  collisions[is.na(n_ped_ksi), n_ped_ksi := 0L]
  collisions[, has_ped_casualty := as.integer(n_ped_casualties > 0)]
  collisions[, has_ped_ksi := as.integer(n_ped_ksi > 0)]
} else {
  cat("WARNING: casualty_type not found. Pedestrian analysis limited.\n")
  collisions[, `:=`(has_ped_casualty = NA_integer_, has_ped_ksi = NA_integer_)]
}

## ------------------------------------------------------------------
## 9. Identify border LAs
## ------------------------------------------------------------------
# Welsh LAs bordering England
welsh_border_las <- c(
  "W06000005",  # Flintshire
  "W06000006",  # Denbighshire
  "W06000003",  # Conwy (near border)
  "W06000001",  # Isle of Anglesey (not bordering, but control)
  "W06000011",  # Wrexham
  "W06000019",  # Powys
  "W06000020",  # Monmouthshire
  "W06000021",  # Newport
  "W06000023"   # Blaenau Gwent (near border)
)

# English LAs bordering Wales
english_border_las <- c(
  "E06000051",  # Shropshire
  "E06000019",  # Herefordshire
  "E06000049",  # Cheshire West and Chester
  "E10000015",  # Gloucestershire
  "E06000050"   # Cheshire East
)

collisions[, border_la := as.integer(
  la_code %in% c(welsh_border_las, english_border_las)
)]

## ------------------------------------------------------------------
## 10. Collapse to LA-month panel
## ------------------------------------------------------------------
panel <- collisions[, .(
  n_collisions     = .N,
  n_fatal          = sum(fatal),
  n_serious        = sum(serious),
  n_slight         = sum(slight),
  n_ksi            = sum(ksi),
  n_ped_collisions = sum(has_ped_casualty, na.rm = TRUE),
  n_ped_ksi        = sum(has_ped_ksi, na.rm = TRUE),
  n_restricted     = sum(restricted_road),
  n_highspeed      = sum(high_speed_road),
  n_ksi_restricted = sum(ksi * restricted_road),
  welsh            = first(welsh),
  country          = first(country),
  post             = first(post),
  border_la        = first(border_la),
  rel_month        = first(rel_month)
), by = .(la_code, year, month)]

# Create year-month factor for FE
panel[, ym := factor(paste0(year, "-", sprintf("%02d", month)))]
panel[, la_factor := factor(la_code)]

# Add log outcomes (with +1 to handle zeros)
panel[, `:=`(
  log_collisions = log(n_collisions + 1),
  log_ksi        = log(n_ksi + 1),
  log_ped_ksi    = log(n_ped_ksi + 1)
)]

cat("Panel dimensions:", nrow(panel), "LA-months\n")
cat("Unique LAs:", uniqueN(panel$la_code), "\n")
cat("Welsh LAs:", uniqueN(panel[welsh == 1]$la_code), "\n")
cat("English LAs:", uniqueN(panel[welsh == 0]$la_code), "\n")
cat("Date range:", as.character(min(as.character(panel$ym))), "to",
    as.character(max(as.character(panel$ym))), "\n")
cat("Pre-treatment obs:", sum(panel$post == 0), "\n")
cat("Post-treatment obs:", sum(panel$post == 1), "\n")

## ------------------------------------------------------------------
## 11. Save panel
## ------------------------------------------------------------------
fwrite(panel, file.path(data_dir, "la_month_panel.csv"))
cat("LA-month panel saved.\n")

## ------------------------------------------------------------------
## 12. Summary statistics for paper
## ------------------------------------------------------------------
sumstats <- panel[, .(
  mean_collisions = mean(n_collisions),
  sd_collisions   = sd(n_collisions),
  mean_ksi        = mean(n_ksi),
  sd_ksi          = sd(n_ksi),
  mean_ped_ksi    = mean(n_ped_ksi),
  sd_ped_ksi      = sd(n_ped_ksi),
  n_lamonths      = .N
), by = .(country, period = ifelse(post == 1, "Post", "Pre"))]

cat("\n=== Summary Statistics ===\n")
print(sumstats)

fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))
