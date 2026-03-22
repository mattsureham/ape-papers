# 02_clean_data.R — Clean and construct LA-quarter panel for DiD analysis
# Wales 20mph Speed Limit and Road Safety (apep_0744)

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Load raw collision data
# ============================================================================

collisions <- fread(file.path(data_dir, "collisions_2020_2024.csv"))
cat(sprintf("Loaded %s collisions\n", format(nrow(collisions), big.mark = ",")))

# ============================================================================
# Identify Welsh vs English LAs using ONS district codes
# Welsh LAs have codes starting with W (W06...)
# English LAs have codes starting with E
# ============================================================================

collisions[, country := fifelse(
  grepl("^W", local_authority_ons_district), "Wales",
  fifelse(grepl("^E", local_authority_ons_district), "England", "Other")
)]

country_counts <- collisions[, .N, by = country]
cat("\nCollisions by country:\n")
print(country_counts)

# Keep only England and Wales (drop Scotland and Other)
collisions <- collisions[country %in% c("England", "Wales")]
cat(sprintf("\nAfter filtering to England/Wales: %s collisions\n",
            format(nrow(collisions), big.mark = ",")))

# ============================================================================
# Parse dates and create quarter variable
# ============================================================================

collisions[, date_parsed := as.Date(date, format = "%d/%m/%Y")]
# Handle alternate format
collisions[is.na(date_parsed), date_parsed := as.Date(date, format = "%Y-%m-%d")]

stopifnot(sum(is.na(collisions$date_parsed)) / nrow(collisions) < 0.01)
collisions <- collisions[!is.na(date_parsed)]

collisions[, year := year(date_parsed)]
collisions[, quarter := quarter(date_parsed)]
collisions[, year_quarter := sprintf("%dQ%d", year, quarter)]

# ============================================================================
# Speed limit categories
# ============================================================================

# The policy changed default 30mph → 20mph on restricted roads
# Key categories:
#   - "low_speed" (20 + 30 mph): these are the affected road category
#   - "high_speed" (40+ mph): placebo roads, unaffected
collisions[, speed_cat := fifelse(speed_limit <= 30, "low_speed", "high_speed")]

# Finer categories for mechanism analysis
collisions[, speed_detail := fcase(
  speed_limit == 20, "20mph",
  speed_limit == 30, "30mph",
  speed_limit >= 40, "40plus",
  default = "other"
)]

# ============================================================================
# Severity categories
# ============================================================================

# STATS19 severity: 1 = Fatal, 2 = Serious, 3 = Slight
collisions[, severity_label := fcase(
  accident_severity == 1, "fatal",
  accident_severity == 2, "serious",
  accident_severity == 3, "slight",
  default = "unknown"
)]

collisions[, killed_or_serious := as.integer(accident_severity <= 2)]

# ============================================================================
# LA name lookup
# ============================================================================

la_key <- unique(collisions[, .(la_code = local_authority_ons_district, country)])
cat(sprintf("\nUnique LAs: %d (%d Welsh, %d English)\n",
            nrow(la_key),
            sum(la_key$country == "Wales"),
            sum(la_key$country == "England")))

# ============================================================================
# Construct LA × quarter × speed_cat panel
# ============================================================================

# Treatment: Welsh LAs, post September 2023
# Treatment date is 17 September 2023
# For quarterly data: 2023Q4 is the first full post-treatment quarter
# (2023Q3 is partially treated — Sep 17 to Sep 30 — drop or treat as transition)

# Create numeric quarter index for panel
qtr_grid <- data.table(expand.grid(
  year = 2020:2024,
  quarter = 1:4
))
qtr_grid <- qtr_grid[year < 2024 | quarter <= 4]  # keep all available
qtr_grid[, year_quarter := sprintf("%dQ%d", year, quarter)]
qtr_grid[, qtr_idx := .I]
qtr_grid[, post := as.integer(year > 2023 | (year == 2023 & quarter >= 4))]

# Aggregate collisions to LA × quarter × speed_cat
panel_full <- collisions[, .(
  n_collisions    = .N,
  n_casualties    = sum(number_of_casualties, na.rm = TRUE),
  n_fatal         = sum(accident_severity == 1),
  n_serious       = sum(accident_severity == 2),
  n_slight        = sum(accident_severity == 3),
  n_ksi           = sum(killed_or_serious)
), by = .(la_code = local_authority_ons_district, country,
          year, quarter, year_quarter, speed_cat)]

# Merge quarter index
panel_full <- merge(panel_full, qtr_grid[, .(year_quarter, qtr_idx, post)],
                    by = "year_quarter", all.x = TRUE)

# Treatment indicator
panel_full[, welsh := as.integer(country == "Wales")]
panel_full[, treat := welsh * post]

# ============================================================================
# Balance panel — ensure all LA × quarter × speed_cat combinations exist
# ============================================================================

all_las <- unique(panel_full$la_code)
all_qtrs <- unique(qtr_grid$year_quarter)
all_cats <- c("low_speed", "high_speed")

balanced <- CJ(la_code = all_las, year_quarter = all_qtrs, speed_cat = all_cats)
balanced <- merge(balanced, la_key, by = "la_code", all.x = TRUE)
balanced <- merge(balanced, qtr_grid[, .(year_quarter, year, quarter, qtr_idx, post)],
                  by = "year_quarter", all.x = TRUE)

panel <- merge(balanced, panel_full[, .(la_code, year_quarter, speed_cat,
                                         n_collisions, n_casualties,
                                         n_fatal, n_serious, n_slight, n_ksi)],
               by = c("la_code", "year_quarter", "speed_cat"), all.x = TRUE)

# Fill NAs with 0 (no collisions in that cell)
cols_fill <- c("n_collisions", "n_casualties", "n_fatal", "n_serious", "n_slight", "n_ksi")
for (col in cols_fill) {
  set(panel, which(is.na(panel[[col]])), col, 0L)
}

panel[, welsh := as.integer(country == "Wales")]
panel[, treat := welsh * post]

# ============================================================================
# Also create the overall (all speed categories combined) panel
# ============================================================================

panel_total <- panel[, .(
  n_collisions = sum(n_collisions),
  n_casualties = sum(n_casualties),
  n_fatal      = sum(n_fatal),
  n_serious    = sum(n_serious),
  n_slight     = sum(n_slight),
  n_ksi        = sum(n_ksi)
), by = .(la_code, country, year_quarter, year, quarter, qtr_idx, post, welsh)]
panel_total[, treat := welsh * post]
panel_total[, speed_cat := "all"]

# ============================================================================
# Create event-time variable for event study
# ============================================================================

# Treatment quarter: 2023Q4 (first full post-treatment quarter)
# Event time: quarters relative to 2023Q4
treat_qtr_idx <- qtr_grid[year_quarter == "2023Q4", qtr_idx]

panel[, event_time := qtr_idx - treat_qtr_idx]
panel_total[, event_time := qtr_idx - treat_qtr_idx]

# ============================================================================
# Identify border Welsh and English LAs for border subsample
# ============================================================================

# Welsh border LAs (those sharing the England-Wales border)
welsh_border_codes <- c(
  "W06000005",  # Flintshire
  "W06000006",  # Wrexham
  "W06000019",  # Powys
  "W06000024",  # Monmouthshire
  "W06000020"   # Newport (near border)
)

# English border LAs (counties/UAs adjacent to Wales)
english_border_codes <- c(
  "E06000049",  # Cheshire East
  "E06000050",  # Cheshire West and Chester
  "E06000051",  # Shropshire
  "E06000019",  # Herefordshire
  "E10000013",  # Gloucestershire (county)
  "E06000025"   # South Gloucestershire
)

panel[, border := as.integer(la_code %in% c(welsh_border_codes, english_border_codes))]
panel_total[, border := as.integer(la_code %in% c(welsh_border_codes, english_border_codes))]

# ============================================================================
# Save panels
# ============================================================================

fwrite(panel, file.path(data_dir, "panel_la_quarter_speedcat.csv"))
fwrite(panel_total, file.path(data_dir, "panel_la_quarter_total.csv"))

cat(sprintf("\n=== Panel Summary ===\n"))
cat(sprintf("Panel (by speed cat): %s rows\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Panel (total):        %s rows\n", format(nrow(panel_total), big.mark = ",")))
cat(sprintf("LAs: %d Welsh, %d English\n",
            length(unique(panel[welsh == 1, la_code])),
            length(unique(panel[welsh == 0, la_code]))))
cat(sprintf("Quarters: %d (%s to %s)\n",
            length(unique(panel$year_quarter)),
            min(panel$year_quarter), max(panel$year_quarter)))
cat(sprintf("Post-treatment quarters: %d\n", sum(unique(qtr_grid$post))))
cat(sprintf("Border LAs: %d Welsh, %d English\n",
            sum(unique(panel[border == 1 & welsh == 1, la_code]) != ""),
            sum(unique(panel[border == 1 & welsh == 0, la_code]) != "")))
