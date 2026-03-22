# 02_clean_data.R — Clean and construct analysis panel
# apep_0734: Wales 20mph Speed Limit and Road Casualties

source("00_packages.R")

cat("=== Loading raw data ===\n")
collisions <- fread("../data/collisions_raw.csv")
casualties <- fread("../data/casualties_raw.csv")

# Standardize column names (DfT uses inconsistent naming across years)
names(collisions) <- tolower(names(collisions))
names(casualties) <- tolower(names(casualties))

# The collision file has the speed limit and LA information
# The casualty file has severity at casualty level
# We need to merge on accident_index (or collision_index)

# Identify the collision ID column
id_col <- intersect(c("accident_index", "collision_index"), names(collisions))[1]
cas_id_col <- intersect(c("accident_index", "collision_index"), names(casualties))[1]
cat("Collision ID column:", id_col, "\n")
cat("Casualty ID column:", cas_id_col, "\n")

# Identify the speed limit column
speed_col <- intersect(c("speed_limit", "speed_limit_value"), names(collisions))[1]
cat("Speed limit column:", speed_col, "\n")

# Identify the LA column
la_col <- intersect(
  c("local_authority_district", "local_authority_(district)",
    "local_authority_ons_district", "local_authority_ons_district_code"),
  names(collisions)
)
cat("LA columns found:", paste(la_col, collapse = ", "), "\n")

# Identify date column
date_col <- intersect(c("date", "accident_date", "collision_date"), names(collisions))[1]
cat("Date column:", date_col, "\n")

# --- Classify country from LA code ---
# Welsh LA codes start with W, English with E, Scottish with S
# We need either a code column or a district number

# Check for the LA district code (ONS code like E09000001)
la_code_col <- intersect(
  c("local_authority_ons_district", "local_authority_ons_district_code",
    "local_authority_district"),
  names(collisions)
)

# Use the first available
if (length(la_code_col) > 0) {
  la_code_col <- la_code_col[1]
  cat("Using LA code column:", la_code_col, "\n")
  cat("Sample values:\n")
  print(head(unique(collisions[[la_code_col]]), 20))
}

# Check if the column contains ONS codes (Exxxxxxxxx, Wxxxxxxxxx) or numeric codes
sample_val <- as.character(collisions[[la_code_col]][1])
if (grepl("^[EWS]", sample_val)) {
  cat("LA codes are ONS format — classifying by first letter\n")
  collisions[, country := fcase(
    grepl("^W", get(la_code_col)), "Wales",
    grepl("^E", get(la_code_col)), "England",
    grepl("^S", get(la_code_col)), "Scotland",
    default = "Other"
  )]
  collisions[, la_code := get(la_code_col)]
} else {
  # Numeric codes — need lookup
  # Welsh LA district codes: 570-590 range (historically)
  # Let's check the highway authority column instead
  ha_col <- intersect(c("local_authority_highway", "local_authority_(highway)"), names(collisions))
  cat("Trying highway authority column(s):", paste(ha_col, collapse = ", "), "\n")

  # Check all available columns for country classification
  cat("\nAll columns in collisions:\n")
  print(names(collisions))

  # Use the district code — DfT codes: Welsh = W prefix or specific numeric ranges
  # Let's use the fact that we can look up by code
  la_num <- as.integer(collisions[[la_code_col]])
  if (!all(is.na(la_num))) {
    cat("Numeric LA codes detected. Attempting DfT lookup...\n")
    # DfT uses ONS codes in recent years. The column might have the code.
    # Let's look for any column with W/E prefix
    for (cn in names(collisions)) {
      vals <- as.character(collisions[[cn]][1:5])
      if (any(grepl("^[EWS]0[0-9]", vals))) {
        cat("Found ONS code column:", cn, "\n")
        la_code_col <- cn
        break
      }
    }
  }

  collisions[, country := fcase(
    grepl("^W", as.character(get(la_code_col))), "Wales",
    grepl("^E", as.character(get(la_code_col))), "England",
    grepl("^S", as.character(get(la_code_col))), "Scotland",
    default = "Other"
  )]
  collisions[, la_code := as.character(get(la_code_col))]
}

cat("\nCountry distribution:\n")
print(collisions[, .N, by = country])

# --- Parse dates and create quarterly panel ---
collisions[, date_parsed := as.Date(get(date_col), format = "%d/%m/%Y")]
# Try alternative format if parsing fails
if (all(is.na(collisions$date_parsed))) {
  collisions[, date_parsed := as.Date(get(date_col))]
}
stopifnot("Date parsing failed" = sum(!is.na(collisions$date_parsed)) > nrow(collisions) * 0.9)

collisions[, quarter := paste0(year(date_parsed), "-Q", quarter(date_parsed))]
collisions[, year_q := year(date_parsed) + (quarter(date_parsed) - 1) / 4]

# --- Speed limit classification ---
collisions[, speed := as.integer(get(speed_col))]
collisions[, restricted := speed %in% c(20L, 30L)]  # Restricted roads (street lighting)
collisions[, speed_20 := speed == 20L]
collisions[, speed_30 := speed == 30L]
collisions[, speed_high := speed >= 40L]  # Non-restricted roads

# --- Merge casualty severity ---
# Count casualties per collision by severity
cas_severity_col <- intersect(c("casualty_severity", "accident_severity"), names(casualties))[1]
if (is.null(cas_severity_col)) {
  # Severity might be in the collision file itself
  sev_col <- intersect(c("accident_severity", "collision_severity"), names(collisions))[1]
  cat("Using collision-level severity:", sev_col, "\n")
  # 1=Fatal, 2=Serious, 3=Slight
  collisions[, n_fatal := fifelse(get(sev_col) == 1, 1L, 0L)]
  collisions[, n_serious := fifelse(get(sev_col) == 2, 1L, 0L)]
  collisions[, n_slight := fifelse(get(sev_col) == 3, 1L, 0L)]
  collisions[, n_casualties := 1L]  # at collision level
} else {
  cat("Merging casualty-level severity from casualties file\n")
  # Count by severity per collision
  casualties[, severity := get(cas_severity_col)]
  cas_counts <- casualties[, .(
    n_fatal = sum(severity == 1, na.rm = TRUE),
    n_serious = sum(severity == 2, na.rm = TRUE),
    n_slight = sum(severity == 3, na.rm = TRUE),
    n_casualties = .N
  ), by = c(cas_id_col)]

  setnames(cas_counts, cas_id_col, id_col)
  collisions <- merge(collisions, cas_counts, by = id_col, all.x = TRUE)
  collisions[is.na(n_casualties), n_casualties := 0L]
  collisions[is.na(n_fatal), n_fatal := 0L]
  collisions[is.na(n_serious), n_serious := 0L]
  collisions[is.na(n_slight), n_slight := 0L]
}

# --- Filter to England and Wales only ---
collisions <- collisions[country %in% c("England", "Wales")]
cat("\nAfter filtering to England & Wales:", nrow(collisions), "collisions\n")

# --- Aggregate to LA-quarter panel ---
# Panel for restricted roads (20+30mph combined)
panel_restricted <- collisions[restricted == TRUE, .(
  casualties = sum(n_casualties),
  fatal = sum(n_fatal),
  serious = sum(n_serious),
  slight = sum(n_slight),
  collisions = .N
), by = .(la_code, country, quarter, year_q)]

# Panel for 20mph roads only
panel_20 <- collisions[speed_20 == TRUE, .(
  casualties_20 = sum(n_casualties),
  collisions_20 = .N
), by = .(la_code, country, quarter, year_q)]

# Panel for 30mph roads only
panel_30 <- collisions[speed_30 == TRUE, .(
  casualties_30 = sum(n_casualties),
  collisions_30 = .N
), by = .(la_code, country, quarter, year_q)]

# Panel for high-speed roads (placebo)
panel_high <- collisions[speed_high == TRUE, .(
  casualties_high = sum(n_casualties),
  collisions_high = .N
), by = .(la_code, country, quarter, year_q)]

# Merge all panels
panel <- merge(panel_restricted, panel_20, by = c("la_code", "country", "quarter", "year_q"), all.x = TRUE)
panel <- merge(panel, panel_30, by = c("la_code", "country", "quarter", "year_q"), all.x = TRUE)
panel <- merge(panel, panel_high, by = c("la_code", "country", "quarter", "year_q"), all.x = TRUE)

# Fill NAs with zeros (LAs with no casualties in a category-quarter)
for (v in c("casualties_20", "collisions_20", "casualties_30", "collisions_30",
            "casualties_high", "collisions_high")) {
  panel[is.na(get(v)), (v) := 0L]
}

# --- Treatment variables ---
panel[, wales := as.integer(country == "Wales")]
panel[, post := as.integer(year_q >= 2023.75)]  # Q4 2023 onward
panel[, treat := wales * post]

# --- Create balanced panel ---
# Ensure all LA-quarter combinations exist
all_las <- unique(panel$la_code)
all_quarters <- sort(unique(panel$quarter))
all_year_qs <- sort(unique(panel$year_q))

balanced <- CJ(la_code = all_las, year_q = all_year_qs)
balanced <- merge(balanced, unique(panel[, .(la_code, country, wales)]), by = "la_code")
balanced <- merge(balanced, unique(panel[, .(year_q, quarter)]), by = "year_q")
balanced[, post := as.integer(year_q >= 2023.75)]
balanced[, treat := wales * post]

panel <- merge(balanced, panel[, .(la_code, year_q, casualties, fatal, serious, slight,
                                    collisions, casualties_20, collisions_20,
                                    casualties_30, collisions_30,
                                    casualties_high, collisions_high)],
               by = c("la_code", "year_q"), all.x = TRUE)

# Fill missing with 0 (LA-quarters with no collisions)
num_cols <- c("casualties", "fatal", "serious", "slight", "collisions",
              "casualties_20", "collisions_20", "casualties_30", "collisions_30",
              "casualties_high", "collisions_high")
for (v in num_cols) {
  panel[is.na(get(v)), (v) := 0L]
}

# --- Population merge ---
if (file.exists("../data/population_raw.csv")) {
  pop <- fread("../data/population_raw.csv")
  cat("Population data columns:", paste(names(pop), collapse = ", "), "\n")

  # Clean population data
  pop_clean <- pop[, .(
    la_code = GEOGRAPHY_CODE,
    pop_year = as.integer(gsub("[^0-9]", "", DATE_NAME)),
    population = as.numeric(OBS_VALUE)
  )]
  pop_clean <- pop_clean[!is.na(population) & population > 0]

  # For each year_q, assign the closest population year
  panel[, pop_year := floor(year_q)]
  panel <- merge(panel, pop_clean, by = c("la_code", "pop_year"), all.x = TRUE)

  # Fill forward/backward for missing years
  panel[, population := nafill(population, type = "locf"), by = la_code]
  panel[, population := nafill(population, type = "nocb"), by = la_code]

  # Per capita rates (per 100,000)
  if (sum(!is.na(panel$population)) > nrow(panel) * 0.5) {
    panel[population > 0, casualties_pc := casualties / population * 100000]
    panel[population > 0, fatal_pc := fatal / population * 100000]
    cat("Population merge successful — per capita rates computed\n")
  } else {
    cat("Population merge incomplete — using raw counts\n")
    panel[, casualties_pc := casualties]
    panel[, fatal_pc := fatal]
  }
} else {
  cat("No population data — using raw counts\n")
  panel[, casualties_pc := casualties]
  panel[, fatal_pc := fatal]
}

# --- Log transform ---
panel[, log_casualties := log(casualties + 1)]
panel[, log_collisions := log(collisions + 1)]

# --- Summary ---
cat("\n=== Panel Summary ===\n")
cat("LAs:", uniqueN(panel$la_code), "\n")
cat("  Welsh:", uniqueN(panel[wales == 1]$la_code), "\n")
cat("  English:", uniqueN(panel[wales == 0]$la_code), "\n")
cat("Quarters:", uniqueN(panel$quarter), "\n")
cat("Pre-treatment quarters:", sum(all_year_qs < 2023.75), "\n")
cat("Post-treatment quarters:", sum(all_year_qs >= 2023.75), "\n")
cat("Total observations:", nrow(panel), "\n")
cat("Quarter range:", min(panel$quarter), "to", max(panel$quarter), "\n")

# --- Save ---
fwrite(panel, "../data/panel.csv")
cat("\nPanel saved to data/panel.csv\n")
