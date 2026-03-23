# ==============================================================================
# 02_clean_data.R — Data cleaning and panel construction
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

source("code/00_packages.R")

data_dir <- "data"

# ── 1. Load Raw Data ─────────────────────────────────────────────────────────
cat("Loading data...\n")
plazas_raw <- fread(file.path(data_dir, "toll_plazas_raw.csv"))
plaza_district <- fread(file.path(data_dir, "plaza_district_map.csv"))
mobility <- fread(file.path(data_dir, "india_mobility_all.csv"))
india_districts <- readRDS(file.path(data_dir, "india_districts.rds"))

# ── 2. Clean Toll Plaza Cross-Section ────────────────────────────────────────
cat("Cleaning toll plaza data...\n")

# Extract cross-sectional characteristics per plaza (static values)
plazas_raw[, traffic_num := as.numeric(gsub("[^0-9.]", "", traffic_per_day))]
plazas_raw[, revenue_num := as.numeric(gsub("[^0-9.]", "", cumulative_revenue))]

# Take latest non-missing snapshot for each plaza
plaza_cross <- plazas_raw[order(id, -as.Date(snapshot_date))]
plaza_cross <- plaza_cross[, .SD[1], by = id]

plaza_cross <- plaza_cross[, .(
  id, name, lat, lon,
  traffic_capacity = traffic_num,
  cumulative_revenue = revenue_num,
  capital_cost = as.numeric(gsub("[^0-9.]", "", capital_cost)),
  project_type,
  fee_effective_date,
  date_commercial_operation
)]

# Classify project type
plaza_cross[, project_group := fcase(
  grepl("BOT.*Toll", project_type, ignore.case = TRUE), "BOT (Toll)",
  grepl("Public", project_type, ignore.case = TRUE), "Public Funded",
  grepl("OMT", project_type, ignore.case = TRUE), "OMT",
  default = "Other"
)]

cat(sprintf("  %d unique plazas, traffic data for %d\n",
            nrow(plaza_cross), sum(!is.na(plaza_cross$traffic_capacity))))

# ── 3. Merge Plaza-District Mapping ─────────────────────────────────────────
# One plaza per district mapping (drop border duplicates)
plaza_dist <- plaza_district[!duplicated(id), .(id, state_name, district_name, gid_2)]
plaza_cross <- merge(plaza_cross, plaza_dist, by = "id", all.x = TRUE)

# ── 4. Compute District-Level Treatment Intensity ────────────────────────────
cat("Computing district treatment intensity...\n")

district_treatment <- plaza_cross[!is.na(gid_2), .(
  n_plazas = .N,
  total_traffic_capacity = sum(traffic_capacity, na.rm = TRUE),
  mean_traffic_capacity = mean(traffic_capacity, na.rm = TRUE),
  total_capital = sum(capital_cost, na.rm = TRUE),
  n_bot = sum(project_group == "BOT (Toll)", na.rm = TRUE),
  n_public = sum(project_group == "Public Funded", na.rm = TRUE)
), by = .(gid_2, state_name, district_name)]

cat(sprintf("  %d districts have toll plazas (%.0f%% of %d GADM districts)\n",
            nrow(district_treatment), 100 * nrow(district_treatment) / nrow(india_districts),
            nrow(india_districts)))

# ── 5. Clean Mobility Data ──────────────────────────────────────────────────
cat("Cleaning mobility data...\n")

mobility[, date := as.Date(date)]

# Rename mobility columns for convenience
setnames(mobility,
  c("transit_stations_percent_change_from_baseline",
    "workplaces_percent_change_from_baseline",
    "retail_and_recreation_percent_change_from_baseline",
    "residential_percent_change_from_baseline"),
  c("transit", "workplace", "retail", "residential"),
  skip_absent = TRUE
)

# Create time variables
mobility[, `:=`(
  year = year(date),
  month = month(date),
  week = as.integer(format(date, "%V")),
  year_week = format(date, "%Y-W%V"),
  post_mandate = as.integer(date >= as.Date("2021-02-16")),
  days_to_mandate = as.numeric(date - as.Date("2021-02-16"))
)]

# Event month (relative to Feb 2021)
mobility[, event_month := (year - 2021) * 12 + month - 2]

# Day of week (for weekday FE)
mobility[, dow := weekdays(date)]
mobility[, weekend := as.integer(dow %in% c("Saturday", "Sunday"))]

cat(sprintf("  %d district-days, %d districts, %s to %s\n",
            nrow(mobility), uniqueN(mobility$sub_region_2),
            min(mobility$date), max(mobility$date)))

# ── 6. Match Mobility Districts to GADM Districts ───────────────────────────
cat("Matching mobility districts to GADM...\n")

# Clean district names for matching
mobility[, district_clean := tolower(trimws(sub_region_2))]
district_treatment[, district_clean := tolower(trimws(district_name))]

# Direct merge
mob_merged <- merge(mobility, district_treatment,
                     by.x = c("sub_region_1", "district_clean"),
                     by.y = c("state_name", "district_clean"),
                     all.x = TRUE)

# Districts without plazas get treatment = 0
mob_merged[is.na(n_plazas), `:=`(
  n_plazas = 0L,
  total_traffic_capacity = 0,
  mean_traffic_capacity = 0,
  total_capital = 0,
  n_bot = 0L,
  n_public = 0L
)]

# Create treatment indicators
mob_merged[, `:=`(
  has_plaza = as.integer(n_plazas > 0),
  log_traffic_capacity = log(total_traffic_capacity + 1),
  traffic_std = (total_traffic_capacity - mean(total_traffic_capacity)) /
    sd(total_traffic_capacity)
)]

# Traffic terciles among treated districts
treated_traffic <- mob_merged[has_plaza == 1, unique(total_traffic_capacity)]
q33 <- quantile(treated_traffic, 1/3, na.rm = TRUE)
q67 <- quantile(treated_traffic, 2/3, na.rm = TRUE)
mob_merged[, traffic_tercile := fcase(
  n_plazas == 0, "No Plaza",
  total_traffic_capacity <= q33, "Low Traffic",
  total_traffic_capacity <= q67, "Medium Traffic",
  total_traffic_capacity > q67, "High Traffic",
  default = NA_character_
)]

cat(sprintf("  Matched: %d districts with plazas, %d without\n",
            uniqueN(mob_merged[has_plaza == 1]$sub_region_2),
            uniqueN(mob_merged[has_plaza == 0]$sub_region_2)))

# ── 7. Aggregate to Weekly Level ────────────────────────────────────────────
cat("Aggregating to weekly level...\n")

# Weekly aggregation reduces noise and computational burden
mob_weekly <- mob_merged[, .(
  transit = mean(transit, na.rm = TRUE),
  workplace = mean(workplace, na.rm = TRUE),
  retail = mean(retail, na.rm = TRUE),
  residential = mean(residential, na.rm = TRUE),
  n_days = .N
), by = .(sub_region_1, sub_region_2, gid_2, year_week, year, month,
          event_month, post_mandate, has_plaza, n_plazas,
          total_traffic_capacity, traffic_std, traffic_tercile, log_traffic_capacity)]

cat(sprintf("  Weekly panel: %d district-weeks, %d districts\n",
            nrow(mob_weekly), uniqueN(mob_weekly$sub_region_2)))

# ── 8. Save Cleaned Data ────────────────────────────────────────────────────
fwrite(mob_weekly, file.path(data_dir, "mobility_weekly_panel.csv"))
fwrite(plaza_cross, file.path(data_dir, "plaza_cross_section.csv"))
fwrite(district_treatment, file.path(data_dir, "district_treatment.csv"))

cat("\n=== DATA SUMMARY ===\n")
cat(sprintf("Weekly mobility panel: %d obs, %d districts\n",
            nrow(mob_weekly), uniqueN(mob_weekly$sub_region_2)))
cat(sprintf("Pre-mandate weeks: ~%d | Post-mandate weeks: ~%d\n",
            uniqueN(mob_weekly[post_mandate == 0]$year_week),
            uniqueN(mob_weekly[post_mandate == 1]$year_week)))
cat(sprintf("Districts with plazas: %d | Without: %d\n",
            uniqueN(mob_weekly[has_plaza == 1]$sub_region_2),
            uniqueN(mob_weekly[has_plaza == 0]$sub_region_2)))

# Pre/post mobility summary
cat("\nTransit mobility by treatment group:\n")
print(mob_weekly[, .(
  mean_transit = round(mean(transit, na.rm = TRUE), 1),
  mean_workplace = round(mean(workplace, na.rm = TRUE), 1),
  n_dist = uniqueN(sub_region_2)
), by = .(has_plaza, post_mandate)])

cat("\nData cleaning complete.\n")
