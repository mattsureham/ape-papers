## ============================================================================
## 02_clean_data.R — Variable Construction & Panel Assembly
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"

## ---- 1. Load CQC care home data ----
cat("=== Loading CQC Data ===\n")
cqc <- fread(file.path(data_dir, "cqc_all_care_homes_england.csv"))
cat(sprintf("  %d care homes loaded\n", nrow(cqc)))

## ---- 2. Construct annual LA-level care home panel ----
cat("=== Building LA-Year Panel ===\n")

# For each LA × year, count:
#   - Stock of active care homes (registered before year-end, not deactivated before year-end)
#   - New registrations (registered in that year)
#   - Closures (deactivated in that year)
#   - Total beds (sum of beds for active homes)

years <- 2012:2019

# Parse dates if not already done
cqc[, reg_date_parsed := as.Date(reg_date, format = "%d/%m/%Y")]
cqc[, deact_date_parsed := as.Date(deact_date, format = "%d/%m/%Y")]

# Remove homes with no LA assignment
cqc_la <- cqc[!is.na(la_name) & la_name != ""]
cat(sprintf("  Homes with LA: %d (dropped %d without LA)\n",
            nrow(cqc_la), nrow(cqc) - nrow(cqc_la)))

# Build panel: for each LA × year, count active stock, entries, exits
panel_rows <- list()
for (yr in years) {
  year_start <- as.Date(sprintf("%d-01-01", yr))
  year_end   <- as.Date(sprintf("%d-12-31", yr))

  # Active at year-end: registered before year-end AND (not deactivated OR deactivated after year-end)
  active_mask <- cqc_la$reg_date_parsed <= year_end &
    (is.na(cqc_la$deact_date_parsed) | cqc_la$deact_date_parsed > year_end)

  # Entries: registered during this year
  entry_mask <- cqc_la$reg_date_parsed >= year_start & cqc_la$reg_date_parsed <= year_end

  # Exits: deactivated during this year
  exit_mask <- !is.na(cqc_la$deact_date_parsed) &
    cqc_la$deact_date_parsed >= year_start & cqc_la$deact_date_parsed <= year_end

  # Aggregate by LA
  active_by_la <- cqc_la[active_mask, .(
    n_homes = .N,
    total_beds = sum(beds, na.rm = TRUE)
  ), by = la_name]

  entry_by_la <- cqc_la[entry_mask, .(n_entries = .N), by = la_name]
  exit_by_la  <- cqc_la[exit_mask,  .(n_exits = .N, beds_lost = sum(beds, na.rm = TRUE)), by = la_name]

  # Merge
  yr_panel <- merge(active_by_la, entry_by_la, by = "la_name", all.x = TRUE)
  yr_panel <- merge(yr_panel, exit_by_la, by = "la_name", all.x = TRUE)
  yr_panel[is.na(n_entries), n_entries := 0L]
  yr_panel[is.na(n_exits), n_exits := 0L]
  yr_panel[is.na(beds_lost), beds_lost := 0L]
  yr_panel[, year := yr]

  panel_rows[[as.character(yr)]] <- yr_panel
}

panel <- rbindlist(panel_rows)
cat(sprintf("  Panel: %d LA-year observations, %d unique LAs, %d years\n",
            nrow(panel), length(unique(panel$la_name)), length(years)))

## ---- 3. Construct NLW Bite Measures ----
cat("=== Constructing NLW Bite ===\n")

# Use hourly pay data (correctly fetched)
ashe_hourly_file <- file.path(data_dir, "ashe_hourly_la.csv")
if (!file.exists(ashe_hourly_file)) {
  stop("ashe_hourly_la.csv not found. Re-run 01_fetch_data.R with pay=5 parameter.")
}
ashe <- fread(ashe_hourly_file)

# Get pre-NLW median hourly wage by LA (use 2015 data)
ashe_2015 <- ashe[DATE == 2015 & !is.na(OBS_VALUE) & OBS_VALUE > 5 & OBS_VALUE < 30]

la_wages <- ashe_2015[, .(
  la_code = GEOGRAPHY_CODE,
  la_name_ashe = GEOGRAPHY_NAME,
  median_wage_2015 = OBS_VALUE
)]
la_wages <- unique(la_wages)
cat(sprintf("  ASHE 2015 hourly wages: %d LAs (range £%.2f-£%.2f)\n",
            nrow(la_wages), min(la_wages$median_wage_2015), max(la_wages$median_wage_2015)))

# NLW rate at introduction
nlw_2016 <- 7.20

# Bite measure 1: Gap = (NLW - median_wage) / median_wage
# Higher values = NLW bites harder (wages closer to or below NLW)
la_wages[, bite_gap := (nlw_2016 - median_wage_2015) / median_wage_2015]

# Bite measure 2: Fraction affected (approximate)
# For care sector specifically, most workers are below median
# Use fraction below NLW as proxy = share with wages between 0 and £7.20
# Since we only have median, approximate: if median < £7.20, ~50%+ affected
# More precisely, use Kaitz index
la_wages[, bite_kaitz := nlw_2016 / median_wage_2015]

# Note: the gap measure will be negative where median > NLW (good — captures variation)
cat(sprintf("  Bite gap range: [%.3f, %.3f]\n",
            min(la_wages$bite_gap, na.rm = TRUE),
            max(la_wages$bite_gap, na.rm = TRUE)))
cat(sprintf("  Kaitz index range: [%.3f, %.3f]\n",
            min(la_wages$bite_kaitz, na.rm = TRUE),
            max(la_wages$bite_kaitz, na.rm = TRUE)))

# Also get ASHE wages for all years (for first-stage analysis)
ashe_panel <- ashe[!is.na(OBS_VALUE) & OBS_VALUE > 5, .(
  la_code = GEOGRAPHY_CODE,
  la_name_ashe = GEOGRAPHY_NAME,
  year = as.integer(DATE),
  median_wage = OBS_VALUE
)]

## ---- 4. Match CQC LA names to ASHE LA names ----
cat("=== Matching LA Names ===\n")

# CQC uses slightly different LA names than NOMIS/ASHE
# Strategy: fuzzy match on name, validate manually
cqc_las <- unique(panel$la_name)
ashe_las <- unique(la_wages$la_name_ashe)

# Clean names for matching
clean_name <- function(x) {
  x <- tolower(x)
  x <- gsub(",.*", "", x)
  x <- gsub("\\s+(council|borough|district|city|county|metropolitan|unitary|authority).*", "", x)
  x <- trimws(x)
  x
}

# Direct match first
panel[, la_clean := clean_name(la_name)]
la_wages[, la_clean := clean_name(la_name_ashe)]

# Deduplicate la_wages by la_clean (keep first if multiple matches)
la_wages_dedup <- la_wages[, .SD[1], by = la_clean]
cat(sprintf("  ASHE after dedup by clean name: %d unique LAs\n", nrow(la_wages_dedup)))

# Merge on cleaned names
panel_merged <- merge(panel, la_wages_dedup[, .(la_clean, la_code, median_wage_2015, bite_gap, bite_kaitz)],
                      by = "la_clean", all.x = TRUE)

n_matched <- sum(!is.na(panel_merged$bite_gap))
n_total <- nrow(panel_merged)
n_la_matched <- length(unique(panel_merged$la_name[!is.na(panel_merged$bite_gap)]))
cat(sprintf("  Matched: %d/%d observations (%d LAs with bite measure)\n",
            n_matched, n_total, n_la_matched))

# For unmatched LAs, try harder matching
unmatched_cqc <- unique(panel_merged$la_name[is.na(panel_merged$bite_gap)])
if (length(unmatched_cqc) > 0) {
  cat(sprintf("  %d unmatched CQC LAs. Attempting fuzzy match...\n", length(unmatched_cqc)))

  # Manual corrections for known discrepancies
  name_map <- c(
    "Kingston upon Hull, City of" = "kingston upon hull",
    "Herefordshire, County of" = "herefordshire",
    "Bristol, City of" = "bristol",
    "Durham County" = "county durham",
    "County Durham" = "county durham"
  )

  for (cqc_name in unmatched_cqc) {
    clean_cqc <- clean_name(cqc_name)
    # Check if in manual map
    if (cqc_name %in% names(name_map)) {
      clean_cqc <- name_map[cqc_name]
    }
    # Try to find close match in ASHE
    dists <- adist(clean_cqc, la_wages$la_clean)
    best_match_idx <- which.min(dists)
    best_dist <- min(dists)
    if (best_dist <= 3) {
      panel_merged[la_name == cqc_name & is.na(bite_gap),
                   `:=`(la_code = la_wages$la_code[best_match_idx],
                        median_wage_2015 = la_wages$median_wage_2015[best_match_idx],
                        bite_gap = la_wages$bite_gap[best_match_idx],
                        bite_kaitz = la_wages$bite_kaitz[best_match_idx])]
    }
  }

  n_matched2 <- sum(!is.na(panel_merged$bite_gap))
  n_la_matched2 <- length(unique(panel_merged$la_name[!is.na(panel_merged$bite_gap)]))
  cat(sprintf("  After fuzzy matching: %d/%d observations (%d LAs)\n",
              n_matched2, n_total, n_la_matched2))
}

## ---- 5. Add Population Controls ----
cat("=== Adding Population Controls ===\n")

pop_file <- file.path(data_dir, "ons_population_la.csv")
if (file.exists(pop_file)) {
  pop <- fread(pop_file)
  # Extract total population and 65+ by LA and year
  pop_clean <- pop[, .(
    la_code_pop = GEOGRAPHY_CODE,
    la_name_pop = GEOGRAPHY_NAME,
    year = as.integer(DATE),
    age_group = C_AGE_NAME,
    population = as.numeric(OBS_VALUE)
  )]

  # Pivot wider: total pop and 65+ pop
  pop_total <- pop_clean[grepl("All ages|Total", age_group, ignore.case = TRUE),
                          .(pop_total = sum(population, na.rm = TRUE)),
                          by = .(la_code_pop, year)]
  pop_65 <- pop_clean[grepl("85|Aged 85", age_group, ignore.case = TRUE),
                       .(pop_65plus = sum(population, na.rm = TRUE)),
                       by = .(la_code_pop, year)]

  pop_panel <- merge(pop_total, pop_65, by = c("la_code_pop", "year"), all = TRUE)

  # Merge with main panel
  panel_merged <- merge(panel_merged, pop_panel,
                        by.x = c("la_code", "year"),
                        by.y = c("la_code_pop", "year"),
                        all.x = TRUE)
  cat(sprintf("  Population merged: %d obs with pop data\n",
              sum(!is.na(panel_merged$pop_total))))
} else {
  cat("  Population data not available. Proceeding without.\n")
  panel_merged[, `:=`(pop_total = NA_real_, pop_65plus = NA_real_)]
}

## ---- 6. Construct Key Variables ----
cat("=== Constructing Analysis Variables ===\n")

# Treatment: post-NLW indicator (April 2016 = fiscal year 2016)
panel_merged[, post := as.integer(year >= 2016)]

# Closure rate per 100 homes
panel_merged[, closure_rate := (n_exits / (n_homes + n_exits)) * 100]

# Beds per 1000 elderly (65+) population
panel_merged[!is.na(pop_65plus) & pop_65plus > 0,
             beds_per_1000_65 := (total_beds / pop_65plus) * 1000]

# Entry rate
panel_merged[, entry_rate := (n_entries / (n_homes + n_exits)) * 100]

# Net change
panel_merged[, net_change := n_entries - n_exits]

# Standardize bite (for regression interpretation)
panel_merged[, bite_gap_std := (bite_gap - mean(bite_gap, na.rm = TRUE)) /
               sd(bite_gap, na.rm = TRUE)]

## ---- 7. Summary Statistics ----
cat("\n=== Summary Statistics ===\n")

# Keep only observations with bite measure
analysis <- panel_merged[!is.na(bite_gap)]

cat(sprintf("  Analysis sample: %d LA-year obs, %d unique LAs, %d years\n",
            nrow(analysis), length(unique(analysis$la_name)), length(unique(analysis$year))))

cat("\n  Pre-NLW (2012-2015):\n")
pre <- analysis[year < 2016]
cat(sprintf("    Mean homes/LA: %.1f | Mean closures/LA: %.1f | Mean closure rate: %.1f%%\n",
            mean(pre$n_homes), mean(pre$n_exits), mean(pre$closure_rate, na.rm = TRUE)))

cat("\n  Post-NLW (2016-2019):\n")
post <- analysis[year >= 2016]
cat(sprintf("    Mean homes/LA: %.1f | Mean closures/LA: %.1f | Mean closure rate: %.1f%%\n",
            mean(post$n_homes), mean(post$n_exits), mean(post$closure_rate, na.rm = TRUE)))

cat("\n  NLW Bite (gap measure, 2015):\n")
bite_sum <- analysis[year == 2015 & !is.na(bite_gap)]
cat(sprintf("    Mean: %.3f | SD: %.3f | Min: %.3f | Max: %.3f\n",
            mean(bite_sum$bite_gap), sd(bite_sum$bite_gap),
            min(bite_sum$bite_gap), max(bite_sum$bite_gap)))

# High-bite vs low-bite comparison
bite_median <- median(bite_sum$bite_gap)
analysis[, high_bite := as.integer(bite_gap > bite_median)]

cat("\n  High-bite LAs (above median):\n")
cat(sprintf("    Pre closure rate: %.1f%% | Post closure rate: %.1f%%\n",
            mean(analysis[high_bite == 1 & year < 2016]$closure_rate, na.rm = TRUE),
            mean(analysis[high_bite == 1 & year >= 2016]$closure_rate, na.rm = TRUE)))
cat("  Low-bite LAs (below median):\n")
cat(sprintf("    Pre closure rate: %.1f%% | Post closure rate: %.1f%%\n",
            mean(analysis[high_bite == 0 & year < 2016]$closure_rate, na.rm = TRUE),
            mean(analysis[high_bite == 0 & year >= 2016]$closure_rate, na.rm = TRUE)))

## ---- 8. Save Analysis Dataset ----
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\n  Analysis panel saved: %s\n", file.path(data_dir, "analysis_panel.csv")))

# Also save bite measure separately for reference
fwrite(la_wages, file.path(data_dir, "la_bite_measures.csv"))

# Save ASHE panel for first-stage
fwrite(ashe_panel, file.path(data_dir, "ashe_wages_panel.csv"))

cat("\nData cleaning complete.\n")
