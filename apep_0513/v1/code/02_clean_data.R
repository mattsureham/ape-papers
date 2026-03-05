## 02_clean_data.R — Construct analysis panels
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load Raw Data
# ============================================================
cat("=== Loading raw data ===\n")

collisions <- fread(file.path(data_dir, "collisions_all_years.csv"))
casualties <- fread(file.path(data_dir, "casualties_all_years.csv"))

cat(sprintf("  Collisions: %s rows\n", format(nrow(collisions), big.mark = ",")))
cat(sprintf("  Casualties: %s rows\n", format(nrow(casualties), big.mark = ",")))

# ============================================================
# 2. Clean Collision Data
# ============================================================
cat("\n=== Cleaning collision data ===\n")

# Parse dates
collisions[, date := as.Date(date)]
collisions[, year := year(date)]
collisions[, month := month(date)]
collisions[, ym := as.Date(sprintf("%d-%02d-01", year, month))]

# Filter to 2019-2024 (analysis window)
collisions <- collisions[year >= 2019]
cat(sprintf("  After filtering to 2019+: %s rows\n", format(nrow(collisions), big.mark = ",")))

# Convert speed_limit to numeric (it's character in the CSV)
collisions[, speed_limit := suppressWarnings(as.integer(speed_limit))]

# Ensure nation is assigned
welsh_forces <- c("Dyfed-Powys", "Gwent", "North Wales", "South Wales")
scottish_forces <- c("Police Scotland", "Central", "Dumfries and Galloway",
                      "Fife", "Grampian", "Lothian and Borders", "Northern",
                      "Strathclyde", "Tayside")

# Always reassign nation from police_force (overwrite any cached values)
if ("police_force" %in% names(collisions)) {
  collisions[, nation := fifelse(
    police_force %in% welsh_forces, "Wales",
    fifelse(police_force %in% scottish_forces, "Scotland", "England")
  )]
}

# Drop Scotland for main analysis (keep for placebo)
collisions_gb <- copy(collisions)
collisions <- collisions[nation %in% c("Wales", "England")]

# Speed limit categories
collisions[, speed_cat := fcase(
  speed_limit %in% c(20, 30), "20-30mph",
  speed_limit %in% c(40, 50), "40-50mph",
  speed_limit %in% c(60, 70), "60-70mph",
  default = "other"
)]

# Treatment variable
collisions[, welsh := as.integer(nation == "Wales")]
collisions[, post := as.integer(date >= as.Date("2023-09-17"))]
collisions[, treat := welsh * post]

# Severity mapping
sev_col <- intersect(c("collision_severity", "accident_severity"), names(collisions))
if (length(sev_col) > 0) {
  collisions[, severity := get(sev_col[1])]
} else {
  collisions[, severity := NA_character_]
}

# Police force area as cluster variable
if ("police_force" %in% names(collisions)) {
  collisions[, pfa := police_force]
}

# LA code
la_col <- intersect(c("local_authority_highway_current",
                       "local_authority_ons_district",
                       "local_authority_district"), names(collisions))
if (length(la_col) > 0) {
  collisions[, la_code := get(la_col[1])]
}

cat(sprintf("  England collisions: %s\n", format(nrow(collisions[nation == "England"]), big.mark = ",")))
cat(sprintf("  Wales collisions: %s\n", format(nrow(collisions[nation == "Wales"]), big.mark = ",")))

# ============================================================
# 3. Build Police Force × Month Panel
# ============================================================
cat("\n=== Building PFA × Month panel ===\n")

# Aggregate to PFA × month for main DiD
pfa_month <- collisions[
  !is.na(pfa) & speed_cat == "20-30mph",
  .(
    collisions = .N,
    fatal = sum(severity == "Fatal", na.rm = TRUE),
    serious = sum(severity == "Serious", na.rm = TRUE),
    slight = sum(severity == "Slight", na.rm = TRUE),
    ksi = sum(severity %in% c("Fatal", "Serious"), na.rm = TRUE)
  ),
  by = .(pfa, nation, welsh, ym, year, month)
]

# Create balanced panel with CJ (cross join)
all_pfas <- unique(pfa_month[, .(pfa, nation, welsh)])
all_months <- data.table(ym = seq(as.Date("2019-01-01"), as.Date("2024-12-01"), by = "month"))
all_months[, year := year(ym)]
all_months[, month := month(ym)]
grid <- CJ(pfa = all_pfas$pfa, ym = all_months$ym)
grid <- merge(grid, all_pfas, by = "pfa")
grid <- merge(grid, all_months[, .(ym, year, month)], by = "ym")

# Merge collision counts into the grid
pfa_month <- merge(grid, pfa_month[, .(pfa, ym, collisions, fatal, serious, slight, ksi)],
                   by = c("pfa", "ym"), all.x = TRUE)

# Fill NAs with zeros (no collisions in that PFA-month)
for (col in c("collisions", "fatal", "serious", "slight", "ksi")) {
  set(pfa_month, which(is.na(pfa_month[[col]])), col, 0L)
}

# Add treatment indicators
pfa_month[, post := as.integer(ym >= as.Date("2023-09-01"))]
pfa_month[, treat := welsh * post]

# Log transform (adding 1 for zeros)
pfa_month[, log_collisions := log(collisions + 1)]
pfa_month[, log_ksi := log(ksi + 1)]

cat(sprintf("  PFA × month panel: %d rows, %d PFAs, %d months\n",
            nrow(pfa_month), n_distinct(pfa_month$pfa), n_distinct(pfa_month$ym)))
cat(sprintf("  Welsh PFAs: %d | English PFAs: %d\n",
            n_distinct(pfa_month[welsh == 1]$pfa),
            n_distinct(pfa_month[welsh == 0]$pfa)))

# ============================================================
# 4. Build Placebo Panel (40+ mph roads)
# ============================================================
cat("\n=== Building Placebo panel (40+ mph roads) ===\n")

placebo_pfa <- collisions[
  !is.na(pfa) & speed_cat %in% c("40-50mph", "60-70mph"),
  .(
    collisions = .N,
    ksi = sum(severity %in% c("Fatal", "Serious"), na.rm = TRUE)
  ),
  by = .(pfa, nation, welsh, ym, year, month)
]
placebo_pfa[, post := as.integer(ym >= as.Date("2023-09-01"))]
placebo_pfa[, treat := welsh * post]
placebo_pfa[, log_collisions := log(collisions + 1)]

cat(sprintf("  Placebo panel: %d rows\n", nrow(placebo_pfa)))

# ============================================================
# 5. Build Scottish Placebo Panel
# ============================================================
cat("\n=== Building Scottish placebo panel ===\n")

# Filter GB data to 2019+ and fix speed_limit
collisions_gb <- collisions_gb[year(date) >= 2019]
collisions_gb[, speed_limit := suppressWarnings(as.integer(speed_limit))]

scot_panel <- collisions_gb[
  nation %in% c("Scotland", "England") & !is.na(speed_limit) & speed_limit %in% c(20L, 30L),
  .(collisions = .N),
  by = .(pfa = police_force, nation, ym = as.Date(sprintf("%d-%02d-01", year(date), month(date))))
]
scot_panel[, scottish := as.integer(nation == "Scotland")]
scot_panel[, post := as.integer(ym >= as.Date("2023-09-01"))]
scot_panel[, treat := scottish * post]
scot_panel[, log_collisions := log(collisions + 1)]

cat(sprintf("  Scottish placebo panel: %d rows\n", nrow(scot_panel)))

# ============================================================
# 6. Build Event Study Panel
# ============================================================
cat("\n=== Building event study indicators ===\n")

# Relative month indicator (0 = September 2023)
treat_date <- as.Date("2023-09-01")
pfa_month[, rel_month := as.integer(round(difftime(ym, treat_date, units = "days") / 30.44))]

# Bin endpoints at -24 and +16
pfa_month[, rel_month_bin := pmax(pmin(rel_month, 16), -24)]

cat(sprintf("  Relative month range: %d to %d\n",
            min(pfa_month$rel_month), max(pfa_month$rel_month)))

# ============================================================
# 7. Clean Land Registry Data
# ============================================================
cat("\n=== Cleaning Land Registry data ===\n")

if (file.exists(file.path(data_dir, "land_registry_all.csv"))) {
  lr <- fread(file.path(data_dir, "land_registry_all.csv"))

  # Parse date
  lr[, date := as.Date(date)]
  lr[, year := year(date)]
  lr[, quarter := quarter(date)]
  lr[, yq := sprintf("%d-Q%d", year, quarter)]

  # Identify Welsh vs English by postcode
  # Welsh postcodes: CF, LD, LL, NP, SA, SY (partially)
  welsh_prefixes <- c("CF", "LD", "LL", "NP", "SA")
  lr[, postcode_area := str_extract(postcode, "^[A-Z]+")]
  lr[, welsh := as.integer(postcode_area %in% welsh_prefixes |
                           (postcode_area == "SY" & !grepl("^SY[0-9]", postcode)))]

  # Note: SY postcode area straddles the border. For precision, we'd need NSPL.
  # Conservative approach: exclude SY postcodes from main analysis
  lr_clean <- lr[postcode_area != "SY" | !is.na(welsh)]

  # Treatment
  lr_clean[, post := as.integer(date >= as.Date("2023-09-17"))]
  lr_clean[, treat := welsh * post]

  # Log price
  lr_clean[, log_price := log(price)]

  # Property type encoding
  lr_clean[, prop_type_label := fcase(
    prop_type == "D", "Detached",
    prop_type == "S", "Semi-detached",
    prop_type == "T", "Terraced",
    prop_type == "F", "Flat",
    default = "Other"
  )]

  cat(sprintf("  Land Registry: %s transactions\n", format(nrow(lr_clean), big.mark = ",")))
  cat(sprintf("  Welsh transactions: %s\n", format(sum(lr_clean$welsh == 1, na.rm = TRUE), big.mark = ",")))
  cat(sprintf("  English transactions: %s\n", format(sum(lr_clean$welsh == 0, na.rm = TRUE), big.mark = ",")))

  fwrite(lr_clean, file.path(data_dir, "land_registry_clean.csv"))
} else {
  cat("  WARNING: No Land Registry data found.\n")
}

# ============================================================
# 8. Save Analysis Panels
# ============================================================
cat("\n=== Saving analysis panels ===\n")

fwrite(pfa_month, file.path(data_dir, "panel_pfa_month.csv"))
fwrite(placebo_pfa, file.path(data_dir, "panel_placebo_pfa.csv"))
fwrite(scot_panel, file.path(data_dir, "panel_scottish_placebo.csv"))

cat("  Saved panel_pfa_month.csv\n")
cat("  Saved panel_placebo_pfa.csv\n")
cat("  Saved panel_scottish_placebo.csv\n")

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("  Main panel: %d PFA-months | %d PFAs | %d months\n",
            nrow(pfa_month), n_distinct(pfa_month$pfa), n_distinct(pfa_month$ym)))
