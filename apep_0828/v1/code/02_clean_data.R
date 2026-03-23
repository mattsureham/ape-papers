## 02_clean_data.R — Build section × year panel for DiD analysis
## Design: 16 identified smart sections + conventional motorway controls

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) script_dir <- dirname(normalizePath(script_path)) else script_dir <- getwd()
source(file.path(script_dir, "00_packages.R"))
setwd(dirname(script_dir))
cat(sprintf("Working directory: %s\n", getwd()))

cat("=== STEP 1: Load data ===\n")
mway <- fread("data/stats19_motorway_collisions_assigned.csv")
cas <- fread("data/stats19_motorway_casualties.csv")
smart <- fread("data/smart_sections.csv")

cat(sprintf("  Collisions: %d, Casualties: %d, Smart sections: %d\n",
            nrow(mway), nrow(cas), nrow(smart)))

# Fix type coercion
mway[, year := as.integer(year)]
mway[, qtr := as.integer(qtr)]

# Casualty-level severity
sev_col <- grep("casualty_severity", names(cas), value = TRUE)[1]
idx_col <- grep("collision_index|accident_index", names(cas), value = TRUE)[1]
cas[, severity := get(sev_col)]
cas[, idx := get(idx_col)]

cat("\n=== STEP 2: Build smart section × year panel ===\n")

# Keep only sections with meaningful collision counts (>= 50 total)
sec_counts <- mway[!is.na(section_id), .N, by = section_id]
good_sections <- sec_counts[N >= 50]$section_id
cat(sprintf("  Sections with >= 50 collisions: %d of %d\n",
            length(good_sections), nrow(smart)))

# Build section × year collision counts
smart_panel <- mway[section_id %in% good_sections,
                     .(n_collisions = .N,
                       n_fatal = sum(severity == "Fatal", na.rm = TRUE),
                       n_serious = sum(severity == "Serious", na.rm = TRUE),
                       n_slight = sum(severity == "Slight", na.rm = TRUE)),
                     by = .(section_id, year)]

# Merge section info
smart_panel <- merge(smart_panel, smart[, .(section_id, motorway, junctions, type,
                                             open_year, length_miles, treat_date)],
                     by = "section_id")

# Collision rates per mile
smart_panel[, `:=`(
  rate_total = n_collisions / length_miles,
  rate_fatal = n_fatal / length_miles,
  rate_serious = n_serious / length_miles,
  rate_ks = (n_fatal + n_serious) / length_miles  # Killed/Seriously injured
)]

# Treatment indicator
smart_panel[, treated := as.integer(year >= open_year)]

# Label
smart_panel[, section_label := paste0(motorway, " ", junctions)]
smart_panel[, unit_type := "smart"]

cat(sprintf("  Smart panel: %d section-years\n", nrow(smart_panel)))

cat("\n=== STEP 3: Build conventional motorway control panel ===\n")

# Identify motorways that had NO smart conversions as pure controls
smart_mways <- unique(smart$motorway)
all_mways <- unique(mway$mway_name[!is.na(mway$mway_name)])
# Only keep genuine motorway names (M + number)
all_mways <- all_mways[grepl("^M[0-9]+$", all_mways)]

# Major conventional motorways (never converted)
# Filter to those with substantial traffic (>= 500 total collisions 2000-2023)
control_candidates <- setdiff(all_mways, smart_mways)
ctrl_counts <- mway[mway_name %in% control_candidates & is.na(section_id),
                     .N, by = mway_name]
# Keep motorways with >= 500 collisions
control_mways <- ctrl_counts[N >= 500]$mway_name
cat(sprintf("  Control motorways (>= 500 collisions): %d\n", length(control_mways)))
cat(sprintf("    %s\n", paste(sort(control_mways), collapse = ", ")))

# Also include the conventional segments of smart motorways (collisions NOT in smart sections)
# For motorways with smart sections, the "non-smart" collisions serve as additional controls
conv_from_smart <- mway[mway_name %in% smart_mways & is.na(section_id)]
cat(sprintf("  Conventional collisions on smart motorways: %d\n", nrow(conv_from_smart)))

# Build control panel — one entry per control motorway × year
control_pure <- mway[mway_name %in% control_mways & is.na(section_id),
                      .(n_collisions = .N,
                        n_fatal = sum(severity == "Fatal", na.rm = TRUE),
                        n_serious = sum(severity == "Serious", na.rm = TRUE),
                        n_slight = sum(severity == "Slight", na.rm = TRUE)),
                      by = .(mway_name, year)]

# Approximate lengths for control motorways (miles, from DfT road lengths)
ctrl_lengths <- data.table(
  mway_name = c("M11", "M40", "M2",  "M18", "M180", "M53", "M54", "M55",
                "M61", "M65", "M66", "M67", "M69",  "M74", "M48", "M50",
                "M26", "M45", "M58", "M57", "M77",  "M9",  "M73", "M80",
                "M8",  "M90", "M876","M621","M606"),
  length_miles = c(51, 89, 26, 32, 44, 18, 26, 13,
                   24, 31, 7,  7,  9,  50, 4,  16,
                   2,  6,  14, 7,  12, 30, 10, 34,
                   61, 34, 5,  7,  4)
)
control_pure <- merge(control_pure, ctrl_lengths, by = "mway_name", all.x = TRUE)
# Drop motorways without known length
control_pure <- control_pure[!is.na(length_miles)]

control_pure[, `:=`(
  rate_total = n_collisions / length_miles,
  rate_fatal = n_fatal / length_miles,
  rate_serious = n_serious / length_miles,
  rate_ks = (n_fatal + n_serious) / length_miles,
  treated = 0L,
  section_id = NA_integer_,
  motorway = mway_name,
  junctions = "All",
  type = "Conventional",
  open_year = NA_integer_,
  treat_date = NA_real_,
  section_label = mway_name,
  unit_type = "conventional"
)]

cat(sprintf("  Control panel: %d motorway-years\n", nrow(control_pure)))

cat("\n=== STEP 4: Combine into analysis panel ===\n")

# Align columns
keep_cols <- c("section_id", "motorway", "junctions", "section_label", "type",
               "unit_type", "open_year", "treat_date", "length_miles",
               "year", "n_collisions", "n_fatal", "n_serious", "n_slight",
               "rate_total", "rate_fatal", "rate_serious", "rate_ks", "treated")

panel <- rbind(
  smart_panel[, ..keep_cols],
  control_pure[, ..keep_cols]
)

# Create unique unit ID for DiD
panel[, unit_id := fifelse(unit_type == "smart",
                            paste0("S_", section_id),
                            paste0("C_", motorway))]

# For Callaway-Sant'Anna: treatment cohort (first year treated; 0 for never-treated)
panel[, cohort := fifelse(is.na(open_year), 0L, as.integer(open_year))]

# Time period (year)
panel[, time_period := year]

# Summary stats
n_treated_units <- length(unique(panel[unit_type == "smart"]$unit_id))
n_control_units <- length(unique(panel[unit_type == "conventional"]$unit_id))
cat(sprintf("  Panel: %d unit-years (%d treated units, %d control units)\n",
            nrow(panel), n_treated_units, n_control_units))
cat(sprintf("  Year range: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Mean collisions/year (smart): %.1f\n",
            mean(panel[unit_type == "smart"]$n_collisions)))
cat(sprintf("  Mean collisions/year (control): %.1f\n",
            mean(panel[unit_type == "conventional"]$n_collisions)))

# Descriptive stats by treatment status
cat("\n  Collision rates per mile (pre-2014 average):\n")
pre <- panel[year < 2014]
cat(sprintf("    Smart sections: %.2f collisions/mile/year\n",
            mean(pre[unit_type == "smart"]$rate_total, na.rm = TRUE)))
cat(sprintf("    Control motorways: %.2f collisions/mile/year\n",
            mean(pre[unit_type == "conventional"]$rate_total, na.rm = TRUE)))

# Save
fwrite(panel, "data/analysis_panel.csv")

cat("\n=== STEP 5: Build casualty-level severity dataset ===\n")

# For collision-level severity analysis
# Merge casualty counts by severity to collision data
cas_by_collision <- cas[, .(
  casualties_fatal = sum(severity == "Fatal", na.rm = TRUE),
  casualties_serious = sum(severity == "Serious", na.rm = TRUE),
  casualties_slight = sum(severity == "Slight", na.rm = TRUE),
  casualties_total = .N
), by = idx]

collision_sev <- merge(
  mway[, .(idx, year, mway_name, section_id, severity,
           easting, northing, smart)],
  cas_by_collision,
  by = "idx", all.x = TRUE
)

# Add treatment info
collision_sev <- merge(collision_sev,
                        smart[, .(section_id, open_year, type, length_miles)],
                        by = "section_id", all.x = TRUE)

# KSI indicator (killed or seriously injured)
collision_sev[, ksi := as.integer(severity %in% c("Fatal", "Serious"))]

fwrite(collision_sev, "data/collision_severity.csv")
cat(sprintf("  Collision-level dataset: %d observations\n", nrow(collision_sev)))

cat("\n=== Clean data complete ===\n")
cat(sprintf("  Analysis panel: data/analysis_panel.csv (%d rows)\n", nrow(panel)))
cat(sprintf("  Collision severity: data/collision_severity.csv (%d rows)\n", nrow(collision_sev)))
