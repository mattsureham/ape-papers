# 02_clean_data.R — Clean and merge force-month panel
# Section 60 Stop-and-Search Relaxation and Knife Crime

source("00_packages.R")

# ── Load raw data ─────────────────────────────────────────────────────────
ss <- fread("../data/ss_force_month.csv")
crime <- fread("../data/crime_force_month.csv")
pop <- fread("../data/force_population.csv")
contiguity <- jsonlite::fromJSON("../data/contiguity.json")

cat(sprintf("Raw S&S: %d records\n", nrow(ss)))
cat(sprintf("Raw crime: %d records\n", nrow(crime)))

# ── Fix force names (remove date prefix from bulk archive filenames) ─────
# Force names have patterns like "2015-02-avon-and-somerset"
# Each represents a different download batch — NOT a geographic sub-area.
# We must keep only ONE batch per force-month to avoid inflating counts.

# Extract date prefix and clean force name
ss[, batch_date := sub("^(\\d{4}-\\d{2})-.*", "\\1", force)]
ss[, force_clean := sub("^\\d{4}-\\d{2}-", "", force)]
ss[, force_clean := sub("^\\d{4}-\\d{2}-", "", force_clean)]
ss[, force_clean := tolower(force_clean)]

crime[, batch_date := sub("^(\\d{4}-\\d{2})-.*", "\\1", force)]
crime[, force_clean := sub("^\\d{4}-\\d{2}-", "", force)]
crime[, force_clean := sub("^\\d{4}-\\d{2}-", "", force_clean)]
crime[, force_clean := tolower(force_clean)]

cat(sprintf("Unique clean forces in S&S: %d\n", uniqueN(ss$force_clean)))
cat(sprintf("Unique clean forces in crime: %d\n", uniqueN(crime$force_clean)))

# Keep only known forces
known_forces <- pop$force
ss <- ss[force_clean %in% known_forces]
crime <- crime[force_clean %in% known_forces]

# Deduplicate: keep only the LATEST batch per force-month
# (latest batch_date has the most current data formatting)
ss[, force := force_clean]
crime[, force := force_clean]

setorder(ss, force, month, -batch_date)
ss_dedup <- ss[, .SD[1], by = .(force, month)]

setorder(crime, force, month, -batch_date)
crime_dedup <- crime[, .SD[1], by = .(force, month)]

cat(sprintf("S&S before dedup: %d, after: %d\n", nrow(ss), nrow(ss_dedup)))
cat(sprintf("Crime before dedup: %d, after: %d\n", nrow(crime), nrow(crime_dedup)))

# Use deduplicated data
ss_agg <- ss_dedup[, .(
  total_stops = total_stops,
  s60_stops = s60_stops,
  weapon_stops = weapon_stops,
  s60_weapon_stops = s60_weapon_stops
), by = .(force, month)]

crime_agg <- crime_dedup[, .(
  weapons_crime = weapons_crime,
  violent_crime = violent_crime,
  shoplifting = shoplifting,
  other_theft = other_theft
), by = .(force, month)]

cat(sprintf("S&S force-months: %d\n", nrow(ss_agg)))
cat(sprintf("Crime force-months: %d\n", nrow(crime_agg)))

# ── Define treatment ──────────────────────────────────────────────────────
cohort1_forces <- c("metropolitan", "west-midlands", "greater-manchester",
                    "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")

all_forces <- pop$force

# ── Create balanced panel ────────────────────────────────────────────────
all_months <- sort(unique(c(ss_agg$month, crime_agg$month)))
panel_grid <- CJ(force = all_forces, month = all_months)

panel <- merge(panel_grid, crime_agg, by = c("force", "month"), all.x = TRUE)
panel <- merge(panel, ss_agg, by = c("force", "month"), all.x = TRUE)
panel <- merge(panel, pop, by = "force", all.x = TRUE)

# Fill NAs with 0
num_cols <- c("weapons_crime", "violent_crime", "shoplifting", "other_theft",
              "total_stops", "s60_stops", "weapon_stops", "s60_weapon_stops")
for (col in num_cols) {
  if (col %in% names(panel)) {
    panel[is.na(get(col)), (col) := 0L]
  }
}

# ── Time and treatment variables ─────────────────────────────────────────
panel[, date := as.Date(paste0(month, "-01"))]
panel[, t := as.integer(difftime(date, as.Date("2017-01-01"), units = "days")) %/% 30]

# Treatment cohorts
panel[, cohort := fifelse(force %in% cohort1_forces, 1L, 2L)]

# First treatment period (for Callaway-Sant'Anna)
g_cohort1 <- as.integer(difftime(as.Date("2019-04-01"), as.Date("2017-01-01"), units = "days")) %/% 30
g_cohort2 <- as.integer(difftime(as.Date("2019-08-01"), as.Date("2017-01-01"), units = "days")) %/% 30

panel[, g := fifelse(cohort == 1L, g_cohort1, g_cohort2)]
panel[, treated := as.integer(t >= g)]

# ── Rates per 100,000 ───────────────────────────────────────────────────
panel[, weapons_rate := (weapons_crime / population) * 100000]
panel[, violent_rate := (violent_crime / population) * 100000]
panel[, theft_rate := (other_theft / population) * 100000]
panel[, shoplifting_rate := (shoplifting / population) * 100000]
panel[, stops_rate := (total_stops / population) * 100000]
panel[, s60_rate := (s60_stops / population) * 100000]

# ── Neighbor classification ──────────────────────────────────────────────
neighbor_of_cohort1 <- character(0)
for (f in cohort1_forces) {
  if (f %in% names(contiguity)) {
    neighbor_of_cohort1 <- c(neighbor_of_cohort1, contiguity[[f]])
  }
}
neighbor_of_cohort1 <- setdiff(unique(neighbor_of_cohort1), cohort1_forces)
panel[, neighbor_cohort1 := as.integer(force %in% neighbor_of_cohort1)]

# ── Numeric force ID ────────────────────────────────────────────────────
panel[, force_id := as.integer(factor(force))]

# ── Filter to analysis window ────────────────────────────────────────────
panel_analysis <- panel[date >= as.Date("2018-01-01") & date <= as.Date("2020-02-01")]

# Remove city-of-london (population 9K, extreme rate outlier)
panel_analysis <- panel_analysis[force != "city-of-london"]

# Recalculate force_id after removal
panel_analysis[, force_id := as.integer(factor(force))]

cat(sprintf("\n=== ANALYSIS PANEL ===\n"))
cat(sprintf("Force-months: %d\n", nrow(panel_analysis)))
cat(sprintf("Forces: %d\n", uniqueN(panel_analysis$force)))
cat(sprintf("Months: %d\n", uniqueN(panel_analysis$month)))
cat(sprintf("Cohort 1: %d forces\n", uniqueN(panel_analysis[cohort == 1]$force)))
cat(sprintf("Cohort 2: %d forces\n", uniqueN(panel_analysis[cohort == 2]$force)))
cat(sprintf("Neighbors of Cohort 1: %d\n", length(neighbor_of_cohort1)))

# ── Pre-period summary ───────────────────────────────────────────────────
pre <- panel_analysis[date < as.Date("2019-04-01")]
cat(sprintf("\n=== PRE-PERIOD SUMMARY ===\n"))
cat(sprintf("Mean weapons rate: %.2f per 100K/month\n", mean(pre$weapons_rate, na.rm = TRUE)))
cat(sprintf("SD weapons rate: %.2f\n", sd(pre$weapons_rate, na.rm = TRUE)))
cat(sprintf("Mean violent rate: %.2f\n", mean(pre$violent_rate, na.rm = TRUE)))
cat(sprintf("Mean S60 rate: %.2f\n", mean(pre$s60_rate, na.rm = TRUE)))
cat(sprintf("Mean total stops rate: %.2f\n", mean(pre$stops_rate, na.rm = TRUE)))

# Cohort comparison
cat(sprintf("\nCohort 1 mean weapons rate: %.2f\n",
            mean(pre[cohort == 1]$weapons_rate, na.rm = TRUE)))
cat(sprintf("Cohort 2 mean weapons rate: %.2f\n",
            mean(pre[cohort == 2]$weapons_rate, na.rm = TRUE)))

# ── Save ─────────────────────────────────────────────────────────────────
fwrite(panel_analysis, "../data/panel_analysis.csv")
cat("\nSaved panel_analysis.csv\n")
