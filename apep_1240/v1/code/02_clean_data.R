## ── 02_clean_data.R ────────────────────────────────────────────
## Clean and construct analysis variables

source("00_packages.R")

data_dir <- "../data"
district_panel <- fread(file.path(data_dir, "district_panel.csv"))
assessment_data <- fread(file.path(data_dir, "assessment_rounds.csv"))
wells_long <- fread(file.path(data_dir, "wells_long.csv"))

cat("=== Cleaning and panel construction ===\n")

## ── 1. Clean outliers in well data ──────────────────────────────
# Drop extreme values (likely measurement errors)
# Negative depth = artesian conditions (keep moderate ones)
# Extreme positive = likely errors
cat("Before cleaning:", nrow(wells_long), "obs\n")
wells_long <- wells_long[depth_to_water > -5 & depth_to_water < 200]
cat("After cleaning:", nrow(wells_long), "obs\n")

## ── 2. Construct treatment variables ────────────────────────────
## Primary treatment: whether a state has HIGH overexploited share
## We use a continuous treatment (oe_share) for the main specification
## and a binary high/low split for heterogeneity

# Identify "high-extraction" states: those with oe_share > 20% by 2013
high_oe_states <- assessment_data[round == 2013 & oe_share > 0.15, unique(state_code)]
cat("\nHigh-OE states (>15% overexploited by 2013):\n")
cat(paste(high_oe_states, collapse = ", "), "\n")

# Identify "surge" states: those with large INCREASE in oe blocks 2004-2013
assessment_wide <- dcast(assessment_data, state_code ~ round,
                         value.var = "n_overexploited")
setnames(assessment_wide, as.character(c(2004, 2009, 2011, 2013, 2017)),
         paste0("oe_", c(2004, 2009, 2011, 2013, 2017)))

assessment_wide[, delta_oe_04_13 := oe_2013 - oe_2004]
assessment_wide[, delta_oe_04_17 := oe_2017 - oe_2004]

# Surge states: those with >15 newly overexploited blocks between 2004-2013
surge_states <- assessment_wide[delta_oe_04_13 > 15, state_code]
cat("\nSurge states (>15 new OE blocks 2004-2013):\n")
cat(paste(surge_states, collapse = ", "), "\n")

## ── 3. Create treatment timing for staggered design ─────────────
## Key insight: the FIRST formal CGWB assessment was 2004. Before 2004,
## there was no official classification. The 2004 assessment created
## the regulatory framework. Subsequent rounds (2009, 2011, 2013, 2017)
## reclassified blocks.
##
## Treatment = first year a state crosses the "high extraction" threshold
## This is a staggered treatment design where states enter treatment at
## different times depending on their groundwater depletion trajectory

# Define treatment entry: first round where oe_share > 0.15
state_treatment <- assessment_data[oe_share > 0.15,
  .(first_high_round = min(round)), by = state_code]

# States that never cross threshold
all_states <- unique(assessment_data$state_code)
never_treated <- setdiff(all_states, state_treatment$state_code)
cat("\nNever-high-OE states:", paste(never_treated, collapse = ", "), "\n")
cat("Treated states and timing:\n")
print(state_treatment[order(first_high_round)])

## ── 4. Rebuild district panel with treatment variables ──────────
# Merge treatment timing
district_panel <- merge(district_panel, state_treatment,
                        by.x = "STATE", by.y = "state_code", all.x = TRUE)

# Mark treated/post
district_panel[, treated := !is.na(first_high_round)]
district_panel[, post := year >= first_high_round]
district_panel[is.na(post), post := FALSE]
district_panel[, treat_post := treated & post]

# Create relative time (for event study)
district_panel[, rel_year := fifelse(treated, year - first_high_round, NA_integer_)]

# Create balanced subsample indicator (districts observed every year)
district_coverage <- district_panel[, .(n_years = uniqueN(year)), by = district_id]
balanced_districts <- district_coverage[n_years >= 15, district_id]
district_panel[, balanced := district_id %in% balanced_districts]

cat("\nDistrict panel summary:\n")
cat("Total obs:", nrow(district_panel), "\n")
cat("Treated districts:", uniqueN(district_panel[treated == TRUE, district_id]), "\n")
cat("Control districts:", uniqueN(district_panel[treated == FALSE, district_id]), "\n")
cat("Balanced districts:", length(balanced_districts), "\n")

## ── 5. Construct well-level panel for well-level analysis ───────
## Use individual wells for more precise estimation

# Merge treatment timing to well data
wells_long <- merge(wells_long, state_treatment,
                    by.x = "STATE", by.y = "state_code", all.x = TRUE)
wells_long[, treated := !is.na(first_high_round)]
wells_long[, post := year >= first_high_round]
wells_long[is.na(post), post := FALSE]
wells_long[, treat_post := treated & post]
wells_long[, rel_year := fifelse(treated, year - first_high_round, NA_integer_)]

# Create well-level time panel
wells_long[, quarter := ceiling(month / 3)]
wells_long[, yq_numeric := year + (quarter - 1) / 4]

cat("\nWell-level panel:\n")
cat("Total obs:", nrow(wells_long), "\n")
cat("Treated wells:", uniqueN(wells_long[treated == TRUE, WLCODE]), "\n")
cat("Control wells:", uniqueN(wells_long[treated == FALSE, WLCODE]), "\n")

## ── 6. Construct SHRUG-linked district panel for economic outcomes ──
cat("\n=== Linking SHRUG nightlights data ===\n")

shrug_dir <- "../../../../data/india_shrug"

# Load nightlights at district level
nl_file <- file.path(shrug_dir, "dmsp_pc11dist.csv")
if (file.exists(nl_file)) {
  nl_dist <- fread(nl_file)
  cat("SHRUG nightlights loaded:", nrow(nl_dist), "obs\n")
  cat("Columns:", paste(names(nl_dist)[1:10], collapse = ", "), "\n")
} else {
  cat("SHRUG nightlights file not found at:", nl_file, "\n")
  cat("Skipping nightlights linkage.\n")
  nl_dist <- NULL
}

## ── 7. Save cleaned data ───────────────────────────────────────
fwrite(district_panel, file.path(data_dir, "district_panel_clean.csv"))
fwrite(wells_long, file.path(data_dir, "wells_long_clean.csv"))
fwrite(assessment_wide, file.path(data_dir, "assessment_wide.csv"))
fwrite(state_treatment, file.path(data_dir, "state_treatment.csv"))

cat("\n=== Cleaned data saved ===\n")
cat("Treatment groups:\n")
print(table(district_panel$treated, district_panel$post))
